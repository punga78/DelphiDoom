{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the monthly report screen of the geoscape              }
{  (MonthlyReportState::btnOkClick of OpenXcom)                                }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.MonthlyReportState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomStrategy.MonthlyReport, DelphiDoom.XcomGeoscape.Control.Intf,
  DelphiDoom.XcomBasescape.Navigator.Intf, DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomGeoscape.Popups;

type
  /// <summary>The saver of the host: it counts what the screens ask</summary>
  TFakeSaver = class(TInterfacedObject, IXcomSavedGameSaver)
  strict private
    FIronman: Boolean;
    FName: string;
    FSaved: string;
    FAbandoned: Integer;
  public
    function IsIronman: Boolean;
    procedure SetName(const AName: string);
    function GetName: string;
    procedure SaveGame(const AFileName: string);
    procedure AbandonGame;
    property Ironman: Boolean read FIronman write FIronman;
    property Saved: string read FSaved;
    property Abandoned: Integer read FAbandoned;
  end;

  [TestFixture]
  [Category('xcom-geoscape')]
  TTestXcomMonthlyReportState = class(TObject)
  strict private
    FWorld: TTestWorld;
    FSave: TXcomSavedGame;
    FControl: TFakeControl;
    FControlRef: IXcomGeoscapeControl;
    FSaver: TFakeSaver;
    FSaverRef: IXcomSavedGameSaver;
    function Push(AGameOver, APsi: Boolean): TXcomState;
    procedure PressOk;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeChiudersiConOkSeIlGiocoContinua;
    [Test]
    procedure DovrebbeAprireLAddestramentoPsiDopoIlRapporto;
    [Test]
    procedure DovrebbeSalvareDaSoloDopoIlRapporto;
    [Test]
    procedure NonDovrebbeSalvareDaSoloSeLOpzioneESpenta;
    [Test]
    procedure DovrebbeMostrareIlFallimentoAlPrimoOkEAprireLeStatisticheAlSecondo;
    [Test]
    procedure DovrebbeSegnareLaSconfittaNelSalvataggio;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomSave.SavedGameHolder, DelphiDoom.XcomGeoscape.MonthlyReportState;

{ TFakeSaver }

procedure TFakeSaver.AbandonGame;
begin
  Inc(FAbandoned);
end;

function TFakeSaver.GetName: string;
begin
  Result := FName;
end;

function TFakeSaver.IsIronman: Boolean;
begin
  Result := FIronman;
end;

procedure TFakeSaver.SaveGame(const AFileName: string);
begin
  FSaved := AFileName;
end;

procedure TFakeSaver.SetName(const AName: string);
begin
  FName := AName;
end;

{ TTestXcomMonthlyReportState }

procedure TTestXcomMonthlyReportState.Setup;
begin
  FWorld := TTestWorld.Create;
  FSave := TXcomSavedGame.Create;
  // the report shows the maintenance of the month before the last
  FSave.MonthlyFunding(0);
  FSave.MonthlyFunding(0);
  FWorld.Game.SetSession(TXcomSavedGameHolder.Create(FSave, nil));
  FControl := TFakeControl.Create;
  FControlRef := FControl;
  FSaver := TFakeSaver.Create;
  FSaverRef := FSaver;
  FWorld.Game.SetSavedGameSaver(FSaverRef);
  FWorld.Game.Options.SetBool('autosave', True);
end;

procedure TTestXcomMonthlyReportState.TearDown;
begin
  FWorld.Game.SetSavedGameSaver(nil);
  FWorld.Game.SetSession(nil);
  FControlRef := nil;
  FSaverRef := nil;
  FWorld.Free;
end;

function TTestXcomMonthlyReportState.Push(AGameOver, APsi: Boolean): TXcomState;
var
  LResult: TXcomMonthlyReportResult;
begin
  LResult := Default(TXcomMonthlyReportResult);
  LResult.Rating := 'STR_RATING_OK';
  LResult.Satisfaction := 'STR_COUNCIL_IS_GENERALLY_SATISFIED';
  LResult.GameOver := AGameOver;
  Result := TXcomMonthlyReportState.Create(FWorld.Game, LResult, APsi, FControlRef);
  FWorld.Game.PushState(Result);
  FWorld.Wait(400);
end;

procedure TTestXcomMonthlyReportState.PressOk;
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := XCOM_KEY_RETURN;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(40);
  LEvent.Kind := ekKeyUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(60);
end;

procedure TTestXcomMonthlyReportState.DovrebbeChiudersiConOkSeIlGiocoContinua;
var
  LState: TXcomState;
begin
  LState := Push(False, False);
  PressOk;
  Assert.IsFalse(FWorld.Game.IsState(LState), 'il rapporto si chiude');
  Assert.AreEqual(Ord(bsNewBase), Ord(FControl.OpenedScreen), 'nessuna schermata aperta senza laboratori psi');
end;

procedure TTestXcomMonthlyReportState.DovrebbeAprireLAddestramentoPsiDopoIlRapporto;
begin
  Push(False, True);
  PressOk;
  Assert.AreEqual(Ord(bsPsiTraining), Ord(FControl.OpenedScreen));
  Assert.IsNull(FControl.OpenedBase, 'tutte le basi con laboratori');
end;

procedure TTestXcomMonthlyReportState.DovrebbeSalvareDaSoloDopoIlRapporto;
begin
  Push(False, False);
  PressOk;
  // SaveGameState waits ten turns before it writes the file
  FWorld.Wait(400);
  Assert.AreEqual('_autogeo_.asav', FSaver.Saved);
end;

procedure TTestXcomMonthlyReportState.NonDovrebbeSalvareDaSoloSeLOpzioneESpenta;
begin
  FWorld.Game.Options.SetBool('autosave', False);
  Push(False, False);
  PressOk;
  FWorld.Wait(400);
  Assert.AreEqual('', FSaver.Saved);
end;

procedure TTestXcomMonthlyReportState.DovrebbeMostrareIlFallimentoAlPrimoOkEAprireLeStatisticheAlSecondo;
var
  LState: TXcomState;
begin
  LState := Push(True, False);
  PressOk;
  Assert.IsTrue(FWorld.Game.IsState(LState), 'il primo OK mostra il testo della sconfitta');
  Assert.AreNotEqual(Ord(bsStatistics), Ord(FControl.OpenedScreen));
  PressOk;
  Assert.AreEqual(Ord(bsStatistics), Ord(FControl.OpenedScreen), 'il secondo OK porta alle statistiche del gioco');
  Assert.AreEqual('', FSaver.Saved, 'una partita persa non si salva da sola');
end;

procedure TTestXcomMonthlyReportState.DovrebbeSegnareLaSconfittaNelSalvataggio;
begin
  Push(True, False);
  Assert.AreEqual(2, FSave.EndingKind, 'END_LOSE');
end;

end.
