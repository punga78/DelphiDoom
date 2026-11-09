/* Harness of the actions of Keen Dreams (issue #165, K8b): runs one function of kd_keen.c, kd_act1.c or kd_act2.c
   (the original objects, compiled with Open Watcom 16 bit, int is 16 bit like in the game) on the scenarios of
   SCEN.TXT and writes what happens. The world is a stub: the functions of kd_play.c (the list of the actors is
   copied) and the refresh manager write their calls in the log. See Tools\Verifica\165\LEGGIMI.md */
#include "KD_DEF.H"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <dos.h>
#include <i86.h>

#include "tbl.inc"
#define NSTATES (sizeof(stbl)/sizeof(stbl[0]))
#define LOG if (!quiet) printf

/* ---- the globals that kd_play.c, id_rf.c and the others own ---- */
gametype gamestate;
exittype playstate;
boolean button0held, button1held;
unsigned originxtilemax, originytilemax;
objtype *new, *check, *player, *scoreobj;
ControlInfo c;
objtype dummyobj;
boolean jumpcheat, godmode;
unsigned tics;
long lasttimecount;
unsigned originxglobal, originyglobal, originxtile, originytile;
unsigned mapwidth, mapheight;
unsigned mapbwidthtable[MAXMAPHEIGHT];
unsigned mapsegs[3];
unsigned tinf_s;
longword TimeCount;
unsigned PrintY;
unsigned grsegs[NUMCHUNKS];
unsigned spritetable_s;
int mapon;

int objectcount;
objtype objarray[MAXACTORS], *lastobj, *objfreelist;
int rndpos;
int rnd[64];
int rndn;
int quiet;
int maxslot;

int slotof(objtype *o)
{
	if (o == &dummyobj) return 100;
	if (!o) return -1;
	return (int)(o - objarray);
}

int stateidx(statetype *s)
{
	unsigned i;
	if (!s) return -1;
	for (i = 0; i < NSTATES; i++) if (stbl[i] == s) return i;
	return -2;
}

/* ---- stubs: what the functions of the actions call ---- */
void SD_PlaySound(word sound) { LOG("snd %u\n", sound); }

int US_RndT(void)
{
	int v = 0;
	if (rndpos < rndn) v = rnd[rndpos];
	rndpos++;
	LOG("rnd %d\n", v);
	return v;
}

void RF_PlaceSprite(void **user, unsigned x, unsigned y, unsigned spritenumber, drawtype draw, int priority)
{
	int slot = -1, i;
	for (i = 0; i < MAXACTORS; i++) if ((void **)&objarray[i].sprite == user) slot = i;
	if ((void **)&dummyobj.sprite == user) slot = 100;
	LOG("place %d %u %u %u %d\n", slot, x, y, spritenumber, priority);
	*user = (void *)1;
}

void RF_RemoveSprite(void **user)
{
	int slot = -1, i;
	for (i = 0; i < MAXACTORS; i++) if ((void **)&objarray[i].sprite == user) slot = i;
	if ((void **)&dummyobj.sprite == user) slot = 100;
	LOG("rmsprite %d\n", slot);
	*user = 0;
}

void RF_ForceRefresh(void) {}
void VW_FixRefreshBuffer(void) {}
void VW_UpdateScreen(void) {}
void US_CenterWindow(word w, word h) { LOG("needbombs\n"); }
void US_CPrint(char *s) {}
void IN_Ack(void) {}
void CAL_ShiftSprite(unsigned segment, unsigned source, unsigned dest, unsigned width, unsigned height,
	unsigned pixshift) {}

void Quit(char *error)
{
	printf("QUIT %s\n", error);
	exit(1);
}

/* ---- kd_play.c: the list of the actors (copied) ---- */
void GetNewObj(boolean usedummy)
{
	if (!objfreelist)
	{
		if (usedummy) { new = &dummyobj; return; }
		Quit("GetNewObj: No free spots in objarray!");
	}
	new = objfreelist;
	objfreelist = new->prev;
	memset(new, 0, sizeof(*new));
	if (lastobj) lastobj->next = new;
	new->prev = lastobj;
	new->active = yes;
	new->needtoclip = true;
	lastobj = new;
	objectcount++;
	if (slotof(new) > maxslot) maxslot = slotof(new);
	LOG("newobj %d\n", slotof(new));
}

void RemoveObj(objtype *gone)
{
	if (gone == player) Quit("RemoveObj: Tried to remove the player!");
	LOG("remove %d\n", slotof(gone));
	RF_RemoveSprite(&gone->sprite);
	if (gone == lastobj) lastobj = (objtype *)gone->prev;
	else gone->next->prev = gone->prev;
	gone->prev->next = gone->next;
	gone->prev = objfreelist;
	objfreelist = gone;
}

