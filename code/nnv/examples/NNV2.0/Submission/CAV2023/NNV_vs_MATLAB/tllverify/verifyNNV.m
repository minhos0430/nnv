function res = verifyNNV(R, prop)
    % NNV verification helper function
    nr = length(R);
    prop = prop{1};
    np = length(prop);
    
    if np == 1
        for k = 1:nr
            Set = R(k).toStar;
            S = Set.intersectHalfSpace(prop.Hg.G, prop.Hg.g);
            if isempty(S)
                res = 0; % UNSAT
            elseif isempty(Set.intersectHalfSpace(-prop.Hg.G, -prop.Hg.g))
                res = 1; % SAT
                break;
            else
                res = 2; % UNKNOWN
                break;
            end
        end
    else
        cp = 1; res = 0;
        while cp < np
            for k = 1:nr
                Set = R(k).toStar;
                S = Set.intersectHalfSpace(prop.Hg.G, prop.Hg.g);
                if isempty(S)
                    continue;
                elseif isempty(Set.intersectHalfSpace(-prop.Hg.G, -prop.Hg.g))
                    res = 1; % SAT
                    cp = np;
                else
                    res = 2; % UNKNOWN
                    break;
                end
            end
            cp = cp + 1;
        end
    end
end
