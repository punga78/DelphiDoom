{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the optimized mesh (DDMESH) of a voxel           }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.MeshOptimizer;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.VoxelEditor.Model;

type
  TVoxelEditorMeshVertex = record
    X, Y, Z: Integer;
  end;

  TVoxelEditorMeshQuad = record
    Color: Cardinal;
    Vertices: array[0..3] of TVoxelEditorMeshVertex;
    Valid: Boolean;
    /// <summary>The axis that is the same for the four vertices: 'x', 'y' or 'z'</summary>
    Orientation: AnsiChar;
  end;

  /// <summary>
  ///   The mesh of a voxel (TVoxelMeshOptimizer of vxe_mesh): a square for each face of a voxel that can be seen,
  ///   then neighbor squares of the same color and the same plane joined in up to PassCount passes, and the file
  ///   (DDMESH) that the engine loads: the quads, then the voxels that are not buried
  /// </summary>
  TVoxelEditorMeshOptimizer = class
  strict private
    FQuads: TArray<TVoxelEditorMeshQuad>;
    FQuadCount: Integer;
    FPassCount: Integer;
    FMessage: string;
    FSize: Integer;
    FVoxels: TArray<Cardinal>;
    procedure AddQuad(AColor: Cardinal; const AVertices: array of Integer);
    procedure SortVertices(var AQuad: TVoxelEditorMeshQuad);
    procedure TryMerge(var AFirst, ASecond: TVoxelEditorMeshQuad);
    procedure InnerOptimize;
  public
    constructor Create;
    /// <summary>Makes the squares of the faces that are seen; what was there before is gone</summary>
    procedure LoadVoxel(const AModel: TVoxelEditorModel);
    /// <summary>Joins squares until a pass changes nothing, or PassCount passes have been done</summary>
    procedure Optimize;
    /// <summary>The DDMESH file</summary>
    function ToBytes: TBytes;
    property QuadCount: Integer read FQuadCount;
    property Quads: TArray<TVoxelEditorMeshQuad> read FQuads;
    /// <summary>The most passes of the optimizer (3, as in the old editor)</summary>
    property PassCount: Integer read FPassCount write FPassCount;
    /// <summary>What the optimizer has to tell (how much the mesh was reduced), empty if nothing</summary>
    property Message: string read FMessage;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types;

const
  FLAG_X0 = 1;
  FLAG_X1 = 2;
  FLAG_Y0 = 4;
  FLAG_Y1 = 8;
  FLAG_Z0 = 16;
  FLAG_Z1 = 32;
  FLAG_ALL = FLAG_X0 + FLAG_X1 + FLAG_Y0 + FLAG_Y1 + FLAG_Z0 + FLAG_Z1;
  /// <summary>A square is tried against the next 10000 only (the old limit, for the time the pass takes)</summary>
  MERGE_WINDOW = 10000;

{ TVoxelEditorMeshOptimizer }

constructor TVoxelEditorMeshOptimizer.Create;
begin
  inherited Create;
  FPassCount := 3;
end;

procedure TVoxelEditorMeshOptimizer.AddQuad(AColor: Cardinal; const AVertices: array of Integer);
var
  LQuad: ^TVoxelEditorMeshQuad;
  LIndex: Integer;
begin
  if FQuadCount >= Length(FQuads) then
    SetLength(FQuads, Length(FQuads) + 256);
  LQuad := @FQuads[FQuadCount];
  Inc(FQuadCount);
  LQuad.Color := AColor;
  for LIndex := 0 to 3 do
  begin
    LQuad.Vertices[LIndex].X := AVertices[LIndex * 3];
    LQuad.Vertices[LIndex].Y := AVertices[LIndex * 3 + 1];
    LQuad.Vertices[LIndex].Z := AVertices[LIndex * 3 + 2];
  end;
  LQuad.Valid := True;
  if (AVertices[0] = AVertices[3]) and (AVertices[0] = AVertices[6]) and (AVertices[0] = AVertices[9]) then
    LQuad.Orientation := 'x'
  else if (AVertices[1] = AVertices[4]) and (AVertices[1] = AVertices[7]) and (AVertices[1] = AVertices[10]) then
    LQuad.Orientation := 'y'
  else if (AVertices[2] = AVertices[5]) and (AVertices[2] = AVertices[8]) and (AVertices[2] = AVertices[11]) then
    LQuad.Orientation := 'z'
  else
  begin
    LQuad.Orientation := ' ';
    LQuad.Valid := False;
  end;
