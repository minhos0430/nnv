function [status, tTime, cexTime, reachTime] = run_vnncomp2024_instance(category, onnx, vnnlib, outputfile)

% single script to run all instances with approx-star only (with bounds checking)

t = tic; % start timer
status = 2; % unknown (to start with)

disp("We are running...")

%% 1) Load components

[net, nnvnet, needReshape, reachOptionsList] = load_vnncomp_network(category, onnx, vnnlib);

% Safe network layer access
try
    if size(net.Layers, 2) >= 1
        inputSize = net.Layers(1, 1).InputSize;
    else
        inputSize = net.Layers(1).InputSize;
    end
catch
    % Fallback for different network structures
    inputSize = net.Layers(1).InputSize;
end

% Load property to verify
property = load_vnnlib(vnnlib);
lb = property.lb; % input lower bounds
ub = property.ub; % input upper bounds
prop = property.prop; % output spec to verify

%% 2) SAT? - Random falsification

nRand = 100; % number of random inputs

% Initialize counterEx to avoid undefined variable
counterEx = nan;

% Choose how to falsify based on vnnlib file
try
    if ~isa(lb, "cell") && length(prop) >= 1 % one input, one output 
        if length(prop) >= 1 && isfield(prop{1}, 'Hg')
            counterEx = falsify_single(net, lb, ub, inputSize, nRand, prop{1}.Hg, needReshape);
        end
    elseif isa(lb, "cell") && length(lb) == length(prop) % multiple inputs, multiple outputs
        for spc = 1:min(length(lb), length(prop)) % Safe bounds
            if isfield(prop{spc}, 'Hg')
                counterEx = falsify_single(net, lb{spc}, ub{spc}, inputSize, nRand, prop{spc}.Hg, needReshape);
                if iscell(counterEx)
                    break
                end
            end
        end
    elseif isa(lb, "cell") && length(prop) >= 1 % can violate the output property from any of the input sets
        if isfield(prop{1}, 'Hg')
            for arr = 1:length(lb)
                counterEx = falsify_single(net, lb{arr}, ub{arr}, inputSize, nRand, prop{1}.Hg, needReshape);
                if iscell(counterEx)
                    break
                end
            end
        end
    else
        warning("Working on adding support to other vnnlib properties");
    end
catch ME
    warning('Error in falsification: %s', ME.message);
    counterEx = nan;
end

cEX_time = toc(t);

%% 3) UNSAT? - Approx-star verification

% Check if property was violated earlier
if iscell(counterEx)
    status = 0;
end

vT = tic;

if status == 2 && isa(nnvnet, "NN") % no counterexample found and supported for reachability

    try
        % Choose how to verify based on vnnlib file
        if ~isa(lb, "cell") && length(prop) >= 1 % one input, one output 

            if ~nnz(lb-ub) % lb == ub, not a set
                status = 1; % verified, since we already tested this            
            else
                while ~isempty(reachOptionsList)
                    reachOptions = reachOptionsList{1};
                    IS = create_input_set(lb, ub, inputSize, needReshape);
                    
                    % Compute reachability
                    ySet = nnvnet.reach(IS, reachOptions);
                    
                    % Verify property
                    status = verify_specification(ySet, prop);
                    
                    if status == 1 % verified, then stop
                        break
                    else
                        reachOptionsList = reachOptionsList(2:end);
                    end
                end
            end

        elseif isa(lb, "cell") && length(lb) == length(prop) % multiple inputs, multiple outputs
            
            local_status = 2*ones(length(lb),1); % track status for each specification
            
            parfor spc = 1:length(lb) % parallel computation
                tempStatus = 2; % Initialize as unknown
                
                if spc <= length(lb) && spc <= length(prop) % Safe bounds check
                    lb_spc = lb{spc};
                    ub_spc = ub{spc};

                    if ~nnz(lb_spc-ub_spc) % lb == ub, not a set
                        local_status(spc) = 1; % verified, since we already tested this                
                    else
                        reachOptPar = reachOptionsList;
                        
                        while ~isempty(reachOptPar)
                            reachOptions = reachOptPar{1};
                            IS = create_input_set(lb_spc, ub_spc, inputSize, needReshape);
                            
                            % Compute reachability
                            ySet = nnvnet.reach(IS, reachOptions);
                            
                            % Verify property
                            if isempty(ySet.C)
                                dd = ySet.V; DD = ySet.V;
                                ySet = Star(dd,DD);
                            end
                            
                            tempStatus = verify_specification(ySet, prop(spc));
                            
                            if tempStatus ~= 2 % verified, then stop (or falsified)
                                break
                            else
                                reachOptPar = reachOptPar(2:end);
                            end
                        end
                        local_status(spc) = tempStatus;
                    end
                end
            end

            % Check for the global verification result
            if all(local_status == 1)
                status = 1;
            else
                status = 2;
            end

        elseif isa(lb, "cell") && length(prop) >= 1 % one specification, multiple input definitions 

            local_status = 2*ones(length(lb),1); % track status for each specification
            
            parfor spc = 1:length(lb) % parallel computation
                tempStatus = 2; % Initialize as unknown
                reachOptPar = reachOptionsList;
                
                if spc <= length(lb) % Safe bounds check
                    lb_spc = lb{spc};
                    ub_spc = ub{spc};

                    if ~nnz(lb_spc-ub_spc) % lb == ub, not a set
                        local_status(spc) = 1; % verified, since we already tested this earlier                
                    else            
                        while ~isempty(reachOptPar)
                            reachOptions = reachOptPar{1};
                            IS = create_input_set(lb_spc, ub_spc, inputSize, needReshape);
                            
                            % Compute reachability
                            ySet = nnvnet.reach(IS, reachOptions);
                            
                            % Add verification status - safe property access
                            if length(prop) >= 1
                                tempStatus = verify_specification(ySet, prop(1));
                            else
                                tempStatus = 2; % Unknown if no property available
                            end
                            
                            if tempStatus ~= 2 % verified, then stop (or falsified)
                                break
                            else
                                reachOptPar = reachOptPar(2:end);
                            end
                            local_status(spc) = tempStatus;
                        end
                    end
                end
            end

            % Check for the global verification result
            if all(local_status == 1)
                status = 1;
            else
                status = 2;
            end

        else
            warning("Working on adding support to other vnnlib properties")
        end
    catch ME
        warning('Error in verification: %s', ME.message);
        status = 2; % Unknown on error
    end
