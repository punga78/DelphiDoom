{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the error codes and of the less common paths of the    }
{  Script engine, through its raw interfaces                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.ErrorCodes;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf;

type
  /// <summary>
  ///   The answers of TScriptCompilerEngine and TScriptExecutorEngine to the arguments they refuse,
  ///   to the values of the wrong type and to what PascalScript reports (hints, warnings, typed
  ///   constants, calling conventions): the expected behaviour is that of PascalScript
  ///   (Libs\PascalScript\ps_compiler.pas, ps_runtime.pas) and of the contract in DelphiDoom.Script.Intf
  /// </summary>
  [TestFixture]
  [Category('script')]
  TTestScriptErrorCodes = class(TObject)
  private
    FLibrary: IScriptLibrary;
    FCompiler: IScriptCompiler;
    FExecutor: IScriptExecutor;
    function Compile(const ASource: AnsiString): TBytes;
    procedure LoadSource(const ASource: AnsiString);
    function CallInteger(const AName: AnsiString; const AValues: array of Int64;
      out AResult: TScriptValue): Integer;
    function CallWithoutArguments(const AName: AnsiString): Int64;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure IlCompilatoreDovrebbeRifiutareGliArgomentiNilONonValidi;
    [Test]
    procedure LeCostantiInteroDovrebberoPrendereIlTipoDichiarato;
    [Test]
    procedure UnaCostanteInteraDiUnTipoRealeDovrebbeFarFallireLaCompilazione;
    [Test]
    procedure LaDichiarazioneDiUnaFunzioneOspiteDovrebbeRiceverneIlPuntoEVirgola;
    [Test]
    procedure IlCompilatoreDovrebbeDareAvvisiESuggerimenti;
    [Test]
    procedure LeConvenzioniPascalCdeclESafecallDovrebberoEssereAccettate;
    [Test]
    procedure UnErroreNelBloccoPrincipaleDovrebbeEssereUnErroreDiEsecuzione;
    [Test]
    procedure LeVariabiliGlobaliDovrebberoRifiutareIlTipoSbagliato;
    [Test]
    procedure LeVariabiliGlobaliDovrebberoRifiutareNomiNilEUnoStatoSenzaCodice;
    [Test]
    procedure LaChiamataDovrebbeRifiutareTipiNonSupportatiEFunzioniOspiti;
    [Test]
    procedure IlTestoDelCodiceDovrebbeDescrivereOgniErrore;
  end;

implementation

uses
  DelphiDoom.Script.Engine, DelphiDoom.Tests.Script.Samples;

const
  CRLF = #13#10;

  SOURCE_CONSTANTS: AnsiString =
    'program C;' + CRLF +
    'function LeggiB: Integer; begin Result := CB; end;' + CRLF +
    'function LeggiS: Integer; begin Result := CS; end;' + CRLF +
    'function LeggiW: Integer; begin Result := CW; end;' + CRLF +
    'function LeggiSS: Integer; begin Result := CSS; end;' + CRLF +
    'function LeggiI: Integer; begin Result := CI; end;' + CRLF +
    'begin end.';

  SOURCE_USES_CD: AnsiString =
    'program D;' + CRLF +
    'function F: Integer; begin Result := CD; end;' + CRLF +
    'begin end.';

  SOURCE_ONE_HOST: AnsiString =
    'program H;' + CRLF +
    'function Raddoppia(x: Integer): Integer; begin Result := HostDouble(x); end;' + CRLF +
    'begin end.';

  // a variable never used gives a hint, "True and X" a warning (the "True and" is not needed)
  SOURCE_HINTS: AnsiString =
    'program W;' + CRLF +
    'function F(X: Boolean): Boolean;' + CRLF +
    'var Unused: Integer;' + CRLF +
    'begin' + CRLF +
    '  Result := True and X;' + CRLF +
    'end;' + CRLF +
    'begin end.';

  SOURCE_CONVENTIONS: AnsiString =
    'program K;' + CRLF +
    'function SottraiC(a, b: Integer): Integer; begin Result := HostSubCdecl(a, b); end;' + CRLF +
    'function SottraiP(a, b: Integer): Integer; begin Result := HostSubPascal(a, b); end;' + CRLF +
    'begin end.';

  SOURCE_MAIN_ERROR: AnsiString =
    'program M;' + CRLF +
    'var a, b: Integer;' + CRLF +
    'begin' + CRLF +
    '  b := 0;' + CRLF +
    '  a := 1 div b;' + CRLF +
    'end.';

  SOURCE_TYPED_GLOBALS: AnsiString =
    'program G;' + CRLF +
    'type TPair = record A, B: Integer; end;' + CRLF +
    'var' + CRLF +
    '  Count: Integer;' + CRLF +
    '  Ratio: Double;' + CRLF +
    '  Name: string;' + CRLF +
    '  Pair: TPair;' + CRLF +
    'function DaiCoppia: TPair; begin Result.A := 1; Result.B := 2; end;' + CRLF +
    'function Somma(P: TPair): Integer; begin Result := P.A + P.B; end;' + CRLF +
    'begin' + CRLF +
    '  Count := 3;' + CRLF +
    '  Ratio := 1.5;' + CRLF +
    '  Name := ''abc'';' + CRLF +
    'end.';

function HostSubCdecl(AFirst, ASecond: Integer): Integer; cdecl;
begin
  Result := AFirst - ASecond;
end;

function HostSubPascal(AFirst, ASecond: Integer): Integer; pascal;
begin
  Result := AFirst - ASecond;
end;

function HostSafe(AValue: Integer): Integer; safecall;
begin
  Result := AValue;
end;

{ TTestScriptErrorCodes }

procedure TTestScriptErrorCodes.Setup;
begin
  FLibrary := TScriptEngine.Create;
  Assert.AreEqual(SCRIPT_OK, FLibrary.CreateCompiler(FCompiler));
  Assert.AreEqual(SCRIPT_OK, FLibrary.CreateExecutor(FExecutor));
end;

procedure TTestScriptErrorCodes.TearDown;
begin
  FExecutor := nil;
  FCompiler := nil;
  FLibrary := nil;
end;

function TTestScriptErrorCodes.Compile(const ASource: AnsiString): TBytes;
var
  LSize: Cardinal;
begin
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER,
    FCompiler.Compile(Pointer(ASource), Length(ASource), nil, LSize));
  SetLength(Result, LSize);
  Assert.AreEqual(SCRIPT_OK,
    FCompiler.Compile(Pointer(ASource), Length(ASource), Pointer(Result), LSize));
  SetLength(Result, LSize);
