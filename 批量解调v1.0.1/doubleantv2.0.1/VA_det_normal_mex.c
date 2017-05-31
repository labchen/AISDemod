/*
refer to VA_det_normal.m
Survivor path is recorded in edge index, not state, to avoid using 'input' matrix,
which may be to large.

trellis matrix is not needed as parameters

input channel_out, coeff, symbols must be complex

VA_det_normal.m:
% [output_sequence, cumulated_metric, state_metric]=VA_det_normal(channel_out, coeff, k0, n0, L, symbols, start_state, end_state)
% viterbi algorithm detector for rate k0:n0 complex convolutional ISI
% no transitional (abnormal) states in the head and tail of the trellis
% 
% input:  channel_out       --   channel output, row vector
%         coeff             --   'time' varying coefficient,matrix with
%                                each column being the instantaneous
%                                coefficients, different outputs adjoint,
%                                different inputs' in series
%         k0                --   rate k0:n0
%         n0                --   rate k0:n0
%         L                 --   constraint length, L-1 registers
%         symbols           --   symbol mapping table, row vector
%         start_state       --   state index the trellis start from, from 1
%                                to number_of_states, set 0 if no initialization
%         end_state         --   state index the trellis end in, from 1 to
%                                number_of_states, set 0 if no termination
% output: output_sequence   --   output symbols' indices, includng initial
%                                memory, row vector of leght k0*(L+depth_of_trellis)
%         cumulated_metric  --   cumulated matric,scalar
%         
% 
%                ____    ____             
% ---------------| 1 |---| 3 |---
%              | ----  | ----   |
%         h:12 |    34 |     56 |
%              -------(+)------(+)-->--------
%                                           |
%                                          (+)----> 1 2
%                                           |
%                ____    ____               |    
% ---------------| 2 |---| 4 |--            |
%              | ----    ----  |            |
%           78 |   9 10  11 12 |            |
%              ---------------(+)--->--------
%                                              
% state: [1 2 3 4] 


% by W.Jiang(w.z.jiang@gmail.com ), 2011-6

*/

//Caution: matrices are passed as vector in column-wise

#define INFTY 1e9

#include "math.h"
#include "mex.h"

#define LAST_IN(s,q,l) (s)>>((l)-2)*(q)
#define LAST_STATE(s,i,q,l) (((s)<<(q))+(i))&((1<<((l)-1)*(q))-1)
// inline function not supported in C
/*
// get the last input for the given ending state
int LAST_IN(int state, int q, int L)
{
	return state>> (L-2)*q;
}

// get the last state for the given ending state
int LAST_STATE(int state, int i, int q, int L)
{
	return ((state<<q)+i) & ((1<<(L-1)*q)-1);
}
*/

// get the symbols' indices in the memory
void memContents(int state, int length, int q, int *out_mem)
{
	int i, temp=state;
	for (i=length-1;i>=0;i--)
	{
		out_mem[i] = temp&((1<<q)-1);
		temp = temp>>q;
	}
}

// map indices to symbols
void toSymbols(int *index, int L, double *symbols_real, double *symbols_imag, double *out_sym_real, double *out_sym_imag)
{
	int i;
	for(i=0;i<L;i++)
	{
		out_sym_real[i] = symbols_real[index[i]];
		out_sym_imag[i] = symbols_imag[index[i]];
	}
}


// get an output, symList:L, coeff:L*M, output:M
// coeff: [L*n0][L*n0]...[L*n0]
void getOutput(int L, int k0, int n0, double *symList_real, double *symList_imag, double *coeff_real, double *coeff_imag, double *output_real, double *output_imag)
{
	int i,j,k,index1,index2;
	for (i=0;i<n0;i++)
	{
		output_real[i] = 0.0;
		output_imag[i] = 0.0;
		for (j=0;j<L;j++)
		{
			for (k=0;k<k0;k++)
			{
				index1 = j*k0+k;
				index2 = (k*L+j)*n0+i;
				output_real[i] += symList_real[index1]*coeff_real[index2] - symList_imag[index1]*coeff_imag[index2];
				output_imag[i] += symList_real[index1]*coeff_imag[index2] + symList_imag[index1]*coeff_real[index2];
			}
		}
	}
}

//metric_Euclid = inline('sum(abs(x-y).^2)');
double metric_Euclid(int M, double *x_real, double *x_imag, double *y_real, double *y_imag)
{
	int i;
	double metric=0.0;
	for (i=0;i<M;i++)
	{
		metric += (x_real[i]-y_real[i])*(x_real[i]-y_real[i])
				+ (x_imag[i]-y_imag[i])*(x_imag[i]-y_imag[i]);
	}
	return metric;
}