end;

procedure TVoxelEditorMeshOptimizer.LoadVoxel(const AModel: TVoxelEditorModel);
var
  LSize, LX, LY, LZ, LX1, LY1, LZ1: Integer;
  LFlags: TArray<Byte>;
  LBits: Byte;
  LColor: Cardinal;
begin
  LSize := AModel.Size;
  FSize := LSize;
  FQuadCount := 0;
  FQuads := nil;
  SetLength(LFlags, Length(AModel.Cells));
  for LX := 0 to LSize - 1 do
    for LY := 0 to LSize - 1 do
      for LZ := 0 to LSize - 1 do
        if (LX > 0) and (LX < LSize - 1) and (LY > 0) and (LY < LSize - 1) and (LZ > 0) and (LZ < LSize - 1) then
        begin
          LBits := 0;
          if AModel.Get(LX - 1, LY, LZ) <> 0 then
            LBits := FLAG_X0;
          if AModel.Get(LX + 1, LY, LZ) <> 0 then
            LBits := LBits + FLAG_X1;
          if AModel.Get(LX, LY - 1, LZ) <> 0 then
            LBits := LBits + FLAG_Y0;
          if AModel.Get(LX, LY + 1, LZ) <> 0 then
            LBits := LBits + FLAG_Y1;
          if AModel.Get(LX, LY, LZ - 1) <> 0 then
            LBits := LBits + FLAG_Z0;
          if AModel.Get(LX, LY, LZ + 1) <> 0 then
            LBits := LBits + FLAG_Z1;
          LFlags[AModel.IndexOf(LX, LY, LZ)] := LBits;
        end;
  for LX := 0 to LSize - 1 do
    for LY := 0 to LSize - 1 do
      for LZ := 0 to LSize - 1 do
      begin
        LColor := AModel.Get(LX, LY, LZ);
        if LColor = 0 then
          Continue;
        LBits := LFlags[AModel.IndexOf(LX, LY, LZ)];
        LX1 := LX + 1;
        LY1 := LY + 1;
        LZ1 := LZ + 1;
        if LBits and FLAG_Z0 = 0 then
          AddQuad(LColor, [LX, LY, LZ, LX, LY1, LZ, LX1, LY1, LZ, LX1, LY, LZ]);
        if LBits and FLAG_Y0 = 0 then
          AddQuad(LColor, [LX, LY, LZ, LX, LY, LZ1, LX1, LY, LZ1, LX1, LY, LZ]);
        if LBits and FLAG_X0 = 0 then
          AddQuad(LColor, [LX, LY, LZ, LX, LY, LZ1, LX, LY1, LZ1, LX, LY1, LZ]);
        if LBits and FLAG_Z1 = 0 then
          AddQuad(LColor, [LX, LY, LZ1, LX, LY1, LZ1, LX1, LY1, LZ1, LX1, LY, LZ1]);
        if LBits and FLAG_Y1 = 0 then
          AddQuad(LColor, [LX, LY1, LZ, LX, LY1, LZ1, LX1, LY1, LZ1, LX1, LY1, LZ]);
        if LBits and FLAG_X1 = 0 then
          AddQuad(LColor, [LX1, LY, LZ, LX1, LY1, LZ, LX1, LY1, LZ1, LX1, LY, LZ1]);
      end;
  // the voxels that are buried (all six sides taken) are not in the file
  SetLength(FVoxels, Length(AModel.Cells));
  for LX := 0 to High(FVoxels) do
    if LFlags[LX] = FLAG_ALL then
      FVoxels[LX] := 0
    else
      FVoxels[LX] := AModel.Cells[LX];
