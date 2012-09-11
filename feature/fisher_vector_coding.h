
#ifndef FISHER_VECTOR_CODING_H
#define FISHER_VECTOR_CODING_H
#include "coding.h"

struct FisherVectorCodeBook;

void InitCodingFisherVector(CodingOpt * opt);
inline void FuncCodingFisherVector (float * data, float * coding, int * coding_bin, const CodingOpt * opt);


void MatReadFisherVectorCodebook(const mxArray * mat_opt, FisherVectorCodeBook * opt);
#endif