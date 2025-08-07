%% Script to verify ACAS Xu property 3 (all 45 networks)
% This script is now self-contained and will run the NNV installer.

% =========================================================================
% --- AUTO-SETUP ---
% This block ensures NNV is installed for this specific session.
fprintf('--- Automatically setting up NNV path... ---\n');
% Find the location of this script
script_dir = fileparts(mfilename('fullpath'));
% Navigate up 3 levels to find the directory containing install.m
nnv_install_dir = fullfile(script_dir, '..', '..', '..');
% Run the installer
run(fullfile(nnv_install_dir, 'install.m'));
fprintf('--- NNV setup complete. Starting verification. ---\n');
% =========================================================================


% --- SETUP (Your original code now works) ---
% Get path to ACAS Xu data
acas_path = [nnvroot(), filesep, 'vnncomp2024_benchmarks', filesep, 'benchmarks', filesep, 'acasxu_2023', filesep];

% Iterate through all the networks to verify
networks = dir(fullfile(acas_path, "onnx", "ACASXU_run2a_5_5_batch_2000.onnx"));

% property to verify
vnnlib_file = fullfile(acas_path, "vnnlib", "prop_1.vnnlib");

% Define reachability parameters
reachOptions = struct;
reachOptions.reachMethod = 'approx-star';

% Preallocate memory for results
results = zeros(length(networks),1) - 1;
reachTime = zeros(length(networks),1);
networkNames = strings(length(networks), 1);

% Begin reachability
for i = 1:length(networks)

    networkNames(i) = networks(i).name;
    fprintf('Verifying network %d of %d: %s\n', i, length(networks), networkNames(i));

    % Load Network
    file = fullfile(networks(i).folder, networks(i).name);
    net = importNetworkFromONNX(file, InputDataFormats='BCSS'); % Using modern function

    % transform into NNV
    net = matlab2nnv(net);
    
    % Verify network
    t = tic;
    results(i) = net.verify_vnnlib(vnnlib_file, reachOptions);
    reachTime(i,1) = toc(t);

end

% --- SUMMARY ---
fprintf('\n--- Final Summary for Property 3 ---\n');
disp('Results (1=verified, 0=falsified, 2=unknown):');
summary_table = table(networkNames, results, reachTime);
disp(summary_table);

% Exit for command-line execution
exit;