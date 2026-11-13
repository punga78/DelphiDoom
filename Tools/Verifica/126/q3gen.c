/* Parity driver of the issue #126: runs the original functions of Quake III and writes one line per case.
   Usage: q3gen <folder with the .cfg files> <tags.md3> [mkmd3]
   Every float is written as #bits (hexadecimal), every int in decimal. */
#include "stubs.h"
#include "types_original.inc"

/* ---------------- the state of the game that the functions read ---------------- */
typedef struct {
	int clientNum;
	int powerups;
	int legsAnim, torsoAnim;
	int eFlags;
	vec3_t angles2;
	struct { vec3_t trDelta; } pos;
} stubEntityState_t;
typedef struct {
	stubEntityState_t currentState;
	playerEntity_t pe;
	vec3_t lerpAngles;
} centity_t;
typedef struct {
	animation_t animations[MAX_TOTALANIMATIONS];
	footstep_t footsteps;
	vec3_t headOffset;
	gender_t gender;
	qboolean fixedlegs;
	qboolean fixedtorso;
} clientInfo_t;
typedef struct { clientInfo_t clientinfo[MAX_CLIENTS]; } cgs_t;
typedef struct { int time; int frametime; } cg_t;
typedef struct { vec3_t origin; vec3_t axis[3]; int oldframe; int frame; float backlerp; } refEntity_t;
typedef struct { md3Header_t *md3[1]; } model_t;

vec3_t vec3_origin = { 0, 0, 0 };
static cgs_t cgs;
static cg_t cg;
/* the cvars as the game registers them: cg_animSpeed 1, cg_debugAnim 0, cg_noPlayerAnims 0, cg_swingSpeed 0.3 */
static vmCvar_t cg_animSpeed, cg_debugAnim, cg_noPlayerAnims, cg_swingSpeed;

static char g_folder[512];
static char g_msgs[64][512];
static int g_msgCount;
static jmp_buf g_jump;
static char g_error[512];
static model_t g_model;

void Com_Printf(const char *fmt, ...) {
	va_list ap;
	char *p;
	va_start(ap, fmt);
	vsnprintf(g_msgs[g_msgCount < 63 ? g_msgCount : 63], 512, fmt, ap);
	va_end(ap);
	p = g_msgs[g_msgCount < 63 ? g_msgCount : 63];
	if (strlen(p) && p[strlen(p) - 1] == '\n') p[strlen(p) - 1] = 0;
	g_msgCount++;
}
void Com_Error(int level, const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(g_error, sizeof(g_error), fmt, ap);
	va_end(ap);
	longjmp(g_jump, 1);
}
#define CG_Printf Com_Printf
static void CG_Error(const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(g_error, sizeof(g_error), fmt, ap);
	va_end(ap);
	longjmp(g_jump, 1);
}

/* the file system: files of the folder */
static FILE *g_file;
static int trap_FS_FOpenFile(const char *qpath, fileHandle_t *f, int mode) {
	char path[1024];
	long len;
	snprintf(path, sizeof(path), "%s/%s", g_folder, qpath);
	g_file = fopen(path, "rb");
	if (!g_file) { *f = 0; return -1; }
	fseek(g_file, 0, SEEK_END);
	len = ftell(g_file);
	fseek(g_file, 0, SEEK_SET);
	*f = 1;
	return (int)len;
}
static void trap_FS_Read(void *buffer, int len, fileHandle_t f) { fread(buffer, 1, len, g_file); }
static void trap_FS_FCloseFile(fileHandle_t f) { fclose(g_file); }

/* the renderer: the handle is the one model of the driver */
static model_t *R_GetModelByHandle(qhandle_t h) { return &g_model; }
#define trap_R_LerpTag R_LerpTag

#include "math_original.inc"
#include "model_original.inc"
#include "ents_original.inc"
#include "players_original.inc"

/* ---------------- the driver ---------------- */
static unsigned g_rs;
static unsigned rnd(void) { g_rs = g_rs * 1664525u + 1013904223u; return g_rs >> 8; }
static float rndf(float range) { return ((int)(rnd() % 20001) - 10000) / 10000.0f * range; }

static void PF(float v) { unsigned u; memcpy(&u, &v, 4); printf(" #%08x", u); }
static void PV(const float *v, int n) { int i; for (i = 0; i < n; i++) PF(v[i]); }
static void PI(int v) { printf(" %d", v); }

static const char *g_names[] = { "full.cfg", "headeropts.cfg", "noheader.cfg", "noflags.cfg", "short.cfg", "toofew.cfg", "nofile.cfg" };
#define NUM_CFG 7

