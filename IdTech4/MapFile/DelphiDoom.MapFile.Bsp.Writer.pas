{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a BSP file (IBSP 46)                 }
{                                                                              }
{  Written for this library after the layout of qfiles.h and of the compilers  }
{  of Quake III Arena (q3map: header, then the lumps one after the other,      }
{  each padded to 4 bytes). GPL v2 or later.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.Writer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Intf;

type
  /// <summary>
  ///   Writes the lumps of an <c>IBspFile</c> back: a file that the reader reads again gives the
  ///   same arrays, and the bytes are the same when the file was written the same way (header
  ///   144 bytes, lumps in the order of the header, each at a multiple of 4, entities with
  ///   their NUL). Not kept: the offsets and the padding of a file written by another tool, and
  ///   what follows the first NUL of the entities lump
  /// </summary>
  TBspFileWriter = class(TInterfacedObject, IBspWriter)
  strict private
    FFileSystem: IIdLibFileSystem;
    class function Encode<T: record>(const AItems: TArray<T>): TBytes; static;
    class function EntityBytes(const AFile: IBspFile): TBytes; static;
    class function VisibilityBytes(const AFile: IBspFile): TBytes; static;
  public
    /// <summary>The file system is needed by Write (not by ToBytes)</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem = nil);
    function ToBytes(const AFile: IBspFile): TBytes;
    function Write(const AFile: IBspFile; const AFileName: AnsiString): Boolean;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Types;

{ TBspFileWriter }

constructor TBspFileWriter.Create(const AFileSystem: IIdLibFileSystem);
begin
  inherited Create;
  FFileSystem := AFileSystem;
end;

class function TBspFileWriter.Encode<T>(const AItems: TArray<T>): TBytes;
begin
  SetLength(Result, Length(AItems) * SizeOf(T));
  if Length(Result) > 0 then
    Move(AItems[0], Result[0], Length(Result));
end;

class function TBspFileWriter.EntityBytes(const AFile: IBspFile): TBytes;
var
  LText: AnsiString;
begin
  LText := AFile.EntityText;
  // the lump holds the string and its terminator; an empty text is an empty lump
  if (LText = '') and (Length(AFile.LumpData[LUMP_ENTITIES]) = 0) then
    Exit(nil);
  SetLength(Result, Length(LText) + 1);
  if Length(LText) > 0 then
    Move(LText[1], Result[0], Length(LText));
  Result[Length(LText)] := 0;
end;

class function TBspFileWriter.VisibilityBytes(const AFile: IBspFile): TBytes;
var
  LNumClusters, LClusterBytes: Integer;
  LRows: TBytes;
begin
  LRows := AFile.Visibility;
  LNumClusters := AFile.NumClusters;
  LClusterBytes := AFile.ClusterBytes;
  if (LNumClusters = 0) and (LClusterBytes = 0) and (Length(LRows) = 0) then
    Exit(nil);
  SetLength(Result, 8 + Length(LRows));
  Move(LNumClusters, Result[0], 4);
  Move(LClusterBytes, Result[4], 4);
  if Length(LRows) > 0 then
    Move(LRows[0], Result[8], Length(LRows));
end;

function TBspFileWriter.ToBytes(const AFile: IBspFile): TBytes;
var
  LLumps: array[0..HEADER_LUMPS - 1] of TBytes;
  LHeader: TBspHeader;
  LIndex, LOffset, LPadded: Integer;
begin
  LLumps[LUMP_ENTITIES] := EntityBytes(AFile);
  LLumps[LUMP_SHADERS] := Encode<TBspShader>(AFile.Shaders);
  LLumps[LUMP_PLANES] := Encode<TBspPlane>(AFile.Planes);
  LLumps[LUMP_NODES] := Encode<TBspNode>(AFile.Nodes);
  LLumps[LUMP_LEAFS] := Encode<TBspLeaf>(AFile.Leafs);
  LLumps[LUMP_LEAFSURFACES] := Encode<Integer>(AFile.LeafSurfaces);
  LLumps[LUMP_LEAFBRUSHES] := Encode<Integer>(AFile.LeafBrushes);
  LLumps[LUMP_MODELS] := Encode<TBspModel>(AFile.Models);
  LLumps[LUMP_BRUSHES] := Encode<TBspBrush>(AFile.Brushes);
  LLumps[LUMP_BRUSHSIDES] := Encode<TBspBrushSide>(AFile.BrushSides);
  LLumps[LUMP_DRAWVERTS] := Encode<TBspDrawVert>(AFile.DrawVerts);
  LLumps[LUMP_DRAWINDEXES] := Encode<Integer>(AFile.DrawIndexes);
  LLumps[LUMP_FOGS] := Encode<TBspFog>(AFile.Fogs);
  LLumps[LUMP_SURFACES] := Encode<TBspSurface>(AFile.Surfaces);
  LLumps[LUMP_LIGHTMAPS] := AFile.Lightmaps;
  LLumps[LUMP_LIGHTGRID] := AFile.LightGrid;
  LLumps[LUMP_VISIBILITY] := VisibilityBytes(AFile);

  LHeader.Ident := BSP_IDENT;
  LHeader.Version := BSP_VERSION;
  LOffset := SizeOf(TBspHeader);
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    LHeader.Lumps[LIndex].FileOfs := LOffset;
    LHeader.Lumps[LIndex].FileLen := Length(LLumps[LIndex]);
    Inc(LOffset, (Length(LLumps[LIndex]) + 3) and not 3);
  end;

  SetLength(Result, LOffset);
  FillChar(Result[0], LOffset, 0);
  Move(LHeader, Result[0], SizeOf(TBspHeader));
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    LPadded := Length(LLumps[LIndex]);
    if LPadded > 0 then
      Move(LLumps[LIndex][0], Result[LHeader.Lumps[LIndex].FileOfs], LPadded);
  end;
end;

function TBspFileWriter.Write(const AFile: IBspFile; const AFileName: AnsiString): Boolean;
begin
  Result := Assigned(FFileSystem) and FFileSystem.WriteFile(AFileName, ToBytes(AFile));
end;

end.
