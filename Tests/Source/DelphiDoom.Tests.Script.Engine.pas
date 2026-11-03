{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Script engine through its raw interfaces           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf;

type
  [TestFixture]
  [Category('script')]
  TTestScriptEngine = class(TObject)
  private
    FLibrary: IScriptLibrary;
    FCompiler: IScriptCompiler;
    FExecutor: IScriptExecutor;
    function Compile(const ASource: AnsiString): TBytes;
    procedure LoadSource(const ASource: AnsiString);
    function CallIntegers(const AName: AnsiString; const AValues: array of Int64): Int64;
    procedure CallWithoutArguments(const AName: AnsiString);
    function LastErrorText: AnsiString;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCompileRejectsEmptySource;
    [Test]
    procedure TestCompileReportsTheSizeWhenTheBufferIsMissing;
    [Test]
    procedure TestCompileReportsTheSizeWhenTheBufferIsTooSmall;
    [Test]
    procedure TestCompileFillsTheBuffer;
    [Test]
    procedure TestCompileErrorGivesMessageWithPosition;
    [Test]
    procedure TestMessageTextBufferTooSmall;
    [Test]
    procedure TestMessageOutOfRange;
    [Test]
    procedure TestCompileDoesNotDependOnTheTerminator;

    [Test]
    procedure TestCallBeforeLoadFails;
    [Test]
    procedure TestLoadRejectsGarbage;
    [Test]
    procedure TestCallInteger;
    [Test]
    procedure TestCallDouble;
    [Test]
    procedure TestCallTextWithRoomForTheResult;
    [Test]
    procedure TestCallTextWithoutRoomKeepsTheResult;
    [Test]
    procedure TestCallUnknownProcedure;
    [Test]
    procedure TestCallWithWrongArgumentCount;
    [Test]
    procedure TestCallWithWrongArgumentType;
    [Test]
    procedure TestCallIsCaseInsensitive;
    [Test]
    procedure TestRuntimeErrorIsReported;

    [Test]
    procedure TestHostFunctionRegisterConvention;
    [Test]
    procedure TestHostFunctionStdcallConvention;
    [Test]
    procedure TestHostFunctionWithStringParameter;
    [Test]
    procedure TestMissingHostFunctionFailsTheLoad;
    [Test]
    procedure TestAddHostFunctionValidation;
    [Test]
    procedure TestAddHostFunctionAfterLoadFails;

    [Test]
    procedure TestGlobalIntegers;
    [Test]
    procedure TestGlobalUnknown;
  end;

implementation

uses
  DelphiDoom.Script.Engine, DelphiDoom.Tests.Script.Samples;

{ TTestScriptEngine }

procedure TTestScriptEngine.Setup;
begin
  FLibrary := TScriptEngine.Create;
  Assert.AreEqual(SCRIPT_OK, FLibrary.CreateCompiler(FCompiler));
  Assert.AreEqual(SCRIPT_OK, FLibrary.CreateExecutor(FExecutor));
end;

procedure TTestScriptEngine.TearDown;
begin
  FExecutor := nil;
  FCompiler := nil;
  FLibrary := nil;
end;

function TTestScriptEngine.Compile(const ASource: AnsiString): TBytes;
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

procedure TTestScriptEngine.LoadSource(const ASource: AnsiString);
var
  LBytecode: TBytes;
begin
  LBytecode := Compile(ASource);
  Assert.AreEqual(SCRIPT_OK,
    FExecutor.LoadBytecode(Pointer(LBytecode), Length(LBytecode)));
end;

function TTestScriptEngine.CallIntegers(const AName: AnsiString;
  const AValues: array of Int64): Int64;
var
  LArguments: TArray<TScriptValue>;
  LResult: TScriptValue;
  LIndex: Integer;
begin
  SetLength(LArguments, Length(AValues));
  for LIndex := 0 to High(AValues) do
  begin
    LArguments[LIndex].Kind := SCRIPT_VALUE_INTEGER;
    LArguments[LIndex].TextSize := 0;
    LArguments[LIndex].IntegerValue := AValues[LIndex];
    LArguments[LIndex].DoubleValue := 0;
    LArguments[LIndex].Text := nil;
  end;
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_OK, FExecutor.CallProcedure(PAnsiChar(AName),
    PScriptValue(LArguments), Length(LArguments), LResult));
  Assert.AreEqual(SCRIPT_VALUE_INTEGER, LResult.Kind);
  Result := LResult.IntegerValue;
