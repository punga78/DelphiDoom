{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the scan codes of the keys of the game             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.ScanCodes;

interface

uses
  Winapi.Windows, System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.ScanCodes;

type
  /// <summary>
  ///   The table from the scan codes of d_ints_h.pas to the keys of the window. The keys that the default settings
  ///   bind have to be the ones that the game used before the bindings existed; the others are checked against the
  ///   answer of Windows (MAPVK_VSC_TO_VK) where the answer does not depend on the keyboard layout
  /// </summary>
  [TestFixture]
  [Category('Greed')]
  TTestGreedScanCodes = class
  public
    [Test]
    [TestCase('north', '72,38')]
    [TestCase('east', '77,39')]
    [TestCase('south', '80,40')]
    [TestCase('west', '75,37')]
    [TestCase('fire', '29,17')]
    [TestCase('strafe', '56,18')]
    [TestCase('use', '57,32')]
    [TestCase('run', '42,16')]
    [TestCase('jump', '44,90')]
    [TestCase('useitem', '45,88')]
    [TestCase('rearview', '30,65')]
    [TestCase('lookup', '73,33')]
    [TestCase('lookdown', '81,34')]
    [TestCase('centerview', '71,36')]
    [TestCase('slideleft', '51,188')]
    [TestCase('slideright', '52,190')]
    [TestCase('invleft', '82,45')]
    [TestCase('invright', '83,46')]
    [TestCase('motionmode', '31,83')]
    procedure DovrebbeDareITastiDiPrimaPerGliScanCodeDiDefault(AScanCode, AVirtualKey: Integer);
    [Test]
    procedure ShiftDestroESinistroDovrebberoDareLoStessoTasto;
    [Test]
    procedure IlF11EIlF12DelloOriginaleDovrebberoEssereQuelliVeri;
    [Test]
    [TestCase('none', '0')]
    [TestCase('bad', '255')]
    [TestCase('over', '256')]
    [TestCase('negative', '-1')]
    [TestCase('gap', '27')]
    procedure UnCodiceCheNonETastoDovrebbeDareZero(AScanCode: Integer);
    [Test]
    procedure UnTastoDiNumeroOLetteraDovrebbeAvereUnSoloScanCode;
    [Test]
    procedure DovrebbeEssereUgualeAllaRispostaDiWindowsPerITastiCheNonDipendonoDalLayout;
  end;

implementation

procedure TTestGreedScanCodes.DovrebbeDareITastiDiPrimaPerGliScanCodeDiDefault(AScanCode, AVirtualKey: Integer);
begin
  Assert.AreEqual(AVirtualKey, TGreedScanCodes.ToVirtualKey(AScanCode));
end;

procedure TTestGreedScanCodes.ShiftDestroESinistroDovrebberoDareLoStessoTasto;
begin
  Assert.AreEqual<Integer>(VK_SHIFT, TGreedScanCodes.ToVirtualKey($2A));
  Assert.AreEqual<Integer>(VK_SHIFT, TGreedScanCodes.ToVirtualKey($36));
end;

procedure TTestGreedScanCodes.IlF11EIlF12DelloOriginaleDovrebberoEssereQuelliVeri;
begin
  Assert.AreEqual<Integer>(VK_F11, TGreedScanCodes.ToVirtualKey($D9));
  Assert.AreEqual<Integer>(VK_F12, TGreedScanCodes.ToVirtualKey($DA));
  Assert.AreEqual<Integer>(VK_F11, TGreedScanCodes.ToVirtualKey($57));
  Assert.AreEqual<Integer>(VK_F12, TGreedScanCodes.ToVirtualKey($58));
end;

procedure TTestGreedScanCodes.UnCodiceCheNonETastoDovrebbeDareZero(AScanCode: Integer);
begin
  Assert.AreEqual(0, TGreedScanCodes.ToVirtualKey(AScanCode));
end;

procedure TTestGreedScanCodes.UnTastoDiNumeroOLetteraDovrebbeAvereUnSoloScanCode;
var
  LScanCode: Integer;
  LOwner: array[0..255] of Integer;
  LVirtualKey: Integer;
begin
  // the digits and the letters are one key each (only Shift and the F11 and F12 of the original have two codes)
  FillChar(LOwner, SizeOf(LOwner), 0);
  for LScanCode := 1 to 255 do
  begin
    LVirtualKey := TGreedScanCodes.ToVirtualKey(LScanCode);
    if CharInSet(Chr(LVirtualKey), ['0'..'9', 'A'..'Z']) and (LVirtualKey <> 0) then
    begin
      Assert.AreEqual(0, LOwner[LVirtualKey], 'two scan codes for the key ' + Chr(LVirtualKey));
      LOwner[LVirtualKey] := LScanCode;
    end;
  end;
end;

procedure TTestGreedScanCodes.DovrebbeEssereUgualeAllaRispostaDiWindowsPerITastiCheNonDipendonoDalLayout;
const
  // the keys of the game that are the same on every keyboard layout (letters and the OEM keys are not checked)
  CODES: array[0..24] of Integer = (
    $01, $02, $0B, $0E, $0F, $1C, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $45, $46, $57, $58,
    $4F, $52, $53);
var
  LIndex: Integer;
begin
  for LIndex := Low(CODES) to High(CODES) do
    Assert.AreEqual(Integer(MapVirtualKey(CODES[LIndex], MAPVK_VSC_TO_VK)), TGreedScanCodes.ToVirtualKey(CODES[LIndex]),
      'scan code $' + IntToHex(CODES[LIndex], 2));
end;

end.
