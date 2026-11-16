{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - marker pairs (F_START/F_END ...)                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Indicators;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Wad.Types;

type
  /// <summary>
  ///   The marker pairs that enclose floors, sprites, patches, voxels and hi
  ///   res textures (F_START/F_END, F1_START/F1_END, S_START/S_END, ...):
  ///   38 pairs, as in the engine
  /// </summary>
  TWadIndicators = class
  strict private
    class var FStarts: TDictionary<string, Integer>;
    class var FEnds: TDictionary<string, Integer>;
    class constructor Create;
    class destructor Destroy;
    class procedure Add(const APrefix: string; AKind: Integer); static;
  public
    /// <summary>True (with the IND_* kind) when AName opens a pair, as in F_START</summary>
    class function IsStart(const AName: string; out AKind: Integer): Boolean; static;
    /// <summary>True (with the IND_* kind) when AName closes a pair, as in F_END</summary>
    class function IsEnd(const AName: string; out AKind: Integer): Boolean; static;
    /// <summary>
    ///   The TYPE_* bits of every lump: those between a closing marker and the
    ///   opening one before it (the scan goes from the last lump, as the engine does)
    /// </summary>
    class function ComputeFlags(const ANames: TArray<string>): TArray<Cardinal>; static;
  end;

implementation

{ TWadIndicators }

class constructor TWadIndicators.Create;
const
  SUFFIXES: array[0..11] of string = ('', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'D');
var
  LSuffix: string;
begin
  FStarts := TDictionary<string, Integer>.Create;
  FEnds := TDictionary<string, Integer>.Create;
  for LSuffix in SUFFIXES do
  begin
    // the last of the series repeats the letter: FF_START, SS_START, PP_START
    if LSuffix = 'D' then
    begin
      Add('FF', IND_FLOOR);
      Add('SS', IND_SPRITE);
      Add('PP', IND_PATCH);
    end
    else
    begin
      Add('F' + LSuffix, IND_FLOOR);
      Add('S' + LSuffix, IND_SPRITE);
      Add('P' + LSuffix, IND_PATCH);
    end;
  end;
  Add('VX', IND_VOXEL);
  Add('HI', IND_HIRES);
end;

class destructor TWadIndicators.Destroy;
begin
  FStarts.Free;
  FEnds.Free;
end;

class procedure TWadIndicators.Add(const APrefix: string; AKind: Integer);
begin
  FStarts.Add(APrefix + '_START', AKind);
  FEnds.Add(APrefix + '_END', AKind);
end;

class function TWadIndicators.IsStart(const AName: string; out AKind: Integer): Boolean;
begin
  Result := FStarts.TryGetValue(AName, AKind);
end;

class function TWadIndicators.IsEnd(const AName: string; out AKind: Integer): Boolean;
begin
  Result := FEnds.TryGetValue(AName, AKind);
end;

class function TWadIndicators.ComputeFlags(const ANames: TArray<string>): TArray<Cardinal>;
var
  LOpen: array[0..IND_MAX - 1] of Integer;
  LIndex, LKind: Integer;
  LFlags: Cardinal;
begin
  SetLength(Result, Length(ANames));
  FillChar(LOpen, SizeOf(LOpen), 0);
  for LIndex := High(ANames) downto 0 do
  begin
    if IsStart(ANames[LIndex], LKind) then
      Dec(LOpen[LKind])
    else if IsEnd(ANames[LIndex], LKind) then
      Inc(LOpen[LKind]);
    LFlags := 0;
    for LKind := 0 to IND_MAX - 1 do
      if LOpen[LKind] > 0 then
        LFlags := LFlags or (Cardinal(1) shl LKind);
    Result[LIndex] := LFlags;
  end;
end;

end.
