{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the game: all the parts of the logic together    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): PlayLoop, UpdateView,       }
{  InitData and maingame of raven.pas, INT_TimerISR of d_ints.pas, newplayer    }
{  of utils.pas                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game;

// the tics and the positions are 32 bit numbers that wrap as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Sound.Intf,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Level.Intf,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.GameRenderer.Intf,
  DelphiDoom.Greed.Inventory, DelphiDoom.Greed.Game.Parts;

const
  /// <summary>MAX_VIEW_WIDTH and MAX_VIEW_HEIGHT: the view in which the weapon and the status bar are placed</summary>
  GREED_GAME_VIEW_WIDTH = 320;
  GREED_GAME_VIEW_HEIGHT = 200;
  /// <summary>
  ///   windowHeight when the program starts (RF_Startup sets the view of 640 x 400): newplayer of the first game
  ///   puts it in player.scrollmax
  /// </summary>
  GREED_GAME_START_WINDOW_HEIGHT = 400;
  /// <summary>AMBIENTLIGHT: SC.ambientlight of a game without a configuration file</summary>
  GREED_GAME_AMBIENT_LIGHT = 2048;

type
  /// <summary>
  ///   A game of Greed: the state, the world, the lists of sprites and elevators and every part of the logic
  ///   (spawner, sprites, player, weapons, items, switches, doors, elevators, events, the life of a map), wired to
  ///   each other, and the loop of the original cut in the two pieces that its program calls:
  ///   Tic is what the timer of the original does 70 times a second (INT_TimerISR: the clock goes on, the commands
  ///   are read on the odd tics, PlayerCommand moves the player); Frame is one turn of PlayLoop: the flags that the
  ///   commands raised are served (inventory, use, warp jammer, nexus, end of the level, grenade, warp, secret
  ///   codes), the level lives (TimeUpdate, twelve times a turn as in the original: sprites, processes of the
  ///   script, spawn areas, elevators, bonus item), walls and flats are animated, warps and doors are checked, the
  ///   view is drawn (UpdateView: the renderer calls back for four of the TimeUpdate and for the shot), the weapon
  ///   in the hand goes on with its animation. NewGame is newplayer and the start of maingame.
  ///   What is drawn over the view and what is shown between the maps is asked of IGreedGameView; the messages of
  ///   IGreedMessages; the sounds of IGreedSoundEffects and IGreedMusic; the commands come from IGreedControls.
  ///   Not ported: the net game, the demos (recording and playback), the rear view camera (its flags and clocks
  ///   change as in the original, the second view is not drawn, so its TimeUpdate calls are not made) and the
  ///   VR helmet (the TimeUpdate of RF_CheckActionFlag are always made, as with SC.vrhelmet 0).
  ///   Difference: the original runs the timer in a thread, held while a view is drawn; here the program calls Tic
  ///   between two Frame
  /// </summary>
  TGreedGame = class
  strict private
    FParts: TGreedGameParts;
    FLogicHost: IInterface;
    FViewHost: IInterface;
    FRenderHost: IInterface;
    FListener: IGreedListener;
    FSampler: IGreedControlsSampler;
    FMapLoader: IGreedMapLoader;
    FSaveGames: IGreedSaveGames;
    FStatusBar: Boolean;
    FCameraDelay: Integer;
    FWeaponX: Integer;
    FWeaponY: Integer;
    FStartPending: Boolean;
    function GetState: TGreedGameState;
    function GetWorld: IGreedWorld;
    function GetInventory: TGreedInventory;
    function GetQuitGame: Boolean;
    function GetDead: Boolean;
    function GetMap: Integer;
    function GetAmbientLight: Integer;
    procedure SetAmbientLight(AValue: Integer);
    function GetLowResolution: Boolean;
    procedure SetLowResolution(AValue: Boolean);
    function GetViolence: Boolean;
    procedure SetViolence(AValue: Boolean);
    procedure CreateParts;
    procedure InitData;
    function LastMap: Integer;
    procedure ServeToggles;
    procedure ServeInventory;
    procedure AnimateWalls;
    procedure ServeDisplayToggles;
    procedure ServeRearView;
    procedure UpdateView(var AFrame: TGreedFrame);
    procedure SelectNewSong;
    procedure RunMenu;
    procedure RunHelp;
    procedure RunBrief;
    procedure RunQuickExit;
    procedure RunPause;
  public
    /// <summary>
    ///   Everything is asked as an interface: the archive of the lumps, what loads a map, what makes the renderer
    ///   (the game gives it its sprites, its clock and its random numbers), the commands of the player, the sound
    ///   effects and the music, the random numbers (rndofs: one sequence for the whole game), the saved games, the
    ///   clock of the system (the original adds it to some random choices), the view (status bar, screens, films,
    ///   menus) and the line of the messages. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(const AArchive: IGreedArchive; const AMapLoader: IGreedMapLoader;
      const ARendererFactory: IGreedGameRendererFactory; const AControls: IGreedControls;
      const AEffects: IGreedSoundEffects; const AMusic: IGreedMusic; const ARandom: IGreedRandom;
      const ASaveGames: IGreedSaveGames; const AClock: IGreedSystemClock; const AView: IGreedGameView;
      const AMessages: IGreedMessages);
    destructor Destroy; override;
    /// <summary>
    ///   DEMO, GAME1, GAME2 and GAME3 of constant.pas: the demo ends after the map 2, the episodes after the maps
    ///   7, 15 and 21. AEpisode is 1..3 (anything else is the episode 3, as in the original)
    /// </summary>
    procedure SetEdition(ADemo: Boolean; AEpisode: Integer);
    /// <summary>
    ///   newplayer(map, chartype, difficulty) and the start of maingame: a new player of that character (0..5) on
    ///   that map (the first is 0), the map loaded with its script and its sprites, the clock at zero
    /// </summary>
    procedure NewGame(AMap, ACharacter, ADifficulty: Integer);
    /// <summary>
    ///   What maingame does before PlayLoop: the data of the loop (InitData) and the first light. NewGame already
    ///   does it; a game loaded from the menu before play (LoadGame) needs it (StartPending) and clears the flag
    /// </summary>
    procedure StartPlay;
    /// <summary>INT_TimerISR: one tic of the timer. Nothing once the game is over (QuitGame)</summary>
    procedure Tic;
    /// <summary>
    ///   One turn of PlayLoop; the view is drawn into AFrame (any size up to 640 x 400) unless the turn ends
    ///   before (a film was played, the level ended the game). Nothing once the game is over
    /// </summary>
    procedure Frame(var AFrame: TGreedFrame);
    /// <summary>SaveGame(n) and LoadGame(n) of utils.pas</summary>
    procedure SaveGame(ANumber: Integer);
    function LoadGame(ANumber: Integer): Boolean;
    /// <summary>The globals of the original: the player, the clocks, the flags</summary>
    property State: TGreedGameState read GetState;
    property World: IGreedWorld read GetWorld;
    /// <summary>The parts, for who needs more than the game says (tests, tools)</summary>
    property Parts: TGreedGameParts read FParts;
    property Inventory: TGreedInventory read GetInventory;
    /// <summary>Where the player is, for the sound effects</summary>
    property Listener: IGreedListener read FListener;
    /// <summary>quitgame: the player left, or the last map of the edition ended</summary>
    property QuitGame: Boolean read GetQuitGame;
    /// <summary>player.angst = 0: the restart command starts the map again</summary>
    property Dead: Boolean read GetDead;
    /// <summary>player.map</summary>
    property Map: Integer read GetMap;
    /// <summary>SC.ambientlight (0..4096): the light of the level when no warp is changing it</summary>
    property AmbientLight: Integer read GetAmbientLight write SetAmbientLight;
    /// <summary>
    ///   lowresolution of raven.pas: the look up and down has half the range and half the speed, as LoadData does;
    ///   the size of the view is the one of the frame given to Frame
    /// </summary>
    property LowResolution: Boolean read GetLowResolution write SetLowResolution;
    /// <summary>SC.violence: blood and corpses</summary>
    property Violence: Boolean read GetViolence write SetViolence;
    /// <summary>
    ///   The status bar is shown (currentViewSize is not the full view): drawing it chooses an item of the
    ///   inventory when none is chosen. True by default
    /// </summary>
    property StatusBar: Boolean read FStatusBar write FStatusBar;
    /// <summary>SC.camdelay: tics between two pictures of the rear view (TICRATE = one picture and off)</summary>
    property CameraDelay: Integer read FCameraDelay write FCameraDelay;
    /// <summary>A game was loaded (LoadGame) and StartPlay has not run since; NewGame clears it</summary>
    property StartPending: Boolean read FStartPending;
    /// <summary>weaponx and weapony of the last view, in the 320 x 200 view</summary>
    property WeaponX: Integer read FWeaponX;
    property WeaponY: Integer read FWeaponY;
  end;

