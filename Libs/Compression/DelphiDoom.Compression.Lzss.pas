{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorLzss (idCompressor_LZSS)       }
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
unit DelphiDoom.Compression.Lzss;

{$Q-}
{$R-}
{$POINTERMATH ON}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Compression.BitStream;

const
  LZSS_BLOCK_SIZE = 65535;
  LZSS_HASH_BITS = 10;
  LZSS_HASH_SIZE = 1 shl LZSS_HASH_BITS;
  LZSS_HASH_MASK = (1 shl LZSS_HASH_BITS) - 1;
  LZSS_OFFSET_BITS = 11;
  LZSS_LENGTH_BITS = 5;

type
  /// <summary>
  ///   idCompressor_LZSS: LZ77 with a flag bit that tells a literal word from an offset/length pair
  ///   (Storer and Szymanski), on words of AWordLength bits, in blocks of 65535 bytes: the dictionary
  ///   is the block itself and every block starts a new one. A match is found through a hash of the first
  ///   10 bits of the word chain. The offset takes 11 bits and the length 5 (the shortest match is the
  ///   number of words that costs more than a pair). Like all the decompressors of the bit stream family
  ///   it decodes a whole block at once, so it needs the stream to hold complete blocks.
  /// </summary>
  TCompressorLzss = class(TCompressorBitStream)
  strict protected
    FOffsetBits: Integer;
    FLengthBits: Integer;
    FMinMatchWords: Integer;
    FBlock: TBytes;
    FBlockSize: Integer;
    FBlockIndex: Integer;
    FHashTable: array[0..LZSS_HASH_SIZE - 1] of Integer;
    FHashNext: TArray<Integer>;
    function FindMatch(AStartWord, AStartValue: Integer; out AWordOffset, ANumWords: Integer): Boolean;
    procedure AddToHash(AIndex, AHash: Integer);
    function GetWordFromBlock(AWordOffset: Integer): Integer;
    procedure ResetHashes;
    procedure CompressBlock; virtual;
    procedure DecompressBlock; virtual;
  public
    constructor Create;
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
    procedure FinishCompress; override;
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{ TCompressorLzss }

constructor TCompressorLzss.Create;
begin
  inherited Create;
  SetLength(FBlock, LZSS_BLOCK_SIZE);
  FillChar(FBlock[0], LZSS_BLOCK_SIZE, 0);
  SetLength(FHashNext, LZSS_BLOCK_SIZE * 8);
end;

procedure TCompressorLzss.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
begin
  inherited Init(AStream, ACompress, AWordLength);
  FOffsetBits := LZSS_OFFSET_BITS;
  FLengthBits := LZSS_LENGTH_BITS;
  FMinMatchWords := (FOffsetBits + FLengthBits + AWordLength) div AWordLength;
  FBlockSize := 0;
  FBlockIndex := 0;
end;

procedure TCompressorLzss.ResetHashes;
var
  LIndex: Integer;
begin
  for LIndex := 0 to LZSS_HASH_SIZE - 1 do
    FHashTable[LIndex] := -1;
  for LIndex := 0 to System.Length(FHashNext) - 1 do
    FHashNext[LIndex] := -1;
end;

function TCompressorLzss.FindMatch(AStartWord, AStartValue: Integer; out AWordOffset, ANumWords: Integer): Boolean;
var
  LIndex, LCount, LHash, LBottom, LMaxBits, LLimit: Integer;
begin
  AWordOffset := AStartWord;
  ANumWords := FMinMatchWords - 1;
  LBottom := AStartWord - ((1 shl FOffsetBits) - 1);
  if LBottom < 0 then
    LBottom := 0;
  LMaxBits := (FBlockSize shl 3) - AStartWord * FWordLength;
  LHash := AStartValue and LZSS_HASH_MASK;
  LIndex := FHashTable[LHash];
  while LIndex >= LBottom do
  begin
    LLimit := (AStartWord - LIndex) * FWordLength;
    if LMaxBits < LLimit then
      LLimit := LMaxBits;
    LCount := Compare(PByte(FBlock), LIndex * FWordLength, PByte(FBlock), AStartWord * FWordLength, LLimit);
    if LCount > ANumWords * FWordLength then
    begin
      ANumWords := LCount div FWordLength;
      AWordOffset := LIndex;
      if ANumWords > ((1 shl FLengthBits) - 1 + FMinMatchWords) - 1 then
      begin
        ANumWords := ((1 shl FLengthBits) - 1 + FMinMatchWords) - 1;
        Break;
      end;
    end;
    LIndex := FHashNext[LIndex];
  end;
  Result := ANumWords >= FMinMatchWords;
end;

procedure TCompressorLzss.AddToHash(AIndex, AHash: Integer);
begin
  FHashNext[AIndex] := FHashTable[AHash];
  FHashTable[AHash] := AIndex;
end;

function TCompressorLzss.GetWordFromBlock(AWordOffset: Integer): Integer;
var
  LBlockBit, LBlockByte, LValueBits, LGet, LFraction: Integer;
