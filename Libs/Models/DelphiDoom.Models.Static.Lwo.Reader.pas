{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the reader of LWO2 files     }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_lwo.cpp   }
{  (lwGetObject, lwGetPoints, lwGetPolygons, lwGetVMap, lwGetTags,             }
{  lwGetPolygonTags, lwGetSurface and the post processing: polygon normals,    }
{  vertex normals, point polygons, vertex maps), converted from the LightWave  }
{  6.5 SDK lwobject sample. Copyright (C) 1999-2011 id Software LLC, a         }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Lwo.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Lwo.Types;

type
  /// <summary>
  ///   Reads a LightWave 6 object (FORM LWO2): layers with points, polygons and vertex maps, the
  ///   tags and the surfaces. As lwGetObject it also computes the normals of the polygons and of
  ///   their vertexes (smoothing groups and angle of the surface). Not read: LWOB (LightWave 5),
  ///   envelopes (ENVL), clips (CLIP) and everything in a surface but its colour and smoothing
  ///   angle. It has no state.
  /// </summary>
  TLwoReader = class
  public
    /// <summary>Raises EStaticModelException (with the offset in the file) if the file is not valid</summary>
    function Read(const AData: TBytes): TLwoObject;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.ByteReader;

function Id(const A, B, C, D: AnsiChar): Cardinal; inline;
begin
  Result := (Cardinal(Ord(A)) shl 24) or (Cardinal(Ord(B)) shl 16) or (Cardinal(Ord(C)) shl 8) or Cardinal(Ord(D));
end;

function IdText(const AId: Cardinal): string;
begin
  Result := string(AnsiChar(AId shr 24)) + string(AnsiChar(AId shr 16)) + string(AnsiChar(AId shr 8)) +
    string(AnsiChar(AId));
end;

type
  TReadState = record
    Obj: TLwoObject;
    /// <summary>The layer that the chunks go to (the last LAYR)</summary>
    Current: Integer;
    /// <summary>layer->point.offset and layer->polygon.offset of the current layer</summary>
    PointOffset: Integer;
    PolygonOffset: Integer;
    /// <summary>tlist->offset</summary>
    TagOffset: Integer;
  end;

procedure Fail(const AId: Cardinal; const AWhat: string; const AOffset: Integer);
begin
  raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadChunk, [IdText(AId), AWhat]), AOffset);
end;

procedure ReadLayer(var AState: TReadState; const AChunk: TBytes; const AChunkId: Cardinal; const AOffset: Integer);
var
  LReader: TStaticByteReader;
  LSize: Integer;
begin
  if AState.Obj.LayerCount > 0 then
  begin
    SetLength(AState.Obj.Layers, Length(AState.Obj.Layers) + 1);
    AState.Current := High(AState.Obj.Layers);
    AState.PointOffset := 0;
    AState.PolygonOffset := 0;
  end;
  Inc(AState.Obj.LayerCount);
  LReader := TStaticByteReader.Create(AChunk);
  try
    with AState.Obj.Layers[AState.Current] do
    begin
      Index := LReader.ReadU2;
      Flags := LReader.ReadU2;
      Pivot.X := LReader.ReadF4;
      Pivot.Y := LReader.ReadF4;
      Pivot.Z := LReader.ReadF4;
      Name := LReader.ReadS0(LSize);
      if LReader.Position <= Length(AChunk) - 2 then
        Parent := LReader.ReadU2;
    end;
  finally
    LReader.Free;
  end;
end;

procedure ReadPoints(var AState: TReadState; const AChunk: TBytes);
var
  LReader: TStaticByteReader;
  LCount, LIndex, LOld: Integer;
begin
  LCount := Length(AChunk) div 12;
  LReader := TStaticByteReader.Create(AChunk);
  try
    LOld := Length(AState.Obj.Layers[AState.Current].Points);
    AState.PointOffset := LOld;
    SetLength(AState.Obj.Layers[AState.Current].Points, LOld + LCount);
    for LIndex := 0 to LCount - 1 do
      with AState.Obj.Layers[AState.Current].Points[LOld + LIndex] do
      begin
        Pos.X := LReader.ReadF4;
        Pos.Y := LReader.ReadF4;
        Pos.Z := LReader.ReadF4;
      end;
  finally
    LReader.Free;
  end;
