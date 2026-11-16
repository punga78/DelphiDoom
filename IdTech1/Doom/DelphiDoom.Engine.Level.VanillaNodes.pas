{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the nodes of the old engine for the old demos of Doom  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.VanillaNodes;

interface

uses
  DelphiDoom.Nodes.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   The lumps SSECTORS, NODES and SEGS of the map read as the old engine read them (JVAL:
  ///   20210131), in vanillasubsectors[], vanillanodes[] and vanillasegs[] of p_setup.pas: the
  ///   demos of the versions before 1.10 play with them. A lump with 32768 or more records is
  ///   left out. It was P_LoadVanillaSegs, P_LoadVanillaSubsectors and P_LoadVanillaNodes
  /// </summary>
  TEngineVanillaNodes = class(TInterfacedObject, ILevelVanillaNodes)
  strict private
    FSource: INodesLumpSource;
    procedure LoadSegs(ALump: Integer);
    procedure LoadSubsectors(ALump: Integer);
    procedure LoadNodes(ALump: Integer);
  public
    constructor Create(const ASource: INodesLumpSource);
    procedure Load(AMapLump: Integer);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdata,
  m_fixed,
  w_wad,
  z_zone,
  r_defs,
  p_setup,
  DelphiDoom.Nodes.Types,
  DelphiDoom.Nodes.VanillaParser;

const
  // the old engine counted the records in 16 bit
  MAX_VANILLA_RECORDS = 32768;

{ TEngineVanillaNodes }

constructor TEngineVanillaNodes.Create(const ASource: INodesLumpSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

procedure TEngineVanillaNodes.LoadSegs(ALump: Integer);
var
  LMapSegs: TArray<TNodesVanillaSeg>;
  LIndex: Integer;
  LMapSeg: TNodesVanillaSeg;
  LSeg: Pvanillaseg_t;
  LLine: Pline_t;
  LSide: Integer;
begin
  LMapSegs := TNodesVanillaParser.ParseSegs(FSource.ReadLump(ALump));
  numvanillasegs := Length(LMapSegs);
  if numvanillasegs >= MAX_VANILLA_RECORDS then
  begin
    numvanillasegs := 0;
    Exit;
  end;

  vanillasegs := Z_Malloc(numvanillasegs * SizeOf(vanillaseg_t), PU_LEVEL, nil);
  memset(vanillasegs, 0, numvanillasegs * SizeOf(vanillaseg_t));

  for LIndex := 0 to numvanillasegs - 1 do
  begin
    LMapSeg := LMapSegs[LIndex];
    LSeg := @vanillasegs[LIndex];
    LSeg.v1 := @vertexes[LMapSeg.Vertex1];
    LSeg.v2 := @vertexes[LMapSeg.Vertex2];

    LSeg.angle := _SHL(LMapSeg.Angle, 16);
    LSeg.offset := _SHL(LMapSeg.Offset, 16);
    LLine := @lines[LMapSeg.Linedef];
    LSeg.linedef := LLine;
    LSide := LMapSeg.Side;
    LSeg.sidedef := @sides[LLine.sidenum[LSide]];
    LSeg.frontsector := sides[LLine.sidenum[LSide]].sector;
    if LLine.flags and ML_TWOSIDED <> 0 then
      LSeg.backsector := sides[LLine.sidenum[LSide xor 1]].sector
    else
      LSeg.backsector := nil;
  end;
end;

procedure TEngineVanillaNodes.LoadSubsectors(ALump: Integer);
var
  LMapSubsectors: TArray<TNodesVanillaSubsector>;
  LIndex: Integer;
  LSubsector: Pvanillasubsector_t;
begin
  LMapSubsectors := TNodesVanillaParser.ParseSubsectors(FSource.ReadLump(ALump));
  numvanillasubsectors := Length(LMapSubsectors);
  if numvanillasubsectors >= MAX_VANILLA_RECORDS then
  begin
    numvanillasubsectors := 0;
    Exit;
  end;

  vanillasubsectors := Z_Malloc(numvanillasubsectors * SizeOf(vanillasubsector_t), PU_LEVEL, nil);
  memset(vanillasubsectors, 0, numvanillasubsectors * SizeOf(vanillasubsector_t));

  for LIndex := 0 to numvanillasubsectors - 1 do
  begin
    LSubsector := @vanillasubsectors[LIndex];
    LSubsector.numlines := LMapSubsectors[LIndex].SegCount;
    LSubsector.firstline := LMapSubsectors[LIndex].FirstSeg;
  end;
end;

procedure TEngineVanillaNodes.LoadNodes(ALump: Integer);
var
  LMapNodes: TArray<TNodesVanillaNode>;
  LIndex: Integer;
  LChild: Integer;
  LCorner: Integer;
  LNode: Pvanillanode_t;
begin
  LMapNodes := TNodesVanillaParser.ParseNodes(FSource.ReadLump(ALump));
  numvanillanodes := Length(LMapNodes);
  if numvanillanodes >= MAX_VANILLA_RECORDS then
  begin
    numvanillanodes := 0;
    Exit;
  end;

  vanillanodes := Z_Malloc(numvanillanodes * SizeOf(vanillanode_t), PU_LEVEL, nil);

  for LIndex := 0 to numvanillanodes - 1 do
  begin
    LNode := @vanillanodes[LIndex];
    LNode.x := LMapNodes[LIndex].X * FRACUNIT;
    LNode.y := LMapNodes[LIndex].Y * FRACUNIT;
    LNode.dx := LMapNodes[LIndex].DeltaX * FRACUNIT;
    LNode.dy := LMapNodes[LIndex].DeltaY * FRACUNIT;
    for LChild := 0 to 1 do
    begin
      LNode.children[LChild] := LMapNodes[LIndex].Children[LChild];
      for LCorner := 0 to 3 do
        LNode.bbox[LChild, LCorner] := LMapNodes[LIndex].BoundingBox[LChild, LCorner] * FRACUNIT;
    end;
  end;
end;

procedure TEngineVanillaNodes.Load(AMapLump: Integer);
begin
  // JVAL: 20210131 - Load vanilla nodes
  if char8tostring(W_GetNameForNum(AMapLump + Ord(ML_SSECTORS))) = 'SSECTORS' then
    LoadSubsectors(AMapLump + Ord(ML_SSECTORS));
  if char8tostring(W_GetNameForNum(AMapLump + Ord(ML_NODES))) = 'NODES' then
    LoadNodes(AMapLump + Ord(ML_NODES));
  if char8tostring(W_GetNameForNum(AMapLump + Ord(ML_SEGS))) = 'SEGS' then
    LoadSegs(AMapLump + Ord(ML_SEGS));
  hasvanillanodes := (vanillasubsectors <> nil) and (vanillanodes <> nil) and (vanillasegs <> nil);
end;

end.