begin
  LBlockBit := (AWordOffset * FWordLength) and 7;
  LBlockByte := (AWordOffset * FWordLength) shr 3;
  if LBlockBit <> 0 then
    Inc(LBlockByte);
  Result := 0;
  LValueBits := 0;
  while LValueBits < FWordLength do
  begin
    if LBlockBit = 0 then
    begin
      if LBlockByte >= LZSS_BLOCK_SIZE then
        Exit(Result);
      Inc(LBlockByte);
    end;
    LGet := 8 - LBlockBit;
    if LGet > (FWordLength - LValueBits) then
      LGet := FWordLength - LValueBits;
    LFraction := FBlock[LBlockByte - 1];
    LFraction := LFraction shr LBlockBit;
    LFraction := LFraction and ((1 shl LGet) - 1);
    Result := Result or (LFraction shl LValueBits);
    Inc(LValueBits, LGet);
    LBlockBit := (LBlockBit + LGet) and 7;
  end;
end;

procedure TCompressorLzss.CompressBlock;
var
  LIndex, LStartWord, LStartValue, LWordOffset, LNumWords: Integer;
begin
  InitCompress(PByte(FBlock), FBlockSize);
  ResetHashes;
  LStartWord := 0;
  while FReadByte < FReadLength do
  begin
    LStartValue := ReadBits(FWordLength);
    if FindMatch(LStartWord, LStartValue, LWordOffset, LNumWords) then
    begin
      WriteBits(1, 1);
      WriteBits(LStartWord - LWordOffset, FOffsetBits);
      WriteBits(LNumWords - FMinMatchWords, FLengthBits);
      UnreadBits(FWordLength);
      for LIndex := 0 to LNumWords - 1 do
      begin
        LStartValue := ReadBits(FWordLength);
        AddToHash(LStartWord, LStartValue and LZSS_HASH_MASK);
        Inc(LStartWord);
      end;
    end
    else
    begin
      WriteBits(0, 1);
      WriteBits(LStartValue, FWordLength);
      AddToHash(LStartWord, LStartValue and LZSS_HASH_MASK);
      Inc(LStartWord);
    end;
  end;
  FBlockSize := 0;
end;

procedure TCompressorLzss.DecompressBlock;
var
  LIndex, LOffset, LStartWord, LNumWords: Integer;
begin
  InitDecompress(PByte(FBlock), LZSS_BLOCK_SIZE);
  LStartWord := 0;
  while (FWriteByte < FWriteLength) and (FReadLength >= 0) do
  begin
    if ReadBits(1) <> 0 then
    begin
      LOffset := LStartWord - ReadBits(FOffsetBits);
      LNumWords := ReadBits(FLengthBits) + FMinMatchWords;
      for LIndex := 0 to LNumWords - 1 do
      begin
        WriteBits(GetWordFromBlock(LOffset + LIndex), FWordLength);
        Inc(LStartWord);
      end;
    end
    else
    begin
      WriteBits(ReadBits(FWordLength), FWordLength);
      Inc(LStartWord);
    end;
  end;
  if FWriteByte < LZSS_BLOCK_SIZE then
    FBlockSize := FWriteByte
  else
    FBlockSize := LZSS_BLOCK_SIZE;
end;

function TCompressorLzss.Write(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LCount: Integer;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  LIndex := 0;
  while LIndex < ALength do
  begin
    LCount := LZSS_BLOCK_SIZE - FBlockSize;
    if ALength - LIndex >= LCount then
    begin
      Move(AData[LIndex], FBlock[FBlockSize], LCount);
      FBlockSize := LZSS_BLOCK_SIZE;
      CompressBlock;
      FBlockSize := 0;
    end
    else
    begin
      Move(AData[LIndex], FBlock[FBlockSize], ALength - LIndex);
      LCount := ALength - LIndex;
      Inc(FBlockSize, LCount);
    end;
    Inc(LIndex, LCount);
  end;
  Result := ALength;
end;

procedure TCompressorLzss.FinishCompress;
begin
  if not FCompress then
    Exit;
  if FBlockSize <> 0 then
    CompressBlock;
  inherited FinishCompress;
end;

function TCompressorLzss.Read(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LCount: Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  if FBlockSize = 0 then
    DecompressBlock;
  LIndex := 0;
  while LIndex < ALength do
  begin
    if FBlockSize = 0 then
      Exit(LIndex);
    LCount := FBlockSize - FBlockIndex;
    if ALength - LIndex >= LCount then
    begin
      Move(FBlock[FBlockIndex], AData[LIndex], LCount);
      DecompressBlock;
      FBlockIndex := 0;
    end
    else
    begin
      Move(FBlock[FBlockIndex], AData[LIndex], ALength - LIndex);
      LCount := ALength - LIndex;
      Inc(FBlockIndex, LCount);
    end;
    Inc(LIndex, LCount);
  end;
  Result := ALength;
end;

end.
