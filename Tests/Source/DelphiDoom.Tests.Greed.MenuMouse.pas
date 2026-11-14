{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mouse in the menus of the greed library             }
{                                                                              }
{  What the scenarios with a mouse do in TGreedMenu (the same scenarios run on   }
{  the original menu.pas give the golden files: see                             }
{  DelphiDoom.Tests.Greed.MenuScenarios and Tools\Verifica\175-menu)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.MenuMouse;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Intf, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.Menu,
  DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Tests.Greed.MenuScenarios;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMenuMouse = class(TObject)
  strict private
    FArchive: IGreedArchive;
    FRunner: TMenuLibraryRunner;
    function Run(ANumber: Integer): TMenuScenario;
    procedure Open(ANumber: Integer; out AScenario: TMenuScenario);
    procedure Tics(ACount: Integer);
    procedure PointTo(AX, AY: Integer);
    procedure Click;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure GliScenariDeiTastiNonDovrebberoAvereIlMouse;
    [Test]
    procedure IlCursoreDelMenuDovrebbeSeguireIlPuntatore;
    [Test]
    procedure DovrebbeIniziareUnaPartitaConTreClic;
    [Test]
    procedure DovrebbeRegolareLeOpzioniConIClic;
    [Test]
    procedure DovrebbeRegolareLeOpzioniAncheInUnaFinestraPiccola;
    [Test]
    procedure DovrebbeUscireConUnClicSuSi;
    [Test]
    procedure DovrebbeRestareConUnClicSuNo;
    [Test]
    procedure DovrebbeIgnorareIClicFuoriDalleRisposteEMentreIlPannelloScende;
    [Test]
    procedure DovrebbeCaricareUnaPartitaConDueClic;
    [Test]
    procedure DovrebbeSalvareScegliendoLaPartitaConUnClic;
    [Test]
    procedure DovrebbeAprireLAiutoERiprendereConIClic;
    [Test]
    procedure IlPannelloDaSoloDovrebbeRispondereAiClic;
    [Test]
    procedure NonDovrebbeVedereIClicSeIMenuNonUsanoIlMouse;
    [Test]
    procedure DovrebbeFunzionareInUnaFinestraPiuGrande;
    [Test]
    procedure IlPuntatoreDovrebbeVincereSuiTasti;
    [Test]
    procedure DovrebbeAndareAvantiEIndietroTraIPersonaggi;
    [Test]
    procedure DovrebbeMostrareIlPuntatoreQuandoIlMenuSiApreENasconderloQuandoSiChiude;
    [Test]
    procedure DovrebbeNascondereIlPuntatoreMentreSiScriveIlNome;
    [Test]
    procedure DovrebbeRimettereIlCursoreAlCentroQuandoIlMenuSiChiude;
    [Test]
    procedure LaPausaELAiutoNonDovrebberoUsareIlMouse;
  end;

implementation

const
  SCREEN_SCALE = 2;

{ TTestGreedMenuMouse }

procedure TTestGreedMenuMouse.Setup;
begin
  FArchive := TMenuScenarios.SyntheticArchive;
  FRunner := TMenuLibraryRunner.Create(FArchive);
end;

procedure TTestGreedMenuMouse.TearDown;
begin
  FRunner.Free;
  FArchive := nil;
end;

function TTestGreedMenuMouse.Run(ANumber: Integer): TMenuScenario;
begin
  Result := TMenuScenarios.Scenario(MENU_KEY_SCENARIOS + ANumber);
  FRunner.Run(Result);
end;

procedure TTestGreedMenuMouse.Open(ANumber: Integer; out AScenario: TMenuScenario);
begin
  // the settings of a scenario with a mouse, and no events: the test moves the mouse itself
  AScenario := TMenuScenarios.Scenario(MENU_KEY_SCENARIOS + ANumber);
  AScenario.Animation := False;
  FRunner.Prepare(AScenario);
end;

procedure TTestGreedMenuMouse.Tics(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FRunner.Menu.Tick;
end;

procedure TTestGreedMenuMouse.PointTo(AX, AY: Integer);
begin
  // as far as the corner, where the pointer stops, then to the pixel
  FRunner.MouseFake.X := FRunner.MouseFake.X - 4000;
  FRunner.MouseFake.Y := FRunner.MouseFake.Y - 4000;
  Tics(2);
  FRunner.MouseFake.X := FRunner.MouseFake.X + AX * SCREEN_SCALE;
  FRunner.MouseFake.Y := FRunner.MouseFake.Y + AY * SCREEN_SCALE;
  Tics(2);
end;

procedure TTestGreedMenuMouse.Click;
begin
  FRunner.MouseFake.Buttons := 1;
  Tics(4);
  FRunner.MouseFake.Buttons := 0;
  Tics(2);
end;

procedure TTestGreedMenuMouse.GliScenariDeiTastiNonDovrebberoAvereIlMouse;
var
  LIndex: Integer;
  LScenario: TMenuScenario;
begin
  for LIndex := 0 to MENU_KEY_SCENARIOS - 1 do
  begin
    LScenario := TMenuScenarios.Scenario(LIndex);
    Assert.IsFalse(LScenario.UseMouse, 'scenario ' + IntToStr(LIndex));
    Assert.AreEqual<Integer>(0, Length(LScenario.Mouse));
  end;
  for LIndex := MENU_KEY_SCENARIOS to MENU_SCENARIOS - 1 do
    Assert.IsTrue(TMenuScenarios.Scenario(LIndex).UseMouse, 'scenario ' + IntToStr(LIndex));
  FRunner.Prepare(TMenuScenarios.Scenario(0));
  Assert.IsNull(FRunner.Mouse);
  Assert.IsNull(FRunner.Input.Mouse);
end;

procedure TTestGreedMenuMouse.IlCursoreDelMenuDovrebbeSeguireIlPuntatore;
begin
  Run(0);
  Assert.IsTrue(FRunner.Menu.Active, 'nothing was pressed');
  Assert.AreEqual(GREED_MENU_MAIN, FRunner.Menu.Level);
  Assert.AreEqual(3, FRunner.Menu.Cursor, 'the pointer went from "load" down to "save" and then off every entry');
  Assert.IsTrue(FRunner.Mouse.IsVisible);
  Assert.AreEqual(0, FRunner.Host.NewGames + FRunner.Host.LoadedGames + FRunner.Host.SavedGames);
end;

procedure TTestGreedMenuMouse.DovrebbeIniziareUnaPartitaConTreClic;
begin
  Run(1);
  Assert.AreEqual(1, FRunner.Host.NewGames);
  Assert.AreEqual(2, FRunner.Host.LastCharacter, 'the third character: moo');
  Assert.AreEqual(4, FRunner.Host.LastDifficulty, 'the second row of the difficulty');
  Assert.IsFalse(FRunner.Menu.Active, 'the menu closed for the game');
  Assert.IsFalse(FRunner.Mouse.IsVisible);
end;

procedure TTestGreedMenuMouse.DovrebbeRegolareLeOpzioniConIClic;
begin
  Run(2);
  Assert.IsFalse(FRunner.Menu.Active);
  // ((x - 40) * 256) div 49 for the last click that is on the bar
  Assert.AreEqual(10, FRunner.Settings.GetInteger('musicvol'), 'the click at 42; the one at 41 is off the bar');
  Assert.AreEqual(182, FRunner.Settings.GetInteger('sfxvol'), 'the click at 75, 64; the row 65 is off the bar');
  Assert.AreEqual(10, FRunner.Host.Music);
  Assert.AreEqual(182, FRunner.Host.Sfx);
  Assert.IsFalse(FRunner.Settings.GetBoolean('violence'), 'left arrow on, right arrow off, between the two nothing');
  Assert.IsTrue(FRunner.Settings.GetBoolean('animation'), 'right arrow off, left arrow on');
  Assert.AreEqual(4096, FRunner.Settings.GetInteger('ambientlight'), 'the end of the bar is more than the most');
  Assert.AreEqual(4096, FRunner.Host.ChangeLight);
  Assert.AreEqual(0, FRunner.Settings.GetInteger('screensize'), 'the end of the bar is the largest view');
  Assert.AreEqual(0, FRunner.Host.ViewSize, 'applied when the menu closed');
  Assert.AreEqual(70, FRunner.Settings.GetInteger('camdelay'));
end;

procedure TTestGreedMenuMouse.DovrebbeRegolareLeOpzioniAncheInUnaFinestraPiccola;
var
  LScenario: TMenuScenario;
begin
  LScenario := Run(14);
  Assert.AreEqual(320, LScenario.WindowWidth);
  Assert.AreEqual(10, FRunner.Settings.GetInteger('musicvol'));
  Assert.AreEqual(182, FRunner.Settings.GetInteger('sfxvol'));
  Assert.AreEqual(70, FRunner.Settings.GetInteger('camdelay'));
end;

procedure TTestGreedMenuMouse.DovrebbeUscireConUnClicSuSi;
begin
  Run(3);
  Assert.IsTrue(FRunner.Host.QuitAsked);
  Assert.IsFalse(FRunner.Menu.Active);
end;

procedure TTestGreedMenuMouse.DovrebbeRestareConUnClicSuNo;
begin
  Run(4);
  Assert.IsFalse(FRunner.Host.QuitAsked);
  Assert.IsFalse(FRunner.Menu.Active, 'escape closed the menu after the panel');
  Assert.IsFalse(FRunner.Menu.QuitAnswer);
end;

procedure TTestGreedMenuMouse.DovrebbeIgnorareIClicFuoriDalleRisposteEMentreIlPannelloScende;
begin
  Run(5);
  Assert.IsFalse(FRunner.Host.QuitAsked, 'only the last click, on NO, was an answer');
  Assert.IsFalse(FRunner.Menu.QuitAnswer);
  Assert.IsFalse(FRunner.Menu.Active);
end;

procedure TTestGreedMenuMouse.DovrebbeCaricareUnaPartitaConDueClic;
begin
  Run(6);
  Assert.AreEqual(1, FRunner.Host.LoadedGames);
  Assert.AreEqual(2, FRunner.Host.LastSlot, 'the third game');
  Assert.AreEqual(3, FRunner.Menu.SavePosition);
  Assert.IsFalse(FRunner.Menu.Active);
end;

procedure TTestGreedMenuMouse.DovrebbeSalvareScegliendoLaPartitaConUnClic;
begin
  Run(7);
  Assert.AreEqual(1, FRunner.Host.SavedGames);
  Assert.AreEqual(4, FRunner.Host.LastSlot, 'the fifth game');
  Assert.IsTrue(FRunner.Menu.SaveNames[4].EndsWith('MOUSE 1Z'), 'the mouse does nothing while the name is typed: ' +
    FRunner.Menu.SaveNames[4]);
  Assert.IsFalse(FRunner.Menu.Active);
end;

procedure TTestGreedMenuMouse.DovrebbeAprireLAiutoERiprendereConIClic;
begin
  Run(8);
  Assert.IsTrue(gmsHelp in FRunner.StatesSeen);
  Assert.IsFalse(FRunner.Menu.Active, 'the click on "resume" closed the menu');
  Assert.AreEqual(0, FRunner.Host.NewGames);
end;

procedure TTestGreedMenuMouse.IlPannelloDaSoloDovrebbeRispondereAiClic;
begin
  Run(9);
  Assert.IsTrue(FRunner.Menu.QuitAnswer, 'YES, with the animation');
  Assert.IsFalse(FRunner.Menu.Active);
  Run(10);
  Assert.IsFalse(FRunner.Menu.QuitAnswer, 'NO, without');
  Assert.IsFalse(FRunner.Menu.Active);
  Assert.IsTrue(FRunner.Mouse.IsVisible, 'ShowQuit ends with MouseShow: who called it hides the pointer');
end;

procedure TTestGreedMenuMouse.NonDovrebbeVedereIClicSeIMenuNonUsanoIlMouse;
begin
  Run(11);
  Assert.IsFalse(FRunner.Menu.QuitAnswer, 'the click on YES was not seen, the key N was');
  Assert.IsFalse(FRunner.Menu.Active);
  Assert.IsFalse(FRunner.Mouse.IsVisible);
  Run(12);
  Assert.AreEqual(0, FRunner.Host.NewGames, 'the click on "new" was not seen');
  Assert.AreEqual(1, FRunner.Host.LoadedGames, 'the keys chose "load" and its third game');
  Assert.AreEqual(2, FRunner.Host.LastSlot);
end;

procedure TTestGreedMenuMouse.DovrebbeFunzionareInUnaFinestraPiuGrande;
var
  LScenario: TMenuScenario;
begin
  LScenario := Run(13);
  Assert.AreEqual(960, LScenario.WindowWidth);
  Assert.AreEqual(1, FRunner.Host.NewGames);
  Assert.AreEqual(4, FRunner.Host.LastCharacter, 'the fifth character');
  Assert.AreEqual(0, FRunner.Host.LastDifficulty, 'the last row');
end;

procedure TTestGreedMenuMouse.IlPuntatoreDovrebbeVincereSuiTasti;
begin
  Run(15);
  // with the pointer on "load" the two arrows down are undone at once and enter opens the saved games; there the
  // pointer is put on no entry and three arrows down choose the fourth game
  Assert.AreEqual(1, FRunner.Host.LoadedGames);
  Assert.AreEqual(3, FRunner.Host.LastSlot);
end;

procedure TTestGreedMenuMouse.DovrebbeAndareAvantiEIndietroTraIPersonaggi;
begin
  Run(19);
  Assert.AreEqual(1, FRunner.Host.NewGames);
  Assert.AreEqual(0, FRunner.Host.LastCharacter, 'the first character, chosen after going back');
  Assert.AreEqual(0, FRunner.Host.LastDifficulty);
end;

procedure TTestGreedMenuMouse.DovrebbeMostrareIlPuntatoreQuandoIlMenuSiApreENasconderloQuandoSiChiude;
var
  LScenario: TMenuScenario;
begin
  Open(0, LScenario);
  Assert.IsFalse(FRunner.Mouse.IsVisible);
  FRunner.Menu.OpenMenu;
  Assert.IsTrue(FRunner.Mouse.IsVisible);
  Tics(40);
  FRunner.Input.PressKey(gmkEscape, True);
  Tics(4);
  Assert.IsFalse(FRunner.Menu.Active);
  Assert.IsFalse(FRunner.Mouse.IsVisible);
end;

procedure TTestGreedMenuMouse.DovrebbeNascondereIlPuntatoreMentreSiScriveIlNome;
var
  LScenario: TMenuScenario;
begin
  LScenario := TMenuScenarios.Scenario(MENU_KEY_SCENARIOS);
  LScenario.Animation := False;
  LScenario.GameLoaded := True;
  FRunner.Prepare(LScenario);
  FRunner.Menu.OpenMenu(GREED_MENU_SAVE);
  Tics(12);
  PointTo(140, 36);
  Click;
  Assert.AreEqual(Ord(gmsSaveName), Ord(FRunner.Menu.State));
  Assert.IsFalse(FRunner.Mouse.IsVisible, 'GetSavedName hides the pointer');
  FRunner.Input.PressKey(gmkEnter, True);
  Tics(4);
  FRunner.Input.PressKey(gmkEnter, False);
  Assert.AreEqual(Ord(gmsMain), Ord(FRunner.Menu.State));
  Assert.IsTrue(FRunner.Mouse.IsVisible, 'and shows it again');
  Assert.AreEqual(1, FRunner.Host.SavedGames);
end;

procedure TTestGreedMenuMouse.DovrebbeRimettereIlCursoreAlCentroQuandoIlMenuSiChiude;
var
  LScenario: TMenuScenario;
  LBefore, LSteps: Integer;
begin
  Open(0, LScenario);
  FRunner.Menu.OpenMenu;
  Tics(40);
  FRunner.Input.PressKey(gmkEscape, True);
  LSteps := 0;
  repeat
    LBefore := FRunner.MouseFake.Positioned;
    FRunner.Menu.Tick;
    Inc(LSteps);
  until (not FRunner.Menu.Active) or (LSteps = 10);
  Assert.IsFalse(FRunner.Menu.Active);
  // the tic that closes the menu puts the cursor in the middle twice: the reading of the mouse, then ResetMouse
  Assert.AreEqual(2, FRunner.MouseFake.Positioned - LBefore);
  Assert.AreEqual(LScenario.WindowWidth div 2, FRunner.MouseFake.X);
  Assert.AreEqual(LScenario.WindowHeight div 2, FRunner.MouseFake.Y);
  Assert.AreEqual(1, FRunner.Host.ControlsReset);
end;

procedure TTestGreedMenuMouse.LaPausaELAiutoNonDovrebberoUsareIlMouse;
begin
  Run(17);
  Assert.IsFalse(FRunner.Menu.Active, 'the key closed the pause; the click before it did not');
  Assert.IsTrue(gmsPauseShow in FRunner.StatesSeen);
  Assert.IsFalse(FRunner.Mouse.IsVisible, 'ShowPause never shows the pointer');
  Run(18);
  Assert.IsFalse(FRunner.Menu.Active);
  Assert.IsFalse(FRunner.Mouse.IsVisible);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMenuMouse);

end.
