{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorArithmetic                     }
{  (idCompressor_Arithmetic)                                                   }
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
unit DelphiDoom.Compression.Arithmetic;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Compression.BitStream;

const
  AC_WORD_LENGTH = 8;
  AC_NUM_BITS = 16;
  AC_MSB_SHIFT = 15;
  AC_MSB2_SHIFT = 14;
  AC_MSB_MASK = $8000;
  AC_MSB2_MASK = $4000;
  AC_HIGH_INIT = $FFFF;
  AC_LOW_INIT = $0000;

type
  /// <summary>
  ///   idCompressor_Arithmetic: arithmetic coding after Mark Nelson, with an adaptive table of
  ///   probabilities of the 256 byte values (a 16 bit range, symbols counted one by one). The table is
  ///   reset every 16 KiB of data, with a marker of 15 zero bits and a 255 byte so the decoder can resynchronise.
  ///   The word length is ignored. All the arithmetic is on 32 bit unsigned integers and 16 bit
  ///   words, as in the original (a <c>long</c> is 32 bits there).
  /// </summary>
  TCompressorArithmetic = class(TCompressorBitStream)
  strict private
    type
      TSymbol = record
        Low: Cardinal;
        High: Cardinal;
        Position: Integer;
      end;
  strict private
    FProbLow: array[0..(1 shl AC_WORD_LENGTH) - 1] of Cardinal;
    FProbHigh: array[0..(1 shl AC_WORD_LENGTH) - 1] of Cardinal;
    FSymbolBuffer: Integer;
    FSymbolBit: Integer;
    FLow: Word;
    FHigh: Word;
    FCode: Word;
    FUnderflowBits: Cardinal;
    FScale: Cardinal;
    procedure InitProbabilities;
    procedure UpdateProbabilities(const ASymbol: TSymbol);
    function ProbabilityForCount(ACount: Cardinal): Integer;
    procedure CharToSymbol(AChar: Byte; out ASymbol: TSymbol);
    procedure EncodeSymbol(const ASymbol: TSymbol);
    function SymbolFromCount(ACount: Cardinal; out ASymbol: TSymbol): Integer;
    function GetCurrentCount: Cardinal;
    procedure RemoveSymbolFromStream(const ASymbol: TSymbol);
    procedure PutBit(ABit: Integer);
    function GetBit: Integer;
    procedure WriteOverflowBits;
  public
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer); override;
    procedure FinishCompress; override;
    function Write(AData: PByte; ALength: Integer): Integer; override;
    function Read(AData: PByte; ALength: Integer): Integer; override;
  end;

implementation

{ TCompressorArithmetic }

procedure TCompressorArithmetic.Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
begin
  inherited Init(AStream, ACompress, AWordLength);
  FSymbolBuffer := 0;
  FSymbolBit := 0;
end;

procedure TCompressorArithmetic.InitProbabilities;
var
  LIndex: Integer;
begin
  FHigh := AC_HIGH_INIT;
  FLow := AC_LOW_INIT;
  FUnderflowBits := 0;
  FCode := 0;
  for LIndex := 0 to (1 shl AC_WORD_LENGTH) - 1 do
  begin
    FProbLow[LIndex] := LIndex;
    FProbHigh[LIndex] := LIndex + 1;
  end;
  FScale := 1 shl AC_WORD_LENGTH;
end;

procedure TCompressorArithmetic.UpdateProbabilities(const ASymbol: TSymbol);
var
  LIndex: Integer;
begin
  Inc(FProbHigh[ASymbol.Position]);
  for LIndex := ASymbol.Position + 1 to (1 shl AC_WORD_LENGTH) - 1 do
  begin
    Inc(FProbLow[LIndex]);
    Inc(FProbHigh[LIndex]);
  end;
  Inc(FScale);
end;

function TCompressorArithmetic.GetCurrentCount: Cardinal;
var
  LNumerator, LDenominator: Cardinal;
