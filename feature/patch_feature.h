#ifndef PATCH_FEATURE_H
#define PATCH_FEATURE_H
        
#include "image.h"
#include "pixel_feature.h"

// coding with pixel coding method
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

// ***************************** //

// entry function for patch feature
void InitPatchFeature(FloatImage * img, PatchFeatureOpt * opt)
{    
    if(opt->use_pixel_feature)
    {
        InitPixelFeature(img, &opt->pixel_opt);
        InitCoding(&opt->pixel_coding_opt);
    
        ASSERT(opt->pixel_opt.length == opt->pixel_coding_opt.length_input);
        opt->length = opt->pixel_coding_opt.length;
    }
    else
    {
    	opt->func_init(img, opt);
    }
    
    if(opt->use_grids)
    {
        opt->coord = NULL;
        if(opt->num == 0)
        {            
            opt->grids = CalculateGrids(img, opt->size_y, opt->size_x, opt->size_y/2, opt->size_x/2);
            opt->num = opt->grids.num_x * opt->grids.num_y;
        }
    }
    else
    {
        ASSERT(opt->coord != NULL && opt->num != 0);
    }
}

void PatchFeature(FloatImage * img, FloatImage * patch_feat, PatchFeatureOpt * opt)
{        
    int size_x = opt->size_x, 
            size_y = opt->size_y;     
    int patch_num = opt->num;
    
    int * coord;
    
    if(opt->use_grids)
        coord = NewCoordianteFromGrids(&opt->grids);
    else
        coord = opt->coord;
    
    if(opt->use_pixel_feature)
    {
        FloatMatrix pixel_feat, pixel_coord;
        FloatSparseMatrix pixel_coding;
        PixelFeatureOpt * pixel_opt = &opt->pixel_opt;
        CodingOpt * pixel_coding_opt = &opt->pixel_coding_opt;
        
        
        // cache pixel level feature
        AllocateImage(&pixel_feat,
                pixel_opt->length,
                pixel_opt->num,
                1);
        
        PixelFeature(img, &pixel_feat, pixel_opt);
        
        // cache pixel level coded feature
        AllocateSparseMatrix(&pixel_coding,
                pixel_coding_opt->length,
                pixel_opt->num,
                pixel_coding_opt->block_num,
                pixel_coding_opt->block_size);
        
        Coding(&pixel_feat, &pixel_coding, pixel_coding_opt);
        
        FreeImage(&pixel_feat);
        
        PoolingSpatial(&pixel_coding, &pixel_opt->grids,
                patch_feat, coord,
                size_y, size_x);
                
        FreeSparseMatrix(&pixel_coding);
    }
    else
    {    
        // patch level
        for(int n=0; n<patch_num; n++){
            int y = *(coord++);
            int x = *(coord++);
            float * dst = patch_feat->p + n*opt->length;
            opt->func_proc(img, x, y, dst, opt);
        }
    }
    
    
    if(opt->use_grids)
        FREE(coord);
    
}

int PatchFeatureSelect(PatchFeatureOpt *opt)
{
    // not implement yet
    return 0;
}

#ifdef MATLAB_COMPILE
// matlab helper function
void MatReadPatchFeatureOpt(const mxArray * mat_opt, PatchFeatureOpt * opt)
{    
    // get feature name
    mxArray * mx_name = mxGetField(mat_opt, 0, "name");
    ASSERT(mx_name != NULL);
    opt->name = mxArrayToString(mx_name);
    
    mxArray * mx_pixel_opt = mxGetField(mat_opt, 0, "pixel_opt");
    
    if(mx_pixel_opt != NULL && !mxIsEmpty(mx_pixel_opt))
    {  
        MatReadPixelFeatureOpt(mx_pixel_opt, &opt->pixel_opt);      
        opt->use_pixel_feature = true;
        opt->param = NULL;
        opt->nparam = 0;
        
        mxArray * mx_pixel_coding_opt = mxGetField(mat_opt, 0, "pixel_coding_opt");
        ASSERT(mx_pixel_coding_opt != NULL);
        MatReadCodingOpt(mx_pixel_coding_opt, &opt->pixel_coding_opt);
    }
    else
    {
        // use patch feature
        opt->use_pixel_feature = false;
        // get parameters
        mxArray * mx_param = mxGetField(mat_opt, 0, "param");
        if(mx_param == NULL || mxGetNumberOfElements(mx_param) == 0)
        {
            opt->param = NULL;
            opt->nparam = 0;
        }
        else
        {
            opt->param = (double *)mxGetPr(mx_param);
            opt->nparam = mxGetNumberOfElements(mxGetField(mat_opt, 0, "param"));
        }
        
// #ifdef PATCH_FEATURE_NAME
//         opt->func_init = FUNC_INIT(PATCH_FEATURE_NAME);
//         opt->func_proc = FUNC_PROC(PATCH_FEATURE_NAME);
// #else
    
        if(!PatchFeatureSelect(opt))
        {
            mexPrintf("%s\n", opt->name);
            mexErrMsgTxt("Patch feature is not implemented");
        }
// #endif
    }
            
    // get patch size   
    COPY_SCALAR_FIELD(opt, size_x, int);
    COPY_SCALAR_FIELD(opt, size_y, int);
}
#endif

#endif