{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiLoader                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Loader;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Intf,
  DelphiDoom.Xmi.Loader;

type
  [TestFixture]
  [Category('xmi')]
  [Category('dll')]
  TTestXmiLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;
    [Test]
    procedure DovrebbeRifiutareUnaLibreriaSenzaLExport;

    /// <summary>
    ///   Needs bin\Libs\DDXmi.dll (Tools\build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;

    /// <summary>
    ///   Needs bin\Libs\DDXmi.dll (Tools\build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestConvertsThroughTheBuiltLibrary;
  end;

implementation

uses
  DelphiDoom.Xmi.Client, DelphiDoom.Tests.Xmi.Samples;

function BuiltLibraryPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDXMI_LIBRARY_NAME));
end;

{ TTestXmiLoader }

procedure TTestXmiLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiLoader.Create('DDXmi.nonexistent.dll').Free;
    end, EXmiException);
end;

// kernel32.dll is always there, and it does not export DDXmiCreate: the loader
// raises, and its destructor unloads the library it had loaded
procedure TTestXmiLoader.DovrebbeRifiutareUnaLibreriaSenzaLExport;
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiLoader.Create('kernel32.dll').Free;
    end, EXmiException);
end;

procedure TTestXmiLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TXmiLoader;
  LSample: TBytes;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDXmi.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TXmiLoader.Create(LPath);
  try
    LSample := TXmiSamples.BuildXmi;
    Assert.AreEqual(Ord(TXmiFormat.Xmi),
      LLoader.Xmi.DetectFormat(Pointer(LSample), Length(LSample)));
  finally
    LLoader.Free;
  end;
end;

procedure TTestXmiLoader.TestConvertsThroughTheBuiltLibrary;
var
  LPath: string;
  LLoader: TXmiLoader;
  LClient: TXmiClient;
  LMidi: TBytes;
begin
  LPath := BuiltLibraryPath;
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDXmi.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TXmiLoader.Create(LPath);
  try
    // The client must go before the loader: its IXmi lives inside the DLL
    LClient := TXmiClient.Create(LLoader.Xmi);
    try
      LMidi := LClient.ConvertToMidi(TXmiSamples.BuildXmi);
    finally
      LClient.Free;
    end;
    Assert.AreEqual('MThd', TXmiSamples.TagAt(LMidi, 0));
    Assert.AreEqual('MTrk', TXmiSamples.TagAt(LMidi, 14));
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiLoader);

end.
