/*
 * Driver of the parity tool of the Quake III profile of the console (issue #113): runs a scenario on the
 * REAL cmd.c and cvar.c of Quake III (included as cmd.inc and cvar.inc) and prints one text line per
 * result. Tests\Source\DelphiDoom.Tests.Console.Q3.Scenario.pas runs the same scenario with the Delphi
 * classes and compares line by line.
 *   q3console.exe scenario.scn > scenario.golden.txt
 * Scenario: one operation per line, fields separated by a tab, \n \t \r \\ and \xNN are escapes.
 */
#include "stubs.h"
#include "types.inc"


/* ---- what the original expects from the rest of the engine ---- */
static char printbuf[65536];
static char dprintbuf[65536];
static char writebuf[65536];

static void Com_Printf(const char *fmt, ...) {
	va_list ap;
	size_t n = strlen(printbuf);
	va_start(ap, fmt);
	vsnprintf(printbuf + n, sizeof(printbuf) - n, fmt, ap);
	va_end(ap);
}
static void Com_DPrintf(const char *fmt, ...) {
	va_list ap;
	size_t n = strlen(dprintbuf);
	va_start(ap, fmt);
	vsnprintf(dprintbuf + n, sizeof(dprintbuf) - n, fmt, ap);
	va_end(ap);
}
static void Com_Error(int code, const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	fprintf(stderr, "Com_Error: ");
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	exit(1);
}
static void FS_Printf(fileHandle_t f, const char *fmt, ...) {
	va_list ap;
	size_t n = strlen(writebuf);
	va_start(ap, fmt);
	vsnprintf(writebuf + n, sizeof(writebuf) - n, fmt, ap);
	va_end(ap);
}

static char *CopyString(const char *in) {
	char *out = (char *)malloc(strlen(in) + 1);
	strcpy(out, in);
	return out;
}

/* files of the scenario */
#define MAX_FILES 16
static char *fileNames[MAX_FILES];
static char *fileTexts[MAX_FILES];
static int fileCount;
static int FS_ReadFile(const char *qpath, void **buffer) {
	int i;
	for (i = 0; i < fileCount; i++) {
		if (!strcmp(fileNames[i], qpath)) {
			*buffer = CopyString(fileTexts[i]);
			return (int)strlen(fileTexts[i]);
		}
	}
	*buffer = NULL;
	return -1;
}
static void FS_FreeFile(void *buffer) { free(buffer); }

/* the game: nothing handles a line, the client forwards it */
static cvar_t *com_cl_running = NULL;
static cvar_t *com_sv_running = NULL;
static int CL_GameCommand(void) { return 0; }
static int SV_GameCommand(void) { return 0; }
static int UI_GameCommand(void) { return 0; }
static void CL_ForwardCommandToServer(const char *text) { Com_Printf("forward %s\n", text); }

/* prototypes of what the two files share */
void Cmd_AddCommand(const char *cmd_name, xcommand_t function);
int Cmd_Argc(void);
char *Cmd_Argv(int arg);
void Cmd_ExecuteString(const char *text);
void Cbuf_Execute(void);
qboolean Cvar_Command(void);
char *Cvar_VariableString(const char *var_name);
float Cvar_VariableValue(const char *var_name);
cvar_t *Cvar_Set2(const char *var_name, const char *value, qboolean force);
void Cvar_Set(const char *var_name, const char *value);
char *Cmd_Args(void);
char *Cmd_ArgsFrom(int arg);
char *Cmd_Cmd();
void Cvar_Update(vmCvar_t *vmCvar);
void Cbuf_InsertText(const char *text);
void Info_SetValueForKey(char *s, const char *key, const char *value);
void Info_SetValueForKey_Big(char *s, const char *key, const char *value);
void Info_RemoveKey(char *s, const char *key);
void Info_RemoveKey_Big(char *s, const char *key);
int Com_Filter(char *filter, char *name, int casesensitive);
void COM_DefaultExtension(char *path, int maxSize, const char *extension);
void Q_strncpyz(char *dest, const char *src, int destsize);
int Q_stricmp(const char *s1, const char *s2);
void QDECL Com_sprintf(char *dest, int size, const char *fmt, ...);
char *QDECL va(char *format, ...);

#include "helpers.inc"
#include "info.inc"
#include "cmd.inc"
#include "cvar.inc"

/* ---- the driver ---- */