implementation

uses
  DelphiDoom.Greed.World, DelphiDoom.Greed.Terrain, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Spawner.Intf, DelphiDoom.Greed.Events.Intf,
  DelphiDoom.Greed.MapSession.Intf, DelphiDoom.Greed.Spawner, DelphiDoom.Greed.Events,
  DelphiDoom.Greed.SpriteLogic, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.SpriteDeath,
  DelphiDoom.Greed.Player.Intf, DelphiDoom.Greed.PlayerRules, DelphiDoom.Greed.PlayerMovement,
  DelphiDoom.Greed.PlayerControl, DelphiDoom.Greed.PlayerWeapons, DelphiDoom.Greed.WeaponPictures,
  DelphiDoom.Greed.Elevator.Intf, DelphiDoom.Greed.ElevatorRules, DelphiDoom.Greed.Door.Intf,
  DelphiDoom.Greed.DoorRules, DelphiDoom.Greed.ItemRules, DelphiDoom.Greed.SwitchRules,
  DelphiDoom.Greed.LevelRules, DelphiDoom.Greed.CheatCodes, DelphiDoom.Greed.MapSession,
  DelphiDoom.Greed.Game.Hosts.Logic, DelphiDoom.Greed.Game.Hosts.View, DelphiDoom.Greed.Game.Hosts.Render;

