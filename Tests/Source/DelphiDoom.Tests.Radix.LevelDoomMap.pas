{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixDoomMap, TRadixLevelTable and TRadixLevelFixOps  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelDoomMap;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.Table,
  DelphiDoom.Radix.Level.Coordinates, DelphiDoom.Radix.Level.DoomMap, DelphiDoom.Radix.Level.Reader,
  DelphiDoom.Radix.Level.FixOps, DelphiDoom.Tests.Radix.LevelBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixDoomMap = class(TObject)
  strict private
    FBuilder: TRadixLevelBuilder;
    FLevel: TRadixLevelData;
    FCoordinates: TRadixLevelCoordinates;
    FMap: TRadixDoomMap;
    procedure MakeMap;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFarCrescereLaTabellaECambiareIRecordSulPosto;
    [Test]
    procedure DovrebbeSollevareFuoriDallaTabella;
    [Test]
    procedure DovrebbeDareIBytesDellaTabella;
    [Test]
    procedure DovrebbeRiusareUnVerticeGiaPresente;
    [Test]
    procedure DovrebbeTenereLOffsetNegativoEFareIlModuloDi128;
    [Test]
    procedure DovrebbeNonUnireLeSideAnchePerdueUguali;
    [Test]
    procedure DovrebbeScrivereLaPosizioneDelSettoreNelloScript;
    [Test]
    procedure DovrebbeScrivereLaPendenzaSoloSeIlSettoreLaHa;
    [Test]
    procedure DovrebbeScrivereGliAngoliDelleTextureSoloSeCe;
    [Test]
    procedure DovrebbeGirareLeLineeDiUnMuroSenzaLatoAnteriore;
    [Test]
    procedure DovrebbeSpostareUnVertice;
    [Test]
    procedure DovrebbeCambiareUnVerticeNelleLinee;
    [Test]
    procedure DovrebbeNonCambiareNullaSeUnVerticeNonCe;
    [Test]
    procedure DovrebbeMettereUnaCosaOgniMezzoMetroUnPoco;
    [Test]
    procedure DovrebbeMettereAlmenoUnaCosaSuUnaLineaCorta;
    [Test]
    procedure DovrebbeCambiareIlSettoreDeiLati;
    [Test]
    procedure DovrebbeFareUnaLineaScorrevoleEUnaBloccante;
    [Test]
    procedure DovrebbeClonareUnMuroSpostato;
    [Test]
    procedure DovrebbeFareUnaLineaAUnSoloLatoBloccante;
  end;

implementation

{ TTestRadixDoomMap }

procedure TTestRadixDoomMap.Setup;
begin
  FBuilder := TRadixLevelBuilder.Create;
  FLevel := nil;
  FCoordinates := TRadixLevelCoordinates.Create(False);
  FMap := nil;
end;

procedure TTestRadixDoomMap.TearDown;
begin
  FMap.Free;
  FCoordinates.Free;
  FLevel.Free;
  FBuilder.Free;
end;

procedure TTestRadixDoomMap.MakeMap;
var
  LPositions: TArray<TRadixSectorPosition>;
  LIndex: Integer;
begin
  FLevel := TRadixLevelReader.Create.TryRead('E1M1', FBuilder.ToBytes);
  SetLength(LPositions, Length(FLevel.Sectors));
  for LIndex := 0 to High(LPositions) do
  begin
    LPositions[LIndex].XMul := 1;
    LPositions[LIndex].XAdd := -32767;
    LPositions[LIndex].YMul := -1;
    LPositions[LIndex].YAdd := 0;
  end;
  FMap := TRadixDoomMap.Create(FLevel, FCoordinates, LPositions, nil);
end;

procedure TTestRadixDoomMap.DovrebbeFarCrescereLaTabellaECambiareIRecordSulPosto;
var
  LTable: TRadixLevelTable<TRadixDoomVertex>;
  LVertex: TRadixDoomVertex;
  LIndex: Integer;
begin
  LTable := TRadixLevelTable<TRadixDoomVertex>.Create;
  try
    for LIndex := 0 to 99 do
    begin
      LVertex.X := LIndex;
      LVertex.Y := -LIndex;
      Assert.AreEqual(LIndex, LTable.Add(LVertex));
    end;
    LTable[50].Y := 7;
    Assert.AreEqual(100, LTable.Count);
    Assert.AreEqual(Integer(7), Integer(LTable[50].Y));
    Assert.AreEqual(Integer(99), Integer(LTable[99].X));
  finally
    LTable.Free;
  end;
end;

procedure TTestRadixDoomMap.DovrebbeSollevareFuoriDallaTabella;
var
  LTable: TRadixLevelTable<TRadixDoomVertex>;
begin
  LTable := TRadixLevelTable<TRadixDoomVertex>.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LTable[0];
      end, ERangeError);
  finally
    LTable.Free;
  end;
