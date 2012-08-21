#include <math.h>
#include <time.h>
#include <stdio.h>
#include "mex.h"

#include <windows.h>
#define THREAD_MAX 2

#define eps 0.0000001
#define GAMMA_TH 20
#define MAX(A, B) ((A) < (B) ? (B) : (A))
#define MIN(A, B) ((A) > (B) ? (B) : (A))
#define FIRST_ORDER 0
#define MAXVAL 100
#define MINVAL 1e-10
#define MINSIGMA -100
struct thread_data {
    double *data;
    double *mu;
    double *invSigma;
    double *prob;
    double *sumLogSigma;
    double *priors;
    //    int nBase;
    //    int nDim;
    mxArray *mxProb;
    
    
    int nSample_this_thread;
};

template <typename T> static inline  int sign(T val) {
    return (val > T(0)) - (val < T(0));
}
// static inline int max(int x, int y) { return (x <= y ? y : x); }


const double log2pi = 1.8379;
const double thresh = 1e-2;
const double maxSigmaRatio = 2.0;

int nDim = 0;
int nSample = 0;
int nBase = 0;

mwSize nModel = 0;
// int nRows =0;
// int nCols = 0;

DWORD WINAPI process(LPVOID thread_arg) {
    thread_data *args = (thread_data *)thread_arg;
    double *data = args->data;
    double *mu = args->mu;
    double *invSigma = args->invSigma;
    double *sumLogSigma =args->sumLogSigma;
    double *priors = args->priors;
    double *prob = args->prob;
    
    int nSample_this_thread = args->nSample_this_thread;
    
    int i, j, k;
    int indj =0, indi = 0;
    double probtemp = 0;
    
    
    
    for (j=0;j<nSample_this_thread;j++){
        
        indj = j*nDim;//+= nDim; // j*nDim;
        indi = 0;
        for (i=0;i<nBase;i++){
            probtemp =sumLogSigma[i];
            for (k=0;k<nDim;k++){                
//                 if ((j==0)&&(i==0)&&(k<100))mexPrintf("%f,", probtemp);
                probtemp+= (data[indj+k]-mu[indi+k])*(data[indj+k]-mu[indi+k])*invSigma[indi+k];
            }
            //   if ((i==1)&&(j<100))mexPrintf("%f..", prob[indx]);
            probtemp =probtemp*-0.5;
//            probtemp = MIN(probtemp,MAXVAL);
            
            prob[i*nSample_this_thread+j] = exp(probtemp)*priors[i];

            
            indi = indi+nDim;//i*nDim;
        }
        //
        //          mexPrintf("%d..%d..%d\\..", nSample_this_thread,nBase,nDim);
        //     return 0;
    };
    double sumProb=0;
    
    int tempind = 0;
    for (i=0;i<nSample_this_thread;i++){
        sumProb = 0;
        for (j=0;j<nBase;j++){
            sumProb+=prob[j*nSample_this_thread+i];
        }
        //sumProb = MAX(MINVAL,sumProb);
        for (j=0;j<nBase;j++){
            tempind = j*nSample_this_thread+i;
            prob[tempind]/=sumProb;
            if (prob[tempind]<thresh){
                prob[tempind] = 0;
            }
        }
    }
    return 0;
}
void calc_prob(double *data, double *mu, double *sigma, double *priors, double *prob){
    double *invSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    double *sumLogSigma = (double *)mxCalloc(nBase, sizeof(double));
    
    int i, j, k;
    for (i=0;i<nBase*nDim;i++){
        invSigma[i] = 1/sigma[i];
    };
    for (i=0;i<nBase;i++){
        sumLogSigma[i] = 0;
        for (j=0;j<nDim;j++){
            sumLogSigma[i]+=log(sigma[i*nDim+j]);
        }
        sumLogSigma[i]+=nDim*log2pi;
       // sumLogSigma[i] = MAX(MINSIGMA,sumLogSigma[i]);
    }
    

    //     double cpuTime;
    //     clock_t start, end;
    //     start = clock();
    
    thread_data *td = (thread_data *)mxCalloc(THREAD_MAX, sizeof(thread_data));
    HANDLE  *hThreadArray = (HANDLE *)mxCalloc(THREAD_MAX, sizeof(HANDLE));
    
    int batch_len = floor(1.0*nSample/THREAD_MAX);
    
    
//                 mexPrintf("%f..", sumLogSigma[0]);
                 
    int out[2];
    
    int ind_start =0;
    for (i=0;i<THREAD_MAX;i++){
        td[i].data = data + ind_start*nDim;
        td[i].mu = mu;
        td[i].invSigma = invSigma;
        td[i].sumLogSigma =sumLogSigma;
        td[i].priors = priors;
        
        if (i<THREAD_MAX-1){
            td[i].nSample_this_thread = batch_len;
        }else{
            td[i].nSample_this_thread = MAX(batch_len,nSample-(THREAD_MAX-1)*batch_len);
        }
        
        out[0] = td[i].nSample_this_thread;
        out[1] = nBase;
        
        //           td[i].mxProb = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
        
        //       mexPrintf("%d..", td[i].nSample_this_thread*nBase);
        td[i].prob = (double *)calloc(td[i].nSample_this_thread*nBase,sizeof(double));//mxGetPr(td[i].mxProb);
        
        hThreadArray[i] = CreateThread(
        NULL,
        0,
        process,
        &td[i],
        0,
        NULL);
        
        ind_start += batch_len;
        
//         mexPrintf("%d..", i);
        
        if (hThreadArray[i] == NULL)
            mexErrMsgTxt("Error creating thread");
    };

    // wait for the treads to finish and set return values
    WaitForMultipleObjects(THREAD_MAX, hThreadArray, TRUE, INFINITE);
//             mexPrintf("%f..", td[0].prob[1]);
//     return;
    ind_start =0;
    for (i = 0; i < THREAD_MAX; i++) {
        CloseHandle(hThreadArray[i]);
        for (j = 0; j< td[i].nSample_this_thread; j++){
            for (k=0;k< nBase;k++){
                prob[k*nSample+j+ind_start]+=td[i].prob[k*td[i].nSample_this_thread+j];
            }
        }
        
        ind_start += batch_len;
        
        free(td[i].prob);
       }
    //     end  = clock();
    //     cpuTime = difftime(end,start)/(CLOCKS_PER_SEC);
    //     mexPrintf("%f..", cpuTime);
    mxFree(invSigma);
    mxFree(sumLogSigma);
    mxFree(td);
    mxFree(hThreadArray);
}


