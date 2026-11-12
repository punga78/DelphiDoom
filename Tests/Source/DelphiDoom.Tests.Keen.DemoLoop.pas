{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the start screens, and the      }
{  small parts that bind the game together                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.DemoLoop;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.DemoLoop,
  DelphiDoom.Tests.Keen.UiWorld;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenDemoLoop = class(TObject)
  strict private
    FWorld: TKeenUiWorld;
    FLog: TStringList;
    FState: IKeenUserState;
    FLoop: TKeenDemoLoop;
    procedure Make(const AScript: string; APanelDiff: TKeenGameDiff; APanelLoads: Boolean; AGamesBeforeQuit: Integer);
    function Log: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure UnTastoSulTitoloDovrebbeAprireIlPannello;
    [Test]
    procedure SenzaTastiDovrebbeMostrareIlTitoloEPoiIPunteggi;
    [Test]
    procedure IlTitoloDovrebbeEssereDisegnatoInCimaAlloSchermo;
    [Test]
    procedure DopoIlPannelloLePagineDovrebberoTornareDoveErano;
    [Test]
    procedure UnaNuovaPartitaDovrebbeAzzerareIlGiocoEGiocarlo;
    [Test]
    procedure UnaPartitaCaricataNonDovrebbeEssereAzzerata;
    [Test]
    procedure DopoUnaPartitaDovrebbeTornareIlTitolo;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenLateBinding = class(TObject)
  public
    [Test]
    procedure LeFunzioniNonLegateDovrebberoDareEccezione;
    [Test]
    procedure LeFunzioniLegateDovrebberoPassareLeChiamate;
    [Test]
    procedure GliEventiNonLegatiDovrebberoDareEccezione;
    [Test]
    procedure GliEventiLegatiDovrebberoPassareLeChiamate;
    [Test]
    procedure ITestiDiAiutoDovrebberoVenireDaiFileDeiDati;
    [Test]
    procedure LImmagineDelloSchermoDovrebbeEssereQuellaDellaScheda;
    [Test]
    procedure IColoriDelloSchermoDovrebberoSeguireLaDissolvenza;
  end;

implementation

uses
  DelphiDoom.Keen.Shape, DelphiDoom.Keen.UserState, DelphiDoom.Keen.LateActions, DelphiDoom.Keen.LateEvents,
  DelphiDoom.Keen.HelpFiles, DelphiDoom.Keen.MemoryFiles, DelphiDoom.Keen.ScreenPicture,
  DelphiDoom.Keen.DisplayCapture, DelphiDoom.Keen.Fader, DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.EgaPalette,
  DelphiDoom.Tests.Keen.GameFakes;

type
  /// <summary>A control panel that does what the test says the first time it runs and then leaves the game</summary>
  TFakePanel = class(TInterfacedObject, IKeenControlPanel)
  strict private
    FLog: TStringList;
    FState: IKeenUserState;
    FDiff: TKeenGameDiff;
    FLoads: Boolean;
  public
    constructor Create(ALog: TStringList; const AState: IKeenUserState; ADiff: TKeenGameDiff; ALoads: Boolean);
    procedure Run;
    procedure SetHooks(const AHooks: IKeenGameHooks);
  end;

  TFakeGame = class(TInterfacedObject, IKeenGame)
  strict private
    FLog: TStringList;
    FGamesLeft: Integer;
  public
    constructor Create(ALog: TStringList; AGamesBeforeQuit: Integer);
    procedure NewGame;
    procedure GameLoop;
  end;

  TFakeScores = class(TInterfacedObject, IKeenHighScores)
  strict private
    FLog: TStringList;
  public
    constructor Create(ALog: TStringList);
    function GetScore(AIndex: Integer): TKeenHighScore;
    procedure SetScore(AIndex: Integer; const AValue: TKeenHighScore);
    function GetDirty: Boolean;
    function Insert(AScore: Integer; ACompleted: Word): Integer;
    procedure Display(AWhich: Integer);
    procedure Check(AScore: Integer; ACompleted: Word);
  end;

  TLogActions = class(TInterfacedObject, IKeenActions)
  public
    Log: string;
    procedure Think(AAction: Word; AObject: PKeenObject);
    procedure Contact(AAction: Word; AObject, AOther: PKeenObject);
    procedure React(AAction: Word; AObject: PKeenObject);
  end;

{ TFakePanel }

constructor TFakePanel.Create(ALog: TStringList; const AState: IKeenUserState; ADiff: TKeenGameDiff; ALoads: Boolean);
begin
  inherited Create;
  FLog := ALog;
  FState := AState;
  FDiff := ADiff;
  FLoads := ALoads;
end;

procedure TFakePanel.Run;
begin
  FLog.Add('panel');
  FState.RestartGame := FDiff;
  FState.LoadedGame := FLoads;
  // escape: nothing chosen, and the test has no more keys
  if (FDiff = kgdContinue) and not FLoads then
    raise EKeenQuitException.Create(SKeenQuit);
end;

procedure TFakePanel.SetHooks(const AHooks: IKeenGameHooks);
begin
end;

{ TFakeGame }

constructor TFakeGame.Create(ALog: TStringList; AGamesBeforeQuit: Integer);
begin
  inherited Create;
  FLog := ALog;
  FGamesLeft := AGamesBeforeQuit;
end;

procedure TFakeGame.NewGame;
begin
  FLog.Add('new');
end;

procedure TFakeGame.GameLoop;
begin
  FLog.Add('game');
  Dec(FGamesLeft);
  if FGamesLeft <= 0 then
    raise EKeenQuitException.Create(SKeenQuit);
end;

{ TFakeScores }

constructor TFakeScores.Create(ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

function TFakeScores.GetScore(AIndex: Integer): TKeenHighScore;
begin
  Result := Default(TKeenHighScore);
end;

procedure TFakeScores.SetScore(AIndex: Integer; const AValue: TKeenHighScore);
begin
end;

function TFakeScores.GetDirty: Boolean;
begin
  Result := False;
end;

function TFakeScores.Insert(AScore: Integer; ACompleted: Word): Integer;
begin
  Result := -1;
end;

procedure TFakeScores.Display(AWhich: Integer);
begin
  FLog.Add('scores ' + IntToStr(AWhich));
end;

procedure TFakeScores.Check(AScore: Integer; ACompleted: Word);
begin
end;

{ TLogActions }

procedure TLogActions.Think(AAction: Word; AObject: PKeenObject);
begin
  Log := Log + 'T' + IntToStr(AAction);
end;

procedure TLogActions.Contact(AAction: Word; AObject, AOther: PKeenObject);
begin
  Log := Log + 'C' + IntToStr(AAction);
end;

procedure TLogActions.React(AAction: Word; AObject: PKeenObject);
begin
  Log := Log + 'R' + IntToStr(AAction);
end;

{ TTestKeenDemoLoop }

procedure TTestKeenDemoLoop.Setup;
begin
  FLog := TStringList.Create;
end;

procedure TTestKeenDemoLoop.TearDown;
begin
  FLoop.Free;
  FLoop := nil;
  FState := nil;
  FreeAndNil(FWorld);
  FLog.Free;
end;

function TTestKeenDemoLoop.Log: string;
begin
  FLog.Delimiter := ',';
  FLog.StrictDelimiter := True;
  Result := FLog.DelimitedText;
end;

procedure TTestKeenDemoLoop.Make(const AScript: string; APanelDiff: TKeenGameDiff; APanelLoads: Boolean;
  AGamesBeforeQuit: Integer);
var
  LTitle: TKeenShape;
  LIndex: Integer;
begin
  FWorld := TKeenUiWorld.Create(nil, AScript);
  FState := TKeenUserState.Create;
  // a title of 320x200 in 4 planes, plain rows: the color 5 everywhere (the planes 0 and 2)
  LTitle := Default(TKeenShape);
  LTitle.Width := 320;
  LTitle.Height := 200;
  LTitle.Depth := 4;
  LTitle.BytesPerRow := 40;
  SetLength(LTitle.Data, 200 * 4 * 40);
  for LIndex := 0 to High(LTitle.Data) do
    if ((LIndex div 40) mod 4) in [0, 2] then
      LTitle.Data[LIndex] := $FF
    else
      LTitle.Data[LIndex] := 0;
  FLoop := TKeenDemoLoop.Create(LTitle, FWorld.Windows, FWorld.Input, TFakeScores.Create(FLog),
    TFakePanel.Create(FLog, FState, APanelDiff, APanelLoads), FState, TFakeGame.Create(FLog, AGamesBeforeQuit));
end;

procedure TTestKeenDemoLoop.UnTastoSulTitoloDovrebbeAprireIlPannello;
begin
  Make('wait 50'#10'press space', kgdNormal, False, 1);
  FLoop.RunAttract;
  Assert.AreEqual('panel', Log, 'the scores were not shown: the key came during the first title');
  Assert.IsTrue(FWorld.Host.Steps < KEEN_TITLE_TICS);
end;

procedure TTestKeenDemoLoop.SenzaTastiDovrebbeMostrareIlTitoloEPoiIPunteggi;
begin
  // the title for 4 seconds, again for 3, the scores for 6, then the title again: the key comes there
  Make(Format('wait %d'#10'press space', [KEEN_TITLE_TICS + KEEN_TITLE_AGAIN_TICS + KEEN_SCORES_TICS + 30]),
    kgdNormal, False, 1);
  FLoop.RunAttract;
  Assert.AreEqual('scores -1,panel', Log);
end;

procedure TTestKeenDemoLoop.IlTitoloDovrebbeEssereDisegnatoInCimaAlloSchermo;
begin
  Make('wait 50'#10'press space', kgdNormal, False, 1);
  // the picture during the title: taken by the panel, that runs right after the key
  FLoop.RunAttract;
  Assert.AreEqual(0, FWorld.Video.CrtcStart, 'the card shows the top of the memory');
  Assert.AreEqual(5, Integer(FWorld.Memory.ReadByte(0, 0) and 1) + Integer(FWorld.Memory.ReadByte(2, 0) and 1) * 4);
  Assert.AreEqual(5, Integer(TKeenDisplayCapture.CaptureVideo(FWorld.Video).Pixels[319 + 199 * 320]));
end;

procedure TTestKeenDemoLoop.DopoIlPannelloLePagineDovrebberoTornareDoveErano;
var
  LBuffer: Integer;
  LDisplay: Integer;
begin
  Make('wait 50'#10'press space', kgdNormal, False, 1);
  LBuffer := FWorld.Video.BufferOfs;
  LDisplay := FWorld.Video.DisplayOfs;
  FLoop.RunAttract;
  Assert.AreEqual(LBuffer, FWorld.Video.BufferOfs);
  Assert.AreEqual(LDisplay, FWorld.Video.DisplayOfs);
end;

procedure TTestKeenDemoLoop.UnaNuovaPartitaDovrebbeAzzerareIlGiocoEGiocarlo;
begin
  Make('wait 50'#10'press space', kgdEasy, False, 1);
  Assert.WillRaise(procedure begin FLoop.Run; end, EKeenQuitException);
  Assert.AreEqual('panel,new,game', Log);
end;

procedure TTestKeenDemoLoop.UnaPartitaCaricataNonDovrebbeEssereAzzerata;
begin
  Make('wait 50'#10'press space', kgdContinue, True, 1);
  Assert.WillRaise(procedure begin FLoop.Run; end, EKeenQuitException);
  Assert.AreEqual('panel,game', Log);
end;

procedure TTestKeenDemoLoop.DopoUnaPartitaDovrebbeTornareIlTitolo;
begin
  // the fake game does not take the "restart" away as the real one does, so the second round has no title:
  // the loop goes on with the next game until the fake leaves
  Make('wait 50'#10'press space', kgdNormal, False, 2);
  Assert.WillRaise(procedure begin FLoop.Run; end, EKeenQuitException);
  Assert.AreEqual('panel,new,game,new,game', Log);
end;

procedure TTestKeenDemoLoop.DovrebbeRifiutareIParametriNulli;
var
  LTitle: TKeenShape;
  LScores: IKeenHighScores;
  LPanel: IKeenControlPanel;
  LGame: IKeenGame;
begin
  Make('', kgdNormal, False, 1);
  LTitle := Default(TKeenShape);
  LScores := TFakeScores.Create(FLog);
  LPanel := TFakePanel.Create(FLog, FState, kgdNormal, False);
  LGame := TFakeGame.Create(FLog, 1);
  Assert.WillRaise(
    procedure begin TKeenDemoLoop.Create(LTitle, nil, FWorld.Input, LScores, LPanel, FState, LGame).Free; end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenDemoLoop.Create(LTitle, FWorld.Windows, nil, LScores, LPanel, FState, LGame).Free; end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenDemoLoop.Create(LTitle, FWorld.Windows, FWorld.Input, nil, LPanel, FState, LGame).Free; end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenDemoLoop.Create(LTitle, FWorld.Windows, FWorld.Input, LScores, nil, FState, LGame).Free; end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenDemoLoop.Create(LTitle, FWorld.Windows, FWorld.Input, LScores, LPanel, nil, LGame).Free; end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenDemoLoop.Create(LTitle, FWorld.Windows, FWorld.Input, LScores, LPanel, FState, nil).Free; end,
    EArgumentNilException);
end;

{ TTestKeenLateBinding }

procedure TTestKeenLateBinding.LeFunzioniNonLegateDovrebberoDareEccezione;
var
  LLate: IKeenActions;
begin
  LLate := TKeenLateActions.Create;
  Assert.WillRaise(procedure begin LLate.Think(1, nil); end, EKeenException);
  Assert.WillRaise(procedure begin LLate.Contact(1, nil, nil); end, EKeenException);
  Assert.WillRaise(procedure begin LLate.React(1, nil); end, EKeenException);
end;

procedure TTestKeenLateBinding.LeFunzioniLegateDovrebberoPassareLeChiamate;
var
  LLate: TKeenLateActions;
  LLateIntf: IKeenActions;
  LTarget: TLogActions;
  LTargetIntf: IKeenActions;
begin
  LLate := TKeenLateActions.Create;
  LLateIntf := LLate;
  LTarget := TLogActions.Create;
  LTargetIntf := LTarget;
  LLate.Bind(LTargetIntf);
  LLateIntf.Think(3, nil);
  LLateIntf.Contact(4, nil, nil);
  LLateIntf.React(5, nil);
  Assert.AreEqual('T3C4R5', LTarget.Log);
  // the link is weak: it does not keep the functions alive, and it can be taken away
  LLate.Bind(nil);
  Assert.WillRaise(procedure begin LLateIntf.Think(1, nil); end, EKeenException);
end;

procedure TTestKeenLateBinding.GliEventiNonLegatiDovrebberoDareEccezione;
var
  LLate: IKeenGameEvents;
begin
  LLate := TKeenLateEvents.Create;
  Assert.WillRaise(procedure begin LLate.KillKeen; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.PlaySound(1); end, EKeenException);
  Assert.WillRaise(procedure begin LLate.CheckKeys; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.IsGameLoaded; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.BeginPlay; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.ClearGodMode; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.IsGodMode; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.IsJumpCheat; end, EKeenException);
  Assert.WillRaise(procedure begin LLate.ShowNeedBombs; end, EKeenException);
end;

procedure TTestKeenLateBinding.GliEventiLegatiDovrebberoPassareLeChiamate;
var
  LLate: TKeenLateEvents;
  LLateIntf: IKeenGameEvents;
  LTarget: TFakeKeenEvents;
  LTargetIntf: IKeenGameEvents;
begin
  LLate := TKeenLateEvents.Create;
  LLateIntf := LLate;
  LTarget := TFakeKeenEvents.Create;
  LTargetIntf := LTarget;
  LLate.Bind(LTargetIntf);
  LLateIntf.KillKeen;
  LLateIntf.PlaySound(7);
  LLateIntf.CheckKeys;
  LLateIntf.BeginPlay;
  LLateIntf.ClearGodMode;
  LLateIntf.ShowNeedBombs;
  Assert.AreEqual(LTargetIntf.IsGameLoaded, LLateIntf.IsGameLoaded);
  Assert.AreEqual(LTargetIntf.IsGodMode, LLateIntf.IsGodMode);
  Assert.AreEqual(LTargetIntf.IsJumpCheat, LLateIntf.IsJumpCheat);
  Assert.AreEqual(1, LTarget.KillCount);
end;

procedure TTestKeenLateBinding.ITestiDiAiutoDovrebberoVenireDaiFileDeiDati;
var
  LFiles: TKeenMemoryFiles;
  LFilesIntf: IKeenDataFiles;
  LHelp: IKeenHelpTexts;
  LText: TBytes;
begin
  LFiles := TKeenMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('CONTEXT.KDR', TBytes.Create(65, 66, 67));
  LHelp := TKeenHelpFiles.Create(LFilesIntf);
  Assert.IsTrue(LHelp.TryGetText(1, LText));
  Assert.AreEqual(TBytes.Create(65, 66, 67), LText);
  Assert.IsFalse(LHelp.TryGetText(0, LText), 'GAMETEXT.KDR is not there');
  Assert.IsFalse(LHelp.TryGetText(3, LText));
  Assert.IsFalse(LHelp.TryGetText(-1, LText));
  Assert.WillRaise(procedure begin TKeenHelpFiles.Create(nil); end, EArgumentNilException);
end;

procedure TTestKeenLateBinding.LImmagineDelloSchermoDovrebbeEssereQuellaDellaScheda;
var
  LWorld: TKeenUiWorld;
  LSlow: TKeenChunkyImage;
  LFast: TKeenChunkyImage;
begin
  LWorld := TKeenUiWorld.Create(nil, '');
  try
    // something on the screen, a start in the middle of the memory and a pel panning
    LWorld.Windows.DrawWindow(3, 3, 20, 10);
    LWorld.Windows.Print('The quick brown fox');
    LWorld.Buffered.DrawPic(100, 80, KEEN_STARTPICS + 5);
    LWorld.Buffered.UpdateScreen;
    LWorld.Video.SetScreen(LWorld.Video.DisplayOfs + 65, 5);
    LSlow := TKeenDisplayCapture.CaptureVideo(LWorld.Video);
    LFast := TKeenScreenPicture.Capture(LWorld.Video);
    Assert.AreEqual(LSlow.Width, LFast.Width);
    Assert.AreEqual(LSlow.Height, LFast.Height);
    Assert.AreEqual(LSlow.Pixels, LFast.Pixels);
    // at the end of the memory the offsets go round
    LWorld.Video.SetScreen($FFF0, 3);
    Assert.AreEqual(TKeenDisplayCapture.CaptureVideo(LWorld.Video).Pixels, TKeenScreenPicture.Capture(LWorld.Video).Pixels);
  finally
    LWorld.Free;
  end;
  Assert.WillRaise(procedure begin TKeenScreenPicture.Capture(nil); end, EArgumentNilException);
end;

procedure TTestKeenLateBinding.IColoriDelloSchermoDovrebberoSeguireLaDissolvenza;
var
  LFader: IKeenFader;
  LColors: TKeenScreenColors;
  LIndex: Integer;
begin
  LFader := TKeenFader.Create(TKeenManualClock.Create(1));
  LColors := TKeenScreenPicture.Colors(LFader.Registers);
  for LIndex := 0 to 15 do
    Assert.AreEqual(TKeenEgaPalette.Color(LIndex), LColors[LIndex]);
  LFader.FadeOut;
  LColors := TKeenScreenPicture.Colors(LFader.Registers);
  for LIndex := 0 to 15 do
    Assert.AreEqual(Cardinal(0), LColors[LIndex]);
end;

end.
