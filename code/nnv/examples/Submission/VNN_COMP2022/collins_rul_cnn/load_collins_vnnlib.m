function [lb_input, ub_input, lb_output, ub_output] = load_collins_vnnlib(propertyFile)
    fprintf('Parsing VNNLIB file: %s\n', propertyFile);
    
    fileID = fopen(propertyFile,'r');
    content = fileread(propertyFile);
    fclose(fileID);
    
    % Determine input size
    if endsWith(propertyFile, "w40.vnnlib")
        lb_input = zeros(20,40);
        ub_input = zeros(20,40);
    else
        lb_input = zeros(20,20);
        ub_input = zeros(20,20);
    end
    
    % Parse input constraints (keep your existing logic)
    lines = split(content, newline);
    input_section = false;
    i = 1;
    
    for line_idx = 1:length(lines)
        line = strip(lines{line_idx});
        
        if contains(line, 'Input constraints')
            input_section = true;
            continue;
        elseif contains(line, 'Output constraints')
            input_section = false;
            break;
        end
        
        if input_section && ~isempty(line)
            tokens = split(line);
            if length(tokens) >= 4
                value_str = split(tokens{4}, ')');
                value = str2double(value_str{1});
                if contains(tokens{2}, '>=')
                    lb_input(i) = value;
                else
                    ub_input(i) = value;
                    i = i + 1;
                end
            end
        end
    end
    
    % **FIXED OUTPUT PARSING** - Safe array access
    fprintf('  Parsing output constraints...\n');
    
    % Parse upper bounds (<= Y_0 value)
    upper_pattern = '\(<= Y_0 ([\d.-]+)\)';
    upper_matches = regexp(content, upper_pattern, 'tokens');
    upper_bounds = [];
    
    fprintf('  Found %d upper bound matches\n', length(upper_matches));
    for i = 1:length(upper_matches)
        if ~isempty(upper_matches{i}) && length(upper_matches{i}) >= 1
            bound_val = str2double(upper_matches{i}{1});
            upper_bounds = [upper_bounds, bound_val];
            fprintf('    Upper bound: %.4f\n', bound_val);
        end
    end
    
    % Parse lower bounds (>= Y_0 value)
    lower_pattern = '\(>= Y_0 ([\d.-]+)\)';
    lower_matches = regexp(content, lower_pattern, 'tokens');
    lower_bounds = [];
    
    fprintf('  Found %d lower bound matches\n', length(lower_matches));
    for i = 1:length(lower_matches)
        if ~isempty(lower_matches{i}) && length(lower_matches{i}) >= 1
            bound_val = str2double(lower_matches{i}{1});
            lower_bounds = [lower_bounds, bound_val];
            fprintf('    Lower bound: %.4f\n', bound_val);
        end
    end
    
    % Combine bounds to create unsafe region
    if ~isempty(upper_bounds) && ~isempty(lower_bounds)
        % Collins OR logic: unsafe region is between bounds
        all_bounds = [upper_bounds, lower_bounds];
        unsafe_lb = min(all_bounds);
        unsafe_ub = max(all_bounds);
        
        lb_output = unsafe_lb;
        ub_output = unsafe_ub;
        
        fprintf('  ✅ Unsafe region: [%.4f, %.4f] - network should avoid this range\n', unsafe_lb, unsafe_ub);
    else
        fprintf('  ⚠️  No complete bounds found - using infinite range\n');
        lb_output = -inf;
        ub_output = inf;
    end
    
    fprintf('Final bounds - Input: [%.4f, %.4f], Output unsafe region: [%.4f, %.4f]\n', ...
            min(lb_input(:)), max(ub_input(:)), lb_output, ub_output);
end
