{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the default physics of an entity          }
{                                                                              }
{  Reduced port of Doom 3 (id Software): game\physics\Physics_Static.cpp (an   }
{  origin, an axis and a clip model; nothing moves). Without a clip in the     }
{  game the bounds are given and there is no clip model.                       }
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
unit DelphiDoom.D3Game.PhysicsStatic;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.D3Game.Physics.Intf,
  DelphiDoom.D3Game.Clip, DelphiDoom.D3Game.ClipModel, DelphiDoom.D3Game.PhysicsClip;

type
  /// <summary>
  ///   idPhysics_Static: the physics an entity has until it gets another one. It has an origin and an axis and, if the
  ///   game has a clip, a clip model (<c>SetClipModel</c>, which links it); the absolute bounds are the clip model's.
  ///   With no clip model the bounds the entity's <c>size</c>, <c>mins</c> and <c>maxs</c> make are given. It never
  ///   moves and has no end of motion.
  /// </summary>
  TD3PhysicsStatic = class(TInterfacedObject, ID3Physics)
  strict private
    FOrigin: TIdVec3;
    FAxis: TIdMat3;
    FMins: TIdVec3;
    FMaxs: TIdVec3;
    FTime: Integer;
    FClip: TD3PhysicsClip;
    FLocalOrigin: TIdVec3;
    FLocalAxis: TIdMat3;
    FHasMaster: Boolean;
    FOrientated: Boolean;
    FMasterPosition: TD3MasterPositionFunc;
  public
    /// <param name="AMins">the bounds relative to the origin (zero for no clip model)</param>
    /// <param name="AClip">the game's clip, nil for none</param>
    /// <param name="ASelf">the entity the physics belongs to</param>
    /// <param name="AMasterPosition">idEntity::GetMasterPosition of the entity; nil for a body that is never bound</param>
    constructor Create(const AOrigin, AMins, AMaxs: TIdVec3; const AClip: TD3Clip = nil;
      const ASelf: TObject = nil; const AMasterPosition: TD3MasterPositionFunc = nil);
    destructor Destroy; override;
    procedure Activate;
    procedure SetMaster(const AHasMaster, AOrientated: Boolean);
    function IsParametric: Boolean;
    function GetOrigin: TIdVec3;
    procedure SetOrigin(const AOrigin: TIdVec3);
    function GetAxis: TIdMat3;
    procedure SetAxis(const AAxis: TIdMat3);
    function GetAbsBoundsMin: TIdVec3;
    function GetAbsBoundsMax: TIdVec3;
    function Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
    procedure UpdateTime(const AEndTimeMSec: Integer);
    function GetTime: Integer;
    function GetLinearEndTime: Integer;
    function GetAngularEndTime: Integer;
    function IsAtRest: Boolean;
    /// <summary>The bounds relative to the origin (what the clip model had)</summary>
    function GetLocalMins: TIdVec3;
    function GetLocalMaxs: TIdVec3;
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
  end;

implementation

constructor TD3PhysicsStatic.Create(const AOrigin, AMins, AMaxs: TIdVec3; const AClip: TD3Clip;
  const ASelf: TObject; const AMasterPosition: TD3MasterPositionFunc);
begin
  inherited Create;
  FOrigin := AOrigin;
  FLocalOrigin.Zero;
  FAxis := TIdMat3.Identity;
  FLocalAxis := TIdMat3.Identity;
  FMasterPosition := AMasterPosition;
  FMins := AMins;
  FMaxs := AMaxs;
  FClip := TD3PhysicsClip.Create(AClip, ASelf);
end;

destructor TD3PhysicsStatic.Destroy;
begin
  FClip.Free;
  inherited Destroy;
end;

function TD3PhysicsStatic.GetOrigin: TIdVec3;
begin
  Result := FOrigin;
end;

procedure TD3PhysicsStatic.Activate;
begin
end;

function TD3PhysicsStatic.IsParametric: Boolean;
begin
  Result := False;
end;

procedure TD3PhysicsStatic.SetOrigin(const AOrigin: TIdVec3);
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  FLocalOrigin := AOrigin;
  if FHasMaster and Assigned(FMasterPosition) then
  begin
    FMasterPosition(LMasterOrigin, LMasterAxis);
    FOrigin := LMasterOrigin + AOrigin * LMasterAxis;
  end
  else
    FOrigin := AOrigin;
  FClip.LinkClip(FOrigin, FAxis);
end;

