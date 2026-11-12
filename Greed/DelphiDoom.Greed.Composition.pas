{******************************************************************************}
{                                                                              }
{  DelphiDoom: Greed32 - the composition root                                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later), "In Pursuit of Greed"       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Composition;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>What Greed32 -play was asked on the command line</summary>
  TGreedPlayOptions = record
    /// <summary>The first map is 0</summary>
    MapNumber: Integer;
    /// <summary>0 is no limit</summary>
    MaxTics: Integer;
    /// <summary>The character of the player (0..5) and the difficulty, as newplayer</summary>
    Character: Integer;
    Difficulty: Integer;
    /// <summary>rndofs at the start: where the game is in its table of random numbers</summary>
    Seed: Integer;
    /// <summary>The player walks, turns, uses and shoots by itself</summary>
    AutoPlay: Boolean;
    /// <summary>The file of the commands (see TGreedScriptControls); empty for none</summary>
    ScriptPath: string;
    /// <summary>The last picture is saved here as a PNG; empty for none</summary>
    ShotPath: string;
    /// <summary>The state of the game at the end is written here (see TGreedGameDump); empty for none</summary>
    DumpPath: string;
    /// <summary>The map from above instead of the first person view</summary>
    TopDown: Boolean;
    /// <summary>320 x 200 instead of 640 x 400 (lowresolution)</summary>
    LowResolution: Boolean;
    /// <summary>
    ///   No window, no sound device and no clock: the game runs as fast as the machine goes, two tics a picture,
    ///   and the same options always give the same game
    /// </summary>
    Headless: Boolean;
    /// <summary>0..255, or -1 for the default</summary>
    MusicVolume: Integer;
    SfxVolume: Integer;
    AudioStatistics: Boolean;
    /// <summary>The messages of the game are written on the console</summary>
    EchoMessages: Boolean;
    /// <summary>With the program (no -play): the game starts at once, without titles and menu (nointro)</summary>
    SkipIntro: Boolean;
    /// <summary>With the program: no screens before a map (nobriefing)</summary>
    NoBriefing: Boolean;
    /// <summary>With the program: the game of -game1, -game2 or -game3 (0 for the one of the settings)</summary>
    Game: Integer;
    /// <summary>With the program: the tics at which a picture is saved, as ShotPath with the tic before the extension</summary>
    ShotTics: TArray<Integer>;
    /// <summary>The options of a game that was not asked anything</summary>
    class function Standard: TGreedPlayOptions; static;
  end;

  /// <summary>
  ///   The one place of Greed32 that knows the classes behind the interfaces: the library of the greed port
  ///   (Libs\Greed) and the ones that it shares with the Doom engine (video palette, PNG, files). It does not
  ///   touch ComposeEngine nor TIdTechGeneration: Greed is not an id Tech 1 game
  /// </summary>
  TGreedComposition = class
  strict private
    class function PlayOn(const AArchive: IGreedArchive; const AFolders: array of string;
      const AOptions: TGreedPlayOptions; ADemo: Boolean): Integer; static;
  public
    /// <summary>The name of the data file of the game</summary>
    const DataFileName = 'GREED.BLO';
    /// <summary>The archive GREED.BLO of the first folder that has it; EGreedNotFoundException if none</summary>
    class function OpenArchive(const AFolders: array of string): IGreedArchive; static;
    /// <summary>What saves maps and lumps as PNG files; the maps of the demos are looked for in AFolders</summary>
    class function CreateExporter(const AArchive: IGreedArchive; const AFolders: array of string): IGreedPngExporter; static;
    /// <summary>What says the kind of a lump</summary>
    class function CreateClassifier(const AArchive: IGreedArchive): IGreedLumpClassifier; static;
    /// <summary>
    ///   Plays a map with TGreedGame: the window of Libs\GameHost with the keys of the original (or no window at
    ///   all), the mixer of the sound on the PCM output, the music of the map, the commands of a script. It ends
    ///   when the window is closed, when the game is over (Escape, or the last map) or after the tics asked for.
    ///   Returns the tics played
    /// </summary>
    class function Play(const AArchive: IGreedArchive; const AFolders: array of string;
      const AOptions: TGreedPlayOptions): Integer; static;
    /// <summary>
    ///   Runs the program as a normal game: the introduction and its menu (or at once a new game with SkipIntro),
    ///   the game with its screens, the endings. The settings (xGreed.ini) and the saved games are in the folder
    ///   ADataFolder, the music and the movies in AFolders. It ends when the player quits, when the window is closed or
    ///   after MaxTics tics. Returns the tics played
    /// </summary>
    class function RunProgram(const AArchive: IGreedArchive; const AFolders: array of string;
      const ADataFolder: string; const AOptions: TGreedPlayOptions): Integer; static;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Greed.Factory, DelphiDoom.Greed.PngEncoder,
  DelphiDoom.Greed.PngExporter, DelphiDoom.Png.Provider, DelphiDoom.Png.IndexedEncoder,
  DelphiDoom.Platform.Factory, DelphiDoom.Clock.Factory, DelphiDoom.Clock.Intf, DelphiDoom.Clock.ManualClock,
  DelphiDoom.Logging.Factory, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Palette, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.TopDownRenderer,
  DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Save.Intf,
  DelphiDoom.Greed.SaveFolder, DelphiDoom.Greed.SaveGames, DelphiDoom.Greed.Sound.Intf,
  DelphiDoom.Greed.SoundEffects, DelphiDoom.Greed.SoundVolumes, DelphiDoom.Greed.Music, DelphiDoom.Greed.PcmMixer,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState, DelphiDoom.Greed.GameView.Intf,
  DelphiDoom.Greed.GameRenderer.Intf, DelphiDoom.Greed.GameRendererFactory, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game, DelphiDoom.Greed.GameLoop, DelphiDoom.Greed.HostWindow, DelphiDoom.Greed.HostControls,
  DelphiDoom.Greed.ScriptControls, DelphiDoom.Greed.PlainView, DelphiDoom.Greed.HudView, DelphiDoom.Greed.Hud.Intf, DelphiDoom.Greed.GameDump,
  DelphiDoom.Greed.HostAudio, DelphiDoom.Greed.TrackerSongDecoder, DelphiDoom.Greed.DemoArchive,
  DelphiDoom.Greed.Settings, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.SettingsStore,
  DelphiDoom.Greed.Application.Intf, DelphiDoom.Greed.ApplicationScript, DelphiDoom.Greed.Application,
  DelphiDoom.Greed.Screens, DelphiDoom.Greed.ScreenView, DelphiDoom.Greed.MenuHost, DelphiDoom.Greed.IntroHost,
  DelphiDoom.Greed.EpisodeHost, DelphiDoom.Greed.HostKeyboard, DelphiDoom.Greed.Menu.Intf, DelphiDoom.Greed.Intro,
  DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.GameHost.KeyState, DelphiDoom.GameHost.Win.Window, DelphiDoom.GameHost.Factory;

