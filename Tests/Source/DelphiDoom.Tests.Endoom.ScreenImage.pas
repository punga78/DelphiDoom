{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomScreenImage and TEndoomEmbeddedFontSource        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.ScreenImage;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The RENDERM and RENDERF lines of Tests\Data\Endoom\editor.golden.txt are the pixels of GetBitmap of the old
  ///   TEndScreen with the font of ENDEDIT. The old flag was blink (true hides the characters of the cells that
  ///   blink); the one of the library is ABlinkVisible, the opposite: blink = 1 is ABlinkVisible = false
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomScreenImage = class(TObject)
  strict private
    FImage: IEndoomScreenImage;
    FFont: TBytes;
    FPixels: TArray<Cardinal>;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDisegnareSeicentoquarantaPerDuecento;
    [Test]
    procedure DovrebbeUsareIColoriDelModoTestoConAlphaPieno;
    [Test]
    procedure DovrebbeMostrareOCelareIlCarattereCheLampeggia;
    [Test]
    procedure DovrebbeRiusareLoStessoBuffer;
    [Test]
    procedure DovrebbeRifiutareUnaSchermataNil;
    [Test]
    procedure DovrebbeRifiutareUnRendererNil;
    [Test]
    procedure DovrebbeDareGliStessiPixelDelVecchioTEndScreenSuiModelli;
    [Test]
    procedure DovrebbeDareGliStessiPixelDelVecchioTEndScreenSulleSchermateDiProva;
    [Test]
    procedure DovrebbeDareIlFontDellEditorDi16384Byte;
    [Test]
    procedure DovrebbeDareUnaCopiaDelFont;
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.Factory, DelphiDoom.Endoom.ScreenImage,
  DelphiDoom.Tests.Endoom.EditorScenarios, DelphiDoom.Tests.Endoom.EditorHelper, DelphiDoom.Tests.Endoom.Fixtures;

{ TTestEndoomScreenImage }

procedure TTestEndoomScreenImage.Setup;
begin
  FImage := TEndoomFactory.CreateScreenImage;
  FFont := TEndoomFactory.CreateEditorFontSource.GetFont;
  FPixels := nil;
end;

procedure TTestEndoomScreenImage.DovrebbeDisegnareSeicentoquarantaPerDuecento;
begin
  FImage.Render(TEndoomFactory.CreateScreen, FFont, True, FPixels);
  Assert.AreEqual(ENDOOM_WIDTH * ENDOOM_HEIGHT, Length(FPixels));
  Assert.AreEqual(640, ENDOOM_WIDTH);
  Assert.AreEqual(200, ENDOOM_HEIGHT);
end;

procedure TTestEndoomScreenImage.DovrebbeUsareIColoriDelModoTestoConAlphaPieno;
var
  LScreen: IEndoomScreen;
  LColor: Integer;
begin
  LScreen := TEndoomFactory.CreateScreen;
  // the empty cells (code 0) show the background
  for LColor := 0 to ENDOOM_BACKGROUND_COLOR_COUNT - 1 do
    LScreen.SetBackground(LColor, 0, LColor);
  FImage.Render(LScreen, FFont, True, FPixels);
  for LColor := 0 to ENDOOM_BACKGROUND_COLOR_COUNT - 1 do
    Assert.AreEqual(Int64(Cardinal($FF000000) or ENDOOM_COLORS[LColor]), Int64(FPixels[LColor * 8]));
end;

procedure TTestEndoomScreenImage.DovrebbeMostrareOCelareIlCarattereCheLampeggia;
var
  LScreen: IEndoomScreen;
  LShown: TArray<Cardinal>;
  LHidden: TArray<Cardinal>;
begin
  LScreen := TEndoomFactory.CreateScreen;
  // a full block: every pixel is the foreground, or the background when it is hidden
  LScreen.SetCharacter(0, 0, $DB);
  LScreen.SetForeground(0, 0, 15);
  LScreen.SetBackground(0, 0, 1);
  LScreen.SetBlink(0, 0, True);
  FImage.Render(LScreen, FFont, True, LShown);
  FImage.Render(LScreen, FFont, False, LHidden);
  Assert.AreEqual(Int64(Cardinal($FF000000) or ENDOOM_COLORS[15]), Int64(LShown[0]));
  Assert.AreEqual(Int64(Cardinal($FF000000) or ENDOOM_COLORS[1]), Int64(LHidden[0]));
  // a cell that does not blink does not change
  LScreen.SetBlink(0, 0, False);
  FImage.Render(LScreen, FFont, False, LHidden);
  Assert.AreEqual(Int64(Cardinal($FF000000) or ENDOOM_COLORS[15]), Int64(LHidden[0]));
end;

procedure TTestEndoomScreenImage.DovrebbeRiusareLoStessoBuffer;
var
  LFirst: TArray<Cardinal>;
begin
  FImage.Render(TEndoomFactory.CreateScreen, FFont, True, FPixels);
  LFirst := FPixels;
  FImage.Render(TEndoomFactory.CreateScreen, FFont, True, FPixels);
  Assert.AreEqual(Length(LFirst), Length(FPixels));
end;

procedure TTestEndoomScreenImage.DovrebbeRifiutareUnaSchermataNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FImage.Render(nil, FFont, True, FPixels);
    end, EArgumentNilException);
