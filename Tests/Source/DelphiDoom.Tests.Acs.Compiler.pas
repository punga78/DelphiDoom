{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS compiler library - parity with the old compiler }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.Compiler;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Acs.Intf,
  DelphiDoom.Acs.Types, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder;

type
  /// <summary>
  ///   Every script in Tests\Data\Acs was compiled by the old compiler (acs_*.pas of the engine):
  ///   the .o files are the bytes it made and the .err files the text of its errors. The new
  ///   compiler has to give the same bytes and the same errors. The exceptions are consteval and define:
  ///   the old compiler folded some constant expressions wrongly (issue 61), their .o were
  ///   rebuilt with the values calculated by hand
  /// </summary>
  [TestFixture]
  [Category('acs')]
  TTestAcsCompiler = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    function DataPath(const AFileName: string): string;
    function ReadBytes(const AFileName: string): TBytes;
    function TextToBytes(const AText: string): TBytes;
    function MakeCompiler(const AProvider: IAcsSourceProvider): IAcsCompiler;
    function ProviderWithTheInclude: IAcsSourceProvider;
    function CompileFile(const AName: string): TBytes;
    function Compile(const AText: string; const AProvider: IAcsSourceProvider = nil): TBytes;
    /// <summary>The error that the text gives; nil if it compiles (the caller frees it)</summary>
    function Failure(const AText: string; const AProvider: IAcsSourceProvider = nil): EAcsCompileException;
    function LongAt(const ABytes: TBytes; AIndex: Integer): Cardinal;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('empty', 'empty')]
    [TestCase('variables', 'variables')]
    [TestCase('expressions', 'expressions')]
    [TestCase('control', 'control')]
    [TestCase('print', 'print')]
    [TestCase('strings', 'strings')]
    [TestCase('specials', 'specials')]
    [TestCase('functions', 'functions')]
    [TestCase('scripts', 'scripts')]
    [TestCase('define', 'define')]
    [TestCase('consteval', 'consteval')]
    [TestCase('comments', 'comments')]
    [TestCase('compact', 'compact')]
    [TestCase('include_main', 'include_main')]
    [TestCase('upper_case', 'upper_case')]
    procedure TestSameBytesAsTheOldCompiler(const AName: string);

    [Test]
    [TestCase('bad_character', 'e_bad_character')]
    [TestCase('bad_expression', 'e_bad_expression')]
    [TestCase('bad_radix', 'e_bad_radix')]
    [TestCase('bad_script_declaration', 'e_bad_script_declaration')]
    [TestCase('bad_special_arg_count', 'e_bad_special_arg_count')]
    [TestCase('case_not_in_switch', 'e_case_not_in_switch')]
    [TestCase('expression_function_without_value', 'e_expression_function_without_value')]
    [TestCase('identifier_too_long', 'e_identifier_too_long')]
    [TestCase('misplaced_break', 'e_misplaced_break')]
    [TestCase('misplaced_continue', 'e_misplaced_continue')]
    [TestCase('missing_include', 'e_missing_include')]
    [TestCase('missing_rparen', 'e_missing_rparen')]
    [TestCase('missing_semicolon', 'e_missing_semicolon')]
    [TestCase('multiple_default', 'e_multiple_default')]
    [TestCase('no_direct_version', 'e_no_direct_version')]
    [TestCase('redefined_identifier', 'e_redefined_identifier')]
    [TestCase('too_many_script_args', 'e_too_many_script_args')]
    [TestCase('too_many_script_vars', 'e_too_many_script_vars')]
    [TestCase('undefined_identifier', 'e_undefined_identifier')]
    [TestCase('unknown_print_type', 'e_unknown_print_type')]
    [TestCase('world_var_index', 'e_world_var_index')]
    procedure TestSameErrorAsTheOldCompiler(const AName: string);

    [Test]
    [TestCase('lt true', '3 < 5,1')]
    [TestCase('lt false', '5 < 3,0')]
    [TestCase('lt equal', '3 < 3,0')]
    [TestCase('le equal', '3 <= 3,1')]
    [TestCase('le false', '4 <= 3,0')]
    [TestCase('le true', '3 <= 5,1')]
    [TestCase('gt true', '5 > 3,1')]
    [TestCase('gt equal', '3 > 3,0')]
    [TestCase('gt false', '3 > 5,0')]
    [TestCase('ge equal', '3 >= 3,1')]
    [TestCase('ge false', '2 >= 3,0')]
    [TestCase('ge true', '5 >= 3,1')]
    [TestCase('eq true', '3 == 3,1')]
    [TestCase('eq false', '3 == 4,0')]
    [TestCase('ne false', '3 != 3,0')]
    [TestCase('ne true', '3 != 4,1')]
    [TestCase('shift left', '1 << 4,16')]
    [TestCase('shift left zero', '1 << 0,1')]
    [TestCase('shift right', '256 >> 2,64')]
    [TestCase('shift right negative', '(0 - 8) >> 1,-4')]
    [TestCase('not zero', '!0,1')]
    [TestCase('not five', '!5,0')]
    [TestCase('not comparison', '!(3 < 5),0')]
    [TestCase('and both', '2 && 1,1')]
    [TestCase('and one', '2 && 0,0')]
    [TestCase('and none', '0 && 0,0')]
    [TestCase('or one', '2 || 0,1')]
    [TestCase('or none', '0 || 0,0')]
    [TestCase('or second', '0 || 4,1')]
    [TestCase('bit and', '6 & 3,2')]
    [TestCase('bit or', '6 | 3,7')]
    [TestCase('bit xor', '6 ^ 3,5')]
    [TestCase('subtract chain', '7 - 2 - 1,4')]
    [TestCase('divide', '20 / 3,6')]
    [TestCase('modulus', '20 % 3,2')]
    [TestCase('precedence', '2 + 3 * 4,14')]
    procedure TestConstantExpressionIsFolded(const AExpression: string; AExpected: Integer);

    [Test]
    [TestCase('divide', '10 / 0')]
    [TestCase('modulus', '10 % 0')]
    [TestCase('inside', '2 + 10 / (3 - 3)')]
    procedure TestDivisionByZeroInAConstantIsAnError(const AExpression: string);
    [Test]
    procedure TestForIsReportedInsteadOfLoopingForever;
    [Test]
    procedure TestObjectStartsWithTheMagicAndTheTableOffset;
    [Test]
    procedure TestEmptyScriptBytes;
    [Test]
    procedure TestTheSameTextGivesTheSameBytesTwice;
    [Test]
    procedure TestAFailedCompileDoesNotSpoilTheNext;
    [Test]
    procedure TestNothingIsKeptBetweenScripts;
    [Test]
    procedure TestIncludeNameIsLookedUpWithoutCase;
    [Test]
    procedure TestIncludeNestingTooDeep;
    [Test]
    procedure TestObjectTooBig;
    [Test]
    procedure TestTooManyStrings;
    [Test]
    procedure TestTooManyScripts;
    [Test]
    procedure TestDeleteCharacterEndsTheText;
    [Test]
    procedure TestTheLogTellsWhatTheCompilerDid;
    [Test]
    procedure TestNoLogIsFine;
    [Test]
    procedure TestErrorInAnIncludedFileTellsThatFile;
  end;

