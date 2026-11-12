{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedMapSession                                        }
{                                                                              }
{  The oracle is utils.pas of xGreed as it was: the harness                     }
{  Tools\Verifica\175-events (SessionGolden) cuts newmap, LoadNewMap,           }
{  ActivateSpritesFromMap, resetengine, respawnplayer, SaveGame and LoadGame    }
{  out of the original file, runs them with event.pas on the scenarios of       }
{  DelphiDoom.Tests.Greed.SessionScenarios and writes                           }
{  Tests\Data\Greed\mapsession.golden.txt; here the library runs the same cases }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.MapSession;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.SaveGames,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.MapReader, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.Events.Intf, DelphiDoom.Greed.Events, DelphiDoom.Greed.MapSession.Intf,
  DelphiDoom.Greed.MapSession, DelphiDoom.Tests.Greed.EventScenarios, DelphiDoom.Tests.Greed.SessionScenarios,
  DelphiDoom.Tests.Greed.Events;

type
  /// <summary>
  ///   The rest of the game for the life of a map, as the stubs of the harness: the calls go to the fingerprint of
  ///   the stand-in of the events; the maps are the ones of the scenarios; the saved games stay in memory
  /// </summary>
  TSessionGameFake = class(TInterfacedObject, IGreedMapSessionHost, IGreedWeaponView, IGreedMapLoader,
    IGreedSaveFiles)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    Game: TEventGameFake;
    Clock: Cardinal;
    LowResolution: Boolean;
    Songs, MusicStops, Briefings, LastEndGame, Textures, MapsLoaded, WeaponsLoaded, LastWeapon, CountResets: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure SelectSong(AMap: Integer);
    procedure StopMusic;
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    procedure LoadTextures;
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    procedure ResetMouse;
    procedure ResetSpawnCounts;
    function GetClock: Cardinal;
    function GetLowResolution: Boolean;
    procedure LoadWeapon(AWeapon: Integer);
    function PictureWidth(AMode: Integer): Integer;
    function PictureHeight(AMode: Integer): Integer;
    function Load(AMapNumber: Integer): IGreedMap;
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
    procedure WriteAll(const AName: string; const ABytes: TBytes);
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedMapSession = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FGame: TEventGameFake;
    FGameIntf: IGreedEventHost;
    FArchive: TEventFakeArchive;
    FArchiveIntf: IGreedArchive;
    FHost: TSessionGameFake;
    FHostIntf: IGreedMapSessionHost;
    FRandom: TGreedRandomTable;
    FRandomIntf: IGreedRandom;
    FEventsObject: TGreedEvents;
    FEvents: IGreedEventRunner;
    FSession: TGreedMapSession;
    procedure NewGame;
    function AddSprite(AKind, ATileX, ATileY, AHitPoints: Integer): PGreedSprite;
    function Saved(ATileX, ATileY: Integer): Integer;
    procedure Feed(var AHash: TEventHash);
    procedure PrepareCase(const ACase: TSessionCase);
    procedure Populate(const ACase: TSessionCase);
    function RunCase(const ACase: TSessionCase): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeAzzerareOrologiERitardi;
    [Test]
    procedure DovrebbeCaricareLaMappaNellOrdineDellOriginale;
    [Test]
    procedure DovrebbeFarNascereOgniCasellaDelPianoDegliSprite;
    [Test]
    procedure DovrebbeAzzerareLeMappeVisteSoloInUnaPartitaNuova;
    [Test]
    procedure DovrebbeMostrareIlBriefingSoloConActivateUno;
    [Test]
    procedure DovrebbeFermareLaMusicaEMostrareIlFinaleAllUltimaMappa;
    [Test]
    procedure DovrebbeNonCaricareLaMappaTreDellaDemo;
    [Test]
    procedure DovrebbeCaricareLeArmiDelGiocatore;
    [Test]
    procedure DovrebbeRimettereIlGiocatoreSuUnaPartenzaLibera;
    [Test]
    procedure DovrebbeSollevareSeNessunaPartenzaELibera;
    [Test]
    procedure DovrebbeSalvareIMostriViviMortiEQuelliCheNonCadono;
    [Test]
    procedure DovrebbeSalvareOggettiESegniDellaMappa;
    [Test]
    procedure DovrebbeSalvarePorteAreeEAscensori;
    [Test]
    procedure DovrebbeSalvareLeParetiDelMondo;
    [Test]
    procedure DovrebbeDareFalsoSeIlSalvataggioNonEsiste;
    [Test]
    procedure DovrebbeRicaricareGliSpriteLeParetiEGliEventiSalvati;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData;

const
  GOLDEN_NAME = 'mapsession.golden.txt';
  /// <case>;<file>: the fingerprint after each part of the state of one case goes to the file (the harness does
  /// the same with a case number and a file), to look for the first thing that differs
  TRACE_VARIABLE = 'DELPHIDOOM_GREED_SESSION_TRACE';

function TileCentre(ATile: Integer): TGreedFixed;
begin
  Result := (ATile shl GREED_FRACTILESHIFT) + (32 shl GREED_FRACBITS);
end;

{ TSessionGameFake }

constructor TSessionGameFake.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TSessionGameFake.Destroy;
begin
  FFiles.Free;
  inherited;
end;

procedure TSessionGameFake.SelectSong(AMap: Integer);
begin
  Game.Calls.AddCall(EVENT_CALL_SONG, [AMap]);
  Inc(Songs);
end;

procedure TSessionGameFake.StopMusic;
begin
  Game.Calls.AddCall(EVENT_CALL_STOP_MUSIC, []);
  Inc(MusicStops);
end;

procedure TSessionGameFake.MissionBriefing(AMap: Integer);
begin
  Game.Calls.AddCall(EVENT_CALL_BRIEFING, [AMap]);
  Inc(Briefings);
end;

procedure TSessionGameFake.EndGame(AEpisode: Integer);
begin
  Game.Calls.AddCall(EVENT_CALL_END_GAME, [AEpisode]);
  LastEndGame := AEpisode;
end;

procedure TSessionGameFake.LoadTextures;
begin
  Game.Calls.AddCall(EVENT_CALL_TEXTURES, []);
  Inc(Textures);
end;

procedure TSessionGameFake.StartWait;
begin
  Game.Calls.AddCall(EVENT_CALL_START_WAIT, []);
end;

