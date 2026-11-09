{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixFlatPart                                  }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateFlats of radix_xlat_wad.pas                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.FlatPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   The flats: every bitmap of the walls turned and repeated to a 64 x 64 or 128 x 128 flat
  ///   (the wall bitmaps are stored by columns), the flat of the tile bitmap and F_SKY1, a flat
  ///   of the color nearest to a light blue
  /// </summary>
  TRadixFlatPart = class(TInterfacedObject, IRadixPart)
  strict private
    FMatcher: IColorMatcher;
    FMakeAllFlats: Boolean;
    class function Repeated(const AImage: TBytes; AWidth, AHeight: Integer): TBytes; static;
  public
    /// <param name="AMatcher">Finds the nearest color of the palette; EArgumentNilException when nil</param>
    /// <param name="AMakeAllFlats">True: a flat for every bitmap; false: only for the square ones</param>
    constructor Create(const AMatcher: IColorMatcher; AMakeAllFlats: Boolean);
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.BitmapTable;

{ TRadixFlatPart }

constructor TRadixFlatPart.Create(const AMatcher: IColorMatcher; AMakeAllFlats: Boolean);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FMatcher := AMatcher;
  FMakeAllFlats := AMakeAllFlats;
end;

class function TRadixFlatPart.Repeated(const AImage: TBytes; AWidth, AHeight: Integer): TBytes;
var
  LSize: Integer;
  LColumn: Integer;
  LRow: Integer;
  LTileX: Integer;
  LTileY: Integer;
begin
  if not (((AWidth = 32) and (AHeight in [32, 64, 128])) or
    ((AWidth = 64) and (AHeight in [64, 128])) or ((AWidth = 128) and (AHeight in [64, 128]))) then
  begin
    // the other sizes are written as they are
    Result := Copy(AImage, 0, AWidth * AHeight);
    Exit;
  end;
  LSize := AWidth;
  if AHeight > LSize then
    LSize := AHeight;
  if LSize < 64 then
    LSize := 64;
  SetLength(Result, LSize * LSize);
  // the bitmap is stored by columns: the flat is the transposed one, repeated to fill the square
  for LColumn := 0 to AWidth - 1 do
    for LRow := 0 to AHeight - 1 do
      for LTileX := 0 to LSize div AWidth - 1 do
        for LTileY := 0 to LSize div AHeight - 1 do
          Result[(LRow + AHeight * LTileY) * LSize + LColumn + AWidth * LTileX] :=
            AImage[LColumn * AHeight + LRow];
end;

procedure TRadixFlatPart.Build(const AContext: TRadixTranslationContext);
var
  LTableIndex: Integer;
  LCount: Integer;
  LTable: TArray<TRadixBitmapRecord>;
  LTile: TBytes;
  LIndex: Integer;
  LImage: TBytes;
  LSky: TBytes;
  LColor: Byte;
begin
  if not TRadixBitmapTable.TryRead(AContext.Container, LTable) then
    Exit;
  LCount := Length(LTable);

  AContext.Wad.AddMarker('F_START');

  LTableIndex := AContext.Container.IndexOf('TileBitmap');
  if (LTableIndex >= 0) and (AContext.Container.Infos[LTableIndex].Length = 4100) then
  begin
    LTile := Copy(AContext.Container.Read(LTableIndex), 4, 4096);
    for LIndex := 0 to 4095 do
      if LTile[LIndex] = 0 then
        LTile[LIndex] := 63;
    AContext.Wad.AddLump(RADIX_FLAT_PREFIX + '0000', LTile);
  end;

  for LIndex := 0 to LCount - 1 do
    if FMakeAllFlats or ((LIndex + 1 < Length(AContext.MarkFlats)) and AContext.MarkFlats[LIndex + 1]) then
    begin
      LImage := AContext.Container.ReadAt(LTable[LIndex].Position,
        LTable[LIndex].Width * LTable[LIndex].Height);
      AContext.Wad.AddLump(RADIX_FLAT_PREFIX + Format('%.4d', [LIndex + 1]),
        Repeated(LImage, LTable[LIndex].Width, LTable[LIndex].Height));
    end;

  // F_SKY1 is flat of the light blue of the sky
  LColor := Byte(FMatcher.FindApproximateIndex(AContext.PaletteColors,
    (77 shl 16) + (179 shl 8) + 255, 0, 255));
  SetLength(LSky, 64 * 64);
  FillChar(LSky[0], Length(LSky), LColor);
  AContext.Wad.AddLump('F_SKY1', LSky);

  AContext.Wad.AddMarker('F_END');
end;

end.