end;

procedure ReadPolygons(var AState: TReadState; const AChunk: TBytes);
var
  LReader: TStaticByteReader;
  LType: Cardinal;
  LCount, LIndex, LVert, LNumVerts, LFlags, LOld, LSize: Integer;
  LEnd: Integer;
begin
  if Length(AChunk) = 0 then
    Exit;
  LReader := TStaticByteReader.Create(AChunk);
  try
    LType := LReader.ReadU4;
    LEnd := Length(AChunk);
    LOld := Length(AState.Obj.Layers[AState.Current].Polygons);
    AState.PolygonOffset := LOld;
    // count first, as the original does, so that a damaged chunk raises before anything is added
    LCount := 0;
    LIndex := LReader.Position;
    while LReader.Position < LEnd do
    begin
      LNumVerts := LReader.ReadU2 and $03FF;
      for LVert := 1 to LNumVerts do
        LReader.ReadVX(LSize);
      Inc(LCount);
    end;
    LReader.Position := LIndex;
    SetLength(AState.Obj.Layers[AState.Current].Polygons, LOld + LCount);
    for LIndex := 0 to LCount - 1 do
      with AState.Obj.Layers[AState.Current].Polygons[LOld + LIndex] do
      begin
        LNumVerts := LReader.ReadU2;
        LFlags := LNumVerts and $FC00;
        LNumVerts := LNumVerts and $03FF;
        Flags := LFlags;
        Kind := LType;
        SetLength(Verts, LNumVerts);
        for LVert := 0 to LNumVerts - 1 do
          Verts[LVert].Index := LReader.ReadVX(LSize) + AState.PointOffset;
      end;
  finally
    LReader.Free;
  end;
end;

procedure ReadVMap(var AState: TReadState; const AChunk: TBytes; const APerPoly: Boolean);
var
  LReader: TStaticByteReader;
  LMap: TLwoVMap;
  LStart, LCount, LIndex, LComponent, LSize: Integer;
begin
  LReader := TStaticByteReader.Create(AChunk);
  try
    LMap.PerPoly := APerPoly;
    LMap.Kind := LReader.ReadU4;
    LMap.Dim := LReader.ReadU2;
    LMap.Name := LReader.ReadS0(LSize);
    LStart := LReader.Position;
    LCount := 0;
    while LReader.Position < Length(AChunk) do
    begin
      LReader.ReadVX(LSize);
      if APerPoly then
        LReader.ReadVX(LSize);
      LReader.Skip(LMap.Dim * SizeOf(Single));
      Inc(LCount);
    end;
    LReader.Position := LStart;
    SetLength(LMap.VertexIndex, LCount);
    if APerPoly then
      SetLength(LMap.PolygonIndex, LCount);
    SetLength(LMap.Values, LCount * LMap.Dim);
    for LIndex := 0 to LCount - 1 do
    begin
      LMap.VertexIndex[LIndex] := LReader.ReadVX(LSize);
      if APerPoly then
        LMap.PolygonIndex[LIndex] := LReader.ReadVX(LSize);
      for LComponent := 0 to LMap.Dim - 1 do
        LMap.Values[LIndex * LMap.Dim + LComponent] := LReader.ReadF4;
    end;
  finally
    LReader.Free;
  end;
  with AState.Obj.Layers[AState.Current] do
  begin
    SetLength(VMaps, Length(VMaps) + 1);
    VMaps[High(VMaps)] := LMap;
  end;
end;

procedure ReadTags(var AState: TReadState; const AChunk: TBytes);
var
  LReader: TStaticByteReader;
  LSize: Integer;
begin
  if Length(AChunk) = 0 then
    Exit;
  AState.TagOffset := Length(AState.Obj.Tags);
  LReader := TStaticByteReader.Create(AChunk);
  try
    while LReader.Remaining > 0 do
    begin
      SetLength(AState.Obj.Tags, Length(AState.Obj.Tags) + 1);
      AState.Obj.Tags[High(AState.Obj.Tags)] := LReader.ReadS0(LSize);
    end;
  finally
    LReader.Free;
  end;
