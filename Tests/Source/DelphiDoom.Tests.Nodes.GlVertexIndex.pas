{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the vertex of a GL seg             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.GlVertexIndex;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Nodes.GlVertexIndex;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesGlVertexIndex = class(TObject)
  public
    [Test]
    [TestCase('V1', '1')]
    [TestCase('V2', '2')]
    procedure TestFinoAllaV2IlBit15DovrebbeIndicareUnVerticeGl(AVersion: Integer);
    [Test]
    [TestCase('V3', '3')]
    [TestCase('V4', '4')]
    procedure TestNellaV3ENellaV4IlBit30DovrebbeIndicareUnVerticeGl(AVersion: Integer);
    [Test]
    procedure TestNellaV5IlBit31DovrebbeIndicareUnVerticeGl;
    [Test]
    [TestCase('V2', '2,1234')]
    [TestCase('V3', '3,32768')]
    [TestCase('V5', '5,1073741824')]
    procedure TestUnNumeroSenzaIlBitDovrebbeEssereUnVerticeDellaMappa(AVersion, ANumber: Integer);
    [Test]
    procedure TestNellaV2IlBit30NonDovrebbeContare;
    [Test]
    procedure TestUnaVersioneOltreLaQuintaDovrebbeDareIlNumeroInvariato;
  end;

implementation

const
  FIRST_GL_VERTEX = 1000;

{ TTestNodesGlVertexIndex }

procedure TTestNodesGlVertexIndex.TestFinoAllaV2IlBit15DovrebbeIndicareUnVerticeGl(AVersion: Integer);
begin
  Assert.AreEqual(FIRST_GL_VERTEX + 7, TNodesGlVertexIndex.Resolve(AVersion, $8007, FIRST_GL_VERTEX));
end;

procedure TTestNodesGlVertexIndex.TestNellaV3ENellaV4IlBit30DovrebbeIndicareUnVerticeGl(AVersion: Integer);
begin
  Assert.AreEqual(FIRST_GL_VERTEX + 70000, TNodesGlVertexIndex.Resolve(AVersion, (1 shl 30) or 70000,
    FIRST_GL_VERTEX));
end;

procedure TTestNodesGlVertexIndex.TestNellaV5IlBit31DovrebbeIndicareUnVerticeGl;
begin
  // il numero letto da un LongWord con il bit 31 diventa negativo come Integer
  Assert.AreEqual(FIRST_GL_VERTEX + 12345, TNodesGlVertexIndex.Resolve(5, Integer(Cardinal($80000000) or 12345),
    FIRST_GL_VERTEX));
end;

procedure TTestNodesGlVertexIndex.TestUnNumeroSenzaIlBitDovrebbeEssereUnVerticeDellaMappa(AVersion,
  ANumber: Integer);
begin
  Assert.AreEqual(ANumber, TNodesGlVertexIndex.Resolve(AVersion, ANumber, FIRST_GL_VERTEX));
end;

procedure TTestNodesGlVertexIndex.TestNellaV2IlBit30NonDovrebbeContare;
begin
  Assert.AreEqual(1 shl 30, TNodesGlVertexIndex.Resolve(2, 1 shl 30, FIRST_GL_VERTEX));
end;

procedure TTestNodesGlVertexIndex.TestUnaVersioneOltreLaQuintaDovrebbeDareIlNumeroInvariato;
begin
  Assert.AreEqual($8007, TNodesGlVertexIndex.Resolve(6, $8007, FIRST_GL_VERTEX));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesGlVertexIndex);

end.
