{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the levels (records made in memory)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Level;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Intf,
  DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf;

type
  /// <summary>
  ///   The level info record is built here byte by byte as the original reads it (offsets of
  ///   wres_loadLevelInfo), so each field has a test; the real levels are in TTestWarLevelParity
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarLevel = class(TObject)
  private
    function BaseRecord(const ATail: TBytes): TBytes;
    function Tail(const AUnits: TBytes; const ARoads: TBytes; const AWalls: TBytes): TBytes;
    function PlayerList(const AEntities, ARoads: TBytes): TBytes;
    function CustomRecord(const AGoldmines: TBytes; const ALists: TArray<TBytes>): TBytes;
    function MapRecord: TBytes;
    function Entry(AIndex: Integer; AType: TWarRecordType): TWarCatalogEntry;
    function Loader(AMapSize: Integer; AVisualField: Word): IWarLevelLoader;
    procedure PutWord(var ABytes: TBytes; AOffset: Integer; AValue: Word);
    procedure PutCardinal(var ABytes: TBytes; AOffset: Integer; AValue: Cardinal);
  public
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiRecordPacked;
    [Test]
    procedure DovrebbeLeggereLaMaschereDelleCaratteristiche;
    [Test]
    procedure DovrebbeLasciareASpentoLeMagieNonConsentite;
    [Test]
    procedure DovrebbeLeggereOroLegnaEPosizioneDiPartenza;
    [Test]
    procedure DovrebbeDareLaRazzaDelPrimoGiocatoreEQuellaOppostaAgliAltri;
    [Test]
    procedure DovrebbeSottrarreDueAgliIndiciEIgnorareZeroEFFFF;
    [Test]
    procedure DovrebbeLeggereIlTestoDegliObiettivi;
    [Test]
    procedure DovrebbeRifiutareGliObiettiviSenzaTerminatore;
    [Test]
    procedure DovrebbeRifiutareGliObiettiviTroppoLunghi;
    [Test]
    procedure DovrebbeLeggereLeUnitaDiPartenzaEL_OroDelleMiniere;
    [Test]
    procedure DovrebbeLeggereStradeEMuri;
    [Test]
    procedure DovrebbeRifiutareUnRecordTroncato;
    [Test]
    procedure DovrebbeRifiutarePiuDelMassimoDiUnita;
    [Test]
    procedure DovrebbeLeggereUnaMappaPersonalizzata;
    [Test]
    procedure DovrebbeTenereLeStradeDellUltimaChiamataInUnaMappaPersonalizzata;
    [Test]
    procedure DovrebbeRifiutareTroppePosizioniDiUnaMappaPersonalizzata;
    [Test]
    procedure DovrebbeLeggereUnaMappaDiTegole;
    [Test]
    procedure DovrebbeRifiutareUnaMappaCorta;
    [Test]
    procedure DovrebbeCaricareUnLivelloConLeSueMappe;
    [Test]
    procedure DovrebbeDareLeTegoleEIPassaggiDiUnaCella;
    [Test]
    procedure DovrebbeRifiutareUnaCellaFuoriDallaMappa;
    [Test]
    procedure DovrebbeElencareILivelliDelCatalogo;
    [Test]
    procedure DovrebbeRifiutareUnRecordCheNonEUnLivello;
    [Test]
    procedure DovrebbeRifiutareUnLivelloLaCuiMappaNonEUnaMappa;
    [Test]
    procedure DovrebbeRifiutareUnaMappaCortaNelCaricamento;
    [Test]
    procedure DovrebbeRifiutareUnArchivioNil;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneFuoriDalCatalogo;
  end;

implementation

uses
  DelphiDoom.War.Factory, DelphiDoom.War.Catalog, DelphiDoom.War.Level.InfoReader, DelphiDoom.War.Level.MapReader,
  DelphiDoom.War.Level.Factory, DelphiDoom.Tests.War.Builders;

const
  DYNAMIC_START = $E3;

{ TTestWarLevel }

procedure TTestWarLevel.PutWord(var ABytes: TBytes; AOffset: Integer; AValue: Word);
begin
  ABytes[AOffset] := Byte(AValue);
  ABytes[AOffset + 1] := Byte(AValue shr 8);
end;

procedure TTestWarLevel.PutCardinal(var ABytes: TBytes; AOffset: Integer; AValue: Cardinal);
begin
  PutWord(ABytes, AOffset, Word(AValue));
  PutWord(ABytes, AOffset + 2, Word(AValue shr 16));
end;

function TTestWarLevel.BaseRecord(const ATail: TBytes): TBytes;
var
  LMarker: Integer;
begin
  // the fixed part up to $E3, five filler bytes, the marker $FFFFFFFF, the offset of the units, then the tail
  LMarker := DYNAMIC_START + 5;
  SetLength(Result, LMarker + 4 + 2 + Length(ATail));
  PutWord(Result, LMarker + 4, LMarker + 6);
  PutCardinal(Result, LMarker, $FFFFFFFF);
  if Length(ATail) > 0 then
    Move(ATail[0], Result[LMarker + 6], Length(ATail));
end;

function TTestWarLevel.Tail(const AUnits, ARoads, AWalls: TBytes): TBytes;
begin
  // each list ends with $FFFF and the original skips two bytes after it
  Result := AUnits + TBytes.Create($FF, $FF) + ARoads + TBytes.Create($FF, $FF) + AWalls + TBytes.Create($FF, $FF);
end;

function TTestWarLevel.PlayerList(const AEntities, ARoads: TBytes): TBytes;
begin
  Result := AEntities + TBytes.Create($FF, $FF) + ARoads + TBytes.Create($FF, $FF);
end;

function TTestWarLevel.CustomRecord(const AGoldmines: TBytes; const ALists: TArray<TBytes>): TBytes;
var
  LHeader: Integer;
  LTable: Integer;
  LConfigurations: Integer;
  LList: Integer;
  LOffset: Integer;
  LPosition: Integer;
begin
  // at the offset of the units: [goldmines] FFFF { [player 0] [player 1] FFFF }* ; then the lists
  LConfigurations := Length(ALists) div 2;
  LHeader := Length(BaseRecord(nil));
  LTable := 4 + 6 * LConfigurations;
  Result := BaseRecord(nil);
  SetLength(Result, LHeader + LTable);
  LOffset := LHeader + LTable;
  PutWord(Result, LHeader, LOffset);
  PutWord(Result, LHeader + 2, $FFFF);
  Result := Result + AGoldmines + TBytes.Create($FF, $FF);
  Inc(LOffset, Length(AGoldmines) + 2);
  for LList := 0 to High(ALists) do
  begin
    LPosition := LHeader + 4 + (LList div 2) * 6 + (LList mod 2) * 2;
    PutWord(Result, LPosition, LOffset);
    if LList mod 2 = 1 then
      PutWord(Result, LPosition + 2, $FFFF);
    Result := Result + ALists[LList];
    Inc(LOffset, Length(ALists[LList]));
  end;
end;

function TTestWarLevel.MapRecord: TBytes;
var
  LCell: Integer;
begin
  SetLength(Result, WAR_LEVEL_MAP_BYTES);
  for LCell := 0 to WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1 do
    PutWord(Result, LCell * 2, Word(LCell * 3 + 1));
end;

function TTestWarLevel.Entry(AIndex: Integer; AType: TWarRecordType): TWarCatalogEntry;
begin
  Result := Default(TWarCatalogEntry);
  Result.Index := AIndex;
  Result.RecordType := AType;
end;

function TTestWarLevel.Loader(AMapSize: Integer; AVisualField: Word): IWarLevelLoader;
var
  LBuilder: TWarArchiveBuilder;
  LInfo: TBytes;
  LMap: TBytes;
begin
  // 0 level info (the maps are the records 1 and 2: the fields hold the number plus two), 3 a text
  LInfo := BaseRecord(Tail(nil, nil, nil));
  PutWord(LInfo, $D0, AVisualField);
  PutWord(LInfo, $D2, 4);
  LMap := MapRecord;
  SetLength(LMap, AMapSize);
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(LInfo);
    LBuilder.AddUncompressed(LMap);
    LBuilder.AddUncompressed(LMap);
    LBuilder.AddUncompressed(TBytes.Create(1, 2, 3));
    Result := TWarLevelFactory.CreateLevelLoader(
      TWarFactory.OpenStream(TBytesStream.Create(LBuilder.Build(WAR_ARCHIVE_ID_RETAIL_DOS)), True, nil),
      TWarCatalog.Create(TArray<TWarCatalogEntry>.Create(
        Entry(0, wrtLevelInfo), Entry(1, wrtLevelVisual), Entry(2, wrtLevelPassable), Entry(3, wrtText))));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestWarLevel.DovrebbeAvereLeDimensioniDeiRecordPacked;
begin
  Assert.AreEqual(7, SizeOf(TWarLevelUnit));
  Assert.AreEqual(6, SizeOf(TWarLevelConstruct));
end;

procedure TTestWarLevel.DovrebbeLeggereLaMaschereDelleCaratteristiche;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil));
  PutCardinal(LRaw, 0, $00000005 or (Cardinal(1) shl 21));
  LInfo := TWarLevelInfoReader.Read(LRaw, 7, 1, False);
  Assert.AreEqual(7, LInfo.Index);
  Assert.AreEqual(1, Integer(LInfo.TilesetType));
  Assert.IsFalse(LInfo.CustomMap);
  Assert.AreEqual(1, Integer(LInfo.AllowedFeatures[0]));
  Assert.AreEqual(0, Integer(LInfo.AllowedFeatures[1]));
  Assert.AreEqual(1, Integer(LInfo.AllowedFeatures[2]));
  Assert.AreEqual(1, Integer(LInfo.AllowedFeatures[21]));
  Assert.IsTrue(LInfo.AllowedHumanUnits and LInfo.AllowedOrcsUnits);
