{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the GWA reader                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.GwaReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.GwaReader, DelphiDoom.Nodes.PwadAssembler, DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesGwaReader = class(TObject)
  strict private
    function ReferenceBytes: TBytes;
    function Describe(const AGwa: INodesGwa; out AVertexes, ASegs, ASubsectors, ANodes: string): string;
    function MakeWad(AVersion: Integer): TBytes;
  public
    [Test]
    procedure TestDovrebbeLeggereIlGwaDiGlbspComeIlVecchioCodice;
    [Test]
    procedure TestIlVecchioCodiceDavaLaVersioneDue;
    [Test]
    procedure TestLaVersioneTreDovrebbeDareGliStessiRecordDellaDue;
    [Test]
    procedure TestLaVersioneQuattroDovrebbeDareGliStessiRecordDellaDue;
    [Test]
    procedure TestLaVersioneCinqueDovrebbeDareGliStessiRecordDellaDue;
    [Test]
    procedure TestIFigliSottoranodoDovrebberoAvereIlFlagDellaVersioneCinque;
    [Test]
    procedure TestUnGwaSenzaMagicDovrebbeEssereLaVersioneZeroConVerticiASedici;
    [Test]
    procedure TestUnFileTroppoCortoDovrebbeDareEccezione;
    [Test]
    procedure TestPiuDiDieciLumpDovrebbeDareEccezione;
    [Test]
    procedure TestZeroLumpDovrebbeDareEccezione;
    [Test]
    procedure TestUnaDirectoryFuoriDalFileDovrebbeDareEccezione;
    [Test]
    procedure TestUnLumpFuoriDalFileDovrebbeDareEccezione;
    [Test]
    procedure TestUnLumpGlVertDiMenoDiQuattroByteNonDovrebbeAvereMagic;
    [Test]
    procedure TestIlNomeDeiLumpNonDovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure TestUnLumpCheFinisceATrattoNonDovrebbeDareIlRecordParziale;
  end;

implementation

const
  V1_SUBSECTOR_FLAG = $8000;

{ TTestNodesGwaReader }

function TTestNodesGwaReader.ReferenceBytes: TBytes;
begin
  Result := TNodesTestData.ReadFile('glbsp_map01.gwa');
end;

function TTestNodesGwaReader.Describe(const AGwa: INodesGwa; out AVertexes, ASegs, ASubsectors,
  ANodes: string): string;
begin
  AVertexes := Format('%d:%s', [Length(AGwa.GlVertexes),
    TNodesTestData.FingerprintOf(AGwa.GlVertexes[0], Length(AGwa.GlVertexes) * SizeOf(TNodesGlVertex))]);
  ASegs := Format('%d:%s', [Length(AGwa.Segs),
    TNodesTestData.FingerprintOf(AGwa.Segs[0], Length(AGwa.Segs) * SizeOf(TNodesGlSeg))]);
  ASubsectors := Format('%d:%s', [Length(AGwa.Subsectors),
    TNodesTestData.FingerprintOf(AGwa.Subsectors[0], Length(AGwa.Subsectors) * SizeOf(TNodesGlSubsector))]);
  ANodes := Format('%d:%s', [Length(AGwa.Nodes),
    TNodesTestData.FingerprintOf(AGwa.Nodes[0], Length(AGwa.Nodes) * SizeOf(TNodesGlNode))]);
  Result := IntToStr(AGwa.Version);
end;

// the GWA of glBSP (V2) rewritten in the other versions of the format
function TTestNodesGwaReader.MakeWad(AVersion: Integer): TBytes;
var
  LSource: TFakeLumpSource;
  LRef: INodesLumpSource;
  LGwa: INodesGwa;
  LAssembler: TNodesPwadAssembler;
  LVert: TBytes;
  LSegs: TBytes;
  LSubsectors: TBytes;
  LNodes: TBytes;
  LIndex: Integer;
  LMagic: Cardinal;
  LSeg: TNodesGlSeg;
  LNode: TNodesGlNode;
  LFlag: Cardinal;
  LStart: Integer;

  function Widen(AVertex: Cardinal): Cardinal;
  begin
    if AVertex and $8000 <> 0 then
      Result := (AVertex and $7FFF) or LFlag
    else
      Result := AVertex;
  end;

  function WidenChild(AChild: Cardinal): Cardinal;
  begin
    if AChild and NODES_CHILD_SUBSECTOR_V5 <> 0 then
      Result := (AChild and not NODES_CHILD_SUBSECTOR_V5) or NODES_CHILD_SUBSECTOR_V1
    else
      Result := AChild;
  end;

begin
  LSource := TFakeLumpSource.Create;
  LRef := LSource;
  LSource.AddWad(ReferenceBytes);
  LGwa := TNodesGwaReader.Read(ReferenceBytes);

  case AVersion of
    3: LMagic := NODES_GL_MAGIC_V2;
    4: LMagic := NODES_GL_MAGIC_V4;
  else
    LMagic := NODES_GL_MAGIC_V5;
  end;
  if AVersion = 5 then
    LFlag := Cardinal(1) shl 31
  else
    LFlag := Cardinal(1) shl 30;

  LStart := 0;
  if AVersion = 3 then
    LStart := 4;

  // GL_VERT: the magic number and the vertexes
  SetLength(LVert, 4 + Length(LGwa.GlVertexes) * SizeOf(TNodesGlVertex));
  Move(LMagic, LVert[0], 4);
  Move(LGwa.GlVertexes[0], LVert[4], Length(LVert) - 4);

  // GL_SEGS: 16 bytes records, V3 with its magic number
  SetLength(LSegs, LStart + Length(LGwa.Segs) * SizeOf(TNodesGlSeg));
  if AVersion = 3 then
  begin
    LMagic := NODES_GL_MAGIC_V3;
    Move(LMagic, LSegs[0], 4);
  end;
  for LIndex := 0 to High(LGwa.Segs) do
  begin
    LSeg := LGwa.Segs[LIndex];
    LSeg.StartVertex := Widen(LSeg.StartVertex);
    LSeg.EndVertex := Widen(LSeg.EndVertex);
    Move(LSeg, LSegs[LStart + LIndex * SizeOf(LSeg)], SizeOf(LSeg));
  end;

  SetLength(LSubsectors, LStart + Length(LGwa.Subsectors) * SizeOf(TNodesGlSubsector));
  if AVersion = 3 then
    Move(LMagic, LSubsectors[0], 4);
  Move(LGwa.Subsectors[0], LSubsectors[LStart], Length(LSubsectors) - LStart);

  if AVersion >= 4 then
  begin
    SetLength(LNodes, Length(LGwa.Nodes) * SizeOf(TNodesGlNode));
    Move(LGwa.Nodes[0], LNodes[0], Length(LNodes));
  end
  else
  begin
    // V1 nodes: 28 bytes, 16 bit children
    SetLength(LNodes, Length(LGwa.Nodes) * SizeOf(TNodesGlNode1));
    for LIndex := 0 to High(LGwa.Nodes) do
    begin
      LNode := LGwa.Nodes[LIndex];
      LNode.RightChild := WidenChild(LNode.RightChild);
      LNode.LeftChild := WidenChild(LNode.LeftChild);
      Move(LNode, LNodes[LIndex * SizeOf(TNodesGlNode1)], 24);
      PWord(@LNodes[LIndex * SizeOf(TNodesGlNode1) + 24])^ := Word(LNode.RightChild);
      PWord(@LNodes[LIndex * SizeOf(TNodesGlNode1) + 26])^ := Word(LNode.LeftChild);
    end;
  end;

  LAssembler := TNodesPwadAssembler.Create;
  try
    LAssembler.AddEmptyLump('GL_MAP01');
    LAssembler.AddLump('GL_VERT', LVert);
    LAssembler.AddLump('GL_SEGS', LSegs);
    LAssembler.AddLump('GL_SSECT', LSubsectors);
    LAssembler.AddLump('GL_NODES', LNodes);
    Result := LAssembler.Build;
  finally
    LAssembler.Free;
  end;
end;

procedure TTestNodesGwaReader.TestDovrebbeLeggereIlGwaDiGlbspComeIlVecchioCodice;
var
  LVertexes, LSegs, LSubsectors, LNodes: string;
begin
  Describe(TNodesGwaReader.Read(ReferenceBytes), LVertexes, LSegs, LSubsectors, LNodes);
  Assert.AreEqual(TNodesTestData.Golden('gwa_v2.golden.txt', 'vertexes'), LVertexes);
  Assert.AreEqual(TNodesTestData.Golden('gwa_v2.golden.txt', 'segs'), LSegs);
  Assert.AreEqual(TNodesTestData.Golden('gwa_v2.golden.txt', 'subsectors'), LSubsectors);
  Assert.AreEqual(TNodesTestData.Golden('gwa_v2.golden.txt', 'nodes'), LNodes);
end;

procedure TTestNodesGwaReader.TestIlVecchioCodiceDavaLaVersioneDue;
var
  LVertexes, LSegs, LSubsectors, LNodes: string;
begin
  Assert.AreEqual(TNodesTestData.Golden('gwa_v2.golden.txt', 'version'),
    Describe(TNodesGwaReader.Read(ReferenceBytes), LVertexes, LSegs, LSubsectors, LNodes));
  Assert.AreEqual('2', TNodesTestData.Golden('gwa_v2.golden.txt', 'version'));
end;

procedure TTestNodesGwaReader.TestLaVersioneTreDovrebbeDareGliStessiRecordDellaDue;
var
  LRef, LGwa: INodesGwa;
  LIndex: Integer;
begin
  LRef := TNodesGwaReader.Read(ReferenceBytes);
  LGwa := TNodesGwaReader.Read(MakeWad(3));
  Assert.AreEqual(3, LGwa.Version);
  Assert.AreEqual(Length(LRef.Segs), Length(LGwa.Segs));
  for LIndex := 0 to High(LRef.Segs) do
  begin
    Assert.AreEqual(LRef.Segs[LIndex].StartVertex and $7FFF, LGwa.Segs[LIndex].StartVertex and $3FFFFFFF);
    Assert.AreEqual(LRef.Segs[LIndex].StartVertex and $8000 <> 0,
      LGwa.Segs[LIndex].StartVertex and $40000000 <> 0);
    Assert.AreEqual(LRef.Segs[LIndex].Linedef, LGwa.Segs[LIndex].Linedef);
  end;
  Assert.AreEqual(Length(LRef.Subsectors), Length(LGwa.Subsectors));
  Assert.AreEqual(LRef.Subsectors[5].FirstSeg, LGwa.Subsectors[5].FirstSeg);
  Assert.AreEqual(Length(LRef.GlVertexes), Length(LGwa.GlVertexes));
  Assert.AreEqual(Length(LRef.Nodes), Length(LGwa.Nodes));
end;

procedure TTestNodesGwaReader.TestLaVersioneQuattroDovrebbeDareGliStessiRecordDellaDue;
var
  LRef, LGwa: INodesGwa;
  LIndex: Integer;
begin
  LRef := TNodesGwaReader.Read(ReferenceBytes);
  LGwa := TNodesGwaReader.Read(MakeWad(4));
  Assert.AreEqual(4, LGwa.Version);
  Assert.AreEqual(Length(LRef.Segs), Length(LGwa.Segs));
  for LIndex := 0 to High(LRef.Segs) do
    Assert.AreEqual(LRef.Segs[LIndex].EndVertex and $7FFF, LGwa.Segs[LIndex].EndVertex and $3FFFFFFF);
  Assert.AreEqual(Length(LRef.Subsectors), Length(LGwa.Subsectors));
  Assert.AreEqual(Length(LRef.Nodes), Length(LGwa.Nodes));
end;

procedure TTestNodesGwaReader.TestLaVersioneCinqueDovrebbeDareGliStessiRecordDellaDue;
var
  LRef, LGwa: INodesGwa;
  LIndex: Integer;
begin
  LRef := TNodesGwaReader.Read(ReferenceBytes);
  LGwa := TNodesGwaReader.Read(MakeWad(5));
  Assert.AreEqual(5, LGwa.Version);
  Assert.AreEqual(Length(LRef.Segs), Length(LGwa.Segs));
  for LIndex := 0 to High(LRef.Segs) do
  begin
    Assert.AreEqual(LRef.Segs[LIndex].StartVertex and $7FFF, LGwa.Segs[LIndex].StartVertex and $7FFFFFFF);
    Assert.AreEqual(LRef.Segs[LIndex].StartVertex and $8000 <> 0,
      LGwa.Segs[LIndex].StartVertex and $80000000 <> 0);
  end;
  for LIndex := 0 to High(LRef.Nodes) do
  begin
    Assert.AreEqual(LRef.Nodes[LIndex].RightChild, LGwa.Nodes[LIndex].RightChild);
    Assert.AreEqual(LRef.Nodes[LIndex].LeftChild, LGwa.Nodes[LIndex].LeftChild);
    Assert.AreEqual(LRef.Nodes[LIndex].X, LGwa.Nodes[LIndex].X);
  end;
end;

procedure TTestNodesGwaReader.TestIFigliSottoranodoDovrebberoAvereIlFlagDellaVersioneCinque;
var
  LGwa: INodesGwa;
  LIndex: Integer;
  LFound: Boolean;
begin
  LGwa := TNodesGwaReader.Read(ReferenceBytes);
  LFound := False;
  for LIndex := 0 to High(LGwa.Nodes) do
  begin
    // nessun figlio deve conservare il flag a 16 bit
    Assert.IsTrue(LGwa.Nodes[LIndex].RightChild and V1_SUBSECTOR_FLAG = 0);
    Assert.IsTrue(LGwa.Nodes[LIndex].LeftChild and V1_SUBSECTOR_FLAG = 0);
    if (LGwa.Nodes[LIndex].RightChild and NODES_CHILD_SUBSECTOR_V5 <> 0) or
       (LGwa.Nodes[LIndex].LeftChild and NODES_CHILD_SUBSECTOR_V5 <> 0) then
      LFound := True;
  end;
  Assert.IsTrue(LFound);
end;

procedure TTestNodesGwaReader.TestUnGwaSenzaMagicDovrebbeEssereLaVersioneZeroConVerticiASedici;
var
  LAssembler: TNodesPwadAssembler;
  LVert: TBytes;
  LGwa: INodesGwa;
begin
  // regressione: il vecchio codice leggeva i vertici V1 come coppie a 32 bit
  SetLength(LVert, 8);
  PSmallInt(@LVert[0])^ := 3;
  PSmallInt(@LVert[2])^ := -4;
  PSmallInt(@LVert[4])^ := -32768;
  PSmallInt(@LVert[6])^ := 32767;
  LAssembler := TNodesPwadAssembler.Create;
  try
    LAssembler.AddEmptyLump('GL_MAP01');
    LAssembler.AddLump('GL_VERT', LVert);
    LAssembler.AddEmptyLump('GL_SEGS');
    LAssembler.AddEmptyLump('GL_SSECT');
    LAssembler.AddEmptyLump('GL_NODES');
    LGwa := TNodesGwaReader.Read(LAssembler.Build);
  finally
    LAssembler.Free;
  end;
  Assert.AreEqual(0, LGwa.Version);
  Assert.AreEqual(2, Length(LGwa.GlVertexes));
  Assert.AreEqual(3 * 65536, LGwa.GlVertexes[0].X);
  Assert.AreEqual(-4 * 65536, LGwa.GlVertexes[0].Y);
  Assert.AreEqual(Integer(-32768) * 65536, LGwa.GlVertexes[1].X);
  Assert.AreEqual(32767 * 65536, LGwa.GlVertexes[1].Y);
end;

procedure TTestNodesGwaReader.TestUnFileTroppoCortoDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesGwaReader.Read(TBytes.Create(1, 2, 3));
    end, ENodesException);
