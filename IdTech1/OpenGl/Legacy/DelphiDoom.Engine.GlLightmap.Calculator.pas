//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the dynamic lightmap of the OpenGL scene
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

unit DelphiDoom.Engine.GlLightmap.Calculator;

interface

uses
  d_delphi,
  gl_defs,
  DelphiDoom.Engine.GlLightmap.Types;

type
  /// <summary>
  ///   Volumetric dynamic lightmap of the OpenGL scene (a single 3D texture of LIGHTMAPSIZEX x LIGHTMAPSIZEY x
  ///   LIGHTMAPSIZEZ cells around the camera): at every tic with dynamic lights it clears the regions marked
  ///   by the previous tic, accumulates the colour of every visible light (and the shadows) into the cells
  ///   it reaches and uploads the changed regions with glTexSubImage3D (it was the state and the routines of
  ///   gl_lightmaps.pas: the same OpenGL calls, in the same order, with the same numbers)
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per frame), never through an interface and with no virtual
  ///   method. The texture object and the state of the texture units stay in gl_lightmaps, which owns the
  ///   instance. The lights come from dlbuffer (sorted by TEngineGlSceneLightSorter), the camera from gl_defs
  /// </remarks>
  TEngineGlLightmapCalculator = class(TObject)
  strict private
    type
      TLightmapBuffer = array[0..LIGHTMAPBUFFERSIZE - 1] of Byte;
      PLightmapBuffer = ^TLightmapBuffer;
      // a region of the lightmap to update
      TLightmapMark = record
        x1, x2: Integer;
        y1, y2: Integer;
        z1, z2: Integer;
        dx, dy, dz: Integer;
      end;
      PLightmapMark = ^TLightmapMark;
      TLightmapMarkArray = array[0..$FFFF] of TLightmapMark;
      PLightmapMarkArray = ^TLightmapMarkArray;
      TLightmapCell = record
        r, g, b: float;
        inter: Integer;
        shadow: Integer;
      end;
      PLightmapCell = ^TLightmapCell;
      // Actual size is intentionally LIGHTMAPSIZEX * LIGHTMAPSIZEY * LIGHTMAPSIZEZ + 1
      TLightmapCellArray = array[0..LIGHTMAPSIZEX * LIGHTMAPSIZEY * LIGHTMAPSIZEZ] of TLightmapCell;
      PLightmapCellArray = ^TLightmapCellArray;
      TLightmapExport = array[0..LIGHTMAPSIZEX - 1, 0..LIGHTMAPSIZEX - 1, 0..LIGHTMAPSIZEX - 1] of LongWord;
      PLightmapExport = ^TLightmapExport;
    const
      MAXSHADOWSHIFT = 8; // 8 shadows max at the same point
      MINLIGHTMAPRADIOUS = 1.7321 * LIGHTMAPUNIT / MAP_COEFF;
  strict private
    FBuffer: PLightmapBuffer;
    FMarks: PLightmapMarkArray;
    FMaxMarks: Integer;
    FNumMarks: Integer;
    FMaxMarkBytes: Integer;
    FDefined: Boolean;
    FRealTimeMap: PLightmapCellArray;
    FShadowFactor: array[0..MAXSHADOWSHIFT - 1] of float;
    FValidCount: Integer;
    /// <summary>Starting point of the lightmap in OpenGL coordinates</summary>
    FOriginX: float;
    FOriginY: float;
    FOriginZ: float;
    function OpenGlToLightmapX(const AValue: float): Integer;
    function OpenGlToLightmapY(const AValue: float): Integer;
    function OpenGlToLightmapZ(const AValue: float): Integer;
    function LightmapToOpenGlX(const AIndex: Integer): float;
    function LightmapToOpenGlY(const AIndex: Integer): float;
    function LightmapToOpenGlZ(const AIndex: Integer): float;
    function FloatToByte(const AValue: float): Byte;
    procedure ClearMark(const AMark: PLightmapMark);
  public
    /// <summary>Allocates the cells and the buffer and marks the whole lightmap to be uploaded</summary>
    constructor Create;
    destructor Destroy; override;
    /// <summary>Calculates the lightmap of the tic (once per tic) and uploads the regions</summary>
    procedure Calculate;
    /// <summary>The texture matrix that puts the lightmap in world coordinates</summary>
    procedure PlaceTexture;
    /// <summary>Writes the lightmap as a DDVOX voxel file (the console command vox_exportlightmap)</summary>
    procedure Export(const AFileName: string);
    /// <summary>True once the 3D texture has been created (the first Calculate)</summary>
    property Defined: Boolean read FDefined;
  end;

