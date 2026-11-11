// Harness for the diaries of the soldiers (SoldierDiary::updateDiary and manageCommendations): runs the REAL
// OpenXcom objects (linked from a real build, see build7.cmd) on careers made up by a fixed generator and writes
//   diary.corpus.txt   the careers (missions, statistics of a unit, kills) one line each
//   diary.golden.txt   what the diary holds after every battle and what manageCommendations answered
// The rules (commendations, items, UFOs...) are those of Tests\Data\XcomSave\diary.rules.yml. Contains no
// OpenXcom code; the output goes in Tests\Data\XcomSave.
// usage: diarygen gen <corpus> <count> <seed>
//        diarygen run <rules.yml> <corpus> <golden>
#include <yaml-cpp/yaml.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include <algorithm>
#define private public
#define protected public
#include "Mod/Mod.h"
#include "Mod/RuleItem.h"
#include "Mod/RuleCommendations.h"
#include "Savegame/SoldierDiary.h"
#include "Savegame/MissionStatistics.h"
#include "Savegame/BattleUnitStatistics.h"
#undef protected
#undef private
#undef main

using namespace OpenXcom;

static unsigned gState;
static int Rnd(int n) { gState = gState * 1103515245u + 12345u; return (int)((gState >> 16) & 0x7fff) % n; }
static bool Chance(int percent) { return Rnd(100) < percent; }

static const char* kRegions[] = {"STR_NORTH_AMERICA", "STR_EUROPE", "STR_ASIA", "STR_REGION_UNKNOWN"};
static const char* kCountries[] = {"STR_USA", "STR_RUSSIA", "STR_UNKNOWN"};
static const char* kTypes[] = {"STR_UFO_CRASH_RECOVERY", "STR_UFO_GROUND_ASSAULT", "STR_TERROR_MISSION", "STR_BASE_DEFENSE", "STR_ALIEN_BASE_ASSAULT", "STR_ALIEN_COLONY"};
static const char* kUfos[] = {"NO_UFO", "STR_SMALL_SCOUT", "STR_MEDIUM_SCOUT", "STR_LARGE_SCOUT"};
static const char* kRanks[] = {"STR_SOLDIER", "STR_COMMANDER", "STR_LEADER", "STR_ENGINEER"};
static const char* kRaces[] = {"STR_SECTOID", "STR_FLOATER", "STR_SNAKEMAN"};
static const char* kWeapons[] = {"STR_RIFLE", "STR_PISTOL", "STR_LASER_RIFLE", "STR_GRENADE", "STR_PROXIMITY_GRENADE", "STR_KNIFE", "STR_NOWEAPON", "STR_NONE"};
static const char* kAmmo[] = {"STR_RIFLE_CLIP", "STR_PISTOL_CLIP", "STR_LASER_CLIP", "STR_GRENADE", "STR_PROXIMITY_GRENADE", "STR_KNIFE", "STR_NOAMMO"};

static void Generate(const char* path, int count, unsigned seed)
{
	gState = seed;
	std::ofstream out(path);
	for (int c = 0; c < count; ++c)
	{
		out << "CASE " << c << "\n";
		int missionId = 0, steps = 1 + Rnd(7);
		for (int s = 0; s < steps; ++s)
		{
			if (Chance(15)) out << "MS\n";
			if (Chance(5)) out << "BR " << Rnd(3) << "\n";
			if (Chance(5)) out << "PM " << Rnd(3) << "\n";
			++missionId;
			// the mission of the battle
			out << "M " << missionId << " " << (Chance(70) ? 1 : 0) << " " << (Rnd(9) * 25 - 50) << " "
				<< kRegions[Rnd(4)] << " " << kCountries[Rnd(3)] << " " << kTypes[Rnd(6)] << " " << kUfos[Rnd(4)]
				<< " " << Rnd(16) << " " << (Chance(10) ? 1 : 0) << "\n";
			// the unit: wasUnc shotAt hit shotBy shotFriendly lone iron longHit lowAcc fired landed daysWounded
			// kia nike mercy healed delta(11) stimulant painkill revS revH revN mia martyr slave
			out << "U " << (Chance(10) ? 1 : 0) << " " << Rnd(26) << " " << Rnd(13) << " " << (Chance(15) ? Rnd(3) : 0)
				<< " " << (Chance(10) ? Rnd(3) : 0) << " " << (Chance(15) ? 1 : 0) << " " << (Chance(10) ? 1 : 0)
				<< " " << Rnd(4) << " " << Rnd(4) << " " << Rnd(30) << " " << Rnd(20) << " "
				<< (Chance(25) ? Rnd(25) : 0) << " " << (Chance(6) ? 1 : 0) << " " << (Chance(15) ? 1 : 0) << " "
				<< (Chance(15) ? 1 : 0) << " " << (Chance(25) ? Rnd(5) : 0);
			for (int d = 0; d < 11; ++d) out << " " << (d == 3 ? Rnd(40) - 10 : (Chance(30) ? Rnd(4) : 0));
			out << " " << Rnd(3) << " " << Rnd(3) << " " << (Chance(10) ? 1 : 0) << " " << (Chance(10) ? 1 : 0)
				<< " " << (Chance(10) ? 1 : 0) << " " << (Chance(4) ? 1 : 0) << " " << (Chance(10) ? Rnd(3) : 0)
				<< " " << (Chance(10) ? Rnd(3) : 0) << "\n";
			int kills = Chance(25) ? 0 : Rnd(8);
			for (int k = 0; k < kills; ++k)
			{
				int faction = Chance(85) ? 1 : (Chance(50) ? 0 : 2);
				static const int statuses[] = {6, 6, 6, 7, 8, 3};
				out << "K " << kRanks[Rnd(4)] << " " << kRaces[Rnd(3)] << " " << kWeapons[Rnd(8)] << " " << kAmmo[Rnd(7)]
					<< " " << faction << " " << statuses[Rnd(6)] << " " << missionId << " " << (1 + Rnd(10) * 3 - (Chance(30) ? 0 : 1) + (Chance(10) ? 1 : 0))
					<< " " << Rnd(5) << " " << Rnd(6) << "\n";
			}
			out << "E\n";
		}
	}
}

