{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the client classes of the Script library              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Client;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Client, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor;

type
  [TestFixture]
  [Category('script')]
  TTestScriptClient = class(TObject)
  private
    FClient: TScriptClient;
    FCompiler: TScriptCompilerClient;
    FExecutor: TScriptExecutorClient;
    procedure DeclareHostFunctions;
    procedure LoadSource(const ASource: AnsiString);
    procedure AssertCompileFails(const ASource: AnsiString);
    procedure AssertCallRaises(const AName: AnsiString;
      const AArguments: array of TScriptData; AExpectedCode: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutLibraryRaises;
    [Test]
    procedure TestCompileAndCallSum;
    [Test]
    procedure TestCompileSuccessHasNoErrors;
    [Test]
    procedure TestCompileErrorRaisesAndKeepsTheMessages;
    [Test]
    procedure TestCompileErrorReportsTheRow;
    [Test]
    procedure TestCompileEmptySourceRaises;
    [Test]
    procedure TestCompileLargeSource;
    [Test]
    procedure TestCallDouble;
    [Test]
    procedure TestCallText;
    [Test]
    procedure TestCallLongTextUsesTheSecondFetch;
    [Test]
    procedure TestTextKeepsEveryByte;
    [Test]
    procedure TestCallProcedureReturnsNone;
    [Test]
    procedure TestCallUnknownRaisesNotFound;
    [Test]
    procedure TestCallWithWrongArgumentsRaisesType;
    [Test]
    procedure TestRuntimeErrorRaisesWithText;
    [Test]
    procedure TestLoadWithoutHostFunctionRaises;
    [Test]
    procedure TestHostFunctionCalledByTheScript;
    [Test]
    procedure TestHostFunctionWithStringAndStdcall;
    [Test]
    procedure TestGlobalIntegers;
    [Test]
    procedure TestGlobalUnknownRaisesNotFound;
    [Test]
    procedure TestRecompileAfterClearingHostFunctions;
  end;

implementation

uses
  DelphiDoom.Script.Engine, DelphiDoom.Tests.Script.Samples;

{ TTestScriptClient }

procedure TTestScriptClient.Setup;
begin
  FClient := TScriptClient.Create(TScriptEngine.Create);
  FCompiler := FClient.CreateCompiler;
  FExecutor := FClient.CreateExecutor;
end;

procedure TTestScriptClient.TearDown;
begin
  FreeAndNil(FExecutor);
  FreeAndNil(FCompiler);
  FreeAndNil(FClient);
end;

procedure TTestScriptClient.DeclareHostFunctions;
begin
  FCompiler.AddHostFunction(DECLARATION_HOST_DOUBLE);
  FCompiler.AddHostFunction(DECLARATION_HOST_LENGTH);
  FCompiler.AddHostFunction(DECLARATION_HOST_ADDSTD);
  FExecutor.AddHostFunction(DECLARATION_HOST_DOUBLE, @HostDouble);
  FExecutor.AddHostFunction(DECLARATION_HOST_LENGTH, @HostLength);
  FExecutor.AddHostFunction(DECLARATION_HOST_ADDSTD, @HostAddStd,
    SCRIPT_CALL_STDCALL);
end;

procedure TTestScriptClient.LoadSource(const ASource: AnsiString);
begin
  FExecutor.Load(FCompiler.Compile(ASource));
end;

procedure TTestScriptClient.AssertCompileFails(const ASource: AnsiString);
begin
  try
    FCompiler.Compile(ASource);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_COMPILE, E.Code);
  end;
end;

procedure TTestScriptClient.AssertCallRaises(const AName: AnsiString;
  const AArguments: array of TScriptData; AExpectedCode: Integer);
begin
  try
    FExecutor.Call(AName, AArguments);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(AExpectedCode, E.Code);
  end;
end;

procedure TTestScriptClient.TestCreateWithoutLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestScriptClient.TestCompileAndCallSum;
var
  LResult: TScriptData;
begin
  LoadSource(SOURCE_SUM);
  LResult := FExecutor.Call('Somma',
    [TScriptData.FromInteger(3), TScriptData.FromInteger(4)]);
  Assert.AreEqual(SCRIPT_VALUE_INTEGER, LResult.Kind);
  Assert.AreEqual(Int64(7), LResult.IntegerValue);
end;

procedure TTestScriptClient.TestCompileSuccessHasNoErrors;
begin
  FCompiler.Compile(SOURCE_SUM);
  Assert.IsFalse(FCompiler.HasErrors);
end;

procedure TTestScriptClient.TestCompileErrorRaisesAndKeepsTheMessages;
begin
  AssertCompileFails(SOURCE_UNKNOWN_IDENTIFIER);
  Assert.IsTrue(FCompiler.HasErrors);
  Assert.IsTrue(Length(FCompiler.Messages) >= 1);
  Assert.IsTrue(FCompiler.Messages[0].Kind = TScriptMessageKind.Error);
  Assert.IsTrue(Length(FCompiler.Messages[0].Text) > 0, 'the text of the error');
end;

procedure TTestScriptClient.TestCompileErrorReportsTheRow;
begin
  AssertCompileFails(SOURCE_UNKNOWN_IDENTIFIER);
  Assert.AreEqual(3, Integer(FCompiler.Messages[0].Row));
  Assert.IsTrue(FCompiler.Messages[0].Col >= 1);
  Assert.IsTrue(FCompiler.Messages[0].Position > 0);
end;

procedure TTestScriptClient.TestCompileEmptySourceRaises;
begin
  try
    FCompiler.Compile('');
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, E.Code);
  end;
