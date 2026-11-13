{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - Maya ASCII (MA) models         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticMa;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Ma.Types,
  DelphiDoom.Tests.Models.GoldenLines;

type
  /// <summary>
  ///   The files of Tests\Data\Models\ma read by the Pascal classes against ma.golden.txt, the
  ///   output of the real Model_ma.cpp (MA_Parse with idParser) and of ConvertMAToModelSurfaces
  ///   compiled with bcc32c (see the README of the folder). Tolerance: 2 ULP, or 4e-6 relative,
  ///   or 1e-5 absolute.
  /// </summary>
  [TestFixture]
  [Category('Ma')]
  TTestMaParity = class
  strict private
    FGolden: TGoldenLines;
    function Parse(const AFile: string): TMaModel;
    procedure CheckFloats(const AWhat: string; const AExpected, AActual: TArray<Single>);
    procedure CheckParsed(const AFile: string);
    procedure CheckConverted(const AFile, ATag: string; const AOptions: TStaticLoadOptions);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('quad', 'quad.ma')]
    [TestCase('parti', 'parts.ma')]
    [TestCase('semplice', 'plain.ma')]
    procedure DovrebbeLeggereLeStesseRisposteDelCpp(const AFile: string);
    [Test]
    [TestCase('quad', 'quad.ma')]
    [TestCase('parti', 'parts.ma')]
    [TestCase('semplice', 'plain.ma')]
    procedure DovrebbeConvertireComeIlCpp(const AFile: string);
    [Test]
    [TestCase('faccia non triangolare', 'err_quadface.ma')]
    [TestCase('connessione senza punto', 'err_connect.ma')]
    [TestCase('vettore non double3', 'err_vec3.ma')]
    [TestCase('troppe poche normali', 'err_normals.ma')]
    procedure DovrebbeDareLoStessoErroreDelCpp(const AFile: string);
  end;

  /// <summary>Cases of the MA reader and loader that the C++ files do not reach</summary>
  [TestFixture]
  [Category('Ma')]
  TTestMaModel = class
  strict private
    function ParseText(const AText: string): TMaModel;
  public
    [Test]
    procedure DovrebbeSaltareUnNodoNonConosciuto;
    [Test]
    procedure DovrebbeIgnorareLeNormaliUvsn;
    [Test]
    procedure DovrebbeTenereIlColoreSeUnVertexNonNeHa;
    [Test]
    procedure DovrebbeDareMaterialePredefinitoAgliOggettiSenzaMateriale;
    [Test]
    procedure DovrebbeSostituireUnNodoCreatoDueVolteSenzaLiberareIlVecchio;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiVertexNellaFaccia;
    [Test]
    procedure DovrebbeUsareIlRisolutoreDeiPercorsi;
    [Test]
    procedure DovrebbeFarCaricareIlFileDalLoader;
    [Test]
    procedure DovrebbeDareErroriDelLexerComeErroriDelModello;
    [Test]
    procedure DovrebbeCaricareUnModelloSenzaOggettiVuoto;
    [Test]
    procedure DovrebbeTrovareIlLoaderDallEstensione;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Ase.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Static.Ma.Parser,
  DelphiDoom.Models.Static.Ma.Converter,
  DelphiDoom.Tests.Models.Md5Golden;

function MaFile(const AName: string): AnsiString;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Models\ma\' + AName)));
  SetString(Result, PAnsiChar(@LBytes[0]), Length(LBytes));
end;

// what the stub of the harness does for OSPathToRelativePath: from "models/" on
function HarnessResolver: TStaticPathResolver;
begin
  Result :=
    function(const APath: AnsiString): AnsiString
    var
      LPosition: Integer;
    begin
      LPosition := Pos('models/', string(APath));
      if LPosition > 0 then
        Result := Copy(APath, LPosition, MaxInt)
      else
        Result := APath;
    end;
end;

function Quad(const ATail: string): string;
begin
  Result := 'createNode mesh -n "m1";' + #10 +
    'setAttr -s 3 ".vt[0:2]" 0 0 0 1 0 0 0 0 -1;' + #10 +
    'setAttr -s 3 ".ed[0:2]" 0 1 0 1 2 0 2 0 0;' + #10 + ATail + #10 +
    'setAttr -s 1 ".fc[0]" -type "polyFaces" f 3 0 1 2;' + #10;
