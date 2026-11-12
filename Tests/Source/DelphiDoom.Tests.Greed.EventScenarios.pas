{******************************************************************************}
{                                                                              }
{  DelphiDoom: the scenarios of the parity of TGreedEvents                      }
{                                                                              }
{  The scripts, the maps, the state of the game and the events of each step,    }
{  and the fingerprint in which both programs write what they see. The harness  }
{  Tools\Verifica\175-events runs them on event.pas of xGreed as it was and     }
{  writes the golden files; the test runs them on the library. No unit of the   }
{  library is used here                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.EventScenarios;

// the generator and the fingerprint wrap
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes;

const
  EVENT_TILES = 4096;
  /// <summary>How many scripts are generated; the first EVENT_SPECIAL_CASES are written by hand</summary>
  EVENT_CASES = 360;
  EVENT_SPECIAL_CASES = 16;
  /// <summary>The tics of each case after its script is loaded</summary>
  EVENT_STEPS = 240;
  /// <summary>The planes, the triggers and the events of the player enter the fingerprint every so many tics</summary>
  EVENT_FULL_EVERY = 16;
  EVENT_MAX_SPRITES = 12;
  EVENT_MAX_ELEVATORS = 6;

  // ---- the calls that go out of event.pas, in the fingerprint as they happen ----

  EVENT_CALL_SPAWN = 1;
  EVENT_CALL_SOUND = 2;
  EVENT_CALL_DEMAND = 3;
  EVENT_CALL_ACTIVATION = 4;
  EVENT_CALL_FLI = 5;
  EVENT_CALL_WAIT = 6;
  EVENT_CALL_SCRIPT = 7;
  // the calls of the life of a map (utils.pas), for the scenarios of TGreedMapSession
  EVENT_CALL_START_WAIT = 8;
  EVENT_CALL_END_WAIT = 9;
  EVENT_CALL_SONG = 10;
  EVENT_CALL_STOP_MUSIC = 11;
  EVENT_CALL_BRIEFING = 12;
  EVENT_CALL_END_GAME = 13;
  EVENT_CALL_TEXTURES = 14;
  EVENT_CALL_RESET_MOUSE = 15;
  EVENT_CALL_LOAD_WEAPON = 16;

  // ---- the lumps of the archive of the scenarios ----

  EVENT_LUMP_MAP = 10;
  EVENT_LUMP_SCRIPT = 60;
  EVENT_LUMP_FIRST_SKY = 100;
  EVENT_LUMP_LAST_SKY = 103;
  EVENT_SKY_LUMP_BYTES = 8 + 32768;
  EVENT_LUMP_WALLS = 500;
  EVENT_LUMP_FIRST_DOOR = 520;

  // ---- what the state has before a script is loaded: LoadScript must clear it ----

  EVENT_DIRTY_TRIGGER = 170;
  EVENT_DIRTY_SWITCH = 85;
  EVENT_DIRTY_ZONE_BYTE = 3;
  EVENT_DIRTY_COUNT = 9;
  EVENT_DIRTY_PROCESS = 1005;

  // ---- the complete game: every map with these ways of loading its script ----

  EVENT_FULL_MAPS = 32;
  EVENT_FULL_VARIANTS = 3;
  EVENT_FULL_PROCESS_STEPS = 3;

type
  TEventTiles = array[0..EVENT_TILES - 1] of Byte;

  /// <summary>FNV-1a of the numbers that are added, in the order they are added</summary>
  TEventHash = record
    Value: Cardinal;
    Count: Integer;
    procedure Reset;
    procedure Add(AValue: Integer);
    procedure AddBoolean(AValue: Boolean);
    procedure AddBytes(const ABytes; ACount: Integer);
    procedure AddCall(AKind: Integer; const AArguments: array of Integer);
    /// <summary>Writes the value so far in EventHashTrace, to look for the first thing that differs</summary>
    procedure Mark(const AName: string);
  end;

  TEventMap = record
    NorthWall, WestWall, FloorPic, CeilingPic, FloorHeight, CeilingHeight, MapLights, MapEffects, MapSprites,
      MapFlags: TEventTiles;
  end;

  TEventSprite = record
    X, Y, Z, MoveSpeed, Kind: Integer;
    Active: Boolean;
  end;

  TEventElevator = record
    MapSpot, Floor, Ceiling, Position, Eval: Integer;
  end;

  TEventCase = record
    Index: Integer;
    MapSeed: Cardinal;
    NewGame: Boolean;
    /// <summary>eventloading while the steps run</summary>
    EventLoading: Boolean;
    Difficulty: Integer;
    PlayerX, PlayerY, PlayerHeight, PlayerTime, TimeCount: Integer;
    Events: array[0..255] of Byte;
    SpriteCount: Integer;
    Sprites: array[0..EVENT_MAX_SPRITES - 1] of TEventSprite;
    ElevatorCount: Integer;
    Elevators: array[0..EVENT_MAX_ELEVATORS - 1] of TEventElevator;
    /// <summary>The number of the map: LoadScript gets the lump EVENT_LUMP_MAP + Map + 1</summary>
    Map: Integer;
    Script: TBytes;
  end;

  TEventScenarios = class
  public
    class function CaseAt(AIndex: Integer): TEventCase; static;
    class procedure BuildMap(ASeed: Cardinal; out AMap: TEventMap); static;
    /// <summary>The event that is run at a tic of a case, -1 for none</summary>
    class function StepEvent(ACase, AStep: Integer): Integer; static;
    /// <summary>CA_GetNamedNum of the scenarios (upper and lower case are one); -1 if there is no such lump</summary>
    class function LumpNumber(const AName: string): Integer; static;
    /// <summary>The bytes of one of the lumps of the sky</summary>
    class function SkyLump(ALump: Integer): TBytes; static;
    /// <summary>The stand-in of SpawnSprite makes a sprite for these values and gives nil for the others</summary>
    class function SpawnMakesSprite(AValue: Integer): Boolean; static;
    class function SpawnedMoveSpeed(AValue: Integer): Integer; static;
    /// <summary>The number of a film from the line that is printed after it; -1 if it is not one of the three</summary>
    class function FliOfCaption(const AText: string): Integer; static;
    class function GoldenLine(const ACase: TEventCase; ALoadFailed: Boolean; AZones, AProcesses, ASteps: Integer;
      AStepFailed: Boolean; ALoadHash, AFinalHash: Cardinal): string; static;
    /// <summary>How the script of a map of the complete game is loaded in a variant</summary>
    class procedure FullVariant(AVariant: Integer; out ANewGame: Boolean; out ADifficulty: Integer;
      out AEventsDone: Boolean); static;
    class function FullLine(AMap, AVariant: Integer; ALoadFailed: Boolean; AZones, AProcesses, AEvents: Integer;
      ARunFailed: Boolean; ALoadHash, AFinalHash: Cardinal): string; static;
  end;

var
  /// <summary>Where TEventHash.Mark writes; nil (nothing is written) unless a difference is being looked for</summary>
  EventHashTrace: TStrings = nil;

implementation

const
  FNV_OFFSET = 2166136261;
  FNV_PRIME = 16777619;

  CRLF = #13#10;

  KEYWORD_COUNT = 21;
  KEYWORDS: array[0..KEYWORD_COUNT - 1] of AnsiString = (
    'TRIGGER', 'AREATRIGGER', 'WALLSWITCH', 'ELEVATOR', 'SPAWNELEVATOR', 'ACTIVATIONZONE', 'MAPZONE', 'BONUSTIME',
    'PRIMARY', 'SECONDARY', 'LEVELSCORE', 'SPRITE', 'SPAWN', 'SPAWNTRIGGER', 'SPAWNSOUND', 'SPAWNFLI', 'FORCELOAD',
    'SPAWNAREATRIGGER', 'BACKDROP', 'REM', 'FOO');

  EVENT_VALUES: array[0..19] of Integer = (0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 201, 202, 203, 204, 255, 256, 300);
  LAYERS: array[0..7] of Integer = (0, 2, 4, 6, 8, 9, 14, 15);
  BAD_LAYERS: array[0..4] of Integer = (1, 3, 16, 99, -1);
  MONSTER_NAMES: array[0..4] of AnsiString = ('KMAN', 'kfem', 'PBoss', 'WIZ', 'NOSUCH');
  SKY_NAMES: array[0..2] of AnsiString = ('BACKDROP', 'sky2', 'NOSKY');
  REM_WORDS: array[0..4] of AnsiString = ('note', 'the door', 'x1 y2', 'open 5', '');
  FLI_CAPTIONS: array[0..2] of string = (
    'Do not taunt happy fun airlock.', 'Original recipe or extra crispy?', 'Thank you for recycling!');

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8) and $FFFFFF;
end;