implementation

uses
  dglOpenGL,
  m_fixed,
  tables,
  r_defs,
  r_main,
  p_tick,
  p_3dfloors,
  r_dynlights;

{ TEngineGlLightmapCalculator }

constructor TEngineGlLightmapCalculator.Create;
var
  LIndex: Integer;
  LCell: PLightmapCell;
begin
  inherited Create;
  FValidCount := -1;
  FOriginX := -LIGHTMAPSIZEX * LIGHTMAPUNIT / MAP_COEFF / 2;
  FOriginY := -LIGHTMAPSIZEY * LIGHTMAPUNIT / MAP_COEFF / 2;
  FOriginZ := -LIGHTMAPSIZEZ * LIGHTMAPUNIT / MAP_COEFF / 2;

  FShadowFactor[0] := 128.0;
  for LIndex := 1 to MAXSHADOWSHIFT - 1 do
    FShadowFactor[LIndex] := 128.0 * (MAXSHADOWSHIFT - LIndex) / MAXSHADOWSHIFT;

  // Setup lightmap mark regions
  FMaxMarks := 32;  // initial value, it grows if needed
  FMarks := mallocz(FMaxMarks * SizeOf(TLightmapMark));
  // Initially the entire lightmap is marked
  FMarks[0].x1 := 0;
  FMarks[0].x2 := LIGHTMAPSIZEX - 1;
  FMarks[0].y1 := 0;
  FMarks[0].y2 := LIGHTMAPSIZEY - 1;
  FMarks[0].z1 := 0;
  FMarks[0].z2 := LIGHTMAPSIZEZ - 1;
  FMarks[0].dx := LIGHTMAPSIZEX;
  FMarks[0].dy := LIGHTMAPSIZEY;
  FMarks[0].dz := LIGHTMAPSIZEZ;
  FNumMarks := 1;

  FRealTimeMap := malloc(SizeOf(TLightmapCellArray));
  LCell := @FRealTimeMap[0];
  for LIndex := 0 to LIGHTMAPSIZEX * LIGHTMAPSIZEY * LIGHTMAPSIZEZ do
  begin
    LCell.r := 0.0;
    LCell.g := 0.0;
    LCell.b := 0.0;
    LCell.shadow := 0;
    LCell.inter := 0;
    inc(LCell);
  end;

  FBuffer := malloc(LIGHTMAPBUFFERSIZE);
  FMaxMarkBytes := LIGHTMAPBUFFERSIZE;
  FDefined := False;
end;

destructor TEngineGlLightmapCalculator.Destroy;
begin
  memfree(pointer(FRealTimeMap), SizeOf(TLightmapCellArray));
  memfree(pointer(FMarks), FMaxMarks * SizeOf(TLightmapMark));
  memfree(pointer(FBuffer), LIGHTMAPBUFFERSIZE);
  inherited Destroy;
end;





//==============================================================================
// OpenGlToLightmapX
//
// Utility functions to switch coordinates (LIGHMAP TEXTURE/OpenGL).
//
//==============================================================================
function TEngineGlLightmapCalculator.OpenGlToLightmapX(const AValue: float): integer;
begin
  result := trunc((AValue - FOriginX) * (MAP_COEFF / LIGHTMAPUNIT));
end;

//==============================================================================
//
// OpenGlToLightmapY
//
//==============================================================================
function TEngineGlLightmapCalculator.OpenGlToLightmapY(const AValue: float): integer;
begin
  result := trunc((AValue - FOriginY) * (MAP_COEFF / LIGHTMAPUNIT));
end;

//==============================================================================
//
// OpenGlToLightmapZ
//
//==============================================================================
function TEngineGlLightmapCalculator.OpenGlToLightmapZ(const AValue: float): integer;
begin
  result := trunc((AValue - FOriginZ) * (MAP_COEFF / LIGHTMAPUNIT));
