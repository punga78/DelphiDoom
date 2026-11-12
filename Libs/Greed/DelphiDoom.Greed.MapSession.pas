{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the life of a map: new, saved, loaded            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): newmap, LoadNewMap,         }
{  ActivateSpritesFromMap, resetengine, respawnplayer, SaveGame and LoadGame    }
{  of utils.pas and RF_ClearWorld of r_public.pas                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MapSession;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Events.Intf, DelphiDoom.Greed.MapSession.Intf;

type
  /// <summary>
  ///   The part of utils.pas that starts, saves and loads a map, line by line over TGreedGameState.
  ///   NewMap(map, activate) is newmap: activate 1 is a new game (the briefing is shown), 2 a new map without the
  ///   briefing, 0 a map that is loaded for a saved game. Its order: the maps seen by the player and its events are
  ///   cleared (if activate is not 0), the music starts or stops, the briefing, ResetEngine, then - unless the map is
  ///   the end of the episode, which shows its end screens instead - LoadNewMap (StartWait, the lumps of the sprites,
  ///   the world cleared and loaded, LoadTextures), LoadScript and, if activate is not 0, ActivateSpritesFromMap;
  ///   then EndWait and the weapons of the player are charged.
  ///   SaveGame fills the three planes of the player record (savesprites, westwall, northwall) from the world and
  ///   writes it; LoadGame reads it, loads the map without its sprites, makes the saved ones, puts back the walls
  ///   and runs again the events that had happened.
  ///   The globals of the original that TGreedGameState does not have are properties here: OldGoalItem (display.pas),
  ///   TimeMessage (timemsg of d_font.pas) and FxTimeCount. The net game is not ported: the "or netmode" of the
  ///   conditions of newmap, netsendtime and nethurtsoundtime of resetengine and NetNewPlayerData of respawnplayer
  ///   are not here. The map from a file (-file) is the job of the map loader.
  ///   Kept defects of the original: LoadGame takes the clock of the saved game after resetengine has cleared it,
  ///   so a loaded game always starts at the tic 0; a dead monster of the kind 2 is not saved; a monster with an
  ///   event of death is not saved (the script makes it again); what is saved later on a tile replaces what was
  ///   saved before (sprites, then the marks of the map, doors, spawn areas, elevators).
  ///   Differences: a sprite, a spawn area or an elevator outside the map is not saved (the original wrote outside
  ///   the record); a weapon number outside the table is not charged and a current weapon outside the five of the
  ///   player loads the weapon 0 (the original read outside); respawnplayer stops with EGreedException after
  ///   100000 tries (the original never ends if every start place is taken)
  /// </summary>
  TGreedMapSession = class
  strict private
    FState: TGreedGameState;
    FArchive: IGreedArchive;
    FMapLoader: IGreedMapLoader;
    FScript: IGreedMapScript;
    FEvents: IGreedEventRunner;
    FSpawner: IGreedSpawner;
    FRandom: IGreedRandom;
    FSaveGames: IGreedSaveGames;
    FWeaponView: IGreedWeaponView;
    FHost: IGreedMapSessionHost;
    FOldGoalItem: Integer;
    FTimeMessage: Integer;
    FFxTimeCount: Integer;
    procedure SaveSpot(ASpot, AValue: Integer);
    procedure SaveSprites;
    procedure SaveMapMarks;
    procedure SaveDoors;
    procedure SaveSpawnAreas;
    procedure SaveElevators;
    procedure LoadMapAndScript(AMap, AActivate: Integer);
    class function MonsterNumber(AKind: Integer): Integer; static;
    class function IsSavedAsItIs(AKind: Integer): Boolean; static;
  public
    /// <summary>
    ///   AState has the world, the pools and the globals of the game; AArchive gives the numbers of the lumps;
    ///   AMapLoader reads a map; AScript is LoadScript and AEvents RunEvent (TGreedEvents is both); ASpawner is
    ///   SpawnSprite; ARandom is MS_RndT; ASaveGames writes and reads the player record; AWeaponView is loadweapon;
    ///   AHost is the rest of the game. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const AArchive: IGreedArchive; const AMapLoader: IGreedMapLoader;
      const AScript: IGreedMapScript; const AEvents: IGreedEventRunner; const ASpawner: IGreedSpawner;
      const ARandom: IGreedRandom; const ASaveGames: IGreedSaveGames; const AWeaponView: IGreedWeaponView;
      const AHost: IGreedMapSessionHost);
    /// <summary>resetengine: the clocks, the speeds and the delays of the game start again</summary>
    procedure ResetEngine;
    /// <summary>
    ///   RF_ClearWorld: no sprites, no elevators, no blood. The doors and the spawn areas are emptied by the world
    ///   when it loads a map
    /// </summary>
    procedure ClearWorld;
    /// <summary>
    ///   LoadNewMap(lump) for the map of a number: the lumps of the sprites (slumps), no goal item, the world
    ///   cleared and loaded from the map, then the textures
    /// </summary>
    procedure LoadNewMap(AMap: Integer);
    /// <summary>ActivateSpritesFromMap: SpawnSprite for every tile of the plane of the sprites that is not 0</summary>
    procedure ActivateSpritesFromMap;
    /// <summary>newmap(map, activate)</summary>
    procedure NewMap(AMap, AActivate: Integer);
    /// <summary>respawnplayer: the player is put on a start place that is free, looking north</summary>
    procedure RespawnPlayer;
    /// <summary>The part of SaveGame before the file: savesprites, westwall and northwall of the player record</summary>
    procedure FillSaveData;
    /// <summary>SaveGame(n)</summary>
    procedure SaveGame(ANumber: Integer);
    /// <summary>LoadGame(n); False, and nothing changed, if there is no such saved game</summary>
    function LoadGame(ANumber: Integer): Boolean;
    /// <summary>oldgoalitem of display.pas: -1 after a map is loaded</summary>
    property OldGoalItem: Integer read FOldGoalItem write FOldGoalItem;
    /// <summary>timemsg of d_font.pas: until when the message on the screen stays</summary>
    property TimeMessage: Integer read FTimeMessage write FTimeMessage;
    /// <summary>fxtimecount: the clock of the sound effects</summary>
    property FxTimeCount: Integer read FFxTimeCount write FFxTimeCount;
  end;

