{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TZlibLoader                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf,
  DelphiDoom.Zlib.Loader;

type
  [TestFixture]
  [Category('zlib')]
  [Category('dll')]
  TTestZlibLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;

    /// <summary>
    ///   Needs bin\Libs\DDZlib.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;
  end;

implementation

{ TTestZlibLoader }

procedure TTestZlibLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TZlibLoader.Create('DDZlib.nonexistent.dll').Free;
    end, EZlibException);
end;

procedure TTestZlibLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TZlibLoader;
begin
  LPath := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDZLIB_LIBRARY_NAME));
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDZlib.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TZlibLoader.Create(LPath);
  try
    Assert.AreEqual('1.2.8', string(AnsiString(LLoader.Zlib.GetVersion)));
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibLoader);

end.
