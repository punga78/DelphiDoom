{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - deformable surfaces parity     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.DeformParity;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Tests.Models.GoldenLines;

type
  /// <summary>
  ///   R_BuildDeformInfo, R_DeriveTangents, R_DeriveFacePlanes and
  ///   R_DeriveTangentsWithoutNormals against the real functions of tr_trisurf.cpp and of
  ///   idSIMD_Generic compiled with bcc32c (Tests\Data\Models\deform). Tolerance: 2 ULP, or
  ///   4e-6 relative, or 1e-5 absolute.
  /// </summary>
  [TestFixture]
  [Category('Deform')]
  TTestDeformParity = class
  strict private
    FGolden: TGoldenLines;
    function ReadVerts(const ACase: string): TArray<TStaticDrawVert>;
    procedure CheckFloats(const AWhat: string; const AExpected, AActual: TArray<Single>);
    procedure CheckInts(const AWhat: string; const AExpected, AActual: TArray<Integer>);
    procedure CheckCase(const ACase: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRiprodurreLaStrisciaConLaTexturaSpecchiata;
    [Test]
    procedure DovrebbeRiprodurreIlCubo;
    [Test]
    procedure DovrebbeRiprodurreLaGriglia;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Geometry.Plane,
  DelphiDoom.Models.Static.Deform.Types,
  DelphiDoom.Models.Static.DeformBuilder,
  DelphiDoom.Models.Static.TangentDeriver,
  DelphiDoom.Tests.Models.Md5Golden;

{ TTestDeformParity }

procedure TTestDeformParity.Setup;
begin
  FGolden := TGoldenLines.Create('deform\deform.golden.txt');
end;

procedure TTestDeformParity.TearDown;
begin
  FGolden.Free;
end;

function TTestDeformParity.ReadVerts(const ACase: string): TArray<TStaticDrawVert>;
var
  LValues: TArray<Single>;
  LIndex: Integer;
begin
  LValues := FGolden.Floats(ACase + ' in verts');
  SetLength(Result, Length(LValues) div 5);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Clear;
    Result[LIndex].Xyz := TIdVec3.Create(LValues[LIndex * 5], LValues[LIndex * 5 + 1], LValues[LIndex * 5 + 2]);
    Result[LIndex].St := TIdVec2.Create(LValues[LIndex * 5 + 3], LValues[LIndex * 5 + 4]);
  end;
end;

procedure TTestDeformParity.CheckFloats(const AWhat: string; const AExpected, AActual: TArray<Single>);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), Length(AActual), AWhat + ': numero di valori');
  for LIndex := 0 to High(AExpected) do
    Assert.IsTrue(TMd5Golden.Close(AExpected[LIndex], AActual[LIndex]),
      Format('%s[%d]: atteso %s, letto %s', [AWhat, LIndex, TMd5Golden.Describe(AExpected[LIndex]),
        TMd5Golden.Describe(AActual[LIndex])]));
end;

procedure TTestDeformParity.CheckInts(const AWhat: string; const AExpected, AActual: TArray<Integer>);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), Length(AActual), AWhat + ': numero di valori');
  for LIndex := 0 to High(AExpected) do
    Assert.AreEqual<Integer>(AExpected[LIndex], AActual[LIndex], Format('%s[%d]', [AWhat, LIndex]));
end;

procedure TTestDeformParity.CheckCase(const ACase: string);
var
  LSource, LVerts: TArray<TStaticDrawVert>;
  LIndexes: TArray<Integer>;
  LInfo: TStaticDeformInfo;
  LUnsmoothed, LCount: Integer;
  LKey: string;
  LActual, LExpected: TArray<Single>;
  LPlanes: TArray<TGeoPlane>;
  LIndex, LBase: Integer;
  LDeclared: TArray<Integer>;
