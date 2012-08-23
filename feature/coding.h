
#ifndef CODING_H
#define CODING_H
#include "image.h"
#include "fisher_vector_coding.h"

// coding struct:
//      name: name of coding
//      func_init & func_proc: coding function
//      length_input: input featue length
//      length: coded featue length

struct CodingOpt;

typedef void (*FuncCodingInit)(CodingOpt * opt);
typedef void (*FuncCodingProc)(float * data, float * coding, int * coding_bin, const CodingOpt * opt);

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
void InitCodingPixelHOG(CodingOpt * opt)
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
void InitCodingPixelHOGHalfSphere(CodingOpt * opt)
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
        
void InitCodingPixelHOGUoC(CodingOpt * opt)
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
 
void InitCodingPixelLBP(CodingOpt * opt)
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

// ********************************* //

void InitCoding(CodingOpt * opt)
{
    opt->func_init(opt);
}

#ifndef THREAD_MAX
// normal version
void Coding(FloatMatrix * data, FloatSparseMatrix * coding, CodingOpt * opt)
{
    float * p = data->p;
    float * coding_val = coding->p;
    int * coding_bin = coding->i;
    int block_stride = opt->block_size * opt->block_num;
    int block_num = opt->block_num;
    
    for(int n=0; n<data->width; n++){
        opt->func_proc(p, coding_val, coding_bin, opt); 
        p += opt->length_input;
        coding_val += block_stride;
        coding_bin += block_num;
    }
}

#else
// MT version
struct CodingMTArgs
{
    FloatMatrix *data;
    FloatSparseMatrix *coding;
    int start;
    int end;
    const CodingOpt * opt;
};

// thread function
#if defined(WIN32)
DWORD WINAPI
#elif defined(__UNIX__)  
void *
#endif 
CodingThread(
#if defined(WIN32)
        LPVOID 
#elif defined(__UNIX__)   
        void *
#endif
        args_in)
{
    CodingMTArgs * args = (CodingMTArgs *) args_in;
    FloatMatrix * data = args->data;
    FloatSparseMatrix * coding = args->coding;
    const CodingOpt * opt = args->opt;
    int start = args->start;
    int end = args->end;
    
    int block_stride = opt->block_size * opt->block_num;
    int block_num = opt->block_num;
    
    float * p = data->p + start*opt->length_input;
    float * coding_val = coding->p + start*block_stride;
    int * coding_bin = coding->i + start*block_num;
    //printf("%d, %d, %d, %d\n", data->width, opt->length_input, block_num, block_stride);
	//return 0;
	
    for(int n=start; n<=end; n++){
        opt->func_proc(p, coding_val, coding_bin, opt);   
        p += opt->length_input;
        coding_val += block_stride;
        coding_bin += block_num;
    }

	return 0;
}

// thread caller
void Coding(FloatMatrix * data, FloatSparseMatrix * coding, CodingOpt * opt)
{
#if defined(WIN32) 
    HANDLE  hThreadArray[THREAD_MAX];
#elif defined(__UNIX__)   
    pthread_t hThreadArray[THREAD_MAX];
#endif
    
    CodingMTArgs thread_arg[THREAD_MAX];
    int ntask = data->width;
    int task_per_thread = (int)ceil(1.0*ntask/THREAD_MAX);
    
	//mexPrintf("%d, %d, %d, %d, %d, %d\n", ntask, task_per_thread, THREAD_MAX, block_num, block_stride, opt->length_input);
	//return;
    
    for(int t=0; t<THREAD_MAX; t++)
    {
        int task_start = t*task_per_thread;
        int task_num = MIN(task_per_thread, ntask-task_start);
        
        // assign input
        thread_arg[t].data = data;        
        thread_arg[t].coding = coding;
        thread_arg[t].opt = opt;
        thread_arg[t].start = task_start;
        thread_arg[t].end = task_start + task_num - 1;        
        
        // launch thread
#if defined(WIN32) 
        hThreadArray[t] = CreateThread(NULL, 0, CodingThread, &thread_arg[t], 0, NULL);
#elif defined(__UNIX__)   
        pthread_create(&hThreadArray[t], NULL, CodingThread, (void *)&thread_arg[t])
#endif
        
    }    
    
#if defined(WIN32) 
    WaitForMultipleObjects(THREAD_MAX, hThreadArray, TRUE, INFINITE);
#elif defined(__UNIX__) 
    void * status;
    for(int t=0; t<THREAD_MAX; t++) 
        pthread_join(hThreadArray[t], &status);
#endif

}

#endif

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
    
    if(!strcmp(opt->name, "CodingPixelHOGHalfSphere"))
    {        
        opt->func_init = InitCodingPixelHOGHalfSphere;
        opt->func_proc = FuncCodingPixelHOGHalfSphere;
        return 1;
    }
        
    if(!strcmp(opt->name, "CodingPixelLBP"))
    {        
        opt->func_init = InitCodingPixelLBP;
        opt->func_proc = FuncCodingPixelLBP;
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
    
    
// #ifdef CODING_NAME
//     opt->func_init = FUNC_INIT(CODING_NAME);
//     opt->func_proc = FUNC_PROC(CODING_NAME);
// #else
    if(!CodingSelect(opt))
    {        
        mexPrintf("%s\n", opt->name);
        mexErrMsgTxt("Coding method is not implemented");
    }
// #endif    
    
    // get codebook
    MatReadFisherVectorCodebook(mxGetField(mat_opt, 0, "fv_codebook"), &opt->fv_codebook);    
}
#endif

#endif

