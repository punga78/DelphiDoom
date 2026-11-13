{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - reading (versions, brushes,     }
{  patches, directives of the worldspawn, files, errors)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestMapFileReader = class
  strict private
    FReader: IMapFileReader;
    function Parse(const AText: AnsiString): TMapFile;
    procedure ExpectError(const AText: AnsiString; const AMessagePart: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLaVersioneDelFile;
    [Test]
    procedure DovrebbeUsareLaVersioneVecchiaSenzaRigaVersion;
    [Test]
    procedure DovrebbeDareUnaMappaVuotaPerUnTestoVuoto;
    [Test]
    procedure DovrebbeLeggereLeCoppieDiUnEntita;
    [Test]
    procedure DovrebbeTogliereGliSpaziFinaliDaChiaviEValori;
    [Test]
    procedure DovrebbeLeggereUnBrushDef3;
    [Test]
    procedure DovrebbeLeggereLeCoppieDiUnBrush;
    [Test]
    procedure DovrebbeLeggereUnBrushConTrePunti;
    [Test]
    procedure DovrebbeSpostareITrePuntiDellOrigineDelLEntita;
    [Test]
    procedure DovrebbeNonSpostareIPianiDelFormatoNuovo;
    [Test]
    procedure DovrebbeAggiungereIlPrefissoTexturesNelleVersioniVecchie;
    [Test]
    procedure DovrebbeLeggereUnBrushDiQuake3;
    [Test]
    procedure DovrebbeLeggereUnaPatchDef3;
    [Test]
    procedure DovrebbeLeggereUnaPatchDef2;
    [Test]
    procedure DovrebbeMetterePerRigheIPuntiDellaPatch;
    [Test]
    procedure DovrebbeLeggereLeCoppieDiUnaPatch;
    [Test]
    procedure DovrebbeRifiutareUnaPatchTroppoGrande;
    [Test]
    procedure DovrebbeRifiutareUnaPatchConLarghezzaZero;
    [Test]
    procedure DovrebbeCalcolareIlCrcDellaGeometria;
    [Test]
    procedure DovrebbeRimuovereLeEntitaDiRemoveEntities;
    [Test]
    procedure DovrebbeCambiareTuttiIMaterialiConOverrideMaterial;
    [Test]
    procedure DovrebbeDareUnNomeAlleEntitaConForceEntityNames;
    [Test]
    procedure DovrebbeSpostareLeFuncGroupNelWorldspawn;
    [Test]
    procedure DovrebbeLeggereUnFileDalFileSystem;
    [Test]
    procedure DovrebbePreferireIlFileRegionSeEsiste;
    [Test]
    procedure DovrebbeIgnorareIlFileRegionSeRichiesto;
    [Test]
    procedure DovrebbeDareNilSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeSollevareConLaRigaPerUnEntitaNonChiusa;
    [Test]
    procedure DovrebbeSollevareSeMancaLaParentesiAperta;
    [Test]
    procedure DovrebbeSollevareSeUnaChiaveDelBrushNonEUnaStringa;
    [Test]
    procedure DovrebbeSollevareSeIlPianoDelBrushNonSiLegge;
    [Test]
    procedure DovrebbeSollevareSeLaMatriceDellaTextureNonSiLegge;
    [Test]
    procedure DovrebbeSollevareSeUnaRigaDellaPatchEIncompleta;
    [Test]
    procedure DovrebbeSollevareConLaClasseDedicata;
    [Test]
    procedure DovrebbeSollevareSeIlBrushFinisceNelMezzo;
    [Test]
    procedure DovrebbeSollevareSeLaChiaveDelBrushNonHaIlValore;
    [Test]
    procedure DovrebbeSollevareSeMancaIlMaterialeDelBrush;
    [Test]
    procedure DovrebbeSollevareSeIlBrushDiQuake3EIncompleto;
    [Test]
    procedure DovrebbeSollevareSeLaPatchEIncompleta;
    [Test]
    procedure DovrebbeSollevareConUnaDimensioneNegativaDellaPatch;
    [Test]
    procedure DovrebbeLimitareLeSuddivisioniDellaPatch;
    [Test]
    procedure DovrebbeSollevareSeLEntitaFinisceDopoLaParentesiDellaPrimitiva;
    [Test]
    procedure DovrebbeSollevareSeIlLexerNonSollevaDaSolo;  end;

implementation

uses
  System.Classes, DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Types,
  DelphiDoom.MapFile.Primitive, DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.Patch,
  DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Factory, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.MapFile.Dump, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.MapFile.ParseFailure;

const
  CUBE_MAP =
    'Version 2'#10 +
    '{'#10 +
    '"classname" "worldspawn"'#10 +
    '{'#10' brushDef3'#10' {'#10 +
    '  ( 1 0 0 -64 ) ( ( 0.03125 0 0 ) ( 0 0.03125 0 ) ) "textures/a" 0 0 0'#10 +
    '  ( -1 0 0 0 ) ( ( 0.5 0 0.25 ) ( 0 0.5 0.125 ) ) "textures/b" 0 0 0'#10 +
    ' }'#10'}'#10 +
    '}'#10;

function TTestMapFileReader.Parse(const AText: AnsiString): TMapFile;
begin
  Result := FReader.ParseText(AText, 'test.map');
end;

procedure TTestMapFileReader.ExpectError(const AText: AnsiString; const AMessagePart: string);
var
  LMap: TMapFile;
  LRaised: Boolean;
begin
  LRaised := False;
  LMap := nil;
  try
    try
      LMap := Parse(AText);
    except
      on E: EMapFileException do
      begin
        LRaised := True;
        Assert.IsTrue(Pos(AMessagePart, E.Message) > 0, 'message: ' + E.Message);
      end;
    end;
  finally
    LMap.Free;
  end;
  Assert.IsTrue(LRaised, 'EMapFileException expected for: ' + AMessagePart);
end;

procedure TTestMapFileReader.Setup;
begin
  FReader := TMapFileFactory.CreateReader(nil);
end;

procedure TTestMapFileReader.DovrebbeLeggereLaVersioneDelFile;
var
  LMap: TMapFile;
begin
  LMap := Parse(CUBE_MAP);
  try
    Assert.AreEqual<Single>(2, LMap.Version);
    Assert.AreEqual(1, LMap.GetNumEntities);
    Assert.IsTrue(LMap.HasPrimitiveData);
    Assert.AreEqual(AnsiString('test.map'), LMap.Name);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeUsareLaVersioneVecchiaSenzaRigaVersion;
var
  LMap: TMapFile;
begin
  LMap := Parse('{'#10'"classname" "worldspawn"'#10'}'#10);
  try
    Assert.AreEqual<Single>(OLD_MAP_VERSION, LMap.Version);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeDareUnaMappaVuotaPerUnTestoVuoto;
var
  LMap: TMapFile;
begin
  LMap := Parse('');
  try
    Assert.AreEqual(0, LMap.GetNumEntities);
    Assert.AreEqual<Cardinal>(0, LMap.GeometryCrc);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereLeCoppieDiUnEntita;
var
  LMap: TMapFile;
begin
  LMap := Parse('{'#10'"classname" "light"'#10'"origin" "1 2 3"'#10'}'#10'{'#10'"classname" "speaker"'#10'}'#10);
  try
    Assert.AreEqual(2, LMap.GetNumEntities);
    Assert.AreEqual(2, LMap.GetEntity(0).Epairs.GetNumKeyVals);
    Assert.AreEqual(AnsiString('light'), LMap.GetEntity(0).Epairs.GetString('CLASSNAME'));
    Assert.AreEqual(AnsiString('speaker'), LMap.GetEntity(1).Epairs.GetString('classname'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeTogliereGliSpaziFinaliDaChiaviEValori;
var
  LMap: TMapFile;
begin
  LMap := Parse('{'#10'"key  " "value   "'#10'}'#10);
  try
    Assert.AreEqual(AnsiString('value'), LMap.GetEntity(0).Epairs.GetString('key'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereUnBrushDef3;
var
  LMap: TMapFile;
  LBrush: TMapBrush;
  LSide: TMapBrushSide;
begin
  LMap := Parse(CUBE_MAP);
  try
    Assert.AreEqual(1, LMap.GetEntity(0).GetNumPrimitives);
    Assert.IsTrue(LMap.GetEntity(0).GetPrimitive(0).PrimitiveType = mptBrush);
    LBrush := TMapBrush(LMap.GetEntity(0).GetPrimitive(0));
    Assert.AreEqual(2, LBrush.GetNumSides);
    LSide := LBrush.GetSide(0);
    Assert.AreEqual<Single>(1, LSide.Plane.A);
    Assert.AreEqual<Single>(-64, LSide.Plane.D);
    Assert.AreEqual(AnsiString('textures/a'), LSide.Material);
    Assert.AreEqual<Single>(0.03125, LSide.TextureMatrix[0].X);
    Assert.AreEqual<Single>(0.03125, LSide.TextureMatrix[1].Y);
    LSide := LBrush.GetSide(1);
    Assert.AreEqual<Single>(0.25, LSide.TextureMatrix[0].Z);
    Assert.AreEqual<Single>(0.125, LSide.TextureMatrix[1].Z);
    Assert.AreEqual(AnsiString('textures/b'), LSide.Material);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereLeCoppieDiUnBrush;
var
  LMap: TMapFile;
begin
  LMap := Parse('{'#10'{'#10'brushDef3'#10'{'#10'"editor_color" "1 0 0"'#10'"x" "y"'#10 +
    '( 0 0 1 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) "m" 0 0 0'#10'}'#10'}'#10'}'#10);
  try
    Assert.AreEqual(AnsiString('1 0 0'), LMap.GetEntity(0).GetPrimitive(0).Epairs.GetString('editor_color'));
    Assert.AreEqual(2, LMap.GetEntity(0).GetPrimitive(0).Epairs.GetNumKeyVals);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereUnBrushConTrePunti;
var
  LMap: TMapFile;
  LSide: TMapBrushSide;
begin
  LMap := Parse('{'#10'{'#10'brushDef'#10'{'#10 +
    '( 0 0 0 ) ( 0 64 0 ) ( 64 0 0 ) ( ( 0.5 0 0 ) ( 0 0.5 0 ) ) "floor" 0 0 0'#10'}'#10'}'#10'}'#10);
  try
    LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0);
    // the plane of the points z = 0, with the length of the normal one
    Assert.AreEqual(Double(1), Double(Abs(LSide.Plane.C)), 0.0001);
    Assert.AreEqual(Double(0), Double(LSide.Plane.D), 0.0001);
    // without the second brushDef2/3 keyword a brush of the old format keeps the textures/ rule of the version
    Assert.AreEqual(AnsiString('textures/floor'), LSide.Material);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeSpostareITrePuntiDellOrigineDelLEntita;
var
  LMap: TMapFile;
  LSide: TMapBrushSide;
begin
  LMap := Parse('Version 2'#10'{'#10'"classname" "func_static"'#10'"origin" "100 200 300"'#10'{'#10'brushDef'#10'{'#10 +
    '( 100 200 305 ) ( 100 264 305 ) ( 164 200 305 ) ( ( 0.5 0 0 ) ( 0 0.5 0 ) ) "floor" 0 0 0'#10'}'#10'}'#10'}'#10);
  try
    LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0);
    // the points are 5 above the origin of the entity: z = 5 (the normal is +z or -z)
    Assert.AreEqual(Double(1), Double(Abs(LSide.Plane.C)), 0.0001);
    Assert.AreEqual(Double(5), Double(Abs(LSide.Plane.D)), 0.0001);
    Assert.AreEqual<Single>(100, LSide.Origin.X);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeNonSpostareIPianiDelFormatoNuovo;
var
  LMap: TMapFile;
  LSide: TMapBrushSide;
begin
  LMap := Parse('Version 2'#10'{'#10'"classname" "func_static"'#10'"origin" "100 200 300"'#10'{'#10'brushDef3'#10'{'#10 +
    '( 0 0 1 -5 ) ( ( 0.5 0 0 ) ( 0 0.5 0 ) ) "floor" 0 0 0'#10'}'#10'}'#10'}'#10);
  try
    LSide := TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0);
    Assert.AreEqual<Single>(-5, LSide.Plane.D);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeAggiungereIlPrefissoTexturesNelleVersioniVecchie;
var
  LMap: TMapFile;
begin
  LMap := Parse('Version 1'#10'{'#10'{'#10'brushDef3'#10'{'#10'( 0 0 1 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) "wall" 0 0 0'#10'}'#10'}'#10 +
    '{'#10'patchDef2'#10'{'#10'"curve"'#10'( 1 1 0 0 0 )'#10'('#10'( ( 0 0 0 0 0 ) )'#10')'#10'}'#10'}'#10'}'#10);
  try
    Assert.AreEqual(AnsiString('textures/wall'),
      TMapBrush(LMap.GetEntity(0).GetPrimitive(0)).GetSide(0).Material);
    Assert.AreEqual(AnsiString('textures/curve'), TMapPatch(LMap.GetEntity(0).GetPrimitive(1)).Material);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereUnBrushDiQuake3;
var
  LMap: TMapFile;
  LBrush: TMapBrush;
begin
  LMap := Parse('{'#10'"classname" "worldspawn"'#10'{'#10 +
    '( 0 0 0 ) ( 0 64 0 ) ( 64 0 0 ) tex/floor 16 8 45 0.5 0.25 0 0 0'#10 +
    '( 0 0 64 ) ( 64 0 64 ) ( 0 64 64 ) tex/ceil 0 0 0 1 1'#10 +
    '}'#10'}'#10);
  try
    LBrush := TMapBrush(LMap.GetEntity(0).GetPrimitive(0));
    Assert.AreEqual(2, LBrush.GetNumSides);
    Assert.AreEqual(AnsiString('textures/tex/floor'), LBrush.GetSide(0).Material);
    Assert.AreEqual(AnsiString('textures/tex/ceil'), LBrush.GetSide(1).Material);
    // shift, rotation and scale are dropped: the matrix is the fixed 1/32
    Assert.AreEqual<Single>(0.03125, LBrush.GetSide(0).TextureMatrix[0].X);
    Assert.AreEqual<Single>(0.03125, LBrush.GetSide(0).TextureMatrix[1].Y);
    Assert.AreEqual<Single>(0, LBrush.GetSide(0).TextureMatrix[0].Y);
    Assert.AreEqual(Double(64), Double(Abs(LBrush.GetSide(1).Plane.D) ), 0.0001);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereUnaPatchDef3;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
begin
  LMap := Parse(TMapDump.LoadData('v2_basic.map'));
  try
    LPatch := TMapPatch(LMap.GetEntity(0).GetPrimitive(2));
    Assert.AreEqual(3, LPatch.Width);
    Assert.AreEqual(3, LPatch.Height);
    Assert.AreEqual(4, LPatch.HorzSubdivisions);
    Assert.AreEqual(5, LPatch.VertSubdivisions);
    Assert.IsTrue(LPatch.ExplicitlySubdivided);
    Assert.AreEqual(AnsiString('textures/test/curve'), LPatch.Material);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereUnaPatchDef2;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
begin
  LMap := Parse(TMapDump.LoadData('v2_basic.map'));
  try
    LPatch := TMapPatch(LMap.GetEntity(1).GetPrimitive(1));
    Assert.AreEqual(3, LPatch.Width);
    Assert.AreEqual(2, LPatch.Height);
    Assert.IsFalse(LPatch.ExplicitlySubdivided);
    Assert.AreEqual(0, LPatch.HorzSubdivisions);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeMetterePerRigheIPuntiDellaPatch;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
begin
  LMap := Parse(TMapDump.LoadData('v2_basic.map'));
  try
    // the patch of the entity "mover_1" has origin (64, 32, 16): the file lists the columns, three of
    // two points each. The point (80 50 28 1 1) is the second of the second column: row 1, column 1
    LPatch := TMapPatch(LMap.GetEntity(1).GetPrimitive(1));
    Assert.AreEqual<Single>(16, LPatch.Vertices[1 * 3 + 1].Position.X);
    Assert.AreEqual<Single>(18, LPatch.Vertices[1 * 3 + 1].Position.Y);
    Assert.AreEqual<Single>(12, LPatch.Vertices[1 * 3 + 1].Position.Z);
    Assert.AreEqual<Single>(1, LPatch.Vertices[1 * 3 + 1].S);
    Assert.AreEqual<Single>(1, LPatch.Vertices[1 * 3 + 1].T);
    // (90 40 20 2 0): row 0, column 2
    Assert.AreEqual<Single>(26, LPatch.Vertices[2].Position.X);
    Assert.AreEqual<Single>(2, LPatch.Vertices[2].S);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereLeCoppieDiUnaPatch;
var
  LMap: TMapFile;
begin
  LMap := Parse(TMapDump.LoadData('keys.map'));
  try
    Assert.AreEqual(AnsiString('patch_value'), LMap.GetEntity(1).GetPrimitive(0).Epairs.GetString('patch_key'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeRifiutareUnaPatchTroppoGrande;
begin
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 5000 5000 0 0 0 )'#10'}'#10'}'#10'}'#10, 'bad size');
end;

procedure TTestMapFileReader.DovrebbeRifiutareUnaPatchConLarghezzaZero;
begin
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 0 3 0 0 0 )'#10'}'#10'}'#10'}'#10,
    'idSurface_Patch::SetSize: invalid patchWidth');
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 3 0 0 0 0 )'#10'}'#10'}'#10'}'#10,
    'idSurface_Patch::SetSize: invalid patchHeight');
