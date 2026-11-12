/* Harness of the AdLib sound effects of Keen Dreams (issue #165, K10): runs the original id_sd.c (compiled with
   Open Watcom 16 bit) on the scripts of SCEN.TXT and writes every register that alOut would send to the card.
   ID_SD_P.C is id_sd.c with one change made by Build-AudioHarness.cmd: the body of alOut (the two "out" to the
   ports 388h and 389h and the delays) is renamed alOut_hw, and alOut is the function below that writes the log.
   The timer interrupt is not installed: the script calls SDL_ALSoundService itself ("T n" is n services).
   See Tools\Verifica\165\LEGGIMI.md */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ID_SD_P.C"

unsigned audiosegs[NUMSNDCHUNKS];
static int logon;

void alOut(byte n, byte b)
{
	if (logon)
		printf("w %u %u\n", (unsigned)n, (unsigned)b);
}

void Quit(char *error)
{
	printf("QUIT %s\n", error);
	exit(1);
}

int US_CheckParm(char *parm, char **strings)
{
	return -1;
}

void main(void)
{
	FILE *in;
	char op[16], a[16], b[16];
	int i, n, v, idx, count;
	long len;
	unsigned seg;
	byte far *p;

	in = fopen("SCEN.TXT", "r");
	if (!in)
		Quit("no SCEN.TXT");
	for (i = 0; i < NUMSOUNDS; i++)
	{
		if (_dos_allocmem(64, &seg))
			Quit("no memory");
		audiosegs[STARTADLIBSOUNDS + i] = seg;
	}
	AdLibPresent = true;
	while (fscanf(in, "%15s", op) == 1)
	{
		switch (op[0])
		{
		case 'S':
			fscanf(in, "%15s %15s", a, b);
			logon = 0;
			SD_SetSoundMode(sdm_Off);
			logon = 1;
			printf("S %s %s\n", a, b);
			break;
		case 'D':
			fscanf(in, "%d %ld %d", &idx, &len, &v);
			p = MK_FP(audiosegs[STARTADLIBSOUNDS + idx], 0);
			p[0] = (byte)len;
			p[1] = (byte)(len >> 8);
			p[2] = (byte)(len >> 16);
			p[3] = (byte)(len >> 24);
			p[4] = (byte)v;
			p[5] = (byte)(v >> 8);
			for (i = 0; i < 17; i++)
			{
				fscanf(in, "%d", &v);
				p[6 + i] = (byte)v;
			}
			fscanf(in, "%d", &count);
			for (i = 0; i < count; i++)
			{
				fscanf(in, "%d", &v);
				p[23 + i] = (byte)v;
			}
			break;
		case 'M':
			fscanf(in, "%d", &v);
			n = SD_SetSoundMode(v);
			printf("m %d\n", n ? 1 : 0);
			break;
		case 'P':
			fscanf(in, "%d", &v);
			printf("p\n");
			SD_PlaySound(v);
			break;
		case 'T':
			fscanf(in, "%d", &count);
			for (i = 0; i < count; i++)
			{
				printf("t\n");
				SDL_ALSoundService();
			}
			break;
		case 'X':
			printf("x\n");
			SD_StopSound();
			break;
		case 'Q':
			printf("q %u\n", SD_SoundPlaying());
			break;
		case 'E':
			printf("E\n");
			break;
		default:
			printf("unknown %s\n", op);
			exit(1);
		}
	}
	logon = 0;
	SD_SetSoundMode(sdm_Off);
	fclose(in);
}
