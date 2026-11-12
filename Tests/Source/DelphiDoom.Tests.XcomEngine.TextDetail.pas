{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the text at the resolution of the display in the   }
{  widgets (Text, TextButton, TextList, TextEdit): the picture of the game      }
{  does not change and the ink falls on the same cells                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.TextDetail;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.FontDetail.Intf,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.TextEdit, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.DetailFakes;

type
  /// <summary>
  ///   The fonts are the ones of the fake resources (the small one: cells of 8 x 8, characters of 4 x 6 from the
  ///   column 1 and the row 1, one pixel between two). With WithDetail they get a fake detail: every character a
  ///   full rectangle as large as its picture times the scale. The "screen" is a surface of 320 x 200
  /// </summary>
  [TestFixture]
  [Category('XcomUi')]
  TTestXcomTextDetail = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FBase: TXcomSurface;
    FLayers: TFakeInkLayers;
    FLayersRef: IXcomInkLayers;
    FSmallDetail: TFakeFontDetail;
    FBigDetail: TFakeFontDetail;
    FText: TXcomText;
    function Small: TXcomFont;
    function Big: TXcomFont;
    procedure WithDetail(AScale: Integer);
    procedure SetScale(AScale: Integer);
    function NewText(AWidth, AHeight, AX, AY: Integer): TXcomText;
    /// <summary>The pixels of ASurface after a text made by AMake was blitted on it</summary>
    function Front(const AInk: TXcomInkBuffer; AX, AY: Integer): Cardinal;
    function InkAt(const AInk: TXcomInkBuffer; AX, AY: Integer): Boolean;
    procedure AssertInkCoversTheText(ASurface: TXcomSurface; const AInk: TXcomInkBuffer);
    class function SameBytes(const AFirst, ASecond: TBytes): Boolean; static;
    class function CopyOf(const ABytes: TBytes): TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaDettaglioIlTestoNonDovrebbeChiedereNulla;
    [Test]
    procedure IlTestoDovrebbeLasciareLInchiostroSulSuoRettangolo;
    [Test]
    [TestCase('doppio', '2')]
    [TestCase('triplo', '3')]
    [TestCase('quadruplo', '4')]
    procedure LImmagineDelGiocoDovrebbeRestareIdentica(AScale: Integer);
    [Test]
    [TestCase('sinistra', '0')]
    [TestCase('centro', '1')]
    [TestCase('destra', '2')]
    procedure LInchiostroDovrebbeCoprireLeStesseCelleDelTesto(AAlign: Integer);
    [Test]
    procedure IlTestoACapoDovrebbeAvereLeStesseRigheELInchiostroSuOgniRiga;
    [Test]
    procedure IlColoreDovrebbeEssereQuelloDelTestoConIlLivelloUno;
    [Test]
    procedure IlTestoSecondarioInvertitoEAdAltoContrastoDovrebberoCambiareLIndice;
    [Test]
    procedure UnCarattereSenzaDettaglioDovrebbeEssereLImmagineIngrandita;
    [Test]
    procedure IlTestoNonDovrebbeUscireDalSuoRettangolo;
    [Test]
    procedure UnTestoNascostoNonDovrebbeLasciareInchiostro;
    [Test]
    procedure UnTestoVuotoNonDovrebbeLasciareInchiostro;
    [Test]
    procedure SuUnaSuperficieCheNonELoSchermoDovrebbeSoloDisegnarsi;
    [Test]
    procedure AlCambioDiScalaIlTestoDovrebbeRidisegnarsi;
    [Test]
    procedure QuandoLaScalaTornaAUnoIlTestoNonDovrebbeLasciareInchiostro;
    [Test]
    procedure LInchiostroDovrebbeEssereRifattoSoloQuandoIlTestoCambia;
    [Test]
    procedure IlPulsanteDovrebbeLasciareUnSoloStratoConLaSuaFaccia;
    [Test]
    procedure IlPulsanteDovrebbeRestareIdenticoNellImmagineDelGioco;
    [Test]
    procedure LaListaDovrebbeLasciareUnSoloStratoConLeSueRighe;
    [Test]
    procedure LaListaDovrebbeTagliareIlTestoAllaColonna;
    [Test]
    procedure IlCampoDiTestoDovrebbeLasciareIlTestoEIlCursore;
    [Test]
    procedure SuUnaSuperficieAIndiciIlTestoDovrebbeDisegnarsiAllaScala;
    [Test]
    procedure SenzaDettaglioDrawDetailNonDovrebbeDisegnare;
  end;

implementation

type
  TFlatState = class(TXcomState)
  end;

const
  TEXT_COLOR = 20;

procedure TTestXcomTextDetail.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FBase := TXcomSurface.Create(320, 200);
  FLayers := TFakeInkLayers.Create;
  FLayersRef := FLayers;
  FLayers.Base := FBase;
end;

procedure TTestXcomTextDetail.TearDown;
begin
  FreeAndNil(FText);
  // the fonts of the world hold the details: they go before the layers
  Small.Detail := nil;
  Big.Detail := nil;
  FSmallDetail := nil;
  FBigDetail := nil;
  FState.Free;
  FBase.Free;
  FLayersRef := nil;
  FWorld.Free;
end;

function TTestXcomTextDetail.Small: TXcomFont;
begin
  Result := FWorld.Resources.GetFont('FONT_SMALL');
end;

function TTestXcomTextDetail.Big: TXcomFont;
begin
  Result := FWorld.Resources.GetFont('FONT_BIG');
end;

procedure TTestXcomTextDetail.WithDetail(AScale: Integer);
begin
  FSmallDetail := TFakeFontDetail.Create(Small, FLayersRef, AScale);
  Small.Detail := FSmallDetail;
  FBigDetail := TFakeFontDetail.Create(Big, FLayersRef, AScale);
  Big.Detail := FBigDetail;
end;

procedure TTestXcomTextDetail.SetScale(AScale: Integer);
begin
  FSmallDetail.ScaleValue := AScale;
  FBigDetail.ScaleValue := AScale;
end;

function TTestXcomTextDetail.NewText(AWidth, AHeight, AX, AY: Integer): TXcomText;
begin
  FreeAndNil(FText);
  FText := TXcomText.Create(AWidth, AHeight, AX, AY);
  FText.InitText(Big, Small, FWorld.Game.Language);
  FText.SetColor(TEXT_COLOR);
  Result := FText;
end;

function TTestXcomTextDetail.Front(const AInk: TXcomInkBuffer; AX, AY: Integer): Cardinal;
begin
  Result := AInk.Pixels[AY * AInk.Width * AInk.Scale + AX] shr 16;
end;

function TTestXcomTextDetail.InkAt(const AInk: TXcomInkBuffer; AX, AY: Integer): Boolean;
begin
  Result := AInk.Cells[AY * AInk.Width + AX] <> 0;
end;

procedure TTestXcomTextDetail.AssertInkCoversTheText(ASurface: TXcomSurface; const AInk: TXcomInkBuffer);
var
  LX: Integer;
  LY: Integer;
  LPixels: Integer;
  LCells: Integer;
  LLeft: Integer;
  LRight: Integer;
  LInkLeft: Integer;
  LInkRight: Integer;
begin
  // every pixel of the text of the game has ink, and the ink does not go beyond the columns and rows of the text
  LPixels := 0;
  LCells := 0;
  LLeft := ASurface.Width;
  LRight := -1;
  LInkLeft := ASurface.Width;
  LInkRight := -1;
  for LY := 0 to ASurface.Height - 1 do
    for LX := 0 to ASurface.Width - 1 do
    begin
      if ASurface.GetPixel(LX, LY) <> 0 then
      begin
        Inc(LPixels);
        if LX < LLeft then
          LLeft := LX;
        if LX > LRight then
          LRight := LX;
        if not InkAt(AInk, LX, LY) then
          Assert.Fail(Format('il pixel %d,%d del testo non ha inchiostro', [LX, LY]));
      end;
      if InkAt(AInk, LX, LY) then
      begin
        Inc(LCells);
        if LX < LInkLeft then
          LInkLeft := LX;
        if LX > LInkRight then
          LInkRight := LX;
      end;
    end;
  Assert.IsTrue(LPixels > 0, 'il testo non ha pixel');
  Assert.AreEqual(LLeft, LInkLeft, 'prima colonna');
  Assert.AreEqual(LRight, LInkRight, 'ultima colonna');
  // the fake characters have ink exactly where their picture has a pixel
  Assert.AreEqual(LPixels, LCells, 'pixel con inchiostro');
end;

class function TTestXcomTextDetail.CopyOf(const ABytes: TBytes): TBytes;
begin
  Result := Copy(ABytes);
end;

class function TTestXcomTextDetail.SameBytes(const AFirst, ASecond: TBytes): Boolean;
begin
  Result := (Length(AFirst) = Length(ASecond)) and ((Length(AFirst) = 0) or
    CompareMem(@AFirst[0], @ASecond[0], Length(AFirst)));
end;

procedure TTestXcomTextDetail.SenzaDettaglioIlTestoNonDovrebbeChiedereNulla;
begin
  NewText(100, 20, 30, 40).SetText('AB');
  FText.Blit(FBase);
  Assert.AreEqual(0, FLayers.Asked);
  Assert.IsTrue(FText.Ink = nil);
  Assert.AreEqual(0, FText.DetailScale);
  Assert.IsFalse(FText.IsInkStale);
end;

procedure TTestXcomTextDetail.IlTestoDovrebbeLasciareLInchiostroSulSuoRettangolo;
var
  LLayer: TFakeInkLayer;
begin
  WithDetail(2);
  NewText(100, 20, 30, 40).SetText('AB');
  FText.Blit(FBase);
  Assert.AreEqual(1, FLayers.Layers.Count);
  LLayer := FLayers.Last;
  Assert.IsTrue(LLayer.Ended);
  Assert.AreEqual(30, LLayer.X);
  Assert.AreEqual(40, LLayer.Y);
  Assert.AreEqual(100, LLayer.Width);
  Assert.AreEqual(20, LLayer.Height);
  Assert.AreEqual(2, LLayer.Ink.Scale);
  Assert.AreEqual(100, LLayer.Ink.Width);
  Assert.AreEqual(20, LLayer.Ink.Height);
  Assert.AreEqual(0, Integer(Length(LLayer.Under)));
  // and the text of the game is on the screen as always
  Assert.AreNotEqual(0, Integer(FBase.GetPixel(30, 41)));
end;

procedure TTestXcomTextDetail.LImmagineDelGiocoDovrebbeRestareIdentica(AScale: Integer);
var
  LPlain: TBytes;
  LWidth: Integer;
  LLines: Integer;
  LHeight: Integer;
begin
  NewText(60, 40, 5, 6).SetWordWrap(True);
  FText.SetAlign(haCenter);
  FText.SetText('ABC DEF GHI JKL MNO PQR');
  FText.Blit(FBase);
  LPlain := CopyOf(FBase.Pixels);
  LWidth := FText.GetTextWidth;
  LLines := FText.GetNumLines;
  LHeight := FText.GetTextHeight;
  FBase.Clear(0);
  WithDetail(AScale);
  NewText(60, 40, 5, 6).SetWordWrap(True);
  FText.SetAlign(haCenter);
  FText.SetText('ABC DEF GHI JKL MNO PQR');
  FText.Blit(FBase);
  Assert.AreEqual(1, FLayers.Layers.Count);
  Assert.IsTrue(SameBytes(LPlain, FBase.Pixels), 'l''immagine del gioco e'' cambiata');
  Assert.AreEqual(LWidth, FText.GetTextWidth);
  Assert.AreEqual(LLines, FText.GetNumLines);
  Assert.AreEqual(LHeight, FText.GetTextHeight);
end;

procedure TTestXcomTextDetail.LInchiostroDovrebbeCoprireLeStesseCelleDelTesto(AAlign: Integer);
begin
  WithDetail(3);
  NewText(80, 12, 0, 0).SetAlign(TXcomTextHAlign(AAlign));
  FText.SetText('AB CD');
  FText.Blit(FBase);
  AssertInkCoversTheText(FText, FLayers.Last.Ink);
end;

procedure TTestXcomTextDetail.IlTestoACapoDovrebbeAvereLeStesseRigheELInchiostroSuOgniRiga;
begin
  WithDetail(2);
  NewText(30, 40, 0, 0).SetWordWrap(True);
  FText.SetVerticalAlign(vaMiddle);
  FText.SetText('ABC DEF GHI');
  FText.Blit(FBase);
  Assert.AreEqual(3, FText.GetNumLines);
  AssertInkCoversTheText(FText, FLayers.Last.Ink);
end;

procedure TTestXcomTextDetail.IlColoreDovrebbeEssereQuelloDelTestoConIlLivelloUno;
var
  LInk: TXcomInkBuffer;
begin
  WithDetail(2);
  NewText(40, 10, 0, 0).SetText('A');
  FText.Blit(FBase);
  LInk := FLayers.Last.Ink;
  // the picture starts at the row 1 of the cell: there the ink is the body, fully covered, of the color + 1
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 1)), Front(LInk, 0, 2));
  Assert.AreEqual(Cardinal(0), Front(LInk, 0, 0));