const
  WINDOW_TITLE = 'Greed32';
  // the episodes of the full game start at these maps
  FIRST_MAP_OF_GAME2 = 8;
  FIRST_MAP_OF_GAME3 = 16;
  // a tic of the game in milliseconds, for the clock of a game without a window
  HEADLESS_TIC_MILLISECONDS = 14;

type
  /// <summary>
  ///   What the game and its sound ask of the time and of the place of the player before the game exists: the
  ///   place the effects are heard from (the listener of the game, once it is made), the wait of the fade of the
  ///   music, and the clock of the system that the original adds to some random choices (in a game without a
  ///   window it is the tics of the loop, so that the game is always the same)
  /// </summary>
  TGreedPlayTime = class(TInterfacedObject, IGreedListener, IGreedTics, IGreedSystemClock)
  public
    Game: TGreedGame;
    Loop: TGreedGameLoop;
    Application: TGreedApplication;
    RealClock: IClock;
    Headless: Boolean;
    function GetX: TGreedFixed;
    function GetY: TGreedFixed;
    function GetAngle: Integer;
    procedure Wait(ATics: Integer);
    function Clock: Cardinal;
  end;

  /// <summary>A game without a window: the pictures go nowhere and nobody closes it</summary>
  TGreedNoWindow = class(TInterfacedObject, IGreedFramePresenter, IGreedInput)
  public
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

  /// <summary>Shows the pictures where it is told and keeps the last one and its palette, for a picture saved at the end</summary>
  TGreedLastFramePresenter = class(TInterfacedObject, IGreedFramePresenter)
  strict private
    FInner: IGreedFramePresenter;
    FFrame: TGreedFrame;
    FColors: TGreedColors;
    FHasFrame: Boolean;
  public
    constructor Create(const AInner: IGreedFramePresenter);
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
    /// <summary>The last picture as an image, with its palette (768 bytes); False if none was shown</summary>
    function Snapshot(out AImage: TGreedImage; out APalette: TBytes): Boolean;
  end;

  /// <summary>Saves the last picture as a PNG at the tics asked for, and passes the tic on to who follows</summary>
  TGreedShotTaker = class(TInterfacedObject, IGreedTicListener)
  strict private
    FPresenter: TGreedLastFramePresenter;
    FNext: IGreedTicListener;
    FEncoder: IGreedImageEncoder;
    FPath: string;
    FTics: TArray<Integer>;
  public
    constructor Create(APresenter: TGreedLastFramePresenter; const ANext: IGreedTicListener;
      const AEncoder: IGreedImageEncoder; const APath: string; const ATics: TArray<Integer>);
    procedure TicStarting(ATic: Integer);
  end;

  /// <summary>Nothing is pressed: the commands of a game without a window come from its script alone</summary>
  TGreedNoKeys = class(TInterfacedObject, IGreedCommandSource)
  public
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

  /// <summary>The map from above (TGreedTopDownRenderer) where the game asks for its renderer</summary>
  TGreedTopDownGameRenderer = class(TInterfacedObject, IGreedGameRenderer, IGreedGameRendererFactory)
  strict private
    FRenderer: IGreedFrameRenderer;
  public
    constructor Create(const ARenderer: IGreedFrameRenderer);
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
    function WeaponLight: IGreedWeaponLight;
    function TileLightReader: IGreedTileLights;
    procedure DemandLoadMonster(ALump, ACount: Integer);
  end;

{ TGreedPlayOptions }

class function TGreedPlayOptions.Standard: TGreedPlayOptions;
begin
  Result := Default(TGreedPlayOptions);
  Result.Difficulty := 2;
  Result.MusicVolume := -1;
  Result.SfxVolume := -1;
end;

{ TGreedPlayTime }

function TGreedPlayTime.GetX: TGreedFixed;
begin
  if Assigned(Game) then
    Result := Game.Listener.GetX
  else
    Result := 0;
end;

function TGreedPlayTime.GetY: TGreedFixed;
begin
  if Assigned(Game) then
    Result := Game.Listener.GetY
  else
    Result := 0;
end;

function TGreedPlayTime.GetAngle: Integer;
begin
  if Assigned(Game) then
    Result := Game.Listener.GetAngle
  else
    Result := 0;
end;

procedure TGreedPlayTime.Wait(ATics: Integer);
begin
  // the fade of the music: the tics are 70 a second
  if Assigned(RealClock) and not Headless then
    RealClock.Wait(ATics * 1000 div GREED_LOOP_TIC_RATE);
end;

