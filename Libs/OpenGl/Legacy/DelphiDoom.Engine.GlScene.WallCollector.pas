//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - collects the walls of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.WallCollector;

interface

uses
  System.SysUtils,
  d_delphi,
  r_defs,
  gl_defs,
  DelphiDoom.GlScene.Types,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlScene.Types,
  DelphiDoom.Engine.GlScene.FlatCollector;

type
  /// <summary>
  ///   The segs the BSP walk meets go to the draw list of the frame as walls: upper, middle and lower
  ///   textures, sky, the sides of the 3d floors and the gaps to flood (it was gld_AddWall, gld_AddMidWall,
  ///   the CALC_* helpers and gld_PreprocessSegs of gl_render.pas): the same records, in the same order
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per seg of every frame), never through an interface. It reads the
  ///   level and the view of the engine (segs, sectors, sides, lines, extralight, usegamma, the sky) and
  ///   registers the textures with gl_tex. The arithmetic is the one of the old code, expression by
  ///   expression: the numbers given to OpenGL are the same bit by bit. Kept from the old code: a wall of sky
  ///   always has the flag GLDWF_SKY (the test for the flipped sky was behind a misspelt define), and the sky
  ///   texture of Doom is chosen with the sector the BSP walk is in. The differences between the games are
  ///   fields and flags their records have: they stay conditional because the records are different by
  ///   construction
  /// </remarks>
  TEngineGlSceneWallCollector = class(TObject)
  strict private
    const
      SMALL_DELTA = 0.001;
  strict private
    FDrawList: TGlSceneDrawList;
    FLightTable: PGlSceneLightTable;
    FFlats: TEngineGlSceneFlatCollector;
    FMarker: Byte;
    FYaw: float;
    FCameraZ: float;
    FSkyMet: Boolean;
    FSegAdded: TBytes;
    FSegs: array of TGLSeg;
    function LightLevel(const ALight: Integer): float;
    class procedure SetHeights(const AWall: PGLWall; var ALineHeight: float;
      const AFloorHeight, ACeilingHeight: Integer); static;
    class procedure SetSignedHeights(const AWall: PGLWall; var ALineHeight: float;
      const AFloorHeight, ACeilingHeight: Integer); static;
    class function OffsetUMiddle(const ATexture: PGLTexture; const ASeg: Pseg_t): float; static;
    class function OffsetUBottom(const ATexture: PGLTexture; const ASeg: Pseg_t): float; static;
    class function OffsetUTop(const ATexture: PGLTexture; const ASeg: Pseg_t): float; static;
    class function OffsetVMiddle(const ATexture: PGLTexture; const ASeg: Pseg_t): float; static;
    class function OffsetVBottom(const ATexture: PGLTexture; const ASeg: Pseg_t): float; static;
    class function OffsetVTop(const ATexture: PGLTexture; const ASeg: Pseg_t): float; static;
    class function OffsetVPegged(const ATexture: PGLTexture; const ASeg: Pseg_t;
      const AOffset: Integer): float; static;
    class procedure SetTopCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
      const ALineLength, ALineHeight: float); static;
    class procedure SetOneSidedCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
      const ALineLength, ALineHeight: float); static;
    class procedure SetThickSideCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
      const ALineLength, ALineHeight: float); static;
    class procedure SetBottomCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
      const ALineLength, ALineHeight: float; const AOffset: Integer); static;
    {$IFDEF DOOM}
    class function SkyTexture(const AWall: PGLWall): Integer; static;
    {$ENDIF}
    procedure SetSky(const AWall: PGLWall);
    procedure Append(const AWall: PGLWall);
    procedure AddMidWall(const ASeg: Pseg_t; const ASector, AMidSector: Psector_t);
  public
    /// <param name="ADrawList">The list of the frame; not owned</param>
    /// <param name="ALightTable">The light table of gl_render (gamma, light level)</param>
    /// <param name="AFlats">Gets the planes that fill the gap of a missing lower texture; not owned</param>
    /// <exception cref="EArgumentNilException">A dependency is nil</exception>
    constructor Create(const ADrawList: TGlSceneDrawList; const ALightTable: PGlSceneLightTable;
      const AFlats: TEngineGlSceneFlatCollector);
    /// <summary>A new level: the ends of its segs in OpenGL units, and no seg marked</summary>
    procedure BeginLevel(const ASegCount: Integer);
    /// <summary>A new frame: its counter, the yaw of the view in degrees and the height of the camera</summary>
    procedure BeginFrame(const AMarker: Byte; const AYaw, ACameraZ: float);
    /// <summary>The walls of a seg, once per frame; ASector is the sector of a polyobject seg</summary>
    procedure Add(const ASeg: Pseg_t; const AIsPolyObject: Boolean; const ASector: Psector_t);
    /// <summary>A wall of sky was added in this frame</summary>
    property SkyMet: Boolean read FSkyMet;
  end;

