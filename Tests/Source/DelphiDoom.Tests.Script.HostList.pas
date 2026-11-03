{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScriptHostList                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.HostList;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Client, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor, DelphiDoom.Script.Client.HostList;

type
  [TestFixture]
  [Category('script')]
  TTestScriptHostList = class(TObject)
  private
    FClient: TScriptClient;
    FCompiler: TScriptCompilerClient;
    FExecutor: TScriptExecutorClient;
    FList: TScriptHostList;
    procedure FillList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAddKeepsTheFunctions;
    [Test]
    procedure TestDefaultConventionIsRegister;
    [Test]
    procedure TestDeclareAndRegisterLetTheScriptCallTheFunctions;
    [Test]
    procedure TestEmptyDeclarationRaises;
    [Test]
    procedure TestNilAddressRaises;
    [Test]
    procedure TestDeclareWithoutRegisterFailsTheLoad;
    [Test]
    procedure TestDeclaredInTheSelectedUnit;
  end;

implementation

uses
  DelphiDoom.Script.Engine, DelphiDoom.Tests.Script.Samples;

const
  CRLF = #13#10;

{ TTestScriptHostList }

procedure TTestScriptHostList.Setup;
begin
  FClient := TScriptClient.Create(TScriptEngine.Create);
  FCompiler := FClient.CreateCompiler;
  FExecutor := FClient.CreateExecutor;
  FList := TScriptHostList.Create;
end;

procedure TTestScriptHostList.TearDown;
begin
  FreeAndNil(FList);
  FreeAndNil(FExecutor);
  FreeAndNil(FCompiler);
  FreeAndNil(FClient);
end;

procedure TTestScriptHostList.FillList;
begin
  FList.Add(DECLARATION_HOST_DOUBLE, @HostDouble);
  FList.Add(DECLARATION_HOST_LENGTH, @HostLength);
  FList.Add(DECLARATION_HOST_ADDSTD, @HostAddStd, SCRIPT_CALL_STDCALL);
end;

procedure TTestScriptHostList.TestAddKeepsTheFunctions;
begin
  FillList;
  Assert.AreEqual(3, FList.Count);
  Assert.AreEqual(string(DECLARATION_HOST_LENGTH), string(FList[1].Declaration));
  Assert.IsTrue(FList[0].Address = @HostDouble);
end;

procedure TTestScriptHostList.TestDefaultConventionIsRegister;
begin
  FillList;
  Assert.AreEqual(SCRIPT_CALL_REGISTER, FList[0].Convention);
  Assert.AreEqual(SCRIPT_CALL_STDCALL, FList[2].Convention);
end;

procedure TTestScriptHostList.TestDeclareAndRegisterLetTheScriptCallTheFunctions;
var
  LResult: TScriptData;
begin
  FillList;
  FList.Declare(FCompiler);
  FList.Register(FExecutor);
  FExecutor.Load(FCompiler.Compile(SOURCE_HOST));
  LResult := FExecutor.Call('Raddoppia', [TScriptData.FromInteger(20)]);
  Assert.AreEqual(Int64(41), LResult.IntegerValue);
  LResult := FExecutor.Call('SommaStd',
    [TScriptData.FromInteger(3), TScriptData.FromInteger(4)]);
  Assert.AreEqual(Int64(7), LResult.IntegerValue);
end;

procedure TTestScriptHostList.TestEmptyDeclarationRaises;
begin
  try
    FList.Add('', @HostDouble);
    Assert.Fail('EArgumentException expected');
  except
    on EArgumentException do
      Assert.AreEqual(0, FList.Count);
  end;
end;

procedure TTestScriptHostList.TestNilAddressRaises;
begin
  try
    FList.Add(DECLARATION_HOST_DOUBLE, nil);
    Assert.Fail('EArgumentNilException expected');
  except
    on EArgumentNilException do
      Assert.AreEqual(0, FList.Count);
  end;
end;

procedure TTestScriptHostList.TestDeclareWithoutRegisterFailsTheLoad;
var
  LBytecode: TBytes;
begin
  FillList;
  FList.Declare(FCompiler);
  LBytecode := FCompiler.Compile(SOURCE_HOST);
  try
    FExecutor.Load(LBytecode);
    Assert.Fail('EScriptException expected');
  except
    on E: EScriptException do
      Assert.AreEqual(SCRIPT_ERROR_LOAD, E.Code);
  end;
end;

procedure TTestScriptHostList.TestDeclaredInTheSelectedUnit;
var
  LResult: TScriptData;
begin
  FillList;
  FCompiler.SelectUnit('Host');
  FList.Declare(FCompiler);
  FList.Register(FExecutor);
  FExecutor.Load(FCompiler.Compile(
    'program T;' + CRLF +
    'uses Host;' + CRLF +
    'function F: Integer;' + CRLF +
    'begin Result := HostDouble(21); end;' + CRLF +
    'begin end.'));
  LResult := FExecutor.Call('F', []);
  Assert.AreEqual(Int64(42), LResult.IntegerValue);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostList);

end.
