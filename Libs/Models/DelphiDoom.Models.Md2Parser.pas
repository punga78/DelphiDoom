{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the reader of MD2 files                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md2Parser;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Intf;

type
  /// <summary>
  ///   The old constructor of TMD2Model without the stream and the OpenGL: from the bytes of the
  ///   file to the vertexes of each frame. The arithmetic of a vertex is the old one (single
  ///   values in an expression of the FPU), so at 32 bit the results have the same bits.
  /// </summary>
  TMd2Parser = class(TInterfacedObject, IMd2Parser)
  strict private
    class function FrameGroupName(const AHead: TMd2FrameHead): string; static;
    class procedure CheckRange(const AWhat: string; const AOffset, ASize: Int64;
      const ALength: Integer); static;
  public
    /// <summary>
    ///   The name of the group of a frame: the name in capital letters, trimmed, without the
    ///   number at the end (one or two digits). "stand01" and "STAND2" are STAND.
    /// </summary>
    class function GroupNameOf(const AFrameName: string): string; static;
    function Parse(const ABytes: TBytes; const APlacement: TModelPlacement): IMd2Model;
  end;

implementation

uses
  DelphiDoom.Models.Md2Model;

{ TMd2Parser }

class procedure TMd2Parser.CheckRange(const AWhat: string; const AOffset, ASize: Int64;
  const ALength: Integer);
begin
  if (AOffset < 0) or (ASize < 0) or (AOffset + ASize > ALength) then
    raise EModelsException.CreateFmt(SModelsMd2Truncated, [AWhat, AOffset, ASize]);
end;

class function TMd2Parser.GroupNameOf(const AFrameName: string): string;
var
  LName: string;
  LIndex: Integer;
  LCharacter: Char;
begin
  // capital letters (only a..z, as the old strupper) and no spaces or control characters around
  LName := AFrameName;
  for LIndex := 1 to Length(LName) do
    if (LName[LIndex] >= 'a') and (LName[LIndex] <= 'z') then
      LName[LIndex] := Char(Ord(LName[LIndex]) - 32);
  LIndex := 1;
  while (LIndex <= Length(LName)) and (LName[LIndex] <= ' ') do
    Inc(LIndex);
  if LIndex > Length(LName) then
    LName := ''
  else
  begin
    Delete(LName, 1, LIndex - 1);
    while LName[Length(LName)] <= ' ' do
      Delete(LName, Length(LName), 1);
  end;

  // the old rule: if the second last character is a digit two characters are taken away
  // (stand01 -> stand), else one (stand1 -> stand; a name without a number loses its last letter)
  LIndex := Length(LName) - 1;
  if LIndex < 1 then
    LIndex := 1;
  if LIndex <= Length(LName) then
    LCharacter := LName[LIndex]
  else
    LCharacter := #0;
  if (LCharacter >= '0') and (LCharacter <= '9') then
    Result := Copy(LName, 1, Length(LName) - 2)
  else
    Result := Copy(LName, 1, Length(LName) - 1);
end;

class function TMd2Parser.FrameGroupName(const AHead: TMd2FrameHead): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to MD2_FRAME_NAME_SIZE - 1 do
  begin
    if AHead.Name[LIndex] = #0 then
      Break;
    Result := Result + Char(Ord(AHead.Name[LIndex]));
  end;
  Result := GroupNameOf(Result);
end;

function TMd2Parser.Parse(const ABytes: TBytes; const APlacement: TModelPlacement): IMd2Model;
var
  LHeader: TMd2Header;
  LTexturePoints: TArray<TMd2TexturePoint>;
  LTriangles: TArray<TMd2Triangle>;
  LFrameHead: TMd2FrameHead;
  LFrames: TArray<TArray<TModelVertex>>;
  LTexCoords: TArray<TModelTexCoord>;
  LGroupNames: TArray<string>;
  LPositions: TArray<TModelVertex>;
  LVertex: TModelVertex;
  LVertexBytes: array[0..2] of Byte;
  LFrameOffset: Int64;
  LFrame, LTriangle, LCorner, LPoint, LTexIndex: Integer;
  LTarget: Integer;
  LByteIndex: Integer;
begin
  if Length(ABytes) < MD2_HEADER_SIZE then
    raise EModelsException.CreateFmt(SModelsMd2TooShort, [Length(ABytes)]);
  Move(ABytes[0], LHeader, MD2_HEADER_SIZE);

  if LHeader.Ident <> MD2_MAGIC then
    raise EModelsException.CreateFmt(SModelsMd2InvalidMagic, [LHeader.Ident]);

  if (LHeader.SkinWidth <= 0) or (LHeader.SkinHeight <= 0) or (LHeader.VertexCount < 0) or
    (LHeader.TexturePointCount < 0) or (LHeader.TriangleCount < 0) or (LHeader.FrameCount < 0) then
    raise EModelsException.CreateFmt(SModelsMd2InvalidCounts, [LHeader.SkinWidth,
      LHeader.SkinHeight, LHeader.VertexCount, LHeader.TexturePointCount, LHeader.TriangleCount,
      LHeader.FrameCount]);
  if LHeader.FrameCount = 0 then
    raise EModelsException.Create(SModelsMd2NoFrames);
  if Int64(LHeader.FrameSize) < MD2_FRAME_HEAD_SIZE + Int64(LHeader.VertexCount) * MD2_VERTEX_SIZE then
    raise EModelsException.CreateFmt(SModelsMd2InvalidFrameSize, [LHeader.FrameSize,
      LHeader.VertexCount]);

  CheckRange('the texture points', LHeader.TexturePointsOffset,
    Int64(LHeader.TexturePointCount) * MD2_TEXTURE_POINT_SIZE, Length(ABytes));
  CheckRange('the triangles', LHeader.TrianglesOffset,
    Int64(LHeader.TriangleCount) * MD2_TRIANGLE_SIZE, Length(ABytes));
  CheckRange('the frames', LHeader.FramesOffset,
    Int64(LHeader.FrameCount) * LHeader.FrameSize, Length(ABytes));

  SetLength(LTexturePoints, LHeader.TexturePointCount);
  if LHeader.TexturePointCount > 0 then
    Move(ABytes[LHeader.TexturePointsOffset], LTexturePoints[0],
      LHeader.TexturePointCount * MD2_TEXTURE_POINT_SIZE);
  SetLength(LTriangles, LHeader.TriangleCount);
  if LHeader.TriangleCount > 0 then
    Move(ABytes[LHeader.TrianglesOffset], LTriangles[0], LHeader.TriangleCount * MD2_TRIANGLE_SIZE);

  for LTriangle := 0 to LHeader.TriangleCount - 1 do
    for LCorner := 0 to 2 do
    begin
      if (LTriangles[LTriangle].VertexIndex[LCorner] < 0) or
        (LTriangles[LTriangle].VertexIndex[LCorner] >= LHeader.VertexCount) then
        raise EModelsException.CreateFmt(SModelsMd2InvalidIndex,
          [LTriangle, 'vertex', LTriangles[LTriangle].VertexIndex[LCorner]]);
      if (LTriangles[LTriangle].TexturePointIndex[LCorner] < 0) or
        (LTriangles[LTriangle].TexturePointIndex[LCorner] >= LHeader.TexturePointCount) then
        raise EModelsException.CreateFmt(SModelsMd2InvalidIndex,
          [LTriangle, 'texture point', LTriangles[LTriangle].TexturePointIndex[LCorner]]);
    end;

  // the texture points of the triangles, in the corner order of the renderer (2, 1, 0): they are
  // the same for all the frames
  SetLength(LTexCoords, LHeader.TriangleCount * 3);
  LTarget := 0;
  for LTriangle := 0 to LHeader.TriangleCount - 1 do
    for LCorner := 2 downto 0 do
    begin
      LTexIndex := LTriangles[LTriangle].TexturePointIndex[LCorner];
      LTexCoords[LTarget].U := LTexturePoints[LTexIndex].S / LHeader.SkinWidth;
      LTexCoords[LTarget].V := LTexturePoints[LTexIndex].T / LHeader.SkinHeight;
      Inc(LTarget);
    end;

  SetLength(LFrames, LHeader.FrameCount);
  SetLength(LGroupNames, LHeader.FrameCount);
  SetLength(LPositions, LHeader.VertexCount);
  for LFrame := 0 to LHeader.FrameCount - 1 do
  begin
    LFrameOffset := Int64(LHeader.FramesOffset) + Int64(LFrame) * LHeader.FrameSize;
    Move(ABytes[LFrameOffset], LFrameHead, MD2_FRAME_HEAD_SIZE);
    LGroupNames[LFrame] := FrameGroupName(LFrameHead);

    // the position of every vertex of the file: the byte of each axis, the scale and the
    // translation of the frame, then the scale and the offset of the placement
    for LPoint := 0 to LHeader.VertexCount - 1 do
    begin
      LByteIndex := Integer(LFrameOffset) + MD2_FRAME_HEAD_SIZE + LPoint * MD2_VERTEX_SIZE;
      LVertexBytes[0] := ABytes[LByteIndex];
      LVertexBytes[1] := ABytes[LByteIndex + 1];
      LVertexBytes[2] := ABytes[LByteIndex + 2];
      // Double: the 32 bit FPU keeps the intermediate values of this Single expression with more bits, and the 64 bit
      // compiler rounds each one to Single (another last bit): with Double the same Single comes out on both
      LPositions[LPoint].X := (Double(LVertexBytes[0]) * LFrameHead.Scale[0] + LFrameHead.Translate[0]) * APlacement.ScaleX + APlacement.OffsetX;
      LPositions[LPoint].Y := (Double(LVertexBytes[1]) * LFrameHead.Scale[1] + LFrameHead.Translate[1]) * APlacement.ScaleY + APlacement.OffsetY;
      LPositions[LPoint].Z := (Double(LVertexBytes[2]) * LFrameHead.Scale[2] + LFrameHead.Translate[2]) * APlacement.ScaleZ + APlacement.OffsetZ;
    end;

    // the vertexes of the triangles: the corner order is 2, 1, 0 and the axes are those of
    // the renderer (y, z, x)
    SetLength(LFrames[LFrame], LHeader.TriangleCount * 3);
    LTarget := 0;
    for LTriangle := 0 to LHeader.TriangleCount - 1 do
      for LCorner := 2 downto 0 do
      begin
        LVertex := LPositions[LTriangles[LTriangle].VertexIndex[LCorner]];
        LFrames[LFrame][LTarget].X := LVertex.Y;
        LFrames[LFrame][LTarget].Y := LVertex.Z;
        LFrames[LFrame][LTarget].Z := LVertex.X;
        Inc(LTarget);
      end;
  end;

  Result := TMd2Model.Create(LFrames, LTexCoords, LGroupNames);
end;

end.