end;

procedure ReadPolygonTags(var AState: TReadState; const AChunk: TBytes; const AOffset: Integer);
var
  LReader: TStaticByteReader;
  LType: Cardinal;
  LPolygon, LTag, LSize: Integer;
  LPolygons: Integer;
begin
  LReader := TStaticByteReader.Create(AChunk);
  try
    LType := LReader.ReadU4;
    if (LType <> Id('S', 'U', 'R', 'F')) and (LType <> Id('P', 'A', 'R', 'T')) and
      (LType <> Id('S', 'M', 'G', 'P')) then
      Exit;
    LPolygons := Length(AState.Obj.Layers[AState.Current].Polygons);
    while LReader.Position < Length(AChunk) do
    begin
      LPolygon := LReader.ReadVX(LSize) + AState.PolygonOffset;
      LTag := LReader.ReadVX(LSize) + AState.TagOffset;
      if (LPolygon < 0) or (LPolygon >= LPolygons) then
        raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadPolygonTag, [LPolygon, LPolygons]), AOffset);
      with AState.Obj.Layers[AState.Current].Polygons[LPolygon] do
        if LType = Id('S', 'U', 'R', 'F') then
          Surf := LTag
        else if LType = Id('P', 'A', 'R', 'T') then
          Part := LTag
        else
          SmoothGroup := LTag;
    end;
  finally
    LReader.Free;
  end;
end;

procedure ReadSurface(var AState: TReadState; const AChunk: TBytes; const AOffset: Integer);
var
  LReader: TStaticByteReader;
  LSurface: TLwoSurface;
  LSize, LChunkSize, LStart, LRead: Integer;
  LSubId: Cardinal;
  LName: AnsiString;
begin
  LSurface.Red := 0.78431;
  LSurface.Green := 0.78431;
  LSurface.Blue := 0.78431;
  LSurface.Smooth := 0;
  LReader := TStaticByteReader.Create(AChunk);
  try
    LSurface.Name := LReader.ReadS0(LSize);
    LName := LReader.ReadS0(LSize);
    while LReader.Position < Length(AChunk) do
    begin
      LSubId := LReader.ReadU4;
      LChunkSize := LReader.ReadU2;
      LChunkSize := LChunkSize + (LChunkSize and 1);
      LStart := LReader.Position;
      if LSubId = Id('C', 'O', 'L', 'R') then
      begin
        LSurface.Red := LReader.ReadF4;
        LSurface.Green := LReader.ReadF4;
        LSurface.Blue := LReader.ReadF4;
        LReader.ReadVX(LSize);
      end
      else if LSubId = Id('S', 'M', 'A', 'N') then
        LSurface.Smooth := LReader.ReadF4;
      LRead := LReader.Position - LStart;
      if LRead > LChunkSize then
        Fail(Id('S', 'U', 'R', 'F'), 'a sub chunk is too short', AOffset);
      LReader.Position := LStart + LChunkSize;
      if LReader.Position > Length(AChunk) then
        Fail(Id('S', 'U', 'R', 'F'), 'a sub chunk is out of the chunk', AOffset);
    end;
  finally
    LReader.Free;
  end;
  SetLength(AState.Obj.Surfaces, Length(AState.Obj.Surfaces) + 1);
  AState.Obj.Surfaces[High(AState.Obj.Surfaces)] := LSurface;
end;

function SurfaceNamed(const AObject: TLwoObject; const AName: AnsiString): Integer;
begin
  for Result := 0 to High(AObject.Surfaces) do
    if AObject.Surfaces[Result].Name = AName then
      Exit;
  Result := -1;
end;

procedure ComputeBounds(var ALayer: TLwoLayer);
var
  LIndex: Integer;
