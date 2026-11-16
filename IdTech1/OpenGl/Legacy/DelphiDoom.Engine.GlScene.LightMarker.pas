//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the dynamic lights and shadows of the sprites of a frame
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

unit DelphiDoom.Engine.GlScene.LightMarker;

interface

uses
  r_dynlights,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.Engine.GlScene.Types;

type
  /// <summary>
  ///   Puts the dynamic lights of a sprite, and its shadow, in the buffer of the lights to sort and draw
  ///   (it was gld_MarkDLights and gld_MarkDShadow of gl_render.pas): the same items, in the same order
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per sprite of every frame). The buffer is the one of the renderer
  ///   (dlbuffer, numdlitems of r_dynlights: gl_render sorts and draws it, gl_lightmaps reads it), the camera
  ///   is the one gld_StartDrawScene filled. One call to the cache of the lights per light of a sprite, as
  ///   before
  /// </remarks>
  TEngineGlSceneLightMarker = class(TObject)
  strict private
    FDynLights: IDynLightRenderCache;
    class function NewItem: Pdlsortitem_t; static;
  public
    /// <exception cref="EArgumentNilException">The cache is nil</exception>
    constructor Create(const ADynLights: IDynLightRenderCache);
    /// <summary>The lights the state of the sprite has for the type of its mobj</summary>
    procedure MarkLights(const ASprite: PGLSprite);
    /// <summary>The shadow under the sprite, as wide as its mobj</summary>
    procedure MarkShadow(const ASprite: PGLSprite);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  m_fixed,
  p_tick,
  gl_defs,
  gl_shadows;

{ TEngineGlSceneLightMarker }

constructor TEngineGlSceneLightMarker.Create(const ADynLights: IDynLightRenderCache);
begin
  inherited Create;
  if not Assigned(ADynLights) then
    raise EArgumentNilException.Create('ADynLights');
  FDynLights := ADynLights;
end;

class function TEngineGlSceneLightMarker.NewItem: Pdlsortitem_t;
var
  LOldCount: Integer;
begin
  if numdlitems >= realdlitems then
  begin
    LOldCount := realdlitems;
    realdlitems := numdlitems + 32;
    realloc(pointer(dlbuffer), LOldCount * SizeOf(dlsortitem_t), realdlitems * SizeOf(dlsortitem_t));
  end;

  Result := @dlbuffer[numdlitems];
end;

procedure TEngineGlSceneLightMarker.MarkShadow(const ASprite: PGLSprite);
var
  dx, dy, dz: single;
  xdist, ydist, zdist: single;
  LItem: Pdlsortitem_t;
begin
  xdist := camera.position[0] - ASprite.x;
  ydist := camera.position[1] - ASprite.y;
  zdist := camera.position[2] - ASprite.z;

  LItem := NewItem;
  LItem.l := gld_GetDynamicShadow(ASprite.mo.info.radius div FRACUNIT);
  dx := xdist;
  dy := ydist;
  dz := zdist;
  LItem.squaredist := dx * dx + dy * dy + dz * dz;
  LItem.x := ASprite.x;
  LItem.y := ASprite.mo.floorz / MAP_SCALE;
  LItem.z := ASprite.z;
  inc(numdlitems);
end;

procedure TEngineGlSceneLightMarker.MarkLights(const ASprite: PGLSprite);
var
  LLight: PGLDRenderLight;
  LIndex: Integer;
  dx, dy, dz: single;
  xdist, ydist, zdist: single;
  LItem: Pdlsortitem_t;
begin
  if ASprite.dlights = nil then
    Exit;

  xdist := camera.position[0] - ASprite.x;
  ydist := camera.position[1] - ASprite.y;
  zdist := camera.position[2] - ASprite.z;

  for LIndex := 0 to ASprite.dlights.Count - 1 do
    if ASprite.dlights[LIndex].num1 = ASprite.mo._type then
    begin
      LLight := FDynLights.GetLight(ASprite.dlights[LIndex].num2, leveltime);
      LItem := NewItem;
      LItem.l := LLight;
      dx := xdist - LLight.x;
      dy := ydist - LLight.y;
      dz := zdist - LLight.z;
      LItem.squaredist := dx * dx + dy * dy + dz * dz;
      LItem.x := ASprite.x + LLight.x;
      LItem.y := ASprite.y + LLight.y;
      LItem.z := ASprite.z + LLight.z;
      inc(numdlitems);
    end;
end;

end.
