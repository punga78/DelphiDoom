{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - the pixel batches (r_mmx) }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AsmParity.PixelBatch;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of R_BatchColorAdd32_MMX and R_BatchColorShade_AMD of r_mmx (in the 32 bit build the
  ///   MMX and 3DNow assembler) with TPixelBatch, on every length and misalignment. The 3DNow
  ///   instruction (pavgusb) does not exist on the processors of today (AMD took it away with
  ///   Zen): then the assembler is not run and the Pascal function is checked against the formula
  ///   of the instruction.
  /// </summary>
  [TestFixture]
  [Category('asm')]
  TTestAsmPixelBatch = class(TObject)
  strict private
    FSavedMmx: Byte;
    FSaved3DNow: Byte;
    FHasMmx: Boolean;
    FHas3DNow: Boolean;
    procedure AssertSameBytes(const AExpected, AActual: TBytes; const AMessage: string);
    function RandomBuffer(ASize: Integer; var AState: Cardinal): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeSommareConSaturazioneCometMmx;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiBytePerOttoCheNonEMultiplo;
    [Test]
    procedure DovrebbeLasciareInvariatoSeIlColoreEZero;
    [Test]
    procedure DovrebbeSommareIlColoreAOgniByteDelPixel;
    [Test]
    procedure DovrebbeDimezzareConLaFormulaDiPavgusb;
    [Test]
    procedure DovrebbeDimezzareCometDreNowSeCeLIstruzione;
  end;

implementation

uses
  d_delphi, r_mmx, DelphiDoom.MathCore.PixelBatch;

function AsmIsProcessorFeaturePresent(AFeature: Cardinal): LongBool; stdcall;
  external 'kernel32.dll' name 'IsProcessorFeaturePresent';

{ TTestAsmPixelBatch }

procedure TTestAsmPixelBatch.AssertSameBytes(const AExpected, AActual: TBytes;
  const AMessage: string);
var
  LIndex: Integer;
begin
  Assert.AreEqual(Length(AExpected), Length(AActual), AMessage + ': length');
  for LIndex := 0 to High(AExpected) do
    if AExpected[LIndex] <> AActual[LIndex] then
      Assert.Fail(System.SysUtils.Format('%s: byte %d expected $%.2x found $%.2x',
        [AMessage, LIndex, AExpected[LIndex], AActual[LIndex]]));
end;

function TTestAsmPixelBatch.RandomBuffer(ASize: Integer; var AState: Cardinal): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
  begin
    AState := AState xor (AState shl 13);
    AState := AState xor (AState shr 17);
    AState := AState xor (AState shl 5);
    Result[LIndex] := Byte(AState shr 11);
  end;
end;

procedure TTestAsmPixelBatch.Setup;
begin
  FSavedMmx := d_delphi.mmxMachine;
  FSaved3DNow := d_delphi.AMD3DNowMachine;
  // PF_MMX_INSTRUCTIONS_AVAILABLE = 3, PF_3DNOW_INSTRUCTIONS_AVAILABLE = 7
  FHasMmx := AsmIsProcessorFeaturePresent(3);
  FHas3DNow := AsmIsProcessorFeaturePresent(7);
  if FHasMmx then
    d_delphi.mmxMachine := 1;
  if FHas3DNow then
    d_delphi.AMD3DNowMachine := 1;
end;

procedure TTestAsmPixelBatch.TearDown;
begin
  d_delphi.mmxMachine := FSavedMmx;
  d_delphi.AMD3DNowMachine := FSaved3DNow;
end;

procedure TTestAsmPixelBatch.DovrebbeSommareConSaturazioneCometMmx;
const
  // pixels: the function wants an even number (a multiple of 8 bytes)
  PIXELS: array[0..13] of Integer = (0, 2, 4, 6, 8, 10, 14, 16, 18, 30, 32, 34, 100, 258);
  COLORS: array[0..6] of Cardinal = ($01010101, $FF000000, $000000FF, $80808080, $FEFEFEFE,
    $12345678, $FFFFFFFF);
var
  LPixels: Integer;
  LColor: Cardinal;
  LState: Cardinal;
  LExpected: TBytes;
  LActual: TBytes;
  LResult: Boolean;
begin
  LState := $9E3779B9;
  for LPixels in PIXELS do
    for LColor in COLORS do
    begin
      LExpected := RandomBuffer(LPixels * 4, LState);
      LActual := Copy(LExpected);
      if LPixels > 0 then
      begin
        TPixelBatch.AddSaturated(@LExpected[0], LColor, LPixels * 4);
        LResult := r_mmx.R_BatchColorAdd32_MMX(@LActual[0], LColor, LPixels);
      end
      else
        LResult := r_mmx.R_BatchColorAdd32_MMX(nil, LColor, 0);
      // without MMX the old function gives false and does not write (the engine then adds in
      // Pascal): nothing to compare
      if (not LResult) and (not FHasMmx) then
        Continue;
      Assert.IsTrue(LResult, 'the function must say that it did the work');
      AssertSameBytes(LExpected, LActual,
        System.SysUtils.Format('R_BatchColorAdd32_MMX pixels=%d color=$%.8x', [LPixels, LColor]));
    end;
end;

procedure TTestAsmPixelBatch.DovrebbeRifiutareUnNumeroDiBytePerOttoCheNonEMultiplo;
var
  LBuffer: TBytes;
  LReference: TBytes;
  LState: Cardinal;
begin
  LState := $85EBCA6B;
  LBuffer := RandomBuffer(64, LState);
  LReference := Copy(LBuffer);
  // 3 pixels are 12 bytes: not a multiple of 8
  Assert.IsFalse(r_mmx.R_BatchColorAdd32_MMX(@LBuffer[0], $01010101, 3));
  AssertSameBytes(LReference, LBuffer, 'odd number of pixels');
end;

procedure TTestAsmPixelBatch.DovrebbeLasciareInvariatoSeIlColoreEZero;
var
  LBuffer: TBytes;
  LReference: TBytes;
  LState: Cardinal;
begin
  LState := $C2B2AE35;
  LBuffer := RandomBuffer(64, LState);
  LReference := Copy(LBuffer);
  // true when MMX is there, false when it is not: in both cases the pixels do not change
  r_mmx.R_BatchColorAdd32_MMX(@LBuffer[0], 0, 16);
  AssertSameBytes(LReference, LBuffer, 'color zero');
end;

procedure TTestAsmPixelBatch.DovrebbeSommareIlColoreAOgniByteDelPixel;
var
  LBuffer: TBytes;
begin
  // blue, green, red and the fourth byte of every pixel get their own byte of the color
  SetLength(LBuffer, 8);
  LBuffer[0] := 250;
  LBuffer[1] := 1;
  LBuffer[2] := 0;
  LBuffer[3] := 255;
  LBuffer[4] := 250;
  LBuffer[5] := 1;
  LBuffer[6] := 0;
  LBuffer[7] := 255;
  TPixelBatch.AddSaturated(@LBuffer[0], $01020A0A, 8);
  Assert.AreEqual(255, Integer(LBuffer[0]), 'byte 0 saturates');
  Assert.AreEqual(11, Integer(LBuffer[1]), 'byte 1');
  Assert.AreEqual(2, Integer(LBuffer[2]), 'byte 2');
  Assert.AreEqual(255, Integer(LBuffer[3]), 'byte 3');
  Assert.AreEqual(255, Integer(LBuffer[4]), 'byte 4 saturates');
  Assert.AreEqual(11, Integer(LBuffer[5]), 'byte 5');
  Assert.AreEqual(2, Integer(LBuffer[6]), 'byte 6');
  Assert.AreEqual(255, Integer(LBuffer[7]), 'byte 7');
end;

procedure TTestAsmPixelBatch.DovrebbeDimezzareConLaFormulaDiPavgusb;
const
  COUNTS: array[0..16] of Integer = (0, 1, 2, 7, 8, 9, 15, 16, 17, 63, 64, 65, 71, 72, 73, 100, 1000);
var
  LCount: Integer;
  LState: Cardinal;
  LBuffer: TBytes;
  LExpected: TBytes;
  LIndex: Integer;
begin
  LState := $27D4EB2F;
  for LCount in COUNTS do
  begin
    LBuffer := RandomBuffer(LCount, LState);
    LExpected := Copy(LBuffer);
    // the instruction gives (b + 0 + 1) shr 1 on the blocks of 8 bytes; the tail is b shr 1
    for LIndex := 0 to LCount - 1 do
      if LIndex < (LCount and not 7) then
        LExpected[LIndex] := Byte((Integer(LBuffer[LIndex]) + 1) shr 1)
      else
        LExpected[LIndex] := Byte(LBuffer[LIndex] shr 1);
    if LCount > 0 then
      TPixelBatch.HalveBytes(@LBuffer[0], LCount);
    AssertSameBytes(LExpected, LBuffer, System.SysUtils.Format('HalveBytes count=%d', [LCount]));
  end;
end;

procedure TTestAsmPixelBatch.DovrebbeDimezzareCometDreNowSeCeLIstruzione;
const
  COUNTS: array[0..13] of Integer = (1, 2, 7, 8, 9, 15, 16, 17, 63, 64, 65, 72, 73, 1000);
var
  LCount: Integer;
  LState: Cardinal;
  LExpected: TBytes;
  LActual: TBytes;
begin
  if not FHas3DNow then
  begin
    Assert.Pass('No 3DNow on this processor: the instruction is checked by the formula');
    Exit;
  end;
  LState := $165667B1;
  for LCount in COUNTS do
  begin
    LExpected := RandomBuffer(LCount, LState);
    LActual := Copy(LExpected);
    TPixelBatch.HalveBytes(@LExpected[0], LCount);
    Assert.IsTrue(r_mmx.R_BatchColorShade_AMD(@LActual[0], LCount));
    AssertSameBytes(LExpected, LActual, System.SysUtils.Format('R_BatchColorShade_AMD count=%d', [LCount]));
  end;
end;

end.
