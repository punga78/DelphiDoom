{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - an I3D model as batches of triangles        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.MeshBuilder;

interface

uses
  DelphiDoom.Models.Intf,
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

const
  /// <summary>The primitives that become triangles: the numbers of GL_TRIANGLES ... GL_POLYGON</summary>
  I3D_MESH_TRIANGLES = 4;
  I3D_MESH_TRIANGLE_STRIP = 5;
  I3D_MESH_TRIANGLE_FAN = 6;
  I3D_MESH_QUADS = 7;
  I3D_MESH_POLYGON = 9;

type
  /// <summary>
  ///   The render target that does the work of the fixed pipeline on the vertexes: it keeps the
  ///   stack of matrices (translations, rotations in degrees, scales, as glTranslatef, glRotatef
  ///   and glScalef compose them), turns fans, strips, quads and polygons into triangles and puts
  ///   them in the batch of their texture and color. One matrix stack: MatrixMode is not kept
  ///   (the models only move the model view). The normals are not kept: an I3D model is drawn
  ///   without lighting. Lines and points are not kept.
  /// </summary>
  TI3dMeshBuilder = class(TInterfacedObject, IModelRenderer, II3dRenderTarget, II3dMeshBuilder)
  strict private
    type
      TMatrix = array[0..3, 0..3] of Single;
    var
      FBatches: TArray<TI3dMeshBatch>;
      FMatrix: TMatrix;
      FStack: TArray<TMatrix>;
      FPrimitive: TArray<TI3dMeshVertex>;
      FPrimitiveCount: Integer;
      FMode: Integer;
      FInPrimitive: Boolean;
      FTexturing: Boolean;
      FTextureIndex: Integer;
      FRed: Single;
      FGreen: Single;
      FBlue: Single;
      FAlpha: Single;
      FU: Single;
      FV: Single;
    class function Identity: TMatrix; static;
    procedure Multiply(const AOther: TMatrix);
    function CurrentBatch: Integer;
    procedure AddTriangle(ABatch, AFirst, ASecond, AThird: Integer);
  public
    constructor Create;
    // IModelRenderer
    procedure BeginPrimitive(const AMode: Integer);
    procedure EndPrimitive;
    procedure TexCoord2f(const AU, AV: Single);
    procedure Vertex3f(const AX, AY, AZ: Single);
    procedure Color3f(const AR, AG, AB: Single);
    procedure Color4f(const AR, AG, AB, AA: Single);
    procedure Normal3f(const ANX, ANY, ANZ: Single);
    procedure MatrixMode(const AMode: Integer);
    procedure PushMatrix;
    procedure PopMatrix;
    procedure Translatef(const AX, AY, AZ: Single);
    procedure Rotatef(const AAngle, AX, AY, AZ: Single);
    procedure LoadIdentity;
    procedure Scalef(const AX, AY, AZ: Single);
    // II3dRenderTarget
    procedure SetTexturing(const AEnabled: Boolean);
    procedure BindTexture(const ATextureIndex: Integer);
    procedure ResetTextureCache;
    // II3dMeshBuilder
    function GetBatchCount: Integer;
    function GetBatch(const AIndex: Integer): TI3dMeshBatch;
    function GetTriangleCount: Integer;
    procedure Clear;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  DelphiDoom.Models.Types;

const
  NO_TEXTURE = -1;

{ TI3dMeshBuilder }

constructor TI3dMeshBuilder.Create;
begin
  inherited Create;
  Clear;
end;

class function TI3dMeshBuilder.Identity: TMatrix;
var
  LRow: Integer;
  LColumn: Integer;
begin
  for LRow := 0 to 3 do
    for LColumn := 0 to 3 do
      if LRow = LColumn then
        Result[LRow, LColumn] := 1.0
      else
        Result[LRow, LColumn] := 0.0;
end;

procedure TI3dMeshBuilder.Multiply(const AOther: TMatrix);
var
  LResult: TMatrix;
  LRow: Integer;
  LColumn: Integer;
begin
  // as OpenGL does: the new transformation is applied to the vertex before the ones already there
  for LRow := 0 to 3 do
    for LColumn := 0 to 3 do
      LResult[LRow, LColumn] :=
        FMatrix[LRow, 0] * AOther[0, LColumn] + FMatrix[LRow, 1] * AOther[1, LColumn] +
        FMatrix[LRow, 2] * AOther[2, LColumn] + FMatrix[LRow, 3] * AOther[3, LColumn];
  FMatrix := LResult;
end;

function TI3dMeshBuilder.CurrentBatch: Integer;
var
  LIndex: Integer;
  LTexture: Integer;
begin
  if FTexturing then
    LTexture := FTextureIndex
  else
    LTexture := NO_TEXTURE;
  for LIndex := 0 to High(FBatches) do
  begin
    if (FBatches[LIndex].Textured = FTexturing) and (FBatches[LIndex].TextureIndex = LTexture) and
       (FBatches[LIndex].Red = FRed) and (FBatches[LIndex].Green = FGreen) and
       (FBatches[LIndex].Blue = FBlue) and (FBatches[LIndex].Alpha = FAlpha) then
      Exit(LIndex);
  end;
  Result := Length(FBatches);
  SetLength(FBatches, Result + 1);
  FBatches[Result].Textured := FTexturing;
  FBatches[Result].TextureIndex := LTexture;
  FBatches[Result].Red := FRed;
  FBatches[Result].Green := FGreen;
  FBatches[Result].Blue := FBlue;
  FBatches[Result].Alpha := FAlpha;
  FBatches[Result].Vertices := nil;
end;

procedure TI3dMeshBuilder.AddTriangle(ABatch, AFirst, ASecond, AThird: Integer);
var
  LCount: Integer;
begin
  LCount := Length(FBatches[ABatch].Vertices);
  SetLength(FBatches[ABatch].Vertices, LCount + 3);
  FBatches[ABatch].Vertices[LCount] := FPrimitive[AFirst];
  FBatches[ABatch].Vertices[LCount + 1] := FPrimitive[ASecond];
  FBatches[ABatch].Vertices[LCount + 2] := FPrimitive[AThird];
end;

procedure TI3dMeshBuilder.BeginPrimitive(const AMode: Integer);
begin
  FMode := AMode;
  FPrimitiveCount := 0;
  FInPrimitive := True;
end;

procedure TI3dMeshBuilder.EndPrimitive;
var
  LBatch: Integer;
  LIndex: Integer;
begin
  if not FInPrimitive then
    Exit;
  FInPrimitive := False;
  if FPrimitiveCount < 3 then
    Exit;
  if not (FMode in [I3D_MESH_TRIANGLES, I3D_MESH_TRIANGLE_STRIP, I3D_MESH_TRIANGLE_FAN,
    I3D_MESH_QUADS, I3D_MESH_POLYGON]) then
    Exit;
  LBatch := CurrentBatch;
  case FMode of
    I3D_MESH_TRIANGLES:
      begin
        LIndex := 0;
        while LIndex + 2 < FPrimitiveCount do
        begin
          AddTriangle(LBatch, LIndex, LIndex + 1, LIndex + 2);
          Inc(LIndex, 3);
        end;
      end;
    I3D_MESH_TRIANGLE_STRIP:
      for LIndex := 0 to FPrimitiveCount - 3 do
      begin
        // every other triangle of a strip is turned, so that all face the same way
        if Odd(LIndex) then
          AddTriangle(LBatch, LIndex + 1, LIndex, LIndex + 2)
        else
          AddTriangle(LBatch, LIndex, LIndex + 1, LIndex + 2);
      end;
    I3D_MESH_QUADS:
      begin
        LIndex := 0;
        while LIndex + 3 < FPrimitiveCount do
        begin
          AddTriangle(LBatch, LIndex, LIndex + 1, LIndex + 2);
          AddTriangle(LBatch, LIndex, LIndex + 2, LIndex + 3);
          Inc(LIndex, 4);
        end;
      end;
  else
    // a fan and a convex polygon: every triangle starts at the first vertex
    for LIndex := 1 to FPrimitiveCount - 2 do
      AddTriangle(LBatch, 0, LIndex, LIndex + 1);
  end;
end;

procedure TI3dMeshBuilder.TexCoord2f(const AU, AV: Single);
begin
  FU := AU;
  FV := AV;
end;

procedure TI3dMeshBuilder.Vertex3f(const AX, AY, AZ: Single);
begin
  if not FInPrimitive then
    Exit;
  if FPrimitiveCount = Length(FPrimitive) then
    SetLength(FPrimitive, FPrimitiveCount * 2 + 8);
  FPrimitive[FPrimitiveCount].X :=
    FMatrix[0, 0] * AX + FMatrix[0, 1] * AY + FMatrix[0, 2] * AZ + FMatrix[0, 3];
  FPrimitive[FPrimitiveCount].Y :=
    FMatrix[1, 0] * AX + FMatrix[1, 1] * AY + FMatrix[1, 2] * AZ + FMatrix[1, 3];
  FPrimitive[FPrimitiveCount].Z :=
    FMatrix[2, 0] * AX + FMatrix[2, 1] * AY + FMatrix[2, 2] * AZ + FMatrix[2, 3];
  FPrimitive[FPrimitiveCount].U := FU;
  FPrimitive[FPrimitiveCount].V := FV;
  Inc(FPrimitiveCount);
end;

procedure TI3dMeshBuilder.Color3f(const AR, AG, AB: Single);
begin
  Color4f(AR, AG, AB, 1.0);
end;

procedure TI3dMeshBuilder.Color4f(const AR, AG, AB, AA: Single);
begin
  FRed := AR;
  FGreen := AG;
  FBlue := AB;
  FAlpha := AA;
end;

procedure TI3dMeshBuilder.Normal3f(const ANX, ANY, ANZ: Single);
begin
  // not kept: see the summary of the class
end;

procedure TI3dMeshBuilder.MatrixMode(const AMode: Integer);
begin
  // one stack: see the summary of the class
end;

procedure TI3dMeshBuilder.PushMatrix;
begin
  SetLength(FStack, Length(FStack) + 1);
  FStack[High(FStack)] := FMatrix;
end;

procedure TI3dMeshBuilder.PopMatrix;
begin
  if Length(FStack) = 0 then
    raise EModelsException.Create(SModelsI3dMeshStackEmpty);
  FMatrix := FStack[High(FStack)];
  SetLength(FStack, Length(FStack) - 1);
end;

procedure TI3dMeshBuilder.Translatef(const AX, AY, AZ: Single);
var
  LMatrix: TMatrix;
begin
  LMatrix := Identity;
  LMatrix[0, 3] := AX;
  LMatrix[1, 3] := AY;
  LMatrix[2, 3] := AZ;
  Multiply(LMatrix);
end;

procedure TI3dMeshBuilder.Rotatef(const AAngle, AX, AY, AZ: Single);
var
  LMatrix: TMatrix;
  LLength: Double;
  LX: Double;
  LY: Double;
  LZ: Double;
  LSine: Double;
  LCosine: Double;
  LRest: Double;
begin
  LLength := Sqrt(AX * AX + AY * AY + AZ * AZ);
  // glRotatef with a null axis changes nothing
  if LLength = 0.0 then
    Exit;
  LX := AX / LLength;
  LY := AY / LLength;
  LZ := AZ / LLength;
  LSine := Sin(DegToRad(Double(AAngle)));
  LCosine := Cos(DegToRad(Double(AAngle)));
  LRest := 1.0 - LCosine;
  LMatrix := Identity;
  LMatrix[0, 0] := LX * LX * LRest + LCosine;
  LMatrix[0, 1] := LX * LY * LRest - LZ * LSine;
  LMatrix[0, 2] := LX * LZ * LRest + LY * LSine;
  LMatrix[1, 0] := LY * LX * LRest + LZ * LSine;
  LMatrix[1, 1] := LY * LY * LRest + LCosine;
  LMatrix[1, 2] := LY * LZ * LRest - LX * LSine;
  LMatrix[2, 0] := LZ * LX * LRest - LY * LSine;
  LMatrix[2, 1] := LZ * LY * LRest + LX * LSine;
  LMatrix[2, 2] := LZ * LZ * LRest + LCosine;
  Multiply(LMatrix);
end;

procedure TI3dMeshBuilder.LoadIdentity;
begin
  FMatrix := Identity;
end;

procedure TI3dMeshBuilder.Scalef(const AX, AY, AZ: Single);
var
  LMatrix: TMatrix;
begin
  LMatrix := Identity;
  LMatrix[0, 0] := AX;
  LMatrix[1, 1] := AY;
  LMatrix[2, 2] := AZ;
  Multiply(LMatrix);
end;

procedure TI3dMeshBuilder.SetTexturing(const AEnabled: Boolean);
begin
  FTexturing := AEnabled;
end;

procedure TI3dMeshBuilder.BindTexture(const ATextureIndex: Integer);
begin
  FTextureIndex := ATextureIndex;
end;

procedure TI3dMeshBuilder.ResetTextureCache;
begin
  FTextureIndex := NO_TEXTURE;
end;

function TI3dMeshBuilder.GetBatchCount: Integer;
begin
  Result := Length(FBatches);
end;

function TI3dMeshBuilder.GetBatch(const AIndex: Integer): TI3dMeshBatch;
begin
  if (AIndex < 0) or (AIndex >= Length(FBatches)) then
    raise EModelsException.CreateFmt(SModelsI3dInvalidIndex, [AIndex]);
  Result := FBatches[AIndex];
end;

function TI3dMeshBuilder.GetTriangleCount: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FBatches) do
    Inc(Result, Length(FBatches[LIndex].Vertices) div 3);
end;

procedure TI3dMeshBuilder.Clear;
begin
  FBatches := nil;
  FStack := nil;
  FMatrix := Identity;
  FPrimitiveCount := 0;
  FInPrimitive := False;
  FMode := 0;
  FTexturing := False;
  FTextureIndex := NO_TEXTURE;
  FRed := 1.0;
  FGreen := 1.0;
  FBlue := 1.0;
  FAlpha := 1.0;
  FU := 0.0;
  FV := 0.0;
end;

end.
