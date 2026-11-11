// Harness for Libs\XcomEngine (the sounds): the REAL SoundSet of OpenXcom (linked from a real build, see build.cmd)
// loads a CAT file as Mod::loadExtraResources does and writes, for every sound, the size and the FNV-1a 64 bit
// fingerprint of the samples that SDL_mixer keeps. The audio is opened with the dummy driver at 11025 Hz, 8 bit
// unsigned, mono: the format of the WAV files that SoundSet builds, so the samples are those of the WAV, unconverted.
// Contains no OpenXcom code; the output is compared with TXcomSoundConverter (Tests\Data\XcomEngine\sounds).
// usage: soundgen <cat file> <dos|wav|index> <output text file>
//   dos    SoundSet::loadCat(file, false)   SOUND1.CAT, SOUND2.CAT, INTRO.CAT of UFO
//   wav    SoundSet::loadCat(file, true)    SAMPLE.CAT, SAMPLE2.CAT, SAMPLE3.CAT
//   index  SoundSet::loadCatbyIndex(file, i) for every entry of the file (the soundDefs sets of TFTD)
#include <cstdio>
#include <cstdlib>
#include <string>
#include <fstream>
#include <SDL.h>
#include <SDL_mixer.h>
#define private public
#define protected public
#include "Engine/SoundSet.h"
#include "Engine/Sound.h"
#include "Engine/CatFile.h"
#include "Engine/Exception.h"
#undef protected
#undef private
#undef main
using namespace OpenXcom;

int main(int argc, char** argv) {
  if (argc < 4) { fprintf(stderr, "usage: soundgen <cat file> <dos|wav|index> <output>\n"); return 2; }
  std::string file = argv[1], mode = argv[2];
  SDL_putenv((char*)"SDL_AUDIODRIVER=dummy");
  if (SDL_Init(SDL_INIT_AUDIO) != 0) { fprintf(stderr, "SDL_Init: %s\n", SDL_GetError()); return 3; }
  if (Mix_OpenAudio(11025, AUDIO_U8, 1, 1024) != 0) { fprintf(stderr, "Mix_OpenAudio: %s\n", Mix_GetError()); return 3; }
  int rate = 0, channels = 0; Uint16 format = 0;
  Mix_QuerySpec(&rate, &format, &channels);
  std::ofstream out(argv[3]);
  out << "spec " << rate << " " << format << " " << channels << "\n";
  try {
    SoundSet set;
    int amount = 0;
    { CatFile cat(file.c_str()); if (!cat) throw Exception(file + " not found"); amount = cat.getAmount(); }
    if (mode == "index") { for (int i = 0; i < amount; i++) set.loadCatbyIndex(file, i); }
    else set.loadCat(file, mode == "wav");
    out << "sounds " << set.getTotalSounds() << "\n";
    for (int i = 0; i < amount; i++) {
      Sound* s = set.getSound(i);
      if (s == 0 || s->_sound == 0) {
        out << i << " none\n";
        if (getenv("SOUNDGEN_WHY")) {
          // why SDL_mixer refuses the entry as the file has it (not what loadCat makes of it)
          CatFile cat(file.c_str());
          char* raw = cat.load(i);
          SDL_RWops* rw = SDL_RWFromConstMem(raw, cat.getObjectSize(i));
          Mix_Chunk* c = Mix_LoadWAV_RW(rw, 1);
          fprintf(stderr, "%d size %u: %s\n", i, cat.getObjectSize(i), c ? "loads" : Mix_GetError());
        }
        continue;
      }
      unsigned long long h = 14695981039346656037ULL;
      for (Uint32 k = 0; k < s->_sound->alen; k++) h = (h ^ s->_sound->abuf[k]) * 1099511628211ULL;
      char text[64];
      snprintf(text, sizeof text, "%d %u %016llX\n", i, (unsigned)s->_sound->alen, h);
      out << text;
    }
  } catch (std::exception& e) { fprintf(stderr, "error: %s\n", e.what()); return 4; }
  return 0;
}
