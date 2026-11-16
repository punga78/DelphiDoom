{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL voxel mesh - the quads as calls of OpenGL                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Voxel.MeshRenderer;

interface

uses
  DelphiDoom.Voxel.MeshRenderer.Intf;

type
  /// <summary>
  ///   The calls of OpenGL of the old RenderGL, in the same order: it is used while a display list
  ///   is compiled (at load time), never per frame
  /// </summary>
  TEngineVoxelMeshRenderer = class(TInterfacedObject, IVoxelMeshRenderer)
  public
    procedure BeginQuads;
    procedure TexCoord(const ACoordS, ACoordT: Single);
    procedure Vertex(const AX, AY, AZ: Single);
    procedure EndQuads;
  end;

implementation

uses
  dglOpenGL;

procedure TEngineVoxelMeshRenderer.BeginQuads;
begin
  glBegin(GL_QUADS);
end;

procedure TEngineVoxelMeshRenderer.TexCoord(const ACoordS, ACoordT: Single);
begin
  glTexCoord2f(ACoordS, ACoordT);
end;

procedure TEngineVoxelMeshRenderer.Vertex(const AX, AY, AZ: Single);
begin
  glVertex3f(AX, AY, AZ);
end;

procedure TEngineVoxelMeshRenderer.EndQuads;
begin
  glEnd;
end;

end.
