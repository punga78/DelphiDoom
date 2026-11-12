{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - the game in a window, or driven by a script             }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  what main and InitGame of kd_main.c do around the game                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameRunner;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes;

type
  /// <summary>How Keen32 runs the game</summary>
  TKeenRunOptions = record
    /// <summary>Where KDREAMS.EGA, .MAP, .AUD, .CMP and the .KDR headers are</summary>
    Folders: TArray<string>;
    /// <summary>Where KDREAMS.CFG and the saved games go; empty for the first data folder</summary>
    SaveFolder: string;
    /// <summary>A script of keys (TKeenScript): the game runs without a window and without the clock of the machine</summary>
    ScriptFile: string;
    /// <summary>Where the pictures of the "shot" commands of the script go; empty for the current folder</summary>
    ShotFolder: string;
    /// <summary>The size of a pixel of the game in the window</summary>
    Scale: Integer;
    /// <summary>False leaves the sound device of the machine closed</summary>
    UseSoundDevice: Boolean;
    /// <summary>The window closes itself after this many seconds; 0 for never</summary>
    QuitAfterSeconds: Double;
    /// <summary>The "comp" parameter of the original</summary>
    Compatibility: Boolean;
    /// <summary>Starts a game at this level without the start screens (the warp of the debug keys); -1 for the start screens</summary>
    StartLevel: Integer;
    /// <summary>Writes what the game and the mixer did when the program ends</summary>
    Report: Boolean;
    class function Defaults: TKeenRunOptions; static;
  end;

  /// <summary>
  ///   Runs the game from the start screens until the player leaves. In a window: the picture of the EGA is shown
  ///   at each tic of the clock (70 a second), the keys of the window go to the input manager, the sound goes to
  ///   waveOut. With a script: no window, a tic for each wait of the game, the keys and the pictures of the
  ///   script. This unit is part of the composition root of Keen32: it knows the classes
  /// </summary>
  TKeenGameRunner = class
  public
    /// <summary>The exit code of the program: 0, or 3 when a script ended and the game was still waiting</summary>
    class function Run(const AOptions: TKeenRunOptions): Integer; static;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.Factory,
  DelphiDoom.Keen.GameFactory, DelphiDoom.Keen.HelpFiles, DelphiDoom.Keen.UserFiles, DelphiDoom.Keen.ScreenPicture,
  DelphiDoom.Keen.Script, DelphiDoom.Keen.ScriptedHost, DelphiDoom.Keen.SoundJournal, DelphiDoom.Keen.PngEncoder, DelphiDoom.Keen.Composition,
  DelphiDoom.Keen.HostClock, DelphiDoom.Keen.HostEvents, DelphiDoom.Keen.UserTypes, DelphiDoom.Clock.Intf,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Factory,
  DelphiDoom.GameHost.Win.Window, DelphiDoom.Platform.Intf, DelphiDoom.Platform.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.Png.IndexedEncoder;

const
  WINDOW_TITLE = 'Commander Keen in Keen Dreams';
  LIBRARY_FILE_NAME = 'KDREAMS.CMP';
  SNoLibrary = 'Keen: Couldn''t find KDREAMS.CMP';
  /// <summary>The frames of sound of a tic of the game (44100 / 70)</summary>
  AUDIO_FRAMES_PER_TIC = 630;

type
  /// <summary>The parts of a run that the two ways of running share</summary>
  TRun = class
  public
    Options: TKeenRunOptions;
    Files: IKeenDataFiles;
    Data: IKeenGameData;
    Audio: TKeenAudioSet;
    Game: TKeenGameSet;
    Journal: TKeenSoundJournal;
    JournalKeeper: IKeenSoundManager;
    procedure OpenData;
    function Parts(const AClock: IKeenClock; const AInput: IKeenInput; ARandomize: Boolean): TKeenGameParts;
    procedure Play;
    function ReportLine: string;
    destructor Destroy; override;
  end;

{ TKeenRunOptions }

class function TKeenRunOptions.Defaults: TKeenRunOptions;
begin
  Result := Default(TKeenRunOptions);
  Result.Scale := 3;
  Result.UseSoundDevice := True;
  Result.StartLevel := -1;
end;

{ TRun }

destructor TRun.Destroy;
begin
  Game.Free;
  if Assigned(Audio.Host) then
    Audio.Host.Close;
  inherited Destroy;
end;

procedure TRun.OpenData;
begin
  Files := TKeenFactory.CreateFolderFiles(Options.Folders);
  Data := TKeenFactory.OpenGameData(Files);
  if not Files.Exists(LIBRARY_FILE_NAME) then
    raise EKeenFileNotFoundException.Create(SNoLibrary);
end;

function TRun.Parts(const AClock: IKeenClock; const AInput: IKeenInput; ARandomize: Boolean): TKeenGameParts;
var
  LSaveFolder: string;
