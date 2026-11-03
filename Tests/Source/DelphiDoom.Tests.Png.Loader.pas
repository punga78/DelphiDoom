{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TPngLoader                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf,
  DelphiDoom.Png.Intf, DelphiDoom.Png.Loader;

type
  [TestFixture]
  [Category('png')]
  [Category('dll')]
  TTestPngLoader = class(TObject)
  private
    function BuiltPngPath: string;
    function BuiltZlibPath: string;
  public
    [Test]
    procedure TestMissingLibraryRaises;
    [Test]
    procedure TestLoaderWithoutZlibRaises;

    /// <summary>
    ///   Needs bin\Libs\DDPng.dll (build.bat librerie); skipped otherwise.
    ///   The zlib is the one linked in the test executable
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDPng.dll and bin\Libs\DDZlib.dll; skipped otherwise.
    ///   Both libraries are DLLs: the PNG DLL compresses with the code of the
    ///   zlib DLL
    /// </summary>
    [Test]
    procedure TestBuiltLibraryWorksWithTheZlibDll;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine, DelphiDoom.Zlib.Loader, DelphiDoom.Png.Client,
  DelphiDoom.Tests.Png.Samples;

{ TTestPngLoader }

function TTestPngLoader.BuiltPngPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDPNG_LIBRARY_NAME));
end;

function TTestPngLoader.BuiltZlibPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDZLIB_LIBRARY_NAME));
end;

procedure TTestPngLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TPngLoader.Create(TZlibEngine.Create, 'DDPng.nonexistent.dll').Free;
    end, EPngException);
end;

procedure TTestPngLoader.TestLoaderWithoutZlibRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TPngLoader.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestPngLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TPngLoader;
  LClient: TPngClient;
  LPixels: TBytes;
  LImage: TPngImage;
  LIndex: Integer;
begin
  LPath := BuiltPngPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDPng.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TPngLoader.Create(TZlibEngine.Create, LPath);
  try
    LClient := TPngClient.Create(LLoader.Png);
    try
      Assert.AreEqual('DDPng 1.0', LClient.Version);

      LPixels := TPngSamples.Noise(24 * 16 * 4, 77);
      LImage := LClient.Decode(LClient.Encode(LPixels, 24, 16));
      Assert.AreEqual(24, LImage.Info.Width);
      Assert.AreEqual(16, LImage.Info.Height);
      for LIndex := 0 to High(LPixels) do
        if LPixels[LIndex] <> LImage.Pixels[LIndex] then
          Assert.Fail(Format('byte %d differs', [LIndex]));
    finally
      // The client holds the interface of the DLL: free it before the loader
      LClient.Free;
    end;
  finally
    LLoader.Free;
  end;
end;

procedure TTestPngLoader.TestBuiltLibraryWorksWithTheZlibDll;
var
  LZlibLoader: TZlibLoader;
  LPngLoader: TPngLoader;
  LClient: TPngClient;
  LPixels: TBytes;
  LImage: TPngImage;
  LIndex: Integer;
begin
  if not TFile.Exists(BuiltPngPath) or not TFile.Exists(BuiltZlibPath) then
  begin
    Assert.Pass('DDPng.dll or DDZlib.dll not built');
    Exit;
  end;

  // Release in the reverse order of creation: the PNG code uses the zlib code
  LZlibLoader := TZlibLoader.Create(BuiltZlibPath);
  try
    LPngLoader := TPngLoader.Create(LZlibLoader.Zlib, BuiltPngPath);
    try
      LClient := TPngClient.Create(LPngLoader.Png);
      try
        LPixels := TPngSamples.Noise(40 * 30 * 4, 78);
        LImage := LClient.Decode(LClient.Encode(LPixels, 40, 30));
        for LIndex := 0 to High(LPixels) do
          if LPixels[LIndex] <> LImage.Pixels[LIndex] then
            Assert.Fail(Format('byte %d differs', [LIndex]));
      finally
        LClient.Free;
      end;
    finally
      LPngLoader.Free;
    end;
  finally
    LZlibLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPngLoader);

end.
