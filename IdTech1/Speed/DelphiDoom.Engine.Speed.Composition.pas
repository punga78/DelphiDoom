{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - composition of the Speed Haste game                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Speed.Composition;

interface

uses
  DelphiDoom.Logging.Intf;

/// <summary>
///   The part of the composition root that only Speed Haste has: ComposeEngine calls it (under the
///   define SPEED) where the WAD services are given to w_wad.pas. It gives the historical units
///   the converter of SPEEDH.JCL, the screens of the end of the race and the display of the race
///   (W_ConfigureConverter, WI_ConfigureReplacement, ST_ConfigureReplacement)
/// </summary>
procedure ComposeSpeed(const ALog: ILog);

implementation

uses
  DelphiDoom.Engine.Speed.DataConverter,
  w_wad,
  wi_stuff,
  st_stuff,
  speed_hud,
  speed_saveg,
  speed_controls,
  speed_menu,
  m_menu,
  g_game,
  DelphiDoom.Engine.Parity.PilotCommand,
  speed_intermission;

procedure ComposeSpeed(const ALog: ILog);
begin
  W_ConfigureConverter(TEngineSpeedDataConverter.Create(ALog));
  // the gauge, the lap, the position and the time of the race in the place of the status bar of Doom
  TStatusBarRoutines.ST_ConfigureReplacement(SH_HudDrawer);
  // the menu of the new race (course, car, laps, transmission, kind of game, skill)
  TMenuRoutines.M_ConfigureExtension(SH_MenuExtension);
  // the gear keys in the ticcmd (the transmission is manual with -manual or speed_transmission 1)
  G_ConfigureTiccmdExtension(SH_TiccmdKeys);
  // the state of the race in a file beside each saved game of the engine
  G_ConfigureSaveGameExtension(SH_SaveGame, SH_LoadGame);
  // the steps "save" and "load" of a script of commands
  TEngineParityPilotCommand.ConfigureSaveGames(SH_ScriptSaveGame, SH_ScriptLoadGame);
  // the result of the race and the tables of the records in the place of the intermission of Doom
  TIntermissionRoutines.WI_ConfigureReplacement(SH_Intermission_Start, SH_Intermission_Ticker, SH_Intermission_Drawer);
end;

end.