function ToBytes(const AText: AnsiString): TBytes;
begin
  SetLength(Result, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], Result[0], Length(AText));
end;

function Number(AValue: Integer): AnsiString;
begin
  Result := AnsiString(IntToStr(AValue));
end;

{ TEventHash }

procedure TEventHash.Reset;
begin
  Value := FNV_OFFSET;
  Count := 0;
end;

procedure TEventHash.Add(AValue: Integer);
var
  LValue: Cardinal;
  LByte: Integer;
begin
  LValue := Cardinal(AValue);
  for LByte := 0 to 3 do
  begin
    Value := (Value xor (LValue and $FF)) * FNV_PRIME;
    LValue := LValue shr 8;
  end;
  Inc(Count);
end;

procedure TEventHash.AddBoolean(AValue: Boolean);
begin
  Add(Ord(AValue));
end;

procedure TEventHash.AddBytes(const ABytes; ACount: Integer);
var
  LByte: PByte;
  LIndex: Integer;
begin
  LByte := @ABytes;
  for LIndex := 0 to ACount - 1 do
  begin
    Value := (Value xor LByte^) * FNV_PRIME;
    Inc(LByte);
  end;
  Inc(Count);
end;

procedure TEventHash.AddCall(AKind: Integer; const AArguments: array of Integer);
var
  LIndex: Integer;
