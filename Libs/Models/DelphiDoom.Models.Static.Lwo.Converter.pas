{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: from a LWO object to a model }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::ConvertLWOToModelSurfaces). Copyright (C) 1999-2011   }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Lwo.Converter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Lwo.Types;

type
  /// <summary>
  ///   Builds the surfaces of a model from the first layer of a LWO object: one surface per
  ///   material (merged by name when the options say so), vertexes welded by position, texture
  ///   coordinate, colour and normal, the axes swapped from LightWave (Y up) to the engine (Z up),
  ///   the texture coordinate inverted in t. The material is a name: there is no declaration
  ///   manager, so "renderbump" materials are not special and "discrete" ones are merged like
  ///   the others.
  /// </summary>
  TLwoConverter = class
  strict private
    FOptions: TStaticLoadOptions;
  public
    constructor Create(const AOptions: TStaticLoadOptions);
    /// <summary>Raises EStaticModelException if the object has no surfaces or no points</summary>
    function Convert(const AObject: TLwoObject; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.SurfacePlanner,
  DelphiDoom.Models.Static.VectorSubset,
  DelphiDoom.Models.Static.VertexWelder;

function ToByte(const AValue: Single): Byte; inline;
begin
  Result := Byte(Trunc(AValue) and $FF);
end;

{ TLwoConverter }

constructor TLwoConverter.Create(const AOptions: TStaticLoadOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TLwoConverter.Convert(const AObject: TLwoObject; const AName: string): IStaticModel;
var
  LModel: TStaticModel;
  LNames: TArray<AnsiString>;
  LMergeTo, LVRemap, LTvRemap, LOffsets: TArray<Integer>;
  LPositions: TArray<TIdVec3>;
  LTexCoords: TArray<TIdVec2>;
  LLayer: ^TLwoLayer;
  LIndex, LMap, LRecord, LPolygon, LVert, LRef, LTotalTv, LTv, LPosition, LJ: Integer;
  LNormalEpsilon, LChannelValue: Single;
  LColor: TStaticColor;
  LNormal: TIdVec3;
  LWelder: TStaticVertexWelder;
  LTriangles: TStaticTriangles;
  LIndexes: TArray<Integer>;
  LIndexCount: Integer;
  LVertex: TStaticDrawVert;
  LSurface: TLwoSurface;
  LPoly: ^TLwoPolygon;
  LPoint: ^TLwoPoint;

  procedure ApplyRef(const ARef: TLwoVMapRef);
  var
    LValueChannel: Integer;
  begin
    if LLayer^.VMaps[ARef.VMap].Kind = LWO_VMAP_TXUV then
      LTv := LTvRemap[ARef.Index + LOffsets[ARef.VMap]]
    else if LLayer^.VMaps[ARef.VMap].Kind = LWO_VMAP_RGBA then
    begin
      if LLayer^.VMaps[ARef.VMap].Dim < 4 then
        raise EStaticModelException.CreateAtOffset(Format(SStaticLwoTexDimension,
          [string(LLayer^.VMaps[ARef.VMap].Name), LLayer^.VMaps[ARef.VMap].Dim]), -1);
      for LValueChannel := 0 to 3 do
      begin
        LChannelValue := 255 * LLayer^.VMaps[ARef.VMap].Value(ARef.Index, LValueChannel);
        case LValueChannel of
          0: LColor.R := ToByte(LChannelValue);
          1: LColor.G := ToByte(LChannelValue);
          2: LColor.B := ToByte(LChannelValue);
        else
          LColor.A := ToByte(LChannelValue);
        end;
      end;
    end;
  end;

begin
  if Length(AObject.Surfaces) = 0 then
    raise EStaticModelException.CreateAtOffset(SStaticLwoNoSurfaces, -1);
  LModel := TStaticModel.Create(AName);
  Result := LModel;
  SetLength(LNames, Length(AObject.Surfaces));
  for LIndex := 0 to High(LNames) do
    LNames[LIndex] := AObject.Surfaces[LIndex].Name;
  LMergeTo := TStaticSurfacePlanner.Plan(LModel, LNames, FOptions.MergeSurfaces);

  // we only ever use the first layer
  LLayer := @AObject.Layers[0];
  if Length(LLayer^.Points) <= 0 then
    raise EStaticModelException.CreateAtOffset(SStaticLwoNoPoints, -1);

  SetLength(LPositions, Length(LLayer^.Points));
  for LIndex := 0 to High(LPositions) do
  begin
    LPositions[LIndex].X := LLayer^.Points[LIndex].Pos.X;
    LPositions[LIndex].Y := LLayer^.Points[LIndex].Pos.Z;
    LPositions[LIndex].Z := LLayer^.Points[LIndex].Pos.Y;
  end;

  // vertex texture coordinates: the TXUV maps one after the other
  SetLength(LOffsets, Length(LLayer^.VMaps));
  LTotalTv := 0;
  for LMap := 0 to High(LLayer^.VMaps) do
    if LLayer^.VMaps[LMap].Kind = LWO_VMAP_TXUV then
    begin
      if LLayer^.VMaps[LMap].Dim < 2 then
        raise EStaticModelException.CreateAtOffset(Format(SStaticLwoTexDimension,
          [string(LLayer^.VMaps[LMap].Name), LLayer^.VMaps[LMap].Dim]), -1);
      LOffsets[LMap] := LTotalTv;
      Inc(LTotalTv, LLayer^.VMaps[LMap].Count);
    end;
  if LTotalTv > 0 then
  begin
    SetLength(LTexCoords, LTotalTv);
    for LMap := 0 to High(LLayer^.VMaps) do
      if LLayer^.VMaps[LMap].Kind = LWO_VMAP_TXUV then
        for LRecord := 0 to LLayer^.VMaps[LMap].Count - 1 do
        begin
          LTexCoords[LOffsets[LMap] + LRecord].X := LLayer^.VMaps[LMap].Value(LRecord, 0);
          // invert the t
          LTexCoords[LOffsets[LMap] + LRecord].Y := 1.0 - LLayer^.VMaps[LMap].Value(LRecord, 1);
        end;
  end
  else
  begin
    LModel.AddWarning(SStaticWarnLwoNoUv);
    SetLength(LTexCoords, 1);
    LTexCoords[0].Zero;
  end;

  if FOptions.FastLoad then
  begin
    SetLength(LVRemap, Length(LPositions));
    for LIndex := 0 to High(LVRemap) do
      LVRemap[LIndex] := LIndex;
    SetLength(LTvRemap, Length(LTexCoords));
    for LIndex := 0 to High(LTvRemap) do
      LTvRemap[LIndex] := LIndex;
    LNormalEpsilon := 1.0;
  end
  else
  begin
    LVRemap := TStaticVectorSubset.RemapPositions(LPositions, FOptions.SlopVertex);
    LTvRemap := TStaticVectorSubset.RemapTexCoords(LTexCoords, FOptions.SlopTexCoord);
    LNormalEpsilon := 1.0 - FOptions.SlopNormal;
  end;

  for LIndex := 0 to High(AObject.Surfaces) do
  begin
    LSurface := AObject.Surfaces[LIndex];
    LWelder := TStaticVertexWelder.Create(Length(LPositions), Length(LLayer^.Polygons) * 3);
    try
      SetLength(LIndexes, Length(LLayer^.Polygons) * 3);
      LIndexCount := 0;
      for LPolygon := 0 to High(LLayer^.Polygons) do
      begin
        LPoly := @LLayer^.Polygons[LPolygon];
        if LPoly^.Surf <> LIndex then
          Continue;
        if Length(LPoly^.Verts) <> 3 then
        begin
          LModel.AddWarning(Format(SStaticWarnLwoPolygon, [Length(LPoly^.Verts)]));
          Continue;
        end;
        for LVert := 0 to 2 do
        begin
          LPosition := LVRemap[LPoly^.Verts[LVert].Index];
          LNormal.X := LPoly^.Verts[LVert].Norm.X;
          LNormal.Y := LPoly^.Verts[LVert].Norm.Z;
          LNormal.Z := LPoly^.Verts[LVert].Norm.Y;
          // LWO models aren't all that pretty when it comes down to the floating point values they store
          LNormal.FixDegenerateNormal;
          LTv := 0;
          LColor.R := ToByte(LSurface.Red * 255);
          LColor.G := ToByte(LSurface.Green * 255);
          LColor.B := ToByte(LSurface.Blue * 255);
          LColor.A := 255;
          // first the attributes of the point, then those of the polygon override them
          LPoint := @LLayer^.Points[LPoly^.Verts[LVert].Index];
          for LRef := 0 to High(LPoint^.VMaps) do
            ApplyRef(LPoint^.VMaps[LRef]);
          for LRef := 0 to High(LPoly^.Verts[LVert].VMaps) do
            ApplyRef(LPoly^.Verts[LVert].VMaps[LRef]);
          LIndexes[LIndexCount] := LWelder.Find(LPosition, LTv, LColor.ToCardinal, LNormal, True, LNormalEpsilon);
          Inc(LIndexCount);
        end;
      end;
      SetLength(LIndexes, LIndexCount);
      LTriangles.Indexes := LIndexes;
      LTriangles.GenerateNormals := False;
      LTriangles.Verts := nil;
      SetLength(LTriangles.Verts, LWelder.Count);
      for LJ := 0 to LWelder.Count - 1 do
      begin
        LVertex.Clear;
        LVertex.Xyz := LPositions[LWelder.Position(LJ)];
        LVertex.St := LTexCoords[LWelder.TexCoord(LJ)];
        LVertex.Normal := LWelder.Normal(LJ);
        LVertex.Color := TStaticColor.FromCardinal(LWelder.Color(LJ));
        LTriangles.Verts[LJ] := LVertex;
      end;
    finally
      LWelder.Free;
    end;
    LModel.AddGeometry(LMergeTo[LIndex], LTriangles);
    LIndexes := nil;
  end;
  LModel.Finish;
end;

end.
