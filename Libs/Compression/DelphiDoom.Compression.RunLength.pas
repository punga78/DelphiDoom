{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorRunLength                      }
{  (idCompressor_RunLength)                                                    }
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
unit DelphiDoom.Compression.RunLength;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Compression.BitStream;

type
  /// <summary>
  ///   idCompressor_RunLength: run length compression with an arbitrary word size. A run of more than
  ///   three equal words becomes the escape word (all ones), the word and the count minus 4; an escape
  ///   word in the data is always written as a run. As in the original every <c>Write</c> call ends
  ///   its input with an extra zero word (it reads one word past the data), so the output of several
  ///   small writes is longer than that of one large write.
  /// </summary>
  TCompressorRunLength = class(TCompressorBitStream)
  strict private
    FRunLengthCode: Integer;
  public
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{ TCompressorRunLength }

procedure TCompressorRunLength.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
begin
  inherited Init(AStream, ACompress, AWordLength);
  // ( 1 << wordLength ) - 1: all ones, also for 32 bits
  FRunLengthCode := Integer((Int64(1) shl AWordLength) - 1);
end;

function TCompressorRunLength.Write(AData: PByte; ALength: Integer): Integer;
var
  LBits, LNextBits, LCount: Integer;
  LLimit: Int64;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  InitCompress(AData, ALength);
  LLimit := Int64(1) shl FWordLength;
  while FReadByte <= FReadLength do
  begin
    LCount := 1;
    LBits := ReadBits(FWordLength);
    LNextBits := ReadBits(FWordLength);
    while LNextBits = LBits do
    begin
      Inc(LCount);
      if LCount >= LLimit then
      begin
        if (LCount >= LLimit + 3) or (LBits = FRunLengthCode) then
          Break;
      end;
      LNextBits := ReadBits(FWordLength);
    end;
    if LNextBits <> LBits then
      UnreadBits(FWordLength);
    if (LCount > 3) or (LBits = FRunLengthCode) then
    begin
      WriteBits(FRunLengthCode, FWordLength);
      WriteBits(LBits, FWordLength);
      if LBits <> FRunLengthCode then
        Dec(LCount, 3);
      WriteBits(LCount - 1, FWordLength);
    end
    else
    begin
      while LCount > 0 do
      begin
        Dec(LCount);
        WriteBits(LBits, FWordLength);
      end;
    end;
  end;
  Result := ALength;
end;

function TCompressorRunLength.Read(AData: PByte; ALength: Integer): Integer;
var
  LBits, LCount: Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  InitDecompress(AData, ALength);
  while (FWriteByte <= FWriteLength) and (FReadLength >= 0) do
  begin
    LBits := ReadBits(FWordLength);
    if LBits = FRunLengthCode then
    begin
      LBits := ReadBits(FWordLength);
      LCount := ReadBits(FWordLength) + 1;
      if LBits <> FRunLengthCode then
        Inc(LCount, 3);
      while LCount > 0 do
      begin
        Dec(LCount);
        WriteBits(LBits, FWordLength);
      end;
    end
    else
      WriteBits(LBits, FWordLength);
  end;
  Result := FWriteByte;
end;

end.