end;

// the four vertices of a square go round it from the corner with the smallest coordinates
procedure TVoxelEditorMeshOptimizer.SortVertices(var AQuad: TVoxelEditorMeshQuad);
var
  LIndex, LTarget: Integer;
  LTable: array[0..3] of Integer;
  LMid1, LMid2: Single;
  LA, LB: array[0..3] of Integer;
  LVertex: TVoxelEditorMeshVertex;
  LDone: Boolean;
begin
  if AQuad.Orientation = 'x' then
    for LIndex := 0 to 3 do
    begin
      LA[LIndex] := AQuad.Vertices[LIndex].Y;
      LB[LIndex] := AQuad.Vertices[LIndex].Z;
    end
  else if AQuad.Orientation = 'y' then
    for LIndex := 0 to 3 do
    begin
      LA[LIndex] := AQuad.Vertices[LIndex].X;
      LB[LIndex] := AQuad.Vertices[LIndex].Z;
    end
  else if AQuad.Orientation = 'z' then
    for LIndex := 0 to 3 do
    begin
      LA[LIndex] := AQuad.Vertices[LIndex].X;
      LB[LIndex] := AQuad.Vertices[LIndex].Y;
    end
  else
    Exit;
  LMid1 := 0;
  LMid2 := 0;
  for LIndex := 0 to 3 do
  begin
    LMid1 := LMid1 + LA[LIndex];
    LMid2 := LMid2 + LB[LIndex];
  end;
  LMid1 := LMid1 / 4;
  LMid2 := LMid2 / 4;
  for LIndex := 0 to 3 do
    if LA[LIndex] < LMid1 then
    begin
      if LB[LIndex] < LMid2 then
        LTable[LIndex] := 0
      else
        LTable[LIndex] := 1;
    end
    else
    begin
      if LB[LIndex] < LMid2 then
        LTable[LIndex] := 3
      else
        LTable[LIndex] := 2;
    end;
  repeat
    LDone := True;
    for LIndex := 0 to 3 do
      if LTable[LIndex] <> LIndex then
      begin
        LVertex := AQuad.Vertices[LIndex];
        LTarget := LTable[LIndex];
        AQuad.Vertices[LIndex] := AQuad.Vertices[LTarget];
        AQuad.Vertices[LTarget] := LVertex;
        LTable[LTarget] := LTarget;
        LTable[LIndex] := LIndex;
        LDone := False;
        Break;
      end;
  until LDone;
end;

// two squares of the same plane that share an edge become one: the first one grows over the second
procedure TVoxelEditorMeshOptimizer.TryMerge(var AFirst, ASecond: TVoxelEditorMeshQuad);
var
  LMatchFirst, LMatchSecond: array[0..3] of Integer;
  LCount, LIndex, LOther, LFirstFree, LLastFree: Integer;
  LFirstA, LFirstB, LSecondA, LSecondB: array[0..3] of Integer;
  LPlaneFirst, LPlaneSecond: Integer;