static std::vector<std::string> Split(const std::string& line)
{
	std::vector<std::string> parts;
	std::istringstream in(line);
	std::string part;
	while (in >> part) parts.push_back(part);
	return parts;
}

static void Dump(std::ofstream& out, SoldierDiary& d, bool awarded)
{
	out << "R " << (awarded ? 1 : 0) << " " << d._KIA << " " << d._MIA << "\n";
	out << "D " << d._daysWoundedTotal << " " << d._totalShotByFriendlyCounter << " " << d._totalShotFriendlyCounter
		<< " " << d._loneSurvivorTotal << " " << d._monthsService << " " << d._unconciousTotal << " " << d._shotAtCounterTotal
		<< " " << d._hitCounterTotal << " " << d._ironManTotal << " " << d._longDistanceHitCounterTotal << " "
		<< d._lowAccuracyHitCounterTotal << " " << d._shotsFiredCounterTotal << " " << d._shotsLandedCounterTotal << " "
		<< d._shotAtCounter10in1Mission << " " << d._hitCounter5in1Mission << " " << d._timesWoundedTotal << " "
		<< d._allAliensKilledTotal << " " << d._allAliensStunnedTotal << " " << d._woundsHealedTotal << " " << d._allUFOs
		<< " " << d._allMissionTypes << " " << d._statGainTotal << " " << d._revivedUnitTotal << " " << d._revivedSoldierTotal
		<< " " << d._revivedHostileTotal << " " << d._revivedNeutralTotal << " " << d._wholeMedikitTotal << " "
		<< d._braveryGainTotal << " " << d._bestOfRank << " " << (int)d._bestSoldier << " " << d._martyrKillsTotal << " "
		<< d._postMortemKills << " " << (int)d._globeTrotter << " " << d._slaveKillsTotal << "\n";
	out << "L " << d._killList.size();
	for (size_t i = 0; i < d._killList.size(); ++i) out << " " << d._killList[i]->turn;
	out << "\nI";
	for (size_t i = 0; i < d._missionIdList.size(); ++i) out << " " << d._missionIdList[i];
	out << "\n";
	for (size_t i = 0; i < d._commendations.size(); ++i)
		out << "C " << d._commendations[i]->getType() << " " << d._commendations[i]->getNoun() << " "
			<< d._commendations[i]->getDecorationLevelInt() << " " << (int)d._commendations[i]->isNew() << "\n";
}

