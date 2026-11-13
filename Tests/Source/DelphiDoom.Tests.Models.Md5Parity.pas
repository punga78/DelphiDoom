{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - MD5 parity with the C++        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md5Parity;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Tests.Models.Md5Golden;

type
  /// <summary>
  ///   The synthetic cube (Tests\Data\Models\md5) read by the classes against the output of the
  ///   real idTech 4 code (idLexer, idMat3, idQuat, idJointMat, idSIMD_Generic and the
  ///   functions of idMD5Anim compiled with bcc32c). Tolerance: see TMd5Golden.Close.
  /// </summary>
  [TestFixture]
  [Category('Md5')]
  TTestMd5Parity = class
  strict private
    FGolden: TMd5Golden;
    FModel: IMd5Model;
    FAnim: IMd5Anim;
    procedure CheckFloats(const AKey: string; const AActual: TArray<Single>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLaPosaPredefinitaRelativaAiGenitori;
    [Test]
    procedure DovrebbeDareLeMatriciAssolute;
    [Test]
    procedure DovrebbeDareIPesiPrescalati;
    [Test]
    procedure DovrebbeDareIVerticiNellaPosaDiRiferimento;
    [Test]
    procedure DovrebbeDareLeBoundsDelModello;
    [Test]
    procedure DovrebbeDareIlGiuntoPiuVicinoComeLOriginale;
    [Test]
    procedure DovrebbeLeggereLeIntestazioniDellAnimazione;
    [Test]
    procedure DovrebbeDareIFotogrammiDiGetFrameBlend;
    [Test]
    procedure DovrebbeConvertireIlTempoInFotogrammi;
    [Test]
    procedure DovrebbeDareOrigineERotazioneDellaRadice;
    [Test]
    procedure DovrebbeDareLeBoundsDellAnimazione;
    [Test]
    procedure DovrebbeInterpolareIGiunti;
    [Test]
    procedure DovrebbeDareLoScheletroInCoordinateAssolute;
    [Test]
    procedure DovrebbeDareIVerticiDelleMeshPerOgniTempo;
    [Test]
    procedure DovrebbeDareIFotogrammiSingoli;
    [Test]
    procedure DovrebbeFareIlGiroDelleMatriciDelleMatriciDiPosa;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Factory;

const
  TIMES: array[0..13] of Integer = (-5, 0, 1, 20, 41, 42, 63, 83, 84, 100, 125, 500, 1000, 2500);
  CYCLES: array[0..2] of Integer = (0, 1, 3);

function QuatsToFloats(const AJoints: TArray<TMd5JointQuat>): TArray<Single>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AJoints) * 7);
  for LIndex := 0 to High(AJoints) do
  begin
    Result[LIndex * 7 + 0] := AJoints[LIndex].Q.X;
    Result[LIndex * 7 + 1] := AJoints[LIndex].Q.Y;
    Result[LIndex * 7 + 2] := AJoints[LIndex].Q.Z;
    Result[LIndex * 7 + 3] := AJoints[LIndex].Q.W;
    Result[LIndex * 7 + 4] := AJoints[LIndex].T.X;
    Result[LIndex * 7 + 5] := AJoints[LIndex].T.Y;
    Result[LIndex * 7 + 6] := AJoints[LIndex].T.Z;
  end;
end;

function MatsToFloats(const AMatrices: TArray<TMd5JointMat>): TArray<Single>;
var
  LIndex, LElement: Integer;
begin
  SetLength(Result, Length(AMatrices) * 12);
  for LIndex := 0 to High(AMatrices) do
    for LElement := 0 to 11 do
      Result[LIndex * 12 + LElement] := AMatrices[LIndex].M[LElement];
end;

function VertsToFloats(const AVerts: TArray<TIdVec3>): TArray<Single>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AVerts) * 3);
  for LIndex := 0 to High(AVerts) do
  begin
    Result[LIndex * 3] := AVerts[LIndex].X;
    Result[LIndex * 3 + 1] := AVerts[LIndex].Y;
    Result[LIndex * 3 + 2] := AVerts[LIndex].Z;
  end;
