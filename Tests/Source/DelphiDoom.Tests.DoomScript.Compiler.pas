{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptCompiler     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Compiler;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.Tests.DoomScript.Rig;

type
  /// <summary>
  ///   What the parity scenarios do not reach in the compiler: folding of constants, the defects of the
  ///   original turned into errors, the messages of rare errors, the limits of a statement.
  /// </summary>
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptCompiler = class
  strict private
    FRig: TDoomScriptTestRig;
    function GlobalFloat(const AName: AnsiString): Single;
    function StatementsOf(const AFunction: AnsiString): Integer;
    procedure ExpectCompileError(const AText: AnsiString; const AMessage: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePiegareLeCostantiAritmetiche;
    [Test]
    procedure DovrebbePiegareConfrontiELogica;
    [Test]
    procedure DovrebbePiegareLeCostantiVettore;
    [Test]
    procedure DovrebbeRiusareLaStessaCostante;
    [Test]
    procedure DovrebbeDareErrorePerLaDivisioneCostantePerZero;
    [Test]
    procedure DovrebbeDareErrorePerIlModuloCostantePerZeroCheNellOriginaleEUnCrash;
    [Test]
    procedure DovrebbeDareErrorePerIlModuloCostanteConDivisoreFraMenoUnoEUno;
    [Test]
    procedure DovrebbeDareZeroPerIlModuloCostantePerMenoUno;
    [Test]
    procedure DovrebbeDareErrorePerUnaFunzioneGlobaleChiamataSuUnEntitaCheNellOriginaleEUnCrash;
    [Test]
    procedure DovrebbeDareErrorePerUnEventoChiamatoComeThread;
    [Test]
    procedure DovrebbeDareErrorePerUnEventoSenzaOggetto;
    [Test]
    procedure DovrebbeDareErrorePerUnEventoCheSysNonConosce;
    [Test]
    procedure DovrebbeDareErrorePerUnNomeCheNonEUnaFunzione;
    [Test]
    procedure DovrebbeDareErrorePerUnVettoreScrittoMale;
    [Test]
    procedure DovrebbeDareErrorePerUnaPunteggiaturaSconosciuta;
    [Test]
    procedure DovrebbeDareErrorePerUnEventoCheLHostNonHaDefinito;
    [Test]
    procedure DovrebbeDareErrorePerUnaFunzioneDichiarataESenzaCorpo;
    [Test]
    procedure DovrebbeMettereFileERigaNellErrore;
    [Test]
    procedure DovrebbeStampareSoloIlTestoDellErroreDallaConsole;
    [Test]
    procedure DovrebbeTroncareA16BitIlNumeroDiRigaDiUnoStatement;
    [Test]
    procedure DovrebbeLasciareEseguibiliLeFunzioniCompilatePrimaDiUnErrore;
    [Test]
    procedure DovrebbeEseguireSenzaDanniLaFunzioneLaCuiCompilazioneEFallita;
    [Test]
    procedure DovrebbeRipristinareLaMascheraDelleEccezioniInVirgolaMobile;
  end;

implementation

uses
  System.Math, DelphiDoom.DoomScript.ScriptProgram;

procedure TTestDoomScriptCompiler.Setup;
begin
  FRig := TDoomScriptTestRig.Create;
end;

procedure TTestDoomScriptCompiler.TearDown;
begin
  FRig.Free;
end;

function TTestDoomScriptCompiler.GlobalFloat(const AName: AnsiString): Single;
var
  LProgram: TDoomScriptProgram;
  LDef: TDoomScriptVarDef;
begin
  LProgram := FRig.Machine.ScriptProgram;
  LDef := LProgram.GetDef(nil, AName, LProgram.DefNamespace);
  Assert.IsNotNull(LDef, string(AName));
  Result := PSingle(LProgram.GlobalPtr(LDef.Value, 4))^;
end;

function TTestDoomScriptCompiler.StatementsOf(const AFunction: AnsiString): Integer;
begin
  Result := FRig.FindFunction(AFunction).NumStatements;
end;

procedure TTestDoomScriptCompiler.ExpectCompileError(const AText: AnsiString; const AMessage: string);
var
  LError: string;
begin
  LError := FRig.CompileError(AText);
  Assert.IsTrue(LError <> '', 'no error, expected: ' + AMessage);
  Assert.Contains(LError, AMessage);
end;

procedure TTestDoomScriptCompiler.DovrebbePiegareLeCostantiAritmetiche;
begin
  FRig.Compile(
    'float a; float b; float c; float d; float e; float f; float g; float h;'#10 +
    'void calc() { a = 2 * 3 + 4; b = 7 / 2; c = 7 % 4; d = 6 & 3; e = 6 | 3; f = -( 2 + 3 ); g = ~5; h = 10 - 2.5; }'#10 +
    'float twelve() { return 3 * 4; }'#10);
  // every expression is one constant: eight stores and the return
  Assert.AreEqual(9, StatementsOf('calc'));
  Assert.IsTrue(FRig.Run('calc'));
  Assert.AreEqual(Single(10), GlobalFloat('a'));
  Assert.AreEqual(Single(3.5), GlobalFloat('b'));
  Assert.AreEqual(Single(3), GlobalFloat('c'));
  Assert.AreEqual(Single(2), GlobalFloat('d'));
  Assert.AreEqual(Single(7), GlobalFloat('e'));
  Assert.AreEqual(Single(-5), GlobalFloat('f'));
  Assert.AreEqual(Single(-6), GlobalFloat('g'));
  Assert.AreEqual(Single(7.5), GlobalFloat('h'));
  // the product is a constant: the return of the value and the return every function ends with
  Assert.AreEqual(2, StatementsOf('twelve'));
end;

procedure TTestDoomScriptCompiler.DovrebbePiegareConfrontiELogica;
begin
  FRig.Compile(
    'float a; float b; float c; float d; float e; float f; float g; float h; float i; float j;'#10 +
    'void calc() { a = ( 2 < 3 ); b = ( 2 > 3 ); c = ( 2 <= 2 ); d = ( 3 >= 4 ); e = ( 2 == 2 ); f = ( 2 != 2 );'#10 +
    '  g = ( 1 && 0 ); h = ( 1 || 0 ); i = !3; j = !0; }'#10);
  Assert.AreEqual(11, StatementsOf('calc'));
  Assert.IsTrue(FRig.Run('calc'));
  Assert.AreEqual(Single(1), GlobalFloat('a'));
  Assert.AreEqual(Single(0), GlobalFloat('b'));
  Assert.AreEqual(Single(1), GlobalFloat('c'));
  Assert.AreEqual(Single(0), GlobalFloat('d'));
  Assert.AreEqual(Single(1), GlobalFloat('e'));
  Assert.AreEqual(Single(0), GlobalFloat('f'));
  Assert.AreEqual(Single(0), GlobalFloat('g'));
  Assert.AreEqual(Single(1), GlobalFloat('h'));
  Assert.AreEqual(Single(0), GlobalFloat('i'));
  Assert.AreEqual(Single(1), GlobalFloat('j'));
end;

procedure TTestDoomScriptCompiler.DovrebbePiegareLeCostantiVettore;
begin
  FRig.Compile(
    'vector v; vector w; vector n; vector s; float dot; float same; float other; float zero;'#10 +
    'void calc() { v = ''1 2 3'' + ''10 20 30''; w = ''1 2 3'' * 2; n = -''1 2 3''; s = ''4 5 6'' - ''1 1 1'';'#10 +
    '  dot = ''1 2 3'' * ''4 5 6''; same = ( ''1 2 3'' == ''1 2 3'' ); other = ( ''1 2 3'' != ''1 2 3'' );'#10 +
    '  zero = !''0 0 0''; }'#10);
  Assert.AreEqual(9, StatementsOf('calc'));
  Assert.IsTrue(FRig.Run('calc'));
  Assert.AreEqual(Single(11), GlobalFloat('v_x'));
  Assert.AreEqual(Single(22), GlobalFloat('v_y'));
  Assert.AreEqual(Single(33), GlobalFloat('v_z'));
  Assert.AreEqual(Single(6), GlobalFloat('w_z'));
  Assert.AreEqual(Single(-2), GlobalFloat('n_y'));
  Assert.AreEqual(Single(3), GlobalFloat('s_x'));
  Assert.AreEqual(Single(32), GlobalFloat('dot'));
  Assert.AreEqual(Single(1), GlobalFloat('same'));
  Assert.AreEqual(Single(0), GlobalFloat('other'));
  Assert.AreEqual(Single(1), GlobalFloat('zero'));
end;

procedure TTestDoomScriptCompiler.DovrebbeRiusareLaStessaCostante;
var
  LBefore: Integer;
  LAfter: Integer;
begin
  FRig.Compile('float a = 42.5;'#10);
  LBefore := FRig.Machine.ScriptProgram.NumDefs;
  FRig.Compile('float b = 42.5;'#10);
  LAfter := FRig.Machine.ScriptProgram.NumDefs;
  // only the def of "b" is new: the immediate 42.5 is the one of "a"
  Assert.AreEqual(LBefore + 1, LAfter);
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerLaDivisioneCostantePerZero;
begin
  ExpectCompileError('void main() { float a; a = 1 / 0; }'#10, 'Divide by zero');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerIlModuloCostantePerZeroCheNellOriginaleEUnCrash;
begin
  // idCompiler::OptimizeOpcode divides the integers without a check: the original compiler crashes
  ExpectCompileError('void main() { float a; a = 5 % 0; }'#10, 'Divide by zero');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerIlModuloCostanteConDivisoreFraMenoUnoEUno;
begin
  // (int)0.5 is 0: the same crash of the original
  ExpectCompileError('void main() { float a; a = 5 % 0.5; }'#10, 'Divide by zero');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareZeroPerIlModuloCostantePerMenoUno;
begin
  // the idiv of the x86 traps on INT_MIN % -1; any value modulo -1 is 0
  FRig.Compile('float a = 9; void main() { a = 5 % -1; }'#10);
  Assert.IsTrue(FRig.Run('main'));
  Assert.AreEqual(Single(0), GlobalFloat('a'));
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnaFunzioneGlobaleChiamataSuUnEntitaCheNellOriginaleEUnCrash;
var
  LError: string;
begin
  // idCompiler::VirtualFunctionConstant asks the name of def_namespace, which has none: a crash of the
  // original. Here it is an error of the compilation.
  LError := FRig.CompileError(
    'void helper() { }'#10 +
    'void main() { entity e; e.helper(); }'#10);
  Assert.IsTrue(LError <> '', 'no error');
  Assert.Contains(LError, 'helper');
  Assert.Contains(LError, 'Error: file test.script, line 2');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnEventoChiamatoComeThread;
begin
  ExpectCompileError('void main() { thread sys.pause(); }'#10, 'Cannot call built-in functions as a thread');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnEventoSenzaOggetto;
begin
  ExpectCompileError('void main() { pause(); }'#10, 'Built-in functions cannot be called without an object');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnEventoCheSysNonConosce;
begin
  // "ping" is an event of the entities of the rig: the class of the threads has no handler for it
  ExpectCompileError('void main() { sys.ping( 1 ); }'#10, '"ping" is not callable as a ''sys'' function');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnNomeCheNonEUnaFunzione;
begin
  ExpectCompileError('float x;'#10'void main() { x(); }'#10, 'is not a function');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnVettoreScrittoMale;
begin
  ExpectCompileError('vector v = ''1 2'';'#10, 'Couldn''t read vector');
  ExpectCompileError('vector v2 = ''1 a 3'';'#10, 'expected float value');
  ExpectCompileError('vector v3 = ''1 - a'';'#10, 'expected a number following ''-''');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnaPunteggiaturaSconosciuta;
begin
  ExpectCompileError('void main() { float a; a = a ^ 2; }'#10, 'Unknown punctuation ''^''');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnEventoCheLHostNonHaDefinito;
begin
  ExpectCompileError('scriptEvent void neverDefinedByTheHost();'#10, 'neverDefinedByTheHost');
end;

procedure TTestDoomScriptCompiler.DovrebbeDareErrorePerUnaFunzioneDichiarataESenzaCorpo;
begin
  ExpectCompileError('void later();'#10'void main() { later(); }'#10, 'function later was not defined');
end;

procedure TTestDoomScriptCompiler.DovrebbeMettereFileERigaNellErrore;
var
  LError: string;
begin
  LError := FRig.CompileError('void main() {'#10#10'  float a = ;'#10'}'#10);
  Assert.StartsWith('Error: file test.script, line 3: ', LError);
  // the text of the error of the game ends with two new lines (one of the compiler, one of the program)
  Assert.EndsWith(#10#10, LError);
end;

procedure TTestDoomScriptCompiler.DovrebbeStampareSoloIlTestoDellErroreDallaConsole;
begin
  Assert.IsFalse(FRig.Machine.ScriptProgram.CompileText('console', 'void main() { float a = ; }'#10, True));
  Assert.Contains(FRig.Printed, 'Error: ');
  Assert.IsFalse(FRig.Printed.Contains('line '), FRig.Printed);
  // nothing else is printed for the console: no "Compiled" and no statistics
  Assert.IsFalse(FRig.Printed.Contains('Compiled '), FRig.Printed);
end;

procedure TTestDoomScriptCompiler.DovrebbeTroncareA16BitIlNumeroDiRigaDiUnoStatement;
var
  LText: AnsiString;
  LFunction: TDoomScriptFunction;
begin
  // statement_t::linenumber is an unsigned short: a statement of line 65537 says it is of line 1
  LText := AnsiString(StringOfChar(#10, 65536)) + 'float a; void main() { a = a + 1; }'#10;
  FRig.Compile(LText);
  LFunction := FRig.FindFunction('main');
  Assert.AreEqual(1, Integer(FRig.Machine.ScriptProgram.GetStatement(LFunction.FirstStatement).LineNumber));
end;

procedure TTestDoomScriptCompiler.DovrebbeLasciareEseguibiliLeFunzioniCompilatePrimaDiUnErrore;
begin
  // as in the original: what was compiled before the error stays in the program
  Assert.IsTrue(FRig.CompileError(
    'void first() { sys.print( "first runs" ); }'#10 +
    'void second() { float a = ; }'#10) <> '');
  Assert.IsTrue(FRig.Run('first'));
  Assert.Contains(FRig.Printed, 'first runs');
end;

procedure TTestDoomScriptCompiler.DovrebbeEseguireSenzaDanniLaFunzioneLaCuiCompilazioneEFallita;
var
  LFunction: TDoomScriptFunction;
  LError: string;
begin
  // The function whose body stopped at the error is in the program without its statements: running it is a
  // crash in the original. Here it ends with an error of the machine.
  Assert.IsTrue(FRig.CompileError(
    'float touched;'#10 +
    'void broken( float p ) { float a; string s; touched = 1; a = ; touched = 2; }'#10) <> '');
  LFunction := FRig.Machine.ScriptProgram.FindFunction('broken');
  Assert.IsNotNull(LFunction, 'the function is declared');
  try
    FRig.Machine.CreateThread(LFunction).Start;
  except
    // any other exception ends the test
    on E: EDoomScriptError do
      LError := E.Message;
  end;
  // the statements compiled before the error run, then the function has no end: it leaves the program
  Assert.AreEqual(Single(1), GlobalFloat('touched'));
  Assert.Contains(LError, 'is outside the program');
  // the program is still usable
  FRig.Machine.RestartThreads;
  FRig.Compile('void fine() { sys.print( "fine" ); }'#10);
  Assert.IsTrue(FRig.Run('fine'));
end;

procedure TTestDoomScriptCompiler.DovrebbeRipristinareLaMascheraDelleEccezioniInVirgolaMobile;
var
  LMask: TArithmeticExceptionMask;
begin
  // the compiler masks the floating point exceptions while it folds constants and puts the mask back,
  // also when the compilation fails
  LMask := GetExceptionMask;
  FRig.Compile('float big; void main() { big = 1e30 * 1e30; }'#10);
  Assert.IsTrue(LMask = GetExceptionMask, 'mask after a compilation');
  FRig.CompileError('float second = ;'#10);
  Assert.IsTrue(LMask = GetExceptionMask, 'mask after an error');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptCompiler);

end.
