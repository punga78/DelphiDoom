{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingThumbnailBuilder                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ThumbnailBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.ThumbnailBuilder, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  /// <summary>The nearest color as V_FindAproxColorIndex searched it (brute force)</summary>
  TReferenceColorIndex = class(TInterfacedObject, IImagingColorIndex)
  public
    function Nearest(const APalette: TImagingPixels; AColor: Cardinal;
      ALow, AHigh: Integer): Integer;
  end;

  /// <summary>Gives the low byte of the color: the thumbnail then shows which pixel was taken</summary>
  TLowByteColorIndex = class(TInterfacedObject, IImagingColorIndex)
  private
    FCalls: Integer;
    FLow: Integer;
    FHigh: Integer;
  public
    function Nearest(const APalette: TImagingPixels; AColor: Cardinal;
      ALow, AHigh: Integer): Integer;
    property Calls: Integer read FCalls;
    property Low: Integer read FLow;
    property High: Integer read FHigh;
  end;

  [TestFixture]
  [Category('imaging')]
  TTestImagingThumbnailBuilder = class(TObject)
  private
    class function Settings(AScreenWidth, AScreenHeight, AViewX, AViewY, AViewWidth,
      AViewHeight: Integer; ABottomUp: Boolean): TImagingThumbnailSettings; static;
  public
    [Test]
    procedure DovrebbeRifiutareUnaRicercaNil;
    [Test]
    procedure DovrebbeDareGliStessiIndiciDelVecchioCodice;
    [Test]
    procedure DovrebbeDareUnIndiceAPixelDellaMiniatura;
    [Test]
    procedure DovrebbeCercareTraIlColore1E255;
    [Test]
    procedure DovrebbePrendereUnPixelOgniTantoDallaFinestraDiVista;
    [Test]
    procedure DovrebbeLeggereLeRigheDalBassoConOpenGL;
    [Test]
    procedure DovrebbeLimitareLeCoordinateAlloSchermo;
    [Test]
    procedure DovrebbeRifiutareUnoSchermoVuoto;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCorta;
    [Test]
    procedure DovrebbeRifiutareUnaMiniaturaSenzaPixel;
  end;

implementation

{ TReferenceColorIndex }

function TReferenceColorIndex.Nearest(const APalette: TImagingPixels; AColor: Cardinal;
  ALow, AHigh: Integer): Integer;
var
  LIndex: Integer;
  LDistance: Cardinal;
  LMinimum: Cardinal;
  LColor: Cardinal;
  LDeltaRed: Integer;
  LDeltaGreen: Integer;
  LDeltaBlue: Integer;
begin
  Result := ALow;
  LMinimum := Cardinal($FFFFFFFF);
  for LIndex := ALow to AHigh do
  begin
    LColor := APalette[LIndex];
    LDeltaRed := Integer(AColor and $FF) - Integer(LColor and $FF);
    LDeltaGreen := Integer((AColor shr 8) and $FF) - Integer((LColor shr 8) and $FF);
    LDeltaBlue := Integer((AColor shr 16) and $FF) - Integer((LColor shr 16) and $FF);
    LDistance := Cardinal(LDeltaRed * LDeltaRed + LDeltaGreen * LDeltaGreen +
      LDeltaBlue * LDeltaBlue);
    if LDistance < LMinimum then
    begin
      Result := LIndex;
      if LDistance = 0 then
        Exit;
      LMinimum := LDistance;
    end;
  end;
end;

{ TLowByteColorIndex }

function TLowByteColorIndex.Nearest(const APalette: TImagingPixels; AColor: Cardinal;
  ALow, AHigh: Integer): Integer;
begin
  Inc(FCalls);
  FLow := ALow;
  FHigh := AHigh;
  Result := Integer(AColor and $FF);
end;

{ TTestImagingThumbnailBuilder }

class function TTestImagingThumbnailBuilder.Settings(AScreenWidth, AScreenHeight, AViewX,
  AViewY, AViewWidth, AViewHeight: Integer; ABottomUp: Boolean): TImagingThumbnailSettings;
begin
  Result.ScreenWidth := AScreenWidth;
  Result.ScreenHeight := AScreenHeight;
  Result.ViewX := AViewX;
  Result.ViewY := AViewY;
  Result.ViewWidth := AViewWidth;
  Result.ViewHeight := AViewHeight;
  Result.Width := 80;
  Result.Height := 50;
  Result.BottomUp := ABottomUp;
end;

procedure TTestImagingThumbnailBuilder.DovrebbeRifiutareUnaRicercaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TImagingThumbnailBuilder.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestImagingThumbnailBuilder.DovrebbeDareGliStessiIndiciDelVecchioCodice;
type
  TCase = record
    Name: string;
    SW, SH, VX, VY, VW, VH: Integer;
    Seed: Cardinal;
  end;
const
  CASES: array[0..5] of TCase = (
    (Name: 'full320x200'; SW: 320; SH: 200; VX: 0; VY: 0; VW: 320; VH: 200; Seed: 21),
    (Name: 'view320x200'; SW: 320; SH: 200; VX: 32; VY: 20; VW: 256; VH: 160; Seed: 22),
    (Name: 'screen640x400'; SW: 640; SH: 400; VX: 0; VY: 0; VW: 640; VH: 368; Seed: 23),
    (Name: 'tiny40x30'; SW: 40; SH: 30; VX: 0; VY: 0; VW: 40; VH: 30; Seed: 24),
    (Name: 'overflow'; SW: 320; SH: 200; VX: 10; VY: 10; VW: 400; VH: 300; Seed: 25),
    (Name: 'negative'; SW: 320; SH: 200; VX: -20; VY: -10; VW: 320; VH: 200; Seed: 26));
var
  LBuilder: IImagingThumbnailBuilder;
  LIndex: Integer;
  LBottomUp: Integer;
  LPixels: TBytes;
begin
  LBuilder := TImagingThumbnailBuilder.Create(TReferenceColorIndex.Create);
  for LIndex := 0 to High(CASES) do
  begin
    LPixels := TImagingSamples.RandomBytes(CASES[LIndex].Seed, CASES[LIndex].SW * CASES[LIndex].SH * 4);
    for LBottomUp := 0 to 1 do
      TImagingGolden.Check('thumbnail.golden.txt',
        'thumb_' + CASES[LIndex].Name + '_gl' + IntToStr(LBottomUp),
        TImagingSamples.Hex(TImagingSamples.Hash(LBuilder.Build(
          Settings(CASES[LIndex].SW, CASES[LIndex].SH, CASES[LIndex].VX, CASES[LIndex].VY,
            CASES[LIndex].VW, CASES[LIndex].VH, LBottomUp = 1),
          Pointer(LPixels), TImagingSamples.Palette(CASES[LIndex].Seed + 100)))));
  end;
end;

procedure TTestImagingThumbnailBuilder.DovrebbeDareUnIndiceAPixelDellaMiniatura;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
begin
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  LPixels := TImagingSamples.RandomBytes(1, 160 * 100 * 4);
  Assert.AreEqual(80 * 50, Length(LBuilder.Build(Settings(160, 100, 0, 0, 160, 100, False),
    Pointer(LPixels), TImagingSamples.Palette(1))));
end;

procedure TTestImagingThumbnailBuilder.DovrebbeCercareTraIlColore1E255;
var
  LColors: TLowByteColorIndex;
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
begin
  LColors := TLowByteColorIndex.Create;
  LBuilder := TImagingThumbnailBuilder.Create(LColors);
  LPixels := TImagingSamples.RandomBytes(1, 160 * 100 * 4);
  LBuilder.Build(Settings(160, 100, 0, 0, 160, 100, False), Pointer(LPixels),
    TImagingSamples.Palette(1));
  Assert.AreEqual(80 * 50, LColors.Calls);
  Assert.AreEqual(1, LColors.Low, 'il colore 0 non si sceglie mai');
  Assert.AreEqual(255, LColors.High);
end;

procedure TTestImagingThumbnailBuilder.DovrebbePrendereUnPixelOgniTantoDallaFinestraDiVista;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
  LThumbnail: TBytes;
  LX: Integer;
  LY: Integer;
begin
  // the first byte of each pixel is its column: the thumbnail shows the column that was taken
  SetLength(LPixels, 160 * 100 * 4);
  for LY := 0 to 99 do
    for LX := 0 to 159 do
      LPixels[(LY * 160 + LX) * 4] := Byte(LX);
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  // a window of 80 pixels that starts at 20: one pixel for one
  LThumbnail := LBuilder.Build(Settings(160, 100, 20, 0, 80, 100, False), Pointer(LPixels),
    TImagingSamples.Palette(1));
  for LX := 0 to 79 do
    Assert.AreEqual(20 + LX, Integer(LThumbnail[LX]), 'colonna ' + IntToStr(LX));
  // the whole width in 80 pixels: one every two
  LThumbnail := LBuilder.Build(Settings(160, 100, 0, 0, 160, 100, False), Pointer(LPixels),
    TImagingSamples.Palette(1));
  for LX := 0 to 79 do
    Assert.AreEqual(LX * 2, Integer(LThumbnail[LX]), 'colonna ' + IntToStr(LX));
end;

procedure TTestImagingThumbnailBuilder.DovrebbeLeggereLeRigheDalBassoConOpenGL;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
  LThumbnail: TBytes;
  LX: Integer;
  LY: Integer;
begin
  // the first byte of each pixel is its row
  SetLength(LPixels, 80 * 50 * 4);
  for LY := 0 to 49 do
    for LX := 0 to 79 do
      LPixels[(LY * 80 + LX) * 4] := Byte(LY);
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  LThumbnail := LBuilder.Build(Settings(80, 50, 0, 0, 80, 50, True), Pointer(LPixels),
    TImagingSamples.Palette(1));
  Assert.AreEqual(49, Integer(LThumbnail[0]), 'in alto c''è l''ultimo rigo dello schermo');
  Assert.AreEqual(0, Integer(LThumbnail[49 * 80]));
end;

procedure TTestImagingThumbnailBuilder.DovrebbeLimitareLeCoordinateAlloSchermo;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
begin
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  LPixels := TImagingSamples.RandomBytes(3, 20 * 10 * 4);
  // a window that is outside the screen on every side must not read outside the buffer
  Assert.AreEqual(80 * 50, Length(LBuilder.Build(Settings(20, 10, -50, -50, 400, 300, False),
    Pointer(LPixels), TImagingSamples.Palette(1))));
  Assert.AreEqual(80 * 50, Length(LBuilder.Build(Settings(20, 10, 15, 8, 400, 300, True),
    Pointer(LPixels), TImagingSamples.Palette(1))));
end;

procedure TTestImagingThumbnailBuilder.DovrebbeRifiutareUnoSchermoVuoto;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
begin
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  SetLength(LPixels, 16);
  Assert.WillRaise(
    procedure
    begin
      LBuilder.Build(Settings(2, 2, 0, 0, 2, 2, False), nil, TImagingSamples.Palette(1));
    end, EImagingException);
  Assert.WillRaise(
    procedure
    begin
      LBuilder.Build(Settings(0, 2, 0, 0, 2, 2, False), Pointer(LPixels),
        TImagingSamples.Palette(1));
    end, EImagingException);
end;

procedure TTestImagingThumbnailBuilder.DovrebbeRifiutareUnaPalettaCorta;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
begin
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  SetLength(LPixels, 16);
  Assert.WillRaise(
    procedure
    begin
      LBuilder.Build(Settings(2, 2, 0, 0, 2, 2, False), Pointer(LPixels), nil);
    end, EImagingException);
end;

procedure TTestImagingThumbnailBuilder.DovrebbeRifiutareUnaMiniaturaSenzaPixel;
var
  LBuilder: IImagingThumbnailBuilder;
  LPixels: TBytes;
  LSettings: TImagingThumbnailSettings;
begin
  LBuilder := TImagingThumbnailBuilder.Create(TLowByteColorIndex.Create);
  SetLength(LPixels, 16);
  LSettings := Settings(2, 2, 0, 0, 2, 2, False);
  LSettings.Width := 0;
  Assert.WillRaise(
    procedure
    begin
      LBuilder.Build(LSettings, Pointer(LPixels), TImagingSamples.Palette(1));
    end, EImagingException);
end;

end.
