function [F_mean] = mean_refl_w(map, F, scale, w, w_f)
%function [F_mean] = mean_refl_w(map, F, scale, w, w_f)
%   此处显示详细说明 w*scale > w_f

[nrows, ncols, nlayers] = size(F);
F_extend = zeros(nrows+2*w*scale, ncols+2*w*scale, nlayers);
for k = 1:nlayers
    F_extend(:,:,k)= Extend_plane(F(:,:,k), w*scale);
end
[nrows, ncols, ~] = size(F_extend);

map_extend = Extend_plane(map, w*scale);

num_class = size(unique(map),1);
F_mean = zeros(nrows/scale, ncols/scale, num_class*nlayers);

for i = 1+w:nrows/scale-w
    for j = 1+w:ncols/scale-w
        %range
        up = (i-1)*scale + 1 - w_f;
        down = i*scale + w_f;
        left = (j-1)*scale + 1 - w_f;
        right = j*scale + w_f;
        
        map_win = map_extend(up:down, left:right);
        F_win = F_extend(up:down, left:right,:);
        %F_mean
        for k= 1:nlayers
            temp = F_win(:, :, k);
            for ic = 1:num_class
                index = map_win == ic;
                F_mean(i, j, (k-1)*num_class+ic) = mean(temp(index), 'all', 'omitnan');
            end

        end 
    end
end
F_mean = F_mean(1+w:end-w, 1+w:end-w, :);
end

