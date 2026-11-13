/*
 * Parity tool of the issue #123 (characters, fuzzy weights and weapons of the bots of Quake III Arena).
 *
 * It links the REAL be_ai_char.c, be_ai_weight.c, be_ai_weap.c (included below, so their static data
 * is visible), l_struct.c, l_libvar.c, l_script.c and l_precomp.c of code/botlib (read only, copied by
 * build.sh) with the stubs of the folder stub/, and runs the commands of a scenario file
 * (Tests/Data/BotAi/botscenario.txt), one per line:
 *     command|argument|argument...
 * Arguments accept the escapes \t \n \r \\ \xNN. For every command the line is echoed (prefix ">") and the
 * results are printed. What the library prints (botimport.Print) is a line "P<level>|text", what it writes
 * to its log "L|text". Floats are printed as their bits and, if finite, with %f: "3F800000(1.000000)".
 *
 *   botgen <data folder> <scenario file>   (the data folder contains botfiles/)
 */
#include "game/q_shared.h"
#include "game/botlib.h"

/* the real code (one translation unit: the headers of the original have no include guards,
   build.sh adds them) */
#include "botlib/l_libvar.h"
#include "botlib/be_ai_char.c"
#include "botlib/be_ai_weight.c"
#include "botlib/be_ai_weap.c"

float LibVarStringValue(char *string);

static const char *datafolder;
static FILE *out;
botlib_import_t botimport;
int bot_developer;

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
	/* BotDumpCharacter writes the skill, a float, with %d: undefined, not part of the golden */
	if (!strcmp(fmt, "skill %d\n")) return;
	va_start(ap, fmt);
	vsnprintf(text, sizeof(text), fmt, ap);
	va_end(ap);
	fprintf(out, "L|");
	print_escaped(out, text);
	fputc('\n', out);
}
void Log_Print(char *fmt, ...) { (void) fmt; }
FILE *Log_FilePointer(void) { return NULL; }
FILE *Log_FileStruct(void) { return NULL; }

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

#define MAXARGS 80
static char *args[MAXARGS];
static int numargs;

static char *arg(int i)
{
	if (i >= numargs) return "";
	return args[i];
}
static long num(int i) { return strtol(arg(i), NULL, 0); }
static float fnum(int i) { return (float) atof(arg(i)); }

static char *fmtfloat(float f)
{
	static char buf[4][64];
	static int n;
	unsigned u;
	char *b = buf[n++ & 3];
	memcpy(&u, &f, 4);
	if (f != f) sprintf(b, "%08X(nan)", u);
	else if (f > 3.4e38f || f < -3.4e38f) sprintf(b, "%08X(%s)", u, f > 0 ? "inf" : "-inf");
	else sprintf(b, "%08X(%f)", u, f);
	return b;
}

static unsigned fnv(const unsigned char *p, int n)
{
	unsigned h = 2166136261u;
	while (n-- > 0) { h ^= *p++; h *= 16777619u; }
	return h;
}


static int inventory[1024];
static int *make_inventory(int first)
{
	int i;
	memset(inventory, 0, sizeof(inventory));
	for (i = first; i < numargs && i - first < 1024; i++) inventory[i - first] = (int) strtol(args[i], NULL, 0);
	return inventory;
}

static weightconfig_t *wcs[16];

static void dump_separator(fuzzyseperator_t *fs, int depth)
{
	for (; fs; fs = fs->next)
	{
		fprintf(out, "%*sidx=%d val=%d type=%d w=%s min=%s max=%s\n", depth * 2, "", fs->index, fs->value, fs->type,
			fmtfloat(fs->weight), fmtfloat(fs->minweight), fmtfloat(fs->maxweight));
		if (fs->child) dump_separator(fs->child, depth + 1);
	}
}

static void dump_weights(int slot)
{
	int i;
	weightconfig_t *wc = wcs[slot];
	if (!wc) { fprintf(out, "noweights\n"); return; }
	fprintf(out, "weights n=%d file=", wc->numweights);
	print_escaped(out, wc->filename);
	fputc('\n', out);
	for (i = 0; i < wc->numweights; i++)
	{
		fprintf(out, "w%d name=", i);
		print_escaped(out, wc->weights[i].name);
		fputc('\n', out);
		dump_separator(wc->weights[i].firstseperator, 1);
	}
}

