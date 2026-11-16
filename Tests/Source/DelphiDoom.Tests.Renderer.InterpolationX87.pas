{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the floating point of the       }
{  interpolation of the frames                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.InterpolationX87;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   The expressions of r_intrpl.pas (issue #40). The integer forms, prev + Round((next - prev) * f) with f a
  ///   Single of 17 bits, are compared on each platform with the exact integer arithmetic (the 32 bit FPU and the
  ///   64 bit SSE both give it). The forms with a Single stored between two operations are computed by
  ///   TRendererInterpolationX87: at 32 bit they are compared with the legacy expression computed by the FPU,
  ///   the fingerprint is a constant and at 64 bit it must be the same
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererInterpolationX87 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlResultatoEsattoNelleFormeIntere;
    [Test]
    procedure DovrebbeDareLeMetaEsatteComeLaFpu;
    [Test]
    procedure DovrebbeInterpolareUnAngoloAttraversoLoZero;
    [Test]
    procedure DovrebbeInterpolareUnSingle;
  end;

implementation

uses
  DelphiDoom.Renderer.InterpolationX87, DelphiDoom.Tests.MathCore.Fingerprint;

const
  ANGLE_MAX = $FFFFFFFF;
  FRACUNIT = 65536;

type
  TRandomSource = record
    State: Cardinal;
    function Next: Cardinal;
  end;

function TRandomSource.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State xor (State shr 13);
end;

// Round(ADifference * ATicFraction / 65536), the halves to the even integer
function ExactRound(ADifference: Int64; ATicFraction: Integer): Int64;
var
  LProduct, LQuotient, LRest: Int64;
begin
  LProduct := ADifference * ATicFraction;
  LQuotient := LProduct div FRACUNIT;
  LRest := LProduct - LQuotient * FRACUNIT;
  if LRest < 0 then
  begin
    Dec(LQuotient);
    Inc(LRest, FRACUNIT);
  end;
  if (LRest > FRACUNIT div 2) or ((LRest = FRACUNIT div 2) and Odd(LQuotient)) then
    Inc(LQuotient);
  Result := LQuotient;
end;

function NativeInteger(APrevious, ANext: Integer; const AFraction: Single): Integer;
begin
  Result := APrevious + Round((ANext - APrevious) * AFraction);
end;

function RandomValue(var ARandom: TRandomSource; AIndex: Integer): Integer;
begin
  case AIndex mod 4 of
    0: Result := Integer(ARandom.Next);
    1: Result := Integer(ARandom.Next) div 256;
    2: Result := Integer(ARandom.Next) div 65536 * FRACUNIT;
  else
    Result := Integer(ARandom.Next) div 4096;
  end;
end;

{ TTestRendererInterpolationX87 }

procedure TTestRendererInterpolationX87.DovrebbeDareIlResultatoEsattoNelleFormeIntere;
const
  COUNT = 400000;
var
  LRandom: TRandomSource;
  LIndex: Integer;
  LPrevious, LNext, LTicFraction: Integer;
  LFraction: Single;
  LExpected: Int64;
begin
  LRandom.State := 4711;
  for LIndex := 0 to COUNT - 1 do
  begin
    LPrevious := RandomValue(LRandom, LIndex);
    LNext := RandomValue(LRandom, LIndex + 1);
    LTicFraction := Integer(LRandom.Next) and $FFFF;
    LFraction := LTicFraction / FRACUNIT;
    LExpected := Int64(LPrevious) + ExactRound(Int64(Integer(LNext - LPrevious)), LTicFraction);
    Assert.AreEqual(Integer(LExpected), NativeInteger(LPrevious, LNext, LFraction),
      Format('%d %d %d', [LPrevious, LNext, LTicFraction]));
  end;
end;

procedure TTestRendererInterpolationX87.DovrebbeDareLeMetaEsatteComeLaFpu;
var
  LDifference, LTicFraction: Integer;
  LFraction: Single;
begin
  // the products that end in an exact half: the even integer wins on both
  for LDifference := -300 to 300 do
    for LTicFraction in [1 shl 15, 1 shl 14, 3 shl 14, 1 shl 13, 5 shl 13, 65535, 1] do
    begin
      LFraction := LTicFraction / FRACUNIT;
      Assert.AreEqual(Integer(ExactRound(LDifference, LTicFraction)), NativeInteger(0, LDifference, LFraction),
        Format('%d %d', [LDifference, LTicFraction]));
    end;
end;

{$IF SizeOf(Extended) > SizeOf(Double)}
function NativeAngle(APrevious, ANext: Cardinal; const AFraction: Single): Int64;
var
  LPrevious, LNext, LMiddle: Single;
begin
  LPrevious := APrevious / ANGLE_MAX;
  LNext := ANext / ANGLE_MAX;
  if APrevious > ANext then
    LNext := LNext + 1.0
  else
    LPrevious := LPrevious + 1.0;
  LMiddle := LPrevious + (LNext - LPrevious) * AFraction;
  if LMiddle > 1.0 then
    LMiddle := LMiddle - 1.0;
  Result := Round(LMiddle * ANGLE_MAX);
end;

function NativeSingle(const APrevious, ANext, AFraction: Single): Single;
begin
  Result := APrevious + (ANext - APrevious) * AFraction;
end;
{$IFEND}

procedure TTestRendererInterpolationX87.DovrebbeInterpolareUnAngoloAttraversoLoZero;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LPrevious, LNext: Cardinal;
  LFraction: Single;
  LResult: Int64;
begin
  LRandom.State := 99;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      // prev < ANG90 and next > ANG270, or the other way round
      LPrevious := LRandom.Next shr 2;
      LNext := $C0000000 + (LRandom.Next shr 2);
      if Odd(LIndex) then
      begin
        LResult := LPrevious;
        LPrevious := LNext;
        LNext := Cardinal(LResult);
      end;
      LFraction := (LRandom.Next and $FFFF) / FRACUNIT;
      LResult := TRendererInterpolationX87.AngleAcrossZero(LPrevious, LNext, LFraction);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(NativeAngle(LPrevious, LNext, LFraction), LResult,
        Format('%u %u %g', [LPrevious, LNext, LFraction]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
    end;
    Assert.AreEqual('8F1DBBB8B80BA113/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererInterpolationX87.DovrebbeInterpolareUnSingle;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LPrevious, LNext, LFraction, LResult: Single;
begin
  LRandom.State := 5;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      LPrevious := (Integer(LRandom.Next) div 1024) / 64.0;
      LNext := (Integer(LRandom.Next) div 1024) / 64.0;
      if LIndex mod 3 = 0 then
        LNext := LPrevious + (LRandom.Next and 255) / 3.0;
      LFraction := (LRandom.Next and $FFFF) / FRACUNIT;
      LResult := TRendererInterpolationX87.InterpolateSingle(LPrevious, LNext, LFraction);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.IsTrue(NativeSingle(LPrevious, LNext, LFraction) = LResult,
        Format('%g %g %g', [LPrevious, LNext, LFraction]));
      {$IFEND}
      LFingerprint.AddSingle(LResult);
    end;
    Assert.AreEqual('F79EDADF773901FA/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