implementation

uses
  DelphiDoom.Acs.ErrorCodes, DelphiDoom.Acs.Factory, DelphiDoom.Logging.Types,
  DelphiDoom.Logging.Factory;

{ TTestAcsCompiler }

procedure TTestAcsCompiler.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
end;

procedure TTestAcsCompiler.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
end;

function TTestAcsCompiler.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Acs\' + AFileName));
end;

function TTestAcsCompiler.ReadBytes(const AFileName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(DataPath(AFileName));
end;

function TTestAcsCompiler.TextToBytes(const AText: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AText));
  for LIndex := 1 to Length(AText) do
    Result[LIndex - 1] := Byte(Ord(AText[LIndex]));
end;

function TTestAcsCompiler.MakeCompiler(const AProvider: IAcsSourceProvider): IAcsCompiler;
var
  LProvider: IAcsSourceProvider;
begin
  LProvider := AProvider;
  if not Assigned(LProvider) then
    LProvider := TAcsFactory.CreateEmptyProvider;
  Result := TAcsFactory.CreateCompiler(LProvider,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
end;

function TTestAcsCompiler.ProviderWithTheInclude: IAcsSourceProvider;
begin
  Result := TAcsFactory.CreateMemoryProvider(['include_defs.acs'],
    [ReadBytes('include_defs.acs')]);
end;

function TTestAcsCompiler.CompileFile(const AName: string): TBytes;
begin
  Result := MakeCompiler(ProviderWithTheInclude).Compile('0', ReadBytes(AName + '.acs'));
end;

function TTestAcsCompiler.Compile(const AText: string; const AProvider: IAcsSourceProvider): TBytes;
begin
  Result := MakeCompiler(AProvider).Compile('0', TextToBytes(AText));
end;

function TTestAcsCompiler.Failure(const AText: string;
  const AProvider: IAcsSourceProvider): EAcsCompileException;
begin
  Result := nil;
  try
    Compile(AText, AProvider);
  except
    on E: EAcsCompileException do
      Result := EAcsCompileException.Create(E.Code, E.HasPosition, E.Line, E.SourceName, E.Message);
  end;
end;

function TTestAcsCompiler.LongAt(const ABytes: TBytes; AIndex: Integer): Cardinal;
begin
  Result := ABytes[AIndex] or (Cardinal(ABytes[AIndex + 1]) shl 8) or
    (Cardinal(ABytes[AIndex + 2]) shl 16) or (Cardinal(ABytes[AIndex + 3]) shl 24);
end;

procedure TTestAcsCompiler.TestSameBytesAsTheOldCompiler(const AName: string);
var
  LExpected: TBytes;
  LActual: TBytes;
begin
  LExpected := ReadBytes(AName + '.o');
  LActual := CompileFile(AName);
  Assert.AreEqual(Length(LExpected), Length(LActual), 'length of ' + AName);
  Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected)),
    'the bytes of ' + AName + ' are not the ones of the old compiler');
