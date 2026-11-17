{******************************************************************************}
{                                                                              }
{  DelphiDoom: models library - dynamic models of Doom 3, shared types         }
{                                                                              }
{  The part of renderEntity_t and renderView_t that the dynamic models read    }
{  (renderer\RenderWorld.h). Based on the Doom 3 GPL Source Code (id           }
{  Software). This unit is derived from it and is therefore available under    }
{  the GNU General Public License, version 3 or (at your option) any later     }
{  version, with the additional terms of the Doom 3 Source Code License        }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later. Copyright (C)    }
{  1999-2011 id Software LLC.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Dynamic.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Types, DelphiDoom.Models.Static.Triangles;

const
  /// <summary>MAX_ENTITY_SHADER_PARMS: the shader parameters of an entity</summary>
  DYNAMIC_MAX_SHADER_PARMS = 12;
  /// <summary>SHADERPARM_RED, GREEN, BLUE and ALPHA: the colour of a sprite or a beam, from 0 to 1</summary>
  SHADERPARM_RED = 0;
  SHADERPARM_GREEN = 1;
  SHADERPARM_BLUE = 2;
  SHADERPARM_ALPHA = 3;
  /// <summary>SHADERPARM_SPRITE_WIDTH and HEIGHT (the same slots as the end of a beam and its width)</summary>
  SHADERPARM_SPRITE_WIDTH = 8;
  SHADERPARM_SPRITE_HEIGHT = 9;
  /// <summary>SHADERPARM_BEAM_END_X, Y and Z: where a beam ends, in world coordinates; BEAM_WIDTH shares the slot of the sprite width</summary>
  SHADERPARM_BEAM_END_X = 8;
  SHADERPARM_BEAM_END_Y = 9;
  SHADERPARM_BEAM_END_Z = 10;
  SHADERPARM_BEAM_WIDTH = 11;
  /// <summary>The name of the model a sprite or a beam makes, as the original gives it to the snapshot</summary>
  SPRITE_SNAPSHOT_NAME = '_sprite_Snapshot_';
  BEAM_SNAPSHOT_NAME = '_beam_Snapshot_';

type
  /// <summary>renderEntity_t as far as the dynamic models read it: where it is and its shader parameters</summary>
  TDynamicEntity = record
    Origin: TIdVec3;
    Axis: TIdMat3;
    ShaderParms: array[0..DYNAMIC_MAX_SHADER_PARMS - 1] of Single;
    /// <summary>A entity at the origin with the identity axis and zero parameters</summary>
    class function Default: TDynamicEntity; static;
  end;

  /// <summary>What a dynamic model makes for one view: the one surface of its snapshot and the box of its vertexes</summary>
  TDynamicSnapshot = record
    Name: string;
    Surface: TStaticSurface;
    Bounds: TGeoBounds;
  end;

implementation

{ TDynamicEntity }

class function TDynamicEntity.Default: TDynamicEntity;
begin
  Result := System.Default(TDynamicEntity);
  Result.Axis := TIdMat3.Identity;
end;

end.
