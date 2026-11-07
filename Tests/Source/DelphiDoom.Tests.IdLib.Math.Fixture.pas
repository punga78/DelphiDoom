{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib math - TIdMath, TIdRandom and the vectors    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Math.Fixture;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of TIdMath, TIdRandom, TIdRandom2, TIdVec2, TIdVec3 and TIdVec4 with the C++ idLib
  ///   (math.golden.txt: float bit patterns of the original on 127 inputs; the C++ harness is
  ///   compiled by bcc32c with the x87, like Delphi, so the results are compared bit for bit
  ///   except where the test says otherwise) and checks of known values
  /// </summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibMath = class(TObject)
  public
    [Test]
    procedure TIdMathDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdRandomDovrebbeDareLaStessaSequenzaDelCpp;
    [Test]
    procedure TIdVec3DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdVec2DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdVec4DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure DovrebbeCalcolareIValoriNoti;
    [Test]
    procedure IRecordDeiVettoriDovrebbeAvereLaDimensioneDelCpp;
    [Test]
    procedure SarDovrebbeSpostareADestraCopiandoIlSegno;
    [Test]
    procedure DovrebbeLeggereEScrivereIBitDiUnFloat;
    [Test]
    procedure LeFunzioniA64BitDovrebberoAvereLaPrecisioneDelDouble;
    [Test]
    procedure LeFunzioniInverseA64BitDovrebberoLimitareGliArgomentiFuoriIntervallo;
    [Test]
    procedure FtolDovrebbeConvertireInInteroSenzaSegno;
    [Test]
    procedure DovrebbeLimitareGliInteriEIFloatCompatti;
    [Test]
    procedure IGeneratoriDovrebberoRipartireDalSemeImpostato;
    [Test]
    procedure TIdVec2DovrebbeImpostareConfrontareEInterpolareAgliEstremi;
    [Test]
    procedure TIdVec3DovrebbeRaddrizzareLeNormaliNegativeSugliAssi;
    [Test]
    procedure TIdVec3DovrebbeDareICasiLimiteDiPolariProiezioniEInterpolazioni;
    [Test]
    procedure TIdVec4DovrebbeImpostareConfrontareEDividere;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Math, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Math.Random, DelphiDoom.Tests.IdLib.Golden,
  DelphiDoom.Tests.IdLib.Math.Cases;

const
  // tolerance, in ULPs of a float, for the results of the transcendental functions (see Libs\IdLib\README.md):
  // the Dinkumware library of the C++ harness and the x87 of Delphi do not round them the same way
  ULPS_LIBM = 16;
  ABS_LIBM = 0.00001;
  LOOSE_SCALARS: array[0..11] of string = ('Sin', 'Cos', 'SinCoss', 'SinCosc', 'Tan', 'ASin', 'ACos', 'ATan', 'ATanxy',
    'Exp', 'Log', 'Pow');
  LOOSE_VEC3: array[0..12] of string = ('yaw', 'pitch', 'ang_p', 'ang_y', 'pol_t', 'pol_p', 'sp_yaw', 'sp_pitch',
    'sp_ang_p', 'sp_ang_y', 'slerp3', 'slerp9', 'sphere');

type
  TCaseProc = procedure(const AValues: TArray<Single>; const ALines: TStrings);

procedure CheckSection(const ASection: string; const AProc: TCaseProc; const AMaxUlps: Integer;
  const ALooseNames: array of string);
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
  LValues: TArray<Single>;
  LMask: TArithmeticExceptionMask;
begin
  // the C++ harness runs with the FPU exceptions masked (a division by zero gives infinity)
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  LGolden := TIdLibGolden.Create('math.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.SelectSection(ASection);
    TIdLibMathCases.LoadInput(TIdLibGolden.DataPath('math.input.txt'), LValues);
    try
      AProc(LValues, LActual);
    finally
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.' + ASection + '.actual.txt'));
    end;
    if Length(ALooseNames) = 0 then
      LGolden.Compare(LActual)
    else
      LGolden.Compare(LActual, AMaxUlps, ALooseNames, ABS_LIBM);
  finally
    LActual.Free;
    LGolden.Free;
    SetExceptionMask(LMask);
  end;
end;

procedure TTestIdLibMath.TIdMathDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('scalars', TIdLibMathCases.Scalars, ULPS_LIBM, LOOSE_SCALARS);
end;

procedure TTestIdLibMath.TIdRandomDovrebbeDareLaStessaSequenzaDelCpp;
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('math.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.SelectSection('random');
    TIdLibMathCases.Randoms(LActual);
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestIdLibMath.TIdVec3DovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('vec3', TIdLibMathCases.Vec3s, ULPS_LIBM, LOOSE_VEC3);
end;

procedure TTestIdLibMath.TIdVec2DovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('vec2', TIdLibMathCases.Vec2s, 0, []);
end;

procedure TTestIdLibMath.TIdVec4DovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('vec4', TIdLibMathCases.Vec4s, 0, []);
end;

procedure TTestIdLibMath.DovrebbeCalcolareIValoriNoti;
var
  LA, LB: TIdVec3;
begin
  Assert.AreEqual(4, TIdMath.CeilPowerOfTwo(3));
  Assert.AreEqual(8, TIdMath.CeilPowerOfTwo(8));
  Assert.AreEqual(4, TIdMath.FloorPowerOfTwo(7));
  Assert.AreEqual(3, TIdMath.BitCount(7));
  Assert.AreEqual(Integer($80000000), TIdMath.BitReverse(1));
  Assert.AreEqual(180.0, TIdMath.AngleNormalize360(-180.0), 0.0);
  Assert.AreEqual(-90.0, TIdMath.AngleNormalize180(270.0), 0.0);
  Assert.AreEqual(2.0, TIdMath.Sqrt(4.0), 0.00001);
  LA := TIdVec3.Create(1, 0, 0);
  LB := TIdVec3.Create(0, 1, 0);
  Assert.IsTrue(LA.Cross(LB) = TIdVec3.Create(0, 0, 1));
  Assert.AreEqual(0.0, LA * LB, 0.0);
  Assert.AreEqual(5.0, TIdVec3.Create(3, 4, 0).Length, 0.0001);
end;

procedure TTestIdLibMath.IRecordDeiVettoriDovrebbeAvereLaDimensioneDelCpp;
begin
  Assert.AreEqual(8, SizeOf(TIdVec2));
  Assert.AreEqual(12, SizeOf(TIdVec3));
  Assert.AreEqual(16, SizeOf(TIdVec4));
end;

// The expected values of the tests below come from the C++ source of idLib (Math.h, Random.h,
// Vector.h: the branches and the constants are read there) or from mathematics, never from a run
// of the Delphi code

procedure TTestIdLibMath.SarDovrebbeSpostareADestraCopiandoIlSegno;
begin
  // the >> of C on a signed int
  Assert.AreEqual(2, TIdMath.Sar(8, 2));
  Assert.AreEqual(-4, TIdMath.Sar(-8, 1));
  Assert.AreEqual(-1, TIdMath.Sar(-1, 31));
  Assert.AreEqual(-1, TIdMath.Sar(Integer($80000000), 31));
  Assert.AreEqual(-3, TIdMath.Sar(-5, 1), 'the shift rounds toward minus infinity');
end;

procedure TTestIdLibMath.DovrebbeLeggereEScrivereIBitDiUnFloat;
begin
  Assert.AreEqual(Integer($3F800000), TIdMath.SingleToBits(1.0));
  Assert.AreEqual(Integer($C0000000), TIdMath.SingleToBits(-2.0));
  Assert.AreEqual(Integer($40490FDB), TIdMath.SingleToBits(ID_PI));
  Assert.AreEqual(Single(0.5), TIdMath.BitsToSingle($3F000000), 0.0);
  Assert.AreEqual(Single(-1.5), TIdMath.BitsToSingle(Integer($BFC00000)), 0.0);
end;

procedure TTestIdLibMath.LeFunzioniA64BitDovrebberoAvereLaPrecisioneDelDouble;
const
  // the inputs are exact Singles: the results are those of the mathematical functions, to a few
  // ULPs of a double (a float result would differ in the eighth digit)
  TOLERANCE = 1E-15;
var
  LSin, LCos: Double;
begin
  Assert.AreEqual(0.8414709848078965, TIdMath.Sin64(1.0), TOLERANCE);
  Assert.AreEqual(0.5403023058681398, TIdMath.Cos64(1.0), TOLERANCE);
  TIdMath.SinCos64(0.5, LSin, LCos);
  Assert.AreEqual(0.479425538604203, LSin, TOLERANCE);
  Assert.AreEqual(0.8775825618903728, LCos, TOLERANCE);
  Assert.AreEqual(0.5463024898437905, TIdMath.Tan64(0.5), TOLERANCE);
  Assert.AreEqual(Pi / 6, TIdMath.ASin64(0.5), TOLERANCE);
  Assert.AreEqual(Pi / 3, TIdMath.ACos64(0.5), TOLERANCE);
  Assert.AreEqual(Pi / 4, TIdMath.ATan64(1.0), TOLERANCE);
  Assert.AreEqual(3 * Pi / 4, TIdMath.ATan64(1.0, -1.0), TOLERANCE);
  Assert.AreEqual(1024.0, TIdMath.Pow64(2.0, 10.0), 1E-12);
  Assert.AreEqual(2.718281828459045, TIdMath.Exp64(1.0), 4 * TOLERANCE);
  Assert.AreEqual(2.0794415416798357, TIdMath.Log64(8.0), 4 * TOLERANCE);
  Assert.AreEqual(0.0, TIdMath.Log64(1.0), 0.0);
end;

procedure TTestIdLibMath.LeFunzioniInverseA64BitDovrebberoLimitareGliArgomentiFuoriIntervallo;
begin
  // idMath::ASin64 and ACos64 return the float constants outside [-1, 1]
  Assert.AreEqual(Double(ID_HALF_PI), TIdMath.ASin64(2.0), 0.0);
  Assert.AreEqual(Double(-ID_HALF_PI), TIdMath.ASin64(-1.0), 0.0);
  Assert.AreEqual(Double(ID_PI), TIdMath.ACos64(-3.0), 0.0);
  Assert.AreEqual(0.0, TIdMath.ACos64(1.0), 0.0);
end;

procedure TTestIdLibMath.FtolDovrebbeConvertireInInteroSenzaSegno;
var
  LMask: TArithmeticExceptionMask;
  LNaN: Single;
begin
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    LNaN := TIdMath.BitsToSingle($7FC00000);
    Assert.AreEqual(Cardinal(3), TIdMath.Ftol(3.75));
    // 3e9 is an exact float above 2^31: an unsigned long holds it
    Assert.AreEqual(Cardinal(3000000000), TIdMath.Ftol(3E9));
    Assert.AreEqual(Cardinal($FFFFFFFF), TIdMath.Ftol(-1.0), 'two''s complement of -1');
    // the values that do not fit, as the 32-bit clang of the goldens converts them (see the unit)
    Assert.AreEqual(Cardinal($80000000), TIdMath.Ftol(LNaN));
    Assert.AreEqual(Cardinal($80000000), TIdMath.Ftol(-3E9));
    Assert.AreEqual(Cardinal(0), TIdMath.Ftol(5E9));
    // FtolFast rounds to the nearest, ties to even, as the FPU in its default mode
    Assert.AreEqual(Cardinal(2), TIdMath.FtolFast(2.5));
    Assert.AreEqual(Cardinal(4), TIdMath.FtolFast(3.5));
    // the integer indefinite of the FPU for the values that do not fit in an int
    Assert.AreEqual(Integer($80000000), TIdMath.Ftoi(LNaN));
    Assert.AreEqual(Integer($80000000), TIdMath.FtoiFast(3E9));
  finally
    SetExceptionMask(LMask);
  end;
end;

procedure TTestIdLibMath.DovrebbeLimitareGliInteriEIFloatCompatti;
begin
  Assert.AreEqual(SmallInt(-32768), TIdMath.ClampShort(-40000));
  Assert.AreEqual(SmallInt(32767), TIdMath.ClampShort(40000));
  Assert.AreEqual(SmallInt(-5), TIdMath.ClampShort(-5));
  // FloatToBits with 5 bits of exponent and 10 of mantissa: below -max the largest value with the
  // sign bit, maxBits | ( 1 << ( exponentBits + mantissaBits ) )
  Assert.AreEqual(((15 shl 10) or 1023) or (1 shl 15), TIdMath.FloatToBits(-1E30, 5, 10));
  Assert.AreEqual((15 shl 10) or 1023, TIdMath.FloatToBits(1E30, 5, 10));
end;

procedure TTestIdLibMath.IGeneratoriDovrebberoRipartireDalSemeImpostato;
var
  LRandom: TIdRandom;
  LRandom2, LCopy2: TIdRandom2;
begin
  LRandom := TIdRandom.Create(123);
  LRandom.RandomInt;
  LRandom.SetSeed(5);
  Assert.AreEqual(5, LRandom.GetSeed);
  // seed = 69069 * seed + 1, masked with MAX_RAND
  Assert.AreEqual((69069 * 5 + 1) and $7FFF, LRandom.RandomInt);

  LRandom2 := TIdRandom2.Create(1);
  LRandom2.RandomInt;
  LRandom2.SetSeed(7);
  Assert.AreEqual(Cardinal(7), LRandom2.GetSeed);
  LCopy2 := TIdRandom2.Create(7);
  Assert.AreEqual(LCopy2.RandomInt, LRandom2.RandomInt);
  Assert.AreEqual(LCopy2.GetSeed, LRandom2.GetSeed);
end;

procedure TTestIdLibMath.TIdVec2DovrebbeImpostareConfrontareEInterpolareAgliEstremi;
var
  LA, LB, LV: TIdVec2;
begin
  LA := TIdVec2.Create(1, 2);
  LB := TIdVec2.Create(5, 6);
  LV.SetValues(1, 2);
  Assert.IsFalse(LV <> LA);
  Assert.IsTrue(LV <> LB);
  LV.Zero;
  Assert.IsTrue(LV = TIdVec2.Create(0, 0));
  Assert.AreEqual(2, LV.GetDimension);
  LV.Lerp(LA, LB, -0.5);
  Assert.IsTrue(LV = LA, 'l <= 0 gives v1');
  LV.Lerp(LA, LB, 1.0);
  Assert.IsTrue(LV = LB, 'l >= 1 gives v2');
  LV := LB;
  LV.Truncate(0);
  Assert.IsTrue(LV = TIdVec2.Create(0, 0), 'a length of zero clears the vector');
end;

procedure TTestIdLibMath.TIdVec3DovrebbeRaddrizzareLeNormaliNegativeSugliAssi;
var
  LV: TIdVec3;
begin
  LV := TIdVec3.Create(0, -0.5, 0);
  Assert.IsTrue(LV.FixDegenerateNormal);
  Assert.IsTrue(LV = TIdVec3.Create(0, -1, 0));
  LV := TIdVec3.Create(-0.25, 0, 0);
  Assert.IsTrue(LV.FixDegenerateNormal);
  Assert.IsTrue(LV = TIdVec3.Create(-1, 0, 0));
  LV := TIdVec3.Create(-1, 0, 0);
  Assert.IsFalse(LV.FixDegenerateNormal, 'already axial');
  LV := TIdVec3.Create(0.5, 0.25, 0.75);
  Assert.IsFalse(LV.FixDegenerateNormal, 'not axial and no component of length one');
  LV := TIdVec3.Create(0.5, 1, 0.75);
  Assert.IsTrue(LV.FixDegenerateNormal);
  Assert.IsTrue(LV = TIdVec3.Create(0, 1, 0));
end;

procedure TTestIdLibMath.TIdVec3DovrebbeDareICasiLimiteDiPolariProiezioniEInterpolazioni;
var
  LV, LA, LB: TIdVec3;
  LRadius, LTheta, LPhi: Single;
begin
  LV.SetValues(1, 2, 3);
  Assert.IsTrue(LV = TIdVec3.Create(1, 2, 3));
  Assert.IsTrue(LV <> TIdVec3.Create(1, 2, 4));
  Assert.IsFalse(LV <> TIdVec3.Create(1, 2, 3));
  Assert.AreEqual(3, LV.GetDimension);

  // on the z axis the yaw is 0 and the pitch 90 or 270; phi is -pitch
  TIdVec3.Create(0, 0, 2).ToPolar(LRadius, LTheta, LPhi);
  Assert.AreEqual(Single(2.0), LRadius, 0.0);
  Assert.AreEqual(Single(0.0), LTheta, 0.0);
  Assert.AreEqual(Single(-90.0), LPhi, 0.0);
  TIdVec3.Create(0, 0, -3).ToPolar(LRadius, LTheta, LPhi);
  Assert.AreEqual(Single(3.0), LRadius, 0.0);
  Assert.AreEqual(Single(-270.0), LPhi, 0.0);

  // a normal almost parallel to the vector: the projection is not possible
  LV := TIdVec3.Create(1, 0, 0);
  Assert.IsFalse(LV.ProjectAlongPlane(TIdVec3.Create(1, 0.000001, 0), 0.1, 1.0));
  Assert.IsTrue(LV = TIdVec3.Create(1, 0, 0), 'the vector does not change');

  LA := TIdVec3.Create(1, 0, 0);
  LB := TIdVec3.Create(0, 1, 0);
  LV.SLerp(LA, LB, 0.0);
  Assert.IsTrue(LV = LA, 't <= 0 gives v1');
  LV.SLerp(LA, LB, 1.5);
  Assert.IsTrue(LV = LB, 't >= 1 gives v2');
end;

procedure TTestIdLibMath.TIdVec4DovrebbeImpostareConfrontareEDividere;
var
  LA, LB, LV: TIdVec4;
begin
  LA := TIdVec4.Create(1, 2, 3, 4);
  LB := TIdVec4.Create(5, 6, 7, 8);
  LV.SetValues(1, 2, 3, 4);
  Assert.IsFalse(LV <> LA);
  Assert.IsTrue(LV <> LB);
  Assert.IsFalse(LA.Compare(TIdVec4.Create(1, 2.5, 3, 4), 0.1), 'y differs');
  Assert.IsFalse(LA.Compare(TIdVec4.Create(1, 2, 3.5, 4), 0.1), 'z differs');
  Assert.IsTrue(LA.Compare(TIdVec4.Create(1.05, 2, 3, 3.95), 0.1));
  LV := TIdVec4.Create(10, 12, 21, 32);
  LV.DivideComponents(TIdVec4.Create(2, 3, 7, 8));
  Assert.IsTrue(LV = TIdVec4.Create(5, 4, 3, 4));
  LV.Zero;
  Assert.IsTrue(LV = TIdVec4.Create(0, 0, 0, 0));
  Assert.AreEqual(4, LV.GetDimension);
  LV.Lerp(LA, LB, 0.0);
  Assert.IsTrue(LV = LA, 'l <= 0 gives v1');
  LV.Lerp(LA, LB, 3.0);
  Assert.IsTrue(LV = LB, 'l >= 1 gives v2');
end;

end.
