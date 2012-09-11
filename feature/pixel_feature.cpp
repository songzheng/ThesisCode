#include "pixel_feature.h"
#include <vl/mathop.h>
#include <vl/imopv.h>


// *********************************//
// entry

void InitPixelFeature(FloatMatrix * img, PixelFeatureOpt * opt)
{
    opt->func_init(opt);

    ASSERT(img->depth == opt->image_depth);    
    
    Grids * grids = &opt->grids;
    
    grids->start_x = opt->margin;
    grids->step_x = 1;
    grids->num_x = img->width-opt->margin*2;
    
    grids->start_y = opt->margin;
    grids->step_y = 1;
    grids->num_y = img->height-opt->margin*2;
    
    opt->num = grids->num_x * grids->num_y;
    
//     mexPrintf("%d, %d, %d, %d, %d\n", img->depth, opt->image_depth, opt->height, opt->width, opt->margin);
}

// #define OPEN_MP
#ifdef OPEN_MP
    #include <omp.h>
#endif

void PixelFeature(FloatMatrix * img, FloatMatrix * feat, PixelFeatureOpt * opt)
{        
    Grids * grids = &opt->grids;
    float * dst = feat->p;
    int x;
        
    #if defined(OPEN_MP) && defined(THREAD_MAX)
        omp_set_num_threads(THREAD_MAX);
    #endif        
            
#ifdef OPEN_MP
    #pragma omp parallel default(none) private(x) shared(grids, img, dst, opt)
#endif
    {
#ifdef OPEN_MP
        #pragma omp for
#endif
        for (x = grids->start_x ; x < grids->start_x+grids->num_x ; ++ x) {        
            for (int y = grids->start_y ; y < grids->start_y+grids->num_y ; ++ y) {            
                opt->func_proc(img, x, y, dst+((x-grids->start_x)*grids->num_y+y-grids->start_y)*opt->length, opt);       
            }
        }   
    }
}
// #undef OPEN_MP

// feature select function
int PixelFeatureSelect(PixelFeatureOpt * opt)
{   
	opt->func_init = NULL;
	opt->func_proc = NULL;
    if(!strcmp(opt->name, "PixelGray8N"))
    {        
        opt->func_init = InitPixelGray8N;
        opt->func_proc = FuncPixelGray8N;
        return 1;
    }
    
    
    if(!strcmp(opt->name, "PixelGray4N"))
    {        
        opt->func_init = InitPixelGray4N;
        opt->func_proc = FuncPixelGray4N;
        return 1;
    }
    
    
    if(!strcmp(opt->name, "PixelColor"))
    {        
        opt->func_init = InitPixelColor;
        opt->func_proc = FuncPixelColor;
        return 1;
    }
    
    return 0;
}

#ifdef MATLAB_COMPILE

void MatReadPixelFeatureOpt(const mxArray * mat_opt, PixelFeatureOpt * opt)
{
    // get feature name
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
    
// #ifdef PIXEL_FEATURE_NAME
//     opt->func_init = FUNC_INIT(PIXEL_FEATURE_NAME);
//     opt->func_proc = FUNC_PROC(PIXEL_FEATURE_NAME);
// #else
    if(!PixelFeatureSelect(opt))
    {
        mexPrintf("%s\n", opt->name);
        mexErrMsgTxt("Pixel feature is not implemented");
    }
// #endif
}
#endif