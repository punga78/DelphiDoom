/*
 * Included before everything (gcc -include): in the original build (MSVC) M_PI is the float constant of
 * q_shared.h, "3.14159265358979323846f"; the math.h of mingw defines it as a double first, which would make
 * AngleVectors multiply as a double. Same as the original: math.h first, then the float constant.
 */
#include <math.h>
#undef M_PI
#define M_PI 3.14159265358979323846f
