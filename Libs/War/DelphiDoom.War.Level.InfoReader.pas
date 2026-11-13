{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the level info record                             }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadLevelInfo and the wres_loadStart*     }
{  functions of war_resources.c, (c) 2019 Alejandro Coto Gutierrez, zlib       }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.InfoReader;

// Word(x - 2) wraps like the u16 of the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types;

type
  /// <summary>
  ///   Reads a level info record: the mask of what is allowed, the upgrades, the gold and lumber, the races,
  ///   the objectives text, the indices of the records of the level and the starting units, roads, walls and
  ///   (for a custom map) gold mines and starting positions. The original read past the record for bad data
  ///   and overflowed its arrays; here that is EWarException
  /// </summary>
  TWarLevelInfoReader = class
  strict private
    class function ReadByte(const ARaw: TBytes; AOffset: Integer): Byte; static;
    class function IndexOf(AValue: Word): Word; static;
    class function LoadStartEntities(const ARaw: TBytes; AOffset: Integer;
      out AUnits: TArray<TWarLevelUnit>): Integer; static;
    class function LoadConstructs(const ARaw: TBytes; AOffset: Integer; AType: TWarConstructType;
      out AConstructs: TArray<TWarLevelConstruct>): Integer; static;
    class function LoadCustomGoldmines(const ARaw: TBytes; AOffset: Integer;
      out AUnits: TArray<TWarLevelUnit>): Integer; static;
    class function LoadCustomEntities(const ARaw: TBytes; AOffset: Integer; APlayer: Byte;
      var AConfiguration: TWarCustomMapConfiguration): Integer; static;
    class function ReadObjectives(const ARaw: TBytes; AOffset: Integer): AnsiString; static;
  public
    /// <param name="ARaw">The bytes of the record</param>
    /// <param name="AIndex">The index of the record in the archive</param>
    /// <param name="ATilesetType">Param1 of the catalog entry</param>
    /// <param name="ACustomMap">Param2 of the catalog entry</param>
    class function Read(const ARaw: TBytes; AIndex: Integer; ATilesetType: Word;
      ACustomMap: Boolean): TWarLevelInfo; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.LittleEndian;

{ TWarLevelInfoReader }

class function TWarLevelInfoReader.ReadByte(const ARaw: TBytes; AOffset: Integer): Byte;
begin
  if (AOffset < 0) or (AOffset >= Length(ARaw)) then
    raise EWarException.CreateFmt(SWarReadPastEnd, [1, AOffset, Length(ARaw)]);
  Result := ARaw[AOffset];
end;

class function TWarLevelInfoReader.IndexOf(AValue: Word): Word;
begin
  // an index of the file is the number of the record plus two; 0 and $FFFF mean "none" (left at 0)
  if (AValue <> 0) and (AValue <> $FFFF) then
    Result := Word(AValue - 2)
  else
    Result := 0;
end;

class function TWarLevelInfoReader.LoadStartEntities(const ARaw: TBytes; AOffset: Integer;
  out AUnits: TArray<TWarLevelUnit>): Integer;
var
  LCount: Integer;
  LUnit: TWarLevelUnit;
begin
  // wres_loadStartEntities
  SetLength(AUnits, 0);
  LCount := 0;
  while AOffset < Length(ARaw) do
  begin
    if TWarLittleEndian.ReadWord(ARaw, AOffset) = $FFFF then
      Break;
    if LCount >= WAR_MAX_ENTITIES_COUNT then
      raise EWarException.CreateFmt(SWarLevelTooMany, [WAR_MAX_ENTITIES_COUNT, 'units']);
    LUnit := Default(TWarLevelUnit);
    LUnit.X := ReadByte(ARaw, AOffset) div 2;
    LUnit.Y := ReadByte(ARaw, AOffset + 1) div 2;
    LUnit.UnitType := ReadByte(ARaw, AOffset + 2);
    LUnit.Player := ReadByte(ARaw, AOffset + 3);
    Inc(AOffset, 4);
    if LUnit.UnitType = WAR_UNIT_GOLDMINE then
    begin
      LUnit.ResourceKind := wrkGold;
      LUnit.Amount := TWarLittleEndian.ReadWord(ARaw, AOffset);
      Inc(AOffset, 2);
    end;
    SetLength(AUnits, LCount + 1);
    AUnits[LCount] := LUnit;
    Inc(LCount);
  end;
  Result := AOffset;
