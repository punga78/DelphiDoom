{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the packets a client sends to the      }
{  server                                                                      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_input.c      }
{  (CL_WritePacket), cl_net_chan.c (CL_Netchan_Transmit, the clc_EOF).         }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientPacketWriter;

// Overflow and range checks are off: the counters of the C are 32 bit integers.

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Q3Host.ClientState;

type
  /// <summary>What the writer needs from the connection (clc and cl of the C)</summary>
  TQ3ClientPacketInput = record
    /// <summary>cl.serverId (sv_serverid of the system info)</summary>
    ServerId: Integer;
    /// <summary>clc.serverMessageSequence: the last message that arrived</summary>
    ServerMessageSequence: Integer;
    /// <summary>clc.netchan.outgoingSequence: the number the packet is going to have</summary>
    OutgoingSequence: Integer;
    /// <summary>clc.checksumFeed</summary>
    ChecksumFeed: Integer;
    /// <summary>cl.snap.valid and cl.snap.messageNum</summary>
    SnapshotValid: Boolean;
    SnapshotMessageNum: Integer;
    /// <summary>cl_nodelta</summary>
    NoDelta: Boolean;
    /// <summary>cl_packetdup: 0 to 5, how many packets before this one repeat their commands</summary>
    PacketDup: Integer;
  end;

  /// <summary>
  ///   CL_WritePacket: the acknowledges, the client commands that the server did not acknowledge and the user
  ///   commands made since the packet that is PacketDup before this one, delta compressed with the key of the
  ///   connection. The message comes out with clc_EOF at the end (CL_Netchan_Transmit writes it), not xor-ed yet.
  ///   It keeps cl.outPackets[].p_cmdNumber
  /// </summary>
  TQ3ClientPacketWriter = class
  strict private
    FState: TQ3ClientState;
    FCoder: IQ3HuffmanCoder;
    FCommandNumbers: array[0..Q3_PACKET_BACKUP - 1] of Integer;
  public
    /// <summary>Neither is owned</summary>
    constructor Create(const AState: TQ3ClientState; const ACoder: IQ3HuffmanCoder);
    /// <summary>
    ///   The packet; an empty array when there is nothing to send because the connection is not there. The
    ///   message is the same bytes the netchan takes (Transmit adds the sequence number)
    /// </summary>
    function Write(const AInput: TQ3ClientPacketInput): TBytes;
  end;

implementation

uses
  System.Math, DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.Factory, DelphiDoom.Net.Q3.UserCmdCodec,
  DelphiDoom.Net.Q3.HashKey, DelphiDoom.Q3Host.Client.Types;

constructor TQ3ClientPacketWriter.Create(const AState: TQ3ClientState; const ACoder: IQ3HuffmanCoder);
begin
  inherited Create;
  FState := AState;
  FCoder := ACoder;
end;

function TQ3ClientPacketWriter.Write(const AInput: TQ3ClientPacketInput): TBytes;
var
  LMessage: TQ3Message;
  LBuffer: TBytes;
  LIndex, LCount, LKey, LOldPacket, LPacket, LDup: Integer;
  LCommand: TQ3HostUserCmd;
  LNew, LOld: TQ3UserCmd;
begin
  SetLength(LBuffer, Q3_MAX_MSGLEN);
  LMessage := TQ3NetFactory.CreateMessage(FCoder);
  try
    LMessage.Init(LBuffer, Q3_MAX_MSGLEN);
    LMessage.Bitstream;
    // write the current serverId so the server can tell if this is from the current gameState
    LMessage.WriteLong(AInput.ServerId);
    // write the last message we received, which can be used for delta compression, and is also used to tell if
    // we dropped a gamestate
    LMessage.WriteLong(AInput.ServerMessageSequence);
    // write the last reliable message we received
    LMessage.WriteLong(FState.ServerCommandSequence);
    // write any unacknowledged clientCommands
    for LIndex := FState.ReliableAcknowledge + 1 to FState.ReliableSequence do
    begin
      LMessage.WriteByte(Q3_CLC_CLIENT_COMMAND);
      LMessage.WriteLong(LIndex);
      LMessage.WriteString(FState.ReliableCommand(LIndex));
    end;
    // we want to send all the usercmds that were generated in the last few packets, so even if a couple packets
    // are dropped in a row, all the cmds will make it to the server
    LDup := Min(5, Max(0, AInput.PacketDup));
    LOldPacket := (AInput.OutgoingSequence - 1 - LDup) and (Q3_PACKET_BACKUP - 1);
    LCount := FState.CurrentCommandNumber - FCommandNumbers[LOldPacket];
    if LCount > Q3_MAX_PACKET_USERCMDS then
      LCount := Q3_MAX_PACKET_USERCMDS;
    if LCount >= 1 then
    begin
      // begin a client move command
      if AInput.NoDelta or not AInput.SnapshotValid or (AInput.ServerMessageSequence <> AInput.SnapshotMessageNum) then
        LMessage.WriteByte(Q3_CLC_MOVE_NODELTA)
      else
        LMessage.WriteByte(Q3_CLC_MOVE);
      // write the command count
      LMessage.WriteByte(LCount);
      // use the checksum feed in the key, the message acknowledge and the last acknowledged server command
      LKey := AInput.ChecksumFeed xor AInput.ServerMessageSequence xor
        TQ3HashKey.Compute(FState.ServerCommandText(FState.ServerCommandSequence), 32);
      // write all the commands, including the predicted command
      LOld := Default(TQ3UserCmd);
      for LIndex := 0 to LCount - 1 do
      begin
        if not FState.TryGetUserCmd(FState.CurrentCommandNumber - LCount + LIndex + 1, LCommand) then
          LCommand := Default(TQ3HostUserCmd);
        Move(LCommand[0], LNew, SizeOf(TQ3UserCmd));
        TQ3UserCmdCodec.WriteDeltaKey(LMessage, LKey, LOld, LNew);
        LOld := LNew;
      end;
    end;
    // deliver the message
    LPacket := AInput.OutgoingSequence and (Q3_PACKET_BACKUP - 1);
    FCommandNumbers[LPacket] := FState.CurrentCommandNumber;
    // CL_Netchan_Transmit: the message ends with clc_EOF
    LMessage.WriteByte(Q3_CLC_EOF);
    Result := Copy(LMessage.Data, 0, LMessage.CurSize);
  finally
    LMessage.Free;
  end;
end;

end.
