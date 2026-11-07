{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - version of the GL nodes            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.GlDetector;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.GlDetector, DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesGlDetector = class(TObject)
  strict private
    FSource: TFakeLumpSource;
    FRef: INodesLumpSource;
    FDetector: INodesGlDetector;
    procedure AddGlLumps(AVertMagic, ASegsMagic: Cardinal);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestDovrebbeRiconoscereLaVersioneDue;
    [Test]
    procedure TestDovrebbeRiconoscereLaVersioneTreDalMagicDeiSeg;
    [Test]
    procedure TestDovrebbeRiconoscereLaVersioneQuattro;
    [Test]
    procedure TestDovrebbeRiconoscereLaVersioneCinque;
    [Test]
    procedure TestIVerticiSenzaMagicDovrebberoDareZero;
    [Test]
    procedure TestUnNomeSbagliatoDovrebbeDareZero;
    [Test]
    procedure TestUnLumpMancanteDovrebbeDareZero;
    [Test]
    procedure TestUnaBaseNegativaODopoLaFineDovrebbeDareZero;
    [Test]
    procedure TestIVerticiCortiDovrebberoDareZeroSenzaLeggereOltre;
    [Test]
    procedure TestIlNomeNonDovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
    [Test]
    procedure TestDovrebbeLeggereIlWadDiProvaDiGlbsp;
  end;

implementation

function MagicBytes(AMagic: Cardinal): TBytes;
begin
  SetLength(Result, 8);
  Move(AMagic, Result[0], 4);
end;

{ TTestNodesGlDetector }

procedure TTestNodesGlDetector.Setup;
begin
  FSource := TFakeLumpSource.Create;
  FRef := FSource;
  FDetector := TNodesGlDetector.Create(FRef);
end;

procedure TTestNodesGlDetector.AddGlLumps(AVertMagic, ASegsMagic: Cardinal);
begin
  FSource.Add('GL_MAP01');
  FSource.Add('GL_VERT', MagicBytes(AVertMagic));
  FSource.Add('GL_SEGS', MagicBytes(ASegsMagic));
  FSource.Add('GL_SSECT');
  FSource.Add('GL_NODES');
end;

procedure TTestNodesGlDetector.TestDovrebbeRiconoscereLaVersioneDue;
begin
  AddGlLumps(NODES_GL_MAGIC_V2, 0);
  Assert.AreEqual(2, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestDovrebbeRiconoscereLaVersioneTreDalMagicDeiSeg;
begin
  AddGlLumps(NODES_GL_MAGIC_V2, NODES_GL_MAGIC_V3);
  Assert.AreEqual(3, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestDovrebbeRiconoscereLaVersioneQuattro;
begin
  AddGlLumps(NODES_GL_MAGIC_V4, 0);
  Assert.AreEqual(4, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestDovrebbeRiconoscereLaVersioneCinque;
begin
  AddGlLumps(NODES_GL_MAGIC_V5, 0);
  Assert.AreEqual(5, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestIVerticiSenzaMagicDovrebberoDareZero;
begin
  // V1: come il vecchio codice, non e' riconosciuta
  AddGlLumps(0, 0);
  Assert.AreEqual(0, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestUnNomeSbagliatoDovrebbeDareZero;
begin
  FSource.Add('GL_MAP01');
  FSource.Add('GL_VERT', MagicBytes(NODES_GL_MAGIC_V2));
  FSource.Add('GL_SEGZ', MagicBytes(0));
  FSource.Add('GL_SSECT');
  FSource.Add('GL_NODES');
  Assert.AreEqual(0, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestUnLumpMancanteDovrebbeDareZero;
begin
  FSource.Add('GL_MAP01');
  FSource.Add('GL_VERT', MagicBytes(NODES_GL_MAGIC_V2));
  FSource.Add('GL_SEGS');
  FSource.Add('GL_SSECT');
  Assert.AreEqual(0, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestUnaBaseNegativaODopoLaFineDovrebbeDareZero;
begin
  AddGlLumps(NODES_GL_MAGIC_V2, 0);
  Assert.AreEqual(0, FDetector.DetectVersion(-1));
  Assert.AreEqual(0, FDetector.DetectVersion(2));
  Assert.AreEqual(0, FDetector.DetectVersion(100));
end;

procedure TTestNodesGlDetector.TestIVerticiCortiDovrebberoDareZeroSenzaLeggereOltre;
begin
  FSource.Add('GL_MAP01');
  FSource.Add('GL_VERT', TBytes.Create(1, 2));
  FSource.Add('GL_SEGS');
  FSource.Add('GL_SSECT');
  FSource.Add('GL_NODES');
  Assert.AreEqual(0, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestIlNomeNonDovrebbeDistinguereLeMaiuscole;
begin
  FSource.Add('gl_map01');
  FSource.Add('gl_vert', MagicBytes(NODES_GL_MAGIC_V5));
  FSource.Add('Gl_Segs');
  FSource.Add('GL_ssect');
  FSource.Add('GL_NODES');
  Assert.AreEqual(5, FDetector.DetectVersion(0));
end;

procedure TTestNodesGlDetector.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesGlDetector.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestNodesGlDetector.TestDovrebbeLeggereIlWadDiProvaDiGlbsp;
begin
  // glbsp_map01_normal.wad: i dieci lump della mappa e poi GL_MAP01 con i suoi quattro
  FSource.AddWad(TNodesTestData.ReadFile('glbsp_map01_normal.wad'));
  Assert.AreEqual(2, FDetector.DetectVersion(11));
  Assert.AreEqual(0, FDetector.DetectVersion(0));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesGlDetector);

end.
