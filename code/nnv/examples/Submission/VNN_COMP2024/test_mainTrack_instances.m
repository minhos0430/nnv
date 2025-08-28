%% Simple Benchmarking - Target Categories Only

% Setup paths
vnncomp_path = "vnncomp2024_benchmarks/benchmarks/";
results_root = fullfile(pwd, "benchmark_results");
if ~exist(results_root,'dir'), mkdir(results_root); end

% CSV setup - updated header with peak RSS memory
csv_file = fullfile(results_root, "timing_results.csv");
if ~exist(csv_file, 'file')
    fid = fopen(csv_file,'w');
    fprintf(fid, "instance_id,peak_memory_mb,total_time_s,status\n");
    fclose(fid);
end

%% ACASXU
disp("Running ACAS XU...")
acas_path = vnncomp_path + "acasxu_2023/";
acas_instances = [
    "onnx/ACASXU_run2a_5_5_batch_2000.onnx", "vnnlib/prop_1.vnnlib";
    "onnx/ACASXU_run2a_5_5_batch_2000.onnx", "vnnlib/prop_2.vnnlib";
    "onnx/ACASXU_run2a_5_5_batch_2000.onnx", "vnnlib/prop_3.vnnlib";
    "onnx/ACASXU_run2a_5_5_batch_2000.onnx", "vnnlib/prop_4.vnnlib";
];

for i = 1:size(acas_instances,1)
    try
        benchmark_instance("acasxu", acas_path + acas_instances(i,1), acas_path + acas_instances(i,2), ...
                          sprintf("acasxu_%d", i), csv_file, results_root);
    catch ME
        fprintf("ERROR in acasxu_%d: %s. Continuing to next instance.\n", i, ME.message);
        continue;
    end
end

%% TLLVerify  
disp("Running TLLVerify...")
tll_path = vnncomp_path + "tllverifybench_2023/";
tll_instances = [
    "onnx/tllBench_n=2_N=M=16_m=1_instance_1_0.onnx", "vnnlib/property_N=16_0.vnnlib";
    "onnx/tllBench_n=2_N=M=64_m=1_instance_7_3.onnx", "vnnlib/property_N=64_3.vnnlib";
];

for i = 1:size(tll_instances,1)
    try
        benchmark_instance("tllverifybench", tll_path + tll_instances(i,1), tll_path + tll_instances(i,2), ...
                          sprintf("tllverify_%d", i), csv_file, results_root);
    catch ME
        fprintf("ERROR in tllverify_%d: %s. Continuing to next instance.\n", i, ME.message);
        continue;
    end
end

%% cGAN
disp("Running cGAN...")
cgan_path = vnncomp_path + "cgan_2023/";
cgan_instances = [
    "onnx/cGAN_imgSz32_nCh_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz32_nCh_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_prop_1_input_eps_0.020_output_eps_0.025.vnnlib";
    "onnx/cGAN_imgSz32_nCh_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_prop_2_input_eps_0.020_output_eps_0.025.vnnlib";
    "onnx/cGAN_imgSz32_nCh_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_prop_3_input_eps_0.020_output_eps_0.025.vnnlib";
    "onnx/cGAN_imgSz32_nCh_1_transposedConvPadding_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_transposedConvPadding_1_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz32_nCh_3.onnx", "vnnlib/cGAN_imgSz32_nCh_3_prop_0_input_eps_0.015_output_eps_0.020.vnnlib";
    "onnx/cGAN_imgSz32_nCh_3.onnx", "vnnlib/cGAN_imgSz32_nCh_3_prop_1_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz32_nCh_3.onnx", "vnnlib/cGAN_imgSz32_nCh_3_prop_2_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz32_nCh_3.onnx", "vnnlib/cGAN_imgSz32_nCh_3_prop_3_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz64_nCh_1.onnx", "vnnlib/cGAN_imgSz64_nCh_1_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz64_nCh_1.onnx", "vnnlib/cGAN_imgSz64_nCh_1_prop_1_input_eps_0.005_output_eps_0.010.vnnlib";
    "onnx/cGAN_imgSz64_nCh_1.onnx", "vnnlib/cGAN_imgSz64_nCh_1_prop_2_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz64_nCh_1.onnx", "vnnlib/cGAN_imgSz64_nCh_1_prop_3_input_eps_0.005_output_eps_0.010.vnnlib";
    "onnx/cGAN_imgSz64_nCh_3.onnx", "vnnlib/cGAN_imgSz64_nCh_3_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz64_nCh_3.onnx", "vnnlib/cGAN_imgSz64_nCh_3_prop_1_input_eps_0.010_output_eps_0.015.vnnlib";
    "onnx/cGAN_imgSz64_nCh_3.onnx", "vnnlib/cGAN_imgSz64_nCh_3_prop_2_input_eps_0.005_output_eps_0.010.vnnlib";
    "onnx/cGAN_imgSz64_nCh_3.onnx", "vnnlib/cGAN_imgSz64_nCh_3_prop_3_input_eps_0.010_output_eps_0.015.vnnlib";
];

for i = 1:size(cgan_instances,1)
    try
        benchmark_instance("cgan", cgan_path + cgan_instances(i,1), cgan_path + cgan_instances(i,2), ...
                          sprintf("cgan_%d", i), csv_file, results_root);
    catch ME
        fprintf("ERROR in cgan_%d: %s. Continuing to next instance.\n", i, ME.message);
        continue;
    end
end

