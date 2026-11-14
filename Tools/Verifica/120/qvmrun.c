/*
 * Parity driver of the issue #120: runs QVM images on the virtual machine of Quake III
 * Arena (vm.c and vm_interpreted.c, included as they are in vm_original.inc) with a fake
 * host, and prints what the tests of Libs\Qvm compare: the value every call returns, the
 * system calls with their arguments, the fingerprint (FNV-1a 64) of the data image.
 *
 *   qvmrun run <scenarios.txt>
 *   qvmrun bench <file.qvm> <profile> <command> <argument> <repetitions>
 *
 * A scenario file:
 *   scenario <name> <profile> <file.qvm> <file.map or ->
 *   trace on|off            the lines of the system calls are printed or only hashed
 *   note <text>             printed as it is
 *   call <command> [<argument> ...]      at most 9 arguments, decimal; prints "R value", or "E text"
 *                           (Com_Error) or "T code" (a trap of the processor) and the memory line
 *   mem                     "M fingerprint-of-the-data-image system-calls fingerprint-of-the-calls"
 *   restart                 VM_Restart
 *   info                    code length, table length, data length, stack, symbols
 *   symbols                 VM_ValueToSymbol of every value from -1 to the code length
 *   symval <name>           VM_SymbolToValue
 *   end
 * After the first error or trap the other calls of a scenario are skipped.
 *
 * VM_Call is not used: it reads its variable arguments as an array from the address of
 * the first one, which holds only with the cdecl convention of 32 bit x86 (it is wrong at
 * 64 bit). The driver does the same six lines and calls VM_CallInterpreted with a real
 * array, so that it does not depend on how it is compiled.
 */
#include <windows.h>
#include <stdint.h>
#include "stubs.h"
#include "vm_original.inc"

void VM_Compile( vm_t *vm, vmHeader_t *header ) { Com_Error( ERR_FATAL, "no compiler" ); }
int VM_CallCompiled( vm_t *vm, int *args ) { return 0; }

enum { PROFILE_TEST, PROFILE_GAME, PROFILE_CGAME, PROFILE_UI };

static int g_profile;
static int g_trace;
static int g_syscalls;
static uint64_t g_traceHash;
static int g_entityToken;
static int g_depth;

#define FNV_OFFSET 0xCBF29CE484222325ull
#define FNV_PRIME 0x100000001B3ull

static void mix( uint64_t *hash, const void *data, int size ) {
	const byte *p = data;
	int i;
	for ( i = 0 ; i < size ; i++ ) {
		*hash = ( *hash ^ p[i] ) * FNV_PRIME;
	}
}

/* ---- traps of the processor (division by zero, INT_MIN / -1, a wild pointer) ---- */

static intptr_t g_trapJump[5];
static volatile int g_inCall;
static volatile unsigned g_trapCode;

static void trap_trampoline( void ) {
	__builtin_longjmp( g_trapJump, 1 );
}

static LONG CALLBACK trap_handler( EXCEPTION_POINTERS *info ) {
	unsigned code = info->ExceptionRecord->ExceptionCode;
	if ( g_inCall && ( code == EXCEPTION_INT_DIVIDE_BY_ZERO || code == EXCEPTION_INT_OVERFLOW
		|| code == EXCEPTION_ACCESS_VIOLATION ) ) {
		g_trapCode = code;
#ifdef _WIN64
		info->ContextRecord->Rip = (DWORD64)trap_trampoline;
		info->ContextRecord->Rsp = ( ( info->ContextRecord->Rsp - 256 ) & ~(DWORD64)15 ) - 8;
#else
		info->ContextRecord->Eip = (DWORD)trap_trampoline;
		info->ContextRecord->Esp = ( ( info->ContextRecord->Esp - 256 ) & ~(DWORD)15 ) - 4;
#endif
		return EXCEPTION_CONTINUE_EXECUTION;
	}
	return EXCEPTION_CONTINUE_SEARCH;
}

/* ---- the fake host ---- */

static byte *host_ptr( int address, int length ) {
	int masked = address & currentVM->dataMask;
	if ( length < 0 || (long long)masked + length > (long long)currentVM->dataMask + 1 ) {
		Com_Error( ERR_DROP, "host: out of range" );
	}
	return currentVM->dataBase + masked;
}

static int host_strlen( int address ) {
	int masked = address & currentVM->dataMask;
	int length = 0;
	while ( 1 ) {
		if ( masked + length > currentVM->dataMask ) {
			Com_Error( ERR_DROP, "host: out of range" );
		}
		if ( !currentVM->dataBase[masked + length] ) {
			return length;
		}
		length++;
	}
}

