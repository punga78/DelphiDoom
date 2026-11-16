{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, the edit field             }
{                                                                              }
{  field_t of qcommon.h, the key codes of keycodes.h and the history size of   }
{  keys.h.                                                                     }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Field.Types;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf;

const
  /// <summary>MAX_EDIT_LINE: the buffer of a field, with its terminating zero</summary>
  Q3_MAX_EDIT_LINE = 256;
  /// <summary>COMMAND_HISTORY: the lines the console remembers</summary>
  Q3_COMMAND_HISTORY = 32;
  /// <summary>MAX_TOKEN_CHARS: the buffer of the shortest completion match</summary>
  Q3_MAX_TOKEN_CHARS = 1024;

  /// <summary>The keys of keycodes.h (keyNum_t) that the line editing reads</summary>
  Q3_K_TAB = 9;
  Q3_K_ENTER = 13;
  Q3_K_UPARROW = 132;
  Q3_K_DOWNARROW = 133;
  Q3_K_LEFTARROW = 134;
  Q3_K_RIGHTARROW = 135;
  Q3_K_CTRL = 137;
  Q3_K_SHIFT = 138;
  Q3_K_INS = 139;
  Q3_K_DEL = 140;
  Q3_K_PGDN = 141;
  Q3_K_PGUP = 142;
  Q3_K_HOME = 143;
  Q3_K_END = 144;
  Q3_K_KP_UPARROW = 161;
  Q3_K_KP_DOWNARROW = 167;
  Q3_K_KP_ENTER = 169;
  Q3_K_KP_INS = 170;
  Q3_K_MWHEELDOWN = 183;
  Q3_K_MWHEELUP = 184;

type
  /// <summary>
  ///   field_t: a line of text with its cursor, the first visible character and the width of the
  ///   visible part. The buffer is the 256 bytes of the original, the text ends at the first zero;
  ///   it is a record because the original copies fields by value (history, completion)
  /// </summary>
  TQ3EditField = record
    Cursor: Integer;
    Scroll: Integer;
    WidthInChars: Integer;
    Buffer: array[0..Q3_MAX_EDIT_LINE - 1] of AnsiChar;
    /// <summary>Field_Clear: no text, cursor and scroll at 0 (the width stays)</summary>
    procedure Clear;
    /// <summary>The text up to the first zero (strlen)</summary>
    function Text: AnsiString;
    /// <summary>strlen of the buffer</summary>
    function Length: Integer;
    /// <summary>
    ///   Com_sprintf into the buffer: the text is cut to 255 characters; a longer one prints
    ///   "Com_sprintf: overflow of N in 256" to the log (optional). The cursor does not move
    /// </summary>
    procedure Assign(const AText: AnsiString; const ALog: IQ3ConsoleLog = nil);
    /// <summary>Q_strcat: appends, cutting at 255 characters</summary>
    procedure Append(const AText: AnsiString);
  end;

implementation

{ TQ3EditField }

procedure TQ3EditField.Clear;
begin
  FillChar(Buffer, SizeOf(Buffer), 0);
  Cursor := 0;
  Scroll := 0;
end;

function TQ3EditField.Length: Integer;
begin
  Result := 0;
  while (Result < Q3_MAX_EDIT_LINE) and (Buffer[Result] <> #0) do
    Inc(Result);
end;

function TQ3EditField.Text: AnsiString;
begin
  SetString(Result, PAnsiChar(@Buffer[0]), Length);
end;

procedure TQ3EditField.Assign(const AText: AnsiString; const ALog: IQ3ConsoleLog);
var
  LCount: Integer;
begin
  LCount := System.Length(AText);
  if (LCount >= Q3_MAX_EDIT_LINE) and Assigned(ALog) then
    ALog.Print(Format('Com_sprintf: overflow of %d in %d'#10, [LCount, Q3_MAX_EDIT_LINE]));
  if LCount > Q3_MAX_EDIT_LINE - 1 then
    LCount := Q3_MAX_EDIT_LINE - 1;
  FillChar(Buffer, SizeOf(Buffer), 0);
  if LCount > 0 then
    Move(AText[1], Buffer[0], LCount);
end;

procedure TQ3EditField.Append(const AText: AnsiString);
var
  LLength: Integer;
  LCount: Integer;
begin
  LLength := Length;
  LCount := System.Length(AText);
  if LCount > Q3_MAX_EDIT_LINE - 1 - LLength then
    LCount := Q3_MAX_EDIT_LINE - 1 - LLength;
  if LCount > 0 then
    Move(AText[1], Buffer[LLength], LCount);
  Buffer[LLength + LCount] := #0;
end;

end.