begin
  // (unsigned)( ( ( (long) code - low ) + 1 ) * scale - 1 ) / ( ( (long) high - low ) + 1 )
  LNumerator := Cardinal(Integer(FCode) - Integer(FLow) + 1) * FScale - 1;
  LDenominator := Cardinal(Integer(FHigh) - Integer(FLow) + 1);
  Result := LNumerator div LDenominator;
end;

function TCompressorArithmetic.ProbabilityForCount(ACount: Cardinal): Integer;
var
  LLength, LMid, LOffset, LResult: Integer;
begin
  LLength := 1 shl AC_WORD_LENGTH;
  LMid := LLength;
  LOffset := 0;
  LResult := 0;
  while LMid > 0 do
  begin
    LMid := LLength shr 1;
    if ACount >= FProbHigh[LOffset + LMid] then
    begin
      Inc(LOffset, LMid);
      Dec(LLength, LMid);
      LResult := 1;
    end
    else if ACount < FProbLow[LOffset + LMid] then
    begin
      Dec(LLength, LMid);
      LResult := 0;
    end
    else
      Exit(LOffset + LMid);
  end;
  Result := LOffset + LResult;
end;

function TCompressorArithmetic.SymbolFromCount(ACount: Cardinal; out ASymbol: TSymbol): Integer;
var
  LPosition: Integer;
begin
  LPosition := ProbabilityForCount(ACount);
  ASymbol.Low := FProbLow[LPosition];
  ASymbol.High := FProbHigh[LPosition];
  ASymbol.Position := LPosition;
  Result := LPosition;
end;

procedure TCompressorArithmetic.RemoveSymbolFromStream(const ASymbol: TSymbol);
var
  LRange: Cardinal;
begin
  LRange := Cardinal(Integer(FHigh) - Integer(FLow)) + 1;
  FHigh := Word(Integer(FLow) + Integer(Word((LRange * ASymbol.High) div FScale - 1)));
  FLow := Word(Integer(FLow) + Integer(Word((LRange * ASymbol.Low) div FScale)));
  while True do
  begin
    if (FHigh and AC_MSB_MASK) = (FLow and AC_MSB_MASK) then
    begin
      // the high digits converged: shift them out
    end
    else if ((FLow and AC_MSB2_MASK) = AC_MSB2_MASK) and ((FHigh and AC_MSB2_MASK) = 0) then
    begin
      FCode := FCode xor AC_MSB2_MASK;
      FLow := FLow and (AC_MSB2_MASK - 1);
      FHigh := FHigh or AC_MSB2_MASK;
    end
    else
    begin
      UpdateProbabilities(ASymbol);
      Exit;
    end;
    FLow := Word(FLow shl 1);
    FHigh := Word(FHigh shl 1);
    FHigh := FHigh or 1;
    FCode := Word(FCode shl 1);
    FCode := FCode or Word(ReadBits(1));
  end;
end;

function TCompressorArithmetic.GetBit: Integer;
var
  LSymbol: TSymbol;
begin
  if FSymbolBit <= 0 then
  begin
    // read a new symbol out
    FSymbolBuffer := SymbolFromCount(GetCurrentCount, LSymbol);
    RemoveSymbolFromStream(LSymbol);
    FSymbolBit := AC_WORD_LENGTH;
  end;
  Result := (FSymbolBuffer shr (AC_WORD_LENGTH - FSymbolBit)) and 1;
  Dec(FSymbolBit);
end;

procedure TCompressorArithmetic.EncodeSymbol(const ASymbol: TSymbol);
var
  LRange: Cardinal;
