/*
 * Parity driver of the issue #127: the player movement of Quake III Arena (bg_pmove.c and
 * bg_slidemove.c, compiled as they are, see build.sh) over a fake world made here.
 *
 *   pmgen golden        writes the golden file (stdout): the world, the items, the scenarios
 *                       (initial state, commands as segments) and one hash per executed command
 *   pmgen dump <id>     per command, the words of the player state and the outputs of Pmove
 *                       (to find the first field that differs from the Pascal port)
 *
 * The world is a list of convex brushes (planes), swept by a box with the algorithm of
 * CM_TraceThroughBrush; the Pascal test reads the same brushes from the golden (as bits of
 * floats) and sweeps them with the same algorithm. Everything the movement reads goes through
 * pm->trace and pm->pointcontents, like in the game.
 */
#include "q_shared.h"
#include "bg_public.h"
#include "bg_local.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>
#include <stdint.h>

#include "q_math_part.inc"

/* ---------------------------------------------------------------- engine stubs */

static char ptext[1 << 16];
static int plen;

void Com_Printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  plen += vsnprintf(ptext + plen, sizeof(ptext) - plen, fmt, ap);
  va_end(ap);
}

void Com_Error(int level, const char *fmt, ...) {
  fprintf(stderr, "Com_Error\n");
  exit(2);
}

int Q_stricmp(const char *a, const char *b) { return _stricmp(a, b); }
void vectoangles(const vec3_t value1, vec3_t angles) { fprintf(stderr, "vectoangles\n"); exit(2); }
float AngleNormalize180(float angle) { fprintf(stderr, "AngleNormalize180\n"); exit(2); return 0; }

/* Sys_SnapVector of the engine: fistp, round to nearest even */
void trap_SnapVector(float *v) {
  v[0] = (float)lrintf(v[0]);
  v[1] = (float)lrintf(v[1]);
  v[2] = (float)lrintf(v[2]);
}

/* ---------------------------------------------------------------- fake world */

#define EPS 0.125f

typedef struct {
  int contents, surf, ent, np;
  float n[8][3];
  float d[8];
} brush_t;

static brush_t W[200];
static int nW;

static brush_t *newbrush(int contents, int surf, int ent) {
  brush_t *b = &W[nW++];
  memset(b, 0, sizeof(*b));
  b->contents = contents;
  b->surf = surf;
  b->ent = ent;
  return b;
}

static void addplane(brush_t *b, float nx, float ny, float nz, float d) {
  b->n[b->np][0] = nx;
  b->n[b->np][1] = ny;
  b->n[b->np][2] = nz;
  b->d[b->np] = d;
  b->np++;
}

static void box(float x1, float y1, float z1, float x2, float y2, float z2, int contents, int surf, int ent) {
  brush_t *b = newbrush(contents, surf, ent);
  addplane(b, -1, 0, 0, -x1);
  addplane(b, 1, 0, 0, x2);
  addplane(b, 0, -1, 0, -y1);
  addplane(b, 0, 1, 0, y2);
  addplane(b, 0, 0, -1, -z1);
  addplane(b, 0, 0, 1, z2);
}

/* a wedge: slope plane (n, through the point px,py,pz), floor at z1, back/toe in x, sides in y */
static void wedge(float nx, float nz, float toex, float backx, float halfy, float z1) {
  brush_t *b = newbrush(CONTENTS_SOLID, 0, 0);
  addplane(b, nx, 0, nz, nx * toex);
  addplane(b, 0, 0, -1, -z1);
  addplane(b, 1, 0, 0, backx);
  addplane(b, -1, 0, 0, -toex);
  addplane(b, 0, -1, 0, halfy);
  addplane(b, 0, 1, 0, halfy);
}

/* a box turned around z: (c, s) is the direction of the long side */
static void rotbox(float cx, float cy, float c, float s, float hl, float ht, float z1, float z2) {
  brush_t *b = newbrush(CONTENTS_SOLID, 0, 0);
  float cu = c * cx + s * cy;
  float cv = -s * cx + c * cy;
  addplane(b, c, s, 0, cu + hl);
  addplane(b, -c, -s, 0, -cu + hl);
  addplane(b, -s, c, 0, cv + ht);
  addplane(b, s, -c, 0, -cv + ht);
  addplane(b, 0, 0, -1, -z1);
  addplane(b, 0, 0, 1, z2);
}

static void pool(float x1, float y1, float x2, float y2, float height, int contents) {
  box(x1 - 20, y1 - 20, -64, x1, y2 + 20, 108, CONTENTS_SOLID, 0, 0);
  box(x2, y1 - 20, -64, x2 + 20, y2 + 20, 108, CONTENTS_SOLID, 0, 0);
  box(x1, y1 - 20, -64, x2, y1, 108, CONTENTS_SOLID, 0, 0);
  box(x1, y2, -64, x2, y2 + 20, 108, CONTENTS_SOLID, 0, 0);
  box(x1, y1, 0, x2, y2, height, contents, 0, 0);
}

