{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMp3Loader                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Mp3.Intf,
  DelphiDoom.Mp3.Loader;

type
  [TestFixture]
  [Category('mp3')]
  [Category('dll')]
  TTestMp3Loader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;
    [Test]
    procedure DovrebbeRifiutareUnaLibreriaSenzaLExport;

    /// <summary>
    ///   Needs bin\Libs\DDMp3.dll (build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDMp3.dll (build.bat librerie); skipped otherwise.
    ///   Decodes silent frames through the DLL
    /// </summary>
    [Test]
    procedure TestDecodesThroughTheBuiltLibrary;
  end;

implementation

uses
  DelphiDoom.Mp3.Client, DelphiDoom.Tests.Mp3.Samples;

function BuiltLibraryPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDMP3_LIBRARY_NAME));
end;

{ TTestMp3Loader }

procedure TTestMp3Loader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TMp3Loader.Create('DDMp3.nonexistent.dll').Free;
    end, EMp3Exception);
end;

procedure TTestMp3Loader.DovrebbeRifiutareUnaLibreriaSenzaLExport;
begin
  // a library of the system: it loads, but it does not export DDMp3Create
  Assert.WillRaise(
    procedure
    begin
      TMp3Loader.Create('kernel32.dll').Free;
    end, EMp3Exception);
end;

procedure TTestMp3Loader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TMp3Loader;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDMp3.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TMp3Loader.Create(LPath);
  try
    Assert.AreEqual(string(AnsiString(DDMP3_VERSION_TEXT)),
      string(AnsiString(LLoader.Mp3.GetVersion)));
  finally
    LLoader.Free;
  end;
end;

procedure TTestMp3Loader.TestDecodesThroughTheBuiltLibrary;
var
  LPath: string;
  LLoader: TMp3Loader;
  LClient: TMp3Client;
  LPcm: TBytes;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDMp3.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TMp3Loader.Create(LPath);
  try
    // The client (and its decoder) must go before the loader
    LClient := TMp3Client.Create(LLoader.Mp3);
    try
      LPcm := LClient.DecodeAll(TMp3Samples.SilentStream(3));
      Assert.AreEqual(3 * SAMPLE_MONO_PCM_BYTES, Length(LPcm));
      Assert.AreEqual(SAMPLE_FREQUENCY, Integer(LClient.Frequency));
    finally
      LClient.Free;
    end;
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMp3Loader);

end.