end;

procedure TTestXcomTextDetail.IlTestoSecondarioInvertitoEAdAltoContrastoDovrebberoCambiareLIndice;
var
  LSecond: Integer;
begin
  WithDetail(2);
  NewText(60, 10, 0, 0).SetSecondaryColor(90);
  // the token 1 switches to the secondary color
  FText.SetText('A' + Char(XCOM_TOKEN_COLOR_FLIP) + 'B');
  FText.Blit(FBase);
  LSecond := Small.GetCharSize(Ord('A')).W * 2;
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 1)), Front(FLayers.Last.Ink, 0, 2));
  Assert.AreEqual(Cardinal((255 shl 8) or 91), Front(FLayers.Last.Ink, LSecond, 2));
  FText.SetInvert(True);
  FText.Blit(FBase);
  // inverted around 3: 1 + 2 * (3 - 1)
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 5)), Front(FLayers.Last.Ink, 0, 2));
  FText.SetInvert(False);
  FText.SetHighContrast(True);
  FText.Blit(FBase);
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 3)), Front(FLayers.Last.Ink, 0, 2));
end;

procedure TTestXcomTextDetail.UnCarattereSenzaDettaglioDovrebbeEssereLImmagineIngrandita;
var
  LInk: TXcomInkBuffer;
  LSecond: Integer;
