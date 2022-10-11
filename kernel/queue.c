#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"
#include "queue.h"

struct queue_info queue_info;
struct proc *sched_queue[NQUEUE][NPROC];

void queue_init()
{
    for (int i = 0; i < NQUEUE; i++)
    {
        queue_info.max_ticks[i] = 1 << i;
        queue_info.num_procs[i] = 0;
        queue_info.last[i] = 0;
    }
}

void queue_insert(struct proc *p, int queue_no)
{
    queue_no += NQUEUE * 10000; // to handle negative queue numbers
    queue_no %= NQUEUE;         // to handle queue numbers > 5
    if (queue_info.last[queue_no] > NPROC)
    {
        panic("MLFQ: Number of processes in current queue exceeds limit");
        return;
    }
    sched_queue[queue_no][queue_info.last[queue_no]] = p;
    queue_info.last[queue_no]++;
    queue_info.num_procs[queue_no]++;
    p->birth_time = sys_uptime(); // birth time also represents the time when it was inducted into the queue
    p->proc_queue = queue_no;
    p->in_queue = 1;        // flag telling whether its a part of a queue
    p->queue_wait_time = 0; // wait time in the queue
    p->running_time = 0;    // doubles up as the time for which the process is run
    return;
}

static void rotate_sched_queue(int queue_no, int num_rotations)
{
    for (int j = 0; j < num_rotations; j++)
    {
        for (int i = 0; i < NPROC - 1; i++)
        {
            sched_queue[queue_no][i] = sched_queue[queue_no][i + 1];
            if (!sched_queue[queue_no][i + 1])
                break;
        }
    }
    return;
}

struct proc* queue_pop(int queue_no)
{
    queue_no += NQUEUE * 10000; // to handle negative queue numbers
    queue_no %= NQUEUE;         // to handle queue numbers > 5
    if (queue_info.num_procs[queue_no] <= 0)
    {
        panic("MLFQ: Attempt to pop empty queue");
        return 0;
    }
    struct proc *retval = sched_queue[queue_no][0];
    retval->in_queue = 0;
    queue_info.num_procs[queue_no]--;
    sched_queue[queue_no][0] = 0;
    queue_info.last[queue_no]--;
    rotate_sched_queue(queue_no, 1);
    return retval;
}