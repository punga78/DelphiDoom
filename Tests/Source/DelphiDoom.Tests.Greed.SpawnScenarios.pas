{******************************************************************************}
{                                                                              }
{  DelphiDoom: the scenarios of the parity of TGreedSpawner                     }
{                                                                              }
{  One list of cases (value, arguments, map, state of the game) and one way to  }
{  write down what a SpawnSprite did. The harness Tools\Verifica\175-spawn      }
{  runs them on spawn.pas of xGreed as it was and writes the golden file; the   }
{  test runs them on the library. No unit of the library is used here           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SpawnScenarios;

// the generator and the fingerprint wrap
{$Q-}
{$R-}

interface

uses
  System.SysUtils;

const
  SPAWN_TILES = 4096;
  /// <summary>Every value from 0 to SPAWN_LAST_VALUE is tried SPAWN_PASSES times</summary>
  SPAWN_LAST_VALUE = 700;
  SPAWN_PASSES = 6;
  SPAWN_EXTRA_ROUNDS = 50;
  /// <summary>What a line of the calls of a snapshot is</summary>
  SPAWN_CALL_SOUND = 1;
  SPAWN_CALL_DEMAND = 2;

type
  TSpawnTiles = array[0..SPAWN_TILES - 1] of Byte;

  TSpawnMap = record
    FloorHeight, CeilingHeight, FloorPic, CeilingPic, MapFlags, MapSprites: TSpawnTiles;
  end;

  TSpawnCase = record
    Index: Integer;
    Value: Integer;
    X, Y, Z, ZAdjust: Integer;
    Angle, Angle2: Integer;
    Active: Boolean;
    SpawnId: Integer;
    MapSeed: Cardinal;
    Midget, NoSpawn, Violence: Boolean;
    PlayerNum: Integer;
    PlayerX, PlayerY, PlayerZ, PlayerHeight, PlayerTime: Integer;
    TimeCount: Integer;
    RandomOffset: Integer;
    BloodCount, MetalCount: Integer;
    /// <summary>How many sprites are in the list before the call (see PrefillKind); the middle one is removed</summary>
    Prefill: Integer;
    Primaries: array[0..3] of Integer;
    Secondaries: array[0..13] of Integer;
  end;

  TSpawnRow = TArray<Integer>;

  /// <summary>What is left after one SpawnSprite, in numbers</summary>
  TSpawnSnapshot = record
    Failed: Boolean;
    /// <summary>The slot of the sprite that was returned, -1 for nil</summary>
    Returned: Integer;
    /// <summary>The sprites in the order of the list: the slot and then the fields</summary>
    Sprites: TArray<TSpawnRow>;
    Elevators: TArray<TSpawnRow>;
    Doors: TArray<TSpawnRow>;
    Areas: TArray<TSpawnRow>;
    FloorHeightHash, MapSpritesHash, MapFlagsHash: Cardinal;
    RandomUsed: Integer;
    /// <summary>SoundEffect and DemandLoadMonster in the order they were called</summary>
    Calls: TArray<TSpawnRow>;
    /// <summary>The player, the start places, the exit, the counters</summary>
    Globals: TSpawnRow;
  end;

  TSpawnScenarios = class
  public
    class function CaseCount: Integer; static;
    class function CaseAt(AIndex: Integer): TSpawnCase; static;
    class procedure BuildMap(ASeed: Cardinal; out AMap: TSpawnMap); static;
    /// <summary>The kind of the sprite number AIndex that is in the list before the call</summary>
    class function PrefillKind(AIndex: Integer): Integer; static;
    /// <summary>The number that CA_GetNamedNum gives for a name in both programs (upper and lower case are one)</summary>
    class function LumpNumber(const AName: string): Integer; static;
    class function HashTiles(const ATiles: TSpawnTiles): Cardinal; static;
    class function Describe(const ASnapshot: TSpawnSnapshot): string; static;
    /// <summary>FNV-1a of the text</summary>
    class function Fingerprint(const AText: string): Cardinal; static;
    /// <summary>The line of the golden file of a case</summary>
    class function GoldenLine(const ACase: TSpawnCase; const ASnapshot: TSpawnSnapshot): string; static;
  end;

implementation

const
  FNV_OFFSET = 2166136261;
  FNV_PRIME = 16777619;

  // the values that use the random numbers, the lists or the state: tried more often
  EXTRA_VALUES: array[0..17] of Integer = (
    532, 607, 525, 600, 531, 535, 534, 536, 528, 100, 101, 15, 16, 1, 605, 603, 606, 527);

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8) and $FFFFFF;
end;

