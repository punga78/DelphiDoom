//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - where the polygons of the flats go
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

unit DelphiDoom.Engine.GlLevel.FlatLoopSink;

interface

uses
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>The polygons go to the vertex arrays and to the loops of the sectors of the renderer (gl_render)</summary>
  TEngineGlFlatLoopSink = class(TInterfacedObject, IGlFlatLoopSink)
  public
    procedure AddLoop(const ASectorId: Integer; const APoints: PGlFixedPoint; const ACount: Integer);
  end;

implementation

uses
  gl_render;

{ TEngineGlFlatLoopSink }

procedure TEngineGlFlatLoopSink.AddLoop(const ASectorId: Integer; const APoints: PGlFixedPoint;
  const ACount: Integer);
begin
  gld_AddFlatLoop(ASectorId, APoints, ACount);
end;

end.
