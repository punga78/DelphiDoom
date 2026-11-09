{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the registry of the host functions                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Registry;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.ScriptHost.Intf;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostRegistry = class(TObject)
  private
    FRegistry: IScriptFunctionRegistry;
    function Joined(const ANames: TArray<string>): string;
    /// <summary>Compiles and runs a script with the real compiler of Pascal Script, with the registry as its OnUses</summary>
    function RunScript(const ASource: string; out AMessage: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeTenereLeUnitInOrdineAlfabeticoQualunqueSiaLOrdineDiRegistrazione;
    [Test]
    procedure DovrebbeDareLeUnitInMaiuscolo;
    [Test]
    procedure DovrebbeTrovareUnaUnitSenzaDistinguereMaiuscole;
    [Test]
    procedure DovrebbeDareErroreSeUnaUnitEGiaRegistrata;
    [Test]
    procedure DovrebbeDareErroreSeLaUnitSiRipeteConAltreMaiuscole;
    [Test]
    procedure DovrebbeDareErroreSeIlGruppoEnil;
    [Test]
    procedure DovrebbeDareErroreSeIlGruppoNonHaUnNome;
    [Test]
    procedure DovrebbeChiedereLeFunzioniAlGruppoUnaVoltaSola;
    [Test]
    procedure DovrebbeDareLeDichiarazioniUnaPerRigaConIlPuntoEVirgola;
    [Test]
    procedure DovrebbeDareStringaVuotaPerUnaUnitSconosciuta;
    [Test]
    procedure DovrebbeTogliereUnaUnit;
    [Test]
    procedure DovrebbeIgnorareIlTogliereUnaUnitSconosciuta;
    [Test]
    procedure DovrebbeLasciareSystemFuoriDallElencoDiAll;
    [Test]
    procedure DovrebbeDareLElencoDiAllInOrdineAlfabetico;
    [Test]
    procedure DovrebbeDareFalsoSeLaUnitNonEnelRegistroPerIlCompilatore;
    [Test]
    procedure DovrebbeDareFalsoSeLaUnitNonEnelRegistroPerLInterprete;
    [Test]
    procedure DovrebbeCompilareEdEseguireUnoScriptCheUsaUnaUnit;
    [Test]
    procedure DovrebbeCompilareEdEseguireUnoScriptCheUsaAll;
    [Test]
    procedure DovrebbeDareErroreDiCompilazioneSeLoScriptUsaUnaUnitSconosciuta;
    [Test]
    procedure DovrebbeDareErroreSeLoScriptChiamaUnaFunzioneDiUnaUnitNonCaricata;
    [Test]
    procedure DovrebbeNonDareAllInterpreteLeFunzioniDopoReset;
    [Test]
    procedure DovrebbeRiregistrareDopoResetEUnaNuovaCompilazione;
  end;

implementation

uses
  ps_defs,
  ps_keywords,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.Fakes;

var
  // the OnUses of the compiler is a plain function: it reaches the registry of the running test
  GRegistry: IScriptFunctionRegistry = nil;

function TestOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
var
  LName: string;
begin
  if string(Name) = 'SYSTEM' then
  begin
    // the compiler always asks for SYSTEM first: its functions are the ones of the registry, if any
    GRegistry.RegisterCompiler('SYSTEM', Sender);
    Exit(True);
  end;
  if string(Name) = 'ALL' then
  begin
    for LName in GRegistry.CompilerUnitNames do
      GRegistry.RegisterCompiler(LName, Sender);
    Exit(True);
  end;
  Result := GRegistry.RegisterCompiler(string(Name), Sender);
  if not Result then
    Sender.MakeError('', ecUnknownIdentifier, '');
end;

function TTestScriptHostRegistry.Joined(const ANames: TArray<string>): string;
var
  LName: string;
begin
  Result := '';
  for LName in ANames do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LName;
  end;
end;

function TTestScriptHostRegistry.RunScript(const ASource: string; out AMessage: string): Boolean;
var
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytes: TbtString;
  LName: string;
begin
  Result := False;
  AMessage := '';
  GRegistry := FRegistry;
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  try
    LCompiler.OnUses := TestOnUses;
    FRegistry.Reset;
    if not LCompiler.Compile(TbtString(ASource)) then
    begin
      if LCompiler.MsgCount > 0 then
        AMessage := 'compile: ' + string(LCompiler.Msg[0].MessageToString);
      Exit;
    end;
    LCompiler.GetOutput(LBytes);
    LExec := TPSExec.Create;
    try
      for LName in FRegistry.UnitNames do
        FRegistry.RegisterExecutor(LName, LExec);
      if not LExec.LoadData(LBytes) then
      begin
        AMessage := 'load';
        Exit;
      end;
      Result := LExec.RunScript and (LExec.ExceptionCode = erNoError);
      if not Result then
        AMessage := 'run';
    finally
      LExec.Free;
    end;
  finally
    LCompiler.Free;
    GRegistry := nil;
  end;
end;

procedure TTestScriptHostRegistry.Setup;
begin
  FRegistry := TScriptHostFactory.CreateRegistry;
  GRecordedValue := 0;
  GRecordedText := '';
end;

procedure TTestScriptHostRegistry.TearDown;
begin
  FRegistry := nil;
end;

procedure TTestScriptHostRegistry.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, Integer(Length(FRegistry.UnitNames)));
  Assert.AreEqual(0, Integer(Length(FRegistry.CompilerUnitNames)));
  Assert.IsFalse(FRegistry.Contains('SYSTEM'));
end;

procedure TTestScriptHostRegistry.DovrebbeTenereLeUnitInOrdineAlfabeticoQualunqueSiaLOrdineDiRegistrazione;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('SYSTEM', ['procedure A;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_OVERLAY', ['procedure B;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_FIXED', ['procedure C;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure D;'], [nil]));
  Assert.AreEqual('PS_FIXED,PS_GAME,PS_OVERLAY,SYSTEM', Joined(FRegistry.UnitNames));
end;

procedure TTestScriptHostRegistry.DovrebbeDareLeUnitInMaiuscolo;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('Mine', ['procedure A;'], [nil]));
  Assert.AreEqual('MINE', Joined(FRegistry.UnitNames));
end;

procedure TTestScriptHostRegistry.DovrebbeTrovareUnaUnitSenzaDistinguereMaiuscole;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure A;'], [nil]));
  Assert.IsTrue(FRegistry.Contains('ps_game'));
  Assert.IsTrue(FRegistry.Contains('PS_GAME'));
  Assert.IsFalse(FRegistry.Contains('PS_OTHER'));
end;

procedure TTestScriptHostRegistry.DovrebbeDareErroreSeUnaUnitEGiaRegistrata;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure A;'], [nil]));
  Assert.WillRaise(
    procedure
    begin
      FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure B;'], [nil]));
    end, EScriptHostException);
  Assert.AreEqual(1, Integer(Length(FRegistry.UnitNames)));
end;

procedure TTestScriptHostRegistry.DovrebbeDareErroreSeLaUnitSiRipeteConAltreMaiuscole;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure A;'], [nil]));
  Assert.WillRaise(
    procedure
    begin
      FRegistry.AddGroup(TFakeScriptGroup.Create('ps_game', ['procedure B;'], [nil]));
    end, EScriptHostException);
end;

procedure TTestScriptHostRegistry.DovrebbeDareErroreSeIlGruppoEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      FRegistry.AddGroup(nil);
    end, EScriptHostException);
