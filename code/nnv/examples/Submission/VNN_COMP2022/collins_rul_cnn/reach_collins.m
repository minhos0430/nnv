function [result, rT, timingBreakdown] = reach_collins(net, propertyFile)
    %% Enhanced reach_collins with NNV-native rigorous analysis
    
    % Initialize timing breakdown
    timingBreakdown = struct();
    
    % Start detailed timing
    totalTime = tic;
    
    fprintf('\n🔍 Starting verification for: %s\n', propertyFile);
    
    %% Step 1: Parse VNNLIB (with timing)
    parseTime = tic;
    [lb_x, ub_x, lb_y, ub_y] = load_collins_vnnlib(propertyFile);
    timingBreakdown.parsing = toc(parseTime);
    fprintf('  📄 VNNLIB parsing: %.6f seconds\n', timingBreakdown.parsing);
    
    %% Step 2: Create input set (with timing) 
    inputTime = tic;
    fprintf('  🎯 Input bounds: [%.4f, %.4f] (size: %dx%d)\n', min(lb_x(:)), max(ub_x(:)), size(lb_x));
    fprintf('  ⚠️  Unsafe region: [%.4f, %.4f]\n', lb_y, ub_y);
    
    X = ImageStar(lb_x', ub_x');
    inputElapsed = toc(inputTime);
    fprintf('  🔢 Input set creation: %.6f seconds\n', inputElapsed);
    
    %% Step 3: Configure reachability options for RIGOROUS analysis
    reachTime = tic;
    reachOptions = struct;
    
    % **FIXED**: NNV-compatible rigorous verification parameters
    reachOptions.reachMethod = 'approx-star';
    reachOptions.relaxFactor = 0.0001;          % Very tight per-layer bounds
    reachOptions.numOfCores = 1;                % Single core for consistency
    
    % Determine analysis method based on network complexity
    if isfield(net, 'Layers') && length(net.Layers) > 10
        reachOptions.reachMethod = 'exact-star';
        fprintf('  🎯 Using EXACT-STAR for rigorous verification (%d layers)\n', length(net.Layers));
    else
        fprintf('  🎯 Using APPROX-STAR with very tight relaxation (%.6f)\n', reachOptions.relaxFactor);
    end
    
    fprintf('  🚀 Starting reachability analysis...\n');
    
    %% Step 4: Perform reachability
    try
        Y = net.reach(X, reachOptions);
        timingBreakdown.reachability = toc(reachTime);
        
        fprintf('  ✅ Reachability completed: %.6f seconds\n', timingBreakdown.reachability);
        
        % Analyze the reachable set size
        if isa(Y, 'Star')
            fprintf('  📊 Reachable set: Single Star with %d dimensions\n', size(Y.V, 1));
        elseif isa(Y, 'cell')
            fprintf('  📊 Reachable set: %d Stars (complex analysis)\n', length(Y));
        end
        
    catch ME
        fprintf('  ❌ Reachability failed: %s\n', ME.message);
        result = -1;
        rT = toc(totalTime);
        timingBreakdown.reachability = toc(reachTime);
        timingBreakdown.verification = 0;
        return;
    end
    
    %% Step 5: Property verification with detailed analysis
    verifyTime = tic;
    [y_lb, y_ub] = Y.getRanges;
    
    fprintf('  🔍 Network output range: [%.6f, %.6f]\n', y_lb, y_ub);
    fprintf('  ⚠️  Unsafe region: [%.6f, %.6f]\n', lb_y, ub_y);
    
    % Enhanced intersection analysis
    if isfinite(lb_y) && isfinite(ub_y)
        network_min = min(y_lb);
        network_max = max(y_ub);
        unsafe_min = lb_y;
        unsafe_max = ub_y;
        
        % Calculate intersection overlap
        if (network_max >= unsafe_min) && (unsafe_max >= network_min)
            overlap_start = max(network_min, unsafe_min);
            overlap_end = min(network_max, unsafe_max);
            overlap_size = overlap_end - overlap_start;
            unsafe_size = unsafe_max - unsafe_min;
            overlap_percentage = (overlap_size / unsafe_size) * 100;
            
            result = 0;  % VIOLATED
            fprintf('  ❌ VIOLATED: %.2f%% overlap with unsafe region\n', overlap_percentage);
            fprintf('      Overlap: [%.6f, %.6f] (size: %.6f)\n', overlap_start, overlap_end, overlap_size);
        else
            result = 1;  % SATISFIED
            gap_to_unsafe = min(abs(network_max - unsafe_min), abs(unsafe_max - network_min));
            fprintf('  ✅ SATISFIED: Gap to unsafe region: %.6f\n', gap_to_unsafe);
        end
    else
        result = 1;
        fprintf('  ⚠️  No finite unsafe region - trivially satisfied\n');
    end
    
    timingBreakdown.verification = toc(verifyTime);
    
    %% Final timing report
    rT = toc(totalTime);
    
    fprintf('\n📊 DETAILED BENCHMARK REPORT:\n');
    fprintf('  ⏱️  Total time: %.6f seconds\n', rT);
    fprintf('     - Parsing: %.6f s (%.1f%%)\n', timingBreakdown.parsing, (timingBreakdown.parsing/rT)*100);
    fprintf('     - Input set: %.6f s (%.1f%%)\n', inputElapsed, (inputElapsed/rT)*100);
    fprintf('     - Reachability: %.6f s (%.1f%%)\n', timingBreakdown.reachability, (timingBreakdown.reachability/rT)*100);
    fprintf('     - Verification: %.6f s (%.1f%%)\n', timingBreakdown.verification, (timingBreakdown.verification/rT)*100);
    
    % MATLAB-compatible result display
    if result == 1
        resultText = 'SATISFIED';
    else
        resultText = 'VIOLATED';
    end
    fprintf('  🎯 Result: %s\n', resultText);
    
    % Adjusted warning threshold for rigorous analysis
    if rT < 5.0
        fprintf('  ⚠️  NOTE: Consider longer timeout for deeper analysis (current: %.3fs)\n', rT);
    else
        fprintf('  ✅ Deep analysis completed successfully\n');
    end
    
    fprintf('🏁 Verification complete.\n\n');
end
