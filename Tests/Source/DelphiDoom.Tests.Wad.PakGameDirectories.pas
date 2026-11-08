{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the WAD library - the folders of the game              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.PakGameDirectories;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Wad.Pak.GameDirectories;

type
  [TestFixture]
  [Category('wad')]
  TTestWadPakGameDirectories = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeCartelleDelGiocoSenzaFileCaricati;
    [Test]
    procedure DovrebbeMettereDavantiIlNomeDiUnFileSenzaEstensione;
    [Test]
    procedure DovrebbeTagliareIlNomeAlPrimoPunto;
    [Test]
    procedure DovrebbeNonRipetereUnaCartellaGiaPresente;
    [Test]
    procedure DovrebbeNonRipetereUnNomeGiaAggiunto;
    [Test]
    procedure DovrebbeAggiungereDallUltimoAlPrimoFile;
    [Test]
    procedure DovrebbeConfrontareIlNomeInteroENonUnaParte;
  end;

implementation

{ TTestWadPakGameDirectories }

procedure TTestWadPakGameDirectories.DovrebbeDareLeCartelleDelGiocoSenzaFileCaricati;
begin
  Assert.AreEqual('DOOM1,DOOM', TPakGameDirectories.Compose('DOOM1,DOOM', nil));
end;

procedure TTestWadPakGameDirectories.DovrebbeMettereDavantiIlNomeDiUnFileSenzaEstensione;
begin
  Assert.AreEqual('MYMOD,DOOM1,DOOM',
    TPakGameDirectories.Compose('DOOM1,DOOM', TArray<string>.Create('MYMOD')));
end;

procedure TTestWadPakGameDirectories.DovrebbeTagliareIlNomeAlPrimoPunto;
begin
  Assert.AreEqual('MY,DOOM',
    TPakGameDirectories.Compose('DOOM', TArray<string>.Create('MY.MOD.WAD')));
end;

procedure TTestWadPakGameDirectories.DovrebbeNonRipetereUnaCartellaGiaPresente;
begin
  Assert.AreEqual('DOOM1,DOOM',
    TPakGameDirectories.Compose('DOOM1,DOOM', TArray<string>.Create('DOOM1.WAD')));
  Assert.AreEqual('DOOM1,DOOM',
    TPakGameDirectories.Compose('DOOM1,DOOM', TArray<string>.Create('DOOM.WAD')));
end;

procedure TTestWadPakGameDirectories.DovrebbeNonRipetereUnNomeGiaAggiunto;
begin
  Assert.AreEqual('A,DOOM',
    TPakGameDirectories.Compose('DOOM', TArray<string>.Create('A.WAD', 'A.PK3')));
end;

procedure TTestWadPakGameDirectories.DovrebbeAggiungereDallUltimoAlPrimoFile;
begin
  // the last file is added first, so the first one ends up in front of the list
  Assert.AreEqual('A,B,C,DOOM',
    TPakGameDirectories.Compose('DOOM', TArray<string>.Create('A.WAD', 'B.WAD', 'C.WAD')));
end;

procedure TTestWadPakGameDirectories.DovrebbeConfrontareIlNomeInteroENonUnaParte;
begin
  Assert.AreEqual('DOO,DOOM1,DOOM',
    TPakGameDirectories.Compose('DOOM1,DOOM', TArray<string>.Create('DOO.WAD')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWadPakGameDirectories);

end.
