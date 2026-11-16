{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the bodies of the specials of the sectors         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Ceilings,
  DelphiDoom.ScriptHost.SectorSpecials.Doors,
  DelphiDoom.ScriptHost.SectorSpecials.Floors,
  DelphiDoom.ScriptHost.SectorSpecials.Lights,
  DelphiDoom.ScriptHost.SectorSpecials.Pillars,
  DelphiDoom.ScriptHost.SectorSpecials.Plats,
  DelphiDoom.ScriptHost.SectorSpecials.Polyobjects;

type
  /// <summary>
  ///   What the PS_* routines of psi_map.pas forward to: the seven classes of the specials of
  ///   the sectors. The objects belong to the one that implements the interface and live as long
  ///   as it does
  /// </summary>
  IScriptSectorSpecialFunctions = interface
    ['{B7A31E60-4D95-4F28-8C1B-62E0D9A57F34}']
    function Doors: TScriptDoorSpecials;
    function Ceilings: TScriptCeilingSpecials;
    function Floors: TScriptFloorSpecials;
    function Lights: TScriptLightSpecials;
    function Plats: TScriptPlatSpecials;
    function Pillars: TScriptPillarSpecials;
    function Polyobjects: TScriptPolyobjectSpecials;
  end;

implementation

end.
