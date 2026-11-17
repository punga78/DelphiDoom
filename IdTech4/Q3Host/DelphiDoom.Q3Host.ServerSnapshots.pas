{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the snapshots the server sends to its   }
{  clients                                                                      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_snapshot.c    }
{  (SV_BuildClientSnapshot, SV_AddEntitiesVisibleFromPoint,                     }
{  SV_EmitPacketEntities, SV_WriteSnapshotToClient, SV_SendClientSnapshot,      }
{  SV_UpdateServerCommandsToClient), sv_client.c (SV_SendClientGameState),      }
{  sv_init.c (SV_CreateBaseline, SV_SetConfigstring) and sv_main.c              }
{  (SV_AddServerCommand, SV_SendServerCommand). Copyright (C) 1999-2005 Id      }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ServerSnapshots;

// Overflow and range checks are off: the counters of the C are 32 bit integers.

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message,
  DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec, DelphiDoom.Q3Host.Services.Intf,
  DelphiDoom.Q3Host.GameWorld;

type
  /// <summary>The state of a client slot of the server (clientState_t: CS_FREE, CS_CONNECTED, CS_PRIMED, CS_ACTIVE)</summary>
  TQ3ServerClientPhase = (Free, Connected, Primed, Active);

  /// <summary>
  ///   The part of the server that talks to the clients, without the network: the server commands of each client
  ///   (the reliable commands, acknowledged by the client), the gamestate message, the baselines and the snapshot
  ///   of every frame with the delta compression against the one the client acknowledged. A message comes out as
  ///   the bytes the client parser reads (<c>TQ3ServerMessageParser.ParseMessage</c>: the acknowledge of the
  ///   client commands, the commands, then gamestate or snapshot and svc_EOF), with the number the netchan would
  ///   have given it. The entities and the player state come from the data the game located
  ///   (<c>TQ3GameWorld</c>), the visibility from the clipmap (PVS and areas). Implements
  ///   <c>IQ3HostServerCommands</c>: it is what <c>trap_SendServerCommand</c> reaches. Differences from the C:
  ///   the entity states of a frame are kept with the frame (no <c>svs.snapshotEntities</c> ring, so the "entities
  ///   rolled off" check is gone), no rate, fragmentation or packet padding, and SVF_NOSERVERINFO is not looked
  ///   at when a configstring is sent
  /// </summary>
  TQ3ServerSnapshots = class(TInterfacedObject, IQ3HostServerCommands)
  strict private
    const
      MAX_CLIENTS = 64;
      MAX_GENTITIES = 1024;
      MAX_CONFIGSTRINGS = 1024;
      SVF_NOCLIENT = 1;
      SVF_CLIENTMASK = 2;
      SVF_BROADCAST = $20;
      SVF_PORTAL = $40;
      SVF_SINGLECLIENT = $100;
      SVF_NOTSINGLECLIENT = $800;
      SNAPFLAG_NOT_ACTIVE = 2;
      MAX_STRING_CHARS = 1024;
      MAX_SNAPSHOT_ENTITIES = 1024;
      MAX_MSGLEN = 16384;
      OLD_NUMBER_NONE = 9999;
    type
      TFrame = record
        AreaBytes: Integer;
        AreaBits: array[0..Q3_MAX_MAP_AREA_BYTES - 1] of Byte;
        PlayerState: TQ3PlayerState;
        Entities: TArray<TQ3EntityState>;
      end;
      PFrame = ^TFrame;
      TClient = record
        Phase: TQ3ServerClientPhase;
        ReliableSequence, ReliableAcknowledge, LastClientCommand: Integer;
        OutgoingSequence, DeltaMessage, MessageAcknowledge: Integer;
        Commands: array[0..Q3_MAX_RELIABLE_COMMANDS - 1] of AnsiString;
        Frames: array[0..Q3_PACKET_BACKUP - 1] of TFrame;
        DropReason: string;
      end;
    var
      FWorld: TQ3GameWorld;
      FClipMap: IQ3HostClipMap;
      FState: IQ3HostServerState;
      FCoder: IQ3HuffmanCoder;
      FEntityCodec: TQ3EntityStateCodec;
      FPlayerCodec: TQ3PlayerStateCodec;
      FClients: array[0..MAX_CLIENTS - 1] of TClient;
      FBaselines: array[0..MAX_GENTITIES - 1] of TQ3EntityState;
      FSnapshotMarks: array[0..MAX_GENTITIES - 1] of Integer;
      FSnapshotCounter: Integer;
      FAreaWork: TBytes;
      FTime: Integer;
      FChecksumFeed: Integer;
      FRunning: Boolean;
    procedure CheckClient(AClient: Integer);
    function NewMessage: TQ3Message;
    function Finish(AMessage: TQ3Message): TBytes;
    procedure AddCommand(AClient: Integer; const AText: AnsiString);
    procedure WriteCommands(var AClient: TClient; AMessage: TQ3Message);
    procedure AddVisible(const AMemory: IQvmMemory; const AOrigin: array of Single; AClient: Integer;
      var AFrame: TFrame; var ANumbers: TArray<Integer>);
    procedure BuildSnapshot(const AMemory: IQvmMemory; AClient: Integer);
    procedure EmitPacketEntities(AFrom, ATo: PFrame; AMessage: TQ3Message);
  public
    /// <summary>The world is not owned; the clipmap and the server state are shared with the host of the game</summary>
    constructor Create(const AWorld: TQ3GameWorld; const AClipMap: IQ3HostClipMap;
      const AState: IQ3HostServerState);
    destructor Destroy; override;
    /// <summary>SV_CreateBaseline: the linked entities as they are now, from entity 1 up</summary>
    procedure CreateBaselines(const AMemory: IQvmMemory);
    /// <summary>svs.time: the time the snapshots carry</summary>
    procedure SetTime(ATime: Integer);
    /// <summary>The server is in the game state (sv.state SS_GAME): from now on a configstring change is sent</summary>
    procedure StartGame;
    /// <summary>
    ///   SV_SetConfigstring when the game runs: "cs index text" (or the bcs0/1/2 chunks of a long one) for every
    ///   client that is primed or active
    /// </summary>
    procedure ConfigstringChanged(AIndex: Integer; const AValue: AnsiString);
    /// <summary>SV_DirectConnect, the part that sets the slot: CS_CONNECTED, the netchan sequence starts at 1</summary>
    procedure ConnectClient(AClient: Integer);
    /// <summary>
    ///   SV_SendClientGameState: the slot is primed and the message has the unsent commands, the configstrings,
    ///   the baselines, the client number and the checksum feed. AMessageNumber is the sequence of the message
    /// </summary>
    function WriteGamestate(AClient: Integer; out AMessageNumber: Integer): TBytes;
    /// <summary>SV_ClientEnterWorld, the part that sets the slot: CS_ACTIVE, no delta until the client says so</summary>
    procedure ClientBegin(AClient: Integer);
    /// <summary>
    ///   SV_SendClientSnapshot: builds the snapshot of the frame, writes it (delta compressed from the message
    ///   the client acknowledged) and counts the message. The data of the game are read from AMemory
    /// </summary>
    function WriteSnapshot(const AMemory: IQvmMemory; AClient: Integer; out AMessageNumber: Integer): TBytes;
    /// <summary>
    ///   What the client tells the server in its next packet (SV_ExecuteClientMessage, SV_UserMove): the last
    ///   message it got, the last server command, and whether it can take a delta (clc_move, not clc_moveNoDelta)
    /// </summary>
    procedure Acknowledge(AClient, AMessageNumber, AServerCommandSequence: Integer; ADelta: Boolean);
    /// <summary>clc.reliableSequence of the client: the next message tells it (client->lastClientCommand)</summary>
    procedure SetLastClientCommand(AClient, ASequence: Integer);
    function Phase(AClient: Integer): TQ3ServerClientPhase;
    /// <summary>client->reliableSequence: the commands sent to a client so far</summary>
    function ReliableSequence(AClient: Integer): Integer;
    { IQ3HostServerCommands }
    /// <summary>SV_SendServerCommand: -1 is every client that is primed or active</summary>
    procedure Send(AClient: Integer; const AText: AnsiString);
    /// <summary>SV_DropClient, the part that matters here: the slot is free and the reason is kept</summary>
    procedure Drop(AClient: Integer; const AReason: AnsiString);
    function DropReason(AClient: Integer): string;
    property Time: Integer read FTime;
    property ChecksumFeed: Integer read FChecksumFeed write FChecksumFeed;
  end;