end;

procedure TTestEndoomScreenImage.DovrebbeRifiutareUnRendererNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TEndoomScreenImage.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestEndoomScreenImage.DovrebbeDareGliStessiPixelDelVecchioTEndScreenSuiModelli;
var
  LGolden: TArray<string>;
  LSeed: Integer;
  LScreen: IEndoomScreen;
  LBlink: Integer;
begin
  LGolden := TEditorHelper.GoldenLines('RENDERM');
  Assert.AreEqual(12, Length(LGolden));
  for LSeed := 1 to 6 do
  begin
    LScreen := TEndoomFactory.CreateScreen;
    TEditorHelper.ApplyOps(LScreen, TEditorScenarios.ModelOps(Cardinal(LSeed * 1000 + 7), 600 * LSeed));
    for LBlink := 0 to 1 do
    begin
      FImage.Render(LScreen, FFont, LBlink = 0, FPixels);
      Assert.AreEqual(Format('%d %d %s', [LSeed, LBlink, TEditorHelper.PixelDigest(FPixels)]),
        LGolden[(LSeed - 1) * 2 + LBlink]);
    end;
  end;
end;

procedure TTestEndoomScreenImage.DovrebbeDareGliStessiPixelDelVecchioTEndScreenSulleSchermateDiProva;
var
  LGolden: TArray<string>;
  LKind: Integer;
  LScreen: IEndoomScreen;
  LBlink: Integer;
begin
  LGolden := TEditorHelper.GoldenLines('RENDERF');
  Assert.AreEqual(6, Length(LGolden));
  LScreen := TEndoomFactory.CreateScreen;
  for LKind := 0 to 2 do
  begin
    LScreen.LoadFromBytes(TEndoomFixtures.Screen(LKind));
    for LBlink := 0 to 1 do
    begin
      FImage.Render(LScreen, FFont, LBlink = 0, FPixels);
      Assert.AreEqual(Format('%d %d %s', [LKind, LBlink, TEditorHelper.PixelDigest(FPixels)]),
        LGolden[LKind * 2 + LBlink]);
    end;
  end;
end;

procedure TTestEndoomScreenImage.DovrebbeDareIlFontDellEditorDi16384Byte;
var
  LIndex: Integer;
  LCount: Integer;
begin
  Assert.AreEqual(ENDOOM_FONT_SIZE, Length(FFont));
  LCount := 0;
  for LIndex := 0 to High(FFont) do
    if FFont[LIndex] <> 0 then
      Inc(LCount);
  // 4281 pixels of the characters (the other 12103 are the background)
  Assert.AreEqual(4281, LCount);
end;

procedure TTestEndoomScreenImage.DovrebbeDareUnaCopiaDelFont;
var
  LOther: TBytes;
begin
  FFont[0] := 77;
  LOther := TEndoomFactory.CreateEditorFontSource.GetFont;
  Assert.AreEqual(0, Integer(LOther[0]));
end;

end.
