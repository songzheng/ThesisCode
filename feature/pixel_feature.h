
#ifndef PIXEL_FEATURE_H
#define PIXEL_FEATURE_H

#include "image.h"

// ***************************** //
// for pixel-wise feature coding
struct PixelFeatureOpt;

typedef void (*FuncPixelFeatureInit)(PixelFeatureOpt * opt);
typedef void (*FuncPixelFeatureProc)(FloatImage * img, int x, int y, float * dst, PixelFeatureOpt * opt);

// pixel feature options:
//      image_depth: depth of image used
//      length: origin featue length
//      param, nparam: code parameter
//      codebook: learning based encoding after extracting feature
//      coded_length: coded featue length
struct PixelFeatureOpt
{
    char* name; //name of the pixel feature    
    FuncPixelFeatureInit func_init;
    FuncPixelFeatureProc func_proc;
    
    // feature options 
    int image_depth;
    double * param;
    int nparam;    
    int length;      
    int margin; 
    
    // feature grids
    Grids grids;
    int num;
};

// ********************************* //
// pixel data implementation

// raw gray pixel 8-N & 4-N
void InitPixelGray8N(PixelFeatureOpt * opt)
{
    opt->image_depth = 1;
    opt->length = 9;
    opt->margin = 1;
}

inline void FuncPixelGray8N(FloatImage *img, int x, int y, float * dst,
        PixelFeatureOpt * opt)
{
    // Set up a circularly indexed neighborhood using nine pointers.
    // |--------------|
    // | p0 | p1 | p2 |
    // |--------------|
    // | p7 | c  | p3 |
    // |--------------|
    // | p6 | p5 | p4 |
    // |--------------|
    
    float * p = img->p + x*img->height + y;
    dst[0] = *(p-1-img->height);
    dst[1] = *(p-1);
    dst[2] = *(p-1+img->height);
    dst[3] = *(p+img->height);
    dst[4] = *(p+1+img->height);
    dst[5] = *(p+1);
    dst[6] = *(p+1-img->height);
    dst[7] = *(p-img->height);
    dst[8] = *p;
}
        
void InitPixelGray4N(PixelFeatureOpt * opt)
{
    opt->image_depth = 1;
    opt->length = 5;
    opt->margin = 1;
}

inline void FuncPixelGray4N(FloatImage *img, int x, int y, float * dst,
        PixelFeatureOpt * opt)
{
    // Set up a circularly indexed neighborhood using nine pointers.
    // |--------------|
    // |    | p0 |    |
    // |--------------|
    // | p3 | c  | p1 |
    // |--------------|
    // |    | p2 |    |
    // |--------------|
    
    float * p = img->p + x*img->height + y;
    
    dst[0] = *(p-1);
    dst[1] = *(p+img->height);
    dst[2] = *(p+1);
    dst[3] = *(p-img->height);
    dst[4] = *(p);
}

// raw color pixel
void InitPixelColor(PixelFeatureOpt * opt)
{
    opt->image_depth = 3;
    opt->length = 3;
    opt->margin = 0;
}

inline void FuncPixelColor(FloatImage *img, int x, int y, float * dst,
        PixelFeatureOpt * opt)
{
    float * p = img->p + x*img->height + y;
    dst[0] = *(p);
    dst[1] = *(p + img->width * img->height);
    dst[2] = *(p + 2*img->width * img->height);
}



// *********************************//
// entry

void InitPixelFeature(FloatMatrix * img, PixelFeatureOpt * opt)
{
    opt->func_init(opt);

    ASSERT(img->depth == opt->image_depth);    
    
    Grids * grids = &opt->grids;
    
    grids->start_x = opt->margin;
    grids->step_x = 1;
    grids->num_x = img->width-opt->margin*2;
    
    grids->start_y = opt->margin;
    grids->step_y = 1;
    grids->num_y = img->height-opt->margin*2;
    
    opt->num = grids->num_x * grids->num_y;
    
//     mexPrintf("%d, %d, %d, %d, %d\n", img->depth, opt->image_depth, opt->height, opt->width, opt->margin);
}

void PixelFeature(FloatMatrix * img, FloatMatrix * feat, PixelFeatureOpt * opt)
{        
    Grids * grids = &opt->grids;
    float * dst = feat->p;
        
    for (int x = grids->start_x ; x < grids->start_x+grids->num_x ; ++ x) {        
        for (int y = grids->start_y ; y < grids->start_y+grids->num_y ; ++ y) {            
            opt->func_proc(img, x, y, dst, opt);                       
            dst += opt->length;
        }
    }   
}

// feature select function
int PixelFeatureSelect(PixelFeatureOpt * opt)
{   
	opt->func_init = NULL;
	opt->func_proc = NULL;
    if(!strcmp(opt->name, "PixelGray8N"))
    {        
        opt->func_init = InitPixelGray8N;
        opt->func_proc = FuncPixelGray8N;
        return 1;
    }
    
    
    if(!strcmp(opt->name, "PixelGray4N"))
    {        
        opt->func_init = InitPixelGray4N;
        opt->func_proc = FuncPixelGray4N;
        return 1;
    }
    
    
    if(!strcmp(opt->name, "PixelColor"))
    {        
        opt->func_init = InitPixelColor;
        opt->func_proc = FuncPixelColor;
        return 1;
    }
    
    return 0;
}

#ifdef MATLAB_COMPILE

void MatReadPixelFeatureOpt(const mxArray * mat_opt, PixelFeatureOpt * opt)
{
    // get feature name
    mxArray * mx_name = mxGetField(mat_opt, 0, "name");
    ASSERT(mx_name != NULL);    
    opt->name = mxArrayToString(mx_name);
        
//     mexPrintf("%s\n", opt->name);
                 
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
    
// #ifdef PIXEL_FEATURE_NAME
//     opt->func_init = FUNC_INIT(PIXEL_FEATURE_NAME);
//     opt->func_proc = FUNC_PROC(PIXEL_FEATURE_NAME);
// #else
    if(!PixelFeatureSelect(opt))
    {
        mexPrintf("%s\n", opt->name);
        mexErrMsgTxt("Pixel feature is not implemented");
    }
// #endif
}
#endif

#endif