implementation

uses
  doomdata,
  m_fixed,
  v_video,
  p_setup,
  {$IFDEF DOOM}
  r_plane,
  {$ENDIF}
  {$IFDEF DOOM_OR_STRIFE}
  r_bsp,
  {$ENDIF}
  r_main,
  r_data,
  r_sky,
  gl_misc,
  gl_tex,
  DelphiDoom.GlScene.Light;

{ TEngineGlSceneWallCollector }

constructor TEngineGlSceneWallCollector.Create(const ADrawList: TGlSceneDrawList;
  const ALightTable: PGlSceneLightTable; const AFlats: TEngineGlSceneFlatCollector);
begin
  inherited Create;
  if not Assigned(ADrawList) then
    raise EArgumentNilException.Create('ADrawList');
  if not Assigned(ALightTable) then
    raise EArgumentNilException.Create('ALightTable');
  if not Assigned(AFlats) then
    raise EArgumentNilException.Create('AFlats');
  FDrawList := ADrawList;
  FLightTable := ALightTable;
  FFlats := AFlats;
end;

procedure TEngineGlSceneWallCollector.BeginLevel(const ASegCount: Integer);
var
  LIndex: Integer;
begin
  FSegAdded := nil;
  // SetLength of an empty array gives zeroes
  SetLength(FSegAdded, ASegCount);
  FSegs := nil;
  SetLength(FSegs, ASegCount);
  for LIndex := 0 to ASegCount - 1 do
  begin
    FSegs[LIndex].x1 := -segs[LIndex].v1.x / MAP_SCALE;
    FSegs[LIndex].z1 :=  segs[LIndex].v1.y / MAP_SCALE;
    FSegs[LIndex].x2 := -segs[LIndex].v2.x / MAP_SCALE;
    FSegs[LIndex].z2 :=  segs[LIndex].v2.y / MAP_SCALE;
    FSegs[LIndex].frontsector := segs[LIndex].frontsector;
    FSegs[LIndex].backsector := segs[LIndex].backsector;
  end;
end;

procedure TEngineGlSceneWallCollector.BeginFrame(const AMarker: Byte; const AYaw, ACameraZ: float);
begin
  FMarker := AMarker;
  FYaw := AYaw;
  FCameraZ := ACameraZ;
  FSkyMet := False;
end;

function TEngineGlSceneWallCollector.LightLevel(const ALight: Integer): float;
begin
  Result := TGlSceneLight.Level(FLightTable, usegamma, ALight);
end;

class procedure TEngineGlSceneWallCollector.SetHeights(const AWall: PGLWall; var ALineHeight: float;
  const AFloorHeight, ACeilingHeight: Integer);
begin
  AWall.ytop := ACeilingHeight / MAP_SCALE + SMALL_DELTA;
  AWall.ybottom := AFloorHeight / MAP_SCALE - SMALL_DELTA;
  ALineHeight := abs((ACeilingHeight - AFloorHeight) / FRACUNIT);
end;

class procedure TEngineGlSceneWallCollector.SetSignedHeights(const AWall: PGLWall; var ALineHeight: float;
  const AFloorHeight, ACeilingHeight: Integer);
begin
  AWall.ytop := ACeilingHeight / MAP_SCALE + SMALL_DELTA;
  AWall.ybottom := AFloorHeight / MAP_SCALE - SMALL_DELTA;
  ALineHeight := (ACeilingHeight - AFloorHeight) / FRACUNIT;
end;

class function TEngineGlSceneWallCollector.OffsetUMiddle(const ATexture: PGLTexture; const ASeg: Pseg_t): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.textureoffset + LSide.midtextureoffset + ASeg.offset) / FRACUNIT) * ATexture.inv_buffer_width;
end;

class function TEngineGlSceneWallCollector.OffsetUBottom(const ATexture: PGLTexture; const ASeg: Pseg_t): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.textureoffset + LSide.bottomtextureoffset + ASeg.offset) / FRACUNIT) * ATexture.inv_buffer_width;
end;

