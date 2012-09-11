#ifndef POOLING_H
#define POOLING_H
#include "image.h"
// ***************************** //
// for image pooling

void PoolingSpatial(FloatSparseMatrix * feat, const Grids * feat_grids,
        FloatMatrix * feat_pool, const int * coord_pool,
        int size_y, int size_x);

void PoolingWeight();
#endif