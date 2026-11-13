{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library - the globe (polygons,    }
{  lines, textures and RuleGlobe)                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.Globe;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Areas, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.Polygon, DelphiDoom.XcomMod.Polyline, DelphiDoom.XcomMod.Texture,
  DelphiDoom.XcomMod.RuleGlobe, DelphiDoom.Tests.XcomMod.Ruleset;

type
  /// <summary>A generator that always gives the same number (clamped to the range)</summary>
  TXcomFixedRandom = class(TInterfacedObject, IXcomRandom)
  strict private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    function Generate(AMin, AMax: Integer): Integer; overload;
    function Generate(AMin, AMax: Double): Double; overload;
    function Seed: UInt64;
    procedure SetSeed(AValue: UInt64);
  end;

  [TestFixture]
  [Category('xcom-mod')]
  [Category('xcom-mod-globe')]
  TTestXcomGlobe = class(TObject)
  strict private
    function Parse(const AText: string): IYamlNode;
    function Dat(const AValues: array of SmallInt): TBytes;
  public
    [Test]
    procedure DovrebbeCaricareUnPoligonoInRadianti;
    [Test]
    procedure DovrebbeSollevareErroreSeIlPoligonoNonHaCoordinateAppaiate;
    [Test]
    procedure DovrebbeCopiareUnPoligono;
    [Test]
    procedure DovrebbeSollevareErroreSeIlPuntoDelPoligonoNonEsiste;
    [Test]
    procedure DovrebbeCaricareUnaLineaInRadianti;
    [Test]
    procedure DovrebbeSollevareErroreSeLaLineaHaUnNumeroDispari;
    [Test]
    procedure DovrebbeLeggereLeDefinizioniDiUnaTexture;
    [Test]
    procedure DovrebbeSollevareErroreSeLAreaDelTerrenoHaMenoDiQuattroNumeri;
    [Test]
    procedure DovrebbeSollevareErroreSeUnTerrenoNonEUnaMappa;
    [Test]
    procedure DovrebbeScegliereIlTerrenoPerPesoEPosizione;
    [Test]
    procedure DovrebbeNonDareTerrenoFuoriDallArea;
    [Test]
    procedure DovrebbeScegliereLoSchieramentoPerPeso;
    [Test]
    procedure DovrebbeDareLoSchieramentoUnicoSenzaGenerare;
    [Test]
    procedure DovrebbeLeggereWorldDatConTreEQuattroPunti;
    [Test]
    procedure DovrebbeIgnorareUnaCodaPiuCortaDiUnRecord;
    [Test]
    procedure DovrebbeSollevareErroreSeMancaIlFileDiWorldDat;
    [Test]
    procedure DovrebbeSostituireIPoligoniECaricareLeTexture;
    [Test]
    procedure DovrebbeCancellareUnaTextureEAggiornarla;
    [Test]
    procedure DovrebbeTroncareIColoriAUnByte;
    [Test]
    procedure DovrebbeUsareIColoriPredefiniti;
    [Test]
    procedure DovrebbeDareITerreniPerSchieramento;
    [Test]
    procedure DovrebbeCaricareIlGloboDalFileDellaRuleset;
  end;

implementation

{ TXcomFixedRandom }

constructor TXcomFixedRandom.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TXcomFixedRandom.Generate(AMin, AMax: Integer): Integer;
begin
  Result := FValue;
  if Result < AMin then
    Result := AMin;
  if Result > AMax then
    Result := AMax;
end;

function TXcomFixedRandom.Generate(AMin, AMax: Double): Double;
begin
  Result := AMin;
end;

function TXcomFixedRandom.Seed: UInt64;
begin
  Result := 1;
end;

procedure TXcomFixedRandom.SetSeed(AValue: UInt64);
begin
end;

{ TTestXcomGlobe }

function TTestXcomGlobe.Parse(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText));
end;

function TTestXcomGlobe.Dat(const AValues: array of SmallInt): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues) * 2);
  for LIndex := 0 to High(AValues) do
  begin
    Result[LIndex * 2] := Byte(AValues[LIndex] and $FF);
    Result[LIndex * 2 + 1] := Byte((AValues[LIndex] shr 8) and $FF);
  end;
end;

procedure TTestXcomGlobe.DovrebbeCaricareUnPoligonoInRadianti;
var
  LPolygon: TXcomPolygon;