end;

procedure TTestRadixDoomMap.DovrebbeDareIBytesDellaTabella;
var
  LTable: TRadixLevelTable<TRadixDoomVertex>;
  LVertex: TRadixDoomVertex;
  LBytes: TBytes;
begin
  LTable := TRadixLevelTable<TRadixDoomVertex>.Create;
  try
    Assert.AreEqual(0, Length(LTable.ToBytes));
    LVertex.X := $0102;
    LVertex.Y := $0304;
    LTable.Add(LVertex);
    LBytes := LTable.ToBytes;
    Assert.AreEqual(4, Length(LBytes));
    Assert.AreEqual(Integer(2), Integer(LBytes[0]));
    Assert.AreEqual(Integer(3), Integer(LBytes[3]));
  finally
    LTable.Free;
  end;
end;

procedure TTestRadixDoomMap.DovrebbeRiusareUnVerticeGiaPresente;
begin
  MakeMap;
  Assert.AreEqual(0, FMap.AddVertex(10, 20));
  Assert.AreEqual(1, FMap.AddVertex(11, 20));
  Assert.AreEqual(0, FMap.AddVertex(10, 20));
  Assert.AreEqual(2, FMap.Vertexes.Count);
end;

procedure TTestRadixDoomMap.DovrebbeTenereLOffsetNegativoEFareIlModuloDi128;
begin
  MakeMap;
  FMap.AddSideDef(-5, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('-'), 0);
  FMap.AddSideDef(300, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('-'), 0);
  Assert.AreEqual(Integer(-5), Integer(FMap.SideDefs[0].TextureOffset));
  Assert.AreEqual(Integer(300 mod 128), Integer(FMap.SideDefs[1].TextureOffset));
end;

procedure TTestRadixDoomMap.DovrebbeNonUnireLeSideAnchePerdueUguali;
begin
  MakeMap;
  Assert.AreEqual(0, FMap.AddSideDef(0, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('A'), 0));
  Assert.AreEqual(1, FMap.AddSideDef(0, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('A'), 0));
end;

