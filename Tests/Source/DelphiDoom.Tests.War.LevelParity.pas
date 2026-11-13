{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the levels with the C of   }
{  the remake on the real DATA.WAR                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.LevelParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Intf,
  DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf, DelphiDoom.MathCore.Crc32, DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   levels.golden.txt is the output of war_lvl_ref.exe: wres_loadLevelInfo, wres_loadLevelVisual and
  ///   wres_loadLevelPassable ORIGINAL of war_resources.c of war1, extracted as they are, compiled with gcc and run
  ///   on DATA.WAR in the order of the table (Tools\Verifica\193). Per level info: its fields (L), the features (F),
  ///   the upgrades (U), gold, lumber and races (R), the objectives (O) and the CRC-32 of the units (E), roads (D),
  ///   walls (W), gold mines (G) and of each starting position of a custom map (K); per map record the CRC-32 of its
  ///   8192 bytes (V visual, A passable)
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarLevelParity = class(TObject)
  private
    function Checksum(const ABytes: TBytes): string;
    function UnitsChecksum(const AUnits: TArray<TWarLevelUnit>): string;
    function ConstructsChecksum(const AConstructs: TArray<TWarLevelConstruct>): string;
    function MapChecksum(const ACells: TArray<Word>): string;
    function InfoLines(const AInfo: TWarLevelInfo): TArray<string>;
    function Listing(const AArchive: IWarArchive; const ACatalog: IWarCatalog): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseImprontedelCodiceOriginaleSuTuttiILivelli;
    [Test]
    procedure DovrebbeLeggere66LivelliCon36MappeVisiveE36Percorribili;
    [Test]
    procedure DovrebbeCaricareOgniLivelloConLeSueMappe;
    [Test]
    procedure DovrebbeAvereDaUnoASeiPosizioniInOgniMappaPersonalizzata;
    [Test]
    procedure DovrebbeDareIlNumeroDelTipoDiMappaComeIndiceDelRecord;
  end;

implementation

uses
  DelphiDoom.War.Factory, DelphiDoom.War.Level.Factory, DelphiDoom.War.Level.MapReader, DelphiDoom.War.Campaign.Types;

{ TTestWarLevelParity }

function TTestWarLevelParity.Checksum(const ABytes: TBytes): string;
var
  LCrc: TCrc32;
begin
  LCrc := TCrc32.Create;
  try
    if Length(ABytes) > 0 then
      LCrc.Update(ABytes[0], Length(ABytes));
    Result := LowerCase(TCrc32.ToHex(LCrc.Value));
  finally
    LCrc.Free;
  end;
end;

function TTestWarLevelParity.UnitsChecksum(const AUnits: TArray<TWarLevelUnit>): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AUnits) * SizeOf(TWarLevelUnit));
  for LIndex := 0 to High(AUnits) do
    Move(AUnits[LIndex], LBytes[LIndex * SizeOf(TWarLevelUnit)], SizeOf(TWarLevelUnit));
  Result := Checksum(LBytes);
end;

function TTestWarLevelParity.ConstructsChecksum(const AConstructs: TArray<TWarLevelConstruct>): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AConstructs) * SizeOf(TWarLevelConstruct));
  for LIndex := 0 to High(AConstructs) do
    Move(AConstructs[LIndex], LBytes[LIndex * SizeOf(TWarLevelConstruct)], SizeOf(TWarLevelConstruct));
  Result := Checksum(LBytes);
end;

function TTestWarLevelParity.MapChecksum(const ACells: TArray<Word>): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(ACells) * 2);
  for LIndex := 0 to High(ACells) do
  begin
    LBytes[LIndex * 2] := Byte(ACells[LIndex]);
    LBytes[LIndex * 2 + 1] := Byte(ACells[LIndex] shr 8);
  end;
  Result := Checksum(LBytes);
end;

function TTestWarLevelParity.InfoLines(const AInfo: TWarLevelInfo): TArray<string>;
var
  LIndex: Integer;
  LLine: string;
  LBytes: TBytes;
  LConfiguration: TWarCustomMapConfiguration;
  LObjectives: AnsiString;