end;

function BoundsToFloats(const ABounds: TGeoBounds): TArray<Single>;
begin
  Result := [ABounds.Mins.X, ABounds.Mins.Y, ABounds.Mins.Z, ABounds.Maxs.X, ABounds.Maxs.Y, ABounds.Maxs.Z];
end;

{ TTestMd5Parity }

procedure TTestMd5Parity.Setup;
begin
  FGolden := TMd5Golden.Create;
  FModel := TMd5Factory.CreateModelParser.Parse(TMd5Golden.ReadText('cube.md5mesh'), 'cube.md5mesh');
  FAnim := TMd5Factory.CreateAnimParser.Parse(TMd5Golden.ReadText('cube.md5anim'), 'cube.md5anim');
end;

procedure TTestMd5Parity.TearDown;
begin
  FAnim := nil;
  FModel := nil;
  FGolden.Free;
end;

procedure TTestMd5Parity.CheckFloats(const AKey: string; const AActual: TArray<Single>);
var
  LExpected: TArray<Single>;
  LIndex: Integer;
begin
  LExpected := FGolden.Floats(AKey);
  Assert.AreEqual<Integer>(Length(LExpected), Length(AActual), AKey + ': numero di valori');
  for LIndex := 0 to High(LExpected) do
    Assert.IsTrue(TMd5Golden.Close(LExpected[LIndex], AActual[LIndex]),
      Format('%s[%d]: atteso %s, ottenuto %s', [AKey, LIndex, TMd5Golden.Describe(LExpected[LIndex]),
      TMd5Golden.Describe(AActual[LIndex])]));
end;

procedure TTestMd5Parity.DovrebbeDareLaPosaPredefinitaRelativaAiGenitori;
var
  LIndex: Integer;
  LPose: TArray<TMd5JointQuat>;
begin
  LPose := FModel.DefaultPose;
  for LIndex := 0 to FModel.NumJoints - 1 do
    CheckFloats('pose ' + IntToStr(LIndex), QuatsToFloats([LPose[LIndex]]));
end;

procedure TTestMd5Parity.DovrebbeDareLeMatriciAssolute;
var
  LIndex: Integer;
  LMatrices: TArray<TMd5JointMat>;
begin
  LMatrices := FModel.ReferenceMatrices;
  for LIndex := 0 to FModel.NumJoints - 1 do
    CheckFloats('abs ' + IntToStr(LIndex), MatsToFloats([LMatrices[LIndex]]));
end;

procedure TTestMd5Parity.DovrebbeDareIPesiPrescalati;
var
  LMesh: IMd5Mesh;
  LIndex: Integer;
  LExpectedInts: TArray<Integer>;
begin
  LMesh := FModel.Meshes[0];
  Assert.AreEqual<Integer>(12, LMesh.NumWeights);
  for LIndex := 0 to LMesh.NumWeights - 1 do
  begin
    CheckFloats('weight ' + IntToStr(LIndex), [LMesh.ScaledWeights[LIndex].X, LMesh.ScaledWeights[LIndex].Y,
      LMesh.ScaledWeights[LIndex].Z, LMesh.ScaledWeights[LIndex].W]);
    LExpectedInts := FGolden.Ints('weight ' + IntToStr(LIndex));
    Assert.AreEqual<Integer>(LExpectedInts[0], LMesh.WeightJoints[LIndex], 'giunto del peso ' + IntToStr(LIndex));
    Assert.AreEqual<Integer>(LExpectedInts[1], Ord(LMesh.WeightEndsVertex[LIndex]), 'fine vertice ' + IntToStr(LIndex));
  end;
end;

procedure TTestMd5Parity.DovrebbeDareIVerticiNellaPosaDiRiferimento;
var
  LVerts: TArray<TIdVec3>;
  LIndex: Integer;
begin
  LVerts := FModel.Meshes[0].TransformVerts(FModel.ReferenceMatrices);
  Assert.AreEqual<Integer>(8, Length(LVerts));
  for LIndex := 0 to High(LVerts) do
    CheckFloats('ref ' + IntToStr(LIndex), VertsToFloats([LVerts[LIndex]]));