class function TEngineGlSceneWallCollector.OffsetUTop(const ATexture: PGLTexture; const ASeg: Pseg_t): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.textureoffset + LSide.toptextureoffset + ASeg.offset) / FRACUNIT) * ATexture.inv_buffer_width;
end;

class function TEngineGlSceneWallCollector.OffsetVMiddle(const ATexture: PGLTexture; const ASeg: Pseg_t): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.rowoffset + LSide.midrowoffset) / FRACUNIT) * ATexture.inv_buffer_height;
end;

class function TEngineGlSceneWallCollector.OffsetVBottom(const ATexture: PGLTexture; const ASeg: Pseg_t): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.rowoffset + LSide.bottomrowoffset) / FRACUNIT) * ATexture.inv_buffer_height;
end;

class function TEngineGlSceneWallCollector.OffsetVTop(const ATexture: PGLTexture; const ASeg: Pseg_t): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.rowoffset + LSide.toprowoffset) / FRACUNIT) * ATexture.inv_buffer_height;
end;

class function TEngineGlSceneWallCollector.OffsetVPegged(const ATexture: PGLTexture; const ASeg: Pseg_t;
  const AOffset: Integer): float;
var
  LSide: Pside_t;
begin
  LSide := ASeg.sidedef;
  Result := ((LSide.rowoffset + LSide.bottomrowoffset - AOffset) / FRACUNIT) * ATexture.inv_buffer_height;
end;

class procedure TEngineGlSceneWallCollector.SetTopCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
  const ALineLength, ALineHeight: float);
var
  LTexture: PGLTexture;
begin
  AWall.flag := GLDWF_TOP;
  LTexture := AWall.gltexture;
  AWall.ul := OffsetUTop(LTexture, ASeg);
  AWall.ur := AWall.ul + (ALineLength * LTexture.inv_buffer_width);
  if APegged then
  begin
    AWall.vb := OffsetVTop(LTexture, ASeg) + (LTexture.height / LTexture.tex_height);
    AWall.vt := AWall.vb - (ALineHeight * LTexture.inv_buffer_height);
  end
  else
  begin
    AWall.vt := OffsetVTop(LTexture, ASeg);
    AWall.vb := AWall.vt + (ALineHeight * LTexture.inv_buffer_height);
  end;
end;

class procedure TEngineGlSceneWallCollector.SetOneSidedCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
  const ALineLength, ALineHeight: float);
var
  LTexture: PGLTexture;
begin
  AWall.flag := GLDWF_M1S;
  LTexture := AWall.gltexture;
  AWall.ul := OffsetUMiddle(LTexture, ASeg);
  AWall.ur := AWall.ul + (ALineLength * LTexture.inv_buffer_width);
  if APegged then
  begin
    AWall.vb := OffsetVMiddle(LTexture, ASeg) + LTexture.heightscale;
    AWall.vt := AWall.vb - (ALineHeight * LTexture.inv_buffer_height);
  end
  else
  begin
    AWall.vt := OffsetVMiddle(LTexture, ASeg);
    AWall.vb := AWall.vt + (ALineHeight * LTexture.inv_buffer_height);
  end;
end;

class procedure TEngineGlSceneWallCollector.SetThickSideCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
  const ALineLength, ALineHeight: float);
var
  LTexture: PGLTexture;
begin
  AWall.flag := GLDWF_MTS;
  LTexture := AWall.gltexture;
  AWall.ul := OffsetUMiddle(LTexture, ASeg);
  AWall.ur := AWall.ul + (ALineLength * LTexture.inv_buffer_width);
  if APegged then
  begin
    AWall.vb := OffsetVMiddle(LTexture, ASeg) + LTexture.heightscale;
    AWall.vt := AWall.vb - (ALineHeight * LTexture.inv_buffer_height);
  end
  else
  begin
    AWall.vt := OffsetVMiddle(LTexture, ASeg);
    AWall.vb := AWall.vt + (ALineHeight * LTexture.inv_buffer_height);
  end;
end;

class procedure TEngineGlSceneWallCollector.SetBottomCoords(const AWall: PGLWall; const ASeg: Pseg_t; const APegged: Boolean;
  const ALineLength, ALineHeight: float; const AOffset: Integer);
var
  LTexture: PGLTexture;
