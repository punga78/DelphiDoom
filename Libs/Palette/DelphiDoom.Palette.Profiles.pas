{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the profiles of the games                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Profiles;

interface

uses
  DelphiDoom.Palette.Types;

type
  /// <summary>The values of V_CreateDoomPalette for each game, without IFDEF</summary>
  TPaletteProfiles = class
  strict private
    class function Shift(ATargetIndex, ARed, AGreen, ABlue, AShift, ASteps: Integer): TPaletteShift; static;
    class procedure AddCommonShifts(var AShifts: TArray<TPaletteShift>); static;
  public
    /// <summary>Doom, Heretic and Strife: 14 palettes (8 red, 4 yellow, 1 green)</summary>
    class function Doom: TPaletteProfile; static;
    /// <summary>Hexen: 28 palettes (red, yellow, 8 green, ice, the 3 grays, the 3 yellows)</summary>
    class function Hexen: TPaletteProfile; static;
  end;

implementation

{ TPaletteProfiles }

class function TPaletteProfiles.Shift(ATargetIndex, ARed, AGreen, ABlue, AShift,
  ASteps: Integer): TPaletteShift;
begin
  Result.TargetIndex := ATargetIndex;
  Result.Red := ARed;
  Result.Green := AGreen;
  Result.Blue := ABlue;
  Result.Shift := AShift;
  Result.Steps := ASteps;
end;

class procedure TPaletteProfiles.AddCommonShifts(var AShifts: TArray<TPaletteShift>);
var
  LIndex: Integer;
begin
  for LIndex := 1 to 8 do
    AShifts := AShifts + [Shift(LIndex, 255, 0, 0, LIndex, 9)];
  for LIndex := 1 to 4 do
    AShifts := AShifts + [Shift(LIndex + 8, 215, 186, 69, LIndex, 8)];
end;

class function TPaletteProfiles.Doom: TPaletteProfile;
begin
  Result.PaletteCount := PLAYPAL_COUNT_DOOM;
  Result.Shifts := nil;
  AddCommonShifts(Result.Shifts);
  // 256 on purpose: the green of the radiation suit goes a little over the byte (as the original)
  Result.Shifts := Result.Shifts + [Shift(13, 0, 256, 0, 1, 8)];
  Result.LastColorShadesAsFirst := False;
  Result.InvertedGrayRow := True;
end;

class function TPaletteProfiles.Hexen: TPaletteProfile;
var
  LIndex: Integer;
begin
  Result.PaletteCount := PLAYPAL_COUNT_HEXEN;
  Result.Shifts := nil;
  AddCommonShifts(Result.Shifts);
  for LIndex := 1 to 8 do
    Result.Shifts := Result.Shifts + [Shift(12 + LIndex, 44, 92, 36, LIndex, 10)];
  Result.Shifts := Result.Shifts + [
    Shift(21, 0, 0, 224, 1, 2),
    Shift(22, 130, 130, 130, 1, 2),
    Shift(23, 100, 100, 100, 1, 2),
    Shift(24, 70, 70, 70, 1, 2),
    Shift(25, 150, 110, 0, 1, 2),
    Shift(26, 125, 92, 0, 1, 2),
    Shift(27, 100, 73, 0, 1, 2)];
  Result.LastColorShadesAsFirst := True;
  Result.InvertedGrayRow := False;
end;

end.
