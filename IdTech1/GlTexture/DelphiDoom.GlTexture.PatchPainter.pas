{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL texture buffers - paints a patch into a buffer           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlTexture.PatchPainter;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.GlTexture.Types;

type
  /// <summary>
  ///   The old gld_AddPatchToTexture and gld_AddPatchToTexture_UnTranslated: the posts of a
  ///   patch (the lump of the game, as bytes) are painted in a buffer at an origin, clipped to
  ///   the real size of the picture, with the colors of the palette (RGBA) or the colors of the
  ///   palette map (paletted buffer), through a table of translation of the colors if there is
  ///   one. Static and without state: it is called while a texture is built, never per pixel of
  ///   a frame.
  /// </summary>
  /// <remarks>
  ///   The patch is not checked against its size (as in the old code, it comes from the lump
  ///   cache): the caller gives only patches of the game.
  /// </remarks>
  TGlTexturePatchPainter = class
  public
    /// <summary>
    ///   Paints the patch. ATranslation is a table of 256 colors or nil for none;
    ///   APaletted chooses a buffer of 1 byte (the palette map) or of 4 (R, G, B, 255) per pixel
    /// </summary>
    class procedure Paint(const ATarget: TGlTextureTarget; const APatch: PByte; const AOriginX, AOriginY: Integer;
      const APalette: TGlTexturePaletteData; const ATranslation: PByte; const APaletted: Boolean); static;
  end;

implementation

{ TGlTexturePatchPainter }

class procedure TGlTexturePatchPainter.Paint(const ATarget: TGlTextureTarget; const APatch: PByte;
  const AOriginX, AOriginY: Integer; const APalette: TGlTexturePaletteData; const ATranslation: PByte;
  const APaletted: Boolean);
var
  LIdentity: array[0..255] of Byte;
  LTranslation: PByte;
  LX, LY, LJ: Integer;
  LStart, LEnd: Integer;
  LRowStart, LRowEnd: Integer;
  LColumn: PByte;
  LSource: PByte;
  LPos: Integer;
  LColor: Integer;
  LDelta, LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  if not Assigned(ATarget.Pixels) or not Assigned(APatch) then
    Exit;

  LStart := 0;
  LEnd := PSmallInt(APatch)^;
  if (LStart + AOriginX) >= ATarget.RealWidth then
    Exit;
  if (LEnd + AOriginX) <= 0 then
    Exit;
  LTranslation := ATranslation;
  if not Assigned(LTranslation) then
  begin
    for LJ := 0 to 255 do
      LIdentity[LJ] := LJ;
    LTranslation := @LIdentity[0];
  end;
  if (LStart + AOriginX) < 0 then
    LStart := -AOriginX;
  if (LEnd + AOriginX) > ATarget.RealWidth then
    LEnd := LEnd + ATarget.RealWidth - (LEnd + AOriginX);
  for LX := LStart to LEnd - 1 do
  begin
    LDelta := 0;
    LTallPatch := False;
    LColumn := APatch + PInteger(APatch + GLTEXTURE_PATCH_HEADER_SIZE + 4 * LX)^;
    while LColumn[0] <> GLTEXTURE_COLUMN_END do
    begin
      LDelta := LDelta + LColumn[0];
      LY := LDelta + AOriginY;
      LRowStart := 0;
      LRowEnd := LColumn[1];
      if (LRowStart + LY >= ATarget.RealHeight) or (LRowEnd + LY <= 0) then
      begin
        LColumn := LColumn + LColumn[1] + 4;
        LDelta := 0;
        Continue;
      end;
      if LRowStart + LY < 0 then
        LRowStart := -LY;
      if LRowEnd + LY > ATarget.RealHeight then
        LRowEnd := LRowEnd + ATarget.RealHeight - (LRowEnd + LY);
      LSource := LColumn + 3;
      if APaletted then
      begin
        LPos := (LRowStart + LY) * ATarget.BufferWidth + LX + AOriginX;
        LJ := LRowStart;
        while LJ < LRowEnd do
        begin
          ATarget.Pixels[LPos] := APalette.ColorMap[LTranslation[LSource[LJ]]];
          Inc(LJ);
          LPos := LPos + ATarget.BufferWidth;
        end;
      end
      else
      begin
        LPos := 4 * ((LRowStart + LY) * ATarget.BufferWidth + LX + AOriginX);
        LJ := LRowStart;
        while LJ < LRowEnd do
        begin
          LColor := LTranslation[LSource[LJ]] * 3;
          ATarget.Pixels[LPos] := APalette.Colors[LColor];
          ATarget.Pixels[LPos + 1] := APalette.Colors[LColor + 1];
          ATarget.Pixels[LPos + 2] := APalette.Colors[LColor + 2];
          ATarget.Pixels[LPos + 3] := 255;
          Inc(LJ);
          LPos := LPos + 4 * ATarget.BufferWidth;
        end;
      end;
      if not LTallPatch then
      begin
        LPreviousDelta := LColumn[0];
        LColumn := LColumn + LColumn[1] + 4;
        if LColumn[0] > LPreviousDelta then
          LDelta := 0
        else
          LTallPatch := True;
      end
      else
        LColumn := LColumn + LColumn[1] + 4;
    end;
  end;
end;

end.
