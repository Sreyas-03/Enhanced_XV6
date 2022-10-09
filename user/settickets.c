#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        fprintf(2, "settickets: insufficient arguments passed\n");
        exit(1);
    }
    else if (argc > 2)
    {
        fprintf(2, "settickets: too many arguments passed\n");
        exit(1);
    }

    int numTickets = atoi(argv[1]);
    int retval = settickets(numTickets);
    if (retval)
    {
        fprintf(2, "settickets: system error. Try again\n");
        exit(1);
    }
    exit(0);
}