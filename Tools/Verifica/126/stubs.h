/* Stubs for the services and the structures of the game that the original functions use:
   just enough to compile them. No game logic is here. */
#ifndef Q3GEN_STUBS_H
#define Q3GEN_STUBS_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>
#include "q_shared.h"
#include "qfiles.h"

#define FS_READ 0
/* the power-up bit of the haste is only a number of the driver: the functions test (1 << PW_HASTE) */
#define PW_HASTE 6
#define EF_DEAD 0x00000001
#define MAX_CLIENTS 64
#endif
