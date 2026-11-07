{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the machine and its interpreter      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.Machine;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Acs.Machine.Types, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Types,
  DelphiDoom.Logging.Recorder, DelphiDoom.Tests.Acs.FakeWorld,
  DelphiDoom.Tests.Acs.Scenario, DelphiDoom.Tests.Acs.MachineTarget;

type
  /// <summary>
  ///   The scenarios in Tests\Data\Acs\Runtime were run on the interpreter of the engine before it
  ///   was replaced (a copy of p_acs.pas, with the host replaced by a fake world) and the
  ///   golden files are what it did. The machine has to do the same: the same calls to the game,
  ///   the same stacks and variables. The exceptions are the scenarios divzero, logic, print, scripts
  ///   and waits: they show the defects of the old interpreter, and their golden files hold the
  ///   corrected result (the tests below check each correction on its own too)
  /// </summary>
  [TestFixture]
  [Category('acs')]
  TTestAcsMachine = class(TObject)
  private
    FWorld: TFakeWorld;
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FTarget: TAcsMachineTarget;
    FInterface: IAcsScenarioTarget;
    function DataPath(const AFileName: string): string;
    function Compile(const AText: string): TBytes;
    function CompileFile(const AName: string): TBytes;
    procedure Run(const ACode: TBytes; const ACommands: array of string);
    function Warnings: string;
    function TraceText: string;
    procedure NewTarget;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('arith', 'arith')]
    [TestCase('control', 'control')]
    [TestCase('divzero', 'divzero')]
    [TestCase('expressions', 'expressions')]
    [TestCase('logic', 'logic')]
    [TestCase('print', 'print')]
    [TestCase('scripts', 'scripts')]
    [TestCase('specials', 'specials')]
    [TestCase('store', 'store')]
    [TestCase('strings', 'strings')]
    [TestCase('variables', 'variables')]
    [TestCase('waits', 'waits')]
    [TestCase('world', 'world')]
    procedure DovrebbeFareLeStesseCoseDelVecchioInterprete(const AName: string);

    [Test]
    procedure DovrebbeEseguireUnaSommaEFinire;
    [Test]
    procedure DovrebbeRimuovereLoScriptCheTermina;
    [Test]
    procedure DovrebbeTerminareLoScriptGiustoQuandoUnoScriptVieneTerminatoDallEsterno;
    [Test]
    procedure DovrebbeConsumareEntrambiGliOperandiDelleOperazioniLogiche;
    [Test]
    procedure DovrebbeAccodareIlTestoDiUnaStampa;
    [Test]
    procedure DovrebbeDareZeroPerUnaDivisionePerZeroSenzaFermarsi;
    [Test]
    procedure DovrebbeFermareLoScriptSeLoStackStraripa;
    [Test]
    procedure DovrebbeFermareLoScriptSeLoStackSiSvuota;
    [Test]
    procedure DovrebbeFermareLoScriptSeUnSaltoEsceDalCodice;
    [Test]
    procedure DovrebbeFermareLoScriptSeIlComandoNonEsiste;
    [Test]
    procedure DovrebbeFermareLoScriptSeLaVariabileNonEsiste;
    [Test]
    procedure DovrebbeFermareLoScriptSeLaStringaNonEsiste;
    [Test]
    procedure DovrebbeFermareLoScriptSeIlCodiceFinisce;
    [Test]
    procedure DovrebbeEseguireUnComandoNop;
    [Test]
    procedure DovrebbeSegnalareUnoScriptSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnOggettoSbagliatoSenzaFermarsi;
    [Test]
    procedure DovrebbeIgnorareUnoScriptDiUnAltroOggetto;
    [Test]
    procedure DovrebbeFallireQuandoLArchivioDegliScriptEPieno;
    [Test]
    procedure DovrebbeAvviareGliScriptApertiDopoUnSecondo;
    [Test]
    procedure DovrebbeLanciareSeNonHaUnHost;
  end;

implementation

uses
  DelphiDoom.Acs.Factory, DelphiDoom.Acs.Intf, DelphiDoom.Acs.Machine.Intf,
  DelphiDoom.Acs.PCodes, DelphiDoom.Logging.Factory, DelphiDoom.Tests.Acs.ObjectBuilder;

