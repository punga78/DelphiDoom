//A face with four edges: the loader only takes triangles
createNode mesh -n "quadShape";
	setAttr -s 4 ".vt[0:3]"  0 0 0  1 0 0  1 0 -1  0 0 -1;
	setAttr -s 4 ".ed[0:3]"  0 1 0  1 2 0  2 3 0  3 0 0;
	setAttr -s 1 ".fc[0]" -type "polyFaces"
		f 4 0 1 2 3;