const
  TIC_RATE = 70;
  /// the maps at which each edition is over (PlayLoop)
  END_MAP_DEMO = 3;
  END_MAP_GAME1 = 8;
  END_MAP_GAME2 = 16;
  END_MAP_GAME3 = 22;
  WALL_ANIMATION_TICS = 12;
  DAMAGE_FLOOR_HURT = 30;
  /// F_DAMAGE of r_refdef.pas, in the flags of a floor
  FLOOR_DAMAGE = 1 shl 7;
  SONG_COUNT = 32;
  /// the flats and the wall that the loop animates, three pictures each
  ANIMATED_FLATS: array[0..1] of Integer = (57, 217);
  ANIMATED_WALL = 228;
  SPECIAL_EFFECT_NEVER = $7FFFFFFF;

{ TGreedGame }

constructor TGreedGame.Create(const AArchive: IGreedArchive; const AMapLoader: IGreedMapLoader;
  const ARendererFactory: IGreedGameRendererFactory; const AControls: IGreedControls;
  const AEffects: IGreedSoundEffects; const AMusic: IGreedMusic; const ARandom: IGreedRandom;
  const ASaveGames: IGreedSaveGames; const AClock: IGreedSystemClock; const AView: IGreedGameView;
  const AMessages: IGreedMessages);
var
  LRenderHost: TGreedGameRenderHost;
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(AMapLoader) then
    raise EArgumentNilException.Create('AMapLoader');
  if not Assigned(ARendererFactory) then
    raise EArgumentNilException.Create('ARendererFactory');
  if not Assigned(AControls) then
    raise EArgumentNilException.Create('AControls');
  if not Assigned(AEffects) then
    raise EArgumentNilException.Create('AEffects');
  if not Assigned(AMusic) then
    raise EArgumentNilException.Create('AMusic');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(ASaveGames) then
    raise EArgumentNilException.Create('ASaveGames');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  FMapLoader := AMapLoader;
  FSaveGames := ASaveGames;
  FStatusBar := True;
  // SC.camdelay of InitDefaults
  FCameraDelay := TIC_RATE div 2;
  Supports(AControls, IGreedControlsSampler, FSampler);
  FParts := TGreedGameParts.Create;
  FParts.Archive := AArchive;
  FParts.Random := ARandom;
  FParts.Clock := AClock;
  FParts.Effects := AEffects;
  FParts.Music := AMusic;
  FParts.View := AView;
  FParts.Messages := AMessages;
  FParts.Controls := AControls;
  FParts.AmbientLight := GREED_GAME_AMBIENT_LIGHT;
  FParts.GameEpisode := 1;
  FParts.World := TGreedWorld.Create;
  FParts.Sprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FParts.Elevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FParts.State := TGreedGameState.Create(FParts.World, FParts.Sprites, FParts.Elevators);
  // playernum of net.pas is 1 in a game that is not in a net: the shots and the mines of the player carry it
  FParts.State.PlayerNum := 1;
  // InitDefaults of modplay.pas: the first newlights brings the light up to the one of the settings
  FParts.State.Lighting := 1;
  FParts.State.ChangeLight := FParts.AmbientLight;
  FLogicHost := TGreedGameLogicHost.Create(FParts);
  FViewHost := TGreedGameViewHost.Create(FParts);
  LRenderHost := TGreedGameRenderHost.Create(FParts);
  FRenderHost := LRenderHost;
  FListener := LRenderHost;
  FParts.Renderer := ARendererFactory.CreateRenderer(FParts.Sprites, LRenderHost, ARandom);
  if not Assigned(FParts.Renderer) then
    raise EArgumentNilException.Create('ARendererFactory.CreateRenderer');
  FParts.Renderer.SetActionHook(LRenderHost);
  CreateParts;
