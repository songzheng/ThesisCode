#include "fisher_vector_coding.h"
// *************************************** //
// Fisher Vector

// fisher vector coding helper struct and function

// codebook struct
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

// Binary heap operation
void inline UpHeap(double * ele, int * ele_idx, int * heap_size, double ele_new, int idx_new)
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
// matlab helper function
void MatReadFisherVectorCodebook(const mxArray * mat_opt, FisherVectorCodeBook * opt)
{
    if ((mat_opt) == NULL)
        return;
    
    COPY_SCALAR_FIELD(opt, nDim, int);
    COPY_SCALAR_FIELD(opt, nBase, int);
    COPY_MATRIX_FIELD(opt, priors, double);
    COPY_MATRIX_FIELD(opt, mu, double);
    COPY_MATRIX_FIELD(opt, sigma, double);
    COPY_MATRIX_FIELD(opt, sqrtPrior, double);
    COPY_MATRIX_FIELD(opt, sqrt2Prior, double);
    COPY_MATRIX_FIELD(opt, invSigma, double);
    COPY_MATRIX_FIELD(opt, sqrtInvSigma, double);
    COPY_MATRIX_FIELD(opt, sumLogSigma, double);
//     mexPrintf("%d, %d, %f, %f\n", opt->nDim, opt->nBase, opt->priors[0], opt->mu[0]);
}

#endif

void InitCodingFisherVector(CodingOpt * opt)
{
    opt->length_input = opt->fv_codebook.nDim;
    // sparse block #
    opt->block_num = 7;
#ifdef FIRST_ORDER
    opt->block_size = opt->fv_codebook.nDim;
    opt->length = opt->fv_codebook.nDim * opt->fv_codebook.nBase;
#else
    opt->block_size = 2*opt->fv_codebook.nDim;
    opt->length = 2*opt->fv_codebook.nDim * opt->fv_codebook.nBase;
#endif
}

