{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TPakPathResolver                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.PakPathResolver;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Wad.Pak.Intf;

type
  [TestFixture]
  [Category('wad')]
  TTestWadPakPathResolver = class(TObject)
  strict private
    FIndex: IPakIndex;
    FResolver: IPakPathResolver;
    // the fake disk and the fake entries: what exists, what fails, and every call in order
    FDiskFiles: TStringList;
    FFailingEntries: TArray<Integer>;
    FCalls: TStringList;
    FOpened: string;
    function Resolve(const AName: string; AMode: TPakLookupMode; const APreferred: TArray<string>;
      const ADirectory: string): Boolean;
    function Calls: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnIndiceNil;
    [Test]
    procedure DovrebbePreferireIlFileSuDiscoNelPercorsoIntero;
    [Test]
    procedure DovrebbeAprireLaVoceDelPercorsoIntero;
    [Test]
    procedure DovrebbeRiprovareComePercorsoConCartelleSeLaVoceNonSiLegge;
    [Test]
    procedure DovrebbeCercarePerNomeCorto;
    [Test]
    procedure DovrebbeProvarePrimaLaCartellaDataAParte;
    [Test]
    procedure DovrebbeProvareLaCartellaAllaFineConIlPercorsoIntero;
    [Test]
    procedure DovrebbeUsareLaRicercaSerialeQuandoLaPrimaSceltaNonSiLegge;
    [Test]
    procedure DovrebbeTogliereLaBarraInizialeEGliSpazi;
    [Test]
    procedure DovrebbeNonProvareUnNomeVuoto;
    [Test]
    procedure DovrebbeDareFalsoSeNonTrovaNulla;
  end;

implementation

uses
  DelphiDoom.Wad.Pak.Index,
  DelphiDoom.Wad.Pak.PathResolver;

{ TTestWadPakPathResolver }

procedure TTestWadPakPathResolver.Setup;
begin
  FIndex := TPakIndex.Create;
  FResolver := TPakPathResolver.Create(FIndex);
  FDiskFiles := TStringList.Create;
  FDiskFiles.CaseSensitive := True;
  FCalls := TStringList.Create;
  FFailingEntries := nil;
  FOpened := '';
end;

procedure TTestWadPakPathResolver.TearDown;
begin
  FCalls.Free;
  FDiskFiles.Free;
  FResolver := nil;
  FIndex := nil;
end;

function TTestWadPakPathResolver.Resolve(const AName: string; AMode: TPakLookupMode;
  const APreferred: TArray<string>; const ADirectory: string): Boolean;
begin
  FCalls.Clear;
  FOpened := '';
  Result := FResolver.Resolve(AName, AMode, APreferred, ADirectory,
    function(const APath: string): Boolean
    begin
      FCalls.Add('disk:' + APath);
      Result := FDiskFiles.IndexOf(APath) >= 0;
      if Result then
        FOpened := 'disk:' + APath;
    end,
    function(AIndex: Integer): Boolean
    var
      LFailing: Integer;
    begin
      FCalls.Add('entry:' + IntToStr(AIndex));
      Result := True;
      for LFailing in FFailingEntries do
        if LFailing = AIndex then
          Result := False;
      if Result then
        FOpened := 'entry:' + IntToStr(AIndex);
    end);
end;

function TTestWadPakPathResolver.Calls: string;
begin
  Result := String.Join(' ', FCalls.ToStringArray);
end;

procedure TTestWadPakPathResolver.DovrebbeRifiutareUnIndiceNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TPakPathResolver.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestWadPakPathResolver.DovrebbePreferireIlFileSuDiscoNelPercorsoIntero;
begin
  FIndex.Add('actordef.txt', 'P', 0, 0, 1);
  FDiskFiles.Add('actordef.txt');
  Assert.IsTrue(Resolve('actordef.txt', TPakLookupMode.Full, nil, ''));
  Assert.AreEqual('disk:actordef.txt', FOpened);
  Assert.AreEqual('disk:actordef.txt', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeAprireLaVoceDelPercorsoIntero;
begin
  FIndex.Add('data\actordef.txt', 'P', 0, 0, 1);
  Assert.IsTrue(Resolve('data\ActorDef.txt', TPakLookupMode.Full, nil, ''));
  Assert.AreEqual('entry:0', FOpened);
  Assert.AreEqual('disk:data\ActorDef.txt entry:0', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeRiprovareComePercorsoConCartelleSeLaVoceNonSiLegge;
begin
  FIndex.Add('data\actordef.txt', 'P', 0, 0, 1);
  FFailingEntries := [0];
  Assert.IsFalse(Resolve('data/actordef.txt', TPakLookupMode.Full, nil, ''));
  // the full path does not fix the slashes; the second try does, and its entry cannot be read
  Assert.AreEqual('disk:data/actordef.txt disk:data\actordef.txt entry:0', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeCercarePerNomeCorto;
begin
  FIndex.Add('sprites\bar.tga', 'P', 0, 0, 1);
  Assert.IsTrue(Resolve('any\BAR.tga', TPakLookupMode.Short, nil, ''));
  Assert.AreEqual('disk:any\BAR.tga entry:0', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeProvarePrimaLaCartellaDataAParte;
begin
  FIndex.Add('voxels\thing.ddvox', 'P', 0, 0, 1);
  FDiskFiles.Add('voxels\thing.ddvox');
  Assert.IsTrue(Resolve('thing.ddvox', TPakLookupMode.Preferred, ['DOOM\'], 'voxels'));
  Assert.AreEqual('disk:voxels\thing.ddvox', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeProvareLaCartellaAllaFineConIlPercorsoIntero;
begin
  Assert.IsFalse(Resolve('x.txt', TPakLookupMode.Full, nil, 'dir'));
  Assert.AreEqual('disk:x.txt disk:x.txt disk:dir\x.txt', Calls);
  Assert.IsFalse(Resolve('x.txt', TPakLookupMode.Short, nil, 'dir'));
  Assert.AreEqual('disk:dir\x.txt disk:x.txt', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeUsareLaRicercaSerialeQuandoLaPrimaSceltaNonSiLegge;
begin
  FIndex.Add('voxels\t.ddvox', 'P', 0, 0, 1);
  FIndex.Add('doom\voxels\t.ddvox', 'P', 0, 1, 1);
  FFailingEntries := [0];
  Assert.IsTrue(Resolve('t.ddvox', TPakLookupMode.Preferred, ['VOXELS\'], ''));
  // first choice: right inside VOXELS\ (0, fails); serial: the last added that contains it (1)
  Assert.AreEqual('disk:t.ddvox entry:0 entry:1', Calls);
  Assert.AreEqual('entry:1', FOpened);
end;

procedure TTestWadPakPathResolver.DovrebbeTogliereLaBarraInizialeEGliSpazi;
begin
  FIndex.Add('a\b.txt', 'P', 0, 0, 1);
  Assert.IsTrue(Resolve('\\a\b.txt ', TPakLookupMode.Directory, nil, ''));
  Assert.AreEqual('disk:a\b.txt entry:0', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeNonProvareUnNomeVuoto;
begin
  Assert.IsFalse(Resolve('  ', TPakLookupMode.Directory, nil, ''));
  Assert.AreEqual('', Calls);
  Assert.IsFalse(Resolve('\', TPakLookupMode.Directory, nil, ''));
  Assert.AreEqual('', Calls);
end;

procedure TTestWadPakPathResolver.DovrebbeDareFalsoSeNonTrovaNulla;
begin
  FIndex.Add('a\b.txt', 'P', 0, 0, 1);
  Assert.IsFalse(Resolve('c.txt', TPakLookupMode.Preferred, ['A\'], ''));
  Assert.AreEqual('disk:c.txt disk:c.txt', Calls);
  Assert.AreEqual('', FOpened);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWadPakPathResolver);

end.
