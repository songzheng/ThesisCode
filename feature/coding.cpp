#include "coding.h"
// helper functions

inline void Projection(float * src, float * dst, 
        const double * projection, const double * mean, 
        int nDim, int nReducedDim)
{    
    float norm = 0;
    for(int i=0; i<nReducedDim; i++)
    {
        dst[i] = 0;
        for(int j=0; j<nDim; j++)
            dst[i] += (src[j]-mean[j]) * projection[j + i*nDim];
        norm += dst[i] * dst[i];
    }
    norm =  vl_fast_sqrt_f(norm);
    for(int i=0; i<nReducedDim; i++)
        dst[i] /= norm;
}


// *************************************** //
// Vector Quantization

void InitCodingVectorQuantization (CodingOpt * opt)
{
    // rotation aware: last two dimension are rotations
    if (opt->param[0] > 0)
        opt->length_input = opt->vq_codebook.nDim + 2;
    else
        opt->length_input = opt->vq_codebook.nDim;
            
    // sparse block #
    opt->block_num = 1;
    opt->block_size = 1;
    
    
    // rotation aware: 8 rotations for each base
    if (opt->param[0] > 0)
        opt->length = opt->vq_codebook.nBase * 8;
    else
        opt->length = opt->vq_codebook.nBase;
}

