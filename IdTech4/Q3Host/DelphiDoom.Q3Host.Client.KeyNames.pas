{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the key names (GENERATED)               }
{                                                                              }
{  keynames[] of cl_keys.c with the key numbers of keycodes.h, written by       }
{  Tools\Verifica\254\client-keys-pascal.sh from keys.golden.txt. Based on the  }
{  Quake III Arena GPL Source Code (id Software), Copyright (C) 1999-2005 Id    }
{  Software, Inc.; available under the GNU General Public License, version 2    }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Client.KeyNames;

interface

type
  TQ3KeyName = record
    Name: AnsiString;
    Number: Integer;
  end;

const
  Q3_KEY_NAME_COUNT = 107;

  /// <summary>keynames[]: the names that are not a lowercase ascii character or a 0xnn sequence</summary>
  Q3_KEY_NAMES: array[0..Q3_KEY_NAME_COUNT - 1] of TQ3KeyName = (
    (Name: 'TAB'; Number: 9),
    (Name: 'ENTER'; Number: 13),
    (Name: 'ESCAPE'; Number: 27),
    (Name: 'SPACE'; Number: 32),
    (Name: 'BACKSPACE'; Number: 127),
    (Name: 'UPARROW'; Number: 132),
    (Name: 'DOWNARROW'; Number: 133),
    (Name: 'LEFTARROW'; Number: 134),
    (Name: 'RIGHTARROW'; Number: 135),
    (Name: 'ALT'; Number: 136),
    (Name: 'CTRL'; Number: 137),
    (Name: 'SHIFT'; Number: 138),
    (Name: 'COMMAND'; Number: 128),
    (Name: 'CAPSLOCK'; Number: 129),
    (Name: 'F1'; Number: 145),
    (Name: 'F2'; Number: 146),
    (Name: 'F3'; Number: 147),
    (Name: 'F4'; Number: 148),
    (Name: 'F5'; Number: 149),
    (Name: 'F6'; Number: 150),
    (Name: 'F7'; Number: 151),
    (Name: 'F8'; Number: 152),
    (Name: 'F9'; Number: 153),
    (Name: 'F10'; Number: 154),
    (Name: 'F11'; Number: 155),
    (Name: 'F12'; Number: 156),
    (Name: 'INS'; Number: 139),
    (Name: 'DEL'; Number: 140),
    (Name: 'PGDN'; Number: 141),
    (Name: 'PGUP'; Number: 142),
    (Name: 'HOME'; Number: 143),
    (Name: 'END'; Number: 144),
    (Name: 'MOUSE1'; Number: 178),
    (Name: 'MOUSE2'; Number: 179),
    (Name: 'MOUSE3'; Number: 180),
    (Name: 'MOUSE4'; Number: 181),
    (Name: 'MOUSE5'; Number: 182),
    (Name: 'MWHEELUP'; Number: 184),
    (Name: 'MWHEELDOWN'; Number: 183),
    (Name: 'JOY1'; Number: 185),
    (Name: 'JOY2'; Number: 186),
    (Name: 'JOY3'; Number: 187),
    (Name: 'JOY4'; Number: 188),
    (Name: 'JOY5'; Number: 189),
    (Name: 'JOY6'; Number: 190),
    (Name: 'JOY7'; Number: 191),
    (Name: 'JOY8'; Number: 192),
    (Name: 'JOY9'; Number: 193),
    (Name: 'JOY10'; Number: 194),
    (Name: 'JOY11'; Number: 195),
    (Name: 'JOY12'; Number: 196),
    (Name: 'JOY13'; Number: 197),
    (Name: 'JOY14'; Number: 198),
    (Name: 'JOY15'; Number: 199),
    (Name: 'JOY16'; Number: 200),
    (Name: 'JOY17'; Number: 201),
    (Name: 'JOY18'; Number: 202),
    (Name: 'JOY19'; Number: 203),
    (Name: 'JOY20'; Number: 204),
    (Name: 'JOY21'; Number: 205),
    (Name: 'JOY22'; Number: 206),
    (Name: 'JOY23'; Number: 207),
    (Name: 'JOY24'; Number: 208),
    (Name: 'JOY25'; Number: 209),
    (Name: 'JOY26'; Number: 210),
    (Name: 'JOY27'; Number: 211),
    (Name: 'JOY28'; Number: 212),
    (Name: 'JOY29'; Number: 213),
    (Name: 'JOY30'; Number: 214),
    (Name: 'JOY31'; Number: 215),
    (Name: 'JOY32'; Number: 216),
    (Name: 'AUX1'; Number: 217),
    (Name: 'AUX2'; Number: 218),
    (Name: 'AUX3'; Number: 219),
    (Name: 'AUX4'; Number: 220),
    (Name: 'AUX5'; Number: 221),
    (Name: 'AUX6'; Number: 222),
    (Name: 'AUX7'; Number: 223),
    (Name: 'AUX8'; Number: 224),
    (Name: 'AUX9'; Number: 225),
    (Name: 'AUX10'; Number: 226),
    (Name: 'AUX11'; Number: 227),
    (Name: 'AUX12'; Number: 228),
    (Name: 'AUX13'; Number: 229),
    (Name: 'AUX14'; Number: 230),
    (Name: 'AUX15'; Number: 231),
    (Name: 'AUX16'; Number: 232),
    (Name: 'KP_HOME'; Number: 160),
    (Name: 'KP_UPARROW'; Number: 161),
    (Name: 'KP_PGUP'; Number: 162),
    (Name: 'KP_LEFTARROW'; Number: 163),
    (Name: 'KP_5'; Number: 164),
    (Name: 'KP_RIGHTARROW'; Number: 165),
    (Name: 'KP_END'; Number: 166),
    (Name: 'KP_DOWNARROW'; Number: 167),
    (Name: 'KP_PGDN'; Number: 168),
    (Name: 'KP_ENTER'; Number: 169),
    (Name: 'KP_INS'; Number: 170),
    (Name: 'KP_DEL'; Number: 171),
    (Name: 'KP_SLASH'; Number: 172),
    (Name: 'KP_MINUS'; Number: 173),
    (Name: 'KP_PLUS'; Number: 174),
    (Name: 'KP_NUMLOCK'; Number: 175),
    (Name: 'KP_STAR'; Number: 176),
    (Name: 'KP_EQUALS'; Number: 177),
    (Name: 'PAUSE'; Number: 131),
    (Name: 'SEMICOLON'; Number: 59)
  );

implementation

end.
