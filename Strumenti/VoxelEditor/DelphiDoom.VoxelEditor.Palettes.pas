{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the palettes                                      }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Palettes;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types;

type
  /// <summary>
  ///   The 256-color palettes that a voxel can be reduced to (vxe_palette of DD_VOXEL): the palettes of the games,
  ///   a file of the user and the search of the nearest color. Colors are $00BBGGRR (RGB() of Windows)
  /// </summary>
  TVoxelEditorPalettes = class sealed
  public
    /// <summary>
    ///   The nearest color of a palette, between two indexes: the smallest distance (sum of the squares of the
    ///   differences of the channels), the first one that is found if there are two, and at once an exact match
    /// </summary>
    class function FindApproximateIndex(const APalette: TVoxelEditorPalette; AColor: Cardinal;
      AStart: Integer = 0; AFinish: Integer = 255): Integer; static;
    /// <summary>The palette of a game; the kinds that are not a game (the octree, a file) give the gray ramp</summary>
    class function OfGame(AKind: TVoxelEditorPaletteKind): TVoxelEditorPalette; static;
    /// <summary>The bytes R, G, B of 256 colors (768) as a palette</summary>
    class function FromRgbBytes(const ABytes: TBytes): TVoxelEditorPalette; static;
    /// <summary>
    ///   The palette of a file: 768 bytes of R, G, B, or 1024 bytes that are 256 colors of 32 bits; any other size,
    ///   and a file that is not there (empty bytes), give the gray ramp
    /// </summary>
    class function FromFileBytes(const ABytes: TBytes): TVoxelEditorPalette; static;
    class function Gray: TVoxelEditorPalette; static;
    /// <summary>RGB() of Windows</summary>
    class function Rgb(ARed, AGreen, ABlue: Cardinal): Cardinal; static; inline;
  end;

implementation

uses
  DelphiDoom.Palette.GamePalettes;

{ TVoxelEditorPalettes }

class function TVoxelEditorPalettes.Rgb(ARed, AGreen, ABlue: Cardinal): Cardinal;
begin
  Result := (ARed and $FF) or ((AGreen and $FF) shl 8) or ((ABlue and $FF) shl 16);
end;

class function TVoxelEditorPalettes.FindApproximateIndex(const APalette: TVoxelEditorPalette; AColor: Cardinal;
  AStart, AFinish: Integer): Integer;
var
  LRed, LGreen, LBlue, LIndex: Integer;
  LCandidate: Cardinal;
  LDeltaRed, LDeltaGreen, LDeltaBlue: Integer;
  LDistance, LMinimum: Cardinal;
begin
  LRed := AColor and $FF;
  LGreen := (AColor shr 8) and $FF;
  LBlue := (AColor shr 16) and $FF;
  Result := AStart;
  LMinimum := $FFFFFFFF;
  for LIndex := AStart to AFinish do
  begin
    LCandidate := APalette[LIndex];
    LDeltaRed := LRed - Integer(LCandidate and $FF);
    LDeltaGreen := LGreen - Integer((LCandidate shr 8) and $FF);
    LDeltaBlue := LBlue - Integer((LCandidate shr 16) and $FF);
    LDistance := Cardinal(LDeltaRed * LDeltaRed + LDeltaGreen * LDeltaGreen + LDeltaBlue * LDeltaBlue);
    if LDistance < LMinimum then
    begin
      Result := LIndex;
      if LDistance = 0 then
        Exit;
      LMinimum := LDistance;
    end;
  end;
end;

class function TVoxelEditorPalettes.FromRgbBytes(const ABytes: TBytes): TVoxelEditorPalette;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    Result[LIndex] := Rgb(ABytes[LIndex * 3], ABytes[LIndex * 3 + 1], ABytes[LIndex * 3 + 2]);
end;

class function TVoxelEditorPalettes.Gray: TVoxelEditorPalette;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    Result[LIndex] := Rgb(LIndex, LIndex, LIndex);
end;

class function TVoxelEditorPalettes.OfGame(AKind: TVoxelEditorPaletteKind): TVoxelEditorPalette;
begin
  case AKind of
    vepDoom:
      Result := FromRgbBytes(TGamePalettes.Colors(gpDoom));
    vepHeretic:
      Result := FromRgbBytes(TGamePalettes.Colors(gpHeretic));
    vepHexen:
      Result := FromRgbBytes(TGamePalettes.Colors(gpHexen));
    vepStrife:
      Result := FromRgbBytes(TGamePalettes.Colors(gpStrife));
    vepRadix:
      Result := FromRgbBytes(TGamePalettes.Colors(gpRadix));
  else
    Result := Gray;
  end;
end;

class function TVoxelEditorPalettes.FromFileBytes(const ABytes: TBytes): TVoxelEditorPalette;
var
  LIndex: Integer;
begin
  if Length(ABytes) = 768 then
    Result := FromRgbBytes(ABytes)
  else if Length(ABytes) = SizeOf(TVoxelEditorPalette) then
    for LIndex := 0 to 255 do
      Result[LIndex] := PCardinal(@ABytes[LIndex * 4])^ and $FFFFFF
  else
    Result := Gray;
end;

end.