function TGreedPlayTime.Clock: Cardinal;
begin
  if Headless or not Assigned(RealClock) then
  begin
    if Assigned(Loop) then
      Result := Cardinal(Loop.Tics) * HEADLESS_TIC_MILLISECONDS
    else if Assigned(Application) then
      Result := Cardinal(Application.Tics) * HEADLESS_TIC_MILLISECONDS
    else
      Result := 0;
  end
  else
    Result := Cardinal(Trunc(RealClock.Seconds * 1000));
end;

{ TGreedNoWindow }

procedure TGreedNoWindow.Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
begin
end;

function TGreedNoWindow.Pump: Boolean;
begin
  Result := True;
end;

function TGreedNoWindow.IsDown(AKey: TGreedKey): Boolean;
begin
  Result := False;
end;

{ TGreedNoKeys }

procedure TGreedNoKeys.BeginReading;
begin
end;

function TGreedNoKeys.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := False;
end;

function TGreedNoKeys.TakeTyped(out ACharacter: Char): Boolean;
begin
  ACharacter := #0;
  Result := False;
end;

function TGreedNoKeys.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := False;
end;

procedure TGreedNoKeys.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := 0;
  ADeltaY := 0;
end;

{ TGreedLastFramePresenter }

constructor TGreedLastFramePresenter.Create(const AInner: IGreedFramePresenter);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  FInner := AInner;
end;

procedure TGreedLastFramePresenter.Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
begin
  FFrame.Width := AFrame.Width;
  FFrame.Height := AFrame.Height;
  FFrame.Pixels := Copy(AFrame.Pixels, 0, Length(AFrame.Pixels));
  FColors := AColors;
  FHasFrame := True;
  FInner.Present(AFrame, AColors);
end;

function TGreedLastFramePresenter.Snapshot(out AImage: TGreedImage; out APalette: TBytes): Boolean;
var
  LIndex: Integer;
begin
  Result := FHasFrame;
  if not Result then
    Exit;
  AImage.Width := FFrame.Width;
  AImage.Height := FFrame.Height;
  AImage.OriginX := 0;
  AImage.OriginY := 0;
  AImage.Pixels := FFrame.Pixels;
  SetLength(APalette, 768);
  for LIndex := 0 to 255 do
  begin
    APalette[LIndex * 3] := Byte(FColors[LIndex] shr 16);
    APalette[LIndex * 3 + 1] := Byte(FColors[LIndex] shr 8);
    APalette[LIndex * 3 + 2] := Byte(FColors[LIndex]);
  end;
end;

{ TGreedShotTaker }

constructor TGreedShotTaker.Create(APresenter: TGreedLastFramePresenter; const ANext: IGreedTicListener;
  const AEncoder: IGreedImageEncoder; const APath: string; const ATics: TArray<Integer>);
begin
  inherited Create;
  if not Assigned(APresenter) then
    raise EArgumentNilException.Create('APresenter');
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  FPresenter := APresenter;
  FNext := ANext;
  FEncoder := AEncoder;
  FPath := APath;
  FTics := ATics;
end;

procedure TGreedShotTaker.TicStarting(ATic: Integer);
var
  LTic: Integer;
  LImage: TGreedImage;
  LPalette: TBytes;
begin
  if Assigned(FNext) then
    FNext.TicStarting(ATic);
  for LTic in FTics do
    if (LTic = ATic) and FPresenter.Snapshot(LImage, LPalette) then
      TFile.WriteAllBytes(ChangeFileExt(FPath, '') + '_' + IntToStr(ATic) + ExtractFileExt(FPath),
        FEncoder.Encode(LImage, LPalette, False));
end;

{ TGreedTopDownGameRenderer }

constructor TGreedTopDownGameRenderer.Create(const ARenderer: IGreedFrameRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
end;

function TGreedTopDownGameRenderer.CreateRenderer(ASprites: TGreedLinkedPool<TGreedSprite>;
  const AClock: IGreedRenderClock; const ARandom: IGreedRandom): IGreedGameRenderer;
begin
  Result := Self;
end;

procedure TGreedTopDownGameRenderer.RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY,
  AZ: TGreedFixed; AAngle: Integer; var AFrame: TGreedFrame);
begin
  FRenderer.Render(AWorld, APlayer, AFrame);
end;

function TGreedTopDownGameRenderer.TileLights: PGreedTileLights;
begin
  Result := nil;
end;

procedure TGreedTopDownGameRenderer.SetLights(ABlackZ: TGreedFixed);
begin
end;

procedure TGreedTopDownGameRenderer.SetFlatTranslation(AFlat, APicture: Integer);
begin
end;

procedure TGreedTopDownGameRenderer.SetWallTranslation(AWall, APicture: Integer);
begin
end;

procedure TGreedTopDownGameRenderer.LoadColorMaps(const ALumpName: string);
begin
end;

procedure TGreedTopDownGameRenderer.SetBackdrop(const APixels: TBytes);
begin
end;

procedure TGreedTopDownGameRenderer.SetActionHook(const AHook: IGreedRenderActionHook);
begin
end;

function TGreedTopDownGameRenderer.WeaponLight: IGreedWeaponLight;
begin
  Result := nil;
end;

function TGreedTopDownGameRenderer.TileLightReader: IGreedTileLights;
begin
  Result := nil;
end;

procedure TGreedTopDownGameRenderer.SetEffectsTime(ATime: Integer);
begin
end;

procedure TGreedTopDownGameRenderer.DemandLoadMonster(ALump, ACount: Integer);
begin
end;

{ TGreedComposition }

class function TGreedComposition.OpenArchive(const AFolders: array of string): IGreedArchive;
var
  LFolder: string;
  LPath: string;
begin
  for LFolder in AFolders do
  begin
    LPath := TPath.Combine(LFolder, DataFileName);
    if TFile.Exists(LPath) then
      Exit(TGreedFactory.OpenArchiveFile(LPath));
  end;
  raise EGreedNotFoundException.CreateFmt(SGreedFileNotFound, [DataFileName]);
end;

