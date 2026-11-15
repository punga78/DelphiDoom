{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the menus of the map                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiMenu;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Intf, DelphiDoom.War.MapUi.Menu;

type
  /// <summary>A host that counts what the menus ask of it</summary>
  TMenuHostSpy = class(TInterfacedObject, IWarMapMenuHost)
  public
    Restarts: Integer;
    Continues: Integer;
    MainMenus: Integer;
    Quits: Integer;
    procedure RestartMap;
    procedure ContinueAfterGameOver;
    procedure ReturnToMainMenu;
    procedure QuitGame;
  end;

  /// <summary>A host that also saves and loads games (the program does)</summary>
  TMenuSessionsSpy = class(TMenuHostSpy, IWarMapMenuSessions)
  public
    Saves: Integer;
    Loads: Integer;
    procedure SaveGame;
    procedure LoadGame;
  end;

  /// <summary>The state of the menus of the map and what their buttons do (war_map_menu.c)</summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapMenu = class(TObject)
  strict private
    FHost: TMenuHostSpy;
    FHostRef: IWarMapMenuHost;
    FSettings: IWarGameSettings;
    FMenu: TWarMapMenu;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeIniziareConLaMappaCheGiraENessunMenu;
    [Test]
    procedure DovrebbeFermareLaMappaAprendoIlMenuERiprenderlaConContinua;
    [Test]
    procedure DovrebbeEditareUnaCopiaDelleOpzioniEPerderlaSeSiAnnulla;
    [Test]
    procedure DovrebbeTenereLeOpzioniConOkEAggiornareIVolumiDelGioco;
    [Test]
    procedure DovrebbeMostrareUnVolumeCheNonEEsattoConUnoInMeno;
    [Test]
    procedure DovrebbeFermarsiAiLimitiDelleVelocitaEDeiVolumi;
    [Test]
    procedure DovrebbeDireAlHostCosaFannoIBottoniCheLasciano;
    [Test]
    procedure DovrebbeNonFareNienteSenzaHostEConSalva;
    [Test]
    procedure DovrebbeChiedereAlHostCheSalvaICaricamentiESalvataggi;
    [Test]
    procedure DovrebbeLasciareISalvataggiComeNelOriginaleSeIlHostNonLiFa;
    [Test]
    procedure DovrebbeRiprendereQuandoSiChiudeIlMenuDellaFine;
    [Test]
    procedure DovrebbeFunzionareSenzaLeImpostazioniDelGioco;
    [Test]
    procedure DovrebbeTornareAlMenuPrincipaleDaOpzioniObiettiviRicominciaEUscita;
  end;

implementation

uses
  DelphiDoom.War.Ui.GameSettings, DelphiDoom.War.MapUi.Types;

{ TMenuHostSpy }

procedure TMenuHostSpy.RestartMap;
begin
  Inc(Restarts);
end;

procedure TMenuHostSpy.ContinueAfterGameOver;
begin
  Inc(Continues);
end;

procedure TMenuHostSpy.ReturnToMainMenu;
begin
  Inc(MainMenus);
end;

procedure TMenuHostSpy.QuitGame;
begin
  Inc(Quits);
end;

{ TTestWarMapMenu }

procedure TTestWarMapMenu.Setup;
begin
  FHost := TMenuHostSpy.Create;
  FHostRef := FHost;
  FSettings := TWarGameSettings.Create;
  FMenu := TWarMapMenu.Create(FHostRef, FSettings);
end;

procedure TTestWarMapMenu.TearDown;
begin
  FMenu.Free;
  FHostRef := nil;
  FSettings := nil;
end;

procedure TTestWarMapMenu.DovrebbeIniziareConLaMappaCheGiraENessunMenu;
begin
  Assert.IsTrue(FMenu.State = wmsNone);
  Assert.IsTrue(FMenu.Playing);
  Assert.AreEqual(WAR_SPEED_NORMAL, FMenu.Settings.GameSpeed);
  Assert.AreEqual(WAR_SPEED_NORMAL, FMenu.Settings.MouseScrollSpeed);
  Assert.AreEqual(WAR_SPEED_NORMAL, FMenu.Settings.KeyScrollSpeed);
end;

procedure TTestWarMapMenu.DovrebbeFermareLaMappaAprendoIlMenuERiprenderlaConContinua;
begin
  FMenu.OpenMain;
  Assert.IsTrue(FMenu.State = wmsMain);
  Assert.IsFalse(FMenu.Playing);
  FMenu.OpenQuit;
  Assert.IsTrue(FMenu.State = wmsQuit);
  FMenu.Back;
  Assert.IsTrue(FMenu.State = wmsMain);
  FMenu.Resume;
  Assert.IsTrue(FMenu.State = wmsNone);
  Assert.IsTrue(FMenu.Playing);
end;

procedure TTestWarMapMenu.DovrebbeEditareUnaCopiaDelleOpzioniEPerderlaSeSiAnnulla;
begin
  FMenu.OpenMain;
  FMenu.OpenOptions;
  Assert.IsTrue(FMenu.State = wmsOptions);
  FMenu.GameSpeedUp;
  FMenu.KeyScrollDown;
  Assert.AreEqual(WAR_SPEED_FASTER, FMenu.Pending.GameSpeed);
  Assert.AreEqual(WAR_SPEED_SLOW, FMenu.Pending.KeyScrollSpeed);
  // what is in force does not change until Ok
  Assert.AreEqual(WAR_SPEED_NORMAL, FMenu.Settings.GameSpeed);
  FMenu.Back;
  FMenu.OpenOptions;
  Assert.AreEqual(WAR_SPEED_NORMAL, FMenu.Pending.GameSpeed);
  Assert.AreEqual(WAR_SPEED_NORMAL, FMenu.Pending.KeyScrollSpeed);
end;

procedure TTestWarMapMenu.DovrebbeTenereLeOpzioniConOkEAggiornareIVolumiDelGioco;
begin
  FMenu.OpenOptions;
  Assert.AreEqual(100, FMenu.Pending.MusicVolume);
  FMenu.MusicVolumeDown;
  FMenu.MusicVolumeDown;
  FMenu.SoundVolumeDown;
  FMenu.MouseScrollUp;
  FMenu.GameSpeedDown;
  FMenu.ApplyOptions;
  Assert.IsTrue(FMenu.State = wmsMain);
  Assert.AreEqual(90, FMenu.Settings.MusicVolume);
  Assert.AreEqual(95, FMenu.Settings.SoundVolume);
  Assert.AreEqual(WAR_SPEED_FASTER, FMenu.Settings.MouseScrollSpeed);
  Assert.AreEqual(WAR_SPEED_SLOW, FMenu.Settings.GameSpeed);
  Assert.AreEqual(0.9, Double(FSettings.MusicVolume), 0.000001);
  Assert.AreEqual(0.95, Double(FSettings.SoundVolume), 0.000001);
end;

procedure TTestWarMapMenu.DovrebbeMostrareUnVolumeCheNonEEsattoConUnoInMeno;
begin
  // (s32)(volume * 100): 0.35 as a float is a little less than 0.35, so it shows 34 (the original does the same, in the
  // precision of the harness; with a float multiplication it would show 35)
  Assert.AreEqual(34, TWarMapMenu.PercentOf(Single(0.35)));
  Assert.AreEqual(50, TWarMapMenu.PercentOf(Single(0.5)));
  Assert.AreEqual(100, TWarMapMenu.PercentOf(Single(1)));
  Assert.AreEqual(0, TWarMapMenu.PercentOf(Single(0)));
  FSettings.SetMusicVolume(Single(35) / 100);
  FMenu.OpenOptions;
  Assert.AreEqual(34, FMenu.Pending.MusicVolume);
end;

procedure TTestWarMapMenu.DovrebbeFermarsiAiLimitiDelleVelocitaEDeiVolumi;
var
  LIndex: Integer;
begin
  FMenu.OpenOptions;
  for LIndex := 1 to 10 do
  begin
    FMenu.GameSpeedUp;
    FMenu.MouseScrollUp;
    FMenu.KeyScrollUp;
    FMenu.MusicVolumeUp;
    FMenu.SoundVolumeUp;
  end;
  Assert.AreEqual(WAR_SPEED_FASTEST, FMenu.Pending.GameSpeed);
  Assert.AreEqual(WAR_SPEED_FASTEST, FMenu.Pending.MouseScrollSpeed);
  Assert.AreEqual(WAR_SPEED_FASTEST, FMenu.Pending.KeyScrollSpeed);
  Assert.AreEqual(100, FMenu.Pending.MusicVolume);
  Assert.AreEqual(100, FMenu.Pending.SoundVolume);
  for LIndex := 1 to 30 do
  begin
    FMenu.GameSpeedDown;
    FMenu.MouseScrollDown;
    FMenu.KeyScrollDown;
    FMenu.MusicVolumeDown;
    FMenu.SoundVolumeDown;
  end;
  Assert.AreEqual(WAR_SPEED_SLOWEST, FMenu.Pending.GameSpeed);
  Assert.AreEqual(WAR_SPEED_SLOWEST, FMenu.Pending.MouseScrollSpeed);
  Assert.AreEqual(WAR_SPEED_SLOWEST, FMenu.Pending.KeyScrollSpeed);
  Assert.AreEqual(0, FMenu.Pending.MusicVolume);
  Assert.AreEqual(0, FMenu.Pending.SoundVolume);
end;

procedure TTestWarMapMenu.DovrebbeDireAlHostCosaFannoIBottoniCheLasciano;
begin
  FMenu.Restart;
  FMenu.ContinueAfterGameOver;
  FMenu.ContinueAfterGameOver;
  FMenu.ReturnToMainMenu;
  FMenu.QuitGame;
  Assert.AreEqual(1, FHost.Restarts);
  Assert.AreEqual(2, FHost.Continues);
  Assert.AreEqual(1, FHost.MainMenus);
  Assert.AreEqual(1, FHost.Quits);
end;

procedure TMenuSessionsSpy.SaveGame;
begin
  Inc(Saves);
end;

procedure TMenuSessionsSpy.LoadGame;
begin
  Inc(Loads);
end;

procedure TTestWarMapMenu.DovrebbeChiedereAlHostCheSalvaICaricamentiESalvataggi;
var
  LSpy: TMenuSessionsSpy;
  LSpyRef: IWarMapMenuHost;
  LMenu: TWarMapMenu;
begin
  LSpy := TMenuSessionsSpy.Create;
  LSpyRef := LSpy;
  LMenu := TWarMapMenu.Create(LSpyRef, nil);
  try
    LMenu.SaveGame;
    LMenu.LoadGame;
    LMenu.LoadGame;
    LMenu.SaveAfterGameOver;
    Assert.AreEqual(2, LSpy.Saves);
    Assert.AreEqual(2, LSpy.Loads);
    Assert.AreEqual(0, LSpy.Restarts, 'salvare non fa altro');
  finally
    LMenu.Free;
    LSpyRef := nil;
  end;
end;

procedure TTestWarMapMenu.DovrebbeLasciareISalvataggiComeNelOriginaleSeIlHostNonLiFa;
begin
  FMenu.SaveGame;
  FMenu.LoadGame;
  FMenu.SaveAfterGameOver;
  Assert.AreEqual(0, FHost.Restarts);
  Assert.AreEqual(0, FHost.Quits);
  Assert.IsTrue(FMenu.Playing);
end;

procedure TTestWarMapMenu.DovrebbeNonFareNienteSenzaHostEConSalva;
var
  LMenu: TWarMapMenu;
begin
  LMenu := TWarMapMenu.Create(nil, nil);
  try
    LMenu.Restart;
    LMenu.ContinueAfterGameOver;
    LMenu.ReturnToMainMenu;
    LMenu.QuitGame;
    LMenu.ShowGameOver(True);
    // Save is NOT_IMPLEMENTED() in the original: it only writes a line
    LMenu.SaveAfterGameOver;
    Assert.IsTrue(LMenu.State = wmsGameOver);
  finally
    LMenu.Free;
  end;
  Assert.AreEqual(0, FHost.Restarts);
end;

procedure TTestWarMapMenu.DovrebbeRiprendereQuandoSiChiudeIlMenuDellaFine;
begin
  FMenu.ShowGameOver(True);
  Assert.IsTrue(FMenu.State = wmsGameOver);
  Assert.IsFalse(FMenu.Playing);
  FMenu.ShowGameOver(False);
  Assert.IsTrue(FMenu.State = wmsNone);
  Assert.IsTrue(FMenu.Playing);
  FMenu.ShowDemoEnd(True);
  Assert.IsTrue(FMenu.State = wmsDemoEnd);
  Assert.IsFalse(FMenu.Playing);
  FMenu.ShowDemoEnd(False);
  Assert.IsTrue(FMenu.State = wmsNone);
  Assert.IsTrue(FMenu.Playing);
end;

procedure TTestWarMapMenu.DovrebbeFunzionareSenzaLeImpostazioniDelGioco;
var
  LMenu: TWarMapMenu;
begin
  LMenu := TWarMapMenu.Create(FHostRef, nil);
  try
    LMenu.OpenOptions;
    LMenu.MusicVolumeDown;
    LMenu.ApplyOptions;
    // with no settings of the game the volumes of the menu stay at 0 and nothing else changes
    Assert.AreEqual(0, LMenu.Settings.MusicVolume);
    Assert.IsTrue(LMenu.State = wmsMain);
  finally
    LMenu.Free;
  end;
end;

procedure TTestWarMapMenu.DovrebbeTornareAlMenuPrincipaleDaOpzioniObiettiviRicominciaEUscita;
begin
  FMenu.OpenOptions;
  FMenu.Back;
  Assert.IsTrue(FMenu.State = wmsMain);
  FMenu.OpenObjectives;
  Assert.IsTrue(FMenu.State = wmsObjectives);
  FMenu.Back;
  FMenu.OpenRestart;
  Assert.IsTrue(FMenu.State = wmsRestart);
  FMenu.Back;
  Assert.IsTrue(FMenu.State = wmsMain);
  Assert.IsFalse(FMenu.Playing);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapMenu);

end.
