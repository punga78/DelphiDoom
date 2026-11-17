{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - reading a .cm file                          }
{                                                                              }
{  Port of the loading part of CollisionModel_files.cpp (ParseVertices,        }
{  ParseEdges, ParseNodes, ParsePolygons, ParseBrushes, ParseCollisionModel,   }
{  LoadCollisionModelFile), Doom 3 GPL Source Code. Copyright (C) 1999-2011    }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3 or (at your option) any later version, with the   }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.CmFile.Reader;

interface

uses
  System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Collision.Intf,
  DelphiDoom.Collision.Model, DelphiDoom.Collision.CmFile.Tokenizer, DelphiDoom.Collision.Model.Node;

type
  /// <summary>
  ///   Reads the text of a collision model file into models. The materials of the polygons
  ///   come from the material catalog (declManager->FindMaterial). A body that is not valid
  ///   raises ECollisionFormatException (the C++ code calls src->Error, which is fatal); a file
  ///   that is not a CM file, has another version or is out of date makes Parse return nil with a
  ///   message, as LoadCollisionModelFile returns false
  /// </summary>
  TCollisionFileReader = class
  private
    FCatalog: ICollisionMaterialCatalog;
    FLog: ILog;
    procedure Warn(const AText: string);
    procedure ParseVertices(ASource: TCollisionTokenizer; AModel: TCollisionModel);
    procedure ParseEdges(ASource: TCollisionTokenizer; AModel: TCollisionModel);
    function ParseNodes(ASource: TCollisionTokenizer; AModel: TCollisionModel; AParent: TCmNode;
      ADepth: Integer): TCmNode;
    function ParseCoordinate(ASource: TCollisionTokenizer): Single;
    procedure ParsePolygons(ASource: TCollisionTokenizer; AModel: TCollisionModel);
    procedure ParseBrushes(ASource: TCollisionTokenizer; AModel: TCollisionModel);
    function ParseCollisionModel(ASource: TCollisionTokenizer): TCollisionModel;
    procedure ParseVector(ASource: TCollisionTokenizer; out AX, AY, AZ: Single);
  public
    /// <summary>ALog may be nil</summary>
    constructor Create(const ACatalog: ICollisionMaterialCatalog; const ALog: ILog);
    /// <summary>
    ///   Parses the text. AMapFileCrc 0 accepts any crc. The caller owns the list and its models;
    ///   nil when the file is rejected
    /// </summary>
    function Parse(const AText: string; AMapFileCrc: Cardinal = 0): TObjectList<TCollisionModel>;
    function LoadFromStream(AStream: TStream; AMapFileCrc: Cardinal = 0): TObjectList<TCollisionModel>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.Types, DelphiDoom.Collision.Model.Types,
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush, DelphiDoom.Collision.Builder.Bsp,
  DelphiDoom.Collision.Builder.EdgeNormals, DelphiDoom.Collision.ContentsNames,
  DelphiDoom.Collision.CmFile.Writer;

resourcestring
  SNotCmFile = 'collision model file is not a CM file.';
  SBadVersion = 'collision model file has version %s instead of %s';
  SNoCrc = 'collision model file has no map file CRC';
  SOutOfDate = 'collision model file is out of date';
  SBadToken = 'ParseCollisionModel: bad token "%s"';
  SBadFileToken = 'LoadCollisionModelFile: bad token "%s"';
  STooManyModels = 'LoadModel: no free slots';
  SBadCount = 'collision model file: bad %s count %d at line %d';
  SBadVertexNumber = 'collision model file: edge %d uses vertex %d, which does not exist, at line %d';
  SBadEdgeNumber = 'collision model file: polygon uses edge %d, which does not exist, at line %d';
  SBadPlaneType = 'collision model file: bad node plane type %d at line %d';
  STreeTooDeep = 'collision model file: the tree of nodes is more than %d levels deep at line %d';
  SBadCoordinate = 'collision model file: coordinate %g is outside the world at line %d';

const
  /// <summary>
  ///   What the reader accepts. The original trusts the file; these are far above what dmap writes, and keep
  ///   an altered file from allocating gigabytes, recursing without end or reaching outside an array
  /// </summary>
  MAX_FILE_VERTICES = 1 shl 20;
  MAX_FILE_EDGES = 1 shl 21;
  MAX_FILE_PLANES = 1024;
  MAX_TREE_DEPTH = 512;
  MAX_COORDINATE = 1.0E9;

{ TCollisionFileReader }

constructor TCollisionFileReader.Create(const ACatalog: ICollisionMaterialCatalog; const ALog: ILog);
begin
  inherited Create;
  FCatalog := ACatalog;
  FLog := ALog;
end;

procedure TCollisionFileReader.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

