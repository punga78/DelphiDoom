{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegLoader                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Loader;

type
  [TestFixture]
  [Category('jpeg')]
  [Category('dll')]
  TTestJpegLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;

    /// <summary>
    ///   Needs bin\Libs\DDJpeg.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDJpeg.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestBuiltLibraryEncodesAndDecodes;
  end;

implementation

uses
  DelphiDoom.Jpeg.Client;

function BuiltLibraryPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDJPEG_LIBRARY_NAME));
end;

{ TTestJpegLoader }

procedure TTestJpegLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TJpegLoader.Create('DDJpeg.nonexistent.dll').Free;
    end, EJpegException);
end;

procedure TTestJpegLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TJpegLoader;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDJpeg.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TJpegLoader.Create(LPath);
  try
    Assert.AreEqual('6b', string(AnsiString(LLoader.Jpeg.GetVersion)));
  finally
    LLoader.Free;
  end;
end;

procedure TTestJpegLoader.TestBuiltLibraryEncodesAndDecodes;
var
  LPath: string;
  LLoader: TJpegLoader;
  LClient: TJpegClient;
  LPixels: TBytes;
  LImage: TJpegImage;
  LIndex: Integer;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDJpeg.dll not built: ' + LPath);
    Exit;
  end;

  // Solid gray 16x16 image
  SetLength(LPixels, 16 * 16);
  FillChar(LPixels[0], Length(LPixels), 120);

  LLoader := TJpegLoader.Create(LPath);
  try
    LClient := TJpegClient.Create(LLoader.Jpeg);
    try
      LImage := LClient.Decode(LClient.Encode(LPixels, 16, 16, 1, 95));
      Assert.AreEqual(16, LImage.Width);
      Assert.AreEqual(16, LImage.Height);
      Assert.AreEqual(1, LImage.Components);
      for LIndex := 0 to High(LImage.Pixels) do
        Assert.IsTrue(Abs(Integer(LImage.Pixels[LIndex]) - 120) <= 3);
    finally
      // The client holds the interface of the DLL: free it before the loader
      LClient.Free;
    end;
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJpegLoader);

end.
