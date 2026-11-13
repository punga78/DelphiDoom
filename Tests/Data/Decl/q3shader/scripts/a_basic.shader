// Shaders written for the parity test of the issue 119; none of them comes from a game.
/* a block comment
   over two lines */
textures/test/plain
{
	qer_editorimage textures/test/plain.tga
	surfaceparm metalsteps
	surfaceparm nodamage
	surfaceparm notinthetable
	{
		map textures/test/plain.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendfunc filter
	}
}

textures/test/blends
{
	cull none
	nomipmaps
	{
		map textures/test/blend_a.tga
		blendfunc GL_ONE GL_ONE_MINUS_SRC_ALPHA
		alphaFunc GE128
		depthfunc equal
	}
	{
		map textures/test/blend_b.tga
		blendfunc add
		alphaFunc LT128
		depthfunc lequal
		depthwrite
	}
	{
		map $whiteimage
		blendfunc blend
		alphaFunc GT0
	}
	{
		clampmap textures/test/blend_c.tga
		blendfunc GL_DST_COLOR GL_ZERO
	}
	{
		map textures/test/blend_d.tga
		blendfunc GL_ONE GL_ZERO
	}
	{
		map textures/test/blend_e.tga
		blendfunc GL_ZERO GL_ONE_MINUS_SRC_COLOR
	}
}

textures/test/blendnames
{
	cull back
	{
		map textures/test/n1.tga
		blendfunc GL_ONE_MINUS_DST_COLOR GL_SRC_ALPHA
	}
	{
		map textures/test/n2.tga
		blendfunc GL_DST_ALPHA GL_ONE_MINUS_DST_ALPHA
	}
	{
		map textures/test/n3.tga
		blendfunc GL_ALPHA_SATURATE GL_SRC_COLOR
	}
	{
		map textures/test/n4.tga
		blendfunc GL_BOGUS GL_BOGUS2
		alphaFunc BOGUS
		depthfunc other
	}
}

textures/test/colors
{
	cull disable
	{
		map textures/test/c1.tga
		rgbGen wave sin 0.5 0.25 0 2
		alphaGen wave triangle 0 1 0.5 1
	}
	{
		map textures/test/c2.tga
		rgbGen const ( 0.5 0.25 1 )
		alphaGen const 0.75
		blendfunc add
	}
	{
		map textures/test/c3.tga
		rgbGen vertex
	}
	{
		map textures/test/c4.tga
		rgbGen exactVertex
		alphaGen portal 300
	}
	{
		map textures/test/c5.tga
		rgbGen entity
		alphaGen oneMinusEntity
	}
	{
		map textures/test/c6.tga
		rgbGen oneMinusEntity
		alphaGen lightingSpecular
	}
	{
		map textures/test/c7.tga
		rgbGen lightingDiffuse
		alphaGen vertex
	}
	{
		map textures/test/c8.tga
		rgbGen oneMinusVertex
		alphaGen oneMinusVertex
	}
}

textures/test/colorerrors
{
	{
		map textures/test/e1.tga
		rgbGen
		alphaGen
		rgbGen bogus
		alphaGen bogus
		alphaGen portal
		rgbGen identityLighting
		alphaGen identity
	}
	{
		map textures/test/e2.tga
		rgbGen wave inversesawtooth 1 2 3
		alphaGen wave bogus 1 2 3 4
	}
	{
		map textures/test/e3.tga
		rgbGen identity
		alphaGen entity
	}
}

textures/test/texgen
{
	{
		map textures/test/t1.tga
		tcGen environment
	}
	{
		map textures/test/t2.tga
		texgen lightmap
	}
	{
		map textures/test/t3.tga
		tcGen base
	}
	{
		map textures/test/t4.tga
		tcGen vector ( 0.5 0 0 ) ( 0 0.5 0 )
	}
	{
		map textures/test/t5.tga
		tcGen texture
		tcGen
		tcGen bogus
	}
}
