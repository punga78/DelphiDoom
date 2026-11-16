{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the gateway to the specials of the sectors        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The classes of the specials of the scripts know nothing of sectors, lines   }
{  and thinkers: they build the arguments and ask this gateway, which the      }
{  engine implements with the EVH_* and PO_* procedures of the map.            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Intf;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>
  ///   Starts the specials of the map for a script. Every function gives back what the special of
  ///   the engine gives back (true if something was started). The arguments are var because the
  ///   engine may read them again: the same buffer is passed to two specials in a row by
  ///   PS_FloorAndCeiling_LowerRaise
  /// </summary>
  IScriptSectorSpecials = interface
    ['{5E2B8D14-93A7-4C60-B1F8-0D47A6C3E952}']
    function DoCeiling(var AArguments: TScriptSpecialArguments; const AKind: TScriptCeilingKind): Boolean;
    function CeilingCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
    function DoDoor(var AArguments: TScriptSpecialArguments; const AKind: TScriptDoorKind): Boolean;
    function DoFloor(var AArguments: TScriptSpecialArguments; const AKind: TScriptFloorKind): Boolean;
    function DoFloorAndCeiling(var AArguments: TScriptSpecialArguments; const ARaise: Boolean): Boolean;
    function FloorCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
    function StartFloorWaggle(const ATag, AAmplitude, AFrequency, AOffset, ATime: Integer): Boolean;
    function SpawnLight(var AArguments: TScriptSpecialArguments; const AKind: TScriptLightKind): Boolean;
    /// <summary>Starts a flash of lightning (Hexen)</summary>
    procedure ForceLightning(const ATics: Integer);
    function BuildPillar(var AArguments: TScriptSpecialArguments; const ACrush: Boolean): Boolean;
    function OpenPillar(var AArguments: TScriptSpecialArguments): Boolean;
    function DoPlat(var AArguments: TScriptSpecialArguments; const AKind: TScriptPlatKind): Boolean;
    function OpenPolyDoor(var AArguments: TScriptSpecialArguments; const AKind: TScriptPolyDoorKind): Boolean;
    function MovePoly(var AArguments: TScriptSpecialArguments; const ATimesEight, AOverride: Boolean): Boolean;
    function RotatePoly(var AArguments: TScriptSpecialArguments; const ADirection: Integer;
      const AOverride: Boolean): Boolean;
  end;

implementation

end.
