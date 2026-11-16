//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the BSP of the level for the carver of the flats
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

unit DelphiDoom.Engine.GlLevel.FlatWorld;

interface

uses
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>The nodes, subsectors and segs of the level (nodes, subsectors, segs of p_setup), read at each call</summary>
  TEngineGlFlatWorld = class(TInterfacedObject, IGlFlatWorld)
  public
    function GetSubsectorCount: Integer;
    function GetNode(const AIndex: Integer): TGlCarverNode;
    function GetSubsector(const AIndex: Integer): TGlCarverSubsector;
    function GetSeg(const AIndex: Integer): TGlCarverSeg;
  end;

implementation

uses
  p_setup;

{ TEngineGlFlatWorld }

function TEngineGlFlatWorld.GetSubsectorCount: Integer;
begin
  Result := numsubsectors;
end;

function TEngineGlFlatWorld.GetNode(const AIndex: Integer): TGlCarverNode;
begin
  Result.Line.X := nodes[AIndex].x;
  Result.Line.Y := nodes[AIndex].y;
  Result.Line.DX := nodes[AIndex].dx;
  Result.Line.DY := nodes[AIndex].dy;
  // the children are 32 bit words: the old code passed them as integers
  Result.Children[0] := Integer(nodes[AIndex].children[0]);
  Result.Children[1] := Integer(nodes[AIndex].children[1]);
end;

function TEngineGlFlatWorld.GetSubsector(const AIndex: Integer): TGlCarverSubsector;
begin
  Result.SectorId := subsectors[AIndex].sector.iSectorID;
  Result.FirstLine := subsectors[AIndex].firstline;
  Result.LineCount := subsectors[AIndex].numlines;
end;

function TEngineGlFlatWorld.GetSeg(const AIndex: Integer): TGlCarverSeg;
begin
  Result.Start.X := segs[AIndex].v1.x;
  Result.Start.Y := segs[AIndex].v1.y;
  Result.Finish.X := segs[AIndex].v2.x;
  Result.Finish.Y := segs[AIndex].v2.y;
end;

end.
