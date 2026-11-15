{******************************************************************************}
{                                                                              }
{  DelphiDoom: models library - the sprite model of Doom 3                     }
{                                                                              }
{  Port of idRenderModelSprite (renderer\Model_sprite.cpp).                    }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Dynamic.SpriteModel;

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Bounds, DelphiDoom.Models.Dynamic.Types;

type
  /// <summary>
  ///   A flat square that always faces the view axis: one surface of four vertexes and six indexes in the
  ///   y-z plane (the renderer turns the entity to face the view), half the width and half the height of the
  ///   entity's shader parameters 8 and 9 from the origin, the colour of parameters 0 to 3 times 255. The
  ///   snapshot is made again for every view (the time is not needed: nothing in it moves)
  /// </summary>
  TSpriteModel = class
  public
    /// <summary>
    ///   InstantiateDynamicModel: always a new snapshot (the original deletes the cached one unless
    ///   <c>r_useCachedDynamicModels</c>, and then writes the same vertexes). The material is the default one
    /// </summary>
    function Instantiate(const AEntity: TDynamicEntity): TDynamicSnapshot;
    /// <summary>
    ///   Bounds: the box that holds the sprite whatever the view: the origin expanded by the larger of the width
    ///   and the height over two (8 units when there is no entity)
    /// </summary>
    function Bounds(const AEntity: TDynamicEntity; AHasEntity: Boolean = True): TGeoBounds;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Math, DelphiDoom.Models.Static.Types;

{ TSpriteModel }

function TSpriteModel.Instantiate(const AEntity: TDynamicEntity): TDynamicSnapshot;
var
  LVertexes: TArray<TStaticDrawVert>;
  LIndex: Integer;
  LRight, LUp: TIdVec3;
  LColor: TStaticColor;
  LTexture: array[0..3, 0..1] of Single;
begin
  SetLength(LVertexes, 4);
  LTexture[0, 0] := 0; LTexture[0, 1] := 0;
  LTexture[1, 0] := 1; LTexture[1, 1] := 0;
  LTexture[2, 0] := 1; LTexture[2, 1] := 1;
  LTexture[3, 0] := 0; LTexture[3, 1] := 1;
  for LIndex := 0 to 3 do
  begin
    LVertexes[LIndex].Clear;
    LVertexes[LIndex].Normal := TIdVec3.Create(1, 0, 0);
    LVertexes[LIndex].Tangents[0] := TIdVec3.Create(0, 1, 0);
    LVertexes[LIndex].Tangents[1] := TIdVec3.Create(0, 0, 1);
    LVertexes[LIndex].St.X := LTexture[LIndex, 0];
    LVertexes[LIndex].St.Y := LTexture[LIndex, 1];
  end;
  LColor := TStaticColor.Make(
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_RED] * 255.0)),
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_GREEN] * 255.0)),
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_BLUE] * 255.0)),
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_ALPHA] * 255.0)));
  LRight := TIdVec3.Create(0, AEntity.ShaderParms[SHADERPARM_SPRITE_WIDTH] * 0.5, 0);
  LUp := TIdVec3.Create(0, 0, AEntity.ShaderParms[SHADERPARM_SPRITE_HEIGHT] * 0.5);
  LVertexes[0].Xyz := LUp + LRight;
  LVertexes[1].Xyz := LUp - LRight;
  LVertexes[2].Xyz := -LRight - LUp;
  LVertexes[3].Xyz := LRight - LUp;
  for LIndex := 0 to 3 do
    LVertexes[LIndex].Color := LColor;

  Result := Default(TDynamicSnapshot);
  Result.Name := SPRITE_SNAPSHOT_NAME;
  Result.Surface.Id := 0;
  Result.Surface.MaterialName := STATIC_DEFAULT_MATERIAL;
  Result.Surface.HasGeometry := True;
  Result.Surface.Triangles.Verts := LVertexes;
  Result.Surface.Triangles.Indexes := [0, 1, 3, 1, 2, 3];
  Result.Bounds := Result.Surface.Triangles.CalcBounds;
end;

function TSpriteModel.Bounds(const AEntity: TDynamicEntity; AHasEntity: Boolean): TGeoBounds;
begin
  Result.Zero;
  if not AHasEntity then
    Result.ExpandSelf(8.0)
  else
    Result.ExpandSelf(Max(AEntity.ShaderParms[SHADERPARM_SPRITE_WIDTH], AEntity.ShaderParms[SHADERPARM_SPRITE_HEIGHT]) * 0.5);
end;

end.
