#include "mex.h"
#include "math.h"

#define PI 3.14159265358979323846
#define INF 1e10

void matMul(double *mat1, double *mat2, int m, int l, int n, double *resultMat);
void complexMatMul
(
 double *mat1_I, double *mat1_Q,
 double *mat2_I, double *mat2_Q,
 int m, int l, int n,
 double *resultMat_I, double *resultMat_Q,
 bool conjFlag
 );
int FindMaxLoc(double *mat, int len);

void mexFunction
(	int nlhs,		mxArray *plhs[],
	int nrhs, const mxArray *prhs[])
{
/**
	input var0:	decision signal(complex)
	input var1:	length of signal(bit)
	input var2:	sample rate
	input var3:	Kf
	input var4:	L
	input var5:	qt
	input var6:	decision delay
	input var7:	state_all
	input var8:	state_in
	input var9:	state_number
	input var10:	DecayFactor

	output var:	digital signal after decision
*/

// ------------------------------------------------
	double *I_out, *Q_out;
	int blockLen = 0;
	int sampleNum = 0;
	double Kf = 0;
	int L = 0;
	double *qt;
	int decDelay = 0;
	double *state_all;
	double *state_in;
	int state_all_n = mxGetM(prhs[7]);
	int state_in_n = mxGetM(prhs[8]);
	double state_number = 0;
	double decayFactor = 0;

	double *decision;

// ----------------------------------
	double *metric_stateI, *metric_stateQ;
	double *survivor_state;
	int i = 0, j = 0, n = 0, k = 0;
	double *phase_refe;
	double *hc1, *hs1;
	double metricI = 0, metricQ = 0;
	double *pMetricI = &metricI;
	double *pMetricQ = &metricQ;
	double metric_abs = 0;
	double metric_state_abs = 0;
	int last_state = 0;
	int survivor = 0;
	double *metric_state_abs_col;
	size_t sigLen = 0;

// ----------------------------------------------------
	sigLen = mxGetN(prhs[0]);
	I_out = mxGetPr(prhs[0]);
	if(!mxIsComplex(prhs[0]))
	{
		if(!(Q_out = (double*)mxMalloc(sigLen*sizeof(double))))
		{
			mexErrMsgTxt("Alloc failed!");
		}
		for(i=0; i<sigLen; i++)
		{
			Q_out[i] = 0;
		}
	}
	else
	{
		Q_out = mxGetPi(prhs[0]);
	}
	blockLen = mxGetScalar(prhs[1]);
	sampleNum = mxGetScalar(prhs[2]);
	Kf = mxGetScalar(prhs[3]);
	L = mxGetScalar(prhs[4]);
	qt = mxGetPr(prhs[5]);
	decDelay = mxGetScalar(prhs[6]);
	state_all = mxGetPr(prhs[7]);
	state_in = mxGetPr(prhs[8]);
	state_number = mxGetScalar(prhs[9]);
	decayFactor = mxGetScalar(prhs[10]);
	if(nrhs == 10)
	{
		decayFactor = 0.5;
	}

	plhs[0] = mxCreateDoubleMatrix(1, blockLen, mxREAL);
	decision = mxGetPr(plhs[0]);

// malloc
	if(		!(metric_stateI = (double*)mxMalloc(state_number*decDelay*sizeof(double)))
		||	!(metric_stateQ = (double*)mxMalloc(state_number*decDelay*sizeof(double)))
		||	!(survivor_state = (double*)mxMalloc(state_number*decDelay*sizeof(double)))
		||	!(phase_refe = (double*)mxMalloc(sampleNum*sizeof(double)))
		||	!(hc1 = (double*)mxMalloc(sampleNum*sizeof(double)))
		||	!(hs1 = (double*)mxMalloc(sampleNum*sizeof(double)))
		||	!(metric_state_abs_col = (double*)mxMalloc(state_number*sizeof(double)))
		)
	{
		mexErrMsgTxt("Alloc failed!");
	}

// init---------------------------------------------------------
	for(i=0; i<state_number; i++)
	{
		for(j=0; j<decDelay; j++)
		{
			metric_stateI[i*decDelay+j] = 0;
			metric_stateQ[i*decDelay+j] = 0;
			survivor_state[i*decDelay+j] = -1;
		}
	}

// decode start------------------------------------------------------
	for(n=0; n<blockLen; n++)
	{
//		if(n == 254)
//		{
//			mexPrintf("here");
//		}
		if(n == 0)
		{
			for(i=0; i<state_number; i++)
			{
				for(k=0; k<sampleNum; k++)
				{
					phase_refe[k] = 2*PI*Kf*(state_all[i*state_all_n+1]*qt[sampleNum+k] + \
						state_all[i*state_all_n]*qt[k]) + \
						state_all[i*state_all_n+3];
					hc1[k] = cos(phase_refe[k]);
					hs1[k] = sin(phase_refe[k]);
				}
				complexMatMul
				(
					hc1, hs1,
					I_out+n*sampleNum, Q_out+n*sampleNum,
					1, sampleNum, 1,
					pMetricI, pMetricQ,
					true
				);
				*pMetricI = *pMetricI + 1e-10;
				metric_abs = sqrt(metricI*metricI + metricQ*metricQ);
				metric_state_abs = sqrt(metric_stateI[i*decDelay+n]*metric_stateI[i*decDelay+n] + \
					metric_stateQ[i*decDelay+n]*metric_stateQ[i*decDelay+n]);
				if(metric_abs > metric_state_abs)
				{
					metric_stateI[i*decDelay+n] = *pMetricI;
					metric_stateQ[i*decDelay+n] = *pMetricQ;
					survivor_state[i*decDelay+n] = state_in[i*state_in_n];
				}
			}
		}
		else if(n == 1)
		{
			for(i=0; i<state_number; i++)
			{
				for(j=0; j<2; j++)
				{
					last_state = state_in[i*state_in_n+j];
					last_state = last_state % (int)pow(2, L);
					if(last_state == 0)
					{
						last_state = (int)pow(2, L);
					}
					for(k=0; k<sampleNum; k++)
					{
						phase_refe[k] = 2*PI*Kf*(state_all[i*state_all_n+1]*qt[sampleNum+k] + \
							state_all[i*state_all_n]*qt[k] + \
							state_all[i*state_all_n+2]*qt[2*sampleNum+k]) + \
							state_all[i*state_all_n+3];
						hc1[k] = cos(phase_refe[k]);
						hs1[k] = sin(phase_refe[k]);
					}
					complexMatMul
					(
						hc1, hs1,
						I_out+n*sampleNum, Q_out+n*sampleNum,
						1, sampleNum, 1,
						pMetricI, pMetricQ,
						true
					);
					*pMetricI = *pMetricI + 1e-10;
					*pMetricI = *pMetricI + decayFactor*metric_stateI[(last_state-1)*decDelay+n-1];
					*pMetricQ = *pMetricQ + decayFactor*metric_stateQ[(last_state-1)*decDelay+n-1];
					metric_abs = sqrt(metricI*metricI + metricQ*metricQ);
					metric_state_abs = sqrt(metric_stateI[i*decDelay+n]*metric_stateI[i*decDelay+n] + \
						metric_stateQ[i*decDelay+n]*metric_stateQ[i*decDelay+n]);
					if(metric_abs > metric_state_abs)
					{
						metric_stateI[i*decDelay+n] = *pMetricI;
						metric_stateQ[i*decDelay+n] = *pMetricQ;
						survivor_state[i*decDelay+n] = i+1;
					}
				}
			}
		}
		else if(n<decDelay-1)
		{
			for(i=0; i<state_number; i++)
			{
				for(j=0; j<2; j++)
				{
					last_state = state_in[i*state_in_n+j];
					for(k=0; k<sampleNum; k++)
					{
						phase_refe[k] = 2*PI*Kf*(state_all[i*state_all_n+1]*qt[sampleNum+k] + \
							state_all[i*state_all_n]*qt[k] + \
							state_all[i*state_all_n+2]*qt[2*sampleNum+k]) + \
							state_all[i*state_all_n+3];
						hc1[k] = cos(phase_refe[k]);
						hs1[k] = sin(phase_refe[k]);
					}
					complexMatMul
					(
						hc1, hs1,
						I_out+n*sampleNum, Q_out+n*sampleNum,
						1, sampleNum, 1,
						pMetricI, pMetricQ,
						true
					);
					*pMetricI = *pMetricI + 1e-10;
					*pMetricI = *pMetricI + decayFactor*metric_stateI[(last_state-1)*decDelay+n-1];
					*pMetricQ = *pMetricQ + decayFactor*metric_stateQ[(last_state-1)*decDelay+n-1];
					metric_abs = sqrt(metricI*metricI + metricQ*metricQ);
					metric_state_abs = sqrt(metric_stateI[i*decDelay+n]*metric_stateI[i*decDelay+n] + \
						metric_stateQ[i*decDelay+n]*metric_stateQ[i*decDelay+n]);
					if(metric_abs > metric_state_abs)
					{
						metric_stateI[i*decDelay+n] = *pMetricI;
						metric_stateQ[i*decDelay+n] = *pMetricQ;
						survivor_state[i*decDelay+n] = state_in[i*state_in_n+j];
					}
				}
			}
		}
		else if(n == blockLen-1)
		{
			if(blockLen != decDelay)
			{
				for(i=0; i<state_number; i++)
				{
					for(j=0; j<decDelay-1; j++)
					{
						metric_stateI[i*decDelay+j] = metric_stateI[i*decDelay+j+1];
						metric_stateQ[i*decDelay+j] = metric_stateQ[i*decDelay+j+1];
						survivor_state[i*decDelay+j] = survivor_state[i*decDelay+j+1];
					}
				}
			}
			for(i=0; i<state_number; i++)
			{
				metric_stateI[i*decDelay+decDelay-1] = 0;
				metric_stateQ[i*decDelay+decDelay-1] = 0;
				survivor_state[i*decDelay+decDelay-1] = 0;
			}
			for(i=0; i<state_number; i++)
			{
				for(j=0; j<2; j++)
				{
					last_state = state_in[i*state_in_n+j];
					for(k=0; k<sampleNum; k++)
					{
						phase_refe[k] = 2*PI*Kf*(state_all[i*state_all_n+1]*qt[sampleNum+k] + \
							state_all[i*state_all_n+2]*qt[2*sampleNum+k]) + \
							state_all[i*state_all_n+3];
						hc1[k] = cos(phase_refe[k]);
						hs1[k] = sin(phase_refe[k]);
					}
					complexMatMul
					(
						hc1, hs1,
						I_out+n*sampleNum, Q_out+n*sampleNum,
						1, sampleNum, 1,
						pMetricI, pMetricQ,
						true
					);
					*pMetricI = *pMetricI + 1e-10;
					*pMetricI = *pMetricI + decayFactor*metric_stateI[(last_state-1)*decDelay+decDelay-2];
					*pMetricQ = *pMetricQ + decayFactor*metric_stateQ[(last_state-1)*decDelay+decDelay-2];
					metric_abs = sqrt(metricI*metricI + metricQ*metricQ);
					metric_state_abs = sqrt(metric_stateI[i*decDelay+decDelay-1]*metric_stateI[i*decDelay+decDelay-1] + \
						metric_stateQ[i*decDelay+decDelay-1]*metric_stateQ[i*decDelay+decDelay-1]);
					if(metric_abs > metric_state_abs)
					{
						metric_stateI[i*decDelay+decDelay-1] = *pMetricI;
						metric_stateQ[i*decDelay+decDelay-1] = *pMetricQ;
						survivor_state[i*decDelay+decDelay-1] = state_in[i*state_in_n+j];
					}
				}
			}
		}
		else
		{
			if(n > decDelay-1)
			{
				for(i=0; i<state_number; i++)
				{
					for(j=0; j<decDelay-1; j++)
					{
						metric_stateI[i*decDelay+j] = metric_stateI[i*decDelay+j+1];
						metric_stateQ[i*decDelay+j] = metric_stateQ[i*decDelay+j+1];
						survivor_state[i*decDelay+j] = survivor_state[i*decDelay+j+1];
					}
				}
			}
			for(i=0; i<state_number; i++)
			{
				metric_stateI[i*decDelay+decDelay-1] = 0;
				metric_stateQ[i*decDelay+decDelay-1] = 0;
				survivor_state[i*decDelay+decDelay-1] = 0;
			}
			for(i=0; i<state_number; i++)
			{
				for(j=0; j<2; j++)
				{
					last_state = state_in[i*state_in_n+j];
					for(k=0; k<sampleNum; k++)
					{
						phase_refe[k] = 2*PI*Kf*(state_all[i*state_all_n+1]*qt[sampleNum+k] + \
							state_all[i*state_all_n]*qt[k] + \
							state_all[i*state_all_n+2]*qt[2*sampleNum+k]) + \
							state_all[i*state_all_n+3];
						hc1[k] = cos(phase_refe[k]);
						hs1[k] = sin(phase_refe[k]);
					}
					complexMatMul
					(
						hc1, hs1,
						I_out+n*sampleNum, Q_out+n*sampleNum,
						1, sampleNum, 1,
						pMetricI, pMetricQ,
						true
					);
					*pMetricI = *pMetricI + 1e-10;
					*pMetricI = *pMetricI + decayFactor*metric_stateI[(last_state-1)*decDelay+decDelay-2];
					*pMetricQ = *pMetricQ + decayFactor*metric_stateQ[(last_state-1)*decDelay+decDelay-2];
					metric_abs = sqrt(metricI*metricI + metricQ*metricQ);
					metric_state_abs = sqrt(metric_stateI[i*decDelay+decDelay-1]*metric_stateI[i*decDelay+decDelay-1] + \
						metric_stateQ[i*decDelay+decDelay-1]*metric_stateQ[i*decDelay+decDelay-1]);
					if(metric_abs > metric_state_abs)
					{
						metric_stateI[i*decDelay+decDelay-1] = *pMetricI;
						metric_stateQ[i*decDelay+decDelay-1] = *pMetricQ;
						survivor_state[i*decDelay+decDelay-1] = state_in[i*state_in_n+j];
					}
				}
			}
		}
		if((n>=decDelay-1) & (n<blockLen-1))
		{
			for(i=0; i<state_number; i++)
			{
				metric_state_abs_col[i] = sqrt(metric_stateI[i*decDelay+decDelay-1]*metric_stateI[i*decDelay+decDelay-1] + \
					metric_stateQ[i*decDelay+decDelay-1]*metric_stateQ[i*decDelay+decDelay-1]);
			}
			survivor = FindMaxLoc(metric_state_abs_col, state_number);
			for(j=decDelay-1; j>0; j--)
			{
				survivor = survivor_state[(survivor-1)*decDelay+j];
			}
			if(n == decDelay-1)
			{
				decision[0] = state_all[(survivor-1)*state_all_n+2];
				decision[1] = state_all[(survivor-1)*state_all_n+1];
			}
			else
			{
				decision[n-decDelay+1] = state_all[(survivor-1)*state_all_n+1];
			}
		}
		else if(n == blockLen-1)
		{
			for(i=0; i<state_number; i++)
			{
				metric_state_abs_col[i] = sqrt(metric_stateI[i*decDelay+decDelay-1]*metric_stateI[i*decDelay+decDelay-1] + \
					metric_stateQ[i*decDelay+decDelay-1]*metric_stateQ[i*decDelay+decDelay-1]);
			}
			survivor = FindMaxLoc(metric_state_abs_col, state_number);
			for(j=decDelay-1; j>0; j--)
			{
				decision[n-decDelay+j+1] = state_all[(survivor-1)*state_all_n+1];
				survivor = survivor_state[(survivor-1)*decDelay+j];
			}
			if(blockLen == decDelay)
			{
				decision[n-decDelay+1] = state_all[(survivor-1)*state_all_n+2];
			}
			else
			{
				decision[n-decDelay+1] = state_all[(survivor-1)*state_all_n+1];
			}
		}
	}


// free------------------------------------------------------
	mxFree(metric_stateI);
	mxFree(metric_stateQ);
	mxFree(survivor_state);
	mxFree(phase_refe);
	mxFree(hc1);
	mxFree(hs1);
	mxFree(metric_state_abs_col);

	return;
}


