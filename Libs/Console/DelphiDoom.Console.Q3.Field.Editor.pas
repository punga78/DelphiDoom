{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, line editing               }
{                                                                              }
{  Field_KeyDownEvent, Field_CharEvent and Field_Paste of cl_keys.c.           }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Field.Editor;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Field.Types,
  DelphiDoom.Console.Q3.Field.Intf;

type
  /// <summary>
  ///   The basic line editing of the console, the chat and the menu fields: printable characters
  ///   from char events, cursor keys, Home, End, Delete, Insert (insert or overstrike), the control
  ///   keys (ctrl-a home, ctrl-e end, ctrl-h backspace, ctrl-c clears, ctrl-v and shift-insert
  ///   paste). The overstrike mode is one for all the fields, as the global of the original, so it
  ///   lives in the editor and the fields that share it share the editor. Quirks kept: ctrl-e puts
  ///   the scroll at cursor minus width (it can go below 0), a character typed once the cursor
  ///   reaches the width always scrolls by one, overstrike does not move the end of the text
  /// </summary>
  TQ3FieldEditor = class
  strict private
    FKeys: IQ3KeyState;
    FClipboard: IQ3Clipboard;
    FOverstrike: Boolean;
    class function IsLetter(AKey: Integer; ALower: AnsiChar): Boolean; static;
    class procedure CheckCursor(const AField: TQ3EditField); static;
  public
    /// <summary>The key state and the clipboard are optional (nil = no key down, nothing to paste)</summary>
    constructor Create(const AKeys: IQ3KeyState = nil; const AClipboard: IQ3Clipboard = nil);
    /// <summary>Field_Paste: each character of the clipboard as if typed</summary>
    procedure Paste(var AField: TQ3EditField);
    /// <summary>Field_KeyDownEvent: the keys that are not printable characters</summary>
    procedure KeyDownEvent(var AField: TQ3EditField; AKey: Integer);
    /// <summary>
    ///   Field_CharEvent: a character (an ASCII code, below 32 the control keys; a negative value is a
    ///   <c>char</c> above 127 as the original reads it)
    /// </summary>
    procedure CharEvent(var AField: TQ3EditField; ACharacter: Integer);
    /// <summary>key_overstrikeMode</summary>
    property Overstrike: Boolean read FOverstrike write FOverstrike;
  end;

implementation

{ TQ3FieldEditor }

constructor TQ3FieldEditor.Create(const AKeys: IQ3KeyState; const AClipboard: IQ3Clipboard);
begin
  inherited Create;
  FKeys := AKeys;
  FClipboard := AClipboard;
end;

class function TQ3FieldEditor.IsLetter(AKey: Integer; ALower: AnsiChar): Boolean;
begin
  // tolower(key) == letter
  Result := (AKey = Ord(ALower)) or (AKey = Ord(ALower) - 32);
end;

class procedure TQ3FieldEditor.CheckCursor(const AField: TQ3EditField);
begin
  // the original moves memory with a cursor outside the buffer; here it is an error
  if (AField.Cursor < 0) or (AField.Cursor >= Q3_MAX_EDIT_LINE) or (AField.Cursor > AField.Length + 1) then
    raise EQ3ConsoleException.CreateFmt(SQ3ConsoleBadCursor, [AField.Cursor]);
end;

procedure TQ3FieldEditor.Paste(var AField: TQ3EditField);
var
  LText: AnsiString;
  LIndex: Integer;
  LByte: Integer;
begin
  if not Assigned(FClipboard) then
    Exit;
  if not FClipboard.TryGetText(LText) then
    Exit;
  for LIndex := 1 to Length(LText) do
  begin
    LByte := Ord(LText[LIndex]);
    if LByte > 127 then
      LByte := LByte - 256;
    CharEvent(AField, LByte);
  end;
end;

procedure TQ3FieldEditor.KeyDownEvent(var AField: TQ3EditField; AKey: Integer);
var
  LLength: Integer;
  LControl: Boolean;
