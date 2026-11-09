{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the lines of an I3D model      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dDump;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Types, DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   The lines that describe a model in the golden files of the I3D reader: the numbers of the
  ///   header, a fingerprint of the faces, of the textures, the tires and three drawings. The
  ///   temporary harness that runs the old loader writes the same lines from its own objects.
  /// </summary>
  TI3dDump = class
  public
    class function Lines(const AName: string; const ALength: Integer;
      const AModel: II3dModel): TArray<string>; static;
    /// <summary>The placement of the three drawings: 0, 1 and 2</summary>
    class function Placement(const AVariant: Integer): TModelPlacement; static;
    class function Selected(const AVariant: Integer): Integer; static;
    class function Tires(const AVariant: Integer): TI3dTireState; static;
    /// <summary>
    ///   Corrections for a model of AFaceCount faces: vertexes of the first faces, of the tires
    ///   and of the last face, plus some that point outside the model (they must be ignored)
    /// </summary>
    class function SampleCorrections(const AFaceCount: Integer): TArray<TI3dCorrection>; static;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.Models.I3d.Factory, DelphiDoom.Tests.Models.Fingerprint, DelphiDoom.Tests.Models.I3dRecorder;

{ TI3dDump }

class function TI3dDump.Placement(const AVariant: Integer): TModelPlacement;
begin
  case AVariant of
    0:
      begin
        Result.ScaleX := 1.0;
        Result.ScaleY := 1.0;
        Result.ScaleZ := 1.0;
        Result.OffsetX := 0.0;
        Result.OffsetY := 0.0;
        Result.OffsetZ := 0.0;
      end;
    1:
      begin
        Result.ScaleX := 0.5;
        Result.ScaleY := 0.75;
        Result.ScaleZ := 1.25;
        Result.OffsetX := 1.0;
        Result.OffsetY := -2.0;
        Result.OffsetZ := 3.0;
      end;
  else
    Result.ScaleX := 0.015625;
    Result.ScaleY := 0.03125;
    Result.ScaleZ := 0.0625;
    Result.OffsetX := -10.5;
    Result.OffsetY := 20.25;
    Result.OffsetZ := 0.125;
  end;
end;

class function TI3dDump.Selected(const AVariant: Integer): Integer;
begin
  if AVariant = 1 then
    Result := 3
  else
    Result := -1;
end;

class function TI3dDump.Tires(const AVariant: Integer): TI3dTireState;
begin
  Result := Default(TI3dTireState);
  if AVariant = 2 then
  begin
    Result.Rotation[0] := 10.0;
    Result.Rotation[1] := 20.0;
    Result.Rotation[2] := 30.5;
    Result.Rotation[3] := 340.25;
    Result.Angle := 15.0;
  end;
end;

class function TI3dDump.SampleCorrections(const AFaceCount: Integer): TArray<TI3dCorrection>;
const
  FACES: array[0..9] of Integer = (0, 1, 5, 17, 40, 63, 64, -2, -3, -4);
var
  LIndex: Integer;
  LFace: Integer;
begin
  SetLength(Result, Length(FACES) + 2);
  for LIndex := 0 to High(Result) do
  begin
    if LIndex < Length(FACES) then
      LFace := FACES[LIndex]
    else
      LFace := AFaceCount - 1 + (LIndex - Length(FACES)) * 5;
    // -2 is the last face, -3 the first one after the end, -4 a negative number
    if LFace = -2 then
      LFace := AFaceCount - 1
    else if LFace = -3 then
      LFace := AFaceCount
    else if LFace = -4 then
      LFace := -1;
    Result[LIndex].Face := LFace;
    Result[LIndex].Vertex := LIndex mod 3;
    Result[LIndex].Visible := LIndex mod 4 <> 1;
    Result[LIndex].X := LIndex * 1000 + 1;
    Result[LIndex].Y := LIndex * -2000 + 2;
    Result[LIndex].Z := LIndex * 3000 + 3;
    Result[LIndex].TextureX := LIndex * 11;
    Result[LIndex].TextureY := LIndex * -13;
    Result[LIndex].Color := Byte(LIndex * 17 + 3);
  end;
end;

class function TI3dDump.Lines(const AName: string; const ALength: Integer;
  const AModel: II3dModel): TArray<string>;
var
  LList: TList<string>;
  LHeader: TI3dHeader;
  LFaces: TArray<TI3dFace>;
  LPrint: TFingerprint;
  LMaterial: TI3dMaterial;
  LFace, LCorner, LIndex, LVariant, LTriangles: Integer;
  LRecorder: TI3dRecorder;
  LTarget: II3dRenderTarget;
  LRenderer: II3dModelRenderer;
  LLine: string;
begin
  LList := TList<string>.Create;
  try
    LHeader := AModel.Header;
    LList.Add(Format('model %s bytes %d', [AName, ALength]));
    LList.Add(Format('header %d %d %d %d %d %d %d %d %d %d %d %d',
      [LHeader.VertexCount, LHeader.NormalCount, LHeader.FaceCount, LHeader.FaceVertexCount,
       LHeader.MaterialCount, LHeader.Flags, LHeader.ScaleX, LHeader.ScaleY, LHeader.ScaleZ,
       LHeader.CenterX, LHeader.CenterY, LHeader.CenterZ]));

    LFaces := AModel.GetFaces;
    LPrint := TFingerprint.Create;
    try
      for LFace := 0 to High(LFaces) do
      begin
        LPrint.AddInteger(Length(LFaces[LFace].Vertices));
        LPrint.AddCardinal(LFaces[LFace].Flags);
        LPrint.AddInteger(LFaces[LFace].TextureOriginX);
        LPrint.AddInteger(LFaces[LFace].TextureOriginY);
        LPrint.AddInteger(LFaces[LFace].TextureScaleX);
        LPrint.AddInteger(LFaces[LFace].TextureScaleY);
        LPrint.AddInteger(LFaces[LFace].TextureAngle);
        LPrint.AddBoolean(LFaces[LFace].MaterialIndex >= 0);
        if LFaces[LFace].MaterialIndex >= 0 then
        begin
          LMaterial := AModel.Materials[LFaces[LFace].MaterialIndex];
          LPrint.AddInteger(LFaces[LFace].Color);
          LPrint.AddInteger(LMaterial.Flags);
          LPrint.AddInteger(LMaterial.TextureIndex);
          LPrint.AddInteger(LMaterial.Ambient);
          LPrint.AddInteger(LMaterial.Diffuse);
          LPrint.AddInteger(LMaterial.Reflected);
          for LIndex := 0 to I3D_TEXTURE_NAME_SIZE - 1 do
            LPrint.AddInteger(Ord(LMaterial.TextureName[LIndex]));
        end;
        for LCorner := 0 to High(LFaces[LFace].Vertices) do
        begin
          LPrint.AddInteger(LFaces[LFace].Vertices[LCorner].X);
          LPrint.AddInteger(LFaces[LFace].Vertices[LCorner].Y);
          LPrint.AddInteger(LFaces[LFace].Vertices[LCorner].Z);
          LPrint.AddInteger(LFaces[LFace].Vertices[LCorner].TextureX);
          LPrint.AddInteger(LFaces[LFace].Vertices[LCorner].TextureY);
        end;
      end;
      LList.Add(Format('faces %d %s', [Length(LFaces), LPrint.ToHex]));
    finally
      LPrint.Free;
    end;

    LPrint := TFingerprint.Create;
    try
      for LIndex := 0 to AModel.TextureCount - 1 do
        for LCorner := 0 to High(AModel.Textures[LIndex].Pixels) do
          LPrint.AddInteger(AModel.Textures[LIndex].Pixels[LCorner]);
      LList.Add(Format('textures %d %s', [AModel.TextureCount, LPrint.ToHex]));
    finally
      LPrint.Free;
    end;

    LLine := 'tires';
    for LIndex := 0 to 3 do
      LLine := LLine + Format(' %d %d %d %d', [AModel.Tires[LIndex].CenterX, AModel.Tires[LIndex].CenterY,
        AModel.Tires[LIndex].CenterZ, AModel.Tires[LIndex].Perimeter]);
    LList.Add(LLine);

    LRenderer := TI3dFactory.CreateRenderer;
    for LVariant := 0 to 2 do
    begin
      LRecorder := TI3dRecorder.Create;
      LTarget := LRecorder;
      LTriangles := LRenderer.Render(AModel, LTarget, Placement(LVariant), Selected(LVariant), Tires(LVariant));
      LList.Add(Format('render %d %d %d %s', [LVariant, LTriangles, LRecorder.Calls, LRecorder.Hash]));
      LTarget := nil;
    end;

    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
