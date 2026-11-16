{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the keyboard of Windows as the keyboard of a PC   }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.KeyboardPump;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>
  ///   Reads the table of the keys of Windows and gives the input manager the bytes that the keyboard of a PC
  ///   gives to the interrupt: the scan code of a key that went down, the same with the bit 7 set for one that
  ///   went up, after $E0 for the keys that have the prefix (the arrows and the keys of the gray block, the
  ///   right control and alt, the divide of the keypad). The pause key is $E1. The codes are the set 1 of the
  ///   US keyboard
  /// </summary>
  TKeenKeyboardPump = class(TInterfacedObject, IKeenInputPump)
  strict private
    FKeyboard: IKeyboardDevice;
    FInput: IKeenInput;
    FPrevious: TKeyStates;
  public
    constructor Create(const AKeyboard: IKeyboardDevice; const AInput: IKeenInput);
    procedure Pump;
    /// <summary>The scan code of a virtual key and whether it has the prefix $E0; 0 when the key has none</summary>
    class function ScanOf(AVirtualKey: Integer; out AExtended: Boolean): Byte; static;
  end;

implementation

type
  TKeyEntry = record
    VirtualKey: Byte;
    Scan: Byte;
    Extended: Boolean;
  end;

const
  VK_PAUSE_KEY = $13;

  KEY_TABLE: array[0..100] of TKeyEntry = (
    (VirtualKey: $1B; Scan: $01; Extended: False),
    (VirtualKey: $31; Scan: $02; Extended: False),
    (VirtualKey: $32; Scan: $03; Extended: False),
    (VirtualKey: $33; Scan: $04; Extended: False),
    (VirtualKey: $34; Scan: $05; Extended: False),
    (VirtualKey: $35; Scan: $06; Extended: False),
    (VirtualKey: $36; Scan: $07; Extended: False),
    (VirtualKey: $37; Scan: $08; Extended: False),
    (VirtualKey: $38; Scan: $09; Extended: False),
    (VirtualKey: $39; Scan: $0A; Extended: False),
    (VirtualKey: $30; Scan: $0B; Extended: False),
    (VirtualKey: $BD; Scan: $0C; Extended: False),
    (VirtualKey: $BB; Scan: $0D; Extended: False),
    (VirtualKey: $08; Scan: $0E; Extended: False),
    (VirtualKey: $09; Scan: $0F; Extended: False),
    (VirtualKey: $51; Scan: $10; Extended: False),
    (VirtualKey: $57; Scan: $11; Extended: False),
    (VirtualKey: $45; Scan: $12; Extended: False),
    (VirtualKey: $52; Scan: $13; Extended: False),
    (VirtualKey: $54; Scan: $14; Extended: False),
    (VirtualKey: $59; Scan: $15; Extended: False),
    (VirtualKey: $55; Scan: $16; Extended: False),
    (VirtualKey: $49; Scan: $17; Extended: False),
    (VirtualKey: $4F; Scan: $18; Extended: False),
    (VirtualKey: $50; Scan: $19; Extended: False),
    (VirtualKey: $DB; Scan: $1A; Extended: False),
    (VirtualKey: $DD; Scan: $1B; Extended: False),
    (VirtualKey: $0D; Scan: $1C; Extended: False),
    (VirtualKey: $A2; Scan: $1D; Extended: False),
    (VirtualKey: $41; Scan: $1E; Extended: False),
    (VirtualKey: $53; Scan: $1F; Extended: False),
    (VirtualKey: $44; Scan: $20; Extended: False),
    (VirtualKey: $46; Scan: $21; Extended: False),
    (VirtualKey: $47; Scan: $22; Extended: False),
    (VirtualKey: $48; Scan: $23; Extended: False),
    (VirtualKey: $4A; Scan: $24; Extended: False),
    (VirtualKey: $4B; Scan: $25; Extended: False),
    (VirtualKey: $4C; Scan: $26; Extended: False),
    (VirtualKey: $BA; Scan: $27; Extended: False),
    (VirtualKey: $DE; Scan: $28; Extended: False),
    (VirtualKey: $C0; Scan: $29; Extended: False),
    (VirtualKey: $A0; Scan: $2A; Extended: False),
    (VirtualKey: $DC; Scan: $2B; Extended: False),
    (VirtualKey: $5A; Scan: $2C; Extended: False),
    (VirtualKey: $58; Scan: $2D; Extended: False),
    (VirtualKey: $43; Scan: $2E; Extended: False),
    (VirtualKey: $56; Scan: $2F; Extended: False),
    (VirtualKey: $42; Scan: $30; Extended: False),
    (VirtualKey: $4E; Scan: $31; Extended: False),
    (VirtualKey: $4D; Scan: $32; Extended: False),
    (VirtualKey: $BC; Scan: $33; Extended: False),
    (VirtualKey: $BE; Scan: $34; Extended: False),
    (VirtualKey: $BF; Scan: $35; Extended: False),
    (VirtualKey: $A1; Scan: $36; Extended: False),
    (VirtualKey: $6A; Scan: $37; Extended: False),
    (VirtualKey: $A4; Scan: $38; Extended: False),
    (VirtualKey: $20; Scan: $39; Extended: False),
    (VirtualKey: $14; Scan: $3A; Extended: False),
    (VirtualKey: $70; Scan: $3B; Extended: False),
    (VirtualKey: $71; Scan: $3C; Extended: False),
    (VirtualKey: $72; Scan: $3D; Extended: False),
    (VirtualKey: $73; Scan: $3E; Extended: False),
    (VirtualKey: $74; Scan: $3F; Extended: False),
    (VirtualKey: $75; Scan: $40; Extended: False),
    (VirtualKey: $76; Scan: $41; Extended: False),
    (VirtualKey: $77; Scan: $42; Extended: False),
    (VirtualKey: $78; Scan: $43; Extended: False),
    (VirtualKey: $79; Scan: $44; Extended: False),
    (VirtualKey: $90; Scan: $45; Extended: False),
    (VirtualKey: $91; Scan: $46; Extended: False),
    (VirtualKey: $67; Scan: $47; Extended: False),
    (VirtualKey: $68; Scan: $48; Extended: False),
    (VirtualKey: $69; Scan: $49; Extended: False),
    (VirtualKey: $6D; Scan: $4A; Extended: False),
    (VirtualKey: $64; Scan: $4B; Extended: False),
    (VirtualKey: $65; Scan: $4C; Extended: False),
    (VirtualKey: $66; Scan: $4D; Extended: False),
    (VirtualKey: $6B; Scan: $4E; Extended: False),
    (VirtualKey: $61; Scan: $4F; Extended: False),
    (VirtualKey: $62; Scan: $50; Extended: False),
    (VirtualKey: $63; Scan: $51; Extended: False),
    (VirtualKey: $60; Scan: $52; Extended: False),
    (VirtualKey: $6E; Scan: $53; Extended: False),
    (VirtualKey: $7A; Scan: $57; Extended: False),
    // sc_F12 of the game is $59 (the key sends $58): the game asks for its own constant
    (VirtualKey: $7B; Scan: $59; Extended: False),
    (VirtualKey: $6F; Scan: $35; Extended: True),
    (VirtualKey: $A3; Scan: $1D; Extended: True),
    (VirtualKey: $A5; Scan: $38; Extended: True),
    (VirtualKey: $24; Scan: $47; Extended: True),
    (VirtualKey: $26; Scan: $48; Extended: True),
    (VirtualKey: $21; Scan: $49; Extended: True),
    (VirtualKey: $25; Scan: $4B; Extended: True),
    (VirtualKey: $27; Scan: $4D; Extended: True),
    (VirtualKey: $23; Scan: $4F; Extended: True),
    (VirtualKey: $28; Scan: $50; Extended: True),
    (VirtualKey: $22; Scan: $51; Extended: True),
    (VirtualKey: $2D; Scan: $52; Extended: True),
    (VirtualKey: $2E; Scan: $53; Extended: True),
    (VirtualKey: $5B; Scan: $5B; Extended: True),
    (VirtualKey: $5C; Scan: $5C; Extended: True),
    (VirtualKey: $5D; Scan: $5D; Extended: True)

  );

