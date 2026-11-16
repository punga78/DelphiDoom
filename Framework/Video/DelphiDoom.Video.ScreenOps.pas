{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the loops of v_video that run over a screen      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.ScreenOps;

interface

uses
  DelphiDoom.Video.Stretch;

type
  /// <summary>
  ///   The hot loops that v_video runs over a whole screen or a part of it: copy without the
  ///   transparent pixels, shade (halve the colors), remove the transparent index. Static functions on plain
  ///   pointers: no interfaces, no allocation, no calls inside the loops; v_video keeps the
  ///   choice of the screens and of the depth, and the loops are the ones that were there
  /// </summary>
  TVideoScreenOps = class sealed
  public
    /// <summary>Copies the pixels that are not 0 (four at once when all four are 0)</summary>
    class procedure CopyTransparent8(Src, Dest: PByte; Count: Integer); static;
    /// <summary>Copies the pixels that are not 0 from an 8 bit screen to a 32 bit one through the palette</summary>
    class procedure CopyTransparent32(Src: PByte; Dest, Palette: PLongWord; Count: Integer); static;
    /// <summary>Halves the 8 bit channels of Count bytes (a 32 bit screen is Count = pixels * 4)</summary>
    class procedure Shade32(Src: PByte; Count: Integer); static;
    /// <summary>Maps Count 8 bit pixels through a colormap of 256 entries</summary>
    class procedure ShadeIndexed(Src: PByte; ColorMap: PByte; Count: Integer); static;
    /// <summary>Halves the three color channels of Count 32 bit pixels and sets the alpha (OpenGL)</summary>
    class procedure ShadeOpaque32(Src: PByte; Count: Integer); static;
    /// <summary>Replaces the index 0 with Approx in Count pixels</summary>
    class procedure RemoveTransparency(Src: PByte; Approx: Byte; Count: Integer); static;
    /// <summary>
    ///   Fills AHeight rows of AWidth bytes (a screen of 8 bit pixels, the rows one after the other) with a flat of
    ///   64x64 pixels repeated (ASource: 4096 bytes); row y takes the row y mod 64 of the flat
    /// </summary>
    class procedure TileFlat64(ASource, ADestination: PByte; AWidth, AHeight: Integer); static;
  end;

implementation

{ TVideoScreenOps }

class procedure TVideoScreenOps.CopyTransparent8(Src, Dest: PByte; Count: Integer);
begin
  while Count > 4 do
  begin
    if PLongWord(Src)^ = 0 then
    begin
      Inc(Dest, 4);
      Inc(Src, 4);
      Dec(Count, 4)
    end
    else
    begin
      if Src^ <> 0 then
        Dest^ := Src^;
      Inc(Dest);
      Inc(Src);
      Dec(Count);
    end;
  end;
  while Count > 0 do
  begin
    if Src^ <> 0 then
      Dest^ := Src^;
    Inc(Dest);
    Inc(Src);
    Dec(Count);
  end;
end;

class procedure TVideoScreenOps.CopyTransparent32(Src: PByte; Dest, Palette: PLongWord; Count: Integer);
begin
  while Count > 0 do
  begin
    if Src^ <> 0 then
      Dest^ := PVideoLongWordRow(Palette)[Src^];
    Inc(Dest);
    Inc(Src);
    Dec(Count);
  end;
end;

class procedure TVideoScreenOps.Shade32(Src: PByte; Count: Integer);
begin
  while Count > 16 do
  begin
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);

    Dec(Count, 16);
  end;

  while Count > 4 do
  begin
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);
      Src^ := Src^ shr 1;
      Inc(Src);

    Dec(Count, 4);
  end;

  while Count > 0 do
  begin
    Src^ := Src^ shr 1;
    Inc(Src);
    Dec(Count);
  end;
end;

class procedure TVideoScreenOps.ShadeIndexed(Src: PByte; ColorMap: PByte; Count: Integer);
begin
  while Count > 0 do
  begin
    Src^ := PVideoByteRow(ColorMap)[Src^];
    Inc(Src);
    Dec(Count);
  end;
end;

class procedure TVideoScreenOps.ShadeOpaque32(Src: PByte; Count: Integer);
begin
  while Count > 0 do
  begin
    Src^ := Src^ shr 1;
    Inc(Src);
    Src^ := Src^ shr 1;
    Inc(Src);
    Src^ := Src^ shr 1;
    Inc(Src);
    Src^ := Src^ or $80;
    Inc(Src);
    Dec(Count);
  end;
end;

class procedure TVideoScreenOps.RemoveTransparency(Src: PByte; Approx: Byte; Count: Integer);
begin
  while Count > 0 do
  begin
    if Src^ = 0 then
      Src^ := Approx;
    Inc(Src);
    Dec(Count);
  end;
end;

class procedure TVideoScreenOps.TileFlat64(ASource, ADestination: PByte; AWidth, AHeight: Integer);
var
  LRow: Integer;
  LRowSource: PByte;
  LTiles: Integer;
  LTile: Integer;
begin
  LTiles := AWidth div 64;
  for LRow := 0 to AHeight - 1 do
  begin
    LRowSource := PByte(NativeInt(ASource) + (LRow and 63) * 64);
    for LTile := 0 to LTiles - 1 do
    begin
      Move(LRowSource^, ADestination^, 64);
      Inc(ADestination, 64);
    end;
    if AWidth and 63 <> 0 then
    begin
      Move(LRowSource^, ADestination^, AWidth and 63);
      Inc(ADestination, AWidth and 63);
    end;
  end;
end;

end.