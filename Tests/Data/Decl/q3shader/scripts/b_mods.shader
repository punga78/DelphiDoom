textures/test/tcmods
{
	{
		map textures/test/m1.tga
		tcMod scroll 0.5 -0.25
		tcMod scale 2 3
		tcMod rotate 30
		tcMod turb 0 0.25 0 0.5
	}
	{
		map textures/test/m2.tga
		tcMod stretch sawtooth 0 1 0 2
		tcMod transform 1 0 0 1 0.5 0.5
		tcMod entityTranslate
	}
	{
		map textures/test/m3.tga
		tcMod bogus 1 2
		tcMod scroll 1 1
	}
}

textures/test/tcmodshort
{
	{
		map textures/test/m5.tga
		tcMod scroll 1
		tcMod turb 1 2 3
		tcMod stretch
		tcMod
	}
}

textures/test/toomanymods
{
	{
		map textures/test/m4.tga
		tcMod rotate 1
		tcMod rotate 2
		tcMod rotate 3
		tcMod rotate 4
		tcMod rotate 5
	}
}

textures/test/anim
{
	{
		animMap 4 textures/test/f1.tga textures/test/f2.tga textures/test/f3.tga
		blendfunc add
	}
	{
		animMap 1 textures/test/g1.tga textures/test/g2.tga textures/test/g3.tga textures/test/g4.tga textures/test/g5.tga textures/test/g6.tga textures/test/g7.tga textures/test/g8.tga textures/test/g9.tga textures/test/g10.tga
	}
	{
		videoMap textures/test/movie.roq
	}
}

textures/test/deforms
{
	deformVertexes wave 100 sin 0 3 0 0.1
	deformVertexes normal 0.5 0.25
	deformVertexes bulge 4 8 2
	{
		map textures/test/d1.tga
	}
}

textures/test/deforms2
{
	deformVertexes move 0 0 1 sawtooth 0 2 0 0.5
	deformVertexes autosprite2
	deformVertexes projectionShadow
	{
		map textures/test/d2.tga
	}
}

textures/test/deforms3
{
	deformVertexes wave 0 sin 0 3 0 0.1
	deformVertexes text
	deformVertexes textures
	{
		map textures/test/d3.tga
	}
}

textures/test/deforms3b
{
	deformVertexes text9
	deformVertexes bogus
	deformVertexes text5
	{
		map textures/test/d3b.tga
	}
}

textures/test/deforms3c
{
	deformVertexes
	deformVertexes bulge 1
	deformVertexes autosprite
	{
		map textures/test/d3c.tga
	}
}

textures/test/deforms4
{
	deformVertexes move 1 2
	deformVertexes normal 1
	deformVertexes wave
	{
		map textures/test/d4.tga
	}
}

textures/test/deformsmax
{
	deformVertexes autosprite
	deformVertexes autosprite
	deformVertexes autosprite
	deformVertexes autosprite2
	{
		map textures/test/d6.tga
	}
}

textures/test/waveerrors
{
	deformVertexes wave 10 bogus 1 2
	deformVertexes move 1 2 3 sin 1 2
	{
		map textures/test/d5.tga
	}
}
