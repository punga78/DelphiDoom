{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLevelConverter                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelConverter;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory, DelphiDoom.Radix.Level.Types,
  DelphiDoom.Radix.Level.Converter, DelphiDoom.Radix.Level.Factory, DelphiDoom.Tests.Radix.LevelBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelConverter = class(TObject)
  strict private
    FConverter: TRadixLevelConverter;
    FBuilder: TRadixLevelBuilder;
    FWad: IGameWadComposer;
    FFlats: TList<Integer>;
    function Convert(const AName: string; AExtraInfo: Boolean = True): Boolean;
    function Lump(const AName: string): TBytes;
    function LineDef(AIndex: Integer): TRadixDoomLineDef;
    function SideDef(AIndex: Integer): TRadixDoomSideDef;
    function Vertex(AIndex: Integer): TRadixDoomVertex;
    function Thing(AIndex: Integer): TRadixDoomThing;
    function Sector(AIndex: Integer): TRadixDoomSector;
    procedure MakeRoom;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareFalsoESenzaLumpSeNonEUnLivello;
    [Test]
    procedure DovrebbeScrivereILumpDiUnaMappaDiDoomNellOrdineGiusto;
    [Test]
    procedure DovrebbeScrivereSoloLaMappaSenzaLeInformazioniExtra;
    [Test]
    procedure DovrebbeSpostareIVerticiNelleCoordinateDiDoom;
    [Test]
    procedure DovrebbeFareUnSoloVerticeDaDuePuntiUguali;
    [Test]
    procedure DovrebbeFareUnMuroAUnLatoBloccanteConLaTexturaNelMezzo;
    [Test]
    procedure DovrebbeFareUnaLineaAdoppiaFacciaDaUnMuroConDueSettori;
    [Test]
    procedure DovrebbeMettereLeFlatDeiSettoriEMarcarle;
    [Test]
    procedure DovrebbeMettereIlCieloNeiSettoriConIlFlagDelCielo;
    [Test]
    procedure DovrebbeCalcolareLaLuceDelSettore;
    [Test]
    procedure DovrebbeAggiungereLeOttoPartenzeEIlResto;
    [Test]
    procedure DovrebbeSaltareLeCoseSenzaChiaveOSenzaTipo;
    [Test]
    procedure DovrebbeRendereInattiviIDroniDelPrimoEpisodio;
    [Test]
    procedure DovrebbeNonRendereInattiviIDroniDeglIAltriEpisodi;
    [Test]
    procedure DovrebbeAggiungereTreMuriFintiPerUnSettoreSenzaLati;
    [Test]
    procedure DovrebbeSpostareLeLineeSenzaLatiFuoriDallaMappa;
    [Test]
    procedure DovrebbeScrivereLaGrigliaDeiTriggerEQuellaDelleCoordinate;
    [Test]
    procedure DovrebbeScrivereLeAzioniEITriggerCosiComeSono;
    [Test]
    procedure DovrebbeScrivereLoScriptConGliIdDeiSettoriEDeiMuri;
  end;

implementation

{ TTestRadixLevelConverter }

procedure TTestRadixLevelConverter.Setup;
begin
  FConverter := TRadixLevelConverter.Create(TRadixLevelFactory.CreateReader, TRadixLevelFactory.CreateFixSelector);
  FBuilder := TRadixLevelBuilder.Create;
  FWad := TGameDataFactory.CreateWadComposer;
  FFlats := TList<Integer>.Create;
end;

procedure TTestRadixLevelConverter.TearDown;
begin
  FFlats.Free;
  FBuilder.Free;
  FConverter.Free;
end;

function TTestRadixLevelConverter.Convert(const AName: string; AExtraInfo: Boolean): Boolean;
begin
  Result := FConverter.Convert(AName, FBuilder.ToBytes, FWad, AExtraInfo,
    procedure(AFlat: Integer)
    begin
      FFlats.Add(AFlat);
    end);
end;

function TTestRadixLevelConverter.Lump(const AName: string): TBytes;
var
  LIndex: Integer;
begin
  LIndex := FWad.IndexOf(AName);
  Assert.IsTrue(LIndex >= 0, 'the lump ' + AName);
  Result := FWad.LumpData[LIndex];
end;

function TTestRadixLevelConverter.LineDef(AIndex: Integer): TRadixDoomLineDef;
begin
  Move(Lump('LINEDEFS')[AIndex * SizeOf(Result)], Result, SizeOf(Result));
end;

function TTestRadixLevelConverter.SideDef(AIndex: Integer): TRadixDoomSideDef;
begin
  Move(Lump('SIDEDEFS')[AIndex * SizeOf(Result)], Result, SizeOf(Result));
end;

function TTestRadixLevelConverter.Vertex(AIndex: Integer): TRadixDoomVertex;
begin
  Move(Lump('VERTEXES')[AIndex * SizeOf(Result)], Result, SizeOf(Result));
end;

function TTestRadixLevelConverter.Thing(AIndex: Integer): TRadixDoomThing;
begin
  Move(Lump('THINGS')[AIndex * SizeOf(Result)], Result, SizeOf(Result));
end;

function TTestRadixLevelConverter.Sector(AIndex: Integer): TRadixDoomSector;
begin
  Move(Lump('SECTORS')[AIndex * SizeOf(Result)], Result, SizeOf(Result));
end;

// a room with a floor and a ceiling (sector 0) and a one sided wall
procedure TTestRadixLevelConverter.MakeRoom;
begin
  FBuilder.AddSector(0, 128, 0, 1, 10, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, -1, RWF_SINGLESIDED);
end;

procedure TTestRadixLevelConverter.DovrebbeDareFalsoESenzaLumpSeNonEUnLivello;
begin
  Assert.IsFalse(FConverter.Convert('E1M1', [1, 2, 3, 4], FWad, True, nil));
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestRadixLevelConverter.DovrebbeScrivereILumpDiUnaMappaDiDoomNellOrdineGiusto;
const
  Names: array[0..16] of string = ('E1M2', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS',
    'NODES', 'SECTORS', 'REJECT', 'BLOCKMAP', 'RMAP', 'RTHINGS', 'RGRID', 'RMAPGRID', 'RACTION', 'RTRIGGER');
var
  LIndex: Integer;
begin
  MakeRoom;
  Assert.IsTrue(Convert('E1M2'));
  Assert.AreEqual(Length(Names), FWad.Count);
  for LIndex := 0 to High(Names) do
    Assert.AreEqual(Names[LIndex], FWad.LumpNames[LIndex]);
  // the nodes are not made: the engine does it
  Assert.AreEqual<Integer>(0, Length(FWad.LumpData[5]));
  Assert.AreEqual<Integer>(0, Length(FWad.LumpData[7]));
end;

procedure TTestRadixLevelConverter.DovrebbeScrivereSoloLaMappaSenzaLeInformazioniExtra;
begin
  MakeRoom;
  Assert.IsTrue(Convert('E1M2', False));
  Assert.AreEqual(11, FWad.Count);
  Assert.AreEqual('BLOCKMAP', FWad.LumpNames[10]);
end;

procedure TTestRadixLevelConverter.DovrebbeSpostareIVerticiNelleCoordinateDiDoom;
begin
  MakeRoom;
  Convert('E1M2');
  Assert.AreEqual(Integer(233), Integer(Vertex(0).X));
  Assert.AreEqual(Integer(-100), Integer(Vertex(0).Y));
  Assert.AreEqual(Integer(333), Integer(Vertex(1).X));
end;

procedure TTestRadixLevelConverter.DovrebbeFareUnSoloVerticeDaDuePuntiUguali;
begin
  FBuilder.AddSector(0, 128, 0, 1, 10, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, -1, RWF_SINGLESIDED);
  FBuilder.AddWall(33100, 100, 33100, 200, 0, -1, RWF_SINGLESIDED);
  Convert('E1M2');
  Assert.AreEqual<Integer>(3, Length(Lump('VERTEXES')) div SizeOf(TRadixDoomVertex));
  Assert.AreEqual(Integer(1), Integer(LineDef(1).V1));
end;

procedure TTestRadixLevelConverter.DovrebbeFareUnMuroAUnLatoBloccanteConLaTexturaNelMezzo;
begin
  MakeRoom;
  Convert('E1M2');
  Assert.AreEqual(Integer(ML_BLOCKING), Integer(LineDef(0).Flags));
  Assert.AreEqual(Integer(-1), Integer(LineDef(0).SideNum[1]));
  // the texture of the wall is the one of the floor plus 1 (the stub RDXW0000)
  Assert.AreEqual(TRadixName8.Make('RDXW0001'), SideDef(0).MidTexture);
  Assert.AreEqual(TRadixName8.Make('-'), SideDef(0).TopTexture);
end;

procedure TTestRadixLevelConverter.DovrebbeFareUnaLineaAdoppiaFacciaDaUnMuroConDueSettori;
begin
  FBuilder.AddSector(0, 128, 0, 1, 10, 0);
  FBuilder.AddSector(16, 128, 0, 1, 10, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, 1, RWF_FLOORWALL);
  Convert('E1M2');
  Assert.AreEqual(Integer(ML_TWOSIDED), Integer(LineDef(0).Flags));
  Assert.AreEqual(Integer(0), Integer(LineDef(0).SideNum[0]));
  Assert.AreEqual(Integer(1), Integer(LineDef(0).SideNum[1]));
  Assert.AreEqual(TRadixName8.Make('RDXW0001'), SideDef(0).BottomTexture);
  Assert.AreEqual(TRadixName8.Make('-'), SideDef(0).MidTexture);
end;

procedure TTestRadixLevelConverter.DovrebbeMettereLeFlatDeiSettoriEMarcarle;
begin
  FBuilder.AddSector(0, 128, 4, 9, 10, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, -1, RWF_SINGLESIDED);
  Convert('E1M2');
  Assert.AreEqual(TRadixName8.Make('RDXF0005'), Sector(0).FloorPic);
  Assert.AreEqual(TRadixName8.Make('RDXF0010'), Sector(0).CeilingPic);
  Assert.AreEqual(2, FFlats.Count);
  Assert.AreEqual(5, FFlats[0]);
  Assert.AreEqual(10, FFlats[1]);
end;

procedure TTestRadixLevelConverter.DovrebbeMettereIlCieloNeiSettoriConIlFlagDelCielo;
begin
  FBuilder.AddSector(0, 128, 4, 9, 10, RSF_FLOORSKY or RSF_CEILINGSKY);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, -1, RWF_SINGLESIDED);
  Convert('E1M2');
  Assert.AreEqual(TRadixName8.Make('F_SKY1'), Sector(0).FloorPic);
  Assert.AreEqual(TRadixName8.Make('F_SKY1'), Sector(0).CeilingPic);
  Assert.AreEqual(0, FFlats.Count);