static void build_world(void) {
  int i;
  float k;
  nW = 0;
  /* specials first: on the same plane as the floor the first brush wins */
  box(100, 300, -64, 300, 500, 0, CONTENTS_SOLID, SURF_SLICK, 0);
  box(400, 300, -64, 600, 500, 0, CONTENTS_SOLID, SURF_METALSTEPS, 0);
  box(700, 300, -64, 900, 500, 0, CONTENTS_SOLID, SURF_NOSTEPS, 0);
  box(1000, 300, -64, 1200, 500, 0, CONTENTS_SOLID, SURF_NODAMAGE, 0);
  box(1300, 300, -64, 1500, 500, 0, CONTENTS_SOLID, SURF_SLICK | SURF_NODAMAGE, 0);
  /* stairs of 8 */
  for (i = 0; i < 4; i++) {
    box(100 + 32 * i, -100, -64, 400, 100, 8 * (i + 1), CONTENTS_SOLID, 0, 0);
  }
  /* bumps: 20 (cannot be stepped), 16, 18 (the step size), 17 */
  box(500, -100, -64, 520, 100, 20, CONTENTS_SOLID, 0, 0);
  box(540, -100, -64, 560, 100, 16, CONTENTS_SOLID, 0, 0);
  box(580, -100, -64, 600, 100, 18, CONTENTS_SOLID, 0, 0);
  box(620, -100, -64, 640, 100, 17, CONTENTS_SOLID, 0, 0);
  /* ramps: walkable, too steep, normal z exactly 0.7f */
  wedge(-0.6f, 0.8f, 700, 1000, 100, -64);
  wedge(-0.8f, 0.6f, 1200, 1400, 100, -64);
  wedge(-0.7141428f, 0.7f, 1500, 1700, 100, -64);
  /* pools: water, slime, lava (rim of 108, surface at 100: a ledge 8 over the water) */
  pool(-1500, -500, -1000, 500, 100, CONTENTS_WATER);
  pool(-1500, 700, -1000, 1200, 100, CONTENTS_SLIME);
  pool(-1500, 1400, -1000, 1900, 100, CONTENTS_LAVA);
  /* shallow water in the open */
  box(-900, -500, 0, -500, 500, 30, CONTENTS_WATER, 0, 0);
  /* a high platform and a pillar */
  box(-500, -300, -64, -300, -100, 128, CONTENTS_SOLID, 0, 0);
  box(-250, -50, -64, -150, 50, 200, CONTENTS_SOLID, 0, 0);
  /* a corridor with a low ceiling (44 over the floor: standing needs 56, ducking 40) */
  box(1800, -100, 44, 2200, 100, 200, CONTENTS_SOLID, 0, 0);
  box(1800, -120, -64, 2200, -100, 200, CONTENTS_SOLID, 0, 0);
  box(1800, 100, -64, 2200, 120, 200, CONTENTS_SOLID, 0, 0);
  /* small bumps for the step events */
  {
    static const float h[5] = {3, 6, 9, 13, 17};
    for (i = 0; i < 5; i++) {
      box(2300 + 40 * i, -100, -64, 2320 + 40 * i, 100, h[i], CONTENTS_SOLID, 0, 0);
    }
  }
  /* two walls at 45 degrees that cross: creases */
  rotbox(-150, 1500, 0.7071068f, 0.7071068f, 300, 16, -64, 200);
  rotbox(150, 1500, 0.7071068f, -0.7071068f, 300, 16, -64, 200);
  /* 36 posts of different entities side by side (more than MAXTOUCH) */
  for (i = 0; i < 36; i++) {
    k = (float)i;
    box(2600, -180 + 10 * k, -64, 2620, -170 + 10 * k, 200, CONTENTS_SOLID, 0, 100 + i);
  }
  /* a mover, a body (a corpse flies through it) and a player clip */
  box(1800, -400, -64, 1900, -300, 60, CONTENTS_SOLID, 0, 7);
  box(200, -400, -64, 300, -300, 100, CONTENTS_BODY, 0, 9);
  box(400, -400, -64, 500, -300, 100, CONTENTS_PLAYERCLIP, 0, 0);
  /* outer walls, a ceiling, the floor */
  box(-3020, -3020, -64, -3000, 3020, 400, CONTENTS_SOLID, 0, 0);
  box(3000, -3020, -64, 3020, 3020, 400, CONTENTS_SOLID, 0, 0);
  box(-3020, -3020, -64, 3020, -3000, 400, CONTENTS_SOLID, 0, 0);
  box(-3020, 3000, -64, 3020, 3020, 400, CONTENTS_SOLID, 0, 0);
  box(-3020, -3020, 600, 3020, 3020, 620, CONTENTS_SOLID, 0, 0);
  box(-3000, -3000, -64, 3000, 3000, 0, CONTENTS_SOLID, 0, 0);
}

