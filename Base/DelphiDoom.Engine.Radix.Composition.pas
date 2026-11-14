{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - composition of the Radix game                          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Radix.Composition;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.Engine.Wad.Lumps.Intf;

/// <summary>
///   The part of the composition root that only the Radix game has: ComposeEngine calls it (under
///   the define RADIX) where the WAD services are given to w_wad.pas. It builds the converter of
///   RADIX.DAT, which also tells the release of the file, and the table of the names of RADIX.DAT,
///   and the readers of the lump RMAP and of the binary lumps of Radix of the levels, and gives
///   them to the historical units (W_ConfigureConverter, W_ConfigureAliases, RX_ConfigureVersion,
///   RX_ConfigureMapInfo, RX_ConfigureLevelLogic)
/// </summary>
procedure ComposeRadix(const ALog: ILog; const ALumps: IEngineLumps);

/// <summary>
///   The reader of the properties of the actors that only Radix has, for the profile of the
///   parser of ACTORDEF (ComposeActorDef). What it reads is the table of radix_pickups
///   (RX_ConfigureActors)
/// </summary>
function ComposeRadixActorProperties(const ALog: ILog): IActorDefExtraProperties;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory,
  DelphiDoom.Engine.Wad.Converter.Intf, DelphiDoom.Engine.Wad.Aliases.Intf,
  DelphiDoom.Engine.Radix.Edition.Intf, DelphiDoom.Engine.Radix.DataConverter,
  DelphiDoom.Engine.Radix.LumpAliases,
  DelphiDoom.Radix.ActorProperties,
  w_wad, st_stuff, wi_stuff, radix_version, radix_map_extra, radix_hud, radix_pickups, radix_logic,
  radix_intermission, radix_controls, g_game;

function ComposeRadixActorProperties(const ALog: ILog): IActorDefExtraProperties;
var
  LProperties: TRadixActorProperties;
begin
  LProperties := TRadixActorProperties.Create(ALog);
  Result := LProperties;
  RX_ConfigureActors(LProperties);
end;

const
  ACTOR_DEFINITIONS_RESOURCE = 'RADIXDEF';

// The ACTORDEF text of the actors of Radix, linked into the program (Radix\Radix32_Data.rc);
// nothing for a program without the resource (a test, a tool)
function LoadActorDefinitions: TBytes;
var
  LStream: TResourceStream;
begin
  Result := nil;
  if FindResource(HInstance, ACTOR_DEFINITIONS_RESOURCE, RT_RCDATA) = 0 then
    Exit;
  LStream := TResourceStream.Create(HInstance, ACTOR_DEFINITIONS_RESOURCE, RT_RCDATA);
  try
    SetLength(Result, LStream.Size);
    if Length(Result) > 0 then
      LStream.ReadBuffer(Result[0], Length(Result));
  finally
    LStream.Free;
  end;
end;

procedure ComposeRadix(const ALog: ILog; const ALumps: IEngineLumps);
var
  LConverter: IEngineWadConverter;
  LAliases: IEngineLumpAliases;
begin
  LConverter := TEngineRadixDataConverter.Create(ALog, LoadActorDefinitions);
  W_ConfigureConverter(LConverter);
  RX_ConfigureVersion(LConverter as IEngineRadixEdition);

  LAliases := TEngineRadixLumpAliases.Create(ALumps,
    function: IRadixLumpAliases
    begin
      Result := TRadixFactory.CreateLumpAliases;
    end);
  W_ConfigureAliases(LAliases);

  RX_ConfigureMapInfo(TRadixFactory.CreateMapInfoReader);
  RX_ConfigureLevelLogic(TRadixFactory.CreateLevelLumpReader);

  // the cockpit of the craft in the place of the status bar of Doom
  ST_ConfigureReplacement(RX_HudDrawer);
  // the debriefing in the place of the intermission of Doom (RADIX.DAT has none of its pictures)
  WI_ConfigureReplacement(RX_Intermission_Start, RX_Intermission_Ticker, RX_Intermission_Drawer);
  // the keys of the afterburner and of the plasma bomb
  G_ConfigureTiccmdExtension(RX_TiccmdKeys);
end;

end.
