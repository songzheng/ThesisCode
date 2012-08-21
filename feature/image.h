#ifndef IMAGE_H
#define IMAGE_H

#include <vl/mathop.h>
#include <vl/imopv.h>

#ifdef MATLAB_COMPILE
    #include <mex.h>
    #include <matrix.h>
    #define ASSERT(expr) if(!expr) _mex_err_report("Assertion Failed", __FILE__, __LINE__)
    #define ALLOCATE(type, size) (type *)mxCalloc((size), sizeof(type))
    #define FREE(ptr) mxFree((ptr))
    
    inline void _mex_err_report(char * msg, char * file, int line)
    {
        mexPrintf("==================================================\n");
        mexPrintf("Error %s In %s(%d)\n", msg, file, line);
        mexPrintf("==================================================\n");
        mexErrMsgTxt("Execution is forced to quit");
    }
#else
    #include <assert.h>
    #define ASSERT(expr) assert((expr))
    #define ALLOCATE(type, size) new type[(size)]()
    #define FREE(ptr) delete[] ptr
#endif

// multi-thread
#ifdef THREAD_MAX
#ifdef WIN32
    #include <windows.h>
#elif defined(__UNIX__)
    #include <pthread.h>
#endif
#endif
            
static inline double MIN(double x, double y) { return (x <= y ? x : y); }
static inline double MAX(double x, double y) { return (x <= y ? y : x); }

static inline float MIN(float x, float y) { return (x <= y ? x : y); }
static inline float MAX(float x, float y) { return (x <= y ? y : x); }

static inline int MIN(int x, int y) { return (x <= y ? x : y); }
static inline int MAX(int x, int y) { return (x <= y ? y : x); }
                        

struct FloatImage
{
    float * p;
    int width;
    int height;
    int depth;
    int stride;
};

typedef struct FloatImage FloatMatrix;

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

// rectangle structure
struct FloatRect
{
    float x1;// left
    float y1;// top
    float x2;// right
    float y2;// bottom
};

// for column blockwise sparse matrix
struct FloatSparseMatrix
{
    float * p;
    int * i;
    int block_num;
    int width;
    int height;
    int block_size;
};
        
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

//  helper function
inline void AddSparseMatrix(FloatSparseMatrix * sparse, int idx, float coef, float * dst)
{
    float * val = sparse->p + idx*sparse->block_num*sparse->block_size;
    int * bin = sparse->i + idx*sparse->block_num;
    for(int i=0; i<sparse->block_num; i++)
    {        
        int b = *(bin++);
        if(b >= 0)
        {
            float * dense = dst + b*sparse->block_size;
            for(int j=0; j<sparse->block_size; j++)
                *(dense++) += coef*(*(val++));
        }
        else
        {
            val += sparse->block_size;
        }
    }
}

struct Grids
{
    int start_x;
    int step_x;
    int num_x;
    int start_y;
    int step_y;
    int num_y;
};

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

Grids CalculateGrids(FloatImage * img, int size_y, int size_x, int step_y, int step_x)
{    
    // default dense rectangle pooling     
    Grids g;
    
    g.start_x = size_x/2;
    g.start_y = size_y/2;
    g.step_x = step_x;
    g.step_y = step_y;
    g.num_x = int(1.0 * (img->width-1-g.start_x) / g.step_x) + 1;
    g.num_y = int(1.0 * (img->height-1-g.start_y) / g.step_y) + 1;
    
    return g;
}


// matlab interfaces
#ifdef MATLAB_COMPILE

#define FUNC_PROC2(name) Func ## name
#define FUNC_PROC(name) FUNC_PROC2(name)
#define FUNC_INIT2(name) Init ## name
#define FUNC_INIT(name) FUNC_INIT2(name)

#define COPY_SCALAR_FIELD(var, field_name, type) var->field_name = (mxGetField(mat_##var, 0, #field_name)==NULL)?0:(type)mxGetScalar(mxGetField(mat_##var, 0, #field_name))
#define COPY_MATRIX_FIELD(var, field_name, type) var->field_name = (mxGetField(mat_##var, 0, #field_name)==NULL)?NULL:(type *)mxGetPr(mxGetField(mat_##var, 0, #field_name))

#define PASTE_SCALAR_FIELD(var, field_name) mxSetField(mat_##var, 0, #field_name, mxCreateDoubleScalar((double)var->field_name));

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


// allocate mat array

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
    
    mxArray * mat_matrix = mxCreateStructMatrix(1, 1, 2, field);
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


#endif