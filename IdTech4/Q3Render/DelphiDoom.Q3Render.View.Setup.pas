{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the view         }
{                                                                              }
{  R_RotateForViewer, R_RotateForEntity, SetFarClip, R_SetupProjection and     }
{  R_SetupFrustum of renderer\tr_main.c. Every operation of the original is    }
{  a float operation: each partial result goes through a local Single, so the  }
{  32 bit x87 code does not keep an extended intermediate. Based on the        }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.View.Setup;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>The set up of a view: the modelview matrix, the frustum and the projection</summary>
  TQ3ViewSetup = class sealed
  strict private
    class function RoundedSin(const AAngle: Single): Single; static;
    class function RoundedCos(const AAngle: Single): Single; static;
    class function RoundedSqrt(const AValue: Single): Single; static;
    class function ScaledTan(const AScale, AAngle: Single): Single; static;
    class function Sum4(const A0, B0, A1, B1, A2, B2, A3, B3: Single): Single; static;
    class function Sum3(const A0, B0, A1, B1, A2, B2: Single): Single; static;
    class procedure SetFarClip(var AView: TQ3FrontViewParms; ARdFlags: Integer); static;
  public
    /// <summary>myGlMultMatrix: out = a * b, the matrices are 16 floats in the order of OpenGL</summary>
    class procedure MultiplyMatrices(const A, B: array of Single; var AOut: array of Single); static;
    /// <summary>
    ///   R_RotateForViewer: the orientation of the world (the identity axes, the viewer as origin of the view
    ///   and the model matrix with the flip to the coordinate system of OpenGL); it is also view.World
    /// </summary>
    class procedure RotateForViewer(var AView: TQ3FrontViewParms; out AOrientation: TQ3ViewOrientation); static;
    /// <summary>R_RotateForEntity: a model gets its own orientation, anything else the one of the world</summary>
    class procedure RotateForEntity(const AEntity: TQ3RefEntity; const AView: TQ3FrontViewParms;
      out AOrientation: TQ3ViewOrientation); static;
    /// <summary>R_SetupFrustum: the four planes (left, right, bottom, top) through the viewer</summary>
    class procedure SetupFrustum(var AView: TQ3FrontViewParms); static;
    /// <summary>
    ///   R_SetupProjection: SetFarClip from the bounds the world has marked, then the matrix; the field of view
    ///   is the one of the refdef
    /// </summary>
    class procedure SetupProjection(var AView: TQ3FrontViewParms; const ARefDef: TQ3RefDef; AZNear: Single); static;
    /// <summary>The identity orientation with the viewer in the origin (Com_Memset and the three ones)</summary>
    class function IdentityOrientation: TQ3ViewOrientation; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Collision.Q3.Math;

const
  // s_flipMatrix: from the system of the game (looking down X) to the one of OpenGL (looking down -Z)
  ViewPi: Single = 3.14159265358979323846;
  FlipMatrix: array[0..15] of Single = (0, 0, -1, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1);

// sin, cos, tan and sqrt of the C library work on a double: the result is a double that is then stored in a float.
// A double local makes the 32 bit x87 code round to a double first, as the C does
class function TQ3ViewSetup.RoundedSin(const AAngle: Single): Single;
var
  LValue: Double;
begin
  LValue := Sin(Double(AAngle));
  Result := LValue;
end;

class function TQ3ViewSetup.RoundedCos(const AAngle: Single): Single;
var
  LValue: Double;
begin
  LValue := Cos(Double(AAngle));
  Result := LValue;
end;

class function TQ3ViewSetup.RoundedSqrt(const AValue: Single): Single;
var
  LValue: Double;
begin
  LValue := Sqrt(Double(AValue));
  Result := LValue;
end;

class function TQ3ViewSetup.ScaledTan(const AScale, AAngle: Single): Single;
var
  LTangent, LProduct: Double;
begin
  // zNear * tan(angle): a float times a double is a double, then it goes to a float
  LTangent := Tan(Double(AAngle));
  LProduct := AScale * LTangent;
  Result := LProduct;
end;

class function TQ3ViewSetup.Sum4(const A0, B0, A1, B1, A2, B2, A3, B3: Single): Single;
var
  LFirst, LSecond, LThird, LFourth: Single;
