{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the aspect of the monitor and   }
{  the angles of the fake 3D view                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.MonitorAspect;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf,
  DelphiDoom.Video.Types, DelphiDoom.Video.Intf;

type
  /// <summary>A fake of the system: the modes it is given, in order</summary>
  TFakeDisplayModeSource = class(TInterfacedObject, IDisplayModeSource)
  public
    Modes: TArray<TDisplayMode>;
    function ListModes: TArray<TDisplayMode>;
  end;

  [TestFixture]
  [Category('renderer')]
  TTestRendererMonitorAspect = class(TObject)
  private
    FSource: TFakeDisplayModeSource;
    FSourceRef: IDisplayModeSource;
    FMeasure: IRendererMonitorAspect;
    procedure SetModes(const AModes: TArray<TDisplayMode>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDare640x480SenzaModi;
    [Test]
    procedure DovrebbeSaltareIModiNonA32Bit;
    [Test]
    procedure DovrebbeSaltareIModiNonPiuGrandiDi640x480;
    [Test]
    procedure DovrebbePrendereIlModoPiuGrandeInOrdineDelSistema;
    [Test]
    procedure DovrebbeTenereIlPrimoSeUnModoSuccessivoEPiuPiccoloInUnLato;
    [Test]
    procedure DovrebbeFallireSenzaSorgente;
    /// <summary>
    ///   Parity: the choice of R_InitAspect of the old r_aspect.pas (two lists of numbers),
    ///   copied here as it was, on random lists of modes
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_InitAspect;
  end;

  [TestFixture]
  [Category('renderer')]
  TTestRendererFake3DAngles = class(TObject)
  private
    FAngles: IRendererFake3DAngles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareUnaVoceOgniDirezione;
    [Test]
    procedure DovrebbeDareCoseniNelCampo;
    [Test]
    procedure DovrebbeFallireConUnIntervalloAlContrario;
    /// <summary>
    ///   Parity: R_CalculateAnglesTable of the old r_fake3d.pas, copied here as it was, with
    ///   the limits of the engine (-110 and 90 look directions times 16)
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_CalculateAnglesTable;
  end;

implementation

uses
  System.Math, DelphiDoom.Renderer.Factory;

{ TFakeDisplayModeSource }

function TFakeDisplayModeSource.ListModes: TArray<TDisplayMode>;
begin
  Result := Modes;
end;

function Mode(AWidth, AHeight, ABits: Integer): TDisplayMode;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.BitsPerPixel := ABits;
end;

{ TTestRendererMonitorAspect }

procedure TTestRendererMonitorAspect.Setup;
begin
  FSource := TFakeDisplayModeSource.Create;
  FSourceRef := FSource;
  FMeasure := TRendererFactory.CreateMonitorAspect(FSourceRef);
end;

procedure TTestRendererMonitorAspect.TearDown;
begin
  FMeasure := nil;
  FSourceRef := nil;
  FSource := nil;
end;

procedure TTestRendererMonitorAspect.SetModes(const AModes: TArray<TDisplayMode>);
begin
  FSource.Modes := AModes;
end;

procedure TTestRendererMonitorAspect.DovrebbeDare640x480SenzaModi;
begin
  Assert.AreEqual(640, FMeasure.Measure.Width);
  Assert.AreEqual(480, FMeasure.Measure.Height);
end;

procedure TTestRendererMonitorAspect.DovrebbeSaltareIModiNonA32Bit;
begin
  SetModes([Mode(1920, 1080, 16), Mode(1024, 768, 32)]);
  Assert.AreEqual(1024, FMeasure.Measure.Width);
  Assert.AreEqual(768, FMeasure.Measure.Height);
end;

procedure TTestRendererMonitorAspect.DovrebbeSaltareIModiNonPiuGrandiDi640x480;
begin
  SetModes([Mode(640, 480, 32), Mode(800, 480, 32), Mode(1280, 400, 32)]);
  Assert.AreEqual(640, FMeasure.Measure.Width);
  Assert.AreEqual(480, FMeasure.Measure.Height);
end;

procedure TTestRendererMonitorAspect.DovrebbePrendereIlModoPiuGrandeInOrdineDelSistema;
begin
  SetModes([Mode(800, 600, 32), Mode(1280, 720, 32), Mode(1920, 1080, 32)]);
  Assert.AreEqual(1920, FMeasure.Measure.Width);
  Assert.AreEqual(1080, FMeasure.Measure.Height);
end;

procedure TTestRendererMonitorAspect.DovrebbeTenereIlPrimoSeUnModoSuccessivoEPiuPiccoloInUnLato;
begin
  // 1280x1024 then 1920x800: the second is wider but lower, so the first stays
  SetModes([Mode(1280, 1024, 32), Mode(1920, 800, 32)]);
  Assert.AreEqual(1280, FMeasure.Measure.Width);
  Assert.AreEqual(1024, FMeasure.Measure.Height);
end;

procedure TTestRendererMonitorAspect.DovrebbeFallireSenzaSorgente;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateMonitorAspect(nil);
    end, EArgumentNilException);
end;

procedure TTestRendererMonitorAspect.DovrebbeFareComeIlVecchioR_InitAspect;
var
  LRound: Integer;
  LModes: TArray<TDisplayMode>;
  LIndex: Integer;
  LWidths, LHeights: TArray<Integer>;
  LMaxWidth, LMaxHeight: Integer;
  LMeasured: TRendererMonitorSize;
begin
  RandSeed := 2472;
  for LRound := 1 to 500 do
  begin
    SetLength(LModes, Random(15));
    for LIndex := 0 to High(LModes) do
      LModes[LIndex] := Mode(320 + Random(8) * 320, 200 + Random(8) * 200, 16 + Random(3) * 8);
    SetModes(LModes);

    // the old code: two lists, a first entry 640 and 480, the modes that pass the filter added,
    // then a scan from the second entry
    LMaxWidth := 640;
    SetLength(LWidths, 1);
    LWidths[0] := LMaxWidth;
    LMaxHeight := 480;
    SetLength(LHeights, 1);
    LHeights[0] := LMaxHeight;
    for LIndex := 0 to High(LModes) do
      if (LModes[LIndex].Width > 640) and (LModes[LIndex].Height > 480) and
        (LModes[LIndex].BitsPerPixel = 32) then
      begin
        SetLength(LWidths, Length(LWidths) + 1);
        LWidths[High(LWidths)] := LModes[LIndex].Width;
        SetLength(LHeights, Length(LHeights) + 1);
        LHeights[High(LHeights)] := LModes[LIndex].Height;
      end;
    for LIndex := 1 to High(LWidths) do
      if (LWidths[LIndex] >= LMaxWidth) and (LHeights[LIndex] >= LMaxHeight) then
      begin
        LMaxWidth := LWidths[LIndex];
        LMaxHeight := LHeights[LIndex];
      end;

    LMeasured := FMeasure.Measure;
    Assert.AreEqual(LMaxWidth, LMeasured.Width);
    Assert.AreEqual(LMaxHeight, LMeasured.Height);
  end;
end;

{ TTestRendererFake3DAngles }

procedure TTestRendererFake3DAngles.Setup;
begin
  FAngles := TRendererFactory.CreateFake3DAngles;
end;

procedure TTestRendererFake3DAngles.TearDown;
begin
  FAngles := nil;
end;

procedure TTestRendererFake3DAngles.DovrebbeDareUnaVoceOgniDirezione;
begin
  // from -110 * 16 to 90 * 16 included
  Assert.AreEqual<Integer>(200 * 16 + 1, Length(FAngles.Cosines(-110 * 16, 90 * 16)));
  Assert.AreEqual<Integer>(1, Length(FAngles.Cosines(5, 5)));
end;

procedure TTestRendererFake3DAngles.DovrebbeDareCoseniNelCampo;
var
  LCosines: TArray<Double>;
  LIndex: Integer;
begin
  LCosines := FAngles.Cosines(-110 * 16, 90 * 16);
  for LIndex := 0 to High(LCosines) do
  begin
    Assert.IsTrue(LCosines[LIndex] >= -1.0);
    Assert.IsTrue(LCosines[LIndex] <= 1.0);
  end;
end;

procedure TTestRendererFake3DAngles.DovrebbeFallireConUnIntervalloAlContrario;
begin
  Assert.WillRaise(
    procedure
    begin
      FAngles.Cosines(10, 5);
    end, EArgumentException);
end;

procedure TTestRendererFake3DAngles.DovrebbeFareComeIlVecchioR_CalculateAnglesTable;
const
  MIN_SIZE = 16 * -110;
  MAX_SIZE = 16 * 90;
  LOOKDIR_TO_ANGLE = 0.5 / 16;
var
  LExpected: array[MIN_SIZE..MAX_SIZE] of Double;
  LCosines: TArray<Double>;
  A1, A2, B1, B2, C1, C2: Extended;
  X, Y, R: Extended;
  V1, V2: Extended;
  D, U, V: Extended;
  Test1, Test2: Extended;
  L: Integer;
  Found: Boolean;
begin
  // the old procedure, copied here as it was
  A1 := MIN_SIZE;
  A2 := A1 * LOOKDIR_TO_ANGLE * Pi / 270;
  Test1 := A2 - 0.001;
  B1 := 0.0;
  B2 := 0.0;
  C1 := MAX_SIZE;
  C2 := C1 * LOOKDIR_TO_ANGLE * Pi / 180;
  Test2 := C2 + 0.001;
  D := (A1 - B1) * (B2 - C2) - (B1 - C1) * (A2 - B2);
  Found := not ((D > -0.0000000001) and (D < 0.0000000001));
  Assert.IsTrue(Found);
  U := (A1 * A1 - B1 * B1 + A2 * A2 - B2 * B2) / 2;
  V := (B1 * B1 - C1 * C1 + B2 * B2 - C2 * C2) / 2;
  X := (U * (B2 - C2) - V * (A2 - B2)) / D;
  Y := (V * (A1 - B1) - U * (B1 - C1)) / D;
  R := Sqrt((X - A1) * (X - A1) + (Y - A2) * (Y - A2));
  for L := MIN_SIZE to MAX_SIZE do
  begin
    V1 := Sqrt(R * R - (L - X) * (L - X));
    V2 := Y + V1;
    V1 := Y - V1;
    if Test1 < Test2 then
      Found := (V1 >= Test1) and (V1 <= Test2)
    else
      Found := (V1 >= Test2) and (V1 <= Test1);
    if Found then
      LExpected[L] := Cos(V1)
    else
      LExpected[L] := Cos(V2);
  end;

  LCosines := FAngles.Cosines(MIN_SIZE, MAX_SIZE);
  for L := MIN_SIZE to MAX_SIZE do
    Assert.AreEqual(LExpected[L], LCosines[L - MIN_SIZE], 0.0);
end;

end.