end;

//==============================================================================
//
// LightmapToOpenGlX
//
//==============================================================================
function TEngineGlLightmapCalculator.LightmapToOpenGlX(const AIndex: integer): float;
begin
  result := (AIndex * LIGHTMAPUNIT / MAP_COEFF) + FOriginX;
end;

//==============================================================================
//
// LightmapToOpenGlY
//
//==============================================================================
function TEngineGlLightmapCalculator.LightmapToOpenGlY(const AIndex: integer): float;
begin
  result := (AIndex * LIGHTMAPUNIT / MAP_COEFF) + FOriginY;
end;

//==============================================================================
//
// LightmapToOpenGlZ
//
//==============================================================================
function TEngineGlLightmapCalculator.LightmapToOpenGlZ(const AIndex: integer): float;
begin
  result := (AIndex * LIGHTMAPUNIT / MAP_COEFF) + FOriginZ;
end;

//==============================================================================
//
// FloatToByte
//
//==============================================================================
function TEngineGlLightmapCalculator.FloatToByte(const AValue: float): byte;
begin
  if AValue <= 0.5 then
    Result := 0
  else if AValue >= 254.5 then
    Result := 255
  else
    Result := Round(AValue);
end;

//==============================================================================
//
// ClearMark
//
//==============================================================================
procedure TEngineGlLightmapCalculator.ClearMark(const AMark: PLightmapMark);
var
  LIndexX, LIndexY, LIndexZ: integer;
  x_offs, xy_offs: integer;
  LCell: PLightmapCell;
begin
  for LIndexX := AMark.x1 to AMark.x2 do
  begin
    x_offs := LIndexX * (LIGHTMAPSIZEX * LIGHTMAPSIZEY);
    for LIndexY := AMark.y1 to AMark.y2 do
    begin
      xy_offs := x_offs + LIndexY * LIGHTMAPSIZEX;
      LCell := @FRealTimeMap[xy_offs + AMark.z1];
      for LIndexZ := AMark.z1 to AMark.z2 do
      begin
        LCell.r := 0.0;
        LCell.g := 0.0;
        LCell.b := 0.0;
        LCell.shadow := 0;
        LCell.inter := 0;
        inc(LCell);
      end;
    end;
  end;
end;

//==============================================================================
//
// Calculate
//
//==============================================================================
procedure TEngineGlLightmapCalculator.Calculate;
var
  LIndexX, LIndexY, LIndexZ: integer;
  LSizeX, LSizeY, LSizeZ: integer;
  LIndexX1, LIndexX2, LIndexY1, LIndexY2, LIndexZ1, LIndexZ2: integer;
  LBoundX1, LBoundX2, LBoundY1, LBoundY2, LBoundZ1, LBoundZ2: float;
  LItem: Pdlsortitem_t;
  LLightX, LLightY, LLightZ: float;
  LLightY1, LLightY2: float;
  LLight: PGLDRenderLight;
  LSquareDistance, LSquareCheck, LSquareCheckInner: float;
  LPoint: PByte;
  LLastItem: dlsortitem_t;
  LMark: PLightmapMark;
  LByteCount: integer;
  LCheckRadius: float;
  LCell: PLightmapCell;
  LSquareZ, LSquareYZ: float;
  LFloorZ, LCeilingZ: float;
  LMapX, LMapY, LMapZ: fixed_t;  // Map Coordinates
  LShadowFactor: float;
  LSector: Psector_t;
begin
  if FDefined and (FValidCount = TTickState.LevelTime) then
    exit;

  FValidCount := TTickState.LevelTime;

