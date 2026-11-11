// ---- the dogfight: the code of DogfightState (the constructor, update, animate without the pixels, the buttons) with
// the window left out: statuses and sounds are written as ev| lines; the geoscape part is what handleDogfights does
// (the UFO is free to be processed again before each think). Globe::insideLand is a fixed function of the position.
// Included by simgen.cpp (before main): it uses Ev, Ammo and Pick of that file
#include "Savegame/CraftWeaponProjectile.h"

static bool DogLand(double lon, double lat) {
  volatile double a = lon * 1000.0, b = lat * 1000.0;
  return (((int)floor(a) + (int)floor(b)) & 1) != 0;
}

struct Dog {
  SavedGame* s; Craft* craft; Ufo* ufo; std::vector<CraftWeaponProjectile*> proj;
  int mode, timeout, currentDist, targetDist, w1Countdown, w2Countdown, w1Interval, w2Interval, ufoSize, interceptionNumber;
  bool end, destroyUfo, destroyCraft, ufoBreakingOff, w1Enabled, w2Enabled, minimized, endDogfight, animatingHit;
  bool waitForPoly, waitForAltitude;
};
static const int STANDOFF_DIST = 560;

static bool gStatusShown = false;
static void DogStatus(Dog& d, const char* key) { Ev("status|%s", key); d.timeout = 50; gStatusShown = true; }

static void DogCtor(Dog& d, SavedGame* s, Craft* craft, Ufo* ufo, Mod* mod) {
  d.s = s; d.craft = craft; d.ufo = ufo; gStatusShown = true;
  d.mode = 0; d.timeout = 50; d.currentDist = 640; d.targetDist = 560; d.w1Countdown = 0; d.w2Countdown = 0;
  d.end = d.destroyUfo = d.destroyCraft = d.ufoBreakingOff = d.minimized = d.endDogfight = d.animatingHit = false;
  d.waitForPoly = d.waitForAltitude = false;
  d.w1Enabled = d.w2Enabled = true; d.w1Interval = d.w2Interval = 0; d.interceptionNumber = 1;
  craft->setInDogfight(true);
  if (craft->getInterceptionOrder() == 0) {
    int maxInterceptionOrder = 0;
    for (std::vector<Base*>::iterator baseIt = s->getBases()->begin(); baseIt != s->getBases()->end(); ++baseIt)
      for (std::vector<Craft*>::iterator craftIt = (*baseIt)->getCrafts()->begin(); craftIt != (*baseIt)->getCrafts()->end(); ++craftIt)
        if ((*craftIt)->getInterceptionOrder() > maxInterceptionOrder) maxInterceptionOrder = (*craftIt)->getInterceptionOrder();
    craft->setInterceptionOrder(++maxInterceptionOrder);
  }
  if (!ufo->getEscapeCountdown()) {
    ufo->setFireCountdown(0);
    int escapeCountdown = ufo->getRules()->getBreakOffTime() + RNG::generate(0, ufo->getRules()->getBreakOffTime()) - 30 * s->getDifficultyCoefficient();
    ufo->setEscapeCountdown(std::max(1, escapeCountdown));
  }
  if (craft->getRules()->getWeapons() > 0 && craft->getWeapons()->at(0) != 0) d.w1Interval = craft->getWeapons()->at(0)->getRules()->getStandardReload();
  if (craft->getRules()->getWeapons() > 1 && craft->getWeapons()->at(1) != 0) d.w2Interval = craft->getWeapons()->at(1)->getRules()->getStandardReload();
  std::string ufoSize = ufo->getRules()->getSize();
  if (ufoSize.compare("STR_VERY_SMALL") == 0) d.ufoSize = 0;
  else if (ufoSize.compare("STR_SMALL") == 0) d.ufoSize = 1;
  else if (ufoSize.compare("STR_MEDIUM_UC") == 0) d.ufoSize = 2;
  else if (ufoSize.compare("STR_LARGE") == 0) d.ufoSize = 3;
  else d.ufoSize = 4;
}