end;

class function TWarLevelInfoReader.LoadConstructs(const ARaw: TBytes; AOffset: Integer; AType: TWarConstructType;
  out AConstructs: TArray<TWarLevelConstruct>): Integer;
var
  LCount: Integer;
  LConstruct: TWarLevelConstruct;
begin
  // wres_loadStartRoads and wres_loadStartWalls, the same but for the type
  SetLength(AConstructs, 0);
  LCount := 0;
  while AOffset < Length(ARaw) do
  begin
    if TWarLittleEndian.ReadWord(ARaw, AOffset) = $FFFF then
      Break;
    if LCount >= WAR_MAX_CONSTRUCTS_COUNT then
      raise EWarException.CreateFmt(SWarLevelTooMany, [WAR_MAX_CONSTRUCTS_COUNT, 'roads or walls']);
    LConstruct.ConstructType := AType;
    LConstruct.X1 := ReadByte(ARaw, AOffset) div 2;
    LConstruct.Y1 := ReadByte(ARaw, AOffset + 1) div 2;
    LConstruct.X2 := ReadByte(ARaw, AOffset + 2) div 2;
    LConstruct.Y2 := ReadByte(ARaw, AOffset + 3) div 2;
    LConstruct.Player := ReadByte(ARaw, AOffset + 4);
    Inc(AOffset, 5);
    SetLength(AConstructs, LCount + 1);
    AConstructs[LCount] := LConstruct;
    Inc(LCount);
  end;
  Result := AOffset;
end;

class function TWarLevelInfoReader.LoadCustomGoldmines(const ARaw: TBytes; AOffset: Integer;
  out AUnits: TArray<TWarLevelUnit>): Integer;
var
  LCount: Integer;
  LUnit: TWarLevelUnit;
begin
  // wres_loadCustomStartGoldmines: no amount in the record, the owner is the neutral player 4
  SetLength(AUnits, 0);
  LCount := 0;
  while AOffset < Length(ARaw) do
  begin
    if TWarLittleEndian.ReadWord(ARaw, AOffset) = $FFFF then
      Break;
    if LCount >= WAR_MAX_CUSTOM_GOLDMINES_COUNT then
      raise EWarException.CreateFmt(SWarLevelTooMany, [WAR_MAX_CUSTOM_GOLDMINES_COUNT, 'gold mines']);
    LUnit := Default(TWarLevelUnit);
    LUnit.X := ReadByte(ARaw, AOffset) div 2;
    LUnit.Y := ReadByte(ARaw, AOffset + 1) div 2;
    LUnit.UnitType := WAR_UNIT_GOLDMINE;
    LUnit.Player := 4;
    Inc(AOffset, 4);
    SetLength(AUnits, LCount + 1);
    AUnits[LCount] := LUnit;
    Inc(LCount);
  end;
  Result := AOffset;
end;

class function TWarLevelInfoReader.LoadCustomEntities(const ARaw: TBytes; AOffset: Integer; APlayer: Byte;
  var AConfiguration: TWarCustomMapConfiguration): Integer;
var
  LCount: Integer;
  LUnit: TWarLevelUnit;