{ TSpawnScenarios }

class function TSpawnScenarios.CaseCount: Integer;
begin
  Result := (SPAWN_LAST_VALUE + 1) * SPAWN_PASSES + Length(EXTRA_VALUES) * SPAWN_EXTRA_ROUNDS;
end;

class function TSpawnScenarios.CaseAt(AIndex: Integer): TSpawnCase;
var
  LSeed: Cardinal;
  LBase, LTileX, LTileY, LNumber: Integer;
begin
  Result := Default(TSpawnCase);
  Result.Index := AIndex;
  LBase := (SPAWN_LAST_VALUE + 1) * SPAWN_PASSES;
  if AIndex < LBase then
    Result.Value := AIndex mod (SPAWN_LAST_VALUE + 1)
  else
    Result.Value := EXTRA_VALUES[(AIndex - LBase) mod Length(EXTRA_VALUES)];
  LSeed := Cardinal(AIndex) * 2654435761 + 12345;
  for LNumber := Low(Result.Primaries) to High(Result.Primaries) do
    Result.Primaries[LNumber] := NextRandom(LSeed) mod 50;
  for LNumber := Low(Result.Secondaries) to High(Result.Secondaries) do
    Result.Secondaries[LNumber] := NextRandom(LSeed) mod 50;
  if AIndex <= SPAWN_LAST_VALUE then
  begin
    // the first pass: the same plain state for every value
    Result.MapSeed := 1;
    Result.X := (10 shl 22) + (32 shl 16);
    Result.Y := (12 shl 22) + (32 shl 16);
    Result.Active := True;
    Result.Violence := True;
    Result.PlayerX := -1;
    Exit;
  end;
  Result.MapSeed := 1 + Cardinal(NextRandom(LSeed) mod 6);
  LTileX := NextRandom(LSeed) mod 64;
  // not the first row nor the last two: there the original reads the memory around its arrays
  LTileY := 1 + NextRandom(LSeed) mod 61;
  Result.X := (LTileX shl 22) + (NextRandom(LSeed) and $3FFFFF);
  Result.Y := (LTileY shl 22) + (NextRandom(LSeed) and $3FFFFF);
  Result.Z := ((NextRandom(LSeed) mod 200) shl 16) + (NextRandom(LSeed) and $FFFF);
  Result.ZAdjust := ((NextRandom(LSeed) mod 60) - 20) shl 16;
  Result.Angle := (NextRandom(LSeed) mod 4096) - 1024;
  Result.Angle2 := (NextRandom(LSeed) mod 256) - 128;
  Result.Active := NextRandom(LSeed) and 1 <> 0;
  Result.SpawnId := NextRandom(LSeed) mod 6;
  Result.Midget := NextRandom(LSeed) mod 8 = 0;
  Result.NoSpawn := NextRandom(LSeed) mod 4 = 0;
  Result.Violence := NextRandom(LSeed) mod 4 <> 0;
  Result.PlayerNum := NextRandom(LSeed) mod 3;
  if NextRandom(LSeed) and 1 <> 0 then
    Result.PlayerX := -1
  else
    Result.PlayerX := 123456;
  Result.PlayerY := 7;
  Result.PlayerZ := 9;
  Result.PlayerHeight := (NextRandom(LSeed) mod 60) shl 16;
  Result.PlayerTime := NextRandom(LSeed) mod 100000;
  Result.TimeCount := NextRandom(LSeed) mod 100000;
  Result.RandomOffset := NextRandom(LSeed) mod 2000;
  if NextRandom(LSeed) mod 3 = 0 then
    Result.BloodCount := 201 + NextRandom(LSeed) mod 3
  else
    Result.BloodCount := NextRandom(LSeed) mod 201;
  if NextRandom(LSeed) mod 3 = 0 then
    Result.MetalCount := 101 + NextRandom(LSeed) mod 3
  else
    Result.MetalCount := NextRandom(LSeed) mod 101;
  Result.Prefill := NextRandom(LSeed) mod 12;
end;

class procedure TSpawnScenarios.BuildMap(ASeed: Cardinal; out AMap: TSpawnMap);
var
  LSeed: Cardinal;
  LSpot, LChoice, LFlags: Integer;