end;

procedure TTestScriptErrorCodes.LoadSource(const ASource: AnsiString);
var
  LBytecode: TBytes;
begin
  LBytecode := Compile(ASource);
  Assert.AreEqual(SCRIPT_OK,
    FExecutor.LoadBytecode(Pointer(LBytecode), Length(LBytecode)));
end;

function TTestScriptErrorCodes.CallInteger(const AName: AnsiString;
  const AValues: array of Int64; out AResult: TScriptValue): Integer;
var
  LArguments: TArray<TScriptValue>;
  LIndex: Integer;
begin
  SetLength(LArguments, Length(AValues));
  FillChar(Pointer(LArguments)^, Length(LArguments) * SizeOf(TScriptValue), 0);
  for LIndex := 0 to High(AValues) do
  begin
    LArguments[LIndex].Kind := SCRIPT_VALUE_INTEGER;
    LArguments[LIndex].IntegerValue := AValues[LIndex];
  end;
  FillChar(AResult, SizeOf(AResult), 0);
  Result := FExecutor.CallProcedure(PAnsiChar(AName), PScriptValue(LArguments),
    Length(LArguments), AResult);
end;

function TTestScriptErrorCodes.CallWithoutArguments(const AName: AnsiString): Int64;
var
  LResult: TScriptValue;
begin
  Assert.AreEqual(SCRIPT_OK, CallInteger(AName, [], LResult), string(AName));
  Assert.AreEqual(SCRIPT_VALUE_INTEGER, LResult.Kind);
  Result := LResult.IntegerValue;