end

vT = toc(vT);

%% 4) Process results

tTime = toc(t); % save total computation time

% Return timing components for benchmarking
cexTime = cEX_time;  % counterexample search time
reachTime = vT;      % reachability time

disp("Verification result: " + string(status));
disp("Counterexample search time: " + string(cEX_time));
disp("Reachability time: " + string(vT));
disp("Total Time: "+ string(tTime));
disp( " ");

% Write results to output file
if status == 0
    fid = fopen(outputfile, 'w');
    fprintf(fid, 'sat \n');
    fclose(fid);
    write_counterexample(outputfile, counterEx)
elseif status == 1
    fid = fopen(outputfile, 'w');
    fprintf(fid, 'unsat \n');
    fclose(fid);
elseif status == 2
    fid = fopen(outputfile, 'w');
    fprintf(fid, 'unknown \n');
    fclose(fid);
end

end

%% Helper functions

function IS = create_input_set(lb, ub, inputSize, needReshape)

    % Get input bounds
    if ~isscalar(inputSize)
        lb = reshape(lb, inputSize);
        ub = reshape(ub, inputSize);
    end

    % Format bounds into correct dimensions
    if needReshape == 1
        lb = permute(lb, [2 1 3]);
        ub = permute(ub, [2 1 3]);
    elseif needReshape == 2
        newSize = [inputSize(2) inputSize(1) inputSize(3:end)];
        lb = reshape(lb, newSize);
        lb = permute(lb, [2 1 3 4]);
        ub = reshape(ub, newSize);
        ub = permute(ub, [2 1 3 4]);
    end

    % Create input set
    IS = ImageStar(lb, ub); 

    % Delete constraints for non-interval dimensions
    xxx = find((lb-ub));
    xxx = reshape(xxx, [], 1);
    if numel(lb) ~= length(xxx)
        IS.C = IS.C(:,xxx);
        IS.pred_lb = IS.pred_lb(xxx);
        IS.pred_ub = IS.pred_ub(xxx);
        xxx = xxx + 1;
        IS.V = IS.V(:,:,:,[1;xxx]);
        IS.numPred = length(xxx);
    end

end

function [net,nnvnet,needReshape,reachOptionsList] = load_vnncomp_network(category, onnx, vnnlib)
% Load benchmarks with approx-star only for fast verification

    needReshape = 0;
    numCores = feature('numcores');

    if contains(category, 'collins_rul')
        net = importNetworkFromONNX(onnx);
        nnvnet = matlab2nnv(net);
        needReshape = 2;
        
        % Use approx-star only
        reachOptions = struct;
        reachOptions.reachMethod = 'approx-star';
        reachOptions.numCores = numCores;
        reachOptionsList{1} = reachOptions;

    elseif contains(category, "cgan")
        if ~contains(onnx, 'transformer')
            net = importNetworkFromONNX(onnx,"InputDataFormats", "BC", 'OutputDataFormats',"BC");
            nnvnet = matlab2nnv(net);
        else
            error("Transformer networks not supported");
        end
        
        % Use approx-star only
        reachOptions = struct;
        reachOptions.reachMethod = 'approx-star';
        reachOptions.numCores = numCores;
        reachOptionsList{1} = reachOptions;

    elseif contains(category, "tllverify")
        net = importNetworkFromONNX(onnx,"InputDataFormats", "BC", 'OutputDataFormats',"BC");
        nnvnet = matlab2nnv(net);
        
        % Use approx-star only
        reachOptions = struct;
        reachOptions.reachMethod = 'approx-star';
        reachOptions.numCores = numCores;
        reachOptionsList{1} = reachOptions;

    elseif contains(category, "acasxu")
        net = importNetworkFromONNX(onnx, "InputDataFormats","BCSS");
        nnvnet = matlab2nnv(net);
        
        % Use approx-star only
        reachOptions = struct;
        reachOptions.reachMethod = 'approx-star';
        reachOptions.numCores = numCores;
        reachOptionsList{1} = reachOptions;

    else
        error("Benchmark category '%s' not supported in this configuration", category)
    end