begin
  Add(AKind);
  for LIndex := 0 to High(AArguments) do
    Add(AArguments[LIndex]);
end;

procedure TEventHash.Mark(const AName: string);
begin
  if Assigned(EventHashTrace) then
    EventHashTrace.Add(AName + ' ' + IntToHex(Value, 8));
end;

{ the scripts }

type
  TScriptWriter = record
    Seed: Cardinal;
    Text: AnsiString;
    Plain: Boolean;
    ElevatorSeen: Boolean;
    ForceLoads: Integer;
    function Pick(ACount: Integer): Integer;
    function Tile: Integer;
    function InnerRow: Integer;
    function EventValue: Integer;
    function Anything: Integer;
    function Separator: AnsiString;
    function LineEnd: AnsiString;
    function Keyword(AIndex: Integer): AnsiString;
    function Shown(AValue: Integer): AnsiString;
    procedure Line(AKeyword: Integer; const AValues: array of Integer; const AName: AnsiString = '');
    procedure RandomLine;
  end;

function TScriptWriter.Pick(ACount: Integer): Integer;
begin
  Result := NextRandom(Seed) mod ACount;
end;

function TScriptWriter.Tile: Integer;
begin
  Result := Pick(64);
end;

function TScriptWriter.InnerRow: Integer;
begin
  // not the first row nor the last two: there the floor of the original reads the memory around its arrays
  Result := 1 + Pick(61);
end;

function TScriptWriter.EventValue: Integer;
begin
  Result := EVENT_VALUES[Pick(Length(EVENT_VALUES))];
end;

function TScriptWriter.Anything: Integer;
begin
  Result := Pick(451) - 50;
end;

function TScriptWriter.Separator: AnsiString;
begin
  if Plain then
    Exit(' ');
  case Pick(12) of
    0:
      Result := '  ';
    1:
      Result := ',';
    2:
      Result := #9;
    3:
      Result := ' ( ';
    4:
      Result := ') ';
    5:
      Result := ' {';
    6:
      Result := '} ';
  else
    Result := ' ';
  end;