void fisher_coding(double *data, double *mu, double *sigma, double *priors, double *prob, double *coding) {
    double *sqrtInvSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    
    #if (!FIRST_ORDER)
    double *invSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    
    //    double *maxsqrtSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    #endif
    
    int i, j, k;
    for (i=0;i<nBase*nDim;i++){
        sqrtInvSigma[i] = 1/sqrt(sigma[i]);
        
        #if (!FIRST_ORDER)
        invSigma[i] = 1/sigma[i];
        
        //        maxsqrtSigma[i] = sqrt(sigma[i])*maxSigmaRatio;
        #endif
    };
    
    //double thresh = 1e-10;
    double temp = 0;
    for (i=0;i<nBase;i++){
        for (j=0;j<nSample;j++){
            if (prob[i*nSample+j]<thresh)continue;
            for (k=0;k<nDim;k++){
                temp = (data[j*nDim+k]-mu[i*nDim+k]);
                //  temp = sign(temp)*MIN(maxsqrtSigma[i*nDim+k],fabs(temp));
                #if (!FIRST_ORDER)
                coding[i*nDim*2+k]+= prob[i*nSample+j]*temp*sqrtInvSigma[i*nDim+k];
                coding[i*nDim*2+k+nDim]+= prob[i*nSample+j]*temp*temp*invSigma[i*nDim+k]-prob[i*nSample+j];
                #else
                coding[i*nDim+k]+= prob[i*nSample+j]*temp*sqrtInvSigma[i*nDim+k];
                #endif
            }
        }
        for (k=0;k<nDim;k++){
            //             coding[i*nDim*2+k]/=nSample*sqrt(priors[i]);
            //             coding[i*nDim*2+k+nDim]/=nSample*sqrt(2*priors[i]);
            #if (!FIRST_ORDER)
            coding[i*nDim*2+k]/=sqrt(priors[i]);
            coding[i*nDim*2+k+nDim]/=sqrt(2*priors[i]);
            #else
            coding[i*nDim+k]/=sqrt(priors[i]);
            #endif
        }
    };
    mxFree(sqrtInvSigma);
    
    #if (!FIRST_ORDER)
    //mxFree(maxsqrtSigma);
    mxFree(invSigma);
    #endif
}


