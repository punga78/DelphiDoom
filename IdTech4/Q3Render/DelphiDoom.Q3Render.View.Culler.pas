{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - culling against  }
{  the frustum                                                                 }
{                                                                              }
{  R_CullLocalBox, R_CullPointAndRadius, R_CullLocalPointAndRadius and         }
{  R_LocalPointToWorld of renderer\tr_main.c. Based on the Quake III Arena     }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.View.Culler;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>
  ///   Tests boxes and spheres against the four planes of the frustum of the view. The orientation is tr.or: the
  ///   one of the entity that is being added (the one of the world for the world itself)
  /// </summary>
  TQ3ViewCuller = class
  strict private
    FFrustum: array[0..3] of TQ3Plane;
    FOrientation: TQ3ViewOrientation;
    FNoCull: Boolean;
  public
    constructor Create(ANoCull: Boolean);
    /// <summary>The frustum of a view (viewParms.frustum) and tr.or</summary>
    procedure SetView(const AView: TQ3FrontViewParms; const AOrientation: TQ3ViewOrientation);
    procedure SetOrientation(const AOrientation: TQ3ViewOrientation);
    property Orientation: TQ3ViewOrientation read FOrientation;
    /// <summary>viewParms.frustum[AIndex]</summary>
    function FrustumPlane(AIndex: Integer): TQ3Plane;
    /// <summary>R_LocalPointToWorld</summary>
    function LocalPointToWorld(const ALocal: TQ3Vec3): TQ3Vec3;
    /// <summary>R_CullLocalBox: CULL_IN, CULL_CLIP or CULL_OUT for the box of two corners in the local space</summary>
    function CullLocalBox(const AMins, AMaxs: TQ3Vec3): Integer;
    /// <summary>R_CullPointAndRadius</summary>
    function CullPointAndRadius(const APoint: TQ3Vec3; ARadius: Single): Integer;
    /// <summary>R_CullLocalPointAndRadius</summary>
    function CullLocalPointAndRadius(const APoint: TQ3Vec3; ARadius: Single): Integer;
  end;

implementation

constructor TQ3ViewCuller.Create(ANoCull: Boolean);
begin
  inherited Create;
  FNoCull := ANoCull;
end;

procedure TQ3ViewCuller.SetView(const AView: TQ3FrontViewParms; const AOrientation: TQ3ViewOrientation);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    FFrustum[LIndex] := AView.Frustum[LIndex];
  FOrientation := AOrientation;
end;

procedure TQ3ViewCuller.SetOrientation(const AOrientation: TQ3ViewOrientation);
begin
  FOrientation := AOrientation;
end;

function TQ3ViewCuller.FrustumPlane(AIndex: Integer): TQ3Plane;
begin
  Result := FFrustum[AIndex];
end;

function TQ3ViewCuller.LocalPointToWorld(const ALocal: TQ3Vec3): TQ3Vec3;
var
  LAxis: Integer;
  LFirst, LSecond, LThird, LSum: Single;
begin
  for LAxis := 0 to 2 do
  begin
    LFirst := ALocal[0] * FOrientation.Axis[0][LAxis];
    LSecond := ALocal[1] * FOrientation.Axis[1][LAxis];
    LSum := LFirst + LSecond;
    LThird := ALocal[2] * FOrientation.Axis[2][LAxis];
    LSum := LSum + LThird;
    Result[LAxis] := LSum + FOrientation.Origin[LAxis];
  end;
end;

function TQ3ViewCuller.CullLocalBox(const AMins, AMaxs: TQ3Vec3): Integer;
var
  LTransformed: array[0..7] of TQ3Vec3;
  LCorner, LAxis, LPlane, LPoint: Integer;
  LValue: TQ3Vec3;
  LFront, LBack, LAnyBack: Boolean;
  LTerm, LDot, LX, LY, LZ: Single;
begin
  if FNoCull then
    Exit(CULL_CLIP);
  // into world space: origin + x * axis0 + y * axis1 + z * axis2, one VectorMA at a time
  for LCorner := 0 to 7 do
  begin
    if (LCorner and 1) <> 0 then
      LValue[0] := AMaxs[0]
    else
      LValue[0] := AMins[0];
    if ((LCorner shr 1) and 1) <> 0 then
      LValue[1] := AMaxs[1]
    else
      LValue[1] := AMins[1];
    if ((LCorner shr 2) and 1) <> 0 then
      LValue[2] := AMaxs[2]
    else
      LValue[2] := AMins[2];
    LTransformed[LCorner] := FOrientation.Origin;
    for LAxis := 0 to 2 do
      for LPoint := 0 to 2 do
      begin
        LTerm := LValue[LAxis] * FOrientation.Axis[LAxis][LPoint];
        LTransformed[LCorner][LPoint] := LTransformed[LCorner][LPoint] + LTerm;
      end;
  end;
  LAnyBack := False;
  for LPlane := 0 to 3 do
  begin
    LFront := False;
    LBack := False;
    for LPoint := 0 to 7 do
    begin
      LX := LTransformed[LPoint][0] * FFrustum[LPlane].Normal[0];
      LY := LTransformed[LPoint][1] * FFrustum[LPlane].Normal[1];
      LDot := LX + LY;
      LZ := LTransformed[LPoint][2] * FFrustum[LPlane].Normal[2];
      LDot := LDot + LZ;
      if LDot > FFrustum[LPlane].Dist then
      begin
        LFront := True;
        if LBack then
          Break;
      end
      else
        LBack := True;
    end;
    if not LFront then
      Exit(CULL_OUT);
    if LBack then
      LAnyBack := True;
  end;
  if not LAnyBack then
    Exit(CULL_IN);
  Result := CULL_CLIP;
end;

function TQ3ViewCuller.CullPointAndRadius(const APoint: TQ3Vec3; ARadius: Single): Integer;
var
  LPlane: Integer;
  LDist, LX, LY, LZ, LNegative: Single;
  LMightBeClipped: Boolean;
begin
  if FNoCull then
    Exit(CULL_CLIP);
  LMightBeClipped := False;
  LNegative := -ARadius;
  for LPlane := 0 to 3 do
  begin
    LX := APoint[0] * FFrustum[LPlane].Normal[0];
    LY := APoint[1] * FFrustum[LPlane].Normal[1];
    LDist := LX + LY;
    LZ := APoint[2] * FFrustum[LPlane].Normal[2];
    LDist := LDist + LZ;
    LDist := LDist - FFrustum[LPlane].Dist;
    if LDist < LNegative then
      Exit(CULL_OUT)
    else if LDist <= ARadius then
      LMightBeClipped := True;
  end;
  if LMightBeClipped then
    Exit(CULL_CLIP);
  Result := CULL_IN;
end;

function TQ3ViewCuller.CullLocalPointAndRadius(const APoint: TQ3Vec3; ARadius: Single): Integer;
begin
  Result := CullPointAndRadius(LocalPointToWorld(APoint), ARadius);
end;

end.