// -----------------------------------------------------------------------------
// Calculate the starting point of lightmap
  FOriginX := LightmapToOpenGlX(OpenGlToLightmapX(camera.position[0] - LIGHTMAPSIZEX * LIGHTMAPUNIT / MAP_COEFF / 2));
  FOriginY := LightmapToOpenGlY(OpenGlToLightmapY(camera.position[1] - LIGHTMAPSIZEY * LIGHTMAPUNIT / MAP_COEFF / 2));
  FOriginZ := LightmapToOpenGlZ(OpenGlToLightmapZ(camera.position[2] - LIGHTMAPSIZEZ * LIGHTMAPUNIT / MAP_COEFF / 2));

  if camera.rotation[0] >= 25.0 then
    FOriginY := FOriginY - LIGHTMAPSIZEY * LIGHTMAPUNIT / MAP_COEFF / 2 + 1.0
  else if camera.rotation[0] <= -25.0 then
    FOriginY := FOriginY + LIGHTMAPSIZEY * LIGHTMAPUNIT / MAP_COEFF / 2 - 1.0;

  if (camera.rotation[1] <= 45.0) and (camera.rotation[1] >= -45.0) then
    FOriginZ := FOriginZ - LIGHTMAPSIZEZ * LIGHTMAPUNIT / MAP_COEFF / 2 + 1.0
  else if (camera.rotation[1] <= 135.0) and (camera.rotation[1] > 45.0) then
    FOriginX := FOriginX + LIGHTMAPSIZEX * LIGHTMAPUNIT / MAP_COEFF / 2 - 1.0
  else if (camera.rotation[1] <= 225.0) and (camera.rotation[1] > 135.0) then
    FOriginZ := FOriginZ + LIGHTMAPSIZEZ * LIGHTMAPUNIT / MAP_COEFF / 2 - 1.0
  else
    FOriginX := FOriginX - LIGHTMAPSIZEX * LIGHTMAPUNIT / MAP_COEFF / 2 + 1.0;

// -----------------------------------------------------------------------------
// Clear the marked regions of lightmap and the rtl lightmap
  memset(FBuffer, 128, FMaxMarkBytes);
  if not FDefined then
  begin
    glTexImage3D(GL_TEXTURE_3D, 0, 3, LIGHTMAPSIZEX, LIGHTMAPSIZEY, LIGHTMAPSIZEZ, 0, GL_RGBA, GL_UNSIGNED_BYTE, FBuffer);
    FDefined := true;  // JVAL: Don't bother reseting this on a new map
  end
  else
  begin
    LMark := @FMarks[FNumMarks];
    while NativeInt(LMark) > NativeInt(FMarks) do
    begin
      dec(LMark);
      // JVAL 20171205 We must clear the mark BEFORE calling glTexSubImage3D :)
      ClearMark(LMark);
      glTexSubImage3D(GL_TEXTURE_3D, 0, LMark.x1, LMark.y1, LMark.z1, LMark.dx, LMark.dy, LMark.dz, GL_RGBA, GL_UNSIGNED_BYTE, FBuffer);
    end;
  end;

