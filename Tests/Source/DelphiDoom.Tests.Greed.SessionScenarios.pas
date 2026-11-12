{******************************************************************************}
{                                                                              }
{  DelphiDoom: the scenarios of the parity of TGreedMapSession                  }
{                                                                              }
{  The maps, the state of the game and what is on the map when it is saved.     }
{  The harness Tools\Verifica\175-events (SessionGolden) runs them on newmap,   }
{  LoadNewMap, ActivateSpritesFromMap, resetengine, respawnplayer, SaveGame     }
{  and LoadGame of utils.pas of xGreed as they were and writes the golden file; }
{  the test runs them on the library. No unit of the library is used here       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SessionScenarios;

// the generator wraps
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Tests.Greed.EventScenarios;

const
  SESSION_CASES = 160;
  SESSION_MAP_SEEDS = 4;
  SESSION_PLANES = 18;
  SESSION_MAP_BYTES = SESSION_PLANES * EVENT_TILES;
  /// <summary>The planes of a map in the order of the file</summary>
  SESSION_PLANE_FLOOR_PIC = 4;
  SESSION_PLANE_FLOOR_HEIGHT = 8;
  SESSION_PLANE_CEILING_HEIGHT = 9;
  SESSION_PLANE_FLOOR_DEF = 10;
  SESSION_PLANE_CEILING_DEF = 12;
  SESSION_PLANE_SPRITES = 16;
  SESSION_PLANE_SLOPES = 17;
  SESSION_MAX_SPRITES = 48;
  SESSION_MAX_DOORS = 10;
  SESSION_MAX_AREAS = 12;
  SESSION_MAX_ELEVATORS = 14;
  /// <summary>What the clocks and the delays of the game have before a map starts: resetengine must clear it</summary>
  SESSION_DIRTY = 17;

type
  TSessionSprite = record
    Kind, X, Y, HitPoints, DeathEvent: Integer;
    NoFalling: Boolean;
  end;

  TSessionDoor = record
    TileX, TileY, Pic, Orientation: Integer;
  end;

  TSessionArea = record
    MapSpot, Kind: Integer;
  end;

  TSessionElevator = record
    Kind, Timer, MapSpot, Position, Floor, Ceiling, NoSave: Integer;
    Up, Down: Boolean;
  end;

  TSessionCase = record
    Index: Integer;
    Map: Integer;
    Activate: Integer;
    Demo, Game1, Game2, Game3: Boolean;
    Difficulty: Integer;
    Weapons: array[0..4] of Integer;
    CurrentWeapon: Integer;
    Clock: Cardinal;
    RandomOffset: Integer;
    StartLocations: array[0..7, 0..1] of Integer;
    /// <summary>The start place whose tile is emptied before respawnplayer, so that it ends</summary>
    FreeStart: Integer;
    PlayerHeight: Integer;
    LowResolution: Boolean;
    ScrollMin, ScrollMax: Integer;
    SaveNumber: Integer;
    /// <summary>The events that have happened when the game is saved</summary>
    Events: array[0..255] of Byte;
    SpriteCount: Integer;
    Sprites: array[0..SESSION_MAX_SPRITES - 1] of TSessionSprite;
    DoorCount: Integer;
    Doors: array[0..SESSION_MAX_DOORS - 1] of TSessionDoor;
    AreaCount: Integer;
    Areas: array[0..SESSION_MAX_AREAS - 1] of TSessionArea;
    ElevatorCount: Integer;
    Elevators: array[0..SESSION_MAX_ELEVATORS - 1] of TSessionElevator;
    Script: TBytes;
  end;

  TSessionScenarios = class
  public
    class function CaseAt(AIndex: Integer): TSessionCase; static;
    /// <summary>The 18 planes of the map of a seed (1 .. SESSION_MAP_SEEDS), as they are in the file</summary>
    class function MapBytes(ASeed: Integer): TBytes; static;
    /// <summary>The seed of the map of a number</summary>
    class function SeedOfMap(AMap: Integer): Integer; static;
    /// <summary>
    ///   CA_GetNamedNum of these scenarios: the numbers of TEventScenarios and, for every other name (the lumps of
    ///   the sprites), a number made from the name
    /// </summary>
    class function LumpNumber(const AName: string): Integer; static;
    class function GoldenLine(const ACase: TSessionCase; ANewMapFailed, ARespawnFailed, ASaveFailed,
      ALoadFailed: Boolean; ASprites, AElevators: Integer; ANewMapHash, ARespawnHash, ASaveHash,
      ALoadHash: Cardinal): string; static;
  end;

implementation

const
  MAPS: array[0..9] of Integer = (0, 1, 2, 3, 5, 8, 16, 22, 4, 7);
  // every kind that SaveGame knows, and some that it does not save
  SPRITE_KINDS: array[0..41] of Integer = (
    75, 77, 79, 81, 98, 84, 86, 88, 90, 92, 94, 96, 34, 36, 38, 255, 254, 250, 241, 135, 134, 133, 136, 137, 51, 52,
    53, 59, 105, 114, 123, 140, 152, 164, 165, 76, 99, 532, 600, 607, 513, 138);
  AREA_KINDS: array[0..12] of Integer = (0, 1, 10, 11, 17, 18, 24, 100, 101, 2, 9, 25, 102);
  ELEVATOR_TIMERS: array[0..5] of Integer = ($70000000, 12600, 25200, 63000, 0, 5000);

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8) and $FFFFFF;
end;

