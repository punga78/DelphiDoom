#include <yaml-cpp/yaml.h>
#include <string>
#include <vector>
#include <map>
#include "Mod/RuleItem.h"
#include "Savegame/Ufo.h"
#include "Savegame/Craft.h"
#include "Engine/Language.h"
#include "Savegame/SerializationHelper.h"
#include <sstream>
#include <cassert>
#include "Mod/Mod.h"
#include "Engine/SoundSet.h"
#include "Engine/Exception.h"
#include <sstream>
#include <cassert>
#include "Mod/Mod.h"
#include "Engine/SoundSet.h"
#include "Engine/Exception.h"
namespace OpenXcom {
LocalizedText Language::getString(const std::string &id) const { return LocalizedText(id); }
void Craft::returnToBase() {}
std::string serializeDouble(double v) { return ""; }
int RuleItem::getInventoryWidth() const { return 1; }
int RuleItem::getInventoryHeight() const { return 1; }
const char *Ufo::ALTITUDE_STRING[] = {"STR_GROUND", "STR_VERY_LOW", "STR_LOW_UFO_ALTITUDE", "STR_HIGH_UFO_ALTITUDE", "STR_VERY_HIGH"};

// --- the offset functions of Mod.cpp, copied literally (Mod.cpp itself needs the whole engine) ---
const std::string ModNameMaster = "master";
const std::string ModNameCurrent = "current";
const size_t ModTransparceySizeReduction = 100;
int SoundSet::getMaxSharedSounds() const { return 20; }
SoundSet *Mod::getSoundSet(const std::string &name, bool error) const { static char buffer[sizeof(SoundSet)]; return (SoundSet *)buffer; }
void Mod::loadOffsetNode(const std::string &parent, int& offset, const YAML::Node &node, int shared, const std::string &set, size_t multiplier, size_t sizeScale) const
{
	assert(_modCurrent);
	const ModData* curr = _modCurrent;
	if (node.IsScalar())
	{
		offset = node.as<int>();
	}
	else if (node.IsMap())
	{
		offset = node["index"].as<int>();
		std::string mod = node["mod"].as<std::string>();
		if (mod == ModNameMaster)
		{
			curr = &_modData.at(0);
		}
		else if (mod == ModNameCurrent)
		{
			//nothing
		}
		else
		{
			const ModData* n = 0;
			for (size_t i = 0; i < _modData.size(); ++i)
			{
				const ModData& d = _modData[i];
				if (d.name == mod)
				{
					n = &d;
					break;
				}
			}

			if (n)
			{
				curr = n;
			}
			else
			{
				std::ostringstream err;
				err << "Error for '" << parent << "': unknown mod '" << mod << "' used";
				throw Exception(err.str());
			}
		}
	}

	if (offset < -1)
	{
		std::ostringstream err;
		err << "Error for '" << parent << "': offset '" << offset << "' has incorrect value in set '" << set << "' at line " << node.Mark().line;
		throw Exception(err.str());
	}
	else if (offset == -1)
	{
		//ok
	}
	else
	{
		int f = offset;
		f *= multiplier;
		if ((size_t)f > curr->size / sizeScale)
		{
			std::ostringstream err;
			err << "Error for '" << parent << "': offset '" << offset << "' exceeds mod size limit " << (curr->size / multiplier / sizeScale) << " in set '" << set << "'";
			throw Exception(err.str());
		}
		if (f >= shared)
			f += curr->offset / sizeScale;
		offset = f;
	}
}
void Mod::loadSoundOffset(const std::string &parent, int& sound, const YAML::Node &node, const std::string &set) const
{
	if (node)
	{
		loadOffsetNode(parent, sound, node, getSoundSet(set)->getMaxSharedSounds(), set, 1);
	}
}
int Mod::getOffset(int id, int max) const
{
	assert(_modCurrent);
	if (id > max)
		return id + _modCurrent->offset;
	else
		return id;
}
void Mod::loadTransparencyOffset(const std::string &parent, int& index, const YAML::Node &node) const
{
	if (node)
	{
		loadOffsetNode(parent, index, node, 0, "TransparencyLUTs", 1, ModTransparceySizeReduction);
	}
}
void Mod::loadSoundOffset(const std::string &parent, std::vector<int>& sounds, const YAML::Node &node, const std::string &set) const
{
	if (node)
	{
		int maxShared = getSoundSet(set)->getMaxSharedSounds();
		sounds.clear();
		if (node.IsSequence())
		{
			for (YAML::const_iterator i = node.begin(); i != node.end(); ++i)
			{
				sounds.push_back(-1);
				loadOffsetNode(parent, sounds.back(), *i, maxShared, set, 1);
			}
		}
		else
		{
			sounds.push_back(-1);
			loadOffsetNode(parent, sounds.back(), node, maxShared, set, 1);
		}
	}
}
}
