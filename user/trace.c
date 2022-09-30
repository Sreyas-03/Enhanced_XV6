#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  fprintf(1, "The year is not %d\n", trace());
  exit(0);
}