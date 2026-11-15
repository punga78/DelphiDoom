{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the mapping of view angles      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.TextureMapping;

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererTextureMapping = class(TObject)
  private
    FBuilder: IRendererTextureMappingBuilder;
    FFineTangent: TArray<Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareTabelleDellaDimensioneGiusta;
    [Test]
    procedure DovrebbeDareLAngoloDiClipDellaPrimaColonna;
    [Test]
    procedure DovrebbeMettereLeColonneDelBordoNeiCasiDiConfine;
    [Test]
    procedure DovrebbeDareColonneNonCrescentiPerAngoliCrescenti;
    [Test]
    procedure DovrebbeFallireSeLaTabellaDelleTangentiEBreve;
    [Test]
    procedure DovrebbeFallireSeLaLarghezzaENegativa;
    /// <summary>
    ///   Parity: the tables of R_InitTextureMapping of the old r_main.pas, copied here as they
    ///   were, and the library give the same tables on random focal lengths and widths
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_InitTextureMapping;
  end;

implementation

// as in the old code: the angles wrap around
{$Q-}
{$R-}

uses
  DelphiDoom.Renderer.Factory, DelphiDoom.MathCore.FixedMath;

const
  FRACUNIT = 65536;
  FINEANGLES = 8192;
  ANGLETOFINEUNIT = 1 shl 19;
  ANG90 = $40000000;

{ TTestRendererTextureMapping }

procedure TTestRendererTextureMapping.Setup;
var
  LIndex: Integer;
begin
  FBuilder := TRendererFactory.CreateTextureMappingBuilder;
  // the table of the tangents of the engine: tan((i - 2048 + 0.5) * 2 pi / 8192) in fixed point
  SetLength(FFineTangent, FINEANGLES div 2);
  for LIndex := 0 to High(FFineTangent) do
    FFineTangent[LIndex] := Round(Tan((LIndex - FINEANGLES div 4 + 0.5) * Pi / (FINEANGLES div 2)) *
      FRACUNIT);
end;

procedure TTestRendererTextureMapping.TearDown;
begin
  FBuilder := nil;
end;

procedure TTestRendererTextureMapping.DovrebbeDareTabelleDellaDimensioneGiusta;
var
  LTables: TRendererTextureMapping;
begin
  LTables := FBuilder.Build(160 * FRACUNIT, 160 * FRACUNIT, 320, FFineTangent);
  Assert.AreEqual<Integer>(FINEANGLES div 2, Length(LTables.ViewAngleToX));
  Assert.AreEqual<Integer>(321, Length(LTables.XToViewAngle));
end;

procedure TTestRendererTextureMapping.DovrebbeDareLAngoloDiClipDellaPrimaColonna;
var
  LTables: TRendererTextureMapping;
begin
  LTables := FBuilder.Build(160 * FRACUNIT, 160 * FRACUNIT, 320, FFineTangent);
  Assert.AreEqual(LTables.XToViewAngle[0], LTables.ClipAngle);
  // a 90 degrees field of view: the clip angle is about 45 degrees
  Assert.IsTrue(LTables.ClipAngle > $1F000000);
  Assert.IsTrue(LTables.ClipAngle < $21000000);
end;

procedure TTestRendererTextureMapping.DovrebbeMettereLeColonneDelBordoNeiCasiDiConfine;
var
  LTables: TRendererTextureMapping;
  LIndex: Integer;
begin
  LTables := FBuilder.Build(160 * FRACUNIT, 160 * FRACUNIT, 320, FFineTangent);
  for LIndex := 0 to High(LTables.ViewAngleToX) do
  begin
    Assert.IsTrue(LTables.ViewAngleToX[LIndex] >= 0, 'no -1 after the cleaning');
    Assert.IsTrue(LTables.ViewAngleToX[LIndex] <= 320, 'no width + 1 after the cleaning');
  end;
  // looking far to the left falls out of the view on the right of the table, to the right on the left
  Assert.AreEqual(320, LTables.ViewAngleToX[0]);
  Assert.AreEqual(0, LTables.ViewAngleToX[High(LTables.ViewAngleToX)]);
end;

procedure TTestRendererTextureMapping.DovrebbeDareColonneNonCrescentiPerAngoliCrescenti;
var
  LTables: TRendererTextureMapping;
  LIndex: Integer;
begin
  LTables := FBuilder.Build(160 * FRACUNIT, 160 * FRACUNIT, 320, FFineTangent);
  for LIndex := 1 to High(LTables.ViewAngleToX) do
    Assert.IsTrue(LTables.ViewAngleToX[LIndex] <= LTables.ViewAngleToX[LIndex - 1]);
end;

procedure TTestRendererTextureMapping.DovrebbeFallireSeLaTabellaDelleTangentiEBreve;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(160 * FRACUNIT, 160 * FRACUNIT, 320, Copy(FFineTangent, 0, 100));
    end, ERendererException);
