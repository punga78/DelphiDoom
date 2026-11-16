{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - key codes                                         }
{                                                                              }
{  The key numbers of ui\keycodes.h and the constants of ui_shared.h that      }
{  the menu input code uses (Quake III Arena, id Software, GPL v2 or later).   }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Keys;

interface

const
  K_TAB = 9;
  K_ENTER = 13;
  K_ESCAPE = 27;
  K_SPACE = 32;
  K_BACKSPACE = 127;
  K_COMMAND = 128;
  K_CAPSLOCK = 129;
  K_POWER = 130;
  K_PAUSE = 131;
  K_UPARROW = 132;
  K_DOWNARROW = 133;
  K_LEFTARROW = 134;
  K_RIGHTARROW = 135;
  K_ALT = 136;
  K_CTRL = 137;
  K_SHIFT = 138;
  K_INS = 139;
  K_DEL = 140;
  K_PGDN = 141;
  K_PGUP = 142;
  K_HOME = 143;
  K_END = 144;
  K_F1 = 145;
  K_F11 = 155;
  K_F12 = 156;
  K_KP_HOME = 160;
  K_KP_UPARROW = 161;
  K_KP_PGUP = 162;
  K_KP_LEFTARROW = 163;
  K_KP_5 = 164;
  K_KP_RIGHTARROW = 165;
  K_KP_END = 166;
  K_KP_DOWNARROW = 167;
  K_KP_PGDN = 168;
  K_KP_ENTER = 169;
  K_KP_INS = 170;
  K_KP_DEL = 171;
  K_MOUSE1 = 178;
  K_MOUSE2 = 179;
  K_MOUSE3 = 180;
  K_MOUSE4 = 181;
  K_MOUSE5 = 182;
  K_MWHEELDOWN = 183;
  K_MWHEELUP = 184;
  K_JOY1 = 185;
  K_JOY2 = 186;
  K_JOY3 = 187;
  K_JOY4 = 188;
  K_AUX1 = 217;
  K_AUX16 = 232;
  /// <summary>K_CHAR_FLAG: ORed into a key that is a typed character, not a key</summary>
  K_CHAR_FLAG = 1024;

  /// <summary>MAX_OPEN_MENUS</summary>
  GUI_MAX_OPEN_MENUS = 16;
  /// <summary>SCROLLBAR_SIZE</summary>
  GUI_SCROLLBAR_SIZE = 16.0;
  /// <summary>SLIDER_WIDTH</summary>
  GUI_SLIDER_WIDTH = 96.0;
  /// <summary>SLIDER_THUMB_WIDTH</summary>
  GUI_SLIDER_THUMB_WIDTH = 12.0;
  /// <summary>SLIDER_THUMB_HEIGHT</summary>
  GUI_SLIDER_THUMB_HEIGHT = 20.0;
  /// <summary>SCROLL_TIME_START (ms)</summary>
  GUI_SCROLL_TIME_START = 500;
  /// <summary>SCROLL_TIME_ADJUST (ms)</summary>
  GUI_SCROLL_TIME_ADJUST = 150;
  /// <summary>SCROLL_TIME_ADJUSTOFFSET (ms)</summary>
  GUI_SCROLL_TIME_ADJUSTOFFSET = 40;
  /// <summary>SCROLL_TIME_FLOOR (ms)</summary>
  GUI_SCROLL_TIME_FLOOR = 20;
  /// <summary>DOUBLE_CLICK_DELAY (ms)</summary>
  GUI_DOUBLE_CLICK_DELAY = 300;
  /// <summary>LISTBOX_IMAGE (menudef.h)</summary>
  GUI_LISTBOX_IMAGE = 1;
  /// <summary>WINDOW_STYLE_CINEMATIC (menudef.h)</summary>
  GUI_WINDOW_STYLE_CINEMATIC = 5;
  /// <summary>CURSOR_ARROW and CURSOR_SIZER (ui_shared.h)</summary>
  GUI_CURSOR_ARROW = 2;
  GUI_CURSOR_SIZER = 4;

implementation

end.
