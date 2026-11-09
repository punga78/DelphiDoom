{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library - the parts of a tile     }
{  (MapData, MapDataSet, the MCD reader and the patches of the mods)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.MapData;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.MapDataLoader,
  DelphiDoom.XcomMod.McdPatch, DelphiDoom.Tests.XcomMod.Ruleset;

type
  [TestFixture]
  [Category('xcom-mod')]
  [Category('xcom-mod-mapdata')]
  TTestXcomMapData = class(TObject)
  strict private
    FFiles: TXcomMemoryFiles;
    FFilesRef: IInterface;
    FSet: TXcomMapDataSet;
    FLoader: TXcomMapDataLoader;
    /// <summary>A MCD record of 62 bytes with the numbers that the loader cares about, armor 10</summary>
    function Part(ADie, AAlt, AArmor: Byte): TBytes;
    procedure AddMcd(const AParts: array of TBytes);
    function Patch(const AText: string): TXcomMcdPatch;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereTuttiICampiDiUnRecordMcd;
    [Test]
    procedure DovrebbeLeggereLaQuotaDelTerrenoConSegno;
    [Test]
    procedure DovrebbeIgnorareUnaCodaPiuCortaDiUnRecord;
    [Test]
    procedure DovrebbeSollevareErroreSeMancaIlFileMcd;
    [Test]
    procedure DovrebbeCaricareUnaSolaVolta;
    [Test]
    procedure DovrebbeSegnalareLePartiNonValide;
    [Test]
    procedure DovrebbeSollevareErroreSeUnaParteNonHaCorazza;
    [Test]
    procedure DovrebbeSollevareErroreSeLOggettoNonEsiste;
    [Test]
    procedure DovrebbeApplicareLaPatchDeiMod;
    [Test]
    procedure DovrebbeApplicareLaPatchPrimaDelControllo;
    [Test]
    procedure DovrebbeSollevareErroreSePatchHaUnIndiceCheNonEsiste;
    [Test]
    procedure DovrebbeSollevareErroreSeLeLoftSuperanoIDodiciStrati;
    [Test]
    procedure DovrebbeTenereLaDefinizioneDelleDueTegoleVuote;
    [Test]
    procedure DovrebbeScaricareIDati;
    [Test]
    procedure DovrebbeDareIBloccoPerTipoDiDanno;
    [Test]
    procedure DovrebbeDareICostiDiMovimento;
    [Test]
    procedure DovrebbeDareLaLuceEmessa;
    [Test]
    procedure DovrebbeSollevareErroreSeLIndiceDelloStratoNonEsiste;
  end;

implementation

{ TTestXcomMapData }

procedure TTestXcomMapData.Setup;
begin
  FFiles := TXcomMemoryFiles.Create;
  FFilesRef := FFiles;
  FSet := TXcomMapDataSet.Create('TEST');
  FLoader := TXcomMapDataLoader.Create(FFiles);
end;

procedure TTestXcomMapData.TearDown;
begin
  FLoader.Free;
  FSet.Free;
  FFilesRef := nil;
end;

function TTestXcomMapData.Part(ADie, AAlt, AArmor: Byte): TBytes;
begin
  SetLength(Result, 62);
  FillChar(Result[0], 62, 0);
  Result[44] := ADie;
  Result[46] := AAlt;
  Result[42] := AArmor;
end;

procedure TTestXcomMapData.AddMcd(const AParts: array of TBytes);
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, 0);
  for LIndex := 0 to High(AParts) do
    LBytes := LBytes + AParts[LIndex];
  FFiles.AddBytes('TERRAIN/TEST.MCD', LBytes);
end;

function TTestXcomMapData.Patch(const AText: string): TXcomMcdPatch;
begin
  Result := TXcomMcdPatch.Create;
  Result.Load(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(AText)));
end;

procedure TTestXcomMapData.DovrebbeLeggereTuttiICampiDiUnRecordMcd;
var
  LRecord: TBytes;
  LData: TXcomMapData;
  LIndex: Integer;