end;

procedure TTestMapFileReader.DovrebbeCalcolareIlCrcDellaGeometria;
var
  LMap: TMapFile;
begin
  LMap := Parse(CUBE_MAP);
  try
    Assert.AreEqual<Cardinal>(LMap.GetEntity(0).GetGeometryCrc, LMap.GeometryCrc);
    Assert.IsTrue(LMap.GeometryCrc <> 0);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeRimuovereLeEntitaDiRemoveEntities;
var
  LMap: TMapFile;
begin
  LMap := Parse(TMapDump.LoadData('directives.map'));
  try
    // seven entities, the two "light" and the "info_player_start" are gone
    Assert.AreEqual(4, LMap.GetNumEntities);
    Assert.AreEqual(AnsiString('func_group'), LMap.GetEntity(1).Epairs.GetString('classname'));
    Assert.IsNull(LMap.FindEntity('nothing'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeCambiareTuttiIMaterialiConOverrideMaterial;
var
  LMap: TMapFile;
  LIndex: Integer;
  LWorld: TMapEntity;
begin
  LMap := Parse(TMapDump.LoadData('directives.map'));
  try
    LWorld := LMap.GetEntity(0);
    for LIndex := 0 to LWorld.GetNumPrimitives - 1 do
    begin
      if LWorld.GetPrimitive(LIndex).PrimitiveType = mptBrush then
        Assert.AreEqual(AnsiString('textures/common/override'),
          TMapBrush(LWorld.GetPrimitive(LIndex)).GetSide(0).Material)
      else
        Assert.AreEqual(AnsiString('textures/common/override'), TMapPatch(LWorld.GetPrimitive(LIndex)).Material);
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeDareUnNomeAlleEntitaConForceEntityNames;
var
  LMap: TMapFile;
begin
  LMap := Parse(TMapDump.LoadData('directives.map'));
  try
    // the number is the index after the removal; an entity that has a name keeps it
    Assert.AreEqual(AnsiString('func_group1'), LMap.GetEntity(1).Epairs.GetString('name'));
    Assert.AreEqual(AnsiString('func_static2'), LMap.GetEntity(2).Epairs.GetString('name'));
    Assert.AreEqual(AnsiString('already_named'), LMap.GetEntity(3).Epairs.GetString('name'));
    Assert.AreEqual(0, LMap.GetEntity(0).Epairs.FindKeyIndex('name') + 1, 'the worldspawn gets no name');
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeSpostareLeFuncGroupNelWorldspawn;
var
  LMap: TMapFile;
begin
  LMap := Parse(TMapDump.LoadData('directives.map'));
  try
    Assert.AreEqual(3, LMap.GetEntity(0).GetNumPrimitives);
    Assert.AreEqual(0, LMap.GetEntity(1).GetNumPrimitives);
    Assert.IsTrue(LMap.GetEntity(0).GetPrimitive(2).PrimitiveType = mptPatch);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeLeggereUnFileDalFileSystem;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LIntf: IIdLibFileSystem;
  LMap: TMapFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LIntf := LFileSystem;
  LFileSystem.SetFile('maps/cube.map', CUBE_MAP);
  LMap := TMapFileFactory.CreateReader(LIntf).Parse('maps/cube.map');
  try
    Assert.IsNotNull(LMap);
    Assert.AreEqual(AnsiString('maps/cube'), LMap.Name);
    Assert.AreEqual(Int64(1234), LMap.FileTime);
    Assert.AreEqual(1, LMap.GetEntity(0).GetNumPrimitives);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbePreferireIlFileRegionSeEsiste;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LIntf: IIdLibFileSystem;
  LMap: TMapFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LIntf := LFileSystem;
  LFileSystem.SetFile('m.map', '{'#10'"source" "map"'#10'}'#10);
  LFileSystem.SetFile('m.reg', '{'#10'"source" "reg"'#10'}'#10);
  LMap := TMapFileFactory.CreateReader(LIntf).Parse('m');
  try
    Assert.AreEqual(AnsiString('reg'), LMap.GetEntity(0).Epairs.GetString('source'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeIgnorareIlFileRegionSeRichiesto;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LIntf: IIdLibFileSystem;
  LMap: TMapFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LIntf := LFileSystem;
  LFileSystem.SetFile('m.map', '{'#10'"source" "map"'#10'}'#10);
  LFileSystem.SetFile('m.reg', '{'#10'"source" "reg"'#10'}'#10);
  LMap := TMapFileFactory.CreateReader(LIntf).Parse('m.map', True);
  try
    Assert.AreEqual(AnsiString('map'), LMap.GetEntity(0).Epairs.GetString('source'));
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeDareNilSeIlFileNonEsiste;
var
  LIntf: IIdLibFileSystem;
begin
  LIntf := TIdLibMemoryFileSystem.Create;
  Assert.IsNull(TMapFileFactory.CreateReader(LIntf).Parse('nothing'));
end;

procedure TTestMapFileReader.DovrebbeSollevareConLaRigaPerUnEntitaNonChiusa;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    FReader.ParseText('Version 2'#10'{'#10'"classname" "x"'#10, 'bad.map').Free;
  except
    on E: EMapFileException do
    begin
      LRaised := True;
      Assert.IsTrue(Pos('file bad.map, line 4', E.Message) > 0, E.Message);
      Assert.IsTrue(Pos('EOF without closing brace', E.Message) > 0, E.Message);
      Assert.AreEqual(4, E.Line);
    end;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestMapFileReader.DovrebbeSollevareSeMancaLaParentesiAperta;
begin
  ExpectError('"classname" "worldspawn"'#10, '{ not found, found classname');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeUnaChiaveDelBrushNonEUnaStringa;
begin
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10'17'#10'}'#10'}'#10'}'#10, 'unexpected 17, expected ( or epair key string');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeIlPianoDelBrushNonSiLegge;
begin
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10'( 0 0 1 ) ( ( 1 0 0 ) ( 0 1 0 ) ) "m" 0 0 0'#10'}'#10'}'#10'}'#10,
    'expected float value');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeLaMatriceDellaTextureNonSiLegge;
begin
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10'( 0 0 1 0 ) ( ( 1 0 ) ( 0 1 0 ) ) "m" 0 0 0'#10'}'#10'}'#10'}'#10,
    'expected float value');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeUnaRigaDellaPatchEIncompleta;
begin
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 2 1 0 0 0 )'#10'('#10'( ( 0 0 0 0 ) )'#10'( ( 0 0 0 0 0 ) )'#10 +
    ')'#10'}'#10'}'#10'}'#10, 'expected float value');
end;

procedure TTestMapFileReader.DovrebbeSollevareConLaClasseDedicata;
begin
  Assert.WillRaise(
    procedure
    begin
      FReader.ParseText('{ "a"', 'x.map').Free;
    end, EMapFileException);
end;

procedure TTestMapFileReader.DovrebbeSollevareSeIlBrushFinisceNelMezzo;
begin
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10, 'unexpected EOF');
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10'"key" "value"'#10, 'unexpected EOF');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeLaChiaveDelBrushNonHaIlValore;
begin
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10'"key" ( 0 0 1 0 )'#10'}'#10'}'#10'}'#10,
    'expected epair value string not found');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeMancaIlMaterialeDelBrush;
begin
  ExpectError('{'#10'{'#10'brushDef3'#10'{'#10'( 0 0 1 0 ) ( ( 1 0 0 ) ( 0 1 0 ) )'#10'"m" 0 0 0'#10'}'#10'}'#10'}'#10,
    'unable to read brush side material');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeIlBrushDiQuake3EIncompleto;
begin
  ExpectError('{'#10'{'#10'( 0 0 ) ( 0 1 0 ) ( 1 0 0 ) tex 0 0 0 1 1'#10'}'#10'}'#10, 'expected float value');
  ExpectError('{'#10'{'#10'( 0 0 0 ) ( 0 1 0 ) ( 1 0 0 )'#10'tex 0 0 0 1 1'#10'}'#10'}'#10,
    'unable to read brush side material');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeLaPatchEIncompleta;
begin
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10, 'unexpected EOF');
  ExpectError('{'#10'{'#10'patchDef3'#10'{'#10'"m"'#10'( 1 1 )'#10'}'#10'}'#10'}'#10, 'expected float value');
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 1 1 0 0 0 )'#10'('#10'( ( 0 0 0 0 0 ) ( 0 0 0 0 0 ) )'#10')'#10'}'#10'}'#10'}'#10,
    'expected '')'' but found ''(''');
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 1 1 0 0 0 )'#10'('#10'( ( 0 0 0 0 0 ) )'#10'}'#10'}'#10'}'#10,
    'expected '')'' but found');
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( 1 1 0 0 0 )'#10'( ('#10, 'couldn''t find expected');
end;

procedure TTestMapFileReader.DovrebbeSollevareConUnaDimensioneNegativaDellaPatch;
begin
  ExpectError('{'#10'{'#10'patchDef2'#10'{'#10'"m"'#10'( -3 2 0 0 0 )'#10'}'#10'}'#10'}'#10, 'bad size');
end;

procedure TTestMapFileReader.DovrebbeLimitareLeSuddivisioniDellaPatch;
var
  LMap: TMapFile;
  LPatch: TMapPatch;
begin
  LMap := Parse('{'#10'{'#10'patchDef3'#10'{'#10'"m"'#10'( 1 1 99999999999 -99999999999 0 0 0 )'#10 +
    '('#10'( ( 0 0 0 0 0 ) )'#10')'#10'}'#10'}'#10'}'#10);
  try
    LPatch := TMapPatch(LMap.GetEntity(0).GetPrimitive(0));
    Assert.AreEqual(1073741824, LPatch.HorzSubdivisions);
    Assert.AreEqual(-1073741824, LPatch.VertSubdivisions);
  finally
    LMap.Free;
  end;
end;

procedure TTestMapFileReader.DovrebbeSollevareSeLEntitaFinisceDopoLaParentesiDellaPrimitiva;
begin
  ExpectError('{'#10'{'#10, 'unexpected EOF');
end;

procedure TTestMapFileReader.DovrebbeSollevareSeIlLexerNonSollevaDaSolo;
var
  LLexer: TIdLexer;
  LRaised: Boolean;
begin
  // a lexer that only counts the errors (LEXFL_NOFATALERRORS) returns from Error: the reader still stops
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOERRORS);
  try
    LLexer.LoadMemory('a'#10'b', 'x');
    LRaised := False;
    try
      TMapParseFailure.Fail(LLexer, 'bad %s', ['thing']);
    except
      on E: EMapFileException do
      begin
        LRaised := True;
        Assert.AreEqual('bad thing', E.Message);
        Assert.AreEqual(1, E.Line);
      end;
    end;
    Assert.IsTrue(LRaised);
  finally
    LLexer.Free;
  end;
end;
end.
