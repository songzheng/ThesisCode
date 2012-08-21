#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mex.h"
#include "matrix.h"

#define MAX(A,B) ((A) < (B) ? (B) : (A))
#define MIN(A,B) ((A) > (B) ? (B) : (A))

// It returns a random permutation of 0..n-1
void randpermute(int * a, int n) {
    int k;
    for (k = 0; k < n; k++)
        a[k] = k;
    for (k = n-1; k > 0; k--) {
        int j = rand() % (k+1);
        int temp = a[j];
        a[j] = a[k];
        a[k] = temp;
    }
}

inline double dot(const double *x, const double *y, int dim) {
    double res = 0;   
    for(int i=0; i<dim; i++)
        res += x[i]*y[i];
    return res;
}

inline void add(double *W, const double* x, const double da, int dim) {
    for(int i=0; i<dim; i++)
        W[i] += da*x[i];
}

inline void sub(double *W, const double* x, const double da, int dim) {
    for(int i=0; i<dim; i++)
        W[i] -= da*x[i];
}

void SVMDualCoordinateDescent(const double * X, const double * label, const double * Q, // data
        const double * C, double lambda, // parameters
        double * alpha, double * w, double * b, double * loss, // model
        int num, int dim)
{          

    int * permute = new int[num];
    randpermute(permute, num);
    
    for (int ii = 0; ii < num; ii++) {
        int i = permute[ii];
        
        const double *x = X + dim*i;
        double Ci = C[i];
        
        if (Ci == 0)
            continue;
        
        double G  = label[i] * (dot(w,x,dim) + *b) - 1;
        double PG = G;
				
        if ((alpha[i] == 0 && G >= 0) || (alpha[i] >= Ci && G <= 0)) {
            PG = 0;
        }
                
        if (PG > 1e-12 || PG < -1e-12) {
            double dA = alpha[i];
            alpha[i] = MIN ( MAX ( alpha[i] - G/Q[i], 0 ) , Ci);
			//printf("Sample %d, alpha = %f == > %f", i, dA, Alpha[i]);
            dA   = alpha[i] - dA;
            loss[0] += dA;
			//printf("DualLoss 1 = %f\n", DualLoss[0]);
            label[i] >0 ? add(w,x,dA,dim):sub(w,x,dA,dim);
            *b += dA/lambda*label[i];
        }
    }
	
	loss[1] = -dot(w, w, dim)/2 - lambda/2*(*b)*(*b);
    delete [] permute;
}


void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] )
{    
    if(nrhs < 3)
         mexErrMsgTxt("Wrong Input");
    
    // data
    const double  *label  = (double  *)mxGetPr(prhs[0]);
    const double  *X  = (double   *)mxGetPr(prhs[1]);
    
    // auxilary data
    const double  *Q  = (double  *)mxGetPr(mxGetField(prhs[2], 0, "Q"));
    
    // model
    double        *alpha  = (double  *)mxGetPr(mxGetField(prhs[2], 0, "alpha"));
    double        *w  = (double  *)mxGetPr(mxGetField(prhs[2], 0, "w"));
    double        *b  = (double  *)mxGetPr(mxGetField(prhs[2], 0, "b"));
    double        *loss  = (double *)mxGetPr(mxGetField(prhs[2], 0, "loss"));
    
    // parameter
    double        lambda = (double)mxGetScalar(mxGetField(prhs[2], 0, "lambda"));
    const double  *C  = (double *)mxGetPr(mxGetField(prhs[2], 0, "C"));
           
    int dim = mxGetM(prhs[1]);
    int num = mxGetN(prhs[1]);
        
    SVMDualCoordinateDescent(X, label, Q,
        C, lambda,
        alpha, w, b, loss, 
        num, dim);
}

