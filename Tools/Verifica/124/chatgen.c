/*
 * Parity tool of the issue #124 (bot chat of Quake III Arena).
 *
 * It links the REAL be_ai_chat.c (included below, so its static types are visible), l_script.c and
 * l_precomp.c of code/botlib (read only, copied by build.sh) with the stubs of the folder stub/, and
 * runs the commands of a scenario file (Tests/Data/BotAi/scenario.txt), one per line:
 *     command|argument|argument...
 * Arguments accept the escapes \t \n \r \\ \xNN; the argument <nil> is a NULL pointer. For every
 * command the line is echoed (prefix ">") and the results are printed. Everything the library
 * prints (botimport.Print) is a line "P<level>|text", what it writes to its log "L|text", the
 * commands the bot would send to the game "E|client|command". Strings are printed with the bytes
 * below 32, above 126 and the backslash as \xNN (the Delphi test makes the same).
 *
 *   chatgen <data folder> <scenario file>   (the data folder contains botfiles/)
 */
#include "game/q_shared.h"
#include "game/botlib.h"

/* the real chat code */
#include "botlib/be_ai_chat.c"

static const char *datafolder;
static FILE *out;
botlib_import_t botimport;
int bot_developer;
static float aas_time;

/* ---------------------------------------------------------------- output */

static void print_escaped(FILE *f, const char *s)
{
	for (; *s; s++)
	{
		unsigned char c = (unsigned char) *s;
		if (c < 32 || c > 126 || c == '\\') fprintf(f, "\\x%02X", c);
		else fputc(c, f);
	}
}

static void Stub_Print(int type, char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	fprintf(out, "P%d|", type);
	print_escaped(out, text);
	fputc('\n', out);
}

void Log_Write(char *fmt, ...)
{
	char text[4096];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	fprintf(out, "L|");
	print_escaped(out, text);
	fputc('\n', out);
}
void Log_Print(char *fmt, ...) { (void) fmt; }
FILE *Log_FilePointer(void) { return NULL; }

void EA_Command(int client, char *command)
{
	fprintf(out, "E|%d|", client);
	print_escaped(out, command);
	fputc('\n', out);
}

float AAS_Time(void) { return aas_time; }

/* ---------------------------------------------------------------- q_shared */

int Com_sprintf(char *dest, int size, const char *fmt, ...)
{
	va_list ap;
	int len;
	va_start(ap, fmt);
	len = vsnprintf(dest, size, fmt, ap);
	va_end(ap);
	if (len >= size) len = size - 1;
	return len;
}
void Com_Error(int level, const char *fmt, ...) { (void) level; fprintf(out, "FATAL %s\n", fmt); exit(2); }
char *va(char *format, ...)
{
	static char string[2][32000];
	static int index = 0;
	char *buf;
	va_list ap;
	index ^= 1;
	buf = string[index];
	va_start(ap, format);
	vsnprintf(buf, sizeof(string[0]), format, ap);
	va_end(ap);
	return buf;
}
void Q_strncpyz(char *dest, const char *src, int destsize)
{
	strncpy(dest, src, destsize - 1);
	dest[destsize - 1] = 0;
}
#include "comcompress.inc"

/* ---------------------------------------------------------------- file system */

static FILE *handles[64];

static int Stub_FOpenFile(const char *qpath, fileHandle_t *file, fsMode_t mode)
{
	char path[1024];
	int i, length;
	FILE *f;
	(void) mode;
	snprintf(path, sizeof(path), "%s/%s", datafolder, qpath);
	for (i = 0; path[i]; i++) if (path[i] == '\\') path[i] = '/';
	f = fopen(path, "rb");
	*file = 0;
	if (!f) return 0;
	fseek(f, 0, SEEK_END);
	length = (int) ftell(f);
	fseek(f, 0, SEEK_SET);
	for (i = 1; i < 64; i++)
	{
		if (!handles[i]) { handles[i] = f; *file = i; break; }
	}
	return length;
}
static int Stub_Read(void *buffer, int len, fileHandle_t f) { return (int) fread(buffer, 1, len, handles[f]); }
static void Stub_Close(fileHandle_t f) { fclose(handles[f]); handles[f] = NULL; }

