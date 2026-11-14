{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the models of the BSP from the collision model     }
{                                                                              }
{  What the server of Quake III answers to botimport.BSPEntityData, inPVS,      }
{  BSPModelMinsMaxsOrigin and EntityTrace (sv_bot.c, sv_game.c), from the       }
{  collision model of Libs\Collision. Based on the Quake III Arena GPL Source   }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is   }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Bsp.CollisionModels;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Bsp.Intf;

type
  /// <summary>The world only: there are no entities in a collision model, the entity trace never collides</summary>
  TAasCollisionModels = class(TInterfacedObject, IAasBspModels)
  strict private
    FCollision: IQ3CollisionModel;
  public
    constructor Create(const ACollision: IQ3CollisionModel);
    function EntityData: AnsiString;
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types;

constructor TAasCollisionModels.Create(const ACollision: IQ3CollisionModel);
begin
  inherited Create;
  FCollision := ACollision;
end;

function TAasCollisionModels.EntityData: AnsiString;
begin
  Result := FCollision.GetEntityString;
end;

function TAasCollisionModels.EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3;
  const AEntNum, AContentMask: Integer): TAasBspTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
  Result.EndPos := AEnd;
  Result.EntityNum := -1;
end;

function TAasCollisionModels.InPVS(const AFirst, ASecond: TVec3): Boolean;
var
  LLeaf1, LLeaf2, LCluster1, LCluster2, LArea1, LArea2: Integer;
  LMask: TBytes;
begin
  LLeaf1 := FCollision.PointLeafnum(TQ3Vec3(AFirst));
  LCluster1 := FCollision.LeafCluster(LLeaf1);
  LArea1 := FCollision.LeafArea(LLeaf1);
  LMask := FCollision.ClusterPVS(LCluster1);
  LLeaf2 := FCollision.PointLeafnum(TQ3Vec3(ASecond));
  LCluster2 := FCollision.LeafCluster(LLeaf2);
  LArea2 := FCollision.LeafArea(LLeaf2);
  // the mask is indexed by the cluster of the second point; a point outside has the cluster -1
  if (Length(LMask) > 0) and (LCluster2 >= 0) and ((LCluster2 shr 3) < Length(LMask)) and
    ((LMask[LCluster2 shr 3] and (1 shl (LCluster2 and 7))) = 0) then
    Exit(False);
  Result := FCollision.AreasConnected(LArea1, LArea2);
end;

procedure TAasCollisionModels.ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3;
  out AMins, AMaxs, AOrigin: TVec3);
var
  LHandle, LIndex: Integer;
  LMins, LMaxs: TQ3Vec3;
  LCorner: array[0..2] of Single;
  LRadius, LA, LB: Single;
begin
  LHandle := FCollision.InlineModel(AModelNum);
  FCollision.ModelBounds(LHandle, LMins, LMaxs);
  if (AAngles[0] <> 0) or (AAngles[1] <> 0) or (AAngles[2] <> 0) then
  begin
    // RadiusFromBounds: expand for the rotation
    for LIndex := 0 to 2 do
    begin
      LA := Abs(LMins[LIndex]);
      LB := Abs(LMaxs[LIndex]);
      if LA > LB then
        LCorner[LIndex] := LA
      else
        LCorner[LIndex] := LB;
    end;
    LRadius := Sqrt(Double(LCorner[0] * LCorner[0] + LCorner[1] * LCorner[1] + LCorner[2] * LCorner[2]));
    for LIndex := 0 to 2 do
    begin
      LMins[LIndex] := -LRadius;
      LMaxs[LIndex] := LRadius;
    end;
  end;
  AMins := TVec3(LMins);
  AMaxs := TVec3(LMaxs);
  AOrigin[0] := 0;
  AOrigin[1] := 0;
  AOrigin[2] := 0;
end;

end.