end;

procedure TTestWarLevel.DovrebbeLasciareASpentoLeMagieNonConsentite;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil));
  // the byte of every upgrade and player is 9; the spells 3..8 are read only if the mask allows them (bits 15..20)
  FillChar(LRaw[4], 50, 9);
  PutCardinal(LRaw, 0, Cardinal(1) shl (15 + (4 + 3) mod 6));
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.AreEqual(9, Integer(LInfo.AllowedUpgrades[0, 0]));
  Assert.AreEqual(9, Integer(LInfo.AllowedUpgrades[9, 4]));
  Assert.AreEqual(0, Integer(LInfo.AllowedUpgrades[3, 0]));
  Assert.AreEqual(9, Integer(LInfo.AllowedUpgrades[4, 2]));
  Assert.AreEqual(0, Integer(LInfo.AllowedUpgrades[8, 4]));
end;

procedure TTestWarLevel.DovrebbeLeggereOroLegnaEPosizioneDiPartenza;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
  LPlayer: Integer;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil));
  for LPlayer := 0 to 4 do
  begin
    PutCardinal(LRaw, $5C + LPlayer * 4, 100 + LPlayer);
    PutCardinal(LRaw, $70 + LPlayer * 4, 200 + LPlayer);
  end;
  PutWord(LRaw, $CC, 21);
  PutWord(LRaw, $CE, 40);
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.AreEqual<Cardinal>(104, LInfo.Lumber[4]);
  Assert.AreEqual<Cardinal>(202, LInfo.Gold[2]);
  Assert.AreEqual(10, Integer(LInfo.StartX));
  Assert.AreEqual(20, Integer(LInfo.StartY));
