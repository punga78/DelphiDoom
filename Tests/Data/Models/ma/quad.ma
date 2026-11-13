//Maya ASCII 4.0 scene
//Name: quad.ma
//Last modified: written for the tests of Libs\Models
requires maya "4.0";
fileInfo "application" "maya";
createNode transform -n "pQuad1";
	setAttr ".t" -type "double3" 1 2 3 ;
	setAttr ".r" -type "double3" 0 90 0 ;
	setAttr ".s" -type "double3" 2 2 2 ;
createNode mesh -n "pQuadShape1" -p "pQuad1";
	setAttr -k off ".v";
	setAttr -s 4 ".vt[0:3]"  -1 0 1  1 0 1  -1 0 -1  1 0 -1;
	setAttr -s 5 ".ed[0:4]"  0 1 0  0 2 0  1 3 0  2 3 0  1 2 1;
	setAttr ".uvst[0].uvsn" -type "string" "map1";
	setAttr -s 4 ".uvst[0].uvsp[0:3]" -type "float2" 0 0 1 0 0 1 1 1;
	setAttr -s 4 ".n[0:3]" -type "float3"  0 1 0  0 1 0  0 1 0  0 1 0 ;
	setAttr -s 4 ".clr[0:3]"  1 0 0 1  0 1 0 1  0 0 1 1  0.5 0.5 0.5 1;
	setAttr -s 2 ".fc[0:1]" -type "polyFaces"
		f 3 0 4 -2
		mu 0 3 0 1 2
		fc 3 0 1 2
		f 3 2 -4 -5
		mu 0 3 1 3 2;
createNode lambert -n "lambert2";
createNode shadingEngine -n "lambert2SG";
createNode file -n "file1";
	setAttr ".ftn" -type "string" "C:/work/models/tex/brick.tga";
connectAttr "file1.oc" "lambert2.c";
connectAttr "lambert2.oc" "lambert2SG.ss";
connectAttr "pQuadShape1.iog" "lambert2SG.dsm" -na;
