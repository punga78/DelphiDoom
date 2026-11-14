{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: what runs a scenario of the net game      }
{                                                                              }
{  Shared by the test of TGreedNetSession and by the harness that runs the      }
{  code of net.pas of xGreed (Tools\Verifica\175-net): no DUnitX here           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.NetRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Tests.Greed.NetScenarios;

const
  NET_DUMP_PLAYERS = 8;

type
  /// <summary>The fields of the sprite of another player that the net game writes</summary>
  TNetSpriteDump = record
    Present: Boolean;
    Values: array[0..18] of Integer;
  end;

  /// <summary>Everything that the net game can change, after a step</summary>
  TNetStateDump = record
    TimeCount, PlayerStatus, PlayerDifficulty, GoalItem, GameLoading: Integer;
    TargX, TargY, TargZ: Integer;
    PlayerFrags: array[0..NET_DUMP_PLAYERS - 1] of Integer;
    BonusTime, BonusScore, BonusTileX, BonusTileY, BonusMapSpot, BonusNum, BonusSpritePicture: Integer;
    BonusName: string;
    FragCount: array[0..NET_DUMP_PLAYERS - 1] of Integer;
    Names: array[0..NET_DUMP_PLAYERS - 1] of AnsiString;
    PlayerData: array[0..NET_DUMP_PLAYERS - 1, 0..12] of Integer;
    PlayerSprites: array[0..NET_DUMP_PLAYERS - 1] of TNetSpriteDump;
    PlayerMapSpot: array[0..NET_DUMP_PLAYERS - 1] of Integer;
    Paused, WarpJammer, WarpJamTime: Integer;
    /// <summary>The sprites of the level in the order of the list: kind, x, y, picture and scale of each</summary>
    Sprites: TArray<Integer>;
    /// <summary>mapsprites: the tiles that are not zero, as tile * 256 + value</summary>
    MapSprites: TArray<Integer>;
    RandomCalls: Integer;
    GoalRefreshed: Integer;
  end;

  /// <summary>
  ///   Runs a scenario on a net game (the library or the original) and writes what happened as lines of text: for
  ///   each step the packets that were sent, byte by byte, a fingerprint of the calls made to the rest of the
  ///   game and a fingerprint of the state. With Verbose the calls and the state are written in full
  /// </summary>
  TNetScenarioRunner = class
  strict private
    FLines: TStrings;
    FCalls: TStringList;
    FTurns: TArray<TNetWaitTurn>;
    FTurnsEmitted: Integer;
    FVerbose: Boolean;
    class function Hash(const AText: string): string; static;
    class function Hex(const ABytes: TBytes): string; static;
    function StateText: string;
    procedure Emit(const ALabel: string);
    procedure EmitWaitTurn(AIndex: Integer);
    procedure RunOp(AIndex: Integer; const AOp: TNetOp);
  protected
    // ---- what each side does ----
    procedure Open(const AScenario: TNetScenario); virtual; abstract;
    procedure Close; virtual; abstract;
    procedure SetClock(AValue: Integer); virtual; abstract;
    /// <summary>x, y, z, angle, angst, height, chartype, status, holopic, holoscale, specialeffect</summary>
    procedure SetPlayer(const AValues: array of Integer); virtual; abstract;
    procedure QueueIncoming(const ABytes: TBytes); virtual; abstract;
    procedure SetMapSprite(ASpot, AValue: Integer); virtual; abstract;
    /// <summary>time, score, tilex, tiley, num of the bonus item</summary>
    procedure SetBonus(const AValues: array of Integer); virtual; abstract;
    procedure AddSprite(AKind, AX, AY: Integer); virtual; abstract;
    /// <summary>The Net* routine of the step (noGetData .. noEvent)</summary>
    procedure Call(const AOp: TNetOp); virtual; abstract;
    /// <summary>
    ///   NetWaitStart: at the top of every turn of its loop WaitTurnBegin(turn) must be called, and the wait is
    ///   cancelled when it says false. True if the game started
    /// </summary>
    function RunWait: Boolean; virtual; abstract;
    function TakeSent: TArray<TBytes>; virtual; abstract;
    procedure GetState(out AState: TNetStateDump); virtual; abstract;
    // ---- for each side ----
    function WaitTurnBegin(AIndex: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The lines of a scenario are added to ALines</summary>
    procedure Run(AIndex: Integer; ALines: TStrings);
    // ---- what the fake game of each side calls: one line for each call that the net game makes ----
    procedure NoteSpawn(AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2: Integer; AActive: Boolean; ASpawnId: Integer;
      AGameLoading: Boolean);
    procedure NoteDemandLoad(ALump, ACount: Integer);
    procedure NoteTryDoor(AX, AY: Integer);
    procedure NoteCheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType, AMapSprite: Integer);
    procedure NoteCheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer);
    procedure NoteSound(ASound, AVariation, AX, AY: Integer);
    procedure NoteMessage(const AText: string);
    procedure NoteAddScore(AAmount: Integer);
    procedure NoteEvent(ANumber: Integer; ANetSend: Boolean);
    procedure NoteError(const AText: string);
    property Verbose: Boolean read FVerbose write FVerbose;
  end;

