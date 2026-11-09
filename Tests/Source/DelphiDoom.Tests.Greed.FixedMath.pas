{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedFixedMath - parity with the original of xGreed   }
{                                                                              }
{  The oracles are the functions of r_public.pas and g_delphi.pas copied as     }
{  they were (the asm ones only exist at 32 bit, so the comparisons are there) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.FixedMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.FixedMath;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedFixedMath = class(TObject)
  private
    FSeed: Cardinal;
    function NextValue: Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeMoltiplicareComeIlProdottoDiDueInteri;
    [Test]
    procedure DovrebbeSaturareLaSommaESaturareIlProdottoArrotondato;
    [Test]
    procedure DovrebbeDividereESaturareSenzaSollevareConDivisoreZero;
    [Test]
    procedure DovrebbeFareLeMoltiplicazioniAArrotondamentoPariSuInt64;
    [Test]
    procedure DovrebbeFareGliSpostamentiAritmetici;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  System.Math;

const
  Edges: array[0..13] of Integer = (0, 1, -1, 65536, -65536, 32768, -32768, 98304, $7FFFFFFF, Integer($80000000),
    $7FFF0000, Integer($80010000), 12345678, -87654321);

{$IFDEF CPUX86}
// ---- the original code of xGreed (r_public.pas), as it was ----
function OldFixedMul(const a, b: Integer): Integer; assembler;
asm
  imul b
  shrd eax, edx, 16
end;

function OldFixedMul1(const a, b: Integer): Integer;
var
  i64: Int64;
begin
  i64 := Round(a / 65536 * b);
  if i64 > MaxInt then
    Result := MaxInt
  else if i64 < Integer($80000000) then
    Result := Integer($80000000)
  else
    Result := i64;
end;

function OldFixedMul64(const a, b: Int64): Int64;
begin
  Result := Round(a / 65536 * b);
end;

function OldFixedDiv2(const a, b: Integer): Integer; assembler;
asm
  mov ebx, b
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
end;

function OldAbsI(const x: Integer): Integer;
begin
  if x < 0 then
    Result := -x
  else
    Result := x;
end;

function OldFixedDiv(const a, b: Integer): Integer;
begin
  if (OldAbsI(a) shr 14) >= OldAbsI(b) then
  begin
    if a xor b < 0 then
      Result := Integer($80000000)
    else
      Result := MaxInt;
  end
  else
    Result := OldFixedDiv2(a, b);
end;

function OldShl(const x: Integer; const bits: Integer): Integer; assembler;
asm
  mov ecx, edx
  sal eax, cl
end;

function OldShr(const x: Integer; const bits: Integer): Integer; assembler;
asm
  mov ecx, edx
  sar eax, cl
end;
{$ENDIF}

{ TTestGreedFixedMath }

procedure TTestGreedFixedMath.Setup;
begin
  FSeed := $1234ABCD;
end;

function TTestGreedFixedMath.NextValue: Integer;
begin
  // xorshift: deterministic; every third value is small, as the game ones
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  if FSeed mod 3 = 0 then
    Result := Integer(FSeed) div 4096
  else
    Result := Integer(FSeed);
end;

procedure TTestGreedFixedMath.DovrebbeMoltiplicareComeIlProdottoDiDueInteri;
begin
  Assert.AreEqual(3 * 65536, TGreedFixedMath.Mul(6 * 65536, 32768 * 1));
  Assert.AreEqual(-65536 * 2, TGreedFixedMath.Mul(-65536, 2 * 65536));
  Assert.AreEqual(0, TGreedFixedMath.Mul(0, Integer($80000000)));
  // wraps to 32 bits, as shrd did
  Assert.AreEqual(Integer(((Int64($7FFFFFFF) * $7FFFFFFF) shr 16) and $FFFFFFFF), TGreedFixedMath.Mul($7FFFFFFF, $7FFFFFFF));
end;

procedure TTestGreedFixedMath.DovrebbeSaturareLaSommaESaturareIlProdottoArrotondato;
begin
  Assert.AreEqual(MaxInt, TGreedFixedMath.AddSaturated(MaxInt, 1));
  Assert.AreEqual(Integer($80000000), TGreedFixedMath.AddSaturated(Integer($80000000), -1));
  Assert.AreEqual(7, TGreedFixedMath.AddSaturated(3, 4));
  Assert.AreEqual(MaxInt, TGreedFixedMath.MulSaturated($7FFFFFFF, $7FFFFFFF));
  Assert.AreEqual(Integer($80000000), TGreedFixedMath.MulSaturated($7FFFFFFF, Integer($80000000)));
  // halves go to the even one: 0.5 -> 0, 1.5 -> 2, 2.5 -> 2
  Assert.AreEqual(0, TGreedFixedMath.MulSaturated(32768, 1));
  Assert.AreEqual(2, TGreedFixedMath.MulSaturated(32768, 3));
  Assert.AreEqual(2, TGreedFixedMath.MulSaturated(32768, 5));
end;

procedure TTestGreedFixedMath.DovrebbeDividereESaturareSenzaSollevareConDivisoreZero;
begin
  Assert.AreEqual(2 * 65536, TGreedFixedMath.Divide(4 * 65536, 2 * 65536));
  Assert.AreEqual(MaxInt, TGreedFixedMath.Divide(65536, 0));
  Assert.AreEqual(Integer($80000000), TGreedFixedMath.Divide(-65536, 0));
  Assert.AreEqual(MaxInt, TGreedFixedMath.Divide($7FFFFFFF, 1));
  Assert.AreEqual(Integer($80000000), TGreedFixedMath.Divide($7FFFFFFF, -1));
end;

procedure TTestGreedFixedMath.DovrebbeFareLeMoltiplicazioniAArrotondamentoPariSuInt64;
begin
  Assert.AreEqual(Int64(0), TGreedFixedMath.Mul64(0, Int64(1) shl 40));
  Assert.AreEqual(Int64(2), TGreedFixedMath.Mul64(32768, 5));
  Assert.AreEqual(Int64(-2), TGreedFixedMath.Mul64(-32768, 5));
  Assert.AreEqual(Int64(1) shl 40, TGreedFixedMath.Mul64(Int64(1) shl 40, 65536));
end;

procedure TTestGreedFixedMath.DovrebbeFareGliSpostamentiAritmetici;
begin
  Assert.AreEqual(-1, TGreedFixedMath.ShiftRight(-1, 20));
  Assert.AreEqual(1, TGreedFixedMath.ShiftRight(16, 4));
  Assert.AreEqual(256, TGreedFixedMath.ShiftLeft(1, 8));
  // the count is taken modulo 32 as by the processor
  Assert.AreEqual(2, TGreedFixedMath.ShiftLeft(1, 33));
end;

procedure TTestGreedFixedMath.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
{$IFDEF CPUX86}
var
  LIndex, LJ, LA, LB: Integer;
  LA64, LB64: Int64;
begin
  for LIndex := 0 to 200000 do
  begin
    if LIndex < Length(Edges) * Length(Edges) then
    begin
      LA := Edges[LIndex div Length(Edges)];
      LB := Edges[LIndex mod Length(Edges)];
    end
    else
    begin
      LA := NextValue;
      LB := NextValue;
    end;
    Assert.AreEqual(OldFixedMul(LA, LB), TGreedFixedMath.Mul(LA, LB), Format('Mul %d %d', [LA, LB]));
    Assert.AreEqual(OldFixedMul1(LA, LB), TGreedFixedMath.MulSaturated(LA, LB), Format('MulSaturated %d %d', [LA, LB]));
    Assert.AreEqual(OldFixedDiv(LA, LB), TGreedFixedMath.Divide(LA, LB), Format('Divide %d %d', [LA, LB]));
    // products that fit in the 64 bit mantissa of the FPU: the 64 bit values are the 32 bit ones, widened
    LA64 := Int64(LA) * (Int64(NextValue) and $FFFF);
    LB64 := LB;
    Assert.AreEqual(OldFixedMul64(LA64, LB64), TGreedFixedMath.Mul64(LA64, LB64), Format('Mul64 %d %d', [LA64, LB64]));
    LJ := NextValue and 31;
    Assert.AreEqual(OldShl(LA, LJ), TGreedFixedMath.ShiftLeft(LA, LJ), 'ShiftLeft');
    Assert.AreEqual(OldShr(LA, LJ), TGreedFixedMath.ShiftRight(LA, LJ), 'ShiftRight');
  end;
end;
{$ELSE}
begin
  // the originals are asm: nothing to compare at 64 bit
  Assert.Pass('asm originals exist only at 32 bit');
end;
{$ENDIF}

initialization
  TDUnitX.RegisterTestFixture(TTestGreedFixedMath);

end.