class function TGreedComposition.CreateExporter(const AArchive: IGreedArchive;
  const AFolders: array of string): IGreedPngExporter;
begin
  Result := TGreedPngExporter.Create(AArchive,
    TGreedFactory.CreateMapLoader(AArchive, TGreedFactory.CreateFolderFiles(AFolders)),
    TGreedFactory.CreateMapRenderer(AArchive), TGreedFactory.CreateLumpClassifier(AArchive),
    TGreedPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client)),
    TPlatformFactory.CreateFileStore);
end;

class function TGreedComposition.CreateClassifier(const AArchive: IGreedArchive): IGreedLumpClassifier;
begin
  Result := TGreedFactory.CreateLumpClassifier(AArchive);
end;

// The index of the palette whose color is the closest to the one asked for (the distance of the squares of the channels)
function NearestIndex(const APalette: TBytes; ARed, AGreen, ABlue: Integer): Byte;
var
  LIndex, LDistance, LBest: Integer;
begin
  Result := 0;
  LBest := MaxInt;
  for LIndex := 0 to 255 do
  begin
    LDistance := Sqr(APalette[LIndex * 3] - ARed) + Sqr(APalette[LIndex * 3 + 1] - AGreen) +
      Sqr(APalette[LIndex * 3 + 2] - ABlue);
    if LDistance < LBest then
    begin
      LBest := LDistance;
      Result := Byte(LIndex);
    end;
  end;
end;

// The commands of -autoplay as a script: the player walks forward and now and then runs, turns (left or right for
// a while), steps aside, shoots in bursts and uses what is in front of it. The lengths come from a linear
// congruential generator of the seed, so the same seed gives the same game
procedure AddAutoPlay(AScript: TStrings; AMaxTics, ASeed: Integer);
const
  DEFAULT_TICS = 70 * 60 * 10;
  COMMANDS: array[0..6] of string = ('north', 'shift', 'east', 'west', 'fire', 'slideleft', 'slideright');
var
  LState: Cardinal;
  LStart, LLength, LCommand: Integer;

  function Roll(ALow, AHigh: Integer): Integer;
  begin
    LState := LState * 1664525 + 1013904223;
    Result := ALow + Integer((LState shr 8) mod Cardinal(AHigh - ALow + 1));
  end;

begin
  if AMaxTics <= 0 then
    AMaxTics := DEFAULT_TICS;
  LState := Cardinal(ASeed) * 2654435761 + 12345;
  // walking: held down for the whole game, the other commands come and go on top
  AScript.Add('1 north down');
  LStart := 3;
  while LStart < AMaxTics do
  begin
    LCommand := Roll(1, High(COMMANDS));
    LLength := Roll(6, 60);
    if (LCommand = 4) or (LCommand = 1) then
      LLength := Roll(20, 100);
    AScript.Add(Format('%d %s down', [LStart, COMMANDS[LCommand]]));
    AScript.Add(Format('%d %s up', [LStart + LLength, COMMANDS[LCommand]]));
    if Roll(0, 5) = 0 then
    begin
      AScript.Add(Format('%d space down', [LStart + LLength + 2]));
      AScript.Add(Format('%d space up', [LStart + LLength + 6]));
    end;
    Inc(LStart, LLength + Roll(2, 40));
  end;
end;
class function TGreedComposition.Play(const AArchive: IGreedArchive; const AFolders: array of string;
  const AOptions: TGreedPlayOptions): Integer;
var
  LMapLump: Integer;
begin
  // the maps of a demo are files next to the archive (their lumps are empty), and its archive does not have
  // every lump that the game names
  LMapLump := AArchive.RequireIndexOf(GREED_LUMP_MAP) + AOptions.MapNumber + 1;
  if (LMapLump < AArchive.LumpCount) and (AArchive.GetLumpSize(LMapLump) = 0) then
    Result := PlayOn(TGreedDemoArchive.Create(AArchive), AFolders, AOptions, True)
  else
    Result := PlayOn(AArchive, AFolders, AOptions, False);
end;

class function TGreedComposition.PlayOn(const AArchive: IGreedArchive; const AFolders: array of string;
  const AOptions: TGreedPlayOptions; ADemo: Boolean): Integer;
var
  LPalette: TBytes;
  LColors: TGreedColors;
  LIndex, LFrameWidth, LFrameHeight, LScale: Integer;
  LFiles: IGreedExternalFiles;
  LKeys: IGameHostKeyState;
  LWindow: TGameHostWinWindow;
  LHostWindow: TGreedHostWindow;
  LPresenter: IGreedFramePresenter;
  LInput: IGreedInput;
  LSource: IGreedCommandSource;
  LScript: TStringList;
  LTime: TGreedPlayTime;
  LTimeIntf: IInterface;
  LClock: IClock;
  LDevice: IGreedSoundDevice;
  LMixer: IGreedPcmRenderer;
  LAudio: TGreedHostAudio;
  LAudioSource: IInterface;
  LDeviceOpen: Boolean;
  LVolumes: IGreedSoundVolumes;
  LEffects: IGreedSoundEffects;
  LMusic: IGreedMusic;
  LRandom: TGreedRandomTable;
  LRandomIntf: IGreedRandom;
  LHudView: TGreedHudView;
  LPlain: TGreedPlainView;
  LViewIntf: IGreedGameView;
  LMessages: IGreedMessages;
  LLogged: TStringList;
  LRendererFactory: IGreedGameRendererFactory;
  LGame: TGreedGame;
  LLoop: TGreedGameLoop;
  LStatistics: TGreedMixerStatistics;
  LImage: TGreedImage;
  LEncoder: IGreedImageEncoder;
  LDump: TStringList;
  LMusicVolume, LSfxVolume: Integer;
  LDemo: Boolean;
