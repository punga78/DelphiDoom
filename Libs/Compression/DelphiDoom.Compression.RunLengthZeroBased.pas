{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorRunLengthZeroBased             }
{  (idCompressor_RunLength_ZeroBased)                                          }
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
unit DelphiDoom.Compression.RunLengthZeroBased;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Compression.BitStream;

type
  /// <summary>
  ///   idCompressor_RunLength_ZeroBased: run length compression of the zero words only, for data with a lot
  ///   of zero bits. A run of zeros is the zero word and the length minus one. Like the other run length
  ///   compressor it reads one word past the data in every <c>Write</c>.
  /// </summary>
  TCompressorRunLengthZeroBased = class(TCompressorBitStream)
  public
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{ TCompressorRunLengthZeroBased }

function TCompressorRunLengthZeroBased.Write(AData: PByte; ALength: Integer): Integer;
var
  LBits, LCount: Integer;
  LLimit: Int64;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  InitCompress(AData, ALength);
  LLimit := Int64(1) shl FWordLength;
  while FReadByte <= FReadLength do
  begin
    LCount := 0;
    LBits := ReadBits(FWordLength);
    while (LBits = 0) and (LCount < LLimit) do
    begin
      Inc(LCount);
      LBits := ReadBits(FWordLength);
    end;
    if LCount <> 0 then
    begin
      WriteBits(0, FWordLength);
      WriteBits(LCount - 1, FWordLength);
      UnreadBits(FWordLength);
    end
    else
      WriteBits(LBits, FWordLength);
  end;
  Result := ALength;
end;

function TCompressorRunLengthZeroBased.Read(AData: PByte; ALength: Integer): Integer;
var
  LBits, LCount: Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  InitDecompress(AData, ALength);
  while (FWriteByte <= FWriteLength) and (FReadLength >= 0) do
  begin
    LBits := ReadBits(FWordLength);
    if LBits = 0 then
    begin
      LCount := ReadBits(FWordLength) + 1;
      while LCount > 0 do
      begin
        Dec(LCount);
        WriteBits(0, FWordLength);
      end;
    end
    else
      WriteBits(LBits, FWordLength);
  end;
  Result := FWriteByte;
end;

end.
