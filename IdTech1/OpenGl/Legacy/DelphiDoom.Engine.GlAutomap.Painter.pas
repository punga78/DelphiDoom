//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the items of the OpenGL automap
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.GlAutomap.Painter;

interface

uses
  DelphiDoom.GlAutomap.Types,
  DelphiDoom.GlAutomap.Intf;

type
  /// <summary>
  ///   The OpenGL calls of the automap of a frame (it was gld_DrawAutomap and the gld_DrawAM* of
  ///   gl_automap.pas): the same calls with the same numbers, in the order of the items
  /// </summary>
  /// <remarks>
  ///   One call to the interface per frame; the items are walked by pointer and the methods are static calls.
  ///   Textures and patches are the ones of the renderer (gl_tex, gl_render), the time of the level is p_tick's.
  /// </remarks>
  TEngineGlAutomapPainter = class(TInterfacedObject, IGlAutomapPainter)
  strict private
    FScalesFlatsToSize: Boolean;
    procedure PaintBackground(const AItem: PGlAutomapItem);
    procedure PaintLine(const AItem: PGlAutomapItem);
    procedure PaintPatch(const AItem: PGlAutomapItem);
    procedure PaintTriangle(const AItem: PGlAutomapItem);
  public
    /// <param name="AScalesFlatsToSize">
    ///   The game maps a flat by its real size (Hexen): the texture coordinates are scaled by 64 / size
    /// </param>
    constructor Create(const AScalesFlatsToSize: Boolean);
    procedure Paint(const AFirst: PGlAutomapItem; const ACount: Integer);
  end;

implementation

uses
  dglOpenGL,
  doomdef,
  p_tick,
  gl_defs,
  gl_tex,
  gl_render;

{ TEngineGlAutomapPainter }

constructor TEngineGlAutomapPainter.Create(const AScalesFlatsToSize: Boolean);
begin
  inherited Create;
  FScalesFlatsToSize := AScalesFlatsToSize;
end;

procedure TEngineGlAutomapPainter.PaintBackground(const AItem: PGlAutomapItem);
begin
  glColor4f(AItem.Red, AItem.Green, AItem.Blue, 1.0);

  glBegin(GL_QUADS);
    glVertex2i(AItem.X1, AItem.Y1);
    glVertex2i(AItem.X2, AItem.Y1);
    glVertex2i(AItem.X2, AItem.Y2);
    glVertex2i(AItem.X1, AItem.Y2);
  glEnd;
end;

procedure TEngineGlAutomapPainter.PaintLine(const AItem: PGlAutomapItem);
begin
  glColor4f(AItem.Red, AItem.Green, AItem.Blue, 1.0);

  glBegin(GL_LINES);
    glVertex2i(AItem.X1, AItem.Y1);
    glVertex2i(AItem.X2, AItem.Y2);
  glEnd;
end;

procedure TEngineGlAutomapPainter.PaintPatch(const AItem: PGlAutomapItem);
begin
  glEnable(GL_TEXTURE_2D);

  glColor4f(1.0, 1.0, 1.0, 1.0);

  gld_DrawNumPatch(AItem.X1, AItem.Y1, AItem.Lump, 0, VPT_NOUNLOAD, SCREENWIDTH / 320, SCREENHEIGHT / 200);

  glDisable(GL_TEXTURE_2D);
end;

procedure TEngineGlAutomapPainter.PaintTriangle(const AItem: PGlAutomapItem);
var
  LTexture: PGLTexture;
  LHasOffsets: Boolean;
  LOffsetX, LOffsetY: Single;
  LAngleX, LAngleY: Single;
  LS1, LT1, LS2, LT2, LS3, LT3: Single;
begin
  glEnable(GL_TEXTURE_2D);

  glColor4f(AItem.Red, AItem.Green, AItem.Blue, 1.0);

  LTexture := gld_RegisterFlat(AItem.Lump, True, AItem.Flat);
  if AItem.Ripples then
    gld_BindFlat(LTexture, leveltime and 31)
  else
    gld_BindFlat(LTexture, -1);

  LHasOffsets := (AItem.OffsetX <> 0) or (AItem.OffsetY <> 0);
  if LHasOffsets then
  begin
    LOffsetX := AItem.OffsetX * LTexture.texturescale / FLATUVSCALE;
    LOffsetY := AItem.OffsetY * LTexture.texturescale / FLATUVSCALE;
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(LOffsetX, LOffsetY, 0.0);
  end;

  // The expressions are the ones of the old code, operation by operation: each is rounded to Single once,
  // when it is stored, as it was when it was passed to OpenGL
  if FScalesFlatsToSize then
  begin
    LS1 := AItem.V1 * LTexture.texturescale * 64 / LTexture.width;
    LT1 := AItem.U1 * LTexture.texturescale * 64 / LTexture.height;
    LS2 := AItem.V2 * LTexture.texturescale * 64 / LTexture.width;
    LT2 := AItem.U2 * LTexture.texturescale * 64 / LTexture.height;
    LS3 := AItem.V3 * LTexture.texturescale * 64 / LTexture.width;
    LT3 := AItem.U3 * LTexture.texturescale * 64 / LTexture.height;
  end
  else
  begin
    LS1 := AItem.V1 * LTexture.texturescale;
    LT1 := AItem.U1 * LTexture.texturescale;
    LS2 := AItem.V2 * LTexture.texturescale;
    LT2 := AItem.U2 * LTexture.texturescale;
    LS3 := AItem.V3 * LTexture.texturescale;
    LT3 := AItem.U3 * LTexture.texturescale;
  end;

  if AItem.HasAngle then
  begin
    if FScalesFlatsToSize then
    begin
      LAngleX := AItem.AngleX * LTexture.texturescale * 64 / LTexture.width;
      LAngleY := AItem.AngleY * LTexture.texturescale * 64 / LTexture.height;
    end
    else
    begin
      LAngleX := AItem.AngleX * LTexture.texturescale;
      LAngleY := AItem.AngleY * LTexture.texturescale;
    end;
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(LAngleX, -LAngleY, 0.0);
    glRotatef(AItem.Angle, 0, 0, 1);
    glTranslatef(-LAngleX, LAngleY, 0.0);
  end;

  glBegin(GL_TRIANGLES);
    glTexCoord2f(LS1, LT1);
    glVertex2i(AItem.X1, AItem.Y1);
    glTexCoord2f(LS2, LT2);
    glVertex2i(AItem.X2, AItem.Y2);
    glTexCoord2f(LS3, LT3);
    glVertex2i(AItem.X3, AItem.Y3);
  glEnd;

  if AItem.HasAngle then
  begin
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
  end;

  if LHasOffsets then
  begin
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
  end;

  glDisable(GL_TEXTURE_2D);
end;

procedure TEngineGlAutomapPainter.Paint(const AFirst: PGlAutomapItem; const ACount: Integer);
var
  LIndex: Integer;
  LItem: PGlAutomapItem;
begin
  glDisable(GL_TEXTURE_2D);

  LItem := AFirst;
  for LIndex := 0 to ACount - 1 do
  begin
    case LItem.Kind of
      gakLine:
        PaintLine(LItem);
      gakBackground:
        PaintBackground(LItem);
      gakTriangle:
        PaintTriangle(LItem);
      gakPatch:
        PaintPatch(LItem);
    end;
    Inc(LItem);
  end;

  glEnable(GL_TEXTURE_2D);
end;

end.
