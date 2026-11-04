{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the global variables and of the events of the script   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Globals;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Client, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor;

type
  [TestFixture]
  [Category('script')]
  TTestScriptGlobals = class(TObject)
  private
    FClient: TScriptClient;
    FCompiler: TScriptCompilerClient;
    FExecutor: TScriptExecutorClient;
    procedure LoadAndRun(const ASource: AnsiString);
    function IndexOfGlobal(const AName: AnsiString): Integer;
    procedure AssertGlobalCode(AExpected: Integer; const AAction: TProc);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGlobalCountAndNames;
    [Test]
    procedure TestGlobalKinds;
    [Test]
    procedure TestGlobalInfoOutOfRangeRaises;
    [Test]
    procedure TestDoubleGlobal;
    [Test]
    procedure TestSetDoubleGlobal;
    [Test]
    procedure TestTextGlobal;
    [Test]
    procedure TestSetTextGlobal;
    [Test]
    procedure TestLongTextGlobalUsesTheSecondFetch;
    [Test]
    procedure TestWrongKindRaisesTypeError;
    [Test]
    procedure TestUnknownGlobalRaisesNotFound;
    [Test]
    procedure TestRunLineHandlerIsCalled;
    [Test]
    procedure TestRunLineHandlerCanBeRemoved;
    [Test]
    procedure TestExceptionHandlerIsCalled;
    [Test]
    procedure TestHandlersSurviveANewLoad;
  end;

implementation

uses
  DelphiDoom.Script.Engine, DelphiDoom.Tests.Script.Samples;

const
  CRLF = #13#10;

  SOURCE_GLOBALS: AnsiString =
    'program G;' + CRLF +
    'var' + CRLF +
    '  Count: Integer;' + CRLF +
    '  Ratio: Double;' + CRLF +
    '  Name: string;' + CRLF +
    'begin' + CRLF +
    '  Count := 3;' + CRLF +
    '  Ratio := 1.5;' + CRLF +
    '  Name := ''abc'';' + CRLF +
    'end.';

  SOURCE_LOOP: AnsiString =
    'program L;' + CRLF +
    'function F: Integer;' + CRLF +
    'var i: Integer;' + CRLF +
    'begin' + CRLF +
    '  Result := 0;' + CRLF +
    '  for i := 1 to 3 do' + CRLF +
    '    Result := Result + i;' + CRLF +
    'end;' + CRLF +
    'begin end.';

var
  GRunLineCount: Integer;
  GExceptionCount: Integer;
  GExceptionCode: Integer;
  GLastUserData: Pointer;

procedure CountRunLine(AUserData: Pointer); stdcall;
begin
  Inc(GRunLineCount);
  GLastUserData := AUserData;
end;

procedure CountException(AUserData: Pointer; ACode: Integer; AProcedure,
  APosition: Cardinal); stdcall;
begin
  Inc(GExceptionCount);
  GExceptionCode := ACode;
  GLastUserData := AUserData;
end;

{ TTestScriptGlobals }

procedure TTestScriptGlobals.Setup;
begin
  GRunLineCount := 0;
  GExceptionCount := 0;
  GExceptionCode := 0;
  GLastUserData := nil;
  FClient := TScriptClient.Create(TScriptEngine.Create);
  FCompiler := FClient.CreateCompiler;
  FExecutor := FClient.CreateExecutor;
end;

procedure TTestScriptGlobals.TearDown;
begin
  FreeAndNil(FExecutor);
  FreeAndNil(FCompiler);
  FreeAndNil(FClient);
end;

procedure TTestScriptGlobals.LoadAndRun(const ASource: AnsiString);
begin
  FExecutor.Load(FCompiler.Compile(ASource));
  FExecutor.RunMain;
end;

function TTestScriptGlobals.IndexOfGlobal(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FExecutor.GlobalCount - 1 do
    if string(FExecutor.GlobalName(LIndex)) = UpperCase(AName) then
      Exit(LIndex);

  Result := -1;
end;

procedure TTestScriptGlobals.AssertGlobalCode(AExpected: Integer;
  const AAction: TProc);
begin
  try
    AAction();
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(AExpected, E.Code);
  end;
end;

procedure TTestScriptGlobals.TestGlobalCountAndNames;
begin
  LoadAndRun(SOURCE_GLOBALS);
  Assert.AreEqual(3, FExecutor.GlobalCount);
  Assert.AreEqual('COUNT', string(FExecutor.GlobalName(0)));
  Assert.AreEqual('RATIO', string(FExecutor.GlobalName(1)));
  Assert.AreEqual('NAME', string(FExecutor.GlobalName(2)));
end;

procedure TTestScriptGlobals.TestGlobalKinds;
begin
  LoadAndRun(SOURCE_GLOBALS);
  Assert.AreEqual(SCRIPT_GLOBAL_INTEGER, FExecutor.GlobalKind(IndexOfGlobal('Count')));
  Assert.AreEqual(SCRIPT_GLOBAL_DOUBLE, FExecutor.GlobalKind(IndexOfGlobal('Ratio')));
  Assert.AreEqual(SCRIPT_GLOBAL_TEXT, FExecutor.GlobalKind(IndexOfGlobal('Name')));
end;

procedure TTestScriptGlobals.TestGlobalInfoOutOfRangeRaises;
begin
  LoadAndRun(SOURCE_GLOBALS);
  AssertGlobalCode(SCRIPT_ERROR_NOTFOUND,
    procedure
    begin
      FExecutor.GlobalName(99);
    end);
end;

procedure TTestScriptGlobals.TestDoubleGlobal;
begin
  LoadAndRun(SOURCE_GLOBALS);
  Assert.AreEqual(1.5, FExecutor.GetGlobalDouble('Ratio'), 0.0000001);
end;

procedure TTestScriptGlobals.TestSetDoubleGlobal;
begin
  LoadAndRun(SOURCE_GLOBALS);
  FExecutor.SetGlobalDouble('Ratio', 7.25);
  Assert.AreEqual(7.25, FExecutor.GetGlobalDouble('Ratio'), 0.0000001);
end;

procedure TTestScriptGlobals.TestTextGlobal;
begin
  LoadAndRun(SOURCE_GLOBALS);
  Assert.AreEqual('abc', string(FExecutor.GetGlobalText('Name')));
end;

procedure TTestScriptGlobals.TestSetTextGlobal;
begin
  LoadAndRun(SOURCE_GLOBALS);
  FExecutor.SetGlobalText('Name', 'changed');
  Assert.AreEqual('changed', string(FExecutor.GetGlobalText('Name')));
end;

procedure TTestScriptGlobals.TestLongTextGlobalUsesTheSecondFetch;
var
  LText: AnsiString;
begin
  LoadAndRun(SOURCE_GLOBALS);
  LText := AnsiString(StringOfChar('x', 1000));
  FExecutor.SetGlobalText('Name', LText);
  Assert.AreEqual(1000, Length(FExecutor.GetGlobalText('Name')));
end;

procedure TTestScriptGlobals.TestWrongKindRaisesTypeError;
begin
  LoadAndRun(SOURCE_GLOBALS);
  AssertGlobalCode(SCRIPT_ERROR_TYPE,
    procedure
    begin
      FExecutor.GetGlobalDouble('Name');
    end);
  AssertGlobalCode(SCRIPT_ERROR_TYPE,
    procedure
    begin
      FExecutor.GetGlobalText('Count');
    end);
  AssertGlobalCode(SCRIPT_ERROR_TYPE,
    procedure
    begin
      FExecutor.SetGlobalDouble('Count', 1.0);
    end);
end;

procedure TTestScriptGlobals.TestUnknownGlobalRaisesNotFound;
begin
  LoadAndRun(SOURCE_GLOBALS);
  AssertGlobalCode(SCRIPT_ERROR_NOTFOUND,
    procedure
    begin
      FExecutor.GetGlobalDouble('NoSuchGlobal');
    end);
  AssertGlobalCode(SCRIPT_ERROR_NOTFOUND,
    procedure
    begin
      FExecutor.SetGlobalText('NoSuchGlobal', 'x');
    end);
end;

procedure TTestScriptGlobals.TestRunLineHandlerIsCalled;
begin
  FExecutor.SetEventHandlers(CountRunLine, nil, Pointer(1234));
  LoadAndRun(SOURCE_LOOP);
  FExecutor.Call('F', []);
  Assert.IsTrue(GRunLineCount > 0, 'the handler ran');
  Assert.IsTrue(GLastUserData = Pointer(1234), 'the user data reaches the handler');
end;

procedure TTestScriptGlobals.TestRunLineHandlerCanBeRemoved;
begin
  FExecutor.SetEventHandlers(CountRunLine, nil, nil);
  LoadAndRun(SOURCE_LOOP);
  FExecutor.SetEventHandlers(nil, nil, nil);
  GRunLineCount := 0;
  FExecutor.Call('F', []);
  Assert.AreEqual(0, GRunLineCount);
end;

procedure TTestScriptGlobals.TestExceptionHandlerIsCalled;
begin
  FExecutor.SetEventHandlers(nil, CountException, nil);
  LoadAndRun(SOURCE_RICH);
  try
    FExecutor.Call('Dividi',
      [TScriptData.FromInteger(1), TScriptData.FromInteger(0)]);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_RUNTIME, E.Code);
  end;
  Assert.AreEqual(1, GExceptionCount);
  Assert.IsTrue(GExceptionCode <> 0, 'the interpreter error number is given');
end;

procedure TTestScriptGlobals.TestHandlersSurviveANewLoad;
begin
  FExecutor.SetEventHandlers(CountRunLine, nil, nil);
  LoadAndRun(SOURCE_LOOP);
  LoadAndRun(SOURCE_LOOP);
  GRunLineCount := 0;
  FExecutor.Call('F', []);
  Assert.IsTrue(GRunLineCount > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptGlobals);

end.
