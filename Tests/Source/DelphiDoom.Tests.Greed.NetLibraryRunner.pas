{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: the scenarios of the net game on          }
{  TGreedNetSession                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.NetLibraryRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Net.Intf, DelphiDoom.Greed.Net.Session,
  DelphiDoom.Tests.Greed.NetScenarios, DelphiDoom.Tests.Greed.NetRunner, DelphiDoom.Tests.Greed.NetFakes;

type
  /// <summary>
  ///   The scenarios on the library: a TGreedNetSession over a net in memory of two computers (the other one is
  ///   the scenario), a real state, world and list of sprites, and a fake game that writes down what the session
  ///   asks of it and makes a sprite for each SpawnSprite, as the stubs of the harness of the original do
  /// </summary>
  TLibraryNetRunner = class(TNetScenarioRunner)
  strict private
    FNet: TFakeGreedNet;
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FGame: IInterface;
    FSession: TGreedNetSession;
    FLink: IGreedNetLink;
    FRandomCalls: Integer;
    FGoalRefreshed: Integer;
    FGoalFlag: Boolean;
  protected
    procedure Open(const AScenario: TNetScenario); override;
    procedure Close; override;
    procedure SetClock(AValue: Integer); override;
    procedure SetPlayer(const AValues: array of Integer); override;
    procedure QueueIncoming(const ABytes: TBytes); override;
    procedure SetMapSprite(ASpot, AValue: Integer); override;
    procedure SetBonus(const AValues: array of Integer); override;
    procedure AddSprite(AKind, AX, AY: Integer); override;
    procedure Call(const AOp: TNetOp); override;
    function RunWait: Boolean; override;
    function TakeSent: TArray<TBytes>; override;
    procedure GetState(out AState: TNetStateDump); override;
  public
    function NextRandom: Byte;
    procedure GoalRefreshed;
    property State: TGreedGameState read FState;
  end;

implementation

uses
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.World, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Net.Types;

type
  /// <summary>The rest of the game, as the session sees it</summary>
  TRunnerGame = class(TInterfacedObject, IGreedArchive, IGreedSpawner, IGreedGameSound, IGreedMessages,
    IGreedPlayerHealth, IGreedRandom, IGreedEventRunner, IGreedNetHost)
  strict private
    FRunner: TLibraryNetRunner;
  public
    constructor Create(ARunner: TLibraryNetRunner);
    // IGreedArchive
    function GetLumpCount: Integer;
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpSize(AIndex: Integer): Integer;
    function IndexOf(const AName: string): Integer;
    function RequireIndexOf(const AName: string): Integer;
    function ReadLump(AIndex: Integer): TBytes;
    function ReadLumpRaw(AIndex: Integer): TBytes;
    // IGreedSpawner
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    // IGreedGameSound
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    // IGreedMessages
    procedure WriteMessage(const AText: string);
    // IGreedPlayerHealth
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
    // IGreedRandom
    function Next: Byte;
    // IGreedEventRunner
    procedure RunEvent(AEvent: Integer; ANetSend: Boolean);
    // IGreedNetHost
    procedure TryDoor(ACenterX, ACenterY: TGreedFixed);
    procedure CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
    procedure RefreshGoalItem;
  end;

{ TRunnerGame }

constructor TRunnerGame.Create(ARunner: TLibraryNetRunner);
begin
  inherited Create;
  FRunner := ARunner;
end;

function TRunnerGame.GetLumpCount: Integer;
begin
  Result := 0;
end;

function TRunnerGame.GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
begin
  Result := Default(TGreedLumpInfo);
end;

function TRunnerGame.GetLumpName(AIndex: Integer): string;
begin
  Result := '';
end;

function TRunnerGame.GetLumpSize(AIndex: Integer): Integer;
begin
  Result := 0;
end;

function TRunnerGame.IndexOf(const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := Low(TGreedGameTables.CharacterNames) to High(TGreedGameTables.CharacterNames) do
    if SameText(TGreedGameTables.CharacterNames[LIndex], AName) then
      Exit(TNetScenarios.CharacterLump(LIndex));
end;

function TRunnerGame.RequireIndexOf(const AName: string): Integer;
begin
  Result := IndexOf(AName);
  if Result < 0 then
    raise EGreedNotFoundException.Create(AName);
end;

function TRunnerGame.ReadLump(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TRunnerGame.ReadLumpRaw(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TRunnerGame.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
var
  LSprite: PGreedSprite;
begin
  FRunner.NoteSpawn(AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2, AActive, ASpawnId, FRunner.State.GameLoading);
  Result := FRunner.State.Sprites.Add;
  LSprite := PGreedSprite(FRunner.State.Sprites.Item(Result));
  LSprite^.Kind := AValue;
  LSprite^.X := AX;
  LSprite^.Y := AY;
  LSprite^.BasePic := NET_SPAWN_PICTURE_BASE + AValue;
end;

procedure TRunnerGame.DemandLoadMonster(ALump, ACount: Integer);
begin
  FRunner.NoteDemandLoad(ALump, ACount);
end;

procedure TRunnerGame.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FRunner.NoteSound(ASound, AVariation, AX, AY);
end;

procedure TRunnerGame.WriteMessage(const AText: string);
begin
  FRunner.NoteMessage(AText);
end;

procedure TRunnerGame.Hurt(AAmount: Integer);
begin
end;

procedure TRunnerGame.Heal(AAmount: Integer);
begin
end;

procedure TRunnerGame.MedPaks(AAmount: Integer);
begin
end;

procedure TRunnerGame.AddScore(AAmount: Integer);
begin
  FRunner.NoteAddScore(AAmount);
end;

function TRunnerGame.Next: Byte;
begin
  Result := FRunner.NextRandom;
end;

procedure TRunnerGame.RunEvent(AEvent: Integer; ANetSend: Boolean);
begin
  FRunner.NoteEvent(AEvent, ANetSend);
end;

procedure TRunnerGame.TryDoor(ACenterX, ACenterY: TGreedFixed);
begin
  FRunner.NoteTryDoor(ACenterX, ACenterY);
end;

procedure TRunnerGame.CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
var
  LSpot: Integer;
begin
  LSpot := (ATileY * GREED_MAP_SIZE + ATileX) and (GREED_MAP_TILES - 1);
  FRunner.NoteCheckItems(ATileX, ATileY, AUseIt, ACharType, FRunner.State.World.GetValue(gpMapSprites, LSpot));
end;

procedure TRunnerGame.CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
begin
  FRunner.NoteCheckHere(AUseIt, ACenterX, ACenterY, AAngle);
end;

procedure TRunnerGame.RefreshGoalItem;
begin
  FRunner.GoalRefreshed;
end;

{ TLibraryNetRunner }

procedure TLibraryNetRunner.Open(const AScenario: TNetScenario);
var
  LGame: TRunnerGame;
  LConfig: TGreedNetConfig;
begin
  FRandomCalls := 0;
  FGoalRefreshed := 0;
  FGoalFlag := False;
  FNet := TFakeGreedNet.Create(2);
  FWorld := TGreedWorld.Create;
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FState.Player.Map := AScenario.Map;
  FState.Player.Difficulty := AScenario.Difficulty;
  FState.BonusItem.Sprite := GREED_POOL_NIL;
  LGame := TRunnerGame.Create(Self);
  FGame := LGame as IGreedArchive;
  LConfig := TGreedNetConfig.Make(AScenario.ConsolePlayer, AScenario.NumPlayers, AScenario.NetName);
  LConfig.NetType := AScenario.NetType;
  FSession := TGreedNetSession.Create(FState, FNet.Endpoint(0), LConfig, LGame, LGame, LGame, LGame, LGame, LGame,
    LGame, LGame);
  FLink := FSession;
end;

procedure TLibraryNetRunner.Close;
begin
  FLink := nil;
  FSession := nil;
  FGame := nil;
  FreeAndNil(FState);
  FreeAndNil(FSprites);
  FreeAndNil(FElevators);
  FWorld := nil;
  FreeAndNil(FNet);
end;

function TLibraryNetRunner.NextRandom: Byte;
begin
  Result := Byte(TNetScenarios.RandomByte(FRandomCalls));
  Inc(FRandomCalls);
end;

procedure TLibraryNetRunner.GoalRefreshed;
begin
  FGoalFlag := True;
end;

procedure TLibraryNetRunner.SetClock(AValue: Integer);
begin
  FState.TimeCount := AValue;
end;

procedure TLibraryNetRunner.SetPlayer(const AValues: array of Integer);
begin
  FState.Player.X := AValues[0];
  FState.Player.Y := AValues[1];
  FState.Player.Z := AValues[2];
  FState.Player.Angle := AValues[3];
  FState.Player.Angst := AValues[4];
  FState.Player.Height := AValues[5];
  FState.Player.CharType := AValues[6];
  FState.Player.Status := AValues[7];
  FState.Player.HoloPic := AValues[8];
  FState.Player.HoloScale := AValues[9];
  FState.SpecialEffect := AValues[10];
end;

procedure TLibraryNetRunner.QueueIncoming(const ABytes: TBytes);
begin
  FNet.Inject(1, 0, ABytes);
end;

procedure TLibraryNetRunner.SetMapSprite(ASpot, AValue: Integer);
begin
  FWorld.SetValue(gpMapSprites, ASpot, Byte(AValue));
end;

procedure TLibraryNetRunner.SetBonus(const AValues: array of Integer);
begin
  FState.BonusItem.Time := AValues[0];
  FState.BonusItem.Score := AValues[1];
  FState.BonusItem.TileX := AValues[2];
  FState.BonusItem.TileY := AValues[3];
  FState.BonusItem.Num := AValues[4];
end;

procedure TLibraryNetRunner.AddSprite(AKind, AX, AY: Integer);
var
  LSprite: PGreedSprite;
begin
  LSprite := PGreedSprite(FSprites.Item(FSprites.Add));
  LSprite^.Kind := AKind;
  LSprite^.X := AX;
  LSprite^.Y := AY;
end;

procedure TLibraryNetRunner.Call(const AOp: TNetOp);
begin
  case AOp.Kind of
    noGetData:
      FLink.GetData;
    noSendPlayer:
      FLink.SendPlayerData;
    noNewPlayer:
      FLink.NewPlayerData;
    noSendSpawn:
      FLink.SendSpawn(AOp.A[0], AOp.A[1], AOp.A[2], AOp.A[3], AOp.A[4], AOp.A[5], AOp.A[6], AOp.A[7] <> 0, AOp.A[8]);
    noSound:
      FLink.SoundEffect(AOp.A[0], AOp.A[1], AOp.A[2], AOp.A[3]);
    noItemPickup:
      FLink.ItemPickup(AOp.A[0], AOp.A[1]);
    noDeath:
      FLink.Death(AOp.A[0]);
    noClosest:
      FLink.GetClosestPlayer(AOp.A[0], AOp.A[1]);
    noOpenDoor:
      FLink.OpenDoor(AOp.A[0], AOp.A[1]);
    noCheckHere:
      FLink.CheckHere(AOp.A[0], AOp.A[1], AOp.A[2]);
    noBonus:
      FLink.BonusItem;
    noPause:
      FLink.Pause;
    noUnPause:
      FLink.UnPause;
    noMessage:
      FLink.SendMessage(AOp.Text);
    noQuit:
      FLink.QuitGame;
    noWarpJam:
      FSession.WarpJam;
    noEvent:
      FSession.Event(AOp.A[0]);
  end;
end;

function TLibraryNetRunner.RunWait: Boolean;
var
  LTurn: Integer;
begin
  Result := False;
  FState.TimeCount := 0;
  FSession.BeginWaitStart;
  LTurn := 0;
  while WaitTurnBegin(LTurn) do
  begin
    if FSession.WaitStartStep then
      Exit(True);
    Inc(LTurn);
  end;
end;

function TLibraryNetRunner.TakeSent: TArray<TBytes>;
begin
  Result := FNet.TakeSent(0);
end;

procedure TLibraryNetRunner.GetState(out AState: TNetStateDump);
var
  LPlayer, LIndex, LSprite, LCount: Integer;
  LData: TGreedPlayerEvent;
  LItem: PGreedSprite;
begin
  AState := Default(TNetStateDump);
  AState.TimeCount := FState.TimeCount;
  AState.PlayerStatus := FState.Player.Status;
  AState.PlayerDifficulty := FState.Player.Difficulty;
  AState.GoalItem := FState.GoalItem;
  AState.GameLoading := Ord(FState.GameLoading);
  AState.TargX := FState.TargX;
  AState.TargY := FState.TargY;
  AState.TargZ := FState.TargZ;
  AState.BonusTime := FState.BonusItem.Time;
  AState.BonusScore := FState.BonusItem.Score;
  AState.BonusTileX := FState.BonusItem.TileX;
  AState.BonusTileY := FState.BonusItem.TileY;
  AState.BonusMapSpot := FState.BonusItem.MapSpot;
  AState.BonusNum := FState.BonusItem.Num;
  AState.BonusName := FState.BonusItem.Name;
  AState.BonusSpritePicture := -1;
  if FState.BonusItem.Sprite <> GREED_POOL_NIL then
    AState.BonusSpritePicture := PGreedSprite(FSprites.Item(FState.BonusItem.Sprite))^.BasePic;
  AState.Paused := Ord(FLink.Paused);
  AState.WarpJammer := Ord(FLink.WarpJammer);
  AState.WarpJamTime := FLink.WarpJamTime;
  AState.RandomCalls := FRandomCalls;
  // the steps in which the goal of the status bar was asked to be drawn again (oldgoalitem := -1)
  if FGoalFlag then
  begin
    Inc(FGoalRefreshed);
    FGoalFlag := False;
  end;
  AState.GoalRefreshed := FGoalRefreshed;
  for LPlayer := 0 to NET_DUMP_PLAYERS - 1 do
  begin
    AState.PlayerFrags[LPlayer] := FState.Player.Frags[LPlayer];
    AState.FragCount[LPlayer] := FLink.FragCount[LPlayer];
    AState.Names[LPlayer] := FLink.NetName[LPlayer];
    LData := FLink.PlayerData[LPlayer];
    Move(LData, AState.PlayerData[LPlayer, 0], SizeOf(LData));
    AState.PlayerMapSpot[LPlayer] := FSession.PlayerMapSpot(LPlayer);
    LSprite := FSession.PlayerSprite(LPlayer);
    AState.PlayerSprites[LPlayer].Present := LSprite <> GREED_POOL_NIL;
    if LSprite <> GREED_POOL_NIL then
    begin
      LItem := PGreedSprite(FSprites.Item(LSprite));
      AState.PlayerSprites[LPlayer].Values[0] := LItem^.X;
      AState.PlayerSprites[LPlayer].Values[1] := LItem^.Y;
      AState.PlayerSprites[LPlayer].Values[2] := LItem^.Z;
      AState.PlayerSprites[LPlayer].Values[3] := LItem^.Angle;
      AState.PlayerSprites[LPlayer].Values[4] := LItem^.BasePic;
      AState.PlayerSprites[LPlayer].Values[5] := LItem^.StartPic;
      AState.PlayerSprites[LPlayer].Values[6] := LItem^.Scale;
      AState.PlayerSprites[LPlayer].Values[7] := Ord(LItem^.Rotate);
      AState.PlayerSprites[LPlayer].Values[8] := LItem^.MoveMode;
      AState.PlayerSprites[LPlayer].Values[9] := LItem^.ModeTime;
      AState.PlayerSprites[LPlayer].Values[10] := LItem^.HitPoints;
      AState.PlayerSprites[LPlayer].Values[11] := Ord(LItem^.SpecialType);
      AState.PlayerSprites[LPlayer].Values[12] := LItem^.Animation;
      AState.PlayerSprites[LPlayer].Values[13] := Ord(LItem^.Active);
      AState.PlayerSprites[LPlayer].Values[14] := LItem^.Heat;
      AState.PlayerSprites[LPlayer].Values[15] := LItem^.MoveSpeed;
      AState.PlayerSprites[LPlayer].Values[16] := LItem^.Intelligence;
      AState.PlayerSprites[LPlayer].Values[17] := LItem^.Kind;
      AState.PlayerSprites[LPlayer].Values[18] := LItem^.Height;
    end;
  end;
  SetLength(AState.Sprites, FSprites.Count * 9);
  LCount := 0;
  LSprite := FSprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    LItem := PGreedSprite(FSprites.Item(LSprite));
    AState.Sprites[LCount] := LItem^.Kind;
    AState.Sprites[LCount + 1] := LItem^.X;
    AState.Sprites[LCount + 2] := LItem^.Y;
    AState.Sprites[LCount + 3] := LItem^.BasePic;
    AState.Sprites[LCount + 4] := LItem^.Scale;
    AState.Sprites[LCount + 5] := LItem^.Animation;
    AState.Sprites[LCount + 6] := LItem^.HitPoints;
    AState.Sprites[LCount + 7] := Ord(LItem^.Rotate);
    AState.Sprites[LCount + 8] := LItem^.Intelligence;
    Inc(LCount, 9);
    LSprite := FSprites.Next(LSprite);
  end;
  LCount := 0;
  SetLength(AState.MapSprites, GREED_MAP_TILES);
  for LIndex := 0 to GREED_MAP_TILES - 1 do
    if FWorld.GetValue(gpMapSprites, LIndex) <> 0 then
    begin
      AState.MapSprites[LCount] := LIndex * 256 + FWorld.GetValue(gpMapSprites, LIndex);
      Inc(LCount);
    end;
  SetLength(AState.MapSprites, LCount);
end;

end.
