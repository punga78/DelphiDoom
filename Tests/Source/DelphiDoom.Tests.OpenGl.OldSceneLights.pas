{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - the old text of the dynamic lights  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.OldSceneLights;

// The text of gld_DrawDLight, gld_SortDlights and gld_DrawDLights of gl_render.pas as it was before
// TEngineGlSceneLightSorter and TEngineGlSceneLightPainter (commit 107c7c4b4, Libs\OpenGl\Legacy\gl_render.pas),
// copied as it was: only the names, and inv_yaw that was a global of gl_render and here is a parameter.

interface

uses
  d_delphi,
  r_dynlights;

procedure OldSortDlights;

procedure OldDrawDLights(const AInverseYaw: float);

implementation

uses
  dglOpenGL,
  r_lights;

const
  COS16TABLE: array[0..16] of float = (
    1.0000000000,
    0.9238795042,
    0.7071067691,
    0.3826834261,
   -0.0000000000,
   -0.3826834261,
   -0.7071067691,
   -0.9238795042,
   -1.0000000000,
   -0.9238795042,
   -0.7071067691,
   -0.3826834261,
    0.0000000000,
    0.3826834261,
    0.7071067691,
    0.9238795042,
    1.0000000000
   );

  SIN16TABLE: array[0..16] of float = (
    0.0000000000,
    0.3826834261,
    0.7071067691,
    0.9238795042,
    1.0000000000,
    0.9238795042,
    0.7071067691,
    0.3826834261,
   -0.0000000000,
   -0.3826834261,
   -0.7071067691,
   -0.9238795042,
   -1.0000000000,
   -0.9238795042,
   -0.7071067691,
   -0.3826834261,
    0.0000000000
   );

procedure gld_DrawDLight(const pdls: Pdlsortitem_t; const inv_yaw: float);
var
  i: integer;
  sz: float;
begin
  glPushMatrix;
  glTranslatef(pdls.x, pdls.y, pdls.z);
  glRotatef(inv_yaw, 0.0, 1.0, 0.0);

  sz := pdls.l.radius;
//  if GL_CheckVisibility(pdls.x, pdls.y, pdls.z, 2 * sz) then
  begin
    glBegin(GL_TRIANGLE_FAN);
      glColor4f(pdls.l.r * 0.2, pdls.l.g * 0.2, pdls.l.b * 0.2, 0.1);
      glVertex3f(0.0, 0.0, 0.05);
      glColor4f(0.0, 0.0, 0.0, 0.1);
      for i := 0 to 16 do
        glVertex3f(sz * COS16TABLE[i], sz * SIN16TABLE[i], 0.05);
    glEnd;
  end;

  glPopMatrix;
end;

procedure OldSortDlights;

  procedure qsort(l, r: Integer);
  var
    i, j: Integer;
    tmp: dlsortitem_t;
    squaredist: float;
  begin
    repeat
      i := l;
      j := r;
      squaredist := dlbuffer[(l + r) shr 1].squaredist;
      repeat
        while dlbuffer[i].squaredist < squaredist do
          inc(i);
        while dlbuffer[j].squaredist > squaredist do
          dec(j);
        if i <= j then
        begin
          tmp := dlbuffer[i];
          dlbuffer[i] := dlbuffer[j];
          dlbuffer[j] := tmp;
          inc(i);
          dec(j);
        end;
      until i > j;
      if l < j then
        qsort(l, j);
      l := i;
    until i >= r;
  end;

begin
  if numdlitems > 0 then
    qsort(0, numdlitems - 1);
end;

procedure OldDrawDLights(const AInverseYaw: float);
var
  pdls: Pdlsortitem_t;
  lastitem: dlsortitem_t;
begin
  if not uselightboost then
    exit;

  if numdlitems = 0 then
    exit;

  glMatrixMode(GL_MODELVIEW);
  glDepthMask(False);
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_ALPHA_TEST);
  glBlendFunc(GL_ONE, GL_ONE);

  FillChar(lastitem, SizeOf(dlsortitem_t), 0);
  // Draw each light in order
  pdls := @dlbuffer[numdlitems];
  while NativeInt(pdls) <> NativeInt(dlbuffer) do
  begin
    dec(pdls);
    if (pdls.l <> lastitem.l) or
       (pdls.x <> lastitem.x) or
       (pdls.y <> lastitem.y) or
       (pdls.z <> lastitem.z) then
    begin
      gld_DrawDLight(pdls, AInverseYaw);
      lastitem := pdls^;
    end;
  end;

  glDepthMask(True);
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_ALPHA_TEST);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

end;

end.
