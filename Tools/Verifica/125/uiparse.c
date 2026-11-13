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
	printf("reg font \"%s\" %d\n", p, pointSize);
	RE_RegisterFont(p, pointSize, font);
}
static void DC_getTeamColor(vec4_t *color) {
	(*color)[0] = 0.25f; (*color)[1] = 0.5f; (*color)[2] = 0.75f; (*color)[3] = 1.0f;
}
static float DC_getCVarValue(const char *cvar) { return strcmp(cvar, "zero") == 0 ? 0.0f : 1.0f; }
static void DC_setCVar(const char *cvar, const char *value) { printf("host setcvar \"%s\" \"%s\"\n", cvar, value); }
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
static qhandle_t RE_RegisterShaderNoMip(const char *name) { return Register(shaders, &shaderCount, name); }
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
		} else {
			printf("unknown scenario line\n");
		}
	}
	fclose(f);
	return 0;
}