begin
  WithDetail(2);
  FSmallDetail.Missing.Add(Ord('B'));
  // a picture with two levels, to see that the levels are kept
  Small.ImageSurface(0).SetPixel(Small.GetChar(Ord('B')).Crop.X + 1, Small.GetChar(Ord('B')).Crop.Y + 1, 2);
  NewText(40, 10, 0, 0).SetText('AB');
  FText.Blit(FBase);
  LInk := FLayers.Last.Ink;
  LSecond := Small.GetCharSize(Ord('A')).W;
  // every pixel of the picture of B is a square of two by two of its own level, all covered
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 1)), Front(LInk, LSecond * 2, 1 * 2));
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 2)), Front(LInk, (LSecond + 1) * 2, 1 * 2));
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 2)), Front(LInk, (LSecond + 1) * 2 + 1, 1 * 2 + 1));
  // the row 0 of the picture is empty: no ink there; A, that has its detail, has the level 1 only
  Assert.AreEqual(Cardinal(0), Front(LInk, LSecond * 2, 0));
  Assert.AreEqual(Cardinal((255 shl 8) or (TEXT_COLOR + 1)), Front(LInk, 0, 2));
end;

procedure TTestXcomTextDetail.IlTestoNonDovrebbeUscireDalSuoRettangolo;
var
  LInk: TXcomInkBuffer;
  LIndex: Integer;