end;

function TScriptWriter.LineEnd: AnsiString;
begin
  if Plain then
    Exit(CRLF);
  case Pick(10) of
    0:
      Result := #10;
    1:
      Result := #13;
    2:
      Result := ' // ' + REM_WORDS[Pick(Length(REM_WORDS))] + CRLF;
  else
    Result := CRLF;
  end;
end;

function TScriptWriter.Keyword(AIndex: Integer): AnsiString;
var
  LIndex: Integer;
begin
  Result := KEYWORDS[AIndex];
  if Plain then
    Exit;
  case Pick(4) of
    0:
      Result := AnsiString(LowerCase(string(Result)));
    1:
      for LIndex := 1 to Length(Result) do
        if Odd(LIndex) then
          Result[LIndex] := AnsiChar(Ord(Result[LIndex]) + 32);
  end;
end;

function TScriptWriter.Shown(AValue: Integer): AnsiString;
begin
  Result := Number(AValue);
  if Plain or (AValue < 0) then
    Exit;
  case Pick(16) of
    0:
      Result := '$' + AnsiString(IntToHex(AValue, 1));
    1:
      Result := '0x' + AnsiString(IntToHex(AValue, 2));
    2:
      Result := '+' + Result;
    3:
      Result := '"' + Result + '"';
    4:
      // a number with a letter after it: the original takes what comes before the letter
      Result := Result + 'q';
  end;
end;

procedure TScriptWriter.Line(AKeyword: Integer; const AValues: array of Integer; const AName: AnsiString);
var
  LIndex, LCount: Integer;
begin
  Text := Text + Keyword(AKeyword);
  if AName <> '' then
    Text := Text + Separator + AName;
  LCount := Length(AValues);
  // one line in 25 has lost its last number: the next word is read in its place (not the number of a film: at
  // the end of the text it would be the event, and the original reads its table of the films outside)
  if not Plain and (LCount > 0) and (AKeyword <> 15) and (Pick(25) = 0) then
    Dec(LCount);
  for LIndex := 0 to LCount - 1 do
    Text := Text + Separator + Shown(AValues[LIndex]);
  Text := Text + LineEnd;
end;

procedure TScriptWriter.RandomLine;
var
  LKeyword, LX, LY, LLayer: Integer;
