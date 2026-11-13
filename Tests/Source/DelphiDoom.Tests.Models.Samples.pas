{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the files and series of test   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Samples;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Models.Types, DelphiDoom.Tests.Models.ExactSingle;

type
  /// <summary>The same inputs for the old code and the new one: xorshift32 with a fixed seed</summary>
  TModelsRandom = class
  private
    FState: Cardinal;
  public
    constructor Create(const ASeed: Cardinal);
    function NextCardinal: Cardinal;
    function NextSingle(const AMin, AMax: Double): Single;
    function NextInteger(const ARange: Integer): Integer;
  end;

  /// <summary>What a test builds in memory: MD2 files and series of commands</summary>
  TModelsSamples = class
  public
    /// <summary>
    ///   A valid MD2 file with the standard layout of Quake 2 (header, skins, texture points,
    ///   triangles, frames, GL commands). The frames get the names in order (the last name
    ///   repeats if there are fewer names than frames).
    /// </summary>
    class function BuildMd2(const ARandom: TModelsRandom; const ATriangles, AVertexes, AFrames,
      ATexturePoints, ASkinWidth, ASkinHeight: Integer; const ANames: array of string): TBytes; static;
    /// <summary>The placement of a model: the offsets and the scales of the map units</summary>
    class function RandomPlacement(const ARandom: TModelsRandom): TModelPlacement; static;
    class function IdentityPlacement: TModelPlacement; static;
    /// <summary>The names of the frames that the tests use for the rule of the group name</summary>
    class function FrameNames: TArray<string>; static;
    /// <summary>
    ///   A random command for a procedural model (one of the 14 that draw or move, a frame
    ///   change or a call). The frames that a call or a change names for the first time come in
    ///   growing order (AMaxFrame is the biggest so far): this is the only way the list of frames
    ///   of the old code is right (see the notes in Tests\Data\Models\README.md).
    /// </summary>
    class procedure RandomCommand(const ARandom: TModelsRandom; var AMaxFrame: Integer;
      out ACommand: Integer; out AParam0, AParam1, AParam2, AParam3: Single); static;
  end;

implementation

{ TModelsRandom }

constructor TModelsRandom.Create(const ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
  if FState = 0 then
    FState := $9E3779B9;
end;

function TModelsRandom.NextCardinal: Cardinal;
begin
  FState := FState xor (FState shl 13);
  FState := FState xor (FState shr 17);
  FState := FState xor (FState shl 5);
  Result := FState;
end;

function TModelsRandom.NextSingle(const AMin, AMax: Double): Single;
begin
  // not a plain Double expression: the 32 bit FPU and the 64 bit one round it to another Single now
  // and then (one case of the series of the merges is one ULP off), see TModelsExactSingle
  Result := TModelsExactSingle.Interpolate(AMin, AMax, NextCardinal / 4294967296.0);
end;

function TModelsRandom.NextInteger(const ARange: Integer): Integer;
begin
  Result := Integer(NextCardinal mod Cardinal(ARange));
end;

{ TModelsSamples }

class function TModelsSamples.BuildMd2(const ARandom: TModelsRandom; const ATriangles, AVertexes,
  AFrames, ATexturePoints, ASkinWidth, ASkinHeight: Integer;
  const ANames: array of string): TBytes;
var
  LHeader: TMd2Header;
  LTexturePoint: TMd2TexturePoint;
  LTriangle: TMd2Triangle;
  LFrameHead: TMd2FrameHead;
  LFrameSize, LPosition, LFrame, LIndex, LNameIndex, LCorner: Integer;
  LVertexBytes: array[0..3] of Byte;
  LName: AnsiString;
begin
  LFrameSize := MD2_FRAME_HEAD_SIZE + AVertexes * MD2_VERTEX_SIZE;
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Ident := MD2_MAGIC;
  LHeader.Version := 8;
  LHeader.SkinWidth := ASkinWidth;
  LHeader.SkinHeight := ASkinHeight;
  LHeader.FrameSize := LFrameSize;
  LHeader.SkinCount := 0;
  LHeader.VertexCount := AVertexes;
  LHeader.TexturePointCount := ATexturePoints;
  LHeader.TriangleCount := ATriangles;
  LHeader.GlCommandCount := 0;
  LHeader.FrameCount := AFrames;
  LHeader.SkinsOffset := MD2_HEADER_SIZE;
  LHeader.TexturePointsOffset := LHeader.SkinsOffset;
  LHeader.TrianglesOffset := LHeader.TexturePointsOffset + ATexturePoints * MD2_TEXTURE_POINT_SIZE;
  LHeader.FramesOffset := LHeader.TrianglesOffset + ATriangles * MD2_TRIANGLE_SIZE;
  LHeader.GlCommandsOffset := LHeader.FramesOffset + AFrames * LFrameSize;
  LHeader.EndOffset := LHeader.GlCommandsOffset;

  SetLength(Result, LHeader.EndOffset);
  Move(LHeader, Result[0], MD2_HEADER_SIZE);
  LPosition := LHeader.TexturePointsOffset;
  for LIndex := 0 to ATexturePoints - 1 do
  begin
    LTexturePoint.S := ARandom.NextInteger(ASkinWidth + 1);
    LTexturePoint.T := ARandom.NextInteger(ASkinHeight + 1);
    Move(LTexturePoint, Result[LPosition], MD2_TEXTURE_POINT_SIZE);
    Inc(LPosition, MD2_TEXTURE_POINT_SIZE);
  end;
  for LIndex := 0 to ATriangles - 1 do
  begin
    for LCorner := 0 to 2 do
    begin
      LTriangle.VertexIndex[LCorner] := ARandom.NextInteger(AVertexes);
      LTriangle.TexturePointIndex[LCorner] := ARandom.NextInteger(ATexturePoints);
    end;
    Move(LTriangle, Result[LPosition], MD2_TRIANGLE_SIZE);
    Inc(LPosition, MD2_TRIANGLE_SIZE);
  end;
  for LFrame := 0 to AFrames - 1 do
  begin
    FillChar(LFrameHead, SizeOf(LFrameHead), 0);
    for LIndex := 0 to 2 do
    begin
      LFrameHead.Scale[LIndex] := ARandom.NextSingle(0.01, 0.5);
      LFrameHead.Translate[LIndex] := ARandom.NextSingle(-40, 40);
    end;
    LNameIndex := LFrame;
    if LNameIndex > High(ANames) then
      LNameIndex := High(ANames);
    LName := AnsiString(ANames[LNameIndex]);
    for LIndex := 1 to Length(LName) do
      if LIndex <= MD2_FRAME_NAME_SIZE then
        LFrameHead.Name[LIndex - 1] := LName[LIndex];
    Move(LFrameHead, Result[LPosition], MD2_FRAME_HEAD_SIZE);
    Inc(LPosition, MD2_FRAME_HEAD_SIZE);
    for LIndex := 0 to AVertexes - 1 do
    begin
      LVertexBytes[0] := ARandom.NextInteger(256);
      LVertexBytes[1] := ARandom.NextInteger(256);
      LVertexBytes[2] := ARandom.NextInteger(256);
      LVertexBytes[3] := ARandom.NextInteger(162);
      Move(LVertexBytes, Result[LPosition], MD2_VERTEX_SIZE);
      Inc(LPosition, MD2_VERTEX_SIZE);
    end;
  end;
end;

class function TModelsSamples.RandomPlacement(const ARandom: TModelsRandom): TModelPlacement;
begin
  // as the renderer does: the offsets and scales of MODELDEF divided by 128
  Result.OffsetX := ARandom.NextSingle(-30, 30) / 128.0;
  Result.OffsetY := ARandom.NextSingle(-30, 30) / 128.0;
  Result.OffsetZ := ARandom.NextSingle(-30, 30) / 128.0;
  Result.ScaleX := ARandom.NextSingle(0.2, 3) / 128.0;
  Result.ScaleY := ARandom.NextSingle(0.2, 3) / 128.0;
  Result.ScaleZ := ARandom.NextSingle(0.2, 3) / 128.0;
end;

class function TModelsSamples.IdentityPlacement: TModelPlacement;
begin
  Result.OffsetX := 0;
  Result.OffsetY := 0;
  Result.OffsetZ := 0;
  Result.ScaleX := 1;
  Result.ScaleY := 1;
  Result.ScaleZ := 1;
end;

class function TModelsSamples.FrameNames: TArray<string>;
begin
  Result := TArray<string>.Create('', 'a', '5', 'ab', '12', 'a1', '1a', 'abc', 'a12', 'stand', 'stand1',
    'stand01', 'STAND12', 'run_03', ' pain1 ', '  ', 'walk 7', 'Attack10', 'death-1', 'x9', '99',
    'frame001', 'Idle', 'idle2', 'a'#9'b2', '0');
end;

class procedure TModelsSamples.RandomCommand(const ARandom: TModelsRandom; var AMaxFrame: Integer;
  out ACommand: Integer; out AParam0, AParam1, AParam2, AParam3: Single);
var
  LFrame: Integer;
begin
  AParam0 := 0;
  AParam1 := 0;
  AParam2 := 0;
  AParam3 := 0;
  ACommand := ARandom.NextInteger(MODEL_CMD_CALLFRAME + 1);
  case ACommand of
    MODEL_CMD_BEGIN, MODEL_CMD_MATRIXMODE:
      AParam0 := ARandom.NextInteger(10);
    MODEL_CMD_CALLFRAME, MODEL_CMD_SETFRAME:
      begin
        LFrame := ARandom.NextInteger(AMaxFrame + 2);
        if LFrame > AMaxFrame then
          AMaxFrame := LFrame;
        AParam0 := LFrame;
      end;
  else
    begin
      AParam0 := ARandom.NextSingle(-5, 5);
      AParam1 := ARandom.NextSingle(-5, 5);
      AParam2 := ARandom.NextSingle(-5, 5);
      AParam3 := ARandom.NextSingle(-5, 5);
    end;
  end;
end;

end.