end;

procedure TTestScriptHostRegistry.DovrebbeDareErroreSeIlGruppoNonHaUnNome;
begin
  Assert.WillRaise(
    procedure
    begin
      FRegistry.AddGroup(TFakeScriptGroup.Create('', ['procedure A;'], [nil]));
    end, EScriptHostException);
end;

procedure TTestScriptHostRegistry.DovrebbeChiedereLeFunzioniAlGruppoUnaVoltaSola;
var
  LGroup: TFakeScriptGroup;
  LInterface: IScriptFunctionGroup;
begin
  LGroup := TFakeScriptGroup.Create('PS_GAME', ['procedure A;'], [nil]);
  LInterface := LGroup;
  FRegistry.AddGroup(LInterface);
  FRegistry.Declarations('PS_GAME');
  FRegistry.Reset;
  Assert.AreEqual(1, LGroup.Described);
end;

procedure TTestScriptHostRegistry.DovrebbeDareLeDichiarazioniUnaPerRigaConIlPuntoEVirgola;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('MINE',
    ['procedure One', '  function Two: integer;  ', 'procedure Three(const x: integer);'], [nil, nil, nil]));
  Assert.AreEqual('procedure One;'#13#10'function Two: integer;'#13#10'procedure Three(const x: integer);'#13#10,
    FRegistry.Declarations('MINE'));