begin
  case AFirst.Orientation of
    'x':
      begin
        LPlaneFirst := AFirst.Vertices[0].X;
        LPlaneSecond := ASecond.Vertices[0].X;
      end;
    'y':
      begin
        LPlaneFirst := AFirst.Vertices[0].Y;
        LPlaneSecond := ASecond.Vertices[0].Y;
      end;
    'z':
      begin
        LPlaneFirst := AFirst.Vertices[0].Z;
        LPlaneSecond := ASecond.Vertices[0].Z;
      end;
  else
    Exit;
  end;
  if LPlaneFirst <> LPlaneSecond then
    Exit;
  for LIndex := 0 to 3 do
  begin
    LMatchFirst[LIndex] := -1;
    LMatchSecond[LIndex] := -1;
    case AFirst.Orientation of
      'x':
        begin
          LFirstA[LIndex] := AFirst.Vertices[LIndex].Y;
          LFirstB[LIndex] := AFirst.Vertices[LIndex].Z;
          LSecondA[LIndex] := ASecond.Vertices[LIndex].Y;
          LSecondB[LIndex] := ASecond.Vertices[LIndex].Z;
        end;
      'y':
        begin
          LFirstA[LIndex] := AFirst.Vertices[LIndex].X;
          LFirstB[LIndex] := AFirst.Vertices[LIndex].Z;
          LSecondA[LIndex] := ASecond.Vertices[LIndex].X;
          LSecondB[LIndex] := ASecond.Vertices[LIndex].Z;
        end;
    else
      begin
        LFirstA[LIndex] := AFirst.Vertices[LIndex].X;
        LFirstB[LIndex] := AFirst.Vertices[LIndex].Y;
        LSecondA[LIndex] := ASecond.Vertices[LIndex].X;
        LSecondB[LIndex] := ASecond.Vertices[LIndex].Y;
      end;
    end;
  end;
  for LIndex := 0 to 3 do
    for LOther := 0 to 3 do
      if (LFirstA[LIndex] = LSecondA[LOther]) and (LFirstB[LIndex] = LSecondB[LOther]) then
      begin
        LMatchFirst[LIndex] := LOther;
        LMatchSecond[LOther] := LIndex;
      end;
  LCount := 0;
  for LIndex := 0 to 3 do
    if LMatchFirst[LIndex] = -1 then
      Inc(LCount);
  if LCount <> 2 then
    Exit;
  LFirstFree := -1;
  for LIndex := 0 to 3 do
    if LMatchSecond[LIndex] = -1 then
    begin
      LFirstFree := LIndex;
      Break;
    end;
  LLastFree := -1;
  for LIndex := 3 downto 0 do
    if LMatchSecond[LIndex] = -1 then
    begin
      LLastFree := LIndex;
      Break;
    end;
  if (LFirstFree = -1) or (LFirstFree = LLastFree) then
    Exit;
  // the two vertices of the first square that touch the second move to the free vertices of the second
  for LIndex := 0 to 3 do
    if LMatchFirst[LIndex] <> -1 then
    begin
      case AFirst.Orientation of
        'x':
          begin
            AFirst.Vertices[LIndex].Y := ASecond.Vertices[LFirstFree].Y;
            AFirst.Vertices[LIndex].Z := ASecond.Vertices[LFirstFree].Z;
          end;
        'y':
          begin
            AFirst.Vertices[LIndex].X := ASecond.Vertices[LFirstFree].X;
            AFirst.Vertices[LIndex].Z := ASecond.Vertices[LFirstFree].Z;
          end;
      else
        begin
          AFirst.Vertices[LIndex].X := ASecond.Vertices[LFirstFree].X;
          AFirst.Vertices[LIndex].Y := ASecond.Vertices[LFirstFree].Y;
        end;
      end;
      Break;
    end;
  for LIndex := 3 downto 0 do
    if LMatchFirst[LIndex] <> -1 then
    begin
      case AFirst.Orientation of
        'x':
          begin
            AFirst.Vertices[LIndex].Y := ASecond.Vertices[LLastFree].Y;
            AFirst.Vertices[LIndex].Z := ASecond.Vertices[LLastFree].Z;
          end;
        'y':
          begin
            AFirst.Vertices[LIndex].X := ASecond.Vertices[LLastFree].X;
            AFirst.Vertices[LIndex].Z := ASecond.Vertices[LLastFree].Z;
          end;
      else
        begin
          AFirst.Vertices[LIndex].X := ASecond.Vertices[LLastFree].X;
          AFirst.Vertices[LIndex].Y := ASecond.Vertices[LLastFree].Y;
        end;
      end;
      Break;
    end;
  ASecond.Valid := False;