end;

procedure TTestNodesGwaReader.TestPiuDiDieciLumpDovrebbeDareEccezione;
var
  LBytes: TBytes;
begin
  LBytes := Copy(ReferenceBytes);
  PInteger(@LBytes[4])^ := 11;
  Assert.WillRaise(
    procedure
    begin
      TNodesGwaReader.Read(LBytes);
    end, ENodesException);
end;

procedure TTestNodesGwaReader.TestZeroLumpDovrebbeDareEccezione;
var
  LBytes: TBytes;
begin
  LBytes := Copy(ReferenceBytes);
  PInteger(@LBytes[4])^ := 0;
  Assert.WillRaise(
    procedure
    begin
      TNodesGwaReader.Read(LBytes);
    end, ENodesException);
end;

procedure TTestNodesGwaReader.TestUnaDirectoryFuoriDalFileDovrebbeDareEccezione;
var
  LBytes: TBytes;
begin
  LBytes := Copy(ReferenceBytes);
  PInteger(@LBytes[8])^ := Length(LBytes) - 20;
  Assert.WillRaise(
    procedure
    begin
      TNodesGwaReader.Read(LBytes);
    end, ENodesException);
end;

procedure TTestNodesGwaReader.TestUnLumpFuoriDalFileDovrebbeDareEccezione;
var
  LBytes: TBytes;
  LDirectory: Integer;
