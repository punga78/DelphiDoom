{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - editing a text field                              }
{                                                                              }
{  Item_TextField_HandleKey of ui_shared.c (Quake III Arena, id Software, GPL  }
{  v2 or later). The text is the 1024 byte buffer of the original: what        }
{  follows the end the field keeps (a cvar longer than maxChars) is written    }
{  back with it. Based on the Quake III Arena GPL Source Code (id Software).   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.TextField;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State,
  DelphiDoom.Gui.Display.Pointer;

type
  /// <summary>The keys of an edit field or a numeric field (the cvar is the text)</summary>
  TGuiTextFieldKeys = class
  strict private
    FState: TGuiDisplayState;
    FPointer: TGuiPointer;
  public
    /// <summary>The state and the pointer are not owned</summary>
    constructor Create(const AState: TGuiDisplayState; const APointer: TGuiPointer);
    /// <summary>
    ///   Item_TextField_HandleKey: true when the key was used. A typed character comes with
    ///   <c>K_CHAR_FLAG</c>. Tab and the arrows may move the focus to another field (and make it the one being
    ///   edited); enter and escape are not used (false) so that the menu handles them. False too for an item
    ///   without a cvar.
    /// </summary>
    function HandleKey(const AItem: TGuiItem; const AKey: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.Gui.Keys;

constructor TGuiTextFieldKeys.Create(const AState: TGuiDisplayState; const APointer: TGuiPointer);
begin
  inherited Create;
  FState := AState;
  FPointer := APointer;
end;

function TGuiTextFieldKeys.HandleKey(const AItem: TGuiItem; const AKey: Integer): Boolean;
var
  LBuffer: array[0..1023] of Byte;
  LText: AnsiString;
  LLength, LKey: Integer;
  LNewItem: TGuiItem;

  procedure Store;
  var
    LEnd: Integer;
  begin
    LEnd := 0;
    while (LEnd < SizeOf(LBuffer)) and (LBuffer[LEnd] <> 0) do
      Inc(LEnd);
    SetString(LText, PAnsiChar(@LBuffer[0]), LEnd);
    if Assigned(FState.Script) then
      FState.Script.SetCvar(AItem.Cvar, LText);
  end;

  // memmove( &buff[to], &buff[from], count ); a move that leaves the buffer is not made (undefined in C)
  procedure Move(const ATo, AFrom, ACount: Integer);
  begin
    if (ACount > 0) and (ATo >= 0) and (AFrom >= 0) and (ATo + ACount <= SizeOf(LBuffer)) and
      (AFrom + ACount <= SizeOf(LBuffer)) then
      System.Move(LBuffer[AFrom], LBuffer[ATo], ACount);
  end;

begin
  Result := False;
  if AItem.Cvar = '' then
    Exit;
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LText := Copy(FState.Input.GetCvarString(AItem.Cvar), 1, SizeOf(LBuffer) - 1);
  if LText <> '' then
    System.Move(LText[1], LBuffer[0], Length(LText));
  LLength := 0;
  while LBuffer[LLength] <> 0 do
    Inc(LLength);
  if (AItem.EditField.MaxChars <> 0) and (LLength > AItem.EditField.MaxChars) then
    LLength := AItem.EditField.MaxChars;
  LKey := AKey;
  if (LKey and K_CHAR_FLAG) <> 0 then
  begin
    LKey := LKey and not K_CHAR_FLAG;
    if LKey = Ord('h') - Ord('a') + 1 then
    begin
      // ctrl-h is backspace
      if AItem.CursorPos > 0 then
      begin
        Move(AItem.CursorPos - 1, AItem.CursorPos, LLength + 1 - AItem.CursorPos);
        Dec(AItem.CursorPos);
        if AItem.CursorPos < AItem.EditField.PaintOffset then
          Dec(AItem.EditField.PaintOffset);
      end;
      Store;
      Exit(True);
    end;
    // ignore any non printable chars
    if LKey < 32 then
      Exit(True);
    if AItem.ItemType = ITEM_TYPE_NUMERICFIELD then
      if (LKey < Ord('0')) or (LKey > Ord('9')) then
        Exit(False);
    if not FState.Input.GetOverstrikeMode then
    begin
      if (LLength = GUI_MAX_EDITFIELD - 1) or ((AItem.EditField.MaxChars <> 0) and (LLength >= AItem.EditField.MaxChars)) then
        Exit(True);
      Move(AItem.CursorPos + 1, AItem.CursorPos, LLength + 1 - AItem.CursorPos);
    end
    else if (AItem.EditField.MaxChars <> 0) and (AItem.CursorPos >= AItem.EditField.MaxChars) then
      Exit(True);
    if (AItem.CursorPos >= 0) and (AItem.CursorPos < SizeOf(LBuffer)) then
      LBuffer[AItem.CursorPos] := Byte(LKey);
    Store;
    if AItem.CursorPos < LLength + 1 then
    begin
      Inc(AItem.CursorPos);
      if (AItem.EditField.MaxPaintChars <> 0) and (AItem.CursorPos > AItem.EditField.MaxPaintChars) then
        Inc(AItem.EditField.PaintOffset);
    end;
  end
  else
  begin
    if (LKey = K_DEL) or (LKey = K_KP_DEL) then
    begin
      if AItem.CursorPos < LLength then
      begin
        Move(AItem.CursorPos, AItem.CursorPos + 1, LLength - AItem.CursorPos);
        Store;
      end;
      Exit(True);
    end;
    if (LKey = K_RIGHTARROW) or (LKey = K_KP_RIGHTARROW) then
    begin
      if (AItem.EditField.MaxPaintChars <> 0) and (AItem.CursorPos >= AItem.EditField.MaxPaintChars) and
        (AItem.CursorPos < LLength) then
      begin
        Inc(AItem.CursorPos);
        Inc(AItem.EditField.PaintOffset);
        Exit(True);
      end;
      if AItem.CursorPos < LLength then
        Inc(AItem.CursorPos);
      Exit(True);
    end;
    if (LKey = K_LEFTARROW) or (LKey = K_KP_LEFTARROW) then
    begin
      if AItem.CursorPos > 0 then
        Dec(AItem.CursorPos);
      if AItem.CursorPos < AItem.EditField.PaintOffset then
        Dec(AItem.EditField.PaintOffset);
      Exit(True);
    end;
    if (LKey = K_HOME) or (LKey = K_KP_HOME) then
    begin
      AItem.CursorPos := 0;
      AItem.EditField.PaintOffset := 0;
      Exit(True);
    end;
    if (LKey = K_END) or (LKey = K_KP_END) then
    begin
      AItem.CursorPos := LLength;
      if AItem.CursorPos > AItem.EditField.MaxPaintChars then
        AItem.EditField.PaintOffset := LLength - AItem.EditField.MaxPaintChars;
      Exit(True);
    end;
    if (LKey = K_INS) or (LKey = K_KP_INS) then
    begin
      FState.Input.SetOverstrikeMode(not FState.Input.GetOverstrikeMode);
      Exit(True);
    end;
  end;
  if (LKey = K_TAB) or (LKey = K_DOWNARROW) or (LKey = K_KP_DOWNARROW) then
  begin
    LNewItem := FPointer.SetNextCursorItem(AItem.Parent);
    if Assigned(LNewItem) and ((LNewItem.ItemType = ITEM_TYPE_EDITFIELD) or (LNewItem.ItemType = ITEM_TYPE_NUMERICFIELD)) then
      FState.EditItem := LNewItem;
  end;
  if (LKey = K_UPARROW) or (LKey = K_KP_UPARROW) then
  begin
    LNewItem := FPointer.SetPrevCursorItem(AItem.Parent);
    if Assigned(LNewItem) and ((LNewItem.ItemType = ITEM_TYPE_EDITFIELD) or (LNewItem.ItemType = ITEM_TYPE_NUMERICFIELD)) then
      FState.EditItem := LNewItem;
  end;
  if (LKey = K_ENTER) or (LKey = K_KP_ENTER) or (LKey = K_ESCAPE) then
    Exit(False);
  Result := True;
end;

end.
