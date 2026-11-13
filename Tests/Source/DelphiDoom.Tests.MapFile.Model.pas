{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the model (map, entity, brush,  }
{  patch, brush side) and the pieces of the geometry checksum                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.Model;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('MapFile')]
  TTestMapGeometryCrc = class
  public
    [Test]
    procedure DovrebbeUsareIBitDelFloat;
    [Test]
    procedure DovrebbeCalcolareIlCrcDiUnTestoAscii;
    [Test]
    procedure DovrebbeTrattareICaratteriAltiComeCharConSegno;
    [Test]
    procedure DovrebbeFermarsiAlPrimoCarattereNullo;
    [Test]
    procedure DovrebbeDareZeroPerUnTestoVuoto;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapBrush = class
  public
    [Test]
    procedure DovrebbePartireVuoto;
    [Test]
    procedure DovrebbeContareLeFacceAggiunte;
    [Test]
    procedure DovrebbeCalcolareIlCrcDiPianiEMateriali;
    [Test]
    procedure DovrebbeEssereUnBrush;
    [Test]
    procedure DovrebbeAvereLeCoppieChiaveValoreDelleFacce;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapBrushSide = class
  public
    [Test]
    procedure DovrebbePartireATuttoZero;
    [Test]
    procedure DovrebbeDareIVettoriDiTexturePerUnPianoOrizzontale;
    [Test]
    procedure DovrebbeSommareLOrigineAlloScostamento;
    [Test]
    procedure DovrebbeRipulireLeComponentiPiccoleDellaNormale;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapPatch = class
  public
    [Test]
    procedure DovrebbePartireVuoto;
    [Test]
    procedure DovrebbeAlloccareLaGriglia;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNegativa;
    [Test]
    procedure DovrebbeRifiutareUnaGrigliaTroppoGrande;
    [Test]
    procedure DovrebbeCalcolareIlCrcDellaGeometria;
    [Test]
    procedure DovrebbeEssereUnaPatch;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapEntity = class
  public
    [Test]
    procedure DovrebbeTenereLePrimitiveInOrdine;
    [Test]
    procedure DovrebbeCombinareIlCrcDelleProprieDelleDuePrimitive;
    [Test]
    procedure DovrebbeLiberareLeSolePrimitive;
    [Test]
    procedure DovrebbeSpostareLePrimitiveInUnAltraEntita;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapFileModel = class
  public
    [Test]
    procedure DovrebbePartireAllaVersioneCorrente;
    [Test]
    procedure DovrebbeTrovareUnEntitaPerNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeRimuovereUnEntita;
    [Test]
    procedure DovrebbeRimuovereLeEntitaPerClassname;
    [Test]
    procedure DovrebbeRimuovereTutteLeEntita;
    [Test]
    procedure DovrebbeRimuovereLeSolePrimitive;
    [Test]
    procedure DovrebbeCombinareIlCrcDelleEntita;
    [Test]
    procedure DovrebbeChiedereIlCaricamentoSeIlFileCambia;
    [Test]
    procedure DovrebbeChiedereIlCaricamentoSeNonTrovaIlFile;
    [Test]
    procedure DovrebbeDareLaRigaNellEccezione;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Types, DelphiDoom.MapFile.GeometryCrc, DelphiDoom.MapFile.Primitive, DelphiDoom.MapFile.Brush,
  DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Map,
  DelphiDoom.Tests.IdLib.Fakes;

function MakeSide(const AMaterial: AnsiString; const AA, AB, AC, AD: Single): TMapBrushSide;
begin
  Result := TMapBrushSide.Create;
  Result.Material := AMaterial;
  Result.Plane := TGeoPlane.Make(AA, AB, AC, AD);
end;

{ TTestMapGeometryCrc }

procedure TTestMapGeometryCrc.DovrebbeUsareIBitDelFloat;
begin
  Assert.AreEqual<Cardinal>($3F800000, TMapGeometryCrc.FloatCrc(1.0));
  Assert.AreEqual<Cardinal>($C0000000, TMapGeometryCrc.FloatCrc(-2.0));
  Assert.AreEqual<Cardinal>(0, TMapGeometryCrc.FloatCrc(0.0));
