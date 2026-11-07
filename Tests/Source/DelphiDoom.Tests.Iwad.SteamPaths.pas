{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the Steam folders                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.SteamPaths;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Intf, DelphiDoom.Iwad.SteamPaths,
  DelphiDoom.Tests.Iwad.Fakes;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadSteamPaths = class(TObject)
  strict private
    FSteam: TFakeIwadSteam;
    FSteamIntf: IIwadSteam;
    FOptions: TFakeIwadOptions;
    FOptionsIntf: IIwadOptions;
    function MakeSearchPath(const AApplications: TArray<Integer>): IIwadSearchPath;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareCartellaBaseEBaseWadsPerOgniApplicazioneInstallata;
    [Test]
    procedure DovrebbeSaltareLeApplicazioniNonInstallate;
    [Test]
    procedure DovrebbeTenereLOrdineDelleApplicazioni;
    [Test]
    procedure DovrebbeDareNienteESenzaChiedereASteamSeLaRicercaESpenta;
    [Test]
    procedure DovrebbeDareEccezioneConSteamNil;
  end;

implementation

{ TTestIwadSteamPaths }

procedure TTestIwadSteamPaths.Setup;
begin
  FSteam := TFakeIwadSteam.Create;
  FSteamIntf := FSteam;
  FOptions := TFakeIwadOptions.Create;
  FOptionsIntf := FOptions;
end;

procedure TTestIwadSteamPaths.TearDown;
begin
  FSteamIntf := nil;
  FOptionsIntf := nil;
end;

function TTestIwadSteamPaths.MakeSearchPath(const AApplications: TArray<Integer>): IIwadSearchPath;
begin
  Result := TIwadSteamPaths.Create(FSteamIntf, FOptionsIntf, AApplications);
end;

procedure TTestIwadSteamPaths.DovrebbeDareCartellaBaseEBaseWadsPerOgniApplicazioneInstallata;
var
  LFolders: TArray<string>;
begin
  FSteam.Install(2280, 'C:\Steam\Doom\');
  LFolders := MakeSearchPath(TArray<Integer>.Create(2280)).GetDirectories;
  Assert.AreEqual(3, Integer(Length(LFolders)));
  Assert.AreEqual('C:\Steam\Doom\', LFolders[0]);
  Assert.AreEqual('C:\Steam\Doom\base\', LFolders[1]);
  Assert.AreEqual('C:\Steam\Doom\base\wads\', LFolders[2]);
end;

procedure TTestIwadSteamPaths.DovrebbeSaltareLeApplicazioniNonInstallate;
var
  LFolders: TArray<string>;
begin
  FSteam.Install(2290, 'C:\Steam\Doom2\');
  LFolders := MakeSearchPath(TArray<Integer>.Create(2280, 2290, 2300)).GetDirectories;
  Assert.AreEqual(3, Integer(Length(LFolders)));
  Assert.AreEqual('C:\Steam\Doom2\', LFolders[0]);
end;

procedure TTestIwadSteamPaths.DovrebbeTenereLOrdineDelleApplicazioni;
var
  LFolders: TArray<string>;
begin
  FSteam.Install(2280, 'C:\Steam\A\');
  FSteam.Install(2300, 'C:\Steam\C\');
  LFolders := MakeSearchPath(TArray<Integer>.Create(2300, 2280)).GetDirectories;
  Assert.AreEqual(6, Integer(Length(LFolders)));
  Assert.AreEqual('C:\Steam\C\', LFolders[0]);
  Assert.AreEqual('C:\Steam\A\', LFolders[3]);
end;

procedure TTestIwadSteamPaths.DovrebbeDareNienteESenzaChiedereASteamSeLaRicercaESpenta;
begin
  FSteam.Install(2280, 'C:\Steam\Doom\');
  FOptions.SearchSteamPaths := False;
  Assert.AreEqual(0,
    Integer(Length(MakeSearchPath(TArray<Integer>.Create(2280)).GetDirectories)));
  Assert.AreEqual(0, FSteam.Queries);
end;

procedure TTestIwadSteamPaths.DovrebbeDareEccezioneConSteamNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadSteamPaths.Create(nil, FOptionsIntf, nil);
    end, EArgumentNilException);
end;

end.
