#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

// setting an alarm
uint64
sys_sigalarm(void){
  int inteval;
  argint(0,&inteval);

  void * handler = (void*)__INT_MAX__;
  argptr(1,handler);
  printf("\t----inside sys \n \t<%d> <%x>\n",inteval,handler);
  int flag = set_alarm(inteval,handler);
  printf("\t----inside sys \n \t<%d> <%x>\n",inteval,handler);

  return flag;
}

// calling and handler when alarm is set
uint64
sys_sigreturn(void){
  alarm_stop();
  return 101;
}

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_strace(void)
{
  int n;
  argint(0, &n);
  strace(n);
  return 0;
}

uint64
sys_settickets(void)
{
  int n;
  argint(0, &n);
  int m = settickets(n);

  if(m == n)  // correct number of tickets set
    return 0;
  return -1;
}

// uint64
// sys_getyear(void) // this is for testing purpose only, can be removed
// {
//   return 2003;
// }