static void DumpCfg(const char *name, const clientInfo_t *ci, int ok) {
	int i;
	printf("cfg %s |", name);
	if (!ok) {
		printf(" fail\n");
	} else {
		printf(" ok");
		PI(ci->footsteps); PI(ci->gender); PI(ci->fixedlegs); PI(ci->fixedtorso);
		PV(ci->headOffset, 3);
		printf("\n");
		for (i = 0; i < MAX_TOTALANIMATIONS; i++) {
			const animation_t *a = &ci->animations[i];
			printf("anim %s %d |", name, i);
			PI(a->firstFrame); PI(a->numFrames); PI(a->loopFrames); PI(a->frameLerp); PI(a->initialLerp);
			PI(a->reversed); PI(a->flipflop);
			printf("\n");
		}
	}
	for (i = 0; i < g_msgCount && i < 64; i++)
		printf("cfgmsg %s %d | %s\n", name, i, g_msgs[i]);
}

static void DumpLerp(const lerpFrame_t *lf) {
	PI(lf->animationNumber); PI(lf->frameTime); PI(lf->oldFrameTime); PI(lf->animationTime);
	PI(lf->frame); PI(lf->oldFrame); PF(lf->backlerp);
}

static int AnimWithToggle(void) {
	int a = (int)(rnd() % MAX_TOTALANIMATIONS);
	if (rnd() % 4 == 0) a |= ANIM_TOGGLEBIT;
	return a;
}

static void Timeline(const char *cfgName, int steps, unsigned seed, int badAnimAtEnd, int badDirAtEnd) {
	static centity_t cent;
	clientInfo_t *ci = &cgs.clientinfo[0];
	int i, legsAnim, torsoAnim, t, dt;
	int legsOld, legs, torsoOld, torso;
	float legsBack, torsoBack;
	vec3_t la, ta, ha;

	memset(ci, 0, sizeof(*ci));
	g_msgCount = 0;
	{
		char path[256];
		snprintf(path, sizeof(path), "%s", cfgName);
		if (!CG_ParseAnimationFile(path, ci)) { printf("timeline %s | cfgfail\n", cfgName); return; }
	}
	g_rs = seed;
	memset(&cent, 0, sizeof(cent));
	t = 1000;
	cg.time = t;
	legsAnim = LEGS_IDLE; torsoAnim = TORSO_STAND;
	/* CG_ResetPlayerEntity: clear the frames and start the angles at the view */
	CG_ClearLerpFrame(ci, &cent.pe.legs, legsAnim);
	CG_ClearLerpFrame(ci, &cent.pe.torso, torsoAnim);
	cent.lerpAngles[YAW] = 90;
	cent.pe.torso.yawAngle = cent.lerpAngles[YAW];
	cent.pe.legs.yawAngle = cent.lerpAngles[YAW];
	printf("timeline %s %u |", cfgName, seed);
	DumpLerp(&cent.pe.legs); DumpLerp(&cent.pe.torso);
	printf("\n");
	for (i = 0; i < steps + (badAnimAtEnd || badDirAtEnd); i++) {
		int haste = rnd() % 4 == 0;
		int dead, pain, painDir;
		float a2;
		dt = (int)(rnd() % 100);
		if (rnd() % 30 == 0) dt = 400 + (int)(rnd() % 400);	/* a long pause */
		t += dt;
		cg.time = t;
		cg.frametime = dt;
		if (rnd() % 6 == 0) legsAnim = AnimWithToggle();
		if (rnd() % 6 == 0) torsoAnim = AnimWithToggle();
		if (rnd() % 12 == 0) { legsAnim = LEGS_IDLE; torsoAnim = TORSO_STAND; }
		dead = rnd() % 15 == 0;
		a2 = (float)(rnd() % 8);
		cent.currentState.legsAnim = legsAnim;
		cent.currentState.torsoAnim = torsoAnim;
		cent.currentState.powerups = haste ? (1 << PW_HASTE) : 0;
		cent.currentState.eFlags = dead ? EF_DEAD : 0;
		cent.currentState.angles2[YAW] = a2;
		/* the view turns by steps and the player moves */
		if (rnd() % 4 == 0) cent.lerpAngles[YAW] = rndf(400);
		else cent.lerpAngles[YAW] += rndf(10);
		cent.lerpAngles[PITCH] = rndf(100);
		cent.lerpAngles[ROLL] = rnd() % 5 == 0 ? rndf(30) : 0;
		if (rnd() % 3 == 0) { cent.currentState.pos.trDelta[0] = cent.currentState.pos.trDelta[1] = cent.currentState.pos.trDelta[2] = 0; }
		else { cent.currentState.pos.trDelta[0] = rndf(320); cent.currentState.pos.trDelta[1] = rndf(320); cent.currentState.pos.trDelta[2] = rndf(100); }
		pain = rnd() % 5 == 0 ? t - (int)(rnd() % 300) : 0;
		painDir = (int)(rnd() % 2);
		cent.pe.painTime = pain;
		cent.pe.painDirection = painDir;
		if (i >= steps) {
			if (badAnimAtEnd) cent.currentState.legsAnim = 99;
			if (badDirAtEnd) { cent.currentState.angles2[YAW] = 9; cent.currentState.eFlags = 0; }
		}
		printf("step %d %d %d %d %d", t, dt, cent.currentState.legsAnim, cent.currentState.torsoAnim, cent.currentState.powerups);
		PI(cent.currentState.eFlags); PF(cent.currentState.angles2[YAW]);
		PV(cent.lerpAngles, 3); PV(cent.currentState.pos.trDelta, 3); PI(cent.pe.painTime); PI(cent.pe.painDirection);
		/* state of the swings before the call: it is an input too */
		PF(cent.pe.torso.yawAngle); PI(cent.pe.torso.yawing); PF(cent.pe.torso.pitchAngle); PI(cent.pe.torso.pitching);
		PF(cent.pe.legs.yawAngle); PI(cent.pe.legs.yawing);
		printf(" |");
		if (setjmp(g_jump)) { printf(" error %s\n", g_error); return; }
		{
			vec3_t laxis[3], taxis[3], haxis[3];
			CG_PlayerAngles(&cent, laxis, taxis, haxis);
			CG_PlayerAnimation(&cent, &legsOld, &legs, &legsBack, &torsoOld, &torso, &torsoBack);
			PV(laxis[0], 3); PV(laxis[1], 3); PV(laxis[2], 3);
			PV(taxis[0], 3); PV(taxis[1], 3); PV(taxis[2], 3);
			PV(haxis[0], 3); PV(haxis[1], 3); PV(haxis[2], 3);
		}
		PI(legsOld); PI(legs); PF(legsBack); PI(torsoOld); PI(torso); PF(torsoBack);
		PF(cent.pe.torso.yawAngle); PI(cent.pe.torso.yawing); PF(cent.pe.torso.pitchAngle); PI(cent.pe.torso.pitching);
		PF(cent.pe.legs.yawAngle); PI(cent.pe.legs.yawing);
		DumpLerp(&cent.pe.legs); DumpLerp(&cent.pe.torso);
		printf("\n");
	}
}