void InitObjArray(void)
{
	int i;
	for (i = 0; i < MAXACTORS; i++) { objarray[i].prev = &objarray[i + 1]; objarray[i].next = NULL; }
	objarray[MAXACTORS - 1].prev = NULL;
	objfreelist = &objarray[0];
	lastobj = NULL;
	objectcount = 0;
	GetNewObj(false); player = new;
	GetNewObj(false); scoreobj = new;
}

void NewState(objtype *ob, statetype *state)
{
	LOG("newstate %d %d\n", slotof(ob), stateidx(state));
	ob->state = state;
	if (state->rightshapenum)
	{
		if (ob->xdir > 0) ob->shapenum = state->rightshapenum;
		else ob->shapenum = state->leftshapenum;
	}
}

void ClipToWalls(objtype *ob) { LOG("clip %d\n", slotof(ob)); }
void ClipToSprite(objtype *push, objtype *solid, boolean squish)
{ LOG("clipsprite %d %d %d\n", slotof(push), slotof(solid), squish); }
void ClipToSpriteSide(objtype *push, objtype *solid)
{ LOG("clipside %d %d\n", slotof(push), slotof(solid)); }

void GivePoints(unsigned points)
{
	LOG("points %u\n", points);
	gamestate.score += points;
	if (gamestate.score >= gamestate.nextextra)
	{
		SD_PlaySound(EXTRAKEENSND);
		gamestate.lives++;
		gamestate.nextextra *= 2;
	}
}

/* ---- the scenarios ---- */
FILE *in;
char word_[64];

int tok(void)
{
	if (fscanf(in, "%63s", word_) != 1) return -32767;
	if (word_[0] == '@') return (int)&objarray[atoi(word_ + 1)];
	if (word_[0] == '$') return (int)stbl[atoi(word_ + 1)];
	return atoi(word_);
}

long ltok(void)
{
	if (fscanf(in, "%63s", word_) != 1) return 0;
	return atol(word_);
}

int namedtok(void) { return fscanf(in, "%63s", word_); }

void readobj(objtype *o)
{
	int s;
	o->obclass = tok();
	o->active = tok();
	o->needtoreact = tok();
	o->needtoclip = tok();
	o->nothink = tok();
	o->x = tok(); o->y = tok();
	o->xdir = tok(); o->ydir = tok();
	o->xmove = tok(); o->ymove = tok();
	o->xspeed = tok(); o->yspeed = tok();
	o->ticcount = tok(); o->ticadjust = tok();
	s = tok();
	o->state = (s < 0) ? NULL : stbl[s];
	o->shapenum = tok();
	o->left = tok(); o->top = tok(); o->right = tok(); o->bottom = tok(); o->midx = tok();
	o->tileleft = tok(); o->tiletop = tok(); o->tileright = tok(); o->tilebottom = tok(); o->tilemidx = tok();
	o->hitnorth = tok(); o->hiteast = tok(); o->hitsouth = tok(); o->hitwest = tok();
	o->temp1 = tok(); o->temp2 = tok(); o->temp3 = tok(); o->temp4 = tok();
}

/* a temp that holds the address of an actor or of a state is written as @slot or $state */
void tempout(int v)
{
	int i;
	unsigned k;
	for (i = 0; i < MAXACTORS; i++) if (v == (int)&objarray[i]) { printf(" %d", i); return; }
	if (v == (int)&dummyobj) { printf(" 100"); return; }
	for (k = 0; k < NSTATES; k++) if (v == (int)stbl[k]) { printf(" %u", k); return; }
	printf(" %d", v);
}

void dumpobj(int slot, objtype *o)
{
	printf("obj %d %d %d %d %d %d %u %u %d %d %d %d %d %d %d %d %d %u", slot, o->obclass, o->active,
		o->needtoreact, o->needtoclip, o->nothink, o->x, o->y, o->xdir, o->ydir, o->xmove, o->ymove,
		o->xspeed, o->yspeed, o->ticcount, o->ticadjust, stateidx(o->state), o->shapenum);
	printf(" %u %u %u %u %u %u %u %u %u %u", o->left, o->top, o->right, o->bottom, o->midx, o->tileleft,
		o->tiletop, o->tileright, o->tilebottom, o->tilemidx);
	printf(" %d %d %d %d", o->hitnorth, o->hiteast, o->hitsouth, o->hitwest);
	tempout(o->temp1); tempout(o->temp2); tempout(o->temp3); tempout(o->temp4);
	printf("\n");
}

extern int jumptime;
extern long leavepoletime;

