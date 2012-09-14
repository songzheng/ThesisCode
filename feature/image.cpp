#include "image.h"

// ***********************************************************************/
// image / matrix

// matlab style height x width x depth
void AllocateImage(FloatImage * img, int height, int width, int depth)
{
    img->p = ALLOCATE(float, width * height * depth);
    
    img->width = width;
    img->height = height;
    img->depth = depth;   
    img->stride = height;   
}

// move image to another struct
void MoveImage(FloatImage * src, FloatImage * dst)
{
    dst->p = src->p;
    dst->width = src->width;
    dst->height = src->height;
    dst->depth = src->depth;   
    dst->stride = src->height;   
    src->p = NULL;
}

// free image
void FreeImage(FloatImage * img)
{
    if(img->p != NULL)
        FREE(img->p);
}

// // image norm
// void NormalizeColumn(FloatImage * img)
// {
//     for(int x=0; x<img->width; x++)
//     {
//         float * dst = img->p + x*img->height;
//         
//         float norm = 0.0f;
//         for(int y=0; y<img->height; y++)
//             norm += dst[y]*dst[y];
//         
//         norm = vl_fast_sqrt_f(norm);
//         
//         for(int y=0; y<img->height; y++)
//             dst[y] /= norm;
//     }
// }

        
// ***********************************************************************/
// sparse matrix

void AllocateSparseMatrix(FloatSparseMatrix * mat, int height, int width, int block_num, int block_size)
{    
    mat->p = ALLOCATE(float, width*block_num*block_size);
    mat->i = ALLOCATE(int, width*block_num);
        
    for(int i=0; i<width*block_num; i++)
        mat->i[i] = -1;
    
    mat->block_num = block_num;
    mat->height = height;
    mat->width = width;
    mat->block_size = block_size;
}


void FreeSparseMatrix(FloatSparseMatrix * mat)
{
    FREE(mat->p);
    FREE(mat->i);         
}


// ***********************************************************************/
// grids

int * NewCoordianteFromGrids(Grids * grids)
{
    int *ret = ALLOCATE(int, grids->num_x*grids->num_y*2);
    int *coord = ret;
    int end_x = grids->start_x + (grids->num_x-1)*grids->step_x;
    int end_y = grids->start_y + (grids->num_y-1)*grids->step_y;
    
    for(int x=grids->start_x; x<=end_x; x+=grids->step_x)
    {
        for(int y=grids->start_y; y<=end_y; y+=grids->step_y)
        {    
            *(coord++) = y;
            *(coord++) = x;
        }
    }
    return ret;    
}

// ***********************************************************************/
// matlab interfaces
#ifdef MATLAB_COMPILE

// ***************************//
// array operations
mxArray * MatCopyFloatMatrix(FloatImage * image)
{
    mwSize dims[3] = {image->height, image->width, image->depth};   
    
    mxArray * mx_image = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    double * dst = mxGetPr(mx_image);
    
    for(int i=0; i<mxGetNumberOfElements(mx_image); i++)
        dst[i] = (double)image->p[i];
    
    return mx_image;
}

// read pointers in mat array
bool MatReadFloatMatrix(const mxArray * mat_matrix, FloatMatrix * matrix)
{    
    int ndims = mxGetNumberOfDimensions(mat_matrix);
    const mwSize * dims = mxGetDimensions(mat_matrix);
    
    matrix->height = dims[0];
    
    if(ndims == 1)
    {
        matrix->width = 1;
        matrix->depth = 1;
    }
    else
    {    
        matrix->width = dims[1];
        if(ndims == 2)
        {
            matrix->depth = 1;
        }
        else
        {     
            matrix->depth = dims[2];
        }
    }
    
    bool iscopy = false;
    if(mxGetClassID(mat_matrix) == mxDOUBLE_CLASS)
    {
        double * src = (double *)mxGetPr(mat_matrix);
        
        AllocateImage(matrix, matrix->height, matrix->width, matrix->depth);
        iscopy = true;
        for(int i=0; i<mxGetNumberOfElements(mat_matrix); i++)
            matrix->p[i] = (float)src[i];        
    }
    else if(mxGetClassID(mat_matrix) == mxUINT8_CLASS)
    {        
        unsigned char * src = (unsigned char * )mxGetPr(mat_matrix);

        AllocateImage(matrix, matrix->height, matrix->width, matrix->depth);
        iscopy = true;
        for(int i=0; i<mxGetNumberOfElements(mat_matrix); i++)
            matrix->p[i] = (float)src[i];        
    }
    else if(mxGetClassID(mat_matrix) == mxSINGLE_CLASS)
    {        
        matrix->p = (float *)mxGetPr(mat_matrix);                
        iscopy = false;
    }
    else
    {
        mexErrMsgTxt("Unsupported matrix convertion");
    }
    
    return iscopy;
}

// allocate and read pointers in matlab array
mxArray * MatAllocateFloatMatrix(FloatMatrix * matrix, int height, int width, int depth)
{
    mwSize dims[3]= {height, width, depth};
    mxArray * mat_matrix = mxCreateNumericArray(3, dims, mxSINGLE_CLASS, mxREAL);
    MatReadFloatMatrix(mat_matrix, matrix);    
    return mat_matrix;
}

// sparse float arrays

void MatReadFloatSparseMatrix(const mxArray * mat_matrix, FloatSparseMatrix * matrix)
{    
    COPY_MATRIX_FIELD(matrix, p, float);
    COPY_MATRIX_FIELD(matrix, i, int);    
    COPY_SCALAR_FIELD(matrix, height, int);
    COPY_SCALAR_FIELD(matrix, width, int);
    COPY_SCALAR_FIELD(matrix, block_num, int);
    COPY_SCALAR_FIELD(matrix, block_size, int);    
}


mxArray * MatAllocateFloatSparseMatrix(FloatSparseMatrix * matrix, int height, int width, int block_num, int block_size)
{
    const char * field[] = {"p", "i", "height", "width", "block_num", "block_size"};
    
    mxArray * mat_matrix = mxCreateStructMatrix(1, 1, 6, field);
    mxSetField(mat_matrix, 0, "p", mxCreateNumericMatrix(block_num*block_size, width, mxSINGLE_CLASS, mxREAL));
    mxSetField(mat_matrix, 0, "i", mxCreateNumericMatrix(block_num, width, mxINT32_CLASS, mxREAL));
    mxSetField(mat_matrix, 0, "height", mxCreateDoubleScalar(height));
    mxSetField(mat_matrix, 0, "width", mxCreateDoubleScalar(width));
    mxSetField(mat_matrix, 0, "block_num", mxCreateDoubleScalar(block_num));
    mxSetField(mat_matrix, 0, "block_size", mxCreateDoubleScalar(block_size));
    
    MatReadFloatSparseMatrix(mat_matrix, matrix);
    
    return mat_matrix;
}

mxArray * MatAllocateGrids(Grids * g)
{
    const char * field[] = {"start_x", "step_x", "num_x", "start_y", "step_y", "num_y"};
    mxArray * mat_g = mxCreateStructMatrix(1, 1, 6, field);
    
    PASTE_SCALAR_FIELD(g, start_x);
    PASTE_SCALAR_FIELD(g, step_x);
    PASTE_SCALAR_FIELD(g, num_x);
    PASTE_SCALAR_FIELD(g, start_y);
    PASTE_SCALAR_FIELD(g, step_y);
    PASTE_SCALAR_FIELD(g, num_y);    
    
    return mat_g;
}

#endif