end;

procedure TGreedGame.CreateParts;
var
  P: TGreedGameParts;
  LSound: IGreedGameSound;
  LHealth: IGreedPlayerHealth;
  LKiller: IGreedSpriteKiller;
begin
  P := FParts;
  LSound := FLogicHost as IGreedGameSound;
  LHealth := FLogicHost as IGreedPlayerHealth;
  LKiller := FLogicHost as IGreedSpriteKiller;
  P.Spawner := TGreedSpawner.Create(P.State, P.Archive, P.Random, LSound, FRenderHost as IGreedSpritePictures);
  P.SpawnerIntf := P.Spawner;
  P.Events := TGreedEvents.Create(P.State, P.Archive, P.SpawnerIntf, LSound, FViewHost as IGreedEventHost);
  P.EventsIntf := P.Events;
  P.PlayerRules := TGreedPlayerRules.Create(FLogicHost as IGreedPlayerContext, FLogicHost as IGreedPlayerFeedback);
  P.Movement := TGreedPlayerMovement.Create(P.World, FLogicHost as IGreedMovementHost);
  P.Movement.DoorSoundSink := FLogicHost as IGreedDoorSoundSink;
  P.Death := TGreedSpriteDeath.Create(P.Sprites, FLogicHost as IGreedDeathHost);
  P.SpriteLogic := TGreedSpriteLogic.Create(P.State, P.SpawnerIntf, P.Random, LSound, LHealth, LKiller,
    FLogicHost as IGreedSpriteHost);
  // reallight: the sprites light the tiles that the renderer draws
  if Assigned(P.Renderer.TileLights) then
    P.SpriteLogic.RealLight := P.Renderer.TileLights;
  P.ElevatorRules := TGreedElevatorRules.Create(P.World, P.Elevators, FLogicHost as IGreedElevatorHost);
  P.DoorRules := TGreedDoorRules.Create(P.World, FLogicHost as IGreedDoorHost);
  P.WeaponPictures := TGreedWeaponPictures.Create(P.State, P.Archive);
  P.WeaponView := P.WeaponPictures;
  P.Weapons := TGreedPlayerWeapons.Create(P.State, P.SpawnerIntf, LSound, P.WeaponView);
  P.WeaponsIntf := P.Weapons;
  P.Control := TGreedPlayerControl.Create(P.State, P.Movement, P.Controls, FLogicHost as IGreedPlayerControlHost,
    P.EventsIntf, P.WeaponsIntf);
  P.Inventory := TGreedInventory.Create(P.State, P.SpawnerIntf, LSound, LHealth, P.Messages);
  P.Items := TGreedItemRules.Create(P.State, P.SpawnerIntf, LSound, P.EventsIntf, P.Messages, LHealth, P.Random,
    P.Clock, FViewHost as IGreedItemHost);
  P.Switches := TGreedSwitchRules.Create(P.State, LSound, P.EventsIntf, FLogicHost as IGreedSwitchHost);
  P.Level := TGreedLevelRules.Create(P.State, P.SpawnerIntf, LSound, P.Messages, P.Random, P.Clock,
    FLogicHost as IGreedTicParts, FViewHost as IGreedLevelHost);
  P.Cheats := TGreedCheatCodes.Create(P.State, P.Messages, LHealth, LKiller, FViewHost as IGreedCheatHost);
  P.Session := TGreedMapSession.Create(P.State, P.Archive, FMapLoader, P.Events, P.EventsIntf, P.SpawnerIntf,
    P.Random, FSaveGames, P.WeaponView, FViewHost as IGreedMapSessionHost);
end;

