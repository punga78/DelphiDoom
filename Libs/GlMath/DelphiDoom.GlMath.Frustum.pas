{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL math library - the view frustum                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlMath.Frustum;

interface

uses
  DelphiDoom.GlMath.Types,
  DelphiDoom.GlMath.Intf;

type
  /// <summary>
  ///   The old gl_frustum without the calls to OpenGL: the planes come from the matrices that the
  ///   caller gives. The expressions are the old ones, so at 32 bit the results have the same bits
  ///   (the FPU keeps the intermediate values in Extended); at 64 bit the intermediate values are
  ///   Single and the last bit of a plane may differ.
  /// </summary>
  TGlFrustum = class(TInterfacedObject, IGlFrustum)
  strict private
    FPlanes: array[0..GLMATH_FRUSTUM_SIDES - 1, 0..3] of Single;
    procedure NormalizePlane(const ASide: Integer);
  public
    procedure Calculate(const AProjection, AModelView: TGlMatrix4);
    function GetPlane(const ASide: TGlFrustumSide; const AIndex: Integer): Single;
    function ContainsPoint(const AX, AY, AZ: Single): Boolean;
    function ContainsSphere(const AX, AY, AZ, ARadius: Single): Boolean;
    function ContainsBox(const AX, AY, AZ, ASizeX, ASizeY, ASizeZ: Single): Boolean;
    function ContainsCube(const AX, AY, AZ, ASize: Single): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TGlFrustum }

procedure TGlFrustum.NormalizePlane(const ASide: Integer);
var
  LMagnitude: Single;
begin
  LMagnitude := Sqrt(FPlanes[ASide][0] * FPlanes[ASide][0] +
                     FPlanes[ASide][1] * FPlanes[ASide][1] +
                     FPlanes[ASide][2] * FPlanes[ASide][2]);
  FPlanes[ASide][0] := FPlanes[ASide][0] / LMagnitude;
  FPlanes[ASide][1] := FPlanes[ASide][1] / LMagnitude;
  FPlanes[ASide][2] := FPlanes[ASide][2] / LMagnitude;
  FPlanes[ASide][3] := FPlanes[ASide][3] / LMagnitude;
end;

procedure TGlFrustum.Calculate(const AProjection, AModelView: TGlMatrix4);
var
  LClip: array[0..15] of Single;
