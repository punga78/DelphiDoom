{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the drawing of an I3D model                 }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  TI3DModelLoader.RenderGL (OPENGL\i3d_model.pas) on a target with a          }
{  contract instead of OpenGL.                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Renderer;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   Sends the faces of a model to an II3dRenderTarget: a triangle fan for each, the texture of
  ///   the material or its color (half transparent for a translucent material), the texture
  ///   points and the vertexes in the placement. The first 64 faces of a car are drawn in a
  ///   matrix that turns them around the center of their tire. There is no state: one renderer
  ///   serves all the models. The target is called a few times for each face, never for the
  ///   internals of a vertex that it does not need.
  /// </summary>
  TI3dModelRenderer = class(TInterfacedObject, II3dModelRenderer)
  public
    function Render(const AModel: II3dModel; const ATarget: II3dRenderTarget;
      const APlacement: TModelPlacement; const ASelectedFace: Integer;
      const ATires: TI3dTireState): Integer;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Coordinates,
  DelphiDoom.Models.I3d.Palette;

const
  /// <summary>No texture has been selected yet (the old $FFFFFFFF)</summary>
  NO_TEXTURE = -2;
  /// <summary>The target is drawing a flat color</summary>
  FLAT_COLOR = -1;

{ TI3dModelRenderer }

function TI3dModelRenderer.Render(const AModel: II3dModel; const ATarget: II3dRenderTarget;
  const APlacement: TModelPlacement; const ASelectedFace: Integer;
  const ATires: TI3dTireState): Integer;
var
  LHeader: TI3dHeader;
  LFaces: TArray<TI3dFace>;
  LMaterial: TI3dMaterial;
  LColor: TI3dColor3f;
  LHasTires: Boolean;
  LTireBox: TI3dTireBox;
  LTireId: Integer;
  LLastTexture: Integer;
  LFace, LCorner: Integer;
  LU, LV: Single;
  LCenterX, LCenterY, LCenterZ: Single;
  LTurns: Boolean;
begin
  Result := 0;
  LHeader := AModel.Header;
  LFaces := AModel.GetFaces;
  LHasTires := AModel.HasTires;
  LLastTexture := NO_TEXTURE;

  for LFace := 0 to High(LFaces) do
  begin
    if not LFaces[LFace].Visible then
      Continue;
    if LFace = ASelectedFace then
      Continue;

    if LFaces[LFace].MaterialIndex >= 0 then
    begin
      LMaterial := AModel.Materials[LFaces[LFace].MaterialIndex];
      if LMaterial.TextureIndex >= 0 then
      begin
        ATarget.SetTexturing(True);
        if LMaterial.TextureIndex <> LLastTexture then
        begin
          ATarget.Color4f(1.0, 1.0, 1.0, 1.0);
          ATarget.BindTexture(LMaterial.TextureIndex);
          LLastTexture := LMaterial.TextureIndex;
        end;
      end
      else
      begin
        ATarget.SetTexturing(False);
        LLastTexture := FLAT_COLOR;
        // the color of the face (a correction can change it for one face)
        LColor := TI3dPalette.Color3f(LFaces[LFace].Color);
        if LMaterial.Flags and I3D_MATERIAL_TRANSLUCENT <> 0 then
          ATarget.Color4f(LColor.R, LColor.G, LColor.B, 0.5)
        else
          ATarget.Color4f(LColor.R, LColor.G, LColor.B, 1.0);
      end;
    end
    else
    begin
      ATarget.SetTexturing(False);
      LLastTexture := FLAT_COLOR;
      ATarget.Color4f(1.0, 1.0, 1.0, 1.0);
    end;

    LTurns := LHasTires and (LFace < I3D_TIRE_FACE_COUNT);
    if LTurns then
    begin
      LTireId := LFace div I3D_FACES_PER_TIRE;
      LTireBox := AModel.Tires[LTireId];
      LCenterX := TI3dCoordinates.WorldX(LHeader, APlacement, LTireBox.CenterX);
      LCenterY := TI3dCoordinates.WorldY(LHeader, APlacement, LTireBox.CenterY);
      LCenterZ := TI3dCoordinates.WorldZ(LHeader, APlacement, LTireBox.CenterZ);
      ATarget.PushMatrix;
      ATarget.Translatef(LCenterX, LCenterY, LCenterZ);
      // only the front tires (0 and 1) steer
      if LTireId < 2 then
        ATarget.Rotatef(ATires.Angle, 0.0, 1.0, 0.0);
      ATarget.Rotatef(ATires.Rotation[LTireId], 1.0, 0.0, 0.0);
      ATarget.Translatef(-LCenterX, -LCenterY, -LCenterZ);
    end;

    ATarget.BeginPrimitive(I3D_PRIMITIVE_TRIANGLE_FAN);
    for LCorner := 0 to High(LFaces[LFace].Vertices) do
    begin
      TI3dCoordinates.TextureToGl(LFaces[LFace].Vertices[LCorner].TextureX,
        LFaces[LFace].Vertices[LCorner].TextureY, LU, LV);
      ATarget.TexCoord2f(LU, LV);
      ATarget.Vertex3f(
        TI3dCoordinates.WorldX(LHeader, APlacement, LFaces[LFace].Vertices[LCorner].X),
        TI3dCoordinates.WorldY(LHeader, APlacement, LFaces[LFace].Vertices[LCorner].Y),
        TI3dCoordinates.WorldZ(LHeader, APlacement, LFaces[LFace].Vertices[LCorner].Z));
    end;
    ATarget.EndPrimitive;

    if LTurns then
      ATarget.PopMatrix;

    // a face of fewer than three vertexes counts negative, as in the old code
    Inc(Result, Length(LFaces[LFace].Vertices) - 2);
  end;
  ATarget.SetTexturing(True);
  ATarget.ResetTextureCache;
end;

end.
