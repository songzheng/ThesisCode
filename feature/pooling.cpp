#include "pooling.h"

#ifdef OPEN_MP
    #include <omp.h>
#endif
        
void PoolingSpatial(FloatSparseMatrix * feat, const Grids * feat_grids,
        FloatMatrix * feat_pool, const int * coord_pool,
        int size_y, int size_x)
{   
    int npool = feat_pool->width;
    
    // pooling size
    int pool_size_x = vl_ceil_f((float)size_x / feat_grids->step_x);
    int pool_size_y = vl_ceil_f((float)size_y / feat_grids->step_y);        
    
    // pooling weight
    float *w = new float[pool_size_x*pool_size_y];
    for(int ix=0; ix<pool_size_x; ix++)
    {
        for(int iy=0; iy<pool_size_y; iy++)
        {
            float vx = 1 - abs(ix - (1.0f*pool_size_x/2-0.5f)) / (1.0f*pool_size_x/2),
                    vy = 1 - abs(iy - (1.0f*pool_size_y/2-0.5f)) / (1.0f*pool_size_y/2);
            w[iy + ix*pool_size_y] = vx * vy;
            
        }
    }    
        
    
    #if defined(OPEN_MP) && defined(THREAD_MAX)
        omp_set_num_threads(THREAD_MAX);
    #endif        
            
    int n;
    
#ifdef OPEN_MP
    #pragma omp parallel default(none) private(n) firstprivate(pool_size_x, pool_size_y, size_x, size_y, feat_grids) shared(npool, feat, feat_pool, coord_pool, w)
#endif        
    {    
#ifdef OPEN_MP
        #pragma omp for schedule(static) nowait
#endif               
        for(int n=0; n<npool; n++)
        {
            float * dst = feat_pool->p + n*feat_pool->height;
            float y = coord_pool[2*n] - 1.0f * size_y/2;
            float x = coord_pool[2*n+1] - 1.0f * size_x/2;

            int pool_start_y = vl_round_f((y-feat_grids->start_y) / feat_grids->step_y);
            int pool_start_x = vl_round_f((x-feat_grids->start_x) / feat_grids->step_x);

    //         mexPrintf("%d, %d\n", pool_start_y, pool_start_x);

            for(int ix=0; ix<pool_size_x; ix++)
            {
                for(int iy=0; iy<pool_size_y; iy++)
                {
                    int fidx = MAX(MIN(pool_start_y+iy, feat_grids->num_y-1), 0) + 
                            MAX(MIN(pool_start_x+ix, feat_grids->num_x-1), 0) * feat_grids->num_y;

                    AddSparseMatrix(feat, fidx, w[iy + ix*pool_size_y], dst);
                }
            }
        }             
    }
    
    delete[] w;
}


