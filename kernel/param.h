#define NPROC        64  // maximum number of processes

#ifdef MLFQ
    #define NCPU          1  // maximum number of CPUs
#endif
#ifndef MLFQ
    #define NCPU          8  // max number of CPUs
#endif

#define NOFILE       16  // open files per process
#define NFILE       100  // open files per system
#define NINODE       50  // maximum number of active i-nodes
#define NDEV         10  // maximum major device number
#define ROOTDEV       1  // device number of file system root disk
#define MAXARG       32  // max exec arguments
#define MAXOPBLOCKS  10  // max # of blocks any FS op writes
#define LOGSIZE      (MAXOPBLOCKS*3)  // max data blocks in on-disk log
#define NBUF         (MAXOPBLOCKS*3)  // size of disk block cache
#define FSSIZE       2000  // size of file system in blocks
#define MAXPATH      128   // maximum file path name
#define NQUEUE       5     // number of priority queues for MLFQ
#define AGING_TICKS 128 // Max wait time before a process age

// #define DEBUG
// #define DEBUG_settickets
// #define DEBUG_setpriority