procedure TCollisionFileReader.ParseVector(ASource: TCollisionTokenizer; out AX, AY, AZ: Single);
begin
  // Parse1DMatrix( 3, ... ): ( x y z )
  ASource.ExpectTokenString('(');
  AX := ParseCoordinate(ASource);
  AY := ParseCoordinate(ASource);
  AZ := ParseCoordinate(ASource);
  ASource.ExpectTokenString(')');
end;

function TCollisionFileReader.ParseCoordinate(ASource: TCollisionTokenizer): Single;
begin
  Result := ASource.ParseFloat;
  if Abs(Result) > MAX_COORDINATE then
    raise ECollisionFormatException.CreateFmt(SBadCoordinate, [Result, ASource.Line]);
end;

procedure TCollisionFileReader.ParseVertices(ASource: TCollisionTokenizer; AModel: TCollisionModel);
var
  LIndex: Integer;
  LX: Single;
  LY: Single;
  LZ: Single;
begin
  ASource.ExpectTokenString('{');
  AModel.NumVertices := ASource.ParseInt;
  if (AModel.NumVertices < 0) or (AModel.NumVertices > MAX_FILE_VERTICES) then
    raise ECollisionFormatException.CreateFmt(SBadCount, ['vertex', AModel.NumVertices, ASource.Line]);
  SetLength(AModel.Vertices, AModel.NumVertices);
  for LIndex := 0 to AModel.NumVertices - 1 do
  begin
    ParseVector(ASource, LX, LY, LZ);
    AModel.Vertices[LIndex].P.SetValues(LX, LY, LZ);
    AModel.Vertices[LIndex].Side := 0;
    AModel.Vertices[LIndex].SideSet := 0;
    AModel.Vertices[LIndex].CheckCount := 0;
  end;
  ASource.ExpectTokenString('}');
end;

procedure TCollisionFileReader.ParseEdges(ASource: TCollisionTokenizer; AModel: TCollisionModel);
var
  LIndex: Integer;
begin
  ASource.ExpectTokenString('{');
  AModel.NumEdges := ASource.ParseInt;
  if (AModel.NumEdges < 0) or (AModel.NumEdges > MAX_FILE_EDGES) then
    raise ECollisionFormatException.CreateFmt(SBadCount, ['edge', AModel.NumEdges, ASource.Line]);
  SetLength(AModel.Edges, AModel.NumEdges);
  for LIndex := 0 to AModel.NumEdges - 1 do
  begin
    ASource.ExpectTokenString('(');
    AModel.Edges[LIndex].VertexNum[0] := ASource.ParseInt;
    AModel.Edges[LIndex].VertexNum[1] := ASource.ParseInt;
    ASource.ExpectTokenString(')');
    // the vertices of an edge are used to index the vertices: they have to exist
    // (edge 0 is a dummy that nothing uses)
    if (LIndex > 0) and ((AModel.Edges[LIndex].VertexNum[0] < 0) or
      (AModel.Edges[LIndex].VertexNum[0] >= AModel.NumVertices) or (AModel.Edges[LIndex].VertexNum[1] < 0) or
      (AModel.Edges[LIndex].VertexNum[1] >= AModel.NumVertices)) then
      raise ECollisionFormatException.CreateFmt(SBadVertexNumber,
        [LIndex, AModel.Edges[LIndex].VertexNum[0], ASource.Line]);
    AModel.Edges[LIndex].Side := 0;
    AModel.Edges[LIndex].SideSet := 0;
    AModel.Edges[LIndex].Internal := ASource.ParseInt and $FFFF;
    AModel.Edges[LIndex].NumUsers := ASource.ParseInt and $FFFF;
    AModel.Edges[LIndex].Normal := TGeoVec3.Origin;
    AModel.Edges[LIndex].CheckCount := 0;
    Inc(AModel.NumInternalEdges, AModel.Edges[LIndex].Internal);
  end;
  ASource.ExpectTokenString('}');
end;

function TCollisionFileReader.ParseNodes(ASource: TCollisionTokenizer; AModel: TCollisionModel;
  AParent: TCmNode; ADepth: Integer): TCmNode;
begin
  if ADepth > MAX_TREE_DEPTH then
    raise ECollisionFormatException.CreateFmt(STreeTooDeep, [MAX_TREE_DEPTH, ASource.Line]);
  Inc(AModel.NumNodes);
  Result := AModel.CreateNode(AParent);
  ASource.ExpectTokenString('(');
  Result.PlaneType := ASource.ParseInt;
  if (Result.PlaneType < -1) or (Result.PlaneType > 2) then
    raise ECollisionFormatException.CreateFmt(SBadPlaneType, [Result.PlaneType, ASource.Line]);
  Result.PlaneDist := ParseCoordinate(ASource);
  ASource.ExpectTokenString(')');
  if Result.PlaneType <> -1 then
  begin
    Result.Children[0] := ParseNodes(ASource, AModel, Result, ADepth + 1);
    Result.Children[1] := ParseNodes(ASource, AModel, Result, ADepth + 1);
  end;
