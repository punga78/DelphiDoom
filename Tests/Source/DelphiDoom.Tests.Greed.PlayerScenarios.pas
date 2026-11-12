{******************************************************************************}
{                                                                              }
{  DelphiDoom: scenarios for the control of the player of the greed library     }
{  (the same scenarios run on the original ControlMovement and fireweapon of    }
{  xGreed in Tools\Verifica\175-player and on TGreedPlayerControl in the tests) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PlayerScenarios;

// the generator and the hashes wrap
{$Q-}
{$R-}
{$H+}

interface

uses
  System.SysUtils;

const
  PLAYER_TILES = 64 * 64;
  PLAYER_MAP_SIZE = 64;
  PLAYER_FRACUNIT = 1 shl 16;
  PLAYER_TILE_UNIT = 1 shl 22;
  PLAYER_SCENARIO_COUNT = 36;
  PLAYER_MAP_COUNT = 6;
  PLAYER_DOOR_COUNT = 8;
  PLAYER_ELEVATOR_COUNT = 6;
  /// <summary>A line of the golden file has the hash of the tics so far every this many tics</summary>
  PLAYER_CHECKPOINT = 25;
  PLAYER_WINDOW_WIDTH = 320;
  PLAYER_WINDOW_HEIGHT = 200;

  // ---- the keys of the keyboard that the scenarios press (the scan code is in PLAYER_SCAN_CODES) ----
  PK_UP = 0;
  PK_RIGHT = 1;
  PK_DOWN = 2;
  PK_LEFT = 3;
  PK_CONTROL = 4;
  PK_ALT = 5;
  PK_SPACE = 6;
  PK_SHIFT = 7;
  PK_Z = 8;
  PK_X = 9;
  PK_A = 10;
  PK_PAGE_UP = 11;
  PK_PAGE_DOWN = 12;
  PK_HOME = 13;
  PK_COMMA = 14;
  PK_PERIOD = 15;
  PK_INSERT = 16;
  PK_DELETE = 17;
  PK_S = 18;
  PK_ESCAPE = 19;
  PK_F1 = 20;
  PK_F2 = 21;
  PK_F3 = 22;
  PK_F4 = 23;
  PK_F5 = 24;
  PK_F6 = 25;
  PK_F7 = 26;
  PK_F9 = 27;
  PK_F10 = 28;
  PK_Q = 29;
  PK_P = 30;
  PK_MINUS = 31;
  PK_PLUS = 32;
  PK_M = 33;
  PK_H = 34;
  PK_TAB = 35;
  PK_CAPS_LOCK = 36;
  PK_NUM_LOCK = 37;
  PK_1 = 38;
  PK_5 = 42;
  PLAYER_KEY_COUNT = 43;

  /// <summary>The scan code of each key (d_ints_h.pas)</summary>
  PLAYER_SCAN_CODES: array[0..PLAYER_KEY_COUNT - 1] of Integer = (
    $48, $4D, $50, $4B, $1D, $38, $39, $2A, $2C, $2D, $1E, $49, $51, $47, $33, $34, $52, $53, $1F,
    $01, $3B, $3C, $3D, $3E, $3F, $40, $41, $43, $44, $10, $19, $0C, $0D, $32, $23, $0F, $3A, $45,
    $02, $03, $04, $05, $06);
  /// <summary>The character of each key, upper case (ASCIINames of d_ints.pas), #0 if it has none</summary>
  PLAYER_KEY_CHARACTERS: array[0..PLAYER_KEY_COUNT - 1] of AnsiChar = (
    #0, #0, #0, #0, #0, #0, ' ', #0, 'Z', 'X', 'A', #0, #0, #0, ',', '.', #0, #127, 'S',
    #27, #0, #0, #0, #0, #0, #0, #0, #0, #0, 'Q', 'P', '-', '=', 'M', 'H', #9, #0, #0,
    '1', '2', '3', '4', '5');

  // ---- the calls to the rest of the game that both programs write in the log ----
  PLAYER_CALL_SOUND = 1;
  PLAYER_CALL_SPAWN = 2;
  PLAYER_CALL_CHECK_SWITCH = 3;
  PLAYER_CALL_SWITCH_WALL = 4;
  PLAYER_CALL_RUN_EVENT = 5;
  PLAYER_CALL_SET_LIGHTS = 6;
  PLAYER_CALL_LOAD_WEAPON = 7;

  /// <summary>The names of the values of a tic, in the order in which both programs list them</summary>
  PLAYER_VALUE_NAMES: array[0..98] of string = (
    'player', 'player_angle64', 'moverate', 'strafrate', 'fallrate', 'turnrate', 'scrollview', 'headbob',
    'weapbob', 'weapmode', 'weaponychange', 'newweapon', 'changingweapons', 'weaponlowering', 'weapdelay',
    'moveforward', 'falldamage', 'keyboardDelay', 'secretdelay', 'inventorydelay', 'usedelay', 'jumpdelay',
    'inventorytime', 'activatemenu', 'activatehelp', 'QuickExit', 'activatebrief', 'paused', 'resizeScreen',
    'biggerScreen', 'togglemapmode', 'toggleheatmode', 'togglemotionmode', 'ToggleRearView', 'togglegoalitem',
    'toggleautorun', 'toggleautotarget', 'newsong', 'goiright', 'goileft', 'deadrestart', 'useitem',
    'checktrigger', 'autorun', 'autotarget', 'MapZoom', 'screensize', 'adjustvrangle', 'adjustvrdist', 'mousedx',
    'mousedy', 'mousebuttons', 'secretbuf', 'lighting', 'changelight', 'SwitchTime', 'charges', 'chargetimes',
    'probe.x', 'probe.y', 'probe.z', 'probe.angle', 'probe.angle2', 'probe.zadj', 'probe.startspot', 'spritehit',
    'playerhit', 'spriteloc', 'hitx', 'hity', 'doorsound', 'doorx', 'doory', 'doors', 'elevators', 'weapbob1',
    'wx', 'wy', 'weaponx', 'weapony', 'actionflag', 'calls', 'callhash', 'netmsgstatus', 'timecount',
    'player.x', 'player.y', 'player.z', 'player.angle', 'player.mapspot', 'player.currentweapon',
    'player.ammo0', 'player.ammo1', 'player.ammo2', 'player.scrollmin', 'player.scrollmax', 'player.status',
    'player.angst', 'warping');

type
  TPlayerTiles = array[0..PLAYER_TILES - 1] of Byte;
  TPlayerKeys = array[0..PLAYER_KEY_COUNT - 1] of Boolean;
  TPlayerValues = array[0..High(PLAYER_VALUE_NAMES)] of Integer;

  TPlayerDoor = record
    TileX, TileY: Integer;
    /// <summary>orientation_t: 0 horizontal, 1 vertical, 2 horizontal2, 3 vertical2</summary>
    Orientation: Integer;
    Open, Bumpable: Boolean;
  end;

  TPlayerElevator = record
    MapSpot: Integer;
    /// <summary>elevtype: 5 E_SWAP, 6 E_SECRET</summary>
    Kind: Integer;
    Floor, Ceiling, Position: Integer;
  end;

  /// <summary>A synthetic map: an area closed by walls with steps, slopes, water, walls, doors, sprites</summary>
  TPlayerMap = record
    NorthWall, NorthFlags, WestWall, WestFlags: TPlayerTiles;
    FloorPic, FloorFlags, CeilingPic, FloorHeight, CeilingHeight: TPlayerTiles;
    MapFlags, MapSprites: TPlayerTiles;
    /// <summary>switches[x][y] of event.pas: the index is x * 64 + y</summary>
    Switches: TPlayerTiles;
    Doors: array[0..PLAYER_DOOR_COUNT - 1] of TPlayerDoor;
    Elevators: array[0..PLAYER_ELEVATOR_COUNT - 1] of TPlayerElevator;
    StartTileX, StartTileY: Integer;
  end;

  TPlayerScenario = record
    Index: Integer;
    /// <summary>1 .. PLAYER_MAP_COUNT</summary>
    MapSeed: Integer;
    CharType: Integer;
    Tics: Integer;
    Angle: Integer;
    Weapons: array[0..4] of Integer;
    Ammo: array[0..2] of Integer;
    MouseEnabled, InvertTurn, InvertLook: Boolean;
    MouseSensitivity: Integer;
    /// <summary>The steps of PlayLoop that belong to the player run every this many tics</summary>
    FrameEvery: Integer;
    /// <summary>The player is dead between these tics (0 = never) and warps between the other two</summary>
    DeadFrom, DeadTo, WarpFrom, WarpTo: Integer;
    Height, WalkMod, RunMod, JumpMod: Integer;
    Seed: Cardinal;
  end;

  /// <summary>What happens in a tic: the keys that are down, the mouse, and what the game does to the player</summary>
  TPlayerTic = record
    Keys: TPlayerKeys;
    MouseDX, MouseDY, MouseFlags: Integer;
    /// <summary>-1 = as it is</summary>
    Angst: Integer;
    Warping: Integer;
    ChangeLight: Integer;
  end;

  /// <summary>The generator of the commands of a scenario: every key is held or released for a while</summary>
  TPlayerInput = record
  strict private
    FSeed: Cardinal;
    FScenario: TPlayerScenario;
    FKeys: TPlayerKeys;
    FHold: array[0..PLAYER_KEY_COUNT - 1] of Integer;
    FMouseHold, FMouseDX, FMouseDY, FMouseFlags: Integer;
  public
    procedure Start(const AScenario: TPlayerScenario);
    procedure Next(ATic: Integer; out AInput: TPlayerTic);
  end;

  /// <summary>FNV-1a of a row of numbers</summary>
  TPlayerHash = record
    Value: Cardinal;
    Count: Integer;
    procedure Reset;
    procedure Add(AValue: Integer);
    procedure AddBytes(const ABuffer; ASize: Integer);
    procedure AddCall(AKind: Integer; const AArguments: array of Integer);
  end;

  TPlayerScenarios = class
  public
    class function Scenario(AIndex: Integer): TPlayerScenario; static;
    class procedure BuildMap(ASeed: Integer; out AMap: TPlayerMap); static;
    /// <summary>The character that INT_ReadControls gives when the keys go from APrevious to ACurrent (#0 none)</summary>
    class function TypedCharacter(const APrevious, ACurrent: TPlayerKeys): AnsiChar; static;
    /// <summary>The size of the picture of a weapon in a mode, in both programs</summary>
    class function PictureWidth(AWeapon, AMode: Integer): Integer; static;
    class function PictureHeight(AWeapon, AMode: Integer): Integer; static;
    /// <summary>What CheckForSwitch answers in both programs</summary>
    class function SwitchAnswer(ATileX, ATileY, AAngle: Integer): Boolean; static;
    class function CheckpointCount(ATics: Integer): Integer; static;
    /// <summary>The line of the golden file of a scenario: index, tics, calls and the hash at each checkpoint</summary>
    class function GoldenLine(const AScenario: TPlayerScenario; ACalls: Integer;
      const ACheckpoints: TArray<Cardinal>): string; static;
    /// <summary>The values of a tic as text, one for each line, for looking for a difference</summary>
    class function Describe(ATic: Integer; const AValues: TPlayerValues): string; static;
  end;

implementation

const
  FNV_OFFSET = 2166136261;
  FNV_PRIME = 16777619;

  FL_DOOR = 128;
  SM_SWAPSWITCH = 156;
  SM_STRIGGER = 168;
  F_NOCLIP = 32;
  F_NOBULLETCLIP = 64;

  // playerheights, pwalkmod, prunmod and pjumpmod of constant.pas (PLAYERMOVESPEED = 163840)
  CHARACTER_HEIGHTS: array[0..5] of Integer = (42, 35, 50, 35, 38, 32);
  CHARACTER_WALK: array[0..5] of Integer = (-163840, 163840, -163840, 163840, 0, 245760);
  CHARACTER_RUN: array[0..5] of Integer = (-163840, 81920, -163840, 81920, 0, 327680);
  CHARACTER_JUMP: array[0..5] of Integer = (-65536, 0, 0, 0, -65536, 0);

  // how often a key goes down (in a thousand, each time it is free) and for how many tics at most
  KEY_CHANCE: array[0..PLAYER_KEY_COUNT - 1] of Integer = (
    650, 250, 150, 250, 450, 120, 220, 350, 120, 60, 25, 60, 60, 30, 60, 60, 40, 40, 25,
    8, 8, 8, 8, 8, 8, 8, 8, 6, 6, 15, 8, 15, 15, 15, 15, 15, 20, 20,
    25, 25, 25, 25, 25);
  KEY_HOLD: array[0..PLAYER_KEY_COUNT - 1] of Integer = (
    90, 30, 40, 30, 60, 40, 12, 80, 10, 8, 6, 20, 20, 6, 30, 30, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 30, 6, 6, 6, 6, 6, 6, 6, 6,
    8, 8, 8, 8, 8);

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8) and $FFFFFF;
end;

