{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the bytes of a packet                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.PacketCodec;

interface

uses
  System.SysUtils, DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  /// <summary>
  ///   The layout of doomdata_t on the wire, byte by byte (little endian, no padding):
  ///   0 checksum word, 4 RetransmitFrom, 5 StartTic, 6 Player, 7 NumTics, 8 flags word, 12 the commands.
  ///   The checksum is $1234567 plus the words of the packet from offset 4, as the old code computed it
  /// </summary>
  TNetPacketCodec = class(TInterfacedObject, INetPacketCodec)
  private
    FCommandSize: Integer;
    FMaxTics: Integer;
  public
    constructor Create(ACommandSize, AMaxTics: Integer);
    /// <summary>
    ///   $1234567 + the little endian words 1..Size div 4 of the packet, masked to 28 bits. The old
    ///   code summed a word that can end up to 3 bytes after the last byte of the packet (the bytes
    ///   that the buffer held before): here those bytes are zero
    /// </summary>
    class function ComputeChecksum(const AData: TBytes; ASize: Integer): LongWord; static;
    function CommandSize: Integer;
    function MaxTics: Integer;
    function PacketSize(ANumTics: Integer): Integer;
    function Encode(var APacket: TNetPacket; AControl: LongWord): TBytes;
    function Decode(const AData: TBytes; out APacket: TNetPacket): TNetDecodeStatus;
  end;

implementation

const
  SBadCommandSize = 'The command size of a net packet must be greater than zero.';
  SBadMaxTics = 'The most tics of a net packet must be between 1 and 255.';
  STooManyTics = 'A net packet cannot have %d tics (the most is %d).';
  SBadCommandBytes = 'A net packet of %d tics needs %d bytes of commands, not %d.';

function ReadWord(const AData: TBytes; AOffset, ASize: Integer): LongWord;
var
  LIndex: Integer;
  LByte: LongWord;
begin
  Result := 0;
  for LIndex := 0 to 3 do
    if (AOffset + LIndex < ASize) and (AOffset + LIndex < Length(AData)) then
    begin
      LByte := AData[AOffset + LIndex];
      Result := Result or (LByte shl (8 * LIndex));
    end;
end;

procedure WriteWord(var AData: TBytes; AOffset: Integer; AValue: LongWord);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    AData[AOffset + LIndex] := Byte((AValue shr (8 * LIndex)) and $FF);
end;

{ TNetPacketCodec }

constructor TNetPacketCodec.Create(ACommandSize, AMaxTics: Integer);
begin
  inherited Create;
  if ACommandSize < 1 then
    raise ENetException.Create(SBadCommandSize);
  if (AMaxTics < 1) or (AMaxTics > 255) then
    raise ENetException.Create(SBadMaxTics);
  FCommandSize := ACommandSize;
  FMaxTics := AMaxTics;
end;

class function TNetPacketCodec.ComputeChecksum(const AData: TBytes; ASize: Integer): LongWord;
var
  LIndex: Integer;
  LSum: UInt64;
begin
  LSum := $1234567;
  for LIndex := 1 to ASize div 4 do
    LSum := LSum + ReadWord(AData, LIndex * 4, ASize);
  Result := LongWord(LSum and NCMD_CHECKSUM);
end;

function TNetPacketCodec.CommandSize: Integer;
begin
  Result := FCommandSize;
end;

function TNetPacketCodec.MaxTics: Integer;
begin
  Result := FMaxTics;
end;

function TNetPacketCodec.PacketSize(ANumTics: Integer): Integer;
begin
  Result := NET_PACKET_HEADER_SIZE + ANumTics * FCommandSize;
end;

function TNetPacketCodec.Encode(var APacket: TNetPacket; AControl: LongWord): TBytes;
var
  LSize: Integer;
begin
  if APacket.NumTics > FMaxTics then
    raise ENetException.CreateFmt(STooManyTics, [APacket.NumTics, FMaxTics]);
  if Length(APacket.Commands) <> APacket.NumTics * FCommandSize then
    raise ENetException.CreateFmt(SBadCommandBytes,
      [APacket.NumTics, APacket.NumTics * FCommandSize, Length(APacket.Commands)]);
  LSize := PacketSize(APacket.NumTics);
  SetLength(Result, LSize);
  FillChar(Result[0], LSize, 0);
  Result[4] := APacket.RetransmitFrom;
  Result[5] := APacket.StartTic;
  Result[6] := APacket.Player;
  Result[7] := APacket.NumTics;
  WriteWord(Result, 8, APacket.Flags);
  if APacket.NumTics > 0 then
    Move(APacket.Commands[0], Result[NET_PACKET_HEADER_SIZE], APacket.NumTics * FCommandSize);
  APacket.Checksum := ComputeChecksum(Result, LSize) or AControl;
  WriteWord(Result, 0, APacket.Checksum);
end;

function TNetPacketCodec.Decode(const AData: TBytes; out APacket: TNetPacket): TNetDecodeStatus;
var
  LNumTics: Integer;
begin
  APacket := Default(TNetPacket);
  if Length(AData) < NET_PACKET_HEADER_SIZE then
    Exit(ndsBadLength);
  LNumTics := AData[7];
  if (LNumTics > FMaxTics) or (Length(AData) <> PacketSize(LNumTics)) then
    Exit(ndsBadLength);
  APacket.Checksum := ReadWord(AData, 0, Length(AData));
  APacket.RetransmitFrom := AData[4];
  APacket.StartTic := AData[5];
  APacket.Player := AData[6];
  APacket.NumTics := AData[7];
  APacket.Flags := ReadWord(AData, 8, Length(AData));
  SetLength(APacket.Commands, LNumTics * FCommandSize);
  if LNumTics > 0 then
    Move(AData[NET_PACKET_HEADER_SIZE], APacket.Commands[0], LNumTics * FCommandSize);
  if ComputeChecksum(AData, Length(AData)) <> (APacket.Checksum and NCMD_CHECKSUM) then
    Exit(ndsBadChecksum);
  Result := ndsOk;
end;

end.