implementation

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Net.Q3.Factory,
  DelphiDoom.Q3Host.Types;

resourcestring
  SBadClientNumber = 'SV: bad client number %d';
  SBadEntity = 'SV_SvEntityForGentity: bad gEnt';
  SDuplicatedEntity = 'SV_QsortEntityStates: duplicated entity';
  SClientMaskTooBig = 'SVF_CLIENTMASK: cientNum > 32';
  SClientNotInGame = 'SV_SendClientSnapshot: client %d has no game entity';
  SServerCommandOverflow = 'Server command overflow';
  SMessageOverflow = 'The message of the server overflowed';
  SNoMap = 'The server has no map';

{ TQ3ServerSnapshots }

constructor TQ3ServerSnapshots.Create(const AWorld: TQ3GameWorld; const AClipMap: IQ3HostClipMap;
  const AState: IQ3HostServerState);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  FWorld := AWorld;
  FClipMap := AClipMap;
  FState := AState;
  FCoder := TQ3NetFactory.CreateMessageHuffman;
  FEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  FPlayerCodec := TQ3NetFactory.CreatePlayerStateCodec;
  for LIndex := 0 to MAX_CLIENTS - 1 do
    FClients[LIndex].DeltaMessage := -1;
end;

destructor TQ3ServerSnapshots.Destroy;
begin
  FEntityCodec.Free;
  FPlayerCodec.Free;
  inherited Destroy;