begin
  // wres_loadCustomStartEntities: the original allocates a NEW zeroed array at each call and goes on counting from
  // the count of the previous one, so after the second player the units of the first are zero units (all fields 0)
  // and the count is the sum. Kept: the data are the ones of the game and the parity depends on it
  LCount := Length(AConfiguration.StartEntities);
  AConfiguration.StartEntities := nil;
  SetLength(AConfiguration.StartEntities, LCount);
  while AOffset < Length(ARaw) do
  begin
    if TWarLittleEndian.ReadWord(ARaw, AOffset) = $FFFF then
      Break;
    if LCount >= WAR_MAX_CUSTOM_ENTITIES_COUNT then
      raise EWarException.CreateFmt(SWarLevelTooMany, [WAR_MAX_CUSTOM_ENTITIES_COUNT, 'units']);
    LUnit := Default(TWarLevelUnit);
    LUnit.X := ReadByte(ARaw, AOffset) div 2;
    LUnit.Y := ReadByte(ARaw, AOffset + 1) div 2;
    LUnit.UnitType := ReadByte(ARaw, AOffset + 2);
    LUnit.Player := APlayer;
    Inc(AOffset, 4);
    SetLength(AConfiguration.StartEntities, LCount + 1);
    AConfiguration.StartEntities[LCount] := LUnit;
    Inc(LCount);
  end;
  Result := AOffset;
end;

class function TWarLevelInfoReader.ReadObjectives(const ARaw: TBytes; AOffset: Integer): AnsiString;
var
  LEnd: Integer;
begin
  // strcpy into a buffer of MAX_OBJECTIVES_LENGTH: no terminator or too long was a read or a write past the buffer
  LEnd := AOffset;
  while (LEnd < Length(ARaw)) and (ARaw[LEnd] <> 0) do
    Inc(LEnd);
  if (AOffset < 0) or (LEnd >= Length(ARaw)) or (LEnd - AOffset >= WAR_MAX_OBJECTIVES_LENGTH) then
    raise EWarException.CreateFmt(SWarLevelObjectivesTooLong, [WAR_MAX_OBJECTIVES_LENGTH - 1]);
  SetString(Result, PAnsiChar(@ARaw[AOffset]), LEnd - AOffset);
end;

class function TWarLevelInfoReader.Read(const ARaw: TBytes; AIndex: Integer; ATilesetType: Word;
  ACustomMap: Boolean): TWarLevelInfo;
var
  LFeature: Integer;
  LUpgrade: Integer;
  LPlayer: Integer;
  LAllowed: Boolean;
  LRace: Cardinal;
  LOffset: Integer;
  LGoldminesOffset: Integer;
  LOffset0: Integer;
  LOffset1: Integer;
  LConfiguration: TWarCustomMapConfiguration;
  LObjectivesOffset: Integer;
