{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts of the interface and the scenes         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_imui.h, war_scenes.h, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an   }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Ui.Types;

type
  IWarScene = interface;

  /// <summary>The input the game reads (WarInput): what is held and what changed in this frame, and the mouse</summary>
  IWarUiInput = interface
    ['{3E7C21A8-5B04-4D69-9F13-A0C84E6D27B1}']
    function IsButtonHeld(AButton: TWarMouseButton): Boolean;
    function IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
    function IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
    function IsKeyHeld(AKey: TWarKey): Boolean;
    function IsKeyJustPressed(AKey: TWarKey): Boolean;
    function IsKeyJustReleased(AKey: TWarKey): Boolean;
    function GetPositionX: Single;
    function GetPositionY: Single;
    property PositionX: Single read GetPositionX;
    property PositionY: Single read GetPositionY;
  end;

  /// <summary>
  ///   A WarSprite: the size of a frame, the frames and one texture, the pixels of the frame that was put in it last
  ///   (wspr_updateSpriteImage). Counted by reference: a sprite that the cache evicts while a button still draws
  ///   with it stays alive (the C freed the texture and used it)
  /// </summary>
  IWarUiSprite = interface
    ['{9C5A07E2-1D38-4F6B-B2A4-73E80D5C1F96}']
    function GetFrameWidth: Integer;
    function GetFrameHeight: Integer;
    function GetFrameCount: Integer;
    function GetTexture: TWarImage;
    /// <summary>wspr_getSpriteFrame; EWarException if the frame is not there</summary>
    function GetFrame(AIndex: Integer): TWarSpriteFrame;
    /// <summary>wspr_updateSpriteImage: the pixels of the frame go to the texture; a frame that does not exist leaves it as it is</summary>
    procedure UpdateImage(AFrameIndex: Integer);
    property FrameWidth: Integer read GetFrameWidth;
    property FrameHeight: Integer read GetFrameHeight;
    property FrameCount: Integer read GetFrameCount;
    property Texture: TWarImage read GetTexture;
  end;

  /// <summary>Where the sprites of the interface come from (wspr_createSpriteFromResourceIndex and the hot spot of a cursor)</summary>
  IWarUiSprites = interface
    ['{62B8D4F0-A917-4E35-8C20-5F1E9B73D6A4}']
    /// <summary>A new sprite of the record (an image, a sprite or a cursor); EWarException for another type of record</summary>
    function CreateSprite(AResourceIndex: Integer): IWarUiSprite;
    /// <summary>The hot spot of a cursor record</summary>
    procedure CursorHotspot(AResourceIndex: Integer; out AX, AY: Integer);
  end;

  /// <summary>wa_createAudio of the scenes: the sound and the music they start (the audio is #198)</summary>
  IWarSceneAudio = interface
    ['{D40E6B93-7A25-4C18-95F7-2B8C3E01A5D9}']
    procedure Play(AAudioId: Integer; ALoop: Boolean);
    /// <summary>wa_removeAudiosOfType(WAR_AUDIO_MIDI): the music that plays stops</summary>
    procedure StopMusic;
  end;

  /// <summary>
  ///   What the audio does beyond IWarSceneAudio for the sounds of a map: a sound with a place on the map (pixels), and the
  ///   rectangle of the map that is on screen, which decides how loud such a sound is (audioDataCallback of the original). The
  ///   output of the original is mono: there is a volume and no pan. Apart so that an audio that has no places stays valid
  /// </summary>
  IWarPositionalAudio = interface
    ['{C85A2F43-0E91-47D6-B3A7-5E10D9F6824B}']
    procedure PlayAt(AAudioId: Integer; AX, AY: Single);
    procedure SetViewport(AX, AY, AWidth, AHeight: Single);
  end;

  /// <summary>The settings of the game that the cheats change (fields of WarContext)</summary>
  IWarGameSettings = interface
    ['{F2A9B5C1-6D30-47E8-8B14-C07E3A5D92F6}']
    function GetCheatsEnabled: Boolean;
    procedure SetCheatsEnabled(AValue: Boolean);
    function GetMusicEnabled: Boolean;
    procedure SetMusicEnabled(AValue: Boolean);
    function GetSoundEnabled: Boolean;
    procedure SetSoundEnabled(AValue: Boolean);
    function GetAudioEnabled: Boolean;
    procedure SetAudioEnabled(AValue: Boolean);
    function GetGlobalScale: Single;
    function GetGlobalSpeed: Single;
    function GetMusicVolume: Single;
    function GetSoundVolume: Single;
    /// <summary>wg_setGlobalScale: at least 1 (the window changes its size: it is the part that is not here)</summary>
    procedure SetGlobalScale(AScale: Single);
    /// <summary>wg_setGlobalSpeed: at least 1</summary>
    procedure SetGlobalSpeed(ASpeed: Single);
    /// <summary>wg_setMusicVolume: between 0 and 1</summary>
    procedure SetMusicVolume(AVolume: Single);
    /// <summary>wg_setSoundVolume: between 0 and 1</summary>
    procedure SetSoundVolume(AVolume: Single);
    property CheatsEnabled: Boolean read GetCheatsEnabled write SetCheatsEnabled;
    property MusicEnabled: Boolean read GetMusicEnabled write SetMusicEnabled;
    property SoundEnabled: Boolean read GetSoundEnabled write SetSoundEnabled;
    property AudioEnabled: Boolean read GetAudioEnabled write SetAudioEnabled;
    property GlobalScale: Single read GetGlobalScale;
    property GlobalSpeed: Single read GetGlobalSpeed;
    property MusicVolume: Single read GetMusicVolume;
    property SoundVolume: Single read GetSoundVolume;
  end;

  /// <summary>
  ///   context->debugRender of the original: which of the debug drawings of the map are on. They belong to the game, not to a
  ///   map: they stay on from one map to the next
  /// </summary>
  IWarDebugRender = interface
    ['{7D3B9E54-A1C2-4F68-B05D-2E8F46A1C973}']
    function GetFlag(AFlag: TWarDebugRenderFlag): Boolean;
    procedure SetFlag(AFlag: TWarDebugRenderFlag; AValue: Boolean);
    /// <summary>
    ///   wcheat_applyDebugRenderCheat after the check of the cheats: "status", or a name and an optional 0 or 1; the text of
    ///   the feedback
    /// </summary>
    function ApplyCheat(const AArgument: AnsiString): AnsiString;
    /// <summary>updateDebugRenderShortcuts: Ctrl and Shift held, and a key that was just pressed toggles its flag</summary>
    procedure UpdateShortcuts(const AInput: IWarUiInput);
    property Flag[AFlag: TWarDebugRenderFlag]: Boolean read GetFlag write SetFlag;
  end;

  /// <summary>
  ///   What a cheat does that is not in the panel. The cheats that change a setting of the game are in
  ///   TWarSettingsCheatEffects; the ones that need a map (gold, spells, god mode...) are the part of the game that is
  ///   not here and are a no-op when there is no map, as they are in the original
  /// </summary>
  IWarCheatEffects = interface
    ['{A1F3C7D5-0B62-48E9-B3D1-6E94F52A8C07}']
    /// <summary>
    ///   wcheat_apply* of the descriptor named AName with its argument; the text of the feedback the cheat shows (empty
    ///   for none: wcheatp_setCheatsFeedback)
    /// </summary>
    function Apply(const AName: string; const AArgument: AnsiString): AnsiString;
  end;

  /// <summary>What a scene asks the game that runs it (the wg_* and the context of the original)</summary>
  IWarSceneHost = interface
    ['{57E92A4C-C18D-4B30-A6F2-0D7B3E59C481}']
    function GetRealTime: Double;
    function GetRealDeltaTime: Single;
    function GetGlobalSpeed: Single;
    function GetOriginalWidth: Integer;
    function GetOriginalHeight: Integer;
    function GetIsDemo: Boolean;
    /// <summary>SDL_StartTextInput or SDL_StopTextInput: the window starts or stops sending the characters typed</summary>
    procedure SetTextInputActive(AActive: Boolean);
    /// <summary>SDL_PushEvent(SDL_EVENT_QUIT): the player quits the game</summary>
    procedure RequestQuit;
    /// <summary>wg_setNextScene</summary>
    procedure SetNextScene(const AScene: IWarScene; ATransitionDelay: Single);
    /// <summary>wg_setNextMap after wmap_createMap of a campaign map: the map is the part of the game that is not here</summary>
    procedure SetNextCampaignMap(AMapType: Integer; ATransitionDelay: Single);
    /// <summary>wg_setNextMap after wmap_createCustomMap with the options of the custom game menu</summary>
    procedure SetNextCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer; ATransitionDelay: Single);
    property RealTime: Double read GetRealTime;
    property RealDeltaTime: Single read GetRealDeltaTime;
    property GlobalSpeed: Single read GetGlobalSpeed;
    property OriginalWidth: Integer read GetOriginalWidth;
    property OriginalHeight: Integer read GetOriginalHeight;
    property IsDemo: Boolean read GetIsDemo;
  end;

  /// <summary>wsc_createScene for the scenes that a scene starts (the download scene is not ported)</summary>
  IWarSceneFactory = interface
    ['{8C41E7B2-D95A-4F03-A168-3B2E0F9D74C5}']
    function CreateBlizzard: IWarScene;
    function CreateMainMenu: IWarScene;
    /// <summary>
    ///   The introduction of the game, which goes on to the main menu: the original has the button "Replay introduction" and
    ///   no code behind it, so this scene is the port's own. A game whose services have no animations (Cinematics) never
    ///   asks for it: the scene would have nothing to play and would go straight on
    /// </summary>
    function CreateIntroduction: IWarScene;
    /// <summary>A briefing of the humans or the orcs for a campaign map</summary>
    function CreateBriefing(ARace: TWarRace; AMapType: Integer): IWarScene;
  end;

  /// <summary>
  ///   The map of the game, which is not part of the interface and the scenes: wmap_createMap and wmap_createCustomMap.
  ///   What it makes is run as a scene (enter, update, render, leave) from the transition to the end of the map
  /// </summary>
  IWarMapLauncher = interface
    ['{B07D5E39-2A64-4C81-9E1F-5D8A3C60F7B2}']
    function CreateCampaignMap(AMapType: Integer): IWarScene;
    function CreateCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer): IWarScene;
  end;

  /// <summary>
  ///   A scene that does something while the game is paused (Ctrl+P): wmap_updateMapPaused, the map that still scrolls
  ///   and shows its status. A scene that does not implement it does nothing then
  /// </summary>
  IWarPausableScene = interface
    ['{8F3A61C7-5D2E-4B94-A0B8-17C94E6D3F52}']
    procedure UpdatePaused;
  end;

  /// <summary>
  ///   A scene that the scripts of the harness can change from outside: the commands that only a map understands ("unit",
  ///   "upgrade", "feature", "gold", "fog", "spawn"). False if the command is not one of the scene
  /// </summary>
  IWarScriptedScene = interface
    ['{4C9E7A12-6B35-4D80-8A57-D1F2E09B3C64}']
    function ScriptCommand(const ACommand: string; const AArguments: TArray<string>): Boolean;
  end;

  /// <summary>
  ///   What the buttons Save and Load of the menus ask of the program (the original has the buttons and no handler):
  ///   the program saves or loads its quick slot between two frames, never in the middle of one. May be nil in the
  ///   services of a game: then the buttons do nothing, as in the original
  /// </summary>
  IWarSessionRequests = interface
    ['{7A4E1C58-92D3-4B06-AF71-3E8D05B2C9F4}']
    procedure RequestSave;
    procedure RequestLoad;
  end;

  /// <summary>A scene: the functions of a WarSceneDescriptor</summary>
  IWarScene = interface
    ['{1B6F83D0-E4A7-4259-8C1E-9A5D70C32B68}']
    function GetSceneType: TWarSceneType;
    /// <summary>enterSceneFunc</summary>
    procedure Enter;
    /// <summary>updateSceneFunc (or what wsc_updateScene does when there is none: the cheat panel and the animations)</summary>
    procedure Update;
    /// <summary>renderSceneFunc, the animations, renderOverlayFunc and the cheat panel, in the order of wsc_renderScene</summary>
    procedure Render;
    /// <summary>leaveSceneFunc</summary>
    procedure Leave;
    /// <summary>
    ///   SDL_EVENT_TEXT_INPUT (appendCheatTextInput): the characters the player typed. The mouse and the keys are not
    ///   events of a scene: they are read from the input, as the original does
    /// </summary>
    procedure HandleTextInput(const AText: AnsiString);
    property SceneType: TWarSceneType read GetSceneType;
  end;

implementation

end.