end;

procedure TTestAcsCompiler.TestSameErrorAsTheOldCompiler(const AName: string);
var
  LExpected: string;
  LError: EAcsCompileException;
begin
  LExpected := TFile.ReadAllText(DataPath(AName + '.err'), TEncoding.ANSI).Trim;
  LError := nil;
  try
    try
      MakeCompiler(ProviderWithTheInclude).Compile('0', ReadBytes(AName + '.acs'));
    except
      on E: EAcsCompileException do
        LError := EAcsCompileException.Create(E.Code, E.HasPosition, E.Line, E.SourceName,
          E.Message);
    end;
    Assert.IsNotNull(LError, AName + ' compiled');
    Assert.AreEqual(LExpected, LError.Message.Trim, 'the text of the error of ' + AName);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestConstantExpressionIsFolded(const AExpression: string;
  AExpected: Integer);
var
  LObject: TBytes;
begin
  // the argument after const: is a constant expression that the compiler calculates;
  // the code starts at 8 with the command, the special and then the argument
  LObject := Compile('special 70:Foldme(1);'#10'script 1 (void) { Foldme(const: ' + AExpression +
    '); }');
  Assert.AreEqual(AExpected, Integer(LongAt(LObject, 16)), AExpression);
end;

procedure TTestAcsCompiler.TestDivisionByZeroInAConstantIsAnError(const AExpression: string);
var
  LError: EAcsCompileException;
begin
  LError := Failure('special 70:Foldme(1);'#10'script 1 (void) { Foldme(const: ' + AExpression +
    '); }');
  try
    Assert.IsNotNull(LError, AExpression);
    Assert.AreEqual(ERR_DIVISION_BY_ZERO, LError.Code);
    Assert.AreEqual(2, LError.Line);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestForIsReportedInsteadOfLoopingForever;
var
  LError: EAcsCompileException;
begin
  // the old compiler looped forever on this: for is not implemented by ACC 1.10
  LError := Failure(TFile.ReadAllText(DataPath('e_for_not_supported.acs')));
  try
    Assert.IsNotNull(LError);
    Assert.AreEqual(ERR_STATEMENT_NOT_IMPLEMENTED, LError.Code);
    Assert.AreEqual(4, LError.Line);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestObjectStartsWithTheMagicAndTheTableOffset;
var
  LObject: TBytes;
begin
  LObject := CompileFile('scripts');
  Assert.AreEqual(Byte(Ord('A')), LObject[0]);
  Assert.AreEqual(Byte(Ord('C')), LObject[1]);
  Assert.AreEqual(Byte(Ord('S')), LObject[2]);
  Assert.AreEqual(Byte(0), LObject[3]);
  // the table is after the code and the strings, and has the 7 scripts
  Assert.IsTrue(LongAt(LObject, 4) > 8);
  Assert.AreEqual(Cardinal(7), LongAt(LObject, Integer(LongAt(LObject, 4))));