end;

procedure TQ3ServerSnapshots.CheckClient(AClient: Integer);
begin
  if (AClient < 0) or (AClient >= Min(MAX_CLIENTS, FState.MaxClients)) then
    raise EQ3HostException.CreateFmt(SBadClientNumber, [AClient]);
end;

function TQ3ServerSnapshots.NewMessage: TQ3Message;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, MAX_MSGLEN);
  Result := TQ3NetFactory.CreateMessage(FCoder);
  Result.Init(LBuffer, MAX_MSGLEN);
  Result.AllowOverflow := True;
end;

function TQ3ServerSnapshots.Finish(AMessage: TQ3Message): TBytes;
begin
  // SV_Netchan_Transmit: every message ends with svc_EOF
  AMessage.WriteByte(Q3_SVC_EOF);
  if AMessage.Overflowed then
    raise EQ3HostException.Create(SMessageOverflow);
  Result := Copy(AMessage.Data, 0, AMessage.CurSize);
end;

procedure TQ3ServerSnapshots.SetTime(ATime: Integer);
begin
  FTime := ATime;
end;

procedure TQ3ServerSnapshots.StartGame;
begin
  FRunning := True;
end;

procedure TQ3ServerSnapshots.CreateBaselines(const AMemory: IQvmMemory);
var
  LNumber, LAddress: Integer;
  LEntity: PQ3EntityState;
begin
  for LNumber := 1 to FWorld.EntityCount - 1 do
  begin
    LAddress := FWorld.EntityAddressOf(LNumber);
    if AMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_LINKED) = 0 then
      Continue;
    LEntity := PQ3EntityState(AMemory.Range(LAddress, SizeOf(TQ3EntityState)));
    LEntity^.Number := LNumber;
    FBaselines[LNumber] := LEntity^;
  end;
end;

procedure TQ3ServerSnapshots.AddCommand(AClient: Integer; const AText: AnsiString);
var
  LClient: ^TClient;
  LIndex: Integer;
begin
  LClient := @FClients[AClient];
  Inc(LClient.ReliableSequence);
  // we check == instead of >= so a broadcast print added by the drop does not drop again
  if LClient.ReliableSequence - LClient.ReliableAcknowledge = Q3_MAX_RELIABLE_COMMANDS + 1 then
  begin
    Drop(AClient, AnsiString(SServerCommandOverflow));
    Exit;
  end;
  LIndex := LClient.ReliableSequence and (Q3_MAX_RELIABLE_COMMANDS - 1);
  LClient.Commands[LIndex] := Copy(AText, 1, MAX_STRING_CHARS - 1);
