# Enhancing xv-6
```
Team members -
    Sreenivas BP - 2021111007
    S Sreyas - 2021111016
```
___

This assignment was developed and tested in -
- Distro      - Ubuntu 22.04
- Language    - ANSI C

## Strace -
- the macro for strace was defined
- the number of arguments taken, and the name of the system call was entered into the struct (these changes are done in `syscall.h` and `syscall.c`)
- a new key(processMask) is added to struct proc in `proc.h`
- create the file `strace.c` to enable the usercall of this funciton
- changes were done to `usys.pl`, `makefile` and `user.h` to enable the usercall

## Sigalarm and Sigreturn -
- The required macros were declared and number and name of the system calls were added to the struct. (changes in `syscall.h` and `syscall.c`)

## Round Robin Scheduling - 
- It is the default scheduler of xv-6
- All the processes that are stored in an array proc.
- The scheduler schedules the process at the next index everytime a process needs to be scheduled.
- this ensures that every process will be scheduled after at most the number of processes that are runnable (max runnable processes = 64)
- No process is scheduled twice while another process is never scheduled

## FCFS scheduling - 
- FCFS is non-preemptive scheduling
- creation time of a process is added to struct proc
- whenever a process is created, its creation time is set using the sys_uptime() system call - (it gives the number of ticks)
- while scheduling, we iterate through all the processes, and find the process with the lowest creation time
- The process having the lowest creation time is run until it gets completed
- No tie-breaks are used, if two processes are created at the same tick, one of them is chosen at random (the one with lower index in the proc array is run)

## Lottery Based Scheduling -
- LBS is preemptive scheduler. the process gets preempted once the time interval is completed
- Every process is assigned a certain number of tickets.
- Num_tickets is added to struct proc to maintain the number of tickets each process has
- Every process is initialised with 1 ticket when it's created
- settickets(int number_of_tickets, int ppid) (sys call)
- It sets number of tickets for the process with pid ppid to number_of_tickets.
- while scheduling the process, 
    - iterate through all the processes
    - store the cumulative sum of the number of tickets
    - Generate a random number and takes its modulo with total number of tickets (a function to generate random numbers given a seed is implemented similar to rand())
    - the first process that has higher cumulative tickets than the random number is executed
- the probability of a certain process being run is the number of tickets it has
- no tiebreak will occur


## Priority Based Scheduling -
- PBS is non-preemptive scheduler, except when set_priority is called. If it is called, the rescheduling is called to preempt the process if necessary
- static priority, dynamic priority, sleep time and running time is added to struct proc
- the set_priority system(int static_priority) can be used to set the priority of the current process to the assiigned static priority
- while scheduling, we iterate through all the processes and calculate their dynamic priorities
- the process with the lowest dynamic priority is executed
- calculation of dynamuc prioity is done by - 
> dynamic_priority = static_prioity - nicesness + 5

- niceness is calculated through running time and sleep time.
- sleep time of a process is calculated as the time between wakeup and sleep of the process
- running time of a process is calculated by incrementing the run time of myproc() whenever we increment ticks
- in case of tie-breaks, we check the number of times a process is scheduled as tie-break
    - process with lower number of schedules is scheduled
- in case of further tie-breaks, we use FCFS, based on creation time of the process

## MLFQ - 
- MLFQ required implementation of queues, so the datasrtucture queue was made
- The queues are of static length (NPROC = 64), and functions to insert and pop from the queue were implemented
- when the scheduler is called, the program iterates through all the processes, and adds teh processes that are runnable but not already in a queue to the highest priority queue(q0)
- The processes are run such that the queue q0 is run until its empty, then q1 is run and so on.
- if a process of higher priority occurs while executing a process, the process is pre-empted and the new process is executed.
- the time after which aging of a process will occur is set to 128 ticks becuase -
    - there are atomst 64 processes, and 5 queues. => about 13 processes per queue
    - the average ticks of a queue per timeframe = (1+2+4+8+16)/5 approx 7
    - as there are 13 procs per queue and 7 ticks on average for a process, we allocate 7*13 = 91, closest power of 2 = 128
- if a process reliquishes control for IO reasons, it is added to the end of the same queue it previously was in
- if the process has used its complete share of time, its added to the next queue (unless its already in the last queue)
- There will be no tie-breaks, as the processes are added to each queue in an order. (or in fact, the process that has lower index in proc array will be run first if its in the same queue).
- MLFQ works only for 1 CPU
___

## Observation -
### ROUND ROBIN - 
![alt text](/s_imgs/RR_SS1.png)
![alt text](/s_imgs/RR_SS3.png)
![alt text](/s_imgs/RR_SS5.png)

### FCFS-
![alt text](/s_imgs/FCFS_SS1.png)
![alt text](/s_imgs/FCFS_SS3.png)
![alt text](/s_imgs/FCFS_SS5.png)
### LBS -
![alt text](/s_imgs/LBS_SS1.png)
![alt text](/s_imgs/LBS_SS3.png)
![alt text](/s_imgs/LBS_SS5.png)
### PBS -
![alt text](/s_imgs/PBS_SS1.png)
![alt text](/s_imgs/PBS_SS3.png)
![alt text](/s_imgs/PBS_SS5.png)
### MLFQ - 
![alt text](/s_imgs/MLFQ_SS1.png)

## Analysis -
![alt text](/s_imgs/ANALYSIS.png)

- from the analysis, we can infer that, for the given set of processes -
> FCFS > PBS > LBS > RR > MLFQ

(order by ratio of runtime to waittime, run one 1 CPU)
- MLFQ will work better when the number of processes increase and when CPU bound processes become more intensive
> FCFS >> PBS > RR > LBS
(order by ration of runtime to waittime, when run on multiple CPUs)
- FCFS outperforms all other schedulers when multiple CPUs are used
