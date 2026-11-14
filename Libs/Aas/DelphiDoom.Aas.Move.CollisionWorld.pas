{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the BSP of the bots through the collision model   }
{                                                                              }
{  AAS_PointContents and AAS_Trace of be_aas_bspq3.c answered by IQ3Collision  }
{  of Libs\Collision (the world only: no entities). Based on the Quake III     }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Move.CollisionWorld;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Move.Intf;

type
  /// <summary>The world of the bots from a collision model; the model is not owned</summary>
  TAasCollisionWorld = class(TInterfacedObject, IAasBspWorld)
  strict private
    FCollision: IQ3Collision;
  public
    constructor Create(const ACollision: IQ3Collision);
    function PointContents(const APoint: TVec3): Integer;
    function Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
      AContentMask: Integer): TAasBspTrace;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types;

{ TAasCollisionWorld }

constructor TAasCollisionWorld.Create(const ACollision: IQ3Collision);
begin
  inherited Create;
  FCollision := ACollision;
end;

function TAasCollisionWorld.PointContents(const APoint: TVec3): Integer;
begin
  Result := FCollision.PointContents(TQ3Vec3(APoint), 0);
end;

function TAasCollisionWorld.Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3;
  const APassEnt, AContentMask: Integer): TAasBspTrace;
var
  LMins, LMaxs: TQ3Vec3;
  LTrace: TQ3Trace;
begin
  FillChar(LMins, SizeOf(LMins), 0);
  FillChar(LMaxs, SizeOf(LMaxs), 0);
  if Assigned(AMins) then
    LMins := TQ3Vec3(AMins^);
  if Assigned(AMaxs) then
    LMaxs := TQ3Vec3(AMaxs^);
  LTrace := FCollision.BoxTrace(TQ3Vec3(AStart), TQ3Vec3(AEnd), LMins, LMaxs, 0, AContentMask, False);
  Result.AllSolid := LTrace.AllSolid;
  Result.StartSolid := LTrace.StartSolid;
  Result.Fraction := LTrace.Fraction;
  Result.EndPos := TVec3(LTrace.EndPos);
  Result.Contents := LTrace.Contents;
  Result.EntityNum := LTrace.EntityNum;
  Result.SurfaceFlags := LTrace.SurfaceFlags;
end;

end.
