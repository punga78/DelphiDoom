{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the net game: the session                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): net.pas (NetInit,           }
{  NetWaitStart, NetGetData, SpawnNewPlayer and the Net* senders), from the     }
{  code that xGreed keeps in a comment after "end."                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Net.Session;

// the tics and the positions are 32 bit numbers that wrap as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Intf, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Net.Types,
  DelphiDoom.Greed.Net.Intf, DelphiDoom.Greed.Net.PacketBuffer;

type
  /// <summary>
  ///   The net game of "In Pursuit of Greed": net.pas as an object. The DOS game talked to a driver that stayed
  ///   in memory (NETGREED.EXE for IPX, SERGREED.EXE for serial line and modem) through a software interrupt and
  ///   the record greedcom_t: command CMD_SEND or CMD_GET, the node (8 = everybody, -1 = nothing arrived) and 128
  ///   bytes of data. xGreed has no driver and its net.pas is empty routines (the code is a comment), so there is
  ///   nothing to be compatible with on a wire: here the "interrupt" is an INetTransport of Libs\Net (datagrams
  ///   to the other nodes of the game; every packet of Greed goes to all of them) and the packets are the same
  ///   bytes that the original put in greedcom.data.
  ///   What travels: where each player is and what it does (every 3 + players tics), every shot, mine and
  ///   device that a player makes, doors, switches, items picked up, sounds, the bonus item (placed by player 0),
  ///   deaths with who caused them, pause, messages. Each computer runs its own monsters and its own clock: the
  ///   game is not kept in step tic by tic (it is not the lockstep of Doom), and nothing is sent twice or
  ///   acknowledged: a packet that is lost is lost.
  ///   The state of the original that is of the net only (fragcount, playerdata, netnames, playersprites,
  ///   netpaused, netwarpjammer) is here; the rest is read and written in the TGreedGameState of the game.
  ///   Differences from the original, which read or wrote outside its arrays: a packet of less than 8 bytes, or
  ///   from a player that is not 0..7, is thrown away; a new player of a character that does not exist is
  ///   ignored; the death of a player whose sprite is not there only clears its tile; the nearest player, when
  ///   nobody is alive and visible, leaves the target as it is; a text of 30 characters or more is cut at 30; the
  ///   tile of a bonus item is taken as it comes (the original would loop for ever on a tile that is not free);
  ///   the walk over the sprites of the warp jammer stops at the end of the list
  /// </summary>
  TGreedNetSession = class(TInterfacedObject, IGreedNetLink, IGreedNetStart)
  strict private
    FState: TGreedGameState;
    FTransport: INetTransport;
    FConfig: TGreedNetConfig;
    FArchive: IGreedArchive;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FMessages: IGreedMessages;
    FHealth: IGreedPlayerHealth;
    FRandom: IGreedRandom;
    FEvents: IGreedEventRunner;
    FHost: IGreedNetHost;
    FBuffer: TGreedNetPacketBuffer;
    FPlayerNum: Integer;
    FFragCount: array[0..GREED_MAX_PLAYERS - 1] of Integer;
    FPlayerData: array[0..GREED_MAX_PLAYERS - 1] of TGreedPlayerEvent;
    FNetNames: array[0..GREED_MAX_PLAYERS - 1] of TGreedNetName;
    FPlayerSprites: array[0..GREED_MAX_PLAYERS - 1] of Integer;
    FPlayerMapSpot: array[0..GREED_MAX_PLAYERS - 1] of Integer;
    FWarpJammer: Boolean;
    FWarpJamTime: Integer;
    FPaused: Boolean;
    // NetWaitStart
    FWaiting: Boolean;
    FPlayers: array[0..GREED_MAX_PLAYERS - 1] of Integer;
    FPlayersFound: array[0..GREED_MAX_PLAYERS - 1] of Integer;
    FFound: Integer;
    FReady: Integer;
    FTimeout: Integer;
    FWaitTime: Integer;
    class function IsPlayer(AValue: Integer): Boolean; static;
    class procedure CopyName(var ATarget: TGreedNetName; const ASource: TGreedNetName); static;
    function MapSprite(ASpot: Integer): Integer;
    procedure SetMapSprite(ASpot, AValue: Integer);
    function TileOf(AX, AY: TGreedFixed): Integer;
    function NameOf(APlayer: Integer): string;
    procedure Send(ALength: Integer);
    function Receive: Boolean;
    procedure SendPlayerOnly(AEventId: Integer);
    procedure FillPlayerEvent(var AEvent: TGreedPlayerEvent; AEventId: Integer);
    procedure FinishWaitStart;
    procedure SpawnNewPlayer;
    procedure DoPlayer;
    procedure DoSpawn;
    procedure DoItem;
    procedure DoBonus;
    procedure DoFrag;
    procedure DoJammer;
    procedure DoMessage;
  public
    /// <summary>
    ///   NetInit: AConfig is what the driver wrote in greedcom_t. AState has the player, the clock, the world and
    ///   the sprites of the game; ATransport carries the packets (node 0 is this computer, the others are the
    ///   other players, in any order); AArchive is CA_GetNamedNum, ASpawner SpawnSprite and DemandLoadMonster,
    ///   ASound SoundEffect, AMessages writemsg, AHealth addscore, ARandom MS_RndT, AEvents Event of event.pas,
    ///   AHost the rest of raven.pas. EArgumentNilException if one is nil; EGreedNetException if the kind of net
    ///   is unknown ("Unknown net type!") or the players are not 1..8 with this one among them
    /// </summary>
    constructor Create(AState: TGreedGameState; const ATransport: INetTransport; const AConfig: TGreedNetConfig;
      const AArchive: IGreedArchive; const ASpawner: IGreedSpawner; const ASound: IGreedGameSound;
      const AMessages: IGreedMessages; const AHealth: IGreedPlayerHealth; const ARandom: IGreedRandom;
      const AEvents: IGreedEventRunner; const AHost: IGreedNetHost);
    destructor Destroy; override;
    // IGreedNetStart
    procedure BeginWaitStart;
    function WaitStartStep: Boolean;
    // IGreedNetLink
    procedure GetData;
    procedure SendPlayerData;
    procedure NewPlayerData;
    procedure SendSpawn(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer);
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure ItemPickup(ATileX, ATileY: Integer);
    procedure Death(ABulletId: Integer);
    procedure GetClosestPlayer(ATileX, ATileY: Integer);
    procedure OpenDoor(AX, AY: TGreedFixed);
    procedure CheckHere(ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
    procedure BonusItem;
    procedure Pause;
    procedure UnPause;
    procedure SendMessage(const AText: AnsiString);
    procedure QuitGame;
    function GetNumPlayers: Integer;
    function GetConsolePlayer: Integer;
    function GetPaused: Boolean;
    function GetWarpJammer: Boolean;
    function GetWarpJamTime: Integer;
    function GetPlayerData(APlayer: Integer): TGreedPlayerEvent;
    function GetFragCount(APlayer: Integer): Integer;
    function GetNetName(APlayer: Integer): AnsiString;
    /// <summary>
    ///   NetWarpJam and NetEvent of net.pas: the game of xGreed never calls them (the call of NetEvent in
    ///   RunEvent is a comment, NetWarpJam is not even declared); the packets are read when they arrive
    /// </summary>
    procedure WarpJam;
    procedure Event(ANumber: Integer);
    /// <summary>playersprites[n]: the sprite that shows another player (GREED_POOL_NIL if there is none)</summary>
    function PlayerSprite(APlayer: Integer): Integer;
    /// <summary>playermapspot[n]: the tile where that sprite was put last</summary>
    function PlayerMapSpot(APlayer: Integer): Integer;
    /// <summary>greedcom.nettype</summary>
    function NetType: Integer;
    /// <summary>BeginWaitStart was called and the game has not started yet</summary>
    property Waiting: Boolean read FWaiting;
  end;

implementation

uses
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Render.Types;

const
  TIC_RATE = 70;
  /// the characters of a name that travel (strncpy(..., 12)); the thirteenth byte is the zero
  NAME_CHARS = GREED_NET_NAME_SIZE - 1;
  NET_PLAYER_HIT_POINTS = 500;
  NET_PLAYER_HEIGHT = 60 * GREED_FRACUNIT;
  NET_PLAYER_PICTURES = 48;
  /// the pictures of a player: walking 0, 8 and 16, firing 24, hit 32, dead 40
  PICTURE_MIDSTEP = 8;
  PICTURE_FIRING = 24;
  PICTURE_HIT = 32;
  PICTURE_DEAD = 40;
  MODE_TICS = 12;
  FRAG_SCORE = 5000;
  /// the shots that a packet tells once and that are made as a ring
  RING_SHOTS_BULLET18 = 12;
  RING_SHOTS_SOUL = 16;
  SFraggedBy = 'You were fragged by %s!';
  SFragged = 'Fragged %s! %d of %d';
  SOtherFragged = '%s fragged %s.';
  SWasKilled = '%s was killed.';
  SWarpJammer = '%s activated Warp Jammer!';
  SLeftGame = '%s has left the game!';
  SBonusLocated = 'Bonus item located!';
  SMessage = '%s: %s';

{ TGreedNetSession }

constructor TGreedNetSession.Create(AState: TGreedGameState; const ATransport: INetTransport;
  const AConfig: TGreedNetConfig; const AArchive: IGreedArchive; const ASpawner: IGreedSpawner;
  const ASound: IGreedGameSound; const AMessages: IGreedMessages; const AHealth: IGreedPlayerHealth;
  const ARandom: IGreedRandom; const AEvents: IGreedEventRunner; const AHost: IGreedNetHost);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ATransport) then
    raise EArgumentNilException.Create('ATransport');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  if not Assigned(AHealth) then
    raise EArgumentNilException.Create('AHealth');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  if (AConfig.NetType <> GREED_NET_IPX) and (AConfig.NetType <> GREED_NET_SERIAL) and
    (AConfig.NetType <> GREED_NET_MODEM) then
    raise EGreedNetException.Create(SGreedNetUnknownType);
  if (AConfig.NumPlayers < 1) or (AConfig.NumPlayers > GREED_MAX_PLAYERS) or (AConfig.ConsolePlayer < 0) or
    (AConfig.ConsolePlayer >= AConfig.NumPlayers) then
    raise EGreedNetException.CreateFmt(SGreedNetBadPlayers, [AConfig.NumPlayers, AConfig.ConsolePlayer]);
  FState := AState;
  FTransport := ATransport;
  FConfig := AConfig;
  FArchive := AArchive;
  FSpawner := ASpawner;
  FSound := ASound;
  FMessages := AMessages;
  FHealth := AHealth;
  FRandom := ARandom;
  FEvents := AEvents;
  FHost := AHost;
  FBuffer := TGreedNetPacketBuffer.Create;
  FPlayerNum := AConfig.ConsolePlayer;
  for LIndex := Low(FPlayerSprites) to High(FPlayerSprites) do
    FPlayerSprites[LIndex] := GREED_POOL_NIL;
end;

destructor TGreedNetSession.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

class function TGreedNetSession.IsPlayer(AValue: Integer): Boolean;
begin
  Result := (AValue >= 0) and (AValue < GREED_MAX_PLAYERS);
end;

class procedure TGreedNetSession.CopyName(var ATarget: TGreedNetName; const ASource: TGreedNetName);
var
  LIndex: Integer;
  LEnded: Boolean;
begin
  // strncpy(target, source, 12): after the zero of the source the rest of the 12 bytes is zero
  LEnded := False;
  for LIndex := 0 to NAME_CHARS - 1 do
  begin
    if ASource[LIndex] = #0 then
      LEnded := True;
    if LEnded then
      ATarget[LIndex] := #0
    else
      ATarget[LIndex] := ASource[LIndex];
  end;
end;

function TGreedNetSession.MapSprite(ASpot: Integer): Integer;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Result := 0
  else
    Result := FState.World.GetValue(gpMapSprites, ASpot);
end;

procedure TGreedNetSession.SetMapSprite(ASpot, AValue: Integer);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(gpMapSprites, ASpot, Byte(AValue and $FF));
end;

function TGreedNetSession.TileOf(AX, AY: TGreedFixed): Integer;
begin
  Result := (AY div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (AX div GREED_FRACTILEUNIT);
end;

function TGreedNetSession.NameOf(APlayer: Integer): string;
begin
  Result := string(GetNetName(APlayer));
end;

procedure TGreedNetSession.Send(ALength: Integer);
var
  LBytes: TBytes;
  LNode: Integer;
begin
  // greedcom.remotenode := MAXPLAYERS: every packet of the game is for everybody
  LBytes := FBuffer.ToBytes(ALength);
  for LNode := 1 to FTransport.NodeCount - 1 do
    FTransport.Send(LNode, LBytes);
end;

function TGreedNetSession.Receive: Boolean;
var
  LNode: Integer;
  LBytes: TBytes;
begin
  // CMD_GET; greedcom.remotenode = -1 when nothing arrived
  Result := FTransport.Receive(LNode, LBytes);
  if Result then
    FBuffer.Load(LBytes);
end;

procedure TGreedNetSession.BeginWaitStart;
var
  LIndex: Integer;
  LOwnName: TGreedNetName;
begin
  FillChar(FPlayers, SizeOf(FPlayers), 0);
  FillChar(FPlayersFound, SizeOf(FPlayersFound), 0);
  FillChar(LOwnName, SizeOf(LOwnName), 0);
  for LIndex := 0 to NAME_CHARS - 1 do
    if LIndex < Length(FConfig.NetName) then
      LOwnName[LIndex] := FConfig.NetName[LIndex + 1];
  CopyName(FNetNames[FPlayerNum], LOwnName);
  // a name filled with blanks up to its eleventh character loses them
  if FNetNames[FPlayerNum][10] = ' ' then
  begin
    LIndex := 10;
    while (LIndex > 0) and (FNetNames[FPlayerNum][LIndex] = ' ') do
    begin
      FNetNames[FPlayerNum][LIndex] := #0;
      Dec(LIndex);
    end;
  end;
  // found ourself
  FPlayers[FPlayerNum] := 1;
  FFound := 1;
  FReady := 0;
  // 10 minute wait
  FTimeout := FState.TimeCount + GREED_NET_START_TIMEOUT;
  FWaitTime := FState.TimeCount + TIC_RATE;
  FWaiting := True;
end;

function TGreedNetSession.WaitStartStep: Boolean;
var
  LEvent: TGreedNetInitEvent;
  LIndex: Integer;
begin
  if not FWaiting then
    raise EGreedNetException.Create(SGreedNetNotWaiting);
  Result := False;
  if FState.TimeCount > FTimeout then
    raise EGreedNetException.Create(SGreedNetTimeOut);
  if FState.TimeCount > FWaitTime then
  begin
    // count how many we've found
    FFound := 0;
    for LIndex := 0 to FConfig.NumPlayers - 1 do
      if FPlayers[LIndex] <> 0 then
        Inc(FFound);
    FPlayersFound[FPlayerNum] := FFound;
    LEvent := FBuffer.ReadInit;
    LEvent.Id := GREED_NET_EVENT_INIT;
    // tell who we are, how many we've found; player 0 tells when to start
    LEvent.PlayerId := FPlayerNum;
    LEvent.Found := FFound;
    LEvent.Start := FReady;
    LEvent.Map := FState.Player.Map;
    LEvent.Difficulty := FState.Player.Difficulty;
    CopyName(LEvent.NetName, FNetNames[FPlayerNum]);
    FBuffer.WriteInit(LEvent);
    Send(SizeOf(TGreedNetInitEvent));
    FWaitTime := FState.TimeCount + GREED_NET_START_PERIOD;
  end;
  // the buffer has the packet that was sent now or the last one that arrived
  if FBuffer.ReadInit.Start = FConfig.NumPlayers then
  begin
    FinishWaitStart;
    Exit(True);
  end;
  // no broadcasts
  if not Receive then
    Exit;
  LEvent := FBuffer.ReadInit;
  // wrong packet id
  if LEvent.Id <> GREED_NET_EVENT_INIT then
    Exit;
  // we can start now
  if (FConfig.NetType <> GREED_NET_IPX) and (LEvent.Start = FConfig.NumPlayers) then
  begin
    FinishWaitStart;
    Exit(True);
  end;
  if not IsPlayer(LEvent.PlayerId) then
    Exit;
  if LEvent.PlayerId = 0 then
    FState.Player.Difficulty := LEvent.Difficulty;
  if LEvent.Map <> FState.Player.Map then
    raise EGreedNetException.CreateFmt(SGreedNetDifferentMap, [LEvent.PlayerId]);
  // found new player, and how many they've found
  FPlayers[LEvent.PlayerId] := 1;
  FPlayersFound[LEvent.PlayerId] := LEvent.Found;
  CopyName(FNetNames[LEvent.PlayerId], LEvent.NetName);
  // player 0 checks for readiness
  if FPlayerNum = 0 then
  begin
    FReady := 0;
    for LIndex := 0 to FConfig.NumPlayers - 1 do
      if FPlayersFound[LIndex] = FConfig.NumPlayers then
        Inc(FReady);
  end;
end;

procedure TGreedNetSession.FinishWaitStart;
begin
  FWaiting := False;
  FState.TimeCount := 0;
  NewPlayerData;
  if (FConfig.NetType <> GREED_NET_IPX) and (FConfig.ConsolePlayer = 0) then
    FState.TimeCount := 19;
  GetData;
end;

procedure TGreedNetSession.SpawnNewPlayer;
var
  LEvent: TGreedPlayerEvent;
  LIndex, LSpot: Integer;
  LSprite: PGreedSprite;
begin
  LEvent := FBuffer.ReadPlayer;
  if (LEvent.CharType < Low(TGreedGameTables.CharacterNames)) or
    (LEvent.CharType > High(TGreedGameTables.CharacterNames)) then
    Exit;
  LIndex := FState.Sprites.Add;
  FPlayerSprites[LEvent.PlayerId] := LIndex;
  LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
  LSprite^.Rotate := grEight;
  LSprite^.BasePic := FArchive.RequireIndexOf(TGreedGameTables.CharacterNames[LEvent.CharType]);
  FSpawner.DemandLoadMonster(LSprite^.BasePic, NET_PLAYER_PICTURES);
  LSprite^.Scale := 1;
  LSprite^.StartPic := LSprite^.BasePic;
  LSprite^.Intelligence := 255;
  LSprite^.X := LEvent.X;
  LSprite^.Y := LEvent.Y;
  LSprite^.Z := LEvent.Z;
  LSprite^.Angle := LEvent.Angle;
  LSprite^.Kind := GREED_S_NETPLAYER;
  LSprite^.HitPoints := NET_PLAYER_HIT_POINTS;
  LSprite^.Height := NET_PLAYER_HEIGHT;
  LSpot := TileOf(LSprite^.X, LSprite^.Y);
  FPlayerMapSpot[LEvent.PlayerId] := LSpot;
  if MapSprite(LSpot) = 0 then
    SetMapSprite(LSpot, GREED_SM_NETPLAYER);
end;

procedure TGreedNetSession.DoPlayer;
var
  LEvent: TGreedPlayerEvent;
  LIndex, LSpot: Integer;
  LSprite: PGreedSprite;
begin
  LEvent := FBuffer.ReadPlayer;
  LIndex := FPlayerSprites[LEvent.PlayerId];
  if LIndex = GREED_POOL_NIL then
    Exit;
  LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
  LSprite^.X := LEvent.X;
  LSprite^.Y := LEvent.Y;
  LSprite^.Z := LEvent.Z - LEvent.Height;
  LSprite^.Angle := LEvent.Angle;
  LSprite^.HitPoints := NET_PLAYER_HIT_POINTS;
  LSpot := FPlayerMapSpot[LEvent.PlayerId];
  if MapSprite(LSpot) = GREED_SM_NETPLAYER then
    SetMapSprite(LSpot, 0);
  LSpot := TileOf(LSprite^.X, LSprite^.Y);
  if MapSprite(LSpot) = 0 then
    SetMapSprite(LSpot, GREED_SM_NETPLAYER);
  FPlayerMapSpot[LEvent.PlayerId] := LSpot;

  if LEvent.Status = GREED_NET_STATUS_HIT then
  begin
    LSprite^.BasePic := LSprite^.StartPic + PICTURE_HIT;
    LSprite^.ModeTime := FState.TimeCount + MODE_TICS;
  end
  else if LEvent.Status = GREED_NET_STATUS_FIRING then
  begin
    LSprite^.BasePic := LSprite^.StartPic + PICTURE_FIRING;
    LSprite^.ModeTime := FState.TimeCount + MODE_TICS;
    // so it draws the walk frame
    FPlayerData[LEvent.PlayerId].X := -1;
  end;

  if FState.TimeCount > LSprite^.ModeTime then
  begin
    if (FPlayerData[LEvent.PlayerId].X <> LEvent.X) or (FPlayerData[LEvent.PlayerId].Y <> LEvent.Y) then
    begin
      if LSprite^.MoveMode = 3 then
      begin
        LSprite^.MoveMode := 0;
        LSprite^.BasePic := LSprite^.StartPic;
      end
      else if LSprite^.MoveMode = 2 then
      begin
        // midstep
        LSprite^.BasePic := LSprite^.StartPic + PICTURE_MIDSTEP;
        Inc(LSprite^.MoveMode);
      end
      else
      begin
        Inc(LSprite^.MoveMode);
        LSprite^.BasePic := LSprite^.StartPic + LSprite^.MoveMode * 8;
      end;
    end;
    LSprite^.ModeTime := FState.TimeCount + MODE_TICS;
  end;

  FPlayerData[LEvent.PlayerId] := LEvent;

  if LEvent.HoloPic <> 0 then
  begin
    LSprite^.BasePic := LEvent.HoloPic;
    LSprite^.Scale := LEvent.HoloScale;
    LSprite^.Rotate := grOne;
  end;

  if LEvent.SpecialEffect = GREED_SE_INVISIBILITY then
    LSprite^.SpecialType := gstTransparent
  else
    LSprite^.SpecialType := gstNone;
end;

procedure TGreedNetSession.DoSpawn;
var
  LEvent: TGreedNetSpawnEvent;
  LIndex, LAngle, LAngleStep, LCount: Integer;
begin
  LEvent := FBuffer.ReadSpawn;
  // the sprites made here are not told to the others again
  FState.GameLoading := True;
  LCount := 0;
  if LEvent.Value = GREED_S_BULLET18 then
    LCount := RING_SHOTS_BULLET18
  else if LEvent.Value = GREED_S_SOULBULLET then
    LCount := RING_SHOTS_SOUL;
  if LCount <> 0 then
  begin
    LAngleStep := GREED_ANGLES div LCount;
    LAngle := 0;
    for LIndex := 0 to LCount - 1 do
    begin
      FSpawner.SpawnSprite(LEvent.Value, LEvent.X, LEvent.Y, LEvent.Z, LEvent.ZAdjust, LAngle, LEvent.Angle2,
        LEvent.Active <> 0, LEvent.SpawnId);
      LAngle := LAngle + LAngleStep;
    end;
  end
  else
    FSpawner.SpawnSprite(LEvent.Value, LEvent.X, LEvent.Y, LEvent.Z, LEvent.ZAdjust, LEvent.Angle, LEvent.Angle2,
      LEvent.Active <> 0, LEvent.SpawnId);
  FState.GameLoading := False;
end;

procedure TGreedNetSession.DoItem;
var
  LEvent: TGreedNetItemEvent;
begin
  LEvent := FBuffer.ReadItem;
  SetMapSprite(LEvent.MapSpot, LEvent.Kind);
  FHost.CheckItems(LEvent.TileX, LEvent.TileY, False, LEvent.CharType);
  SetMapSprite(LEvent.MapSpot, 0);
end;

procedure TGreedNetSession.DoBonus;
var
  LEvent: TGreedNetBonusEvent;
  LSprite: Integer;
  LX, LY: TGreedFixed;
begin
  LEvent := FBuffer.ReadBonus;
  if FState.BonusItem.Score > 0 then
  begin
    LSprite := FState.Sprites.First;
    while LSprite <> GREED_POOL_NIL do
    begin
      if PGreedSprite(FState.Sprites.Item(LSprite))^.Kind = GREED_S_BONUSITEM then
      begin
        FState.Sprites.Remove(LSprite);
        SetMapSprite(FState.BonusItem.MapSpot, 0);
        Break;
      end;
      LSprite := FState.Sprites.Next(LSprite);
    end;
    FSpawner.SpawnSprite(GREED_S_WARP, (FState.BonusItem.TileX * GREED_MAP_SIZE + 32) * GREED_FRACUNIT,
      (FState.BonusItem.TileY * GREED_MAP_SIZE + 32) * GREED_FRACUNIT, 0, 0, 0, 0, False, 0);
  end;
  // the original repeats this while the tile is not free, and the tile never changes
  FState.BonusItem.TileX := LEvent.TileX;
  FState.BonusItem.TileY := LEvent.TileY;
  FState.BonusItem.MapSpot := FState.BonusItem.TileY * GREED_MAP_SIZE + FState.BonusItem.TileX;
  FState.BonusItem.Score := LEvent.Score;
  FState.BonusItem.Time := LEvent.Time;
  FState.BonusItem.Num := LEvent.Num;
  if (LEvent.Num >= Low(TGreedGameTables.RandomItemNames)) and
    (LEvent.Num <= High(TGreedGameTables.RandomItemNames)) then
    FState.BonusItem.Name := TGreedGameTables.RandomItemNames[LEvent.Num]
  else
    FState.BonusItem.Name := '';
  LX := (FState.BonusItem.TileX * GREED_MAP_SIZE + 32) * GREED_FRACUNIT;
  LY := (FState.BonusItem.TileY * GREED_MAP_SIZE + 32) * GREED_FRACUNIT;
  FState.BonusItem.Sprite := FSpawner.SpawnSprite(GREED_S_BONUSITEM, LX, LY, 0, 0, 0, 0, False, 0);
  FSpawner.SpawnSprite(GREED_S_WARP, LX, LY, 0, 0, 0, 0, False, 0);
  if FState.BonusItem.Sprite <> GREED_POOL_NIL then
  begin
    LSprite := FState.BonusItem.Sprite;
    PGreedSprite(FState.Sprites.Item(LSprite))^.BasePic :=
      PGreedSprite(FState.Sprites.Item(LSprite))^.BasePic + FState.BonusItem.Num;
  end;
  FHost.RefreshGoalItem;
  FMessages.WriteMessage(SBonusLocated);
end;

procedure TGreedNetSession.DoFrag;
var
  LEvent: TGreedNetFragEvent;
  LIndex, LMine: Integer;
  LSprite, LMineSprite: PGreedSprite;
begin
  LEvent := FBuffer.ReadFrag;
  if IsPlayer(LEvent.BulletId) then
  begin
    FHost.RefreshGoalItem;
    Inc(FFragCount[LEvent.BulletId]);
    FState.GoalItem := LEvent.BulletId + 1;
  end;
  if FPlayerNum = LEvent.BulletId then
  begin
    Inc(FState.Player.Frags[LEvent.PlayerId]);
    FHealth.AddScore(FRAG_SCORE);
    FMessages.WriteMessage(Format(SFragged, [NameOf(LEvent.PlayerId), FState.Player.Frags[LEvent.PlayerId],
      FFragCount[FPlayerNum]]));
  end
  else if IsPlayer(LEvent.BulletId) then
    FMessages.WriteMessage(Format(SOtherFragged, [NameOf(LEvent.BulletId), NameOf(LEvent.PlayerId)]))
  else
    FMessages.WriteMessage(Format(SWasKilled, [NameOf(LEvent.PlayerId)]));

  LIndex := FPlayerSprites[LEvent.PlayerId];
  if LIndex <> GREED_POOL_NIL then
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
    if LSprite^.StartPic = FArchive.RequireIndexOf(TGreedGameTables.CharacterNames[0]) then
    begin
      // do not transmit
      FState.GameLoading := True;
      LMine := FSpawner.SpawnSprite(GREED_S_TIMEMINE, LSprite^.X, LSprite^.Y, 0, 0, 0, 0, False, FPlayerNum);
      FState.GameLoading := False;
      if LMine <> GREED_POOL_NIL then
      begin
        LMineSprite := PGreedSprite(FState.Sprites.Item(LMine));
        LMineSprite^.BasePic := LSprite^.StartPic + PICTURE_DEAD;
        LMineSprite^.Scale := 1;
      end;
      LSprite^.BasePic := LSprite^.StartPic + PICTURE_DEAD;
      LSprite^.Animation := GREED_ANIM_SELF_DESTRUCT;
    end
    else
    begin
      LSprite^.BasePic := LSprite^.StartPic + PICTURE_DEAD;
      LSprite^.Animation := (8 shl 5) + ((6 + (FRandom.Next and 3)) shl 9);
    end;
    LSprite^.Rotate := grOne;
    LSprite^.Heat := 0;
    LSprite^.Active := False;
    LSprite^.MoveSpeed := 0;
    LSprite^.HitPoints := 0;
    LSprite^.Intelligence := 0;
  end;
  SetMapSprite(FPlayerMapSpot[LEvent.PlayerId], 0);
  FPlayerSprites[LEvent.PlayerId] := GREED_POOL_NIL;
end;

procedure TGreedNetSession.DoJammer;
var
  LSprite, LRemoved: Integer;
  LItem: PGreedSprite;
begin
  // as the original: the loop steps once more after its body has already stepped, so it looks at one sprite in
  // two when nothing is removed
  LSprite := FState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    LItem := PGreedSprite(FState.Sprites.Item(LSprite));
    if (LItem^.Kind = GREED_S_GENERATOR) or ((LItem^.Kind >= GREED_S_GENSTART) and (LItem^.Kind <= GREED_S_GENEND)) then
    begin
      SetMapSprite(TileOf(LItem^.X, LItem^.Y), 0);
      LRemoved := LSprite;
      LSprite := FState.Sprites.Next(LSprite);
      FState.Sprites.Remove(LRemoved);
    end
    else
      LSprite := FState.Sprites.Next(LSprite);
    if LSprite <> GREED_POOL_NIL then
      LSprite := FState.Sprites.Next(LSprite);
  end;
  FMessages.WriteMessage(Format(SWarpJammer, [NameOf(FBuffer.PlayerId)]));
  FWarpJammer := True;
  FWarpJamTime := FState.TimeCount + GREED_NET_WARP_JAM_TICS;
end;

procedure TGreedNetSession.DoMessage;
var
  LEvent: TGreedNetMessageEvent;
  LText: AnsiString;
  LLength: Integer;
begin
  LEvent := FBuffer.ReadMessage;
  LLength := 0;
  while (LLength < GREED_NET_TEXT_SIZE) and (LEvent.Text[LLength] <> #0) do
    Inc(LLength);
  SetString(LText, PAnsiChar(@LEvent.Text[0]), LLength);
  FMessages.WriteMessage(Format(SMessage, [NameOf(LEvent.PlayerId), string(LText)]));
  FSound.SoundEffect(GREED_SN_NEXUS, 0, FState.Player.X, FState.Player.Y);
end;

procedure TGreedNetSession.GetData;
var
  LPlayer: Integer;
  LDoor: TGreedNetDoorEvent;
  LSound: TGreedNetSoundEvent;
begin
  repeat
    if not Receive then
      Exit;
    LPlayer := FBuffer.PlayerId;
    if LPlayer = FPlayerNum then
      Continue;
    if not IsPlayer(LPlayer) then
      Continue;
    case FBuffer.EventId of
      GREED_NET_EVENT_PLAYER:
        DoPlayer;
      GREED_NET_EVENT_SPAWN:
        DoSpawn;
      GREED_NET_EVENT_DOOR:
        begin
          LDoor := FBuffer.ReadDoor;
          FHost.TryDoor(LDoor.X, LDoor.Y);
        end;
      GREED_NET_EVENT_ITEM:
        DoItem;
      GREED_NET_EVENT_SOUND:
        begin
          LSound := FBuffer.ReadSound;
          FSound.SoundEffect(LSound.Effect, LSound.Variation, LSound.X, LSound.Y);
        end;
      GREED_NET_EVENT_BONUS:
        DoBonus;
      GREED_NET_EVENT_TRIGGER:
        begin
          LDoor := FBuffer.ReadDoor;
          FHost.CheckHere(False, LDoor.X, LDoor.Y, LDoor.Angle);
        end;
      GREED_NET_EVENT_FRAG:
        DoFrag;
      GREED_NET_EVENT_NEW_PLAYER:
        SpawnNewPlayer;
      GREED_NET_EVENT_PAUSE:
        FPaused := True;
      GREED_NET_EVENT_UNPAUSE:
        FPaused := False;
      GREED_NET_EVENT_JAMMER:
        DoJammer;
      GREED_NET_EVENT_EVENT:
        FEvents.RunEvent(FBuffer.ReadFrag.BulletId, False);
      GREED_NET_EVENT_QUIT:
        FMessages.WriteMessage(Format(SLeftGame, [NameOf(LPlayer)]));
      GREED_NET_EVENT_MESSAGE:
        DoMessage;
    end;
  until False;
end;

procedure TGreedNetSession.FillPlayerEvent(var AEvent: TGreedPlayerEvent; AEventId: Integer);
begin
  AEvent.PlayerId := FPlayerNum;
  AEvent.Id := AEventId;
  AEvent.X := FState.Player.X;
  AEvent.Y := FState.Player.Y;
  AEvent.Z := FState.Player.Z;
  AEvent.Angle := FState.Player.Angle;
  AEvent.Angst := FState.Player.Angst;
  AEvent.Height := FState.Player.Height;
  AEvent.CharType := FState.Player.CharType;
  AEvent.Status := FState.Player.Status;
  AEvent.HoloPic := FState.Player.HoloPic;
end;

procedure TGreedNetSession.SendPlayerData;
var
  LEvent: TGreedPlayerEvent;
begin
  LEvent := FBuffer.ReadPlayer;
  FillPlayerEvent(LEvent, GREED_NET_EVENT_PLAYER);
  LEvent.HoloScale := FState.Player.HoloScale;
  LEvent.SpecialEffect := FState.SpecialEffect;
  FState.Player.Status := 0;
  FPlayerData[FPlayerNum] := LEvent;
  FBuffer.WritePlayer(LEvent);
  Send(SizeOf(TGreedPlayerEvent));
end;

procedure TGreedNetSession.NewPlayerData;
var
  LEvent: TGreedPlayerEvent;
begin
  // as the original: holoscale is not set here and travels with what the buffer had there
  LEvent := FBuffer.ReadPlayer;
  FillPlayerEvent(LEvent, GREED_NET_EVENT_NEW_PLAYER);
  LEvent.SpecialEffect := FState.SpecialEffect;
  FState.Player.Status := 0;
  FPlayerData[FPlayerNum] := LEvent;
  FBuffer.WritePlayer(LEvent);
  Send(SizeOf(TGreedPlayerEvent));
end;

procedure TGreedNetSession.SendSpawn(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer);
var
  LEvent: TGreedNetSpawnEvent;
begin
  LEvent.Id := GREED_NET_EVENT_SPAWN;
  LEvent.Value := AValue;
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Z := AZ;
  LEvent.ZAdjust := AZAdjust;
  LEvent.Angle := AAngle;
  LEvent.Angle2 := AAngle2;
  LEvent.Active := Ord(AActive);
  LEvent.SpawnId := ASpawnId;
  LEvent.PlayerId := FPlayerNum;
  FBuffer.WriteSpawn(LEvent);
  Send(SizeOf(TGreedNetSpawnEvent));
end;

procedure TGreedNetSession.SendPlayerOnly(AEventId: Integer);
var
  LEvent: TGreedNetPlayerOnlyEvent;
begin
  LEvent.Id := AEventId;
  LEvent.PlayerId := FPlayerNum;
  FBuffer.WritePlayerOnly(LEvent);
  Send(SizeOf(TGreedNetPlayerOnlyEvent));
end;

procedure TGreedNetSession.QuitGame;
begin
  Death(GREED_NET_NO_KILLER);
  SendPlayerOnly(GREED_NET_EVENT_QUIT);
end;

procedure TGreedNetSession.OpenDoor(AX, AY: TGreedFixed);
var
  LEvent: TGreedNetDoorEvent;
begin
  // as the original: the angle is not set and travels with what the buffer had there
  LEvent := FBuffer.ReadDoor;
  LEvent.Id := GREED_NET_EVENT_DOOR;
  LEvent.PlayerId := FPlayerNum;
  LEvent.X := AX;
  LEvent.Y := AY;
  FBuffer.WriteDoor(LEvent);
  Send(SizeOf(TGreedNetDoorEvent));
end;

procedure TGreedNetSession.Death(ABulletId: Integer);
var
  LEvent: TGreedNetFragEvent;
begin
  LEvent.Id := GREED_NET_EVENT_FRAG;
  LEvent.PlayerId := FPlayerNum;
  LEvent.BulletId := ABulletId;
  FBuffer.WriteFrag(LEvent);
  if IsPlayer(ABulletId) then
  begin
    FHost.RefreshGoalItem;
    Inc(FFragCount[ABulletId]);
    FState.GoalItem := ABulletId + 1;
    FMessages.WriteMessage(Format(SFraggedBy, [NameOf(ABulletId)]));
  end;
  Send(SizeOf(TGreedNetFragEvent));
end;

procedure TGreedNetSession.ItemPickup(ATileX, ATileY: Integer);
var
  LEvent: TGreedNetItemEvent;
begin
  LEvent.Id := GREED_NET_EVENT_ITEM;
  LEvent.PlayerId := FPlayerNum;
  LEvent.TileX := ATileX;
  LEvent.TileY := ATileY;
  LEvent.MapSpot := ATileY * GREED_MAP_SIZE + ATileX;
  LEvent.Kind := MapSprite(LEvent.MapSpot);
  LEvent.CharType := FState.Player.CharType;
  FBuffer.WriteItem(LEvent);
  Send(SizeOf(TGreedNetItemEvent));
end;

procedure TGreedNetSession.BonusItem;
var
  LEvent: TGreedNetBonusEvent;
begin
  LEvent.Id := GREED_NET_EVENT_BONUS;
  LEvent.PlayerId := FPlayerNum;
  LEvent.Time := FState.BonusItem.Time;
  LEvent.Score := FState.BonusItem.Score;
  LEvent.TileX := FState.BonusItem.TileX;
  LEvent.TileY := FState.BonusItem.TileY;
  LEvent.Num := FState.BonusItem.Num;
  FBuffer.WriteBonus(LEvent);
  Send(SizeOf(TGreedNetBonusEvent));
end;

procedure TGreedNetSession.GetClosestPlayer(ATileX, ATileY: Integer);
var
  LMinDistance, LMinPlayer, LDistance, LIndex, LPlayerX, LPlayerY: Integer;
begin
  LMinPlayer := -1;
  LMinDistance := MaxInt;
  for LIndex := 0 to FConfig.NumPlayers - 1 do
    // gotta be alive and visible
    if (FPlayerData[LIndex].Angst <> 0) and (FPlayerData[LIndex].SpecialEffect <> GREED_SE_INVISIBILITY) then
    begin
      LPlayerX := FPlayerData[LIndex].X div GREED_FRACTILEUNIT;
      LPlayerY := FPlayerData[LIndex].Y div GREED_FRACTILEUNIT;
      LDistance := (LPlayerX - ATileX) * (LPlayerX - ATileX) + (LPlayerY - ATileY) * (LPlayerY - ATileY);
      if LDistance < LMinDistance then
      begin
        LMinDistance := LDistance;
        LMinPlayer := LIndex;
      end;
    end;
  if LMinPlayer < 0 then
    Exit;
  FState.TargX := FPlayerData[LMinPlayer].X;
  FState.TargY := FPlayerData[LMinPlayer].Y;
  FState.TargZ := FPlayerData[LMinPlayer].Z;
end;

procedure TGreedNetSession.Pause;
begin
  SendPlayerOnly(GREED_NET_EVENT_PAUSE);
end;

procedure TGreedNetSession.UnPause;
begin
  SendPlayerOnly(GREED_NET_EVENT_UNPAUSE);
end;

procedure TGreedNetSession.CheckHere(ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
var
  LEvent: TGreedNetDoorEvent;
begin
  LEvent.Id := GREED_NET_EVENT_TRIGGER;
  LEvent.PlayerId := FPlayerNum;
  LEvent.X := ACenterX;
  LEvent.Y := ACenterY;
  LEvent.Angle := AAngle;
  FBuffer.WriteDoor(LEvent);
  Send(SizeOf(TGreedNetDoorEvent));
end;

procedure TGreedNetSession.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
var
  LEvent: TGreedNetSoundEvent;
begin
  LEvent.Id := GREED_NET_EVENT_SOUND;
  LEvent.PlayerId := FPlayerNum;
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Variation := AVariation;
  LEvent.Effect := ASound;
  FBuffer.WriteSound(LEvent);
  Send(SizeOf(TGreedNetSoundEvent));
end;

procedure TGreedNetSession.WarpJam;
begin
  SendPlayerOnly(GREED_NET_EVENT_JAMMER);
end;

procedure TGreedNetSession.Event(ANumber: Integer);
var
  LEvent: TGreedNetFragEvent;
begin
  LEvent.Id := GREED_NET_EVENT_EVENT;
  LEvent.PlayerId := FPlayerNum;
  LEvent.BulletId := ANumber;
  FBuffer.WriteFrag(LEvent);
  Send(SizeOf(TGreedNetFragEvent));
end;

procedure TGreedNetSession.SendMessage(const AText: AnsiString);
var
  LEvent: TGreedNetMessageEvent;
  LIndex: Integer;
begin
  // strcpy(mevent.message, s): the text and its zero; what follows stays as the buffer had it
  LEvent := FBuffer.ReadMessage;
  LEvent.Id := GREED_NET_EVENT_MESSAGE;
  LEvent.PlayerId := FPlayerNum;
  LIndex := 0;
  while (LIndex < GREED_NET_TEXT_SIZE) and (LIndex < Length(AText)) and (AText[LIndex + 1] <> #0) do
  begin
    LEvent.Text[LIndex] := AText[LIndex + 1];
    Inc(LIndex);
  end;
  if LIndex < GREED_NET_TEXT_SIZE then
    LEvent.Text[LIndex] := #0;
  FBuffer.WriteMessage(LEvent);
  Send(SizeOf(TGreedNetMessageEvent));
end;

function TGreedNetSession.GetNumPlayers: Integer;
begin
  Result := FConfig.NumPlayers;
end;

function TGreedNetSession.GetConsolePlayer: Integer;
begin
  Result := FConfig.ConsolePlayer;
end;

function TGreedNetSession.NetType: Integer;
begin
  Result := FConfig.NetType;
end;

function TGreedNetSession.GetPaused: Boolean;
begin
  Result := FPaused;
end;

function TGreedNetSession.GetWarpJammer: Boolean;
begin
  Result := FWarpJammer;
end;

function TGreedNetSession.GetWarpJamTime: Integer;
begin
  Result := FWarpJamTime;
end;

function TGreedNetSession.GetPlayerData(APlayer: Integer): TGreedPlayerEvent;
begin
  if not IsPlayer(APlayer) then
    raise EArgumentOutOfRangeException.Create('APlayer');
  Result := FPlayerData[APlayer];
end;

function TGreedNetSession.GetFragCount(APlayer: Integer): Integer;
begin
  if not IsPlayer(APlayer) then
    raise EArgumentOutOfRangeException.Create('APlayer');
  Result := FFragCount[APlayer];
end;

function TGreedNetSession.GetNetName(APlayer: Integer): AnsiString;
var
  LLength: Integer;
begin
  if not IsPlayer(APlayer) then
    raise EArgumentOutOfRangeException.Create('APlayer');
  LLength := 0;
  while (LLength < GREED_NET_NAME_SIZE) and (FNetNames[APlayer][LLength] <> #0) do
    Inc(LLength);
  SetString(Result, PAnsiChar(@FNetNames[APlayer][0]), LLength);
end;

function TGreedNetSession.PlayerSprite(APlayer: Integer): Integer;
begin
  if not IsPlayer(APlayer) then
    raise EArgumentOutOfRangeException.Create('APlayer');
  Result := FPlayerSprites[APlayer];
end;

function TGreedNetSession.PlayerMapSpot(APlayer: Integer): Integer;
begin
  if not IsPlayer(APlayer) then
    raise EArgumentOutOfRangeException.Create('APlayer');
  Result := FPlayerMapSpot[APlayer];
end;

end.
