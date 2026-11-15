// Shaders written for the parity test of the issue 237 (CollapseMultitexture and VertexLightingCollapse of
// tr_shader.c); none of them comes from a game.

textures/test/c_lm_first
{
	{ map $lightmap
	  rgbGen identity }
	{ map textures/test/c1.tga
	  blendfunc filter
	  rgbGen identity }
}

textures/test/c_lm_second
{
	{ map textures/test/c1.tga
	  rgbGen identity }
	{ map $lightmap
	  blendfunc filter }
}

textures/test/c_modulate_blend
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc GL_ZERO GL_SRC_COLOR }
}

textures/test/c_filter_filter
{
	{ map textures/test/c1.tga
	  blendfunc filter }
	{ map textures/test/c2.tga
	  blendfunc filter }
}

textures/test/c_srccolor_filter
{
	{ map textures/test/c1.tga
	  blendfunc GL_ZERO GL_SRC_COLOR }
	{ map textures/test/c2.tga
	  blendfunc filter }
}

textures/test/c_filter_srccolor
{
	{ map textures/test/c1.tga
	  blendfunc filter }
	{ map textures/test/c2.tga
	  blendfunc GL_ZERO GL_SRC_COLOR }
}

textures/test/c_srccolor_srccolor
{
	{ map textures/test/c1.tga
	  blendfunc GL_ZERO GL_SRC_COLOR }
	{ map textures/test/c2.tga
	  blendfunc GL_ZERO GL_SRC_COLOR }
}

textures/test/c_add
{
	{ map textures/test/c1.tga
	  rgbGen identity }
	{ map textures/test/glow.tga
	  blendfunc add
	  rgbGen identity }
}

textures/test/c_add_vertex
{
	{ map textures/test/c1.tga
	  rgbGen vertex }
	{ map textures/test/glow.tga
	  blendfunc add
	  rgbGen vertex }
}

textures/test/c_add_add
{
	{ map textures/test/c1.tga
	  blendfunc add
	  rgbGen identity }
	{ map textures/test/glow.tga
	  blendfunc add
	  rgbGen identity }
}

textures/test/c_rgbgen_differs
{
	{ map textures/test/c1.tga
	  rgbGen identity }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen vertex }
}

textures/test/c_alphagen_differs
{
	{ map textures/test/c1.tga
	  rgbGen identity
	  alphaGen vertex }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen identity }
}

textures/test/c_wave_same
{
	{ map textures/test/c1.tga
	  rgbGen wave sin 0.5 0.25 0 2 }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen wave sin 0.5 0.25 0 2 }
}

textures/test/c_wave_phase
{
	{ map textures/test/c1.tga
	  rgbGen wave sin 0.5 0.25 0 2 }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen wave sin 0.5 0.25 0.5 2 }
}

textures/test/c_wave_func
{
	{ map textures/test/c1.tga
	  rgbGen wave sin 0.5 0.25 0 2 }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen wave triangle 0.5 0.25 0 2 }
}

// the alpha waveform is compared only for AGEN_PORTAL (the original compares with CGEN_WAVEFORM): two
// different waveforms collapse, an alpha portal with the same (empty) waveform does too
textures/test/c_alpha_wave_differs
{
	{ map textures/test/c1.tga
	  rgbGen identity
	  alphaGen wave sin 0 1 0 1 }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen identity
	  alphaGen wave square 0 1 0 4 }
}

textures/test/c_alpha_portal
{
	{ map textures/test/c1.tga
	  rgbGen identity
	  alphaGen portal 300 }
	{ map textures/test/c2.tga
	  blendfunc filter
	  rgbGen identity
	  alphaGen portal 500 }
}

textures/test/c_alphafunc_differs
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc filter
	  alphaFunc GT0 }
}

textures/test/c_depthfunc_differs
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc filter
	  depthfunc equal }
}

textures/test/c_depthwrite_differs
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc filter
	  depthwrite }
}

textures/test/c_three
{
	{ map $lightmap
	  rgbGen identity }
	{ map textures/test/c1.tga
	  blendfunc filter
	  rgbGen identity }
	{ map textures/test/glow.tga
	  blendfunc add
	  rgbGen identity }
}