destructor TGreedGame.Destroy;
begin
  if Assigned(FParts) then
  begin
    if Assigned(FParts.Renderer) then
      FParts.Renderer.SetActionHook(nil);
    FreeAndNil(FParts.Session);
    FreeAndNil(FParts.Cheats);
    FreeAndNil(FParts.Level);
    FreeAndNil(FParts.Switches);
    FreeAndNil(FParts.Items);
    FreeAndNil(FParts.Inventory);
    FreeAndNil(FParts.Control);
    FParts.WeaponsIntf := nil;
    FParts.Weapons := nil;
    FParts.WeaponView := nil;
    FParts.WeaponPictures := nil;
    FreeAndNil(FParts.DoorRules);
    FreeAndNil(FParts.ElevatorRules);
    FreeAndNil(FParts.SpriteLogic);
    FreeAndNil(FParts.Death);
    FreeAndNil(FParts.Movement);
    FreeAndNil(FParts.PlayerRules);
    FParts.EventsIntf := nil;
    FParts.Events := nil;
    FParts.SpawnerIntf := nil;
    FParts.Spawner := nil;
    FParts.Renderer := nil;
  end;
  FListener := nil;
  FRenderHost := nil;
  FViewHost := nil;
  FLogicHost := nil;
  if Assigned(FParts) then
  begin
    FreeAndNil(FParts.State);
    FreeAndNil(FParts.Sprites);
    FreeAndNil(FParts.Elevators);
    FParts.World := nil;
  end;
  FreeAndNil(FParts);
  inherited Destroy;
end;

function TGreedGame.GetState: TGreedGameState;
begin
  Result := FParts.State;
end;

function TGreedGame.GetWorld: IGreedWorld;
begin
  Result := FParts.World;
end;

function TGreedGame.GetInventory: TGreedInventory;
begin
  Result := FParts.Inventory;
end;

function TGreedGame.GetQuitGame: Boolean;
begin
  Result := FParts.State.QuitGame;
end;

function TGreedGame.GetDead: Boolean;
begin
  Result := FParts.State.Player.Angst = 0;
end;

function TGreedGame.GetMap: Integer;
begin
  Result := FParts.State.Player.Map;
end;

function TGreedGame.GetAmbientLight: Integer;
begin
  Result := FParts.AmbientLight;
end;

procedure TGreedGame.SetAmbientLight(AValue: Integer);
begin
  // as the sliders of the menu: the light goes to the new value at the next newlights
  FParts.AmbientLight := AValue;
  FParts.State.Lighting := 1;
  FParts.State.ChangeLight := AValue;
end;

function TGreedGame.GetLowResolution: Boolean;
begin
  Result := FParts.LowResolution;
end;

procedure TGreedGame.SetLowResolution(AValue: Boolean);
begin
  FParts.LowResolution := AValue;
  if AValue then
  begin
    FParts.Control.MaxScroll := GREED_MAXSCROLL1 div 2;
    FParts.Control.ScrollRate := GREED_SCROLLRATE1 div 2;
  end
  else
  begin
    FParts.Control.MaxScroll := GREED_MAXSCROLL1;
    FParts.Control.ScrollRate := GREED_SCROLLRATE1;
  end;
end;

function TGreedGame.GetViolence: Boolean;
begin
  Result := FParts.Spawner.Violence;
end;

procedure TGreedGame.SetViolence(AValue: Boolean);
begin
  FParts.Spawner.Violence := AValue;
end;

procedure TGreedGame.SetEdition(ADemo: Boolean; AEpisode: Integer);
begin
  FParts.State.Demo := ADemo;
  FParts.State.Game1 := AEpisode = 1;
  FParts.State.Game2 := AEpisode = 2;
  FParts.State.Game3 := not (FParts.State.Game1 or FParts.State.Game2);
  FParts.GameEpisode := AEpisode;
end;

procedure TGreedGame.InitData;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  S.QuitGame := False;
  S.MapMode := 0;
  S.HeatMode := False;
  S.MotionMode := False;
  S.TurnRate := 0;
  S.MoveRate := 0;
  S.FallRate := 0;
  S.StrafRate := 0;
  S.MapZoom := 8;
  S.SecretBuf := '';
  FParts.Weapons.InitProbe;
  FParts.View.ResetDisplay;
end;

procedure TGreedGame.NewGame(AMap, ACharacter, ADifficulty: Integer);
var
  S: TGreedGameState;
