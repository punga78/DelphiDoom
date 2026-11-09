{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the OpenGL calls of a procedural model                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Models.Renderer;

interface

uses
  DelphiDoom.Models.Intf;

type
  /// <summary>
  ///   The renderer that Libs\Models plays a procedural model on: every call is the OpenGL call
  ///   of the old DoRenderFrame. A model is played once for each frame, into a display list,
  ///   so the interface calls are not on the path of the drawing of a frame.
  /// </summary>
  TEngineModelRenderer = class(TInterfacedObject, IModelRenderer)
  public
    procedure BeginPrimitive(const AMode: Integer);
    procedure EndPrimitive;
    procedure TexCoord2f(const AU, AV: Single);
    procedure Vertex3f(const AX, AY, AZ: Single);
    procedure Color3f(const AR, AG, AB: Single);
    procedure Color4f(const AR, AG, AB, AA: Single);
    procedure Normal3f(const ANX, ANY, ANZ: Single);
    procedure MatrixMode(const AMode: Integer);
    procedure PushMatrix;
    procedure PopMatrix;
    procedure Translatef(const AX, AY, AZ: Single);
    procedure Rotatef(const AAngle, AX, AY, AZ: Single);
    procedure LoadIdentity;
    procedure Scalef(const AX, AY, AZ: Single);
  end;

implementation

uses
  dglOpenGL;

{ TEngineModelRenderer }

procedure TEngineModelRenderer.BeginPrimitive(const AMode: Integer);
begin
  glBegin(AMode);
end;

procedure TEngineModelRenderer.EndPrimitive;
begin
  glEnd;
end;

procedure TEngineModelRenderer.TexCoord2f(const AU, AV: Single);
begin
  glTexCoord2f(AU, AV);
end;

procedure TEngineModelRenderer.Vertex3f(const AX, AY, AZ: Single);
begin
  glVertex3f(AX, AY, AZ);
end;

procedure TEngineModelRenderer.Color3f(const AR, AG, AB: Single);
begin
  glColor3f(AR, AG, AB);
end;

procedure TEngineModelRenderer.Color4f(const AR, AG, AB, AA: Single);
begin
  glColor4f(AR, AG, AB, AA);
end;

procedure TEngineModelRenderer.Normal3f(const ANX, ANY, ANZ: Single);
begin
  glNormal3f(ANX, ANY, ANZ);
end;

procedure TEngineModelRenderer.MatrixMode(const AMode: Integer);
begin
  glMatrixMode(AMode);
end;

procedure TEngineModelRenderer.PushMatrix;
begin
  glPushMatrix;
end;

procedure TEngineModelRenderer.PopMatrix;
begin
  glPopMatrix;
end;

procedure TEngineModelRenderer.Translatef(const AX, AY, AZ: Single);
begin
  glTranslatef(AX, AY, AZ);
end;

procedure TEngineModelRenderer.Rotatef(const AAngle, AX, AY, AZ: Single);
begin
  glRotatef(AAngle, AX, AY, AZ);
end;

procedure TEngineModelRenderer.LoadIdentity;
begin
  glLoadIdentity;
end;

procedure TEngineModelRenderer.Scalef(const AX, AY, AZ: Single);
begin
  glScalef(AX, AY, AZ);
end;

end.
