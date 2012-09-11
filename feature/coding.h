
#ifndef CODING_H
#define CODING_H
#include "image.h"

// coding struct:
//      name: name of coding
//      func_init & func_proc: coding function
//      length_input: input featue length
//      length: coded featue length

struct CodingOpt;
struct FisherVectorCodeBook;

typedef void (*FuncCodingInit)(CodingOpt * opt);
typedef void (*FuncCodingProc)(float * data, float * coding, int * coding_bin, const CodingOpt * opt);

void InitCoding(CodingOpt * opt);
void Coding(FloatMatrix * data, FloatSparseMatrix * coding, CodingOpt * opt);
int CodingSelect(CodingOpt * opt);

// codebook struct
// fisher vector coding helper struct and function
struct FisherVectorCodeBook
{
    int nDim, nBase;
    
    const double * priors;
    const double * mu; // dim nBase
    const double * sigma; // dim nDim x nBase
    
    // derived precomputed variables
    const double * sqrtPrior; // dim nBase
    const double * sqrt2Prior; // dim nBase
    const double * invSigma; // dim nDim x nBase
    const double * sqrtInvSigma; // dim nDim x nBase
    const double * sumLogSigma; // dim nBase
};

struct CodingOpt{
    char* name;
    FuncCodingInit func_init;
    FuncCodingProc func_proc;
    
    double * param;
    int nparam;
    
    // codebooks
    union
    {
        FisherVectorCodeBook fv_codebook;
        //VQCodeBook vq_codebook;
    };
    
    int length_input;
    int length;
    
    // sparse info
    int block_size;
    int block_num;
            
};


// ********************************* //

// pixel-level manual coding
//  histogram of oriented gradient
inline void InitCodingPixelHOG(CodingOpt * opt)
{
    opt->length_input = 5;
    opt->block_num = 2;
    opt->block_size = 1;
    ASSERT(opt->nparam == 1);   
    opt->length = (int)opt->param[0];          
}

