{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorLzssWordAligned                }
{  (idCompressor_LZSS_WordAligned)                                             }
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
unit DelphiDoom.Compression.LzssWordAligned;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Compression.Lzss;

type
  /// <summary>
  ///   idCompressor_LZSS_WordAligned: LZSS that outputs word aligned data: every item is a length word
  ///   (0 for a literal) followed by the offset (two words) or the literal word, with no flag bit.
  /// </summary>
  TCompressorLzssWordAligned = class(TCompressorLzss)
  strict protected
    procedure CompressBlock; override;
    procedure DecompressBlock; override;
  public
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
  end;

implementation

{ TCompressorLzssWordAligned }

procedure TCompressorLzssWordAligned.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
begin
  inherited Init(AStream, ACompress, AWordLength);
  FOffsetBits := 2 * AWordLength;
  FLengthBits := AWordLength;
  FMinMatchWords := (FOffsetBits + FLengthBits + AWordLength) div AWordLength;
  FBlockSize := 0;
  FBlockIndex := 0;
end;

procedure TCompressorLzssWordAligned.CompressBlock;
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
      WriteBits(LNumWords - (FMinMatchWords - 1), FLengthBits);
      WriteBits(LStartWord - LWordOffset, FOffsetBits);
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
      WriteBits(0, FLengthBits);
      WriteBits(LStartValue, FWordLength);
      AddToHash(LStartWord, LStartValue and LZSS_HASH_MASK);
      Inc(LStartWord);
    end;
  end;
  FBlockSize := 0;
end;

procedure TCompressorLzssWordAligned.DecompressBlock;
var
  LIndex, LOffset, LStartWord, LNumWords: Integer;
begin
  InitDecompress(PByte(FBlock), LZSS_BLOCK_SIZE);
  LStartWord := 0;
  while (FWriteByte < FWriteLength) and (FReadLength >= 0) do
  begin
    LNumWords := ReadBits(FLengthBits);
    if LNumWords <> 0 then
    begin
      Inc(LNumWords, FMinMatchWords - 1);
      LOffset := LStartWord - ReadBits(FOffsetBits);
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

end.