begin
  // the model view matrix times the projection matrix gives the clipping planes
  LClip[ 0] := AModelView[ 0] * AProjection[ 0] + AModelView[ 1] * AProjection[ 4] + AModelView[ 2] * AProjection[ 8] + AModelView[ 3] * AProjection[12];
  LClip[ 1] := AModelView[ 0] * AProjection[ 1] + AModelView[ 1] * AProjection[ 5] + AModelView[ 2] * AProjection[ 9] + AModelView[ 3] * AProjection[13];
  LClip[ 2] := AModelView[ 0] * AProjection[ 2] + AModelView[ 1] * AProjection[ 6] + AModelView[ 2] * AProjection[10] + AModelView[ 3] * AProjection[14];
  LClip[ 3] := AModelView[ 0] * AProjection[ 3] + AModelView[ 1] * AProjection[ 7] + AModelView[ 2] * AProjection[11] + AModelView[ 3] * AProjection[15];

  LClip[ 4] := AModelView[ 4] * AProjection[ 0] + AModelView[ 5] * AProjection[ 4] + AModelView[ 6] * AProjection[ 8] + AModelView[ 7] * AProjection[12];
  LClip[ 5] := AModelView[ 4] * AProjection[ 1] + AModelView[ 5] * AProjection[ 5] + AModelView[ 6] * AProjection[ 9] + AModelView[ 7] * AProjection[13];
  LClip[ 6] := AModelView[ 4] * AProjection[ 2] + AModelView[ 5] * AProjection[ 6] + AModelView[ 6] * AProjection[10] + AModelView[ 7] * AProjection[14];
  LClip[ 7] := AModelView[ 4] * AProjection[ 3] + AModelView[ 5] * AProjection[ 7] + AModelView[ 6] * AProjection[11] + AModelView[ 7] * AProjection[15];

  LClip[ 8] := AModelView[ 8] * AProjection[ 0] + AModelView[ 9] * AProjection[ 4] + AModelView[10] * AProjection[ 8] + AModelView[11] * AProjection[12];
  LClip[ 9] := AModelView[ 8] * AProjection[ 1] + AModelView[ 9] * AProjection[ 5] + AModelView[10] * AProjection[ 9] + AModelView[11] * AProjection[13];
  LClip[10] := AModelView[ 8] * AProjection[ 2] + AModelView[ 9] * AProjection[ 6] + AModelView[10] * AProjection[10] + AModelView[11] * AProjection[14];
  LClip[11] := AModelView[ 8] * AProjection[ 3] + AModelView[ 9] * AProjection[ 7] + AModelView[10] * AProjection[11] + AModelView[11] * AProjection[15];

  LClip[12] := AModelView[12] * AProjection[ 0] + AModelView[13] * AProjection[ 4] + AModelView[14] * AProjection[ 8] + AModelView[15] * AProjection[12];
  LClip[13] := AModelView[12] * AProjection[ 1] + AModelView[13] * AProjection[ 5] + AModelView[14] * AProjection[ 9] + AModelView[15] * AProjection[13];
  LClip[14] := AModelView[12] * AProjection[ 2] + AModelView[13] * AProjection[ 6] + AModelView[14] * AProjection[10] + AModelView[15] * AProjection[14];
  LClip[15] := AModelView[12] * AProjection[ 3] + AModelView[13] * AProjection[ 7] + AModelView[14] * AProjection[11] + AModelView[15] * AProjection[15];

  // right side
  FPlanes[Ord(fsRight)][0] := LClip[ 3] - LClip[ 0];
  FPlanes[Ord(fsRight)][1] := LClip[ 7] - LClip[ 4];
  FPlanes[Ord(fsRight)][2] := LClip[11] - LClip[ 8];
  FPlanes[Ord(fsRight)][3] := LClip[15] - LClip[12];
  NormalizePlane(Ord(fsRight));

  // left side
  FPlanes[Ord(fsLeft)][0] := LClip[ 3] + LClip[ 0];
  FPlanes[Ord(fsLeft)][1] := LClip[ 7] + LClip[ 4];
  FPlanes[Ord(fsLeft)][2] := LClip[11] + LClip[ 8];
  FPlanes[Ord(fsLeft)][3] := LClip[15] + LClip[12];
  NormalizePlane(Ord(fsLeft));

  // bottom side
  FPlanes[Ord(fsBottom)][0] := LClip[ 3] + LClip[ 1];
  FPlanes[Ord(fsBottom)][1] := LClip[ 7] + LClip[ 5];
  FPlanes[Ord(fsBottom)][2] := LClip[11] + LClip[ 9];
  FPlanes[Ord(fsBottom)][3] := LClip[15] + LClip[13];
  NormalizePlane(Ord(fsBottom));

  // top side
  FPlanes[Ord(fsTop)][0] := LClip[ 3] - LClip[ 1];
  FPlanes[Ord(fsTop)][1] := LClip[ 7] - LClip[ 5];
  FPlanes[Ord(fsTop)][2] := LClip[11] - LClip[ 9];
  FPlanes[Ord(fsTop)][3] := LClip[15] - LClip[13];
  NormalizePlane(Ord(fsTop));

  // back side
  FPlanes[Ord(fsBack)][0] := LClip[ 3] - LClip[ 2];
  FPlanes[Ord(fsBack)][1] := LClip[ 7] - LClip[ 6];
  FPlanes[Ord(fsBack)][2] := LClip[11] - LClip[10];
  FPlanes[Ord(fsBack)][3] := LClip[15] - LClip[14];
  NormalizePlane(Ord(fsBack));

  // front side
  FPlanes[Ord(fsFront)][0] := LClip[ 3] + LClip[ 2];
  FPlanes[Ord(fsFront)][1] := LClip[ 7] + LClip[ 6];
  FPlanes[Ord(fsFront)][2] := LClip[11] + LClip[10];
  FPlanes[Ord(fsFront)][3] := LClip[15] + LClip[14];
  NormalizePlane(Ord(fsFront));
