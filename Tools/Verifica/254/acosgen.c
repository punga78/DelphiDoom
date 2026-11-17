/* Issue #254 (fase 2c): what CG_ACOS of cl_cgame.c answers: FloatAsInt( Q_acos( VMF(1) ) ), with Q_acos of
   qcommon\common.c copied as it is. Output: <bits of c> <bits of the answer>, seeded xorshift32 after a list of
   special values. Built by acos.sh; the golden is Tests/Data/Q3Host/acos.golden.txt. */
#include <stdio.h>
#include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

typedef unsigned int u32;

static u32 state = 2463534242u;

static u32 next( void ) {
	state ^= state << 13;
	state ^= state >> 17;
	state ^= state << 5;
	return state;
}

/* qcommon\common.c */
float Q_acos(float c) {
	float angle;

	angle = acos(c);

	if (angle > M_PI) {
		return (float)M_PI;
	}
	if (angle < -M_PI) {
		return (float)M_PI;
	}
	return angle;
}

static u32 bits( float f ) {
	u32 b;
	memcpy( &b, &f, 4 );
	return b;
}

static float asfloat( u32 b ) {
	float f;
	memcpy( &f, &b, 4 );
	return f;
}

static void line( u32 b ) {
	printf( "%08x %08x\n", b, bits( Q_acos( asfloat( b ) ) ) );
}

int main( void ) {
	static const u32 special[] = { 0x00000000, 0x80000000, 0x3f800000, 0xbf800000, 0x3f000000, 0xbf000000,
		0x3f7fffff, 0xbf7fffff, 0x3f800001, 0xbf800001, 0x40000000, 0xc0000000, 0x7f800000, 0xff800000,
		0x7fc00000, 0xffc00000, 0x00000001, 0x80000001, 0x007fffff, 0x3f3504f3, 0x3eaaaaab, 0x3f490fdb };
	int i, n = sizeof( special ) / sizeof( special[0] );
	for ( i = 0 ; i < n ; i++ ) {
		line( special[i] );
	}
	/* values inside -1..1 (exponent 2^-30 to 2^-1 and 1 - eps), some outside */
	for ( i = 0 ; i < 4000 ; i++ ) {
		u32 a = ( next() & 0x807fffff ) | ( ( 97u + next() % 31u ) << 23 );
		line( a );
	}
	for ( i = 0 ; i < 200 ; i++ ) {
		u32 a = ( next() & 0x807fffff ) | ( ( 127u + next() % 4u ) << 23 );
		line( a );
	}
	return 0;
}
