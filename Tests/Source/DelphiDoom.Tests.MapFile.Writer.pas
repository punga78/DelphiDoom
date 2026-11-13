{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - writing, and reading what was   }
{  written                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.Writer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Map,
  DelphiDoom.MapFile.Intf;

type
  /// <summary>A file system that cannot write</summary>
  TReadOnlyFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  public
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapFileWriter = class
  strict private
    FWriter: IMapFileWriter;
    FReader: IMapFileReader;
    function BuildMap: TMapFile;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeScrivereLaRigaVersionELeEntita;
    [Test]
    procedure DovrebbeScrivereUnBrushDef3;
    [Test]
    procedure DovrebbeScrivereUnaPatchDef2;
    [Test]
    procedure DovrebbeScrivereUnaPatchDef3;
    [Test]
    procedure DovrebbeRimettereLOrigineNelleSolePatch;
    [Test]
    procedure DovrebbeScrivereIFloatConDieciDecimaliSenzaZeriFinali;
    [Test]
    procedure DovrebbeArrotondareAlPariUnaParitaEsatta;
    [Test]
    procedure DovrebbeScrivereIlMenoDelloZeroNegativo;
    [Test]
    procedure DovrebbeScrivereUnaMappaVuotaConLaSolaVersione;
    [Test]
    procedure DovrebbeLeggereCioCheHaScrittoConLeStesseCifre;
    [Test]
    procedure DovrebbeDareLoStessoTestoDopoDueGiriDiLetturaEScrittura;
    [Test]
    procedure DovrebbeTenereIlCrcDellaGeometriaNelGiro;
    [Test]
    procedure DovrebbeConvertireUnFileDiUnaVersioneVecchiaAllaCorrente;
    [Test]
    procedure DovrebbeScrivereNelFileSystemConLEstensioneDataDalChiamante;
    [Test]
    procedure DovrebbeAnnunciareLaScritturaNelLog;
    [Test]
    procedure DovrebbeDareFalsoESegnalareSeNonPuoScrivere;
    [Test]
    procedure DovrebbeDareFalsoSenzaFileSystem;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestMapFileFactory = class
  public
    [Test]
    procedure DovrebbeCreareLettoreEScrittore;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Brush,
  DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Factory,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.MapFile.Dump;

{ TReadOnlyFileSystem }

function TReadOnlyFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
begin
  Result := False;
end;

function TReadOnlyFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

{ TTestMapFileWriter }

procedure TTestMapFileWriter.Setup;
begin
  FWriter := TMapFileFactory.CreateWriter(nil);
  FReader := TMapFileFactory.CreateReader(nil);
end;

function TTestMapFileWriter.BuildMap: TMapFile;
var
  LEntity: TMapEntity;
  LBrush: TMapBrush;
  LSide: TMapBrushSide;
  LMatrix: TGeoVec3;
begin
  Result := TMapFile.Create;
  LEntity := TMapEntity.Create;
  LEntity.Epairs.SetValue('classname', 'worldspawn');
  LBrush := TMapBrush.Create;
  LBrush.Epairs.SetValue('editor_color', '1 0 0');
  LSide := TMapBrushSide.Create;
  LSide.Material := 'textures/a';
  LSide.Plane := TGeoPlane.Make(0, 0, 1, -16);
  LMatrix.SetValues(0.5, 0, 0.25);
  LSide.TextureMatrix[0] := LMatrix;
  LMatrix.SetValues(0, 0.5, 0);
  LSide.TextureMatrix[1] := LMatrix;
  LBrush.AddSide(LSide);
  LEntity.AddPrimitive(LBrush);
  Result.AddEntity(LEntity);
end;

procedure TTestMapFileWriter.DovrebbeScrivereLaRigaVersionELeEntita;
var
  LMap: TMapFile;
begin
  LMap := BuildMap;
  try
    Assert.AreEqual(AnsiString(
      'Version 2'#10 +
      '// entity 0'#10 +
      '{'#10 +
      '"classname" "worldspawn"'#10 +
      '// primitive 0'#10 +
      '{'#10 +
      ' brushDef3'#10 +
      ' {'#10 +
      '  "editor_color" "1 0 0"'#10 +
      '  ( 0 0 1 -16 ) ( ( 0.5 0 0.25 ) ( 0 0.5 0 ) ) "textures/a" 0 0 0'#10 +
      ' }'#10 +
      '}'#10 +
      '}'#10), FWriter.ToText(LMap));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereUnBrushDef3;
var
  LMap: TMapFile;
  LText: AnsiString;
begin
  LMap := BuildMap;
  try
    LText := FWriter.ToText(LMap);
    Assert.IsTrue(Pos(AnsiString(' brushDef3'#10), LText) > 0);
    Assert.IsTrue(Pos(AnsiString('( 0 0 1 -16 ) ( ( 0.5 0 0.25 ) ( 0 0.5 0 ) ) "textures/a" 0 0 0'#10), LText) > 0);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereUnaPatchDef2;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
  LVertex: TMapPatchVertex;
  LText: AnsiString;
begin
  LMap := TMapFile.Create;
  try
    LMap.AddEntity(TMapEntity.Create);
    LPatch := TMapPatch.Create(2, 1);
    LPatch.Material := 'textures/p';
    LVertex.Position.SetValues(1, 2, 3);
    LVertex.S := 0.5;
    LVertex.T := 1;
    LPatch.Vertices[0] := LVertex;
    LVertex.Position.SetValues(4, 5, 6);
    LPatch.Vertices[1] := LVertex;
    LMap.GetEntity(0).AddPrimitive(LPatch);
    LText := FWriter.ToText(LMap);
    Assert.AreEqual(AnsiString(
      'Version 2'#10 +
      '// entity 0'#10 +
      '{'#10 +
      '// primitive 0'#10 +
      '{'#10 +
      ' patchDef2'#10 +
      ' {'#10 +
      '  "textures/p"'#10 +
      '  ( 2 1 0 0 0 )'#10 +
      '  ('#10 +
      '   (  ( 1 2 3 0.5 1 ) )'#10 +
      '   (  ( 4 5 6 0.5 1 ) )'#10 +
      '  )'#10 +
      ' }'#10 +
      '}'#10 +
      '}'#10), LText);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereUnaPatchDef3;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
  LText: AnsiString;
begin
  LMap := TMapFile.Create;
  try
    LMap.AddEntity(TMapEntity.Create);
    LPatch := TMapPatch.Create(1, 1);
    LPatch.Material := 'm';
    LPatch.ExplicitlySubdivided := True;
    LPatch.HorzSubdivisions := 4;
    LPatch.VertSubdivisions := 5;
    LMap.GetEntity(0).AddPrimitive(LPatch);
    LText := FWriter.ToText(LMap);
    Assert.IsTrue(Pos(AnsiString(' patchDef3'#10), LText) > 0);
    Assert.IsTrue(Pos(AnsiString('  ( 1 1 4 5 0 0 0 )'#10), LText) > 0);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeRimettereLOrigineNelleSolePatch;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
  LVertex: TMapPatchVertex;
  LBrush: TMapBrush;
  LSide: TMapBrushSide;
  LText: AnsiString;
begin
  LMap := TMapFile.Create;
  try
    LMap.AddEntity(TMapEntity.Create);
    LMap.GetEntity(0).Epairs.SetValue('origin', '10 20 30');
    LPatch := TMapPatch.Create(1, 1);
    LVertex.Position.SetValues(1, 2, 3);
    LVertex.S := 0;
    LVertex.T := 0;
    LPatch.Vertices[0] := LVertex;
    LMap.GetEntity(0).AddPrimitive(LPatch);
    LBrush := TMapBrush.Create;
    LSide := TMapBrushSide.Create;
    LSide.Plane := TGeoPlane.Make(0, 0, 1, 7);
    LBrush.AddSide(LSide);
    LMap.GetEntity(0).AddPrimitive(LBrush);
    LText := FWriter.ToText(LMap);
    // the point is moved by the origin; the plane of the brush is not
    Assert.IsTrue(Pos(AnsiString('( 11 22 33 0 0 )'), LText) > 0, string(LText));
    Assert.IsTrue(Pos(AnsiString('( 0 0 1 7 )'), LText) > 0, string(LText));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereIFloatConDieciDecimaliSenzaZeriFinali;
var
  LMap: TMapFile;
  LSide: TMapBrushSide;
  LText: AnsiString;
begin
  LMap := BuildMap;
  try
    LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0);
    // the float 0.1 is 0.100000001490116...; 1/3 is 0.3333333432674408...
    LSide.Plane := TGeoPlane.Make(0.1, 1 / 3, 123456789, 1E-12);
    LText := FWriter.ToText(LMap);
    Assert.IsTrue(Pos(AnsiString('( 0.1000000015 0.3333333433 123456792 0 )'), LText) > 0, string(LText));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeArrotondareAlPariUnaParitaEsatta;
var
  LMap: TMapFile;
  LSide: TMapBrushSide;
  LText: AnsiString;
begin
  LMap := BuildMap;
  try
    LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0);
    // 2^-11 is 0.00048828125, exactly halfway between 0.0004882812 and 0.0004882813: the C library gives the even one
    LSide.Plane := TGeoPlane.Make(0.00048828125, 0, 0, 0);
    LText := FWriter.ToText(LMap);
    Assert.IsTrue(Pos(AnsiString('( 0.0004882812 0 0 0 )'), LText) > 0, string(LText));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereIlMenoDelloZeroNegativo;
var
  LNegativeZero: Single;
  LMap: TMapFile;
  LSide: TMapBrushSide;
  LText: AnsiString;
begin
  LMap := BuildMap;
  try
    LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0);
    LNegativeZero := 0;
    PCardinal(@LNegativeZero)^ := $80000000;
    LSide.Plane := TGeoPlane.Make(LNegativeZero, 0, 0, 0);
    LText := FWriter.ToText(LMap);
    Assert.IsTrue(Pos(AnsiString('( -0 0 0 0 )'), LText) > 0, string(LText));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereUnaMappaVuotaConLaSolaVersione;
var
  LMap: TMapFile;
begin
  LMap := TMapFile.Create;
  try
    Assert.AreEqual(AnsiString('Version 2'#10), FWriter.ToText(LMap));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeLeggereCioCheHaScrittoConLeStesseCifre;
var
  LMap, LRead: TMapFile;
  LSide: TMapBrushSide;
begin
  LMap := BuildMap;
  try
    LRead := FReader.ParseText(FWriter.ToText(LMap), 'x');
    try
      LSide := TMapBrush(LRead.GetEntity(0).GetPrimitive(0)).GetSide(0);
      Assert.AreEqual(AnsiString('textures/a'), LSide.Material);
      Assert.AreEqual<Single>(-16, LSide.Plane.D);
      Assert.AreEqual<Single>(0.25, LSide.TextureMatrix[0].Z);
      Assert.AreEqual(AnsiString('1 0 0'), LRead.GetEntity(0).GetPrimitive(0).Epairs.GetString('editor_color'));
    finally
      LRead.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeDareLoStessoTestoDopoDueGiriDiLetturaEScrittura;
var
  LMap, LRead: TMapFile;
  LFirst, LSecond: AnsiString;
begin
  LMap := FReader.ParseText(TMapDump.LoadData('v2_basic.map'), 'v2_basic');
  try
    LFirst := FWriter.ToText(LMap);
    LRead := FReader.ParseText(LFirst, 'again');
    try
      LSecond := FWriter.ToText(LRead);
    finally
      LRead.Free;
    end;
    Assert.AreEqual(LFirst, LSecond);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeTenereIlCrcDellaGeometriaNelGiro;
var
  LMap, LFirst, LSecond: TMapFile;
begin
  // the first rewrite may move a float by one unit in the last place (ten decimals, and the number
  // conversion of the lexer is not exact); from then on the checksum does not change any more
  LMap := FReader.ParseText(TMapDump.LoadData('v2_basic.map'), 'v2_basic');
  try
    LFirst := FReader.ParseText(FWriter.ToText(LMap), 'first');
    try
      LSecond := FReader.ParseText(FWriter.ToText(LFirst), 'second');
      try
        Assert.AreEqual<Cardinal>(LFirst.GeometryCrc, LSecond.GeometryCrc);
        Assert.IsTrue(LFirst.GeometryCrc <> 0);
      finally
        LSecond.Free;
      end;
    finally
      LFirst.Free;
    end;
  finally
    LMap.Free;
  end;
end;
procedure TTestMapFileWriter.DovrebbeConvertireUnFileDiUnaVersioneVecchiaAllaCorrente;
var
  LMap, LRead: TMapFile;
  LText: AnsiString;
begin
  LMap := FReader.ParseText(TMapDump.LoadData('v1_old.map'), 'v1_old');
  try
    Assert.AreEqual<Single>(1, LMap.Version);
    LText := FWriter.ToText(LMap);
    Assert.AreEqual(AnsiString('Version 2'), Copy(LText, 1, 9));
    LRead := FReader.ParseText(LText, 'v2');
    try
      Assert.AreEqual<Single>(2, LRead.Version);
      // the materials already have the textures/ prefix, which version 2 does not add again
      Assert.AreEqual(AnsiString('textures/base/floor'),
        TMapBrush(LRead.GetEntity(0).GetPrimitive(0)).GetSide(0).Material);
      Assert.AreEqual<Cardinal>(LMap.GeometryCrc, LRead.GeometryCrc);
    finally
      LRead.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeScrivereNelFileSystemConLEstensioneDataDalChiamante;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LIntf: IIdLibFileSystem;
  LMap: TMapFile;
  LWriter: IMapFileWriter;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LIntf := LFileSystem;
  LWriter := TMapFileFactory.CreateWriter(LIntf);
  LMap := BuildMap;
  try
    Assert.IsTrue(LWriter.Write(LMap, 'maps/test.old', 'map'));
    Assert.AreEqual(LWriter.ToText(LMap), LFileSystem.GetFile('maps/test.map'));
    Assert.IsTrue(LWriter.Write(LMap, 'maps/test', 'reg'));
    Assert.AreEqual(LWriter.ToText(LMap), LFileSystem.GetFile('maps/test.reg'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeAnnunciareLaScritturaNelLog;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFileSystemIntf: IIdLibFileSystem;
  LLog: TIdLibLogRecorder;
  LLogIntf: IIdLibLog;
  LMap: TMapFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LFileSystemIntf := LFileSystem;
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  LMap := BuildMap;
  try
    TMapFileFactory.CreateWriter(LFileSystemIntf, LLogIntf).Write(LMap, 'a/b', 'map');
    Assert.AreEqual(1, LLog.Entries.Count);
    Assert.AreEqual('P:writing a/b.map...'#10, LLog.Entries[0]);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeDareFalsoESegnalareSeNonPuoScrivere;
var
  LFileSystem: IIdLibFileSystem;
  LLog: TIdLibLogRecorder;
  LLogIntf: IIdLibLog;
  LMap: TMapFile;
begin
  LFileSystem := TReadOnlyFileSystem.Create;
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  LMap := BuildMap;
  try
    Assert.IsFalse(TMapFileFactory.CreateWriter(LFileSystem, LLogIntf).Write(LMap, 'a/b', 'map'));
    Assert.AreEqual(2, LLog.Entries.Count);
    Assert.AreEqual('W:Couldn''t open a/b.map'#10, LLog.Entries[1]);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileWriter.DovrebbeDareFalsoSenzaFileSystem;
var
  LMap: TMapFile;
begin
  LMap := BuildMap;
  try
    Assert.IsFalse(FWriter.Write(LMap, 'a/b', 'map'));
  finally
    LMap.Free;
  end;
end;

{ TTestMapFileFactory }

procedure TTestMapFileFactory.DovrebbeCreareLettoreEScrittore;
begin
  Assert.IsNotNull(TMapFileFactory.CreateReader(nil));
  Assert.IsNotNull(TMapFileFactory.CreateWriter(nil));
end;

end.