begin
  AWall.flag := GLDWF_BOT;
  LTexture := AWall.gltexture;
  AWall.ul := OffsetUBottom(LTexture, ASeg);
  AWall.ur := AWall.ul + (ALineLength / LTexture.realtexwidth);
  if APegged then
  begin
    AWall.vb := OffsetVPegged(LTexture, ASeg, AOffset) + LTexture.heightscale;
    AWall.vt := AWall.vb - ALineHeight * LTexture.inv_buffer_height;
  end
  else
  begin
    AWall.vt := OffsetVBottom(LTexture, ASeg);
    AWall.vb := AWall.vt + ALineHeight * LTexture.inv_buffer_height;
  end;
end;

{$IFDEF DOOM}
class function TEngineGlSceneWallCollector.SkyTexture(const AWall: PGLWall): Integer;
begin
  Result := r_sky.skytexture;
  if AWall.glseg.frontsector.sky and PL_SKYFLAT <> 0 then
    Result := texturetranslation[sides[lines[r_bsp.frontsector.sky and not PL_SKYFLAT].sidenum[0]].toptexture];
end;
{$ENDIF}

procedure TEngineGlSceneWallCollector.SetSky(const AWall: PGLWall);
begin
  AWall.gltexture := gld_RegisterTexture({$IFDEF DOOM}SkyTexture(AWall){$ELSE}r_sky.skytexture{$ENDIF}, false);
  AWall.gltexture.textype := GLDT_SKY;
  AWall.skyyaw := -2.0 * ((FYaw + 90.0) / 90.0);
  AWall.skyymid := 200.0 / 319.5;
  AWall.flag := GLDWF_SKY;
  FSkyMet := true;
end;

procedure TEngineGlSceneWallCollector.Append(const AWall: PGLWall);
begin
  AWall.blend := not ((AWall.flag in [GLDWF_SKY, GLDWF_SKYFLIP, GLDWF_TOP, GLDWF_M1S, GLDWF_BOT]) or (AWall.alpha > 0.999));
  PGLWall(FDrawList.AddWall)^ := AWall^;
end;

procedure TEngineGlSceneWallCollector.AddMidWall(const ASeg: Pseg_t; const ASector, AMidSector: Psector_t);
var
  LWall: GLWall;
  LTexture: PGLTexture;
  LRelativeLight: integer;
  LTextureId: integer;
  LLine: Pline_t;
  LOther: Psector_t;
begin
  LWall.glseg := @FSegs[ASeg.iSegID];

  if gl_fakecontrast and (ASeg.sidedef.flags and SDF_NOFAKECONTRAST = 0) then
  begin
    if ASeg.linedef.dx = 0 then
      LRelativeLight := 16 // 8
    else if ASeg.linedef.dy = 0 then
      LRelativeLight := -16 // -8
    else
      LRelativeLight := 0;
  end
  else
    LRelativeLight := 0;

  LWall.light := LightLevel(ASector.lightlevel + LRelativeLight + (extralight shl 5));
  LWall.whitefog := ASector.renderflags and SRF_FOG <> 0;

  if ASector = ASeg.frontsector then
    LOther := ASeg.backsector
  else
    LOther := nil;
  if LOther = nil then
  begin
    LWall.light2 := LWall.light;
    LWall.whitefog2 := LWall.whitefog;
    LWall.doublelight := False;
  end
  else if LOther.midsec < 0 then
  begin
    LWall.light2 := LWall.light;
    LWall.whitefog2 := LWall.whitefog;
    LWall.doublelight := False;
  end
  else
  begin
    LOther := @sectors[LOther.midsec];
    LWall.light2 := LightLevel(LOther.lightlevel + LRelativeLight + (extralight shl 5));
    LWall.whitefog2 := LOther.renderflags and SRF_FOG <> 0;
    LWall.doublelight := true;
    LWall.ymid := (LOther.floorheight / MAP_SCALE + LOther.ceilingheight / MAP_SCALE) / 2;
  end;

  {$IFDEF DOOM}
  if ASeg.linedef.renderflags and LRF_TRANSPARENT <> 0 then
    LWall.alpha := 0.5
  else
  {$ENDIF}
    LWall.alpha := 1.0;

  LWall.gltexture := nil;

  LWall.glseg.x1 := -ASeg.v1.x / MAP_SCALE;
  LWall.glseg.z1 :=  ASeg.v1.y / MAP_SCALE;
  LWall.glseg.x2 := -ASeg.v2.x / MAP_SCALE;
  LWall.glseg.z2 :=  ASeg.v2.y / MAP_SCALE;
  LWall.ytop := AMidSector.floorheight / MAP_SCALE;
  LWall.ybottom := AMidSector.ceilingheight / MAP_SCALE;

  LLine := @lines[ASector.midline];

  if LLine.sidenum[0] > -1 then
    LTextureId := sides[LLine.sidenum[0]].midtexture
  else if LLine.sidenum[1] > -1 then
    LTextureId := sides[LLine.sidenum[1]].midtexture
  else
    Exit;

  LTexture := gld_RegisterTexture(texturetranslation[LTextureId], true);
  if LTexture <> nil then
  begin
    LWall.gltexture := LTexture;
    SetThickSideCoords(
      @LWall, ASeg, false,
      ASeg.length, (AMidSector.ceilingheight - AMidSector.floorheight) / FRACUNIT
    );
    Append(@LWall);
  end;
