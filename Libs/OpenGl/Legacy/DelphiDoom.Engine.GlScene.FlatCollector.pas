//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - collects the flats of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.FlatCollector;

interface

uses
  System.SysUtils,
  d_delphi,
  m_fixed,
  tables,
  r_defs,
  r_visplanes,
  DelphiDoom.GlScene.Types,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlScene.Types;

type
  /// <summary>
  ///   The floors and ceilings the BSP walk meets go to the draw list of the frame (it was gld_AddPlane,
  ///   gld_AddFlat, gld_AddFlat_Extra and gld_AddFlat_3dFloor of gl_render.pas): the same records, in the
  ///   same order
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per subsector of every frame), never through an interface. It reads
  ///   the level and the view of the engine (sectors, subsectors, viewz, extralight, usegamma, skyflatnum) and
  ///   registers the textures with gl_tex. The marks "already added in this frame" are bytes that hold the
  ///   counter of the frame, one per sector, as in the old code. The differences between the games are the
  ///   fields their records have (light of the planes of Doom and Strife, offsets in the visplane of Hexen,
  ///   no offsets in Heretic): they stay conditional because the records are different by construction
  /// </remarks>
  TEngineGlSceneFlatCollector = class(TObject)
  strict private
    FDrawList: TGlSceneDrawList;
    FLightTable: PGlSceneLightTable;
    FMarker: Byte;
    FSectorAdded: TBytes;
    FCeilingExtraAdded: TBytes;
    FFloorExtraAdded: TBytes;
    FMidFloorAdded: TBytes;
    function LightLevel(const ALight: Integer): float;
    class procedure SetRotation(var AFlat: GLFlat; const AAngle: angle_t;
      const AAngleX, AAngleY: fixed_t); static;
    procedure Add(const ASectorNum: Integer; const ACeiling: Boolean; const APlane: Pvisplane_t);
    procedure AddMidFloor(const ASectorNum: Integer; const APic, AHeight: Integer; const ARipple: Boolean;
      const ALight: Integer; const AAngle: angle_t; const AAngleX, AAngleY: fixed_t;
      const AWhiteFog: Boolean);
  public
    /// <param name="ADrawList">The list of the frame; not owned</param>
    /// <param name="ALightTable">The light table of gl_render (gamma, light level)</param>
    /// <exception cref="EArgumentNilException">A dependency is nil</exception>
    constructor Create(const ADrawList: TGlSceneDrawList; const ALightTable: PGlSceneLightTable);
    /// <summary>A new level: no sector is marked</summary>
    procedure BeginLevel(const ASectorCount: Integer);
    /// <summary>A new frame: AMarker is its counter (the one given to the draw list)</summary>
    procedure BeginFrame(const AMarker: Byte);
    /// <summary>Floor and ceiling of the sector of a subsector, and the planes of its 3d floor, once per frame</summary>
    procedure AddPlane(const ASubsectorNum: Integer; const AFloor, ACeiling: Pvisplane_t);
    /// <summary>The plane that fills the gap of a missing lower texture with the flat of the back sector</summary>
    procedure AddExtra(const ASectorNum: Integer; const APic, AHeight: Integer; const AIsFloor: Boolean;
      const ARipple: Boolean; const AAngle: angle_t; const AAngleX, AAngleY: fixed_t);
  end;

implementation

uses
  v_video,
  p_setup,
  {$IFDEF DOOM_OR_STRIFE}
  r_bsp,
  {$ENDIF}
  r_main,
  r_data,
  r_sky,
  gl_defs,
  gl_tex,
  DelphiDoom.GlScene.Light;

{ TEngineGlSceneFlatCollector }

constructor TEngineGlSceneFlatCollector.Create(const ADrawList: TGlSceneDrawList;
  const ALightTable: PGlSceneLightTable);
begin
  inherited Create;
  if not Assigned(ADrawList) then
    raise EArgumentNilException.Create('ADrawList');
  if not Assigned(ALightTable) then
    raise EArgumentNilException.Create('ALightTable');
  FDrawList := ADrawList;
  FLightTable := ALightTable;
end;

procedure TEngineGlSceneFlatCollector.BeginLevel(const ASectorCount: Integer);
begin
  FSectorAdded := nil;
  FCeilingExtraAdded := nil;
  FFloorExtraAdded := nil;
  FMidFloorAdded := nil;
  // SetLength of an empty array gives zeroes
  SetLength(FSectorAdded, ASectorCount);
  SetLength(FCeilingExtraAdded, ASectorCount);
  SetLength(FFloorExtraAdded, ASectorCount);
  SetLength(FMidFloorAdded, ASectorCount);