static void print_escaped( const char *prefix, const byte *text, int length ) {
	int i;
	printf( "%s", prefix );
	for ( i = 0 ; i < length ; i++ ) {
		if ( text[i] < 32 || text[i] > 126 || text[i] == '\\' ) {
			printf( "\\x%02X", text[i] );
		} else {
			putchar( text[i] );
		}
	}
	putchar( '\n' );
}

static int float_bits( float value ) { int bits; memcpy( &bits, &value, 4 ); return bits; }
static float bits_float( int bits ) { float value; memcpy( &value, &bits, 4 ); return value; }

static int host_round( int bits, int up ) {
	unsigned magnitude = (unsigned)bits & 0x7FFFFFFF;
	float value, whole;
	if ( magnitude >= 0x4B000000 ) {	/* 2^23 and above, infinite, NaN: already whole */
		return bits;
	}
	value = bits_float( bits );
	whole = (float)(int)value;
	if ( up ) {
		if ( whole < value ) whole += 1.0f;
	} else {
		if ( whole > value ) whole -= 1.0f;
	}
	return float_bits( whole );
}

static int call_vm( vm_t *vm, int *args ) {
	vm_t *oldVM = currentVM;
	int r;
	currentVM = vm;
	lastVM = vm;
	r = VM_CallInterpreted( vm, args );
	if ( oldVM != NULL ) {
		currentVM = oldVM;
	}
	return r;
}

static const char *g_entityTokens[] = { "{", "classname", "worldspawn", "}" };

static int host_dispatch( int *args ) {
	int number = args[0];
	int printTrap = 0, errorTrap = 1, floorTrap = 107, ceilTrap = 108;
	int length, i;

	if ( g_profile == PROFILE_UI ) {
		printTrap = 1;
		errorTrap = 0;
	}
	if ( g_profile == PROFILE_GAME ) {
		floorTrap = 110;
		ceilTrap = 111;
	}

	if ( number == printTrap || number == errorTrap ) {
		length = host_strlen( args[1] );
		print_escaped( number == errorTrap ? "X " : "P ", host_ptr( args[1], length ), length );
		if ( number == errorTrap ) {
			char text[1024];
			if ( length > 1023 ) length = 1023;
			memcpy( text, host_ptr( args[1], length ), length );
			text[length] = 0;
			Com_Error( ERR_DROP, "%s", text );
		}
		return 0;
	}
	if ( number == floorTrap ) {
		return host_round( args[1], 0 );
	}
	if ( number == ceilTrap ) {
		return host_round( args[1], 1 );
	}
	switch ( number ) {
	case 100:	/* memset */
		memset( host_ptr( args[1], args[3] ), args[2], args[3] );
		return args[1];
	case 101:	/* memcpy */
		memmove( host_ptr( args[1], args[3] ), host_ptr( args[2], args[3] ), args[3] );
		return args[1];
	case 102: {	/* strncpy */
		byte *dest = host_ptr( args[1], args[3] );
		length = host_strlen( args[2] );
		for ( i = 0 ; i < args[3] ; i++ ) {
			dest[i] = i < length ? *host_ptr( args[2] + i, 1 ) : 0;
		}
		return args[1];
	}
	case 103:	/* sin */
	case 105:	/* atan2 */
		return 0;
	case 104:	/* cos */
		return 0x3F800000;
	case 106: {	/* sqrt */
		float value = bits_float( args[1] );
		if ( !( value >= 0.0f ) ) {
			return 0x7FC00000;
		}
		return float_bits( (float)sqrt( (double)value ) );
	}
	}
	if ( g_profile == PROFILE_TEST ) {
		switch ( number ) {
		case 200: {	/* enters the machine again */
			int nested[10];
			memset( nested, 0, sizeof( nested ) );
			nested[0] = args[1];
			nested[1] = args[2];
			nested[2] = args[3];
			return call_vm( currentVM, nested );
		}
		case 201: {	/* reads through VM_ArgPtr */
			void *p = VM_ArgPtr( args[1] );
			if ( !p ) {
				return -1;
			}
			host_ptr( args[1], 4 );
			return *(int *)p;
		}
		case 202:	/* writes */
			*(int *)host_ptr( args[1], 4 ) = args[2];
			return 0;
		case 203:
			return args[1];
		}
	}
	if ( g_profile == PROFILE_GAME && number == 37 ) {	/* G_GET_ENTITY_TOKEN */
		byte *dest;
		if ( g_entityToken >= 4 || args[2] <= 0 ) {
			return 0;
		}
		dest = host_ptr( args[1], args[2] );
		Q_strncpyz( (char *)dest, g_entityTokens[g_entityToken++], args[2] );
		return 1;
	}
	if ( g_profile == PROFILE_GAME && number == 19 ) {	/* G_GET_CONFIGSTRING: every string is empty */
		if ( args[3] > 0 ) {
			*host_ptr( args[2], 1 ) = 0;
		}
		return 0;
	}
	if ( g_profile == PROFILE_CGAME && number == 50 ) {	/* CG_GETGAMESTATE: only CS_GAME_VERSION */
		byte *state = host_ptr( args[1], 4 * 1024 + 16000 + 4 );
		memset( state, 0, 4 * 1024 + 16000 + 4 );
		*(int *)( state + 4 * 20 ) = 1;
		memcpy( state + 4 * 1024 + 1, "baseoa-1", 9 );
		*(int *)( state + 4 * 1024 + 16000 ) = 10;
		return 0;
	}
	return 0;
}