end;

procedure TEngineGlSceneWallCollector.Add(const ASeg: Pseg_t; const AIsPolyObject: Boolean; const ASector: Psector_t);
var
  LWall: GLWall;
  LTexture: PGLTexture;
  LFrontSector: Psector_t;
  LBackSector: Psector_t;
  LLineHeight: float;
  LRelativeLight: integer;
  LFloorHeight, LCeilingHeight: integer;
  LFloorMax, LCeilingMin, LLineLength: integer;
  LMip: float;
  LOther: Psector_t;
{$IFDEF DOOM_OR_STRIFE}
  LFrontTemp: sector_t; // needed for R_FakeFlat
  LBackTemp: sector_t; // needed for R_FakeFlat
{$ENDIF}
label
  bottomtexture;
begin
  // mark the segment as visible for auto map
  ASeg.linedef.flags := ASeg.linedef.flags or ML_MAPPED;

  if FSegAdded = nil then
    Exit;

  if FSegAdded[ASeg.iSegID] = FMarker then
    Exit;

  FSegAdded[ASeg.iSegID] := FMarker;

  if ASeg.frontsector = nil then
    Exit;

  {$IFDEF DOOM_OR_STRIFE}
  LFrontSector := R_FakeFlat(ASeg.frontsector, @LFrontTemp, nil, nil, false); // for boom effects
  {$ELSE}
  LFrontSector := ASeg.frontsector;
  {$ENDIF}
  LWall.glseg := @FSegs[ASeg.iSegID];

  if gl_fakecontrast and (ASeg.sidedef.flags and SDF_NOFAKECONTRAST = 0) then
  begin
    if ASeg.linedef.dx = 0 then
      LRelativeLight := 16 // 8
    else if ASeg.linedef.dy = 0 then
      LRelativeLight := -16 // -8
    else
      LRelativeLight := 0;
  end
  else
    LRelativeLight := 0;

  LWall.light := LightLevel(LFrontSector.lightlevel + LRelativeLight + (extralight shl 5));
  LWall.whitefog := LFrontSector.renderflags and SRF_FOG <> 0;

