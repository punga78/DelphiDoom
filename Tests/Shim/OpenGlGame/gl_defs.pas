{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_defs for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_defs.pas in DelphiDoom.Tests.OpenGl.<Game> only: the options and
// the types the scene units read, same names, same initial values and same declarations as the real ones
// (keep them aligned).
unit gl_defs;

interface

uses
  d_delphi,
  dglOpenGL,
  m_fixed,
  r_draw;

type
  GLTexture = record
    width, height: integer;
    leftoffset, topoffset: integer;
    tex_width, tex_height: integer;
    realtexwidth, realtexheight: integer;
  end;
  PGLTexture = ^GLTexture;

const
  CR_DEFAULT = CR_LIMIT;
  VPT_STRETCH = 1;
  VPT_FLIP = 2;
  VPT_TRANS = 4;
  VPT_NOUNLOAD = 8;

type
  gld_camera_t = record
    position: TGLVectorf3;
    rotation: TGLVectorf3;
  end;
  Pgld_camera_t = ^gld_camera_t;

const
  __glPi = 3.14159265358979323846;
  MAP_COEFF = 128.0;
  MAP_SCALE = MAP_COEFF * FRACUNIT;

var
  camera: gld_camera_t;

  use_fog: boolean = false;
  fog_density: integer = 100;
  use_white_fog: boolean = true;
  white_fog_density: integer = 200;
  tran_filter_pct: integer = 66;

  gl_screensync: boolean = true;
  gl_nearclip: integer = 5;
  gl_renderwireframe: Boolean = false;
  gl_no_glfinish_hack: Boolean = true;
  gl_texture_filter_anisotropic: boolean = false;
  gl_use_paletted_texture: integer = 0;
  gl_use_shared_texture_palette: integer = 0;
  gl_paletted_texture: boolean = false;
  gl_shared_texture_palette: boolean = false;

type
  lp3DFXFUNC = procedure(i1, i2, i3, i4, i5: integer; const p: pointer);

var
  gld_ColorTableEXT: lp3DFXFUNC = nil;

type
  gl_filter_t = (
    FLT_NEAREST,
    FLT_LINEAR,
    FLT_LINEAR_MIPMAP_NEAREST,
    FLT_NEAREST_MIPMAP_NEAREST,
    FLT_NEAREST_MIPMAP_LINEAR,
    FLT_LINEAR_MIPMAP_LINEAR,
    NUM_GL_FILTERS
  );

const
  gl_tex_filters: array[0..Ord(NUM_GL_FILTERS) - 1] of string = (
    'GL_NEAREST',
    'GL_LINEAR',
    'GL_LINEAR_MIPMAP_NEAREST',
    'GL_NEAREST_MIPMAP_NEAREST',
    'GL_NEAREST_MIPMAP_LINEAR',
    'GL_LINEAR_MIPMAP_LINEAR'
  );

var
  gl_tex_format_string: string;
  gl_tex_format: integer = GL_RGBA8;

type
  tex_format_lookup_t = record
    tex_format: integer;
    desc: string
  end;

const
  DEF_TEX_FORMAT = GL_RGBA;
  NUM_GL_TEX_FORMATS = 5;
  gl_tex_formats: array[0..NUM_GL_TEX_FORMATS - 1] of tex_format_lookup_t = (
    (tex_format: GL_RGBA8; desc: 'GL_RGBA8'),
    (tex_format: GL_RGB5_A1; desc: 'GL_RGB5_A1'),
    (tex_format: GL_RGBA4; desc: 'GL_RGBA4'),
    (tex_format: GL_RGBA2; desc: 'GL_RGBA2'),
    (tex_format: GL_RGBA; desc: 'GL_RGBA')
  );

implementation

end.