function HasWord(const ABytes: TBytes; const AWord: AnsiString): Boolean;
var
  LIndex, LChar: Integer;
  LFound: Boolean;
begin
  for LIndex := 0 to Length(ABytes) - Length(AWord) do
  begin
    LFound := True;
    for LChar := 1 to Length(AWord) do
      if UpCase(AnsiChar(ABytes[LIndex + LChar - 1])) <> AWord[LChar] then
      begin
        LFound := False;
        Break;
      end;
    if LFound then
      Exit(True);
  end;
  Result := False;
end;

// a script of the scenarios of the events that is written plainly and names no sky that does not exist (here a
// name that is not known is a lump all the same)
function PlainScript(ANumber: Integer): TBytes;
var
  LIndex, LFound: Integer;
begin
  LFound := -1;
  LIndex := EVENT_SPECIAL_CASES;
  repeat
    Result := TEventScenarios.CaseAt(LIndex).Script;
    if not HasWord(Result, 'NOSKY') then
      Inc(LFound);
    Inc(LIndex, 4);
    if LIndex >= EVENT_CASES then
      LIndex := EVENT_SPECIAL_CASES;
  until LFound = ANumber;
end;

{ TSessionScenarios }

class function TSessionScenarios.SeedOfMap(AMap: Integer): Integer;
begin
  Result := 1 + AMap mod SESSION_MAP_SEEDS;
end;

class function TSessionScenarios.MapBytes(ASeed: Integer): TBytes;
var
  LSeed: Cardinal;
  LPlane, LSpot: Integer;
  LValue: Integer;
begin
  SetLength(Result, SESSION_MAP_BYTES);
  LSeed := Cardinal(ASeed) * 104729 + 71;
  for LPlane := 0 to SESSION_PLANES - 1 do
    for LSpot := 0 to EVENT_TILES - 1 do
    begin
      LValue := NextRandom(LSeed) mod 256;
      case LPlane of
        SESSION_PLANE_FLOOR_PIC:
          // one tile in ten is water
          if LValue mod 10 = 0 then
            LValue := 57 + LValue mod 3
          else
            LValue := LValue mod 50;
        SESSION_PLANE_FLOOR_HEIGHT:
          LValue := LValue mod 120;
        SESSION_PLANE_CEILING_HEIGHT:
          LValue := 120 + LValue mod 100;
        SESSION_PLANE_FLOOR_DEF, SESSION_PLANE_CEILING_DEF:
          // some tiles have no definition: the game gives them the 56
          if LValue < 60 then
            LValue := 0;
        SESSION_PLANE_SPRITES:
          // half of the tiles are empty, the others have every value
          if NextRandom(LSeed) and 1 = 0 then
            LValue := 0;
        SESSION_PLANE_SLOPES:
          if LValue < 200 then
            LValue := 0
          else
            LValue := 46 + LValue mod 20;
      end;
      Result[LPlane * EVENT_TILES + LSpot] := LValue;
    end;