begin
  LBytes := Copy(ReferenceBytes);
  LDirectory := PInteger(@LBytes[8])^;
  // the size of GL_VERT (second entry) goes past the end of the file
  PInteger(@LBytes[LDirectory + 16 + 4])^ := Length(LBytes);
  Assert.WillRaise(
    procedure
    begin
      TNodesGwaReader.Read(LBytes);
    end, ENodesException);
end;

procedure TTestNodesGwaReader.TestUnLumpGlVertDiMenoDiQuattroByteNonDovrebbeAvereMagic;
var
  LAssembler: TNodesPwadAssembler;
  LGwa: INodesGwa;
begin
  LAssembler := TNodesPwadAssembler.Create;
  try
    LAssembler.AddEmptyLump('GL_MAP01');
    LAssembler.AddLump('GL_VERT', TBytes.Create(1, 2));
    LGwa := TNodesGwaReader.Read(LAssembler.Build);
  finally
    LAssembler.Free;
  end;
  Assert.AreEqual(0, LGwa.Version);
  Assert.AreEqual(0, Length(LGwa.GlVertexes));
end;

procedure TTestNodesGwaReader.TestIlNomeDeiLumpNonDovrebbeDistinguereLeMaiuscole;
var
  LAssembler: TNodesPwadAssembler;
  LGwa: INodesGwa;
  LVert: TBytes;