end;

procedure TTestRendererTextureMapping.DovrebbeFallireSeLaLarghezzaENegativa;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(160 * FRACUNIT, 160 * FRACUNIT, -1, FFineTangent);
    end, ERendererException);
end;

procedure TTestRendererTextureMapping.DovrebbeFareComeIlVecchioR_InitTextureMapping;
var
  LScenario: Integer;
  LTables: TRendererTextureMapping;
  viewwidth: Integer;
  centerxfrac: Integer;
  focallength: Integer;
  viewangletox: array[0..FINEANGLES div 2 - 1] of Integer;
  xtoviewangle: array[0..2047] of Cardinal;
  clipangle: Cardinal;
  i, x, t: Integer;
  an: Cardinal;
begin
  RandSeed := 20261116;
  for LScenario := 1 to 200 do
  begin
    viewwidth := 1 + Random(2047);
    centerxfrac := (viewwidth div 2) * FRACUNIT + Random(2) * (FRACUNIT div 2);
    focallength := (viewwidth div 2 + Random(viewwidth + 1)) * FRACUNIT + Random(FRACUNIT);
    if Random(10) = 0 then
      focallength := Random(1000) * FRACUNIT;

    LTables := FBuilder.Build(focallength, centerxfrac, viewwidth, FFineTangent);

    // the old code, as it was (FixedMul is TFixedMath.Mul: proved equal to the asm of 32 bit)
    for i := 0 to FINEANGLES div 2 - 1 do
    begin
      if FFineTangent[i] > FRACUNIT * 2 then
        t := -1
      else if FFineTangent[i] < -FRACUNIT * 2 then
        t := viewwidth + 1
      else
      begin
        t := TFixedMath.Mul(FFineTangent[i], focallength);
        t := (centerxfrac - t + (FRACUNIT - 1)) div FRACUNIT;

        if t < -1 then
          t := -1
        else if t > viewwidth + 1 then
          t := viewwidth + 1;
      end;
      viewangletox[i] := t;
    end;
    for x := 0 to viewwidth do
    begin
      an := 0;
      while viewangletox[an] > x do
        Inc(an);
      xtoviewangle[x] := an * ANGLETOFINEUNIT - ANG90;
    end;
    for i := 0 to FINEANGLES div 2 - 1 do
    begin
      if viewangletox[i] = -1 then
        viewangletox[i] := 0
      else if viewangletox[i] = viewwidth + 1 then
        viewangletox[i] := viewwidth;
    end;
    clipangle := xtoviewangle[0];

    for i := 0 to FINEANGLES div 2 - 1 do
      Assert.AreEqual(viewangletox[i], LTables.ViewAngleToX[i], 'viewangletox ' + IntToStr(i));
    for x := 0 to viewwidth do
      Assert.AreEqual(xtoviewangle[x], LTables.XToViewAngle[x], 'xtoviewangle ' + IntToStr(x));
    Assert.AreEqual(clipangle, LTables.ClipAngle);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRendererTextureMapping);

end.
