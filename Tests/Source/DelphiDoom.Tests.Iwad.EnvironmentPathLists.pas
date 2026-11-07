{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the lists of folders of variables    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.EnvironmentPathLists;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.EnvironmentPathLists, DelphiDoom.Tests.Iwad.Fakes;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadEnvironmentPathLists = class(TObject)
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
    procedure DovrebbeSpezzareOgniVariabileInCartelle;
    [Test]
    procedure DovrebbeTenereLOrdineDelleVariabiliEDelleCartelle;
    [Test]
    procedure DovrebbeSaltareLeCartelleVuote;
    [Test]
    procedure DovrebbeDareNienteSeLaRicercaESpenta;
    [Test]
    procedure DovrebbeNonUsareLOpzioneDelleCartelleSingole;
    [Test]
    procedure DovrebbeDareEccezioneConAmbienteNil;
  end;

implementation

{ TTestIwadEnvironmentPathLists }

procedure TTestIwadEnvironmentPathLists.Setup;
begin
  FEnvironment := TFakeIwadEnvironment.Create;
  FEnvironmentIntf := FEnvironment;
  FOptions := TFakeIwadOptions.Create;
  FOptionsIntf := FOptions;
end;

procedure TTestIwadEnvironmentPathLists.TearDown;
begin
  FEnvironmentIntf := nil;
  FOptionsIntf := nil;
end;

function TTestIwadEnvironmentPathLists.MakeSearchPath(
  const AVariables: TArray<string>): IIwadSearchPath;
begin
  Result := TIwadEnvironmentPathLists.Create(FEnvironmentIntf, FOptionsIntf, AVariables);
end;

procedure TTestIwadEnvironmentPathLists.DovrebbeSpezzareOgniVariabileInCartelle;
var
  LFolders: TArray<string>;
begin
  FEnvironment.SetValue('DOOMWADPATH', 'C:\A;D:\B');
  LFolders := MakeSearchPath(TArray<string>.Create('DOOMWADPATH')).GetDirectories;
  Assert.AreEqual(2, Integer(Length(LFolders)));
  Assert.AreEqual('C:\A', LFolders[0]);
  Assert.AreEqual('D:\B', LFolders[1]);
end;

procedure TTestIwadEnvironmentPathLists.DovrebbeTenereLOrdineDelleVariabiliEDelleCartelle;
var
  LFolders: TArray<string>;
begin
  FEnvironment.SetValue('HEXENWADPATH', 'C:\H1;C:\H2');
  FEnvironment.SetValue('DOOMWADPATH', 'C:\D1');
  LFolders := MakeSearchPath(TArray<string>.Create('HEXENWADPATH', 'DOOMWADPATH')).GetDirectories;
  Assert.AreEqual(3, Integer(Length(LFolders)));
  Assert.AreEqual('C:\H1', LFolders[0]);
  Assert.AreEqual('C:\H2', LFolders[1]);
  Assert.AreEqual('C:\D1', LFolders[2]);
end;

procedure TTestIwadEnvironmentPathLists.DovrebbeSaltareLeCartelleVuote;
var
  LFolders: TArray<string>;
begin
  FEnvironment.SetValue('DOOMWADPATH', ';C:\A;;');
  LFolders := MakeSearchPath(TArray<string>.Create('DOOMWADPATH')).GetDirectories;
  Assert.AreEqual(1, Integer(Length(LFolders)));
  Assert.AreEqual('C:\A', LFolders[0]);
end;

procedure TTestIwadEnvironmentPathLists.DovrebbeDareNienteSeLaRicercaESpenta;
begin
  FEnvironment.SetValue('DOOMWADPATH', 'C:\A');
  FOptions.SearchWadPath := False;
  Assert.AreEqual(0,
    Integer(Length(MakeSearchPath(TArray<string>.Create('DOOMWADPATH')).GetDirectories)));
end;

procedure TTestIwadEnvironmentPathLists.DovrebbeNonUsareLOpzioneDelleCartelleSingole;
begin
  FEnvironment.SetValue('DOOMWADPATH', 'C:\A');
  FOptions.SearchWadDirectory := False;
  Assert.AreEqual(1,
    Integer(Length(MakeSearchPath(TArray<string>.Create('DOOMWADPATH')).GetDirectories)));
end;

procedure TTestIwadEnvironmentPathLists.DovrebbeDareEccezioneConAmbienteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadEnvironmentPathLists.Create(nil, FOptionsIntf, nil);
    end, EArgumentNilException);
end;

end.
