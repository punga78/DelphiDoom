{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the GL nodes of a map              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.GlMapFinder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.Adler32, DelphiDoom.Nodes.GlMapFinder, DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesGlMapFinder = class(TObject)
  strict private
    FSource: TFakeLumpSource;
    FRef: INodesLumpSource;
    FFinder: INodesGlMapFinder;
    function Checksum(AMapLabel: Integer): Cardinal;
    function GlText(const ALevel: string; AChecksum: Cardinal): TBytes;
    procedure AddMap(const AName: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestDovrebbeTrovareLEtichettaGlSubitoDopoLaMappa;
    [Test]
    procedure TestUnChecksumDiversoDovrebbeDareMenoUno;
    [Test]
    procedure TestSenzaEtichettaGlDovrebbeDareMenoUno;
    [Test]
    procedure TestDovrebbeCercareTraLeEtichetteConLoStessoNomeQuellaGiusta;
    [Test]
    procedure TestDovrebbeTrovareLEtichettaPrimaDellaMappa;
    [Test]
    procedure TestUnaMappaConNomeLungoDovrebbeUsareGlLevelConLaChiaveLevel;
    [Test]
    procedure TestGlLevelDiUnAltraMappaNonDovrebbeEssereTrovata;
    [Test]
    procedure TestGlLevelConLaChiaveMapnameDovrebbeEssereTrovata;
    [Test]
    procedure TestIlWadDiProvaDiGlbspDovrebbeTrovareLEtichetta;
    [Test]
    procedure TestIlTestoSenzaChecksumDovrebbeDareZero;
    [Test]
    procedure TestIlChecksumDecimaleEsadecimaleEDiesisDovrebberoEssereLetti;
    [Test]
    procedure TestIlChecksumNonValidoDovrebbeDareZero;
    [Test]
    procedure TestIlTestoDiUnaAltraMappaDovrebbeDareZero;
    [Test]
    procedure TestIlBuilderEIlTempoNonDovrebberoDisturbare;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

{ TTestNodesGlMapFinder }

procedure TTestNodesGlMapFinder.Setup;
begin
  FSource := TFakeLumpSource.Create;
  FRef := FSource;
  FFinder := TNodesGlMapFinder.Create(FRef);
end;

procedure TTestNodesGlMapFinder.AddMap(const AName: string);
const
  LUMPS: array[0..9] of string = ('THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS',
    'SSECTORS', 'NODES', 'SECTORS', 'REJECT', 'BLOCKMAP');
var
  LIndex: Integer;
begin
  FSource.Add(AName);
  for LIndex := 1 to 10 do
    FSource.Add(LUMPS[LIndex - 1], TEncoding.ASCII.GetBytes(AName + IntToStr(LIndex)));
end;

function TTestNodesGlMapFinder.Checksum(AMapLabel: Integer): Cardinal;
begin
  Result := TNodesAdler32.OfMap(FRef, AMapLabel);
end;

function TTestNodesGlMapFinder.GlText(const ALevel: string; AChecksum: Cardinal): TBytes;
begin
  Result := TEncoding.ASCII.GetBytes(Format('LEVEL=%s'#10'BUILDER=glBSP 2.24'#10'CHECKSUM=0x%.8x'#10,
    [ALevel, AChecksum]));
end;

procedure TTestNodesGlMapFinder.TestDovrebbeTrovareLEtichettaGlSubitoDopoLaMappa;
begin
  AddMap('MAP01');
  FSource.Add('GL_MAP01', GlText('MAP01', Checksum(0)));
  FSource.Add('GL_VERT');
  Assert.AreEqual(11, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestUnChecksumDiversoDovrebbeDareMenoUno;
begin
  AddMap('MAP01');
  FSource.Add('GL_MAP01', GlText('MAP01', Checksum(0) + 1));
  Assert.AreEqual(-1, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestSenzaEtichettaGlDovrebbeDareMenoUno;
begin
  AddMap('MAP01');
  Assert.AreEqual(-1, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestDovrebbeCercareTraLeEtichetteConLoStessoNomeQuellaGiusta;
begin
  AddMap('MAP01');
  // l'ultima ha il checksum sbagliato: la prima, dopo la mappa, e' quella giusta
  FSource.Add('GL_MAP01', GlText('MAP01', Checksum(0)));
  FSource.Add('GL_VERT');
  FSource.Add('GL_MAP01', GlText('MAP01', 12345));
  Assert.AreEqual(11, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestDovrebbeTrovareLEtichettaPrimaDellaMappa;
var
  LChecksum: Cardinal;
begin
  // il checksum dipende solo da VERTEXES e LINEDEFS, che AddMap riempie sempre uguali
  AddMap('MAP01');
  LChecksum := Checksum(0);
  FSource := TFakeLumpSource.Create;
  FRef := FSource;
  FFinder := TNodesGlMapFinder.Create(FRef);
  FSource.Add('GL_MAP01', GlText('MAP01', LChecksum));
  AddMap('MAP01');
  FSource.Add('GL_MAP01', GlText('MAP01', LChecksum + 1));
  // l'ultima etichetta e' sbagliata: quella giusta sta prima della mappa (che e' in 1)
  Assert.AreEqual(0, FFinder.FindGlMapLump(1));
end;

procedure TTestNodesGlMapFinder.TestUnaMappaConNomeLungoDovrebbeUsareGlLevelConLaChiaveLevel;
begin
  // glBSP: per un nome di piu' di cinque caratteri l'etichetta e' GL_LEVEL con LEVEL=nome
  // (il vecchio codice cercava le etichette con il nome della mappa e non trovava mai GL_LEVEL)
  AddMap('MAP001XX');
  FSource.Add('GL_LEVEL', GlText('MAP001XX', Checksum(0)));
  Assert.AreEqual(11, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestGlLevelDiUnAltraMappaNonDovrebbeEssereTrovata;
begin
  AddMap('MAP001XX');
  FSource.Add('GL_LEVEL', GlText('MAP002XX', Checksum(0)));
  Assert.AreEqual(-1, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestGlLevelConLaChiaveMapnameDovrebbeEssereTrovata;
begin
  AddMap('MAP001XX');
  FSource.Add('GL_LEVEL', TEncoding.ASCII.GetBytes(Format('MAPNAME=map001xx'#10'CHECKSUM=%d'#10,
    [Checksum(0)])));
  Assert.AreEqual(11, FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestIlWadDiProvaDiGlbspDovrebbeTrovareLEtichetta;
begin
  FSource.AddWad(TNodesTestData.ReadFile('glbsp_map01_normal.wad'));
  // il valore del vecchio codice, nello stesso WAD caricato dal motore
  Assert.AreEqual(StrToInt(TNodesTestData.Golden('gl_finder.golden.txt', 'normal_wad')),
    FFinder.FindGlMapLump(0));
end;

procedure TTestNodesGlMapFinder.TestIlTestoSenzaChecksumDovrebbeDareZero;
begin
  Assert.AreEqual(Cardinal(0), TNodesGlMapFinder.ChecksumOfText('LEVEL=MAP01'#10'X=1', 'GL_MAP01',
    'GL_MAP01'));
  Assert.AreEqual(Cardinal(0), TNodesGlMapFinder.ChecksumOfText('', 'GL_MAP01', 'GL_MAP01'));
end;

procedure TTestNodesGlMapFinder.TestIlChecksumDecimaleEsadecimaleEDiesisDovrebberoEssereLetti;
begin
  Assert.AreEqual(Cardinal(1234), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=1234', 'GL_MAP01',
    'GL_MAP01'));
  Assert.AreEqual(Cardinal($6B1A4D3C), TNodesGlMapFinder.ChecksumOfText('checksum = 0x6b1a4d3c',
    'GL_MAP01', 'GL_MAP01'));
  Assert.AreEqual(Cardinal($6B1A4D3C), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=$6B1A4D3C',
    'GL_MAP01', 'GL_MAP01'));
  Assert.AreEqual(Cardinal(77), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=#77', 'GL_MAP01',
    'GL_MAP01'));
end;

procedure TTestNodesGlMapFinder.TestIlChecksumNonValidoDovrebbeDareZero;
begin
  Assert.AreEqual(Cardinal(0), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=abc', 'GL_MAP01',
    'GL_MAP01'));
  Assert.AreEqual(Cardinal(0), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=4294967296', 'GL_MAP01',
    'GL_MAP01'));
  Assert.AreEqual(Cardinal(0), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=', 'GL_MAP01',
    'GL_MAP01'));
end;

procedure TTestNodesGlMapFinder.TestIlTestoDiUnaAltraMappaDovrebbeDareZero;
begin
  Assert.AreEqual(Cardinal(0), TNodesGlMapFinder.ChecksumOfText('CHECKSUM=5'#10'LEVEL=MAP02',
    'GL_LEVEL', 'GL_MAP01'));
  Assert.AreEqual(Cardinal(5), TNodesGlMapFinder.ChecksumOfText('LEVEL=MAP01'#10'CHECKSUM=5',
    'GL_LEVEL', 'GL_MAP01'));
  Assert.AreEqual(Cardinal(5), TNodesGlMapFinder.ChecksumOfText('LEVEL=GL_MAP01'#10'CHECKSUM=5',
    'GL_LEVEL', 'GL_MAP01'));
end;

procedure TTestNodesGlMapFinder.TestIlBuilderEIlTempoNonDovrebberoDisturbare;
begin
  Assert.AreEqual(Cardinal(99), TNodesGlMapFinder.ChecksumOfText(
    'BUILDER=glBSP 2.24'#13#10'TIME=Mon Jan 01'#13#10#13#10'CHECKSUM=99'#13#10, 'GL_MAP01', 'GL_MAP01'));
end;

procedure TTestNodesGlMapFinder.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesGlMapFinder.Create(nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesGlMapFinder);

end.
