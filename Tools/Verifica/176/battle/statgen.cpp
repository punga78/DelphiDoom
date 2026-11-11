// Harness for Libs\XcomBasescape (TXcomGameStatistics): the REAL StatisticsState of OpenXcom (constructor: listStats) on
// every saved game of a folder, with a REAL Game (SDL dummy drivers) and no texts loaded (tr(key) gives the key).
// Writes NAME.stat.txt: the title and the rows of the list (key, value). Contains no OpenXcom code.
// usage: statgen <data> <user> <folder of the .sav> <out folder>
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <windows.h>
#define private public
#define protected public
#include "Engine/Game.h"
#include "Engine/State.h"
#include "Engine/Options.h"
#include "Engine/Logger.h"
#include "Engine/Exception.h"
#include "Engine/RNG.h"
#include "Engine/Language.h"
#include "Interface/Text.h"
#include "Interface/TextList.h"
#include "Mod/Mod.h"
#include "Savegame/SavedGame.h"
#include "Menu/StatisticsState.h"
#undef protected
#undef private
#undef main
using namespace OpenXcom;

static void CopyFileBinary(const std::string& from, const std::string& to) {
  std::ifstream in(from.c_str(), std::ios::binary);
  std::ofstream o(to.c_str(), std::ios::binary);
  o << in.rdbuf();
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: statgen <data> <user> <saves> <out>\n"); return 2; }
  _putenv("SDL_VIDEODRIVER=dummy");
  _putenv("SDL_AUDIODRIVER=dummy");
  std::string data = argv[1], user = argv[2], saves = argv[3], out = argv[4];
  static char a0[] = "statgen", a1[] = "-data", a3[] = "-user", a5[] = "-cfg";
  std::string cfg = user;
  char* args[] = {a0, a1, (char*)data.c_str(), a3, (char*)user.c_str(), a5, (char*)cfg.c_str()};
  Logger::reportingLevel() = LOG_ERROR;
  if (!Options::init(7, args)) return 3;
  int done = 0;
  try {
    Options::updateMods();
    Game* game = new Game("statgen");
    State::setGamePtr(game);
    Options::baseXResolution = Options::displayWidth;
    Options::baseYResolution = Options::displayHeight;
    game->loadMods();
    game->loadLanguages();
    Options::mute = true;
    game->_lang = new Language();
    std::string folder = Options::getMasterUserFolder();
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA((saves + "/*.sav").c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return 4;
    do {
      std::string name = fd.cFileName;
      if (name.find(".re.") != std::string::npos) continue;
      CopyFileBinary(saves + "/" + name, folder + "statin.sav");
      try {
        SavedGame* s = new SavedGame();
        s->load("statin.sav", game->getMod());
        game->setSavedGame(s);
        StatisticsState* st = new StatisticsState();
        std::ostringstream t;
        t << "title=" << st->_txtTitle->getText() << "\n";
        for (size_t i = 0; i < st->_lstStats->getRows(); i++)
          t << st->_lstStats->getCellText(i, 0) << "|" << st->_lstStats->getCellText(i, 1) << "\n";
        std::ofstream o((out + "/" + name.substr(0, name.size() - 4) + ".stat.txt").c_str(), std::ios::binary);
        o << t.str();
        delete st;
        done++;
      } catch (std::exception& e) {
        fprintf(stderr, "skipped %s: %s\n", name.c_str(), e.what());
      }
    } while (FindNextFileA(h, &fd));
  } catch (std::exception& e) {
    fprintf(stderr, "EXCEPTION: %s\n", e.what());
    return 1;
  }
  fprintf(stderr, "ok (%d saves)\n", done);
  return 0;
}