procedure TD3PhysicsStatic.SetMaster(const AHasMaster, AOrientated: Boolean);
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  if AHasMaster then
  begin
    if not FHasMaster then
    begin
      // transform from world space to master space
      FMasterPosition(LMasterOrigin, LMasterAxis);
      FLocalOrigin := (FOrigin - LMasterOrigin) * LMasterAxis.Transpose;
      if AOrientated then
        FLocalAxis := FAxis * LMasterAxis.Transpose
      else
        FLocalAxis := FAxis;
      FHasMaster := True;
      FOrientated := AOrientated;
    end;
  end
  else if FHasMaster then
    FHasMaster := False;
end;

function TD3PhysicsStatic.GetAxis: TIdMat3;
begin
  Result := FAxis;
end;

procedure TD3PhysicsStatic.SetAxis(const AAxis: TIdMat3);
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
begin
  FLocalAxis := AAxis;
  if FHasMaster and FOrientated then
  begin
    FMasterPosition(LMasterOrigin, LMasterAxis);
    FAxis := AAxis * LMasterAxis;
  end
  else
    FAxis := AAxis;
  FClip.LinkClip(FOrigin, FAxis);
end;

function TD3PhysicsStatic.GetAbsBoundsMin: TIdVec3;
var
  LMins: TIdVec3;
  LMaxs: TIdVec3;
begin
  if FClip.GetAbsBounds(LMins, LMaxs) then
    Result := LMins
  else
    Result := FMins + FOrigin;
end;

function TD3PhysicsStatic.GetAbsBoundsMax: TIdVec3;
var
  LMins: TIdVec3;
  LMaxs: TIdVec3;
begin
  if FClip.GetAbsBounds(LMins, LMaxs) then
    Result := LMaxs
  else
    Result := FMaxs + FOrigin;
end;

function TD3PhysicsStatic.GetLocalMins: TIdVec3;
begin
  Result := FMins;
end;

function TD3PhysicsStatic.GetLocalMaxs: TIdVec3;
begin
  Result := FMaxs;
end;

function TD3PhysicsStatic.Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
var
  LMasterOrigin: TIdVec3;
  LMasterAxis: TIdMat3;
  LOldOrigin: TIdVec3;
  LOldAxis: TIdMat3;
begin
  FTime := AEndTimeMSec;
  Result := False;
  if FHasMaster then
  begin
    LOldOrigin := FOrigin;
    LOldAxis := FAxis;
    FMasterPosition(LMasterOrigin, LMasterAxis);
    FOrigin := LMasterOrigin + FLocalOrigin * LMasterAxis;
    if FOrientated then
      FAxis := FLocalAxis * LMasterAxis
    else
      FAxis := FLocalAxis;
    FClip.LinkClip(FOrigin, FAxis);
    Result := (FOrigin <> LOldOrigin) or (FAxis <> LOldAxis);
  end;
end;

procedure TD3PhysicsStatic.UpdateTime(const AEndTimeMSec: Integer);
begin
  FTime := AEndTimeMSec;
end;

function TD3PhysicsStatic.GetTime: Integer;
begin
  Result := FTime;
end;

function TD3PhysicsStatic.GetLinearEndTime: Integer;
begin
  Result := 0;
end;

function TD3PhysicsStatic.GetAngularEndTime: Integer;
begin
  Result := 0;
end;

function TD3PhysicsStatic.IsAtRest: Boolean;
begin
  Result := True;
end;

procedure TD3PhysicsStatic.SetClipModel(const AModel: TD3ClipModel);
begin
  FClip.SetClipModel(AModel, FOrigin, FAxis);
end;

function TD3PhysicsStatic.GetClipModel: TD3ClipModel;
begin
  Result := FClip.GetClipModel;
end;

function TD3PhysicsStatic.GetNumClipModels: Integer;
begin
  Result := FClip.GetNumClipModels;
end;

procedure TD3PhysicsStatic.SetContents(const AContents: Integer);
begin
  FClip.SetContents(AContents);
end;

function TD3PhysicsStatic.GetContents: Integer;
begin
  Result := FClip.GetContents;
end;

procedure TD3PhysicsStatic.DisableClip;
begin
  FClip.DisableClip;
end;

procedure TD3PhysicsStatic.EnableClip;
begin
  FClip.EnableClip;
end;

procedure TD3PhysicsStatic.UnlinkClip;
begin
  FClip.UnlinkClip;
end;

procedure TD3PhysicsStatic.LinkClip;
begin
  FClip.LinkClip(FOrigin, FAxis);
end;

function TD3PhysicsStatic.ClipContents(const AModel: TD3ClipModel): Integer;
begin
  Result := FClip.ClipContents(AModel);
end;

end.