{ TPlayerHash }

procedure TPlayerHash.Reset;
begin
  Value := FNV_OFFSET;
  Count := 0;
end;

procedure TPlayerHash.Add(AValue: Integer);
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
end;

procedure TPlayerHash.AddBytes(const ABuffer; ASize: Integer);
var
  LByte: PByte;
  LIndex: Integer;
begin
  LByte := @ABuffer;
  for LIndex := 0 to ASize - 1 do
  begin
    Value := (Value xor LByte^) * FNV_PRIME;
    Inc(LByte);
  end;
end;

procedure TPlayerHash.AddCall(AKind: Integer; const AArguments: array of Integer);
var
  LIndex: Integer;
begin
  Inc(Count);
  Add(AKind);
  for LIndex := 0 to High(AArguments) do
    Add(AArguments[LIndex]);
end;

{ TPlayerInput }

procedure TPlayerInput.Start(const AScenario: TPlayerScenario);
var
  LKey: Integer;
begin
  FScenario := AScenario;
  FSeed := AScenario.Seed;
  for LKey := 0 to PLAYER_KEY_COUNT - 1 do
  begin
    FKeys[LKey] := False;
    FHold[LKey] := 0;
  end;
  FMouseHold := 0;
  FMouseDX := 0;
  FMouseDY := 0;
  FMouseFlags := 0;