/* tags.md3: a model with 6 frames and 4 tags, no surfaces; the tags are drifting rotations with noise so that the axes are not unit vectors */
static void MakeMd3(const char *path) {
	enum { FRAMES = 6, TAGS = 4 };
	static const char *names[TAGS] = { "tag_torso", "tag_head", "tag_weapon", "tag_flag" };
	unsigned char buf[108 + FRAMES * 56 + FRAMES * TAGS * 112];
	md3Header_t *h = (md3Header_t *)buf;
	md3Frame_t *fr = (md3Frame_t *)(buf + 108);
	md3Tag_t *tg = (md3Tag_t *)(buf + 108 + FRAMES * 56);
	int f, t, i;
	FILE *out;
	memset(buf, 0, sizeof(buf));
	h->ident = ('3' << 24) + ('P' << 16) + ('D' << 8) + 'I';
	h->version = 15;
	strcpy(h->name, "models/test/tags.md3");
	h->numFrames = FRAMES; h->numTags = TAGS; h->numSurfaces = 0; h->numSkins = 0;
	h->ofsFrames = 108; h->ofsTags = 108 + FRAMES * 56; h->ofsSurfaces = sizeof(buf); h->ofsEnd = sizeof(buf);
	g_rs = 12345;
	for (f = 0; f < FRAMES; f++) {
		for (i = 0; i < 3; i++) { fr[f].bounds[0][i] = -10; fr[f].bounds[1][i] = 10; fr[f].localOrigin[i] = 0; }
		fr[f].radius = 17.5f;
		sprintf(fr[f].name, "frame%d", f);
		for (t = 0; t < TAGS; t++) {
			md3Tag_t *tag = &tg[f * TAGS + t];
			strcpy(tag->name, names[t]);
			for (i = 0; i < 3; i++) tag->origin[i] = rndf(24);
			/* a rotation about z by a random angle, plus noise, and a scale: not orthonormal on purpose */
			{
				float a = rndf(3.14159f), s = 0.8f + (rnd() % 100) / 250.0f, c;
				c = cosf(a); a = sinf(a);
				tag->axis[0][0] = c * s; tag->axis[0][1] = a * s; tag->axis[0][2] = rndf(0.2f);
				tag->axis[1][0] = -a * s; tag->axis[1][1] = c * s; tag->axis[1][2] = rndf(0.2f);
				tag->axis[2][0] = rndf(0.2f); tag->axis[2][1] = rndf(0.2f); tag->axis[2][2] = s;
			}
		}
	}
	out = fopen(path, "wb");
	fwrite(buf, 1, sizeof(buf), out);
	fclose(out);
}

