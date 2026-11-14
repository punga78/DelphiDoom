{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - writing a .map file in the      }
{  format of Quake III Arena (q3_written.map is read by the real idMapFile in  }
{  mapfile.golden.txt)                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.Q3Writer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Entity,
  DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestMapQ3Writer = class
  strict private
    function DataFolder: string;
    function BuildBrush(const AOrigin: array of Single; const AMaterial: AnsiString): TMapBrush;
    function BuildSample: TMapFile;
    function Read(const AText: AnsiString): TMapFile;
  public
    /// <summary>
    ///   q3_written.map is the text this writer gives for the sample map; the file is in
    ///   cases.txt, so that the real idMapFile reads it and TTestMapFileGolden compares what it
    ///   found with what the classes of this library read from the same text
    /// </summary>
    [Test]
    procedure DovrebbeScrivereIlFileDiProva;
    [Test]
    procedure DovrebbeScrivereSenzaVersioneEConIMaterialiSenzaPrefisso;
    [Test]
    procedure DovrebbeRileggereIPianiDegliAssiEsattamente;
    [Test]
    procedure DovrebbeRileggereIPianiObliquiConUnaPiccolaTolleranza;
    [Test]
    procedure DovrebbeDareITrePuntiDiUnPianoNellOrdineGiusto;
    [Test]
    procedure DovrebbeRimettereLOrigineDellEntitaNeiPunti;
    [Test]
    procedure DovrebbeRileggereLeMaterialiConIlPrefisso;
    [Test]
    procedure DovrebbeRileggereLePatchConIPunti;
    [Test]
    procedure DovrebbeScrivereUnaPatchDef3ComePatchDef2;
    [Test]
    procedure DovrebbeNonScrivereLeCoppieDeiBrush;
    [Test]
    procedure DovrebbeScrivereNelFileSystemCambiandoLEstensione;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileSystemNonScrive;
    [Test]
    procedure DovrebbeDareFalsoSenzaFileSystem;
    [Test]
    procedure DovrebbeLasciareFuoriLeMaterialiGiaSenzaPrefisso;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Types, DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.Patch,
  DelphiDoom.MapFile.Factory, DelphiDoom.MapFile.Q3BrushWriter, DelphiDoom.Tests.IdLib.Fakes;

type
  TRefusingFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  public
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

function TRefusingFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
begin
  Result := False;
end;

function TRefusingFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

function MakeSide(const AA, AB, AC, AD: Single; const AMaterial: AnsiString; const AOrigin: TGeoVec3): TMapBrushSide;
begin
  Result := TMapBrushSide.Create;
  Result.Plane := TGeoPlane.Make(AA, AB, AC, AD);
  Result.Material := AMaterial;
  Result.Origin := AOrigin;
  Result.TextureMatrix[0] := TGeoVec3.Make(0.03125, 0, 0);
  Result.TextureMatrix[1] := TGeoVec3.Make(0, 0.03125, 0);
end;

{ TTestMapQ3Writer }

function TTestMapQ3Writer.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\MapFile\');
end;

function TTestMapQ3Writer.BuildBrush(const AOrigin: array of Single; const AMaterial: AnsiString): TMapBrush;
var
  LBrush: TMapBrush;
  LOrigin: TGeoVec3;
begin
  LOrigin := TGeoVec3.Make(AOrigin[0], AOrigin[1], AOrigin[2]);
  LBrush := TMapBrush.Create;
  // a box 0..64 and the planes in front of the points: x = 64 and -x = 0 and so on
  LBrush.AddSide(MakeSide(1, 0, 0, -64, AMaterial, LOrigin));
  LBrush.AddSide(MakeSide(-1, 0, 0, 0, AMaterial, LOrigin));
  LBrush.AddSide(MakeSide(0, 1, 0, -64, AMaterial, LOrigin));
  LBrush.AddSide(MakeSide(0, -1, 0, 0, AMaterial, LOrigin));
  LBrush.AddSide(MakeSide(0, 0, 1, -64, AMaterial, LOrigin));
  LBrush.AddSide(MakeSide(0, 0, -1, 0, AMaterial, LOrigin));
  Result := LBrush;
end;

function TTestMapQ3Writer.BuildSample: TMapFile;
var
  LEntity: TMapEntity;
  LBrush: TMapBrush;
  LPatch: TMapPatch;
  LVertex: TMapPatchVertex;
  LColumn, LRow: Integer;
begin
  Result := TMapFile.Create;
  try
    // the world: a box, a brush with an oblique side and a patch
    LEntity := TMapEntity.Create;
    Result.AddEntity(LEntity);
    LEntity.Epairs.SetValue('classname', 'worldspawn');
    LEntity.Epairs.SetValue('message', 'q3 sample');
    LEntity.AddPrimitive(BuildBrush([0, 0, 0], 'textures/base_wall/metal'));
    LBrush := TMapBrush.Create;
    LBrush.AddSide(MakeSide(0.6, 0.8, 0, -100, 'textures/base_wall/oblique', TGeoVec3.Origin));
    LBrush.AddSide(MakeSide(0, 0, 1, -32, 'textures/base_wall/oblique', TGeoVec3.Origin));
    LBrush.AddSide(MakeSide(-0.6, -0.8, 0, 40, 'common/caulk', TGeoVec3.Origin));
    LBrush.Epairs.SetValue('ignored', 'pair of a brush');
    LEntity.AddPrimitive(LBrush);
    LPatch := TMapPatch.Create(3, 3);
    LPatch.Material := 'textures/gothic_block/curve';
    for LColumn := 0 to 2 do
      for LRow := 0 to 2 do
      begin
        LVertex.Position := TGeoVec3.Make(LColumn * 64, LRow * 64, (LColumn * LRow) * 16);
        LVertex.S := LColumn * 0.5;
        LVertex.T := LRow * 0.25;
        LPatch.Vertices[LRow * 3 + LColumn] := LVertex;
      end;
    LEntity.AddPrimitive(LPatch);

    // an entity with an origin: the points are written moved
    LEntity := TMapEntity.Create;
    Result.AddEntity(LEntity);
    LEntity.Epairs.SetValue('classname', 'func_static');
    LEntity.Epairs.SetValue('origin', '100 200 300');
    LEntity.AddPrimitive(BuildBrush([100, 200, 300], 'textures/base_wall/moved'));
    LPatch := TMapPatch.Create(3, 5);
    LPatch.Material := 'textures/gothic_block/moved';
    LPatch.HorzSubdivisions := 8;
    LPatch.VertSubdivisions := 8;
    LPatch.ExplicitlySubdivided := True;
    for LColumn := 0 to 2 do
      for LRow := 0 to 4 do
      begin
        LVertex.Position := TGeoVec3.Make(LColumn * 8, LRow * 8, 4);
        LVertex.S := LColumn;
        LVertex.T := LRow;
        LPatch.Vertices[LRow * 3 + LColumn] := LVertex;
      end;
    LEntity.AddPrimitive(LPatch);
  except
    Result.Free;
    raise;
  end;
end;

function TTestMapQ3Writer.Read(const AText: AnsiString): TMapFile;
begin
  Result := TMapFileFactory.CreateReader(nil).ParseText(AText, 'q3');
end;

procedure TTestMapQ3Writer.DovrebbeScrivereIlFileDiProva;
var
  LMap: TMapFile;
  LText: AnsiString;
  LBytes: TBytes;
  LExpected: AnsiString;
begin
  LMap := BuildSample;
  try
    LText := TMapFileFactory.CreateQ3Writer(nil).ToText(LMap);
  finally
    LMap.Free;
  end;
  Assert.IsTrue(TFile.Exists(DataFolder + 'q3_written.map'), 'q3_written.map not found in ' + DataFolder);
  LBytes := TFile.ReadAllBytes(DataFolder + 'q3_written.map');
  SetLength(LExpected, Length(LBytes));
  Move(LBytes[0], LExpected[1], Length(LBytes));
  if LText <> LExpected then
    TFile.WriteAllBytes(ChangeFileExt(ParamStr(0), '.q3_written.actual.map'), BytesOf(LText));
  Assert.AreEqual(string(LExpected), string(LText));
end;

procedure TTestMapQ3Writer.DovrebbeScrivereSenzaVersioneEConIMaterialiSenzaPrefisso;
var
  LMap: TMapFile;
  LText: string;
begin
  LMap := BuildSample;
  try
    LText := string(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
  finally
    LMap.Free;
  end;
  Assert.IsFalse(LText.Contains('Version'));
  Assert.IsFalse(LText.Contains('textures/'));
  Assert.IsTrue(LText.Contains('base_wall/metal 0 0 0 0.5 0.5 0 0 0'));
  Assert.IsTrue(LText.Contains('// entity 1'));
  Assert.IsTrue(LText.Contains('// brush 2'));
  Assert.IsTrue(LText.Contains('patchDef2'));
  Assert.IsFalse(LText.Contains('brushDef3'));
end;

procedure TTestMapQ3Writer.DovrebbeRileggereIPianiDegliAssiEsattamente;
var
  LMap, LBack: TMapFile;
  LSide, LBackSide: TMapBrushSide;
  LIndex: Integer;
begin
  LMap := BuildSample;
  try
    LBack := Read(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    try
      for LIndex := 0 to 5 do
      begin
        LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(LIndex);
        LBackSide := TMapBrush(LBack.GetEntity(0).GetPrimitive(0)).GetSide(LIndex);
        Assert.IsTrue(LSide.Plane.Compare(LBackSide.Plane), 'side ' + IntToStr(LIndex));
      end;
    finally
      LBack.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeRileggereIPianiObliquiConUnaPiccolaTolleranza;
var
  LMap, LBack: TMapFile;
  LIndex: Integer;
begin
  LMap := BuildSample;
  try
    LBack := Read(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    try
      for LIndex := 0 to 2 do
        Assert.IsTrue(TMapBrush(LMap.GetEntity(0).GetPrimitive(1)).GetSide(LIndex).Plane.Compare(
          TMapBrush(LBack.GetEntity(0).GetPrimitive(1)).GetSide(LIndex).Plane, 0.0001, 0.001), 'side ' + IntToStr(LIndex));
    finally
      LBack.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeDareITrePuntiDiUnPianoNellOrdineGiusto;
var
  LPoint1, LPoint2, LPoint3: TGeoVec3;
  LPlane, LBack: TGeoPlane;
begin
  // the three points of a plane give the plane back, whatever the direction of its normal
  LPlane := TGeoPlane.Make(0, 0, -1, 24);
  TMapQ3BrushWriter.PlanePoints(LPlane, TGeoVec3.Origin, LPoint1, LPoint2, LPoint3);
  LBack := TGeoPlane.Make(0, 0, 0, 0);
  Assert.IsTrue(LBack.FromPoints(LPoint1, LPoint2, LPoint3));
  Assert.IsTrue(LPlane.Compare(LBack));
  LPlane := TGeoPlane.Make(0, 1, 0, 0);
  TMapQ3BrushWriter.PlanePoints(LPlane, TGeoVec3.Make(10, 0, 0), LPoint1, LPoint2, LPoint3);
  Assert.AreEqual<Single>(10, LPoint2.X);
  Assert.AreEqual<Single>(0, LPoint2.Y);
end;

procedure TTestMapQ3Writer.DovrebbeRimettereLOrigineDellEntitaNeiPunti;
var
  LMap, LBack: TMapFile;
  LText: string;
  LSide: TMapBrushSide;
begin
  LMap := BuildSample;
  try
    LText := string(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    // the plane x = 64 of the brush is the plane x = 164 for the file, and the points of the
    // patch are moved by the origin (100 200 300)
    Assert.IsTrue(LText.Contains('( 100 200 300 ) '), 'the point of a patch or a plane at the origin');
    LBack := Read(AnsiString(LText));
    try
      LSide := TMapBrush(LBack.GetEntity(1).GetPrimitive(0)).GetSide(0);
      Assert.IsTrue(TGeoPlane.Make(1, 0, 0, -64).Compare(LSide.Plane), 'plane relative to the origin');
      Assert.AreEqual<Single>(100, LSide.Origin.X);
      Assert.AreEqual<Single>(4, TMapPatch(LBack.GetEntity(1).GetPrimitive(1)).Vertices[0].Position.Z);
      Assert.IsTrue(LText.Contains('( 100 200 304 0 0 )'), 'the first point of the patch, moved');
    finally
      LBack.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeRileggereLeMaterialiConIlPrefisso;
var
  LMap, LBack: TMapFile;
begin
  LMap := BuildSample;
  try
    LBack := Read(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    try
      Assert.AreEqual('textures/base_wall/metal', string(TMapBrush(LBack.GetEntity(0).GetPrimitive(0)).GetSide(3).Material));
      Assert.AreEqual('textures/gothic_block/curve', string(TMapPatch(LBack.GetEntity(0).GetPrimitive(2)).Material));
    finally
      LBack.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeRileggereLePatchConIPunti;
var
  LMap, LBack: TMapFile;
  LPatch, LBackPatch: TMapPatch;
  LIndex: Integer;
begin
  LMap := BuildSample;
  try
    LBack := Read(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    try
      LPatch := TMapPatch(LMap.GetEntity(0).GetPrimitive(2));
      LBackPatch := TMapPatch(LBack.GetEntity(0).GetPrimitive(2));
      Assert.AreEqual<Integer>(LPatch.Width, LBackPatch.Width);
      Assert.AreEqual<Integer>(LPatch.Height, LBackPatch.Height);
      for LIndex := 0 to LPatch.GetNumVertices - 1 do
      begin
        Assert.AreEqual<Single>(LPatch.Vertices[LIndex].Position.X, LBackPatch.Vertices[LIndex].Position.X);
        Assert.AreEqual<Single>(LPatch.Vertices[LIndex].Position.Z, LBackPatch.Vertices[LIndex].Position.Z);
        Assert.AreEqual<Single>(LPatch.Vertices[LIndex].S, LBackPatch.Vertices[LIndex].S);
        Assert.AreEqual<Single>(LPatch.Vertices[LIndex].T, LBackPatch.Vertices[LIndex].T);
      end;
    finally
      LBack.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeScrivereUnaPatchDef3ComePatchDef2;
var
  LMap, LBack: TMapFile;
begin
  LMap := BuildSample;
  try
    LBack := Read(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    try
      Assert.IsFalse(TMapPatch(LBack.GetEntity(1).GetPrimitive(1)).ExplicitlySubdivided);
      Assert.AreEqual<Integer>(3, TMapPatch(LBack.GetEntity(1).GetPrimitive(1)).Width);
      Assert.AreEqual<Integer>(5, TMapPatch(LBack.GetEntity(1).GetPrimitive(1)).Height);
    finally
      LBack.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeNonScrivereLeCoppieDeiBrush;
var
  LMap: TMapFile;
begin
  LMap := BuildSample;
  try
    Assert.IsFalse(string(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap)).Contains('pair of a brush'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeScrivereNelFileSystemCambiandoLEstensione;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LWriter: IMapFileWriter;
  LMap: TMapFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LWriter := TMapFileFactory.CreateQ3Writer(LFileSystem, TIdLibLogRecorder.Create);
  LMap := BuildSample;
  try
    Assert.IsTrue(LWriter.Write(LMap, 'maps/test.txt', 'map'));
    Assert.AreEqual(LWriter.ToText(LMap), LFileSystem.GetFile('maps/test.map'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeDareFalsoSeIlFileSystemNonScrive;
var
  LMap: TMapFile;
  LLog: TIdLibLogRecorder;
  LLogIntf: IIdLibLog;
begin
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  LMap := BuildSample;
  try
    Assert.IsFalse(TMapFileFactory.CreateQ3Writer(TRefusingFileSystem.Create, LLogIntf).Write(LMap, 'x', 'map'));
    Assert.AreEqual<Integer>(2, LLog.Entries.Count);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeDareFalsoSenzaFileSystem;
var
  LMap: TMapFile;
begin
  LMap := BuildSample;
  try
    Assert.IsFalse(TMapFileFactory.CreateQ3Writer(nil).Write(LMap, 'x', 'map'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapQ3Writer.DovrebbeLasciareFuoriLeMaterialiGiaSenzaPrefisso;
var
  LMap: TMapFile;
  LText: string;
begin
  LMap := BuildSample;
  try
    LText := string(TMapFileFactory.CreateQ3Writer(nil).ToText(LMap));
    // a material that did not have the prefix is written as it is
    Assert.IsTrue(LText.Contains('common/caulk 0 0 0'));
  finally
    LMap.Free;
  end;
end;

end.
