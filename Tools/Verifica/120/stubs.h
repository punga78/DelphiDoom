/*
 * Minimal stubs for the virtual machine of Quake III Arena (code/qcommon/vm.c,
 * vm_interpreted.c, vm_local.h), whose text is included by qvmrun.c as it is (see
 * build.sh). Issue #120. The stubs replace the engine: the types of q_shared.h and
 * qcommon.h the VM uses, the hunk, the file system (files in memory), the cvars, the
 * console and Com_Error (a longjmp back to the driver); nothing of the VM is changed.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>
#include <setjmp.h>

typedef unsigned char byte;
typedef int qboolean;
#define qfalse 0
#define qtrue 1

#define QDECL
#define MAX_QPATH 64
#define MAX_TOKEN_CHARS 1024
#define MAX_STRING_CHARS 1024
#define ERR_FATAL 0
#define ERR_DROP 1
#define CVAR_ARCHIVE 1
#define LittleLong(x) (x)
#define Com_Memset memset
#define Com_Memcpy memcpy

/* qfiles.h: VM_MAGIC can be given on the command line (0x12721445 is the VM_MAGIC_VER2 of
   ioquake3, the one of the files of OpenArena: same header plus the length of the jump table) */
#ifndef VM_MAGIC
#define VM_MAGIC 0x12721444
#endif
typedef struct {
	int		vmMagic;
	int		instructionCount;
	int		codeOffset;
	int		codeLength;
	int		dataOffset;
	int		dataLength;
	int		litLength;
	int		bssLength;
} vmHeader_t;

/* qcommon.h */
typedef struct vm_s vm_t;
typedef enum { VMI_NATIVE, VMI_BYTECODE, VMI_COMPILED } vmInterpret_t;
typedef enum { h_high, h_low, h_dontcare } ha_pref;
typedef struct { float value; int integer; } cvar_t;

vm_t *VM_Create( const char *module, int (*systemCalls)(int *), vmInterpret_t interpret );
void VM_Free( vm_t *vm );
void VM_Clear(void);
vm_t *VM_Restart( vm_t *vm );
int QDECL VM_Call( vm_t *vm, int callNum, ... );
void VM_Debug( int level );
void *VM_ArgPtr( int intValue );
void *VM_ExplicitArgPtr( vm_t *vm, int intValue );

/* q_shared.c (the originals are in vm_original.inc) */
char *COM_Parse( char **data_p );
char *COM_ParseExt( char **data_p, qboolean allowLineBreaks );
void Q_strncpyz( char *dest, const char *src, int destsize );
int Q_stricmp (const char *s1, const char *s2);
int Q_stricmpn (const char *s1, const char *s2, int n);
void QDECL Com_sprintf( char *dest, int size, const char *fmt, ...);
void COM_StripExtension( const char *in, char *out );

/* the engine */
static jmp_buf g_errorJump;
static char g_errorText[4096];
static void QDECL Com_Error( int level, const char *fmt, ... ) {
	va_list ap;
	va_start( ap, fmt );
	vsnprintf( g_errorText, sizeof( g_errorText ), fmt, ap );
	va_end( ap );
	longjmp( g_errorJump, 1 );
}
#define Com_Printf(...) ((void)0)
#define Com_DPrintf(...) ((void)0)

static cvar_t g_developer = { 1.0f, 1 };
static cvar_t *com_developer = &g_developer;
static cvar_t *Cvar_Get( const char *name, const char *value, int flags ) { return &g_developer; }
static float Cvar_VariableValue( const char *name ) { return 0; }
static void Cmd_AddCommand( const char *name, void (*function)(void) ) {}

/* the hunk: zero filled, never freed while a scenario runs; the 256 bytes more are what
   the original reads past the end of the image (OP_LOAD4 at the last bytes, the arguments
   of a system call at the top of the stack), so that they are zero and not what follows */
#define MAX_HUNK_BLOCKS 256
static void *g_hunk[MAX_HUNK_BLOCKS];
static int g_hunkCount;
static void *Hunk_Alloc( int size, ha_pref preference ) {
	void *block = calloc( 1, (size_t)size + 256 );
	if ( g_hunkCount < MAX_HUNK_BLOCKS ) {
		g_hunk[g_hunkCount++] = block;
	}
	return block;
}
static void Hunk_Clear( void ) {
	while ( g_hunkCount > 0 ) {
		free( g_hunk[--g_hunkCount] );
	}
}
static int Hunk_MemoryRemaining( void ) { return 0; }
static void *Z_Malloc( int size ) { return calloc( 1, size ); }
static void Z_Free( void *block ) { free( block ); }

/* the file system: two files in memory, the image and the symbols */
static struct { char name[MAX_QPATH]; byte *data; int length; } g_files[2];
static int FS_ReadFile( const char *qpath, void **buffer ) {
	int i;
	for ( i = 0 ; i < 2 ; i++ ) {
		if ( g_files[i].data && !strcmp( g_files[i].name, qpath ) ) {
			byte *copy = malloc( g_files[i].length + 1 );
			memcpy( copy, g_files[i].data, g_files[i].length );
			copy[g_files[i].length] = 0;
			*buffer = copy;
			return g_files[i].length;
		}
	}
	*buffer = NULL;
	return -1;
}
static void FS_FreeFile( void *buffer ) { free( buffer ); }

/* no DLLs and no compiler */
static void *Sys_LoadDll( const char *name, char *fqpath, int (QDECL **entryPoint)(int, ...),
	int (QDECL *systemcalls)(int, ...) ) { return NULL; }
static void Sys_UnloadDll( void *dllHandle ) {}