static void DogMin(Dog& d) {
  int max = 0;
  for (std::vector<CraftWeapon*>::iterator i = d.craft->getWeapons()->begin(); i < d.craft->getWeapons()->end(); ++i) {
    if (*i == 0) continue;
    if ((*i)->getRules()->getRange() > max && (*i)->getAmmo() > 0) max = (*i)->getRules()->getRange();
  }
  d.targetDist = max == 0 ? STANDOFF_DIST : max * 8;
}
static void DogMax(Dog& d) {
  int min = 1000;
  for (std::vector<CraftWeapon*>::iterator i = d.craft->getWeapons()->begin(); i < d.craft->getWeapons()->end(); ++i) {
    if (*i == 0) continue;
    if ((*i)->getRules()->getRange() < min && (*i)->getAmmo() > 0) min = (*i)->getRules()->getRange();
  }
  d.targetDist = min == 1000 ? STANDOFF_DIST : min * 8;
}
static void DogFire(Dog& d, int which) {
  CraftWeapon* w = d.craft->getWeapons()->at(which);
  if (w->setAmmo(w->getAmmo() - 1)) {
    if (which == 0) d.w1Countdown = d.w1Interval; else d.w2Countdown = d.w2Interval;
    CraftWeaponProjectile* p = w->fire();
    p->setDirection(D_UP);
    p->setHorizontalPosition(which == 0 ? HP_LEFT : HP_RIGHT);
    d.proj.push_back(p);
    Ev("sound|weapon|%d", w->getRules()->getSound());
  }
}
static void DogUfoFire(Dog& d) {
  int fireCountdown = std::max(1, (d.ufo->getRules()->getWeaponReload() - 2 * d.s->getDifficultyCoefficient()));
  d.ufo->setFireCountdown(RNG::generate(0, fireCountdown) + fireCountdown);
  DogStatus(d, "STR_UFO_RETURN_FIRE");
  CraftWeaponProjectile* p = new CraftWeaponProjectile();
  p->setType(CWPT_PLASMA_BEAM);
  p->setAccuracy(60);
  p->setDamage(d.ufo->getRules()->getWeaponPower());
  p->setDirection(D_DOWN);
  p->setHorizontalPosition(HP_CENTER);
  p->setPosition(d.currentDist - (d.ufo->getRules()->getRadius() / 2));
  d.proj.push_back(p);
  Ev("sound|ufofire");
}
static void DogEnd(Dog& d) {
  if (d.endDogfight) return;
  d.craft->setInDogfight(false);
  d.craft->setInterceptionOrder(0);
  d.ufo->setInterceptionProcessed(false);
  d.endDogfight = true;
}
static void DogAnimate(Dog& d) {
  if (d.timeout == 0) { if (gStatusShown) { Ev("status|"); gStatusShown = false; } } else d.timeout--;
  bool lastHitAnimFrame = false;
  if (d.animatingHit && d.ufo->getHitFrame() > 0) {
    d.ufo->setHitFrame(d.ufo->getHitFrame() - 1);
    if (d.ufo->getHitFrame() == 0) { d.animatingHit = false; lastHitAnimFrame = true; }
  }
  if (d.ufo->isCrashed() && d.ufo->getHitFrame() == 0 && !lastHitAnimFrame) --d.ufoSize;
}
static void DogUpdate(Dog& d, Mod* mod) {
  SavedGame* s = d.s; Craft* craft = d.craft; Ufo* ufo = d.ufo;
  bool finalRun = false;
  Ufo* u = dynamic_cast<Ufo*>(craft->getDestination());
  if (u != ufo || !craft->isInDogfight() || craft->getLowFuel() || (d.minimized && ufo->isCrashed())) { DogEnd(d); return; }
  if (!d.minimized) {
    DogAnimate(d);
    if (!ufo->isCrashed() && !ufo->isDestroyed() && !craft->isDestroyed() && !ufo->getInterceptionProcessed()) {
      ufo->setInterceptionProcessed(true);
      int escapeCounter = ufo->getEscapeCountdown();
      if (escapeCounter > 0) {
        escapeCounter--;
        ufo->setEscapeCountdown(escapeCounter);
        if (escapeCounter == 0) ufo->setSpeed(ufo->getRules()->getMaxSpeed());
      }
      if (ufo->getFireCountdown() > 0) ufo->setFireCountdown(ufo->getFireCountdown() - 1);
    }
  }
  if (ufo->getSpeed() > craft->getRules()->getMaxSpeed()) { d.ufoBreakingOff = true; finalRun = true; DogStatus(d, "STR_UFO_OUTRUNNING_INTERCEPTOR"); }
  else d.ufoBreakingOff = false;
  bool projectileInFlight = false;
  if (!d.minimized) {
    int distanceChange = 0;
    if (!d.ufoBreakingOff) {
      if (d.currentDist < d.targetDist && !ufo->isCrashed() && !craft->isDestroyed()) {
        distanceChange = 4;
        if (d.currentDist + distanceChange > d.targetDist) distanceChange = d.targetDist - d.currentDist;
      } else if (d.currentDist > d.targetDist && !ufo->isCrashed() && !craft->isDestroyed()) distanceChange = -2;
      for (std::vector<CraftWeaponProjectile*>::iterator it = d.proj.begin(); it != d.proj.end(); ++it)
        if ((*it)->getGlobalType() != CWPGT_BEAM && (*it)->getDirection() == D_UP) (*it)->setPosition((*it)->getPosition() + distanceChange);
    } else distanceChange = 4;
    d.currentDist += distanceChange;
    for (std::vector<CraftWeaponProjectile*>::iterator it = d.proj.begin(); it != d.proj.end(); ++it) {
      CraftWeaponProjectile* p = (*it);
      p->move();
      if (p->getDirection() == D_UP) {
        if (((p->getPosition() >= d.currentDist) || (p->getGlobalType() == CWPGT_BEAM && p->toBeRemoved())) && !ufo->isCrashed() && !p->getMissed()) {
          if (RNG::percent((p->getAccuracy() * (100 + 300 / (5 - d.ufoSize)) + 100) / 200)) {
            int damage = RNG::generate(p->getDamage() / 2, p->getDamage());
            ufo->setDamage(ufo->getDamage() + damage);
            if (ufo->isCrashed()) {
              ufo->setShotDownByCraftId(craft->getUniqueId());
              ufo->setSpeed(0);
              ufo->setDestination(0);
              d.ufoBreakingOff = false; finalRun = false; d.end = false;
            }
            if (ufo->getHitFrame() == 0) { d.animatingHit = true; ufo->setHitFrame(3); }
            DogStatus(d, "STR_UFO_HIT");
            Ev("sound|ufohit");
            p->remove();
          } else {
            if (p->getGlobalType() == CWPGT_BEAM) p->remove(); else p->setMissed(true);
          }
        }
        if (p->getGlobalType() == CWPGT_MISSILE && p->getPosition() / 8 >= p->getRange()) p->remove();
        else if (!ufo->isCrashed()) projectileInFlight = true;
      } else if (p->getDirection() == D_DOWN) {
        if (p->getGlobalType() == CWPGT_MISSILE || (p->getGlobalType() == CWPGT_BEAM && p->toBeRemoved())) {
          if (RNG::percent(p->getAccuracy())) {
            int damage = RNG::generate(0, ufo->getRules()->getWeaponPower());
            if (damage) {
              craft->setDamage(craft->getDamage() + damage);
              Ev("craftdamage");
              DogStatus(d, "STR_INTERCEPTOR_DAMAGED");
              Ev("sound|interceptorhit");
              if (d.mode == 1 && craft->getDamagePercentage() >= 50) d.targetDist = STANDOFF_DIST;
            }
          }
          p->remove();
        }
      }
    }
    for (std::vector<CraftWeaponProjectile*>::iterator it = d.proj.begin(); it != d.proj.end();) {
      if ((*it)->toBeRemoved() == true || ((*it)->getMissed() == true && (*it)->getPosition() <= 0)) { delete *it; it = d.proj.erase(it); }
      else ++it;
    }
    for (unsigned int i = 0; i < craft->getRules()->getWeapons(); ++i) {
      CraftWeapon* w = craft->getWeapons()->at(i);
      if (w == 0) continue;
      int wTimer = i == 0 ? d.w1Countdown : d.w2Countdown;
      if (wTimer == 0 && d.currentDist <= w->getRules()->getRange() * 8 && w->getAmmo() > 0 && d.mode != 0 && d.mode != 4 && !ufo->isCrashed() && !craft->isDestroyed()) {
        if (i == 0) { if (d.w1Enabled) { DogFire(d, 0); projectileInFlight = true; } }
        else { if (d.w2Enabled) { DogFire(d, 1); projectileInFlight = true; } }
      } else if (wTimer > 0) { if (i == 0) d.w1Countdown--; else d.w2Countdown--; }
      if (w->getAmmo() == 0 && !projectileInFlight && !craft->isDestroyed()) {
        if (d.mode == 1) DogMin(d); else if (d.mode == 2) DogMax(d);
      }
    }
    if (d.currentDist <= ufo->getRules()->getWeaponRange() * 8 && !ufo->isCrashed() && !craft->isDestroyed()) {
      if (ufo->getShootingAt() == 0) ufo->setShootingAt(d.interceptionNumber);
      if (ufo->getShootingAt() == d.interceptionNumber) { if (ufo->getFireCountdown() == 0) DogUfoFire(d); }
    } else if (ufo->getShootingAt() == d.interceptionNumber) ufo->setShootingAt(0);
  }
  if (d.end == true && (((d.currentDist > 640 || d.minimized) && (d.mode == 4 || d.ufoBreakingOff == true)) || (d.timeout == 0 && (ufo->isCrashed() || craft->isDestroyed())))) {
    if (d.ufoBreakingOff) { ufo->move(); craft->setDestination(ufo); }
    if (!d.destroyCraft && (d.destroyUfo || d.mode == 4)) craft->returnToBase();
    if (ufo->isCrashed()) {
      std::vector<Craft*> followers = ufo->getCraftFollowers();
      for (std::vector<Craft*>::iterator i = followers.begin(); i != followers.end(); ++i)
        if ((*i)->getNumSoldiers() == 0 && (*i)->getNumVehicles() == 0) (*i)->returnToBase();
    }
    DogEnd(d);
  }
  if (d.currentDist > 640 && d.ufoBreakingOff) finalRun = true;
  if (!d.end) {
    if (craft->isDestroyed()) {
      DogStatus(d, "STR_INTERCEPTOR_DESTROYED");
      d.timeout += 30;
      Ev("sound|interceptorexplode");
      finalRun = true; d.destroyCraft = true; ufo->setShootingAt(0);
    }
    if (ufo->isCrashed()) {
      AlienMission* mission = ufo->getMission();
      mission->ufoShotDown(*ufo);
      int retaliationOdds = mission->getRules().getRetaliationOdds();
      if (retaliationOdds == -1) retaliationOdds = 100 - (4 * (24 - s->getDifficultyCoefficient()));
      if (RNG::percent(retaliationOdds)) {
        std::string targetRegion;
        if (RNG::percent(50 - 6 * s->getDifficultyCoefficient())) targetRegion = ufo->getMission()->getRegion();
        else targetRegion = s->locateRegion(*craft->getBase())->getRules()->getType();
        if (!s->findAlienMission(targetRegion, OBJECTIVE_RETALIATION)) {
          const RuleAlienMission& rule = *mod->getRandomMission(OBJECTIVE_RETALIATION, s->getMonthsPassed());
          AlienMission* newMission = new AlienMission(rule);
          newMission->setId(s->getId("ALIEN_MISSIONS"));
          newMission->setRegion(targetRegion, *mod);
          newMission->setRace(ufo->getAlienRace());
          newMission->start(newMission->getRules().getWave(0).spawnTimer);
          s->getAlienMissions().push_back(newMission);
        }
      }
      if (ufo->isDestroyed()) {
        if (ufo->getShotDownByCraftId() == craft->getUniqueId()) {
          for (std::vector<Country*>::iterator country = s->getCountries()->begin(); country != s->getCountries()->end(); ++country)
            if ((*country)->getRules()->insideCountry(ufo->getLongitude(), ufo->getLatitude())) { (*country)->addActivityXcom(ufo->getRules()->getScore() * 2); break; }
          for (std::vector<Region*>::iterator region = s->getRegions()->begin(); region != s->getRegions()->end(); ++region)
            if ((*region)->getRules()->insideRegion(ufo->getLongitude(), ufo->getLatitude())) { (*region)->addActivityXcom(ufo->getRules()->getScore() * 2); break; }
          DogStatus(d, "STR_UFO_DESTROYED");
          Ev("sound|ufoexplode");
        }
        d.destroyUfo = true;
      } else {
        if (ufo->getShotDownByCraftId() == craft->getUniqueId()) {
          DogStatus(d, "STR_UFO_CRASH_LANDS");
          Ev("sound|ufocrash");
          for (std::vector<Country*>::iterator country = s->getCountries()->begin(); country != s->getCountries()->end(); ++country)
            if ((*country)->getRules()->insideCountry(ufo->getLongitude(), ufo->getLatitude())) { (*country)->addActivityXcom(ufo->getRules()->getScore()); break; }
          for (std::vector<Region*>::iterator region = s->getRegions()->begin(); region != s->getRegions()->end(); ++region)
            if ((*region)->getRules()->insideRegion(ufo->getLongitude(), ufo->getLatitude())) { (*region)->addActivityXcom(ufo->getRules()->getScore()); break; }
        }
        if (!DogLand(ufo->getLongitude(), ufo->getLatitude())) { ufo->setStatus(Ufo::DESTROYED); d.destroyUfo = true; }
        else {
          ufo->setSecondsRemaining(RNG::generate(24, 96) * 3600);
          ufo->setAltitude("STR_GROUND");
          if (ufo->getCrashId() == 0) ufo->setCrashId(s->getId("STR_CRASH_SITE"));
        }
      }
      d.timeout += 30;
      if (ufo->getShotDownByCraftId() != craft->getUniqueId()) { d.timeout += 50; ufo->setHitFrame(3); }
      finalRun = true;
      if (ufo->getStatus() == Ufo::LANDED) { d.timeout += 30; finalRun = true; ufo->setShootingAt(0); }
    }
  }
  if (!projectileInFlight && finalRun) d.end = true;
}
static void DogThink(Dog& d, Mod* mod) {
  if (!d.endDogfight) DogUpdate(d, mod);
  if (!d.craft->isInDogfight() || d.craft->getDestination() != d.ufo || d.ufo->getStatus() == Ufo::LANDED) DogEnd(d);
}
static void DogPress(Dog& d, int mode) {
  d.mode = mode;
  Craft* craft = d.craft;
  if (d.ufo->isCrashed() || craft->isDestroyed() || d.ufoBreakingOff) return;
  if (mode == 0) { d.end = false; DogStatus(d, "STR_STANDOFF"); d.targetDist = STANDOFF_DIST; }
  else if (mode == 1 || mode == 2 || mode == 3) {
    d.end = false;
    DogStatus(d, mode == 1 ? "STR_CAUTIOUS_ATTACK" : mode == 2 ? "STR_STANDARD_ATTACK" : "STR_AGGRESSIVE_ATTACK");
    if (craft->getRules()->getWeapons() > 0 && craft->getWeapons()->at(0) != 0) {
      RuleCraftWeapon* r = craft->getWeapons()->at(0)->getRules();
      d.w1Interval = mode == 1 ? r->getCautiousReload() : mode == 2 ? r->getStandardReload() : r->getAggressiveReload();
    }
    if (craft->getRules()->getWeapons() > 1 && craft->getWeapons()->at(1) != 0) {
      RuleCraftWeapon* r = craft->getWeapons()->at(1)->getRules();
      d.w2Interval = mode == 1 ? r->getCautiousReload() : mode == 2 ? r->getStandardReload() : r->getAggressiveReload();
    }
    if (mode == 1) DogMin(d); else if (mode == 2) DogMax(d); else d.targetDist = 64;
  } else { d.end = true; DogStatus(d, "STR_DISENGAGING"); d.targetDist = 800; }
}

