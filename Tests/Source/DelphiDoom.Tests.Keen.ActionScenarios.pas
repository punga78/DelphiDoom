{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the scenarios of the actions         }
{  (the same scenarios run the original C in Tools\Verifica\165)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.ActionScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf;

const
  SCENARIO_FIELDS = 35;
  SCENARIO_MAP_SIDE = 16;
  SCENARIO_FIRST_TEMP = 31;

type
  /// <summary>An actor of a scenario: the 35 fields of objtype that the C harness reads, and what the temps mean</summary>
  TKeenScenarioObject = record
    Fields: array[0..SCENARIO_FIELDS - 1] of Integer;
    /// <summary>For each temp: ' ' a number, '@' the place of an actor, '$' a state (only in the text for the C)</summary>
    TempKind: array[0..3] of Char;
  end;

  TKeenScenario = record
    Name: string;
    Kind: Char;
    Action: Word;
    XAxis, YAxis: Integer;
    Button0, Button1, Held0, Held1: Boolean;
    Tics, LastTime, Time: Integer;
    OriginXTile, OriginYTile, OriginXGlobal, OriginYGlobal, OriginXTileMax, OriginYTileMax: Integer;
    GameMapOn, MapOn, Keys, Bombs, Flowers, Lives, Difficulty: Integer;
    God, JumpCheat: Boolean;
    JumpTime, LeavePoleTime, Score, WorldX, WorldY, BombsThisLevel: Integer;
    Rnd: TArray<Integer>;
    Plane1, Plane2: TArray<Integer>;
    Objects: TArray<TKeenScenarioObject>;
    ObSel, HitSel: Integer;
  end;

  /// <summary>The scenarios: random but fixed (a generator with a seed) situations for each function of the states</summary>
  TKeenActionScenarios = class
  public
    /// <summary>The header of the table of tiles that the scenarios use: "H n" and n lines</summary>
    class function TileTable: TBytes; static;
    class function Generate(APerAction: Integer): TArray<TKeenScenario>; static;
    /// <summary>The text that the C harness reads (SCEN.TXT)</summary>
    class function DirectionOf(AXAxis, AYAxis: Integer): TKeenDirection; static;
    class function ToHarnessText(const AScenarios: TArray<TKeenScenario>): string; static;
    /// <summary>What the actions do in a scenario: the same text as the harness writes, from "S" to "E"</summary>
    class function Run(const AScenario: TKeenScenario): string; static;
    class function Hash(const AText: string): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.StateTable, DelphiDoom.Keen.TileInfo,
  DelphiDoom.Keen.WorkingMap, DelphiDoom.Keen.ActionContext, DelphiDoom.Keen.GameActions, DelphiDoom.Keen.PlayState,
  DelphiDoom.Keen.ObjectList, DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache,
  DelphiDoom.Keen.Refresh, DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.PlayerActions,
  DelphiDoom.Tests.Keen.VideoFakes, DelphiDoom.Tests.Keen.GameWorld;

const
  // tile, north, east, south, west, intile
  TILE_DEFS: array[0..8, 0..5] of Byte = (
    (0, 0, 0, 0, 0, 0), (1, 1, 1, 1, 1, 0), (2, 1, 0, 0, 0, 0), (3, 0, 0, 1, 0, 0), (4, 0, 0, 0, 0, 1),
    (5, 0, 0, 17, 0, 1), (6, 17, 0, 0, 0, 1), (7, 0, 1, 0, 1, 0), (8, 2, 0, 0, 0, 0));

var
  FWorld: TKeenTestWorld;

type
  /// <summary>xorshift32: the same numbers on every machine</summary>
  TScenarioRandom = record
    State: Cardinal;
    function Next(ALimit: Integer): Integer;
    function Range(AFirst, ALast: Integer): Integer;
    function Chance(APercent: Integer): Boolean;
  end;

  TActionPair = record
    Action: Word;
    Kind: Char;
    States: TArray<Integer>;
  end;

function TScenarioRandom.Next(ALimit: Integer): Integer;
begin
  State := State xor (State shl 13);
  State := State xor (State shr 17);
  State := State xor (State shl 5);
  Result := Integer((State shr 4) mod Cardinal(ALimit));
end;

function TScenarioRandom.Range(AFirst, ALast: Integer): Integer;
begin
  Result := AFirst + Next(ALast - AFirst + 1);
end;

function TScenarioRandom.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

function PairsOfActions: TArray<TActionPair>;
var
  LList: TList<TActionPair>;
  LIndex: Integer;
  LPair: TActionPair;
  LFound: Integer;

  procedure Note(AAction: Word; AKind: Char; AState: Integer);
  var
    LK: Integer;
  begin
    if AAction = KEEN_ACTION_NONE then
      Exit;
    LFound := -1;
    for LK := 0 to LList.Count - 1 do
      if (LList[LK].Action = AAction) and (LList[LK].Kind = AKind) then
        LFound := LK;
    if LFound < 0 then
    begin
      LPair.Action := AAction;
      LPair.Kind := AKind;
      SetLength(LPair.States, 0);
      LList.Add(LPair);
      LFound := LList.Count - 1;
    end;
    LPair := LList[LFound];
    SetLength(LPair.States, Length(LPair.States) + 1);
    LPair.States[High(LPair.States)] := AState;
    LList[LFound] := LPair;
  end;

begin
  LList := TList<TActionPair>.Create;
  try
    for LIndex := 0 to High(KEEN_STATES) do
    begin
      Note(KEEN_STATES[LIndex].Think, 'T', LIndex);
      Note(KEEN_STATES[LIndex].Contact, 'C', LIndex);
      Note(KEEN_STATES[LIndex].React, 'R', LIndex);
    end;
    LList.Sort(TComparer<TActionPair>.Construct(
      function(const ALeft, ARight: TActionPair): Integer
      begin
        Result := ALeft.Action - ARight.Action;
        if Result = 0 then
          Result := Ord(ALeft.Kind) - Ord(ARight.Kind);
      end));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function IsKeenAction(AAction: Word): Boolean;
begin
  Result := Copy(KEEN_ACTION_NAMES[AAction], 1, 4) = 'Keen';
end;

const
  TEMP_POOL: array[0..20] of Integer = (0, 0, 1, 2, 3, 4, 5, 8, 10, 15, 58, 59, 60, 61, 200, 201, 299, 301, 401, 701, -1);
  HIT_POOL: array[0..10] of Integer = (0, 0, 1, 2, 3, 7, 8, 9, 17, 24, 25);

procedure RandomObject(var ARandom: TScenarioRandom; var AObject: TKeenScenarioObject; const APair: TActionPair;
  AUseBias: Boolean);
var
  LIndex: Integer;
begin
  FillChar(AObject, SizeOf(AObject), 0);
  for LIndex := 0 to 3 do
    AObject.TempKind[LIndex] := ' ';
  with ARandom do
  begin
    AObject.Fields[0] := Next(26); // obclass
    AObject.Fields[1] := Next(4); // active
    AObject.Fields[2] := Next(2);
    AObject.Fields[3] := Next(2);
    AObject.Fields[4] := Next(4);
    AObject.Fields[5] := Range(256, 10 * 256 - 1); // x
    AObject.Fields[6] := Range(256, 9 * 256 - 1); // y
    AObject.Fields[7] := Range(-1, 1);
    AObject.Fields[8] := Range(-1, 1);
    AObject.Fields[9] := Range(-60, 60);
    AObject.Fields[10] := Range(-60, 60);
    AObject.Fields[11] := Range(-70, 70);
    AObject.Fields[12] := Range(-90, 90);
    AObject.Fields[13] := Next(25);
    AObject.Fields[14] := Next(5);
    if AUseBias and (Length(APair.States) > 0) and Chance(85) then
      AObject.Fields[15] := APair.States[Next(Length(APair.States))]
    else
      AObject.Fields[15] := Next(Length(KEEN_STATES));
    AObject.Fields[16] := Range(1, 300);
    AObject.Fields[17] := AObject.Fields[5] + Next(33); // left
    AObject.Fields[19] := AObject.Fields[17] + Range(16, 300); // right
    AObject.Fields[18] := AObject.Fields[6] + Next(33); // top
    AObject.Fields[20] := AObject.Fields[18] + Range(16, 300); // bottom
    AObject.Fields[21] := (AObject.Fields[17] + AObject.Fields[19]) div 2;
    AObject.Fields[22] := AObject.Fields[17] shr 8;
    AObject.Fields[23] := AObject.Fields[18] shr 8;
    AObject.Fields[24] := AObject.Fields[19] shr 8;
    AObject.Fields[25] := AObject.Fields[20] shr 8;
    AObject.Fields[26] := AObject.Fields[21] shr 8;
    AObject.Fields[27] := HIT_POOL[Next(Length(HIT_POOL))];
    AObject.Fields[28] := HIT_POOL[Next(Length(HIT_POOL))];
    AObject.Fields[29] := HIT_POOL[Next(Length(HIT_POOL))];
    AObject.Fields[30] := HIT_POOL[Next(Length(HIT_POOL))];
    AObject.Fields[31] := TEMP_POOL[Next(Length(TEMP_POOL))];
    AObject.Fields[32] := TEMP_POOL[Next(Length(TEMP_POOL))];
    AObject.Fields[33] := TEMP_POOL[Next(Length(TEMP_POOL))];
    AObject.Fields[34] := Next(16); // a column of the map
  end;
end;

{ TKeenActionScenarios }

class function TKeenActionScenarios.TileTable: TBytes;
var
  LIndex: Integer;
  LTile: Integer;
begin
  SetLength(Result, KEEN_TINF_SIZE);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to High(TILE_DEFS) do
  begin
    LTile := TILE_DEFS[LIndex, 0];
    Result[KEEN_TINF_NORTHWALL + LTile] := TILE_DEFS[LIndex, 1];
    Result[KEEN_TINF_EASTWALL + LTile] := TILE_DEFS[LIndex, 2];
    Result[KEEN_TINF_SOUTHWALL + LTile] := TILE_DEFS[LIndex, 3];
    Result[KEEN_TINF_WESTWALL + LTile] := TILE_DEFS[LIndex, 4];
    Result[KEEN_TINF_INTILE + LTile] := TILE_DEFS[LIndex, 5];
  end;
end;

class function TKeenActionScenarios.Generate(APerAction: Integer): TArray<TKeenScenario>;
var
  LPairs: TArray<TActionPair>;
  LList: TList<TKeenScenario>;
  LRandom: TScenarioRandom;
  LPair: TActionPair;
  LScenario: TKeenScenario;
  LCount: Integer;
  LIndex: Integer;
  LObjects: Integer;
  LName: string;
  LHitStates: array[0..5] of Integer;
begin
  LHitStates[0] := KEEN_STATE_S_TATERATTACK2;
  LHitStates[1] := KEEN_STATE_S_BROCCOSMASH3;
  LHitStates[2] := KEEN_STATE_S_BROCCOSMASH4;
  LHitStates[3] := KEEN_STATE_S_SQUASHERJUMP2;
  LHitStates[4] := KEEN_STATE_S_GRAPEFALL;
  LHitStates[5] := KEEN_STATE_S_DOORRAISE;
  LPairs := PairsOfActions;
  LRandom.State := 2463534242;
  LList := TList<TKeenScenario>.Create;
  try
    for LPair in LPairs do
    begin
      LName := KEEN_ACTION_NAMES[LPair.Action];
      if LName = 'ScoreThink' then
        Continue; // draws into the sprite memory: not in the harness
      for LCount := 1 to APerAction do
      begin
        FillChar(LScenario, SizeOf(LScenario), 0);
        LScenario.Name := LName;
        LScenario.Kind := LPair.Kind;
        LScenario.Action := LPair.Action;
        with LRandom do
        begin
          LScenario.XAxis := Range(-1, 1);
          LScenario.YAxis := Range(-1, 1);
          LScenario.Button0 := Chance(40);
          LScenario.Button1 := Chance(30);
          LScenario.Held0 := Chance(30);
          LScenario.Held1 := Chance(30);
          LScenario.Tics := Range(1, 6);
          LScenario.LastTime := Range(100, 5000);
          LScenario.Time := LScenario.LastTime - Next(40);
          LScenario.OriginXTile := Next(8);
          LScenario.OriginYTile := Next(4);
          LScenario.OriginXGlobal := LScenario.OriginXTile * 256 + Next(256);
          LScenario.OriginYGlobal := LScenario.OriginYTile * 256 + Next(256);
          LScenario.OriginXTileMax := LScenario.OriginXTile + 20;
          LScenario.OriginYTileMax := LScenario.OriginYTile + 13;
          LScenario.GameMapOn := Next(18);
          if Chance(35) then
            LScenario.MapOn := 15
          else
            LScenario.MapOn := Next(18);
          LScenario.Keys := Next(3);
          LScenario.Bombs := Next(15);
          LScenario.Flowers := Next(6);
          LScenario.Lives := Range(1, 11);
          LScenario.Difficulty := Next(4);
          LScenario.God := Chance(10);
          LScenario.JumpCheat := Chance(10);
          LScenario.JumpTime := Next(17);
          if Chance(50) then
            LScenario.LeavePoleTime := 0
          else
            LScenario.LeavePoleTime := LScenario.Time - Next(40) + Next(10);
          case Next(3) of
            0: LScenario.Score := Next(1000);
            1: LScenario.Score := 19900 + Next(100);
          else
            LScenario.Score := 100000 + Next(1000);
          end;
          LScenario.WorldX := Next(2000);
          LScenario.WorldY := Next(2000);
          LScenario.BombsThisLevel := Next(5);
          SetLength(LScenario.Rnd, 40);
          for LIndex := 0 to 39 do
            LScenario.Rnd[LIndex] := Next(256);
          SetLength(LScenario.Plane1, SCENARIO_MAP_SIDE * SCENARIO_MAP_SIDE);
          SetLength(LScenario.Plane2, SCENARIO_MAP_SIDE * SCENARIO_MAP_SIDE);
          for LIndex := 0 to SCENARIO_MAP_SIDE * SCENARIO_MAP_SIDE - 1 do
          begin
            if Chance(50) then
              LScenario.Plane1[LIndex] := 0
            else
              LScenario.Plane1[LIndex] := Next(9);
            if Chance(70) then
              LScenario.Plane2[LIndex] := 0
            else
              LScenario.Plane2[LIndex] := Next(21);
          end;
        end;
        LObjects := 4;
        if LName = 'KeenSleepThink' then
          LObjects := 5;
        SetLength(LScenario.Objects, LObjects);
        for LIndex := 0 to LObjects - 1 do
          RandomObject(LRandom, LScenario.Objects[LIndex], LPair, LIndex = 2);
        // slot 0 is the player, 1 the score box
        if IsKeenAction(LPair.Action) then
        begin
          LScenario.ObSel := 0;
          RandomObject(LRandom, LScenario.Objects[0], LPair, True);
        end
        else
          LScenario.ObSel := 2;
        LScenario.HitSel := 3;
        if (LName = 'KeenWorldThink') or (LName = 'KeenWorldWalk') then
        begin
          // the shapes of the walk are tables of 8 and 4 entries: the C reads other memory for a bigger index
          LScenario.Objects[0].Fields[SCENARIO_FIRST_TEMP] := LRandom.Next(8);
          LScenario.Objects[0].Fields[SCENARIO_FIRST_TEMP + 1] := LRandom.Next(4);
        end;
        // situations that a random control rarely gives: nobody touches the control (the player gets bored and
        // goes to sleep), a jump with the throw button, the poles with the throw button
        if ((LName = 'KeenPauseThink') or (LName = 'KeenSleepThink')) and LRandom.Chance(70) then
        begin
          LScenario.XAxis := 0;
          LScenario.YAxis := 0;
          LScenario.Button0 := False;
          LScenario.Button1 := False;
        end;
        if (LName = 'KeenAirThink') or (LName = 'KeenPoleThink') or (LName = 'KeenClimbThink') or
          (LName = 'KeenDropThink') then
        begin
          LScenario.Button1 := LRandom.Chance(70);
          LScenario.Held1 := LRandom.Chance(20);
        end;
        if (LName = 'ProjectileReact') or (LName = 'PowerReact') then
        begin
          // the speed is small half of the times, so the shot stops; the south wall is rare
          if LRandom.Chance(50) then
          begin
            LScenario.Objects[2].Fields[11] := LRandom.Range(-8, 8);
            LScenario.Objects[2].Fields[12] := LRandom.Range(0, 8);
          end;
          if LRandom.Chance(60) then
            LScenario.Objects[2].Fields[29] := 0;          // bounceangle has 8 rows: the C reads other memory for a bigger wall number (17 is a pole hole)
          LScenario.Objects[2].Fields[27] := LRandom.Next(8);
          if (LName = 'PowerReact') and LRandom.Chance(20) then
            LScenario.Objects[2].Fields[27] := 17;
        end;
        if LPair.Kind = 'C' then
        begin
          if LRandom.Chance(50) then
            LScenario.Objects[3].Fields[15] := LHitStates[LRandom.Next(6)];
        end;
        if LName = 'KeenThrow' then
          LScenario.Objects[0].Fields[15] := LPair.States[LRandom.Next(Length(LPair.States))];
        if LName = 'KeenSleepThink' then
        begin
          LScenario.Objects[0].Fields[SCENARIO_FIRST_TEMP] := 4;
          LScenario.Objects[0].TempKind[0] := '@';
        end;
        if LName = 'ChangeFromFlower' then
        begin
          LScenario.Objects[2].Fields[SCENARIO_FIRST_TEMP] := 3;
          LScenario.Objects[2].TempKind[0] := '@';
          LScenario.Objects[3].Fields[SCENARIO_FIRST_TEMP + 1] := LRandom.Next(Length(KEEN_STATES));
          LScenario.Objects[3].TempKind[1] := '$';
          LScenario.Objects[3].Fields[SCENARIO_FIRST_TEMP] := LRandom.Next(26);
        end;
        LList.Add(LScenario);
      end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TKeenActionScenarios.DirectionOf(AXAxis, AYAxis: Integer): TKeenDirection;
begin
  Result := kdNone;
  case AYAxis of
    -1:
      case AXAxis of
        -1: Result := kdNorthWest;
        0: Result := kdNorth;
        1: Result := kdNorthEast;
      end;
    0:
      case AXAxis of
        -1: Result := kdWest;
        1: Result := kdEast;
      end;
    1:
      case AXAxis of
        -1: Result := kdSouthWest;
        0: Result := kdSouth;
        1: Result := kdSouthEast;
      end;
  end;
end;

class function TKeenActionScenarios.ToHarnessText(const AScenarios: TArray<TKeenScenario>): string;
var
  LBuilder: TStringBuilder;
  LScenario: TKeenScenario;
  LDef: Integer;
  LValue: Integer;
  LObject: TKeenScenarioObject;
  LIndex: Integer;
  LDirection: Integer;

  procedure Int(AValue: Integer);
  begin
    LBuilder.Append(' ').Append(AValue);
  end;

  procedure Bool(AValue: Boolean);
  begin
    if AValue then
      Int(1)
    else
      Int(0);
  end;

begin
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.Append('H ').Append(Length(TILE_DEFS)).Append(#10);
    for LDef := 0 to High(TILE_DEFS) do
    begin
      for LValue := 0 to 5 do
        Int(TILE_DEFS[LDef, LValue]);
      LBuilder.Append(#10);
    end;
    for LScenario in AScenarios do
    begin
      LBuilder.Append('S ').Append(LScenario.Name).Append(' ').Append(LScenario.Kind).Append(#10);
      LDirection := Ord(DirectionOf(LScenario.XAxis, LScenario.YAxis));
      LBuilder.Append('CTL');
      Int(LScenario.XAxis);
      Int(LScenario.YAxis);
      Int(LDirection);
      Bool(LScenario.Button0);
      Bool(LScenario.Button1);
      Bool(LScenario.Held0);
      Bool(LScenario.Held1);
      LBuilder.Append(#10'GLB');
      Int(LScenario.Tics);
      Int(LScenario.LastTime);
      Int(LScenario.Time);
      Int(LScenario.OriginXTile);
      Int(LScenario.OriginYTile);
      Int(LScenario.OriginXGlobal);
      Int(LScenario.OriginYGlobal);
      Int(LScenario.OriginXTileMax);
      Int(LScenario.OriginYTileMax);
      Int(LScenario.GameMapOn);
      Int(LScenario.MapOn);
      Int(LScenario.Keys);
      Int(LScenario.Bombs);
      Int(LScenario.Flowers);
      Int(LScenario.Lives);
      Int(LScenario.Difficulty);
      Bool(LScenario.God);
      Bool(LScenario.JumpCheat);
      Int(LScenario.JumpTime);
      Int(LScenario.LeavePoleTime);
      Int(LScenario.Score);
      Int(LScenario.WorldX);
      Int(LScenario.WorldY);
      Int(LScenario.BombsThisLevel);
      LBuilder.Append(#10'RND ').Append(Length(LScenario.Rnd));
      for LValue in LScenario.Rnd do
        Int(LValue);
      LBuilder.Append(#10'MAP ').Append(SCENARIO_MAP_SIDE).Append(' ').Append(SCENARIO_MAP_SIDE);
      for LValue in LScenario.Plane1 do
        Int(LValue);
      for LValue in LScenario.Plane2 do
        Int(LValue);
      LBuilder.Append(#10'OBJ ').Append(Length(LScenario.Objects));
      for LObject in LScenario.Objects do
      begin
        for LIndex := 0 to SCENARIO_FIELDS - 1 do
          if (LIndex >= SCENARIO_FIRST_TEMP) and (LObject.TempKind[LIndex - SCENARIO_FIRST_TEMP] <> ' ') then
            LBuilder.Append(' ').Append(LObject.TempKind[LIndex - SCENARIO_FIRST_TEMP]).Append(LObject.Fields[LIndex])
          else
            Int(LObject.Fields[LIndex]);
      end;
      LBuilder.Append(#10'SEL');
      Int(LScenario.ObSel);
      Int(LScenario.HitSel);
      LBuilder.Append(#10);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TKeenActionScenarios.Hash(const AText: string): Cardinal;
var
  LBytes: TBytes;
  LByte: Byte;
begin
  Result := 2166136261;
  LBytes := TEncoding.UTF8.GetBytes(AText);
  for LByte in LBytes do
    Result := (Result xor LByte) * 16777619;
end;

type
  /// <summary>Where everything that the actions do is written, in the format of the C harness</summary>
  TActionLog = class
  public
    Text: TStringBuilder;
    Quiet: Boolean;
    MaxSlot: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Line(const AText: string);
  end;

  TLoggingObjects = class(TInterfacedObject, IKeenObjectList)
  strict private
    FList: IKeenObjectList;
    FLog: TActionLog;
  public
    constructor Create(const AList: IKeenObjectList; ALog: TActionLog);
    function GetCount: Integer;
    function GetNew: PKeenObject;
    function GetPlayer: PKeenObject;
    function GetScoreObj: PKeenObject;
    function GetFirst: PKeenObject;
    function GetObject(ASlot: Integer): PKeenObject;
    procedure Init;
    function GetNewObj(AUseDummy: Boolean): PKeenObject;
    procedure RemoveObj(AGone: PKeenObject);
    function NextOf(AObject: PKeenObject): PKeenObject;
  end;

  TLoggingEvents = class(TInterfacedObject, IKeenGameEvents)
  strict private
    FLog: TActionLog;
    FGod: Boolean;
    FJumpCheat: Boolean;
  public
    constructor Create(ALog: TActionLog; AGod, AJumpCheat: Boolean);
    procedure KillKeen;
    procedure PlaySound(ASound: Integer);
    procedure CheckKeys;
    function IsGameLoaded: Boolean;
    procedure BeginPlay;
    procedure ClearGodMode;
    function IsGodMode: Boolean;
    function IsJumpCheat: Boolean;
    procedure ShowNeedBombs;
  end;

  TLoggingRandom = class(TInterfacedObject, IKeenRandom)
  strict private
    FLog: TActionLog;
    FValues: TArray<Integer>;
    FPosition: Integer;
  public
    constructor Create(ALog: TActionLog; const AValues: TArray<Integer>);
    procedure Initialize(ARandomize: Boolean; ATime: Integer);
    function RndT: Byte;
  end;

  TLoggingPlay = class(TInterfacedObject, IKeenPlayState)
  strict private
    FLog: TActionLog;
    FInner: IKeenPlayState;
  public
    constructor Create(ALog: TActionLog; const AInner: IKeenPlayState);
    function GetControl: TKeenControlInfo;
    procedure SetControl(const AValue: TKeenControlInfo);
    function GetButton0Held: Boolean;
    procedure SetButton0Held(AValue: Boolean);
    function GetButton1Held: Boolean;
    procedure SetButton1Held(AValue: Boolean);
    function GetPlayState: TKeenExit;
    procedure SetPlayState(AValue: TKeenExit);
    function GetGameState: PKeenGameState;
    function GetMapOn: Integer;
    procedure SetMapOn(AValue: Integer);
    procedure GivePoints(APoints: Integer);
  end;

  TLoggingView = class(TInterfacedObject, IKeenActionView)
  strict private
    FLog: TActionLog;
    FObjects: IKeenObjectList;
    FScenario: ^TKeenScenario;
    function SlotOf(var AUser: TKeenSpriteHandle): Integer;
  public
    constructor Create(ALog: TActionLog; const AObjects: IKeenObjectList; const AScenario: TKeenScenario);
    function GetTics: Integer;
    function GetLastTimeCount: Integer;
    function GetTimeCount: Integer;
    function GetOriginXGlobal: Integer;
    function GetOriginYGlobal: Integer;
    function GetOriginXTile: Integer;
    function GetOriginYTile: Integer;
    function GetOriginXTileMax: Integer;
    function GetOriginYTileMax: Integer;
    procedure PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk, APriority: Integer);
    procedure RemoveSprite(var AUser: TKeenSpriteHandle);
  end;

  TLoggingPhysics = class(TInterfacedObject, IKeenActorPhysics)
  strict private
    FLog: TActionLog;
    FStates: IKeenStateTable;
  public
    constructor Create(ALog: TActionLog; const AStates: IKeenStateTable);
    procedure ClipToWalls(AObject: PKeenObject);
    procedure ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
    procedure ClipToSpriteSide(APush, ASolid: PKeenObject);
    procedure NewState(AObject: PKeenObject; AState: Integer);
  end;

{ TActionLog }

constructor TActionLog.Create;
begin
  inherited Create;
  Text := TStringBuilder.Create;
end;

destructor TActionLog.Destroy;
begin
  Text.Free;
  inherited Destroy;
end;

procedure TActionLog.Line(const AText: string);
begin
  Text.Append(AText).Append(#10);
end;

{ TLoggingObjects }

constructor TLoggingObjects.Create(const AList: IKeenObjectList; ALog: TActionLog);
begin
  inherited Create;
  FList := AList;
  FLog := ALog;
end;

function TLoggingObjects.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TLoggingObjects.GetNew: PKeenObject;
begin
  Result := FList.New;
end;

function TLoggingObjects.GetPlayer: PKeenObject;
begin
  Result := FList.Player;
end;

function TLoggingObjects.GetScoreObj: PKeenObject;
begin
  Result := FList.ScoreObj;
end;

function TLoggingObjects.GetFirst: PKeenObject;
begin
  Result := FList.First;
end;

function TLoggingObjects.GetObject(ASlot: Integer): PKeenObject;
begin
  Result := FList[ASlot];
end;

procedure TLoggingObjects.Init;
begin
  FList.Init;
end;

function TLoggingObjects.GetNewObj(AUseDummy: Boolean): PKeenObject;
begin
  Result := FList.GetNewObj(AUseDummy);
  if Result^.Slot < KEEN_DUMMY_SLOT then
  begin
    if Result^.Slot > FLog.MaxSlot then
      FLog.MaxSlot := Result^.Slot;
    if not FLog.Quiet then
      FLog.Line(Format('newobj %d', [Result^.Slot]));
  end;
end;

procedure TLoggingObjects.RemoveObj(AGone: PKeenObject);
begin
  FLog.Line(Format('remove %d', [AGone^.Slot]));
  FLog.Line(Format('rmsprite %d', [AGone^.Slot]));
  FList.RemoveObj(AGone);
end;

function TLoggingObjects.NextOf(AObject: PKeenObject): PKeenObject;
begin
  Result := FList.NextOf(AObject);
end;

{ TLoggingEvents }

constructor TLoggingEvents.Create(ALog: TActionLog; AGod, AJumpCheat: Boolean);
begin
  inherited Create;
  FLog := ALog;
  FGod := AGod;
  FJumpCheat := AJumpCheat;
end;

procedure TLoggingEvents.KillKeen;
begin
end;

procedure TLoggingEvents.PlaySound(ASound: Integer);
begin
  FLog.Line(Format('snd %d', [ASound]));
end;

procedure TLoggingEvents.CheckKeys;
begin
end;

function TLoggingEvents.IsGameLoaded: Boolean;
begin
  Result := False;
end;

procedure TLoggingEvents.BeginPlay;
begin
end;

procedure TLoggingEvents.ClearGodMode;
begin
end;

function TLoggingEvents.IsGodMode: Boolean;
begin
  Result := FGod;
end;

function TLoggingEvents.IsJumpCheat: Boolean;
begin
  Result := FJumpCheat;
end;

procedure TLoggingEvents.ShowNeedBombs;
begin
  FLog.Line('needbombs');
end;

{ TLoggingRandom }

constructor TLoggingRandom.Create(ALog: TActionLog; const AValues: TArray<Integer>);
begin
  inherited Create;
  FLog := ALog;
  FValues := AValues;
end;

procedure TLoggingRandom.Initialize(ARandomize: Boolean; ATime: Integer);
begin
end;

function TLoggingRandom.RndT: Byte;
var
  LValue: Integer;
begin
  LValue := 0;
  if FPosition < Length(FValues) then
    LValue := FValues[FPosition];
  Inc(FPosition);
  FLog.Line(Format('rnd %d', [LValue]));
  Result := Byte(LValue);
end;

{ TLoggingPlay }

constructor TLoggingPlay.Create(ALog: TActionLog; const AInner: IKeenPlayState);
begin
  inherited Create;
  FLog := ALog;
  FInner := AInner;
end;

function TLoggingPlay.GetControl: TKeenControlInfo;
begin
  Result := FInner.Control;
end;

procedure TLoggingPlay.SetControl(const AValue: TKeenControlInfo);
begin
  FInner.Control := AValue;
end;

function TLoggingPlay.GetButton0Held: Boolean;
begin
  Result := FInner.Button0Held;
end;

procedure TLoggingPlay.SetButton0Held(AValue: Boolean);
begin
  FInner.Button0Held := AValue;
end;

function TLoggingPlay.GetButton1Held: Boolean;
begin
  Result := FInner.Button1Held;
end;

procedure TLoggingPlay.SetButton1Held(AValue: Boolean);
begin
  FInner.Button1Held := AValue;
end;

function TLoggingPlay.GetPlayState: TKeenExit;
begin
  Result := FInner.PlayState;
end;

procedure TLoggingPlay.SetPlayState(AValue: TKeenExit);
begin
  FInner.PlayState := AValue;
end;

function TLoggingPlay.GetGameState: PKeenGameState;
begin
  Result := FInner.GameState;
end;

function TLoggingPlay.GetMapOn: Integer;
begin
  Result := FInner.MapOn;
end;

procedure TLoggingPlay.SetMapOn(AValue: Integer);
begin
  FInner.MapOn := AValue;
end;

procedure TLoggingPlay.GivePoints(APoints: Integer);
begin
  FLog.Line(Format('points %d', [APoints]));
  FInner.GivePoints(APoints);
end;

{ TLoggingView }

constructor TLoggingView.Create(ALog: TActionLog; const AObjects: IKeenObjectList; const AScenario: TKeenScenario);
begin
  inherited Create;
  FLog := ALog;
  FObjects := AObjects;
  New(FScenario);
  FScenario^ := AScenario;
end;

function TLoggingView.SlotOf(var AUser: TKeenSpriteHandle): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to KEEN_MAXACTORS - 1 do
    if @AUser = @FObjects[LIndex]^.Sprite then
      Result := LIndex;
end;

function TLoggingView.GetTics: Integer;
begin
  Result := FScenario^.Tics;
end;

function TLoggingView.GetLastTimeCount: Integer;
begin
  Result := FScenario^.LastTime;
end;

function TLoggingView.GetTimeCount: Integer;
begin
  Result := FScenario^.Time;
end;

function TLoggingView.GetOriginXGlobal: Integer;
begin
  Result := FScenario^.OriginXGlobal;
end;

function TLoggingView.GetOriginYGlobal: Integer;
begin
  Result := FScenario^.OriginYGlobal;
end;

function TLoggingView.GetOriginXTile: Integer;
begin
  Result := FScenario^.OriginXTile;
end;

function TLoggingView.GetOriginYTile: Integer;
begin
  Result := FScenario^.OriginYTile;
end;

function TLoggingView.GetOriginXTileMax: Integer;
begin
  Result := FScenario^.OriginXTileMax;
end;

function TLoggingView.GetOriginYTileMax: Integer;
begin
  Result := FScenario^.OriginYTileMax;
end;

procedure TLoggingView.PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk,
  APriority: Integer);
begin
  FLog.Line(Format('place %d %u %u %u %d', [SlotOf(AUser), Word(AGlobalX), Word(AGlobalY), Word(ASpriteChunk),
    APriority]));
  AUser := 1;
end;

procedure TLoggingView.RemoveSprite(var AUser: TKeenSpriteHandle);
begin
  FLog.Line(Format('rmsprite %d', [SlotOf(AUser)]));
  AUser := 0;
end;

{ TLoggingPhysics }

constructor TLoggingPhysics.Create(ALog: TActionLog; const AStates: IKeenStateTable);
begin
  inherited Create;
  FLog := ALog;
  FStates := AStates;
end;

procedure TLoggingPhysics.ClipToWalls(AObject: PKeenObject);
begin
  FLog.Line(Format('clip %d', [AObject^.Slot]));
end;

procedure TLoggingPhysics.ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
begin
  FLog.Line(Format('clipsprite %d %d %d', [APush^.Slot, ASolid^.Slot, Ord(ASquish)]));
end;

procedure TLoggingPhysics.ClipToSpriteSide(APush, ASolid: PKeenObject);
begin
  FLog.Line(Format('clipside %d %d', [APush^.Slot, ASolid^.Slot]));
end;

procedure TLoggingPhysics.NewState(AObject: PKeenObject; AState: Integer);
var
  LDef: TKeenStateDef;
begin
  FLog.Line(Format('newstate %d %d', [AObject^.Slot, AState]));
  AObject^.State := AState;
  LDef := FStates[AState];
  if LDef.RightShape <> 0 then
  begin
    if AObject^.XDir > 0 then
      AObject^.ShapeNum := Word(LDef.RightShape)
    else
      AObject^.ShapeNum := Word(LDef.LeftShape);
  end;
end;

procedure LoadObject(AObject: PKeenObject; const ASource: TKeenScenarioObject);
begin
  AObject^.ObClass := TKeenClass(ASource.Fields[0]);
  AObject^.Active := TKeenActive(ASource.Fields[1]);
  AObject^.NeedToReact := ASource.Fields[2] <> 0;
  AObject^.NeedToClip := ASource.Fields[3] <> 0;
  AObject^.NoThink := Word(ASource.Fields[4]);
  AObject^.X := Word(ASource.Fields[5]);
  AObject^.Y := Word(ASource.Fields[6]);
  AObject^.XDir := SmallInt(ASource.Fields[7]);
  AObject^.YDir := SmallInt(ASource.Fields[8]);
  AObject^.XMove := SmallInt(ASource.Fields[9]);
  AObject^.YMove := SmallInt(ASource.Fields[10]);
  AObject^.XSpeed := SmallInt(ASource.Fields[11]);
  AObject^.YSpeed := SmallInt(ASource.Fields[12]);
  AObject^.TicCount := SmallInt(ASource.Fields[13]);
  AObject^.TicAdjust := SmallInt(ASource.Fields[14]);
  AObject^.State := SmallInt(ASource.Fields[15]);
  AObject^.ShapeNum := Word(ASource.Fields[16]);
  AObject^.Left := Word(ASource.Fields[17]);
  AObject^.Top := Word(ASource.Fields[18]);
  AObject^.Right := Word(ASource.Fields[19]);
  AObject^.Bottom := Word(ASource.Fields[20]);
  AObject^.MidX := Word(ASource.Fields[21]);
  AObject^.TileLeft := Word(ASource.Fields[22]);
  AObject^.TileTop := Word(ASource.Fields[23]);
  AObject^.TileRight := Word(ASource.Fields[24]);
  AObject^.TileBottom := Word(ASource.Fields[25]);
  AObject^.TileMidX := Word(ASource.Fields[26]);
  AObject^.HitNorth := SmallInt(ASource.Fields[27]);
  AObject^.HitEast := SmallInt(ASource.Fields[28]);
  AObject^.HitSouth := SmallInt(ASource.Fields[29]);
  AObject^.HitWest := SmallInt(ASource.Fields[30]);
  AObject^.Temp1 := SmallInt(ASource.Fields[31]);
  AObject^.Temp2 := SmallInt(ASource.Fields[32]);
  AObject^.Temp3 := SmallInt(ASource.Fields[33]);
  AObject^.Temp4 := SmallInt(ASource.Fields[34]);
end;

function DumpObject(AObject: PKeenObject): string;
begin
  Result := Format('obj %d %d %d %d %d %d %u %u %d %d %d %d %d %d %d %d %d %u %u %u %u %u %u %u %u %u %u %u %d %d %d %d %d %d %d %d',
    [AObject^.Slot, Ord(AObject^.ObClass), Ord(AObject^.Active), Ord(AObject^.NeedToReact),
    Ord(AObject^.NeedToClip), SmallInt(AObject^.NoThink), AObject^.X, AObject^.Y, AObject^.XDir, AObject^.YDir,
    AObject^.XMove, AObject^.YMove, AObject^.XSpeed, AObject^.YSpeed, AObject^.TicCount, AObject^.TicAdjust,
    AObject^.State, AObject^.ShapeNum, AObject^.Left, AObject^.Top, AObject^.Right, AObject^.Bottom, AObject^.MidX,
    AObject^.TileLeft, AObject^.TileTop, AObject^.TileRight, AObject^.TileBottom, AObject^.TileMidX,
    AObject^.HitNorth, AObject^.HitEast, AObject^.HitSouth, AObject^.HitWest, AObject^.Temp1, AObject^.Temp2,
    AObject^.Temp3, AObject^.Temp4]);
end;

class function TKeenActionScenarios.Run(const AScenario: TKeenScenario): string;
var
  LLog: TActionLog;
  LList: IKeenObjectList;
  LEvents: IKeenGameEvents;
  LPlayInner: IKeenPlayState;
  LPlay: IKeenPlayState;
  LMap: IKeenWorkingMap;
  LContext: IKeenActionContext;
  LGame: TKeenGameActions;
  LActions: IKeenActions;
  LControl: TKeenControlInfo;
  LState: PKeenGameState;
  LIndex: Integer;
  LObject: PKeenObject;
  LHit: PKeenObject;
begin
  if not Assigned(FWorld) then
    FWorld := TKeenTestWorld.Create(SCENARIO_MAP_SIDE, SCENARIO_MAP_SIDE, KEEN_STATES);
  LLog := TActionLog.Create;
  try
    LList := TLoggingObjects.Create(FWorld.Objects, LLog);
    LEvents := TLoggingEvents.Create(LLog, AScenario.God, AScenario.JumpCheat);
    LPlayInner := TKeenPlayState.Create(LEvents);
    LPlay := TLoggingPlay.Create(LLog, LPlayInner);
    LLog.Quiet := True;
    LList.Init;
    LLog.MaxSlot := 1;
    for LIndex := 2 to High(AScenario.Objects) do
      LList.GetNewObj(False);
    for LIndex := 0 to High(AScenario.Objects) do
      LoadObject(LList[LIndex], AScenario.Objects[LIndex]);
    LLog.Quiet := False;
    LMap := TKeenWorkingMap.Create(SCENARIO_MAP_SIDE, SCENARIO_MAP_SIDE);
    for LIndex := 0 to SCENARIO_MAP_SIDE * SCENARIO_MAP_SIDE - 1 do
    begin
      LMap.Planes[1][LIndex] := Word(AScenario.Plane1[LIndex]);
      LMap.Planes[2][LIndex] := Word(AScenario.Plane2[LIndex]);
    end;
    FillChar(LControl, SizeOf(LControl), 0);
    LControl.XAxis := AScenario.XAxis;
    LControl.YAxis := AScenario.YAxis;
    LControl.Direction := DirectionOf(AScenario.XAxis, AScenario.YAxis);
    LControl.Button0 := AScenario.Button0;
    LControl.Button1 := AScenario.Button1;
    LPlay.Control := LControl;
    LPlay.Button0Held := AScenario.Held0;
    LPlay.Button1Held := AScenario.Held1;
    LPlay.MapOn := AScenario.MapOn;
    LState := LPlay.GameState;
    LState^.MapOn := AScenario.GameMapOn;
    LState^.Keys := AScenario.Keys;
    LState^.BoobusBombs := AScenario.Bombs;
    LState^.FlowerPowers := AScenario.Flowers;
    LState^.Lives := AScenario.Lives;
    LState^.Difficulty := AScenario.Difficulty;
    LState^.Score := AScenario.Score;
    LState^.WorldX := Word(AScenario.WorldX);
    LState^.WorldY := Word(AScenario.WorldY);
    LState^.BombsThisLevel := AScenario.BombsThisLevel;
    LState^.NextExtra := 20000;
    LContext := TKeenActionContext.Create(LList, FWorld.States, TLoggingRandom.Create(LLog, AScenario.Rnd),
      LEvents, TLoggingView.Create(LLog, LList, AScenario), TLoggingPhysics.Create(LLog, FWorld.States), LPlay, LMap,
      TKeenTileInfo.Create(TileTable));
    LGame := TKeenGameActions.Create(LContext, FWorld.Graphics, FWorld.Sprites);
    LActions := LGame;
    LGame.Player.JumpTime := AScenario.JumpTime;
    LGame.Player.LeavePoleTime := AScenario.LeavePoleTime;
    LLog.Text.Clear;
    LLog.Text.Append('S ').Append(AScenario.Name).Append(' ').Append(AScenario.Kind).Append(#10);
    LObject := LList[AScenario.ObSel];
    LHit := LList[AScenario.HitSel];
    case AScenario.Kind of
      'T': LActions.Think(AScenario.Action, LObject);
      'C': LActions.Contact(AScenario.Action, LObject, LHit);
      'R': LActions.React(AScenario.Action, LObject);
    end;
    LLog.Line(Format('state %d %d %d %d %d %d %d %d %d %u %u %d', [Ord(LPlay.PlayState), LState^.Score,
      LState^.NextExtra, LState^.Lives, LState^.FlowerPowers, LState^.BoobusBombs, LState^.BombsThisLevel,
      LState^.Keys, LState^.MapOn, LState^.WorldX, LState^.WorldY, Ord(AScenario.God)]));
    LLog.Line(Format('flags %d %d %d %d', [Ord(LPlay.Button0Held), Ord(LPlay.Button1Held),
      LGame.Player.JumpTime, LGame.Player.LeavePoleTime]));
    LLog.Line(Format('new %d', [LList.New^.Slot]));
    for LIndex := 0 to LLog.MaxSlot do
      LLog.Line(DumpObject(LList[LIndex]));
    LLog.Line('E');
    Result := LLog.Text.ToString;
  finally
    LLog.Free;
  end;
end;

initialization

finalization
  FWorld.Free;

end.
