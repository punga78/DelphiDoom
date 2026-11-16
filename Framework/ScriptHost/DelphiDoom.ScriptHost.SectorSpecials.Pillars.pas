{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the pillar specials of the scripts                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Pillar_* functions of the scripts (PS_Pillar_* of psi_map.pas).         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Pillars;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base;

type
  /// <summary>The pillars that a script can build or open</summary>
  TScriptPillarSpecials = class(TScriptSectorSpecialsBase)
  public
    function BuildAndCrush(const ATag, ASpeed, AHeight: Integer): Boolean;
    function Build(const ATag, ASpeed, AHeight: Integer): Boolean;
    function Open(const ATag, ASpeed, AFloorDistance, ACeilingDistance: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.ScriptHost.SectorSpecials.Types;

{ TScriptPillarSpecials }

function TScriptPillarSpecials.BuildAndCrush(const ATag, ASpeed, AHeight: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AHeight);
  Result := Specials.BuildPillar(LArguments, True);
end;

function TScriptPillarSpecials.Build(const ATag, ASpeed, AHeight: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AHeight);
  Result := Specials.BuildPillar(LArguments, False);
end;

function TScriptPillarSpecials.Open(const ATag, ASpeed, AFloorDistance, ACeilingDistance: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, AFloorDistance);
  SetByte(LArguments, 3, ACeilingDistance);
  Result := Specials.OpenPillar(LArguments);
end;

end.
