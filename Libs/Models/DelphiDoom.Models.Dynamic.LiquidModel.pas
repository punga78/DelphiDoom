{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - liquid model (idRenderModelLiquid)          }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_liquid.cpp}
{  and Model_local.h. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Dynamic.LiquidModel;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Random,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Deform.Types;

type
  /// <summary>
  ///   The model of a liquid surface (idRenderModelLiquid, a ".liquid" file): a grid of vertexes whose
  ///   heights follow a simulation of waves on two pages, with a drop at random places every
  ///   <c>drop_delay</c>. The time is always an argument (the view time, milliseconds); the random
  ///   numbers come from a generator seeded by the file (<c>seed</c>), so the same times give the
  ///   same surfaces. The material is a name (the model does not look it up). A file that is not
  ///   valid makes the model defaulted (<c>Defaulted</c>): the caller shows the default model, as
  ///   <c>MakeDefaultModel</c> does. Not ported: the render counters and the vertex caches.
  /// </summary>
  TLiquidModel = class
  strict private
    FLog: IIdLibLog;
    FName: AnsiString;
    FVertsX: Integer;
    FVertsY: Integer;
    FScaleX: Single;
    FScaleY: Single;
    FTime: Integer;
    FLiquidType: Integer;
    FUpdateTics: Integer;
    FSeed: Integer;
    FRandom: TIdRandom;
    FShaderName: AnsiString;
    FDensity: Single;
    FDropHeight: Single;
    FDropRadius: Integer;
    FDropDelay: Single;
    FPages: TArray<Single>;
    FPage1: Integer;
    FPage2: Integer;
    FVerts: TArray<TStaticDrawVert>;
    FDeformInfo: TStaticDeformInfo;
    FHasDeformInfo: Boolean;
    FNextDropTime: Integer;
    FBounds: TGeoBounds;
    FDefaulted: Boolean;
    procedure MakeDefaultModel;
    procedure WaterDrop(const AX, AY, APage: Integer);
    procedure Update;
    function GenerateSurface(const ALerp: Single): TStaticTriangles;
  public
    /// <summary>The defaults of the constructor: a 32 x 32 grid of 256 units, density 0.97, drops of 4 every second</summary>
    constructor Create(const ALog: IIdLibLog = nil);
    /// <summary>
    ///   InitFromFile for the text of the file: seed, size_x, size_y, verts_x, verts_y, liquid_type
    ///   (1 to 3), density, drop_height, drop_radius, drop_delay (seconds), shader, update_rate (1
    ///   to 60 updates a second). Anything else is a warning and a defaulted model.
    /// </summary>
    procedure InitFromText(const AName, AText: AnsiString);
    /// <summary>Reset: back to flat water at time 0 and the generator at its seed</summary>
    procedure Reset;
    /// <summary>
    ///   InstantiateDynamicModel: runs the simulation up to the time (at most 5 updates at once: the
    ///   time does not pile up when frames are skipped) and gives the surface between the last two
    ///   pages, with normals and tangents. Empty (no vertexes) for a model that is not usable.
    /// </summary>
    function Instantiate(const ATime: Integer): TStaticTriangles;
    /// <summary>IntersectBounds: a solid in the water pushes it down (not below the solid's lowest z)</summary>
    procedure IntersectBounds(const ABounds: TGeoBounds; const ADisplacement: Single);
    property Name: AnsiString read FName;
    property ShaderName: AnsiString read FShaderName;
    property Defaulted: Boolean read FDefaulted;
    property VertsX: Integer read FVertsX;
    property VertsY: Integer read FVertsY;
    /// <summary>Bounds: the grid and ten times the height of a drop either way</summary>
    property Bounds: TGeoBounds read FBounds;
    property Time: Integer read FTime;
    property UpdateTics: Integer read FUpdateTics;
    /// <summary>The time of the next drop (nextDropTime)</summary>
    property NextDropTime: Integer read FNextDropTime;
    /// <summary>The simulation of the file, 0 to 2 (the file says 1 to 3)</summary>
    property LiquidType: Integer read FLiquidType;
    property ScaleX: Single read FScaleX;
    property ScaleY: Single read FScaleY;
    property Density: Single read FDensity;
    property DropHeight: Single read FDropHeight;
    property DropRadius: Integer read FDropRadius;
    /// <summary>The delay between two drops in milliseconds (drop_delay, a float with an integer value)</summary>
    property DropDelay: Single read FDropDelay;
    property Seed: Integer read FSeed;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Scanner.IdParser,
  DelphiDoom.Models.Static.DeformBuilder,
  DelphiDoom.Models.Static.TangentDeriver;

const
  LIQUID_MAX_SKIP_FRAMES = 5;
  LIQUID_MAX_TYPES = 3;

{ TLiquidModel }

constructor TLiquidModel.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
  FVertsX := 32;
  FVertsY := 32;
  FScaleX := 256.0;
  FScaleY := 256.0;
  FLiquidType := 0;
  FDensity := 0.97;
  FDropHeight := 4;
  FDropRadius := 4;
  FDropDelay := 1000;
  FShaderName := '';
  FUpdateTics := 33;
  FTime := 0;
  FSeed := 0;
  FRandom := TIdRandom.Create(0);
  FBounds.Clear;
end;

procedure TLiquidModel.MakeDefaultModel;
begin
  FDefaulted := True;
  FHasDeformInfo := False;
end;

procedure TLiquidModel.InitFromText(const AName, AText: AnsiString);
var
  LParser: TIdParser;
  LToken: TIdToken;
  LIndex, LX, LY: Integer;
  LSizeX, LSizeY, LRate: Single;
  LTris: TArray<Integer>;
  LVertCount: Single;

  procedure ParserWarning(const AMessage: string);
  begin
    LParser.Warning(AMessage);
  end;

begin
  FName := AName;
  FDefaulted := False;
  FHasDeformInfo := False;
  LParser := TIdParser.Create(LEXFL_ALLOWPATHNAMES or LEXFL_NOSTRINGESCAPECHARS, FLog);
  try
    if not LParser.LoadMemory(AText, AName) then
    begin
      MakeDefaultModel;
      Exit;
    end;
    LToken := TIdToken.Create;
    LSizeX := FScaleX * FVertsX;
    LSizeY := FScaleY * FVertsY;
    while LParser.ReadToken(LToken) do
    begin
      if SameText(string(LToken.Text), 'seed') then
        FSeed := LParser.ParseInt
      else if SameText(string(LToken.Text), 'size_x') then
        LSizeX := LParser.ParseFloat
      else if SameText(string(LToken.Text), 'size_y') then
        LSizeY := LParser.ParseFloat
      else if SameText(string(LToken.Text), 'verts_x') then
      begin
        LVertCount := LParser.ParseFloat;
        FVertsX := Trunc(LVertCount);
        if FVertsX < 2 then
        begin
          ParserWarning('Invalid # of verts.  Using default model.');
          MakeDefaultModel;
          Exit;
        end;
      end
      else if SameText(string(LToken.Text), 'verts_y') then
      begin
        LVertCount := LParser.ParseFloat;
        FVertsY := Trunc(LVertCount);
        if FVertsY < 2 then
        begin
          ParserWarning('Invalid # of verts.  Using default model.');
          MakeDefaultModel;
          Exit;
        end;
      end
      else if SameText(string(LToken.Text), 'liquid_type') then
      begin
        FLiquidType := LParser.ParseInt - 1;
        if (FLiquidType < 0) or (FLiquidType >= LIQUID_MAX_TYPES) then
        begin
          ParserWarning('Invalid liquid_type.  Using default model.');
          MakeDefaultModel;
          Exit;
        end;
      end
      else if SameText(string(LToken.Text), 'density') then
        FDensity := LParser.ParseFloat
      else if SameText(string(LToken.Text), 'drop_height') then
        FDropHeight := LParser.ParseFloat
      else if SameText(string(LToken.Text), 'drop_radius') then
        FDropRadius := LParser.ParseInt
      else if SameText(string(LToken.Text), 'drop_delay') then
      begin
        // SEC2MS: the product is cut to an int
        LRate := LParser.ParseFloat;
        LRate := LRate * 1000;
        FDropDelay := Trunc(LRate);
      end
      else if SameText(string(LToken.Text), 'shader') then
      begin
        LParser.ReadToken(LToken);
        FShaderName := LToken.Text;
      end
      else if SameText(string(LToken.Text), 'update_rate') then
      begin
        LRate := LParser.ParseFloat;
        if (LRate <= 0.0) or (LRate > 60.0) then
        begin
          ParserWarning('Invalid update_rate.  Must be between 0 and 60.  Using default model.');
          MakeDefaultModel;
          Exit;
        end;
        LRate := 1000 / LRate;
        FUpdateTics := Trunc(LRate);
      end
      else
      begin
        ParserWarning(Format('Unknown parameter ''%s''.  Using default model.', [string(LToken.Text)]));
        MakeDefaultModel;
        Exit;
      end;
    end;
  finally
    LParser.Free;
  end;
  FScaleX := LSizeX / (FVertsX - 1);
  FScaleY := LSizeY / (FVertsY - 1);
  SetLength(FPages, 2 * FVertsX * FVertsY);
  FPage1 := 0;
  FPage2 := FVertsX * FVertsY;
  SetLength(FVerts, FVertsX * FVertsY);
  LIndex := 0;
  for LY := 0 to FVertsY - 1 do
    for LX := 0 to FVertsX - 1 do
    begin
      FPages[FPage1 + LIndex] := 0;
      FPages[FPage2 + LIndex] := 0;
      FVerts[LIndex].Clear;
      FVerts[LIndex].Xyz := TIdVec3.Create(LX * FScaleX, LY * FScaleY, 0.0);
      FVerts[LIndex].St := TIdVec2.Create(Single(LX) / Single(FVertsX - 1), Single(-LY) / Single(FVertsY - 1));
      Inc(LIndex);
    end;
  SetLength(LTris, (FVertsX - 1) * (FVertsY - 1) * 6);
  LIndex := 0;
  for LY := 0 to FVertsY - 2 do
    for LX := 1 to FVertsX - 1 do
    begin
      LTris[LIndex + 0] := LY * FVertsX + LX;
      LTris[LIndex + 1] := LY * FVertsX + LX - 1;
      LTris[LIndex + 2] := (LY + 1) * FVertsX + LX - 1;
      LTris[LIndex + 3] := (LY + 1) * FVertsX + LX - 1;
      LTris[LIndex + 4] := (LY + 1) * FVertsX + LX;
      LTris[LIndex + 5] := LY * FVertsX + LX;
      Inc(LIndex, 6);
    end;
  // the information common to all the animations: edge connectivity and normal and tangent generation
  FDeformInfo := TStaticDeformBuilder.Build(FVerts, LTris, True, FLog);
  FHasDeformInfo := True;
  FBounds.Clear;
  FBounds.AddPoint(TGeoVec3.Make(0.0, 0.0, FDropHeight * -10.0));
  FBounds.AddPoint(TGeoVec3.Make((FVertsX - 1) * FScaleX, (FVertsY - 1) * FScaleY, FDropHeight * 10.0));
  Reset;
end;

procedure TLiquidModel.Reset;
var
  LIndex: Integer;
begin
  if Length(FPages) < 2 * FVertsX * FVertsY then
    Exit;
  FNextDropTime := 0;
  FTime := 0;
  FRandom.SetSeed(FSeed);
  FPage1 := 0;
  FPage2 := FVertsX * FVertsY;
  for LIndex := 0 to FVertsX * FVertsY - 1 do
  begin
    FPages[FPage1 + LIndex] := 0.0;
    FPages[FPage2 + LIndex] := 0.0;
    FVerts[LIndex].Xyz.Z := 0.0;
  end;
end;

procedure TLiquidModel.WaterDrop(const AX, AY, APage: Integer);
var
  LX, LY, LCx, LCy, LLeft, LTop, LRight, LBottom, LSquare, LRadSquare: Integer;
  LInverseLength, LDist, LAngle: Single;
begin
  LX := AX;
  LY := AY;
  LRadSquare := FDropRadius * FDropRadius;
  LInverseLength := 1.0 / Single(LRadSquare);
  if LX < 0 then
    LX := 1 + FDropRadius + FRandom.RandomInt(FVertsX - 2 * FDropRadius - 1);
  if LY < 0 then
    LY := 1 + FDropRadius + FRandom.RandomInt(FVertsY - 2 * FDropRadius - 1);
  LLeft := -FDropRadius;
  LRight := FDropRadius;
  LTop := -FDropRadius;
  LBottom := FDropRadius;
  // edge clipping
  if LX - FDropRadius < 1 then
    Dec(LLeft, LX - FDropRadius - 1);
  if LY - FDropRadius < 1 then
    Dec(LTop, LY - FDropRadius - 1);
  if LX + FDropRadius > FVertsX - 1 then
    Dec(LRight, LX + FDropRadius - FVertsX + 1);
  if LY + FDropRadius > FVertsY - 1 then
    Dec(LBottom, LY + FDropRadius - FVertsY + 1);
  for LCy := LTop to LBottom - 1 do
    for LCx := LLeft to LRight - 1 do
    begin
      LSquare := LCy * LCy + LCx * LCx;
      if LSquare < LRadSquare then
      begin
        LDist := TIdMath.Sqrt(Single(LSquare) * LInverseLength);
        LAngle := LDist * ID_PI * 0.5;
        // one rounding for the whole sum, as the original (page[i] += cos * height)
        FPages[APage + FVertsX * (LCy + LY) + LCx + LX] := FPages[APage + FVertsX * (LCy + LY) + LCx + LX] +
          TIdMath.Cos16(LAngle) * FDropHeight;
      end;
    end;
end;

procedure TLiquidModel.IntersectBounds(const ABounds: TGeoBounds; const ADisplacement: Single);
var
  LCx, LCy, LLeft, LTop, LRight, LBottom: Integer;
  LDown: Single;
  LQuotient: Single;
begin
  LQuotient := ABounds.Mins.X / FScaleX;
  LLeft := Trunc(LQuotient);
  LQuotient := ABounds.Maxs.X / FScaleX;
  LRight := Trunc(LQuotient);
  LQuotient := ABounds.Mins.Y / FScaleY;
  LTop := Trunc(LQuotient);
  LQuotient := ABounds.Maxs.Y / FScaleY;
  LBottom := Trunc(LQuotient);
  LDown := ABounds.Mins.Z;
  // the original tests the top against verts_x
  if (LRight < 1) or (LLeft >= FVertsX) or (LBottom < 1) or (LTop >= FVertsX) then
    Exit;
  if LLeft < 1 then
    LLeft := 1;
  if LRight >= FVertsX then
    LRight := FVertsX - 1;
  if LTop < 1 then
    LTop := 1;
  if LBottom >= FVertsY then
    LBottom := FVertsY - 1;
  for LCy := LTop to LBottom - 1 do
    for LCx := LLeft to LRight - 1 do
      if FPages[FPage1 + FVertsX * LCy + LCx] > LDown then
        FPages[FPage1 + FVertsX * LCy + LCx] := LDown;
end;

procedure TLiquidModel.Update;
var
  LX, LY, LSwap, LP1, LP2: Integer;
  LValue: Single;
  LTwoNinths, LOneNinth: Single;
begin
  LTwoNinths := 2.0 / 9.0;
  LOneNinth := 1.0 / 9.0;
  Inc(FTime, FUpdateTics);
  LSwap := FPage1;
  FPage1 := FPage2;
  FPage2 := LSwap;
  if FTime > FNextDropTime then
  begin
    WaterDrop(-1, -1, FPage2);
    FNextDropTime := FTime + Trunc(FDropDelay);
  end
  else if FTime < FNextDropTime - Trunc(FDropDelay) then
    FNextDropTime := FTime + Trunc(FDropDelay);
  case FLiquidType of
    0:
      for LY := 1 to FVertsY - 2 do
      begin
        LP1 := FPage1 + LY * FVertsX;
        LP2 := FPage2 + LY * FVertsX;
        for LX := 1 to FVertsX - 2 do
        begin
          LValue := (FPages[LP2 + LX + FVertsX] + FPages[LP2 + LX - FVertsX] + FPages[LP2 + LX + 1] +
            FPages[LP2 + LX - 1] + FPages[LP2 + LX - FVertsX - 1] + FPages[LP2 + LX - FVertsX + 1] +
            FPages[LP2 + LX + FVertsX - 1] + FPages[LP2 + LX + FVertsX + 1] + FPages[LP2 + LX]) * LTwoNinths -
            FPages[LP1 + LX];
          FPages[LP1 + LX] := LValue * FDensity;
        end;
      end;
    1:
      for LY := 1 to FVertsY - 2 do
      begin
        LP1 := FPage1 + LY * FVertsX;
        LP2 := FPage2 + LY * FVertsX;
        for LX := 1 to FVertsX - 2 do
        begin
          LValue := (FPages[LP2 + LX + FVertsX] + FPages[LP2 + LX - FVertsX] + FPages[LP2 + LX + 1] +
            FPages[LP2 + LX - 1] + FPages[LP2 + LX - FVertsX - 1] + FPages[LP2 + LX - FVertsX + 1] +
            FPages[LP2 + LX + FVertsX - 1] + FPages[LP2 + LX + FVertsX + 1]) * 0.25 - FPages[LP1 + LX];
          FPages[LP1 + LX] := LValue * FDensity;
        end;
      end;
    2:
      for LY := 1 to FVertsY - 2 do
      begin
        LP1 := FPage1 + LY * FVertsX;
        LP2 := FPage2 + LY * FVertsX;
        for LX := 1 to FVertsX - 2 do
        begin
          LValue := (FPages[LP2 + LX + FVertsX] + FPages[LP2 + LX - FVertsX] + FPages[LP2 + LX + 1] +
            FPages[LP2 + LX - 1] + FPages[LP2 + LX - FVertsX - 1] + FPages[LP2 + LX - FVertsX + 1] +
            FPages[LP2 + LX + FVertsX - 1] + FPages[LP2 + LX + FVertsX + 1] + FPages[LP2 + LX]) * LOneNinth;
          FPages[LP1 + LX] := LValue * FDensity;
        end;
      end;
  end;
end;

function TLiquidModel.GenerateSurface(const ALerp: Single): TStaticTriangles;
var
  LInverse: Single;
  LIndex, LBase: Integer;
  LVerts: TArray<TStaticDrawVert>;
begin
  LInverse := 1.0 - ALerp;
  for LIndex := 0 to High(FVerts) do
    FVerts[LIndex].Xyz.Z := FPages[FPage1 + LIndex] * ALerp + FPages[FPage2 + LIndex] * LInverse;
  SetLength(LVerts, FDeformInfo.NumOutputVerts);
  for LIndex := 0 to FDeformInfo.NumSourceVerts - 1 do
    LVerts[LIndex] := FVerts[LIndex];
  // replicate the mirror seam vertexes
  LBase := FDeformInfo.NumOutputVerts - FDeformInfo.NumMirroredVerts;
  for LIndex := 0 to FDeformInfo.NumMirroredVerts - 1 do
    LVerts[LBase + LIndex] := LVerts[FDeformInfo.MirroredVerts[LIndex]];
  // the face planes, the normals and the tangents
  TStaticTangentDeriver.DeriveTangents(LVerts, FDeformInfo.Indexes, FDeformInfo.DupVerts, FDeformInfo.DominantTris);
  Result.Verts := LVerts;
  Result.Indexes := FDeformInfo.Indexes;
  Result.GenerateNormals := False;
  Result.SilEdges := FDeformInfo.SilEdges;
end;

function TLiquidModel.Instantiate(const ATime: Integer): TStaticTriangles;
var
  LFrames: Integer;
  LLerp: Single;
begin
  Result.Verts := nil;
  Result.Indexes := nil;
  Result.GenerateNormals := False;
  Result.PerfectHull := False;
  if (not FHasDeformInfo) or FDefaulted then
    Exit;
  // update the liquid model
  LFrames := (ATime - FTime) div FUpdateTics;
  if LFrames > LIQUID_MAX_SKIP_FRAMES then
  begin
    // do not let time accumulate when skipping frames
    Inc(FTime, FUpdateTics * (LFrames - LIQUID_MAX_SKIP_FRAMES));
    LFrames := LIQUID_MAX_SKIP_FRAMES;
  end;
  while LFrames > 0 do
  begin
    Update;
    Dec(LFrames);
  end;
  LLerp := Single(ATime - FTime) / Single(FUpdateTics);
  Result := GenerateSurface(LLerp);
end;

end.
