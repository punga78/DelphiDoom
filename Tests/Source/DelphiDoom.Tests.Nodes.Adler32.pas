{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the Adler-32 checksum              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.Adler32;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Adler32, DelphiDoom.Nodes.Intf,
  DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesAdler32 = class(TObject)
  public
    [Test]
    procedure TestDovrebbeDareIlValoreNotoDiWikipedia;
    [Test]
    procedure TestSenzaDatiDovrebbeDareUno;
    [Test]
    procedure TestPiuBufferDovrebberoEssereComeUnoSolo;
    [Test]
    procedure TestIlChecksumDiUnaMappaDovrebbeUnireVertexesELinedefsInQuestOrdine;
    [Test]
    procedure TestIlChecksumDiUnaMappaConLumpGrandiNonDovrebbeTroncare;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

function Ascii(const AText: string): TBytes;
begin
  Result := TEncoding.ASCII.GetBytes(AText);
end;

{ TTestNodesAdler32 }

procedure TTestNodesAdler32.TestDovrebbeDareIlValoreNotoDiWikipedia;
begin
  Assert.AreEqual(Cardinal($11E60398), TNodesAdler32.OfBuffers([Ascii('Wikipedia')]));
end;

procedure TTestNodesAdler32.TestSenzaDatiDovrebbeDareUno;
begin
  Assert.AreEqual(Cardinal(1), TNodesAdler32.OfBuffers([]));
end;

procedure TTestNodesAdler32.TestPiuBufferDovrebberoEssereComeUnoSolo;
begin
  Assert.AreEqual(TNodesAdler32.OfBuffers([Ascii('Wikipedia')]),
    TNodesAdler32.OfBuffers([Ascii('Wiki'), nil, Ascii('pedia')]));
end;

procedure TTestNodesAdler32.TestIlChecksumDiUnaMappaDovrebbeUnireVertexesELinedefsInQuestOrdine;
var
  LSource: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  LSource := TFakeLumpSource.Create;
  LRef := LSource;
  LSource.Add('MAP01');
  LSource.Add('THINGS', Ascii('tt'));
  LSource.Add('LINEDEFS', Ascii('pedia'));
  LSource.Add('SIDEDEFS', Ascii('ss'));
  LSource.Add('VERTEXES', Ascii('Wiki'));
  Assert.AreEqual(Cardinal($11E60398), TNodesAdler32.OfMap(LRef, 0));
end;

procedure TTestNodesAdler32.TestIlChecksumDiUnaMappaConLumpGrandiNonDovrebbeTroncare;
var
  LSource: TFakeLumpSource;
  LRef: INodesLumpSource;
  LBig: TBytes;
  LIndex: Integer;
begin
  LSource := TFakeLumpSource.Create;
  LRef := LSource;
  SetLength(LBig, 200000);
  for LIndex := 0 to High(LBig) do
    LBig[LIndex] := 255;
  LSource.Add('MAP01');
  LSource.Add('THINGS');
  LSource.Add('LINEDEFS', LBig);
  LSource.Add('SIDEDEFS');
  LSource.Add('VERTEXES', LBig);
  // 400000 byte a 255: A = 1 + 255 n mod 65521 (calcolo indipendente)
  Assert.AreEqual(TNodesAdler32.OfBuffers([LBig, LBig]), TNodesAdler32.OfMap(LRef, 0));
  Assert.AreEqual(Cardinal((1 + Cardinal((Int64(255) * 400000) mod 65521)) mod 65521),
    TNodesAdler32.OfMap(LRef, 0) and $FFFF);
end;

procedure TTestNodesAdler32.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesAdler32.OfMap(nil, 0);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesAdler32);

end.
