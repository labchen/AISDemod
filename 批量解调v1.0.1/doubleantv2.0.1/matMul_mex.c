#include "mex.h"
#include <stdio.h>

void complexMatMul
(
 double *mat1_I, double *mat1_Q,
 double *mat2_I, double *mat2_Q,
 double *resultMat_I, double *resultMat_Q,
 int sigLen
);
void mexFunction
(	int nlhs,		mxArray *plhs[],
	int nrhs, const mxArray *prhs[])
{
	double *mat1_I;
	double *mat1_Q;
	double *mat2_I;
	double *mat2_Q;
	double *result_I;
	double *result_Q;
	int sigLen = 0;
	int i = 0;
	if(nrhs > 2 || nrhs < 0) {
		mexErrMsgTxt("Number of parametes wrong!\n");
		return;
	}
	sigLen = mxGetN(prhs[0]);
	// mat1
	mat1_I = mxGetPr(prhs[0]);
	if(!mxIsComplex(prhs[0]))
	{
		if(!(mat1_Q = (double*)mxMalloc(sigLen*sizeof(double))))
		{
			mexErrMsgTxt("Alloc failed!");
		}
		for(i=0; i<sigLen; i++)
		{
			mat1_Q[i] = 0;
		}
	}
	else
	{
		mat1_Q = mxGetPi(prhs[0]);
	}
	// mat2
	mat2_I = mxGetPr(prhs[1]);
	if(!mxIsComplex(prhs[1]))
	{
		if(!(mat2_Q = (double*)mxMalloc(sigLen*sizeof(double))))
		{
			mexErrMsgTxt("Alloc failed!");
		}
		for(i=0; i<sigLen; i++)
		{
			mat2_Q[i] = 0;
		}
	}
	else
	{
		mat2_Q = mxGetPi(prhs[1]);
	}
	// malloc to struct
	plhs[0] = mxCreateDoubleMatrix(1, sigLen, mxCOMPLEX);
	result_I = mxGetPr(plhs[0]);
	result_Q = mxGetPi(plhs[0]);
	complexMatMul(mat1_I, mat1_Q, mat2_I, mat2_Q, result_I, result_Q, sigLen);
}

void complexMatMul
(
 double *mat1_I, double *mat1_Q,
 double *mat2_I, double *mat2_Q,
 double *resultMat_I, double *resultMat_Q,
 int sigLen
)
{// complex matrix mul
	int i = 0;

	for(i = 0; i < sigLen; i++)
	{
		resultMat_I[i] = mat1_I[i]*mat2_I[i] - mat1_Q[i]*mat2_Q[i];
		resultMat_Q[i] = mat1_I[i]*mat2_Q[i] + mat1_Q[i]*mat2_I[i];
	}
}