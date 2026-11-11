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
    [Test]
    procedure DovrebbeDareLeMedaglieDelMeseDiServizio;
    [Test]
    procedure NonDovrebbeChiamareNessunoSeNessunoHaUnaMedaglia;
    [Test]
    procedure DovrebbeContareIlMeseDiServizioAncheSenzaRegoleDelleMedaglie;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.RulesetDiaryRules, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomSave.SavedGameHolder,
  DelphiDoom.XcomGeoscape.MonthlyReportState;

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

type
  /// <summary>The sizes of the shared sets that a ruleset asks for (none of the rules of the test uses them)</summary>
  TMedalShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

function TMedalShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TMedalShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 100;
end;

/// <summary>The rules of a medal for a number of months of service</summary>
function MedalRules(AMonths: Integer): TXcomRuleset;
begin
  Result := TXcomRuleset.Create(TMedalShared.Create);
  Result.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
  Result.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(Format(
    '{commendations: [{type: STR_MEDAL_SERVICE, criteria: {totalMonthlyService: [%d]}}]}', [AMonths]))));
end;

procedure TTestXcomMonthlyReportState.DovrebbeDareLeMedaglieDelMeseDiServizio;
var
  LRuleset: TXcomRuleset;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LState: TXcomMonthlyReportState;
  LCalls: Integer;
  LNames: string;
begin
  LRuleset := MedalRules(1);
  try
    LBase := TXcomBase.Create;
    FSave.Bases.Add(LBase);
    // id 0: a soldier as a saved game loads it, with no rules to roll its statistics from
    LSoldier := TXcomSoldier.Create(nil, nil, 0, nil);
    LSoldier.Name := 'Ada';
    LBase.Soldiers.Add(LSoldier);
    LCalls := 0;
    LState := Push(False, False) as TXcomMonthlyReportState;
    LState.SetMedals(TXcomRulesetDiaryRules.Create(LRuleset),
      procedure(ASoldiers: TList<TXcomSoldier>)
      var
        LMedalled: TXcomSoldier;
      begin
        Inc(LCalls);
        for LMedalled in ASoldiers do
          LNames := LNames + LMedalled.Name;
      end);
    PressOk;
    Assert.AreEqual(1, LCalls);
    Assert.AreEqual('Ada', LNames);
    Assert.AreEqual(1, LSoldier.Diary.Commendations.Count);
    Assert.AreEqual('STR_MEDAL_SERVICE', LSoldier.Diary.Commendations[0].CommendationType);
  finally
    LRuleset.Free;
  end;
end;

procedure TTestXcomMonthlyReportState.NonDovrebbeChiamareNessunoSeNessunoHaUnaMedaglia;
var
  LRuleset: TXcomRuleset;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LState: TXcomMonthlyReportState;
  LCalls: Integer;
begin
  // the medal wants three months: the first one is not enough
  LRuleset := MedalRules(3);
  try
    LBase := TXcomBase.Create;
    FSave.Bases.Add(LBase);
    LSoldier := TXcomSoldier.Create(nil, nil, 0, nil);
    LBase.Soldiers.Add(LSoldier);
    LCalls := 0;
    LState := Push(False, False) as TXcomMonthlyReportState;
    LState.SetMedals(TXcomRulesetDiaryRules.Create(LRuleset),
      procedure(ASoldiers: TList<TXcomSoldier>)
      begin
        Inc(LCalls);
      end);
    PressOk;
    Assert.AreEqual(0, LCalls);
    Assert.AreEqual(0, LSoldier.Diary.Commendations.Count);
    Assert.AreEqual(1, LSoldier.Diary.Counter('monthsService'));
  finally
    LRuleset.Free;
  end;
end;

procedure TTestXcomMonthlyReportState.DovrebbeContareIlMeseDiServizioAncheSenzaRegoleDelleMedaglie;
var
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
begin
  LBase := TXcomBase.Create;
  FSave.Bases.Add(LBase);
  LSoldier := TXcomSoldier.Create(nil, nil, 0, nil);
  LBase.Soldiers.Add(LSoldier);
  Push(False, False);
  PressOk;
  Assert.AreEqual(1, LSoldier.Diary.Counter('monthsService'));
end;

end.
