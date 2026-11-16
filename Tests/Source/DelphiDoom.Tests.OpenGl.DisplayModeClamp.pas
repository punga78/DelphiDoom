{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL context - the limits of a new screen size   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.DisplayModeClamp;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlContext.DisplayModeClamp;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlDisplayModeClamp = class(TObject)
  strict private
    FLimits: TGlDisplayModeLimits;
    // the text of the first part of GL_SetDisplayMode of gl_main.pas before IdTech1\GlContext
    procedure OldClamp(const newwidth, newheight: Integer; out nwidth, nheight: Integer);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioSuUnaGrigliaDiMisure;
    [Test]
    [TestCase('dispari', '641,481,640,480')]
    [TestCase('gia nei limiti', '800,600,800,600')]
    [TestCase('troppo stretto', '100,100,320,200')]
    [TestCase('troppo largo', '5000,600,2048,600')]
    procedure DovrebbeRendereParieStringereLeLarghezzeNeiLimiti(const AWidth, AHeight, AExpectedWidth,
      AExpectedHeight: Integer);
    [Test]
    procedure DovrebbeConservareIlDifettoDellAltezzaOltreIlMassimo;
    [Test]
    procedure DovrebbeNonFarMaiPiuAltaCheLargaLaFinestra;
  end;

implementation

{ TTestOpenGlDisplayModeClamp }

procedure TTestOpenGlDisplayModeClamp.Setup;
begin
  FLimits.MinWidth := 320;
  FLimits.MaxWidth := 2048;
  FLimits.MinHeight := 200;
  FLimits.MaxHeight := 1536;
end;

procedure TTestOpenGlDisplayModeClamp.OldClamp(const newwidth, newheight: Integer; out nwidth, nheight: Integer);
begin
  nwidth := newwidth and not 1;
  if nwidth > FLimits.MaxWidth then
    nwidth := FLimits.MaxWidth
  else if nwidth < FLimits.MinWidth then
    nwidth := FLimits.MinWidth;

  nheight := newheight and not 1;
  if nheight > FLimits.MaxHeight then
    nwidth := FLimits.MaxHeight
  else if nheight < FLimits.MinHeight then
    nheight := FLimits.MinHeight;

  if nheight > nwidth then
    nheight := nwidth;
end;

procedure TTestOpenGlDisplayModeClamp.DovrebbeDareLoStessoRisultatoDelVecchioSuUnaGrigliaDiMisure;
var
  LWidth, LHeight: Integer;
  LOldWidth, LOldHeight: Integer;
  LNewWidth, LNewHeight: Integer;
begin
  LWidth := -20;
  while LWidth <= 5000 do
  begin
    LHeight := -20;
    while LHeight <= 4000 do
    begin
      OldClamp(LWidth, LHeight, LOldWidth, LOldHeight);
      TGlDisplayModeClamp.Clamp(LWidth, LHeight, FLimits, LNewWidth, LNewHeight);
      Assert.AreEqual(LOldWidth, LNewWidth, Format('larghezza per %dx%d', [LWidth, LHeight]));
      Assert.AreEqual(LOldHeight, LNewHeight, Format('altezza per %dx%d', [LWidth, LHeight]));
      Inc(LHeight, 37);
    end;
    Inc(LWidth, 41);
  end;
end;

procedure TTestOpenGlDisplayModeClamp.DovrebbeRendereParieStringereLeLarghezzeNeiLimiti(const AWidth, AHeight,
  AExpectedWidth, AExpectedHeight: Integer);
var
  LWidth, LHeight: Integer;
begin
  TGlDisplayModeClamp.Clamp(AWidth, AHeight, FLimits, LWidth, LHeight);
  Assert.AreEqual(AExpectedWidth, LWidth);
  Assert.AreEqual(AExpectedHeight, LHeight);
end;

procedure TTestOpenGlDisplayModeClamp.DovrebbeConservareIlDifettoDellAltezzaOltreIlMassimo;
var
  LWidth, LHeight: Integer;
begin
  // the width, not the height, is set to the maximum height
  TGlDisplayModeClamp.Clamp(1024, 3000, FLimits, LWidth, LHeight);
  Assert.AreEqual(FLimits.MaxHeight, LWidth);
  Assert.AreEqual(FLimits.MaxHeight, LHeight);
end;

procedure TTestOpenGlDisplayModeClamp.DovrebbeNonFarMaiPiuAltaCheLargaLaFinestra;
var
  LWidth, LHeight: Integer;
begin
  TGlDisplayModeClamp.Clamp(400, 1000, FLimits, LWidth, LHeight);
  Assert.AreEqual(400, LWidth);
  Assert.AreEqual(400, LHeight);
end;

end.