end;

procedure TTestRadixLevelConverter.DovrebbeCalcolareLaLuceDelSettore;
begin
  FBuilder.AddSector(0, 128, 0, 1, 40, 0);
  FBuilder.AddSector(0, 128, 0, 1, 10, RSF_FOG);
  FBuilder.AddSector(0, 128, 0, 1, 64, RSF_DARKNESS);
  FBuilder.AddSector(0, 128, 0, 1, 255, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, 1, RWF_SINGLESIDED);
  FBuilder.AddWall(33000, 100, 33100, 100, 2, 3, RWF_SINGLESIDED);
  Convert('E1M2');
  Assert.AreEqual(Integer(220), Integer(Sector(0).LightLevel));
  Assert.AreEqual(Integer(42), Integer(Sector(1).LightLevel));
  Assert.AreEqual(Integer(255), Integer(Sector(2).LightLevel));
  // 200 + 255 div 2 does not fit in a byte
  Assert.AreEqual(Integer((200 + 127) and $FF), Integer(Sector(3).LightLevel));
end;

procedure TTestRadixLevelConverter.DovrebbeAggiungereLeOttoPartenzeEIlResto;
begin
  MakeRoom;
  FBuilder.SetPlayerStart(0, 33000, 100, 8, 128);
  FBuilder.AddThing(33200, 300, 5, 7, 2, 64);
  Convert('E1M2');
  Assert.AreEqual<Integer>(9, Length(Lump('THINGS')) div SizeOf(TRadixDoomThing));
  Assert.AreEqual(Integer(1), Integer(Thing(0).ThingType));
  Assert.AreEqual(Integer(4), Integer(Thing(3).ThingType));
  Assert.AreEqual(Integer(11), Integer(Thing(4).ThingType));
  Assert.AreEqual(Integer(7), Integer(Thing(0).Options));
  Assert.AreEqual(Integer(180), Integer(Thing(0).Angle));
  Assert.AreEqual(Integer(233), Integer(Thing(0).X));
  // the thing of the level: type + 1000, skill 2 is normal and hard
  Assert.AreEqual(Integer(1005), Integer(Thing(8).ThingType));
  Assert.AreEqual(Integer(MTF_NORMAL or MTF_HARD), Integer(Thing(8).Options));
  Assert.AreEqual(Integer(-300), Integer(Thing(8).Y));
  Assert.AreEqual(Integer(90), Integer(Thing(8).Angle));
