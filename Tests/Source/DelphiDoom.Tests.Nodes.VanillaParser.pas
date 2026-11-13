{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - SEGS, SSECTORS and NODES           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.VanillaParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.VanillaParser,
  DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesVanillaParser = class(TObject)
  public
    [Test]
    procedure TestISegDovrebberoAvereTuttiICampi;
    [Test]
    procedure TestISubsectorDovrebberoAvereTuttiICampi;
    [Test]
    procedure TestINodiDovrebberoAvereTuttiICampi;
    [Test]
    procedure TestUnRecordParzialeInFondoDovrebbeEssereIgnorato;
    [Test]
    procedure TestUnLumpVuotoDovrebbeDareUnArrayVuoto;
    [Test]
    procedure TestIlWadDiProvaDovrebbeDareIConteggiDelVecchioCodice;
  end;

implementation

{ TTestNodesVanillaParser }

procedure TTestNodesVanillaParser.TestISegDovrebberoAvereTuttiICampi;
var
  LBytes: TBytes;
  LSegs: TArray<TNodesVanillaSeg>;
begin
  SetLength(LBytes, 24);
  PSmallInt(@LBytes[0])^ := 1;
  PSmallInt(@LBytes[2])^ := 2;
  PSmallInt(@LBytes[4])^ := -16384;
  PSmallInt(@LBytes[6])^ := 300;
  PSmallInt(@LBytes[8])^ := 1;
  PSmallInt(@LBytes[10])^ := -5;
  PSmallInt(@LBytes[12])^ := 9;
  LSegs := TNodesVanillaParser.ParseSegs(LBytes);
  Assert.AreEqual<Integer>(2, Length(LSegs));
  Assert.AreEqual(SmallInt(1), LSegs[0].Vertex1);
  Assert.AreEqual(SmallInt(2), LSegs[0].Vertex2);
  Assert.AreEqual(SmallInt(-16384), LSegs[0].Angle);
  Assert.AreEqual(SmallInt(300), LSegs[0].Linedef);
  Assert.AreEqual(SmallInt(1), LSegs[0].Side);
  Assert.AreEqual(SmallInt(-5), LSegs[0].Offset);
  Assert.AreEqual(SmallInt(9), LSegs[1].Vertex1);
end;

procedure TTestNodesVanillaParser.TestISubsectorDovrebberoAvereTuttiICampi;
var
  LBytes: TBytes;
  LSubsectors: TArray<TNodesVanillaSubsector>;
begin
  SetLength(LBytes, 8);
  PWord(@LBytes[0])^ := 4;
  PWord(@LBytes[2])^ := 60000;
  PWord(@LBytes[4])^ := 5;
  PWord(@LBytes[6])^ := 6;
  LSubsectors := TNodesVanillaParser.ParseSubsectors(LBytes);
  Assert.AreEqual<Integer>(2, Length(LSubsectors));
  Assert.AreEqual(Word(4), LSubsectors[0].SegCount);
  Assert.AreEqual(Word(60000), LSubsectors[0].FirstSeg);
  Assert.AreEqual(Word(6), LSubsectors[1].FirstSeg);
end;

procedure TTestNodesVanillaParser.TestINodiDovrebberoAvereTuttiICampi;
var
  LBytes: TBytes;
  LNodes: TArray<TNodesVanillaNode>;
  LIndex: Integer;
begin
  SetLength(LBytes, 28);
  for LIndex := 0 to 13 do
    PSmallInt(@LBytes[LIndex * 2])^ := LIndex + 1;
  PWord(@LBytes[24])^ := $8001;
  PWord(@LBytes[26])^ := 7;
  LNodes := TNodesVanillaParser.ParseNodes(LBytes);
  Assert.AreEqual<Integer>(1, Length(LNodes));
  Assert.AreEqual(SmallInt(1), LNodes[0].X);
  Assert.AreEqual(SmallInt(4), LNodes[0].DeltaY);
  Assert.AreEqual(SmallInt(5), LNodes[0].BoundingBox[0, 0]);
  Assert.AreEqual(SmallInt(12), LNodes[0].BoundingBox[1, 3]);
  Assert.AreEqual(Word($8001), LNodes[0].Children[0]);
  Assert.AreEqual(Word(7), LNodes[0].Children[1]);
end;

procedure TTestNodesVanillaParser.TestUnRecordParzialeInFondoDovrebbeEssereIgnorato;
begin
  Assert.AreEqual<Integer>(1, Length(TNodesVanillaParser.ParseSegs(TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 3))));
  Assert.AreEqual<Integer>(1, Length(TNodesVanillaParser.ParseSubsectors(TBytes.Create(1, 2, 3, 4, 5))));
  Assert.AreEqual<Integer>(0, Length(TNodesVanillaParser.ParseNodes(TBytes.Create(1, 2, 3))));
end;

procedure TTestNodesVanillaParser.TestUnLumpVuotoDovrebbeDareUnArrayVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(TNodesVanillaParser.ParseSegs(nil)));
  Assert.AreEqual<Integer>(0, Length(TNodesVanillaParser.ParseSubsectors(nil)));
  Assert.AreEqual<Integer>(0, Length(TNodesVanillaParser.ParseNodes(nil)));
end;

procedure TTestNodesVanillaParser.TestIlWadDiProvaDovrebbeDareIConteggiDelVecchioCodice;
var
  LSource: TFakeLumpSource;
  LRef: IInterface;
  LSegs: TArray<TNodesVanillaSeg>;
begin
  // SEGS 26796 / 12, SSECTORS 2792 / 4, NODES 19516 / 28 (glbsp_map01.wad)
  LSource := TFakeLumpSource.Create;
  LRef := LSource;
  LSource.AddWad(TNodesTestData.ReadFile('glbsp_map01.wad'));
  Assert.AreEqual<Integer>(2233, Length(TNodesVanillaParser.ParseSegs(LSource.ReadLump(5))));
  Assert.AreEqual<Integer>(698, Length(TNodesVanillaParser.ParseSubsectors(LSource.ReadLump(6))));
  Assert.AreEqual<Integer>(697, Length(TNodesVanillaParser.ParseNodes(LSource.ReadLump(7))));
  LSegs := TNodesVanillaParser.ParseSegs(LSource.ReadLump(5));
  Assert.AreEqual(TNodesTestData.Fingerprint(LSource.ReadLump(5)),
    TNodesTestData.FingerprintOf(LSegs[0], Length(LSegs) * SizeOf(TNodesVanillaSeg)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesVanillaParser);

end.
