{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the server on a network transport      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_main.c       }
{  (SV_PacketEvent, SV_ConnectionlessPacket, SVC_Status, SVC_Info),            }
{  sv_net_chan.c (SV_Netchan_Transmit, SV_Netchan_TransmitNextFragment,        }
{  SV_Netchan_Process), net_chan.c (NET_OutOfBandPrint). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ServerNetwork;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Net.Transport.Intf,
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.Netchan,
  DelphiDoom.Q3Host.Server.Intf, DelphiDoom.Q3Host.ServerSnapshots, DelphiDoom.Q3Host.Server;

type
  /// <summary>
  ///   Gives a <c>TQ3Server</c> a network: the datagrams that arrive on the transport (SV_PacketEvent: the
  ///   connectionless ones are answered, a sequenced one goes through the netchan of its client, is decoded and
  ///   reaches the server), and what the server sends (a netchan for each client slot, the xor encoding, the
  ///   fragments of the messages that are too long and the queue of the messages that wait for them). It is the
  ///   output of the server. Nothing here opens a socket: the transport is whatever the owner passes
  /// </summary>
  TQ3ServerNetwork = class(TInterfacedObject, IQ3ServerOutput)
  strict private
    const
      MAX_CLIENTS = 64;
    var
      FTransport: INetTransport;
      FNetTransport: IQ3NetTransport;
      FServer: TQ3Server;
      FArguments: IQ3CommandArguments;
      FCoder: IQ3HuffmanCoder;
      FLog: ILog;
      FLoopback: Boolean;
      FNetchans: array[0..MAX_CLIENTS - 1] of TQ3Netchan;
      FQueues: array[0..MAX_CLIENTS - 1] of TQueue<TBytes>;
    procedure SendDatagram(ANode: Integer; const AData: TBytes);
    procedure ConnectionlessPacket(ANode: Integer; const AFrom: TQ3NetAddress; AMessage: TQ3Message);
    procedure SequencedPacket(ANode: Integer; const AFrom: TQ3NetAddress; AMessage: TQ3Message);
    procedure TransmitEncoded(AClient: Integer; const AMessage: TBytes);
    procedure InfoResponse(const AFrom: TQ3NetAddress; AStatus: Boolean);
  public
    /// <summary>
    ///   The server, the transport and the coder are not owned. ALoopback: the nodes of the transport are on the
    ///   LAN (a wire in memory). The log gets what showpackets and showdrop would print (nil: silence)
    /// </summary>
    constructor Create(const AServer: TQ3Server; const ATransport: INetTransport; const AArguments: IQ3CommandArguments;
      const ACoder: IQ3HuffmanCoder; ALoopback: Boolean; const ALog: ILog = nil);
    destructor Destroy; override;
    /// <summary>The datagrams that are waiting on the transport, one after the other; the number of them</summary>
    function Poll: Integer;
    { IQ3ServerOutput }
    procedure SendMessage(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
    procedure SendOutOfBand(const AAddress: TQ3NetAddress; const AText: AnsiString);
    function HasUnsentFragments(AClient: Integer): Boolean;
    procedure TransmitNextFragment(AClient: Integer);
    /// <summary>The channel of a client slot (nil if the slot never had one)</summary>
    function Netchan(AClient: Integer): TQ3Netchan;
  end;

implementation

uses
  System.Classes, DelphiDoom.Net.Q3.Factory, DelphiDoom.Net.Q3.HuffmanCompressor,
  DelphiDoom.Net.Q3.InfoString, DelphiDoom.Net.Q3.PacketCrypt, DelphiDoom.Q3Host.NetTransportAdapter;

constructor TQ3ServerNetwork.Create(const AServer: TQ3Server; const ATransport: INetTransport;
  const AArguments: IQ3CommandArguments; const ACoder: IQ3HuffmanCoder; ALoopback: Boolean; const ALog: ILog);
begin
  inherited Create;
  FServer := AServer;
  FTransport := ATransport;
  FArguments := AArguments;
  FCoder := ACoder;
  FLoopback := ALoopback;
  FLog := ALog;
  FNetTransport := TQ3NetTransportAdapter.Create(ATransport);
end;

destructor TQ3ServerNetwork.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_CLIENTS - 1 do
  begin
    FNetchans[LIndex].Free;
    FQueues[LIndex].Free;
  end;
  inherited Destroy;
end;

procedure TQ3ServerNetwork.SendDatagram(ANode: Integer; const AData: TBytes);
begin
  FTransport.Send(ANode, AData);
end;

function TQ3ServerNetwork.Netchan(AClient: Integer): TQ3Netchan;
begin
  Result := FNetchans[AClient];
end;

// NET_OutOfBandPrint( NS_SERVER, adr, string )
procedure TQ3ServerNetwork.SendOutOfBand(const AAddress: TQ3NetAddress; const AText: AnsiString);
var
  LData: TBytes;
begin
  SetLength(LData, 4 + Length(AText));
  LData[0] := $FF;
  LData[1] := $FF;
  LData[2] := $FF;
  LData[3] := $FF;
  if Length(AText) > 0 then
    Move(AText[1], LData[4], Length(AText));
  SendDatagram(TQ3NodeAddresses.ToNode(AAddress), LData);
end;

// the connect command of a client that the server accepted gets its channel (Netchan_Setup in SV_DirectConnect)
procedure TQ3ServerNetwork.TransmitEncoded(AClient: Integer; const AMessage: TBytes);
var
  LMessage: TQ3Message;
  LBuffer: TBytes;
begin
  // SV_Netchan_Encode and Netchan_Transmit
  SetLength(LBuffer, Length(AMessage) + 4);
  if Length(AMessage) > 0 then
    Move(AMessage[0], LBuffer[0], Length(AMessage));
  LMessage := TQ3NetFactory.CreateMessage(FCoder);
  try
    LMessage.Init(LBuffer, Length(LBuffer));
    LMessage.CurSize := Length(AMessage);
    TQ3PacketCrypt.ServerEncode(LMessage, FServer.ClientChallenge(AClient), FNetchans[AClient].OutgoingSequence,
      FServer.ClientLastCommand(AClient));
    FNetchans[AClient].Transmit(LMessage.Data, LMessage.CurSize);
  finally
    LMessage.Free;
  end;
end;

procedure TQ3ServerNetwork.SendMessage(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
begin
  if not Assigned(FNetchans[AClient]) then
    Exit;
  if not Assigned(FQueues[AClient]) then
    FQueues[AClient] := TQueue<TBytes>.Create;
  if FNetchans[AClient].UnsentFragments then
  begin
    // the message is stored, the encoding depends on stuff we still have to finish sending
    FQueues[AClient].Enqueue(Copy(AMessage));
    FNetchans[AClient].TransmitNextFragment;
    Exit;
  end;
  TransmitEncoded(AClient, AMessage);
end;

function TQ3ServerNetwork.HasUnsentFragments(AClient: Integer): Boolean;
begin
  Result := Assigned(FNetchans[AClient]) and FNetchans[AClient].UnsentFragments;
end;

// SV_Netchan_TransmitNextFragment
procedure TQ3ServerNetwork.TransmitNextFragment(AClient: Integer);
begin
  if not Assigned(FNetchans[AClient]) then
    Exit;
  FNetchans[AClient].TransmitNextFragment;
  if not FNetchans[AClient].UnsentFragments and Assigned(FQueues[AClient]) and (FQueues[AClient].Count > 0) then
    // the last fragment was transmitted: a queued message goes now
    TransmitEncoded(AClient, FQueues[AClient].Dequeue);
end;

// SVC_Info and SVC_Status
procedure TQ3ServerNetwork.InfoResponse(const AFrom: TQ3NetAddress; AStatus: Boolean);
var
  LInfo, LText: AnsiString;
  LIndex, LCount: Integer;
begin
  if AStatus then
  begin
    LInfo := FServer.ServerState.GetConfigstring(0);
    LText := 'statusResponse'#10 + LInfo + #10;
    SendOutOfBand(AFrom, LText);
    Exit;
  end;
  LCount := 0;
  for LIndex := 0 to FServer.ServerState.MaxClients - 1 do
    if FServer.ClientPhase[LIndex] >= TQ3ServerClientPhase.Connected then
      Inc(LCount);
  LInfo := '';
  TQ3InfoString.SetValueForKey(LInfo, 'challenge', FArguments.Argv(1));
  TQ3InfoString.SetValueForKey(LInfo, 'protocol', AnsiString(IntToStr(FServer.Protocol)));
  TQ3InfoString.SetValueForKey(LInfo, 'mapname', FServer.MapName);
  TQ3InfoString.SetValueForKey(LInfo, 'clients', AnsiString(IntToStr(LCount)));
  TQ3InfoString.SetValueForKey(LInfo, 'sv_maxclients', AnsiString(IntToStr(FServer.ServerState.MaxClients)));
  SendOutOfBand(AFrom, 'infoResponse'#10 + LInfo);
end;

// SV_ConnectionlessPacket
procedure TQ3ServerNetwork.ConnectionlessPacket(ANode: Integer; const AFrom: TQ3NetAddress; AMessage: TQ3Message);
var
  LMessage: TQ3Message;
  LText, LName: AnsiString;
  LClient: Integer;
begin
  LMessage := AMessage;
  LMessage.BeginReadingOOB;
  // skip the -1 marker
  LMessage.ReadLong;
  if (LMessage.CurSize >= 11) and (Copy(string(PAnsiChar(@LMessage.Data[4])), 1, 7) = 'connect') then
    TQ3HuffmanCompressor.Decompress(LMessage, 12);
  LText := LMessage.ReadStringLine;
  FArguments.Tokenize(LText);
  LName := FArguments.Argv(0);
  if SameText(string(LName), 'getstatus') then
    InfoResponse(AFrom, True)
  else if SameText(string(LName), 'getinfo') then
    InfoResponse(AFrom, False)
  else if SameText(string(LName), 'getchallenge') then
    FServer.GetChallenge(AFrom)
  else if SameText(string(LName), 'connect') then
  begin
    LClient := FServer.DirectConnect(AFrom, FArguments.Argv(1));
    if LClient >= 0 then
    begin
      // Netchan_Setup( NS_SERVER, &newcl->netchan, from, qport )
      if not Assigned(FNetchans[LClient]) then
        FNetchans[LClient] := TQ3NetFactory.CreateNetchan(FNetTransport, FLog);
      FNetchans[LClient].Setup(nsServer, AFrom, FServer.ClientQPort(LClient));
      FreeAndNil(FQueues[LClient]);
    end;
  end;
  // "disconnect", "rcon" and the others: nothing (no remote console)
end;

// SV_PacketEvent for a datagram that is not connectionless
procedure TQ3ServerNetwork.SequencedPacket(ANode: Integer; const AFrom: TQ3NetAddress; AMessage: TQ3Message);
var
  LMessage: TQ3Message;
  LQPort, LIndex: Integer;
  LPayload: TBytes;
begin
  LMessage := AMessage;
  // read the qport out of the message so we can fix up stupid address translating routers
  LMessage.BeginReadingOOB;
  LMessage.ReadLong;
  LQPort := LMessage.ReadShort and $FFFF;
  for LIndex := 0 to FServer.ServerState.MaxClients - 1 do
  begin
    if (FServer.ClientPhase[LIndex] = TQ3ServerClientPhase.Free) or not Assigned(FNetchans[LIndex]) then
      Continue;
    if (FNetchans[LIndex].RemoteAddress.AddressType <> AFrom.AddressType) or
      (TQ3NodeAddresses.ToNode(FNetchans[LIndex].RemoteAddress) <> ANode) then
      Continue;
    // clients from a single address are told apart by their qport
    if FNetchans[LIndex].QPort <> LQPort then
      Continue;
    // make sure it is a valid, in sequence packet
    if FNetchans[LIndex].Process(LMessage) then
    begin
      TQ3PacketCrypt.ServerDecode(LMessage, FServer.ClientChallenge(LIndex),
        function(ASequence: Integer): AnsiString
        begin
          Result := FServer.Snapshots.ServerCommand(LIndex, ASequence);
        end);
      // zombie clients still need to do the Netchan_Process, but they do nothing else
      if FServer.ClientPhase[LIndex] <> TQ3ServerClientPhase.Zombie then
      begin
        LPayload := Copy(LMessage.Data, LMessage.ReadCount, LMessage.CurSize - LMessage.ReadCount);
        FServer.ExecuteClientMessage(LIndex, LPayload, Length(LPayload));
      end;
    end;
    Exit;
  end;
  // a sequenced packet from an address we don't recognize: tell it to go away
  SendOutOfBand(AFrom, 'disconnect');
end;

function TQ3ServerNetwork.Poll: Integer;
var
  LNode: Integer;
  LData, LBuffer: TBytes;
  LMessage: TQ3Message;
  LFrom: TQ3NetAddress;
begin
  Result := 0;
  while FTransport.Receive(LNode, LData) do
  begin
    Inc(Result);
    LFrom := TQ3NodeAddresses.FromNode(LNode, FLoopback);
    // a buffer that can take a message put together from fragments (4 bytes for the sequence number)
    SetLength(LBuffer, Q3_MAX_MSGLEN + 4);
    if Length(LData) > Length(LBuffer) then
      Continue;
    if Length(LData) > 0 then
      Move(LData[0], LBuffer[0], Length(LData));
    LMessage := TQ3NetFactory.CreateMessage(FCoder);
    try
      LMessage.Init(LBuffer, Length(LBuffer));
      LMessage.CurSize := Length(LData);
      // check for connectionless packet (0xffffffff) first
      if (Length(LData) >= 4) and (LData[0] = $FF) and (LData[1] = $FF) and (LData[2] = $FF) and (LData[3] = $FF) then
        ConnectionlessPacket(LNode, LFrom, LMessage)
      else if Length(LData) >= 6 then
        SequencedPacket(LNode, LFrom, LMessage);
    finally
      LMessage.Free;
    end;
  end;
end;

end.
