//Maya ASCII 4.0 scene
//Name: parts.ma
//Two triangles under two nested transforms, with vertex offsets (pt), no normals, two shading networks
//that point at the same picture (written for the tests of Libs\Models)
requires maya "4.0";
createNode transform -n "grp1";
	setAttr ".t" -type "double3" 0 0 5 ;
	setAttr ".r" -type "double3" 30 0 45 ;
createNode transform -n "obj1" -p "grp1";
	setAttr ".t" -type "double3" 1 0 0 ;
	setAttr ".s" -type "double3" 1 2 3 ;
	setAttr -k off ".v";
createNode mesh -n "tri1Shape" -p "obj1";
	setAttr -s 3 ".vt[0:2]"  0 0 0  1 0 0  0 0 -1;
	setAttr -s 3 ".ed[0:2]"  0 1 0  1 2 0  2 0 0;
	setAttr -s 3 ".uvst[0].uvsp[0:2]" -type "float2" 0 0 1 0 0 1;
	setAttr -s 3 ".pt";
	setAttr ".pt[0:2]" -type "float3" 0.5 0 0  0 0 0.25  0 0 0;
	setAttr -s 1 ".fc[0]" -type "polyFaces"
		f 3 0 1 2
		mf 3 0 1 2;
createNode mesh -n "tri2Shape" -p "obj1";
	setAttr -s 3 ".vt[0:2]"  0 0 0  0 1 0  1 1 0;
	setAttr -s 3 ".ed[0:2]"  0 1 0  1 2 0  2 0 0;
	setAttr -s 1 ".fc[0]" -type "polyFaces"
		f 3 0 1 2;
createNode lambert -n "lambertA";
createNode shadingEngine -n "lambertASG";
createNode file -n "fileA";
	setAttr ".ftn" -type "string" "D:/art/models/tex/stone.tga";
createNode blinn -n "blinnB";
createNode shadingEngine -n "blinnBSG";
createNode file -n "fileB";
	setAttr ".ftn" -type "string" "D:/art/models/tex/stone.tga";
connectAttr "fileA.oc" "lambertA.c";
connectAttr "lambertA.oc" "lambertASG.ss";
connectAttr "tri1Shape.iog" "lambertASG.dsm" -na;
connectAttr "fileB.oc" "blinnB.c";
connectAttr "blinnB.oc" "blinnBSG.ss";
connectAttr "tri2Shape.iog" "blinnBSG.dsm" -na;
select -ne :time1;