textures/test/c_five
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc filter }
	{ map textures/test/c3.tga
	  blendfunc add }
	{ map textures/test/c4.tga
	  blendfunc blend }
	{ map textures/test/c5.tga
	  blendfunc add
	  tcMod scroll 0.5 0
	}
}

textures/test/c_single
{
	{ map textures/test/c1.tga
	  rgbGen identity }
}

textures/test/c_blend
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc blend }
}

textures/test/c_tcmods
{
	{ map textures/test/c1.tga
	  tcGen environment
	  tcMod rotate 30
	}
	{ map textures/test/c2.tga
	  blendfunc filter
	  tcMod scroll 0.25 0.5
	  tcMod scale 2 2
	}
}

textures/test/c_noimage_second
{
	{ map textures/test/c1.tga }
	{ blendfunc filter }
	{ map textures/test/c2.tga
	  blendfunc filter }
}

// vertex light mode: one pass for an opaque shader, the best ranked stage
textures/test/v_opaque_lightmap
{
	{ map $lightmap
	  rgbGen identity }
	{ map textures/test/c1.tga
	  blendfunc filter
	  rgbGen identity }
}

textures/test/v_opaque_ranked
{
	{ map textures/test/c1.tga
	  rgbGen wave sin 0.5 0.25 0 2
	  tcMod scroll 1 1
	}
	{ map textures/test/c2.tga
	  tcGen environment
	  rgbGen identity }
	{ map textures/test/c3.tga
	  rgbGen vertex
	  alphaGen vertex }
	{ map textures/test/c4.tga
	  rgbGen identityLighting
	  blendfunc filter }
}

textures/test/v_opaque_tie
{
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc filter }
}

textures/test/v_opaque_tcgen
{
	{ map textures/test/c1.tga
	  tcGen environment }
	{ map textures/test/c2.tga
	  tcMod rotate 10
	}
	{ map textures/test/c3.tga
	  rgbGen const ( 1 0 0 ) }
}

textures/test/v_blend_plain
{
	{ map textures/test/c1.tga
	  blendfunc add }
	{ map textures/test/c2.tga
	  blendfunc add }
}

textures/test/v_blend_lightmap_first
{
	{ map $lightmap
	  blendfunc filter
	  rgbGen identity }
	{ map textures/test/c2.tga
	  blendfunc add
	  rgbGen identity }
}

textures/test/v_oneminusentity_first
{
	{ map textures/test/c1.tga
	  blendfunc add
	  rgbGen oneMinusEntity }
	{ map textures/test/c2.tga
	  blendfunc add
	  rgbGen entity }
}

textures/test/v_oneminusentity_second
{
	{ map textures/test/c1.tga
	  blendfunc add
	  rgbGen entity }
	{ map textures/test/c2.tga
	  blendfunc add
	  rgbGen oneMinusEntity }
}

textures/test/v_saw
{
	{ map textures/test/c1.tga
	  blendfunc add
	  rgbGen wave sawtooth 0 1 0 1 }
	{ map textures/test/c2.tga
	  blendfunc add
	  rgbGen wave inversesawtooth 0 1 0 1 }
}

textures/test/v_saw_reversed
{
	{ map textures/test/c1.tga
	  blendfunc add
	  rgbGen wave inversesawtooth 0 1 0 1 }
	{ map textures/test/c2.tga
	  blendfunc add
	  rgbGen wave sawtooth 0 1 0 1 }
}

textures/test/v_saw_same
{
	{ map textures/test/c1.tga
	  blendfunc add
	  rgbGen wave sawtooth 0 1 0 1 }
	{ map textures/test/c2.tga
	  blendfunc add
	  rgbGen wave sawtooth 0 1 0 1 }
}

textures/test/v_single
{
	{ map textures/test/c1.tga
	  blendfunc add }
}

textures/test/v_sky
{
	skyparms textures/test/sky 512 -
	{ map textures/test/c1.tga }
	{ map textures/test/c2.tga
	  blendfunc filter }
}