begin
  LPalette := TGreedPalette.FromLump(AArchive.ReadLump(AArchive.RequireIndexOf(GREED_LUMP_PALETTE)));
  for LIndex := 0 to 255 do
    LColors[LIndex] := (Cardinal(LPalette[LIndex * 3]) shl 16) or (Cardinal(LPalette[LIndex * 3 + 1]) shl 8) or
      Cardinal(LPalette[LIndex * 3 + 2]);
  if AOptions.TopDown or AOptions.LowResolution then
  begin
    LFrameWidth := 320;
    LFrameHeight := 200;
    LScale := 3;
  end
  else
  begin
    LFrameWidth := 640;
    LFrameHeight := 400;
    LScale := 1;
  end;
  LFiles := TGreedFactory.CreateFolderFiles(AFolders);
  LWindow := nil;
  LGame := nil;
  LLoop := nil;
  LAudio := nil;
  LScript := TStringList.Create;
  try
    // the window of Libs\GameHost with its display on GDI and the keys of the original, or nothing at all. The
    // system cursor stays visible: the game draws none
    if AOptions.Headless then
    begin
      LPresenter := TGreedNoWindow.Create;
      LInput := LPresenter as IGreedInput;
      LSource := TGreedNoKeys.Create;
    end
    else
    begin
      LKeys := TGameHostKeyState.Create;
      LWindow := TGameHostFactory.CreateWindow(WINDOW_TITLE, LKeys as IGameHostEventSink, False);
      LHostWindow := TGreedHostWindow.Create(TGameHostFactory.CreateGdiDevice(LWindow), LKeys,
        function: Boolean
        begin
          Result := LWindow.Pump;
        end, WINDOW_TITLE, LFrameWidth, LFrameHeight, LScale);
      LPresenter := LHostWindow;
      LInput := LHostWindow;
      LSource := TGreedHostControls.Create(LKeys);
    end;
    if AOptions.ScriptPath <> '' then
      LScript.LoadFromFile(AOptions.ScriptPath);
    if AOptions.AutoPlay then
      AddAutoPlay(LScript, AOptions.MaxTics, AOptions.Seed);
    if LScript.Count > 0 then
      LSource := TGreedScriptControls.Create(LScript, LSource);

    LTime := TGreedPlayTime.Create;
    LTimeIntf := LTime;
    LTime.Headless := AOptions.Headless;
    if AOptions.Headless then
      LClock := TManualClock.Create
    else
      LClock := TClockFactory.CreateClock(nil);
    LTime.RealClock := LClock;

    // the sound: the mixer of the game on the PCM output of the host; without a device the game is silent
    LDevice := TGreedPcmMixer.Create(GREED_PCM_DEFAULT_RATE, TGreedTrackerSongDecoder.Create,
      TLogFactory.CreateLog(nil, nil));
    LMixer := LDevice as IGreedPcmRenderer;
    LDevice.Initialize;
    LDeviceOpen := False;
    if not AOptions.Headless then
    begin
      LAudio := TGreedHostAudio.Create(TGameHostFactory.CreatePcmOutput, LMixer);
      LAudioSource := LAudio;
      LDeviceOpen := LAudio.Open;
    end;
    LVolumes := TGreedSoundVolumes.Create;
    LMusicVolume := AOptions.MusicVolume;
    LSfxVolume := AOptions.SfxVolume;
    if (LMusicVolume >= 0) or (LSfxVolume >= 0) then
    begin
      if LMusicVolume < 0 then
        LMusicVolume := LVolumes.MusicVolume;
      if LSfxVolume < 0 then
        LSfxVolume := LVolumes.SfxVolume;
      LVolumes.SetVolumes(LMusicVolume, LSfxVolume);
    end;
    LEffects := TGreedSoundEffects.Create(LDevice, AArchive, LTime, LVolumes);
    LMusic := TGreedMusic.Create(LDevice, LFiles, LVolumes, LTime, False);

    LRandom := TGreedRandomTable.Create;
    LRandomIntf := LRandom;
    LRandom.Offset := AOptions.Seed;
    // the status bar, the weapon and the messages are drawn over the first person view; the view from above has
    // no HUD
    LHudView := nil;
    if AOptions.TopDown then
    begin
      LPlain := TGreedPlainView.Create(AArchive);
      LPlain.Echo := AOptions.EchoMessages;
      LViewIntf := LPlain;
      LMessages := LPlain;
      LLogged := LPlain.Messages;
    end
    else
    begin
      LHudView := TGreedHudView.Create(AArchive);
      LHudView.Echo := AOptions.EchoMessages;
      LViewIntf := LHudView;
      LMessages := LHudView;
      LLogged := LHudView.Messages;
    end;
    if AOptions.TopDown then
      LRendererFactory := TGreedTopDownGameRenderer.Create(TGreedTopDownRenderer.Create(
        NearestIndex(LPalette, 60, 60, 80), NearestIndex(LPalette, 240, 240, 240),
        NearestIndex(LPalette, 230, 200, 40), NearestIndex(LPalette, 240, 40, 40)))
    else
      LRendererFactory := TGreedGameRendererFactory.Create(AArchive);

    LGame := TGreedGame.Create(AArchive, TGreedFactory.CreateMapLoader(AArchive, LFiles), LRendererFactory,
      TGreedCommandState.Create(LSource), LEffects, LMusic, LRandomIntf,
      TGreedSaveGames.Create(TGreedSaveFolder.Create(GetCurrentDir), ggvDefault), LTime, LViewIntf,
      LMessages);
    if Assigned(LHudView) then
      LHudView.Attach(LGame);
    LTime.Game := LGame;
    LGame.LowResolution := AOptions.LowResolution;
    // the full game has three episodes that start at the maps 0, 8 and 16
    LDemo := ADemo;
    if AOptions.MapNumber >= FIRST_MAP_OF_GAME3 then
      LGame.SetEdition(LDemo, 3)
    else if AOptions.MapNumber >= FIRST_MAP_OF_GAME2 then
      LGame.SetEdition(LDemo, 2)
    else
      LGame.SetEdition(LDemo, 1);
    LLoop := TGreedGameLoop.Create(LGame, LPresenter, LInput, LClock, LColors, LFrameWidth, LFrameHeight);
    LLoop.FreeRunning := AOptions.Headless;
    LTime.Loop := LLoop;
    try
      LGame.NewGame(AOptions.MapNumber, AOptions.Character, AOptions.Difficulty);
      Result := LLoop.Run(AOptions.MaxTics);
      if AOptions.ShotPath <> '' then
      begin
        LImage.Width := LLoop.FrameBuffer.Width;
        LImage.Height := LLoop.FrameBuffer.Height;
        LImage.OriginX := 0;
        LImage.OriginY := 0;
        LImage.Pixels := LLoop.FrameBuffer.Pixels;
        LEncoder := TGreedPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client));
        TFile.WriteAllBytes(AOptions.ShotPath, LEncoder.Encode(LImage, LPalette, False));
      end;
      LStatistics := LMixer.Statistics;
      if AOptions.DumpPath <> '' then
      begin
        LDump := TStringList.Create;
        try
          TGreedGameDump.Write(LGame, LLoop.Tics, LLoop.Frames, LRandom.Offset, LDump);
          LDump.Add(Format('effects.started=%d', [LStatistics.EffectsStarted]));
          LDump.Add(Format('songs.started=%d', [LStatistics.SongsStarted]));
          LDump.Add(Format('messages=%d', [LLogged.Count]));
          for LIndex := 0 to LLogged.Count - 1 do
            LDump.Add(Format('message.%d=%s', [LIndex, LLogged[LIndex]]));
          LDump.SaveToFile(AOptions.DumpPath);
        finally
          LDump.Free;
        end;
      end;
    finally
      LStatistics := LMixer.Statistics;
      if AOptions.AudioStatistics then
      begin
        LIndex := 0;
        if Assigned(LAudio) then
          LIndex := LAudio.CompletedBuffers;
        Writeln(Format('Audio: device %s, buffers played %d, frames %d (with sound %d, with music %d), peak %d, ' +
          'clipped %d, effects started %d (refused %d, ended %d), songs started %d (refused %d)',
          [BoolToStr(LDeviceOpen, True), LIndex, LStatistics.FramesRendered,
          LStatistics.FramesWithSound, LStatistics.FramesWithMusic, LStatistics.Peak, LStatistics.ClippedSamples,
          LStatistics.EffectsStarted, LStatistics.EffectsRejected, LStatistics.EffectsEnded,
          LStatistics.SongsStarted, LStatistics.SongsRejected]));
      end;
      // the output asks the mixer from its thread: it is closed before the sounds go
      if Assigned(LAudio) then
        LAudio.Close;
      LEffects.StopAll;
      LTime.Loop := nil;
      LTime.Game := nil;
      FreeAndNil(LLoop);
      FreeAndNil(LGame);
      LEffects := nil;
      LMusic := nil;
      LDevice.Shutdown;
    end;
  finally
    LScript.Free;
    // the display draws in the window: its last references go before the window
    LInput := nil;
    LPresenter := nil;
    LWindow.Free;
  end;