begin
  LSaveFolder := Options.SaveFolder;
  if LSaveFolder = '' then
    LSaveFolder := Options.Folders[0];
  Result := Default(TKeenGameParts);
  Result.Data := Data;
  Result.Clock := AClock;
  Result.Input := AInput;
  // the game asks the sounds through a journal, for the report
  Journal := TKeenSoundJournal.Create(Audio.Sound);
  JournalKeeper := Journal;
  Result.Sound := JournalKeeper;
  Result.Files := TKeenFolderUserFiles.Create(TPlatformFactory.CreateFileStore, LSaveFolder);
  Result.Help := TKeenHelpFiles.Create(Files);
  Result.Title := TKeenGameFactory.LoadTitle(Files.ReadAll(LIBRARY_FILE_NAME));
  Result.Compatibility := Options.Compatibility;
  Result.Randomize := ARandomize;
  // the hundredths of a second of the time of the day, as the clock of the DOS gives them to US_InitRndT
  Result.RandomTime := Integer(Trunc(Frac(Now) * 8640000) mod 256);
end;

procedure TRun.Play;
begin
  // US_Startup and US_Setup: the configuration and the saved games
  Game.LoadConfig;
  if Options.StartLevel >= 0 then
  begin
    // a game from a level, as the warp of the debug keys does
    Game.Game.NewGame;
    Game.Play.GameState^.MapOn := Options.StartLevel;
    Game.UserState.RestartGame := kgdNormal;
    Game.Game.GameLoop;
  end;
  Game.DemoLoop.Run;
end;

function TRun.ReportLine: string;
var
  LState: PKeenGameState;
  LStatistics: TKeenAudioStatistics;
  LDone: Integer;
  LIndex: Integer;
begin
  LState := Game.Play.GameState;
  LStatistics := Audio.Mixer.Statistics;
  LDone := 0;
  for LIndex := 1 to KEEN_GAMELEVELS - 1 do
    if LState^.LevelDone[LIndex] then
      Inc(LDone);
  Result := Format('game: map %d (loaded %d), score %d, lives %d, flower powers %d, bombs %d, keys %d, levels done %d, ' +
    'actors %d; sound: mode %d, services %d, frames %d, audible frames %d, peak %d, buffers played %d; sounds asked: %s',
    [LState^.MapOn, Game.Play.MapOn, LState^.Score, LState^.Lives, LState^.FlowerPowers, LState^.BoobusBombs,
     LState^.Keys, LDone, Game.Objects.Count, Ord(Game.Sound.Mode), LStatistics.Services, LStatistics.Frames,
     LStatistics.AudibleFrames, LStatistics.Peak, Audio.Host.CompletedBuffers, Journal.Summary]);
end;

function RunWindow(ARun: TRun): Integer;
var
  LClock: IClock;
  LHostClock: TKeenHostClock;
  LGameClock: IKeenClock;
  LEvents: TKeenHostEvents;
  LEventsIntf: IInterface;
  LWindow: TGameHostWinWindow;
  LDevice: IGameHostVideoDevice;
  LInput: IKeenInput;
  LLastTic: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LYield: TProc;
  LPalette: TGameHostPalette;
  LPictures: Integer;
begin
  Result := 0;
  LPictures := 0;
  FillChar(LPalette, SizeOf(LPalette), 0);
  LClock := TKeenComposition.CreateClock;
  LHostClock := TKeenHostClock.Create(LClock);
  LGameClock := LHostClock;
  LEvents := TKeenHostEvents.Create;
  LEventsIntf := LEvents;
  LWindow := TGameHostFactory.CreateWindow(WINDOW_TITLE, LEvents, False);
  try
    LDevice := TGameHostFactory.CreateGdiDevice(LWindow);
    LDevice.SetTitle(WINDOW_TITLE);
    LWidth := KEEN_DISPLAY_WIDTH * ARun.Options.Scale;
    LHeight := KEEN_DISPLAY_HEIGHT * ARun.Options.Scale;
    LDevice.SetMode(LWidth, LHeight, False);
    LInput := TKeenFactory.CreateInput(LGameClock, nil, nil, nil);
    LEvents.Keys :=
      procedure(AByte: Byte)
      begin
        LInput.KeyService(AByte);
      end;
    LLastTic := -1;
    // what every loop of the game that waits does: the messages of the window, the sound without a device, the
    // picture when a tic went by, a short sleep
    LYield :=
      procedure
      var
        LTic: Integer;
        LColors: TKeenScreenColors;
        LIndex: Integer;
      begin
        if (not LWindow.Pump) or LEvents.Quit then
          raise EKeenQuitException.Create(SKeenQuit);
        if (ARun.Options.QuitAfterSeconds > 0) and (LClock.Seconds >= ARun.Options.QuitAfterSeconds) then
          raise EKeenQuitException.Create(SKeenQuit);
        ARun.Audio.Host.Pump;
        LTic := LClock.Steps(KEEN_TICKBASE);
        if (LTic <> LLastTic) and Assigned(ARun.Game) then
        begin
          LLastTic := LTic;
          Inc(LPictures);
        LColors := TKeenScreenPicture.Colors(ARun.Game.Fader.Registers);
        for LIndex := 0 to 15 do
        begin
          LPalette[LIndex].Red := Byte(LColors[LIndex] shr 16);
          LPalette[LIndex].Green := Byte(LColors[LIndex] shr 8);
          LPalette[LIndex].Blue := Byte(LColors[LIndex]);
        end;
        LDevice.Present(TKeenScreenPicture.Capture(ARun.Game.Video).Pixels, KEEN_DISPLAY_WIDTH, KEEN_DISPLAY_HEIGHT,
          LPalette);
        end;
        LClock.Sleep(1);
      end;
    LHostClock.OnIdle := LYield;
    ARun.Audio := TKeenComposition.CreateAudio(ARun.Data, LClock, ARun.Options.UseSoundDevice, LYield);
    ARun.Game := TKeenGameFactory.CreateGame(ARun.Parts(LGameClock, LInput, True));
    ARun.Game.Buffered.SetUpdateHook(LYield);
    ARun.Audio.Host.Open;
    try
      try
        ARun.Play;
      except
        // leaving the game: the control panel, the close box of the window, the time that was given
        on E: EKeenQuitException do
          Result := 0;
      end;
      // US_Shutdown: the configuration is written when the program ends
      ARun.Game.SaveConfig;
      if ARun.Options.Report then
        Writeln(Format('window: %d pictures in %.1f seconds; ', [LPictures, LClock.Seconds],
          TFormatSettings.Invariant) + ARun.ReportLine);
    finally
      ARun.Audio.Host.Close;
      ARun.Game.Buffered.SetUpdateHook(nil);
      LHostClock.OnIdle := nil;
      LEvents.Keys := nil;
      FreeAndNil(ARun.Game);
    end;
  finally
    // the display draws in the window: it goes before the window
    LDevice := nil;
    LWindow.Free;
  end;
