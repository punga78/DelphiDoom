{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the reader of MD2 files        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md2Parser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Models.Types, DelphiDoom.Models.Intf;

type
  /// <summary>Parity with the old constructor of TMD2Model (golden file models.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('models')]
  TTestModelsMd2Parser = class(TObject)
  strict private
    FParser: IMd2Parser;
    /// <summary>One triangle, three vertexes, one frame: the numbers of the vertexes are easy to follow</summary>
    function BuildTinyModel(const AFrameName: string): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiRecordDelFormato;
    [Test]
    procedure DovrebbeDareLaStessaImprontaDelVecchioCodiceSuiModelli;
    [Test]
    procedure DovrebbeDareLeStesseImprontaDelVecchioCodiceSuiNomiDeiGruppi;
    [Test]
    procedure DovrebbeDareLaStessaImprontaDelVecchioCodiceSuLeUnioni;
    [Test]
    procedure DovrebbeInvertireGliAngoliEGliAssiDelTriangolo;
    [Test]
    procedure DovrebbeApplicareScalaEPosizioneDelModello;
    [Test]
    procedure DovrebbeLeggereIlNomeDelFotogrammaDi16ByteSenzaSpostareIVertici;
    [Test]
    procedure DovrebbeRaggruppareIFotogrammiConLoStessoNome;
    [Test]
    procedure DovrebbeTrovareUnGruppoSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeDareUnGruppoVuotoAUnNomeVuotoInvecediBloccarsi;
    [Test]
    procedure DovrebbeLeggereLeCoordinateDelleTessitureInFrazioniDellaPelle;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileEBreveOHaUnaMagiaSbagliata;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIConteggiSonoNegativiOLaPelleEVuota;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlModelloNonHaFotogrammi;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileEIncompleto;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnTriangoloUsaUnIndiceInesistente;
    [Test]
    procedure DovrebbeUnireLeAnimazioniDiPiuFileCopiandoOgniFotogramma;
    [Test]
    procedure DovrebbeUnireAncheFileConPiuFotogrammi;
    [Test]
    procedure DovrebbeRifiutareLUnioneSeIVerticiSonoDiversi;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFotogrammaNonEsiste;
  end;

implementation

uses
  DelphiDoom.Models.Factory, DelphiDoom.Models.Md2Parser, DelphiDoom.Tests.Models.Golden,
  DelphiDoom.Tests.Models.Samples, DelphiDoom.Tests.Models.Scenarios,
  DelphiDoom.Tests.Models.Subject;

{ TTestModelsMd2Parser }

procedure TTestModelsMd2Parser.Setup;
begin
  FParser := TModelsFactory.CreateMd2Parser;
end;

function TTestModelsMd2Parser.BuildTinyModel(const AFrameName: string): TBytes;
var
  LHeader: TMd2Header;
  LTexturePoint: TMd2TexturePoint;
  LTriangle: TMd2Triangle;
  LFrameHead: TMd2FrameHead;
  LPosition, LIndex: Integer;
  LName: AnsiString;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Ident := MD2_MAGIC;
  LHeader.Version := 8;
  LHeader.SkinWidth := 100;
  LHeader.SkinHeight := 50;
  LHeader.VertexCount := 3;
  LHeader.TexturePointCount := 3;
  LHeader.TriangleCount := 1;
  LHeader.FrameCount := 1;
  LHeader.FrameSize := MD2_FRAME_HEAD_SIZE + 3 * MD2_VERTEX_SIZE;
  LHeader.TexturePointsOffset := MD2_HEADER_SIZE;
  LHeader.TrianglesOffset := LHeader.TexturePointsOffset + 3 * MD2_TEXTURE_POINT_SIZE;
  LHeader.FramesOffset := LHeader.TrianglesOffset + MD2_TRIANGLE_SIZE;
  LHeader.EndOffset := LHeader.FramesOffset + LHeader.FrameSize;
  SetLength(Result, LHeader.EndOffset);
  Move(LHeader, Result[0], MD2_HEADER_SIZE);

  LPosition := LHeader.TexturePointsOffset;
  // texture points (in pixels of the skin 100 x 50): (10, 5), (20, 10), (30, 15)
  for LIndex := 0 to 2 do
  begin
    LTexturePoint.S := (LIndex + 1) * 10;
    LTexturePoint.T := (LIndex + 1) * 5;
    Move(LTexturePoint, Result[LPosition], MD2_TEXTURE_POINT_SIZE);
    Inc(LPosition, MD2_TEXTURE_POINT_SIZE);
  end;
  // the triangle: the vertexes 0, 1, 2 and the texture points 0, 1, 2
  for LIndex := 0 to 2 do
  begin
    LTriangle.VertexIndex[LIndex] := LIndex;
    LTriangle.TexturePointIndex[LIndex] := LIndex;
  end;
  Move(LTriangle, Result[LPosition], MD2_TRIANGLE_SIZE);
  Inc(LPosition, MD2_TRIANGLE_SIZE);

  FillChar(LFrameHead, SizeOf(LFrameHead), 0);
  for LIndex := 0 to 2 do
  begin
    LFrameHead.Scale[LIndex] := 1;
    LFrameHead.Translate[LIndex] := 0;
  end;
  LName := AnsiString(AFrameName);
  for LIndex := 1 to Length(LName) do
    LFrameHead.Name[LIndex - 1] := LName[LIndex];
  Move(LFrameHead, Result[LPosition], MD2_FRAME_HEAD_SIZE);
  Inc(LPosition, MD2_FRAME_HEAD_SIZE);
  // the vertexes: (1, 2, 3), (4, 5, 6), (7, 8, 9) and a normal each
  for LIndex := 0 to 2 do
  begin
    Result[LPosition] := LIndex * 3 + 1;
    Result[LPosition + 1] := LIndex * 3 + 2;
    Result[LPosition + 2] := LIndex * 3 + 3;
    Result[LPosition + 3] := 0;
    Inc(LPosition, MD2_VERTEX_SIZE);
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeAvereLeDimensioniDeiRecordDelFormato;
begin
  Assert.AreEqual(MD2_HEADER_SIZE, SizeOf(TMd2Header));
  Assert.AreEqual(MD2_TRIANGLE_SIZE, SizeOf(TMd2Triangle));
  Assert.AreEqual(MD2_TEXTURE_POINT_SIZE, SizeOf(TMd2TexturePoint));
  Assert.AreEqual(MD2_FRAME_HEAD_SIZE, SizeOf(TMd2FrameHead));
  Assert.AreEqual(MODEL_COMMAND_SIZE, SizeOf(TModelCommand));
  Assert.AreEqual(12, SizeOf(TModelVertex));
  Assert.AreEqual(8, SizeOf(TModelTexCoord));
end;

procedure TTestModelsMd2Parser.DovrebbeDareLaStessaImprontaDelVecchioCodiceSuiModelli;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('models.golden.txt');
  try
    LGolden.Check('md2.models', TModelsScenarios.Md2Models(TModelsSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeDareLeStesseImprontaDelVecchioCodiceSuiNomiDeiGruppi;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('models.golden.txt');
  try
    LGolden.Check('md2.groupnames', TModelsScenarios.GroupNames(TModelsSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeDareLaStessaImprontaDelVecchioCodiceSuLeUnioni;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('models.golden.txt');
  try
    LGolden.Check('md2.merges', TModelsScenarios.Md2Merges(TModelsSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeInvertireGliAngoliEGliAssiDelTriangolo;
var
  LModel: IMd2Model;
  LVertex: PModelVertex;
begin
  LModel := FParser.Parse(BuildTinyModel('stand01'), TModelsSamples.IdentityPlacement);
  Assert.AreEqual(1, LModel.FrameCount);
  Assert.AreEqual(3, LModel.VertexCount);
  LVertex := LModel.GetFrameVertices(0);
  // the first corner is the vertex 2 of the file (7, 8, 9): x = file y, y = file z, z = file x
  Assert.AreEqual(8.0, LVertex^.X, 0.0001);
  Assert.AreEqual(9.0, LVertex^.Y, 0.0001);
  Assert.AreEqual(7.0, LVertex^.Z, 0.0001);
  Inc(LVertex);
  // the second is the vertex 1 (4, 5, 6)
  Assert.AreEqual(5.0, LVertex^.X, 0.0001);
  Assert.AreEqual(6.0, LVertex^.Y, 0.0001);
  Assert.AreEqual(4.0, LVertex^.Z, 0.0001);
  Inc(LVertex);
  // the third is the vertex 0 (1, 2, 3)
  Assert.AreEqual(2.0, LVertex^.X, 0.0001);
  Assert.AreEqual(3.0, LVertex^.Y, 0.0001);
  Assert.AreEqual(1.0, LVertex^.Z, 0.0001);
end;

procedure TTestModelsMd2Parser.DovrebbeApplicareScalaEPosizioneDelModello;
var
  LModel: IMd2Model;
  LPlacement: TModelPlacement;
  LVertex: PModelVertex;
begin
  LPlacement := TModelsSamples.IdentityPlacement;
  LPlacement.ScaleX := 2;
  LPlacement.ScaleY := 3;
  LPlacement.ScaleZ := 4;
  LPlacement.OffsetX := 10;
  LPlacement.OffsetY := 20;
  LPlacement.OffsetZ := 30;
  LModel := FParser.Parse(BuildTinyModel('stand01'), LPlacement);
  LVertex := LModel.GetFrameVertices(0);
  // the vertex 2 of the file is (7, 8, 9): the positions are (7*2+10, 8*3+20, 9*4+30) = (24, 44, 66)
  Assert.AreEqual(44.0, LVertex^.X, 0.0001);
  Assert.AreEqual(66.0, LVertex^.Y, 0.0001);
  Assert.AreEqual(24.0, LVertex^.Z, 0.0001);
end;

procedure TTestModelsMd2Parser.DovrebbeLeggereIlNomeDelFotogrammaDi16ByteSenzaSpostareIVertici;
var
  LModel: IMd2Model;
  LVertex: PModelVertex;
begin
  // regression: the old record had the name as 16 Char of 2 bytes in Delphi 11, so the name was
  // garbage and the vertexes were taken from 16 bytes later (4 vertexes of the file)
  LModel := FParser.Parse(BuildTinyModel('stand01'), TModelsSamples.IdentityPlacement);
  Assert.AreEqual('STAND', LModel.GetGroupName(0));
  LVertex := LModel.GetFrameVertices(0);
  Assert.AreEqual(8.0, LVertex^.X, 0.0001);
end;

procedure TTestModelsMd2Parser.DovrebbeRaggruppareIFotogrammiConLoStessoNome;
var
  LRandom: TModelsRandom;
  LModel: IMd2Model;
begin
  LRandom := TModelsRandom.Create(5);
  try
    LModel := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 4, 6, 6, 6, 64, 64,
      ['stand01', 'stand02', 'stand03', 'run1', 'run2', 'pain1']), TModelsSamples.IdentityPlacement);
    Assert.AreEqual(6, LModel.FrameCount);
    Assert.AreEqual(3, LModel.GroupCount);
    Assert.AreEqual('STAND', LModel.GetGroupName(0));
    Assert.AreEqual(0, LModel.GetGroupStartFrame(0));
    Assert.AreEqual(2, LModel.GetGroupEndFrame(0));
    Assert.AreEqual('RUN', LModel.GetGroupName(1));
    Assert.AreEqual(3, LModel.GetGroupStartFrame(1));
    Assert.AreEqual(4, LModel.GetGroupEndFrame(1));
    Assert.AreEqual(5, LModel.GetGroupStartFrame(2));
    Assert.AreEqual(-1, LModel.GetGroupStartFrame(3));
    Assert.AreEqual(-1, LModel.GetGroupEndFrame(-1));
    Assert.AreEqual('', LModel.GetGroupName(9));
  finally
    LRandom.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeTrovareUnGruppoSenzaDistinguereLeMaiuscole;
var
  LModel: IMd2Model;
begin
  LModel := FParser.Parse(BuildTinyModel('stand01'), TModelsSamples.IdentityPlacement);
  Assert.AreEqual(0, LModel.FindGroup('STAND'));
  Assert.AreEqual(0, LModel.FindGroup('stand'));
  Assert.AreEqual(0, LModel.FindGroup('Stand'));
  Assert.AreEqual(-1, LModel.FindGroup('run'));
end;

procedure TTestModelsMd2Parser.DovrebbeDareUnGruppoVuotoAUnNomeVuotoInvecediBloccarsi;
begin
  // the old code looped for ever on a name of only spaces
  Assert.AreEqual('', TMd2Parser.GroupNameOf(''));
  Assert.AreEqual('', TMd2Parser.GroupNameOf('   '));
  Assert.AreEqual('', TMd2Parser.GroupNameOf('a'));
end;

procedure TTestModelsMd2Parser.DovrebbeLeggereLeCoordinateDelleTessitureInFrazioniDellaPelle;
var
  LModel: IMd2Model;
  LCoord: PModelTexCoord;
begin
  LModel := FParser.Parse(BuildTinyModel('stand01'), TModelsSamples.IdentityPlacement);
  LCoord := LModel.GetTexCoords;
  // the corners are in the order 2, 1, 0: the texture point 2 is (30, 15) on a skin of 100 x 50
  Assert.AreEqual(0.3, LCoord^.U, 0.0001);
  Assert.AreEqual(0.3, LCoord^.V, 0.0001);
  Inc(LCoord);
  Assert.AreEqual(0.2, LCoord^.U, 0.0001);
  Assert.AreEqual(0.2, LCoord^.V, 0.0001);
  Inc(LCoord);
  Assert.AreEqual(0.1, LCoord^.U, 0.0001);
  Assert.AreEqual(0.1, LCoord^.V, 0.0001);
end;

procedure TTestModelsMd2Parser.DovrebbeSollevareUnErroreSeIlFileEBreveOHaUnaMagiaSbagliata;
var
  LBytes: TBytes;
begin
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(nil, TModelsSamples.IdentityPlacement);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(TBytes.Create(1, 2, 3), TModelsSamples.IdentityPlacement);
    end, EModelsException);
  LBytes := BuildTinyModel('stand01');
  LBytes[0] := Ord('X');
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException, 'Invalid MD2 model magic');
end;

procedure TTestModelsMd2Parser.DovrebbeSollevareUnErroreSeIConteggiSonoNegativiOLaPelleEVuota;
var
  LHeader: TMd2Header;
  LBytes: TBytes;
begin
  // the old code divided by the size of the skin: zero raised a division by zero in the engine
  LBytes := BuildTinyModel('stand01');
  Move(LBytes[0], LHeader, MD2_HEADER_SIZE);
  LHeader.SkinWidth := 0;
  Move(LHeader, LBytes[0], MD2_HEADER_SIZE);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException);
  LHeader.SkinWidth := 100;
  LHeader.TriangleCount := -1;
  Move(LHeader, LBytes[0], MD2_HEADER_SIZE);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException);
end;

procedure TTestModelsMd2Parser.DovrebbeSollevareUnErroreSeIlModelloNonHaFotogrammi;
var
  LHeader: TMd2Header;
  LBytes: TBytes;
begin
  LBytes := BuildTinyModel('stand01');
  Move(LBytes[0], LHeader, MD2_HEADER_SIZE);
  LHeader.FrameCount := 0;
  Move(LHeader, LBytes[0], MD2_HEADER_SIZE);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException, 'no frames');
