function [res, time, memory_mb] = verify_tllverify_nnv_with_memory(onnxF, vnnlibF, reachOpt)
    % Memory tracking
    initial_vars = whos;
    initial_memory = sum([initial_vars.bytes]);
    
    % load network
    loadOpt.InputDataFormat = "BC";
    nn = onnx2nnv(onnxF, loadOpt);
    
    % load property
    property = load_vnnlib(vnnlibF);
    IS = ImageStar(property.lb, property.ub);

    % Reach
    t = tic;
    R = nn.reach(IS, reachOpt);

    % Verify
    res = verifyNNV(R, property.prop);
    time = toc(t);
    
    % Calculate memory usage
    final_vars = whos;
    final_memory = sum([final_vars.bytes]);
    memory_mb = (final_memory - initial_memory) / (1024 * 1024);
end

% Keep the verifyNNV function as is...
