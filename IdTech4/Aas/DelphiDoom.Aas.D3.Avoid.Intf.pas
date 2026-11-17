{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - obstacle avoidance, the body that walks  }
{                                                                              }
{  The part of idPhysics and idClip that idAI::GetObstacles reads,             }
{  AI_pathing.cpp Doom 3 GPL Source Code. Based on the Doom 3 GPL Source Code  }
{  (id Software). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media     }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3 or (at  }
{  your option) any later version, with the additional terms of the Doom 3     }
{  Source Code License (Reference\doom3\COPYING.txt: preservation of legal     }
{  notices and trademarks, no use of the licensors' names for publicity,       }
{  warranty disclaimer). The repository as a whole is GPL v2 or later.         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.Intf;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Aas.D3.Avoid.Types;

type
  /// <summary>
  ///   The body that walks and the world around it, as the game gives them: the physics of the AI (box, place,
  ///   gravity, speed) and the obstacles that touch a box. This is the only thing that the obstacle avoidance
  ///   asks the game
  /// </summary>
  IAvoidBody = interface
    ['{4C1D8A30-6E27-4B59-9F03-2A7E15C8B406}']
    /// <summary>idPhysics::GetBounds: the box of the body, in its own space</summary>
    function GetBounds: TGeoBounds;
    /// <summary>idPhysics::GetAbsBounds</summary>
    function GetAbsBounds: TGeoBounds;
    /// <summary>idPhysics::GetGravityNormal</summary>
    function GetGravityNormal: TGeoVec3;
    /// <summary>idPhysics::GetOrigin</summary>
    function GetOrigin: TGeoVec3;
    /// <summary>idPhysics::GetLinearVelocity</summary>
    function GetLinearVelocity: TGeoVec3;
    /// <summary>
    ///   The obstacles that touch the bounds (idClip::ClipModelsTouchingBounds with the clip mask of the body,
    ///   then the choices of idAI::GetObstacles that depend on the entities): see <c>TAvoidClipModel</c>
    /// </summary>
    function ObstaclesTouchingBounds(const ABounds: TGeoBounds): TArray<TAvoidClipModel>;
  end;

implementation

end.
