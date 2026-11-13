{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the GL lumps                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.GlParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.GlParser;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesGlParser = class(TObject)
  public
    [Test]
    procedure TestIVerticiDellaVersioneUnoDovrebberoEssereAVirgolaFissa;
    [Test]
    procedure TestIVerticiDallaVersioneDueDovrebberoSaltareIlMagic;
    [Test]
    procedure TestUnLumpDiVerticiSenzaMagicNonDovrebbeDareNegativi;
    [Test]
    procedure TestISegDellaVersioneDueDovrebberoEssereAllargati;
    [Test]
    procedure TestISegDellaVersioneTreDovrebberoSaltareIlMagic;
    [Test]
    procedure TestISegDellaVersioneQuattroECinqueNonHannoMagic;
    [Test]
    procedure TestISubsectorDellaVersioneDueDovrebberoEssereAllargati;
    [Test]
    procedure TestISubsectorDellaVersioneTreDovrebberoSaltareIlMagic;
    [Test]
    procedure TestISubsectorDallaQuattroNonHannoMagic;
    [Test]
    procedure TestINodiPrimaDellaQuattroDovrebberoAllargareIFigli;
    [Test]
    procedure TestINodiDallaQuattroDovrebberoEssereCopiati;
    [Test]
    procedure TestUnLumpVuotoDovrebbeDareUnArrayVuoto;
  end;

implementation

{ TTestNodesGlParser }

procedure TTestNodesGlParser.TestIVerticiDellaVersioneUnoDovrebberoEssereAVirgolaFissa;
var
  LBytes: TBytes;
  LVertexes: TArray<TNodesGlVertex>;
begin
  SetLength(LBytes, 8);
  PSmallInt(@LBytes[0])^ := 5;
  PSmallInt(@LBytes[2])^ := -6;
  PSmallInt(@LBytes[4])^ := 32767;
  PSmallInt(@LBytes[6])^ := -32768;
  LVertexes := TNodesGlParser.ParseVertexes(LBytes, 1);
  Assert.AreEqual<Integer>(2, Length(LVertexes));
  Assert.AreEqual(5 * 65536, LVertexes[0].X);
  Assert.AreEqual(-6 * 65536, LVertexes[0].Y);
  Assert.AreEqual(32767 * 65536, LVertexes[1].X);
  Assert.AreEqual(Integer(-32768) * 65536, LVertexes[1].Y);
end;

procedure TTestNodesGlParser.TestIVerticiDallaVersioneDueDovrebberoSaltareIlMagic;
var
  LBytes: TBytes;
  LVertexes: TArray<TNodesGlVertex>;
  LVersion: Integer;
begin
  SetLength(LBytes, 4 + 16);
  PCardinal(@LBytes[0])^ := NODES_GL_MAGIC_V2;
  PInteger(@LBytes[4])^ := 100000;
  PInteger(@LBytes[8])^ := -200000;
  PInteger(@LBytes[12])^ := 7;
  PInteger(@LBytes[16])^ := 8;
  for LVersion := 2 to 5 do
  begin
    LVertexes := TNodesGlParser.ParseVertexes(LBytes, LVersion);
    Assert.AreEqual<Integer>(2, Length(LVertexes));
    Assert.AreEqual(100000, LVertexes[0].X);
    Assert.AreEqual(-200000, LVertexes[0].Y);
    Assert.AreEqual(8, LVertexes[1].Y);
  end;
end;

procedure TTestNodesGlParser.TestUnLumpDiVerticiSenzaMagicNonDovrebbeDareNegativi;
begin
  Assert.AreEqual<Integer>(0, Length(TNodesGlParser.ParseVertexes(TBytes.Create(1, 2), 2)));
end;

procedure TTestNodesGlParser.TestISegDellaVersioneDueDovrebberoEssereAllargati;
var
  LBytes: TBytes;
  LSegs: TArray<TNodesGlSeg>;
begin
  SetLength(LBytes, 20);
  PWord(@LBytes[0])^ := $8001;
  PWord(@LBytes[2])^ := 2;
  PWord(@LBytes[4])^ := $FFFF;
  PWord(@LBytes[6])^ := 1;
  PWord(@LBytes[8])^ := 9;
  PWord(@LBytes[10])^ := 3;
  PWord(@LBytes[12])^ := $8002;
  PWord(@LBytes[14])^ := 7;
  PWord(@LBytes[16])^ := 0;
  PWord(@LBytes[18])^ := $FFFF;
  LSegs := TNodesGlParser.ParseSegs(LBytes, 2);
  Assert.AreEqual<Integer>(2, Length(LSegs));
  Assert.AreEqual(Cardinal($8001), LSegs[0].StartVertex);
  Assert.AreEqual(Word($FFFF), LSegs[0].Linedef);
  Assert.AreEqual(Cardinal(9), LSegs[0].PartnerSeg);
  Assert.AreEqual(Cardinal($FFFF), LSegs[1].PartnerSeg);
end;

procedure TTestNodesGlParser.TestISegDellaVersioneTreDovrebberoSaltareIlMagic;
var
  LBytes: TBytes;
  LSegs: TArray<TNodesGlSeg>;
begin
  SetLength(LBytes, 4 + 16);
  PCardinal(@LBytes[0])^ := NODES_GL_MAGIC_V3;
  PCardinal(@LBytes[4])^ := $40000005;
  PCardinal(@LBytes[8])^ := 6;
  PWord(@LBytes[12])^ := 11;
  PWord(@LBytes[14])^ := 1;
  PCardinal(@LBytes[16])^ := 12;
  LSegs := TNodesGlParser.ParseSegs(LBytes, 3);
  Assert.AreEqual<Integer>(1, Length(LSegs));
  Assert.AreEqual(Cardinal($40000005), LSegs[0].StartVertex);
  Assert.AreEqual(Word(11), LSegs[0].Linedef);
  Assert.AreEqual(Cardinal(12), LSegs[0].PartnerSeg);
end;

procedure TTestNodesGlParser.TestISegDellaVersioneQuattroECinqueNonHannoMagic;
var
  LBytes: TBytes;
  LVersion: Integer;
  LSegs: TArray<TNodesGlSeg>;
begin
  SetLength(LBytes, 16);
  PCardinal(@LBytes[0])^ := $80000005;
  PCardinal(@LBytes[4])^ := 6;
  for LVersion := 4 to 5 do
  begin
    LSegs := TNodesGlParser.ParseSegs(LBytes, LVersion);
    Assert.AreEqual<Integer>(1, Length(LSegs));
    Assert.AreEqual(Cardinal($80000005), LSegs[0].StartVertex);
  end;
end;

procedure TTestNodesGlParser.TestISubsectorDellaVersioneDueDovrebberoEssereAllargati;
var
  LBytes: TBytes;
  LSubsectors: TArray<TNodesGlSubsector>;
begin
  SetLength(LBytes, 8);
  PWord(@LBytes[0])^ := 4;
  PWord(@LBytes[2])^ := 10;
  PWord(@LBytes[4])^ := 3;
  PWord(@LBytes[6])^ := $FFFE;
  LSubsectors := TNodesGlParser.ParseSubsectors(LBytes, 2);
  Assert.AreEqual<Integer>(2, Length(LSubsectors));
  Assert.AreEqual(Cardinal(4), LSubsectors[0].Count);
  Assert.AreEqual(Cardinal($FFFE), LSubsectors[1].FirstSeg);
end;

procedure TTestNodesGlParser.TestISubsectorDellaVersioneTreDovrebberoSaltareIlMagic;
var
  LBytes: TBytes;
  LSubsectors: TArray<TNodesGlSubsector>;
begin
  SetLength(LBytes, 4 + 8);
  PCardinal(@LBytes[0])^ := NODES_GL_MAGIC_V3;
  PCardinal(@LBytes[4])^ := 70000;
  PCardinal(@LBytes[8])^ := 80000;
  LSubsectors := TNodesGlParser.ParseSubsectors(LBytes, 3);
  Assert.AreEqual<Integer>(1, Length(LSubsectors));
  Assert.AreEqual(Cardinal(70000), LSubsectors[0].Count);
  Assert.AreEqual(Cardinal(80000), LSubsectors[0].FirstSeg);
end;

procedure TTestNodesGlParser.TestISubsectorDallaQuattroNonHannoMagic;
var
  LBytes: TBytes;
  LSubsectors: TArray<TNodesGlSubsector>;
begin
  SetLength(LBytes, 8);
  PCardinal(@LBytes[0])^ := 5;
  PCardinal(@LBytes[4])^ := 6;
  LSubsectors := TNodesGlParser.ParseSubsectors(LBytes, 5);
  Assert.AreEqual<Integer>(1, Length(LSubsectors));
  Assert.AreEqual(Cardinal(5), LSubsectors[0].Count);
end;

procedure TTestNodesGlParser.TestINodiPrimaDellaQuattroDovrebberoAllargareIFigli;
var
  LBytes: TBytes;
  LNode: TNodesGlNode1;
  LNodes: TArray<TNodesGlNode>;
begin
  FillChar(LNode, SizeOf(LNode), 0);
  LNode.X := -3;
  LNode.DeltaY := 9;
  LNode.RightBoundingBox[2] := -77;
  LNode.LeftBoundingBox[3] := 88;
  LNode.RightChild := $8000 or 12;
  LNode.LeftChild := 5;
  SetLength(LBytes, SizeOf(LNode));
  Move(LNode, LBytes[0], SizeOf(LNode));
  LNodes := TNodesGlParser.ParseNodes(LBytes, 2);
  Assert.AreEqual<Integer>(1, Length(LNodes));
  Assert.AreEqual(SmallInt(-3), LNodes[0].X);
  Assert.AreEqual(SmallInt(9), LNodes[0].DeltaY);
  Assert.AreEqual(SmallInt(-77), LNodes[0].RightBoundingBox[2]);
  Assert.AreEqual(SmallInt(88), LNodes[0].LeftBoundingBox[3]);
  Assert.AreEqual(NODES_CHILD_SUBSECTOR_V5 or 12, LNodes[0].RightChild);
  Assert.AreEqual(Cardinal(5), LNodes[0].LeftChild);
end;

procedure TTestNodesGlParser.TestINodiDallaQuattroDovrebberoEssereCopiati;
var
  LBytes: TBytes;
  LNode: TNodesGlNode;
  LNodes: TArray<TNodesGlNode>;
  LVersion: Integer;
begin
  FillChar(LNode, SizeOf(LNode), 0);
  LNode.X := 100;
  LNode.RightChild := NODES_CHILD_SUBSECTOR_V5 or 70000;
  LNode.LeftChild := 65536;
  SetLength(LBytes, SizeOf(LNode) * 2);
  Move(LNode, LBytes[0], SizeOf(LNode));
  Move(LNode, LBytes[SizeOf(LNode)], SizeOf(LNode));
  for LVersion := 4 to 5 do
  begin
    LNodes := TNodesGlParser.ParseNodes(LBytes, LVersion);
    Assert.AreEqual<Integer>(2, Length(LNodes));
    Assert.AreEqual(NODES_CHILD_SUBSECTOR_V5 or 70000, LNodes[1].RightChild);
    Assert.AreEqual(Cardinal(65536), LNodes[1].LeftChild);
  end;
end;

procedure TTestNodesGlParser.TestUnLumpVuotoDovrebbeDareUnArrayVuoto;
var
  LVersion: Integer;
begin
  for LVersion := 1 to 5 do
  begin
    Assert.AreEqual<Integer>(0, Length(TNodesGlParser.ParseVertexes(nil, LVersion)));
    Assert.AreEqual<Integer>(0, Length(TNodesGlParser.ParseSegs(nil, LVersion)));
    Assert.AreEqual<Integer>(0, Length(TNodesGlParser.ParseSubsectors(nil, LVersion)));
    Assert.AreEqual<Integer>(0, Length(TNodesGlParser.ParseNodes(nil, LVersion)));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesGlParser);

end.