end;

procedure TEngineGlSceneFlatCollector.BeginFrame(const AMarker: Byte);
begin
  FMarker := AMarker;
end;

function TEngineGlSceneFlatCollector.LightLevel(const ALight: Integer): float;
begin
  Result := TGlSceneLight.Level(FLightTable, usegamma, ALight);
end;

class procedure TEngineGlSceneFlatCollector.SetRotation(var AFlat: GLFlat; const AAngle: angle_t;
  const AAngleX, AAngleY: fixed_t);
begin
  if AAngle <> 0 then
  begin
    AFlat.angle := (AAngle / ANGLE_MAX) * 360.0;
    AFlat.anglex := AAngleX / FLATUVSCALE;
    AFlat.angley := AAngleY / FLATUVSCALE;
    AFlat.hasangle := True;
  end
  else
  begin
    AFlat.angle := 0.0;
    AFlat.anglex := 0.0;
    AFlat.angley := 0.0;
    AFlat.hasangle := False;
  end;
end;

procedure TEngineGlSceneFlatCollector.AddExtra(const ASectorNum: Integer; const APic, AHeight: Integer;
  const AIsFloor: Boolean; const ARipple: Boolean; const AAngle: angle_t; const AAngleX, AAngleY: fixed_t);
var
  {$IFDEF DOOM_OR_STRIFE}
  LTempSector: sector_t; // needed for R_FakeFlat
  {$ENDIF}
  LSector: Psector_t;
  LFlat: GLFlat;
begin
  if ASectorNum < 0 then
    Exit;

  if AIsFloor then
  begin
    if FFloorExtraAdded = nil then
      Exit;

    if FFloorExtraAdded[ASectorNum] = FMarker then
      Exit;

    FFloorExtraAdded[ASectorNum] := FMarker;
  end
  else
  begin
    if FCeilingExtraAdded = nil then
      Exit;

    if FCeilingExtraAdded[ASectorNum] = FMarker then
      Exit;

    FCeilingExtraAdded[ASectorNum] := FMarker;
  end;

  LFlat.sectornum := ASectorNum;
  LSector := @sectors[ASectorNum];
  {$IFDEF DOOM_OR_STRIFE}
  LSector := R_FakeFlat(LSector, @LTempSector, nil, nil, false); // for boom effects
  {$ENDIF}
  LFlat.ceiling := true;

  // get the texture. flattranslation is maintained by doom and
  // contains the number of the current animation frame
  LFlat.gltexture := gld_RegisterFlat(R_GetLumpForFlat(APic), true, APic);
  if LFlat.gltexture = nil then
    Exit;
  LFlat.light := LightLevel(LSector.lightlevel + (extralight shl 5));
  // calculate texture offsets
  {$IFDEF DOOM_OR_STRIFE}
  LFlat.hasoffset := (LSector.ceiling_xoffs <> 0) or (LSector.ceiling_yoffs <> 0);
  if LFlat.hasoffset then
  begin
    LFlat.uoffs := LSector.ceiling_xoffs / FLATUVSCALE;
    LFlat.voffs := LSector.ceiling_yoffs / FLATUVSCALE;
  end
  else
  begin
    LFlat.uoffs := 0.0;
    LFlat.voffs := 0.0;
  end;
  {$ENDIF}
  {$IFDEF HEXEN}
  LFlat.hasoffset := false;
  LFlat.uoffs := 0.0;
  LFlat.voffs := 0.0;
  {$ENDIF}
  LFlat.ripple := ARipple;

  SetRotation(LFlat, AAngle, AAngleX, AAngleY);

  // get height from plane
  LFlat.z := AHeight / MAP_SCALE;

  LFlat.whitefog := LSector.renderflags and SRF_FOG <> 0; // JVAL: Mars fog sectors

  PGLFlat(FDrawList.AddFlat)^ := LFlat;
end;

procedure TEngineGlSceneFlatCollector.AddMidFloor(const ASectorNum: Integer; const APic, AHeight: Integer;
  const ARipple: Boolean; const ALight: Integer; const AAngle: angle_t; const AAngleX, AAngleY: fixed_t;
  const AWhiteFog: Boolean);
var
  {$IFDEF DOOM_OR_STRIFE}
  LTempSector: sector_t; // needed for R_FakeFlat
  LSector: Psector_t;
  {$ENDIF}
  LFlat: GLFlat;
