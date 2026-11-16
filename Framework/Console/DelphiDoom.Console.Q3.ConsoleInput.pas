{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, the input line of the      }
{  console                                                                     }
{                                                                              }
{  Console_Key of cl_keys.c: Enter, Tab, the history, the scrolling keys and   }
{  the line editing, on the console field (g_consoleField).                    }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.ConsoleInput;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.Field.Types,
  DelphiDoom.Console.Q3.Field.Intf, DelphiDoom.Console.Q3.Field.Editor, DelphiDoom.Console.Q3.Field.History,
  DelphiDoom.Console.Q3.Field.Completer;

type
  /// <summary>
  ///   The line the player types in the console. A key goes to <c>Key</c>: ctrl-l clears the screen,
  ///   Enter runs the line (a line without a leading slash or backslash is a command only when the
  ///   client is not in the game, else it is a chat message, "cmd say"), Tab completes, the up and
  ///   down arrows (ctrl-p and ctrl-n, shift and the mouse wheel) walk the history, Page Up and Page Down
  ///   and the wheel scroll, ctrl-Home and ctrl-End go to the top and the bottom, any other key is
  ///   line editing. An empty line is echoed and not added to the history. The history keys copy a
  ///   whole field: its width comes with it (0 for a slot never used)
  /// </summary>
  TQ3ConsoleInput = class
  strict private
    FBuffer: IQ3CommandBuffer;
    FLog: IQ3ConsoleLog;
    FKeys: IQ3KeyState;
    FScroller: IQ3ConsoleScroller;
    FClient: IQ3ClientState;
    FEditor: TQ3FieldEditor;
    FHistory: TQ3FieldHistory;
    FCompleter: TQ3FieldCompleter;
    FField: TQ3EditField;
    FFieldWidth: Integer;
    class function IsLetter(AKey: Integer; ALower: AnsiChar): Boolean; static;
    function IsKeyDown(AKey: Integer): Boolean;
    procedure Print(const AText: string);
    procedure Submit;
  public
    /// <summary>
    ///   The editor (and its overstrike state), the history and the completer are given; the log,
    ///   the key state, the scroller and the client state are optional (nil = nothing happens, no key
    ///   down, not in the game and not disconnected). The editor, history and completer are not owned
    /// </summary>
    constructor Create(const ABuffer: IQ3CommandBuffer; AEditor: TQ3FieldEditor; AHistory: TQ3FieldHistory;
      ACompleter: TQ3FieldCompleter; const ALog: IQ3ConsoleLog = nil; const AKeys: IQ3KeyState = nil;
      const AScroller: IQ3ConsoleScroller = nil; const AClient: IQ3ClientState = nil);
    /// <summary>Console_Key</summary>
    procedure Key(AKey: Integer);
    /// <summary>A character typed (Field_CharEvent on the console field)</summary>
    procedure Character(ACharacter: Integer);
    /// <summary>g_consoleField</summary>
    property Field: TQ3EditField read FField write FField;
    /// <summary>g_console_field_width: the width a line gets once it has been run</summary>
    property FieldWidth: Integer read FFieldWidth write FFieldWidth;
  end;

implementation

{ TQ3ConsoleInput }

constructor TQ3ConsoleInput.Create(const ABuffer: IQ3CommandBuffer; AEditor: TQ3FieldEditor;
  AHistory: TQ3FieldHistory; ACompleter: TQ3FieldCompleter; const ALog: IQ3ConsoleLog; const AKeys: IQ3KeyState;
  const AScroller: IQ3ConsoleScroller; const AClient: IQ3ClientState);
begin
  inherited Create;
  FBuffer := ABuffer;
  FEditor := AEditor;
  FHistory := AHistory;
  FCompleter := ACompleter;
  FLog := ALog;
  FKeys := AKeys;
  FScroller := AScroller;
  FClient := AClient;
end;

class function TQ3ConsoleInput.IsLetter(AKey: Integer; ALower: AnsiChar): Boolean;
begin
  Result := (AKey = Ord(ALower)) or (AKey = Ord(ALower) - 32);
end;

