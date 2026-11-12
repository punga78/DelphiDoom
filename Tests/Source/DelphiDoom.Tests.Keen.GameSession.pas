{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - whole games on the data of the  }
{  shareware, driven by the keys of a script                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameSession;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.GameFactory,
  DelphiDoom.Keen.ScriptedHost, DelphiDoom.Keen.SoundJournal, DelphiDoom.Tests.Keen.UiWorld;

type
  /// <summary>
  ///   The game as Keen32 puts it together for a script (the same factory), with the data of the shareware, a
  ///   sound manager that plays nothing, files in memory and the clock of the script. The tests that use it are
  ///   ignored on a machine without the data
  /// </summary>
  TKeenTestSession = class
  public
    Host: TKeenScriptedHost;
    Clock: IKeenClock;
    Input: IKeenInput;
    Journal: TKeenSoundJournal;
    Sound: IKeenSoundManager;
    Files: TUiFakeFiles;
    FilesIntf: IKeenUserFiles;
    Game: TKeenGameSet;
    /// <summary>Why the run ended: 'quit', 'script ended' or the class of another exception</summary>
    Ending: string;
    constructor Create(const AScript: string);
    destructor Destroy; override;
    /// <summary>The whole program: the start screens, then what the keys do</summary>
    procedure RunFromStart;
    /// <summary>A new game at a level, without the start screens; ALives is the number of lives</summary>
    procedure RunFromLevel(ALevel: Integer; ALives: Integer = 3);
    function ScreenHash: Cardinal;
    function State: PKeenGameState;
  end;

  [TestFixture]
  [Category('keen')]
  [Category('keen-game')]
  TTestKeenGameSession = class(TObject)
  strict private
    FSession: TKeenTestSession;
    procedure Make(const AScript: string);
    class function Repeated(const ALines: array of string; ACount: Integer): string; static;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DallAvvioIlPannelloDovrebbePortareAllaMappaDelMondo;
    [Test]
    procedure DallaMappaDelMondoDovrebbeEntrareNelPrimoLivello;
    [Test]
    procedure NelLivelloKeenDovrebbeCamminareESaltare;
    [Test]
    procedure DopoLaMorteDovrebbePotereTornareAllaMappa;
    [Test]
    procedure UnFioreLanciatoDovrebbeTrasformareUnNemico;
    [Test]
    procedure LoSpazioDovrebbeAprireLaFinestraDelloStato;
    [Test]
    procedure IlTruccoDelSaltoDiLivelloDovrebbeCaricareUnAltroLivello;
    [Test]
    procedure UnaPartitaSalvataDovrebbeTornareComEraQuandoVieneCaricata;
    [Test]
    procedure SenzaViteDovrebbeFinireLaPartitaETornareAlTitolo;
    [Test]
    procedure LaStessaPartitaDovrebbeDareSempreLoStessoRisultato;
    [Test]
    procedure IlPannelloInGiocoDovrebbeCambiareIlSuonoERiprendere;
    [Test]
    procedure LaConfigurazioneDovrebbeEssereScrittaERiletta;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.Script, DelphiDoom.Keen.HelpFiles, DelphiDoom.Keen.SaveSlots,
  DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.ScreenPicture, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Tests.Keen.RealData, DelphiDoom.Tests.Keen.VideoFakes, DelphiDoom.Tests.Shared.Skip;

type
  /// <summary>A sound device that is always silent: a sound ends as soon as it is asked for</summary>
  TSilentSound = class(TInterfacedObject, IKeenSoundManager)
  strict private
    FMode: TKeenSoundMode;
  public
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
    function AdLibPresent: Boolean;
    function TrySetMode(AMode: TKeenSoundMode): Boolean;
    procedure SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
  end;

{ TSilentSound }

function TSilentSound.GetMode: TKeenSoundMode;
begin
  Result := FMode;
end;

procedure TSilentSound.SetMode(AMode: TKeenSoundMode);
begin
  FMode := AMode;
end;

procedure TSilentSound.PlaySound(ASound: Integer);
begin
end;

procedure TSilentSound.StopSound;
begin
end;

function TSilentSound.SoundPlaying: Integer;
begin
  Result := 0;
end;

procedure TSilentSound.Service;
begin
end;

procedure TSilentSound.WaitSoundDone;
begin
end;

function TSilentSound.AdLibPresent: Boolean;
begin
  Result := True;
end;

function TSilentSound.TrySetMode(AMode: TKeenSoundMode): Boolean;
begin
  FMode := AMode;
  Result := True;
end;

procedure TSilentSound.SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
begin
  if AGotIt then
    FMode := AMode
  else
    FMode := ksmAdLib;
end;

{ TKeenTestSession }

constructor TKeenTestSession.Create(const AScript: string);
var
  LFiles: IKeenDataFiles;
  LParts: TKeenGameParts;
  LHost: TKeenScriptedHost;
  LInput: IKeenInput;
begin
  inherited Create;
  LFiles := TKeenRealData.OpenFiles;
  if not Assigned(LFiles) or not LFiles.Exists('KDREAMS.CMP') then
    TTestSkip.Ignore('i file dello shareware di Keen Dreams non sono su questa macchina');
  Host := TKeenScriptedHost.Create(TKeenScript.Parse(AScript));
  Clock := Host;
  Input := TKeenFactory.CreateInput(Clock, nil, nil, nil);
  Journal := TKeenSoundJournal.Create(TSilentSound.Create);
  Sound := Journal;
  Files := TUiFakeFiles.Create;
  FilesIntf := Files;
  LParts := Default(TKeenGameParts);
  LParts.Data := TKeenFactory.OpenGameData(LFiles);
  LParts.Clock := Clock;
  LParts.Input := Input;
  LParts.Sound := Sound;
  LParts.Files := FilesIntf;
  LParts.Help := TKeenHelpFiles.Create(LFiles);
  LParts.Title := TKeenGameFactory.LoadTitle(LFiles.ReadAll('KDREAMS.CMP'));
  Game := TKeenGameFactory.CreateGame(LParts);
  LHost := Host;
  LInput := Input;
  Host.Keys :=
    procedure(AByte: Byte)
    begin
      LInput.KeyService(AByte);
    end;
  Game.Buffered.SetUpdateHook(
    procedure
    begin
      LHost.Step;
    end);
end;

destructor TKeenTestSession.Destroy;
begin
  if Assigned(Host) then
    Host.Keys := nil;
  Game.Free;
  inherited Destroy;
end;

procedure TKeenTestSession.RunFromStart;
begin
  try
    Game.LoadConfig;
    Game.DemoLoop.Run;
  except
    on E: EKeenQuitException do
      Ending := 'quit';
    on E: EKeenScriptEndedException do
      Ending := 'script ended';
  end;
end;

procedure TKeenTestSession.RunFromLevel(ALevel: Integer; ALives: Integer);
begin
  try
    Game.LoadConfig;
    Game.Game.NewGame;
    Game.Play.GameState^.MapOn := ALevel;
    Game.Play.GameState^.Lives := ALives;
    Game.UserState.RestartGame := kgdNormal;
    Game.Game.GameLoop;
    Game.DemoLoop.Run;
  except
    on E: EKeenQuitException do
      Ending := 'quit';
    on E: EKeenScriptEndedException do
      Ending := 'script ended';
  end;
end;

function TKeenTestSession.ScreenHash: Cardinal;
begin
  Result := TFakeKeenPixels.ImageHash(TKeenScreenPicture.Capture(Game.Video));
end;

function TKeenTestSession.State: PKeenGameState;
begin
  Result := Game.Play.GameState;
end;

{ TTestKeenGameSession }

procedure TTestKeenGameSession.Make(const AScript: string);
begin
  FSession := TKeenTestSession.Create(AScript);
end;

procedure TTestKeenGameSession.TearDown;
begin
  FreeAndNil(FSession);
end;

class function TTestKeenGameSession.Repeated(const ALines: array of string; ACount: Integer): string;
var
  LBuilder: TStringBuilder;
  LIndex: Integer;
  LLine: string;
begin
  LBuilder := TStringBuilder.Create;
  try
    for LIndex := 1 to ACount do
      for LLine in ALines do
        LBuilder.Append(LLine).Append(#10);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestKeenGameSession.DallAvvioIlPannelloDovrebbePortareAllaMappaDelMondo;
begin
  // the title, a key for the control panel, F5 and return for a new game in normal mode, then the world map
  Make('wait 30'#10'press space'#10'wait 40'#10'press f5'#10'wait 40'#10'press enter'#10'wait 300'#10'quit');
  FSession.RunFromStart;
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreEqual(Ord(keNotDone), Ord(FSession.Game.Play.PlayState), 'the script ended in the loop of the frames');
  Assert.AreEqual(0, FSession.Game.Play.MapOn, 'the world map');
  Assert.AreEqual(3, Integer(FSession.State^.Lives));
  Assert.AreEqual(0, FSession.State^.Score);
  Assert.AreEqual(20000, FSession.State^.NextExtra);
  Assert.AreEqual(Ord(kgdNormal), Integer(FSession.State^.Difficulty));
  Assert.AreEqual(Ord(kcKeen), Ord(FSession.Game.Objects.Player^.ObClass));
  Assert.AreEqual(2, FSession.Game.Objects.Count, 'Keen and the score box');
  Assert.IsFalse(FSession.Game.Fader.IsFaded, 'the level faded in');
end;

procedure TTestKeenGameSession.DallaMappaDelMondoDovrebbeEntrareNelPrimoLivello;
begin
  // a few steps to the left of the start and the jump button on the place of Horseradish Hill
  Make('wait 150'#10 + Repeated(['down left', 'wait 12', 'up left', 'press ctrl', 'wait 6'], 8) + 'wait 200'#10'quit');
  FSession.RunFromLevel(0);
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreEqual(1, FSession.Game.Play.MapOn, 'the level that is loaded');
  Assert.AreEqual(1, FSession.Journal.Count(KEEN_SND_ENTERLEVELSND));
  Assert.IsTrue(FSession.Game.Objects.Count > 10, 'the actors of the level');
  Assert.IsTrue(FSession.State^.WorldX <> 0, 'the place on the world map is remembered');
end;

procedure TTestKeenGameSession.NelLivelloKeenDovrebbeCamminareESaltare;
var
  LStartX: Integer;
  LSession: TKeenTestSession;
begin
  // to the left for 500 tics, a jump on the way
  Make('wait 150'#10'shot start'#10'down left'#10'wait 250'#10'press ctrl'#10'wait 250'#10'up left'#10'wait 30'#10'quit');
  LStartX := -1;
  LSession := FSession;
  FSession.Host.OnShot :=
    procedure(AName: string)
    begin
      LStartX := LSession.Game.Objects.Player^.X;
    end;
  FSession.RunFromLevel(1);
  FSession.Host.OnShot := nil;
  Assert.AreEqual('quit', FSession.Ending);
  Assert.IsTrue(LStartX > 0);
  Assert.IsTrue(Integer(FSession.Game.Objects.Player^.X) < LStartX - 16 * 256, 'Keen walked more than 16 tiles to the left');
  Assert.IsTrue(FSession.Journal.Count(KEEN_SND_JUMPSND) >= 1, 'Keen jumped');
  Assert.IsTrue(FSession.Game.Refresh.OriginXGlobal > 0, 'the view followed Keen');
end;

procedure TTestKeenGameSession.DopoLaMorteDovrebbePotereTornareAllaMappa;
begin
  // walking left Keen meets an enemy and dies; "exit to Tuberia" is the second line of the window
  Make('wait 150'#10'down left'#10'wait 1500'#10'up left'#10'wait 60'#10'press down'#10'wait 20'#10'press enter'#10 +
    'wait 300'#10'quit');
  FSession.RunFromLevel(1);
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreEqual(2, Integer(FSession.State^.Lives), 'a life is gone');
  Assert.AreEqual(1, FSession.Journal.Count(KEEN_SND_WAKEUPSND), 'the sound of the death of Keen');
  Assert.AreEqual(0, FSession.Game.Play.MapOn, 'back on the world map');
  Assert.IsFalse(FSession.State^.LevelDone[1], 'the level is not done');
end;

procedure TTestKeenGameSession.UnFioreLanciatoDovrebbeTrasformareUnNemico;
begin
  // F10 and I give 99 flower powers; then to the left, throwing every few steps
  Make('wait 150'#10'down f10'#10'wait 4'#10'down i'#10'wait 10'#10'up i'#10'up f10'#10'wait 20'#10'press enter'#10 +
    'wait 30'#10 + Repeated(['down left', 'wait 30', 'up left', 'wait 4', 'press alt', 'wait 20'], 60) + 'quit');
  FSession.RunFromLevel(1);
  Assert.AreEqual('quit', FSession.Ending);
  Assert.IsTrue(FSession.Journal.Count(KEEN_SND_THROWSND) > 10, 'flower powers were thrown');
  Assert.IsTrue(FSession.Journal.Count(KEEN_SND_FLOWERPOWERSND) >= 1, 'an enemy became a flower');
  Assert.IsTrue(FSession.Journal.Count(KEEN_SND_UNFLOWERPOWERSND) >= 1, 'and came back');
  Assert.AreEqual(99, Integer(FSession.State^.BoobusBombs), 'the cheat gave the bombs too');
  Assert.IsTrue(FSession.Journal.Count(KEEN_SND_GETPOWERSND) >= 1, 'a flower power was taken back from the ground');
  Assert.IsTrue(FSession.State^.Score > 0, 'and some points on the way');
end;

procedure TTestKeenGameSession.LoSpazioDovrebbeAprireLaFinestraDelloStato;
var
  LBefore: Cardinal;
  LDuring: Cardinal;
  LSession: TKeenTestSession;
begin
  Make('wait 150'#10'shot before'#10'press space'#10'wait 30'#10'shot during'#10'press enter'#10'wait 60'#10'shot after'#10'quit');
  LBefore := 0;
  LDuring := 0;
  LSession := FSession;
  FSession.Host.OnShot :=
    procedure(AName: string)
    begin
      if AName = 'before' then
        LBefore := LSession.ScreenHash
      else if AName = 'during' then
        LDuring := LSession.ScreenHash
      else
        Assert.AreNotEqual(LDuring, LSession.ScreenHash, 'the window is gone when a key closes it');
    end;
  FSession.RunFromLevel(1);
  FSession.Host.OnShot := nil;
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreNotEqual(Cardinal(0), LBefore);
  Assert.AreNotEqual(LBefore, LDuring, 'the status window is on the screen');
end;

procedure TTestKeenGameSession.IlTruccoDelSaltoDiLivelloDovrebbeCaricareUnAltroLivello;
begin
  // F10 and W ask for a level; "2" and return
  Make('wait 150'#10'down f10'#10'wait 4'#10'down w'#10'wait 10'#10'up w'#10'up f10'#10'wait 30'#10'type 2'#10 +
    'press enter'#10'wait 300'#10'quit');
  FSession.RunFromLevel(1);
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreEqual(2, FSession.Game.Play.MapOn);
  Assert.AreEqual(2, Integer(FSession.State^.MapOn));
end;

procedure TTestKeenGameSession.UnaPartitaSalvataDovrebbeTornareComEraQuandoVieneCaricata;
var
  LSavedX: Integer;
  LSavedScore: Integer;
  LSession: TKeenTestSession;
  LBytes: TBytes;
  LSlot: TKeenSaveSlot;
begin
  // F6 opens the saved games with the cursor on the first load button: right is its save button, return, a name.
  // Escape goes back to the level. Keen walks and takes things. F6 again: now the load button is enabled
  Make('wait 150'#10'press f6'#10'wait 40'#10'press right'#10'wait 30'#10'press enter'#10'wait 60'#10'type first'#10 +
    'press enter'#10'wait 60'#10'shot saved'#10'press esc'#10'wait 60'#10'down left'#10'wait 500'#10'up left'#10'wait 20'#10 +
    'shot moved'#10'press f6'#10'wait 40'#10'press enter'#10'wait 200'#10'press enter'#10'wait 60'#10'quit');
  LSavedX := -1;
  LSavedScore := -1;
  LSession := FSession;
  FSession.Host.OnShot :=
    procedure(AName: string)
    begin
      if AName = 'saved' then
      begin
        LSavedX := LSession.Game.Objects.Player^.X;
        LSavedScore := LSession.State^.Score;
      end
      else
      begin
        // the game went on after the save
        Assert.AreNotEqual(LSavedX, Integer(LSession.Game.Objects.Player^.X));
      end;
    end;
  FSession.RunFromLevel(1);
  FSession.Host.OnShot := nil;
  Assert.AreEqual('quit', FSession.Ending);
  Assert.IsTrue(FSession.FilesIntf.TryRead('SAVEGM0.KDR', LBytes), 'the file of the saved game');
  Assert.IsTrue(TKeenSaveSlots.TryDecodeHeader(LBytes, LSlot));
  Assert.AreEqual(AnsiString('first'), LSlot.Name);
  Assert.IsTrue(Length(LBytes) > 39 + 60 + 2 * 76);
  // loaded: the score and the place of Keen are the saved ones (the loaded game starts paused: return goes on)
  Assert.AreEqual(LSavedScore, FSession.State^.Score);
  Assert.AreEqual(LSavedX, Integer(FSession.Game.Objects.Player^.X));
  Assert.AreEqual(1, FSession.Game.Play.MapOn);
  Assert.IsFalse(FSession.Game.UserState.LoadedGame, 'the game loop took the loaded game');
end;

procedure TTestKeenGameSession.SenzaViteDovrebbeFinireLaPartitaETornareAlTitolo;
begin
  // with no lives left the first death is the end: "Game Over!", a key, the scores for five seconds, the title
  Make('wait 150'#10'down left'#10'wait 1500'#10'up left'#10'wait 100'#10'press enter'#10'wait 500'#10'quit');
  FSession.RunFromLevel(1, 0);
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreEqual(-1, Integer(FSession.State^.Lives));
  Assert.IsFalse(FSession.Game.UserState.InGame, 'the game is over');
  Assert.AreEqual(0, FSession.Game.Video.CrtcStart, 'the title is shown from the top of the memory');
end;

procedure TTestKeenGameSession.LaStessaPartitaDovrebbeDareSempreLoStessoRisultato;
var
  LScript: string;
  LHash: Cardinal;
  LScore: Integer;
  LX: Integer;
  LSteps: Integer;
  LSounds: string;
begin
  LScript := 'wait 150'#10 + Repeated(['down left', 'wait 40', 'press ctrl', 'wait 30', 'up left', 'wait 5'], 10) + 'quit';
  Make(LScript);
  FSession.RunFromLevel(1);
  LHash := FSession.ScreenHash;
  LScore := FSession.State^.Score;
  LX := FSession.Game.Objects.Player^.X;
  LSteps := FSession.Host.Steps;
  LSounds := FSession.Journal.Summary;
  FreeAndNil(FSession);
  Make(LScript);
  FSession.RunFromLevel(1);
  Assert.AreEqual(LHash, FSession.ScreenHash, 'the picture');
  Assert.AreEqual(LScore, FSession.State^.Score);
  Assert.AreEqual(LX, Integer(FSession.Game.Objects.Player^.X));
  Assert.AreEqual(LSteps, FSession.Host.Steps);
  Assert.AreEqual(LSounds, FSession.Journal.Summary);
end;

procedure TTestKeenGameSession.IlPannelloInGiocoDovrebbeCambiareIlSuonoERiprendere;
begin
  // F2 in a level opens the sound buttons; 2 is the PC speaker; escape goes back to the level
  Make('wait 150'#10'press f2'#10'wait 40'#10'press 2'#10'wait 30'#10'press esc'#10'wait 100'#10'quit');
  FSession.RunFromLevel(1);
  Assert.AreEqual('quit', FSession.Ending);
  Assert.AreEqual(Ord(ksmPC), Ord(FSession.Sound.Mode));
  Assert.AreEqual(Ord(keNotDone), Ord(FSession.Game.Play.PlayState), 'the level goes on');
  Assert.AreEqual(1, FSession.Game.Play.MapOn);
end;

procedure TTestKeenGameSession.LaConfigurazioneDovrebbeEssereScrittaERiletta;
var
  LBytes: TBytes;
  LScore: TKeenHighScore;
  LFirst: TKeenTestSession;
begin
  Make('wait 10'#10'quit');
  FSession.Game.LoadConfig;
  Assert.AreEqual(10000, FSession.Game.Scores.Scores[0].Score, 'no file: the defaults');
  LScore.Name := 'Billy';
  LScore.Score := 54321;
  LScore.Completed := 4;
  FSession.Game.Scores.Scores[0] := LScore;
  FSession.Sound.TrySetMode(ksmPC);
  Assert.IsTrue(FSession.Game.SaveConfig);
  Assert.IsTrue(FSession.FilesIntf.TryRead('KDREAMS.CFG', LBytes));
  Assert.AreEqual(656, Length(LBytes));
  // another game reads it
  LFirst := FSession;
  FSession := nil;
  try
    Make('wait 10'#10'quit');
    FSession.Files.Put('KDREAMS.CFG', LBytes);
    FSession.Game.LoadConfig;
    Assert.AreEqual(AnsiString('Billy'), FSession.Game.Scores.Scores[0].Name);
    Assert.AreEqual(54321, FSession.Game.Scores.Scores[0].Score);
    Assert.AreEqual(Ord(ksmPC), Ord(FSession.Sound.Mode));
    Assert.AreEqual(Ord(kctKeyboard1), Ord(FSession.Input.Controls[0]));
  finally
    LFirst.Free;
  end;
end;

end.
