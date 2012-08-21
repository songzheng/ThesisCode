#define MATLAB_EXPORT
#include <mex.h>
#include "../src/AgeEstimation/AgeEstimation.cpp"

mxArray * CopyFloatMatrixToMxArray(FloatMatrix src )
{    
    mxArray *dst = mxCreateNumericMatrix(src.size[0], src.size[1], mxDOUBLE_CLASS, mxREAL);
    double * pdata = (double *)mxGetPr(dst);
    for(int i=0; i<src.size[0] * src.size[1]; i++)
        pdata[i] = (double)src.data[i];
    
    return dst;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    if (nrhs != 1 && mxGetClassID(prhs[0]) != mxUINT8_CLASS
            && mxGetNumberOfDimensions(prhs[0]) != 3)
        mexErrMsgTxt("Wrong number of inputs");
    if (nlhs != 1)
        mexErrMsgTxt("Wrong number of outputs");
    
    Age estimator;
    
    const int * dims = mxGetDimensions(prhs[0]);
    int width = dims[1];
    int height = dims[0];
    Byte * im_origin = (Byte *)mxGetPr(prhs[0]);
    
    int stride = 3*width;
    Byte * im = (Byte *)mxCalloc(3*width*height, sizeof(Byte));
    for(int i=0; i<height; i++)
        for(int j=0; j<width; j++)
            for(int c=0; c<3; c++)
                im[i*stride + 3*j + c] = im_origin[c*width*height + j*height + i];
    
    FloatMatrix im_norm = estimator.ConvertImageToMatrix(im, stride, width, height);
	FloatMatrix feature = estimator.BIFFeature(im_norm);
    plhs[0] = CopyFloatMatrixToMxArray(feature);
    im_norm.FreeMatrix();
    feature.FreeMatrix();
}