// -----------------------------------------------------------------------------
// Itterates all active lights, mark the affected regions, precalc the rtl lightmap
  FMaxMarkBytes := 0;
  FNumMarks := 0;

  // Lightmap boundaries
  LBoundX1 := LightmapToOpenGlX(0);
  LBoundX2 := LightmapToOpenGlX(LIGHTMAPSIZEX - 1);
  LBoundY1 := LightmapToOpenGlY(0);
  LBoundY2 := LightmapToOpenGlY(LIGHTMAPSIZEY - 1);
  LBoundZ1 := LightmapToOpenGlZ(0);
  LBoundZ2 := LightmapToOpenGlZ(LIGHTMAPSIZEZ - 1);

  LItem := @dlbuffer[numdlitems];
  ZeroMemory(@LLastItem, SizeOf(dlsortitem_t));
  while NativeInt(LItem) <> NativeInt(dlbuffer) do
  begin
    dec(LItem);
    if (LItem.l <> LLastItem.l) or
       (LItem.x <> LLastItem.x) or
       (LItem.y <> LLastItem.y) or
       (LItem.z <> LLastItem.z) then
    begin
      LLastItem := LItem^;
      LLightX := LLastItem.x;
      LLightY := LLastItem.y;
      LLightZ := LLastItem.z;

      // Check if the light source is inside the lightmap boundaries
      if (LLightX >= LBoundX1) and (LLightX <= LBoundX2) and
         (LLightY >= LBoundY1) and (LLightY <= LBoundY2) and
         (LLightZ >= LBoundZ1) and (LLightZ <= LBoundZ2) then
      begin
        LLight := LItem.l;
        LCheckRadius := LLight.radius;
        if LCheckRadius <  MINLIGHTMAPRADIOUS then
          LCheckRadius := MINLIGHTMAPRADIOUS;
        LSquareCheck := LCheckRadius * LCheckRadius;
        LSquareCheckInner := LSquareCheck / 1.141421356;

        LIndexX1 := OpenGlToLightmapX(LLightX - LCheckRadius);
        if LIndexX1 < 0 then
          LIndexX1 := 0
        else if LIndexX1 >= LIGHTMAPSIZEX then
          LIndexX1 := LIGHTMAPSIZEX - 1;

        LIndexX2 := OpenGlToLightmapX(LLightX + LCheckRadius);
        if LIndexX2 < 0 then
          LIndexX2 := 0
        else if LIndexX2 >= LIGHTMAPSIZEX then
          LIndexX2 := LIGHTMAPSIZEX - 1;

        LLightY1 := LLightY - LCheckRadius;
        LLightY2 := LLightY + LCheckRadius;

        LMapX := -Round(LLightX * MAP_SCALE);
        LMapY := Round(LLightZ * MAP_SCALE);
        LMapZ := Round(LLightY * MAP_SCALE);
        LSector := TRendererMain.R_PointInSubsector(LMapX, LMapY).sector;
        if LLight.shadow then
        begin
          LLightY1 := (T3dFloorRoutines.P_3dFloorHeight(LSector, LMapX, LMapY, LMapZ) - 4 * FRACUNIT) / MAP_SCALE;
          LLightY2 := LLightY2 - LCheckRadius / 2;
          LFloorZ := (T3dFloorRoutines.P_3dFloorHeight(LSector, LMapX, LMapY, LMapZ) - 4 * FRACUNIT) / MAP_SCALE;
          LCeilingZ := (T3dFloorRoutines.P_3dCeilingHeight(LSector, LMapX, LMapY, LMapZ) + 4 * FRACUNIT) / MAP_SCALE;
          if LLightY2 < LFloorZ then
            LLightY2 := LFloorZ
          else if LLightY2 > LCeilingZ then
            LLightY2 := LCeilingZ;
        end
        else
        begin
          LFloorZ := (T3dFloorRoutines.P_3dFloorHeight(LSector, LMapX, LMapY, LMapZ) - 4 * FRACUNIT) / MAP_SCALE;
          LCeilingZ := (T3dFloorRoutines.P_3dCeilingHeight(LSector, LMapX, LMapY, LMapZ) + 4 * FRACUNIT) / MAP_SCALE;
          if LLightY1 < LFloorZ then
            LLightY1 := LFloorZ
          else if LLightY1 > LCeilingZ then
            LLightY1 := LCeilingZ;
          if LLightY2 < LFloorZ then
            LLightY2 := LFloorZ
          else if LLightY2 > LCeilingZ then
            LLightY2 := LCeilingZ;
        end;

        LIndexY1 := OpenGlToLightmapY(LLightY1);
        if LIndexY1 < 0 then
          LIndexY1 := 0
        else if LIndexY1 >= LIGHTMAPSIZEY then
          LIndexY1 := LIGHTMAPSIZEY - 1;

        LIndexY2 := OpenGlToLightmapY(LLightY2);
        if LIndexY2 < 0 then
          LIndexY2 := 0
        else if LIndexY2 >= LIGHTMAPSIZEY then
          LIndexY2 := LIGHTMAPSIZEY - 1;

        LIndexZ1 := OpenGlToLightmapZ(LLightZ - LCheckRadius);
        if LIndexZ1 < 0 then
          LIndexZ1 := 0
        else if LIndexZ1 >= LIGHTMAPSIZEZ then
          LIndexZ1 := LIGHTMAPSIZEZ - 1;

        LIndexZ2 := OpenGlToLightmapZ(LLightZ + LCheckRadius);
        if LIndexZ2 < 0 then
          LIndexZ2 := 0
        else if LIndexZ2 >= LIGHTMAPSIZEZ then
          LIndexZ2 := LIGHTMAPSIZEZ - 1;

        // Determine the maximum size that will be erased in the next pass
        LSizeX := LIndexX2 - LIndexX1 + 1;
        LSizeY := LIndexY2 - LIndexY1 + 1;
        LSizeZ := LIndexZ2 - LIndexZ1 + 1;
        LByteCount := LSizeX * LSizeY * LSizeZ * 4;
        if LByteCount > FMaxMarkBytes then
          FMaxMarkBytes := LByteCount;

        for LIndexZ := LIndexZ1 to LIndexZ2 do
        begin
          LSquareZ := sqr(LLightZ - LightmapToOpenGlZ(LIndexZ));
          if LSquareZ <= LSquareCheck then
          begin
            for LIndexY := LIndexY1 to LIndexY2 do
            begin
              LSquareYZ := LSquareZ + sqr(LLightY - LightmapToOpenGlY(LIndexY));
              if LSquareYZ <= LSquareCheck then
              begin
                LCell := @FRealTimeMap[LIndexX1 * (LIGHTMAPSIZEX * LIGHTMAPSIZEY) + LIndexY * LIGHTMAPSIZEX + LIndexZ];
                for LIndexX := LIndexX1 to LIndexX2 do
                begin
                  LSquareDistance := LSquareYZ + sqr(LLightX - LightmapToOpenGlX(LIndexX));
                  if LSquareDistance <= LSquareCheckInner then
                  begin
                    if LLight.shadow then
                      inc(LCell.shadow, 2)
                    else
                    begin
                      LCell.r := LCell.r + LLight.r;
                      LCell.g := LCell.g + LLight.g;
                      LCell.b := LCell.b + LLight.b;
                      inc(LCell.inter);
                    end;
                  end
                  else if LSquareDistance <= LSquareCheck then
                  begin
                    if LLight.shadow then
                      inc(LCell.shadow)
                    else
                    begin
                      LCell.r := LCell.r + LLight.r / 2;
                      LCell.g := LCell.g + LLight.g / 2;
                      LCell.b := LCell.b + LLight.b / 2;
                      inc(LCell.inter);
                    end;
                  end;
                  inc(LCell, LIGHTMAPSIZEX * LIGHTMAPSIZEY);
                end;
              end;
            end;
          end;
        end;

        // Grow the marks array if needed
        if FNumMarks = FMaxMarks then
        begin
          realloc(pointer(FMarks), FMaxMarks * SizeOf(TLightmapMark), (FMaxMarks + 16) * SizeOf(TLightmapMark));
          FMaxMarks := FMaxMarks + 16;
        end;
        LMark := @FMarks[FNumMarks];
        LMark.x1 := LIndexX1;
        LMark.x2 := LIndexX2;
        LMark.y1 := LIndexY1;
        LMark.y2 := LIndexY2;
        LMark.z1 := LIndexZ1;
        LMark.z2 := LIndexZ2;
        LMark.dx := LSizeX;
        LMark.dy := LSizeY;
        LMark.dz := LSizeZ;
        inc(FNumMarks);

      end;
    end;
  end;

