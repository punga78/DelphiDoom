{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the xor encoding of the messages of Quake III     }
{  (SV_Netchan_Encode/Decode, CL_Netchan_Encode/Decode)                        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_net_chan.c,  }
{  cl_net_chan.c, qcommon.h (SV_ENCODE_START...). Copyright (C) 1999-2005 id   }
{  Software, Inc.                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.PacketCrypt;

// Overflow and range checks are off: key is a byte of the C, the shifts of '.' and of the characters wrap.
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Message;

type
  /// <summary>
  ///   Gives the text of a command by its number (reliableCommands[ n &amp; (MAX_RELIABLE_COMMANDS-1) ] and
  ///   serverCommands[ ... ])
  /// </summary>
  TQ3CommandLookup = reference to function(ASequence: Integer): AnsiString;

  /// <summary>
  ///   The messages between a client and a server are xor-ed, from a start byte on, with a key that changes at
  ///   every byte: the challenge of the client, numbers of the message and the text of the last commands that
  ///   were acknowledged. Not a protection (the data of the key travel in the clear); it keeps a packet from being
  ///   replayed or forged without having seen the connection. The four functions work on a message as the netchan
  ///   gives it: Decode on a received datagram (ReadCount past the header), Encode on the data that go out
  ///   (without header). The read position of the message is not changed
  /// </summary>
  TQ3PacketCrypt = class sealed
  strict private
    const
      SV_ENCODE_START = 4;
      SV_DECODE_START = 12;
      CL_ENCODE_START = 12;
      CL_DECODE_START = 4;
    class function CharKey(AKey: Byte; ACharacter: Byte; APosition: Integer): Byte; static; inline;
  public
    /// <summary>SV_Netchan_Encode: the message of the server, before Netchan_Transmit</summary>
    class procedure ServerEncode(AMessage: TQ3Message; AChallenge, AOutgoingSequence: Integer;
      const ALastClientCommand: AnsiString); static;
    /// <summary>SV_Netchan_Decode: the message of a client, after Netchan_Process</summary>
    class procedure ServerDecode(AMessage: TQ3Message; AChallenge: Integer;
      const AReliableCommands: TQ3CommandLookup); static;
    /// <summary>CL_Netchan_Encode: the message of the client, before Netchan_Transmit (it ends with clc_EOF)</summary>
    class procedure ClientEncode(AMessage: TQ3Message; AChallenge: Integer;
      const AServerCommands: TQ3CommandLookup); static;
    /// <summary>CL_Netchan_Decode: the message of the server, after Netchan_Process</summary>
    class procedure ClientDecode(AMessage: TQ3Message; AChallenge: Integer;
      const AReliableCommands: TQ3CommandLookup); static;
  end;

implementation

class function TQ3PacketCrypt.CharKey(AKey: Byte; ACharacter: Byte; APosition: Integer): Byte;
begin
  // if (string[index] > 127 || string[index] == '%') key ^= '.' << (i & 1); else key ^= string[index] << (i & 1)
  if (ACharacter > 127) or (ACharacter = Ord('%')) then
    Result := Byte(AKey xor (Ord('.') shl (APosition and 1)))
  else
    Result := Byte(AKey xor (ACharacter shl (APosition and 1)));
end;

class procedure TQ3PacketCrypt.ServerEncode(AMessage: TQ3Message; AChallenge, AOutgoingSequence: Integer;
  const ALastClientCommand: AnsiString);
var
  LText, LPosition: Integer;
  LKey: Byte;
  LCharacter: Byte;
begin
  if AMessage.CurSize < SV_ENCODE_START then
    Exit;
  // the C reads reliableAcknowledge here and does not use it
  LText := 0;
  // xor the client challenge with the netchan sequence number
  LKey := Byte(AChallenge xor AOutgoingSequence);
  for LPosition := SV_ENCODE_START to AMessage.CurSize - 1 do
  begin
    // modify the key with the last received and with this message acknowledged client command
    if (LText >= Length(ALastClientCommand)) or (ALastClientCommand[LText + 1] = #0) then
      LText := 0;
    if Length(ALastClientCommand) = 0 then
      LCharacter := 0
    else
      LCharacter := Byte(ALastClientCommand[LText + 1]);
    LKey := CharKey(LKey, LCharacter, LPosition);
    Inc(LText);
    // encode the data with this key
    AMessage.Data[LPosition] := AMessage.Data[LPosition] xor LKey;
  end;
end;

class procedure TQ3PacketCrypt.ServerDecode(AMessage: TQ3Message; AChallenge: Integer;
  const AReliableCommands: TQ3CommandLookup);
var
  LServerId, LMessageAcknowledge, LReliableAcknowledge: Integer;
  LText, LPosition, LSavedRead, LSavedBit: Integer;
  LSavedOob: Boolean;
  LKey, LCharacter: Byte;
  LCommand: AnsiString;
begin
  LSavedRead := AMessage.ReadCount;
  LSavedBit := AMessage.Bit;
  LSavedOob := AMessage.Oob;
  AMessage.Oob := False;
  LServerId := AMessage.ReadLong;
  LMessageAcknowledge := AMessage.ReadLong;
  LReliableAcknowledge := AMessage.ReadLong;
  AMessage.Oob := LSavedOob;
  AMessage.Bit := LSavedBit;
  AMessage.ReadCount := LSavedRead;
  LCommand := AReliableCommands(LReliableAcknowledge);
  LText := 0;
  LKey := Byte(AChallenge xor LServerId xor LMessageAcknowledge);
  for LPosition := AMessage.ReadCount + SV_DECODE_START to AMessage.CurSize - 1 do
  begin
    // modify the key with the last sent and acknowledged server command
    if (LText >= Length(LCommand)) or (LCommand[LText + 1] = #0) then
      LText := 0;
    if Length(LCommand) = 0 then
      LCharacter := 0
    else
      LCharacter := Byte(LCommand[LText + 1]);
    LKey := CharKey(LKey, LCharacter, LPosition);
    Inc(LText);
    // decode the data with this key
    AMessage.Data[LPosition] := AMessage.Data[LPosition] xor LKey;
  end;
end;

class procedure TQ3PacketCrypt.ClientEncode(AMessage: TQ3Message; AChallenge: Integer;
  const AServerCommands: TQ3CommandLookup);
var
  LServerId, LMessageAcknowledge, LReliableAcknowledge: Integer;
  LText, LPosition, LSavedRead, LSavedBit: Integer;
  LSavedOob: Boolean;
  LKey, LCharacter: Byte;
  LCommand: AnsiString;
begin
  if AMessage.CurSize <= CL_ENCODE_START then
    Exit;
  LSavedRead := AMessage.ReadCount;
  LSavedBit := AMessage.Bit;
  LSavedOob := AMessage.Oob;
  AMessage.Bit := 0;
  AMessage.ReadCount := 0;
  AMessage.Oob := False;
  LServerId := AMessage.ReadLong;
  LMessageAcknowledge := AMessage.ReadLong;
  LReliableAcknowledge := AMessage.ReadLong;
  AMessage.Oob := LSavedOob;
  AMessage.Bit := LSavedBit;
  AMessage.ReadCount := LSavedRead;
  LCommand := AServerCommands(LReliableAcknowledge);
  LText := 0;
  LKey := Byte(AChallenge xor LServerId xor LMessageAcknowledge);
  for LPosition := CL_ENCODE_START to AMessage.CurSize - 1 do
  begin
    // modify the key with the last received now acknowledged server command
    if (LText >= Length(LCommand)) or (LCommand[LText + 1] = #0) then
      LText := 0;
    if Length(LCommand) = 0 then
      LCharacter := 0
    else
      LCharacter := Byte(LCommand[LText + 1]);
    LKey := CharKey(LKey, LCharacter, LPosition);
    Inc(LText);
    // encode the data with this key
    AMessage.Data[LPosition] := AMessage.Data[LPosition] xor LKey;
  end;
end;

class procedure TQ3PacketCrypt.ClientDecode(AMessage: TQ3Message; AChallenge: Integer;
  const AReliableCommands: TQ3CommandLookup);
var
  LReliableAcknowledge, LSequence: Integer;
  LText, LPosition, LSavedRead, LSavedBit: Integer;
  LSavedOob: Boolean;
  LKey, LCharacter: Byte;
  LCommand: AnsiString;
begin
  LSavedRead := AMessage.ReadCount;
  LSavedBit := AMessage.Bit;
  LSavedOob := AMessage.Oob;
  AMessage.Oob := False;
  LReliableAcknowledge := AMessage.ReadLong;
  AMessage.Oob := LSavedOob;
  AMessage.Bit := LSavedBit;
  AMessage.ReadCount := LSavedRead;
  LCommand := AReliableCommands(LReliableAcknowledge);
  LText := 0;
  // xor the client challenge with the netchan sequence number (the first four bytes of the datagram)
  LSequence := AMessage.Data[0] or (AMessage.Data[1] shl 8) or (AMessage.Data[2] shl 16) or (AMessage.Data[3] shl 24);
  LKey := Byte(AChallenge xor LSequence);
  for LPosition := AMessage.ReadCount + CL_DECODE_START to AMessage.CurSize - 1 do
  begin
    // modify the key with the last sent and with this message acknowledged client command
    if (LText >= Length(LCommand)) or (LCommand[LText + 1] = #0) then
      LText := 0;
    if Length(LCommand) = 0 then
      LCharacter := 0
    else
      LCharacter := Byte(LCommand[LText + 1]);
    LKey := CharKey(LKey, LCharacter, LPosition);
    Inc(LText);
    // decode the data with this key
    AMessage.Data[LPosition] := AMessage.Data[LPosition] xor LKey;
  end;
end;

end.
