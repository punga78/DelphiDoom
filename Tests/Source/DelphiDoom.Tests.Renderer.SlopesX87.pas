{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the floating point of the       }
{  slopes of the 32 bit renderer                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.SlopesX87;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererSlopesX87 against the expressions of r_slopes.pas (issue #40). At 32 bit each result is compared
  ///   with the expression of the renderer computed by the FPU (copied here); the fingerprint of the results is
  ///   a constant and at 64 bit, where the renderer calls the class, the same fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererSlopesX87 = class(TObject)
  public
    [Test]
    procedure DovrebbeProiettareUnPuntoSulloSchermo;
    [Test]
    procedure DovrebbeDareLaProfonditaDiUnPunto;
    [Test]
    procedure DovrebbeDareIPassiELePosizioniDiUnLato;
    [Test]
    procedure DovrebbeInterpolareLaProfonditaLungoUnLato;
    [Test]
    procedure DovrebbeDareIlPassoDiUnMuroInPendenza;
    [Test]
    procedure DovrebbeDareLInversoInSingle;
    [Test]
    procedure DovrebbeDareGliAngoliDelFrustum;
  end;

implementation

uses
  DelphiDoom.MathCore.SoftExtended, DelphiDoom.Renderer.SlopesX87, DelphiDoom.Renderer.X87,
  DelphiDoom.Tests.MathCore.Fingerprint;

const
  FRACUNIT = 65536;
  CASES = 60000;
  // the constants of tables.pas, as the renderer has them
  D_PI = 3.141592657;
  ANGLE_T_TO_RAD = 2 * D_PI / $100000000;

type
  TRandomSource = record
    State: Cardinal;
    function Next: Cardinal;
    /// <summary>A Double with 53 random bits, signed, times a power of two</summary>
    function NextDouble(AScale: Integer): Double;
    function NextInteger(ABits: Integer): Integer;
  end;

function TRandomSource.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State xor (State shr 13);
end;

function TRandomSource.NextDouble(AScale: Integer): Double;
var
  LBits: Int64;
begin
  LBits := (Int64(Next and $1FFFFF) shl 32) or Int64(Next);
  Result := LBits / 9007199254740992.0 * AScale;
  if Next and 1 = 1 then
    Result := -Result;
end;

function TRandomSource.NextInteger(ABits: Integer): Integer;
begin
  Result := Integer(Next and Cardinal((Int64(1) shl ABits) - 1));
  if Next and 1 = 1 then
    Result := -Result;
end;

function SameBits(const A, B: Double): Boolean;
begin
  Result := PUInt64(@A)^ = PUInt64(@B)^;
end;

function SameBitsSingle(const A, B: Single): Boolean;
begin
  Result := PCardinal(@A)^ = PCardinal(@B)^;
end;

{$IF SizeOf(Extended) > SizeOf(Double)}
// R_SlopesCalcSSPoint of r_slopes.pas, as it is for the 32 bit renderer
procedure NativeProjectPoint(const wx, wy, wz, viewx, viewy, viewz, projection, projectiony, centerx, centery: Integer;
  const dviewsin, dviewcos: Double; var x, y, z: Double);
var
  x1, y1: Double;
  tr_x: Double;
  tr_y: Double;
  tr_z: Double;
  tx: Double;
  tz: Double;
  xscale: Double;
  yscale: Double;
  dcos, dsin: Double;
begin
  tr_x := (wx - viewx) / FRACUNIT;
  tr_y := (wy - viewy) / FRACUNIT;
  tr_z := (wz - viewz) / FRACUNIT;
  dcos := dviewcos;
  dsin := dviewsin;

  tz := 1.0 / (tr_x * dcos + tr_y * dsin);

  z := projection * tz;
  xscale := z / FRACUNIT;

  tx := tr_x * dsin - tr_y * dcos;

  x1 := centerx + tx * xscale;

  yscale := projectiony / FRACUNIT * tz;
  y1 := centery - tr_z * yscale;

  x := x1;
  y := y1;
end;
{$IFEND}

{ TTestRendererSlopesX87 }

procedure TTestRendererSlopesX87.DovrebbeProiettareUnPuntoSulloSchermo;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LViewX, LViewY, LViewZ, LWorldX, LWorldY, LWorldZ: Integer;
  LSine, LCosine, LX, LY, LZ: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNativeX, LNativeY, LNativeZ: Double;
  {$IFEND}
begin
  LRandom.State := 4001;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LViewX := LRandom.NextInteger(26);
      LViewY := LRandom.NextInteger(26);
      LViewZ := LRandom.NextInteger(24);
      LWorldX := LViewX + LRandom.NextInteger(25);
      LWorldY := LViewY + LRandom.NextInteger(25);
      LWorldZ := LRandom.NextInteger(24);
      LSine := TRendererX87.ViewSine(LRandom.Next);
      LCosine := TRendererX87.ViewCosine(LRandom.Next);
      TRendererSlopesX87.ProjectPoint(LWorldX, LWorldY, LWorldZ, LViewX, LViewY, LViewZ, 320 * FRACUNIT,
        400 * FRACUNIT + LIndex, 320, 240, LSine, LCosine, LX, LY, LZ);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      NativeProjectPoint(LWorldX, LWorldY, LWorldZ, LViewX, LViewY, LViewZ, 320 * FRACUNIT, 400 * FRACUNIT + LIndex,
        320, 240, LSine, LCosine, LNativeX, LNativeY, LNativeZ);
      Assert.IsTrue(SameBits(LNativeX, LX) and SameBits(LNativeY, LY) and SameBits(LNativeZ, LZ),
        Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LX);
      LFingerprint.AddDouble(LY);
      LFingerprint.AddDouble(LZ);
    end;
    Assert.AreEqual('0381B86263A32AAF/180000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererSlopesX87.DovrebbeDareLaProfonditaDiUnPunto;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LNumerator, LDenominator, LProjection: Integer;
  LScreenY, LResult: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := 4002;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LNumerator := LRandom.NextInteger(27);
      LDenominator := -(120 * FRACUNIT) - FRACUNIT div 2;
      LProjection := 300 * FRACUNIT + LRandom.NextInteger(12);
      LScreenY := LRandom.NextDouble(1024);
      LResult := TRendererSlopesX87.WorldDepth(LNumerator, LDenominator, LScreenY, LProjection);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := LNumerator / (LDenominator + LScreenY * FRACUNIT) * LProjection;
      Assert.IsTrue(SameBits(LNative, LResult), Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LResult);
    end;
    Assert.AreEqual('BB189ED7371598D2/60000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererSlopesX87.DovrebbeDareIPassiELePosizioniDiUnLato;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LA, LB, LC, LD, LStep, LStart: Double;
  LRow: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := 4003;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LA := LRandom.NextDouble(1024);
      LB := LRandom.NextDouble(1024);
      LC := LRandom.NextDouble(512);
      LD := LRandom.NextDouble(512);
      LRow := Integer(LRandom.Next mod 480);
      LStep := TRendererSlopesX87.EdgeStep(LA, LB, LC, LD);
      LStart := TRendererSlopesX87.EdgeStart(LA, LStep, LRow, LC);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := (LA - LB) / (LC - LD);
      Assert.IsTrue(SameBits(LNative, LStep), Format('step %d', [LIndex]));
      LNative := LA + LStep * (LRow - LC);
      Assert.IsTrue(SameBits(LNative, LStart), Format('start %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LStep);
      LFingerprint.AddDouble(LStart);
    end;
    Assert.AreEqual('FB9D977080EDBCF7/120000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererSlopesX87.DovrebbeInterpolareLaProfonditaLungoUnLato;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LTPos, LZ1, LZ2, LWorld1, LWorld2, LTheta, LComplement: Double;
  LRounded: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNativeTheta, LNativeComplement: Double;
  LNativeRounded: Integer;
  {$IFEND}
begin
  LRandom.State := 4004;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LTPos := LRandom.NextDouble(64) + 80;
      LZ1 := LRandom.NextDouble(64) + 80;
      LZ2 := LRandom.NextDouble(64) + 80;
      LWorld1 := LRandom.NextDouble(1 shl 20);
      LWorld2 := LRandom.NextDouble(1 shl 20);
      LTheta := TRendererSlopesX87.Theta(LTPos, LZ1, LZ2);
      LComplement := TRendererSlopesX87.ThetaComplement(LTheta);
      LRounded := TRendererSlopesX87.RoundInterpolated(LComplement, LTheta, LWorld1, LWorld2);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNativeTheta := (1.0 / LTPos - 1.0 / LZ1) / (1.0 / LZ2 - 1.0 / LZ1);
      Assert.IsTrue(SameBits(LNativeTheta, LTheta), Format('theta %d', [LIndex]));
      LNativeComplement := 1.0 - LTheta;
      Assert.IsTrue(SameBits(LNativeComplement, LComplement), Format('complement %d', [LIndex]));
      LNativeRounded := Round(LComplement * LWorld1 + LTheta * LWorld2);
      Assert.AreEqual(LNativeRounded, LRounded, Format('rounded %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LTheta);
      LFingerprint.AddDouble(LComplement);
      LFingerprint.AddInteger(LRounded);
    end;
    Assert.AreEqual('4A603713C63E35DF/180000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererSlopesX87.DovrebbeDareIlPassoDiUnMuroInPendenza;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LOrigin, LScale, LHeight, LScaleStep, LHeight1, LDifference, LEdge, LStep: Double;
  LCount, LColumn, LRounded: Integer;
  LLineStep: Single;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  LNativeRounded: Integer;
  {$IFEND}
begin
  LRandom.State := 4005;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LOrigin := LRandom.NextInteger(20) / 16;
      LScale := LRandom.NextDouble(1 shl 6);
      LHeight := LRandom.NextInteger(22) / 16;
      LScaleStep := LRandom.NextDouble(1 shl 2);
      LHeight1 := LRandom.NextInteger(22) / 16;
      LDifference := LRandom.NextInteger(22) / 16;
      LCount := 1 + Integer(LRandom.Next mod 640);
      LColumn := LRandom.NextInteger(26);
      LLineStep := LRandom.NextDouble(8);
      LEdge := TRendererSlopesX87.WallEdge(LOrigin, LScale, LHeight);
      LStep := TRendererSlopesX87.WallEdgeStep(LScaleStep, LHeight1, LScale, LDifference, LCount);
      LRounded := TRendererSlopesX87.RoundColumnStep(LColumn, LLineStep);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := LOrigin - LScale * LHeight;
      Assert.IsTrue(SameBits(LNative, LEdge), Format('edge %d', [LIndex]));
      LNative := -LScaleStep * LHeight1 + LScale * LDifference / LCount;
      Assert.IsTrue(SameBits(LNative, LStep), Format('step %d', [LIndex]));
      LNativeRounded := Round(LColumn * LLineStep);
      Assert.AreEqual(LNativeRounded, LRounded, Format('column %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LEdge);
      LFingerprint.AddDouble(LStep);
      LFingerprint.AddInteger(LRounded);
    end;
    Assert.AreEqual('D1161CF7493AAB89/180000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererSlopesX87.DovrebbeDareLInversoInSingle;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LValue, LInverse: Single;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Single;
  {$IFEND}
begin
  LRandom.State := 4006;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LValue := LRandom.NextDouble(1 shl 20);
      if LValue = 0 then
        LValue := 1;
      LInverse := TRendererSlopesX87.SingleReciprocal(LValue);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := 1.0 / LValue;
      Assert.IsTrue(SameBitsSingle(LNative, LInverse), Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddSingle(LInverse);
    end;
    Assert.AreEqual('75A3A6D97C2A8775/60000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererSlopesX87.DovrebbeDareGliAngoliDelFrustum;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LAngle: Cardinal;
  LDistance: Integer;
  LRoundedCosine, LRoundedSine, LTruncatedCosine, LTruncatedSine: Integer;
begin
  LRandom.State := 4007;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to CASES - 1 do
    begin
      LAngle := LRandom.Next;
      if LIndex mod 2 = 0 then
        LDistance := FRACUNIT * 4
      else
        LDistance := FRACUNIT * 16384;
      LRoundedCosine := TRendererX87.RoundAngleProduct(LAngle, LDistance, True);
      LRoundedSine := TRendererX87.RoundAngleProduct(LAngle, LDistance, False);
      LTruncatedCosine := TRendererX87.TruncAngleProduct(LAngle, LDistance, True);
      LTruncatedSine := TRendererX87.TruncAngleProduct(LAngle, LDistance, False);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      // the sine of the processor is not correctly rounded: the integers may differ only when the product is
      // within a few units of the last place of an integer, which is as rare as it is for the Doubles
      Assert.IsTrue(Abs(Round(Cos(LAngle * ANGLE_T_TO_RAD) * LDistance) - LRoundedCosine) <= 1,
        Format('cosine %d', [LIndex]));
      Assert.IsTrue(Abs(Round(Sin(LAngle * ANGLE_T_TO_RAD) * LDistance) - LRoundedSine) <= 1,
        Format('sine %d', [LIndex]));
      Assert.IsTrue(Abs(Trunc(Cos(LAngle * ANGLE_T_TO_RAD) * LDistance) - LTruncatedCosine) <= 1,
        Format('cosine (trunc) %d', [LIndex]));
      Assert.IsTrue(Abs(Trunc(Sin(LAngle * ANGLE_T_TO_RAD) * LDistance) - LTruncatedSine) <= 1,
        Format('sine (trunc) %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LRoundedCosine);
      LFingerprint.AddInteger(LRoundedSine);
      LFingerprint.AddInteger(LTruncatedCosine);
      LFingerprint.AddInteger(LTruncatedSine);
    end;
    Assert.AreEqual('339FF1C9E88549B3/240000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
