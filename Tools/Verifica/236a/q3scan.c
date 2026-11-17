/*
 * Parity tool of the issue #236: dumps the tokens that the REAL l_script.c (PS_*) and l_precomp.c
 * (PC_*) of Quake III Arena produce for the cases of Tests/Data/Scanner/Q3/cases.txt.
 *
 *   q3scan <data folder> <cases file>
 *
 * A line of the cases file:  mode|name|input file|option|option...   (mode is ps or pc)
 * options:  flags=N   script flags (SetScriptFlags of the first script)
 *           mem=1     load the file with LoadScriptMemory / LoadSourceMemory (no COM_Compress)
 *           ops=file  operations (one per line) instead of "read until the end"
 *           nv=1      do not print intvalue and floatvalue (they are not initialized by #eval)
 *           nv=2      also not the subtype and the line (the stringizing operator does not set them)
 *           def=text  PC_AddDefine,  gdef=text  PC_AddGlobalDefine,  base=folder  PS_SetBaseFolder
 *           inc=path  PC_SetIncludePath,  builtin=1  PC_AddBuiltinDefines (the library never calls it itself)
 * Everything the library prints is "P<level>|text"; a token is
 *   T|type|subtype|intvalue|floatvalue|line|linescrossed|whitespace length|string
 * with the floatvalue as the 10 bytes of the long double (mantissa 16 hex digits, then sign and exponent).
 * Strings are written with the bytes below 32, above 126 and the backslash as \xNN.
 */
#include "game/q_shared.h"
#include "game/botlib.h"
#include "botlib/l_script.h"
#include "botlib/l_precomp.h"

static const char *datafolder;
static FILE *out;
botlib_import_t botimport;
int bot_developer;
static int hide_values;

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
void Log_Write(char *fmt, ...) { (void) fmt; }
void Log_Print(char *fmt, ...) { (void) fmt; }
FILE *Log_FilePointer(void) { return NULL; }
int Com_sprintf(char *dest, int size, const char *fmt, ...)
{
	va_list ap; int len;
	va_start(ap, fmt);
	len = vsnprintf(dest, size, fmt, ap);
	va_end(ap);
	if (len >= size) len = size - 1;
	return len;
}
void Com_Error(int level, const char *fmt, ...) { (void) level; fprintf(out, "FATAL %s\n", fmt); exit(2); }
char *va(char *format, ...) { return format; }
void Q_strncpyz(char *dest, const char *src, int destsize) { strncpy(dest, src, destsize - 1); dest[destsize - 1] = 0; }
#include "comcompress.inc"

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
	for (i = 1; i < 64; i++) if (!handles[i]) { handles[i] = f; *file = i; break; }
	return length;
}
static int Stub_Read(void *buffer, int len, fileHandle_t f) { return (int) fread(buffer, 1, len, handles[f]); }
static void Stub_Close(fileHandle_t f) { fclose(handles[f]); handles[f] = NULL; }

static char *slurp(const char *name, int *length)
{
	char path[1024];
	FILE *f;
	char *buf;
	snprintf(path, sizeof(path), "%s/%s", datafolder, name);
	f = fopen(path, "rb");
	if (!f) { *length = -1; return NULL; }
	fseek(f, 0, SEEK_END);
	*length = (int) ftell(f);
	fseek(f, 0, SEEK_SET);
	buf = (char *) malloc(*length + 1);
	fread(buf, 1, *length, f);
	buf[*length] = 0;
	fclose(f);
	return buf;
}

static void print_ld(long double v)
{
	unsigned char raw[16];
	unsigned long long mant;
	unsigned int se;
	memset(raw, 0, sizeof(raw));
	memcpy(raw, &v, 10);
	memcpy(&mant, raw, 8);
	se = raw[8] | (raw[9] << 8);
	fprintf(out, "%016llX%04X", mant, se);
}
static void print_token(token_t *t)
{
	if (hide_values == 2)
	{
		/* a token made by the stringizing operator: the subtype, the values and the line are not set */
		fprintf(out, "T|%d|-|-|-|-|-|%d|", t->type, (int) (t->endwhitespace_p - t->whitespace_p));
		print_escaped(out, t->string);
		fputc('\n', out);
		return;
	}
	fprintf(out, "T|%d|%d|", t->type, t->subtype);
	if (hide_values) fprintf(out, "-|-");
	else if (t->type == TT_PUNCTUATION) fprintf(out, "0|00000000000000000000");   /* never set: the tokens of the directives keep stack garbage */
	else
	{
		fprintf(out, "%lu|", (unsigned long) t->intvalue);
		print_ld(t->floatvalue);
	}
	fprintf(out, "|%d|%d|%d|", t->line, t->linescrossed, (int) (t->endwhitespace_p - t->whitespace_p));
	print_escaped(out, t->string);
	fputc('\n', out);
}

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
			else if (*r == '\\') *w++ = '\\';
			else if (*r == 'x' && r[1] && r[2]) { char hex[3] = { r[1], r[2], 0 }; *w++ = (char) strtol(hex, NULL, 16); r += 2; }
			else *w++ = *r;
			r++;
		}
		else *w++ = *r++;
	}
	*w = 0;
	return (int) (w - s);
}