void main(void)
{
	int i, k, w, h, nobj, obsel, hitsel, ntinf, tl;
	char kind[8];
	char name[64];
	void (*fn)();
	unsigned seg;
	unsigned far *p;
	byte far *t;

	in = fopen("SCEN.TXT", "r");
	if (!in) { printf("no SCEN.TXT\n"); return; }
	if (_dos_allocmem(0x1000, &seg)) { printf("no mem\n"); return; }
	tinf_s = seg;
	t = (byte far *)MK_FP(tinf_s, 0);
	_fmemset(t, 0, 0xFFF0);
	/* the table of the tiles: "H n" then n lines of: tile north east south west intile */
	namedtok(); ntinf = tok();
	for (i = 0; i < ntinf; i++)
	{
		tl = tok();
		t[NORTHWALL + tl] = tok();
		t[EASTWALL + tl] = tok();
		t[SOUTHWALL + tl] = tok();
		t[WESTWALL + tl] = tok();
		t[INTILE + tl] = tok();
	}
	if (_dos_allocmem(0x400, &seg)) { printf("no mem\n"); return; }
	mapsegs[1] = seg;
	if (_dos_allocmem(0x400, &seg)) { printf("no mem\n"); return; }
	mapsegs[2] = seg;
	for (;;)
	{
		if (namedtok() != 1) break;           /* "S" */
		if (word_[0] != 'S') break;
		namedtok(); strcpy(name, word_);
		namedtok(); strcpy(kind, word_);
		namedtok();                            /* CTL */
		c.xaxis = tok(); c.yaxis = tok(); c.dir = tok(); c.button0 = tok(); c.button1 = tok();
		button0held = tok(); button1held = tok();
		namedtok();                            /* GLB */
		tics = tok(); lasttimecount = ltok(); TimeCount = ltok();
		originxtile = tok(); originytile = tok(); originxglobal = tok(); originyglobal = tok();
		originxtilemax = tok(); originytilemax = tok();
		memset(&gamestate, 0, sizeof(gamestate));
		gamestate.mapon = tok(); mapon = tok(); gamestate.keys = tok(); gamestate.boobusbombs = tok();
		gamestate.flowerpowers = tok(); gamestate.lives = tok(); gamestate.difficulty = tok();
		godmode = tok(); jumpcheat = tok(); jumptime = tok(); leavepoletime = ltok();
		gamestate.score = ltok(); gamestate.worldx = tok(); gamestate.worldy = tok();
		gamestate.bombsthislevel = tok();
		gamestate.nextextra = 20000L;
		playstate = notdone;
		namedtok();                            /* RND */
		rndn = tok(); rndpos = 0;
		for (i = 0; i < rndn; i++) rnd[i] = tok();
		namedtok();                            /* MAP */
		w = tok(); h = tok();
		mapwidth = w; mapheight = h;
		for (i = 0; i < MAXMAPHEIGHT; i++) mapbwidthtable[i] = i * w * 2;
		p = (unsigned far *)MK_FP(mapsegs[1], 0);
		for (i = 0; i < w * h; i++) p[i] = tok();
		p = (unsigned far *)MK_FP(mapsegs[2], 0);
		for (i = 0; i < w * h; i++) p[i] = tok();
		namedtok();                            /* OBJ */
		nobj = tok();
		memset(&dummyobj, 0, sizeof(dummyobj));
		memset(objarray, 0, sizeof(objarray));
		quiet = 1; maxslot = 0;
		InitObjArray();
		for (i = 2; i < nobj; i++) GetNewObj(false);
		for (i = 0; i < nobj; i++) readobj(&objarray[i]);
		namedtok();                            /* SEL */
		obsel = tok(); hitsel = tok();
		new = &objarray[nobj - 1];
		fn = 0;
		for (k = 0; acts[k].name; k++) if (strcmp(acts[k].name, name) == 0) fn = acts[k].fn;
		if (!fn) { printf("unknown %s\n", name); break; }
		printf("S %s %s\n", name, kind);
		quiet = 0;
		if (kind[0] == 'C') ((void (*)(objtype *, objtype *))fn)(&objarray[obsel], &objarray[hitsel]);
		else ((void (*)(objtype *))fn)(&objarray[obsel]);
		printf("state %d %ld %ld %d %d %d %d %d %d %u %u %d\n", playstate, gamestate.score, gamestate.nextextra,
			gamestate.lives, gamestate.flowerpowers, gamestate.boobusbombs, gamestate.bombsthislevel,
			gamestate.keys, gamestate.mapon, gamestate.worldx, gamestate.worldy, godmode);
		printf("flags %d %d %d %ld\n", button0held, button1held, jumptime, leavepoletime);
		printf("new %d\n", slotof(new));
		for (i = 0; i <= maxslot && i < MAXACTORS; i++) dumpobj(i, &objarray[i]);
		printf("E\n");
	}
	fclose(in);
}
