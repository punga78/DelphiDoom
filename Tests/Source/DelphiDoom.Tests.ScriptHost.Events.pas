{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the events of the scripts                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Events;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Factory,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Types,
  DelphiDoom.Logging.Recorder,
  DelphiDoom.ScriptHost.Events.Intf,
  DelphiDoom.Tests.ScriptHost.Interpreter;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostEvents = class(TObject)
  private
    FRecorder: TLogRecorder;
    FRecorderRef: ILogSink;
    FLog: ILog;
    FInterpreter: TTestInterpreter;
    FEvents: IScriptEvents;
    procedure Load(const ASource: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonFareNullaSenzaProcedure;
    [Test]
    procedure DovrebbeNonFareNullaSeLeProcedureNonSonoCollegate;
    [Test]
    procedure DovrebbeChiamareOnTickConIlParametro;
    [Test]
    procedure DovrebbeChiamareOnMapStartSenzaParametri;
    [Test]
    procedure DovrebbeDareIParametriNellOrdineGiusto;
    [Test]
    procedure DovrebbeDareLeChiamateDiTimerEDiLinea;
    [Test]
    procedure DovrebbeLasciarePerdereUnEventoCheLoScriptNonHa;
    [Test]
    procedure DovrebbeDimenticareLeProcedureConClear;
    [Test]
    procedure DovrebbeAvvisareESaltareUnEccezioneDelloScript;
    [Test]
    procedure DovrebbeDareErroreSeLInterpreteOIlLogSononil;
    [Test]
    procedure DovrebbeAvereDieciEventiNellaTabella;
  end;

implementation

uses
  ps_defs,
  ps_utils,
  ps_runtime,
  DelphiDoom.ScriptHost.Events.Table,
  DelphiDoom.ScriptHost.Factory;

const
  // an integer that the events of the test change, then readable at the position 0
  SCRIPT_TICK =
    'var Total: Integer;'#13#10 +
    'event OnTick(const tick: Integer);'#13#10 +
    'begin'#13#10 +
    '  Total := Total + tick;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.';

{ TTestScriptHostEvents }

procedure TTestScriptHostEvents.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FRecorderRef := FRecorder;
  FLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderRef), nil);
end;

procedure TTestScriptHostEvents.TearDown;
begin
  FEvents := nil;
  FreeAndNil(FInterpreter);
  FLog := nil;
  FRecorderRef := nil;
end;

procedure TTestScriptHostEvents.Load(const ASource: string);
begin
  FreeAndNil(FInterpreter);
  FInterpreter := TTestInterpreter.Create(ASource, True);
  FEvents := TScriptHostFactory.CreateEvents(FInterpreter.Exec, FLog);
  FEvents.LinkEvents;
end;