end;

procedure TTestScriptErrorCodes.IlCompilatoreDovrebbeRifiutareGliArgomentiNilONonValidi;
begin
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.SelectUnit(nil));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddType(nil, 'Integer'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddType('TNumero', nil));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantInteger(nil, 1, nil));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantDouble(nil, 1.0));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantString(nil, 'a'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantString('Testo', nil));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddDefine(nil));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddInclude(nil, 'x'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddInclude('x.inc', nil));
  // a type name and a constant name must be identifiers, a name is reserved once
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantInteger('Uno', 1, '1Tipo'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantDouble('1Mezzo', 0.5));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantString('Saluto', 'ciao'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddConstantString('SALUTO', 'di nuovo'));
end;

procedure TTestScriptErrorCodes.LeCostantiInteroDovrebberoPrendereIlTipoDichiarato;
begin
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantInteger('CB', 200, 'Byte'));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantInteger('CS', -100, 'ShortInt'));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantInteger('CW', 60000, 'Word'));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantInteger('CSS', -30000, 'SmallInt'));
  // without a type the constant is an integer
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantInteger('CI', 7, nil));
  LoadSource(SOURCE_CONSTANTS);

  Assert.AreEqual(Int64(200), CallWithoutArguments('LeggiB'));
  Assert.AreEqual(Int64(-100), CallWithoutArguments('LeggiS'));
  Assert.AreEqual(Int64(60000), CallWithoutArguments('LeggiW'));
  Assert.AreEqual(Int64(-30000), CallWithoutArguments('LeggiSS'));
  Assert.AreEqual(Int64(7), CallWithoutArguments('LeggiI'));
end;

procedure TTestScriptErrorCodes.UnaCostanteInteraDiUnTipoRealeDovrebbeFarFallireLaCompilazione;
var
  LSize: Cardinal;
  LCount: Cardinal;
begin
  // the name of the type is valid, but a Double cannot hold the integer constant: the
  // registration of the declarations, during the compilation, fails
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddConstantInteger('CD', 1, 'Double'));
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_COMPILE,
    FCompiler.Compile(Pointer(SOURCE_USES_CD), Length(SOURCE_USES_CD), nil, LSize));
  Assert.AreEqual(SCRIPT_OK, FCompiler.GetMessageCount(LCount));
  Assert.IsTrue(LCount >= 1, 'the failure must be explained');
end;

procedure TTestScriptErrorCodes.LaDichiarazioneDiUnaFunzioneOspiteDovrebbeRiceverneIlPuntoEVirgola;
const
  // no final semicolon and white space after the declaration
  DECLARATION: AnsiString = 'function HostDouble(a: Integer): Integer'#9'  ';
var
  LResult: TScriptValue;
begin
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION)));
  Assert.AreEqual(SCRIPT_OK,
    FExecutor.AddHostFunction(PAnsiChar(DECLARATION), @HostDouble, SCRIPT_CALL_REGISTER));
  LoadSource(SOURCE_ONE_HOST);
  Assert.AreEqual(SCRIPT_OK, CallInteger('Raddoppia', [21], LResult));
  Assert.AreEqual(Int64(42), LResult.IntegerValue);
end;

procedure TTestScriptErrorCodes.IlCompilatoreDovrebbeDareAvvisiESuggerimenti;
var
  LCount: Cardinal;
  LIndex: Cardinal;
  LInfo: TScriptMessageInfo;
  LText: array[0..255] of AnsiChar;
  LTextSize: Cardinal;
  LWarnings, LHints, LErrors: Integer;
begin
  Compile(SOURCE_HINTS);
  Assert.AreEqual(SCRIPT_OK, FCompiler.GetMessageCount(LCount));
  LWarnings := 0;
  LHints := 0;
  LErrors := 0;
  for LIndex := 0 to LCount - 1 do
  begin
    LTextSize := SizeOf(LText);
    Assert.AreEqual(SCRIPT_OK, FCompiler.GetMessageInfo(LIndex, LInfo, @LText[0], LTextSize));
    case LInfo.Kind of
      SCRIPT_MESSAGE_ERROR: Inc(LErrors);
      SCRIPT_MESSAGE_WARNING: Inc(LWarnings);
      SCRIPT_MESSAGE_HINT: Inc(LHints);
    end;
  end;
  Assert.AreEqual(0, LErrors);
  Assert.IsTrue(LWarnings >= 1, '"True and" is not needed');
  Assert.IsTrue(LHints >= 1, 'the variable is never used');
