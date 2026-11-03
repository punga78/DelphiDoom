{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGlbspLoader                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Loader;

{
  The tests never run glbsp, even when the real DDGlbsp.dll is loaded: they
  only create the IGlbsp and call methods that stop before the process.
}

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Glbsp.Intf, DelphiDoom.Glbsp.Loader;

type
  [TestFixture]
  [Category('glbsp')]
  [Category('dll')]
  TTestGlbspLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;

    /// <summary>
    ///   A real DLL that is not ours: loads, but has no DDGlbspCreate
    /// </summary>
    [Test]
    procedure TestLibraryWithoutTheExportRaises;

    [Test]
    procedure TestMissingLibraryReportsLoadLibraryCode;

    /// <summary>
    ///   Needs bin\Libs\DDGlbsp.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;
  end;

implementation

{ TTestGlbspLoader }

procedure TTestGlbspLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspLoader.Create('DDGlbsp.nonexistent.dll').Free;
    end, EGlbspException);
end;

procedure TTestGlbspLoader.TestLibraryWithoutTheExportRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspLoader.Create('kernel32.dll').Free;
    end, EGlbspException);
end;

procedure TTestGlbspLoader.TestMissingLibraryReportsLoadLibraryCode;
begin
  try
    TGlbspLoader.Create('DDGlbsp.nonexistent.dll').Free;
    Assert.Fail('EGlbspException expected');
  except
    on E: EGlbspException do
      Assert.AreEqual(GLBSP_ERR_LOAD_LIBRARY, E.Code);
  end;
end;

procedure TTestGlbspLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TGlbspLoader;
  LGlbsp: IGlbsp;
begin
  LPath := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDGLBSP_LIBRARY_NAME));
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDGlbsp.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TGlbspLoader.Create(LPath);
  try
    // A local interface, released before the DLL is unloaded: a temporary
    // made by the compiler for LLoader.Glbsp would be released too late
    LGlbsp := LLoader.Glbsp;
    try
      Assert.IsTrue(Assigned(LGlbsp));
      Assert.AreEqual(57404, Integer(LGlbsp.GetExecutableSize));
      // Stops at the validation: no process is started
      Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
        LGlbsp.BuildNodes(nil, nil, GLBSP_OPT_NONE, GLBSP_DEFAULT_TIMEOUT_MS));
    finally
      LGlbsp := nil;
    end;
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspLoader);

end.
