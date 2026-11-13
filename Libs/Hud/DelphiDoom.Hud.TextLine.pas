{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - a line of text                       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.TextLine;

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>
  ///   A line of text of the heads-up display (the old hu_textline_t): the characters, where they
  ///   are written and how many erase passes the line still needs. It holds no font: the drawing
  ///   chooses it
  /// </summary>
  /// <remarks>
  ///   The text is 8 bit (AnsiChar), as the engine writes it on the screen. A line feed (#10)
  ///   starts a new row at the left margin and a carriage return (#13) goes down one row.
  /// </remarks>
  THudTextLine = class sealed
  strict private
    FX: Integer;
    FY: Integer;
    FStartChar: Integer;
    FNeedsUpdate: Integer;
    FLength: Integer;
    FText: array[0..HUD_MAX_LINE_LENGTH] of AnsiChar;
  public
    /// <summary>A line at the given place whose first glyph is the character AStartChar</summary>
    constructor Create(const AX, AY, AStartChar: Integer);
    /// <summary>Puts the line back as new (HUlib_initTextLine)</summary>
    procedure Initialize(const AX, AY, AStartChar: Integer);
    /// <summary>Empties the line (HUlib_clearTextLine)</summary>
    procedure Clear;
    /// <summary>Adds a character at the end, false if the line is full (HUlib_addCharToTextLine)</summary>
    function AddChar(const AChar: Char): Boolean;
    /// <summary>Adds all the characters of the text, those that do not fit are lost</summary>
    procedure AddText(const AText: string);
    /// <summary>Takes the last character away, false if the line is empty (HUlib_delCharFromTextLine)</summary>
    function DeleteChar: Boolean;
    /// <summary>Empties the line character by character and writes the text (as the title line does)</summary>
    procedure Replace(const AText: string);
    /// <summary>Rows of text of the line: 0 if empty, else one plus the line feeds (HUlib_countLineLines)</summary>
    function CountRows: Integer;
    /// <summary>Takes away the first row of text and its line break (HUlib_removeLineFromSText)</summary>
    procedure RemoveFirstRow;
    /// <summary>A character of the line, index from 0 to Length - 1</summary>
    function CharAt(const AIndex: Integer): AnsiChar;
    /// <summary>The text of the line</summary>
    function Text: AnsiString;
    /// <summary>Marks the line to be erased again for the next passes</summary>
    procedure MarkChanged;
    /// <summary>One erase pass is done: the passes left go down by one, never below zero</summary>
    procedure ConsumePass;
    /// <summary>Left margin</summary>
    property X: Integer read FX;
    /// <summary>Top of the first row</summary>
    property Y: Integer read FY;
    /// <summary>The character the first glyph of the font stands for</summary>
    property StartChar: Integer read FStartChar;
    /// <summary>Characters in the line</summary>
    property Length: Integer read FLength;
    /// <summary>Erase passes still needed (needsupdate)</summary>
    property NeedsUpdate: Integer read FNeedsUpdate;
  end;

implementation

const
  LINE_FEED = #10;
  CARRIAGE_RETURN = #13;

{ THudTextLine }

constructor THudTextLine.Create(const AX, AY, AStartChar: Integer);
begin
  inherited Create;
  Initialize(AX, AY, AStartChar);
end;

procedure THudTextLine.Initialize(const AX, AY, AStartChar: Integer);
begin
  FX := AX;
  FY := AY;
  FStartChar := AStartChar;
  Clear;
end;

procedure THudTextLine.Clear;
begin
  FLength := 0;
  FText[0] := #0;
  FNeedsUpdate := 1;
end;

function THudTextLine.AddChar(const AChar: Char): Boolean;
begin
  Result := FLength < HUD_MAX_LINE_LENGTH;
  if not Result then
    Exit;
  // the old code cast the character to AnsiChar: the low byte stays
  FText[FLength] := AnsiChar(Ord(AChar) and $FF);
  Inc(FLength);
  FText[FLength] := #0;
  FNeedsUpdate := HUD_UPDATE_PASSES;
end;

procedure THudTextLine.AddText(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to System.Length(AText) do
    AddChar(AText[LIndex]);
end;

function THudTextLine.DeleteChar: Boolean;
begin
  Result := FLength > 0;
  if not Result then
    Exit;
  Dec(FLength);
  FText[FLength] := #0;
  FNeedsUpdate := HUD_UPDATE_PASSES;
end;

procedure THudTextLine.Replace(const AText: string);
begin
  while DeleteChar do
    ;
  AddText(AText);
end;

function THudTextLine.CountRows: Integer;
var
  LIndex: Integer;
begin
  if FLength = 0 then
    Exit(0);
  Result := 1;
  for LIndex := 1 to FLength - 1 do
    if FText[LIndex] = LINE_FEED then
      Inc(Result);
end;

procedure THudTextLine.RemoveFirstRow;
var
  // every row grows by one (a single line break becomes #13#10) and the last one by two
  LRest: array[0..2 * HUD_MAX_LINE_LENGTH + 2] of AnsiChar;
  LPosition: Integer;
  LStart: Integer;
  LRestLength: Integer;
  LIndex: Integer;
begin
  // The old code gave the text to a string list and took its first line away: a row ends at a
  // line feed, at a carriage return, or at the pair (the characters after a #0 do not count)
  LPosition := 0;
  while (LPosition < FLength) and not (FText[LPosition] in [#0, LINE_FEED, CARRIAGE_RETURN]) do
    Inc(LPosition);
  if (LPosition < FLength) and (FText[LPosition] = CARRIAGE_RETURN) then
    Inc(LPosition);
  if (LPosition < FLength) and (FText[LPosition] = LINE_FEED) then
    Inc(LPosition);
  // the rows after the first, each one followed by #13#10, and then the last pair is cut
  LRestLength := 0;
  while (LPosition < FLength) and (FText[LPosition] <> #0) do
  begin
    LStart := LPosition;
    while (LPosition < FLength) and not (FText[LPosition] in [#0, LINE_FEED, CARRIAGE_RETURN]) do
      Inc(LPosition);
    for LIndex := LStart to LPosition - 1 do
    begin
      LRest[LRestLength] := FText[LIndex];
      Inc(LRestLength);
    end;
    if (LPosition < FLength) and (FText[LPosition] = CARRIAGE_RETURN) then
      Inc(LPosition);
    if (LPosition < FLength) and (FText[LPosition] = LINE_FEED) then
      Inc(LPosition);
    LRest[LRestLength] := CARRIAGE_RETURN;
    Inc(LRestLength);
    LRest[LRestLength] := LINE_FEED;
    Inc(LRestLength);
  end;
  // the string list text ends with #13#10: the old code cut it when the text is longer than 1
  if (LRestLength > 1) and (LRest[LRestLength - 2] = CARRIAGE_RETURN) and
    (LRest[LRestLength - 1] = LINE_FEED) then
    Dec(LRestLength, 2);
  // a row of only line breaks can grow the text: what does not fit is lost (the old code wrote
  // past the end of the line)
  FLength := LRestLength;
  if FLength > HUD_MAX_LINE_LENGTH then
    FLength := HUD_MAX_LINE_LENGTH;
  for LIndex := 0 to FLength - 1 do
    FText[LIndex] := LRest[LIndex];
  FText[FLength] := #0;
  FNeedsUpdate := HUD_UPDATE_PASSES;
end;

function THudTextLine.CharAt(const AIndex: Integer): AnsiChar;
begin
  Result := FText[AIndex];
end;

function THudTextLine.Text: AnsiString;
begin
  SetString(Result, PAnsiChar(@FText[0]), FLength);
end;

procedure THudTextLine.MarkChanged;
begin
  FNeedsUpdate := HUD_UPDATE_PASSES;
end;

procedure THudTextLine.ConsumePass;
begin
  if FNeedsUpdate > 0 then
    Dec(FNeedsUpdate);
end;

end.
