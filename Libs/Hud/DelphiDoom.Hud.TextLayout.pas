{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - where the glyphs of a text go        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.TextLayout;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.TextLine, DelphiDoom.Hud.Layout;

type
  /// <summary>
  ///   The three ways the heads-up display writes text, without drawing: they walk the characters
  ///   once and put in a layout the glyph, the column and the row of each one. The drawing
  ///   then calls the engine for every glyph of the list; nothing here crosses an interface for a
  ///   character
  /// </summary>
  THudTextLayout = class sealed
  public
    /// <summary>
    ///   A text line (HUlib_drawTextLine): upper case, the glyph of a character is its code minus
    ///   AStartChar up to ALastChar included; a space is four columns; the text stops where a glyph
    ///   would pass the right edge. With ACursor the cursor (the glyph of the underscore) is put
    ///   after the text if it fits
    /// </summary>
    class procedure Line(const ALine: THudTextLine; const AWidths: THudFontWidths;
      const AScreenWidth, ALastChar: Integer; const ACursor: Boolean; const ALayout: THudLayout); static;
    /// <summary>
    ///   Text that goes to a new row at the edge and keeps the left margin (HUlib_drawYellowText of
    ///   Strife): the underscore is a space, the spaces at the start of a row are skipped,
    ///   a word that does not fit goes to the next row
    /// </summary>
    class procedure Wrapped(const AText: string; const AX, AY: Integer; const AWidths: THudFontWidths;
      const AFirstChar, ARowHeight, ARightLimit: Integer; const ALayout: THudLayout); static;
    /// <summary>
    ///   Text for the statistics of the automap (HU_WriteText of Doom): the first digit turns on the
    ///   highlight for the rest of the text when AHighlightDigits is set. EndX and EndY of the
    ///   layout are where the text ends
    /// </summary>
    class procedure Highlighted(const AText: string; const AX, AY: Integer; const AWidths: THudFontWidths;
      const AFirstChar, ARowHeight, AScreenWidth: Integer; const AHighlightDigits: Boolean;
      const ALayout: THudLayout); static;
  end;

implementation

const
  SPACE_WIDTH = 4;
  LINE_ROW_HEIGHT = 8;
  LINE_FEED = 10;
  CARRIAGE_RETURN = 13;
  UNDERSCORE = Ord('_');

function UpperCode(const ACode: Integer): Integer; inline;
begin
  if (ACode >= Ord('a')) and (ACode <= Ord('z')) then
    Result := ACode - 32
  else
    Result := ACode;
end;

{ THudTextLayout }

class procedure THudTextLayout.Line(const ALine: THudTextLine; const AWidths: THudFontWidths;
  const AScreenWidth, ALastChar: Integer; const ACursor: Boolean; const ALayout: THudLayout);
var
  LIndex: Integer;
  LCode: Integer;
  LGlyph: Integer;
  LWidth: Integer;
  LX: Integer;
  LY: Integer;
  LStartChar: Integer;
begin
  ALayout.Reset;
  LStartChar := ALine.StartChar;
  LX := ALine.X;
  LY := ALine.Y;
  for LIndex := 0 to ALine.Length - 1 do
  begin
    LCode := UpperCode(Ord(ALine.CharAt(LIndex)));
    if LCode = LINE_FEED then
      LX := ALine.X
    else if LCode = CARRIAGE_RETURN then
      LY := LY + LINE_ROW_HEIGHT
    else if LCode = Ord(' ') then
    begin
      LX := LX + SPACE_WIDTH;
      if LX >= AScreenWidth then
        Break;
    end
    else if (LCode >= LStartChar) and (LCode <= ALastChar) then
    begin
      LGlyph := LCode - LStartChar;
      // a glyph the font does not have is skipped (the old code read what followed the font)
      if LGlyph >= AWidths.Count then
        Continue;
      LWidth := AWidths.Width[LGlyph];
      if LX + LWidth > AScreenWidth then
        Break;
      ALayout.Add(LGlyph, LX, LY);
      LX := LX + LWidth;
    end;
  end;
  ALayout.EndX := LX;
  ALayout.EndY := LY;
  // the cursor stands on the first row of the line, not on the last one
  LGlyph := UNDERSCORE - LStartChar;
  if ACursor and (LGlyph >= 0) and (LGlyph < AWidths.Count) and
    (LX + AWidths.Width[LGlyph] <= AScreenWidth) then
  begin
    ALayout.CursorFits := True;
    ALayout.CursorX := LX;
    ALayout.CursorY := ALine.Y;
  end;
end;

class procedure THudTextLayout.Wrapped(const AText: string; const AX, AY: Integer;
  const AWidths: THudFontWidths; const AFirstChar, ARowHeight, ARightLimit: Integer;
  const ALayout: THudLayout);
var
  LIndex: Integer;
  LCode: Integer;
  LGlyph: Integer;
  LWidth: Integer;
  LX: Integer;
  LY: Integer;
begin
  ALayout.Reset;
  LX := AX;
  LY := AY;
  for LIndex := 1 to Length(AText) do
  begin
    LCode := UpperCode(Ord(AText[LIndex]));
    if LCode = LINE_FEED then
    begin
      LX := AX;
      Continue;
    end
    else if LCode = CARRIAGE_RETURN then
    begin
      LY := LY + ARowHeight;
      Continue;
    end
    else if LCode = UNDERSCORE then
      LCode := Ord(' ')
    else if (LCode = Ord(' ')) and (LX = AX) then // skip the spaces at the start of a row
      Continue;

    LGlyph := LCode - AFirstChar;
    if (LGlyph < 0) or (LGlyph >= AWidths.Count) then
    begin
      LX := LX + SPACE_WIDTH;
      Continue;
    end;

    LWidth := AWidths.Width[LGlyph];
    if LX + LWidth > ARightLimit then
    begin // word wrap
      LX := AX;
      LY := LY + ARowHeight;
    end;
    ALayout.Add(LGlyph, LX, LY);
    LX := LX + LWidth;
  end;
  ALayout.EndX := LX;
  ALayout.EndY := LY;
end;

class procedure THudTextLayout.Highlighted(const AText: string; const AX, AY: Integer;
  const AWidths: THudFontWidths; const AFirstChar, ARowHeight, AScreenWidth: Integer;
  const AHighlightDigits: Boolean; const ALayout: THudLayout);
var
  LIndex: Integer;
  LCode: Integer;
  LGlyph: Integer;
  LWidth: Integer;
  LX: Integer;
  LY: Integer;
  LHighlight: Boolean;
begin
  ALayout.Reset;
  LX := AX;
  LY := AY;
  ALayout.EndX := AX;
  ALayout.EndY := AY;
  LHighlight := False;
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Ord(AText[LIndex]);
    if AHighlightDigits then
      LHighlight := LHighlight or ((LCode >= Ord('0')) and (LCode <= Ord('9')));
    if LCode = 0 then
      Break;
    if LCode = LINE_FEED then
    begin
      LX := AX;
      Continue;
    end;
    if LCode = CARRIAGE_RETURN then
    begin
      LY := LY + ARowHeight;
      Continue;
    end;
    LGlyph := UpperCode(LCode) - AFirstChar;
    if (LGlyph < 0) or (LGlyph >= AWidths.Count) then
    begin
      LX := LX + SPACE_WIDTH;
      Continue;
    end;
    LWidth := AWidths.Width[LGlyph];
    if LX + LWidth > AScreenWidth then
      Break;
    ALayout.Add(LGlyph, LX, LY, LHighlight);
    LX := LX + LWidth;
  end;
  ALayout.EndX := LX;
  ALayout.EndY := LY;
end;

end.
