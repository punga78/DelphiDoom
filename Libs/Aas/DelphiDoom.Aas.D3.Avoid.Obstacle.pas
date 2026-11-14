{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, one obstacle         }
{                                                                              }
{  Port of obstacle_t (AI_pathing.cpp), Doom 3 GPL Source Code.                 }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.Obstacle;

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Winding2D;

type
  /// <summary>
  ///   An obstacle: the 2D winding of the projection of a box on the floor, expanded for the box of the body,
  ///   the 2D bounds of the winding and the entity (<c>AVOID_NO_ENTITY</c> for a wall of the AAS). The
  ///   winding belongs to the obstacle
  /// </summary>
  TAvoidObstacle = class
  strict private
    FWinding: TGeoWinding2D;
  public
    BoundsMin: TIdVec2;
    BoundsMax: TIdVec2;
    EntityId: Integer;
    constructor Create;
    destructor Destroy; override;
    property Winding: TGeoWinding2D read FWinding;
    /// <summary>Sets the bounds from the winding (idWinding2D::GetBounds)</summary>
    procedure UpdateBounds;
  end;

implementation

{ TAvoidObstacle }

constructor TAvoidObstacle.Create;
begin
  inherited Create;
  FWinding := TGeoWinding2D.Create;
end;

destructor TAvoidObstacle.Destroy;
begin
  FWinding.Free;
  inherited Destroy;
end;

procedure TAvoidObstacle.UpdateBounds;
begin
  FWinding.GetBounds(BoundsMin, BoundsMax);
end;

end.
