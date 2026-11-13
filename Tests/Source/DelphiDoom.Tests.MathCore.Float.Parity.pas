{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the floating point math of MathCore - parity with the  }
{  C++ idLib (angles, matrices, quaternions, rotations, complex numbers)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Float.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idlib\math of Doom 3 (Tests\Data\MathCore\float.golden.txt: about
  ///   4900 lines written by the C++ classes compiled with bcc32c on the x87, with the inputs on
  ///   each line: "name in... | out..."). Every line is recomputed from its own inputs.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestFloatParity = class(TObject)
  private
    FLines: TStringList;
    FOldMask: TArithmeticExceptionMask;
    procedure Run(const APrefixes: array of string; const AMaxUlps: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TIdAnglesDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeConversioniDaMatriceDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdMat3DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdQuatDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdRotationDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdComplexDovrebbeDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Complex,
  DelphiDoom.MathCore.Float.Conversions, DelphiDoom.MathCore.Float.CQuat,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.MathCore.Float.Rotation, DelphiDoom.Tests.IdLib.Golden;

type
  TFloats = array of Single;

function Bits(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Result := PSingle(@LBits)^;
end;

function ParseInputs(const ALine: string; out AName: string): TFloats;
var
  LParts: TArray<string>;
  LIndex, LCount: Integer;
begin
  LParts := ALine.Split([' ']);
  AName := LParts[0];
  SetLength(Result, 0);
  LCount := 0;
  for LIndex := 1 to High(LParts) do
  begin
    if LParts[LIndex] = '|' then
      Break;
    SetLength(Result, LCount + 1);
    Result[LCount] := Bits(LParts[LIndex]);
    Inc(LCount);
  end;
end;

function HeadOf(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Pos('|', ALine));
end;

procedure Put(var ALine: string; const AValue: Single); overload;
begin
  ALine := ALine + ' ' + TIdLibGolden.FloatToken(AValue);
end;

procedure PutVec(var ALine: string; const AValue: TIdVec3);
begin
  Put(ALine, AValue.X);
  Put(ALine, AValue.Y);
  Put(ALine, AValue.Z);
end;

procedure PutMat(var ALine: string; const AValue: TIdMat3);
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    PutVec(ALine, AValue.Rows[LRow]);
end;

procedure PutQuat(var ALine: string; const AValue: TIdQuat);
begin
  Put(ALine, AValue.X);
  Put(ALine, AValue.Y);
  Put(ALine, AValue.Z);
  Put(ALine, AValue.W);
end;

procedure PutAngles(var ALine: string; const AValue: TIdAngles);
begin
  Put(ALine, AValue.Pitch);
  Put(ALine, AValue.Yaw);
  Put(ALine, AValue.Roll);
end;

procedure PutRotation(var ALine: string; const AValue: TIdRotation);
begin
  PutVec(ALine, AValue.Origin);
  PutVec(ALine, AValue.Vector);
  Put(ALine, AValue.Angle);
end;

procedure PutFlag(var ALine: string; const AValue: Boolean);
begin
  if AValue then
    ALine := ALine + ' 1'
  else
    ALine := ALine + ' 0';
end;

function VecAt(const AFloats: TFloats; const AIndex: Integer): TIdVec3;
begin
  Result := TIdVec3.Create(AFloats[AIndex], AFloats[AIndex + 1], AFloats[AIndex + 2]);
end;

function MatAt(const AFloats: TFloats; const AIndex: Integer): TIdMat3;
begin
  Result := TIdMat3.Create(VecAt(AFloats, AIndex), VecAt(AFloats, AIndex + 3), VecAt(AFloats, AIndex + 6));
end;

function QuatAt(const AFloats: TFloats; const AIndex: Integer): TIdQuat;
begin
  Result := TIdQuat.Create(AFloats[AIndex], AFloats[AIndex + 1], AFloats[AIndex + 2], AFloats[AIndex + 3]);
end;

function AnglesAt(const AFloats: TFloats): TIdAngles;
begin
  Result := TIdAngles.Create(AFloats[0], AFloats[1], AFloats[2]);
end;

function RotationAt(const AFloats: TFloats): TIdRotation;
begin
  Result := TIdRotation.Create(VecAt(AFloats, 0), VecAt(AFloats, 3), AFloats[6]);
end;

function ComputeAngles(const AName: string; const F: TFloats; var ALine: string): Boolean;
var
  LAngles, LCopy: TIdAngles;
  LForward, LRight, LUp: TIdVec3;
begin
  Result := True;
  LAngles := AnglesAt(F);
  if AName = 'A_norm360' then
  begin
    LCopy := LAngles;
    LCopy.Normalize360;
    PutAngles(ALine, LCopy);
  end
  else if AName = 'A_norm180' then
  begin
    LCopy := LAngles;
    LCopy.Normalize180;
    PutAngles(ALine, LCopy);
  end
  else if AName = 'A_vectors' then
  begin
    LAngles.ToVectors(LForward, LRight, LUp);
    PutVec(ALine, LForward);
    PutVec(ALine, LRight);
    PutVec(ALine, LUp);
  end
  else if AName = 'A_forward' then
    PutVec(ALine, LAngles.ToForward)
  else if AName = 'A_mat' then
    PutMat(ALine, TIdRotationConversions.AnglesToMat(LAngles))
  else if AName = 'A_quat' then
    PutQuat(ALine, TIdRotationConversions.AnglesToQuat(LAngles))
  else if AName = 'A_rot' then
    PutRotation(ALine, TIdRotationConversions.AnglesToRotation(LAngles))
  else if AName = 'A_angvel' then
    PutVec(ALine, TIdRotationConversions.AnglesToAngularVelocity(LAngles))
  else if AName = 'R_angles' then
    PutAngles(ALine, TIdRotationConversions.MatToAngles(TIdRotationConversions.AnglesToMat(LAngles)))
  else if AName = 'R_quat' then
    PutQuat(ALine, TIdRotationConversions.MatToQuat(TIdRotationConversions.AnglesToMat(LAngles)))
  else if AName = 'R_cquat' then
  begin
    with TIdRotationConversions.MatToCQuat(TIdRotationConversions.AnglesToMat(LAngles)) do
    begin
      Put(ALine, X);
      Put(ALine, Y);
      Put(ALine, Z);
    end;
  end
  else if AName = 'R_rot' then
    PutRotation(ALine, TIdRotationConversions.MatToRotation(TIdRotationConversions.AnglesToMat(LAngles)))
  else if AName = 'R_angvel' then
    PutVec(ALine, TIdRotationConversions.MatToAngularVelocity(TIdRotationConversions.AnglesToMat(LAngles)))
  else
    Result := False;
end;

function ComputeMat(const AName: string; const F: TFloats; var ALine: string): Boolean;
var
  LMat, LOther, LCopy: TIdMat3;
  LOk: Boolean;
begin
  Result := True;
  LMat := MatAt(F, 0);
  if AName = 'M_det' then
    Put(ALine, LMat.Determinant)
  else if AName = 'M_inv' then
  begin
    LCopy := LMat;
    LOk := LCopy.InverseSelf;
    PutFlag(ALine, LOk);
    PutMat(ALine, LCopy);
  end
  else if AName = 'M_invfast' then
  begin
    LCopy := LMat;
    LOk := LCopy.InverseFastSelf;
    PutFlag(ALine, LOk);
    PutMat(ALine, LCopy);
  end
  else if AName = 'M_transpose' then
    PutMat(ALine, LMat.Transpose)
  else if AName = 'M_ortho' then
    PutMat(ALine, LMat.OrthoNormalize)
  else if AName = 'M_trace' then
    Put(ALine, LMat.Trace)
  else if AName = 'M_sym' then
  begin
    PutFlag(ALine, LMat.IsSymmetric);
    PutFlag(ALine, LMat.IsDiagonal);
    PutFlag(ALine, LMat.IsIdentity);
  end
  else if AName = 'M_fixdeg' then
  begin
    LCopy := LMat;
    LOk := LCopy.FixDegeneracies;
    PutFlag(ALine, LOk);
    PutMat(ALine, LCopy);
  end
  else if AName = 'M_mul' then
    PutMat(ALine, LMat * MatAt(F, 9))
  else if AName = 'M_tmul' then
    PutMat(ALine, LMat.TransposeMultiply(MatAt(F, 9)))
  else if AName = 'M_inertiaR' then
  begin
    LOther := MatAt(F, 9);
    PutMat(ALine, LMat.InertiaRotate(LOther));
  end
  else if AName = 'M_mulvec' then
    PutVec(ALine, LMat * VecAt(F, 9))
  else if AName = 'M_vecmul' then
    PutVec(ALine, VecAt(F, 9) * LMat)
  else if AName = 'M_scale' then
    PutMat(ALine, LMat * F[9])
  else if AName = 'M_inertiaT' then
    PutMat(ALine, LMat.InertiaTranslate(F[9], VecAt(F, 10), VecAt(F, 13)))
  else
    Result := False;
end;

function ComputeQuat(const AName: string; const F: TFloats; var ALine: string): Boolean;
var
  LQuat, LCopy: TIdQuat;
  LCompressed: TIdCQuat;
begin
  Result := True;
  LQuat := QuatAt(F, 0);
  if AName = 'Q_norm' then
  begin
    LCopy := LQuat;
    LCopy.Normalize;
    PutQuat(ALine, LCopy);
  end
  else if AName = 'Q_len' then
    Put(ALine, LQuat.Length)
  else if AName = 'Q_inv' then
    PutQuat(ALine, LQuat.Inverse)
  else if AName = 'Q_calcw' then
    Put(ALine, LQuat.CalcW)
  else if AName = 'Q_cquat' then
  begin
    LCompressed := TIdRotationConversions.QuatToCQuat(LQuat);
    Put(ALine, LCompressed.X);
    Put(ALine, LCompressed.Y);
    Put(ALine, LCompressed.Z);
  end
  else if AName = 'C_quat' then
    PutQuat(ALine, TIdCQuat.Create(F[0], F[1], F[2]).ToQuat)
  else if AName = 'C_mat' then
    PutMat(ALine, TIdRotationConversions.CQuatToMat(TIdCQuat.Create(F[0], F[1], F[2])))
  else if AName = 'Q_angvel' then
    PutVec(ALine, LQuat.ToAngularVelocity)
  else if AName = 'Q_mul' then
    PutQuat(ALine, LQuat * QuatAt(F, 4))
  else if AName = 'Q_mulvec' then
    PutVec(ALine, LQuat * VecAt(F, 4))
  else if AName = 'Q_mat' then
    PutMat(ALine, TIdRotationConversions.QuatToMat(LQuat))
  else if AName = 'Q_angles' then
    PutAngles(ALine, TIdRotationConversions.QuatToAngles(LQuat))
  else if AName = 'Q_rot' then
    PutRotation(ALine, TIdRotationConversions.QuatToRotation(LQuat))
  else if AName = 'Q_slerp' then
  begin
    LCopy.Slerp(LQuat, QuatAt(F, 4), F[8]);
    PutQuat(ALine, LCopy);
  end
  else
    Result := False;
end;

function ComputeRotation(const AName: string; const F: TFloats; var ALine: string): Boolean;
var
  LRotation, LCopy: TIdRotation;
begin
  Result := True;
  LRotation := RotationAt(F);
  if AName = 'Rot_mat' then
    PutMat(ALine, LRotation.ToMat3)
  else if AName = 'Rot_quat' then
    PutQuat(ALine, LRotation.ToQuat)
  else if AName = 'Rot_angles' then
    PutAngles(ALine, TIdRotationConversions.RotationToAngles(LRotation))
  else if AName = 'Rot_angvel' then
    PutVec(ALine, LRotation.ToAngularVelocity)
  else if AName = 'Rot_n180' then
  begin
    LCopy := LRotation;
    LCopy.Normalize180;
    Put(ALine, LCopy.Angle);
  end
  else if AName = 'Rot_n360' then
  begin
    LCopy := LRotation;
    LCopy.Normalize360;
    Put(ALine, LCopy.Angle);
  end
  else if AName = 'Rot_point' then
    PutVec(ALine, LRotation * VecAt(F, 7))
  else if AName = 'Rot_scale' then
  begin
    LCopy := LRotation;
    LCopy.Scale(0.5);
    Put(ALine, LCopy.Angle);
    PutMat(ALine, LCopy.ToMat3);
  end
  else
    Result := False;
end;

function ComputeComplex(const AName: string; const F: TFloats; var ALine: string): Boolean;
var
  LA, LB, LResult: TIdComplex;
begin
  Result := True;
  LA := TIdComplex.Create(F[0], F[1]);
  if Length(F) >= 4 then
    LB := TIdComplex.Create(F[2], F[3]);
  if AName = 'X_mul' then
    LResult := LA * LB
  else if AName = 'X_div' then
    LResult := LA / LB
  else if AName = 'X_add' then
    LResult := LA + LB
  else if AName = 'X_recip' then
    LResult := LA.Reciprocal
  else if AName = 'X_sqrt' then
    LResult := LA.Sqrt
  else if AName = 'X_divf' then
    LResult := LA / F[2]
  else if AName = 'X_fdiv' then
    LResult := F[2] / LA
  else if AName = 'X_abs' then
  begin
    Put(ALine, LA.Abs);
    Exit;
  end
  else
    Exit(False);
  Put(ALine, LResult.R);
  Put(ALine, LResult.I);
end;

// distance in ULPs between two float bit patterns (sign-magnitude to a monotonic integer)
function UlpDistance(const AExpected, AActual: Cardinal): Int64;
  function Monotonic(const ABits: Cardinal): Int64;
  begin
    if (ABits and $80000000) <> 0 then
      Result := -Int64(ABits and $7FFFFFFF)
    else
      Result := Int64(ABits);
  end;
begin
  Result := Abs(Monotonic(AExpected) - Monotonic(AActual));
end;

function IsNaNBits(const ABits: Cardinal): Boolean;
begin
  Result := ((ABits and $7F800000) = $7F800000) and ((ABits and $007FFFFF) <> 0);
end;

procedure CompareLines(const AExpected, AActual: TStrings; const AMaxUlps: Integer);
var
  LLine, LToken: Integer;
  LExpectedTokens, LActualTokens: TArray<string>;
  LExpectedBits, LActualBits: Cardinal;
begin
  Assert.AreEqual(AExpected.Count, AActual.Count, 'numero di righe');
  for LLine := 0 to AExpected.Count - 1 do
  begin
    LExpectedTokens := AExpected[LLine].Split([' ']);
    LActualTokens := AActual[LLine].Split([' ']);
    Assert.AreEqual(Length(LExpectedTokens), Length(LActualTokens), 'numero di token: ' + AExpected[LLine]);
    for LToken := 0 to High(LExpectedTokens) do
    begin
      if (LExpectedTokens[LToken] <> '') and (LExpectedTokens[LToken][1] = '#') then
      begin
        LExpectedBits := Cardinal(StrToInt64('$' + Copy(LExpectedTokens[LToken], 2, 8)));
        LActualBits := Cardinal(StrToInt64('$' + Copy(LActualTokens[LToken], 2, 8)));
        if IsNaNBits(LExpectedBits) and IsNaNBits(LActualBits) then
          Continue;
        // tolerance: AMaxUlps, or a relative error of 4e-6 (about 34 ULP at the worst) of the
        // answer or of 1: the C++ is compiled by clang (each float operation rounded), Delphi keeps
        // a whole expression in the x87 registers, so sums with cancellation differ in the last bits
        if (UlpDistance(LExpectedBits, LActualBits) > AMaxUlps) and
          (Abs(Bits(LActualTokens[LToken]) - Bits(LExpectedTokens[LToken])) >
            4E-6 * Max(1.0, Abs(Bits(LExpectedTokens[LToken])))) then
          Assert.Fail(Format('riga %d, token %d: atteso %s, ottenuto %s (%d ULP)' + sLineBreak +
            'atteso   %s' + sLineBreak + 'ottenuto %s',
            [LLine, LToken, LExpectedTokens[LToken], LActualTokens[LToken],
             UlpDistance(LExpectedBits, LActualBits), AExpected[LLine], AActual[LLine]]));
      end
      else
        Assert.AreEqual(LExpectedTokens[LToken], LActualTokens[LToken], 'riga ' + IntToStr(LLine));
    end;
  end;
end;

{ TTestFloatParity }

procedure TTestFloatParity.Setup;
begin
  // the C++ divides by zero and produces NaN without traps: mask the FPU exceptions
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
  FLines := TStringList.Create;
  FLines.LoadFromFile(TIdLibGolden.DataPath('..\MathCore\float.golden.txt'));
end;

procedure TTestFloatParity.TearDown;
begin
  SetExceptionMask(FOldMask);
  FLines.Free;
end;

procedure TTestFloatParity.Run(const APrefixes: array of string; const AMaxUlps: Integer);
var
  LIndex, LPrefix: Integer;
  LName, LLine: string;
  LFloats: TFloats;
  LActual, LExpected: TStringList;
  LMatch, LKnown: Boolean;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LIndex := 0 to FLines.Count - 1 do
    begin
      LMatch := False;
      for LPrefix := 0 to High(APrefixes) do
        if FLines[LIndex].StartsWith(APrefixes[LPrefix]) then
          LMatch := True;
      if not LMatch then
        Continue;
      LFloats := ParseInputs(FLines[LIndex], LName);
      LLine := HeadOf(FLines[LIndex]);
      LKnown := ComputeAngles(LName, LFloats, LLine) or ComputeMat(LName, LFloats, LLine) or
        ComputeQuat(LName, LFloats, LLine) or ComputeRotation(LName, LFloats, LLine) or
        ComputeComplex(LName, LFloats, LLine);
      Assert.IsTrue(LKnown, 'operazione sconosciuta ' + LName);
      LActual.Add(LLine);
      LExpected.Add(FLines[LIndex]);
    end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden');
    CompareLines(LExpected, LActual, AMaxUlps);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestFloatParity.TIdAnglesDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['A_'], 2);
end;

procedure TTestFloatParity.LeConversioniDaMatriceDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['R_'], 2);
end;

procedure TTestFloatParity.TIdMat3DovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['M_'], 2);
end;

procedure TTestFloatParity.TIdQuatDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['Q_', 'C_'], 2);
end;

procedure TTestFloatParity.TIdRotationDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['Rot_'], 2);
end;

procedure TTestFloatParity.TIdComplexDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['X_'], 2);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFloatParity);

end.
