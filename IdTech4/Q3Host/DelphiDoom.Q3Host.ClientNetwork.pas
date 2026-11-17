{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the client on a network transport      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_main.c       }
{  (CL_Connect_f, CL_CheckForResend, CL_ConnectionlessPacket,                  }
{  CL_PacketEvent), cl_net_chan.c (CL_Netchan_Transmit, CL_Netchan_Process),   }
{  cl_input.c (CL_WritePacket), net_chan.c (NET_OutOfBandPrint,                }
{  NET_OutOfBandData). Copyright (C) 1999-2005 Id Software, Inc. This unit     }
{  is derived from the Quake III Arena source code and is therefore            }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientNetwork;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Net.Transport.Intf, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.Netchan,
  DelphiDoom.Net.Q3.ServerMessageParser,
  DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientPacketWriter;

type
  /// <summary>connstate_t of the connection (the ones the network part of the client goes through)</summary>
  TQ3ClientConnection = (Disconnected, Connecting, Challenging, Connected);

  /// <summary>
  ///   The client's end of the connection: CL_CheckForResend (getchallenge, then connect with the user info
  ///   Huffman compressed), the answers of the server, the netchan, the xor encoding and the parser of the
  ///   messages, and CL_WritePacket every time the owner asks for a packet. The parser puts what the server says
  ///   into the state of the client (see TQ3ClientMessageSink); cgame, the renderer and the input stay with the
  ///   owner, who calls Poll and SendPacket in its frame. Nothing opens a socket: the transport is passed in
  /// </summary>
  TQ3ClientNetwork = class
  strict private
    FTransport: INetTransport;
    FNetTransport: IQ3NetTransport;
    FNode: Integer;
    FLoopback: Boolean;
    FState: TQ3ClientState;
    FParser: TQ3ServerMessageParser;
    FWriter: TQ3ClientPacketWriter;
    FCoder: IQ3HuffmanCoder;
    FArguments: IQ3CommandArguments;
    FLog: ILog;
    FNetchan: TQ3Netchan;
    FConnection: TQ3ClientConnection;
    FUserinfo: AnsiString;
    FProtocol: Integer;
    FQPort: Integer;
    FChallenge: Integer;
    FPacketDup: Integer;
    FNoDelta: Boolean;
    FServerMessageSequence: Integer;
    FPrints: TArray<AnsiString>;
    procedure OutOfBand(const AText: AnsiString);
    procedure OutOfBandData(const AText: AnsiString);
    procedure ConnectionlessPacket(AMessage: TQ3Message);
    procedure SequencedPacket(AMessage: TQ3Message);
    function ServerIdOfSystemInfo: Integer;
  public
    /// <summary>The state, the parser and the writer are not owned; the transport is the way to the server (node 1)</summary>
    constructor Create(const ATransport: INetTransport; ANode: Integer; ALoopback: Boolean;
      const AState: TQ3ClientState; const AParser: TQ3ServerMessageParser; const AWriter: TQ3ClientPacketWriter;
      const AArguments: IQ3CommandArguments; const ACoder: IQ3HuffmanCoder; const ALog: ILog = nil);
    destructor Destroy; override;
    /// <summary>
    ///   CL_Connect_f: AUserinfo is the user info of the player; the protocol and the qport are added to it.
    ///   The first getchallenge goes at once
    /// </summary>
    procedure Connect(const AUserinfo: AnsiString; AProtocol, AQPort: Integer);
    /// <summary>CL_PacketEvent for every datagram that is waiting; how many there were</summary>
    function Poll: Integer;
    /// <summary>CL_WritePacket and CL_Netchan_Transmit: one packet of commands to the server</summary>
    procedure SendPacket;
    /// <summary>The "print" and "disconnect" texts the server sent out of band</summary>
    function Prints: TArray<AnsiString>;
    property Connection: TQ3ClientConnection read FConnection;
    /// <summary>clc.serverMessageSequence: the number of the last message that arrived</summary>
    property ServerMessageSequence: Integer read FServerMessageSequence;
    property Netchan: TQ3Netchan read FNetchan;
    property Challenge: Integer read FChallenge;
    property PacketDup: Integer read FPacketDup write FPacketDup;
    property NoDelta: Boolean read FNoDelta write FNoDelta;
  end;

implementation

uses
  DelphiDoom.Net.Q3.Factory, DelphiDoom.Net.Q3.HuffmanCompressor,
  DelphiDoom.Net.Q3.InfoString, DelphiDoom.Net.Q3.PacketCrypt, DelphiDoom.Q3Host.NetTransportAdapter;

const
  // CS_SYSTEMINFO
  CS_SYSTEMINFO = 1;

function CAtoi(const AText: AnsiString): Integer;
var
  LIndex, LSign: Integer;