begin
  LSeed := ASeed * 7919 + 17;
  for LSpot := 0 to SPAWN_TILES - 1 do
  begin
    AMap.FloorHeight[LSpot] := NextRandom(LSeed) mod 120;
    AMap.CeilingHeight[LSpot] := AMap.FloorHeight[LSpot] + NextRandom(LSeed) mod 100;
    LChoice := NextRandom(LSeed) mod 10;
    if LChoice = 0 then
      AMap.FloorPic[LSpot] := 0
    else if LChoice = 1 then
      // water
      AMap.FloorPic[LSpot] := 57 + NextRandom(LSeed) mod 3
    else
      AMap.FloorPic[LSpot] := 1 + NextRandom(LSeed) mod 50;
    if NextRandom(LSeed) mod 12 = 0 then
      AMap.CeilingPic[LSpot] := 0
    else
      AMap.CeilingPic[LSpot] := 1 + NextRandom(LSeed) mod 50;
    LFlags := 0;
    // three tiles in ten have a floor that is not flat, and the same for the ceiling
    if NextRandom(LSeed) mod 10 < 3 then
      LFlags := LFlags or (1 + NextRandom(LSeed) mod 3);
    if NextRandom(LSeed) mod 10 < 3 then
      LFlags := LFlags or ((1 + NextRandom(LSeed) mod 3) shl 3);
    if NextRandom(LSeed) mod 8 = 0 then
      LFlags := LFlags or 128;
    AMap.MapFlags[LSpot] := LFlags;
    AMap.MapSprites[LSpot] := NextRandom(LSeed) mod 256;
  end;
end;

class function TSpawnScenarios.PrefillKind(AIndex: Integer): Integer;
begin
  case AIndex mod 3 of
    0:
      Result := 75;
    1:
      Result := 532;
  else
    Result := 607;
  end;
end;

class function TSpawnScenarios.LumpNumber(const AName: string): Integer;
begin
  Result := 100 + Integer(Fingerprint(LowerCase(AName)) mod 30000);
end;

class function TSpawnScenarios.HashTiles(const ATiles: TSpawnTiles): Cardinal;
var
  LSpot: Integer;
begin
  Result := FNV_OFFSET;
  for LSpot := 0 to SPAWN_TILES - 1 do
    Result := (Result xor ATiles[LSpot]) * FNV_PRIME;
end;

class function TSpawnScenarios.Fingerprint(const AText: string): Cardinal;
var
  LIndex: Integer;
begin
  Result := FNV_OFFSET;
  for LIndex := 1 to Length(AText) do
    Result := (Result xor (Ord(AText[LIndex]) and $FF)) * FNV_PRIME;
end;

class function TSpawnScenarios.Describe(const ASnapshot: TSpawnSnapshot): string;
var
  LText: TStringBuilder;

  procedure AddRow(const ATitle: string; const ARow: TSpawnRow);
  var
    LNumber: Integer;
  begin
    LText.Append(ATitle);
    for LNumber := 0 to High(ARow) do
      LText.Append(' ').Append(ARow[LNumber]);
    LText.Append(#10);
  end;

  procedure AddRows(const ATitle: string; const ARows: TArray<TSpawnRow>);
  var
    LNumber: Integer;
  begin
    LText.Append(ATitle).Append('s ').Append(Length(ARows)).Append(#10);
    for LNumber := 0 to High(ARows) do
      AddRow(ATitle, ARows[LNumber]);
  end;

begin
  LText := TStringBuilder.Create;
  try
    LText.Append('failed ').Append(Ord(ASnapshot.Failed)).Append(#10);
    LText.Append('returned ').Append(ASnapshot.Returned).Append(#10);
    AddRows('sprite', ASnapshot.Sprites);
    AddRows('elevator', ASnapshot.Elevators);
    AddRows('door', ASnapshot.Doors);
    AddRows('area', ASnapshot.Areas);
    LText.Append('planes ').Append(IntToHex(ASnapshot.FloorHeightHash, 8)).Append(' ')
      .Append(IntToHex(ASnapshot.MapSpritesHash, 8)).Append(' ').Append(IntToHex(ASnapshot.MapFlagsHash, 8))
      .Append(#10);
    LText.Append('random ').Append(ASnapshot.RandomUsed).Append(#10);
    AddRows('call', ASnapshot.Calls);
    AddRow('globals', ASnapshot.Globals);
    Result := LText.ToString;
  finally
    LText.Free;
  end;
end;

class function TSpawnScenarios.GoldenLine(const ACase: TSpawnCase; const ASnapshot: TSpawnSnapshot): string;
begin
  Result := Format('%d %d %d %d %d %d %s', [ACase.Index, ACase.Value, Ord(ASnapshot.Failed), ASnapshot.Returned,
    Length(ASnapshot.Sprites), ASnapshot.RandomUsed, IntToHex(Fingerprint(Describe(ASnapshot)), 8)]);
end;

end.