begin
  ALayer.BBoxMin.Zero;
  ALayer.BBoxMax.Zero;
  for LIndex := 0 to High(ALayer.Points) do
  begin
    if LIndex = 0 then
    begin
      ALayer.BBoxMin := ALayer.Points[0].Pos;
      ALayer.BBoxMax := ALayer.Points[0].Pos;
    end
    else
    begin
      if ALayer.Points[LIndex].Pos.X < ALayer.BBoxMin.X then ALayer.BBoxMin.X := ALayer.Points[LIndex].Pos.X;
      if ALayer.Points[LIndex].Pos.Y < ALayer.BBoxMin.Y then ALayer.BBoxMin.Y := ALayer.Points[LIndex].Pos.Y;
      if ALayer.Points[LIndex].Pos.Z < ALayer.BBoxMin.Z then ALayer.BBoxMin.Z := ALayer.Points[LIndex].Pos.Z;
      if ALayer.Points[LIndex].Pos.X > ALayer.BBoxMax.X then ALayer.BBoxMax.X := ALayer.Points[LIndex].Pos.X;
      if ALayer.Points[LIndex].Pos.Y > ALayer.BBoxMax.Y then ALayer.BBoxMax.Y := ALayer.Points[LIndex].Pos.Y;
      if ALayer.Points[LIndex].Pos.Z > ALayer.BBoxMax.Z then ALayer.BBoxMax.Z := ALayer.Points[LIndex].Pos.Z;
    end;
  end;
end;

/// <summary>The functions dot, cross and normalize of the SDK, which use idMath::Sqrt</summary>
function Dot(const A, B: TIdVec3): Single;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;

function Cross(const A, B: TIdVec3): TIdVec3;
begin
  Result.X := A.Y * B.Z - A.Z * B.Y;
  Result.Y := A.Z * B.X - A.X * B.Z;
  Result.Z := A.X * B.Y - A.Y * B.X;
end;

procedure NormalizeVec(var AVector: TIdVec3);
var
  LLength: Single;
begin
  LLength := TIdMath.Sqrt(Dot(AVector, AVector));
  if LLength > 0 then
  begin
    AVector.X := AVector.X / LLength;
    AVector.Y := AVector.Y / LLength;
    AVector.Z := AVector.Z / LLength;
  end;
end;

procedure PostProcess(var AObject: TLwoObject);
var
  LLayerIndex, LPolygon, LVert, LPoint, LTagIndex, LOther, LRef, LMap, LRecord: Integer;
  LV1, LV2, LP1: TIdVec3;
  LTagSurface: TArray<Integer>;
  LAngle: Single;
  LSmooth: Single;
  LOffset: Integer;
