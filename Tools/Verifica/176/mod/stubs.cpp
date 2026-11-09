#include <yaml-cpp/yaml.h>
#include <string>
#include <vector>
#include <map>
#include "Mod/RuleItem.h"
#include "Savegame/Ufo.h"
#include "Savegame/Craft.h"
#include "Engine/Language.h"
#include "Savegame/SerializationHelper.h"
namespace OpenXcom {
LocalizedText Language::getString(const std::string &id) const { return LocalizedText(id); }
void Craft::returnToBase() {}
std::string serializeDouble(double v) { return ""; }
int RuleItem::getInventoryWidth() const { return 1; }
int RuleItem::getInventoryHeight() const { return 1; }
const char *Ufo::ALTITUDE_STRING[] = {"STR_GROUND", "STR_VERY_LOW", "STR_LOW_UFO_ALTITUDE", "STR_HIGH_UFO_ALTITUDE", "STR_VERY_HIGH"};
}
