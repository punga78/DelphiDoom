{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the names of the keys the menus show            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.KeyNames;

interface

type
  /// <summary>
  ///   The text the key bindings menu shows for a key code of the engine (issue #185, wave 11b: the pure part of
  ///   the four m_menu units, which had the same case statement in each game)
  /// </summary>
  TInputKeyNames = class sealed
  public
    /// <summary>The name of a key</summary>
    /// <param name="AKey">The key code of the engine: the printable ASCII keys or one of the KEY_ codes of doomdef</param>
    /// <returns>
    ///   The printable character for the codes 33..126 (the keys of the numbers row that share the key of a
    ///   symbol show the symbol, as the old menu did: '=' as '+', ',' as '<', '.' as '>'), the name of the special
    ///   key otherwise, an empty string for a code the menu does not know
    /// </returns>
    class function NameOf(const AKey: Integer): string; static;
  end;

implementation

type
  TInputKeyNameEntry = record
    Code: Integer;
    Text: string;
  end;

const
  KEY_NAME_COUNT = 32;

  // KEY_CON (126), KEY_EQUALS ($3d) and KEY_MINUS ($2d) are not here: they are printable codes and the old
  // case statement never reached them
  KEY_NAMES: array[0..KEY_NAME_COUNT - 1] of TInputKeyNameEntry = (
    (Code: 32; Text: 'SPACE'),
    (Code: $ae; Text: 'RIGHTARROW'),
    (Code: $ac; Text: 'LEFTARROW'),
    (Code: $ad; Text: 'UPARROW'),
    (Code: $af; Text: 'DOWNARROW'),
    (Code: 27; Text: 'ESCAPE'),
    (Code: 13; Text: 'ENTER'),
    (Code: 9; Text: 'TAB'),
    (Code: $80 + $3b; Text: 'F1'),
    (Code: $80 + $3c; Text: 'F2'),
    (Code: $80 + $3d; Text: 'F3'),
    (Code: $80 + $3e; Text: 'F4'),
    (Code: $80 + $3f; Text: 'F5'),
    (Code: $80 + $40; Text: 'F6'),
    (Code: $80 + $41; Text: 'F7'),
    (Code: $80 + $42; Text: 'F8'),
    (Code: $80 + $43; Text: 'F9'),
    (Code: $80 + $44; Text: 'F10'),
    (Code: $80 + $57; Text: 'F11'),
    (Code: $80 + $58; Text: 'F12'),
    (Code: $80 + $59; Text: 'PRNT'),
    (Code: 127; Text: 'BACKSPACE'),
    (Code: $ff; Text: 'PAUSE'),
    (Code: $80 + $36; Text: 'SHIFT'),
    (Code: $80 + $1d; Text: 'CTRL'),
    (Code: $80 + $38; Text: 'ALT'),
    (Code: $80 + $45; Text: 'PAGEDOWN'),
    (Code: $80 + $46; Text: 'PAGEUP'),
    (Code: $80 + $47; Text: 'INS'),
    (Code: $80 + $48; Text: 'HOME'),
    (Code: $80 + $49; Text: 'END'),
    (Code: $80 + $4a; Text: 'DELETE')
  );

{ TInputKeyNames }

class function TInputKeyNames.NameOf(const AKey: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  if (AKey >= 33) and (AKey <= 126) then
  begin
    Result := Chr(AKey);
    if Result = '=' then
      Result := '+'
    else if Result = ',' then
      Result := '<'
    else if Result = '.' then
      Result := '>';
  end
  else
  begin
    for LIndex := 0 to KEY_NAME_COUNT - 1 do
      if KEY_NAMES[LIndex].Code = AKey then
      begin
        Result := KEY_NAMES[LIndex].Text;
        Break;
      end;
  end;
end;

end.
