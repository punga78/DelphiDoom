{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the tables of the scan codes                      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  ASCIINames, ShiftNames, SpecialNames, ScanNames of id_in.c                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ScanTables;

interface

uses
  System.SysUtils, DelphiDoom.Keen.InputTypes;

type
  /// <summary>
  ///   What a scan code of the PC keyboard is: the ASCII code (plain, with shift, and for the keys that come
  ///   after the prefix $E0) and the name that the menus show. A code the table does not know gives 0
  /// </summary>
  TKeenScanTables = class
  public
    /// <summary>ASCIINames: the character of the key without shift</summary>
    class function PlainAscii(AScan: Integer): Byte; static;
    /// <summary>ShiftNames: with a shift key down</summary>
    class function ShiftedAscii(AScan: Integer): Byte; static;
    /// <summary>SpecialNames: the keys that come after the prefix $E0</summary>
    class function SpecialAscii(AScan: Integer): Byte; static;
    /// <summary>IN_GetScanName: the name of a key, "?" for the ones that have none; codes over 127 are "?" too</summary>
    class function ScanName(AScan: Integer): AnsiString; static;
  end;

implementation

const
  PLAIN_ASCII: array[0..KEEN_NUM_CODES - 1] of Byte = (
      0,  27,  49,  50,  51,  52,  53,  54,  55,  56,  57,  48,  45,  61,   8,   9,
    113, 119, 101, 114, 116, 121, 117, 105, 111, 112,  91,  93,  13,   0,  97, 115,
    100, 102, 103, 104, 106, 107, 108,  59,  39,  96,   0,  92, 122, 120,  99, 118,
     98, 110, 109,  44,  46,  47,   0,  42,   0,  32,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,  55,  56,  57,  45,  52,  53,  54,  43,  49,
     50,  51,  48, 127,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
  );

  SHIFT_ASCII: array[0..KEEN_NUM_CODES - 1] of Byte = (
      0,  27,  33,  64,  35,  36,  37,  94,  38,  42,  40,  41,  95,  43,   8,   9,
     81,  87,  69,  82,  84,  89,  85,  73,  79,  80, 123, 125,  13,   0,  65,  83,
     68,  70,  71,  72,  74,  75,  76,  58,  34, 126,   0, 124,  90,  88,  67,  86,
     66,  78,  77,  60,  62,  63,   0,  42,   0,  32,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,  55,  56,  57,  45,  52,  53,  54,  43,  49,
     50,  51,  48, 127,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
  );

  SPECIAL_ASCII: array[0..KEEN_NUM_CODES - 1] of Byte = (
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  13,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,  47,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
  );

  // ScanNames: the names of one character (the ones with a longer name are in EXT_SCAN_CODES)
  SINGLE_NAMES: array[0..KEEN_NUM_CODES - 1] of AnsiString = (
    '?', '?', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '+', '?', '?',
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '|', '?', 'A', 'S',
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', '"', '?', '?', '?', 'Z', 'X', 'C', 'V',
    'B', 'N', 'M', ',', '.', '/', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?',
    '?', '?', '?', '?', '?', '?', '?', '?', #$0F, '?', '-', #$15, '5', #$11, '+', '?',
    #$13, '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?',
    '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?',
    '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?'
  );

  EXT_SCAN_COUNT = 35;
  EXT_SCAN_CODES: array[0..EXT_SCAN_COUNT - 1] of Byte = (
    $01, $0E, $0F, $1D, $2A, $39, $3A, $3B, $3C, $3D, $3E,
    $3F, $40, $41, $42, $43, $44, $57, $59, $46, $1C, $36,
    $37, $38, $47, $49, $4F, $51, $52, $53, $45, $48,
    $50, $4B, $4D
  );
  EXT_SCAN_NAMES: array[0..EXT_SCAN_COUNT - 1] of AnsiString = (
    'Esc', 'BkSp', 'Tab', 'Ctrl', 'LShft', 'Space', 'CapsLk', 'F1', 'F2', 'F3', 'F4',
    'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'ScrlLk', 'Enter', 'RShft',
    'PrtSc', 'Alt', 'Home', 'PgUp', 'End', 'PgDn', 'Ins', 'Del', 'NumLk', 'Up',
    'Down', 'Left', 'Right'
  );

{ TKeenScanTables }

class function TKeenScanTables.PlainAscii(AScan: Integer): Byte;
begin
  if (AScan < 0) or (AScan >= KEEN_NUM_CODES) then
    Exit(0);
  Result := PLAIN_ASCII[AScan];
end;

class function TKeenScanTables.ShiftedAscii(AScan: Integer): Byte;
begin
  if (AScan < 0) or (AScan >= KEEN_NUM_CODES) then
    Exit(0);
  Result := SHIFT_ASCII[AScan];
end;

class function TKeenScanTables.SpecialAscii(AScan: Integer): Byte;
begin
  if (AScan < 0) or (AScan >= KEEN_NUM_CODES) then
    Exit(0);
  Result := SPECIAL_ASCII[AScan];
end;

class function TKeenScanTables.ScanName(AScan: Integer): AnsiString;
var
  LIndex: Integer;
begin
  for LIndex := 0 to EXT_SCAN_COUNT - 1 do
    if EXT_SCAN_CODES[LIndex] = AScan then
      Exit(EXT_SCAN_NAMES[LIndex]);
  // the C reads the table for any byte; here a code that is not in the table of 128 is "?"
  if (AScan < 0) or (AScan >= KEEN_NUM_CODES) then
    Exit('?');
  Result := SINGLE_NAMES[AScan];
end;

end.