begin
  for LLayerIndex := 0 to High(AObject.Layers) do
  begin
    ComputeBounds(AObject.Layers[LLayerIndex]);
    with AObject.Layers[LLayerIndex] do
    begin
      // lwGetPolyNormals: the cross product of the first and the last edge
      for LPolygon := 0 to High(Polygons) do
      begin
        if Length(Polygons[LPolygon].Verts) < 3 then
          Continue;
        for LVert := 0 to High(Polygons[LPolygon].Verts) do
          if (Polygons[LPolygon].Verts[LVert].Index < 0) or (Polygons[LPolygon].Verts[LVert].Index >= Length(Points)) then
            raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadPoint,
              [Polygons[LPolygon].Verts[LVert].Index, Length(Points)]), -1);
        LP1 := Points[Polygons[LPolygon].Verts[0].Index].Pos;
        LV1 := Points[Polygons[LPolygon].Verts[1].Index].Pos;
        LV2 := Points[Polygons[LPolygon].Verts[High(Polygons[LPolygon].Verts)].Index].Pos;
        LV1.X := LV1.X - LP1.X; LV1.Y := LV1.Y - LP1.Y; LV1.Z := LV1.Z - LP1.Z;
        LV2.X := LV2.X - LP1.X; LV2.Y := LV2.Y - LP1.Y; LV2.Z := LV2.Z - LP1.Z;
        Polygons[LPolygon].Norm := Cross(LV1, LV2);
        NormalizeVec(Polygons[LPolygon].Norm);
      end;
      // lwGetPointPolygons
      for LPolygon := 0 to High(Polygons) do
        for LVert := 0 to High(Polygons[LPolygon].Verts) do
        begin
          LPoint := Polygons[LPolygon].Verts[LVert].Index;
          if (LPoint < 0) or (LPoint >= Length(Points)) then
            raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadPoint, [LPoint, Length(Points)]), -1);
          SetLength(Points[LPoint].Polygons, Length(Points[LPoint].Polygons) + 1);
          Points[LPoint].Polygons[High(Points[LPoint].Polygons)] := LPolygon;
        end;
    end;
    // lwResolvePolySurfaces: tag indexes to surfaces; a tag without surface gets a default one
    if (Length(AObject.Tags) > 0) then
    begin
      SetLength(LTagSurface, Length(AObject.Tags));
      for LTagIndex := 0 to High(AObject.Tags) do
        LTagSurface[LTagIndex] := SurfaceNamed(AObject, AObject.Tags[LTagIndex]);
      for LPolygon := 0 to High(AObject.Layers[LLayerIndex].Polygons) do
      begin
        LTagIndex := AObject.Layers[LLayerIndex].Polygons[LPolygon].Surf;
        if (LTagIndex < 0) or (LTagIndex >= Length(AObject.Tags)) then
          raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadTag, [LTagIndex, Length(AObject.Tags)]), -1);
        if LTagSurface[LTagIndex] < 0 then
        begin
          SetLength(AObject.Surfaces, Length(AObject.Surfaces) + 1);
          with AObject.Surfaces[High(AObject.Surfaces)] do
          begin
            Name := AObject.Tags[LTagIndex];
            Red := 0.78431;
            Green := 0.78431;
            Blue := 0.78431;
            Smooth := 0;
          end;
          LTagSurface[LTagIndex] := High(AObject.Surfaces);
        end;
        AObject.Layers[LLayerIndex].Polygons[LPolygon].Surf := LTagSurface[LTagIndex];
      end;
    end
    else if Length(AObject.Layers[LLayerIndex].Polygons) > 0 then
      raise EStaticModelException.CreateAtOffset(SStaticLwoNoTags, -1);

    with AObject.Layers[LLayerIndex] do
    begin
      // lwGetVertNormals
      for LPolygon := 0 to High(Polygons) do
        for LVert := 0 to High(Polygons[LPolygon].Verts) do
        begin
          Polygons[LPolygon].Verts[LVert].Norm := Polygons[LPolygon].Norm;
          LSmooth := AObject.Surfaces[Polygons[LPolygon].Surf].Smooth;
          if LSmooth <= 0 then
            Continue;
          LPoint := Polygons[LPolygon].Verts[LVert].Index;
          for LOther := 0 to High(Points[LPoint].Polygons) do
          begin
            LRef := Points[LPoint].Polygons[LOther];
            if LRef = LPolygon then
              Continue;
            if Polygons[LPolygon].SmoothGroup <> Polygons[LRef].SmoothGroup then
              Continue;
            LAngle := TIdMath.ACos(Dot(Polygons[LPolygon].Norm, Polygons[LRef].Norm));
            if LAngle > LSmooth then
              Continue;
            Polygons[LPolygon].Verts[LVert].Norm.X := Polygons[LPolygon].Verts[LVert].Norm.X + Polygons[LRef].Norm.X;
            Polygons[LPolygon].Verts[LVert].Norm.Y := Polygons[LPolygon].Verts[LVert].Norm.Y + Polygons[LRef].Norm.Y;
            Polygons[LPolygon].Verts[LVert].Norm.Z := Polygons[LPolygon].Verts[LVert].Norm.Z + Polygons[LRef].Norm.Z;
          end;
          NormalizeVec(Polygons[LPolygon].Verts[LVert].Norm);
        end;
      // lwGetPointVMaps and lwGetPolyVMaps
      for LMap := 0 to High(VMaps) do
        for LRecord := 0 to VMaps[LMap].Count - 1 do
        begin
          LPoint := VMaps[LMap].VertexIndex[LRecord];
          if not VMaps[LMap].PerPoly then
          begin
            if (LPoint < 0) or (LPoint >= Length(Points)) then
              raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadVMap,
                [string(VMaps[LMap].Name), 'point', LPoint]), -1);
            SetLength(Points[LPoint].VMaps, Length(Points[LPoint].VMaps) + 1);
            Points[LPoint].VMaps[High(Points[LPoint].VMaps)].VMap := LMap;
            Points[LPoint].VMaps[High(Points[LPoint].VMaps)].Index := LRecord;
          end
          else
          begin
            LPolygon := VMaps[LMap].PolygonIndex[LRecord];
            if (LPolygon < 0) or (LPolygon >= Length(Polygons)) then
              raise EStaticModelException.CreateAtOffset(Format(SStaticLwoBadVMap,
                [string(VMaps[LMap].Name), 'polygon', LPolygon]), -1);
            for LVert := 0 to High(Polygons[LPolygon].Verts) do
              if Polygons[LPolygon].Verts[LVert].Index = LPoint then
              begin
                LOffset := Length(Polygons[LPolygon].Verts[LVert].VMaps);
                SetLength(Polygons[LPolygon].Verts[LVert].VMaps, LOffset + 1);
                Polygons[LPolygon].Verts[LVert].VMaps[LOffset].VMap := LMap;
                Polygons[LPolygon].Verts[LVert].VMaps[LOffset].Index := LRecord;
                Break;
              end;
          end;
        end;
    end;
  end;
