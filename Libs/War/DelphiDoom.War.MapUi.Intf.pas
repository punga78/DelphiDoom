{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contract between the game of the scenes and the   }
{  maker of the maps                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Intf;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.MapUi.Types;

type
  /// <summary>
  ///   The sounds of the map as far as the model of the game is concerned: the audio of the original is a list of entities
  ///   (wa_createAudio) that take an id and a place of the pool, and the choice of a sound among several draws a number
  ///   from the generator of the game; both matter to everything that comes after, so they are done even if nothing plays
  /// </summary>
  IWarMapAudio = interface
    ['{E94B2A60-1D87-4F3C-B5A9-80C2D7E41F36}']
    /// <summary>wa_createAudio: the entity of a sound</summary>
    procedure PlaySound(AAudioId: Integer);
    /// <summary>wa_createAudioRandom: one of the sounds from the first to the last, drawn</summary>
    procedure PlayRandomSound(AFromId, AToId: Integer);
    /// <summary>wa_playAcknowledgementSound: the units answer (not twice within 150 ms)</summary>
    procedure Acknowledge(APlayer: Integer);
    /// <summary>wa_playDudeSelectionSound for the unit of the slot</summary>
    procedure DudeSelected(ASlot: Integer);
    /// <summary>wa_playBuildingSelectionSound for the building of the slot</summary>
    procedure BuildingSelected(ASlot: Integer);
  end;

  /// <summary>
  ///   What the menus of the map ask of the scene when a button leaves the map (war_map_menu.c): the other scene or map that
  ///   comes next, always after a second of black (wg_setNextScene and wg_setNextMap with a delay of 1)
  /// </summary>
  IWarMapMenuHost = interface
    ['{5B8E2F71-C3A4-4D06-9E18-7A4D0C26B953}']
    /// <summary>wmm_handleRestartRestart: the same map from the start</summary>
    procedure RestartMap;
    /// <summary>wmm_handleGameOverContinue: the next briefing, the same briefing again or the main menu</summary>
    procedure ContinueAfterGameOver;
    /// <summary>wmm_handleQuitMenu and wmm_handleDemoEndMenu: the main menu</summary>
    procedure ReturnToMainMenu;
    /// <summary>wmm_handleQuitQuit: the game ends</summary>
    procedure QuitGame;
  end;

  /// <summary>
  ///   What the cheats that need the map ask of it (war_cheats.c: the ones that end the map, change the fog, send the player to
  ///   another map or choose what a click on the map does). The gold, the spells, the upgrades, the god mode and the speed
  ///   are the model's and the cheats reach them themselves
  /// </summary>
  IWarMapCheatTarget = interface
    ['{2F61A8D9-4C73-4E05-9B1A-6D3E70C85F42}']
    /// <summary>map->result = WAR_LEVEL_RESULT_WIN or LOSE: the map ends in the same update</summary>
    procedure ConcludeMap(AResult: TWarLevelResult);
    /// <summary>The end cheat: the map stops and the menu of the end of the demo opens</summary>
    procedure ShowDemoEnd;
    /// <summary>map->fowEnabled = !map->fowEnabled</summary>
    procedure ToggleFog;
    /// <summary>The skip cheats: the briefing of a map of the campaign after a second</summary>
    procedure SkipToBriefing(ARace: TWarRace; AMapType: Integer);
    /// <summary>map->editing.mode and pendingUnitType</summary>
    procedure SetEditing(AMode: TWarMapEditMode; AUnitType: Integer);
    function GetEditMode: TWarMapEditMode;
  end;

  /// <summary>
  ///   What a maker of maps (an IWarMapLauncher) that draws with the interface of the game implements besides: the game
  ///   gives it the services (the input, the canvas, the immediate interface, the sprites) once it has made them, because the
  ///   map is made after them and needs them
  /// </summary>
  IWarMapServicesTarget = interface
    ['{C3E81F4A-7B25-4D90-A6E1-092D5B73F8A1}']
    procedure AttachServices(const AServices: TWarSceneServices);
  end;

  /// <summary>
  ///   What the Save and Load buttons of the menus of the map ask of the scene (the original has no handler for them).
  ///   Optional on a host of the menus, asked for with Supports: a host that does not have it leaves the buttons as the
  ///   original has them
  /// </summary>
  IWarMapMenuSessions = interface
    ['{D8B3F162-4E79-4A0D-9C85-61A7E2F40B93}']
    procedure SaveGame;
    procedure LoadGame;
  end;

implementation

end.