{ TKeenKeyboardPump }

constructor TKeenKeyboardPump.Create(const AKeyboard: IKeyboardDevice; const AInput: IKeenInput);
begin
  inherited Create;
  if not Assigned(AKeyboard) then
    raise EArgumentNilException.Create('AKeyboard');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  FKeyboard := AKeyboard;
  FInput := AInput;
  FillChar(FPrevious, SizeOf(FPrevious), 0);
end;

class function TKeenKeyboardPump.ScanOf(AVirtualKey: Integer; out AExtended: Boolean): Byte;
var
  LIndex: Integer;
begin
  AExtended := False;
  Result := 0;
  for LIndex := 0 to High(KEY_TABLE) do
    if KEY_TABLE[LIndex].VirtualKey = AVirtualKey then
    begin
      AExtended := KEY_TABLE[LIndex].Extended;
      Exit(KEY_TABLE[LIndex].Scan);
    end;
end;

procedure TKeenKeyboardPump.Pump;
var
  LStates: TKeyStates;
  LIndex: Integer;
  LDown: Boolean;
  LWasDown: Boolean;
begin
  if not FKeyboard.ReadState(LStates) then
    Exit;
  for LIndex := 0 to High(KEY_TABLE) do
  begin
    LDown := (LStates[KEY_TABLE[LIndex].VirtualKey] and KEYSTATE_DOWN) <> 0;
    LWasDown := (FPrevious[KEY_TABLE[LIndex].VirtualKey] and KEYSTATE_DOWN) <> 0;
    if LDown = LWasDown then
      Continue;
    if KEY_TABLE[LIndex].Extended then
      FInput.KeyService($E0);
    if LDown then
      FInput.KeyService(KEY_TABLE[LIndex].Scan)
    else
      FInput.KeyService(KEY_TABLE[LIndex].Scan or $80);
  end;
  // the pause key: the interrupt gets $E1 when it goes down
  if ((LStates[VK_PAUSE_KEY] and KEYSTATE_DOWN) <> 0) and ((FPrevious[VK_PAUSE_KEY] and KEYSTATE_DOWN) = 0) then
    FInput.KeyService($E1);
  FPrevious := LStates;
end;

end.
