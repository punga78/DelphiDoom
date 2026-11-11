// Harness for Libs\XcomFormats (TXcomFlcDecoder): the REAL FlcPlayer of OpenXcom (linked from a real build, see
// build.cmd) with a REAL Game (SDL dummy drivers) decodes a FLI/FLC file a frame at a time and writes, for every frame,
// the FNV-1a 64 bit fingerprint of the pixels of the screen surface and of the palette of the screen. The loop is the
// one of FlcPlayer::play (decodeVideo), with the speed of the header set to 0 so that the player does not wait.
// Contains no OpenXcom code; the output is compared with TXcomFlcDecoder (Tests\Data\XcomEngine\flc).
// usage: flcgen <data> <user> <flc file> <output text file> [skiplast]
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <sstream>
#include <string>
#include <fstream>
#include <SDL.h>
#define private public
#define protected public
#include "Engine/Game.h"
#include "Engine/State.h"
#include "Engine/Options.h"
#include "Engine/Logger.h"
#include "Engine/Screen.h"
#include "Engine/Surface.h"
#include "Engine/FlcPlayer.h"
#include "Menu/CutsceneState.h"
#undef protected
#undef private
#undef main
using namespace OpenXcom;

static std::string Hex(unsigned long long h) {
  char text[32];
  snprintf(text, sizeof text, "%016llX", h);
  return text;
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: flcgen <data> <user> <flc file> <output> [skiplast]\n"); return 2; }
  _putenv("SDL_VIDEODRIVER=dummy");
  _putenv("SDL_AUDIODRIVER=dummy");
  std::string data = argv[1], user = argv[2];
  bool skipLast = argc > 5;
  static char a0[] = "flcgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  try {
    Options::mute = true;
    Game* game = new Game("flcgen");
    State::setGamePtr(game);
    CutsceneState::initDisplay();
    FlcPlayer* p = new FlcPlayer();
    if (!p->init(argv[3], 0, game, false, 0, 0)) { fprintf(stderr, "init failed\n"); return 4; }
    std::ofstream out(argv[4]);
    SDL_Surface* s = p->_mainScreen;
    out << "flc " << p->_headerWidth << " " << p->_headerHeight << " " << p->_headerFrames << " " << p->_headerSpeed
        << " " << p->_headerType << " screen " << s->w << " " << s->h << "\n";
    // the start of FlcPlayer::play
    p->_playingState = 0;
    p->_dy = (s->h - p->_headerHeight) / 2;
    p->_offset = p->_dy * s->pitch + s->format->BytesPerPixel * p->_dx;
    p->_videoFrameData = p->_fileBuf + 128;
    p->_audioFrameData = p->_videoFrameData;
    p->_headerSpeed = 0;
    int last = -1;
    while (!p->shouldQuit()) {
      p->decodeVideo(skipLast);
      if (p->_frameCount == last) continue;
      last = p->_frameCount;
      unsigned long long h = 14695981039346656037ULL;
      for (int y = 0; y < s->h; y++) {
        const Uint8* row = (const Uint8*)s->pixels + y * s->pitch;
        for (int x = 0; x < s->w; x++) h = (h ^ row[x]) * 1099511628211ULL;
      }
      unsigned long long c = 14695981039346656037ULL;
      SDL_Color* pal = game->getScreen()->getPalette();
      for (int i = 0; i < 256; i++) {
        c = (c ^ pal[i].r) * 1099511628211ULL;
        c = (c ^ pal[i].g) * 1099511628211ULL;
        c = (c ^ pal[i].b) * 1099511628211ULL;
      }
      out << last << " " << Hex(h) << " " << Hex(c) << " " << p->_delayOverride << "\n";
    }
    out << "end " << p->_frameCount << " " << p->_playingState << "\n";
  } catch (std::exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok\n");
  return 0;
}
