{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the layout of the text                            }
{                                                                              }
{  Port of war1 (acoto87/war1), war_font.c (getCharIndex,                      }
{  wfont_getAlignmentOffset, wfont_getLineAlignmentOffset,                     }
{  wfont_splitTextIntoLines, wfont_measureSingleSpriteText,                    }
{  wfont_measureMultiSpriteText), (c) 2019 Alejandro Coto Gutierrez, zlib      }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Text.Layout;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Types, DelphiDoom.War.Font.Types, DelphiDoom.War.Text.Types;

type
  /// <summary>
  ///   Where each character of a text goes and how large the text is, with the numbers and the rounding of the
  ///   original (every operation on a float is rounded to a float: the x87 of Win32 would keep more bits). No
  ///   state, no drawing
  /// </summary>
  TWarTextLayout = class
  public
    /// <summary>
    ///   getCharIndex: the glyph of a character is its code minus 32; the original reads char with a sign, so the
    ///   space, the zero and the codes from 128 up are the glyph 0
    /// </summary>
    class function GlyphIndex(AChar: AnsiChar): Integer; static;
    /// <summary>The glyph of a character; EWarException for the codes 1 to 31 and 127 (the original read the table outside)</summary>
    class function GlyphOf(const AFont: TWarFontData; AChar: AnsiChar): TWarGlyph; static;
    /// <summary>ceilf of a float: the result keeps the sign (the ceiling of -0.3 is -0)</summary>
    class function CeilFloat(AValue: Single): Single; static;
    /// <summary>
    ///   wfont_measureSingleSpriteText: the size of the first ALength characters of the text (all of them if ALength
    ///   is negative) in one line; a new line is a step of the advance
    /// </summary>
    class function MeasureSingle(const AText: AnsiString; ALength: Integer; const AParams: TWarFontParams): TWarTextSize; static;
    /// <summary>
    ///   wfont_splitTextIntoLines: the lines of a text that goes in AWidth (a line breaks at each new line and, if the
    ///   wrapping is by character, where the next character does not fit), with the spaces and tabs of the ends cut off
    ///   as the trimming says. At most AMaxLines lines
    /// </summary>
    class function SplitIntoLines(const AText: AnsiString; AMaxLines: Integer; AWidth: Single;
      const AParams: TWarFontParams): TArray<TWarTextSpan>; static;
    /// <summary>wfont_measureMultiSpriteText: the widest line and the height of all (the lines are split at BoundingsX)</summary>
    class function MeasureMulti(const AText: AnsiString; const AParams: TWarFontParams): TWarTextSize; static;
    /// <summary>
    ///   wfont_getAlignmentOffset: where a text goes in its bounds. As in the original the right alignment is
    ///   the same as the center
    /// </summary>
    class function AlignmentOffset(AHorizontal, AVertical: TWarTextAlignment; ABoundingsX, ABoundingsY: Single;
      const ATextSize: TWarTextSize): TWarTextSize; static;
    /// <summary>wfont_getLineAlignmentOffset</summary>
    class function LineAlignmentOffset(ALineAlign: TWarTextAlignment; AWidth, ALineWidth: Single): Single; static;
  end;

implementation

class function TWarTextLayout.GlyphIndex(AChar: AnsiChar): Integer;
var
  LSigned: Integer;
begin
  LSigned := ShortInt(Ord(AChar));
  if LSigned > 0 then
    Result := LSigned - 32
  else
    Result := 0;
end;

class function TWarTextLayout.GlyphOf(const AFont: TWarFontData; AChar: AnsiChar): TWarGlyph;
var
  LIndex: Integer;
begin
  LIndex := GlyphIndex(AChar);
  if (LIndex < 0) or (LIndex >= WAR_FONT_GLYPH_COUNT) then
    raise EWarException.CreateFmt(SWarTextNoGlyph, [Ord(AChar)]);
  Result := AFont.Glyphs[LIndex];
end;

class function TWarTextLayout.CeilFloat(AValue: Single): Single;
var
  LBits: Cardinal;
begin
  if (AValue < 0) and (AValue > -1) then
  begin
    LBits := $80000000;
    Move(LBits, Result, SizeOf(Result));
    Exit;
  end;
  if AValue = 0 then
    Exit(AValue);
  Result := Ceil(AValue);
end;

class function TWarTextLayout.MeasureSingle(const AText: AnsiString; ALength: Integer;
  const AParams: TWarFontParams): TWarTextSize;