function TQ3ConsoleInput.IsKeyDown(AKey: Integer): Boolean;
begin
  Result := Assigned(FKeys) and FKeys.IsDown(AKey);
end;

procedure TQ3ConsoleInput.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

procedure TQ3ConsoleInput.Character(ACharacter: Integer);
begin
  FEditor.CharEvent(FField, ACharacter);
end;

procedure TQ3ConsoleInput.Submit;
var
  LText: AnsiString;
begin
  LText := FField.Text;
  // outside the game a line without a slash is a command: the slash is put in front
  if not (Assigned(FClient) and FClient.IsActive) and (FField.Buffer[0] <> '\') and (FField.Buffer[0] <> '/') then
  begin
    FField.Assign('\' + LText, FLog);
    Inc(FField.Cursor);
  end;
  LText := FField.Text;
  Print(Format(']%s'#10, [string(LText)]));
  // a leading slash is an explicit command
  if (FField.Buffer[0] = '\') or (FField.Buffer[0] = '/') then
  begin
    FBuffer.AddText(Copy(LText, 2, MaxInt));
    FBuffer.AddText(#10);
  end
  else if FField.Buffer[0] = #0 then
    Exit
  else
  begin
    // other text is a chat message
    FBuffer.AddText('cmd say ');
    FBuffer.AddText(LText);
    FBuffer.AddText(#10);
  end;
  FHistory.Add(FField);
  FField.Clear;
  FField.WidthInChars := FFieldWidth;
  if Assigned(FClient) and FClient.IsDisconnected then
    FClient.UpdateScreen;
end;

procedure TQ3ConsoleInput.Key(AKey: Integer);
var
  LControl: Boolean;
  LShift: Boolean;
begin
  LControl := IsKeyDown(Q3_K_CTRL);
  LShift := IsKeyDown(Q3_K_SHIFT);
  // ctrl-l clears the screen
  if (AKey = Ord('l')) and LControl then
  begin
    FBuffer.AddText('clear'#10);
    Exit;
  end;
  if (AKey = Q3_K_ENTER) or (AKey = Q3_K_KP_ENTER) then
  begin
    Submit;
    Exit;
  end;
  if AKey = Q3_K_TAB then
  begin
    FCompleter.Complete(FField);
    Exit;
  end;
  if ((AKey = Q3_K_MWHEELUP) and LShift) or (AKey = Q3_K_UPARROW) or (AKey = Q3_K_KP_UPARROW) or
    (IsLetter(AKey, 'p') and LControl) then
  begin
    FHistory.Previous(FField);
    Exit;
  end;
  if ((AKey = Q3_K_MWHEELDOWN) and LShift) or (AKey = Q3_K_DOWNARROW) or (AKey = Q3_K_KP_DOWNARROW) or
    (IsLetter(AKey, 'n') and LControl) then
  begin
    FHistory.Next(FField);
    Exit;
  end;
  if AKey = Q3_K_PGUP then
  begin
    if Assigned(FScroller) then
      FScroller.PageUp;
    Exit;
  end;
  if AKey = Q3_K_PGDN then
  begin
    if Assigned(FScroller) then
      FScroller.PageDown;
    Exit;
  end;
  if AKey = Q3_K_MWHEELUP then
  begin
    if Assigned(FScroller) then
    begin
      FScroller.PageUp;
      // hold ctrl to accelerate the scrolling
      if LControl then
      begin
        FScroller.PageUp;
        FScroller.PageUp;
      end;
    end;
    Exit;
  end;
  if AKey = Q3_K_MWHEELDOWN then
  begin
    if Assigned(FScroller) then
    begin
      FScroller.PageDown;
      if LControl then
      begin
        FScroller.PageDown;
        FScroller.PageDown;
      end;
    end;
    Exit;
  end;
  if (AKey = Q3_K_HOME) and LControl then
  begin
    if Assigned(FScroller) then
      FScroller.Top;
    Exit;
  end;
  if (AKey = Q3_K_END) and LControl then
  begin
    if Assigned(FScroller) then
      FScroller.Bottom;
    Exit;
  end;
  // the normal line editing
  FEditor.KeyDownEvent(FField, AKey);
end;

end.
