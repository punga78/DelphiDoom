{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - from the keys of Windows to the keys of the game        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Input.KeyMap;

interface

uses
  DelphiDoom.Input.Intf;

type
  /// <summary>The table of the virtual keys of Windows and the KEY_* codes of the game</summary>
  TEngineKeyMap = class(TInterfacedObject, IKeyMap)
  public
    function Translate(AVirtualKey: Integer): Integer;
    function TranslateModifier(AVirtualKey: Integer): Integer;
  end;

implementation

uses
  Windows,
  d_delphi,
  doomdef;

{ TEngineKeyMap }

function TEngineKeyMap.Translate(AVirtualKey: Integer): Integer;
begin
  case AVirtualKey of
    VK_LEFT, VK_NUMPAD4: Result := KEY_LEFTARROW;
    VK_RIGHT, VK_NUMPAD6: Result := KEY_RIGHTARROW;
    VK_DOWN, VK_NUMPAD2: Result := KEY_DOWNARROW;
    VK_UP, VK_NUMPAD8: Result := KEY_UPARROW;
    VK_ESCAPE: Result := KEY_ESCAPE;
    VK_RETURN: Result := KEY_ENTER;
    VK_TAB: Result := KEY_TAB;
    VK_SNAPSHOT: Result := KEY_PRNT;
    VK_F1: Result := KEY_F1;
    VK_F2: Result := KEY_F2;
    VK_F3: Result := KEY_F3;
    VK_F4: Result := KEY_F4;
    VK_F5: Result := KEY_F5;
    VK_F6: Result := KEY_F6;
    VK_F7: Result := KEY_F7;
    VK_F8: Result := KEY_F8;
    VK_F9: Result := KEY_F9;
    VK_F10: Result := KEY_F10;
    VK_F11: Result := KEY_F11;
    VK_F12: Result := KEY_F12;
    187: Result := KEY_EQUALS;
    188: Result := Ord(',');
    189: Result := KEY_MINUS;
    VK_BACK: Result := KEY_BACKSPACE;
    192: Result := KEY_CON;
    220: Result := Ord('\');
{$IFNDEF DOOM}
    219: Result := Ord('[');
    221: Result := Ord(']');
{$ENDIF}
    VK_ADD: Result := Ord('+');
    VK_SUBTRACT: Result := Ord('-');
    VK_MULTIPLY: Result := Ord('*');
    VK_DIVIDE, 191: Result := Ord('/');
    VK_DECIMAL, 190: Result := Ord('.');
    VK_PAUSE: Result := KEY_PAUSE;
    VK_NUMPAD3, VK_NEXT: Result := KEY_PAGEDOWN;
    VK_NUMPAD9, VK_PRIOR: Result := KEY_PAGEUP;
    VK_NUMPAD0, VK_INSERT: Result := KEY_INS;
    VK_NUMPAD7, VK_HOME: Result := KEY_HOME;
    VK_NUMPAD1, VK_END: Result := KEY_END;
    VK_DELETE: Result := KEY_DELETE;
  else
    if (AVirtualKey >= Ord('A')) and (AVirtualKey <= Ord('Z')) then
      Result := Ord(tolower(Chr(AVirtualKey)))
    else if AVirtualKey < 128 then
      Result := AVirtualKey
    else
      Result := 0;
  end;
end;

function TEngineKeyMap.TranslateModifier(AVirtualKey: Integer): Integer;
begin
  case AVirtualKey of
    VK_SHIFT: Result := KEY_RSHIFT;
    VK_CONTROL: Result := KEY_RCTRL;
    VK_MENU: Result := KEY_RALT;
  else
    Result := 0;
  end;
end;

end.
