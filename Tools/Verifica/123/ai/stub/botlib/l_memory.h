/* Stub of l_memory.h: the memory is the one of the C library */
#include <stdlib.h>
#define GetMemory(size) malloc(size)
#define GetClearedMemory(size) calloc(1, (size))
#define GetHunkMemory(size) malloc(size)
#define GetClearedHunkMemory(size) calloc(1, (size))
#define FreeMemory(ptr) free(ptr)