end;

procedure TTestMd5Parity.DovrebbeDareLeBoundsDelModello;
begin
  CheckFloats('bounds', BoundsToFloats(FModel.Bounds));
end;

procedure TTestMd5Parity.DovrebbeDareIlGiuntoPiuVicinoComeLOriginale;
const
  CASES: array[0..8] of array[0..2] of Integer =
    ((0, -1, -1), (3, -1, -1), (4, -1, -1), (5, -1, -1), (-1, 6, -1), (-1, -1, 7), (-1, -1, -1), (9, 2, 3), (1, 2, 3));
var
  LIndex: Integer;
  LExpected: TArray<Integer>;
begin
  for LIndex := 0 to High(CASES) do
  begin
    LExpected := FGolden.Ints(Format('nearest %d %d', [CASES[LIndex][0], CASES[LIndex][1]]));
    Assert.AreEqual<Integer>(LExpected[1], FModel.NearestJoint(0, CASES[LIndex][0], CASES[LIndex][1],
      CASES[LIndex][2]), Format('nearest %d %d %d', [CASES[LIndex][0], CASES[LIndex][1], CASES[LIndex][2]]));
  end;
end;

procedure TTestMd5Parity.DovrebbeLeggereLeIntestazioniDellAnimazione;
var
  LExpected: TArray<Integer>;
  LIndex, LFrame: Integer;
begin
  LExpected := FGolden.Ints('anim');
  Assert.AreEqual<Integer>(LExpected[0], FAnim.NumFrames, 'fotogrammi');
  Assert.AreEqual<Integer>(LExpected[1], FAnim.NumJoints, 'giunti');
  Assert.AreEqual<Integer>(LExpected[2], FAnim.FrameRate, 'frame rate');
  Assert.AreEqual<Integer>(LExpected[3], FAnim.Length, 'lunghezza');
  CheckFloats('delta', [FAnim.TotalMovementDelta.X, FAnim.TotalMovementDelta.Y, FAnim.TotalMovementDelta.Z]);
  for LIndex := 0 to FAnim.NumJoints - 1 do
    CheckFloats('base ' + IntToStr(LIndex), QuatsToFloats([FAnim.BaseFrame[LIndex]]));
  for LFrame := 0 to FAnim.NumFrames - 1 do
    CheckFloats('fbounds ' + IntToStr(LFrame), BoundsToFloats(FAnim.FrameBounds[LFrame]));
end;

procedure TTestMd5Parity.DovrebbeDareIFotogrammiDiGetFrameBlend;
var
  LFrame: Integer;
  LBlend: TMd5FrameBlend;
  LExpected: TArray<Integer>;
begin
  for LFrame := -1 to FAnim.NumFrames + 1 do
  begin
    LBlend := FAnim.GetFrameBlend(LFrame);
    LExpected := FGolden.Ints('fblend ' + IntToStr(LFrame));
    Assert.AreEqual<Integer>(LExpected[0], LBlend.CycleCount);
    Assert.AreEqual<Integer>(LExpected[1], LBlend.Frame1);
    Assert.AreEqual<Integer>(LExpected[2], LBlend.Frame2);
    CheckFloats('fblend ' + IntToStr(LFrame), [LBlend.FrontLerp, LBlend.BackLerp]);
  end;
end;

procedure TTestMd5Parity.DovrebbeConvertireIlTempoInFotogrammi;
var
  LTime, LCycle: Integer;
  LBlend: TMd5FrameBlend;
  LKey: string;
  LExpected: TArray<Integer>;
begin
  for LTime in TIMES do
    for LCycle in CYCLES do
    begin
      LKey := Format('blend %d %d', [LTime, LCycle]);
      LBlend := FAnim.ConvertTimeToFrame(LTime, LCycle);
      LExpected := FGolden.Ints(LKey);
      Assert.AreEqual<Integer>(LExpected[0], LBlend.CycleCount, LKey + ' cicli');
      Assert.AreEqual<Integer>(LExpected[1], LBlend.Frame1, LKey + ' fotogramma 1');
      Assert.AreEqual<Integer>(LExpected[2], LBlend.Frame2, LKey + ' fotogramma 2');
      CheckFloats(LKey, [LBlend.FrontLerp, LBlend.BackLerp]);
    end;
