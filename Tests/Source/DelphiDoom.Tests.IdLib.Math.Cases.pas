{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib math - the scenarios of math.golden.txt      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Math.Cases;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The same scenarios as the C++ harness that wrote math.golden.txt: the scalar functions of
  ///   idMath on 127 floats and 22 integers, idRandom and idRandom2, idVec2, idVec3 and idVec4.
  ///   Every result is a float bit pattern ('#' token), a double (the letter D and 16 digits) or
  ///   an integer.
  /// </summary>
  TIdLibMathCases = class
  public
    class procedure LoadInput(const AInputPath: string; out AValues: TArray<Single>); static;
    class procedure Scalars(const AValues: TArray<Single>; const ALines: TStrings); static;
    class procedure Randoms(const ALines: TStrings); static;
    class procedure Vec3s(const AValues: TArray<Single>; const ALines: TStrings); static;
    class procedure Vec2s(const AValues: TArray<Single>; const ALines: TStrings); static;
    class procedure Vec4s(const AValues: TArray<Single>; const ALines: TStrings); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Random, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Tests.IdLib.Golden;

function FT(const AValue: Single): string;
begin
  Result := TIdLibGolden.FloatToken(AValue);
end;

function B(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

procedure PF(const ALines: TStrings; const AName: string; const AIndex: Integer; const AValue: Single);
begin
  ALines.Add(Format('%s %d %s', [AName, AIndex, FT(AValue)]));
end;

procedure PD(const ALines: TStrings; const AName: string; const AIndex: Integer; const AValue: Double);
var
  LBits: UInt64;
begin
  LBits := PUInt64(@AValue)^;
  ALines.Add(Format('%s %d D%s%s', [AName, AIndex, LowerCase(IntToHex(Cardinal(LBits shr 32), 8)),
    LowerCase(IntToHex(Cardinal(LBits), 8))]));
end;

procedure PN(const ALines: TStrings; const AName: string; const AIndex: Integer; const AValue: Integer);
begin
  ALines.Add(Format('%s %d %d', [AName, AIndex, AValue]));
end;

procedure PV2(const ALines: TStrings; const AName: string; const AIndex: Integer; const AValue: TIdVec2);
begin
  ALines.Add(Format('%s %d %s %s', [AName, AIndex, FT(AValue.X), FT(AValue.Y)]));
end;

procedure PV3(const ALines: TStrings; const AName: string; const AIndex: Integer; const AValue: TIdVec3);
begin
  ALines.Add(Format('%s %d %s %s %s', [AName, AIndex, FT(AValue.X), FT(AValue.Y), FT(AValue.Z)]));
end;

procedure PV4(const ALines: TStrings; const AName: string; const AIndex: Integer; const AValue: TIdVec4);
begin
  ALines.Add(Format('%s %d %s %s %s %s', [AName, AIndex, FT(AValue.X), FT(AValue.Y), FT(AValue.Z), FT(AValue.W)]));
end;

class procedure TIdLibMathCases.LoadInput(const AInputPath: string; out AValues: TArray<Single>);
var
  LInput: TStringList;
  LIndex, LCount: Integer;
  LBits: Cardinal;
begin
  LInput := TStringList.Create;
  try
    LInput.LoadFromFile(AInputPath);
    SetLength(AValues, 256);
    LCount := 0;
    for LIndex := 0 to LInput.Count - 1 do
      if Copy(LInput[LIndex], 1, 2) = 'f ' then
      begin
        LBits := Cardinal(StrToInt64('$' + Copy(LInput[LIndex], 3, 8)));
        AValues[LCount] := PSingle(@LBits)^;
        Inc(LCount);
      end;
    // the harness keeps the array at 256 entries with zeros after the data, and loops to the real count
    SetLength(AValues, LCount);
  finally
    LInput.Free;
  end;
end;

class procedure TIdLibMathCases.Scalars(const AValues: TArray<Single>; const ALines: TStrings);
const
  INTS: array[0..21] of Integer = (0, 1, 2, 3, 5, 7, 8, 9, 15, 16, 17, 255, 256, 1000, 65535, 65536, 1000000, -1, -2,
    -5, -256, 2147483647);
var
  LCount, LI, LEb, LMb, LBits, LV: Integer;
  LX, LAbs, LS, LC: Single;
  LPair: array[0..1] of Single;
begin
  ALines.Add('== scalars');
  LCount := Length(AValues);
  for LI := 0 to LCount - 1 do
  begin
    LX := AValues[LI];
    LAbs := TIdMath.Fabs(LX);
    PF(ALines, 'RSqrt', LI, TIdMath.RSqrt(LAbs));
    PF(ALines, 'InvSqrt', LI, TIdMath.InvSqrt(LAbs));
    PF(ALines, 'InvSqrt16', LI, TIdMath.InvSqrt16(LAbs));
    PD(ALines, 'InvSqrt64', LI, TIdMath.InvSqrt64(LAbs));
    PF(ALines, 'Sqrt', LI, TIdMath.Sqrt(LAbs));
    PF(ALines, 'Sqrt16', LI, TIdMath.Sqrt16(LAbs));
    PD(ALines, 'Sqrt64', LI, TIdMath.Sqrt64(LAbs));
    PF(ALines, 'Sin16', LI, TIdMath.Sin16(LX));
    PF(ALines, 'Cos16', LI, TIdMath.Cos16(LX));
    TIdMath.SinCos16(LX, LS, LC);
    PF(ALines, 'SinCos16s', LI, LS);
    PF(ALines, 'SinCos16c', LI, LC);
    PF(ALines, 'Tan16', LI, TIdMath.Tan16(LX));
    PF(ALines, 'ASin16', LI, TIdMath.ASin16(LX));
    PF(ALines, 'ACos16', LI, TIdMath.ACos16(LX));
    PF(ALines, 'ATan16', LI, TIdMath.ATan16(LX));
    PF(ALines, 'ATan16xy', LI, TIdMath.ATan16(LX, AValues[(LI + 1) mod LCount]));
    PF(ALines, 'Exp16', LI, TIdMath.Exp16(TIdMath.ClampFloat(-80.0, 80.0, LX)));
    PF(ALines, 'Log16', LI, TIdMath.Log16(LAbs));
    PF(ALines, 'Pow16', LI, TIdMath.Pow16(LAbs, TIdMath.ClampFloat(-3.0, 3.0, AValues[(LI + 2) mod LCount])));
    PF(ALines, 'ASin', LI, TIdMath.ASin(LX));
    PF(ALines, 'ACos', LI, TIdMath.ACos(LX));
    if LAbs <= 8.0 then
    begin
      PF(ALines, 'Sin', LI, TIdMath.Sin(LX));
      PF(ALines, 'Cos', LI, TIdMath.Cos(LX));
      TIdMath.SinCos(LX, LS, LC);
      PF(ALines, 'SinCoss', LI, LS);
      PF(ALines, 'SinCosc', LI, LC);
      PF(ALines, 'Tan', LI, TIdMath.Tan(LX));
    end;
    PF(ALines, 'ATan', LI, TIdMath.ATan(LX));
    PF(ALines, 'ATanxy', LI, TIdMath.ATan(LX, AValues[(LI + 1) mod LCount]));
    PF(ALines, 'Exp', LI, TIdMath.Exp(TIdMath.ClampFloat(-80.0, 80.0, LX)));
    PF(ALines, 'Log', LI, TIdMath.Log(LAbs));
    PF(ALines, 'Pow', LI, TIdMath.Pow(LAbs, TIdMath.ClampFloat(-3.0, 3.0, AValues[(LI + 2) mod LCount])));
    PN(ALines, 'ILog2', LI, TIdMath.ILog2(LX));
    PN(ALines, 'BitsForFloat', LI, TIdMath.BitsForFloat(LX));
    PN(ALines, 'MaskForFloatSign', LI, TIdMath.MaskForFloatSign(LX));
    PF(ALines, 'Fabs', LI, TIdMath.Fabs(LX));
    PF(ALines, 'Floor', LI, TIdMath.Floor(LX));
    PF(ALines, 'Ceil', LI, TIdMath.Ceil(LX));
    PF(ALines, 'Rint', LI, TIdMath.Rint(LX));
    if LAbs < 2E9 then
    begin
      PN(ALines, 'Ftoi', LI, TIdMath.Ftoi(LX));
      PN(ALines, 'FtoiFast', LI, TIdMath.FtoiFast(LX));
    end;
    PF(ALines, 'Normalize360', LI, TIdMath.AngleNormalize360(LX));
    PF(ALines, 'Normalize180', LI, TIdMath.AngleNormalize180(LX));
    PF(ALines, 'AngleDelta', LI, TIdMath.AngleDelta(LX, AValues[(LI + 3) mod LCount]));
    PF(ALines, 'ClampFloat', LI, TIdMath.ClampFloat(-1.5, 2.5, LX));
    LEb := 4;
    while LEb <= 8 do
    begin
      LMb := 4;
      while LMb <= 20 do
      begin
        LBits := TIdMath.FloatToBits(LX, LEb, LMb);
        ALines.Add(Format('FloatToBits %d %d %d %d', [LI, LEb, LMb, LBits]));
        PF(ALines, 'BitsToFloat', LI * 100 + LEb * 10 + LMb, TIdMath.BitsToFloat(LBits, LEb, LMb));
        Inc(LMb, 8);
      end;
      Inc(LEb, 2);
    end;
    LPair[0] := LX;
    LPair[1] := AValues[(LI + 1) mod LCount];
    PN(ALines, 'FloatHash', LI, TIdMath.FloatHash(LPair, 2));
  end;
  for LI := 0 to 21 do
  begin
    LV := INTS[LI];
    if LV > 0 then PN(ALines, 'iILog2', LI, TIdMath.ILog2(LV)) else PN(ALines, 'iILog2', LI, -999);
    if LV > 0 then PN(ALines, 'iBitsForInteger', LI, TIdMath.BitsForInteger(LV)) else PN(ALines, 'iBitsForInteger', LI, -999);
    if LV > 0 then PN(ALines, 'iFloorPowerOfTwo', LI, TIdMath.FloorPowerOfTwo(LV)) else PN(ALines, 'iFloorPowerOfTwo', LI, -999);
    if (LV > 0) and (LV < 1000000000) then
      PN(ALines, 'iCeilPowerOfTwo', LI, TIdMath.CeilPowerOfTwo(LV))
    else
      PN(ALines, 'iCeilPowerOfTwo', LI, -999);
    PN(ALines, 'iIsPowerOfTwo', LI, B(TIdMath.IsPowerOfTwo(LV)));
    PN(ALines, 'iBitCount', LI, TIdMath.BitCount(LV));
    PN(ALines, 'iBitReverse', LI, TIdMath.BitReverse(LV));
    if LV = Integer($80000000) then PN(ALines, 'iAbs', LI, 0) else PN(ALines, 'iAbs', LI, TIdMath.Abs(LV));
    PN(ALines, 'iMaskForIntegerSign', LI, TIdMath.MaskForIntegerSign(LV));
    PN(ALines, 'iIPow', LI, TIdMath.IPow(LV mod 10, 3));
    PN(ALines, 'iClampChar', LI, TIdMath.ClampChar(LV));
    PN(ALines, 'iClampShort', LI, TIdMath.ClampShort(LV));
    PN(ALines, 'iClampInt', LI, TIdMath.ClampInt(-7, 77, LV));
  end;
end;

class procedure TIdLibMathCases.Randoms(const ALines: TStrings);
var
  LRandom: TIdRandom;
  LRandom2: TIdRandom2;
  LI, LA, LD: Integer;
  LB, LC: Single;
begin
  ALines.Add('== random');
  LRandom := TIdRandom.Create(12345);
  for LI := 0 to 199 do
  begin
    LA := LRandom.RandomInt;
    LB := LRandom.RandomFloat;
    LC := LRandom.CRandomFloat;
    LD := LRandom.RandomInt(1 + LI);
    ALines.Add(Format('r %d %d %s %s %d seed=%d', [LI, LA, FT(LB), FT(LC), LD, LRandom.GetSeed]));
  end;
  LRandom := TIdRandom.Create(0);
  ALines.Add(Format('r0 %d', [LRandom.RandomInt(0)]));
  LRandom2 := TIdRandom2.Create(777);
  for LI := 0 to 199 do
  begin
    LA := LRandom2.RandomInt;
    LB := LRandom2.RandomFloat;
    LC := LRandom2.CRandomFloat;
    LD := LRandom2.RandomInt(1 + LI mod 50);
    ALines.Add(Format('q %d %d %s %s %d seed=%u', [LI, LA, FT(LB), FT(LC), LD, LRandom2.GetSeed]));
  end;
  LRandom2 := TIdRandom2.Create(5);
  ALines.Add(Format('q0 %d', [LRandom2.RandomInt(0)]));
end;

class procedure TIdLibMathCases.Vec3s(const AValues: TArray<Single>; const ALines: TStrings);
const
  BASE = 37;
var
  LCount, LN, LI, LOk: Integer;
  LA, LB, LC, LT, LL, LD, LU, LNa, LNb, LNrm: TIdVec3;
  LK, LLen, LPitch, LYaw, LRoll: Single;
  LSp: array[0..17] of TIdVec3;
  LV2: TIdVec2;
begin
  ALines.Add('== vec3');
  LCount := Length(AValues);
  LN := (LCount - 40) div 3 - 1;
  for LI := 0 to LN - 1 do
  begin
    LA := TIdVec3.Create(AValues[BASE + LI * 3], AValues[BASE + LI * 3 + 1], AValues[BASE + LI * 3 + 2]);
    LB := TIdVec3.Create(AValues[BASE + LI * 3 + 3], AValues[BASE + LI * 3 + 4], AValues[BASE + LI * 3 + 5]);
    LK := AValues[LI mod 36];
    PV3(ALines, 'add', LI, LA + LB);
    PV3(ALines, 'sub', LI, LA - LB);
    PV3(ALines, 'neg', LI, -LA);
    PF(ALines, 'dot', LI, LA * LB);
    PV3(ALines, 'mulk', LI, LA * LK);
    PV3(ALines, 'kmul', LI, LK * LA);
    if LK = 0.0 then
      PV3(ALines, 'divk', LI, LA / 3.0)
    else
      PV3(ALines, 'divk', LI, LA / LK);
    PV3(ALines, 'cross', LI, LA.Cross(LB));
    LC.Cross(LA, LB);
    PV3(ALines, 'cross2', LI, LC);
    PF(ALines, 'len', LI, LA.Length);
    PF(ALines, 'lensqr', LI, LA.LengthSqr);
    PF(ALines, 'lenfast', LI, LA.LengthFast);
    LT := LA;
    LLen := LT.Normalize;
    PV3(ALines, 'normalize', LI, LT);
    PF(ALines, 'normlen', LI, LLen);
    LT := LA;
    LLen := LT.NormalizeFast;
    PV3(ALines, 'normfast', LI, LT);
    PF(ALines, 'normfastlen', LI, LLen);
    LT := LA;
    LT.Truncate(3.5);
    PV3(ALines, 'truncate', LI, LT);
    LT := LA;
    LT.Truncate(0.0);
    PV3(ALines, 'truncate0', LI, LT);
    LT := LA;
    LT.Clamp(TIdVec3.Create(-50, -0.5, -2), TIdVec3.Create(60, 0.5, 3));
    PV3(ALines, 'clamp', LI, LT);
    LT := LA;
    LT.Snap;
    PV3(ALines, 'snap', LI, LT);
    LT := LA;
    LT.SnapInt;
    PV3(ALines, 'snapint', LI, LT);
    PF(ALines, 'yaw', LI, LA.ToYaw);
    PF(ALines, 'pitch', LI, LA.ToPitch);
    LA.ToAngles(LPitch, LYaw, LRoll);
    PF(ALines, 'ang_p', LI, LPitch);
    PF(ALines, 'ang_y', LI, LYaw);
    PF(ALines, 'ang_r', LI, LRoll);
    LA.ToPolar(LLen, LYaw, LPitch);
    PF(ALines, 'pol_r', LI, LLen);
    PF(ALines, 'pol_t', LI, LYaw);
    PF(ALines, 'pol_p', LI, LPitch);
    LA.NormalVectors(LL, LD);
    PV3(ALines, 'nv_l', LI, LL);
    PV3(ALines, 'nv_d', LI, LD);
    LA.OrthogonalBasis(LL, LU);
    PV3(ALines, 'ob_l', LI, LL);
    PV3(ALines, 'ob_u', LI, LU);
    LNrm := LB;
    LNrm.Normalize;
    LT := LA;
    LT.ProjectOntoPlane(LNrm, 1.0);
    PV3(ALines, 'pop1', LI, LT);
    LT := LA;
    LT.ProjectOntoPlane(LNrm, 1.5);
    PV3(ALines, 'pop15', LI, LT);
    LT := LA;
    LOk := B(LT.ProjectAlongPlane(LNrm, 0.01, 1.0));
    PN(ALines, 'pap_ok', LI, LOk);
    PV3(ALines, 'pap', LI, LT);
    LT := LA;
    LT.ProjectSelfOntoSphere(3.0);
    PV3(ALines, 'sphere', LI, LT);
    LT.Lerp(LA, LB, -0.5);
    PV3(ALines, 'lerp-', LI, LT);
    LT.Lerp(LA, LB, 0.25);
    PV3(ALines, 'lerp25', LI, LT);
    LT.Lerp(LA, LB, 1.5);
    PV3(ALines, 'lerp+', LI, LT);
    LNa := LA;
    LNb := LB;
    LNa.Normalize;
    LNb.Normalize;
    LT.SLerp(LNa, LNb, 0.3);
    PV3(ALines, 'slerp3', LI, LT);
    LT.SLerp(LNa, LNb, 0.9);
    PV3(ALines, 'slerp9', LI, LT);
    LT.SLerp(LNa, LNa, 0.5);
    PV3(ALines, 'slerpsame', LI, LT);
    PN(ALines, 'cmp', LI, B(LA.Compare(LB, 100.0)));
    PN(ALines, 'cmpe', LI, B(LA = LA));
    PN(ALines, 'eq', LI, B(LA = LB));
    LT := LA;
    LT.DivideComponents(LB);
    PV3(ALines, 'divc', LI, LT);
    LT := LA;
    PN(ALines, 'fixden', LI, B(LT.FixDenormals));
    PV3(ALines, 'fixden_v', LI, LT);
    LV2 := LA.ToVec2;
    PV2(ALines, 'tovec2', LI, LV2);
    ALines.Add(Format('tostring %d "%s"', [LI, string(LA.ToString(3))]));
  end;
  LSp[0] := TIdVec3.Create(0, 0, 5);
  LSp[1] := TIdVec3.Create(0, 0, -0.5);
  LSp[2] := TIdVec3.Create(0, 5, 0);
  LSp[3] := TIdVec3.Create(0, -1, 0);
  LSp[4] := TIdVec3.Create(3, 0, 0);
  LSp[5] := TIdVec3.Create(-1, 0, 0);
  LSp[6] := TIdVec3.Create(1, 0, 0);
  LSp[7] := TIdVec3.Create(0, 0, 1);
  LSp[8] := TIdVec3.Create(1, 0.001, 0);
  LSp[9] := TIdVec3.Create(0.001, 1, 0);
  LSp[10] := TIdVec3.Create(0, 0.001, 1);
  LSp[11] := TIdVec3.Create(1, 1, 0);
  LSp[12] := TIdVec3.Create(-1, 0.5, 0);
  LSp[13] := TIdVec3.Create(0, 0, 0);
  LSp[14] := TIdVec3.Create(1E-31, 2E-31, 3);
  LSp[15] := TIdVec3.Create(1, 1E-31, 0);
  LSp[16] := TIdVec3.Create(0.5, 0.5, 0.5);
  LSp[17] := TIdVec3.Create(0, 1, 0.0000001);
  for LI := 0 to 17 do
  begin
    LT := LSp[LI];
    LOk := B(LT.FixDegenerateNormal);
    PN(ALines, 'fdn', LI, LOk);
    PV3(ALines, 'fdn_v', LI, LT);
    LT := LSp[LI];
    LOk := B(LT.FixDenormals);
    PN(ALines, 'fdnorm', LI, LOk);
    PV3(ALines, 'fdnorm_v', LI, LT);
    PF(ALines, 'sp_yaw', LI, LSp[LI].ToYaw);
    PF(ALines, 'sp_pitch', LI, LSp[LI].ToPitch);
    LSp[LI].ToAngles(LPitch, LYaw, LRoll);
    PF(ALines, 'sp_ang_p', LI, LPitch);
    PF(ALines, 'sp_ang_y', LI, LYaw);
    LSp[LI].NormalVectors(LL, LD);
    PV3(ALines, 'sp_nv_l', LI, LL);
    PV3(ALines, 'sp_nv_d', LI, LD);
    LSp[LI].OrthogonalBasis(LL, LU);
    PV3(ALines, 'sp_ob_l', LI, LL);
    PV3(ALines, 'sp_ob_u', LI, LU);
  end;
end;

class procedure TIdLibMathCases.Vec2s(const AValues: TArray<Single>; const ALines: TStrings);
var
  LI: Integer;
  LA, LB, LT: TIdVec2;
  LK, LLen: Single;
begin
  ALines.Add('== vec2');
  for LI := 0 to 29 do
  begin
    LA := TIdVec2.Create(AValues[37 + LI * 2], AValues[37 + LI * 2 + 1]);
    LB := TIdVec2.Create(AValues[37 + LI * 2 + 2], AValues[37 + LI * 2 + 3]);
    LK := AValues[LI mod 36];
    PV2(ALines, 'add', LI, LA + LB);
    PV2(ALines, 'sub', LI, LA - LB);
    PV2(ALines, 'neg', LI, -LA);
    PF(ALines, 'dot', LI, LA * LB);
    PV2(ALines, 'mulk', LI, LA * LK);
    PV2(ALines, 'kmul', LI, LK * LA);
    if LK = 0.0 then
      PV2(ALines, 'divk', LI, LA / 3.0)
    else
      PV2(ALines, 'divk', LI, LA / LK);
    PF(ALines, 'len', LI, LA.Length);
    PF(ALines, 'lensqr', LI, LA.LengthSqr);
    PF(ALines, 'lenfast', LI, LA.LengthFast);
    LT := LA;
    LLen := LT.Normalize;
    PV2(ALines, 'normalize', LI, LT);
    PF(ALines, 'normlen', LI, LLen);
    LT := LA;
    LLen := LT.NormalizeFast;
    PV2(ALines, 'normfast', LI, LT);
    PF(ALines, 'normfastlen', LI, LLen);
    LT := LA;
    LT.Truncate(3.5);
    PV2(ALines, 'truncate', LI, LT);
    LT := LA;
    LT.Clamp(TIdVec2.Create(-50, -0.5), TIdVec2.Create(60, 0.5));
    PV2(ALines, 'clamp', LI, LT);
    LT := LA;
    LT.Snap;
    PV2(ALines, 'snap', LI, LT);
    LT := LA;
    LT.SnapInt;
    PV2(ALines, 'snapint', LI, LT);
    LT.Lerp(LA, LB, 0.25);
    PV2(ALines, 'lerp25', LI, LT);
    PN(ALines, 'cmp', LI, B(LA.Compare(LB, 100.0)));
    PN(ALines, 'eq', LI, B(LA = LB));
    ALines.Add(Format('tostring %d "%s"', [LI, string(LA.ToString(3))]));
  end;
end;

class procedure TIdLibMathCases.Vec4s(const AValues: TArray<Single>; const ALines: TStrings);
var
  LI: Integer;
  LA, LB, LT: TIdVec4;
  LK, LLen: Single;
begin
  ALines.Add('== vec4');
  for LI := 0 to 19 do
  begin
    LA := TIdVec4.Create(AValues[37 + LI * 4], AValues[37 + LI * 4 + 1], AValues[37 + LI * 4 + 2], AValues[37 + LI * 4 + 3]);
    LB := TIdVec4.Create(AValues[37 + LI * 4 + 4], AValues[37 + LI * 4 + 5], AValues[37 + LI * 4 + 6], AValues[37 + LI * 4 + 7]);
    LK := AValues[LI mod 36];
    PV4(ALines, 'add', LI, LA + LB);
    PV4(ALines, 'sub', LI, LA - LB);
    PV4(ALines, 'neg', LI, -LA);
    PF(ALines, 'dot', LI, LA * LB);
    PV4(ALines, 'mulk', LI, LA * LK);
    PV4(ALines, 'kmul', LI, LK * LA);
    if LK = 0.0 then
      PV4(ALines, 'divk', LI, LA / 3.0)
    else
      PV4(ALines, 'divk', LI, LA / LK);
    PF(ALines, 'len', LI, LA.Length);
    PF(ALines, 'lensqr', LI, LA.LengthSqr);
    LT := LA;
    LLen := LT.Normalize;
    PV4(ALines, 'normalize', LI, LT);
    PF(ALines, 'normlen', LI, LLen);
    LT := LA;
    LLen := LT.NormalizeFast;
    PV4(ALines, 'normfast', LI, LT);
    PF(ALines, 'normfastlen', LI, LLen);
    LT.Lerp(LA, LB, 0.25);
    PV4(ALines, 'lerp25', LI, LT);
    PN(ALines, 'cmp', LI, B(LA.Compare(LB, 100.0)));
    PN(ALines, 'eq', LI, B(LA = LB));
    PV3(ALines, 'tovec3', LI, LA.ToVec3);
    PV2(ALines, 'tovec2', LI, LA.ToVec2);
    ALines.Add(Format('tostring %d "%s"', [LI, string(LA.ToString(3))]));
  end;
end;

end.