void conf_model(double *data, double *mu, double *sigma, double *priors, double *prob, double *model_w, double *conf) {
    //    int nSample = mxGetN(mxFea);
    //    int nDim = mxGetM(mxFea);
    //    double *fea = (double*)mxGetPr(mxFea);
    
    //    int *ir = (int*)mxGetPr(mxGetField(mxProb,0,"ii"));
    //    int *jc = (int*)mxGetPr(mxGetField(mxProb,0,"jj"));
    //    double *prob_val = mxGetPr(mxGetField(mxProb,0,"vv"));
    int i, j, k;
    
    int *ir = (int *)mxCalloc(nSample*GAMMA_TH, sizeof(int)); //nsample
    int *jc = (int *)mxCalloc(nSample*GAMMA_TH, sizeof(int)); //nbase
    double *prob_val =(double *)mxCalloc(nSample*GAMMA_TH, sizeof(double));
    int nz=0;
    for (i=0;i<nSample;i++){
        for (j=0;j<nBase;j++){
            if((prob[j*nSample+i]>=thresh)&&(nz<nSample*GAMMA_TH)){
                ir[nz] = i;
                jc[nz] = j;
                prob_val[nz] = prob[j*nSample+i];
                nz++;
            }
        }
    }
    
    //mexPrintf("\n %f ", double(nz)/nSample);
    
    if (nz==nSample*GAMMA_TH){
        mexErrMsgTxt("Too many prob!, increase Gamma_th...\n");
    }
    
    //   mwSize nModel = mxGetNumberOfElements(mxModel);
    
    //  mwSize out[2];
    //  out[0] = nSample;
    // out[1] = nModel;
    
    //    mxArray *mxConf = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    //   double *conf= (double *)mxGetPr(mxConf);
    #if FIRST_ORDER
    int nModelDim = nDim*nBase;
    #else
    int nModelDim = nDim*nBase*2;
    #endif
    double *sqrtInvSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    
    double *tempDataInt = (double *)mxCalloc(nDim, sizeof(double));
    double *tempDataFir = (double *)mxCalloc(nDim, sizeof(double));
    double *tempGmmSqrtPrior = (double *)mxCalloc(nBase, sizeof(double));
    #if (!FIRST_ORDER)
    double *invSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    double *tempGmmTwoSqrtPrior = (double *)mxCalloc(nBase, sizeof(double));
    double *tempDataSec = (double *)mxCalloc(nDim, sizeof(double));
    #endif
    
    #if (FIRST_ORDER)
    for (i=0;i<nBase*nDim;i++){
        sqrtInvSigma[i] = 1/sqrt(sigma[i]);
    };
    for (i=0;i<nBase;i++){
        tempGmmSqrtPrior[i] = sqrt(priors[i]);
    };
    int temp = 0, temp2 = 0;
    int tempDim = nDim;
    for (i=0;i<nz;i++){
        for (j=0;j<nDim;j++){
            tempDataInt[j] = (data[ir[i]*nDim+j]-mu[jc[i]*nDim+j]);
        }
        for (j=0;j<nDim;j++){
            tempDataFir[j] = prob_val[i]*tempDataInt[j]*sqrtInvSigma[jc[i]*nDim+j]/tempGmmSqrtPrior[jc[i]];
        }
        for (k=0; k<nModel; k++){
            temp = k*nSample;
            temp2 = k*nModelDim;
            for(j=0;j<nDim;j++){
                conf[temp+ir[i]]+= tempDataFir[j]*model_w[temp2+jc[i]*tempDim+j];
            }
        }
    }
    
    mxFree(sqrtInvSigma);
    mxFree(tempDataInt);
    mxFree(tempDataFir);
    mxFree(tempGmmSqrtPrior);
    #else
    for (i=0;i<nBase*nDim;i++){
        invSigma[i] = 1/sigma[i];
        sqrtInvSigma[i] = 1/sqrt(sigma[i]);
    };
    for (i=0;i<nBase;i++){
        tempGmmSqrtPrior[i] = sqrt(priors[i]);
        tempGmmTwoSqrtPrior[i] = sqrt(2*priors[i]);
    }
    int temp = 0, temp2 = 0;
    int tempDim = nDim*2;
    for (i=0;i<nz;i++){
        for (j=0;j<nDim;j++){
            tempDataInt[j] = (data[ir[i]*nDim+j]-mu[jc[i]*nDim+j]);
        }
        for (j=0;j<nDim;j++){
            tempDataFir[j] = prob_val[i]*tempDataInt[j]*sqrtInvSigma[jc[i]*nDim+j]/tempGmmSqrtPrior[jc[i]];
            tempDataSec[j] = (prob_val[i]*tempDataInt[j]*tempDataInt[j]*invSigma[jc[i]*nDim+j]-prob_val[i])/tempGmmTwoSqrtPrior[jc[i]];
        }
        for (k=0; k<nModel; k++){
            temp = k*nSample;
            temp2 = k*nModelDim;
            for(j=0;j<nDim;j++){
                //                 conf[k*nSample+ir[i]]+= (prob_val[i]*tempDataInt[j]*sqrtInvSigma[jc[i]*nDim+j]*model_w[k*nModelDim+jc[i]*nDim*2+j])/sqrt(gmmPriors[jc[i]]);
                //                 conf[k*nSample+ir[i]]+= (prob_val[i]*tempDataInt[j]*tempDataInt[j]*invSigma[jc[i]*nDim+j]-prob_val[i])*model_w[k*nModelDim+jc[i]*nDim*2+nDim+j]/sqrt(2*gmmPriors[jc[i]]);
                conf[temp+ir[i]]+= tempDataFir[j]*model_w[temp2+jc[i]*tempDim+j];
                conf[temp+ir[i]]+= tempDataSec[j]*model_w[temp2+jc[i]*tempDim+nDim+j];
                
            }
        }
    }
    
    
    //     for(i = 0;i<nSample*nModel;i++){
    //         conf[i]/=nSample;
    //     }
    
    mxFree(invSigma);
    mxFree(sqrtInvSigma);
    mxFree(tempDataInt);
    mxFree(tempDataFir);
    mxFree(tempDataSec);
    mxFree(tempGmmSqrtPrior);
    mxFree(tempGmmTwoSqrtPrior);
    
    
    #endif
    
    mxFree(ir);
    mxFree(jc);
    mxFree(prob_val);
    
    
}



