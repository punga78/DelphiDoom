{******************************************************************************}
{                                                                              }
{  DelphiDoom: the stand-ins of what TGreedGame is given, for its tests         }
{                                                                              }
{  An archive where every name is a lump, a map built in memory, a renderer     }
{  that counts, commands that the test presses, sounds, music, view and         }
{  messages that are written in lists: no data of the game, no window, no       }
{  sound device                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.GameFakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Random,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.SpriteLogic.Intf,
  DelphiDoom.Greed.CommandState, DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.GameRenderer.Intf,
  DelphiDoom.Greed.Game;

const
  /// <summary>The lumps of the fake archive: "map" and the script of the maps ("SUX") have their own ranges</summary>
  FAKE_MAP_LUMP = 1000;
  FAKE_SCRIPT_LUMP = 2000;
  FAKE_LUMP_COUNT = 3000;
  /// <summary>The tile where the player starts in the fake map</summary>
  FAKE_START_X = 10;
  FAKE_START_Y = 10;

type
  /// <summary>Every name is a lump (the same name gives the same number); the lumps are empty but the scripts</summary>
  TFakeGameArchive = class(TInterfacedObject, IGreedArchive)
  strict private
    FNames: TStringList;
  public
    /// <summary>The script of each map (the text of event.pas); a map without one has an empty script</summary>
    Scripts: TDictionary<Integer, string>;
    constructor Create;
    destructor Destroy; override;
    function GetLumpCount: Integer;
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpSize(AIndex: Integer): Integer;
    function IndexOf(const AName: string): Integer;
    function RequireIndexOf(const AName: string): Integer;
    function ReadLump(AIndex: Integer): TBytes;
    function ReadLumpRaw(AIndex: Integer): TBytes;
  end;

  /// <summary>
  ///   A map of one open room: a floor and a high ceiling everywhere, the player on (10, 10); the test puts
  ///   values in the planes before the game loads it (Put)
  /// </summary>
  TFakeGameMaps = class(TInterfacedObject, IGreedMapLoader)
  strict private
    FBytes: TBytes;
  public
    Loads: Integer;
    LastMap: Integer;
    constructor Create;
    procedure Put(APlane: TGreedPlane; ATileX, ATileY: Integer; AValue: Byte);
    function Load(AMapNumber: Integer): IGreedMap;
  end;

  /// <summary>Counts the views and calls the action hook four times a view, as the renderer of the library</summary>
  TFakeGameRenderer = class(TInterfacedObject, IGreedGameRenderer, IGreedGameRendererFactory)
  strict private
    FHook: IGreedRenderActionHook;
    FLights: TGreedTileLights;
  public
    Views: Integer;
    LastZ: TGreedFixed;
    LastBlackZ: TGreedFixed;
    FlatTranslations: TDictionary<Integer, Integer>;
    ColorMaps: TStringList;
    MonsterLoads: Integer;
    Backdrops: Integer;
    EffectsTimeResets: Integer;
    LastEffectsTime: Integer;
    constructor Create;
    destructor Destroy; override;
    function CreateRenderer(ASprites: TGreedLinkedPool<TGreedSprite>; const AClock: IGreedRenderClock;
      const ARandom: IGreedRandom): IGreedGameRenderer;
    procedure RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY, AZ: TGreedFixed;
      AAngle: Integer; var AFrame: TGreedFrame);
    function TileLights: PGreedTileLights;
    procedure SetLights(ABlackZ: TGreedFixed);
    procedure SetFlatTranslation(AFlat, APicture: Integer);
    procedure SetWallTranslation(AWall, APicture: Integer);
    procedure LoadColorMaps(const ALumpName: string);
    procedure SetBackdrop(const APixels: TBytes);
    procedure SetActionHook(const AHook: IGreedRenderActionHook);
    procedure SetEffectsTime(ATime: Integer);
    procedure DemandLoadMonster(ALump, ACount: Integer);
  end;

  /// <summary>The commands that the test holds down, the text that it types</summary>
  TFakeCommandSource = class(TInterfacedObject, IGreedCommandSource)
  public
    Pressed: set of TGreedCommand;
    Typed: string;
    Readings: Integer;
    TypedInReading: Boolean;
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

  /// <summary>The sounds and the songs that the game asked for</summary>
  TFakeGameSound = class(TInterfacedObject, IGreedSoundEffects, IGreedMusic)
  public
    Sounds: TList<Integer>;
    Updates: Integer;
    Songs: TStringList;
    MusicStops: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
    procedure Update;
    procedure StopAll;
    procedure Play(const AFileName: string; APattern: Integer);
    procedure Stop;
    function CountOf(ASound: Integer): Integer;
  end;

  /// <summary>There are no saved games</summary>
  TFakeSaveGames = class(TInterfacedObject, IGreedSaveGames)
  public
    Saved: Integer;
    function GameFileName(ANumber: Integer): string;
    function DirectoryFileName: string;
    procedure SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
    function LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
    function ReadDirectory: TGreedSaveDirectory;
    procedure WriteDirectory(const ADirectory: TGreedSaveDirectory);
  end;

  /// <summary>The clock of the system is what the test says</summary>
  TFakeSystemClock = class(TInterfacedObject, IGreedSystemClock)
  public
    Value: Cardinal;
    function Clock: Cardinal;
  end;

  /// <summary>What the game asked of its view and the messages that it wrote, by name</summary>
  TFakeGameView = class(TInterfacedObject, IGreedGameView, IGreedMessages)
  public
    Calls: TStringList;
    Messages: TStringList;
    Overlays: Integer;
    LastOverlay: TGreedViewOverlay;
    /// <summary>What ShowMenu and ConfirmQuit answer</summary>
    QuitFromMenu: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure RefreshInventory;
    procedure RefreshAmmo;
    procedure RefreshGoalItem;
    procedure ResetDisplay;
    procedure SetTotalEffectTime(ATics: Integer);
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    procedure PlayFli(AMovie: Integer);
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    procedure FadeOutLevel;
    procedure ChangeViewSize(ABigger: Boolean);
    procedure SetGameEpisode(AEpisode: Integer);
    function ShowMenu: Boolean;
    procedure ShowHelp;
    procedure ShowPause;
    function ConfirmQuit: Boolean;
    procedure DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
    procedure WriteMessage(const AText: string);
    function CountOf(const ACall: string): Integer;
  end;

  /// <summary>A TGreedGame on its stand-ins: the test keeps the objects to look at what the game did with them</summary>
  TFakeGameSetup = class
  strict private
    FArchiveIntf: IGreedArchive;
    FMapsIntf: IGreedMapLoader;
    FRendererIntf: IGreedGameRendererFactory;
    FSourceIntf: IGreedCommandSource;
    FSoundIntf: IGreedSoundEffects;
    FRandomIntf: IGreedRandom;
    FClockIntf: IGreedSystemClock;
    FViewIntf: IGreedGameView;
  public
    Archive: TFakeGameArchive;
    Maps: TFakeGameMaps;
    Renderer: TFakeGameRenderer;
    Commands: TFakeCommandSource;
    Sound: TFakeGameSound;
    Random: TGreedRandomTable;
    Clock: TFakeSystemClock;
    View: TFakeGameView;
    Game: TGreedGame;
    Frame: TGreedFrame;
    constructor Create;
    destructor Destroy; override;
    /// <summary>The game is made (after the test has prepared the map and the scripts)</summary>
    procedure CreateGame;
    /// <summary>ATurns times: ATicsPerTurn tics and a turn of the loop (Frame)</summary>
    procedure Play(ATurns: Integer; ATicsPerTurn: Integer = 2);
    /// <summary>How many sprites of that kind are in the level</summary>
    function SpritesOfKind(AKind: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Greed.Factory, DelphiDoom.Tests.Greed.Builders;

{ TFakeGameArchive }

constructor TFakeGameArchive.Create;
begin
  inherited Create;
  FNames := TStringList.Create;
  Scripts := TDictionary<Integer, string>.Create;
end;

destructor TFakeGameArchive.Destroy;
begin
  Scripts.Free;
  FNames.Free;
  inherited Destroy;
end;

function TFakeGameArchive.GetLumpCount: Integer;
begin
  Result := FAKE_LUMP_COUNT;
end;

function TFakeGameArchive.GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
begin
  Result := Default(TGreedLumpInfo);
end;

function TFakeGameArchive.GetLumpName(AIndex: Integer): string;
begin
  if (AIndex >= 1) and (AIndex <= FNames.Count) then
    Result := FNames[AIndex - 1]
  else
    Result := '';
end;

function TFakeGameArchive.GetLumpSize(AIndex: Integer): Integer;
begin
  Result := Length(ReadLumpRaw(AIndex));
end;

function TFakeGameArchive.IndexOf(const AName: string): Integer;
var
  LName: string;
begin
  LName := LowerCase(AName);
  if LName = 'map' then
    Exit(FAKE_MAP_LUMP);
  if LName = 'sux' then
    Exit(FAKE_SCRIPT_LUMP);
  Result := FNames.IndexOf(LName);
  if Result < 0 then
    Result := FNames.Add(LName);
  Inc(Result);
end;

function TFakeGameArchive.RequireIndexOf(const AName: string): Integer;
begin
  Result := IndexOf(AName);
end;

function TFakeGameArchive.ReadLump(AIndex: Integer): TBytes;
begin
  Result := ReadLumpRaw(AIndex);
end;

function TFakeGameArchive.ReadLumpRaw(AIndex: Integer): TBytes;
var
  LScript: string;
begin
  Result := nil;
  if (AIndex > FAKE_SCRIPT_LUMP) and Scripts.TryGetValue(AIndex - FAKE_SCRIPT_LUMP - 1, LScript) then
    Result := TEncoding.ANSI.GetBytes(LScript);
end;

{ TFakeGameMaps }

constructor TFakeGameMaps.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  FBytes := TGreedLumps.MapBytes(nil);
  FillChar(FBytes[0], Length(FBytes), 0);
  for LIndex := 0 to GREED_MAP_TILES - 1 do
  begin
    FBytes[Ord(gpFloorPic) * GREED_MAP_TILES + LIndex] := 1;
    FBytes[Ord(gpCeilingPic) * GREED_MAP_TILES + LIndex] := 1;
    FBytes[Ord(gpCeilingHeight) * GREED_MAP_TILES + LIndex] := 200;
  end;
  Put(gpMapSprites, FAKE_START_X, FAKE_START_Y, 1);
end;

procedure TFakeGameMaps.Put(APlane: TGreedPlane; ATileX, ATileY: Integer; AValue: Byte);
begin
  FBytes[Ord(APlane) * GREED_MAP_TILES + ATileY * GREED_MAP_SIZE + ATileX] := AValue;
end;

function TFakeGameMaps.Load(AMapNumber: Integer): IGreedMap;
begin
  Inc(Loads);
  LastMap := AMapNumber;
  Result := TGreedFactory.CreateMapReader.Read(Copy(FBytes));
end;

{ TFakeGameRenderer }

constructor TFakeGameRenderer.Create;
begin
  inherited Create;
  FlatTranslations := TDictionary<Integer, Integer>.Create;
  ColorMaps := TStringList.Create;
end;

destructor TFakeGameRenderer.Destroy;
begin
  ColorMaps.Free;
  FlatTranslations.Free;
  inherited Destroy;
end;

function TFakeGameRenderer.CreateRenderer(ASprites: TGreedLinkedPool<TGreedSprite>; const AClock: IGreedRenderClock;
  const ARandom: IGreedRandom): IGreedGameRenderer;
begin
  Result := Self;
end;

procedure TFakeGameRenderer.RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY,
  AZ: TGreedFixed; AAngle: Integer; var AFrame: TGreedFrame);
