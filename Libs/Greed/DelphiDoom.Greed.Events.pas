{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the script of a map and its events               }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): AddProcess, RunEvent,       }
{  Process and LoadScript of event.pas                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Events;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.ScriptScanner,
  DelphiDoom.Greed.Events.Intf;

type
  /// <summary>
  ///   event.pas, line by line. LoadScript reads the script of a map (the text lump that is as far after the lump
  ///   SUX as the lump of the map is after the lump MAP) and fills the triggers, the wall switches, the zones, the
  ///   goals and the score of the level, makes the elevators of the script, asks for the pictures of FORCELOAD,
  ///   reads the sky (BACKDROP) and runs the event 0. RunEvent marks the event of the player, clears its triggers
  ///   and switches, starts its elevators and does what its zones say. Process carries on the zones that change a
  ///   plane of the map a step at a time (call it only while State.NumProcesses is not 0, as the original does).
  ///   The globals of event.pas are in TGreedGameState; triggers[x][y] of the original is State.Triggers[x * 64 +
  ///   y] and the same for the switches. The sky is the property Backdrop. The net game is not ported: the NetEvent
  ///   of RunEvent is not here and a film is played also where the original asked "not netmode".
  ///   Not ported: the script from a file (-file: the original stops in CA_LumpName, which never ends).
  ///   Kept defects of the original: SPAWNELEVATOR uses the end event of the last ELEVATOR line (0 if there was
  ///   none: in the original the value is not set); a number that is missing or wrong does not stop the script
  ///   (see TGreedScriptScanner); a zone with a layer that Process does not know stops the game only when it runs;
  ///   AREATRIGGER of the script includes its last row and column and the zone of SPAWNAREATRIGGER does not; the
  ///   255th zone is "Out of mapzones".
  ///   Differences: what the original wrote outside its arrays is not written (a trigger, a tile, an event of the
  ///   player, a goal outside its table; the map 10 of the complete game has "sprite 6 81 86", which in the original
  ///   falls in the plane of the slopes, not read after the script) and a tile outside the map is not changed by
  ///   Process; a wrong number near the end of the text does not stop the script (the original dies with a list
  ///   index error while it prints the lines around the error: ScriptPrintLineError reads one line too many); more
  ///   than 16 FORCELOAD lines are EGreedDataException (the original wrote past its array); a sky lump shorter
  ///   than 8 +
  ///   32768 bytes leaves zeros (the original read what follows in the file); MS_Error is EGreedDataException for
  ///   the script and EGreedException for the processes
  /// </summary>
  TGreedEvents = class(TInterfacedObject, IGreedEventRunner, IGreedMapScript)
  strict private
    FState: TGreedGameState;
    FArchive: IGreedArchive;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FHost: IGreedEventHost;
    FBackdrop: TBytes;
    FBackdropLump: Integer;
    FScriptProblems: Integer;
    function FloorZ(AX, AY: TGreedFixed): TGreedFixed;
    procedure SetTrigger(AX, AY, AValue: Integer);
    procedure SetSwitch(AX, AY, AValue: Integer);
    procedure WriteTile(APlane: TGreedPlane; ASpot, AValue: Integer);
    procedure RetireZone(var AZone: TGreedZone);
    procedure RunElevators(AEvent: Integer);
    procedure RunZone(AIndex, AEvent: Integer);
    procedure ActivateZoneSprites(const AZone: TGreedZone);
    procedure SpawnZoneSprite(const AZone: TGreedZone);
    function NewZone: Integer;
    procedure ScriptElevator(AScanner: TGreedScriptScanner; ATriggered: Boolean; var AEndEvent: Integer);
    procedure ReadBackdropHalf(ALump, AOffset: Integer);
    class function LayerPlane(ALayer: Integer): TGreedPlane; static;
  public
    /// <summary>
    ///   AState has the world, the pools and the globals of the game; AArchive gives the numbers of the lumps, the
    ///   script and the sky; ASpawner is SpawnSprite and DemandLoadMonster; ASound is SoundEffect; AHost is the rest
    ///   of the game. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const AArchive: IGreedArchive; const ASpawner: IGreedSpawner;
      const ASound: IGreedGameSound; const AHost: IGreedEventHost);
    /// <summary>AddProcess(n): the zone n starts to change its plane. EGreedException if there are 128</summary>
    procedure AddProcess(AZone: Integer);
    /// <summary>RunEvent(eval, netsend)</summary>
    procedure RunEvent(AEvent: Integer; ANetSend: Boolean);
    /// <summary>Process: a step of every running zone; the player follows the floor that moved under it</summary>
    procedure Process;
    /// <summary>
    ///   LoadScript(lump, newgame): ALump is the lump of the map (the lump "map" + the number of the map + 1), the
    ///   script is the lump ALump - "MAP" + "SUX". ANewGame is false when a saved game is loaded: the sprites of
    ///   the script are not put on the map and a spawn that was already used is not made again
    /// </summary>
    procedure LoadScript(ALump: Integer; ANewGame: Boolean);
    /// <summary>LoadScript with the text of the script given by the caller (the bytes of the lump)</summary>
    procedure LoadScriptText(const AScript: TBytes; ANewGame: Boolean);
    /// <summary>The number of the lump of the script of a map lump</summary>
    function ScriptLumpOf(AMapLump: Integer): Integer;
    /// <summary>backdrop of r_render.pas: 65536 bytes, the two halves of the sky of the map</summary>
    property Backdrop: TBytes read FBackdrop;
    /// <summary>eventlump: the first of the two lumps of the sky</summary>
    property BackdropLump: Integer read FBackdropLump;
    /// <summary>How many errors of the last script the original would only have printed</summary>
    property ScriptProblems: Integer read FScriptProblems;
  end;

