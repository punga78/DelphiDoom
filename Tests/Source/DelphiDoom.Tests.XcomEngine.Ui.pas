{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom interface library - the widgets drawn     }
{  with a font made by code                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Ui;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.ManualClock, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.Frame,
  DelphiDoom.XcomUi.NumberText, DelphiDoom.XcomUi.Cursor, DelphiDoom.XcomUi.FpsCounter,
  DelphiDoom.XcomUi.PaletteShift, DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('XcomUi')]
  TTestXcomText = class
  strict private
    FWorld: TTestWorld;
    FText: TXcomText;
    function NewText(AWidth, AHeight: Integer): TXcomText;
    function Count(ASurface: TXcomSurface; AValue: Byte): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure MisuraLaLarghezzaConLaSpaziatura;
    [Test]
    procedure LAltezzaDiUnaRigaEQuelladelCarattereDiNuovaRiga;
    [Test]
    procedure UnTestoSenzaFontNonHaRighe;
    [Test]
    procedure IlFontGrandeFiniscePiccoloSeNonCiStaEIlTestoNonFiniscePerPunto;
    [Test]
    procedure UnTestoCheFiniscePerPuntoRestaGrande;
    [Test]
    procedure GliAcapoSpezzanoLeRighe;
    [Test]
    procedure AcapoAutomaticoPerParole;
    [Test]
    procedure AcapoAutomaticoPerLettere;
    [Test]
    procedure IlRientroSiRipeteDopoUnAcapo;
    [Test]
    procedure DisegnaIPixelDelColore;
    [Test]
    procedure InvertitoCambiaIlColore;
    [Test]
    procedure AltoContrastoMoltiplica;
    [Test]
    procedure IlTokenDelColoreAlternaIlSecondario;
    [Test]
    procedure AllineaAlCentroEADestra;
    [Test]
    procedure AllineaInVerticale;
    [Test]
    procedure ILTokenPiccoloCambiaFont;
    [Test]
    procedure UnTestoVuotoNonDisegnaNulla;
    [Test]
    procedure LaRotellaScorreIlTestoScorrevole;
    [Test]
    procedure LeOpzioniDiColoreSiLeggono;
    [Test]
    procedure IlDebugDisegnaLaCornice;
    [Test]
    procedure DaDestraASinistraLeLineeSiAllineanoAlContrario;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomWindow = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlBordoHaCinqueSfumature;
    [Test]
    procedure ConAltoContrastoLeSfumatureSonoDoppie;
    [Test]
    procedure IlBordoSottileHaAltreSfumature;
    [Test]
    procedure LoSfondoVieneDisegnatoDentroIlBordo;
    [Test]
    procedure UnaFinestraSenzaPopupEGiaAperta;
    [Test]
    procedure IlPopupSiApreConIlTempoENascondeGliAltri;
    [Test]
    procedure UnaFinestraConPopupTogliePerUnPoLoStatoDaSchermo;
    [Test]
    procedure IlPopupOrizzontaleCresceSoloInLarghezza;
    [Test]
    procedure IlPopupVerticaleCresceSoloInAltezza;
    [Test]
    procedure RiavviareLoStatoRidisegnaLaFinestra;
    [Test]
    procedure ColoreEContrastoSiLeggono;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomTextButton = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FButton: TXcomTextButton;
    procedure Press(AX, AY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlBordoHaCinqueSfumature;
    [Test]
    procedure PremutoInvertePrimaDelleSfumature;
    [Test]
    procedure IlTestoSiDisegnaAlCentro;
    [Test]
    procedure IlGruppoTieneSoloUnPulsanteAcceso;
    [Test]
    procedure IlPulsanteDellaGeoscapeHaGliAngoliDelColore;
    [Test]
    procedure ComeComboBoxRispondeAlSoloSinistro;
    [Test]
    procedure IlComboBoxVieneAcceso;
    [Test]
    procedure CambiareLeDimensioniCambiaLeDelTesto;
    [Test]
    procedure ILClickChiamaIlGestore;
    [Test]
    procedure LeImpostazioniDelTestoPassanoAlTesto;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomSmallWidgets = class
  strict private
    FWorld: TTestWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaCorniceHaSfumatureESfondo;
    [Test]
    procedure LaCorniceSpessaHaIBordiScuri;
    [Test]
    procedure LaCorniceConAltoContrasto;
    [Test]
    procedure IlNumeroDisegnaLeCifre;
    [Test]
    procedure IlNumeroConIlBordoDisegnaDiPiuPixel;
    [Test]
    procedure IlNumeroDiPiuCifreHaLaSpaziatura;
    [Test]
    procedure IlCursoreSegueIlMouseConLaScala;
    [Test]
    procedure IlCursoreEUnaFrecciaDelColore;
    [Test]
    procedure IlContatoreDiFotogrammiMisuraAlSecondo;
    [Test]
    procedure IlTastoDelContatoreLoMostraENascondeEntrambe;
    [Test]
    procedure IlFontTerminaleHaINovePerSedici;
    [Test]
    procedure IlFontTerminaleHaIDueColori;
    [Test]
    procedure PaletteShiftRitagliaEPosizionaIlCarattere;
    [Test]
    procedure PaletteShiftNonDisegnaFuoriDallaDestinazione;
  end;

implementation

uses
  DelphiDoom.XcomEngine.TerminalFont;

type
  TFlatState = class(TXcomState)
  end;

{ TTestXcomText }

procedure TTestXcomText.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomText.TearDown;
begin
  FreeAndNil(FText);
  FWorld.Free;
end;

function TTestXcomText.NewText(AWidth, AHeight: Integer): TXcomText;
begin
  FreeAndNil(FText);
  FText := TXcomText.Create(AWidth, AHeight, 0, 0);
  FText.InitText(FWorld.Resources.GetFont('FONT_BIG'), FWorld.Resources.GetFont('FONT_SMALL'), FWorld.Game.Language);
  Result := FText;
end;

function TTestXcomText.Count(ASurface: TXcomSurface; AValue: Byte): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to Length(ASurface.Pixels) - 1 do
    if ASurface.Pixels[LIndex] = AValue then
      Inc(Result);
end;

procedure TTestXcomText.MisuraLaLarghezzaConLaSpaziatura;
begin
  NewText(200, 50).SetText('AB');
  // a small character of the fake font: 4 pixels of glyph and 1 of spacing
  Assert.AreEqual(10, FText.GetTextWidth);
  Assert.AreEqual(10, FText.GetTextWidth(0));
  Assert.AreEqual(9, FText.GetTextHeight);
  Assert.AreEqual(1, FText.GetNumLines);
end;

procedure TTestXcomText.LAltezzaDiUnaRigaEQuelladelCarattereDiNuovaRiga;
begin
  NewText(200, 50).SetText('A'#10'B');
  Assert.AreEqual(18, FText.GetTextHeight);
  Assert.AreEqual(9, FText.GetTextHeight(1));
end;

procedure TTestXcomText.UnTestoSenzaFontNonHaRighe;
var
  LText: TXcomText;
begin
  LText := TXcomText.Create(10, 10);
  try
    LText.SetText('A');
    Assert.AreEqual(0, LText.GetTextHeight);
    Assert.AreEqual('A', LText.GetText);
    Assert.IsNull(LText.GetFont);
  finally
    LText.Free;
  end;
end;

procedure TTestXcomText.IlFontGrandeFiniscePiccoloSeNonCiStaEIlTestoNonFiniscePerPunto;
begin
  NewText(20, 20).SetBig;
  FText.SetText('AAAA');
  Assert.AreSame(FWorld.Resources.GetFont('FONT_SMALL'), FText.GetFont);
end;

procedure TTestXcomText.UnTestoCheFiniscePerPuntoRestaGrande;
begin
  NewText(20, 20).SetBig;
  FText.SetText('AAAA.');
  Assert.AreSame(FWorld.Resources.GetFont('FONT_BIG'), FText.GetFont);
end;

procedure TTestXcomText.GliAcapoSpezzanoLeRighe;
begin
  NewText(200, 50).SetText('A'#10'B'#10'C');
  Assert.AreEqual(27, FText.GetTextHeight);
end;

procedure TTestXcomText.AcapoAutomaticoPerParole;
begin
  NewText(14, 100).SetWordWrap(True);
  FText.SetText('AA AA AA');
  Assert.AreEqual(3, FText.GetNumLines);
  Assert.IsTrue(FText.GetTextWidth <= 14);
end;

procedure TTestXcomText.AcapoAutomaticoPerLettere;
var
  LLanguage: TXcomLanguage;
  LText: TXcomText;
begin
  LLanguage := TXcomLanguage.Create('ja', twAuto, nil, nil);
  LText := TXcomText.Create(20, 100, 0, 0);
  try
    LText.InitText(FWorld.Resources.GetFont('FONT_BIG'), FWorld.Resources.GetFont('FONT_SMALL'), LLanguage);
    LText.SetWordWrap(True);
    LText.SetText('AAAAAAAAAA');
    Assert.IsTrue(LText.GetNumLines >= 3);
  finally
    LText.Free;
    LLanguage.Free;
  end;
end;

procedure TTestXcomText.IlRientroSiRipeteDopoUnAcapo;
begin
  NewText(40, 100).SetWordWrap(True, True);
  FText.SetText('AA AA AA AA');
  Assert.IsTrue(FText.GetNumLines >= 2);
  // the second line starts with the indentation (a tab, 3/4 of the character width)
  Assert.IsTrue(FText.GetTextWidth(1) > 0);
end;

procedure TTestXcomText.DisegnaIPixelDelColore;
begin
  NewText(50, 20).SetText('A');
  FText.SetColor(40);
  FText.Draw;
  Assert.AreEqual(24, Count(FText, 41));
  Assert.AreEqual(40, Integer(FText.GetColor));
  Assert.AreEqual(40, Integer(FText.GetSecondaryColor));
end;

procedure TTestXcomText.InvertitoCambiaIlColore;
begin
  NewText(50, 20).SetText('A');
  FText.SetColor(40);
  FText.SetInvert(True);
  FText.Draw;
  Assert.AreEqual(24, Count(FText, 45));
end;

procedure TTestXcomText.AltoContrastoMoltiplica;
begin
  NewText(50, 20).SetText('A');
  FText.SetColor(40);
  FText.SetHighContrast(True);
  FText.Draw;
  Assert.AreEqual(24, Count(FText, 43));
end;

procedure TTestXcomText.IlTokenDelColoreAlternaIlSecondario;
begin
  NewText(50, 20).SetText('A'#1'A');
  FText.SetColor(40);
  FText.SetSecondaryColor(60);
  FText.Draw;
  Assert.AreEqual(24, Count(FText, 41));
  Assert.AreEqual(24, Count(FText, 61));
end;

procedure TTestXcomText.AllineaAlCentroEADestra;
var
  LLeft: Integer;
  LX: Integer;
  LY: Integer;
begin
  NewText(50, 20).SetText('A');
  FText.SetColor(40);
  FText.SetAlign(haCenter);
  FText.Draw;
  LLeft := -1;
  for LX := 0 to 49 do
    for LY := 0 to 19 do
      if (LLeft = -1) and (FText.GetPixel(LX, LY) = 41) then
        LLeft := LX;
  // (50 + 1 - 5) / 2 = 23 plus the empty first column of the glyph cell
  Assert.AreEqual(23, LLeft);
  FText.SetAlign(haRight);
  Assert.IsTrue(FText.GetAlign = haRight);
  FText.Draw;
  LLeft := -1;
  for LX := 0 to 49 do
    for LY := 0 to 19 do
      if (LLeft = -1) and (FText.GetPixel(LX, LY) = 41) then
        LLeft := LX;
  Assert.AreEqual(50 - 1 - 5, LLeft);
end;

procedure TTestXcomText.AllineaInVerticale;
var
  LTop: Integer;
  LY: Integer;
begin
  NewText(50, 40).SetText('A');
  FText.SetColor(40);
  FText.SetVerticalAlign(vaMiddle);
  FText.Draw;
  LTop := -1;
  for LY := 0 to 39 do
    if (LTop = -1) and (FText.GetPixel(2, LY) = 41) then
      LTop := LY;
  // ceil((40 - 9) / 2) = 16, plus the first row of the glyph cell
  Assert.AreEqual(17, LTop);
  FText.SetVerticalAlign(vaBottom);
  Assert.IsTrue(FText.GetVerticalAlign = vaBottom);
end;

procedure TTestXcomText.ILTokenPiccoloCambiaFont;
begin
  NewText(100, 60).SetBig;
  FText.SetText('A'#2'A');
  // the first line is big (11 high), after the small line break the lines are small (9 high)
  Assert.AreEqual(11 + 9, FText.GetTextHeight);
end;

procedure TTestXcomText.UnTestoVuotoNonDisegnaNulla;
begin
  NewText(50, 20).SetText('');
  FText.SetColor(40);
  FText.Draw;
  Assert.AreEqual(50 * 20, Count(FText, 0));
end;

procedure TTestXcomText.LaRotellaScorreIlTestoScorrevole;
var
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
  LBefore: Integer;
begin
  NewText(30, 18).SetText('A'#10'AA'#10'A'#10'AA');
  FText.SetColor(40);
  FText.SetScrollable(True);
  FText.Draw;
  LBefore := FText.GetPixel(6, 1);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := 3;
  LEvent.Y := 3;
  LEvent.Button := XCOM_BUTTON_WHEELDOWN;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    FText.Handle(LAction);
  finally
    LAction.Free;
  end;
  FText.Draw;
  Assert.AreEqual(0, LBefore);
  // scrolled up by a line (8 + 1): the first visible line is now the one with two letters
  Assert.AreEqual(41, Integer(FText.GetPixel(6, 1)));
end;

procedure TTestXcomText.LeOpzioniDiColoreSiLeggono;
begin
  NewText(50, 20);
  Assert.IsTrue(FText.GetAlign = haLeft);
  Assert.IsTrue(FText.GetVerticalAlign = vaTop);
  FText.SetWordWrap(True);
  FText.SetText('A');
  Assert.AreEqual(1, FText.GetNumLines);
end;

procedure TTestXcomText.IlDebugDisegnaLaCornice;
begin
  NewText(50, 20).SetText('A');
  FText.DebugUi := True;
  FText.Draw;
  Assert.AreEqual(5, Integer(FText.GetPixel(0, 0)));
  Assert.AreEqual(0, Integer(FText.GetPixel(45, 15)));
end;

procedure TTestXcomText.DaDestraASinistraLeLineeSiAllineanoAlContrario;
var
  LLanguage: TXcomLanguage;
  LText: TXcomText;
begin
  // a language that is not left to right is not in the data of this slice: the direction stays left to right
  LLanguage := TXcomLanguage.Create('ar', twAuto, nil, nil);
  LText := TXcomText.Create(50, 20, 0, 0);
  try
    LText.InitText(FWorld.Resources.GetFont('FONT_BIG'), FWorld.Resources.GetFont('FONT_SMALL'), LLanguage);
    LText.SetText('A');
    Assert.IsTrue(LLanguage.TextDirection = tdLeftToRight);
    Assert.AreEqual(5, LText.GetTextWidth);
  finally
    LText.Free;
    LLanguage.Free;
  end;
end;

{ TTestXcomWindow }

procedure TTestXcomWindow.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
end;

procedure TTestXcomWindow.TearDown;
begin
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomWindow.IlBordoHaCinqueSfumature;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpNone);
  try
    LWindow.SetColor(10);
    LWindow.Draw;
    Assert.AreEqual(13, Integer(LWindow.GetPixel(0, 0)));
    Assert.AreEqual(12, Integer(LWindow.GetPixel(1, 1)));
    Assert.AreEqual(11, Integer(LWindow.GetPixel(2, 2)));
    Assert.AreEqual(12, Integer(LWindow.GetPixel(3, 3)));
    Assert.AreEqual(13, Integer(LWindow.GetPixel(4, 4)));
    Assert.AreEqual(13, Integer(LWindow.GetPixel(20, 15)));
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.ConAltoContrastoLeSfumatureSonoDoppie;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpNone);
  try
    LWindow.SetColor(10);
    LWindow.SetHighContrast(True);
    LWindow.Draw;
    Assert.AreEqual(16, Integer(LWindow.GetPixel(0, 0)));
    Assert.AreEqual(14, Integer(LWindow.GetPixel(1, 1)));
    Assert.AreEqual(12, Integer(LWindow.GetPixel(2, 2)));
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.IlBordoSottileHaAltreSfumature;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpNone);
  try
    LWindow.SetColor(10);
    LWindow.SetThinBorder;
    LWindow.Draw;
    Assert.AreEqual(11, Integer(LWindow.GetPixel(0, 0)));
    // the corner pixel of the first rectangle has the lightest shade
    Assert.AreEqual(15, Integer(LWindow.GetPixel(39, 0)));
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.LoSfondoVieneDisegnatoDentroIlBordo;
var
  LWindow: TXcomWindow;
  LBackground: TXcomSurface;
begin
  LBackground := FWorld.Resources.GetSurface('BACK01.SCR');
  LWindow := TXcomWindow.Create(FState, 40, 30, 20, 10, wpNone);
  try
    LWindow.SetColor(10);
    LWindow.SetBackground(LBackground);
    LWindow.Draw;
    // the window is at 20,10: its pixel 5,5 shows the picture at 25,15 (the 5 pixels of border are skipped)
    Assert.AreEqual(Integer(LBackground.GetPixel(25, 15)), Integer(LWindow.GetPixel(5, 5)));
    Assert.AreEqual(Integer(LBackground.GetPixel(40, 30)), Integer(LWindow.GetPixel(20, 20)));
    Assert.AreEqual(13, Integer(LWindow.GetPixel(0, 0)));
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.UnaFinestraSenzaPopupEGiaAperta;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpNone);
  try
    Assert.AreEqual(1.0, LWindow.PopupStep, 0.0001);
    Assert.IsFalse(LWindow.Hidden);
    Assert.IsTrue(FState.IsScreen);
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.IlPopupSiApreConIlTempoENascondeGliAltri;
var
  LWindow: TXcomWindow;
  LOther: TXcomText;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpBoth);
  LOther := TXcomText.Create(10, 10);
  FState.Add(LWindow);
  FState.Add(LOther);
  FWorld.Game.SetState(FState);
  FWorld.Wait(25);
  // the window starts hidden, shows when it thinks, and hides the rest while it opens
  Assert.IsFalse(LWindow.Hidden);
  Assert.IsTrue(LOther.Hidden);
  Assert.IsTrue(LWindow.PopupStep < 1.0);
  FWorld.Wait(400);
  Assert.AreEqual(1.0, LWindow.PopupStep, 0.0001);
  Assert.IsFalse(LOther.Hidden);
  FState := nil;
end;

procedure TTestXcomWindow.UnaFinestraConPopupTogliePerUnPoLoStatoDaSchermo;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpVertical);
  try
    Assert.IsFalse(FState.IsScreen);
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.IlPopupOrizzontaleCresceSoloInLarghezza;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpHorizontal);
  try
    LWindow.SetColor(10);
    LWindow.Draw;
    // at the start the window is zero wide: only the 1 pixel border of the squeezed rectangles
    Assert.AreEqual(0, Integer(LWindow.GetPixel(0, 0)));
    Assert.IsTrue(LWindow.PopupStep = 0.0);
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.IlPopupVerticaleCresceSoloInAltezza;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpVertical);
  try
    LWindow.SetColor(10);
    LWindow.Draw;
    Assert.AreEqual(0, Integer(LWindow.GetPixel(0, 0)));
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.RiavviareLoStatoRidisegnaLaFinestra;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpNone);
  try
    LWindow.Draw;
    Assert.IsFalse(LWindow.Redraw);
    LWindow.StateInitialized;
    Assert.IsTrue(LWindow.Redraw);
  finally
    LWindow.Free;
  end;
