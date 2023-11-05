% This is a code for Agri-Fuse: A novel spatiotemporal fusion method designed for agricultural scenarios with diverse phenological change
% The authors would like to thank Prof. Xiaolin Zhu, Prof. Qunming Wang for providing the source code of Fit-Fc
%%%%Gu, Z., Chen, J., Chen, Y., Qiu, Y., Zhu, X., & Chen. X. (2023). “Agri-Fuse: A novel spatiotemporal fusion method designed for agricultural scenarios with diverse phenological changes”. Remote Sensing of Environment, 299, 113874.
%%%%Q. Wang, P. M. Atkinson. Spatio-temporal fusion for daily Sentinel-2 images. Remote Sensing of Environment, 2018, 204: 31–42.
%% Read data and set parameters
clc;clear;
currentdir = pwd;
addpath(strcat(currentdir(1,:), '\util\'));
addpath(strcat(currentdir(1,:), '\Fit-FC-master\'));
% %---------Remote sensing data------%
scale = 30;
DN_min = 0;
DN_max = 10000;

filedir = strcat(currentdir(1,:), '\demo\');

F1 = double(imread(strcat(filedir, "S2_07-04.tif")));
C1 = double(imread(strcat(filedir, "S3_07-04.tif")));

F2 = double(imread(strcat(filedir, "S2_08-20.tif")));
C2 = double(imread(strcat(filedir, "S3_08-20.tif")));

seg_raw = imread(strcat(filedir, "Segmentation_S2_07-04.tif"));
new_class = read_ENVIimagefile_class(strcat(filedir, 'iso_2-6c_20iter_2500minP_5cd_1-4bstack'));

%--Save---%
save_path = strcat(currentdir(1,:), '\result\');
name1 ='AgriFuse_without_spatial_filter';
name2 ='AgriFuse_with_spatial_filter';

%----Segementation parameters---%
thred_ndvi = 0.24; % to delete the boundary of class map
num_patch = 500; % To delete small objects less than 500 pixels
maj_perct = 60;  %The thresholds for the reassignment of the major categories of each band
%----Fusion parameters----%
pure_pr = 0.40; % to define a pure pixel helpful for unmixing
num_pure = 50; %
w_f = 0; %extend box strategy,defult as 0
w_s = 2;
%---Spatial Filter---%
w0 = 10;
N_S = 5;
%% Preprocessing
[F1] = remove_outlier(F1,0.01, 99.99, DN_min, DN_max);
[F2] = remove_outlier(F2,0.01, 99.99, DN_min, DN_max);
[nrows, ncols, nlayers] = size(F1);

C1 = imresize(C1, 1/scale, 'box');
C2 = imresize(C2, 1/scale, 'box');

F1_300 = imresize(F1, 1/scale, 'box');
F2_300 = imresize(F2, 1/scale, 'box');
%% Step1: Objected-post processing of the classification results
%Remove delete small objects
I = seg_raw(:,:,end);
count = tabulate(reshape(I,1,[]));
maj = find(count(:,2) >= num_patch);
maj_value = count(maj,1);

I_1 = zeros(size(I));
c = 1;
for i = 1:size(maj_value)
    ind = find(I == maj_value(i, 1));
    I_1(ind) = c;
    c = c + 1;
end
num_seg = size(unique(I_1),1);

%to combine the non-crop type into one class
F1_ndvi = (F1(:,:,4)-F1(:,:,3)) ./ (F1(:,:,4)+F1(:,:,3));
noVeg_mask_ind = F1_ndvi < thred_ndvi;

%to reassign of the major categories of each band
for k = 1:size(new_class,3)
    temp_class = new_class(:,:,k);
    for i = 1:num_seg-1
        ind = find(I_1 == i);
        %extract patch
        seg_class = temp_class(ind);
        %find the major class
        seg_count = tabulate(seg_class);
        %set majority percentage
        seg_maj_ind = find(seg_count(:,3) >= maj_perct);
        %update the class
        if ~isempty(seg_maj_ind)
            max_value = max(seg_count(seg_maj_ind,3));
            if max_value ~= 0
                max_ind = find(seg_count(:,3) == max_value);
                temp_class(ind) = seg_count(max_ind,1);
                %new_class(:,:,k) = temp_class;
            end
        end
    end
    
    num_class = size(unique(temp_class),1);
    temp_class(noVeg_mask_ind) = num_class+1;
    new_class(:,:,k) = temp_class;
end

%% Step2: Unmixing the coefficients
tic
C1_0 = F1_300;
C2_0 = F1_300+ (C2-C1);
F2_predict = F1;
[nrows, ncols, nlayers] = size(C1_0);

for k = 1:nlayers
    % purest pixels
    num_class = size(unique(new_class(:,:,k)),1);
    [fraction_w] = fraction_SUM_w(new_class(:,:,k), scale, w_s, w_f);  %[nrows, ncols,num_class]
    [F_mean_w] = mean_refl_w(new_class(:,:,k), F1(:,:,k), scale, w_s, w_f);
    ind = nan(nrows*ncols,num_class);
    
    for ic = 1:num_class
        f = reshape(fraction_w(:,:,ic),[],1);
        [value_f,ind_f] = sort(f,'descend');
        
        if value_f(num_pure) > pure_pr
            num_pure1 = find(value_f > pure_pr, 1, 'last' );
        else
            num_pure1 = num_pure;
        end
        %purest pixels
        CC1 = reshape(C1_0(:,:,k),[],1);
        CC2 = reshape(C2_0(:,:,k),[],1);
        CC1(ind_f(num_pure1+1:end)) = nan;
        CC2(ind_f(num_pure1+1:end)) = nan;
        % unchange pixels
        c_change = abs(CC2 - CC1);
        c_page = prctile(c_change,95,'all');
        ind_c =  c_change < c_page;
        ind(:,ic) = ind_c;
    end
    %the index of the purest pixels
    ind = sum(ind,2,'omitnan');
    ind(ind >= 1) = 1;
    ind = find(ind == 1);

    %%*C2
    matrix_a = reshape(C2_0(:,:,k),[],1); 
    matrix_a = matrix_a(ind); 

    %fFf
    temp_f = reshape(fraction_w(:, :, :), [], num_class);
    temp_f = temp_f(ind,:);

    temp_F = reshape(F_mean_w(:, :, :), [], num_class);
    temp_F = temp_F(ind,:);
    index_F = isnan(temp_F);temp_F(index_F) = 0;clear index_F

    matrix_fF = temp_f .* temp_F; %[num_coarse,num_class]
    matrix_fFf = [matrix_fF temp_f];
    
    %lsqr matrix_a = matrix_fFf * x;
    x = matrix_fFf\matrix_a; 

    %predict
    F2_predict(:, :, k) = predict_t2_fine_boundary(F1(:,:, k),...
        reshape(x(1:num_class,1),1,[]), reshape(x(num_class+1:end,1),1,[]),...
        new_class(:,:,k));
end

% remove the outliner
for i = 1:nrows*scale
    for j = 1:ncols*scale
        for k = 1:nlayers
            if F2_predict(i,j,k) <= DN_min || F2_predict(i,j,k) > DN_max
                F2_predict(i,j,k) = F1(i,j,k);
            end
        end
    end
end
%% Evaluation
toc
[~,rmse_all1] = acc_rmse(F2_predict,F2);
msgbox("finish!")

enviwrite(pagetranspose(F2_predict),strcat(save_path,name1));
%% Step3: Spatial filter !! time-consuming process
tic
A=(2*w0+1)/2;
Z0=zeros(size(F2_predict));
B1=3;%input('Enter the number of the red band in the Landsta cube: ');
B2=4;%input('Enter the number of the NIR band in the Landsta cube: ');
for i=1:nlayers
    Z(:,:,i)=STARFM_fast_2016_v2(Z0(:,:,i),Z0(:,:,i),F2_predict(:,:,i),F1(:,:,B1),F1(:,:,B2),w0,N_S,A);
end
%% Evaluation
F2_predict2 = Z;
[~,rmse_all12] = acc_rmse(F2_predict2,F2);
msgbox("finish!")
enviwrite(pagetranspose(F2_predict),strcat(save_path,name2));
toc