begin
  LPolygon := TXcomPolygon.Create(1);
  try
    LPolygon.Load(Parse('[7, 180, 90, 0, -90]'));
    Assert.AreEqual(2, LPolygon.Points);
    Assert.AreEqual(7, LPolygon.Texture);
    Assert.AreEqual(Double(3.14159265358979323846), LPolygon.GetLongitude(0), 1E-15);
    Assert.AreEqual(Double(3.14159265358979323846 / 2), LPolygon.GetLatitude(0), 1E-15);
    Assert.AreEqual(Double(0), LPolygon.GetLongitude(1), 0.0);
    Assert.AreEqual(0, Integer(LPolygon.GetX(1)));
  finally
    LPolygon.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSollevareErroreSeIlPoligonoNonHaCoordinateAppaiate;
var
  LPolygon: TXcomPolygon;
begin
  LPolygon := TXcomPolygon.Create(3);
  try
    Assert.WillRaise(procedure begin LPolygon.Load(Parse('[]')); end, EXcomModException);
    Assert.WillRaise(procedure begin LPolygon.Load(Parse('[1, 2, 3, 4]')); end, EXcomModException);
    Assert.WillRaise(procedure begin LPolygon.Load(Parse('{a: 1}')); end, EYamlBadConversion);
  finally
    LPolygon.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeCopiareUnPoligono;
var
  LPolygon, LCopy: TXcomPolygon;
begin
  LPolygon := TXcomPolygon.Create(2);
  try
    LPolygon.SetLatitude(1, 0.5);
    LPolygon.SetX(0, -4);
    LPolygon.Texture := 9;
    LCopy := TXcomPolygon.CreateCopy(LPolygon);
    try
      LPolygon.SetLatitude(1, 0.75);
      Assert.AreEqual(Double(0.5), LCopy.GetLatitude(1), 0.0);
      Assert.AreEqual(-4, Integer(LCopy.GetX(0)));
      Assert.AreEqual(9, LCopy.Texture);
    finally
      LCopy.Free;
    end;
  finally
    LPolygon.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSollevareErroreSeIlPuntoDelPoligonoNonEsiste;
var
  LPolygon: TXcomPolygon;
begin
  LPolygon := TXcomPolygon.Create(2);
  try
    Assert.WillRaise(procedure begin LPolygon.GetX(2); end, EXcomModException);
    Assert.WillRaise(procedure begin LPolygon.SetY(-1, 0); end, EXcomModException);
  finally
    LPolygon.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeCaricareUnaLineaInRadianti;
var
  LLine: TXcomPolyline;
begin
  LLine := TXcomPolyline.Create(3);
  try
    LLine.Load(Parse('[180, 90, 0, 0]'));
    Assert.AreEqual(2, LLine.Points);
    Assert.AreEqual(Double(3.14159265358979323846), LLine.GetLongitude(0), 1E-15);
    Assert.AreEqual(Double(0), LLine.GetLatitude(1), 0.0);
    LLine.Load(Parse('[]'));
    Assert.AreEqual(0, LLine.Points);
  finally
    LLine.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSollevareErroreSeLaLineaHaUnNumeroDispari;
var
  LLine: TXcomPolyline;
