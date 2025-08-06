clc;
clear;



model_file_path = '../../../../../../vnncomp2024_benchmarks/benchmarks/acasxu_2023/onnx/ACASXU_run2a_5_5_batch_2000.onnx'; % <-- EDIT THIS

% 2. Provide the full, absolute path to the VNNLIB property file.
%    Example: '/home/msung/benchmarks/acas_xu/vnnlib/prop_1.vnnlib'
vnnlib_file_path = '../../../../../../vnncomp2024_benchmarks/benchmarks/acasxu_2023/vnnlib/prop_2.vnnlib'; % <-- EDIT THIS


% =========================================================================
% --- SCRIPT EXECUTION (No edits needed below this line) ---
% =========================================================================

% --- SETUP ---
fprintf('--- Initializing Verification ---\n');
fprintf('Model: %s\n', model_file_path);
fprintf('Property: %s\n\n', vnnlib_file_path);

% Check if files exist before starting
if ~isfile(model_file_path)
    error('Network file not found. Please check the path: %s', model_file_path);
end
if ~isfile(vnnlib_file_path)
    error('VNNLIB file not found. Please check the path: %s', vnnlib_file_path);
end

% Define reachability parameters
reachOptions = struct;
reachOptions.reachMethod = 'approx-star';
reachOptions.display = 'on';

% --- VERIFICATION ---
% Load Network
[~, net_name, ~] = fileparts(model_file_path);
fprintf('Loading network: %s\n', net_name);
net = importNetworkFromONNX(model_file_path, InputDataFormats='BCSS');
net = matlab2nnv(net);
fprintf('Network loaded.\n\n');
    
% Verify network against the single property
fprintf('Starting verification...\n');
t = tic;
result = -1; % Default result if verification fails
try
    result = net.verify_vnnlib(vnnlib_file_path, reachOptions);
catch ME
    fprintf('ERROR during verification: %s\n', ME.message);
    result = -3; % Use -3 to indicate a verification error
end
reachTime = toc(t);

% --- SUMMARY ---
fprintf('\n--- Verification Summary ---\n');
[~, prop_name, ~] = fileparts(vnnlib_file_path);
disp('Result Codes (1=verified, 0=falsified, 2=unknown, -3=error)');
summary_table = table(string(net_name), string(prop_name), result, reachTime, 'VariableNames', {'Network', 'Property', 'Result', 'Time_sec'});
disp(summary_table);

% Ensure MATLAB exits for command-line execution
exit;