{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorBitStream                      }
{  (idCompressor_BitStream)                                                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): framework\Compressor.cpp }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Compression.BitStream;

{$Q-}
{$R-}
{$POINTERMATH ON}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Compression.Types, DelphiDoom.Compression.None;

type
  /// <summary>
  ///   idCompressor_BitStream: the base of the compressors that work on words of AWordLength bits. It
  ///   keeps a read cursor and a write cursor in bits (least significant bit first) over either the
  ///   caller's memory or its own 64 KiB buffer, which is flushed to or refilled from the stream. Used as
  ///   a compressor it copies the bytes (and so tests the bit machinery).
  ///   <para>The cursors run past the end of the input without error, as in the original: a read beyond
  ///   the data gives zero bits (when it reads the caller's memory) or the stale content of the buffer
  ///   (when it reads the stream), and the decompressors rely on the caller asking for the right length.
  ///   The buffer starts zeroed (the original's is uninitialised).</para>
  /// </summary>
  TCompressorBitStream = class(TCompressorNone)
  strict protected
    FBuffer: TBytes;
    FWordLength: Integer;
    FReadTotalBytes: Integer;
    FReadLength: Integer;
    FReadByte: Integer;
    FReadBit: Integer;
    FReadData: PByte;
    FWriteTotalBytes: Integer;
    FWriteLength: Integer;
    FWriteByte: Integer;
    FWriteBit: Integer;
    FWriteData: PByte;
    procedure InitCompress(AInData: PByte; AInLength: Integer);
    procedure InitDecompress(AOutData: PByte; AOutLength: Integer);
    procedure WriteBits(AValue, ANumBits: Integer);
    function ReadBits(ANumBits: Integer): Integer;
    procedure UnreadBits(ANumBits: Integer);
    /// <summary>The number of bits, up to AMaxBits, in which the two bit strings are equal</summary>
    function Compare(ASource1: PByte; ABitPtr1: Integer; ASource2: PByte; ABitPtr2: Integer;
      AMaxBits: Integer): Integer;
  public
    constructor Create;
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
    procedure FinishCompress; override;
    function GetCompressionRatio: Single; override;
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{ TCompressorBitStream }

constructor TCompressorBitStream.Create;
begin
  inherited Create;
  SetLength(FBuffer, COMPRESSOR_BUFFER_SIZE);
  FillChar(FBuffer[0], COMPRESSOR_BUFFER_SIZE, 0);
end;

procedure TCompressorBitStream.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
begin
  if (AWordLength < 1) or (AWordLength > 32) then
    raise ECompressionException.CreateFmt(SCompressorBadWordLength, [AWordLength]);
  inherited Init(AStream, ACompress, AWordLength);
  FWordLength := AWordLength;
  FReadTotalBytes := 0;
  FReadLength := 0;
  FReadByte := 0;
  FReadBit := 0;
  FReadData := nil;
  FWriteTotalBytes := 0;
  FWriteLength := 0;
  FWriteByte := 0;
  FWriteBit := 0;
  FWriteData := nil;
end;

procedure TCompressorBitStream.InitCompress(AInData: PByte; AInLength: Integer);
begin
  FReadLength := AInLength;
  FReadByte := 0;
  FReadBit := 0;
  FReadData := AInData;
  if FWriteLength = 0 then
  begin
    FWriteLength := COMPRESSOR_BUFFER_SIZE;
    FWriteByte := 0;
    FWriteBit := 0;
    FWriteData := PByte(FBuffer);
  end;
end;

procedure TCompressorBitStream.InitDecompress(AOutData: PByte; AOutLength: Integer);
begin
  if FReadLength = 0 then
  begin
    RequireStream;
    FReadLength := FStream.Read(FBuffer[0], COMPRESSOR_BUFFER_SIZE);
    FReadByte := 0;
    FReadBit := 0;
    FReadData := PByte(FBuffer);
  end;
  FWriteLength := AOutLength;
  FWriteByte := 0;
  FWriteBit := 0;
  FWriteData := AOutData;