end;

function TGlFrustum.GetPlane(const ASide: TGlFrustumSide; const AIndex: Integer): Single;
begin
  if (AIndex < 0) or (AIndex > 3) then
    raise EGlMathException.CreateFmt(SGlMathInvalidFrustumIndex, [AIndex]);
  Result := FPlanes[Ord(ASide)][AIndex];
end;

function TGlFrustum.ContainsPoint(const AX, AY, AZ: Single): Boolean;
var
  LSide: Integer;
begin
  for LSide := 0 to GLMATH_FRUSTUM_SIDES - 1 do
    // the point is behind a side of the frustum: it is not inside
    if FPlanes[LSide][0] * AX + FPlanes[LSide][1] * AY + FPlanes[LSide][2] * AZ + FPlanes[LSide][3] <= 0 then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

function TGlFrustum.ContainsSphere(const AX, AY, AZ, ARadius: Single): Boolean;
var
  LSide: Integer;
begin
  for LSide := 0 to GLMATH_FRUSTUM_SIDES - 1 do
    if FPlanes[LSide][0] * AX + FPlanes[LSide][1] * AY + FPlanes[LSide][2] * AZ + FPlanes[LSide][3] <= -ARadius then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

function TGlFrustum.ContainsBox(const AX, AY, AZ, ASizeX, ASizeY, ASizeZ: Single): Boolean;
var
  LSide: Integer;
begin
  for LSide := 0 to GLMATH_FRUSTUM_SIDES - 1 do
  begin
    if FPlanes[LSide][0] * AX + FPlanes[LSide][1] * AY + FPlanes[LSide][2] * AZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * ASizeX + FPlanes[LSide][1] * AY + FPlanes[LSide][2] * AZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * AX + FPlanes[LSide][1] * ASizeY + FPlanes[LSide][2] * AZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * ASizeX + FPlanes[LSide][1] * ASizeY + FPlanes[LSide][2] * AZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * AX + FPlanes[LSide][1] * AY + FPlanes[LSide][2] * ASizeZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * ASizeX + FPlanes[LSide][1] * AY + FPlanes[LSide][2] * ASizeZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * AX + FPlanes[LSide][1] * ASizeY + FPlanes[LSide][2] * ASizeZ + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * ASizeX + FPlanes[LSide][1] * ASizeY + FPlanes[LSide][2] * ASizeZ + FPlanes[LSide][3] > 0 then
      Continue;

    // no corner is in front of this plane: the box is not in the frustum
    Result := False;
    Exit;
  end;
  Result := True;
end;

function TGlFrustum.ContainsCube(const AX, AY, AZ, ASize: Single): Boolean;
var
  LSide: Integer;
begin
  for LSide := 0 to GLMATH_FRUSTUM_SIDES - 1 do
  begin
    if FPlanes[LSide][0] * (AX - ASize) + FPlanes[LSide][1] * (AY - ASize) + FPlanes[LSide][2] * (AZ - ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX + ASize) + FPlanes[LSide][1] * (AY - ASize) + FPlanes[LSide][2] * (AZ - ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX - ASize) + FPlanes[LSide][1] * (AY + ASize) + FPlanes[LSide][2] * (AZ - ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX + ASize) + FPlanes[LSide][1] * (AY + ASize) + FPlanes[LSide][2] * (AZ - ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX - ASize) + FPlanes[LSide][1] * (AY - ASize) + FPlanes[LSide][2] * (AZ + ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX + ASize) + FPlanes[LSide][1] * (AY - ASize) + FPlanes[LSide][2] * (AZ + ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX - ASize) + FPlanes[LSide][1] * (AY + ASize) + FPlanes[LSide][2] * (AZ + ASize) + FPlanes[LSide][3] > 0 then
      Continue;
    if FPlanes[LSide][0] * (AX + ASize) + FPlanes[LSide][1] * (AY + ASize) + FPlanes[LSide][2] * (AZ + ASize) + FPlanes[LSide][3] > 0 then
      Continue;

    Result := False;
    Exit;
  end;
  Result := True;
end;

end.
