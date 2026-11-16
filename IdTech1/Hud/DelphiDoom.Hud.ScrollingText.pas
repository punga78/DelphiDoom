{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the scrolling text window            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.ScrollingText;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.TextLine;

type
  /// <summary>
  ///   A window of a few lines of text where the new message goes in the current line (the old
  ///   hu_stext_t); the lines are a ring, the current one is the newest
  /// </summary>
  THudScrollingText = class sealed
  strict private
    FEcho: IHudEcho;
    FLines: array[0..HUD_MAX_LINES - 1] of THudTextLine;
    FHeight: Integer;
    FCurrentLine: Integer;
    FLastVisible: Boolean;
    procedure AddRow(const APrefix, AText: string);
    function GetLine(const AIndex: Integer): THudTextLine;
  public
    /// <summary>A window that copies its messages to the echo (the console)</summary>
    constructor Create(const AEcho: IHudEcho);
    destructor Destroy; override;
    /// <summary>
    ///   Puts the window back as new, AHeight lines high, the first at (AX, AY) and the others one
    ///   line (ALineHeight) above the previous one (HUlib_initSText)
    /// </summary>
    procedure Initialize(const AX, AY, AHeight, ALineHeight, AStartChar: Integer);
    /// <summary>Goes to the next line of the ring and empties it (HUlib_addLineToSText)</summary>
    procedure AddLine;
    /// <summary>Takes the first row of text away from the current line (HUlib_removeLineFromSText)</summary>
    procedure RemoveRow;
    /// <summary>A message in a new line, as the chat writes it (HUlib_addMessageToSText)</summary>
    procedure AddMessage(const APrefix, AText: string);
    /// <summary>
    ///   A message below the ones already in the current line, up to HUD_MAX_LINE_ROWS rows
    ///   (HUlib_addMessageToSText2)
    /// </summary>
    procedure AddMessageBelow(const APrefix, AText: string);
    /// <summary>
    ///   The window is going to be erased, and is visible or not: when it has just become hidden
    ///   all its lines must be erased again. Remembers the state for the next time
    /// </summary>
    procedure PrepareErase(const AVisible: Boolean);
    /// <summary>The line of the ring, 0 is the first (the oldest ring slot, not the newest)</summary>
    property Lines[const AIndex: Integer]: THudTextLine read GetLine;
    /// <summary>Lines of the window (height)</summary>
    property Height: Integer read FHeight;
    /// <summary>Index of the newest line (curline)</summary>
    property CurrentLine: Integer read FCurrentLine;
    /// <summary>The line where the text goes now</summary>
    function Current: THudTextLine;
    /// <summary>Line i steps back from the newest one, 0 is the newest (the order the window is drawn)</summary>
    function LineBack(const ASteps: Integer): THudTextLine;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SMissingEcho = 'The scrolling text needs an echo to copy the messages to';
  SHeightOutOfRange = 'The scrolling text has from 1 to %d lines, not %d';

{ THudScrollingText }

constructor THudScrollingText.Create(const AEcho: IHudEcho);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AEcho) then
    raise EArgumentNilException.Create(SMissingEcho);
  FEcho := AEcho;
  for LIndex := 0 to HUD_MAX_LINES - 1 do
    FLines[LIndex] := THudTextLine.Create(0, 0, 0);
  FHeight := 1;
  FLastVisible := True;
end;

destructor THudScrollingText.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to HUD_MAX_LINES - 1 do
    FLines[LIndex].Free;
  inherited Destroy;
end;

procedure THudScrollingText.Initialize(const AX, AY, AHeight, ALineHeight, AStartChar: Integer);
var
  LIndex: Integer;
begin
  if (AHeight < 1) or (AHeight > HUD_MAX_LINES) then
    raise EHudException.CreateFmt(SHeightOutOfRange, [HUD_MAX_LINES, AHeight]);
  FHeight := AHeight;
  FLastVisible := True;
  FCurrentLine := 0;
  for LIndex := 0 to AHeight - 1 do
    FLines[LIndex].Initialize(AX, AY - LIndex * ALineHeight, AStartChar);
end;

procedure THudScrollingText.AddLine;
var
  LIndex: Integer;
begin
  Inc(FCurrentLine);
  if FCurrentLine = FHeight then
    FCurrentLine := 0;
  FLines[FCurrentLine].Clear;
  // everything needs updating
  for LIndex := 0 to FHeight - 1 do
    FLines[LIndex].MarkChanged;
end;

procedure THudScrollingText.RemoveRow;
begin
  FLines[FCurrentLine].RemoveFirstRow;
end;

procedure THudScrollingText.AddRow(const APrefix, AText: string);
begin
  FLines[FCurrentLine].AddText(APrefix);
  FLines[FCurrentLine].AddText(AText);
end;

procedure THudScrollingText.AddMessage(const APrefix, AText: string);
begin
  AddLine;
  FEcho.Echo(APrefix + AText);
  AddRow(APrefix, AText);
end;

procedure THudScrollingText.AddMessageBelow(const APrefix, AText: string);
begin
  while FLines[FCurrentLine].CountRows >= HUD_MAX_LINE_ROWS do
    RemoveRow;
  FEcho.Echo(APrefix + AText);
  if FLines[FCurrentLine].Length > 0 then
  begin
    FLines[FCurrentLine].AddChar(#13);
    FLines[FCurrentLine].AddChar(#10);
  end;
  AddRow(APrefix, AText);
  FLines[FCurrentLine].MarkChanged;
end;

procedure THudScrollingText.PrepareErase(const AVisible: Boolean);
var
  LIndex: Integer;
begin
  if FLastVisible and not AVisible then
    for LIndex := 0 to FHeight - 1 do
      FLines[LIndex].MarkChanged;
  FLastVisible := AVisible;
end;

function THudScrollingText.GetLine(const AIndex: Integer): THudTextLine;
begin
  Result := FLines[AIndex];
end;

function THudScrollingText.Current: THudTextLine;
begin
  Result := FLines[FCurrentLine];
end;

function THudScrollingText.LineBack(const ASteps: Integer): THudTextLine;
var
  LIndex: Integer;
begin
  LIndex := FCurrentLine - ASteps;
  if LIndex < 0 then
    Inc(LIndex, FHeight);
  Result := FLines[LIndex];
end;

end.