begin
  WithDetail(2);
  // room for two characters and a half
  NewText(12, 8, 0, 0).SetText('ABCDEF');
  FText.Blit(FBase);
  LInk := FLayers.Last.Ink;
  Assert.AreEqual(12 * 2 * 8 * 2, Integer(Length(LInk.Pixels)));
  for LIndex := 0 to 7 do
    Assert.IsTrue(InkAt(LInk, 11, LIndex) = (FText.GetPixel(11, LIndex) <> 0));
end;

procedure TTestXcomTextDetail.UnTestoNascostoNonDovrebbeLasciareInchiostro;
begin
  WithDetail(2);
  NewText(40, 10, 0, 0).SetText('A');
  FText.Visible := False;
  FText.Blit(FBase);
  FText.Visible := True;
  FText.Hidden := True;
  FText.Blit(FBase);
  Assert.AreEqual(0, FLayers.Layers.Count);
  Assert.AreEqual(0, Integer(FBase.GetPixel(1, 1)));
end;

procedure TTestXcomTextDetail.UnTestoVuotoNonDovrebbeLasciareInchiostro;
begin
  WithDetail(2);
  NewText(40, 10, 0, 0).SetText('');
  FText.Blit(FBase);
  FText.SetText('   ');
  FText.Blit(FBase);
  Assert.AreEqual(0, FLayers.Layers.Count);