begin
  if ((AKey = Q3_K_INS) or (AKey = Q3_K_KP_INS)) and Assigned(FKeys) and FKeys.IsDown(Q3_K_SHIFT) then
  begin
    Paste(AField);
    Exit;
  end;
  LControl := Assigned(FKeys) and FKeys.IsDown(Q3_K_CTRL);
  LLength := AField.Length;
  if AKey = Q3_K_DEL then
  begin
    if AField.Cursor < LLength then
    begin
      CheckCursor(AField);
      Move(AField.Buffer[AField.Cursor + 1], AField.Buffer[AField.Cursor], LLength - AField.Cursor);
    end;
    Exit;
  end;
  if AKey = Q3_K_RIGHTARROW then
  begin
    if AField.Cursor < LLength then
      Inc(AField.Cursor);
    if (AField.Cursor >= AField.Scroll + AField.WidthInChars) and (AField.Cursor <= LLength) then
      Inc(AField.Scroll);
    Exit;
  end;
  if AKey = Q3_K_LEFTARROW then
  begin
    if AField.Cursor > 0 then
      Dec(AField.Cursor);
    if AField.Cursor < AField.Scroll then
      Dec(AField.Scroll);
    Exit;
  end;
  if (AKey = Q3_K_HOME) or (IsLetter(AKey, 'a') and LControl) then
  begin
    AField.Cursor := 0;
    Exit;
  end;
  if (AKey = Q3_K_END) or (IsLetter(AKey, 'e') and LControl) then
  begin
    AField.Cursor := LLength;
    Exit;
  end;
  if AKey = Q3_K_INS then
    FOverstrike := not FOverstrike;
end;

procedure TQ3FieldEditor.CharEvent(var AField: TQ3EditField; ACharacter: Integer);
var
  LLength: Integer;
begin
  if ACharacter = 22 then
  begin
    // ctrl-v is paste
    Paste(AField);
    Exit;
  end;
  if ACharacter = 3 then
  begin
    // ctrl-c clears the field
    AField.Clear;
    Exit;
  end;
  LLength := AField.Length;
  if ACharacter = 8 then
  begin
    // ctrl-h is backspace
    if AField.Cursor > 0 then
    begin
      CheckCursor(AField);
      Move(AField.Buffer[AField.Cursor], AField.Buffer[AField.Cursor - 1], LLength + 1 - AField.Cursor);
      Dec(AField.Cursor);
      if AField.Cursor < AField.Scroll then
        Dec(AField.Scroll);
    end;
    Exit;
  end;
  if ACharacter = 1 then
  begin
    // ctrl-a is home
    AField.Cursor := 0;
    AField.Scroll := 0;
    Exit;
  end;
  if ACharacter = 5 then
  begin
    // ctrl-e is end
    AField.Cursor := LLength;
    AField.Scroll := AField.Cursor - AField.WidthInChars;
    Exit;
  end;
  // ignore any other non printable chars
  if ACharacter < 32 then
    Exit;
  CheckCursor(AField);
  if FOverstrike then
  begin
    if AField.Cursor = Q3_MAX_EDIT_LINE - 1 then
      Exit;
    AField.Buffer[AField.Cursor] := AnsiChar(ACharacter and $FF);
    Inc(AField.Cursor);
  end
  else
  begin
    if LLength = Q3_MAX_EDIT_LINE - 1 then
      Exit;
    Move(AField.Buffer[AField.Cursor], AField.Buffer[AField.Cursor + 1], LLength + 1 - AField.Cursor);
    AField.Buffer[AField.Cursor] := AnsiChar(ACharacter and $FF);
    Inc(AField.Cursor);
  end;
  if AField.Cursor >= AField.WidthInChars then
    Inc(AField.Scroll);
  if AField.Cursor = LLength + 1 then
    AField.Buffer[AField.Cursor] := #0;
end;

end.