end;

procedure TTestScriptEngine.CallWithoutArguments(const AName: AnsiString);
var
  LResult: TScriptValue;
begin
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_OK, FExecutor.CallProcedure(PAnsiChar(AName), nil, 0, LResult));
  Assert.AreEqual(SCRIPT_VALUE_NONE, LResult.Kind, 'a procedure has no result');
end;

function TTestScriptEngine.LastErrorText: AnsiString;
var
  LSize: Cardinal;
begin
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER, FExecutor.GetLastErrorText(nil, LSize));
  SetLength(Result, LSize);
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetLastErrorText(PAnsiChar(Result), LSize));
  SetLength(Result, LSize - 1);
end;

procedure TTestScriptEngine.TestCompileRejectsEmptySource;
var
  LSize: Cardinal;
begin
  LSize := 100;
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.Compile(nil, 10, nil, LSize));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FCompiler.Compile(Pointer(SOURCE_SUM), 0, nil, LSize));
end;

procedure TTestScriptEngine.TestCompileReportsTheSizeWhenTheBufferIsMissing;
var
  LSize: Cardinal;
begin
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER,
    FCompiler.Compile(Pointer(SOURCE_SUM), Length(SOURCE_SUM), nil, LSize));
  Assert.IsTrue(LSize > 0, 'the size needed must be reported');
end;

procedure TTestScriptEngine.TestCompileReportsTheSizeWhenTheBufferIsTooSmall;
var
  LSize: Cardinal;
  LNeeded: Cardinal;
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 4);
  LSize := 4;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER,
    FCompiler.Compile(Pointer(SOURCE_SUM), Length(SOURCE_SUM), Pointer(LBuffer), LSize));
  Assert.IsTrue(LSize > 4);
  LNeeded := LSize;

  // The second call, with the same source, receives the code already compiled
  SetLength(LBuffer, LNeeded);
  Assert.AreEqual(SCRIPT_OK,
    FCompiler.Compile(Pointer(SOURCE_SUM), Length(SOURCE_SUM), Pointer(LBuffer), LSize));
  Assert.AreEqual(Integer(LNeeded), Integer(LSize));
end;

procedure TTestScriptEngine.TestCompileFillsTheBuffer;
var
  LBytecode: TBytes;
  LTotal: Integer;
  LIndex: Integer;
begin
  LBytecode := Compile(SOURCE_SUM);
  Assert.IsTrue(Length(LBytecode) > 16);
  // Not an empty buffer
  LTotal := 0;
  for LIndex := 0 to High(LBytecode) do
    LTotal := LTotal or LBytecode[LIndex];
  Assert.AreNotEqual(0, LTotal);
end;

procedure TTestScriptEngine.TestCompileErrorGivesMessageWithPosition;
var
  LSize: Cardinal;
  LCount: Cardinal;
  LInfo: TScriptMessageInfo;
  LText: AnsiString;
  LTextSize: Cardinal;
  LBuffer: array[0..15] of Byte;