void conf_model_datanorm(double *data, double *mu, double *sigma, double *priors, double *prob, double *model_w, double *conf,double *datanorm) {
    //    int nSample = mxGetN(mxFea);
    //    int nDim = mxGetM(mxFea);
    //    double *fea = (double*)mxGetPr(mxFea);
    
    //    int *ir = (int*)mxGetPr(mxGetField(mxProb,0,"ii"));
    //    int *jc = (int*)mxGetPr(mxGetField(mxProb,0,"jj"));
    //    double *prob_val = mxGetPr(mxGetField(mxProb,0,"vv"));
    int i, j, k;
    
    int *ir = (int *)mxCalloc(nSample*GAMMA_TH, sizeof(int)); //nsample
    int *jc = (int *)mxCalloc(nSample*GAMMA_TH, sizeof(int)); //nbase
    double *prob_val =(double *)mxCalloc(nSample*GAMMA_TH, sizeof(double));
    int nz=0;
    for (i=0;i<nSample;i++){
        for (j=0;j<nBase;j++){
            if((prob[j*nSample+i]>=thresh)&&(nz<nSample*GAMMA_TH)){
                ir[nz] = i;
                jc[nz] = j;
                prob_val[nz] = prob[j*nSample+i];
                nz++;
            }
        }
    }
    
    //mexPrintf("\n %f ", double(nz)/nSample);
    
    if (nz==nSample*GAMMA_TH){
        mexErrMsgTxt("Too many prob!, increase Gamma_th...\n");
    }
    
    //   mwSize nModel = mxGetNumberOfElements(mxModel);
    
    //  mwSize out[2];
    //  out[0] = nSample;
    // out[1] = nModel;
    
    //    mxArray *mxConf = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    //   double *conf= (double *)mxGetPr(mxConf);
    #if FIRST_ORDER
    int nModelDim = nDim*nBase;
    #else
    int nModelDim = nDim*nBase*2;
    #endif
    double *sqrtInvSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    
    double *tempDataInt = (double *)mxCalloc(nDim, sizeof(double));
    double *tempDataFir = (double *)mxCalloc(nDim, sizeof(double));
    double *tempGmmSqrtPrior = (double *)mxCalloc(nBase, sizeof(double));
    #if (!FIRST_ORDER)
    double *invSigma = (double *)mxCalloc(nDim*nBase, sizeof(double));
    double *tempGmmTwoSqrtPrior = (double *)mxCalloc(nBase, sizeof(double));
    double *tempDataSec = (double *)mxCalloc(nDim, sizeof(double));
    #endif
    
    #if (FIRST_ORDER)
    for (i=0;i<nBase*nDim;i++){
        sqrtInvSigma[i] = 1/sqrt(sigma[i]);
    };
    for (i=0;i<nBase;i++){
        tempGmmSqrtPrior[i] = sqrt(priors[i]);
    };
    int temp = 0, temp2 = 0;
    int tempDim = nDim;
    for (i=0;i<nz;i++){
        for (j=0;j<nDim;j++){
            tempDataInt[j] = (data[ir[i]*nDim+j]-mu[jc[i]*nDim+j]);
        }
        for (j=0;j<nDim;j++){
            tempDataFir[j] = prob_val[i]*tempDataInt[j]*sqrtInvSigma[jc[i]*nDim+j]/tempGmmSqrtPrior[jc[i]];
            datanorm[ir[i]] +=tempDataFir[j]*tempDataFir[j]; 
        }
        for (k=0; k<nModel; k++){
            temp = k*nSample;
            temp2 = k*nModelDim;
            for(j=0;j<nDim;j++){
                conf[temp+ir[i]]+= tempDataFir[j]*model_w[temp2+jc[i]*tempDim+j];
            }
        }
    }
    
    mxFree(sqrtInvSigma);
    mxFree(tempDataInt);
    mxFree(tempDataFir);
    mxFree(tempGmmSqrtPrior);
    #else
    for (i=0;i<nBase*nDim;i++){
        invSigma[i] = 1/sigma[i];
        sqrtInvSigma[i] = 1/sqrt(sigma[i]);
    };
    for (i=0;i<nBase;i++){
        tempGmmSqrtPrior[i] = sqrt(priors[i]);
        tempGmmTwoSqrtPrior[i] = sqrt(2*priors[i]);
    }
    int temp = 0, temp2 = 0;
    int tempDim = nDim*2;
    for (i=0;i<nz;i++){
        for (j=0;j<nDim;j++){
            tempDataInt[j] = (data[ir[i]*nDim+j]-mu[jc[i]*nDim+j]);
        }
        for (j=0;j<nDim;j++){
            tempDataFir[j] = prob_val[i]*tempDataInt[j]*sqrtInvSigma[jc[i]*nDim+j]/tempGmmSqrtPrior[jc[i]];
            tempDataSec[j] = (prob_val[i]*tempDataInt[j]*tempDataInt[j]*invSigma[jc[i]*nDim+j]-prob_val[i])/tempGmmTwoSqrtPrior[jc[i]];
            datanorm[ir[i]] +=tempDataFir[j]*tempDataFir[j]; 
            datanorm[ir[i]] +=tempDataSec[j]*tempDataSec[j];
        }
        for (k=0; k<nModel; k++){
            temp = k*nSample;
            temp2 = k*nModelDim;
            for(j=0;j<nDim;j++){
                //                 conf[k*nSample+ir[i]]+= (prob_val[i]*tempDataInt[j]*sqrtInvSigma[jc[i]*nDim+j]*model_w[k*nModelDim+jc[i]*nDim*2+j])/sqrt(gmmPriors[jc[i]]);
                //                 conf[k*nSample+ir[i]]+= (prob_val[i]*tempDataInt[j]*tempDataInt[j]*invSigma[jc[i]*nDim+j]-prob_val[i])*model_w[k*nModelDim+jc[i]*nDim*2+nDim+j]/sqrt(2*gmmPriors[jc[i]]);
                conf[temp+ir[i]]+= tempDataFir[j]*model_w[temp2+jc[i]*tempDim+j];
                conf[temp+ir[i]]+= tempDataSec[j]*model_w[temp2+jc[i]*tempDim+nDim+j];
                
            }
        }
    }
    
    
    //     for(i = 0;i<nSample*nModel;i++){
    //         conf[i]/=nSample;
    //     }
    
    mxFree(invSigma);
    mxFree(sqrtInvSigma);
    mxFree(tempDataInt);
    mxFree(tempDataFir);
    mxFree(tempDataSec);
    mxFree(tempGmmSqrtPrior);
    mxFree(tempGmmTwoSqrtPrior);
    
    
    #endif
    
    mxFree(ir);
    mxFree(jc);
    mxFree(prob_val);
    
    
}



