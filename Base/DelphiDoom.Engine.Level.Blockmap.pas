{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the blockmap of a level                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.Blockmap;

interface

uses
  DelphiDoom.Blockmap.Types,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   The blockmap of the level in blockmaplump, blockmap, blocklinks and the variables of
  ///   p_setup.pas: the lump BLOCKMAP if it can be used, otherwise built from the lines (a
  ///   missing, too small or too big lump, a large map or -blockmap). Also the removal of the
  ///   slime trails (killough 10/98). The calculations are the ones of Libs\Blockmap
  /// </summary>
  TEngineLevelBlockmap = class(TInterfacedObject, ILevelBlockmap)
  strict private
    FBuilder: IBlockmapBuilder;
    FLumpReader: IBlockmapLumpReader;
    FSlimeTrails: ISlimeTrailRemover;
    FLumps: IEngineLumps;
    FZone: IZoneAllocator;
    function BuildFromLines: TBlockmapData;
    function ReadData(ALump: Integer): TBlockmapData;
    procedure StoreData(const AData: TBlockmapData);
  public
    /// <summary>ALumps gives the lump BLOCKMAP and AZone the memory of the level</summary>
    constructor Create(const ABuilder: IBlockmapBuilder; const ALumpReader: IBlockmapLumpReader;
      const ASlimeTrails: ISlimeTrailRemover; const ALumps: IEngineLumps;
      const AZone: IZoneAllocator);
    procedure Load(ALump: Integer);
    /// <summary>
    ///   Slime trails are inherent to Doom's coordinate system: a node builder cannot avoid them
    ///   because two lines through integer points may cross at a point that is not integer, and
    ///   a WAD has no fractional coordinates. The vertex of a seg that is not an end of its
    ///   linedef is moved onto the linedef (law of cosines); orthogonal linedefs and minisegs
    ///   are skipped
    /// </summary>
    procedure RemoveSlimeTrails;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  m_fixed,
  m_argv,
  i_system,
  r_defs,
  p_setup,
  DelphiDoom.Zone.Types;

{ TEngineLevelBlockmap }

constructor TEngineLevelBlockmap.Create(const ABuilder: IBlockmapBuilder;
  const ALumpReader: IBlockmapLumpReader; const ASlimeTrails: ISlimeTrailRemover;
  const ALumps: IEngineLumps; const AZone: IZoneAllocator);
begin
  inherited Create;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  if not Assigned(ALumpReader) then
    raise EArgumentNilException.Create('ALumpReader');
  if not Assigned(ASlimeTrails) then
    raise EArgumentNilException.Create('ASlimeTrails');
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(AZone) then
    raise EArgumentNilException.Create('AZone');
  FBuilder := ABuilder;
  FLumpReader := ALumpReader;
  FSlimeTrails := ASlimeTrails;
  FLumps := ALumps;
  FZone := AZone;
end;

function TEngineLevelBlockmap.BuildFromLines: TBlockmapData;
var
  LIndex: Integer;
  LVertexes: TArray<TBlockmapPoint>;
  LLines: TArray<TBlockmapLine>;
begin
  SetLength(LVertexes, numvertexes);
  for LIndex := 0 to numvertexes - 1 do
  begin
    LVertexes[LIndex].X := vertexes[LIndex].x;
    LVertexes[LIndex].Y := vertexes[LIndex].y;
  end;
  SetLength(LLines, numlines);
  for LIndex := 0 to numlines - 1 do
  begin
    LLines[LIndex].X1 := lines[LIndex].v1.x;
    LLines[LIndex].Y1 := lines[LIndex].v1.y;
    LLines[LIndex].X2 := lines[LIndex].v2.x;
    LLines[LIndex].Y2 := lines[LIndex].v2.y;
  end;
  Result := FBuilder.Build(LVertexes, LLines);
end;

function TEngineLevelBlockmap.ReadData(ALump: Integer): TBlockmapData;
var
  LCount: Integer;
  LLumpBytes: TBytes;
  LFromLump: Boolean;
begin
  LFromLump := False;
  LCount := FLumps.LengthOf(ALump);
  if (M_CheckParm('-blockmap') = 0) and not largemap and (LCount > 0) then
  begin
    SetLength(LLumpBytes, LCount);
    FLumps.Read(ALump, @LLumpBytes[0]);
    LFromLump := FLumpReader.IsUsable(LLumpBytes);
  end;

  try
    if LFromLump then
      Result := FLumpReader.Read(LLumpBytes)
    else
      Result := BuildFromLines;
  except
    on E: EBlockmapException do
      I_Error('P_LoadBlockMap(): %s', [E.Message]);
  end;
end;

procedure TEngineLevelBlockmap.StoreData(const AData: TBlockmapData);
var
  LSize: Integer;
  LCount: Integer;
begin
  LSize := Length(AData.Lump) * SizeOf(Integer);
  blockmaplump := FZone.Allocate(LSize, ZONE_TAG_LEVEL, nil);
  Move(AData.Lump[0], blockmaplump[0], LSize);
  blockmapxneg := AData.NegX;
  blockmapyneg := AData.NegY;
  internalblockmapformat := AData.Built;

  blockmap := @blockmaplump[4];

  bmaporgx := blockmaplump[0] * FRACUNIT;
  bmaporgy := blockmaplump[1] * FRACUNIT;
  bmapwidth := blockmaplump[2];
  bmapheight := blockmaplump[3];
  bmapsize := bmapwidth * bmapheight;
  // clear out mobj chains
  LCount := SizeOf(blocklinkitem_t) * bmapwidth * bmapheight;
  blocklinks := FZone.Allocate(LCount, ZONE_TAG_LEVEL, nil);
  ZeroMemory(blocklinks, LCount);
end;

procedure TEngineLevelBlockmap.Load(ALump: Integer);
begin
  StoreData(ReadData(ALump));
end;

procedure TEngineLevelBlockmap.RemoveSlimeTrails;
var
  LIndex: Integer;
  LVertexes: TArray<TBlockmapPoint>;
  LSegs: TArray<TBlockmapSeg>;
begin
  SetLength(LVertexes, numvertexes);
  for LIndex := 0 to numvertexes - 1 do
  begin
    LVertexes[LIndex].X := vertexes[LIndex].x;
    LVertexes[LIndex].Y := vertexes[LIndex].y;
  end;
  SetLength(LSegs, numsegs);
  for LIndex := 0 to numsegs - 1 do
  begin
    LSegs[LIndex].Vertex1 := (NativeInt(segs[LIndex].v1) - NativeInt(vertexes)) div SizeOf(vertex_t);
    LSegs[LIndex].Vertex2 := (NativeInt(segs[LIndex].v2) - NativeInt(vertexes)) div SizeOf(vertex_t);
    LSegs[LIndex].Miniseg := segs[LIndex].miniseg;
    if not segs[LIndex].miniseg then
    begin
      LSegs[LIndex].LineVertex1 := (NativeInt(segs[LIndex].linedef.v1) - NativeInt(vertexes)) div SizeOf(vertex_t);
      LSegs[LIndex].LineVertex2 := (NativeInt(segs[LIndex].linedef.v2) - NativeInt(vertexes)) div SizeOf(vertex_t);
      LSegs[LIndex].LineDeltaX := segs[LIndex].linedef.dx;
      LSegs[LIndex].LineDeltaY := segs[LIndex].linedef.dy;
    end;
  end;

  try
    FSlimeTrails.Remove(LVertexes, LSegs);
  except
    on E: EBlockmapException do
      I_Error('P_RemoveSlimeTrails(): %s', [E.Message]);
  end;

  for LIndex := 0 to numvertexes - 1 do
  begin
    vertexes[LIndex].x := LVertexes[LIndex].X;
    vertexes[LIndex].y := LVertexes[LIndex].Y;
  end;
end;

end.