static void dump_character(int h)
{
	int i;
	bot_character_t *ch;
	if (h <= 0 || h > MAX_CLIENTS || !botcharacters[h]) { fprintf(out, "nochar\n"); return; }
	ch = botcharacters[h];
	fprintf(out, "char file=");
	print_escaped(out, ch->filename);
	fprintf(out, " skill=%s\n", fmtfloat(ch->skill));
	for (i = 0; i <= MAX_CHARACTERISTICS; i++)
	{
		switch (ch->c[i].type)
		{
			case CT_INTEGER: fprintf(out, "c%d int %d\n", i, ch->c[i].value.integer); break;
			case CT_FLOAT: fprintf(out, "c%d float %s\n", i, fmtfloat(ch->c[i].value._float)); break;
			case CT_STRING: fprintf(out, "c%d string ", i); print_escaped(out, ch->c[i].value.string); fputc('\n', out); break;
		}
	}
}

static void dump_struct(structdef_t *def, char *structure)
{
	FILE *fp = fopen("struct.tmp", "wb+");
	int c;
	if (!fp) { fprintf(out, "cannot open struct.tmp\n"); return; }
	WriteStructure(fp, def, structure);
	fflush(fp);
	fseek(fp, 0, SEEK_SET);
	while ((c = fgetc(fp)) != EOF)
	{
		if (c < 32 || c > 126 || c == '\\') fprintf(out, "\\x%02X", c);
		else fputc(c, out);
		if (c == '\n') fputc('\n', out);
	}
	fclose(fp);
	remove("struct.tmp");
}

static void dump_weaponinfo(weaponinfo_t *w)
{
	fprintf(out, "weapon valid=%d hash=%08X\n", w->valid, fnv((unsigned char *) w, sizeof(weaponinfo_t)));
	dump_struct(&weaponinfo_struct, (char *) w);
}

static void dump_weaponconfig(void)
{
	int i;
	if (!weaponconfig) { fprintf(out, "noweaponconfig\n"); return; }
	fprintf(out, "weaponconfig numweapons=%d numprojectiles=%d sizes=%d,%d\n", weaponconfig->numweapons,
		weaponconfig->numprojectiles, (int) sizeof(weaponinfo_t), (int) sizeof(projectileinfo_t));
	for (i = 0; i < weaponconfig->numprojectiles; i++)
	{
		fprintf(out, "projectile %d hash=%08X\n", i, fnv((unsigned char *) &weaponconfig->projectileinfo[i], sizeof(projectileinfo_t)));
		dump_struct(&projectileinfo_struct, (char *) &weaponconfig->projectileinfo[i]);
	}
	for (i = 0; i < weaponconfig->numweapons; i++)
	{
		if (!weaponconfig->weaponinfo[i].valid) continue;
		fprintf(out, "slot %d ", i);
		dump_weaponinfo(&weaponconfig->weaponinfo[i]);
	}
}

/* a structure with every kind of field, packed: Delphi has the same offsets (TestStruct in the runner) */
static fielddef_t sub_fields[] =
{
	{"x", 0, FT_INT},
	{"y", 4, FT_INT},
	{NULL, 0, 0, 0}
};
static structdef_t sub_def = { 8, sub_fields };
static fielddef_t test_fields[] =
{
	{"c", 0, FT_CHAR},
	{"uc", 1, FT_CHAR|FT_UNSIGNED},
	{"i", 2, FT_INT},
	{"ui", 6, FT_INT|FT_UNSIGNED},
	{"f", 10, FT_FLOAT},
	{"bf", 14, FT_FLOAT|FT_BOUNDED, 0, -1.0f, 2.5f},
	{"bi", 18, FT_INT|FT_BOUNDED, 0, -10.0f, 10.0f},
	{"s", 22, FT_STRING},
	{"a", 102, FT_FLOAT|FT_ARRAY, 3},
	{"ia", 114, FT_INT|FT_ARRAY, 3},
	{"sub", 126, FT_STRUCT, 0, 0, 0, &sub_def},
	{"cb", 134, FT_CHAR|FT_BOUNDED, 0, -5.0f, 5.0f},
	{NULL, 0, 0, 0}
};
static structdef_t test_def = { 135, test_fields };