begin
  LKeyword := Pick(KEYWORD_COUNT + 6);
  // the zones are tried more often than the rest
  if LKeyword >= KEYWORD_COUNT then
    LKeyword := 5 + (LKeyword - KEYWORD_COUNT) mod 2;
  case LKeyword of
    0:
      Line(0, [Tile, Tile, EventValue]);
    1:
      begin
        LX := Tile;
        LY := Tile;
        Line(1, [LX, LY, LX + Pick(64 - LX) mod 6, LY + Pick(64 - LY) mod 6, EventValue]);
      end;
    2:
      Line(2, [Tile, Tile, EventValue]);
    3:
      begin
        Line(3, [Tile, Tile, EventValue, EventValue, Pick(3), Pick(200), Pick(200), 1 + Pick(8)]);
        ElevatorSeen := True;
      end;
    4:
      // without an ELEVATOR line before it the end event of the original is not set
      if ElevatorSeen then
        Line(4, [Tile, Tile, EventValue, Pick(3), Pick(200), Pick(200), 1 + Pick(8)]);
    5:
      Line(5, [Pick(80) - 10, Pick(80) - 10, Pick(80) - 5, Pick(80) - 5, EventValue, Pick(2)]);
    6:
      begin
        LX := Tile;
        LY := Tile;
        if Pick(60) = 0 then
          LLayer := BAD_LAYERS[Pick(Length(BAD_LAYERS))]
        else
          LLayer := LAYERS[Pick(Length(LAYERS))];
        Line(6, [LX, LY, LX + Pick(64 - LX) mod 5, LY + Pick(64 - LY) mod 5, EventValue, EventValue, LLayer,
          Pick(300) - 20, Pick(24) - 1, Pick(2)]);
      end;
    7:
      Line(7, [Anything]);
    8:
      Line(8, [Pick(2), Anything, Anything, Anything]);
    9:
      Line(9, [Pick(7), Anything, Anything, Anything]);
    10:
      Line(10, [Anything * 1000]);
    11:
      Line(11, [Tile, Tile, Pick(600), Anything, Pick(6), Pick(6)]);
    12:
      Line(12, [Tile, InnerRow, Pick(256), Pick(600), Anything, Pick(6), Pick(6), Pick(2)]);
    13:
      Line(13, [Tile, Tile, EventValue, Anything, Pick(2)]);
    14:
      Line(14, [Anything, Anything, EventValue, Anything, Pick(2)]);
    15:
      Line(15, [EventValue, Pick(3)]);
    16:
      if ForceLoads < 16 then
      begin
        // one name in 40 is of a lump that does not exist
        if Pick(40) = 0 then
          Line(16, [Pick(60)], MONSTER_NAMES[4])
        else
          Line(16, [Pick(60)], MONSTER_NAMES[Pick(4)]);
        Inc(ForceLoads);
      end;
    17:
      begin
        LX := Tile;
        LY := Tile;
        Line(17, [LX, LY, LX + Pick(65 - LX) mod 6, LY + Pick(65 - LY) mod 6, EventValue, Anything, Pick(2)]);
      end;
    18:
      if Pick(30) = 0 then
        Line(18, [], SKY_NAMES[2])
      else
        Line(18, [], SKY_NAMES[Pick(2)]);
    19:
      Text := Text + Keyword(19) + ' ' + REM_WORDS[Pick(Length(REM_WORDS))] + CRLF;
    20:
      Line(20, [Pick(9), Pick(9)]);
  end;
end;

function AllKeywords: AnsiString;
begin
  Result :=
    'REM every word of the script once' + CRLF +
    'TRIGGER 3 4 5' + CRLF +
    'AREATRIGGER 10 11 12 13 6' + CRLF +
    'WALLSWITCH 20 21 7' + CRLF +
    'ELEVATOR 5 6 1 2 0 90 30 4' + CRLF +
    'ELEVATOR 7 8 2 3 1 80 20 2' + CRLF +
    'SPAWNELEVATOR 9 10 3 0 70 10 3' + CRLF +
    'ACTIVATIONZONE 0 0 63 63 1 1' + CRLF +
    'ACTIVATIONZONE 0 0 63 63 2 0' + CRLF +
    'MAPZONE 2 2 6 6 1 4 8 60 3 1' + CRLF +
    'MAPZONE 2 2 6 6 4 0 14 0 7 0' + CRLF +
    'MAPZONE 30 30 31 31 0 5 9 200 50 1' + CRLF +
    'BONUSTIME 90' + CRLF +
    'PRIMARY 0 100 2 51' + CRLF +
    'PRIMARY 1 200 1 52' + CRLF +
    'SECONDARY 0 10 3 53' + CRLF +
    'SECONDARY 6 20 4 59' + CRLF +
    'LEVELSCORE 54321' + CRLF +
    'SPRITE 40 41 75 0 0 5' + CRLF +
    'SPRITE 42 43 77 0 3 3' + CRLF +
    'SPAWN 12 13 2 75 9 0 5 1' + CRLF +
    'SPAWN 14 15 3 80 0 0 5 0' + CRLF +
    'SPAWNTRIGGER 16 17 2 33 1' + CRLF +
    'SPAWNSOUND 18 19 3 12 0' + CRLF +
    'SPAWNFLI 5 1' + CRLF +
    'FORCELOAD KMAN 56' + CRLF +
    'FORCELOAD wiz 48' + CRLF +
    'SPAWNAREATRIGGER 50 50 53 52 0 44 1' + CRLF +
    'SPAWNAREATRIGGER 54 54 56 56 4 45 0' + CRLF +
    'BACKDROP SKY2' + CRLF +
    'END' + CRLF +
    'TRIGGER 1 1 1' + CRLF;