begin
  LSize := SizeOf(LBuffer);
  Assert.AreEqual(SCRIPT_ERROR_COMPILE,
    FCompiler.Compile(Pointer(SOURCE_UNKNOWN_IDENTIFIER),
      Length(SOURCE_UNKNOWN_IDENTIFIER), @LBuffer[0], LSize));

  Assert.AreEqual(SCRIPT_OK, FCompiler.GetMessageCount(LCount));
  Assert.IsTrue(LCount >= 1, 'at least one message expected');

  SetLength(LText, 512);
  LTextSize := Length(LText);
  Assert.AreEqual(SCRIPT_OK,
    FCompiler.GetMessageInfo(0, LInfo, PAnsiChar(LText), LTextSize));
  Assert.AreEqual(SCRIPT_MESSAGE_ERROR, LInfo.Kind);
  Assert.AreEqual(3, Integer(LInfo.Row), 'the error is on the third line');
  Assert.IsTrue(LInfo.Col >= 1);
  Assert.IsTrue(LInfo.Position > 0);
  Assert.IsTrue(LTextSize > 1, 'the text of the error must not be empty');
  Assert.AreEqual(0, Integer(Ord(LText[LTextSize])), 'the text is zero terminated');
end;

procedure TTestScriptEngine.TestMessageTextBufferTooSmall;
var
  LSize: Cardinal;
  LInfo: TScriptMessageInfo;
  LTextSize: Cardinal;
  LBuffer: array[0..15] of Byte;
  LTiny: array[0..0] of AnsiChar;
begin
  LSize := SizeOf(LBuffer);
  FCompiler.Compile(Pointer(SOURCE_UNKNOWN_IDENTIFIER),
    Length(SOURCE_UNKNOWN_IDENTIFIER), @LBuffer[0], LSize);

  LTextSize := 1;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER,
    FCompiler.GetMessageInfo(0, LInfo, @LTiny[0], LTextSize));
  Assert.IsTrue(LTextSize > 1, 'the size needed must be reported');
  // The position is reported anyway
  Assert.AreEqual(3, Integer(LInfo.Row));
end;

procedure TTestScriptEngine.TestMessageOutOfRange;
var
  LInfo: TScriptMessageInfo;
  LTextSize: Cardinal;
begin
  LTextSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FCompiler.GetMessageInfo(0, LInfo, nil, LTextSize));
end;

procedure TTestScriptEngine.TestCompileDoesNotDependOnTheTerminator;
var
  LSource: TBytes;
  LSize: Cardinal;
begin
  // A buffer that is not zero terminated and has bytes after the source
  SetLength(LSource, Length(SOURCE_SUM) + 8);
  FillChar(Pointer(LSource)^, Length(LSource), Ord('x'));
  Move(Pointer(SOURCE_SUM)^, Pointer(LSource)^, Length(SOURCE_SUM));
  LSize := 0;
  Assert.AreEqual(SCRIPT_ERROR_BUFFER,
    FCompiler.Compile(Pointer(LSource), Length(SOURCE_SUM), nil, LSize));
  Assert.IsTrue(LSize > 0);
end;

procedure TTestScriptEngine.TestCallBeforeLoadFails;
var
  LResult: TScriptValue;
begin
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_ERROR_STATE,
    FExecutor.CallProcedure('Somma', nil, 0, LResult));
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.RunMain);
end;

procedure TTestScriptEngine.TestLoadRejectsGarbage;
var
  LGarbage: TBytes;
  LIndex: Integer;
begin
  SetLength(LGarbage, 64);
  for LIndex := 0 to High(LGarbage) do
    LGarbage[LIndex] := Byte(LIndex * 7 + 3);
  Assert.AreEqual(SCRIPT_ERROR_LOAD,
    FExecutor.LoadBytecode(Pointer(LGarbage), Length(LGarbage)));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.LoadBytecode(nil, 10));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.LoadBytecode(Pointer(LGarbage), 0));
end;

procedure TTestScriptEngine.TestCallInteger;
begin
  LoadSource(SOURCE_SUM);
  Assert.AreEqual(Int64(7), CallIntegers('Somma', [3, 4]));
  Assert.AreEqual(Int64(-1), CallIntegers('Somma', [10, -11]));
  Assert.AreEqual(Int64(2147483647), CallIntegers('Somma', [2147483646, 1]));
end;