end;

procedure TTestXcomWindow.ColoreEContrastoSiLeggono;
var
  LWindow: TXcomWindow;
begin
  LWindow := TXcomWindow.Create(FState, 40, 30, 0, 0, wpNone);
  try
    LWindow.SetColor(77);
    LWindow.SetDX(3);
    LWindow.SetDY(4);
    Assert.AreEqual(77, Integer(LWindow.GetColor));
  finally
    LWindow.Free;
  end;
end;

{ TTestXcomTextButton }

procedure TTestXcomTextButton.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FButton := TXcomTextButton.Create(40, 20, 10, 10);
  FState.Add(FButton);
  FButton.SetColor(20);
end;

procedure TTestXcomTextButton.TearDown;
begin
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomTextButton.Press(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX;
  LEvent.Y := AY;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    FButton.Handle(LAction);
    LAction.Details^.Kind := ekMouseDown;
    LAction.Details^.Button := XCOM_BUTTON_LEFT;
    FButton.Handle(LAction);
  finally
    LAction.Free;
  end;
end;

procedure TTestXcomTextButton.IlBordoHaCinqueSfumature;
begin
  FButton.Draw;
  Assert.AreEqual(21, Integer(FButton.GetPixel(0, 0)));
  // the pixel at the top right of the second frame is the lightest
  Assert.AreEqual(25, Integer(FButton.GetPixel(39, 0)));
  Assert.AreEqual(25, Integer(FButton.GetPixel(39, 10)));
  Assert.AreEqual(25, Integer(FButton.GetPixel(20, 19)));
  Assert.AreEqual(22, Integer(FButton.GetPixel(1, 1)));
  Assert.AreEqual(23, Integer(FButton.GetPixel(10, 10)));
end;

procedure TTestXcomTextButton.PremutoInvertePrimaDelleSfumature;
begin
  // a button that handles no click does not draw itself again when pressed
  FButton.OnMouseClick(procedure(A: TXcomAction) begin end);
  FButton.Draw;
  Assert.AreEqual(21, Integer(FButton.GetPixel(0, 0)));
  Press(15, 15);
  // inverted around color + 3: 21 becomes 25
  Assert.AreEqual(25, Integer(FButton.GetPixel(0, 0)));
end;

procedure TTestXcomTextButton.IlTestoSiDisegnaAlCentro;
var
  LX: Integer;
  LY: Integer;
  LCount: Integer;
begin
  FButton.SetText('A');
  FButton.Draw;
  LCount := 0;
  for LY := 5 to 14 do
    for LX := 10 to 30 do
      if FButton.GetPixel(LX, LY) = 21 then
        Inc(LCount);
  Assert.IsTrue(LCount > 0);
  Assert.AreEqual('A', FButton.GetText);
end;

procedure TTestXcomTextButton.IlGruppoTieneSoloUnPulsanteAcceso;
var
  LGroup: TXcomButtonGroup;
  LOther: TXcomTextButton;
begin
  LGroup := TXcomButtonGroup.Create;
  LOther := TXcomTextButton.Create(40, 20, 60, 10);
  try
    FState.Add(LOther);
    LOther.SetColor(20);
    FButton.SetGroup(LGroup);
    LOther.SetGroup(LGroup);
    LGroup.Selected := FButton;
    FButton.Draw;
    LOther.Draw;
    Assert.AreEqual(25, Integer(FButton.GetPixel(0, 0)));
    Assert.AreEqual(21, Integer(LOther.GetPixel(0, 0)));
    LGroup.Selected := LOther;
    FButton.Draw;
    LOther.Draw;
    Assert.AreEqual(21, Integer(FButton.GetPixel(0, 0)));
    Assert.AreEqual(25, Integer(LOther.GetPixel(0, 0)));
  finally
    FButton.SetGroup(nil);
    LGroup.Free;
  end;
end;

procedure TTestXcomTextButton.IlPulsanteDellaGeoscapeHaGliAngoliDelColore;
begin
  FButton.SetGeoscapeButton(True);
  FButton.Draw;
  Assert.AreEqual(20, Integer(FButton.GetPixel(0, 0)));
  Assert.AreEqual(20, Integer(FButton.GetPixel(1, 1)));
end;

procedure TTestXcomTextButton.ComeComboBoxRispondeAlSoloSinistro;
begin
  FButton.SetComboToggle(procedure begin end);
  Assert.IsTrue(FButton.IsButtonHandled(XCOM_BUTTON_LEFT));
  Assert.IsFalse(FButton.IsButtonHandled(XCOM_BUTTON_RIGHT));
  FButton.SetComboToggle(nil);
  Assert.IsFalse(FButton.IsButtonHandled(XCOM_BUTTON_LEFT));
end;

procedure TTestXcomTextButton.IlComboBoxVieneAcceso;
var
  LToggled: Integer;
begin
  LToggled := 0;
  FButton.SetComboToggle(procedure begin Inc(LToggled); end);
  Press(15, 15);
  Assert.AreEqual(1, LToggled);
end;

procedure TTestXcomTextButton.CambiareLeDimensioniCambiaLeDelTesto;
begin
  FButton.SetWidth(60);
  FButton.SetHeight(30);
  Assert.AreEqual(60, FButton.Width);
  Assert.AreEqual(30, FButton.Height);
  FButton.SetText('AA');
  FButton.Draw;
  Assert.AreEqual(21, Integer(FButton.GetPixel(0, 0)));
end;

procedure TTestXcomTextButton.ILClickChiamaIlGestore;
var
  LClicks: Integer;
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LClicks := 0;
  FButton.OnMouseClick(procedure(A: TXcomAction) begin Inc(LClicks); end);
  Press(15, 15);
  LEvent := TXcomInputEvent.Make(ekMouseUp);
  LEvent.X := 15;
  LEvent.Y := 15;
  LEvent.Button := XCOM_BUTTON_LEFT;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    FButton.Handle(LAction);
  finally
    LAction.Free;
  end;
  Assert.AreEqual(1, LClicks);
end;

procedure TTestXcomTextButton.LeImpostazioniDelTestoPassanoAlTesto;
begin
  FButton.SetBig;
  Assert.AreSame(FWorld.Resources.GetFont('FONT_BIG'), FButton.GetFont);
  FButton.SetSmall;
  Assert.AreSame(FWorld.Resources.GetFont('FONT_SMALL'), FButton.GetFont);
  FButton.SetTextColor(50);
  FButton.SetHighContrast(True);
  FButton.SetText('A');
  FButton.Draw;
  Assert.AreEqual(20, Integer(FButton.GetColor));
end;

{ TTestXcomSmallWidgets }

procedure TTestXcomSmallWidgets.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomSmallWidgets.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomSmallWidgets.LaCorniceHaSfumatureESfondo;
var
  LFrame: TXcomFrame;
begin
  LFrame := TXcomFrame.Create(40, 30);
  try
    LFrame.SetColor(30);
    LFrame.SetSecondaryColor(7);
    LFrame.Draw;
    Assert.AreEqual(33, Integer(LFrame.GetPixel(0, 0)));
    Assert.AreEqual(32, Integer(LFrame.GetPixel(1, 1)));
    Assert.AreEqual(31, Integer(LFrame.GetPixel(2, 2)));
    Assert.AreEqual(32, Integer(LFrame.GetPixel(3, 3)));
    Assert.AreEqual(33, Integer(LFrame.GetPixel(4, 4)));
    Assert.AreEqual(7, Integer(LFrame.GetPixel(20, 15)));
    Assert.AreEqual(30, Integer(LFrame.GetColor));
    Assert.AreEqual(7, Integer(LFrame.GetSecondaryColor));
  finally
    LFrame.Free;
  end;
end;

procedure TTestXcomSmallWidgets.LaCorniceSpessaHaIBordiScuri;
var
  LFrame: TXcomFrame;
begin
  LFrame := TXcomFrame.Create(40, 30);
  try
    LFrame.SetBorderColor(32);
    LFrame.SetThickness(8);
    LFrame.Draw;
    // the darkest color of the block of 16: 32 / 16 * 16 + 15
    Assert.AreEqual(47, Integer(LFrame.GetPixel(0, 0)));
    Assert.AreEqual(47, Integer(LFrame.GetPixel(7, 7)));
  finally
    LFrame.Free;
  end;
end;

procedure TTestXcomSmallWidgets.LaCorniceConAltoContrasto;
var
  LFrame: TXcomFrame;
begin
  LFrame := TXcomFrame.Create(40, 30);
  try
    LFrame.SetColor(30);
    LFrame.SetHighContrast(True);
    LFrame.Draw;
    Assert.AreEqual(36, Integer(LFrame.GetPixel(0, 0)));
    Assert.AreEqual(34, Integer(LFrame.GetPixel(1, 1)));
  finally
    LFrame.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlNumeroDisegnaLeCifre;
var
  LNumber: TXcomNumberText;
begin
  LNumber := TXcomNumberText.Create(20, 8);
  try
    LNumber.SetValue(5);
    LNumber.SetColor(10);
    LNumber.Draw;
    Assert.AreEqual(11, Integer(LNumber.GetPixel(0, 0)));
    Assert.AreEqual(11, Integer(LNumber.GetPixel(2, 0)));
    Assert.AreEqual(11, Integer(LNumber.GetPixel(0, 1)));
    Assert.AreEqual(0, Integer(LNumber.GetPixel(1, 1)));
    Assert.AreEqual(5, Integer(LNumber.GetValue));
    Assert.AreEqual(10, Integer(LNumber.GetColor));
  finally
    LNumber.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlNumeroConIlBordoDisegnaDiPiuPixel;
var
  LPlain: TXcomNumberText;
  LBordered: TXcomNumberText;
  LIndex: Integer;
  LPlainCount: Integer;
  LBorderedCount: Integer;
begin
  LPlain := TXcomNumberText.Create(20, 8);
  LBordered := TXcomNumberText.Create(20, 8);
  try
    LPlain.SetValue(8);
    LBordered.SetValue(8);
    LBordered.SetBordered(True);
    LPlain.Draw;
    LBordered.Draw;
    LPlainCount := 0;
    LBorderedCount := 0;
    for LIndex := 0 to Length(LPlain.Pixels) - 1 do
    begin
      if LPlain.Pixels[LIndex] <> 0 then
        Inc(LPlainCount);
      if LBordered.Pixels[LIndex] <> 0 then
        Inc(LBorderedCount);
    end;
    Assert.IsTrue(LBorderedCount > LPlainCount);
  finally
    LBordered.Free;
    LPlain.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlNumeroDiPiuCifreHaLaSpaziatura;
var
  LNumber: TXcomNumberText;
begin
  LNumber := TXcomNumberText.Create(20, 8);
  try
    LNumber.SetValue(11);
    LNumber.Draw;
    // the digit 1 has its top pixel in the middle: columns 1 and 5 (3 wide plus one pixel of space)
    Assert.AreNotEqual(0, Integer(LNumber.GetPixel(1, 0)));
    Assert.AreNotEqual(0, Integer(LNumber.GetPixel(5, 0)));
    Assert.AreEqual(0, Integer(LNumber.GetPixel(3, 0)));
  finally
    LNumber.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlCursoreSegueIlMouseConLaScala;
var
  LCursor: TXcomCursor;
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LCursor := TXcomCursor.Create(9, 13);
  try
    LEvent := TXcomInputEvent.Make(ekMouseMotion);
    LEvent.X := 90;
    LEvent.Y := 61;
    LAction := TXcomAction.Create(LEvent, 2.0, 2.0, 1, 10);
    try
      LCursor.Handle(LAction);
    finally
      LAction.Free;
    end;
    Assert.AreEqual(40, LCursor.X);
    Assert.AreEqual(30, LCursor.Y);
    LEvent.Kind := ekKeyDown;
    LAction := TXcomAction.Create(LEvent, 2.0, 2.0, 1, 10);
    try
      LCursor.Handle(LAction);
    finally
      LAction.Free;
    end;
    Assert.AreEqual(40, LCursor.X);
  finally
    LCursor.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlCursoreEUnaFrecciaDelColore;
var
  LCursor: TXcomCursor;
begin
  LCursor := TXcomCursor.Create(9, 13);
  try
    LCursor.SetColor(100);
    LCursor.Draw;
    Assert.AreEqual(100, Integer(LCursor.GetPixel(0, 0)));
    Assert.AreEqual(100, Integer(LCursor.GetPixel(0, 12)));
    Assert.AreEqual(103, Integer(LCursor.GetPixel(4, 8)));
    Assert.AreEqual(100, Integer(LCursor.GetColor));
  finally
    LCursor.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlContatoreDiFotogrammiMisuraAlSecondo;
var
  LFps: TXcomFpsCounter;
  LClock: TXcomManualClock;
  LRef: IXcomClock;
  LIndex: Integer;
begin
  LClock := TXcomManualClock.Create;
  LRef := LClock;
  LFps := TXcomFpsCounter.Create(LRef, 15, 5, 0, 0, True, 288);
  try
    LFps.SetColor(10);
    for LIndex := 1 to 30 do
      LFps.FrameAdded;
    LClock.Advance(1000);
    LFps.Think;
    Assert.IsTrue(LFps.Redraw);
    LFps.Draw;
    // 30 frames in a second: the digits 3 and 0 are drawn in the 15 x 5 surface
    Assert.AreNotEqual(0, Integer(LFps.GetPixel(0, 0)));
  finally
    LFps.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlTastoDelContatoreLoMostraENascondeEntrambe;
var
  LFps: TXcomFpsCounter;
  LClock: TXcomManualClock;
  LRef: IXcomClock;
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
  LColors: array[0..255] of TXcomColor;
begin
  LClock := TXcomManualClock.Create;
  LRef := LClock;
  LFps := TXcomFpsCounter.Create(LRef, 15, 5, 0, 0, False, 288);
  try
    FillChar(LColors, SizeOf(LColors), 0);
    LFps.SetPalette(@LColors[0], 0, 256);
    Assert.IsFalse(LFps.Visible);
    LEvent := TXcomInputEvent.Make(ekKeyDown);
    LEvent.Key := 288;
    LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
    try
      LFps.Handle(LAction);
      Assert.IsTrue(LFps.Visible);
      LFps.Handle(LAction);
      Assert.IsFalse(LFps.Visible);
      LAction.Details^.Key := 65;
      LFps.Handle(LAction);
      Assert.IsFalse(LFps.Visible);
    finally
      LAction.Free;
    end;
  finally
    LFps.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlFontTerminaleHaINovePerSedici;
var
  LFont: TXcomFont;
begin
  LFont := TXcomTerminalFont.Create;
  try
    Assert.AreEqual(9, LFont.Width);
    Assert.AreEqual(16, LFont.Height);
    Assert.AreEqual(9, LFont.GetCharSize(Ord('A')).W);
    Assert.AreEqual(16, LFont.GetCharSize(10).H);
    Assert.AreEqual(1, LFont.ImageCount);
    Assert.IsTrue(LFont.Monospace);
    Assert.AreEqual(288, LFont.ImageSurface(0).Width);
    Assert.AreEqual(48, LFont.ImageSurface(0).Height);
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSmallWidgets.IlFontTerminaleHaIDueColori;
var
  LColors: TArray<TXcomColor>;
  LFont: TXcomFont;
  LGlyph: TXcomSurface;
  LIndex: Integer;
  LCount: Integer;
begin
  LColors := TXcomTerminalFont.Colors;
  Assert.AreEqual(2, Length(LColors));
  Assert.AreEqual(185, Integer(LColors[1].Red));
  Assert.AreEqual(0, Integer(LColors[0].Alpha));
  LFont := TXcomTerminalFont.Create;
  try
    LGlyph := LFont.GetChar(Ord('A'));
    LCount := 0;
    for LIndex := 0 to Length(LGlyph.Pixels) - 1 do
      if LGlyph.Pixels[LIndex] = 1 then
        Inc(LCount);
    // the glyph of the whole picture of the font: many pixels of color 1
    Assert.AreEqual(185, Integer(LGlyph.Palette.Colors[1].Red));
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSmallWidgets.PaletteShiftRitagliaEPosizionaIlCarattere;
var
  LDestination: TXcomSurface;
  LGlyph: TXcomSurface;
begin
  LDestination := TXcomSurface.Create(20, 20);
  LGlyph := TXcomSurface.Create(10, 10);
  try
    LGlyph.DrawRect(0, 0, 10, 10, 2);
    // a crop of 3 x 2 pixels at (4, 5) of the glyph, drawn at (8, 9)
    LGlyph.Crop := TXcomRect.Make(4, 5, 3, 2);
    LGlyph.X := 8;
    LGlyph.Y := 9;
    TXcomPaletteShift.Draw(LDestination, LGlyph, 100, 1, 0);
    Assert.AreEqual(102, Integer(LDestination.GetPixel(8, 9)));
    Assert.AreEqual(102, Integer(LDestination.GetPixel(10, 10)));
    Assert.AreEqual(0, Integer(LDestination.GetPixel(11, 9)));
    Assert.AreEqual(0, Integer(LDestination.GetPixel(8, 11)));
  finally
    LGlyph.Free;
    LDestination.Free;
  end;
end;

procedure TTestXcomSmallWidgets.PaletteShiftNonDisegnaFuoriDallaDestinazione;
var
  LDestination: TXcomSurface;
  LGlyph: TXcomSurface;
begin
  LDestination := TXcomSurface.Create(5, 5);
  LGlyph := TXcomSurface.Create(4, 4);
  try
    LGlyph.DrawRect(0, 0, 4, 4, 1);
    LGlyph.X := -2;
    LGlyph.Y := 3;
    TXcomPaletteShift.Draw(LDestination, LGlyph, 50, 1, 0);
    Assert.AreEqual(51, Integer(LDestination.GetPixel(0, 3)));
    Assert.AreEqual(51, Integer(LDestination.GetPixel(1, 4)));
    Assert.AreEqual(0, Integer(LDestination.GetPixel(2, 3)));
  finally
    LGlyph.Free;
    LDestination.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomText);
  TDUnitX.RegisterTestFixture(TTestXcomWindow);
  TDUnitX.RegisterTestFixture(TTestXcomTextButton);
  TDUnitX.RegisterTestFixture(TTestXcomSmallWidgets);

end.
