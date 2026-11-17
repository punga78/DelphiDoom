{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the scan codes of the keys of the game           }
{  Port of xGreed (Jim Valavanis): the SC_* constants of d_ints_h.pas and the   }
{  keyboard[] that INT_ReadControls of d_ints.pas fills with I_MapVirtualKey    }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScanCodes;

interface

type
  /// <summary>
  ///   The scan codes that xGreed.ini keeps for the keys of the game (bt_north ... bt_motionmode, the SC_* of
  ///   d_ints_h.pas) and the key of the window that each one is. The original asks Windows for the scan code of every
  ///   key (I_MapVirtualKey(i, MAPVK_VSC_TO_VK)); here the answer is a fixed table, so that the game gives the
  ///   same keys on every machine and the window of Framework\GameHost, which tells the key of a message, can be
  ///   asked about it: Shift, Ctrl and Alt are the keys without a side (VK_SHIFT, VK_CONTROL, VK_MENU) because the
  ///   message does not say which side, as MAPVK_VSC_TO_VK does not
  /// </summary>
  TGreedScanCodes = class sealed
  public
    /// <summary>
    ///   The virtual key of a scan code of the original (SC_*, the set 1 codes of the PC keyboard; the F11 and F12
    ///   of the original are $D9 and $DA, and the real ones, $57 and $58, give the same keys). 0 for a scan code
    ///   that is not a key of the table (SC_NONE, SC_BAD, a number the player wrote by mistake)
    /// </summary>
    class function ToVirtualKey(AScanCode: Integer): Integer; static;
  end;

implementation

uses
  Winapi.Windows;

type
  TScanCodeKey = record
    ScanCode: Byte;
    VirtualKey: Byte;
  end;

const
  SCAN_CODE_KEYS: array[0..77] of TScanCodeKey = (
    (ScanCode: $01; VirtualKey: VK_ESCAPE),
    (ScanCode: $02; VirtualKey: Ord('1')),
    (ScanCode: $03; VirtualKey: Ord('2')),
    (ScanCode: $04; VirtualKey: Ord('3')),
    (ScanCode: $05; VirtualKey: Ord('4')),
    (ScanCode: $06; VirtualKey: Ord('5')),
    (ScanCode: $07; VirtualKey: Ord('6')),
    (ScanCode: $08; VirtualKey: Ord('7')),
    (ScanCode: $09; VirtualKey: Ord('8')),
    (ScanCode: $0A; VirtualKey: Ord('9')),
    (ScanCode: $0B; VirtualKey: Ord('0')),
    (ScanCode: $0C; VirtualKey: VK_OEM_MINUS),
    (ScanCode: $0D; VirtualKey: VK_OEM_PLUS),
    (ScanCode: $0E; VirtualKey: VK_BACK),
    (ScanCode: $0F; VirtualKey: VK_TAB),
    (ScanCode: $10; VirtualKey: Ord('Q')),
    (ScanCode: $11; VirtualKey: Ord('W')),
    (ScanCode: $12; VirtualKey: Ord('E')),
    (ScanCode: $13; VirtualKey: Ord('R')),
    (ScanCode: $14; VirtualKey: Ord('T')),
    (ScanCode: $15; VirtualKey: Ord('Y')),
    (ScanCode: $16; VirtualKey: Ord('U')),
    (ScanCode: $17; VirtualKey: Ord('I')),
    (ScanCode: $18; VirtualKey: Ord('O')),
    (ScanCode: $19; VirtualKey: Ord('P')),
    (ScanCode: $1C; VirtualKey: VK_RETURN),
    (ScanCode: $1D; VirtualKey: VK_CONTROL),
    (ScanCode: $1E; VirtualKey: Ord('A')),
    (ScanCode: $1F; VirtualKey: Ord('S')),
    (ScanCode: $20; VirtualKey: Ord('D')),
    (ScanCode: $21; VirtualKey: Ord('F')),
    (ScanCode: $22; VirtualKey: Ord('G')),
    (ScanCode: $23; VirtualKey: Ord('H')),
    (ScanCode: $24; VirtualKey: Ord('J')),
    (ScanCode: $25; VirtualKey: Ord('K')),
    (ScanCode: $26; VirtualKey: Ord('L')),
    (ScanCode: $29; VirtualKey: VK_OEM_3),
    (ScanCode: $2A; VirtualKey: VK_SHIFT),
    (ScanCode: $2C; VirtualKey: Ord('Z')),
    (ScanCode: $2D; VirtualKey: Ord('X')),
    (ScanCode: $2E; VirtualKey: Ord('C')),
    (ScanCode: $2F; VirtualKey: Ord('V')),
    (ScanCode: $30; VirtualKey: Ord('B')),
    (ScanCode: $31; VirtualKey: Ord('N')),
    (ScanCode: $32; VirtualKey: Ord('M')),
    (ScanCode: $33; VirtualKey: VK_OEM_COMMA),
    (ScanCode: $34; VirtualKey: VK_OEM_PERIOD),
    (ScanCode: $36; VirtualKey: VK_SHIFT),
    (ScanCode: $38; VirtualKey: VK_MENU),
    (ScanCode: $39; VirtualKey: VK_SPACE),
    (ScanCode: $3A; VirtualKey: VK_CAPITAL),
    (ScanCode: $3B; VirtualKey: VK_F1),
    (ScanCode: $3C; VirtualKey: VK_F2),
    (ScanCode: $3D; VirtualKey: VK_F3),
    (ScanCode: $3E; VirtualKey: VK_F4),
    (ScanCode: $3F; VirtualKey: VK_F5),
    (ScanCode: $40; VirtualKey: VK_F6),
    (ScanCode: $41; VirtualKey: VK_F7),
    (ScanCode: $42; VirtualKey: VK_F8),
    (ScanCode: $43; VirtualKey: VK_F9),
    (ScanCode: $44; VirtualKey: VK_F10),
    (ScanCode: $45; VirtualKey: VK_NUMLOCK),
    (ScanCode: $46; VirtualKey: VK_SCROLL),
    (ScanCode: $47; VirtualKey: VK_HOME),
    (ScanCode: $48; VirtualKey: VK_UP),
    (ScanCode: $49; VirtualKey: VK_PRIOR),
    (ScanCode: $4B; VirtualKey: VK_LEFT),
    (ScanCode: $4D; VirtualKey: VK_RIGHT),
    (ScanCode: $4F; VirtualKey: VK_END),
    (ScanCode: $50; VirtualKey: VK_DOWN),
    (ScanCode: $51; VirtualKey: VK_NEXT),
    (ScanCode: $52; VirtualKey: VK_INSERT),
    (ScanCode: $53; VirtualKey: VK_DELETE),
    (ScanCode: $54; VirtualKey: VK_SNAPSHOT),
    (ScanCode: $57; VirtualKey: VK_F11),
    (ScanCode: $58; VirtualKey: VK_F12),
    (ScanCode: $D9; VirtualKey: VK_F11),
    (ScanCode: $DA; VirtualKey: VK_F12)
  );

{ TGreedScanCodes }

class function TGreedScanCodes.ToVirtualKey(AScanCode: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := Low(SCAN_CODE_KEYS) to High(SCAN_CODE_KEYS) do
    if SCAN_CODE_KEYS[LIndex].ScanCode = AScanCode then
    begin
      Result := SCAN_CODE_KEYS[LIndex].VirtualKey;
      Break;
    end;
end;

end.