// ---------------------------------------------------------------- entrance
void mexFunction(
                 int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{

	//Input and output
	double *channel_out_real, *channel_out_imag, *coeff_real, *coeff_imag;
	double *symbols_real, *symbols_imag;
	double *output_sequence, *cumulated_metric;//output
  int start_state=0, end_state=0;

	int k0, n0, L, q, NumState, degreeNode, TrellisLength;

	double *state_metric, temp_metric;
	double *symVec_real, *symVec_imag, *symMemory_real, *symMemory_imag, *outVec_real, *outVec_imag;
	int *survivor_path, *memory,  *inVec;
	
	int real_ch_out=0, real_coeff=0, real_symbols=0;
	int i, j, k;
	
// Check for proper number of arguments 
	if (nrhs < 6)
	{
		mexErrMsgTxt("VA_det_normal_mex requires 6 input arguments at least.");
	} 
	else if (nlhs > 2)
	{
		mexErrMsgTxt("VA_det_normal_mex has only 2 outputs.");
	} 
  
//-----------------------------------------------------------------------read parameters
	channel_out_real = mxGetPr(prhs[0]);
	channel_out_imag = mxGetPi(prhs[0]);
	coeff_real = mxGetPr(prhs[1]);
	coeff_imag = mxGetPi(prhs[1]);
	k0 = mxGetScalar(prhs[2]);
	n0 = mxGetScalar(prhs[3]);
	L = mxGetScalar(prhs[4]);
	symbols_real = mxGetPr(prhs[5]);
	symbols_imag = mxGetPi(prhs[5]);//input must be complex, or mxGetPi will get NULL
	if (nrhs > 6) start_state = mxGetScalar(prhs[6]);
	if (nrhs > 7) end_state = mxGetScalar(prhs[7]);
	

//----------------------------------------------------------------------- setup the environment variables
	q = (int)(log10(mxGetN(prhs[5]))/log10(2)+0.5);
	NumState = 1<<q*k0*(L-1); //number of states
	degreeNode = 1<<(q*k0); //number of edges go into and from each node,equal to size of inputs alphabet
	TrellisLength = (int)(mxGetN(prhs[0])/n0);// Length of the trellis
	//max_input = degreeNode;//number of possible input of edges,equal to degreeNode
	//num_edge = NumState*max_input;// number of edges 
	if (	!(survivor_path = (int *)mxMalloc(NumState*(TrellisLength)*sizeof(double)))
	||	!(state_metric = (double *)mxMalloc(2*NumState*sizeof(double)))
	||	!(memory = (int *)mxMalloc(k0*(L-1)*sizeof(int)))
	||	!(symMemory_real = (double *)mxMalloc(k0*(L-1)*sizeof(double)))
	||	!(symMemory_imag = (double *)mxMalloc(k0*(L-1)*sizeof(double)))
	||	!(symVec_real = (double *)mxMalloc(k0*L*sizeof(double)))
	||	!(symVec_imag = (double *)mxMalloc(k0*L*sizeof(double)))
	||	!(outVec_real = (double *)mxMalloc(n0*sizeof(double)))
	||	!(outVec_imag = (double *)mxMalloc(n0*sizeof(double)))
	||	!(inVec = (int *)mxMalloc(k0*sizeof(int)))	)
	{
		mexErrMsgTxt("VA_det_normal_mex: memory allocation error.");
	}

	// in case of real input
	if(!channel_out_imag) 
	{
		real_ch_out = 1;
		channel_out_imag = (double *)mxMalloc(mxGetN(prhs[0])*sizeof(double));
		for (i=0;i<mxGetN(prhs[0]);i++)
		{
			channel_out_imag[i] = 0.0;
		}
	}
	
	if(!coeff_imag) 
	{
		real_coeff = 1;
		coeff_imag = (double *)mxMalloc(mxGetM(prhs[1])*mxGetN(prhs[1])*sizeof(double));
		for (i=0;i<mxGetM(prhs[1])*mxGetN(prhs[1]);i++)
		{
			coeff_imag[i] = 0.0;
		}
	}
	
	if(!symbols_imag) 
	{
		real_symbols = 1;
		symbols_imag = (double *)mxMalloc(mxGetN(prhs[5])*sizeof(double));
		for (i=0;i<mxGetN(prhs[5]);i++)
		{
			symbols_imag[i] = 0.0;
		}
	}
	
	if((!channel_out_imag)||(!coeff_imag)||(!symbols_imag))
	{
		mexErrMsgTxt("VA_det_normal_mex: memory allocation error.");
	}

/*
	printf("last_in = \n");
	for(i=0;i<NumState;i++)
	{
		for(j=0;j<degreeNode;j++)
		printf("%d ",LAST_IN(i,q,L));
		printf("\n");
	}
	printf("last_state = \n");
	for(i=0;i<NumState;i++)
	{
		for(j=0;j<degreeNode;j++)
		printf("%d ",LAST_STATE(i,j,q,L));
		printf("\n");
	}
*/

// initialize the metric
	for (i=0;i<2*NumState;i++)
	{
		state_metric[i]=0.0;
	}
	
	if ((start_state>0)&&(start_state<=NumState))
	{
		for (i=0;i<NumState;i++)
		{
			state_metric[i]=INFTY;
		}
		state_metric[start_state-1] = 0;
	}




// middle metrix
	for (i=0;i<TrellisLength;i++)
	{
		for(j=0;j<NumState;j++)
		{
			state_metric[j+NumState] = INFTY;
		}
		for (j=0;j<NumState;j++)//post-state
		{
			for (k=0;k<degreeNode;k++)//incoming edge
			{
				memContents(LAST_STATE(j,k,q*k0,L),(L-1)*k0,q,memory);
				memContents(LAST_IN(j,q*k0,L), k0, q, inVec);
				toSymbols(inVec, k0, symbols_real, symbols_imag, symVec_real, symVec_imag);
				toSymbols(memory,(L-1)*k0,symbols_real,symbols_imag,symVec_real+k0,symVec_imag+k0);
				getOutput(L,k0,n0,symVec_real,symVec_imag,coeff_real+i*L*k0*n0,coeff_imag+i*L*k0*n0,outVec_real,outVec_imag);
				temp_metric = metric_Euclid(n0,outVec_real,outVec_imag,channel_out_real+i*n0,channel_out_imag+i*n0);
				if(state_metric[j+NumState] > state_metric[LAST_STATE(j,k,q*k0,L)]+temp_metric)
				{
					state_metric[j+NumState] = state_metric[LAST_STATE(j,k,q*k0,L)]+temp_metric;
					survivor_path[j+i*NumState] = k;//record edge,not state
				}
			}
		}
		//exchange
		for (j=0;j<NumState;j++)
		{
			temp_metric = state_metric[j];
			state_metric[j] = state_metric[j+NumState];
			state_metric[j+NumState] = temp_metric;
		}
	}



//----------------------------------------------------------------- output
	plhs[0] = mxCreateDoubleMatrix(1, (TrellisLength+L-1)*k0, mxREAL);
	//plhs[1] = mxCreateDoubleScalar(INFTY); // illegal types?
	plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
	output_sequence = mxGetPr(plhs[0]);
	//cumulated_metric = mxGetScalar(plhs[1]); // wrong way
	cumulated_metric = mxGetPr(plhs[1]);// get the pointer so that it's value can be changed


	//get ending state
	if ((end_state>0)&&(end_state<=NumState)) // terminated
	{
		j = end_state-1;
		*cumulated_metric = state_metric[j];
	}
	else
	{
		j = 0;//state
  	temp_metric = INFTY;
  	for (i=0;i<NumState;i++)
  	{
  		if(temp_metric>state_metric[i])
  		{
  			temp_metric = state_metric[i];
  			j = i;
  		}
  	}
  	*cumulated_metric = temp_metric;
	}
	
	//get output
	for (i=TrellisLength-1;i>=0;i--)
	{
		memContents(LAST_IN(j,q*k0,L), k0, q, inVec);
		for (k=0;k<k0;k++)
		{
			output_sequence[(i+L-1)*k0+k] = inVec[k];
		}
		j = LAST_STATE(j,survivor_path[j+i*NumState],q*k0,L);
	}
	
	//also output initial memory
	memContents(j,(L-1)*k0,q,memory);
	for (i=L-2;i>=0;i--)
	{
		for (k=0;k<k0;k++)
		{
			output_sequence[i*k0+k]=memory[(L-2-i)*k0+k];
		}
	}


//----------------------------------------------------------------- free the memory 
	mxFree(survivor_path);
	mxFree(state_metric);
	mxFree(memory);
	mxFree(symMemory_real);
	mxFree(symMemory_imag);
	mxFree(symVec_real);
	mxFree(symVec_imag);
	mxFree(outVec_real);
	mxFree(outVec_imag);
	mxFree(inVec);
	if (real_ch_out>0) mxFree(channel_out_imag);
	if (real_coeff>0) mxFree(coeff_imag);
	if (real_symbols>0) mxFree(symbols_imag);

	return;
}
