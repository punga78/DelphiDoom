{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - types of the input (keys and usercmd)     }
{                                                                              }
{  Port of Doom 3 (id Software): framework\KeyInput.h, UsercmdGen.h and the    }
{  tables of UsercmdGen.cpp.                                                   }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Input.Types;

interface

const
  /// <summary>MAX_KEYS of KeyInput.cpp</summary>
  D3_MAX_KEYS = 256;
  /// <summary>USERCMD_HZ: usercmds per second</summary>
  USERCMD_HZ = 60;
  /// <summary>USERCMD_MSEC: the length of a tic in milliseconds</summary>
  USERCMD_MSEC = 1000 div USERCMD_HZ;
  /// <summary>MAX_BUFFERED_USERCMD</summary>
  D3_MAX_BUFFERED_USERCMD = 64;
  /// <summary>KEY_MOVESPEED of UsercmdGen.cpp</summary>
  D3_KEY_MOVESPEED = 127;

  /// <summary>usercmd_t.buttons bits</summary>
  BUTTON_ATTACK = 1 shl 0;
  BUTTON_RUN = 1 shl 1;
  BUTTON_ZOOM = 1 shl 2;
  BUTTON_SCORES = 1 shl 3;
  BUTTON_MLOOK = 1 shl 4;
  /// <summary>usercmd_t.flags: toggled every time an impulse command is sent</summary>
  UCF_IMPULSE_SEQUENCE = $0001;

  /// <summary>inhibit_t: the session</summary>
  INHIBIT_SESSION = 0;
  /// <summary>inhibit_t: the async code</summary>
  INHIBIT_ASYNC = 1;

  /// <summary>The key numbers of KeyInput.h (keyNum_t): normal keys are lowercased ascii</summary>
  K_TAB = 9;
  K_ENTER = 13;
  K_ESCAPE = 27;
  K_SPACE = 32;
  K_BACKSPACE = 127;
  K_COMMAND = 128;
  K_CAPSLOCK = 129;
  K_SCROLL = 130;
  K_POWER = 131;
  K_PAUSE = 132;
  K_UPARROW = 133;
  K_DOWNARROW = 134;
  K_LEFTARROW = 135;
  K_RIGHTARROW = 136;
  K_LWIN = 137;
  K_RWIN = 138;
  K_MENU = 139;
  K_ALT = 140;
  K_CTRL = 141;
  K_SHIFT = 142;
  K_INS = 143;
  K_DEL = 144;
  K_PGDN = 145;
  K_PGUP = 146;
  K_HOME = 147;
  K_END = 148;
  K_F1 = 149;
  K_F2 = 150;
  K_F3 = 151;
  K_F4 = 152;
  K_F5 = 153;
  K_F6 = 154;
  K_F7 = 155;
  K_F8 = 156;
  K_F9 = 157;
  K_F10 = 158;
  K_F11 = 159;
  K_F12 = 160;
  K_INVERTED_EXCLAMATION = 161;
  K_F13 = 162;
  K_F14 = 163;
  K_F15 = 164;
  K_KP_HOME = 165;
  K_KP_UPARROW = 166;
  K_KP_PGUP = 167;
  K_KP_LEFTARROW = 168;
  K_KP_5 = 169;
  K_KP_RIGHTARROW = 170;
  K_KP_END = 171;
  K_KP_DOWNARROW = 172;
  K_KP_PGDN = 173;
  K_KP_ENTER = 174;
  K_KP_INS = 175;
  K_KP_DEL = 176;
  K_KP_SLASH = 177;
  K_SUPERSCRIPT_TWO = 178;
  K_KP_MINUS = 179;
  K_ACUTE_ACCENT = 180;
  K_KP_PLUS = 181;
  K_KP_NUMLOCK = 182;
  K_KP_STAR = 183;
  K_KP_EQUALS = 184;
  K_MASCULINE_ORDINATOR = 186;
  K_MOUSE1 = 187;
  K_MOUSE2 = 188;
  K_MOUSE3 = 189;
  K_MOUSE4 = 190;
  K_MOUSE5 = 191;
  K_MOUSE6 = 192;
  K_MOUSE7 = 193;
  K_MOUSE8 = 194;
  K_MWHEELDOWN = 195;
  K_MWHEELUP = 196;
  K_JOY1 = 197;
  K_JOY2 = 198;
  K_JOY3 = 199;
  K_JOY4 = 200;
  K_JOY5 = 201;
  K_JOY6 = 202;
  K_JOY7 = 203;
  K_JOY8 = 204;
  K_JOY9 = 205;
  K_JOY10 = 206;
  K_JOY11 = 207;
  K_JOY12 = 208;
  K_JOY13 = 209;
  K_JOY14 = 210;
  K_JOY15 = 211;
  K_JOY16 = 212;
  K_JOY17 = 213;
  K_JOY18 = 214;
  K_JOY19 = 215;
  K_JOY20 = 216;
  K_JOY21 = 217;
  K_JOY22 = 218;
  K_JOY23 = 219;
  K_JOY24 = 220;
  K_JOY25 = 221;
  K_JOY26 = 222;
  K_JOY27 = 223;
  K_GRAVE_A = 224;
  K_JOY28 = 225;
  K_JOY29 = 226;
  K_JOY30 = 227;
  K_JOY31 = 228;
  K_JOY32 = 229;
  K_AUX1 = 230;
  K_CEDILLA_C = 231;
  K_GRAVE_E = 232;
  K_AUX2 = 233;
  K_AUX3 = 234;
  K_AUX4 = 235;
  K_GRAVE_I = 236;
  K_AUX5 = 237;
  K_AUX6 = 238;
  K_AUX7 = 239;
  K_AUX8 = 240;
  K_TILDE_N = 241;
  K_GRAVE_O = 242;
  K_AUX9 = 243;
  K_AUX10 = 244;
  K_AUX11 = 245;
  K_AUX12 = 246;
  K_AUX13 = 247;
  K_AUX14 = 248;
  K_GRAVE_U = 249;
  K_AUX15 = 250;
  K_AUX16 = 251;
  K_PRINT_SCR = 252;
  K_RIGHT_ALT = 253;
  K_LAST_KEY = 254;

  /// <summary>usercmdButton_t of UsercmdGen.cpp: the buttons that the bindings of the user commands name</summary>
  UB_NONE = 0;
  UB_UP = 1;
  UB_DOWN = 2;
  UB_LEFT = 3;
  UB_RIGHT = 4;
  UB_FORWARD = 5;
  UB_BACK = 6;
  UB_LOOKUP = 7;
  UB_LOOKDOWN = 8;
  UB_STRAFE = 9;
  UB_MOVELEFT = 10;
  UB_MOVERIGHT = 11;
  UB_BUTTON0 = 12;
  UB_BUTTON1 = 13;
  UB_BUTTON2 = 14;
  UB_BUTTON3 = 15;
  UB_BUTTON4 = 16;
  UB_BUTTON5 = 17;
  UB_BUTTON6 = 18;
  UB_BUTTON7 = 19;
  UB_ATTACK = 20;
  UB_SPEED = 21;
  UB_ZOOM = 22;
  UB_SHOWSCORES = 23;
  UB_MLOOK = 24;
  UB_IMPULSE0 = 25;
  UB_IMPULSE1 = 26;
  UB_IMPULSE2 = 27;
  UB_IMPULSE3 = 28;
  UB_IMPULSE4 = 29;
  UB_IMPULSE5 = 30;
  UB_IMPULSE6 = 31;
  UB_IMPULSE7 = 32;
  UB_IMPULSE8 = 33;
  UB_IMPULSE9 = 34;
  UB_IMPULSE10 = 35;
  UB_IMPULSE11 = 36;
  UB_IMPULSE12 = 37;
  UB_IMPULSE13 = 38;
  UB_IMPULSE14 = 39;
  UB_IMPULSE15 = 40;
  UB_IMPULSE16 = 41;
  UB_IMPULSE17 = 42;
  UB_IMPULSE18 = 43;
  UB_IMPULSE19 = 44;
  UB_IMPULSE20 = 45;
  UB_IMPULSE21 = 46;
  UB_IMPULSE22 = 47;
  UB_IMPULSE23 = 48;
  UB_IMPULSE24 = 49;
  UB_IMPULSE25 = 50;
  UB_IMPULSE26 = 51;
  UB_IMPULSE27 = 52;
  UB_IMPULSE28 = 53;
  UB_IMPULSE29 = 54;
  UB_IMPULSE30 = 55;
  UB_IMPULSE31 = 56;
  UB_IMPULSE32 = 57;
  UB_IMPULSE33 = 58;
  UB_IMPULSE34 = 59;
  UB_IMPULSE35 = 60;
  UB_IMPULSE36 = 61;
  UB_IMPULSE37 = 62;
  UB_IMPULSE38 = 63;
  UB_IMPULSE39 = 64;
  UB_IMPULSE40 = 65;
  UB_IMPULSE41 = 66;
  UB_IMPULSE42 = 67;
  UB_IMPULSE43 = 68;
  UB_IMPULSE44 = 69;
  UB_IMPULSE45 = 70;
  UB_IMPULSE46 = 71;
  UB_IMPULSE47 = 72;
  UB_IMPULSE48 = 73;
  UB_IMPULSE49 = 74;
  UB_IMPULSE50 = 75;
  UB_IMPULSE51 = 76;
  UB_IMPULSE52 = 77;
  UB_IMPULSE53 = 78;
  UB_IMPULSE54 = 79;
  UB_IMPULSE55 = 80;
  UB_IMPULSE56 = 81;
  UB_IMPULSE57 = 82;
  UB_IMPULSE58 = 83;
  UB_IMPULSE59 = 84;
  UB_IMPULSE60 = 85;
  UB_IMPULSE61 = 86;
  UB_IMPULSE62 = 87;
  UB_IMPULSE63 = 88;
  UB_MAX_BUTTONS = 89;

  /// <summary>joystickAxis_t of sys_public.h</summary>
  AXIS_SIDE = 0;
  AXIS_FORWARD = 1;
  AXIS_UP = 2;
  AXIS_ROLL = 3;
  AXIS_YAW = 4;
  AXIS_PITCH = 5;
  MAX_JOYSTICK_AXIS = 6;

  /// <summary>sys_mEvents of sys_public.h: the actions of the mouse</summary>
  M_ACTION1 = 0;
  M_ACTION2 = 1;
  M_ACTION3 = 2;
  M_ACTION4 = 3;
  M_ACTION5 = 4;
  M_ACTION6 = 5;
  M_ACTION7 = 6;
  M_ACTION8 = 7;
  M_DELTAX = 8;
  M_DELTAY = 9;
  M_DELTAZ = 10;

  /// <summary>Default values and flags of the cvars of UsercmdGen.cpp</summary>
  D3_CVAR_BOOL = 1;
  D3_CVAR_INTEGER = 2;
  D3_CVAR_FLOAT = 4;
  D3_CVAR_SYSTEM = 8;
  D3_CVAR_ARCHIVE = 64;