var
  LIndex: Integer;
begin
  Inc(Views);
  LastZ := AZ;
  for LIndex := 1 to 4 do
    if Assigned(FHook) then
      FHook.CheckActionFlag;
end;

function TFakeGameRenderer.TileLights: PGreedTileLights;
begin
  Result := @FLights;
end;

procedure TFakeGameRenderer.SetLights(ABlackZ: TGreedFixed);
begin
  LastBlackZ := ABlackZ;
end;

procedure TFakeGameRenderer.SetFlatTranslation(AFlat, APicture: Integer);
begin
  FlatTranslations.AddOrSetValue(AFlat, APicture);
end;

procedure TFakeGameRenderer.SetWallTranslation(AWall, APicture: Integer);
begin
end;

procedure TFakeGameRenderer.LoadColorMaps(const ALumpName: string);
begin
  ColorMaps.Add(ALumpName);
end;

procedure TFakeGameRenderer.SetBackdrop(const APixels: TBytes);
begin
  Inc(Backdrops);
end;

procedure TFakeGameRenderer.SetActionHook(const AHook: IGreedRenderActionHook);
begin
  FHook := AHook;
end;

procedure TFakeGameRenderer.SetEffectsTime(ATime: Integer);
begin
  Inc(EffectsTimeResets);
  LastEffectsTime := ATime;
