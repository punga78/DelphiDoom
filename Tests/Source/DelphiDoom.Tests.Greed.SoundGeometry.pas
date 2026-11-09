{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSoundGeometry - parity with modplay.pas of xGreed }
{                                                                              }
{  The oracle is UpdateChannelParams and the test of SoundEffect as they were   }
{  (with the FIXEDMUL/FIXEDDIV of the original, in asm at 32 bit)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SoundGeometry;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.SoundGeometry;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSoundGeometry = class(TObject)
  public
    [Test]
    procedure DovrebbeEscludereLeSorgentiTroppoLontane;
    [Test]
    procedure DovrebbeDareIlPanDaSinistraADestra;
    [Test]
    procedure DovrebbeAbbassareIlVolumeConLaDistanza;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.TrigTables, DelphiDoom.Greed.FixedMath;

const
  FRACUNIT = 65536;
  FRACTILEUNIT = 1 shl 22;
  MAXSOUNDDIST = 384;
  MSD = MAXSOUNDDIST * FRACUNIT;

function OldFixedMul(const a, b: Integer): Integer;
begin
  Result := TGreedFixedMath.Mul(a, b);
end;

// the original FIXEDDIV: the double check of the saturation is in TGreedFixedMath.Divide, copied from it
function OldFixedDiv(const a, b: Integer): Integer;
begin
  Result := TGreedFixedMath.Divide(a, b);
end;

var
  GOldSin, GOldCos: array[0..1023] of Integer;

procedure InitOldTables;
const
  g_PI = 3.14159265;
var
  i: Integer;
  angle: double;
begin
  for i := 0 to 1023 do
  begin
    angle := (i * g_PI * 2) / 1024;
    GOldSin[i] := trunc(sin(angle) * FRACUNIT + 0.5);
    GOldCos[i] := trunc(cos(angle) * FRACUNIT + 0.5);
  end;
end;

// UpdateChannelParams of modplay.pas, with the player and the channel as parameters
procedure OldParams(const px, py, pangle, cx, cy, sfxvol: Integer; out pan: Single; out vol: Single);
var
  d, asin, acos: integer;
  dx, dy: integer;
begin
  acos := GOldCos[pangle];
  asin := GOldSin[pangle];
  dx := cx - px;
  dy := cy - py;
  d := OldFixedMul(dx, acos) + OldFixedMul(dy, asin);
  d := OldFixedDiv(d, MSD) * $40;
  d := d div FRACUNIT;
  if d < -64 then
    d := -64
  else if d > 64 then
    d := 64;
  pan := d / 64;
  dx := dx div FRACTILEUNIT;
  dy := dy div FRACTILEUNIT;
  d := dx * dx + dy * dy;
  if d > MAXSOUNDDIST then
    d := MAXSOUNDDIST;
  vol := (MAXSOUNDDIST - d) / MAXSOUNDDIST * sfxvol / 255;
end;

{ TTestGreedSoundGeometry }

procedure TTestGreedSoundGeometry.DovrebbeEscludereLeSorgentiTroppoLontane;
begin
  Assert.IsTrue(TGreedSoundGeometry.IsInRange(0, 0));
  Assert.IsTrue(TGreedSoundGeometry.IsInRange(19 * GREED_FRACTILEUNIT, 0));
  // 20 * 20 = 400 >= 384
  Assert.IsFalse(TGreedSoundGeometry.IsInRange(20 * GREED_FRACTILEUNIT, 0));
  Assert.IsFalse(TGreedSoundGeometry.IsInRange(-14 * GREED_FRACTILEUNIT, 14 * GREED_FRACTILEUNIT));
end;

procedure TTestGreedSoundGeometry.DovrebbeDareIlPanDaSinistraADestra;
begin
  // the original projects the distance on the cosine and sine of the angle: at angle 0 only the x distance counts
  Assert.AreEqual(0, TGreedSoundGeometry.PanUnits(0, 0, 0));
  Assert.AreEqual(0, TGreedSoundGeometry.PanUnits(0, 5 * GREED_FRACTILEUNIT, 0));
  Assert.IsTrue(TGreedSoundGeometry.PanUnits(2 * GREED_FRACTILEUNIT, 0, 0) > 0);
  Assert.IsTrue(TGreedSoundGeometry.PanUnits(-2 * GREED_FRACTILEUNIT, 0, 0) < 0);
  Assert.AreEqual(64, TGreedSoundGeometry.PanUnits(400 * GREED_FRACTILEUNIT, 0, 0));
  Assert.AreEqual(-64, TGreedSoundGeometry.PanUnits(-400 * GREED_FRACTILEUNIT, 0, 0));
end;

procedure TTestGreedSoundGeometry.DovrebbeAbbassareIlVolumeConLaDistanza;
begin
  Assert.AreEqual(Single(1.0), TGreedSoundGeometry.Volume(0, 0, 255));
  Assert.AreEqual(Single(0.0), TGreedSoundGeometry.Volume(100 * GREED_FRACTILEUNIT, 0, 255));
  Assert.IsTrue(TGreedSoundGeometry.Volume(5 * GREED_FRACTILEUNIT, 0, 255) <
    TGreedSoundGeometry.Volume(2 * GREED_FRACTILEUNIT, 0, 255));
  Assert.AreEqual(Single(0.0), TGreedSoundGeometry.Volume(0, 0, 0));
end;

procedure TTestGreedSoundGeometry.DovrebbeDareGliStessiValoriDelCodiceOriginale;
var
  LSeed: Cardinal;
  LIndex: Integer;
  LPx, LPy, LAngle, LCx, LCy, LVolume: Integer;
  LOldPan, LOldVol: Single;
  LRange: Integer;
begin
  InitOldTables;
  LSeed := 12345;
  for LIndex := 1 to 100000 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    LPx := Integer(LSeed shr 4) mod (64 * FRACTILEUNIT div 64) + 0;
    LSeed := LSeed * 1664525 + 1013904223;
    LPy := Integer(LSeed shr 4) mod (64 * FRACTILEUNIT div 64);
    LSeed := LSeed * 1664525 + 1013904223;
    LAngle := (LSeed shr 8) and 1023;
    LRange := 40 * FRACTILEUNIT;
    LSeed := LSeed * 1664525 + 1013904223;
    LCx := LPx + Integer(LSeed shr 3) mod (2 * LRange) - LRange;
    LSeed := LSeed * 1664525 + 1013904223;
    LCy := LPy + Integer(LSeed shr 3) mod (2 * LRange) - LRange;
    LSeed := LSeed * 1664525 + 1013904223;
    LVolume := (LSeed shr 8) and 255;
    OldParams(LPx, LPy, LAngle, LCx, LCy, LVolume, LOldPan, LOldVol);
    Assert.AreEqual(LOldPan, TGreedSoundGeometry.Pan(LCx - LPx, LCy - LPy, LAngle), 'pan ' + IntToStr(LIndex));
    Assert.AreEqual(LOldVol, TGreedSoundGeometry.Volume(LCx - LPx, LCy - LPy, LVolume), 'vol ' + IntToStr(LIndex));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSoundGeometry);

end.
