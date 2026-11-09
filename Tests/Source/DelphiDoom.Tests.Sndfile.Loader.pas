{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSndfileLoader                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sndfile.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf,
  DelphiDoom.Sndfile.Loader;

type
  [TestFixture]
  [Category('sndfile')]
  [Category('dll')]
  TTestSndfileLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;
    [Test]
    procedure TestUnaLibreriaSenzaLExportSollevaUnaEccezione;

    /// <summary>
    ///   Needs bin\Libs\DDSndfile.dll (Tools\build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDSndfile.dll (Tools\build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestOpensASoundThroughTheBuiltLibrary;
  end;

implementation

uses
  DelphiDoom.Tests.Sndfile.Wav;

function BuiltLibraryPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDSNDFILE_LIBRARY_NAME));
end;

{ TTestSndfileLoader }

procedure TTestSndfileLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TSndfileLoader.Create('DDSndfile.nonexistent.dll').Free;
    end, ESndfileException);
end;

procedure TTestSndfileLoader.TestUnaLibreriaSenzaLExportSollevaUnaEccezione;
begin
  // kernel32 is always there and does not export DDSndfileCreate
  Assert.WillRaiseWithMessage(
    procedure
    begin
      TSndfileLoader.Create('kernel32.dll').Free;
    end, ESndfileException, 'kernel32.dll does not export ' + DDSNDFILE_CREATE_EXPORT);
end;

procedure TTestSndfileLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TSndfileLoader;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDSndfile.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TSndfileLoader.Create(LPath);
  try
    Assert.IsTrue(Length(string(AnsiString(LLoader.Sndfile.GetVersion))) > 0);
  finally
    LLoader.Free;
  end;
end;

procedure TTestSndfileLoader.TestOpensASoundThroughTheBuiltLibrary;
var
  LPath: string;
  LLoader: TSndfileLoader;
  LSource: TBytes;
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
  LBuffer: array of SmallInt;
  LFramesRead: Int64;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDSndfile.dll not built: ' + LPath);
    Exit;
  end;

  LSource := TSndfileTestWav.MakePcm16(1, 11025, [5, 10, 15, 20]);
  LLoader := TSndfileLoader.Create(LPath);
  try
    try
      Assert.AreEqual(SNDFILE_OK, LLoader.Sndfile.OpenMemory(Pointer(LSource),
        Length(LSource), LSound));
      Assert.AreEqual(SNDFILE_OK, LSound.GetInfo(LInfo));
      Assert.AreEqual(4, Integer(LInfo.Frames));

      SetLength(LBuffer, 4);
      Assert.AreEqual(SNDFILE_OK, LSound.ReadShort(@LBuffer[0], 4, LFramesRead));
      Assert.AreEqual(4, Integer(LFramesRead));
      Assert.AreEqual(15, Integer(LBuffer[2]));
    finally
      // The code of the sound lives in the DLL: release it before unloading
      LSound := nil;
    end;
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSndfileLoader);

end.