end;

procedure TTestWarLevel.DovrebbeDareLaRazzaDelPrimoGiocatoreEQuellaOppostaAgliAltri;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil));
  PutCardinal(LRaw, $84, 1 shl 16);
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.IsTrue(LInfo.Races[0] = wraHumans);
  Assert.IsTrue(LInfo.Races[3] = wraOrcs);
  Assert.IsTrue(LInfo.Races[4] = wraNeutral);
  PutCardinal(LRaw, $84, 1);
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.IsTrue(LInfo.Races[0] = wraOrcs);
  Assert.IsTrue(LInfo.Races[1] = wraHumans);
end;

procedure TTestWarLevel.DovrebbeSottrarreDueAgliIndiciEIgnorareZeroEFFFF;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil));
  PutWord(LRaw, $CA, 120);
  PutWord(LRaw, $D0, 0);
  PutWord(LRaw, $D2, $FFFF);
  PutWord(LRaw, $D4, 50);
  PutWord(LRaw, $D6, 51);
  PutWord(LRaw, $D8, 1);
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.AreEqual(118, Integer(LInfo.NextLevelIndex));
  Assert.AreEqual(0, Integer(LInfo.VisualIndex));
  Assert.AreEqual(0, Integer(LInfo.PassableIndex));
  Assert.AreEqual(48, Integer(LInfo.TilesetIndex));
  Assert.AreEqual(49, Integer(LInfo.TilesIndex));
  // 1 - 2 wraps to 65535 like the u16 of the original
  Assert.AreEqual($FFFF, Integer(LInfo.PaletteIndex));
end;