end;

procedure TTestScriptErrorCodes.LeConvenzioniPascalCdeclESafecallDovrebberoEssereAccettate;
const
  DECLARATION_CDECL: AnsiString = 'function HostSubCdecl(a, b: Integer): Integer;';
  DECLARATION_PASCAL: AnsiString = 'function HostSubPascal(a, b: Integer): Integer;';
var
  LResult: TScriptValue;
begin
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_CDECL)));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_PASCAL)));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(PAnsiChar(DECLARATION_CDECL),
    @HostSubCdecl, SCRIPT_CALL_CDECL));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(PAnsiChar(DECLARATION_PASCAL),
    @HostSubPascal, SCRIPT_CALL_PASCAL));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction('function HostSafe(a: Integer): Integer;',
    @HostSafe, SCRIPT_CALL_SAFECALL));
  LoadSource(SOURCE_CONVENTIONS);

  // the order of the arguments shows that each convention is the right one
  Assert.AreEqual(SCRIPT_OK, CallInteger('SottraiC', [10, 3], LResult));
  Assert.AreEqual(Int64(7), LResult.IntegerValue, 'cdecl');
  Assert.AreEqual(SCRIPT_OK, CallInteger('SottraiP', [10, 3], LResult));
  Assert.AreEqual(Int64(7), LResult.IntegerValue, 'pascal');
end;

procedure TTestScriptErrorCodes.UnErroreNelBloccoPrincipaleDovrebbeEssereUnErroreDiEsecuzione;
var
  LSize: Cardinal;
begin
  LoadSource(SOURCE_MAIN_ERROR);
  Assert.AreEqual(SCRIPT_ERROR_RUNTIME, FExecutor.RunMain);
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER, FExecutor.GetLastErrorText(nil, LSize));
  Assert.IsTrue(LSize > 1, 'the error must have a text');
end;

procedure TTestScriptErrorCodes.LeVariabiliGlobaliDovrebberoRifiutareIlTipoSbagliato;
var
  LDouble: Double;
  LInteger: Int64;
  LText: array[0..15] of AnsiChar;
  LSize: Cardinal;
  LCount, LIndex: Cardinal;
  LKind: Integer;
  LName: array[0..31] of AnsiChar;
  LFoundPair: Boolean;
begin
  LoadSource(SOURCE_TYPED_GLOBALS);
  Assert.AreEqual(SCRIPT_OK, FExecutor.RunMain);

  Assert.AreEqual(SCRIPT_ERROR_TYPE, FExecutor.GetGlobalDouble('Count', LDouble));
  Assert.AreEqual(SCRIPT_ERROR_TYPE, FExecutor.SetGlobalDouble('Name', 1.0));
  LSize := SizeOf(LText);
  Assert.AreEqual(SCRIPT_ERROR_TYPE, FExecutor.GetGlobalText('Ratio', @LText[0], LSize));
  Assert.AreEqual(SCRIPT_ERROR_TYPE, FExecutor.SetGlobalText('Count', 'x'));
  Assert.AreEqual(SCRIPT_ERROR_TYPE, FExecutor.GetGlobalInteger('Name', LInteger));
  Assert.AreEqual(SCRIPT_ERROR_TYPE, FExecutor.SetGlobalInteger('Name', 1));

  // a record is neither a number nor a text
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalCount(LCount));
  LFoundPair := False;
  for LIndex := 0 to LCount - 1 do
  begin
    LSize := SizeOf(LName);
    Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInfo(LIndex, LKind, @LName[0], LSize));
    if SameText(string(AnsiString(PAnsiChar(@LName[0]))), 'Pair') then
    begin
      LFoundPair := True;
      Assert.AreEqual(SCRIPT_GLOBAL_OTHER, LKind);
    end;
  end;
  Assert.IsTrue(LFoundPair, 'the record is a global of the script');