/* the sweep of CM_TraceThroughBrush on a list of brushes */
static void wtrace(trace_t *tr, const vec3_t start, const vec3_t mins, const vec3_t maxs, const vec3_t end,
                   int passEntityNum, int contentMask) {
  int bi, i, j;
  float enter0;
  memset(tr, 0, sizeof(*tr));
  tr->fraction = 1.0f;
  for (bi = 0; bi < nW; bi++) {
    brush_t *b = &W[bi];
    float enter = -1.0f, leave = 1.0f;
    int startout = 0, getout = 0, clip = -1, miss = 0;
    if (!(b->contents & contentMask)) {
      continue;
    }
    for (i = 0; i < b->np; i++) {
      float off[3], dist, d1, d2, f;
      for (j = 0; j < 3; j++) {
        off[j] = b->n[i][j] < 0 ? maxs[j] : mins[j];
      }
      dist = b->d[i] - DotProduct(off, b->n[i]);
      d1 = DotProduct(start, b->n[i]) - dist;
      d2 = DotProduct(end, b->n[i]) - dist;
      if (d2 > 0) getout = 1;
      if (d1 > 0) startout = 1;
      if (d1 > 0 && d2 >= d1) {
        miss = 1;
        break;
      }
      if (d1 <= 0 && d2 <= 0) continue;
      if (d1 > d2) {
        f = (d1 - EPS) / (d1 - d2);
        if (f < 0) f = 0;
        if (f > enter) {
          enter = f;
          clip = i;
        }
      } else {
        f = (d1 + EPS) / (d1 - d2);
        if (f > 1) f = 1;
        if (f < leave) leave = f;
      }
    }
    if (miss) continue;
    if (!startout) {
      tr->startsolid = 1;
      if (!getout) {
        tr->allsolid = 1;
        tr->fraction = 0;
        tr->contents = b->contents;
      }
      continue;
    }
    if (enter < leave && enter > -1 && enter < tr->fraction) {
      if (enter < 0) enter = 0;
      tr->fraction = enter;
      tr->plane.normal[0] = b->n[clip][0];
      tr->plane.normal[1] = b->n[clip][1];
      tr->plane.normal[2] = b->n[clip][2];
      tr->surfaceFlags = b->surf;
      tr->contents = b->contents;
      tr->entityNum = b->ent ? b->ent : ENTITYNUM_WORLD;
    }
  }
  if (tr->fraction == 1.0f) {
    VectorCopy(end, tr->endpos);
    tr->entityNum = ENTITYNUM_NONE;
  } else {
    for (i = 0; i < 3; i++) {
      tr->endpos[i] = start[i] + tr->fraction * (end[i] - start[i]);
    }
    if (tr->allsolid) tr->entityNum = ENTITYNUM_WORLD;
  }
  (void)enter0;
}

static int wpointcontents(const vec3_t point, int passEntityNum) {
  int bi, i, c = 0;
  for (bi = 0; bi < nW; bi++) {
    brush_t *b = &W[bi];
    int inside = 1;
    for (i = 0; i < b->np; i++) {
      if (DotProduct(point, b->n[i]) - b->d[i] > 0) {
        inside = 0;
        break;
      }
    }
    if (inside) c |= b->contents;
  }
  return c;
}

/* ---------------------------------------------------------------- scenarios */

#define NWORDS (int)(sizeof(playerState_t) / 4)
#define MAXSEG 24

typedef struct {
  int count, msec, f, r, u, buttons, weapon;
  int a0[3], da[3];
} seg_t;

typedef struct {
  char name[24];
  unsigned ps[NWORDS];
  int tracemask, nofoot, gaunt, fixed, fixmsec, debug;
  int nseg;
  seg_t seg[MAXSEG];
} scn_t;

static unsigned rstate;
static unsigned rnd(void) {
  rstate ^= rstate << 13;
  rstate ^= rstate >> 17;
  rstate ^= rstate << 5;
  return rstate;
}
static int ri(int lo, int hi) { return lo + (int)(rnd() % (unsigned)(hi - lo + 1)); }
static int pick(const int *a, int n) { return a[rnd() % (unsigned)n]; }
static float rf(float lo, float hi) { return lo + (hi - lo) * (float)(rnd() % 100000) / 100000.0f; }

static void set_ps(scn_t *s, const playerState_t *p) { memcpy(s->ps, p, sizeof(*p)); }

static void base_ps(playerState_t *p, float x, float y, float z) {
  memset(p, 0, sizeof(*p));
  p->commandTime = 1000 + ri(0, 50) * 7;
  p->origin[0] = x;
  p->origin[1] = y;
  p->origin[2] = z;
  p->gravity = 800;
  p->speed = 320;
  p->viewheight = DEFAULT_VIEWHEIGHT;
  p->groundEntityNum = (rnd() & 1) ? ENTITYNUM_NONE : ENTITYNUM_WORLD;
  p->stats[STAT_HEALTH] = 100;
  p->stats[STAT_MAX_HEALTH] = 100;
  p->stats[STAT_WEAPONS] = 0x3FE;
  p->weapon = WP_MACHINEGUN;
  p->persistant[PERS_TEAM] = TEAM_FREE;
  p->clientNum = 0;
  p->ammo[WP_GAUNTLET] = -1;
  p->ammo[WP_MACHINEGUN] = 100;
  p->ammo[WP_SHOTGUN] = 10;
  p->ammo[WP_GRENADE_LAUNCHER] = 5;
  p->ammo[WP_ROCKET_LAUNCHER] = 3;
  p->ammo[WP_LIGHTNING] = 50;
  p->ammo[WP_RAILGUN] = 0;
  p->ammo[WP_PLASMAGUN] = 30;
  p->ammo[WP_BFG] = 2;
  p->ammo[WP_GRAPPLING_HOOK] = -1;
}

