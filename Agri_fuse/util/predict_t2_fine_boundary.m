function [F2] = predict_t2_fine_boundary(F1,a,b,map)
%function [F2] = predict_t2_ab(F1,a,b,map)
%   此处显示详细说明

[nrows, ncols] = size(F1);
F2 = zeros(nrows, ncols);
class_list = unique(map);
for i = 1:nrows
    for j = 1:ncols
        % c = map(i, j);
        c = find(class_list == map(i, j));
        if c ~= 0
            cof = a(c);
            cut = b(c);
            F2(i, j) = cof * F1(i, j) + cut;
        end
    end
end
end