static void escapePrint(const char *prefix, const char *s) {
	printf("%s", prefix);
	for (; *s; s++) {
		unsigned char c = (unsigned char)*s;
		if (c == '\n') printf("\\n");
		else if (c == '\\') printf("\\\\");
		else if (c < 32 || c > 126) printf("\\x%02X", c);
		else putchar(c);
	}
	printf("\n");
}

static void flushOutput(void) {
	if (printbuf[0]) { escapePrint("P: ", printbuf); printbuf[0] = 0; }
	if (dprintbuf[0]) { escapePrint("D: ", dprintbuf); dprintbuf[0] = 0; }
}

static int floatBits(float f) { int b; memcpy(&b, &f, 4); return b; }

static void printCvar(const cvar_t *v) {
	char line[4096];
	if (!v) { printf("G: <none>\n"); return; }
	sprintf(line, "%s|%s|%s|%s|%d|%d|%d|%08X|%d", v->name, v->string, v->resetString,
		v->latchedString ? v->latchedString : "~", v->flags, v->modified, v->modificationCount,
		(unsigned)floatBits(v->value), v->integer);
	escapePrint("G: ", line);
}

static void listArgs(const char *prefix) {
	static char all[65536];
	int i;
	sprintf(all, "%d", Cmd_Argc());
	for (i = 0; i < Cmd_Argc(); i++) {
		strcat(all, "|");
		strcat(all, Cmd_Argv(i));
	}
	escapePrint(prefix, all);
}

static void probe(void) {
	listArgs("A: ");
	escapePrint("R: ", Cmd_Args());
	escapePrint("C: ", Cmd_Cmd());
}

/* an escape-aware split of a scenario line */
static int unescape(char *dst, const char *src) {
	int n = 0;
	while (*src) {
		if (*src == '\\' && src[1]) {
			src++;
			if (*src == 'n') dst[n++] = '\n';
			else if (*src == 't') dst[n++] = '\t';
			else if (*src == 'r') dst[n++] = '\r';
			else if (*src == 'x' && src[1] && src[2]) {
				char hex[3] = { src[1], src[2], 0 };
				dst[n++] = (char)strtol(hex, NULL, 16);
				src += 2;
			}
			else dst[n++] = *src;
			src++;
		} else dst[n++] = *src++;
	}
	dst[n] = 0;
	return n;
}

#define MAX_FIELDS 8
static vmCvar_t vms[16];

