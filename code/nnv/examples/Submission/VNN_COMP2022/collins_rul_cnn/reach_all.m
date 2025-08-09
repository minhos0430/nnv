%% Enhanced reach_all.m - Platform compatible (no memory() dependency)
diary('collins_detailed_benchmark.txt');
diary on;

fprintf('🔬 COLLINS RUL CNN COMPREHENSIVE BENCHMARK\n');
fprintf('==========================================\n');
fprintf('Start time: %s\n', datestr(now));
fprintf('MATLAB version: %s\n', version);
fprintf('Platform: %s\n', computer);

%% 1) Load networks with timing
networkTime = tic;
[networks, name2idx] = load_collins_NNs();
networkLoadTime = toc(networkTime);
fprintf('📁 Network loading time: %.6f seconds\n\n', networkLoadTime);

%% 2) Verify all properties with detailed tracking
csvFile = "instances.csv";
benchmarkFolder = "../../../../../../vnncomp2024_benchmarks/benchmarks/collins_rul_cnn_2023/";
NNs_props_timeout = readtable(benchmarkFolder+csvFile);

% Initialize comprehensive results tracking
verified = zeros(height(NNs_props_timeout),1);
reachTimes = zeros(height(NNs_props_timeout),1);
parseTime = zeros(height(NNs_props_timeout),1);
reachabilityTime = zeros(height(NNs_props_timeout),1);
verificationTime = zeros(height(NNs_props_timeout),1);
errorMsgs = [];

% System-level monitoring
systemStartTime = tic;

fprintf('🧪 STARTING %d VERIFICATION INSTANCES\n', height(NNs_props_timeout));
fprintf('======================================\n');

for i=1:height(NNs_props_timeout)
    instanceStart = tic;
    
    name = split(NNs_props_timeout.Var1{i},'/');
    name = name{2};
    net = networks{name2idx(name)};
    propertyFile = benchmarkFolder + string(NNs_props_timeout.Var2{i});
    
    fprintf('🔬 INSTANCE %d/%d: %s\n', i, height(NNs_props_timeout), name);
    fprintf('   Property: %s\n', NNs_props_timeout.Var2{i});
    
    try
        % Call enhanced verification with detailed timing
        [result, rT, timingBreakdown] = reach_collins(net, propertyFile);
        
        verified(i) = result;
        reachTimes(i) = rT;
        parseTime(i) = timingBreakdown.parsing;
        reachabilityTime(i) = timingBreakdown.reachability;
        verificationTime(i) = timingBreakdown.verification;
        
        instanceTime = toc(instanceStart);
        
        fprintf('📊 INSTANCE %d SUMMARY:\n', i);
        
        % MATLAB-compatible conditional formatting
        if result == 1
            resultStr = '✅ SATISFIED';
        elseif result == 0
            resultStr = '❌ VIOLATED';
        else
            resultStr = '⚠️ ERROR';
        end
        fprintf('   Result: %s\n', resultStr);
        
        fprintf('   Total time: %.6f seconds\n', rT);
        fprintf('   Breakdown: Parse=%.6f, Reach=%.6f, Verify=%.6f\n', ...
                parseTime(i), reachabilityTime(i), verificationTime(i));
        fprintf('   Overhead: %.6f seconds\n\n', instanceTime - rT);
        
        % Force cleanup between instances
        clear Y X reachSet;
        
    catch ME
        verified(i) = -1;
        instanceTime = toc(instanceStart);
        
        fprintf('❌ ERROR in instance %d:\n', i);
        fprintf('   Error: %s\n', ME.message);
        fprintf('   Time: %.6f seconds\n', instanceTime);
        if length(ME.stack) > 0
            fprintf('   Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        
        errorMsgs = [errorMsgs; ME];
        warning("Verification of network " + string(name) + " WITH specification " + string(NNs_props_timeout.Var2{i}) + " FAILED");
    end
end

systemTotalTime = toc(systemStartTime);

%% Comprehensive benchmark report
fprintf('\n🏆 COLLINS RUL CNN FINAL BENCHMARK REPORT\n');
fprintf('==========================================\n');
fprintf('Total verification time: %.6f seconds\n', systemTotalTime);
fprintf('Network loading time: %.6f seconds (%.1f%%)\n', networkLoadTime, (networkLoadTime/systemTotalTime)*100);

% Filter out error cases for statistics
validIndices = verified ~= -1;
if sum(validIndices) > 0
    fprintf('Average time per instance: %.6f seconds\n', mean(reachTimes(validIndices)));
    fprintf('Median time per instance: %.6f seconds\n', median(reachTimes(validIndices)));
    fprintf('Fastest instance: %.6f seconds\n', min(reachTimes(validIndices)));
    fprintf('Slowest instance: %.6f seconds\n', max(reachTimes(validIndices)));
    
    fprintf('\n⏱️ TIMING BREAKDOWN ANALYSIS:\n');
    fprintf('Average parsing time: %.6f seconds (%.1f%%)\n', mean(parseTime(validIndices)), mean(parseTime(validIndices))/mean(reachTimes(validIndices))*100);
    fprintf('Average reachability time: %.6f seconds (%.1f%%)\n', mean(reachabilityTime(validIndices)), mean(reachabilityTime(validIndices))/mean(reachTimes(validIndices))*100);
    fprintf('Average verification time: %.6f seconds (%.1f%%)\n', mean(verificationTime(validIndices)), mean(verificationTime(validIndices))/mean(reachTimes(validIndices))*100);
end

fprintf('\n📈 VERIFICATION RESULTS:\n');
fprintf('Properties SATISFIED: %d (%.1f%%)\n', sum(verified==1), (sum(verified==1)/height(NNs_props_timeout))*100);
fprintf('Properties VIOLATED: %d (%.1f%%)\n', sum(verified==0), (sum(verified==0)/height(NNs_props_timeout))*100);
fprintf('Errors/timeouts: %d (%.1f%%)\n', sum(verified==-1), (sum(verified==-1)/height(NNs_props_timeout))*100);

% Save detailed results
results_table = table((1:height(NNs_props_timeout))', NNs_props_timeout.Var1, NNs_props_timeout.Var2, ...
                     verified, reachTimes, parseTime, reachabilityTime, verificationTime, ...
                     'VariableNames', {'Instance', 'Network', 'Property', 'Result', 'Total_Time_sec', 'Parse_Time_sec', 'Reach_Time_sec', 'Verify_Time_sec'});
writetable(results_table, 'collins_detailed_results.csv');
fprintf('\nDetailed results saved to: collins_detailed_results.csv\n');

fprintf('\n⚠️ BENCHMARK QUALITY CHECK:\n');
suspiciouslyFast = sum(reachTimes < 0.5 & verified ~= -1);
if suspiciouslyFast > 0
    fprintf('⚠️ %d instances completed in <0.5 seconds - verification may be too shallow\n', suspiciouslyFast);
    fprintf('   Consider using exact-star reachability or tighter relaxation factors\n');
end

diary off;
fprintf('\n📝 Complete benchmark log saved to: collins_detailed_benchmark.txt\n');
