function relmap = LabelRelevenceMap(labelA, labelB)

relmap = double(bsxfun(@eq, labelA, labelB') & bsxfun(@and, labelA~=0, labelB'~=0)) ...
    - double(bsxfun(@or, labelA==0, labelB'==0));