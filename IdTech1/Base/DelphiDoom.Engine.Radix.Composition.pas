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
  DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Dehacked.ThingFields, DelphiDoom.MathCore.Intf;

/// <summary>
///   The part of the composition root that only the Radix game has: ComposeEngine calls it (under
///   the define RADIX) where the WAD services are given to w_wad.pas. It builds the converter of
///   RADIX.DAT, which also tells the release of the file, and the table of the names of RADIX.DAT,
///   and the readers of the lump RMAP and of the binary lumps of Radix of the levels, and gives
///   them to the historical units (W_ConfigureConverter, W_ConfigureAliases, RX_ConfigureVersion,
///   RX_ConfigureMapInfo, RX_ConfigureLevelLogic)
/// </summary>
/// <param name="AThingFields">
///   The place that the parser of DEHACKED asks for the fields of the things it does not know: it
///   gets the table of the Radix part of the actors
/// </param>
/// <param name="ARandom">The random numbers of the game: a saved game of Radix keeps where they are</param>
procedure ComposeRadix(const ALog: ILog; const ALumps: IEngineLumps;
  const AThingFields: IEngineDehackedThingFields; const ARandom: IGameRandom);

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
  DelphiDoom.Radix.ActorProperties, DelphiDoom.Dehacked.Intf, DelphiDoom.Engine.Parity.PilotCommand,
  w_wad, st_stuff, wi_stuff, radix_version, radix_map_extra, radix_hud, radix_pickups, radix_logic,
  radix_intermission, radix_controls, radix_saveg, radix_menu, radix_finale, radix_wipe, m_menu, f_finale, f_wipe, g_game,
  DelphiDoom.Radix.Editions;

var
  // The one table of the Radix part of the actors: ComposeActorDef asks for it first (the parser of
  // ACTORDEF fills it), ComposeRadix then gives it to the parser of DEHACKED. Only this part of the
  // composition root sees it
  radix_actor_properties: IActorDefExtraProperties = nil;

function ComposeRadixActorProperties(const ALog: ILog): IActorDefExtraProperties;
var
  LProperties: TRadixActorProperties;
begin
  if not Assigned(radix_actor_properties) then
  begin
    LProperties := TRadixActorProperties.Create(ALog);
    radix_actor_properties := LProperties;
    RX_ConfigureActors(LProperties);
  end;
  Result := radix_actor_properties;
end;

const
  ACTOR_DEFINITIONS_RESOURCE = 'RADIXDEF';
  END_SCREEN_RESOURCE = 'RADIXEND%d';

// A resource linked into the program (IdTech1\Radix\Radix32_Data.rc); nothing for a program without the
// resource (a test, a tool)
function LoadDataResource(const AName: string): TBytes;
var
  LStream: TResourceStream;
begin
  Result := nil;
  if FindResource(HInstance, PChar(AName), RT_RCDATA) = 0 then
    Exit;
  LStream := TResourceStream.Create(HInstance, AName, RT_RCDATA);
  try
    SetLength(Result, LStream.Size);
    if Length(Result) > 0 then
      LStream.ReadBuffer(Result[0], Length(Result));
  finally
    LStream.Free;
  end;
end;

procedure ComposeRadix(const ALog: ILog; const ALumps: IEngineLumps;
  const AThingFields: IEngineDehackedThingFields; const ARandom: IGameRandom);
var
  LConverter: IEngineWadConverter;
  LAliases: IEngineLumpAliases;
begin
  LConverter := TEngineRadixDataConverter.Create(ALog, LoadDataResource(ACTOR_DEFINITIONS_RESOURCE),
    function(AEdition: TRadixEdition): TBytes
    begin
      // a file that the table does not know leaves as the 1.0 shareware, as in Rad-X
      if AEdition = reUnknown then
        AEdition := reV10Shareware;
      Result := LoadDataResource(Format(END_SCREEN_RESOURCE, [Ord(AEdition)]));
    end);
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
  TIntermissionRoutines.WI_ConfigureReplacement(RX_Intermission_Start, RX_Intermission_Ticker, RX_Intermission_Drawer);
  // the end of an episode: the text of RADIX.DAT over the flight among the stars
  TFinaleRoutines.F_ConfigureReplacement(RX_Finale_Start, RX_Finale_Ticker, RX_Finale_Drawer);
  // the screens fade into one another (the engine of Doom melts them)
  wipe_ConfigureCustom(RX_WipeFade);
  // the look of the menus of Rad-X, the name of the pilot, the top ten, the gameplay options
  M_ConfigureExtension(RX_MenuExtension);
  // the fields of Rad-X of the Thing blocks of DEHACKED (GAMEDEF has them) go to the same table
  AThingFields.Attach(ComposeRadixActorProperties(ALog) as IDehackedExtraThingFields);
  // the keys of the afterburner and of the plasma bomb
  G_ConfigureTiccmdExtension(RX_TiccmdKeys);
  // the state of Radix in a file beside each saved game of the engine
  RX_ConfigureSaveGame(ARandom);
  G_ConfigureSaveGameExtension(RX_SaveGame, RX_LoadGame);
  // the steps "save" and "load" of a script of commands
  TEngineParityPilotCommand.ConfigureSaveGames(RX_ScriptSaveGame, RX_ScriptLoadGame);
end;

end.