end;

procedure TTestScriptClient.TestCompileLargeSource;
var
  LSource: AnsiString;
  LIndex: Integer;
  LResult: TScriptData;
begin
  // A source with many procedures, so that the bytecode is not small
  LSource := 'program Large;' + #13#10;
  for LIndex := 1 to 300 do
    LSource := LSource + 'function F' + AnsiString(IntToStr(LIndex)) +
      '(a: Integer): Integer;' + #13#10 + 'begin' + #13#10 +
      '  Result := a + ' + AnsiString(IntToStr(LIndex)) + ';' + #13#10 +
      'end;' + #13#10;
  LSource := LSource + 'begin' + #13#10 + 'end.';

  LoadSource(LSource);
  LResult := FExecutor.Call('F300', [TScriptData.FromInteger(1)]);
  Assert.AreEqual(Int64(301), LResult.IntegerValue);
end;

procedure TTestScriptClient.TestCallDouble;
var
  LResult: TScriptData;
begin
  LoadSource(SOURCE_RICH);
  LResult := FExecutor.Call('Media',
    [TScriptData.FromDouble(3.0), TScriptData.FromDouble(4.0)]);
  Assert.AreEqual(SCRIPT_VALUE_DOUBLE, LResult.Kind);
  Assert.AreEqual(3.5, LResult.DoubleValue, 0.0000001);
end;

procedure TTestScriptClient.TestCallText;
var
  LResult: TScriptData;
begin
  LoadSource(SOURCE_RICH);
  LResult := FExecutor.Call('Unisci',
    [TScriptData.FromText('foo'), TScriptData.FromText('bar')]);
  Assert.AreEqual(SCRIPT_VALUE_TEXT, LResult.Kind);
  Assert.AreEqual('foobar', string(LResult.Text));
end;

procedure TTestScriptClient.TestCallLongTextUsesTheSecondFetch;
var
  LFirst: AnsiString;
  LSecond: AnsiString;
  LResult: TScriptData;
begin
  // 600 bytes do not fit the first buffer of the client: the call runs once
  // and the text is fetched afterwards
  LoadSource(SOURCE_RICH);
  LFirst := AnsiString(StringOfChar('a', 300));
  LSecond := AnsiString(StringOfChar('b', 300));
  LResult := FExecutor.Call('Unisci',
    [TScriptData.FromText(LFirst), TScriptData.FromText(LSecond)]);
  Assert.AreEqual(600, Length(LResult.Text));
  Assert.IsTrue(LResult.Text = LFirst + LSecond);
end;

procedure TTestScriptClient.TestTextKeepsEveryByte;
var
  LFirst: AnsiString;
  LSecond: AnsiString;
  LResult: TScriptData;
begin
  // Bytes above 127 must not be changed by any conversion
  LoadSource(SOURCE_RICH);
  SetLength(LFirst, 2);
  LFirst[1] := AnsiChar($E8);
  LFirst[2] := AnsiChar($FF);
  SetLength(LSecond, 1);
  LSecond[1] := AnsiChar($80);
  LResult := FExecutor.Call('Unisci',
    [TScriptData.FromText(LFirst), TScriptData.FromText(LSecond)]);
  Assert.AreEqual(3, Length(LResult.Text));
  Assert.AreEqual($E8, Integer(Ord(LResult.Text[1])));
  Assert.AreEqual($FF, Integer(Ord(LResult.Text[2])));
  Assert.AreEqual($80, Integer(Ord(LResult.Text[3])));
end;

procedure TTestScriptClient.TestCallProcedureReturnsNone;
var
  LResult: TScriptData;
