{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - liquid model parity            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.LiquidParity;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Dynamic.LiquidModel,
  DelphiDoom.Tests.Models.GoldenLines;

type
  /// <summary>
  ///   TLiquidModel against the real idRenderModelLiquid of Doom 3 (Model_liquid.cpp: InitFromFile, Update,
  ///   WaterDrop, GenerateSurface, IntersectBounds, InstantiateDynamicModel) on the real
  ///   R_BuildDeformInfo and R_DeriveTangents, compiled with bcc32c (Tests\Data\Models\deform,
  ///   harness\build.ps1.txt, liquid.golden.txt). Tolerance: 2 ULP, or 4e-6 relative, or 1e-5 absolute.
  /// </summary>
  [TestFixture]
  [Category('Liquid')]
  TTestLiquidParity = class
  strict private
    FGolden: TGoldenLines;
    procedure CheckFloats(const AWhat: string; const AExpected, AActual: TArray<Single>);
    procedure CheckCase(const ACase: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase('liquido di tipo 2 (A)', 'typeA')]
    [TestCase('liquido di tipo 3 (B)', 'typeB')]
    [TestCase('liquido di tipo 4 (C)', 'typeC')]
    [TestCase('un solido nell acqua', 'intersect')]
    [TestCase('valori di partenza', 'defaults')]
    [TestCase('verts_x troppo piccolo', 'badverts')]
    [TestCase('liquid_type fuori intervallo', 'badtype')]
    [TestCase('update_rate troppo alto', 'badrate')]
    [TestCase('update_rate zero', 'badrate0')]
    [TestCase('parametro sconosciuto', 'unknown')]
    procedure DovrebbeDareLeStesseRisposteDelCpp(const ACase: string);
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Tests.Models.Md5Golden,
  DelphiDoom.Tests.Models.AnimSupport;

{ TTestLiquidParity }

procedure TTestLiquidParity.Setup;
begin
  FGolden := TGoldenLines.Create('deform\liquid.golden.txt');
end;

procedure TTestLiquidParity.TearDown;
begin
  FGolden.Free;
end;

procedure TTestLiquidParity.CheckFloats(const AWhat: string; const AExpected, AActual: TArray<Single>);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), Length(AActual), AWhat + ': number of values');
  for LIndex := 0 to High(AExpected) do
    Assert.IsTrue(TMd5Golden.Close(AExpected[LIndex], AActual[LIndex]),
      Format('%s[%d]: expected %s, got %s', [AWhat, LIndex, TMd5Golden.Describe(AExpected[LIndex]),
        TMd5Golden.Describe(AActual[LIndex])]));
end;

procedure TTestLiquidParity.CheckCase(const ACase: string);
var
  LModel: TLiquidModel;
  LLog: TRecordingLog;
  LLogIntf: IIdLibLog;
  LText, LKey: string;
  LInit, LTimes: TArray<Integer>;
  LFloats: TArray<Single>;
  LActual: TArray<Single>;
  LTriangles: TStaticTriangles;
  LBounds: TGeoBounds;
  LIndex, LVert, LAt: Integer;
  LState: TArray<Integer>;
