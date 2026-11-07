{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lumps of a classic map                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.MapReader;

interface

uses
  DelphiDoom.GameState.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   Reads the lumps of a classic map (VERTEXES, SECTORS, SIDEDEFS, LINEDEFS, SSECTORS, NODES,
  ///   SEGS, REJECT) in the global structures of p_setup.pas and groups the lines in the
  ///   sectors. What depends on the game (fields of the sectors, textures of the sides,
  ///   arguments of the lines, the lines drawn as transparent or with a colormap) is asked to
  ///   the rules of the game. It was the P_Load* procedures of p_setup.pas
  /// </summary>
  TEngineLevelMapReader = class(TInterfacedObject, ILevelMapReader)
  strict private
    FRules: ILevelGeometryRules;
    FGame: IGameContext;
    procedure FindSubsectorSectors;
    procedure CountSectorLines(out ATotal: Integer);
    procedure BuildSectorLines(ATotal: Integer);
  public
    /// <summary>AGame says when the lines with wrong sides are printed (-devparm)</summary>
    constructor Create(const ARules: ILevelGeometryRules; const AGame: IGameContext);
    procedure LoadVertexes(ALump: Integer);
    procedure LoadSectors(ALump: Integer);
    procedure LoadSideDefs(ALump: Integer);
    procedure LoadLineDefs(ALump: Integer);
    procedure LoadSubsectors(ALump: Integer);
    procedure LoadNodes(ALump: Integer);
    procedure LoadSegs(ALump: Integer);
    procedure LoadReject(ALump: Integer);
    procedure GroupLines;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdef,
  doomdata,
  doomtype,
  m_fixed,
  i_system,
  w_wad,
  z_zone,
  r_defs,
  r_data,
  p_local,
  p_setup,
  r_intrpl,
{$IFDEF OPENGL}
  gl_setup,
{$ENDIF}
  DelphiDoom.MathCore.Types,
  DelphiDoom.MathCore.BoundingBox;

{ TEngineLevelMapReader }

constructor TEngineLevelMapReader.Create(const ARules: ILevelGeometryRules; const AGame: IGameContext);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EArgumentNilException.Create('ARules');
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FRules := ARules;
  FGame := AGame;
end;

procedure TEngineLevelMapReader.LoadVertexes(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LMapVertex: Pmapvertex_t;
  LVertex: Pvertex_t;
  LMinX, LMaxX, LMinY, LMaxY: Integer;
  LDeltaX, LDeltaY: Integer;
begin
  numvertexes := W_LumpLength(ALump) div SizeOf(mapvertex_t);
  vertexes := Z_Malloc(numvertexes * SizeOf(vertex_t), PU_LEVEL, nil);
  LData := W_CacheLumpNum(ALump, PU_STATIC);
  LMapVertex := Pmapvertex_t(LData);

  // internal representation as fixed
  LVertex := @vertexes[0];

  // JVAL: 20200414 -> Find map boundaries
  LMinX := 100000;
  LMaxX := -100000;
  LMinY := 100000;
  LMaxY := -100000;
  for LIndex := 0 to numvertexes - 1 do
  begin
    if LMapVertex.x > LMaxX then
      LMaxX := LMapVertex.x;
    if LMapVertex.x < LMinX then
      LMinX := LMapVertex.x;
    if LMapVertex.y > LMaxY then
      LMaxY := LMapVertex.y;
    if LMapVertex.y < LMinY then
      LMinY := LMapVertex.y;
    LVertex.x := LMapVertex.x * FRACUNIT;
    LVertex.y := LMapVertex.y * FRACUNIT;
    LVertex.amvalidcount := 0;
    LVertex.interpvalidcount := 0;
    Inc(LMapVertex);
    Inc(LVertex);
  end;

  LDeltaX := LMaxX - LMinX;
  LDeltaY := LMaxY - LMinY;
  largemap := (LDeltaX < -32767) or (LDeltaX > 32767) or (LDeltaY < -32767) or (LDeltaY > 32767);

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadSegs(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LMapSeg: Pmapseg_t;
  LSeg: Pseg_t;
  LLine: Pline_t;
  LLineNumber: Integer;
  LSide: Integer;
  LSideNumber: Integer;
begin
  numsegs := W_LumpLength(ALump) div SizeOf(mapseg_t);
  segs := Z_Malloc(numsegs * SizeOf(seg_t), PU_LEVEL, nil);
  ZeroMemory(segs, numsegs * SizeOf(seg_t));
  LData := W_CacheLumpNum(ALump, PU_STATIC);

  LMapSeg := Pmapseg_t(LData);
  LSeg := @segs[0];
  for LIndex := 0 to numsegs - 1 do
  begin
    LSeg.v1 := @vertexes[smallintwarp2(LMapSeg.v1)];
    LSeg.v2 := @vertexes[smallintwarp2(LMapSeg.v2)];

    LSeg.angle := LMapSeg.angle * FRACUNIT;
    LSeg.offset := LMapSeg.offset * FRACUNIT;
    LLineNumber := smallintwarp2(LMapSeg.linedef);
    LLine := @lines[LLineNumber];
    LSeg.linedef := LLine;
    LSide := smallintwarp2(LMapSeg.side);
    LSeg.sidedef := @sides[LLine.sidenum[LSide]];
    LSeg.frontsector := LSeg.sidedef.sector;
    if LLine.flags and ML_TWOSIDED <> 0 then
    begin
      LSideNumber := LLine.sidenum[LSide xor 1];
      if LSideNumber = -1 then
      begin
        I_Warning('P_LoadSegs(): Line %d is marked with ML_TWOSIDED flag without backsector'#13#10, [LLineNumber]);
        LLine.flags := LLine.flags and not ML_TWOSIDED;
        LSeg.backsector := nil;
      end
      else
        LSeg.backsector := sides[LSideNumber].sector
    end
    else
      LSeg.backsector := nil;
{$IFDEF OPENGL}
    LSeg.length := GetDistance(LSeg.v2.x - LSeg.v1.x, LSeg.v2.y - LSeg.v1.y);
    LSeg.iSegID := LIndex;
{$ENDIF}
    LSeg.miniseg := False;
    Inc(LMapSeg);
    Inc(LSeg);
  end;

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadSubsectors(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LMapSubsector: Pmapsubsector_t;
  LSubsector: Psubsector_t;
begin
  numsubsectors := W_LumpLength(ALump) div SizeOf(mapsubsector_t);
  subsectors := Z_Malloc(numsubsectors * SizeOf(subsector_t), PU_LEVEL, nil);
  LData := W_CacheLumpNum(ALump, PU_STATIC);

  LMapSubsector := Pmapsubsector_t(LData);
  ZeroMemory(subsectors, numsubsectors * SizeOf(subsector_t));

  LSubsector := @subsectors[0];
  for LIndex := 0 to numsubsectors - 1 do
  begin
    LSubsector.numlines := LMapSubsector.numsegs;
    LSubsector.firstline := LMapSubsector.firstseg;
    Inc(LMapSubsector);
    Inc(LSubsector);
  end;

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadSectors(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LMapSector: Pmapsector_t;
  LSector: Psector_t;
begin
  numsectors := W_LumpLength(ALump) div SizeOf(mapsector_t);
  sectors := Z_Malloc(numsectors * SizeOf(sector_t), PU_LEVEL, nil);
  ZeroMemory(sectors, numsectors * SizeOf(sector_t));
  LData := W_CacheLumpNum(ALump, PU_STATIC);

  LMapSector := Pmapsector_t(LData);
  LSector := @sectors[0];
  for LIndex := 0 to numsectors - 1 do
  begin
    LSector.floorheight := LMapSector.floorheight * FRACUNIT;
    LSector.ceilingheight := LMapSector.ceilingheight * FRACUNIT;
    LSector.floorpic := R_FlatNumForName(LMapSector.floorpic);
    LSector.ceilingpic := R_FlatNumForName(LMapSector.ceilingpic);
    // https://www.doomworld.com/forum/topic/118126-doom-sector-light-levels/
    // JVAL: 20220116 -> If sector lightlevel in WAD is 256 change it to 255,
    //                   do not treat as fog sector
    if LMapSector.lightlevel = 256 then
      LMapSector.lightlevel := $FF;
    LSector.lightlevel := LMapSector.lightlevel;
    LSector.special := LMapSector.special;
    LSector.tag := LMapSector.tag;
    LSector.thinglist := nil;
    LSector.midsec := -1;    // JVAL: 3d floors
    LSector.midline := -1;
    LSector.renderflags := 0;
    if LSector.lightlevel >= 1000 then // JVAL: Fog sectors
    begin
      LSector.renderflags := LSector.renderflags or SRF_FOG;
      LSector.lightlevel := LSector.lightlevel - 1000;
    end;
    LSector.flags := 0;
    LSector.gravity := GRAVITY;  // JVAL: sector gravity (VERSION 204)
    LSector.floorangle := 0;     // JVAL: 20200221 - Texture angle
    LSector.flooranglex := 0;    // JVAL: 20201229 - Texture angle rover
    LSector.floorangley := 0;    // JVAL: 20201229 - Texture angle rover
    LSector.ceilingangle := 0;   // JVAL: 20200221 - Texture angle
    LSector.ceilinganglex := 0;  // JVAL: 20201229 - Texture angle rover
    LSector.ceilingangley := 0;  // JVAL: 20201229 - Texture angle rover
{$IFNDEF OPENGL}
    // [kb] For R_WiggleFix
    LSector.cachedheight := 0;
    LSector.scaleindex := 0;
    // JVAL: 20201225 - Speed up maps with large number of slopes
    LSector.floorvisslope := -1;
    LSector.ceilingvisslope := -1;
{$ENDIF}
    // JVAL: 20220327 - Group sectors to interpolate groups
    LSector.interpolate_group := LIndex mod NUM_SECTOR_INTERPOLATE_GROUPS;

    LSector.iSectorID := LIndex; // JVAL: 3d Floors
    FRules.InitializeSector(LSector);
    Inc(LMapSector);
    Inc(LSector);
  end;

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadNodes(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LChild: Integer;
  LCorner: Integer;
  LMapNode: Pmapnode_t;
  LNode: Pnode_t;
begin
  numnodes := W_LumpLength(ALump) div SizeOf(mapnode_t);
  nodes := Z_Malloc(numnodes * SizeOf(node_t), PU_LEVEL, nil);
  LData := W_CacheLumpNum(ALump, PU_STATIC);

  LMapNode := Pmapnode_t(LData);
  LNode := @nodes[0];
  for LIndex := 0 to numnodes - 1 do
  begin
    LNode.x := LMapNode.x * FRACUNIT;
    LNode.y := LMapNode.y * FRACUNIT;
    LNode.dx := LMapNode.dx * FRACUNIT;
    LNode.dy := LMapNode.dy * FRACUNIT;
    for LChild := 0 to 1 do
    begin
      // JVAL: glbsp
      if LMapNode.children[LChild] and NF_SUBSECTOR <> 0 then
      begin
        LMapNode.children[LChild] := LMapNode.children[LChild] and not NF_SUBSECTOR;
        LNode.children[LChild] := LMapNode.children[LChild];
        LNode.children[LChild] := LNode.children[LChild] or NF_SUBSECTOR_V5;
      end
      else
        LNode.children[LChild] := LMapNode.children[LChild];

      for LCorner := 0 to 3 do
        LNode.bbox[LChild, LCorner] := LMapNode.bbox[LChild, LCorner] * FRACUNIT;
    end;
    Inc(LMapNode);
    Inc(LNode);
  end;

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadLineDefs(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LMapLine: Pmaplinedef_t;
  LLine: Pline_t;
  LVertex1: Pvertex_t;
  LVertex2: Pvertex_t;
  LSize: Integer;
begin
  LSize := W_LumpLength(ALump);
  numlines := LSize div SizeOf(maplinedef_t);
  lines := Z_Malloc(numlines * SizeOf(line_t), PU_LEVEL, nil);
  ZeroMemory(lines, numlines * SizeOf(line_t));
  LData := W_CacheLumpNum(ALump, PU_STATIC);

  FRules.FixLineDefs(LData, LSize, numlines);

  LMapLine := Pmaplinedef_t(LData);
  LLine := @lines[0];
  for LIndex := 0 to numlines - 1 do
  begin
    LLine.flags := LMapLine.flags;
    LLine.special := LMapLine.special;
    FRules.ReadLineArguments(LMapLine, LLine);
    LLine.v1 := @vertexes[smallintwarp2(LMapLine.v1)];
    LVertex1 := LLine.v1;
    LLine.v2 := @vertexes[smallintwarp2(LMapLine.v2)];
    LVertex2 := LLine.v2;
    LLine.dx := LVertex2.x - LVertex1.x;
    LLine.dy := LVertex2.y - LVertex1.y;

    if LLine.dx = 0 then
      LLine.slopetype := ST_VERTICAL
    else if LLine.dy = 0 then
      LLine.slopetype := ST_HORIZONTAL
    else if FixedDiv(LLine.dy, LLine.dx) > 0 then
      LLine.slopetype := ST_POSITIVE
    else
      LLine.slopetype := ST_NEGATIVE;

    if LVertex1.x < LVertex2.x then
    begin
      LLine.bbox[BOX_LEFT] := LVertex1.x;
      LLine.bbox[BOX_RIGHT] := LVertex2.x;
    end
    else
    begin
      LLine.bbox[BOX_LEFT] := LVertex2.x;
      LLine.bbox[BOX_RIGHT] := LVertex1.x;
    end;

    if LVertex1.y < LVertex2.y then
    begin
      LLine.bbox[BOX_BOTTOM] := LVertex1.y;
      LLine.bbox[BOX_TOP] := LVertex2.y;
    end
    else
    begin
      LLine.bbox[BOX_BOTTOM] := LVertex2.y;
      LLine.bbox[BOX_TOP] := LVertex1.y;
    end;

    LLine.sidenum[0] := smallintwarp1(LMapLine.sidenum[0]);
    LLine.sidenum[1] := smallintwarp1(LMapLine.sidenum[1]);

    if (LLine.sidenum[0] >= 0) and (LLine.sidenum[0] < numsides) then
      LLine.frontsector := sides[LLine.sidenum[0]].sector
    else
    begin
      if FGame.IsDeveloperMode then
        printf('P_LoadLineDefs(): Line %d does has invalid front sidedef %d'#13#10, [LIndex, LLine.sidenum[0]]);
      LLine.sidenum[0] := 0;
      LLine.frontsector := sides[0].sector;
    end;

    if (LLine.sidenum[1] >= 0) and (LLine.sidenum[1] < numsides) then
      LLine.backsector := sides[LLine.sidenum[1]].sector
    else
    begin
      LLine.backsector := nil;
      if FGame.IsDeveloperMode then
        if LLine.sidenum[1] >= numsides then
          printf('P_LoadLineDefs(): Line %d does has invalid back sidedef %d'#13#10, [LIndex, LLine.sidenum[0]]);
    end;

    LLine.renderflags := 0;

    Inc(LMapLine);
    Inc(LLine);
  end;

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadSideDefs(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LMapSide: Pmapsidedef_t;
  LSide: Pside_t;
begin
  numsides := W_LumpLength(ALump) div SizeOf(mapsidedef_t);
  sides := Z_Malloc(numsides * SizeOf(side_t), PU_LEVEL, nil);
  ZeroMemory(sides, numsides * SizeOf(side_t));
  LData := W_CacheLumpNum(ALump, PU_STATIC);

  LMapSide := Pmapsidedef_t(LData);
  LSide := @sides[0];
  for LIndex := 0 to numsides - 1 do
  begin
    LSide.textureoffset := LMapSide.textureoffset * FRACUNIT;
    LSide.rowoffset := LMapSide.rowoffset * FRACUNIT;
    FRules.ReadSideTextures(LMapSide, LSide);
    LSide.sector := @sectors[smallintwarp2(LMapSide.sector)];
    Inc(LMapSide);
    Inc(LSide);
  end;

  Z_Free(LData);
end;

procedure TEngineLevelMapReader.LoadReject(ALump: Integer);
begin
  rejectmatrix := W_CacheLumpNum(ALump, PU_LEVEL);
  rejectmatrixsize := W_LumpLength(ALump);
end;

procedure TEngineLevelMapReader.FindSubsectorSectors;
var
  LIndex: Integer;
  LInner: Integer;
  LSubsector: Psubsector_t;
  LSeg: Pseg_t;
begin
  LSubsector := @subsectors[0];
  for LIndex := 0 to numsubsectors - 1 do
  begin
    LSeg := @segs[LSubsector.firstline];
    LSubsector.sector := nil;
    for LInner := 0 to LSubsector.numlines - 1 do
    begin
      if LSeg.sidedef <> nil then
      begin
        LSubsector.sector := LSeg.sidedef.sector;
        Break;
      end;
      Inc(LSeg);
    end;
    if LSubsector.sector = nil then
      I_Error('P_GroupLines(): Subsector %d is not part of a sector', [LIndex]);
    Inc(LSubsector);
  end;
end;

procedure TEngineLevelMapReader.CountSectorLines(out ATotal: Integer);
var
  LIndex: Integer;
  LLine: Pline_t;
begin
  ATotal := 0;
  for LIndex := 0 to numlines - 1 do
  begin
    LLine := @lines[LIndex];
    Inc(ATotal);
    if LLine.frontsector <> nil then
      LLine.frontsector.linecount := LLine.frontsector.linecount + 1
    else
    begin
      if LLine.backsector = nil then
        I_Warning('P_GroupLines(): Line %d is missing frontsector & backsector'#13#10, [LIndex])
      else
        I_Warning('P_GroupLines(): Line %d is missing frontsector'#13#10, [LIndex]);
    end;

    if (LLine.backsector <> nil) and (LLine.backsector <> LLine.frontsector) then
    begin
      LLine.backsector.linecount := LLine.backsector.linecount + 1;
      Inc(ATotal);
    end;
  end;
end;

procedure TEngineLevelMapReader.BuildSectorLines(ATotal: Integer);
var
  LLineBuffer: Pline_tPArray; // pointer to an array of pointers Pline_t
  LIndex: Integer;
  LInner: Integer;
  LLine: Pline_t;
  LSector: Psector_t;
  LBox: TBoundingBox;
  LBlock: Integer;
  LInternal: Boolean;
begin
  // the same for every sector of the level
  LInternal := FRules.UsesInternalBlockCoordinates;

  LLineBuffer := Z_Malloc(ATotal * SizeOf(Pline_t), PU_LEVEL, nil);
  LSector := @sectors[0];
  for LIndex := 0 to numsectors - 1 do
  begin
    TBoundingBoxMath.Clear(LBox);
    LSector.lines := LLineBuffer;
    LLine := @lines[0];
    for LInner := 0 to numlines - 1 do
    begin
      if (LLine.frontsector = LSector) or (LLine.backsector = LSector) then
      begin
        LLineBuffer[0] := LLine;
        LLineBuffer := @LLineBuffer[1];
        TBoundingBoxMath.AddPoint(LBox, LLine.v1.x, LLine.v1.y);
        TBoundingBoxMath.AddPoint(LBox, LLine.v2.x, LLine.v2.y);
      end;
      Inc(LLine);
    end;
    if pDiff(LLineBuffer, LSector.lines, SizeOf(Pointer)) <> LSector.linecount then
      I_Error('P_GroupLines(): miscounted');

    // set the degenmobj_t to the middle of the bounding box
    if largemap then
    begin
      LSector.soundorg.x := LBox[BOX_RIGHT] div 2 + LBox[BOX_LEFT] div 2;
      LSector.soundorg.y := LBox[BOX_TOP] div 2 + LBox[BOX_BOTTOM] div 2;
    end
    else
    begin
      LSector.soundorg.x := (LBox[BOX_RIGHT] + LBox[BOX_LEFT]) div 2;
      LSector.soundorg.y := (LBox[BOX_TOP] + LBox[BOX_BOTTOM]) div 2;
    end;

    // adjust bounding box to map blocks
    if LInternal then
      LBlock := MapBlockIntY(Int64(LBox[BOX_TOP]) - Int64(bmaporgy) + MAXRADIUS)
    else
      LBlock := MapBlockInt(LBox[BOX_TOP] - bmaporgy + MAXRADIUS);
    if LBlock >= bmapheight then
      LBlock := bmapheight - 1;
    LSector.blockbox[BOX_TOP] := LBlock;

    if LInternal then
      LBlock := MapBlockIntY(Int64(LBox[BOX_BOTTOM]) - Int64(bmaporgy) - MAXRADIUS)
    else
      LBlock := MapBlockInt(LBox[BOX_BOTTOM] - bmaporgy - MAXRADIUS);
    if LBlock < 0 then
      LBlock := 0;
    LSector.blockbox[BOX_BOTTOM] := LBlock;

    if LInternal then
      LBlock := MapBlockIntX(Int64(LBox[BOX_RIGHT]) - Int64(bmaporgx) + MAXRADIUS)
    else
      LBlock := MapBlockInt(LBox[BOX_RIGHT] - bmaporgx + MAXRADIUS);
    if LBlock >= bmapwidth then
      LBlock := bmapwidth - 1;
    LSector.blockbox[BOX_RIGHT] := LBlock;

    if LInternal then
      LBlock := MapBlockIntX(Int64(LBox[BOX_LEFT]) - Int64(bmaporgx) - MAXRADIUS)
    else
      LBlock := MapBlockInt(LBox[BOX_LEFT] - bmaporgx - MAXRADIUS);
    if LBlock < 0 then
      LBlock := 0;
    LSector.blockbox[BOX_LEFT] := LBlock;

    Inc(LSector);
  end;
end;

procedure TEngineLevelMapReader.GroupLines;
var
  LTotal: Integer;
begin
  FRules.BeforeGroupLines;
  // look up sector number for each subsector
  FindSubsectorSectors;
  // count number of lines in each sector
  CountSectorLines(LTotal);
  FRules.MarkTransparentLines;
  // build line tables for each sector
  BuildSectorLines(LTotal);
  FRules.AfterGroupLines;
end;

end.
