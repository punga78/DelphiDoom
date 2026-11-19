{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the parametric physics (linear motion)    }
{                                                                              }
{  Reduced port of Doom 3 (id Software): game\physics\Physics_Parametric.cpp.  }
{  Only the linear path is ported (extrapolation and acceleration/deceleration }
{  interpolation of the position): no angles, spline, pusher, clip model or    }
{  master. The curves are TIdExtrapolate and TIdInterpolateAccelDecelLinear of }
{  Framework\MathCore.                                                         }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.PhysicsParametric;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Extrapolate,
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelLinear, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.D3Game.Physics.Intf,
  DelphiDoom.D3Game.Clip, DelphiDoom.D3Game.ClipModel, DelphiDoom.D3Game.PhysicsClip;

type
  /// <summary>What the physics asks of the game and of its entity: the time and the think flags</summary>
  TD3PhysicsHost = record
    /// <summary>gameLocal.time</summary>
    GetTime: TFunc<Integer>;
    /// <summary>self->BecomeActive( flags )</summary>
    BecomeActive: TProc<Integer>;
    /// <summary>self->BecomeInactive( flags )</summary>
    BecomeInactive: TProc<Integer>;
  end;

  /// <summary>
  ///   idPhysics_Parametric (linear motion): the position follows an extrapolation or an interpolation with
  ///   acceleration and deceleration over time, set by the owner (doors, movers). When the motion is over the body rests:
  ///   the entity stops thinking about physics.
  /// </summary>
  TD3PhysicsParametric = class(TInterfacedObject, ID3Physics)
  strict private
    FHost: TD3PhysicsHost;
    FTime: Integer;
    FAtRest: Integer;
    FOrigin: TIdVec3;
    FAxis: TIdMat3;
    FLocalOrigin: TIdVec3;
    FMins: TIdVec3;
    FMaxs: TIdVec3;
    FClip: TD3PhysicsClip;
    FLinearExtrapolation: TIdExtrapolate<TIdVec3>;
    FLinearInterpolation: TIdInterpolateAccelDecelLinear<TIdVec3>;
    function TestIfAtRest: Boolean;
    procedure Rest;
  public
    /// <param name="AMins">the bounds of the body relative to its origin (the clip model's)</param>
    /// <param name="AClip">the game's clip, nil for none (the bounds are then given)</param>
    /// <param name="ASelf">the entity the physics belongs to</param>
    constructor Create(const AHost: TD3PhysicsHost; const AMins, AMaxs: TIdVec3; const AClip: TD3Clip = nil;
      const ASelf: TObject = nil);
    destructor Destroy; override;
    function GetAxis: TIdMat3;
    procedure SetAxis(const AAxis: TIdMat3);
    procedure SetClipModel(const AModel: TD3ClipModel);
    function GetClipModel: TD3ClipModel;
    function GetNumClipModels: Integer;
    procedure SetContents(const AContents: Integer);
    function GetContents: Integer;
    procedure DisableClip;
    procedure EnableClip;
    procedure UnlinkClip;
    procedure LinkClip;
    function ClipContents(const AModel: TD3ClipModel): Integer;
    /// <summary>idPhysics_Parametric::Activate</summary>
    procedure Activate;
    /// <summary>idPhysics_Parametric::SetLinearExtrapolation (the type is an ID_EXTRAPOLATION_ constant)</summary>
    procedure SetLinearExtrapolation(const AType, ATime, ADuration: Integer; const ABase, ASpeed, ABaseSpeed: TIdVec3);
    /// <summary>idPhysics_Parametric::SetLinearInterpolation</summary>
    procedure SetLinearInterpolation(const ATime, AAccelTime, ADecelTime, ADuration: Integer;
      const AStartPos, AEndPos: TIdVec3);
    function GetLinearExtrapolationType: Integer;
    /// <summary>idPhysics_Parametric::GetLocalOrigin</summary>
    function GetLocalOrigin: TIdVec3;
    function GetOrigin: TIdVec3;
    procedure SetOrigin(const AOrigin: TIdVec3);
    function GetAbsBoundsMin: TIdVec3;
    function GetAbsBoundsMax: TIdVec3;
    function Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
    procedure UpdateTime(const AEndTimeMSec: Integer);
    function GetTime: Integer;
    function GetLinearEndTime: Integer;
    function GetAngularEndTime: Integer;
    function IsAtRest: Boolean;
    /// <summary>idPhysics_Parametric::GetRestStartTime</summary>
    function GetRestStartTime: Integer;
    /// <summary>
    ///   The physics a mover makes in its spawn function: <c>physicsObj.SetClipModel( new idClipModel( GetPhysics()->
    ///   GetClipModel() ), 1.0f )</c>. With a clip, the clip model is a copy of the one of the current physics (the
    ///   default clip model of the game if it has none, as the original's <c>GetClipModel</c> gives) and the bounds
    ///   are its own; with no clip the bounds are the given ones. The caller sets the origin next.
    /// </summary>
    class function CreateMoverPhysics(const AHost: TD3PhysicsHost; const ACurrent: ID3Physics; const AMins,
      AMaxs: TIdVec3; const AClip: TD3Clip; const ASelf: TObject): TD3PhysicsParametric; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.ClipConvert;

