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
    
    // image input
    bool im_copy = MatReadFloatMatrix(prhs[0], &im);
        
    MatReadPixelFeatureOpt(prhs[1], &opt);
    
    // initialize 
    InitPixelFeature(&im, &opt);
    
    // allocate return memory    
    FloatImage pixel_feat, pixel_coordinate;
    plhs[0] = MatAllocateFloatMatrix(&pixel_feat, opt.length, opt.num, 1);
    plhs[1] = MatAllocateGrids(&opt.grids);
    
    // process
    PixelFeature(&im, &pixel_feat, &opt);    
    FreeImage(&im);
}