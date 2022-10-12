#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"

typedef struct syscall_details
{
  char *name;
  int numArgs;
} syscall_details;

// Fetch the uint64 at addr from the current process.
int fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    return -1;
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    return -1;
  return strlen(buf);
}

static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n)
  {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
  *ip = argraw(n);
}

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
}

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}

// Prototypes for the functions that handle system calls.
extern uint64 sys_fork(void);
extern uint64 sys_exit(void);
extern uint64 sys_wait(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_kill(void);
extern uint64 sys_exec(void);
extern uint64 sys_fstat(void);
extern uint64 sys_chdir(void);
extern uint64 sys_dup(void);
extern uint64 sys_getpid(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_uptime(void);
extern uint64 sys_open(void);
extern uint64 sys_write(void);
extern uint64 sys_mknod(void);
extern uint64 sys_unlink(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_close(void);
extern uint64 sys_strace(void);
extern uint64 sys_settickets(void);
extern uint64 sys_set_priority(void);
/////////////////// IMPLEMENTED FOR SIGALARM //////////////
extern uint64 sys_sigalarm(void);
extern uint64 sys_sigreturn(void);
///////////////////////////////////////////////////////////
/////////////////// IMPLEMENTED FOR SCHED TEST //////////////
extern uint64 sys_waitx(void);
///////////////////////////////////////////////////////////
// extern uint64 sys_getyear(void);  // this is for testing purpose only, can be removed

// An array mapping syscall numbers from syscall.h
// to the function that handles the system call.
static uint64 (*syscalls[])(void) = {
    [SYS_fork] sys_fork,
    [SYS_exit] sys_exit,
    [SYS_wait] sys_wait,
    [SYS_pipe] sys_pipe,
    [SYS_read] sys_read,
    [SYS_kill] sys_kill,
    [SYS_exec] sys_exec,
    [SYS_fstat] sys_fstat,
    [SYS_chdir] sys_chdir,
    [SYS_dup] sys_dup,
    [SYS_getpid] sys_getpid,
    [SYS_sbrk] sys_sbrk,
    [SYS_sleep] sys_sleep,
    [SYS_uptime] sys_uptime,
    [SYS_open] sys_open,
    [SYS_write] sys_write,
    [SYS_mknod] sys_mknod,
    [SYS_unlink] sys_unlink,
    [SYS_link] sys_link,
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
    [SYS_strace] sys_strace,
    [SYS_settickets] sys_settickets,
    [SYS_set_priority] sys_set_priority,
    /////////////////// IMPLEMENTED FOR SIGALARM ///////////////
    [SYS_sigalarm]   sys_sigalarm,
    [SYS_sigreturn]   sys_sigreturn,
    ////////////////////////////////////////////////////////
    ////////////////// IMPLEMENTED FOR SCHED TEST ////////////
    [SYS_waitx] sys_waitx
    //////////////////////////////////////////////////////////

    // [SYS_getyear] sys_getyear,
};

syscall_details syscall_info[] = {
    [SYS_fork].name = "fork",
    [SYS_exit].name = "exit",
    [SYS_wait].name = "wait",
    [SYS_pipe].name = "pipe",
    [SYS_read].name = "read",
    [SYS_kill].name = "kill",
    [SYS_exec].name = "exec",
    [SYS_fstat].name = "fstat",
    [SYS_chdir].name = "chdir",
    [SYS_dup].name = "dup",
    [SYS_getpid].name = "getpid",
    [SYS_sbrk].name = "sbrk",
    [SYS_sleep].name = "sleep",
    [SYS_uptime].name = "uptime",
    [SYS_open].name = "open",
    [SYS_write].name = "write",
    [SYS_mknod].name = "mknod",
    [SYS_unlink].name = "unlink",
    [SYS_link].name = "link",
    [SYS_mkdir].name = "mkdir",
    [SYS_close].name = "close",
    [SYS_strace].name = "strace",
    [SYS_settickets].name = "settickets",
    [SYS_set_priority].name = "set_priority",
    /////////////////// IMPLEMENTED FOR SIGALARM ///////////////
    [SYS_sigalarm].name = "sigalarm",
    [SYS_sigreturn].name = "sigreturn",
    ////////////////////////////////////////////////////////

    //////////////////// IMPLEMENTED FOR SCHED TEST ////////////////
    [SYS_waitx].name = "waitx",
    [SYS_waitx].numArgs = 0,
    ////////////////////////////////////////////////////////////////

    [SYS_fork].numArgs = 0,
    [SYS_exit].numArgs = 1,
    [SYS_wait].numArgs = 1,
    [SYS_pipe].numArgs = 1,
    [SYS_read].numArgs = 3,
    [SYS_kill].numArgs = 1,
    [SYS_exec].numArgs = 2,
    [SYS_fstat].numArgs = 2,
    [SYS_chdir].numArgs = 1,
    [SYS_dup].numArgs = 1,
    [SYS_getpid].numArgs = 0,
    [SYS_sbrk].numArgs = 1,
    [SYS_sleep].numArgs = 1,
    [SYS_uptime].numArgs = 0,
    [SYS_open].numArgs = 2,
    [SYS_write].numArgs = 3,
    [SYS_mknod].numArgs = 3,
    [SYS_unlink].numArgs = 1,
    [SYS_link].numArgs = 2,
    [SYS_mkdir].numArgs = 1,
    [SYS_close].numArgs = 1,
    [SYS_strace].numArgs = 1,
    [SYS_settickets].numArgs = 1,
    [SYS_set_priority].numArgs = 2,
    /////////////////// IMPLEMENTED FOR SIGALARM ///////////////
    [SYS_sigalarm].numArgs = 2,
    [SYS_sigreturn].numArgs = 0,
    ///////////////////////////////////////////////////////////
    
};

void prompt_strace(struct proc *p, int num)
{
  printf("%d: syscall %s (", p->pid, syscall_info[num].name);
  int arg;
  for (int i = 0; i < syscall_info[num].numArgs; i++)
  {
    argint(i, &arg);
    if (i == syscall_info[num].numArgs - 1)
      printf("%d", arg);
    else
      printf("%d ", arg);
  }
  printf(") -> %d\n", p->trapframe->a0);
  return;
}

void syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
  }
  else
  {
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }

  if (num > 0 && num < NELEM(syscalls) && syscalls[num] && ((p->strace_bit>>num) & 1))
  {
    prompt_strace(p, num);
  }
  return;
}
