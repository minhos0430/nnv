function verifyAll()
    % NNV-only benchmarking with SIMPLIFIED timeout
    
    fprintf('=== NNV Benchmark Setup ===\n');
    
    nnv_engine_utils = '../../../../../../engine/utils'; 
    nnv_root = '../../../../../../';
    
    fprintf('Adding NNV paths...\n');
    
    if isfolder(nnv_engine_utils)
        addpath(nnv_engine_utils);
        fprintf('✓ Added engine/utils: %s\n', nnv_engine_utils);
    else
        error('Engine/utils directory not found at: %s', nnv_engine_utils);
    end
    
    if isfolder(nnv_root)
        addpath(genpath(nnv_root));
        fprintf('✓ Added NNV root: %s\n', nnv_root);
    else
        warning('NNV root directory not found at: %s', nnv_root);
    end

    required_functions = {'onnx2nnv', 'load_vnnlib', 'ImageStar', 'verifyNNV'};
    missing_functions = {};
    
    for i = 1:length(required_functions)
        if exist(required_functions{i}, 'file')
            fprintf('✓ %s found\n', required_functions{i});
        else
            missing_functions{end+1} = required_functions{i};
            fprintf('✗ %s missing\n', required_functions{i});
        end
    end
    
    if ~isempty(missing_functions)
        error('Missing required functions: %s', strjoin(missing_functions, ', '));
    end
    
    fprintf('=== Starting NNV Benchmark at %s ===\n', datetime('now'));
    
    try
        csvFile = "instances.csv";
        
        if ~isfile(csvFile)
            error('CSV file %s not found', csvFile);
        end
        
        opts = detectImportOptions(csvFile);
        opts.Delimiter = ',';
        NNs_props_timeout = readtable(csvFile, opts);
        N = min(10, height(NNs_props_timeout));
        
        fprintf('Found %d instances to process\n', N);
        
        res = zeros(N, 3);
        reachOpt1 = struct; 
        reachOpt1.reachMethod = 'approx-star';
        
        for i = 1:N
            fprintf('\n--- Processing instance %d/%d ---\n', i, N);
            fprintf('Network: %s\n', NNs_props_timeout.Var1{i});
            fprintf('Property: %s\n', NNs_props_timeout.Var2{i});
            
            % DECISION: Use timeout only for larger instances
            [~, onnx_filename, ~] = fileparts(NNs_props_timeout.Var1{i});
            
            if contains(onnx_filename, 'N=M=16') % Small instance - run directly
                fprintf('  Running NNV verification (direct - small instance)...\n');
                try
                    [res(i,1), res(i,2), res(i,3)] = verify_tllverify_nnv_with_memory(...
                        NNs_props_timeout.Var1{i}, NNs_props_timeout.Var2{i}, reachOpt1);
                    fprintf('  NNV: Result=%d, Time=%.3fs, Memory=%.2fMB\n', res(i,1), res(i,2), res(i,3));
                catch ME
                    fprintf('  NNV verification failed: %s\n', ME.message);
                    res(i,1:3) = [-1, -1, -1];
                end
                
            else % Large instance - use system timeout
                fprintf('  Running NNV verification (with timeout - large instance)...\n');
                timeout_cmd = sprintf('timeout 120s matlab -nodisplay -r "addpath(''%s''); addpath(genpath(''%s'')); [r,t,m]=verify_tllverify_nnv_with_memory(''%s'',''%s'',struct(''reachMethod'',''approx-star'')); fprintf(''RESULT:%%d,%%f,%%f\\n'',r,t,m); exit;"', ...
                    nnv_engine_utils, nnv_root, NNs_props_timeout.Var1{i}, NNs_props_timeout.Var2{i});
                
                start_time = tic;
                [status, output] = system(timeout_cmd);
                elapsed = toc(start_time);
                
                if status == 124 % timeout
                    res(i,1:3) = [-2, 120, -1];
                    fprintf('  NNV: TIMEOUT after 120 seconds\n');
                else
                    % Parse output
                    tokens = regexp(output, 'RESULT:(-?\d+),([\d.-]+),([\d.-]+)', 'tokens');
                    if ~isempty(tokens)
                        res(i,1) = str2double(tokens{1}{1});
                        res(i,2) = str2double(tokens{1}{2});
                        res(i,3) = str2double(tokens{1}{3});
                        fprintf('  NNV: Result=%d, Time=%.3fs, Memory=%.2fMB\n', res(i,1), res(i,2), res(i,3));
                    else
                        res(i,1:3) = [-1, elapsed, -1];
                        fprintf('  NNV: ERROR (could not parse output)\n');
                    end
                end
            end
            
            % Clear workspace
            clearvars -except i N res NNs_props_timeout reachOpt1 csvFile opts nnv_engine_utils nnv_root
            if exist('java.lang.System', 'class')
                java.lang.System.gc();
            end
        end
        
        save_nnv_results_txt(res, NNs_props_timeout, N);
        fprintf('\n=== NNV Benchmark completed successfully at %s ===\n', datetime('now'));
        
    catch ME
        fprintf('\n!!! Critical error in verifyAll !!!\n');
        fprintf('Error: %s\n', ME.message);
        rethrow(ME);
    end