end;

procedure TQ3ServerSnapshots.Send(AClient: Integer; const AText: AnsiString);
var
  LIndex: Integer;
begin
  if AClient >= 0 then
  begin
    CheckClient(AClient);
    AddCommand(AClient, AText);
    Exit;
  end;
  // the data goes to all the clients that are primed or active
  for LIndex := 0 to Min(MAX_CLIENTS, FState.MaxClients) - 1 do
    if FClients[LIndex].Phase >= TQ3ServerClientPhase.Primed then
      AddCommand(LIndex, AText);
end;

procedure TQ3ServerSnapshots.Drop(AClient: Integer; const AReason: AnsiString);
begin
  CheckClient(AClient);
  FClients[AClient].Phase := TQ3ServerClientPhase.Free;
  FClients[AClient].DropReason := string(AReason);
end;

function TQ3ServerSnapshots.DropReason(AClient: Integer): string;
begin
  CheckClient(AClient);
  Result := FClients[AClient].DropReason;
end;

procedure TQ3ServerSnapshots.ConfigstringChanged(AIndex: Integer; const AValue: AnsiString);
const
  CHUNK = MAX_STRING_CHARS - 24;
var
  LClient, LSent, LRemaining: Integer;
  LCommand: AnsiString;
begin
  // while the server spawns the clients get the strings with the gamestate
  if not FRunning then
    Exit;
  for LClient := 0 to Min(MAX_CLIENTS, FState.MaxClients) - 1 do
  begin
    if FClients[LClient].Phase < TQ3ServerClientPhase.Primed then
      Continue;
    if Length(AValue) >= CHUNK then
    begin
      LSent := 0;
      LRemaining := Length(AValue);
      while LRemaining > 0 do
      begin
        if LSent = 0 then
          LCommand := 'bcs0'
        else if LRemaining < CHUNK then
          LCommand := 'bcs2'
        else
          LCommand := 'bcs1';
        // Q_strncpyz( buf, &val[sent], maxChunkSize ): at most maxChunkSize - 1 characters
        AddCommand(LClient, AnsiString(Format('%s %d "%s"'#10, [string(LCommand), AIndex,
          string(Copy(AValue, LSent + 1, CHUNK - 1))])));
        Inc(LSent, CHUNK - 1);
        Dec(LRemaining, CHUNK - 1);
      end;
    end
    else
      AddCommand(LClient, AnsiString(Format('cs %d "%s"'#10, [AIndex, string(AValue)])));
  end;
end;

procedure TQ3ServerSnapshots.ConnectClient(AClient: Integer);
begin
  CheckClient(AClient);
  FClients[AClient] := Default(TClient);
  FClients[AClient].Phase := TQ3ServerClientPhase.Connected;
  // Netchan_Setup: the first packet is the number 1
  FClients[AClient].OutgoingSequence := 1;
  FClients[AClient].DeltaMessage := -1;
end;

procedure TQ3ServerSnapshots.WriteCommands(var AClient: TClient; AMessage: TQ3Message);
var
  LIndex: Integer;
begin
  // write any unacknowledged serverCommands
  for LIndex := AClient.ReliableAcknowledge + 1 to AClient.ReliableSequence do
  begin
    AMessage.WriteByte(Q3_SVC_SERVERCOMMAND);
    AMessage.WriteLong(LIndex);
    AMessage.WriteString(AClient.Commands[LIndex and (Q3_MAX_RELIABLE_COMMANDS - 1)]);
  end;
end;

function TQ3ServerSnapshots.WriteGamestate(AClient: Integer; out AMessageNumber: Integer): TBytes;
var
  LMessage: TQ3Message;
  LNull: TQ3EntityState;
  LIndex: Integer;
  LText: AnsiString;
begin
  CheckClient(AClient);
  FClients[AClient].Phase := TQ3ServerClientPhase.Primed;
  LMessage := NewMessage;
  try
    // all server to client messages acknowledge the client commands received
    LMessage.WriteLong(FClients[AClient].LastClientCommand);
    // the gamestate sets clc.serverCommandSequence: the commands waiting go first
    WriteCommands(FClients[AClient], LMessage);
    LMessage.WriteByte(Q3_SVC_GAMESTATE);
    LMessage.WriteLong(FClients[AClient].ReliableSequence);
    for LIndex := 0 to MAX_CONFIGSTRINGS - 1 do
    begin
      LText := FState.GetConfigstring(LIndex);
      if LText <> '' then
      begin
        LMessage.WriteByte(Q3_SVC_CONFIGSTRING);
        LMessage.WriteShort(LIndex);
        LMessage.WriteBigString(LText);
      end;
    end;
    LNull := Default(TQ3EntityState);
    for LIndex := 0 to MAX_GENTITIES - 1 do
    begin
      if FBaselines[LIndex].Number = 0 then
        Continue;
      LMessage.WriteByte(Q3_SVC_BASELINE);
      FEntityCodec.WriteDelta(LMessage, @LNull, @FBaselines[LIndex], True);
    end;
    LMessage.WriteByte(Q3_SVC_EOF);
    LMessage.WriteLong(AClient);
    LMessage.WriteLong(FChecksumFeed);
    Result := Finish(LMessage);
  finally
    LMessage.Free;
  end;
  AMessageNumber := FClients[AClient].OutgoingSequence;
  Inc(FClients[AClient].OutgoingSequence);
end;

procedure TQ3ServerSnapshots.ClientBegin(AClient: Integer);
begin
  CheckClient(AClient);
  FClients[AClient].Phase := TQ3ServerClientPhase.Active;
  FClients[AClient].DeltaMessage := -1;
end;

procedure TQ3ServerSnapshots.Acknowledge(AClient, AMessageNumber, AServerCommandSequence: Integer;
  ADelta: Boolean);
begin
  CheckClient(AClient);
  FClients[AClient].MessageAcknowledge := AMessageNumber;
  FClients[AClient].ReliableAcknowledge := AServerCommandSequence;
  if ADelta and (FClients[AClient].Phase = TQ3ServerClientPhase.Active) then
    FClients[AClient].DeltaMessage := AMessageNumber
  else
    FClients[AClient].DeltaMessage := -1;
end;

procedure TQ3ServerSnapshots.SetLastClientCommand(AClient, ASequence: Integer);
begin
  CheckClient(AClient);
  FClients[AClient].LastClientCommand := ASequence;
end;

function TQ3ServerSnapshots.Phase(AClient: Integer): TQ3ServerClientPhase;
begin
  CheckClient(AClient);
  Result := FClients[AClient].Phase;
end;

function TQ3ServerSnapshots.ReliableSequence(AClient: Integer): Integer;
begin
  CheckClient(AClient);
  Result := FClients[AClient].ReliableSequence;
end;

// SV_AddEntitiesVisibleFromPoint
procedure TQ3ServerSnapshots.AddVisible(const AMemory: IQvmMemory; const AOrigin: array of Single;
  AClient: Integer; var AFrame: TFrame; var ANumbers: TArray<Integer>);
var
  LModel: IQ3CollisionModel;
  LOrigin: TQ3Vec3;
  LLeaf, LArea, LCluster, LEntity, LIndex, LCluster2, LFlags, LSingle: Integer;
  LPvs: TBytes;
  LAddress: Integer;
  LState: PQ3EntityState;
  LSv: TQ3GameWorld.TSvEntity;
  LDeltaX, LDeltaY, LDeltaZ: Single;
  LPortalOrigin: TQ3Vec3;

  function Visible(ACluster: Integer): Boolean;
  begin
    // the C reads the row without a bound; a cluster outside of it is not visible here
    Result := (ACluster >= 0) and ((ACluster shr 3) < Length(LPvs))
      and ((LPvs[ACluster shr 3] and (1 shl (ACluster and 7))) <> 0);
  end;

  procedure AddEntity(ANumber: Integer);
  begin
    // if we have already added this entity to this snapshot, don't add again
    if FSnapshotMarks[ANumber] = FSnapshotCounter then
      Exit;
    FSnapshotMarks[ANumber] := FSnapshotCounter;
    // if we are full, silently discard entities
    if Length(ANumbers) >= MAX_SNAPSHOT_ENTITIES then
      Exit;
    SetLength(ANumbers, Length(ANumbers) + 1);
    ANumbers[High(ANumbers)] := ANumber;
  end;

begin
  LModel := FClipMap.Model;
  if not Assigned(LModel) then
    raise EQ3HostException.Create(SNoMap);
  LOrigin[0] := AOrigin[0];
  LOrigin[1] := AOrigin[1];
  LOrigin[2] := AOrigin[2];
  LLeaf := LModel.PointLeafnum(LOrigin);
  LArea := LModel.LeafArea(LLeaf);
  LCluster := LModel.LeafCluster(LLeaf);
  // calculate the visible areas
  AFrame.AreaBytes := LModel.WriteAreaBits(FAreaWork, LArea);
  LPvs := LModel.ClusterPVS(LCluster);
  for LEntity := 0 to FWorld.EntityCount - 1 do
  begin
    LAddress := FWorld.EntityAddressOf(LEntity);
    // never send entities that aren't linked in
    if AMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_LINKED) = 0 then
      Continue;
    LState := PQ3EntityState(AMemory.Range(LAddress, SizeOf(TQ3EntityState)));
    if LState^.Number <> LEntity then
      LState^.Number := LEntity;
    LFlags := AMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_SVFLAGS);
    LSingle := AMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_SINGLECLIENT);
    // entities can be flagged to explicitly not be sent to the client
    if (LFlags and SVF_NOCLIENT) <> 0 then
      Continue;
    if ((LFlags and SVF_SINGLECLIENT) <> 0) and (LSingle <> AFrame.PlayerState.ClientNum) then
      Continue;
    if ((LFlags and SVF_NOTSINGLECLIENT) <> 0) and (LSingle = AFrame.PlayerState.ClientNum) then
      Continue;
    if (LFlags and SVF_CLIENTMASK) <> 0 then
    begin
      if AFrame.PlayerState.ClientNum >= 32 then
        raise EQ3HostException.Create(SClientMaskTooBig);
      if ((not LSingle) and (1 shl AFrame.PlayerState.ClientNum)) <> 0 then
        Continue;
    end;
    // don't double add an entity through portals
    if FSnapshotMarks[LEntity] = FSnapshotCounter then
      Continue;
    // broadcast entities are always sent
    if (LFlags and SVF_BROADCAST) <> 0 then
    begin
      AddEntity(LEntity);
      Continue;
    end;
    // ignore if not touching a PV leaf: check area, doors can legally straddle two areas
    LSv := FWorld.SvEntity(LEntity);
    if not LModel.AreasConnected(LArea, LSv.AreaNum) then
      if not LModel.AreasConnected(LArea, LSv.AreaNum2) then
        Continue;
    // check individual leafs
    if LSv.NumClusters = 0 then
      Continue;
    LCluster2 := 0;
    LIndex := 0;
    while LIndex < LSv.NumClusters do
    begin
      LCluster2 := LSv.ClusterNums[LIndex];
      if Visible(LCluster2) then
        Break;
      Inc(LIndex);
    end;
    // if we haven't found it to be visible, check overflow clusters that couldn't be stored
    if LIndex = LSv.NumClusters then
    begin
      if LSv.LastCluster <> 0 then
      begin
        while LCluster2 <= LSv.LastCluster do
        begin
          if Visible(LCluster2) then
            Break;
          Inc(LCluster2);
        end;
        if LCluster2 = LSv.LastCluster then
          Continue;
      end
      else
        Continue;
    end;
    AddEntity(LEntity);
    // if its a portal entity, add everything visible from its camera position
    if (LFlags and SVF_PORTAL) <> 0 then
    begin
      if LState^.Generic1 <> 0 then
      begin
        LDeltaX := LState^.Origin[0] - LOrigin[0];
        LDeltaY := LState^.Origin[1] - LOrigin[1];
        LDeltaZ := LState^.Origin[2] - LOrigin[2];
        if LDeltaX * LDeltaX + LDeltaY * LDeltaY + LDeltaZ * LDeltaZ >
          Single(LState^.Generic1) * Single(LState^.Generic1) then
          Continue;
      end;
      LPortalOrigin[0] := LState^.Origin2[0];
      LPortalOrigin[1] := LState^.Origin2[1];
      LPortalOrigin[2] := LState^.Origin2[2];
      AddVisible(AMemory, LPortalOrigin, AClient, AFrame, ANumbers);
    end;
  end;