end;

procedure TPlayerInput.Next(ATic: Integer; out AInput: TPlayerTic);
var
  LKey: Integer;
begin
  for LKey := 0 to PLAYER_KEY_COUNT - 1 do
  begin
    if FHold[LKey] > 0 then
      Dec(FHold[LKey])
    else
    begin
      FKeys[LKey] := NextRandom(FSeed) mod 1000 < KEY_CHANCE[LKey];
      if FKeys[LKey] then
        FHold[LKey] := 1 + NextRandom(FSeed) mod KEY_HOLD[LKey]
      else
        FHold[LKey] := 1 + NextRandom(FSeed) mod (KEY_HOLD[LKey] * 2);
    end;
  end;
  if FMouseHold > 0 then
    Dec(FMouseHold)
  else
  begin
    FMouseHold := 1 + NextRandom(FSeed) mod 30;
    if NextRandom(FSeed) mod 3 = 0 then
    begin
      FMouseDX := NextRandom(FSeed) mod 41 - 20;
      FMouseDY := NextRandom(FSeed) mod 21 - 10;
    end
    else
    begin
      FMouseDX := 0;
      FMouseDY := 0;
    end;
    FMouseFlags := 0;
    if NextRandom(FSeed) mod 5 = 0 then
      FMouseFlags := NextRandom(FSeed) mod 8;
  end;
  AInput.Keys := FKeys;
  AInput.MouseDX := FMouseDX;
  AInput.MouseDY := FMouseDY;
  AInput.MouseFlags := FMouseFlags;
  AInput.Angst := -1;
  AInput.Warping := -1;
  AInput.ChangeLight := 0;
  if FScenario.DeadFrom <> 0 then
  begin
    if ATic = FScenario.DeadFrom then
      AInput.Angst := 0;
    if ATic = FScenario.DeadTo then
      AInput.Angst := 100;
  end;
  if FScenario.WarpFrom <> 0 then
  begin
    if ATic = FScenario.WarpFrom then
      AInput.Warping := 1;
    if ATic = FScenario.WarpTo then
      AInput.Warping := 0;
  end;
  if NextRandom(FSeed) mod 200 = 0 then
    AInput.ChangeLight := NextRandom(FSeed) mod 3001 - 1500;
