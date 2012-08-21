
#include <mexutils.h>
#include "patch_feature.h"

// Patch-level feature coding extraction
// •	HOG
// •	LBP
// •	BIF
// •	Color Histogram
// •	Learning based descriptor
// Input: Image
// Output: Dense Patch Feature

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    FloatImage im;
    PatchFeatureOpt opt;
    
    // image input
    bool im_copy = MatReadFloatMatrix(prhs[0], &im);
    
    // whether use default grids
    opt.use_grids = mxIsEmpty(prhs[1]);
    
    // option
    MatReadPatchFeatureOpt(prhs[2], &opt);
    
    if(!opt.use_grids)
    {
        nlhs = 1;
        if(mxGetClassID(prhs[1]) != mxINT32_CLASS && mxGetM(prhs[1]) != 2)
            mexErrMsgTxt("Wrong Patch Coordinate Input");
        
        // self defined patch position
        opt.coord = (int *)mxGetPr(prhs[1]);               
        opt.num = mxGetN(prhs[1]);
    }
    else
    {
        nlhs = 2;
        opt.coord = NULL;
        opt.num = 0;
    }
    
    InitPatchFeature(&im, &opt);
    
    if(opt.use_grids)        
        plhs[1] = MatAllocateGrids(&opt.grids);
    
    FloatImage patch_feat;
//     mexPrintf("%d, %d\n", opt.length, opt.num);
    plhs[0] = MatAllocateFloatMatrix(&patch_feat, opt.length, opt.num, 1);    
    
    PatchFeature(&im, &patch_feat, &opt);
    
    if (im_copy)
        FreeImage(&im);
    
}