constructor TD3PhysicsParametric.Create(const AHost: TD3PhysicsHost; const AMins, AMaxs: TIdVec3;
  const AClip: TD3Clip; const ASelf: TObject);
begin
  inherited Create;
  FClip := TD3PhysicsClip.Create(AClip, ASelf);
  FAxis := TIdMat3.Identity;
  FHost := AHost;
  FMins := AMins;
  FMaxs := AMaxs;
  FTime := FHost.GetTime();
  FAtRest := -1;
  FOrigin.Zero;
  FLocalOrigin.Zero;
  FLinearExtrapolation := TIdExtrapolate<TIdVec3>.Create(TIdCurveVec3Arithmetic.Create);
  FLinearExtrapolation.Init(0, 0, TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0),
    ID_EXTRAPOLATION_NONE);
  FLinearInterpolation := TIdInterpolateAccelDecelLinear<TIdVec3>.Create(TIdCurveVec3Arithmetic.Create);
  FLinearInterpolation.Init(0, 0, 0, 0, TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0));
end;

destructor TD3PhysicsParametric.Destroy;
begin
  FClip.Free;
  FLinearInterpolation.Free;
  FLinearExtrapolation.Free;
  inherited Destroy;
end;

procedure TD3PhysicsParametric.Activate;
begin
  FAtRest := -1;
  FHost.BecomeActive(D3_TH_PHYSICS);
end;

function TD3PhysicsParametric.TestIfAtRest: Boolean;
begin
  if ((FLinearExtrapolation.GetExtrapolationType and not ID_EXTRAPOLATION_NOSTOP) = ID_EXTRAPOLATION_NONE) and
    (FLinearInterpolation.GetDuration = 0) then
    Exit(True);
  if not FLinearExtrapolation.IsDone(FTime) then
    Exit(False);
  if not FLinearInterpolation.IsDone(FTime) then
    Exit(False);
  Result := True;
end;

procedure TD3PhysicsParametric.Rest;
begin
  FAtRest := FHost.GetTime();
  FHost.BecomeInactive(D3_TH_PHYSICS);
end;

procedure TD3PhysicsParametric.SetLinearExtrapolation(const AType, ATime, ADuration: Integer; const ABase, ASpeed,
  ABaseSpeed: TIdVec3);
begin
  FTime := FHost.GetTime();
  FLinearExtrapolation.Init(ATime, ADuration, ABase, ABaseSpeed, ASpeed, AType);
  FLocalOrigin := ABase;
  Activate;
end;

procedure TD3PhysicsParametric.SetLinearInterpolation(const ATime, AAccelTime, ADecelTime, ADuration: Integer;
  const AStartPos, AEndPos: TIdVec3);
begin
  FTime := FHost.GetTime();
  FLinearInterpolation.Init(ATime, AAccelTime, ADecelTime, ADuration, AStartPos, AEndPos);
  FLocalOrigin := AStartPos;
  Activate;
end;

function TD3PhysicsParametric.GetLinearExtrapolationType: Integer;
begin
  Result := FLinearExtrapolation.GetExtrapolationType;
end;

function TD3PhysicsParametric.GetLocalOrigin: TIdVec3;
begin
  Result := FLocalOrigin;
end;

function TD3PhysicsParametric.GetOrigin: TIdVec3;
begin
  Result := FOrigin;
end;

procedure TD3PhysicsParametric.SetOrigin(const AOrigin: TIdVec3);
begin
  FLinearExtrapolation.SetStartValue(AOrigin);
  FLinearInterpolation.SetStartValue(AOrigin);
  FLocalOrigin := FLinearExtrapolation.GetCurrentValue(FTime);
  // no master: the origin is the local origin
  FOrigin := FLocalOrigin;
  FClip.LinkClip(FOrigin, FAxis);
  Activate;
end;

function TD3PhysicsParametric.GetAbsBoundsMin: TIdVec3;
var
  LMins: TIdVec3;
  LMaxs: TIdVec3;
begin
  if FClip.GetAbsBounds(LMins, LMaxs) then
    Result := LMins
  else
    Result := FMins + FOrigin;
end;

function TD3PhysicsParametric.GetAbsBoundsMax: TIdVec3;
var
  LMins: TIdVec3;
  LMaxs: TIdVec3;
begin
  if FClip.GetAbsBounds(LMins, LMaxs) then
    Result := LMaxs
  else
    Result := FMaxs + FOrigin;