implementation

uses
  DelphiDoom.Greed.Terrain, DelphiDoom.Greed.SaveGames;

const
  SNoFreeStart = 'respawnplayer: no start place is free';

  LUMP_MAP = 'map';
  LUMP_START_WALLS = 'startwalls';
  LUMP_DOOR = 'door_';
  DOOR_KINDS = 7;
  NORTH = 256;
  HALF_TILE = 32;
  BONUS_ITEM_TIME = 2100;
  FULL_CHARGE = 100;
  /// the calls to UpdateWait of LoadNewMap and DoLoadMapData before the textures
  LOAD_MAP_WAITS = 25;
  /// the timer of an elevator that waits for a switch
  ELEVATOR_PAUSED = $70000000;
  ELEVATOR_3_MINUTES = 12600;
  ELEVATOR_6_MINUTES = 25200;
  ELEVATOR_15_MINUTES = 63000;
  MAX_RESPAWN_TRIES = 100000;
  LAST_MAP_OF_DEMO = 3;
  LAST_MAP_OF_GAME1 = 8;
  LAST_MAP_OF_GAME2 = 16;
  LAST_MAP_OF_GAME3 = 22;

  /// S_MONSTER1 .. S_MONSTER15; the value that does not fall is the next one and the corpse is 256 - the number
  MONSTER_KINDS: array[1..15] of Integer = (
    GREED_S_MONSTER1, GREED_S_MONSTER2, GREED_S_MONSTER3, GREED_S_MONSTER4, GREED_S_MONSTER5, GREED_S_MONSTER6,
    GREED_S_MONSTER7, GREED_S_MONSTER8, GREED_S_MONSTER9, GREED_S_MONSTER10, GREED_S_MONSTER11, GREED_S_MONSTER12,
    GREED_S_MONSTER13, GREED_S_MONSTER14, GREED_S_MONSTER15);

{ TGreedMapSession }