end;

{ TTestMaParity }

procedure TTestMaParity.Setup;
begin
  FGolden := TGoldenLines.Create('ma\ma.golden.txt');
end;

procedure TTestMaParity.TearDown;
begin
  FGolden.Free;
end;

function TTestMaParity.Parse(const AFile: string): TMaModel;
var
  LParser: TMaParser;
begin
  LParser := TMaParser.Create(HarnessResolver());
  try
    Result := LParser.Parse(MaFile(AFile), AnsiString(AFile));
  finally
    LParser.Free;
  end;
end;

procedure TTestMaParity.CheckFloats(const AWhat: string; const AExpected, AActual: TArray<Single>);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), Length(AActual), AWhat + ': numero di valori');
  for LIndex := 0 to High(AExpected) do
    Assert.IsTrue(TMd5Golden.Close(AExpected[LIndex], AActual[LIndex]),
      Format('%s[%d]: atteso %s, letto %s', [AWhat, LIndex, TMd5Golden.Describe(AExpected[LIndex]),
        TMd5Golden.Describe(AActual[LIndex])]));
end;

procedure TTestMaParity.CheckParsed(const AFile: string);
var
  LModel: TMaModel;
  LObject: TMaObject;
  LIndex, LFace, LCorner: Integer;
  LKey: string;
  LTokens: TArray<string>;
  LActual: TArray<Single>;
  LInts: TArray<Integer>;
begin
  LModel := Parse(AFile);
  try
    LTokens := FGolden.Tokens(AFile + ' materials');
    Assert.AreEqual<Integer>(Length(LTokens), LModel.Materials.Count, 'materiali');
    for LIndex := 0 to High(LTokens) do
      Assert.AreEqual(LTokens[LIndex], string(LModel.Materials[LIndex]));
    Assert.AreEqual<Integer>(FGolden.Ints(AFile + ' objects')[0], LModel.Objects.Count, 'oggetti');
    for LIndex := 0 to LModel.Objects.Count - 1 do
    begin
      LObject := LModel.Objects[LIndex];
      LKey := Format('%s obj %d', [AFile, LIndex]);
      LTokens := FGolden.Tokens(LKey);
      Assert.AreEqual(LTokens[0], string(LObject.Name));
      Assert.AreEqual(LTokens[1], IntToStr(LObject.MaterialRef), LKey + ' materialRef');
      if Length(LTokens) > 2 then
        Assert.AreEqual(LTokens[2], string(LObject.MaterialName))
      else
        Assert.AreEqual('', string(LObject.MaterialName));
      SetLength(LActual, Length(LObject.Mesh.Vertexes) * 3);
      for LFace := 0 to High(LObject.Mesh.Vertexes) do
      begin
        LActual[LFace * 3] := LObject.Mesh.Vertexes[LFace].X;
        LActual[LFace * 3 + 1] := LObject.Mesh.Vertexes[LFace].Y;
        LActual[LFace * 3 + 2] := LObject.Mesh.Vertexes[LFace].Z;
      end;
      CheckFloats(LKey + ' verts', FGolden.Floats(LKey + ' verts'), LActual);
      SetLength(LActual, Length(LObject.Mesh.TVertexes) * 2);
      for LFace := 0 to High(LObject.Mesh.TVertexes) do
      begin
        LActual[LFace * 2] := LObject.Mesh.TVertexes[LFace].X;
        LActual[LFace * 2 + 1] := LObject.Mesh.TVertexes[LFace].Y;
      end;
      CheckFloats(LKey + ' tverts', FGolden.Floats(LKey + ' tverts'), LActual);
      Assert.AreEqual<Integer>(FGolden.Ints(LKey + ' faces')[0], Length(LObject.Mesh.Faces), 'facce');
      for LFace := 0 to High(LObject.Mesh.Faces) do
      begin
        LInts := FGolden.Ints(Format('%s face %d', [LKey, LFace]));
        for LCorner := 0 to 2 do
        begin
          Assert.AreEqual<Integer>(LInts[LCorner], LObject.Mesh.Faces[LFace].VertexNum[LCorner], 'vertexNum');
          if Length(LObject.Mesh.TVertexes) > 0 then
            Assert.AreEqual<Integer>(LInts[3 + LCorner], LObject.Mesh.Faces[LFace].TVertexNum[LCorner], 'tVertexNum');
          Assert.AreEqual<Integer>(LInts[6 + LCorner], LObject.Mesh.Faces[LFace].VertexColors[LCorner], 'colore');
        end;
        if LObject.Mesh.NormalsParsed then
        begin
          SetLength(LActual, 9);
          for LCorner := 0 to 2 do
          begin
            LActual[LCorner * 3] := LObject.Mesh.Faces[LFace].VertexNormals[LCorner].X;
            LActual[LCorner * 3 + 1] := LObject.Mesh.Faces[LFace].VertexNormals[LCorner].Y;
            LActual[LCorner * 3 + 2] := LObject.Mesh.Faces[LFace].VertexNormals[LCorner].Z;
          end;
          CheckFloats(Format('%s face %d normals', [LKey, LFace]), FGolden.Floats(Format('%s face %d', [LKey, LFace])), LActual);
        end;
      end;
      LInts := FGolden.Ints(LKey + ' colors');
      Assert.AreEqual<Integer>(Length(LInts), Length(LObject.Mesh.Colors), 'byte dei colori');
      for LFace := 0 to High(LInts) do
        Assert.AreEqual<Integer>(LInts[LFace], LObject.Mesh.Colors[LFace], 'colore');
      Assert.AreEqual<Integer>(FGolden.Ints(LKey + ' normals')[0], Ord(LObject.Mesh.NormalsParsed), 'normali');
    end;
  finally
    LModel.Free;
  end;
