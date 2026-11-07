{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - writing a .cm file                          }
{                                                                              }
{  Port of the writing part of CollisionModel_files.cpp (WriteNodes,           }
{  WritePolygons, WriteBrushes, WriteCollisionModel and the file header) and   }
{  of FS_WriteFloatString of Doom 3 GPL Source Code. Copyright (C) 1999-2011   }
{  id Software LLC, a ZeniMax Media company. Doom 3 Source Code: GNU General   }
{  Public License version 3 with additional terms. This unit is a derived      }
{  work (GPL v3).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.CmFile.Writer;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Model.Node;

const
  CM_FILE_EXT = 'cm';
  CM_FILEID = 'CM';
  CM_FILEVERSION = '1.00';

type
  /// <summary>
  ///   Writes collision models in the text format of Doom 3 (file id "CM", version "1.00").
  ///   Floats are written like idFile::WriteFloatString does: ten decimals, then the trailing
  ///   zeros and the trailing point are removed. The text is UTF-8 without a byte order mark
  ///   (names in practice are ASCII). Opening and closing the file is the caller's job
  ///   (the C++ code asks the file system), so the writer works on a stream or a string.
  /// </summary>
  TCollisionFileWriter = class
  private
    FOutput: TStringBuilder;
    procedure WriteNodes(ANode: TCmNode);
    procedure WritePolygons(ANode: TCmNode; ASeen: TDictionary<TObject, Boolean>);
    procedure WriteBrushes(ANode: TCmNode; ASeen: TDictionary<TObject, Boolean>);
    function CountPolygonMemory(AModel: TCollisionModel): Integer;
    function CountBrushMemory(AModel: TCollisionModel): Integer;
    class function FloatText(AValue: Single): string; static;
    class function Vec3Text(const AVector: TGeoVec3): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The file id, the version and the map file crc: CM "1.00" and the crc as unsigned</summary>
    procedure WriteHeader(AMapFileCrc: Cardinal);
    /// <summary>One "collisionModel" block (WriteCollisionModel)</summary>
    procedure WriteModel(AModel: TCollisionModel);
    /// <summary>Everything written so far</summary>
    function Text: string;
    /// <summary>The whole file in one call (WriteCollisionModelsToFile): header and the models</summary>
    class function ToText(const AModels: array of TCollisionModel; AMapFileCrc: Cardinal): string; static;
    class procedure ToStream(AStream: TStream; const AModels: array of TCollisionModel;
      AMapFileCrc: Cardinal); static;
  end;

implementation

uses
  DelphiDoom.Collision.Types, DelphiDoom.Collision.ContentsNames,
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush;

const
  // sizeof(cm_polygon_t) and sizeof(cm_brush_t) of the 32 bit C++ build, which the original
  // writes in the "polygonMemory" and "brushMemory" comments of the file
  POLYGON_STRUCT_SIZE = 60;
  BRUSH_STRUCT_SIZE = 60;

{ TCollisionFileWriter }

constructor TCollisionFileWriter.Create;
begin
  inherited Create;
  FOutput := TStringBuilder.Create;
end;

destructor TCollisionFileWriter.Destroy;
begin
  FOutput.Free;
  inherited Destroy;
end;

class function TCollisionFileWriter.FloatText(AValue: Single): string;
begin
  // high precision floating point number without trailing zeros
  Result := Format('%1.10f', [Double(AValue)], TFormatSettings.Invariant);
  while (Result <> '') and (Result[Length(Result)] = '0') do
    Delete(Result, Length(Result), 1);
  while (Result <> '') and (Result[Length(Result)] = '.') do
    Delete(Result, Length(Result), 1);
end;

class function TCollisionFileWriter.Vec3Text(const AVector: TGeoVec3): string;
begin
  Result := FloatText(AVector.X) + ' ' + FloatText(AVector.Y) + ' ' + FloatText(AVector.Z);
end;

procedure TCollisionFileWriter.WriteHeader(AMapFileCrc: Cardinal);
begin
  FOutput.Append(CM_FILEID + ' "' + CM_FILEVERSION + '"'#10#10);
  FOutput.Append(UIntToStr(AMapFileCrc) + #10#10);
end;

procedure TCollisionFileWriter.WriteNodes(ANode: TCmNode);
begin
  FOutput.Append(#9'( ' + IntToStr(ANode.PlaneType) + ' ' + FloatText(ANode.PlaneDist) + ' )'#10);
  if ANode.PlaneType <> -1 then
  begin
    WriteNodes(ANode.Children[0]);
    WriteNodes(ANode.Children[1]);
  end;
end;

procedure TCollisionFileWriter.WritePolygons(ANode: TCmNode; ASeen: TDictionary<TObject, Boolean>);
var
  LPolygon: TCmPolygon;
  LIndex: Integer;
begin
  for LPolygon in ANode.Polygons do
  begin
    // the checkcount of the C++ code: write each polygon once
    if not ASeen.TryAdd(LPolygon, True) then
      Continue;
    FOutput.Append(#9 + IntToStr(LPolygon.NumEdges) + ' (');
    for LIndex := 0 to LPolygon.NumEdges - 1 do
      FOutput.Append(' ' + IntToStr(LPolygon.Edges[LIndex]));
    FOutput.Append(' ) ( ' + Vec3Text(LPolygon.Plane.Normal) + ' ) ' + FloatText(LPolygon.Plane.Dist));
    FOutput.Append(' ( ' + Vec3Text(LPolygon.Bounds.Mins) + ' )');
    FOutput.Append(' ( ' + Vec3Text(LPolygon.Bounds.Maxs) + ' )');
    FOutput.Append(' "' + LPolygon.Material.Name + '"'#10);
  end;
  if ANode.PlaneType <> -1 then
  begin
    WritePolygons(ANode.Children[0], ASeen);
    WritePolygons(ANode.Children[1], ASeen);
  end;
end;

procedure TCollisionFileWriter.WriteBrushes(ANode: TCmNode; ASeen: TDictionary<TObject, Boolean>);
var
  LBrush: TCmBrush;
  LIndex: Integer;
begin
  for LBrush in ANode.Brushes do
  begin
    if not ASeen.TryAdd(LBrush, True) then
      Continue;
    FOutput.Append(#9 + IntToStr(LBrush.NumPlanes) + ' {'#10);
    for LIndex := 0 to LBrush.NumPlanes - 1 do
      FOutput.Append(#9#9'( ' + Vec3Text(LBrush.Planes[LIndex].Normal) + ' ) ' +
        FloatText(LBrush.Planes[LIndex].Dist) + #10);
    FOutput.Append(#9'} ( ' + Vec3Text(LBrush.Bounds.Mins) + ' )');
    FOutput.Append(' ( ' + Vec3Text(LBrush.Bounds.Maxs) + ' ) "' +
      TCollisionContentsNames.StringFromContents(LBrush.Contents) + '"'#10);
  end;
  if ANode.PlaneType <> -1 then
  begin
    WriteBrushes(ANode.Children[0], ASeen);
    WriteBrushes(ANode.Children[1], ASeen);
  end;
end;

function TCollisionFileWriter.CountPolygonMemory(AModel: TCollisionModel): Integer;
var
  LPolygon: TCmPolygon;
begin
  Result := 0;
  for LPolygon in AModel.TreePolygons do
    Inc(Result, POLYGON_STRUCT_SIZE + (LPolygon.NumEdges - 1) * SizeOf(Integer));
end;

function TCollisionFileWriter.CountBrushMemory(AModel: TCollisionModel): Integer;
var
  LBrush: TCmBrush;
begin
  Result := 0;
  for LBrush in AModel.TreeBrushes do
    Inc(Result, BRUSH_STRUCT_SIZE + (LBrush.NumPlanes - 1) * 16);
end;

procedure TCollisionFileWriter.WriteModel(AModel: TCollisionModel);
var
  LIndex: Integer;
  LSeen: TDictionary<TObject, Boolean>;
begin
  FOutput.Append('collisionModel "' + AModel.Name + '" {'#10);
  // vertices
  FOutput.Append(#9'vertices { /* numVertices = */ ' + IntToStr(AModel.NumVertices) + #10);
  for LIndex := 0 to AModel.NumVertices - 1 do
    FOutput.Append(#9'/* ' + IntToStr(LIndex) + ' */ ( ' + Vec3Text(AModel.Vertices[LIndex].P) + ' )'#10);
  FOutput.Append(#9'}'#10);
  // edges
  FOutput.Append(#9'edges { /* numEdges = */ ' + IntToStr(AModel.NumEdges) + #10);
  for LIndex := 0 to AModel.NumEdges - 1 do
    FOutput.Append(#9'/* ' + IntToStr(LIndex) + ' */ ( ' + IntToStr(AModel.Edges[LIndex].VertexNum[0]) + ' ' +
      IntToStr(AModel.Edges[LIndex].VertexNum[1]) + ' ) ' + IntToStr(AModel.Edges[LIndex].Internal) + ' ' +
      IntToStr(AModel.Edges[LIndex].NumUsers) + #10);
  FOutput.Append(#9'}'#10);
  // nodes
  FOutput.Append(#9'nodes {'#10);
  WriteNodes(AModel.Node);
  FOutput.Append(#9'}'#10);
  // polygons
  FOutput.Append(#9'polygons /* polygonMemory = */ ' + IntToStr(CountPolygonMemory(AModel)) + ' {'#10);
  LSeen := TDictionary<TObject, Boolean>.Create;
  try
    WritePolygons(AModel.Node, LSeen);
  finally
    LSeen.Free;
  end;
  FOutput.Append(#9'}'#10);
  // brushes
  FOutput.Append(#9'brushes /* brushMemory = */ ' + IntToStr(CountBrushMemory(AModel)) + ' {'#10);
  LSeen := TDictionary<TObject, Boolean>.Create;
  try
    WriteBrushes(AModel.Node, LSeen);
  finally
    LSeen.Free;
  end;
  FOutput.Append(#9'}'#10);
  // closing brace
  FOutput.Append('}'#10);
end;

function TCollisionFileWriter.Text: string;
begin
  Result := FOutput.ToString;
end;

class function TCollisionFileWriter.ToText(const AModels: array of TCollisionModel;
  AMapFileCrc: Cardinal): string;
var
  LWriter: TCollisionFileWriter;
  LIndex: Integer;
begin
  LWriter := TCollisionFileWriter.Create;
  try
    LWriter.WriteHeader(AMapFileCrc);
    for LIndex := 0 to High(AModels) do
      LWriter.WriteModel(AModels[LIndex]);
    Result := LWriter.Text;
  finally
    LWriter.Free;
  end;
end;

class procedure TCollisionFileWriter.ToStream(AStream: TStream; const AModels: array of TCollisionModel;
  AMapFileCrc: Cardinal);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(ToText(AModels, AMapFileCrc));
  if Length(LBytes) > 0 then
    AStream.WriteBuffer(LBytes[0], Length(LBytes));
end;

end.
