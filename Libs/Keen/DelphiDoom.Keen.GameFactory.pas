{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the game put together                             }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  what InitGame of kd_main.c starts, US_Startup and US_Shutdown of id_us.c     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameFactory;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.Shape,
  DelphiDoom.Keen.ActorMover, DelphiDoom.Keen.StateMachine, DelphiDoom.Keen.PlayLoop, DelphiDoom.Keen.LevelScanner,
  DelphiDoom.Keen.GameSaver, DelphiDoom.Keen.DemoLoop, DelphiDoom.Keen.ConfigStore, DelphiDoom.Keen.LateActions,
  DelphiDoom.Keen.LateEvents;

type
  /// <summary>What a program gives to have a game: the data and the parts that belong to the machine</summary>
  TKeenGameParts = record
    /// <summary>The graphics, the maps and the sounds</summary>
    Data: IKeenGameData;
    /// <summary>TimeCount, and what a loop that waits does</summary>
    Clock: IKeenClock;
    /// <summary>The keyboard, the mouse and the joysticks</summary>
    Input: IKeenInput;
    Sound: IKeenSoundManager;
    /// <summary>Where the configuration and the saved games go</summary>
    Files: IKeenUserFiles;
    /// <summary>The help texts; nil for none</summary>
    Help: IKeenHelpTexts;
    /// <summary>The joysticks, for their calibration; nil for none</summary>
    Joysticks: IKeenJoysticks;
    /// <summary>The title picture (TITLESCR.LBM of KDREAMS.CMP)</summary>
    Title: TKeenShape;
    /// <summary>The "comp" parameter of the original: the screens never go past the end of the video memory</summary>
    Compatibility: Boolean;
    /// <summary>US_InitRndT(true): the random numbers start from the time; false starts them from 0, always the same</summary>
    Randomize: Boolean;
    /// <summary>The time that Randomize uses (the hundredths of a second of the clock of the DOS)</summary>
    RandomTime: Integer;
  end;

  /// <summary>
  ///   A game of Keen Dreams with all its parts, made by TKeenGameFactory. It owns the parts and frees them in the
  ///   right order; a program runs DemoLoop.Run (or Game.GameLoop) and frees the set at the end
  /// </summary>
  TKeenGameSet = class
  strict private
    FMover: TKeenActorMover;
    FMachine: TKeenStateMachine;
    FPlayLoop: TKeenPlayLoop;
    FScanner: TKeenLevelScanner;
    FSaver: TKeenGameSaver;
    FDemoLoop: TKeenDemoLoop;
    FConfig: TKeenConfigStore;
    FLateActions: TKeenLateActions;
    FLateEvents: TKeenLateEvents;
    FLateActionsKeeper: IKeenActions;
    FLateEventsKeeper: IKeenGameEvents;
    FActions: IKeenActions;
  public
    Memory: IKeenEgaMemory;
    Video: IKeenVideo;
    Refresh: IKeenRefresh;
    Buffered: IKeenBufferedVideo;
    Fader: IKeenFader;
    Input: IKeenInput;
    Sound: IKeenSoundManager;
    Windows: IKeenUserWindows;
    Objects: IKeenObjectList;
    Play: IKeenPlayState;
    Level: IKeenLevelSetup;
    UserState: IKeenUserState;
    Slots: IKeenSaveSlots;
    Scores: IKeenHighScores;
    Panel: IKeenControlPanel;
    Game: IKeenGame;
    constructor Create(const AParts: TKeenGameParts);
    destructor Destroy; override;
    /// <summary>
    ///   USL_ReadConfig and USL_CheckSavedGames: the scores, the sound mode, the control and the keys of the
    ///   configuration file (the defaults if there is none), and which saved games are there
    /// </summary>
    procedure LoadConfig;
    /// <summary>USL_WriteConfig; false if the file cannot be written</summary>
    function SaveConfig: Boolean;
    /// <summary>The loop of the frames of a level, for a program that drives it by itself</summary>
    property PlayLoop: TKeenPlayLoop read FPlayLoop;
    /// <summary>The start screens and the games one after the other</summary>
    property DemoLoop: TKeenDemoLoop read FDemoLoop;
  end;

  /// <summary>The only place of the library that knows which classes make a game</summary>
  TKeenGameFactory = class
  public
    class function CreateGame(const AParts: TKeenGameParts): TKeenGameSet; static;
    /// <summary>The title picture of a SoftLib library (the bytes of KDREAMS.CMP)</summary>
    class function LoadTitle(const ALibrary: TBytes): TKeenShape; static;
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.Video, DelphiDoom.Keen.Refresh,
  DelphiDoom.Keen.BufferedVideo, DelphiDoom.Keen.Fader, DelphiDoom.Keen.UserWindows, DelphiDoom.Keen.ObjectList,
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.Random, DelphiDoom.Keen.PlayState,
  DelphiDoom.Keen.ActionAdapters, DelphiDoom.Keen.ActionContext, DelphiDoom.Keen.GameActions,
  DelphiDoom.Keen.WorkingMap, DelphiDoom.Keen.LevelSetup, DelphiDoom.Keen.UserState, DelphiDoom.Keen.SaveSlots,
  DelphiDoom.Keen.HighScores, DelphiDoom.Keen.ControlPanel, DelphiDoom.Keen.Game, DelphiDoom.Keen.ShapeLibrary;

