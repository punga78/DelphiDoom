{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the preprocessor and of the keyword tables             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Preprocessor;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Client, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor;

type
  [TestFixture]
  [Category('script')]
  TTestScriptPreprocessor = class(TObject)
  private
    FClient: TScriptClient;
    FCompiler: TScriptCompilerClient;
    FExecutor: TScriptExecutorClient;
    function CallF(const ASource: AnsiString): Int64;
    procedure AssertCompileFails(const ASource: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDefineSelectsTheBranch;
    [Test]
    procedure TestWithoutDefineTheElseBranchIsTaken;
    [Test]
    procedure TestDefineInTheSourceItself;
    [Test]
    procedure TestIncludeIsGivenByTheHost;
    [Test]
    procedure TestIncludeNameIgnoresCase;
    [Test]
    procedure TestMissingIncludeFailsTheCompilation;
    [Test]
    procedure TestInvalidDefineIsRefused;
    [Test]
    procedure TestEmptyIncludeNameIsRefused;
    [Test]
    procedure TestPreprocessorOffLeavesTheSourceAlone;
    [Test]
    procedure TestModelKeywordsCompileASimpleSource;
    [Test]
    procedure TestUnknownKeywordTableIsRefused;
  end;

implementation

uses
  DelphiDoom.Script.Engine;

const
  CRLF = #13#10;

  SOURCE_BRANCH: AnsiString =
    'program T;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin' + CRLF +
    '{$IFDEF FEATURE}' + CRLF +
    '  Result := 1;' + CRLF +
    '{$ELSE}' + CRLF +
    '  Result := 2;' + CRLF +
    '{$ENDIF}' + CRLF +
    'end;' + CRLF +
    'begin end.';

  SOURCE_INCLUDE: AnsiString =
    'program T;' + CRLF +
    '{$I values.inc}' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := K; end;' + CRLF +
    'begin end.';

{ TTestScriptPreprocessor }

procedure TTestScriptPreprocessor.Setup;
begin
  FClient := TScriptClient.Create(TScriptEngine.Create);
  FCompiler := FClient.CreateCompiler;
  FExecutor := FClient.CreateExecutor;
end;

procedure TTestScriptPreprocessor.TearDown;
begin
  FreeAndNil(FExecutor);
  FreeAndNil(FCompiler);
  FreeAndNil(FClient);
end;

function TTestScriptPreprocessor.CallF(const ASource: AnsiString): Int64;
begin
  FExecutor.Load(FCompiler.Compile(ASource));
  Result := FExecutor.Call('F', []).IntegerValue;
end;

procedure TTestScriptPreprocessor.AssertCompileFails(const ASource: AnsiString);
begin
  try
    FCompiler.Compile(ASource);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_COMPILE, E.Code);
  end;
end;

procedure TTestScriptPreprocessor.TestDefineSelectsTheBranch;
begin
  FCompiler.SetPreprocessor(True);
  FCompiler.AddDefine('Feature');
  Assert.AreEqual(Int64(1), CallF(SOURCE_BRANCH));
end;

procedure TTestScriptPreprocessor.TestWithoutDefineTheElseBranchIsTaken;
begin
  FCompiler.SetPreprocessor(True);
  Assert.AreEqual(Int64(2), CallF(SOURCE_BRANCH));
end;

procedure TTestScriptPreprocessor.TestDefineInTheSourceItself;
begin
  FCompiler.SetPreprocessor(True);
  Assert.AreEqual(Int64(1), CallF(
    'program T;' + CRLF +
    '{$DEFINE FEATURE}' + CRLF +
    'function F: Integer;' + CRLF +
    'begin' + CRLF +
    '{$IFDEF FEATURE}' + CRLF +
    '  Result := 1;' + CRLF +
    '{$ELSE}' + CRLF +
    '  Result := 2;' + CRLF +
    '{$ENDIF}' + CRLF +
    'end;' + CRLF +
    'begin end.'));
end;

procedure TTestScriptPreprocessor.TestIncludeIsGivenByTheHost;
begin
  FCompiler.SetPreprocessor(True);
  FCompiler.AddInclude('values.inc', 'const K = 7;');
  Assert.AreEqual(Int64(7), CallF(SOURCE_INCLUDE));
end;

procedure TTestScriptPreprocessor.TestIncludeNameIgnoresCase;
begin
  FCompiler.SetPreprocessor(True);
  FCompiler.AddInclude('VALUES.INC', 'const K = 9;');
  Assert.AreEqual(Int64(9), CallF(SOURCE_INCLUDE));
end;

procedure TTestScriptPreprocessor.TestMissingIncludeFailsTheCompilation;
begin
  FCompiler.SetPreprocessor(True);
  AssertCompileFails(SOURCE_INCLUDE);
  Assert.IsTrue(FCompiler.HasErrors);
end;

procedure TTestScriptPreprocessor.TestInvalidDefineIsRefused;
begin
  try
    FCompiler.AddDefine('not valid');
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, E.Code);
  end;
end;

procedure TTestScriptPreprocessor.TestEmptyIncludeNameIsRefused;
begin
  try
    FCompiler.AddInclude('', 'const K = 1;');
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, E.Code);
  end;
end;

procedure TTestScriptPreprocessor.TestPreprocessorOffLeavesTheSourceAlone;
begin
  // The include is declared but nobody asks for the preprocessor: the
  // directive stays a comment for the compiler and K is unknown
  FCompiler.AddInclude('values.inc', 'const K = 7;');
  AssertCompileFails(SOURCE_INCLUDE);
end;

procedure TTestScriptPreprocessor.TestModelKeywordsCompileASimpleSource;
var
  LCompiler: TScriptCompilerClient;
begin
  LCompiler := FClient.CreateCompiler(SCRIPT_KEYWORDS_MODEL);
  try
    // The reduced table has no PROGRAM: a model script is just var and begin
    Assert.IsTrue(Length(LCompiler.Compile(
      'var X: Integer;' + CRLF +
      'begin X := 1; end.')) > 0);
  finally
    LCompiler.Free;
  end;
end;

procedure TTestScriptPreprocessor.TestUnknownKeywordTableIsRefused;
var
  LCompiler: TScriptCompilerClient;
begin
  LCompiler := nil;
  try
    try
      LCompiler := FClient.CreateCompiler(99);
      Assert.Fail('EScriptException expected');
    except
      on E: EScriptException do
        Assert.AreEqual(SCRIPT_ERROR_ARGUMENT, E.Code);
    end;
  finally
    LCompiler.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptPreprocessor);

end.
