/* Parity driver of the issue #125: reads menu files and runs scripts with the REAL code of
   ui_shared.c (the parser of Team Arena menus, Item_RunScript and the script handlers), the real
   botlib precompiler (l_script.c, l_precomp.c) that the "trap_PC_*" calls of the ui module reach,
   and the real Asset_Parse / UI_ParseMenu / UI_LoadMenus of ui_main.c and RE_RegisterFont of
   tr_font.c (the .dat branch), cut out of the sources by build.sh.
   The display context is a stub that records what the engine would have been asked.

   usage: uiparse <root folder> <scenario file>
   scenario lines (blank lines and lines starting with # are skipped):
     menu <path>                 UI_ParseMenu
     menus <path>                UI_LoadMenus (loadmenu list)
     font <pointsize>            RE_RegisterFont, then a dump of the font
     run <menu> <item|-> <text>  Item_RunScript on the item (- : an item that is not in the menu)
     dump                        every menu, in full
     state                       the window state of every menu and item
     reset                       Menu_Reset
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "../game/q_shared.h"
#include "../game/botlib.h"
#include "../botlib/be_interface.h"
#include "ui_shared.h"

char g_root[512];
extern botlib_import_t botimport;
void InitBotImport(void);
void Menu_UpdatePosition(menuDef_t *menu);
itemDef_t *Menu_FindItemByName(menuDef_t *menu, const char *p);
void Item_RunScript(itemDef_t *item, const char *s);

void LogLine(const char *fmt, ...) {
	char buf[8192];
	va_list ap;
	char *p;
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	/* messages end with a new line of their own: print them as one line each */
	for (p = buf + strlen(buf); p > buf && (p[-1] == '\n' || p[-1] == '\r'); ) *--p = 0;
	printf("log %s\n", buf);
}

/* ------------------------------------------------------------------ display context stub */

#define MAX_NAMES 256
typedef struct { char name[128]; } nameEntry_t;
static nameEntry_t shaders[MAX_NAMES], models[MAX_NAMES], sounds[MAX_NAMES];
static int shaderCount, modelCount, soundCount;

static int Register(nameEntry_t *table, int *count, const char *name) {
	int i;
	for (i = 0; i < *count; i++) if (strcmp(table[i].name, name) == 0) return i + 1;
	strncpy(table[*count].name, name, 127);
	return ++*count;
}