static void add_seg(scn_t *s, int count, int msec, int f, int r, int u, int buttons, int weapon, int yaw, int pitch,
                    int roll, int dyaw, int dpitch, int droll) {
  seg_t *g;
  if (s->nseg >= MAXSEG) return;
  g = &s->seg[s->nseg++];
  g->count = count;
  g->msec = msec;
  g->f = f;
  g->r = r;
  g->u = u;
  g->buttons = buttons;
  g->weapon = weapon;
  g->a0[0] = pitch;
  g->a0[1] = yaw;
  g->a0[2] = roll;
  g->da[0] = dpitch;
  g->da[1] = dyaw;
  g->da[2] = droll;
}

static const int MOVES[] = {0, 127, -127, 64, -64, 100, -30, 0, 127, 127};
static const int UPS[] = {0, 0, 0, 127, -127, 20, 5, 0, 0, 127};
static const int MSECS[] = {8, 8, 16, 16, 16, 16, 33, 33, 50, 100, 150, 8, 16, 16};

/* a random segment; the biases come from the mode of the scenario */
static void rand_seg(scn_t *s, int mode, int yaw, int walkpush) {
  int count = ri(1, 24);
  int msec = pick(MSECS, 14);
  int f = pick(MOVES, 10), r = pick(MOVES, 10), u = pick(UPS, 10);
  int buttons = 0, dyaw = 0;
  if (rnd() % 4 == 0) buttons |= BUTTON_WALKING;
  if (rnd() % 5 == 0) buttons |= BUTTON_ATTACK;
  if (rnd() % 12 == 0) buttons |= BUTTON_GESTURE;
  if (rnd() % 20 == 0) buttons |= BUTTON_USE_HOLDABLE;
  if (rnd() % 40 == 0) buttons |= BUTTON_TALK;
  if (rnd() % 3 == 0) dyaw = ri(-300, 300);
  if (walkpush) f = 127;
  if (mode == 6 || mode == 7) { /* water: more vertical */
    if (rnd() % 2) u = pick(UPS, 10);
  }
  add_seg(s, count, msec, f, r, u, buttons, ri(0, 9), yaw, ri(-3000, 3000), 0, dyaw, ri(-20, 20), 0);
}

static int item_index(int tag, int type) {
  int i;
  for (i = 0; i < bg_numItems; i++) {
    if (bg_itemlist[i].giType == type && bg_itemlist[i].giTag == tag) return i;
  }
  return 0;
}

#define NMODES 16
#define PER_MODE 12