end;

{ TPlayerScenarios }

class function TPlayerScenarios.Scenario(AIndex: Integer): TPlayerScenario;
var
  LSeed: Cardinal;
  LSlot: Integer;
begin
  Result := Default(TPlayerScenario);
  Result.Index := AIndex;
  LSeed := Cardinal(AIndex) * 2654435761 + 777;
  Result.Seed := LSeed xor $5A5A5A5A;
  // every character on every map
  Result.MapSeed := 1 + AIndex mod PLAYER_MAP_COUNT;
  Result.CharType := (AIndex div PLAYER_MAP_COUNT) mod 6;
  Result.Tics := 500 + (AIndex mod 4) * 500;
  Result.Angle := NextRandom(LSeed) mod 1024;
  // every weapon of the table is in the hands of somebody; the first slot always has one
  for LSlot := 0 to 4 do
    Result.Weapons[LSlot] := (AIndex * 5 + LSlot * 7 + 1) mod 19;
  if AIndex mod 5 = 3 then
    Result.Weapons[2 + AIndex mod 3] := -1;
  if AIndex mod 3 = 0 then
  begin
    Result.Ammo[0] := 300;
    Result.Ammo[1] := 300;
    Result.Ammo[2] := 300;
  end
  else
  begin
    // the ammunition ends during the scenario
    Result.Ammo[0] := 5 + NextRandom(LSeed) mod 30;
    Result.Ammo[1] := 5 + NextRandom(LSeed) mod 30;
    Result.Ammo[2] := 5 + NextRandom(LSeed) mod 90;
  end;
  Result.MouseEnabled := AIndex mod 3 <> 1;
  Result.InvertTurn := AIndex mod 4 = 2;
  Result.InvertLook := AIndex mod 5 = 2;
  Result.MouseSensitivity := AIndex mod 7;
  Result.FrameEvery := 1 + AIndex mod 3;
  if AIndex mod 4 = 3 then
  begin
    Result.DeadFrom := 301 + AIndex;
    Result.DeadTo := 420 + AIndex;
  end;
  if AIndex mod 5 = 2 then
  begin
    Result.WarpFrom := 150 + AIndex;
    Result.WarpTo := 190 + AIndex;
  end;
  Result.Height := CHARACTER_HEIGHTS[Result.CharType] * PLAYER_FRACUNIT;
  Result.WalkMod := CHARACTER_WALK[Result.CharType];
  Result.RunMod := CHARACTER_RUN[Result.CharType];
  Result.JumpMod := CHARACTER_JUMP[Result.CharType];
