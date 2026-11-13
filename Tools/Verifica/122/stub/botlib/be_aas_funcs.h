/* Stub of be_aas_funcs.h: what the two files call from other parts of the AAS */
void QDECL AAS_Error(char *fmt, ...);
int AAS_AreaReachability(int areanum);
qboolean AAS_EntityCollision(int entnum, vec3_t start, vec3_t boxmins, vec3_t boxmaxs, vec3_t end,
								int contentmask, bsp_trace_t *trace);
