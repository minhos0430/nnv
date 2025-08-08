function [res, time, memory_mb] = verify_tllverify_matlab_with_memory(onnxF, vnnlibF)
    % Memory tracking using MATLAB's whos function
    initial_vars = whos;
    initial_memory = sum([initial_vars.bytes]);
    
    % Load network
    net = importONNXNetwork(onnxF, InputDataFormats="BC");
    
    % Remove ElementWise and output layers
    Layers = net.Layers;
    n = length(Layers);
    good_idxs = [];
    for i=1:(n-1)
        if isa(Layers(i), 'nnet.onnx.layer.ElementwiseAffineLayer')
            Layers(i-1).Bias = Layers(i).Offset;
        else
            good_idxs = [good_idxs i];
        end
    end
    Layers = Layers(good_idxs);
    net = dlnetwork(Layers);
    
    % Load vnnlib property
    [XLower, XUpper, output] = load_vnnlib_matlab(vnnlibF);
    XLower = dlarray(XLower, "CB");
    XUpper = dlarray(XUpper, "CB");

    % Reachability Computation
    t = tic;
    [lb, ub] = estimateNetworkOutputBounds(net, XLower, XUpper);
    res = verifyMAT(lb, ub, output);
    time = toc(t);
    
    % Calculate memory usage
    final_vars = whos;
    final_memory = sum([final_vars.bytes]);
    memory_mb = (final_memory - initial_memory) / (1024 * 1024);
end

function res = verifyMAT(lb, ub, output)
    result = ones(length(output),1);
    for i = 1:length(output)
        result(i) = eval(output{i}{1});
        if ~result(i)
            result(i) = eval(output{i}{2});
            if ~result(i)
                result(i) = 2; % unknown
            else
                result(i) = 0; % unsat
                break;
            end
        end
    end
    
    if all(result == 1)
        res = 1;
    elseif any(result == 0)
        res = 0;
    else
        res = 2;
    end
end