static void LoadMd3(const char *path) {
	FILE *f = fopen(path, "rb");
	long len;
	if (!f) { fprintf(stderr, "no %s\n", path); exit(1); }
	fseek(f, 0, SEEK_END); len = ftell(f); fseek(f, 0, SEEK_SET);
	g_model.md3[0] = (md3Header_t *)malloc(len);
	fread(g_model.md3[0], 1, len, f);
	fclose(f);
}

static void Tags(void) {
	static const char *tagNames[] = { "tag_torso", "tag_head", "tag_weapon", "tag_flag", "tag_missing", "TAG_TORSO" };
	int n;
	g_rs = 777;
	for (n = 0; n < 100; n++) {
		orientation_t o;
		const char *name = tagNames[rnd() % 6];
		int s = (int)(rnd() % 8) - 0, e = (int)(rnd() % 8);	/* frames 6 and 7 do not exist: clamped to 5 */
		float frac = (n % 7 == 0) ? 0.0f : (n % 11 == 0) ? 1.0f : (rnd() % 1001) / 1000.0f;
		int ok = R_LerpTag(&o, 0, s, e, frac, name);
		printf("tag %s %d %d", name, s, e); PF(frac);
		printf(" | %d", ok); PV(o.origin, 3); PV(o.axis[0], 3); PV(o.axis[1], 3); PV(o.axis[2], 3);
		printf("\n");
	}
	for (n = 0; n < 100; n++) {
		refEntity_t parent, entity;
		const char *name = tagNames[rnd() % 4 + (n % 25 == 0 ? 2 : 0) % 3];
		int rotated = n & 1;
		float pa[3];
		vec3_t ang;
		memset(&parent, 0, sizeof(parent));
		memset(&entity, 0, sizeof(entity));
		ang[0] = rndf(180); ang[1] = rndf(180); ang[2] = rndf(180);
		AnglesToAxis(ang, parent.axis);
		parent.origin[0] = rndf(100); parent.origin[1] = rndf(100); parent.origin[2] = rndf(100);
		parent.oldframe = (int)(rnd() % 7); parent.frame = (int)(rnd() % 7);
		parent.backlerp = (n % 9 == 0) ? 0.0f : (rnd() % 1001) / 1000.0f;
		if (rotated) { ang[0] = rndf(180); ang[1] = rndf(180); ang[2] = rndf(180); AnglesToAxis(ang, entity.axis); }
		entity.backlerp = 0.375f;
		(void)pa;
		printf("pos %d %d %d", rotated, parent.oldframe, parent.frame); PF(parent.backlerp);
		printf(" %s", name); PV(parent.origin, 3); PV(parent.axis[0], 3); PV(parent.axis[1], 3); PV(parent.axis[2], 3);
		PV(entity.axis[0], 3); PV(entity.axis[1], 3); PV(entity.axis[2], 3);
		if (rotated) CG_PositionRotatedEntityOnTag(&entity, &parent, 0, (char *)name);
		else CG_PositionEntityOnTag(&entity, &parent, 0, (char *)name);
		printf(" |"); PV(entity.origin, 3); PV(entity.axis[0], 3); PV(entity.axis[1], 3); PV(entity.axis[2], 3); PF(entity.backlerp);
		printf("\n");
	}
}

int main(int argc, char **argv) {
	int i;
	if (argc < 3) { fprintf(stderr, "usage: q3gen <folder> <tags.md3> [mkmd3]\n"); return 1; }
	strcpy(g_folder, argv[1]);
	cg_animSpeed.integer = 1; cg_animSpeed.value = 1;
	cg_swingSpeed.integer = 0; cg_swingSpeed.value = 0.3f;
	if (argc > 3 && !strcmp(argv[3], "mkmd3")) { MakeMd3(argv[2]); return 0; }
	LoadMd3(argv[2]);
	for (i = 0; i < NUM_CFG; i++) {
		clientInfo_t *ci = &cgs.clientinfo[0];
		int ok;
		memset(ci, 0, sizeof(*ci));
		g_msgCount = 0;
		ok = CG_ParseAnimationFile(g_names[i], ci);
		DumpCfg(g_names[i], ci, ok);
	}
	Timeline("full.cfg", 60, 1, 0, 0);
	Timeline("headeropts.cfg", 60, 2, 0, 0);
	Timeline("noflags.cfg", 40, 3, 0, 0);
	Timeline("full.cfg", 20, 4, 1, 0);
	Timeline("full.cfg", 20, 5, 0, 1);
	Tags();
	return 0;
}
