{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL texture buffers - does a texture have holes              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlTexture.Transparency;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.GlTexture.Types;

type
  /// <summary>
  ///   The old gld_AddPatchForTransparencyCheck and the scan of gld_CheckTextureTransparency: the
  ///   posts of the patches of a texture are marked with 255 in a mask of one byte per pixel
  ///   (rows of the real width), and the texture has holes if some byte of the mask is not 255.
  /// </summary>
  /// <remarks>
  ///   The patch is not checked against its size (as in the old code, it comes from the lump
  ///   cache).
  /// </remarks>
  TGlTextureTransparency = class
  public
    /// <summary>Marks the posts of a patch in the mask; the stride of the mask is the real width</summary>
    class procedure MarkPatch(const AMask: PByte; const ARealWidth, ARealHeight: Integer; const APatch: PByte;
      const AOriginX, AOriginY: Integer); static;
    /// <summary>
    ///   True if some byte of the mask is not 255, except that (as in the old code) the first
    ///   four bytes are not looked at when the mask has more than 6 bytes
    /// </summary>
    class function HasHoles(const AMask: PByte; const ASize: Integer): Boolean; static;
  end;

implementation

{ TGlTextureTransparency }

class procedure TGlTextureTransparency.MarkPatch(const AMask: PByte; const ARealWidth, ARealHeight: Integer;
  const APatch: PByte; const AOriginX, AOriginY: Integer);
var
  LX, LY, LJ: Integer;
  LStart, LEnd: Integer;
  LRowStart, LRowEnd: Integer;
  LColumn: PByte;
  LPos: Integer;
  LDelta, LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LStart := 0;
  LEnd := PSmallInt(APatch)^;
  if LStart + AOriginX >= ARealWidth then
    Exit;
  if LEnd + AOriginX <= 0 then
    Exit;
  if LStart + AOriginX < 0 then
    LStart := -AOriginX;
  if LEnd + AOriginX > ARealWidth then
    LEnd := LEnd + ARealWidth - (LEnd + AOriginX);
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
      if (LRowStart + LY >= ARealHeight) or (LRowEnd + LY <= 0) then
      begin
        LColumn := LColumn + LColumn[1] + 4;
        LDelta := 0;
        Continue;
      end;
      if LRowStart + LY < 0 then
        LRowStart := -LY;
      if LRowEnd + LY > ARealHeight then
        LRowEnd := LRowEnd + ARealHeight - (LRowEnd + LY);
      LPos := (LRowStart + LY) * ARealWidth + LX + AOriginX;
      LJ := LRowStart;
      while LJ < LRowEnd do
      begin
        AMask[LPos] := 255;
        Inc(LJ);
        LPos := LPos + ARealWidth;
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

class function TGlTextureTransparency.HasHoles(const AMask: PByte; const ASize: Integer): Boolean;
var
  LSpot, LIndex: Integer;
  LWords: PCardinal;
begin
  Result := False;
  if ASize > 3 then
  begin
    LSpot := (ASize - 3) and (not 3);
    // the words go down from the spot and the first four bytes of the mask are never looked at:
    // both are as in the old code. A word that would end after the mask (the mask has 4n + 3
    // bytes) was read with the byte after it in the old code; here it is skipped, and its bytes
    // are the ones of the loop below.
    for LIndex := 0 to (LSpot shr 2) - 1 do
    begin
      LWords := PCardinal(AMask + LSpot - 4 * LIndex);
      if (LSpot - 4 * LIndex + 4 <= ASize) and (LWords^ <> $FFFFFFFF) then
      begin
        Result := True;
        Break;
      end;
    end;

    for LIndex := LSpot to ASize - 1 do
    begin
      if AMask[LIndex] <> 255 then
      begin
        Result := True;
        Break;
      end;
    end;
  end
  else
  begin
    for LIndex := 0 to ASize - 1 do
    begin
      if AMask[LIndex] <> 255 then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

end.