end;

procedure TTestRadixLevelConverter.DovrebbeSaltareLeCoseSenzaChiaveOSenzaTipo;
begin
  MakeRoom;
  FBuilder.AddThing(33200, 300, 5, -1, 0, 0);
  FBuilder.AddThing(33200, 300, -1, 4, 0, 0);
  Convert('E1M2');
  Assert.AreEqual<Integer>(8, Length(Lump('THINGS')) div SizeOf(TRadixDoomThing));
end;

procedure TTestRadixLevelConverter.DovrebbeRendereInattiviIDroniDelPrimoEpisodio;
begin
  MakeRoom;
  FBuilder.AddThing(33200, 300, 31, 1, 0, 0);
  Convert('E1M2');
  Assert.AreEqual(Integer(MT_DEFENCEDRONE_STUB1), Integer(Thing(8).ThingType));
  Assert.IsTrue(Thing(8).Options and MTF_INACTIVE <> 0);
end;

procedure TTestRadixLevelConverter.DovrebbeNonRendereInattiviIDroniDeglIAltriEpisodi;
begin
  MakeRoom;
  FBuilder.AddThing(33200, 300, 31, 1, 0, 0);
  Convert('E2M2');
  Assert.IsTrue(Thing(8).Options and MTF_INACTIVE = 0);