procedure TSessionGameFake.UpdateWait;
begin
  Game.UpdateWait;
end;

procedure TSessionGameFake.EndWait;
begin
  Game.Calls.AddCall(EVENT_CALL_END_WAIT, []);
end;

procedure TSessionGameFake.ResetMouse;
begin
  Game.Calls.AddCall(EVENT_CALL_RESET_MOUSE, []);
end;

procedure TSessionGameFake.ResetSpawnCounts;
begin
  Inc(CountResets);
end;

function TSessionGameFake.GetClock: Cardinal;
begin
  Result := Clock;
end;

function TSessionGameFake.GetLowResolution: Boolean;
begin
  Result := LowResolution;
end;

procedure TSessionGameFake.LoadWeapon(AWeapon: Integer);
begin
  Game.Calls.AddCall(EVENT_CALL_LOAD_WEAPON, [AWeapon]);
  Inc(WeaponsLoaded);
  LastWeapon := AWeapon;
end;

function TSessionGameFake.PictureWidth(AMode: Integer): Integer;
begin
  Result := 0;
end;

function TSessionGameFake.PictureHeight(AMode: Integer): Integer;
begin
  Result := 0;
end;

function TSessionGameFake.Load(AMapNumber: Integer): IGreedMap;
var
  LReader: IGreedMapReader;
begin
  Inc(MapsLoaded);
  LReader := TGreedMapReader.Create;
  Result := LReader.Read(TSessionScenarios.MapBytes(TSessionScenarios.SeedOfMap(AMapNumber)));
end;

function TSessionGameFake.Exists(const AName: string): Boolean;
begin
  Result := FFiles.ContainsKey(AName);
end;

function TSessionGameFake.ReadAll(const AName: string): TBytes;
begin
  Result := FFiles[AName];
end;

procedure TSessionGameFake.WriteAll(const AName: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(AName, Copy(ABytes));
end;

{ TTestGreedMapSession }

procedure TTestGreedMapSession.Setup;
begin
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FGame := TEventGameFake.Create;
  FGameIntf := FGame;
  FArchive := TEventFakeArchive.Create;
  FArchiveIntf := FArchive;
  FArchive.Game := FGame;
  FArchive.Lenient := True;
  FHost := TSessionGameFake.Create;
  FHostIntf := FHost;
  FHost.Game := FGame;
  FRandom := TGreedRandomTable.Create;
  FRandomIntf := FRandom;
  NewGame;
end;

procedure TTestGreedMapSession.TearDown;
begin
  FreeAndNil(FSession);
  FEvents := nil;
  FEventsObject := nil;
  FreeAndNil(FState);
  FRandomIntf := nil;
  FRandom := nil;
  FHostIntf := nil;
  FHost := nil;
  FArchiveIntf := nil;
  FArchive := nil;
  FGameIntf := nil;
  FGame := nil;
  FWorld := nil;
  FreeAndNil(FElevators);
  FreeAndNil(FSprites);
end;

procedure TTestGreedMapSession.NewGame;
begin
  FreeAndNil(FSession);
  FEvents := nil;
  FreeAndNil(FState);
  FSprites.Clear;
  FElevators.Clear;
  FWorld := TGreedWorld.Create;
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FState.Player.Angst := 100;
  FGame.State := FState;
  FGame.Calls.Reset;
  FGame.Spawns := 0;
  FHost.Songs := 0;
  FHost.MusicStops := 0;
  FHost.Briefings := 0;
  FHost.LastEndGame := 0;
  FHost.Textures := 0;
  FHost.MapsLoaded := 0;
  FHost.WeaponsLoaded := 0;
  FHost.CountResets := 0;
  FRandom.Offset := 0;
  FArchive.Script := nil;
  FEventsObject := TGreedEvents.Create(FState, FArchiveIntf, FGame, FGame, FGame);
  FEvents := FEventsObject;
  FSession := TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, FEvents, FGame, FRandomIntf,
    TGreedSaveGames.Create(FHost, ggvGame1), FHost, FHost);
end;

function TTestGreedMapSession.AddSprite(AKind, ATileX, ATileY, AHitPoints: Integer): PGreedSprite;
begin
  Result := PGreedSprite(FSprites.Item(FSprites.Add));
  Result^.Kind := AKind;
  Result^.X := TileCentre(ATileX);
  Result^.Y := TileCentre(ATileY);
  Result^.HitPoints := AHitPoints;
end;

function TTestGreedMapSession.Saved(ATileX, ATileY: Integer): Integer;
begin
  Result := FState.Player.SaveSprites[ATileY * 64 + ATileX];
end;

procedure TTestGreedMapSession.Feed(var AHash: TEventHash);
var
  LIndex: Integer;
  LSprite: PGreedSprite;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
  LDoor: TGreedDoor;
  LArea: TGreedSpawnArea;
  LPlane: TGreedPlane;
  LTiles: TEventTiles;
