#include "pixel_feature.h"
#include <vl/mathop.h>
#include <vl/imopv.h>


Grids CalculatePixelGrids(FloatImage * img, int margin)
{    
    // default dense rectangle pooling     
    Grids g;
    
    g.start_x = margin;
    g.step_x = 1;
    g.num_x = img->width - margin*2;
    
    g.start_y = margin;
    g.step_y = 1;
    g.num_y = img->height - margin*2;
    
    return g;
}
// *********************************//
// entry

void InitPixelFeature(FloatMatrix * img, PixelFeatureOpt * opt)
{
#ifdef PIXEL_FEATURE_NAME
    FUNC_INIT(opt);
#else
    opt->func_init(opt);
#endif
    
    ASSERT(img->depth == opt->image_depth);    
    
    if (opt->use_grids)
    {
        opt->grids = CalculatePixelGrids(img, opt->margin);
        opt->coord = NULL;
        opt->num = opt->grids.num_x * opt->grids.num_y;
    }
    else        
    {
        ASSERT(opt->coord != NULL && opt->num != 0);
    }   
    
//     mexPrintf("%d, %d, %d, %d, %d\n", img->depth, opt->image_depth, opt->height, opt->width, opt->margin);
}

// #define OPEN_MP
#ifdef OPEN_MP
    #include <omp.h>
#endif

void PixelFeature(FloatMatrix * img, FloatMatrix * feat, PixelFeatureOpt * opt)
{        
    float * dst = feat->p;
    int * coord = NULL;
    
    if(opt->use_grids)
        coord = NewCoordianteFromGrids(&opt->grids);
    else
        coord = opt->coord;
    
    int n;
        
#if defined(OPEN_MP) && defined(THREAD_MAX)
    omp_set_num_threads(THREAD_MAX);
#endif        
            
#ifdef OPEN_MP
    #pragma omp parallel default(none) private(n) shared(coord, img, dst, opt)
#endif
    {
#ifdef OPEN_MP
        #pragma omp for schedule(static) nowait
#endif
         for(n =0; n<opt->num; n++)
         {
            int y = coord[2*n], x = coord[2*n+1];
#ifdef PIXEL_FEATURE_NAME
            FUNC_PROC(PIXEL_FEATURE_NAME)(img, x, y, dst+n*opt->length, opt);
#else
            opt->func_proc(img, x, y, dst+n*opt->length, opt);       
#endif
        }
    }

    if(opt->use_grids)
        FREE(coord);
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
    
    if(!strcmp(opt->name, "PixelGray4x4"))
    {
        opt->func_init = InitPixelGray4x4;
        opt->func_proc = FuncPixelGray4x4;
        return 1;
    }
    
    if(!strcmp(opt->name, "PixelGray4x4Rot"))
    {
        opt->func_init = InitPixelGray4x4Rot;
        opt->func_proc = FuncPixelGray4x4Rot;
        return 1;
    }
    
    if(!strcmp(opt->name, "PixelGray4x4DCT"))
    {
        opt->func_init = InitPixelGray4x4DCT;
        opt->func_proc = FuncPixelGray4x4DCT;
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
    
#ifdef PIXEL_FEATURE_NAME
    opt->func_init = NULL;
    opt->func_proc = NULL;
#else
    if(!PixelFeatureSelect(opt))
    {
        mexPrintf("%s\n", opt->name);
        mexErrMsgTxt("Pixel feature is not implemented");
    }
#endif
}
#endif