// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define REFINDEX(pa) ((uint64)pa >> 12)
#define REFMAX_SIZE PHYSTOP/PGSIZE

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;

  //////// COW ////////
  int count[REFMAX_SIZE];
  //////////////////////

} kmem;

void
kinit()
{
  //////// COW ////////
  memset(kmem.count, 0, sizeof(kmem.count) / sizeof(int));
  //////////////////////
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  // memset(pa, 1, PGSIZE);
  // r = (struct run*)pa;

  ////////////////// COW //////////////////////
  acquire(&kmem.lock);
  if((--kmem.count[REFINDEX(pa)]) <= 0)
  {
    memset(pa, 1, PGSIZE);
    r = (struct run*)pa;
    r->next = kmem.freelist;
    kmem.freelist = r;
  }
  release(&kmem.lock);
  //////////////////////////////////////////
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
//////////////// COW ///////////////////////////////
  if(r)
  {
    kmem.freelist = r->next;
    kmem.count[REFINDEX(r)] = 1;
  }
  /////////////////////////////////////////////////
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}

//////////////// COW ///////////////////////////////
void add_refs_to_pte(void *pa) {
  acquire(&kmem.lock);
  kmem.count[REFINDEX(pa)] += 1;
  release(&kmem.lock);
}

int cow_fault_rectifier(uint64 va,pagetable_t pagetable) {
  if(va >= MAXVA) 
    return -1;
  
  pte_t *pte = walk(pagetable, va, 0);
  if(pte == 0 || (*pte & PTE_V) == 0)
    return -1;

  uint64 flags =  PTE_FLAGS(*pte);
  uint64 pa = (uint64)PTE2PA(*pte);
  char * mem;

  acquire(&kmem.lock);
  if((*pte & PTE_C) && kmem.count[REFINDEX(pa)] == 1) {
    flags &= (~PTE_C); 
    flags |= PTE_W;    
    *pte = PA2PTE(pa) | flags;
    release(&kmem.lock);
    return 0;
  }
  release(&kmem.lock);

  mem = (char *)kalloc();
  if(mem == 0) 
    return -1;

  memmove((void *)mem, (void *)pa, PGSIZE); // copy pte to pa
  kfree((void *)pa);

  //  unset cow bit and set write bit 
  flags &= (~PTE_C); 
  flags |= PTE_W;    
  *pte = PA2PTE(mem) | flags;   // changing flags of pte

  return 0;
}
///////////////////////////////////////////////