begin
  AHash.Add(FState.NumZones);
  AHash.Add(FState.NumProcesses);
  AHash.Add(FState.FliPlayed);
  for LIndex := Low(FState.Processes) to High(FState.Processes) do
    AHash.Add(FState.Processes[LIndex]);
  for LIndex := 0 to FState.NumZones - 1 do
  begin
    AHash.Add(FState.Zones[LIndex].X1);
    AHash.Add(FState.Zones[LIndex].Y1);
    AHash.Add(FState.Zones[LIndex].X2);
    AHash.Add(FState.Zones[LIndex].Y2);
    AHash.Add(FState.Zones[LIndex].Eval);
    AHash.Add(FState.Zones[LIndex].EndEval);
    AHash.Add(FState.Zones[LIndex].Rate);
    AHash.Add(FState.Zones[LIndex].Layer);
    AHash.Add(FState.Zones[LIndex].NewValue);
    AHash.Add(FState.Zones[LIndex].SType);
    AHash.Add(FState.Zones[LIndex].Removeable);
    AHash.Add(FState.Zones[LIndex].Kind);
  end;
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FSprites.Item(LIndex));
    AHash.Add(LIndex);
    AHash.Add(LSprite^.Kind);
    AHash.Add(LSprite^.X);
    AHash.Add(LSprite^.Y);
    AHash.Add(LSprite^.Z);
    AHash.Add(LSprite^.MoveSpeed);
    AHash.AddBoolean(LSprite^.Active);
    AHash.Add(LSprite^.ActionTime);
    AHash.Add(LSprite^.DeathEvent);
    AHash.Add(LSprite^.HitPoints);
    AHash.AddBoolean(LSprite^.NoFalling);
    LIndex := FSprites.Next(LIndex);
  end;
  AHash.Add(-1);
  LIndex := FElevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LElevator := FElevators.Item(LIndex);
    AHash.Add(LIndex);
    AHash.AddBoolean(LElevator^.Up);
    AHash.AddBoolean(LElevator^.Down);
    AHash.Add(LElevator^.Position);
    AHash.Add(LElevator^.Position64);
    AHash.Add(LElevator^.Timer);
    AHash.Add(LElevator^.Floor);
    AHash.Add(LElevator^.Ceiling);
    AHash.Add(LElevator^.MapSpot);
    AHash.Add(LElevator^.Speed);
    AHash.Add(LElevator^.Eval);
    AHash.Add(LElevator^.EndEval);
    AHash.Add(LElevator^.NoSave);
    AHash.Add(Ord(LElevator^.Kind));
    LIndex := FElevators.Next(LIndex);
  end;
  AHash.Add(-1);
  AHash.Mark('zones, sprites and elevators');
  AHash.Add(FWorld.DoorCount);
  for LIndex := 0 to FWorld.DoorCount - 1 do
  begin
    LDoor := FWorld.GetDoor(LIndex);
    AHash.Add(LDoor.TileX);
    AHash.Add(LDoor.TileY);
    AHash.Add(LDoor.Pic);
    AHash.Add(Ord(LDoor.Orientation));
  end;
  AHash.Add(FWorld.SpawnAreaCount);
  for LIndex := 0 to FWorld.SpawnAreaCount - 1 do
  begin
    LArea := FWorld.GetSpawnArea(LIndex);
    AHash.Add(LArea.MapSpot);
    AHash.Add(LArea.Kind);
  end;
  AHash.Mark('doors and areas');
  AHash.AddBytes(FState.Player, SizeOf(FState.Player));
  AHash.Mark('player');
  AHash.Add(FState.PlayerAngle64);
  AHash.Add(FState.TurnRate);
  AHash.Add(FState.MoveRate);
  AHash.Add(FState.FallRate);
  AHash.Add(FState.StrafRate);
  AHash.AddBoolean(FState.ExitExists);
  AHash.Add(FState.BonusItem.Time);
  AHash.Add(FState.BonusItem.Score);
  AHash.Add(FState.TimeCount);
  AHash.Add(FState.Frames);
  AHash.Add(FState.WeapDelay);
  AHash.Add(FState.SecretDelay);
  AHash.Add(FState.InventoryDelay);
  AHash.Add(FState.UseDelay);
  AHash.Add(FState.JumpDelay);
  AHash.Add(FState.KeyboardDelay);
  AHash.Add(FState.SpriteMoveTime);
  AHash.Add(FState.WallAnimationTime);
  AHash.Add(FSession.TimeMessage);
  AHash.Add(FState.RearViewTime);
  AHash.Add(FState.RearViewDelay);
  AHash.Add(FState.SwitchTime);
  AHash.Add(FState.InventoryTime);
  AHash.AddBoolean(FState.MidgetMode);
  AHash.Add(FSession.FxTimeCount);
  AHash.Add(Length(FState.SecretBuf));
  AHash.Add(FState.GoalItem);
  AHash.Add(FSession.OldGoalItem);
  AHash.AddBoolean(FState.ToggleGoalItem);
  AHash.AddBoolean(FState.GameLoaded);
  AHash.AddBoolean(FState.GameLoading);
  AHash.AddBoolean(FState.EventLoading);
  AHash.Mark('globals');
  for LIndex := Low(FState.Primaries) to High(FState.Primaries) do
    AHash.Add(FState.Primaries[LIndex]);
  for LIndex := Low(FState.Secondaries) to High(FState.Secondaries) do
    AHash.Add(FState.Secondaries[LIndex]);
  for LIndex := Low(FState.PCount) to High(FState.PCount) do
    AHash.Add(FState.PCount[LIndex]);
  for LIndex := Low(FState.SCount) to High(FState.SCount) do
    AHash.Add(FState.SCount[LIndex]);
  AHash.Add(FState.BonusTime);
  AHash.Add(FState.LevelScore);
  AHash.Mark('goals');
  for LIndex := Low(FState.SpriteLumps) to High(FState.SpriteLumps) do
    AHash.Add(FState.SpriteLumps[LIndex]);
  for LIndex := Low(FState.Weapons) to High(FState.Weapons) do
  begin
    AHash.Add(FState.Weapons[LIndex].Charge);
    AHash.Add(FState.Weapons[LIndex].ChargeTime);
  end;
  AHash.Mark('lumps and weapons');
  AHash.Add(FRandom.Offset);
  for LIndex := 0 to GREED_MAXSTARTLOCATIONS - 1 do
  begin
    AHash.Add(FState.StartLocations[LIndex][0]);
    AHash.Add(FState.StartLocations[LIndex][1]);
  end;
  AHash.Mark('random and starts');
  AHash.Add(Integer(FGame.Calls.Value));
  AHash.Add(FGame.Calls.Count);
  AHash.Mark('calls');
  AHash.AddBytes(FState.Triggers, EVENT_TILES);
  AHash.AddBytes(FState.Switches, EVENT_TILES);
  AHash.Mark('triggers and switches');
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
  begin
    if LPlane = gpMapSprites then
      AHash.Mark('planes before the sprites')
    else if LPlane = gpMapSlopes then
      AHash.Mark('mapsprites');
    FWorld.CopyPlane(LPlane, @LTiles[0]);
    AHash.AddBytes(LTiles, EVENT_TILES);
  end;
  FWorld.CopyMapFlags(@LTiles[0]);
  AHash.AddBytes(LTiles, EVENT_TILES);
  AHash.Mark('slopes and flags');
  AHash.AddBytes(FEventsObject.Backdrop[0], Length(FEventsObject.Backdrop));
end;

procedure TTestGreedMapSession.PrepareCase(const ACase: TSessionCase);
var
  LIndex: Integer;
