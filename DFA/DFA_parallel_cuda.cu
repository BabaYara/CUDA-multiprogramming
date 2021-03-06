#include <stdio.h>
#include <stdlib.h>

//Kernel
__global__  void DFA_kernal(int *t_m,int *in,int n_state,int n_sigma,int init_state,int final_state,int n,int *out) {
	extern __shared__ int state_vectors[];
	int i,j;
	int t_id = threadIdx.x;
	//int *state_vector = (int *)malloc(sizeof(int)*n_state);
	//TO-DO: give this thread a part of string
	for(i=0;i<n_state;i++){
		//state_vector[i] = t_m[n_sigma*i + in[t_id]];
		state_vectors[n_state*t_id + i] = t_m[n_sigma*i + in[t_id]];
	}
	__syncthreads();
	//O(P) reduction
	for(i = 1; i < blockDim.x; ++i) {
        __syncthreads();
        if(t_id == i) {
            for(j=0;j<n_state;j++){
            	state_vectors[n_state*t_id + j] = state_vectors[n_state*t_id + state_vectors[n_state*(t_id-1) + j]];
            }
        }
    }
    for(int i=0;i<n_state;i++){
    	out[i] = state_vectors[n_state*(n-1) + i];
    }

}
 
int main()
{
	//Variables
	int STATES,SIGMA,INITIAL_STATE,FINAL_STATE,INPUT_LENGTH;
	int i,j;
	//Taking input
	//cin >> STATES >> SIGMA >> FINAL_STATE >> INPUT_LENGTH;
	scanf("%d %d %d %d",&STATES,&SIGMA,&FINAL_STATE,&INPUT_LENGTH);
	//An additional state has to be added for complete transition function
	STATES++;
	INITIAL_STATE = 0;
	//Input memory allocation and input retrival
	int *input = (int *)malloc(sizeof(int)*INPUT_LENGTH);
	for(i=0;i<INPUT_LENGTH;i++){
		scanf("%d",&input[i]);
	}
	//Allocating memory and retriving to transition matrix
	int **transition_matrix = (int **)malloc(sizeof(int *)*STATES);
	int *transition_matrix_data = (int *)malloc(sizeof(int)*STATES*SIGMA);
	for(i=0;i<STATES;i++){
		transition_matrix[i] = &transition_matrix_data[i*SIGMA];
	}

	for(i=0;i<STATES;i++){
		for(j=0;j<SIGMA;j++){
			scanf("%d",&transition_matrix[i][j]);
		}
	}
	//printing the input taken
	for(i=0;i<INPUT_LENGTH;i++){
		printf("%d ",input[i]);
	}
	printf("\n");
	for(i=0;i<STATES;i++){
		for(j=0;j<SIGMA;j++){
			printf("%d ",transition_matrix[i][j]);
		}
		printf("\n");
	}
	printf("\n");
	int *h_out = (int *)malloc(sizeof(int)*STATES);
	//////////////////////////////////////////////////////////////////////////
 	//Device memory
	int *d_transition_matrix;
	int *d_input;
	int *d_output;
 	
 	//Allocating and initializing memory on GPU
	cudaMalloc((void**)&d_transition_matrix,sizeof(int)*STATES*SIGMA);
	cudaMemcpy((void *)d_transition_matrix,(void *)transition_matrix_data,sizeof(int)*STATES*SIGMA,cudaMemcpyHostToDevice);
	
	cudaMalloc((void**)&d_input,sizeof(int)*INPUT_LENGTH);
	cudaMemcpy((void *)d_input,(void *)input,sizeof(int)*INPUT_LENGTH,cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_output,sizeof(int)*STATES);
	
	//Declaring grid and block size
	dim3 dimBlock(INPUT_LENGTH,1,1);
	dim3 dimGrid(1,1,1);
	DFA_kernal<<<dimGrid, dimBlock, STATES*INPUT_LENGTH>>>(d_transition_matrix,d_input,STATES,SIGMA,INITIAL_STATE,FINAL_STATE,INPUT_LENGTH,d_output);

	cudaMemcpy((void *)h_out,(void *)d_output,sizeof(int)*STATES,cudaMemcpyDeviceToHost);

	cudaFree(d_output);
	cudaFree(d_transition_matrix);
	cudaFree(d_input);

	/*for(i=0;i<STATES;i++){
		printf("%d\n",h_out[i]);
	}*/
	if(h_out[0]==FINAL_STATE){
		printf("Automata is accepting the string\n");
	}
	else{
		printf("String not accepted\n");
	}

	printf("All done\n");
	return 0;
}