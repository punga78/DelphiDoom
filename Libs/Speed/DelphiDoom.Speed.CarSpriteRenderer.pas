{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - a car as a picture seen from one side           }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The cars of Speed Haste are 3D models; the software renderer of the        }
{  engine draws sprites. This class draws a model (I3D) with the rasterizer    }
{  from one of the eight sides of a sprite of Doom                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.CarSpriteRenderer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Models.I3d.Intf, DelphiDoom.Models.I3d.Types,
  DelphiDoom.Speed.TriangleRasterizer;

const
  /// <summary>The number of sides of a sprite of Doom (the rotations 1..8)</summary>
  SPEED_SPRITE_ROTATIONS = 8;
  /// <summary>The color variants of a car: the permutations of red, green and blue</summary>
  SPEED_CAR_VARIANTS = 6;

type
  /// <summary>
  ///   Which axis of the model is the front, the left and the top of the car, and in which direction.
  ///   Axis 0, 1, 2 are X, Y, Z of the mesh; the sign is 1 or -1
  /// </summary>
  TSpeedModelAxes = record
    ForwardAxis: Integer;
    ForwardSign: Integer;
    LeftAxis: Integer;
    LeftSign: Integer;
    UpAxis: Integer;
    UpSign: Integer;
  end;

  /// <summary>
  ///   A picture of a car: Width x Height indexes of the palette of the game, row after row from the
  ///   top, and the pixel of the picture that sits on the point of the ground under the car
  /// </summary>
  TSpeedCarSpriteImage = record
    Width: Integer;
    Height: Integer;
    LeftOffset: Integer;
    TopOffset: Integer;
    Pixels: TBytes;
  end;

  TSpeedCarSpriteRenderer = class
  strict private
    FParser: II3dParser;
    FRenderer: II3dModelRenderer;
    FMesh: II3dMeshBuilder;
    FPlayPal: TBytes;
    FTransparent: Byte;
    FAxes: TSpeedModelAxes;
    FPixelsPerUnit: Single;
    FLength: Single;
    FFixedScale: Single;
    FPitch: Single;
    FModel: II3dModel;
    FColorMaps: array[0..SPEED_CAR_VARIANTS - 1] of TBytes;
    FShadeMaps: array[0..16] of TBytes;
    function NearestColor(ARed, AGreen, ABlue: Integer): Byte;
    procedure BuildColorMaps;
    procedure BuildShadeMaps(const AColorMap: TBytes);
    function ToLocal(const AVertex: TI3dMeshVertex): TArray<Single>;
  public
    /// <param name="APlayPal">The 768 bytes of the palette of the game</param>
    /// <param name="AColorMap">The 34 * 256 bytes of the COLORMAP of the game (the light levels)</param>
    /// <param name="ATransparent">The index that means "no pixel" in the pictures of the game</param>
    /// <param name="ALength">How many pixels long the car is at the end (the longest side of the model)</param>
    /// <param name="APitch">How high the eye looks from, in degrees over the horizon</param>
    /// <exception cref="EArgumentNilException">A service is nil</exception>
    /// <exception cref="EArgumentException">A palette is too short</exception>
    constructor Create(const AParser: II3dParser; const ARenderer: II3dModelRenderer;
      const AMesh: II3dMeshBuilder; const APlayPal, AColorMap: TBytes; ATransparent: Byte;
      const AAxes: TSpeedModelAxes; ALength, APitch: Single);
    /// <summary>Loads a model: the next pictures are of it</summary>
    /// <exception cref="EModelsException">The file is not a model</exception>
    procedure Load(const AModelBytes: TBytes);
    /// <summary>
    ///   The picture of the loaded car seen as the rotation 1..8 of a sprite of Doom (1: the car comes
    ///   at the viewer, 5: it goes away, counterclockwise) with the colors of a variant (0..5)
    /// </summary>
    function Render(ARotation, AVariant: Integer): TSpeedCarSpriteImage;
    /// <summary>The longest side of the loaded model in the units of its mesh (to find the axes)</summary>
    function Extent(AAxis: Integer; out AMinimum, AMaximum: Single): Boolean;
    /// <summary>Pixels for each unit of the mesh when the picture keeps the size of the model (0: the length of the car is fixed)</summary>
    property FixedScale: Single read FFixedScale write FFixedScale;
    /// <summary>The pixels for each unit of the mesh that the last picture used</summary>
    property PixelsPerMeshUnit: Single read FPixelsPerUnit;
  end;

implementation

uses
  System.Math, DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Palette;

resourcestring
  SSpeedCarPalette = 'The palette of the cars has %d bytes, %d are needed';
  SSpeedCarNoModel = 'No model is loaded in the renderer of the cars';

const
  PALETTE_SIZE = 768;
  // the colors of the palette of the game that a picture may use (the others are for the engine)
  PALETTE_LOW = 16;
  PALETTE_HIGH = 239;
  COLORMAP_ROW_SIZE = 256;
  SHADE_LEVELS = 16;
  AMBIENT_LIGHT = 0.55;
  PADDING = 2;
  TRANSLUCENT_LIMIT = 0.99;
  // a patch is at most 255 rows high
  MAX_PICTURE_PIXELS = 170;
  // the direction of the light in the axes of the car: front, left, up
  LIGHT_FRONT = 0.35;
  LIGHT_LEFT = 0.35;
  LIGHT_UP = 0.85;

{ TSpeedCarSpriteRenderer }

constructor TSpeedCarSpriteRenderer.Create(const AParser: II3dParser; const ARenderer: II3dModelRenderer;
  const AMesh: II3dMeshBuilder; const APlayPal, AColorMap: TBytes; ATransparent: Byte;
  const AAxes: TSpeedModelAxes; ALength, APitch: Single);
begin
  inherited Create;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer');
  if not Assigned(AMesh) then
    raise EArgumentNilException.Create('AMesh');
  if Length(APlayPal) < PALETTE_SIZE then
    raise EArgumentException.CreateFmt(SSpeedCarPalette, [Length(APlayPal), PALETTE_SIZE]);
  if Length(AColorMap) < (SHADE_LEVELS + 1) * COLORMAP_ROW_SIZE then
    raise EArgumentException.CreateFmt(SSpeedCarPalette, [Length(AColorMap), (SHADE_LEVELS + 1) * COLORMAP_ROW_SIZE]);
  FParser := AParser;
  FRenderer := ARenderer;
  FMesh := AMesh;
  FPlayPal := Copy(APlayPal, 0, PALETTE_SIZE);
  FTransparent := ATransparent;
  FAxes := AAxes;
  FLength := ALength;
  FPitch := APitch * Pi / 180;
  BuildColorMaps;
  BuildShadeMaps(AColorMap);
end;

function TSpeedCarSpriteRenderer.NearestColor(ARed, AGreen, ABlue: Integer): Byte;
var
  LIndex, LDistance, LBest: Integer;
begin
  Result := PALETTE_LOW;
  LBest := MaxInt;
  for LIndex := PALETTE_LOW to PALETTE_HIGH do
  begin
    if LIndex = FTransparent then
      Continue;
    LDistance := Sqr(ARed - FPlayPal[LIndex * 3]) + Sqr(AGreen - FPlayPal[LIndex * 3 + 1]) +
      Sqr(ABlue - FPlayPal[LIndex * 3 + 2]);
    if LDistance < LBest then
    begin
      LBest := LDistance;
      Result := LIndex;
      if LDistance = 0 then
        Exit;
    end;
  end;
end;

procedure TSpeedCarSpriteRenderer.BuildColorMaps;
var
  LVariant, LIndex: Integer;
  LColor: Cardinal;
  LChannels: array[0..2] of Integer;
  LOut: array[0..2] of Integer;
const
  // which source channel goes to red, green and blue for each variant
  PERMUTATIONS: array[0..SPEED_CAR_VARIANTS - 1, 0..2] of Integer = (
    (0, 1, 2), (2, 1, 0), (1, 0, 2), (0, 2, 1), (1, 2, 0), (2, 0, 1));
begin
  for LVariant := 0 to SPEED_CAR_VARIANTS - 1 do
  begin
    SetLength(FColorMaps[LVariant], 256);
    for LIndex := 0 to 255 do
    begin
      LColor := TI3dPalette.ColorLong(Byte(LIndex));
      LChannels[0] := LColor and $FF;
      LChannels[1] := (LColor shr 8) and $FF;
      LChannels[2] := (LColor shr 16) and $FF;
      LOut[0] := LChannels[PERMUTATIONS[LVariant, 0]];
      LOut[1] := LChannels[PERMUTATIONS[LVariant, 1]];
      LOut[2] := LChannels[PERMUTATIONS[LVariant, 2]];
      FColorMaps[LVariant][LIndex] := NearestColor(LOut[0], LOut[1], LOut[2]);
    end;
  end;
end;

procedure TSpeedCarSpriteRenderer.BuildShadeMaps(const AColorMap: TBytes);
var
  LLevel: Integer;
begin
  for LLevel := 0 to SHADE_LEVELS do
    FShadeMaps[LLevel] := Copy(AColorMap, LLevel * COLORMAP_ROW_SIZE, COLORMAP_ROW_SIZE);
end;

procedure TSpeedCarSpriteRenderer.Load(const AModelBytes: TBytes);
var
  LPlacement: TModelPlacement;
  LTires: TI3dTireState;
begin
  FModel := FParser.Parse(AModelBytes);
  FMesh.Clear;
  LPlacement := Default(TModelPlacement);
  LPlacement.ScaleX := 1.0;
  LPlacement.ScaleY := 1.0;
  LPlacement.ScaleZ := 1.0;
  LTires := Default(TI3dTireState);
  FRenderer.Render(FModel, FMesh, LPlacement, -1, LTires);
end;

function TSpeedCarSpriteRenderer.Extent(AAxis: Integer; out AMinimum, AMaximum: Single): Boolean;
var
  LBatch, LVertex: Integer;
  LValue: Single;
begin
  Result := False;
  AMinimum := MaxSingle;
  AMaximum := -MaxSingle;
  if FMesh = nil then
    Exit;
  for LBatch := 0 to FMesh.BatchCount - 1 do
    for LVertex := 0 to High(FMesh.Batches[LBatch].Vertices) do
    begin
      case AAxis of
        0: LValue := FMesh.Batches[LBatch].Vertices[LVertex].X;
        1: LValue := FMesh.Batches[LBatch].Vertices[LVertex].Y;
      else
        LValue := FMesh.Batches[LBatch].Vertices[LVertex].Z;
      end;
      AMinimum := Min(AMinimum, LValue);
      AMaximum := Max(AMaximum, LValue);
      Result := True;
    end;
end;

function TSpeedCarSpriteRenderer.ToLocal(const AVertex: TI3dMeshVertex): TArray<Single>;
var
  LSource: array[0..2] of Single;
begin
  LSource[0] := AVertex.X;
  LSource[1] := AVertex.Y;
  LSource[2] := AVertex.Z;
  SetLength(Result, 3);
  Result[0] := FAxes.ForwardSign * LSource[FAxes.ForwardAxis];
  Result[1] := FAxes.LeftSign * LSource[FAxes.LeftAxis];
  Result[2] := FAxes.UpSign * LSource[FAxes.UpAxis];
end;

function TSpeedCarSpriteRenderer.Render(ARotation, AVariant: Integer): TSpeedCarSpriteImage;
type
  TVector = array[0..2] of Single;
var
  LAngle, LCosPitch, LSinPitch: Single;
  LView, LRight, LScreenUp: TVector;
  LMinX, LMaxX, LMinY, LMaxY, LMinF, LMaxF, LMinL, LMaxL, LMinU, LMaxU, LLargest: Single;
  LScale: Single;
  LRasterizer: TSpeedTriangleRasterizer;
  LBatch, LVertex, LCorner, LLevel: Integer;
  LLocal: array of TVector;
  LRaster: array[0..2] of TSpeedRasterVertex;
  LTriangle: array[0..2] of TVector;
  LNormal: TVector;
  LLength, LShade, LFacing: Single;
  LBatchData: TI3dMeshBatch;
  LTexture: TI3dTexture;
  LFlatColor: Byte;
  LOriginX, LOriginY: Single;
  LColorMap: TBytes;

  function Cross(const P, Q: TVector): TVector;
  begin
    Result[0] := P[1] * Q[2] - P[2] * Q[1];
    Result[1] := P[2] * Q[0] - P[0] * Q[2];
    Result[2] := P[0] * Q[1] - P[1] * Q[0];
  end;

  function Subtract(const P, Q: TVector): TVector;
  begin
    Result[0] := P[0] - Q[0];
    Result[1] := P[1] - Q[1];
    Result[2] := P[2] - Q[2];
  end;

  function Dot(const P, Q: TVector): Single;
  begin
    Result := P[0] * Q[0] + P[1] * Q[1] + P[2] * Q[2];
  end;

  procedure Normalize(var P: TVector);
  var
    LNorm: Single;
  begin
    LNorm := Sqrt(Dot(P, P));
    if LNorm > 1E-9 then
    begin
      P[0] := P[0] / LNorm;
      P[1] := P[1] / LNorm;
      P[2] := P[2] / LNorm;
    end;
  end;

  function Project(const P: TVector): TSpeedRasterVertex;
  begin
    Result.X := LScale * Dot(P, LRight);
    Result.Y := -LScale * Dot(P, LScreenUp);
    Result.Depth := Dot(P, LView);
    Result.U := 0;
    Result.V := 0;
  end;

var
  LCar: TArray<Single>;
  LUp, LCamera: TVector;
begin
  if FModel = nil then
    raise EInvalidOpException.Create(SSpeedCarNoModel);
  if (AVariant < 0) or (AVariant >= SPEED_CAR_VARIANTS) then
    AVariant := 0;
  LColorMap := FColorMaps[AVariant];
  // the viewer is on the side ARotation-1 steps counterclockwise from the front of the car
  LAngle := (ARotation - 1) * Pi / 4;
  LCosPitch := Cos(FPitch);
  LSinPitch := Sin(FPitch);
  LUp[0] := 0; LUp[1] := 0; LUp[2] := 1;
  LCamera[0] := Cos(LAngle) * LCosPitch;
  LCamera[1] := Sin(LAngle) * LCosPitch;
  LCamera[2] := LSinPitch;
  LView[0] := -LCamera[0]; LView[1] := -LCamera[1]; LView[2] := -LCamera[2];
  LRight := Cross(LView, LUp);
  Normalize(LRight);
  LScreenUp := Cross(LRight, LView);
  Normalize(LScreenUp);

  // the car in its own axes, and how big it is
  LMinF := MaxSingle; LMaxF := -MaxSingle; LMinL := MaxSingle; LMaxL := -MaxSingle; LMinU := MaxSingle; LMaxU := -MaxSingle;
  for LBatch := 0 to FMesh.BatchCount - 1 do
    for LVertex := 0 to High(FMesh.Batches[LBatch].Vertices) do
    begin
      LCar := ToLocal(FMesh.Batches[LBatch].Vertices[LVertex]);
      LMinF := Min(LMinF, LCar[0]); LMaxF := Max(LMaxF, LCar[0]);
      LMinL := Min(LMinL, LCar[1]); LMaxL := Max(LMaxL, LCar[1]);
      LMinU := Min(LMinU, LCar[2]);
      LMaxU := Max(LMaxU, LCar[2]);
    end;
  if (LMaxF < LMinF) or ((FFixedScale <= 0) and (LMaxF = LMinF)) then
    raise EInvalidOpException.Create(SSpeedCarNoModel);
  if FFixedScale > 0 then
  begin
    // a scenery model: its own size, reduced when the picture would be taller than a patch can be
    FPixelsPerUnit := FFixedScale;
    LLargest := Max(LMaxF - LMinF, Max(LMaxL - LMinL, LMaxU - LMinU)) * FPixelsPerUnit;
    if LLargest > MAX_PICTURE_PIXELS then
      FPixelsPerUnit := FPixelsPerUnit * MAX_PICTURE_PIXELS / LLargest;
  end
  else
    FPixelsPerUnit := FLength / (LMaxF - LMinF);
  LScale := FPixelsPerUnit;
  // the center of the car on the ground is the origin

  // the bounds on the screen
  LMinX := MaxSingle; LMaxX := -MaxSingle; LMinY := MaxSingle; LMaxY := -MaxSingle;
  for LBatch := 0 to FMesh.BatchCount - 1 do
    for LVertex := 0 to High(FMesh.Batches[LBatch].Vertices) do
    begin
      LCar := ToLocal(FMesh.Batches[LBatch].Vertices[LVertex]);
      LTriangle[0][0] := LCar[0] - (LMinF + LMaxF) / 2;
      LTriangle[0][1] := LCar[1] - (LMinL + LMaxL) / 2;
      LTriangle[0][2] := LCar[2] - LMinU;
      LRaster[0] := Project(LTriangle[0]);
      LMinX := Min(LMinX, LRaster[0].X); LMaxX := Max(LMaxX, LRaster[0].X);
      LMinY := Min(LMinY, LRaster[0].Y); LMaxY := Max(LMaxY, LRaster[0].Y);
    end;
  // the point of the ground under the center of the car
  LTriangle[0][0] := 0; LTriangle[0][1] := 0; LTriangle[0][2] := 0;
  LRaster[0] := Project(LTriangle[0]);
  LOriginX := LRaster[0].X;
  LOriginY := LRaster[0].Y;
  LMinY := Min(LMinY, LOriginY);
  LMaxY := Max(LMaxY, LOriginY);

  Result.Width := Ceil(LMaxX - LMinX) + 2 * PADDING;
  Result.Height := Ceil(LMaxY - LMinY) + 2 * PADDING;
  Result.LeftOffset := Round(LOriginX - LMinX) + PADDING;
  Result.TopOffset := Round(LOriginY - LMinY) + PADDING;

  LRasterizer := TSpeedTriangleRasterizer.Create(Result.Width, Result.Height, FTransparent);
  try
    for LBatch := 0 to FMesh.BatchCount - 1 do
    begin
      LBatchData := FMesh.Batches[LBatch];
      // the shadow of the car under it is a translucent face: a picture on the ground draws its own
      if LBatchData.Alpha < TRANSLUCENT_LIMIT then
        Continue;
      if LBatchData.Textured and (LBatchData.TextureIndex >= 0) then
        LTexture := FModel.Textures[LBatchData.TextureIndex]
      else
        LTexture := Default(TI3dTexture);
      LFlatColor := NearestColor(Round(LBatchData.Red * 255), Round(LBatchData.Green * 255),
        Round(LBatchData.Blue * 255));
      LVertex := 0;
      while LVertex + 2 < Length(LBatchData.Vertices) do
      begin
        for LCorner := 0 to 2 do
        begin
          LCar := ToLocal(LBatchData.Vertices[LVertex + LCorner]);
          LTriangle[LCorner][0] := LCar[0] - (LMinF + LMaxF) / 2;
          LTriangle[LCorner][1] := LCar[1] - (LMinL + LMaxL) / 2;
          LTriangle[LCorner][2] := LCar[2] - LMinU;
          LRaster[LCorner] := Project(LTriangle[LCorner]);
          LRaster[LCorner].X := LRaster[LCorner].X - LMinX + PADDING;
          LRaster[LCorner].Y := LRaster[LCorner].Y - LMinY + PADDING;
          LRaster[LCorner].U := LBatchData.Vertices[LVertex + LCorner].U;
          LRaster[LCorner].V := LBatchData.Vertices[LVertex + LCorner].V;
        end;
        // the light: the side of the face that the viewer sees
        LNormal := Cross(Subtract(LTriangle[1], LTriangle[0]), Subtract(LTriangle[2], LTriangle[0]));
        Normalize(LNormal);
        LFacing := Dot(LNormal, LView);
        if LFacing > 0 then
        begin
          LNormal[0] := -LNormal[0]; LNormal[1] := -LNormal[1]; LNormal[2] := -LNormal[2];
        end;
        LLength := LNormal[0] * LIGHT_FRONT + LNormal[1] * LIGHT_LEFT + LNormal[2] * LIGHT_UP;
        LShade := AMBIENT_LIGHT + (1 - AMBIENT_LIGHT) * Max(0, LLength);
        LLevel := Round((1 - Min(1, LShade)) * SHADE_LEVELS);
        if LBatchData.Textured and (Length(LTexture.Pixels) > 0) then
          LRasterizer.DrawTextured(LRaster[0], LRaster[1], LRaster[2], LTexture.Pixels, LTexture.Width,
            LTexture.Height, LColorMap, FShadeMaps[LLevel])
        else
          LRasterizer.DrawFlat(LRaster[0], LRaster[1], LRaster[2], FShadeMaps[LLevel][LFlatColor]);
        Inc(LVertex, 3);
      end;
    end;
    Result.Pixels := Copy(LRasterizer.Pixels, 0, Length(LRasterizer.Pixels));
  finally
    LRasterizer.Free;
  end;
end;

end.
