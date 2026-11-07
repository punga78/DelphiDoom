{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScriptLoader                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Loader;

type
  [TestFixture]
  [Category('script')]
  [Category('dll')]
  TTestScriptLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;

    /// <summary>
    ///   A DLL that exists but is not DDScript (kernel32.dll): the export is missing
    /// </summary>
    [Test]
    procedure DovrebbeRifiutareUnaDllSenzaLaFunzioneDiCreazione;

    /// <summary>
    ///   Needs bin\Libs\DDScript.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDScript.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestCompilesAndRunsThroughTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDScript.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestHostFunctionAcrossTheBuiltLibrary;
  end;

implementation

uses
  DelphiDoom.Script.Client, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor, DelphiDoom.Tests.Script.Samples;

function BuiltLibraryPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDSCRIPT_LIBRARY_NAME));
end;

{ TTestScriptLoader }

procedure TTestScriptLoader.DovrebbeRifiutareUnaDllSenzaLaFunzioneDiCreazione;
var
  LMessage: string;
begin
  LMessage := '';
  try
    TScriptLoader.Create('kernel32.dll').Free;
  except
    on E: EScriptException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(Pos(DDSCRIPT_CREATE_EXPORT, LMessage) > 0, 'the message names the export: ' + LMessage);
end;

procedure TTestScriptLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptLoader.Create('DDScript.nonexistent.dll').Free;
    end, EScriptException);
end;

procedure TTestScriptLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TScriptLoader;
  LCompiler: IScriptCompiler;
  LExecutor: IScriptExecutor;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDScript.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TScriptLoader.Create(LPath);
  try
    Assert.AreEqual(SCRIPT_OK, LLoader.ScriptLibrary.CreateCompiler(LCompiler));
    Assert.AreEqual(SCRIPT_OK, LLoader.ScriptLibrary.CreateExecutor(LExecutor));
    Assert.IsTrue(Assigned(LCompiler));
    Assert.IsTrue(Assigned(LExecutor));
    // The interfaces live in the DLL: release them before unloading it
    LCompiler := nil;
    LExecutor := nil;
  finally
    LLoader.Free;
  end;
end;

procedure TTestScriptLoader.TestCompilesAndRunsThroughTheBuiltLibrary;
var
  LPath: string;
  LLoader: TScriptLoader;
  LClient: TScriptClient;
  LCompiler: TScriptCompilerClient;
  LExecutor: TScriptExecutorClient;
  LResult: TScriptData;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDScript.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TScriptLoader.Create(LPath);
  try
    LClient := TScriptClient.Create(LLoader.ScriptLibrary);
    try
      LCompiler := LClient.CreateCompiler;
      LExecutor := LClient.CreateExecutor;
      try
        LExecutor.Load(LCompiler.Compile(SOURCE_SUM));
        LResult := LExecutor.Call('Somma',
          [TScriptData.FromInteger(3), TScriptData.FromInteger(4)]);
        Assert.AreEqual(Int64(7), LResult.IntegerValue);
      finally
        // The clients must go before the loader: their interfaces live in
        // the DLL
        LExecutor.Free;
        LCompiler.Free;
      end;
    finally
      LClient.Free;
    end;
  finally
    LLoader.Free;
  end;
end;

procedure TTestScriptLoader.TestHostFunctionAcrossTheBuiltLibrary;
var
  LPath: string;
  LLoader: TScriptLoader;
  LClient: TScriptClient;
  LCompiler: TScriptCompilerClient;
  LExecutor: TScriptExecutorClient;
  LResult: TScriptData;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDScript.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TScriptLoader.Create(LPath);
  try
    LClient := TScriptClient.Create(LLoader.ScriptLibrary);
    try
      LCompiler := LClient.CreateCompiler;
      LExecutor := LClient.CreateExecutor;
      try
        // Functions of this executable called by the script inside the DLL:
        // the string parameter is only read, so no memory crosses the two
        // memory managers
        LCompiler.AddHostFunction(DECLARATION_HOST_DOUBLE);
        LCompiler.AddHostFunction(DECLARATION_HOST_LENGTH);
        LCompiler.AddHostFunction(DECLARATION_HOST_ADDSTD);
        LExecutor.AddHostFunction(DECLARATION_HOST_DOUBLE, @HostDouble);
        LExecutor.AddHostFunction(DECLARATION_HOST_LENGTH, @HostLength);
        LExecutor.AddHostFunction(DECLARATION_HOST_ADDSTD, @HostAddStd,
          SCRIPT_CALL_STDCALL);
        LExecutor.Load(LCompiler.Compile(SOURCE_HOST));

        LResult := LExecutor.Call('Raddoppia', [TScriptData.FromInteger(20)]);
        Assert.AreEqual(Int64(41), LResult.IntegerValue, 'register');
        LResult := LExecutor.Call('Lunghezza', [TScriptData.FromText('abcdef')]);
        Assert.AreEqual(Int64(6), LResult.IntegerValue, 'string');
        LResult := LExecutor.Call('SommaStd',
          [TScriptData.FromInteger(1), TScriptData.FromInteger(2)]);
        Assert.AreEqual(Int64(3), LResult.IntegerValue, 'stdcall');
      finally
        LExecutor.Free;
        LCompiler.Free;
      end;
    finally
      LClient.Free;
    end;
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptLoader);

end.
