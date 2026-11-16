{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the floor specials of the scripts                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Floor_* and FloorAndCeiling_* functions of the scripts (PS_Floor_* and  }
{  PS_FloorAndCeiling_* of psi_map.pas).                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Floors;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>The floors (and the floor with the ceiling) that a script can start</summary>
  TScriptFloorSpecials = class(TScriptSectorSpecialsBase)
  strict private
    function Start(const AKind: TScriptFloorKind; const ATag, ASpeed, AThird: Integer): Boolean;
    function StartFour(const AKind: TScriptFloorKind; const ATag, ASpeed, AThird, AFourth: Integer): Boolean;
    function StartWithValue(const AKind: TScriptFloorKind; const ATag, ASpeed, AHeight,
      ANegative: Integer): Boolean;
  public
    function FloorAndCeilingLowerByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
    /// <summary>The floor goes to the lowest, the ceiling to the highest: true if one of the two started</summary>
    function FloorAndCeilingLowerRaise(const ATag, AFloorSpeed, ACeilingSpeed: Integer): Boolean;
    function FloorAndCeilingRaiseByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
    function CrushStop(const ATag: Integer): Boolean;
    function LowerByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
    function LowerByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
    function LowerToHighest(const ATag, ASpeed, AAdjust: Integer): Boolean;
    function LowerToLowestCeiling(const ATag, ASpeed: Integer): Boolean;
    function LowerToLowest(const ATag, ASpeed: Integer): Boolean;
    function LowerToNearest(const ATag, ASpeed: Integer): Boolean;
    /// <summary>The height is a 16 bit value</summary>
    function MoveToValue(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
    function MoveToValueTimes8(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
    function RaiseAndCrushDoom(const ATag, ASpeed, ACrush: Integer): Boolean;
    function RaiseAndCrush(const ATag, ASpeed, ACrush: Integer): Boolean;
    function RaiseByTexture(const ATag, ASpeed: Integer): Boolean;
    function RaiseByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
    function RaiseByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
    function RaiseInstant(const ATag, ASpeed, AHeight: Integer): Boolean;
    function LowerInstant(const ATag, ASpeed, AHeight: Integer): Boolean;
    function RaiseToCeilingNoChange(const ATag, ASpeed, ACrush, AGap: Integer): Boolean;
    function RaiseToHighest(const ATag, ASpeed: Integer): Boolean;
    function RaiseToLowestCeiling(const ATag, ASpeed: Integer): Boolean;
    function RaiseToNearest(const ATag, ASpeed: Integer): Boolean;
    function ToCeilingInstantNoChange(const ATag, ACrush, AGap: Integer): Boolean;
    function Waggle(const ATag, AAmplitude, AFrequency, AOffset, ATime: Integer): Boolean;
  end;

implementation

{ TScriptFloorSpecials }

function TScriptFloorSpecials.Start(const AKind: TScriptFloorKind; const ATag, ASpeed,
  AThird: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AThird);
  Result := Specials.DoFloor(LArguments, AKind);
end;

function TScriptFloorSpecials.StartFour(const AKind: TScriptFloorKind; const ATag, ASpeed, AThird,
  AFourth: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AThird);
  SetByte(LArguments, 3, AFourth);
  Result := Specials.DoFloor(LArguments, AKind);
end;

function TScriptFloorSpecials.StartWithValue(const AKind: TScriptFloorKind; const ATag, ASpeed,
  AHeight, ANegative: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetSmallInt(LArguments, 2, AHeight);
  SetByte(LArguments, 4, ANegative);
  Result := Specials.DoFloor(LArguments, AKind);
end;

function TScriptFloorSpecials.FloorAndCeilingLowerByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AHeight);
  Result := Specials.DoFloorAndCeiling(LArguments, False);
end;

function TScriptFloorSpecials.FloorAndCeilingLowerRaise(const ATag, AFloorSpeed,
  ACeilingSpeed: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
  LFloor: Boolean;
  LCeiling: Boolean;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, AFloorSpeed);
  LFloor := Specials.DoFloor(LArguments, sfkLowerFloorToLowest);
  SetByte(LArguments, 1, ACeilingSpeed);
  LCeiling := Specials.DoCeiling(LArguments, sckRaiseToHighest);
  Result := LFloor or LCeiling;
end;

function TScriptFloorSpecials.FloorAndCeilingRaiseByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AHeight);
  Result := Specials.DoFloorAndCeiling(LArguments, True);
end;

function TScriptFloorSpecials.CrushStop(const ATag: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  Result := Specials.FloorCrushStop(LArguments);
end;

function TScriptFloorSpecials.LowerByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sfkLowerFloorByValue, ATag, ASpeed, AHeight);
end;

function TScriptFloorSpecials.LowerByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sfkLowerByValueTimes8, ATag, ASpeed, AHeight);
end;

function TScriptFloorSpecials.LowerToHighest(const ATag, ASpeed, AAdjust: Integer): Boolean;
begin
  Result := Start(sfkLowerFloorToHighest, ATag, ASpeed, AAdjust);
end;

function TScriptFloorSpecials.LowerToLowestCeiling(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkLowerFloorToLowestCeiling, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.LowerToLowest(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkLowerFloorToLowest, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.LowerToNearest(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkLowerFloor, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.MoveToValue(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
begin
  Result := StartWithValue(sfkMoveToValue, ATag, ASpeed, AHeight, ANegative);
end;

function TScriptFloorSpecials.MoveToValueTimes8(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
begin
  Result := StartFour(sfkMoveToValueTimes8, ATag, ASpeed, AHeight, ANegative);
end;

function TScriptFloorSpecials.RaiseAndCrushDoom(const ATag, ASpeed, ACrush: Integer): Boolean;
begin
  Result := Start(sfkRaiseFloorCrushDoom, ATag, ASpeed, ACrush);
end;

function TScriptFloorSpecials.RaiseAndCrush(const ATag, ASpeed, ACrush: Integer): Boolean;
begin
  Result := Start(sfkRaiseFloorCrush, ATag, ASpeed, ACrush);
end;

function TScriptFloorSpecials.RaiseByTexture(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkRaiseToTexture, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.RaiseByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sfkRaiseFloorByValue, ATag, ASpeed, AHeight);
end;

function TScriptFloorSpecials.RaiseByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sfkRaiseFloorByValueTimes8, ATag, ASpeed, AHeight);
end;

function TScriptFloorSpecials.RaiseInstant(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sfkRaiseTimes8Instant, ATag, ASpeed, AHeight);
end;

function TScriptFloorSpecials.LowerInstant(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sfkLowerTimes8Instant, ATag, ASpeed, AHeight);
end;

function TScriptFloorSpecials.RaiseToCeilingNoChange(const ATag, ASpeed, ACrush, AGap: Integer): Boolean;
begin
  Result := StartFour(sfkRaiseToCeiling, ATag, ASpeed, ACrush, AGap);
end;

function TScriptFloorSpecials.RaiseToHighest(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkRaiseFloor, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.RaiseToLowestCeiling(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkRaiseToLowestCeiling, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.RaiseToNearest(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sfkRaiseFloorToNearest, ATag, ASpeed, 0);
end;

function TScriptFloorSpecials.ToCeilingInstantNoChange(const ATag, ACrush, AGap: Integer): Boolean;
begin
  // the speed is not a parameter of the script function: the byte 1 stays 0
  Result := StartFour(sfkFloorToCeilingInstant, ATag, 0, ACrush, AGap);
end;

function TScriptFloorSpecials.Waggle(const ATag, AAmplitude, AFrequency, AOffset, ATime: Integer): Boolean;
begin
  Result := Specials.StartFloorWaggle(ATag, AAmplitude, AFrequency, AOffset, ATime);
end;

end.