#define MAXARGS 8
static int split(char *line, char **args)
{
	int n = 0;
	char *p = line;
	args[n++] = p;
	while (*p && n < MAXARGS) { if (*p == '|') { *p = 0; args[n++] = p + 1; } p++; }
	return n;
}

static void run_ps(script_t *s, const char *opsfile)
{
	token_t tok, last;
	memset(&last, 0, sizeof(last));
	if (!opsfile)
	{
		while (PS_ReadToken(s, &tok)) print_token(&tok);
		fprintf(out, "END|%d|%d\n", s->line, EndOfScript(s));
		return;
	}
	{
		int len;
		char *ops = slurp(opsfile, &len), *line, *next;
		for (line = ops; line && *line; line = next)
		{
			char *a[MAXARGS];
			int r;
			next = strchr(line, '\n');
			if (next) { *next++ = 0; }
			if (strchr(line, '\r')) *strchr(line, '\r') = 0;
			if (!*line) continue;
			split(line, a);
			fprintf(out, ">%s\n", a[0]);
			if (!strcmp(a[0], "read")) { r = PS_ReadToken(s, &tok); last = tok; fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "expstr")) { unescape(a[1]); r = PS_ExpectTokenString(s, a[1]); fprintf(out, "R|%d\n", r); }
			else if (!strcmp(a[0], "exptype")) { r = PS_ExpectTokenType(s, atoi(a[1]), atoi(a[2]), &tok); fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "expany")) { r = PS_ExpectAnyToken(s, &tok); fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "chkstr")) { r = PS_CheckTokenString(s, a[1]); fprintf(out, "R|%d\n", r); }
			else if (!strcmp(a[0], "chktype")) { r = PS_CheckTokenType(s, atoi(a[1]), atoi(a[2]), &tok); fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "skip")) { r = PS_SkipUntilString(s, a[1]); fprintf(out, "R|%d\n", r); }
			else if (!strcmp(a[0], "unread")) { PS_UnreadLastToken(s); }
			else if (!strcmp(a[0], "unreadtok")) { PS_UnreadToken(s, &last); }
			else if (!strcmp(a[0], "sint")) { fprintf(out, "R|%ld\n", ReadSignedInt(s)); }
			else if (!strcmp(a[0], "sfloat")) { long double v = ReadSignedFloat(s); fprintf(out, "R|"); print_ld(v); fputc('\n', out); }
			else if (!strcmp(a[0], "eos")) { fprintf(out, "R|%d\n", EndOfScript(s)); }
			else if (!strcmp(a[0], "ws")) { fprintf(out, "R|%d\n", (int) (unsigned char) PS_NextWhiteSpaceChar(s)); }
			else if (!strcmp(a[0], "reset")) { ResetScript(s); }
			else if (!strcmp(a[0], "flags")) { SetScriptFlags(s, atoi(a[1])); }
			else if (!strcmp(a[0], "getflags")) { fprintf(out, "R|%d\n", GetScriptFlags(s)); }
			else if (!strcmp(a[0], "punct")) { fprintf(out, "R|%s\n", PunctuationFromNum(s, atoi(a[1]))); }
			else if (!strcmp(a[0], "strip2")) { StripDoubleQuotes(last.string); print_token(&last); }
			else if (!strcmp(a[0], "strip1")) { StripSingleQuotes(last.string); print_token(&last); }
			else if (!strcmp(a[0], "line")) { fprintf(out, "R|%d|%d\n", s->line, s->lastline); }
			else fprintf(out, "?unknown op\n");
		}
		free(ops);
	}
}