constructor TGreedMapSession.Create(AState: TGreedGameState; const AArchive: IGreedArchive;
  const AMapLoader: IGreedMapLoader; const AScript: IGreedMapScript; const AEvents: IGreedEventRunner;
  const ASpawner: IGreedSpawner; const ARandom: IGreedRandom; const ASaveGames: IGreedSaveGames;
  const AWeaponView: IGreedWeaponView; const AHost: IGreedMapSessionHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(AMapLoader) then
    raise EArgumentNilException.Create('AMapLoader');
  if not Assigned(AScript) then
    raise EArgumentNilException.Create('AScript');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(ASaveGames) then
    raise EArgumentNilException.Create('ASaveGames');
  if not Assigned(AWeaponView) then
    raise EArgumentNilException.Create('AWeaponView');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FArchive := AArchive;
  FMapLoader := AMapLoader;
  FScript := AScript;
  FEvents := AEvents;
  FSpawner := ASpawner;
  FRandom := ARandom;
  FSaveGames := ASaveGames;
  FWeaponView := AWeaponView;
  FHost := AHost;
end;

procedure TGreedMapSession.ResetEngine;
begin
  FState.TurnRate := 0;
  FState.MoveRate := 0;
  FState.FallRate := 0;
  FState.StrafRate := 0;
  FState.ExitExists := False;
  FState.BonusItem.Time := BONUS_ITEM_TIME;
  FState.BonusItem.Score := 0;
  FState.TimeCount := 0;
  FState.Frames := 0;
  FState.Player.TimeCount := 0;
  FState.WeapDelay := 0;
  FState.SecretDelay := 0;
  FState.InventoryDelay := 0;
  FState.UseDelay := 0;
  FState.JumpDelay := 0;
  FState.KeyboardDelay := 0;
  FState.SpriteMoveTime := 0;
  FState.WallAnimationTime := 0;
  FTimeMessage := 0;
  FState.RearViewTime := 0;
  FState.RearViewDelay := 0;
  FState.SwitchTime := 0;
  FState.InventoryTime := 0;
  FState.MidgetMode := False;
  FFxTimeCount := 0;
  FState.SecretBuf := '';
  FHost.ResetMouse;
end;

procedure TGreedMapSession.ClearWorld;
begin
  FState.Sprites.Clear;
  FState.Elevators.Clear;
  FHost.ResetSpawnCounts;
end;

procedure TGreedMapSession.LoadNewMap(AMap: Integer);
var
  LIndex: Integer;
  LMap: IGreedMap;
begin
  FHost.StartWait;
  for LIndex := Low(FState.SpriteLumps) to High(FState.SpriteLumps) do
    FState.SpriteLumps[LIndex] := FArchive.RequireIndexOf(TGreedGameTables.SpriteLumpNames[LIndex]);
  FState.GoalItem := -1;
  FOldGoalItem := -1;
  FState.ToggleGoalItem := True;
  ClearWorld;
  LMap := FMapLoader.Load(AMap);
  // the world clears its doors and its spawn areas, copies the planes, clears the flags of the tiles, gives a
  // floor and a ceiling to the tiles that have none and activates the slopes
  FState.World.Load(LMap);
  // the original turns the wait picture between its steps: here they are one
  for LIndex := 1 to LOAD_MAP_WAITS do
    FHost.UpdateWait;
  FHost.LoadTextures;
end;

procedure TGreedMapSession.ActivateSpritesFromMap;
var
  LX, LY, LValue: Integer;
begin
  FState.GameLoading := True;
  for LY := 0 to GREED_MAP_SIZE - 1 do
    for LX := 0 to GREED_MAP_SIZE - 1 do
    begin
      LValue := FState.World.GetValue(gpMapSprites, LY * GREED_MAP_SIZE + LX);
      if LValue <> 0 then
        FSpawner.SpawnSprite(LValue, (LX * GREED_MAP_SIZE + HALF_TILE) * GREED_FRACUNIT,
          (LY * GREED_MAP_SIZE + HALF_TILE) * GREED_FRACUNIT, 0, 0, 0, 0, False, 0);
    end;
  FState.GameLoading := False;
end;

procedure TGreedMapSession.LoadMapAndScript(AMap, AActivate: Integer);
var
  LLump: Integer;
begin
  LLump := FArchive.RequireIndexOf(LUMP_MAP) + AMap + 1;
  LoadNewMap(AMap);
  if AActivate <> 0 then
  begin
    FScript.LoadScript(LLump, True);
    ActivateSpritesFromMap;
  end
  else
    FScript.LoadScript(LLump, False);
end;

procedure TGreedMapSession.NewMap(AMap, AActivate: Integer);
var
  LIndex, LWeapon: Integer;
  LDidEnd: Boolean;
begin
  if AActivate <> 0 then
  begin
    FillChar(FState.Player.WestMap, SizeOf(FState.Player.WestMap), 0);
    FillChar(FState.Player.NorthMap, SizeOf(FState.Player.NorthMap), 0);
    FillChar(FState.Player.Events, SizeOf(FState.Player.Events), 0);
    FState.Player.X := -1;
  end;
  FState.Player.Map := AMap;
  if (FState.Game1 and (AMap <> LAST_MAP_OF_GAME1)) or (FState.Game2 and (AMap <> LAST_MAP_OF_GAME2)) or
    (FState.Game3 and (AMap <> LAST_MAP_OF_GAME3)) then
    FHost.SelectSong(AMap)
  else
    FHost.StopMusic;
  if AActivate = 1 then
    FHost.MissionBriefing(AMap);
  ResetEngine;
  if FState.Demo then
  begin
    if AMap <> LAST_MAP_OF_DEMO then
      LoadMapAndScript(AMap, AActivate);
  end
  else
  begin
    LDidEnd := False;
    if FState.Game1 then
    begin
      if AMap = LAST_MAP_OF_GAME1 then
      begin
        FHost.EndGame(1);
        LDidEnd := True;
      end;
    end
    else if FState.Game2 then
    begin
      if AMap = LAST_MAP_OF_GAME2 then
      begin
        FHost.EndGame(2);
        LDidEnd := True;
      end;
    end
    else if AMap = LAST_MAP_OF_GAME3 then
    begin
      FHost.EndGame(3);
      LDidEnd := True;
    end;
    if not LDidEnd then
      LoadMapAndScript(AMap, AActivate);
  end;
  FHost.EndWait;
  for LIndex := Low(FState.Player.Weapons) to High(FState.Player.Weapons) do
    if FState.Player.Weapons[LIndex] <> -1 then
    begin
      LWeapon := FState.Player.Weapons[LIndex];
      if (LWeapon >= Low(FState.Weapons)) and (LWeapon <= High(FState.Weapons)) then
      begin
        FState.Weapons[LWeapon].Charge := FULL_CHARGE;
        FState.Weapons[LWeapon].ChargeTime := FState.TimeCount + FState.Weapons[LWeapon].ChargeRate;
      end;
    end;
end;

procedure TGreedMapSession.RespawnPlayer;
var
  LSpot, LX, LY, LPlace, LTries: Integer;
begin
  LTries := 0;
  repeat
    Inc(LTries);
    if LTries > MAX_RESPAWN_TRIES then
      raise EGreedException.Create(SNoFreeStart);
    LPlace := Integer((FHost.GetClock + FRandom.Next) mod GREED_MAXSTARTLOCATIONS);
    LX := FState.StartLocations[LPlace][0];
    LY := FState.StartLocations[LPlace][1];
    LSpot := LY * GREED_MAP_SIZE + LX;
  until FState.World.GetValue(gpMapSprites, LSpot) = 0;
  FState.Player.X := (LX * GREED_FRACTILEUNIT) + (HALF_TILE * GREED_FRACUNIT);
  FState.Player.Y := (LY * GREED_FRACTILEUNIT) + (HALF_TILE * GREED_FRACUNIT);
  FState.Player.Z := TGreedTerrain.FloorZ(FState.World, FState.Player.X, FState.Player.Y) + FState.Player.Height;
  FState.Player.Angle := NORTH;
  FState.PlayerAngle64 := NORTH * 64;
end;

procedure TGreedMapSession.SaveSpot(ASpot, AValue: Integer);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.Player.SaveSprites[ASpot] := Byte(AValue);
end;

class function TGreedMapSession.MonsterNumber(AKind: Integer): Integer;
var
  LNumber: Integer;
begin
  for LNumber := Low(MONSTER_KINDS) to High(MONSTER_KINDS) do
    if MONSTER_KINDS[LNumber] = AKind then
      Exit(LNumber);
  Result := 0;
end;

class function TGreedMapSession.IsSavedAsItIs(AKind: Integer): Boolean;
begin
  Result := ((AKind >= GREED_S_DEADMONSTER15) and (AKind <= GREED_S_DEADMONSTER1)) or
    (AKind = GREED_S_AMMOBOX) or (AKind = GREED_S_MEDBOX) or (AKind = GREED_S_GOODIEBOX) or
    (AKind = GREED_S_PROXMINE) or (AKind = GREED_S_TIMEMINE) or
    ((AKind >= GREED_S_PRIMARY1) and (AKind <= GREED_S_SECONDARY7)) or
    ((AKind >= GREED_S_WEAPON0) and (AKind <= GREED_S_WEAPON18)) or
    ((AKind >= GREED_S_ITEM1) and (AKind <= GREED_S_ITEM25));
end;

procedure TGreedMapSession.SaveSprites;
var
  LIndex, LSpot, LMonster: Integer;
  LSprite: PGreedSprite;
begin
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
    LSpot := (LSprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (LSprite^.X div GREED_FRACTILEUNIT);
    LMonster := MonsterNumber(LSprite^.Kind);
    if LMonster <> 0 then
    begin
      if LSprite^.DeathEvent = 0 then
      begin
        if LSprite^.HitPoints <> 0 then
        begin
          // the monster 5 has no value that does not fall
          if LSprite^.NoFalling and (LMonster <> 5) then
            SaveSpot(LSpot, LSprite^.Kind + 1)
          else
            SaveSpot(LSpot, LSprite^.Kind);
        end
        // the corpse of the monster 2 is not saved
        else if LMonster <> 2 then
          SaveSpot(LSpot, 256 - LMonster);
      end;
    end
    else if IsSavedAsItIs(LSprite^.Kind) then
      SaveSpot(LSpot, LSprite^.Kind);
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

procedure TGreedMapSession.SaveMapMarks;
var
  LSpot, LValue: Integer;
begin
  for LSpot := 0 to GREED_MAP_TILES - 1 do
  begin
    LValue := FState.World.GetValue(gpMapSprites, LSpot);
    case LValue of
      GREED_SM_WARP1, GREED_SM_WARP2, GREED_SM_WARP3:
        SaveSpot(LSpot, LValue);
      GREED_SM_SWITCHDOWN:
        SaveSpot(LSpot, GREED_S_TRIGGER1);
      GREED_SM_SWITCHDOWN2:
        SaveSpot(LSpot, GREED_S_TRIGGER2);
      GREED_SM_SWAPSWITCH:
        SaveSpot(LSpot, GREED_S_SWAPSWITCH);
      GREED_SM_STRIGGER:
        SaveSpot(LSpot, GREED_S_STRIGGER);
      GREED_SM_EXIT:
        SaveSpot(LSpot, GREED_S_EXIT);
    end;
  end;
end;

procedure TGreedMapSession.SaveDoors;
var
  LIndex, LKind, LWallLump: Integer;
  LDoor: TGreedDoor;
begin
  LWallLump := FArchive.RequireIndexOf(LUMP_START_WALLS);
  for LIndex := 0 to FState.World.DoorCount - 1 do
  begin
    LDoor := FState.World.GetDoor(LIndex);
    for LKind := 1 to DOOR_KINDS do
      if LDoor.Pic = FArchive.RequireIndexOf(LUMP_DOOR + IntToStr(LKind)) - LWallLump then
      begin
        if (LDoor.Orientation = gdoVertical) or (LDoor.Orientation = gdoVertical2) then
          SaveSpot(LDoor.TileY * GREED_MAP_SIZE + LDoor.TileX, GREED_S_VDOOR1 + (LKind - 1) * 2)
        else
          SaveSpot(LDoor.TileY * GREED_MAP_SIZE + LDoor.TileX, GREED_S_HDOOR1 + (LKind - 1) * 2);
        Break;
      end;
  end;
end;

procedure TGreedMapSession.SaveSpawnAreas;
var
  LIndex: Integer;
  LArea: TGreedSpawnArea;
begin
  for LIndex := 0 to FState.World.SpawnAreaCount - 1 do
  begin
    LArea := FState.World.GetSpawnArea(LIndex);
    case LArea.Kind of
      0:
        SaveSpot(LArea.MapSpot, GREED_S_GENERATOR1);
      1:
        SaveSpot(LArea.MapSpot, GREED_S_GENERATOR2);
      10..24:
        SaveSpot(LArea.MapSpot, GREED_S_SPAWN1 + LArea.Kind - 10);
      100:
        SaveSpot(LArea.MapSpot, GREED_S_SPAWN8_NS);
      101:
        SaveSpot(LArea.MapSpot, GREED_S_SPAWN9_NS);
    end;
  end;
end;

procedure TGreedMapSession.SaveElevators;
var
  LIndex: Integer;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  LIndex := FState.Elevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LElevator := FState.Elevators.Item(LIndex);
    case LElevator^.Kind of
      getNormal:
        if LElevator^.NoSave = 0 then
        begin
          if LElevator^.Timer = ELEVATOR_PAUSED then
            SaveSpot(LElevator^.MapSpot, GREED_S_PAUSEDELEVATOR)
          else
            SaveSpot(LElevator^.MapSpot, GREED_S_ELEVATOR);
        end;
      getTimed:
        case LElevator^.Timer of
          ELEVATOR_3_MINUTES:
            SaveSpot(LElevator^.MapSpot, GREED_S_ELEVATOR3M);
          ELEVATOR_6_MINUTES:
            SaveSpot(LElevator^.MapSpot, GREED_S_ELEVATOR6M);
          ELEVATOR_15_MINUTES:
            SaveSpot(LElevator^.MapSpot, GREED_S_ELEVATOR15M);
        end;
      getSwitchDown:
        SaveSpot(LElevator^.MapSpot, GREED_S_TRIGGERD1);
      getSwitchDown2:
        SaveSpot(LElevator^.MapSpot, GREED_S_TRIGGERD2);
      getSecret:
        SaveSpot(LElevator^.MapSpot, GREED_S_SDOOR);
      getSwap:
        if ((LElevator^.Position = LElevator^.Floor) and not LElevator^.Up) or LElevator^.Down then
          SaveSpot(LElevator^.MapSpot, GREED_S_ELEVATORLOW)
        else if ((LElevator^.Position = LElevator^.Ceiling) and not LElevator^.Down) or LElevator^.Up then
          SaveSpot(LElevator^.MapSpot, GREED_S_ELEVATORHIGH);
    end;
    LIndex := FState.Elevators.Next(LIndex);
  end;
end;

procedure TGreedMapSession.FillSaveData;
begin
  FHost.StartWait;
  FillChar(FState.Player.SaveSprites, SizeOf(FState.Player.SaveSprites), 0);
  FState.World.CopyPlane(gpWestWall, @FState.Player.WestWall[0]);
  FState.World.CopyPlane(gpNorthWall, @FState.Player.NorthWall[0]);
  FHost.UpdateWait;
  SaveSprites;
  FHost.UpdateWait;
  SaveMapMarks;
  FHost.UpdateWait;
  SaveDoors;
  FHost.UpdateWait;
  SaveSpawnAreas;
  FHost.UpdateWait;
  SaveElevators;
  FHost.UpdateWait;
end;

procedure TGreedMapSession.SaveGame(ANumber: Integer);
begin
  FillSaveData;
  FHost.UpdateWait;
  FSaveGames.SaveGame(ANumber, FState.Player);
  FHost.UpdateWait;
  FHost.EndWait;
end;

function TGreedMapSession.LoadGame(ANumber: Integer): Boolean;
var
  LPlayer: TGreedPlayerRecord;
  LIndex, LOldScore, LWeapon: Integer;
begin
  Result := FSaveGames.LoadGame(ANumber, LPlayer);
  if not Result then
    Exit;
  FState.Player := LPlayer;
  LOldScore := FState.Player.LevelScore;

  FState.PlayerAngle64 := FState.Player.Angle * 64;

  ResetEngine;
  FState.GameLoaded := True;
  TGreedSaveGames.AdjustScroll(FState.Player, FHost.GetLowResolution);
  // resetengine has cleared the clock of the player: the loaded game starts at 0, as in the original
  FState.TimeCount := FState.Player.TimeCount;
  FState.KeyboardDelay := 0;
  FState.BonusItem.Time := FState.TimeCount + BONUS_ITEM_TIME;
  FState.WallAnimationTime := FState.Player.TimeCount;
  FState.SpriteMoveTime := FState.Player.TimeCount;

  NewMap(FState.Player.Map, 0);
  for LIndex := 0 to GREED_MAP_TILES - 1 do
    FState.World.SetValue(gpMapSprites, LIndex, FState.Player.SaveSprites[LIndex]);
  ActivateSpritesFromMap;
  FState.TimeCount := FState.Player.TimeCount;
  LWeapon := 0;
  if (FState.Player.CurrentWeapon >= Low(FState.Player.Weapons)) and
    (FState.Player.CurrentWeapon <= High(FState.Player.Weapons)) then
    LWeapon := FState.Player.Weapons[FState.Player.CurrentWeapon];
  FWeaponView.LoadWeapon(LWeapon);
  FState.Player.LevelScore := LOldScore;
  for LIndex := 0 to GREED_MAP_TILES - 1 do
  begin
    FState.World.SetValue(gpWestWall, LIndex, FState.Player.WestWall[LIndex]);
    FState.World.SetValue(gpNorthWall, LIndex, FState.Player.NorthWall[LIndex]);
  end;
  FState.EventLoading := True;
  for LIndex := 1 to 255 do
    if FState.Player.Events[LIndex] <> 0 then
      FEvents.RunEvent(LIndex, True);
  FState.EventLoading := False;
end;

end.
