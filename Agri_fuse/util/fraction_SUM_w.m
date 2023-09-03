function [fraction] = fraction_SUM_w(map, scale,w, w_f)
%[fraction] = fraction_SUM(map, scale)
%   calculate fraction
map_extend = Extend_plane(map, w*scale);
[nrows, ncols] = size(map_extend);
num_class = size(unique(map),1);
fraction = zeros(nrows/scale, ncols/scale, num_class);

for i = 1+w:nrows/scale-w
    for j = 1+w:ncols/scale-w
        %range
        up = (i-1)*scale + 1 - w_f;
        down = i*scale + w_f;
        left = (j-1)*scale + 1 - w_f;
        right = j*scale + w_f;
        temp = map_extend(up:down, left:right);
        %fraction
        for k= 1:num_class
            index = find(temp == k);
            fraction(i, j, k) = size(index,1)/((down+1-up) * (right+1-left));
        end 
    end
end
fraction = fraction(1+w:end-w, 1+w:end-w, :);
end