end;

class function TSessionScenarios.LumpNumber(const AName: string): Integer;
var
  LName: string;
  LHash: Cardinal;
  LIndex: Integer;
begin
  Result := TEventScenarios.LumpNumber(AName);
  if Result >= 0 then
    Exit;
  LName := UpperCase(AName);
  LHash := 2166136261;
  for LIndex := 1 to Length(LName) do
    LHash := (LHash xor (Ord(LName[LIndex]) and $FF)) * 16777619;
  Result := 1000 + Integer(LHash mod 3000);
end;

class function TSessionScenarios.CaseAt(AIndex: Integer): TSessionCase;
var
  LSeed: Cardinal;
  LIndex, LEpisode: Integer;
begin
  Result := Default(TSessionCase);
  Result.Index := AIndex;
  LSeed := Cardinal(AIndex) * 2246822519 + 3141;
  Result.Map := MAPS[NextRandom(LSeed) mod Length(MAPS)];
  Result.Activate := AIndex mod 3;
  LEpisode := NextRandom(LSeed) mod 5;
  Result.Demo := LEpisode = 0;
  Result.Game1 := (LEpisode = 1) or (LEpisode = 0);
  Result.Game2 := LEpisode = 2;
  Result.Game3 := LEpisode = 3;
  Result.Difficulty := NextRandom(LSeed) mod 6;
  for LIndex := 0 to 4 do
    if NextRandom(LSeed) mod 3 = 0 then
      Result.Weapons[LIndex] := -1
    else
      Result.Weapons[LIndex] := NextRandom(LSeed) mod 19;
  Result.CurrentWeapon := NextRandom(LSeed) mod 5;
  Result.Clock := Cardinal(NextRandom(LSeed)) * 257 + Cardinal(NextRandom(LSeed));
  Result.RandomOffset := NextRandom(LSeed) mod 2000;
  for LIndex := 0 to 7 do
  begin
    Result.StartLocations[LIndex][0] := NextRandom(LSeed) mod 64;
    // not the first row nor the last two: there the floor of the original reads the memory around its arrays
    Result.StartLocations[LIndex][1] := 1 + NextRandom(LSeed) mod 61;
  end;
  Result.FreeStart := NextRandom(LSeed) mod 8;
  Result.PlayerHeight := (30 + NextRandom(LSeed) mod 30) shl 16;
  Result.LowResolution := NextRandom(LSeed) and 1 = 0;
  Result.ScrollMin := NextRandom(LSeed) mod 100;
  if NextRandom(LSeed) and 1 = 0 then
    Result.ScrollMax := Result.ScrollMin + 200
  else
    Result.ScrollMax := Result.ScrollMin + 400;
  Result.SaveNumber := NextRandom(LSeed) mod 10;
  for LIndex := 1 to 255 do
    Result.Events[LIndex] := Ord(NextRandom(LSeed) mod 6 = 0);
  Result.SpriteCount := NextRandom(LSeed) mod (SESSION_MAX_SPRITES + 1);
  for LIndex := 0 to Result.SpriteCount - 1 do
  begin
    Result.Sprites[LIndex].Kind := SPRITE_KINDS[NextRandom(LSeed) mod Length(SPRITE_KINDS)];
    Result.Sprites[LIndex].X := ((NextRandom(LSeed) mod 64) shl 22) + (NextRandom(LSeed) and $3FFFFF);
    Result.Sprites[LIndex].Y := ((NextRandom(LSeed) mod 64) shl 22) + (NextRandom(LSeed) and $3FFFFF);
    if NextRandom(LSeed) mod 3 = 0 then
      Result.Sprites[LIndex].HitPoints := 0
    else
      Result.Sprites[LIndex].HitPoints := 1 + NextRandom(LSeed) mod 300;
    if NextRandom(LSeed) mod 4 = 0 then
      Result.Sprites[LIndex].DeathEvent := 1 + NextRandom(LSeed) mod 9;
    Result.Sprites[LIndex].NoFalling := NextRandom(LSeed) mod 3 = 0;
  end;
  Result.DoorCount := NextRandom(LSeed) mod (SESSION_MAX_DOORS + 1);
  for LIndex := 0 to Result.DoorCount - 1 do
  begin
    Result.Doors[LIndex].TileX := NextRandom(LSeed) mod 64;
    Result.Doors[LIndex].TileY := NextRandom(LSeed) mod 64;
    // the pictures of the seven doors, from the first wall, and one that is not a door
    if NextRandom(LSeed) mod 9 = 0 then
      Result.Doors[LIndex].Pic := 7
    else
      Result.Doors[LIndex].Pic := EVENT_LUMP_FIRST_DOOR - EVENT_LUMP_WALLS + (NextRandom(LSeed) mod 7) * 3;
    Result.Doors[LIndex].Orientation := NextRandom(LSeed) mod 4;
  end;
  Result.AreaCount := NextRandom(LSeed) mod (SESSION_MAX_AREAS + 1);
  for LIndex := 0 to Result.AreaCount - 1 do
  begin
    Result.Areas[LIndex].MapSpot := NextRandom(LSeed) mod EVENT_TILES;
    Result.Areas[LIndex].Kind := AREA_KINDS[NextRandom(LSeed) mod Length(AREA_KINDS)];
  end;
  Result.ElevatorCount := NextRandom(LSeed) mod (SESSION_MAX_ELEVATORS + 1);
  for LIndex := 0 to Result.ElevatorCount - 1 do
  begin
    Result.Elevators[LIndex].Kind := NextRandom(LSeed) mod 10;
    Result.Elevators[LIndex].Timer := ELEVATOR_TIMERS[NextRandom(LSeed) mod Length(ELEVATOR_TIMERS)];
    Result.Elevators[LIndex].MapSpot := NextRandom(LSeed) mod EVENT_TILES;
    Result.Elevators[LIndex].Floor := NextRandom(LSeed) mod 100;
    Result.Elevators[LIndex].Ceiling := 100 + NextRandom(LSeed) mod 100;
    case NextRandom(LSeed) mod 3 of
      0:
        Result.Elevators[LIndex].Position := Result.Elevators[LIndex].Floor;
      1:
        Result.Elevators[LIndex].Position := Result.Elevators[LIndex].Ceiling;
    else
      Result.Elevators[LIndex].Position := Result.Elevators[LIndex].Floor + 1;
    end;
    Result.Elevators[LIndex].NoSave := Ord(NextRandom(LSeed) mod 4 = 0);
    Result.Elevators[LIndex].Up := NextRandom(LSeed) mod 4 = 0;
    Result.Elevators[LIndex].Down := NextRandom(LSeed) mod 4 = 0;
  end;
  Result.Script := PlainScript(AIndex mod 40);
end;

class function TSessionScenarios.GoldenLine(const ACase: TSessionCase; ANewMapFailed, ARespawnFailed, ASaveFailed,
  ALoadFailed: Boolean; ASprites, AElevators: Integer; ANewMapHash, ARespawnHash, ASaveHash,
  ALoadHash: Cardinal): string;
begin
  Result := Format('S %d %d %d %d %d %d %d %d %d %s %s %s %s', [ACase.Index, ACase.Map, ACase.Activate,
    Ord(ANewMapFailed), Ord(ARespawnFailed), Ord(ASaveFailed), Ord(ALoadFailed), ASprites, AElevators,
    IntToHex(ANewMapHash, 8), IntToHex(ARespawnHash, 8), IntToHex(ASaveHash, 8), IntToHex(ALoadHash, 8)]);
end;

end.
