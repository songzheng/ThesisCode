
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
    
    // feature grids/points
    bool use_grids;
    int * coord;
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

// raw gray pixel with rotation & flip awareness

inline void swap_f(float *a, float *b)
{
    float tmp = *a;
    *a = *b;
    *b = tmp;
}

inline void swap4_f(float *a0, float *a1, float * a2, float * a3)
{
    float tmp = *a0;
    *a0 = *a1;
    *a1 = *a2;
    *a2 = *a3;
    *a3 = tmp;
}

inline void flip4x4(float * data)
{    
    swap_f(data, data+12);      swap_f(data+4, data+8); 
    swap_f(data+1, data+13);    swap_f(data+5, data+9);
    swap_f(data+2, data+14);    swap_f(data+6, data+10); 
    swap_f(data+3, data+15);    swap_f(data+7, data+11);
}

inline void rotate4x4_cw90(float * data)
{    
    swap4_f(data, data+3, data+15, data+12);        swap4_f(data+4, data+2, data+11, data+13);
    swap4_f(data+1, data+7, data+14, data+8);      swap4_f(data+5, data+6, data+10, data+9);
}

inline void rotate4x4_180(float * data)
{    
    swap_f(data, data+15);      swap_f(data+4, data+11); 
    swap_f(data+1, data+14);    swap_f(data+5, data+10);
    swap_f(data+2, data+13);    swap_f(data+6, data+9); 
    swap_f(data+3, data+12);    swap_f(data+7, data+8);
}

inline void rotate4x4_cc90(float * data)
{    
    swap4_f(data, data+12, data+15, data+3);        swap4_f(data+4, data+13, data+11, data+2);
    swap4_f(data+1, data+8, data+14, data+7);      swap4_f(data+5, data+9, data+10, data+6);
}


inline void InitPixelGray4x4Rot(PixelFeatureOpt * opt)
{
    opt->image_depth = 1;
    opt->length = 18;
    opt->margin = 2;
}

inline void FuncPixelGray4x4Rot(FloatImage *img, int x, int y, float * dst,
        PixelFeatureOpt * opt)
{    
    float * p = img->p + (x-1)*img->height + (y-1);
    float sum_all = 0, sum_all_sq = 0;

    for(int i=0; i<4; i++)
    {
        for(int j=0; j<4; j++)
        {
            dst[i*4+j] = p[i*img->height+j];
            sum_all += dst[i*4+j];
            sum_all_sq += dst[i*4+j] * dst[i*4+j];
        }
    }

    float mean = sum_all/16;
    float std = vl_fast_sqrt_f(sum_all_sq/16 - mean*mean);
    float factor = std>20?(20/std):1.0f;
    
    
    for(int i=0; i<4; i++)
        for(int j=0; j<4; j++)
            dst[i*4+j] = (dst[i*4+j]-mean)*factor;

    float sum[4];
    
    sum[0] = p[0]+p[1]+p[4]+p[5];   sum[1] = p[8]+p[9]+p[12]+p[13];   
    sum[3] = p[2]+p[3]+p[6]+p[7];   sum[2] = p[10]+p[11]+p[14]+p[15];
    
    // find larget region
    int id_largest = 0;
    float val_largest = sum[0];
    
    if(sum[1] > sum[0])
    {
        id_largest = 1;  
        val_largest = sum[1];
    }
    
    if(sum[2] > val_largest)
    {
        id_largest = 2;
        val_largest = sum[2];
    }
        
    if(sum[3] > val_largest)
    {
        id_largest = 3;
    }
    
    // find neigbour region
    int id_prev = (id_largest+3)%4;
    int id_next = (id_largest+1)%4;
    
    // decide flip and rotation
    int flip = sum[id_prev]<sum[id_next]?0:1;    
    int rot = id_largest ^ flip;
    
    if(flip)
        flip4x4(dst);
    
    switch(rot)
    {
        case 0:
            break;
        case 1:
            rotate4x4_cc90(dst);
            break;
        case 2:
            rotate4x4_180(dst);
            break;
        case 3:
            rotate4x4_cw90(dst);
            break;
        default:
            ASSERT(false);            
    }
    
    dst[16] = float(rot);
    dst[17] = float(flip);
}


// raw gray pixel 8-N & 4-N
inline void InitPixelGray4x4(PixelFeatureOpt * opt)
{
    opt->image_depth = 1;
    opt->length = 16;
    opt->margin = 2;
}

inline void FuncPixelGray4x4(FloatImage *img, int x, int y, float * dst,
        PixelFeatureOpt * opt)
{    
    float * p = img->p + (x-1)*img->height + (y-1);
    
#pragma unroll
    for(int i=0; i<4; i++)
        for(int j=0; j<4; j++)
            dst[i*4+j] = p[i*img->height+j];
}


// raw gray dct

inline void dct4_1d(float * data, int stride)
{
    float in[4] = {data[0], data[stride], data[2*stride], data[3*stride]};
    data[0] = in[0] + in[1] + in[2] + in[3];
    data[0] /= 2;
    
    data[stride] = 0.6533*in[0] + 0.2706*in[1] - 0.2706*in[2] - 0.6533*in[3];
    
    data[2*stride] = in[0] - in[1] - in[2] + in[3];
    data[2*stride] /= 2;
    
    data[3*stride] = 0.2706*in[0] - 0.6533*in[1] + 0.6533*in[2] - 0.2706*in[3];
}


inline void dct4_2d(float * data, int stride)
{
    dct4_1d(data, 1);
    dct4_1d(data+stride, 1);
    dct4_1d(data+2*stride, 1);
    dct4_1d(data+3*stride, 1);
        
    dct4_1d(data, stride);
    dct4_1d(data+1, stride);
    dct4_1d(data+2, stride);
    dct4_1d(data+3, stride);
}

inline void InitPixelGray4x4DCT(PixelFeatureOpt * opt)
{
    opt->image_depth = 1;
    opt->length = 16;
    opt->margin = 2;
}

inline void FuncPixelGray4x4DCT(FloatImage *img, int x, int y, float * dst,
        PixelFeatureOpt * opt)
{    
    float * p = img->p + (x-1)*img->height + (y-1);
    
#pragma unroll
    for(int i=0; i<4; i++)
        for(int j=0; j<4; j++)
            dst[i*4+j] = p[i*img->height+j];

    dct4_2d(dst, 4);
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
