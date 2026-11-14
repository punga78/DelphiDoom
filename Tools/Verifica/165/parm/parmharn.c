/* Harness of US_CheckParm of Keen Dreams (issue #165): the original function, cut out of id_us.c by
   Run-ParmParity.ps1 (USCHECK.INC) and compiled with Open Watcom 16 bit, answers a list of parameters against the
   five tables of strings that the managers of the game have (ParmStrings of id_in.c, id_rf.c, id_sd.c, id_us.c and
   id_vw.c). One line for each case: parameter, table, index. Parameters without a letter are not asked: the C runs
   past the end of the string (the port answers -1, a difference that has its own test). */
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#define nil 0

#include "USCHECK.INC"

static char *InputParms[] = {"nojoys","nomouse",nil};
static char *RefreshParms[] = {"comp",""};
static char *SoundParms[] = {"noal","nosb","nodr","noss","sst","ss1","ss2","ss3",nil};
static char *UserParms[] = {"TEDLEVEL",""};
static char *VideoParms[] = {"HIDDENCARD",""};

static char **tables[5] = {InputParms, RefreshParms, SoundParms, UserParms, VideoParms};
static char *names[5] = {"input", "refresh", "sound", "user", "video"};

static char *parms[] = {
	"nomouse", "NOMOUSE", "NoMouse", "-nomouse", "/nomouse", "--nomouse", "-9nomouse", "nomouse2", "nomouseXYZ",
	"nojoys", "-NOJOYS", "nojoy", "nomous", "no", "n", "comp", "-comp", "COMP", "compat", "co", "noal", "-noal",
	"nosb", "nodr", "noss", "sst", "ss1", "ss2", "ss3", "ss4", "ss", "ss12", "-ss2", "tedlevel", "TEDLEVEL",
	"-TedLevel", "tedlevl", "hiddencard", "HIDDENCARD", "-HiddenCard", "hidden", "a", "z", "ZZZ", "Comp1",
	"nomouse-", "x-nomouse", "1x", "-x", "no mouse", "noMOUSE", "NoJoys", "sst2", "ss1x", "nosbx", "nodrx",
	"n0mouse", "nomouse\x7f", nil
};

int main(void)
{
	int i, t;
	FILE *f = fopen("OUT.TXT", "w");
	if (!f) return 1;
	for (i = 0; parms[i]; i++)
		for (t = 0; t < 5; t++)
			fprintf(f, "%s\t%s\t%d\n", parms[i], names[t], US_CheckParm(parms[i], tables[t]));
	fprintf(f, "E\n");
	fclose(f);
	return 0;
}
