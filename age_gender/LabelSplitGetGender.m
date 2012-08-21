function label_gender = LabelSplitGetGender(label_split)
label_gender = zeros(length(label_split),1);

label_gender(mod(label_split, 2) == 0) = 1;
label_gender(mod(label_split, 2) == 1 & label_split > 1) = 2;
label_gender(label_split == 1) = 0;