begin
  if ASectorNum < 0 then
    Exit;

  if FMidFloorAdded = nil then
    Exit;

  if FMidFloorAdded[ASectorNum] = FMarker then
    Exit;

  FMidFloorAdded[ASectorNum] := FMarker;

  LFlat.sectornum := ASectorNum;
  {$IFDEF DOOM_OR_STRIFE}
  LSector := @sectors[ASectorNum];
  LSector := R_FakeFlat(LSector, @LTempSector, nil, nil, false); // for boom effects
  {$ENDIF}
  LFlat.ceiling := true;

  // get the texture. flattranslation is maintained by doom and
  // contains the number of the current animation frame
  LFlat.gltexture := gld_RegisterFlat(R_GetLumpForFlat(APic), true, APic);
  if LFlat.gltexture = nil then
    Exit;
  LFlat.light := LightLevel(ALight + (extralight shl 5));
  // calculate texture offsets
  {$IFDEF DOOM_OR_STRIFE}
  LFlat.hasoffset := (LSector.ceiling_xoffs <> 0) or (LSector.ceiling_yoffs <> 0);
  if LFlat.hasoffset then
  begin
    LFlat.uoffs := LSector.ceiling_xoffs / FLATUVSCALE;
    LFlat.voffs := LSector.ceiling_yoffs / FLATUVSCALE;
  end
  else
  begin
    LFlat.uoffs := 0.0;
    LFlat.voffs := 0.0;
  end;
  {$ENDIF}
  {$IFDEF HEXEN}
  LFlat.hasoffset := false;
  LFlat.uoffs := 0.0;
  LFlat.voffs := 0.0;
  {$ENDIF}
  LFlat.ripple := ARipple;

  SetRotation(LFlat, AAngle, AAngleX, AAngleY);

  // get height from plane
  LFlat.z := AHeight / MAP_SCALE;

  LFlat.whitefog := AWhiteFog; // JVAL: Mars fog sectors

  PGLFlat(FDrawList.AddFlat)^ := LFlat;
end;

procedure TEngineGlSceneFlatCollector.Add(const ASectorNum: Integer; const ACeiling: Boolean;
  const APlane: Pvisplane_t);
var
  {$IFDEF DOOM_OR_STRIFE}
  LTempSector: sector_t; // needed for R_FakeFlat
  {$ENDIF}
  LSector: Psector_t;
  LFlat: GLFlat;
  LMidSector: Psector_t; // JVAL: 3d Floors