end;

function RunScript(ARun: TRun): Integer;
var
  LHost: TKeenScriptedHost;
  LGameClock: IKeenClock;
  LInput: IKeenInput;
  LScratch: TBytes;
  LEncoder: IKeenImageEncoder;
  LStore: IFileStore;
  LShots: Integer;
begin
  Result := 0;
  LShots := 0;
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse(TFile.ReadAllText(ARun.Options.ScriptFile)));
  LGameClock := LHost;
  LInput := TKeenFactory.CreateInput(LGameClock, nil, nil, nil);
  LEncoder := TKeenPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client));
  LStore := TPlatformFactory.CreateFileStore;
  SetLength(LScratch, AUDIO_FRAMES_PER_TIC * 4);
  // the sound has no device and no clock: a step of the script is a tic of sound
  ARun.Audio := TKeenComposition.CreateAudio(ARun.Data, nil, False,
    procedure
    begin
      LHost.Step;
    end);
  ARun.Game := TKeenGameFactory.CreateGame(ARun.Parts(LGameClock, LInput, False));
  LHost.Keys :=
    procedure(AByte: Byte)
    begin
      LInput.KeyService(AByte);
    end;
  LHost.OnStep :=
    procedure
    begin
      ARun.Audio.Mixer.Render(@LScratch[0], Length(LScratch));
    end;
  LHost.OnShot :=
    procedure(AName: string)
    var
      LBytes: TBytes;
      LPath: string;
    begin
      // the colors of a picture are the 16 of the game, whatever the fade is at
      LBytes := LEncoder.Encode(TKeenScreenPicture.Capture(ARun.Game.Video));
      LPath := AName;
      if ARun.Options.ShotFolder <> '' then
        LPath := TPath.Combine(ARun.Options.ShotFolder, AName);
      if not LStore.Write(LPath, @LBytes[0], Length(LBytes)) then
        raise EKeenException.CreateFmt(SKeenFileNotWritten, [LPath]);
      Inc(LShots);
    end;
  ARun.Game.Buffered.SetUpdateHook(
    procedure
    begin
      LHost.Step;
    end);
  try
    try
      ARun.Play;
    except
      on E: EKeenQuitException do
        Result := 0;
      on E: EKeenScriptEndedException do
      begin
        Writeln(ErrOutput, E.Message);
        Result := 3;
      end;
    end;
    if Result = 0 then
      ARun.Game.SaveConfig;
    if ARun.Options.Report then
      Writeln(Format('script: %d steps, %d pictures; ', [LHost.Steps, LShots]) + ARun.ReportLine);
  finally
    ARun.Game.Buffered.SetUpdateHook(nil);
    LHost.Keys := nil;
    LHost.OnStep := nil;
    LHost.OnShot := nil;
    FreeAndNil(ARun.Game);
  end;
end;

{ TKeenGameRunner }

class function TKeenGameRunner.Run(const AOptions: TKeenRunOptions): Integer;
var
  LRun: TRun;
begin
  LRun := TRun.Create;
  try
    LRun.Options := AOptions;
    if LRun.Options.Scale < 1 then
      LRun.Options.Scale := 1;
    LRun.OpenData;
    if LRun.Options.ScriptFile <> '' then
      Result := RunScript(LRun)
    else
      Result := RunWindow(LRun);
  finally
    LRun.Free;
  end;
end;

end.