static int host_systemCall( int *args ) {
	int r, i;
	g_syscalls++;
	mix( &g_traceHash, args, 40 );
	if ( g_trace ) {
		printf( "S %d", args[0] );
		for ( i = 1 ; i < 10 ; i++ ) {
			printf( " %d", args[i] );
		}
		putchar( '\n' );
	}
	g_depth++;
	r = host_dispatch( args );
	g_depth--;
	mix( &g_traceHash, &r, 4 );
	if ( g_trace ) {
		printf( "= %d\n", r );
	}
	return r;
}

/* ---- the driver ---- */

static byte *read_whole( const char *path, int *length ) {
	FILE *f = fopen( path, "rb" );
	byte *data;
	if ( !f ) {
		return NULL;
	}
	fseek( f, 0, SEEK_END );
	*length = ftell( f );
	fseek( f, 0, SEEK_SET );
	data = malloc( *length + 1 );
	fread( data, 1, *length, f );
	fclose( f );
	return data;
}

static void set_file( int slot, const char *qpath, const char *path ) {
	free( g_files[slot].data );
	g_files[slot].data = NULL;
	if ( path ) {
		g_files[slot].data = read_whole( path, &g_files[slot].length );
		if ( !g_files[slot].data ) {
			fprintf( stderr, "cannot read %s\n", path );
			exit( 2 );
		}
		Q_strncpyz( g_files[slot].name, qpath, sizeof( g_files[slot].name ) );
	}
}

/* 0 = returned, 1 = Com_Error, 2 = trap */
static int guarded_call( vm_t *vm, int *args, int *result ) {
	if ( setjmp( g_errorJump ) ) {
		g_inCall = 0;
		return 1;
	}
	if ( __builtin_setjmp( g_trapJump ) ) {
		g_inCall = 0;
		return 2;
	}
	g_inCall = 1;
	*result = call_vm( vm, args );
	g_inCall = 0;
	return 0;
}

static void print_memory( vm_t *vm ) {
	uint64_t hash = FNV_OFFSET;
	const char *folder = getenv( "QVM_MEMDUMP" );
	static int serial;
	mix( &hash, vm->dataBase, vm->dataMask + 1 );
	if ( folder ) {	/* the data image, to compare it with the one the test writes with the same variable */
		char path[1024];
		FILE *f;
		snprintf( path, sizeof( path ), "%s/c_%d.bin", folder, serial++ );
		f = fopen( path, "wb" );
		if ( f ) {
			fwrite( vm->dataBase, 1, vm->dataMask + 1, f );
			fclose( f );
		}
	}
	printf( "M %016llx %d %016llx\n", (unsigned long long)hash, g_syscalls, (unsigned long long)g_traceHash );
}

static int profile_of( const char *name ) {
	if ( !strcmp( name, "game" ) ) return PROFILE_GAME;
	if ( !strcmp( name, "cgame" ) ) return PROFILE_CGAME;
	if ( !strcmp( name, "ui" ) ) return PROFILE_UI;
	return PROFILE_TEST;
}

static vm_t *create_vm( const char *module, const char *qvm, const char *map ) {
	char qpath[MAX_QPATH];
	VM_Clear();
	Hunk_Clear();
	currentVM = NULL;
	Com_sprintf( qpath, sizeof( qpath ), "vm/%s.qvm", module );
	set_file( 0, qpath, qvm );
	Com_sprintf( qpath, sizeof( qpath ), "vm/%s.map", module );
	set_file( 1, qpath, map );
	if ( setjmp( g_errorJump ) ) {
		print_escaped( "E ", (const byte *)g_errorText, (int)strlen( g_errorText ) );
		return NULL;
	}
	return VM_Create( module, host_systemCall, VMI_BYTECODE );
}