// -----------------------------------------------------------------------------
// Create the lightmap texture, uses the affected regions and the rtl lightmap
  LMark := @FMarks[FNumMarks];
  while NativeInt(LMark) > NativeInt(FMarks) do
  begin
    dec(LMark);
    LPoint := @FBuffer[0];
    for LIndexZ := LMark.z1 to LMark.z2 do
    begin
      for LIndexY := LMark.y1 to LMark.y2 do
      begin
        LCell := @FRealTimeMap[LMark.x1 * (LIGHTMAPSIZEX * LIGHTMAPSIZEY) + LIndexY * LIGHTMAPSIZEX + LIndexZ];
        for LIndexX := LMark.x1 to LMark.x2 do
        begin
          if (LCell.inter = 0) and (LCell.shadow = 0) then
          begin
            PLongWord(LPoint)^ := $80808080;
            inc(LPoint, 4);
          end
          else
          begin
            if LCell.shadow = 0 then
            begin
              LPoint^ := FloatToByte(128.0 + LCell.r * 127);
              inc(LPoint);
              LPoint^ := FloatToByte(128.0 + LCell.g * 127);
              inc(LPoint);
              LPoint^ := FloatToByte(128.0 + LCell.b * 127);
              inc(LPoint);
              LPoint^ := $80;
              inc(LPoint);
            end
            else
            begin
              if LCell.shadow >= MAXSHADOWSHIFT then
                LShadowFactor := FShadowFactor[MAXSHADOWSHIFT - 1]
              else
                LShadowFactor := FShadowFactor[LCell.shadow];
              LPoint^ := FloatToByte(LShadowFactor + LCell.r * 127);
              inc(LPoint);
              LPoint^ := FloatToByte(LShadowFactor + LCell.g * 127);
              inc(LPoint);
              LPoint^ := FloatToByte(LShadowFactor + LCell.b * 127);
              inc(LPoint);
              LPoint^ := $80;
              inc(LPoint);
            end;
          end;
          inc(LCell, LIGHTMAPSIZEX * LIGHTMAPSIZEY);
        end;
      end;
    end;
    glTexSubImage3D(GL_TEXTURE_3D, 0, LMark.x1, LMark.y1, LMark.z1, LMark.dx, LMark.dy, LMark.dz, GL_RGBA, GL_UNSIGNED_BYTE, FBuffer);
  end;