end;

procedure TCollisionFileReader.ParsePolygons(ASource: TCollisionTokenizer; AModel: TCollisionModel);
var
  LPolygon: TCmPolygon;
  LIndex: Integer;
  LNumEdges: Integer;
  LToken: string;
  LIsString: Boolean;
  LX: Single;
  LY: Single;
  LZ: Single;
  LBsp: TCollisionBspBuilder;
begin
  // the optional polygon memory, which the block allocator of the C++ code used
  if ASource.NextIsNumber then
    ASource.ReadToken(LToken, LIsString);

  LBsp := TCollisionBspBuilder.Create(AModel);
  try
    ASource.ExpectTokenString('{');
    while not ASource.CheckTokenString('}') do
    begin
      // parse polygon
      LNumEdges := ASource.ParseInt;
      // the collision code keeps one cache entry for each edge of a polygon (CM_MAX_POLYGON_EDGES)
      if (LNumEdges < 3) or (LNumEdges > CM_MAX_POLYGON_EDGES) then
        raise ECollisionFormatException.CreateFmt(SBadCount, ['polygon edge', LNumEdges, ASource.Line]);
      LPolygon := AModel.CreatePolygon(LNumEdges);
      ASource.ExpectTokenString('(');
      for LIndex := 0 to LNumEdges - 1 do
      begin
        LPolygon.Edges[LIndex] := ASource.ParseInt;
        if (LPolygon.Edges[LIndex] = 0) or (Abs(LPolygon.Edges[LIndex]) >= AModel.NumEdges) then
          raise ECollisionFormatException.CreateFmt(SBadEdgeNumber, [LPolygon.Edges[LIndex], ASource.Line]);
      end;
      ASource.ExpectTokenString(')');
      ParseVector(ASource, LX, LY, LZ);
      LPolygon.Plane.SetNormal(TGeoVec3.Make(LX, LY, LZ));
      LPolygon.Plane.SetDist(ParseCoordinate(ASource));
      ParseVector(ASource, LX, LY, LZ);
      LPolygon.Bounds.Mins.SetValues(LX, LY, LZ);
      ParseVector(ASource, LX, LY, LZ);
      LPolygon.Bounds.Maxs.SetValues(LX, LY, LZ);
      // get material
      LPolygon.Material := FCatalog.FindMaterial(ASource.ExpectString);
      LPolygon.Contents := LPolygon.Material.Contents;
      LPolygon.CheckCount := 0;
      // filter polygon into tree
      LBsp.FilterPolygonIntoTree(AModel.Node, LPolygon);
    end;
  finally
    LBsp.Free;
  end;
end;

procedure TCollisionFileReader.ParseBrushes(ASource: TCollisionTokenizer; AModel: TCollisionModel);
var
  LBrush: TCmBrush;
  LIndex: Integer;
  LNumPlanes: Integer;
  LToken: string;
  LIsString: Boolean;
  LX: Single;
  LY: Single;
  LZ: Single;
  LBsp: TCollisionBspBuilder;
  LContents: Integer;
begin
  // the optional brush memory
  if ASource.NextIsNumber then
    ASource.ReadToken(LToken, LIsString);

  LBsp := TCollisionBspBuilder.Create(AModel);
  try
    ASource.ExpectTokenString('{');
    while not ASource.CheckTokenString('}') do
    begin
      // parse brush
      LNumPlanes := ASource.ParseInt;
      if (LNumPlanes < 0) or (LNumPlanes > MAX_FILE_PLANES) then
        raise ECollisionFormatException.CreateFmt(SBadCount, ['brush plane', LNumPlanes, ASource.Line]);
      LBrush := AModel.CreateBrush(LNumPlanes);
      ASource.ExpectTokenString('{');
      for LIndex := 0 to LNumPlanes - 1 do
      begin
        ParseVector(ASource, LX, LY, LZ);
        LBrush.Planes[LIndex].SetNormal(TGeoVec3.Make(LX, LY, LZ));
        LBrush.Planes[LIndex].SetDist(ParseCoordinate(ASource));
      end;
      ASource.ExpectTokenString('}');
      ParseVector(ASource, LX, LY, LZ);
      LBrush.Bounds.Mins.SetValues(LX, LY, LZ);
      ParseVector(ASource, LX, LY, LZ);
      LBrush.Bounds.Maxs.SetValues(LX, LY, LZ);
      if not ASource.ReadToken(LToken, LIsString) then
        raise ECollisionFormatException.CreateFmt('collision model file: unexpected end of file at line %d',
          [ASource.Line]);
      if (not LIsString) and TryStrToInt(LToken, LContents) then
        LBrush.Contents := LContents // old .cm files use a single integer
      else
        LBrush.Contents := TCollisionContentsNames.ContentsFromString(LToken);
      LBrush.CheckCount := 0;
      LBrush.PrimitiveNum := 0;
      // filter brush into tree
      LBsp.FilterBrushIntoTree(AModel.Node, LBrush);
    end;
  finally
    LBsp.Free;
  end;