end;

{ TLwoReader }

function TLwoReader.Read(const AData: TBytes): TLwoObject;
var
  LReader: TStaticByteReader;
  LState: TReadState;
  LId, LType: Cardinal;
  LFormSize, LChunkSize, LChunkStart: Integer;
  LChunk: TBytes;
begin
  LReader := TStaticByteReader.Create(AData);
  try
    if Length(AData) < 12 then
      raise EStaticModelException.CreateAtOffset(SStaticLwoNotLwo, 12);
    LId := LReader.ReadU4;
    LFormSize := Integer(LReader.ReadU4);
    LType := LReader.ReadU4;
    if LId <> Id('F', 'O', 'R', 'M') then
      raise EStaticModelException.CreateAtOffset(SStaticLwoNotLwo, 12);
    if LType = Id('L', 'W', 'O', 'B') then
      raise EStaticModelException.CreateAtOffset(SStaticLwoLwob, 12);
    if LType <> Id('L', 'W', 'O', '2') then
      raise EStaticModelException.CreateAtOffset(SStaticLwoNotLwo, 12);

    Initialize(LState);
    SetLength(LState.Obj.Layers, 1);
    LId := LReader.ReadU4;
    LChunkSize := Integer(LReader.ReadU4);
    while True do
    begin
      LChunkStart := LReader.Position;
      if LChunkSize < 0 then
        raise EStaticModelException.CreateAtOffset(Format(SStaticNegativeSize, [LChunkSize, LChunkStart]), LChunkStart);
      LChunkSize := LChunkSize + (LChunkSize and 1);
      LChunk := LReader.ReadBytes(LChunkSize);
      if LId = Id('L', 'A', 'Y', 'R') then
        ReadLayer(LState, LChunk, LId, LChunkStart)
      else if LId = Id('P', 'N', 'T', 'S') then
        ReadPoints(LState, LChunk)
      else if LId = Id('P', 'O', 'L', 'S') then
        ReadPolygons(LState, LChunk)
      else if (LId = Id('V', 'M', 'A', 'P')) or (LId = Id('V', 'M', 'A', 'D')) then
        ReadVMap(LState, LChunk, LId = Id('V', 'M', 'A', 'D'))
      else if LId = Id('P', 'T', 'A', 'G') then
        ReadPolygonTags(LState, LChunk, LChunkStart)
      else if LId = Id('T', 'A', 'G', 'S') then
        ReadTags(LState, LChunk)
      else if LId = Id('S', 'U', 'R', 'F') then
        ReadSurface(LState, LChunk, LChunkStart);
      // BBOX (computed anyway), ENVL, CLIP, DESC, TEXT, ICON and the unknown ones are skipped
      if LFormSize <= LReader.Position - 8 then
        Break;
      LId := LReader.ReadU4;
      LChunkSize := Integer(LReader.ReadU4);
    end;
    if LState.Obj.LayerCount = 0 then
      LState.Obj.LayerCount := 1;
    PostProcess(LState.Obj);
    Result := LState.Obj;
  finally
    LReader.Free;
  end;
end;

end.
