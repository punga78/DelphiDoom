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
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Math, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Tests.IdLib.Golden,
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

end.