static void run_scenarios( const char *path ) {
	FILE *f = fopen( path, "r" );
	char line[4096], word[5][1024];
	vm_t *vm = NULL;
	int dead = 1, count, serial = 0;

	if ( !f ) {
		fprintf( stderr, "cannot read %s\n", path );
		exit( 2 );
	}
	while ( fgets( line, sizeof( line ), f ) ) {
		count = sscanf( line, "%1023s %1023s %1023s %1023s %1023s", word[0], word[1], word[2], word[3], word[4] );
		if ( count < 1 ) {
			continue;
		}
		if ( !strcmp( word[0], "scenario" ) && count == 5 ) {
			char module[MAX_QPATH];
			printf( "scenario %s\n", word[1] );
			g_profile = profile_of( word[2] );
			g_trace = 1;
			g_syscalls = 0;
			g_traceHash = FNV_OFFSET;
			g_entityToken = 0;
			g_depth = 0;
			Com_sprintf( module, sizeof( module ), "m%d", serial++ );
			vm = create_vm( module, word[3], strcmp( word[4], "-" ) ? word[4] : NULL );
			dead = vm == NULL;
		} else if ( !strcmp( word[0], "trace" ) ) {
			g_trace = !strcmp( word[1], "on" );
		} else if ( !strcmp( word[0], "end" ) ) {
			printf( "end\n" );
			dead = 1;
		} else if ( !strcmp( word[0], "note" ) ) {
			printf( "%s", line );
		} else if ( dead ) {
			continue;
		} else if ( !strcmp( word[0], "call" ) ) {
			int args[10], n = 0, result = 0, outcome;
			char *p = strstr( line, "call" ) + 4;
			memset( args, 0, sizeof( args ) );
			while ( n < 10 ) {
				char *endp;
				long value = strtol( p, &endp, 10 );
				if ( endp == p ) break;
				args[n++] = (int)value;
				p = endp;
			}
			outcome = guarded_call( vm, args, &result );
			if ( outcome == 0 ) {
				printf( "R %d\n", result );
			} else if ( outcome == 1 ) {
				print_escaped( "E ", (const byte *)g_errorText, (int)strlen( g_errorText ) );
				dead = 1;
			} else {
				printf( "T %08X\n", g_trapCode );
				dead = 1;
			}
			if ( dead ) {
				print_memory( vm );
			}
			if ( dead ) {
				currentVM = NULL;
			}
		} else if ( !strcmp( word[0], "restart" ) ) {
			if ( setjmp( g_errorJump ) ) {
				print_escaped( "E ", (const byte *)g_errorText, (int)strlen( g_errorText ) );
				dead = 1;
			} else {
				vm = VM_Restart( vm );
				printf( "restarted\n" );
			}
		} else if ( !strcmp( word[0], "mem" ) ) {
			print_memory( vm );
		} else if ( !strcmp( word[0], "info" ) ) {
			printf( "I %d %d %d %d %d %d\n", vm->codeLength, vm->instructionPointersLength, vm->dataMask + 1,
				vm->programStack, vm->stackBottom, vm->numSymbols );
		} else if ( !strcmp( word[0], "symbols" ) ) {
			int value;
			for ( value = -1 ; value <= vm->codeLength ; value++ ) {
				printf( "Y %d %s\n", value, VM_ValueToSymbol( vm, value ) );
			}
		} else if ( !strcmp( word[0], "symval" ) && count >= 2 ) {
			printf( "V %s %d\n", word[1], VM_SymbolToValue( vm, word[1] ) );
		}
	}
	fclose( f );
}

static void run_bench( char **argv ) {
	vm_t *vm;
	int args[10], result = 0, repetitions = atoi( argv[6] ), i;
	LARGE_INTEGER frequency, start, stop;

	g_profile = profile_of( argv[3] );
	g_trace = 0;
	g_traceHash = FNV_OFFSET;
	vm = create_vm( "bench", argv[2], NULL );
	if ( !vm ) {
		exit( 2 );
	}
	memset( args, 0, sizeof( args ) );
	args[0] = atoi( argv[4] );
	args[1] = atoi( argv[5] );
	QueryPerformanceFrequency( &frequency );
	QueryPerformanceCounter( &start );
	for ( i = 0 ; i < repetitions ; i++ ) {
		if ( guarded_call( vm, args, &result ) ) {
			printf( "failed: %s\n", g_errorText );
			exit( 3 );
		}
	}
	QueryPerformanceCounter( &stop );
	printf( "result %d seconds %.6f\n", result, (double)( stop.QuadPart - start.QuadPart ) / (double)frequency.QuadPart );
}

int main( int argc, char **argv ) {
	AddVectoredExceptionHandler( 1, trap_handler );
	setvbuf( stdout, NULL, _IOFBF, 1 << 16 );
	if ( argc == 3 && !strcmp( argv[1], "run" ) ) {
		run_scenarios( argv[2] );
		return 0;
	}
	if ( argc == 7 && !strcmp( argv[1], "bench" ) ) {
		run_bench( argv );
		return 0;
	}
	fprintf( stderr, "qvmrun run <scenarios.txt> | qvmrun bench <file.qvm> <profile> <command> <argument> <repetitions>\n" );
	return 1;
}