void map_conf(double *conf, int *pos, int nRows, int nCols, int nMap, double *map){
    
    int oneMapSize = nRows*nCols;
    for(int i=0;i<oneMapSize*nMap;i++) {
        map[i]=0;
    }
    for(int j = 0;j<nMap;j++){
        for(int i=0;i<nSample;i++) {
            //index  = pos[i*2]*nCols+pos[i*2+1];
            map[(pos[i*2+1]-1)*nRows+pos[i*2]-1+j*oneMapSize] += conf[i+nSample*j];
        }
    }
}




//get soft assignment prob from data and GMM model; process_mode1(data, GMM,prob);
void process_mode1(const mxArray *mxfea, const mxArray *mxGMM, mxArray *output[]) {
    double *fea = (double *)mxGetPr(mxfea);
    const int *dims = mxGetDimensions(mxfea);
    nDim = dims[0];
    nSample = dims[1];
    
    double *gmmMu = (double *)mxGetPr(mxGetField(mxGMM, 0, "Mu"));
    
    double *gmmSigma = (double *)mxGetPr(mxGetField(mxGMM, 0, "Sigma"));
    // //mexPrintf("\n %f %f %f.", gmmSigma[0],gmmSigma[1],gmmSigma[2]);
    
    
    double *gmmPriors = (double *)mxGetPr(mxGetField(mxGMM, 0, "Priors"));
    const int *dims2 = mxGetDimensions(mxGetField(mxGMM, 0, "Mu"));
    nBase = dims2[1];
    int nDim2 = dims2[0];
    if (nDim!=nDim2) mexErrMsgTxt("the dim of feature and gmm model is different!");
    
    int out[2];
    out[0] = nSample;
    out[1] = nBase;
    mxArray *mxProb = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    double *prob = (double *)mxGetPr(mxProb);
    ////mexPrintf("%d.%d.%d.\n", nBase, nSample,nDim);
    
    calc_prob(fea, gmmMu, gmmSigma, gmmPriors, prob);
    output[0] = mxProb;
    //    //mexPrintf("%f.%f.%f.%f\n", prob[0], prob[1],prob[2],prob[3]);
    //     return;
    
}

