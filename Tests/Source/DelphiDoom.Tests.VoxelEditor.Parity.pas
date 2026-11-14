{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the voxel editor with the old DD_VOXEL (issue #167)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Parity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model,
  DelphiDoom.Tests.VoxelEditor.Scenarios;

type
  /// <summary>
  ///   The answers of the OLD code of DD_VOXEL (units of the original program compiled in a harness, Tools\Verifica\167)
  ///   to the scenarios of TVoxelScenarios, in Tests\Data\VoxelEditor\voxel.golden.txt, against the library
  /// </summary>
  [TestFixture]
  [Category('voxeleditor,parity')]
  TTestVoxelEditorParity = class(TObject)
  strict private
    FLines: TStringList;
    function Golden(const AKey: string): string;
    function NewModel(AIndex: Integer): TVoxelEditorModel;
    function ModelHash(const AModel: TVoxelEditorModel): string;
    class function FileNameOfGolden: string; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeStessePalettedeiGiochi;
    [Test]
    procedure DovrebbeDareLeStesseViste;
    [Test]
    procedure DovrebbeDareLeStesseProfondita;
    [Test]
    procedure DovrebbeDareGliStessiPuntatoriDelleSonde;
    [Test]
    procedure DovrebbeDipingereUnaVistaComeIlVecchio;
    [Test]
    procedure DovrebbeLeggereEScrivereIPianiComeIlVecchio;
    [Test]
    procedure DovrebbeSpecchiareEGirareIPianiComeIlVecchio;
    [Test]
    procedure DovrebbeTogliereIVoxelNonVisibiliComeIlVecchio;
    [Test]
    procedure DovrebbeTagliareEStringereLAltezzaComeIlVecchio;
    [Test]
    procedure DovrebbeFareLaScalaDiGrigiComeIlVecchio;
    [Test]
    procedure DovrebbeContareIColoriComeIlVecchio;
    [Test]
    procedure DovrebbeRidurreAUnaPalettaComeIlVecchio;
    [Test]
    procedure DovrebbeApplicareUnaTexturaAlTerrenoComeIlVecchio;
    [Test]
    procedure DovrebbeFareLaMappaDelleAltezzeComeIlVecchio;
    [Test]
    procedure DovrebbeRuotareIlVoxelComeIlVecchio;
    [Test]
    procedure DovrebbeRuotareIlVoxelInAltaQualitaComeIlVecchio;
    [Test]
    procedure DovrebbeQuantizzareIColoriComeIlVecchio;
    [Test]
    procedure DovrebbeFareLaMeshComeIlVecchioDoveIlVecchioNonSbagliava;
    [Test]
    procedure DovrebbeFareLaMeshDelVecchioConLaCorrezioneDelCompattamento;
    [Test]
    procedure DovrebbeLeggereUnaMeshComeIlVecchio;
    [Test]
    procedure DovrebbeScrivereEIlVoxDelVecchio;
    [Test]
    procedure DovrebbeScrivereEIlDdvoxDelVecchio;
    [Test]
    procedure DovrebbeLeggereIlDdvoxDelVecchio;
    [Test]
    procedure DovrebbeLeggereIKvxDelVecchio;
    [Test]
    procedure DovrebbeLeggereIVoxDelVecchio;
  end;

implementation

uses
  System.Math,
  DelphiDoom.VoxelEditor.Views,
  DelphiDoom.VoxelEditor.Planes,
  DelphiDoom.VoxelEditor.Transforms,
  DelphiDoom.VoxelEditor.Operations,
  DelphiDoom.VoxelEditor.Rotator,
  DelphiDoom.VoxelEditor.Palettes,
  DelphiDoom.VoxelEditor.Quantizer,
  DelphiDoom.VoxelEditor.MeshOptimizer,
  DelphiDoom.VoxelEditor.Format.Ddvox,
  DelphiDoom.VoxelEditor.Format.Kvx,
  DelphiDoom.VoxelEditor.Format.Vox,
  DelphiDoom.VoxelEditor.Format.Ddmesh,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.MathCore.SoftExtended;

// ADegrees / 360 * (2 * Pi) as the 32 bit compiler computes it: in Extended (Pi has 64 bits of mantissa) and rounded
// to a Double when it is passed. At 64 bit Extended is a Double, which gives an angle one ULP away (and the sine of
// 30 degrees is no longer 0.5): the same operations are done in software
function RotationAngle(ADegrees: Integer): Double;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := ADegrees / 360 * (2 * Pi);
end;
{$ELSE}
var
  LTwoPi: TSoftExtended;
begin
  // Pi as the 32 bit compiler has it: $C90FDAA22168C235 * 2^-62
  LTwoPi := TSoftExtended.FromMantissa($C90FDAA22168C235, -62) * TSoftExtended.FromInt64(2);
  Result := (TSoftExtended.FromInt64(ADegrees) / TSoftExtended.FromInt64(360) * LTwoPi).ToDouble;
end;
{$IFEND}

{ TTestVoxelEditorParity }

class function TTestVoxelEditorParity.FileNameOfGolden: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\VoxelEditor\voxel.golden.txt');
end;

procedure TTestVoxelEditorParity.Setup;
begin
  FLines := TStringList.Create;
  FLines.LoadFromFile(FileNameOfGolden);
end;

procedure TTestVoxelEditorParity.TearDown;
begin
  FLines.Free;
end;

// the text that follows a key on its line of the golden file
function TTestVoxelEditorParity.Golden(const AKey: string): string;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FLines.Count - 1 do
    if FLines[LIndex].StartsWith(AKey + ' ') then
      Exit(Copy(FLines[LIndex], Length(AKey) + 2, MaxInt));
  Assert.Fail('The golden file has no line "' + AKey + '"');
  Result := '';
end;

function TTestVoxelEditorParity.NewModel(AIndex: Integer): TVoxelEditorModel;
var
  LCells: TArray<Cardinal>;
begin
  Result := TVoxelEditorModel.Create(TVoxelScenarios.ModelSize(AIndex));
  LCells := TVoxelScenarios.ModelCells(AIndex);
  Move(LCells[0], Result.Cells[0], Length(LCells) * SizeOf(Cardinal));
end;

function TTestVoxelEditorParity.ModelHash(const AModel: TVoxelEditorModel): string;
begin
  Result := TVoxelScenarios.Digest(AModel.Cells);
end;

procedure TTestVoxelEditorParity.DovrebbeDareLeStessePalettedeiGiochi;
const
  NAMES: array[TGamePalette] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE', 'RADIX', '');
var
  LGame: TGamePalette;
begin
  for LGame := gpDoom to gpRadix do
    Assert.AreEqual(Golden('palraw ' + NAMES[LGame]), TVoxelScenarios.DigestBytes(TGamePalettes.Colors(LGame)), NAMES[LGame]);
end;

procedure TTestVoxelEditorParity.DovrebbeDareLeStesseViste;
var
  LModelIndex, LView: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      for LView := 1 to 6 do
        Assert.AreEqual(Golden(Format('view %s %d', [TVoxelScenarios.ModelName(LModelIndex), LView])),
          TVoxelScenarios.Digest(TVoxelEditorViews.GetView(LModel, TVoxelEditorView(LView))),
          TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(LView));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeDareLeStesseProfondita;
var
  LModelIndex, LView, LIndex: Integer;
  LModel: TVoxelEditorModel;
  LDepth: TArray<TVoxelEditorDepthItem>;
  LItems: TArray<Cardinal>;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      for LView := 1 to 6 do
      begin
        LDepth := TVoxelEditorViews.GetDepthView(LModel, TVoxelEditorView(LView));
        SetLength(LItems, Length(LDepth) * 3);
        for LIndex := 0 to High(LDepth) do
        begin
          LItems[LIndex * 3] := LDepth[LIndex].Color;
          LItems[LIndex * 3 + 1] := LDepth[LIndex].Depth;
          LItems[LIndex * 3 + 2] := Cardinal(LDepth[LIndex].Previous + 1);
        end;
        Assert.AreEqual(Golden(Format('depth %s %d', [TVoxelScenarios.ModelName(LModelIndex), LView])),
          TVoxelScenarios.Digest(LItems), TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(LView));
      end;
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeDareGliStessiPuntatoriDelleSonde;
var
  LModelIndex, LView, LX, LY, LZ, LSize, LStep: Integer;
  LModel: TVoxelEditorModel;
  LIndexes: TArray<Integer>;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      LSize := LModel.Size;
      LStep := 1;
      if LSize > 64 then
        LStep := 5;
      for LView := 1 to 6 do
      begin
        LIndexes := nil;
        LX := -3;
        while LX < LSize + 6 do
        begin
          LY := -2;
          while LY < LSize + 5 do
          begin
            SetLength(LIndexes, Length(LIndexes) + 4);
            LIndexes[High(LIndexes) - 3] := TVoxelEditorViews.DepthIndexAtXY(LModel, LX, LY, TVoxelEditorView(LView));
            for LZ := 0 to 2 do
              LIndexes[High(LIndexes) - 2 + LZ] :=
                TVoxelEditorViews.DepthIndexAtXYZ(LModel, LX, LY, (LZ * (LSize - 1)) div 2, TVoxelEditorView(LView));
            Inc(LY, LStep * 3 + 1);
          end;
          Inc(LX, LStep * 3 + 2);
        end;
        Assert.AreEqual(Golden(Format('probe %s %d', [TVoxelScenarios.ModelName(LModelIndex), LView])),
          TVoxelScenarios.DigestIntegers(LIndexes), TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(LView));
      end;
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeDipingereUnaVistaComeIlVecchio;
var
  LModelIndex, LView: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
    for LView := 1 to 6 do
    begin
      LModel := NewModel(LModelIndex);
      try
        TVoxelEditorViews.SetView(LModel, TVoxelEditorView(LView), TVoxelScenarios.ProbeImage(LModel.Size, LView));
        Assert.AreEqual(Golden(Format('setview %s %d', [TVoxelScenarios.ModelName(LModelIndex), LView])),
          ModelHash(LModel), TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(LView));
      finally
        LModel.Free;
      end;
    end;
end;

// the planes of the scenarios: 0, 1, 2 are the slices x, y and z and 3.. the six views (the kind of the harness is 2 + the view)
function PlaneOfKind(AKind, ASize: Integer): TVoxelEditorPlane;
begin
  case AKind of
    0: Result := TVoxelEditorPlane.Slice(veaX, ASize div 2);
    1: Result := TVoxelEditorPlane.Slice(veaY, ASize div 3);
    2: Result := TVoxelEditorPlane.Slice(veaZ, 1);
  else
    Result := TVoxelEditorPlane.OfView(TVoxelEditorView(AKind - 2));
  end;
end;

function KindName(AKind: Integer): string;
begin
  case AKind of
    0: Result := 'x';
    1: Result := 'y';
    2: Result := 'z';
  else
    Result := 'view' + IntToStr(AKind - 2);
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeLeggereEScrivereIPianiComeIlVecchio;
var
  LModelIndex, LKind: Integer;
  LModel: TVoxelEditorModel;
  LPlane: TVoxelEditorPlane;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 64 then
      Continue;
    for LKind := 0 to 8 do
    begin
      LModel := NewModel(LModelIndex);
      try
        LPlane := PlaneOfKind(LKind, LModel.Size);
        Assert.AreEqual(Golden(Format('getplane %s %s', [TVoxelScenarios.ModelName(LModelIndex), KindName(LKind)])),
          TVoxelScenarios.Digest(TVoxelEditorPlanes.Read(LModel, LPlane)), 'get');
        TVoxelEditorPlanes.Erase(LModel, LPlane);
        Assert.AreEqual(Golden(Format('erase %s %s', [TVoxelScenarios.ModelName(LModelIndex), KindName(LKind)])),
          ModelHash(LModel), 'erase');
      finally
        LModel.Free;
      end;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeSpecchiareEGirareIPianiComeIlVecchio;
const
  OPS: array[0..3] of string = ('flipH', 'flipV', 'rotL', 'rotR');
var
  LModelIndex, LKind, LOp: Integer;
  LModel: TVoxelEditorModel;
  LPlane: TVoxelEditorPlane;
  LImage: TVoxelEditorImage;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 64 then
      Continue;
    for LKind := 0 to 8 do
      for LOp := 0 to 3 do
      begin
        LModel := NewModel(LModelIndex);
        try
          LPlane := PlaneOfKind(LKind, LModel.Size);
          LImage := TVoxelEditorPlanes.Read(LModel, LPlane);
          case LOp of
            0: LImage := TVoxelEditorTransforms.FlipHorizontal(LImage, LModel.Size);
            1: LImage := TVoxelEditorTransforms.FlipVertical(LImage, LModel.Size);
            2: LImage := TVoxelEditorTransforms.RotateCounterClockwise(LImage, LModel.Size);
          else
            LImage := TVoxelEditorTransforms.RotateClockwise(LImage, LModel.Size);
          end;
          TVoxelEditorPlanes.Write(LModel, LPlane, LImage);
          Assert.AreEqual(Golden(Format('plane %s %s %s', [TVoxelScenarios.ModelName(LModelIndex), KindName(LKind), OPS[LOp]])),
            ModelHash(LModel), TVoxelScenarios.ModelName(LModelIndex) + ' ' + KindName(LKind) + ' ' + OPS[LOp]);
        finally
          LModel.Free;
        end;
      end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeTogliereIVoxelNonVisibiliComeIlVecchio;
var
  LModelIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      TVoxelEditorOperations.RemoveNonVisible(LModel);
      Assert.AreEqual(Golden('nonvisible ' + TVoxelScenarios.ModelName(LModelIndex)), ModelHash(LModel),
        TVoxelScenarios.ModelName(LModelIndex));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeTagliareEStringereLAltezzaComeIlVecchio;
const
  CROPS: array[0..5, 0..1] of Integer = ((0, 255), (10, 200), (64, 128), (100, 100), (200, 50), (255, 255));
  SHRINKS: array[0..6, 0..1] of Integer = ((10, 200), (64, 128), (0, 100), (50, 255), (200, 50), (0, 0), (255, 255));
var
  LModelIndex, LIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    for LIndex := 0 to High(CROPS) do
    begin
      LModel := NewModel(LModelIndex);
      try
        TVoxelEditorOperations.CropHeight(LModel, CROPS[LIndex, 0], CROPS[LIndex, 1]);
        Assert.AreEqual(Golden(Format('crop %s %d-%d', [TVoxelScenarios.ModelName(LModelIndex), CROPS[LIndex, 0],
          CROPS[LIndex, 1]])), ModelHash(LModel), 'crop ' + TVoxelScenarios.ModelName(LModelIndex));
      finally
        LModel.Free;
      end;
    end;
    for LIndex := 0 to High(SHRINKS) do
    begin
      if (TVoxelScenarios.ModelSize(LModelIndex) < 256) and (SHRINKS[LIndex, 0] >= 255) then
        Continue;
      LModel := NewModel(LModelIndex);
      try
        TVoxelEditorOperations.ShrinkHeight(LModel, SHRINKS[LIndex, 0], SHRINKS[LIndex, 1]);
        Assert.AreEqual(Golden(Format('shrink %s %d-%d', [TVoxelScenarios.ModelName(LModelIndex), SHRINKS[LIndex, 0],
          SHRINKS[LIndex, 1]])), ModelHash(LModel), 'shrink ' + TVoxelScenarios.ModelName(LModelIndex));
      finally
        LModel.Free;
      end;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeFareLaScalaDiGrigiComeIlVecchio;
var
  LModelIndex: Integer;
  LModel: TVoxelEditorModel;
  LChanged: Boolean;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      LChanged := TVoxelEditorOperations.ToGrayScale(LModel);
      Assert.AreEqual(Golden('gray ' + TVoxelScenarios.ModelName(LModelIndex)),
        IntToStr(Ord(LChanged)) + ' ' + ModelHash(LModel), TVoxelScenarios.ModelName(LModelIndex));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeContareIColoriComeIlVecchio;
var
  LModelIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      Assert.AreEqual(Golden('count ' + TVoxelScenarios.ModelName(LModelIndex)),
        IntToStr(TVoxelEditorOperations.CountColors(LModel)), TVoxelScenarios.ModelName(LModelIndex));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeRidurreAUnaPalettaComeIlVecchio;
const
  KINDS: array[0..1] of TVoxelEditorPaletteKind = (vepDoom, vepHeretic);
  NAMES: array[0..1] of string = ('DOOM', 'HERETIC');
var
  LModelIndex, LIndex: Integer;
  LModel: TVoxelEditorModel;
  LChanged: Boolean;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
    for LIndex := 0 to 1 do
    begin
      LModel := NewModel(LModelIndex);
      try
        LChanged := TVoxelEditorOperations.ApplyPalette(LModel, TVoxelEditorPalettes.OfGame(KINDS[LIndex]));
        Assert.AreEqual(Golden(Format('applypal %s %s', [TVoxelScenarios.ModelName(LModelIndex), NAMES[LIndex]])),
          IntToStr(Ord(LChanged)) + ' ' + ModelHash(LModel), TVoxelScenarios.ModelName(LModelIndex) + ' ' + NAMES[LIndex]);
      finally
        LModel.Free;
      end;
    end;
end;

procedure TTestVoxelEditorParity.DovrebbeApplicareUnaTexturaAlTerrenoComeIlVecchio;
var
  LModelIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      TVoxelEditorOperations.ApplyTerrainTexture(LModel, TVoxelScenarios.ProbeImage(LModel.Size, 77, 10));
      Assert.AreEqual(Golden('terrain ' + TVoxelScenarios.ModelName(LModelIndex)), ModelHash(LModel),
        TVoxelScenarios.ModelName(LModelIndex));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeFareLaMappaDelleAltezzeComeIlVecchio;
const
  SIZES: array[0..3] of Integer = (16, 32, 64, 256);
var
  LIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LIndex := 0 to High(SIZES) do
  begin
    LModel := TVoxelEditorModel.Create(SIZES[LIndex]);
    try
      TVoxelEditorOperations.BuildHeightmap(LModel, TVoxelScenarios.ProbeImage(SIZES[LIndex], 31, 15));
      Assert.AreEqual(Golden('heightmap ' + IntToStr(SIZES[LIndex])), ModelHash(LModel), IntToStr(SIZES[LIndex]));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeRuotareIlVoxelComeIlVecchio;
const
  DEGREES: array[0..5] of Integer = (0, 30, 45, 90, 133, -20);
var
  LModelIndex, LIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 64 then
      Continue;
    for LIndex := 0 to High(DEGREES) do
    begin
      LModel := NewModel(LModelIndex);
      try
        TVoxelEditorRotator.Rotate(LModel, RotationAngle(DEGREES[LIndex]));
        Assert.AreEqual(Golden(Format('rotate %s %d', [TVoxelScenarios.ModelName(LModelIndex), DEGREES[LIndex]])),
          ModelHash(LModel), TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(DEGREES[LIndex]));
      finally
        LModel.Free;
      end;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeRuotareIlVoxelInAltaQualitaComeIlVecchio;
const
  DEGREES: array[0..5] of Integer = (0, 30, 45, 90, 133, -20);
var
  LModelIndex, LIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 32 then
      Continue;
    for LIndex := 0 to High(DEGREES) do
    begin
      LModel := NewModel(LModelIndex);
      try
        TVoxelEditorRotator.RotateHighQuality(LModel, RotationAngle(DEGREES[LIndex]));
        Assert.AreEqual(Golden(Format('rotatehq %s %d', [TVoxelScenarios.ModelName(LModelIndex), DEGREES[LIndex]])),
          ModelHash(LModel), TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(DEGREES[LIndex]));
      finally
        LModel.Free;
      end;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeQuantizzareIColoriComeIlVecchio;
const
  COUNTS: array[0..2] of Integer = (255, 100, 16);
var
  LModelIndex, LIndex, LColor: Integer;
  LModel: TVoxelEditorModel;
  LPalette: TVoxelEditorPalette;
  LFlag: Boolean;
  LHash: TArray<Cardinal>;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
    for LIndex := 0 to High(COUNTS) do
    begin
      LModel := NewModel(LModelIndex);
      try
        FillChar(LPalette, SizeOf(LPalette), 0);
        LFlag := TVoxelEditorQuantizer.GetPalette(LModel, COUNTS[LIndex], LPalette);
        SetLength(LHash, 256);
        for LColor := 0 to 255 do
          LHash[LColor] := LPalette[LColor];
        Assert.AreEqual(Golden(Format('quantpal %s %d', [TVoxelScenarios.ModelName(LModelIndex), COUNTS[LIndex]])),
          IntToStr(Ord(LFlag)) + ' ' + TVoxelScenarios.Digest(LHash), 'palette ' + TVoxelScenarios.ModelName(LModelIndex));
        TVoxelEditorQuantizer.Quantize(LModel, COUNTS[LIndex]);
        Assert.AreEqual(Golden(Format('quantize %s %d', [TVoxelScenarios.ModelName(LModelIndex), COUNTS[LIndex]])),
          ModelHash(LModel), 'quantize ' + TVoxelScenarios.ModelName(LModelIndex));
      finally
        LModel.Free;
      end;
    end;
end;

procedure TTestVoxelEditorParity.DovrebbeFareLaMeshComeIlVecchioDoveIlVecchioNonSbagliava;
var
  LModelIndex, LPass: Integer;
  LModel: TVoxelEditorModel;
  LMesh: TVoxelEditorMeshOptimizer;
  LParts: TArray<string>;
  LChecked: Integer;
begin
  LChecked := 0;
  for LModelIndex := 1 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 64 then
      Continue;
    for LPass := 1 to 3 do
    begin
      // mesh name pass legacy-hash legacy-hits fixed-hash fixed-quads legacy-quads
      LParts := Golden(Format('mesh %s %d', [TVoxelScenarios.ModelName(LModelIndex), LPass])).Split([' ']);
      if LParts[1] <> '0' then
        Continue;
      LModel := NewModel(LModelIndex);
      LMesh := TVoxelEditorMeshOptimizer.Create;
      try
        LMesh.LoadVoxel(LModel);
        LMesh.PassCount := LPass;
        LMesh.Optimize;
        Assert.AreEqual(LParts[0], TVoxelScenarios.DigestBytes(LMesh.ToBytes),
          TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(LPass));
        Inc(LChecked);
      finally
        LMesh.Free;
        LModel.Free;
      end;
    end;
  end;
  // the old compaction was wrong in most of the cases: a few are enough to prove the rest
  Assert.IsTrue(LChecked >= 5, 'cases without the defect: ' + IntToStr(LChecked));
end;

procedure TTestVoxelEditorParity.DovrebbeFareLaMeshDelVecchioConLaCorrezioneDelCompattamento;
var
  LModelIndex, LPass: Integer;
  LModel: TVoxelEditorModel;
  LMesh: TVoxelEditorMeshOptimizer;
  LParts: TArray<string>;
begin
  for LModelIndex := 1 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 64 then
      Continue;
    for LPass := 1 to 3 do
    begin
      LParts := Golden(Format('mesh %s %d', [TVoxelScenarios.ModelName(LModelIndex), LPass])).Split([' ']);
      LModel := NewModel(LModelIndex);
      LMesh := TVoxelEditorMeshOptimizer.Create;
      try
        LMesh.LoadVoxel(LModel);
        LMesh.PassCount := LPass;
        LMesh.Optimize;
        Assert.AreEqual(LParts[2], TVoxelScenarios.DigestBytes(LMesh.ToBytes),
          TVoxelScenarios.ModelName(LModelIndex) + ' ' + IntToStr(LPass));
        Assert.AreEqual(StrToInt(LParts[3]), LMesh.QuadCount, 'quads');
      finally
        LMesh.Free;
        LModel.Free;
      end;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeLeggereUnaMeshComeIlVecchio;
var
  LModelIndex: Integer;
  LModel, LRead: TVoxelEditorModel;
  LMesh: TVoxelEditorMeshOptimizer;
  LParts: TArray<string>;
begin
  for LModelIndex := 1 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    if TVoxelScenarios.ModelSize(LModelIndex) > 64 then
      Continue;
    LParts := Golden('meshread ' + TVoxelScenarios.ModelName(LModelIndex)).Split([' ']);
    LModel := NewModel(LModelIndex);
    LRead := TVoxelEditorModel.Create(1);
    LMesh := TVoxelEditorMeshOptimizer.Create;
    try
      LMesh.LoadVoxel(LModel);
      LMesh.Optimize;
      TVoxelEditorDdmeshFormat.Read(LMesh.ToBytes, LRead);
      Assert.AreEqual(StrToInt(LParts[0]), LRead.Size, 'size');
      Assert.AreEqual(LParts[1], ModelHash(LRead), TVoxelScenarios.ModelName(LModelIndex));
    finally
      LMesh.Free;
      LRead.Free;
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeScrivereEIlVoxDelVecchio;
var
  LModelIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      Assert.AreEqual(Golden('voxwrite ' + TVoxelScenarios.ModelName(LModelIndex)),
        TVoxelScenarios.DigestBytes(TVoxelEditorVoxFormat.Write(LModel)), TVoxelScenarios.ModelName(LModelIndex));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeScrivereEIlDdvoxDelVecchio;
var
  LModelIndex: Integer;
  LModel: TVoxelEditorModel;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LModel := NewModel(LModelIndex);
    try
      Assert.AreEqual(Golden('ddvoxwrite ' + TVoxelScenarios.ModelName(LModelIndex)),
        TVoxelScenarios.DigestBytes(TVoxelEditorDdvoxFormat.Write(LModel)), TVoxelScenarios.ModelName(LModelIndex));
    finally
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeLeggereIlDdvoxDelVecchio;
var
  LModelIndex: Integer;
  LModel, LRead: TVoxelEditorModel;
  LParts: TArray<string>;
begin
  for LModelIndex := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    LParts := Golden('ddvoxread ' + TVoxelScenarios.ModelName(LModelIndex)).Split([' ']);
    LModel := NewModel(LModelIndex);
    LRead := TVoxelEditorModel.Create(1);
    try
      TVoxelEditorDdvoxFormat.Read(TVoxelEditorDdvoxFormat.Write(LModel), LRead);
      Assert.AreEqual(StrToInt(LParts[0]), LRead.Size, 'size');
      Assert.AreEqual(LParts[1], ModelHash(LRead), TVoxelScenarios.ModelName(LModelIndex));
    finally
      LRead.Free;
      LModel.Free;
    end;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeLeggereIKvxDelVecchio;
var
  LIndex: Integer;
  LRead: TVoxelEditorModel;
  LParts: TArray<string>;
begin
  LRead := TVoxelEditorModel.Create(1);
  try
    for LIndex := 0 to TVoxelScenarios.KVX_COUNT - 1 do
    begin
      LParts := Golden('kvx ' + IntToStr(LIndex)).Split([' ']);
      TVoxelEditorKvxFormat.Read(TVoxelScenarios.KvxBytes(LIndex), LRead);
      Assert.AreEqual(StrToInt(LParts[0]), LRead.Size, 'size ' + IntToStr(LIndex));
      Assert.AreEqual(LParts[1], ModelHash(LRead), 'kvx ' + IntToStr(LIndex));
    end;
  finally
    LRead.Free;
  end;
end;

procedure TTestVoxelEditorParity.DovrebbeLeggereIVoxDelVecchio;
var
  LIndex: Integer;
  LRead: TVoxelEditorModel;
  LParts: TArray<string>;
begin
  LRead := TVoxelEditorModel.Create(1);
  try
    for LIndex := 0 to TVoxelScenarios.VOX_COUNT - 1 do
    begin
      LParts := Golden('vox ' + IntToStr(LIndex)).Split([' ']);
      TVoxelEditorVoxFormat.Read(TVoxelScenarios.VoxBytes(LIndex), LRead);
      Assert.AreEqual(StrToInt(LParts[0]), LRead.Size, 'size ' + IntToStr(LIndex));
      Assert.AreEqual(LParts[1], ModelHash(LRead), 'vox ' + IntToStr(LIndex));
    end;
  finally
    LRead.Free;
  end;
end;

end.