end;

function TD3PhysicsParametric.GetAxis: TIdMat3;
begin
  Result := FAxis;
end;

procedure TD3PhysicsParametric.SetAxis(const AAxis: TIdMat3);
begin
  FAxis := AAxis;
  FClip.LinkClip(FOrigin, FAxis);
end;

procedure TD3PhysicsParametric.SetClipModel(const AModel: TD3ClipModel);
begin
  FClip.SetClipModel(AModel, FOrigin, FAxis);
end;

function TD3PhysicsParametric.GetClipModel: TD3ClipModel;
begin
  Result := FClip.GetClipModel;
end;

function TD3PhysicsParametric.GetNumClipModels: Integer;
begin
  Result := FClip.GetNumClipModels;
end;

procedure TD3PhysicsParametric.SetContents(const AContents: Integer);
begin
  FClip.SetContents(AContents);
end;

function TD3PhysicsParametric.GetContents: Integer;
begin
  Result := FClip.GetContents;
end;

procedure TD3PhysicsParametric.DisableClip;
begin
  FClip.DisableClip;
end;

procedure TD3PhysicsParametric.EnableClip;
begin
  FClip.EnableClip;
end;

procedure TD3PhysicsParametric.UnlinkClip;
begin
  FClip.UnlinkClip;
end;

procedure TD3PhysicsParametric.LinkClip;
begin
  FClip.LinkClip(FOrigin, FAxis);
end;

function TD3PhysicsParametric.ClipContents(const AModel: TD3ClipModel): Integer;
begin
  Result := FClip.ClipContents(AModel);
end;

class function TD3PhysicsParametric.CreateMoverPhysics(const AHost: TD3PhysicsHost; const ACurrent: ID3Physics;
  const AMins, AMaxs: TIdVec3; const AClip: TD3Clip; const ASelf: TObject): TD3PhysicsParametric;
var
  LSource: TD3ClipModel;
  LMins: TIdVec3;
  LMaxs: TIdVec3;
begin
  LMins := AMins;
  LMaxs := AMaxs;
  LSource := nil;
  if Assigned(AClip) then
  begin
    if ACurrent.GetNumClipModels > 0 then
      LSource := ACurrent.GetClipModel
    else
      LSource := AClip.DefaultClipModel;
    LMins := TD3ClipConvert.ToId(LSource.Bounds.Mins);
    LMaxs := TD3ClipConvert.ToId(LSource.Bounds.Maxs);
  end;
  Result := TD3PhysicsParametric.Create(AHost, LMins, LMaxs, AClip, ASelf);
  if Assigned(LSource) then
    Result.SetClipModel(TD3ClipModel.Create(LSource));
end;

function TD3PhysicsParametric.Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
var
  LOldOrigin: TIdVec3;
begin
  LOldOrigin := FOrigin;
  FLocalOrigin.Zero;
  if FLinearInterpolation.GetDuration <> 0 then
    FLocalOrigin := FLocalOrigin + FLinearInterpolation.GetCurrentValue(AEndTimeMSec)
  else
    FLocalOrigin := FLocalOrigin + FLinearExtrapolation.GetCurrentValue(AEndTimeMSec);
  FOrigin := FLocalOrigin;
  // a pusher would be clipped against what is in the way here (idPush::ClipPush is not ported: it never is)
  FClip.LinkClip(FOrigin, FAxis);
  FTime := AEndTimeMSec;
  if TestIfAtRest then
    Rest;
  Result := FOrigin <> LOldOrigin;
end;

procedure TD3PhysicsParametric.UpdateTime(const AEndTimeMSec: Integer);
var
  LLeap: Integer;
begin
  LLeap := AEndTimeMSec - FTime;
  FTime := AEndTimeMSec;
  // move the trajectory start times to sync the trajectory with the current endTime
  FLinearExtrapolation.SetStartTime(FLinearExtrapolation.GetStartTime + LLeap);
  FLinearInterpolation.SetStartTime(FLinearInterpolation.GetStartTime + LLeap);
end;

function TD3PhysicsParametric.GetTime: Integer;
begin
  Result := FTime;
end;

function TD3PhysicsParametric.GetLinearEndTime: Integer;
begin
  if FLinearInterpolation.GetDuration <> 0 then
    Result := Trunc(FLinearInterpolation.GetEndTime)
  else
    Result := Trunc(FLinearExtrapolation.GetEndTime);
end;

function TD3PhysicsParametric.GetAngularEndTime: Integer;
begin
  // the angular motion is always an extrapolation of type NONE with no duration
  Result := 0;
end;

function TD3PhysicsParametric.IsAtRest: Boolean;
begin
  Result := FAtRest >= 0;
end;

function TD3PhysicsParametric.GetRestStartTime: Integer;
begin
  Result := FAtRest;
end;

end.