begin
  SetLength(Result, 10);
  Result[0] := Format('L %d %d %d %s %d %d %d %d %d %d %d %d', [AInfo.Index, AInfo.TilesetType, Ord(AInfo.CustomMap),
    LowerCase(IntToHex(AInfo.AllowId, 8)), AInfo.StartX, AInfo.StartY, AInfo.NextLevelIndex, AInfo.VisualIndex,
    AInfo.PassableIndex, AInfo.PaletteIndex, AInfo.TilesIndex, AInfo.TilesetIndex]);
  SetLength(LBytes, WAR_MAX_FEATURES_COUNT);
  Move(AInfo.AllowedFeatures[0], LBytes[0], WAR_MAX_FEATURES_COUNT);
  Result[1] := Format('F %d %d %d %s', [AInfo.Index, Ord(AInfo.AllowedHumanUnits), Ord(AInfo.AllowedOrcsUnits),
    Checksum(LBytes)]);
  SetLength(LBytes, WAR_MAX_UPGRADES_COUNT * WAR_MAX_PLAYERS_COUNT);
  Move(AInfo.AllowedUpgrades[0, 0], LBytes[0], Length(LBytes));
  Result[2] := Format('U %d %s', [AInfo.Index, Checksum(LBytes)]);
  LLine := Format('R %d', [AInfo.Index]);
  for LIndex := 0 to 4 do
    LLine := LLine + ' ' + UIntToStr(AInfo.Lumber[LIndex]);
  for LIndex := 0 to 4 do
    LLine := LLine + ' ' + UIntToStr(AInfo.Gold[LIndex]);
  for LIndex := 0 to 4 do
    LLine := LLine + ' ' + IntToStr(Ord(AInfo.Races[LIndex]));
  Result[3] := LLine;
  LObjectives := AInfo.Objectives;
  SetLength(LBytes, Length(LObjectives));
  if Length(LObjectives) > 0 then
    Move(LObjectives[1], LBytes[0], Length(LObjectives));
  Result[4] := Format('O %d %d %s', [AInfo.Index, Length(LObjectives), Checksum(LBytes)]);
  Result[5] := Format('E %d %d %s', [AInfo.Index, Length(AInfo.StartEntities), UnitsChecksum(AInfo.StartEntities)]);
  Result[6] := Format('D %d %d %s', [AInfo.Index, Length(AInfo.StartRoads), ConstructsChecksum(AInfo.StartRoads)]);
  Result[7] := Format('W %d %d %s', [AInfo.Index, Length(AInfo.StartWalls), ConstructsChecksum(AInfo.StartWalls)]);
  Result[8] := Format('G %d %d %s', [AInfo.Index, Length(AInfo.StartGoldmines), UnitsChecksum(AInfo.StartGoldmines)]);
  LLine := Format('K %d %d', [AInfo.Index, Length(AInfo.StartConfigurations)]);
  for LConfiguration in AInfo.StartConfigurations do
    LLine := LLine + Format(' %d:%s', [Length(LConfiguration.StartEntities), UnitsChecksum(LConfiguration.StartEntities)]);
  Result[9] := LLine;
end;

function TTestWarLevelParity.Listing(const AArchive: IWarArchive; const ACatalog: IWarCatalog): TStringList;
var
  LLoader: IWarLevelLoader;
  LPosition: Integer;
  LEntry: TWarCatalogEntry;
  LLine: string;
begin
  Result := TStringList.Create;
  LLoader := TWarLevelFactory.CreateLevelLoader(AArchive, ACatalog);
  for LPosition := 0 to ACatalog.Count - 1 do
  begin
    LEntry := ACatalog.GetEntry(LPosition);
    case LEntry.RecordType of
      wrtLevelInfo:
        for LLine in InfoLines(LLoader.LoadInfo(LEntry.Index)) do
          Result.Add(LLine);
      wrtLevelVisual:
        Result.Add(Format('V %d %s', [LEntry.Index, MapChecksum(TWarLevelMapReader.Read(AArchive.ReadRecord(LEntry.Index)))]));
      wrtLevelPassable:
        Result.Add(Format('A %d %s', [LEntry.Index, MapChecksum(TWarLevelMapReader.Read(AArchive.ReadRecord(LEntry.Index)))]));
    end;
  end;
