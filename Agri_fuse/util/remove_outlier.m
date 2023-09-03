function [F1] = remove_outlier(F1,p1,p2,DN_min,DN_max)
%UNTITLED11 此处显示有关此函数的摘要
%   此处显示详细说明
for k = 1:size(F1,3)
    temp1 = F1(:, :, k);
    Ypage = prctile(temp1,[p1,p2],'all');
    
    index_min1 = temp1 >= DN_min & temp1 > Ypage(1);
    min_v = min(temp1(index_min1));
    index_min2 = temp1 < DN_min | temp1 <= Ypage(1);
    temp1(index_min2) = min_v;
    
    index_max1 = temp1 <= DN_max & temp1 < Ypage(2);
    max_v = max(temp1(index_max1));
    index_max2 = temp1 > DN_max | temp1>= Ypage(2);
    temp1(index_max2) = max_v;
    
    F1(:, :, k) = temp1;
end
end

