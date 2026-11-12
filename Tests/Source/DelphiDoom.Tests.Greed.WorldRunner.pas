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
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.GameRendererFactory;

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
    constructor Create(ASeed: Cardinal);
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

  TWorldSaveGames = class(TInterfacedObject, IGreedSaveGames)
  public
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

  /// <summary>Nothing is drawn around the view and nothing is shown between the maps</summary>
  TWorldView = class(TInterfacedObject, IGreedGameView, IGreedMessages)
  public
    procedure RefreshInventory;
    procedure RefreshAmmo;
    procedure RefreshGoalItem;
    procedure ResetDisplay;
    procedure SetTotalEffectTime(ATics: Integer);
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    procedure PlayFli(AMovie: Integer);
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    procedure FadeOutLevel;
    procedure ChangeViewSize(ABigger: Boolean);
    procedure SetGameEpisode(AEpisode: Integer);
    function ShowMenu: Boolean;
    procedure ShowHelp;
    procedure ShowPause;
    function ConfirmQuit: Boolean;
    procedure DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
    procedure WriteMessage(const AText: string);
  end;

{ TWorldCommandSource }

constructor TWorldCommandSource.Create(ASeed: Cardinal);
begin
  inherited Create;
  FCommands := TWorldCommands.Create(ASeed);
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
  TYPING: array[0..7] of TWorldKey = (wkWeapon1, wkWeapon2, wkJump, wkUseItem, wkSlideLeft, wkSlideRight, wkSpace,
    wkInventoryRight);
  TYPED: array[0..7] of Char = ('1', '2', 'Z', 'X', ',', '.', ' ', #127);
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
end;

function TWorldSaveGames.LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
begin
  FillChar(APlayer, SizeOf(APlayer), 0);
  Result := False;
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

{ TWorldView }

procedure TWorldView.RefreshInventory;
begin
end;

procedure TWorldView.RefreshAmmo;
begin
end;

procedure TWorldView.RefreshGoalItem;
begin
end;

procedure TWorldView.ResetDisplay;
begin
end;

procedure TWorldView.SetTotalEffectTime(ATics: Integer);
begin
end;

procedure TWorldView.MissionBriefing(AMap: Integer);
begin
end;

procedure TWorldView.EndGame(AEpisode: Integer);
begin
end;

procedure TWorldView.PlayFli(AMovie: Integer);
begin
end;

procedure TWorldView.StartWait;
begin
end;

procedure TWorldView.UpdateWait;
begin
end;

procedure TWorldView.EndWait;
begin
end;

procedure TWorldView.FadeOutLevel;
begin
end;

procedure TWorldView.ChangeViewSize(ABigger: Boolean);
begin
end;

procedure TWorldView.SetGameEpisode(AEpisode: Integer);
begin
end;

function TWorldView.ShowMenu: Boolean;
begin
  Result := False;
end;

procedure TWorldView.ShowHelp;
begin
end;

procedure TWorldView.ShowPause;
begin
end;

function TWorldView.ConfirmQuit: Boolean;
begin
  Result := False;
end;

procedure TWorldView.DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
begin
end;

procedure TWorldView.WriteMessage(const AText: string);
begin
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
  LView: TWorldView;
  LViewIntf: IGreedGameView;
  LFrame: TGreedFrame;
  LFrameNumber, LTic, LTotalTics, LEpisode, LShift: Integer;
  LHistory, LTotal, LClockBase: Cardinal;
  LValues: TStringList;

  procedure Note;
  begin
    if LFrameNumber = FDumpFrame then
    begin
      LValues := TStringList.Create;
      try
        LPrint.Lines := LValues;
        PrintWorld(LGame, LRandom, LPrint);
        LPrint.Lines := nil;
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
    if FAllFrames or (LFrameNumber mod AEvery = 0) or (LFrameNumber = AFrames) or LGame.QuitGame then
      ALines.Add(Format('W %d %d %d %d %s %s', [AMap, ASeed, LFrameNumber, LGame.State.TimeCount,
        IntToHex(LHistory, 8), LPrint.Line]));
  end;

begin
  LPrint := TWorldPrint.Create;
  LGame := nil;
  try
    LRandom := TGreedRandomTable.Create;
    LRandomIntf := LRandom;
    LClock := TWorldClock.Create;
    LClockIntf := LClock;
    LSound := TWorldSound.Create(LPrint);
    LSoundIntf := LSound;
    LView := TWorldView.Create;
    LViewIntf := LView;
    LGame := TGreedGame.Create(FArchive,
      TGreedFactory.CreateMapLoader(FArchive, TGreedFactory.CreateFolderFiles([FFolder])),
      TGreedGameRendererFactory.Create(FArchive),
      TGreedCommandState.Create(TWorldCommandSource.Create(Cardinal(ASeed))), LSoundIntf, LSound as IGreedMusic,
      LRandomIntf, TWorldSaveGames.Create, LClockIntf, LViewIntf, LView as IGreedMessages);
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
      for LTic := 1 to WORLD_TICS_PER_FRAME do
      begin
        Inc(LTotalTics);
        LClock.Value := LClockBase + Cardinal(LTotalTics) * WORLD_CLOCK_PER_TIC;
        LGame.Tic;
      end;
      LGame.Frame(LFrame);
      Note;
    end;
  finally
    LGame.Free;
    LPrint.Free;
  end;
end;

end.