end;

procedure TTestMaParity.CheckConverted(const AFile, ATag: string; const AOptions: TStaticLoadOptions);
var
  LModel: TMaModel;
  LConverter: TMaConverter;
  LResult: IStaticModel;
  LSurface: Integer;
  LKey: string;
  LTokens: TArray<string>;
  LTriangles: TStaticTriangles;
  LIndex: Integer;
  LActual: TArray<Single>;
  LColors: TArray<Int64>;
begin
  LModel := Parse(AFile);
  try
    LConverter := TMaConverter.Create(AOptions);
    try
      LResult := LConverter.Convert(LModel, AFile);
    finally
      LConverter.Free;
    end;
  finally
    LModel.Free;
  end;
  Assert.AreEqual<Integer>(FGolden.Ints(Format('%s %s surfaces', [AFile, ATag]))[0], LResult.NumSurfaces, 'superfici');
  for LSurface := 0 to LResult.NumSurfaces - 1 do
  begin
    LKey := Format('%s %s s%d', [AFile, ATag, LSurface]);
    LTokens := FGolden.Tokens(LKey);
    LTriangles := LResult.Surfaces[LSurface].Triangles;
    Assert.AreEqual(LTokens[0], string(LResult.Surfaces[LSurface].MaterialName), LKey + ' materiale');
    Assert.AreEqual(LTokens[1], IntToStr(LResult.Surfaces[LSurface].Id), LKey + ' id');
    Assert.AreEqual(LTokens[2], IntToStr(LTriangles.NumVerts), LKey + ' vertexes');
    Assert.AreEqual(LTokens[3], IntToStr(LTriangles.NumIndexes), LKey + ' indexes');
    Assert.AreEqual<Integer>(FGolden.Ints(LKey + ' generate')[0], Ord(LTriangles.GenerateNormals), LKey + ' generateNormals');
    for LIndex := 0 to LTriangles.NumIndexes - 1 do
      Assert.AreEqual<Integer>(FGolden.Ints(LKey + ' indexes')[LIndex], LTriangles.Indexes[LIndex], LKey + ' indice');
    SetLength(LActual, LTriangles.NumVerts * 8);
    for LIndex := 0 to LTriangles.NumVerts - 1 do
    begin
      LActual[LIndex * 8] := LTriangles.Verts[LIndex].Xyz.X;
      LActual[LIndex * 8 + 1] := LTriangles.Verts[LIndex].Xyz.Y;
      LActual[LIndex * 8 + 2] := LTriangles.Verts[LIndex].Xyz.Z;
      LActual[LIndex * 8 + 3] := LTriangles.Verts[LIndex].St.X;
      LActual[LIndex * 8 + 4] := LTriangles.Verts[LIndex].St.Y;
      LActual[LIndex * 8 + 5] := LTriangles.Verts[LIndex].Normal.X;
      LActual[LIndex * 8 + 6] := LTriangles.Verts[LIndex].Normal.Y;
      LActual[LIndex * 8 + 7] := LTriangles.Verts[LIndex].Normal.Z;
    end;
    CheckFloats(LKey + ' verts', FGolden.Floats(LKey + ' verts'), LActual);
    // the colours are the decimal tokens of the line, one per vertex
    LColors := FGolden.Int64s(LKey + ' verts');
    Assert.AreEqual<Integer>(LTriangles.NumVerts, Length(LColors), LKey + ' colori');
    for LIndex := 0 to High(LColors) do
      Assert.AreEqual<Cardinal>(Cardinal(LColors[LIndex]), LTriangles.Verts[LIndex].Color.ToCardinal, LKey + ' colore');
  end;
