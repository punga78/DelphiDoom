{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the net game: the buffer of the packets          }
{  Port of xGreed (Jim Valavanis): greedcom.data of                             }
{  protos_h.pas and the event pointers of net.pas that all point into it        }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Net.PacketBuffer;

interface

uses
  System.SysUtils, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Net.Types;

type
  /// <summary>
  ///   greedcom.data: the 128 bytes in which the original builds every packet that it sends and finds every packet
  ///   that it receives. In net.pas ten pointers (pevent, sevent, ievent ...) look at the same bytes as ten
  ///   different structures, so a field that a sender does not set travels with the bytes of the packet that was
  ///   there before (the angle of a door packet, the padding and the tail of a text). Here the buffer is the same
  ///   one for the whole session and each kind of packet is read from it and written to it field by field, as
  ///   little endian 32 bit numbers whatever the machine: reading a packet, changing some fields and writing it
  ///   back leaves the other bytes as they were, which is what the original does
  /// </summary>
  TGreedNetPacketBuffer = class
  strict private
    FData: array[0..GREED_NET_MAX_DATA - 1] of Byte;
    function GetInt(AOffset: Integer): Integer;
    procedure SetInt(AOffset, AValue: Integer);
    procedure GetInts(AOffset, ACount: Integer; AFirst: PInteger);
    procedure SetInts(AOffset, ACount: Integer; AFirst: PInteger);
  public
    /// <summary>All the bytes to zero (the buffer of a program that has just started)</summary>
    procedure Clear;
    /// <summary>
    ///   A packet that arrived: its bytes go to the start of the buffer (at most 128); the bytes after its end
    ///   stay as they were
    /// </summary>
    procedure Load(const ABytes: TBytes);
    /// <summary>The first ALength bytes: the packet to send (greedcom.datalength)</summary>
    function ToBytes(ALength: Integer): TBytes;
    /// <summary>The first number of every packet: one of GREED_NET_EVENT_</summary>
    function EventId: Integer;
    /// <summary>The second number of every packet: who sent it</summary>
    function PlayerId: Integer;
    function ReadInit: TGreedNetInitEvent;
    procedure WriteInit(const AEvent: TGreedNetInitEvent);
    function ReadPlayer: TGreedPlayerEvent;
    procedure WritePlayer(const AEvent: TGreedPlayerEvent);
    function ReadSpawn: TGreedNetSpawnEvent;
    procedure WriteSpawn(const AEvent: TGreedNetSpawnEvent);
    function ReadPlayerOnly: TGreedNetPlayerOnlyEvent;
    procedure WritePlayerOnly(const AEvent: TGreedNetPlayerOnlyEvent);
    function ReadDoor: TGreedNetDoorEvent;
    procedure WriteDoor(const AEvent: TGreedNetDoorEvent);
    function ReadFrag: TGreedNetFragEvent;
    procedure WriteFrag(const AEvent: TGreedNetFragEvent);
    function ReadBonus: TGreedNetBonusEvent;
    procedure WriteBonus(const AEvent: TGreedNetBonusEvent);
    function ReadItem: TGreedNetItemEvent;
    procedure WriteItem(const AEvent: TGreedNetItemEvent);
    function ReadSound: TGreedNetSoundEvent;
    procedure WriteSound(const AEvent: TGreedNetSoundEvent);
    function ReadMessage: TGreedNetMessageEvent;
    procedure WriteMessage(const AEvent: TGreedNetMessageEvent);
  end;

implementation

const
  INT_SIZE = 4;
  OFFSET_ID = 0;
  OFFSET_PLAYER_ID = 4;
  /// ievent_t: four numbers, the name with its padding, two numbers
  INIT_NAME_OFFSET = 16;
  INIT_NAME_BYTES = 16;
  INIT_MAP_OFFSET = 32;
  /// mevent_t: two numbers, then the text with its padding
  MESSAGE_TEXT_OFFSET = 8;
  MESSAGE_TEXT_BYTES = 32;

{ TGreedNetPacketBuffer }

procedure TGreedNetPacketBuffer.Clear;
begin
  FillChar(FData, SizeOf(FData), 0);
end;

function TGreedNetPacketBuffer.GetInt(AOffset: Integer): Integer;
begin
  Result := Integer(Cardinal(FData[AOffset]) or (Cardinal(FData[AOffset + 1]) shl 8) or
    (Cardinal(FData[AOffset + 2]) shl 16) or (Cardinal(FData[AOffset + 3]) shl 24));
end;

