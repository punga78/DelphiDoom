#ifndef BEAASDEF_GUARD
#define BEAASDEF_GUARD
/* Stub of be_aas_def.h for the parity tool of the routing (issue #122): the fields of aasworld that be_aas_file.c,
   be_aas_sample.c, be_aas_route.c and be_aas_routealt.c use. The names, the types and the structures of the routing
   (aas_routingcache_t, aas_routingupdate_t, aas_reversedlink_t, aas_reversedreachability_t,
   aas_reachabilityareas_t) are copied from the real be_aas_def.h */
#define MAX_PATH_STUB 144

typedef struct aas_link_s
{
	int entnum;
	int areanum;
	struct aas_link_s *next_ent, *prev_ent;
	struct aas_link_s *next_area, *prev_area;
} aas_link_t;

#define CACHETYPE_PORTAL		0
#define CACHETYPE_AREA			1

//routing cache
typedef struct aas_routingcache_s
{
	byte type;									//portal or area cache
	float time;									//last time accessed or updated
	int size;									//size of the routing cache
	int cluster;								//cluster the cache is for
	int areanum;								//area the cache is created for
	vec3_t origin;								//origin within the area
	float starttraveltime;						//travel time to start with
	int travelflags;							//combinations of the travel flags
	struct aas_routingcache_s *prev, *next;
	struct aas_routingcache_s *time_prev, *time_next;
	unsigned char *reachabilities;				//reachabilities used for routing
	unsigned short int traveltimes[1];			//travel time for every area (variable sized)
} aas_routingcache_t;

//fields for the routing algorithm
typedef struct aas_routingupdate_s
{
	int cluster;
	int areanum;								//area number of the update
	vec3_t start;								//start point the area was entered
	unsigned short int tmptraveltime;			//temporary travel time
	unsigned short int *areatraveltimes;		//travel times within the area
	qboolean inlist;							//true if the update is in the list
	struct aas_routingupdate_s *next;
	struct aas_routingupdate_s *prev;
} aas_routingupdate_t;

//reversed reachability link
typedef struct aas_reversedlink_s
{
	int linknum;								//the aas_areareachability_t
	int areanum;								//reachable from this area
	struct aas_reversedlink_s *next;			//next link
} aas_reversedlink_t;

//reversed area reachability
typedef struct aas_reversedreachability_s
{
	int numlinks;
	aas_reversedlink_t *first;
} aas_reversedreachability_t;

//areas a reachability goes through
typedef struct aas_reachabilityareas_s
{
	int firstarea, numareas;
} aas_reachabilityareas_t;

typedef struct aas_s
{
	int loaded;
	int initialized;
	int savefile;
	int bspchecksum;
	float time;
	int numframes;
	char filename[MAX_PATH_STUB];
	char mapname[MAX_PATH_STUB];
	int numbboxes;
	aas_bbox_t *bboxes;
	int numvertexes;
	aas_vertex_t *vertexes;
	int numplanes;
	aas_plane_t *planes;
	int numedges;
	aas_edge_t *edges;
	int edgeindexsize;
	aas_edgeindex_t *edgeindex;
	int numfaces;
	aas_face_t *faces;
	int faceindexsize;
	aas_faceindex_t *faceindex;
	int numareas;
	aas_area_t *areas;
	int numareasettings;
	aas_areasettings_t *areasettings;
	int reachabilitysize;
	aas_reachability_t *reachability;
	int numnodes;
	aas_node_t *nodes;
	int numportals;
	aas_portal_t *portals;
	int portalindexsize;
	aas_portalindex_t *portalindex;
	int numclusters;
	aas_cluster_t *clusters;
	int numreachabilityareas;
	float reachabilitytime;
	aas_link_t *linkheap;
	int linkheapsize;
	aas_link_t *freelinks;
	aas_link_t **arealinkedentities;
	int travelflagfortype[MAX_TRAVELTYPES];
	int *areacontentstravelflags;
	aas_routingupdate_t *areaupdate;
	aas_routingupdate_t *portalupdate;
	int frameroutingupdates;
	aas_reversedreachability_t *reversedreachability;
	unsigned short ***areatraveltimes;
	aas_routingcache_t ***clusterareacache;
	aas_routingcache_t **portalcache;
	aas_routingcache_t *oldestcache;
	aas_routingcache_t *newestcache;
	int *portalmaxtraveltimes;
	int *reachabilityareaindex;
	aas_reachabilityareas_t *reachabilityareas;
	/* the route cache dump of the real file also uses these: unused here */
	byte **areavisibility;
	byte *decompressedvis;
} aas_t;

extern aas_t aasworld;
#endif