// JVAL: 3d floors
  if ASeg.frontsector.midsec >= 0 then
  begin
    LOther := @sectors[ASeg.frontsector.midsec];
    AddMidWall(ASeg, ASeg.frontsector, LOther);
    LWall.light2 := LightLevel(LOther.lightlevel + LRelativeLight + (extralight shl 5));
    LWall.whitefog2 := LOther.renderflags and SRF_FOG <> 0;
    LWall.doublelight := true;
    LWall.ymid := (LOther.floorheight / MAP_SCALE + LOther.ceilingheight / MAP_SCALE) / 2;
  end
  else
  begin
    LWall.light2 := LWall.light;
    LWall.whitefog2 := LWall.whitefog;
    LWall.doublelight := False;
  end;

  if ASeg.backsector <> nil then
    if ASeg.backsector.midsec >= 0 then
      AddMidWall(ASeg, ASeg.backsector, @sectors[ASeg.backsector.midsec]);

  {$IFNDEF HEXEN}
  if ASeg.linedef.renderflags and LRF_TRANSPARENT <> 0 then
    LWall.alpha := 0.5
  else
  {$ENDIF}
  {$IFDEF STRIFE}
    if (ASeg.linedef.flags and ML_TRANSPARENT1 <> 0) or (ASeg.linedef.flags and ML_TRANSPARENT2 <> 0) then
      LWall.alpha := 0.75
    else
  {$ENDIF}
    LWall.alpha := 1.0;

  LWall.gltexture := nil;

  if AIsPolyObject then
  begin
    LWall.glseg.x1 := -ASeg.v1.x / MAP_SCALE;
    LWall.glseg.z1 :=  ASeg.v1.y / MAP_SCALE;
    LWall.glseg.x2 := -ASeg.v2.x / MAP_SCALE;
    LWall.glseg.z2 :=  ASeg.v2.y / MAP_SCALE;
    LWall.ytop := ASector.ceilingheight / MAP_SCALE;
    LWall.ybottom := ASector.floorheight / MAP_SCALE;
    LTexture := gld_RegisterTexture(texturetranslation[ASeg.sidedef.midtexture], true);
    if LTexture <> nil then
    begin
      LWall.gltexture := LTexture;
      SetOneSidedCoords(
        @LWall, ASeg, false,
        ASeg.length, (ASector.ceilingheight - ASector.floorheight) / FRACUNIT
      );
      Append(@LWall);
    end;
    Exit;
  end;

  if ASeg.backsector = nil then // onesided
  begin
    if LFrontSector.ceilingpic = skyflatnum then
    begin
      LWall.ytop := 255.0;
      LWall.ybottom := LFrontSector.ceilingheight / MAP_SCALE;
      SetSky(@LWall);
      Append(@LWall);
    end;
    if LFrontSector.floorpic = skyflatnum then
    begin
      LWall.ytop := LFrontSector.floorheight / MAP_SCALE;
      LWall.ybottom := -255.0;
      SetSky(@LWall);
      Append(@LWall);
    end;
    LTexture := gld_RegisterTexture(texturetranslation[ASeg.sidedef.midtexture], true);
    if (LTexture <> nil) and (LFrontSector.ceilingheight > LFrontSector.floorheight) then
    begin
      LWall.gltexture := LTexture;
      SetHeights(@LWall, LLineHeight, LFrontSector.floorheight, LFrontSector.ceilingheight);
      SetOneSidedCoords(
        @LWall, ASeg, ASeg.linedef.flags and ML_DONTPEGBOTTOM <> 0,
        ASeg.length, LLineHeight
      );
      Append(@LWall);
    end;
  end
  // JVAL: This corrects some problems with MAP18 from Doom2 and other similar maps
  else if ASeg.backsector.linecount = 1 then
  begin
    if LFrontSector.ceilingpic = skyflatnum then
    begin
      LWall.ytop := 255.0;
      LWall.ybottom := LFrontSector.ceilingheight / MAP_SCALE;
      SetSky(@LWall);
      Append(@LWall);
    end;
    if LFrontSector.floorpic = skyflatnum then
    begin
      LWall.ytop := LFrontSector.floorheight / MAP_SCALE;
      LWall.ybottom := -255.0;
      SetSky(@LWall);
      Append(@LWall);
    end;
    LTexture := gld_RegisterTexture(texturetranslation[ASeg.sidedef.toptexture], true);
    if LTexture <> nil then
    begin
      LWall.gltexture := LTexture;
      SetHeights(@LWall, LLineHeight, LFrontSector.floorheight, LFrontSector.ceilingheight);
      SetOneSidedCoords(
        @LWall, ASeg, ASeg.linedef.flags and ML_DONTPEGBOTTOM <> 0,
        ASeg.length, LLineHeight
      );
      Append(@LWall);
    end;
  end
  else // twosided
  begin
    {$IFDEF DOOM_OR_STRIFE}
    LBackSector := R_FakeFlat(ASeg.backsector, @LBackTemp, nil, nil, true); // for boom effects
    {$ELSE}
    LBackSector := ASeg.backsector;
    {$ENDIF}
    // toptexture
    LCeilingHeight := LFrontSector.ceilingheight;
    LFloorHeight := LBackSector.ceilingheight;
    if LFrontSector.ceilingpic = skyflatnum then
    begin
      LWall.ytop := 255.0;
      if  // e6y
          // Fix for HOM in the starting area on Memento Mori map29 and on map30.
          // old code: (LBackSector.ceilingheight==LBackSector.floorheight) &&
          ((LBackSector.ceilingheight = LBackSector.floorheight) or (LBackSector.ceilingheight <= LFrontSector.floorheight)) and
           (LBackSector.ceilingpic = skyflatnum) then
      begin
        if ASeg.sidedef.rowoffset > 0 then
          LWall.ybottom := (LBackSector.floorheight + ASeg.sidedef.rowoffset) / MAP_SCALE
        else
          LWall.ybottom := LBackSector.floorheight / MAP_SCALE;
        SetSky(@LWall);
        Append(@LWall);
      end
      else
      begin
        if texturetranslation[ASeg.sidedef.toptexture] <> NO_TEXTURE then
        begin
          // e6y
          // It corrects some problem with sky, but I do not remember which one
          // old code: LWall.ybottom= LFrontSector.ceilingheight/MAP_SCALE;
          if LFrontSector.ceilingheight > LBackSector.ceilingheight then
            LWall.ybottom := LFrontSector.ceilingheight / MAP_SCALE
          else
            LWall.ybottom := LBackSector.ceilingheight / MAP_SCALE;

          SetSky(@LWall);
          Append(@LWall);
        end
        else if (LBackSector.ceilingheight <= LFrontSector.floorheight) or
                (LBackSector.ceilingpic <> skyflatnum) then
        begin
          LWall.ybottom := LBackSector.ceilingheight / MAP_SCALE;
          SetSky(@LWall);
          Append(@LWall);
        end;
      end;
    end;

    if (LFloorHeight < LCeilingHeight) or
       (LBackSector.renderflags and SRF_SLOPED <> 0) or // JVAL: Slopes
       (LFrontSector.renderflags and SRF_SLOPED <> 0) then
    begin
      if not ((LFrontSector.ceilingpic = skyflatnum) and (LBackSector.ceilingpic = skyflatnum)) then
      begin
        LTexture := gld_RegisterTexture(texturetranslation[ASeg.sidedef.toptexture], true);
        if LTexture <> nil then
        begin
          LWall.gltexture := LTexture;
          SetSignedHeights(@LWall, LLineHeight, LFloorHeight, LCeilingHeight);
          SetTopCoords(
            @LWall, ASeg, (ASeg.linedef.flags and ML_DONTPEGTOP) = 0,
            ASeg.length, LLineHeight
          );
          Append(@LWall);
        end
        else if (LBackSector <> nil) and (ASeg.linedef.renderflags and LRF_ISOLATED = 0) and
                (LFrontSector.ceilingpic <> skyflatnum) and (LBackSector.ceilingpic <> skyflatnum) then
        begin
          LWall.ytop := LCeilingHeight / MAP_SCALE + SMALL_DELTA;
          LWall.ybottom := LFloorHeight / MAP_SCALE - SMALL_DELTA;
          LTexture := gld_RegisterFlat(R_GetLumpForFlat(ASeg.backsector.ceilingpic), true, ASeg.backsector.ceilingpic);
          if LTexture <> nil then
          begin
            LWall.flag := GLDWF_TOPFLUD;
            LWall.gltexture := LTexture;
            Append(@LWall);
          end;