inline void FuncCodingPixelHOG (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{        
    float gx, gy ;
    float angle, mod, nt, rbint ;
    int bint ;
            
    int num_ori = opt->length;
    
    gy = 0.5f * (data[2] - data[0]);
    gx = 0.5f * (data[1] - data[3]);
    
    /* angle and modulus */
    angle = vl_fast_atan2_f (gy,gx) ;
    mod = vl_fast_sqrt_f (gx*gx + gy*gy) ;
    
    /* quantize angle */
    nt = vl_mod_2pi_f (angle) * float(num_ori / (2*VL_PI)) ;
    bint = vl_floor_f (nt) ;
    rbint = nt - bint ;        
    
    coding[0] = (float)(1 - rbint) * mod;    
    coding_bin[0] = bint%num_ori;
    coding[1] = (float)(rbint) * mod;    
    coding_bin[1] = (bint+1)%num_ori;
}

//  histogram of oriented gradient
inline void InitCodingPixelHOGHalfSphere(CodingOpt * opt)
{
    opt->length_input = 5;
    opt->block_num = 2;
    opt->block_size = 1;
    ASSERT(opt->nparam == 1);   
    opt->length = (int)opt->param[0];          
}

inline void FuncCodingPixelHOGHalfSphere (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{        
    float gx, gy ;
    float angle, mod, nt, rbint ;
    int bint ;
            
    int num_ori = opt->length;
    
    gy = 0.5f * (data[2] - data[0]);
    gx = 0.5f * (data[1] - data[3]);
    
    /* angle and modulus */
    angle = vl_fast_atan2_f (gy,gx) ;
    mod = vl_fast_sqrt_f (gx*gx + gy*gy) ;
    
    /* quantize angle */
    nt = vl_mod_2pi_f (angle) * float(num_ori) / VL_PI ;
    bint = vl_floor_f (nt) ;
    rbint = nt - bint ;        
    
    coding[0] = (float)(1 - rbint) * mod;    
    coding_bin[0] = bint%num_ori;
    coding[1] = (float)(rbint) * mod;    
    coding_bin[1] = (bint+1)%num_ori;
}

// hog of UoC

static double uu[9] = {1.0000, 
		0.9397, 
		0.7660, 
		0.500, 
		0.1736, 
		-0.1736, 
		-0.5000, 
		-0.7660, 
		-0.9397};
static double vv[9] = {0.0000, 
		0.3420, 
		0.6428, 
		0.8660, 
		0.9848, 
		0.9848, 
		0.8660, 
		0.6428, 
		0.3420};
        
inline void InitCodingPixelHOGUoC(CodingOpt * opt)
{
    opt->length_input = 5;
    opt->block_num = 1;
    opt->block_size = 1;
    ASSERT(opt->nparam == 1);   
    opt->length = (int)opt->param[0];    
}
inline void FuncCodingPixelHOGUoC (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{    
    float gx, gy;
        
    int num_ori = int(opt->param[0]);
    
    gy = 0.5f * (data[2] - data[0]);
    gx = 0.5f * (data[1] - data[3]);
    float mod = (float)vl_fast_sqrt_f (gx*gx + gy*gy) ;
    
    // snap to one of 18 orientations within 2*pi, degree=best_o*2*pi/18
    double best_dot = 0;
    int best_o = 0;
    for (int o = 0; o < 9; o++) {
        double dot = uu[o]*gx + vv[o]*gy;
        if (dot > best_dot) {
            best_dot = dot;
            best_o = o;
        } else if (-dot > best_dot) {
            best_dot = -dot;
            best_o = o+9;
        }
    }
    
    coding[0] = mod;    
    coding_bin[0] = best_o;
}

// lbp 59
static unsigned int LBP59_Map[256]=
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
 
inline void InitCodingPixelLBP(CodingOpt * opt)
{
    opt->length_input = 9;
    opt->block_size = 1;
    opt->block_num = 1;
    opt->length = 59;
}

inline void FuncCodingPixelLBP(float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{
    unsigned int  bitString = 0 ;
    for(int i=0; i<8; i++)
        if(data[i] > data[8]) 
            bitString |= 0x1 << i;         
       
    coding[0] = 1;
    coding_bin[0] = LBP59_Map[bitString];
}

// *************************************** //
// Vector Quantization

inline void FuncCodingVQ (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{
}

inline void FuncCodingPQ (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{
}

// *************************************** //
// Fisher Vector

// Binary heap operation
inline void UpHeap(double * ele, int * ele_idx, int * heap_size, double ele_new, int idx_new)
{ 
    int i;
    for (i = ++(*heap_size); i>1 && ele[i/2-1] > ele_new; i/=2)
    {
        ele[i-1] = ele[i/2-1];
        ele_idx[i-1] = ele_idx[i/2-1];
    }

    ele[i-1] = ele_new;
    ele_idx[i-1] = idx_new;
}

inline void DownHeap(double * ele, int * idx, int * heap_size)
{
    int i, child;
    
    if ((*heap_size) == 0) {
        return;
    }
    
    double ele_min = ele[0];
    double ele_last = ele[(*heap_size)-1];
    int idx_last = idx[(*heap_size)-1];
    (*heap_size)--;
    
    for (i = 1; i*2 <= *heap_size; i=child) {
        /* Find smaller child */
        child = i * 2;
        if (child != *heap_size && ele[child] < ele[child-1])
            child++;
        
        /* Percolate one level */
        if (ele_last > ele[child-1])
        {
            ele[i-1] = ele[child-1];
            idx[i-1] = idx[child-1];
        }
        else
            break;
    }
    ele[i-1] = ele_last;
    idx[i-1] = idx_last;
}

#ifdef MATLAB_COMPILE
void MatReadCodingOpt(const mxArray * mat_opt, CodingOpt * opt);
void MatReadFisherVectorCodebook(const mxArray * mat_opt, FisherVectorCodeBook * opt);
#endif

#endif