end;

procedure TTestRadixLevelConverter.DovrebbeAggiungereTreMuriFintiPerUnSettoreSenzaLati;
begin
  MakeRoom;
  // the sector 1 has no wall
  FBuilder.AddSector(0, 128, 0, 1, 10, 0);
  Convert('E1M2');
  Assert.AreEqual<Integer>(4, Length(Lump('LINEDEFS')) div SizeOf(TRadixDoomLineDef));
  Assert.AreEqual(Integer(ML_BLOCKING), Integer(LineDef(0).Flags));
  Assert.AreEqual(Integer(ML_DONTDRAW or ML_AUTOMAPIGNOGE or ML_BLOCKING), Integer(LineDef(1).Flags));
  // the middle texture of the stub is the second wall texture
  Assert.AreEqual(TRadixName8.Make('RDXW0002'), SideDef(1).MidTexture);
  Assert.AreEqual(Integer(1), Integer(SideDef(1).Sector));
end;

procedure TTestRadixLevelConverter.DovrebbeSpostareLeLineeSenzaLatiFuoriDallaMappa;
begin
  MakeRoom;
  // a sector that is a flat floor and has no textures makes no side: the line has none
  FBuilder.AddSector(64, 64, 0, 0, 10, 0);
  FBuilder.AddWall(33500, 500, 33600, 500, 1, -1, 0);
  Convert('E1M2');
  Assert.AreEqual(Integer(-1), Integer(LineDef(1).SideNum[0]));
  Assert.AreEqual(Integer(-1), Integer(LineDef(1).SideNum[1]));
  Assert.IsTrue(LineDef(1).Flags and ML_AUTOMAPIGNOGE <> 0);
  // 64 units to the right of the left edge, 256 above the top
  Assert.AreEqual(Integer(233 + 64), Integer(Vertex(LineDef(1).V1).X));
  Assert.AreEqual(Integer(32), Integer(Vertex(LineDef(1).V2).X - Vertex(LineDef(1).V1).X));
  Assert.AreEqual(Integer(-100 + 256), Integer(Vertex(LineDef(1).V1).Y));
