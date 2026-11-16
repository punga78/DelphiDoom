{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, command history            }
{                                                                              }
{  historyEditLines, nextHistoryLine and historyLine of cl_keys.c.             }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Field.History;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Field.Types;

type
  /// <summary>
  ///   The last 32 lines of the console, as whole fields (cursor and scroll too) in a ring: the line
  ///   counter grows without bound and the slot is the counter modulo 32. Quirks kept: going back with
  ///   nothing in the history copies an empty field (the line is cleared), and going forward from the
  ///   line after the last one copies whatever the slot holds (the oldest line once the ring is full)
  /// </summary>
  TQ3FieldHistory = class
  strict private
    FLines: array[0..Q3_COMMAND_HISTORY - 1] of TQ3EditField;
    FNextLine: Integer;
    FCurrentLine: Integer;
  public
    /// <summary>Copies a line into the ring and points past it (the end of Enter)</summary>
    procedure Add(const AField: TQ3EditField);
    /// <summary>The up arrow: the previous line, while the ring has one; the field takes its copy</summary>
    procedure Previous(var AField: TQ3EditField);
    /// <summary>The down arrow: the next line; at the end of the history nothing happens</summary>
    procedure Next(var AField: TQ3EditField);
    /// <summary>A line of the ring by slot (0 to 31)</summary>
    function Slot(AIndex: Integer): TQ3EditField;
    /// <summary>nextHistoryLine: the lines added so far, not masked</summary>
    property NextLine: Integer read FNextLine;
    /// <summary>historyLine: the line shown, never above NextLine</summary>
    property CurrentLine: Integer read FCurrentLine;
  end;

implementation

{ TQ3FieldHistory }

procedure TQ3FieldHistory.Add(const AField: TQ3EditField);
begin
  FLines[FNextLine mod Q3_COMMAND_HISTORY] := AField;
  Inc(FNextLine);
  FCurrentLine := FNextLine;
end;

procedure TQ3FieldHistory.Previous(var AField: TQ3EditField);
begin
  if (FNextLine - FCurrentLine < Q3_COMMAND_HISTORY) and (FCurrentLine > 0) then
    Dec(FCurrentLine);
  AField := FLines[FCurrentLine mod Q3_COMMAND_HISTORY];
end;

procedure TQ3FieldHistory.Next(var AField: TQ3EditField);
begin
  if FCurrentLine = FNextLine then
    Exit;
  Inc(FCurrentLine);
  AField := FLines[FCurrentLine mod Q3_COMMAND_HISTORY];
end;

function TQ3FieldHistory.Slot(AIndex: Integer): TQ3EditField;
begin
  Result := FLines[AIndex];
end;

end.