begin
  NewGame;
  FState.ResetWeapons;
  for LIndex := Low(FState.Weapons) to High(FState.Weapons) do
    FState.Weapons[LIndex].Charge := 5;
  FState.TurnRate := SESSION_DIRTY;
  FState.MoveRate := SESSION_DIRTY;
  FState.FallRate := SESSION_DIRTY;
  FState.StrafRate := SESSION_DIRTY;
  FState.ExitExists := True;
  FState.BonusItem.Time := SESSION_DIRTY;
  FState.BonusItem.Score := SESSION_DIRTY;
  FState.TimeCount := SESSION_DIRTY;
  FState.Frames := SESSION_DIRTY;
  FState.WeapDelay := SESSION_DIRTY;
  FState.SecretDelay := SESSION_DIRTY;
  FState.InventoryDelay := SESSION_DIRTY;
  FState.UseDelay := SESSION_DIRTY;
  FState.JumpDelay := SESSION_DIRTY;
  FState.KeyboardDelay := SESSION_DIRTY;
  FState.SpriteMoveTime := SESSION_DIRTY;
  FState.WallAnimationTime := SESSION_DIRTY;
  FSession.TimeMessage := SESSION_DIRTY;
  FState.RearViewTime := SESSION_DIRTY;
  FState.RearViewDelay := SESSION_DIRTY;
  FState.SwitchTime := SESSION_DIRTY;
  FState.InventoryTime := SESSION_DIRTY;
  FState.MidgetMode := True;
  FSession.FxTimeCount := SESSION_DIRTY;
  FState.SecretBuf := 'abc';
  FState.GoalItem := SESSION_DIRTY;
  FSession.OldGoalItem := SESSION_DIRTY;
  FState.ToggleGoalItem := False;
  FState.GameLoaded := False;
  FState.Demo := ACase.Demo;
  FState.Game1 := ACase.Game1;
  FState.Game2 := ACase.Game2;
  FState.Game3 := ACase.Game3;
  FState.Player := Default(TGreedPlayerRecord);
  FState.Player.X := 5 shl 22;
  FState.Player.Y := 5 shl 22;
  FState.Player.Height := ACase.PlayerHeight;
  FState.Player.Difficulty := ACase.Difficulty;
  for LIndex := 0 to 4 do
    FState.Player.Weapons[LIndex] := ACase.Weapons[LIndex];
  FState.Player.CurrentWeapon := ACase.CurrentWeapon;
  FState.Player.ScrollMin := ACase.ScrollMin;
  FState.Player.ScrollMax := ACase.ScrollMax;
  FState.Player.Angst := 100;
  FState.Player.LevelScore := 4242;
  FState.Player.TimeCount := 777;
  FillChar(FState.Player.WestMap, SizeOf(FState.Player.WestMap), 1);
  FillChar(FState.Player.NorthMap, SizeOf(FState.Player.NorthMap), 2);
  FillChar(FState.Player.Events, SizeOf(FState.Player.Events), 1);
  FState.PlayerAngle64 := 3;
  FRandom.Offset := ACase.RandomOffset;
  FHost.Clock := ACase.Clock;
  FHost.LowResolution := ACase.LowResolution;
  FArchive.Script := ACase.Script;
  FGame.Calls.Reset;
end;

procedure TTestGreedMapSession.Populate(const ACase: TSessionCase);
var
  LIndex: Integer;
  LSprite: PGreedSprite;
  LDoor: TGreedDoor;
  LArea: TGreedSpawnArea;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  for LIndex := 0 to ACase.SpriteCount - 1 do
  begin
    LSprite := PGreedSprite(FSprites.Item(FSprites.Add));
    LSprite^.Kind := ACase.Sprites[LIndex].Kind;
    LSprite^.X := ACase.Sprites[LIndex].X;
    LSprite^.Y := ACase.Sprites[LIndex].Y;
    LSprite^.HitPoints := ACase.Sprites[LIndex].HitPoints;
    LSprite^.DeathEvent := ACase.Sprites[LIndex].DeathEvent;
    LSprite^.NoFalling := ACase.Sprites[LIndex].NoFalling;
  end;
  for LIndex := 0 to ACase.DoorCount - 1 do
  begin
    LDoor := FWorld.GetDoor(FWorld.AddDoor(ACase.Doors[LIndex].TileX, ACase.Doors[LIndex].TileY));
    LDoor.Pic := ACase.Doors[LIndex].Pic;
    LDoor.Orientation := TGreedDoorOrientation(ACase.Doors[LIndex].Orientation);
    FWorld.SetDoor(FWorld.DoorCount - 1, LDoor);
  end;
  for LIndex := 0 to ACase.AreaCount - 1 do
  begin
    LArea := Default(TGreedSpawnArea);
    LArea.MapSpot := ACase.Areas[LIndex].MapSpot;
    LArea.Kind := ACase.Areas[LIndex].Kind;
    FWorld.SetSpawnArea(FWorld.AddSpawnArea, LArea);
  end;
  for LIndex := 0 to ACase.ElevatorCount - 1 do
  begin
    LElevator := FElevators.Item(FElevators.Add);
    LElevator^.Kind := TGreedElevatorType(ACase.Elevators[LIndex].Kind);
    LElevator^.Timer := ACase.Elevators[LIndex].Timer;
    LElevator^.MapSpot := ACase.Elevators[LIndex].MapSpot;
    LElevator^.Position := ACase.Elevators[LIndex].Position;
    LElevator^.Floor := ACase.Elevators[LIndex].Floor;
    LElevator^.Ceiling := ACase.Elevators[LIndex].Ceiling;
    LElevator^.NoSave := ACase.Elevators[LIndex].NoSave;
    LElevator^.Up := ACase.Elevators[LIndex].Up;
    LElevator^.Down := ACase.Elevators[LIndex].Down;
  end;
  Move(ACase.Events, FState.Player.Events, 256);
  for LIndex := 0 to GREED_MAXSTARTLOCATIONS - 1 do
  begin
    FState.StartLocations[LIndex][0] := ACase.StartLocations[LIndex][0];
    FState.StartLocations[LIndex][1] := ACase.StartLocations[LIndex][1];
  end;
  FWorld.SetValue(gpMapSprites, ACase.StartLocations[ACase.FreeStart][1] * 64 +
    ACase.StartLocations[ACase.FreeStart][0], 0);
end;

function TTestGreedMapSession.RunCase(const ACase: TSessionCase): string;
var
  LHash: TEventHash;
  LFailed: array[0..3] of Boolean;
  LHashes: array[0..3] of Cardinal;
  LStep: Integer;