//          gld_AddFlat_Extra(ASeg.frontsector.iSectorID, ASeg.backsector.ceilingpic, ASeg.frontsector.floorheight, true, false); // here SOS SOS JVAL 20200105
        end
      end;
    end;

    // midtexture
    LTexture := gld_RegisterTexture(texturetranslation[ASeg.sidedef.midtexture], true);
    if LTexture <> nil then
    begin
      LWall.gltexture := LTexture;
      if ASeg.linedef.flags and ML_DONTPEGBOTTOM > 0 then
      begin
        if ASeg.backsector.ceilingheight <= ASeg.frontsector.floorheight then
          goto bottomtexture;
        LFloorHeight := gl_i_max(ASeg.frontsector.floorheight, ASeg.backsector.floorheight) + ASeg.sidedef.rowoffset;
        LCeilingHeight := LFloorHeight + (LTexture.realtexheight * FRACUNIT);
      end
      else
      begin
        if ASeg.backsector.ceilingheight <= ASeg.frontsector.floorheight then
          goto bottomtexture;
        LCeilingHeight := gl_i_min(ASeg.frontsector.ceilingheight, ASeg.backsector.ceilingheight) + ASeg.sidedef.rowoffset;
        LFloorHeight := LCeilingHeight - (LTexture.realtexheight * FRACUNIT);
      end;

      LMip := LTexture.realtexheight * LTexture.inv_buffer_height;
      if ASeg.sidedef.bottomtexture <> 0 then
        LFloorMax := gl_i_max(ASeg.frontsector.floorheight, ASeg.backsector.floorheight)
      else
        LFloorMax := LFloorHeight;
      if ASeg.sidedef.toptexture <> 0 then
        LCeilingMin := gl_i_min(ASeg.frontsector.ceilingheight, ASeg.backsector.ceilingheight)
      else
        LCeilingMin := LCeilingHeight;
      LLineLength := abs(LCeilingHeight - LFloorHeight);
      LWall.ytop := gl_i_min(LCeilingMin, LCeilingHeight) / MAP_SCALE;
      LWall.ybottom := gl_i_max(LFloorMax, LFloorHeight) / MAP_SCALE;
      LWall.flag := GLDWF_M2S;
      LWall.ul := OffsetUMiddle(LTexture, ASeg);
      LWall.ur := LWall.ul + (ASeg.length * LTexture.inv_buffer_width);
      if LFloorMax <= LFloorHeight then
        LWall.vb := LMip
      else
        LWall.vb := LMip * (LCeilingHeight - LFloorMax) / LLineLength;
      if LCeilingMin >= LCeilingHeight then
        LWall.vt := 0.0
      else
        LWall.vt := LMip * (LCeilingHeight - LCeilingMin) / LLineLength;
{      if (ASeg.linedef.tranlump >= 0) and general_translucency)
        LWall.alpha= tran_filter_pct/100.0;}
      Append(@LWall);