end;

procedure TTestMaParity.DovrebbeLeggereLeStesseRisposteDelCpp(const AFile: string);
begin
  CheckParsed(AFile);
end;

procedure TTestMaParity.DovrebbeConvertireComeIlCpp(const AFile: string);
var
  LOptions: TStaticLoadOptions;
begin
  LOptions := TStaticLoadOptions.Default;
  CheckConverted(AFile, 'merge', LOptions);
  LOptions.MergeSurfaces := False;
  CheckConverted(AFile, 'nomerge', LOptions);
  LOptions := TStaticLoadOptions.Default;
  LOptions.FastLoad := True;
  CheckConverted(AFile, 'fast', LOptions);
end;

procedure TTestMaParity.DovrebbeDareLoStessoErroreDelCpp(const AFile: string);
var
  LExpected: string;
  LTokens: TArray<string>;
begin
  LTokens := FGolden.Tokens(AFile + ' error');
  LExpected := string.Join(' ', LTokens);
  try
    Parse(AFile).Free;
    Assert.Fail('doveva fallire');
  except
    on E: EStaticModelException do
      Assert.AreEqual(LExpected, E.Message);
  end;
end;


{ TTestMaModel }

function TTestMaModel.ParseText(const AText: string): TMaModel;
var
  LParser: TMaParser;
begin
  LParser := TMaParser.Create;
  try
    Result := LParser.Parse(AnsiString(AText), 'inline.ma');
  finally
    LParser.Free;
  end;
end;

procedure TTestMaModel.DovrebbeSaltareUnNodoNonConosciuto;
var
  LModel: TMaModel;