type
  /// <summary>usercmd_t: what the player did in one tic</summary>
  TD3Usercmd = record
    GameFrame: Integer;
    GameTime: Integer;
    DuplicateCount: Integer;
    Buttons: Byte;
    ForwardMove: ShortInt;
    RightMove: ShortInt;
    UpMove: ShortInt;
    Angles: array[0..2] of SmallInt;
    Mx: SmallInt;
    My: SmallInt;
    Impulse: ShortInt;
    Flags: Byte;
    Sequence: Integer;
    /// <summary>usercmd_t::operator==: it does not compare the frame, the time, the duplicate count nor the sequence</summary>
    function SameInput(const AOther: TD3Usercmd): Boolean;
  end;

  /// <summary>A key (keyname_t): its name, its number and the id of its localized name</summary>
  TD3KeyName = record
    Name: AnsiString;
    Key: Integer;
    StrId: AnsiString;
  end;

  /// <summary>A user command (userCmdString_t): the text that a binding uses and the button it sets</summary>
  TD3UserCommand = record
    Name: AnsiString;
    Button: Integer;
  end;

  /// <summary>A cvar that a class of this library reads: the name, the default text and the flags</summary>
  TD3CVarDefault = record
    Name: AnsiString;
    Value: AnsiString;
    Flags: Integer;
  end;