static void make_scenario(scn_t *s, int id) {
  playerState_t p;
  int mode = id % NMODES, i, n, yaw;
  float x, y, z;
  memset(s, 0, sizeof(*s));
  rstate = 2463534242u ^ ((unsigned)(id + 1) * 2654435761u);
  for (i = 0; i < 4; i++) rnd();
  s->tracemask = MASK_PLAYERSOLID;
  yaw = ri(0, 65535);
  sprintf(s->name, "mode%d.%d", mode, id / NMODES);

  /* spawn */
  x = rf(-200, 200);
  y = rf(-200, 200);
  z = 24;
  switch (mode) {
  case 0: break; /* flat */
  case 1: break;
  case 2: x = 1790; y = rf(-60, 60); break; /* corridor */
  case 3: x = rf(20, 90); y = rf(-60, 60); yaw = 0; if ((id / NMODES) % 2) x = rf(2250, 2290); break; /* stairs, bumps */
  case 4: x = rf(660, 690); y = rf(-60, 60); yaw = 0; if (id % 3 == 1) x = rf(1160, 1190); if (id % 3 == 2) x = rf(1460, 1490); break;
  case 5: x = rf(120, 280); y = rf(320, 480); z = 24 + (float)ri(0, 200); if (id % 5 == 1) x += 300; if (id % 5 == 2) x += 600; if (id % 5 == 3) x += 900; if (id % 5 == 4) x += 1200; break;
  case 6: x = rf(-1400, -1100); y = rf(-400, 400); z = rf(20, 120); break; /* pool */
  case 7: x = rf(-1400, -1100); y = (id % 2) ? rf(800, 1100) : rf(1500, 1800); z = rf(120, 400); break;
  case 8: x = rf(-480, -320); y = rf(-280, -120); z = 128 + 24; if (id % 3 == 2) { x = rf(-600, -400); y = rf(600, 800); z = 420 + rf(0, 150); } break; /* platform, a high fall */
  case 9: x = rf(-100, 100); y = rf(1400, 1600); break; /* creases */
  case 10: x = rf(-2000, 2000); y = rf(-2000, 2000); z = rf(24, 500); break;
  case 11: x = rf(-100, 100); y = rf(-100, 100); z = rf(24, 80); break;
  case 12: x = rf(-100, 100); y = rf(-100, 100); break;
  case 13: if ((id / NMODES) % 2 == 0) { x = 1850; y = -350; z = 84; } break; /* on a mover */
  case 14: break;
  default:
    x = rf(-2900, 2900);
    y = rf(-2900, 2900);
    z = rf(24, 100);
    break;
  }
  if (mode == 9 && (id % 3 == 2)) { x = 2980; y = 2980; }       /* a corner of the room */
  if (mode == 9 && (id % 3 == 1)) { x = 2584; y = -190; yaw = 16384; }  /* along the posts */

  base_ps(&p, x, y, z);

  /* mode specific state */
  switch (mode) {
  case 1:
    break;
  case 8:
    if (id % 3 == 0) p.stats[STAT_HEALTH] = 10;
    break;
  case 10:
    p.pm_type = (id / NMODES) % 3 == 0 ? PM_NOCLIP : (id / NMODES) % 3 == 1 ? PM_SPECTATOR : PM_NORMAL;
    if (p.pm_type == PM_NORMAL) p.powerups[PW_FLIGHT] = 100000;
    p.velocity[0] = rf(-300, 300);
    p.velocity[1] = rf(-300, 300);
    p.velocity[2] = rf(-100, 100);
    break;
  case 11:
    switch ((id / NMODES) % 6) {
    case 0: p.pm_type = PM_DEAD; p.stats[STAT_HEALTH] = -10; break;
    case 1: p.pm_type = PM_DEAD; p.stats[STAT_HEALTH] = 0; z = 24; break;
    case 2: p.pm_type = PM_FREEZE; break;
    case 3: p.pm_type = PM_INTERMISSION; break;
    case 4: p.pm_type = PM_SPINTERMISSION; break;
    default: p.pm_type = PM_NORMAL; p.stats[STAT_HEALTH] = -5; break;
    }
    p.velocity[0] = rf(-400, 400);
    p.velocity[1] = rf(-400, 400);
    p.velocity[2] = rf(-50, 300);
    break;
  case 12:
    switch ((id / NMODES) % 6) {
    case 0: p.pm_flags = PMF_TIME_KNOCKBACK; p.pm_time = ri(50, 300); p.velocity[0] = rf(-500, 500); p.velocity[1] = rf(-500, 500); break;
    case 1: p.pm_flags = PMF_TIME_WATERJUMP; p.pm_time = ri(100, 2000); p.velocity[0] = 200; p.velocity[2] = 350; break;
    case 2: p.pm_flags = PMF_GRAPPLE_PULL; p.grapplePoint[0] = rf(-300, 300); p.grapplePoint[1] = rf(-300, 300); p.grapplePoint[2] = rf(100, 400); break;
    case 3: p.pm_flags = PMF_RESPAWNED | PMF_JUMP_HELD; break;
    case 4: p.pm_flags = PMF_DUCKED | PMF_BACKWARDS_JUMP | PMF_BACKWARDS_RUN | PMF_TIME_LAND; p.pm_time = 250; break;
    default: p.pm_flags = PMF_INVULEXPAND | PMF_USE_ITEM_HELD | PMF_FOLLOW | PMF_SCOREBOARD; p.powerups[PW_INVULNERABILITY] = (id / NMODES) & 1; break;
    }
    break;
  case 13:
    p.stats[STAT_HOLDABLE_ITEM] = item_index((id / NMODES) % 2 ? HI_MEDKIT : HI_TELEPORTER, IT_HOLDABLE);
    if (id % 5 == 0) p.stats[STAT_HOLDABLE_ITEM] = ri(0, bg_numItems - 1);
    p.weapon = ri(0, 9);
    p.weaponstate = ri(0, 3);
    p.weaponTime = ri(0, 800);
    p.powerups[PW_HASTE] = (id / NMODES) % 3 == 0 ? 100000 : 0;
    if ((id / NMODES) % 4 == 0) p.stats[STAT_HEALTH] = 150;
    if ((id / NMODES) % 5 == 4) p.persistant[PERS_TEAM] = TEAM_SPECTATOR;
    if ((id / NMODES) % 7 == 3) p.stats[STAT_WEAPONS] = 0;
    s->gaunt = (id / NMODES) & 1;
    s->nofoot = ((id / NMODES) / 2) & 1;
    break;
  case 14:
    s->fixed = (id / NMODES) % 3 == 0;
    s->fixmsec = pick((const int[]){8, 10, 20, 33}, 4);
    break;
  case 15:
    p.gravity = pick((const int[]){800, 0, 200, 1600, 800, -300}, 6);
    p.speed = pick((const int[]){320, 0, 100, 400, 320, 640}, 6);
    p.pm_type = pick((const int[]){0, 0, 0, 1, 2, 3, 4, 0}, 8);
    p.pm_flags = (int)(rnd() & 0x7FFF) & ~PMF_FOLLOW;
    p.pm_time = ri(0, 400);
    p.velocity[0] = rf(-800, 800);
    p.velocity[1] = rf(-800, 800);
    p.velocity[2] = rf(-800, 800);
    p.stats[STAT_HEALTH] = pick((const int[]){100, 100, -20, 0}, 4);
    p.viewheight = pick((const int[]){26, 12, -16}, 3);
    p.legsTimer = ri(0, 300);
    p.torsoTimer = ri(0, 300);
    p.bobCycle = ri(0, 255);
    p.weaponTime = ri(0, 500);
    p.weapon = ri(0, 9);
    p.weaponstate = ri(0, 3);
    p.eventSequence = ri(0, 5);
    p.pmove_framecount = ri(0, 63);
    p.movementDir = ri(0, 7);
    s->tracemask = pick((const int[]){MASK_PLAYERSOLID, MASK_PLAYERSOLID, MASK_DEADSOLID, MASK_SOLID, MASK_ALL}, 5);
    s->nofoot = rnd() & 1;
    s->gaunt = rnd() & 1;
    if (id % 4 == 0) p.powerups[PW_FLIGHT] = 100000;
    break;
  }
  if (rnd() % 3 == 0 && !(mode == 9 && id % 3 == 1)) {
    p.delta_angles[0] = ri(-30000, 30000);
    p.delta_angles[1] = ri(-70000, 70000);
    p.delta_angles[2] = ri(-3000, 3000);
  }
  if (mode == 14 && (id / NMODES) % 5 == 1) {
    p.delta_angles[0] = 40000;
    p.delta_angles[1] = -40000;
  }
  s->debug = (id % 9 == 4);
  set_ps(s, &p);

  /* commands */
  switch (mode) {
  case 0:
    add_seg(s, 40, 8, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 20, 16, 127, 127, 0, BUTTON_WALKING, 2, yaw, 0, 0, 100, 0, 0);
    add_seg(s, 30, 16, 0, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, -127, -127, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    break;
  case 1:
    for (n = 0; n < 6; n++) {
      add_seg(s, ri(3, 25), pick(MSECS, 14), n % 2 ? 127 : 0, ri(-1, 1) * 127, 127, 0, 2, yaw + n * 4000, 0, 0, 0, 0, 0);
      add_seg(s, ri(1, 6), 16, n % 2 ? 127 : 0, 0, 0, 0, 2, yaw + n * 4000, 0, 0, 0, 0, 0);
    }
    break;
  case 2:
    add_seg(s, 30, 16, 127, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 25, 16, 127, 0, -127, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 25, 16, 127, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 25, 16, 0, 0, 127, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 25, 16, -127, 0, -127, 0, 2, 0, 0, 0, 0, 0, 0);
    break;
  case 3:
    add_seg(s, 80, 16, 127, ri(-30, 30), 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 20, 16, 127, 0, 127, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 60, 16, 127, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 60, 16, -127, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    break;
  case 4:
    add_seg(s, 60, 16, 127, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, 127, ri(-60, 60), 127, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 60, 16, -127, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    break;
  case 5:
    add_seg(s, 40, 16, 0, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 40, 16, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, 0, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, -127, 127, 0, BUTTON_WALKING, 2, yaw, 0, 0, 50, 0, 0);
    break;
  case 6:
  case 7:
    add_seg(s, 30, 16, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, 0, 0, 127, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 40, 16, 127, 0, 127, 0, 2, 16384 * (id % 4), 0, 0, 0, 0, 0);
    for (n = 0; n < 5; n++) rand_seg(s, mode, yaw, 0);
    add_seg(s, 60, 16, 127, 0, 127, BUTTON_WALKING, 2, 0, 0, 0, 0, 0, 0);
    break;
  case 8:
    add_seg(s, 30, 16, 127, 0, 0, 0, 2, 32768 * (id % 2), 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, 127, 0, -127 * (id % 2), 0, 2, 32768 * (id % 2), 0, 0, 0, 0, 0);
    add_seg(s, 40, 16, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
    add_seg(s, 30, 16, 127, 0, 127, 0, 2, 0, 0, 0, 0, 0, 0);
    break;
  case 9:
    if (id % 3 == 1) {
      add_seg(s, 2, 1000, 127, 64, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
      add_seg(s, 60, 16, 127, 64, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    }
    for (n = 0; n < 4; n++) rand_seg(s, mode, yaw, n % 2);
    break;
  default:
    for (n = 0; n < 6; n++) rand_seg(s, mode, yaw, n % 2);
    break;
  }
  if (mode != 0 && mode != 2 && mode != 3 && mode != 4) {
    int extra = ri(2, 6);
    for (n = 0; n < extra; n++) rand_seg(s, mode, yaw + ri(-2000, 2000), 0);
  }
  if (mode == 14) {
    add_seg(s, 3, 1500, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 3, 0, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 3, -40, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 4, 1, 127, 127, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 3, 66, 127, 0, 127, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 2, 67, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 2, 199, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
    add_seg(s, 2, 250, 127, 0, 0, 0, 2, yaw, 0, 0, 0, 0, 0);
  }
}

/* ---------------------------------------------------------------- run */

static uint32_t fnv_byte(uint32_t h, unsigned b) { return (h ^ (b & 255)) * 16777619u; }
static uint32_t fnv_word(uint32_t h, uint32_t w) {
  h = fnv_byte(h, w);
  h = fnv_byte(h, w >> 8);
  h = fnv_byte(h, w >> 16);
  h = fnv_byte(h, w >> 24);
  return h;
}
static uint32_t fbits(float f) {
  uint32_t u;
  memcpy(&u, &f, 4);
  return u;
}

/* the hash of what one command left: the player state, the outputs, the command and the text printed */
static uint32_t state_hash(const playerState_t *ps, const pmove_t *pm) {
  uint32_t h = 2166136261u;
  const uint32_t *w = (const uint32_t *)ps;
  int i;
  for (i = 0; i < NWORDS; i++) h = fnv_word(h, w[i]);
  h = fnv_word(h, (uint32_t)pm->numtouch);
  for (i = 0; i < pm->numtouch; i++) h = fnv_word(h, (uint32_t)pm->touchents[i]);
  for (i = 0; i < 3; i++) h = fnv_word(h, fbits(pm->mins[i]));
  for (i = 0; i < 3; i++) h = fnv_word(h, fbits(pm->maxs[i]));
  h = fnv_word(h, (uint32_t)pm->watertype);
  h = fnv_word(h, (uint32_t)pm->waterlevel);
  h = fnv_word(h, fbits(pm->xyspeed));
  for (i = 0; i < 3; i++) h = fnv_word(h, (uint32_t)pm->cmd.angles[i]);
  h = fnv_word(h, (uint32_t)pm->cmd.buttons);
  h = fnv_word(h, (uint32_t)pm->cmd.weapon);
  h = fnv_word(h, (uint32_t)(int)pm->cmd.forwardmove);
  h = fnv_word(h, (uint32_t)(int)pm->cmd.rightmove);
  h = fnv_word(h, (uint32_t)(int)pm->cmd.upmove);
  h = fnv_word(h, (uint32_t)pm->cmd.serverTime);
  for (i = 0; i < plen; i++) h = fnv_byte(h, (unsigned char)ptext[i]);
  return h;
}

/* what the scenarios reach (printed on stderr by golden) */
static int cov_event[256], cov_flags, cov_wl[4], cov_maxtouch, cov_type[8], cov_ground[3];
static unsigned cov_eflags;

static void run_scenario(const scn_t *s, FILE *out, int dump) {
  playerState_t ps;
  pmove_t pm;
  int t, gi, k, i, count = 0;
  memcpy(&ps, s->ps, sizeof(ps));
  c_pmove = 0;
  plen = 0;
  t = ps.commandTime;
  if (!dump) fprintf(out, "H");
  for (gi = 0; gi < s->nseg; gi++) {
    const seg_t *g = &s->seg[gi];
    for (k = 0; k < g->count; k++) {
      t += g->msec;
      memset(&pm, 0, sizeof(pm));
      pm.ps = &ps;
      pm.cmd.serverTime = t;
      for (i = 0; i < 3; i++) pm.cmd.angles[i] = g->a0[i] + k * g->da[i];
      pm.cmd.buttons = g->buttons;
      pm.cmd.weapon = (byte)g->weapon;
      pm.cmd.forwardmove = (signed char)g->f;
      pm.cmd.rightmove = (signed char)g->r;
      pm.cmd.upmove = (signed char)g->u;
      pm.tracemask = s->tracemask;
      pm.debugLevel = s->debug;
      pm.noFootsteps = s->nofoot;
      pm.gauntletHit = s->gaunt;
      pm.pmove_fixed = s->fixed;
      pm.pmove_msec = s->fixmsec;
      pm.trace = wtrace;
      pm.pointcontents = wpointcontents;
      plen = 0;
      {
        int seq0 = ps.eventSequence, q;
        Pmove(&pm);
        for (q = seq0; q < ps.eventSequence && q < seq0 + 2; q++) cov_event[ps.events[q & 1] & 255]++;
      }
      cov_flags |= ps.pm_flags;
      cov_eflags |= ps.eFlags;
      cov_wl[pm.waterlevel & 3]++;
      if (pm.numtouch > cov_maxtouch) cov_maxtouch = pm.numtouch;
      cov_type[ps.pm_type & 7]++;
      cov_ground[ps.groundEntityNum == ENTITYNUM_NONE ? 0 : ps.groundEntityNum == ENTITYNUM_WORLD ? 1 : 2]++;
      if (dump) {
        const uint32_t *w = (const uint32_t *)&ps;
        fprintf(out, "C %d t=%d\nW", count, t);
        for (i = 0; i < NWORDS; i++) {
          if (w[i]) fprintf(out, " %d:%08x", i, w[i]);
        }
        fprintf(out, "\nO touch=%d", pm.numtouch);
        for (i = 0; i < pm.numtouch; i++) fprintf(out, ",%d", pm.touchents[i]);
        fprintf(out, " mins=%08x,%08x,%08x maxs=%08x,%08x,%08x wt=%d wl=%d xy=%08x cmd=%d,%d,%d,%d text=[%s]\n",
                fbits(pm.mins[0]), fbits(pm.mins[1]), fbits(pm.mins[2]), fbits(pm.maxs[0]), fbits(pm.maxs[1]),
                fbits(pm.maxs[2]), pm.watertype, pm.waterlevel, fbits(pm.xyspeed), pm.cmd.buttons,
                (int)pm.cmd.forwardmove, (int)pm.cmd.rightmove, (int)pm.cmd.upmove, ptext);
      } else {
        fprintf(out, " %08x", state_hash(&ps, &pm));
        if (count % 16 == 15) fprintf(out, "\nH");
      }
      count++;
    }
  }
  if (!dump) fprintf(out, "\n");
}

static void write_scenario(const scn_t *s, int id, FILE *out) {
  int i;
  fprintf(out, "SCENARIO %d %s %d %d %d %d %d %d %d\n", id, s->name, s->tracemask, s->nofoot, s->gaunt, s->fixed,
          s->fixmsec, s->debug, s->nseg);
  fprintf(out, "PS");
  for (i = 0; i < NWORDS; i++) {
    if (s->ps[i]) fprintf(out, " %d:%x", i, s->ps[i]);
  }
  fprintf(out, "\n");
  for (i = 0; i < s->nseg; i++) {
    const seg_t *g = &s->seg[i];
    fprintf(out, "SEG %d %d %d %d %d %d %d %d %d %d %d %d %d\n", g->count, g->msec, g->f, g->r, g->u, g->buttons,
            g->weapon, g->a0[0], g->a0[1], g->a0[2], g->da[0], g->da[1], g->da[2]);
  }
}

int main(int argc, char **argv) {
  int id, i, j, nscn;
  static scn_t scn;
  _Static_assert(sizeof(playerState_t) == 468, "playerState_t");
  build_world();
  nscn = NMODES * PER_MODE;
  if (argc >= 3 && strcmp(argv[1], "dump") == 0) {
    id = atoi(argv[2]);
    make_scenario(&scn, id);
    run_scenario(&scn, stdout, 1);
    return 0;
  }
  printf("# golden of the player movement of Quake III Arena (bg_pmove.c, bg_slidemove.c), issue #127\n");
  printf("# produced by Tools/Verifica/127 (pmgen.c); floats are written as bits in hex\n");
  printf("ITEMS %d", bg_numItems);
  for (i = 0; i < bg_numItems; i++) printf(" %d", bg_itemlist[i].giTag);
  printf("\n");
  /* the constants whose bits the Pascal side checks */
  printf("CONST");
  for (i = 1; i <= 200; i++) {
    double m = i * 0.001;
    printf(" %x", fbits((float)m));
  }
  printf("\n");
  {
    /* SHORT2ANGLE of every short, folded in one hash (PM_UpdateViewAngles) */
    uint32_t h = 2166136261u;
    int s;
    for (s = -32768; s < 32768; s++) {
      float f = SHORT2ANGLE((short)s);
      h = fnv_word(h, fbits(f));
    }
    printf("ANGLEHASH %08x\n", h);
  }
  for (i = 0; i < nW; i++) {
    printf("BRUSH %d %d %d %d", W[i].contents, W[i].surf, W[i].ent, W[i].np);
    for (j = 0; j < W[i].np; j++) {
      printf(" %x %x %x %x", fbits(W[i].n[j][0]), fbits(W[i].n[j][1]), fbits(W[i].n[j][2]), fbits(W[i].d[j]));
    }
    printf("\n");
  }
  printf("SCENARIOS %d\n", nscn);
  for (id = 0; id < nscn; id++) {
    make_scenario(&scn, id);
    write_scenario(&scn, id, stdout);
    run_scenario(&scn, stdout, 0);
    printf("END\n");
  }
  {
    int e;
    fprintf(stderr, "events:");
    for (e = 0; e < 256; e++) if (cov_event[e]) fprintf(stderr, " %d:%d", e, cov_event[e]);
    fprintf(stderr, "\npm_flags seen: %x eflags: %x waterlevels: %d %d %d %d maxtouch %d types: ", cov_flags, cov_eflags,
            cov_wl[0], cov_wl[1], cov_wl[2], cov_wl[3], cov_maxtouch);
    for (e = 0; e < 7; e++) fprintf(stderr, "%d ", cov_type[e]);
    fprintf(stderr, "ground none/world/ent: %d %d %d\n", cov_ground[0], cov_ground[1], cov_ground[2]);
  }
  return 0;
}