end;

procedure TCompressorBitStream.WriteBits(AValue, ANumBits: Integer);
var
  LPut, LFraction: Integer;
begin
  // short circuit for writing single bytes at a time
  if (FWriteBit = 0) and (ANumBits = 8) and (FWriteByte < FWriteLength) then
  begin
    Inc(FWriteByte);
    Inc(FWriteTotalBytes);
    FWriteData[FWriteByte - 1] := Byte(AValue);
    Exit;
  end;
  while ANumBits <> 0 do
  begin
    if FWriteBit = 0 then
    begin
      if FWriteByte >= FWriteLength then
      begin
        if FWriteData = PByte(FBuffer) then
        begin
          FStream.Write(FBuffer[0], FWriteByte);
          FWriteByte := 0;
        end
        else
        begin
          // the caller's memory is full: the cursor goes on but nothing is stored
          LPut := ANumBits;
          FWriteBit := LPut and 7;
          Inc(FWriteByte, (LPut shr 3) + Ord(FWriteBit <> 0));
          Inc(FWriteTotalBytes, (LPut shr 3) + Ord(FWriteBit <> 0));
          Exit;
        end;
      end;
      FWriteData[FWriteByte] := 0;
      Inc(FWriteByte);
      Inc(FWriteTotalBytes);
    end;
    LPut := 8 - FWriteBit;
    if LPut > ANumBits then
      LPut := ANumBits;
    LFraction := AValue and ((1 shl LPut) - 1);
    FWriteData[FWriteByte - 1] := FWriteData[FWriteByte - 1] or Byte(LFraction shl FWriteBit);
    Dec(ANumBits, LPut);
    AValue := Integer(Cardinal(AValue) shr LPut);
    FWriteBit := (FWriteBit + LPut) and 7;
  end;
end;

function TCompressorBitStream.ReadBits(ANumBits: Integer): Integer;
var
  LValueBits, LGet, LFraction: Integer;
begin
  Result := 0;
  LValueBits := 0;
  // short circuit for reading single bytes at a time
  if (FReadBit = 0) and (ANumBits = 8) and (FReadByte < FReadLength) then
  begin
    Inc(FReadByte);
    Inc(FReadTotalBytes);
    Exit(FReadData[FReadByte - 1]);
  end;
  while LValueBits < ANumBits do
  begin
    if FReadBit = 0 then
    begin
      if FReadByte >= FReadLength then
      begin
        if FReadData = PByte(FBuffer) then
        begin
          FReadLength := FStream.Read(FBuffer[0], COMPRESSOR_BUFFER_SIZE);
          FReadByte := 0;
        end
        else
        begin
          // past the end of the caller's memory: zero bits, the cursor goes on
          LGet := ANumBits - LValueBits;
          FReadBit := LGet and 7;
          Inc(FReadByte, (LGet shr 3) + Ord(FReadBit <> 0));
          Inc(FReadTotalBytes, (LGet shr 3) + Ord(FReadBit <> 0));
          Exit(Result);
        end;
      end;
      Inc(FReadByte);
      Inc(FReadTotalBytes);
    end;
    LGet := 8 - FReadBit;
    if LGet > (ANumBits - LValueBits) then
      LGet := ANumBits - LValueBits;
    LFraction := FReadData[FReadByte - 1];
    LFraction := LFraction shr FReadBit;
    LFraction := LFraction and ((1 shl LGet) - 1);
    Result := Result or (LFraction shl LValueBits);
    Inc(LValueBits, LGet);
    FReadBit := (FReadBit + LGet) and 7;
  end;
end;

procedure TCompressorBitStream.UnreadBits(ANumBits: Integer);
begin
  Dec(FReadByte, ANumBits shr 3);
  Dec(FReadTotalBytes, ANumBits shr 3);
  if FReadBit = 0 then
    FReadBit := 8 - (ANumBits and 7)
  else
  begin
    Dec(FReadBit, ANumBits and 7);
    if FReadBit <= 0 then
    begin
      Dec(FReadByte);
      Dec(FReadTotalBytes);
      FReadBit := (FReadBit + 8) and 7;
    end;
  end;
  if FReadByte < 0 then
  begin
    FReadByte := 0;
    FReadBit := 0;
  end;