end;

class procedure TPlayerScenarios.BuildMap(ASeed: Integer; out AMap: TPlayerMap);
var
  LSeed: Cardinal;
  LSpot, LX, LY, LBase, LChoice, LIndex, LBlock: Integer;
  LBlockHeights: array[0..63] of Integer;
begin
  FillChar(AMap, SizeOf(AMap), 0);
  LSeed := Cardinal(ASeed) * 7919 + 4711;
  // the floor is made of blocks of 8 x 8 tiles at heights that are a step apart, with some single steps
  for LBlock := 0 to 63 do
    LBlockHeights[LBlock] := 24 + (NextRandom(LSeed) mod 5) * 12;
  for LY := 0 to PLAYER_MAP_SIZE - 1 do
    for LX := 0 to PLAYER_MAP_SIZE - 1 do
    begin
      LSpot := LY * PLAYER_MAP_SIZE + LX;
      LBase := LBlockHeights[(LY div 8) * 8 + LX div 8];
      LChoice := NextRandom(LSeed) mod 20;
      if LChoice = 0 then
        LBase := LBase + 10
      else if LChoice = 1 then
        LBase := LBase + 22
      else if LChoice = 2 then
        LBase := LBase - 14;
      AMap.FloorHeight[LSpot] := LBase;
      // some ceilings are low enough to stop a jump, a few to stop the player
      LChoice := NextRandom(LSeed) mod 12;
      if LChoice = 0 then
        AMap.CeilingHeight[LSpot] := LBase + 40 + NextRandom(LSeed) mod 30
      else if LChoice < 4 then
        AMap.CeilingHeight[LSpot] := LBase + 70 + NextRandom(LSeed) mod 30
      else
        AMap.CeilingHeight[LSpot] := LBase + 100 + NextRandom(LSeed) mod 60;
      LChoice := NextRandom(LSeed) mod 40;
      if LChoice = 0 then
        AMap.FloorPic[LSpot] := 0
      else if LChoice < 4 then
        // water
        AMap.FloorPic[LSpot] := 57 + NextRandom(LSeed) mod 3
      else
        AMap.FloorPic[LSpot] := 1 + NextRandom(LSeed) mod 50;
      AMap.CeilingPic[LSpot] := 1 + NextRandom(LSeed) mod 50;
      // the floors that push the player (F_RIGHT, F_LEFT, F_UP, F_DOWN)
      if NextRandom(LSeed) mod 25 = 0 then
        AMap.FloorFlags[LSpot] := 1 shl (NextRandom(LSeed) mod 4);
      // one tile in ten has a floor that is not flat, one in twenty a ceiling
      if NextRandom(LSeed) mod 10 = 0 then
        AMap.MapFlags[LSpot] := 1 + NextRandom(LSeed) mod 3;
      if NextRandom(LSeed) mod 20 = 0 then
        AMap.MapFlags[LSpot] := AMap.MapFlags[LSpot] or ((1 + NextRandom(LSeed) mod 3) shl 3);
      // walls inside the area: some let the player through, some let the shots through
      if NextRandom(LSeed) mod 16 = 0 then
      begin
        AMap.NorthWall[LSpot] := 1 + NextRandom(LSeed) mod 100;
        LChoice := NextRandom(LSeed) mod 8;
        if LChoice = 0 then
          AMap.NorthFlags[LSpot] := F_NOCLIP
        else if LChoice = 1 then
          AMap.NorthFlags[LSpot] := F_NOBULLETCLIP;
      end;
      if NextRandom(LSeed) mod 16 = 0 then
      begin
        AMap.WestWall[LSpot] := 1 + NextRandom(LSeed) mod 100;
        LChoice := NextRandom(LSeed) mod 8;
        if LChoice = 0 then
          AMap.WestFlags[LSpot] := F_NOCLIP
        else if LChoice = 1 then
          AMap.WestFlags[LSpot] := F_NOBULLETCLIP;
      end;
      // sprites: solid things (the targets of the probe), instawalls, switches of elevators, triggers
      LChoice := NextRandom(LSeed) mod 100;
      if LChoice < 3 then
        AMap.MapSprites[LSpot] := 1 + NextRandom(LSeed) mod 127
      else if LChoice = 3 then
        AMap.MapSprites[LSpot] := 64
      else if LChoice < 7 then
        AMap.MapSprites[LSpot] := SM_SWAPSWITCH
      else if LChoice < 10 then
        AMap.MapSprites[LSpot] := SM_STRIGGER
      else if LChoice < 12 then
        AMap.MapSprites[LSpot] := 128 + NextRandom(LSeed) mod 128;
      if NextRandom(LSeed) mod 14 = 0 then
        AMap.Switches[LX * PLAYER_MAP_SIZE + LY] := 1 + NextRandom(LSeed) mod 60;
    end;
  // the walls that close the area: nothing goes to the row and the column 0 and 63
  for LIndex := 0 to PLAYER_MAP_SIZE - 1 do
  begin
    AMap.NorthWall[1 * PLAYER_MAP_SIZE + LIndex] := 7;
    AMap.NorthFlags[1 * PLAYER_MAP_SIZE + LIndex] := 0;
    AMap.NorthWall[63 * PLAYER_MAP_SIZE + LIndex] := 7;
    AMap.NorthFlags[63 * PLAYER_MAP_SIZE + LIndex] := 0;
    AMap.WestWall[LIndex * PLAYER_MAP_SIZE + 1] := 7;
    AMap.WestFlags[LIndex * PLAYER_MAP_SIZE + 1] := 0;
    AMap.WestWall[LIndex * PLAYER_MAP_SIZE + 63] := 7;
    AMap.WestFlags[LIndex * PLAYER_MAP_SIZE + 63] := 0;
  end;
  // no solid sprite near the walls of the area: the probe of a shot goes through a wall when a sprite is in a tile
  // that it looks at before the tile of the wall, and outside the map the original reads other memory
  // and no floor there: a character that runs at more than 16 units a tic goes through a wall (TryMove looks at the
  // tiles under the place where it arrives), but nobody goes on a tile without a floor
  for LIndex := 0 to PLAYER_MAP_SIZE - 1 do
    for LBase := 0 to 5 do
    begin
      LChoice := LBase;
      if LBase >= 3 then
        LChoice := PLAYER_MAP_SIZE - 6 + LBase;
      AMap.MapSprites[LChoice * PLAYER_MAP_SIZE + LIndex] := 0;
      AMap.MapSprites[LIndex * PLAYER_MAP_SIZE + LChoice] := 0;
      AMap.FloorPic[LChoice * PLAYER_MAP_SIZE + LIndex] := 0;
      AMap.FloorPic[LIndex * PLAYER_MAP_SIZE + LChoice] := 0;
    end;
  // the place where the player starts: a flat square without walls and sprites
  AMap.StartTileX := 20 + NextRandom(LSeed) mod 24;
  AMap.StartTileY := 20 + NextRandom(LSeed) mod 24;
  for LY := AMap.StartTileY - 2 to AMap.StartTileY + 2 do
    for LX := AMap.StartTileX - 2 to AMap.StartTileX + 2 do
    begin
      LSpot := LY * PLAYER_MAP_SIZE + LX;
      AMap.FloorHeight[LSpot] := 36;
      AMap.CeilingHeight[LSpot] := 180;
      AMap.FloorPic[LSpot] := 5;
      AMap.FloorFlags[LSpot] := 0;
      AMap.MapFlags[LSpot] := 0;
      AMap.MapSprites[LSpot] := 0;
      AMap.NorthWall[LSpot] := 0;
      AMap.WestWall[LSpot] := 0;
      // half of the tiles of the square have a switch with its event
      if (LX + LY) and 1 = 1 then
        AMap.Switches[LX * PLAYER_MAP_SIZE + LY] := 1 + NextRandom(LSeed) mod 60
      else
        AMap.Switches[LX * PLAYER_MAP_SIZE + LY] := 0;
    end;
  // and next to the start there are the switch of the elevators that swap and the trigger of the secret ones
  AMap.MapSprites[AMap.StartTileY * PLAYER_MAP_SIZE + AMap.StartTileX + 1] := SM_SWAPSWITCH;
  AMap.MapSprites[(AMap.StartTileY + 1) * PLAYER_MAP_SIZE + AMap.StartTileX] := SM_STRIGGER;
  AMap.MapSprites[(AMap.StartTileY - 1) * PLAYER_MAP_SIZE + AMap.StartTileX - 1] := SM_SWAPSWITCH;
  // the tiles around the square are flat too: a slope reads the heights of its neighbours
  for LY := AMap.StartTileY - 3 to AMap.StartTileY + 3 do
    for LX := AMap.StartTileX - 3 to AMap.StartTileX + 3 do
      AMap.MapFlags[LY * PLAYER_MAP_SIZE + LX] := 0;
  // doors near the start and far from it, of the four orientations, some open, some that do not open
  for LIndex := 0 to PLAYER_DOOR_COUNT - 1 do
  begin
    if LIndex < 4 then
    begin
      AMap.Doors[LIndex].TileX := AMap.StartTileX - 6 + NextRandom(LSeed) mod 13;
      AMap.Doors[LIndex].TileY := AMap.StartTileY - 6 + NextRandom(LSeed) mod 13;
    end
    else
    begin
      AMap.Doors[LIndex].TileX := 4 + NextRandom(LSeed) mod 56;
      AMap.Doors[LIndex].TileY := 4 + NextRandom(LSeed) mod 56;
    end;
    AMap.Doors[LIndex].Orientation := LIndex mod 4;
    AMap.Doors[LIndex].Open := NextRandom(LSeed) mod 5 = 0;
    AMap.Doors[LIndex].Bumpable := NextRandom(LSeed) mod 6 <> 0;
    LSpot := AMap.Doors[LIndex].TileY * PLAYER_MAP_SIZE + AMap.Doors[LIndex].TileX;
    AMap.MapFlags[LSpot] := AMap.MapFlags[LSpot] or FL_DOOR;
  end;
  // elevators that swap and secret elevators, near the start
  for LIndex := 0 to PLAYER_ELEVATOR_COUNT - 1 do
  begin
    LX := AMap.StartTileX - 5 + NextRandom(LSeed) mod 11;
    LY := AMap.StartTileY - 5 + NextRandom(LSeed) mod 11;
    AMap.Elevators[LIndex].MapSpot := LY * PLAYER_MAP_SIZE + LX;
    AMap.Elevators[LIndex].Kind := 5 + LIndex mod 2;
    AMap.Elevators[LIndex].Floor := 20;
    AMap.Elevators[LIndex].Ceiling := 90;
    case NextRandom(LSeed) mod 3 of
      0:
        AMap.Elevators[LIndex].Position := 20;
      1:
        AMap.Elevators[LIndex].Position := 90;
    else
      AMap.Elevators[LIndex].Position := 50;
    end;
  end;