end;

procedure TFakeGameRenderer.DemandLoadMonster(ALump, ACount: Integer);
begin
  Inc(MonsterLoads);
end;

{ TFakeCommandSource }

procedure TFakeCommandSource.BeginReading;
begin
  Inc(Readings);
  TypedInReading := False;
end;

function TFakeCommandSource.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := ACommand in Pressed;
end;

function TFakeCommandSource.TakeTyped(out ACharacter: Char): Boolean;
begin
  // a key a reading, as a hand on a keyboard
  Result := (Typed <> '') and not TypedInReading;
  if Result then
  begin
    TypedInReading := True;
    ACharacter := Typed[1];
    Delete(Typed, 1, 1);
  end
  else
    ACharacter := #0;
end;

function TFakeCommandSource.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := False;
end;

procedure TFakeCommandSource.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := 0;
  ADeltaY := 0;
end;

{ TFakeGameSound }

constructor TFakeGameSound.Create;
begin
  inherited Create;
  Sounds := TList<Integer>.Create;
  Songs := TStringList.Create;
end;

destructor TFakeGameSound.Destroy;
begin
  Songs.Free;
  Sounds.Free;
  inherited Destroy;
end;

procedure TFakeGameSound.Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Sounds.Add(ASoundNumber);
end;