end

function [res, time, memory_mb] = verify_tllverify_nnv_with_memory(onnxF, vnnlibF, reachOpt)
    % NNV verification with memory tracking
    
    if ~isfile(onnxF)
        error('ONNX file not found: %s', onnxF);
    end
    if ~isfile(vnnlibF)
        error('VNNLIB file not found: %s', vnnlibF);
    end
    
    % Memory tracking
    initial_vars = whos;
    initial_memory = sum([initial_vars.bytes]);
    
    try
        % Load network
        loadOpt.InputDataFormat = "BC";
        nn = onnx2nnv(onnxF, loadOpt);
        
        % Load property
        property = load_vnnlib(vnnlibF);
        IS = ImageStar(property.lb, property.ub);

        % Reachability computation
        t = tic;
        R = nn.reach(IS, reachOpt);

        % Verify
        res = verifyNNV(R, property.prop);
        time = toc(t);
        
    catch ME
        fprintf('    NNV verification error: %s\n', ME.message);
        res = -1;
        time = -1;
    end
    
    % Calculate memory usage
    try
        final_vars = whos;
        final_memory = sum([final_vars.bytes]);
        memory_mb = (final_memory - initial_memory) / (1024 * 1024);
        if memory_mb < 0
            memory_mb = 0;
        end
    catch
        memory_mb = -1;
    end
end

