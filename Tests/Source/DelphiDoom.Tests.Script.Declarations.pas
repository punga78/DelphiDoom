{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the types, constants and units declared by the host    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Declarations;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Client, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor;

type
  [TestFixture]
  [Category('script')]
  TTestScriptDeclarations = class(TObject)
  private
    FClient: TScriptClient;
    FCompiler: TScriptCompilerClient;
    FExecutor: TScriptExecutorClient;
    function CallF(const ASource: AnsiString): TScriptData;
    procedure AssertCompileFails(const ASource: AnsiString);
    procedure AssertDeclarationFails(const AAction: TProc;
      AExpectedCode: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDeclaredTypeIsUsableByTheSource;
    [Test]
    procedure TestIntegerConstant;
    [Test]
    procedure TestLongWordConstantKeepsTheHighBit;
    [Test]
    procedure TestInt64Constant;
    [Test]
    procedure TestDoubleConstant;
    [Test]
    procedure TestStringConstant;
    [Test]
    procedure TestConstantOfAnotherUnitNeedsTheUsesClause;
    [Test]
    procedure TestConstantOfAnotherUnitIsVisibleWithTheUsesClause;
    [Test]
    procedure TestUnknownUnitFailsTheCompilation;
    [Test]
    procedure TestSystemIsTheDefaultUnit;
    [Test]
    procedure TestSelectUnitBackToSystem;
    [Test]
    procedure TestInvalidNamesAreRefused;
    [Test]
    procedure TestDuplicateNamesAreRefused;
    [Test]
    procedure TestEmptyTypeDefinitionIsRefused;
    [Test]
    procedure TestUnknownTypeOfAnIntegerConstantFailsTheCompilation;
    [Test]
    procedure TestClearForgetsTheDeclarations;
    [Test]
    procedure TestDeclaringAfterACompilationChangesTheNextOne;
  end;

implementation

uses
  DelphiDoom.Script.Engine;

const
  CRLF = #13#10;

{ TTestScriptDeclarations }

procedure TTestScriptDeclarations.Setup;
begin
  FClient := TScriptClient.Create(TScriptEngine.Create);
  FCompiler := FClient.CreateCompiler;
  FExecutor := FClient.CreateExecutor;
end;

procedure TTestScriptDeclarations.TearDown;
begin
  FreeAndNil(FExecutor);
  FreeAndNil(FCompiler);
  FreeAndNil(FClient);
end;

function TTestScriptDeclarations.CallF(const ASource: AnsiString): TScriptData;
begin
  FExecutor.Load(FCompiler.Compile(ASource));
  Result := FExecutor.Call('F', []);
end;

procedure TTestScriptDeclarations.AssertCompileFails(const ASource: AnsiString);
begin
  try
    FCompiler.Compile(ASource);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_COMPILE, E.Code);
  end;
end;

procedure TTestScriptDeclarations.AssertDeclarationFails(const AAction: TProc;
  AExpectedCode: Integer);
begin
  try
    AAction();
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(AExpectedCode, E.Code);
  end;
end;

procedure TTestScriptDeclarations.TestDeclaredTypeIsUsableByTheSource;
var
  LResult: TScriptData;
begin
  FCompiler.AddType('TIntegerArray', 'array of integer');
  LResult := CallF(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'var a: TIntegerArray;' + CRLF +
    'begin' + CRLF +
    '  SetLength(a, 3);' + CRLF +
    '  a[2] := 7;' + CRLF +
    '  Result := Length(a) + a[2];' + CRLF +
    'end;' + CRLF +
    'begin end.');
  Assert.AreEqual(Int64(10), LResult.IntegerValue);
end;

procedure TTestScriptDeclarations.TestIntegerConstant;
begin
  FCompiler.AddConstant('MAXHEALTH', 100);
  Assert.AreEqual(Int64(100), CallF(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := MAXHEALTH; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestLongWordConstantKeepsTheHighBit;
begin
  FCompiler.AddConstant('MF_BIG', Int64($80000000), 'longword');
  Assert.AreEqual(Int64(8), CallF(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := MF_BIG shr 28; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestInt64Constant;
begin
  FCompiler.AddConstant('HUGE', Int64(5000000000), 'int64');
  Assert.AreEqual(Int64(5000000000), CallF(
    'program T;' + CRLF +
    'function F: Int64;' + CRLF +
    'begin Result := HUGE; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestDoubleConstant;
begin
  FCompiler.AddConstant('RATIO', 6.5);
  Assert.AreEqual(6.5, CallF(
    'program T;' + CRLF +
    'function F: Double;' + CRLF +
    'begin Result := RATIO; end;' + CRLF +
    'begin end.').DoubleValue, 0.0000001);
end;

procedure TTestScriptDeclarations.TestStringConstant;
var
  LResult: TScriptData;
begin
  FCompiler.AddConstant('GREETING', AnsiString('hello'));
  LResult := CallF(
    'program T;' + CRLF +
    'function F: string;' + CRLF +
    'begin Result := GREETING + ''!''; end;' + CRLF +
    'begin end.');
  Assert.AreEqual('hello!', string(LResult.Text));
end;

procedure TTestScriptDeclarations.TestConstantOfAnotherUnitNeedsTheUsesClause;
begin
  FCompiler.SelectUnit('Extra');
  FCompiler.AddConstant('SECRET', 42);
  AssertCompileFails(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := SECRET; end;' + CRLF +
    'begin end.');
end;

procedure TTestScriptDeclarations.TestConstantOfAnotherUnitIsVisibleWithTheUsesClause;
begin
  FCompiler.SelectUnit('Extra');
  FCompiler.AddConstant('SECRET', 42);
  Assert.AreEqual(Int64(42), CallF(
    'program T;' + CRLF +
    'uses Extra;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := SECRET; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestUnknownUnitFailsTheCompilation;
begin
  AssertCompileFails(
    'program T;' + CRLF +
    'uses NoSuchUnit;' + CRLF +
    'begin end.');
end;

procedure TTestScriptDeclarations.TestSystemIsTheDefaultUnit;
begin
  // Nothing selected: the declaration is visible without a uses clause
  FCompiler.AddConstant('EVERYWHERE', 5);
  Assert.AreEqual(Int64(5), CallF(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := EVERYWHERE; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestSelectUnitBackToSystem;
begin
  FCompiler.SelectUnit('Extra');
  FCompiler.AddConstant('HIDDEN', 1);
  FCompiler.SelectUnit('system');
  FCompiler.AddConstant('SHOWN', 2);
  Assert.AreEqual(Int64(2), CallF(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := SHOWN; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestInvalidNamesAreRefused;
begin
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.SelectUnit('1Bad');
    end, SCRIPT_ERROR_ARGUMENT);
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.AddConstant('has space', 1);
    end, SCRIPT_ERROR_ARGUMENT);
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.AddConstant('', 1);
    end, SCRIPT_ERROR_ARGUMENT);
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.AddType('Bad-Name', 'integer');
    end, SCRIPT_ERROR_ARGUMENT);
end;

procedure TTestScriptDeclarations.TestDuplicateNamesAreRefused;
begin
  FCompiler.AddConstant('ONCE', 1);
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.AddConstant('once', 2);
    end, SCRIPT_ERROR_ARGUMENT);
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.AddType('ONCE', 'integer');
    end, SCRIPT_ERROR_ARGUMENT);
end;

procedure TTestScriptDeclarations.TestEmptyTypeDefinitionIsRefused;
begin
  AssertDeclarationFails(
    procedure
    begin
      FCompiler.AddType('TNothing', '   ');
    end, SCRIPT_ERROR_ARGUMENT);
end;

procedure TTestScriptDeclarations.TestUnknownTypeOfAnIntegerConstantFailsTheCompilation;
begin
  // The type is looked up when the source is compiled
  FCompiler.AddConstant('ODD', 1, 'NoSuchType');
  AssertCompileFails(
    'program T;' + CRLF +
    'begin end.');
end;

procedure TTestScriptDeclarations.TestClearForgetsTheDeclarations;
begin
  FCompiler.AddConstant('GONE', 9);
  FCompiler.ClearHostFunctions;
  AssertCompileFails(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := GONE; end;' + CRLF +
    'begin end.');
  // The name is free again
  FCompiler.AddConstant('GONE', 10);
  Assert.AreEqual(Int64(10), CallF(
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := GONE; end;' + CRLF +
    'begin end.').IntegerValue);
end;

procedure TTestScriptDeclarations.TestDeclaringAfterACompilationChangesTheNextOne;
const
  SOURCE: AnsiString =
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := LATER; end;' + CRLF +
    'begin end.';
begin
  AssertCompileFails(SOURCE);
  FCompiler.AddConstant('LATER', 3);
  Assert.AreEqual(Int64(3), CallF(SOURCE).IntegerValue);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptDeclarations);

end.
