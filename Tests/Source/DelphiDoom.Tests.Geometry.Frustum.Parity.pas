{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the frustum of id Tech 4 (idFrustum) - parity with the }
{  C++ idLib                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Frustum.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real idFrustum of Doom 3 (Tests\Data\Geometry\frustum.golden.txt: 6800
  ///   lines written by Frustum.cpp, Winding.cpp and the idlib it needs compiled with bcc32c on
  ///   the x87, with the inputs on each line: "name inputs | outputs"). Every line is recomputed
  ///   from its own inputs. Discrete answers (flags, sides) must be identical; the floats are
  ///   compared with 2 ULP, or a relative error of 4e-6, or 1e-4 absolute.
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometryFrustumParity = class(TObject)
  private
    FLines: TStringList;
    FOldMask: TArithmeticExceptionMask;
    procedure Run(const APrefixes: array of string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeProprietaDelFrustumDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeTrasformazioniDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IPuntiELePianeDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IlCullingDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeIntersezioniDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LinieERaggiDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeProiezioniDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeProiezioniNelFrustumDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LaCostruzioneEIVincoliDovrebberoDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.IOUtils,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Sphere, DelphiDoom.Geometry.Box,
  DelphiDoom.Geometry.Winding, DelphiDoom.Geometry.Frustum;

type
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
    function Frustum: TGeoFrustum;
    function Winding: TGeoWinding;
  end;

function Bits(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Result := PSingle(@LBits)^;
end;

function BitsOf(const AValue: Single): Cardinal; inline;
begin
  Result := PCardinal(@AValue)^;
end;

function OrderedBits(const ABits: Cardinal): Int64;
begin
  if (ABits and $80000000) <> 0 then
    Result := -Int64(ABits and $7FFFFFFF)
  else
    Result := Int64(ABits);
end;

function UlpDistance(const A, B: Cardinal): Int64;
begin
  Result := System.Abs(OrderedBits(A) - OrderedBits(B));
end;

function IsNaNBits(const ABits: Cardinal): Boolean;
begin
  Result := ((ABits and $7F800000) = $7F800000) and ((ABits and $007FFFFF) <> 0);
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

// the inputs of a frustum are origin, axis, near, far, left and up: the rest comes from SetSize
function TReader.Frustum: TGeoFrustum;
var
  LNear, LFar, LLeft, LUp: Single;
begin
  Result := TGeoFrustum.Make;
  Result.Origin := Vec;
  Result.Axis := Mat;
  LNear := Float;
  LFar := Float;
  LLeft := Float;
  LUp := Float;
  Result.SetSize(LNear, LFar, LLeft, LUp);
end;

function TReader.Winding: TGeoWinding;
var
  LCount, LIndex: Integer;
begin
  Result := TGeoWinding.Create;
  LCount := Int;
  for LIndex := 1 to LCount do
    Result.AddPoint(Vec);
end;

procedure PutF(var ALine: string; const AValue: Single);
begin
  ALine := ALine + ' #' + LowerCase(IntToHex(BitsOf(AValue), 8));
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

procedure PutFrustum(var ALine: string; const AValue: TGeoFrustum);
begin
  PutVec(ALine, AValue.Origin);
  PutMat(ALine, AValue.Axis);
  PutF(ALine, AValue.DNear);
  PutF(ALine, AValue.DFar);
  PutF(ALine, AValue.DLeft);
  PutF(ALine, AValue.DUp);
  PutF(ALine, AValue.InvFar);
end;

function HeadOf(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Pos('|', ALine));
end;

function ComputeBasic(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LFrustum, LOther: TGeoFrustum;
  LPlane: TGeoPlane;
  LVector: TGeoVec3;
  LMat: TGeoMat3;
  LFloat, LEpsilon: Single;
  LPlanes: TGeoFrustumPlanes;
  LPoints: TGeoFrustumPoints;
  LIndex: Integer;
  LMin, LMax: Single;
  LBounds: TGeoBounds;
begin
  Result := True;
  if AName = 'FR_center' then
  begin
    LFrustum := R.Frustum;
    PutVec(ALine, LFrustum.GetCenter);
  end
  else if AName = 'FR_valid' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.IsValid);
  end
  else if AName = 'FR_pyramid' then
  begin
    LFrustum := R.Frustum;
    LFrustum.SetPyramid(LFrustum.DNear, LFrustum.DFar);
    PutFrustum(ALine, LFrustum);
  end
  else if AName = 'FR_movenear' then
  begin
    LFrustum := R.Frustum;
    LFloat := R.Float;
    LFrustum.MoveNearDistance(LFloat);
    PutFrustum(ALine, LFrustum);
  end
  else if AName = 'FR_movefar' then
  begin
    LFrustum := R.Frustum;
    LFloat := R.Float;
    LFrustum.MoveFarDistance(LFloat);
    PutFrustum(ALine, LFrustum);
  end
  else if AName = 'FR_expand' then
  begin
    LFrustum := R.Frustum;
    LFloat := R.Float;
    PutFrustum(ALine, LFrustum.Expand(LFloat));
    LOther := LFrustum;
    LOther.ExpandSelf(LFloat);
    PutFrustum(ALine, LOther);
  end
  else if AName = 'FR_translate' then
  begin
    LFrustum := R.Frustum;
    LVector := R.Vec;
    PutFrustum(ALine, LFrustum.Translate(LVector));
    LOther := LFrustum;
    LOther.TranslateSelf(LVector);
    PutFrustum(ALine, LOther);
  end
  else if AName = 'FR_rotate' then
  begin
    LFrustum := R.Frustum;
    LMat := R.Mat;
    PutFrustum(ALine, LFrustum.Rotate(LMat));
    LOther := LFrustum;
    LOther.RotateSelf(LMat);
    PutFrustum(ALine, LOther);
  end
  else if AName = 'FR_pdist' then
  begin
    LFrustum := R.Frustum;
    LPlane := R.Plane;
    PutF(ALine, LFrustum.PlaneDistance(LPlane));
  end
  else if AName = 'FR_pside' then
  begin
    LFrustum := R.Frustum;
    LPlane := R.Plane;
    LEpsilon := R.Float;
    PutI(ALine, LFrustum.PlaneSide(LPlane, LEpsilon));
  end
  else if AName = 'FR_planes' then
  begin
    LFrustum := R.Frustum;
    LFrustum.ToPlanes(LPlanes);
    for LIndex := 0 to 5 do
      PutPlane(ALine, LPlanes[LIndex]);
  end
  else if AName = 'FR_points' then
  begin
    LFrustum := R.Frustum;
    LFrustum.ToPoints(LPoints);
    for LIndex := 0 to 7 do
      PutVec(ALine, LPoints[LIndex]);
  end
  else if AName = 'FR_axisproj' then
  begin
    LFrustum := R.Frustum;
    LVector := R.Vec;
    LFrustum.AxisProjection(LVector, LMin, LMax);
    PutF(ALine, LMin);
    PutF(ALine, LMax);
  end
  else if AName = 'FR_axisprojmat' then
  begin
    LFrustum := R.Frustum;
    LMat := R.Mat;
    LFrustum.AxisProjection(LMat, LBounds);
    PutBounds(ALine, LBounds);
  end
  else
    Result := False;
end;

function ComputeCull(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LFrustum, LOther: TGeoFrustum;
  LWinding: TGeoWinding;
  LPoint: TGeoVec3;
begin
  Result := True;
  if AName = 'FR_cullpoint' then
  begin
    LFrustum := R.Frustum;
    LPoint := R.Vec;
    PutFlag(ALine, LFrustum.CullPoint(LPoint));
    PutFlag(ALine, LFrustum.ContainsPoint(LPoint));
  end
  else if AName = 'FR_cullbounds' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.CullBounds(R.Bounds));
  end
  else if AName = 'FR_cullbox' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.CullBox(R.Box));
  end
  else if AName = 'FR_cullsphere' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.CullSphere(R.Sphere));
  end
  else if AName = 'FR_cullfrustum' then
  begin
    LFrustum := R.Frustum;
    LOther := R.Frustum;
    PutFlag(ALine, LFrustum.CullFrustum(LOther));
  end
  else if AName = 'FR_cullwinding' then
  begin
    LFrustum := R.Frustum;
    LWinding := R.Winding;
    try
      PutFlag(ALine, LFrustum.CullWinding(LWinding));
    finally
      LWinding.Free;
    end;
  end
  else
    Result := False;
end;

function ComputeIntersection(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LFrustum, LOther: TGeoFrustum;
  LWinding: TGeoWinding;
  LStart, LEnd: TGeoVec3;
  LScale1, LScale2: Single;
  LHit: Boolean;
begin
  Result := True;
  if AName = 'FR_ibounds' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.IntersectsBounds(R.Bounds));
  end
  else if AName = 'FR_ibox' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.IntersectsBox(R.Box));
  end
  else if AName = 'FR_isphere' then
  begin
    LFrustum := R.Frustum;
    PutFlag(ALine, LFrustum.IntersectsSphere(R.Sphere));
  end
  else if AName = 'FR_ifrustum' then
  begin
    LFrustum := R.Frustum;
    LOther := R.Frustum;
    PutFlag(ALine, LFrustum.IntersectsFrustum(LOther));
  end
  else if AName = 'FR_iwinding' then
  begin
    LFrustum := R.Frustum;
    LWinding := R.Winding;
    try
      PutFlag(ALine, LFrustum.IntersectsWinding(LWinding));
    finally
      LWinding.Free;
    end;
  end
  else if AName = 'FR_line' then
  begin
    LFrustum := R.Frustum;
    LStart := R.Vec;
    LEnd := R.Vec;
    PutFlag(ALine, LFrustum.LineIntersection(LStart, LEnd));
  end
  else if AName = 'FR_ray' then
  begin
    LFrustum := R.Frustum;
    LStart := R.Vec;
    LEnd := R.Vec;
    LScale1 := -7;
    LScale2 := -7;
    LHit := LFrustum.RayIntersection(LStart, LEnd, LScale1, LScale2);
    PutFlag(ALine, LHit);
    PutF(ALine, LScale1);
    PutF(ALine, LScale2);
  end
  else
    Result := False;
end;

function ComputeProjection(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LFrustum, LOther: TGeoFrustum;
  LWinding: TGeoWinding;
  LBox: TGeoBox;
  LBounds: TGeoBounds;
  LHit: Boolean;
begin
  Result := True;
  LBounds.Zero;
  if AName = 'FR_pb_bounds' then
  begin
    LFrustum := R.Frustum;
    LHit := LFrustum.ProjectionBounds(R.Bounds, LBounds);
  end
  else if AName = 'FR_pb_box' then
  begin
    LFrustum := R.Frustum;
    LHit := LFrustum.ProjectionBounds(R.Box, LBounds);
  end
  else if AName = 'FR_pb_sphere' then
  begin
    LFrustum := R.Frustum;
    LHit := LFrustum.ProjectionBounds(R.Sphere, LBounds);
  end
  else if AName = 'FR_pb_frustum' then
  begin
    LFrustum := R.Frustum;
    LOther := R.Frustum;
    LHit := LFrustum.ProjectionBounds(LOther, LBounds);
  end
  else if AName = 'FR_pb_winding' then
  begin
    LFrustum := R.Frustum;
    LWinding := R.Winding;
    try
      LHit := LFrustum.ProjectionBounds(LWinding, LBounds);
    finally
      LWinding.Free;
    end;
  end
  else if AName = 'FR_cpb' then
  begin
    LFrustum := R.Frustum;
    LOther := R.Frustum;
    LBox := R.Box;
    LHit := LFrustum.ClippedProjectionBounds(LOther, LBox, LBounds);
  end
  else
  begin
    Result := False;
    Exit;
  end;
  PutFlag(ALine, LHit);
  PutBounds(ALine, LBounds);
end;

function ComputeBuild(const AName: string; var R: TReader; var ALine: string): Boolean;
var
  LFrustum, LOther: TGeoFrustum;
  LBounds: TGeoBounds;
  LBox: TGeoBox;
  LSphere: TGeoSphere;
  LOrigin: TGeoVec3;
  LFar: Single;
  LHit: Boolean;
begin
  Result := True;
  // the reader is called in separate statements: the order of the arguments of a call is not defined
  LFrustum := R.Frustum;
  if AName = 'FR_fromproj_bounds' then
  begin
    LBounds := R.Bounds;
    LOrigin := R.Vec;
    LFar := R.Float;
    LHit := LFrustum.FromProjection(LBounds, LOrigin, LFar);
  end
  else if AName = 'FR_fromproj_box' then
  begin
    LBox := R.Box;
    LOrigin := R.Vec;
    LFar := R.Float;
    LHit := LFrustum.FromProjection(LBox, LOrigin, LFar);
  end
  else if AName = 'FR_fromproj_sphere' then
  begin
    LSphere := R.Sphere;
    LOrigin := R.Vec;
    LFar := R.Float;
    LHit := LFrustum.FromProjection(LSphere, LOrigin, LFar);
  end
  else if AName = 'FR_constrain_bounds' then
    LHit := LFrustum.ConstrainToBounds(R.Bounds)
  else if AName = 'FR_constrain_box' then
    LHit := LFrustum.ConstrainToBox(R.Box)
  else if AName = 'FR_constrain_sphere' then
    LHit := LFrustum.ConstrainToSphere(R.Sphere)
  else if AName = 'FR_constrain_frustum' then
  begin
    LOther := R.Frustum;
    LHit := LFrustum.ConstrainToFrustum(LOther);
  end
  else
  begin
    Result := False;
    Exit;
  end;
  PutFlag(ALine, LHit);
  PutFrustum(ALine, LFrustum);
end;

procedure CompareLines(const AExpected, AActual: TStrings);
const
  MAX_ULPS = 2;
  ABS_TOLERANCE = 1E-4;
  REL_TOLERANCE = 4E-6;
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
        // clang rounds every float operation, Delphi on the x87 keeps an expression in the registers
        if (UlpDistance(LExpectedBits, LActualBits) > MAX_ULPS) and
          (System.Abs(Bits(LActualTokens[LToken]) - Bits(LExpectedTokens[LToken])) >
            Max(ABS_TOLERANCE, REL_TOLERANCE * Max(1.0, System.Abs(Bits(LExpectedTokens[LToken]))))) then
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

{ TTestGeometryFrustumParity }

procedure TTestGeometryFrustumParity.Setup;
begin
  // the C++ divides by zero and produces infinities without traps: mask the FPU exceptions
  FOldMask := SetExceptionMask(exAllArithmeticExceptions);
  FLines := TStringList.Create;
  FLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Geometry\frustum.golden.txt')));
end;

procedure TTestGeometryFrustumParity.TearDown;
begin
  SetExceptionMask(FOldMask);
  FLines.Free;
end;

procedure TTestGeometryFrustumParity.Run(const APrefixes: array of string);
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
      LKnown := ComputeBasic(LReader.Tokens[0], LReader, LLine) or ComputeCull(LReader.Tokens[0], LReader, LLine) or
        ComputeIntersection(LReader.Tokens[0], LReader, LLine) or
        ComputeProjection(LReader.Tokens[0], LReader, LLine) or ComputeBuild(LReader.Tokens[0], LReader, LLine);
      Assert.IsTrue(LKnown, 'operazione sconosciuta ' + LReader.Tokens[0]);
      LActual.Add(LLine);
      LExpected.Add(FLines[LIndex]);
    end;
    Assert.IsTrue(LExpected.Count > 0, 'nessuna riga nel golden');
    CompareLines(LExpected, LActual);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestGeometryFrustumParity.LeProprietaDelFrustumDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_center', 'FR_valid', 'FR_pyramid', 'FR_movenear', 'FR_movefar']);
end;

procedure TTestGeometryFrustumParity.LeTrasformazioniDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_expand', 'FR_translate', 'FR_rotate']);
end;

procedure TTestGeometryFrustumParity.IPuntiELePianeDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_pdist', 'FR_pside', 'FR_planes', 'FR_points', 'FR_axisproj', 'FR_axisprojmat']);
end;

procedure TTestGeometryFrustumParity.IlCullingDovrebbeDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_cullpoint', 'FR_cullbounds', 'FR_cullbox', 'FR_cullsphere', 'FR_cullfrustum', 'FR_cullwinding']);
end;

procedure TTestGeometryFrustumParity.LeIntersezioniDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_ibounds', 'FR_ibox', 'FR_isphere', 'FR_ifrustum', 'FR_iwinding']);
end;

procedure TTestGeometryFrustumParity.LinieERaggiDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_line', 'FR_ray']);
end;

procedure TTestGeometryFrustumParity.LeProiezioniDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_pb_bounds', 'FR_pb_box', 'FR_pb_sphere', 'FR_pb_winding']);
end;

procedure TTestGeometryFrustumParity.LeProiezioniNelFrustumDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_pb_frustum', 'FR_cpb']);
end;

procedure TTestGeometryFrustumParity.LaCostruzioneEIVincoliDovrebberoDareLeStesseRispostePerIlCpp;
begin
  Run(['FR_fromproj_bounds', 'FR_fromproj_box', 'FR_fromproj_sphere', 'FR_constrain_bounds',
    'FR_constrain_box', 'FR_constrain_sphere', 'FR_constrain_frustum']);
end;

end.