begin
  LLine := TXcomPolyline.Create(3);
  try
    Assert.WillRaise(procedure begin LLine.Load(Parse('[1, 2, 3]')); end, EXcomModException);
    Assert.WillRaise(procedure begin LLine.GetLatitude(7); end, EXcomModException);
  finally
    LLine.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeLeggereLeDefinizioniDiUnaTexture;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(5);
  try
    LTexture.Load(Parse('{deployments: {B: 20, A: 10}, terrain: [{name: T1, area: [0, 90, -45, 45]}, {name: T2, weight: 3}]}'));
    Assert.AreEqual(5, LTexture.Id);
    Assert.AreEqual(2, LTexture.Deployments.Count);
    Assert.AreEqual('A', LTexture.Deployments.Key(0));
    Assert.AreEqual<Integer>(2, Length(LTexture.Terrain));
    Assert.AreEqual('T1', LTexture.Terrain[0].Name);
    Assert.AreEqual(1, LTexture.Terrain[0].Weight);
    Assert.AreEqual(Double(3.14159265358979323846 / 2), LTexture.Terrain[0].LonMax, 1E-15);
    // the default criteria are in degrees, as the C++ writes them
    Assert.AreEqual(Double(360), LTexture.Terrain[1].LonMax, 0.0);
    Assert.AreEqual(Double(-90), LTexture.Terrain[1].LatMin, 0.0);
    // a field that is not there keeps the values
    LTexture.Load(Parse('{id: 8}'));
    Assert.AreEqual(8, LTexture.Id);
    Assert.AreEqual(2, LTexture.Deployments.Count);
    Assert.AreEqual<Integer>(2, Length(LTexture.Terrain));
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSollevareErroreSeLAreaDelTerrenoHaMenoDiQuattroNumeri;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(1);
  try
    Assert.WillRaise(procedure begin LTexture.Load(Parse('{terrain: [{name: T, area: [1, 2]}]}')); end,
      EXcomModException);
    Assert.WillRaise(procedure begin LTexture.Load(Parse('{terrain: [{name: T, area: x}]}')); end,
      EYamlBadConversion);
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSollevareErroreSeUnTerrenoNonEUnaMappa;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(1);
  try
    Assert.WillRaise(procedure begin LTexture.Load(Parse('{terrain: [a]}')); end, EYamlBadConversion);
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeScegliereIlTerrenoPerPesoEPosizione;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(1);
  try
    LTexture.Load(Parse('{terrain: [{name: A, weight: 2, area: [0, 90, -10, 10]}, {name: B, weight: 3, area: [0, 90, -10, 10]}, ' +
      '{name: C, weight: 0}, {name: D, weight: 5, area: [100, 120, -10, 10]}]}'));
    Assert.AreEqual('A', LTexture.GetRandomTerrain(0.1, 0.0, TXcomFixedRandom.Create(2)));
    Assert.AreEqual('B', LTexture.GetRandomTerrain(0.1, 0.0, TXcomFixedRandom.Create(3)));
    Assert.AreEqual('B', LTexture.GetRandomTerrain(0.1, 0.0, TXcomFixedRandom.Create(5)));
    // the longitude upper limit is excluded
    Assert.AreEqual('', LTexture.GetRandomTerrain(XcomDegToRad(90), 0.0, TXcomFixedRandom.Create(1)));
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeNonDareTerrenoFuoriDallArea;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(1);
  try
    LTexture.Load(Parse('{terrain: [{name: A, area: [0, 10, 0, 10]}]}'));
    Assert.AreEqual('', LTexture.GetRandomTerrain(2.0, 0.0, TXcomFixedRandom.Create(1)));
  finally
    LTexture.Free;
  end;
  // a texture without terrains
  LTexture := TXcomTexture.Create(2);
  try
    Assert.AreEqual('', LTexture.GetRandomTerrain(0, 0, TXcomFixedRandom.Create(1)));
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeScegliereLoSchieramentoPerPeso;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(1);
  try
    LTexture.Load(Parse('{deployments: {A: 1, B: 4, C: 5}}'));
    Assert.AreEqual('A', LTexture.GetRandomDeployment(TXcomFixedRandom.Create(1)));
    Assert.AreEqual('B', LTexture.GetRandomDeployment(TXcomFixedRandom.Create(2)));
    Assert.AreEqual('B', LTexture.GetRandomDeployment(TXcomFixedRandom.Create(5)));
    Assert.AreEqual('C', LTexture.GetRandomDeployment(TXcomFixedRandom.Create(6)));
    LTexture.Load(Parse('{deployments: {A: 0, B: -3}}'));
    Assert.AreEqual('', LTexture.GetRandomDeployment(TXcomFixedRandom.Create(1)));
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeDareLoSchieramentoUnicoSenzaGenerare;
var
  LTexture: TXcomTexture;
begin
  LTexture := TXcomTexture.Create(1);
  try
    Assert.AreEqual('', LTexture.GetRandomDeployment(nil));
    LTexture.Load(Parse('{deployments: {Only: 0}}'));
    Assert.AreEqual('Only', LTexture.GetRandomDeployment(nil));
  finally
    LTexture.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeLeggereWorldDatConTreEQuattroPunti;
var
  LFiles: TXcomMemoryFiles;
  LRef: IInterface;
  LGlobe: TXcomRuleGlobe;
