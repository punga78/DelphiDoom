{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the memory fills               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.MemoryFill;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TMemoryFill with values written by hand; the parity with the old MMX assembler is in the
  ///   project of the tests of the assembler (DelphiDoom.Tests.Asm)
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreMemoryFill = class(TObject)
  public
    [Test]
    procedure DovrebbeRiempireSoloIByteRichiesti;
    [Test]
    procedure DovrebbeUsareSoloIlByteBassoDelValore;
    [Test]
    procedure DovrebbeRiempireLeParole;
    [Test]
    procedure DovrebbeRiempireLeDoppiaParole;
    [Test]
    procedure DovrebbeNonScrivereSeIlConteggioENulloONegativo;
  end;

implementation

uses
  DelphiDoom.MathCore.MemoryFill;

{ TTestMathCoreMemoryFill }

procedure TTestMathCoreMemoryFill.DovrebbeRiempireSoloIByteRichiesti;
var
  LBuffer: array[0..9] of Byte;
  LIndex: Integer;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  TMemoryFill.FillBytes(@LBuffer[2], 7, 5);
  for LIndex := 0 to 9 do
    if (LIndex >= 2) and (LIndex <= 6) then
      Assert.AreEqual(7, Integer(LBuffer[LIndex]), 'filled byte ' + IntToStr(LIndex))
    else
      Assert.AreEqual(0, Integer(LBuffer[LIndex]), 'untouched byte ' + IntToStr(LIndex));
end;

procedure TTestMathCoreMemoryFill.DovrebbeUsareSoloIlByteBassoDelValore;
var
  LBuffer: array[0..3] of Byte;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  TMemoryFill.FillBytes(@LBuffer[0], $1AB, 4);
  Assert.AreEqual($AB, Integer(LBuffer[0]));
  Assert.AreEqual($AB, Integer(LBuffer[3]));
  TMemoryFill.FillBytes(@LBuffer[0], -1, 4);
  Assert.AreEqual($FF, Integer(LBuffer[2]));
end;

procedure TTestMathCoreMemoryFill.DovrebbeRiempireLeParole;
var
  LBuffer: array[0..4] of SmallInt;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  TMemoryFill.FillWords(@LBuffer[1], -2, 3);
  Assert.AreEqual(0, Integer(LBuffer[0]));
  Assert.AreEqual(-2, Integer(LBuffer[1]));
  Assert.AreEqual(-2, Integer(LBuffer[2]));
  Assert.AreEqual(-2, Integer(LBuffer[3]));
  Assert.AreEqual(0, Integer(LBuffer[4]));
end;

procedure TTestMathCoreMemoryFill.DovrebbeRiempireLeDoppiaParole;
var
  LBuffer: array[0..4] of Cardinal;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  TMemoryFill.FillDWords(@LBuffer[1], 3, $DEADBEEF);
  Assert.AreEqual<Cardinal>(0, LBuffer[0]);
  Assert.AreEqual<Cardinal>($DEADBEEF, LBuffer[1]);
  Assert.AreEqual<Cardinal>($DEADBEEF, LBuffer[2]);
  Assert.AreEqual<Cardinal>($DEADBEEF, LBuffer[3]);
  Assert.AreEqual<Cardinal>(0, LBuffer[4]);
end;

procedure TTestMathCoreMemoryFill.DovrebbeNonScrivereSeIlConteggioENulloONegativo;
var
  LBytes: array[0..3] of Byte;
  LWords: array[0..1] of SmallInt;
  LDWords: array[0..1] of Cardinal;
begin
  FillChar(LBytes, SizeOf(LBytes), 9);
  LWords[0] := 5;
  LWords[1] := 5;
  LDWords[0] := 5;
  LDWords[1] := 5;
  TMemoryFill.FillBytes(@LBytes[0], 1, 0);
  TMemoryFill.FillBytes(@LBytes[0], 1, -3);
  TMemoryFill.FillWords(@LWords[0], 1, 0);
  TMemoryFill.FillWords(@LWords[0], 1, -3);
  TMemoryFill.FillDWords(@LDWords[0], 0, 1);
  TMemoryFill.FillDWords(@LDWords[0], -3, 1);
  Assert.AreEqual(9, Integer(LBytes[0]));
  Assert.AreEqual(9, Integer(LBytes[3]));
  Assert.AreEqual(5, Integer(LWords[0]));
  Assert.AreEqual(5, Integer(LWords[1]));
  Assert.AreEqual<Cardinal>(5, LDWords[0]);
  Assert.AreEqual<Cardinal>(5, LDWords[1]);
end;

end.
