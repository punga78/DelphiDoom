{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the shadow of the night of the finer globe         }
{  (issue 183): the whole number routine gives the shade of Globe::drawShadow   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.GlobeNightShade;

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.XcomGeoscape.GlobeNightShade;

type
  [TestFixture]
  [Category('XcomGeoscape')]
  TTestXcomGlobeNightShade = class
  strict private
    const
      WIDTH = 256;
      HEIGHT = 200;
      RADIUS = 90.0;
      OCEAN = 192;
      LAND = 100;
    var
      FGradient: array[0..239] of SmallInt;
      FNoise: TArray<SmallInt>;
      FLand: TBytes;
      FTarget: TBytes;
      FShade: TXcomGlobeNightShade;
    procedure Make(AOceanShading: Boolean);
    procedure Fill(AColor: Byte);
    /// <summary>getShadowValue of Globe.cpp in floating point for the pixel of the table; -1 off the sphere</summary>
    function Reference(ATableX, ATableY: Integer; ASunX, ASunY, ASunZ: Double; ANoise: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('sole di fronte', '0,0,1')]
    [TestCase('sole di lato', '1000,0,1')]
    [TestCase('sole dietro', '0,0,-1')]
    [TestCase('sole in alto a sinistra', '-500,-600,1')]
    [TestCase('tramonto', '800,100,-1')]
    procedure IlMareDovrebbeAvereLOmbraDelCalcoloInVirgolaMobile(ASunXThousandths, ASunYThousandths, ASunZSign: Integer);
    [Test]
    procedure FuoriDallaSferaIlPixelDovrebbeEssereVuoto;
    [Test]
    procedure DoveNonCENullaIlPixelDovrebbeRestareVuoto;
    [Test]
    procedure LaTerraDovrebbeMuoversiDentroIlSuoBloccoDiSedici;
    [Test]
    procedure SenzaOmbraDelMareIlMareDovrebbeEssereTrattatoComeLaTerra;
    [Test]
    procedure IlRumoreDovrebbeCoprireUnPixelDelGioco;
    [Test]
    procedure ConUnoSpostamentoIPixelNonRaggiuntiDovrebberoEssereCopiati;
    [Test]
    procedure LaStessaImmagineDovrebbePoterEssereSorgenteEBersaglio;
    [Test]
    procedure UnSoleMossoDiPocoDovrebbeEssereLoStesso;
    [Test]
    procedure UnaMisuraSbagliataDovrebbeSollevare;
  end;

implementation

procedure TTestXcomGlobeNightShade.Setup;
var
  LIndex: Integer;
  LValue: Integer;
begin
  // the table of GlobeStaticData
  for LIndex := 0 to 239 do
  begin
    LValue := LIndex - 120;
    if LValue < -66 then
      LValue := -16
    else if LValue < -48 then
      LValue := -15
    else if LValue < -33 then
      LValue := -14
    else if LValue < -22 then
      LValue := -13
    else if LValue < -15 then
      LValue := -12
    else if LValue < -11 then
      LValue := -11
    else if LValue < -9 then
      LValue := -10;
    if LValue > 120 then
      LValue := 19
    else if LValue > 98 then
      LValue := 18
    else if LValue > 86 then
      LValue := 17
    else if LValue > 74 then
      LValue := 16
    else if LValue > 54 then
      LValue := 15
    else if LValue > 38 then
      LValue := 14
    else if LValue > 26 then
      LValue := 13
    else if LValue > 18 then
      LValue := 12
    else if LValue > 13 then
      LValue := 11
    else if LValue > 10 then
      LValue := 10
    else if LValue > 8 then
      LValue := 9;
    FGradient[LIndex] := LValue + 16;
  end;
  SetLength(FNoise, TXcomGlobeNightShade.NOISE_SIZE * TXcomGlobeNightShade.NOISE_SIZE);
  for LIndex := 0 to High(FNoise) do
    FNoise[LIndex] := (LIndex * 7 + LIndex div 60) mod 4;
  SetLength(FLand, WIDTH * HEIGHT);
  SetLength(FTarget, WIDTH * HEIGHT);
end;

procedure TTestXcomGlobeNightShade.TearDown;
begin
  FShade.Free;
  FShade := nil;
end;

procedure TTestXcomGlobeNightShade.Make(AOceanShading: Boolean);
begin
  FShade := TXcomGlobeNightShade.Create(WIDTH, HEIGHT, 1, OCEAN, AOceanShading, FGradient);
  FShade.SetRadius(RADIUS);
end;

procedure TTestXcomGlobeNightShade.Fill(AColor: Byte);
begin
  FillChar(FLand[0], Length(FLand), AColor);
end;

function TTestXcomGlobeNightShade.Reference(ATableX, ATableY: Integer; ASunX, ASunY, ASunZ: Double;
  ANoise: Integer): Integer;
var
  LX, LY, LZ, LRest, LValue: Double;
begin
  LX := ATableX + 0.5 - WIDTH div 2;
  LY := ATableY + 0.5 - HEIGHT div 2;
  LRest := RADIUS * RADIUS - (LX * LX + LY * LY);
  if LRest <= 0 then
    Exit(-1);
  LX := LX / RADIUS;
  LY := LY / RADIUS;
  LZ := Sqrt(LRest) / RADIUS;
  LValue := (Sqr(LX - ASunX) + Sqr(LY - ASunY) + Sqr(LZ - ASunZ) - 2) * 125.0;
  if LValue < -110 then
    LValue := -31
  else if LValue > 120 then
    LValue := 50
  else
    LValue := FGradient[Trunc(LValue) + 120];
  LValue := LValue - ANoise;
  Result := Trunc(Min(Max(LValue, 0.0), 31.0));
end;

procedure TTestXcomGlobeNightShade.IlMareDovrebbeAvereLOmbraDelCalcoloInVirgolaMobile(ASunXThousandths,
  ASunYThousandths, ASunZSign: Integer);
var
  LX, LY, LExpected, LGot, LOnSphere, LDifferent: Integer;
  LSunX, LSunY, LSunZ: Double;
begin
  // a vector of length 1 from its x and y and the side its z is on
  LSunX := ASunXThousandths / 1000;
  LSunY := ASunYThousandths / 1000;
  LSunZ := ASunZSign * Sqrt(Max(0.0, 1 - LSunX * LSunX - LSunY * LSunY));
  Make(True);
  Fill(OCEAN);
  FShade.Shade(FLand, FTarget, 0, 0, LSunX, LSunY, LSunZ, FNoise);
  LOnSphere := 0;
  LDifferent := 0;
  for LY := 0 to HEIGHT - 1 do
    for LX := 0 to WIDTH - 1 do
    begin
      LExpected := Reference(LX, LY, LSunX, LSunY, LSunZ, FNoise[(LY mod 60) * 60 + LX mod 60]);
      if LExpected < 0 then
        Continue;
      Inc(LOnSphere);
      LGot := FTarget[LY * WIDTH + LX] - OCEAN;
      // the two computations round the angle differently: on the edge of a level they can be one level apart
      if Abs(LGot - LExpected) > 1 then
        Assert.Fail(Format('pixel %d,%d: %d al posto di %d', [LX, LY, LGot, LExpected]));
      if LGot <> LExpected then
        Inc(LDifferent);
    end;
  Assert.IsTrue(LOnSphere > 20000);
  Assert.IsTrue(LDifferent * 200 < LOnSphere, Format('%d pixel di un livello diversi su %d', [LDifferent, LOnSphere]));
end;

procedure TTestXcomGlobeNightShade.FuoriDallaSferaIlPixelDovrebbeEssereVuoto;
begin
  Make(True);
  Fill(OCEAN);
  FShade.Shade(FLand, FTarget, 0, 0, 0, 0, 1, FNoise);
  Assert.AreEqual(0, Integer(FTarget[0]));
  Assert.AreEqual(0, Integer(FTarget[(HEIGHT div 2) * WIDTH + 10]));
  Assert.AreNotEqual(0, Integer(FTarget[(HEIGHT div 2) * WIDTH + WIDTH div 2]));
end;

procedure TTestXcomGlobeNightShade.DoveNonCENullaIlPixelDovrebbeRestareVuoto;
begin
  Make(True);
  Fill(0);
  FShade.Shade(FLand, FTarget, 0, 0, 0, 0, -1, FNoise);
  Assert.AreEqual(0, Integer(FTarget[(HEIGHT div 2) * WIDTH + WIDTH div 2]));
end;

procedure TTestXcomGlobeNightShade.LaTerraDovrebbeMuoversiDentroIlSuoBloccoDiSedici;
var
  LCenter: Integer;
  LLevel: Integer;
begin
  Make(True);
  LCenter := (HEIGHT div 2) * WIDTH + WIDTH div 2;
  // day: the land keeps its color
  Fill(LAND);
  FShade.Shade(FLand, FTarget, 0, 0, 0, 0, 1, FNoise);
  Assert.AreEqual(LAND, Integer(FTarget[LCenter]));
  // night: a third of the shade
  FShade.Shade(FLand, FTarget, 0, 0, 0, 0, -1, FNoise);
  LLevel := Reference(WIDTH div 2, HEIGHT div 2, 0, 0, -1, FNoise[(HEIGHT div 2 mod 60) * 60 + (WIDTH div 2) mod 60]);
  Assert.IsTrue(LLevel >= 28);
  Assert.AreEqual(LAND + LLevel div 3, Integer(FTarget[LCenter]));
  // a color at the end of its block stays in it
  Fill(LAND or $0F);
  FShade.Shade(FLand, FTarget, 0, 0, 0, 0, -1, FNoise);
  Assert.AreEqual(LAND or $0F, Integer(FTarget[LCenter]));
end;

procedure TTestXcomGlobeNightShade.SenzaOmbraDelMareIlMareDovrebbeEssereTrattatoComeLaTerra;
var
  LCenter: Integer;
begin
  Make(False);
  LCenter := (HEIGHT div 2) * WIDTH + WIDTH div 2;
  Fill(OCEAN);
  FShade.Shade(FLand, FTarget, 0, 0, 0, 0, -1, FNoise);
  Assert.IsTrue((FTarget[LCenter] > OCEAN) and (FTarget[LCenter] <= OCEAN + 10),
    Format('colore %d', [FTarget[LCenter]]));
end;

procedure TTestXcomGlobeNightShade.IlRumoreDovrebbeCoprireUnPixelDelGioco;
var
  LLarge: TXcomGlobeNightShade;
  LLand, LTarget: TBytes;
  LX, LY, LSame, LCells: Integer;
  LFlat: array[0..239] of SmallInt;
begin
  // at the scale 4 the sixteen pixels of a pixel of the game share the cell of noise. With a gradient that gives
  // the shade 10 for every angle, every pixel near the edge of the night is 10 - noise
  for LX := 0 to 239 do
    LFlat[LX] := 10;
  LLarge := TXcomGlobeNightShade.Create(WIDTH * 4, HEIGHT * 4, 4, OCEAN, True, LFlat);
  try
    LLarge.SetRadius(RADIUS * 4);
    SetLength(LLand, WIDTH * 4 * HEIGHT * 4);
    SetLength(LTarget, Length(LLand));
    FillChar(LLand[0], Length(LLand), OCEAN);
    LLarge.Shade(LLand, LTarget, 0, 0, 1, 0, 0, FNoise);
    LSame := 0;
    LCells := 0;
    for LY := HEIGHT * 2 - 40 to HEIGHT * 2 + 39 do
      for LX := WIDTH * 2 - 40 to WIDTH * 2 + 39 do
      begin
        Inc(LCells);
        if LTarget[LY * WIDTH * 4 + LX] = OCEAN + 10 - FNoise[((LY div 4) mod 60) * 60 + (LX div 4) mod 60] then
          Inc(LSame);
      end;
    Assert.AreEqual(LCells, LSame);
  finally
    LLarge.Free;
  end;
end;

procedure TTestXcomGlobeNightShade.ConUnoSpostamentoIPixelNonRaggiuntiDovrebberoEssereCopiati;
begin
  Make(True);
  Fill(LAND);
  // the table moved 3 to the right and 2 down: the first columns and rows are not reached
  FShade.Shade(FLand, FTarget, 3, 2, 0, 0, 1, FNoise);
  Assert.AreEqual(LAND, Integer(FTarget[0]));
  Assert.AreEqual(LAND, Integer(FTarget[50 * WIDTH + 2]));
  Assert.AreEqual(LAND, Integer(FTarget[1 * WIDTH + 100]));
  // the first reached pixel is the corner of the table: off the sphere
  Assert.AreEqual(0, Integer(FTarget[2 * WIDTH + 3]));
  // the center of the sphere moved with the table
  Assert.AreEqual(LAND, Integer(FTarget[(HEIGHT div 2 + 2) * WIDTH + WIDTH div 2 + 3]));
end;

procedure TTestXcomGlobeNightShade.LaStessaImmagineDovrebbePoterEssereSorgenteEBersaglio;
var
  LIndex: Integer;
begin
  Make(True);
  Fill(OCEAN);
  FShade.Shade(FLand, FTarget, 0, 0, 0.6, 0, 0.8, FNoise);
  FShade.Shade(FLand, FLand, 0, 0, 0.6, 0, 0.8, FNoise);
  for LIndex := 0 to High(FLand) do
    if FLand[LIndex] <> FTarget[LIndex] then
      Assert.Fail(Format('pixel %d', [LIndex]));
end;

procedure TTestXcomGlobeNightShade.UnSoleMossoDiPocoDovrebbeEssereLoStesso;
begin
  Assert.IsTrue(TXcomGlobeNightShade.SameSun(0, 0, 1, 0, 0, 1));
  Assert.IsTrue(TXcomGlobeNightShade.SameSun(0, 0, 1, 0.0005, 0, 1));
  Assert.IsFalse(TXcomGlobeNightShade.SameSun(0, 0, 1, 0.002, 0, 1));
  Assert.IsFalse(TXcomGlobeNightShade.SameSun(0, 0, 1, 0, 0, -1));
end;

procedure TTestXcomGlobeNightShade.UnaMisuraSbagliataDovrebbeSollevare;
var
  LShort: TBytes;
begin
  Make(True);
  SetLength(LShort, 10);
  Assert.WillRaise(
    procedure
    begin
      FShade.Shade(LShort, FTarget, 0, 0, 0, 0, 1, FNoise);
    end, EArgumentException);
  Assert.WillRaise(
    procedure
    begin
      TXcomGlobeNightShade.Create(0, 10, 1, OCEAN, True, FGradient);
    end, EArgumentException);
  Assert.WillRaise(
    procedure
    begin
      TXcomGlobeNightShade.Create(10, 10, 1, OCEAN, True, [1, 2, 3]);
    end, EArgumentException);
end;

end.
