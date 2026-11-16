{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the world of the movement is the collision      }
{  model of a Quake III map                                                    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the trace and   }
{  pointcontents callbacks of the server game (SV_Trace, SV_PointContents of   }
{  sv_world.c). Copyright (C) 1999-2005 Id Software, Inc. This unit is         }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.CollisionTrace;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Pmove.Intf;

type
  /// <summary>
  ///   IPmoveTrace on the collision model of one map: the world alone, no entities (the movement of the map is
  ///   what this gives; a game that has movers and bodies gives a trace that adds them). The entity number of a
  ///   hit is ENTITYNUM_WORLD, of a miss ENTITYNUM_NONE, as the server sets it: the model leaves it unset
  /// </summary>
  TPmoveCollisionTrace = class(TInterfacedObject, IPmoveTrace)
  strict private
    FModel: IQ3CollisionModel;
  public
    constructor Create(const AModel: IQ3CollisionModel);
    function Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3; const AEntityToSkip, AContentMask: Integer): TQ3Trace;
    function PointContents(const APoint: TQ3Vec3; const AEntityToSkip: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Pmove.Types;

constructor TPmoveCollisionTrace.Create(const AModel: IQ3CollisionModel);
begin
  inherited Create;
  Assert(Assigned(AModel));
  FModel := AModel;
end;

function TPmoveCollisionTrace.Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3; const AEntityToSkip,
  AContentMask: Integer): TQ3Trace;
begin
  // model 0 is the world tree, a box (not a capsule)
  Result := FModel.BoxTrace(AStart, AEnd, AMins, AMaxs, 0, AContentMask, False);
  if Result.Fraction < 1.0 then
    Result.EntityNum := Q3_ENTITYNUM_WORLD
  else
    Result.EntityNum := Q3_ENTITYNUM_NONE;
end;

function TPmoveCollisionTrace.PointContents(const APoint: TQ3Vec3; const AEntityToSkip: Integer): Integer;
begin
  Result := FModel.PointContents(APoint, 0);
end;

end.