begin
  SetLength(LVert, 12);
  PCardinal(@LVert[0])^ := NODES_GL_MAGIC_V2;
  LAssembler := TNodesPwadAssembler.Create;
  try
    LAssembler.AddEmptyLump('gl_map01');
    LAssembler.AddLump('gl_vert', LVert);
    LGwa := TNodesGwaReader.Read(LAssembler.Build);
  finally
    LAssembler.Free;
  end;
  Assert.AreEqual(2, LGwa.Version);
  Assert.AreEqual(1, Length(LGwa.GlVertexes));
end;

procedure TTestNodesGwaReader.TestUnLumpCheFinisceATrattoNonDovrebbeDareIlRecordParziale;
var
  LAssembler: TNodesPwadAssembler;
  LGwa: INodesGwa;
  LVert: TBytes;
begin
  SetLength(LVert, 4 + 8 + 5);
  PCardinal(@LVert[0])^ := NODES_GL_MAGIC_V2;
  LAssembler := TNodesPwadAssembler.Create;
  try
    LAssembler.AddEmptyLump('GL_MAP01');
    LAssembler.AddLump('GL_VERT', LVert);
    LGwa := TNodesGwaReader.Read(LAssembler.Build);
  finally
    LAssembler.Free;
  end;
  Assert.AreEqual(1, Length(LGwa.GlVertexes));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesGwaReader);

end.
