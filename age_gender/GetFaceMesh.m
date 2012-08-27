function p_mesh = GetFaceMesh(p_landmark)

ldeyebr_idx = [8,13,11,15,9] + 1;
rdeyebr_idx = [25,31,27,29,24] + 1;

ldeye_idx = [5,3,7,1] + 1;
lueye_idx = [0,4,2,6,1] + 1;
rdeye_idx = [23,19,21,16] + 1;
rueye_idx = [17,22,18,20,16] + 1;

leye_corner_idx = 0+1;
reye_corner_idx = 17+1;
lmouth_corner_idx = 44+1;
rmouth_corner_idx = 45+1;
lnose_corner_idx = 36+1;
rnose_corner_idx = 38+1;

lnose_idx = [36,35,40,41] + 1;
rnose_idx = [38,37,42,43] + 1;
dnose_idx = [36,32,34,33,38] + 1;
cnose_idx = 39+1;


luface_idx = [66,67,68,69] + 1;
ruface_idx = [86,85,84,83] + 1;
lmface_idx = [70,71,72] + 1;
rmface_idx = [82,81,80] + 1;
dface_idx = [73,74,75,76,77,78,79] + 1;

umouth = [58,50,46, 54, 62] + 1;
dmouth = [44,61,53,49,57,65,45] + 1;


p_mesh = [p_landmark, ...
    GetInterpolate(p_landmark(ldeyebr_idx), p_landmark(lueye_idx), 1),...
    GetInterpolate(p_landmark(rdeyebr_idx), p_landmark(rueye_idx), 1),...
    GetInterpolate(p_landmark(cnose_idx), p_landmark([lnose_idx, rnose_idx, dnose_idx]), 1),...
    GetInterpolate(p_landmark(dnose_idx), p_landmark(umouth), 2),...
    GetInterpolate(p_landmark(dmouth), p_landmark(dface_idx), 3),...    
    GetInterpolate(p_landmark(ldeye_idx), p_landmark(lnose_idx), 3),...
    GetInterpolate(p_landmark(rdeye_idx), p_landmark(:, rnose_idx), 3),...
    GetInterpolate(p_landmark(lmouth_corner_idx), p_landmark([luface_idx, lmface_idx]), 3),...
    GetInterpolate(p_landmark(rmouth_corner_idx), p_landmark([ruface_idx, rmface_idx]), 3),...
    GetInterpolate(p_landmark(lnose_corner_idx), p_landmark(luface_idx), 3),...
    GetInterpolate(p_landmark(rnose_corner_idx), p_landmark(ruface_idx), 3),...
    GetInterpolate(p_landmark(leye_corner_idx), p_landmark(luface_idx), 3),...
    GetInterpolate(p_landmark(reye_corner_idx), p_landmark(ruface_idx), 3),...
    ];


function p = GetInterpolate(p1, p2, n)

npts = max(length(p1), length(p2));
p = complex(zeros(1,n*npts));
for i = 1:n
    p((i-1)*npts+1:i*npts) = bsxfun(@plus, i/(n+1)*p1, (n+1-i)/(n+1)*p2);
end