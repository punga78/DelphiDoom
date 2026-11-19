{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the buffers of   }
{  a frame                                                                     }
{                                                                              }
{  The entities, dlights and polys that RE_AddRefEntityToScene,                }
{  RE_AddDynamicLightToScene and RE_AddPolyToScene of renderer\tr_scene.c      }
{  collect for the scenes of a frame, with their limits and the first of each  }
{  scene (RE_ClearScene). Based on the Quake III Arena GPL Source Code (id     }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Scene.Buffers;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Render.Types,
  DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>
  ///   What the scenes of a frame have added: the three lists (with the index of the first one of the scene that is
  ///   open) and the limits of the C (1022 entities, 32 dlights, r_maxpolys polys and r_maxpolyverts vertexes)
  /// </summary>
  TQ3SceneBuffers = class
  strict private
    FEntities: TList<TQ3RefEntity>;
    FDlights: TList<TQ3DynamicLight>;
    FPolys: TList<TQ3ScenePoly>;
    FFogs: TArray<TQ3WorldFog>;
    FFirstEntity: Integer;
    FFirstDlight: Integer;
    FFirstPoly: Integer;
    FPolyVertCount: Integer;
    FMaxPolys: Integer;
    FMaxPolyVerts: Integer;
    function FogIndexOf(const AVerts: TArray<TQ3PolyVert>): Integer;
  public
    constructor Create(AMaxPolys, AMaxPolyVerts: Integer);
    destructor Destroy; override;
    /// <summary>The fogs of the world that polys are tested against (world_t.fogs, entry 0 is no fog); empty if none</summary>
    procedure SetFogs(const AFogs: TArray<TQ3WorldFog>);
    /// <summary>R_ToggleSmpFrame: a new frame starts with empty buffers</summary>
    procedure ResetFrame;
    /// <summary>RE_ClearScene: the next scene starts after what is already added</summary>
    procedure ClearScene;
    /// <summary>RE_AddRefEntityToScene; a reType that does not exist is an error of the renderer (ERR_DROP)</summary>
    procedure AddEntity(const AEntity: TQ3RefEntity);
    /// <summary>RE_AddDynamicLightToScene</summary>
    procedure AddLight(const AOrigin: TQ3Vec3; AIntensity, ARed, AGreen, ABlue: Single; AAdditive: Boolean);
    /// <summary>
    ///   RE_AddPolyToScene for ANumPolys polygons of ANumVerts vertexes each (AVerts has them one after the other);
    ///   the shader is a table index (the check for the null shader is the caller's)
    /// </summary>
    procedure AddPolys(AShader, ANumVerts: Integer; const AVerts: TArray<TQ3PolyVert>; ANumPolys: Integer);
    function EntityCount: Integer;
    function DlightCount: Integer;
    function PolyCount: Integer;
    /// <summary>The entities, dlights and polys of the open scene (from the first of it)</summary>
    function SceneEntities: TArray<TQ3RefEntity>;
    function SceneDlights: TArray<TQ3DynamicLight>;
    function ScenePolys: TArray<TQ3ScenePoly>;
    /// <summary>r_firstScene* = r_num*: the scene that was rendered is closed</summary>
    procedure CloseScene;
  end;

implementation

resourcestring
  SQ3RenderBadReType = 'RE_AddRefEntityToScene: bad reType %d';

constructor TQ3SceneBuffers.Create(AMaxPolys, AMaxPolyVerts: Integer);
begin
  inherited Create;
  FEntities := TList<TQ3RefEntity>.Create;
  FDlights := TList<TQ3DynamicLight>.Create;
  FPolys := TList<TQ3ScenePoly>.Create;
  FMaxPolys := AMaxPolys;
  FMaxPolyVerts := AMaxPolyVerts;
end;

destructor TQ3SceneBuffers.Destroy;
begin
  FEntities.Free;
  FDlights.Free;
  FPolys.Free;
  inherited Destroy;
end;

procedure TQ3SceneBuffers.SetFogs(const AFogs: TArray<TQ3WorldFog>);
begin
  FFogs := AFogs;
end;

procedure TQ3SceneBuffers.ResetFrame;
begin
  FEntities.Clear;
  FDlights.Clear;
  FPolys.Clear;
  FFirstEntity := 0;
  FFirstDlight := 0;
  FFirstPoly := 0;
  FPolyVertCount := 0;
end;

procedure TQ3SceneBuffers.ClearScene;
begin
  FFirstDlight := FDlights.Count;
  FFirstEntity := FEntities.Count;
  FFirstPoly := FPolys.Count;
end;

procedure TQ3SceneBuffers.CloseScene;
begin
  FFirstDlight := FDlights.Count;
  FFirstEntity := FEntities.Count;
  FFirstPoly := FPolys.Count;
end;

procedure TQ3SceneBuffers.AddEntity(const AEntity: TQ3RefEntity);
begin
  // the check of bug 402: no more than ENTITYNUM_WORLD entities
  if FEntities.Count >= Q3_ENTITYNUM_WORLD then
    Exit;
  if (AEntity.ReType < 0) or (AEntity.ReType >= RT_MAX_REF_ENTITY_TYPE) then
    raise EQ3RenderException.CreateFmt(SQ3RenderBadReType, [AEntity.ReType]);
  FEntities.Add(AEntity);
end;

procedure TQ3SceneBuffers.AddLight(const AOrigin: TQ3Vec3; AIntensity, ARed, AGreen, ABlue: Single;
  AAdditive: Boolean);
var
  LLight: TQ3DynamicLight;
begin
  if FDlights.Count >= Q3_MAX_DLIGHTS then
    Exit;
  if AIntensity <= 0 then
    Exit;
  LLight.Origin := AOrigin;
  LLight.Radius := AIntensity;
  LLight.Color[0] := ARed;
  LLight.Color[1] := AGreen;
  LLight.Color[2] := ABlue;
  LLight.Additive := Ord(AAdditive);
  FDlights.Add(LLight);
end;

function TQ3SceneBuffers.FogIndexOf(const AVerts: TArray<TQ3PolyVert>): Integer;
var
  LMins, LMaxs: TQ3Vec3;
  LIndex, LFog, LAxis: Integer;
  LInside: Boolean;
begin
  // no world, or one fog: the poly is not in a fog volume
  if Length(FFogs) <= 1 then
    Exit(0);
  LMins := AVerts[0].Xyz;
  LMaxs := AVerts[0].Xyz;
  for LIndex := 1 to High(AVerts) do
    for LAxis := 0 to 2 do
    begin
      if AVerts[LIndex].Xyz[LAxis] < LMins[LAxis] then
        LMins[LAxis] := AVerts[LIndex].Xyz[LAxis];
      if AVerts[LIndex].Xyz[LAxis] > LMaxs[LAxis] then
        LMaxs[LAxis] := AVerts[LIndex].Xyz[LAxis];
    end;
  for LFog := 1 to High(FFogs) do
  begin
    LInside := True;
    for LAxis := 0 to 2 do
      if not ((LMaxs[LAxis] >= FFogs[LFog].Mins[LAxis]) and (LMins[LAxis] <= FFogs[LFog].Maxs[LAxis])) then
        LInside := False;
    if LInside then
      Exit(LFog);
  end;
  Result := 0;
end;

procedure TQ3SceneBuffers.AddPolys(AShader, ANumVerts: Integer; const AVerts: TArray<TQ3PolyVert>;
  ANumPolys: Integer);
var
  LPoly: Integer;
  LItem: TQ3ScenePoly;
begin
  for LPoly := 0 to ANumPolys - 1 do
  begin
    if (FPolyVertCount + ANumVerts > FMaxPolyVerts) or (FPolys.Count >= FMaxPolys) then
      Exit;
    LItem.HShader := AShader;
    SetLength(LItem.Verts, ANumVerts);
    if ANumVerts > 0 then
      Move(AVerts[LPoly * ANumVerts], LItem.Verts[0], ANumVerts * SizeOf(TQ3PolyVert));
    FPolys.Add(LItem);
    Inc(FPolyVertCount, ANumVerts);
    if ANumVerts > 0 then
      LItem.FogIndex := FogIndexOf(LItem.Verts)
    else
      LItem.FogIndex := 0;
    FPolys[FPolys.Count - 1] := LItem;
  end;
end;

function TQ3SceneBuffers.EntityCount: Integer;
begin
  Result := FEntities.Count;
end;

function TQ3SceneBuffers.DlightCount: Integer;
begin
  Result := FDlights.Count;
end;

function TQ3SceneBuffers.PolyCount: Integer;
begin
  Result := FPolys.Count;
end;

function TQ3SceneBuffers.SceneEntities: TArray<TQ3RefEntity>;
begin
  Result := FEntities.ToArray;
  Result := Copy(Result, FFirstEntity, Length(Result) - FFirstEntity);
end;

function TQ3SceneBuffers.SceneDlights: TArray<TQ3DynamicLight>;
begin
  Result := FDlights.ToArray;
  Result := Copy(Result, FFirstDlight, Length(Result) - FFirstDlight);
end;

function TQ3SceneBuffers.ScenePolys: TArray<TQ3ScenePoly>;
begin
  Result := FPolys.ToArray;
  Result := Copy(Result, FFirstPoly, Length(Result) - FFirstPoly);
end;

end.
