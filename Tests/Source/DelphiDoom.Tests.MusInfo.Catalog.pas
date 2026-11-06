{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MUSINFO library - the catalog                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MusInfo.Catalog;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Types,
  DelphiDoom.MusInfo.Intf, DelphiDoom.Tests.MusInfo.Fakes;

type
  [TestFixture]
  [Category('musinfo')]
  TTestMusInfoCatalog = class(TObject)
  private
    FMusic: TFakeMusic;
    FMusicIntf: IMusInfoMusicResolver;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FCatalog: IMusInfoCatalog;
    class function Entry(const AMap: string; AId: Integer; const AName: string): TMusInfoEntry; static;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestDovrebbeDareIlNumeroDellaMusicaDelResolver;
    [Test]
    procedure TestDovrebbeChiedereAlResolverIlNomeInMaiuscolo;
    [Test]
    procedure TestDovrebbeIgnorareIlNumeroGiaScrittoNellaVoce;
    [Test]
    procedure TestDovrebbeCercareIlNomeDellaMappaSenzaDistinguereLeMaiuscole;
    [Test]
    procedure TestDovrebbeDareMenoUnoSeLaVoceNonCe;
    [Test]
    procedure TestDovrebbeDareMenoUnoSeLaMusicaNonEsisteNelGioco;
    [Test]
    procedure TestDovrebbeDistinguereLeMappeConLoStessoId;
    [Test]
    procedure TestDovrebbeSostituireLaVoceConLaStessaMappaELoStessoId;
    [Test]
    procedure TestDovrebbeTenereLaPosizioneDellaVoceSostituita;
    [Test]
    procedure TestDovrebbeRifiutareLaVoceOltreIlLimiteConUnAvviso;
    [Test]
    procedure TestDovrebbeSostituireUnaVoceAnchePiena;
    [Test]
    procedure TestDovrebbeAccettareMilleVentiquattroVoci;
    [Test]
    procedure TestDovrebbeSvuotarsi;
    [Test]
    procedure TestDovrebbeDareLeVociPerPosizione;
    [Test]
    procedure TestDovrebbeFunzionareSenzaLog;
    [Test]
    procedure TestDovrebbeRifiutareUnResolverMancante;
  end;

implementation

uses
  DelphiDoom.MusInfo.Factory;

{ TTestMusInfoCatalog }

class function TTestMusInfoCatalog.Entry(const AMap: string; AId: Integer;
  const AName: string): TMusInfoEntry;
begin
  Result.MapName := AMap;
  Result.MusicId := AId;
  Result.MusicName := AName;
  Result.MusicNumber := 0;
end;

procedure TTestMusInfoCatalog.Setup;
begin
  FMusic := TFakeMusic.Create;
  FMusicIntf := FMusic;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FCatalog := TMusInfoFactory.CreateCatalog(FMusicIntf, FLogIntf);
end;

procedure TTestMusInfoCatalog.TestDovrebbeDareIlNumeroDellaMusicaDelResolver;
begin
  Assert.IsTrue(FCatalog.Add(Entry('MAP01', 1, 'D_ONE')));
  Assert.AreEqual(TFakeMusic.NumberOf('D_ONE'), FCatalog.Find(1, 'MAP01'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeChiedereAlResolverIlNomeInMaiuscolo;
begin
  FCatalog.Add(Entry('map01', 1, 'd_one'));
  Assert.AreEqual(1, FMusic.Asked.Count);
  Assert.AreEqual('D_ONE', FMusic.Asked[0]);
  Assert.AreEqual('MAP01', FCatalog.GetEntry(0).MapName);
  Assert.AreEqual('D_ONE', FCatalog.GetEntry(0).MusicName);
end;

procedure TTestMusInfoCatalog.TestDovrebbeIgnorareIlNumeroGiaScrittoNellaVoce;
var
  LEntry: TMusInfoEntry;
begin
  LEntry := Entry('MAP01', 1, 'D_ONE');
  LEntry.MusicNumber := 12345;
  FCatalog.Add(LEntry);
  Assert.AreEqual(TFakeMusic.NumberOf('D_ONE'), FCatalog.Find(1, 'MAP01'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeCercareIlNomeDellaMappaSenzaDistinguereLeMaiuscole;
begin
  FCatalog.Add(Entry('E1M1', 1, 'D_ONE'));
  Assert.AreEqual(TFakeMusic.NumberOf('D_ONE'), FCatalog.Find(1, 'e1m1'));
  Assert.AreEqual(TFakeMusic.NumberOf('D_ONE'), FCatalog.Find(1, 'E1m1'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeDareMenoUnoSeLaVoceNonCe;
begin
  FCatalog.Add(Entry('MAP01', 1, 'D_ONE'));
  Assert.AreEqual(-1, FCatalog.Find(2, 'MAP01'));
  Assert.AreEqual(-1, FCatalog.Find(1, 'MAP02'));
  Assert.AreEqual(-1, FCatalog.Find(1, 'UNA_MAPPA_LUNGA'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeDareMenoUnoSeLaMusicaNonEsisteNelGioco;
begin
  FCatalog.Add(Entry('MAP01', 1, 'UNKNOWN'));
  Assert.AreEqual(1, FCatalog.Count, 'la voce c''è lo stesso');
  Assert.AreEqual(-1, FCatalog.Find(1, 'MAP01'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeDistinguereLeMappeConLoStessoId;
begin
  FCatalog.Add(Entry('E1M1', 5, 'D_A'));
  FCatalog.Add(Entry('E1M2', 5, 'D_B'));
  Assert.AreEqual(2, FCatalog.Count);
  Assert.AreEqual(TFakeMusic.NumberOf('D_A'), FCatalog.Find(5, 'E1M1'));
  Assert.AreEqual(TFakeMusic.NumberOf('D_B'), FCatalog.Find(5, 'E1M2'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeSostituireLaVoceConLaStessaMappaELoStessoId;
begin
  FCatalog.Add(Entry('MAP01', 1, 'D_FIRST'));
  FCatalog.Add(Entry('MAP01', 1, 'D_SECOND'));
  Assert.AreEqual(1, FCatalog.Count);
  Assert.AreEqual(TFakeMusic.NumberOf('D_SECOND'), FCatalog.Find(1, 'MAP01'));
  Assert.AreEqual('D_SECOND', FCatalog.GetEntry(0).MusicName);
end;

procedure TTestMusInfoCatalog.TestDovrebbeTenereLaPosizioneDellaVoceSostituita;
begin
  FCatalog.Add(Entry('MAP01', 1, 'D_A'));
  FCatalog.Add(Entry('MAP02', 1, 'D_B'));
  FCatalog.Add(Entry('MAP01', 1, 'D_C'));
  Assert.AreEqual('MAP01', FCatalog.GetEntry(0).MapName);
  Assert.AreEqual('D_C', FCatalog.GetEntry(0).MusicName);
  Assert.AreEqual('MAP02', FCatalog.GetEntry(1).MapName);
end;

procedure TTestMusInfoCatalog.TestDovrebbeRifiutareLaVoceOltreIlLimiteConUnAvviso;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MUSINFO_MAX_ENTRIES - 1 do
    FCatalog.Add(Entry(Format('M%.4d', [LIndex]), 1, 'D_A'));
  Assert.AreEqual(MUSINFO_MAX_ENTRIES, FCatalog.Count);
  Assert.AreEqual('', FLog.Warnings);

  Assert.IsFalse(FCatalog.Add(Entry('MAP99', 1, 'D_LATE')));
  Assert.AreEqual(MUSINFO_MAX_ENTRIES, FCatalog.Count);
  Assert.AreEqual(-1, FCatalog.Find(1, 'MAP99'));
  Assert.AreEqual('P_AddMusInfo(): More than 1025 musinfo entries found, ignoring mus "D_LATE" of map "MAP99"'#13#10,
    FLog.Warnings);
end;

procedure TTestMusInfoCatalog.TestDovrebbeSostituireUnaVoceAnchePiena;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MUSINFO_MAX_ENTRIES - 1 do
    FCatalog.Add(Entry(Format('M%.4d', [LIndex]), 1, 'D_A'));
  Assert.IsTrue(FCatalog.Add(Entry('M0007', 1, 'D_REPLACED')));
  Assert.AreEqual(TFakeMusic.NumberOf('D_REPLACED'), FCatalog.Find(1, 'M0007'));
  Assert.AreEqual(MUSINFO_MAX_ENTRIES, FCatalog.Count);
  Assert.AreEqual('', FLog.Warnings);
end;

procedure TTestMusInfoCatalog.TestDovrebbeAccettareMilleVentiquattroVoci;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1023 do
    Assert.IsTrue(FCatalog.Add(Entry(Format('M%.4d', [LIndex]), 0, 'D_A')));
  Assert.AreEqual(1024, FCatalog.Count);
end;

procedure TTestMusInfoCatalog.TestDovrebbeSvuotarsi;
begin
  FCatalog.Add(Entry('MAP01', 1, 'D_ONE'));
  FCatalog.Clear;
  Assert.AreEqual(0, FCatalog.Count);
  Assert.AreEqual(-1, FCatalog.Find(1, 'MAP01'));
end;

procedure TTestMusInfoCatalog.TestDovrebbeDareLeVociPerPosizione;
begin
  FCatalog.Add(Entry('MAP01', 1, 'D_ONE'));
  FCatalog.Add(Entry('MAP02', 2, 'D_TWO'));
  Assert.AreEqual('MAP02', FCatalog.GetEntry(1).MapName);
  Assert.AreEqual(2, FCatalog.GetEntry(1).MusicId);
  Assert.AreEqual(TFakeMusic.NumberOf('D_TWO'), FCatalog.GetEntry(1).MusicNumber);
end;

procedure TTestMusInfoCatalog.TestDovrebbeFunzionareSenzaLog;
var
  LCatalog: IMusInfoCatalog;
  LIndex: Integer;
begin
  LCatalog := TMusInfoFactory.CreateCatalog(FMusicIntf, nil);
  for LIndex := 0 to MUSINFO_MAX_ENTRIES do
    LCatalog.Add(Entry(Format('M%.4d', [LIndex]), 1, 'D_A'));
  Assert.AreEqual(MUSINFO_MAX_ENTRIES, LCatalog.Count);
end;

procedure TTestMusInfoCatalog.TestDovrebbeRifiutareUnResolverMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TMusInfoFactory.CreateCatalog(nil, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMusInfoCatalog);

end.