end;

class function TPlayerScenarios.TypedCharacter(const APrevious, ACurrent: TPlayerKeys): AnsiChar;
var
  LKey, LBestCode: Integer;
begin
  // INT_ReadControls goes through the scan codes in order: the last new key with a character wins
  Result := #0;
  LBestCode := -1;
  for LKey := 0 to PLAYER_KEY_COUNT - 1 do
    if ACurrent[LKey] and not APrevious[LKey] and (PLAYER_KEY_CHARACTERS[LKey] <> #0) and
      (PLAYER_SCAN_CODES[LKey] > LBestCode) then
    begin
      LBestCode := PLAYER_SCAN_CODES[LKey];
      Result := PLAYER_KEY_CHARACTERS[LKey];
    end;
end;

class function TPlayerScenarios.PictureWidth(AWeapon, AMode: Integer): Integer;
begin
  Result := 60 + (AWeapon * 7 + AMode * 3 + 50) mod 50;
end;

class function TPlayerScenarios.PictureHeight(AWeapon, AMode: Integer): Integer;
begin
  Result := 40 + (AWeapon * 5 + AMode * 11 + 60) mod 60;
end;

class function TPlayerScenarios.SwitchAnswer(ATileX, ATileY, AAngle: Integer): Boolean;
begin
  Result := (ATileX + ATileY * 3 + AAngle) mod 3 <> 0;
end;

class function TPlayerScenarios.CheckpointCount(ATics: Integer): Integer;
begin
  Result := (ATics + PLAYER_CHECKPOINT - 1) div PLAYER_CHECKPOINT;
end;

class function TPlayerScenarios.GoldenLine(const AScenario: TPlayerScenario; ACalls: Integer;
  const ACheckpoints: TArray<Cardinal>): string;
var
  LIndex: Integer;
begin
  Result := IntToStr(AScenario.Index) + ' ' + IntToStr(AScenario.Tics) + ' ' + IntToStr(ACalls);
  for LIndex := 0 to High(ACheckpoints) do
    Result := Result + ' ' + IntToStr(Int64(ACheckpoints[LIndex]));
end;

class function TPlayerScenarios.Describe(ATic: Integer; const AValues: TPlayerValues): string;
var
  LIndex: Integer;
begin
  Result := '== tic ' + IntToStr(ATic);
  for LIndex := 0 to High(AValues) do
    Result := Result + sLineBreak + PLAYER_VALUE_NAMES[LIndex] + ' ' + IntToStr(AValues[LIndex]);
end;

end.