static qhandle_t DC_registerShaderNoMip(const char *p) {
	int h = Register(shaders, &shaderCount, p);
	printf("reg shader %d \"%s\"\n", h, p);
	return h;
}
static qhandle_t DC_registerModel(const char *p) {
	int h = Register(models, &modelCount, p);
	printf("reg model %d \"%s\"\n", h, p);
	return h;
}
static sfxHandle_t DC_registerSound(const char *name, qboolean compressed) {
	int h = Register(sounds, &soundCount, name);
	printf("reg sound %d \"%s\" %d\n", h, name, compressed);
	return h;
}
void RE_RegisterFont(const char *fontName, int pointSize, fontInfo_t *font);
static void DC_registerFont(const char *p, int pointSize, fontInfo_t *font) {
	RE_RegisterFont(p, pointSize, font);
}
static void DC_getTeamColor(vec4_t *color) {
	(*color)[0] = 0.25f; (*color)[1] = 0.5f; (*color)[2] = 0.75f; (*color)[3] = 1.0f;
}
/* the cvars of the input scenarios ("cvar name value"); a name that is not in the table behaves as before */
#define MAX_CVARS 32
static struct { char name[64]; char value[1024]; } cvarTable[MAX_CVARS];
static int cvarCount;
static int FindCvar(const char *name) {
	int i;
	for (i = 0; i < cvarCount; i++) if (strcmp(cvarTable[i].name, name) == 0) return i;
	return -1;
}
static float DC_getCVarValue(const char *cvar) {
	int i = FindCvar(cvar);
	if (i >= 0) return (float)atof(cvarTable[i].value);
	return strcmp(cvar, "zero") == 0 ? 0.0f : 1.0f;
}
static void DC_setCVar(const char *cvar, const char *value) {
	int i = FindCvar(cvar);
	printf("host setcvar \"%s\" \"%s\"\n", cvar, value);
	if (i >= 0) { strncpy(cvarTable[i].value, value, 1023); cvarTable[i].value[1023] = 0; }
}
static void DC_getCVarString(const char *cvar, char *buffer, int bufsize) {
	int i = FindCvar(cvar);
	if (i >= 0) { strncpy(buffer, cvarTable[i].value, bufsize - 1); buffer[bufsize - 1] = 0; }
	else buffer[0] = 0;
}
static qboolean overstrike;
static qboolean DC_getOverstrikeMode(void) { return overstrike; }
static void DC_setOverstrikeMode(qboolean b) { overstrike = b; printf("host overstrike %d\n", (int)b); }
static qboolean DC_ownerDrawHandleKey(int ownerDraw, int flags, float *special, int key) {
	printf("host ownerdraw %d %d %d\n", ownerDraw, flags, key);
	return key == 13;
}
#define MAX_FEEDERS 8
static int feederCounts[MAX_FEEDERS];
static int DC_feederCount(float feederID) {
	int id = (int)feederID;
	return (id >= 0 && id < MAX_FEEDERS) ? feederCounts[id] : 0;
}
static void DC_feederSelection(float feederID, int index) { printf("host feeder %d %d\n", (int)feederID, index); }
static void DC_Pause(qboolean b) { printf("host pause %d\n", (int)b); }
static void DC_executeText(int when, const char *text) { printf("host exec %d \"%s\"\n", when, text); }
static void DC_startLocalSound(sfxHandle_t sfx, int channel) { printf("host sound %d %d\n", sfx, channel); }
static void DC_stopBackgroundTrack(void) { printf("host stopbackground\n"); }
static void DC_startBackgroundTrack(const char *intro, const char *loop) { printf("host background \"%s\" \"%s\"\n", intro, loop); }
static void DC_stopCinematic(int handle) { printf("host stopcinematic %d\n", handle); }
static void DC_Print(const char *msg, ...) {
	char buf[4096];
	va_list ap;
	va_start(ap, msg);
	vsnprintf(buf, sizeof(buf), msg, ap);
	va_end(ap);
	LogLine("dc %s", buf);
}
/* a command that Item_RunScript does not know: the host takes its arguments up to the next ";" */
static void DC_runScript(char **p) {
	printf("host command");
	for (;;) {
		char *q = *p;
		char *token = COM_ParseExt(&q, qfalse);
		if (!token[0] || strcmp(token, ";") == 0) break;
		printf(" \"%s\"", token);
		*p = q;
	}
	printf("\n");
}



/* ------------------------------------------------------------------ real code cut out of ui_main.c and tr_font.c */

static struct { displayContextDef_t uiDC; } uiInfo;
#define dc (uiInfo.uiDC)
vmCvar_t ui_new;
void trap_Error(const char *string) { printf("trap_error \"%s\"\n", string); }
int trap_Milliseconds(void) { return 0; }
void trap_R_RegisterFont(const char *fontName, int pointSize, void *font) { RE_RegisterFont(fontName, pointSize, (fontInfo_t *)font); }
qhandle_t trap_R_RegisterShaderNoMip(const char *name) { return DC_registerShaderNoMip(name); }
sfxHandle_t trap_S_RegisterSound(const char *sample, qboolean compressed) { return DC_registerSound(sample, compressed); }

#include "ui_main_original.inc"