const
  TITLE_FILE_NAME = 'TITLESCR.LBM';

{ TKeenGameSet }

constructor TKeenGameSet.Create(const AParts: TKeenGameParts);
var
  LGraphics: IKeenGraphics;
  LTileInfo: IKeenTileInfo;
  LSprites: IKeenSpriteCache;
  LRefresh: TKeenRefresh;
  LStates: IKeenStateTable;
  LRandom: IKeenRandom;
  LContext: IKeenActionContext;
  LGameActions: TKeenGameActions;
  LGame: TKeenGame;
begin
  inherited Create;
  if not Assigned(AParts.Data) then
    raise EArgumentNilException.Create('AParts.Data');
  if not Assigned(AParts.Clock) then
    raise EArgumentNilException.Create('AParts.Clock');
  if not Assigned(AParts.Input) then
    raise EArgumentNilException.Create('AParts.Input');
  if not Assigned(AParts.Sound) then
    raise EArgumentNilException.Create('AParts.Sound');
  if not Assigned(AParts.Files) then
    raise EArgumentNilException.Create('AParts.Files');
  LGraphics := AParts.Data.Graphics;
  LTileInfo := AParts.Data.Maps.TileInfo;
  Input := AParts.Input;
  Sound := AParts.Sound;
  // the video: the memory of the card, the drawing routines, the refresh manager, the windows
  Memory := TKeenEgaMemory.Create;
  LSprites := TKeenSpriteCache.Create(LGraphics);
  Video := TKeenVideo.Create(Memory, LGraphics, LSprites);
  LRefresh := TKeenRefresh.Create(Video, LGraphics, LTileInfo, LSprites, AParts.Clock, AParts.Compatibility);
  Refresh := LRefresh;
  Buffered := TKeenBufferedVideo.Create(Video, LRefresh, LGraphics, LSprites, AParts.Clock);
  Fader := TKeenFader.Create(AParts.Clock);
  Windows := TKeenUserWindows.Create(Buffered, Input, AParts.Clock);
  // the actors. The state machine and the functions of the states call each other, and the functions tell the
  // game what happens: the two are bound when both sides exist
  Objects := TKeenObjectList.Create(Refresh);
  LStates := TKeenFactory.CreateGameStateTable;
  LRandom := TKeenRandom.Create;
  LRandom.Initialize(AParts.Randomize, AParts.RandomTime);
  FLateActions := TKeenLateActions.Create;
  FLateActionsKeeper := FLateActions;
  FLateEvents := TKeenLateEvents.Create;
  FLateEventsKeeper := FLateEvents;
  FMover := TKeenActorMover.Create(nil, LTileInfo, LSprites, LStates, Objects, FLateEventsKeeper);
  FMachine := TKeenStateMachine.Create(Objects, LStates, FLateActionsKeeper, FMover, Refresh);
  Play := TKeenPlayState.Create(FLateEventsKeeper);
  // the functions need a map from the start: an empty one stands until the first level
  LContext := TKeenActionContext.Create(Objects, LStates, LRandom, FLateEventsKeeper,
    TKeenActionView.Create(Refresh, AParts.Clock), TKeenActorPhysics.Create(FMover, FMachine), Play,
    TKeenWorkingMap.Create(1, 1), LTileInfo);
  LGameActions := TKeenGameActions.Create(LContext, LGraphics, LSprites);
  FActions := LGameActions;
  FLateActions.Bind(FActions);
  FPlayLoop := TKeenPlayLoop.Create(Objects, FMachine, FMover, LStates, FLateActionsKeeper, Refresh, Input, LRandom,
    FLateEventsKeeper, Play);
  FScanner := TKeenLevelScanner.Create(Objects, LGameActions);
  Level := TKeenLevelSetup.Create(AParts.Data.Maps, Refresh, FScanner, FMover, FPlayLoop, LContext, LGameActions,
    Fader, Windows);
  FSaver := TKeenGameSaver.Create(Play, Objects, LStates, Level);
  // the user manager
  UserState := TKeenUserState.Create;
  Slots := TKeenSaveSlots.Create(AParts.Files);
  Scores := TKeenHighScores.Create(Windows, Input);
  Panel := TKeenControlPanel.Create(Windows, Input, AParts.Clock, Sound, UserState, Slots, AParts.Help,
    AParts.Joysticks);
  FConfig := TKeenConfigStore.Create(AParts.Files);
  // the game, and what waited for it
  LGame := TKeenGame.Create(Play, FPlayLoop, Level, FSaver, LGameActions, Refresh, Windows, Fader, Input,
    AParts.Clock, Sound, UserState, Panel, Scores);
  Game := LGame;
  FLateEvents.Bind(LGame);
  Panel.SetHooks(LGame);
  FDemoLoop := TKeenDemoLoop.Create(AParts.Title, Windows, Input, Scores, Panel, UserState, Game);