procedure TTestScriptEngine.TestCallDouble;
var
  LArguments: array[0..1] of TScriptValue;
  LResult: TScriptValue;
begin
  LoadSource(SOURCE_RICH);
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_DOUBLE;
  LArguments[0].DoubleValue := 3.0;
  LArguments[1].Kind := SCRIPT_VALUE_DOUBLE;
  LArguments[1].DoubleValue := 4.0;
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_OK,
    FExecutor.CallProcedure('Media', @LArguments[0], 2, LResult));
  Assert.AreEqual(SCRIPT_VALUE_DOUBLE, LResult.Kind);
  Assert.AreEqual(3.5, LResult.DoubleValue, 0.0000001);
end;

procedure TTestScriptEngine.TestCallTextWithRoomForTheResult;
var
  LFirst: AnsiString;
  LSecond: AnsiString;
  LArguments: array[0..1] of TScriptValue;
  LResult: TScriptValue;
  LBuffer: array[0..31] of AnsiChar;
begin
  LoadSource(SOURCE_RICH);
  LFirst := 'foo';
  LSecond := 'bar';
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_TEXT;
  LArguments[0].Text := PAnsiChar(LFirst);
  LArguments[1].Kind := SCRIPT_VALUE_TEXT;
  LArguments[1].Text := PAnsiChar(LSecond);
  FillChar(LResult, SizeOf(LResult), 0);
  LResult.Text := @LBuffer[0];
  LResult.TextSize := SizeOf(LBuffer);

  Assert.AreEqual(SCRIPT_OK,
    FExecutor.CallProcedure('Unisci', @LArguments[0], 2, LResult));
  Assert.AreEqual(SCRIPT_VALUE_TEXT, LResult.Kind);
  Assert.AreEqual(7, Integer(LResult.TextSize), 'six characters and the terminator');
  Assert.AreEqual('foobar', string(AnsiString(PAnsiChar(@LBuffer[0]))));
end;

procedure TTestScriptEngine.TestCallTextWithoutRoomKeepsTheResult;
var
  LFirst: AnsiString;
  LSecond: AnsiString;
  LArguments: array[0..1] of TScriptValue;
  LResult: TScriptValue;
  LBuffer: array[0..2] of AnsiChar;
  LText: AnsiString;
  LSize: Cardinal;
begin
  LoadSource(SOURCE_RICH);
  LFirst := 'foo';
  LSecond := 'bar';
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_TEXT;
  LArguments[0].Text := PAnsiChar(LFirst);
  LArguments[1].Kind := SCRIPT_VALUE_TEXT;
  LArguments[1].Text := PAnsiChar(LSecond);
  FillChar(LResult, SizeOf(LResult), 0);
  LResult.Text := @LBuffer[0];
  LResult.TextSize := SizeOf(LBuffer);

  // The procedure runs; the text does not fit and is kept
  Assert.AreEqual(SCRIPT_ERROR_BUFFER,
    FExecutor.CallProcedure('Unisci', @LArguments[0], 2, LResult));
  Assert.AreEqual(SCRIPT_VALUE_TEXT, LResult.Kind);
  Assert.AreEqual(7, Integer(LResult.TextSize));

  SetLength(LText, LResult.TextSize);
  LSize := LResult.TextSize;
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetResultText(PAnsiChar(LText), LSize));
  Assert.AreEqual('foobar', string(AnsiString(PAnsiChar(LText))));
end;

procedure TTestScriptEngine.TestCallUnknownProcedure;
var
  LResult: TScriptValue;
begin
  LoadSource(SOURCE_SUM);
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_ERROR_NOTFOUND,
    FExecutor.CallProcedure('NonEsiste', nil, 0, LResult));
end;

procedure TTestScriptEngine.TestCallWithWrongArgumentCount;
var
  LArguments: array[0..0] of TScriptValue;
  LResult: TScriptValue;