static void run_pc(source_t *s, const char *opsfile)
{
	token_t tok, last;
	memset(&last, 0, sizeof(last));
	if (!opsfile)
	{
		while (PC_ReadToken(s, &tok)) print_token(&tok);
		fprintf(out, "END|%d\n", s->scriptstack ? s->scriptstack->line : -1);
		return;
	}
	{
		int len;
		char *ops = slurp(opsfile, &len), *line, *next;
		for (line = ops; line && *line; line = next)
		{
			char *a[MAXARGS];
			int r;
			next = strchr(line, '\n');
			if (next) { *next++ = 0; }
			if (strchr(line, '\r')) *strchr(line, '\r') = 0;
			if (!*line) continue;
			split(line, a);
			fprintf(out, ">%s\n", a[0]);
			if (!strcmp(a[0], "read")) { r = PC_ReadToken(s, &tok); last = tok; fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "expstr")) { r = PC_ExpectTokenString(s, a[1]); fprintf(out, "R|%d\n", r); }
			else if (!strcmp(a[0], "exptype")) { r = PC_ExpectTokenType(s, atoi(a[1]), atoi(a[2]), &tok); fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "expany")) { r = PC_ExpectAnyToken(s, &tok); fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "chkstr")) { r = PC_CheckTokenString(s, a[1]); fprintf(out, "R|%d\n", r); }
			else if (!strcmp(a[0], "chktype")) { r = PC_CheckTokenType(s, atoi(a[1]), atoi(a[2]), &tok); fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "skip")) { r = PC_SkipUntilString(s, a[1]); fprintf(out, "R|%d\n", r); }
			else if (!strcmp(a[0], "unread")) { PC_UnreadLastToken(s); }
			else if (!strcmp(a[0], "unreadtok")) { PC_UnreadToken(s, &last); }
			else if (!strcmp(a[0], "readline")) { r = PC_ReadLine(s, &tok); last = tok; fprintf(out, "R|%d\n", r); if (r) print_token(&tok); }
			else if (!strcmp(a[0], "wsbefore")) { fprintf(out, "R|%d\n", PC_WhiteSpaceBeforeToken(&last)); }
			else if (!strcmp(a[0], "adddef")) { fprintf(out, "R|%d\n", PC_AddDefine(s, a[1])); }
			else if (!strcmp(a[0], "line")) { fprintf(out, "R|%d\n", s->scriptstack ? s->scriptstack->line : -1); }
			else fprintf(out, "?unknown op\n");
		}
		free(ops);
	}
}

/* mode seq (issue #254): the numbered sources of botlib (PC_LoadSourceHandle...) and the global defines that
 * they get when they are opened. Operations, one per line:
 *   gdef|text   PC_AddGlobalDefine         G|result
 *   rmall       PC_RemoveAllGlobalDefines
 *   load|file   PC_LoadSourceHandle        H|handle
 *   read|h|n    n tokens (0 = to the end)  K|type|subtype|intvalue (numbers only)|string, then R|last result
 *   free|h      PC_FreeSourceHandle        F|result
 *   where|h     PC_SourceFileAndLine       W|result|file|line
 */
static void run_seq(const char *opsfile)
{
	int len;
	char *ops = opsfile ? slurp(opsfile, &len) : NULL, *line, *next;
	if (!ops) { fprintf(out, "NOFILE\n"); return; }
	for (line = ops; line && *line; line = next)
	{
		char *a[MAXARGS];
		next = strchr(line, '\n');
		if (next) *next++ = 0;
		if (strchr(line, '\r')) *strchr(line, '\r') = 0;
		if (!*line) continue;
		split(line, a);
		fprintf(out, ">%s\n", a[0]);
		if (!strcmp(a[0], "gdef")) fprintf(out, "G|%d\n", PC_AddGlobalDefine(a[1]));
		else if (!strcmp(a[0], "rmall")) PC_RemoveAllGlobalDefines();
		else if (!strcmp(a[0], "load")) fprintf(out, "H|%d\n", PC_LoadSourceHandle(a[1]));
		else if (!strcmp(a[0], "free")) fprintf(out, "F|%d\n", PC_FreeSourceHandle(atoi(a[1])));
		else if (!strcmp(a[0], "where"))
		{
			char file[MAX_PATH + 1];
			int ln = 0, r;
			file[0] = 0;
			r = PC_SourceFileAndLine(atoi(a[1]), file, &ln);
			fprintf(out, "W|%d|%s|%d\n", r, file, ln);
		}
		else if (!strcmp(a[0], "read"))
		{
			int h = atoi(a[1]), n = atoi(a[2]), r = 0, i;
			pc_token_t t;
			for (i = 0; n == 0 || i < n; i++)
			{
				memset(&t, 0, sizeof(t));
				r = PC_ReadTokenHandle(h, &t);
				if (!r) break;
				fprintf(out, "K|%d|%d|", t.type, t.subtype);
				if (t.type == TT_NUMBER) fprintf(out, "%d|", t.intvalue); else fprintf(out, "-|");
				print_escaped(out, t.string);
				fputc('\n', out);
			}
			fprintf(out, "R|%d\n", r);
		}
		else fprintf(out, "?unknown op\n");
	}
	free(ops);
}

