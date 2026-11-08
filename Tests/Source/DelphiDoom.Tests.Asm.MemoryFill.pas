{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the assembler replacements - the memory fills          }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Asm.MemoryFill;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of the memory fills of d_delphi (in the 32 bit build the MMX assembler: memset,
  ///   memsetsi, memseti, ZeroMemory; FillDWord is compared with the copy of the old one) with the
  ///   Pascal ones of TMemoryFill, on every size and every misalignment of the destination.
  ///   The buffers have sentinel bytes before and after, so a write out of the range is seen.
  /// </summary>
  [TestFixture]
  [Category('asm')]
  TTestAsmMemoryFill = class(TObject)
  strict private
    FSavedMmx: Byte;
    FHasMmx: Boolean;
    procedure AssertSameBytes(const AExpected, AActual: TBytes; const AMessage: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRiempireIByteCometMemset;
    [Test]
    procedure DovrebbeRiempireLeParoleCometMemsetsi;
    [Test]
    procedure DovrebbeRiempireIDoppiaParolaCometMemseti;
    [Test]
    procedure DovrebbeScrivereAncheLUltimoValoreDiMemsetiConUnNumeroDispari;
    [Test]
    procedure DovrebbeAzzerareCometZeroMemory;
    [Test]
    procedure DovrebbeRiempireIDoppiaParolaCometFillDWord;
    [Test]
    procedure DovrebbeNonScrivereConUnConteggioNegativo;
  end;

implementation

uses
  d_delphi, DelphiDoom.MathCore.MemoryFill
{$IFDEF CPUX86}
  , DelphiDoom.Tests.Asm.Oracles
{$ENDIF}
  ;

const
  SENTINEL = $A5;
  GUARD_BYTES = 16;

function AsmIsProcessorFeaturePresent(AFeature: Cardinal): LongBool; stdcall;
  external 'kernel32.dll' name 'IsProcessorFeaturePresent';

function MakeBuffer(ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize + 2 * GUARD_BYTES);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := SENTINEL;
end;

{ TTestAsmMemoryFill }

procedure TTestAsmMemoryFill.AssertSameBytes(const AExpected, AActual: TBytes;
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

procedure TTestAsmMemoryFill.Setup;
begin
  FSavedMmx := d_delphi.mmxMachine;
  // PF_MMX_INSTRUCTIONS_AVAILABLE = 3: without MMX the old functions fall back on the RTL
  FHasMmx := AsmIsProcessorFeaturePresent(3);
  if FHasMmx then
    d_delphi.mmxMachine := 1;
end;

procedure TTestAsmMemoryFill.TearDown;
begin
  d_delphi.mmxMachine := FSavedMmx;
end;

procedure TTestAsmMemoryFill.DovrebbeRiempireIByteCometMemset;
const
  SIZES: array[0..19] of Integer =
    (0, 1, 2, 3, 7, 8, 9, 15, 16, 17, 31, 63, 64, 65, 100, 127, 128, 129, 1000, 4099);
  VALUES: array[0..6] of Integer = (0, 1, $7F, $80, $FF, $1AB, -1);
var
  LSize: Integer;
  LValue: Integer;
  LOffset: Integer;
  LExpected: TBytes;
  LActual: TBytes;
begin
  for LSize in SIZES do
    for LValue in VALUES do
      for LOffset := 0 to 15 do
      begin
        LExpected := MakeBuffer(LSize + 16);
        LActual := MakeBuffer(LSize + 16);
        TMemoryFill.FillBytes(@LExpected[GUARD_BYTES + LOffset], LValue, LSize);
        d_delphi.memset(@LActual[GUARD_BYTES + LOffset], LValue, LSize);
        AssertSameBytes(LExpected, LActual,
          System.SysUtils.Format('memset size=%d value=%d offset=%d', [LSize, LValue, LOffset]));
      end;
end;

procedure TTestAsmMemoryFill.DovrebbeRiempireLeParoleCometMemsetsi;
const
  COUNTS: array[0..16] of Integer = (0, 1, 2, 3, 4, 5, 7, 8, 9, 31, 32, 33, 64, 65, 100, 1000, 2049);
  VALUES: array[0..5] of SmallInt = (0, 1, 127, 255, -1, -32768);
var
  LCount: Integer;
  LValue: SmallInt;
  LOffset: Integer;
  LExpected: TBytes;
  LActual: TBytes;
begin
  for LCount in COUNTS do
    for LValue in VALUES do
      for LOffset := 0 to 15 do
      begin
        LExpected := MakeBuffer(LCount * 2 + 16);
        LActual := MakeBuffer(LCount * 2 + 16);
        TMemoryFill.FillWords(@LExpected[GUARD_BYTES + LOffset], LValue, LCount);
        d_delphi.memsetsi(@LActual[GUARD_BYTES + LOffset], LValue, LCount);
        AssertSameBytes(LExpected, LActual,
          System.SysUtils.Format('memsetsi count=%d value=%d offset=%d', [LCount, LValue, LOffset]));
      end;
end;

procedure TTestAsmMemoryFill.DovrebbeRiempireIDoppiaParolaCometMemseti;
const
  COUNTS: array[0..16] of Integer = (0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 33, 100, 1001, 4096);
  VALUES: array[0..4] of Integer = (0, 1, -1, $12345678, MaxInt);
var
  LCount: Integer;
  LValue: Integer;
  LOffset: Integer;
  LExpected: TBytes;
  LActual: TBytes;
begin
  for LCount in COUNTS do
    for LValue in VALUES do
      for LOffset := 0 to 15 do
      begin
        LExpected := MakeBuffer(LCount * 4 + 16);
        LActual := MakeBuffer(LCount * 4 + 16);
        TMemoryFill.FillDWords(@LExpected[GUARD_BYTES + LOffset], LCount, Cardinal(LValue));
        d_delphi.memseti(@LActual[GUARD_BYTES + LOffset], LValue, LCount);
        AssertSameBytes(LExpected, LActual,
          System.SysUtils.Format('memseti count=%d value=%d offset=%d', [LCount, LValue, LOffset]));
      end;
end;

procedure TTestAsmMemoryFill.DovrebbeScrivereAncheLUltimoValoreDiMemsetiConUnNumeroDispari;
var
  LBuffer: TBytes;
  LIndex: Integer;
begin
  // regression: with MMX and a destination aligned to 8 bytes the old memseti stopped one value
  // before the end when the count was odd (while count > 4 instead of >= 4); with one value it
  // wrote nothing. The first byte of the dynamic array data is not 8 aligned, so move the start.
  for LIndex := 0 to 7 do
  begin
    LBuffer := MakeBuffer(64);
    d_delphi.memseti(@LBuffer[GUARD_BYTES + LIndex], $11223344, 1);
    Assert.AreEqual($44, Integer(LBuffer[GUARD_BYTES + LIndex]), 'memseti with count 1, byte 0');
    Assert.AreEqual($11, Integer(LBuffer[GUARD_BYTES + LIndex + 3]), 'memseti with count 1, byte 3');
    Assert.AreEqual(SENTINEL, Integer(LBuffer[GUARD_BYTES + LIndex + 4]),
      'memseti with count 1, after');
  end;
end;

procedure TTestAsmMemoryFill.DovrebbeAzzerareCometZeroMemory;
const
  SIZES: array[0..15] of Integer = (0, 1, 2, 7, 8, 9, 15, 16, 17, 63, 64, 65, 127, 128, 129, 4099);
var
  LSize: Integer;
  LOffset: Integer;
  LExpected: TBytes;
  LActual: TBytes;
begin
  for LSize in SIZES do
    for LOffset := 0 to 15 do
    begin
      LExpected := MakeBuffer(LSize + 16);
      LActual := MakeBuffer(LSize + 16);
      TMemoryFill.FillBytes(@LExpected[GUARD_BYTES + LOffset], 0, LSize);
      d_delphi.ZeroMemory(@LActual[GUARD_BYTES + LOffset], LSize);
      AssertSameBytes(LExpected, LActual,
        System.SysUtils.Format('ZeroMemory size=%d offset=%d', [LSize, LOffset]));
    end;
end;

procedure TTestAsmMemoryFill.DovrebbeRiempireIDoppiaParolaCometFillDWord;
const
  COUNTS: array[0..12] of Integer = (0, 1, 2, 3, 7, 8, 9, 31, 64, 65, 100, 1001, 4096);
  VALUES: array[0..3] of Cardinal = (0, 1, $FFFFFFFF, $DEADBEEF);
var
  LCount: Integer;
  LValue: Cardinal;
  LOffset: Integer;
  LExpected: TBytes;
  LActual: TBytes;
  LPascal: TBytes;
begin
  for LCount in COUNTS do
    for LValue in VALUES do
      for LOffset := 0 to 3 do
      begin
        LExpected := MakeBuffer(LCount * 4 + 16);
        LPascal := MakeBuffer(LCount * 4 + 16);
        LActual := MakeBuffer(LCount * 4 + 16);
        {$IFDEF CPUX86}
        OldFillDWord(@LExpected[GUARD_BYTES + LOffset], LCount, LValue);
        {$ELSE}
        TMemoryFill.FillDWords(@LExpected[GUARD_BYTES + LOffset], LCount, LValue);
        {$ENDIF}
        TMemoryFill.FillDWords(@LPascal[GUARD_BYTES + LOffset], LCount, LValue);
        d_delphi.FillDWord(@LActual[GUARD_BYTES + LOffset], LCount, LValue);
        AssertSameBytes(LExpected, LPascal,
          System.SysUtils.Format('TMemoryFill.FillDWords count=%d offset=%d', [LCount, LOffset]));
        AssertSameBytes(LExpected, LActual,
          System.SysUtils.Format('FillDWord count=%d offset=%d', [LCount, LOffset]));
      end;
end;

procedure TTestAsmMemoryFill.DovrebbeNonScrivereConUnConteggioNegativo;
var
  LBuffer: TBytes;
  LReference: TBytes;
begin
  // the old FillDWord with a negative count (rep stosd) would fill the memory up to the end of the
  // address space: the Pascal fills do nothing
  LBuffer := MakeBuffer(32);
  LReference := MakeBuffer(32);
  TMemoryFill.FillDWords(@LBuffer[GUARD_BYTES], -5, $FFFFFFFF);
  TMemoryFill.FillWords(@LBuffer[GUARD_BYTES], -1, -5);
  TMemoryFill.FillBytes(@LBuffer[GUARD_BYTES], $FF, -5);
  TMemoryFill.FillBytes(@LBuffer[GUARD_BYTES], $FF, 0);
  AssertSameBytes(LReference, LBuffer, 'negative or zero count');
end;

end.