end

% Create random examples from input set (with bounds checking)
function xRand = create_random_examples(net, lb, ub, nR, inputSize, needReshape)
    try
        xB = Box(lb, ub);
        xRand = xB.sample(nR-2);
        xRand = [lb, ub, xRand];
        
        if needReshape
            if needReshape == 2
                newSize = [inputSize(2) inputSize(1) inputSize(3:end)];
                xRand = reshape(xRand, [newSize nR]);
                xRand = permute(xRand, [2 1 3 4]);
            else
                xRand = reshape(xRand, [inputSize nR]);
                xRand = permute(xRand, [2 1 3 4]);
            end
        else
            xRand = reshape(xRand,[inputSize nR]);
        end
        
        if isa(net, 'dlnetwork')
            if isa(net.Layers(1, 1), 'nnet.cnn.layer.ImageInputLayer')
                xRand = dlarray(xRand, "SSCB");
            elseif isa(net.Layers(1, 1), 'nnet.cnn.layer.FeatureInputLayer') || isa(net.Layers(1, 1), 'nnet.onnx.layer.FeatureInputLayer')
                xRand = dlarray(xRand, "CB");
            else
                disp(net.Layers(1,1));
                error("Unknown input format");
            end
        end
    catch ME
        warning('Error creating random examples: %s', ME.message);
        xRand = [];
    end
end

% Write counterexample to output file
function write_counterexample(outputfile, counterEx)
    try
        precision = '%.16g';
        fid = fopen(outputfile, 'a+');
        x = counterEx{1};
        x = reshape(x, [], 1);
        fprintf(fid,'(');
        for i = 1:length(x)
            fprintf(fid, "(X_" + string(i-1) + " " + num2str(x(i), precision)+ ")\n");
        end
        y = counterEx{2};
        y = reshape(y, [], 1);
        for j =1:length(y)
            fprintf(fid, "(Y_" + string(j-1) + " " + num2str(y(j), precision)+ ")\n");
        end
        fprintf(fid, ')');
        fclose(fid);
    catch ME
        warning('Error writing counterexample: %s', ME.message);
    end
end

% Falsification function (random simulation) with bounds checking
function counterEx = falsify_single(net, lb, ub, inputSize, nRand, Hs, needReshape)
    counterEx = nan;
    
    try
        xRand = create_random_examples(net, lb, ub, nRand, inputSize, needReshape);
        
        if isempty(xRand)
            return;
        end
        
        s = size(xRand);
        n = length(s);
        
        % Safe iteration bounds
        maxIterations = s(end); % Use last dimension size
        
        for i = 1:maxIterations
            if i > size(xRand, n) % Additional safety check
                break;
            end
            
            x = get_example(xRand, i);
            if isempty(x)
                continue;
            end
            
            yPred = predict(net, x);
            if isa(x, 'dlarray')
                x = extractdata(x);
                yPred = extractdata(yPred);
            end
            yPred = reshape(yPred, [], 1);
            
            for h = 1:length(Hs)
                if Hs(h).contains(double(yPred))
                    n = numel(x);
                    if needReshape == 2
                        x = permute(x, [2 1 3]);
                    elseif needReshape == 1
                        if ndims(x) == 3
                            x = permute(x, [2 1 3]);
                        end
                    end
                    counterEx = {x; yPred};
                    return; % Early exit on success
                end
            end
        end
    catch ME
        warning('Error in falsification: %s', ME.message);
        counterEx = nan;
    end
end

% Get random example from input set (with comprehensive bounds checking)
function x = get_example(xRand, i)
    x = [];
    
    try
        s = size(xRand);
        n = length(s);
        
        % Debug output for troubleshooting
        % fprintf('Debug: xRand size = [%s], requesting index %d\n', num2str(s), i);
        
        if n == 4
            if i <= s(4)
                x = xRand(:,:,:,i);
            else
                warning('Index %d exceeds dimension 4 size (%d)', i, s(4));
                return;
            end
        elseif n == 3
            if i <= s(3)
                x = xRand(:,:,i);
            else
                warning('Index %d exceeds dimension 3 size (%d)', i, s(3));
                return;
            end
        elseif n == 2
            if i <= s(2)
                x = xRand(:,i);
            else
                warning('Index %d exceeds dimension 2 size (%d)', i, s(2));
                return;
            end
            xsize = size(x);
            if xsize(1) ~= 1 && ~isa(x,"dlarray")
                x = x';
            end
        else
            error("Unexpected InputSize = "+string(s));
        end
    catch ME
        warning('Error getting example %d: %s', i, ME.message);
        x = [];
    end
end
