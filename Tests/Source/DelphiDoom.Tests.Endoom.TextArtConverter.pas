{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomTextArtConverter                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.TextArtConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Endoom.Intf, DelphiDoom.Imaging.Intf;

type
  /// <summary>A resampler that gives a picture made of what its owner asks, and remembers what it was asked</summary>
  TFakeResampler = class(TInterfacedObject, IImagingResampler)
  public
    Calls: Integer;
    SourceWidth: Integer;
    SourceHeight: Integer;
    DestinationWidth: Integer;
    DestinationHeight: Integer;
    Pixels: TArray<Cardinal>;
    function Resample(const ASource: TArray<Cardinal>; ASourceWidth, ASourceHeight,
      ADestinationWidth, ADestinationHeight: Integer): TArray<Cardinal>;
  end;

  /// <summary>
  ///   The TEXTART lines of Tests\Data\Endoom\textart.golden.txt were written by BitmapToScreen of the old ee_textart
  ///   (with the original Graphics32, Tools\Verifica\164\H3.dpr) on the pictures of TResampleCases and on a screen made
  ///   with TEditorScenarios.ModelOps(555, 700), for each of the five methods: with the Lanczos of the imaging library
  ///   the screens are the same
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomTextArtConverter = class(TObject)
  strict private
    FFake: TFakeResampler;
    FFakeIntf: IImagingResampler;
    FScreen: IEndoomScreen;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeChiedereLaPitturaDi160PerCinquanta;
    [Test]
    procedure DovrebbeDareOgniCellaDaiQuattroPixelAlSuoPosto;
    [Test]
    procedure DovrebbeLasciareCioCheIlMetodoNonDecide;
    [Test]
    procedure DovrebbeIgnorareLAlphaDeiPixel;
    [Test]
    procedure DovrebbeRifiutareUnRicampionatoreNil;
    [Test]
    procedure DovrebbeRifiutareUnaSchermataEUnMetodoNil;
    [Test]
    procedure DovrebbeDareLeStesseSchermateDelVecchioBitmapToScreen;
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.Factory, DelphiDoom.Endoom.TextArt.Types, DelphiDoom.Endoom.TextArt.Intf,
  DelphiDoom.Endoom.TextArt.Factory, DelphiDoom.Imaging.Resampler,
  DelphiDoom.Tests.Endoom.Digest, DelphiDoom.Tests.Endoom.EditorScenarios, DelphiDoom.Tests.Endoom.EditorHelper,
  DelphiDoom.Tests.Imaging.ResampleCases;

{ TFakeResampler }

function TFakeResampler.Resample(const ASource: TArray<Cardinal>; ASourceWidth, ASourceHeight,
  ADestinationWidth, ADestinationHeight: Integer): TArray<Cardinal>;
begin
  Inc(Calls);
  SourceWidth := ASourceWidth;
  SourceHeight := ASourceHeight;
  DestinationWidth := ADestinationWidth;
  DestinationHeight := ADestinationHeight;
  Result := Pixels;
end;

{ TTestEndoomTextArtConverter }

procedure TTestEndoomTextArtConverter.Setup;
begin
  FFake := TFakeResampler.Create;
  FFakeIntf := FFake;
  FScreen := TEndoomFactory.CreateScreen;
  SetLength(FFake.Pixels, ENDOOM_COLUMNS * 2 * ENDOOM_ROWS * 2);
end;

procedure TTestEndoomTextArtConverter.DovrebbeChiedereLaPitturaDi160PerCinquanta;
begin
  TEndoomTextArtFactory.CreateConverter(FFakeIntf).Convert(FScreen, [1, 2, 3, 4, 5, 6], 3, 2,
    TEndoomTextArtFactory.CreateMethod(eakBackgroundOnly));
  Assert.AreEqual(1, FFake.Calls);
  Assert.AreEqual(3, FFake.SourceWidth);
  Assert.AreEqual(2, FFake.SourceHeight);
  Assert.AreEqual(160, FFake.DestinationWidth);
  Assert.AreEqual(50, FFake.DestinationHeight);
end;

procedure TTestEndoomTextArtConverter.DovrebbeDareOgniCellaDaiQuattroPixelAlSuoPosto;
var
  LX: Integer;
  LY: Integer;
begin
  // the cell (3, 2) has the four pixels of the columns 6, 7 and of the rows 4, 5: blue there, black elsewhere
  FFake.Pixels[4 * 160 + 6] := $0000AA;
  FFake.Pixels[4 * 160 + 7] := $0000AA;
  FFake.Pixels[5 * 160 + 6] := $0000AA;
  FFake.Pixels[5 * 160 + 7] := $0000AA;
  TEndoomTextArtFactory.CreateConverter(FFakeIntf).Convert(FScreen, [0], 1, 1,
    TEndoomTextArtFactory.CreateMethod(eakBackgroundOnly));
  for LY := 0 to ENDOOM_ROWS - 1 do
    for LX := 0 to ENDOOM_COLUMNS - 1 do
      if (LX = 3) and (LY = 2) then
        Assert.AreEqual(1, FScreen.GetBackground(LX, LY))
      else
        Assert.AreEqual(0, FScreen.GetBackground(LX, LY));
end;

procedure TTestEndoomTextArtConverter.DovrebbeLasciareCioCheIlMetodoNonDecide;
begin
  FScreen.SetCharacter(10, 10, 66);
  FScreen.SetForeground(10, 10, 12);
  TEndoomTextArtFactory.CreateConverter(FFakeIntf).Convert(FScreen, [0], 1, 1,
    TEndoomTextArtFactory.CreateMethod(eakBackgroundOnly));
  Assert.AreEqual(66, Integer(FScreen.GetCharacter(10, 10)));
  Assert.AreEqual(12, FScreen.GetForeground(10, 10));
end;

procedure TTestEndoomTextArtConverter.DovrebbeIgnorareLAlphaDeiPixel;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FFake.Pixels) do
    FFake.Pixels[LIndex] := $FF0000AA;
  TEndoomTextArtFactory.CreateConverter(FFakeIntf).Convert(FScreen, [0], 1, 1,
    TEndoomTextArtFactory.CreateMethod(eakBackgroundOnly));
  Assert.AreEqual(1, FScreen.GetBackground(0, 0));
  Assert.AreEqual(1, FScreen.GetBackground(79, 24));
