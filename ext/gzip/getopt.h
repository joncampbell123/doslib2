#ifndef __GZIP_GETOPT_H
#define __GZIP_GETOPT_H

#include <unistd.h>

struct option
{
  const char *name;
  /* has_arg can't be an enum because some compilers complain about
     type mismatches in all the code that assumes it is an int.  */
  int has_arg;
  int *flag;
  int val;
};

extern int getopt_long (int ___argc, char * const *___argv,
                        const char *__shortopts,
                        const struct option *__longopts, int *__longind);
extern int getopt_long_only (int ___argc, char * const *___argv,
                             const char *__shortopts,
                             const struct option *__longopts, int *__longind);

#endif