end;

function TCompressorBitStream.Compare(ASource1: PByte; ABitPtr1: Integer; ASource2: PByte;
  ABitPtr2: Integer; AMaxBits: Integer): Integer;
var
  LIndex, LBits, LBitsRemain, LRemain, LFinalBits: Integer;
  LPointer1, LPointer2: PByte;
begin
  // if the two bit pointers are aligned then the bytes can be compared whole
  if ((ABitPtr1 and 7) = (ABitPtr2 and 7)) and (AMaxBits > 16) then
  begin
    LPointer1 := @ASource1[ABitPtr1 shr 3];
    LPointer2 := @ASource2[ABitPtr2 shr 3];
    LBits := 0;
    LBitsRemain := AMaxBits;
    // compare the first couple bits (if any)
    if (ABitPtr1 and 7) <> 0 then
    begin
      for LIndex := (ABitPtr1 and 7) to 7 do
      begin
        if (((LPointer1^ shr LIndex) xor (LPointer2^ shr LIndex)) and 1) <> 0 then
          Exit(LBits);
        Inc(LBits);
        Dec(LBitsRemain);
      end;
      Inc(LPointer1);
      Inc(LPointer2);
    end;
    LRemain := LBitsRemain shr 3;
    // compare the remaining bytes
    while (LRemain > 0) and (LPointer1^ = LPointer2^) do
    begin
      Inc(LPointer1);
      Inc(LPointer2);
      Dec(LRemain);
      Inc(LBits, 8);
    end;
    // compare the last couple of bits (if any)
    LFinalBits := 8;
    if LRemain = 0 then
      LFinalBits := LBitsRemain and 7;
    for LIndex := 0 to LFinalBits - 1 do
    begin
      if (((LPointer1^ shr LIndex) xor (LPointer2^ shr LIndex)) and 1) <> 0 then
        Exit(LBits);
      Inc(LBits);
    end;
    Exit(LBits);
  end;
  LIndex := 0;
  while LIndex < AMaxBits do
  begin
    if (((ASource1[ABitPtr1 shr 3] shr (ABitPtr1 and 7)) xor (ASource2[ABitPtr2 shr 3] shr (ABitPtr2 and 7))) and 1) <> 0 then
      Break;
    Inc(ABitPtr1);
    Inc(ABitPtr2);
    Inc(LIndex);
  end;
  Result := LIndex;
end;

function TCompressorBitStream.Write(AData: PByte; ALength: Integer): Integer;
var
  LIndex: Integer;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  InitCompress(AData, ALength);
  for LIndex := 0 to ALength - 1 do
    WriteBits(ReadBits(8), 8);
  Result := ALength;
end;

procedure TCompressorBitStream.FinishCompress;
begin
  if not FCompress then
    Exit;
  if FWriteByte <> 0 then
    FStream.Write(FBuffer[0], FWriteByte);
  FWriteLength := 0;
  FWriteByte := 0;
  FWriteBit := 0;
end;

function TCompressorBitStream.Read(AData: PByte; ALength: Integer): Integer;
var
  LIndex: Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  InitDecompress(AData, ALength);
  LIndex := 0;
  while (LIndex < ALength) and (FReadLength >= 0) do
  begin
    WriteBits(ReadBits(8), 8);
    Inc(LIndex);
  end;
  Result := LIndex;
end;

function TCompressorBitStream.GetCompressionRatio: Single;
begin
  if FCompress then
    Result := Percent(FReadTotalBytes - FWriteTotalBytes, FReadTotalBytes)
  else
    Result := Percent(FWriteTotalBytes - FReadTotalBytes, FWriteTotalBytes);
end;

end.