/* ---------------------------------------------------------------- library variables */

typedef struct { char name[64]; char string[256]; float value; } libvar_t;
static libvar_t libvars[64];
static int numlibvars;

static libvar_t *LibVarFind(char *name)
{
	int i;
	for (i = 0; i < numlibvars; i++) if (!strcmp(libvars[i].name, name)) return &libvars[i];
	return NULL;
}
static libvar_t *LibVarSet(char *name, char *value)
{
	libvar_t *v = LibVarFind(name);
	if (!v) { v = &libvars[numlibvars++]; strcpy(v->name, name); }
	strcpy(v->string, value);
	v->value = (float) atof(value);
	return v;
}
float LibVarGetValue(char *name) { libvar_t *v = LibVarFind(name); return v ? v->value : 0; }
float LibVarValue(char *name, char *value)
{
	libvar_t *v = LibVarFind(name);
	if (!v) v = LibVarSet(name, value);
	return v->value;
}
char *LibVarString(char *name, char *value)
{
	libvar_t *v = LibVarFind(name);
	if (!v) v = LibVarSet(name, value);
	return v->string;
}

/* ---------------------------------------------------------------- scenario */

static int unescape(char *s)
{
	char *r = s, *w = s;
	while (*r)
	{
		if (*r == '\\' && r[1])
		{
			r++;
			if (*r == 't') *w++ = '\t';
			else if (*r == 'n') *w++ = '\n';
			else if (*r == 'r') *w++ = '\r';
			else if (*r == '\\') *w++ = '\\';
			else if (*r == 'x' && r[1] && r[2])
			{
				char hex[3] = { r[1], r[2], 0 };
				*w++ = (char) strtol(hex, NULL, 16);
				r += 2;
			}
			else *w++ = *r;
			r++;
		}
		else *w++ = *r++;
	}
	*w = 0;
	return (int) (w - s);
}

#define MAXARGS 16
static char *args[MAXARGS];
static int numargs;

static char *arg(int i)
{
	if (i >= numargs) return "";
	return args[i];
}
static char *varg(int i)
{
	if (i >= numargs || !strcmp(args[i], "<nil>")) return NULL;
	return args[i];
}
static long num(int i) { return strtol(arg(i), NULL, 0); }
static unsigned long unum(int i) { return strtoul(arg(i), NULL, 0); }

static int quiet;

static void show_message(int h)
{
	char buf[MAX_MESSAGE_SIZE];
	fprintf(out, "chatlen=%d\n", BotChatLength(h));
	BotGetChatMessage(h, buf, sizeof(buf));
	fprintf(out, "chatmsg=");
	print_escaped(out, buf);
	fputc('\n', out);
}

static void show_match(bot_match_t *m)
{
	int i;
	char buf[MAX_MESSAGE_SIZE];
	fprintf(out, "match type=%d subtype=%d\n", m->type, m->subtype);
	for (i = 0; i < MAX_MATCHVARIABLES; i++)
	{
		BotMatchVariable(m, i, buf, sizeof(buf));
		fprintf(out, "var%d offset=%d length=%d text=", i, m->variables[i].offset, m->variables[i].length);
		print_escaped(out, buf);
		fputc('\n', out);
	}
}

