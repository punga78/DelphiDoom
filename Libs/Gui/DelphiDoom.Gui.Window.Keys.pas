{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - events and keys of the windows of Doom 3          }
{                                                                              }
{  The part of sysEvent_t (sys\sys_public.h) and of keyNum_t (framework\       }
{  KeyInput.h) that ui\*.cpp of Doom 3 (id Software, GPL v3) uses, and the     }
{  state of the keys (idKeyInput::IsDown).                                     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Keys;

interface

const
  /// <summary>sysEventType_t</summary>
  GUI_SE_NONE = 0;
  GUI_SE_KEY = 1;
  GUI_SE_CHAR = 2;
  GUI_SE_MOUSE = 3;
  GUI_SE_JOYSTICK_AXIS = 4;
  GUI_SE_CONSOLE = 5;

  /// <summary>keyNum_t: the keys the windows use (the numbers of framework\KeyInput.h)</summary>
  GUI_K_TAB = 9;
  GUI_K_ENTER = 13;
  GUI_K_ESCAPE = 27;
  GUI_K_SPACE = 32;
  GUI_K_BACKSPACE = 127;
  GUI_K_UPARROW = 133;
  GUI_K_DOWNARROW = 134;
  GUI_K_LEFTARROW = 135;
  GUI_K_RIGHTARROW = 136;
  GUI_K_ALT = 140;
  GUI_K_CTRL = 141;
  GUI_K_SHIFT = 142;
  GUI_K_INS = 143;
  GUI_K_DEL = 144;
  GUI_K_PGDN = 145;
  GUI_K_PGUP = 146;
  GUI_K_HOME = 147;
  GUI_K_END = 148;
  GUI_K_KP_HOME = 165;
  GUI_K_KP_UPARROW = 166;
  GUI_K_KP_PGUP = 167;
  GUI_K_KP_LEFTARROW = 168;
  GUI_K_KP_5 = 169;
  GUI_K_KP_RIGHTARROW = 170;
  GUI_K_KP_END = 171;
  GUI_K_KP_DOWNARROW = 172;
  GUI_K_KP_PGDN = 173;
  GUI_K_KP_ENTER = 174;
  GUI_K_KP_INS = 175;
  GUI_K_KP_DEL = 176;
  GUI_K_MOUSE1 = 187;
  GUI_K_MOUSE2 = 188;
  GUI_K_MOUSE3 = 189;
  GUI_K_MWHEELDOWN = 195;
  GUI_K_MWHEELUP = 196;

type
  /// <summary>
  ///   sysEvent_t: <c>Value</c> and <c>Value2</c> are the key and whether it went down (SE_KEY), the character
  ///   (SE_CHAR) or the movement of the mouse (SE_MOUSE)
  /// </summary>
  TGuiSysEvent = record
    EventType: Integer;
    Value: Integer;
    Value2: Integer;
    class function Make(const AType, AValue, AValue2: Integer): TGuiSysEvent; static;
  end;

  /// <summary>idKeyInput::KeysFromBinding: the names of the keys bound to a command (for the bind windows)</summary>
  IGuiKeyBindings = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F42}']
    function KeysFromBinding(const ABinding: AnsiString): AnsiString;
  end;

  /// <summary>idKeyInput::IsDown: which keys are down</summary>
  IGuiKeyState = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F41}']
    function IsDown(const AKey: Integer): Boolean;
  end;

implementation

class function TGuiSysEvent.Make(const AType, AValue, AValue2: Integer): TGuiSysEvent;
begin
  Result.EventType := AType;
  Result.Value := AValue;
  Result.Value2 := AValue2;
end;

end.