end;

// SV_BuildClientSnapshot
procedure TQ3ServerSnapshots.BuildSnapshot(const AMemory: IQvmMemory; AClient: Integer);
var
  LClient: ^TClient;
  LFrame: PFrame;
  LNumbers: TArray<Integer>;
  LBytes: TBytes;
  LOrigin: array[0..2] of Single;
  LIndex: Integer;
begin
  LClient := @FClients[AClient];
  if LClient.Phase = TQ3ServerClientPhase.Free then
    raise EQ3HostException.CreateFmt(SClientNotInGame, [AClient]);
  // bump the counter used to prevent double adding
  Inc(FSnapshotCounter);
  LFrame := @LClient.Frames[LClient.OutgoingSequence and (Q3_PACKET_BACKUP - 1)];
  LFrame^.AreaBytes := 0;
  FillChar(LFrame^.AreaBits, SizeOf(LFrame^.AreaBits), 0);
  LFrame^.Entities := nil;
  SetLength(FAreaWork, Max(Q3_MAX_MAP_AREA_BYTES, (FClipMap.Model.NumAreas + 7) div 8));
  FillChar(FAreaWork[0], Length(FAreaWork), 0);
  // grab the current playerState_t
  LBytes := AMemory.ReadBytes(FWorld.ClientAddressOf(AClient), SizeOf(TQ3PlayerState));
  Move(LBytes[0], LFrame^.PlayerState, SizeOf(TQ3PlayerState));
  // never send client's own entity, because it can be regenerated from the playerstate
  if (LFrame^.PlayerState.ClientNum < 0) or (LFrame^.PlayerState.ClientNum >= MAX_GENTITIES) then
    raise EQ3HostException.Create(SBadEntity);
  FSnapshotMarks[LFrame^.PlayerState.ClientNum] := FSnapshotCounter;
  // find the client's viewpoint
  LOrigin[0] := LFrame^.PlayerState.Origin[0];
  LOrigin[1] := LFrame^.PlayerState.Origin[1];
  LOrigin[2] := LFrame^.PlayerState.Origin[2] + LFrame^.PlayerState.ViewHeight;
  AddVisible(AMemory, LOrigin, AClient, LFrame^, LNumbers);
  // portals may leave entities out of order: sort, which also catches an entity included twice
  TArray.Sort<Integer>(LNumbers);
  for LIndex := 1 to High(LNumbers) do
    if LNumbers[LIndex] = LNumbers[LIndex - 1] then
      raise EQ3HostException.Create(SDuplicatedEntity);
  // now that all viewpoint's areabits have been OR'd together, invert them to make a mask vector
  for LIndex := 0 to Q3_MAX_MAP_AREA_BYTES - 1 do
    LFrame^.AreaBits[LIndex] := FAreaWork[LIndex] xor $FF;
  // copy the entity states out
  SetLength(LFrame^.Entities, Length(LNumbers));
  for LIndex := 0 to High(LNumbers) do
    LFrame^.Entities[LIndex] :=
      PQ3EntityState(AMemory.Range(FWorld.EntityAddressOf(LNumbers[LIndex]), SizeOf(TQ3EntityState)))^;
