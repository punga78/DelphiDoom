{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the tables of the view size     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.ViewTables;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererViewTables = class(TObject)
  private
    FTables: IRendererViewTables;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareTuttoLoSchermoOltreIDieciBlocchi;
    [Test]
    procedure DovrebbeDareLAltezzaPienaAIDieciBlocchi;
    [Test]
    procedure DovrebbeDareMultipliDiOttoSottoIDieciBlocchi;
    [Test]
    procedure DovrebbeDareUnaRigaSulCentroDellOrizzonte;
    [Test]
    procedure DovrebbeTenereAlMinimoLaDistanzaPerLeLuciVicinoAllOrizzonte;
    [Test]
    procedure DovrebbeDareLaScalaDiUnCosenoUnitario;
    [Test]
    procedure DovrebbeDareLivelliDiLuceNelCampo;
    /// <summary>
    ///   Parity: the tables of the old R_ExecuteSetViewSize, copied here as they were, on random
    ///   sizes of the view
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_ExecuteSetViewSize;
  end;

implementation

uses
  DelphiDoom.Renderer.Factory, DelphiDoom.MathCore.FixedMath;

const
  FRACUNIT = 65536;
  LIGHTLEVELS = 16;
  MAXLIGHTSCALE = 48;
  HLL_MAXLIGHTSCALE = MAXLIGHTSCALE * 64;

{ TTestRendererViewTables }

procedure TTestRendererViewTables.Setup;
begin
  FTables := TRendererFactory.CreateViewTables;
end;

procedure TTestRendererViewTables.TearDown;
begin
  FTables := nil;
end;

procedure TTestRendererViewTables.DovrebbeDareTuttoLoSchermoOltreIDieciBlocchi;
var
  LSize: TRendererViewDimensions;
begin
  LSize := FTables.Dimensions(11, 640, 480, 400, 400, 10);
  Assert.AreEqual(640, LSize.ScaledViewWidth);
  Assert.AreEqual(480, LSize.ViewHeight);
end;

procedure TTestRendererViewTables.DovrebbeDareLAltezzaPienaAIDieciBlocchi;
var
  LSize: TRendererViewDimensions;
begin
  LSize := FTables.Dimensions(10, 640, 480, 396, 400, 10);
  Assert.AreEqual(640, LSize.ScaledViewWidth);
  Assert.AreEqual(396, LSize.ViewHeight);
end;

procedure TTestRendererViewTables.DovrebbeDareMultipliDiOttoSottoIDieciBlocchi;
var
  LSize: TRendererViewDimensions;
begin
  LSize := FTables.Dimensions(5, 640, 480, 396, 400, 10);
  // 5 * 640 div 10 = 320; 5 * 400 div 10 = 200: both multiples of eight
  Assert.AreEqual(320, LSize.ScaledViewWidth);
  Assert.AreEqual(200, LSize.ViewHeight);
  LSize := FTables.Dimensions(3, 641, 480, 396, 401, 10);
  Assert.AreEqual(0, LSize.ScaledViewWidth mod 8);
  Assert.AreEqual(0, LSize.ViewHeight mod 8);
end;

procedure TTestRendererViewTables.DovrebbeDareUnaRigaSulCentroDellOrizzonte;
var
  LTables: TRendererSlopeTables;
begin
  LTables := FTables.Slopes(400 * FRACUNIT, 100 * FRACUNIT, 200);
  Assert.AreEqual<Integer>(200, Length(LTables.YSlope));
  Assert.AreEqual<Integer>(200, Length(LTables.LightYSlope));
  // the first row is half a row above the centre
  Assert.AreEqual(TFixedMath.Divide(400 * FRACUNIT, 100 * FRACUNIT - FRACUNIT div 2),
    LTables.YSlope[0]);
end;

procedure TTestRendererViewTables.DovrebbeTenereAlMinimoLaDistanzaPerLeLuciVicinoAllOrizzonte;
var
  LTables: TRendererSlopeTables;
begin
  LTables := FTables.Slopes(400 * FRACUNIT, 100 * FRACUNIT, 200);
  // row 99 is half a row from the horizon: the distance is below four, so the light has a minimum
  Assert.AreEqual(TFixedMath.Divide(400 * FRACUNIT, 4 * FRACUNIT), LTables.LightYSlope[99]);
  Assert.AreEqual(LTables.YSlope[0], LTables.LightYSlope[0]);
end;

procedure TTestRendererViewTables.DovrebbeDareLaScalaDiUnCosenoUnitario;
var
  LScales: TArray<Integer>;
begin
  LScales := FTables.DistanceScales([FRACUNIT, -FRACUNIT, FRACUNIT div 2]);
  Assert.AreEqual(FRACUNIT, LScales[0]);
  Assert.AreEqual(FRACUNIT, LScales[1]);
  Assert.AreEqual(2 * FRACUNIT, LScales[2]);
end;

procedure TTestRendererViewTables.DovrebbeDareLivelliDiLuceNelCampo;
var
  LLevels: TArray<Integer>;
  LIndex: Integer;
begin
  LLevels := FTables.LightLevels(LIGHTLEVELS, HLL_MAXLIGHTSCALE, 640, 640, True);
  Assert.AreEqual<Integer>(LIGHTLEVELS * HLL_MAXLIGHTSCALE, Length(LLevels));
  for LIndex := 0 to High(LLevels) do
  begin
    Assert.IsTrue(LLevels[LIndex] >= 1);
    Assert.IsTrue(LLevels[LIndex] <= FRACUNIT);
  end;
end;

procedure TTestRendererViewTables.DovrebbeFareComeIlVecchioR_ExecuteSetViewSize;
var
  LRound: Integer;
  LBlocks, LScreenWidth, LScreenHeight, LFullHeight, LBlockBase: Integer;
  LOldWidth, LOldHeight: Integer;
  LSize: TRendererViewDimensions;
  LProjectionY, LCenterYFrac, LViewHeight, LViewWidth: Integer;
  LSlopes: TRendererSlopeTables;
  LDy, LDy1, LIndex, LColumn, LStartMap, LLevelHi: Integer;
  LOldYSlope, LOldSlYSlope: Integer;
  LCosines, LScales: TArray<Integer>;
  LLights: TArray<Integer>;
  LDoom: Boolean;
  LOldLight: Integer;
begin
  RandSeed := 2473;
  for LRound := 1 to 150 do
  begin
    LBlocks := 3 + Random(10);
    LScreenWidth := 320 + Random(1600);
    LScreenHeight := 200 + Random(1000);
    LFullHeight := LScreenHeight - Random(100);
    LBlockBase := LScreenHeight - Random(100);

    // the old size of the view
    if LBlocks > 10 then
    begin
      LOldWidth := LScreenWidth;
      LOldHeight := LScreenHeight;
    end
    else
    begin
      if LBlocks = 10 then
        LOldWidth := LScreenWidth
      else
        LOldWidth := (LBlocks * LScreenWidth div 10) and not 7;
      if LBlocks = 10 then
        LOldHeight := LFullHeight
      else
        LOldHeight := (LBlocks * LBlockBase div 10) and not 7;
    end;
    LSize := FTables.Dimensions(LBlocks, LScreenWidth, LScreenHeight, LFullHeight, LBlockBase, 10);
    Assert.AreEqual(LOldWidth, LSize.ScaledViewWidth);
    Assert.AreEqual(LOldHeight, LSize.ViewHeight);

    // the old planes
    LViewHeight := 50 + Random(600);
    LViewWidth := 64 + Random(1200);
    LProjectionY := (1 + Random(2000)) * FRACUNIT div 4;
    LCenterYFrac := (LViewHeight div 2 + Random(40) - 20) * FRACUNIT;
    LSlopes := FTables.Slopes(LProjectionY, LCenterYFrac, LViewHeight);
    LDy := LCenterYFrac + FRACUNIT div 2;
    for LIndex := 0 to LViewHeight - 1 do
    begin
      LDy := LDy - FRACUNIT;
      LDy1 := Abs(LDy);
      LOldYSlope := TFixedMath.Divide(LProjectionY, LDy1);
      if LDy1 < 4 * FRACUNIT then
        LOldSlYSlope := TFixedMath.Divide(LProjectionY, 4 * FRACUNIT)
      else
        LOldSlYSlope := LOldYSlope;
      Assert.AreEqual(LOldYSlope, LSlopes.YSlope[LIndex]);
      Assert.AreEqual(LOldSlYSlope, LSlopes.LightYSlope[LIndex]);
    end;

    SetLength(LCosines, LViewWidth);
    for LIndex := 0 to LViewWidth - 1 do
      LCosines[LIndex] := Random(2 * FRACUNIT) - FRACUNIT;
    LScales := FTables.DistanceScales(LCosines);
    for LIndex := 0 to LViewWidth - 1 do
      Assert.AreEqual(TFixedMath.Divide(FRACUNIT, Abs(LCosines[LIndex])), LScales[LIndex]);

    // the old light levels, in both orders of operations
    for LDoom in [True, False] do
    begin
      LLights := FTables.LightLevels(LIGHTLEVELS, HLL_MAXLIGHTSCALE, LViewWidth, LScreenWidth, LDoom);
      for LIndex := 0 to LIGHTLEVELS - 1 do
      begin
        LStartMap := ((LIGHTLEVELS - 1 - LIndex) * 2 * FRACUNIT) div LIGHTLEVELS;
        for LColumn := 0 to HLL_MAXLIGHTSCALE - 1 do
        begin
          if LDoom then
            LLevelHi := LStartMap - (LColumn * LScreenWidth) div LViewWidth * 16
          else
            LLevelHi := LStartMap - LColumn * 16 * LScreenWidth div LViewWidth;
          if LLevelHi < 0 then
            LOldLight := FRACUNIT
          else if LLevelHi >= FRACUNIT then
            LOldLight := 1
          else
            LOldLight := FRACUNIT - LLevelHi;
          Assert.AreEqual(LOldLight, LLights[LIndex * HLL_MAXLIGHTSCALE + LColumn]);
        end;
      end;
    end;
  end;
end;

end.