end;

procedure TTestRadixLevelConverter.DovrebbeScrivereLaGrigliaDeiTriggerEQuellaDelleCoordinate;
var
  LGrid: TBytes;
  LPoints: TBytes;
  LPoint: TRadixLevelMapPoint;
begin
  MakeRoom;
  FBuilder.TriggerGridValue := 7;
  Convert('E1M2');
  LGrid := Lump('RGRID');
  Assert.AreEqual<Integer>(SizeOf(TRadixLevelGrid), Length(LGrid));
  Assert.AreEqual(320, Integer(PInteger(@LGrid[0])^));
  Assert.AreEqual(128, Integer(PInteger(@LGrid[4])^));
  Assert.AreEqual(7, Integer(PSmallInt(@LGrid[8])^));
  LPoints := Lump('RMAPGRID');
  Assert.AreEqual<Integer>(SizeOf(TRadixLevelMapPoints), Length(LPoints));
  Move(LPoints[4 * 321], LPoint, 4);
  // the cell (1, 1) is at (64, 64) in Radix
  Assert.AreEqual(Integer(64 - 32767), Integer(LPoint.X));
  Assert.AreEqual(Integer(-64), Integer(LPoint.Y));
end;

procedure TTestRadixLevelConverter.DovrebbeScrivereLeAzioniEITriggerCosiComeSono;
begin
  MakeRoom;
  FBuilder.AddAction([11, 22]);
  FBuilder.AddTrigger(1);
  Convert('E1M2');
  Assert.AreEqual<Integer>(SizeOf(TRadixLevelAction), Length(Lump('RACTION')));
  Assert.AreEqual<Integer>(SizeOf(TRadixLevelTrigger), Length(Lump('RTRIGGER')));
  Assert.AreEqual(11, Integer(PSmallInt(@Lump('RACTION')[RADIX_ACTION_HEADER_SIZE])^));
  Assert.AreEqual<Integer>(8 * SizeOf(TRadixDoomThingExtra), Length(Lump('RTHINGS')));
end;

procedure TTestRadixLevelConverter.DovrebbeScrivereLoScriptConGliIdDeiSettoriEDeiMuri;
var
  LText: string;
  LBytes: TBytes;
begin
  MakeRoom;
  Convert('E1M2');
  LBytes := Lump('RMAP');
  LText := TEncoding.ANSI.GetString(LBytes);
  Assert.IsTrue(LText.StartsWith('sectorid 0'#13#10'xmul 1'#13#10'xadd -32767'#13#10'ymul -1'#13#10'yadd 0'#13#10));
  Assert.IsTrue(LText.Contains('sectorflags ' + IntToStr(RSF_RADIXSECTOR) + #13#10));
  Assert.IsTrue(LText.Contains('wallid 0'#13#10'wallflags ' + IntToStr(RWF_SINGLESIDED or RWF_RADIXWALL) +
    #13#10'wallhitpoints 100'#13#10'walltrigger 0'#13#10#13#10));
end;

end.
