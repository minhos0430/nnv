%% ACASXU_5_5_Verify.m
% Author: MinHo Sung
% Date: August 6, 2025 at 4:28 PM KST
% Location: Suwon-si, Gyeonggi-do

clc;
clear;

% =========================================================================
% --- AUTOMATIC RELATIVE PATH CONFIGURATION ---
% This section finds the benchmark directory relative to this script.
% =========================================================================

fprintf('--- Locating Benchmark Data from Script ---\n');

% Get the full path to the directory containing this script
% e.g., /home/msung/nnv/code/nnv/examples/NN/ACASXU
script_dir = fileparts(mfilename('fullpath'));
fprintf('Script directory is: %s\n', script_dir);

% Navigate up 6 levels to get to the common ancestor (/home/msung)
common_ancestor_path = fullfile(script_dir, '..', '..', '..', '..', '..', '..');

% Define the target benchmark folder relative to the common ancestor
target_benchmark_dir = fullfile('vnncomp2024_benchmarks', 'benchmarks', 'acasxu_2023');

% Construct the final, absolute path to the benchmark data
% This path will be correct no matter where /home/msung is.
base_benchmark_path = fullfile(common_ancestor_path, target_benchmark_dir);

fprintf('Successfully located benchmark path: %s\n\n', base_benchmark_path);


% =========================================================================
% --- SCRIPT EXECUTION ---
% The rest of your script now uses these correctly resolved paths.
% =========================================================================

% --- SETUP ---
% Set up the paths for the onnx and vnnlib files
onnx_path   = fullfile(base_benchmark_path, 'onnx');
vnnlib_path = fullfile(base_benchmark_path, 'vnnlib');
net_file    = fullfile(onnx_path, 'ACASXU_run2a_5_5_batch_2000.onnx');

% ... The rest of your verification script logic goes here ...

% Example of loading the network
fprintf('Loading network from: %s\n', net_file);
if ~isfile(net_file), error('Network file not found. Check calculated path.'); end
% net = importNetworkFromONNX(net_file, ...);

% ... and so on