procedure TTestRadixDoomMap.DovrebbeScrivereLaPosizioneDelSettoreNelloScript;
begin
  FBuilder.AddSector(0, 128, 0, 0, 10, 0);
  MakeMap;
  FMap.AddSector(FLevel.Sectors[0]);
  Assert.AreEqual('sectorid 0'#13#10'xmul 1'#13#10'xadd -32767'#13#10'ymul -1'#13#10'yadd 0'#13#10 +
    'sectorflags ' + IntToStr(RSF_RADIXSECTOR) + #13#10#13#10, FMap.ScriptText);
end;

procedure TTestRadixDoomMap.DovrebbeScrivereLaPendenzaSoloSeIlSettoreLaHa;
var
  LText: string;
begin
  FBuilder.AddSector(0, 128, 0, 0, 10, RSF_FLOORSLOPE);
  MakeMap;
  FLevel.Sectors[0].FloorA := 1;
  FLevel.Sectors[0].FloorD := 4;
  FLevel.Sectors[0].HeightNodesX[2] := 9;
  FLevel.Sectors[0].FloorHeights[1] := 5;
  FLevel.Sectors[0].CeilingHeights[1] := 6;
  FMap.AddSector(FLevel.Sectors[0]);
  LText := FMap.ScriptText;
  Assert.IsTrue(LText.Contains('floorslope 1 0 0 4'#13#10));
  Assert.IsTrue(LText.Contains('heightnodesx 0 0 9'#13#10));
  Assert.IsTrue(LText.Contains('floorheights 0 5 0'#13#10));
  Assert.IsFalse(LText.Contains('ceilingslope'));
  Assert.IsFalse(LText.Contains('ceilingheights'));
end;

procedure TTestRadixDoomMap.DovrebbeScrivereGliAngoliDelleTextureSoloSeCe;
var
  LText: string;
begin
  FBuilder.AddSector(0, 128, 0, 0, 10, 0);
  MakeMap;
  FLevel.Sectors[0].FloorAngle := $C0000000;
  FLevel.Sectors[0].FloorAngleX := 11;
  FMap.AddSector(FLevel.Sectors[0]);
  LText := FMap.ScriptText;
  // as an Integer, like itoa of the old code
  Assert.IsTrue(LText.Contains('floorangle ' + IntToStr(Integer($C0000000)) + #13#10));
  Assert.IsTrue(LText.Contains('floorangle_x 11'#13#10));
  Assert.IsFalse(LText.Contains('ceilingangle'));
end;

procedure TTestRadixDoomMap.DovrebbeGirareLeLineeDiUnMuroSenzaLatoAnteriore;
var
  LWall: TRadixLevelWall;
begin
  FBuilder.AddSector(0, 128, 0, 1, 10, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, -1, 0, RWF_SINGLESIDED);
  MakeMap;
  FMap.AddSector(FLevel.Sectors[0]);
  LWall := FLevel.Walls[0];
  TRadixLevelCoordinates.ConvertDefault(LWall.V1X, LWall.V1Y);
  TRadixLevelCoordinates.ConvertDefault(LWall.V2X, LWall.V2Y);
  FMap.AddWall(LWall);
  // the vertices go the other way round and the side is the back one
  Assert.AreEqual(1, Integer(FMap.LineDefs[0].V1));
  Assert.AreEqual(0, Integer(FMap.LineDefs[0].V2));
  Assert.AreEqual(0, Integer(FMap.LineDefs[0].SideNum[0]));
  Assert.AreEqual(-1, Integer(FMap.LineDefs[0].SideNum[1]));
end;

procedure TTestRadixDoomMap.DovrebbeSpostareUnVertice;
begin
  MakeMap;
  FMap.AddVertex(1, 2);
  FMap.AddVertex(3, 4);
  TRadixLevelFixOps.MoveVertex(FMap, 3, 4, 30, 40);
  TRadixLevelFixOps.MoveVertex(FMap, 99, 99, 0, 0);
  Assert.AreEqual(Integer(30), Integer(FMap.Vertexes[1].X));
  Assert.AreEqual(Integer(2), Integer(FMap.Vertexes[0].Y));
end;

procedure TTestRadixDoomMap.DovrebbeCambiareUnVerticeNelleLinee;
var
  LLine: TRadixDoomLineDef;
begin
  MakeMap;
  FMap.AddVertex(1, 1);
  FMap.AddVertex(2, 2);
  FMap.AddVertex(3, 3);
  FillChar(LLine, SizeOf(LLine), 0);
  LLine.V1 := 0;
  LLine.V2 := 1;
  FMap.LineDefs.Add(LLine);
  LLine.V1 := 1;
  LLine.V2 := 2;
  FMap.LineDefs.Add(LLine);
  TRadixLevelFixOps.ChangeVertexes(FMap, 2, 2, 3, 3);
  Assert.AreEqual(Integer(0), Integer(FMap.LineDefs[0].V1));
  Assert.AreEqual(Integer(2), Integer(FMap.LineDefs[0].V2));
  Assert.AreEqual(Integer(2), Integer(FMap.LineDefs[1].V1));
  Assert.AreEqual(Integer(2), Integer(FMap.LineDefs[1].V2));
end;

procedure TTestRadixDoomMap.DovrebbeNonCambiareNullaSeUnVerticeNonCe;
var
  LLine: TRadixDoomLineDef;
begin
  MakeMap;
  FMap.AddVertex(1, 1);
  FillChar(LLine, SizeOf(LLine), 0);
  FMap.LineDefs.Add(LLine);
  TRadixLevelFixOps.ChangeVertexes(FMap, 1, 1, 5, 5);
  Assert.AreEqual(Integer(0), Integer(FMap.LineDefs[0].V1));
end;

procedure TTestRadixDoomMap.DovrebbeMettereUnaCosaOgniMezzoMetroUnPoco;
begin
  MakeMap;
  // 128 units: sqrt = 128, 128 / 64 + 0.4999 rounds to 2
  TRadixLevelFixOps.SlideSegment(FMap, 0, 0, 128, 0);
  Assert.AreEqual(2, FMap.Things.Count);
  Assert.AreEqual(Integer(32), Integer(FMap.Things[0].X));
  Assert.AreEqual(Integer(96), Integer(FMap.Things[1].X));
  Assert.AreEqual(Integer(MT_PLAYERFLOORSLIDE64), Integer(FMap.Things[0].ThingType));
  Assert.AreEqual(Integer(MTF_EASY or MTF_NORMAL or MTF_HARD), Integer(FMap.Things[0].Options));
  Assert.AreEqual(2, FMap.ThingExtras.Count);
  Assert.AreEqual(Integer(-1), Integer(FMap.ThingExtras[0].RadixId));
end;

procedure TTestRadixDoomMap.DovrebbeMettereAlmenoUnaCosaSuUnaLineaCorta;
begin
  MakeMap;
  TRadixLevelFixOps.SlideSegment(FMap, 10, 10, 10, 10);
  Assert.AreEqual(1, FMap.Things.Count);
  Assert.AreEqual(Integer(10), Integer(FMap.Things[0].X));
end;

procedure TTestRadixDoomMap.DovrebbeCambiareIlSettoreDeiLati;
begin
  MakeMap;
  FMap.AddSideDef(0, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('-'), 3);
  FMap.AddSideDef(0, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('-'), 4);
  TRadixLevelFixOps.ReplaceSideSector(FMap, 3, 9);
  Assert.AreEqual(Integer(9), Integer(FMap.SideDefs[0].Sector));
  Assert.AreEqual(Integer(4), Integer(FMap.SideDefs[1].Sector));
end;

procedure TTestRadixDoomMap.DovrebbeFareUnaLineaScorrevoleEUnaBloccante;
var
  LLine: TRadixDoomLineDef;
begin
  MakeMap;
  FillChar(LLine, SizeOf(LLine), 0);
  FMap.LineDefs.Add(LLine);
  TRadixLevelFixOps.MakeSlideLine(FMap, 0);
  Assert.AreEqual(Integer(ML_SLIDELINE), Integer(FMap.LineDefs[0].Flags));
  TRadixLevelFixOps.MakeBlockingLine(FMap, 0);
  Assert.AreEqual(Integer(ML_SLIDELINE or ML_BLOCKING), Integer(FMap.LineDefs[0].Flags));
end;

procedure TTestRadixDoomMap.DovrebbeClonareUnMuroSpostato;
var
  LWall: TRadixLevelWall;
begin
  FBuilder.AddSector(0, 128, 0, 1, 10, 0);
  FBuilder.AddWall(100, 100, 200, 100, 0, -1, RWF_SINGLESIDED);
  MakeMap;
  LWall := FLevel.Walls[0];
  TRadixLevelCoordinates.ConvertDefault(LWall.V1X, LWall.V1Y);
  TRadixLevelCoordinates.ConvertDefault(LWall.V2X, LWall.V2Y);
  FLevel.Walls[0] := LWall;
  TRadixLevelFixOps.CloneAndMoveWall(FMap, 0, 10, 20);
  Assert.AreEqual(1, FMap.LineDefs.Count);
  Assert.AreEqual(Integer(100 - 32767 + 10), Integer(FMap.Vertexes[0].X));
  Assert.AreEqual(Integer(-100 + 20), Integer(FMap.Vertexes[0].Y));
end;

procedure TTestRadixDoomMap.DovrebbeFareUnaLineaAUnSoloLatoBloccante;
var
  LLine: TRadixDoomLineDef;
begin
  MakeMap;
  FillChar(LLine, SizeOf(LLine), 0);
  LLine.Flags := ML_TWOSIDED;
  LLine.SideNum[0] := 5;
  LLine.SideNum[1] := 6;
  FMap.LineDefs.Add(LLine);
  TRadixLevelFixOps.MakeOneSided(FMap, 0, 2);
  Assert.AreEqual(Integer(ML_BLOCKING), Integer(FMap.LineDefs[0].Flags));
  Assert.AreEqual(Integer(2), Integer(FMap.LineDefs[0].SideNum[0]));
  Assert.AreEqual(Integer(-1), Integer(FMap.LineDefs[0].SideNum[1]));
end;

end.
