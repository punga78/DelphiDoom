{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorLzw (idCompressor_LZW)         }
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
unit DelphiDoom.Compression.Lzw;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.IdLib.Containers.HashIndex, DelphiDoom.Compression.BitStream;

const
  LZW_BLOCK_SIZE = 32767;
  LZW_START_BITS = 9;
  LZW_FIRST_CODE = 1 shl (LZW_START_BITS - 1);
  LZW_DICT_BITS = 12;
  LZW_DICT_SIZE = 1 shl LZW_DICT_BITS;

type
  /// <summary>
  ///   idCompressor_LZW: the scheme of GIF without the clear and end codes (the end is the end of the
  ///   input and the clear happens when the dictionary of 4096 entries is full). The code size grows from
  ///   9 to 12 bits as the dictionary fills. The word length is ignored (symbols are bytes). The
  ///   dictionary index is the <c>TIdHashIndex</c> of the idLib port. Unlike the other compressors
  ///   <c>Write</c> does not check the direction.
  /// </summary>
  TCompressorLzw = class(TCompressorBitStream)
  strict private
    FDictK: array[0..LZW_DICT_SIZE - 1] of Integer;
    FDictW: array[0..LZW_DICT_SIZE - 1] of Integer;
    FIndex: TIdHashIndex;
    FNextCode: Integer;
    FCodeBits: Integer;
    FBlock: TBytes;
    FBlockSize: Integer;
    FBlockIndex: Integer;
    // used by the compressor
    FW: Integer;
    // used by the decompressor
    FOldCode: Integer;
    function AddToDict(AW, AK: Integer): Integer;
    function Lookup(AW, AK: Integer): Integer;
    function BumpBits: Boolean;
    function WriteChain(ACode: Integer): Integer;
    procedure DecompressBlock;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
    procedure FinishCompress; override;
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{$POINTERMATH ON}

{ TCompressorLzw }

constructor TCompressorLzw.Create;
begin
  inherited Create;
  FIndex := TIdHashIndex.Create;
  SetLength(FBlock, LZW_BLOCK_SIZE);
  FillChar(FBlock[0], LZW_BLOCK_SIZE, 0);
end;

destructor TCompressorLzw.Destroy;
begin
  FIndex.Free;
  inherited Destroy;
end;

procedure TCompressorLzw.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
var
  LIndex: Integer;
begin
  inherited Init(AStream, ACompress, AWordLength);
  for LIndex := 0 to LZW_FIRST_CODE - 1 do
  begin
    FDictK[LIndex] := LIndex;
    FDictW[LIndex] := -1;
  end;
  FIndex.Clear;
  FNextCode := LZW_FIRST_CODE;
  FCodeBits := LZW_START_BITS;
  FBlockSize := 0;
  FBlockIndex := 0;
  FW := -1;
  FOldCode := -1;
end;

function TCompressorLzw.Read(AData: PByte; ALength: Integer): Integer;
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

function TCompressorLzw.Lookup(AW, AK: Integer): Integer;
var
  LIndex: Integer;
begin
  if AW = -1 then
    Exit(AK);
  LIndex := FIndex.First(AW xor AK);
  while LIndex >= 0 do
  begin
    if (FDictK[LIndex] = AK) and (FDictW[LIndex] = AW) then
      Exit(LIndex);
    LIndex := FIndex.Next(LIndex);
  end;
  Result := -1;
end;

function TCompressorLzw.AddToDict(AW, AK: Integer): Integer;
begin
  FDictK[FNextCode] := AK;
  FDictW[FNextCode] := AW;
  FIndex.Add(AW xor AK, FNextCode);
  Result := FNextCode;
  Inc(FNextCode);
end;

function TCompressorLzw.BumpBits: Boolean;
begin
  // possibly increments the code size; true if the dictionary was cleared
  Result := False;
  if FNextCode = (1 shl FCodeBits) then
  begin
    Inc(FCodeBits);
    if FCodeBits > LZW_DICT_BITS then
    begin
      FNextCode := LZW_FIRST_CODE;
      FCodeBits := LZW_START_BITS;
      FIndex.Clear;
      Result := True;
    end;
  end;
end;

procedure TCompressorLzw.FinishCompress;
begin
  WriteBits(FW, FCodeBits);
  inherited FinishCompress;
end;

function TCompressorLzw.Write(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LK, LCode: Integer;
begin
  InitCompress(AData, ALength);
  for LIndex := 0 to ALength - 1 do
  begin
    LK := ReadBits(8);
    LCode := Lookup(FW, LK);
    if LCode >= 0 then
      FW := LCode
    else
    begin
      WriteBits(FW, FCodeBits);
      if not BumpBits then
        AddToDict(FW, LK);
      FW := LK;
    end;
  end;
  Result := ALength;
end;

function TCompressorLzw.WriteChain(ACode: Integer): Integer;
var
  LChain: array[0..LZW_DICT_SIZE - 1] of Byte;
  LIndex: Integer;
begin
  // the chain is stored backwards: it goes to a buffer, then out in reverse
  LIndex := 0;
  repeat
    LChain[LIndex] := Byte(FDictK[ACode]);
    Inc(LIndex);
    ACode := FDictW[ACode];
  until ACode < 0;
  Dec(LIndex);
  Result := LChain[LIndex];
  while LIndex >= 0 do
  begin
    WriteBits(LChain[LIndex], 8);
    Dec(LIndex);
  end;
end;

procedure TCompressorLzw.DecompressBlock;
var
  LCode, LFirstChar: Integer;
begin
  InitDecompress(PByte(FBlock), LZW_BLOCK_SIZE);
  while (FWriteByte < FWriteLength - LZW_DICT_SIZE) and (FReadLength > 0) do
  begin
    LCode := ReadBits(FCodeBits);
    if FReadLength = 0 then
      Break;
    if FOldCode = -1 then
    begin
      WriteBits(LCode, 8);
      FOldCode := LCode;
      Continue;
    end;
    if LCode >= FNextCode then
    begin
      LFirstChar := WriteChain(FOldCode);
      WriteBits(LFirstChar, 8);
    end
    else
      LFirstChar := WriteChain(LCode);
    AddToDict(FOldCode, LFirstChar);
    if BumpBits then
      FOldCode := -1
    else
      FOldCode := LCode;
  end;
  if FWriteByte < LZW_BLOCK_SIZE then
    FBlockSize := FWriteByte
  else
    FBlockSize := LZW_BLOCK_SIZE;
end;

end.