begin
  LFiles := TXcomMemoryFiles.Create;
  LRef := LFiles;
  // a quad (the fourth point is in value[6], value[7]) and a triangle (value[6] = -1), texture in value[8]
  LFiles.AddBytes('GEODATA/WORLD.DAT',
    Dat([8, 16, 24, 32, 40, 48, 56, 64, 3, 0, 8, 16, 24, 32, 40, 48, -1, -1, 5, 0]));
  LGlobe := TXcomRuleGlobe.Create(LFiles);
  try
    LGlobe.Load(Parse('{data: GEODATA/WORLD.DAT}'));
    Assert.AreEqual(2, LGlobe.Polygons.Count);
    Assert.AreEqual(4, LGlobe.Polygons[0].Points);
    Assert.AreEqual(3, LGlobe.Polygons[0].Texture);
    Assert.AreEqual(3, LGlobe.Polygons[1].Points);
    Assert.AreEqual(5, LGlobe.Polygons[1].Texture);
    Assert.AreEqual(TXcomRuleGlobe.XcomToRadians(56), LGlobe.Polygons[0].GetLongitude(3), 0.0);
    Assert.AreEqual(TXcomRuleGlobe.XcomToRadians(64), LGlobe.Polygons[0].GetLatitude(3), 0.0);
    // 8 eighths of a degree is one degree
    Assert.AreEqual(Double(3.14159265358979323846 / 180), LGlobe.Polygons[0].GetLongitude(0), 1E-15);
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeIgnorareUnaCodaPiuCortaDiUnRecord;
var
  LFiles: TXcomMemoryFiles;
  LRef: IInterface;
  LGlobe: TXcomRuleGlobe;
begin
  LFiles := TXcomMemoryFiles.Create;
  LRef := LFiles;
  LFiles.AddBytes('W.DAT', Dat([0, 0, 0, 0, 0, 0, -1, -1, 1, 0, 9, 9, 9]));
  LGlobe := TXcomRuleGlobe.Create(LFiles);
  try
    LGlobe.Load(Parse('{data: W.DAT}'));
    Assert.AreEqual(1, LGlobe.Polygons.Count);
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSollevareErroreSeMancaIlFileDiWorldDat;
var
  LGlobe: TXcomRuleGlobe;
  LFiles: TXcomMemoryFiles;
  LRef: IInterface;
begin
  LGlobe := TXcomRuleGlobe.Create(nil);
  try
    Assert.WillRaise(procedure begin LGlobe.Load(Parse('{data: W.DAT}')); end, EXcomModException);
  finally
    LGlobe.Free;
  end;
  LFiles := TXcomMemoryFiles.Create;
  LRef := LFiles;
  LGlobe := TXcomRuleGlobe.Create(LFiles);
  try
    Assert.WillRaise(procedure begin LGlobe.Load(Parse('{data: W.DAT}')); end, EXcomModException);
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeSostituireIPoligoniECaricareLeTexture;
var
  LGlobe: TXcomRuleGlobe;
begin
  LGlobe := TXcomRuleGlobe.Create;
  try
    LGlobe.Load(Parse('{polygons: [[1, 0, 0, 10, 0, 10, 10], [2, 0, 0, 1, 1, 2, 2]], polylines: [[0, 0, 5, 5]], ' +
      'textures: [{id: 3, deployments: {A: 1}}, {id: 1}]}'));
    Assert.AreEqual(2, LGlobe.Polygons.Count);
    Assert.AreEqual(3, LGlobe.Polygons[0].Points);
    Assert.AreEqual(1, LGlobe.Polylines.Count);
    Assert.AreEqual(1, LGlobe.TextureIds[0]);
    Assert.AreEqual(3, LGlobe.TextureIds[1]);
    Assert.IsNotNull(LGlobe.GetTexture(3));
    Assert.IsNull(LGlobe.GetTexture(2));
    LGlobe.Load(Parse('{polygons: [[4, 0, 0, 1, 1, 2, 2]]}'));
    Assert.AreEqual(1, LGlobe.Polygons.Count);
    Assert.AreEqual(1, LGlobe.Polylines.Count);
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeCancellareUnaTextureEAggiornarla;
var
  LGlobe: TXcomRuleGlobe;