void PoolingWeight()
{
}
// 
// #else
// 
// struct PoolingMTArgs
// {
//     FloatSparseMatrix * feat;
//     Grids * feat_grids;
//     FloatMatrix * feat_pool;
//     const int * coord_pool;
//     const float * w;    
//     int size_x;
//     int size_y;
//     int pool_size_x;
//     int pool_size_y;
//     
//     int start;
//     int end;
// };
// 
// // thread function
// #if defined(WIN32)
// DWORD WINAPI
// #elif defined(__UNIX__)  
// void *
// #endif 
// PoolingSpatialThread(
// #if defined(WIN32)
//         LPVOID 
// #elif defined(__UNIX__)   
//         void *
// #endif
//         args_in)
// {
//     PoolingMTArgs * args = (PoolingMTArgs *) args_in;
//     FloatSparseMatrix * feat = args->feat;
//     Grids * feat_grids = args->feat_grids;
//     FloatMatrix * feat_pool = args->feat_pool;
//     const int * coord_pool = args->coord_pool;
//     int size_x = args->size_x;
//     int size_y = args->size_y; 
//     int pool_size_x = args->pool_size_x;
//     int pool_size_y = args->pool_size_y;
//     const float * w = args->w;
//     
//     int start = args->start;
//     int end = args->end;
//     
//         
//     for(int n=start; n<=end; n++)
//     {
//         float * dst = feat_pool->p + n*feat_pool->height;
//         float y = coord_pool[2*n] - 1.0f * size_y/2;
//         float x = coord_pool[2*n+1] - 1.0f * size_x/2;
//         
//         int pool_start_y = vl_round_f((y-feat_grids->start_y) / feat_grids->step_y);
//         int pool_start_x = vl_round_f((x-feat_grids->start_x) / feat_grids->step_x);
//         
// //         mexPrintf("%d, %d\n", pool_start_y, pool_start_x);
//         
//         for(int ix=0; ix<pool_size_x; ix++)
//         {
//             for(int iy=0; iy<pool_size_y; iy++)
//             {
//                 int fidx = MAX(MIN(pool_start_y+iy, feat_grids->num_y-1), 0) + 
//                         MAX(MIN(pool_start_x+ix, feat_grids->num_x-1), 0) * feat_grids->num_y;
//                 
//                 AddSparseMatrix(feat, fidx, w[iy + ix*pool_size_y], dst);
//             }
//         }
//     }             
//     
//     return 0;
//     
// }
// 
// // thread caller
// void PoolingSpatial(FloatSparseMatrix * feat, Grids * feat_grids,
//         FloatMatrix * feat_pool, const int * coord_pool,
//         int size_y, int size_x)
// {
//     
//     // pooling size
//     int pool_size_x = vl_ceil_f((float)size_x / feat_grids->step_x);
//     int pool_size_y = vl_ceil_f((float)size_y / feat_grids->step_y);        
//     
//     // pooling weight
//     float *w = new float[pool_size_x*pool_size_y];
//     for(int ix=0; ix<pool_size_x; ix++)
//     {
//         for(int iy=0; iy<pool_size_y; iy++)
//         {
//             float vx = 1 - abs(ix - (1.0f*pool_size_x/2-0.5f)) / (1.0f*pool_size_x/2),
//                     vy = 1 - abs(iy - (1.0f*pool_size_y/2-0.5f)) / (1.0f*pool_size_y/2);
//             w[iy + ix*pool_size_y] = vx * vy;
//             
//         }
//     }    
// 
// #if defined(WIN32) 
//     HANDLE  hThreadArray[THREAD_MAX];
// #elif defined(__UNIX__)   
//     pthread_t hThreadArray[THREAD_MAX];
// #endif
//     PoolingMTArgs thread_arg[THREAD_MAX];
//     int ntask = feat_pool->width;
//     int task_per_thread = (int)ceil(1.0*ntask/THREAD_MAX);
//     
// 	//mexPrintf("%d, %d, %d, %d, %d, %d\n", ntask, task_per_thread, THREAD_MAX, block_num, block_stride, opt->length_input);
// 	//return;
//     
//     for(int t=0; t<THREAD_MAX; t++)
//     {
//         int task_start = t*task_per_thread;
//         int task_num = MIN(task_per_thread, ntask-task_start);
//         
//         // assign input
//         thread_arg[t].feat = feat;     
//         thread_arg[t].feat_grids = feat_grids;     
//         thread_arg[t].feat_pool = feat_pool;     
//         thread_arg[t].coord_pool = coord_pool;     
//         thread_arg[t].size_x = size_x;     
//         thread_arg[t].size_y = size_y;         
//         thread_arg[t].pool_size_x = pool_size_x;     
//         thread_arg[t].pool_size_y = pool_size_y;     
//         thread_arg[t].w = w;     
//         thread_arg[t].start = task_start;
//         thread_arg[t].end = task_start + task_num - 1;        
//         
//         // launch thread
// #if defined(WIN32) 
//         hThreadArray[t] = CreateThread(NULL, 0, PoolingSpatialThread, &thread_arg[t], 0, NULL);
// #elif defined(__UNIX__)   
//         pthread_create(&hThreadArray[t], NULL, PoolingSpatialThread, (void *)&thread_arg[t])
// #endif
//         
//     }    
//     
// #if defined(WIN32) 
//     WaitForMultipleObjects(THREAD_MAX, hThreadArray, TRUE, INFINITE);
// #elif defined(__UNIX__) 
//     void * status;
//     for(int t=0; t<THREAD_MAX; t++) 
//         pthread_join(hThreadArray[t], &status);
// #endif
// 
//     delete[] w;
// }
// 
// #endif


//     // group and encode in pyramids
//     if(opt->codebook == NULL)
//     {
//         MoveImage(&patch_feat, desp);
//     }
//     else
//     {
//         if(pyra_opt != NULL)
//         {
//             // encode in rectangle pyramid areas
//             int nsplit = pyra_opt->npyramid;
//             AllocateImage(desp, opt->codebook->length, nsplit, 1);
//             for(int i=0; i<nsplit; i++)
//                 EncodeRect(&patch_feat, pyra_opt->pyramid+i, patch_coordinate, desp->p+i*desp->height, 1, opt->codebook);
//         }
//         else
//         {
//             // encode each patch
//             AllocateImage(desp, opt->coded_length, patch_feat.width, 1);        
//             for(int i=0; i<patch_feat.width; i++)
//                 opt->codebook->f(patch_feat.p+i*patch_feat.height, desp->p+i*desp->height, 1, opt->codebook);
//         }
//     
//         FreeImage(&patch_feat);
//     }

// #endif