end;

destructor TKeenGameSet.Destroy;
begin
  // the hooks first: they point at objects that go away below
  if Assigned(Panel) then
    Panel.SetHooks(nil);
  if Assigned(Refresh) then
    Refresh.SetRefreshHook(nil);
  if Assigned(Buffered) then
    Buffered.SetUpdateHook(nil);
  if Assigned(FLateEvents) then
    FLateEvents.Bind(nil);
  if Assigned(FLateActions) then
    FLateActions.Bind(nil);
  FDemoLoop.Free;
  Game := nil;
  Panel := nil;
  Level := nil;
  FSaver.Free;
  FConfig.Free;
  FScanner.Free;
  FPlayLoop.Free;
  FActions := nil;
  FMachine.Free;
  FMover.Free;
  inherited Destroy;
end;

procedure TKeenGameSet.LoadConfig;
var
  LConfig: TKeenConfig;
  LIndex: Integer;
  LMode: TKeenSoundMode;
  LGotSound: Boolean;
begin
  LConfig := FConfig.Read(Input.KeyboardDefs[0]);
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
    Scores.Scores[LIndex] := LConfig.Scores[LIndex];
  // SD_Default: a device that this port does not have counts as "not there"
  LGotSound := TKeenConfigStore.TrySoundMode(LConfig.SoundMode, LMode);
  Sound.SetDefault(LConfig.Found and LGotSound, LMode);
  if LConfig.Found then
    Input.KeyboardDefs[0] := LConfig.Keyboard;
  Input.SetDefault(LConfig.Found, LConfig.Control);
  Slots.Check;
end;

function TKeenGameSet.SaveConfig: Boolean;
var
  LConfig: TKeenConfig;
  LIndex: Integer;
begin
  LConfig.Found := True;
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
    LConfig.Scores[LIndex] := Scores.Scores[LIndex];
  LConfig.SoundMode := Ord(Sound.Mode);
  LConfig.MusicMode := 0;
  LConfig.Control := Input.Controls[0];
  LConfig.Keyboard := Input.KeyboardDefs[0];
  Result := FConfig.Write(LConfig);
end;

{ TKeenGameFactory }

class function TKeenGameFactory.CreateGame(const AParts: TKeenGameParts): TKeenGameSet;
begin
  Result := TKeenGameSet.Create(AParts);
end;

class function TKeenGameFactory.LoadTitle(const ALibrary: TBytes): TKeenShape;
var
  LLibrary: TKeenShapeLibrary;
begin
  LLibrary := TKeenShapeLibrary.Create(ALibrary);
  try
    Result := TKeenShapeReader.Parse(LLibrary.LoadFile(TITLE_FILE_NAME));
  finally
    LLibrary.Free;
  end;
end;

end.
