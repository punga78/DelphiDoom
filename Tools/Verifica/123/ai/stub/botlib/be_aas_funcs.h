/* Stub of be_aas_funcs.h: the prototypes of the AAS functions that the files of the harness call (the real
   headers be_aas_*.h need the whole of be_aas_def.h) */
#ifndef STUB_BE_AAS_FUNCS_H
#define STUB_BE_AAS_FUNCS_H
typedef struct bsp_link_s
{
	int entnum;
	int leafnum;
	struct bsp_link_s *next_ent, *prev_ent;
	struct bsp_link_s *next_leaf, *prev_leaf;
} bsp_link_t;
typedef struct bsp_entdata_s
{
	vec3_t origin;
	vec3_t angles;
	vec3_t absmins;
	vec3_t absmaxs;
	int solid;
	int modelnum;
} bsp_entdata_t;
#define AASINTERN
#include "be_aas_bsp.h"
#undef AASINTERN
qboolean AAS_EntityCollision(int entnum, vec3_t start, vec3_t boxmins, vec3_t boxmaxs, vec3_t end, int contentmask, bsp_trace_t *trace);
void QDECL AAS_Error(char *fmt, ...);
int AAS_Initialized(void);
int AAS_Loaded(void);
float AAS_Time(void);
void AAS_ProjectPointOntoVector( vec3_t point, vec3_t vStart, vec3_t vEnd, vec3_t vProj );
void AAS_EntitySize(int entnum, vec3_t mins, vec3_t maxs);
int AAS_EntityModelNum(int entnum);
int AAS_OriginOfMoverWithModelNum(int modelnum, vec3_t origin);
void AAS_EntityInfo(int entnum, aas_entityinfo_t *info);
int AAS_NextEntity(int entnum);
int AAS_EntityType(int entnum);
int AAS_EntityModelindex(int entnum);
void AAS_PresenceTypeBoundingBox(int presencetype, vec3_t mins, vec3_t maxs);
int AAS_AreaCluster(int areanum);
int AAS_AreaPresenceType(int areanum);
int AAS_PointPresenceType(vec3_t point);
aas_trace_t AAS_TraceClientBBox(vec3_t start, vec3_t end, int presencetype, int passent);
int AAS_TraceAreas(vec3_t start, vec3_t end, int *areas, vec3_t *points, int maxareas);
int AAS_PointAreaNum(vec3_t point);
int AAS_AreaReachability(int areanum);
int AAS_BestReachableArea(vec3_t origin, vec3_t mins, vec3_t maxs, vec3_t goalorigin);
int AAS_BestReachableFromJumpPadArea(vec3_t origin, vec3_t mins, vec3_t maxs);
int AAS_NextModelReachability(int num, int modelnum);
int AAS_AreaCrouch(int areanum);
int AAS_AreaSwim(int areanum);
int AAS_AreaLiquid(int areanum);
int AAS_AreaLava(int areanum);
int AAS_AreaSlime(int areanum);
int AAS_AreaGrounded(int areanum);
int AAS_AreaLadder(int areanum);
int AAS_AreaJumpPad(int areanum);
int AAS_AreaDoNotEnter(int areanum);
int AAS_TravelFlagForType(int traveltype);
int AAS_AreaContentsTravelFlags(int areanum);
int AAS_NextAreaReachability(int areanum, int reachnum);
void AAS_ReachabilityFromNum(int num, struct aas_reachability_s *reach);
unsigned short int AAS_AreaTravelTime(int areanum, vec3_t start, vec3_t end);
int AAS_AreaTravelTimeToGoalArea(int areanum, vec3_t origin, int goalareanum, int travelflags);
int AAS_PredictClientMovement(struct aas_clientmove_s *move, int entnum, vec3_t origin, int presencetype, int onground, vec3_t velocity, vec3_t cmdmove, int cmdframes, int maxframes, float frametime, int stopevent, int stopareanum, int visualize);
int AAS_OnGround(vec3_t origin, int presencetype, int passent);
int AAS_Swimming(vec3_t origin);
void AAS_JumpReachRunStart(struct aas_reachability_s *reach, vec3_t runstart);
int AAS_AgainstLadder(vec3_t origin);
int AAS_HorizontalVelocityForJump(float zvel, vec3_t start, vec3_t end, float *velocity);
int AAS_DropToFloor(vec3_t origin, vec3_t mins, vec3_t maxs);
void AAS_InitSettings(void);
#endif