begin
  LoadSource(SOURCE_SUM);
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_INTEGER;
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_ERROR_TYPE,
    FExecutor.CallProcedure('Somma', @LArguments[0], 1, LResult), 'too few');
  Assert.AreEqual(SCRIPT_ERROR_TYPE,
    FExecutor.CallProcedure('Somma', nil, 0, LResult), 'none');
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FExecutor.CallProcedure('Somma', nil, 2, LResult), 'nil array');
end;

procedure TTestScriptEngine.TestCallWithWrongArgumentType;
var
  LArguments: array[0..1] of TScriptValue;
  LText: AnsiString;
  LResult: TScriptValue;
begin
  LoadSource(SOURCE_SUM);
  LText := 'abc';
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_TEXT;
  LArguments[0].Text := PAnsiChar(LText);
  LArguments[1].Kind := SCRIPT_VALUE_INTEGER;
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_ERROR_TYPE,
    FExecutor.CallProcedure('Somma', @LArguments[0], 2, LResult));

  LArguments[0].Kind := 99;
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FExecutor.CallProcedure('Somma', @LArguments[0], 2, LResult), 'unknown kind');
end;

procedure TTestScriptEngine.TestCallIsCaseInsensitive;
begin
  LoadSource(SOURCE_SUM);
  Assert.AreEqual(Int64(9), CallIntegers('SOMMA', [4, 5]));
  Assert.AreEqual(Int64(9), CallIntegers('somma', [4, 5]));
end;

procedure TTestScriptEngine.TestRuntimeErrorIsReported;
var
  LArguments: array[0..1] of TScriptValue;
  LResult: TScriptValue;
begin
  LoadSource(SOURCE_RICH);
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_INTEGER;
  LArguments[0].IntegerValue := 1;
  LArguments[1].Kind := SCRIPT_VALUE_INTEGER;
  LArguments[1].IntegerValue := 0;
  FillChar(LResult, SizeOf(LResult), 0);

  Assert.AreEqual(SCRIPT_ERROR_RUNTIME,
    FExecutor.CallProcedure('Dividi', @LArguments[0], 2, LResult));
  Assert.IsTrue(Length(LastErrorText) > 0, 'the error must have a text');
end;

procedure TTestScriptEngine.TestHostFunctionRegisterConvention;
begin
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE)));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_LENGTH)));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_ADDSTD)));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble, SCRIPT_CALL_REGISTER));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_LENGTH), @HostLength, SCRIPT_CALL_REGISTER));
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_ADDSTD), @HostAddStd, SCRIPT_CALL_STDCALL));
  LoadSource(SOURCE_HOST);

  Assert.AreEqual(Int64(41), CallIntegers('Raddoppia', [20]), 'Raddoppia(20)');
end;

procedure TTestScriptEngine.TestHostFunctionStdcallConvention;
begin
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE));
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_LENGTH));
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_ADDSTD));
  FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble,
    SCRIPT_CALL_REGISTER);
  FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_LENGTH), @HostLength,
    SCRIPT_CALL_REGISTER);
  FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_ADDSTD), @HostAddStd,
    SCRIPT_CALL_STDCALL);
  LoadSource(SOURCE_HOST);

  Assert.AreEqual(Int64(300), CallIntegers('SommaStd', [100, 200]));
end;

procedure TTestScriptEngine.TestHostFunctionWithStringParameter;
var
  LText: AnsiString;
  LArguments: array[0..0] of TScriptValue;
  LResult: TScriptValue;
begin
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE));
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_LENGTH));
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_ADDSTD));
  FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble,
    SCRIPT_CALL_REGISTER);
  FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_LENGTH), @HostLength,
    SCRIPT_CALL_REGISTER);
  FExecutor.AddHostFunction(PAnsiChar(DECLARATION_HOST_ADDSTD), @HostAddStd,
    SCRIPT_CALL_STDCALL);
  LoadSource(SOURCE_HOST);

  LText := 'hello world';
  FillChar(LArguments, SizeOf(LArguments), 0);
  LArguments[0].Kind := SCRIPT_VALUE_TEXT;
  LArguments[0].Text := PAnsiChar(LText);
  FillChar(LResult, SizeOf(LResult), 0);
  Assert.AreEqual(SCRIPT_OK,
    FExecutor.CallProcedure('Lunghezza', @LArguments[0], 1, LResult));
  Assert.AreEqual(Int64(11), LResult.IntegerValue);
