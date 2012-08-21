#include <math.h>
#include "mex.h"

// get lbp bits for specified pixel
#define compab_mask_inc(ptr, shift) { value |= ((unsigned int)(*center - *ptr - 1) & 0x80000000) >> (31-shift); ptr++; }
#define compab_mask(val, shift) { value |= ((unsigned int)(*center - (val) - 1) & 0x80000000) >> (31-shift); }
// small value, used to avoid division by zero
#define eps 0.0001
// PI
#define M_PI 3.1415926


// radius
#define predicate 1

// bits
#define bits 8
#define origin_bins 256
#define map_bins 59

typedef struct {
    int x, y;
} integerpoint;

typedef struct {
    double x, y;
} doublepoint;

// initial for radius = 1, bits = 8
// interpolate upperleft
integerpoint points[bits]={
    {1, 0},
    {0, 0},
    {0, 1},
    {-1, 0},
    {-1, 0},
    {-1, -1},
    {0, -1},
    {0, -1}};
//offset from point
    doublepoint offsets[bits]={
        {0.000000, 0.000000},
        {0.707107, 0.707107},
        {0.000000, 0.000000},
        {0.292893, 0.707107},
        {0.000000, 0.000000},
        {0.292893, 0.292893},
        {0.000000, 0.000000},
        {0.707107, 0.292893}};

unsigned int map[origin_bins]=
{0, 1, 2, 3, 4, 58, 5, 6, 7, 58, 58, 58, 8, 58, 9, 10, 11, 58, 58, 58, 58, 58, 58, 58, 12,
 58, 58, 58, 13, 58, 14, 15, 16, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
 58, 17, 58, 58, 58, 58, 58, 58, 58, 18, 58, 58, 58, 19, 58, 20, 21, 22, 58, 58, 58, 58,
 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
 58, 58, 58, 58, 58, 23, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 24,
 58, 58, 58, 58, 58, 58, 58, 25, 58, 58, 58, 26, 58, 27, 28, 29, 30, 58, 31, 58, 58, 58,
 32, 58, 58, 58, 58, 58, 58, 58, 33, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
 58, 58, 34, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 35, 36, 37, 58, 38, 58, 58, 58, 39, 58,
 58, 58, 58, 58, 58, 58, 40, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
 41, 42, 43, 58, 44, 58, 58, 58, 45, 58, 58, 58, 58, 58, 58, 58, 46, 47, 48, 58, 49, 58,
 58, 58, 50, 51, 52, 58, 53, 54, 55, 56, 57};
//---------------------------------------------------------------------------
/*
 * Calculate the point coordinates for circular sampling of the neighborhood.
 */
void calculate_points(void) {
    double step = 2 * M_PI / bits, tmpX, tmpY;
    int i;
    for (i=0;i<bits;i++) {
        tmpX = predicate * cos(i * step);
        tmpY = predicate * sin(i * step);
        points[i].x = (int)tmpX;
        points[i].y = (int)tmpY;
        offsets[i].x = tmpX - points[i].x;
        offsets[i].y = tmpY - points[i].y;
        if (offsets[i].x < 1.0e-10 && offsets[i].x > -1.0e-10) /* rounding error */
            offsets[i].x = 0;
        if (offsets[i].y < 1.0e-10 && offsets[i].y > -1.0e-10) /* rounding error */
            offsets[i].y = 0;
        
        if (tmpX < 0 && offsets[i].x != 0) {
            points[i].x -= 1;
            offsets[i].x += 1;
        }
        if (tmpY < 0 && offsets[i].y != 0) {
            points[i].y -= 1;
            offsets[i].y += 1;
        }
    }
}

static inline double min(double x, double y) { return (x <= y ? x : y); }
static inline double max(double x, double y) { return (x <= y ? y : x); }

static inline int min(int x, int y) { return (x <= y ? x : y); }
static inline int max(int x, int y) { return (x <= y ? y : x); }
//---------------------------------------------------------------------------
//Get a bilinearly interpolated value for a pixel.
inline double interpolate_at_ptr(double* upperLeft, int i, int columns) {
    double dx = 1-offsets[i].x;
    double dy = 1-offsets[i].y;
    return
            *upperLeft*dx*dy +
            *(upperLeft+1)*offsets[i].x*dy +
            *(upperLeft+columns)*dx*offsets[i].y +
            *(upperLeft+columns+1)*offsets[i].x*offsets[i].y;
}

//---------------------------------------------------------------------------
/*
 * img: the image data, an array of rows*columns integers arranged in
 * a horizontal raster-scan order
 * rows: the number of rows in the image
 * columns: the number of columns in the image
 * result: an array of map_bins integers. Will hold the map_bins LBP histogram.
 * interpolated: if != 0, a circular sampling of the neighborhood is
 * performed. Each pixel value not matching the discrete image grid
 * exactly is obtained using a bilinear interpolation. You must call
 * calculate_points (only once) prior to using the interpolated version.
 */

