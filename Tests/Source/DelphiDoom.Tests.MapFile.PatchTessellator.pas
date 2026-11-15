{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the tessellation of the patches of a .map (DUnitX)     }
{                                                                              }
{  ParsePatch of dmap: the subdivision is TGeoSurfacePatch, whose parity with  }
{  idSurface_Patch is in the tests of Libs\Geometry; here the control grid of  }
{  a map patch becomes the surface and the right call is made.                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.PatchTessellator;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Surface.Patch,
  DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.Patch.Tessellator;

type
  [TestFixture]
  [Category('mapfile')]
  TTestMapPatchTessellator = class(TObject)
  strict private
    function Grid(AMiddleHeight: Single): TMapPatch;
  public
    [Test]
    procedure DovrebbeCopiareLaGrigliaNellaSuperficie;
    [Test]
    procedure DovrebbeRidurreUnaPatchPianaAUnQuadrato;
    [Test]
    procedure DovrebbeSuddividereUnaPatchCurvaConUnErroreMassimoDiQuattro;
    [Test]
    procedure DovrebbeUsareLeSuddivisioniEsplicite;
    [Test]
    procedure DovrebbeGenerareLeNormali;
    [Test]
    procedure DovrebbeUsareUnErroreDiverso;
  end;

implementation

function TTestMapPatchTessellator.Grid(AMiddleHeight: Single): TMapPatch;
var
  LRow, LColumn: Integer;
  LVertex: TMapPatchVertex;
begin
  Result := TMapPatch.Create(3, 3);
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
    begin
      LVertex.Position := TGeoVec3.Make(LColumn * 64, LRow * 64, 0);
      if (LRow = 1) and (LColumn = 1) then
        LVertex.Position.Z := AMiddleHeight;
      LVertex.S := LColumn * 0.5;
      LVertex.T := LRow * 0.5;
      Result.Vertices[LRow * 3 + LColumn] := LVertex;
    end;
end;

procedure TTestMapPatchTessellator.DovrebbeCopiareLaGrigliaNellaSuperficie;
var
  LPatch: TMapPatch;
  LSurface: TGeoSurfacePatch;
begin
  LPatch := Grid(30);
  try
    LSurface := TMapPatchTessellator.ToSurface(LPatch);
    try
      Assert.AreEqual(3, LSurface.Width);
      Assert.AreEqual(3, LSurface.Height);
      Assert.AreEqual(64.0, Double(LSurface.Vertices[4].Xyz.X), 0);
      Assert.AreEqual(30.0, Double(LSurface.Vertices[4].Xyz.Z), 0);
      Assert.AreEqual(0.5, Double(LSurface.Vertices[4].St.X), 0);
      Assert.AreEqual(1.0, Double(LSurface.Vertices[8].St.Y), 0);
    finally
      LSurface.Free;
    end;
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatchTessellator.DovrebbeRidurreUnaPatchPianaAUnQuadrato;
var
  LPatch: TMapPatch;
  LSurface: TGeoSurfacePatch;
begin
  LPatch := Grid(0);
  try
    LSurface := TMapPatchTessellator.Tessellate(LPatch);
    try
      // a flat patch: the linear rows and columns are removed, two triangles remain
      Assert.AreEqual(4, LSurface.NumVertices);
      Assert.AreEqual(6, LSurface.NumIndexes);
    finally
      LSurface.Free;
    end;
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatchTessellator.DovrebbeSuddividereUnaPatchCurvaConUnErroreMassimoDiQuattro;
var
  LPatch: TMapPatch;
  LSurface: TGeoSurfacePatch;
  LFlat: TGeoSurfacePatch;
begin
  LPatch := Grid(60);
  try
    LSurface := TMapPatchTessellator.Tessellate(LPatch);
    LFlat := TMapPatchTessellator.TessellateWith(LPatch, 400, 400, -1);
    try
      Assert.IsTrue(LSurface.NumVertices > 9);
      // a larger error allows fewer vertexes
      Assert.IsTrue(LFlat.NumVertices < LSurface.NumVertices);
      Assert.AreEqual(0, LSurface.NumIndexes mod 3);
    finally
      LFlat.Free;
      LSurface.Free;
    end;
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatchTessellator.DovrebbeUsareLeSuddivisioniEsplicite;
var
  LPatch: TMapPatch;
  LSurface: TGeoSurfacePatch;
begin
  LPatch := Grid(60);
  try
    LPatch.ExplicitlySubdivided := True;
    LPatch.HorzSubdivisions := 4;
    LPatch.VertSubdivisions := 2;
    LSurface := TMapPatchTessellator.Tessellate(LPatch);
    try
      // one 3x3 patch: 4 steps across (5 columns) and 2 steps up (3 rows)
      Assert.AreEqual(15, LSurface.NumVertices);
      Assert.AreEqual(4 * 2 * 6, LSurface.NumIndexes);
      Assert.AreEqual(5, LSurface.Width);
      Assert.AreEqual(3, LSurface.Height);
    finally
      LSurface.Free;
    end;
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatchTessellator.DovrebbeGenerareLeNormali;
var
  LPatch: TMapPatch;
  LSurface: TGeoSurfacePatch;
  LIndex: Integer;
begin
  LPatch := Grid(0);
  try
    LPatch.ExplicitlySubdivided := True;
    LPatch.HorzSubdivisions := 2;
    LPatch.VertSubdivisions := 2;
    LSurface := TMapPatchTessellator.Tessellate(LPatch);
    try
      // the patch is flat in the x-y plane: every normal is (0, 0, 1) or (0, 0, -1)
      for LIndex := 0 to LSurface.NumVertices - 1 do
        Assert.AreEqual(1.0, Abs(Double(LSurface.Vertices[LIndex].Normal.Z)), 0.001);
    finally
      LSurface.Free;
    end;
  finally
    LPatch.Free;
  end;
end;

procedure TTestMapPatchTessellator.DovrebbeUsareUnErroreDiverso;
var
  LPatch: TMapPatch;
  LCoarse, LFine: TGeoSurfacePatch;
begin
  LPatch := Grid(60);
  try
    LCoarse := TMapPatchTessellator.TessellateWith(LPatch, MAP_DEFAULT_CURVE_MAX_ERROR_CD, MAP_DEFAULT_CURVE_MAX_ERROR_CD, -1);
    LFine := TMapPatchTessellator.TessellateWith(LPatch, 1, 1, -1);
    try
      Assert.IsTrue(LFine.NumVertices > LCoarse.NumVertices);
    finally
      LFine.Free;
      LCoarse.Free;
    end;
  finally
    LPatch.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMapPatchTessellator);

end.
