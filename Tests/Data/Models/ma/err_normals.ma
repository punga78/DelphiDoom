//Normals: one less than the triangle needs
createNode mesh -n "nShape";
	setAttr -s 3 ".vt[0:2]"  0 0 0  1 0 0  0 0 -1;
	setAttr -s 3 ".ed[0:2]"  0 1 0  1 2 0  2 0 0;
	setAttr -s 2 ".n[0:1]" -type "float3"  0 1 0  0 1 0 ;
	setAttr -s 1 ".fc[0]" -type "polyFaces"
		f 3 0 1 2;