implementation

const
  OP_NAMES: array[TNetOpKind] of string = (
    'clock', 'player', 'incoming', 'mapsprite', 'setbonus', 'addsprite',
    'getdata', 'sendplayer', 'newplayer', 'sendspawn', 'sound', 'itempickup', 'death', 'closest', 'opendoor',
    'checkhere', 'bonus', 'pause', 'unpause', 'message', 'quit', 'warpjam', 'event');

{ TNetScenarioRunner }

constructor TNetScenarioRunner.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
end;

destructor TNetScenarioRunner.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

class function TNetScenarioRunner.Hash(const AText: string): string;
var
  LHash: Cardinal;
  LIndex: Integer;
begin
  // FNV-1a over the characters (all below 256)
  LHash := 2166136261;
  for LIndex := 1 to Length(AText) do
  begin
    LHash := LHash xor (Cardinal(Ord(AText[LIndex])) and $FF);
    LHash := LHash * 16777619;
  end;
  Result := IntToHex(LHash, 8);
end;

class function TNetScenarioRunner.Hex(const ABytes: TBytes): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(ABytes) do
    Result := Result + IntToHex(ABytes[LIndex], 2);
end;

function TNetScenarioRunner.StateText: string;
var
  LState: TNetStateDump;
  LBuilder: TStringBuilder;
  LPlayer, LIndex: Integer;
begin
  GetState(LState);
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.AppendFormat('t=%d st=%d dif=%d goal=%d load=%d targ=%d,%d,%d', [LState.TimeCount, LState.PlayerStatus,
      LState.PlayerDifficulty, LState.GoalItem, LState.GameLoading, LState.TargX, LState.TargY, LState.TargZ]);
    LBuilder.AppendFormat(' bonus=%d,%d,%d,%d,%d,%d,%d,"%s"', [LState.BonusTime, LState.BonusScore,
      LState.BonusTileX, LState.BonusTileY, LState.BonusMapSpot, LState.BonusNum, LState.BonusSpritePicture,
      LState.BonusName]);
    LBuilder.AppendFormat(' pause=%d jam=%d,%d rnd=%d refresh=%d', [LState.Paused, LState.WarpJammer,
      LState.WarpJamTime, LState.RandomCalls, LState.GoalRefreshed]);
    for LPlayer := 0 to NET_DUMP_PLAYERS - 1 do
    begin
      LBuilder.AppendLine;
      LBuilder.AppendFormat(' p%d frags=%d count=%d name="%s" spot=%d data=', [LPlayer, LState.PlayerFrags[LPlayer],
        LState.FragCount[LPlayer], string(LState.Names[LPlayer]), LState.PlayerMapSpot[LPlayer]]);
      for LIndex := 0 to 12 do
        LBuilder.Append(LState.PlayerData[LPlayer, LIndex]).Append(',');
      if LState.PlayerSprites[LPlayer].Present then
      begin
        LBuilder.Append(' sprite=');
        for LIndex := Low(LState.PlayerSprites[LPlayer].Values) to High(LState.PlayerSprites[LPlayer].Values) do
          LBuilder.Append(LState.PlayerSprites[LPlayer].Values[LIndex]).Append(',');
      end;
    end;
    LBuilder.AppendLine;
    LBuilder.Append(' sprites=');
    for LIndex := 0 to High(LState.Sprites) do
      LBuilder.Append(LState.Sprites[LIndex]).Append(',');
    LBuilder.AppendLine;
    LBuilder.Append(' map=');
    for LIndex := 0 to High(LState.MapSprites) do
      LBuilder.Append(LState.MapSprites[LIndex]).Append(',');
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TNetScenarioRunner.Emit(const ALabel: string);
var
  LSent: TArray<TBytes>;
  LPackets, LState: string;
  LIndex: Integer;
begin
  LSent := TakeSent;
  LPackets := '';
  for LIndex := 0 to High(LSent) do
  begin
    if LIndex > 0 then
      LPackets := LPackets + ';';
    LPackets := LPackets + Hex(LSent[LIndex]);
  end;
  LState := StateText;
  FLines.Add(Format('%s | %s | calls %d %s | state %s', [ALabel, LPackets, FCalls.Count, Hash(FCalls.Text),
    Hash(LState)]));
  if FVerbose then
  begin
    for LIndex := 0 to FCalls.Count - 1 do
      FLines.Add('    > ' + FCalls[LIndex]);
    FLines.Add('    ' + LState);
  end;
  FCalls.Clear;