begin
  S := FParts.State;
  // newplayer
  S.GameLoaded := True;
  TGreedPlayerRules.NewPlayer(S.Player, AMap, ACharacter, ADifficulty, S.LevelScore,
    GREED_GAME_START_WINDOW_HEIGHT);
  FParts.Session.ResetEngine;
  (FViewHost as IGreedLevelHost).NewMap(S.Player.Map, 1);
  S.TimeCount := 0;
  S.KeyboardDelay := 0;
  FParts.WeaponView.LoadWeapon(S.Player.Weapons[0]);
  // maingame
  StartPlay;
  // PlayLoop
  S.TimeCount := 0;
  // the map after the last one of the edition is not a map: newmap shows the end of the episode and loads
  // nothing. The original gets there only from EndLevel, which ends the game; a game that starts there is over
  // (the original would go on in an empty world, where CheckBonusItem never finds a tile)
  if AMap = LastMap then
    S.QuitGame := True;
end;

procedure TGreedGame.StartPlay;
begin
  InitData;
  FParts.Control.NewLights;
  FStartPending := False;
end;

procedure TGreedGame.Tic;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.QuitGame then
    Exit;
  Inc(S.TimeCount);
  if (S.TimeCount and 1 <> 0) and Assigned(FSampler) then
    FSampler.ReadControls;
  FParts.Control.PlayerCommand;
end;

function TGreedGame.LastMap: Integer;
begin
  if FParts.State.Demo then
    Result := END_MAP_DEMO
  else if FParts.State.Game1 then
    Result := END_MAP_GAME1
  else if FParts.State.Game2 then
    Result := END_MAP_GAME2
  else
    Result := END_MAP_GAME3;
end;

procedure TGreedGame.ServeToggles;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.ToggleAutoRun then
  begin
    S.AutoRun := not S.AutoRun;
    if S.AutoRun then
      FParts.Messages.WriteMessage('Auto-Run On')
    else
      FParts.Messages.WriteMessage('Auto-Run Off');
    S.ToggleAutoRun := False;
  end;
  if S.ToggleAutoTarget then
  begin
    S.AutoTarget := not S.AutoTarget;
    if S.AutoTarget then
      FParts.Messages.WriteMessage('Auto-Target On')
    else
      FParts.Messages.WriteMessage('Auto-Target Off');
    S.ToggleAutoTarget := False;
  end;
end;

procedure TGreedGame.ServeInventory;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.GoIRight then
  begin
    FParts.Inventory.Right;
    S.GoIRight := False;
  end;
  if S.GoILeft then
  begin
    FParts.Inventory.Left;
    S.GoILeft := False;
  end;
  if S.UseItem then
  begin
    FParts.Inventory.Use;
    S.UseItem := False;
  end;
end;

procedure TGreedGame.AnimateWalls;
var
  S: TGreedGameState;
  LStep, LIndex, LPicture, LFlat: Integer;
begin
  S := FParts.State;
  if S.TimeCount < S.WallAnimationTime then
    Exit;
  Inc(S.WallAnimCount);
  // the three pictures of each animation turn: 0 the next one, 1 the one before, 2 its own
  case S.WallAnimCount mod 3 of
    0: LStep := 1;
    1: LStep := 2;
  else
    LStep := 0;
  end;
  for LIndex := 0 to 2 do
  begin
    LPicture := (LIndex + LStep) mod 3;
    for LFlat in ANIMATED_FLATS do
      FParts.Renderer.SetFlatTranslation(LFlat + LIndex, LFlat + LPicture);
    FParts.Renderer.SetWallTranslation(ANIMATED_WALL + LIndex, ANIMATED_WALL + LPicture);
  end;
  S.WallAnimationTime := S.TimeCount + WALL_ANIMATION_TICS;
  if (FParts.World.GetValue(gpFloorFlags, S.Player.MapSpot) and FLOOR_DAMAGE <> 0) and
    (S.Player.Z = TGreedTerrain.FloorZ(FParts.World, S.Player.X, S.Player.Y) + S.Player.Height) then
    FParts.PlayerRules.Hurt(S.Player, DAMAGE_FLOOR_HURT);
end;

procedure TGreedGame.ServeDisplayToggles;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.ToggleHeatMode then
  begin
    if S.HeatMode then
      S.HeatMode := False
    else
    begin
      S.HeatMode := True;
      if S.MapMode = 2 then
        S.MapMode := 1;
    end;
    S.ToggleHeatMode := False;
  end;
  if S.ToggleMotionMode then
  begin
    if S.MotionMode then
      S.MotionMode := False
    else
    begin
      S.MotionMode := True;
      if S.MapMode = 2 then
        S.MapMode := 1;
    end;
    S.ToggleMotionMode := False;
  end;
  if S.ToggleMapMode then
  begin
    case S.MapMode of
      0:
        S.MapMode := 1;
      1:
        if S.HeatMode or S.MotionMode then
          S.MapMode := 0
        else
          S.MapMode := 2;
      2:
        S.MapMode := 0;
    end;
    S.ToggleMapMode := False;
  end;
  if S.ToggleGoalItem then
    FParts.Level.NewGoalItem;
