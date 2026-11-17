//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the OpenGL part of the loading of a level
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.GlLevel.Preprocessor;

interface

uses
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlScene.FlatCollector,
  DelphiDoom.Engine.GlScene.WallCollector;

type
  /// <summary>
  ///   What the OpenGL renderer does when a level is loaded (it was gld_PreprocessLevel, gld_PreprocessSectors,
  ///   gld_AddGlobalVertexes, gld_AddFlatLoop and gld_SkyTextureHack of gl_render.pas): precaches the textures,
  ///   builds the vertex arrays and the loops of the flats of the sectors, and resets the collectors and the
  ///   draw list of the frame
  /// </summary>
  /// <remarks>
  ///   Cold path (once per level). A plain class: the arrays it fills (gld_vertexes, gld_texcoords, sectorloops)
  ///   stay in gl_render because the painters of the scene read them for every flat. It does not own the draw
  ///   list nor the collectors (gl_render does)
  /// </remarks>
  TEngineGlLevelPreprocessor = class(TObject)
  strict private
    FDrawList: TGlSceneDrawList;
    FFlats: TEngineGlSceneFlatCollector;
    FWalls: TEngineGlSceneWallCollector;
    FMaxVertexes: Integer;
    FNumVertexes: Integer;
    procedure AddGlobalVertexes(const ACount: Integer);
    procedure PreprocessSectors(const ACarver: IGlFlatCarver; const ASectors: IGlSectorPreprocessor);
    {$IFDEF DOOM}
    class procedure SkyTextureHack; static;
    {$ENDIF}
  public
    /// <param name="ADrawList">The list of the frame; not owned</param>
    /// <param name="AFlats">The collector of the flats; not owned</param>
    /// <param name="AWalls">The collector of the walls; not owned</param>
    /// <exception cref="EArgumentNilException">A dependency is nil</exception>
    constructor Create(const ADrawList: TGlSceneDrawList; const AFlats: TEngineGlSceneFlatCollector;
      const AWalls: TEngineGlSceneWallCollector);
    /// <summary>Prepares the renderer for the level that was just loaded</summary>
    procedure Preprocess(const ACarver: IGlFlatCarver; const ASectors: IGlSectorPreprocessor);
    /// <summary>A convex polygon of a flat (a fan of points in fixed point) goes to the vertex arrays and to the loops of its sector</summary>
    procedure AddFlatLoop(const ASectorId: Integer; const APoints: PGlFixedPoint; const ACount: Integer);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  dglOpenGL,
  doomstat,
  g_game,
  gl_defs,
  gl_types,
  gl_tex,
  i_system,
  m_fixed,
  nd_main,
  p_setup,
  r_defs,
  {$IFDEF DOOM}
  r_plane,
  r_sky,
  {$ENDIF}
  z_zone,
  DelphiDoom.Engine.GlScene.Types,
  gl_render;

{ TEngineGlLevelPreprocessor }

constructor TEngineGlLevelPreprocessor.Create(const ADrawList: TGlSceneDrawList;
  const AFlats: TEngineGlSceneFlatCollector; const AWalls: TEngineGlSceneWallCollector);
begin
  inherited Create;
  if not Assigned(ADrawList) then
    raise EArgumentNilException.Create('ADrawList');
  if not Assigned(AFlats) then
    raise EArgumentNilException.Create('AFlats');
  if not Assigned(AWalls) then
    raise EArgumentNilException.Create('AWalls');
  FDrawList := ADrawList;
  FFlats := AFlats;
  FWalls := AWalls;
end;

procedure TEngineGlLevelPreprocessor.AddGlobalVertexes(const ACount: Integer);
begin
  if (FNumVertexes + ACount) >= FMaxVertexes then
  begin
    FMaxVertexes := FMaxVertexes + ACount + 1024;
    gld_vertexes := Z_Realloc(gld_vertexes, FMaxVertexes * SizeOf(GLVertex), PU_LEVEL, nil);
    gld_texcoords := Z_Realloc(gld_texcoords, FMaxVertexes * SizeOf(GLTexcoord), PU_LEVEL, nil);
  end;
end;

procedure TEngineGlLevelPreprocessor.AddFlatLoop(const ASectorId: Integer; const APoints: PGlFixedPoint;
  const ACount: Integer);
var
  LIndex: Integer;
  LPoint: PGlFixedPoint;
  LSector: PGLSector;
  LLoop: PGLLoopDef;
  LVertex: PGLVertex;