procedure TGreedNetPacketBuffer.SetInt(AOffset, AValue: Integer);
var
  LValue: Cardinal;
begin
  LValue := Cardinal(AValue);
  FData[AOffset] := Byte(LValue and $FF);
  FData[AOffset + 1] := Byte((LValue shr 8) and $FF);
  FData[AOffset + 2] := Byte((LValue shr 16) and $FF);
  FData[AOffset + 3] := Byte(LValue shr 24);
end;

procedure TGreedNetPacketBuffer.GetInts(AOffset, ACount: Integer; AFirst: PInteger);
var
  LIndex: Integer;
begin
  // the records are packed and these fields are 32 bit numbers one after the other
  for LIndex := 0 to ACount - 1 do
  begin
    AFirst^ := GetInt(AOffset + LIndex * INT_SIZE);
    Inc(AFirst);
  end;
end;

procedure TGreedNetPacketBuffer.SetInts(AOffset, ACount: Integer; AFirst: PInteger);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    SetInt(AOffset + LIndex * INT_SIZE, AFirst^);
    Inc(AFirst);
  end;
end;

procedure TGreedNetPacketBuffer.Load(const ABytes: TBytes);
var
  LLength: Integer;
begin
  LLength := Length(ABytes);
  if LLength > GREED_NET_MAX_DATA then
    LLength := GREED_NET_MAX_DATA;
  if LLength > 0 then
    Move(ABytes[0], FData[0], LLength);
end;

function TGreedNetPacketBuffer.ToBytes(ALength: Integer): TBytes;
begin
  if (ALength < 0) or (ALength > GREED_NET_MAX_DATA) then
    raise EArgumentOutOfRangeException.Create('ALength');
  SetLength(Result, ALength);
  if ALength > 0 then
    Move(FData[0], Result[0], ALength);
end;

function TGreedNetPacketBuffer.EventId: Integer;
begin
  Result := GetInt(OFFSET_ID);
end;

function TGreedNetPacketBuffer.PlayerId: Integer;
begin
  Result := GetInt(OFFSET_PLAYER_ID);
end;

function TGreedNetPacketBuffer.ReadInit: TGreedNetInitEvent;
begin
  GetInts(0, 4, @Result.Id);
  Move(FData[INIT_NAME_OFFSET], Result.NetName, INIT_NAME_BYTES);
  GetInts(INIT_MAP_OFFSET, 2, @Result.Map);
end;

procedure TGreedNetPacketBuffer.WriteInit(const AEvent: TGreedNetInitEvent);
begin
  SetInts(0, 4, @AEvent.Id);
  Move(AEvent.NetName, FData[INIT_NAME_OFFSET], INIT_NAME_BYTES);
  SetInts(INIT_MAP_OFFSET, 2, @AEvent.Map);
end;

function TGreedNetPacketBuffer.ReadPlayer: TGreedPlayerEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WritePlayer(const AEvent: TGreedPlayerEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadSpawn: TGreedNetSpawnEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WriteSpawn(const AEvent: TGreedNetSpawnEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadPlayerOnly: TGreedNetPlayerOnlyEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WritePlayerOnly(const AEvent: TGreedNetPlayerOnlyEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadDoor: TGreedNetDoorEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WriteDoor(const AEvent: TGreedNetDoorEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadFrag: TGreedNetFragEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WriteFrag(const AEvent: TGreedNetFragEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadBonus: TGreedNetBonusEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WriteBonus(const AEvent: TGreedNetBonusEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadItem: TGreedNetItemEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WriteItem(const AEvent: TGreedNetItemEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadSound: TGreedNetSoundEvent;
begin
  GetInts(0, SizeOf(Result) div INT_SIZE, @Result.Id);
end;

procedure TGreedNetPacketBuffer.WriteSound(const AEvent: TGreedNetSoundEvent);
begin
  SetInts(0, SizeOf(AEvent) div INT_SIZE, @AEvent.Id);
end;

function TGreedNetPacketBuffer.ReadMessage: TGreedNetMessageEvent;
begin
  GetInts(0, 2, @Result.Id);
  Move(FData[MESSAGE_TEXT_OFFSET], Result.Text, MESSAGE_TEXT_BYTES);
end;

procedure TGreedNetPacketBuffer.WriteMessage(const AEvent: TGreedNetMessageEvent);
begin
  SetInts(0, 2, @AEvent.Id);
  Move(AEvent.Text, FData[MESSAGE_TEXT_OFFSET], MESSAGE_TEXT_BYTES);
end;

end.