end;

function TCollisionFileReader.ParseCollisionModel(ASource: TCollisionTokenizer): TCollisionModel;
var
  LToken: string;
  LIsString: Boolean;
begin
  Result := TCollisionModel.Create;
  try
    // parse the file
    Result.Name := ASource.ExpectString;
    ASource.ExpectTokenString('{');
    // a model with no "nodes" block would have no tree: give it a leaf
    Result.Node := nil;
    while not ASource.CheckTokenString('}') do
    begin
      if not ASource.ReadToken(LToken, LIsString) then
        raise ECollisionFormatException.CreateFmt('collision model file: unexpected end of file at line %d',
          [ASource.Line]);

      if LToken = 'vertices' then
        ParseVertices(ASource, Result)
      else if LToken = 'edges' then
        ParseEdges(ASource, Result)
      else if LToken = 'nodes' then
      begin
        ASource.ExpectTokenString('{');
        Result.Node := ParseNodes(ASource, Result, nil, 0);
        ASource.ExpectTokenString('}');
      end
      else if LToken = 'polygons' then
      begin
        if not Assigned(Result.Node) then
          raise ECollisionFormatException.CreateFmt('collision model file: polygons before nodes at line %d',
            [ASource.Line]);
        ParsePolygons(ASource, Result);
      end
      else if LToken = 'brushes' then
      begin
        if not Assigned(Result.Node) then
          raise ECollisionFormatException.CreateFmt('collision model file: brushes before nodes at line %d',
            [ASource.Line]);
        ParseBrushes(ASource, Result);
      end
      else
        raise ECollisionFormatException.CreateFmt(SBadToken, [LToken]);
    end;
    if not Assigned(Result.Node) then
    begin
      Result.Node := Result.CreateNode(nil);
      Result.Node.PlaneType := -1;
    end;
    // calculate edge normals
    TCollisionEdgeNormals.Calculate(Result);
    // get model bounds from brush and polygon bounds
    Result.CalculateBounds;
    // get model contents
    Result.CalculateContents;
  except
    Result.Free;
    raise;
  end;
end;

function TCollisionFileReader.Parse(const AText: string; AMapFileCrc: Cardinal): TObjectList<TCollisionModel>;
var
  LSource: TCollisionTokenizer;
  LToken: string;
  LIsString: Boolean;
  LCrcText: string;
  LCrc: Int64;
begin
  Result := nil;
  LSource := TCollisionTokenizer.Create(AText);
  try
    if not (LSource.ReadToken(LToken, LIsString) and (not LIsString) and (LToken = CM_FILEID)) then
    begin
      Warn(SNotCmFile);
      Exit;
    end;
    if not LSource.ReadToken(LToken, LIsString) or (LToken <> CM_FILEVERSION) then
    begin
      Warn(Format(SBadVersion, [LToken, CM_FILEVERSION]));
      Exit;
    end;
    if not LSource.ReadToken(LCrcText, LIsString) or LIsString or not TryStrToInt64(LCrcText, LCrc) then
    begin
      Warn(SNoCrc);
      Exit;
    end;
    if (AMapFileCrc <> 0) and (Cardinal(LCrc) <> AMapFileCrc) then
    begin
      Warn(SOutOfDate);
      Exit;
    end;

    Result := TObjectList<TCollisionModel>.Create(True);
    try
      // parse the file
      while LSource.ReadToken(LToken, LIsString) do
      begin
        if (not LIsString) and (LToken = 'collisionModel') then
        begin
          if Result.Count >= MAX_SUBMODELS then
            raise ECollisionFormatException.Create(STooManyModels);
          Result.Add(ParseCollisionModel(LSource));
          Continue;
        end;
        raise ECollisionFormatException.CreateFmt(SBadFileToken, [LToken]);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    LSource.Free;
  end;
end;

function TCollisionFileReader.LoadFromStream(AStream: TStream; AMapFileCrc: Cardinal): TObjectList<TCollisionModel>;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size - AStream.Position);
  if Length(LBytes) > 0 then
    AStream.ReadBuffer(LBytes[0], Length(LBytes));
  Result := Parse(TEncoding.UTF8.GetString(LBytes), AMapFileCrc);
end;

end.
