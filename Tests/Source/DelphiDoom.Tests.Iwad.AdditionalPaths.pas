{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the additional paths                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.AdditionalPaths;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Intf, DelphiDoom.Iwad.AdditionalPaths,
  DelphiDoom.Tests.Iwad.Fakes;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadAdditionalPaths = class(TObject)
  strict private
    FOptions: TFakeIwadOptions;
    FOptionsIntf: IIwadOptions;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeCartelleDellOpzione;
    [Test]
    procedure DovrebbeDareNienteSeLOpzioneEVuota;
    [Test]
    procedure DovrebbeCercareAncheConLeAltreRicercheSpente;
    [Test]
    procedure DovrebbeLeggereLOpzioneAdOgniChiamata;
    [Test]
    procedure DovrebbeDareEccezioneConOpzioniNil;
  end;

implementation

{ TTestIwadAdditionalPaths }

procedure TTestIwadAdditionalPaths.Setup;
begin
  FOptions := TFakeIwadOptions.Create;
  FOptionsIntf := FOptions;
end;

procedure TTestIwadAdditionalPaths.TearDown;
begin
  FOptionsIntf := nil;
end;

procedure TTestIwadAdditionalPaths.DovrebbeDareLeCartelleDellOpzione;
var
  LSearchPath: IIwadSearchPath;
  LFolders: TArray<string>;
begin
  FOptions.AdditionalPaths := 'C:\A;;D:\B';
  LSearchPath := TIwadAdditionalPaths.Create(FOptionsIntf);
  LFolders := LSearchPath.GetDirectories;
  Assert.AreEqual(2, Integer(Length(LFolders)));
  Assert.AreEqual('C:\A', LFolders[0]);
  Assert.AreEqual('D:\B', LFolders[1]);
end;

procedure TTestIwadAdditionalPaths.DovrebbeDareNienteSeLOpzioneEVuota;
var
  LSearchPath: IIwadSearchPath;
begin
  LSearchPath := TIwadAdditionalPaths.Create(FOptionsIntf);
  Assert.AreEqual(0, Integer(Length(LSearchPath.GetDirectories)));
end;

procedure TTestIwadAdditionalPaths.DovrebbeCercareAncheConLeAltreRicercheSpente;
var
  LSearchPath: IIwadSearchPath;
begin
  FOptions.SearchWadDirectory := False;
  FOptions.SearchWadPath := False;
  FOptions.SearchSteamPaths := False;
  FOptions.AdditionalPaths := 'C:\A';
  LSearchPath := TIwadAdditionalPaths.Create(FOptionsIntf);
  Assert.AreEqual(1, Integer(Length(LSearchPath.GetDirectories)));
end;

procedure TTestIwadAdditionalPaths.DovrebbeLeggereLOpzioneAdOgniChiamata;
var
  LSearchPath: IIwadSearchPath;
begin
  LSearchPath := TIwadAdditionalPaths.Create(FOptionsIntf);
  Assert.AreEqual(0, Integer(Length(LSearchPath.GetDirectories)));
  FOptions.AdditionalPaths := 'C:\A';
  Assert.AreEqual(1, Integer(Length(LSearchPath.GetDirectories)));
end;

procedure TTestIwadAdditionalPaths.DovrebbeDareEccezioneConOpzioniNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadAdditionalPaths.Create(nil);
    end, EArgumentNilException);
end;

end.
