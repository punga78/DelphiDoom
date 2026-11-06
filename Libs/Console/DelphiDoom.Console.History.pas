{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the history of the commands                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.History;

interface

const
  /// <summary>How many lines the console remembers</summary>
  CONSOLE_HISTORY_SIZE = 64;

type
  /// <summary>
  ///   The last lines typed, on a ring (as the old code did): the up arrow goes back, the down
  ///   arrow goes forward, and an empty place stops the walk
  /// </summary>
  TConsoleHistory = class
  private
    FLines: array[0..CONSOLE_HISTORY_SIZE - 1] of string;
    FHead: Integer;
    FCurrent: Integer;
  public
    constructor Create;
    procedure Clear;
    /// <summary>The line becomes the most recent one and the walk starts again from it</summary>
    procedure Add(const ALine: string);
    /// <summary>Goes back by one. Gives false (and stays) if there is nothing before</summary>
    function Previous(out ALine: string): Boolean;
    /// <summary>Goes forward by one. Gives false (and stays) if there is nothing after</summary>
    function Next(out ALine: string): Boolean;
  end;

implementation

{ TConsoleHistory }

constructor TConsoleHistory.Create;
begin
  inherited Create;
  Clear;
end;

procedure TConsoleHistory.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to CONSOLE_HISTORY_SIZE - 1 do
    FLines[LIndex] := '';
  FHead := 0;
  FCurrent := 0;
end;

procedure TConsoleHistory.Add(const ALine: string);
begin
  FLines[FHead] := ALine;
  Inc(FHead);
  FCurrent := FHead;
  if FHead >= CONSOLE_HISTORY_SIZE then
    FHead := 0;
  FLines[FHead] := '';
end;

function TConsoleHistory.Previous(out ALine: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FCurrent - 1;
  if LIndex < 0 then
    LIndex := CONSOLE_HISTORY_SIZE - 1;
  Result := FLines[LIndex] <> '';
  if Result then
  begin
    ALine := FLines[LIndex];
    FCurrent := LIndex;
  end
  else
    ALine := '';
end;

function TConsoleHistory.Next(out ALine: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FCurrent + 1;
  if LIndex >= CONSOLE_HISTORY_SIZE then
    LIndex := 0;
  Result := FLines[LIndex] <> '';
  if Result then
  begin
    ALine := FLines[LIndex];
    FCurrent := LIndex;
  end
  else
    ALine := '';
end;

end.
