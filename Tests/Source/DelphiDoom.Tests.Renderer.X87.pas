{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the floating point of the       }
{  32 bit renderer                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.X87;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererX87 against the expressions of r_main.pas, r_plane.pas and r_scale.pas (issue #40). At 32 bit
  ///   each result is compared with the expression of the renderer computed by the FPU (copied here); the
  ///   fingerprint of the results is a constant and at 64 bit, where the renderer calls the class, the same
  ///   fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererX87 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareSenoECosenoDellaVista;
    [Test]
    procedure DovrebbeDareIlRapportoDelMonitor;
    [Test]
    procedure DovrebbeDareIlRapportoDeiPiani;
    [Test]
    procedure DovrebbeDareIPassiDiUnoSpan;
    [Test]
    procedure DovrebbeDareIPassiDiUnoSpanVicinoAllaMeta;
    [Test]
    procedure DovrebbeDareLaScalaDiUnMuro;
    [Test]
    procedure DovrebbeLimitareLaScalaDiUnMuro;
    [Test]
    procedure DovrebbeDareDistanzaELarghezzaDiUnaLuce;
    [Test]
    procedure DovrebbeDareSenoECosenoDiUnAngoloInSingle;
    [Test]
    procedure DovrebbeDareLaDistanzaDiUnaPendenzaPerPixel;
  end;

implementation

uses
  System.Math, DelphiDoom.MathCore.SoftExtended, DelphiDoom.Renderer.X87, DelphiDoom.Tests.MathCore.Fingerprint;

const
  // the constants of tables.pas, as the renderer has them
  D_PI = 3.141592657;
  ANGLE_T_TO_RAD = 2 * D_PI / $100000000;
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

function SameBits(const A, B: Double): Boolean;
begin
  Result := PUInt64(@A)^ = PUInt64(@B)^;
end;

{ TTestRendererX87 }

procedure TTestRendererX87.DovrebbeDareSenoECosenoDellaVista;
const
  COUNT = 100000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LAngle: Cardinal;
  LSine, LCosine: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  LDifferent: Integer;
  {$IFEND}
begin
  LRandom.State := 2026;
  LFingerprint := TFingerprint.Create;
  try
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LDifferent := 0;
    {$IFEND}
    for LIndex := 0 to COUNT - 1 do
    begin
      LAngle := LRandom.Next;
      if LIndex < 8 then
        LAngle := Cardinal(LIndex) shl 29;
      LSine := TRendererX87.ViewSine(LAngle);
      LCosine := TRendererX87.ViewCosine(LAngle);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Sin(LAngle / $FFFFFFFF * 2 * Pi);
      if not SameBits(LNative, LSine) then
        Inc(LDifferent);
      Assert.AreEqual(LNative, LSine, 1E-15, Format('sine of %u', [LAngle]));
      LNative := Cos(LAngle / $FFFFFFFF * 2 * Pi);
      if not SameBits(LNative, LCosine) then
        Inc(LDifferent);
      Assert.AreEqual(LNative, LCosine, 1E-15, Format('cosine of %u', [LAngle]));
      {$IFEND}
      LFingerprint.AddDouble(LSine);
      LFingerprint.AddDouble(LCosine);
    end;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    // the sine of the processor is not correctly rounded: measured, one Double in a hundred thousand differs
    // (by its last bit)
    Assert.IsTrue(LDifferent <= 2 * COUNT div 5000, Format('%d Doubles differ from the FPU', [LDifferent]));
    {$IFEND}
    Assert.AreEqual('BD5975BF45A31350/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeDareIlRapportoDelMonitor;
const
  WIDTHS: array[0..11] of Integer = (640, 800, 1024, 1280, 1280, 1366, 1440, 1600, 1920, 2560, 3440, 3840);
  HEIGHTS: array[0..11] of Integer = (480, 600, 768, 720, 1024, 768, 900, 900, 1080, 1440, 1440, 2160);
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LWidth, LHeight: Integer;
  LAspect, LForced: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to High(WIDTHS) do
    begin
      LWidth := WIDTHS[LIndex];
      LHeight := HEIGHTS[LIndex];
      LAspect := TRendererX87.MonitorAspect(LWidth, LHeight);
      LForced := TRendererX87.AspectOverFourThirds(LWidth / 1000);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      // R_InitAspect and R_GetRelativeAspect
      LNative := LWidth / LHeight / (4 / 3);
      Assert.IsTrue(SameBits(LNative, LAspect), Format('%d x %d', [LWidth, LHeight]));
      LNative := LWidth / 1000;
      LNative := LNative / (4 / 3);
      Assert.IsTrue(SameBits(LNative, LForced), Format('forced %d', [LWidth]));
      {$IFEND}
      LFingerprint.AddDouble(LAspect);
    end;
    Assert.AreEqual(1.0, TRendererX87.MonitorAspect(640, 480), 1E-15);
    Assert.AreEqual(4 / 3, TRendererX87.MonitorAspect(1920, 1080), 1E-15);
    Assert.AreEqual('A2D7BBEB9ED85481/12', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeDareIlRapportoDeiPiani;
const
  WIDTHS: array[0..7] of Integer = (320, 640, 800, 1024, 1280, 1366, 1920, 2560);
  HEIGHTS: array[0..7] of Integer = (200, 480, 600, 768, 720, 768, 1080, 1440);
  ASPECTS: array[0..4] of Double = (1.0, 1.2, 0.8333333333333334, 1.3333333333333333, 0.75);
var
  LFingerprint: TFingerprint;
  LSize, LAspect: Integer;
  LResult: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  LHeight, LWidth: Integer;
  {$IFEND}
begin
  LFingerprint := TFingerprint.Create;
  try
    for LSize := 0 to High(WIDTHS) do
      for LAspect := 0 to High(ASPECTS) do
      begin
        LResult := TRendererX87.PlaneRelativeAspect(HEIGHTS[LSize], WIDTHS[LSize], ASPECTS[LAspect]);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LHeight := HEIGHTS[LSize];
        LWidth := WIDTHS[LSize];
        LNative := 320 / 200 * LHeight / LWidth * ASPECTS[LAspect];
        Assert.IsTrue(SameBits(LNative, LResult), Format('%d x %d, aspect %d', [LWidth, LHeight, LAspect]));
        {$IFEND}
        LFingerprint.AddDouble(LResult);
      end;
    Assert.AreEqual(1.2, TRendererX87.PlaneRelativeAspect(480, 640, 1.0), 1E-12);
    Assert.AreEqual('52153BEDE91559E8/40', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeDareIPassiDiUnoSpan;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LHeight, LRows: Integer;
  LScreenWidth, LScreenHeight: Integer;
  LAspect, LSine, LCosine: Double;
  LX, LY, LExactX, LExactY: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LSlope: Double;
  {$IFEND}
begin
  LRandom.State := 4040;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 299999 do
    begin
      LHeight := Integer(LRandom.Next mod (512 * FRACUNIT)) + 1;
      LRows := 1 + Integer(LRandom.Next mod 1080);
      // one draw per statement: the order of evaluation of the arguments differs between the two compilers
      LScreenWidth := 320 + Integer(LRandom.Next mod 2300);
      LScreenHeight := 200 + Integer(LRandom.Next mod 1300);
      LAspect := TRendererX87.PlaneRelativeAspect(LScreenHeight, LScreenWidth, 1.0);
      LSine := TRendererX87.ViewSine(LRandom.Next);
      LCosine := TRendererX87.ViewCosine(LRandom.Next);
      TRendererX87.PlaneSteps(LHeight, LRows, LAspect, LSine, LCosine, LX, LY);
      TRendererX87.PlaneStepsExact(LHeight, LRows, LAspect, LSine, LCosine, LExactX, LExactY);
      Assert.AreEqual(LExactX, LX, Format('x step of case %d', [LIndex]));
      Assert.AreEqual(LExactY, LY, Format('y step of case %d', [LIndex]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      // R_MapPlane
      LSlope := (LHeight / LRows) * LAspect;
      Assert.AreEqual(Integer(Round(LSine * LSlope)), LExactX, Format('x step of case %d against the FPU', [LIndex]));
      Assert.AreEqual(Integer(Round(LCosine * LSlope)), LExactY, Format('y step of case %d against the FPU', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LExactX);
      LFingerprint.AddInteger(LExactY);
    end;
    Assert.AreEqual('987BFCAFCCA92048/600000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeDareIPassiDiUnoSpanVicinoAllaMeta;
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LHeight, LRows: Integer;
  LX, LY, LExactX, LExactY: Integer;
  LSine: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LSlope: Double;
  {$IFEND}
begin
  // sine 0.5 and 0.25 with an aspect of 1: the product falls on a half whenever the slope is an odd integer
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 49999 do
    begin
      LRows := 1 + LIndex mod 7;
      LHeight := (2 * LIndex + 1) * LRows;
      LSine := 0.5;
      if Odd(LIndex shr 3) then
        LSine := -0.25;
      TRendererX87.PlaneSteps(LHeight, LRows, 1.0, LSine, 0.75, LX, LY);
      TRendererX87.PlaneStepsExact(LHeight, LRows, 1.0, LSine, 0.75, LExactX, LExactY);
      Assert.AreEqual(LExactX, LX, Format('x step of case %d', [LIndex]));
      Assert.AreEqual(LExactY, LY, Format('y step of case %d', [LIndex]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LSlope := (LHeight / LRows) * 1.0;
      Assert.AreEqual(Integer(Round(LSine * LSlope)), LExactX, Format('x step of case %d against the FPU', [LIndex]));
      Assert.AreEqual(Integer(Round(0.75 * LSlope)), LExactY, Format('y step of case %d against the FPU', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LExactX);
      LFingerprint.AddInteger(LExactY);
    end;
    // halves go to the even integer
    TRendererX87.PlaneSteps(3, 1, 1.0, 0.5, -0.5, LX, LY);
    Assert.AreEqual(2, LX);
    Assert.AreEqual(-2, LY);
    TRendererX87.PlaneSteps(5, 1, 1.0, 0.5, -0.5, LX, LY);
    Assert.AreEqual(2, LX);
    Assert.AreEqual(-2, LY);
    Assert.AreEqual('1450C4399C1592BC/100000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeDareLaScalaDiUnMuro;
const
  COUNT = 100000;
  MAX_SCALE = 64 * FRACUNIT;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LProjection, LDistance: Integer;
  LAngleA, LAngleB: Cardinal;
  LResult: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNumerator, LDenominator, LNative: Double;
  LDifferent: Integer;
  {$IFEND}
begin
  LRandom.State := 630;
  LFingerprint := TFingerprint.Create;
  try
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LDifferent := 0;
    {$IFEND}
    for LIndex := 0 to COUNT - 1 do
    begin
      LProjection := (160 + Integer(LRandom.Next mod 1200)) * FRACUNIT;
      LDistance := 1 + Integer(LRandom.Next mod (4096 * FRACUNIT));
      // the angle of the column is within the field of view, the one of the wall anywhere in front
      LAngleA := $40000000 + LRandom.Next mod $20000000 - $10000000;
      LAngleB := LRandom.Next mod $7FFFFFFF + 1;
      LResult := TRendererX87.ScaleFromAngles(LProjection, LDistance, LAngleA, LAngleB, MAX_SCALE);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      // R_ScaleFromGlobalAngle_DBL
      LNumerator := LProjection * Sin(LAngleB * ANGLE_T_TO_RAD);
      LDenominator := LDistance * Sin(LAngleA * ANGLE_T_TO_RAD);
      LNative := (LNumerator / LDenominator) * FRACUNIT;
      if LNative < 256 then
        LNative := 256
      else if LNative > MAX_SCALE then
        LNative := MAX_SCALE;
      if not SameBits(LNative, LResult) then
        Inc(LDifferent);
      Assert.AreEqual(LNative, LResult, Abs(LNative) * 1E-15, Format('case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddDouble(LResult);
    end;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    Assert.IsTrue(LDifferent <= COUNT div 2000, Format('%d Doubles differ from the FPU', [LDifferent]));
    {$IFEND}
    Assert.AreEqual('21F977DEFCF71FDB/100000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeLimitareLaScalaDiUnMuro;
const
  MAX_SCALE = 64 * FRACUNIT;
begin
  // a wall at distance zero: the denominator is zero
  Assert.AreEqual(Double(MAX_SCALE), TRendererX87.ScaleFromAngles(160 * FRACUNIT, 0, $40000000, $40000000, MAX_SCALE));
  Assert.AreEqual(Double(256), TRendererX87.ScaleFromAngles(160 * FRACUNIT, 0, $40000000, $C0000000, MAX_SCALE));
  // very far and very near
  Assert.AreEqual(Double(256), TRendererX87.ScaleFromAngles(FRACUNIT, MaxInt, $40000000, $40000000, MAX_SCALE));
  Assert.AreEqual(Double(MAX_SCALE), TRendererX87.ScaleFromAngles(160 * FRACUNIT, 1, $40000000, $40000000, MAX_SCALE));
  // facing the wall at the distance of the projection: the scale is one
  Assert.AreEqual(Double(FRACUNIT), TRendererX87.ScaleFromAngles(160 * FRACUNIT, 160 * FRACUNIT, $40000000, $40000000,
    MAX_SCALE), 1E-6);
end;

procedure TTestRendererX87.DovrebbeDareDistanzaELarghezzaDiUnaLuce;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LX, LY, LZ, LLightX, LLightY, LLightZ, LRadius: Single;
  LDistance, LWidth: Single;
  LFactor: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LDeltaX, LDeltaY, LDeltaZ, LNative: Single;
  {$IFEND}
begin
  LRandom.State := 289;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to 199999 do
    begin
      // one draw per statement; the positions are 16.16 numbers divided by 65536, the offsets of the lights
      // are the decimal numbers of a definition
      LX := (Integer(LRandom.Next) div 64) / 65536;
      LY := (Integer(LRandom.Next) div 64) / 65536;
      LZ := (Integer(LRandom.Next) div 4096) / 65536;
      LLightX := (Integer(LRandom.Next mod 2001) - 1000) / 100;
      LLightY := (Integer(LRandom.Next mod 2001) - 1000) / 100;
      LLightZ := (Integer(LRandom.Next mod 6401)) / 100;
      LRadius := (1 + Integer(LRandom.Next mod 25600)) / 100;
      LFactor := 1 + Integer(LRandom.Next mod 10);
      LDistance := TRendererX87.LightSquareDistance(LX, LY, LZ, LLightX, LLightY, LLightZ);
      LWidth := TRendererX87.LightWidth(LRadius, LFactor, 5);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      // R_MarkDLights and R_DrawVisLight
      LDeltaX := LX - LLightX;
      LDeltaY := LY - LLightY;
      LDeltaZ := LZ - LLightZ;
      LNative := LDeltaX * LDeltaX + LDeltaY * LDeltaY + LDeltaZ * LDeltaZ;
      Assert.AreEqual(PCardinal(@LNative)^, PCardinal(@LDistance)^, Format('distance of case %d', [LIndex]));
      LNative := 2 * LRadius * LFactor / 5;
      Assert.AreEqual(PCardinal(@LNative)^, PCardinal(@LWidth)^, Format('width of case %d', [LIndex]));
      {$IFEND}
      LFingerprint.AddSingle(LDistance);
      LFingerprint.AddSingle(LWidth);
    end;
    Assert.AreEqual('FBFF728970162698/400000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87.DovrebbeDareLaDistanzaDiUnaPendenzaPerPixel;
const
  COUNT = 600000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LScreenDX, LTheta, LRTheta: Integer;
  LLeftWorld, LRightWorld: Integer;
  LInverseLeft, LInverseRight: Single;
  LResult, LExact: Integer;
begin
  // r_slopes: distance := Abs(Round(1.0 / (rTheta * inv_zleft + Theta * inv_zright))) with Single inverses
  LRandom.State := 9090;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      // one draw per statement: the order of evaluation of the arguments differs between the two compilers
      LScreenDX := 2 + Integer(LRandom.Next mod 2400);
      LTheta := 1 + Integer(LRandom.Next mod Cardinal(LScreenDX - 1));
      LRTheta := LScreenDX - LTheta;
      LLeftWorld := 1 + Integer(LRandom.Next mod (1 shl (8 + LIndex mod 17)));
      LRightWorld := 1 + Integer(LRandom.Next mod (1 shl (8 + LIndex mod 17)));
      LInverseLeft := 1.0 / Single(Int64(LLeftWorld) * LScreenDX);
      LInverseRight := 1.0 / Single(Int64(LRightWorld) * LScreenDX);
      LResult := TRendererX87.SlopeInverseDistance(LRTheta, LTheta, LInverseLeft, LInverseRight);
      LExact := TRendererX87.SlopeInverseDistanceExact(LRTheta, LTheta, LInverseLeft, LInverseRight);
      Assert.AreEqual(LExact, LResult, Format('case %d', [LIndex]));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Integer(Round(1.0 / (LRTheta * LInverseLeft + LTheta * LInverseRight))), LExact,
        Format('case %d against the FPU', [LIndex]));
      {$IFEND}
      LFingerprint.AddInteger(LExact);
    end;
    Assert.AreEqual('6903B9AF79E0BE5A/600000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;
procedure TTestRendererX87.DovrebbeDareSenoECosenoDiUnAngoloInSingle;
const
  COUNT = 100000;
type
  angle_t = LongWord;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LAngle, LView: angle_t;
  LSine, LCosine, LViewSine: Single;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Single;
  LDifferent: Integer;
  {$IFEND}
begin
  LRandom.State := 1757;
  LFingerprint := TFingerprint.Create;
  try
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LDifferent := 0;
    {$IFEND}
    for LIndex := 0 to COUNT - 1 do
    begin
      LAngle := LRandom.Next;
      LView := LRandom.Next;
      // ds_sine, ds_cosine and ds_viewsine of R_DrawPlanes: the first angle is negative
      LSine := TRendererX87.AngleSineSingle(-Int64(LAngle));
      LCosine := TRendererX87.AngleCosineSingle(LAngle);
      LViewSine := TRendererX87.AngleSineSingle(angle_t(LView - LAngle));
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := Sin(-LAngle * ANGLE_T_TO_RAD);
      if PCardinal(@LNative)^ <> PCardinal(@LSine)^ then
        Inc(LDifferent);
      LNative := Cos(LAngle * ANGLE_T_TO_RAD);
      if PCardinal(@LNative)^ <> PCardinal(@LCosine)^ then
        Inc(LDifferent);
      LNative := Sin((LView - LAngle) * ANGLE_T_TO_RAD);
      if PCardinal(@LNative)^ <> PCardinal(@LViewSine)^ then
        Inc(LDifferent);
      {$IFEND}
      LFingerprint.AddSingle(LSine);
      LFingerprint.AddSingle(LCosine);
      LFingerprint.AddSingle(LViewSine);
    end;
    {$IF SizeOf(Extended) > SizeOf(Double)}
    // a Single hides the last bit of the sine of the processor nearly always
    Assert.IsTrue(LDifferent <= 2, Format('%d Singles differ from the FPU', [LDifferent]));
    {$IFEND}
    Assert.AreEqual('F874E029A07248CA/300000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