end;

procedure TTestScriptHostRegistry.DovrebbeDareStringaVuotaPerUnaUnitSconosciuta;
begin
  Assert.AreEqual('', FRegistry.Declarations('NOTHING'));
end;

procedure TTestScriptHostRegistry.DovrebbeTogliereUnaUnit;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure A;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('SYSTEM', ['procedure B;'], [nil]));
  FRegistry.RemoveGroup('ps_game');
  Assert.AreEqual('SYSTEM', Joined(FRegistry.UnitNames));
  // and it can be registered again
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure A;'], [nil]));
  Assert.AreEqual('PS_GAME,SYSTEM', Joined(FRegistry.UnitNames));
end;

procedure TTestScriptHostRegistry.DovrebbeIgnorareIlTogliereUnaUnitSconosciuta;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('SYSTEM', ['procedure B;'], [nil]));
  FRegistry.RemoveGroup('NOTHING');
  Assert.AreEqual('SYSTEM', Joined(FRegistry.UnitNames));
end;

procedure TTestScriptHostRegistry.DovrebbeLasciareSystemFuoriDallElencoDiAll;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('SYSTEM', ['procedure A;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('PS_GAME', ['procedure B;'], [nil]));
  Assert.AreEqual('PS_GAME', Joined(FRegistry.CompilerUnitNames));
end;

procedure TTestScriptHostRegistry.DovrebbeDareLElencoDiAllInOrdineAlfabetico;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('ZZZ', ['procedure A;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('SYSTEM', ['procedure B;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('AAA', ['procedure C;'], [nil]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('MMM', ['procedure D;'], [nil]));
  Assert.AreEqual('AAA,MMM,ZZZ', Joined(FRegistry.CompilerUnitNames));
end;

procedure TTestScriptHostRegistry.DovrebbeDareFalsoSeLaUnitNonEnelRegistroPerIlCompilatore;
var
  LCompiler: TPSPascalCompiler;
begin
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  try
    Assert.IsFalse(FRegistry.RegisterCompiler('NOTHING', LCompiler));
  finally
    LCompiler.Free;
  end;
end;

procedure TTestScriptHostRegistry.DovrebbeDareFalsoSeLaUnitNonEnelRegistroPerLInterprete;
var
  LExec: TPSExec;
begin
  LExec := TPSExec.Create;
  try
    Assert.IsFalse(FRegistry.RegisterExecutor('NOTHING', LExec));
  finally
    LExec.Free;
  end;
end;

procedure TTestScriptHostRegistry.DovrebbeCompilareEdEseguireUnoScriptCheUsaUnaUnit;
var
  LMessage: string;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('MINE', ['procedure RecordValue(const AValue: Integer);'],
    [@RecordValue]));
  Assert.IsTrue(RunScript('uses MINE;'#13#10'begin'#13#10'  RecordValue(42);'#13#10'end.', LMessage), LMessage);
  Assert.AreEqual(42, GRecordedValue);
end;

procedure TTestScriptHostRegistry.DovrebbeCompilareEdEseguireUnoScriptCheUsaAll;
var
  LMessage: string;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('SYSTEM', ['procedure RecordText(const AText: string);'],
    [@RecordText]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('MINE', ['function AddNumbers(const A, B: Integer): Integer;'],
    [@AddNumbers]));
  FRegistry.AddGroup(TFakeScriptGroup.Create('OTHER', ['procedure RecordValue(const AValue: Integer);'],
    [@RecordValue]));
  // SYSTEM is always loaded, "all" brings the others
  Assert.IsTrue(RunScript('uses all;'#13#10'begin'#13#10'  RecordValue(AddNumbers(20, 22));'#13#10 +
    '  RecordText(''abc'');'#13#10'end.', LMessage), LMessage);
  Assert.AreEqual(42, GRecordedValue);
  Assert.AreEqual('abc', GRecordedText);
end;

procedure TTestScriptHostRegistry.DovrebbeDareErroreDiCompilazioneSeLoScriptUsaUnaUnitSconosciuta;
var
  LMessage: string;
begin
  Assert.IsFalse(RunScript('uses NOTHING;'#13#10'begin'#13#10'end.', LMessage));
  Assert.IsTrue(Pos('compile', LMessage) = 1, LMessage);
end;

procedure TTestScriptHostRegistry.DovrebbeDareErroreSeLoScriptChiamaUnaFunzioneDiUnaUnitNonCaricata;
var
  LMessage: string;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('MINE', ['procedure RecordValue(const AValue: Integer);'],
    [@RecordValue]));
  // the script does not say "uses MINE": the function is unknown to the compiler
  Assert.IsFalse(RunScript('begin'#13#10'  RecordValue(1);'#13#10'end.', LMessage));
  Assert.IsTrue(Pos('compile', LMessage) = 1, LMessage);
end;

procedure TTestScriptHostRegistry.DovrebbeNonDareAllInterpreteLeFunzioniDopoReset;
var
  LExec: TPSExec;
  LCompiler: TPSPascalCompiler;
  LBytes: TbtString;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('MINE', ['procedure RecordValue(const AValue: Integer);'],
    [@RecordValue]));
  GRegistry := FRegistry;
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  try
    LCompiler.OnUses := TestOnUses;
    Assert.IsTrue(LCompiler.Compile('uses MINE;'#13#10'begin'#13#10'  RecordValue(7);'#13#10'end.'));
    LCompiler.GetOutput(LBytes);
  finally
    LCompiler.Free;
    GRegistry := nil;
  end;
  // the compilation marked the functions of the unit; the reset takes the marks away and the
  // interpreter gets nothing: the script cannot find its function
  FRegistry.Reset;
  LExec := TPSExec.Create;
  try
    FRegistry.RegisterExecutor('MINE', LExec);
    Assert.IsFalse(LExec.LoadData(LBytes));
  finally
    LExec.Free;
  end;
end;

procedure TTestScriptHostRegistry.DovrebbeRiregistrareDopoResetEUnaNuovaCompilazione;
var
  LMessage: string;
begin
  FRegistry.AddGroup(TFakeScriptGroup.Create('MINE', ['procedure RecordValue(const AValue: Integer);'],
    [@RecordValue]));
  Assert.IsTrue(RunScript('uses MINE;'#13#10'begin'#13#10'  RecordValue(1);'#13#10'end.', LMessage), LMessage);
  Assert.IsTrue(RunScript('uses MINE;'#13#10'begin'#13#10'  RecordValue(2);'#13#10'end.', LMessage), LMessage);
  Assert.AreEqual(2, GRecordedValue);
end;

end.
