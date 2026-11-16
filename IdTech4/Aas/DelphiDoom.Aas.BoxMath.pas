{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - boxes and planes (be_aas_sample.c)                }
{                                                                              }
{  Port of AAS_PresenceTypeBoundingBox, AAS_BoxOriginDistanceFromPlane,        }
{  AAS_BoxOnPlaneSide2 and the macro AAS_BoxOnPlaneSide. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.BoxMath;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types;

type
  /// <summary>The functions of be_aas_sample.c that only look at a box and a plane</summary>
  TAasBoxMath = class
  public
    /// <summary>
    ///   AAS_PresenceTypeBoundingBox: the box of the client for a presence type. An unknown
    ///   type prints PRT_FATAL (when there is an import) and gives the crouching box, as the original
    /// </summary>
    class procedure PresenceTypeBoundingBox(const AImport: IBotImport; const APresenceType: Integer;
      out AMins, AMaxs: TVec3); static;
    /// <summary>
    ///   AAS_BoxOriginDistanceFromPlane: the distance between the origin of the box and the
    ///   plane when they touch on the side of the plane (ASide 0 the normal side, 1 the other)
    /// </summary>
    class function BoxOriginDistanceFromPlane(const ANormal, AMins, AMaxs: TVec3; const ASide: Integer): Single; static;
    /// <summary>AAS_BoxOnPlaneSide2: 1 the box is at the front, 2 at the back, 3 on both sides</summary>
    class function BoxOnPlaneSide2(const AAbsMins, AAbsMaxs: TVec3; const APlane: TAasPlane): Integer; static;
    /// <summary>The macro AAS_BoxOnPlaneSide: the same, faster for the planes of the axes</summary>
    class function BoxOnPlaneSide(const AAbsMins, AAbsMaxs: TVec3; const APlane: TAasPlane): Integer; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath;

resourcestring
  SUnknownPresence = 'AAS_PresenceTypeBoundingBox: unknown presence type'#10;

const
  // the constants of the original are double literals
  BBOX_NORMAL_EPSILON: Double = 0.001;

{ TAasBoxMath }

class procedure TAasBoxMath.PresenceTypeBoundingBox(const AImport: IBotImport; const APresenceType: Integer;
  out AMins, AMaxs: TVec3);
const
  BOX_MINS: array[0..2] of TVec3 = ((0, 0, 0), (-15, -15, -24), (-15, -15, -24));
  BOX_MAXS: array[0..2] of TVec3 = ((0, 0, 0), (15, 15, 32), (15, 15, 8));
var
  LIndex: Integer;
begin
  if APresenceType = PRESENCE_NORMAL then
    LIndex := 1
  else if APresenceType = PRESENCE_CROUCH then
    LIndex := 2
  else
  begin
    TAasPrinter.Print(AImport, PRT_FATAL, SUnknownPresence);
    LIndex := 2;
  end;
  AMins := BOX_MINS[LIndex];
  AMaxs := BOX_MAXS[LIndex];
end;

class function TAasBoxMath.BoxOriginDistanceFromPlane(const ANormal, AMins, AMaxs: TVec3;
  const ASide: Integer): Single;
var
  LV1, LV2: TVec3;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    // a point of the box that would be one of the first to collide with the plane
    if ANormal[LIndex] > BBOX_NORMAL_EPSILON then
    begin
      if ASide <> 0 then
        LV1[LIndex] := AMaxs[LIndex]
      else
        LV1[LIndex] := AMins[LIndex];
    end
    else if ANormal[LIndex] < -BBOX_NORMAL_EPSILON then
    begin
      if ASide <> 0 then
        LV1[LIndex] := AMins[LIndex]
      else
        LV1[LIndex] := AMaxs[LIndex];
    end
    else
      LV1[LIndex] := 0;
  end;
  LV2[0] := -ANormal[0];
  LV2[1] := -ANormal[1];
  LV2[2] := -ANormal[2];
  Result := TAasVectorMath.Dot(LV1, LV2);
end;

class function TAasBoxMath.BoxOnPlaneSide2(const AAbsMins, AAbsMaxs: TVec3; const APlane: TAasPlane): Integer;
var
  LCorner0, LCorner1: TVec3;
  LIndex: Integer;
  LDist1, LDist2: Single;
begin
  for LIndex := 0 to 2 do
  begin
    if APlane.Normal[LIndex] < 0 then
    begin
      LCorner0[LIndex] := AAbsMins[LIndex];
      LCorner1[LIndex] := AAbsMaxs[LIndex];
    end
    else
    begin
      LCorner1[LIndex] := AAbsMins[LIndex];
      LCorner0[LIndex] := AAbsMaxs[LIndex];
    end;
  end;
  LDist1 := TAasVectorMath.Dot(APlane.Normal, LCorner0);
  LDist1 := LDist1 - APlane.Dist;
  LDist2 := TAasVectorMath.Dot(APlane.Normal, LCorner1);
  LDist2 := LDist2 - APlane.Dist;
  Result := 0;
  if LDist1 >= 0 then
    Result := 1;
  if LDist2 < 0 then
    Result := Result or 2;
end;

class function TAasBoxMath.BoxOnPlaneSide(const AAbsMins, AAbsMaxs: TVec3; const APlane: TAasPlane): Integer;
begin
  if (APlane.PlaneType >= 0) and (APlane.PlaneType < 3) then
  begin
    if APlane.Dist <= AAbsMins[APlane.PlaneType] then
      Result := 1
    else if APlane.Dist >= AAbsMaxs[APlane.PlaneType] then
      Result := 2
    else
      Result := 3;
  end
  else
    Result := BoxOnPlaneSide2(AAbsMins, AAbsMaxs, APlane);
end;

end.
