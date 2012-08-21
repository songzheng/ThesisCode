#include <mex.h>
#include "WarpImage.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs != 5)
        mexErrMsgTxt("Wrong number of inputs");
    if (nlhs != 2 && nlhs != 1)
        mexErrMsgTxt("Wrong number of outputs");
    
    const mxArray *mxIm = prhs[0], *mxPts = prhs[1], *mxLandmark = prhs[2],
            *mxLandmarkTarget = prhs[3], *mxSizeTarget = prhs[4];
    
    if (mxGetClassID(mxIm) != mxUINT8_CLASS 
            && mxGetNumberOfDimensions(mxIm) != 3)
        mexErrMsgTxt("Invalid input: image");
    
    if (mxGetClassID(mxLandmark) != mxDOUBLE_CLASS 
            && mxGetNumberOfElements(mxLandmark) != 4)
        mexErrMsgTxt("Invalid input: landmark");    
    
    if (mxGetClassID(mxLandmarkTarget) != mxDOUBLE_CLASS
            && mxGetNumberOfElements(mxLandmarkTarget) != 4)
        mexErrMsgTxt("Invalid input: landmarktarget");    
    
    if (mxGetClassID(mxSizeTarget) != mxDOUBLE_CLASS
            && mxGetNumberOfElements(mxSizeTarget) != 2)
        mexErrMsgTxt("Invalid input: sizetarget");
   
    Warp wp;
    
    // parse and convert input image
    const mwSize * imgsize = mxGetDimensions(mxIm);
    double * landmark_x = (double *)mxGetPr(mxLandmark);
    double * landmark_y = (double *)mxGetPi(mxLandmark);
    double * landmarktraget_x = (double *)mxGetPr(mxLandmarkTarget);
    double * landmarktraget_y = (double *)mxGetPi(mxLandmarkTarget);
    double * dtargetsize = (double *)mxGetPr(mxSizeTarget);
    int targetsize[3] = {int(dtargetsize[0]), int(dtargetsize[1]), 3};
    
    BYTE * imageData = (BYTE*)mxGetPr(mxIm);
    
    wp.src.imageData = 
            (BYTE *)mxCalloc(imgsize[0]*imgsize[1]*imgsize[2], sizeof(BYTE));
    wp.src.height = imgsize[0];
    wp.src.width = imgsize[1];
    wp.src.widthStep = imgsize[1]*imgsize[2];
    
    BYTE * cur = wp.src.imageData;
    
    for(int i=0; i<imgsize[0]; i++)
        for(int j=0; j<imgsize[1]; j++)
            for(int k=0; k<imgsize[2]; k++)
                *(cur++) = imageData[i+j*imgsize[0]+k*imgsize[0]*imgsize[1]];
    
    wp.src.landmark1.x = (float)landmark_x[0] - 1;
    wp.src.landmark1.y = (float)landmark_y[0] - 1;
    wp.src.landmark2.x = (float)landmark_x[1] - 1;
    wp.src.landmark2.y = (float)landmark_y[1] - 1;
    
    wp.dst.imageData = 
            (BYTE *)mxCalloc(targetsize[0]*targetsize[1]*targetsize[2], sizeof(BYTE));
    wp.dst.height = targetsize[0];
    wp.dst.width = targetsize[1];
    wp.dst.widthStep = targetsize[1]*targetsize[2];
    
    wp.dst.landmark1.x = (float)landmarktraget_x[0] - 1;
    wp.dst.landmark1.y = (float)landmarktraget_y[0] - 1;
    wp.dst.landmark2.x = (float)landmarktraget_x[1] - 1;
    wp.dst.landmark2.y = (float)landmarktraget_y[1] - 1;

    // check points to warp
    wp.point_num = 0;
    if (!mxIsEmpty(mxPts) && nlhs == 2)
    {
        wp.point_num = mxGetNumberOfElements(mxPts);
        wp.pts_src = new FloatPoint[wp.point_num];
        wp.pts_dst = new FloatPoint[wp.point_num];
        
        double * src_x = (double *)mxGetPr(mxPts);
        double * src_y = (double *)mxGetPi(mxPts);
        
        for(int n=0; n<wp.point_num; n++)
        {
            wp.pts_src[n].x = src_x[n]-1;
            wp.pts_src[n].y = src_y[n]-1;
        }
    }    
    
    //mexPrintf("crop.pose = %d, face = %dx%d\n", crop.pose, FACE_WIDTH_CROP, FACE_HEIGHT_CROP);
    int suc = WarpImage(&wp);        
    if(suc < 0)
    {
        targetsize[0] = 0;
        targetsize[1] = 0;
        targetsize[2] = 3;
        plhs[0] = mxCreateNumericArray(3, targetsize, mxUINT8_CLASS, mxREAL);
        mxFree(wp.dst.imageData);
        mxFree(wp.src.imageData);
        return;
    }
            
    // convert back    
    plhs[0] = mxCreateNumericArray(3, targetsize, mxUINT8_CLASS, mxREAL);
    imageData = (BYTE*)mxGetPr(plhs[0]);
    cur = wp.dst.imageData;
    
    for(int i=0; i<targetsize[0]; i++)
        for(int j=0; j<targetsize[1]; j++)
            for(int k=0; k<targetsize[2]; k++)
                imageData[i+j*targetsize[0]+k*targetsize[0]*targetsize[1]] 
                        = *(cur++);
    
    mxFree(wp.dst.imageData);
    mxFree(wp.src.imageData);
    if (!mxIsEmpty(mxPts) && nlhs == 2)
    {
        plhs[1] = mxCreateNumericMatrix(1, wp.point_num, mxDOUBLE_CLASS, mxCOMPLEX);
        double * dst_x = (double *)mxGetPr(plhs[1]);
        double * dst_y = (double *)mxGetPi(plhs[1]);
        
        for(int n=0; n<wp.point_num; n++)
        {
            dst_x[n] = wp.pts_dst[n].x+1;
            dst_y[n] = wp.pts_dst[n].y+1;
        }
        delete [] wp.pts_src;
        delete [] wp.pts_dst;
    }
}
