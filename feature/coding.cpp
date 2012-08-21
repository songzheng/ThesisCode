
#include <mex.h>
#include <math.h>
#include <string.h>

// vlfeat headers
#include "coding.h"

// feature coding from dense to sparse
// •	VQ / PQ
// •	Fisher Vector
// •	Pixel coding 
// Input: Dense feature in columns
// Output: Sparse coded feature in  columns

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    FloatMatrix patch_feat;
    MatReadFloatMatrix(prhs[0], &patch_feat);
        
    CodingOpt opt;
    MatReadCodingOpt(prhs[1], &opt);
    
    InitCoding(&opt);
    
    FloatSparseMatrix patch_coding;
    plhs[0] = MatAllocateFloatSparseMatrix(&patch_coding, opt.length, patch_feat.width, opt.block_num, opt.block_size);    
    
    Coding(&patch_feat, &patch_coding, &opt);
    
}