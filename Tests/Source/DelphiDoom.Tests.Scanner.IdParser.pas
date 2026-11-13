{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - TIdParser and its parts          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.IdParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Token, DelphiDoom.Scanner.IdParser,
  DelphiDoom.Tests.Scanner.IdFakes;

type
  [TestFixture]
  [Category('IdParser')]
  TTestIdParser = class
  strict private
    FLog: TFakeIdLibLog;
    FLogIntf: IIdLibLog;
    FFileSystem: TFakeIdLibFileSystem;
    FFileSystemIntf: IIdLibFileSystem;
    function NewParser(const AText: AnsiString; const AFlags: Integer = 0): TIdParser;
    function Tokens(const AParser: TIdParser): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSostituireUnaMacroConParametri;
    [Test]
    procedure DovrebbeEspandereLeBuiltinDataEOraConLOrologioDato;
    [Test]
    procedure DovrebbeEspandereLineEFile;
    [Test]
    procedure DovrebbeLeggereUnFileDalFileSystem;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileMancante;
    [Test]
    procedure DovrebbeSollevareSeUnaSorgenteEGiaCaricata;
    [Test]
    procedure DovrebbeDareIlNomeLaRigaELOffset;
    [Test]
    procedure DovrebbeConoscereLaPunteggiaturaDiDefault;
    [Test]
    procedure DovrebbeUsareUnaPunteggiaturaPropria;
    [Test]
    procedure DovrebbeSpiegareUnTipoDiNumeroSbagliato;
    [Test]
    procedure DovrebbeSpiegareUnaPunteggiaturaSbagliata;
    [Test]
    procedure DovrebbeSpiegareUnTipoSbagliato;
    [Test]
    procedure DovrebbeControllareEGuardareUnTokenPerTipo;
    [Test]
    procedure DovrebbeLeggereLeMatrici;
    [Test]
    procedure DovrebbeLeggereUnaSezioneEsattaDelloScript;
    [Test]
    procedure DovrebbeTenereIDefineConFreeSourceCheLiConserva;
    [Test]
    procedure DovrebbeSollevareSenzaSorgenteCaricata;
    [Test]
    procedure DovrebbeRestareValidoDopoLaConversioneAInterfaccia;
    [Test]
    procedure DovrebbeAggiungereEToglieDefineGlobali;
    [Test]
    procedure DovrebbeUsareLaBaseFolderDelFileSystem;
    [Test]
    procedure DovrebbeCambiareIFlagDiTuttiGliScript;
    [Test]
    procedure DovrebbeDareFalsoPerUnDefinedSenzaNome;
    [Test]
    procedure DovrebbeFermarsiAlMassimoDiValoriEOperatori;
  end;

  [TestFixture]
  [Category('IdParser')]
  TTestIdParserEvaluator = class
  strict private
    function Lex(const AText: AnsiString): TArray<TIdToken>;
  public
    [Test]
    procedure DovrebbeDareLePrioritaDegliOperatori;
    [Test]
    procedure DovrebbeCalcolareInteriEFloatInsieme;
    [Test]
    procedure DovrebbeRifiutareGliOperatoriInteriSuiFloat;
    [Test]
    procedure DovrebbeUsareLaFunzioneDefined;
    [Test]
    procedure DovrebbeFarGirareISegniEGliScorrimenti;
    [Test]
    procedure DovrebbeDareZeroSeCeUnErrore;
  end;

  [TestFixture]
  [Category('IdParser')]
  TTestIdParserDefines = class
  public
    [Test]
    procedure DovrebbeCopiareUnDefineSenzaCondividerlo;
    [Test]
    procedure DovrebbeTrovareIParametri;
    [Test]
    procedure DovrebbeTenereLeGlobaliInOrdineInversoDiInserimento;
    [Test]
    procedure DovrebbeTogliereUnaGlobaleEDirePerche;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Scanner.IdParser.Types, DelphiDoom.Scanner.IdParser.Intf, DelphiDoom.Scanner.IdParser.Define,
  DelphiDoom.Scanner.IdParser.GlobalDefines, DelphiDoom.Scanner.IdParser.Evaluator;

{ TTestIdParser }

procedure TTestIdParser.Setup;
begin
  FLog := TFakeIdLibLog.Create;
  FLogIntf := FLog;
  FFileSystem := TFakeIdLibFileSystem.Create;
  FFileSystemIntf := FFileSystem;
end;

procedure TTestIdParser.TearDown;
begin
  FFileSystemIntf := nil;
  FLogIntf := nil;
end;

function TTestIdParser.NewParser(const AText: AnsiString; const AFlags: Integer): TIdParser;
begin
  Result := TIdParser.Create(AFlags, FLogIntf, FFileSystemIntf);
  Result.LoadMemory(AText, 'test');
end;

function TTestIdParser.Tokens(const AParser: TIdParser): string;
var
  LToken: TIdToken;
begin
  Result := '';
  LToken := TIdToken.Create;
  while AParser.ReadToken(LToken) do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + string(LToken.Text);
  end;
end;

procedure TTestIdParser.DovrebbeSostituireUnaMacroConParametri;
var
  LParser: TIdParser;
begin
  LParser := NewParser('#define ADD(a, b) ((a) + (b))'#10'ADD(1, 2)');
  try
    Assert.AreEqual('( ( 1 ) + ( 2 ) )', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeEspandereLeBuiltinDataEOraConLOrologioDato;
var
  LParser: TIdParser;
begin
  LParser := NewParser('__DATE__ __TIME__', LEXFL_NOSTRINGCONCAT);
  try
    LParser.AddBuiltinDefines;
    LParser.Clock := function: TDateTime
      begin
        Result := EncodeDate(2026, 11, 4) + EncodeTime(9, 5, 7, 0);
      end;
    Assert.AreEqual('"Nov  4 2026" "09:05:07"', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeEspandereLineEFile;
var
  LParser: TIdParser;
begin
  LParser := NewParser('a'#10'__LINE__ __FILE__');
  try
    LParser.AddBuiltinDefines;
    Assert.AreEqual('a 2 test', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeLeggereUnFileDalFileSystem;
var
  LParser: TIdParser;
begin
  FFileSystem.Add('dir/a.txt', 'one two');
  LParser := TIdParser.Create(0, FLogIntf, FFileSystemIntf);
  try
    Assert.IsTrue(LParser.LoadFile('dir/a.txt'));
    Assert.IsTrue(LParser.IsLoaded);
    Assert.AreEqual('one two', Tokens(LParser));
    Assert.AreEqual('dir/a.txt', string(LParser.FileName));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeDareFalsoPerUnFileMancante;
var
  LParser: TIdParser;
begin
  LParser := TIdParser.Create(0, FLogIntf, FFileSystemIntf);
  try
    Assert.IsFalse(LParser.LoadFile('missing.txt'));
    Assert.IsFalse(LParser.IsLoaded);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeSollevareSeUnaSorgenteEGiaCaricata;
var
  LParser: TIdParser;
begin
  LParser := NewParser('x');
  try
    Assert.WillRaise(
      procedure
      begin
        LParser.LoadMemory('y', 'again');
      end, EIdLibFatalException);
    Assert.WillRaise(
      procedure
      begin
        LParser.LoadFile('a');
      end, EIdLibFatalException);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeDareIlNomeLaRigaELOffset;
var
  LParser: TIdParser;
  LToken: TIdToken;
begin
  LParser := TIdParser.Create;
  try
    Assert.AreEqual('', string(LParser.FileName));
    Assert.AreEqual(0, LParser.LineNum);
    Assert.AreEqual(0, LParser.FileOffset);
    Assert.AreEqual(Int64(0), LParser.FileTime);
    Assert.AreEqual(0, LParser.GetLastWhiteSpace(LToken.Text));
    LParser.LoadMemory('a'#10'bb', 'script');
    LToken := TIdToken.Create;
    LParser.ReadToken(LToken);
    LParser.ReadToken(LToken);
    Assert.AreEqual('script', string(LParser.FileName));
    Assert.AreEqual(2, LParser.LineNum);
    Assert.AreEqual(4, LParser.FileOffset);
    Assert.AreEqual(Int64(0), LParser.FileTime);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeConoscereLaPunteggiaturaDiDefault;
var
  LParser: TIdParser;
begin
  LParser := TIdParser.Create;
  try
    Assert.AreEqual('+', string(LParser.GetPunctuationFromId(P_ADD)));
    Assert.AreEqual(P_ADD, LParser.GetPunctuationId('+'));
    Assert.AreEqual(0, LParser.GetPunctuationId('no'));
    Assert.AreEqual('unkown punctuation', string(LParser.GetPunctuationFromId(9999)));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeUsareUnaPunteggiaturaPropria;
var
  LParser: TIdParser;
  LSet: TIdPunctuationList;
begin
  SetLength(LSet, 1);
  LSet[0].Text := '@';
  LSet[0].Id := 77;
  LParser := TIdParser.Create;
  try
    LParser.SetPunctuations(LSet);
    LParser.LoadMemory('a@b', 'x');
    Assert.AreEqual('@', string(LParser.GetPunctuationFromId(77)));
    Assert.AreEqual(77, LParser.GetPunctuationId('@'));
    Assert.AreEqual('unkown punctuation', string(LParser.GetPunctuationFromId(P_ADD)));
    Assert.AreEqual(0, LParser.GetPunctuationId('+'));
    Assert.AreEqual('a @ b', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeSpiegareUnTipoDiNumeroSbagliato;
var
  LParser: TIdParser;
  LToken: TIdToken;
begin
  LParser := NewParser('12 12 0x10', LEXFL_NOFATALERRORS);
  try
    LToken := TIdToken.Create;
    Assert.IsFalse(LParser.ExpectTokenType(TT_NUMBER, TT_FLOAT, LToken));
    Assert.IsFalse(LParser.ExpectTokenType(TT_NUMBER, TT_DECIMAL or TT_UNSIGNED or TT_LONG, LToken));
    Assert.IsFalse(LParser.ExpectTokenType(TT_NUMBER, TT_BINARY or TT_INTEGER, LToken));
    Assert.AreEqual('W: file test, line 1: expected float but found ''12''', FLog.Lines[0]);
    Assert.AreEqual('W: file test, line 1: expected decimal unsigned long but found ''12''', FLog.Lines[1]);
    Assert.AreEqual('W: file test, line 1: expected binary integer but found ''0x10''', FLog.Lines[2]);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeSpiegareUnaPunteggiaturaSbagliata;
var
  LParser: TIdParser;
  LToken: TIdToken;
begin
  LParser := NewParser('+ + +', LEXFL_NOFATALERRORS);
  try
    LToken := TIdToken.Create;
    Assert.IsFalse(LParser.ExpectTokenType(TT_PUNCTUATION, P_SUB, LToken));
    Assert.IsFalse(LParser.ExpectTokenType(TT_PUNCTUATION, -1, LToken));
    Assert.IsTrue(LParser.ExpectTokenType(TT_PUNCTUATION, P_ADD, LToken));
    Assert.AreEqual('W: file test, line 1: expected ''-'' but found ''+''', FLog.Lines[0]);
    Assert.AreEqual('W: file test, line 1: BUG: wrong punctuation subtype', FLog.Lines[1]);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeSpiegareUnTipoSbagliato;
var
  LParser: TIdParser;
  LToken: TIdToken;
  LTypes: array[0..5] of Integer;
  LNames: array[0..5] of string;
  LIndex: Integer;
begin
  LTypes[0] := TT_STRING;
  LTypes[1] := TT_LITERAL;
  LTypes[2] := TT_NUMBER;
  LTypes[3] := TT_NAME;
  LTypes[4] := TT_PUNCTUATION;
  LTypes[5] := 99;
  LNames[0] := 'string';
  LNames[1] := 'literal';
  LNames[2] := 'number';
  LNames[3] := 'name';
  LNames[4] := 'punctuation';
  LNames[5] := 'unknown type';
  LParser := NewParser('+ + + + + + +', LEXFL_NOFATALERRORS);
  try
    LToken := TIdToken.Create;
    for LIndex := 0 to 5 do
    begin
      Assert.IsFalse(LParser.ExpectTokenType(LTypes[LIndex], 0, LToken));
      if LTypes[LIndex] <> TT_PUNCTUATION then
        Assert.AreEqual('W: file test, line 1: expected a ' + LNames[LIndex] + ' but found ''+''',
          FLog.Lines[FLog.Lines.Count - 1]);
    end;
    // at the end of the script
    LParser.ReadToken(LToken);
    Assert.IsFalse(LParser.ExpectTokenType(TT_NAME, 0, LToken));
    Assert.IsFalse(LParser.ExpectAnyToken(LToken));
    Assert.AreEqual('W: file test, line 1: couldn''t read expected token', FLog.Lines[FLog.Lines.Count - 1]);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeControllareEGuardareUnTokenPerTipo;
var
  LParser: TIdParser;
  LToken: TIdToken;
begin
  LParser := NewParser('name 5');
  try
    LToken := TIdToken.Create;
    Assert.IsFalse(LParser.CheckTokenType(TT_NUMBER, 0, LToken));
    Assert.IsFalse(LParser.PeekTokenType(TT_NUMBER, 0, LToken));
    Assert.IsTrue(LParser.PeekTokenType(TT_NAME, 0, LToken));
    Assert.AreEqual('name', string(LToken.Text));
    Assert.IsTrue(LParser.CheckTokenType(TT_NAME, 0, LToken));
    LToken := TIdToken.Create;
    LToken.Text := 'back';
    LParser.UnreadToken(LToken);
    Assert.IsTrue(LParser.CheckTokenString('back'));
    Assert.IsTrue(LParser.CheckTokenType(TT_NUMBER, TT_INTEGER, LToken));
    Assert.AreEqual(5, LToken.GetIntValue);
    Assert.IsFalse(LParser.CheckTokenType(TT_NAME, 0, LToken));
    Assert.IsFalse(LParser.PeekTokenType(TT_NAME, 0, LToken));
    Assert.IsFalse(LParser.PeekTokenString('x'));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeLeggereLeMatrici;
var
  LParser: TIdParser;
  LMatrix: array[0..7] of Single;
begin
  LParser := NewParser('( 1 2 ) ( ( 1 2 ) ( 3 4 ) ) ( ( ( 1 2 ) ( 3 4 ) ) ( ( 5 6 ) ( 7 8 ) ) ) ( 1 2');
  try
    FillChar(LMatrix, SizeOf(LMatrix), 0);
    Assert.IsTrue(LParser.Parse1DMatrix(2, LMatrix));
    Assert.AreEqual(Single(2), LMatrix[1]);
    Assert.IsTrue(LParser.Parse2DMatrix(2, 2, LMatrix));
    Assert.AreEqual(Single(3), LMatrix[2]);
    Assert.AreEqual(Single(4), LMatrix[3]);
    Assert.IsTrue(LParser.Parse3DMatrix(2, 2, 2, LMatrix));
    Assert.AreEqual(Single(8), LMatrix[7]);
  finally
    LParser.Free;
  end;
  LParser := NewParser('( 1 2', LEXFL_NOFATALERRORS);
  try
    Assert.IsFalse(LParser.Parse1DMatrix(2, LMatrix));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeLeggereUnaSezioneEsattaDelloScript;
var
  LParser: TIdParser;
  LText: AnsiString;
begin
  LParser := NewParser('{ a  b'#10'  c }');
  try
    LParser.ParseBracedSectionExact(LText);
    Assert.AreEqual('{ a  b'#10'  c }', string(LText));
  finally
    LParser.Free;
  end;
  LParser := TIdParser.Create;
  try
    Assert.AreEqual('', string(LParser.ParseBracedSectionExact(LText)));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeTenereIDefineConFreeSourceCheLiConserva;
var
  LParser: TIdParser;
begin
  LParser := NewParser('#define KEPT 5');
  try
    Tokens(LParser);
    LParser.FreeSource(True);
    Assert.IsFalse(LParser.IsLoaded);
    LParser.LoadMemory('KEPT', 'two');
    Assert.AreEqual('5', Tokens(LParser));
    LParser.FreeSource(False);
    LParser.LoadMemory('KEPT', 'three');
    Assert.AreEqual('KEPT', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeSollevareSenzaSorgenteCaricata;
var
  LParser: TIdParser;
begin
  LParser := TIdParser.Create;
  try
    Assert.WillRaise(
      procedure
      var
        LToken: TIdToken;
      begin
        LToken := TIdToken.Create;
        LParser.ReadToken(LToken);
      end, EIdLibFatalException);
    Assert.WillRaise(
      procedure
      begin
        LParser.AddDefine('A 1');
      end, EIdLibFatalException);
    Assert.WillRaise(
      procedure
      begin
        LParser.AddBuiltinDefines;
      end, EIdLibFatalException);
    Assert.WillRaise(
      procedure
      begin
        LParser.AddGlobalDefine('A 1');
      end, EIdLibFatalException);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeRestareValidoDopoLaConversioneAInterfaccia;
var
  LParser: TIdParser;

  procedure UseAsInterface(const ASource: IIdTokenSource);
  var
    LToken: TIdToken;
  begin
    LToken := TIdToken.Create;
    Assert.IsTrue(ASource.ReadToken(LToken));
    Assert.IsTrue(ASource.ExpectTokenString('b'));
  end;

begin
  LParser := NewParser('a b');
  try
    UseAsInterface(LParser);
    LParser.FreeSource;
    LParser.LoadMemory('a b', 'again');
    UseAsInterface(LParser);
    Assert.IsTrue(Supports(LParser, IIdTokenSource));
    // the object is still alive: the interface did not count
    Assert.IsFalse(LParser.PeekTokenString('b'));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeAggiungereEToglieDefineGlobali;
var
  LGlobals: TIdParserGlobalDefines;
  LParser: TIdParser;
begin
  LGlobals := TIdParserGlobalDefines.Create;
  try
    LParser := TIdParser.Create(0, FLogIntf, FFileSystemIntf, LGlobals);
    try
      Assert.IsTrue(LParser.AddGlobalDefine('G 9'));
      Assert.AreEqual(1, LGlobals.Count);
      LParser.LoadMemory('G', 'x');
      Assert.AreEqual('9', Tokens(LParser));
    finally
      LParser.Free;
    end;
  finally
    LGlobals.Free;
  end;
end;

procedure TTestIdParser.DovrebbeUsareLaBaseFolderDelFileSystem;
var
  LParser: TIdParser;
begin
  FFileSystem.Add('base/a.txt', 'found');
  LParser := TIdParser.Create(0, FLogIntf, FFileSystemIntf);
  try
    LParser.BaseFolder := 'base';
    Assert.IsTrue(LParser.LoadFile('a.txt'));
    Assert.AreEqual('found', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeCambiareIFlagDiTuttiGliScript;
var
  LParser: TIdParser;
begin
  FFileSystem.Add('inc.txt', '"x" "y"');
  LParser := NewParser('#include "inc.txt"'#10'name "a" "b"', LEXFL_NOSTRINGCONCAT);
  try
    Assert.AreEqual(LEXFL_NOSTRINGCONCAT, LParser.Flags);
    LParser.Flags := 0;
    Assert.AreEqual('xy name ab', Tokens(LParser));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeDareFalsoPerUnDefinedSenzaNome;
var
  LParser: TIdParser;
begin
  LParser := NewParser('#if defined'#10'x'#10'#endif'#10'y', LEXFL_NOFATALERRORS);
  try
    // the original reads past the end of the tokens here
    Assert.AreEqual('', Tokens(LParser));
    Assert.AreEqual('W: file test, line 2: defined() without name in #if/#elif', FLog.Lines[0]);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdParser.DovrebbeFermarsiAlMassimoDiValoriEOperatori;
var
  LParser: TIdParser;
  LExpression: string;
  LIndex: Integer;
begin
  LExpression := '1';
  for LIndex := 1 to 70 do
    LExpression := LExpression + ' + 1';
  LParser := NewParser(AnsiString('#if ' + LExpression + #10'x'#10'#endif'), LEXFL_NOFATALERRORS);
  try
    Assert.AreEqual('', Tokens(LParser));
    Assert.IsTrue(Pos('out of value space', FLog.Lines[0]) > 0);
  finally
    LParser.Free;
  end;
  FLog.Lines.Clear;
  LParser := NewParser('#if 1 (2) (3) (4)'#10'x', LEXFL_NOFATALERRORS);
  try
    Tokens(LParser);
    Assert.IsTrue(FLog.Lines.Count > 0);
  finally
    LParser.Free;
  end;
end;

{ TTestIdParserEvaluator }

function TTestIdParserEvaluator.Lex(const AText: AnsiString): TArray<TIdToken>;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
  LList: TList<TIdToken>;
begin
  LLexer := TIdLexer.Create;
  LList := TList<TIdToken>.Create;
  try
    LLexer.LoadMemory(AText, 'expression');
    LToken := TIdToken.Create;
    while LLexer.ReadToken(LToken) do
      LList.Add(LToken);
    Result := LList.ToArray;
  finally
    LList.Free;
    LLexer.Free;
  end;
end;

procedure TTestIdParserEvaluator.DovrebbeDareLePrioritaDegliOperatori;
begin
  Assert.AreEqual(15, TIdParserEvaluator.OperatorPriority(P_MUL));
  Assert.AreEqual(14, TIdParserEvaluator.OperatorPriority(P_ADD));
  Assert.AreEqual(16, TIdParserEvaluator.OperatorPriority(P_LOGIC_NOT));
  Assert.AreEqual(5, TIdParserEvaluator.OperatorPriority(P_QUESTIONMARK));
  Assert.AreEqual(0, TIdParserEvaluator.OperatorPriority(P_INC));
end;

procedure TTestIdParserEvaluator.DovrebbeCalcolareInteriEFloatInsieme;
var
  LEvaluator: TIdParserEvaluator;
  LInt: Integer;
  LFloat: Double;
begin
  LEvaluator := TIdParserEvaluator.Create(nil, nil);
  try
    Assert.IsTrue(LEvaluator.Evaluate(Lex('1 + 2 * 3'), True, LInt, LFloat));
    Assert.AreEqual(7, LInt);
    Assert.AreEqual(Double(7), LFloat);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('1.5 * 2.0'), False, LInt, LFloat));
    Assert.AreEqual(Double(3), LFloat);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('7 / 2'), True, LInt, LFloat));
    Assert.AreEqual(3, LInt);
    Assert.AreEqual(Double(3.5), LFloat);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('1 ? 10 : 20'), True, LInt, LFloat));
    Assert.AreEqual(10, LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('0 ? 10 : 20'), True, LInt, LFloat));
    Assert.AreEqual(20, LInt);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestIdParserEvaluator.DovrebbeRifiutareGliOperatoriInteriSuiFloat;
var
  LEvaluator: TIdParserEvaluator;
  LInt: Integer;
  LFloat: Double;
  LMessage: string;
begin
  LMessage := '';
  LEvaluator := TIdParserEvaluator.Create(nil,
    procedure(const AText: string)
    begin
      LMessage := AText;
    end);
  try
    Assert.IsFalse(LEvaluator.Evaluate(Lex('5 % 2'), False, LInt, LFloat));
    Assert.AreEqual('illigal operator ''%'' on floating point operands'#10, LMessage);
    Assert.AreEqual(0, LInt);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestIdParserEvaluator.DovrebbeUsareLaFunzioneDefined;
var
  LEvaluator: TIdParserEvaluator;
  LInt: Integer;
  LFloat: Double;
begin
  LEvaluator := TIdParserEvaluator.Create(
    function(const AName: AnsiString): Boolean
    begin
      Result := AName = 'YES';
    end, nil);
  try
    Assert.IsTrue(LEvaluator.Evaluate(Lex('defined(YES) && !defined NO'), True, LInt, LFloat));
    Assert.AreEqual(1, LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('defined(NO) || defined YES'), True, LInt, LFloat));
    Assert.AreEqual(1, LInt);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestIdParserEvaluator.DovrebbeFarGirareISegniEGliScorrimenti;
var
  LEvaluator: TIdParserEvaluator;
  LInt: Integer;
  LFloat: Double;
begin
  LEvaluator := TIdParserEvaluator.Create(nil, nil);
  try
    Assert.IsTrue(LEvaluator.Evaluate(Lex('-8 >> 1'), True, LInt, LFloat));
    Assert.AreEqual(-4, LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('1 << 31'), True, LInt, LFloat));
    Assert.AreEqual(Low(Integer), LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('1 << 32'), True, LInt, LFloat));
    Assert.AreEqual(1, LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('-5 % 3'), True, LInt, LFloat));
    Assert.AreEqual(-2, LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('0 - 2147483647 - 1'), True, LInt, LFloat));
    Assert.AreEqual(Low(Integer), LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('(0 - 2147483647 - 1) / (0 - 1)'), True, LInt, LFloat));
    Assert.AreEqual(Low(Integer), LInt);
    Assert.IsTrue(LEvaluator.Evaluate(Lex('(0 - 2147483647 - 1) % (0 - 1)'), True, LInt, LFloat));
    Assert.AreEqual(0, LInt);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestIdParserEvaluator.DovrebbeDareZeroSeCeUnErrore;
var
  LEvaluator: TIdParserEvaluator;
  LInt: Integer;
  LFloat: Double;
begin
  LEvaluator := TIdParserEvaluator.Create(nil, nil);
  try
    Assert.IsFalse(LEvaluator.Evaluate(Lex('1 / 0'), True, LInt, LFloat));
    Assert.AreEqual(0, LInt);
    Assert.AreEqual(Double(0), LFloat);
    Assert.IsFalse(LEvaluator.Evaluate(Lex('1 +'), True, LInt, LFloat));
    Assert.IsFalse(LEvaluator.Evaluate(Lex('name'), True, LInt, LFloat));
    Assert.IsFalse(LEvaluator.Evaluate(Lex('"s"'), True, LInt, LFloat));
  finally
    LEvaluator.Free;
  end;
end;

{ TTestIdParserDefines }

procedure TTestIdParserDefines.DovrebbeCopiareUnDefineSenzaCondividerlo;
var
  LDefine, LCopy: TIdParserDefine;
  LToken: TIdToken;
begin
  LDefine := TIdParserDefine.Create('NAME');
  try
    LToken := TIdToken.Create;
    LToken.Text := 'a';
    LDefine.AddParm(LToken);
    LToken.Text := 'body';
    LDefine.AddToken(LToken);
    LDefine.Flags := DEFINE_FIXED;
    LDefine.Builtin := 3;
    LCopy := LDefine.Copy;
    try
      LDefine.AddToken(LToken);
      Assert.AreEqual('NAME', string(LCopy.Name));
      Assert.AreEqual(1, LCopy.NumParms);
      Assert.AreEqual(1, Integer(Length(LCopy.Tokens)));
      Assert.AreEqual(2, Integer(Length(LDefine.Tokens)));
      Assert.AreEqual(DEFINE_FIXED, LCopy.Flags);
      Assert.AreEqual(3, LCopy.Builtin);
    finally
      LCopy.Free;
    end;
  finally
    LDefine.Free;
  end;
end;

procedure TTestIdParserDefines.DovrebbeTrovareIParametri;
var
  LDefine: TIdParserDefine;
  LToken: TIdToken;
begin
  LDefine := TIdParserDefine.Create('F');
  try
    LToken := TIdToken.Create;
    LToken.Text := 'x';
    LDefine.AddParm(LToken);
    LToken.Text := 'y';
    LDefine.AddParm(LToken);
    Assert.AreEqual(0, LDefine.FindParm('x'));
    Assert.AreEqual(1, LDefine.FindParm('y'));
    Assert.AreEqual(-1, LDefine.FindParm('z'));
  finally
    LDefine.Free;
  end;
end;

procedure TTestIdParserDefines.DovrebbeTenereLeGlobaliInOrdineInversoDiInserimento;
var
  LGlobals: TIdParserGlobalDefines;
begin
  LGlobals := TIdParserGlobalDefines.Create;
  try
    LGlobals.Push(TIdParserDefine.Create('A'));
    LGlobals.Push(TIdParserDefine.Create('B'));
    Assert.AreEqual(2, LGlobals.Count);
    Assert.AreEqual('B', string(LGlobals.Item(0).Name));
    Assert.AreEqual('A', string(LGlobals.Item(1).Name));
    LGlobals.Clear;
    Assert.AreEqual(0, LGlobals.Count);
  finally
    LGlobals.Free;
  end;
end;

procedure TTestIdParserDefines.DovrebbeTogliereUnaGlobaleEDirePerche;
var
  LGlobals: TIdParserGlobalDefines;
begin
  LGlobals := TIdParserGlobalDefines.Create;
  try
    LGlobals.Push(TIdParserDefine.Create('A'));
    Assert.IsTrue(LGlobals.Remove('A'));
    Assert.IsFalse(LGlobals.Remove('A'));
    Assert.AreEqual(0, LGlobals.Count);
  finally
    LGlobals.Free;
  end;
end;

end.