procedure TTestScriptHostEvents.DovrebbeNonFareNullaSenzaProcedure;
begin
  Load('begin'#13#10'end.');
  FEvents.ProcTick(1);
  FEvents.ProcMapStart;
  FEvents.ProcActorDied(1, 2);
  FEvents.ProcPlayerEnter(0);
  FEvents.ProcPlayerDied(0, 1);
  FEvents.ProcCrossLine(1, 2, 3);
  FEvents.ProcShootLine(1, 2, 3);
  FEvents.ProcUseLine(1, 2, 3);
  FEvents.ProcTimerEverySecond(1);
  FEvents.ProcTimerEveryMinute(1);
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestScriptHostEvents.DovrebbeNonFareNullaSeLeProcedureNonSonoCollegate;
begin
  Load(SCRIPT_TICK);
  FEvents.Clear;
  FEvents.ProcTick(5);
  Assert.AreEqual(0, FInterpreter.IntegerOf(0));
end;

procedure TTestScriptHostEvents.DovrebbeChiamareOnTickConIlParametro;
begin
  Load(SCRIPT_TICK);
  FEvents.ProcTick(5);
  FEvents.ProcTick(7);
  Assert.AreEqual(12, FInterpreter.IntegerOf(0));
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestScriptHostEvents.DovrebbeChiamareOnMapStartSenzaParametri;
begin
  Load(
    'var Started: Integer;'#13#10 +
    'event OnMapStart;'#13#10 +
    'begin'#13#10 +
    '  Started := Started + 1;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.');
  FEvents.ProcMapStart;
  FEvents.ProcMapStart;
  Assert.AreEqual(2, FInterpreter.IntegerOf(0));
end;

procedure TTestScriptHostEvents.DovrebbeDareIParametriNellOrdineGiusto;
begin
  // 1000 * first + 10 * second + third, for the events with 1, 2 and 3 parameters
  Load(
    'var Died, PlayerDied, Crossed: Integer;'#13#10 +
    'event OnActorDied(const actorKEY: Integer; const killer: Integer);'#13#10 +
    'begin'#13#10 +
    '  Died := actorKEY * 10 + killer;'#13#10 +
    'end;'#13#10 +
    'event OnPlayerDied(const playerNO: integer; const killer: Integer);'#13#10 +
    'begin'#13#10 +
    '  PlayerDied := playerNO * 10 + killer;'#13#10 +
    'end;'#13#10 +
    'event OnCrossLine(const actorKEY: Integer; const lineNO: Integer; const oldside: Integer);'#13#10 +
    'begin'#13#10 +
    '  Crossed := actorKEY * 100 + lineNO * 10 + oldside;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.');
  FEvents.ProcActorDied(4, 9);
  FEvents.ProcPlayerDied(3, 8);
  FEvents.ProcCrossLine(1, 2, 3);
  Assert.AreEqual(49, FInterpreter.IntegerOf(0));
  Assert.AreEqual(38, FInterpreter.IntegerOf(1));
  Assert.AreEqual(123, FInterpreter.IntegerOf(2));
end;

procedure TTestScriptHostEvents.DovrebbeDareLeChiamateDiTimerEDiLinea;
begin
  Load(
    'var Seconds, Minutes, Shot, Used, Entered: Integer;'#13#10 +
    'event OnTimerEverySecond(const second: Integer);'#13#10 +
    'begin'#13#10 +
    '  Seconds := second;'#13#10 +
    'end;'#13#10 +
    'event OnTimerEveryMinute(const minute: integer);'#13#10 +
    'begin'#13#10 +
    '  Minutes := minute;'#13#10 +
    'end;'#13#10 +
    'event OnShootLine(const actorKEY: Integer; const lineNO: Integer; const side: Integer);'#13#10 +
    'begin'#13#10 +
    '  Shot := lineNO * 10 + side;'#13#10 +
    'end;'#13#10 +
    'event OnUseLine(const actorKEY: Integer; const lineNO: Integer; const side: Integer);'#13#10 +
    'begin'#13#10 +
    '  Used := lineNO * 10 + side;'#13#10 +
    'end;'#13#10 +
    'event OnPlayerEnter(const playerNO: integer);'#13#10 +
    'begin'#13#10 +
    '  Entered := playerNO + 100;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.');
  FEvents.ProcTimerEverySecond(6);
  FEvents.ProcTimerEveryMinute(2);
  FEvents.ProcShootLine(1, 5, 1);
  FEvents.ProcUseLine(1, 7, 0);
  FEvents.ProcPlayerEnter(2);
  Assert.AreEqual(6, FInterpreter.IntegerOf(0));
  Assert.AreEqual(2, FInterpreter.IntegerOf(1));
  Assert.AreEqual(51, FInterpreter.IntegerOf(2));
  Assert.AreEqual(70, FInterpreter.IntegerOf(3));
  Assert.AreEqual(102, FInterpreter.IntegerOf(4));
end;

procedure TTestScriptHostEvents.DovrebbeLasciarePerdereUnEventoCheLoScriptNonHa;
begin
  Load(SCRIPT_TICK);
  // the script has OnTick only
  FEvents.ProcMapStart;
  FEvents.ProcTimerEverySecond(1);
  FEvents.ProcTick(3);
  Assert.AreEqual(3, FInterpreter.IntegerOf(0));
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestScriptHostEvents.DovrebbeDimenticareLeProcedureConClear;
begin
  Load(SCRIPT_TICK);
  FEvents.ProcTick(1);
  FEvents.Clear;
  FEvents.ProcTick(100);
  Assert.AreEqual(1, FInterpreter.IntegerOf(0));
  // and a new link finds them again
  FEvents.LinkEvents;
  FEvents.ProcTick(100);
  Assert.AreEqual(101, FInterpreter.IntegerOf(0));
end;

procedure TTestScriptHostEvents.DovrebbeAvvisareESaltareUnEccezioneDelloScript;
begin
  Load(
    'var Zero, After: Integer;'#13#10 +
    'event OnTick(const tick: Integer);'#13#10 +
    'begin'#13#10 +
    '  After := 1;'#13#10 +
    '  RaiseException(erCustomError, ''boom'');'#13#10 +
    '  After := 2;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.');
  // the game goes on: the exception of the script is a warning
  FEvents.ProcTick(1);
  Assert.IsTrue(Pos('TScriptEvents.RunProc():Exception in script', FRecorder.TextOf(TLogChannel.Output)) > 0);
  Assert.IsTrue(Pos('ONTICK', UpperCase(FRecorder.TextOf(TLogChannel.Output))) > 0);
  // the procedure stopped at the exception
  Assert.AreEqual(1, FInterpreter.IntegerOf(1));
end;

procedure TTestScriptHostEvents.DovrebbeDareErroreSeLInterpreteOIlLogSononil;
begin
  Load(SCRIPT_TICK);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateEvents(nil, FLog);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateEvents(FInterpreter.Exec, nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostEvents.DovrebbeAvereDieciEventiNellaTabella;
var
  LIndex: Integer;
begin
  Assert.AreEqual(10, SCRIPT_EVENT_COUNT);
  for LIndex := Low(SCRIPT_EVENT_SIGNATURES) to High(SCRIPT_EVENT_SIGNATURES) do
  begin
    Assert.AreEqual(string(SCRIPT_EVENT_SIGNATURES[LIndex].Name), UpperCase(string(SCRIPT_EVENT_SIGNATURES[LIndex].Name)));
    // the template starts with the keyword and the name of the event
    Assert.IsTrue(Pos('EVENT ' + string(SCRIPT_EVENT_SIGNATURES[LIndex].Name),
      UpperCase(string(SCRIPT_EVENT_SIGNATURES[LIndex].Template))) = 1);
    Assert.IsTrue(SCRIPT_EVENT_SIGNATURES[LIndex].ParamCount <= 3);
  end;
  Assert.AreEqual('ONTICK', string(SCRIPT_EVENT_SIGNATURES[6].Name));
  Assert.AreEqual(Integer(Ord(btS32)), Integer(SCRIPT_EVENT_SIGNATURES[6].Typ[1]));
end;

end.
