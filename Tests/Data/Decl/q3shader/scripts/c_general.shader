textures/test/sky
{
	skyParms textures/test/env/sky 512 -
	surfaceparm sky
	q3map_sun 0 0 1 300 90 45
	q3map_surfacelight 100
	tesssize 256
	{
		map textures/test/clouds.tga
		tcMod scroll 0.1 0.1
	}
}

textures/test/sky2
{
	skyParms - 0 textures/test/env/inner
	nopicmip
}

textures/test/skybad
{
	skyParms textures/test/env/only
	{
		map textures/test/s.tga
	}
}

textures/test/sun2
{
	q3map_sun 3 0 0 200 0 0
	{
		map textures/test/s2.tga
	}
}

textures/test/fog
{
	qer_editorimage textures/test/fog.tga
	surfaceparm fog
	surfaceparm trans
	fogParms ( 0.5 0.25 0.125 ) 256
	surfaceparm nonsolid
}

textures/test/fog2
{
	fogParms ( 1 1 1 ) 64 0 0 -1
	surfaceparm fog
}

textures/test/fogbad
{
	fogParms 1 1 1
	surfaceparm fog
}

textures/test/fogmissing
{
	fogParms ( 1 1 1 )
	surfaceparm fog
}

textures/test/sorts
{
	sort additive
	polygonOffset
	entityMergable
	clampTime 2.5
	light 1
	{
		map textures/test/so.tga
		blendfunc add
	}
}

textures/test/sorts2
{
	sort 7.5
	{
		map textures/test/so2.tga
	}
}

textures/test/sorts3
{
	sort portal
	portal
	{
		map textures/test/so3.tga
	}
}

textures/test/sorts4
{
	polygonOffset
	{
		map textures/test/so4.tga
	}
}

textures/test/sorts5
{
	sort
	cull
	cull bogus
	cull backsided
	sort underwater
	{
		map textures/test/so5.tga
		blendfunc blend
	}
}

textures/test/sortnames
{
	sort banner
	sort decal
	sort seeThrough
	sort opaque
	sort nearest
	sort sky
	{
		map textures/test/so6.tga
	}
}

textures/test/blendsort
{
	{
		map textures/test/bs1.tga
		blendfunc blend
	}
	{
		map textures/test/bs2.tga
		blendfunc add
		depthwrite
	}
}

textures/test/blendsort2
{
	{
		map textures/test/bs3.tga
		blendfunc blend
		depthwrite
	}
	{
		map textures/test/bs4.tga
		blendfunc blend
	}
}

textures/test/surfaceparms
{
	surfaceparm water
	surfaceparm slime
	surfaceparm lava
	surfaceparm playerclip
	surfaceparm monsterclip
	surfaceparm nodrop
	surfaceparm origin
	surfaceparm detail
	surfaceparm structural
	surfaceparm areaportal
	surfaceparm clusterportal
	surfaceparm donotenter
	surfaceparm lightfilter
	surfaceparm alphashadow
	surfaceparm hint
	surfaceparm slick
	surfaceparm noimpact
	surfaceparm nomarks
	surfaceparm ladder
	surfaceparm flesh
	surfaceparm nosteps
	surfaceparm nodraw
	surfaceparm pointlight
	surfaceparm nolightmap
	surfaceparm nodlight
	surfaceparm dust
	surfaceparm
	{
		map textures/test/sp.tga
	}
}