end;

procedure TVoxelEditorMeshOptimizer.InnerOptimize;
var
  LFirst, LSecond, LLimit, LKept: Integer;
  LOrientation: AnsiChar;
  LColor: Cardinal;
begin
  for LFirst := 0 to FQuadCount - 2 do
    if FQuads[LFirst].Valid then
    begin
      LOrientation := FQuads[LFirst].Orientation;
      LColor := FQuads[LFirst].Color;
      LLimit := FQuadCount;
      if LLimit - LFirst > MERGE_WINDOW then
        LLimit := LFirst + MERGE_WINDOW;
      for LSecond := LFirst + 1 to LLimit - 1 do
        if FQuads[LSecond].Valid then
          if (FQuads[LSecond].Orientation = LOrientation) and (FQuads[LSecond].Color = LColor) then
            TryMerge(FQuads[LFirst], FQuads[LSecond]);
    end;
  // the squares that were joined are taken out, and each vertex list that remains is put in order. The old code
  // did this in place when the room did not change, and then lost the first square, repeated the last and
  // forgot to count them: that defect is not kept
  LKept := 0;
  for LFirst := 0 to FQuadCount - 1 do
    if FQuads[LFirst].Valid then
    begin
      if LFirst <> LKept then
        FQuads[LKept] := FQuads[LFirst];
      SortVertices(FQuads[LKept]);
      Inc(LKept);
    end;
  FQuadCount := LKept;
end;

procedure TVoxelEditorMeshOptimizer.Optimize;
var
  LCount, LOldCount, LPass: Integer;
begin
  if FPassCount <= 0 then
  begin
    FPassCount := 0;
    FMessage := SVoxelEditorMeshNoPasses;
    Exit;
  end;
  LOldCount := FQuadCount;
  LPass := 0;
  repeat
    LCount := FQuadCount;
    InnerOptimize;
    Inc(LPass);
    if LPass = FPassCount then
      Break;
  until LCount = FQuadCount;
  if LOldCount > FQuadCount then
    FMessage := Format(SVoxelEditorMeshReduced, [LOldCount, FQuadCount, LPass]);
end;

function TVoxelEditorMeshOptimizer.ToBytes: TBytes;
var
  LStream: TBytesStream;
  LIndex, LVertex, LCount, LX, LY, LZ: Integer;
  LMagic: Cardinal;
  LVersion: Integer;
  LCoordinate: Byte;
  LColor: Cardinal;
begin
  LStream := TBytesStream.Create;
  try
    LMagic := VOXEL_EDITOR_DDMESH_MAGIC;
    LVersion := VOXEL_EDITOR_DDMESH_VERSION;
    LStream.Write(LMagic, 4);
    LStream.Write(LVersion, 4);
    LStream.Write(FSize, 4);
    LStream.Write(FQuadCount, 4);
    for LIndex := 0 to FQuadCount - 1 do
    begin
      LStream.Write(FQuads[LIndex].Color, 4);
      for LVertex := 0 to 3 do
        LStream.Write(FQuads[LIndex].Vertices[LVertex], SizeOf(TVoxelEditorMeshVertex));
    end;
    LCount := 0;
    for LIndex := 0 to High(FVoxels) do
      if FVoxels[LIndex] <> 0 then
        Inc(LCount);
    LStream.Write(LCount, 4);
    for LX := 0 to FSize - 1 do
      for LY := 0 to FSize - 1 do
        for LZ := 0 to FSize - 1 do
        begin
          LColor := FVoxels[(LX * FSize + LY) * FSize + LZ];
          if LColor <> 0 then
          begin
            LCoordinate := LX;
            LStream.Write(LCoordinate, 1);
            LCoordinate := LY;
            LStream.Write(LCoordinate, 1);
            LCoordinate := LZ;
            LStream.Write(LCoordinate, 1);
            LStream.Write(LColor, 4);
          end;
        end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

end.