begin
  LModel := ParseText('createNode camera -n "c";' + #10 + 'setAttr ".t" 1;' + #10 + Quad(''));
  try
    Assert.AreEqual<Integer>(1, LModel.Objects.Count);
    Assert.AreEqual('m1', string(LModel.Objects[0].Name));
  finally
    LModel.Free;
  end;
end;

procedure TTestMaModel.DovrebbeIgnorareLeNormaliUvsn;
var
  LModel: TMaModel;
begin
  LModel := ParseText(Quad('setAttr ".uvst[0].uvsn" -type "string" "map1";' + #10 +
    'setAttr -s 3 ".uvst[0].uvsp[0:2]" -type "float2" 0 0 1 0 0 0.25;'));
  try
    Assert.AreEqual<Integer>(3, Length(LModel.Objects[0].Mesh.TVertexes));
    Assert.AreEqual(0.75, LModel.Objects[0].Mesh.TVertexes[2].Y, 0.0);
  finally
    LModel.Free;
  end;
end;

procedure TTestMaModel.DovrebbeTenereIlColoreSeUnVertexNonNeHa;
var
  LModel: TMaModel;
  LConverter: TMaConverter;
  LResult: IStaticModel;
begin
  LModel := ParseText('createNode mesh -n "m1";' + #10 +
    'setAttr -s 3 ".vt[0:2]" 0 0 0 1 0 0 0 0 -1;' + #10 +
    'setAttr -s 3 ".ed[0:2]" 0 1 0 1 2 0 2 0 0;' + #10 +
    'setAttr -s 1 ".clr[0]" 1 0 0 1;' + #10 +
    'setAttr -s 1 ".fc[0]" -type "polyFaces" f 3 0 1 2 fc 3 0 -1 -999;');
  try
    LConverter := TMaConverter.Create(TStaticLoadOptions.Default);
    try
      LResult := LConverter.Convert(LModel, 'inline.ma');
    finally
      LConverter.Free;
    end;
  finally
    LModel.Free;
  end;
  Assert.AreEqual<Integer>(3, LResult.Surfaces[0].Triangles.NumVerts);
  Assert.AreEqual<Integer>(255, LResult.Surfaces[0].Triangles.Verts[0].Color.R);
  Assert.AreEqual<Integer>(255, LResult.Surfaces[0].Triangles.Verts[1].Color.R, 'resta l''ultimo colore');
  Assert.AreEqual<Integer>(0, LResult.Surfaces[0].Triangles.Verts[2].Color.G);
  Assert.AreEqual<Integer>(255, LResult.Surfaces[0].Triangles.Verts[2].Color.A);
end;

procedure TTestMaModel.DovrebbeDareMaterialePredefinitoAgliOggettiSenzaMateriale;
var
  LModel: TMaModel;
  LConverter: TMaConverter;
  LResult: IStaticModel;
begin
  LModel := ParseText(Quad('') +
    'createNode mesh -n "m2";' + #10 +
    'setAttr -s 3 ".vt[0:2]" 0 0 0 1 0 0 0 0 -1;' + #10 +
    'setAttr -s 3 ".ed[0:2]" 0 1 0 1 2 0 2 0 0;' + #10 +
    'setAttr -s 1 ".fc[0]" -type "polyFaces" f 3 0 1 2;' + #10 +
    'createNode shadingEngine -n "sg";' + #10 +
    'createNode file -n "f1";' + #10 +
    'setAttr ".ftn" -type "string" "tex/a.tga";' + #10 +
    'connectAttr "f1.oc" "sg.ss";' + #10 +
    'connectAttr "m1.iog" "sg.dsm";');
  try
    LConverter := TMaConverter.Create(TStaticLoadOptions.Default);
    try
      LResult := LConverter.Convert(LModel, 'inline.ma');
    finally
      LConverter.Free;
    end;
  finally
    LModel.Free;
  end;
  Assert.AreEqual<Integer>(2, LResult.NumSurfaces);
  Assert.AreEqual('tex/a.tga', string(LResult.Surfaces[0].MaterialName));
  Assert.AreEqual('_default', string(LResult.Surfaces[1].MaterialName));
end;

procedure TTestMaModel.DovrebbeSostituireUnNodoCreatoDueVolteSenzaLiberareIlVecchio;
var
  LModel: TMaModel;
begin
  LModel := ParseText('createNode transform -n "t";' + #10 + 'setAttr ".t" -type "double3" 1 0 0;' + #10 +
    'createNode mesh -n "m1" -p "t";' + #10 +
    'setAttr -s 3 ".vt[0:2]" 0 0 0 1 0 0 0 0 -1;' + #10 +
    'createNode transform -n "t";' + #10 + 'setAttr ".t" -type "double3" 5 0 0;');
  try
    Assert.AreEqual(5.0, LModel.Transforms['t'].Translate.X, 0.0, 'vale l''ultimo');
    Assert.AreEqual(1.0, LModel.Objects[0].Mesh.Vertexes[0].X, 0.0001, 'la mesh ha usato il primo');
  finally
    LModel.Free;
  end;
end;

procedure TTestMaModel.DovrebbeRifiutareUnIndiceFuoriIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      ParseText('createNode mesh -n "m1";' + #10 + 'setAttr -s 3 ".vt[0:5]" 0 0 0 1 0 0 0 0 -1 0 0 0 0 0 0 0 0 0;').Free;
    end, EStaticModelException);
end;

procedure TTestMaModel.DovrebbeRifiutareUnIndiceDiVertexNellaFaccia;
begin
  Assert.WillRaise(
    procedure
    begin
      ParseText('createNode mesh -n "m1";' + #10 + 'setAttr -s 3 ".vt[0:2]" 0 0 0 1 0 0 0 0 -1;' + #10 +
        'setAttr -s 3 ".ed[0:2]" 0 1 0 1 2 0 2 0 0;' + #10 +
        'setAttr -s 1 ".fc[0]" -type "polyFaces" f 3 0 1 9;').Free;
    end, EStaticModelException);
end;

procedure TTestMaModel.DovrebbeUsareIlRisolutoreDeiPercorsi;
var
  LParser: TMaParser;
  LModel: TMaModel;
begin
  LParser := TMaParser.Create(
    function(const APath: AnsiString): AnsiString
    begin
      Result := 'resolved:' + APath;
    end);
  try
    LModel := LParser.Parse('createNode mesh -n "m1";' + #10 + 'createNode shadingEngine -n "sg";' + #10 +
      'createNode file -n "f1";' + #10 + 'setAttr ".ftn" -type "string" "tex/a.tga";' + #10 +
      'connectAttr "f1.oc" "sg.ss";' + #10 + 'connectAttr "m1.iog" "sg.dsm";', 'inline.ma');
  finally
    LParser.Free;
  end;
  try
    Assert.AreEqual('resolved:tex/a.tga', string(LModel.Materials[0]));
  finally
    LModel.Free;
  end;
end;

procedure TTestMaModel.DovrebbeFarCaricareIlFileDalLoader;
var
  LModel: IStaticModel;
  LData: AnsiString;
  LBytes: TBytes;
begin
  LData := MaFile('quad.ma');
  SetLength(LBytes, Length(LData));
  Move(LData[1], LBytes[0], Length(LData));
  LModel := TStaticModelFactory.CreateMaLoader(TStaticLoadOptions.Default, HarnessResolver()).Load(LBytes, 'quad.ma');
  Assert.AreEqual('quad.ma', LModel.Name);
  Assert.AreEqual<Integer>(1, LModel.NumSurfaces);
  Assert.AreEqual('models/tex/brick.tga', string(LModel.Surfaces[0].MaterialName));
  Assert.AreEqual<Integer>(6, LModel.TotalIndexes);
  Assert.IsTrue(LModel.Bounds.Maxs.X > LModel.Bounds.Mins.X);
end;

procedure TTestMaModel.DovrebbeDareErroriDelLexerComeErroriDelModello;
begin
  Assert.WillRaise(
    procedure
    begin
      TStaticModelFactory.CreateMaLoader.Load(TEncoding.ASCII.GetBytes('createNode mesh -n "oops' + #10 + ';'), 'bad.ma');
    end, EStaticModelException);
  Assert.WillRaise(
    procedure
    begin
      TStaticModelFactory.CreateMaLoader.Load(TEncoding.ASCII.GetBytes('connectAttr "a" "b.c";'), 'bad.ma');
    end, EStaticModelException);
end;

procedure TTestMaModel.DovrebbeCaricareUnModelloSenzaOggettiVuoto;
var
  LModel: IStaticModel;
begin
  LModel := TStaticModelFactory.CreateMaLoader.Load(TEncoding.ASCII.GetBytes('//nothing' + #10 + 'requires maya "4.0";'), 'empty.ma');
  Assert.AreEqual<Integer>(0, LModel.NumSurfaces);
  LModel := TStaticModelFactory.CreateMaLoader.Load(nil, 'nothing.ma');
  Assert.AreEqual<Integer>(0, LModel.NumSurfaces);
end;

procedure TTestMaModel.DovrebbeTrovareIlLoaderDallEstensione;
begin
  Assert.IsNotNull(TStaticModelFactory.CreateLoaderFor('models/x.MA', TStaticLoadOptions.Default));
  Assert.IsNull(TStaticModelFactory.CreateLoaderFor('models/x.mb', TStaticLoadOptions.Default));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMaParity);
  TDUnitX.RegisterTestFixture(TTestMaModel);

end.