static void run(char *line)
{
	char *cmd, *p;
	int h;
	numargs = 0;
	cmd = line;
	for (p = line; ; p++)
	{
		if (*p == '|' || *p == 0)
		{
			int last = (*p == 0);
			*p = 0;
			if (numargs < MAXARGS) { args[numargs] = (cmd == line && numargs == 0) ? cmd : cmd; numargs++; }
			cmd = p + 1;
			if (last) break;
		}
	}
	{
		int i;
		for (i = 0; i < numargs; i++) unescape(args[i]);
	}
	cmd = args[0];
	/* the command is args[0]; the other arguments are shifted by one in arg(i) */
	{
		char *name = args[0];
		int i;
		for (i = 0; i + 1 < numargs; i++) args[i] = args[i + 1];
		numargs--;
		cmd = name;
	}
	if (!strcmp(cmd, "libvar")) { LibVarSet(arg(0), arg(1)); }
	else if (!strcmp(cmd, "seed")) { srand((unsigned) num(0)); }
	else if (!strcmp(cmd, "time")) { aas_time = (float) atof(arg(0)); }
	else if (!strcmp(cmd, "setup"))
	{
		bot_developer = (int) LibVarGetValue("bot_developer");
		fprintf(out, "setup=%d\n", BotSetupChatAI());
	}
	else if (!strcmp(cmd, "shutdown")) { BotShutdownChatAI(); }
	else if (!strcmp(cmd, "resetchat")) { BotResetChatAI(); }
	else if (!strcmp(cmd, "alloc")) { fprintf(out, "alloc=%d\n", BotAllocChatState()); }
	else if (!strcmp(cmd, "free")) { BotFreeChatState((int) num(0)); }
	else if (!strcmp(cmd, "loadchat")) { fprintf(out, "loadchat=%d\n", BotLoadChatFile((int) num(0), arg(1), arg(2))); }
	else if (!strcmp(cmd, "gender")) { BotSetChatGender((int) num(0), (int) num(1)); }
	else if (!strcmp(cmd, "name")) { BotSetChatName((int) num(0), arg(1), (int) num(2)); }
	else if (!strcmp(cmd, "numinitial")) { fprintf(out, "numinitial=%d\n", BotNumInitialChats((int) num(0), arg(1))); }
	else if (!strcmp(cmd, "initial"))
	{
		h = (int) num(0);
		BotInitialChat(h, arg(1), (int) num(2), varg(3), varg(4), varg(5), varg(6), varg(7), varg(8), varg(9), varg(10));
		if (!quiet) show_message(h);
	}
	else if (!strcmp(cmd, "quiet")) { quiet = (int) num(0); }
	else if (!strcmp(cmd, "show")) { show_message((int) num(0)); }
	else if (!strcmp(cmd, "reply"))
	{
		h = (int) num(0);
		fprintf(out, "reply=%d\n", BotReplyChat(h, arg(1), (int) num(2), (int) num(3), varg(4), varg(5), varg(6), varg(7), varg(8), varg(9), varg(10), varg(11)));
		if (!quiet) show_message(h);
	}
	else if (!strcmp(cmd, "construct"))
	{
		bot_match_t match;
		int i, index = 0;
		h = (int) num(0);
		memset(&match, 0, sizeof(match));
		for (i = 0; i < 8; i++)
		{
			char *v = varg(5 + i);
			if (!v) continue;
			strcat(match.string, v);
			match.variables[i].offset = index;
			match.variables[i].length = strlen(v);
			index += strlen(v);
		}
		BotConstructChatMessage(BotChatStateFromHandle(h), arg(1), (unsigned long) unum(2), &match, (unsigned long) unum(3), (int) num(4));
		show_message(h);
	}
	else if (!strcmp(cmd, "enter")) { BotEnterChat((int) num(0), (int) num(1), (int) num(2)); }
	else if (!strcmp(cmd, "find"))
	{
		bot_match_t match;
		int r;
		memset(&match, 0, sizeof(match));
		r = BotFindMatch(arg(0), &match, (unsigned long) unum(1));
		fprintf(out, "find=%d\n", r);
		if (r) show_match(&match);
	}
	else if (!strcmp(cmd, "matchvar"))
	{
		bot_match_t match;
		char buf[MAX_MESSAGE_SIZE];
		int size = (int) num(3);
		memset(&match, 0, sizeof(match));
		memset(buf, 'Z', sizeof(buf));
		BotFindMatch(arg(0), &match, (unsigned long) unum(1));
		BotMatchVariable(&match, (int) num(2), buf, size);
		fprintf(out, "matchvar=");
		print_escaped(out, buf);
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "unify"))
	{
		char buf[1024];
		strcpy(buf, arg(0));
		UnifyWhiteSpaces(buf);
		fprintf(out, "unify=");
		print_escaped(out, buf);
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "replsyn") || !strcmp(cmd, "replrsyn"))
	{
		char buf[1024];
		strcpy(buf, arg(0));
		if (cmd[4] == 'r') BotReplaceReplySynonyms(buf, (unsigned long) unum(1));
		else BotReplaceSynonyms(buf, (unsigned long) unum(1));
		fprintf(out, "%s=", cmd);
		print_escaped(out, buf);
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "weighted"))
	{
		char buf[1024];
		strcpy(buf, arg(0));
		BotReplaceWeightedSynonyms(buf, (unsigned long) unum(1));
		fprintf(out, "weighted=");
		print_escaped(out, buf);
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "contains")) { fprintf(out, "contains=%d\n", StringContains(arg(0), arg(1), (int) num(2))); }
	else if (!strcmp(cmd, "containsword"))
	{
		char *r = StringContainsWord(arg(0), arg(1), (int) num(2));
		fprintf(out, "containsword=%d\n", r ? (int) (r - arg(0)) : -1);
	}
	else if (!strcmp(cmd, "replacewords"))
	{
		char buf[1024];
		strcpy(buf, arg(0));
		StringReplaceWords(buf, arg(1), arg(2));
		fprintf(out, "replacewords=");
		print_escaped(out, buf);
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "tildes"))
	{
		char buf[1024];
		strcpy(buf, arg(0));
		BotRemoveTildes(buf);
		fprintf(out, "tildes=");
		print_escaped(out, buf);
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "queue")) { BotQueueConsoleMessage((int) num(0), (int) num(1), arg(2)); }
	else if (!strcmp(cmd, "nextmsg"))
	{
		bot_consolemessage_t cm;
		int r = BotNextConsoleMessage((int) num(0), &cm);
		fprintf(out, "nextmsg=%d", r);
		if (r)
		{
			fprintf(out, " type=%d time=%.2f text=", cm.type, cm.time);
			print_escaped(out, cm.message);
		}
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "removemsg")) { BotRemoveConsoleMessage((int) num(0), (int) num(1)); }
	else if (!strcmp(cmd, "numconsole")) { fprintf(out, "numconsole=%d\n", BotNumConsoleMessages((int) num(0))); }
	else fprintf(out, "UNKNOWN COMMAND %s\n", cmd);
}

int main(int argc, char **argv)
{
	FILE *scenario;
	char line[4096];

	if (argc < 3) { fprintf(stderr, "usage: chatgen <data folder> <scenario>\n"); return 1; }
	datafolder = argv[1];
	scenario = fopen(argv[2], "rb");
	if (!scenario) { fprintf(stderr, "cannot open %s\n", argv[2]); return 1; }
	out = stdout;
	setvbuf(stdout, NULL, _IONBF, 0);
	botimport.Print = Stub_Print;
	botimport.FS_FOpenFile = Stub_FOpenFile;
	botimport.FS_Read = Stub_Read;
	botimport.FS_FCloseFile = Stub_Close;
	while (fgets(line, sizeof(line), scenario))
	{
		int len = (int) strlen(line);
		char echo[4096];
		while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) line[--len] = 0;
		if (!len || line[0] == ';') continue;
		strcpy(echo, line);
		fprintf(out, "> ");
		print_escaped(out, echo);
		fputc('\n', out);
		run(line);
	}
	fclose(scenario);
	return 0;
}