end;

procedure TTestScriptErrorCodes.LeVariabiliGlobaliDovrebberoRifiutareNomiNilEUnoStatoSenzaCodice;
var
  LDouble: Double;
  LInteger: Int64;
  LCount: Cardinal;
  LKind: Integer;
  LSize: Cardinal;
begin
  // nothing loaded
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.GetGlobalDouble('Count', LDouble));
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.GetGlobalCount(LCount));
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.GetGlobalInfo(0, LKind, nil, LSize));
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.GetGlobalInteger('Count', LInteger));
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.SetGlobalInteger('Count', 1));

  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.SetGlobalInteger(nil, 1));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.GetGlobalDouble(nil, LDouble));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.SetGlobalDouble('', 1.0));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.GetGlobalText(nil, nil, LSize));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.SetGlobalText(nil, 'x'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.SetGlobalText('Name', nil));
end;

procedure TTestScriptErrorCodes.LaChiamataDovrebbeRifiutareTipiNonSupportatiEFunzioniOspiti;
var
  LResult: TScriptValue;
  LArgument: TScriptValue;
begin
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE)));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE),
    @HostDouble, SCRIPT_CALL_REGISTER));
  // a declaration without a name is refused by the executor too
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FExecutor.AddHostFunction('x := 1;', @HostDouble, SCRIPT_CALL_REGISTER));
  LoadSource(SOURCE_ONE_HOST);
  // a host function is not a procedure of the script
  Assert.AreEqual(SCRIPT_ERROR_NOTFOUND, CallInteger('HostDouble', [1], LResult));

  FExecutor := nil;
  Assert.AreEqual(SCRIPT_OK, FLibrary.CreateExecutor(FExecutor));
  LoadSource(SOURCE_TYPED_GLOBALS);
  // the result is a record
  Assert.AreEqual(SCRIPT_ERROR_TYPE, CallInteger('DaiCoppia', [], LResult));
  // an integer is not a record
  Assert.AreEqual(SCRIPT_ERROR_TYPE, CallInteger('Somma', [1], LResult));
  // a text argument needs its text
  FillChar(LArgument, SizeOf(LArgument), 0);
  LArgument.Kind := SCRIPT_VALUE_TEXT;
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FExecutor.CallProcedure('Somma', @LArgument, 1, LResult));
end;

procedure TTestScriptErrorCodes.IlTestoDelCodiceDovrebbeDescrivereOgniErrore;
begin
  Assert.AreEqual('OK', EScriptException.TextOf(SCRIPT_OK));
  Assert.AreEqual('Invalid argument', EScriptException.TextOf(SCRIPT_ERROR_ARGUMENT));
  Assert.AreEqual('Buffer too small', EScriptException.TextOf(SCRIPT_ERROR_BUFFER));
  Assert.AreEqual('Compilation failed', EScriptException.TextOf(SCRIPT_ERROR_COMPILE));
  Assert.AreEqual('Cannot load the bytecode', EScriptException.TextOf(SCRIPT_ERROR_LOAD));
  Assert.AreEqual('Invalid state', EScriptException.TextOf(SCRIPT_ERROR_STATE));
  Assert.AreEqual('Not found', EScriptException.TextOf(SCRIPT_ERROR_NOTFOUND));
  Assert.AreEqual('Script runtime error', EScriptException.TextOf(SCRIPT_ERROR_RUNTIME));
  Assert.AreEqual('Type or argument count mismatch', EScriptException.TextOf(SCRIPT_ERROR_TYPE));
  Assert.AreEqual('Insufficient memory', EScriptException.TextOf(SCRIPT_ERROR_MEMORY));
  Assert.AreEqual('Internal error', EScriptException.TextOf(SCRIPT_ERROR_INTERNAL));
  Assert.AreEqual('Unknown error', EScriptException.TextOf(-99));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptErrorCodes);

end.