end;

procedure TTestXcomTextDetail.SuUnaSuperficieCheNonELoSchermoDovrebbeSoloDisegnarsi;
var
  LOther: TXcomSurface;
begin
  WithDetail(2);
  LOther := TXcomSurface.Create(320, 200);
  try
    NewText(40, 10, 0, 0).SetText('A');
    FText.Blit(LOther);
    Assert.AreEqual(0, FLayers.Layers.Count);
    Assert.AreNotEqual(0, Integer(LOther.GetPixel(1, 1)));
    // the owner of that surface can still take the characters
    Assert.IsTrue(FText.Ink <> nil);
    Assert.AreEqual(1, FText.Ink.Count);
  finally
    LOther.Free;
  end;
end;

procedure TTestXcomTextDetail.AlCambioDiScalaIlTestoDovrebbeRidisegnarsi;
begin
  WithDetail(2);
  NewText(40, 10, 0, 0).SetText('A');
  FText.Blit(FBase);
  Assert.AreEqual(2, FLayers.Last.Ink.Scale);
  SetScale(3);
  Assert.IsTrue(FText.IsInkStale);
  FText.Blit(FBase);
  Assert.AreEqual(3, FLayers.Last.Ink.Scale);
  Assert.AreEqual(40 * 3 * 10 * 3, Integer(Length(FLayers.Last.Ink.Pixels)));
  Assert.IsFalse(FText.IsInkStale);
end;

procedure TTestXcomTextDetail.QuandoLaScalaTornaAUnoIlTestoNonDovrebbeLasciareInchiostro;
begin
  WithDetail(2);
  NewText(40, 10, 0, 0).SetText('A');
  FText.Blit(FBase);
  SetScale(1);
  FText.Blit(FBase);
  Assert.AreEqual(1, FLayers.Layers.Count);
  Assert.IsTrue(FText.Ink = nil);
  Assert.AreNotEqual(0, Integer(FBase.GetPixel(1, 1)));
end;

procedure TTestXcomTextDetail.LInchiostroDovrebbeEssereRifattoSoloQuandoIlTestoCambia;
var
  LAsked: Integer;
begin
  WithDetail(2);
  NewText(40, 10, 0, 0).SetText('AB');
  FText.Blit(FBase);
  LAsked := FSmallDetail.Asked;
  Assert.AreEqual(2, LAsked);
  FText.Blit(FBase);
  FText.Blit(FBase);
  Assert.AreEqual(LAsked, FSmallDetail.Asked);
  Assert.AreEqual(3, FLayers.Layers.Count);
  FText.SetText('ABC');
  FText.Blit(FBase);
  Assert.AreEqual(LAsked + 3, FSmallDetail.Asked);
