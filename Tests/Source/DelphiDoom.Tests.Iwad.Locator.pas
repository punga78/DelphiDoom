{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the locator of files                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.Locator;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Intf, DelphiDoom.Iwad.Locator,
  DelphiDoom.Tests.Iwad.Fakes;

type
  /// <summary>A source of folders that the test fills; it counts how many times it is asked</summary>
  TFakeIwadSearchPath = class(TInterfacedObject, IIwadSearchPath)
  public
    Directories: TArray<string>;
    Calls: Integer;
    constructor Create(const ADirectories: TArray<string>);
    function GetDirectories: TArray<string>;
  end;

  [TestFixture]
  [Category('iwad')]
  TTestIwadLocator = class(TObject)
  strict private
    FFileSystem: TFakeIwadFileSystem;
    FFileSystemIntf: IIwadFileSystem;
    function MakeLocator(const ASearchPaths: TArray<IIwadSearchPath>): IIwadLocator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlNomeCosiComeSeIlFileEsiste;
    [Test]
    procedure DovrebbeDareIlNomeCosiComeSeNessunoHaIlFile;
    [Test]
    procedure DovrebbeCercareLoStessoNomeNelleCartelle;
    [Test]
    procedure DovrebbeIgnorareLaCartellaDelNomeNellaRicerca;
    [Test]
    procedure DovrebbeProvareLeCartelleNellOrdineDelleSorgenti;
    [Test]
    procedure DovrebbeAggiungereLaBarraFinaleSeManca;
    [Test]
    procedure DovrebbeTrasformareLeBarreInAvanti;
    [Test]
    procedure DovrebbeSaltareLeCartelleVuote;
    [Test]
    procedure DovrebbeNonChiedereLeCartelleSeIlFileEsiste;
    [Test]
    procedure DovrebbeChiedereLeCartelleAdOgniChiamata;
    [Test]
    procedure DovrebbeDareEccezioneConFileSystemNil;
    [Test]
    procedure DovrebbeDareEccezioneConUnaSorgenteNil;
  end;

implementation

{ TFakeIwadSearchPath }

constructor TFakeIwadSearchPath.Create(const ADirectories: TArray<string>);
begin
  inherited Create;
  Directories := ADirectories;
end;

function TFakeIwadSearchPath.GetDirectories: TArray<string>;
begin
  Inc(Calls);
  Result := Directories;
end;

{ TTestIwadLocator }

procedure TTestIwadLocator.Setup;
begin
  FFileSystem := TFakeIwadFileSystem.Create;
  FFileSystemIntf := FFileSystem;
end;

procedure TTestIwadLocator.TearDown;
begin
  FFileSystemIntf := nil;
end;

function TTestIwadLocator.MakeLocator(const ASearchPaths: TArray<IIwadSearchPath>): IIwadLocator;
begin
  Result := TIwadLocator.Create(FFileSystemIntf, ASearchPaths);
end;

procedure TTestIwadLocator.DovrebbeDareIlNomeCosiComeSeIlFileEsiste;
begin
  FFileSystem.AddFile('R:\cwd\doom2.wad');
  Assert.AreEqual('doom2.wad', MakeLocator(nil).Locate('doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeDareIlNomeCosiComeSeNessunoHaIlFile;
var
  LLocator: IIwadLocator;
begin
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A', 'R:\B'))));
  Assert.AreEqual('sub\doom2.wad', LLocator.Locate('sub\doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeCercareLoStessoNomeNelleCartelle;
var
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\B\doom2.wad');
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A', 'R:\B\'))));
  Assert.AreEqual('R:\B\doom2.wad', LLocator.Locate('doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeIgnorareLaCartellaDelNomeNellaRicerca;
var
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\A\doom2.wad');
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A'))));
  Assert.AreEqual('R:\A\doom2.wad', LLocator.Locate('X:\altrove\doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeProvareLeCartelleNellOrdineDelleSorgenti;
var
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\A\doom2.wad');
  FFileSystem.AddFile('R:\B\doom2.wad');
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:\B')),
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A'))));
  Assert.AreEqual('R:\B\doom2.wad', LLocator.Locate('doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeAggiungereLaBarraFinaleSeManca;
var
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\A\doom2.wad');
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A'))));
  Assert.AreEqual('R:\A\doom2.wad', LLocator.Locate('doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeTrasformareLeBarreInAvanti;
var
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\A\doom2.wad');
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('R:/A'))));
  Assert.AreEqual('R:\A\doom2.wad', LLocator.Locate('doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeSaltareLeCartelleVuote;
var
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\A\doom2.wad');
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(
    TFakeIwadSearchPath.Create(TArray<string>.Create('', 'R:\A'))));
  Assert.AreEqual('R:\A\doom2.wad', LLocator.Locate('doom2.wad'));
end;

procedure TTestIwadLocator.DovrebbeNonChiedereLeCartelleSeIlFileEsiste;
var
  LSearchPath: TFakeIwadSearchPath;
  LLocator: IIwadLocator;
begin
  FFileSystem.AddFile('R:\cwd\doom2.wad');
  LSearchPath := TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A'));
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(LSearchPath));
  LLocator.Locate('doom2.wad');
  Assert.AreEqual(0, LSearchPath.Calls);
end;

procedure TTestIwadLocator.DovrebbeChiedereLeCartelleAdOgniChiamata;
var
  LSearchPath: TFakeIwadSearchPath;
  LLocator: IIwadLocator;
begin
  LSearchPath := TFakeIwadSearchPath.Create(TArray<string>.Create('R:\A'));
  LLocator := MakeLocator(TArray<IIwadSearchPath>.Create(LSearchPath));
  Assert.AreEqual('doom2.wad', LLocator.Locate('doom2.wad'));
  FFileSystem.AddFile('R:\A\doom2.wad');
  Assert.AreEqual('R:\A\doom2.wad', LLocator.Locate('doom2.wad'));
  Assert.AreEqual(2, LSearchPath.Calls);
end;

procedure TTestIwadLocator.DovrebbeDareEccezioneConFileSystemNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadLocator.Create(nil, nil);
    end, EArgumentNilException);
end;

procedure TTestIwadLocator.DovrebbeDareEccezioneConUnaSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadLocator.Create(FFileSystemIntf, TArray<IIwadSearchPath>.Create(nil));
    end, EArgumentNilException);
end;

end.