begin
  AddGlobalVertexes(ACount);
  if (gld_vertexes <> nil) and (gld_texcoords <> nil) then
  begin
    LSector := @sectorloops[ASectorId];
    LSector.loops := Z_Realloc(LSector.loops, SizeOf(GLLoopDef) * (LSector.loopcount + 1), PU_LEVEL, nil);
    LLoop := @LSector.loops[LSector.loopcount];
    LLoop.mode := GL_TRIANGLE_FAN;
    LLoop.vertexcount := ACount;
    LLoop.vertexindex := FNumVertexes;
    Inc(LSector.loopcount);

    LPoint := APoints;
    for LIndex := 0 to ACount - 1 do
    begin
      gld_texcoords[FNumVertexes].u := (LPoint.X / FRACUNIT) / 64.0;
      gld_texcoords[FNumVertexes].v := (-LPoint.Y / FRACUNIT) / 64.0;
      LVertex := @gld_vertexes[FNumVertexes];
      LVertex.x := -LPoint.X / MAP_SCALE;
      LVertex.y := 0.0;
      LVertex.z := LPoint.Y / MAP_SCALE;
      Inc(FNumVertexes);
      Inc(LPoint);
    end;
  end;
end;

// This checks all sectors if they are closed and calls the carver to calculate the loops of every sector
// (the idea to check for closed sectors is from DEU)
procedure TEngineGlLevelPreprocessor.PreprocessSectors(const ACarver: IGlFlatCarver;
  const ASectors: IGlSectorPreprocessor);
var
  LSectorClosed: PBooleanArray;
begin
  LSectorClosed := Z_Malloc2(numsectors * SizeOf(Boolean), PU_LEVEL, nil);
  if LSectorClosed = nil then
    I_Error('gld_PreprocessSectors(): Not enough memory for array sectorclosed');
  ZeroMemory(LSectorClosed, SizeOf(Boolean) * numsectors);

  sectorloops := Z_Malloc2(numsectors * SizeOf(GLSector), PU_LEVEL, nil);
  if sectorloops = nil then
    I_Error('gld_PreprocessSectors(): Not enough memory for array sectorloops');
  ZeroMemory(sectorloops, numsectors * SizeOf(GLSector));

  FFlats.BeginLevel(numsectors);

  gld_vertexes := nil;
  gld_texcoords := nil;
  FMaxVertexes := 0;
  FNumVertexes := 0;
  AddGlobalVertexes(numvertexes * 2);

  ASectors.Preprocess;

  // figgi -- adapted for glnodes // JVAL
  if glnodesver = 0 then
    ACarver.CarveFlats(numnodes - 1,
      function(const sectorid: Integer): Boolean
      begin
        Result := LSectorClosed[sectorid];
      end)
  else
    ACarver.AddSubsectorLoops(
      function(const sectorid: Integer): Boolean
      begin
        Result := LSectorClosed[sectorid];
      end);

  Z_Free(LSectorClosed);
end;

{$IFDEF DOOM}
class procedure TEngineGlLevelPreprocessor.SkyTextureHack;
var
  LIndex: Integer;
  LSide, LLine: Integer;
begin
  for LIndex := 0 to numsectors - 1 do
    if sectors[LIndex].sky and PL_SKYFLAT <> 0 then
    begin
      LLine := sectors[LIndex].sky and not PL_SKYFLAT;
      if LLine >= 0 then
        if LLine < numlines then
        begin
          LSide := lines[LLine].sidenum[0];
          if LSide >= 0 then
            if LSide < numsides then
            begin
              skytexture := sides[LSide].toptexture;
              Exit;
            end;
        end;
    end;
end;
{$ENDIF}

procedure TEngineGlLevelPreprocessor.Preprocess(const ACarver: IGlFlatCarver;
  const ASectors: IGlSectorPreprocessor);
begin
  if not Assigned(ASectors) then
    I_Error('gld_PreprocessSectors(): the sector preprocessor is not configured (ComposeEngine was not called)');
  if not Assigned(ACarver) then
    I_Error('gld_PreprocessSectors(): the flat carver is not configured (ComposeEngine was not called)');

  // preload graphics
  // JVAL
  // Precache if we have external textures
  {$IFDEF DOOM}
  SkyTextureHack;
  {$ENDIF}
  if TGameSession.Precache or externalpakspresent then
    gld_Precache;
  PreprocessSectors(ACarver, ASectors);
  FWalls.BeginLevel(numsegs);
  FDrawList.Release;
  glTexCoordPointer(2, GL_FLOAT, 0, gld_texcoords);
  glVertexPointer(3, GL_FLOAT, 0, gld_vertexes);
end;

end.