var
  LLineHeight: Single;
  LScale: Single;
  LAdvance: Single;
  LCount: Integer;
  LIndex: Integer;
  LChar: AnsiChar;
  LGlyph: TWarGlyph;
  LWidth: Single;
  LStep: Single;
  LHeight: Single;
begin
  LLineHeight := AParams.FontData.LineHeight;
  LScale := AParams.FontSize / LLineHeight;
  LAdvance := AParams.FontData.Advance;
  Result.X := 0;
  Result.Y := 0;
  LCount := Length(AText);
  if (ALength >= 0) and (ALength < LCount) then
    LCount := ALength;
  for LIndex := 1 to LCount do
  begin
    LChar := AText[LIndex];
    if LChar = #10 then
    begin
      LStep := LAdvance * LScale;
      Result.X := Result.X + LStep;
    end
    else if LChar = #9 then
    begin
      LGlyph := GlyphOf(AParams.FontData, ' ');
      LWidth := LGlyph.Width;
      LStep := WAR_TAB_WIDTH * LWidth;
      LStep := LStep + LAdvance;
      LStep := LStep * LScale;
      Result.X := Result.X + LStep;
    end
    else
    begin
      LGlyph := GlyphOf(AParams.FontData, LChar);
      LWidth := LGlyph.Width;
      LStep := LWidth + LAdvance;
      LStep := LStep * LScale;
      Result.X := Result.X + LStep;
      LHeight := LGlyph.Height;
      LStep := LHeight * LScale;
      if LStep > Result.Y then
        Result.Y := LStep;
    end;
  end;
end;

class function TWarTextLayout.SplitIntoLines(const AText: AnsiString; AMaxLines: Integer; AWidth: Single;
  const AParams: TWarFontParams): TArray<TWarTextSpan>;
var
  LLineHeight: Single;
  LScale: Single;
  LAdvance: Single;
  LWrap: Boolean;
  LX: Single;
  LCount: Integer;
  LStart: Integer;
  LLength: Integer;
  LIndex: Integer;
  LChar: AnsiChar;
  LGlyph: TWarGlyph;
  LWidth: Single;
  LStep: Single;
  LSum: Single;
  LSpaceWidth: Single;
  LLine: Integer;
  LLines: array[0..WAR_MAX_LINES - 1] of TWarTextSpan;
  LFirst: AnsiChar;
  LLast: AnsiChar;

  procedure AddLine(AFrom, ACount: Integer; AWidthOfLine: Single);
  begin
    LLines[LCount].Start := AFrom;
    LLines[LCount].Length := ACount;
    LLines[LCount].Width := AWidthOfLine;
    Inc(LCount);
  end;