procedure TTestWarLevel.DovrebbeLeggereIlTestoDegliObiettivi;
var
  LRaw: TBytes;
  LText: TBytes;
  LInfo: TWarLevelInfo;
begin
  LText := WarBytesOf('Build'#10'6 farms') + TBytes.Create(0);
  LRaw := BaseRecord(Tail(nil, nil, nil)) + LText;
  PutWord(LRaw, $94, Length(LRaw) - Length(LText));
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.AreEqual(AnsiString('Build'#10'6 farms'), LInfo.Objectives);
end;

procedure TTestWarLevel.DovrebbeRifiutareGliObiettiviSenzaTerminatore;
var
  LRaw: TBytes;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil)) + WarBytesOf('abc');
  PutWord(LRaw, $94, Length(LRaw) - 3);
  Assert.WillRaise(
    procedure
    begin
      TWarLevelInfoReader.Read(LRaw, 0, 0, False);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeRifiutareGliObiettiviTroppoLunghi;
var
  LRaw: TBytes;
  LText: TBytes;
begin
  SetLength(LText, WAR_MAX_OBJECTIVES_LENGTH + 1);
  FillChar(LText[0], WAR_MAX_OBJECTIVES_LENGTH, Ord('x'));
  LRaw := BaseRecord(Tail(nil, nil, nil)) + LText;
  PutWord(LRaw, $94, Length(LRaw) - Length(LText));
  Assert.WillRaise(
    procedure
    begin
      TWarLevelInfoReader.Read(LRaw, 0, 0, False);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeLeggereLeUnitaDiPartenzaEL_OroDelleMiniere;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  // a footman at (10, 20) of the player 0; a gold mine at (30, 40) of the player 4 with 2500 gold
  LRaw := BaseRecord(Tail(
    TBytes.Create(20, 40, WAR_UNIT_FOOTMAN, 0, 60, 80, WAR_UNIT_GOLDMINE, 4, $C4, $09), nil, nil));
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.AreEqual<Integer>(2, Length(LInfo.StartEntities));
  Assert.AreEqual(10, Integer(LInfo.StartEntities[0].X));
  Assert.AreEqual(20, Integer(LInfo.StartEntities[0].Y));
  Assert.IsTrue(LInfo.StartEntities[0].ResourceKind = wrkNone);
  Assert.AreEqual(30, Integer(LInfo.StartEntities[1].X));
  Assert.AreEqual(Integer(WAR_UNIT_GOLDMINE), Integer(LInfo.StartEntities[1].UnitType));
  Assert.AreEqual(4, Integer(LInfo.StartEntities[1].Player));
  Assert.IsTrue(LInfo.StartEntities[1].ResourceKind = wrkGold);
  Assert.AreEqual(2500, Integer(LInfo.StartEntities[1].Amount));
end;

procedure TTestWarLevel.DovrebbeLeggereStradeEMuri;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  LRaw := BaseRecord(Tail(nil, TBytes.Create(2, 4, 12, 4, 0, 6, 6, 6, 20, 1), TBytes.Create(8, 8, 8, 16, 2)));
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, False);
  Assert.AreEqual<Integer>(2, Length(LInfo.StartRoads));
  Assert.IsTrue(LInfo.StartRoads[0].ConstructType = wctRoad);
  Assert.AreEqual(1, Integer(LInfo.StartRoads[0].X1));
  Assert.AreEqual(6, Integer(LInfo.StartRoads[0].X2));
  Assert.AreEqual(10, Integer(LInfo.StartRoads[1].Y2));
  Assert.AreEqual(1, Integer(LInfo.StartRoads[1].Player));
  Assert.AreEqual<Integer>(1, Length(LInfo.StartWalls));
  Assert.IsTrue(LInfo.StartWalls[0].ConstructType = wctWall);
  Assert.AreEqual(8, Integer(LInfo.StartWalls[0].Y2));
  Assert.AreEqual(2, Integer(LInfo.StartWalls[0].Player));
end;

procedure TTestWarLevel.DovrebbeRifiutareUnRecordTroncato;
var
  LRaw: TBytes;
begin
  LRaw := BaseRecord(Tail(nil, nil, nil));
  SetLength(LRaw, 100);
  Assert.WillRaise(
    procedure
    begin
      TWarLevelInfoReader.Read(LRaw, 0, 0, False);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeRifiutarePiuDelMassimoDiUnita;
var
  LUnits: TBytes;
  LRaw: TBytes;
  LIndex: Integer;
begin
  SetLength(LUnits, (WAR_MAX_ENTITIES_COUNT + 1) * 4);
  for LIndex := 0 to WAR_MAX_ENTITIES_COUNT do
    LUnits[LIndex * 4] := 2;
  LRaw := BaseRecord(Tail(LUnits, nil, nil));
  Assert.WillRaise(
    procedure
    begin
      TWarLevelInfoReader.Read(LRaw, 0, 0, False);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeLeggereUnaMappaPersonalizzata;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  // two positions; each player of each one has a unit and the second player of the second one a road
  LRaw := CustomRecord(TBytes.Create(12, 16, WAR_UNIT_GOLDMINE, 0), TArray<TBytes>.Create(
    PlayerList(TBytes.Create(8, 8, WAR_UNIT_TOWNHALL_HUMANS, 0), nil),
    PlayerList(TBytes.Create(40, 40, WAR_UNIT_TOWNHALL_ORCS, 0, 42, 40, WAR_UNIT_FARM_ORCS, 0), nil),
    PlayerList(TBytes.Create(20, 20, WAR_UNIT_TOWNHALL_HUMANS, 0), nil),
    PlayerList(TBytes.Create(60, 60, WAR_UNIT_TOWNHALL_ORCS, 0), nil)));
  LInfo := TWarLevelInfoReader.Read(LRaw, 5, 2, True);
  Assert.IsTrue(LInfo.CustomMap);
  Assert.AreEqual<Integer>(1, Length(LInfo.StartGoldmines));
  Assert.AreEqual(6, Integer(LInfo.StartGoldmines[0].X));
  Assert.AreEqual(8, Integer(LInfo.StartGoldmines[0].Y));
  Assert.AreEqual(4, Integer(LInfo.StartGoldmines[0].Player));
  Assert.AreEqual<Integer>(2, Length(LInfo.StartConfigurations));
  // the original allocates a new array for each player and keeps counting: the unit of the first player is lost
  // (a zero unit stays in its place) and the two of the second follow
  Assert.AreEqual<Integer>(3, Length(LInfo.StartConfigurations[0].StartEntities));
  Assert.AreEqual(0, Integer(LInfo.StartConfigurations[0].StartEntities[0].X));
  Assert.AreEqual(0, Integer(LInfo.StartConfigurations[0].StartEntities[0].UnitType));
  Assert.AreEqual(1, Integer(LInfo.StartConfigurations[0].StartEntities[1].Player));
  Assert.AreEqual(20, Integer(LInfo.StartConfigurations[0].StartEntities[1].X));
  Assert.AreEqual(Integer(WAR_UNIT_FARM_ORCS), Integer(LInfo.StartConfigurations[0].StartEntities[2].UnitType));
  Assert.AreEqual<Integer>(2, Length(LInfo.StartConfigurations[1].StartEntities));
  Assert.AreEqual<Integer>(0, Length(LInfo.StartEntities));
  Assert.AreEqual<Integer>(0, Length(LInfo.StartWalls));
end;

procedure TTestWarLevel.DovrebbeTenereLeStradeDellUltimaChiamataInUnaMappaPersonalizzata;
var
  LRaw: TBytes;
  LInfo: TWarLevelInfo;
begin
  // a road in the first list of the first position, one in the last list of the last: the original replaced the
  // array of roads at every call, so only the last (here, from the second position, second player) is left
  LRaw := CustomRecord(nil, TArray<TBytes>.Create(
    PlayerList(nil, TBytes.Create(2, 2, 4, 2, 0)),
    PlayerList(nil, nil),
    PlayerList(nil, nil),
    PlayerList(nil, TBytes.Create(14, 14, 16, 14, 1))));
  LInfo := TWarLevelInfoReader.Read(LRaw, 0, 0, True);
  Assert.AreEqual<Integer>(1, Length(LInfo.StartRoads));
  Assert.AreEqual(7, Integer(LInfo.StartRoads[0].X1));
  Assert.AreEqual(1, Integer(LInfo.StartRoads[0].Player));
end;

procedure TTestWarLevel.DovrebbeRifiutareTroppePosizioniDiUnaMappaPersonalizzata;
var
  LRaw: TBytes;
  LLists: TArray<TBytes>;
  LIndex: Integer;
begin
  SetLength(LLists, (WAR_MAX_CUSTOM_CONFIGURATIONS_COUNT + 1) * 2);
  for LIndex := 0 to High(LLists) do
    LLists[LIndex] := PlayerList(nil, nil);
  LRaw := CustomRecord(nil, LLists);
  Assert.WillRaise(
    procedure
    begin
      TWarLevelInfoReader.Read(LRaw, 0, 0, True);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeLeggereUnaMappaDiTegole;
var
  LCells: TArray<Word>;
begin
  LCells := TWarLevelMapReader.Read(MapRecord);
  Assert.AreEqual<Integer>(4096, Length(LCells));
  Assert.AreEqual(1, Integer(LCells[0]));
  Assert.AreEqual(4, Integer(LCells[1]));
  Assert.AreEqual(Integer(Word(4095 * 3 + 1)), Integer(LCells[4095]));
end;

procedure TTestWarLevel.DovrebbeRifiutareUnaMappaCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarLevelMapReader.Read(TBytes.Create(1, 2, 3));
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeCaricareUnLivelloConLeSueMappe;
var
  LLevel: IWarLevel;
begin
  LLevel := Loader(WAR_LEVEL_MAP_BYTES, 3).Load(0);
  Assert.AreEqual(0, LLevel.Info.Index);
  Assert.AreEqual(1, Integer(LLevel.Info.VisualIndex));
  Assert.AreEqual(2, Integer(LLevel.Info.PassableIndex));
  Assert.AreEqual<Integer>(4096, Length(LLevel.Visual));
  Assert.AreEqual<Integer>(4096, Length(LLevel.Passable));
end;

procedure TTestWarLevel.DovrebbeDareLeTegoleEIPassaggiDiUnaCella;
var
  LLevel: IWarLevel;
begin
  LLevel := Loader(WAR_LEVEL_MAP_BYTES, 3).Load(0);
  Assert.AreEqual(4, Integer(LLevel.VisualAt(1, 0)));
  Assert.AreEqual(Integer(Word((64 + 2) * 3 + 1)), Integer(LLevel.PassableAt(2, 1)));
end;

procedure TTestWarLevel.DovrebbeRifiutareUnaCellaFuoriDallaMappa;
var
  LLevel: IWarLevel;
begin
  LLevel := Loader(WAR_LEVEL_MAP_BYTES, 3).Load(0);
  Assert.WillRaise(
    procedure
    begin
      LLevel.VisualAt(64, 0);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LLevel.PassableAt(0, -1);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeElencareILivelliDelCatalogo;
var
  LLoader: IWarLevelLoader;
begin
  LLoader := Loader(WAR_LEVEL_MAP_BYTES, 3);
  Assert.AreEqual(1, LLoader.LevelCount);
  Assert.AreEqual(0, LLoader.GetLevelIndex(0));
  Assert.IsTrue(LLoader.IsLevel(0));
  Assert.IsFalse(LLoader.IsLevel(3));
  Assert.IsFalse(LLoader.IsLevel(99));
  Assert.IsFalse(LLoader.IsLevel(-1));
end;

procedure TTestWarLevel.DovrebbeRifiutareUnRecordCheNonEUnLivello;
var
  LLoader: IWarLevelLoader;
begin
  LLoader := Loader(WAR_LEVEL_MAP_BYTES, 3);
  Assert.WillRaise(
    procedure
    begin
      LLoader.LoadInfo(3);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LLoader.Load(1);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeRifiutareUnLivelloLaCuiMappaNonEUnaMappa;
var
  LLoader: IWarLevelLoader;
begin
  // the visual field points at the record 3, a text
  LLoader := Loader(WAR_LEVEL_MAP_BYTES, 5);
  Assert.WillRaise(
    procedure
    begin
      LLoader.Load(0);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeRifiutareUnaMappaCortaNelCaricamento;
var
  LLoader: IWarLevelLoader;
begin
  LLoader := Loader(100, 3);
  Assert.WillRaise(
    procedure
    begin
      LLoader.Load(0);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeRifiutareUnArchivioNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarLevelFactory.CreateLevelLoader(nil, TWarFactory.CreateCatalog);
    end, EWarException);
end;

procedure TTestWarLevel.DovrebbeRifiutareUnaPosizioneFuoriDalCatalogo;
var
  LLoader: IWarLevelLoader;
begin
  LLoader := Loader(WAR_LEVEL_MAP_BYTES, 3);
  Assert.WillRaise(
    procedure
    begin
      LLoader.GetLevelIndex(1);
    end, EWarException);
end;

end.