procedure TFakeGameSound.Update;
begin
  Inc(Updates);
end;

procedure TFakeGameSound.StopAll;
begin
end;

procedure TFakeGameSound.Play(const AFileName: string; APattern: Integer);
begin
  Songs.Add(AFileName);
end;

procedure TFakeGameSound.Stop;
begin
  Inc(MusicStops);
end;

function TFakeGameSound.CountOf(ASound: Integer): Integer;
var
  LSound: Integer;
begin
  Result := 0;
  for LSound in Sounds do
    if LSound = ASound then
      Inc(Result);
end;

{ TFakeSaveGames }

function TFakeSaveGames.GameFileName(ANumber: Integer): string;
begin
  Result := 'SAVEGAME.' + IntToStr(ANumber);
end;

function TFakeSaveGames.DirectoryFileName: string;
begin
  Result := 'SAVEGAME.DIR';
end;

procedure TFakeSaveGames.SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
begin
  Inc(Saved);
end;

function TFakeSaveGames.LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
begin
  FillChar(APlayer, SizeOf(APlayer), 0);
  Result := False;
end;

function TFakeSaveGames.ReadDirectory: TGreedSaveDirectory;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

procedure TFakeSaveGames.WriteDirectory(const ADirectory: TGreedSaveDirectory);
begin
end;

{ TFakeSystemClock }

function TFakeSystemClock.Clock: Cardinal;
begin
  Result := Value;
end;

{ TFakeGameView }

constructor TFakeGameView.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
  Messages := TStringList.Create;
end;

destructor TFakeGameView.Destroy;
begin
  Messages.Free;
  Calls.Free;
  inherited Destroy;
end;

function TFakeGameView.CountOf(const ACall: string): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to Calls.Count - 1 do
    if Calls[LIndex] = ACall then
      Inc(Result);
end;

procedure TFakeGameView.RefreshInventory;
begin
  Calls.Add('RefreshInventory');
end;

procedure TFakeGameView.RefreshAmmo;
begin
  Calls.Add('RefreshAmmo');
end;

procedure TFakeGameView.RefreshGoalItem;
begin
  Calls.Add('RefreshGoalItem');
end;

procedure TFakeGameView.ResetDisplay;
begin
  Calls.Add('ResetDisplay');