end;

procedure TTestXcomTextDetail.IlPulsanteDovrebbeLasciareUnSoloStratoConLaSuaFaccia;
var
  LButton: TXcomTextButton;
  LLayer: TFakeInkLayer;
  LX: Integer;
  LY: Integer;
  LText: Integer;
begin
  WithDetail(2);
  LButton := TXcomTextButton.Create(50, 16, 20, 30);
  FState.Add(LButton);
  LButton.SetColor(40);
  LButton.SetText('AB');
  LButton.Blit(FBase);
  // one layer, of the button: the text inside it is not on the screen by itself
  Assert.AreEqual(1, FLayers.Layers.Count);
  LLayer := FLayers.Last;
  Assert.AreEqual(20, LLayer.X);
  Assert.AreEqual(30, LLayer.Y);
  Assert.AreEqual(50, LLayer.Width);
  Assert.AreEqual(16, LLayer.Height);
  Assert.AreEqual(50 * 16, Integer(Length(LLayer.Under)));
  // the face without the text: the border is there, and where the text is the face shows
  Assert.AreEqual(Integer(LButton.GetPixel(0, 0)), Integer(LLayer.Under[0]));
  LText := 0;
  for LY := 0 to 15 do
    for LX := 0 to 49 do
      if LLayer.Under[LY * 50 + LX] <> LButton.GetPixel(LX, LY) then
      begin
        Inc(LText);
        Assert.IsTrue(InkAt(LLayer.Ink, LX, LY), 'un pixel del testo del pulsante senza inchiostro');
      end;
  Assert.IsTrue(LText > 0);
end;

procedure TTestXcomTextDetail.IlPulsanteDovrebbeRestareIdenticoNellImmagineDelGioco;
var
  LButton: TXcomTextButton;
  LPlain: TBytes;
begin
  LButton := TXcomTextButton.Create(50, 16, 20, 30);
  FState.Add(LButton);
  LButton.SetColor(40);
  LButton.SetText('AB');
  LButton.Blit(FBase);
  LPlain := CopyOf(FBase.Pixels);
  Assert.AreEqual(0, FLayers.Asked);
  FBase.Clear(0);
  WithDetail(4);
  // the fonts changed under the button: it draws itself again
  LButton.Blit(FBase);
  Assert.AreEqual(1, FLayers.Layers.Count);
  Assert.AreEqual(4, FLayers.Last.Ink.Scale);
  Assert.IsTrue(SameBytes(LPlain, FBase.Pixels), 'l''immagine del gioco e'' cambiata');
end;

procedure TTestXcomTextDetail.LaListaDovrebbeLasciareUnSoloStratoConLeSueRighe;
var
  LList: TXcomTextList;
  LLayer: TFakeInkLayer;
  LPlain: TBytes;
begin
  LList := TXcomTextList.Create(FWorld.Game.Options, FWorld.Game.Clock, 100, 40, 10, 20);
  FState.Add(LList);
  LList.SetColor(TEXT_COLOR);
  LList.SetColumns([60, 40]);
  LList.AddRow(['AB', 'C']);
  LList.AddRow(['DE', 'F']);
  TXcomSurface(LList).Blit(FBase);
  LPlain := CopyOf(FBase.Pixels);
  Assert.AreEqual(0, FLayers.Asked);
  FBase.Clear(0);
  WithDetail(2);
  TXcomSurface(LList).Blit(FBase);
  Assert.IsTrue(SameBytes(LPlain, FBase.Pixels), 'l''immagine del gioco e'' cambiata');
  Assert.AreEqual(1, FLayers.Layers.Count);
  LLayer := FLayers.Last;
  Assert.AreEqual(10, LLayer.X);
  Assert.AreEqual(20, LLayer.Y);
  Assert.AreEqual(100, LLayer.Width);
  Assert.AreEqual(40, LLayer.Height);
  Assert.AreEqual(0, Integer(Length(LLayer.Under)));
  AssertInkCoversTheText(LList, LLayer.Ink);