static void Run(const char* rulesPath, const char* corpusPath, const char* goldenPath)
{
	Mod mod;
	YAML::Node rules = YAML::LoadFile(rulesPath);
	for (size_t i = 0; i < rules["ufos"].size(); ++i) mod._ufosIndex.push_back(rules["ufos"][i].as<std::string>());
	for (size_t i = 0; i < rules["deployments"].size(); ++i) mod._deploymentsIndex.push_back(rules["deployments"][i].as<std::string>());
	for (size_t i = 0; i < rules["countries"].size(); ++i) mod._countriesIndex.push_back(rules["countries"][i].as<std::string>());
	for (size_t i = 0; i < rules["items"].size(); ++i)
	{
		const YAML::Node n = rules["items"][i];
		RuleItem* item = new RuleItem(n["type"].as<std::string>());
		item->_battleType = (BattleType)n["battleType"].as<int>();
		item->_damageType = (ItemDamageType)n["damageType"].as<int>();
		mod._items[item->_type] = item;
	}
	for (size_t i = 0; i < rules["commendations"].size(); ++i)
	{
		const YAML::Node n = rules["commendations"][i];
		RuleCommendations* c = new RuleCommendations();
		c->load(n);
		mod._commendations[n["type"].as<std::string>()] = c;
	}
	std::ifstream in(corpusPath);
	std::ofstream out(goldenPath);
	std::string line;
	SoldierDiary* diary = 0;
	std::vector<MissionStatistics*> missions;
	BattleUnitStatistics* stats = 0;
	while (std::getline(in, line))
	{
		std::vector<std::string> p = Split(line);
		if (p.empty()) continue;
		if (p[0] == "CASE")
		{
			delete diary;
			diary = new SoldierDiary();
			for (size_t i = 0; i < missions.size(); ++i) delete missions[i];
			missions.clear();
			out << line << "\n";
		}
		else if (p[0] == "MS") diary->addMonthlyService();
		else if (p[0] == "BR") diary->awardBestOfRank(atoi(p[1].c_str()));
		else if (p[0] == "PM") diary->awardPostMortemKill(atoi(p[1].c_str()));
		else if (p[0] == "M")
		{
			MissionStatistics* m = new MissionStatistics();
			m->id = atoi(p[1].c_str());
			m->success = atoi(p[2].c_str()) != 0;
			m->score = atoi(p[3].c_str());
			m->region = p[4];
			m->country = p[5];
			m->type = p[6];
			m->ufo = p[7];
			m->daylight = atoi(p[8].c_str());
			m->valiantCrux = atoi(p[9].c_str()) != 0;
			missions.push_back(m);
		}
		else if (p[0] == "U")
		{
			delete stats;
			stats = new BattleUnitStatistics();
			int v[40];
			for (size_t i = 1; i < p.size() && i < 40; ++i) v[i] = atoi(p[i].c_str());
			stats->wasUnconcious = v[1] != 0; stats->shotAtCounter = v[2]; stats->hitCounter = v[3];
			stats->shotByFriendlyCounter = v[4]; stats->shotFriendlyCounter = v[5]; stats->loneSurvivor = v[6] != 0;
			stats->ironMan = v[7] != 0; stats->longDistanceHitCounter = v[8]; stats->lowAccuracyHitCounter = v[9];
			stats->shotsFiredCounter = v[10]; stats->shotsLandedCounter = v[11]; stats->daysWounded = v[12];
			stats->KIA = v[13] != 0; stats->nikeCross = v[14] != 0; stats->mercyCross = v[15] != 0;
			stats->woundsHealed = v[16];
			stats->delta = UnitStats(v[17], v[18], v[19], v[20], v[21], v[22], v[23], v[24], v[25], v[26], v[27]);
			stats->appliedStimulant = v[28]; stats->appliedPainKill = v[29];
			stats->revivedSoldier = v[30]; stats->revivedHostile = v[31]; stats->revivedNeutral = v[32];
			stats->MIA = v[33] != 0; stats->martyr = v[34]; stats->slaveKills = v[35];
		}
		else if (p[0] == "K")
		{
			BattleUnitKills* k = new BattleUnitKills();
			k->rank = p[1]; k->race = p[2]; k->weapon = p[3]; k->weaponAmmo = p[4];
			k->faction = (UnitFaction)atoi(p[5].c_str()); k->status = (UnitStatus)atoi(p[6].c_str());
			k->mission = atoi(p[7].c_str()); k->turn = atoi(p[8].c_str());
			k->side = (UnitSide)atoi(p[9].c_str()); k->bodypart = (UnitBodyPart)atoi(p[10].c_str());
			stats->kills.push_back(k);
		}
		else if (p[0] == "E")
		{
			diary->updateDiary(stats, &missions, &mod);
			bool awarded = diary->manageCommendations(&mod, &missions);
			Dump(out, *diary, awarded);
			delete stats;
			stats = 0;
		}
	}
}

int main(int argc, char** argv)
{
	if (argc >= 5 && std::string(argv[1]) == "gen") { Generate(argv[2], atoi(argv[3]), (unsigned)atoi(argv[4])); return 0; }
	if (argc >= 5 && std::string(argv[1]) == "run") { Run(argv[2], argv[3], argv[4]); return 0; }
	fprintf(stderr, "usage: diarygen gen <corpus> <count> <seed> | run <rules.yml> <corpus> <golden>\n");
	return 1;
}
