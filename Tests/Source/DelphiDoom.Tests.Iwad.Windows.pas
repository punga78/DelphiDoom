{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the classes on Windows               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.Windows;

interface

uses
  System.SysUtils, System.IOUtils, Winapi.Windows, DUnitX.TestFramework, DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.Games, DelphiDoom.Iwad.Factory, DelphiDoom.Iwad.DiskFileSystem,
  DelphiDoom.Iwad.WindowsEnvironment, DelphiDoom.Iwad.SteamRegistry, DelphiDoom.Tests.Iwad.Fakes;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadWindows = class(TObject)
  strict private
    FFolder: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeVedereUnFileCheEsisteSulDisco;
    [Test]
    procedure DovrebbeNonVedereUnFileCheNonEsiste;
    [Test]
    procedure DovrebbeNonConfondereUnaCartellaConUnFile;
    [Test]
    procedure DovrebbeCompletareUnPercorsoRelativo;
    [Test]
    procedure DovrebbeLeggereUnaVariabileSenzaGliSpaziAttorno;
    [Test]
    procedure DovrebbeDareVuotoPerUnaVariabileNonImpostata;
    [Test]
    procedure DovrebbeDareVuotoPerUnaApplicazioneSteamCheNonCe;
    [Test]
    procedure DovrebbeTrovareUnFileConLaFabbricaDiWindows;
  end;

implementation

{ TTestIwadWindows }

procedure TTestIwadWindows.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'ddiwadtest_' + IntToStr(GetCurrentProcessId));
  TDirectory.CreateDirectory(FFolder);
end;

procedure TTestIwadWindows.TearDown;
begin
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
  SetEnvironmentVariable('DDIWAD_TEST_VALUE', nil);
  SetEnvironmentVariable('DOOMWADDIR', nil);
end;

procedure TTestIwadWindows.DovrebbeVedereUnFileCheEsisteSulDisco;
var
  LFileSystem: IIwadFileSystem;
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, 'doom2.wad');
  TFile.WriteAllText(LPath, 'x');
  LFileSystem := TIwadDiskFileSystem.Create;
  Assert.IsTrue(LFileSystem.FileExists(LPath));
end;

procedure TTestIwadWindows.DovrebbeNonVedereUnFileCheNonEsiste;
var
  LFileSystem: IIwadFileSystem;
begin
  LFileSystem := TIwadDiskFileSystem.Create;
  Assert.IsFalse(LFileSystem.FileExists(TPath.Combine(FFolder, 'nothing.wad')));
end;

procedure TTestIwadWindows.DovrebbeNonConfondereUnaCartellaConUnFile;
var
  LFileSystem: IIwadFileSystem;
begin
  LFileSystem := TIwadDiskFileSystem.Create;
  Assert.IsFalse(LFileSystem.FileExists(FFolder));
end;

procedure TTestIwadWindows.DovrebbeCompletareUnPercorsoRelativo;
var
  LFileSystem: IIwadFileSystem;
begin
  LFileSystem := TIwadDiskFileSystem.Create;
  Assert.AreEqual(ExpandFileName('x.wad'), LFileSystem.ExpandPath('x.wad'));
  Assert.IsTrue(Pos(':', LFileSystem.ExpandPath('x.wad')) = 2);
end;

procedure TTestIwadWindows.DovrebbeLeggereUnaVariabileSenzaGliSpaziAttorno;
var
  LEnvironment: IIwadEnvironment;
begin
  SetEnvironmentVariable('DDIWAD_TEST_VALUE', '  C:\Giochi  ');
  LEnvironment := TIwadWindowsEnvironment.Create;
  Assert.AreEqual('C:\Giochi', LEnvironment.GetValue('DDIWAD_TEST_VALUE'));
end;

procedure TTestIwadWindows.DovrebbeDareVuotoPerUnaVariabileNonImpostata;
var
  LEnvironment: IIwadEnvironment;
begin
  LEnvironment := TIwadWindowsEnvironment.Create;
  Assert.AreEqual('', LEnvironment.GetValue('DDIWAD_TEST_NOT_SET'));
end;

procedure TTestIwadWindows.DovrebbeDareVuotoPerUnaApplicazioneSteamCheNonCe;
var
  LSteam: IIwadSteam;
begin
  LSteam := TIwadSteamRegistry.Create;
  Assert.AreEqual('', LSteam.GetInstallDirectory(999999999));
end;

procedure TTestIwadWindows.DovrebbeTrovareUnFileConLaFabbricaDiWindows;
var
  LOptions: IIwadOptions;
  LServices: TIwadServices;
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, 'freedoom2.wad');
  TFile.WriteAllText(LPath, 'x');
  SetEnvironmentVariable('DOOMWADDIR', PChar(FFolder));
  LOptions := TFakeIwadOptions.Create;
  LServices := TIwadFactory.CreateWindowsServices(igDoom, LOptions);
  Assert.AreEqual(LPath, LServices.Locator.Locate('freedoom2.wad'));
end;

end.