begin
  LLog := TRecordingLog.Create;
  LLogIntf := LLog;
  LText := string.Join(' ', FGolden.Tokens('LIQ ' + ACase + ' text'));
  LModel := TLiquidModel.Create(LLogIntf);
  try
    LModel.InitFromText('test.liquid', AnsiString(LText));
    LInit := FGolden.Ints('LIQ ' + ACase + ' init');
    Assert.AreEqual(LInit[0] <> 0, LModel.Defaulted, ACase + ': defaulted');
    if FGolden.Has('LIQ ' + ACase + ' warning') then
      // the golden is split at the white space: the double space after a full stop is one
      Assert.IsTrue(Pos(string.Join(' ', FGolden.Tokens('LIQ ' + ACase + ' warning')),
        StringReplace(LLog.Text, '  ', ' ', [rfReplaceAll])) > 0, ACase + ': warning ' + LLog.Text)
    else
      Assert.AreEqual<Integer>(0, LLog.Count, ACase + ': no warning expected');
    Assert.AreEqual<Integer>(LInit[1], LModel.VertsX, ACase + ': verts_x');
    Assert.AreEqual<Integer>(LInit[2], LModel.VertsY, ACase + ': verts_y');
    Assert.AreEqual<Integer>(LInit[3], LModel.UpdateTics, ACase + ': update tics');
    Assert.AreEqual<Integer>(LInit[4], LModel.LiquidType, ACase + ': liquid type');
    if LModel.Defaulted then
    begin
      Assert.AreEqual<Integer>(0, Length(LModel.Instantiate(100).Verts), ACase + ': a defaulted model has no surface');
      Exit;
    end;
    LFloats := FGolden.Floats('LIQ ' + ACase + ' dims');
    CheckFloats(ACase + ' dims', LFloats, [LModel.ScaleX, LModel.ScaleY, LModel.Density, LModel.DropHeight,
      LModel.DropDelay]);
    LState := FGolden.Ints('LIQ ' + ACase + ' dims');
    Assert.AreEqual<Integer>(LState[0], LModel.DropRadius, ACase + ': drop radius');
    Assert.AreEqual<Integer>(LState[1], LModel.Seed, ACase + ': seed');
    LBounds := LModel.Bounds;
    CheckFloats(ACase + ' model bounds', FGolden.Floats('LIQ ' + ACase + ' modelbounds'),
      [LBounds.Mins.X, LBounds.Mins.Y, LBounds.Mins.Z, LBounds.Maxs.X, LBounds.Maxs.Y, LBounds.Maxs.Z]);
    Assert.AreEqual(string.Join(' ', FGolden.Tokens('LIQ ' + ACase + ' shader')), string(LModel.ShaderName),
      ACase + ': shader name');
    LTimes := FGolden.Ints('LIQ ' + ACase + ' times');
    for LIndex := 0 to High(LTimes) do
    begin
      LKey := Format('LIQ %s t%d', [ACase, LIndex]);
      if FGolden.Has(Format('LIQ %s intersect', [ACase])) then
      begin
        LAt := FGolden.Ints(Format('LIQ %s intersect', [ACase]))[0];
        if LAt = LIndex then
        begin
          LFloats := FGolden.Floats(Format('LIQ %s intersect', [ACase]));
          LBounds.Mins := TGeoVec3.Make(LFloats[0], LFloats[1], LFloats[2]);
          LBounds.Maxs := TGeoVec3.Make(LFloats[3], LFloats[4], LFloats[5]);
          LModel.IntersectBounds(LBounds, 0.0);
        end;
      end;
      LTriangles := LModel.Instantiate(LTimes[LIndex]);
      LInit := FGolden.Ints(LKey);
      Assert.AreEqual<Integer>(LInit[1], Length(LTriangles.Verts), LKey + ': vertexes');
      Assert.AreEqual<Integer>(LInit[2], Length(LTriangles.Indexes), LKey + ': indexes');
      SetLength(LActual, Length(LTriangles.Verts));
      for LVert := 0 to High(LTriangles.Verts) do
        LActual[LVert] := LTriangles.Verts[LVert].Xyz.Z;
      CheckFloats(LKey + ' z', FGolden.Floats(LKey + ' z'), LActual);
      LBounds := LTriangles.CalcBounds;
      CheckFloats(LKey + ' bounds', FGolden.Floats(LKey + ' bounds'),
        [LBounds.Mins.X, LBounds.Mins.Y, LBounds.Mins.Z, LBounds.Maxs.X, LBounds.Maxs.Y, LBounds.Maxs.Z]);
      // The normals and tangents come from the dominant triangle of every vertex, chosen when the grid is flat:
      // every triangle of a vertex has the same area and qsort leaves the order of equal ones undefined (the
      // C++ here is bcc32c's qsort, Doom 3's is the one of its compiler; Delphi keeps the order they appear in).
      // They are compared on the first frame (flat, so the same whichever triangle is chosen).
      if (LIndex = 0) and FGolden.Has(LKey + ' normals') then
      begin
        SetLength(LActual, Length(LTriangles.Verts) * 9);
        for LVert := 0 to High(LTriangles.Verts) do
        begin
          LActual[LVert * 9] := LTriangles.Verts[LVert].Normal.X;
          LActual[LVert * 9 + 1] := LTriangles.Verts[LVert].Normal.Y;
          LActual[LVert * 9 + 2] := LTriangles.Verts[LVert].Normal.Z;
          LActual[LVert * 9 + 3] := LTriangles.Verts[LVert].Tangents[0].X;
          LActual[LVert * 9 + 4] := LTriangles.Verts[LVert].Tangents[0].Y;
          LActual[LVert * 9 + 5] := LTriangles.Verts[LVert].Tangents[0].Z;
          LActual[LVert * 9 + 6] := LTriangles.Verts[LVert].Tangents[1].X;
          LActual[LVert * 9 + 7] := LTriangles.Verts[LVert].Tangents[1].Y;
          LActual[LVert * 9 + 8] := LTriangles.Verts[LVert].Tangents[1].Z;
        end;
        CheckFloats(LKey + ' normals', FGolden.Floats(LKey + ' normals'), LActual);
      end;
      LState := FGolden.Ints(LKey + ' state');
      Assert.AreEqual<Integer>(LState[0], LModel.Time, LKey + ': time');
      Assert.AreEqual<Integer>(LState[1], LModel.NextDropTime, LKey + ': next drop time');
    end;
  finally
    LModel.Free;
  end;
end;

procedure TTestLiquidParity.DovrebbeDareLeStesseRisposteDelCpp(const ACase: string);
begin
  CheckCase(ACase);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLiquidParity);

end.