end;

function SpecialScript(AIndex: Integer): AnsiString;
var
  LLine: Integer;
begin
  Result := '';
  case AIndex of
    0:
      Result := '';
    1:
      Result := '  ' + CRLF + #9 + CRLF + ' ';
    2:
      Result := AllKeywords;
    3:
      // the 255th zone stops the original
      for LLine := 0 to 259 do
        Result := Result + 'SPAWNFLI ' + Number(LLine mod 9) + ' ' + Number(LLine mod 3) + CRLF;
    4:
      Result := 'TRIGGER 1 2 3' + CRLF + 'FORCELOAD NOSUCH 5' + CRLF + 'TRIGGER 4 5 6' + CRLF;
    5:
      Result := 'BACKDROP nosky' + CRLF + 'TRIGGER 4 5 6' + CRLF;
    6:
      Result := 'BACKDROP sky2' + CRLF + 'BACKDROP backdrop' + CRLF + 'backdrop SKY2';
    7:
      // quotes, and one that is never closed: its word goes on to the end of the text
      Result := 'TRIGGER "3" "4" "5"' + CRLF + '"WALLSWITCH" 6 7 8' + CRLF + 'BACKDROP "SKY2' + CRLF;
    8:
      // single slashes are thrown away, a comment ends a word
      Result := '/TRIGGER 1 / 2 /3' + CRLF + 'WALLSWITCH 4 5 6// 7' + CRLF + '// TRIGGER 9 9 9' + CRLF +
        'TRIGGER 9//' + CRLF + '10 11';
    9:
      // a word longer than the buffer of the original is two words
      Result := 'TRIGGER 1 2 3' + CRLF + AnsiString(StringOfChar('7', 1500)) + CRLF + 'WALLSWITCH 2 3 4' + CRLF +
        '"' + AnsiString(StringOfChar('8', 1500)) + '"' + CRLF + 'TRIGGER 5 6 7';
    10:
      Result := 'trigger 1 2 3' + CRLF + 'End' + CRLF + 'TRIGGER 4 5 6' + CRLF + 'MAPZONE 1 1 1 1 0 0 99 1 1 1';
    11:
      // after REM at the end of the text the last word is read once more: here it is a command without numbers
      Result := 'LEVELSCORE 7' + CRLF + 'REM TRIGGER' + CRLF;
    12:
      Result := 'BONUSTIME 1' + CRLF + 'REM note PRIMARY' + CRLF;
    13:
      // the text ends in the middle of a command: the numbers that are missing are the last one read
      Result := 'LEVELSCORE 9' + CRLF + 'MAPZONE 4 5';
    14:
      Result := 'TRIGGER 5 6 2' + CRLF + 'ELEVATOR 3';
    15:
      // numbers that are not numbers, a zone with a layer that is not done, a process that never ends
      Result := 'TRIGGER abc 12x $1F' + CRLF + 'WALLSWITCH 0x10 +7 -' + CRLF + 'MAPZONE 1 1 2 2 0 0 5 9 1 0' + CRLF +
        'MAPZONE 3 3 4 4 1 0 8 -4 2 0' + CRLF + 'MAPZONE 5 5 6 6 2 0 8 300 0 0' + CRLF + 'LEVELSCORE 99999999999';
  end;
end;

{ TEventScenarios }

class function TEventScenarios.CaseAt(AIndex: Integer): TEventCase;
var
  LSeed: Cardinal;
  LWriter: TScriptWriter;
  LIndex, LLines: Integer;
