#ifndef IMAGE_H
#define IMAGE_H

#include <string.h>
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
// #ifdef THREAD_MAX
// #ifdef WIN32
//     #include <windows.h>
// #elif defined(__UNIX__)
//     #include <pthread.h>
// #endif
// #endif
            
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
// rectangle structure
struct FloatRect
{
    float x1;// left
    float y1;// top
    float x2;// right
    float y2;// bottom
};

struct Grids
{
    int start_x;
    int step_x;
    int num_x;
    int start_y;
    int step_y;
    int num_y;
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



void AllocateImage(FloatImage * img, int height, int width, int depth);
void MoveImage(FloatImage * src, FloatImage * dst);
void FreeImage(FloatImage * img);

void AllocateSparseMatrix(FloatSparseMatrix * mat, int height, int width, int block_num, int block_size);
void FreeSparseMatrix(FloatSparseMatrix * mat);
// void AddSparseMatrix(FloatSparseMatrix * sparse, int idx, float coef, float * dst);

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

Grids CalculateGrids(FloatImage * img, int size_y, int size_x, int step_y, int step_x);
int * NewCoordianteFromGrids(Grids * grids);

#ifdef MATLAB_COMPILE

#define FUNC_PROC2(name) Func ## name
#define FUNC_PROC(name) FUNC_PROC2(name)
#define FUNC_INIT2(name) Init ## name
#define FUNC_INIT(name) FUNC_INIT2(name)

#define COPY_SCALAR_FIELD(var, field_name, type) var->field_name = (mxGetField(mat_##var, 0, #field_name)==NULL)?0:(type)mxGetScalar(mxGetField(mat_##var, 0, #field_name))
#define COPY_MATRIX_FIELD(var, field_name, type) var->field_name = (mxGetField(mat_##var, 0, #field_name)==NULL)?NULL:(type *)mxGetPr(mxGetField(mat_##var, 0, #field_name))
#define PASTE_SCALAR_FIELD(var, field_name) mxSetField(mat_##var, 0, #field_name, mxCreateDoubleScalar((double)var->field_name));


mxArray * MatCopyFloatMatrix(FloatImage * image);
bool MatReadFloatMatrix(const mxArray * mat_matrix, FloatMatrix * matrix);
mxArray * MatAllocateFloatMatrix(FloatMatrix * matrix, int height, int width, int depth);

void MatReadFloatSparseMatrix(const mxArray * mat_matrix, FloatSparseMatrix * matrix);
mxArray * MatAllocateFloatSparseMatrix(FloatSparseMatrix * matrix, int height, int width, int block_num, int block_size);

mxArray * MatAllocateGrids(Grids * g);
#endif

#endif