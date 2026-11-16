/* Issue #254: what the math system calls of Quake III answer (TRAP_SIN ... TRAP_CEIL of sv_game.c, CG_* of
   cl_cgame.c, UI_* of cl_ui.c): FloatAsInt( sin( VMF(1) ) ) and so on, a float widened to a double, the function
   of the C library, the result narrowed to a float. The golden is Tests/Data/Q3Host/math.golden.txt:
     <bits a> <bits b> <sin> <cos> <atan2(a,b)> <sqrt a> <floor a> <ceil a>        (all as hex bits)
   Seeded xorshift32; a few special values first. Built by math.sh. */
#include <stdio.h>
#include <string.h>
#include <math.h>

typedef unsigned int u32;

static u32 state = 2463534242u;

static u32 next( void ) {
	state ^= state << 13;
	state ^= state >> 17;
	state ^= state << 5;
	return state;
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

static void line( u32 ba, u32 bb ) {
	float a = asfloat( ba ), b = asfloat( bb );
	printf( "%08x %08x %08x %08x %08x %08x %08x %08x\n", ba, bb,
		bits( (float)sin( a ) ), bits( (float)cos( a ) ), bits( (float)atan2( a, b ) ),
		bits( (float)sqrt( a ) ), bits( (float)floor( a ) ), bits( (float)ceil( a ) ) );
}

int main( void ) {
	static const u32 special[] = { 0x00000000, 0x80000000, 0x3f800000, 0xbf800000, 0x3f000000, 0xbf000000,
		0x7f800000, 0xff800000, 0x7fc00000, 0xffc00000, 0x00000001, 0x4b000000, 0x4affffff, 0xcb000000,
		0x40490fdb, 0x3fc90fdb, 0x42b40000 };
	int i, j, n = sizeof( special ) / sizeof( special[0] );
	for ( i = 0 ; i < n ; i++ ) {
		for ( j = 0 ; j < n ; j++ ) {
			line( special[i], special[j] );
		}
	}
	/* ordinary values: sign, exponent from 2^-20 to 2^14, any mantissa */
	for ( i = 0 ; i < 4000 ; i++ ) {
		u32 a = ( next() & 0x807fffff ) | ( ( 107u + next() % 35u ) << 23 );
		u32 b = ( next() & 0x807fffff ) | ( ( 107u + next() % 35u ) << 23 );
		line( a, b );
	}
	return 0;
}