begin
  LFirst := A0 * B0;
  LSecond := A1 * B1;
  Result := LFirst + LSecond;
  LThird := A2 * B2;
  Result := Result + LThird;
  LFourth := A3 * B3;
  Result := Result + LFourth;
end;

class function TQ3ViewSetup.Sum3(const A0, B0, A1, B1, A2, B2: Single): Single;
var
  LFirst, LSecond, LThird: Single;
begin
  LFirst := A0 * B0;
  LSecond := A1 * B1;
  Result := LFirst + LSecond;
  LThird := A2 * B2;
  Result := Result + LThird;
end;

class procedure TQ3ViewSetup.MultiplyMatrices(const A, B: array of Single; var AOut: array of Single);
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to 3 do
    for LColumn := 0 to 3 do
      AOut[LRow * 4 + LColumn] := Sum4(A[LRow * 4 + 0], B[0 * 4 + LColumn], A[LRow * 4 + 1], B[1 * 4 + LColumn],
        A[LRow * 4 + 2], B[2 * 4 + LColumn], A[LRow * 4 + 3], B[3 * 4 + LColumn]);
end;

class function TQ3ViewSetup.IdentityOrientation: TQ3ViewOrientation;
begin
  Result := Default(TQ3ViewOrientation);
  Result.Axis[0][0] := 1;
  Result.Axis[1][1] := 1;
  Result.Axis[2][2] := 1;
end;

class procedure TQ3ViewSetup.RotateForViewer(var AView: TQ3FrontViewParms; out AOrientation: TQ3ViewOrientation);
var
  LViewer: array[0..15] of Single;
  LOrigin: TQ3Vec3;
begin
  AOrientation := IdentityOrientation;
  AOrientation.ViewOrigin := AView.Orientation.Origin;
  LOrigin := AView.Orientation.Origin;

  LViewer[0] := AView.Orientation.Axis[0][0];
  LViewer[4] := AView.Orientation.Axis[0][1];
  LViewer[8] := AView.Orientation.Axis[0][2];
  LViewer[12] := Sum3(-LOrigin[0], LViewer[0], -LOrigin[1], LViewer[4], -LOrigin[2], LViewer[8]);

  LViewer[1] := AView.Orientation.Axis[1][0];
  LViewer[5] := AView.Orientation.Axis[1][1];
  LViewer[9] := AView.Orientation.Axis[1][2];
  LViewer[13] := Sum3(-LOrigin[0], LViewer[1], -LOrigin[1], LViewer[5], -LOrigin[2], LViewer[9]);

  LViewer[2] := AView.Orientation.Axis[2][0];
  LViewer[6] := AView.Orientation.Axis[2][1];
  LViewer[10] := AView.Orientation.Axis[2][2];
  LViewer[14] := Sum3(-LOrigin[0], LViewer[2], -LOrigin[1], LViewer[6], -LOrigin[2], LViewer[10]);

  LViewer[3] := 0;
  LViewer[7] := 0;
  LViewer[11] := 0;
  LViewer[15] := 1;
  MultiplyMatrices(LViewer, FlipMatrix, AOrientation.ModelMatrix);
  AView.World := AOrientation;
end;

class procedure TQ3ViewSetup.RotateForEntity(const AEntity: TQ3RefEntity; const AView: TQ3FrontViewParms;
  out AOrientation: TQ3ViewOrientation);
var
  LMatrix: array[0..15] of Single;
  LDelta: TQ3Vec3;
  LAxisLength, LSquared, LTerm: Single;
  LAxis: Integer;