//get coding from data, prob and GMM; process_model2(data,prob,GMM,coding);
void process_mode2(const mxArray *mxfea, const mxArray *mxProb, const mxArray *mxGMM, mxArray *output[]) {
    double *fea = (double *)mxGetPr(mxfea);
    const mwSize *dims = mxGetDimensions(mxfea);
    nDim = dims[0];
    nSample = dims[1];
    double *gmmMu = (double *)mxGetPr(mxGetField(mxGMM, 0, "Mu"));
    double *gmmSigma = (double *)mxGetPr(mxGetField(mxGMM, 0, "Sigma"));
    double *gmmPriors = (double *)mxGetPr(mxGetField(mxGMM, 0, "Priors"));
    const mwSize *dims2 = mxGetDimensions(mxGetField(mxGMM, 0, "Mu"));
    nBase = dims2[1];
    int nDim2 = dims2[0];
    if (nDim!=nDim2) mexErrMsgTxt("the dim of feature and gmm model is different!");
    
    double *prob = (double *)mxGetPr(mxProb);
    mwSize out[2];
    #if (FIRST_ORDER)
    out[0] = nBase*nDim;
    
    #else
    out[0] = nBase*nDim*2 ;
    #endif
    out[1] = 1;
    mxArray *mxCoding = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    double *coding = (double *)mxGetPr(mxCoding);
    //mexPrintf("%f %f %f \n",prob[1], prob[2],prob[4]);
    if (nSample==0){
        mexPrintf("wrong! the coding samples is zeros!!!...... \n");
        
    }else{
        fisher_coding(fea, gmmMu, gmmSigma, gmmPriors, prob, coding);
    }
    output[0] = mxCoding;
}


//get coding from data and GMM; process_model3(data,GMM,coding);
void process_mode3(const mxArray *mxfea, const mxArray *mxGMM, mxArray *output[]) {
    double *fea = (double *)mxGetPr(mxfea);
    const int *dims = mxGetDimensions(mxfea);
    nDim = dims[0];
    nSample = dims[1];
    double *gmmMu = (double *)mxGetPr(mxGetField(mxGMM, 0, "Mu"));
    
    double *gmmSigma = (double *)mxGetPr(mxGetField(mxGMM, 0, "Sigma"));
    // //mexPrintf("\n %f %f %f.", gmmSigma[0],gmmSigma[1],gmmSigma[2]);
    
    double *gmmPriors = (double *)mxGetPr(mxGetField(mxGMM, 0, "Priors"));
    const int *dims2 = mxGetDimensions(mxGetField(mxGMM, 0, "Mu"));
    nBase = dims2[1];
    int nDim2 = dims2[0];
    if (nDim!=nDim2) mexErrMsgTxt("the dim of feature and gmm model is different!");
    
    mwSize out[2];
    out[0] = nSample;
    out[1] = nBase;
    
    double *prob = (double *)mxCalloc(nSample*nBase, sizeof(double));
    calc_prob(fea, gmmMu, gmmSigma, gmmPriors, prob);
    
    #if (FIRST_ORDER)
    out[0] = nBase*nDim;
    
    #else
    out[0] = nBase*nDim*2 ;
    #endif
    out[1] = 1;
    mxArray *mxCoding = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    double *coding = (double *)mxGetPr(mxCoding);
    //     //mexPrintf("%f %f %f \n",prob[1], prob[2],prob[4]);
    if (nSample==0){
        //mexPrintf("wrong! the coding samples is zeros!!!...... \n");
        
    }else{
        fisher_coding(fea, gmmMu, gmmSigma, gmmPriors, prob, coding);
    }
    output[0] = mxCoding;
    mxFree(prob);
}