end;

class function TGreedComposition.RunProgram(const AArchive: IGreedArchive; const AFolders: array of string;
  const ADataFolder: string; const AOptions: TGreedPlayOptions): Integer;
const
  HEADLESS_DEFAULT_TICS = 70 * 60 * 20;
var
  LPalette: TBytes;
  LFrameWidth, LFrameHeight, LScale, LIndex, LFirstMap, LMapLump: Integer;
  LDemo: Boolean;
  LFiles, LMovies: IGreedExternalFiles;
  LMovieFolders: TArray<string>;
  LKeys: IGameHostKeyState;
  LWindow: TGameHostWinWindow;
  LHostWindow: TGreedHostWindow;
  LPresenter: IGreedFramePresenter;
  LInput: IGreedInput;
  LShown: TGreedLastFramePresenter;
  LShownIntf: IGreedFramePresenter;
  LSource: IGreedCommandSource;
  LScript: TStringList;
  LScriptKeys: TGreedApplicationScript;
  LScriptIntf: IInterface;
  LKeyboards: TArray<IGreedKeyboard>;
  LListener: IGreedTicListener;
  LEncoder: IGreedImageEncoder;
  LTime: TGreedPlayTime;
  LTimeIntf: IInterface;
  LClock: IClock;
  LDevice: IGreedSoundDevice;
  LMixer: IGreedPcmRenderer;
  LAudio: TGreedHostAudio;
  LAudioSource: IInterface;
  LDeviceOpen: Boolean;
  LVolumes: IGreedSoundVolumes;
  LEffects: IGreedSoundEffects;
  LMusic: IGreedMusic;
  LRandom: TGreedRandomTable;
  LRandomIntf: IGreedRandom;
  LSettings: IGreedSettings;
  LStore: IGreedSettingsStore;
  LSaves: IGreedSaveGames;
  LHud: TGreedHudView;
  LHudIntf: IGreedGameView;
  LMessages: IGreedMessages;
  LScreenView: TGreedScreenView;
  LScreenViewIntf: IGreedGameView;
  LRendererFactory: IGreedGameRendererFactory;
  LGame: TGreedGame;
  LMenuHost: IGreedMenuHost;
  LIntroHost: IGreedIntroHost;
  LEpisodeHost: TGreedEpisodeHost;
  LEpisodeIntf: IInterface;
  LScreens: TGreedScreens;
  LApplication: TGreedApplication;
  LApplicationOptions: TGreedApplicationOptions;
  LStatistics: TGreedMixerStatistics;
  LImage: TGreedImage;
  LShotPalette: TBytes;
  LDump: TStringList;
  LMusicVolume, LSfxVolume: Integer;
