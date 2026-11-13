/*
 * Parity driver of the FLIC decoder (issue #199).
 *
 * flc_original.inc is made by build.sh of line ranges of
 * Reference\OpenXcom\src\Engine\FlcPlayer.cpp (the decoder: readFileHeader, isValidFrame,
 * decodeVideo, playVideoFrame, color256, fliSS2, fliBRun, fliLC, color64, fliCopy, black,
 * isEndOfFile, shouldQuit, readU16/readU32/readS16 of the little endian build): it is not
 * retyped. The screen, the surface and the log are the stubs below, the real FlcPlayer.h
 * is the one of OpenXcom (the harness opens its private members). The only new code is the
 * driver: it does what FlcPlayer::play does (without audio, polling or clock) and, on every
 * "flip", prints the CRC-32 of the pixels of the picture (width*height bytes, pitch =
 * width) and of the palette (256 colors, 3 bytes) and the delay that decodeVideo asked for.
 *
 *   flcextract file.flc [skiplast]
 */
#include <algorithm>
#include <iostream>
#include <vector>
#include "SDL.h"

#define private public
#include "FlcPlayer.h"
#undef private

static unsigned int crc32(const unsigned char *data, size_t length)
{
	static unsigned int table[256];
	if (table[1] == 0)
		for (unsigned int i = 0; i < 256; i++)
		{
			unsigned int c = i;
			for (int k = 0; k < 8; k++)
				c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
			table[i] = c;
		}
	unsigned int crc = 0xFFFFFFFFu;
	for (size_t i = 0; i < length; i++)
		crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8);
	return crc ^ 0xFFFFFFFFu;
}

enum { LOG_WARNING };
struct NullLog
{
	template <class T> NullLog &operator<<(const T &) { return *this; }
};
#define Log(x) NullLog()

namespace OpenXcom
{

class Surface
{
public:
	SDL_Surface *s;
	SDL_Surface *getSurface() { return s; }
};

class Screen
{
public:
	Surface surf;
	SDL_Color pal[256];
	void (*onFlip)(Screen *);
	Surface *getSurface() { return &surf; }
	void flip() { onFlip(this); }
	void setPalette(SDL_Color *colors, int first, int n, bool)
	{
		for (int i = 0; i < n; i++)
			if (first + i < 256)
				pal[first + i] = colors[i];
	}
};

static Uint32 lastDelay;

FlcPlayer::FlcPlayer() : _fileBuf(0), _mainScreen(0), _realScreen(0), _game(0) {}
FlcPlayer::~FlcPlayer() {}
void FlcPlayer::waitForNextFrame(Uint32 delay) { lastDelay = delay; }

#include "flc_original.inc"

}

using namespace OpenXcom;

static int frameNumber;

static void onFlip(Screen *screen)
{
	SDL_Surface *s = screen->surf.s;
	unsigned char palette[768];
	for (int i = 0; i < 256; i++)
	{
		palette[i * 3] = screen->pal[i].r;
		palette[i * 3 + 1] = screen->pal[i].g;
		palette[i * 3 + 2] = screen->pal[i].b;
	}
	if (getenv("FLCDUMP"))
	{
		printf("dump %d ", frameNumber);
		for (size_t i = 0; i < (size_t)s->w * s->h; i++)
			printf("%02x", ((unsigned char *)s->pixels)[i]);
		printf("\n");
	}
	printf("frame %d pix %08x pal %08x delay %u\n", frameNumber++,
		crc32((const unsigned char *)s->pixels, (size_t)s->w * s->h), crc32(palette, 768),
		(unsigned)lastDelay);
}

int main(int argc, char **argv)
{
	if (argc < 2)
		return 2;
	FILE *f = fopen(argv[1], "rb");
	if (!f)
		return 1;
	fseek(f, 0, SEEK_END);
	long size = ftell(f);
	fseek(f, 0, SEEK_SET);
	std::vector<Uint8> bytes(size + 64);
	fread(&bytes[0], 1, size, f);
	fclose(f);
	bool skipLast = argc > 2;

	FlcPlayer player;
	player._fileBuf = &bytes[0];
	player._fileSize = (Uint32)size;
	player.readFileHeader();
	if (player._headerType != FLI_TYPE && player._headerType != FLC_TYPE)
	{
		printf("not a flic\n");
		return 3;
	}
	player._screenWidth = player._headerWidth;
	player._screenHeight = player._headerHeight;
	printf("header type %04x frames %u size %ux%u speed %u\n", player._headerType,
		player._headerFrames, player._headerWidth, player._headerHeight, player._headerSpeed);

	std::vector<Uint8> pixels((size_t)player._headerWidth * player._headerHeight + 65536, 0);
	SDL_PixelFormat format = { 1, 8 };
	SDL_Surface surface = { &pixels[0], player._headerWidth, player._headerWidth, player._headerHeight, &format };
	Screen screen;
	memset(screen.pal, 0, sizeof(screen.pal));
	screen.surf.s = &surface;
	screen.onFlip = onFlip;
	player._mainScreen = &surface;
	player._realScreen = &screen;
	player._frameCallBack = 0;
	player._useInternalAudio = false;
	player._dx = 0;
	player._frameCount = 0;

	// FlcPlayer::play without audio, polling and clock
	player._playingState = PLAYING;
	player._dy = (player._mainScreen->h - player._headerHeight) / 2;
	player._offset = player._dy * player._mainScreen->pitch + player._mainScreen->format->BytesPerPixel * player._dx;
	player._videoFrameData = player._fileBuf + 128;
	player._audioFrameData = player._videoFrameData;
	while (!player.shouldQuit())
		player.decodeVideo(skipLast);
	printf("end frames %d\n", frameNumber);
	return 0;
}