//      LWall.alpha := 1.0;
    end;

bottomtexture:
    LCeilingHeight := LBackSector.floorheight;
    LFloorHeight := LFrontSector.floorheight;
    if LFrontSector.floorpic = skyflatnum then
    begin
      LWall.ybottom := -255.0;
      if (
          (LBackSector.ceilingheight = LBackSector.floorheight) and
          (LBackSector.floorpic = skyflatnum)
         ) then
      begin
        LWall.ytop := LBackSector.floorheight / MAP_SCALE;
        SetSky(@LWall);
        Append(@LWall);
      end
      else
      begin
        if texturetranslation[ASeg.sidedef.bottomtexture] <> NO_TEXTURE then
        begin
          LWall.ytop := LFrontSector.floorheight / MAP_SCALE;
          SetSky(@LWall);
          Append(@LWall);
        end
        else
          if (LBackSector.floorheight >= LFrontSector.ceilingheight) or
             (LBackSector.floorpic <> skyflatnum) then
          begin
            LWall.ytop := LBackSector.floorheight / MAP_SCALE;
            SetSky(@LWall);
            Append(@LWall);
          end;
      end;
    end;
    if (LFloorHeight < LCeilingHeight) or
       (LBackSector.renderflags and SRF_SLOPED <> 0) or
       (LFrontSector.renderflags and SRF_SLOPED <> 0) then // JVAL: Slopes
    begin
      if (LFrontSector.floorpic <> skyflatnum) and // JVAL 21/5/2011
         (LBackSector.floorheight > LFrontSector.floorheight) and
         (texturetranslation[ASeg.sidedef.bottomtexture] = NO_TEXTURE) then
      begin
        LWall.ytop := LCeilingHeight / MAP_SCALE + SMALL_DELTA;
        LWall.ybottom := LFloorHeight / MAP_SCALE - SMALL_DELTA;
        if LWall.ytop <= FCameraZ then
        begin
          LTexture := gld_RegisterFlat(R_GetLumpForFlat(ASeg.backsector.floorpic), true, ASeg.backsector.floorpic);
          if LTexture <> nil then
          begin
            LWall.flag := GLDWF_BOTFLUD;
            LWall.gltexture := LTexture;
            Append(@LWall);
          end;
        end;
        //gld_AddFlat_Extra(ASeg.frontsector.iSectorID, ASeg.backsector.floorpic, ASeg.backsector.floorheight, true, false); // here
      end
      else
      begin
        LTexture := gld_RegisterTexture(texturetranslation[ASeg.sidedef.bottomtexture], true);
        if LTexture <> nil then
        begin
          LWall.gltexture := LTexture;
          SetSignedHeights(@LWall, LLineHeight, LFloorHeight, LCeilingHeight);
          SetBottomCoords(
            @LWall, ASeg, (ASeg.linedef.flags and ML_DONTPEGBOTTOM) <> 0,
            ASeg.length, LLineHeight,
            LFloorHeight - LFrontSector.ceilingheight
          );
          Append(@LWall);
        end
        else if (LBackSector <> nil) and (ASeg.linedef.renderflags and LRF_ISOLATED = 0) and
                (LFrontSector.ceilingpic <> skyflatnum) and (LBackSector.ceilingpic <> skyflatnum) then
        begin
          FFlats.AddExtra(
            ASeg.frontsector.iSectorID, ASeg.backsector.floorpic, ASeg.frontsector.floorheight,
            False, ASeg.frontsector.renderflags and SRF_RIPPLE_CEILING <> 0,
            ASeg.backsector.floorangle, ASeg.backsector.flooranglex, ASeg.backsector.floorangley);
        end;
      end;
    end;
  end;
end;
end.
