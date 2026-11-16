{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the polyobject specials of the scripts            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Polyobj_* functions of the scripts (PS_Polyobj_* of psi_map.pas); the   }
{  ones with OR in the name are the "override" variants of the engine.         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Polyobjects;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base;

type
  /// <summary>The polyobjects that a script can move, rotate or open</summary>
  TScriptPolyobjectSpecials = class(TScriptSectorSpecialsBase)
  strict private
    function Move(const APolyobject, ASpeed, AAngle, ADistance: Integer; const ATimesEight,
      AOverride: Boolean): Boolean;
    function Rotate(const APolyobject, ASpeed, AAngle, ADirection: Integer;
      const AOverride: Boolean): Boolean;
  public
    function DoorSlide(const APolyobject, ASpeed, AAngle, ADistance, ADelay: Integer): Boolean;
    /// <summary>A negative speed swings the door the other way</summary>
    function DoorSwing(const APolyobject, ASpeed, AAngle, ADelay: Integer): Boolean;
    function MoveBy(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
    function MoveTimes8(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
    function MoveOverride(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
    function MoveTimes8Override(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
    function RotateLeftOverride(const APolyobject, ASpeed, AAngle: Integer): Boolean;
    function RotateRightOverride(const APolyobject, ASpeed, AAngle: Integer): Boolean;
    function RotateLeft(const APolyobject, ASpeed, AAngle: Integer): Boolean;
    function RotateRight(const APolyobject, ASpeed, AAngle: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.ScriptHost.SectorSpecials.Types;

{ TScriptPolyobjectSpecials }

function TScriptPolyobjectSpecials.Move(const APolyobject, ASpeed, AAngle, ADistance: Integer;
  const ATimesEight, AOverride: Boolean): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, APolyobject);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AAngle);
  SetByte(LArguments, 3, ADistance);
  Result := Specials.MovePoly(LArguments, ATimesEight, AOverride);
end;

function TScriptPolyobjectSpecials.Rotate(const APolyobject, ASpeed, AAngle, ADirection: Integer;
  const AOverride: Boolean): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, APolyobject);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AAngle);
  Result := Specials.RotatePoly(LArguments, ADirection, AOverride);
end;

function TScriptPolyobjectSpecials.DoorSlide(const APolyobject, ASpeed, AAngle, ADistance,
  ADelay: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, APolyobject);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AAngle);
  SetByte(LArguments, 3, ADistance);
  SetByte(LArguments, 4, ADelay);
  Result := Specials.OpenPolyDoor(LArguments, spdSlide);
end;

function TScriptPolyobjectSpecials.DoorSwing(const APolyobject, ASpeed, AAngle, ADelay: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, APolyobject);
  SetByte(LArguments, 1, Abs(ASpeed));
  SetByte(LArguments, 2, AAngle);
  SetByte(LArguments, 3, ADelay);
  if ASpeed < 0 then
    SetByte(LArguments, 4, 1);
  Result := Specials.OpenPolyDoor(LArguments, spdSwing);
end;

function TScriptPolyobjectSpecials.MoveBy(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
begin
  Result := Move(APolyobject, ASpeed, AAngle, ADistance, False, False);
end;

function TScriptPolyobjectSpecials.MoveTimes8(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
begin
  Result := Move(APolyobject, ASpeed, AAngle, ADistance, True, False);
end;

function TScriptPolyobjectSpecials.MoveOverride(const APolyobject, ASpeed, AAngle, ADistance: Integer): Boolean;
begin
  Result := Move(APolyobject, ASpeed, AAngle, ADistance, False, True);
end;

function TScriptPolyobjectSpecials.MoveTimes8Override(const APolyobject, ASpeed, AAngle,
  ADistance: Integer): Boolean;
begin
  Result := Move(APolyobject, ASpeed, AAngle, ADistance, True, True);
end;

function TScriptPolyobjectSpecials.RotateLeftOverride(const APolyobject, ASpeed, AAngle: Integer): Boolean;
begin
  Result := Rotate(APolyobject, ASpeed, AAngle, 1, True);
end;

function TScriptPolyobjectSpecials.RotateRightOverride(const APolyobject, ASpeed, AAngle: Integer): Boolean;
begin
  Result := Rotate(APolyobject, ASpeed, AAngle, -1, True);
end;

function TScriptPolyobjectSpecials.RotateLeft(const APolyobject, ASpeed, AAngle: Integer): Boolean;
begin
  Result := Rotate(APolyobject, ASpeed, AAngle, 1, False);
end;

function TScriptPolyobjectSpecials.RotateRight(const APolyobject, ASpeed, AAngle: Integer): Boolean;
begin
  Result := Rotate(APolyobject, ASpeed, AAngle, -1, False);
end;

end.