end;

procedure TTestMapGeometryCrc.DovrebbeCalcolareIlCrcDiUnTestoAscii;
begin
  // 97, 98 shl 1, 99 shl 2, 100 shl 3 combined with xor
  Assert.AreEqual<Cardinal>($209, TMapGeometryCrc.StringCrc('abcd'));
  // the fifth character goes back to the shift of the first
  Assert.AreEqual<Cardinal>($209 xor 101, TMapGeometryCrc.StringCrc('abcde'));
end;

procedure TTestMapGeometryCrc.DovrebbeTrattareICaratteriAltiComeCharConSegno;
begin
  // $E9 is -23 as a signed char, extended to 32 bits
  Assert.AreEqual<Cardinal>($FFFFFFE9, TMapGeometryCrc.StringCrc(AnsiString(#$E9)));
  Assert.AreEqual<Cardinal>($FFFFFFE9 xor (98 shl 1), TMapGeometryCrc.StringCrc(AnsiString(#$E9 + 'b')));
end;

procedure TTestMapGeometryCrc.DovrebbeFermarsiAlPrimoCarattereNullo;
begin
  Assert.AreEqual<Cardinal>(97, TMapGeometryCrc.StringCrc('a'#0'bcd'));
end;

procedure TTestMapGeometryCrc.DovrebbeDareZeroPerUnTestoVuoto;
begin
  Assert.AreEqual<Cardinal>(0, TMapGeometryCrc.StringCrc(''));
end;

{ TTestMapBrush }

procedure TTestMapBrush.DovrebbePartireVuoto;
var
  LBrush: TMapBrush;
begin
  LBrush := TMapBrush.Create;
  try
    Assert.AreEqual(0, LBrush.GetNumSides);
    Assert.AreEqual<Cardinal>(0, LBrush.GetGeometryCrc);
    Assert.AreEqual(0, LBrush.Epairs.GetNumKeyVals);
  finally
    LBrush.Free;
  end;
end;

procedure TTestMapBrush.DovrebbeContareLeFacceAggiunte;
var
  LBrush: TMapBrush;
  LSide: TMapBrushSide;
begin
  LBrush := TMapBrush.Create;
  try
    LSide := MakeSide('a', 1, 0, 0, 0);
    Assert.AreEqual(0, LBrush.AddSide(LSide));
    Assert.AreEqual(1, LBrush.AddSide(MakeSide('b', 0, 1, 0, 0)));
    Assert.AreEqual(2, LBrush.GetNumSides);
    Assert.AreSame(LSide, LBrush.GetSide(0));
  finally
    LBrush.Free;
  end;
end;

procedure TTestMapBrush.DovrebbeCalcolareIlCrcDiPianiEMateriali;
var
  LBrush: TMapBrush;
begin
  LBrush := TMapBrush.Create;
  try
    LBrush.AddSide(MakeSide('a', 1, 2, 3, 4));
    // 3F800000 xor 40000000 xor 40400000 xor 40800000 xor 'a'
    Assert.AreEqual<Cardinal>($7F400061, LBrush.GetGeometryCrc);
    // the same side twice cancels out
    LBrush.AddSide(MakeSide('a', 1, 2, 3, 4));
    Assert.AreEqual<Cardinal>(0, LBrush.GetGeometryCrc);
  finally
    LBrush.Free;
  end;
end;

procedure TTestMapBrush.DovrebbeEssereUnBrush;
var
  LBrush: TMapBrush;
begin
  LBrush := TMapBrush.Create;
  try
    Assert.IsTrue(LBrush.PrimitiveType = mptBrush);
  finally
    LBrush.Free;
  end;
end;

procedure TTestMapBrush.DovrebbeAvereLeCoppieChiaveValoreDelleFacce;
var
  LBrush: TMapBrush;
begin
  LBrush := TMapBrush.Create;
  try
    LBrush.Epairs.SetValue('editor_color', '1 0 0');
    Assert.AreEqual(AnsiString('1 0 0'), LBrush.Epairs.GetString('EDITOR_COLOR'));
  finally
    LBrush.Free;
  end;
end;

{ TTestMapBrushSide }

procedure TTestMapBrushSide.DovrebbePartireATuttoZero;
var
  LSide: TMapBrushSide;
begin
  LSide := TMapBrushSide.Create;
  try
    Assert.AreEqual<Single>(0, LSide.Plane.A);
    Assert.AreEqual<Single>(0, LSide.Plane.D);
    Assert.AreEqual<Single>(0, LSide.TextureMatrix[1].Z);
    Assert.AreEqual<Single>(0, LSide.Origin.X);
    Assert.AreEqual(AnsiString(''), LSide.Material);
  finally
    LSide.Free;
  end;
end;

procedure TTestMapBrushSide.DovrebbeDareIVettoriDiTexturePerUnPianoOrizzontale;
var
  LSide: TMapBrushSide;
  LS, LT: TIdVec4;
  LMatrix: TGeoVec3;
begin
  LSide := TMapBrushSide.Create;
  try
    LSide.Plane := TGeoPlane.Make(0, 0, 1, 0);
    LMatrix.SetValues(1, 0, 0.5);
    LSide.TextureMatrix[0] := LMatrix;
    LMatrix.SetValues(0, 1, 0.25);
    LSide.TextureMatrix[1] := LMatrix;
    LSide.GetTextureVectors(LS, LT);
    // texS = (0, 1, 0) and texT = (1, 0, 0) for a normal along +z: the matrix row 0 picks texS, row 1 texT
    Assert.AreEqual(Double(0), Double(LS.X), 0.0001);
    Assert.AreEqual(Double(1), Double(LS.Y), 0.0001);
    Assert.AreEqual(Double(0), Double(LS.Z), 0.0001);
    Assert.AreEqual(Double(0.5), Double(LS.W), 0.0001);
    Assert.AreEqual(Double(1), Double(LT.X), 0.0001);
    Assert.AreEqual(Double(0), Double(LT.Y), 0.0001);
    Assert.AreEqual(Double(0.25), Double(LT.W), 0.0001);
  finally
    LSide.Free;
  end;
end;

procedure TTestMapBrushSide.DovrebbeSommareLOrigineAlloScostamento;
var
  LSide: TMapBrushSide;
  LS, LT: TIdVec4;
  LMatrix: TGeoVec3;
begin
  LSide := TMapBrushSide.Create;
  try
    LSide.Plane := TGeoPlane.Make(0, 0, 1, 0);
    LMatrix.SetValues(1, 0, 0);
    LSide.TextureMatrix[0] := LMatrix;
    LMatrix.SetValues(0, 1, 0);
    LSide.TextureMatrix[1] := LMatrix;
    LMatrix.SetValues(10, 20, 30);
    LSide.Origin := LMatrix;
    LSide.GetTextureVectors(LS, LT);
    // w = offset + origin . (x, y, z) of the vector: texS is (0, 1, 0)
    Assert.AreEqual(Double(20), Double(LS.W), 0.0001);
    Assert.AreEqual(Double(10), Double(LT.W), 0.0001);
  finally
    LSide.Free;
  end;
end;

procedure TTestMapBrushSide.DovrebbeRipulireLeComponentiPiccoleDellaNormale;
var
  LSide, LClean: TMapBrushSide;
  LS1, LT1, LS2, LT2: TIdVec4;
  LMatrix: TGeoVec3;
begin
  LSide := TMapBrushSide.Create;
  LClean := TMapBrushSide.Create;
  try
    LMatrix.SetValues(1, 0, 0);
    LSide.TextureMatrix[0] := LMatrix;
    LClean.TextureMatrix[0] := LMatrix;
    LMatrix.SetValues(0, 1, 0);
    LSide.TextureMatrix[1] := LMatrix;
    LClean.TextureMatrix[1] := LMatrix;
    // components under 1e-6 count as zero (ComputeAxisBase)
    LSide.Plane := TGeoPlane.Make(5E-7, -5E-7, 1, 0);
    LClean.Plane := TGeoPlane.Make(0, 0, 1, 0);
    LSide.GetTextureVectors(LS1, LT1);
    LClean.GetTextureVectors(LS2, LT2);
    Assert.AreEqual(Double(LS2.X), Double(LS1.X), 0);
    Assert.AreEqual(Double(LS2.Y), Double(LS1.Y), 0);
    Assert.AreEqual(Double(LT2.X), Double(LT1.X), 0);
  finally
    LClean.Free;
    LSide.Free;
  end;
end;

{ TTestMapPatch }

procedure TTestMapPatch.DovrebbePartireVuoto;
var
  LPatch: TMapPatch;
begin
  LPatch := TMapPatch.Create;
  try
    Assert.AreEqual(0, LPatch.Width);
    Assert.AreEqual(0, LPatch.Height);
    Assert.AreEqual(0, LPatch.GetNumVertices);
    Assert.IsFalse(LPatch.ExplicitlySubdivided);
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatch.DovrebbeAlloccareLaGriglia;
var
  LPatch: TMapPatch;
  LVertex: TMapPatchVertex;
begin
  LPatch := TMapPatch.Create(3, 2);
  try
    Assert.AreEqual(6, LPatch.GetNumVertices);
    LVertex := LPatch.Vertices[5];
    Assert.AreEqual<Single>(0, LVertex.Position.X);
    LVertex.Position.SetValues(1, 2, 3);
    LVertex.S := 0.5;
    LPatch.Vertices[5] := LVertex;
    Assert.AreEqual<Single>(3, LPatch.Vertices[5].Position.Z);
    Assert.AreEqual<Single>(0.5, LPatch.Vertices[5].S);
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatch.DovrebbeRifiutareUnaDimensioneNegativa;
begin
  Assert.WillRaise(
    procedure
    begin
      TMapPatch.Create(-1, 2).Free;
    end, EMapFileException);
end;

procedure TTestMapPatch.DovrebbeRifiutareUnaGrigliaTroppoGrande;
begin
  Assert.WillRaise(
    procedure
    begin
      TMapPatch.Create(5000, 5000).Free;
    end, EMapFileException);
end;

procedure TTestMapPatch.DovrebbeCalcolareIlCrcDellaGeometria;
var
  LPatch: TMapPatch;
  LVertex: TMapPatchVertex;
begin
  LPatch := TMapPatch.Create(2, 2);
  try
    LPatch.Material := 'a';
    LPatch.HorzSubdivisions := 4;
    LPatch.VertSubdivisions := 5;
    LVertex := LPatch.Vertices[0];
    LVertex.Position.SetValues(1, 2, 3);
    // the texture coordinates do not count
    LVertex.S := 9;
    LPatch.Vertices[0] := LVertex;
    // (4 xor 5) xor 3F800000 xor 40000000 xor 40400000 xor 'a'
    Assert.AreEqual<Cardinal>($3FC00060, LPatch.GetGeometryCrc);
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatch.DovrebbeEssereUnaPatch;
var
  LPatch: TMapPatch;
begin
  LPatch := TMapPatch.Create;
  try
    Assert.IsTrue(LPatch.PrimitiveType = mptPatch);
  finally
    LPatch.Free;
  end;
end;

{ TTestMapEntity }

procedure TTestMapEntity.DovrebbeTenereLePrimitiveInOrdine;
var
  LEntity: TMapEntity;
  LBrush: TMapBrush;
  LPatch: TMapPatch;
begin
  LEntity := TMapEntity.Create;
  try
    LBrush := TMapBrush.Create;
    LPatch := TMapPatch.Create;
    LEntity.AddPrimitive(LBrush);
    LEntity.AddPrimitive(LPatch);
    Assert.AreEqual(2, LEntity.GetNumPrimitives);
    Assert.AreSame(TMapPrimitive(LBrush), LEntity.GetPrimitive(0));
    Assert.AreSame(TMapPrimitive(LPatch), LEntity.GetPrimitive(1));
  finally
    LEntity.Free;
  end;
end;

procedure TTestMapEntity.DovrebbeCombinareIlCrcDelleProprieDelleDuePrimitive;
var
  LEntity: TMapEntity;
  LBrush: TMapBrush;
  LPatch: TMapPatch;
begin
  LEntity := TMapEntity.Create;
  try
    LBrush := TMapBrush.Create;
    LBrush.AddSide(MakeSide('a', 1, 2, 3, 4));
    LPatch := TMapPatch.Create(1, 1);
    LPatch.HorzSubdivisions := 3;
    LEntity.AddPrimitive(LBrush);
    LEntity.AddPrimitive(LPatch);
    Assert.AreEqual<Cardinal>(LBrush.GetGeometryCrc xor LPatch.GetGeometryCrc, LEntity.GetGeometryCrc);
    Assert.AreEqual<Cardinal>($7F400061 xor 3, LEntity.GetGeometryCrc);
  finally
    LEntity.Free;
  end;
end;

procedure TTestMapEntity.DovrebbeLiberareLeSolePrimitive;
var
  LEntity: TMapEntity;
begin
  LEntity := TMapEntity.Create;
  try
    LEntity.Epairs.SetValue('classname', 'worldspawn');
    LEntity.AddPrimitive(TMapBrush.Create);
    LEntity.RemovePrimitiveData;
    Assert.AreEqual(0, LEntity.GetNumPrimitives);
    Assert.AreEqual(AnsiString('worldspawn'), LEntity.Epairs.GetString('classname'));
  finally
    LEntity.Free;
  end;
end;

procedure TTestMapEntity.DovrebbeSpostareLePrimitiveInUnAltraEntita;
var
  LFrom, LTo: TMapEntity;
  LBrush: TMapBrush;
begin
  LFrom := TMapEntity.Create;
  LTo := TMapEntity.Create;
  try
    LTo.AddPrimitive(TMapBrush.Create);
    LBrush := TMapBrush.Create;
    LFrom.AddPrimitive(LBrush);
    LFrom.AddPrimitive(TMapPatch.Create);
    LFrom.MovePrimitivesTo(LTo);
    Assert.AreEqual(0, LFrom.GetNumPrimitives);
    Assert.AreEqual(3, LTo.GetNumPrimitives);
    Assert.AreSame(TMapPrimitive(LBrush), LTo.GetPrimitive(1));
  finally
    LFrom.Free;
    LTo.Free;
  end;
end;

{ TTestMapFileModel }

procedure TTestMapFileModel.DovrebbePartireAllaVersioneCorrente;
var
  LMap: TMapFile;
begin
  LMap := TMapFile.Create;
  try
    Assert.AreEqual<Single>(CURRENT_MAP_VERSION, LMap.Version);
    Assert.AreEqual(0, LMap.GetNumEntities);
    Assert.IsFalse(LMap.HasPrimitiveData);
    Assert.AreEqual<Cardinal>(0, LMap.GeometryCrc);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeTrovareUnEntitaPerNomeSenzaMaiuscole;
var
  LMap: TMapFile;
  LEntity: TMapEntity;
begin
  LMap := TMapFile.Create;
  try
    LEntity := TMapEntity.Create;
    LEntity.Epairs.SetValue('name', 'Door_1');
    LMap.AddEntity(TMapEntity.Create);
    Assert.AreEqual(1, LMap.AddEntity(LEntity));
    Assert.AreSame(LEntity, LMap.FindEntity('door_1'));
    Assert.IsNull(LMap.FindEntity('door_2'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeRimuovereUnEntita;
var
  LMap: TMapFile;
  LEntity: TMapEntity;
begin
  LMap := TMapFile.Create;
  try
    LEntity := TMapEntity.Create;
    LMap.AddEntity(TMapEntity.Create);
    LMap.AddEntity(LEntity);
    LMap.RemoveEntity(LEntity);
    Assert.AreEqual(1, LMap.GetNumEntities);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeRimuovereLeEntitaPerClassname;
var
  LMap: TMapFile;
  LIndex: Integer;
  LEntity: TMapEntity;
begin
  LMap := TMapFile.Create;
  try
    for LIndex := 0 to 4 do
    begin
      LEntity := TMapEntity.Create;
      if LIndex in [1, 2, 4] then
        LEntity.Epairs.SetValue('classname', 'Light')
      else
        LEntity.Epairs.SetValue('classname', 'speaker');
      LMap.AddEntity(LEntity);
    end;
    LMap.RemoveEntities('light');
    Assert.AreEqual(2, LMap.GetNumEntities);
    Assert.AreEqual(AnsiString('speaker'), LMap.GetEntity(1).Epairs.GetString('classname'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeRimuovereTutteLeEntita;
var
  LMap: TMapFile;
begin
  LMap := TMapFile.Create;
  try
    LMap.AddEntity(TMapEntity.Create);
    LMap.HasPrimitiveData := True;
    LMap.RemoveAllEntities;
    Assert.AreEqual(0, LMap.GetNumEntities);
    Assert.IsFalse(LMap.HasPrimitiveData);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeRimuovereLeSolePrimitive;
var
  LMap: TMapFile;
  LEntity: TMapEntity;
begin
  LMap := TMapFile.Create;
  try
    LEntity := TMapEntity.Create;
    LEntity.AddPrimitive(TMapBrush.Create);
    LMap.AddEntity(LEntity);
    LMap.HasPrimitiveData := True;
    LMap.RemovePrimitiveData;
    Assert.AreEqual(1, LMap.GetNumEntities);
    Assert.AreEqual(0, LEntity.GetNumPrimitives);
    Assert.IsFalse(LMap.HasPrimitiveData);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeCombinareIlCrcDelleEntita;
var
  LMap: TMapFile;
  LEntity: TMapEntity;
  LBrush: TMapBrush;
begin
  LMap := TMapFile.Create;
  try
    LEntity := TMapEntity.Create;
    LBrush := TMapBrush.Create;
    LBrush.AddSide(MakeSide('a', 1, 2, 3, 4));
    LEntity.AddPrimitive(LBrush);
    LMap.AddEntity(LEntity);
    Assert.AreEqual<Cardinal>(0, LMap.GeometryCrc);
    LMap.UpdateGeometryCrc;
    Assert.AreEqual<Cardinal>($7F400061, LMap.GeometryCrc);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeChiedereIlCaricamentoSeIlFileCambia;
var
  LMap: TMapFile;
  LFileSystem: TIdLibMemoryFileSystem;
  LIntf: IIdLibFileSystem;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LIntf := LFileSystem;
  LFileSystem.SetFile('maps/test', 'x');
  LMap := TMapFile.Create;
  try
    LMap.Name := 'maps/test';
    // the file system of the tests dates every file 1234
    LMap.FileTime := 1000;
    Assert.IsTrue(LMap.NeedsReload(LIntf));
    LMap.FileTime := 1234;
    Assert.IsFalse(LMap.NeedsReload(LIntf));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeChiedereIlCaricamentoSeNonTrovaIlFile;
var
  LMap: TMapFile;
  LIntf: IIdLibFileSystem;
begin
  LIntf := TIdLibMemoryFileSystem.Create;
  LMap := TMapFile.Create;
  try
    // without a name, and with a name that the file system does not have
    Assert.IsTrue(LMap.NeedsReload(LIntf));
    LMap.Name := 'maps/test';
    Assert.IsTrue(LMap.NeedsReload(LIntf));
    Assert.IsTrue(LMap.NeedsReload(nil));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileModel.DovrebbeDareLaRigaNellEccezione;
var
  LException: EMapFileException;
begin
  LException := EMapFileException.Create('bad', 12);
  try
    Assert.AreEqual(12, LException.Line);
    Assert.AreEqual('bad', LException.Message);
  finally
    LException.Free;
  end;
  LException := EMapFileException.Create('no line');
  try
    Assert.AreEqual(0, LException.Line);
  finally
    LException.Free;
  end;
end;

end.