end;

procedure TTestWarLevelParity.DovrebbeDareLeStesseImprontedelCodiceOriginaleSuTuttiILivelli;
var
  LCatalog: IWarCatalog;
  LGolden: TStringList;
  LActual: TStringList;
  LIndex: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('levels.golden.txt'));
    LActual := Listing(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
    try
      Assert.AreEqual(LGolden.Count, LActual.Count);
      for LIndex := 0 to LGolden.Count - 1 do
        Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
    finally
      LActual.Free;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarLevelParity.DovrebbeLeggere66LivelliCon36MappeVisiveE36Percorribili;
var
  LCatalog: IWarCatalog;
  LActual: TStringList;
  LLine: string;
  LLevels: Integer;
  LVisual: Integer;
  LPassable: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LActual := Listing(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  try
    LLevels := 0;
    LVisual := 0;
    LPassable := 0;
    for LLine in LActual do
    begin
      if LLine.StartsWith('L ') then
        Inc(LLevels)
      else if LLine.StartsWith('V ') then
        Inc(LVisual)
      else if LLine.StartsWith('A ') then
        Inc(LPassable);
    end;
    // the levels share their maps: 66 levels, 36 visual and 36 passable records
    Assert.AreEqual(66, LLevels);
    Assert.AreEqual(36, LVisual);
    Assert.AreEqual(36, LPassable);
  finally
    LActual.Free;
  end;
end;

procedure TTestWarLevelParity.DovrebbeCaricareOgniLivelloConLeSueMappe;
var
  LCatalog: IWarCatalog;
  LLoader: IWarLevelLoader;
  LPosition: Integer;
  LLevel: IWarLevel;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LLoader := TWarLevelFactory.CreateLevelLoader(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  Assert.AreEqual(66, LLoader.LevelCount);
  for LPosition := 0 to LLoader.LevelCount - 1 do
  begin
    LLevel := LLoader.Load(LLoader.GetLevelIndex(LPosition));
    Assert.AreEqual(4096, Length(LLevel.Visual), 'visuale del livello ' + IntToStr(LLoader.GetLevelIndex(LPosition)));
    Assert.AreEqual(4096, Length(LLevel.Passable));
  end;
end;

procedure TTestWarLevelParity.DovrebbeAvereDaUnoASeiPosizioniInOgniMappaPersonalizzata;
var
  LCatalog: IWarCatalog;
  LLoader: IWarLevelLoader;
  LPosition: Integer;
  LInfo: TWarLevelInfo;
  LCustom: Integer;
  LPositions: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LLoader := TWarLevelFactory.CreateLevelLoader(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  LCustom := 0;
  LPositions := 0;
  for LPosition := 0 to LLoader.LevelCount - 1 do
  begin
    LInfo := LLoader.LoadInfo(LLoader.GetLevelIndex(LPosition));
    if LInfo.CustomMap then
    begin
      Inc(LCustom);
      Assert.IsTrue(Length(LInfo.StartConfigurations) in [1..6]);
      Inc(LPositions, Length(LInfo.StartConfigurations));
    end;
  end;
  Assert.AreEqual(42, LCustom);
  // 7 maps with 1 position, 5 with 2, 7 with 3, 9 with 4 and 14 with 6 (the golden)
  Assert.AreEqual(158, LPositions);
end;

procedure TTestWarLevelParity.DovrebbeDareIlNumeroDelTipoDiMappaComeIndiceDelRecord;
var
  LCatalog: IWarCatalog;
  LLoader: IWarLevelLoader;
  LIndex: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LLoader := TWarLevelFactory.CreateLevelLoader(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  for LIndex := WAR_CAMPAIGN_HUMANS_01 to WAR_CAMPAIGN_ORCS_12 do
    Assert.IsTrue(LLoader.IsLevel(LIndex), 'livello ' + IntToStr(LIndex));
end;

end.
