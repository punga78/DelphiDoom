{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the ceiling specials of the scripts               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Ceiling_* functions of the scripts (PS_Ceiling_* of psi_map.pas).       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Ceilings;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>The ceilings that a script can start</summary>
  TScriptCeilingSpecials = class(TScriptSectorSpecialsBase)
  strict private
    function Start(const AKind: TScriptCeilingKind; const ATag, ASpeed, AThird: Integer): Boolean;
    function StartWithValue(const AKind: TScriptCeilingKind; const ATag, ASpeed, AHeight,
      AFlag: Integer): Boolean;
    function StartTimes8(const AKind: TScriptCeilingKind; const ATag, ASpeed, AHeight,
      ANegative: Integer): Boolean;
  public
    /// <summary>Action 42</summary>
    function CrushAndRaise(const ATag, ASpeed, ACrush: Integer): Boolean;
    /// <summary>Action 45</summary>
    function CrushRaiseAndStay(const ATag, ASpeed, ACrush: Integer): Boolean;
    /// <summary>Action 44</summary>
    function CrushStop(const ATag: Integer): Boolean;
    /// <summary>Action 43</summary>
    function LowerAndCrush(const ATag, ASpeed, ACrush: Integer): Boolean;
    /// <summary>Action 40</summary>
    function LowerByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
    /// <summary>Action 199 (ZDoom)</summary>
    function LowerByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
    /// <summary>Action 254 (ZDoom)</summary>
    function LowerToFloor(const ATag, ASpeed: Integer): Boolean;
    /// <summary>Action 192 (ZDoom)</summary>
    function LowerToHighestFloor(const ATag, ASpeed: Integer): Boolean;
    /// <summary>Action 253 (ZDoom)</summary>
    function LowerToLowest(const ATag, ASpeed: Integer): Boolean;
    /// <summary>Action 280 (ZDoom); the height is a 16 bit value</summary>
    function MoveToValueAndCrush(const ATag, ASpeed, AHeight, ACrush: Integer): Boolean;
    /// <summary>Action 47 (ZDoom); the height is a 16 bit value</summary>
    function MoveToValue(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
    /// <summary>Action 69</summary>
    function MoveToValueTimes8(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
    /// <summary>Action 41</summary>
    function RaiseByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
    /// <summary>Action 198 (ZDoom)</summary>
    function RaiseByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
    /// <summary>Action 266 (ZDoom)</summary>
    function RaiseToHighestFloor(const ATag, ASpeed: Integer): Boolean;
  end;

implementation

{ TScriptCeilingSpecials }

// tag, speed and a third value in the bytes 0..2 (the callers without a third value pass 0, which
// is what the cleared buffer holds)
function TScriptCeilingSpecials.Start(const AKind: TScriptCeilingKind; const ATag, ASpeed,
  AThird: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AThird);
  Result := Specials.DoCeiling(LArguments, AKind);
end;

function TScriptCeilingSpecials.StartWithValue(const AKind: TScriptCeilingKind; const ATag, ASpeed,
  AHeight, AFlag: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetSmallInt(LArguments, 2, AHeight);
  SetByte(LArguments, 4, AFlag);
  Result := Specials.DoCeiling(LArguments, AKind);
end;

function TScriptCeilingSpecials.StartTimes8(const AKind: TScriptCeilingKind; const ATag, ASpeed,
  AHeight, ANegative: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AHeight);
  SetByte(LArguments, 3, ANegative);
  Result := Specials.DoCeiling(LArguments, AKind);
end;

function TScriptCeilingSpecials.CrushAndRaise(const ATag, ASpeed, ACrush: Integer): Boolean;
begin
  Result := Start(sckCrushAndRaise, ATag, ASpeed, ACrush);
end;

function TScriptCeilingSpecials.CrushRaiseAndStay(const ATag, ASpeed, ACrush: Integer): Boolean;
begin
  Result := Start(sckCrushRaiseAndStay, ATag, ASpeed, ACrush);
end;

function TScriptCeilingSpecials.CrushStop(const ATag: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  Result := Specials.CeilingCrushStop(LArguments);
end;

function TScriptCeilingSpecials.LowerAndCrush(const ATag, ASpeed, ACrush: Integer): Boolean;
begin
  Result := Start(sckLowerAndCrush, ATag, ASpeed, ACrush);
end;

function TScriptCeilingSpecials.LowerByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sckLowerByValue, ATag, ASpeed, AHeight);
end;

function TScriptCeilingSpecials.LowerByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sckLowerByValueTimes8, ATag, ASpeed, AHeight);
end;

function TScriptCeilingSpecials.LowerToFloor(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sckLowerToFloor, ATag, ASpeed, 0);
end;

function TScriptCeilingSpecials.LowerToHighestFloor(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sckLowerToMaxFloor, ATag, ASpeed, 0);
end;

function TScriptCeilingSpecials.LowerToLowest(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sckLowerToLowest, ATag, ASpeed, 0);
end;

function TScriptCeilingSpecials.MoveToValueAndCrush(const ATag, ASpeed, AHeight, ACrush: Integer): Boolean;
begin
  Result := StartWithValue(sckMoveToValueAndCrush, ATag, ASpeed, AHeight, ACrush);
end;

function TScriptCeilingSpecials.MoveToValue(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
begin
  Result := StartWithValue(sckMoveToValue, ATag, ASpeed, AHeight, ANegative);
end;

function TScriptCeilingSpecials.MoveToValueTimes8(const ATag, ASpeed, AHeight, ANegative: Integer): Boolean;
begin
  Result := StartTimes8(sckMoveToValueTimes8, ATag, ASpeed, AHeight, ANegative);
end;

function TScriptCeilingSpecials.RaiseByValue(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sckRaiseByValue, ATag, ASpeed, AHeight);
end;

function TScriptCeilingSpecials.RaiseByValueTimes8(const ATag, ASpeed, AHeight: Integer): Boolean;
begin
  Result := Start(sckRaiseByValueTimes8, ATag, ASpeed, AHeight);
end;

function TScriptCeilingSpecials.RaiseToHighestFloor(const ATag, ASpeed: Integer): Boolean;
begin
  Result := Start(sckRaiseToHighestFloor, ATag, ASpeed, 0);
end;

end.
