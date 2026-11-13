{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the geometry of id Tech 4 (planes, bounds, spheres,    }
{  boxes) - parity with the C++ idLib                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Geometry.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idlib of Doom 3 (Tests\Data\MathCore\geometry.golden.txt: 9109 lines
  ///   written by idPlane, idBounds, idSphere and idBox compiled with bcc32c on the x87, with the
  ///   inputs on each line: "name in... | out..."). Every line is recomputed from its own inputs.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestGeometryParity = class(TObject)
  private
    FLines: TStringList;
    FOldMask: TArithmeticExceptionMask;
    procedure Run(const APrefixes: array of string; const AMaxUlps: Integer;
      const AAbsTolerance: Single = 0);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IPianiDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IBoundsDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IBoundsInRotazioneDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeSfereDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeSfereInRotazioneDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeScatoleDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeScatoleCheCresconoDovrebberoDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Rotation,
  DelphiDoom.MathCore.Float.BoundsRotation,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Sphere, DelphiDoom.Geometry.Box,
  DelphiDoom.Tests.IdLib.Golden;

type
  TFloats = array of Single;

  /// <summary>Reads the inputs of a line: floats written as #bits, then integers</summary>
  TReader = record
    Tokens: TArray<string>;
    Position: Integer;
    function Float: Single;
    function Int: Integer;
    function Vec: TGeoVec3;
    function Mat: TGeoMat3;
    function Plane: TGeoPlane;
    function Bounds: TGeoBounds;
    function Sphere: TGeoSphere;
    function Box: TGeoBox;
    function Rotation: TIdRotation;
  end;

function Bits(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Result := PSingle(@LBits)^;
end;

function TReader.Float: Single;
begin
  Result := Bits(Tokens[Position]);
  Inc(Position);
end;

function TReader.Int: Integer;
begin
  Result := StrToInt(Tokens[Position]);
  Inc(Position);
end;

function TReader.Vec: TGeoVec3;
begin
  Result.X := Float;
  Result.Y := Float;
  Result.Z := Float;
end;

function TReader.Mat: TGeoMat3;
begin
  Result.Rows[0] := Vec;
  Result.Rows[1] := Vec;
  Result.Rows[2] := Vec;
end;

function TReader.Plane: TGeoPlane;
begin
  Result.A := Float;
  Result.B := Float;
  Result.C := Float;
  Result.D := Float;
end;

function TReader.Bounds: TGeoBounds;
begin
  Result.Mins := Vec;
  Result.Maxs := Vec;
end;

function TReader.Sphere: TGeoSphere;
begin
  Result.Origin := Vec;
  Result.Radius := Float;
end;

function TReader.Box: TGeoBox;
begin
  Result.Center := Vec;
  Result.Extents := Vec;
  Result.Axis := Mat;
end;

function TReader.Rotation: TIdRotation;
var
  LOrigin, LVector: TIdVec3;
  LAngle: Single;
begin
  LOrigin.X := Float;
  LOrigin.Y := Float;
  LOrigin.Z := Float;
  LVector.X := Float;
  LVector.Y := Float;
  LVector.Z := Float;
  LAngle := Float;
  Result := TIdRotation.Create(LOrigin, LVector, LAngle);
end;

procedure PutF(var ALine: string; const AValue: Single);
begin
  ALine := ALine + ' ' + TIdLibGolden.FloatToken(AValue);
end;

procedure PutI(var ALine: string; const AValue: Integer);
begin
  ALine := ALine + ' ' + IntToStr(AValue);
end;

procedure PutFlag(var ALine: string; const AValue: Boolean);
begin
  if AValue then
    ALine := ALine + ' 1'
  else
    ALine := ALine + ' 0';
end;

procedure PutVec(var ALine: string; const AValue: TGeoVec3);
begin
  PutF(ALine, AValue.X);
  PutF(ALine, AValue.Y);
  PutF(ALine, AValue.Z);
end;

procedure PutMat(var ALine: string; const AValue: TGeoMat3);
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    PutVec(ALine, AValue.Rows[LRow]);
end;

procedure PutPlane(var ALine: string; const AValue: TGeoPlane);
begin
  PutF(ALine, AValue.A);
  PutF(ALine, AValue.B);
  PutF(ALine, AValue.C);
  PutF(ALine, AValue.D);
end;

procedure PutBounds(var ALine: string; const AValue: TGeoBounds);
begin
  PutVec(ALine, AValue.Mins);
  PutVec(ALine, AValue.Maxs);
end;

procedure PutSphere(var ALine: string; const AValue: TGeoSphere);
begin
  PutVec(ALine, AValue.Origin);
  PutF(ALine, AValue.Radius);
end;

procedure PutBox(var ALine: string; const AValue: TGeoBox);
begin
  PutVec(ALine, AValue.Center);
  PutVec(ALine, AValue.Extents);
  PutMat(ALine, AValue.Axis);
end;

function HeadOf(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Pos('|', ALine));
end;

function ComputePlane(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LPlane, LOther, LResult: TGeoPlane;
  LA, LB, LC, LStart, LDir: TGeoVec3;
  LMat: TGeoMat3;
  LOk: Boolean;
  LScale: Single;
begin
  Result := True;
  if AName = 'PL_type' then
  begin
    LPlane := R.Plane;
    PutI(ALine, LPlane.PlaneType);
  end
  else if (AName = 'PL_from3') or (AName = 'PL_fromvecs') then
  begin
    LA := R.Vec;
    LB := R.Vec;
    LC := R.Vec;
    LResult.Zero;
    if AName = 'PL_from3' then
      LOk := LResult.FromPoints(LA, LB, LC)
    else
      LOk := LResult.FromVecs(LA, LB, LC);
    PutFlag(ALine, LOk);
    PutPlane(ALine, LResult);
  end
  else if AName = 'PL_translate' then
  begin
    LPlane := R.Plane;
    PutPlane(ALine, LPlane.Translate(R.Vec));
  end
  else if AName = 'PL_rotate' then
  begin
    LPlane := R.Plane;
    LA := R.Vec;
    LMat := R.Mat;
    PutPlane(ALine, LPlane.Rotate(LA, LMat));
  end
  else if AName = 'PL_line' then
  begin
    LPlane := R.Plane;
    LA := R.Vec;
    LB := R.Vec;
    PutFlag(ALine, LPlane.LineIntersection(LA, LB));
  end
  else if AName = 'PL_ray' then
  begin
    LPlane := R.Plane;
    LA := R.Vec;
    LB := R.Vec;
    LOk := LPlane.RayIntersection(LA, LB, LScale);
    PutFlag(ALine, LOk);
    PutF(ALine, LScale);
  end
  else if AName = 'PL_planeint' then
  begin
    LPlane := R.Plane;
    LOther := R.Plane;
    LOk := LPlane.PlaneIntersection(LOther, LStart, LDir);
    PutFlag(ALine, LOk);
    if LOk then
    begin
      PutVec(ALine, LStart);
      PutVec(ALine, LDir);
    end;
  end
  else if AName = 'PL_fixdeg' then
  begin
    LPlane := R.Plane;
    LOk := LPlane.FixDegeneracies(R.Float);
    PutFlag(ALine, LOk);
    PutPlane(ALine, LPlane);
  end
  else if AName = 'PL_cmp' then
  begin
    LPlane := R.Plane;
    LOther := R.Plane;
    PutFlag(ALine, LPlane.Compare(LOther));
    PutFlag(ALine, LPlane.Compare(LOther, Single(0.25)));
    PutFlag(ALine, LPlane.Compare(LOther, Single(0.25), Single(0.5)));
    PutFlag(ALine, LPlane.Compare(LPlane, Single(0)));
  end
  else
    Result := False;
end;

function ComputeBounds(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LBounds, LOther, LResult: TGeoBounds;
  LA, LB: TGeoVec3;
  LMat: TGeoMat3;
  LPlane: TGeoPlane;
  LScale, LMin, LMax, LEps: Single;
  LIndex, LCount: Integer;
  LOk: Boolean;
  LPoints: array[0..7] of TGeoVec3;
  LList: array of TGeoVec3;
begin
  Result := True;
  if AName = 'B_radius' then
  begin
    LBounds := R.Bounds;
    PutF(ALine, LBounds.GetRadius);
  end
  else if AName = 'B_radiusc' then
  begin
    LBounds := R.Bounds;
    PutF(ALine, LBounds.GetRadius(R.Vec));
  end
  else if AName = 'B_vol' then
  begin
    LBounds := R.Bounds;
    PutF(ALine, LBounds.GetVolume);
  end
  else if AName = 'B_intersect' then
  begin
    LBounds := R.Bounds;
    LOther := R.Bounds;
    PutBounds(ALine, LBounds.Intersect(LOther));
  end
  else if AName = 'B_intersectself' then
  begin
    LBounds := R.Bounds;
    LOther := R.Bounds;
    LBounds.IntersectSelf(LOther);
    PutBounds(ALine, LBounds);
  end
  else if AName = 'B_expand' then
  begin
    LBounds := R.Bounds;
    PutBounds(ALine, LBounds.Expand(R.Float));
  end
  else if AName = 'B_translate' then
  begin
    LBounds := R.Bounds;
    PutBounds(ALine, LBounds.Translate(R.Vec));
  end
  else if AName = 'B_rotate' then
  begin
    LBounds := R.Bounds;
    PutBounds(ALine, LBounds.Rotate(R.Mat));
  end
  else if AName = 'B_planedist' then
  begin
    LBounds := R.Bounds;
    PutF(ALine, LBounds.PlaneDistance(R.Plane));
  end
  else if AName = 'B_planeside' then
  begin
    LBounds := R.Bounds;
    LPlane := R.Plane;
    LEps := R.Float;
    PutI(ALine, LBounds.PlaneSide(LPlane, LEps));
  end
  else if AName = 'B_contains' then
  begin
    LBounds := R.Bounds;
    PutFlag(ALine, LBounds.ContainsPoint(R.Vec));
  end
  else if AName = 'B_intersects' then
  begin
    LBounds := R.Bounds;
    PutFlag(ALine, LBounds.IntersectsBounds(R.Bounds));
  end
  else if AName = 'B_line' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LB := R.Vec;
    PutFlag(ALine, LBounds.LineIntersection(LA, LB));
  end
  else if AName = 'B_ray' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LB := R.Vec;
    LOk := LBounds.RayIntersection(LA, LB, LScale);
    PutFlag(ALine, LOk);
    PutF(ALine, LScale);
  end
  else if AName = 'B_transformed' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LMat := R.Mat;
    LResult.FromTransformedBounds(LBounds, LA, LMat);
    PutBounds(ALine, LResult);
  end
  else if AName = 'B_pointtrans' then
  begin
    LA := R.Vec;
    LB := R.Vec;
    LResult.FromPointTranslation(LA, LB);
    PutBounds(ALine, LResult);
  end
  else if AName = 'B_boundstrans' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LMat := R.Mat;
    LB := R.Vec;
    LResult.FromBoundsTranslation(LBounds, LA, LMat, LB);
    PutBounds(ALine, LResult);
  end
  else if AName = 'B_topoints' then
  begin
    LBounds := R.Bounds;
    LBounds.ToPoints(LPoints);
    for LIndex := 0 to 7 do
      PutVec(ALine, LPoints[LIndex]);
  end
  else if AName = 'B_sphere' then
  begin
    LBounds := R.Bounds;
    PutSphere(ALine, LBounds.ToSphere);
  end
  else if AName = 'B_axisproj' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LBounds.AxisProjection(LA, LMin, LMax);
    PutF(ALine, LMin);
    PutF(ALine, LMax);
  end
  else if AName = 'B_axisproj2' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LMat := R.Mat;
    LB := R.Vec;
    LBounds.AxisProjection(LA, LMat, LB, LMin, LMax);
    PutF(ALine, LMin);
    PutF(ALine, LMax);
  end
  else if AName = 'B_frompoints' then
  begin
    LCount := R.Int;
    SetLength(LList, LCount);
    for LIndex := 0 to LCount - 1 do
      LList[LIndex] := R.Vec;
    LResult.FromPoints(LList);
    PutBounds(ALine, LResult);
  end
  else if AName = 'B_addpoint' then
  begin
    LBounds := R.Bounds;
    LOk := LBounds.AddPoint(R.Vec);
    PutFlag(ALine, LOk);
    PutBounds(ALine, LBounds);
  end
  else if AName = 'B_addbounds' then
  begin
    LBounds := R.Bounds;
    LOk := LBounds.AddBounds(R.Bounds);
    PutFlag(ALine, LOk);
    PutBounds(ALine, LBounds);
  end
  else
  begin
    Result := False;
  end;
end;

function ComputeBoundsRotation(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LBounds: TGeoBounds;
  LA, LB: TGeoVec3;
  LMat: TGeoMat3;
  LRotation: TIdRotation;
begin
  Result := True;
  if AName = 'B_ptrot_arc' then
  begin
    LA := R.Vec;
    LRotation := R.Rotation;
    PutBounds(ALine, TIdBoundsRotation.ForPointRotation(LA, LRotation));
  end
  else if AName = 'B_ptrot' then
  begin
    LA := R.Vec;
    LRotation := R.Rotation;
    PutBounds(ALine, TIdBoundsRotation.FromPointRotation(LA, LRotation));
  end
  else if AName = 'B_boundsrot' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LMat := R.Mat;
    LRotation := R.Rotation;
    LB := LA;
    PutBounds(ALine, TIdBoundsRotation.FromBoundsRotation(LBounds, LB, LMat, LRotation));
  end
  else
    Result := False;
end;

function ComputeSphere(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LSphere, LResult: TGeoSphere;
  LA, LB, LDir: TGeoVec3;
  LPlane: TGeoPlane;
  LScale1, LScale2, LMin, LMax, LEps: Single;
  LOk: Boolean;
  LIndex, LCount: Integer;
  LList: array of TGeoVec3;
  LRotation: TIdRotation;
begin
  Result := True;
  if AName = 'S_addpoint' then
  begin
    LSphere := R.Sphere;
    LOk := LSphere.AddPoint(R.Vec);
    PutFlag(ALine, LOk);
    PutSphere(ALine, LSphere);
  end
  else if AName = 'S_addsphere' then
  begin
    LSphere := R.Sphere;
    LOk := LSphere.AddSphere(R.Sphere);
    PutFlag(ALine, LOk);
    PutSphere(ALine, LSphere);
  end
  else if AName = 'S_planedist' then
  begin
    LSphere := R.Sphere;
    PutF(ALine, LSphere.PlaneDistance(R.Plane));
  end
  else if AName = 'S_planeside' then
  begin
    LSphere := R.Sphere;
    LPlane := R.Plane;
    LEps := R.Float;
    PutI(ALine, LSphere.PlaneSide(LPlane, LEps));
  end
  else if AName = 'S_contains' then
  begin
    LSphere := R.Sphere;
    PutFlag(ALine, LSphere.ContainsPoint(R.Vec));
  end
  else if AName = 'S_intersects' then
  begin
    LSphere := R.Sphere;
    PutFlag(ALine, LSphere.IntersectsSphere(R.Sphere));
  end
  else if AName = 'S_line' then
  begin
    LSphere := R.Sphere;
    LA := R.Vec;
    LB := R.Vec;
    PutFlag(ALine, LSphere.LineIntersection(LA, LB));
  end
  else if AName = 'S_ray' then
  begin
    LSphere := R.Sphere;
    LA := R.Vec;
    LDir := R.Vec;
    LOk := LSphere.RayIntersection(LA, LDir, LScale1, LScale2);
    PutFlag(ALine, LOk);
    if LOk then
    begin
      PutF(ALine, LScale1);
      PutF(ALine, LScale2);
    end;
  end
  else if AName = 'S_frompoints' then
  begin
    LCount := R.Int;
    SetLength(LList, LCount);
    for LIndex := 0 to LCount - 1 do
      LList[LIndex] := R.Vec;
    LResult.FromPoints(LList);
    PutSphere(ALine, LResult);
  end
  else if AName = 'S_pointtrans' then
  begin
    LA := R.Vec;
    LB := R.Vec;
    LResult.FromPointTranslation(LA, LB);
    PutSphere(ALine, LResult);
  end
  else if AName = 'S_spheretrans' then
  begin
    LSphere := R.Sphere;
    LA := R.Vec;
    LB := R.Vec;
    LResult.FromSphereTranslation(LSphere, LA, LB);
    PutSphere(ALine, LResult);
  end
  else if AName = 'S_axisproj' then
  begin
    LSphere := R.Sphere;
    LA := R.Vec;
    LSphere.AxisProjection(LA, LMin, LMax);
    PutF(ALine, LMin);
    PutF(ALine, LMax);
  end
  else if AName = 'S_expand' then
  begin
    LSphere := R.Sphere;
    PutSphere(ALine, LSphere.Expand(R.Float));
  end
  else if AName = 'S_ptrot' then
  begin
    LA := R.Vec;
    LRotation := R.Rotation;
    PutSphere(ALine, TIdBoundsRotation.SphereFromPointRotation(LA, LRotation));
  end
  else if AName = 'S_sphrot' then
  begin
    LSphere := R.Sphere;
    LA := R.Vec;
    LRotation := R.Rotation;
    PutSphere(ALine, TIdBoundsRotation.SphereFromSphereRotation(LSphere, LA, LRotation));
  end
  else
  begin
    Result := False;
  end;
end;

function ComputeBox(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LBox: TGeoBox;
  LA, LB: TGeoVec3;
  LMat: TGeoMat3;
  LPlane: TGeoPlane;
  LBounds, LResult: TGeoBounds;
  LScale1, LScale2, LMin, LMax, LEps: Single;
  LOk: Boolean;
  LIndex, LCount: Integer;
  LPoints: array[0..7] of TGeoVec3;
  LSilhouette: array[0..5] of TGeoVec3;
begin
  Result := True;
  if AName = 'X_addpoint' then
  begin
    LBox := R.Box;
    LOk := LBox.AddPoint(R.Vec);
    PutFlag(ALine, LOk);
    PutBox(ALine, LBox);
  end
  else if AName = 'X_addbox' then
  begin
    LBox := R.Box;
    LOk := LBox.AddBox(R.Box);
    PutFlag(ALine, LOk);
    PutBox(ALine, LBox);
  end
  else if AName = 'X_volume' then
  begin
    LBox := R.Box;
    PutF(ALine, LBox.GetVolume);
  end
  else if AName = 'X_planedist' then
  begin
    LBox := R.Box;
    PutF(ALine, LBox.PlaneDistance(R.Plane));
  end
  else if AName = 'X_planeside' then
  begin
    LBox := R.Box;
    LPlane := R.Plane;
    LEps := R.Float;
    PutI(ALine, LBox.PlaneSide(LPlane, LEps));
  end
  else if AName = 'X_contains' then
  begin
    LBox := R.Box;
    PutFlag(ALine, LBox.ContainsPoint(R.Vec));
  end
  else if AName = 'X_intersects' then
  begin
    LBox := R.Box;
    PutFlag(ALine, LBox.IntersectsBox(R.Box));
  end
  else if AName = 'X_line' then
  begin
    LBox := R.Box;
    LA := R.Vec;
    LB := R.Vec;
    PutFlag(ALine, LBox.LineIntersection(LA, LB));
  end
  else if AName = 'X_ray' then
  begin
    LBox := R.Box;
    LA := R.Vec;
    LB := R.Vec;
    LOk := LBox.RayIntersection(LA, LB, LScale1, LScale2);
    PutFlag(ALine, LOk);
    PutF(ALine, LScale1);
    PutF(ALine, LScale2);
  end
  else if AName = 'X_topoints' then
  begin
    LBox := R.Box;
    LBox.ToPoints(LPoints);
    for LIndex := 0 to 7 do
      PutVec(ALine, LPoints[LIndex]);
  end
  else if AName = 'X_sphere' then
  begin
    LBox := R.Box;
    PutSphere(ALine, LBox.ToSphere);
  end
  else if AName = 'X_axisproj' then
  begin
    LBox := R.Box;
    LA := R.Vec;
    LBox.AxisProjection(LA, LMin, LMax);
    PutF(ALine, LMin);
    PutF(ALine, LMax);
  end
  else if AName = 'X_axisproj2' then
  begin
    LBox := R.Box;
    LMat := R.Mat;
    LBox.AxisProjection(LMat, LResult);
    PutBounds(ALine, LResult);
  end
  else if (AName = 'X_sil') or (AName = 'X_psil') then
  begin
    LBox := R.Box;
    LA := R.Vec;
    if AName = 'X_sil' then
      LCount := LBox.GetProjectionSilhouetteVerts(LA, LSilhouette)
    else
      LCount := LBox.GetParallelProjectionSilhouetteVerts(LA, LSilhouette);
    PutI(ALine, LCount);
    for LIndex := 0 to LCount - 1 do
      PutVec(ALine, LSilhouette[LIndex]);
  end
  else if AName = 'X_frombounds' then
  begin
    LBounds := R.Bounds;
    LA := R.Vec;
    LMat := R.Mat;
    PutBox(ALine, TGeoBox.Make(LBounds, LA, LMat));
  end
  else if AName = 'X_rotate' then
  begin
    LBox := R.Box;
    PutBox(ALine, LBox.Rotate(R.Mat));
  end
  else if AName = 'X_expand' then
  begin
    LBox := R.Box;
    PutBox(ALine, LBox.Expand(R.Float));
  end
  else
  begin
    Result := False;
  end;
end;

// distance in ULPs between two float bit patterns
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

procedure CompareLines(const AExpected, AActual: TStrings; const AMaxUlps: Integer;
  const AAbsTolerance: Single);
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
    Assert.AreEqual(Length(LExpectedTokens), Length(LActualTokens), 'numero di token' + sLineBreak +
      'atteso   ' + AExpected[LLine] + sLineBreak + 'ottenuto ' + AActual[LLine]);
    for LToken := 0 to High(LExpectedTokens) do
    begin
      if (LExpectedTokens[LToken] <> '') and (LExpectedTokens[LToken][1] = '#') then
      begin
        LExpectedBits := Cardinal(StrToInt64('$' + Copy(LExpectedTokens[LToken], 2, 8)));
        LActualBits := Cardinal(StrToInt64('$' + Copy(LActualTokens[LToken], 2, 8)));
        if IsNaNBits(LExpectedBits) and IsNaNBits(LActualBits) then
          Continue;
        // tolerance: AMaxUlps or a relative error of 4e-6 (or the absolute one, for results that
        // come from a cancellation): the C++ is compiled by clang (each float operation rounded,
        // idMath::Sqrt is x * InvSqrt(x)), Delphi keeps an expression in the x87 registers
        if (UlpDistance(LExpectedBits, LActualBits) > AMaxUlps) and
          (Abs(Bits(LActualTokens[LToken]) - Bits(LExpectedTokens[LToken])) >
            Max(AAbsTolerance, 4E-6 * Max(1.0, Abs(Bits(LExpectedTokens[LToken]))))) then
          Assert.Fail(Format('riga %d, token %d: atteso %s, ottenuto %s (%d ULP)' + sLineBreak +
            'atteso   %s' + sLineBreak + 'ottenuto %s',
            [LLine, LToken, LExpectedTokens[LToken], LActualTokens[LToken],
             UlpDistance(LExpectedBits, LActualBits), AExpected[LLine], AActual[LLine]]));
      end
      else if LExpectedTokens[LToken] <> LActualTokens[LToken] then
        Assert.Fail(Format('riga %d, token %d: atteso %s, ottenuto %s' + sLineBreak +
          'atteso   %s' + sLineBreak + 'ottenuto %s',
          [LLine, LToken, LExpectedTokens[LToken], LActualTokens[LToken], AExpected[LLine], AActual[LLine]]));
    end;
  end;
end;

{ TTestGeometryParity }

procedure TTestGeometryParity.Setup;
begin
  // the C++ divides by zero and produces infinities without traps: mask the FPU exceptions
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
  FLines := TStringList.Create;
  FLines.LoadFromFile(TIdLibGolden.DataPath('..\MathCore\geometry.golden.txt'));
end;

procedure TTestGeometryParity.TearDown;
begin
  SetExceptionMask(FOldMask);
  FLines.Free;
end;

procedure TTestGeometryParity.Run(const APrefixes: array of string; const AMaxUlps: Integer;
  const AAbsTolerance: Single);
var
  LIndex, LPrefix: Integer;
  LLine: string;
  LReader: TReader;
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
        if FLines[LIndex].StartsWith(APrefixes[LPrefix] + ' ') then
          LMatch := True;
      if not LMatch then
        Continue;
      LReader.Tokens := FLines[LIndex].Split([' ']);
      LReader.Position := 1;
      LLine := HeadOf(FLines[LIndex]);
      LKnown := ComputePlane(LReader.Tokens[0], LReader, LLine) or ComputeBounds(LReader.Tokens[0], LReader, LLine) or
        ComputeBoundsRotation(LReader.Tokens[0], LReader, LLine) or ComputeSphere(LReader.Tokens[0], LReader, LLine) or
        ComputeBox(LReader.Tokens[0], LReader, LLine);
      Assert.IsTrue(LKnown, 'operazione sconosciuta ' + LReader.Tokens[0]);
      LActual.Add(LLine);
      LExpected.Add(FLines[LIndex]);
    end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden');
    CompareLines(LExpected, LActual, AMaxUlps, AAbsTolerance);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestGeometryParity.IPianiDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['PL_type', 'PL_from3', 'PL_fromvecs', 'PL_translate', 'PL_rotate', 'PL_line', 'PL_ray', 'PL_planeint',
    'PL_fixdeg', 'PL_cmp'], 2, 1E-4);
end;

procedure TTestGeometryParity.IBoundsDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['B_radius', 'B_radiusc', 'B_vol', 'B_intersect', 'B_intersectself', 'B_expand', 'B_translate', 'B_rotate',
    'B_planedist', 'B_planeside', 'B_contains', 'B_intersects', 'B_line', 'B_ray', 'B_transformed', 'B_pointtrans',
    'B_boundstrans', 'B_topoints', 'B_sphere', 'B_axisproj', 'B_axisproj2', 'B_frompoints', 'B_addpoint',
    'B_addbounds'], 2, 1E-4);
end;

procedure TTestGeometryParity.IBoundsInRotazioneDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['B_ptrot_arc', 'B_ptrot', 'B_boundsrot'], 2, 1E-3);
end;

procedure TTestGeometryParity.LeSfereDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['S_addpoint', 'S_addsphere', 'S_planedist', 'S_planeside', 'S_contains', 'S_intersects', 'S_line', 'S_ray',
    'S_frompoints', 'S_pointtrans', 'S_spheretrans', 'S_axisproj', 'S_expand'], 2, 1E-4);
end;

procedure TTestGeometryParity.LeSfereInRotazioneDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['S_ptrot', 'S_sphrot'], 2, 1E-3);
end;

procedure TTestGeometryParity.LeScatoleDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['X_volume', 'X_planedist', 'X_planeside', 'X_contains', 'X_intersects', 'X_line', 'X_ray', 'X_topoints',
    'X_sphere', 'X_axisproj', 'X_axisproj2', 'X_sil', 'X_psil', 'X_frombounds', 'X_rotate', 'X_expand'], 2, 1E-4);
end;

procedure TTestGeometryParity.LeScatoleCheCresconoDovrebberoDareLeStesseRispostePerIlCpp;
begin
  // the new axes come from normalised vectors (idMath::InvSqrt is a table plus two Newton steps,
  // here 1/Sqrt): a few ULP more than elsewhere
  Run(['X_addpoint', 'X_addbox'], 2, 5E-4);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGeometryParity);

end.