end;

procedure TFakeGameView.SetTotalEffectTime(ATics: Integer);
begin
  Calls.Add('SetTotalEffectTime ' + IntToStr(ATics));
end;

procedure TFakeGameView.MissionBriefing(AMap: Integer);
begin
  Calls.Add('MissionBriefing ' + IntToStr(AMap));
end;

procedure TFakeGameView.EndGame(AEpisode: Integer);
begin
  Calls.Add('EndGame ' + IntToStr(AEpisode));
end;

procedure TFakeGameView.PlayFli(AMovie: Integer);
begin
  Calls.Add('PlayFli ' + IntToStr(AMovie));
end;

procedure TFakeGameView.StartWait;
begin
  Calls.Add('StartWait');
end;

procedure TFakeGameView.UpdateWait;
begin
end;

procedure TFakeGameView.EndWait;
begin
  Calls.Add('EndWait');
end;

procedure TFakeGameView.FadeOutLevel;
begin
  Calls.Add('FadeOutLevel');
end;

procedure TFakeGameView.ChangeViewSize(ABigger: Boolean);
begin
  Calls.Add('ChangeViewSize ' + IntToStr(Ord(ABigger)));
end;

procedure TFakeGameView.SetGameEpisode(AEpisode: Integer);
begin
  Calls.Add('SetGameEpisode ' + IntToStr(AEpisode));
end;

function TFakeGameView.ShowMenu: Boolean;
begin
  Calls.Add('ShowMenu');
  Result := QuitFromMenu;
end;

procedure TFakeGameView.ShowHelp;
begin
  Calls.Add('ShowHelp');
end;

procedure TFakeGameView.ShowPause;
begin
  Calls.Add('ShowPause');
end;

function TFakeGameView.ConfirmQuit: Boolean;
begin
  Calls.Add('ConfirmQuit');
  Result := QuitFromMenu;
end;

procedure TFakeGameView.DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
begin
  Inc(Overlays);
  LastOverlay := AOverlay;
end;

procedure TFakeGameView.WriteMessage(const AText: string);
begin
  Messages.Add(AText);
end;

{ TFakeGameSetup }

constructor TFakeGameSetup.Create;
begin
  inherited Create;
  Archive := TFakeGameArchive.Create;
  FArchiveIntf := Archive;
  Maps := TFakeGameMaps.Create;
  FMapsIntf := Maps;
  Renderer := TFakeGameRenderer.Create;
  FRendererIntf := Renderer;
  Commands := TFakeCommandSource.Create;
  FSourceIntf := Commands;
  Sound := TFakeGameSound.Create;
  FSoundIntf := Sound;
  Random := TGreedRandomTable.Create;
  FRandomIntf := Random;
  Clock := TFakeSystemClock.Create;
  FClockIntf := Clock;
  View := TFakeGameView.Create;
  FViewIntf := View;
  Frame := TGreedFrame.Make(GREED_GAME_VIEW_WIDTH, GREED_GAME_VIEW_HEIGHT);
end;

destructor TFakeGameSetup.Destroy;
begin
  FreeAndNil(Game);
  inherited Destroy;
end;

procedure TFakeGameSetup.CreateGame;
begin
  FreeAndNil(Game);
  Game := TGreedGame.Create(FArchiveIntf, FMapsIntf, FRendererIntf, TGreedCommandState.Create(FSourceIntf),
    FSoundIntf, Sound as IGreedMusic, FRandomIntf, TFakeSaveGames.Create, FClockIntf, FViewIntf,
    View as IGreedMessages);
end;

procedure TFakeGameSetup.Play(ATurns: Integer; ATicsPerTurn: Integer);
var
  LTurn, LTic: Integer;
begin
  for LTurn := 1 to ATurns do
  begin
    for LTic := 1 to ATicsPerTurn do
      Game.Tic;
    Game.Frame(Frame);
  end;
end;

function TFakeGameSetup.SpritesOfKind(AKind: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  LIndex := Game.State.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    if PGreedSprite(Game.State.Sprites.Item(LIndex))^.Kind = AKind then
      Inc(Result);
    LIndex := Game.State.Sprites.Next(LIndex);
  end;
end;

end.
