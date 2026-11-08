{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the pixel batches              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.PixelBatch;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TPixelBatch with values written by hand; the parity with the old MMX and 3DNow assembler of
  ///   r_mmx is in the project of the tests of the assembler (DelphiDoom.Tests.Asm)
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCorePixelBatch = class(TObject)
  public
    [Test]
    procedure DovrebbeSommareConSaturazioneOgniByteConIlSuoColore;
    [Test]
    procedure DovrebbeSommareSoloIByteRichiesti;
    [Test]
    procedure DovrebbeSommareUnColoreZeroSenzaCambiareNulla;
    [Test]
    procedure DovrebbeDimezzareArrotondandoPerEccessoNeiBlocchiDiOttoByte;
    [Test]
    procedure DovrebbeDimezzareArrotondandoPerDifettoNellaCoda;
    [Test]
    procedure DovrebbeNonScrivereSeIlConteggioENulloONegativo;
  end;

implementation

uses
  DelphiDoom.MathCore.PixelBatch;

{ TTestMathCorePixelBatch }

procedure TTestMathCorePixelBatch.DovrebbeSommareConSaturazioneOgniByteConIlSuoColore;
var
  LBuffer: array[0..7] of Byte;
begin
  LBuffer[0] := 250;
  LBuffer[1] := 1;
  LBuffer[2] := 0;
  LBuffer[3] := 255;
  LBuffer[4] := 250;
  LBuffer[5] := 1;
  LBuffer[6] := 0;
  LBuffer[7] := 255;
  TPixelBatch.AddSaturated(@LBuffer[0], $01020A0A, 8);
  Assert.AreEqual(255, Integer(LBuffer[0]));
  Assert.AreEqual(11, Integer(LBuffer[1]));
  Assert.AreEqual(2, Integer(LBuffer[2]));
  Assert.AreEqual(255, Integer(LBuffer[3]));
  Assert.AreEqual(255, Integer(LBuffer[4]));
  Assert.AreEqual(11, Integer(LBuffer[5]));
  Assert.AreEqual(2, Integer(LBuffer[6]));
  Assert.AreEqual(255, Integer(LBuffer[7]));
end;

procedure TTestMathCorePixelBatch.DovrebbeSommareSoloIByteRichiesti;
var
  LBuffer: array[0..5] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 5 do
    LBuffer[LIndex] := 10;
  TPixelBatch.AddSaturated(@LBuffer[1], $04030201, 4);
  Assert.AreEqual(10, Integer(LBuffer[0]));
  Assert.AreEqual(11, Integer(LBuffer[1]));
  Assert.AreEqual(12, Integer(LBuffer[2]));
  Assert.AreEqual(13, Integer(LBuffer[3]));
  Assert.AreEqual(14, Integer(LBuffer[4]));
  Assert.AreEqual(10, Integer(LBuffer[5]));
end;

procedure TTestMathCorePixelBatch.DovrebbeSommareUnColoreZeroSenzaCambiareNulla;
var
  LBuffer: array[0..3] of Byte;
begin
  LBuffer[0] := 1;
  LBuffer[1] := 2;
  LBuffer[2] := 3;
  LBuffer[3] := 255;
  TPixelBatch.AddSaturated(@LBuffer[0], 0, 4);
  Assert.AreEqual(1, Integer(LBuffer[0]));
  Assert.AreEqual(255, Integer(LBuffer[3]));
end;

procedure TTestMathCorePixelBatch.DovrebbeDimezzareArrotondandoPerEccessoNeiBlocchiDiOttoByte;
var
  LBuffer: array[0..7] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    LBuffer[LIndex] := Byte(LIndex + 1);
  LBuffer[7] := 255;
  TPixelBatch.HalveBytes(@LBuffer[0], 8);
  // (b + 1) shr 1, as pavgusb with zero
  Assert.AreEqual(1, Integer(LBuffer[0]));
  Assert.AreEqual(1, Integer(LBuffer[1]));
  Assert.AreEqual(2, Integer(LBuffer[2]));
  Assert.AreEqual(2, Integer(LBuffer[3]));
  Assert.AreEqual(3, Integer(LBuffer[4]));
  Assert.AreEqual(3, Integer(LBuffer[5]));
  Assert.AreEqual(4, Integer(LBuffer[6]));
  Assert.AreEqual(128, Integer(LBuffer[7]));
end;

procedure TTestMathCorePixelBatch.DovrebbeDimezzareArrotondandoPerDifettoNellaCoda;
var
  LBuffer: array[0..10] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 10 do
    LBuffer[LIndex] := 5;
  TPixelBatch.HalveBytes(@LBuffer[0], 11);
  // 8 bytes in a block: (5 + 1) shr 1 = 3; the 3 of the tail: 5 shr 1 = 2
  Assert.AreEqual(3, Integer(LBuffer[7]));
  Assert.AreEqual(2, Integer(LBuffer[8]));
  Assert.AreEqual(2, Integer(LBuffer[10]));
end;

procedure TTestMathCorePixelBatch.DovrebbeNonScrivereSeIlConteggioENulloONegativo;
var
  LBuffer: array[0..3] of Byte;
begin
  LBuffer[0] := 9;
  LBuffer[1] := 9;
  LBuffer[2] := 9;
  LBuffer[3] := 9;
  TPixelBatch.AddSaturated(@LBuffer[0], $01010101, 0);
  TPixelBatch.AddSaturated(@LBuffer[0], $01010101, -4);
  TPixelBatch.HalveBytes(@LBuffer[0], 0);
  TPixelBatch.HalveBytes(@LBuffer[0], -4);
  Assert.AreEqual(9, Integer(LBuffer[0]));
  Assert.AreEqual(9, Integer(LBuffer[3]));
end;

end.
