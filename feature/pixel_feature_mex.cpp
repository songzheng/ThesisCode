#include <mexutils.h>
#define MATLAB_COMPILE
#include "pixel_feature.h"


// Raw pixel coding extraction
// •	Raw Pixel (Color / Gray) "PixelGray8N" "PixelGray4N" "PixelColor"
// •	Local Normalized Pixel (center-surround)
// •	Gradient
// •	High Order Moment
// •	Linear Filter
// Input: Image
// Output: Dense Image Feature

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
        
    FloatImage im;    
    PixelFeatureOpt opt;
    FloatImage pixel_feat;
    
    // image input
    bool im_copy = MatReadFloatMatrix(prhs[0], &im);
        
    MatReadPixelFeatureOpt(prhs[1], &opt);
    
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
    
    // initialize 
    InitPixelFeature(&im, &opt);
    
    // allocate return memory    
    plhs[0] = MatAllocateFloatMatrix(&pixel_feat, opt.length, opt.num, 1);
    
    if(opt.use_grids)
        plhs[1] = MatAllocateGrids(&opt.grids);
    
    // process
    PixelFeature(&im, &pixel_feat, &opt);   
    
    if(im_copy)
        FreeImage(&im);
}