//---------------------------------------------------------------------------
mxArray *process(const mxArray *mximage, const mxArray *mxsbin, int interpolated) {
    double *img = (double *)mxGetPr(mximage);
    const int *dims = mxGetDimensions(mximage);
        
    int sbin = (int)mxGetScalar(mxsbin);
    
    // memory for caching orientation histograms & their norms
    // blocks=size+2 if use default settings in train.m
    int blocks[2];
    blocks[0] = (int)((double)dims[0]/(double)sbin + 0.5);
    blocks[1] = (int)((double)dims[1]/(double)sbin + 0.5);
    
    // 59 LBP bins
    double *hist = (double *)mxCalloc(blocks[0]*blocks[1]*map_bins, sizeof(double));
    double *norm = (double *)mxCalloc(blocks[0]*blocks[1], sizeof(double));
    int leap = dims[0]*predicate;
    
    // memory for LBP output features
    int out[3];
    // save a margin of 2
    out[0] = max(blocks[0]-2, 0);
    out[1] = max(blocks[1]-2, 0);
    out[2] = map_bins;//corresponds to 59 uniform LBP bin
    mxArray *mxfeat = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);
    double *feat = (double *)mxGetPr(mxfeat);
    
    // visible points for current blocks
    int visible[2];
    visible[0] = min(blocks[0]*sbin,dims[0]);
    visible[1] = min(blocks[1]*sbin,dims[1]);    
    
    /*Set up a circularly indexed neighborhood using nine pointers.*/
    double
            *p0 = img,
            *p1 = p0 + predicate,
            *p2 = p1 + predicate,
            *p3 = p2 + leap,
            *p4 = p3 + leap,
            *p5 = p4 - predicate,
            *p6 = p5 - predicate,
            *p7 = p6 - leap,
            *center = p7 + predicate;
    
    unsigned int value;
    int pred2 = predicate * 2;
    
    if (!interpolated) {
        for (int x=0;x<visible[1]-pred2;x++) {
            p0 = img + x*dims[0];
            p1 = p0 + predicate;
            p2 = p1 + predicate;
            p3 = p2 + leap;
            p4 = p3 + leap;
            p5 = p4 - predicate;
            p6 = p5 - predicate;
            p7 = p6 - leap;
            center = p7 + predicate;
            for (int y=0;y<visible[0]-pred2;y++) {
                value = 0;
                
                /* Unrolled loop */
                compab_mask_inc(p0, 0);
                compab_mask_inc(p1, 1);
                compab_mask_inc(p2, 2);
                compab_mask_inc(p3, 3);
                compab_mask_inc(p4, 4);
                compab_mask_inc(p5, 5);
                compab_mask_inc(p6, 6);
                compab_mask_inc(p7, 7);
                center++;
                
                value=map[value];
                double xp = ((double)x+0.5+predicate)/(double)sbin - 0.5;
                double yp = ((double)y+0.5+predicate)/(double)sbin - 0.5;
                int ixp = (int)floor(xp);
                int iyp = (int)floor(yp);
                double vx0 = xp-ixp;
                double vy0 = yp-iyp;
                double vx1 = 1.0-vx0;
                double vy1 = 1.0-vy0;
                
                if (ixp >= 0 && iyp >= 0) {
                    *(hist + ixp*blocks[0] + iyp + value*blocks[0]*blocks[1]) +=
                            vx1*vy1;
                }
                
                if (ixp+1 < blocks[1] && iyp >= 0) {
                    *(hist + (ixp+1)*blocks[0] + iyp + value*blocks[0]*blocks[1]) +=
                            vx0*vy1;
                }
                
                if (ixp >= 0 && iyp+1 < blocks[0]) {
                    *(hist + ixp*blocks[0] + (iyp+1) + value*blocks[0]*blocks[1]) +=
                            vx1*vy0;
                }
                
                if (ixp+1 < blocks[1] && iyp+1 < blocks[0]) {
                    *(hist + (ixp+1)*blocks[0] + (iyp+1) + value*blocks[0]*blocks[1]) +=
                            vx0*vy0;
                }
            }
        }
    }
    else {        
        for (int x=0;x<visible[1]-pred2;x++) {
            
            p1 = img + x*dims[0] + predicate;
            p3 = p1 + predicate + leap;
            p5 = p3 + leap - predicate;
            p7 = p5 - predicate - leap;
            center = p7 + predicate;            
            p0 = center + points[5].x + points[5].y * dims[0];
            p2 = center + points[7].x + points[7].y * dims[0];
            p4 = center + points[1].x + points[1].y * dims[0];
            p6 = center + points[3].x + points[3].y * dims[0];
            
            for (int y=0;y<visible[0]-pred2;y++) {
                value = 0;
                
                /* Unrolled loop */
                compab_mask_inc(p1, 1);
                compab_mask_inc(p3, 3);
                compab_mask_inc(p5, 5);
                compab_mask_inc(p7, 7);
                
                /* Interpolate corner pixels */
                compab_mask((int)(interpolate_at_ptr(p0, 5, dims[0])+0.5), 0);
                compab_mask((int)(interpolate_at_ptr(p2, 7, dims[0])+0.5), 2);
                compab_mask((int)(interpolate_at_ptr(p4, 1, dims[0])+0.5), 4);
                compab_mask((int)(interpolate_at_ptr(p6, 3, dims[0])+0.5), 6);
                p0++;
                p2++;
                p4++;
                p6++;
                center++;
                
                value=map[value];
                
                double xp = ((double)x+0.5+predicate)/(double)sbin - 0.5;
                double yp = ((double)y+0.5+predicate)/(double)sbin - 0.5;
                int ixp = (int)floor(xp);
                int iyp = (int)floor(yp);
                double vx0 = xp-ixp;
                double vy0 = yp-iyp;
                double vx1 = 1.0-vx0;
                double vy1 = 1.0-vy0;
                
                if (ixp >= 0 && iyp >= 0) {
                    *(hist + ixp*blocks[0] + iyp + value*blocks[0]*blocks[1]) +=
                            vx1*vy1;
                }
                
                if (ixp+1 < blocks[1] && iyp >= 0) {
                    *(hist + (ixp+1)*blocks[0] + iyp + value*blocks[0]*blocks[1]) +=
                            vx0*vy1;
                }
                
                if (ixp >= 0 && iyp+1 < blocks[0]) {
                    *(hist + ixp*blocks[0] + (iyp+1) + value*blocks[0]*blocks[1]) +=
                            vx1*vy0;
                }
                
                if (ixp+1 < blocks[1] && iyp+1 < blocks[0]) {
                    *(hist + (ixp+1)*blocks[0] + (iyp+1) + value*blocks[0]*blocks[1]) +=
                            vx0*vy0;
                }
            }
        }
    }
    
    // compute energy in each block by summing over bins
    for (int o = 0; o < map_bins; o++) {
        double *src = hist + o*blocks[0]*blocks[1];
        double *dst = norm;
        double *end = norm + blocks[1]*blocks[0];
        while (dst < end) {
            //L2 norm
            //norm is computed by sum of two orientations with pi difference
            *(dst++) += (*src)*(*src);
            src++;
        }
    }
    
    // compute features
    // dim(out)=dim(blocks)-2
    for (int x = 0; x < out[1]; x++) {
        for (int y = 0; y < out[0]; y++) {
            double *dst = feat + x*out[0] + y;
            double *src, *p, n1, n2, n3, n4;
            
            p = norm + (x+1)*blocks[0] + y+1;
            n1 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
            p = norm + (x+1)*blocks[0] + y;
            n2 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
            p = norm + x*blocks[0] + y+1;
            n3 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
            p = norm + x*blocks[0] + y;
            n4 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
            
            src = hist + (x+1)*blocks[0] + (y+1);
            for (int o = 0; o < map_bins; o++) {
                //suppress to overlarge values
                double h1 = min(*src * n1, 0.2);
                double h2 = min(*src * n2, 0.2);
                double h3 = min(*src * n3, 0.2);
                double h4 = min(*src * n4, 0.2);
                //average of four adjacent blocks
                *dst = 0.5 * (h1 + h2 + h3 + h4);
                dst += out[0]*out[1];
                src += blocks[0]*blocks[1];
            }
        }
    }
    
    
    mxFree(hist);
    mxFree(norm);
    return mxfeat;
}

// matlab entry point
// F = features(image, bin)
// image should be color with double values
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int interpolated;
    if (nrhs == 2)
        interpolated = 1;
    else if (nrhs == 3)
        interpolated = (int)mxGetScalar(prhs[2]);
    else
        mexErrMsgTxt("Wrong number of inputs");
    if (nlhs != 1)
        mexErrMsgTxt("Wrong number of outputs");
    
    
    if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Invalid input");
    
    
 /*   if (mxGetNumberOfDimensions(prhs[0]) == 3){
        mxArray * color, * color_uint, * gray;        
        color=mxDuplicateArray(prhs[0]);
        mexCallMATLAB(1,&color_uint,1,&color,"uint8");
        mexCallMATLAB(1,&gray,1,&color_uint,"rgb2gray");
        plhs[0] = process(gray, prhs[1], interpolated);
    }else*/
    if (mxGetNumberOfDimensions(prhs[0]) == 2)
        plhs[0] = process(prhs[0], prhs[1], interpolated);
    else        
        mexErrMsgTxt("Invalid input");
        
}


