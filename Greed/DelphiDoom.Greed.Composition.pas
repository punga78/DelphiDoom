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
    /// <summary>The options of a game that was not asked anything</summary>
    class function Standard: TGreedPlayOptions; static;
  end;

  /// <summary>
  ///   The one place of Greed32 that knows the classes behind the interfaces: the library of the greed port
  ///   (Libs\Greed) and the ones that it shares with the Doom engine (video palette, PNG, files). It does not
  ///   touch ComposeEngine nor TIdTechGeneration: Greed is not an id Tech 1 game
  /// </summary>
  TGreedComposition = class
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
  DelphiDoom.Greed.ScriptControls, DelphiDoom.Greed.PlainView, DelphiDoom.Greed.GameDump,
  DelphiDoom.Greed.HostAudio, DelphiDoom.Greed.TrackerSongDecoder, DelphiDoom.GameHost.Events.Intf,
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

// The commands of -autoplay as a script: the player walks, turns left for a while every 200 tics, uses what is
// in front of it and shoots
procedure AddAutoPlay(AScript: TStrings; AMaxTics: Integer);
const
  PERIOD = 200;
  DEFAULT_TICS = 70 * 60 * 10;
var
  LStart: Integer;
begin
  if AMaxTics <= 0 then
    AMaxTics := DEFAULT_TICS;
  LStart := 0;
  while LStart < AMaxTics do
  begin
    AScript.Add(Format('%d north down', [LStart + 1]));
    AScript.Add(Format('%d space down', [LStart + 31]));
    AScript.Add(Format('%d space up', [LStart + 35]));
    AScript.Add(Format('%d west down', [LStart + 61]));
    AScript.Add(Format('%d west up', [LStart + 91]));
    AScript.Add(Format('%d fire down', [LStart + 101]));
    AScript.Add(Format('%d fire up', [LStart + 141]));
    AScript.Add(Format('%d space down', [LStart + 151]));
    AScript.Add(Format('%d space up', [LStart + 155]));
    Inc(LStart, PERIOD);
  end;
end;

class function TGreedComposition.Play(const AArchive: IGreedArchive; const AFolders: array of string;
  const AOptions: TGreedPlayOptions): Integer;
var
  LPalette: TBytes;
  LColors: TGreedColors;
  LIndex, LFrameWidth, LFrameHeight, LScale, LMapLump: Integer;
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
  LView: TGreedPlainView;
  LViewIntf: IGreedGameView;
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
      AddAutoPlay(LScript, AOptions.MaxTics);
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
    LView := TGreedPlainView.Create(AArchive);
    LViewIntf := LView;
    LView.Echo := AOptions.EchoMessages;
    if AOptions.TopDown then
      LRendererFactory := TGreedTopDownGameRenderer.Create(TGreedTopDownRenderer.Create(
        NearestIndex(LPalette, 60, 60, 80), NearestIndex(LPalette, 240, 240, 240),
        NearestIndex(LPalette, 230, 200, 40), NearestIndex(LPalette, 240, 40, 40)))
    else
      LRendererFactory := TGreedGameRendererFactory.Create(AArchive);

    LGame := TGreedGame.Create(AArchive, TGreedFactory.CreateMapLoader(AArchive, LFiles), LRendererFactory,
      TGreedCommandState.Create(LSource), LEffects, LMusic, LRandomIntf,
      TGreedSaveGames.Create(TGreedSaveFolder.Create(GetCurrentDir), ggvDefault), LTime, LViewIntf,
      LView as IGreedMessages);
    LTime.Game := LGame;
    LGame.LowResolution := AOptions.LowResolution;
    // the maps of a demo are files next to the archive (their lumps are empty); the full game has three
    // episodes that start at the maps 0, 8 and 16
    LMapLump := AArchive.RequireIndexOf(GREED_LUMP_MAP) + AOptions.MapNumber + 1;
    LDemo := (LMapLump < AArchive.LumpCount) and (AArchive.GetLumpSize(LMapLump) = 0);
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
          LDump.Add(Format('messages=%d', [LView.Messages.Count]));
          for LIndex := 0 to LView.Messages.Count - 1 do
            LDump.Add(Format('message.%d=%s', [LIndex, LView.Messages[LIndex]]));
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

end.