begin
  if AEntity.ReType <> RT_MODEL then
  begin
    AOrientation := AView.World;
    Exit;
  end;
  AOrientation := Default(TQ3ViewOrientation);
  AOrientation.Origin := AEntity.Origin;
  for LAxis := 0 to 2 do
    AOrientation.Axis[LAxis] := AEntity.Axis[LAxis];

  LMatrix[0] := AOrientation.Axis[0][0];
  LMatrix[4] := AOrientation.Axis[1][0];
  LMatrix[8] := AOrientation.Axis[2][0];
  LMatrix[12] := AOrientation.Origin[0];
  LMatrix[1] := AOrientation.Axis[0][1];
  LMatrix[5] := AOrientation.Axis[1][1];
  LMatrix[9] := AOrientation.Axis[2][1];
  LMatrix[13] := AOrientation.Origin[1];
  LMatrix[2] := AOrientation.Axis[0][2];
  LMatrix[6] := AOrientation.Axis[1][2];
  LMatrix[10] := AOrientation.Axis[2][2];
  LMatrix[14] := AOrientation.Origin[2];
  LMatrix[3] := 0;
  LMatrix[7] := 0;
  LMatrix[11] := 0;
  LMatrix[15] := 1;
  MultiplyMatrices(LMatrix, AView.World.ModelMatrix, AOrientation.ModelMatrix);

  // the viewer in the space of the model: needed for fog, specular and environment mapping
  LDelta[0] := AView.Orientation.Origin[0] - AOrientation.Origin[0];
  LDelta[1] := AView.Orientation.Origin[1] - AOrientation.Origin[1];
  LDelta[2] := AView.Orientation.Origin[2] - AOrientation.Origin[2];
  if AEntity.NonNormalizedAxes <> 0 then
  begin
    // VectorLength: sqrt of the sum of the squares
    LSquared := Sum3(AEntity.Axis[0][0], AEntity.Axis[0][0], AEntity.Axis[0][1], AEntity.Axis[0][1],
      AEntity.Axis[0][2], AEntity.Axis[0][2]);
    LAxisLength := RoundedSqrt(LSquared);
    if LAxisLength = 0 then
      LAxisLength := 0
    else
      LAxisLength := 1.0 / LAxisLength;
  end
  else
    LAxisLength := 1.0;
  LTerm := Sum3(LDelta[0], AOrientation.Axis[0][0], LDelta[1], AOrientation.Axis[0][1], LDelta[2],
    AOrientation.Axis[0][2]);
  AOrientation.ViewOrigin[0] := LTerm * LAxisLength;
  LTerm := Sum3(LDelta[0], AOrientation.Axis[1][0], LDelta[1], AOrientation.Axis[1][1], LDelta[2],
    AOrientation.Axis[1][2]);
  AOrientation.ViewOrigin[1] := LTerm * LAxisLength;
  LTerm := Sum3(LDelta[0], AOrientation.Axis[2][0], LDelta[1], AOrientation.Axis[2][1], LDelta[2],
    AOrientation.Axis[2][2]);
  AOrientation.ViewOrigin[2] := LTerm * LAxisLength;
end;

class procedure TQ3ViewSetup.SetupFrustum(var AView: TQ3FrontViewParms);
var
  LIndex: Integer;
  LAngle, LSine, LCosine, LHalf: Single;
  LNormal: TQ3Vec3;
  LTerm: Single;

  procedure MakePlane(APlane, ASideAxis: Integer; ASign: Single);
  var
    LComponent: Integer;
    LScaled, LSide: Single;
  begin
    for LComponent := 0 to 2 do
    begin
      LScaled := AView.Orientation.Axis[0][LComponent] * LSine;
      LSide := AView.Orientation.Axis[ASideAxis][LComponent] * (ASign * LCosine);
      LNormal[LComponent] := LScaled + LSide;
    end;
    AView.Frustum[APlane].Normal := LNormal;
  end;

begin
  LHalf := 0.5;
  // ang = fovX / 180 * M_PI * 0.5f, with M_PI a float constant
  LAngle := AView.FovX / 180;
  LAngle := LAngle * ViewPi;
  LAngle := LAngle * LHalf;
  LSine := RoundedSin(LAngle);
  LCosine := RoundedCos(LAngle);
  MakePlane(0, 1, 1);
  MakePlane(1, 1, -1);

  LAngle := AView.FovY / 180;
  LAngle := LAngle * ViewPi;
  LAngle := LAngle * LHalf;
  LSine := RoundedSin(LAngle);
  LCosine := RoundedCos(LAngle);
  MakePlane(2, 2, 1);
  MakePlane(3, 2, -1);

  for LIndex := 0 to 3 do
  begin
    AView.Frustum[LIndex].PlaneType := Q3_PLANE_NON_AXIAL;
    LTerm := Sum3(AView.Orientation.Origin[0], AView.Frustum[LIndex].Normal[0], AView.Orientation.Origin[1],
      AView.Frustum[LIndex].Normal[1], AView.Orientation.Origin[2], AView.Frustum[LIndex].Normal[2]);
    AView.Frustum[LIndex].Dist := LTerm;
    AView.Frustum[LIndex].SignBits := TQ3Math.SignBitsOf(AView.Frustum[LIndex].Normal);
  end;