begin
  LSource := ReadVerts(ACase);
  LIndexes := FGolden.Ints(ACase + ' in idx');
  for LUnsmoothed := 0 to 1 do
  begin
    LKey := Format('%s %d ', [ACase, LUnsmoothed]);
    LInfo := TStaticDeformBuilder.Build(LSource, LIndexes, LUnsmoothed <> 0);
    LDeclared := FGolden.Ints(LKey + 'deform');
    Assert.AreEqual<Integer>(LDeclared[0], LInfo.NumSourceVerts, LKey + 'numSourceVerts');
    Assert.AreEqual<Integer>(LDeclared[1], LInfo.NumOutputVerts, LKey + 'numOutputVerts');
    Assert.AreEqual<Integer>(LDeclared[2], LInfo.NumMirroredVerts, LKey + 'numMirroredVerts');
    Assert.AreEqual<Integer>(LDeclared[3], LInfo.NumDupVerts, LKey + 'numDupVerts');
    CheckInts(LKey + 'mirrored', FGolden.Ints(LKey + 'mirrored'), LInfo.MirroredVerts);
    CheckInts(LKey + 'dup', FGolden.Ints(LKey + 'dup'), LInfo.DupVerts);
    CheckInts(LKey + 'idx', FGolden.Ints(LKey + 'idx'), LInfo.Indexes);
    CheckInts(LKey + 'sil', FGolden.Ints(LKey + 'sil'), LInfo.SilIndexes);
    if LUnsmoothed <> 0 then
    begin
      LExpected := FGolden.Floats(LKey + 'dominant');
      LDeclared := FGolden.Ints(LKey + 'dominant');
      Assert.AreEqual<Integer>(LInfo.NumOutputVerts, Length(LInfo.DominantTris), LKey + 'dominanti');
      SetLength(LActual, Length(LInfo.DominantTris) * 3);
      for LIndex := 0 to High(LInfo.DominantTris) do
      begin
        Assert.AreEqual<Integer>(LDeclared[LIndex * 2], LInfo.DominantTris[LIndex].V2, LKey + 'v2');
        Assert.AreEqual<Integer>(LDeclared[LIndex * 2 + 1], LInfo.DominantTris[LIndex].V3, LKey + 'v3');
        for LCount := 0 to 2 do
          LActual[LIndex * 3 + LCount] := LInfo.DominantTris[LIndex].NormalizationScale[LCount];
      end;
      CheckFloats(LKey + 'scale', LExpected, LActual);
    end
    else
      Assert.AreEqual<Integer>(0, Length(LInfo.DominantTris), LKey + 'dominanti attesi vuoti');

    SetLength(LVerts, LInfo.NumOutputVerts);
    for LIndex := 0 to LInfo.NumSourceVerts - 1 do
      LVerts[LIndex] := LSource[LIndex];
    LBase := LInfo.NumOutputVerts - LInfo.NumMirroredVerts;
    for LIndex := 0 to LInfo.NumMirroredVerts - 1 do
      LVerts[LBase + LIndex] := LVerts[LInfo.MirroredVerts[LIndex]];
    LPlanes := TStaticTangentDeriver.DeriveTangents(LVerts, LInfo.Indexes, LInfo.DupVerts, LInfo.DominantTris);

    SetLength(LActual, Length(LVerts) * 9);
    for LIndex := 0 to High(LVerts) do
    begin
      LActual[LIndex * 9] := LVerts[LIndex].Normal.X;
      LActual[LIndex * 9 + 1] := LVerts[LIndex].Normal.Y;
      LActual[LIndex * 9 + 2] := LVerts[LIndex].Normal.Z;
      LActual[LIndex * 9 + 3] := LVerts[LIndex].Tangents[0].X;
      LActual[LIndex * 9 + 4] := LVerts[LIndex].Tangents[0].Y;
      LActual[LIndex * 9 + 5] := LVerts[LIndex].Tangents[0].Z;
      LActual[LIndex * 9 + 6] := LVerts[LIndex].Tangents[1].X;
      LActual[LIndex * 9 + 7] := LVerts[LIndex].Tangents[1].Y;
      LActual[LIndex * 9 + 8] := LVerts[LIndex].Tangents[1].Z;
    end;
    CheckFloats(LKey + 'tangents', FGolden.Floats(LKey + 'tangents'), LActual);

    if LUnsmoothed = 0 then
    begin
      SetLength(LActual, Length(LPlanes) * 4);
      for LIndex := 0 to High(LPlanes) do
      begin
        LActual[LIndex * 4] := LPlanes[LIndex].A;
        LActual[LIndex * 4 + 1] := LPlanes[LIndex].B;
        LActual[LIndex * 4 + 2] := LPlanes[LIndex].C;
        LActual[LIndex * 4 + 3] := LPlanes[LIndex].D;
      end;
      CheckFloats(ACase + ' planes', FGolden.Floats(ACase + ' planes'), LActual);

      LPlanes := TStaticTangentDeriver.DeriveFacePlanes(LVerts, LInfo.Indexes);
      SetLength(LActual, Length(LPlanes) * 4);
      for LIndex := 0 to High(LPlanes) do
      begin
        LActual[LIndex * 4] := LPlanes[LIndex].A;
        LActual[LIndex * 4 + 1] := LPlanes[LIndex].B;
        LActual[LIndex * 4 + 2] := LPlanes[LIndex].C;
        LActual[LIndex * 4 + 3] := LPlanes[LIndex].D;
      end;
      CheckFloats(ACase + ' faceplanes', FGolden.Floats(ACase + ' faceplanes'), LActual);

      TStaticTangentDeriver.DeriveTangentsWithoutNormals(LVerts, LInfo.Indexes);
      SetLength(LActual, Length(LVerts) * 6);
      for LIndex := 0 to High(LVerts) do
      begin
        LActual[LIndex * 6] := LVerts[LIndex].Tangents[0].X;
        LActual[LIndex * 6 + 1] := LVerts[LIndex].Tangents[0].Y;
        LActual[LIndex * 6 + 2] := LVerts[LIndex].Tangents[0].Z;
        LActual[LIndex * 6 + 3] := LVerts[LIndex].Tangents[1].X;
        LActual[LIndex * 6 + 4] := LVerts[LIndex].Tangents[1].Y;
        LActual[LIndex * 6 + 5] := LVerts[LIndex].Tangents[1].Z;
      end;
      CheckFloats(ACase + ' nonormals', FGolden.Floats(ACase + ' nonormals'), LActual);
    end;
  end;
end;

procedure TTestDeformParity.DovrebbeRiprodurreLaStrisciaConLaTexturaSpecchiata;
begin
  CheckCase('mirror');
end;

procedure TTestDeformParity.DovrebbeRiprodurreIlCubo;
begin
  CheckCase('cube');
end;

procedure TTestDeformParity.DovrebbeRiprodurreLaGriglia;
begin
  CheckCase('grid');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeformParity);

end.