begin
  if ASectorNum < 0 then
    Exit;

  LFlat.sectornum := ASectorNum;
  LSector := @sectors[ASectorNum];
  {$IFDEF DOOM_OR_STRIFE}
  LSector := R_FakeFlat(LSector, @LTempSector, nil, nil, false); // for boom effects
  {$ENDIF}
  LFlat.ceiling := ACeiling;
  if ACeiling then
  begin
    if LSector.ceilingpic = skyflatnum then // don't draw if sky
      Exit;
    // get the texture. flattranslation is maintained by doom and
    // contains the number of the current animation frame
    LFlat.gltexture := gld_RegisterFlat(R_GetLumpForFlat(LSector.ceilingpic), true, LSector.ceilingpic);
    if LFlat.gltexture = nil then
      Exit;
    LFlat.light := LightLevel({$IFDEF DOOM_OR_STRIFE}LSector.ceilinglightlevel{$ELSE}LSector.lightlevel{$ENDIF} + (extralight shl 5));
    // calculate texture offsets
    {$IFDEF DOOM_OR_STRIFE}
    LFlat.hasoffset := (LSector.ceiling_xoffs <> 0) or (LSector.ceiling_yoffs <> 0);
    if LFlat.hasoffset then
    begin
      LFlat.uoffs := LSector.ceiling_xoffs / FLATUVSCALE;
      LFlat.voffs := LSector.ceiling_yoffs / FLATUVSCALE;
    end
    else
    begin
      LFlat.uoffs := 0.0;
      LFlat.voffs := 0.0;
    end;
    {$ENDIF}
    {$IFDEF HEXEN}
    LFlat.hasoffset := (APlane.xoffs <> 0) or (APlane.yoffs <> 0);
    if LFlat.hasoffset then
    begin
      LFlat.uoffs := APlane.xoffs / FLATUVSCALE;
      LFlat.voffs := APlane.yoffs / FLATUVSCALE;
    end
    else
    begin
      LFlat.uoffs := 0.0;
      LFlat.voffs := 0.0;
    end;
    {$ENDIF}
    LFlat.ripple := APlane.renderflags and SRF_RIPPLE_CEILING <> 0;

    SetRotation(LFlat, APlane.angle, APlane.anglex, APlane.angley);
    LFlat.whitefog := LSector.renderflags and SRF_FOG <> 0; // JVAL: Mars fog sectors
  end
  else
  begin
    if LSector.floorpic = skyflatnum then // don't draw if sky
      Exit;
    // get the texture. flattranslation is maintained by doom and
    // contains the number of the current animation frame
    LFlat.gltexture := gld_RegisterFlat(R_GetLumpForFlat(LSector.floorpic), true, LSector.floorpic);
    if LFlat.gltexture = nil then
      Exit;

    if LSector.midsec >= 0 then  // JVAL: 3d Floors
    begin
      LMidSector := @sectors[LSector.midsec];
      LFlat.light := LightLevel({$IFDEF DOOM_OR_STRIFE}LMidSector.floorlightlevel{$ELSE}LMidSector.lightlevel{$ENDIF} + (extralight shl 5));
      LFlat.whitefog := LMidSector.renderflags and SRF_FOG <> 0; // JVAL: Mars fog sectors
    end
    else
    begin
      LFlat.light := LightLevel({$IFDEF DOOM_OR_STRIFE}LSector.floorlightlevel{$ELSE}LSector.lightlevel{$ENDIF} + (extralight shl 5));
      LFlat.whitefog := LSector.renderflags and SRF_FOG <> 0; // JVAL: Mars fog sectors
    end;
    // calculate texture offsets
    {$IFDEF DOOM_OR_STRIFE}
    LFlat.hasoffset := (LSector.floor_xoffs <> 0) or (LSector.floor_yoffs <> 0);
    if LFlat.hasoffset then
    begin
      LFlat.uoffs := LSector.floor_xoffs / FLATUVSCALE;
      LFlat.voffs := LSector.floor_yoffs / FLATUVSCALE;
    end
    else
    begin
      LFlat.uoffs := 0.0;
      LFlat.voffs := 0.0;
    end;
    {$ENDIF}
    {$IFDEF HEXEN}
    LFlat.hasoffset := (APlane.xoffs <> 0) or (APlane.yoffs <> 0);
    if LFlat.hasoffset then
    begin
      LFlat.uoffs := APlane.xoffs / FLATUVSCALE;
      LFlat.voffs := APlane.yoffs / FLATUVSCALE;
    end
    else
    begin
      LFlat.uoffs := 0.0;
      LFlat.voffs := 0.0;
    end;
    {$ENDIF}
    LFlat.ripple := APlane.renderflags and SRF_RIPPLE_FLOOR <> 0;

    SetRotation(LFlat, APlane.angle, APlane.anglex, APlane.angley);
  end;

  // get height from plane
  LFlat.z := APlane.height / MAP_SCALE;

  PGLFlat(FDrawList.AddFlat)^ := LFlat;
end;

procedure TEngineGlSceneFlatCollector.AddPlane(const ASubsectorNum: Integer;
  const AFloor, ACeiling: Pvisplane_t);
var
  LSectorId: Integer;
  LSector: Psector_t;
  LMidSector: Psector_t; // JVAL: 3d floors
begin
  // no level yet
  if FSectorAdded = nil then
    Exit;

  LSectorId := subsectors[ASubsectorNum].sector.iSectorID;
  if FSectorAdded[LSectorId] <> FMarker then
  begin
    LSector := @sectors[LSectorId];
    if AFloor <> nil then
      if (AFloor.height < viewz) or (LSector.renderflags and SRF_SLOPEFLOOR <> 0) then
        Add(LSectorId, false, AFloor);
    if ACeiling <> nil then
      if (ACeiling.height > viewz) or (LSector.renderflags and SRF_SLOPECEILING <> 0) then
        Add(LSectorId, true, ACeiling);

    if LSector.midsec >= 0 then
    begin
      LMidSector := @sectors[LSector.midsec];
      if viewz < LMidSector.floorheight then
        AddMidFloor(
          LSectorId, LMidSector.floorpic, LMidSector.floorheight,
          LMidSector.renderflags and SRF_RIPPLE_FLOOR <> 0,
          LMidSector.lightlevel, LMidSector.floorangle, LMidSector.flooranglex, LMidSector.floorangley,
          LMidSector.renderflags and SRF_FOG <> 0);
      if viewz > LMidSector.ceilingheight then
        AddMidFloor(
          LSectorId, LMidSector.ceilingpic, LMidSector.ceilingheight,
          LMidSector.renderflags and SRF_RIPPLE_CEILING <> 0,
          LSector.lightlevel, LMidSector.ceilingangle, LMidSector.ceilinganglex, LMidSector.ceilingangley,
          LSector.renderflags and SRF_FOG <> 0);
    end;

    FSectorAdded[LSectorId] := FMarker;
  end;
end;

end.
