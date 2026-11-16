{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL scene - the shared texture palette from a game palette   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlScene.SharedPalette;

interface

const
  /// <summary>Entries of a game palette</summary>
  GL_SHARED_PALETTE_COLORS = 256;
  /// <summary>Bytes of the table for OpenGL: four (R, G, B, A) for every entry</summary>
  GL_SHARED_PALETTE_BYTES = GL_SHARED_PALETTE_COLORS * 4;

type
  /// <summary>
  ///   The table that gld_SetPalette of gl_render.pas gives to glColorTableEXT when the video card has a shared
  ///   texture palette (it was the body of that branch): 256 entries of four bytes, opaque, the colour of each
  ///   entry taken from the palette of the game, or through the fixed colormap of the player when there is one
  /// </summary>
  TGlSceneSharedPalette = class sealed
  public
    /// <summary>
    ///   Fills ATable (GL_SHARED_PALETTE_BYTES bytes). AColors points at the three-byte colours the table is built
    ///   from (gld_SetPalette passes the second palette of PLAYPAL, kept as it was); AColormap, when not nil, is the
    ///   fixed colormap (256 bytes) that picks the colour of every entry. The entry ATransparentIndex becomes
    ///   transparent black; an index outside 0..255 leaves every entry opaque (the old code wrote past the table)
    /// </summary>
    class procedure Build(const AColors: PByte; const AColormap: PByte; const ATransparentIndex: Integer;
      const ATable: PByte); static;
  end;

implementation

{$POINTERMATH ON}

{ TGlSceneSharedPalette }

class procedure TGlSceneSharedPalette.Build(const AColors: PByte; const AColormap: PByte;
  const ATransparentIndex: Integer; const ATable: PByte);
var
  LIndex: Integer;
  LSource: Integer;
  LTarget: Integer;
begin
  for LIndex := 0 to GL_SHARED_PALETTE_COLORS - 1 do
  begin
    if AColormap <> nil then
      LSource := 3 * AColormap[LIndex]
    else
      LSource := 3 * LIndex;
    LTarget := LIndex * 4;
    ATable[LTarget] := AColors[LSource];
    ATable[LTarget + 1] := AColors[LSource + 1];
    ATable[LTarget + 2] := AColors[LSource + 2];
    ATable[LTarget + 3] := 255;
  end;

  if (ATransparentIndex >= 0) and (ATransparentIndex < GL_SHARED_PALETTE_COLORS) then
  begin
    LTarget := ATransparentIndex * 4;
    ATable[LTarget] := 0;
    ATable[LTarget + 1] := 0;
    ATable[LTarget + 2] := 0;
    ATable[LTarget + 3] := 0;
  end;
end;

end.
