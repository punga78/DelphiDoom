/* Parity driver of the issue #119, second part: the shader time functions of Quake III (tr_shade_calc.c).
   Includes, unchanged, renderer/tr_noise.c, renderer/tr_shade.c and renderer/tr_shade_calc.c, so that the functions
   that run are the real ones (EvalWaveForm, RB_CalcWaveColor, RB_DeformTessGeometry, ComputeTexCoords ...); the
   function tables are filled with the loop of R_Init (tr_init.c, copied literally below: R_Init itself needs the
   whole renderer). The OpenGL entry points and everything the renderer would give are never called: the link ignores
   the unresolved symbols.
   Scenario lines (one command each, read from the file of the first argument):
     shadertime <f>, time <int>, identity <f>, view <x> <y> <z>
     entity none | <r> <g> <b> <a> <s> <t>
     verts <n> <seed>                      xyz, normals and two sets of texture coordinates from a small generator
     evalwave <func> <base> <amp> <phase> <freq>
     wavecolor / wavealpha <func> <base> <amp> <phase> <freq>
     entcolor | entonecolor | entalpha | entonealpha
     deform <type> <func> <base> <amp> <phase> <freq> <spread> <bulgeW> <bulgeH> <bulgeSpeed> <mx> <my> <mz>
     tcgen <identity|texture|lightmap|vector|env>, tcvec <ax ay az bx by bz>, clearmods
     texmod turb|stretch <func> <base> <amp> <phase> <freq> | scroll <s> <t> | scale <s> <t> | rotate <degs>
            | transform <m00> <m01> <m10> <m11> <t0> <t1> | entity
     compute                               ComputeTexCoords on the stage built so far
   The dump: every float as the hexadecimal bits, bytes as numbers. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>
/* q_shared.h defines M_PI as a float ("matches value in gcc v2 math.h") only if math.h has not defined it: the
   MSVC math.h does not, the mingw one defines a double, and the sine table of R_Init then differs in the last bit
   for 656 of its 1024 entries. The Windows build of the game, which the Delphi classes follow, has the float. */
#include <math.h>
#undef M_PI
#define M_PI 3.14159265358979323846f
#include "tr_noise.c"
#include "tr_shade.c"
#include "tr_shade_calc.c"

trGlobals_t tr;
backEndState_t backEnd;
glconfig_t glConfig;
refimport_t ri;
backEndData_t *backEndData[SMP_FRAMES];

static jmp_buf g_drop;
static trRefEntity_t g_entity;
static shader_t g_shader;
static shaderStage_t g_stage;
static texModInfo_t g_mods[TR_MAX_TEXMODS];

void QDECL Com_Printf(const char *fmt, ...) {}
void QDECL Com_Error(int level, const char *fmt, ...) { printf("com_error\n"); exit(2); }
void Com_Memset(void *dest, const int val, const size_t count) { memset(dest, val, count); }
void Com_Memcpy(void *dest, const void *src, const size_t count) { memcpy(dest, src, count); }

static void QDECL RI_Error(int level, const char *fmt, ...) { longjmp(g_drop, 1); }
static void QDECL RI_Printf(int level, const char *fmt, ...) {}

static void bits(float f) {
	unsigned u;
	memcpy(&u, &f, 4);
	printf(" %08x", u);
}

/* tr_init.c, R_Init: "init function tables" */
static void init_tables(void) {
	int i;
	for (i = 0; i < FUNCTABLE_SIZE; i++) {
		tr.sinTable[i] = sin(DEG2RAD(i * 360.0f / ((float)(FUNCTABLE_SIZE - 1))));
		tr.squareTable[i] = (i < FUNCTABLE_SIZE / 2) ? 1.0f : -1.0f;
		tr.sawToothTable[i] = (float)i / FUNCTABLE_SIZE;
		tr.inverseSawToothTable[i] = 1.0f - tr.sawToothTable[i];
		if (i < FUNCTABLE_SIZE / 2) {
			if (i < FUNCTABLE_SIZE / 4) {
				tr.triangleTable[i] = (float)i / (FUNCTABLE_SIZE / 4);
			} else {
				tr.triangleTable[i] = 1.0f - tr.triangleTable[i - FUNCTABLE_SIZE / 4];
			}
		} else {
			tr.triangleTable[i] = -tr.triangleTable[i - FUNCTABLE_SIZE / 2];
		}
	}
}

static unsigned g_seed;
static int next_r(void) {
	g_seed = g_seed * 1103515245u + 12345u;
	return (int)((g_seed >> 16) & 0x7fff);
}

static void gen_verts(int n, unsigned seed) {
	int i, k;
	g_seed = seed;
	tess.numVertexes = n;
	for (i = 0; i < n; i++) {
		for (k = 0; k < 3; k++) tess.xyz[i][k] = (float)(next_r() - 16384) / 256.0f;
		tess.xyz[i][3] = 1.0f;
		for (k = 0; k < 3; k++) tess.normal[i][k] = (float)(next_r() - 16384) / 16384.0f;
		tess.normal[i][3] = 0.0f;
		for (k = 0; k < 4; k++) ((float *)tess.texCoords[i])[k] = (float)(next_r() - 16384) / 8192.0f;
	}
}

