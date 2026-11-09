{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the endoom library - the scenarios of the editor        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.EditorScenarios;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils;

const
  EDITOR_TOOL_RECTANGLE = 0;
  EDITOR_TOOL_FILL_RECTANGLE = 1;
  EDITOR_TOOL_ELLIPSE = 2;
  EDITOR_TOOL_FILLED_ELLIPSE = 3;
  EDITOR_TOOL_LINE = 4;
  EDITOR_TOOL_FLOOD_FILL = 5;
  /// <summary>The five frames of characters: this plus 0..4</summary>
  EDITOR_TOOL_FRAME = 6;
  EDITOR_TOOL_COUNT = 11;

  EDITOR_OP_CHARACTER = 0;
  EDITOR_OP_FOREGROUND = 1;
  EDITOR_OP_BACKGROUND = 2;
  EDITOR_OP_BLINK = 3;
  EDITOR_OP_CLEAR = 4;

type
  /// <summary>One change of a cell, as the old TEndScreen takes it: the colors are TColor (blue in the high byte)</summary>
  TEditorModelOp = record
    Kind: Integer;
    X: Integer;
    Y: Integer;
    Color: Cardinal;
    Value: Integer;
  end;

  /// <summary>A tool of the editor used with the mouse from the first cell to the second one</summary>
  TEditorDrawCase = record
    Tool: Integer;
    DownX: Integer;
    DownY: Integer;
    UpX: Integer;
    UpY: Integer;
    /// <summary>Index of the color in 0..7</summary>
    Background: Integer;
    /// <summary>Index of the color in 0..15</summary>
    Foreground: Integer;
  end;

  TEditorPasteCase = record
    Text: string;
    X: Integer;
    Y: Integer;
    Foreground: Integer;
  end;

  /// <summary>
  ///   The cases that the harness of the old ENDEDIT (it wrote Tests\Data\Endoom\editor.golden.txt)
  ///   and the tests use: both read them from here, so the inputs are the same
  /// </summary>
  TEditorScenarios = class
  public
    class function NextRandom(var AState: Cardinal): Cardinal; static;
    /// <summary>The TColor of a color of ENDOOM_COLORS: red and blue swap places</summary>
    class function ToTColor(ARgb: Cardinal): Cardinal; static;
    class function ToRgb(ATColor: Cardinal): Cardinal; static;
    /// <summary>ACount changes of cells, with colors that are in the table and colors that are not</summary>
    class function ModelOps(ASeed: Cardinal; ACount: Integer): TArray<TEditorModelOp>; static;
    /// <summary>The screen that the drawing cases start from (patches of backgrounds)</summary>
    class function BaseOps: TArray<TEditorModelOp>; static;
    /// <summary>The cases of a tool; the groups of AGroupSize cases give a line of the golden file</summary>
    class function DrawCases(ATool: Integer): TArray<TEditorDrawCase>; static;
    class function PasteCases: TArray<TEditorPasteCase>; static;
    /// <summary>Colors (TColor) to find the nearest one of the text mode for</summary>
    class function ColorsToQuantize: TArray<Cardinal>; static;
  end;

implementation

uses
  DelphiDoom.Endoom.Types;

{ TEditorScenarios }

class function TEditorScenarios.NextRandom(var AState: Cardinal): Cardinal;
begin
  AState := (AState * 1103515245 + 12345) and $7FFFFFFF;
  Result := AState shr 8;
end;

class function TEditorScenarios.ToTColor(ARgb: Cardinal): Cardinal;
begin
  Result := ((ARgb and $FF) shl 16) or (ARgb and $FF00) or ((ARgb shr 16) and $FF);
end;

class function TEditorScenarios.ToRgb(ATColor: Cardinal): Cardinal;
begin
  Result := ToTColor(ATColor);
end;

class function TEditorScenarios.ModelOps(ASeed: Cardinal; ACount: Integer): TArray<TEditorModelOp>;
var
  LState: Cardinal;
  LIndex: Integer;
  LRandom: Cardinal;
begin
  LState := ASeed;
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    LRandom := NextRandom(LState);
    Result[LIndex].Kind := Integer(LRandom mod 13);
    // 0..5 characters, 6..8 foregrounds, 9..11 backgrounds, 12 blinks; the clear is rare
    case Result[LIndex].Kind of
      0..5: Result[LIndex].Kind := EDITOR_OP_CHARACTER;
      6..8: Result[LIndex].Kind := EDITOR_OP_FOREGROUND;
      9..10: Result[LIndex].Kind := EDITOR_OP_BACKGROUND;
      11, 12: Result[LIndex].Kind := EDITOR_OP_BLINK;
    end;
    if (LRandom mod 997) = 0 then
      Result[LIndex].Kind := EDITOR_OP_CLEAR;
    Result[LIndex].X := Integer(NextRandom(LState) mod ENDOOM_COLUMNS);
    Result[LIndex].Y := Integer(NextRandom(LState) mod ENDOOM_ROWS);
    Result[LIndex].Value := Integer(NextRandom(LState) and $FF);
    LRandom := NextRandom(LState);
    if (LRandom mod 3) = 0 then
      Result[LIndex].Color := ToTColor(ENDOOM_COLORS[NextRandom(LState) mod ENDOOM_COLOR_COUNT])
    else
      Result[LIndex].Color := NextRandom(LState) and $FFFFFF;
  end;
end;

class function TEditorScenarios.BaseOps: TArray<TEditorModelOp>;
var
  LState: Cardinal;
  LPatch: Integer;
  LX: Integer;
  LY: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LColor: Cardinal;
  LList: TArray<TEditorModelOp>;
  LCount: Integer;
  LCellX: Integer;
  LCellY: Integer;
begin
  LState := 777;
  LCount := 0;
  SetLength(LList, 12 * 80 * 25);
  for LPatch := 0 to 11 do
  begin
    LX := Integer(NextRandom(LState) mod 70);
    LY := Integer(NextRandom(LState) mod 20);
    LWidth := 3 + Integer(NextRandom(LState) mod 25);
    LHeight := 2 + Integer(NextRandom(LState) mod 9);
    LColor := ToTColor(ENDOOM_COLORS[NextRandom(LState) mod ENDOOM_BACKGROUND_COLOR_COUNT]);
    for LCellY := LY to LY + LHeight - 1 do
      for LCellX := LX to LX + LWidth - 1 do
        if (LCellX < ENDOOM_COLUMNS) and (LCellY < ENDOOM_ROWS) then
        begin
          LList[LCount].Kind := EDITOR_OP_BACKGROUND;
          LList[LCount].X := LCellX;
          LList[LCount].Y := LCellY;
          LList[LCount].Color := LColor;
          LList[LCount].Value := 0;
          Inc(LCount);
        end;
  end;
  SetLength(LList, LCount);
  Result := LList;
end;

class function TEditorScenarios.DrawCases(ATool: Integer): TArray<TEditorDrawCase>;
const
  POINTS: array[0..11, 0..1] of Integer = (
    (0, 0), (79, 24), (5, 3), (40, 12), (10, 20), (70, 2), (0, 24), (79, 0), (39, 12), (41, 13),
    (12, 12), (60, 8));
  CENTERS: array[0..4, 0..1] of Integer = ((40, 12), (0, 0), (79, 24), (10, 5), (70, 20));
var
  LList: TArray<TEditorDrawCase>;
  LCount: Integer;
  LState: Cardinal;

  procedure Add(ADownX, ADownY, AUpX, AUpY: Integer);
  begin
    if LCount >= Length(LList) then
      SetLength(LList, Length(LList) * 2 + 64);
    LList[LCount].Tool := ATool;
    LList[LCount].DownX := ADownX;
    LList[LCount].DownY := ADownY;
    LList[LCount].UpX := AUpX;
    LList[LCount].UpY := AUpY;
    LList[LCount].Background := LCount mod ENDOOM_BACKGROUND_COLOR_COUNT;
    LList[LCount].Foreground := (LCount * 5 + 3) mod ENDOOM_COLOR_COUNT;
    Inc(LCount);
  end;

var
  LFirst: Integer;
  LSecond: Integer;
  LCenter: Integer;
  LX: Integer;
  LY: Integer;
  LRound: Integer;
begin
  LList := nil;
  LCount := 0;
  LState := 4242 + Cardinal(ATool);
  case ATool of
    EDITOR_TOOL_ELLIPSE, EDITOR_TOOL_FILLED_ELLIPSE:
      for LCenter := 0 to High(CENTERS) do
        for LY := 0 to ENDOOM_ROWS - 1 do
          for LX := 0 to ENDOOM_COLUMNS - 1 do
            Add(CENTERS[LCenter, 0], CENTERS[LCenter, 1], LX, LY);
    EDITOR_TOOL_FLOOD_FILL:
      for LY := 0 to ENDOOM_ROWS - 1 do
        for LX := 0 to ENDOOM_COLUMNS - 1 do
          Add(LX, LY, LX, LY);
  else
    for LFirst := 0 to High(POINTS) do
      for LSecond := 0 to High(POINTS) do
        Add(POINTS[LFirst, 0], POINTS[LFirst, 1], POINTS[LSecond, 0], POINTS[LSecond, 1]);
    for LRound := 1 to 300 do
      Add(Integer(NextRandom(LState) mod ENDOOM_COLUMNS), Integer(NextRandom(LState) mod ENDOOM_ROWS),
        Integer(NextRandom(LState) mod ENDOOM_COLUMNS), Integer(NextRandom(LState) mod ENDOOM_ROWS));
  end;
  SetLength(LList, LCount);
  Result := LList;
end;

class function TEditorScenarios.PasteCases: TArray<TEditorPasteCase>;
const
  TEXTS: array[0..9] of string = (
    'Hello',
    'Prima riga' + #13#10 + 'Seconda riga' + #13#10 + 'Terza',
    'Con a capo finale' + #13#10,
    '',
    #13#10#13#10 + 'dopo due righe vuote',
    '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789',
    'a' + #10 + 'b' + #10 + 'c' + #10 + 'd' + #10 + 'e' + #10 + 'f' + #10 + 'g' + #10 + 'h' + #10 + 'i' + #10 +
      'j' + #10 + 'k' + #10 + 'l' + #10 + 'm' + #10 + 'n' + #10 + 'o' + #10 + 'p' + #10 + 'q' + #10 + 'r' + #10 +
      's' + #10 + 't' + #10 + 'u' + #10 + 'v' + #10 + 'w' + #10 + 'x' + #10 + 'y' + #10 + 'z' + #10 + '1' + #10 + '2',
    'caff' + #$E8 + ' ' + #$B0 + #$B1 + #$B2 + #$DB,
    'riga 1' + #13#10 + '        con spazi    ' + #13#10 + #9 + 'tab',
    'x');
  STARTS: array[0..5, 0..1] of Integer = ((0, 0), (75, 3), (79, 24), (10, 23), (40, 12), (0, 24));
var
  LIndex: Integer;
  LStart: Integer;
  LCount: Integer;
begin
  SetLength(Result, Length(TEXTS) * Length(STARTS));
  LCount := 0;
  for LIndex := 0 to High(TEXTS) do
    for LStart := 0 to High(STARTS) do
    begin
      Result[LCount].Text := TEXTS[LIndex];
      Result[LCount].X := STARTS[LStart, 0];
      Result[LCount].Y := STARTS[LStart, 1];
      Result[LCount].Foreground := (LIndex + LStart) mod ENDOOM_COLOR_COUNT;
      Inc(LCount);
    end;
end;

class function TEditorScenarios.ColorsToQuantize: TArray<Cardinal>;
var
  LIndex: Integer;
  LState: Cardinal;
begin
  SetLength(Result, ENDOOM_COLOR_COUNT + 6 + 4000);
  for LIndex := 0 to ENDOOM_COLOR_COUNT - 1 do
    Result[LIndex] := ToTColor(ENDOOM_COLORS[LIndex]);
  Result[ENDOOM_COLOR_COUNT] := 0;
  Result[ENDOOM_COLOR_COUNT + 1] := $FFFFFF;
  Result[ENDOOM_COLOR_COUNT + 2] := $808080;
  Result[ENDOOM_COLOR_COUNT + 3] := $FF0000;
  Result[ENDOOM_COLOR_COUNT + 4] := $00FF00;
  Result[ENDOOM_COLOR_COUNT + 5] := $0000FF;
  LState := 31337;
  for LIndex := ENDOOM_COLOR_COUNT + 6 to High(Result) do
    Result[LIndex] := NextRandom(LState) and $FFFFFF;
end;

end.
