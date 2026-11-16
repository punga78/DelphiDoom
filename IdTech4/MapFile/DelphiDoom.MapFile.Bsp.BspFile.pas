{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: the model        }
{                                                                              }
{  Written for this library (the original keeps the lumps as pointers into     }
{  the file buffer). Based on the Quake III Arena GPL Source Code (id          }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.BspFile;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   The lumps of a BSP file, decoded from their bytes. The records are packed with the layout of
  ///   the file (little endian, as every machine the engine runs on); the constructor expects
  ///   lumps that the reader has already checked (a length that is a multiple of the record).
  /// </summary>
  TBspFile = class(TInterfacedObject, IBspFile)
  strict private
    FVersion: Integer;
    FLumps: array[0..HEADER_LUMPS - 1] of TBspLump;
    FLumpData: array[0..HEADER_LUMPS - 1] of TBytes;
    FEntityText: AnsiString;
    FShaders: TArray<TBspShader>;
    FPlanes: TArray<TBspPlane>;
    FNodes: TArray<TBspNode>;
    FLeafs: TArray<TBspLeaf>;
    FLeafSurfaces: TArray<Integer>;
    FLeafBrushes: TArray<Integer>;
    FModels: TArray<TBspModel>;
    FBrushes: TArray<TBspBrush>;
    FBrushSides: TArray<TBspBrushSide>;
    FDrawVerts: TArray<TBspDrawVert>;
    FDrawIndexes: TArray<Integer>;
    FFogs: TArray<TBspFog>;
    FSurfaces: TArray<TBspSurface>;
    FNumClusters: Integer;
    FClusterBytes: Integer;
    FVisibility: TBytes;
    class function Decode<T: record>(const ABytes: TBytes): TArray<T>; static;
    class function NameOf(const AChars: array of AnsiChar): AnsiString; static;
  public
    /// <param name="ALumpData">the bytes of each lump, in the order of the header (17 entries)</param>
    constructor Create(const AHeader: TBspHeader; const ALumpData: array of TBytes);
    function GetVersion: Integer;
    function GetLump(const AIndex: Integer): TBspLump;
    function GetLumpData(const AIndex: Integer): TBytes;
    function GetEntityText: AnsiString;
    function GetShaders: TArray<TBspShader>;
    function GetPlanes: TArray<TBspPlane>;
    function GetNodes: TArray<TBspNode>;
    function GetLeafs: TArray<TBspLeaf>;
    function GetLeafSurfaces: TArray<Integer>;
    function GetLeafBrushes: TArray<Integer>;
    function GetModels: TArray<TBspModel>;
    function GetBrushes: TArray<TBspBrush>;
    function GetBrushSides: TArray<TBspBrushSide>;
    function GetDrawVerts: TArray<TBspDrawVert>;
    function GetDrawIndexes: TArray<Integer>;
    function GetFogs: TArray<TBspFog>;
    function GetSurfaces: TArray<TBspSurface>;
    function GetLightmaps: TBytes;
    function GetLightGrid: TBytes;
    function GetNumClusters: Integer;
    function GetClusterBytes: Integer;
    function GetVisibility: TBytes;
    function ShaderName(const AIndex: Integer): AnsiString;
    function FogShaderName(const AIndex: Integer): AnsiString;
    function LightmapCount: Integer;
  end;

implementation

{ TBspFile }

constructor TBspFile.Create(const AHeader: TBspHeader; const ALumpData: array of TBytes);
var
  LIndex, LLength: Integer;
  LEntities: TBytes;
begin
  inherited Create;
  FVersion := AHeader.Version;
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    FLumps[LIndex] := AHeader.Lumps[LIndex];
    FLumpData[LIndex] := ALumpData[LIndex];
  end;

  // the entity string of the engine ends at the first NUL
  LEntities := FLumpData[LUMP_ENTITIES];
  LLength := 0;
  while (LLength < Length(LEntities)) and (LEntities[LLength] <> 0) do
    Inc(LLength);
  SetLength(FEntityText, LLength);
  if LLength > 0 then
    Move(LEntities[0], FEntityText[1], LLength);

  FShaders := Decode<TBspShader>(FLumpData[LUMP_SHADERS]);
  FPlanes := Decode<TBspPlane>(FLumpData[LUMP_PLANES]);
  FNodes := Decode<TBspNode>(FLumpData[LUMP_NODES]);
  FLeafs := Decode<TBspLeaf>(FLumpData[LUMP_LEAFS]);
  FLeafSurfaces := Decode<Integer>(FLumpData[LUMP_LEAFSURFACES]);
  FLeafBrushes := Decode<Integer>(FLumpData[LUMP_LEAFBRUSHES]);
  FModels := Decode<TBspModel>(FLumpData[LUMP_MODELS]);
  FBrushes := Decode<TBspBrush>(FLumpData[LUMP_BRUSHES]);
  FBrushSides := Decode<TBspBrushSide>(FLumpData[LUMP_BRUSHSIDES]);
  FDrawVerts := Decode<TBspDrawVert>(FLumpData[LUMP_DRAWVERTS]);
  FDrawIndexes := Decode<Integer>(FLumpData[LUMP_DRAWINDEXES]);
  FFogs := Decode<TBspFog>(FLumpData[LUMP_FOGS]);
  FSurfaces := Decode<TBspSurface>(FLumpData[LUMP_SURFACES]);

  // R_LoadVisibility: two integers and the rows; an empty lump means "no visibility"
  LLength := Length(FLumpData[LUMP_VISIBILITY]);
  if LLength >= 8 then
  begin
    Move(FLumpData[LUMP_VISIBILITY][0], FNumClusters, 4);
    Move(FLumpData[LUMP_VISIBILITY][4], FClusterBytes, 4);
    SetLength(FVisibility, LLength - 8);
    if LLength > 8 then
      Move(FLumpData[LUMP_VISIBILITY][8], FVisibility[0], LLength - 8);
  end;
end;

class function TBspFile.Decode<T>(const ABytes: TBytes): TArray<T>;
var
  LCount: Integer;
begin
  LCount := Length(ABytes) div SizeOf(T);
  SetLength(Result, LCount);
  if LCount > 0 then
    Move(ABytes[0], Result[0], LCount * SizeOf(T));
end;

class function TBspFile.NameOf(const AChars: array of AnsiChar): AnsiString;
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < Length(AChars)) and (AChars[LLength] <> #0) do
    Inc(LLength);
  SetLength(Result, LLength);
  if LLength > 0 then
    Move(AChars[0], Result[1], LLength);
end;

function TBspFile.GetVersion: Integer;
begin
  Result := FVersion;
end;

function TBspFile.GetLump(const AIndex: Integer): TBspLump;
begin
  Result := FLumps[AIndex];
end;

function TBspFile.GetLumpData(const AIndex: Integer): TBytes;
begin
  Result := FLumpData[AIndex];
end;

function TBspFile.GetEntityText: AnsiString;
begin
  Result := FEntityText;
end;

function TBspFile.GetShaders: TArray<TBspShader>;
begin
  Result := FShaders;
end;

function TBspFile.GetPlanes: TArray<TBspPlane>;
begin
  Result := FPlanes;
end;

function TBspFile.GetNodes: TArray<TBspNode>;
begin
  Result := FNodes;
end;

function TBspFile.GetLeafs: TArray<TBspLeaf>;
begin
  Result := FLeafs;
end;

function TBspFile.GetLeafSurfaces: TArray<Integer>;
begin
  Result := FLeafSurfaces;
end;

function TBspFile.GetLeafBrushes: TArray<Integer>;
begin
  Result := FLeafBrushes;
end;

function TBspFile.GetModels: TArray<TBspModel>;
begin
  Result := FModels;
end;

function TBspFile.GetBrushes: TArray<TBspBrush>;
begin
  Result := FBrushes;
end;

function TBspFile.GetBrushSides: TArray<TBspBrushSide>;
begin
  Result := FBrushSides;
end;

function TBspFile.GetDrawVerts: TArray<TBspDrawVert>;
begin
  Result := FDrawVerts;
end;

function TBspFile.GetDrawIndexes: TArray<Integer>;
begin
  Result := FDrawIndexes;
end;

function TBspFile.GetFogs: TArray<TBspFog>;
begin
  Result := FFogs;
end;

function TBspFile.GetSurfaces: TArray<TBspSurface>;
begin
  Result := FSurfaces;
end;

function TBspFile.GetLightmaps: TBytes;
begin
  Result := FLumpData[LUMP_LIGHTMAPS];
end;

function TBspFile.GetLightGrid: TBytes;
begin
  Result := FLumpData[LUMP_LIGHTGRID];
end;

function TBspFile.GetNumClusters: Integer;
begin
  Result := FNumClusters;
end;

function TBspFile.GetClusterBytes: Integer;
begin
  Result := FClusterBytes;
end;

function TBspFile.GetVisibility: TBytes;
begin
  Result := FVisibility;
end;

function TBspFile.ShaderName(const AIndex: Integer): AnsiString;
begin
  Result := NameOf(FShaders[AIndex].Shader);
end;

function TBspFile.FogShaderName(const AIndex: Integer): AnsiString;
begin
  Result := NameOf(FFogs[AIndex].Shader);
end;

function TBspFile.LightmapCount: Integer;
begin
  Result := Length(FLumpData[LUMP_LIGHTMAPS]) div BSP_LIGHTMAP_BYTES;
end;

end.