end;

procedure TGreedGame.ServeRearView;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.ToggleRearView then
  begin
    S.RearViewOn := not S.RearViewOn;
    S.ToggleRearView := False;
    S.RearViewDelay := S.TimeCount;
  end;
  if S.RearViewOn and (S.TimeCount >= S.RearViewDelay) then
  begin
    // RearView (the second view of 64 x 64) is not drawn
    S.RearViewTime := S.TimeCount + 2 * TIC_RATE;
    S.RearViewDelay := S.TimeCount + FCameraDelay;
    if FCameraDelay = TIC_RATE then
      S.RearViewOn := False;
  end;
end;

procedure TGreedGame.UpdateView(var AFrame: TGreedFrame);
var
  S: TGreedGameState;
  LOverlay: TGreedViewOverlay;
  LHeadBob: Integer;
begin
  S := FParts.State;
  FParts.Weapons.WeaponBobView := S.WeapBob;
  LOverlay := Default(TGreedViewOverlay);
  LOverlay.TimeCount := S.TimeCount;
  if S.HeadBobOn then
    LHeadBob := TGreedGameTables.HeadMove[S.HeadBob]
  else
    LHeadBob := 0;
  // the renderer calls CheckActionFlag four times: a TimeUpdate each, and the shot of the player
  FParts.Renderer.RenderView(FParts.World, S.Player, S.Player.X, S.Player.Y, S.Player.Z + LHeadBob, S.Player.Angle,
    AFrame);
  FParts.Level.TimeUpdate;
  // (the holo picture and the rear view go here)
  FParts.Level.TimeUpdate;
  LOverlay.WeaponVisible := S.Player.Angst <> 0;
  LOverlay.WeaponLump := -1;
  if LOverlay.WeaponVisible then
  begin
    FParts.Weapons.UpdateWeaponView(True, GREED_GAME_VIEW_WIDTH, GREED_GAME_VIEW_HEIGHT, FWeaponX, FWeaponY);
    LOverlay.WeaponLump := FParts.WeaponPictures.PictureLump(S.WeapMode);
    LOverlay.WeaponX := FWeaponX;
    LOverlay.WeaponY := FWeaponY;
    LOverlay.WeaponMode := S.WeapMode;
  end;
  FParts.Level.TimeUpdate;
  LOverlay.MapMode := S.MapMode;
  LOverlay.HeatMode := S.HeatMode;
  LOverlay.MotionMode := S.MotionMode;
  // displayinventory of the status bar
  // displayinventory of the status bar chooses an item when none is chosen or the chosen one is finished
  if FStatusBar and ((FParts.Inventory.Cursor = GREED_INVENTORY_NONE) or
    (S.Player.Inventory[FParts.Inventory.Cursor] = 0)) then
    FParts.Inventory.Right;
  FParts.View.DrawOverlay(AFrame, LOverlay);
  FParts.Level.TimeUpdate;
end;

procedure TGreedGame.SelectNewSong;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  Inc(S.SongNum);
  S.SongNum := S.SongNum mod SONG_COUNT;
  (FViewHost as IGreedMapSessionHost).SelectSong(S.SongNum);
  S.NewSong := False;
end;

procedure TGreedGame.RunMenu;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  S.Player.TimeCount := S.TimeCount;
  if FParts.View.ShowMenu then
    S.QuitGame := True;
  S.TimeCount := S.Player.TimeCount;
  S.ActivateMenu := False;
  S.KeyboardDelay := S.TimeCount + GREED_KBDELAY;
end;

procedure TGreedGame.RunHelp;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  S.Player.TimeCount := S.TimeCount;
  FParts.View.ShowHelp;
  S.ActivateHelp := False;
  S.TimeCount := S.Player.TimeCount;
  S.KeyboardDelay := S.TimeCount + GREED_KBDELAY;
end;

procedure TGreedGame.RunBrief;
begin
  FParts.View.MissionBriefing(FParts.State.Player.Map);
  FParts.State.ActivateBrief := False;
end;

