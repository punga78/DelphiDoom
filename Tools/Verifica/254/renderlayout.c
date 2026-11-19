/* renderlayout.c - sizeof and offsetof of refEntity_t, refdef_t and polyVert_t of the real tr_types.h (issue #254, R1). The numbers are the ones TQ3SceneReader and TTestQ3SceneReader use. Build: gcc -m32 -DWIN32 -D_WIN32 -DC_ONLY -I<code>/game -I<code>/cgame renderlayout.c. Licensed under the GNU General Public License, version 2 or later (Quake III Arena GPL Source Code, id Software). */
#include <stdio.h>
#include <stddef.h>
#include "q_shared.h"
#include "tr_types.h"
#define O(t, f) printf("%s.%s %d\n", #t, #f, (int)offsetof(t, f))
int main(void) {
	printf("refEntity_t %d refdef_t %d polyVert_t %d\n", (int)sizeof(refEntity_t), (int)sizeof(refdef_t), (int)sizeof(polyVert_t));
	O(refEntity_t, reType); O(refEntity_t, renderfx); O(refEntity_t, hModel); O(refEntity_t, lightingOrigin);
	O(refEntity_t, shadowPlane); O(refEntity_t, axis); O(refEntity_t, nonNormalizedAxes); O(refEntity_t, origin);
	O(refEntity_t, frame); O(refEntity_t, oldorigin); O(refEntity_t, oldframe); O(refEntity_t, backlerp);
	O(refEntity_t, skinNum); O(refEntity_t, customSkin); O(refEntity_t, customShader); O(refEntity_t, shaderRGBA);
	O(refEntity_t, shaderTexCoord); O(refEntity_t, shaderTime); O(refEntity_t, radius); O(refEntity_t, rotation);
	O(refdef_t, x); O(refdef_t, fov_x); O(refdef_t, vieworg); O(refdef_t, viewaxis); O(refdef_t, time);
	O(refdef_t, rdflags); O(refdef_t, areamask); O(refdef_t, text);
	O(polyVert_t, st); O(polyVert_t, modulate);
	return 0;
}