//get conf from data, prob,GMM, model; process_model4(data,prob, GMM, model,conf);
void process_mode4(const mxArray *mxfea, const mxArray *mxProb, const mxArray *mxGMM, const mxArray *mxModels, mxArray *output[]) {
    double *fea = (double *)mxGetPr(mxfea);
    const int *dims = mxGetDimensions(mxfea);
    nDim = dims[0];
    nSample = dims[1];
    double *gmmMu = (double *)mxGetPr(mxGetField(mxGMM, 0, "Mu"));
    
    double *gmmSigma = (double *)mxGetPr(mxGetField(mxGMM, 0, "Sigma"));
    // //mexPrintf("\n %f %f %f.", gmmSigma[0],gmmSigma[1],gmmSigma[2]);
    
    double *gmmPriors = (double *)mxGetPr(mxGetField(mxGMM, 0, "Priors"));
    double *prob = (double *)mxGetPr(mxProb);
    nModel = mxGetNumberOfElements(mxModels);
    const int *dims2 = mxGetDimensions(mxGetField(mxGMM, 0, "Mu"));
    nBase = dims2[1];
    
    mwSize out[2];
    out[0] = nSample;
    out[1] = nModel;
    
    mxArray *mxConf = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    double *conf= (double *)mxGetPr(mxConf);
    
    #if (FIRST_ORDER)
    int nModelDim = nDim*nBase;
    #else
    int nModelDim = nDim*nBase*2;
    #endif
    
    double *model_w = (double *)mxCalloc(nModelDim*nModel, sizeof(double));
    int i, j;
    for(i=0;i<nModel;i++){
        mxArray *tempModel = mxGetCell(mxModels, i);
        //double *w = (double *)mxGetPr(mxGetField(tempModel, 0, "w_reshape"));
        double *w = (double *)mxGetPr(mxGetField(tempModel, 0, "w"));
        for (j=0;j<nModelDim;j++){
            model_w[i*nModelDim+j] = w[j];
        }
    }
    
    conf_model(fea, gmmMu, gmmSigma, gmmPriors, prob, model_w, conf);
    output[0] = mxConf;
    mxFree(model_w);
}

//get map from conf and int32 pos,int32 size;
void process_mode5(const mxArray *mxConf, const mxArray *mxPos, const mxArray *mxMapSize, mxArray *output[]) {
    const int *dims = mxGetDimensions(mxConf);
    nSample = dims[0];
    int nMap = dims[1];
    int *mapSize = (int*) mxGetPr(mxMapSize);
    
    int nRows =mapSize[0];
    int nCols = mapSize[1];
    int nSample2 = mxGetN(mxPos);
    
    if (nSample2!=nSample)  mexErrMsgTxt("invalid input");
    
    // //mexPrintf("%d %d %d \n",nSample2, nRows,nCols);
    double *conf = (double*)mxGetPr(mxConf);
    int *pos = (int*)mxGetPr(mxPos);
    
    //mexPrintf("\n %d %d %d.", nMap,nSample,nRows);
    
    int outputdims []= {nRows, nCols, nMap};
    
    //mexPrintf("\n %d %d %d.", nRows,nCols,nMap);
    
    
    mxArray *mxMap =  mxCreateNumericArray(3, outputdims , mxDOUBLE_CLASS, mxREAL);
    
    double *map = mxGetPr(mxMap);
    
    map_conf(conf, pos, nRows, nCols, nMap, map);
    output[0] = mxMap;
}

// get map from data, GMM, model, pos,size;
void process_mode6(const mxArray *mxfea, const mxArray *mxGMM, const mxArray *mxModels, const mxArray *mxPos, const mxArray *mxMapSize, mxArray *output[]) {
    double *fea = (double *)mxGetPr(mxfea);
    const mwSize *dims = mxGetDimensions(mxfea);
    nDim = dims[0];
    nSample = dims[1];
    double *gmmMu = (double *)mxGetPr(mxGetField(mxGMM, 0, "Mu"));
    double *gmmSigma = (double *)mxGetPr(mxGetField(mxGMM, 0, "Sigma"));
    double *gmmPriors = (double *)mxGetPr(mxGetField(mxGMM, 0, "Priors"));
    const mwSize *dims2 = mxGetDimensions(mxGetField(mxGMM, 0, "Mu"));
    nBase = dims2[1];
    int nDim2 = dims2[0];
    if (nDim!=nDim2) mexErrMsgTxt("the dim of feature and gmm model is different!");
    
    double *prob = (double *)mxCalloc(nSample*nBase, sizeof(double));
    
    calc_prob(fea, gmmMu, gmmSigma, gmmPriors, prob);
    
    
    nModel = mxGetNumberOfElements(mxModels);
    
    double *conf= (double *)mxCalloc(nSample*nModel, sizeof(double));
    
    #if (FIRST_ORDER)
    int nModelDim = nDim*nBase;
    #else
    int nModelDim = nDim*nBase*2;
    #endif
    double *model_w = (double *)mxCalloc(nModelDim*nModel, sizeof(double));
    int i, j;
    for(i=0;i<nModel;i++){
        mxArray *tempModel = mxGetCell(mxModels, i);
        //        double *w = (double *)mxGetPr(mxGetField(tempModel, 0, "w_reshape"));
        double *w = (double *)mxGetPr(mxGetField(tempModel, 0, "w"));
        
        for (j=0;j<nModelDim;j++){
            model_w[i*nModelDim+j] = w[j];
        }
    }
    conf_model(fea, gmmMu, gmmSigma, gmmPriors, prob, model_w, conf);
    
    //mexPrintf("\n %f %d %d.", conf[1],nDim,nSample);
    
    int *mapSize = (int*) mxGetPr(mxMapSize);
    
    int nRows =mapSize[0];
    int nCols = mapSize[1];
    int nSample2 = mxGetN(mxPos);
    
    int *pos = (int*)mxGetPr(mxPos);
    
    int out []= {nRows, nCols, nModel};
    
    //mexPrintf("%d %d %d \n",nModel, nRows,nCols);
    
    
    mxArray *mxMap =  mxCreateNumericArray(3, out , mxDOUBLE_CLASS, mxREAL);
    double *map = mxGetPr(mxMap);
    
    map_conf(conf, pos, nRows, nCols, nModel, map);
    output[0] = mxMap;
    // mxSetPr(output[0],conf);
    
    mxFree(conf);
    mxFree(model_w);
    mxFree(prob);
}