inline void FuncCodingFisherVector (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{    
    // codebook data
    const FisherVectorCodeBook * cb = &opt->fv_codebook;
    int nDim = cb->nDim, nBase = cb->nBase;
    const double * mu = cb->mu, *priors = cb->priors,
            * invSigma = cb->invSigma, 
            * sqrtInvSigma = cb->sqrtInvSigma,
            * sumLogSigma = cb->sumLogSigma;
    
    // initialize for prob computation    
    double probtemp = 0;
    int indi = 0;
    int heap_size = 1;
    double * prob_val = new double[opt->block_num];
    int * prob_bin = new int[opt->block_num];
    prob_val[0] = -1;
    
    // find high probability GMM
    for (int i=0; i<nBase; i++){
        probtemp = sumLogSigma[i];
        for (int k=0; k<nDim; k++)            
            probtemp += ((double)data[k]-mu[indi+k])*((double)data[k]-mu[indi+k])*invSigma[indi+k];
                 
        probtemp *= -0.5;  
        indi = indi+nDim;
                
        // a min-heap to keep max prob centers        
        if(heap_size < opt->block_num)
        {
            UpHeap(prob_val, prob_bin, &heap_size, probtemp, i);         
        }
        else if(probtemp > prob_val[0])
        {
            DownHeap(prob_val, prob_bin, &heap_size);
            UpHeap(prob_val, prob_bin, &heap_size, probtemp, i);     
        }
    }
    
    double probsum = 0;  
    // normalize probs
    for (int i=0; i<opt->block_num; i++){
        int bin = prob_bin[i];
        prob_val[i] = exp(prob_val[i])*priors[bin];
        probsum += prob_val[i];
    }
    for (int i=0; i<opt->block_num; i++){
        prob_val[i] /= probsum;
//         coding[i] = (float)prob_val[i];
    }
        
    // coding vector
    for (int i=0; i<opt->block_num; i++){
            
        int bin = prob_bin[i];
        coding_bin[i] = bin;
        
        double sqrt_prior = cb->sqrtPrior[bin],
                sqrt_2_prior = cb->sqrt2Prior[bin];
        
        for (int k=0; k<nDim; k++){
            double diff = (data[k]-mu[bin*nDim+k]);
            //  temp = sign(temp)*MIN(maxsqrtSigma[i*nDim+k],fabs(temp));
#ifdef FIRST_ORDER
            coding[i*nDim+k] = (float)(prob_val[i]*diff*sqrtInvSigma[bin*nDim+k]/sqrt_prior);
#else
            coding[i*nDim*2+k] = (float)(prob_val[i]*diff*sqrtInvSigma[bin*nDim+k]/sqrt_prior);
            coding[i*nDim*2+k+nDim] = (float)((prob_val[i]*diff*diff*invSigma[bin*nDim+k]-prob_val[i])/sqrt_2_prior);
#endif
        }        
    }
    
    delete [] prob_val;
    delete [] prob_bin;
}



// // calculate prob
// inline void FisherVectorProb(float * data, float * prob_val, int * prob_bin, 
//         int center_max, FisherVectorCodeBook * cb)
// {    
//     int nDim = cb->nDim, nBase = cb->nBase;
//     double probtemp = 0;
//     double probsum = 0;
//     int indi = 0;
//     int heap_size = 1;
//     prob_val[0] = -1;
//     
//     for (int i=0; i<nBase; i++){
//         probtemp = cb->sumLogSigma[i];
//         for (int k=0; k<nDim; k++)            
//             probtemp+= (data[k]-cb->mu[indi+k])*(data[k]-cb->mu[indi+k])*cb->invSigma[indi+k];
//                 
//         probtemp *= -0.5;        
//         probtemp = exp(probtemp)*cb->priors[i];
//         probsum += probtemp;
//         indi = indi+nDim;
//                 
//         // a min-heap to keep max prob centers        
//         if(heap_size < center_max)
//         {
//             UpHeap(prob_val, prob_bin, &heap_size, probtemp, i);         
//         }
//         else if(probtemp > prob_val[0])
//         {
//             DownHeap(prob_val, prob_bin, &heap_size);
//             UpHeap(prob_val, prob_bin, &heap_size, probtemp, i);     
//         }
//     }
//     for (int i=0; i<center_max; i++){
//         prob_val[i] /= probsum;
//     }
// }
// 
// // calculate coding
// inline void FisherVectorCoding(float * data, float * coding_val, int * coding_bin,
//         int center_max, FisherVectorCodeBook * cb, 
//         float * prob_val, int * prob_bin)
// {
//     int nDim = cb->nDim;
//     
//     double temp = 0;
//     for (int i=0; i<center_max; i++){
//         int bin = prob_bin[i];
//         coding_bin[i] = bin;
//         
//         double sqrt_prior = cb->sqrtPrior[bin],
//                 sqrt_2_prior = cb->sqrt2Prior[bin];
//         
//         for (int k=0; k<nDim; k++){
//             temp = (data[k]-cb->mu[bin*nDim+k]);
//             //  temp = sign(temp)*MIN(maxsqrtSigma[i*nDim+k],fabs(temp));
// #ifdef FIRST_ORDER
//             coding_val[i*nDim+k] = prob_val[i]*temp*cb->sqrtInvSigma[bin*nDim+k]/sqrt_prior;
// #else
//             coding_val[i*nDim*2+k] = prob_val[i]*temp*cb->sqrtInvSigma[bin*nDim+k]/sqrt_prior;
//             coding_val[i*nDim*2+k+nDim] = (prob_val[i]*temp*temp*cb->invSigma[bin*nDim+k]-prob_val[i])/sqrt_2_prior;
// #endif
//         }        
//     }
// }
// 

// fisher vector v1, coding from feature: do_prob && do_coding
// fisher vector v2, coding use precomputed probability: !do_prob && do_coding
// fisher vector v3, only prob output: do_prob && !do_coding
// inline void FuncCodingFisherVector (float * data, float * coding, int * coding_bin, CodingOpt * opt,
//         float * prob_val = NULL, int * prob_bin = NULL, float * model = NULL)
//     bool do_prob = opt->param[0] > 0,
//             do_coding = opt->param[1]>0;
//     
//     if(do_prob)
//     FisherVectorProb(data, opt->prob_val, opt->prob_bin, opt->block_num, &opt->fv_codebook);
        
//     if(do_coding)
//     FisherVectorCoding(data, coding, coding_bin, opt->block_num, &opt->fv_codebook, opt->prob_val, opt->prob_bin);