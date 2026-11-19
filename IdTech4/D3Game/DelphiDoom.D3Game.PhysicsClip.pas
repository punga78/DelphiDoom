{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the clip model of a physics object        }
{                                                                              }
{  Port of the clip model members that idPhysics_Static and                    }
{  idPhysics_Parametric share (game\physics\Physics_Static.cpp:                }
{  SetClipModel, GetClipModel, GetNumClipModels, SetContents, GetContents,     }
{  GetAbsBounds, DisableClip, EnableClip, UnlinkClip, LinkClip, ClipContents), }
{  kept in one class instead of two copies.                                    }
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
unit DelphiDoom.D3Game.PhysicsClip;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.D3Game.Clip, DelphiDoom.D3Game.ClipModel;

type
  /// <summary>
  ///   The clip model of a physics object and what links it. With no clip (the game has none) every operation does
  ///   nothing and the object has no clip model, as an entity without <c>size</c> does. The object owns the clip model
  ///   it is given (the destructor of the physics deletes it).
  /// </summary>
  TD3PhysicsClip = class
  strict private
    FClip: TD3Clip;
    FSelf: TObject;
    FClipModel: TD3ClipModel;
  public
    /// <param name="AClip">the game's clip; nil for a game with no clipping</param>
    /// <param name="ASelf">the entity the physics belongs to (what the clip model reports as its entity)</param>
    constructor Create(const AClip: TD3Clip; const ASelf: TObject);
    destructor Destroy; override;
    /// <summary>
    ///   idPhysics_Static::SetClipModel: takes the model (and frees the old one if it is another) and links it at the
    ///   origin and axis
    /// </summary>
    procedure SetClipModel(const AModel: TD3ClipModel; const AOrigin: TIdVec3; const AAxis: TIdMat3;
      const AFreeOld: Boolean = True);
    /// <summary>The clip model, nil if there is none</summary>
    function GetClipModel: TD3ClipModel;
    function GetNumClipModels: Integer;
    /// <summary>idPhysics_Static::LinkClip</summary>
    procedure LinkClip(const AOrigin: TIdVec3; const AAxis: TIdMat3);
    procedure UnlinkClip;
    procedure DisableClip;
    procedure EnableClip;
    procedure SetContents(const AContents: Integer);
    function GetContents: Integer;
    /// <summary>idPhysics_Static::ClipContents: the contents of the clip model of the physics inside a clip model, or in the world</summary>
    function ClipContents(const AModel: TD3ClipModel): Integer;
    /// <summary>The absolute bounds of the clip model; false if there is none</summary>
    function GetAbsBounds(out AMins, AMaxs: TIdVec3): Boolean;
    property Clip: TD3Clip read FClip;
  end;

implementation

uses
  DelphiDoom.D3Game.ClipConvert;

constructor TD3PhysicsClip.Create(const AClip: TD3Clip; const ASelf: TObject);
begin
  inherited Create;
  FClip := AClip;
  FSelf := ASelf;
end;

destructor TD3PhysicsClip.Destroy;
begin
  FClipModel.Free;
  inherited Destroy;
end;

procedure TD3PhysicsClip.SetClipModel(const AModel: TD3ClipModel; const AOrigin: TIdVec3; const AAxis: TIdMat3;
  const AFreeOld: Boolean);
begin
  if Assigned(FClipModel) and (FClipModel <> AModel) and AFreeOld then
    FClipModel.Free;
  FClipModel := AModel;
  if Assigned(FClipModel) and Assigned(FClip) then
    FClip.Link(FClipModel, FSelf, 0, TD3ClipConvert.ToGeo(AOrigin), TD3ClipConvert.ToGeo(AAxis));
end;

function TD3PhysicsClip.GetClipModel: TD3ClipModel;
begin
  Result := FClipModel;
end;

function TD3PhysicsClip.GetNumClipModels: Integer;
begin
  if Assigned(FClipModel) then
    Result := 1
  else
    Result := 0;
end;

procedure TD3PhysicsClip.LinkClip(const AOrigin: TIdVec3; const AAxis: TIdMat3);
begin
  if Assigned(FClipModel) and Assigned(FClip) then
    FClip.Link(FClipModel, FSelf, 0, TD3ClipConvert.ToGeo(AOrigin), TD3ClipConvert.ToGeo(AAxis));
end;

procedure TD3PhysicsClip.UnlinkClip;
begin
  if Assigned(FClipModel) then
    FClipModel.Unlink;
end;

procedure TD3PhysicsClip.DisableClip;
begin
  if Assigned(FClipModel) then
    FClipModel.Disable;
end;

procedure TD3PhysicsClip.EnableClip;
begin
  if Assigned(FClipModel) then
    FClipModel.Enable;
end;

procedure TD3PhysicsClip.SetContents(const AContents: Integer);
begin
  if Assigned(FClipModel) then
    FClipModel.Contents := AContents;
end;

function TD3PhysicsClip.GetContents: Integer;
begin
  if Assigned(FClipModel) then
    Result := FClipModel.Contents
  else
    Result := 0;
end;

function TD3PhysicsClip.ClipContents(const AModel: TD3ClipModel): Integer;
begin
  Result := 0;
  if not (Assigned(FClipModel) and Assigned(FClip)) then
    Exit;
  if Assigned(AModel) then
    Result := FClip.ContentsModel(FClipModel.Origin, FClipModel, FClipModel.Axis, -1, AModel.Handle, AModel.Origin,
      AModel.Axis)
  else
    Result := FClip.Contents(FClipModel.Origin, FClipModel, FClipModel.Axis, -1, nil);
end;

function TD3PhysicsClip.GetAbsBounds(out AMins, AMaxs: TIdVec3): Boolean;
begin
  Result := Assigned(FClipModel);
  if Result then
  begin
    AMins := TD3ClipConvert.ToId(FClipModel.AbsBounds.Mins);
    AMaxs := TD3ClipConvert.ToId(FClipModel.AbsBounds.Maxs);
  end;
end;

end.
