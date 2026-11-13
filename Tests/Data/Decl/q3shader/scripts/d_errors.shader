textures/test/nostage
{
	surfaceparm nodraw
}

textures/test/unknowngeneral
{
	bogusword 1 2
	{
		map textures/test/u1.tga
	}
}

textures/test/unknownstage
{
	{
		map textures/test/u2.tga
		bogusstage 1
	}
}

textures/test/missingmap
{
	{
		map
	}
}

textures/test/missingother
{
	{
		blendfunc
		alphaFunc
	}
}

textures/test/noimage
{
	{
		rgbGen identity
	}
	{
		map textures/test/u3.tga
	}
}

textures/test/crlf
{
	// a comment
	{
		map "textures/test/quoted name.tga"
		blendfunc add
	}
}

textures/test/detaildup
{
	{
		map textures/test/dd1.tga
		detail
	}
	{
		map textures/test/dd2.tga
		blendfunc filter
	}
	{
		map textures/test/dd3.tga
		detail
	}
	{
		map textures/test/dd4.tga
	}
}

textures/test/detaildup2
{
	{
		map textures/test/dd1.tga
		detail
	}
	{
		map textures/test/dd2.tga
		blendfunc filter
	}
	{
		map textures/test/dd3.tga
		detail
	}
	{
		map textures/test/dd4.tga
	}
}

textures/test/twice
{
	{
		map textures/test/first.tga
	}
}

textures/test/twice
{
	{
		map textures/test/second.tga
	}
}
