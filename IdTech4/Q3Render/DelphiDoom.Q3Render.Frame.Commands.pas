{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the render       }
{  commands                                                                    }
{                                                                              }
{  renderCommandList_t of renderer\tr_local.h: the commands that the front end  }
{  leaves for the backend (RC_SET_COLOR, RC_STRETCH_PIC, RC_DRAW_SURFS,        }
{  RC_DRAW_BUFFER, RC_SWAP_BUFFERS) as records in a list, and the entry points }
{  of tr_cmds.c that make them (RE_BeginFrame, RE_EndFrame, RE_SetColor,       }
{  RE_StretchPic, R_AddDrawSurfCmd). Based on the Quake III Arena GPL Source   }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Frame.Commands;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Q3Render.Scene.Types;

type
  TQ3RenderCommandKind = (rcSetColor, rcStretchPic, rcDrawSurfs, rcDrawBuffer, rcSwapBuffers);

  /// <summary>
  ///   One command. A draw surfaces command holds the drawSurfs of the view as the sort left them (a copy: the front
  ///   end reuses its array), the view, the refdef and the entities of the scene (the backend looks them up by the
  ///   entity number of the sort key)
  /// </summary>
  TQ3RenderCommand = record
    Kind: TQ3RenderCommandKind;
    Color: array[0..3] of Single;
    /// <summary>The index of the shader in the shader table</summary>
    Shader: Integer;
    X, Y, W, H, S1, T1, S2, T2: Single;
    View: TQ3FrontViewParms;
    RefDef: TQ3RefDef;
    FloatTime: Single;
    DrawSurfs: TArray<TQ3DrawSurf>;
    Entities: TArray<TQ3RefEntity>;
    /// <summary>The polygons of the scene (srfPoly_t: a drawSurf of kind skPoly indexes them)</summary>
    Polys: TArray<TQ3ScenePoly>;
    /// <summary>refdef.dlights of the scene (what the dynamic light pass reads)</summary>
    Dlights: TArray<TQ3DynamicLight>;
    /// <summary>The buffer of a draw buffer command: GL_BACK</summary>
    Buffer: Integer;
  end;

  /// <summary>The list of commands of a frame; it is emptied when the frame ends</summary>
  TQ3CommandList = class
  strict private
    FCommands: TList<TQ3RenderCommand>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Count: Integer;
    function Item(AIndex: Integer): TQ3RenderCommand;
    /// <summary>RE_BeginFrame: the draw buffer command</summary>
    procedure AddDrawBuffer;
    /// <summary>RE_SetColor: nil is white</summary>
    procedure AddSetColor(const AColor: TArray<Single>);
    /// <summary>RE_StretchPic</summary>
    procedure AddStretchPic(AShader: Integer; AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single);
    /// <summary>R_AddDrawSurfCmd</summary>
    procedure AddDrawSurfs(const AView: TQ3FrontViewParms; const ARefDef: TQ3RefDef;
      const ASurfaces: TArray<TQ3DrawSurf>; const AEntities: TArray<TQ3RefEntity>;
      const APolys: TArray<TQ3ScenePoly>; const ADlights: TArray<TQ3DynamicLight>);
    /// <summary>RE_EndFrame: the swap buffers command</summary>
    procedure AddSwapBuffers;
  end;

implementation

const
  // GL_BACK
  DrawBufferBack = $0405;
  // 0.001f of the original
  Thousandth: Single = 0.001;

constructor TQ3CommandList.Create;
begin
  inherited Create;
  FCommands := TList<TQ3RenderCommand>.Create;
end;

destructor TQ3CommandList.Destroy;
begin
  FCommands.Free;
  inherited Destroy;
end;

procedure TQ3CommandList.Clear;
begin
  FCommands.Clear;
end;

function TQ3CommandList.Count: Integer;
begin
  Result := FCommands.Count;
end;

function TQ3CommandList.Item(AIndex: Integer): TQ3RenderCommand;
begin
  Result := FCommands[AIndex];
end;

procedure TQ3CommandList.AddDrawBuffer;
var
  LCommand: TQ3RenderCommand;
begin
  LCommand := Default(TQ3RenderCommand);
  LCommand.Kind := rcDrawBuffer;
  LCommand.Buffer := DrawBufferBack;
  FCommands.Add(LCommand);
end;

procedure TQ3CommandList.AddSetColor(const AColor: TArray<Single>);
var
  LCommand: TQ3RenderCommand;
  LIndex: Integer;
begin
  LCommand := Default(TQ3RenderCommand);
  LCommand.Kind := rcSetColor;
  for LIndex := 0 to 3 do
    if Length(AColor) = 4 then
      LCommand.Color[LIndex] := AColor[LIndex]
    else
      LCommand.Color[LIndex] := 1;
  FCommands.Add(LCommand);
end;

procedure TQ3CommandList.AddStretchPic(AShader: Integer; AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single);
var
  LCommand: TQ3RenderCommand;
begin
  LCommand := Default(TQ3RenderCommand);
  LCommand.Kind := rcStretchPic;
  LCommand.Shader := AShader;
  LCommand.X := AX;
  LCommand.Y := AY;
  LCommand.W := AWidth;
  LCommand.H := AHeight;
  LCommand.S1 := AS1;
  LCommand.T1 := AT1;
  LCommand.S2 := AS2;
  LCommand.T2 := AT2;
  FCommands.Add(LCommand);
end;

procedure TQ3CommandList.AddDrawSurfs(const AView: TQ3FrontViewParms; const ARefDef: TQ3RefDef;
  const ASurfaces: TArray<TQ3DrawSurf>; const AEntities: TArray<TQ3RefEntity>; const APolys: TArray<TQ3ScenePoly>;
  const ADlights: TArray<TQ3DynamicLight>);
var
  LCommand: TQ3RenderCommand;
begin
  LCommand := Default(TQ3RenderCommand);
  LCommand.Kind := rcDrawSurfs;
  LCommand.Polys := Copy(APolys);
  LCommand.Dlights := Copy(ADlights);
  LCommand.View := AView;
  LCommand.RefDef := ARefDef;
  // refdef.floatTime = time * 0.001f
  LCommand.FloatTime := ARefDef.Time * Thousandth;
  LCommand.DrawSurfs := ASurfaces;
  LCommand.Entities := AEntities;
  FCommands.Add(LCommand);
end;

procedure TQ3CommandList.AddSwapBuffers;
var
  LCommand: TQ3RenderCommand;
begin
  LCommand := Default(TQ3RenderCommand);
  LCommand.Kind := rcSwapBuffers;
  FCommands.Add(LCommand);
end;

end.
