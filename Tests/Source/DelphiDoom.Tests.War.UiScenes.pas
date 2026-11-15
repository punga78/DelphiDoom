{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenes and their manager         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiScenes;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game, DelphiDoom.Tests.War.UiFakes;

type
  /// <summary>
  ///   The manager of the scenes (time, transitions, pause), the three scenes with sprites that are solid colors, the
  ///   animations and the script runner, with no DATA.WAR
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarUiScenes = class(TObject)
  private
    FSprites: TFakeUiSprites;
    FSpritesRef: IWarUiSprites;
    FAudio: TFakeAudio;
    FAudioRef: IWarSceneAudio;
    FLog: TStringList;
    FLauncher: IWarMapLauncher;
    FGame: TWarUiGame;
    procedure NewGame(AIsDemo: Boolean = False; AWithLauncher: Boolean = True);
    /// <summary>
    ///   The next scene by its name. It is a method of its own so that the reference the call makes to the scene is
    ///   released here: a test that frees the game while it holds a scene would release it after its host is gone
    /// </summary>
    procedure ShowScene(const AName: string; ARace: TWarRace = wraNeutral; AMap: Integer = 0; ADelay: Single = 0);
    procedure Tick(ACount: Integer = 1);
    procedure Click(AX, AY: Single);
    procedure PressKey(AKey: TWarKey);
    function Pixel(AX, AY: Integer): Integer;
    function Menu: TObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareCorrereIlTempoRealeCoiDeltaDiOgniFotogramma;
    [Test]
    procedure DovrebbeNonDisegnareNienteDuranteLaPausaDiUnaTransizioneNemmenoIlCursore;
    [Test]
    procedure DovrebbeCambiareSceneAlPrimoAggiornamentoEAspettareLaPausaPerAggiornarla;
    [Test]
    procedure DovrebbeMetterePausaConCtrlPEnonConCtrlShiftP;
    [Test]
    procedure DovrebbeNonCambiareSceneInPausaMaFarAndareIlTempoReale;
    [Test]
    procedure DovrebbeEntrareNellaMappaDopoLaPausaESostituireLaScena;
    [Test]
    procedure DovrebbeLasciareLoSchermoVuotoSenzaUnaMappa;
    [Test]
    procedure DovrebbeRichiedereLaMappaPersonalizzataConLeOpzioni;
    [Test]
    procedure DovrebbeTenereLaRichiestaDellaMappaQuandoSiCambiaScena;
    [Test]
    procedure DovrebbeChiedereLUscitaDalMenu;
    [Test]
    procedure DovrebbePassareDalLogoAlMenuDopoTreSecondi;
    [Test]
    procedure DovrebbeSuonareILogoEIlMenuMaNonLaMusicaNellaDemo;
    [Test]
    procedure DovrebbeNavigareTraIPannelliDelMenu;
    [Test]
    procedure DovrebbeScegliereLeRazzeELaMappaFraILimiti;
    [Test]
    procedure DovrebbeDareIlNomeDelleMappePersonalizzate;
    [Test]
    procedure DovrebbeAvviareLaCampagnaDegliUmaniEDegliOrchi;
    [Test]
    procedure DovrebbeAvviareLaPartitaPersonalizzataConIlSuoClic;
    [Test]
    procedure DovrebbeFarScorrereILTestoDelBriefingEFinireDaSolo;
    [Test]
    procedure DovrebbeFinireIlBriefingConIlClicConInvioEConLoSpazio;
    [Test]
    procedure DovrebbeCrearePiuAnimazioniPerLeUmaneENonLaTerzaDegliOrchiNellaDemo;
    [Test]
    procedure DovrebbeLasciareVuotoUnBriefingDiUnaRazzaNeutrale;
    [Test]
    procedure DovrebbeFarGirareLeAnimazioniEFermarleInPausa;
    [Test]
    procedure DovrebbeRimuovereUnAnimazioneFinitaESaltareLaSeguente;
    [Test]
    procedure DovrebbeCalcolareLeAnimazioniInScenaEInMappa;
    [Test]
    procedure DovrebbeAggiungereUnIntervalloDiFotogrammiInSuEInGiu;
    [Test]
    procedure DovrebbeEseguireUnScriptEScrivereLeImpronte;
    [Test]
    procedure DovrebbeRifiutareICommandiCheServonoLaMappaOLaRete;
    [Test]
    procedure DovrebbeScrivereLeChiamateDiDisegnoNellaTraccia;
    [Test]
    procedure DovrebbeScrivereIPixelDelFotogramma;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.Ui.SceneMainMenu, DelphiDoom.War.Ui.SceneBriefing,
  DelphiDoom.War.Ui.Animation, DelphiDoom.War.Ui.Animations, DelphiDoom.War.Ui.ScriptRunner;

{ TTestWarUiScenes }

procedure TTestWarUiScenes.Setup;
begin
  FSprites := TFakeUiSprites.Create;
  FSpritesRef := FSprites;
  FAudio := TFakeAudio.Create;
  FAudioRef := FAudio;
  FLog := TStringList.Create;
  FLauncher := TFakeMapLauncher.Create(FLog);
  NewGame;
end;

procedure TTestWarUiScenes.TearDown;
begin
  FreeAndNil(FGame);
  FLauncher := nil;
  FreeAndNil(FLog);
  FAudioRef := nil;
  FSpritesRef := nil;
end;

procedure TTestWarUiScenes.NewGame(AIsDemo: Boolean; AWithLauncher: Boolean);
var
  LLauncher: IWarMapLauncher;
begin
  FreeAndNil(FGame);
  if AWithLauncher then
    LLauncher := FLauncher
  else
    LLauncher := nil;
  FGame := TFakeUiRig.CreateGame(FSpritesRef, FAudioRef, LLauncher, AIsDemo);
end;

procedure TTestWarUiScenes.ShowScene(const AName: string; ARace: TWarRace; AMap: Integer; ADelay: Single);
begin
  if AName = 'blizzard' then
    FGame.Manager.SetNextScene(FGame.Scenes.CreateBlizzard, ADelay)
  else if AName = 'menu' then
    FGame.Manager.SetNextScene(FGame.Scenes.CreateMainMenu, ADelay)
  else
    FGame.Manager.SetNextScene(FGame.Scenes.CreateBriefing(ARace, AMap), ADelay);
end;

procedure TTestWarUiScenes.Tick(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FGame.Manager.RunFrame(Single(1) / Single(60));
    FGame.Manager.BeginInputFrame;
  end;
end;

procedure TTestWarUiScenes.Click(AX, AY: Single);
begin
  FGame.Input.SetPosition(AX, AY);
  FGame.Input.SetButton(wmbLeft, True);
  Tick;
  FGame.Input.SetButton(wmbLeft, False);
  Tick;
end;

procedure TTestWarUiScenes.PressKey(AKey: TWarKey);
begin
  FGame.Input.SetKey(AKey, True);
  FGame.Input.SetKey(AKey, False);
  Tick;
end;

function TTestWarUiScenes.Pixel(AX, AY: Integer): Integer;
begin
  Result := FGame.Canvas.Blitter.Pixels[(AY * 320 + AX) * 4];
end;

function TTestWarUiScenes.Menu: TObject;
begin
  Result := FGame.Manager.Scene as TObject;
end;

procedure TTestWarUiScenes.DovrebbeFareCorrereIlTempoRealeCoiDeltaDiOgniFotogramma;
begin
  Tick(60);
  Assert.AreEqual(1.0, FGame.Manager.RealTime, 0.0001);
  Assert.AreEqual(60, FGame.Manager.FrameCount);
  Assert.AreEqual(1.0, FGame.Manager.GameTime, 0.0001);
  Assert.IsFalse(FGame.Manager.QuitRequested);
end;

procedure TTestWarUiScenes.DovrebbeNonDisegnareNienteDuranteLaPausaDiUnaTransizioneNemmenoIlCursore;
begin
  ShowScene('blizzard', wraNeutral, 0, 1.0);
  FGame.Input.SetPosition(100, 100);
  Tick(2);
  Assert.AreEqual(0, Pixel(100, 100), 'nero: ne'' scena ne'' cursore');
  Assert.AreEqual(255, Integer(FGame.Canvas.Blitter.Pixels[(100 * 320 + 100) * 4 + 3]), 'ma opaco');
  Tick(70);
  Assert.AreNotEqual(0, Integer(FGame.Canvas.Blitter.Pixels[(10 * 320 + 10) * 4]) + Pixel(100, 100), 'poi si disegna');
end;

procedure TTestWarUiScenes.DovrebbeCambiareSceneAlPrimoAggiornamentoEAspettareLaPausaPerAggiornarla;
begin
  ShowScene('menu', wraNeutral, 0, 0.5);
  Assert.IsFalse(Assigned(FGame.Manager.Scene));
  Tick;
  Assert.IsTrue(Assigned(FGame.Manager.Scene), 'il cambio e'' subito');
  Assert.AreEqual(Ord(wstMainMenu), Ord(FGame.Manager.Scene.SceneType));
  // 0,5 s of pause: the menu has not been updated, so the cheat panel is closed even with Enter
  FGame.Input.SetKey(wkEnter, True);
  FGame.Input.SetKey(wkEnter, False);
  Tick;
  Assert.IsFalse((FGame.Manager.Scene as TWarSceneBase).CheatsPanel.Visible);
end;

procedure TTestWarUiScenes.DovrebbeMetterePausaConCtrlPEnonConCtrlShiftP;
begin
  FGame.Input.SetKey(wkCtrl, True);
  FGame.Input.SetKey(wkP, True);
  Tick;
  FGame.Input.SetKey(wkP, False);
  Tick;
  Assert.IsTrue(FGame.Manager.Paused);
  Tick;
  Assert.AreEqual(0.0, Double(FGame.Manager.GameDeltaTime), 0.0000001, 'in pausa il tempo del gioco non corre');
  FGame.Input.SetKey(wkP, True);
  Tick;
  FGame.Input.SetKey(wkP, False);
  Tick;
  Assert.IsFalse(FGame.Manager.Paused, 'ancora Ctrl+P: riprende');
  FGame.Input.SetKey(wkShift, True);
  FGame.Input.SetKey(wkP, True);
  Tick;
  FGame.Input.SetKey(wkP, False);
  Tick;
  Assert.IsFalse(FGame.Manager.Paused, 'Ctrl+Shift+P no');
end;

procedure TTestWarUiScenes.DovrebbeNonCambiareSceneInPausaMaFarAndareIlTempoReale;
var
  LTime: Double;
begin
  FGame.Input.SetKey(wkCtrl, True);
  FGame.Input.SetKey(wkP, True);
  Tick;
  FGame.Input.SetKey(wkP, False);
  Tick;
  LTime := FGame.Manager.RealTime;
  ShowScene('menu');
  Tick(10);
  Assert.IsFalse(Assigned(FGame.Manager.Scene), 'la scena non cambia in pausa');
  Assert.IsTrue(FGame.Manager.RealTime > LTime, 'il tempo reale va avanti');
  Assert.AreEqual(1.0, Double(FGame.Settings.GlobalSpeed), 0.0001);
end;

procedure TTestWarUiScenes.DovrebbeEntrareNellaMappaDopoLaPausaESostituireLaScena;
begin
  ShowScene('menu');
  Tick(2);
  FGame.Manager.SetNextCampaignMap(117, 1.0);
  Tick;
  Assert.AreEqual('campaign 117', FLog[0]);
  Assert.AreEqual('map enter', FLog[1]);
  Assert.AreEqual(Ord(wstMap), Ord(FGame.Manager.Scene.SceneType));
  Assert.IsFalse(FGame.Settings.AudioEnabled and False);
  Tick(70);
  Assert.IsTrue(FLog.IndexOf('map update') > 0);
  Assert.IsTrue(FLog.IndexOf('map render') > 0);
  FGame.Manager.HandleTextInput('x');
  Assert.IsTrue(FLog.IndexOf('map text x') > 0);
  ShowScene('blizzard');
  Tick;
  Assert.IsTrue(FLog.IndexOf('map leave') > 0);
end;

procedure TTestWarUiScenes.DovrebbeLasciareLoSchermoVuotoSenzaUnaMappa;
begin
  NewGame(False, False);
  ShowScene('menu');
  Tick(2);
  FGame.Manager.SetNextCampaignMap(117, 0);
  Tick(3);
  Assert.IsFalse(Assigned(FGame.Manager.Scene));
  Assert.IsTrue(FGame.Settings.AudioEnabled);
  FGame.Manager.HandleTextInput('x');
  FGame.Manager.SetNextCustomMap(147, 1, 2, 0);
  Tick(3);
  Assert.IsFalse(Assigned(FGame.Manager.Scene));
end;

procedure TTestWarUiScenes.DovrebbeRichiedereLaMappaPersonalizzataConLeOpzioni;
begin
  FGame.Manager.SetNextCustomMap(150, 1, 2, 0);
  Tick(2);
  Assert.AreEqual('custom 150 1 2', FLog[0]);
end;

procedure TTestWarUiScenes.DovrebbeTenereLaRichiestaDellaMappaQuandoSiCambiaScena;
begin
  // a defect of the original: the request of a map is not canceled by a scene, the map comes after it
  FGame.Manager.SetNextCampaignMap(119, 0);
  ShowScene('menu');
  Tick;
  Assert.AreEqual(Ord(wstMainMenu), Ord(FGame.Manager.Scene.SceneType));
  Tick;
  Assert.AreEqual(Ord(wstMap), Ord(FGame.Manager.Scene.SceneType));
  Assert.AreEqual('campaign 119', FLog[0]);
end;

procedure TTestWarUiScenes.DovrebbeChiedereLUscitaDalMenu;
begin
  ShowScene('menu');
  Tick(2);
  Click(150, 170);
  Assert.IsTrue(FGame.Manager.QuitRequested);
end;

procedure TTestWarUiScenes.DovrebbePassareDalLogoAlMenuDopoTreSecondi;
begin
  ShowScene('blizzard');
  Tick(170);
  Assert.AreEqual(Ord(wstBlizzard), Ord(FGame.Manager.Scene.SceneType));
  Tick(15);
  Assert.AreEqual(Ord(wstMainMenu), Ord(FGame.Manager.Scene.SceneType));
end;

procedure TTestWarUiScenes.DovrebbeSuonareILogoEIlMenuMaNonLaMusicaNellaDemo;
begin
  ShowScene('blizzard');
  Tick;
  Assert.AreEqual(WAR_AUDIO_LOGO, FAudio.Played[0]);
  Assert.IsTrue(FAudio.Loops[0]);
  ShowScene('menu');
  Tick;
  Assert.AreEqual(WAR_AUDIO_MUSIC_00, FAudio.Played[1]);
  NewGame(True);
  FAudio.Played.Clear;
  ShowScene('menu');
  Tick;
  Assert.AreEqual(0, FAudio.Played.Count, 'la demo non ha la musica');
end;

procedure TTestWarUiScenes.DovrebbeNavigareTraIPannelliDelMenu;
var
  LMenu: TWarSceneMainMenu;
begin
  ShowScene('menu');
  Tick(2);
  LMenu := Menu as TWarSceneMainMenu;
  Assert.AreEqual(Ord(wmpMain), Ord(LMenu.MenuPanel));
  // the inert buttons
  Click(150, 110);
  Click(150, 130);
  Assert.AreEqual(Ord(wmpMain), Ord(LMenu.MenuPanel));
  Click(150, 90);
  Assert.AreEqual(Ord(wmpSinglePlayer), Ord(LMenu.MenuPanel));
  Click(140, 170);
  Assert.AreEqual(Ord(wmpMain), Ord(LMenu.MenuPanel), 'Cancel');
  PressKey(wkS);
  PressKey(wkU);
  Assert.AreEqual(Ord(wmpCustomGame), Ord(LMenu.MenuPanel));
  Assert.AreEqual(Ord(wraHumans), Ord(LMenu.YourRace));
  Assert.AreEqual(Ord(wraOrcs), Ord(LMenu.EnemyRace));
  Assert.AreEqual(147, LMenu.CustomMap);
  PressKey(wkC);
  Assert.AreEqual(Ord(wmpSinglePlayer), Ord(LMenu.MenuPanel), 'Cancel del custom torna a un giocatore');
end;

procedure TTestWarUiScenes.DovrebbeScegliereLeRazzeELaMappaFraILimiti;
var
  LMenu: TWarSceneMainMenu;
  LIndex: Integer;
begin
  ShowScene('menu');
  Tick(2);
  PressKey(wkS);
  PressKey(wkU);
  LMenu := Menu as TWarSceneMainMenu;
  Click(165, 105);
  Assert.AreEqual(Ord(wraNeutral), Ord(LMenu.YourRace));
  Click(165, 105);
  Assert.AreEqual(Ord(wraNeutral), Ord(LMenu.YourRace), 'non va sotto Random');
  Click(240, 105);
  Click(240, 105);
  Click(240, 105);
  Assert.AreEqual(Ord(wraOrcs), Ord(LMenu.YourRace), 'non va sopra Orc');
  Click(165, 125);
  Assert.AreEqual(Ord(wraHumans), Ord(LMenu.EnemyRace));
  Click(165, 125);
  Assert.AreEqual(Ord(wraNeutral), Ord(LMenu.EnemyRace));
  Click(165, 125);
  Assert.AreEqual(Ord(wraNeutral), Ord(LMenu.EnemyRace), 'non va sotto Random');
  Click(240, 125);
  Click(240, 125);
  Click(240, 125);
  Assert.AreEqual(Ord(wraOrcs), Ord(LMenu.EnemyRace));
  for LIndex := 1 to 45 do
    Click(240, 145);
  Assert.AreEqual(188, LMenu.CustomMap, 'ultima mappa');
  for LIndex := 1 to 45 do
    Click(165, 145);
  Assert.AreEqual(147, LMenu.CustomMap, 'prima mappa');
end;

procedure TTestWarUiScenes.DovrebbeDareIlNomeDelleMappePersonalizzate;
var
  LMenu: TWarSceneMainMenu;
begin
  // the names are drawn: only the frame must not fail for the 42 maps and the one outside
  ShowScene('menu');
  Tick(2);
  PressKey(wkS);
  PressKey(wkU);
  LMenu := Menu as TWarSceneMainMenu;
  Assert.AreEqual(147, LMenu.CustomMap);
  Tick(2);
end;

procedure TTestWarUiScenes.DovrebbeAvviareLaCampagnaDegliUmaniEDegliOrchi;
var
  LBriefing: TWarSceneBriefing;
begin
  ShowScene('menu');
  Tick(2);
  PressKey(wkS);
  Click(150, 110);
  Tick(70);
  Assert.AreEqual(Ord(wstBriefing), Ord(FGame.Manager.Scene.SceneType));
  LBriefing := FGame.Manager.Scene as TWarSceneBriefing;
  Assert.IsTrue(Assigned(LBriefing));
  Assert.IsTrue(FAudio.Played.Contains(551), 'il briefing parlato della prima missione degli umani');
  ShowScene('menu');
  Tick(2);
  PressKey(wkS);
  PressKey(wkO);
  Tick(70);
  Assert.IsTrue(FAudio.Played.Contains(563), 'e'' quello degli orchi');
end;

procedure TTestWarUiScenes.DovrebbeAvviareLaPartitaPersonalizzataConIlSuoClic;
begin
  ShowScene('menu');
  Tick(2);
  PressKey(wkS);
  PressKey(wkU);
  Click(240, 105);
  Click(240, 145);
  Click(105, 170);
  Tick(70);
  Assert.AreEqual('custom 148 2 2', FLog[0]);
end;

procedure TTestWarUiScenes.DovrebbeFarScorrereILTestoDelBriefingEFinireDaSolo;
var
  LBriefing: TWarSceneBriefing;
  LStart: Single;
begin
  ShowScene('briefing', wraHumans, 117);
  Tick;
  LBriefing := FGame.Manager.Scene as TWarSceneBriefing;
  LStart := LBriefing.ScrollY;
  Assert.AreEqual(160.0, Double(LStart), 0.2);
  Tick(60);
  Assert.AreEqual(Double(LStart) - 10.0, Double(LBriefing.ScrollY), 0.05, '10 unita'' al secondo');
  Assert.AreEqual(24.0, LBriefing.EndRealTime, 0.05);
  Tick(1400);
  Assert.AreEqual(Ord(wstMap), Ord(FGame.Manager.Scene.SceneType), 'la mappa dopo 24 s e la pausa');
  Assert.AreEqual('campaign 117', FLog[0]);
end;

procedure TTestWarUiScenes.DovrebbeFinireIlBriefingConIlClicConInvioEConLoSpazio;
begin
  ShowScene('briefing', wraOrcs, 118);
  Tick(3);
  Click(10, 10);
  Tick(70);
  Assert.IsTrue(FLog.IndexOf('campaign 118') >= 0);
  ShowScene('briefing', wraOrcs, 120);
  Tick(3);
  PressKey(wkEnter);
  Tick(70);
  Assert.IsTrue(FLog.IndexOf('campaign 120') >= 0);
  ShowScene('briefing', wraHumans, 119);
  Tick(3);
  PressKey(wkSpace);
  Tick(70);
  Assert.IsTrue(FLog.IndexOf('campaign 119') >= 0);
end;

procedure TTestWarUiScenes.DovrebbeCrearePiuAnimazioniPerLeUmaneENonLaTerzaDegliOrchiNellaDemo;
var
  LScene: TWarSceneBase;
begin
  ShowScene('briefing', wraHumans, 117);
  Tick;
  LScene := FGame.Manager.Scene as TWarSceneBase;
  Assert.AreEqual(4, LScene.SceneAnimations.Count);
  Assert.AreEqual(10, LScene.SceneAnimations[0].FrameCount, '0 a 4 e 4 a 0');
  ShowScene('briefing', wraOrcs, 118);
  Tick;
  LScene := FGame.Manager.Scene as TWarSceneBase;
  Assert.AreEqual(3, LScene.SceneAnimations.Count);
  NewGame(True);
  FAudio.Played.Clear;
  ShowScene('briefing', wraOrcs, 118);
  Tick;
  LScene := FGame.Manager.Scene as TWarSceneBase;
  Assert.AreEqual(2, LScene.SceneAnimations.Count, 'nella demo senza la terza e senza il parlato');
  Assert.AreEqual(0, FAudio.Played.Count);
end;

procedure TTestWarUiScenes.DovrebbeLasciareVuotoUnBriefingDiUnaRazzaNeutrale;
var
  LScene: TWarSceneBase;
begin
  // its end time is never set (0): the map is asked at once, as the original does
  ShowScene('briefing', wraNeutral, 117);
  Tick;
  LScene := FGame.Manager.Scene as TWarSceneBase;
  Assert.AreEqual(0, LScene.SceneAnimations.Count);
end;

procedure TTestWarUiScenes.DovrebbeFarGirareLeAnimazioniEFermarleInPausa;
var
  LScene: TWarSceneBase;
  LTime: Single;
begin
  ShowScene('briefing', wraHumans, 117);
  Tick(10);
  LScene := FGame.Manager.Scene as TWarSceneBase;
  Assert.AreEqual(Ord(wasRunning), Ord(LScene.SceneAnimations[0].Status));
  LTime := LScene.SceneAnimations[2].AnimTime;
  Assert.IsTrue(LTime > 0);
  FGame.Input.SetKey(wkCtrl, True);
  FGame.Input.SetKey(wkP, True);
  Tick;
  FGame.Input.SetKey(wkP, False);
  Tick(30);
  Assert.AreEqual(Double(LTime), Double(LScene.SceneAnimations[2].AnimTime), 0.05, 'ferma');
end;

procedure TTestWarUiScenes.DovrebbeRimuovereUnAnimazioneFinitaESaltareLaSeguente;
var
  LAnimations: TWarUiAnimations;
  LFirst: TWarUiAnimation;
  LSecond: TWarUiAnimation;
  LThird: TWarUiAnimation;
  LSprite: IWarUiSprite;
begin
  LSprite := FSprites.CreateSprite(1000);
  LAnimations := TWarUiAnimations.Create;
  try
    // not looping and one frame of 0.5 s: finishes at the second update; the next one is skipped in the update that removes it
    LFirst := TWarUiAnimation.Create('a', LSprite, 0.5, False);
    LFirst.AddFrame(0);
    LSecond := TWarUiAnimation.Create('b', LSprite, 5, False);
    LSecond.AddFrame(0);
    LThird := TWarUiAnimation.Create('c', LSprite, 5, False);
    LThird.AddFrame(0);
    LAnimations.Add(LFirst);
    LAnimations.Add(LSecond);
    LAnimations.Add(LThird);
    LAnimations.Update(True, 0.6, 1, 0);
    Assert.AreEqual(Ord(wasFinished), Ord(LFirst.Status));
    Assert.AreEqual(1, RoundInt(LFirst.AnimTime));
    LAnimations.Update(True, 0.6, 1, 0);
    // a is removed and b, that moved into its place, is skipped (k goes on): c was updated
    Assert.AreEqual(2, LAnimations.Count);
    Assert.AreEqual<AnsiString>('b', LAnimations[0].Name);
    Assert.IsTrue(LAnimations[1].AnimTime > 0.1);
  finally
    LAnimations.Free;
  end;
end;

procedure TTestWarUiScenes.DovrebbeCalcolareLeAnimazioniInScenaEInMappa;
var
  LAnimation: TWarUiAnimation;
begin
  LAnimation := TWarUiAnimation.Create('a', FSprites.CreateSprite(1000), 1, True);
  try
    LAnimation.AddFramesRange(0, 1);
    LAnimation.LoopDelay := 1;
    // a scene: the real delta times the speed; 2 frames of 1 s
    LAnimation.Update(True, 0.5, 2, 99);
    Assert.AreEqual(0.5, Double(LAnimation.AnimTime), 0.0001);
    LAnimation.Update(True, 0.5, 2, 99);
    // finished: it loops and waits for the delay
    Assert.AreEqual(Ord(wasRunning), Ord(LAnimation.Status));
    Assert.AreEqual(1.0, Double(LAnimation.LoopTime), 0.0001);
    LAnimation.Update(True, 0.25, 2, 99);
    Assert.AreEqual(0.5, Double(LAnimation.LoopTime), 0.0001, 'la pausa passa al tempo reale per la velocita''');
    LAnimation.Update(False, 99, 9, 0.25);
    Assert.AreEqual(0.25, Double(LAnimation.LoopTime), 0.0001, 'in una mappa col tempo del gioco');
    LAnimation.Update(False, 99, 9, 0.5);
    LAnimation.Update(False, 99, 9, 1);
    Assert.AreEqual(0.5, Double(LAnimation.AnimTime), 0.0001, 'in una mappa dt e'' del gioco');
    LAnimation.Reset;
    Assert.AreEqual(Ord(wasNotStarted), Ord(LAnimation.Status));
  finally
    LAnimation.Free;
  end;
end;

procedure TTestWarUiScenes.DovrebbeAggiungereUnIntervalloDiFotogrammiInSuEInGiu;
var
  LAnimation: TWarUiAnimation;
begin
  LAnimation := TWarUiAnimation.Create('a', FSprites.CreateSprite(1000), 0.1, False);
  try
    LAnimation.AddFramesRange(0, 2);
    LAnimation.AddFramesRange(2, 0);
    Assert.AreEqual(6, LAnimation.FrameCount);
    Assert.AreEqual(0.6, Double(LAnimation.Duration), 0.0001);
    LAnimation.OffsetX := 1;
    LAnimation.OffsetY := 2;
    LAnimation.ScaleX := 3;
    LAnimation.ScaleY := 4;
    Assert.AreEqual(3, RoundInt(LAnimation.ScaleX));
    Assert.AreEqual(4, RoundInt(LAnimation.ScaleY));
    Assert.AreEqual(1, RoundInt(LAnimation.OffsetX));
    Assert.AreEqual(2, RoundInt(LAnimation.OffsetY));
  finally
    LAnimation.Free;
  end;
end;

procedure TTestWarUiScenes.DovrebbeEseguireUnScriptEScrivereLeImpronte;
var
  LOutput: TStringList;
begin
  LOutput := TStringList.Create;
  try
    with TWarUiScriptRunner.Create(FGame, LOutput, nil) do
    try
      Run(['# un commento', '', 'scene blizzard', 'run 4 2', 'move 10.5 20', 'lbutton down', 'rbutton down', 'key a down',
        'key esc up', 'text x', 'run 1', 'hash', 'trace on', 'png a.png', 'lbutton up', 'rbutton up', 'scene menu', 'run 2 0',
        'briefing human 117', 'briefing orc 118', 'run 1 1']);
    finally
      Free;
    end;
    Assert.AreEqual(5, LOutput.Count);
    Assert.IsTrue(LOutput[0].StartsWith('H 2 '));
    Assert.IsTrue(LOutput[1].StartsWith('H 4 '));
    Assert.IsTrue(LOutput[2].StartsWith('H 5 '));
    Assert.AreEqual(8, Length(LOutput[2]) - Length('H 5 '));
    Assert.AreEqual(LOutput[2].Substring(4), LOutput[3].Substring(4), 'hash e'' lo stesso del fotogramma corrente');
  finally
    LOutput.Free;
  end;
end;

procedure TTestWarUiScenes.DovrebbeRifiutareICommandiCheServonoLaMappaOLaRete;
var
  LOutput: TStringList;
begin
  LOutput := TStringList.Create;
  try
    with TWarUiScriptRunner.Create(FGame, LOutput, nil) do
    try
      Assert.WillRaise(procedure begin Run(['campaign human 1']); end, EWarException);
      Assert.WillRaise(procedure begin Run(['custom 150']); end, EWarException);
      Assert.WillRaise(procedure begin Run(['scene download']); end, EWarException);
      Assert.WillRaise(procedure begin Run(['frobnicate']); end, EWarException);
      Assert.WillRaise(procedure begin Run(['key banana down']); end, EWarException);
    finally
      Free;
    end;
  finally
    LOutput.Free;
  end;
end;

procedure TTestWarUiScenes.DovrebbeScrivereLeChiamateDiDisegnoNellaTraccia;
var
  LOutput: TStringList;
  LTrace: TStringList;
begin
  LOutput := TStringList.Create;
  LTrace := TStringList.Create;
  try
    with TWarUiScriptRunner.Create(FGame, LOutput, LTrace) do
    try
      Run(['scene menu', 'run 2 0', 'trace on', 'key enter down', 'key enter up', 'run 1 0', 'text 7', 'run 1 0', 'trace off',
        'run 1 0']);
    finally
      Free;
    end;
    Assert.IsTrue(LTrace.Count > 10);
    Assert.IsTrue(LTrace[0].StartsWith('T 0 0 '), 'la prima e'' l''immagine di sfondo: ' + LTrace[0]);
    Assert.IsTrue(LTrace[0].EndsWith(' a255 c255,255,255 b1'));
    Assert.IsTrue(LTrace.IndexOf('F 0 0 320 12 c100,100,100,160') >= 0, 'il riquadro del pannello');
  finally
    LTrace.Free;
    LOutput.Free;
  end;
end;

procedure TTestWarUiScenes.DovrebbeScrivereIPixelDelFotogramma;
var
  LOutput: TStringList;
  LPath: string;
  LBytes: TBytes;
begin
  LOutput := TStringList.Create;
  LPath := ChangeFileExt(ParamStr(0), '.frame.rgba');
  try
    with TWarUiScriptRunner.Create(FGame, LOutput, nil) do
    try
      Run(['scene menu', 'run 3 0', 'rgba ' + LPath]);
    finally
      Free;
    end;
    LBytes := TFile.ReadAllBytes(LPath);
    Assert.AreEqual(320 * 200 * 4, Length(LBytes));
    DeleteFile(LPath);
  finally
    LOutput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarUiScenes);

end.
