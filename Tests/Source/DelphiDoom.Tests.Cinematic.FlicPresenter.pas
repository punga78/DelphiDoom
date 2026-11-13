{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFlicPresenter (issue #199)                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicPresenter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Flic.Intf;

type
  [TestFixture]
  [Category('cinematic')]
  TTestFlicPresenter = class(TObject)
  strict private
    function Image(AWidth, AHeight: Integer): TFlicPlayerImage;
  public
    [Test]
    procedure DovrebbeCentrareConLeFasceSeLoSchermoEPiuLargo;
    [Test]
    procedure DovrebbeCentrareConLeFasceSeLoSchermoEPiuAlto;
    [Test]
    procedure DovrebbeRiempireTuttoLoSchermoSeLeProporzioniSonoUguali;
    [Test]
    procedure DovrebbeUsareLeProporzioniDelloSchermoDosAQuattroTerzi;
    [Test]
    procedure DovrebbeUsareIlPiuGrandeMultiploInteroSeRichiesto;
    [Test]
    procedure DovrebbeUsareLaScalaPiccolaSeLoSchermoEPiuPiccoloDelMultiploIntero;
    [Test]
    procedure DovrebbeDeformareConLoStiramento;
    [Test]
    procedure DovrebbeDareUnRettangoloVuotoConMisureNonPositive;
    [Test]
    procedure DovrebbeLasciareAlmenoUnPixel;
    [Test]
    procedure DovrebbeDisegnareLaImmagineAlCentroEIlFondoAttorno;
    [Test]
    procedure DovrebbeIngrandireConIlPixelPiuVicino;
    [Test]
    procedure DovrebbeRimpicciolireConIlPixelPiuVicino;
    [Test]
    procedure DovrebbeDipingereSoloLoSfondoSenzaImmagine;
    [Test]
    procedure DovrebbeVuotareLoSchermoSeLeMisureNonSonoPositive;
    [Test]
    procedure DovrebbeUsareLoSfondoDato;
  end;

implementation

uses
  DelphiDoom.Cinematic.Flic.Presenter;

{ TTestFlicPresenter }

function TTestFlicPresenter.Image(AWidth, AHeight: Integer): TFlicPlayerImage;
var
  LIndex: Integer;
begin
  Result := Default(TFlicPlayerImage);
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Pixels, AWidth * AHeight);
  // each pixel is its own position + 1, so that the tests can tell where it went
  for LIndex := 0 to High(Result.Pixels) do
    Result.Pixels[LIndex] := Cardinal(LIndex + 1);
end;

procedure TTestFlicPresenter.DovrebbeCentrareConLeFasceSeLoSchermoEPiuLargo;
var
  LRect: TFlicPresentRect;
begin
  // 320 x 200 on 1000 x 400: height 400, width 640, bands of 180 at the sides
  LRect := TFlicPresenter.Layout(320, 200, 1000, 400, fpmFit);
  Assert.AreEqual<Integer>(640, LRect.Width);
  Assert.AreEqual<Integer>(400, LRect.Height);
  Assert.AreEqual<Integer>(180, LRect.Left);
  Assert.AreEqual<Integer>(0, LRect.Top);
end;

procedure TTestFlicPresenter.DovrebbeCentrareConLeFasceSeLoSchermoEPiuAlto;
var
  LRect: TFlicPresentRect;
begin
  LRect := TFlicPresenter.Layout(320, 200, 640, 800, fpmFit);
  Assert.AreEqual<Integer>(640, LRect.Width);
  Assert.AreEqual<Integer>(400, LRect.Height);
  Assert.AreEqual<Integer>(0, LRect.Left);
  Assert.AreEqual<Integer>(200, LRect.Top);
end;

procedure TTestFlicPresenter.DovrebbeRiempireTuttoLoSchermoSeLeProporzioniSonoUguali;
var
  LRect: TFlicPresentRect;
begin
  LRect := TFlicPresenter.Layout(320, 200, 1280, 800, fpmFit);
  Assert.AreEqual<Integer>(1280, LRect.Width);
  Assert.AreEqual<Integer>(800, LRect.Height);
  Assert.AreEqual<Integer>(0, LRect.Left);
  Assert.AreEqual<Integer>(0, LRect.Top);
end;

procedure TTestFlicPresenter.DovrebbeUsareLeProporzioniDelloSchermoDosAQuattroTerzi;
var
  LRect: TFlicPresentRect;
begin
  // the pixels of the DOS games were not square: 320 x 200 was shown at 4 : 3
  LRect := TFlicPresenter.Layout(320, 200, 1280, 960, fpmFit, 4, 3);
  Assert.AreEqual<Integer>(1280, LRect.Width);
  Assert.AreEqual<Integer>(960, LRect.Height);
  LRect := TFlicPresenter.Layout(320, 200, 1920, 1080, fpmFit, 4, 3);
  Assert.AreEqual<Integer>(1440, LRect.Width);
  Assert.AreEqual<Integer>(1080, LRect.Height);
  Assert.AreEqual<Integer>(240, LRect.Left);
end;

procedure TTestFlicPresenter.DovrebbeUsareIlPiuGrandeMultiploInteroSeRichiesto;
var
  LRect: TFlicPresentRect;
begin
  LRect := TFlicPresenter.Layout(320, 200, 1000, 700, fpmIntegerFit);
  // 3 times: 960 x 600; 4 times would be 1280 wide
  Assert.AreEqual<Integer>(960, LRect.Width);
  Assert.AreEqual<Integer>(600, LRect.Height);
  Assert.AreEqual<Integer>(20, LRect.Left);
  Assert.AreEqual<Integer>(50, LRect.Top);
end;

procedure TTestFlicPresenter.DovrebbeUsareLaScalaPiccolaSeLoSchermoEPiuPiccoloDelMultiploIntero;
var
  LRect: TFlicPresentRect;
begin
  // a screen smaller than the picture: it cannot be a whole multiple, it is fitted
  LRect := TFlicPresenter.Layout(320, 200, 160, 160, fpmIntegerFit);
  Assert.AreEqual<Integer>(160, LRect.Width);
  Assert.AreEqual<Integer>(100, LRect.Height);
  Assert.AreEqual<Integer>(30, LRect.Top);
end;

procedure TTestFlicPresenter.DovrebbeDeformareConLoStiramento;
var
  LRect: TFlicPresentRect;
begin
  LRect := TFlicPresenter.Layout(320, 200, 1000, 400, fpmStretch);
  Assert.AreEqual<Integer>(1000, LRect.Width);
  Assert.AreEqual<Integer>(400, LRect.Height);
  Assert.AreEqual<Integer>(0, LRect.Left);
end;

procedure TTestFlicPresenter.DovrebbeDareUnRettangoloVuotoConMisureNonPositive;
var
  LRect: TFlicPresentRect;
begin
  LRect := TFlicPresenter.Layout(0, 200, 100, 100, fpmFit);
  Assert.AreEqual<Integer>(0, LRect.Width);
  LRect := TFlicPresenter.Layout(320, -1, 100, 100, fpmFit);
  Assert.AreEqual<Integer>(0, LRect.Width);
  LRect := TFlicPresenter.Layout(320, 200, 0, 100, fpmFit);
  Assert.AreEqual<Integer>(0, LRect.Width);
  LRect := TFlicPresenter.Layout(320, 200, 100, 0, fpmFit);
  Assert.AreEqual<Integer>(0, LRect.Height);
end;

procedure TTestFlicPresenter.DovrebbeLasciareAlmenoUnPixel;
var
  LRect: TFlicPresentRect;
begin
  LRect := TFlicPresenter.Layout(1000, 1, 10, 10, fpmFit);
  Assert.AreEqual<Integer>(10, LRect.Width);
  Assert.AreEqual<Integer>(1, LRect.Height, 'The height 0.01 is one pixel');
end;

procedure TTestFlicPresenter.DovrebbeDisegnareLaImmagineAlCentroEIlFondoAttorno;
var
  LScreen: TImagingPixels;
begin
  // 2 x 2 on 6 x 4: height 4, width 4, one column of band on each side
  TFlicPresenter.Present(Image(2, 2), fpmFit, 6, 4, LScreen);
  Assert.AreEqual<Integer>(24, Length(LScreen));
  Assert.AreEqual<Cardinal>($FF000000, LScreen[0]);
  Assert.AreEqual<Cardinal>($FF000000, LScreen[5]);
  Assert.AreEqual<Cardinal>(1, LScreen[1]);
  Assert.AreEqual<Cardinal>(1, LScreen[2]);
  Assert.AreEqual<Cardinal>(2, LScreen[3]);
  Assert.AreEqual<Cardinal>(2, LScreen[4]);
  // the second row of the screen is still the first row of the picture; the third is the second
  Assert.AreEqual<Cardinal>(1, LScreen[6 + 1]);
  Assert.AreEqual<Cardinal>(3, LScreen[12 + 1]);
  Assert.AreEqual<Cardinal>(4, LScreen[18 + 4]);
end;

procedure TTestFlicPresenter.DovrebbeIngrandireConIlPixelPiuVicino;
var
  LScreen: TImagingPixels;
  LX: Integer;
begin
  TFlicPresenter.Present(Image(2, 1), fpmStretch, 6, 1, LScreen);
  for LX := 0 to 2 do
    Assert.AreEqual<Cardinal>(1, LScreen[LX]);
  for LX := 3 to 5 do
    Assert.AreEqual<Cardinal>(2, LScreen[LX]);
end;

procedure TTestFlicPresenter.DovrebbeRimpicciolireConIlPixelPiuVicino;
var
  LScreen: TImagingPixels;
begin
  TFlicPresenter.Present(Image(4, 1), fpmStretch, 2, 1, LScreen);
  Assert.AreEqual<Cardinal>(1, LScreen[0]);
  Assert.AreEqual<Cardinal>(3, LScreen[1]);
end;

procedure TTestFlicPresenter.DovrebbeDipingereSoloLoSfondoSenzaImmagine;
var
  LScreen: TImagingPixels;
  LIndex: Integer;
begin
  TFlicPresenter.Present(Default(TFlicPlayerImage), fpmFit, 4, 3, LScreen, $FF123456);
  Assert.AreEqual<Integer>(12, Length(LScreen));
  for LIndex := 0 to High(LScreen) do
    Assert.AreEqual<Cardinal>($FF123456, LScreen[LIndex]);
end;

procedure TTestFlicPresenter.DovrebbeVuotareLoSchermoSeLeMisureNonSonoPositive;
var
  LScreen: TImagingPixels;
begin
  SetLength(LScreen, 5);
  TFlicPresenter.Present(Image(2, 2), fpmFit, 0, 4, LScreen);
  Assert.AreEqual<Integer>(0, Length(LScreen));
  SetLength(LScreen, 5);
  TFlicPresenter.Present(Image(2, 2), fpmFit, 4, -1, LScreen);
  Assert.AreEqual<Integer>(0, Length(LScreen));
end;

procedure TTestFlicPresenter.DovrebbeUsareLoSfondoDato;
var
  LScreen: TImagingPixels;
begin
  TFlicPresenter.Present(Image(2, 2), fpmFit, 6, 4, LScreen, $FF0000FF);
  Assert.AreEqual<Cardinal>($FF0000FF, LScreen[0]);
  Assert.AreEqual<Cardinal>($FF0000FF, LScreen[23]);
end;

end.