end;

procedure TTestModelsMd2Parser.DovrebbeSollevareUnErroreSeIlFileEIncompleto;
var
  LBytes: TBytes;
begin
  // the file without the last bytes of the last frame: the old code read what was after
  LBytes := BuildTinyModel('stand01');
  SetLength(LBytes, Length(LBytes) - 1);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException, 'truncated');
end;

procedure TTestModelsMd2Parser.DovrebbeSollevareUnErroreSeUnTriangoloUsaUnIndiceInesistente;
var
  LBytes: TBytes;
  LTriangle: TMd2Triangle;
  LHeader: TMd2Header;
begin
  LBytes := BuildTinyModel('stand01');
  Move(LBytes[0], LHeader, MD2_HEADER_SIZE);
  Move(LBytes[LHeader.TrianglesOffset], LTriangle, MD2_TRIANGLE_SIZE);
  LTriangle.VertexIndex[1] := 3;
  Move(LTriangle, LBytes[LHeader.TrianglesOffset], MD2_TRIANGLE_SIZE);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException, 'vertex');
  LBytes := BuildTinyModel('stand01');
  Move(LBytes[LHeader.TrianglesOffset], LTriangle, MD2_TRIANGLE_SIZE);
  LTriangle.TexturePointIndex[0] := -1;
  Move(LTriangle, LBytes[LHeader.TrianglesOffset], MD2_TRIANGLE_SIZE);
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse(LBytes, TModelsSamples.IdentityPlacement);
    end, EModelsException, 'texture point');