procedure TGreedGame.RunQuickExit;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  S.QuickExit := False;
  if FParts.View.ConfirmQuit then
    S.QuitGame := True;
  S.KeyboardDelay := S.TimeCount + GREED_KBDELAY;
end;

procedure TGreedGame.RunPause;
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.Paused then
    S.GamePause := True;
  S.Player.TimeCount := S.TimeCount;
  FParts.View.ShowPause;
  S.TimeCount := S.Player.TimeCount;
  S.Paused := False;
  S.GamePause := False;
  S.KeyboardDelay := S.TimeCount + GREED_KBDELAY;
end;

procedure TGreedGame.Frame(var AFrame: TGreedFrame);
var
  S: TGreedGameState;
begin
  S := FParts.State;
  if S.QuitGame then
    Exit;
  // a film was played (the player died in it): nothing moves until the player asks to start again
  if S.FliPlayed <> 0 then
  begin
    if S.DeadRestart then
      FParts.Level.StartOver(2);
    Exit;
  end;
  ServeToggles;
  ServeInventory;
  if S.CheckTrigger then
  begin
    S.CheckTrigger := False;
    FParts.Switches.CheckHere(True, S.Player.X, S.Player.Y, S.Player.Angle);
    if S.FliPlayed <> 0 then
      Exit;
  end;
  if S.WarpJammer then
    FParts.Level.JamWarps;
  if S.FallDamage <> 0 then
  begin
    // just makes a grunt sound
    FParts.Effects.Start(GREED_SN_HIT0 + S.Player.CharType, 15, S.Player.X, S.Player.Y);
    S.FallDamage := 0;
  end;
  if (S.Player.LevelScore = 0) and (not S.ExitExists) and
    (((S.Primaries[0] <> -1) and (S.Player.Primaries[0] = S.PCount[0])) or (S.Primaries[0] = -1)) and
    (((S.Primaries[2] <> -1) and (S.Player.Primaries[1] = S.PCount[1])) or (S.Primaries[2] = -1)) then
    FParts.Level.PrepareNexus;
  if S.ExitLevel then
  begin
    FParts.Level.EndLevel;
    if S.Player.Map >= LastMap then
    begin
      S.QuitGame := True;
      Exit;
    end;
  end;
  if S.TimeCount > S.SpecialEffectTime then
  begin
    S.SpecialEffect := 0;
    S.SpecialEffectTime := SPECIAL_EFFECT_NEVER;
  end;
  if FParts.Inventory.FireGrenade then
    FParts.Inventory.ThrowGrenade;
  if S.Warping <> 0 then
    FParts.Level.WarpAnim;
  // check special code flag
  FParts.Cheats.SpecialCode;
  // update sprite movement
  FParts.Level.TimeUpdate;
  AnimateWalls;
  FParts.Items.CheckWarps(S.Player.X, S.Player.Y);
  if S.FliPlayed <> 0 then
    Exit;
  FParts.DoorRules.Check(S.Player.X, S.Player.Y);
  if S.DeadRestart then
    FParts.Level.StartOver(2);
  if FParts.Control.ResizeScreen then
  begin
    FParts.View.ChangeViewSize(FParts.Control.BiggerScreen);
    FParts.Control.ResizeScreen := False;
  end;
  if S.ScrollView <> 0 then
    FParts.Control.ChangeScroll;
  FParts.Level.TimeUpdate;
  ServeDisplayToggles;
  ServeRearView;
  UpdateView(AFrame);
  if S.NewSong then
    SelectNewSong;
  if S.ActivateMenu then
    RunMenu;
  if S.ActivateHelp then
    RunHelp;
  if S.ActivateBrief then
    RunBrief;
  FParts.Level.TimeUpdate;
  if S.QuickExit then
    RunQuickExit;
  if S.Paused then
    RunPause;
  Inc(S.Frames);
  FParts.Level.TimeUpdate;
  // update lights if necessary
  if S.ChangeLight <> 0 then
    FParts.Control.NewLights;
  // update weapon to be displayed
  FParts.WeaponsIntf.AdvanceWeaponMode;
end;

procedure TGreedGame.SaveGame(ANumber: Integer);
begin
  FParts.Session.SaveGame(ANumber);
end;

function TGreedGame.LoadGame(ANumber: Integer): Boolean;
begin
  Result := FParts.Session.LoadGame(ANumber);
  if Result then
  begin
    FStartPending := True;
    FParts.Renderer.SetBackdrop(FParts.Events.Backdrop);
  end;
end;

end.