begin
  PrepareCase(ACase);
  LHash.Reset;
  for LStep := 0 to 3 do
  begin
    LFailed[LStep] := False;
    try
      case LStep of
        0:
          FSession.NewMap(ACase.Map, ACase.Activate);
        1:
          begin
            Populate(ACase);
            FSession.RespawnPlayer;
          end;
        2:
          FSession.SaveGame(ACase.SaveNumber);
        3:
          begin
            FState.TimeCount := 999;
            FSession.LoadGame(ACase.SaveNumber);
          end;
      end;
    except
      on E: EGreedException do
        LFailed[LStep] := True;
    end;
    Feed(LHash);
    LHashes[LStep] := LHash.Value;
  end;
  Result := TSessionScenarios.GoldenLine(ACase, LFailed[0], LFailed[1], LFailed[2], LFailed[3], FSprites.Count,
    FElevators.Count, LHashes[0], LHashes[1], LHashes[2], LHashes[3]);
end;

procedure TTestGreedMapSession.DovrebbeSollevareSenzaUnaDipendenza;
var
  LSaves: IGreedSaveGames;
begin
  LSaves := TGreedSaveGames.Create(FHost, ggvGame1);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(nil, FArchiveIntf, FHost, FEventsObject, FEvents, FGame, FRandomIntf, LSaves, FHost,
        FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, nil, FHost, FEventsObject, FEvents, FGame, FRandomIntf, LSaves, FHost, FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, nil, FEventsObject, FEvents, FGame, FRandomIntf, LSaves, FHost,
        FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, nil, FEvents, FGame, FRandomIntf, LSaves, FHost, FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, nil, FGame, FRandomIntf, LSaves, FHost,
        FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, FEvents, nil, FRandomIntf, LSaves, FHost,
        FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, FEvents, FGame, nil, LSaves, FHost, FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, FEvents, FGame, FRandomIntf, nil, FHost,
        FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, FEvents, FGame, FRandomIntf, LSaves, nil,
        FHost);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMapSession.Create(FState, FArchiveIntf, FHost, FEventsObject, FEvents, FGame, FRandomIntf, LSaves,
        FHost, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedMapSession.DovrebbeAzzerareOrologiERitardi;
begin
  FState.TimeCount := 500;
  FState.Player.TimeCount := 500;
  FState.FallRate := 9;
  FState.MidgetMode := True;
  FState.ExitExists := True;
  FState.SecretBuf := 'abc';
  FSession.TimeMessage := 7;
  FSession.FxTimeCount := 7;
  FSession.ResetEngine;
  Assert.AreEqual(0, FState.TimeCount);
  Assert.AreEqual(0, FState.Player.TimeCount);
  Assert.AreEqual(0, FState.FallRate);
  Assert.IsFalse(FState.MidgetMode);
  Assert.IsFalse(FState.ExitExists);
  Assert.AreEqual('', FState.SecretBuf);
  Assert.AreEqual(2100, FState.BonusItem.Time);
  Assert.AreEqual(0, FSession.TimeMessage);
  Assert.AreEqual(0, FSession.FxTimeCount);
end;

procedure TTestGreedMapSession.DovrebbeCaricareLaMappaNellOrdineDellOriginale;
var
  LMap: TBytes;
begin
  FSprites.Add;
  FElevators.Add;
  FState.GoalItem := 4;
  FSession.OldGoalItem := 4;
  FSession.LoadNewMap(1);
  Assert.AreEqual(0, FSprites.Count, 'the world is cleared');
  Assert.AreEqual(0, FElevators.Count);
  Assert.AreEqual(1, FHost.CountResets);
  Assert.AreEqual(1, FHost.MapsLoaded);
  Assert.AreEqual(1, FHost.Textures);
  Assert.AreEqual(-1, FState.GoalItem);
  Assert.AreEqual(-1, FSession.OldGoalItem);
  Assert.IsTrue(FState.ToggleGoalItem);
  Assert.AreEqual(TSessionScenarios.LumpNumber('kman'), TSessionScenarios.LumpNumber('KMAN'));
  Assert.IsTrue(FState.SpriteLumps[0] >= 0);
  LMap := TSessionScenarios.MapBytes(TSessionScenarios.SeedOfMap(1));
  Assert.AreEqual(Integer(LMap[100]), Integer(FWorld.GetValue(gpNorthWall, 100)));
  Assert.AreEqual(Integer(LMap[SESSION_PLANE_SPRITES * 4096 + 7]), Integer(FWorld.GetValue(gpMapSprites, 7)));
end;

procedure TTestGreedMapSession.DovrebbeFarNascereOgniCasellaDelPianoDegliSprite;
begin
  FWorld.SetValue(gpMapSprites, 3 * 64 + 2, 75);
  FWorld.SetValue(gpMapSprites, 5 * 64 + 4, 200);
  FSession.ActivateSpritesFromMap;
  Assert.AreEqual(2, FGame.Spawns);
  Assert.AreEqual(200, FGame.LastSpawnValue);
  Assert.IsFalse(FState.GameLoading);
  // 75 makes a sprite in the stand-in: at the centre of its tile, not active
  Assert.AreEqual(TileCentre(2), PGreedSprite(FSprites.Item(FSprites.First))^.X);
  Assert.AreEqual(TileCentre(3), PGreedSprite(FSprites.Item(FSprites.First))^.Y);
  Assert.IsFalse(PGreedSprite(FSprites.Item(FSprites.First))^.Active);
end;

procedure TTestGreedMapSession.DovrebbeAzzerareLeMappeVisteSoloInUnaPartitaNuova;
begin
  FState.Player.WestMap[5] := 1;
  FState.Player.Events[9] := 1;
  FState.Player.X := 77;
  FSession.NewMap(0, 0);
  Assert.AreEqual(1, Integer(FState.Player.WestMap[5]));
  Assert.AreEqual(1, Integer(FState.Player.Events[9]));
  Assert.AreEqual(77, FState.Player.X);
  Assert.AreEqual(0, FGame.Spawns, 'a loaded map waits for its saved sprites');
  FSession.NewMap(0, 2);
  Assert.AreEqual(0, Integer(FState.Player.WestMap[5]));
  Assert.AreEqual(0, Integer(FState.Player.Events[9]));
  Assert.AreEqual(-1, FState.Player.X);
  Assert.AreEqual(0, FState.Player.Map);
  Assert.IsTrue(FGame.Spawns > 1000, 'the sprites of the map are made');
end;

procedure TTestGreedMapSession.DovrebbeMostrareIlBriefingSoloConActivateUno;
begin
  FSession.NewMap(1, 2);
  Assert.AreEqual(0, FHost.Briefings);
  FSession.NewMap(1, 1);
  Assert.AreEqual(1, FHost.Briefings);
  Assert.AreEqual(2, FHost.Songs);
  Assert.AreEqual(1, FState.Player.Map);
end;

procedure TTestGreedMapSession.DovrebbeFermareLaMusicaEMostrareIlFinaleAllUltimaMappa;
begin
  FSession.NewMap(8, 2);
  Assert.AreEqual(1, FHost.LastEndGame);
  Assert.AreEqual(1, FHost.MusicStops);
  Assert.AreEqual(0, FHost.MapsLoaded, 'the last map of the episode is not loaded');
  NewGame;
  FState.Game1 := False;
  FState.Game2 := True;
  FSession.NewMap(16, 2);
  Assert.AreEqual(2, FHost.LastEndGame);
  FSession.NewMap(8, 2);
  Assert.AreEqual(1, FHost.MapsLoaded, 'the map 8 is a map as the others in the second episode');
  NewGame;
  FState.Game1 := False;
  FSession.NewMap(22, 2);
  Assert.AreEqual(3, FHost.LastEndGame, 'without an episode the end is the one of the third');
  Assert.AreEqual(1, FHost.MusicStops);
end;

procedure TTestGreedMapSession.DovrebbeNonCaricareLaMappaTreDellaDemo;
begin
  FState.Demo := True;
  FSession.NewMap(3, 2);
  Assert.AreEqual(0, FHost.MapsLoaded);
  Assert.AreEqual(0, FHost.LastEndGame);
  FSession.NewMap(8, 2);
  Assert.AreEqual(1, FHost.MapsLoaded, 'the demo has no end of the episode');
end;

procedure TTestGreedMapSession.DovrebbeCaricareLeArmiDelGiocatore;
begin
  FState.Player.Weapons[0] := 7;
  FState.Player.Weapons[1] := -1;
  FState.Player.Weapons[2] := 3;
  FState.Player.Weapons[3] := -1;
  FState.Player.Weapons[4] := 40;
  FState.Weapons[7].Charge := 0;
  FState.Weapons[1].Charge := 0;
  FSession.NewMap(0, 2);
  Assert.AreEqual(100, FState.Weapons[7].Charge);
  Assert.AreEqual(FState.Weapons[7].ChargeRate, FState.Weapons[7].ChargeTime, 'the clock is 0 after resetengine');
  Assert.AreEqual(100, FState.Weapons[3].Charge);
  Assert.AreEqual(0, FState.Weapons[1].Charge);
end;

procedure TTestGreedMapSession.DovrebbeRimettereIlGiocatoreSuUnaPartenzaLibera;
var
  LIndex: Integer;
begin
  for LIndex := 0 to GREED_MAXSTARTLOCATIONS - 1 do
  begin
    FState.StartLocations[LIndex][0] := 10 + LIndex;
    FState.StartLocations[LIndex][1] := 20;
    FWorld.SetValue(gpMapSprites, 20 * 64 + 10 + LIndex, 75);
  end;
  FWorld.SetValue(gpMapSprites, 20 * 64 + 13, 0);
  FWorld.SetValue(gpFloorHeight, 20 * 64 + 13, 30);
  FState.Player.Height := 40 * GREED_FRACUNIT;
  FSession.RespawnPlayer;
  Assert.AreEqual(TileCentre(13), FState.Player.X);
  Assert.AreEqual(TileCentre(20), FState.Player.Y);
  Assert.AreEqual(70 * GREED_FRACUNIT, FState.Player.Z);
  Assert.AreEqual(256, FState.Player.Angle);
  Assert.AreEqual(256 * 64, FState.PlayerAngle64);
  Assert.IsTrue(FRandom.Offset > 0);
end;

procedure TTestGreedMapSession.DovrebbeSollevareSeNessunaPartenzaELibera;
begin
  // every start place is the tile 0, 0
  FWorld.SetValue(gpMapSprites, 0, 75);
  Assert.WillRaise(
    procedure
    begin
      FSession.RespawnPlayer;
    end, EGreedException);
end;

procedure TTestGreedMapSession.DovrebbeSalvareIMostriViviMortiEQuelliCheNonCadono;
begin
  AddSprite(GREED_S_MONSTER1, 1, 1, 50);
  AddSprite(GREED_S_MONSTER1, 2, 1, 50)^.NoFalling := True;
  AddSprite(GREED_S_MONSTER1, 3, 1, 0);
  AddSprite(GREED_S_MONSTER1, 4, 1, 50)^.DeathEvent := 3;
  AddSprite(GREED_S_MONSTER2, 5, 1, 0);
  AddSprite(GREED_S_MONSTER5, 6, 1, 50)^.NoFalling := True;
  AddSprite(GREED_S_MONSTER15, 7, 1, 0);
  AddSprite(GREED_S_MONSTER13, 8, 1, 9)^.NoFalling := True;
  FSession.FillSaveData;
  Assert.AreEqual(GREED_S_MONSTER1, Saved(1, 1));
  Assert.AreEqual(GREED_S_MONSTER1_NS, Saved(2, 1));
  Assert.AreEqual(GREED_S_DEADMONSTER1, Saved(3, 1));
  Assert.AreEqual(0, Saved(4, 1), 'the script makes again a monster with an event of death');
  Assert.AreEqual(0, Saved(5, 1), 'the corpse of the monster 2 is not saved');
  Assert.AreEqual(GREED_S_MONSTER5, Saved(6, 1));
  Assert.AreEqual(GREED_S_DEADMONSTER15, Saved(7, 1));
  Assert.AreEqual(GREED_S_MONSTER13_NS, Saved(8, 1));
end;

procedure TTestGreedMapSession.DovrebbeSalvareOggettiESegniDellaMappa;
begin
  AddSprite(GREED_S_AMMOBOX, 1, 2, 0);
  AddSprite(GREED_S_WEAPON18, 2, 2, 0);
  AddSprite(GREED_S_ITEM25, 3, 2, 0);
  AddSprite(GREED_S_ITEM26, 4, 2, 0);
  AddSprite(GREED_S_WARP, 5, 2, 0);
  // outside the map: not saved, and nothing is written
  AddSprite(GREED_S_AMMOBOX, 2, 70, 0);
  FWorld.SetValue(gpMapSprites, 10, GREED_SM_WARP2);
  FWorld.SetValue(gpMapSprites, 11, GREED_SM_SWITCHDOWN);
  FWorld.SetValue(gpMapSprites, 12, GREED_SM_SWITCHDOWN2);
  FWorld.SetValue(gpMapSprites, 13, GREED_SM_SWAPSWITCH);
  FWorld.SetValue(gpMapSprites, 14, GREED_SM_STRIGGER);
  FWorld.SetValue(gpMapSprites, 15, GREED_SM_EXIT);
  FWorld.SetValue(gpMapSprites, 16, GREED_SM_MEDPAK1);
  FSession.FillSaveData;
  Assert.AreEqual(GREED_S_AMMOBOX, Saved(1, 2));
  Assert.AreEqual(GREED_S_WEAPON18, Saved(2, 2));
  Assert.AreEqual(GREED_S_ITEM25, Saved(3, 2));
  Assert.AreEqual(0, Saved(4, 2));
  Assert.AreEqual(0, Saved(5, 2));
  Assert.AreEqual(GREED_SM_WARP2, Saved(10, 0));
  Assert.AreEqual(GREED_S_TRIGGER1, Saved(11, 0));
  Assert.AreEqual(GREED_S_TRIGGER2, Saved(12, 0));
  Assert.AreEqual(GREED_S_SWAPSWITCH, Saved(13, 0));
  Assert.AreEqual(GREED_S_STRIGGER, Saved(14, 0));
  Assert.AreEqual(GREED_S_EXIT, Saved(15, 0));
  Assert.AreEqual(0, Saved(16, 0));
end;

procedure TTestGreedMapSession.DovrebbeSalvarePorteAreeEAscensori;
var
  LDoor: TGreedDoor;
  LArea: TGreedSpawnArea;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;

  procedure AddDoor(ATileX, ATileY, AKind: Integer; AOrientation: TGreedDoorOrientation);
  begin
    LDoor := FWorld.GetDoor(FWorld.AddDoor(ATileX, ATileY));
    LDoor.Pic := TSessionScenarios.LumpNumber('door_' + IntToStr(AKind)) - TSessionScenarios.LumpNumber('startwalls');
    LDoor.Orientation := AOrientation;
    FWorld.SetDoor(FWorld.DoorCount - 1, LDoor);
  end;

  procedure AddArea(ASpot, AKind: Integer);
  begin
    LArea := Default(TGreedSpawnArea);
    LArea.MapSpot := ASpot;
    LArea.Kind := AKind;
    FWorld.SetSpawnArea(FWorld.AddSpawnArea, LArea);
  end;

  procedure AddElevator(ASpot: Integer; AKind: TGreedElevatorType; ATimer: Integer);
  begin
    LElevator := FElevators.Item(FElevators.Add);
    LElevator^.MapSpot := ASpot;
    LElevator^.Kind := AKind;
    LElevator^.Timer := ATimer;
    LElevator^.Floor := 10;
    LElevator^.Ceiling := 50;
    LElevator^.Position := 10;
  end;

begin
  AddDoor(1, 3, 1, gdoVertical);
  AddDoor(2, 3, 7, gdoHorizontal2);
  AddDoor(3, 3, 4, gdoVertical2);
  AddArea(200, 0);
  AddArea(201, 1);
  AddArea(202, 10);
  AddArea(203, 24);
  AddArea(204, 100);
  AddArea(205, 101);
  AddArea(206, 5);
  AddElevator(300, getNormal, 5);
  AddElevator(301, getNormal, $70000000);
  AddElevator(302, getNormal, 5);
  LElevator^.NoSave := 1;
  AddElevator(303, getTimed, 12600);
  AddElevator(304, getTimed, 25200);
  AddElevator(305, getTimed, 63000);
  AddElevator(306, getTimed, 7);
  AddElevator(307, getSwitchDown, 0);
  AddElevator(308, getSwitchDown2, 0);
  AddElevator(309, getSecret, 0);
  AddElevator(310, getSwap, 0);
  AddElevator(311, getSwap, 0);
  LElevator^.Position := 50;
  AddElevator(312, getSwap, 0);
  LElevator^.Position := 30;
  AddElevator(313, getTriggered, 0);
  FSession.FillSaveData;
  Assert.AreEqual(GREED_S_VDOOR1, Saved(1, 3));
  Assert.AreEqual(GREED_S_HDOOR1 + 12, Saved(2, 3));
  Assert.AreEqual(GREED_S_VDOOR4, Saved(3, 3));
  Assert.AreEqual(GREED_S_GENERATOR1, Integer(FState.Player.SaveSprites[200]));
  Assert.AreEqual(GREED_S_GENERATOR2, Integer(FState.Player.SaveSprites[201]));
  Assert.AreEqual(GREED_S_SPAWN1, Integer(FState.Player.SaveSprites[202]));
  Assert.AreEqual(GREED_S_SPAWN15, Integer(FState.Player.SaveSprites[203]));
  Assert.AreEqual(GREED_S_SPAWN8_NS, Integer(FState.Player.SaveSprites[204]));
  Assert.AreEqual(GREED_S_SPAWN9_NS, Integer(FState.Player.SaveSprites[205]));
  Assert.AreEqual(0, Integer(FState.Player.SaveSprites[206]));
  Assert.AreEqual(GREED_S_ELEVATOR, Integer(FState.Player.SaveSprites[300]));
  Assert.AreEqual(GREED_S_PAUSEDELEVATOR, Integer(FState.Player.SaveSprites[301]));
  Assert.AreEqual(0, Integer(FState.Player.SaveSprites[302]), 'an elevator of the script is not saved');
  Assert.AreEqual(GREED_S_ELEVATOR3M, Integer(FState.Player.SaveSprites[303]));
  Assert.AreEqual(GREED_S_ELEVATOR6M, Integer(FState.Player.SaveSprites[304]));
  Assert.AreEqual(GREED_S_ELEVATOR15M, Integer(FState.Player.SaveSprites[305]));
  Assert.AreEqual(0, Integer(FState.Player.SaveSprites[306]));
  Assert.AreEqual(GREED_S_TRIGGERD1, Integer(FState.Player.SaveSprites[307]));
  Assert.AreEqual(GREED_S_TRIGGERD2, Integer(FState.Player.SaveSprites[308]));
  Assert.AreEqual(GREED_S_SDOOR, Integer(FState.Player.SaveSprites[309]));
  Assert.AreEqual(GREED_S_ELEVATORLOW, Integer(FState.Player.SaveSprites[310]));
  Assert.AreEqual(GREED_S_ELEVATORHIGH, Integer(FState.Player.SaveSprites[311]));
  Assert.AreEqual(0, Integer(FState.Player.SaveSprites[312]), 'a swap elevator that is half way is not saved');
  Assert.AreEqual(0, Integer(FState.Player.SaveSprites[313]));
end;

procedure TTestGreedMapSession.DovrebbeSalvareLeParetiDelMondo;
var
  LPlayer: TGreedPlayerRecord;
  LSaves: IGreedSaveGames;
begin
  FWorld.SetValue(gpWestWall, 9, 33);
  FWorld.SetValue(gpNorthWall, 4000, 44);
  FState.Player.SaveSprites[5] := 99;
  FState.Player.Score := 1234;
  FSession.SaveGame(3);
  Assert.AreEqual(33, Integer(FState.Player.WestWall[9]));
  Assert.AreEqual(44, Integer(FState.Player.NorthWall[4000]));
  Assert.AreEqual(0, Integer(FState.Player.SaveSprites[5]), 'the saved sprites start empty');
  LSaves := TGreedSaveGames.Create(FHost, ggvGame1);
  Assert.IsTrue(LSaves.LoadGame(3, LPlayer));
  Assert.AreEqual(1234, LPlayer.Score);
  Assert.AreEqual(33, Integer(LPlayer.WestWall[9]));
end;

procedure TTestGreedMapSession.DovrebbeDareFalsoSeIlSalvataggioNonEsiste;
begin
  FState.Player.Score := 55;
  FState.TimeCount := 9;
  Assert.IsFalse(FSession.LoadGame(4));
  Assert.AreEqual(55, FState.Player.Score);
  Assert.AreEqual(9, FState.TimeCount);
  Assert.AreEqual(0, FHost.MapsLoaded);
end;

procedure TTestGreedMapSession.DovrebbeRicaricareGliSpriteLeParetiEGliEventiSalvati;
var
  LSpot: Integer;
begin
  FArchive.Script := TEncoding.ANSI.GetBytes('TRIGGER 1 2 3'#13#10'SPAWNSOUND 5 5 3 12 0'#13#10'LEVELSCORE 500');
  FSession.NewMap(2, 2);
  // only one thing is left on the map
  FSprites.Clear;
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    FWorld.SetValue(gpMapSprites, LSpot, 0);
  AddSprite(GREED_S_AMMOBOX, 30, 31, 0);
  FWorld.SetValue(gpWestWall, 9, 33);
  FState.Player.Events[3] := 1;
  FState.Player.LevelScore := 321;
  FState.Player.TimeCount := 4000;
  FState.Player.Angle := 100;
  FState.Player.CurrentWeapon := 1;
  FState.Player.Weapons[1] := 9;
  FState.Player.ScrollMin := 0;
  FState.Player.ScrollMax := 400;
  FSession.SaveGame(1);
  FWorld.SetValue(gpWestWall, 9, 0);
  FState.Player.LevelScore := 0;
  FGame.Spawns := 0;
  FGame.Sounds := 0;
  FHost.WeaponsLoaded := 0;
  FHost.LowResolution := False;
  Assert.IsTrue(FSession.LoadGame(1));
  Assert.AreEqual(1, FGame.Spawns, 'only the saved sprite is made');
  Assert.AreEqual(GREED_S_AMMOBOX, FGame.LastSpawnValue);
  Assert.AreEqual(33, Integer(FWorld.GetValue(gpWestWall, 9)));
  Assert.AreEqual(321, FState.Player.LevelScore, 'the score of the level is the saved one, not the one of the script');
  Assert.AreEqual(6400, FState.PlayerAngle64);
  Assert.AreEqual(1, FHost.WeaponsLoaded);
  Assert.AreEqual(9, FHost.LastWeapon);
  Assert.IsTrue(FState.GameLoaded);
  Assert.IsFalse(FState.EventLoading);
  Assert.AreEqual(1, FGame.Sounds, 'the event 3 is run again');
  Assert.AreEqual(0, Integer(FState.Triggers[1 * 64 + 2]), 'and its trigger is gone');
  // kept defect: resetengine clears the clock of the player before it is used
  Assert.AreEqual(0, FState.TimeCount);
  Assert.AreEqual(0, FState.Player.TimeCount);
end;

procedure TTestGreedMapSession.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
var
  LGolden: TStringList;
  LIndex, LDifferences: Integer;
  LFirst, LActual, LTrace: string;
begin
  LDifferences := 0;
  LFirst := '';
  LTrace := GetEnvironmentVariable(TRACE_VARIABLE);
  if LTrace <> '' then
  begin
    EventHashTrace := TStringList.Create;
    try
      RunCase(TSessionScenarios.CaseAt(StrToInt(Copy(LTrace, 1, Pos(';', LTrace) - 1))));
      EventHashTrace.SaveToFile(Copy(LTrace, Pos(';', LTrace) + 1, MaxInt));
    finally
      FreeAndNil(EventHashTrace);
    end;
  end;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(GOLDEN_NAME));
    Assert.AreEqual(SESSION_CASES + 1, LGolden.Count, 'the golden file is of another list of cases');
    for LIndex := 0 to SESSION_CASES - 1 do
    begin
      LActual := RunCase(TSessionScenarios.CaseAt(LIndex));
      if LGolden[LIndex + 1] <> LActual then
      begin
        Inc(LDifferences);
        if LFirst = '' then
          LFirst := Format('original "%s", library "%s"', [LGolden[LIndex + 1], LActual]);
      end;
    end;
  finally
    LGolden.Free;
  end;
  Assert.AreEqual(0, LDifferences, Format('%d cases of %d differ; the first: %s', [LDifferences, SESSION_CASES,
    LFirst]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMapSession);

end.
