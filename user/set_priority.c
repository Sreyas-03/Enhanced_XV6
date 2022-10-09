#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        fprintf(2, "set_priority: insufficient arguments passed\n");
        exit(1);
    }
    else if (argc > 3)
    {
        fprintf(2, "set_priority: too many arguments passed\n");
        exit(1);
    }

    int newSP = atoi(argv[1]);
    int pid = atoi(argv[2]);
    int retval = set_priority(newSP, pid);
    if (retval == -1)
    {
        fprintf(2, "set_priority: Given pid (%d) does not exist\n", pid);
        exit(1);
    }
    exit(0);
}