{ TTestAcsMachine }

procedure TTestAcsMachine.Setup;
begin
  FWorld := TFakeWorld.Create;
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  NewTarget;
end;

procedure TTestAcsMachine.NewTarget;
begin
  FInterface := nil;
  FTarget := TAcsMachineTarget.Create(FWorld, TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
  FInterface := FTarget;
end;

procedure TTestAcsMachine.TearDown;
begin
  FInterface := nil;
  FTarget := nil;
  FSink := nil;
  FRecorder := nil;
  FWorld.Free;
end;

function TTestAcsMachine.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Acs\' + AFileName));
end;

function TTestAcsMachine.Compile(const AText: string): TBytes;
var
  LSource: TBytes;
  LIndex: Integer;
begin
  SetLength(LSource, Length(AText));
  for LIndex := 1 to Length(AText) do
    LSource[LIndex - 1] := Byte(Ord(AText[LIndex]));
  Result := TAcsFactory.CreateCompiler(TAcsFactory.CreateEmptyProvider, nil).Compile('0', LSource);
end;

function TTestAcsMachine.CompileFile(const AName: string): TBytes;
begin
  Result := TAcsFactory.CreateCompiler(TAcsFactory.CreateMemoryProvider(['include_defs.acs'],
    [TFile.ReadAllBytes(DataPath('include_defs.acs'))]), nil).Compile('0',
    TFile.ReadAllBytes(DataPath(AName)));
end;

function TTestAcsMachine.Warnings: string;
begin
  Result := FRecorder.TextOf(TLogChannel.ErrorFile);
end;

function TTestAcsMachine.TraceText: string;
begin
  Result := FWorld.Trace.Text;
end;

procedure TTestAcsMachine.Run(const ACode: TBytes; const ACommands: array of string);
var
  LCommand: string;
  LWords: TArray<string>;
  LArguments: TAcsArguments;
begin
  FInterface.Load(ACode);
  FillChar(LArguments, SizeOf(LArguments), 0);
  for LCommand in ACommands do
  begin
    LWords := LCommand.Split([' ']);
    if LWords[0] = 'start' then
      FInterface.Start(StrToInt(LWords[1]), 0, LArguments, nil, nil, 0)
    else if LWords[0] = 'terminate' then
      FInterface.Terminate(StrToInt(LWords[1]))
    else if LWords[0] = 'tick' then
      FInterface.Tick;
  end;
end;

procedure TTestAcsMachine.DovrebbeFareLeStesseCoseDelVecchioInterprete(const AName: string);
var
  LLines: TStringList;
  LGolden: TStringList;
  LRunner: TAcsScenarioRunner;
  LActual: string;
begin
  LLines := TStringList.Create;
  LGolden := TStringList.Create;
  try
    LLines.LoadFromFile(DataPath('Runtime\' + AName + '.scenario.txt'));
    LGolden.LoadFromFile(DataPath('Runtime\' + AName + '.golden.txt'));
    LRunner := TAcsScenarioRunner.Create(FWorld, FInterface,
      function(AFile: string): TBytes
      begin
        Result := CompileFile(AFile);
      end);
    try
      LActual := LRunner.Run(LLines);
    finally
      LRunner.Free;
    end;
    Assert.AreEqual(LGolden.Text.Replace(#13#10, #10), LActual.Replace(#13#10, #10));
  finally
    LGolden.Free;
    LLines.Free;
  end;
end;

procedure TTestAcsMachine.DovrebbeEseguireUnaSommaEFinire;
begin
  Run(TAcsObjectBuilder.Build([PCD_PUSHNUMBER, 7, PCD_PUSHNUMBER, 5, PCD_ADD, PCD_ASSIGNMAPVAR, 0,
    PCD_TERMINATE], []), ['start 1', 'tick']);
  Assert.AreEqual(12, FTarget.Machine.MapVariables[0]);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.AreEqual('', Warnings);
end;

procedure TTestAcsMachine.DovrebbeRimuovereLoScriptCheTermina;
begin
  Run(TAcsObjectBuilder.Build([PCD_TERMINATE], []), ['start 1', 'tick', 'tick']);
  Assert.AreEqual('remove script 1'#13#10, TraceText);
end;

procedure TTestAcsMachine.DovrebbeTerminareLoScriptGiustoQuandoUnoScriptVieneTerminatoDallEsterno;
var
  LCode: TBytes;
begin
  LCode := Compile('script 1 (void) { delay(1000); }' + #10 + 'script 2 (void) { delay(1000); }');
  Run(LCode, ['start 1', 'start 2', 'tick', 'terminate 1', 'tick']);
  Assert.AreEqual('remove script 1'#13#10, TraceText);
  Assert.IsFalse(FTarget.Thinkers.IsRemoved(FTarget.Thinkers.Item(1)));
end;

procedure TTestAcsMachine.DovrebbeConsumareEntrambiGliOperandiDelleOperazioniLogiche;
begin
  Run(TAcsObjectBuilder.Build([PCD_PUSHNUMBER, 1, PCD_PUSHNUMBER, 5, PCD_ORLOGICAL,
    PCD_PUSHNUMBER, 0, PCD_PUSHNUMBER, 9, PCD_ANDLOGICAL, PCD_ADD, PCD_ASSIGNMAPVAR, 0,
    PCD_TERMINATE], []), ['start 1', 'tick']);
  Assert.AreEqual(1, FTarget.Machine.MapVariables[0]);
  Assert.AreEqual(0, FTarget.Snapshot.Scripts[0].StackPtr);
end;

procedure TTestAcsMachine.DovrebbeAccodareIlTestoDiUnaStampa;
begin
  Run(Compile('script 1 (void) { print(s:"ab", i:12, c:67); }'), ['start 1', 'tick']);
  Assert.AreEqual('message activator=nil text=ab12C'#13#10'remove script 1'#13#10, TraceText);
end;

procedure TTestAcsMachine.DovrebbeDareZeroPerUnaDivisionePerZeroSenzaFermarsi;
begin
  Run(TAcsObjectBuilder.Build([PCD_PUSHNUMBER, 5, PCD_PUSHNUMBER, 0, PCD_DIVIDE, PCD_ASSIGNMAPVAR, 1,
    PCD_PUSHNUMBER, 8, PCD_ASSIGNMAPVAR, 2, PCD_TERMINATE], []), ['start 1', 'tick']);
  Assert.AreEqual(0, FTarget.Machine.MapVariables[1]);
  Assert.AreEqual(8, FTarget.Machine.MapVariables[2]);
  Assert.IsTrue(Warnings.Contains('division by zero'));
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeLoStackStraripa;
var
  LCommands: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(LCommands, 100);
  for LIndex := 0 to 49 do
  begin
    LCommands[LIndex * 2] := PCD_PUSHNUMBER;
    LCommands[LIndex * 2 + 1] := LIndex;
  end;
  Run(TAcsObjectBuilder.Build(LCommands, []), ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('stack'));
  Assert.AreEqual(ACS_STACK_DEPTH, FTarget.Snapshot.Scripts[0].StackPtr);
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeLoStackSiSvuota;
begin
  Run(TAcsObjectBuilder.Build([PCD_ADD, PCD_TERMINATE], []), ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('stack'));
  Assert.AreEqual(0, FTarget.Snapshot.Scripts[0].StackPtr);
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeUnSaltoEsceDalCodice;
begin
  Run(TAcsObjectBuilder.Build([PCD_GOTO, 99999], []), ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('jump'));
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeIlComandoNonEsiste;
begin
  Run(TAcsObjectBuilder.Build([500], []), ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('command 500'));
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeLaVariabileNonEsiste;
begin
  Run(TAcsObjectBuilder.Build([PCD_PUSHNUMBER, 1, PCD_ASSIGNSCRIPTVAR, 50, PCD_ASSIGNMAPVAR, 40,
    PCD_TERMINATE], []), ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('variable 50'));
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeLaStringaNonEsiste;
begin
  Run(TAcsObjectBuilder.Build([PCD_PUSHNUMBER, 3, PCD_PRINTSTRING, PCD_TERMINATE], ['only']),
    ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('string 3'));
end;

procedure TTestAcsMachine.DovrebbeFermareLoScriptSeIlCodiceFinisce;
var
  LCode: TBytes;
begin
  // the script starts at the last long of the object: a command, and then nothing
  LCode := TAcsObjectBuilder.Build([PCD_NOP], []);
  TAcsObjectBuilder.PutLong(LCode, TAcsObjectBuilder.LongAt(LCode, 4) + 8, Length(LCode) - 4);
  Run(LCode, ['start 1', 'tick']);
  Assert.IsTrue(FTarget.Machine.ScriptState[0] = assInactive);
  Assert.IsTrue(Warnings.Contains('runs out'));
end;

procedure TTestAcsMachine.DovrebbeEseguireUnComandoNop;
begin
  Run(TAcsObjectBuilder.Build([PCD_NOP, PCD_NOP, PCD_PUSHNUMBER, 3, PCD_ASSIGNMAPVAR, 0,
    PCD_TERMINATE], []), ['start 1', 'tick']);
  Assert.AreEqual(3, FTarget.Machine.MapVariables[0]);
  Assert.AreEqual('', Warnings);
end;

procedure TTestAcsMachine.DovrebbeSegnalareUnoScriptSconosciuto;
begin
  Run(TAcsObjectBuilder.Build([PCD_TERMINATE], []), ['start 99']);
  Assert.AreEqual('message console text=P_STARTACS ERROR: UNKNOWN SCRIPT 99'#13#10, TraceText);
end;

procedure TTestAcsMachine.DovrebbeRifiutareUnOggettoSbagliatoSenzaFermarsi;
var
  LCode: TBytes;
begin
  LCode := TAcsObjectBuilder.Build([PCD_TERMINATE], []);
  TAcsObjectBuilder.PutLong(LCode, 0, 0);
  FInterface.Load(LCode);
  Assert.AreEqual(0, FTarget.Machine.ScriptCount);
  Assert.IsFalse(FTarget.Machine.StartScript(1, 0, Default(TAcsArguments), nil, nil, 0));
end;

procedure TTestAcsMachine.DovrebbeIgnorareUnoScriptDiUnAltroOggetto;
var
  LScript: PAcsScript;
begin
  Run(TAcsObjectBuilder.Build([PCD_TERMINATE], []), []);
  LScript := PAcsScript(FTarget.Thinkers.Allocate(SizeOf(TAcsScript)));
  LScript.InfoIndex := 5;
  LScript.Number := 77;
  FTarget.Machine.Execute(LScript);
  Assert.IsTrue(FTarget.Thinkers.IsRemoved(LScript));
  Assert.IsTrue(Warnings.Contains('script 77'));
end;

procedure TTestAcsMachine.DovrebbeFallireQuandoLArchivioDegliScriptEPieno;
var
  LIndex: Integer;
  LArguments: TAcsArguments;
begin
  Run(TAcsObjectBuilder.Build([PCD_TERMINATE], []), []);
  FillChar(LArguments, SizeOf(LArguments), 0);
  for LIndex := 1 to ACS_STORE_SIZE do
    Assert.IsTrue(FTarget.Machine.StartScript(LIndex, 2, LArguments, nil, nil, 0));
  Assert.WillRaise(
    procedure
    begin
      FTarget.Machine.StartScript(500, 2, LArguments, nil, nil, 0);
    end,
    EAcsMachineException);
end;

procedure TTestAcsMachine.DovrebbeAvviareGliScriptApertiDopoUnSecondo;
var
  LTick: Integer;
begin
  Run(TAcsObjectBuilder.Build([PCD_PUSHNUMBER, 4, PCD_ASSIGNMAPVAR, 0, PCD_TERMINATE], [], 1001), []);
  Assert.AreEqual(1, FTarget.Thinkers.Count);
  for LTick := 1 to 35 do
    FTarget.Tick;
  Assert.AreEqual(0, FTarget.Machine.MapVariables[0]);
  FTarget.Tick;
  Assert.AreEqual(4, FTarget.Machine.MapVariables[0]);
end;

procedure TTestAcsMachine.DovrebbeLanciareSeNonHaUnHost;
begin
  Assert.WillRaise(
    procedure
    begin
      TAcsFactory.CreateMachine(nil, nil);
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAcsMachine);

end.
