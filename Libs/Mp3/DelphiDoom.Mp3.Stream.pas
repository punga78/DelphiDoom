{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - growing input buffer read by the bit stream               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Stream;

interface

uses
  d_delphi;

type
  /// <summary>
  ///   Sequential byte source for TBitStream. The caller appends blocks of MP3
  ///   data with Append; the decoder consumes them in order. Bytes already
  ///   consumed are released when the buffer has to grow
  /// </summary>
  /// <remarks>
  ///   TBitStream only moves forward (plus the Seek(0, FromBeginning) that its
  ///   Restart method issues, which here means "nothing to rewind": the
  ///   stream keeps no history). Seeking backwards is possible only inside the
  ///   bytes still retained
  /// </remarks>
  TMp3FeedStream = class(TDStream)
  private
    FData: TArray<Byte>;
    FCount: Integer;
    FPosition: Integer;
    FBase: Int64;
    procedure Compact;
    class function ClampToLongint(AValue: Int64): Longint; static;
  public
    /// <summary>
    ///   Appends ASize bytes copied from AData
    /// </summary>
    procedure Append(AData: Pointer; ASize: Integer);

    /// <summary>
    ///   Pointer to the first byte not consumed yet (nil when the buffer is
    ///   empty); valid until the next Append
    /// </summary>
    function Peek: PByte;

    /// <summary>
    ///   Bytes appended and not consumed yet
    /// </summary>
    function Available: Integer;

    /// <summary>
    ///   Consumes ACount bytes (at most Available)
    /// </summary>
    procedure Skip(ACount: Integer);

    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    function Size: Longint; override;
    function Position: Integer; override;
  end;

implementation

const
  // Bytes kept before the read position when the buffer is compacted, so that
  // the Seek(-3, FromCurrent) of the header search still works
  RETAINED_BYTES = 3;

  MIN_CAPACITY = 16 * 1024;

{ TMp3FeedStream }

class function TMp3FeedStream.ClampToLongint(AValue: Int64): Longint;
begin
  if AValue > High(Longint) then
    Result := High(Longint)
  else
    Result := Longint(AValue);
end;

procedure TMp3FeedStream.Compact;
var
  LDropped: Integer;
begin
  LDropped := FPosition - RETAINED_BYTES;
  if LDropped > 0 then
  begin
    Move((PByte(FData) + LDropped)^, PByte(FData)^, FCount - LDropped);
    Dec(FCount, LDropped);
    Dec(FPosition, LDropped);
    Inc(FBase, LDropped);
  end;
end;

procedure TMp3FeedStream.Append(AData: Pointer; ASize: Integer);
var
  LCapacity: Integer;
begin
  if ASize <= 0 then
    Exit;

  if FCount + ASize > Length(FData) then
  begin
    Compact;
    if FCount + ASize > Length(FData) then
    begin
      LCapacity := Length(FData) * 2;
      if LCapacity < FCount + ASize then
        LCapacity := FCount + ASize;
      if LCapacity < MIN_CAPACITY then
        LCapacity := MIN_CAPACITY;
      SetLength(FData, LCapacity);
    end;
  end;

  Move(AData^, (PByte(FData) + FCount)^, ASize);
  Inc(FCount, ASize);
end;

function TMp3FeedStream.Peek: PByte;
begin
  if FCount = 0 then
    Result := nil
  else
    Result := PByte(FData) + FPosition;
end;

function TMp3FeedStream.Available: Integer;
begin
  Result := FCount - FPosition;
end;

procedure TMp3FeedStream.Skip(ACount: Integer);
begin
  if ACount > Available then
    ACount := Available;
  if ACount > 0 then
    Inc(FPosition, ACount);
end;

function TMp3FeedStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := Count;
  if Result > Available then
    Result := Available;
  if Result <= 0 then
    Result := 0
  else
  begin
    Move((PByte(FData) + FPosition)^, Buffer, Result);
    Inc(FPosition, Result);
  end;
end;

function TMp3FeedStream.Write(const Buffer; Count: Longint): Longint;
begin
  // The stream is fed only through Append
  Result := 0;
  FIOResult := 1;
end;

function TMp3FeedStream.Seek(Offset: Longint; Origin: Word): Longint;
var
  LTarget: Int64;
begin
  LTarget := FPosition;
  case Origin of
    sFromBeginning:
      // Offset 0 is the Restart of TBitStream: no history, nothing to rewind
      if Offset <> 0 then
        LTarget := Int64(Offset) - FBase;
    sFromCurrent:
      LTarget := Int64(FPosition) + Offset;
    sFromEnd:
      LTarget := Int64(FCount) - Offset;
  end;

  if LTarget < 0 then
    LTarget := 0
  else if LTarget > FCount then
    LTarget := FCount;
  FPosition := Integer(LTarget);
  Result := Position;
end;

function TMp3FeedStream.Size: Longint;
begin
  // Total bytes ever appended
  Result := ClampToLongint(FBase + FCount);
end;

function TMp3FeedStream.Position: Integer;
begin
  Result := ClampToLongint(FBase + FPosition);
end;

end.
