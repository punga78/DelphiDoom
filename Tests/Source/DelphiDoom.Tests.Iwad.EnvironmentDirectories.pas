{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the folders of the variables         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.EnvironmentDirectories;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.EnvironmentDirectories, DelphiDoom.Tests.Iwad.Fakes;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadEnvironmentDirectories = class(TObject)
  strict private
    FEnvironment: TFakeIwadEnvironment;
    FEnvironmentIntf: IIwadEnvironment;
    FOptions: TFakeIwadOptions;
    FOptionsIntf: IIwadOptions;
    function MakeSearchPath(const AVariables: TArray<string>): IIwadSearchPath;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeCartelleDelleVariabiliNellOrdineDato;
    [Test]
    procedure DovrebbeSaltareLeVariabiliVuote;
    [Test]
    procedure DovrebbeDareNienteSeLaRicercaESpenta;
    [Test]
    procedure DovrebbeLeggereLeOpzioniAdOgniChiamata;
    [Test]
    procedure DovrebbeDareEccezioneConAmbienteNil;
    [Test]
    procedure DovrebbeDareEccezioneConOpzioniNil;
  end;

implementation

{ TTestIwadEnvironmentDirectories }

procedure TTestIwadEnvironmentDirectories.Setup;
begin
  FEnvironment := TFakeIwadEnvironment.Create;
  FEnvironmentIntf := FEnvironment;
  FOptions := TFakeIwadOptions.Create;
  FOptionsIntf := FOptions;
end;

procedure TTestIwadEnvironmentDirectories.TearDown;
begin
  FEnvironmentIntf := nil;
  FOptionsIntf := nil;
end;

function TTestIwadEnvironmentDirectories.MakeSearchPath(
  const AVariables: TArray<string>): IIwadSearchPath;
begin
  Result := TIwadEnvironmentDirectories.Create(FEnvironmentIntf, FOptionsIntf, AVariables);
end;

procedure TTestIwadEnvironmentDirectories.DovrebbeDareLeCartelleDelleVariabiliNellOrdineDato;
var
  LFolders: TArray<string>;
begin
  FEnvironment.SetValue('HERETICWADDIR', 'C:\Heretic');
  FEnvironment.SetValue('DOOMWADDIR', 'C:\Doom');
  LFolders := MakeSearchPath(TArray<string>.Create('HERETICWADDIR', 'DOOMWADDIR')).GetDirectories;
  Assert.AreEqual(2, Integer(Length(LFolders)));
  Assert.AreEqual('C:\Heretic', LFolders[0]);
  Assert.AreEqual('C:\Doom', LFolders[1]);
end;

procedure TTestIwadEnvironmentDirectories.DovrebbeSaltareLeVariabiliVuote;
var
  LFolders: TArray<string>;
begin
  FEnvironment.SetValue('DOOMWADDIR', 'C:\Doom');
  LFolders := MakeSearchPath(TArray<string>.Create('HERETICWADDIR', 'DOOMWADDIR')).GetDirectories;
  Assert.AreEqual(1, Integer(Length(LFolders)));
  Assert.AreEqual('C:\Doom', LFolders[0]);
end;

procedure TTestIwadEnvironmentDirectories.DovrebbeDareNienteSeLaRicercaESpenta;
begin
  FEnvironment.SetValue('DOOMWADDIR', 'C:\Doom');
  FOptions.SearchWadDirectory := False;
  Assert.AreEqual(0,
    Integer(Length(MakeSearchPath(TArray<string>.Create('DOOMWADDIR')).GetDirectories)));
end;

procedure TTestIwadEnvironmentDirectories.DovrebbeLeggereLeOpzioniAdOgniChiamata;
var
  LSearchPath: IIwadSearchPath;
begin
  FEnvironment.SetValue('DOOMWADDIR', 'C:\Doom');
  LSearchPath := MakeSearchPath(TArray<string>.Create('DOOMWADDIR'));
  Assert.AreEqual(1, Integer(Length(LSearchPath.GetDirectories)));
  FOptions.SearchWadDirectory := False;
  Assert.AreEqual(0, Integer(Length(LSearchPath.GetDirectories)));
  FOptions.SearchWadDirectory := True;
  FEnvironment.SetValue('DOOMWADDIR', '');
  Assert.AreEqual(0, Integer(Length(LSearchPath.GetDirectories)));
end;

procedure TTestIwadEnvironmentDirectories.DovrebbeDareEccezioneConAmbienteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadEnvironmentDirectories.Create(nil, FOptionsIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestIwadEnvironmentDirectories.DovrebbeDareEccezioneConOpzioniNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadEnvironmentDirectories.Create(FEnvironmentIntf, nil, nil);
    end, EArgumentNilException);
end;

end.