static void run_struct(char *file)
{
	source_t *source;
	char buf[135];
	int r;
	PC_SetBaseFolder(BOTFILESBASEFOLDER);
	source = LoadSourceFile(file);
	if (!source) { fprintf(out, "struct nosource\n"); return; }
	memset(buf, 0, sizeof(buf));
	r = ReadStructure(source, &test_def, buf);
	FreeSource(source);
	fprintf(out, "struct=%d hash=%08X\n", r, fnv((unsigned char *) buf, sizeof(buf)));
	dump_struct(&test_def, buf);
}

static void run(char *line)
{
	char *cmd, *p;
	int i;
	numargs = 0;
	cmd = line;
	for (p = line; ; p++)
	{
		if (*p == '|' || *p == 0)
		{
			int last = (*p == 0);
			*p = 0;
			if (numargs < MAXARGS) { args[numargs] = cmd; numargs++; }
			cmd = p + 1;
			if (last) break;
		}
	}
	for (i = 0; i < numargs; i++) unescape(args[i]);
	cmd = args[0];
	/* the arguments of the command start at index 1: shift */
	args[0] = "";
	/* ---- library variables */
	if (!strcmp(cmd, "libset")) LibVarSet(arg(1), arg(2));
	else if (!strcmp(cmd, "libget"))
	{
		fprintf(out, "libget text=");
		print_escaped(out, LibVarGetString(arg(1)));
		fprintf(out, " value=%s changed=%d\n", fmtfloat(LibVarGetValue(arg(1))), LibVarChanged(arg(1)));
	}
	else if (!strcmp(cmd, "libval")) fprintf(out, "libval=%s\n", fmtfloat(LibVarValue(arg(1), arg(2))));
	else if (!strcmp(cmd, "libstr"))
	{
		fprintf(out, "libstr=");
		print_escaped(out, LibVarString(arg(1), arg(2)));
		fputc('\n', out);
	}
	else if (!strcmp(cmd, "libnotmod")) LibVarSetNotModified(arg(1));
	else if (!strcmp(cmd, "libconv")) fprintf(out, "libconv=%s\n", fmtfloat(LibVarStringValue(arg(1))));
	else if (!strcmp(cmd, "struct")) run_struct(arg(1));
	/* ---- characters */
	else if (!strcmp(cmd, "char")) fprintf(out, "char=%d\n", BotLoadCharacter(arg(1), fnum(2)));
	else if (!strcmp(cmd, "chardump")) dump_character((int) num(1));
	else if (!strcmp(cmd, "charfree")) BotFreeCharacter((int) num(1));
	else if (!strcmp(cmd, "charshutdown")) BotShutdownCharacters();
	else if (!strcmp(cmd, "cfloat")) fprintf(out, "cfloat=%s\n", fmtfloat(Characteristic_Float((int) num(1), (int) num(2))));
	else if (!strcmp(cmd, "cbfloat")) fprintf(out, "cbfloat=%s\n", fmtfloat(Characteristic_BFloat((int) num(1), (int) num(2), fnum(3), fnum(4))));
	else if (!strcmp(cmd, "cint")) fprintf(out, "cint=%d\n", Characteristic_Integer((int) num(1), (int) num(2)));
	else if (!strcmp(cmd, "cbint")) fprintf(out, "cbint=%d\n", Characteristic_BInteger((int) num(1), (int) num(2), (int) num(3), (int) num(4)));
	else if (!strcmp(cmd, "cstr"))
	{
		char buf[256];
		memset(buf, 0, sizeof(buf));
		Characteristic_String((int) num(1), (int) num(2), buf, (int) num(3));
		fprintf(out, "cstr=");
		print_escaped(out, buf);
		fputc('\n', out);
	}
	/* ---- fuzzy weights: slots 0..15 */
	else if (!strcmp(cmd, "wread"))
	{
		int slot = (int) num(1), k, same = -1;
		wcs[slot] = ReadWeightConfig(arg(2));
		for (k = 0; k < 16; k++) if (k != slot && wcs[k] && wcs[k] == wcs[slot]) { same = k; break; }
		fprintf(out, "wread ok=%d same=%d\n", wcs[slot] != NULL, same);
	}
	else if (!strcmp(cmd, "wdump")) dump_weights((int) num(1));
	else if (!strcmp(cmd, "wfree"))
	{
		int slot = (int) num(1), k;
		if (wcs[slot]) FreeWeightConfig(wcs[slot]);
		/* a freed configuration is not read again (the slot and the ones that share it are cleared if it was freed) */
		if (LibVarGetValue("bot_reloadcharacters"))
		{
			weightconfig_t *gone = wcs[slot];
			for (k = 0; k < 16; k++) if (wcs[k] == gone) wcs[k] = NULL;
		}
	}
	else if (!strcmp(cmd, "wshutdown"))
	{
		int k;
		BotShutdownWeights();
		for (k = 0; k < 16; k++) wcs[k] = NULL;
	}
	else if (!strcmp(cmd, "wfind")) fprintf(out, "wfind=%d\n", FindFuzzyWeight(wcs[num(1)], arg(2)));
	else if (!strcmp(cmd, "wfuzzy")) fprintf(out, "wfuzzy=%s\n", fmtfloat(FuzzyWeight(make_inventory(3), wcs[num(1)], (int) num(2))));
	else if (!strcmp(cmd, "wundecided"))
	{
		float r;
		srand((unsigned) num(3));
		r = FuzzyWeightUndecided(make_inventory(4), wcs[num(1)], (int) num(2));
		fprintf(out, "wundecided=%s\n", fmtfloat(r));
	}
	else if (!strcmp(cmd, "wscale")) ScaleWeight(wcs[num(1)], arg(2), fnum(3));
	else if (!strcmp(cmd, "wrange")) ScaleFuzzyBalanceRange(wcs[num(1)], fnum(2));
	else if (!strcmp(cmd, "wevolve")) { srand((unsigned) num(2)); EvolveWeightConfig(wcs[num(1)]); }
	else if (!strcmp(cmd, "wbreed")) InterbreedWeightConfigs(wcs[num(1)], wcs[num(2)], wcs[num(3)]);
	/* ---- weapons */
	else if (!strcmp(cmd, "wpsetup")) fprintf(out, "wpsetup=%d\n", BotSetupWeaponAI());
	else if (!strcmp(cmd, "wpdump")) dump_weaponconfig();
	else if (!strcmp(cmd, "wpshutdown")) BotShutdownWeaponAI();
	else if (!strcmp(cmd, "wpalloc")) fprintf(out, "wpalloc=%d\n", BotAllocWeaponState());
	else if (!strcmp(cmd, "wpfree")) BotFreeWeaponState((int) num(1));
	else if (!strcmp(cmd, "wpreset")) BotResetWeaponState((int) num(1));
	else if (!strcmp(cmd, "wpweights")) fprintf(out, "wpweights=%d\n", BotLoadWeaponWeights((int) num(1), arg(2)));
	else if (!strcmp(cmd, "wpbest")) fprintf(out, "wpbest=%d\n", BotChooseBestFightWeapon((int) num(1), make_inventory(2)));
	else if (!strcmp(cmd, "wpinfo"))
	{
		weaponinfo_t info;
		memset(&info, 0, sizeof(info));
		BotGetWeaponInfo((int) num(1), (int) num(2), &info);
		fprintf(out, "wpinfo ");
		dump_weaponinfo(&info);
	}
	else fprintf(out, "UNKNOWN COMMAND %s\n", cmd);
}

int main(int argc, char **argv)
{
	FILE *scenario;
	char line[4096];

	if (argc < 3) { fprintf(stderr, "usage: botgen <data folder> <scenario>\n"); return 1; }
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
