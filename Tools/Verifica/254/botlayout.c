/* Issue #254 (fase 2d): the layout in memory of the structures the BOTLIB system calls of qagame pass by pointer
   (the data of the program), as the real headers give it (gcc -m32). Compiled by botlayout.sh. */
#include "q_shared.h"
#include "botlib.h"
#include "be_aas.h"
#include "be_ea.h"
#include "be_ai_goal.h"
#include "be_ai_move.h"
#include "be_ai_weap.h"
#include "be_ai_chat.h"
#include <stdio.h>
#include <stddef.h>
#define O(t, f) printf(#t "." #f " %d\n", (int)offsetof(t, f))
#define S(t) printf("sizeof " #t " %d\n", (int)sizeof(t))
int main(void) {
  S(bot_entitystate_t); S(bot_input_t); S(bot_goal_t); S(bot_initmove_t); S(bot_moveresult_t); S(bot_avoidspot_t);
  S(aas_trace_t); S(aas_entityinfo_t); S(aas_areainfo_t); S(aas_clientmove_t); S(aas_altroutegoal_t);
  S(aas_predictroute_t); S(bot_match_t); S(bot_matchvariable_t); S(bot_consolemessage_t); S(weaponinfo_t);
  S(projectileinfo_t); S(pc_token_t);
  O(bot_entitystate_t, type); O(bot_entitystate_t, flags); O(bot_entitystate_t, origin); O(bot_entitystate_t, angles);
  O(bot_entitystate_t, old_origin); O(bot_entitystate_t, mins); O(bot_entitystate_t, maxs);
  O(bot_entitystate_t, groundent); O(bot_entitystate_t, solid); O(bot_entitystate_t, modelindex);
  O(bot_entitystate_t, modelindex2); O(bot_entitystate_t, frame); O(bot_entitystate_t, event);
  O(bot_entitystate_t, eventParm); O(bot_entitystate_t, powerups); O(bot_entitystate_t, weapon);
  O(bot_entitystate_t, legsAnim); O(bot_entitystate_t, torsoAnim);
  O(bot_input_t, thinktime); O(bot_input_t, dir); O(bot_input_t, speed); O(bot_input_t, viewangles);
  O(bot_input_t, actionflags); O(bot_input_t, weapon);
  O(bot_goal_t, origin); O(bot_goal_t, areanum); O(bot_goal_t, mins); O(bot_goal_t, maxs); O(bot_goal_t, entitynum);
  O(bot_goal_t, number); O(bot_goal_t, flags); O(bot_goal_t, iteminfo);
  O(bot_initmove_t, origin); O(bot_initmove_t, velocity); O(bot_initmove_t, viewoffset); O(bot_initmove_t, entitynum);
  O(bot_initmove_t, client); O(bot_initmove_t, thinktime); O(bot_initmove_t, presencetype);
  O(bot_initmove_t, viewangles); O(bot_initmove_t, or_moveflags);
  O(bot_moveresult_t, failure); O(bot_moveresult_t, type); O(bot_moveresult_t, blocked);
  O(bot_moveresult_t, blockentity); O(bot_moveresult_t, traveltype); O(bot_moveresult_t, flags);
  O(bot_moveresult_t, weapon); O(bot_moveresult_t, movedir); O(bot_moveresult_t, ideal_viewangles);
  O(aas_trace_t, startsolid); O(aas_trace_t, fraction); O(aas_trace_t, endpos); O(aas_trace_t, ent);
  O(aas_trace_t, lastarea); O(aas_trace_t, area); O(aas_trace_t, planenum);
  O(aas_entityinfo_t, valid); O(aas_entityinfo_t, type); O(aas_entityinfo_t, flags); O(aas_entityinfo_t, ltime);
  O(aas_entityinfo_t, update_time); O(aas_entityinfo_t, number); O(aas_entityinfo_t, origin);
  O(aas_entityinfo_t, angles); O(aas_entityinfo_t, old_origin); O(aas_entityinfo_t, lastvisorigin);
  O(aas_entityinfo_t, mins); O(aas_entityinfo_t, maxs); O(aas_entityinfo_t, groundent);
  O(aas_entityinfo_t, solid); O(aas_entityinfo_t, modelindex); O(aas_entityinfo_t, modelindex2);
  O(aas_entityinfo_t, frame); O(aas_entityinfo_t, event); O(aas_entityinfo_t, eventParm);
  O(aas_entityinfo_t, powerups); O(aas_entityinfo_t, weapon); O(aas_entityinfo_t, legsAnim);
  O(aas_entityinfo_t, torsoAnim);
  O(aas_areainfo_t, contents); O(aas_areainfo_t, flags); O(aas_areainfo_t, presencetype); O(aas_areainfo_t, cluster);
  O(aas_areainfo_t, mins); O(aas_areainfo_t, maxs); O(aas_areainfo_t, center);
  O(aas_clientmove_t, endpos); O(aas_clientmove_t, endarea); O(aas_clientmove_t, velocity);
  O(aas_clientmove_t, trace); O(aas_clientmove_t, presencetype); O(aas_clientmove_t, stopevent);
  O(aas_clientmove_t, endcontents); O(aas_clientmove_t, time); O(aas_clientmove_t, frames);
  O(aas_altroutegoal_t, origin); O(aas_altroutegoal_t, areanum); O(aas_altroutegoal_t, starttraveltime);
  O(aas_altroutegoal_t, goaltraveltime); O(aas_altroutegoal_t, extratraveltime);
  O(aas_predictroute_t, endpos); O(aas_predictroute_t, endarea); O(aas_predictroute_t, stopevent);
  O(aas_predictroute_t, endcontents); O(aas_predictroute_t, endtravelflags); O(aas_predictroute_t, numareas);
  O(aas_predictroute_t, time);
  O(bot_match_t, string); O(bot_match_t, type); O(bot_match_t, subtype); O(bot_match_t, variables);
  O(bot_matchvariable_t, offset); O(bot_matchvariable_t, length);
  O(bot_consolemessage_t, handle); O(bot_consolemessage_t, time); O(bot_consolemessage_t, type);
  O(bot_consolemessage_t, message); O(bot_consolemessage_t, prev); O(bot_consolemessage_t, next);
  O(weaponinfo_t, valid); O(weaponinfo_t, number); O(weaponinfo_t, name); O(weaponinfo_t, model);
  O(weaponinfo_t, level); O(weaponinfo_t, weaponindex); O(weaponinfo_t, flags); O(weaponinfo_t, projectile);
  O(weaponinfo_t, numprojectiles); O(weaponinfo_t, hspread); O(weaponinfo_t, vspread); O(weaponinfo_t, speed);
  O(weaponinfo_t, acceleration); O(weaponinfo_t, recoil); O(weaponinfo_t, offset); O(weaponinfo_t, angleoffset);
  O(weaponinfo_t, extrazvelocity); O(weaponinfo_t, ammoamount); O(weaponinfo_t, ammoindex);
  O(weaponinfo_t, activate); O(weaponinfo_t, reload); O(weaponinfo_t, spinup); O(weaponinfo_t, spindown);
  O(weaponinfo_t, proj);
  O(pc_token_t, type); O(pc_token_t, subtype); O(pc_token_t, intvalue); O(pc_token_t, floatvalue);
  O(pc_token_t, string);
  printf("const MAX_MESSAGE_SIZE %d\nconst MAX_MATCHVARIABLES %d\nconst MAX_STRINGFIELD %d\nconst MAX_TOKENLENGTH %d\n",
    MAX_MESSAGE_SIZE, MAX_MATCHVARIABLES, MAX_STRINGFIELD, MAX_TOKENLENGTH);
  return 0; }