end;

class procedure TQ3ViewSetup.SetFarClip(var AView: TQ3FrontViewParms; ARdFlags: Integer);
var
  LIndex, LAxis: Integer;
  LCorner, LVector: TQ3Vec3;
  LDistance, LFarthest: Single;
begin
  // not rendering the world (icons, menus, etc): a far plane at two thousand units
  if (ARdFlags and RDF_NOWORLDMODEL) <> 0 then
  begin
    AView.ZFar := 2048;
    Exit;
  end;
  LFarthest := 0;
  for LIndex := 0 to 7 do
  begin
    for LAxis := 0 to 2 do
      if (LIndex and (1 shl LAxis)) <> 0 then
        LCorner[LAxis] := AView.VisBounds[0][LAxis]
      else
        LCorner[LAxis] := AView.VisBounds[1][LAxis];
    for LAxis := 0 to 2 do
      LVector[LAxis] := LCorner[LAxis] - AView.Orientation.Origin[LAxis];
    LDistance := Sum3(LVector[0], LVector[0], LVector[1], LVector[1], LVector[2], LVector[2]);
    if LDistance > LFarthest then
      LFarthest := LDistance;
  end;
  AView.ZFar := RoundedSqrt(LFarthest);
end;

class procedure TQ3ViewSetup.SetupProjection(var AView: TQ3FrontViewParms; const ARefDef: TQ3RefDef; AZNear: Single);
var
  LXMin, LXMax, LYMin, LYMax, LWidth, LHeight, LDepth, LZFar, LAngle, LTerm, LNumerator: Single;
  LHalf: Single;
begin
  SetFarClip(AView, ARefDef.RdFlags);
  LZFar := AView.ZFar;
  LHalf := 360.0;

  LAngle := ARefDef.FovY * ViewPi;
  LAngle := LAngle / LHalf;
  LYMax := ScaledTan(AZNear, LAngle);
  LYMin := -LYMax;
  LAngle := ARefDef.FovX * ViewPi;
  LAngle := LAngle / LHalf;
  LXMax := ScaledTan(AZNear, LAngle);
  LXMin := -LXMax;

  LWidth := LXMax - LXMin;
  LHeight := LYMax - LYMin;
  LDepth := LZFar - AZNear;

  LTerm := 2 * AZNear;
  AView.ProjectionMatrix[0] := LTerm / LWidth;
  AView.ProjectionMatrix[4] := 0;
  LTerm := LXMax + LXMin;
  AView.ProjectionMatrix[8] := LTerm / LWidth;
  AView.ProjectionMatrix[12] := 0;

  AView.ProjectionMatrix[1] := 0;
  LTerm := 2 * AZNear;
  AView.ProjectionMatrix[5] := LTerm / LHeight;
  LTerm := LYMax + LYMin;
  AView.ProjectionMatrix[9] := LTerm / LHeight;
  AView.ProjectionMatrix[13] := 0;

  AView.ProjectionMatrix[2] := 0;
  AView.ProjectionMatrix[6] := 0;
  LTerm := LZFar + AZNear;
  LTerm := -LTerm;
  AView.ProjectionMatrix[10] := LTerm / LDepth;
  LNumerator := -2 * LZFar;
  LNumerator := LNumerator * AZNear;
  AView.ProjectionMatrix[14] := LNumerator / LDepth;

  AView.ProjectionMatrix[3] := 0;
  AView.ProjectionMatrix[7] := 0;
  AView.ProjectionMatrix[11] := -1;
  AView.ProjectionMatrix[15] := 0;
end;

end.