begin
  // rescale high and low for the new symbol
  LRange := Cardinal(Integer(FHigh) - Integer(FLow) + 1);
  FHigh := Word(Integer(FLow) + Integer(Word((LRange * ASymbol.High) div FScale - 1)));
  FLow := Word(Integer(FLow) + Integer(Word((LRange * ASymbol.Low) div FScale)));
  while True do
  begin
    if (FHigh and AC_MSB_MASK) = (FLow and AC_MSB_MASK) then
    begin
      // the high digits of low and high have converged, and can be written to the stream
      WriteBits(FHigh shr AC_MSB_SHIFT, 1);
      while FUnderflowBits > 0 do
      begin
        WriteBits((not Integer(FHigh)) shr AC_MSB_SHIFT, 1);
        Dec(FUnderflowBits);
      end;
    end
    else if ((FLow and AC_MSB2_MASK) <> 0) and ((FHigh and AC_MSB2_MASK) = 0) then
    begin
      // underflow is in danger: the second digits converge but the first digits don't match
      Inc(FUnderflowBits);
      FLow := FLow and (AC_MSB2_MASK - 1);
      FHigh := FHigh or AC_MSB2_MASK;
    end
    else
    begin
      UpdateProbabilities(ASymbol);
      Exit;
    end;
    FLow := Word(FLow shl 1);
    FHigh := Word(FHigh shl 1);
    FHigh := FHigh or 1;
  end;
end;

procedure TCompressorArithmetic.CharToSymbol(AChar: Byte; out ASymbol: TSymbol);
begin
  ASymbol.Low := FProbLow[AChar];
  ASymbol.High := FProbHigh[AChar];
  ASymbol.Position := AChar;
end;

procedure TCompressorArithmetic.PutBit(ABit: Integer);
var
  LSymbol: TSymbol;
begin
  FSymbolBuffer := FSymbolBuffer or ((ABit and 1) shl FSymbolBit);
  Inc(FSymbolBit);
  if FSymbolBit >= AC_WORD_LENGTH then
  begin
    CharToSymbol(Byte(FSymbolBuffer), LSymbol);
    EncodeSymbol(LSymbol);
    FSymbolBit := 0;
    FSymbolBuffer := 0;
  end;
end;

procedure TCompressorArithmetic.WriteOverflowBits;
begin
  WriteBits(FLow shr AC_MSB2_SHIFT, 1);
  Inc(FUnderflowBits);
  // while( underflowBits-- > 0 ): the counter ends one below zero
  while FUnderflowBits > 0 do
  begin
    Dec(FUnderflowBits);
    WriteBits((not Integer(FLow)) shr AC_MSB2_SHIFT, 1);
  end;
  FUnderflowBits := Cardinal(-1);
end;

function TCompressorArithmetic.Write(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LBit: Integer;
begin
  if (not FCompress) or (ALength <= 0) then
    Exit(0);
  InitCompress(AData, ALength);
  for LIndex := 0 to ALength - 1 do
  begin
    if (FReadTotalBytes and ((1 shl 14) - 1)) = 0 then
    begin
      if FReadTotalBytes <> 0 then
      begin
        WriteOverflowBits;
        WriteBits(0, 15);
        while FWriteBit <> 0 do
          WriteBits(0, 1);
        WriteBits(255, 8);
      end;
      InitProbabilities;
    end;
    for LBit := 0 to 7 do
      PutBit(ReadBits(1));
  end;
  Result := ALength;
end;

procedure TCompressorArithmetic.FinishCompress;
begin
  if not FCompress then
    Exit;
  WriteOverflowBits;
  inherited FinishCompress;
end;

function TCompressorArithmetic.Read(AData: PByte; ALength: Integer): Integer;
var
  LIndex, LBit: Integer;
begin
  if FCompress or (ALength <= 0) then
    Exit(0);
  InitDecompress(AData, ALength);
  LIndex := 0;
  while (LIndex < ALength) and (FReadLength >= 0) do
  begin
    if (FWriteTotalBytes and ((1 shl 14) - 1)) = 0 then
    begin
      if FWriteTotalBytes <> 0 then
      begin
        while FReadBit <> 0 do
          ReadBits(1);
        while (ReadBits(8) = 0) and (FReadLength > 0) do
        begin
        end;
      end;
      InitProbabilities;
      for LBit := 0 to AC_NUM_BITS - 1 do
      begin
        FCode := Word(FCode shl 1);
        FCode := FCode or Word(ReadBits(1));
      end;
    end;
    for LBit := 0 to 7 do
      WriteBits(GetBit, 1);
    Inc(LIndex);
  end;
  Result := LIndex;
end;

end.
