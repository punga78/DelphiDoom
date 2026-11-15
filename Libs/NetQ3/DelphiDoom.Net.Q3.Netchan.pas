{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the network channel of Quake III (netchan_t)      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): net_chan.c,     }
{  qcommon.h. Copyright (C) 1999-2005 id Software, Inc.                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.Netchan;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf,
  DelphiDoom.Net.Q3.Message;

type
  /// <summary>
  ///   Netchan: sequence numbers, duplicate and out of order packets, and the fragmentation of messages
  ///   that do not fit in a datagram. The packet header is the sequence (4 bytes, high bit set on the
  ///   fragments), the qport (2 bytes, only from a client) and, for a fragment, its start and length
  ///   (2 bytes each); a fragment shorter than FRAGMENT_SIZE is the last. Datagrams leave through the
  ///   transport that the channel receives; a received datagram is given to <c>Process</c>.
  ///   The original keeps showpackets, showdrop and the qport in cvars: here they are properties
  /// </summary>
  TQ3Netchan = class
  strict private
    FTransport: IQ3NetTransport;
    FLog: ILog;
    FSource: TQ3NetSource;
    FDropped: Integer;
    FRemoteAddress: TQ3NetAddress;
    FQPort: Integer;
    FIncomingSequence: Integer;
    FOutgoingSequence: Integer;
    FFragmentSequence: Integer;
    FFragmentLength: Integer;
    FFragmentBuffer: TBytes;
    FUnsentFragments: Boolean;
    FUnsentFragmentStart: Integer;
    FUnsentLength: Integer;
    FUnsentBuffer: TBytes;
    FShowPackets: Boolean;
    FShowDrop: Boolean;
    procedure Report(const AText: string);
    function SourceName: string;
  public
    /// <summary>ALog gets what showpackets and showdrop would print (nil = silence)</summary>
    constructor Create(const ATransport: IQ3NetTransport; const ALog: ILog = nil);
    /// <summary>Netchan_Setup: opens the channel to a remote system (everything starts again)</summary>
    procedure Setup(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; AQPort: Integer);
    /// <summary>
    ///   Netchan_Transmit: sends a message, fragmenting it if it is FRAGMENT_SIZE bytes or more (only the
    ///   first fragment goes now; the others with <c>TransmitNextFragment</c>). A zero length still makes a
    ///   packet. More than MAX_MSGLEN bytes is an <c>EQ3NetchanException</c>
    /// </summary>
    procedure Transmit(const AData: TBytes; ALength: Integer);
    /// <summary>Netchan_TransmitNextFragment: one fragment of the message in progress</summary>
    procedure TransmitNextFragment;
    /// <summary>
    ///   Netchan_Process: reads the header of a received datagram. False if the message should not be
    ///   processed: out of order, duplicated, a fragment that is not the last or not the next one. The last
    ///   fragment of a message makes the whole message (sequence number first) replace the datagram, so the
    ///   buffer of the message must hold 4 bytes more than MAX_MSGLEN-sized messages need
    /// </summary>
    function Process(AMessage: TQ3Message): Boolean;

    property Source: TQ3NetSource read FSource;
    /// <summary>Packets lost between the last packet and the previous one</summary>
    property Dropped: Integer read FDropped;
    property RemoteAddress: TQ3NetAddress read FRemoteAddress;
    property QPort: Integer read FQPort;
    property IncomingSequence: Integer read FIncomingSequence write FIncomingSequence;
    property OutgoingSequence: Integer read FOutgoingSequence write FOutgoingSequence;
    property FragmentSequence: Integer read FFragmentSequence;
    property FragmentLength: Integer read FFragmentLength;
    property UnsentFragments: Boolean read FUnsentFragments;
    property UnsentFragmentStart: Integer read FUnsentFragmentStart;
    property UnsentLength: Integer read FUnsentLength;
    property ShowPackets: Boolean read FShowPackets write FShowPackets;
    property ShowDrop: Boolean read FShowDrop write FShowDrop;
  end;

implementation

{ TQ3Netchan }

constructor TQ3Netchan.Create(const ATransport: IQ3NetTransport; const ALog: ILog);
begin
  inherited Create;
  FTransport := ATransport;
  FLog := ALog;
  SetLength(FFragmentBuffer, Q3_MAX_MSGLEN);
  SetLength(FUnsentBuffer, Q3_MAX_MSGLEN);
end;

procedure TQ3Netchan.Report(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText);
end;

function TQ3Netchan.SourceName: string;
begin
  if FSource = nsClient then
    Result := 'client'
  else
    Result := 'server';
end;

procedure TQ3Netchan.Setup(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; AQPort: Integer);
begin
  FSource := ASource;
  FRemoteAddress := AAddress;
  FQPort := AQPort;
  FDropped := 0;
  FIncomingSequence := 0;
  FOutgoingSequence := 1;
  FFragmentSequence := 0;
  FFragmentLength := 0;
  FUnsentFragments := False;
  FUnsentFragmentStart := 0;
  FUnsentLength := 0;
  FillChar(FFragmentBuffer[0], Length(FFragmentBuffer), 0);
  FillChar(FUnsentBuffer[0], Length(FUnsentBuffer), 0);
end;

procedure TQ3Netchan.TransmitNextFragment;
var
  LSend: TQ3Message;
  LBuffer, LPacket, LFragment: TBytes;
  LFragmentLength: Integer;
begin
  SetLength(LBuffer, Q3_MAX_PACKETLEN);
  LSend := TQ3Message.Create(nil, FLog);
  try
    // write the packet header
    LSend.InitOOB(LBuffer, Length(LBuffer));
    LSend.WriteLong(FOutgoingSequence or Q3_FRAGMENT_BIT);

    // send the qport if we are a client
    if FSource = nsClient then
      LSend.WriteShort(FQPort);

    // copy the reliable message to the packet first
    LFragmentLength := Q3_FRAGMENT_SIZE;
    if FUnsentFragmentStart + LFragmentLength > FUnsentLength then
      LFragmentLength := FUnsentLength - FUnsentFragmentStart;

    LSend.WriteShort(FUnsentFragmentStart);
    LSend.WriteShort(LFragmentLength);
    LFragment := Copy(FUnsentBuffer, FUnsentFragmentStart, LFragmentLength);
    LSend.WriteData(LFragment, LFragmentLength);

    // send the datagram
    LPacket := Copy(LBuffer, 0, LSend.CurSize);
    FTransport.SendPacket(FSource, FRemoteAddress, LPacket);

    if FShowPackets then
      Report(Format('%s send %4d : s=%d fragment=%d,%d', [SourceName, LSend.CurSize, FOutgoingSequence,
        FUnsentFragmentStart, LFragmentLength]));
  finally
    LSend.Free;
  end;

  Inc(FUnsentFragmentStart, LFragmentLength);

  // this exit condition is a little tricky, because a packet that is exactly the fragment length
  // still needs to send a second packet of zero length so that the other side can tell there
  // aren't more to follow
  if (FUnsentFragmentStart = FUnsentLength) and (LFragmentLength <> Q3_FRAGMENT_SIZE) then
  begin
    Inc(FOutgoingSequence);
    FUnsentFragments := False;
  end;
end;

procedure TQ3Netchan.Transmit(const AData: TBytes; ALength: Integer);
var
  LSend: TQ3Message;
  LBuffer, LPacket: TBytes;
begin
  if ALength > Q3_MAX_MSGLEN then
    raise EQ3NetchanException.CreateFmt(SQ3NetchanTooLong, [ALength]);
  FUnsentFragmentStart := 0;

  // fragment large reliable messages
  if ALength >= Q3_FRAGMENT_SIZE then
  begin
    FUnsentFragments := True;
    FUnsentLength := ALength;
    Move(AData[0], FUnsentBuffer[0], ALength);

    // only send the first fragment now
    TransmitNextFragment;
    Exit;
  end;

  // write the packet header
  SetLength(LBuffer, Q3_MAX_PACKETLEN);
  LSend := TQ3Message.Create(nil, FLog);
  try
    LSend.InitOOB(LBuffer, Length(LBuffer));
    LSend.WriteLong(FOutgoingSequence);
    Inc(FOutgoingSequence);

    // send the qport if we are a client
    if FSource = nsClient then
      LSend.WriteShort(FQPort);

    LSend.WriteData(AData, ALength);

    // send the datagram
    LPacket := Copy(LBuffer, 0, LSend.CurSize);
    FTransport.SendPacket(FSource, FRemoteAddress, LPacket);

    if FShowPackets then
      Report(Format('%s send %4d : s=%d ack=%d', [SourceName, LSend.CurSize, FOutgoingSequence - 1,
        FIncomingSequence]));
  finally
    LSend.Free;
  end;
end;

function TQ3Netchan.Process(AMessage: TQ3Message): Boolean;
var
  LSequence, LFragmentStart, LFragmentLength: Integer;
  LFragmented: Boolean;
  LText: string;
begin
  // get sequence numbers
  AMessage.BeginReadingOOB;
  LSequence := AMessage.ReadLong;

  // check for fragment information
  if (LSequence and Q3_FRAGMENT_BIT) <> 0 then
  begin
    LSequence := LSequence and not Q3_FRAGMENT_BIT;
    LFragmented := True;
  end
  else
    LFragmented := False;

  // read the qport if we are a server
  if FSource = nsServer then
    AMessage.ReadShort;

  // read the fragment information
  if LFragmented then
  begin
    LFragmentStart := AMessage.ReadShort;
    LFragmentLength := AMessage.ReadShort;
  end
  else
  begin
    LFragmentStart := 0;
    LFragmentLength := 0;
  end;

  if FShowPackets then
  begin
    if LFragmented then
      Report(Format('%s recv %4d : s=%d fragment=%d,%d', [SourceName, AMessage.CurSize, LSequence,
        LFragmentStart, LFragmentLength]))
    else
      Report(Format('%s recv %4d : s=%d', [SourceName, AMessage.CurSize, LSequence]));
  end;

  // discard out of order or duplicated packets
  if LSequence <= FIncomingSequence then
  begin
    if FShowDrop or FShowPackets then
      Report(Format('Out of order packet %d at %d', [LSequence, FIncomingSequence]));
    Exit(False);
  end;

  // dropped packets don't keep the message from being used
  FDropped := LSequence - (FIncomingSequence + 1);
  if (FDropped > 0) and (FShowDrop or FShowPackets) then
    Report(Format('Dropped %d packets at %d', [FDropped, LSequence]));

  // if this is the final fragment of a reliable message, bump incoming_reliable_sequence
  if LFragmented then
  begin
    // make sure we add the fragments in correct order: either a packet was dropped, or we received this
    // one too soon; we don't reconstruct the fragments, we wait till this fragment gets to us again
    if LSequence <> FFragmentSequence then
    begin
      FFragmentSequence := LSequence;
      FFragmentLength := 0;
    end;

    // if we missed a fragment, dump the message (what we have so far is kept)
    if LFragmentStart <> FFragmentLength then
    begin
      if FShowDrop or FShowPackets then
        Report('Dropped a message fragment');
      Exit(False);
    end;

    // copy the fragment to the fragment buffer
    if (LFragmentLength < 0) or (AMessage.ReadCount + LFragmentLength > AMessage.CurSize)
      or (FFragmentLength + LFragmentLength > Length(FFragmentBuffer)) then
    begin
      if FShowDrop or FShowPackets then
        Report('illegal fragment length');
      Exit(False);
    end;

    if LFragmentLength > 0 then
      Move(AMessage.Data[AMessage.ReadCount], FFragmentBuffer[FFragmentLength], LFragmentLength);
    Inc(FFragmentLength, LFragmentLength);

    // if this wasn't the last fragment, don't process anything
    if LFragmentLength = Q3_FRAGMENT_SIZE then
      Exit(False);

    if FFragmentLength > AMessage.MaxSize then
    begin
      LText := Format('fragmentLength %d > msg->maxsize', [FFragmentLength]);
      Report(LText);
      Exit(False);
    end;

    // copy the full message over the partial fragment
    if Length(AMessage.Data) < FFragmentLength + 4 then
      raise EQ3MessageOverflowException.CreateFmt(SQ3NetchanBufferTooSmall,
        [Length(AMessage.Data), FFragmentLength + 4]);

    // make sure the sequence number is still there
    AMessage.Data[0] := Byte(LSequence);
    AMessage.Data[1] := Byte(LSequence shr 8);
    AMessage.Data[2] := Byte(LSequence shr 16);
    AMessage.Data[3] := Byte(LSequence shr 24);

    if FFragmentLength > 0 then
      Move(FFragmentBuffer[0], AMessage.Data[4], FFragmentLength);
    AMessage.CurSize := FFragmentLength + 4;
    FFragmentLength := 0;
    AMessage.ReadCount := 4; // past the sequence number
    AMessage.Bit := 32; // past the sequence number

    // clients were not acking fragmented messages
    FIncomingSequence := LSequence;

    Exit(True);
  end;

  // the message can now be read from the current message pointer
  FIncomingSequence := LSequence;
  Result := True;
end;

end.