begin
  LRecord := Part(0, 0, 7);
  for LIndex := 0 to 7 do
    LRecord[LIndex] := 10 + LIndex;
  for LIndex := 0 to 11 do
    LRecord[8 + LIndex] := 20 + LIndex;
  LRecord[20] := $34;
  LRecord[21] := $12;
  LRecord[30] := 1;   // UFO_Door
  LRecord[31] := 1;   // Stop_LOS
  LRecord[32] := 0;   // No_Floor
  LRecord[33] := 3;   // Big_Wall
  LRecord[34] := 1;   // Gravlift
  LRecord[35] := 0;   // Door
  LRecord[36] := 1;   // Block_Fire
  LRecord[37] := 1;   // Block_Smoke
  LRecord[39] := 4;   // TU_Walk
  LRecord[40] := 5;   // TU_Slide
  LRecord[41] := 6;   // TU_Fly
  LRecord[43] := 77;  // HE_Block
  LRecord[45] := 8;   // Flammable
  LRecord[49] := 9;   // P_Level
  LRecord[51] := 12;  // Light_Block
  LRecord[52] := 13;  // Footstep
  LRecord[53] := 2;   // Tile_Type
  LRecord[54] := 1;   // HE_Type
  LRecord[55] := 30;  // HE_Strength
  LRecord[57] := 14;  // Fuel
  LRecord[58] := 5;   // Light_Source
  LRecord[59] := 11;  // Target_Type
  LRecord[60] := 1;   // Xcom_Base
  AddMcd([LRecord]);
  FLoader.LoadData(FSet, nil);
  Assert.AreEqual(1, FSet.Size);
  LData := FSet.GetObject(0);
  Assert.AreEqual(13, LData.GetSprite(3));
  Assert.AreEqual(9, LData.YOffset);
  Assert.AreEqual(11, LData.SpecialType);
  Assert.AreEqual(2, LData.ObjectType);
  Assert.AreEqual(4, LData.TuWalk);
  Assert.AreEqual(6, LData.TuFly);
  Assert.AreEqual(5, LData.TuSlide);
  Assert.IsTrue(LData.IsUfoDoor);
  Assert.IsTrue(LData.StopLos);
  Assert.IsFalse(LData.IsNoFloor);
  Assert.IsTrue(LData.IsGravLift);
  Assert.IsFalse(LData.IsDoor);
  Assert.IsTrue(LData.BlockFire);
  Assert.IsTrue(LData.BlockSmoke);
  Assert.IsTrue(LData.IsBaseModule);
  Assert.AreEqual(3, LData.BigWall);
  Assert.AreEqual(13, LData.FootstepSound);
  Assert.AreEqual(7, LData.Armor);
  Assert.AreEqual(8, LData.Flammable);
  Assert.AreEqual(14, LData.Fuel);
  Assert.AreEqual(1, LData.ExplosiveType);
  Assert.AreEqual(30, LData.Explosive);
  Assert.AreEqual(5, LData.LightSource);
  Assert.AreEqual(4, LData.GetLightSource);
  Assert.AreEqual($1234, Integer(LData.MiniMapIndex));
  Assert.AreEqual(25, LData.GetLoftId(5));
  // block: light, vision (stop LOS 1 -> 255), HE, smoke (1 -> 256), fire (flammable), gas (HE)
  Assert.AreEqual(12, LData.BlockValue(0));
  Assert.AreEqual(255, LData.BlockValue(1));
  Assert.AreEqual(77, LData.BlockValue(2));
  Assert.AreEqual(256, LData.BlockValue(3));
  Assert.AreEqual(8, LData.BlockValue(4));
  Assert.AreEqual(77, LData.BlockValue(5));
end;

procedure TTestXcomMapData.DovrebbeLeggereLaQuotaDelTerrenoConSegno;
var
  LRecord: TBytes;
begin
  LRecord := Part(0, 0, 1);
  LRecord[48] := 232;
  AddMcd([LRecord]);
  FLoader.LoadData(FSet, nil);
  Assert.AreEqual(-24, FSet.GetObject(0).TerrainLevel);
end;

procedure TTestXcomMapData.DovrebbeIgnorareUnaCodaPiuCortaDiUnRecord;
var
  LBytes: TBytes;
begin
  LBytes := Part(0, 0, 1) + Part(1, 1, 1);
  SetLength(LBytes, Length(LBytes) + 30);
  FFiles.AddBytes('TERRAIN/TEST.MCD', LBytes);
  FLoader.LoadData(FSet, nil);
  Assert.AreEqual(2, FSet.Size);
end;

procedure TTestXcomMapData.DovrebbeSollevareErroreSeMancaIlFileMcd;
begin
  Assert.WillRaise(procedure begin FLoader.LoadData(FSet, nil); end, EXcomModException);
end;

procedure TTestXcomMapData.DovrebbeCaricareUnaSolaVolta;
begin
  AddMcd([Part(0, 0, 1)]);
  FLoader.LoadData(FSet, nil);
  FLoader.LoadData(FSet, nil);
  Assert.AreEqual(1, FSet.Size);
  Assert.IsTrue(FSet.Loaded);
end;

