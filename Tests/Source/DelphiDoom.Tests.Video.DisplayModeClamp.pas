{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the limits of a display mode        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.DisplayModeClamp;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Video.DisplayModeClamp;

type
  [TestFixture]
  [Category('video')]
  TTestVideoDisplayModeClamp = class(TObject)
  public
    [Test]
    procedure DovrebbeLimitareLAltezzaOltreIlMassimoSenzaToccareLaLarghezza;
    [Test]
    procedure DovrebbeLimitareLaLarghezzaOltreIlMassimo;
    [Test]
    procedure DovrebbeAlzareAlMinimoLeMisureTroppoPiccole;
    [Test]
    procedure DovrebbeRendereParileMisure;
    [Test]
    procedure DovrebbeTenereLAltezzaNonOltreLaLarghezza;
    [Test]
    procedure DovrebbeRiprodurreIlVecchioCodiceFuoriDalRamoDifettoso;
  end;

implementation

const
  MIN_WIDTH = 160;
  MIN_HEIGHT = 100;
  MAX_WIDTH = 4096;
  MAX_HEIGHT = 3072;

// The body of V_SetDisplayMode as it was in v_displaymode, copied; the branch of the height over the maximum
// is the intended one (nheight, not nwidth)
procedure OldClampWithoutDefect(const ANewWidth, ANewHeight: Integer; out AWidth, AHeight: Integer);
begin
  AWidth := ANewWidth and not 1;
  if AWidth > MAX_WIDTH then
    AWidth := MAX_WIDTH
  else if AWidth < MIN_WIDTH then
    AWidth := MIN_WIDTH;

  AHeight := ANewHeight and not 1;
  if AHeight > MAX_HEIGHT then
    AHeight := MAX_HEIGHT
  else if AHeight < MIN_HEIGHT then
    AHeight := MIN_HEIGHT;

  if AHeight > AWidth then
    AHeight := AWidth;
end;

{ TTestVideoDisplayModeClamp }

procedure TTestVideoDisplayModeClamp.DovrebbeLimitareLAltezzaOltreIlMassimoSenzaToccareLaLarghezza;
var
  LWidth, LHeight: Integer;
begin
  // the old code wrote 3072 in the width (and then 5000 > width gave 3072 x 3072)
  TVideoDisplayModeClamp.Clamp(4000, 5000, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT, LWidth, LHeight);
  Assert.AreEqual<Integer>(4000, LWidth);
  Assert.AreEqual<Integer>(MAX_HEIGHT, LHeight);
end;

procedure TTestVideoDisplayModeClamp.DovrebbeLimitareLaLarghezzaOltreIlMassimo;
var
  LWidth, LHeight: Integer;
begin
  TVideoDisplayModeClamp.Clamp(9000, 800, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT, LWidth, LHeight);
  Assert.AreEqual<Integer>(MAX_WIDTH, LWidth);
  Assert.AreEqual<Integer>(800, LHeight);
end;

procedure TTestVideoDisplayModeClamp.DovrebbeAlzareAlMinimoLeMisureTroppoPiccole;
var
  LWidth, LHeight: Integer;
begin
  TVideoDisplayModeClamp.Clamp(10, 10, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT, LWidth, LHeight);
  Assert.AreEqual<Integer>(MIN_WIDTH, LWidth);
  Assert.AreEqual<Integer>(MIN_HEIGHT, LHeight);
end;

procedure TTestVideoDisplayModeClamp.DovrebbeRendereParileMisure;
var
  LWidth, LHeight: Integer;
begin
  TVideoDisplayModeClamp.Clamp(641, 481, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT, LWidth, LHeight);
  Assert.AreEqual<Integer>(640, LWidth);
  Assert.AreEqual<Integer>(480, LHeight);
end;

procedure TTestVideoDisplayModeClamp.DovrebbeTenereLAltezzaNonOltreLaLarghezza;
var
  LWidth, LHeight: Integer;
begin
  TVideoDisplayModeClamp.Clamp(320, 2000, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT, LWidth, LHeight);
  Assert.AreEqual<Integer>(320, LWidth);
  Assert.AreEqual<Integer>(320, LHeight);
end;

procedure TTestVideoDisplayModeClamp.DovrebbeRiprodurreIlVecchioCodiceFuoriDalRamoDifettoso;
var
  LRequestedWidth, LRequestedHeight, LExpectedWidth, LExpectedHeight, LWidth, LHeight: Integer;
begin
  LRequestedWidth := -20;
  while LRequestedWidth <= 5000 do
  begin
    LRequestedHeight := -20;
    while LRequestedHeight <= 4000 do
    begin
      OldClampWithoutDefect(LRequestedWidth, LRequestedHeight, LExpectedWidth, LExpectedHeight);
      TVideoDisplayModeClamp.Clamp(LRequestedWidth, LRequestedHeight, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH,
        MAX_HEIGHT, LWidth, LHeight);
      Assert.AreEqual<Integer>(LExpectedWidth, LWidth);
      Assert.AreEqual<Integer>(LExpectedHeight, LHeight);
      Inc(LRequestedHeight, 37);
    end;
    Inc(LRequestedWidth, 41);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoDisplayModeClamp);

end.