begin
  if AOptions.TopDown then
    raise EGreedException.Create('Greed32: the view from above is only for -play');
  LPalette := TGreedPalette.FromLump(AArchive.ReadLump(AArchive.RequireIndexOf(GREED_LUMP_PALETTE)));
  if AOptions.LowResolution then
  begin
    LFrameWidth := 320;
    LFrameHeight := 200;
    LScale := 3;
  end
  else
  begin
    LFrameWidth := 640;
    LFrameHeight := 400;
    LScale := 1;
  end;
  // a demo has its maps in files next to the archive: its map lumps are empty
  LMapLump := AArchive.RequireIndexOf(GREED_LUMP_MAP) + 1;
  LDemo := (LMapLump < AArchive.LumpCount) and (AArchive.GetLumpSize(LMapLump) = 0);
  LFiles := TGreedFactory.CreateFolderFiles(AFolders);
  SetLength(LMovieFolders, Length(AFolders) * 2);
  for LIndex := 0 to High(AFolders) do
  begin
    LMovieFolders[LIndex * 2] := TPath.Combine(AFolders[LIndex], 'MOVIES');
    LMovieFolders[LIndex * 2 + 1] := AFolders[LIndex];
  end;
  LMovies := TGreedFactory.CreateFolderFiles(LMovieFolders);
  ForceDirectories(ADataFolder);
  LWindow := nil;
  LGame := nil;
  LScreens := nil;
  LApplication := nil;
  LAudio := nil;
  LScript := TStringList.Create;
  try
    if AOptions.Headless then
    begin
      LShown := TGreedLastFramePresenter.Create(TGreedNoWindow.Create);
      LShownIntf := LShown;
      LPresenter := LShownIntf;
      LInput := TGreedNoWindow.Create;
      LSource := TGreedNoKeys.Create;
    end
    else
    begin
      LKeys := TGameHostKeyState.Create;
      LWindow := TGameHostFactory.CreateWindow(WINDOW_TITLE, LKeys as IGameHostEventSink, False);
      LHostWindow := TGreedHostWindow.Create(TGameHostFactory.CreateGdiDevice(LWindow), LKeys,
        function: Boolean
        begin
          Result := LWindow.Pump;
        end, WINDOW_TITLE, LFrameWidth, LFrameHeight, LScale);
      LShown := TGreedLastFramePresenter.Create(LHostWindow);
      LShownIntf := LShown;
      LPresenter := LShownIntf;
      LInput := LHostWindow;
      LSource := TGreedHostControls.Create(LKeys);
      SetLength(LKeyboards, 1);
      LKeyboards[0] := TGreedHostKeyboard.Create(LKeys);
    end;
    if AOptions.ScriptPath <> '' then
      LScript.LoadFromFile(AOptions.ScriptPath);
    if AOptions.AutoPlay then
      AddAutoPlay(LScript, AOptions.MaxTics, AOptions.Seed);
    LListener := nil;
    if LScript.Count > 0 then
    begin
      LScriptKeys := TGreedApplicationScript.Create(LScript, LSource);
      LScriptIntf := LScriptKeys;
      LSource := LScriptKeys;
      SetLength(LKeyboards, Length(LKeyboards) + 1);
      LKeyboards[High(LKeyboards)] := LScriptKeys;
      LListener := LScriptKeys;
    end;
    LEncoder := TGreedPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client));
    if Length(AOptions.ShotTics) > 0 then
      LListener := TGreedShotTaker.Create(LShown, LListener, LEncoder, AOptions.ShotPath, AOptions.ShotTics);

    LTime := TGreedPlayTime.Create;
    LTimeIntf := LTime;
    LTime.Headless := AOptions.Headless;
    if AOptions.Headless then
      LClock := TManualClock.Create
    else
      LClock := TClockFactory.CreateClock(nil);
    LTime.RealClock := LClock;

    // the settings: xGreed.ini in the folder of the data of the program, then the volumes asked on the command line
    LSettings := TGreedSettings.Create;
    LStore := TGreedSettingsStore.Create(TGreedSaveFolder.Create(ADataFolder), GREED_SETTINGS_FILE);
    LStore.Load(LSettings, AOptions.Game);
    if AOptions.MusicVolume >= 0 then
      LSettings.SetInteger('musicvol', AOptions.MusicVolume);
    if AOptions.SfxVolume >= 0 then
      LSettings.SetInteger('sfxvol', AOptions.SfxVolume);

    // the sound: the mixer of the game on the PCM output of the host; without a device the game is silent
    LDevice := TGreedPcmMixer.Create(GREED_PCM_DEFAULT_RATE, TGreedTrackerSongDecoder.Create,
      TLogFactory.CreateLog(nil, nil));
    LMixer := LDevice as IGreedPcmRenderer;
    LDevice.Initialize;
    LDeviceOpen := False;
    if not AOptions.Headless then
    begin
      LAudio := TGreedHostAudio.Create(TGameHostFactory.CreatePcmOutput, LMixer);
      LAudioSource := LAudio;
      LDeviceOpen := LAudio.Open;
    end;
    LVolumes := TGreedSoundVolumes.Create;
    LMusicVolume := LSettings.GetInteger('musicvol');
    LSfxVolume := LSettings.GetInteger('sfxvol');
    LVolumes.SetVolumes(LMusicVolume, LSfxVolume);
    LEffects := TGreedSoundEffects.Create(LDevice, AArchive, LTime, LVolumes);
    LMusic := TGreedMusic.Create(LDevice, LFiles, LVolumes, LTime, False);

    LRandom := TGreedRandomTable.Create;
    LRandomIntf := LRandom;
    LRandom.Offset := AOptions.Seed;
    LHud := TGreedHudView.Create(AArchive);
    LHud.Echo := AOptions.EchoMessages;
    LHudIntf := LHud;
    LMessages := LHud;
    LScreenView := TGreedScreenView.Create(LHudIntf);
    LScreenViewIntf := LScreenView;
    LRendererFactory := TGreedGameRendererFactory.Create(AArchive);
    LSaves := TGreedSaveGames.Create(TGreedSaveFolder.Create(ADataFolder), LSettings.GetGameVariant);

    LGame := TGreedGame.Create(AArchive, TGreedFactory.CreateMapLoader(AArchive, LFiles), LRendererFactory,
      TGreedCommandState.Create(LSource), LEffects, LMusic, LRandomIntf, LSaves, LTime, LScreenViewIntf, LMessages);
    LHud.Attach(LGame);
    LHud.SetSize(LSettings.GetInteger('screensize'));
    LTime.Game := LGame;
    LGame.LowResolution := AOptions.LowResolution;
    LGame.SetEdition(LDemo, LSettings.Episode);
    LGame.Violence := LSettings.GetBoolean('violence');
    LGame.AmbientLight := LSettings.GetInteger('ambientlight');
    LGame.CameraDelay := LSettings.GetInteger('camdelay');

    LMenuHost := TGreedMenuHost.Create(LGame, LSettings, LStore, LHud);
    LIntroHost := TGreedIntroHost.Create(LGame);
    LEpisodeHost := TGreedEpisodeHost.Create(LGame);
    LEpisodeIntf := LEpisodeHost;
    LScreens := TGreedScreens.Create(AArchive, LSettings, LVolumes, LSaves, LMovies, LMenuHost, LIntroHost,
      LEpisodeHost, LEpisodeHost, LDemo, LSettings.GetGameVariant);

    LApplicationOptions := TGreedApplicationOptions.Standard;
    LApplicationOptions.FreeRunning := AOptions.Headless;
    LApplicationOptions.MaxTics := AOptions.MaxTics;
    if AOptions.Headless and (LApplicationOptions.MaxTics = 0) then
      LApplicationOptions.MaxTics := HEADLESS_DEFAULT_TICS;
    LApplicationOptions.SkipIntro := AOptions.SkipIntro;
    LApplicationOptions.NoBriefing := AOptions.NoBriefing;
    LApplicationOptions.Character := AOptions.Character;
    LApplicationOptions.Difficulty := AOptions.Difficulty;
    // the first map of the episode that is played (the demo has one episode)
    LFirstMap := 0;
    if not LDemo then
      case LSettings.Episode of
        2: LFirstMap := FIRST_MAP_OF_GAME2;
        3: LFirstMap := FIRST_MAP_OF_GAME3;
      end;
    if AOptions.MapNumber >= 0 then
      LFirstMap := AOptions.MapNumber;
    LApplicationOptions.StartMap := LFirstMap;
    LApplication := TGreedApplication.Create(LGame, LScreens, LSettings, LStore, LPresenter, LInput, LClock,
      LKeyboards, LListener, LMovies, LFrameWidth, LFrameHeight, LApplicationOptions);
    LTime.Application := LApplication;
    LScreenView.Screens := LApplication;
    try
      Result := LApplication.Run;
      if AOptions.ShotPath <> '' then
        if LShown.Snapshot(LImage, LShotPalette) then
          TFile.WriteAllBytes(AOptions.ShotPath, LEncoder.Encode(LImage, LShotPalette, False));
      LStatistics := LMixer.Statistics;
      if AOptions.DumpPath <> '' then
      begin
        LDump := TStringList.Create;
        try
          LApplication.Describe(LDump);
          TGreedGameDump.Write(LGame, LGame.State.TimeCount, LApplication.Frames, LRandom.Offset, LDump);
          LDump.Add(Format('effects.started=%d', [LStatistics.EffectsStarted]));
          LDump.Add(Format('songs.started=%d', [LStatistics.SongsStarted]));
          LDump.Add(Format('messages=%d', [LHud.Messages.Count]));
          for LIndex := 0 to LHud.Messages.Count - 1 do
            LDump.Add(Format('message.%d=%s', [LIndex, LHud.Messages[LIndex]]));
          LDump.SaveToFile(AOptions.DumpPath);
        finally
          LDump.Free;
        end;
      end;
    finally
      if AOptions.AudioStatistics then
      begin
        LStatistics := LMixer.Statistics;
        LIndex := 0;
        if Assigned(LAudio) then
          LIndex := LAudio.CompletedBuffers;
        Writeln(Format('Audio: device %s, buffers played %d, frames %d (with sound %d, with music %d), peak %d, ' +
          'clipped %d, effects started %d (refused %d, ended %d), songs started %d (refused %d)',
          [BoolToStr(LDeviceOpen, True), LIndex, LStatistics.FramesRendered,
          LStatistics.FramesWithSound, LStatistics.FramesWithMusic, LStatistics.Peak, LStatistics.ClippedSamples,
          LStatistics.EffectsStarted, LStatistics.EffectsRejected, LStatistics.EffectsEnded,
          LStatistics.SongsStarted, LStatistics.SongsRejected]));
      end;
      // the output asks the mixer from its thread: it is closed before the sounds go
      if Assigned(LAudio) then
        LAudio.Close;
      LEffects.StopAll;
      LScreenView.Screens := nil;
      LTime.Application := nil;
      LTime.Game := nil;
      FreeAndNil(LApplication);
      FreeAndNil(LScreens);
      LMenuHost := nil;
      LIntroHost := nil;
      LEpisodeIntf := nil;
      FreeAndNil(LGame);
      LEffects := nil;
      LMusic := nil;
      LDevice.Shutdown;
    end;
  finally
    LScript.Free;
    // the display draws in the window: its last references go before the window
    LInput := nil;
    LPresenter := nil;
    LShownIntf := nil;
    LWindow.Free;
  end;
end;

end.
