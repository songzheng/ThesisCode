function feat=features_hoglbp(image,sbin)
feat1=features_hog(image,sbin);
if size(image,3)==3
    image=double(rgb2gray(uint8(image)));
end

feat2=features_lbp(image,sbin);
%feat=cat(3,feat1,feat2, zeros(size(feat1,1), size(feat1,2)));
feat=cat(3,feat1,feat2);