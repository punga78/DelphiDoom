/* Stub of code/game/botlib.h for the parity tool of the bot AI: the print levels, the error codes, bot_input_t,
   bsp_trace_t, bot_entitystate_t and botimport (the structures are copied from the real header) */
#ifndef STUB_BOTLIB_H
#define STUB_BOTLIB_H

#define BOTLIB_API_VERSION 2
#define BLERR_NOERROR 0
#define BLERR_LIBRARYNOTSETUP 1
#define BLERR_INVALIDENTITYNUMBER 2
#define BLERR_NOAASFILE 3
#define BLERR_CANNOTOPENAASFILE 4
#define BLERR_WRONGAASFILEID 5
#define BLERR_WRONGAASFILEVERSION 6
#define BLERR_CANNOTREADAASLUMP 7
#define BLERR_CANNOTLOADICHAT 8
#define BLERR_CANNOTLOADITEMWEIGHTS 9
#define BLERR_CANNOTLOADITEMCONFIG 10
#define BLERR_CANNOTLOADWEAPONWEIGHTS 11
#define BLERR_CANNOTLOADWEAPONCONFIG 12

#define PRT_MESSAGE 1
#define PRT_WARNING 2
#define PRT_ERROR 3
#define PRT_FATAL 4
#define PRT_EXIT 5

#define FS_SEEK_SET 0

#define ACTION_ATTACK			0x0000001
#define ACTION_USE				0x0000002
#define ACTION_RESPAWN			0x0000008
#define ACTION_JUMP				0x0000010
#define ACTION_MOVEUP			0x0000020
#define ACTION_CROUCH			0x0000080
#define ACTION_MOVEDOWN			0x0000100
#define ACTION_MOVEFORWARD		0x0000200
#define ACTION_MOVEBACK			0x0000800
#define ACTION_MOVELEFT			0x0001000
#define ACTION_MOVERIGHT		0x0002000
#define ACTION_DELAYEDJUMP		0x0008000
#define ACTION_TALK				0x0010000
#define ACTION_GESTURE			0x0020000
#define ACTION_WALK				0x0080000
#define ACTION_AFFIRMATIVE		0x0100000
#define ACTION_NEGATIVE			0x0200000
#define ACTION_GETFLAG			0x0800000
#define ACTION_GUARDBASE		0x1000000
#define ACTION_PATROL			0x2000000
#define ACTION_FOLLOWME			0x8000000

typedef int fileHandle_t;
typedef enum { FS_READ, FS_WRITE, FS_APPEND, FS_APPEND_SYNC } fsMode_t;

typedef struct bot_input_s
{
	float thinktime;		//time since last output (in seconds)
	vec3_t dir;				//movement direction
	float speed;			//speed in the range [0, 400]
	vec3_t viewangles;		//the view angles
	int actionflags;		//one of the ACTION_? flags
	int weapon;				//weapon to use
} bot_input_t;

typedef struct bsp_surface_s
{
	char name[16];
	int flags;
	int value;
} bsp_surface_t;

typedef struct bsp_trace_s
{
	qboolean		allsolid;
	qboolean		startsolid;
	float			fraction;
	vec3_t			endpos;
	cplane_t		plane;
	float			exp_dist;
	int				sidenum;
	bsp_surface_t	surface;
	int				contents;
	int				ent;
} bsp_trace_t;

typedef struct bot_entitystate_s
{
	int		type;
	int		flags;
	vec3_t	origin;
	vec3_t	angles;
	vec3_t	old_origin;
	vec3_t	mins;
	vec3_t	maxs;
	int		groundent;
	int		solid;
	int		modelindex;
	int		modelindex2;
	int		frame;
	int		event;
	int		eventParm;
	int		powerups;
	int		weapon;
	int		legsAnim;
	int		torsoAnim;
} bot_entitystate_t;

typedef struct botlib_import_s
{
	void (*Print)(int type, char *fmt, ...);
	void (*Trace)(bsp_trace_t *trace, vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end, int passent, int contentmask);
	void (*EntityTrace)(bsp_trace_t *trace, vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end, int entnum, int contentmask);
	int (*PointContents)(vec3_t point);
	int (*inPVS)(vec3_t p1, vec3_t p2);
	char *(*BSPEntityData)(void);
	void (*BSPModelMinsMaxsOrigin)(int modelnum, vec3_t angles, vec3_t mins, vec3_t maxs, vec3_t origin);
	void (*BotClientCommand)(int client, char *command);
	int (*FS_FOpenFile)(const char *qpath, fileHandle_t *file, fsMode_t mode);
	int (*FS_Read)(void *buffer, int len, fileHandle_t f);
	int (*FS_Write)(const void *buffer, int len, fileHandle_t f);
	void (*FS_FCloseFile)(fileHandle_t f);
	int (*FS_Seek)(fileHandle_t f, long offset, int origin);
} botlib_import_t;

#endif