end;

// SV_EmitPacketEntities
procedure TQ3ServerSnapshots.EmitPacketEntities(AFrom, ATo: PFrame; AMessage: TQ3Message);
var
  LNewIndex, LOldIndex, LNewNumber, LOldNumber, LFromCount: Integer;
begin
  if Assigned(AFrom) then
    LFromCount := Length(AFrom^.Entities)
  else
    LFromCount := 0;
  LNewIndex := 0;
  LOldIndex := 0;
  while (LNewIndex < Length(ATo^.Entities)) or (LOldIndex < LFromCount) do
  begin
    if LNewIndex >= Length(ATo^.Entities) then
      LNewNumber := OLD_NUMBER_NONE
    else
      LNewNumber := ATo^.Entities[LNewIndex].Number;
    if LOldIndex >= LFromCount then
      LOldNumber := OLD_NUMBER_NONE
    else
      LOldNumber := AFrom^.Entities[LOldIndex].Number;
    if LNewNumber = LOldNumber then
    begin
      // delta update from old position: nothing is written when the entity did not change
      FEntityCodec.WriteDelta(AMessage, @AFrom^.Entities[LOldIndex], @ATo^.Entities[LNewIndex], False);
      Inc(LOldIndex);
      Inc(LNewIndex);
    end
    else if LNewNumber < LOldNumber then
    begin
      // this is a new entity, send it from the baseline
      FEntityCodec.WriteDelta(AMessage, @FBaselines[LNewNumber], @ATo^.Entities[LNewIndex], True);
      Inc(LNewIndex);
    end
    else
    begin
      // the old entity isn't present in the new message
      FEntityCodec.WriteDelta(AMessage, @AFrom^.Entities[LOldIndex], nil, True);
      Inc(LOldIndex);
    end;
  end;
  // end of packetentities
  AMessage.WriteBits(MAX_GENTITIES - 1, Q3_GENTITYNUM_BITS);