begin
  Result := Default(TWarLevelInfo);
  Result.Index := AIndex;
  Result.TilesetType := ATilesetType;
  Result.CustomMap := ACustomMap;
  Result.AllowId := TWarLittleEndian.ReadCardinal(ARaw, 0);
  Result.AllowedHumanUnits := True;
  Result.AllowedOrcsUnits := True;

  for LFeature := 0 to WAR_MAX_FEATURES_COUNT - 1 do
    if (Result.AllowId and (Cardinal(1) shl LFeature)) <> 0 then
      Result.AllowedFeatures[LFeature] := 1;

  for LUpgrade := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
  begin
    LAllowed := True;
    if (LUpgrade >= 3) and (LUpgrade <= 8) then
      // a spell is researchable only if the level allows it; the spells are in the mask from the feature 15,
      // in another order than in the list of upgrades
      LAllowed := Result.AllowedFeatures[15 + (LUpgrade + 3) mod 6] > 0;
    if LAllowed then
      for LPlayer := 0 to 4 do
        Result.AllowedUpgrades[LUpgrade, LPlayer] := ReadByte(ARaw, 4 + LUpgrade * 5 + LPlayer);
  end;

  for LPlayer := 0 to 4 do
  begin
    Result.Lumber[LPlayer] := TWarLittleEndian.ReadCardinal(ARaw, $5C + LPlayer * 4);
    Result.Gold[LPlayer] := TWarLittleEndian.ReadCardinal(ARaw, $70 + LPlayer * 4);
  end;

  Result.StartX := TWarLittleEndian.ReadWord(ARaw, $CC) div 2;
  Result.StartY := TWarLittleEndian.ReadWord(ARaw, $CE) div 2;

  LRace := TWarLittleEndian.ReadCardinal(ARaw, $84);
  if LRace >= (Cardinal(1) shl 16) then
    Result.Races[0] := wraHumans
  else
    Result.Races[0] := wraOrcs;
  for LPlayer := 1 to 3 do
    if Result.Races[0] = wraHumans then
      Result.Races[LPlayer] := wraOrcs
    else
      Result.Races[LPlayer] := wraHumans;

  LObjectivesOffset := TWarLittleEndian.ReadWord(ARaw, $94);
  if LObjectivesOffset <> 0 then
    Result.Objectives := ReadObjectives(ARaw, LObjectivesOffset);

  Result.NextLevelIndex := IndexOf(TWarLittleEndian.ReadWord(ARaw, $CA));
  Result.VisualIndex := IndexOf(TWarLittleEndian.ReadWord(ARaw, $D0));
  Result.PassableIndex := IndexOf(TWarLittleEndian.ReadWord(ARaw, $D2));
  Result.TilesetIndex := IndexOf(TWarLittleEndian.ReadWord(ARaw, $D4));
  Result.TilesIndex := IndexOf(TWarLittleEndian.ReadWord(ARaw, $D6));
  Result.PaletteIndex := IndexOf(TWarLittleEndian.ReadWord(ARaw, $D8));

  // the dynamic data start at $E3 and end at four $FF bytes; then the marker and the offset of the units
  LOffset := $E3;
  while TWarLittleEndian.ReadCardinal(ARaw, LOffset) <> $FFFFFFFF do
    Inc(LOffset);
  Inc(LOffset, 4);
  LOffset := TWarLittleEndian.ReadWord(ARaw, LOffset);

  if ACustomMap then
  begin
    LGoldminesOffset := TWarLittleEndian.ReadWord(ARaw, LOffset);
    LoadCustomGoldmines(ARaw, LGoldminesOffset, Result.StartGoldmines);
    Inc(LOffset, 2);
    Inc(LOffset, 2); // marker
    while LOffset < LGoldminesOffset do
    begin
      if Length(Result.StartConfigurations) >= WAR_MAX_CUSTOM_CONFIGURATIONS_COUNT then
        raise EWarException.CreateFmt(SWarLevelTooMany, [WAR_MAX_CUSTOM_CONFIGURATIONS_COUNT, 'starting positions']);
      LConfiguration := Default(TWarCustomMapConfiguration);

      LOffset0 := TWarLittleEndian.ReadWord(ARaw, LOffset);
      LOffset0 := LoadCustomEntities(ARaw, LOffset0, 0, LConfiguration);
      // the roads of every position go to the same list: the level keeps the ones of the last (the original
      // allocated a new array for each call and dropped the previous one)
      LoadConstructs(ARaw, LOffset0 + 2, wctRoad, Result.StartRoads);
      Inc(LOffset, 2);

      LOffset1 := TWarLittleEndian.ReadWord(ARaw, LOffset);
      LOffset1 := LoadCustomEntities(ARaw, LOffset1, 1, LConfiguration);
      LoadConstructs(ARaw, LOffset1 + 2, wctRoad, Result.StartRoads);
      Inc(LOffset, 2);

      Inc(LOffset, 2); // marker
      SetLength(Result.StartConfigurations, Length(Result.StartConfigurations) + 1);
      Result.StartConfigurations[High(Result.StartConfigurations)] := LConfiguration;
    end;
  end
  else
  begin
    LOffset := LoadStartEntities(ARaw, LOffset, Result.StartEntities);
    Inc(LOffset, 2);
    LOffset := LoadConstructs(ARaw, LOffset, wctRoad, Result.StartRoads);
    Inc(LOffset, 2);
    LoadConstructs(ARaw, LOffset, wctWall, Result.StartWalls);
  end;
end;

end.