end;

procedure TTestAcsCompiler.TestEmptyScriptBytes;
var
  LObject: TBytes;
begin
  LObject := CompileFile('empty');
  Assert.AreEqual<Integer>(32, Length(LObject));
  Assert.AreEqual(Cardinal(12), LongAt(LObject, 4)); // the table is after the code
  Assert.AreEqual(Cardinal(1), LongAt(LObject, 8)); // terminate
  Assert.AreEqual(Cardinal(1), LongAt(LObject, 12)); // one script
  Assert.AreEqual(Cardinal(1), LongAt(LObject, 16)); // number 1
  Assert.AreEqual(Cardinal(8), LongAt(LObject, 20)); // its code is at 8
  Assert.AreEqual(Cardinal(0), LongAt(LObject, 24)); // no arguments
  Assert.AreEqual(Cardinal(0), LongAt(LObject, 28)); // no strings
end;

procedure TTestAcsCompiler.TestTheSameTextGivesTheSameBytesTwice;
var
  LCompiler: IAcsCompiler;
  LFirst: TBytes;
  LSecond: TBytes;
begin
  LCompiler := MakeCompiler(ProviderWithTheInclude);
  LFirst := LCompiler.Compile('0', ReadBytes('strings.acs'));
  LSecond := LCompiler.Compile('0', ReadBytes('strings.acs'));
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  Assert.IsTrue(CompareMem(@LFirst[0], @LSecond[0], Length(LFirst)));
end;

procedure TTestAcsCompiler.TestAFailedCompileDoesNotSpoilTheNext;
var
  LCompiler: IAcsCompiler;
  LExpected: TBytes;
  LActual: TBytes;
begin
  LCompiler := MakeCompiler(nil);
  try
    LCompiler.Compile('0', TextToBytes('script 1 (void) { nowhere = 1; }'));
  except
    on EAcsCompileException do;
  end;
  LExpected := ReadBytes('empty.o');
  LActual := LCompiler.Compile('0', ReadBytes('empty.acs'));
  Assert.AreEqual(Length(LExpected), Length(LActual));
  Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected)));
end;

procedure TTestAcsCompiler.TestNothingIsKeptBetweenScripts;
var
  LCompiler: IAcsCompiler;
  LAlone: TBytes;
  LAfter: TBytes;
  LFailed: Boolean;
begin
  LCompiler := MakeCompiler(nil);
  LCompiler.Compile('0', TextToBytes('int a; script 1 (void) { a = 1; print(s:"first"); }'));

  // the variable of the first script is not there any more
  LFailed := False;
  try
    LCompiler.Compile('0', TextToBytes('script 1 (void) { a = 1; }'));
  except
    on E: EAcsCompileException do
      LFailed := E.Code = ERR_UNKNOWN_IDENTIFIER;
  end;
  Assert.IsTrue(LFailed);

  // and the strings start again from the first
  LAlone := MakeCompiler(nil).Compile('0', TextToBytes('script 1 (void) { print(s:"second"); }'));
  LAfter := LCompiler.Compile('0', TextToBytes('script 1 (void) { print(s:"second"); }'));
  Assert.AreEqual(Length(LAlone), Length(LAfter));
  Assert.IsTrue(CompareMem(@LAlone[0], @LAfter[0], Length(LAlone)));
end;

procedure TTestAcsCompiler.TestIncludeNameIsLookedUpWithoutCase;
begin
  Assert.IsTrue(Length(Compile('#include "INCLUDE_DEFS.ACS"'#10'script 1 (void) { }',
    ProviderWithTheInclude)) > 0);
end;

procedure TTestAcsCompiler.TestIncludeNestingTooDeep;
var
  LProvider: IAcsSourceProvider;
  LError: EAcsCompileException;