void FuncCodingVectorQuantization (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{
    int nBase = opt->vq_codebook.nBase;
    int nReducedDim = opt->vq_codebook.nReducedDim;
    int nDim = opt->vq_codebook.nDim;
    
    int min_base = -1;
    int min_dist = 0;
    const double * base = opt->vq_codebook.base;
    const double * projection = opt->vq_codebook.projection;
    const double * mean = opt->vq_codebook.mean;
    
    float * data_to_encode;
    bool project;
    if(nReducedDim > 0)
    {
        project = true;
        data_to_encode = new float[nReducedDim];
        Projection(data, data_to_encode, projection, mean, nDim, nReducedDim);
    }
    else
    {
        project = false;
        data_to_encode = data;
        nReducedDim = nDim;
    }
    
    for(int i=0; i<nBase; i++)
    {
        float dist = 0;
        for(int j=0; j<nReducedDim; j++)
            dist += (data_to_encode[j] - base[j+i*nReducedDim]) * (data_to_encode[j] - base[j+i*nReducedDim]);
        
        if(min_base == -1 || dist < min_dist)
        {
            min_dist = dist;
            min_base = i;
        }
    }
    
    // rotation aware
    if(opt->param[0] > 0)
        min_base = min_base * 8 + int(data[nDim]) + int(data[nDim+1]*4);
    
    coding[0] = 1;
    coding_bin[0] = min_base;
    
    if(project)
        delete[] data_to_encode;
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

void FuncCodingFisherVector (float * data, float * coding, int * coding_bin, const CodingOpt * opt)
{    
    // codebook data
    const FisherVectorCodeBook * cb = &opt->fv_codebook;
    int nDim = cb->nDim, nBase = cb->nBase;
    const double * base = cb->base, *priors = cb->priors,
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
            probtemp += ((double)data[k]-base[indi+k])*((double)data[k]-base[indi+k])*invSigma[indi+k];
                 
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
            double diff = (data[k]-base[bin*nDim+k]);
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

#ifdef MATLAB_COMPILE
// matlab helper function
void MatReadVectorQuantizationCodebook(const mxArray * mat_opt, VectorQuantizationCodeBook * opt)
{
    if ((mat_opt) == NULL)
        return;
    
    COPY_SCALAR_FIELD(opt, nDim, int);
    COPY_SCALAR_FIELD(opt, nBase, int);
    COPY_SCALAR_FIELD(opt, nReducedDim, int);
    COPY_MATRIX_FIELD(opt, base, double);
    COPY_MATRIX_FIELD(opt, projection, double);
    COPY_MATRIX_FIELD(opt, mean, double);
//     mexPrintf("%d, %d, %f, %f\n", opt->nDim, opt->nBase, opt->priors[0], opt->base[0]);
}

void MatReadFisherVectorCodebook(const mxArray * mat_opt, FisherVectorCodeBook * opt)
{
    if ((mat_opt) == NULL)
        return;
    
    COPY_SCALAR_FIELD(opt, nDim, int);
    COPY_SCALAR_FIELD(opt, nBase, int);
    COPY_MATRIX_FIELD(opt, priors, double);
    COPY_MATRIX_FIELD(opt, base, double);
    COPY_MATRIX_FIELD(opt, sigma, double);
    COPY_MATRIX_FIELD(opt, sqrtPrior, double);
    COPY_MATRIX_FIELD(opt, sqrt2Prior, double);
    COPY_MATRIX_FIELD(opt, invSigma, double);
    COPY_MATRIX_FIELD(opt, sqrtInvSigma, double);
    COPY_MATRIX_FIELD(opt, sumLogSigma, double);
//     mexPrintf("%d, %d, %f, %f\n", opt->nDim, opt->nBase, opt->priors[0], opt->base[0]);
}

#endif
// ********************************* //

void InitCoding(CodingOpt * opt)
{
#ifdef CODING_NAME
    FUNC_INIT(CODING_NAME)(opt);
#else
    opt->func_init(opt);
#endif
}

#ifdef OPEN_MP
    #include <omp.h>
#endif

void Coding(FloatMatrix * data, FloatSparseMatrix * coding, CodingOpt * opt)
{
    float * p = data->p;
    float * coding_val = coding->p;
    int * coding_bin = coding->i;
    int block_stride = opt->block_size * opt->block_num;
    int block_num = opt->block_num;   
    
    #if defined(OPEN_MP) && defined(THREAD_MAX)
        omp_set_num_threads(THREAD_MAX);
    #endif        
    
    int n;
    int ndata = data->width;
#ifdef OPEN_MP
    #pragma omp parallel default(none) private(n) shared(ndata, opt, p, coding_val, coding_bin, block_stride, block_num)
#endif
    {
#ifdef OPEN_MP
        #pragma omp for schedule(static) nowait
#endif
        for(n=0; n<ndata; n++){
#ifdef CODING_NAME
            FUNC_PROC(CODING_NAME)(p + n*opt->length_input,
                    coding_val + n*block_stride,
                    coding_bin + n*block_num,
                    opt); 
#else
            opt->func_proc(p + n*opt->length_input,
                    coding_val + n*block_stride,
                    coding_bin + n*block_num,
                    opt); 
#endif
        }
    }
}

int CodingSelect(CodingOpt * opt)
{

	opt->func_init = NULL;
	opt->func_proc = NULL;

    if(!strcmp(opt->name, "CodingPixelHOG"))
    {        
        opt->func_init = InitCodingPixelHOG;
        opt->func_proc = FuncCodingPixelHOG;
        return 1;
    }
            
    if(!strcmp(opt->name, "CodingPixelLBP"))
    {        
        opt->func_init = InitCodingPixelLBP;
        opt->func_proc = FuncCodingPixelLBP;
        return 1;
    }
    
    if(!strcmp(opt->name, "CodingVectorQuantization"))
    {
        opt->func_init = InitCodingVectorQuantization;
        opt->func_proc = FuncCodingVectorQuantization;
        return 1;        
    }
    
    if(!strcmp(opt->name, "CodingFisherVector"))
    {        
        opt->func_init = InitCodingFisherVector;
        opt->func_proc = FuncCodingFisherVector;
        return 1;
    }
    
    return 0;
}

#ifdef MATLAB_COMPILE
// matlab helper function
void MatReadCodingOpt(const mxArray * mat_opt, CodingOpt * opt)
{
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
    
    
#ifdef CODING_NAME
    opt->func_init = NULL;
    opt->func_proc = NULL;
#else
    if(!CodingSelect(opt))
    {        
        mexPrintf("%s\n", opt->name);
        mexErrMsgTxt("Coding method is not implemented");
    }
#endif    
    
    // get codebook
    MatReadFisherVectorCodebook(mxGetField(mat_opt, 0, "fv_codebook"), &opt->fv_codebook);    
    MatReadVectorQuantizationCodebook(mxGetField(mat_opt, 0, "vq_codebook"), &opt->vq_codebook);    
}
#endif