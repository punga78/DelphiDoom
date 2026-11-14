{******************************************************************************}
{                                                                              }
{  DelphiDoom: a game of Greed played by TGreedGame without a window, with      }
{  the fingerprints of its whole world                                         }
{                                                                              }
{  The side of the library of the parity with the original game (the harness    }
{  Tools\Verifica\175-world plays the same game with the code of xGreed): the   }
{  same commands from the same seed, two tics before every turn of the loop,    }
{  the same clock, the view of 320 x 200                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.WorldRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Game, DelphiDoom.Tests.Greed.WorldCommands,
  DelphiDoom.Tests.Greed.WorldPrint;

const
  /// <summary>The tics of the timer before every turn of the loop, and the clock of the system for each of them</summary>
  WORLD_TICS_PER_FRAME = 2;
  WORLD_CLOCK_PER_TIC = 14;
  WORLD_CLOCK_PER_SEED = 1000;

type
  /// <summary>
  ///   Plays a map of the data in a folder (GREED.BLO) with the commands of a seed and gives a line of fingerprints
  ///   for the turns asked, in the format of the golden files of the world:
  ///   W map seed turn timecount history total player sprites elevators doors areas planes events globals sounds
  /// </summary>
  TLibraryWorldRunner = class
  strict private
    FArchive: IGreedArchive;
    FFolder: string;
    FDumpFrame: Integer;
    FDumpFile: string;
    FAllFrames: Boolean;
    FRearView: Boolean;
    FRecordTo: TStream;
    FPlayFrom: TBytes;
    FTapeOutOfStep: Boolean;
    FSaveTurns: string;
    procedure PrintWorld(AGame: TGreedGame; ARandom: TGreedRandomTable; APrint: TWorldPrint);
  public
    /// <summary>EGreedNotFoundException if the folder has no GREED.BLO</summary>
    constructor Create(const AFolder: string);
    /// <summary>
    ///   The lines of a game of AFrames turns on the map, one every AEvery turns (and the last one), added to
    ///   ALines
    /// </summary>
    procedure Play(AMap, ASeed, AFrames, AEvery: Integer; ALines: TStrings);
    /// <summary>After that turn every value of the world is written in a file as name=value (-1: never)</summary>
    property DumpFrame: Integer read FDumpFrame write FDumpFrame;
    property DumpFile: string read FDumpFile write FDumpFile;
    /// <summary>A line for every turn</summary>
    property AllFrames: Boolean read FAllFrames write FAllFrames;
    /// <summary>
    ///   The player also uses the rear view camera (the key A), and each line gets one more column: the
    ///   fingerprint of the picture of the camera (rearbuf), which also goes in the history
    /// </summary>
    property RearView: Boolean read FRearView write FRearView;
    /// <summary>
    ///   The game is recorded on this stream as a tape of TGreedDemoWriter (nil, the default: no tape). The stream
    ///   is not owned
    /// </summary>
    property RecordTo: TStream read FRecordTo write FRecordTo;
    /// <summary>
    ///   The game is not driven by the commands of the seed but by this tape (TGreedDemoPlayer): the commands, the
    ///   clock of the system and the tics of each turn. Empty (the default): no tape
    /// </summary>
    property PlayFrom: TBytes read FPlayFrom write FPlayFrom;
    /// <summary>The last game played from a tape asked for something that the tape did not have next</summary>
    property TapeOutOfStep: Boolean read FTapeOutOfStep;
    /// <summary>
    ///   The turns after which the game is saved and loaded again as the menu does (SaveGame and LoadGame), as a
    ///   list "300,700"; the length and the fingerprint of the bytes of the saved game go in the history. Empty
    ///   (the default): never
    /// </summary>
    property SaveTurns: string read FSaveTurns write FSaveTurns;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.GameRendererFactory, DelphiDoom.Greed.HudView,
  DelphiDoom.Greed.Demo.Types, DelphiDoom.Greed.Demo.Intf, DelphiDoom.Greed.Demo.Writer, DelphiDoom.Greed.Demo.Reader,
  DelphiDoom.Greed.Demo.Recorder, DelphiDoom.Greed.Demo.Player, DelphiDoom.Greed.Game.Constants;

const
  ARCHIVE_NAME = 'GREED.BLO';
  FNV_OFFSET = 2166136261;
  FNV_PRIME = 16777619;
  PLANE_NAMES: array[TGreedPlane] of string = ('northwall', 'northflags', 'westwall', 'westflags', 'floorpic',
    'floorflags', 'ceilingpic', 'ceilingflags', 'floorheight', 'ceilingheight', 'floordef', 'floordefflags',
    'ceilingdef', 'ceilingdefflags', 'maplights', 'mapeffects', 'mapsprites', 'mapslopes');

type
  /// <summary>The keys of the generated commands as the commands of the game, and the characters that they type</summary>
  TWorldCommandSource = class(TInterfacedObject, IGreedCommandSource)
  strict private
    FCommands: TWorldCommands;
    FKeys: TWorldKeys;
    FTyped: string;
  public
    constructor Create(ASeed: Cardinal; ARearView: Boolean);
    destructor Destroy; override;
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

  /// <summary>The sounds and the songs go to the fingerprint</summary>
  TWorldSound = class(TInterfacedObject, IGreedSoundEffects, IGreedMusic)
  strict private
    FPrint: TWorldPrint;
  public
    constructor Create(APrint: TWorldPrint);
    procedure Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
    procedure Update;
    procedure StopAll;
    procedure Play(const AFileName: string; APattern: Integer);
    procedure Stop;
  end;

  /// <summary>The saved games stay in memory: each is the record as SaveGame of the original writes it to its file</summary>
  TWorldSaveGames = class(TInterfacedObject, IGreedSaveGames)
  strict private
    FGames: array[0..9] of TGreedPlayerRecord;
    FSaved: array[0..9] of Boolean;
  public
    /// <summary>FNV-1a of the bytes of the saved game ANumber and their number; 0 bytes if it was never saved</summary>
    function Fingerprint(ANumber: Integer; out ALength: Cardinal): Cardinal;
    function GameFileName(ANumber: Integer): string;
    function DirectoryFileName: string;
    procedure SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
    function LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
    function ReadDirectory: TGreedSaveDirectory;
    procedure WriteDirectory(const ADirectory: TGreedSaveDirectory);
  end;

  TWorldClock = class(TInterfacedObject, IGreedSystemClock)
  public
    Value: Cardinal;
    function Clock: Cardinal;
  end;

{ TWorldCommandSource }

constructor TWorldCommandSource.Create(ASeed: Cardinal; ARearView: Boolean);
begin
  inherited Create;
  FCommands := TWorldCommands.Create(ASeed, ARearView);
end;

destructor TWorldCommandSource.Destroy;
begin
  FCommands.Free;
  inherited Destroy;
end;

procedure TWorldCommandSource.BeginReading;
const
  // the keys that type a character, in the order of their scan codes (the last one typed in a reading wins):
  // 1, 2, Z, X, comma, period, space, Delete (which is the character 127 in the table of the original)
  // (A, the rear view, is between 2 and Z)
  TYPING: array[0..8] of TWorldKey = (wkWeapon1, wkWeapon2, wkRearView, wkJump, wkUseItem, wkSlideLeft,
    wkSlideRight, wkSpace, wkInventoryRight);
  TYPED: array[0..8] of Char = ('1', '2', 'A', 'Z', 'X', ',', '.', ' ', #127);
var
  LNew: TWorldKeys;
  LIndex: Integer;
begin
  LNew := FCommands.Next;
  FTyped := '';
  for LIndex := Low(TYPING) to High(TYPING) do
    if (TYPING[LIndex] in LNew) and not (TYPING[LIndex] in FKeys) then
      FTyped := FTyped + TYPED[LIndex];
  FKeys := LNew;
end;

function TWorldCommandSource.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  case ACommand of
    gcNorth: Result := wkNorth in FKeys;
    gcSouth: Result := wkSouth in FKeys;
    gcEast: Result := wkEast in FKeys;
    gcWest: Result := wkWest in FKeys;
    gcFire: Result := wkFire in FKeys;
    gcUse, gcRestart: Result := wkSpace in FKeys;
    gcRun, gcShift: Result := wkShift in FKeys;
    gcSlideLeft: Result := wkSlideLeft in FKeys;
    gcSlideRight: Result := wkSlideRight in FKeys;
    gcJump: Result := wkJump in FKeys;
    gcUseItem: Result := wkUseItem in FKeys;
    gcInventoryLeft: Result := wkInventoryLeft in FKeys;
    gcInventoryRight: Result := wkInventoryRight in FKeys;
    gcLookUp: Result := wkLookUp in FKeys;
    gcLookDown: Result := wkLookDown in FKeys;
    gcCenterView: Result := wkCenterView in FKeys;
    gcWeapon1: Result := wkWeapon1 in FKeys;
    gcWeapon2: Result := wkWeapon2 in FKeys;
    gcRearView: Result := wkRearView in FKeys;
  else
    Result := False;
  end;
end;

function TWorldCommandSource.TakeTyped(out ACharacter: Char): Boolean;
begin
  Result := FTyped <> '';
  if Result then
  begin
    ACharacter := FTyped[1];
    Delete(FTyped, 1, 1);
  end
  else
    ACharacter := #0;
end;

function TWorldCommandSource.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := False;
end;

procedure TWorldCommandSource.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := 0;
  ADeltaY := 0;
end;

{ TWorldSound }

constructor TWorldSound.Create(APrint: TWorldPrint);
begin
  inherited Create;
  FPrint := APrint;
end;

procedure TWorldSound.Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FPrint.Sound(ASoundNumber, AVariation, AX, AY);
end;

procedure TWorldSound.Update;
begin
end;

procedure TWorldSound.StopAll;
begin
end;

procedure TWorldSound.Play(const AFileName: string; APattern: Integer);
begin
  FPrint.Song(AFileName);
end;

procedure TWorldSound.Stop;
begin
  FPrint.Song('');
end;

{ TWorldSaveGames }

function TWorldSaveGames.GameFileName(ANumber: Integer): string;
begin
  Result := '';
end;

function TWorldSaveGames.DirectoryFileName: string;
begin
  Result := '';
end;

procedure TWorldSaveGames.SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
begin
  if (ANumber < Low(FGames)) or (ANumber > High(FGames)) then
    Exit;
  FGames[ANumber] := APlayer;
  FSaved[ANumber] := True;
end;

function TWorldSaveGames.Fingerprint(ANumber: Integer; out ALength: Cardinal): Cardinal;
var
  LBytes: PByte;
  LIndex: Integer;
begin
  Result := FNV_OFFSET;
  ALength := 0;
  if (ANumber < Low(FGames)) or (ANumber > High(FGames)) or not FSaved[ANumber] then
    Exit;
  ALength := SizeOf(TGreedPlayerRecord);
  LBytes := PByte(@FGames[ANumber]);
  for LIndex := 0 to SizeOf(TGreedPlayerRecord) - 1 do
    Result := (Result xor LBytes[LIndex]) * FNV_PRIME;
end;

function TWorldSaveGames.LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
begin
  Result := (ANumber >= Low(FGames)) and (ANumber <= High(FGames)) and FSaved[ANumber];
  if Result then
    APlayer := FGames[ANumber]
  else
    FillChar(APlayer, SizeOf(APlayer), 0);
end;

function TWorldSaveGames.ReadDirectory: TGreedSaveDirectory;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

procedure TWorldSaveGames.WriteDirectory(const ADirectory: TGreedSaveDirectory);
begin
end;

{ TWorldClock }

function TWorldClock.Clock: Cardinal;
begin
  Result := Value;
end;

{ TLibraryWorldRunner }

constructor TLibraryWorldRunner.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := AFolder;
  FDumpFrame := -1;
  FArchive := TGreedFactory.OpenArchiveFile(TPath.Combine(AFolder, ARCHIVE_NAME));
end;

procedure TLibraryWorldRunner.PrintWorld(AGame: TGreedGame; ARandom: TGreedRandomTable; APrint: TWorldPrint);
var
  S: TGreedGameState;
  LIndex, LCount: Integer;
  LPlane: TGreedPlane;
  LBytes: array[0..GREED_MAP_TILES - 1] of Byte;
  LEvents: TWorldEvents;
  LGlobals: TWorldGlobals;
begin
  S := AGame.State;
  APrint.StartFrame;
  APrint.Player(S.Player);

  APrint.Select(wsSprites);
  LCount := 0;
  LIndex := S.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    APrint.Sprite(LCount, PGreedSprite(S.Sprites.Item(LIndex))^);
    Inc(LCount);
    LIndex := S.Sprites.Next(LIndex);
  end;
  APrint.Select(wsSprites);
  APrint.Int('count', LCount);

  APrint.Select(wsElevators);
  LCount := 0;
  LIndex := S.Elevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    APrint.Elevator(LCount, S.Elevators.Item(LIndex)^);
    Inc(LCount);
    LIndex := S.Elevators.Next(LIndex);
  end;
  APrint.Select(wsElevators);
  APrint.Int('count', LCount);

  APrint.Select(wsDoors);
  APrint.Int('count', AGame.World.DoorCount);
  for LIndex := 0 to AGame.World.DoorCount - 1 do
    APrint.Door(LIndex, AGame.World.GetDoor(LIndex));

  APrint.Select(wsAreas);
  APrint.Int('count', AGame.World.SpawnAreaCount);
  for LIndex := 0 to AGame.World.SpawnAreaCount - 1 do
    APrint.Area(LIndex, AGame.World.GetSpawnArea(LIndex));

  APrint.Select(wsPlanes);
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
  begin
    // mapslopes is not in the fingerprint: it is read only when the map is loaded (it becomes mapflags, which is
    // here), and the original writes in it when a sprite is put past the end of mapsprites (the map 10)
    if LPlane = gpMapSlopes then
      Continue;
    AGame.World.CopyPlane(LPlane, @LBytes[0]);
    APrint.Block(PLANE_NAMES[LPlane], @LBytes[0], SizeOf(LBytes));
  end;
  AGame.World.CopyMapFlags(@LBytes[0]);
  // the last 320 bytes are not printed (see the harness: the original writes there with reallight[-n])
  APrint.Block('mapflags', @LBytes[0], SizeOf(LBytes) - 320);

  FillChar(LEvents, SizeOf(LEvents), 0);
  LEvents.Triggers := S.Triggers;
  LEvents.Switches := S.Switches;
  Move(S.Processes, LEvents.Processes, SizeOf(LEvents.Processes));
  LEvents.NumProcesses := S.NumProcesses;
  LEvents.NumZones := S.NumZones;
  LEvents.FliPlayed := S.FliPlayed;
  for LIndex := Low(S.Zones) to High(S.Zones) do
    LEvents.Zones[LIndex] := S.Zones[LIndex];
  for LIndex := 0 to 3 do
    LEvents.Primaries[LIndex] := S.Primaries[LIndex];
  for LIndex := 0 to 13 do
    LEvents.Secondaries[LIndex] := S.Secondaries[LIndex];
  for LIndex := 0 to 1 do
    LEvents.PCount[LIndex] := S.PCount[LIndex];
  for LIndex := 0 to 6 do
    LEvents.SCount[LIndex] := S.SCount[LIndex];
  LEvents.BonusTime := S.BonusTime;
  LEvents.LevelScore := S.LevelScore;
  APrint.Events(LEvents);

  FillChar(LGlobals, SizeOf(LGlobals), 0);
  LGlobals.RandomOffset := ARandom.Offset;
  LGlobals.TimeCount := S.TimeCount;
  LGlobals.Frames := S.Frames;
  LGlobals.WeapDelay := S.WeapDelay;
  LGlobals.SpriteMoveTime := S.SpriteMoveTime;
  LGlobals.SecretDelay := S.SecretDelay;
  LGlobals.InventoryDelay := S.InventoryDelay;
  LGlobals.UseDelay := S.UseDelay;
  LGlobals.JumpDelay := S.JumpDelay;
  LGlobals.KeyboardDelay := S.KeyboardDelay;
  LGlobals.RearViewTime := S.RearViewTime;
  LGlobals.RearViewDelay := S.RearViewDelay;
  LGlobals.InventoryTime := S.InventoryTime;
  LGlobals.ChangingWeapons := S.ChangingWeapons;
  LGlobals.WeaponLowering := S.WeaponLowering;
  LGlobals.QuitGame := S.QuitGame;
  LGlobals.HeatMode := S.HeatMode;
  LGlobals.GodMode := S.GodMode;
  LGlobals.MotionMode := S.MotionMode;
  LGlobals.HurtBorder := S.HurtBorder;
  LGlobals.DoorSound := S.DoorSound;
  LGlobals.DeadRestart := S.DeadRestart;
  LGlobals.ExitLevel := S.ExitLevel;
  LGlobals.ExitExists := S.ExitExists;
  LGlobals.WarpJammer := S.WarpJammer;
  LGlobals.AutoRun := S.AutoRun;
  LGlobals.RearViewOn := S.RearViewOn;
  LGlobals.CheckTrigger := S.CheckTrigger;
  LGlobals.UseItem := S.UseItem;
  LGlobals.GoIRight := S.GoIRight;
  LGlobals.GoILeft := S.GoILeft;
  LGlobals.MidgetMode := S.MidgetMode;
  LGlobals.AutoTarget := S.AutoTarget;
  LGlobals.ToggleGoalItem := S.ToggleGoalItem;
  LGlobals.WeapMode := S.WeapMode;
  LGlobals.NewWeapon := S.NewWeapon;
  LGlobals.WeaponYChange := S.WeaponYChange;
  LGlobals.HeadBob := S.HeadBob;
  LGlobals.WeapBob := S.WeapBob;
  LGlobals.ChangeLight := S.ChangeLight;
  LGlobals.Lighting := S.Lighting;
  LGlobals.TurnRate := S.TurnRate;
  LGlobals.MapMode := S.MapMode;
  LGlobals.ScrollView := S.ScrollView;
  LGlobals.DoorX := S.DoorX;
  LGlobals.DoorY := S.DoorY;
  LGlobals.Warping := S.Warping;
  LGlobals.GoalItem := S.GoalItem;
  LGlobals.SpecialEffect := S.SpecialEffect;
  LGlobals.FallDamage := S.FallDamage;
  LGlobals.WallAnimCount := S.WallAnimCount;
  LGlobals.SongNum := S.SongNum;
  LGlobals.MoveRate := S.MoveRate;
  LGlobals.StrafRate := S.StrafRate;
  LGlobals.FallRate := S.FallRate;
  LGlobals.WarpX := S.WarpX;
  LGlobals.WarpY := S.WarpY;
  LGlobals.WallAnimationTime := S.WallAnimationTime;
  LGlobals.SpecialEffectTime := S.SpecialEffectTime;
  LGlobals.SwitchTime := S.SwitchTime;
  LGlobals.PlayerAngle64 := S.PlayerAngle64;
  LGlobals.BonusTime := S.BonusItem.Time;
  LGlobals.BonusScore := S.BonusItem.Score;
  LGlobals.BonusTileX := S.BonusItem.TileX;
  LGlobals.BonusTileY := S.BonusItem.TileY;
  LGlobals.BonusMapSpot := S.BonusItem.MapSpot;
  LGlobals.BonusNum := S.BonusItem.Num;
  LGlobals.BonusSprite := -1;
  LCount := 0;
  LIndex := S.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    if LIndex = S.BonusItem.Sprite then
      LGlobals.BonusSprite := LCount;
    Inc(LCount);
    LIndex := S.Sprites.Next(LIndex);
  end;
  LGlobals.InventoryCursor := AGame.Inventory.Cursor;
  LGlobals.FireGrenade := AGame.Inventory.FireGrenade;
  LGlobals.FirePending := AGame.Parts.Control.FirePending;
  LGlobals.WarpActive := AGame.Parts.Items.WarpActive;
  LGlobals.BloodCount := AGame.Parts.Spawner.BloodCount;
  LGlobals.MetalCount := AGame.Parts.Spawner.MetalCount;
  LGlobals.MouseDX := AGame.Parts.Control.MouseDX;
  LGlobals.MouseDY := AGame.Parts.Control.MouseDY;
  for LIndex := Low(S.Weapons) to High(S.Weapons) do
  begin
    LGlobals.WeaponCharge[LIndex] := S.Weapons[LIndex].Charge;
    LGlobals.WeaponChargeTime[LIndex] := S.Weapons[LIndex].ChargeTime;
  end;
  APrint.Globals(LGlobals);
end;

procedure TLibraryWorldRunner.Play(AMap, ASeed, AFrames, AEvery: Integer; ALines: TStrings);
var
  LPrint: TWorldPrint;
  LGame: TGreedGame;
  LRandom: TGreedRandomTable;
  LRandomIntf: IGreedRandom;
  LClock: TWorldClock;
  LClockIntf: IGreedSystemClock;
  LSound: TWorldSound;
  LSoundIntf: IGreedSoundEffects;
  LView: TGreedHudView;
  LViewIntf: IGreedGameView;
  LFrame: TGreedFrame;
  LFrameNumber, LTic, LTotalTics, LEpisode, LShift: Integer;
  LHistory, LTotal, LClockBase, LRear: Cardinal;
  LValues: TStringList;
  LSource: IGreedCommandSource;
  LPacer: IGreedFramePacer;
  LGameClock: IGreedSystemClock;
  LHeader: TGreedDemoHeader;
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
  LRecorder: TGreedDemoRecorder;
  LPlayer: TGreedDemoPlayer;
  LTicsOfTurn: Integer;
  LSaves: TWorldSaveGames;
  LSavesIntf: IGreedSaveGames;
  LSaveLength, LSavePrint: Cardinal;

  procedure AddToHistory(AValue: Cardinal);
  var
    LBits: Integer;
  begin
    LBits := 0;
    while LBits < 32 do
    begin
      LHistory := (LHistory xor ((AValue shr LBits) and $FF)) * FNV_PRIME;
      Inc(LBits, 8);
    end;
  end;

  // what RunMenu of raven.pas does around the menu, with the menu saving the game and loading it at once
  procedure SaveAndLoad;
  begin
    LGame.State.Player.TimeCount := LGame.State.TimeCount;
    LGame.SaveGame(1);
    LSavePrint := LSaves.Fingerprint(1, LSaveLength);
    AddToHistory(LSaveLength);
    AddToHistory(LSavePrint);
    LGame.LoadGame(1);
    LGame.State.TimeCount := LGame.State.Player.TimeCount;
    LGame.State.KeyboardDelay := LGame.State.TimeCount + GREED_KBDELAY;
  end;

  // FNV-1a of rearbuf (64 x 64 pixels, all zero before the first picture of the camera, as the array of the original)
  function RearPrint(const ABuffer: TBytes): Cardinal;
  var
    LIndex: Integer;
    LByte: Byte;
  begin
    Result := FNV_OFFSET;
    for LIndex := 0 to 64 * 64 - 1 do
    begin
      if LIndex < Length(ABuffer) then
        LByte := ABuffer[LIndex]
      else
        LByte := 0;
      Result := (Result xor LByte) * FNV_PRIME;
    end;
  end;

  // the rows of rearbuf as hexadecimal text, as the harness of the original writes them with -Valori
  procedure DumpRear(const ABuffer: TBytes; ALines: TStrings);
  var
    LRow, LColumn, LIndex: Integer;
    LText: string;
  begin
    for LRow := 0 to 63 do
    begin
      LText := '';
      for LColumn := 0 to 63 do
      begin
        LIndex := LRow * 64 + LColumn;
        if LIndex < Length(ABuffer) then
          LText := LText + IntToHex(ABuffer[LIndex], 2)
        else
          LText := LText + '00';
      end;
      ALines.Add(Format('rear.%d=%s', [LRow, LText]));
    end;
  end;

  // per-tic trace of the fields of the weapon (GREED_TRACE = "<first turn>-<last turn>", GREED_TRACE_FILE): the
  // same lines of the harness of the original, to find the first value that differs
  procedure Trace(const AWhere: string);
  var
    LText, LFile: string;
    LFirst, LLast, LWeapon: Integer;
    LLines: TStringList;
    LState: TGreedGameState;
  begin
    LText := GetEnvironmentVariable('GREED_TRACE');
    LFile := GetEnvironmentVariable('GREED_TRACE_FILE');
    if (LText = '') or (LFile = '') then
      Exit;
    LFirst := StrToInt(Copy(LText, 1, Pos('-', LText) - 1));
    LLast := StrToInt(Copy(LText, Pos('-', LText) + 1, 20));
    if (LFrameNumber < LFirst) or (LFrameNumber > LLast) then
      Exit;
    LState := LGame.State;
    LWeapon := LState.Player.Weapons[LState.Player.CurrentWeapon];
    LLines := TStringList.Create;
    try
      if FileExists(LFile) then
        LLines.LoadFromFile(LFile);
      LLines.Add(Format('%s w=%d charge=%d/%d mode=%d delay=%d action=%d ammo1=%d cur=%d chg=%d status=%d',
        [AWhere, LWeapon, LState.Weapons[LWeapon].Charge, LState.Weapons[LWeapon].ChargeTime, LState.WeapMode,
        LState.WeapDelay, Ord(LGame.Parts.Control.FirePending), LState.Player.Ammo[1], LState.Player.CurrentWeapon,
        Ord(LState.ChangingWeapons), LState.Player.Status]));
      LLines.SaveToFile(LFile);
    finally
      LLines.Free;
    end;
  end;

  procedure Note;
  begin
    Trace(Format('E %d end tc %d', [LFrameNumber, LGame.State.TimeCount]));
    if LFrameNumber = FDumpFrame then
    begin
      LValues := TStringList.Create;
      try
        LPrint.Lines := LValues;
        PrintWorld(LGame, LRandom, LPrint);
        LPrint.Lines := nil;
        if FRearView then
          DumpRear(LGame.RearBuffer, LValues);
        LValues.SaveToFile(FDumpFile);
      finally
        LValues.Free;
      end;
    end
    else
      PrintWorld(LGame, LRandom, LPrint);
    LTotal := LPrint.Total;
    LShift := 0;
    while LShift < 32 do
    begin
      LHistory := (LHistory xor ((LTotal shr LShift) and $FF)) * FNV_PRIME;
      Inc(LShift, 8);
    end;
    if FRearView then
    begin
      LRear := RearPrint(LGame.RearBuffer);
      LShift := 0;
      while LShift < 32 do
      begin
        LHistory := (LHistory xor ((LRear shr LShift) and $FF)) * FNV_PRIME;
        Inc(LShift, 8);
      end;
    end;
    if FAllFrames or (LFrameNumber mod AEvery = 0) or (LFrameNumber = AFrames) or LGame.QuitGame then
    begin
      if FRearView then
        ALines.Add(Format('W %d %d %d %d %s %s %s', [AMap, ASeed, LFrameNumber, LGame.State.TimeCount,
          IntToHex(LHistory, 8), LPrint.Line, IntToHex(LRear, 8)]))
      else
        ALines.Add(Format('W %d %d %d %d %s %s', [AMap, ASeed, LFrameNumber, LGame.State.TimeCount,
          IntToHex(LHistory, 8), LPrint.Line]));
    end;
  end;

begin
  LPrint := TWorldPrint.Create;
  LGame := nil;
  LWriter := nil;
  LReader := nil;
  LRecorder := nil;
  LPlayer := nil;
  FTapeOutOfStep := False;
  try
    LRandom := TGreedRandomTable.Create;
    LRandomIntf := LRandom;
    LClock := TWorldClock.Create;
    LClockIntf := LClock;
    LSound := TWorldSound.Create(LPrint);
    LSoundIntf := LSound;
    // the status bar of the original changes the game too (the goal item that it shows moves on when the bonus
    // item goes away): the game is played with the HUD of the program, drawn at every turn
    LView := TGreedHudView.Create(FArchive);
    LViewIntf := LView;
    LSaves := TWorldSaveGames.Create;
    LSavesIntf := LSaves;
    LSource := TWorldCommandSource.Create(Cardinal(ASeed), FRearView);
    LPacer := nil;
    LGameClock := LClockIntf;
    if Length(FPlayFrom) > 0 then
    begin
      // the tape instead of the commands of the seed and of the clock
      LReader := TGreedDemoReader.Create(FPlayFrom);
      LPlayer := TGreedDemoPlayer.Create(LReader, False);
      LSource := LPlayer;
      LGameClock := LPlayer;
      LPacer := LPlayer;
    end
    else if Assigned(FRecordTo) then
    begin
      LHeader := Default(TGreedDemoHeader);
      LHeader.Map := AMap;
      LHeader.Difficulty := 2;
      LHeader.LowResolution := True;
      LHeader.RandomOffset := ASeed;
      LWriter := TGreedDemoWriter.Create(FRecordTo, LHeader);
      LRecorder := TGreedDemoRecorder.Create(LWriter, LSource, LClockIntf);
      LSource := LRecorder;
      LGameClock := LRecorder;
      LPacer := LRecorder;
    end;
    LGame := TGreedGame.Create(FArchive,
      TGreedFactory.CreateMapLoader(FArchive, TGreedFactory.CreateFolderFiles([FFolder])),
      TGreedGameRendererFactory.Create(FArchive),
      TGreedCommandState.Create(LSource), LSoundIntf, LSound as IGreedMusic,
      LRandomIntf, LSavesIntf, LGameClock, LViewIntf, LView as IGreedMessages);
    LView.Attach(LGame);
    LGame.LowResolution := True;
    if AMap >= 16 then
      LEpisode := 3
    else if AMap >= 8 then
      LEpisode := 2
    else
      LEpisode := 1;
    LGame.SetEdition(False, LEpisode);
    LClockBase := Cardinal(ASeed) * WORLD_CLOCK_PER_SEED;
    LClock.Value := LClockBase;
    LRandom.Offset := ASeed;
    LFrame := TGreedFrame.Make(GREED_GAME_VIEW_WIDTH, GREED_GAME_VIEW_HEIGHT);
    LGame.NewGame(AMap, 0, 2);
    LHistory := FNV_OFFSET;
    LTotalTics := 0;
    LFrameNumber := 0;
    Note;
    while (LFrameNumber < AFrames) and not LGame.QuitGame do
    begin
      Inc(LFrameNumber);
      LTicsOfTurn := WORLD_TICS_PER_FRAME;
      if Assigned(LPacer) then
        LPacer.NextFrame(LTicsOfTurn);
      for LTic := 1 to LTicsOfTurn do
      begin
        Inc(LTotalTics);
        LClock.Value := LClockBase + Cardinal(LTotalTics) * WORLD_CLOCK_PER_TIC;
        LGame.Tic;
        Trace(Format('T %d tic %d tc %d', [LFrameNumber, LTic, LGame.State.TimeCount]));
      end;
      LGame.Frame(LFrame);
      if (FSaveTurns <> '') and (Pos(',' + IntToStr(LFrameNumber) + ',', ',' + FSaveTurns + ',') > 0) and
        not LGame.QuitGame then
        SaveAndLoad;
      Note;
    end;
    if Assigned(LRecorder) then
      LRecorder.Close;
    if Assigned(LPlayer) then
      FTapeOutOfStep := LPlayer.Desynchronized;
  finally
    LGame.Free;
    LPacer := nil;
    LSource := nil;
    LGameClock := nil;
    LWriter.Free;
    LReader.Free;
    LPrint.Free;
  end;
end;

end.
