
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
    FloatImage patch_feat;
    
    // image input
    bool im_copy = MatReadFloatMatrix(prhs[0], &im);
    
    // option
    MatReadPatchFeatureOpt(prhs[1], &opt);
    
    
    opt.use_grids = false;
    // whether use default grids
    if(nrhs < 3 || mxIsEmpty(prhs[2]))
        opt.use_grids = true;    
    
    
    if(!opt.use_grids)
    {
        nlhs = 1;
        if(mxGetClassID(prhs[2]) != mxINT32_CLASS && mxGetM(prhs[2]) != 2)
            mexErrMsgTxt("Wrong Patch Coordinate Input");
        
        // self defined patch position
        opt.coord = (int *)mxGetPr(prhs[2]);               
        opt.num = mxGetN(prhs[2]);
    }
    else
    {
        nlhs = 2;
        opt.coord = NULL;
    }
    
    InitPatchFeature(&im, &opt);
    
    // allocate return variables
    plhs[0] = MatAllocateFloatMatrix(&patch_feat, opt.length, opt.num, 1);    
    if(opt.use_grids)        
        plhs[1] = MatAllocateGrids(&opt.grids);
    
//     mexPrintf("%d, %d\n", opt.length, opt.num);
    
    // process
    PatchFeature(&im, &patch_feat, &opt);
    
    if (im_copy)
        FreeImage(&im);
    
}