procedure TTestXcomMapData.DovrebbeSegnalareLePartiNonValide;
begin
  AddMcd([Part(0, 0, 1), Part(5, 9, 0)]);
  try
    FLoader.LoadData(FSet, nil);
    Assert.Fail('doveva fallire');
  except
    on E: EXcomModException do
      Assert.AreEqual('invalid MCD file: TERRAIN/TEST.MCD, check log file for more details.', E.Message);
  end;
  Assert.AreEqual(3, Length(FLoader.Problems));
  Assert.AreEqual('MCD TEST object 1 has invalid DieMCD: 5', FLoader.Problems[0]);
  Assert.AreEqual('MCD TEST object 1 has invalid AltMCD: 9', FLoader.Problems[1]);
  Assert.AreEqual('MCD TEST object 1 has 0 armor', FLoader.Problems[2]);
  // the parts read stay in the set and the set counts as loaded
  Assert.AreEqual(2, FSet.Size);
  Assert.IsTrue(FSet.Loaded);
end;

procedure TTestXcomMapData.DovrebbeSollevareErroreSeUnaParteNonHaCorazza;
begin
  AddMcd([Part(0, 0, 0)]);
  Assert.WillRaise(procedure begin FLoader.LoadData(FSet, nil); end, EXcomModException);
end;

procedure TTestXcomMapData.DovrebbeSollevareErroreSeLOggettoNonEsiste;
begin
  AddMcd([Part(0, 0, 1)]);
  FLoader.LoadData(FSet, nil);
  try
    FSet.GetObject(3);
    Assert.Fail('doveva fallire');
  except
    on E: EXcomModException do
      Assert.AreEqual('MCD TEST has no object 3', E.Message);
  end;
end;

procedure TTestXcomMapData.DovrebbeApplicareLaPatchDeiMod;
var
  LPatch: TXcomMcdPatch;
  LData: TXcomMapData;
begin
  AddMcd([Part(0, 0, 1), Part(1, 1, 1)]);
  LPatch := Patch('data: [{MCDIndex: 1, bigWall: 2, TUWalk: 9, TUFly: 8, TUSlide: 7, deathTile: 0, terrainHeight: -6, ' +
    'specialType: 4, explosive: 50, armor: 33, flammability: 12, fuel: 3, footstepSound: 2, HEBlock: 99, ' +
    'noFloor: true, stopLOS: true, objectType: 3, LOFTS: [1, 2, 3]}]');
  try
    FLoader.LoadData(FSet, LPatch);
  finally
    LPatch.Free;
  end;
  LData := FSet.GetObject(1);
  Assert.AreEqual(2, LData.BigWall);
  Assert.AreEqual(9, LData.TuWalk);
  Assert.AreEqual(8, LData.TuFly);
  Assert.AreEqual(7, LData.TuSlide);
  Assert.AreEqual(0, LData.DieMcd);
  Assert.AreEqual(-6, LData.TerrainLevel);
  // the special type keeps the object type that the patch sets later
  Assert.AreEqual(4, LData.SpecialType);
  Assert.AreEqual(3, LData.ObjectType);
  Assert.AreEqual(50, LData.Explosive);
  Assert.AreEqual(33, LData.Armor);
  Assert.AreEqual(12, LData.Flammable);
  Assert.AreEqual(3, LData.Fuel);
  Assert.AreEqual(2, LData.FootstepSound);
  Assert.AreEqual(99, LData.BlockValue(2));
  Assert.IsTrue(LData.IsNoFloor);
  Assert.IsTrue(LData.StopLos);
  Assert.AreEqual(255, LData.BlockValue(1));
  Assert.AreEqual(3, LData.GetLoftId(2));
  Assert.AreEqual(0, LData.GetLoftId(3));
end;

procedure TTestXcomMapData.DovrebbeApplicareLaPatchPrimaDelControllo;
var
  LPatch: TXcomMcdPatch;
begin
  // the part has no armor in the file: the patch gives it before the check
  AddMcd([Part(0, 0, 0)]);
  LPatch := Patch('data: [{MCDIndex: 0, armor: 5}]');
  try
    FLoader.LoadData(FSet, LPatch);
  finally
    LPatch.Free;
  end;
  Assert.AreEqual(5, FSet.GetObject(0).Armor);
end;

procedure TTestXcomMapData.DovrebbeSollevareErroreSePatchHaUnIndiceCheNonEsiste;
var
  LPatch: TXcomMcdPatch;
begin
  AddMcd([Part(0, 0, 1)]);
  LPatch := Patch('data: [{MCDIndex: 4, armor: 5}]');
  try
    Assert.WillRaise(procedure begin FLoader.LoadData(FSet, LPatch); end, EXcomModException);
  finally
    LPatch.Free;
  end;
