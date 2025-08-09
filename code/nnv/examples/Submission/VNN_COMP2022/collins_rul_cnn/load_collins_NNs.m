function [networks, names2idxs] = load_collins_NNs()
%% 1) Load networks (collins benchmarks)
vnnFolder = "../../../../../../vnncomp2024_benchmarks/benchmarks/";
benchmarkFolder = "collins_rul_cnn_2023/onnx/";
listNN = dir(vnnFolder+benchmarkFolder);
networks = {}; % create a cell array of neural networks
names = {};    % ← CHANGE: Initialize as cell array
idxs = [];     % ← Keep as numeric array
count = 1;
t = tic;
for h = 1:length(listNN)
    if endsWith(listNN(h).name, ".onnx")
        networks{count} = onnx2nnv(vnnFolder+benchmarkFolder+string(listNN(h).name));
        names{count} = listNN(h).name;
        idxs(count) = count;  % ← CHANGE: Use numeric indexing
        count = count + 1;
    end
end
t = toc(t);
names2idxs = containers.Map(names,idxs);
disp("All networks are loaded in " + string(t) + " seconds");
end