end;

procedure TTestXcomTextDetail.LaListaDovrebbeTagliareIlTestoAllaColonna;
var
  LList: TXcomTextList;
  LX: Integer;
  LY: Integer;
begin
  WithDetail(2);
  LList := TXcomTextList.Create(FWorld.Game.Options, FWorld.Game.Clock, 100, 40, 10, 20);
  FState.Add(LList);
  LList.SetColor(TEXT_COLOR);
  LList.SetColumns([22, 78]);
  // the first cell is too long for its column
  LList.AddRow(['ABCDEFGHIJ', 'K']);
  TXcomSurface(LList).Blit(FBase);
  for LY := 0 to 39 do
    for LX := 0 to 99 do
      Assert.IsTrue(InkAt(FLayers.Last.Ink, LX, LY) = (LList.GetPixel(LX, LY) <> 0),
        Format('inchiostro e testo diversi in %d,%d', [LX, LY]));
end;

procedure TTestXcomTextDetail.IlCampoDiTestoDovrebbeLasciareIlTestoEIlCursore;
var
  LEdit: TXcomTextEdit;
  LLayer: TFakeInkLayer;
  LPlain: TBytes;
begin
  LEdit := TXcomTextEdit.Create(FState, 100, 12, 10, 10);
  FState.Add(LEdit);
  LEdit.SetColor(TEXT_COLOR);
  LEdit.SetText('AB');
  LEdit.Blit(FBase);
  LPlain := CopyOf(FBase.Pixels);
  FBase.Clear(0);
  WithDetail(2);
  LEdit.Blit(FBase);
  Assert.IsTrue(SameBytes(LPlain, FBase.Pixels), 'l''immagine del gioco e'' cambiata');
  Assert.AreEqual(1, FLayers.Layers.Count);
  LLayer := FLayers.Last;
  Assert.AreEqual(10, LLayer.X);
  Assert.AreEqual(10, LLayer.Y);
  Assert.AreEqual(100, LLayer.Width);
  Assert.AreEqual(12, LLayer.Height);
  AssertInkCoversTheText(LEdit, LLayer.Ink);
end;

procedure TTestXcomTextDetail.SuUnaSuperficieAIndiciIlTestoDovrebbeDisegnarsiAllaScala;
var
  LTarget: TXcomSurface;
begin
  WithDetail(3);
  LTarget := TXcomSurface.Create(120, 60);
  try
    NewText(30, 10, 0, 0).SetText('AB');
    Assert.IsFalse(FText.DrawDetail(LTarget, 6, 9, 2));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(6, 12)));
    Assert.IsTrue(FText.DrawDetail(LTarget, 6, 9, 3));
    // the first character: its cell at (6, 9), the picture from the row 1, of the color + 1
    Assert.AreEqual(0, Integer(LTarget.GetPixel(6, 9)));
    Assert.AreEqual(TEXT_COLOR + 1, Integer(LTarget.GetPixel(6, 12)));
    Assert.AreEqual(TEXT_COLOR + 1, Integer(LTarget.GetPixel(6 + 4 * 3 - 1, 12)));
    // the pixel between two characters
    Assert.AreEqual(0, Integer(LTarget.GetPixel(6 + 4 * 3, 12)));
    Assert.AreEqual(TEXT_COLOR + 1, Integer(LTarget.GetPixel(6 + 5 * 3, 12)));
    Assert.AreEqual(0, FLayers.Asked);
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomTextDetail.SenzaDettaglioDrawDetailNonDovrebbeDisegnare;
var
  LTarget: TXcomSurface;
begin
  LTarget := TXcomSurface.Create(120, 60);
  try
    NewText(30, 10, 0, 0).SetText('AB');
    Assert.IsFalse(FText.DrawDetail(LTarget, 0, 0, 2));
  finally
    LTarget.Free;
  end;
end;

end.