implementation

uses
  DelphiDoom.Greed.Terrain;

const
  STooManyProcesses = 'AddProcess(): Too many active processes! (%d)';
  SProcessOverflow = 'AddProcess(): Process array overflow';
  SNoNextProcess = 'Processes(): can''t find next process!';
  SLayerNotImplemented = 'Layer %d is not implemented';
  SOutOfMapZones = 'Out of mapzones';
  STooManyForceLoads = 'LoadScript(): more than %d FORCELOAD lines';

  LUMP_BACKDROP = 'BACKDROP';
  LUMP_MAP = 'MAP';
  LUMP_SCRIPT = 'SUX';
  TIC_RATE = 70;
  /// the header of a picture before its pixels
  BACKDROP_HEADER_BYTES = 8;
  DEFAULT_BONUS_TIME = 3150;
  DEFAULT_LEVEL_SCORE = 100000;
  /// the sprites of an activation zone wait this many tics before they act
  ACTIVATION_DELAY = 40;
  WARP_HEIGHT = 10 * GREED_FRACUNIT;
  HALF_TILE = 32;
  FIRST_PAIRED_EVENT = 200;

{ TGreedEvents }

constructor TGreedEvents.Create(AState: TGreedGameState; const AArchive: IGreedArchive;
  const ASpawner: IGreedSpawner; const ASound: IGreedGameSound; const AHost: IGreedEventHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FArchive := AArchive;
  FSpawner := ASpawner;
  FSound := ASound;
  FHost := AHost;
  SetLength(FBackdrop, GREED_BACKDROP_BYTES);
  FBackdropLump := -1;
end;

function TGreedEvents.FloorZ(AX, AY: TGreedFixed): TGreedFixed;
begin
  Result := TGreedTerrain.FloorZ(FState.World, AX, AY);
end;

procedure TGreedEvents.SetTrigger(AX, AY, AValue: Integer);
var
  LIndex: Integer;
begin
  LIndex := AX * GREED_MAP_SIZE + AY;
  if (LIndex >= 0) and (LIndex < GREED_MAP_TILES) then
    FState.Triggers[LIndex] := Byte(AValue);
end;

procedure TGreedEvents.SetSwitch(AX, AY, AValue: Integer);
var
  LIndex: Integer;
begin
  LIndex := AX * GREED_MAP_SIZE + AY;
  if (LIndex >= 0) and (LIndex < GREED_MAP_TILES) then
    FState.Switches[LIndex] := Byte(AValue);
end;

procedure TGreedEvents.WriteTile(APlane: TGreedPlane; ASpot, AValue: Integer);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(APlane, ASpot, Byte(AValue));
end;

procedure TGreedEvents.RetireZone(var AZone: TGreedZone);
begin
  if AZone.Removeable <> 0 then
  begin
    AZone.Kind := GREED_ZONE_REMOVED;
    AZone.Eval := 0;
  end;
end;

procedure TGreedEvents.AddProcess(AZone: Integer);
var
  LIndex: Integer;
begin
  if FState.NumProcesses = GREED_MAX_PROCESSES then
    raise EGreedException.CreateFmt(STooManyProcesses, [GREED_MAX_PROCESSES]);
  LIndex := 0;
  while (LIndex < GREED_MAX_PROCESSES) and (FState.Processes[LIndex] <> 0) do
    Inc(LIndex);
  if LIndex = GREED_MAX_PROCESSES then
    raise EGreedException.Create(SProcessOverflow);
  FState.Processes[LIndex] := GREED_PROCESS_BASE + AZone;
  Inc(FState.NumProcesses);
end;

procedure TGreedEvents.RunElevators(AEvent: Integer);
var
  LIndex: Integer;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  LIndex := FState.Elevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LElevator := FState.Elevators.Item(LIndex);
    if (LElevator^.Eval = AEvent) and (AEvent > 0) then
    begin
      if LElevator^.Position = LElevator^.Floor then
      begin
        LElevator^.Up := True;
        LElevator^.Eval := 0;
        LElevator^.Timer := FState.TimeCount;
        FSound.SoundEffect(GREED_SN_ELEVATORSTART, 15, (LElevator^.MapSpot and 63) * GREED_FRACTILEUNIT,
          (LElevator^.MapSpot div 64) * GREED_FRACTILEUNIT);
      end
      else if LElevator^.Position = LElevator^.Ceiling then
      begin
        LElevator^.Down := True;
        LElevator^.Eval := 0;
        LElevator^.Timer := FState.TimeCount;
        FSound.SoundEffect(GREED_SN_ELEVATORSTART, 15, (LElevator^.MapSpot and 63) * GREED_FRACTILEUNIT,
          (LElevator^.MapSpot div 64) * GREED_FRACTILEUNIT);
      end;
    end;
    LIndex := FState.Elevators.Next(LIndex);
  end;
end;

procedure TGreedEvents.ActivateZoneSprites(const AZone: TGreedZone);
var
  LIndex, LTileX, LTileY: Integer;
  LSprite: PGreedSprite;
begin
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
    if not LSprite^.Active and (LSprite^.MoveSpeed <> 0) then
    begin
      LTileX := LSprite^.X div GREED_FRACTILEUNIT;
      LTileY := LSprite^.Y div GREED_FRACTILEUNIT;
      if (LTileX >= AZone.X1) and (LTileX <= AZone.X2) and (LTileY >= AZone.Y1) and (LTileY <= AZone.Y2) then
      begin
        LSprite^.Active := True;
        LSprite^.ActionTime := FState.TimeCount + ACTIVATION_DELAY;
        FHost.ActivationSound(LIndex);
      end;
    end;
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

procedure TGreedEvents.SpawnZoneSprite(const AZone: TGreedZone);
var
  LX, LY: TGreedFixed;
  LSprite: Integer;
begin
  FState.GameLoading := True;
  if not FState.EventLoading or (AZone.EndEval <> 0) then
  begin
    LX := (AZone.X1 * GREED_MAP_SIZE + HALF_TILE) * GREED_FRACUNIT;
    LY := (AZone.Y1 * GREED_MAP_SIZE + HALF_TILE) * GREED_FRACUNIT;
    FSpawner.SpawnSprite(GREED_S_WARP, LX, LY, FloorZ(LX, LY) + WARP_HEIGHT, 0, 0, 0, True, 0);
    LSprite := FSpawner.SpawnSprite(AZone.SType, LX, LY, FloorZ(LX, LY) + WARP_HEIGHT, 0, 0, 0, True, 0);
    if LSprite <> GREED_POOL_NIL then
      PGreedSprite(FState.Sprites.Item(LSprite))^.DeathEvent := AZone.EndEval;
  end;
  FState.GameLoading := False;
end;

procedure TGreedEvents.RunZone(AIndex, AEvent: Integer);
var
  LZone: ^TGreedZone;
  LX, LY: Integer;
begin
  LZone := @FState.Zones[AIndex];
  if LZone^.Kind = GREED_ZONE_ACTIVATION then
  begin
    ActivateZoneSprites(LZone^);
    RetireZone(LZone^);
  end
  else if LZone^.Kind = GREED_ZONE_MAP then
  begin
    AddProcess(AIndex);
    RetireZone(LZone^);
  end
  else if (LZone^.Kind = GREED_ZONE_SPAWN) and (AEvent > 0) then
  begin
    SpawnZoneSprite(LZone^);
    RetireZone(LZone^);
  end
  else if (LZone^.Kind = GREED_ZONE_TRIGGER) and (AEvent > 0) then
  begin
    SetTrigger(LZone^.X1, LZone^.Y1, LZone^.EndEval);
    RetireZone(LZone^);
  end
  else if (LZone^.Kind = GREED_ZONE_SOUND) and (AEvent > 0) then
  begin
    FSound.SoundEffect(LZone^.EndEval, 0, (LZone^.X1 * GREED_MAP_SIZE + HALF_TILE) * GREED_FRACUNIT,
      (LZone^.Y1 * GREED_MAP_SIZE + HALF_TILE) * GREED_FRACUNIT);
    RetireZone(LZone^);
  end
  else if LZone^.Kind = GREED_ZONE_AREA_TRIGGER then
  begin
    for LY := LZone^.Y1 to LZone^.Y2 - 1 do
      for LX := LZone^.X1 to LZone^.X2 - 1 do
        SetTrigger(LX, LY, LZone^.EndEval);
    RetireZone(LZone^);
  end
  else if (LZone^.Kind = GREED_ZONE_FLI) and (AEvent > 0) then
  begin
    FHost.PlayFli(LZone^.EndEval);
    FState.FliPlayed := 1;
    LZone^.Eval := 0;
    LZone^.Kind := GREED_ZONE_REMOVED;
    FState.Player.Angst := 0;
  end;
end;

procedure TGreedEvents.RunEvent(AEvent: Integer; ANetSend: Boolean);
var
  LIndex, LZones: Integer;
begin
  if AEvent < 256 then
  begin
    if AEvent >= 0 then
      FState.Player.Events[AEvent] := 1;
    if (AEvent > FIRST_PAIRED_EVENT) and (AEvent and 1 = 0) then
      FState.Player.Events[AEvent - 1] := 0;
  end;

  for LIndex := 0 to GREED_MAP_TILES - 1 do
    if FState.Triggers[LIndex] = AEvent then
      FState.Triggers[LIndex] := 0;
  for LIndex := 0 to GREED_MAP_TILES - 1 do
    if FState.Switches[LIndex] = AEvent then
      FState.Switches[LIndex] := 0;

  RunElevators(AEvent);

  LZones := FState.NumZones;
  for LIndex := 0 to LZones - 1 do
    if FState.Zones[LIndex].Eval = AEvent then
      RunZone(LIndex, AEvent);
end;

class function TGreedEvents.LayerPlane(ALayer: Integer): TGreedPlane;
begin
  case ALayer of
    GREED_LAYER_NORTH_WALL:
      Result := gpNorthWall;
    GREED_LAYER_WEST_WALL:
      Result := gpWestWall;
    GREED_LAYER_LIGHTS:
      Result := gpMapLights;
    GREED_LAYER_FLOOR_HEIGHT:
      Result := gpFloorHeight;
    GREED_LAYER_CEILING_HEIGHT:
      Result := gpCeilingHeight;
    GREED_LAYER_EFFECTS:
      Result := gpMapEffects;
    GREED_LAYER_CEILING:
      Result := gpCeilingPic;
    GREED_LAYER_FLOOR:
      Result := gpFloorPic;
  else
    raise EGreedDataException.CreateFmt(SLayerNotImplemented, [ALayer]);
  end;
end;

procedure TGreedEvents.Process;
var
  LCount, LIndex, LX, LY, LSpot, LValue: Integer;
  LZone: TGreedZone;
  LPlane: TGreedPlane;
  LChanged: Boolean;
  LOldFloorZ, LNewFloorZ: TGreedFixed;
begin
  LOldFloorZ := FloorZ(FState.Player.X, FState.Player.Y) + FState.Player.Height;

  LCount := FState.NumProcesses;
  LIndex := -1;
  repeat
    Inc(LIndex);
    Dec(LCount);
    while (LIndex < GREED_MAX_PROCESSES) and (FState.Processes[LIndex] = 0) do
      Inc(LIndex);
    if LIndex = GREED_MAX_PROCESSES then
      raise EGreedException.Create(SNoNextProcess);
    // the zone is not changed while its tiles are: a copy is what the pointer of the original reads
    LZone := FState.Zones[FState.Processes[LIndex] - GREED_PROCESS_BASE];
    LPlane := LayerPlane(LZone.Layer);

    LChanged := False;
    for LY := LZone.Y1 to LZone.Y2 do
      for LX := LZone.X1 to LZone.X2 do
      begin
        LSpot := LY * GREED_MAP_SIZE + LX;
        if (LSpot < 0) or (LSpot >= GREED_MAP_TILES) then
          Continue;
        LValue := FState.World.GetValue(LPlane, LSpot);
        if LValue < LZone.NewValue then
        begin
          if LValue + LZone.Rate > LZone.NewValue then
            LValue := Byte(LZone.NewValue)
          else
            LValue := Byte(LValue + LZone.Rate);
          FState.World.SetValue(LPlane, LSpot, Byte(LValue));
          LChanged := True;
        end
        else if LValue > LZone.NewValue then
        begin
          if LValue - LZone.Rate < LZone.NewValue then
            LValue := Byte(LZone.NewValue)
          else
            LValue := Byte(LValue - LZone.Rate);
          if LValue < LZone.NewValue then
            LValue := Byte(LZone.NewValue);
          FState.World.SetValue(LPlane, LSpot, Byte(LValue));
          LChanged := True;
        end;
      end;

    if not LChanged then
    begin
      Dec(FState.NumProcesses);
      FState.Processes[LIndex] := 0;
      if LZone.EndEval <> 0 then
        RunEvent(LZone.EndEval, False);
    end;
  until LCount <= 0;

  LNewFloorZ := FloorZ(FState.Player.X, FState.Player.Y) + FState.Player.Height;
  if LNewFloorZ <> LOldFloorZ then
  begin
    FState.Player.Z := LNewFloorZ;
    FState.FallRate := 0;
  end;
end;

function TGreedEvents.NewZone: Integer;
begin
  Result := FState.NumZones;
  Inc(FState.NumZones);
  if FState.NumZones = GREED_MAX_ZONES then
    raise EGreedDataException.Create(SOutOfMapZones);
end;

procedure TGreedEvents.ScriptElevator(AScanner: TGreedScriptScanner; ATriggered: Boolean; var AEndEvent: Integer);
var
  LX, LY, LEvent, LType, LUpper, LLower, LSpeed, LIndex: Integer;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  AScanner.MustGetInteger;
  LX := AScanner.IntegerValue;
  AScanner.MustGetInteger;
  LY := AScanner.IntegerValue;
  AScanner.MustGetInteger;
  LEvent := AScanner.IntegerValue;
  if ATriggered then
  begin
    AScanner.MustGetInteger;
    AEndEvent := AScanner.IntegerValue;
  end;
  AScanner.MustGetInteger;
  LType := AScanner.IntegerValue;
  AScanner.MustGetInteger;
  LUpper := AScanner.IntegerValue;
  AScanner.MustGetInteger;
  LLower := AScanner.IntegerValue;
  AScanner.MustGetInteger;
  LSpeed := AScanner.IntegerValue;
  LIndex := FState.Elevators.Add;
  LElevator := FState.Elevators.Item(LIndex);
  LElevator^.Floor := LLower;
  LElevator^.MapSpot := LY * GREED_MAP_SIZE + LX;
  LElevator^.Ceiling := LUpper;
  if LType = 0 then
    LElevator^.Position := LLower
  else
    LElevator^.Position := LUpper;
  LElevator^.Position64 := LElevator^.Position * GREED_FRACUNIT;
  if ATriggered then
    LElevator^.Kind := getTriggered
  else
    LElevator^.Kind := getNormal;
  LElevator^.Speed := LSpeed;
  LElevator^.Eval := LEvent;
  LElevator^.EndEval := AEndEvent;
  LElevator^.Timer := FState.Player.TimeCount;
  LElevator^.NoSave := 1;
  WriteTile(gpFloorHeight, LElevator^.MapSpot, LElevator^.Position);
end;

procedure TGreedEvents.ReadBackdropHalf(ALump, AOffset: Integer);
var
  LBytes: TBytes;
  LCount: Integer;
begin
  LBytes := FArchive.ReadLumpRaw(ALump);
  FillChar(FBackdrop[AOffset], GREED_BACKDROP_HALF_BYTES, 0);
  LCount := Length(LBytes) - BACKDROP_HEADER_BYTES;
  if LCount > GREED_BACKDROP_HALF_BYTES then
    LCount := GREED_BACKDROP_HALF_BYTES;
  if LCount > 0 then
    Move(LBytes[BACKDROP_HEADER_BYTES], FBackdrop[AOffset], LCount);
end;

function TGreedEvents.ScriptLumpOf(AMapLump: Integer): Integer;
begin
  Result := AMapLump - FArchive.RequireIndexOf(LUMP_MAP) + FArchive.RequireIndexOf(LUMP_SCRIPT);
end;

procedure TGreedEvents.LoadScript(ALump: Integer; ANewGame: Boolean);
begin
  LoadScriptText(FArchive.ReadLumpRaw(ScriptLumpOf(ALump)), ANewGame);
end;

procedure TGreedEvents.LoadScriptText(const AScript: TBytes; ANewGame: Boolean);
var
  LScanner: TGreedScriptScanner;
  LWord, LName: string;
  LIndex, LRow, LColumn, LX, LY, LEvent, LEndEvent: Integer;
  LNumber, LValue, LSprite, LTotal, LChildEvent, LLow, LHigh, LX1, LY1, LX2, LY2, LRemoveable: Integer;
  LZone: ^TGreedZone;
  LForceLoads: Integer;
  LForceLumps, LForceCounts: array[0..GREED_MAX_FORCE_LOADS - 1] of Integer;
begin
  FillChar(FState.Triggers, SizeOf(FState.Triggers), 0);
  FillChar(FState.Switches, SizeOf(FState.Switches), 0);
  FillChar(FState.Zones, SizeOf(FState.Zones), 0);
  FillChar(FState.Processes, SizeOf(FState.Processes), 0);
  FState.NumProcesses := 0;
  FState.NumZones := 0;
  FState.FliPlayed := 0;
  LForceLoads := 0;
  LEndEvent := 0;
  FScriptProblems := 0;

  for LIndex := Low(FState.Secondaries) to High(FState.Secondaries) do
    FState.Secondaries[LIndex] := -1;
  for LIndex := Low(FState.Primaries) to High(FState.Primaries) do
    FState.Primaries[LIndex] := -1;
  FillChar(FState.PCount, SizeOf(FState.PCount), 0);
  FillChar(FState.SCount, SizeOf(FState.SCount), 0);
  FState.BonusTime := DEFAULT_BONUS_TIME;
  FState.LevelScore := DEFAULT_LEVEL_SCORE;
  FState.Player.LevelScore := DEFAULT_LEVEL_SCORE;
  FBackdropLump := FArchive.RequireIndexOf(LUMP_BACKDROP);

  LScanner := TGreedScriptScanner.Create(TGreedScriptScanner.NormalizeLines(AScript));
  try
    while LScanner.GetString do
    begin
      LWord := LScanner.UpperToken;
      if LWord = 'END' then
        Break
      else if LWord = 'TRIGGER' then
      begin
        LScanner.MustGetInteger;
        LX := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LEvent := LScanner.IntegerValue;
        SetTrigger(LX, LY, LEvent);
      end
      else if LWord = 'AREATRIGGER' then
      begin
        LScanner.MustGetInteger;
        LX1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LX2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LEvent := LScanner.IntegerValue;
        for LRow := LY1 to LY2 do
          for LColumn := LX1 to LX2 do
            SetTrigger(LColumn, LRow, LEvent);
      end
      else if LWord = 'WALLSWITCH' then
      begin
        LScanner.MustGetInteger;
        LX := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LEvent := LScanner.IntegerValue;
        SetSwitch(LX, LY, LEvent);
      end
      else if LWord = 'ELEVATOR' then
        ScriptElevator(LScanner, True, LEndEvent)
      else if LWord = 'SPAWNELEVATOR' then
        ScriptElevator(LScanner, False, LEndEvent)
      else if LWord = 'ACTIVATIONZONE' then
      begin
        LZone := @FState.Zones[NewZone];
        LScanner.MustGetInteger;
        LZone^.X1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Y1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.X2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Y2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Eval := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Removeable := LScanner.IntegerValue;
        LZone^.Kind := GREED_ZONE_ACTIVATION;
      end
      else if LWord = 'MAPZONE' then
      begin
        LZone := @FState.Zones[NewZone];
        LScanner.MustGetInteger;
        LZone^.X1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Y1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.X2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Y2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Eval := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.EndEval := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Layer := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.NewValue := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Rate := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Removeable := LScanner.IntegerValue;
        LZone^.Kind := GREED_ZONE_MAP;
      end
      else if LWord = 'BONUSTIME' then
      begin
        LScanner.MustGetInteger;
        FState.BonusTime := LScanner.IntegerValue * TIC_RATE;
      end
      else if LWord = 'PRIMARY' then
      begin
        LScanner.MustGetInteger;
        LNumber := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LValue := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LTotal := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LSprite := LScanner.IntegerValue;
        if (LNumber >= 0) and (LNumber <= High(FState.PCount)) then
        begin
          FState.Primaries[LNumber * 2] := LSprite;
          FState.Primaries[LNumber * 2 + 1] := LValue;
          FState.PCount[LNumber] := LTotal;
        end;
      end
      else if LWord = 'SECONDARY' then
      begin
        LScanner.MustGetInteger;
        LNumber := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LValue := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LTotal := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LSprite := LScanner.IntegerValue;
        if (LNumber >= 0) and (LNumber <= High(FState.SCount)) then
        begin
          FState.Secondaries[LNumber * 2] := LSprite;
          FState.Secondaries[LNumber * 2 + 1] := LValue;
          FState.SCount[LNumber] := LTotal;
        end;
      end
      else if LWord = 'LEVELSCORE' then
      begin
        LScanner.MustGetInteger;
        FState.Player.LevelScore := LScanner.IntegerValue;
      end
      else if LWord = 'SPRITE' then
      begin
        LScanner.MustGetInteger;
        LX := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LNumber := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LScanner.MustGetInteger;
        LLow := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LHigh := LScanner.IntegerValue;
        if ANewGame and (FState.Player.Difficulty >= 5 - LHigh) and (FState.Player.Difficulty <= 5 - LLow) then
        begin
          FState.GameLoading := True;
          WriteTile(gpMapSprites, LY * GREED_MAP_SIZE + LX, LNumber);
          FState.GameLoading := False;
        end;
      end
      else if LWord = 'SPAWN' then
      begin
        LScanner.MustGetInteger;
        LX := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LEvent := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LNumber := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LChildEvent := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LLow := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LHigh := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LRemoveable := LScanner.IntegerValue;
        if (FState.Player.Difficulty >= 5 - LHigh) and (FState.Player.Difficulty <= 5 - LLow) and
          (ANewGame or (LRemoveable = 0) or (LEvent < 0) or (LEvent > High(FState.Player.Events)) or
          (FState.Player.Events[LEvent] = 0)) then
        begin
          LZone := @FState.Zones[NewZone];
          LZone^.X1 := LX;
          LZone^.Y1 := LY;
          LZone^.Eval := LEvent;
          LZone^.EndEval := LChildEvent;
          LZone^.SType := LNumber;
          LZone^.Kind := GREED_ZONE_SPAWN;
          LZone^.Removeable := LRemoveable;
        end;
      end
      else if (LWord = 'SPAWNTRIGGER') or (LWord = 'SPAWNSOUND') then
      begin
        LScanner.MustGetInteger;
        LX := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LY := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LEvent := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LChildEvent := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LRemoveable := LScanner.IntegerValue;
        LZone := @FState.Zones[NewZone];
        LZone^.X1 := LX;
        LZone^.Y1 := LY;
        LZone^.Eval := LEvent;
        LZone^.EndEval := LChildEvent;
        if LWord = 'SPAWNTRIGGER' then
          LZone^.Kind := GREED_ZONE_TRIGGER
        else
          LZone^.Kind := GREED_ZONE_SOUND;
        LZone^.Removeable := LRemoveable;
      end
      else if LWord = 'SPAWNFLI' then
      begin
        LScanner.MustGetInteger;
        LEvent := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LChildEvent := LScanner.IntegerValue;
        LZone := @FState.Zones[NewZone];
        LZone^.Eval := LEvent;
        LZone^.EndEval := LChildEvent;
        LZone^.Kind := GREED_ZONE_FLI;
      end
      else if LWord = 'FORCELOAD' then
      begin
        LScanner.MustGetString;
        LName := LScanner.Token;
        LScanner.MustGetInteger;
        LX := LScanner.IntegerValue;
        if LForceLoads = GREED_MAX_FORCE_LOADS then
          raise EGreedDataException.CreateFmt(STooManyForceLoads, [GREED_MAX_FORCE_LOADS]);
        LForceLumps[LForceLoads] := FArchive.RequireIndexOf(LName);
        LForceCounts[LForceLoads] := LX;
        Inc(LForceLoads);
      end
      else if LWord = 'SPAWNAREATRIGGER' then
      begin
        LZone := @FState.Zones[NewZone];
        LScanner.MustGetInteger;
        LZone^.X1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Y1 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.X2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Y2 := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Eval := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.EndEval := LScanner.IntegerValue;
        LScanner.MustGetInteger;
        LZone^.Removeable := LScanner.IntegerValue;
        LZone^.Kind := GREED_ZONE_AREA_TRIGGER;
      end
      else if LWord = 'BACKDROP' then
      begin
        LScanner.MustGetString;
        FBackdropLump := FArchive.RequireIndexOf(LScanner.Token);
      end
      else if LWord = 'REM' then
        LScanner.SkipToEndOfLine;
    end;
    FScriptProblems := LScanner.Problems;
  finally
    LScanner.Free;
  end;

  for LIndex := 0 to LForceLoads - 1 do
  begin
    FHost.UpdateWait;
    FSpawner.DemandLoadMonster(LForceLumps[LIndex], LForceCounts[LIndex]);
    FHost.UpdateWait;
  end;
  ReadBackdropHalf(FBackdropLump, 0);
  ReadBackdropHalf(FBackdropLump + 1, GREED_BACKDROP_HALF_BYTES);
  RunEvent(0, False);
end;

end.
