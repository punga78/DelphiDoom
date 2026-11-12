{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedEvents                                            }
{                                                                              }
{  The oracle is event.pas of xGreed as it was: the harness                     }
{  Tools\Verifica\175-events compiles the original file and writes              }
{  Tests\Data\Greed\events.golden.txt on the scenarios of                       }
{  DelphiDoom.Tests.Greed.EventScenarios and events.full.golden.txt on the      }
{  scripts of the complete game; here the library runs the same cases           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Events;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Events.Intf, DelphiDoom.Greed.Events, DelphiDoom.Tests.Greed.EventScenarios;

type
  /// <summary>
  ///   The rest of the game for the events, as the stubs of the harness: every call goes to the fingerprint Calls
  ///   and SpawnSprite makes a plain sprite for the values of TEventScenarios.SpawnMakesSprite
  /// </summary>
  TEventGameFake = class(TInterfacedObject, IGreedSpawner, IGreedGameSound, IGreedEventHost)
  public
    Calls: TEventHash;
    State: TGreedGameState;
    LastSpawnValue, LastSound, LastFli, Spawns, Sounds, Activations, Waits, Demands: Integer;
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure ActivationSound(ASprite: Integer);
    procedure PlayFli(AMovie: Integer);
    procedure UpdateWait;
  end;

  /// <summary>The archive of the scenarios: the numbers of the names, the script of the case, the lumps of the sky</summary>
  TEventFakeArchive = class(TInterfacedObject, IGreedArchive)
  public
    Game: TEventGameFake;
    Script: TBytes;
    /// <summary>A sky lump that is shorter than a picture, to try what the library does with it</summary>
    ShortSky: Boolean;
    function GetLumpCount: Integer;
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpSize(AIndex: Integer): Integer;
    function IndexOf(const AName: string): Integer;
    function RequireIndexOf(const AName: string): Integer;
    function ReadLump(AIndex: Integer): TBytes;
    function ReadLumpRaw(AIndex: Integer): TBytes;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedEvents = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FGame: TEventGameFake;
    FGameIntf: IGreedEventHost;
    FArchive: TEventFakeArchive;
    FArchiveIntf: IGreedArchive;
    FEventsObject: TGreedEvents;
    FEvents: IGreedEventRunner;
    procedure NewGame(const AArchive: IGreedArchive);
    procedure Load(const AScript: string; ANewGame: Boolean = True);
    procedure Dirty;
    procedure Feed(var AHash: TEventHash; AFull, ASky: Boolean);
    procedure PrepareCase(const ACase: TEventCase; const AMap: TEventMap);
    function RunCase(const ACase: TEventCase; const AMap: TEventMap): string;
    function RunFull(const AArchive: IGreedArchive; AMap, AVariant: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeLeggereLoScriptDelLumpDopoSux;
    [Test]
    procedure DovrebbeAzzerareLoStatoPrimaDiLeggere;
    [Test]
    procedure DovrebbeMettereTriggerEInterruttoriConLaPrimaCoordinataPerRiga;
    [Test]
    procedure DovrebbeRiempireLAreaDeiTriggerEstremiCompresi;
    [Test]
    procedure DovrebbeCreareLAscensoreDelloScript;
    [Test]
    procedure DovrebbeDareAllAscensoreDiSpawnLEventoFinaleDellUltimoAscensore;
    [Test]
    procedure DovrebbeLeggereObiettiviPunteggioETempo;
    [Test]
    procedure DovrebbeMettereLoSpriteSoloInUnaPartitaNuovaEPerLaDifficolta;
    [Test]
    procedure DovrebbeSaltareLoSpawnGiaUsatoQuandoSiCarica;
    [Test]
    procedure DovrebbeChiedereLeImmaginiDiForceload;
    [Test]
    procedure DovrebbeLeggereIlCieloDelLumpIndicato;
    [Test]
    procedure DovrebbeLasciareZeriSeIlCieloECorto;
    [Test]
    procedure DovrebbeFermarsiAEnd;
    [Test]
    procedure DovrebbeIgnorareRemECommenti;
    [Test]
    procedure DovrebbeContareINumeriSbagliatiSenzaFermarsi;
    [Test]
    procedure DovrebbeSollevareOltreLeZoneDisponibili;
    [Test]
    procedure DovrebbeSollevarePerUnLumpCheNonEsiste;
    [Test]
    procedure DovrebbeSollevareOltreSediciForceload;
    [Test]
    procedure DovrebbeSegnareLEventoDelGiocatoreESpegnereIlPrecedente;
    [Test]
    procedure DovrebbeTogliereTriggerEInterruttoriDellEvento;
    [Test]
    procedure DovrebbeAvviareLAscensoreFermoInBassoOInAlto;
    [Test]
    procedure DovrebbeSvegliareGliSpriteDellaZona;
    [Test]
    procedure DovrebbeFarNascereLoSpriteConIlSuoEventoDiMorte;
    [Test]
    procedure DovrebbeNonFarNascereMentreSiRipetonoGliEventiSalvati;
    [Test]
    procedure DovrebbeMettereIlTriggerELAreaDelleZone;
    [Test]
    procedure DovrebbeSuonareLaZonaDelSuono;
    [Test]
    procedure DovrebbeMostrareIlFilmEUccidereIlGiocatore;
    [Test]
    procedure DovrebbeTogliereLaZonaRimovibile;
    [Test]
    procedure DovrebbeCambiareIlPianoUnPassoAllaVoltaEPoiLanciareLEventoFinale;
    [Test]
    procedure DovrebbeFarSeguireAlGiocatoreIlPavimentoCheSiMuove;
    [Test]
    procedure DovrebbeSollevareSeNonCiSonoProcessi;
    [Test]
    procedure DovrebbeSollevarePerUnPianoNonPrevisto;
    [Test]
    procedure DovrebbeSollevareOltreIProcessiDisponibili;
    [Test]
    procedure DovrebbeIgnorareCioCheCadeFuoriDalleTabelle;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
    [Test]
    procedure DovrebbeLeggereGliScriptDelGiocoCompletoComeLOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData, DelphiDoom.Tests.Shared.Skip;

const
  GOLDEN_NAME = 'events.golden.txt';
  FULL_GOLDEN_NAME = 'events.full.golden.txt';
  FIRST_MAP_LUMP = EVENT_LUMP_MAP + 1;

function TileCentre(ATile: Integer): TGreedFixed;
begin
  Result := (ATile shl GREED_FRACTILESHIFT) + (32 shl GREED_FRACBITS);
end;

{ TEventGameFake }

function TEventGameFake.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
var
  LSprite: PGreedSprite;
begin
  Calls.AddCall(EVENT_CALL_SPAWN, [AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2, Ord(AActive), ASpawnId]);
  Inc(Spawns);
  LastSpawnValue := AValue;
  Result := GREED_POOL_NIL;
  if not TEventScenarios.SpawnMakesSprite(AValue) then
    Exit;
  Result := State.Sprites.Add;
  LSprite := PGreedSprite(State.Sprites.Item(Result));
  LSprite^.Kind := AValue;
  LSprite^.X := AX;
  LSprite^.Y := AY;
  LSprite^.Z := AZ;
  LSprite^.Active := AActive;
  LSprite^.MoveSpeed := TEventScenarios.SpawnedMoveSpeed(AValue);
end;

procedure TEventGameFake.DemandLoadMonster(ALump, ACount: Integer);
begin
  Calls.AddCall(EVENT_CALL_DEMAND, [ALump, ACount]);
  Inc(Demands);
end;

procedure TEventGameFake.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Calls.AddCall(EVENT_CALL_SOUND, [ASound, AVariation, AX, AY]);
  Inc(Sounds);
  LastSound := ASound;
end;

procedure TEventGameFake.ActivationSound(ASprite: Integer);
begin
  Calls.AddCall(EVENT_CALL_ACTIVATION, [ASprite]);
  Inc(Activations);
end;

procedure TEventGameFake.PlayFli(AMovie: Integer);
begin
  Calls.AddCall(EVENT_CALL_FLI, [AMovie]);
  LastFli := AMovie;
end;

procedure TEventGameFake.UpdateWait;
begin
  Calls.AddCall(EVENT_CALL_WAIT, []);
  Inc(Waits);
end;

{ TEventFakeArchive }

function TEventFakeArchive.GetLumpCount: Integer;
begin
  Result := 0;
end;

function TEventFakeArchive.GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
begin
  Result := Default(TGreedLumpInfo);
end;

function TEventFakeArchive.GetLumpName(AIndex: Integer): string;
begin
  Result := '';
end;

function TEventFakeArchive.GetLumpSize(AIndex: Integer): Integer;
begin
  Result := 0;
end;

function TEventFakeArchive.IndexOf(const AName: string): Integer;
begin
  Result := TEventScenarios.LumpNumber(AName);
end;

function TEventFakeArchive.RequireIndexOf(const AName: string): Integer;
begin
  Result := TEventScenarios.LumpNumber(AName);
  if Result < 0 then
    raise EGreedNotFoundException.CreateFmt(SGreedLumpNotFound, [AName]);
end;

function TEventFakeArchive.ReadLump(AIndex: Integer): TBytes;
begin
  Result := ReadLumpRaw(AIndex);
end;

function TEventFakeArchive.ReadLumpRaw(AIndex: Integer): TBytes;
begin
  if (AIndex >= EVENT_LUMP_FIRST_SKY) and (AIndex <= EVENT_LUMP_LAST_SKY) then
  begin
    Result := TEventScenarios.SkyLump(AIndex);
    if ShortSky then
      SetLength(Result, 108);
  end
  else if (AIndex > EVENT_LUMP_SCRIPT) and (AIndex < EVENT_LUMP_FIRST_SKY) then
  begin
    Game.Calls.AddCall(EVENT_CALL_SCRIPT, [AIndex]);
    Result := Script;
  end
  else
    raise EGreedNotFoundException.CreateFmt(SGreedLumpInvalid, [AIndex, 0]);
end;

{ TTestGreedEvents }

procedure TTestGreedEvents.Setup;
begin
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FGame := TEventGameFake.Create;
  FGameIntf := FGame;
  FArchive := TEventFakeArchive.Create;
  FArchiveIntf := FArchive;
  FArchive.Game := FGame;
  NewGame(FArchiveIntf);
end;

procedure TTestGreedEvents.TearDown;
begin
  FEvents := nil;
  FEventsObject := nil;
  FreeAndNil(FState);
  FArchiveIntf := nil;
  FArchive := nil;
  FGameIntf := nil;
  FGame := nil;
  FWorld := nil;
  FreeAndNil(FElevators);
  FreeAndNil(FSprites);
end;

procedure TTestGreedEvents.NewGame(const AArchive: IGreedArchive);
begin
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
  FGame.Sounds := 0;
  FGame.Activations := 0;
  FGame.Waits := 0;
  FGame.Demands := 0;
  FGame.LastFli := -1;
  FEventsObject := TGreedEvents.Create(FState, AArchive, FGame, FGame, FGame);
  FEvents := FEventsObject;
end;

procedure TTestGreedEvents.Load(const AScript: string; ANewGame: Boolean);
begin
  FArchive.Script := TEncoding.ANSI.GetBytes(AScript);
  FEventsObject.LoadScript(FIRST_MAP_LUMP, ANewGame);
end;

procedure TTestGreedEvents.Dirty;
var
  LIndex: Integer;
begin
  FillChar(FState.Triggers, SizeOf(FState.Triggers), EVENT_DIRTY_TRIGGER);
  FillChar(FState.Switches, SizeOf(FState.Switches), EVENT_DIRTY_SWITCH);
  FillChar(FState.Zones, SizeOf(FState.Zones), EVENT_DIRTY_ZONE_BYTE);
  for LIndex := Low(FState.Processes) to High(FState.Processes) do
    FState.Processes[LIndex] := EVENT_DIRTY_PROCESS;
  FState.NumZones := EVENT_DIRTY_COUNT;
  FState.NumProcesses := EVENT_DIRTY_COUNT;
  FState.FliPlayed := EVENT_DIRTY_COUNT;
  FState.BonusTime := EVENT_DIRTY_COUNT;
  FState.LevelScore := EVENT_DIRTY_COUNT;
  for LIndex := Low(FState.Primaries) to High(FState.Primaries) do
    FState.Primaries[LIndex] := EVENT_DIRTY_COUNT;
  for LIndex := Low(FState.Secondaries) to High(FState.Secondaries) do
    FState.Secondaries[LIndex] := EVENT_DIRTY_COUNT;
  for LIndex := Low(FState.PCount) to High(FState.PCount) do
    FState.PCount[LIndex] := EVENT_DIRTY_COUNT;
  for LIndex := Low(FState.SCount) to High(FState.SCount) do
    FState.SCount[LIndex] := EVENT_DIRTY_COUNT;
  FState.FallRate := EVENT_DIRTY_COUNT;
end;

procedure TTestGreedEvents.Feed(var AHash: TEventHash; AFull, ASky: Boolean);
const
  PLANES: array[0..8] of TGreedPlane = (gpNorthWall, gpWestWall, gpFloorPic, gpCeilingPic, gpFloorHeight,
    gpCeilingHeight, gpMapLights, gpMapEffects, gpMapSprites);
var
  LIndex: Integer;
  LSprite: PGreedSprite;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
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
  AHash.Add(FState.Player.X);
  AHash.Add(FState.Player.Y);
  AHash.Add(FState.Player.Z);
  AHash.Add(FState.Player.Angst);
  AHash.Add(FState.Player.LevelScore);
  AHash.Add(FState.FallRate);
  AHash.AddBoolean(FState.GameLoading);
  AHash.AddBoolean(FState.EventLoading);
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
  AHash.Add(Integer(FGame.Calls.Value));
  AHash.Add(FGame.Calls.Count);
  if AFull then
  begin
    AHash.AddBytes(FState.Triggers, EVENT_TILES);
    AHash.AddBytes(FState.Switches, EVENT_TILES);
    AHash.AddBytes(FState.Player.Events, 256);
    for LIndex := Low(PLANES) to High(PLANES) do
    begin
      FWorld.CopyPlane(PLANES[LIndex], @LTiles[0]);
      AHash.AddBytes(LTiles, EVENT_TILES);
    end;
  end;
  if ASky then
    AHash.AddBytes(FEventsObject.Backdrop[0], Length(FEventsObject.Backdrop));
end;

procedure TTestGreedEvents.PrepareCase(const ACase: TEventCase; const AMap: TEventMap);
var
  LSpot, LIndex: Integer;
  LSprite: PGreedSprite;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  NewGame(FArchiveIntf);
  for LSpot := 0 to EVENT_TILES - 1 do
  begin
    FWorld.SetValue(gpNorthWall, LSpot, AMap.NorthWall[LSpot]);
    FWorld.SetValue(gpWestWall, LSpot, AMap.WestWall[LSpot]);
    FWorld.SetValue(gpFloorPic, LSpot, AMap.FloorPic[LSpot]);
    FWorld.SetValue(gpCeilingPic, LSpot, AMap.CeilingPic[LSpot]);
    FWorld.SetValue(gpFloorHeight, LSpot, AMap.FloorHeight[LSpot]);
    FWorld.SetValue(gpCeilingHeight, LSpot, AMap.CeilingHeight[LSpot]);
    FWorld.SetValue(gpMapLights, LSpot, AMap.MapLights[LSpot]);
    FWorld.SetValue(gpMapEffects, LSpot, AMap.MapEffects[LSpot]);
    FWorld.SetValue(gpMapSprites, LSpot, AMap.MapSprites[LSpot]);
    FWorld.SetMapFlags(LSpot, AMap.MapFlags[LSpot]);
  end;
  FState.Player.X := ACase.PlayerX;
  FState.Player.Y := ACase.PlayerY;
  FState.Player.Height := ACase.PlayerHeight;
  FState.Player.TimeCount := ACase.PlayerTime;
  FState.Player.Difficulty := ACase.Difficulty;
  FState.Player.Angst := 100;
  Move(ACase.Events, FState.Player.Events, 256);
  FState.TimeCount := ACase.TimeCount;
  Dirty;
  for LIndex := 0 to ACase.SpriteCount - 1 do
  begin
    LSprite := PGreedSprite(FSprites.Item(FSprites.Add));
    LSprite^.X := ACase.Sprites[LIndex].X;
    LSprite^.Y := ACase.Sprites[LIndex].Y;
    LSprite^.Z := ACase.Sprites[LIndex].Z;
    LSprite^.MoveSpeed := ACase.Sprites[LIndex].MoveSpeed;
    LSprite^.Kind := ACase.Sprites[LIndex].Kind;
    LSprite^.Active := ACase.Sprites[LIndex].Active;
  end;
  for LIndex := 0 to ACase.ElevatorCount - 1 do
  begin
    LElevator := FElevators.Item(FElevators.Add);
    LElevator^.MapSpot := ACase.Elevators[LIndex].MapSpot;
    LElevator^.Floor := ACase.Elevators[LIndex].Floor;
    LElevator^.Ceiling := ACase.Elevators[LIndex].Ceiling;
    LElevator^.Position := ACase.Elevators[LIndex].Position;
    LElevator^.Position64 := LElevator^.Position * GREED_FRACUNIT;
    LElevator^.Eval := ACase.Elevators[LIndex].Eval;
    LElevator^.Kind := getNormal;
  end;
  FArchive.Script := ACase.Script;
  FGame.Calls.Reset;
end;

function TTestGreedEvents.RunCase(const ACase: TEventCase; const AMap: TEventMap): string;
var
  LHash: TEventHash;
  LLoadFailed, LStepFailed: Boolean;
  LLoadHash: Cardinal;
  LStep, LSteps, LEvent: Integer;
begin
  PrepareCase(ACase, AMap);
  LLoadFailed := False;
  try
    FEventsObject.LoadScript(EVENT_LUMP_MAP + ACase.Map + 1, ACase.NewGame);
  except
    on E: EGreedException do
      LLoadFailed := True;
  end;
  LHash.Reset;
  Feed(LHash, True, not LLoadFailed);
  LLoadHash := LHash.Value;
  LSteps := 0;
  LStepFailed := False;
  if not LLoadFailed then
  begin
    FState.EventLoading := ACase.EventLoading;
    for LStep := 0 to EVENT_STEPS - 1 do
    begin
      Inc(FState.TimeCount);
      try
        LEvent := TEventScenarios.StepEvent(ACase.Index, LStep);
        if LEvent >= 0 then
          FEvents.RunEvent(LEvent, False);
        if FState.NumProcesses > 0 then
          FEventsObject.Process;
      except
        on E: EGreedException do
          LStepFailed := True;
      end;
      Feed(LHash, (LStep mod EVENT_FULL_EVERY = 0) or LStepFailed, False);
      Inc(LSteps);
      if LStepFailed then
        Break;
    end;
  end;
  Feed(LHash, True, False);
  Result := TEventScenarios.GoldenLine(ACase, LLoadFailed, FState.NumZones, FState.NumProcesses, LSteps,
    LStepFailed, LLoadHash, LHash.Value);
end;

function TTestGreedEvents.RunFull(const AArchive: IGreedArchive; AMap, AVariant: Integer): string;
var
  LHash: TEventHash;
  LNewGame, LDone, LLoadFailed, LRunFailed: Boolean;
  LDifficulty, LEvent, LSteps, LEvents: Integer;
  LLoadHash: Cardinal;
begin
  TEventScenarios.FullVariant(AVariant, LNewGame, LDifficulty, LDone);
  NewGame(AArchive);
  FState.Player.X := TileCentre(5);
  FState.Player.Y := TileCentre(5);
  FState.Player.Height := 40 shl 16;
  FState.Player.Difficulty := LDifficulty;
  if LDone then
    FillChar(FState.Player.Events, 256, 1);
  FState.TimeCount := 1000;
  Dirty;
  LLoadFailed := False;
  try
    FEventsObject.LoadScript(AArchive.RequireIndexOf('map') + AMap + 1, LNewGame);
  except
    on E: EGreedException do
      LLoadFailed := True;
  end;
  LHash.Reset;
  Feed(LHash, True, not LLoadFailed);
  LLoadHash := LHash.Value;
  LRunFailed := False;
  LEvents := 0;
  if not LLoadFailed then
    for LEvent := 1 to 255 do
    begin
      Inc(FState.TimeCount);
      try
        FEvents.RunEvent(LEvent, False);
        LSteps := 0;
        while (FState.NumProcesses > 0) and (LSteps < EVENT_FULL_PROCESS_STEPS) do
        begin
          FEventsObject.Process;
          Inc(LSteps);
        end;
      except
        on E: EGreedException do
          LRunFailed := True;
      end;
      Feed(LHash, LRunFailed, False);
      Inc(LEvents);
      if LRunFailed then
        Break;
    end;
  Feed(LHash, True, False);
  Result := TEventScenarios.FullLine(AMap, AVariant, LLoadFailed, FState.NumZones, FState.NumProcesses, LEvents,
    LRunFailed, LLoadHash, LHash.Value);
end;

procedure TTestGreedEvents.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedEvents.Create(nil, FArchiveIntf, FGame, FGame, FGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedEvents.Create(FState, nil, FGame, FGame, FGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedEvents.Create(FState, FArchiveIntf, nil, FGame, FGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedEvents.Create(FState, FArchiveIntf, FGame, nil, FGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedEvents.Create(FState, FArchiveIntf, FGame, FGame, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedEvents.DovrebbeLeggereLoScriptDelLumpDopoSux;
begin
  Assert.AreEqual(EVENT_LUMP_SCRIPT + 8, FEventsObject.ScriptLumpOf(EVENT_LUMP_MAP + 8));
  FArchive.Script := TEncoding.ANSI.GetBytes('TRIGGER 1 2 3');
  FEventsObject.LoadScript(EVENT_LUMP_MAP + 8, True);
  Assert.AreEqual(3, Integer(FState.Triggers[1 * 64 + 2]));
  FEventsObject.LoadScriptText(TEncoding.ANSI.GetBytes('TRIGGER 4 5 6'), True);
  Assert.AreEqual(0, Integer(FState.Triggers[1 * 64 + 2]));
  Assert.AreEqual(6, Integer(FState.Triggers[4 * 64 + 5]));
end;

procedure TTestGreedEvents.DovrebbeAzzerareLoStatoPrimaDiLeggere;
var
  LIndex: Integer;
begin
  Dirty;
  Load('');
  Assert.AreEqual(0, FState.NumZones);
  Assert.AreEqual(0, FState.NumProcesses);
  Assert.AreEqual(0, FState.FliPlayed);
  Assert.AreEqual(3150, FState.BonusTime);
  Assert.AreEqual(100000, FState.LevelScore);
  Assert.AreEqual(100000, FState.Player.LevelScore);
  for LIndex := 0 to GREED_MAP_TILES - 1 do
    if (FState.Triggers[LIndex] <> 0) or (FState.Switches[LIndex] <> 0) then
      Assert.Fail('a trigger or a switch was left');
  for LIndex := Low(FState.Processes) to High(FState.Processes) do
    Assert.AreEqual(0, FState.Processes[LIndex]);
  for LIndex := Low(FState.Primaries) to High(FState.Primaries) do
    Assert.AreEqual(-1, FState.Primaries[LIndex]);
  for LIndex := Low(FState.Secondaries) to High(FState.Secondaries) do
    Assert.AreEqual(-1, FState.Secondaries[LIndex]);
  Assert.AreEqual(0, FState.PCount[1]);
  Assert.AreEqual(0, FState.SCount[6]);
  Assert.AreEqual(0, FState.Zones[3].X1);
  // the event 0 is run at the end
  Assert.AreEqual(1, Integer(FState.Player.Events[0]));
end;

procedure TTestGreedEvents.DovrebbeMettereTriggerEInterruttoriConLaPrimaCoordinataPerRiga;
begin
  Load('trigger 3 4 5'#13#10'WallSwitch 20,21,7');
  Assert.AreEqual(5, Integer(FState.Triggers[3 * 64 + 4]));
  Assert.AreEqual(7, Integer(FState.Switches[20 * 64 + 21]));
  Assert.AreEqual(0, Integer(FState.Triggers[4 * 64 + 3]));
end;

procedure TTestGreedEvents.DovrebbeRiempireLAreaDeiTriggerEstremiCompresi;
begin
  Load('AREATRIGGER 10 20 12 21 6');
  Assert.AreEqual(6, Integer(FState.Triggers[10 * 64 + 20]));
  Assert.AreEqual(6, Integer(FState.Triggers[12 * 64 + 21]));
  Assert.AreEqual(0, Integer(FState.Triggers[13 * 64 + 21]));
  Assert.AreEqual(0, Integer(FState.Triggers[12 * 64 + 22]));
end;

procedure TTestGreedEvents.DovrebbeCreareLAscensoreDelloScript;
var
  LElevator: TGreedElevator;
begin
  FState.Player.TimeCount := 777;
  Load('ELEVATOR 5 6 1 2 0 90 30 4'#13#10'ELEVATOR 7 8 3 4 1 80 20 2');
  Assert.AreEqual(2, FElevators.Count);
  LElevator := FElevators.Item(FElevators.First)^;
  Assert.AreEqual(6 * 64 + 5, LElevator.MapSpot);
  Assert.AreEqual(30, LElevator.Floor);
  Assert.AreEqual(90, LElevator.Ceiling);
  Assert.AreEqual(30, LElevator.Position);
  Assert.AreEqual(30 * GREED_FRACUNIT, LElevator.Position64);
  Assert.AreEqual(Ord(getTriggered), Ord(LElevator.Kind));
  Assert.AreEqual(4, LElevator.Speed);
  Assert.AreEqual(1, LElevator.Eval);
  Assert.AreEqual(2, LElevator.EndEval);
  Assert.AreEqual(777, LElevator.Timer);
  Assert.AreEqual(1, LElevator.NoSave);
  Assert.AreEqual(30, Integer(FWorld.GetValue(gpFloorHeight, 6 * 64 + 5)));
  // the second one starts at the top
  Assert.AreEqual(80, Integer(FWorld.GetValue(gpFloorHeight, 8 * 64 + 7)));
end;

procedure TTestGreedEvents.DovrebbeDareAllAscensoreDiSpawnLEventoFinaleDellUltimoAscensore;
var
  LIndex: Integer;
begin
  Load('SPAWNELEVATOR 1 1 3 0 70 10 3'#13#10'ELEVATOR 5 6 1 9 0 90 30 4'#13#10'SPAWNELEVATOR 9 10 3 0 70 10 3');
  LIndex := FElevators.First;
  Assert.AreEqual(0, FElevators.Item(LIndex)^.EndEval, 'without an ELEVATOR line before it');
  Assert.AreEqual(Ord(getNormal), Ord(FElevators.Item(LIndex)^.Kind));
  LIndex := FElevators.Next(FElevators.Next(LIndex));
  Assert.AreEqual(9, FElevators.Item(LIndex)^.EndEval);
  Assert.AreEqual(10 * 64 + 9, FElevators.Item(LIndex)^.MapSpot);
end;

procedure TTestGreedEvents.DovrebbeLeggereObiettiviPunteggioETempo;
begin
  Load('BONUSTIME 90'#13#10'PRIMARY 1 200 2 52'#13#10'SECONDARY 6 20 4 59'#13#10'LEVELSCORE 54321');
  Assert.AreEqual(90 * 70, FState.BonusTime);
  Assert.AreEqual(52, FState.Primaries[2]);
  Assert.AreEqual(200, FState.Primaries[3]);
  Assert.AreEqual(2, FState.PCount[1]);
  Assert.AreEqual(59, FState.Secondaries[12]);
  Assert.AreEqual(20, FState.Secondaries[13]);
  Assert.AreEqual(4, FState.SCount[6]);
  Assert.AreEqual(54321, FState.Player.LevelScore);
  Assert.AreEqual(100000, FState.LevelScore, 'LEVELSCORE is of the player only');
end;

procedure TTestGreedEvents.DovrebbeMettereLoSpriteSoloInUnaPartitaNuovaEPerLaDifficolta;
begin
  FState.Player.Difficulty := 2;
  // the difficulty must be between 5 - the second number and 5 - the first
  Load('SPRITE 40 41 75 0 0 5'#13#10'SPRITE 42 43 77 0 4 5'#13#10'SPRITE 44 45 78 0 3 3');
  Assert.AreEqual(75, Integer(FWorld.GetValue(gpMapSprites, 41 * 64 + 40)));
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 43 * 64 + 42)));
  Assert.AreEqual(78, Integer(FWorld.GetValue(gpMapSprites, 45 * 64 + 44)));
  Assert.IsFalse(FState.GameLoading);
  NewGame(FArchiveIntf);
  FState.Player.Difficulty := 2;
  Load('SPRITE 40 41 75 0 0 5', False);
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 41 * 64 + 40)));
end;

procedure TTestGreedEvents.DovrebbeSaltareLoSpawnGiaUsatoQuandoSiCarica;
begin
  FState.Player.Difficulty := 2;
  FState.Player.Events[7] := 1;
  Load('SPAWN 1 2 7 75 9 0 5 1'#13#10'SPAWN 3 4 7 76 0 0 5 0'#13#10'SPAWN 5 6 8 77 0 0 5 1'#13#10 +
    'SPAWN 7 8 8 78 0 4 5 0', False);
  Assert.AreEqual(2, FState.NumZones, 'the used one that can be removed and the one of another difficulty are left out');
  Assert.AreEqual(76, FState.Zones[0].SType);
  Assert.AreEqual(77, FState.Zones[1].SType);
  Assert.AreEqual(GREED_ZONE_SPAWN, FState.Zones[1].Kind);
  NewGame(FArchiveIntf);
  FState.Player.Difficulty := 2;
  FState.Player.Events[7] := 1;
  Load('SPAWN 1 2 7 75 9 0 5 1');
  Assert.AreEqual(1, FState.NumZones, 'a new game makes it');
  Assert.AreEqual(9, FState.Zones[0].EndEval);
end;

procedure TTestGreedEvents.DovrebbeChiedereLeImmaginiDiForceload;
begin
  Load('FORCELOAD kman 56'#13#10'FORCELOAD WIZ 48');
  Assert.AreEqual(2, FGame.Demands);
  Assert.AreEqual(4, FGame.Waits, 'the wait picture turns before and after each one');
end;

procedure TTestGreedEvents.DovrebbeLeggereIlCieloDelLumpIndicato;
var
  LSky: TBytes;
begin
  Load('');
  Assert.AreEqual(EVENT_LUMP_FIRST_SKY, FEventsObject.BackdropLump);
  Assert.AreEqual<Integer>(GREED_BACKDROP_BYTES, Length(FEventsObject.Backdrop));
  LSky := TEventScenarios.SkyLump(EVENT_LUMP_FIRST_SKY);
  Assert.AreEqual(Integer(LSky[8]), Integer(FEventsObject.Backdrop[0]));
  Assert.AreEqual(Integer(LSky[8 + 32767]), Integer(FEventsObject.Backdrop[32767]));
  LSky := TEventScenarios.SkyLump(EVENT_LUMP_FIRST_SKY + 1);
  Assert.AreEqual(Integer(LSky[8]), Integer(FEventsObject.Backdrop[32768]));
  Load('BACKDROP sky2');
  Assert.AreEqual(EVENT_LUMP_FIRST_SKY + 2, FEventsObject.BackdropLump);
  LSky := TEventScenarios.SkyLump(EVENT_LUMP_FIRST_SKY + 3);
  Assert.AreEqual(Integer(LSky[8 + 100]), Integer(FEventsObject.Backdrop[32768 + 100]));
end;

procedure TTestGreedEvents.DovrebbeLasciareZeriSeIlCieloECorto;
var
  LSky: TBytes;
begin
  Load('');
  FArchive.ShortSky := True;
  Load('');
  LSky := TEventScenarios.SkyLump(EVENT_LUMP_FIRST_SKY);
  Assert.AreEqual(Integer(LSky[8 + 99]), Integer(FEventsObject.Backdrop[99]));
  Assert.AreEqual(0, Integer(FEventsObject.Backdrop[100]));
  Assert.AreEqual(0, Integer(FEventsObject.Backdrop[32768 + 100]));
end;

procedure TTestGreedEvents.DovrebbeFermarsiAEnd;
begin
  Load('TRIGGER 1 2 3'#13#10'end'#13#10'TRIGGER 4 5 6');
  Assert.AreEqual(3, Integer(FState.Triggers[1 * 64 + 2]));
  Assert.AreEqual(0, Integer(FState.Triggers[4 * 64 + 5]));
end;

procedure TTestGreedEvents.DovrebbeIgnorareRemECommenti;
begin
  Load('REM TRIGGER 1 2 3'#13#10'// TRIGGER 4 5 6'#13#10'TRIGGER 7 8 9 // TRIGGER 10 11 12'#13#10'FOO 1 2'#13#10 +
    'TRIGGER 13 14 15');
  Assert.AreEqual(0, Integer(FState.Triggers[1 * 64 + 2]));
  Assert.AreEqual(0, Integer(FState.Triggers[4 * 64 + 5]));
  Assert.AreEqual(9, Integer(FState.Triggers[7 * 64 + 8]));
  Assert.AreEqual(0, Integer(FState.Triggers[10 * 64 + 11]));
  Assert.AreEqual(15, Integer(FState.Triggers[13 * 64 + 14]));
  Assert.AreEqual(0, FEventsObject.ScriptProblems);
end;

procedure TTestGreedEvents.DovrebbeContareINumeriSbagliatiSenzaFermarsi;
begin
  // abc is 0, 12x is 12, $1F is 31; the last command has no numbers: they are the last one read
  Load('TRIGGER abc 12x $1F'#13#10'WALLSWITCH 2 3');
  Assert.AreEqual(31, Integer(FState.Triggers[0 * 64 + 12]));
  Assert.AreEqual(3, Integer(FState.Switches[2 * 64 + 3]));
  Assert.IsTrue(FEventsObject.ScriptProblems >= 2);
end;

procedure TTestGreedEvents.DovrebbeSollevareOltreLeZoneDisponibili;
var
  LScript: string;
  LIndex: Integer;
begin
  LScript := '';
  for LIndex := 1 to 254 do
    LScript := LScript + 'SPAWNFLI 5 1'#13#10;
  Load(LScript);
  Assert.AreEqual(254, FState.NumZones);
  Assert.WillRaise(
    procedure
    begin
      Load(LScript + 'SPAWNFLI 5 1'#13#10);
    end, EGreedDataException);
end;

procedure TTestGreedEvents.DovrebbeSollevarePerUnLumpCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      Load('FORCELOAD nosuch 5');
    end, EGreedNotFoundException);
  Assert.WillRaise(
    procedure
    begin
      Load('BACKDROP nosky');
    end, EGreedNotFoundException);
end;

procedure TTestGreedEvents.DovrebbeSollevareOltreSediciForceload;
var
  LScript: string;
  LIndex: Integer;
begin
  LScript := '';
  for LIndex := 1 to 16 do
    LScript := LScript + 'FORCELOAD kman 1'#13#10;
  Load(LScript);
  Assert.AreEqual(16, FGame.Demands);
  Assert.WillRaise(
    procedure
    begin
      Load(LScript + 'FORCELOAD kman 1');
    end, EGreedDataException);
end;

procedure TTestGreedEvents.DovrebbeSegnareLEventoDelGiocatoreESpegnereIlPrecedente;
begin
  FState.Player.Events[201] := 1;
  FState.Player.Events[9] := 1;
  FEvents.RunEvent(202, False);
  FEvents.RunEvent(10, False);
  FEvents.RunEvent(300, False);
  Assert.AreEqual(1, Integer(FState.Player.Events[202]));
  Assert.AreEqual(0, Integer(FState.Player.Events[201]), 'an even event above 200 puts out the one before it');
  Assert.AreEqual(1, Integer(FState.Player.Events[10]));
  Assert.AreEqual(1, Integer(FState.Player.Events[9]));
end;

procedure TTestGreedEvents.DovrebbeTogliereTriggerEInterruttoriDellEvento;
begin
  Load('TRIGGER 1 2 3'#13#10'TRIGGER 4 5 6'#13#10'WALLSWITCH 7 8 3');
  FEvents.RunEvent(3, False);
  Assert.AreEqual(0, Integer(FState.Triggers[1 * 64 + 2]));
  Assert.AreEqual(6, Integer(FState.Triggers[4 * 64 + 5]));
  Assert.AreEqual(0, Integer(FState.Switches[7 * 64 + 8]));
end;

procedure TTestGreedEvents.DovrebbeAvviareLAscensoreFermoInBassoOInAlto;
var
  LLow, LHigh, LMiddle: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  Load('ELEVATOR 5 6 4 0 0 90 30 4'#13#10'ELEVATOR 7 8 4 0 1 80 20 2'#13#10'ELEVATOR 9 9 4 0 0 80 20 2');
  LLow := FElevators.Item(FElevators.First);
  LHigh := FElevators.Item(FElevators.Next(FElevators.First));
  LMiddle := FElevators.Item(FElevators.Next(FElevators.Next(FElevators.First)));
  LMiddle^.Position := 50;
  FState.TimeCount := 1234;
  FGame.Sounds := 0;
  FEvents.RunEvent(4, False);
  Assert.IsTrue(LLow^.Up);
  Assert.IsFalse(LLow^.Down);
  Assert.AreEqual(0, LLow^.Eval);
  Assert.AreEqual(1234, LLow^.Timer);
  Assert.IsTrue(LHigh^.Down);
  Assert.IsFalse(LMiddle^.Up or LMiddle^.Down, 'an elevator between the two ends waits');
  Assert.AreEqual(4, LMiddle^.Eval);
  Assert.AreEqual(2, FGame.Sounds);
  Assert.AreEqual(GREED_SN_ELEVATORSTART, FGame.LastSound);
end;

procedure TTestGreedEvents.DovrebbeSvegliareGliSpriteDellaZona;
var
  LInside, LOutside, LStill: PGreedSprite;
begin
  LInside := PGreedSprite(FSprites.Item(FSprites.Add));
  LInside^.X := TileCentre(5);
  LInside^.Y := TileCentre(6);
  LInside^.MoveSpeed := 1;
  LOutside := PGreedSprite(FSprites.Item(FSprites.Add));
  LOutside^.X := TileCentre(20);
  LOutside^.Y := TileCentre(6);
  LOutside^.MoveSpeed := 1;
  LStill := PGreedSprite(FSprites.Item(FSprites.Add));
  LStill^.X := TileCentre(5);
  LStill^.Y := TileCentre(6);
  Load('ACTIVATIONZONE 4 4 8 8 2 0');
  FState.TimeCount := 500;
  FEvents.RunEvent(2, False);
  Assert.IsTrue(LInside^.Active);
  Assert.AreEqual(540, LInside^.ActionTime);
  Assert.IsFalse(LOutside^.Active);
  Assert.IsFalse(LStill^.Active, 'a sprite that cannot move is not woken');
  Assert.AreEqual(1, FGame.Activations);
end;

procedure TTestGreedEvents.DovrebbeFarNascereLoSpriteConIlSuoEventoDiMorte;
var
  LSprite: PGreedSprite;
begin
  FState.Player.Difficulty := 2;
  Load('SPAWN 12 13 2 75 9 0 5 1');
  FEvents.RunEvent(2, False);
  Assert.AreEqual(2, FGame.Spawns, 'the warp and the sprite');
  Assert.AreEqual(75, FGame.LastSpawnValue);
  Assert.AreEqual(2, FSprites.Count);
  LSprite := PGreedSprite(FSprites.Item(FSprites.Next(FSprites.First)));
  Assert.AreEqual(9, LSprite^.DeathEvent);
  Assert.AreEqual(TileCentre(12), LSprite^.X);
  Assert.AreEqual(TileCentre(13), LSprite^.Y);
  Assert.AreEqual(10 * GREED_FRACUNIT, LSprite^.Z);
  Assert.IsFalse(FState.GameLoading);
  Assert.AreEqual(GREED_ZONE_REMOVED, FState.Zones[0].Kind);
end;

procedure TTestGreedEvents.DovrebbeNonFarNascereMentreSiRipetonoGliEventiSalvati;
begin
  FState.Player.Difficulty := 2;
  Load('SPAWN 12 13 2 75 0 0 5 0'#13#10'SPAWN 14 15 2 77 6 0 5 0');
  FState.EventLoading := True;
  FEvents.RunEvent(2, False);
  Assert.AreEqual(2, FGame.Spawns, 'only the one with an event of death is made again');
  Assert.AreEqual(77, FGame.LastSpawnValue);
end;

procedure TTestGreedEvents.DovrebbeMettereIlTriggerELAreaDelleZone;
begin
  Load('SPAWNTRIGGER 16 17 2 33 1'#13#10'SPAWNAREATRIGGER 50 40 52 42 3 44 0');
  Assert.AreEqual(0, Integer(FState.Triggers[16 * 64 + 17]));
  FEvents.RunEvent(2, False);
  Assert.AreEqual(33, Integer(FState.Triggers[16 * 64 + 17]));
  FEvents.RunEvent(3, False);
  Assert.AreEqual(44, Integer(FState.Triggers[50 * 64 + 40]));
  Assert.AreEqual(44, Integer(FState.Triggers[51 * 64 + 41]));
  Assert.AreEqual(0, Integer(FState.Triggers[52 * 64 + 41]), 'the last column is not in the area of a zone');
  Assert.AreEqual(0, Integer(FState.Triggers[51 * 64 + 42]));
end;

procedure TTestGreedEvents.DovrebbeSuonareLaZonaDelSuono;
begin
  Load('SPAWNSOUND 18 19 3 12 0');
  FGame.Sounds := 0;
  FEvents.RunEvent(3, False);
  FEvents.RunEvent(3, False);
  Assert.AreEqual(2, FGame.Sounds, 'a zone that is not removed sounds every time');
  Assert.AreEqual(12, FGame.LastSound);
end;

procedure TTestGreedEvents.DovrebbeMostrareIlFilmEUccidereIlGiocatore;
begin
  Load('SPAWNFLI 5 1');
  Assert.AreEqual(100, FState.Player.Angst);
  FEvents.RunEvent(5, False);
  Assert.AreEqual(1, FGame.LastFli);
  Assert.AreEqual(1, FState.FliPlayed);
  Assert.AreEqual(0, FState.Player.Angst);
  Assert.AreEqual(GREED_ZONE_REMOVED, FState.Zones[0].Kind);
  FGame.LastFli := -1;
  FEvents.RunEvent(5, False);
  Assert.AreEqual(-1, FGame.LastFli, 'a film is shown once');
end;

procedure TTestGreedEvents.DovrebbeTogliereLaZonaRimovibile;
begin
  Load('SPAWNSOUND 1 1 3 12 1');
  FGame.Sounds := 0;
  FEvents.RunEvent(3, False);
  FEvents.RunEvent(3, False);
  Assert.AreEqual(1, FGame.Sounds);
  Assert.AreEqual(0, FState.Zones[0].Eval);
end;

procedure TTestGreedEvents.DovrebbeCambiareIlPianoUnPassoAllaVoltaEPoiLanciareLEventoFinale;
var
  LSteps: Integer;
begin
  FWorld.SetValue(gpMapLights, 2 * 64 + 2, 10);
  FWorld.SetValue(gpMapLights, 3 * 64 + 3, 30);
  Load('MAPZONE 2 2 3 3 1 7 14 20 4 1');
  FEvents.RunEvent(1, False);
  Assert.AreEqual(1, FState.NumProcesses);
  Assert.AreEqual(GREED_PROCESS_BASE, FState.Processes[0]);
  FEventsObject.Process;
  Assert.AreEqual(14, Integer(FWorld.GetValue(gpMapLights, 2 * 64 + 2)));
  Assert.AreEqual(26, Integer(FWorld.GetValue(gpMapLights, 3 * 64 + 3)));
  Assert.AreEqual(4, Integer(FWorld.GetValue(gpMapLights, 2 * 64 + 3)));
  LSteps := 1;
  while FState.NumProcesses > 0 do
  begin
    FEventsObject.Process;
    Inc(LSteps);
  end;
  Assert.AreEqual(20, Integer(FWorld.GetValue(gpMapLights, 2 * 64 + 2)));
  Assert.AreEqual(20, Integer(FWorld.GetValue(gpMapLights, 3 * 64 + 3)));
  Assert.AreEqual(20, Integer(FWorld.GetValue(gpMapLights, 2 * 64 + 3)));
  Assert.AreEqual(6, LSteps, 'five steps that change and one that finds nothing to do');
  Assert.AreEqual(1, Integer(FState.Player.Events[7]), 'the end event');
end;

procedure TTestGreedEvents.DovrebbeFarSeguireAlGiocatoreIlPavimentoCheSiMuove;
begin
  FState.Player.X := TileCentre(2);
  FState.Player.Y := TileCentre(2);
  FState.Player.Height := 40 * GREED_FRACUNIT;
  FState.Player.Z := 123;
  FState.FallRate := 9;
  Load('MAPZONE 2 2 2 2 1 0 8 50 5 0'#13#10'MAPZONE 30 30 30 30 2 0 8 50 5 0');
  FEvents.RunEvent(2, False);
  FEventsObject.Process;
  Assert.AreEqual(123, FState.Player.Z, 'the floor under the player did not move');
  Assert.AreEqual(9, FState.FallRate);
  FEvents.RunEvent(1, False);
  FEventsObject.Process;
  Assert.AreEqual(45 * GREED_FRACUNIT, FState.Player.Z);
  Assert.AreEqual(0, FState.FallRate);
end;

procedure TTestGreedEvents.DovrebbeSollevareSeNonCiSonoProcessi;
begin
  Load('');
  Assert.WillRaise(
    procedure
    begin
      FEventsObject.Process;
    end, EGreedException);
end;

procedure TTestGreedEvents.DovrebbeSollevarePerUnPianoNonPrevisto;
begin
  Load('MAPZONE 2 2 3 3 1 0 5 20 4 1');
  FEvents.RunEvent(1, False);
  Assert.WillRaise(
    procedure
    begin
      FEventsObject.Process;
    end, EGreedDataException);
end;

procedure TTestGreedEvents.DovrebbeSollevareOltreIProcessiDisponibili;
var
  LIndex: Integer;
begin
  Load('MAPZONE 2 2 3 3 1 0 8 20 0 0');
  for LIndex := 1 to GREED_MAX_PROCESSES do
    FEventsObject.AddProcess(0);
  Assert.AreEqual(GREED_MAX_PROCESSES, FState.NumProcesses);
  Assert.WillRaise(
    procedure
    begin
      FEvents.RunEvent(1, False);
    end, EGreedException);
end;

procedure TTestGreedEvents.DovrebbeIgnorareCioCheCadeFuoriDalleTabelle;
begin
  // the original writes outside its arrays: here nothing is written
  Load('TRIGGER 70 5 3'#13#10'TRIGGER -1 0 3'#13#10'WALLSWITCH 64 0 3'#13#10'PRIMARY 2 1 1 1'#13#10 +
    'SECONDARY 7 1 1 1'#13#10'SPRITE 0 64 75 0 0 5'#13#10'ELEVATOR 0 64 1 2 0 90 30 4'#13#10 +
    'MAPZONE 62 63 70 70 1 0 8 20 4 1');
  Assert.AreEqual(-1, FState.Primaries[3]);
  Assert.AreEqual(-1, FState.Secondaries[13]);
  Assert.AreEqual(1, FElevators.Count);
  FEvents.RunEvent(1, False);
  FEventsObject.Process;
  Assert.AreEqual(4, Integer(FWorld.GetValue(gpFloorHeight, 63 * 64 + 62)));
  FEvents.RunEvent(-5, False);
  Assert.AreEqual(1, Integer(FState.Player.Events[0]));
end;

procedure TTestGreedEvents.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
var
  LGolden: TStringList;
  LMaps: array[1..4] of TEventMap;
  LCase: TEventCase;
  LIndex, LDifferences: Integer;
  LFirst, LActual: string;
begin
  for LIndex := Low(LMaps) to High(LMaps) do
    TEventScenarios.BuildMap(LIndex, LMaps[LIndex]);
  LDifferences := 0;
  LFirst := '';
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(GOLDEN_NAME));
    Assert.AreEqual(EVENT_CASES + 1, LGolden.Count, 'the golden file is of another list of cases');
    for LIndex := 0 to EVENT_CASES - 1 do
    begin
      LCase := TEventScenarios.CaseAt(LIndex);
      LActual := RunCase(LCase, LMaps[LCase.MapSeed]);
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
  Assert.AreEqual(0, LDifferences, Format('%d cases of %d differ; the first: %s', [LDifferences, EVENT_CASES,
    LFirst]));
end;

procedure TTestGreedEvents.DovrebbeLeggereGliScriptDelGiocoCompletoComeLOriginale;
var
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LMap, LVariant, LLine, LDifferences: Integer;
  LFirst, LActual: string;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('i dati del gioco completo (GREED.BLO) non sono su questa macchina');
  LArchive := TGreedRealData.OpenArchive(TGreedRealData.FullFolder);
  LDifferences := 0;
  LFirst := '';
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(FULL_GOLDEN_NAME));
    Assert.AreEqual(EVENT_FULL_MAPS * EVENT_FULL_VARIANTS + 1, LGolden.Count,
      'the golden file is of another list of maps');
    LLine := 1;
    for LMap := 0 to EVENT_FULL_MAPS - 1 do
      for LVariant := 0 to EVENT_FULL_VARIANTS - 1 do
      begin
        LActual := RunFull(LArchive, LMap, LVariant);
        if LGolden[LLine] <> LActual then
        begin
          Inc(LDifferences);
          if LFirst = '' then
            LFirst := Format('original "%s", library "%s"', [LGolden[LLine], LActual]);
        end;
        Inc(LLine);
      end;
  finally
    LGolden.Free;
  end;
  Assert.AreEqual(0, LDifferences, Format('%d of %d differ; the first: %s', [LDifferences,
    EVENT_FULL_MAPS * EVENT_FULL_VARIANTS, LFirst]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedEvents);

end.
