{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the door specials of the scripts                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Door_* functions of the scripts (PS_Door_* of psi_map.pas).             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Doors;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base;

type
  /// <summary>The doors that a script can start</summary>
  TScriptDoorSpecials = class(TScriptSectorSpecialsBase)
  public
    /// <summary>Action 10</summary>
    function Close(const ATag, ASpeed: Integer): Boolean;
    /// <summary>Action 249 (ZDoom)</summary>
    function CloseWaitOpen(const ATag, ASpeed, ADelay: Integer): Boolean;
    /// <summary>Action 11</summary>
    function Open(const ATag, ASpeed: Integer): Boolean;
    /// <summary>Door_Raise: opens, waits and closes</summary>
    function RaiseDoor(const ATag, ASpeed, ADelay: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.ScriptHost.SectorSpecials.Types;

{ TScriptDoorSpecials }

function TScriptDoorSpecials.Close(const ATag, ASpeed: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  Result := Specials.DoDoor(LArguments, sdkClose);
end;

function TScriptDoorSpecials.CloseWaitOpen(const ATag, ASpeed, ADelay: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, ADelay);
  Result := Specials.DoDoor(LArguments, sdkCloseWaitThenOpen);
end;

function TScriptDoorSpecials.Open(const ATag, ASpeed: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  Result := Specials.DoDoor(LArguments, sdkOpen);
end;

function TScriptDoorSpecials.RaiseDoor(const ATag, ASpeed, ADelay: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, ADelay);
  Result := Specials.DoDoor(LArguments, sdkNormal);
end;

end.