void matMul(double *mat1, double *mat2, int m, int l, int n, double *resultMat)
{// matrix mul
	int i = 0, j = 0, k = 0;
	double tmp=0;
	for(i=0; i<m; i++)
	{
		for(j=0; j<n; j++)
		{
			tmp = 0;
			for(k=0; k<l; k++)
			{
				tmp +=  mat1[i*l+k]*mat2[k*n+j];
			}
			resultMat[i*n+j] = tmp;
		}
	}
}

void complexMatMul
(
 double *mat1_I, double *mat1_Q,
 double *mat2_I, double *mat2_Q,
 int m, int l, int n,
 double *resultMat_I, double *resultMat_Q,
 bool conjFlag
 )
{// complex matrix mul
	double *resultMat_I1, *resultMat_I2;
	double *resultMat_Q1, *resultMat_Q2;
	int i = 0, j = 0;

	if(		!(resultMat_I1 = (double*)mxMalloc(m*n*sizeof(double)))
		||	!(resultMat_I2 = (double*)mxMalloc(m*n*sizeof(double)))
		||	!(resultMat_Q1 = (double*)mxMalloc(m*n*sizeof(double)))
		||	!(resultMat_Q2 = (double*)mxMalloc(m*n*sizeof(double)))
		)
	{
		mexErrMsgTxt("Alloc failed!");
	}
	matMul(mat1_I, mat2_I, m, l, n, resultMat_I1);
	matMul(mat1_Q, mat2_Q, m, l, n, resultMat_I2);
	matMul(mat1_Q, mat2_I, m, l, n, resultMat_Q1);
	matMul(mat1_I, mat2_Q, m, l, n, resultMat_Q2);

	for(i=0; i<m; i++)
	{
		for(j=0; j<n; j++)
		{
			if(conjFlag)
			{
				resultMat_I[i*n+j] = resultMat_I1[i*n+j] + resultMat_I2[i*n+j];
				resultMat_Q[i*n+j] = resultMat_Q1[i*n+j] - resultMat_Q2[i*n+j];
			}
			else
			{
				resultMat_I[i*n+j] = resultMat_I1[i*n+j] - resultMat_I2[i*n+j];
				resultMat_Q[i*n+j] = resultMat_Q1[i*n+j] + resultMat_Q2[i*n+j];
			}
		}
	}
	mxFree(resultMat_I1);
	mxFree(resultMat_I2);
	mxFree(resultMat_Q1);
	mxFree(resultMat_Q2);
}

int FindMaxLoc(double *mat, int len)
{// find max location in vector
	int maxLoc = 0;
	double maxNum = -INF;
	int i=0;

	for(i=0; i<len; i++)
	{
		if(mat[i] > maxNum)
		{
			maxNum = mat[i];
			maxLoc = i;
		}
	}

	return maxLoc+1;
}