int main(int argc, char **argv) {
	FILE *f = fopen(argv[1], "rb");
	static char raw[65536];
	static char orig[65536];
	char *fields[MAX_FIELDS];
	static char storage[MAX_FIELDS][8192];
	if (!f) { fprintf(stderr, "no scenario\n"); return 1; }
	while (fgets(raw, sizeof(raw), f)) {
		int nf = 0, i;
		char *p = raw, *start;
		size_t len = strlen(raw);
		while (len && (raw[len - 1] == '\n' || raw[len - 1] == '\r')) raw[--len] = 0;
		if (!len || raw[0] == '#') continue;
		strcpy(orig, raw);
		start = p;
		for (;;) {
			char *tab = strchr(start, '\t');
			if (tab) *tab = 0;
			if (nf < MAX_FIELDS) { unescape(storage[nf], start); fields[nf] = storage[nf]; nf++; }
			if (!tab) break;
			start = tab + 1;
		}
		for (i = nf; i < MAX_FIELDS; i++) { storage[i][0] = 0; fields[i] = storage[i]; }
		{
			/* the line as it was written, tabs as \t */
			const char *s;
			printf("> ");
			for (s = orig; *s; s++) {
				if (*s == 9) printf("\\t");
				else putchar(*s);
			}
			printf("\n");
		}
		{
			const char *op = fields[0];
			if (!strcmp(op, "init")) { Cbuf_Init(); Cmd_Init(); Cvar_Init(); }
			else if (!strcmp(op, "addcmd")) {
				if (!strcmp(fields[2], "probe")) Cmd_AddCommand(fields[1], probe);
				else Cmd_AddCommand(fields[1], NULL);
			}
			else if (!strcmp(op, "rmcmd")) Cmd_RemoveCommand(fields[1]);
			else if (!strcmp(op, "cmd")) Cmd_ExecuteString(fields[1]);
			else if (!strcmp(op, "now")) Cbuf_ExecuteText(EXEC_NOW, fields[1]);
			else if (!strcmp(op, "append")) Cbuf_ExecuteText(EXEC_APPEND, fields[1]);
			else if (!strcmp(op, "insert")) Cbuf_ExecuteText(EXEC_INSERT, fields[1]);
			else if (!strcmp(op, "run")) Cbuf_Execute();
			else if (!strcmp(op, "pending")) {
				char tmp[MAX_CMD_BUFFER + 1];
				memcpy(tmp, cmd_text.data, cmd_text.cursize);
				tmp[cmd_text.cursize] = 0;
				escapePrint("B: ", tmp);
				printf("W: %d\n", cmd_wait);
			}
			else if (!strcmp(op, "tok")) {
				int k;
				Cmd_TokenizeString(fields[1]);
				listArgs("T: ");
				escapePrint("R: ", Cmd_Args());
				escapePrint("F: ", Cmd_ArgsFrom(1));
				escapePrint("C: ", Cmd_Cmd());
				printf("O: [%s]\n", Cmd_Argv(99));
			}
			else if (!strcmp(op, "file")) {
				fileNames[fileCount] = CopyString(fields[1]);
				fileTexts[fileCount] = CopyString(fields[2]);
				fileCount++;
			}
			else if (!strcmp(op, "get")) printCvar(Cvar_Get(fields[1], fields[2], atoi(fields[3])));
			else if (!strcmp(op, "set")) { Cvar_Set(fields[1], fields[2]); printCvar(Cvar_FindVar(fields[1])); }
			else if (!strcmp(op, "setl")) { Cvar_SetLatched(fields[1], fields[2]); printCvar(Cvar_FindVar(fields[1])); }
			else if (!strcmp(op, "set2")) { Cvar_Set2(fields[1], fields[2], atoi(fields[3])); printCvar(Cvar_FindVar(fields[1])); }
			else if (!strcmp(op, "setv")) { Cvar_SetValue(fields[1], (float)atof(fields[2])); printCvar(Cvar_FindVar(fields[1])); }
			else if (!strcmp(op, "reset")) { Cvar_Reset(fields[1]); printCvar(Cvar_FindVar(fields[1])); }
			else if (!strcmp(op, "cheat")) Cvar_SetCheatState();
			else if (!strcmp(op, "clearmod")) cvar_modifiedFlags = 0;
			else if (!strcmp(op, "val")) {
				char one[1024];
				sprintf(one, "%08X|%d|%s", (unsigned)floatBits(Cvar_VariableValue(fields[1])),
					Cvar_VariableIntegerValue(fields[1]), Cvar_VariableString(fields[1]));
				escapePrint("V: ", one);
			}
			else if (!strcmp(op, "vbuf")) {
				char buf[1024];
				Cvar_VariableStringBuffer(fields[1], buf, atoi(fields[2]));
				escapePrint("V: ", buf);
			}
			else if (!strcmp(op, "dump")) {
				cvar_t *v;
				for (v = cvar_vars; v; v = v->next) printCvar(v);
				printf("M: %d N: %d\n", cvar_modifiedFlags, cvar_numIndexes);
			}
			else if (!strcmp(op, "write")) { writebuf[0] = 0; Cvar_WriteVariables(0); escapePrint("F: ", writebuf); }
			else if (!strcmp(op, "info")) escapePrint("I: ", Cvar_InfoString(atoi(fields[1])));
			else if (!strcmp(op, "infobig")) escapePrint("I: ", Cvar_InfoString_Big(atoi(fields[1])));
			else if (!strcmp(op, "vmreg")) {
				int slot = atoi(fields[1]);
				char one[1024];
				Cvar_Register(&vms[slot], fields[2], fields[3], atoi(fields[4]));
				sprintf(one, "%d|%d|%08X|%d|%s", vms[slot].handle, vms[slot].modificationCount,
					(unsigned)floatBits(vms[slot].value), vms[slot].integer, vms[slot].string);
				escapePrint("Y: ", one);
			}
			else if (!strcmp(op, "vmupd")) {
				int slot = atoi(fields[1]);
				char one[1024];
				Cvar_Update(&vms[slot]);
				sprintf(one, "%d|%d|%08X|%d|%s", vms[slot].handle, vms[slot].modificationCount,
					(unsigned)floatBits(vms[slot].value), vms[slot].integer, vms[slot].string);
				escapePrint("Y: ", one);
			}
			else { fprintf(stderr, "unknown operation %s\n", op); return 1; }
		}
		flushOutput();
	}
	return 0;
}