int main(int argc, char **argv)
{
	int len;
	char *cases, *line, *next;
	if (argc < 3) return 1;
	datafolder = argv[1];
	out = stdout;
	botimport.Print = Stub_Print;
	botimport.FS_FOpenFile = Stub_FOpenFile;
	botimport.FS_Read = Stub_Read;
	botimport.FS_FCloseFile = Stub_Close;
	cases = slurp(argv[2], &len);
	if (!cases) return 2;
	for (line = cases; line && *line; line = next)
	{
		char *a[MAXARGS + 8];
		int n, i, flags = 0, mem = 0;
		const char *ops = NULL;
		next = strchr(line, '\n');
		if (next) *next++ = 0;
		if (strchr(line, '\r')) *strchr(line, '\r') = 0;
		if (!*line || *line == '#') continue;
		{
			char *p = line;
			n = 0;
			a[n++] = p;
			while (*p && n < MAXARGS + 8) { if (*p == '|') { *p = 0; a[n++] = p + 1; } p++; }
		}
		hide_values = 0;
		PS_SetBaseFolder("");
		PC_RemoveAllGlobalDefines();
		fprintf(out, "CASE|%s|%s\n", a[1], a[0]);
		for (i = 3; i < n; i++)
		{
			if (!strncmp(a[i], "flags=", 6)) flags = atoi(a[i] + 6);
			else if (!strncmp(a[i], "mem=", 4)) mem = atoi(a[i] + 4);
			else if (!strncmp(a[i], "ops=", 4)) ops = a[i] + 4;
			else if (!strncmp(a[i], "nv=", 3)) hide_values = atoi(a[i] + 3);
			else if (!strncmp(a[i], "base=", 5)) PS_SetBaseFolder(a[i] + 5);
			else if (!strncmp(a[i], "gdef=", 5)) fprintf(out, "G|%d\n", PC_AddGlobalDefine(a[i] + 5));
		}
		if (!strcmp(a[0], "seq")) { run_seq(ops); continue; }
		if (!strcmp(a[0], "ps"))
		{
			script_t *s;
			if (mem)
			{
				int length;
				char *buf = slurp(a[2], &length);
				s = buf ? LoadScriptMemory(buf, length, a[2]) : NULL;
				free(buf);
			}
			else s = LoadScriptFile(a[2]);
			if (!s) { fprintf(out, "NOFILE\n"); continue; }
			SetScriptFlags(s, flags);
			run_ps(s, ops);
			FreeScript(s);
		}
		else
		{
			source_t *s;
			if (mem)
			{
				int length;
				char *buf = slurp(a[2], &length);
				s = buf ? LoadSourceMemory(buf, length, a[2]) : NULL;
				free(buf);
			}
			else s = LoadSourceFile(a[2]);
			if (!s) { fprintf(out, "NOFILE\n"); continue; }
			SetScriptFlags(s->scriptstack, flags);
			for (i = 3; i < n; i++)
			{
				if (!strncmp(a[i], "def=", 4)) fprintf(out, "D|%d\n", PC_AddDefine(s, a[i] + 4));
				else if (!strncmp(a[i], "inc=", 4)) PC_SetIncludePath(s, a[i] + 4);
				else if (!strncmp(a[i], "builtin=", 8)) PC_AddBuiltinDefines(s);
			}
			run_pc(s, ops);
			FreeSource(s);
		}
	}
	return 0;
}