begin
  LLineHeight := AParams.FontData.LineHeight;
  LScale := AParams.FontSize / LLineHeight;
  LAdvance := AParams.FontData.Advance;
  LWrap := AParams.Wrapping = wtwChar;
  LX := 0;
  LCount := 0;
  LStart := 0;
  LLength := Length(AText);
  LIndex := 0;
  while (LIndex < LLength) and (LCount < AMaxLines) do
  begin
    LChar := AText[LIndex + 1];
    // a new line is generated for each line feed
    if LChar = #10 then
    begin
      AddLine(LStart, LIndex - LStart, LX);
      LStart := LIndex + 1;
      LX := 0;
    end
    else
    begin
      if LChar = #9 then
      begin
        LGlyph := GlyphOf(AParams.FontData, ' ');
        LWidth := LGlyph.Width;
        LStep := WAR_TAB_WIDTH * LWidth;
        LStep := LStep + LAdvance;
        LStep := LStep * LScale;
      end
      else
      begin
        LGlyph := GlyphOf(AParams.FontData, LChar);
        LWidth := LGlyph.Width;
        LStep := LWidth + LAdvance;
        LStep := LStep * LScale;
      end;
      // if the current character does not fit in the line generate a new line
      LSum := LX + LStep;
      if (LSum > AWidth) and LWrap then
      begin
        AddLine(LStart, LIndex - LStart, LX);
        LStart := LIndex;
        LX := 0;
      end;
      LSum := LX + LStep;
      LX := LSum;
    end;
    Inc(LIndex);
  end;
  if (LStart < LLength) and (LCount < AMaxLines) then
    AddLine(LStart, LLength - LStart, LX);
  // trim start and end spaces on lines
  if AParams.Trimming <> wttNone then
  begin
    LGlyph := GlyphOf(AParams.FontData, ' ');
    LWidth := LGlyph.Width;
    LSpaceWidth := LWidth + LAdvance;
    LSpaceWidth := LSpaceWidth * LScale;
    for LLine := 0 to LCount - 1 do
    begin
      while LLines[LLine].Length > 0 do
      begin
        LFirst := AText[LLines[LLine].Start + 1];
        if (LFirst = ' ') and (AParams.Trimming >= wttSpaces) then
        begin
          LSum := LLines[LLine].Width - LSpaceWidth;
          LLines[LLine].Width := LSum;
          Inc(LLines[LLine].Start);
          Dec(LLines[LLine].Length);
        end
        else if (LFirst = #9) and (AParams.Trimming >= wttAll) then
        begin
          LStep := WAR_TAB_WIDTH * LSpaceWidth;
          LSum := LLines[LLine].Width - LStep;
          LLines[LLine].Width := LSum;
          Inc(LLines[LLine].Start);
          Dec(LLines[LLine].Length);
        end
        else
          Break;
      end;
      while LLines[LLine].Length > 0 do
      begin
        LLast := AText[LLines[LLine].Start + LLines[LLine].Length];
        if (LLast = ' ') and (AParams.Trimming >= wttSpaces) then
        begin
          LSum := LLines[LLine].Width - LSpaceWidth;
          LLines[LLine].Width := LSum;
          Dec(LLines[LLine].Length);
        end
        else if (LLast = #9) and (AParams.Trimming >= wttAll) then
        begin
          LStep := WAR_TAB_WIDTH * LSpaceWidth;
          LSum := LLines[LLine].Width - LStep;
          LLines[LLine].Width := LSum;
          Dec(LLines[LLine].Length);
        end
        else
          Break;
      end;
    end;
  end;
  SetLength(Result, LCount);
  for LLine := 0 to LCount - 1 do
    Result[LLine] := LLines[LLine];
end;

class function TWarTextLayout.MeasureMulti(const AText: AnsiString; const AParams: TWarFontParams): TWarTextSize;
var
  LLineHeight: Single;
  LScale: Single;
  LRowHeight: Single;
  LLines: TArray<TWarTextSpan>;
  LLine: Integer;
  LStep: Single;
  LSum: Single;
begin
  LLineHeight := AParams.FontData.LineHeight;
  LScale := AParams.FontSize / LLineHeight;
  if AParams.LineHeight > 0 then
    LRowHeight := AParams.LineHeight
  else
    LRowHeight := LLineHeight;
  LLines := SplitIntoLines(AText, WAR_MAX_LINES, AParams.BoundingsX, AParams);
  Result.X := 0;
  Result.Y := 0;
  for LLine := 0 to High(LLines) do
  begin
    if LLines[LLine].Width > Result.X then
      Result.X := LLines[LLine].Width;
    LStep := LRowHeight * LScale;
    LSum := Result.Y + LStep;
    Result.Y := LSum;
  end;
end;

class function TWarTextLayout.AlignmentOffset(AHorizontal, AVertical: TWarTextAlignment; ABoundingsX, ABoundingsY: Single;
  const ATextSize: TWarTextSize): TWarTextSize;
var
  LDifference: Single;
  LHalf: Single;
begin
  Result.X := 0;
  Result.Y := 0;
  case AHorizontal of
    wtaCenter, wtaRight:
      begin
        LDifference := ABoundingsX - ATextSize.X;
        LHalf := 0.5 * LDifference;
        Result.X := CeilFloat(LHalf);
      end;
  end;
  case AVertical of
    wtaMiddle:
      begin
        LDifference := ABoundingsY - ATextSize.Y;
        LHalf := 0.5 * LDifference;
        Result.Y := CeilFloat(LHalf);
      end;
    wtaBottom:
      begin
        LDifference := ABoundingsY - ATextSize.Y;
        Result.Y := CeilFloat(LDifference);
      end;
  end;
end;

class function TWarTextLayout.LineAlignmentOffset(ALineAlign: TWarTextAlignment; AWidth, ALineWidth: Single): Single;
var
  LDifference: Single;
  LHalf: Single;
begin
  Result := 0;
  case ALineAlign of
    wtaCenter:
      begin
        LDifference := AWidth - ALineWidth;
        LHalf := 0.5 * LDifference;
        Result := CeilFloat(LHalf);
      end;
    wtaRight:
      begin
        LDifference := AWidth - ALineWidth;
        Result := CeilFloat(LDifference);
      end;
  end;
end;

end.