function save_nnv_results_txt(res, NNs_props_timeout, N)
    % Save NNV-only results as organized .txt file
    
    try
        filename = 'NNV_tllverify_results.txt';
        nnv_results = res(:, 1);
        nnv_times = res(:, 2);
        nnv_memory = res(:, 3);
        
        fid = fopen(filename, 'w');
        if fid == -1
            error('Could not open file for writing: %s', filename);
        end
        
        fprintf(fid, '================================================================================\n');
        fprintf(fid, '                         NNV TLLVERIFY BENCHMARK RESULTS\n');
        fprintf(fid, '================================================================================\n');
        fprintf(fid, 'Benchmark Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fprintf(fid, 'Total Instances: %d\n', N);
        fprintf(fid, 'Verification Method: NNV (approx-star)\n');
        fprintf(fid, '================================================================================\n\n');
        
        % Calculate statistics for successful runs
        nnv_success_idx = nnv_results >= 0;
        
        if any(nnv_success_idx)
            nnv_avg_time = mean(nnv_times(nnv_success_idx));
            nnv_avg_memory = mean(nnv_memory(nnv_success_idx));
            nnv_max_time = max(nnv_times(nnv_success_idx));
            nnv_min_time = min(nnv_times(nnv_success_idx));
        else
            nnv_avg_time = 0; nnv_avg_memory = 0; nnv_max_time = 0; nnv_min_time = 0;
        end
        
        fprintf(fid, 'SUMMARY STATISTICS\n');
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'Successful instances:    %2d/%d (%.1f%%)\n', sum(nnv_success_idx), N, 100*sum(nnv_success_idx)/N);
        fprintf(fid, 'Failed instances:        %2d/%d (%.1f%%)\n', sum(nnv_results == -1), N, 100*sum(nnv_results == -1)/N);
        fprintf(fid, 'Timeout instances:       %2d/%d (%.1f%%)\n', sum(nnv_results == -2), N, 100*sum(nnv_results == -2)/N);
        
        if any(nnv_success_idx)
            fprintf(fid, 'Average time:            %.3f seconds\n', nnv_avg_time);
            fprintf(fid, 'Average memory:          %.2f MB\n', nnv_avg_memory);
            fprintf(fid, 'Max time:                %.3f seconds\n', nnv_max_time);
            fprintf(fid, 'Min time:                %.3f seconds\n', nnv_min_time);
        else
            fprintf(fid, 'Average time:            N/A (no successful runs)\n');
            fprintf(fid, 'Average memory:          N/A (no successful runs)\n');
            fprintf(fid, 'Max time:                N/A (no successful runs)\n');
            fprintf(fid, 'Min time:                N/A (no successful runs)\n');
        end
        
        fprintf(fid, '------------------------------------------------------------\n\n');
        
        % Detailed results section
        fprintf(fid, 'DETAILED RESULTS\n');
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, '%-30s | %-8s %-10s %-10s\n', 'Instance', 'Result', 'Time(s)', 'Memory(MB)');
        fprintf(fid, '------------------------------------------------------------\n');
        
        for i = 1:N
            [~, onnx_filename, ~] = fileparts(NNs_props_timeout.Var1{i});
            if length(onnx_filename) > 28
                onnx_filename = [onnx_filename(1:25) '...'];
            end
            
            nnv_status = format_result(nnv_results(i));
            
            fprintf(fid, '%-30s | %-8s %10.3f %10.2f\n', ...
                onnx_filename, nnv_status, nnv_times(i), nnv_memory(i));
        end
        
        fprintf(fid, '------------------------------------------------------------\n\n');
        
        % Legend section
        fprintf(fid, 'LEGEND\n');
        fprintf(fid, '------------------------------------------------------------\n');
        fprintf(fid, 'Result Codes:\n');
        fprintf(fid, '  SAT     = Property violated (counterexample found)\n');
        fprintf(fid, '  UNSAT   = Property verified (safe)\n');
        fprintf(fid, '  UNKN    = Unknown result (inconclusive)\n');
        fprintf(fid, '  ERROR   = Verification failed (internal error)\n');
        fprintf(fid, '  TIMEOUT = Exceeded time limit (120 seconds)\n');
        fprintf(fid, '\nNotes:\n');
        fprintf(fid, '  - Times shown in seconds, memory in megabytes\n');
        fprintf(fid, '  - Individual instance timeout: 120 seconds\n');
        fprintf(fid, '============================================================\n');
        
        fclose(fid);
        
        fprintf('\n-- RESULTS SAVED --\n');
        fprintf('File: %s\n', filename);
        fprintf('Successfully processed: %d/%d instances\n', sum(nnv_success_idx), N);
        fprintf('\n-- QUICK SUMMARY --\n');
        fprintf('NNV successful: %d/%d (%.1f%%)\n', sum(nnv_success_idx), N, 100*sum(nnv_success_idx)/N);
        fprintf('NNV timeouts: %d/%d (%.1f%%)\n', sum(nnv_results == -2), N, 100*sum(nnv_results == -2)/N);
        fprintf('NNV errors: %d/%d (%.1f%%)\n', sum(nnv_results == -1), N, 100*sum(nnv_results == -1)/N);
        
    catch ME
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        fprintf('Error saving results: %s\n', ME.message);
        rethrow(ME);
    end
end

function status_str = format_result(result_code)
    switch result_code
        case 1; status_str = 'SAT';
        case 0; status_str = 'UNSAT';
        case 2; status_str = 'UNKN';
        case -1; status_str = 'ERROR';
        case -2; status_str = 'TIMEOUT';
        otherwise; status_str = 'UNKN';
    end
end