/* renderer services of RE_RegisterFont */
static struct {
	void (*Printf)(int level, const char *fmt, ...);
	int (*FS_ReadFile)(const char *name, void **buf);
} ri;
#define PRINT_ALL 0
static void RI_Printf(int level, const char *fmt, ...) {
	char buf[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	LogLine("%s", buf);
}
static int RI_ReadFile(const char *name, void **buf) {
	char path[1024];
	FILE *f;
	int len;
	snprintf(path, sizeof(path), "%s/%s", g_root, name);
	f = fopen(path, "rb");
	if (!f) return -1;
	fseek(f, 0, SEEK_END);
	len = (int)ftell(f);
	fseek(f, 0, SEEK_SET);
	if (buf) {
		*buf = malloc(len);
		fread(*buf, 1, len, f);
	}
	fclose(f);
	return len;
}
static void R_SyncRenderThread(void) {}
static qhandle_t RE_RegisterShaderNoMip(const char *name) { return DC_registerShaderNoMip(name); }
#define Com_Memcpy memcpy
#include "tr_font_original.inc"

/* ------------------------------------------------------------------ dump */

static void P(const char *name, float f) {
	unsigned int u;
	memcpy(&u, &f, 4);
	printf(" %s=%08x", name, u);
}
static void PI(const char *name, int i) { printf(" %s=%d", name, i); }
static void PS(const char *name, const char *s) {
	const unsigned char *c = (const unsigned char *)(s ? s : "");
	printf(" %s=\"", name);
	for (; *c; c++) {
		if (*c == '\\' || *c == '"') printf("\\%c", *c);
		else if (*c < 32 || *c > 126) printf("\\x%02x", *c);
		else putchar(*c);
	}
	putchar('"');
}
static void PR(const char *name, rectDef_t *r) {
	printf(" %s=", name);
	{
		float v[4] = { r->x, r->y, r->w, r->h };
		int i;
		for (i = 0; i < 4; i++) {
			unsigned int u;
			memcpy(&u, &v[i], 4);
			printf(i ? ",%08x" : "%08x", u);
		}
	}
}
static void PC(const char *name, vec4_t c) {
	int i;
	printf(" %s=", name);
	for (i = 0; i < 4; i++) {
		unsigned int u;
		memcpy(&u, &c[i], 4);
		printf(i ? ",%08x" : "%08x", u);
	}
}

static void DumpWindowState(windowDef_t *w) {
	PR("rect", &w->rect);
	PR("rectClient", &w->rectClient);
	PI("flags", w->flags);
	PR("rectEffects", &w->rectEffects);
	PR("rectEffects2", &w->rectEffects2);
	PI("offsetTime", w->offsetTime);
	PC("foreColor", w->foreColor);
	PC("backColor", w->backColor);
	PC("borderColor", w->borderColor);
	PI("background", w->background);
	PI("cinematic", w->cinematic);
	printf("\n");
}

static void DumpWindow(windowDef_t *w) {
	PS("name", w->name);
	PS("group", w->group);
	PS("cinematicName", w->cinematicName);
	PI("cinematic", w->cinematic);
	PI("style", w->style);
	PI("border", w->border);
	PI("ownerDraw", w->ownerDraw);
	PI("ownerDrawFlags", w->ownerDrawFlags);
	P("borderSize", w->borderSize);
	PI("flags", w->flags);
	printf("\n    ");
	PR("rect", &w->rect);
	PR("rectClient", &w->rectClient);
	PR("rectEffects", &w->rectEffects);
	PR("rectEffects2", &w->rectEffects2);
	PI("offsetTime", w->offsetTime);
	PI("nextTime", w->nextTime);
	printf("\n    ");
	PC("foreColor", w->foreColor);
	PC("backColor", w->backColor);
	PC("borderColor", w->borderColor);
	PC("outlineColor", w->outlineColor);
	PI("background", w->background);
	printf("\n");
}

static void DumpItem(int index, itemDef_t *item) {
	int i;
	printf("  item %d\n   window", index);
	DumpWindow(&item->window);
	printf("   ");
	PR("textRect", &item->textRect);
	PI("type", item->type);
	PI("alignment", item->alignment);
	PI("textalignment", item->textalignment);
	P("textalignx", item->textalignx);
	P("textaligny", item->textaligny);
	P("textscale", item->textscale);
	PI("textStyle", item->textStyle);
	PI("asset", item->asset);
	PI("focusSound", item->focusSound);
	P("special", item->special);
	PI("cursorPos", item->cursorPos);
	PI("cvarFlags", item->cvarFlags);
	printf("\n   ");
	PS("text", item->text);
	PS("cvar", item->cvar);
	PS("cvarTest", item->cvarTest);
	PS("enableCvar", item->enableCvar);
	printf("\n   ");
	PS("mouseEnterText", item->mouseEnterText);
	PS("mouseExitText", item->mouseExitText);
	PS("mouseEnter", item->mouseEnter);
	PS("mouseExit", item->mouseExit);
	PS("action", item->action);
	PS("onFocus", item->onFocus);
	PS("leaveFocus", item->leaveFocus);
	printf("\n");
	PI("   numColors", item->numColors);
	printf("\n");
	for (i = 0; i < item->numColors; i++) {
		printf("   colorRange %d", i);
		P("low", item->colorRanges[i].low);
		P("high", item->colorRanges[i].high);
		PC("color", item->colorRanges[i].color);
		printf("\n");
	}
	if (item->typeData) {
		if (item->type == ITEM_TYPE_LISTBOX) {
			listBoxDef_t *l = (listBoxDef_t *)item->typeData;
			printf("   listbox");
			PI("startPos", l->startPos);
			PI("endPos", l->endPos);
			PI("drawPadding", l->drawPadding);
			PI("cursorPos", l->cursorPos);
			P("elementWidth", l->elementWidth);
			P("elementHeight", l->elementHeight);
			PI("elementStyle", l->elementStyle);
			PI("numColumns", l->numColumns);
			PS("doubleClick", l->doubleClick);
			PI("notselectable", l->notselectable);
			printf("\n");
			for (i = 0; i < MAX_LB_COLUMNS; i++) {
				if (l->columnInfo[i].pos || l->columnInfo[i].width || l->columnInfo[i].maxChars) {
					printf("   column %d", i);
					PI("pos", l->columnInfo[i].pos);
					PI("width", l->columnInfo[i].width);
					PI("maxChars", l->columnInfo[i].maxChars);
					printf("\n");
				}
			}
		} else if (item->type == ITEM_TYPE_EDITFIELD || item->type == ITEM_TYPE_NUMERICFIELD || item->type == ITEM_TYPE_YESNO ||
				   item->type == ITEM_TYPE_BIND || item->type == ITEM_TYPE_SLIDER || item->type == ITEM_TYPE_TEXT) {
			editFieldDef_t *e = (editFieldDef_t *)item->typeData;
			printf("   editfield");
			P("minVal", e->minVal);
			P("maxVal", e->maxVal);
			P("defVal", e->defVal);
			P("range", e->range);
			PI("maxChars", e->maxChars);
			PI("maxPaintChars", e->maxPaintChars);
			PI("paintOffset", e->paintOffset);
			printf("\n");
		} else if (item->type == ITEM_TYPE_MULTI) {
			multiDef_t *m = (multiDef_t *)item->typeData;
			printf("   multi");
			PI("count", m->count);
			PI("strDef", m->strDef);
			printf("\n");
			for (i = 0; i < m->count; i++) {
				printf("   entry %d", i);
				PS("cvar", m->cvarList[i]);
				PS("str", m->cvarStr[i]);
				P("value", m->cvarValue[i]);
				printf("\n");
			}
		} else if (item->type == ITEM_TYPE_MODEL) {
			modelDef_t *m = (modelDef_t *)item->typeData;
			printf("   model");
			P("o0", m->origin[0]);
			P("o1", m->origin[1]);
			P("o2", m->origin[2]);
			P("fov_x", m->fov_x);
			P("fov_y", m->fov_y);
			PI("rotationSpeed", m->rotationSpeed);
			/* the angle is rand() % 360: not compared */
			printf("\n");
		}
	}
}

static void DumpMenu(int index, menuDef_t *menu) {
	int i;
	printf("menu %d\n window", index);
	DumpWindow(&menu->window);
	printf(" ");
	PS("font", menu->font);
	PI("fullScreen", menu->fullScreen);
	PI("itemCount", menu->itemCount);
	PI("fontIndex", menu->fontIndex);
	PI("cursorItem", menu->cursorItem);
	PI("fadeCycle", menu->fadeCycle);
	P("fadeClamp", menu->fadeClamp);
	P("fadeAmount", menu->fadeAmount);
	printf("\n ");
	PS("onOpen", menu->onOpen);
	PS("onClose", menu->onClose);
	PS("onESC", menu->onESC);
	PS("soundName", menu->soundName);
	PC("focusColor", menu->focusColor);
	PC("disableColor", menu->disableColor);
	printf("\n");
	for (i = 0; i < menu->itemCount; i++) DumpItem(i, menu->items[i]);
}

static void DumpAll(void) {
	int i;
	printf("menus %d\n", Menu_Count());
	for (i = 0; i < Menu_Count(); i++) {
		extern menuDef_t Menus[MAX_MENUS];
		DumpMenu(i, &Menus[i]);
	}
	printf("assets");
	P("fadeClamp", dc.Assets.fadeClamp);
	PI("fadeCycle", dc.Assets.fadeCycle);
	P("fadeAmount", dc.Assets.fadeAmount);
	P("shadowX", dc.Assets.shadowX);
	P("shadowY", dc.Assets.shadowY);
	PC("shadowColor", dc.Assets.shadowColor);
	P("shadowFadeClamp", dc.Assets.shadowFadeClamp);
	PS("cursorStr", dc.Assets.cursorStr);
	PI("cursor", dc.Assets.cursor);
	PI("gradientBar", dc.Assets.gradientBar);
	PI("menuEnterSound", dc.Assets.menuEnterSound);
	PI("menuExitSound", dc.Assets.menuExitSound);
	PI("menuBuzzSound", dc.Assets.menuBuzzSound);
	PI("itemFocusSound", dc.Assets.itemFocusSound);
	PI("fontRegistered", dc.Assets.fontRegistered);
	printf("\n");
}

static void DumpState(void) {
	int i, j;
	extern menuDef_t Menus[MAX_MENUS];
	for (i = 0; i < Menu_Count(); i++) {
		printf("state menu %d", i);
		DumpWindowState(&Menus[i].window);
		for (j = 0; j < Menus[i].itemCount; j++) {
			printf("state item %d.%d", i, j);
			DumpWindowState(&Menus[i].items[j]->window);
		}
	}
}

static unsigned int Fnv(const void *data, int len) {
	const unsigned char *p = (const unsigned char *)data;
	unsigned int h = 2166136261u;
	while (len--) { h ^= *p++; h *= 16777619u; }
	return h;
}

static void DumpFont(const char *label, fontInfo_t *font) {
	int i;
	unsigned int h = 2166136261u;
	printf("font %s", label);
	PS("name", font->name);
	P("glyphScale", font->glyphScale);
	for (i = 0; i < 256; i++) {
		glyphInfo_t *g = &font->glyphs[i];
		h ^= Fnv(g, sizeof(glyphInfo_t));
		h *= 16777619u;
	}
	printf(" glyphs=%08x\n", h);
	for (i = 0; i < 256; i++) {
		glyphInfo_t *g = &font->glyphs[i];
		if (i == 0 || i == 32 || i == 65 || i == 200 || i == 254 || i == 255) {
			printf(" glyph %d", i);
			PI("height", g->height);
			PI("top", g->top);
			PI("bottom", g->bottom);
			PI("pitch", g->pitch);
			PI("xSkip", g->xSkip);
			PI("imageWidth", g->imageWidth);
			PI("imageHeight", g->imageHeight);
			P("s", g->s);
			P("t", g->t);
			P("s2", g->s2);
			P("t2", g->t2);
			PI("glyph", g->glyph);
			PS("shaderName", g->shaderName);
			printf("\n");
		}
	}
}

/* ------------------------------------------------------------------ the input scenarios */

/* the statics of ui_shared.c that build.sh makes global (objcopy) */
extern itemDef_t *itemCapture;
extern void (*captureFunc)(void *p);
extern void *captureData;
extern qboolean g_editingField;
extern itemDef_t *g_editItem;
extern qboolean debugMode;
extern menuDef_t *menuStack[];
extern int openMenuCount;
extern menuDef_t Menus[MAX_MENUS];
extern int menuCount;
void Item_Action(itemDef_t *item);
/* prototypes of the functions that ui_shared.h does not declare: without them the float arguments would be passed as doubles */
qboolean Item_SetFocus(itemDef_t *item, float x, float y);
itemDef_t *Menu_HitTest(menuDef_t *menu, float x, float y);
void Item_MouseEnter(itemDef_t *item, float x, float y);
void Item_MouseLeave(itemDef_t *item);
itemDef_t *Menu_SetNextCursorItem(menuDef_t *menu);
itemDef_t *Menu_SetPrevCursorItem(menuDef_t *menu);
void Menu_ScrollFeeder(menuDef_t *menu, int feeder, qboolean down);
void Menu_SetFeederSelection(menuDef_t *menu, int feeder, int index, const char *name);
void Menus_Activate(menuDef_t *menu);
menuDef_t *Menus_ActivateByName(const char *p);
void Menus_OpenByName(const char *p);
void Menus_ShowByName(const char *p);
void Menus_CloseByName(const char *p);
void Menus_CloseAll(void);
void Menu_HandleKey(menuDef_t *menu, int key, qboolean down);
void Display_HandleKey(int key, qboolean down, int x, int y);
qboolean Display_MouseMove(void *p, int x, int y);
void *Display_CaptureItem(int x, int y);
int Display_CursorType(int x, int y);
int Display_VisibleMenuCount(void);
qboolean Menus_AnyFullScreenVisible(void);
menuDef_t *Menu_GetFocused(void);

static const char *MenuName(menuDef_t *m) { return m ? m->window.name : "-"; }
static const char *ItemName(itemDef_t *i) { return i ? (i->window.name ? i->window.name : "") : "-"; }

static menuDef_t *FindMenu(const char *name) { return strcmp(name, "-") == 0 ? NULL : Menus_FindByName(name); }

static void DumpInput(void) {
	int i, j;
	printf("istate stack %d", openMenuCount);
	for (i = 0; i < openMenuCount; i++) printf(" %s", MenuName(menuStack[i]));
	printf(" capture %s editing %d edit %s overstrike %d debug %d\n", ItemName(itemCapture), (int)g_editingField,
		ItemName(g_editItem), (int)overstrike, (int)debugMode);
	for (i = 0; i < Menu_Count(); i++) {
		printf(" menu %s flags=%d cursorItem=%d rect=%08x,%08x\n", MenuName(&Menus[i]), Menus[i].window.flags,
			Menus[i].cursorItem, *(unsigned *)&Menus[i].window.rect.x, *(unsigned *)&Menus[i].window.rect.y);
		for (j = 0; j < Menus[i].itemCount; j++) {
			itemDef_t *it = Menus[i].items[j];
			int start = 0, lcursor = 0, paint = 0;
			if (it->type == ITEM_TYPE_LISTBOX) {
				listBoxDef_t *l = (listBoxDef_t *)it->typeData;
				start = l->startPos;
				lcursor = l->cursorPos;
			} else if (it->typeData && (it->type == ITEM_TYPE_EDITFIELD || it->type == ITEM_TYPE_NUMERICFIELD)) {
				paint = ((editFieldDef_t *)it->typeData)->paintOffset;
			}
			/* an item that is as the menu file left it (only visible) is not listed */
			if (it->window.flags == WINDOW_VISIBLE && !it->cursorPos && !start && !lcursor && !paint) continue;
			printf("  item %s flags=%d cursorPos=%d special=%08x", ItemName(it), it->window.flags, it->cursorPos,
				*(unsigned *)&it->special);
			if (it->type == ITEM_TYPE_LISTBOX) printf(" start=%d cursor=%d", start, lcursor);
			else if (it->type == ITEM_TYPE_EDITFIELD || it->type == ITEM_TYPE_NUMERICFIELD) printf(" paintOffset=%d", paint);
			printf("\n");
		}
	}
}

/* returns 1 if the line was an input command */
static int InputCommand(char *p) {
	char a[128], b[128], c[1024];
	int n1, n2, n3, n4, n5;
	float f1, f2, f3, f4;
	menuDef_t *m;
	itemDef_t *it;
	if (strcmp(p, "istate") == 0) { DumpInput(); return 1; }
	if (sscanf(p, "cursor %d %d", &n1, &n2) == 2) { dc.cursorx = n1; dc.cursory = n2; return 1; }
	if (sscanf(p, "time %d", &n1) == 1) { dc.realTime = n1; return 1; }
	if (sscanf(p, "feeder %d %d", &n1, &n2) == 2) { if (n1 >= 0 && n1 < MAX_FEEDERS) feederCounts[n1] = n2; return 1; }
	if (strncmp(p, "cvar ", 5) == 0) {
		char *sp;
		strncpy(a, p + 5, 127); a[127] = 0;
		sp = strchr(a, ' ');
		if (sp) { *sp++ = 0; strncpy(c, sp, 1023); c[1023] = 0; } else c[0] = 0;
		n1 = FindCvar(a);
		if (n1 < 0) { n1 = cvarCount++; strncpy(cvarTable[n1].name, a, 63); }
		strncpy(cvarTable[n1].value, c, 1023);
		return 1;
	}
	if (sscanf(p, "textrect %127s %127s %f %f %f %f", a, b, &f1, &f2, &f3, &f4) == 6) {
		m = Menus_FindByName(a);
		it = m ? Menu_FindItemByName(m, b) : NULL;
		if (it) { it->textRect.x = f1; it->textRect.y = f2; it->textRect.w = f3; it->textRect.h = f4; }
		return 1;
	}
	if (sscanf(p, "cinematic %127s %127s %d", a, b, &n1) == 3) {
		m = Menus_FindByName(a);
		it = m ? Menu_FindItemByName(m, b) : NULL;
		if (it) it->window.cinematic = n1;
		return 1;
	}
	if (sscanf(p, "activate %127s", a) == 1) { m = Menus_FindByName(a); if (m) Menus_Activate(m); DumpInput(); return 1; }
	if (sscanf(p, "open %127s", a) == 1) { Menus_OpenByName(a); DumpInput(); return 1; }
	if (sscanf(p, "show %127s", a) == 1) { Menus_ShowByName(a); DumpInput(); return 1; }
	if (sscanf(p, "closemenu %127s", a) == 1) { Menus_CloseByName(a); DumpInput(); return 1; }
	if (strcmp(p, "closeall") == 0) { Menus_CloseAll(); DumpInput(); return 1; }
	if (sscanf(p, "key %d %d", &n1, &n2) == 2) { Display_HandleKey(n1, n2, dc.cursorx, dc.cursory); DumpInput(); return 1; }
	if (sscanf(p, "menukey %127s %d %d", a, &n1, &n2) == 3) { Menu_HandleKey(FindMenu(a), n1, n2); DumpInput(); return 1; }
	if (sscanf(p, "move %d %d", &n1, &n2) == 2) { Display_MouseMove(NULL, n1, n2); DumpInput(); return 1; }
	if (sscanf(p, "drag %127s %d %d", a, &n1, &n2) == 3) { Display_MouseMove(FindMenu(a), n1, n2); DumpInput(); return 1; }
	if (strcmp(p, "capture") == 0) { if (captureFunc) captureFunc(captureData); DumpInput(); return 1; }
	if (sscanf(p, "focus %127s %127s", a, b) == 2) {
		m = Menus_FindByName(a);
		it = m ? Menu_FindItemByName(m, b) : NULL;
		n1 = it ? Item_SetFocus(it, (float)dc.cursorx, (float)dc.cursory) : -1;
		printf("result %d\n", n1);
		DumpInput();
		return 1;
	}
	if (sscanf(p, "next %127s", a) == 1) { m = Menus_FindByName(a); printf("result %s\n", ItemName(m ? Menu_SetNextCursorItem(m) : NULL)); DumpInput(); return 1; }
	if (sscanf(p, "prev %127s", a) == 1) { m = Menus_FindByName(a); printf("result %s\n", ItemName(m ? Menu_SetPrevCursorItem(m) : NULL)); DumpInput(); return 1; }
	if (strcmp(p, "visible") == 0) { printf("result %d\n", Display_VisibleMenuCount()); return 1; }
	if (strcmp(p, "fullscreen") == 0) { printf("result %d\n", (int)Menus_AnyFullScreenVisible()); return 1; }
	if (strcmp(p, "focused") == 0) { printf("result %s\n", MenuName(Menu_GetFocused())); return 1; }
	if (sscanf(p, "cursortype %d %d", &n1, &n2) == 2) { printf("result %d\n", Display_CursorType(n1, n2)); return 1; }
	if (sscanf(p, "captureitem %d %d", &n1, &n2) == 2) { printf("result %s\n", MenuName((menuDef_t *)Display_CaptureItem(n1, n2))); return 1; }
	if (sscanf(p, "hit %127s %f %f", a, &f1, &f2) == 3) { m = Menus_FindByName(a); printf("result %s\n", ItemName(m ? Menu_HitTest(m, f1, f2) : NULL)); return 1; }
	if (sscanf(p, "scrollfeeder %127s %d %d", a, &n1, &n2) == 3) { Menu_ScrollFeeder(Menus_FindByName(a), n1, n2); DumpInput(); return 1; }
	if (sscanf(p, "feedersel %127s %d %d %d", a, &n1, &n2, &n3) == 4) {
		/* feedersel <menu|-> <feeder> <index> <named 0|1> [name] */
		char name[128];
		name[0] = 0;
		if (n3) sscanf(p, "feedersel %127s %d %d %d %127s", a, &n1, &n2, &n3, name);
		Menu_SetFeederSelection(FindMenu(a), n1, n2, n3 ? name : NULL);
		DumpInput();
		return 1;
	}
	if (sscanf(p, "mouseenter %127s %127s %f %f", a, b, &f1, &f2) == 4) {
		m = Menus_FindByName(a);
		it = m ? Menu_FindItemByName(m, b) : NULL;
		Item_MouseEnter(it, f1, f2);
		DumpInput();
		return 1;
	}
	if (sscanf(p, "mouseleave %127s %127s", a, b) == 2) {
		m = Menus_FindByName(a);
		it = m ? Menu_FindItemByName(m, b) : NULL;
		Item_MouseLeave(it);
		DumpInput();
		return 1;
	}
	(void)n4; (void)n5; (void)f3; (void)f4;
	return 0;
}

int main(int argc, char **argv) {
	FILE *f;
	char line[4096];
	static fontInfo_t font;
	setvbuf(stdout, NULL, _IONBF, 0);
	if (argc < 3) { fprintf(stderr, "usage: uiparse <root> <scenario>\n"); return 2; }
	strncpy(g_root, argv[1], sizeof(g_root) - 1);
	InitBotImport();
	memset(&dc, 0, sizeof(dc));
	dc.registerShaderNoMip = DC_registerShaderNoMip;
	dc.registerModel = DC_registerModel;
	dc.registerSound = DC_registerSound;
	dc.registerFont = DC_registerFont;
	dc.getTeamColor = DC_getTeamColor;
	dc.getCVarValue = DC_getCVarValue;
	dc.setCVar = DC_setCVar;
	dc.executeText = DC_executeText;
	dc.startLocalSound = DC_startLocalSound;
	dc.stopBackgroundTrack = DC_stopBackgroundTrack;
	dc.startBackgroundTrack = DC_startBackgroundTrack;
	dc.stopCinematic = DC_stopCinematic;
	dc.Print = DC_Print;
	dc.runScript = DC_runScript;
	dc.getCVarString = DC_getCVarString;
	dc.getOverstrikeMode = DC_getOverstrikeMode;
	dc.setOverstrikeMode = DC_setOverstrikeMode;
	dc.ownerDrawHandleKey = DC_ownerDrawHandleKey;
	dc.feederCount = DC_feederCount;
	dc.feederSelection = DC_feederSelection;
	dc.Pause = DC_Pause;
	/* the defaults the engine gives its display context before it reads assets */
	dc.Assets.fadeClamp = 1.0f;
	dc.Assets.fadeCycle = 1;
	dc.Assets.fadeAmount = 0.1f;
	ri.Printf = RI_Printf;
	ri.FS_ReadFile = RI_ReadFile;
	Init_Display(&dc);
	/* String_Init + Item/Menu keyword hashes, as UI_Init does */
	String_Init();
	/* Asset_Parse writes to uiInfo.uiDC: keep one display context */
	f = fopen(argv[2], "r");
	if (!f) { fprintf(stderr, "no scenario\n"); return 2; }
	while (fgets(line, sizeof(line), f)) {
		char *p = line;
		size_t n = strlen(p);
		while (n && (p[n - 1] == '\n' || p[n - 1] == '\r')) p[--n] = 0;
		if (!n || p[0] == '#') continue;
		printf("> %s\n", p);
		if (strncmp(p, "menu ", 5) == 0) {
			UI_ParseMenu(p + 5);
		} else if (strncmp(p, "menus ", 6) == 0) {
			UI_LoadMenus(p + 6, qfalse);
		} else if (strncmp(p, "font ", 5) == 0) {
			int size = atoi(p + 5);
			memset(&font, 0, sizeof(font));
			RE_RegisterFont("ignored.ttf", size, &font);
			DumpFont("result", &font);
		} else if (strncmp(p, "run ", 4) == 0) {
			char *menuName = p + 4;
			char *itemName = strchr(menuName, ' ');
			char *script;
			menuDef_t *menu;
			itemDef_t *item;
			static itemDef_t dummy;
			*itemName++ = 0;
			script = strchr(itemName, ' ');
			*script++ = 0;
			menu = Menus_FindByName(menuName);
			if (!menu) { printf("no menu\n"); continue; }
			if (strcmp(itemName, "-") == 0) {
				memset(&dummy, 0, sizeof(dummy));
				dummy.parent = menu;
				item = &dummy;
			} else {
				item = Menu_FindItemByName(menu, itemName);
				if (!item) { printf("no item\n"); continue; }
			}
			Item_RunScript(item, script);
			DumpState();
			if (item == &dummy) { printf("dummy"); DumpWindowState(&dummy.window); }
		} else if (strcmp(p, "dump") == 0) {
			DumpAll();
		} else if (strcmp(p, "state") == 0) {
			DumpState();
		} else if (strcmp(p, "reset") == 0) {
			Menu_Reset();
		} else if (InputCommand(p)) {
		} else {
			printf("unknown scenario line\n");
		}
	}
	fclose(f);
	return 0;
}
