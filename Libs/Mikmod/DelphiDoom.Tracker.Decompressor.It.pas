{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - unpacks the compressed samples of Impulse Tracker     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Decompressor.It;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The compression of IT 2.14 and 2.15: blocks of variable width codes,
  ///   with the difference of the samples (and of the differences, in 2.15)
  /// </summary>
  TTrackerItDecompressor = class
  public
    /// <summary>
    ///   Unpacks ALength samples from ASource, which holds the blocks one
    ///   after the other (each starts with the number of bytes it takes)
    /// </summary>
    /// <param name="A16Bit">16 bit samples; otherwise 8 bit, returned as 16 bit</param>
    /// <param name="AIt215">the 2.15 variant: the second order difference</param>
    /// <exception cref="ETrackerException">truncated or bad data</exception>
    class function Unpack(const ASource: TBytes; const ALength: Integer; const A16Bit,
      AIt215: Boolean): TArray<SmallInt>; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tracker.Types;

const
  BLOCK_SAMPLES_8BIT = $8000;
  BLOCK_SAMPLES_16BIT = $4000;
  STruncated = 'A compressed sample is truncated';
  SBadWidth = 'A compressed sample has a bad code width';

{ TTrackerItDecompressor }

class function TTrackerItDecompressor.Unpack(const ASource: TBytes; const ALength: Integer;
  const A16Bit, AIt215: Boolean): TArray<SmallInt>;
var
  LPosition, LDone, LBlockSize, LBlockEnd, LBlockLength, LCount: Integer;
  LBitBuffer: UInt64;
  LBitCount, LBytePos: Integer;
  LWidth, LValue, LBorder, LNewWidth, LDelta, LD1, LD2, LOut: Integer;
  LMaxWidth, LStartWidth, LChangeBits, LMask, LBorderRange: Integer;

  function ReadBits(const ACountOfBits: Integer): Integer;
  begin
    while LBitCount < ACountOfBits do
    begin
      if LBytePos >= LBlockEnd then
        raise ETrackerException.Create(STruncated);
      LBitBuffer := LBitBuffer or (UInt64(ASource[LBytePos]) shl LBitCount);
      Inc(LBytePos);
      Inc(LBitCount, 8);
    end;
    Result := Integer(LBitBuffer and ((UInt64(1) shl ACountOfBits) - 1));
    LBitBuffer := LBitBuffer shr ACountOfBits;
    Dec(LBitCount, ACountOfBits);
  end;

begin
  SetLength(Result, ALength);
  if A16Bit then
  begin
    LStartWidth := 17;
    LMaxWidth := 17;
    LChangeBits := 4;
    LBorderRange := 16;
  end
  else
  begin
    LStartWidth := 9;
    LMaxWidth := 9;
    LChangeBits := 3;
    LBorderRange := 8;
  end;

  LPosition := 0;
  LDone := 0;
  while LDone < ALength do
  begin
    if LPosition + 2 > Length(ASource) then
      raise ETrackerException.Create(STruncated);
    LBlockSize := ASource[LPosition] or (ASource[LPosition + 1] shl 8);
    Inc(LPosition, 2);
    LBlockEnd := LPosition + LBlockSize;
    if LBlockEnd > Length(ASource) then
      raise ETrackerException.Create(STruncated);

    if A16Bit then
      LBlockLength := Min(ALength - LDone, BLOCK_SAMPLES_16BIT)
    else
      LBlockLength := Min(ALength - LDone, BLOCK_SAMPLES_8BIT);

    LBitBuffer := 0;
    LBitCount := 0;
    LBytePos := LPosition;
    LWidth := LStartWidth;
    LD1 := 0;
    LD2 := 0;
    LCount := 0;

    while LCount < LBlockLength do
    begin
      if (LWidth < 1) or (LWidth > LMaxWidth) then
        raise ETrackerException.Create(SBadWidth);
      LValue := ReadBits(LWidth);

      if LWidth < 7 then
      begin
        // The code with only the top bit set announces a new width
        if LValue = (1 shl (LWidth - 1)) then
        begin
          LNewWidth := ReadBits(LChangeBits) + 1;
          if LNewWidth >= LWidth then
            Inc(LNewWidth);
          LWidth := LNewWidth;
          Continue;
        end;
      end
      else if LWidth < LMaxWidth then
      begin
        if A16Bit then
          LBorder := ($FFFF shr (17 - LWidth)) - 8
        else
          LBorder := ($FF shr (9 - LWidth)) - 4;
        if (LValue > LBorder) and (LValue <= LBorder + LBorderRange) then
        begin
          Dec(LValue, LBorder);
          if LValue >= LWidth then
            Inc(LValue);
          LWidth := LValue;
          Continue;
        end;
      end
      else if LWidth = LMaxWidth then
      begin
        if (LValue and (1 shl (LMaxWidth - 1))) <> 0 then
        begin
          LWidth := (LValue + 1) and $FF;
          Continue;
        end;
      end
      else
        raise ETrackerException.Create(SBadWidth);

      if (LWidth < 1) or (LWidth > LMaxWidth) then
        raise ETrackerException.Create(SBadWidth);

      // The code is a signed number of LWidth bits
      if A16Bit then
      begin
        if LWidth < 16 then
        begin
          LMask := 1 shl (LWidth - 1);
          if LValue >= LMask then
            LDelta := LValue - (1 shl LWidth)
          else
            LDelta := LValue;
        end
        else
          LDelta := SmallInt(LValue and $FFFF);
        LD1 := SmallInt(LD1 + LDelta);
        LD2 := SmallInt(LD2 + LD1);
        if AIt215 then
          LOut := LD2
        else
          LOut := LD1;
        Result[LDone + LCount] := SmallInt(LOut);
      end
      else
      begin
        if LWidth < 8 then
        begin
          LMask := 1 shl (LWidth - 1);
          if LValue >= LMask then
            LDelta := LValue - (1 shl LWidth)
          else
            LDelta := LValue;
        end
        else
          LDelta := ShortInt(LValue and $FF);
        LD1 := ShortInt(LD1 + LDelta);
        LD2 := ShortInt(LD2 + LD1);
        if AIt215 then
          LOut := LD2
        else
          LOut := LD1;
        Result[LDone + LCount] := ShortInt(LOut) * 256;
      end;
      Inc(LCount);
    end;

    Inc(LDone, LBlockLength);
    LPosition := LBlockEnd;
  end;
end;

end.