//get conf and datanorm from data, prob,GMM, model; process_model7(data,prob, GMM, model,conf/datanorm);
void process_mode7(const mxArray *mxfea, const mxArray *mxProb, const mxArray *mxGMM, const mxArray *mxModels, mxArray *output[]) {
    double *fea = (double *)mxGetPr(mxfea);
    const int *dims = mxGetDimensions(mxfea);
    nDim = dims[0];
    nSample = dims[1];
    double *gmmMu = (double *)mxGetPr(mxGetField(mxGMM, 0, "Mu"));
    
    double *gmmSigma = (double *)mxGetPr(mxGetField(mxGMM, 0, "Sigma"));
    // //mexPrintf("\n %f %f %f.", gmmSigma[0],gmmSigma[1],gmmSigma[2]);
    
    double *gmmPriors = (double *)mxGetPr(mxGetField(mxGMM, 0, "Priors"));
    double *prob = (double *)mxGetPr(mxProb);
    nModel = mxGetNumberOfElements(mxModels);
    const int *dims2 = mxGetDimensions(mxGetField(mxGMM, 0, "Mu"));
    nBase = dims2[1];
    
    mwSize out[2];
    out[0] = nSample;
    out[1] = nModel;
    
    mxArray *mxConf = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    double *conf= (double *)mxGetPr(mxConf);

    out[0] = nSample;
    out[1] = 1;
    mxArray *mxDataNorm = mxCreateNumericArray(2, out, mxDOUBLE_CLASS, mxREAL);
    double *dataNorm= (double *)mxGetPr(mxDataNorm);
    
    #if (FIRST_ORDER)
    int nModelDim = nDim*nBase;
    #else
    int nModelDim = nDim*nBase*2;
    #endif
    
    double *model_w = (double *)mxCalloc(nModelDim*nModel, sizeof(double));
    int i, j;
    for(i=0;i<nModel;i++){
        mxArray *tempModel = mxGetCell(mxModels, i);
        //double *w = (double *)mxGetPr(mxGetField(tempModel, 0, "w_reshape"));
        double *w = (double *)mxGetPr(mxGetField(tempModel, 0, "w"));
        for (j=0;j<nModelDim;j++){
            model_w[i*nModelDim+j] = w[j];
        }
    }
    
    conf_model_datanorm(fea, gmmMu, gmmSigma, gmmPriors, prob, model_w, conf,dataNorm);
    output[0] = mxConf;
    output[1] = mxDataNorm;
    mxFree(model_w);
}



bool check_input(const mxArray *input[]){
    return true;
}
// matlab entry point
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)mexErrMsgTxt("invalid input");
    //     process_prob(prhs[0], prhs[1], plhs);
    if (check_input(prhs)){
        int mode = (int)mxGetScalar(prhs[0]);
        // mexPrintf("mode no.%d...\n", mode);
        switch(mode) {
            case 1:
                
                process_mode1(prhs[1], prhs[2], plhs); //get soft assignment prob from data and GMM model; process_mode1(data, GMM,prob);
                break;
            case 2:
                process_mode2(prhs[1], prhs[2], prhs[3], plhs); //get coding from data, prob and GMM; process_model2(data,prob,GMM,coding);
                break;
                
            case 3:
                process_mode3(prhs[1], prhs[2], plhs); //get coding from data and GMM; process_model3(data,GMM,coding);
                break;
                
            case 4:
                process_mode4(prhs[1], prhs[2], prhs[3], prhs[4], plhs); //get conf from data, prob,GMM, model; process_model4(data,prob, GMM, model,conf);
                break;
                
            case 5:
                process_mode5(prhs[1], prhs[2], prhs[3], plhs) ; //get map from conf and pos, size;
                break;
                
            case 6:
                process_mode6(prhs[1], prhs[2], prhs[3], prhs[4], prhs[5], plhs) ; // get map from data, GMM, model, pos,size;
                break;
            case 7:
                process_mode7(prhs[1], prhs[2], prhs[3], prhs[4], plhs); //get conf and datanorm from data, prob,GMM, model; process_model4(data,prob, GMM, model,conf);
                break;
            default:
                return;
        }
    }

    return;
}