end;

procedure TNetScenarioRunner.EmitWaitTurn(AIndex: Integer);
begin
  if AIndex < FTurnsEmitted then
    Exit;
  Emit(Format('  wait %d', [AIndex]));
  FTurnsEmitted := AIndex + 1;
end;

function TNetScenarioRunner.WaitTurnBegin(AIndex: Integer): Boolean;
begin
  if AIndex > 0 then
    EmitWaitTurn(AIndex - 1);
  if AIndex > High(FTurns) then
    Exit(False);
  SetClock(FTurns[AIndex].Time);
  if FTurns[AIndex].HasPacket then
    QueueIncoming(FTurns[AIndex].Packet);
  Result := True;
end;

procedure TNetScenarioRunner.RunOp(AIndex: Integer; const AOp: TNetOp);
begin
  case AOp.Kind of
    noClock:
      SetClock(AOp.A[0]);
    noPlayer:
      SetPlayer(AOp.A);
    noIncoming:
      QueueIncoming(AOp.Bytes);
    noMapSprite:
      SetMapSprite(AOp.A[0], AOp.A[1]);
    noSetBonus:
      SetBonus(AOp.A);
    noAddSprite:
      AddSprite(AOp.A[0], AOp.A[1], AOp.A[2]);
  else
    try
      Call(AOp);
    except
      on E: Exception do
        NoteError(E.Message);
    end;
    Emit(Format('  %d %s', [AIndex, OP_NAMES[AOp.Kind]]));
  end;
end;

procedure TNetScenarioRunner.Run(AIndex: Integer; ALines: TStrings);
var
  LScenario: TNetScenario;
  LIndex: Integer;
  LOutcome: string;
begin
  LScenario := TNetScenarios.Build(AIndex);
  FLines := ALines;
  FCalls.Clear;
  FLines.Add(Format('scenario %d: %s (player %d of %d, net %d)', [AIndex, LScenario.Name, LScenario.ConsolePlayer,
    LScenario.NumPlayers, LScenario.NetType]));
  Open(LScenario);
  try
    Emit('  open');
    if Length(LScenario.Wait) > 0 then
    begin
      FTurns := LScenario.Wait;
      FTurnsEmitted := 0;
      try
        if RunWait then
          LOutcome := 'started'
        else
          LOutcome := 'cancelled';
      except
        on E: Exception do
          LOutcome := 'error: ' + E.Message;
      end;
      Emit('  wait end: ' + LOutcome);
    end;
    for LIndex := 0 to High(LScenario.Ops) do
      RunOp(LIndex, LScenario.Ops[LIndex]);
  finally
    Close;
    FLines := nil;
  end;
end;

procedure TNetScenarioRunner.NoteSpawn(AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2: Integer; AActive: Boolean;
  ASpawnId: Integer; AGameLoading: Boolean);
begin
  FCalls.Add(Format('SpawnSprite %d %d %d %d %d %d %d %d %d loading=%d', [AValue, AX, AY, AZ, AZAdjust, AAngle,
    AAngle2, Ord(AActive), ASpawnId, Ord(AGameLoading)]));
end;

procedure TNetScenarioRunner.NoteDemandLoad(ALump, ACount: Integer);
begin
  FCalls.Add(Format('DemandLoadMonster %d %d', [ALump, ACount]));
end;

procedure TNetScenarioRunner.NoteTryDoor(AX, AY: Integer);
begin
  FCalls.Add(Format('TryDoor %d %d', [AX, AY]));
end;

procedure TNetScenarioRunner.NoteCheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType,
  AMapSprite: Integer);
begin
  FCalls.Add(Format('CheckItems %d %d %d %d map=%d', [ATileX, ATileY, Ord(AUseIt), ACharType, AMapSprite]));
end;

procedure TNetScenarioRunner.NoteCheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer);
begin
  FCalls.Add(Format('CheckHere %d %d %d %d', [Ord(AUseIt), AX, AY, AAngle]));
end;

procedure TNetScenarioRunner.NoteSound(ASound, AVariation, AX, AY: Integer);
begin
  FCalls.Add(Format('SoundEffect %d %d %d %d', [ASound, AVariation, AX, AY]));
end;

procedure TNetScenarioRunner.NoteMessage(const AText: string);
begin
  FCalls.Add('writemsg ' + AText);
end;

procedure TNetScenarioRunner.NoteAddScore(AAmount: Integer);
begin
  FCalls.Add(Format('addscore %d', [AAmount]));
end;

procedure TNetScenarioRunner.NoteEvent(ANumber: Integer; ANetSend: Boolean);
begin
  FCalls.Add(Format('Event %d %d', [ANumber, Ord(ANetSend)]));
end;

procedure TNetScenarioRunner.NoteError(const AText: string);
begin
  FCalls.Add('error: ' + AText);
end;

end.