static void fillwave(waveForm_t *w, char **tok) {
	w->func = (genFunc_t)atoi(tok[0]);
	w->base = (float)atof(tok[1]);
	w->amplitude = (float)atof(tok[2]);
	w->phase = (float)atof(tok[3]);
	w->frequency = (float)atof(tok[4]);
}

static void dump_xyz(const char *label) {
	int i;
	printf("%s\n", label);
	for (i = 0; i < tess.numVertexes; i++) {
		printf(" v%d", i);
		bits(tess.xyz[i][0]); bits(tess.xyz[i][1]); bits(tess.xyz[i][2]);
		bits(tess.normal[i][0]); bits(tess.normal[i][1]); bits(tess.normal[i][2]);
		printf("\n");
	}
}

static void dump_colors(const char *label, const unsigned char *c, int bytes) {
	int i, k;
	printf("%s\n", label);
	for (i = 0; i < tess.numVertexes; i++) {
		printf(" c%d", i);
		for (k = 0; k < bytes; k++) printf(" %d", c[i * 4 + k]);
		printf("\n");
	}
}

static void dump_st(const char *label) {
	int i;
	printf("%s\n", label);
	for (i = 0; i < tess.numVertexes; i++) {
		printf(" t%d", i);
		bits(tess.svars.texcoords[0][i][0]); bits(tess.svars.texcoords[0][i][1]);
		printf("\n");
	}
}

static int split(char *line, char **tok, int max) {
	int n = 0;
	char *p = strtok(line, " \t");
	while (p && n < max) { tok[n++] = p; p = strtok(NULL, " \t"); }
	return n;
}