const
  /// <summary>The names of the keys that are not a single character, in the order of keynames[] of KeyInput.cpp</summary>
  D3_KEY_NAMES: array[0..116] of TD3KeyName = (
    (Name: 'TAB'; Key: K_TAB; StrId: '#str_07018'),
    (Name: 'ENTER'; Key: K_ENTER; StrId: '#str_07019'),
    (Name: 'ESCAPE'; Key: K_ESCAPE; StrId: '#str_07020'),
    (Name: 'SPACE'; Key: K_SPACE; StrId: '#str_07021'),
    (Name: 'BACKSPACE'; Key: K_BACKSPACE; StrId: '#str_07022'),
    (Name: 'UPARROW'; Key: K_UPARROW; StrId: '#str_07023'),
    (Name: 'DOWNARROW'; Key: K_DOWNARROW; StrId: '#str_07024'),
    (Name: 'LEFTARROW'; Key: K_LEFTARROW; StrId: '#str_07025'),
    (Name: 'RIGHTARROW'; Key: K_RIGHTARROW; StrId: '#str_07026'),
    (Name: 'ALT'; Key: K_ALT; StrId: '#str_07027'),
    (Name: 'RIGHTALT'; Key: K_RIGHT_ALT; StrId: '#str_07027'),
    (Name: 'CTRL'; Key: K_CTRL; StrId: '#str_07028'),
    (Name: 'SHIFT'; Key: K_SHIFT; StrId: '#str_07029'),
    (Name: 'LWIN'; Key: K_LWIN; StrId: '#str_07030'),
    (Name: 'RWIN'; Key: K_RWIN; StrId: '#str_07031'),
    (Name: 'MENU'; Key: K_MENU; StrId: '#str_07032'),
    (Name: 'COMMAND'; Key: K_COMMAND; StrId: '#str_07033'),
    (Name: 'CAPSLOCK'; Key: K_CAPSLOCK; StrId: '#str_07034'),
    (Name: 'SCROLL'; Key: K_SCROLL; StrId: '#str_07035'),
    (Name: 'PRINTSCREEN'; Key: K_PRINT_SCR; StrId: '#str_07179'),
    (Name: 'F1'; Key: K_F1; StrId: '#str_07036'),
    (Name: 'F2'; Key: K_F2; StrId: '#str_07037'),
    (Name: 'F3'; Key: K_F3; StrId: '#str_07038'),
    (Name: 'F4'; Key: K_F4; StrId: '#str_07039'),
    (Name: 'F5'; Key: K_F5; StrId: '#str_07040'),
    (Name: 'F6'; Key: K_F6; StrId: '#str_07041'),
    (Name: 'F7'; Key: K_F7; StrId: '#str_07042'),
    (Name: 'F8'; Key: K_F8; StrId: '#str_07043'),
    (Name: 'F9'; Key: K_F9; StrId: '#str_07044'),
    (Name: 'F10'; Key: K_F10; StrId: '#str_07045'),
    (Name: 'F11'; Key: K_F11; StrId: '#str_07046'),
    (Name: 'F12'; Key: K_F12; StrId: '#str_07047'),
    (Name: 'INS'; Key: K_INS; StrId: '#str_07048'),
    (Name: 'DEL'; Key: K_DEL; StrId: '#str_07049'),
    (Name: 'PGDN'; Key: K_PGDN; StrId: '#str_07050'),
    (Name: 'PGUP'; Key: K_PGUP; StrId: '#str_07051'),
    (Name: 'HOME'; Key: K_HOME; StrId: '#str_07052'),
    (Name: 'END'; Key: K_END; StrId: '#str_07053'),
    (Name: 'MOUSE1'; Key: K_MOUSE1; StrId: '#str_07054'),
    (Name: 'MOUSE2'; Key: K_MOUSE2; StrId: '#str_07055'),
    (Name: 'MOUSE3'; Key: K_MOUSE3; StrId: '#str_07056'),
    (Name: 'MOUSE4'; Key: K_MOUSE4; StrId: '#str_07057'),
    (Name: 'MOUSE5'; Key: K_MOUSE5; StrId: '#str_07058'),
    (Name: 'MOUSE6'; Key: K_MOUSE6; StrId: '#str_07059'),
    (Name: 'MOUSE7'; Key: K_MOUSE7; StrId: '#str_07060'),
    (Name: 'MOUSE8'; Key: K_MOUSE8; StrId: '#str_07061'),
    (Name: 'MWHEELUP'; Key: K_MWHEELUP; StrId: '#str_07131'),
    (Name: 'MWHEELDOWN'; Key: K_MWHEELDOWN; StrId: '#str_07132'),
    (Name: 'JOY1'; Key: K_JOY1; StrId: '#str_07062'),
    (Name: 'JOY2'; Key: K_JOY2; StrId: '#str_07063'),
    (Name: 'JOY3'; Key: K_JOY3; StrId: '#str_07064'),
    (Name: 'JOY4'; Key: K_JOY4; StrId: '#str_07065'),
    (Name: 'JOY5'; Key: K_JOY5; StrId: '#str_07066'),
    (Name: 'JOY6'; Key: K_JOY6; StrId: '#str_07067'),
    (Name: 'JOY7'; Key: K_JOY7; StrId: '#str_07068'),
    (Name: 'JOY8'; Key: K_JOY8; StrId: '#str_07069'),
    (Name: 'JOY9'; Key: K_JOY9; StrId: '#str_07070'),
    (Name: 'JOY10'; Key: K_JOY10; StrId: '#str_07071'),
    (Name: 'JOY11'; Key: K_JOY11; StrId: '#str_07072'),
    (Name: 'JOY12'; Key: K_JOY12; StrId: '#str_07073'),
    (Name: 'JOY13'; Key: K_JOY13; StrId: '#str_07074'),
    (Name: 'JOY14'; Key: K_JOY14; StrId: '#str_07075'),
    (Name: 'JOY15'; Key: K_JOY15; StrId: '#str_07076'),
    (Name: 'JOY16'; Key: K_JOY16; StrId: '#str_07077'),
    (Name: 'JOY17'; Key: K_JOY17; StrId: '#str_07078'),
    (Name: 'JOY18'; Key: K_JOY18; StrId: '#str_07079'),
    (Name: 'JOY19'; Key: K_JOY19; StrId: '#str_07080'),
    (Name: 'JOY20'; Key: K_JOY20; StrId: '#str_07081'),
    (Name: 'JOY21'; Key: K_JOY21; StrId: '#str_07082'),
    (Name: 'JOY22'; Key: K_JOY22; StrId: '#str_07083'),
    (Name: 'JOY23'; Key: K_JOY23; StrId: '#str_07084'),
    (Name: 'JOY24'; Key: K_JOY24; StrId: '#str_07085'),
    (Name: 'JOY25'; Key: K_JOY25; StrId: '#str_07086'),
    (Name: 'JOY26'; Key: K_JOY26; StrId: '#str_07087'),
    (Name: 'JOY27'; Key: K_JOY27; StrId: '#str_07088'),
    (Name: 'JOY28'; Key: K_JOY28; StrId: '#str_07089'),
    (Name: 'JOY29'; Key: K_JOY29; StrId: '#str_07090'),
    (Name: 'JOY30'; Key: K_JOY30; StrId: '#str_07091'),
    (Name: 'JOY31'; Key: K_JOY31; StrId: '#str_07092'),
    (Name: 'JOY32'; Key: K_JOY32; StrId: '#str_07093'),
    (Name: 'AUX1'; Key: K_AUX1; StrId: '#str_07094'),
    (Name: 'AUX2'; Key: K_AUX2; StrId: '#str_07095'),
    (Name: 'AUX3'; Key: K_AUX3; StrId: '#str_07096'),
    (Name: 'AUX4'; Key: K_AUX4; StrId: '#str_07097'),
    (Name: 'AUX5'; Key: K_AUX5; StrId: '#str_07098'),
    (Name: 'AUX6'; Key: K_AUX6; StrId: '#str_07099'),
    (Name: 'AUX7'; Key: K_AUX7; StrId: '#str_07100'),
    (Name: 'AUX8'; Key: K_AUX8; StrId: '#str_07101'),
    (Name: 'AUX9'; Key: K_AUX9; StrId: '#str_07102'),
    (Name: 'AUX10'; Key: K_AUX10; StrId: '#str_07103'),
    (Name: 'AUX11'; Key: K_AUX11; StrId: '#str_07104'),
    (Name: 'AUX12'; Key: K_AUX12; StrId: '#str_07105'),
    (Name: 'AUX13'; Key: K_AUX13; StrId: '#str_07106'),
    (Name: 'AUX14'; Key: K_AUX14; StrId: '#str_07107'),
    (Name: 'AUX15'; Key: K_AUX15; StrId: '#str_07108'),
    (Name: 'AUX16'; Key: K_AUX16; StrId: '#str_07109'),
    (Name: 'KP_HOME'; Key: K_KP_HOME; StrId: '#str_07110'),
    (Name: 'KP_UPARROW'; Key: K_KP_UPARROW; StrId: '#str_07111'),
    (Name: 'KP_PGUP'; Key: K_KP_PGUP; StrId: '#str_07112'),
    (Name: 'KP_LEFTARROW'; Key: K_KP_LEFTARROW; StrId: '#str_07113'),
    (Name: 'KP_5'; Key: K_KP_5; StrId: '#str_07114'),
    (Name: 'KP_RIGHTARROW'; Key: K_KP_RIGHTARROW; StrId: '#str_07115'),
    (Name: 'KP_END'; Key: K_KP_END; StrId: '#str_07116'),
    (Name: 'KP_DOWNARROW'; Key: K_KP_DOWNARROW; StrId: '#str_07117'),
    (Name: 'KP_PGDN'; Key: K_KP_PGDN; StrId: '#str_07118'),
    (Name: 'KP_ENTER'; Key: K_KP_ENTER; StrId: '#str_07119'),
    (Name: 'KP_INS'; Key: K_KP_INS; StrId: '#str_07120'),
    (Name: 'KP_DEL'; Key: K_KP_DEL; StrId: '#str_07121'),
    (Name: 'KP_SLASH'; Key: K_KP_SLASH; StrId: '#str_07122'),
    (Name: 'KP_MINUS'; Key: K_KP_MINUS; StrId: '#str_07123'),
    (Name: 'KP_PLUS'; Key: K_KP_PLUS; StrId: '#str_07124'),
    (Name: 'KP_NUMLOCK'; Key: K_KP_NUMLOCK; StrId: '#str_07125'),
    (Name: 'KP_STAR'; Key: K_KP_STAR; StrId: '#str_07126'),
    (Name: 'KP_EQUALS'; Key: K_KP_EQUALS; StrId: '#str_07127'),
    (Name: 'PAUSE'; Key: K_PAUSE; StrId: '#str_07128'),
    (Name: 'SEMICOLON'; Key: Ord(';'); StrId: '#str_07129'),
    (Name: 'APOSTROPHE'; Key: Ord(''''); StrId: '#str_07130')
  );

  /// <summary>userCmdStrings[] of UsercmdGen.cpp, without its terminator</summary>
  D3_USER_COMMANDS: array[0..87] of TD3UserCommand = (
    (Name: '_moveUp'; Button: UB_UP),
    (Name: '_moveDown'; Button: UB_DOWN),
    (Name: '_left'; Button: UB_LEFT),
    (Name: '_right'; Button: UB_RIGHT),
    (Name: '_forward'; Button: UB_FORWARD),
    (Name: '_back'; Button: UB_BACK),
    (Name: '_lookUp'; Button: UB_LOOKUP),
    (Name: '_lookDown'; Button: UB_LOOKDOWN),
    (Name: '_strafe'; Button: UB_STRAFE),
    (Name: '_moveLeft'; Button: UB_MOVELEFT),
    (Name: '_moveRight'; Button: UB_MOVERIGHT),
    (Name: '_attack'; Button: UB_ATTACK),
    (Name: '_speed'; Button: UB_SPEED),
    (Name: '_zoom'; Button: UB_ZOOM),
    (Name: '_showScores'; Button: UB_SHOWSCORES),
    (Name: '_mlook'; Button: UB_MLOOK),
    (Name: '_button0'; Button: UB_BUTTON0),
    (Name: '_button1'; Button: UB_BUTTON1),
    (Name: '_button2'; Button: UB_BUTTON2),
    (Name: '_button3'; Button: UB_BUTTON3),
    (Name: '_button4'; Button: UB_BUTTON4),
    (Name: '_button5'; Button: UB_BUTTON5),
    (Name: '_button6'; Button: UB_BUTTON6),
    (Name: '_button7'; Button: UB_BUTTON7),
    (Name: '_impulse0'; Button: UB_IMPULSE0),
    (Name: '_impulse1'; Button: UB_IMPULSE1),
    (Name: '_impulse2'; Button: UB_IMPULSE2),
    (Name: '_impulse3'; Button: UB_IMPULSE3),
    (Name: '_impulse4'; Button: UB_IMPULSE4),
    (Name: '_impulse5'; Button: UB_IMPULSE5),
    (Name: '_impulse6'; Button: UB_IMPULSE6),
    (Name: '_impulse7'; Button: UB_IMPULSE7),
    (Name: '_impulse8'; Button: UB_IMPULSE8),
    (Name: '_impulse9'; Button: UB_IMPULSE9),
    (Name: '_impulse10'; Button: UB_IMPULSE10),
    (Name: '_impulse11'; Button: UB_IMPULSE11),
    (Name: '_impulse12'; Button: UB_IMPULSE12),
    (Name: '_impulse13'; Button: UB_IMPULSE13),
    (Name: '_impulse14'; Button: UB_IMPULSE14),
    (Name: '_impulse15'; Button: UB_IMPULSE15),
    (Name: '_impulse16'; Button: UB_IMPULSE16),
    (Name: '_impulse17'; Button: UB_IMPULSE17),
    (Name: '_impulse18'; Button: UB_IMPULSE18),
    (Name: '_impulse19'; Button: UB_IMPULSE19),
    (Name: '_impulse20'; Button: UB_IMPULSE20),
    (Name: '_impulse21'; Button: UB_IMPULSE21),
    (Name: '_impulse22'; Button: UB_IMPULSE22),
    (Name: '_impulse23'; Button: UB_IMPULSE23),
    (Name: '_impulse24'; Button: UB_IMPULSE24),
    (Name: '_impulse25'; Button: UB_IMPULSE25),
    (Name: '_impulse26'; Button: UB_IMPULSE26),
    (Name: '_impulse27'; Button: UB_IMPULSE27),
    (Name: '_impulse28'; Button: UB_IMPULSE28),
    (Name: '_impulse29'; Button: UB_IMPULSE29),
    (Name: '_impulse30'; Button: UB_IMPULSE30),
    (Name: '_impulse31'; Button: UB_IMPULSE31),
    (Name: '_impulse32'; Button: UB_IMPULSE32),
    (Name: '_impulse33'; Button: UB_IMPULSE33),
    (Name: '_impulse34'; Button: UB_IMPULSE34),
    (Name: '_impulse35'; Button: UB_IMPULSE35),
    (Name: '_impulse36'; Button: UB_IMPULSE36),
    (Name: '_impulse37'; Button: UB_IMPULSE37),
    (Name: '_impulse38'; Button: UB_IMPULSE38),
    (Name: '_impulse39'; Button: UB_IMPULSE39),
    (Name: '_impulse40'; Button: UB_IMPULSE40),
    (Name: '_impulse41'; Button: UB_IMPULSE41),
    (Name: '_impulse42'; Button: UB_IMPULSE42),
    (Name: '_impulse43'; Button: UB_IMPULSE43),
    (Name: '_impulse44'; Button: UB_IMPULSE44),
    (Name: '_impulse45'; Button: UB_IMPULSE45),
    (Name: '_impulse46'; Button: UB_IMPULSE46),
    (Name: '_impulse47'; Button: UB_IMPULSE47),
    (Name: '_impulse48'; Button: UB_IMPULSE48),
    (Name: '_impulse49'; Button: UB_IMPULSE49),
    (Name: '_impulse50'; Button: UB_IMPULSE50),
    (Name: '_impulse51'; Button: UB_IMPULSE51),
    (Name: '_impulse52'; Button: UB_IMPULSE52),
    (Name: '_impulse53'; Button: UB_IMPULSE53),
    (Name: '_impulse54'; Button: UB_IMPULSE54),
    (Name: '_impulse55'; Button: UB_IMPULSE55),
    (Name: '_impulse56'; Button: UB_IMPULSE56),
    (Name: '_impulse57'; Button: UB_IMPULSE57),
    (Name: '_impulse58'; Button: UB_IMPULSE58),
    (Name: '_impulse59'; Button: UB_IMPULSE59),
    (Name: '_impulse60'; Button: UB_IMPULSE60),
    (Name: '_impulse61'; Button: UB_IMPULSE61),
    (Name: '_impulse62'; Button: UB_IMPULSE62),
    (Name: '_impulse63'; Button: UB_IMPULSE63)
  );

  /// <summary>The cvars that the usercmd generator reads (idUsercmdGenLocal::in_yawSpeed and the others)</summary>
  D3_USERCMD_CVARS: array[0..14] of TD3CVarDefault = (
    (Name: 'in_yawspeed'; Value: '140'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'in_pitchspeed'; Value: '140'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'in_anglespeedkey'; Value: '1.5'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'in_freeLook'; Value: '1'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_BOOL),
    (Name: 'in_alwaysRun'; Value: '0'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_BOOL),
    (Name: 'in_toggleRun'; Value: '0'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_BOOL),
    (Name: 'in_toggleCrouch'; Value: '0'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_BOOL),
    (Name: 'in_toggleZoom'; Value: '0'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_BOOL),
    (Name: 'sensitivity'; Value: '5'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'm_pitch'; Value: '0.022'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'm_yaw'; Value: '0.022'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'm_strafeScale'; Value: '6.25'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_FLOAT),
    (Name: 'm_smooth'; Value: '1'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_INTEGER),
    (Name: 'm_strafeSmooth'; Value: '4'; Flags: D3_CVAR_SYSTEM or D3_CVAR_ARCHIVE or D3_CVAR_INTEGER),
    (Name: 'm_showMouseRate'; Value: '0'; Flags: D3_CVAR_SYSTEM or D3_CVAR_BOOL)
  );

implementation

function TD3Usercmd.SameInput(const AOther: TD3Usercmd): Boolean;
begin
  Result := (Buttons = AOther.Buttons) and (ForwardMove = AOther.ForwardMove) and (RightMove = AOther.RightMove) and
    (UpMove = AOther.UpMove) and (Angles[0] = AOther.Angles[0]) and (Angles[1] = AOther.Angles[1]) and
    (Angles[2] = AOther.Angles[2]) and (Impulse = AOther.Impulse) and (Flags = AOther.Flags) and (Mx = AOther.Mx) and
    (My = AOther.My);
end;

end.