{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom debriefing library - the screens (with    }
{  the fake game of the engine tests)                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomDebriefing.States;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomDebriefing.Types,
  DelphiDoom.Tests.XcomEngine.World;

type
  TStateCracker = class(TXcomState);

  [TestFixture]
  [Category('xcom-debriefing')]
  TTestXcomDebriefingStates = class(TObject)
  strict private
    FWorld: TTestWorld;
    FReport: TXcomDebriefingReport;
    function FindButton(AState: TXcomState; AIndex: Integer): TXcomTextButton;
    procedure ClickButton(AButton: TXcomTextButton);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMostrareSoloLeRigheConQuantita;
    [Test]
    procedure DovrebbeSeparareLeRigheDelRecuperoDaQuelleDelleStatistiche;
    [Test]
    procedure DovrebbeScrivereIlTotaleEIlGiudizio;
    [Test]
    procedure DovrebbeCambiarePaginaConIlPulsanteDelleStatistiche;
    [Test]
    procedure DovrebbeSegnareSoloLeStatisticheCheSonoMigliorate;
    [Test]
    procedure DovrebbeChiudersiEChiamareLaFineConOk;
    [Test]
    procedure DovrebbeSuonareLaMusicaDelDebriefingUnaVoltaSola;
    [Test]
    procedure NonDovrebbeCambiareMusicaSenzaUnNome;
    [Test]
    procedure DovrebbeElencareGliOggettiCheMancanoAlVelivolo;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomDebriefing.DebriefingState,
  DelphiDoom.XcomDebriefing.CannotReequipState;

procedure TTestXcomDebriefingStates.Setup;
var
  LImprovement: TXcomSoldierImprovement;
  LStat: TXcomDebriefingStat;
begin
  FWorld := TTestWorld.Create;
  FReport := TXcomDebriefingReport.Create;
  FReport.Title := 'STR_ALIENS_DEFEATED';
  FReport.Rating := 'STR_RATING_OK';
  FReport.Total := 150;
  LStat := TXcomDebriefingStat.Create('STR_ALIENS_KILLED', False);
  LStat.Quantity := 3;
  LStat.Score := 90;
  FReport.Stats.Add(LStat);
  FReport.Stats.Add(TXcomDebriefingStat.Create('STR_ALIEN_CORPSES_RECOVERED', False));
  LStat := TXcomDebriefingStat.Create('STR_ALIEN_CRYOGENICS', True);
  LStat.Quantity := 4;
  LStat.Score := 60;
  FReport.Stats.Add(LStat);
  FReport.RecoveryTitle := 'STR_UFO_RECOVERY';
  LImprovement.Name := 'Eleni Mechela';
  LImprovement.Stats := Default(TXcomUnitStats);
  LImprovement.Stats.Firing := 2;
  LImprovement.Stats.Strength := 1;
  FReport.SoldierStats.Add(LImprovement);
end;

procedure TTestXcomDebriefingStates.TearDown;
begin
  FReport.Free;
  FWorld.Free;
end;

function TTestXcomDebriefingStates.FindButton(AState: TXcomState; AIndex: Integer): TXcomTextButton;
var
  LWidget: TXcomWidget;
  LCount: Integer;
begin
  LCount := 0;
  for LWidget in TStateCracker(AState).Surfaces do
    if LWidget is TXcomTextButton then
    begin
      if LCount = AIndex then
        Exit(TXcomTextButton(LWidget));
      Inc(LCount);
    end;
  Result := nil;
end;

procedure TTestXcomDebriefingStates.ClickButton(AButton: TXcomTextButton);
begin
  FWorld.Wait(400);
  FWorld.Click((AButton.X + AButton.Width div 2) * 2, (AButton.Y + AButton.Height div 2) * 2);
end;

procedure TTestXcomDebriefingStates.DovrebbeMostrareSoloLeRigheConQuantita;
var
  LState: TXcomDebriefingState;
begin
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(1, LState.StatsList.GetRows);
  // the cells of a list with dots end with the dots
  Assert.IsTrue(LState.StatsList.GetCellText(0, 0).StartsWith('STR_ALIENS_KILLED.'));
end;

procedure TTestXcomDebriefingStates.DovrebbeSeparareLeRigheDelRecuperoDaQuelleDelleStatistiche;
var
  LState: TXcomDebriefingState;
begin
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(1, LState.RecoveryList.GetRows);
  Assert.IsTrue(LState.RecoveryList.GetCellText(0, 0).StartsWith('STR_ALIEN_CRYOGENICS.'));
  Assert.AreEqual('STR_UFO_RECOVERY', LState.RecoveryText.GetText);
  // la lista del recupero sta sotto quella delle statistiche
  Assert.AreEqual(LState.StatsList.Y + 8 + 5 + 8, LState.RecoveryList.Y);
end;

procedure TTestXcomDebriefingStates.DovrebbeScrivereIlTotaleEIlGiudizio;
var
  LState: TXcomDebriefingState;
begin
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
  FWorld.Game.PushState(LState);
  Assert.AreEqual('150', LState.TotalList.GetCellText(0, 1));
  Assert.AreEqual('STR_ALIENS_DEFEATED', LState.TitleText.GetText);
end;

procedure TTestXcomDebriefingStates.DovrebbeCambiarePaginaConIlPulsanteDelleStatistiche;
var
  LState: TXcomDebriefingState;
begin
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
  FWorld.Game.PushState(LState);
  Assert.IsFalse(LState.ShowSoldierStats);
  ClickButton(FindButton(LState, 1));
  Assert.IsTrue(LState.ShowSoldierStats);
  Assert.IsFalse(LState.StatsList.Visible);
  Assert.IsTrue(LState.SoldierStatsList.Visible);
end;

procedure TTestXcomDebriefingStates.DovrebbeSegnareSoloLeStatisticheCheSonoMigliorate;
var
  LState: TXcomDebriefingState;
begin
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
  FWorld.Game.PushState(LState);
  Assert.IsTrue(LState.SoldierStatsList.GetCellText(0, 0).StartsWith('Eleni Mechela.'));
  Assert.IsTrue(LState.SoldierStatsList.GetCellText(0, 1).StartsWith('.'));
  // l'ordine delle colonne: ... tiro, lancio, corpo a corpo, forza ...
  Assert.IsTrue(LState.SoldierStatsList.GetCellText(0, 6).Contains('+2'), LState.SoldierStatsList.GetCellText(0, 6));
  Assert.IsTrue(LState.SoldierStatsList.GetCellText(0, 9).Contains('+1'), LState.SoldierStatsList.GetCellText(0, 9));
end;

procedure TTestXcomDebriefingStates.DovrebbeChiudersiEChiamareLaFineConOk;
var
  LState: TXcomDebriefingState;
  LCalled: Boolean;
begin
  LCalled := False;
  LState := TXcomDebriefingState.Create(FWorld.Game, FReport,
    procedure(const AReport: TXcomDebriefingReport)
    begin
      LCalled := AReport = FReport;
    end);
  FWorld.Game.PushState(LState);
  ClickButton(FindButton(LState, 0));
  Assert.IsTrue(LCalled);
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

type
  /// <summary>IXcomMusicPlayer that writes down the music it is asked for</summary>
  TRecordingMusic = class(TInterfacedObject, IXcomMusicPlayer)
  public
    Names: string;
    procedure Reload(const AResources: IXcomResources);
    procedure PlayMusic(const AName: string; AId: Integer = 0);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    function IsPlaying: Boolean;
    function CurrentFormat: string;
    function LoadedCount: Integer;
  end;

procedure TRecordingMusic.Reload(const AResources: IXcomResources);
begin
end;

procedure TRecordingMusic.PlayMusic(const AName: string; AId: Integer);
begin
  Names := Names + AName + ';';
end;

procedure TRecordingMusic.Stop;
begin
end;

procedure TRecordingMusic.Pause;
begin
end;

procedure TRecordingMusic.Resume;
begin
end;

function TRecordingMusic.IsPlaying: Boolean;
begin
  Result := Names <> '';
end;

function TRecordingMusic.CurrentFormat: string;
begin
  Result := 'Adlib';
end;

function TRecordingMusic.LoadedCount: Integer;
begin
  Result := 0;
end;

procedure TTestXcomDebriefingStates.DovrebbeSuonareLaMusicaDelDebriefingUnaVoltaSola;
var
  LMusic: TRecordingMusic;
  LMusicRef: IXcomMusicPlayer;
  LState: TXcomDebriefingState;
  LOver: TXcomState;
begin
  LMusic := TRecordingMusic.Create;
  LMusicRef := LMusic;
  FWorld.Game.SetMusicPlayer(LMusicRef);
  try
    LState := TXcomDebriefingState.Create(FWorld.Game, FReport, nil);
    LState.Music := 'GMDEBGOO';
    FWorld.Game.PushState(LState);
    FWorld.Wait(100);
    Assert.AreEqual('GMDEBGOO;', LMusic.Names);
    // a screen over the debriefing and back: the music does not start again
    LOver := TXcomState.Create(FWorld.Game);
    FWorld.Game.PushState(LOver);
    FWorld.Wait(100);
    FWorld.Game.PopState;
    FWorld.Wait(100);
    Assert.AreEqual('GMDEBGOO;', LMusic.Names);
  finally
    FWorld.Game.SetMusicPlayer(nil);
  end;
end;

procedure TTestXcomDebriefingStates.NonDovrebbeCambiareMusicaSenzaUnNome;
var
  LMusic: TRecordingMusic;
  LMusicRef: IXcomMusicPlayer;
begin
  LMusic := TRecordingMusic.Create;
  LMusicRef := LMusic;
  FWorld.Game.SetMusicPlayer(LMusicRef);
  try
    FWorld.Game.PushState(TXcomDebriefingState.Create(FWorld.Game, FReport, nil));
    FWorld.Wait(100);
    Assert.AreEqual('', LMusic.Names);
  finally
    FWorld.Game.SetMusicPlayer(nil);
  end;
end;

procedure TTestXcomDebriefingStates.DovrebbeElencareGliOggettiCheMancanoAlVelivolo;
var
  LStat: TXcomReequipStat;
  LState: TXcomCannotReequipState;
begin
  LStat.Item := 'STR_GAUSS_CANNON';
  LStat.Quantity := 2;
  LStat.CraftName := 'TRITON-1';
  FReport.MissingItems.Add(LStat);
  LState := TXcomCannotReequipState.Create(FWorld.Game, FReport.MissingItems);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(1, LState.List.GetRows);
  Assert.AreEqual('2', LState.List.GetCellText(0, 1));
  Assert.AreEqual('TRITON-1', LState.List.GetCellText(0, 2));
  ClickButton(FindButton(LState, 0));
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomDebriefingStates);

end.