end;

procedure TTestModelsMd2Parser.DovrebbeUnireLeAnimazioniDiPiuFileCopiandoOgniFotogramma;
var
  LRandom: TModelsRandom;
  LFirst, LSecond: IMd2Model;
  LMerged: Boolean;
begin
  LRandom := TModelsRandom.Create(6);
  try
    LFirst := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 5, 8, 2, 8, 64, 64,
      ['stand1', 'stand2']), TModelsSamples.IdentityPlacement);
    LSecond := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 5, 8, 1, 8, 64, 64, ['pain1']),
      TModelsSamples.IdentityPlacement);
    LMerged := LFirst.MergeFrames(LSecond);
    Assert.IsTrue(LMerged);
    Assert.AreEqual(3, LFirst.FrameCount);
    Assert.AreEqual(2, LFirst.GroupCount);
    Assert.AreEqual('PAIN', LFirst.GetGroupName(1));
    Assert.AreEqual(2, LFirst.GetGroupStartFrame(1));
    Assert.AreEqual(2, LFirst.GetGroupEndFrame(1));
    Assert.AreEqual(LSecond.GetFrameVertices(0)^.X, LFirst.GetFrameVertices(2)^.X, 0.0);
    // the copy is its own memory
    Assert.IsTrue(LSecond.GetFrameVertices(0) <> LFirst.GetFrameVertices(2));
  finally
    LRandom.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeUnireAncheFileConPiuFotogrammi;
var
  LRandom: TModelsRandom;
  LFirst, LSecond: IMd2Model;
  LFrame, LIndex: Integer;
begin
  // regression: the old merge read the frames of the second model at the index
  // (frames of the first - i), that is zero or negative: only one frame could be merged
  LRandom := TModelsRandom.Create(7);
  try
    LFirst := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 4, 6, 2, 6, 64, 64,
      ['stand1', 'stand2']), TModelsSamples.IdentityPlacement);
    LSecond := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 4, 6, 3, 6, 64, 64,
      ['run1', 'run2', 'run3']), TModelsSamples.IdentityPlacement);
    Assert.IsTrue(LFirst.MergeFrames(LSecond));
    Assert.AreEqual(5, LFirst.FrameCount);
    for LFrame := 0 to 2 do
      for LIndex := 0 to LSecond.VertexCount - 1 do
      begin
        Assert.AreEqual(PModelVertex(PByte(LSecond.GetFrameVertices(LFrame)) + LIndex * SizeOf(TModelVertex))^.Y,
          PModelVertex(PByte(LFirst.GetFrameVertices(2 + LFrame)) + LIndex * SizeOf(TModelVertex))^.Y, 0.0);
      end;
    Assert.AreEqual(2, LFirst.GetGroupStartFrame(1));
    Assert.AreEqual(4, LFirst.GetGroupEndFrame(1));
  finally
    LRandom.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeRifiutareLUnioneSeIVerticiSonoDiversi;
var
  LRandom: TModelsRandom;
  LFirst, LSecond: IMd2Model;
begin
  LRandom := TModelsRandom.Create(8);
  try
    LFirst := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 4, 6, 2, 6, 64, 64, ['a1']),
      TModelsSamples.IdentityPlacement);
    LSecond := FParser.Parse(TModelsSamples.BuildMd2(LRandom, 5, 6, 1, 6, 64, 64, ['b1']),
      TModelsSamples.IdentityPlacement);
    Assert.IsFalse(LFirst.MergeFrames(LSecond));
    Assert.IsFalse(LFirst.MergeFrames(nil));
    Assert.AreEqual(2, LFirst.FrameCount);
    Assert.AreEqual(1, LFirst.GroupCount);
  finally
    LRandom.Free;
  end;
end;

procedure TTestModelsMd2Parser.DovrebbeSollevareUnErroreSeIlFotogrammaNonEsiste;
var
  LModel: IMd2Model;
begin
  LModel := FParser.Parse(BuildTinyModel('stand01'), TModelsSamples.IdentityPlacement);
  Assert.WillRaise(
    procedure
    begin
      LModel.GetFrameVertices(1);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      LModel.GetFrameVertices(-1);
    end, EModelsException);
end;

end.