end;

procedure TTestScriptEngine.TestMissingHostFunctionFailsTheLoad;
var
  LBytecode: TBytes;
begin
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE));
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_LENGTH));
  FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_ADDSTD));
  LBytecode := Compile(SOURCE_HOST);

  // The executor does not know the functions the bytecode imports
  Assert.AreEqual(SCRIPT_ERROR_LOAD,
    FExecutor.LoadBytecode(Pointer(LBytecode), Length(LBytecode)));
  Assert.IsTrue(Length(LastErrorText) > 0, 'the load error must have a text');
end;

procedure TTestScriptEngine.TestAddHostFunctionValidation;
begin
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddHostFunction(nil));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddHostFunction('x := 1;'));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FCompiler.AddHostFunction('function (a: Integer);'));
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE)));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT,
    FCompiler.AddHostFunction('function HOSTDOUBLE(a: Integer): Integer;'), 'duplicate');
  Assert.AreEqual(SCRIPT_OK, FCompiler.ClearHostFunctions);
  Assert.AreEqual(SCRIPT_OK, FCompiler.AddHostFunction(PAnsiChar(DECLARATION_HOST_DOUBLE)));

  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_DOUBLE), nil, SCRIPT_CALL_REGISTER), 'nil address');
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble, 77), 'unknown convention');
  Assert.AreEqual(SCRIPT_OK, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble, SCRIPT_CALL_REGISTER));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble, SCRIPT_CALL_REGISTER), 'duplicate');
end;

procedure TTestScriptEngine.TestAddHostFunctionAfterLoadFails;
begin
  LoadSource(SOURCE_SUM);
  Assert.AreEqual(SCRIPT_ERROR_STATE, FExecutor.AddHostFunction(
    PAnsiChar(DECLARATION_HOST_DOUBLE), @HostDouble, SCRIPT_CALL_REGISTER));
end;

procedure TTestScriptEngine.TestGlobalIntegers;
var
  LValue: Int64;
begin
  LoadSource(SOURCE_RICH);
  Assert.AreEqual(SCRIPT_OK, FExecutor.RunMain);

  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInteger('Counter', LValue));
  Assert.AreEqual(Int64(10), LValue, 'initialized by the main block');
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInteger('TOTAL', LValue));
  Assert.AreEqual(Int64(5), LValue, 'second variable');

  CallWithoutArguments('Incrementa');
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInteger('Counter', LValue));
  Assert.AreEqual(Int64(11), LValue, 'changed by the script');

  Assert.AreEqual(SCRIPT_OK, FExecutor.SetGlobalInteger('Counter', 100));
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInteger('Counter', LValue));
  Assert.AreEqual(Int64(100), LValue, 'changed by the host');
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInteger('Total', LValue));
  Assert.AreEqual(Int64(5), LValue, 'the other variable is untouched');

  CallWithoutArguments('Incrementa');
  Assert.AreEqual(SCRIPT_OK, FExecutor.GetGlobalInteger('Counter', LValue));
  Assert.AreEqual(Int64(101), LValue, 'the script continues from the value of the host');
end;

procedure TTestScriptEngine.TestGlobalUnknown;
var
  LValue: Int64;
begin
  LoadSource(SOURCE_RICH);
  Assert.AreEqual(SCRIPT_ERROR_NOTFOUND, FExecutor.GetGlobalInteger('Nope', LValue));
  Assert.AreEqual(SCRIPT_ERROR_NOTFOUND, FExecutor.SetGlobalInteger('Nope', 1));
  Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, FExecutor.GetGlobalInteger(nil, LValue));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptEngine);

end.
