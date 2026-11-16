//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - sorts the dynamic lights of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.LightSorter;

interface

type
  /// <summary>
  ///   Sorts the buffer of the dynamic lights of the frame (dlbuffer, numdlitems of r_dynlights) by the square
  ///   distance from the camera, the closer light first (it was gld_SortDlights of gl_render.pas): the same
  ///   quick sort, so lights at the same distance end in the same order as before
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method, called once per frame. It holds nothing: the buffer
  ///   is the one the light marker fills and gl_lightmaps reads
  /// </remarks>
  TEngineGlSceneLightSorter = class(TObject)
  strict private
    class procedure QuickSort(ALeft, ARight: Integer); static;
  public
    /// <summary>Sorts the lights of the buffer; nothing if it is empty</summary>
    procedure Sort;
  end;

implementation

uses
  r_dynlights;

{ TEngineGlSceneLightSorter }

class procedure TEngineGlSceneLightSorter.QuickSort(ALeft, ARight: Integer);
var
  i, j: Integer;
  tmp: dlsortitem_t;
  squaredist: Single;
begin
  repeat
    i := ALeft;
    j := ARight;
    squaredist := dlbuffer[(ALeft + ARight) shr 1].squaredist;
    repeat
      while dlbuffer[i].squaredist < squaredist do
        inc(i);
      while dlbuffer[j].squaredist > squaredist do
        dec(j);
      if i <= j then
      begin
        tmp := dlbuffer[i];
        dlbuffer[i] := dlbuffer[j];
        dlbuffer[j] := tmp;
        inc(i);
        dec(j);
      end;
    until i > j;
    if ALeft < j then
      QuickSort(ALeft, j);
    ALeft := i;
  until i >= ARight;
end;

procedure TEngineGlSceneLightSorter.Sort;
begin
  if numdlitems > 0 then
    QuickSort(0, numdlitems - 1);
end;

end.