end;

// SV_SendClientSnapshot + SV_WriteSnapshotToClient
function TQ3ServerSnapshots.WriteSnapshot(const AMemory: IQvmMemory; AClient: Integer;
  out AMessageNumber: Integer): TBytes;
var
  LClient: ^TClient;
  LMessage: TQ3Message;
  LFrame, LOldFrame: PFrame;
  LLastFrame, LSnapFlags: Integer;
  LAreaBits: TBytes;
begin
  CheckClient(AClient);
  BuildSnapshot(AMemory, AClient);
  LClient := @FClients[AClient];
  LFrame := @LClient.Frames[LClient.OutgoingSequence and (Q3_PACKET_BACKUP - 1)];
  // try to use a previous frame as the source for delta compressing the snapshot
  LOldFrame := nil;
  LLastFrame := 0;
  if (LClient.DeltaMessage > 0) and (LClient.Phase = TQ3ServerClientPhase.Active)
    and (LClient.OutgoingSequence - LClient.DeltaMessage < Q3_PACKET_BACKUP - 3) then
  begin
    LOldFrame := @LClient.Frames[LClient.DeltaMessage and (Q3_PACKET_BACKUP - 1)];
    LLastFrame := LClient.OutgoingSequence - LClient.DeltaMessage;
  end;
  LMessage := NewMessage;
  try
    LMessage.WriteLong(LClient.LastClientCommand);
    WriteCommands(LClient^, LMessage);
    LMessage.WriteByte(Q3_SVC_SNAPSHOT);
    // send over the current server time so the client can drift its view of time
    LMessage.WriteLong(FTime);
    // what we are delta'ing from
    LMessage.WriteByte(LLastFrame);
    LSnapFlags := 0;
    if LClient.Phase <> TQ3ServerClientPhase.Active then
      LSnapFlags := LSnapFlags or SNAPFLAG_NOT_ACTIVE;
    LMessage.WriteByte(LSnapFlags);
    // send over the areabits
    LMessage.WriteByte(LFrame^.AreaBytes);
    SetLength(LAreaBits, LFrame^.AreaBytes);
    if LFrame^.AreaBytes > 0 then
      Move(LFrame^.AreaBits[0], LAreaBits[0], LFrame^.AreaBytes);
    LMessage.WriteData(LAreaBits, LFrame^.AreaBytes);
    // delta encode the playerstate
    if Assigned(LOldFrame) then
      FPlayerCodec.WriteDelta(LMessage, @LOldFrame^.PlayerState, @LFrame^.PlayerState)
    else
      FPlayerCodec.WriteDelta(LMessage, nil, @LFrame^.PlayerState);
    EmitPacketEntities(LOldFrame, LFrame, LMessage);
    Result := Finish(LMessage);
  finally
    LMessage.Free;
  end;
  AMessageNumber := LClient.OutgoingSequence;
  Inc(LClient.OutgoingSequence);
end;

end.
