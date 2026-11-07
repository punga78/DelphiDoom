{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the nodes of a level                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.Nodes;

interface

uses
  System.SysUtils,
  r_defs,
  DelphiDoom.Platform.Intf,
  DelphiDoom.Glbsp.Client,
  DelphiDoom.Nodes.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   The nodes of a level with the services of Libs\Nodes: the GL nodes in the WAD, the GWA
  ///   that glBSP builds in DATA\BSP and the WAD built for a map without nodes (DATA\WADS),
  ///   converted in vertexes[], subsectors[], nodes[] and segs[]. It was the level part of
  ///   nd_main.pas (ND_NodesCheck, ND_GetNodes, ND_ReadGwa, ND_Load*)
  /// </summary>
  TEngineLevelNodes = class(TInterfacedObject, ILevelNodes)
  strict private
    FSource: INodesLumpSource;
    FDetector: INodesGlDetector;
    FFinder: INodesGlMapFinder;
    FInputBuilder: INodesGlbspInputBuilder;
    FTempFiles: ITempFiles;
    FHexen: Boolean;
    // the first GL vertex of the GWA in vertexes[]
    FFirstGlVertex: Integer;
    class procedure WriteBytes(const AFileName: string; const ABytes: TBytes); static;
    class function OffsetOf(AVertex1, AVertex2: Pvertex_t): Integer; static;
{$IFDEF OPENGL}
    class function GlDistance(ADeltaX, ADeltaY: Integer): Single; static;
{$ENDIF}
    function GlbspOptions: TGlbspOptions;
    function LumpCrc32(ALump: Integer): string;
    function ReadGwa(const AFileName: string): INodesGwa;
    function BuildGwa(const AMapName: string): string;
  public
    /// <summary>AHexen: the maps are in the Hexen format and glBSP is told so</summary>
    constructor Create(const ASource: INodesLumpSource; const ADetector: INodesGlDetector;
      const AFinder: INodesGlMapFinder; const AInputBuilder: INodesGlbspInputBuilder;
      const ATempFiles: ITempFiles; AHexen: Boolean);
    procedure CheckNodes(const AMapName: string);
    function FindGwa(const AMapName: string): INodesGwa;
    function FindGlMapLump(AMapLump: Integer): Integer;
    function DetectGlNodesVersion(AGlMapLump: Integer): Integer;
    procedure LoadVertexes(ALump: Integer; const AGwa: INodesGwa);
    procedure LoadSubsectors(const AGwa: INodesGwa);
    procedure LoadNodes(const AGwa: INodesGwa);
    procedure LoadSegs(const AGwa: INodesGwa);
  end;

implementation

uses
  System.Classes,
  d_delphi,
  doomdata,
  m_fixed,
  m_argv,
  i_system,
  r_main,
  w_wad,
  z_zone,
  p_setup,
  nd_main,
  DelphiDoom.MathCore.Crc32,
  DelphiDoom.Wad.Types,
  DelphiDoom.Nodes.Types,
  DelphiDoom.Nodes.Adler32,
  DelphiDoom.Nodes.Factory,
  DelphiDoom.Nodes.MapScanner,
  DelphiDoom.Nodes.GlVertexIndex,
  DelphiDoom.Nodes.FileNames;

{ TEngineLevelNodes }

constructor TEngineLevelNodes.Create(const ASource: INodesLumpSource; const ADetector: INodesGlDetector;
  const AFinder: INodesGlMapFinder; const AInputBuilder: INodesGlbspInputBuilder;
  const ATempFiles: ITempFiles; AHexen: Boolean);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(ADetector) then
    raise EArgumentNilException.Create('ADetector');
  if not Assigned(AFinder) then
    raise EArgumentNilException.Create('AFinder');
  if not Assigned(AInputBuilder) then
    raise EArgumentNilException.Create('AInputBuilder');
  if not Assigned(ATempFiles) then
    raise EArgumentNilException.Create('ATempFiles');
  FSource := ASource;
  FDetector := ADetector;
  FFinder := AFinder;
  FInputBuilder := AInputBuilder;
  FTempFiles := ATempFiles;
  FHexen := AHexen;
end;

class procedure TEngineLevelNodes.WriteBytes(const AFileName: string; const ABytes: TBytes);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(ABytes) > 0 then
      LStream.WriteBuffer(ABytes[0], Length(ABytes));
  finally
    LStream.Free;
  end;
end;

class function TEngineLevelNodes.OffsetOf(AVertex1, AVertex2: Pvertex_t): Integer;
var
  LDeltaX, LDeltaY: Single;
begin
  LDeltaX := (AVertex1.x - AVertex2.x) / FRACUNIT;
  LDeltaY := (AVertex1.y - AVertex2.y) / FRACUNIT;
  Result := Round(Sqrt(LDeltaX * LDeltaX + LDeltaY * LDeltaY) * FRACUNIT);
end;

{$IFDEF OPENGL}
class function TEngineLevelNodes.GlDistance(ADeltaX, ADeltaY: Integer): Single;
var
  LDeltaX, LDeltaY: Single;
begin
  // in single precision, as the old gldist of nd_main
  LDeltaX := ADeltaX / FRACUNIT;
  LDeltaY := ADeltaY / FRACUNIT;
  Result := Sqrt(LDeltaX * LDeltaX + LDeltaY * LDeltaY);
end;
{$ENDIF}

function TEngineLevelNodes.GlbspOptions: TGlbspOptions;
begin
  if FHexen then
    Result := [goHexen]
  else
    Result := [];
end;

function TEngineLevelNodes.LumpCrc32(ALump: Integer): string;
var
  LBytes: TBytes;
begin
  // 'DEADDEAD' for a lump that is not there, as the old GetLumpCRC32 of m_crc32
  if ALump < 0 then
    Exit('DEADDEAD');
  LBytes := FSource.ReadLump(ALump);
  Result := TCrc32.ToHex(TCrc32.Calculate(Pointer(LBytes)^, Length(LBytes)));
end;

function TEngineLevelNodes.FindGlMapLump(AMapLump: Integer): Integer;
begin
  Result := FFinder.FindGlMapLump(AMapLump);
end;

function TEngineLevelNodes.DetectGlNodesVersion(AGlMapLump: Integer): Integer;
begin
  Result := FDetector.DetectVersion(AGlMapLump);
  if Result > 0 then
    printf('gld_GetGLNodesVersion(): GL v%d nodes found.'#13#10, [Result]);
end;

function TEngineLevelNodes.BuildGwa(const AMapName: string): string;
var
  LMapLump: Integer;
  LAdler32: Cardinal;
  LPath: string;
  LMapFileName: string;
begin
  LMapLump := W_GetNumForName(AMapName);
  LAdler32 := TNodesAdler32.OfMap(FSource, LMapLump);

  LPath := M_SaveFileName('DATA\');
  MkDir(LPath);
  LPath := LPath + 'BSP\';
  MkDir(LPath);

  Result := fexpand(TNodesFileNames.GwaFileName(LPath, AMapName, LAdler32));
  if fexists(Result) then
    Exit;

  LMapFileName := FTempFiles.NewTempFile(TNodesFileNames.GlbspInputFileName(AMapName, LAdler32));
  WriteBytes(LMapFileName, FInputBuilder.BuildForMap(LMapLump));

  gld_BuildNodes(LMapFileName, Result);

  if not fexists(Result) then
    Result := '';
end;

function TEngineLevelNodes.ReadGwa(const AFileName: string): INodesGwa;
var
  LStream: TFileStream;
  LBytes: TBytes;
begin
  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(LBytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(LBytes[0], LStream.Size);
  finally
    LStream.Free;
  end;

  try
    Result := TNodesFactory.ReadGwa(LBytes);
  except
    on E: ENodesException do
    begin
      Result := nil;
      I_Error('ND_ReadGwa(): %s (%s)', [E.Message, AFileName]);
    end;
  end;

  glnodesver := Result.Version;
  printf('ND_ReadGwa(): GL v%d nodes found.'#13#10, [glnodesver]);
end;

function TEngineLevelNodes.FindGwa(const AMapName: string): INodesGwa;
var
  LFileName: string;
begin
  LFileName := BuildGwa(AMapName);
  if LFileName = '' then
    Result := nil
  else
    Result := ReadGwa(LFileName);
end;

procedure TEngineLevelNodes.LoadVertexes(ALump: Integer; const AGwa: INodesGwa);
var
  LData: Pointer;
  LIndex: Integer;
  LMapVertex: Pmapvertex_t;
  LVertex: Pvertex_t;
  LGlVertexCount: Integer;
  LGlVertexes: TArray<TNodesGlVertex>;
  LMinX, LMaxX, LMinY, LMaxY: Integer;
  LDeltaX, LDeltaY: Integer;
begin
  if AGwa = nil then
    LGlVertexCount := 0
  else
  begin
    LGlVertexes := AGwa.GlVertexes;
    LGlVertexCount := Length(LGlVertexes);
  end;

  FFirstGlVertex := W_LumpLength(ALump) div SizeOf(mapvertex_t);
  numvertexes := FFirstGlVertex + LGlVertexCount;

  vertexes := Z_Malloc(numvertexes * SizeOf(vertex_t), PU_LEVEL, nil);

  LData := W_CacheLumpNum(ALump, PU_STATIC);
  LMapVertex := Pmapvertex_t(LData);

  // JVAL: 20200414 -> Find map boundaries
  LMinX := 100000;
  LMaxX := -100000;
  LMinY := 100000;
  LMaxY := -100000;

  // internal representation as fixed
  LVertex := @vertexes[0];
  for LIndex := 0 to FFirstGlVertex - 1 do
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

  for LIndex := 0 to LGlVertexCount - 1 do
  begin
    LVertex.x := LGlVertexes[LIndex].X;
    LVertex.y := LGlVertexes[LIndex].Y;
    LVertex.amvalidcount := 0;
    LVertex.interpvalidcount := 0;
    Inc(LVertex);
  end;
end;

procedure TEngineLevelNodes.LoadSubsectors(const AGwa: INodesGwa);
var
  LIndex: Integer;
  LSubsector: Psubsector_t;
  LGlSubsectors: TArray<TNodesGlSubsector>;
begin
  LGlSubsectors := AGwa.Subsectors;
  numsubsectors := Length(LGlSubsectors);
  subsectors := Z_Malloc(numsubsectors * SizeOf(subsector_t), PU_LEVEL, nil);
  ZeroMemory(subsectors, numsubsectors * SizeOf(subsector_t));

  LSubsector := @subsectors[0];
  for LIndex := 0 to numsubsectors - 1 do
  begin
    LSubsector.numlines := LGlSubsectors[LIndex].Count;
    LSubsector.firstline := LGlSubsectors[LIndex].FirstSeg;
    Inc(LSubsector);
  end;
end;

procedure TEngineLevelNodes.LoadNodes(const AGwa: INodesGwa);
var
  LIndex: Integer;
  LCorner: Integer;
  LNode: Pnode_t;
  LGlNodes: TArray<TNodesGlNode>;
begin
  LGlNodes := AGwa.Nodes;
  numnodes := Length(LGlNodes);
  nodes := Z_Malloc(numnodes * SizeOf(node_t), PU_LEVEL, nil);
  ZeroMemory(nodes, numnodes * SizeOf(node_t));

  LNode := @nodes[0];
  for LIndex := 0 to numnodes - 1 do
  begin
    LNode.x := LGlNodes[LIndex].X * FRACUNIT;
    LNode.y := LGlNodes[LIndex].Y * FRACUNIT;
    LNode.dx := LGlNodes[LIndex].DeltaX * FRACUNIT;
    LNode.dy := LGlNodes[LIndex].DeltaY * FRACUNIT;
    LNode.children[0] := LGlNodes[LIndex].RightChild;
    LNode.children[1] := LGlNodes[LIndex].LeftChild;
    for LCorner := 0 to 3 do
      LNode.bbox[0, LCorner] := LGlNodes[LIndex].RightBoundingBox[LCorner] * FRACUNIT;
    for LCorner := 0 to 3 do
      LNode.bbox[1, LCorner] := LGlNodes[LIndex].LeftBoundingBox[LCorner] * FRACUNIT;
    Inc(LNode);
  end;
end;

procedure TEngineLevelNodes.LoadSegs(const AGwa: INodesGwa);
var
  LIndex: Integer;
  LGlSeg: TNodesGlSeg;
  LGlSegs: TArray<TNodesGlSeg>;
  LSeg: Pseg_t;
  LLine: Pline_t;
  LLineNumber: Integer;
  LSide: Integer;
  LSideNumber: Integer;
begin
  LGlSegs := AGwa.Segs;
  numsegs := Length(LGlSegs);
  segs := Z_Malloc(numsegs * SizeOf(seg_t), PU_LEVEL, nil);
  ZeroMemory(segs, numsegs * SizeOf(seg_t));

  LSeg := @segs[0];
  for LIndex := 0 to numsegs - 1 do
  begin
    LGlSeg := LGlSegs[LIndex];
    LSeg.v1 := @vertexes[TNodesGlVertexIndex.Resolve(glnodesver, LGlSeg.StartVertex, FFirstGlVertex)];
    LSeg.v2 := @vertexes[TNodesGlVertexIndex.Resolve(glnodesver, LGlSeg.EndVertex, FFirstGlVertex)];
{$IFDEF OPENGL}
    LSeg.iSegID := LIndex;
{$ENDIF}

    if LGlSeg.Linedef = Word(1 shl 16 - 1) then
    begin
      LSeg.miniseg := True;
      LSeg.angle := 0;
      LSeg.offset := 0;
{$IFDEF OPENGL}
      LSeg.length := 0;
{$ENDIF}
      LSeg.linedef := nil;
      LSeg.sidedef := nil;
      LSeg.frontsector := nil;
      LSeg.backsector := nil;
    end
    else
    begin
      LSeg.miniseg := False;
      LSeg.angle := R_PointToAngle2(LSeg.v1.x, LSeg.v1.y, LSeg.v2.x, LSeg.v2.y);
      LLineNumber := LGlSeg.Linedef;
      LLine := @lines[LLineNumber];
      if LGlSeg.Side <> 0 then
        LSeg.offset := OffsetOf(LSeg.v1, LLine.v2)
      else
        LSeg.offset := OffsetOf(LSeg.v1, LLine.v1);
      LSeg.linedef := LLine;
      LSide := LGlSeg.Side;
      LSeg.sidedef := @sides[LLine.sidenum[LSide]];
      LSeg.frontsector := LSeg.sidedef.sector;
      if LLine.flags and ML_TWOSIDED <> 0 then
      begin
        LSideNumber := LLine.sidenum[LSide xor 1];
        if LSideNumber = -1 then
        begin
          I_Warning('ND_LoadSegs(): Line %d is marked with ML_TWOSIDED flag without backsector'#13#10, [LLineNumber]);
          LLine.flags := LLine.flags and not ML_TWOSIDED;
          LSeg.backsector := nil;
        end
        else
          LSeg.backsector := sides[LSideNumber].sector;
      end
      else
        LSeg.backsector := nil;
{$IFDEF OPENGL}
      LSeg.length := GlDistance(LSeg.v2.x - LSeg.v1.x, LSeg.v2.y - LSeg.v1.y);
{$ENDIF}
    end;
    Inc(LSeg);
  end;
end;

procedure TEngineLevelNodes.CheckNodes(const AMapName: string);
var
  LMapLump: Integer;
  LLayout: TNodesMapLayout;
  LBaseName: string;
  LOutFileName: string;
  LWadFileName: string;
  LMapFolder: string;
begin
  LMapLump := W_GetNumForName(AMapName);
  if (LMapLump < 0) or (LMapLump >= W_NumLumps - 1) then
    Exit;

  LLayout := TNodesMapScanner.Scan(FSource, LMapLump, FHexen);

  if LLayout.IsComplete(FHexen) then
    Exit; // Nothing to do

  // Check if we can build the nodes
  if not LLayout.CanBuildNodes then
  begin
    I_Warning('ND_NodesCheck(): Missing critical map data to play the map'#13#10);
    Exit;
  end;

  LMapFolder := M_SaveFileName('DATA\');
  MkDir(LMapFolder);
  LMapFolder := LMapFolder + 'WADS\';
  MkDir(LMapFolder);
  LBaseName := TNodesFileNames.RebuiltMapName(LMapFolder, AMapName,
    [LumpCrc32(LMapLump + LLayout.Linedefs), LumpCrc32(LMapLump + LLayout.Sidedefs),
     LumpCrc32(LMapLump + LLayout.Vertexes), LumpCrc32(LMapLump + LLayout.Sectors)]);
  LWadFileName := LBaseName + '.wad';

  if not fexists(LWadFileName) then
  begin
    LOutFileName := LBaseName + '.out';
    FTempFiles.Declare(LOutFileName);

    WriteBytes(LOutFileName, FInputBuilder.BuildForMapWithoutNodes(LMapLump, LLayout));

    // Build the nodes
    printf(#13#10'  ND_NodesCheck: Building GL-Friendly nodes for %s'#13#10, [AMapName]);

    if not ND_RunGlbsp(LOutFileName, LWadFileName, GlbspOptions) then
    begin
      printf(#13#10);
      I_Warning('ND_NodesCheck(): Failed to build GL-Friendly nodes for %s'#13#10, [LOutFileName]);
      Exit;
    end;
    printf(#13#10);
  end;

  W_RuntimeLoad(LWadFileName, F_ORIGIN_WAD);
end;

end.