static std::string DogProj(Dog& d) {
  std::string r;
  for (size_t i = 0; i < d.proj.size(); i++) {
    char b[96];
    snprintf(b, sizeof b, "%s%d:%d:%d:%d:%d", i ? ";" : "", (int)d.proj[i]->getType(), d.proj[i]->getPosition(), d.proj[i]->getDirection(), d.proj[i]->getState(), (int)d.proj[i]->getMissed());
    r += b;
  }
  return r;
}

// A craft with weapons against a new UFO of a random type: the buttons are pressed at random, up to 1500 steps
static void ScenarioDogfight(Mod* mod, SavedGame* s, int v) {
  const std::vector<std::string>& ufos = mod->getUfosList();
  const std::vector<std::string>& missions = mod->getAlienMissionList();
  const std::vector<std::string>& races = mod->getAlienRacesList();
  int bi = 0, count = 0;
  for (std::vector<Base*>::iterator bp = s->getBases()->begin(); bp != s->getBases()->end(); ++bp, ++bi) {
    Base* base = *bp;
    for (size_t ci = 0; ci < base->getCrafts()->size() && count < 5; ci++) {
      Craft* c = (*base->getCrafts())[ci];
      if (c->getRules()->getWeapons() == 0) continue;
      bool any = false;
      for (size_t i = 0; i < c->_weapons.size(); i++) if (c->_weapons[i]) any = true;
      if (!any) continue;
      for (int rep = 0; rep < 4; rep++, count++) {
        for (size_t i = 0; i < c->_weapons.size(); i++)
          if (c->_weapons[i]) c->_weapons[i]->setAmmo(1 + Pick(c->_weapons[i]->getRules()->getAmmoMax()));
        c->setDamage(Pick(3) == 0 ? Pick(c->getRules()->getMaxDamage() / 2) : 0);
        const RuleAlienMission* rule = mod->getAlienMission(missions[Pick((int)missions.size())]);
        AlienMission* m = new AlienMission(*rule);
        m->setId(s->getId("ALIEN_MISSIONS"));
        m->setRegion(mod->getRegionsList()[Pick((int)mod->getRegionsList().size())], *mod);
        m->setRace(races[Pick((int)races.size())]);
        s->_activeMissions.push_back(m);
        Ufo* u = new Ufo(mod->getUfo(ufos[Pick((int)ufos.size())]));
        u->setId(s->getId("STR_UFO"));
        u->setMissionInfo(m, mod->getUfoTrajectory(rule->getWave(0).trajectory));
        volatile double lon = base->getLongitude() + 0.1 + Pick(100) * 0.001;
        volatile double lat = base->getLatitude() + Pick(100) * 0.001;
        u->setLongitude(lon);
        u->setLatitude(lat);
        c->setLongitude(lon);
        c->setLatitude(lat);
        u->setAltitude(Pick(2) == 0 ? "STR_VERY_LOW" : "STR_HIGH_UC");
        u->setDetected(true);
        // half of the UFOs are nearly down: a hit crashes or destroys them (the retaliation and the score are reached)
        u->setDamage(Pick(2) == 0 ? std::max(0, u->getRules()->getMaxDamage() / 2 - Pick(40)) : (Pick(3) == 0 ? Pick(u->getRules()->getMaxDamage() / 2) : 0));
        u->setSpeed(Pick(4) == 0 ? c->getRules()->getMaxSpeed() + 100 : c->getRules()->getMaxSpeed() / 2 + Pick(c->getRules()->getMaxSpeed() / 2));
        s->getUfos()->push_back(u);
        c->setStatus("STR_OUT");
        c->setDestination(u);
        Dog d;
        DogCtor(d, s, c, u, mod);
        fprintf(gOut, "dog|%d|%d|%d|%d|ufo=%s|size=%d|esc=%d|w=%d,%d|ammo=%s|cdmg=%d|udmg=%d|uspeed=%d|cspeed=%d\n", v, bi, (int)ci, rep, u->getRules()->getType().c_str(),
          d.ufoSize, u->getEscapeCountdown(), d.w1Interval, d.w2Interval, Ammo(c).c_str(), c->getDamage(), u->getDamage(), u->getSpeed(), c->getRules()->getMaxSpeed());
        int step = 0;
        while (!d.endDogfight && step < 900) {
          if (step % 40 == 0 && Pick(3) != 0) DogPress(d, Pick(6) == 0 ? 4 : 1 + Pick(3));
          if (step % 97 == 0 && Pick(4) == 0) { d.w1Enabled = !d.w1Enabled; }
          u->setInterceptionProcessed(false);
          long before = ftell(gOut);
          size_t missionsBefore = s->_activeMissions.size();
          DogThink(d, mod);
          if (s->_activeMissions.size() > missionsBefore) Ev("retaliation|%s|%s", s->_activeMissions.back()->getRegion().c_str(), s->_activeMissions.back()->getRules().getType().c_str());
          bool changed = ftell(gOut) != before;
          if (changed || step % 10 == 0 || d.endDogfight) fprintf(gOut, "df|%d|%d|%d|%d|%d|dist=%d|tgt=%d|mode=%d|udmg=%d|ust=%d|usp=%d|hit=%d|fire=%d|esc=%d|shoot=%d|cdmg=%d|ammo=%s|cd=%d,%d|proj=%s|to=%d|end=%d|ended=%d|size=%d|alt=%s|dest=%d|indf=%d\n",
            v, bi, (int)ci, rep, step, d.currentDist, d.targetDist, d.mode, u->getDamage(), (int)u->getStatus(), u->getSpeed(), u->getHitFrame(),
            u->getFireCountdown(), u->getEscapeCountdown(), u->getShootingAt(), c->getDamage(), Ammo(c).c_str(), d.w1Countdown, d.w2Countdown,
            DogProj(d).c_str(), d.timeout, (int)d.end, (int)d.endDogfight, d.ufoSize, u->getAltitude().c_str(), (int)(c->getDestination() != 0), (int)c->isInDogfight());
          step++;
        }
        for (size_t k = 0; k < d.proj.size(); k++) delete d.proj[k];
        // the geoscape removes a destroyed UFO; a live one stays in the game with its status
        if (u->getStatus() == Ufo::DESTROYED) {
          c->setDestination(0);
          for (size_t k = 0; k < s->getUfos()->size(); k++) if ((*s->getUfos())[k] == u) { delete u; s->getUfos()->erase(s->getUfos()->begin() + k); break; }
        } else { c->setDestination(0); u->setDestination(0); }
        c->setStatus("STR_READY");
        fprintf(gOut, "dogend|%d|%d|%d|%d|steps=%d|rng=%llu\n", v, bi, (int)ci, rep, step, (unsigned long long)RNG::getSeed());
      }
    }
  }
}