%% Collins RUL
disp("Running Collins RUL...")
rul_path = vnncomp_path + "collins_rul_cnn_2023/";
rul_instances = [
    "onnx/NN_rul_full_window_20.onnx","vnnlib/robustness_2perturbations_delta5_epsilon10_w20.vnnlib";
    "onnx/NN_rul_full_window_20.onnx","vnnlib/robustness_16perturbations_delta5_epsilon10_w20.vnnlib";
    "onnx/NN_rul_full_window_20.onnx","vnnlib/monotonicity_CI_shift20_w20.vnnlib";
    "onnx/NN_rul_full_window_40.onnx","vnnlib/robustness_2perturbations_delta5_epsilon10_w40.vnnlib";
    "onnx/NN_rul_full_window_40.onnx","vnnlib/robustness_16perturbations_delta5_epsilon10_w40.vnnlib";  % Fixed .vnnx typo
    "onnx/NN_rul_full_window_40.onnx","vnnlib/monotonicity_CI_shift20_w40.vnnlib";
];

for i = 1:size(rul_instances,1)
    try
        benchmark_instance("collins_rul", rul_path + rul_instances(i,1), rul_path + rul_instances(i,2), ...
                          sprintf("collins_rul_%d", i), csv_file, results_root);
    catch ME
        fprintf("ERROR in collins_rul_%d: %s. Continuing to next instance.\n", i, ME.message);
        continue;
    end
end

fprintf("\nBenchmarking complete! Results: %s\n", csv_file);

%% Helper function with peak RSS memory tracking (like /usr/bin/time)
function benchmark_instance(category, onnx, vnnlib, inst_id, csv_file, results_root)
    fprintf("  Running %s...\n", inst_id);
    
    % Initialize peak RSS tracking
    peak_rss_mb = 0;
    mem_timer = [];
    
    % Instance directory
    inst_dir = fullfile(results_root, inst_id);
    if ~exist(inst_dir,'dir'), mkdir(inst_dir); end
    output_file = fullfile(inst_dir, "result.txt");
    
    % Set timeout and run verification
    timeout_seconds = 120;
    start_time = tic;
    status = 2; tTime = NaN; cexTime = NaN; reachTime = NaN;
    
    try
        % Start memory monitoring timer (sample every second)
        mem_timer = timer('Period', 1, 'ExecutionMode', 'fixedRate', ...
            'TimerFcn', @(~,~) update_peak_memory());
        start(mem_timer);
        
        % Run verification
        [status, tTime, cexTime, reachTime] = run_vnncomp2024_instance(category, onnx, vnnlib, output_file);
        
        % Stop memory monitoring
        stop(mem_timer);
        delete(mem_timer);
        mem_timer = [];
        
        % Check if we exceeded timeout after completion
        elapsed = toc(start_time);
        if elapsed >= timeout_seconds
            fprintf("    Instance completed but exceeded timeout (%.1fs)\n", elapsed);
            tTime = elapsed;
        end
        
    catch ME
        % Clean up timer
        if ~isempty(mem_timer)
            try stop(mem_timer); delete(mem_timer); catch, end
        end
        
        elapsed = toc(start_time);
        status = 2; tTime = elapsed; cexTime = NaN; reachTime = NaN;
        
        % Log error
        fid = fopen(fullfile(inst_dir, "error.txt"), 'w');
        fprintf(fid, "%s\n%s\n", ME.identifier, ME.message);
        fclose(fid);
        
        fprintf("    ERROR after %.1fs: %s\n", elapsed, ME.message);
    end
    
    % Nested function to update peak memory
    function update_peak_memory()
        current_rss = get_current_rss_mb();
        peak_rss_mb = max(peak_rss_mb, current_rss);
    end
    
    % Convert status to string
    if status == 0
        status_str = "SAT";
    elseif status == 1
        status_str = "UNSAT";
    elseif status == 2
        status_str = "UNKNOWN";
    else
        status_str = "ERROR";
    end
    
    % Log peak RSS data to CSV (comparable to /usr/bin/time)
    fid = fopen(csv_file, 'a');
    fprintf(fid, "%s,%.4f,%.4f,%s\n", inst_id, peak_rss_mb, tTime, status_str);
    fclose(fid);
    
    % Console output
    if ~isnan(tTime) && tTime >= timeout_seconds - 1
        fprintf("    Status: %s (%d), Time: %.2fs [LONG/TIMEOUT], Peak Memory: %.2f MB\n", status_str, status, tTime, peak_rss_mb);
    elseif ~isnan(cexTime) && ~isnan(reachTime)
        fprintf("    Status: %s (%d), Time: %.2fs (cex: %.2fs, reach: %.2fs), Peak Memory: %.2f MB\n", ...
                status_str, status, tTime, cexTime, reachTime, peak_rss_mb);
    else
        fprintf("    Status: %s (%d), Time: %.2fs, Peak Memory: %.2f MB\n", status_str, status, tTime, peak_rss_mb);
    end
end

%% Helper function to get current RSS in MB (like /usr/bin/time measures)
function rss_mb = get_current_rss_mb()
    if isunix
        try
            [status, result] = system('grep VmRSS /proc/self/status 2>/dev/null');
            if status == 0 && ~isempty(result)
                tokens = regexp(result, '(\d+)', 'tokens');
                if ~isempty(tokens)
                    rss_kb = str2double(tokens{1}{1});
                    rss_mb = rss_kb / 1024;  % Convert KB to MB
                else
                    rss_mb = 0;
                end
            else
                rss_mb = 0;
            end
        catch
            rss_mb = 0;
        end
    else
        % Fallback for non-Unix systems - could use tasklist on Windows
        rss_mb = 0;
    end
end