begin
  Result := Default(TEventCase);
  Result.Index := AIndex;
  LSeed := Cardinal(AIndex) * 2654435761 + 977;
  Result.MapSeed := 1 + Cardinal(NextRandom(LSeed) mod 4);
  Result.NewGame := AIndex mod 3 <> 1;
  Result.EventLoading := NextRandom(LSeed) mod 5 = 0;
  Result.Difficulty := NextRandom(LSeed) mod 6;
  Result.PlayerX := ((NextRandom(LSeed) mod 64) shl 22) + (NextRandom(LSeed) and $3FFFFF);
  Result.PlayerY := ((1 + NextRandom(LSeed) mod 61) shl 22) + (NextRandom(LSeed) and $3FFFFF);
  Result.PlayerHeight := (30 + NextRandom(LSeed) mod 30) shl 16;
  Result.PlayerTime := NextRandom(LSeed) mod 100000;
  Result.TimeCount := NextRandom(LSeed) mod 100000;
  Result.Map := NextRandom(LSeed) mod 32;
  for LIndex := 0 to 255 do
    Result.Events[LIndex] := Ord(NextRandom(LSeed) mod 3 = 0);
  Result.SpriteCount := NextRandom(LSeed) mod (EVENT_MAX_SPRITES + 1);
  for LIndex := 0 to Result.SpriteCount - 1 do
  begin
    Result.Sprites[LIndex].X := ((NextRandom(LSeed) mod 64) shl 22) + (NextRandom(LSeed) and $3FFFFF);
    Result.Sprites[LIndex].Y := ((NextRandom(LSeed) mod 64) shl 22) + (NextRandom(LSeed) and $3FFFFF);
    Result.Sprites[LIndex].Z := NextRandom(LSeed);
    Result.Sprites[LIndex].MoveSpeed := (NextRandom(LSeed) mod 3) shl 16;
    Result.Sprites[LIndex].Kind := 75 + NextRandom(LSeed) mod 20;
    Result.Sprites[LIndex].Active := NextRandom(LSeed) mod 3 = 0;
  end;
  Result.ElevatorCount := NextRandom(LSeed) mod (EVENT_MAX_ELEVATORS + 1);
  for LIndex := 0 to Result.ElevatorCount - 1 do
  begin
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
    Result.Elevators[LIndex].Eval := EVENT_VALUES[NextRandom(LSeed) mod Length(EVENT_VALUES)];
  end;
  if AIndex < EVENT_SPECIAL_CASES then
  begin
    Result.Script := ToBytes(SpecialScript(AIndex));
    Exit;
  end;
  LWriter := Default(TScriptWriter);
  LWriter.Seed := LSeed;
  // one script in four is written plainly: nothing in it goes wrong
  LWriter.Plain := AIndex mod 4 = 0;
  LLines := 1 + LWriter.Pick(60);
  for LIndex := 0 to LLines - 1 do
    LWriter.RandomLine;
  if LWriter.Pick(6) = 0 then
    LWriter.Text := LWriter.Text + 'END' + CRLF + 'TRIGGER 1 1 1' + CRLF;
  // sometimes the last line has no line break
  if (LWriter.Pick(5) = 0) and (Length(LWriter.Text) >= 2) and
    (Copy(LWriter.Text, Length(LWriter.Text) - 1, 2) = CRLF) then
    SetLength(LWriter.Text, Length(LWriter.Text) - 2);
  Result.Script := ToBytes(LWriter.Text);
end;

class procedure TEventScenarios.BuildMap(ASeed: Cardinal; out AMap: TEventMap);
var
  LSeed: Cardinal;
  LSpot, LChoice, LFlags: Integer;
begin
  LSeed := ASeed * 7919 + 31;
  for LSpot := 0 to EVENT_TILES - 1 do
  begin
    AMap.NorthWall[LSpot] := NextRandom(LSeed) mod 256;
    AMap.WestWall[LSpot] := NextRandom(LSeed) mod 256;
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
    AMap.CeilingPic[LSpot] := NextRandom(LSeed) mod 50;
    AMap.MapLights[LSpot] := NextRandom(LSeed) mod 256;
    AMap.MapEffects[LSpot] := NextRandom(LSeed) mod 256;
    AMap.MapSprites[LSpot] := NextRandom(LSeed) mod 256;
    LFlags := 0;
    // three tiles in ten have a floor that is not flat
    if NextRandom(LSeed) mod 10 < 3 then
      LFlags := LFlags or (1 + NextRandom(LSeed) mod 3);
    AMap.MapFlags[LSpot] := LFlags;
  end;