begin
  LProvider := TAcsFactory.CreateMemoryProvider(['loop.acs'],
    [TextToBytes('#include "loop.acs"'#10)]);
  LError := Failure('#include "loop.acs"'#10'script 1 (void) { }', LProvider);
  try
    Assert.IsNotNull(LError);
    Assert.AreEqual(ERR_INCL_NESTING_TOO_DEEP, LError.Code);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestObjectTooBig;
var
  LText: TStringBuilder;
  LIndex: Integer;
  LError: EAcsCompileException;
begin
  LText := TStringBuilder.Create;
  try
    LText.Append('int m; script 1 (void) {');
    for LIndex := 1 to 12000 do
      LText.Append(' m = 1;');
    LText.Append(' }');
    LError := Failure(LText.ToString);
  finally
    LText.Free;
  end;
  try
    Assert.IsNotNull(LError);
    Assert.AreEqual(ERR_PCODE_BUFFER_OVERFLOW, LError.Code);
    Assert.IsFalse(LError.HasPosition);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestTooManyStrings;
var
  LText: TStringBuilder;
  LIndex: Integer;
  LError: EAcsCompileException;
begin
  LText := TStringBuilder.Create;
  try
    LText.Append('script 1 (void) {');
    for LIndex := 1 to 129 do
      LText.Append(Format(' print(s:"text%d");', [LIndex]));
    LText.Append(' }');
    LError := Failure(LText.ToString);
  finally
    LText.Free;
  end;
  try
    Assert.IsNotNull(LError);
    Assert.AreEqual(ERR_TOO_MANY_STRINGS, LError.Code);
    Assert.IsTrue(Pos('Current maximum: 128', LError.Message) > 0);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestTooManyScripts;
var
  LText: TStringBuilder;
  LIndex: Integer;
  LError: EAcsCompileException;
begin
  LText := TStringBuilder.Create;
  try
    for LIndex := 1 to 65 do
      LText.Append(Format('script %d (void) { }'#10, [LIndex]));
    LError := Failure(LText.ToString);
  finally
    LText.Free;
  end;
  try
    Assert.IsNotNull(LError);
    Assert.AreEqual(ERR_TOO_MANY_SCRIPTS, LError.Code);
  finally
    LError.Free;
  end;
end;

procedure TTestAcsCompiler.TestDeleteCharacterEndsTheText;
var
  LWith: TBytes;
  LWithout: TBytes;
begin
  LWith := Compile('script 1 (void) { }'#127'this is not read @@@');
  LWithout := Compile('script 1 (void) { }');
  Assert.AreEqual(Length(LWithout), Length(LWith));
  Assert.IsTrue(CompareMem(@LWith[0], @LWithout[0], Length(LWith)));
end;

procedure TTestAcsCompiler.TestTheLogTellsWhatTheCompilerDid;
var
  LText: string;
begin
  CompileFile('empty');
  LText := FRecorder.TextOf(TLogChannel.Output);
  Assert.IsTrue(Pos('ACC Version 1.10 by Ben Gokey', LText) > 0);
  Assert.IsTrue(Pos('Copyright (c) 1995 Raven Software, Corp.', LText) > 0);
  Assert.IsTrue(Pos('Host byte order: LITTLE endian', LText) > 0);
  Assert.IsTrue(Pos('''0'':', LText) > 0);
  Assert.IsTrue(Pos(' 1 script (0 open), 0 functions', LText) > 0);
  Assert.IsTrue(Pos('0 world variables, 0 map variables', LText) > 0);
  Assert.IsTrue(Pos('object ''0.o'': 32 bytes', LText) > 0);
end;

procedure TTestAcsCompiler.TestNoLogIsFine;
begin
  Assert.IsTrue(Length(TAcsFactory.CreateCompiler(TAcsFactory.CreateEmptyProvider, nil).Compile(
    '0', TextToBytes('script 1 (void) { }'))) > 0);
end;

procedure TTestAcsCompiler.TestErrorInAnIncludedFileTellsThatFile;
var
  LProvider: IAcsSourceProvider;
  LError: EAcsCompileException;
begin
  LProvider := TAcsFactory.CreateMemoryProvider(['bad.acs'], [TextToBytes('int m;'#10'foo'#10)]);
  LError := Failure('#include "bad.acs"'#10'script 1 (void) { }', LProvider);
  try
    Assert.IsNotNull(LError);
    Assert.AreEqual(ERR_INVALID_DECLARATOR, LError.Code);
    Assert.AreEqual('bad.acs', LError.SourceName);
    Assert.AreEqual(2, LError.Line);
  finally
    LError.Free;
  end;
end;

end.