begin
  Result := 0;
  LIndex := 1;
  while (LIndex <= Length(AText)) and (AText[LIndex] in [' ', #9]) do
    Inc(LIndex);
  LSign := 1;
  if (LIndex <= Length(AText)) and (AText[LIndex] in ['-', '+']) then
  begin
    if AText[LIndex] = '-' then
      LSign := -1;
    Inc(LIndex);
  end;
  while (LIndex <= Length(AText)) and (AText[LIndex] in ['0'..'9']) do
  begin
    Result := Result * 10 + (Ord(AText[LIndex]) - Ord('0'));
    Inc(LIndex);
  end;
  Result := Result * LSign;
end;

constructor TQ3ClientNetwork.Create(const ATransport: INetTransport; ANode: Integer; ALoopback: Boolean;
  const AState: TQ3ClientState; const AParser: TQ3ServerMessageParser; const AWriter: TQ3ClientPacketWriter;
  const AArguments: IQ3CommandArguments; const ACoder: IQ3HuffmanCoder; const ALog: ILog);
begin
  inherited Create;
  FTransport := ATransport;
  FNetTransport := TQ3NetTransportAdapter.Create(ATransport);
  FNode := ANode;
  FLoopback := ALoopback;
  FState := AState;
  FParser := AParser;
  FWriter := AWriter;
  FArguments := AArguments;
  FCoder := ACoder;
  FLog := ALog;
  FNetchan := TQ3NetFactory.CreateNetchan(FNetTransport, ALog);
  // cl_packetdup "1"
  FPacketDup := 1;
end;

destructor TQ3ClientNetwork.Destroy;
begin
  FNetchan.Free;
  inherited Destroy;
end;

// NET_OutOfBandPrint( NS_CLIENT, adr, string )
procedure TQ3ClientNetwork.OutOfBand(const AText: AnsiString);
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
  FTransport.Send(FNode, LData);
end;

// NET_OutOfBandData: the data are Huffman compressed from byte 12 on
procedure TQ3ClientNetwork.OutOfBandData(const AText: AnsiString);
var
  LMessage: TQ3Message;
  LBuffer, LData: TBytes;
begin
  SetLength(LBuffer, Q3_MAX_MSGLEN);
  SetLength(LData, 4 + Length(AText));
  LData[0] := $FF;
  LData[1] := $FF;
  LData[2] := $FF;
  LData[3] := $FF;
  if Length(AText) > 0 then
    Move(AText[1], LData[4], Length(AText));
  Move(LData[0], LBuffer[0], Length(LData));
  LMessage := TQ3NetFactory.CreateMessage(FCoder);
  try
    LMessage.Init(LBuffer, Length(LBuffer));
    LMessage.CurSize := Length(LData);
    TQ3HuffmanCompressor.Compress(LMessage, 12);
    FTransport.Send(FNode, Copy(LMessage.Data, 0, LMessage.CurSize));
  finally
    LMessage.Free;
  end;
end;

procedure TQ3ClientNetwork.Connect(const AUserinfo: AnsiString; AProtocol, AQPort: Integer);
begin
  FUserinfo := AUserinfo;
  FProtocol := AProtocol;
  FQPort := AQPort;
  FConnection := TQ3ClientConnection.Connecting;
  FPrints := nil;
  FState.ClearState;
  // CL_CheckForResend: getchallenge
  OutOfBand('getchallenge');
end;

function TQ3ClientNetwork.ServerIdOfSystemInfo: Integer;
begin
  // CL_SystemInfoChanged: cl.serverId = atoi( Info_ValueForKey( systemInfo, "sv_serverid" ) )
  Result := CAtoi(TQ3InfoString.ValueForKey(FState.ConfigString(CS_SYSTEMINFO), 'sv_serverid'));
end;

function TQ3ClientNetwork.Prints: TArray<AnsiString>;
begin
  Result := FPrints;
end;

// CL_ConnectionlessPacket
procedure TQ3ClientNetwork.ConnectionlessPacket(AMessage: TQ3Message);
var
  LText, LCommand, LInfo: AnsiString;
begin
  AMessage.BeginReadingOOB;
  // skip the -1
  AMessage.ReadLong;
  LText := AMessage.ReadStringLine;
  FArguments.Tokenize(LText);
  LCommand := FArguments.Argv(0);
  if SameText(string(LCommand), 'challengeResponse') then
  begin
    if FConnection = TQ3ClientConnection.Connecting then
    begin
      FChallenge := CAtoi(FArguments.Argv(1));
      FConnection := TQ3ClientConnection.Challenging;
      // CL_CheckForResend: connect "userinfo"
      LInfo := FUserinfo;
      TQ3InfoString.SetValueForKey(LInfo, 'protocol', AnsiString(IntToStr(FProtocol)));
      TQ3InfoString.SetValueForKey(LInfo, 'qport', AnsiString(IntToStr(FQPort)));
      TQ3InfoString.SetValueForKey(LInfo, 'challenge', AnsiString(IntToStr(FChallenge)));
      OutOfBandData('connect "' + LInfo + '"');
    end;
  end
  else if SameText(string(LCommand), 'connectResponse') then
  begin
    if FConnection = TQ3ClientConnection.Challenging then
    begin
      // Netchan_Setup( NS_CLIENT, &clc.netchan, from, net_qport )
      FNetchan.Setup(nsClient, TQ3NodeAddresses.FromNode(FNode, FLoopback), FQPort);
      FConnection := TQ3ClientConnection.Connected;
    end;
  end
  else if SameText(string(LCommand), 'print') then
  begin
    SetLength(FPrints, Length(FPrints) + 1);
    FPrints[High(FPrints)] := AMessage.ReadString;
  end
  else if SameText(string(LCommand), 'disconnect') then
  begin
    SetLength(FPrints, Length(FPrints) + 1);
    FPrints[High(FPrints)] := 'disconnect';
    if FConnection = TQ3ClientConnection.Connected then
      FConnection := TQ3ClientConnection.Disconnected;
  end;
end;

// CL_PacketEvent for a message of the netchan
procedure TQ3ClientNetwork.SequencedPacket(AMessage: TQ3Message);
var
  LPayload: TBytes;
begin
  if FConnection <> TQ3ClientConnection.Connected then
    Exit;
  // packet from the right server: make sure it is a valid, in sequence packet
  if not FNetchan.Process(AMessage) then
    Exit;
  TQ3PacketCrypt.ClientDecode(AMessage, FChallenge,
    function(ASequence: Integer): AnsiString
    begin
      Result := FState.ReliableCommand(ASequence);
    end);
  // clc.serverMessageSequence = LittleLong( *(int *)msg->data )
  FServerMessageSequence := AMessage.Data[0] or (AMessage.Data[1] shl 8) or (AMessage.Data[2] shl 16)
    or (AMessage.Data[3] shl 24);
  LPayload := Copy(AMessage.Data, AMessage.ReadCount, AMessage.CurSize - AMessage.ReadCount);
  FParser.OutgoingSequence := FNetchan.OutgoingSequence;
  FParser.ReliableSequence := FState.ReliableSequence;
  FParser.ParseMessage(LPayload, Length(LPayload), FServerMessageSequence);
end;

function TQ3ClientNetwork.Poll: Integer;
var
  LNode: Integer;
  LData, LBuffer: TBytes;
  LMessage: TQ3Message;
begin
  Result := 0;
  while FTransport.Receive(LNode, LData) do
  begin
    Inc(Result);
    SetLength(LBuffer, Q3_MAX_MSGLEN + 4);
    if Length(LData) > Length(LBuffer) then
      Continue;
    if Length(LData) > 0 then
      Move(LData[0], LBuffer[0], Length(LData));
    LMessage := TQ3NetFactory.CreateMessage(FCoder);
    try
      LMessage.Init(LBuffer, Length(LBuffer));
      LMessage.CurSize := Length(LData);
      if (Length(LData) >= 4) and (LData[0] = $FF) and (LData[1] = $FF) and (LData[2] = $FF) and (LData[3] = $FF) then
        ConnectionlessPacket(LMessage)
      else if Length(LData) >= 4 then
        SequencedPacket(LMessage);
    finally
      LMessage.Free;
    end;
  end;
end;

procedure TQ3ClientNetwork.SendPacket;
var
  LInput: TQ3ClientPacketInput;
  LData, LBuffer: TBytes;
  LMessage: TQ3Message;
  LServerTime: Integer;
begin
  if FConnection <> TQ3ClientConnection.Connected then
    Exit;
  LInput :=Default(TQ3ClientPacketInput);
  LInput.ServerId := ServerIdOfSystemInfo;
  LInput.ServerMessageSequence := FServerMessageSequence;
  LInput.OutgoingSequence := FNetchan.OutgoingSequence;
  LInput.ChecksumFeed := FState.ChecksumFeed;
  LInput.SnapshotValid := FState.SnapshotValid;
  FState.CurrentSnapshotNumber(LInput.SnapshotMessageNum, LServerTime);
  LInput.NoDelta := FNoDelta;
  LInput.PacketDup := FPacketDup;
  LData := FWriter.Write(LInput);
  SetLength(LBuffer, Length(LData) + 4);
  Move(LData[0], LBuffer[0], Length(LData));
  LMessage := TQ3NetFactory.CreateMessage(FCoder);
  try
    LMessage.Init(LBuffer, Length(LBuffer));
    LMessage.CurSize := Length(LData);
    // CL_Netchan_Encode and Netchan_Transmit
    TQ3PacketCrypt.ClientEncode(LMessage, FChallenge,
      function(ASequence: Integer): AnsiString
      begin
        Result := FState.ServerCommandText(ASequence);
      end);
    FNetchan.Transmit(LMessage.Data, LMessage.CurSize);
    // clients never really should have messages large enough to fragment, but in case they do, fire them all off
    while FNetchan.UnsentFragments do
      FNetchan.TransmitNextFragment;
  finally
    LMessage.Free;
  end;
end;

end.
