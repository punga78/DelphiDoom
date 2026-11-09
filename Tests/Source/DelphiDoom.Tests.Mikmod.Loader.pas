{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMikModLoader                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.Loader;

{
  The tests never call IMikMod.Initialize, so the audio device is not opened
  even when the real DDMikmod.dll is loaded.
}

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.Loader, DelphiDoom.Mikmod.TrackerEngine;

type
  [TestFixture]
  [Category('mikmod')]
  [Category('dll')]
  TTestMikModLoader = class(TObject)
  public
    [Test]
    procedure TestMissingLibraryRaises;

    /// <summary>
    ///   A real DLL that is not ours: loads, but has no DDMikmodCreate
    /// </summary>
    [Test]
    procedure TestLibraryWithoutTheExportRaises;

    /// <summary>
    ///   Needs bin\Libs\DDMikmod.dll (Tools\build.bat librerie); skipped otherwise
    /// </summary>
    [Test]
    procedure TestLoadsTheBuiltLibrary;
  end;

implementation

{ TTestMikModLoader }

procedure TTestMikModLoader.TestMissingLibraryRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TMikModLoader.Create('DDMikmod.nonexistent.dll').Free;
    end, EMikModException);
end;

procedure TTestMikModLoader.TestLibraryWithoutTheExportRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TMikModLoader.Create('kernel32.dll').Free;
    end, EMikModException);
end;

procedure TTestMikModLoader.TestLoadsTheBuiltLibrary;
var
  LPath: string;
  LLoader: TMikModLoader;
  LPlayer: IMikModPlayer;
begin
  LPath := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\Libs\' + DDMIKMOD_LIBRARY_NAME));
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('DDMikmod.dll not built: ' + LPath);
    Exit;
  end;

  LLoader := TMikModLoader.Create(LPath);
  try
    Assert.AreEqual(Integer(TRACKER_VERSION), Integer(LLoader.MikMod.GetVersion));
    Assert.IsFalse(LLoader.MikMod.IsInitialized);
    Assert.AreEqual(MIKMOD_ERR_NOT_INITIALIZED,
      LLoader.MikMod.CreatePlayer(LPlayer));
    Assert.IsFalse(Assigned(LPlayer));
  finally
    LLoader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMikModLoader);

end.
