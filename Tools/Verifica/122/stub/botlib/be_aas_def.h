#ifndef BEAASDEF_GUARD
#define BEAASDEF_GUARD
/* Stub of be_aas_def.h: the part of the structure aasworld that be_aas_file.c and be_aas_sample.c use
   (the field names and the types are the real ones) */
#define MAX_TRAVELTYPES_STUB 32

typedef struct aas_link_s
{
	int entnum;
	int areanum;
	struct aas_link_s *next_ent, *prev_ent;
	struct aas_link_s *next_area, *prev_area;
} aas_link_t;

typedef struct aas_s
{
	int loaded;
	int initialized;
	int savefile;
	int bspchecksum;
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
	aas_link_t *linkheap;
	int linkheapsize;
	aas_link_t *freelinks;
	aas_link_t **arealinkedentities;
} aas_t;

extern aas_t aasworld;
#endif
