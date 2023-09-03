function [rmse,rmse_all] = acc_rmse(pred_img,ref_img)
%[rmse] = acc_rmse(img,ref_img)
%   obtain rmse of each band

[nr,nc,nb] = size(pred_img);
rmse = zeros(nr,nc,nb);
rmse_all = zeros(nb+1,1);

for inb = 1:nb
    Ypred = pred_img(:,:,inb);
    Yobsv = ref_img(:,:,inb);
    
    rmse(:,:,inb) = sqrt((Ypred-Yobsv).^2);
    rmse_all(inb,1)= sqrt(mean((Ypred-Yobsv).^2,'all','omitnan'));
end
rmse_all(end,1) = mean(rmse_all(1:end-1,1),'omitnan');
end