begin
  LoadSource(SOURCE_RICH);
  LResult := FExecutor.Call('Incrementa', []);
  Assert.AreEqual(SCRIPT_VALUE_NONE, LResult.Kind);
end;

procedure TTestScriptClient.TestCallUnknownRaisesNotFound;
begin
  LoadSource(SOURCE_SUM);
  AssertCallRaises('NonEsiste', [], SCRIPT_ERROR_NOTFOUND);
end;

procedure TTestScriptClient.TestCallWithWrongArgumentsRaisesType;
begin
  LoadSource(SOURCE_SUM);
  AssertCallRaises('Somma', [TScriptData.FromInteger(1)], SCRIPT_ERROR_TYPE);
  AssertCallRaises('Somma', [TScriptData.FromText('x'),
    TScriptData.FromInteger(1)], SCRIPT_ERROR_TYPE);
  AssertCallRaises('Somma', [TScriptData.FromInteger(1),
    TScriptData.FromInteger(2), TScriptData.FromInteger(3)], SCRIPT_ERROR_TYPE);
end;

procedure TTestScriptClient.TestRuntimeErrorRaisesWithText;
begin
  LoadSource(SOURCE_RICH);
  try
    FExecutor.Call('Dividi', [TScriptData.FromInteger(1),
      TScriptData.FromInteger(0)]);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
    begin
      Assert.AreEqual(SCRIPT_ERROR_RUNTIME, E.Code);
      // The message carries the text of the interpreter
      Assert.IsTrue(Pos('(', E.Message) > 0, E.Message);
    end;
  end;
end;

procedure TTestScriptClient.TestLoadWithoutHostFunctionRaises;
var
  LBytecode: TBytes;
begin
  FCompiler.AddHostFunction(DECLARATION_HOST_DOUBLE);
  FCompiler.AddHostFunction(DECLARATION_HOST_LENGTH);
  FCompiler.AddHostFunction(DECLARATION_HOST_ADDSTD);
  LBytecode := FCompiler.Compile(SOURCE_HOST);
  try
    FExecutor.Load(LBytecode);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_LOAD, E.Code);
  end;
end;

procedure TTestScriptClient.TestHostFunctionCalledByTheScript;
var
  LResult: TScriptData;
begin
  DeclareHostFunctions;
  LoadSource(SOURCE_HOST);
  LResult := FExecutor.Call('Raddoppia', [TScriptData.FromInteger(20)]);
  Assert.AreEqual(Int64(41), LResult.IntegerValue);
end;

procedure TTestScriptClient.TestHostFunctionWithStringAndStdcall;
var
  LResult: TScriptData;
begin
  DeclareHostFunctions;
  LoadSource(SOURCE_HOST);
  LResult := FExecutor.Call('Lunghezza', [TScriptData.FromText('hello world')]);
  Assert.AreEqual(Int64(11), LResult.IntegerValue, 'string parameter');
  LResult := FExecutor.Call('SommaStd',
    [TScriptData.FromInteger(100), TScriptData.FromInteger(200)]);
  Assert.AreEqual(Int64(300), LResult.IntegerValue, 'stdcall');
end;

procedure TTestScriptClient.TestGlobalIntegers;
begin
  LoadSource(SOURCE_RICH);
  FExecutor.RunMain;
  Assert.AreEqual(Int64(10), FExecutor.GetGlobalInteger('Counter'));
  Assert.AreEqual(Int64(5), FExecutor.GetGlobalInteger('Total'));

  FExecutor.Call('Incrementa', []);
  Assert.AreEqual(Int64(11), FExecutor.GetGlobalInteger('Counter'));

  FExecutor.SetGlobalInteger('Counter', 100);
  Assert.AreEqual(Int64(100), FExecutor.GetGlobalInteger('Counter'));
  Assert.AreEqual(Int64(5), FExecutor.GetGlobalInteger('Total'));
end;

procedure TTestScriptClient.TestGlobalUnknownRaisesNotFound;
begin
  LoadSource(SOURCE_RICH);
  try
    FExecutor.GetGlobalInteger('Nope');
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_NOTFOUND, E.Code);
  end;
end;

procedure TTestScriptClient.TestRecompileAfterClearingHostFunctions;
begin
  // With the declarations the source compiles, without them it does not
  FCompiler.AddHostFunction(DECLARATION_HOST_DOUBLE);
  FCompiler.AddHostFunction(DECLARATION_HOST_LENGTH);
  FCompiler.AddHostFunction(DECLARATION_HOST_ADDSTD);
  FCompiler.Compile(SOURCE_HOST);

  FCompiler.ClearHostFunctions;
  AssertCompileFails(SOURCE_HOST);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptClient);

end.
