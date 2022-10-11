#include "param.h"

struct queue_info {
	int num_procs[NQUEUE];   // stores the number of processes in the queue
	int max_ticks[NQUEUE];   // stores the tick interval for each queue
	int last[NQUEUE];        // stores the index where append should be done in the array
};  // each element of the array is for each of the 5 different priority queues

void queue_init();  // initialises the priority queues
void queue_insert(struct proc*, int);   // inserts proc into specified queue
struct proc* queue_pop(int);   // pops the top priority proc from specified queue

extern struct queue_info queue_info;    // making the struct accessible throughout
