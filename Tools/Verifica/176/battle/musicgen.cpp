// Harness for Libs\XcomAudio (the music): the REAL Mod of OpenXcom (linked from a real build, see build.cmd) loads the
// mods of options.cfg with the sound on (SDL_mixer with the dummy driver, 22050 Hz, 16 bit, stereo) and writes which
// music of the rules it loaded: one line per music of Mod::_musics, "type adlib <bytes> <FNV-1a 64 of the song>" for
// an AdlibMusic and "type other" for anything else, and "type missing" for a rule of musics: that has no music.
// Also the sound sets it loaded: "set <name> <sounds>". Contains no OpenXcom code.
// usage: musicgen <data folder> <user folder> <output text file>
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <map>
#include <fstream>
#include <SDL.h>
#include <SDL_mixer.h>
#define private public
#define protected public
#include "Mod/Mod.h"
#include "Mod/RuleMusic.h"
#include "Engine/Music.h"
#include "Engine/AdlibMusic.h"
#include "Engine/SoundSet.h"
#include "Engine/Sound.h"
#include "Engine/Options.h"
#include "Engine/FileMap.h"
#include "Engine/Logger.h"
#include "Engine/Exception.h"
#undef protected
#undef private
#undef main
using namespace OpenXcom;

int main(int argc, char** argv) {
  if (argc < 4) { fprintf(stderr, "usage: musicgen <data> <user> <output>\n"); return 2; }
  std::string data = argv[1], user = argv[2];
  static char a0[] = "musicgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  SDL_putenv((char*)"SDL_AUDIODRIVER=dummy");
  SDL_putenv((char*)"SDL_VIDEODRIVER=dummy");
  if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO) != 0) { fprintf(stderr, "SDL_Init: %s\n", SDL_GetError()); return 3; }
  if (Mix_OpenAudio(22050, AUDIO_S16SYS, 2, 1024) != 0) { fprintf(stderr, "Mix_OpenAudio: %s\n", Mix_GetError()); return 3; }
  Options::mute = false;
  Options::audioBitDepth = 16;
  if (getenv("MUSICGEN_PREFERRED_MUSIC")) Options::preferredMusic = (MusicFormat)atoi(getenv("MUSICGEN_PREFERRED_MUSIC"));
  if (getenv("MUSICGEN_PREFERRED_SOUND")) Options::preferredSound = (SoundFormat)atoi(getenv("MUSICGEN_PREFERRED_SOUND"));
  try {
    Options::updateMods();
    Mod::resetGlobalStatics();
    Mod* mod = new Mod();
    mod->loadAll(FileMap::getRulesets());
    std::ofstream out(argv[3]);
    out << "currentSound " << (int)Options::currentSound << "\n";
    for (std::map<std::string, RuleMusic*>::const_iterator i = mod->_musicDefs.begin(); i != mod->_musicDefs.end(); ++i) {
      std::map<std::string, Music*>::const_iterator m = mod->_musics.find(i->first);
      if (m == mod->_musics.end()) { out << i->first << " missing\n"; continue; }
      AdlibMusic* a = dynamic_cast<AdlibMusic*>(m->second);
      if (a == 0) { out << i->first << " other\n"; continue; }
      unsigned long long h = 14695981039346656037ULL;
      for (size_t k = 0; k < a->_size; k++) h = (h ^ (unsigned char)a->_data[k]) * 1099511628211ULL;
      char text[96];
      snprintf(text, sizeof text, " adlib %u %016llX\n", (unsigned)a->_size, a->_data ? h : 0ULL);
      out << i->first << text;
    }
    for (std::map<std::string, SoundSet*>::const_iterator i = mod->_sounds.begin(); i != mod->_sounds.end(); ++i) {
      int loaded = 0;
      for (std::map<int, Sound*>::const_iterator s = i->second->_sounds.begin(); s != i->second->_sounds.end(); ++s)
        if (s->second && s->second->_sound) loaded++;
      out << "set " << i->first << " " << i->second->_sounds.size() << " " << loaded << "\n";
    }
  } catch (std::exception& e) { fprintf(stderr, "EXCEPTION: %s\n", e.what()); return 4; }
  return 0;
}