begin
  LGlobe := TXcomRuleGlobe.Create;
  try
    LGlobe.Load(Parse('{textures: [{id: 3, deployments: {A: 1}}, {id: 4}]}'));
    LGlobe.Load(Parse('{textures: [{id: 3, deployments: {B: 2}}, {delete: 4}, {delete: 99}, {other: 1}]}'));
    Assert.AreEqual<Integer>(1, Length(LGlobe.TextureIds));
    Assert.IsTrue(LGlobe.GetTexture(3).Deployments.ContainsKey('B'));
    Assert.IsFalse(LGlobe.GetTexture(3).Deployments.ContainsKey('A'));
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeTroncareIColoriAUnByte;
var
  LGlobe: TXcomRuleGlobe;
begin
  LGlobe := TXcomRuleGlobe.Create;
  try
    LGlobe.Load(Parse('{countryColor: 300, cityColor: 7, baseColor: -1, lineColor: 256, oceanPalette: 1, oceanShading: false}'));
    Assert.AreEqual(44, Integer(LGlobe.CountryLabelColor));
    Assert.AreEqual(7, Integer(LGlobe.CityLabelColor));
    Assert.AreEqual(255, Integer(LGlobe.BaseLabelColor));
    Assert.AreEqual(0, Integer(LGlobe.LineColor));
    Assert.AreEqual(16, Integer(LGlobe.OceanColor));
    Assert.IsFalse(LGlobe.OceanShading);
    LGlobe.Load(Parse('{oceanPalette: 20}'));
    Assert.AreEqual(64, Integer(LGlobe.OceanColor));
    // a bad value gives the current color as the block (64 * 16 = 1024 -> 0)
    LGlobe.Load(Parse('{oceanPalette: x}'));
    Assert.AreEqual(0, Integer(LGlobe.OceanColor));
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeUsareIColoriPredefiniti;
var
  LGlobe: TXcomRuleGlobe;
begin
  LGlobe := TXcomRuleGlobe.Create;
  try
    Assert.AreEqual(239, Integer(LGlobe.CountryLabelColor));
    Assert.AreEqual(138, Integer(LGlobe.CityLabelColor));
    Assert.AreEqual(133, Integer(LGlobe.BaseLabelColor));
    Assert.AreEqual(162, Integer(LGlobe.LineColor));
    Assert.AreEqual(192, Integer(LGlobe.OceanColor));
    Assert.IsTrue(LGlobe.OceanShading);
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeDareITerreniPerSchieramento;
var
  LGlobe: TXcomRuleGlobe;
  LNames: TArray<string>;
begin
  LGlobe := TXcomRuleGlobe.Create;
  try
    LGlobe.Load(Parse('{textures: [{id: 1, terrain: [{name: X}, {name: Y}]}, {id: 2, deployments: {D: 1}, ' +
      'terrain: [{name: Z}]}, {id: 3, deployments: {D: 1, E: 1}, terrain: [{name: W}]}]}'));
    LNames := LGlobe.GetTerrains('');
    Assert.AreEqual('X,Y', string.Join(',', LNames));
    Assert.AreEqual('Z,W', string.Join(',', LGlobe.GetTerrains('D')));
    Assert.AreEqual('W', string.Join(',', LGlobe.GetTerrains('E')));
    Assert.AreEqual<Integer>(0, Length(LGlobe.GetTerrains('none')));
  finally
    LGlobe.Free;
  end;
end;

procedure TTestXcomGlobe.DovrebbeCaricareIlGloboDalFileDellaRuleset;
var
  LFiles: TXcomMemoryFiles;
  LRef: IInterface;
  LRuleset: TXcomRuleset;
begin
  LFiles := TXcomMemoryFiles.Create;
  LRef := LFiles;
  LFiles.AddBytes('G/W.DAT', Dat([0, 0, 0, 0, 0, 0, -1, -1, 1, 0]));
  LRuleset := TXcomRuleset.Create(TXcomFixedShared.Create, LFiles);
  try
    LRuleset.LoadFile(Parse('globe: {data: G/W.DAT, countryColor: 3}'));
    Assert.AreEqual(1, LRuleset.Globe.Polygons.Count);
    Assert.AreEqual(3, Integer(LRuleset.Globe.CountryLabelColor));
  finally
    LRuleset.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGlobe);

end.