end;

class function TEventScenarios.StepEvent(ACase, AStep: Integer): Integer;
var
  LSeed: Cardinal;
begin
  LSeed := Cardinal(ACase) * 40503 + Cardinal(AStep) * 69069 + 7;
  if NextRandom(LSeed) mod 3 <> 0 then
    Exit(-1);
  Result := EVENT_VALUES[NextRandom(LSeed) mod Length(EVENT_VALUES)];
end;

class function TEventScenarios.LumpNumber(const AName: string): Integer;
var
  LName: string;
begin
  LName := UpperCase(AName);
  if LName = 'MAP' then
    Result := EVENT_LUMP_MAP
  else if LName = 'SUX' then
    Result := EVENT_LUMP_SCRIPT
  else if LName = 'BACKDROP' then
    Result := EVENT_LUMP_FIRST_SKY
  else if LName = 'SKY2' then
    Result := EVENT_LUMP_FIRST_SKY + 2
  else if LName = 'KMAN' then
    Result := 200
  else if LName = 'KFEM' then
    Result := 260
  else if LName = 'PBOSS' then
    Result := 320
  else if LName = 'WIZ' then
    Result := 380
  else if LName = 'STARTWALLS' then
    Result := EVENT_LUMP_WALLS
  else if (Length(LName) = 6) and (Copy(LName, 1, 5) = 'DOOR_') and (LName[6] >= '1') and (LName[6] <= '7') then
    // the pictures of the doors, some lumps after the first wall
    Result := EVENT_LUMP_FIRST_DOOR + (Ord(LName[6]) - Ord('1')) * 3
  else
    Result := -1;
end;

class function TEventScenarios.SkyLump(ALump: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, EVENT_SKY_LUMP_BYTES);
  for LIndex := 0 to EVENT_SKY_LUMP_BYTES - 1 do
    Result[LIndex] := Byte(LIndex * 7 + ALump * 13 + (LIndex shr 8));
end;

class function TEventScenarios.SpawnMakesSprite(AValue: Integer): Boolean;
begin
  Result := AValue and 3 <> 0;
end;

class function TEventScenarios.SpawnedMoveSpeed(AValue: Integer): Integer;
begin
  Result := (AValue mod 3) shl 16;
end;

class function TEventScenarios.FliOfCaption(const AText: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := Low(FLI_CAPTIONS) to High(FLI_CAPTIONS) do
    if AText = FLI_CAPTIONS[LIndex] then
      Exit(LIndex);
  Result := -1;
end;

class function TEventScenarios.GoldenLine(const ACase: TEventCase; ALoadFailed: Boolean; AZones, AProcesses,
  ASteps: Integer; AStepFailed: Boolean; ALoadHash, AFinalHash: Cardinal): string;
begin
  Result := Format('E %d %d %d %d %d %d %s %s', [ACase.Index, Ord(ALoadFailed), AZones, AProcesses, ASteps,
    Ord(AStepFailed), IntToHex(ALoadHash, 8), IntToHex(AFinalHash, 8)]);
end;

class procedure TEventScenarios.FullVariant(AVariant: Integer; out ANewGame: Boolean; out ADifficulty: Integer;
  out AEventsDone: Boolean);
begin
  ANewGame := AVariant <> 2;
  AEventsDone := AVariant = 2;
  case AVariant of
    0:
      ADifficulty := 2;
    1:
      ADifficulty := 0;
  else
    ADifficulty := 4;
  end;
end;

class function TEventScenarios.FullLine(AMap, AVariant: Integer; ALoadFailed: Boolean; AZones, AProcesses,
  AEvents: Integer; ARunFailed: Boolean; ALoadHash, AFinalHash: Cardinal): string;
begin
  Result := Format('F %d %d %d %d %d %d %d %s %s', [AMap, AVariant, Ord(ALoadFailed), AZones, AProcesses, AEvents,
    Ord(ARunFailed), IntToHex(ALoadHash, 8), IntToHex(AFinalHash, 8)]);
end;

end.
