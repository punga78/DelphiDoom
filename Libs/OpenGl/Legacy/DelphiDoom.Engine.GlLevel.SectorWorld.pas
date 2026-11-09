//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the sectors and lines of the level for the preprocessor
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

unit DelphiDoom.Engine.GlLevel.SectorWorld;

interface

uses
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>
  ///   sectors, sides, lines and vertexes of p_setup, read at each call; it writes no_toptextures,
  ///   no_bottomtextures and LRF_ISOLATED (cold path: once per level)
  /// </summary>
  TEngineGlSectorWorld = class(TInterfacedObject, IGlSectorWorld)
  public
    function GetSectorCount: Integer;
    function GetVertexCount: Integer;
    function GetLineCount(const ASector: Integer): Integer;
    function GetLine(const ASector, ALine: Integer): TGlSectorLine;
    procedure SetNoTextures(const ASector: Integer; const ANoTop, ANoBottom: Boolean);
    procedure MarkIsolated(const ASector, ALine: Integer);
  end;

implementation

uses
  r_defs,
  p_setup;

{ TEngineGlSectorWorld }

function TEngineGlSectorWorld.GetSectorCount: Integer;
begin
  Result := numsectors;
end;

function TEngineGlSectorWorld.GetVertexCount: Integer;
begin
  Result := numvertexes;
end;

function TEngineGlSectorWorld.GetLineCount(const ASector: Integer): Integer;
begin
  Result := sectors[ASector].linecount;
end;

function TEngineGlSectorWorld.GetLine(const ASector, ALine: Integer): TGlSectorLine;
var
  LLine: Pline_t;
begin
  LLine := sectors[ASector].lines[ALine];
  Result.Vertex1 := (NativeInt(LLine.v1) - NativeInt(vertexes)) div SizeOf(vertex_t);
  Result.Vertex2 := (NativeInt(LLine.v2) - NativeInt(vertexes)) div SizeOf(vertex_t);
  Result.HasBothSides := (LLine.sidenum[0] <> -1) and (LLine.sidenum[1] <> -1);
  if Result.HasBothSides then
  begin
    Result.FrontTopTexture := sides[LLine.sidenum[0]].toptexture;
    Result.FrontBottomTexture := sides[LLine.sidenum[0]].bottomtexture;
    Result.BackTopTexture := sides[LLine.sidenum[1]].toptexture;
    Result.BackBottomTexture := sides[LLine.sidenum[1]].bottomtexture;
  end
  else
  begin
    Result.FrontTopTexture := 0;
    Result.FrontBottomTexture := 0;
    Result.BackTopTexture := 0;
    Result.BackBottomTexture := 0;
  end;
end;

procedure TEngineGlSectorWorld.SetNoTextures(const ASector: Integer; const ANoTop, ANoBottom: Boolean);
begin
  sectors[ASector].no_toptextures := ANoTop;
  sectors[ASector].no_bottomtextures := ANoBottom;
end;

procedure TEngineGlSectorWorld.MarkIsolated(const ASector, ALine: Integer);
var
  LLine: Pline_t;
begin
  LLine := sectors[ASector].lines[ALine];
  LLine.renderflags := LLine.renderflags or LRF_ISOLATED;
end;

end.