static void command(char *line) {
	char *tok[32];
	int n = split(line, tok, 32);
	static unsigned char colors[SHADER_MAX_VERTEXES * 4];
	int i;
	if (n == 0) return;
	printf("> %s", tok[0]);
	for (i = 1; i < n; i++) printf(" %s", tok[i]);
	printf("\n");
	if (!strcmp(tok[0], "shadertime")) tess.shaderTime = (float)atof(tok[1]);
	else if (!strcmp(tok[0], "time")) backEnd.refdef.time = atoi(tok[1]);
	else if (!strcmp(tok[0], "identity")) tr.identityLight = (float)atof(tok[1]);
	else if (!strcmp(tok[0], "view")) {
		backEnd.or.viewOrigin[0] = (float)atof(tok[1]);
		backEnd.or.viewOrigin[1] = (float)atof(tok[2]);
		backEnd.or.viewOrigin[2] = (float)atof(tok[3]);
	}
	else if (!strcmp(tok[0], "entity")) {
		if (!strcmp(tok[1], "none")) backEnd.currentEntity = NULL;
		else {
			backEnd.currentEntity = &g_entity;
			for (i = 0; i < 4; i++) g_entity.e.shaderRGBA[i] = (byte)atoi(tok[1 + i]);
			g_entity.e.shaderTexCoord[0] = (float)atof(tok[5]);
			g_entity.e.shaderTexCoord[1] = (float)atof(tok[6]);
		}
	}
	else if (!strcmp(tok[0], "verts")) gen_verts(atoi(tok[1]), (unsigned)atoi(tok[2]));
	else if (!strcmp(tok[0], "evalwave")) {
		waveForm_t w;
		float value, clamped;
		if (setjmp(g_drop) == 0) {
			fillwave(&w, tok + 1);
			value = EvalWaveForm(&w);
			clamped = EvalWaveFormClamped(&w);
			printf(" eval"); bits(value); printf(" clamped"); bits(clamped); printf("\n");
		} else printf(" error\n");
	}
	else if (!strcmp(tok[0], "wavecolor") || !strcmp(tok[0], "wavealpha")) {
		waveForm_t w;
		memset(colors, 7, sizeof(colors));
		if (setjmp(g_drop) == 0) {
			fillwave(&w, tok + 1);
			if (tok[0][4] == 'c') RB_CalcWaveColor(&w, colors); else RB_CalcWaveAlpha(&w, colors);
			dump_colors(" result", colors, 4);
		} else printf(" error\n");
	}
	else if (!strcmp(tok[0], "entcolor") || !strcmp(tok[0], "entonecolor") || !strcmp(tok[0], "entalpha") ||
		!strcmp(tok[0], "entonealpha")) {
		memset(colors, 7, sizeof(colors));
		if (!strcmp(tok[0], "entcolor")) RB_CalcColorFromEntity(colors);
		else if (!strcmp(tok[0], "entonecolor")) RB_CalcColorFromOneMinusEntity(colors);
		else if (!strcmp(tok[0], "entalpha")) RB_CalcAlphaFromEntity(colors);
		else RB_CalcAlphaFromOneMinusEntity(colors);
		/* RB_CalcColorFromOneMinusEntity writes invModulate[3] of an array of 3: the fourth byte is not defined */
		dump_colors(" result", colors, !strcmp(tok[0], "entonecolor") ? 3 : 4);
	}
	else if (!strcmp(tok[0], "deform")) {
		deformStage_t *d = &g_shader.deforms[0];
		memset(d, 0, sizeof(*d));
		d->deformation = (deform_t)atoi(tok[1]);
		fillwave(&d->deformationWave, tok + 2);
		d->deformationSpread = (float)atof(tok[7]);
		d->bulgeWidth = (float)atof(tok[8]);
		d->bulgeHeight = (float)atof(tok[9]);
		d->bulgeSpeed = (float)atof(tok[10]);
		d->moveVector[0] = (float)atof(tok[11]);
		d->moveVector[1] = (float)atof(tok[12]);
		d->moveVector[2] = (float)atof(tok[13]);
		g_shader.numDeforms = 1;
		tess.shader = &g_shader;
		if (setjmp(g_drop) == 0) {
			RB_DeformTessGeometry();
			dump_xyz(" result");
		} else printf(" error\n");
	}
	else if (!strcmp(tok[0], "tcgen")) {
		textureBundle_t *b = &g_stage.bundle[0];
		if (!strcmp(tok[1], "identity")) b->tcGen = TCGEN_IDENTITY;
		else if (!strcmp(tok[1], "texture")) b->tcGen = TCGEN_TEXTURE;
		else if (!strcmp(tok[1], "lightmap")) b->tcGen = TCGEN_LIGHTMAP;
		else if (!strcmp(tok[1], "vector")) b->tcGen = TCGEN_VECTOR;
		else b->tcGen = TCGEN_ENVIRONMENT_MAPPED;
	}
	else if (!strcmp(tok[0], "tcvec")) {
		for (i = 0; i < 6; i++) g_stage.bundle[0].tcGenVectors[i / 3][i % 3] = (float)atof(tok[1 + i]);
	}
	else if (!strcmp(tok[0], "clearmods")) g_stage.bundle[0].numTexMods = 0;
	else if (!strcmp(tok[0], "texmod")) {
		textureBundle_t *b = &g_stage.bundle[0];
		texModInfo_t *t = &b->texMods[b->numTexMods++];
		memset(t, 0, sizeof(*t));
		if (!strcmp(tok[1], "turb")) { t->type = TMOD_TURBULENT; fillwave(&t->wave, tok + 2); }
		else if (!strcmp(tok[1], "stretch")) { t->type = TMOD_STRETCH; fillwave(&t->wave, tok + 2); }
		else if (!strcmp(tok[1], "scroll")) {
			t->type = TMOD_SCROLL; t->scroll[0] = (float)atof(tok[2]); t->scroll[1] = (float)atof(tok[3]);
		}
		else if (!strcmp(tok[1], "scale")) {
			t->type = TMOD_SCALE; t->scale[0] = (float)atof(tok[2]); t->scale[1] = (float)atof(tok[3]);
		}
		else if (!strcmp(tok[1], "rotate")) { t->type = TMOD_ROTATE; t->rotateSpeed = (float)atof(tok[2]); }
		else if (!strcmp(tok[1], "transform")) {
			t->type = TMOD_TRANSFORM;
			t->matrix[0][0] = (float)atof(tok[2]); t->matrix[0][1] = (float)atof(tok[3]);
			t->matrix[1][0] = (float)atof(tok[4]); t->matrix[1][1] = (float)atof(tok[5]);
			t->translate[0] = (float)atof(tok[6]); t->translate[1] = (float)atof(tok[7]);
		}
		else if (!strcmp(tok[1], "entity")) t->type = TMOD_ENTITY_TRANSLATE;
	}
	else if (!strcmp(tok[0], "compute")) {
		memset(tess.svars.texcoords, 0, sizeof(tess.svars.texcoords[0][0]) * tess.numVertexes);
		if (setjmp(g_drop) == 0) {
			ComputeTexCoords(&g_stage);
			dump_st(" result");
		} else printf(" error\n");
	}
}

int main(int argc, char **argv) {
	char line[1024];
	FILE *f;
	if (argc < 2) return 1;
	setvbuf(stdout, NULL, _IONBF, 0);
	f = fopen(argv[1], "r");
	if (!f) return 1;
	ri.Printf = RI_Printf;
	ri.Error = RI_Error;
	tess.shader = &g_shader;
	init_tables();
	R_NoiseInit();
	tr.identityLight = 1.0f;
	g_stage.bundle[0].tcGen = TCGEN_TEXTURE;
	g_stage.bundle[0].texMods = g_mods;
	while (fgets(line, sizeof(line), f)) {
		int n = (int)strlen(line);
		while (n > 0 && (line[n - 1] == '\n' || line[n - 1] == '\r')) line[--n] = 0;
		if (line[0] == '#') continue;
		command(line);
	}
	return 0;
}
