{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - an I3D model                                }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The data of TI3DModelLoader (OPENGL\i3d_model.pas of Speed) without the     }
{  streams, OpenGL and the software renderer.                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Model;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   A model read from a file: made by TI3dParser, it keeps the header, the faces, the materials
  ///   and the textures. The only thing that changes after that are the corrections.
  /// </summary>
  TI3dModel = class(TInterfacedObject, II3dModel)
  strict private
    FHeader: TI3dHeader;
    FFaces: TArray<TI3dFace>;
    FMaterials: TArray<TI3dMaterial>;
    FTextures: TArray<TI3dTexture>;
    FTires: array[0..3] of TI3dTireBox;
    procedure MeasureTires;
    procedure ApplyCorrection(const ACorrection: TI3dCorrection);
  public
    constructor Create(const AHeader: TI3dHeader; const AFaces: TArray<TI3dFace>;
      const AMaterials: TArray<TI3dMaterial>; const ATextures: TArray<TI3dTexture>);
    function GetHeader: TI3dHeader;
    function GetFaceCount: Integer;
    function GetFaces: TArray<TI3dFace>;
    function GetMaterialCount: Integer;
    function GetMaterial(const AIndex: Integer): TI3dMaterial;
    function GetTextureCount: Integer;
    function GetTexture(const AIndex: Integer): TI3dTexture;
    function GetHasTires: Boolean;
    function GetTire(const AIndex: Integer): TI3dTireBox;
    function TextureToRgba(const AIndex: Integer): TArray<Cardinal>;
    function FindMaterialByTextureName(const AName: string): Integer;
    procedure ApplyCorrections(const ACorrections: TArray<TI3dCorrection>);
  end;

implementation

uses
  DelphiDoom.Models.I3d.Palette;

{ TI3dModel }

constructor TI3dModel.Create(const AHeader: TI3dHeader; const AFaces: TArray<TI3dFace>;
  const AMaterials: TArray<TI3dMaterial>; const ATextures: TArray<TI3dTexture>);
begin
  inherited Create;
  FHeader := AHeader;
  FFaces := AFaces;
  FMaterials := AMaterials;
  FTextures := ATextures;
  MeasureTires;
end;

function TI3dModel.GetHeader: TI3dHeader;
begin
  Result := FHeader;
end;

function TI3dModel.GetFaceCount: Integer;
begin
  Result := Length(FFaces);
end;

function TI3dModel.GetFaces: TArray<TI3dFace>;
begin
  Result := FFaces;
end;

function TI3dModel.GetMaterialCount: Integer;
begin
  Result := Length(FMaterials);
end;

function TI3dModel.GetMaterial(const AIndex: Integer): TI3dMaterial;
begin
  if (AIndex < 0) or (AIndex >= Length(FMaterials)) then
    raise EModelsException.CreateFmt(SModelsI3dInvalidIndex, [AIndex]);
  Result := FMaterials[AIndex];
end;

function TI3dModel.GetTextureCount: Integer;
begin
  Result := Length(FTextures);
end;

function TI3dModel.GetTexture(const AIndex: Integer): TI3dTexture;
begin
  if (AIndex < 0) or (AIndex >= Length(FTextures)) then
    raise EModelsException.CreateFmt(SModelsI3dInvalidIndex, [AIndex]);
  Result := FTextures[AIndex];
end;

function TI3dModel.GetHasTires: Boolean;
begin
  Result := FHeader.Flags and I3D_OBJECT_HAS_TIRES <> 0;
end;

function TI3dModel.GetTire(const AIndex: Integer): TI3dTireBox;
begin
  if (AIndex < 0) or (AIndex > 3) then
    raise EModelsException.CreateFmt(SModelsI3dInvalidIndex, [AIndex]);
  Result := FTires[AIndex];
end;

function TI3dModel.TextureToRgba(const AIndex: Integer): TArray<Cardinal>;
var
  LTexture: TI3dTexture;
  LIndex: Integer;
begin
  LTexture := GetTexture(AIndex);
  SetLength(Result, Length(LTexture.Pixels));
  for LIndex := 0 to High(Result) do
    Result[LIndex] := TI3dPalette.ColorLong(LTexture.Pixels[LIndex]) or $FF000000;
end;

function TI3dModel.FindMaterialByTextureName(const AName: string): Integer;
var
  LIndex: Integer;
  LName: string;
  LCharacter: Integer;
begin
  for LIndex := 0 to High(FMaterials) do
  begin
    // the name of the file is padded with zeros up to 8 characters
    LName := '';
    for LCharacter := 0 to I3D_TEXTURE_NAME_SIZE - 1 do
    begin
      if FMaterials[LIndex].TextureName[LCharacter] = #0 then
        Break;
      LName := LName + Char(Ord(FMaterials[LIndex].TextureName[LCharacter]));
    end;
    if LName = AName then
      Exit(LIndex);
  end;
  Result := -1;
end;

procedure TI3dModel.MeasureTires;
var
  LTire, LFace, LVertex: Integer;
  LNumber: Integer;
  LMinX, LMaxX, LMinY, LMaxY, LMinZ, LMaxZ: Integer;
  LBox: TI3dTireBox;
begin
  for LTire := 0 to 3 do
    FTires[LTire] := Default(TI3dTireBox);
  if not GetHasTires then
    Exit;
  // the first 64 faces are four tires of 16 faces each; a model with fewer faces has none
  if Length(FFaces) < I3D_TIRE_FACE_COUNT then
    Exit;

  LNumber := 0;
  for LTire := 0 to 3 do
  begin
    LMinX := MaxInt;
    LMaxX := -MaxInt;
    LMinY := MaxInt;
    LMaxY := -MaxInt;
    LMinZ := MaxInt;
    LMaxZ := -MaxInt;
    for LFace := 0 to I3D_FACES_PER_TIRE - 1 do
    begin
      for LVertex := 0 to High(FFaces[LNumber].Vertices) do
      begin
        if FFaces[LNumber].Vertices[LVertex].X < LMinX then
          LMinX := FFaces[LNumber].Vertices[LVertex].X;
        if FFaces[LNumber].Vertices[LVertex].X > LMaxX then
          LMaxX := FFaces[LNumber].Vertices[LVertex].X;
        if FFaces[LNumber].Vertices[LVertex].Y < LMinY then
          LMinY := FFaces[LNumber].Vertices[LVertex].Y;
        if FFaces[LNumber].Vertices[LVertex].Y > LMaxY then
          LMaxY := FFaces[LNumber].Vertices[LVertex].Y;
        if FFaces[LNumber].Vertices[LVertex].Z < LMinZ then
          LMinZ := FFaces[LNumber].Vertices[LVertex].Z;
        if FFaces[LNumber].Vertices[LVertex].Z > LMaxZ then
          LMaxZ := FFaces[LNumber].Vertices[LVertex].Z;
      end;
      Inc(LNumber);
    end;
    // a tire without vertexes keeps MaxInt and -MaxInt, so its center is 0 (as in the old code)
    LBox.CenterX := Integer((Int64(LMinX) + LMaxX) div 2);
    LBox.CenterY := Integer((Int64(LMinY) + LMaxY) div 2);
    LBox.CenterZ := Integer((Int64(LMinZ) + LMaxZ) div 2);
    LBox.Perimeter := LMaxY - LMinY;
    FTires[LTire] := LBox;
  end;
end;

procedure TI3dModel.ApplyCorrection(const ACorrection: TI3dCorrection);
begin
  if (ACorrection.Face < 0) or (ACorrection.Face >= Length(FFaces)) then
    Exit;
  if (ACorrection.Vertex < 0) or (ACorrection.Vertex >= Length(FFaces[ACorrection.Face].Vertices)) then
    Exit;

  FFaces[ACorrection.Face].Visible := ACorrection.Visible;
  FFaces[ACorrection.Face].Vertices[ACorrection.Vertex].X := ACorrection.X;
  FFaces[ACorrection.Face].Vertices[ACorrection.Vertex].Y := ACorrection.Y;
  FFaces[ACorrection.Face].Vertices[ACorrection.Vertex].Z := ACorrection.Z;
  FFaces[ACorrection.Face].Vertices[ACorrection.Vertex].TextureX := ACorrection.TextureX;
  FFaces[ACorrection.Face].Vertices[ACorrection.Vertex].TextureY := ACorrection.TextureY;
  if FFaces[ACorrection.Face].MaterialIndex >= 0 then
    FFaces[ACorrection.Face].Color := ACorrection.Color;
end;

procedure TI3dModel.ApplyCorrections(const ACorrections: TArray<TI3dCorrection>);
var
  LCorrection: TI3dCorrection;
begin
  for LCorrection in ACorrections do
    ApplyCorrection(LCorrection);
  MeasureTires;
end;

end.

