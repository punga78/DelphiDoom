{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the colormaps read from the lumps              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.ColormapPreparer;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   What R_InitData and R_InitCustomColormaps do to the bytes of COLORMAP, of the custom
  ///   colormaps (C_START..C_END) and of FOGMAP once they are read
  /// </summary>
  TColormapPreparer = class(TInterfacedObject, IColormapPreparer)
  public
    function ReplaceZeros(const AColormap: TBytes; ABlack: Byte): TBytes;
    function ExpandRows(const AColormap: TBytes; AMinRows: Integer; out AMapCount: Integer): TBytes;
    function RowColors(const AColormap: TBytes; ARow: Integer;
      const APaletteColors: TArray<Cardinal>): TArray<Cardinal>;
    function PrepareFog(const AFog, AColormap: TBytes; ABlack: Byte;
      const APaletteColors: TArray<Cardinal>): TFogMapData;
  end;

implementation

{ TColormapPreparer }

function TColormapPreparer.ReplaceZeros(const AColormap: TBytes; ABlack: Byte): TBytes;
var
  LIndex: Integer;
begin
  Result := Copy(AColormap);
  for LIndex := 0 to High(Result) do
    if Result[LIndex] = 0 then
      Result[LIndex] := ABlack;
end;

function TColormapPreparer.ExpandRows(const AColormap: TBytes; AMinRows: Integer;
  out AMapCount: Integer): TBytes;
var
  LRow: Integer;
begin
  AMapCount := Length(AColormap) div COLORMAP_ROW_SIZE;
  if AMapCount < 1 then
    raise EPaletteException.CreateFmt(SColormapTooShort, [Length(AColormap), COLORMAP_ROW_SIZE]);
  Result := Copy(AColormap);
  if AMapCount >= AMinRows then
    Exit;
  SetLength(Result, AMinRows * COLORMAP_ROW_SIZE);
  for LRow := AMapCount to AMinRows - 1 do
    Move(Result[(AMapCount - 1) * COLORMAP_ROW_SIZE], Result[LRow * COLORMAP_ROW_SIZE],
      COLORMAP_ROW_SIZE);
  AMapCount := AMinRows;
end;

function TColormapPreparer.RowColors(const AColormap: TBytes; ARow: Integer;
  const APaletteColors: TArray<Cardinal>): TArray<Cardinal>;
var
  LIndex: Integer;
begin
  if (ARow < 0) or (Length(AColormap) < (ARow + 1) * COLORMAP_ROW_SIZE) then
    raise EPaletteException.CreateFmt(SColormapRowInvalid, [ARow]);
  if Length(APaletteColors) < PALETTE_COLOR_COUNT then
    raise EPaletteException.CreateFmt(SPaletteTooShort, [Length(APaletteColors), PALETTE_COLOR_COUNT]);
  SetLength(Result, COLORMAP_ROW_SIZE);
  for LIndex := 0 to COLORMAP_ROW_SIZE - 1 do
    Result[LIndex] := APaletteColors[AColormap[ARow * COLORMAP_ROW_SIZE + LIndex]];
end;

function TColormapPreparer.PrepareFog(const AFog, AColormap: TBytes; ABlack: Byte;
  const APaletteColors: TArray<Cardinal>): TFogMapData;
var
  LIndex: Integer;
begin
  if Length(AFog) > Length(AColormap) then
    raise EPaletteException.CreateFmt(SFogLongerThanColormap, [Length(AFog), Length(AColormap)]);
  if Length(APaletteColors) < PALETTE_COLOR_COUNT then
    raise EPaletteException.CreateFmt(SPaletteTooShort, [Length(APaletteColors), PALETTE_COLOR_COUNT]);
  Result.Indexes := Copy(AFog);
  SetLength(Result.Colors, Length(AFog));
  for LIndex := 0 to High(Result.Indexes) do
  begin
    if Result.Indexes[LIndex] = 0 then
      Result.Indexes[LIndex] := ABlack;
    // where the light colormap is black the fog is black too
    if AColormap[LIndex] = ABlack then
      Result.Indexes[LIndex] := ABlack;
    Result.Colors[LIndex] := APaletteColors[Result.Indexes[LIndex]];
  end;
end;

end.
