#ifndef PATCH_FEATURE_H
#define PATCH_FEATURE_H
        
#include "image.h"
#include "pixel_feature.h"
#include "coding.h"
#include "pooling.h"

// ***************************** //
// for patch feature extraction
                
// extract feature from rectangle patch option:
//      name: the patch feature name
//      func_init, func_proc: the patch feature function
//      param, nparam: the patch feature parameter
//      pixel_opt: use the pixel feature if use_pixel_feature == true
//      sizebin_{x,y}: patch step of each bin
//      length: patch featue length of each bin

struct PatchFeatureOpt;
typedef void (*FuncPatchFeatureInit)(FloatImage * img, PatchFeatureOpt * opt);
typedef void (*FuncPatchFeatureProc)(FloatImage * img, int x, int y, float * dst, PatchFeatureOpt * opt);

struct PatchFeatureOpt
{
    char * name;
    FuncPatchFeatureInit func_init;
    FuncPatchFeatureProc func_proc;
    
    int image_depth;
    double * param;
    int nparam;
    bool use_pixel_feature;
    PixelFeatureOpt pixel_opt; 
    CodingOpt pixel_coding_opt;
    
    int size_x, size_y;    
    int length;
    
    bool use_grids;    
    Grids grids;
    int  * coord;
    int num;
};


void InitPatchFeature(FloatImage * img, PatchFeatureOpt * opt);
void PatchFeature(FloatImage * img, FloatImage * patch_feat, PatchFeatureOpt * opt);

#ifdef MATLAB_COMPILE
void MatReadPatchFeatureOpt(const mxArray * mat_opt, PatchFeatureOpt * opt);
#endif
#endif