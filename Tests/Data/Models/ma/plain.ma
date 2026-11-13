//Maya ASCII 4.0 scene
//A single triangle without transform, material or texture coordinates (written for the tests of Libs\Models)
requires maya "4.0";
createNode mesh -n "plainShape";
	setAttr -s 3 ".vt[0:2]"  0 0 0  2 0 0  0 0 -2;
	setAttr -s 3 ".ed[0:2]"  0 1 0  1 2 0  2 0 0;
	setAttr -s 1 ".fc[0]" -type "polyFaces"
		f 3 0 1 2;