end;

procedure TTestMd5Parity.DovrebbeDareOrigineERotazioneDellaRadice;
var
  LTime, LCycle: Integer;
  LOrigin: TIdVec3;
  LRotation: TIdQuat;
begin
  for LTime in TIMES do
    for LCycle in CYCLES do
    begin
      LOrigin := FAnim.GetOrigin(LTime, LCycle);
      CheckFloats(Format('origin %d %d', [LTime, LCycle]), [LOrigin.X, LOrigin.Y, LOrigin.Z]);
      LRotation := FAnim.GetOriginRotation(LTime, LCycle);
      CheckFloats(Format('originrot %d %d', [LTime, LCycle]), [LRotation.X, LRotation.Y, LRotation.Z, LRotation.W]);
    end;
end;

procedure TTestMd5Parity.DovrebbeDareLeBoundsDellAnimazione;
var
  LTime, LCycle: Integer;
begin
  for LTime in TIMES do
    for LCycle in CYCLES do
      CheckFloats(Format('abounds %d %d', [LTime, LCycle]), BoundsToFloats(FAnim.GetBounds(LTime, LCycle)));
end;

procedure TTestMd5Parity.DovrebbeInterpolareIGiunti;
var
  LTime, LCycle: Integer;
begin
  for LTime in TIMES do
    for LCycle in CYCLES do
      CheckFloats(Format('interp %d %d', [LTime, LCycle]),
        QuatsToFloats(FAnim.GetInterpolatedFrame(FAnim.ConvertTimeToFrame(LTime, LCycle), nil)));
end;

procedure TTestMd5Parity.DovrebbeDareLoScheletroInCoordinateAssolute;
var
  LTime, LCycle: Integer;
begin
  for LTime in TIMES do
    for LCycle in CYCLES do
      CheckFloats(Format('world %d %d', [LTime, LCycle]),
        MatsToFloats(FModel.Skeleton.ToAbsolute(
          FAnim.GetInterpolatedFrame(FAnim.ConvertTimeToFrame(LTime, LCycle), nil))));
end;

procedure TTestMd5Parity.DovrebbeDareIVerticiDelleMeshPerOgniTempo;
var
  LTime, LCycle: Integer;
begin
  for LTime in TIMES do
    for LCycle in CYCLES do
      CheckFloats(Format('verts %d %d', [LTime, LCycle]),
        VertsToFloats(FModel.Meshes[0].TransformVerts(FModel.Skeleton.ToAbsolute(
          FAnim.GetInterpolatedFrame(FAnim.ConvertTimeToFrame(LTime, LCycle), nil)))));
end;

procedure TTestMd5Parity.DovrebbeDareIFotogrammiSingoli;
var
  LFrame: Integer;
begin
  for LFrame := 0 to FAnim.NumFrames - 1 do
    CheckFloats('single ' + IntToStr(LFrame), QuatsToFloats(FAnim.GetSingleFrame(LFrame, nil)));
end;

procedure TTestMd5Parity.DovrebbeFareIlGiroDelleMatriciDelleMatriciDiPosa;
var
  LMatrices: TArray<TMd5JointMat>;
begin
  LMatrices := FModel.Skeleton.ConvertToMatrices(FModel.DefaultPose);
  FModel.Skeleton.TransformJoints(LMatrices, 1, FModel.NumJoints - 1);
  CheckFloats('defworld', MatsToFloats(LMatrices));
  FModel.Skeleton.UntransformJoints(LMatrices, 1, FModel.NumJoints - 1);
  CheckFloats('defuntrans', MatsToFloats(LMatrices));
  CheckFloats('matquats', QuatsToFloats(FModel.Skeleton.ConvertToQuats(FModel.ReferenceMatrices)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMd5Parity);

end.
