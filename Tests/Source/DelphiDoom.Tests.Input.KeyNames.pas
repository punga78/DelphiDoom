{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the names of the keys                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.KeyNames;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Input.KeyNames;

type
  [TestFixture]
  [Category('input')]
  TTestInputKeyNames = class
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuTuttiICodici;
    [Test]
    procedure DovrebbeDareIlSimboloPerIlTastoDelleCifre;
    [Test]
    procedure DovrebbeDareIlNomeDeiTastiSpeciali;
    [Test]
    procedure DovrebbeDareVuotoPerUnCodiceSconosciuto;
  end;

implementation

uses
  System.SysUtils;

const
  KEY_RIGHTARROW = $ae;
  KEY_LEFTARROW = $ac;
  KEY_UPARROW = $ad;
  KEY_DOWNARROW = $af;
  KEY_ESCAPE = 27;
  KEY_ENTER = 13;
  KEY_TAB = 9;
  KEY_F1 = $80 + $3b;
  KEY_F2 = $80 + $3c;
  KEY_F3 = $80 + $3d;
  KEY_F4 = $80 + $3e;
  KEY_F5 = $80 + $3f;
  KEY_F6 = $80 + $40;
  KEY_F7 = $80 + $41;
  KEY_F8 = $80 + $42;
  KEY_F9 = $80 + $43;
  KEY_F10 = $80 + $44;
  KEY_F11 = $80 + $57;
  KEY_F12 = $80 + $58;
  KEY_PRNT = $80 + $59;
  KEY_CON = 126;
  KEY_BACKSPACE = 127;
  KEY_PAUSE = $ff;
  KEY_EQUALS = $3d;
  KEY_MINUS = $2d;
  KEY_RSHIFT = $80 + $36;
  KEY_RCTRL = $80 + $1d;
  KEY_RALT = $80 + $38;
  KEY_PAGEDOWN = $80 + $45;
  KEY_PAGEUP = $80 + $46;
  KEY_INS = $80 + $47;
  KEY_HOME = $80 + $48;
  KEY_END = $80 + $49;
  KEY_DELETE = $80 + $4a;

// M_KeyToString of the four m_menu units, copied as it was (it was the same in the four games)
function OldKeyToString(const k: integer): string;
begin
  if (k >= 33) and (k <= 126) then
  begin
    result := Chr(k);
    if result = '=' then
      result := '+'
    else if result = ',' then
      result := '<'
    else if result = '.' then
      result := '>';
    exit;
  end;

  case k of
    32: result := 'SPACE';
    KEY_RIGHTARROW: result := 'RIGHTARROW';
    KEY_LEFTARROW: result := 'LEFTARROW';
    KEY_UPARROW: result := 'UPARROW';
    KEY_DOWNARROW: result := 'DOWNARROW';
    KEY_ESCAPE: result := 'ESCAPE';
    KEY_ENTER: result := 'ENTER';
    KEY_TAB: result := 'TAB';
    KEY_F1: result := 'F1';
    KEY_F2: result := 'F2';
    KEY_F3: result := 'F3';
    KEY_F4: result := 'F4';
    KEY_F5: result := 'F5';
    KEY_F6: result := 'F6';
    KEY_F7: result := 'F7';
    KEY_F8: result := 'F8';
    KEY_F9: result := 'F9';
    KEY_F10: result := 'F10';
    KEY_F11: result := 'F11';
    KEY_F12: result := 'F12';
    KEY_PRNT: result := 'PRNT';
    KEY_CON: result := 'CON';
    KEY_BACKSPACE: result := 'BACKSPACE';
    KEY_PAUSE: result := 'PAUSE';
    KEY_EQUALS: result := 'EQUALS';
    KEY_MINUS: result := 'MINUS';
    KEY_RSHIFT: result := 'SHIFT';
    KEY_RCTRL: result := 'CTRL';
    KEY_RALT: result := 'ALT';
    KEY_PAGEDOWN: result := 'PAGEDOWN';
    KEY_PAGEUP: result := 'PAGEUP';
    KEY_INS: result := 'INS';
    KEY_HOME: result := 'HOME';
    KEY_END: result := 'END';
    KEY_DELETE: result := 'DELETE';
  else
    result := '';
  end;
end;

{ TTestInputKeyNames }

procedure TTestInputKeyNames.DovrebbeEssereUgualeAlVecchioCodiceSuTuttiICodici;
var
  LKey: Integer;
begin
  for LKey := -300 to 600 do
    Assert.AreEqual(OldKeyToString(LKey), TInputKeyNames.NameOf(LKey), 'code ' + IntToStr(LKey));
end;

procedure TTestInputKeyNames.DovrebbeDareIlSimboloPerIlTastoDelleCifre;
begin
  Assert.AreEqual('+', TInputKeyNames.NameOf(Ord('=')));
  Assert.AreEqual('<', TInputKeyNames.NameOf(Ord(',')));
  Assert.AreEqual('>', TInputKeyNames.NameOf(Ord('.')));
  Assert.AreEqual('A', TInputKeyNames.NameOf(Ord('A')));
end;

procedure TTestInputKeyNames.DovrebbeDareIlNomeDeiTastiSpeciali;
begin
  Assert.AreEqual('SPACE', TInputKeyNames.NameOf(32));
  Assert.AreEqual('ESCAPE', TInputKeyNames.NameOf(27));
  Assert.AreEqual('F12', TInputKeyNames.NameOf(KEY_F12));
  Assert.AreEqual('DELETE', TInputKeyNames.NameOf(KEY_DELETE));
end;

procedure TTestInputKeyNames.DovrebbeDareVuotoPerUnCodiceSconosciuto;
begin
  Assert.AreEqual('', TInputKeyNames.NameOf(0));
  Assert.AreEqual('', TInputKeyNames.NameOf(-1));
  Assert.AreEqual('', TInputKeyNames.NameOf(1000));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestInputKeyNames);

end.