end;

procedure TTestXcomMapData.DovrebbeSollevareErroreSeLeLoftSuperanoIDodiciStrati;
var
  LPatch: TXcomMcdPatch;
begin
  AddMcd([Part(0, 0, 1)]);
  LPatch := Patch('data: [{MCDIndex: 0, LOFTS: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]}]');
  try
    Assert.WillRaise(procedure begin FLoader.LoadData(FSet, LPatch); end, EXcomModException);
  finally
    LPatch.Free;
  end;
end;

procedure TTestXcomMapData.DovrebbeTenereLaDefinizioneDelleDueTegoleVuote;
var
  LBlanks: TXcomMapDataSet;
begin
  Assert.IsNull(FSet.BlankFloorTile);
  LBlanks := TXcomMapDataSet.Create('BLANKS');
  try
    Assert.IsNull(LBlanks.BlankFloorTile);
    FFiles.AddBytes('TERRAIN/BLANKS.MCD', Part(0, 0, 1) + Part(1, 1, 1));
    FLoader.LoadData(LBlanks, nil);
    Assert.AreSame(LBlanks.GetObject(0), LBlanks.BlankFloorTile);
    Assert.AreSame(LBlanks.GetObject(1), LBlanks.ScorchedEarthTile);
  finally
    LBlanks.Free;
  end;
end;

procedure TTestXcomMapData.DovrebbeScaricareIDati;
begin
  AddMcd([Part(0, 0, 1)]);
  FLoader.LoadData(FSet, nil);
  FSet.Unload;
  Assert.AreEqual(0, FSet.Size);
  Assert.IsFalse(FSet.Loaded);
  FLoader.LoadData(FSet, nil);
  Assert.AreEqual(1, FSet.Size);
end;

procedure TTestXcomMapData.DovrebbeDareIBloccoPerTipoDiDanno;
var
  LData: TXcomMapData;
begin
  LData := TXcomMapData.Create;
  try
    LData.SetBlockValue(1, 1, 40, 1, 2, 3);
    // none: sight; incendiary, HE and stun: HE; smoke: smoke; the rest nothing
    Assert.AreEqual(255, LData.GetBlock(0));
    Assert.AreEqual(40, LData.GetBlock(2));
    Assert.AreEqual(40, LData.GetBlock(3));
    Assert.AreEqual(40, LData.GetBlock(6));
    Assert.AreEqual(256, LData.GetBlock(9));
    Assert.AreEqual(0, LData.GetBlock(1));
    Assert.AreEqual(0, LData.GetBlock(8));
    LData.SetBlockValue(0, 2, 0, 5, 0, 0);
    Assert.AreEqual(0, LData.GetBlock(0));
    Assert.AreEqual(0, LData.GetBlock(9));
  finally
    LData.Free;
  end;
end;

procedure TTestXcomMapData.DovrebbeDareICostiDiMovimento;
var
  LData: TXcomMapData;
begin
  LData := TXcomMapData.Create;
  try
    LData.SetTuCosts(4, 5, 6);
    Assert.AreEqual(4, LData.GetTuCost(XCOM_MOVE_WALK));
    Assert.AreEqual(5, LData.GetTuCost(XCOM_MOVE_FLY));
    Assert.AreEqual(6, LData.GetTuCost(XCOM_MOVE_SLIDE));
    Assert.AreEqual(0, LData.GetTuCost(XCOM_MOVE_FLOAT));
    Assert.AreEqual(0, LData.GetTuCost(XCOM_MOVE_SINK));
  finally
    LData.Free;
  end;
end;

procedure TTestXcomMapData.DovrebbeDareLaLuceEmessa;
var
  LData: TXcomMapData;
begin
  LData := TXcomMapData.Create;
  try
    Assert.AreEqual(-1, LData.GetLightSource);
    LData.LightSource := 1;
    Assert.AreEqual(15, LData.GetLightSource);
    LData.LightSource := 6;
    Assert.AreEqual(5, LData.GetLightSource);
  finally
    LData.Free;
  end;
end;

procedure TTestXcomMapData.DovrebbeSollevareErroreSeLIndiceDelloStratoNonEsiste;
var
  LData: TXcomMapData;
begin
  LData := TXcomMapData.Create;
  try
    Assert.WillRaise(procedure begin LData.GetLoftId(12); end, EXcomModException);
    Assert.WillRaise(procedure begin LData.SetSprite(8, 1); end, EXcomModException);
    Assert.WillRaise(procedure begin LData.BlockValue(-1); end, EXcomModException);
  finally
    LData.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMapData);

end.
