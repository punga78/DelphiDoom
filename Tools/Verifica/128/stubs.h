/*
 * Minimal stubs for the sound system of Quake III Arena (code/client/snd_dma.c,
 * snd_mix.c, snd_mem.c), whose functions are included by q3snd.c with the text of the
 * original (see build.sh). Issue #128. The stubs replace the engine: the types and
 * globals of snd_local.h and snd_dma.c, the vector macros of q_shared.h, the clock, the
 * cvars and the DMA device; nothing of the sound code is changed.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>

typedef unsigned char byte;
typedef int qboolean;
#define qfalse 0
#define qtrue 1
typedef float vec_t;
typedef vec_t vec3_t[3];
typedef int sfxHandle_t;
typedef int fileHandle_t;

#define MAX_QPATH 64
#define ID_INLINE inline
#define MAX_GENTITIES 1024
#define ERR_FATAL 0
#define ERR_DROP 1
#define S_COLOR_YELLOW "^3"

enum { CHAN_AUTO, CHAN_LOCAL, CHAN_WEAPON, CHAN_VOICE, CHAN_ITEM, CHAN_BODY, CHAN_LOCAL_SOUND, CHAN_ANNOUNCER };

#define DotProduct(x,y)			((x)[0]*(y)[0]+(x)[1]*(y)[1]+(x)[2]*(y)[2])
#define VectorSubtract(a,b,c)	((c)[0]=(a)[0]-(b)[0],(c)[1]=(a)[1]-(b)[1],(c)[2]=(a)[2]-(b)[2])
#define VectorAdd(a,b,c)		((c)[0]=(a)[0]+(b)[0],(c)[1]=(a)[1]+(b)[1],(c)[2]=(a)[2]+(b)[2])
#define VectorCopy(a,b)			((b)[0]=(a)[0],(b)[1]=(a)[1],(b)[2]=(a)[2])

#define LittleShort(x) (x)
#define LittleLong(x) (x)

/* snd_local.h */
#define	PAINTBUFFER_SIZE		4096
#define SND_CHUNK_SIZE			1024
#define SND_CHUNK_SIZE_FLOAT	(SND_CHUNK_SIZE/2)
#define SND_CHUNK_SIZE_BYTE		(SND_CHUNK_SIZE*2)
#define	MAX_CHANNELS			96
#define	MAX_RAW_SAMPLES			16384
#define START_SAMPLE_IMMEDIATE	0x7fffffff

typedef struct { int left; int right; } portable_samplepair_t;
typedef struct adpcm_state { short sample; char index; } adpcm_state_t;
typedef	struct sndBuffer_s {
	short					sndChunk[SND_CHUNK_SIZE];
	struct sndBuffer_s		*next;
	int						size;
	adpcm_state_t			adpcm;
} sndBuffer;
typedef struct sfx_s {
	sndBuffer		*soundData;
	qboolean		defaultSound;
	qboolean		inMemory;
	qboolean		soundCompressed;
	int				soundCompressionMethod;
	int 			soundLength;
	char 			soundName[MAX_QPATH];
	int				lastTimeUsed;
	struct sfx_s	*next;
} sfx_t;
typedef struct {
	int			channels;
	int			samples;
	int			submission_chunk;
	int			samplebits;
	int			speed;
	byte		*buffer;
} dma_t;
typedef struct loopSound_s {
	vec3_t		origin;
	vec3_t		velocity;
	sfx_t		*sfx;
	int			mergeFrame;
	qboolean	active;
	qboolean	kill;
	qboolean	doppler;
	float		dopplerScale;
	float		oldDopplerScale;
	int			framenum;
} loopSound_t;
typedef struct {
	int			allocTime;
	int			startSample;
	int			entnum;
	int			entchannel;
	int			leftvol;
	int			rightvol;
	int			master_vol;
	float		dopplerScale;
	float		oldDopplerScale;
	vec3_t		origin;
	qboolean	fixed_origin;
	sfx_t		*thesfx;
	qboolean	doppler;
} channel_t;

typedef struct { float value; int integer; } cvar_t;

/* snd_dma.c constants and globals */
#define		SOUND_FULLVOLUME	80
#define		SOUND_ATTENUATE		0.0008f
channel_t   s_channels[MAX_CHANNELS];
channel_t   loop_channels[MAX_CHANNELS];
int			numLoopChannels;
static int	s_soundStarted;
static		qboolean	s_soundMuted;
dma_t		dma;
static int			listener_number;
static vec3_t		listener_origin;
static vec3_t		listener_axis[3];
int			s_soundtime;
int   		s_paintedtime;
#define		MAX_SFX			4096
sfx_t		s_knownSfx[MAX_SFX];
int			s_numSfx = 0;
cvar_t		*s_volume, *s_testsound, *s_khz, *s_show, *s_mixahead, *s_mixPreStep, *s_separation, *s_doppler;
static loopSound_t		loopSounds[MAX_GENTITIES];
static	channel_t		*freelist = NULL;
int						s_rawend;
portable_samplepair_t	s_rawsamples[MAX_RAW_SAMPLES];

/* snd_mix.c globals */
static portable_samplepair_t paintbuffer[PAINTBUFFER_SIZE];
static int snd_vol;
int*     snd_p;
int      snd_linear_count;
short*   snd_out;

/* the engine */
static int g_ms;
static int g_dmapos;
static struct { int framecount; } cls;
static int Com_Milliseconds(void) { return g_ms; }
#define Com_Printf(...) ((void)0)
#define Com_DPrintf(...) ((void)0)
#define Com_Memset memset
#define Snd_Memset memset
static void Com_Error(int level, const char *fmt, ...) { fprintf(stderr, "Com_Error %d: %s\n", level, fmt); exit(3); }
static void SNDDMA_BeginPainting(void) {}
static void SNDDMA_Submit(void) {}
static int SNDDMA_GetDMAPos(void) { return g_dmapos; }
static void S_memoryLoad(sfx_t *sfx) { sfx->inMemory = qtrue; }
static void S_StopBackgroundTrack(void) {}
static void S_UpdateBackgroundTrack(void) {}
static sndBuffer *SND_malloc(void) { sndBuffer *v = calloc(1, sizeof(sndBuffer)); return v; }
static void S_PaintChannelFromADPCM(channel_t *ch, sfx_t *sc, int count, int sampleOffset, int bufferOffset) {}
static void S_PaintChannelFromWavelet(channel_t *ch, sfx_t *sc, int count, int sampleOffset, int bufferOffset) {}
static void S_PaintChannelFromMuLaw(channel_t *ch, sfx_t *sc, int count, int sampleOffset, int bufferOffset) {}
