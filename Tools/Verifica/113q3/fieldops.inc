/*
 * The edit field, the console key handler and the command completion of Quake III (issue #236, part B):
 * the REAL Field_* of client/cl_keys.c, Console_Key, and Field_CompleteCommand of qcommon/common.c, with
 * the little the original takes from the rest of the client (the clipboard, the scrolling of the console,
 * the connection state, the screen update) replaced by stubs that print one line. Included by driver.c
 * after the escape helpers; fieldOp() runs one scenario operation of the field family and returns 0 if
 * the operation is not one of them.
 */

#define MAX_EDIT_LINE 256
#define COMMAND_HISTORY 32
typedef struct {
	int		cursor;
	int		scroll;
	int		widthInChars;
	char	buffer[MAX_EDIT_LINE];
} field_t;

#include "keynums.inc"

typedef struct { int down; } qkey_t;
static qkey_t keys[256];
static int g_console_field_width = 78;
static int clsState = 1;	/* CA_DISCONNECTED */
#define CA_DISCONNECTED_STATE 1
#define CA_ACTIVE_STATE 8
static char *clipboardText = NULL;

static char *Sys_GetClipboardData(void) {
	return clipboardText ? CopyString(clipboardText) : NULL;
}
static void Con_PageUp(void) { Com_Printf("[PageUp]\n"); }
static void Con_PageDown(void) { Com_Printf("[PageDown]\n"); }
static void Con_Top(void) { Com_Printf("[Top]\n"); }
static void Con_Bottom(void) { Com_Printf("[Bottom]\n"); }
static void SCR_UpdateScreen(void) { Com_Printf("[UpdateScreen]\n"); }
void Cbuf_AddText(const char *text);
void Q_strcat(char *dest, int size, const char *src);
int Q_stricmpn(const char *s1, const char *s2, int n);
void Cmd_TokenizeString(const char *text_in);
void Cmd_CommandCompletion(void(*callback)(const char *s));
void Cvar_CommandCompletion(void(*callback)(const char *s));
void Field_Clear(field_t *edit);
void Field_CompleteCommand(field_t *edit);
void Field_CharEvent(field_t *edit, int ch);

#define CA_ACTIVE CA_ACTIVE_STATE
#define CA_DISCONNECTED CA_DISCONNECTED_STATE
static struct { int state; } cls;

field_t historyEditLines[COMMAND_HISTORY];
int nextHistoryLine;
int historyLine;
field_t g_consoleField;
qboolean key_overstrikeMode;

#include "field.inc"
#include "complete.inc"

static void fieldDump(void) {
	char line[1024];
	sprintf(line, "%d|%d|%d|%d|%d|%d|%s", g_consoleField.cursor, g_consoleField.scroll,
		g_consoleField.widthInChars, key_overstrikeMode, nextHistoryLine, historyLine, g_consoleField.buffer);
	escapePrint("K: ", line);
}

static int fieldOp(const char *op, char **fields) {
	if (!strcmp(op, "keydown")) keys[atoi(fields[1]) & 255].down = 1;
	else if (!strcmp(op, "keyup")) keys[atoi(fields[1]) & 255].down = 0;
	else if (!strcmp(op, "fclear")) Field_Clear(&g_consoleField);
	else if (!strcmp(op, "fkey")) { Field_KeyDownEvent(&g_consoleField, atoi(fields[1])); fieldDump(); }
	else if (!strcmp(op, "fchar")) { Field_CharEvent(&g_consoleField, atoi(fields[1])); fieldDump(); }
	else if (!strcmp(op, "ftext")) {
		const unsigned char *p;
		for (p = (const unsigned char *)fields[1]; *p; p++) Field_CharEvent(&g_consoleField, *p);
		fieldDump();
	}
	else if (!strcmp(op, "ckey")) { Console_Key(atoi(fields[1])); fieldDump(); }
	else if (!strcmp(op, "fcomplete")) { Field_CompleteCommand(&g_consoleField); fieldDump(); }
	else if (!strcmp(op, "fset")) {
		Field_Clear(&g_consoleField);
		strncpy(g_consoleField.buffer, fields[1], MAX_EDIT_LINE - 1);
		g_consoleField.cursor = atoi(fields[2]);
		g_consoleField.scroll = atoi(fields[3]);
		fieldDump();
	}
	else if (!strcmp(op, "fwidth")) {
		g_console_field_width = atoi(fields[1]);
		g_consoleField.widthInChars = g_console_field_width;
	}
	else if (!strcmp(op, "fstate")) cls.state = atoi(fields[1]) ? CA_ACTIVE : CA_DISCONNECTED;
	else if (!strcmp(op, "clip")) clipboardText = CopyString(fields[1]);
	else if (!strcmp(op, "noclip")) clipboardText = NULL;
	else if (!strcmp(op, "hdump")) {
		int i;
		for (i = 0; i < COMMAND_HISTORY; i++) {
			char line[1024];
			if (!historyEditLines[i].buffer[0] && !historyEditLines[i].cursor && !historyEditLines[i].scroll) continue;
			sprintf(line, "%d|%d|%d|%d|%s", i, historyEditLines[i].cursor, historyEditLines[i].scroll,
				historyEditLines[i].widthInChars, historyEditLines[i].buffer);
			escapePrint("H: ", line);
		}
	}
	else return 0;
	return 1;
}
