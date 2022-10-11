#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void h1(){
    printf("h1h1h1--h2\n");
    return ;
}

int main(){
    void(*  h1_ptr)(void);
    h1_ptr = h1;

    long int x = (long int)h1_ptr;
    printf("%x(%x) -> %d\n",h1_ptr,h1,x);

    printf("> alarm %d \n",sigalarm(100000,h1_ptr));
    printf("> return %d \n",sigreturn());
    return 0;
}