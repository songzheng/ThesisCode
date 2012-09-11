
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

void InitPixelFeature(FloatMatrix * img, PixelFeatureOpt * opt);
void PixelFeature(FloatMatrix * img, FloatMatrix * feat, PixelFeatureOpt * opt);
int PixelFeatureSelect(PixelFeatureOpt * opt);
void MatReadPixelFeatureOpt(const mxArray * mat_opt, PixelFeatureOpt * opt);


// ********************************* //
// pixel data implementation

// raw gray pixel 8-N & 4-N
inline void InitPixelGray8N(PixelFeatureOpt * opt)
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
        
inline void InitPixelGray4N(PixelFeatureOpt * opt)
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
inline void InitPixelColor(PixelFeatureOpt * opt)
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

#endif
