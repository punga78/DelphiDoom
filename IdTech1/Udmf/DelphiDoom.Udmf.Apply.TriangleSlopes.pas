{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the slopes of a triangular sector                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.TriangleSlopes;

interface

uses
  DelphiDoom.Udmf.Apply.Types, DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>A floor or a ceiling slopes when any corner has its own absolute height</summary>
  TUdmfTriangleSlopes = class(TInterfacedObject, IUdmfTriangleSlopes)
  strict private
    function CornerFloor(const ACorner: TUdmfTriangleCorner; AFloorHeight: Integer): Single;
    function CornerCeiling(const ACorner: TUdmfTriangleCorner; ACeilingHeight: Integer): Single;
  public
    function Solve(const ACorners: TUdmfTriangle; AFloorHeight, ACeilingHeight: Integer): TUdmfSurfaceSlopes;
  end;

implementation

uses
  DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Apply.PlaneMath;

{ TUdmfTriangleSlopes }

function TUdmfTriangleSlopes.CornerFloor(const ACorner: TUdmfTriangleCorner;
  AFloorHeight: Integer): Single;
begin
  if ACorner.Flags and UDMF_VF_ZFLOOR <> 0 then
    Result := ACorner.ZFloor / FRACUNIT
  else
    Result := AFloorHeight / FRACUNIT;
end;

function TUdmfTriangleSlopes.CornerCeiling(const ACorner: TUdmfTriangleCorner;
  ACeilingHeight: Integer): Single;
begin
  if ACorner.Flags and UDMF_VF_ZCEILING <> 0 then
    Result := ACorner.ZCeiling / FRACUNIT
  else
    Result := ACeilingHeight / FRACUNIT;
end;

function TUdmfTriangleSlopes.Solve(const ACorners: TUdmfTriangle; AFloorHeight,
  ACeilingHeight: Integer): TUdmfSurfaceSlopes;
var
  LIndex: Integer;
  LX, LY: array[0..2] of Single;
begin
  Result.HasFloor := False;
  Result.HasCeiling := False;
  FillChar(Result.Floor, SizeOf(Result.Floor), 0);
  FillChar(Result.Ceiling, SizeOf(Result.Ceiling), 0);

  for LIndex := 0 to 2 do
  begin
    LX[LIndex] := ACorners[LIndex].X / FRACUNIT;
    LY[LIndex] := ACorners[LIndex].Y / FRACUNIT;
    if ACorners[LIndex].Flags and UDMF_VF_ZFLOOR <> 0 then
      Result.HasFloor := True;
    if ACorners[LIndex].Flags and UDMF_VF_ZCEILING <> 0 then
      Result.HasCeiling := True;
  end;

  if Result.HasFloor then
    Result.Floor := TUdmfPlaneMath.ThroughPoints(
      LX[0], LY[0], CornerFloor(ACorners[0], AFloorHeight),
      LX[1], LY[1], CornerFloor(ACorners[1], AFloorHeight),
      LX[2], LY[2], CornerFloor(ACorners[2], AFloorHeight));
  if Result.HasCeiling then
    Result.Ceiling := TUdmfPlaneMath.ThroughPoints(
      LX[0], LY[0], CornerCeiling(ACorners[0], ACeilingHeight),
      LX[1], LY[1], CornerCeiling(ACorners[1], ACeilingHeight),
      LX[2], LY[2], CornerCeiling(ACorners[2], ACeilingHeight));
end;

end.