end;

procedure TTestEndoomTextArtConverter.DovrebbeRifiutareUnRicampionatoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TEndoomTextArtFactory.CreateConverter(nil);
    end, EArgumentNilException);
end;

procedure TTestEndoomTextArtConverter.DovrebbeRifiutareUnaSchermataEUnMetodoNil;
var
  LConverter: IEndoomTextArtConverter;
begin
  LConverter := TEndoomTextArtFactory.CreateConverter(FFakeIntf);
  Assert.WillRaise(
    procedure
    begin
      LConverter.Convert(nil, [0], 1, 1, TEndoomTextArtFactory.CreateMethod(eakDither));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      LConverter.Convert(FScreen, [0], 1, 1, nil);
    end, EArgumentNilException);
end;

procedure TTestEndoomTextArtConverter.DovrebbeDareLeStesseSchermateDelVecchioBitmapToScreen;
var
  LGolden: TArray<string>;
  LConverter: IEndoomTextArtConverter;
  LCase: Integer;
  LMethod: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LPixels: TArray<Cardinal>;
  LCount: Integer;
begin
  LGolden := TEditorHelper.GoldenLines('TEXTART', 'textart.golden.txt');
  LConverter := TEndoomTextArtFactory.CreateConverter(TImagingLanczosResampler.Create);
  LCount := 0;
  for LCase := 0 to TResampleCases.Count - 1 do
  begin
    LPixels := TResampleCases.Build(LCase, LWidth, LHeight);
    for LMethod := 0 to Ord(High(TEndoomTextArtKind)) do
    begin
      FScreen.Clear;
      TEditorHelper.ApplyOps(FScreen, TEditorScenarios.ModelOps(555, 700));
      LConverter.Convert(FScreen, LPixels, LWidth, LHeight, TEndoomTextArtFactory.CreateMethod(TEndoomTextArtKind(LMethod)));
      Assert.AreEqual(Format('%s %d %s', [TResampleCases.Name(LCase), LMethod, TEndoomDigest.OfBytes(FScreen.ToBytes)]),
        LGolden[LCount]);
      Inc(LCount);
    end;
  end;
  Assert.AreEqual(Length(LGolden), LCount);
end;

end.