end;

//==============================================================================
//
// PlaceTexture
//
// Texture positioning in world coordinates
//
//==============================================================================
procedure TEngineGlLightmapCalculator.PlaceTexture;
begin
  glMatrixMode(GL_TEXTURE);
  glPushMatrix;
  glTranslatef(-FOriginX * MAP_COEFF / (LIGHTMAPSIZEX * LIGHTMAPUNIT),
               -FOriginY * MAP_COEFF / (LIGHTMAPSIZEY * LIGHTMAPUNIT),
               -FOriginZ * MAP_COEFF / (LIGHTMAPSIZEZ * LIGHTMAPUNIT));

  glMatrixMode(GL_MODELVIEW);
end;

//==============================================================================
//
// Export
//
//==============================================================================
procedure TEngineGlLightmapCalculator.Export(const AFileName: string);
var
  x, y, z: integer;
  lst: TDStringList;
  tmp: string;
  c: LongWord;
  skips: integer;
  blancline: boolean;
  lp: PLightmapExport;

  function _get_color(const rl: TLightmapCell): LongWord;
  var
    r, g, b: integer;
  begin
    r := Round(rl.r * 256);
    if r < 0 then
      r := 0
    else if r > 255 then
      r := 255;
    g := Round(rl.g * 256);
    if r < 0 then
      g := 0
    else if g > 255 then
      g := 255;
    b := Round(rl.b * 256);
    if b < 0 then
      b := 0
    else if b > 255 then
      b := 255;
    Result := b shl 16 + g shl 8 + r;
  end;

begin
  if strtrim(AFileName) = '' then
  begin
    printf('Please specify the output filename'#13#10);
    exit;
  end;

  lp := mallocz(SizeOf(TLightmapExport));

  for x := 0 to LIGHTMAPSIZEX - 1 do
    for y := 0 to LIGHTMAPSIZEY - 1 do
      for z := 0 to LIGHTMAPSIZEZ - 1 do
        lp[x, y, z] := _get_color(FRealTimeMap[x * (LIGHTMAPSIZEX * LIGHTMAPSIZEY) + y * LIGHTMAPSIZEX + z]);

  lst := TDStringList.Create;
  try
    lst.Add(itoa(LIGHTMAPSIZEX));
    for x := 0 to LIGHTMAPSIZEX - 1 do
      for y := 0 to LIGHTMAPSIZEX - 1 do
      begin
        tmp := '';
        blancline := True;
        skips := 0;
        for z := 0 to LIGHTMAPSIZEX - 1 do
        begin
          c := lp[LIGHTMAPSIZEX - 1 - x, LIGHTMAPSIZEX - 1 - y, z];
          if c <> 0 then
            blancline := False
          else if blancline then
            inc(skips);
          if not blancline then
            tmp := tmp + ' ' + itoa(c);
        end;
        if blancline then
          lst.Add('skip ' + itoa(LIGHTMAPSIZEX))
        else
        begin
          if skips > 0 then
            lst.Add('skip ' + itoa(skips) + ' ' + tmp)
          else
            lst.Add(tmp);
        end;
      end;
    lst.SaveToFile(AFileName);
  finally
    lst.Free;
  end;
  freemem(pointer(lp), SizeOf(TLightmapExport));
end;

end.
