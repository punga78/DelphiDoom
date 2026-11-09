{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom interface library - the controls (bar,    }
{  arrow button, scroll bar, slider, text list, combo box, text edit...)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Controls;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Xcom.Types,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Math, DelphiDoom.XcomUi.ScrollableList, DelphiDoom.XcomUi.ComboBoxLink,
  DelphiDoom.XcomUi.Bar, DelphiDoom.XcomUi.ImageButton, DelphiDoom.XcomUi.ArrowButton,
  DelphiDoom.XcomUi.ScrollBar, DelphiDoom.XcomUi.Slider, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomUi.BattlescapeButton,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>A list that records what the controls ask of it</summary>
  TRecordingList = class(TInterfacedObject, IXcomScrollableList)
  public
    Rows: Integer;
    Visible: Integer;
    Scroll: Integer;
    Combo: Boolean;
    Calls: TStringList;
    constructor Create;
    destructor Destroy; override;
    function GetRows: Integer;
    function GetVisibleRows: Integer;
    function GetScroll: Integer;
    procedure ScrollTo(AScroll: Integer);
    procedure ScrollUp(AToMax: Boolean; AByWheel: Boolean = False);
    procedure ScrollDown(AToMax: Boolean; AByWheel: Boolean = False);
    function HasComboBox: Boolean;
  end;

  /// <summary>Sends mouse and keyboard events to a surface as the game does</summary>
  TEventSender = class
  public
    class procedure Mouse(ASurface: TXcomInteractiveSurface; AKind: TXcomEventKind; AX, AY: Integer;
      AButton: Integer = XCOM_BUTTON_LEFT); static;
    class procedure Key(ASurface: TXcomInteractiveSurface; AKey: Integer; ACharacter: Cardinal = 0); static;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomMath = class
  public
    [Test]
    procedure ArrotondaLaMetaVersoLontanoDalloZero;
    [Test]
    procedure ClampTieneIlValoreNellIntervallo;
    [Test]
    procedure ToWordPrendeI16BitBassi;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomBar = class
  strict private
    FBar: TXcomBar;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DisegnaBordoEValori;
    [Test]
    procedure IlSecondoValoreStaSopraDiDefault;
    [Test]
    procedure IlSecondoValoreSottoSiPuoScegliere;
    [Test]
    procedure UnValoreNegativoDiventaZero;
    [Test]
    procedure ILColoreDelBordoSostituisceQuelloDerivato;
    [Test]
    procedure ValoriEColoriSiLeggono;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomImageButton = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FButton: TXcomImageButton;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TogglePremeEInverteIlColore;
    [Test]
    procedure TogglePremutoDueVolteNonInvertePiu;
    [Test]
    procedure IlGruppoTieneSoloUnPulsanteInvertito;
    [Test]
    procedure IlClickInvertePoiRilascia;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomArrowButton = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FList: TRecordingList;
    FListRef: IXcomScrollableList;
    FButton: TXcomArrowButton;
    procedure Make(AShape: TXcomArrowShape);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaFrecciaGrandeInSuHaIlTriangolo;
    [Test]
    procedure IlBordoHaLeSfumature;
    [Test]
    procedure LeFreccePiccoleSiDisegnano;
    [Test]
    procedure TenereLaFrecciaScorreOgniCinquantaMillisecondi;
    [Test]
    procedure RilasciareFermaLoScorrimento;
    [Test]
    procedure IlDestroVaAllaFine;
    [Test]
    procedure LaRotellaScorreConLaRotella;
    [Test]
    procedure ConLaListaGestisceSinistroEDestro;
    [Test]
    procedure SenzaListaNonGestisceIlDestro;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomScrollBar = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FList: TRecordingList;
    FListRef: IXcomScrollableList;
    FBar: TXcomScrollBar;
    FTarget: TXcomSurface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlPollliceSegueLoScorrimento;
    [Test]
    procedure IlPollliceDisegnaGliAngoli;
    [Test]
    procedure IlPollliceTrascinatoScorreLaLista;
    [Test]
    procedure UnClickFuoriDalPollliceLoCentra;
    [Test]
    procedure RilasciareFermaIlTrascinamento;
    [Test]
    procedure LaRotellaScorreLaLista;
    [Test]
    procedure LaPistaUsaLoSfondoScuritoDi5;
    [Test]
    procedure ConUnComboBoxLaPistaSiSchiarisce;
    [Test]
    procedure SpostandoLaBarraSiSpostanoPistaEPollice;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomSlider = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FSlider: TXcomSlider;
    FChanges: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ILPulsanteSiPosizionaSecondoIlValore;
    [Test]
    procedure IlValoreSiTieneNelRange;
    [Test]
    procedure UnRangeInvertitoFunziona;
    [Test]
    procedure TrascinareImpostaIlValoreEAvvisa;
    [Test]
    procedure SpostareLoSliderSpostaIlPulsante;
    [Test]
    procedure UnRangeNulloNonDividePerZero;
    [Test]
    procedure IlColoreSiPassaATutto;
    [Test]
    procedure DisegnaIlMenoEIlPiu;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomTextList = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FList: TXcomTextList;
    FBackground: TXcomSurface;
    procedure Fill(ARows: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeRigheVisibiliDipendonoDallAltezza;
    [Test]
    procedure AggiungereRigheLeConta;
    [Test]
    procedure ILTestoDelleCelleSiLegge;
    [Test]
    procedure ScorreInSuEInGiu;
    [Test]
    procedure ScrollToTieneLaListaNelLimite;
    [Test]
    procedure ScorrereAlMassimoVaAllaFine;
    [Test]
    procedure LaRotellaScorreDellaVelocitaDelleOpzioni;
    [Test]
    procedure SenzaScorrimentoNonScorre;
    [Test]
    procedure SvuotareLaListaAzzeraLoScorrimento;
    [Test]
    procedure IlTestoAcapoOccupaPiuRighe;
    [Test]
    procedure IPuntiRiempionoLaColonna;
    [Test]
    procedure LeColonneSiPosizionano;
    [Test]
    procedure SelezionabileEvidenziaLaRigaSottoIlMouse;
    [Test]
    procedure IlClickDaLaRigaSelezionata;
    [Test]
    procedure IlComboBoxRiceveLaRigaScelta;
    [Test]
    procedure IlFontGrandeCambiaLeRigheVisibili;
    [Test]
    procedure LeFrecceDiRigaGestisconoIClick;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomComboBox = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FCombo: TXcomComboBox;
    FChanges: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure PartiChiuso;
    [Test]
    procedure SelezionareMostraIlTestoNelPulsante;
    [Test]
    procedure IlToggleApreELaListaEModale;
    [Test]
    procedure ChiudereAvvisaDelCambiamentoAlProssimoEvento;
    [Test]
    procedure IlSuggerimentoEIlSelezionatoSeLaListaEChiusa;
    [Test]
    procedure IlMenuAppareSottoIlPulsanteOSopra;
    [Test]
    procedure LaListaSiAccorciaSeNonStaNelloSchermo;
    [Test]
    procedure UnClickFuoriChiudeLaLista;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomTextEdit = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FEdit: TXcomTextEdit;
    FChanges: Integer;
    procedure TypeText(const AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure PartiSenzaFocus;
    [Test]
    procedure UnClickDaIlFocusEMettaIlCursoreInFondo;
    [Test]
    procedure SiScriveCarattereDopoCarattere;
    [Test]
    procedure IlBackspaceCancellaPrimaDelCursore;
    [Test]
    procedure CancCancellaDopoIlCursore;
    [Test]
    procedure FreccePrincipioEFineEInserimento;
    [Test]
    procedure InvioChiudeSoloSeCEDelTesto;
    [Test]
    procedure NonSiScriveOltreLaLarghezza;
    [Test]
    procedure IlVincoloNumericoPositivoAccettaSoloCifre;
    [Test]
    procedure IlVincoloNumericoAccettaIlSegnoSoloInTesta;
    [Test]
    procedure IlCursoreLampeggiaOgniCentoMillisecondi;
    [Test]
    procedure ClickFuoriTogliIlFocus;
    [Test]
    procedure SenzaTastieraSiSceglieLaLetteraConLeFrecce;
    [Test]
    procedure IlGestoreDelCambioViene;
  end;

  [TestFixture]
  [Category('XcomUi')]
  TTestXcomBattlescapeButton = class
  strict private
    FWorld: TTestWorld;
    FState: TXcomState;
    FButton: TXcomBattlescapeButton;
    FTarget: TXcomSurface;
    procedure Prepare;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaSecondaImmagineInvertePerIlColore;
    [Test]
    procedure InModalitaTftdUsaLaTabella;
    [Test]
    procedure PremutoDisegnaLaSecondaImmagine;
    [Test]
    procedure IlGruppoTieneSoloUnPulsante;
    [Test]
    procedure IlClickInvertePerIlTempoDelClick;
    [Test]
    procedure IlToggleDeveEssereConsentito;
  end;

implementation


type
  TFlatState = class(TXcomState)
  end;

{ TRecordingList }

constructor TRecordingList.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
  Rows := 20;
  Visible := 5;
end;

destructor TRecordingList.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

function TRecordingList.GetRows: Integer;
begin
  Result := Rows;
end;

function TRecordingList.GetVisibleRows: Integer;
begin
  Result := Visible;
end;

function TRecordingList.GetScroll: Integer;
begin
  Result := Scroll;
end;

procedure TRecordingList.ScrollTo(AScroll: Integer);
begin
  Scroll := AScroll;
  Calls.Add('to' + IntToStr(AScroll));
end;

procedure TRecordingList.ScrollUp(AToMax, AByWheel: Boolean);
begin
  Calls.Add('up' + IntToStr(Ord(AToMax)) + IntToStr(Ord(AByWheel)));
end;

procedure TRecordingList.ScrollDown(AToMax, AByWheel: Boolean);
begin
  Calls.Add('down' + IntToStr(Ord(AToMax)) + IntToStr(Ord(AByWheel)));
end;

function TRecordingList.HasComboBox: Boolean;
begin
  Result := Combo;
end;

{ TEventSender }

class procedure TEventSender.Mouse(ASurface: TXcomInteractiveSurface; AKind: TXcomEventKind; AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := AButton;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    ASurface.Handle(LAction);
  finally
    LAction.Free;
  end;
end;

class procedure TEventSender.Key(ASurface: TXcomInteractiveSurface; AKey: Integer; ACharacter: Cardinal);
var
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  LEvent.Character := ACharacter;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    ASurface.Handle(LAction);
  finally
    LAction.Free;
  end;
end;

{ TTestXcomMath }

procedure TTestXcomMath.ArrotondaLaMetaVersoLontanoDalloZero;
begin
  Assert.AreEqual(3, TXcomMath.RoundToInt(2.5));
  Assert.AreEqual(-3, TXcomMath.RoundToInt(-2.5));
  Assert.AreEqual(0, TXcomMath.RoundToInt(0.49));
  Assert.AreEqual(-1, TXcomMath.RoundToInt(-0.51));
  Assert.AreEqual(4, TXcomMath.RoundToInt(3.5));
end;

procedure TTestXcomMath.ClampTieneIlValoreNellIntervallo;
begin
  Assert.AreEqual(5, TXcomMath.Clamp(3, 5, 9));
  Assert.AreEqual(9, TXcomMath.Clamp(30, 5, 9));
  Assert.AreEqual(7, TXcomMath.Clamp(7, 5, 9));
  Assert.AreEqual(1.5, TXcomMath.Clamp(1.5, 1.0, 2.0), 0.0);
  Assert.AreEqual(2.0, TXcomMath.Clamp(3.5, 1.0, 2.0), 0.0);
end;

procedure TTestXcomMath.ToWordPrendeI16BitBassi;
begin
  Assert.AreEqual(4464, TXcomMath.ToWord(70000.5));
  Assert.AreEqual(12, TXcomMath.ToWord(12.9));
end;

{ TTestXcomBar }

procedure TTestXcomBar.Setup;
begin
  FBar := TXcomBar.Create(30, 5, 0, 0);
  FBar.SetColor(20);
  FBar.SetSecondaryColor(60);
  FBar.SetScale(2.0);
  FBar.SetMax(10);
  FBar.SetValue(4);
  FBar.SetValue2(2);
end;

procedure TTestXcomBar.TearDown;
begin
  FBar.Free;
end;

procedure TTestXcomBar.DisegnaBordoEValori;
begin
  FBar.Draw;
  // the border is as wide as the maximum plus one pixel, in the color plus 4
  Assert.AreEqual(24, Integer(FBar.GetPixel(0, 0)));
  Assert.AreEqual(24, Integer(FBar.GetPixel(20, 0)));
  Assert.AreEqual(0, Integer(FBar.GetPixel(21, 0)));
  Assert.AreEqual(24, Integer(FBar.GetPixel(20, 2)));
  Assert.AreEqual(24, Integer(FBar.GetPixel(3, 4)));
  // inside: the second value on top of the first, then the empty part
  Assert.AreEqual(60, Integer(FBar.GetPixel(2, 2)));
  Assert.AreEqual(20, Integer(FBar.GetPixel(6, 2)));
  Assert.AreEqual(0, Integer(FBar.GetPixel(10, 2)));
end;

procedure TTestXcomBar.IlSecondoValoreStaSopraDiDefault;
begin
  FBar.Draw;
  Assert.AreEqual(60, Integer(FBar.GetPixel(0, 1)));
end;

procedure TTestXcomBar.IlSecondoValoreSottoSiPuoScegliere;
begin
  FBar.SetSecondValueOnTop(False);
  FBar.Draw;
  Assert.AreEqual(20, Integer(FBar.GetPixel(0, 1)));
  Assert.AreEqual(20, Integer(FBar.GetPixel(2, 2)));
end;

procedure TTestXcomBar.UnValoreNegativoDiventaZero;
begin
  FBar.SetValue(-5);
  FBar.SetValue2(-1);
  Assert.AreEqual(0.0, FBar.GetValue, 0.0);
  Assert.AreEqual(0.0, FBar.GetValue2, 0.0);
  FBar.Draw;
  Assert.AreEqual(0, Integer(FBar.GetPixel(2, 2)));
end;

procedure TTestXcomBar.ILColoreDelBordoSostituisceQuelloDerivato;
begin
  FBar.SetBorderColor(99);
  FBar.Draw;
  Assert.AreEqual(99, Integer(FBar.GetPixel(0, 0)));
  Assert.AreEqual(99, Integer(FBar.GetPixel(20, 3)));
end;

procedure TTestXcomBar.ValoriEColoriSiLeggono;
begin
  Assert.AreEqual(20, Integer(FBar.GetColor));
  Assert.AreEqual(60, Integer(FBar.GetSecondaryColor));
  Assert.AreEqual(2.0, FBar.GetScale, 0.0);
  Assert.AreEqual(10.0, FBar.GetMax, 0.0);
  Assert.AreEqual(4.0, FBar.GetValue, 0.0);
  Assert.AreEqual(2.0, FBar.GetValue2, 0.0);
end;

{ TTestXcomImageButton }

procedure TTestXcomImageButton.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FButton := TXcomImageButton.Create(10, 10, 0, 0);
  FState.Add(FButton);
  FButton.SetColor(20);
  FButton.SetPixel(1, 1, 5);
  FButton.SetPixel(2, 2, 22);
end;

procedure TTestXcomImageButton.TearDown;
begin
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomImageButton.TogglePremeEInverteIlColore;
begin
  FButton.Toggle(True);
  // 5 + 2 * (23 - 5) = 41; 22 + 2 * (23 - 22) = 24
  Assert.AreEqual(41, Integer(FButton.GetPixel(1, 1)));
  Assert.AreEqual(24, Integer(FButton.GetPixel(2, 2)));
  FButton.Toggle(False);
  Assert.AreEqual(5, Integer(FButton.GetPixel(1, 1)));
end;

procedure TTestXcomImageButton.TogglePremutoDueVolteNonInvertePiu;
begin
  FButton.Toggle(True);
  FButton.Toggle(True);
  Assert.AreEqual(41, Integer(FButton.GetPixel(1, 1)));
end;

procedure TTestXcomImageButton.IlGruppoTieneSoloUnPulsanteInvertito;
var
  LGroup: TXcomImageButtonGroup;
  LOther: TXcomImageButton;
begin
  LGroup := TXcomImageButtonGroup.Create;
  LOther := TXcomImageButton.Create(10, 10, 20, 0);
  try
    FState.Add(LOther);
    LOther.SetColor(20);
    LOther.SetPixel(1, 1, 5);
    FButton.SetGroup(LGroup);
    LOther.SetGroup(LGroup);
    TEventSender.Mouse(FButton, ekMouseMotion, 5, 5);
    TEventSender.Mouse(FButton, ekMouseDown, 5, 5);
    Assert.AreSame(FButton, LGroup.Selected);
    Assert.AreEqual(41, Integer(FButton.GetPixel(1, 1)));
    TEventSender.Mouse(LOther, ekMouseMotion, 25, 5);
    TEventSender.Mouse(LOther, ekMouseDown, 25, 5);
    Assert.AreSame(LOther, LGroup.Selected);
    Assert.AreEqual(41, Integer(LOther.GetPixel(1, 1)));
    // the first one is given back
    Assert.AreEqual(5, Integer(FButton.GetPixel(1, 1)));
  finally
    FButton.SetGroup(nil);
    LOther.SetGroup(nil);
    LGroup.Free;
  end;
end;

procedure TTestXcomImageButton.IlClickInvertePoiRilascia;
begin
  FButton.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
    end);
  TEventSender.Mouse(FButton, ekMouseMotion, 5, 5);
  TEventSender.Mouse(FButton, ekMouseDown, 5, 5);
  Assert.AreEqual(41, Integer(FButton.GetPixel(1, 1)));
  TEventSender.Mouse(FButton, ekMouseUp, 5, 5);
  Assert.AreEqual(5, Integer(FButton.GetPixel(1, 1)));
end;

{ TTestXcomArrowButton }

procedure TTestXcomArrowButton.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FList := TRecordingList.Create;
  FListRef := FList;
end;

procedure TTestXcomArrowButton.TearDown;
begin
  FState.Free;
  FButton := nil;
  FListRef := nil;
  FWorld.Free;
end;

procedure TTestXcomArrowButton.Make(AShape: TXcomArrowShape);
begin
  FButton := TXcomArrowButton.Create(FWorld.Game.Clock, AShape, 13, 14, 10, 10);
  FState.Add(FButton);
  FButton.SetColor(20);
  FButton.SetTextList(FListRef);
end;

procedure TTestXcomArrowButton.IlBordoHaLeSfumature;
begin
  Make(arBigUp);
  FButton.Draw;
  Assert.AreEqual(21, Integer(FButton.GetPixel(0, 0)));
  Assert.AreEqual(24, Integer(FButton.GetPixel(12, 0)));
  Assert.AreEqual(24, Integer(FButton.GetPixel(0, 13)));
  Assert.AreEqual(22, Integer(FButton.GetPixel(0, 5)));
  Assert.AreEqual(25, Integer(FButton.GetPixel(12, 13)));
  Assert.AreEqual(24, Integer(FButton.GetPixel(3, 1)));
end;

procedure TTestXcomArrowButton.LaFrecciaGrandeInSuHaIlTriangolo;
begin
  Make(arBigUp);
  FButton.Draw;
  // the stem of 3 x 3 and the triangle that narrows to one pixel at the top
  Assert.AreEqual(21, Integer(FButton.GetPixel(6, 9)));
  Assert.AreEqual(21, Integer(FButton.GetPixel(2, 7)));
  Assert.AreEqual(21, Integer(FButton.GetPixel(10, 7)));
  Assert.AreEqual(21, Integer(FButton.GetPixel(6, 3)));
  Assert.AreEqual(24, Integer(FButton.GetPixel(6, 2)));
  Assert.AreEqual(24, Integer(FButton.GetPixel(2, 6)));
end;

procedure TTestXcomArrowButton.LeFreccePiccoleSiDisegnano;
begin
  Make(arSmallDown);
  FButton.Draw;
  // two triangles: the outer in color + 3 and the inner in color + 1
  Assert.AreEqual(23, Integer(FButton.GetPixel(1, 2)));
  Assert.AreEqual(21, Integer(FButton.GetPixel(2, 2)));
  Assert.AreEqual(23, Integer(FButton.GetPixel(5, 6)));
  FButton.SetShape(arSmallUp);
  FButton.Draw;
  Assert.AreEqual(23, Integer(FButton.GetPixel(1, 5)));
  Assert.AreEqual(21, Integer(FButton.GetPixel(2, 5)));
  FButton.SetShape(arSmallLeft);
  FButton.Draw;
  Assert.AreEqual(21, Integer(FButton.GetPixel(3, 4)));
  FButton.SetShape(arSmallRight);
  FButton.Draw;
  Assert.AreEqual(21, Integer(FButton.GetPixel(6, 4)));
end;

procedure TTestXcomArrowButton.TenereLaFrecciaScorreOgniCinquantaMillisecondi;
begin
  Make(arBigDown);
  TEventSender.Mouse(FButton, ekMouseMotion, 15, 15);
  TEventSender.Mouse(FButton, ekMouseDown, 15, 15);
  FWorld.Clock.Advance(49);
  FButton.Think;
  Assert.AreEqual(0, FList.Calls.Count);
  FWorld.Clock.Advance(1);
  FButton.Think;
  Assert.AreEqual('down00', FList.Calls[0]);
end;

procedure TTestXcomArrowButton.RilasciareFermaLoScorrimento;
begin
  Make(arBigUp);
  TEventSender.Mouse(FButton, ekMouseMotion, 15, 15);
  TEventSender.Mouse(FButton, ekMouseDown, 15, 15);
  TEventSender.Mouse(FButton, ekMouseUp, 15, 15);
  FWorld.Clock.Advance(200);
  FButton.Think;
  Assert.IsFalse(FList.Calls.IndexOf('up00') >= 0);
end;

procedure TTestXcomArrowButton.IlDestroVaAllaFine;
begin
  Make(arBigDown);
  TEventSender.Mouse(FButton, ekMouseMotion, 15, 15);
  TEventSender.Mouse(FButton, ekMouseDown, 15, 15, XCOM_BUTTON_RIGHT);
  TEventSender.Mouse(FButton, ekMouseUp, 15, 15, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FList.Calls.IndexOf('down10') >= 0);
  Make(arBigUp);
  TEventSender.Mouse(FButton, ekMouseMotion, 15, 15);
  TEventSender.Mouse(FButton, ekMouseDown, 15, 15, XCOM_BUTTON_RIGHT);
  TEventSender.Mouse(FButton, ekMouseUp, 15, 15, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FList.Calls.IndexOf('up10') >= 0);
end;

procedure TTestXcomArrowButton.LaRotellaScorreConLaRotella;
begin
  Make(arBigDown);
  TEventSender.Mouse(FButton, ekMouseMotion, 15, 15);
  TEventSender.Mouse(FButton, ekMouseDown, 15, 15, XCOM_BUTTON_WHEELUP);
  TEventSender.Mouse(FButton, ekMouseDown, 15, 15, XCOM_BUTTON_WHEELDOWN);
  Assert.IsTrue(FList.Calls.IndexOf('up01') >= 0);
  Assert.IsTrue(FList.Calls.IndexOf('down01') >= 0);
end;

procedure TTestXcomArrowButton.ConLaListaGestisceSinistroEDestro;
begin
  Make(arBigDown);
  Assert.IsTrue(FButton.IsButtonHandled(XCOM_BUTTON_LEFT));
  Assert.IsTrue(FButton.IsButtonHandled(XCOM_BUTTON_RIGHT));
  Assert.IsFalse(FButton.IsButtonHandled(XCOM_BUTTON_MIDDLE));
end;

procedure TTestXcomArrowButton.SenzaListaNonGestisceIlDestro;
begin
  Make(arBigDown);
  FButton.SetTextList(nil);
  Assert.IsFalse(FButton.IsButtonHandled(XCOM_BUTTON_RIGHT));
  FButton.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
    end,
    XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FButton.IsButtonHandled(XCOM_BUTTON_RIGHT));
end;

{ TTestXcomScrollBar }

procedure TTestXcomScrollBar.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FList := TRecordingList.Create;
  FListRef := FList;
  FList.Scroll := 4;
  FBar := TXcomScrollBar.Create(13, 50, 100, 20);
  FState.Add(FBar);
  FBar.SetColor(20);
  FBar.SetTextList(FListRef);
  FTarget := TXcomSurface.Create(200, 100);
end;

procedure TTestXcomScrollBar.TearDown;
begin
  FTarget.Free;
  FState.Free;
  FListRef := nil;
  FWorld.Free;
end;

procedure TTestXcomScrollBar.IlPollliceSegueLoScorrimento;
begin
  FBar.Draw;
  // 50 pixels for 20 rows: 2.5 pixels a row; 4 rows scrolled and 5 visible
  Assert.AreEqual(10, Integer(FBar.ThumbRect.Y));
  Assert.AreEqual(13, Integer(FBar.ThumbRect.H));
  Assert.AreEqual(13, Integer(FBar.ThumbRect.W));
  FList.Scroll := 0;
  FBar.Draw;
  Assert.AreEqual(0, Integer(FBar.ThumbRect.Y));
end;

procedure TTestXcomScrollBar.IlPollliceDisegnaGliAngoli;
begin
  FBar.Visible := True;
  FBar.Redraw := True;
  FBar.Blit(FTarget);
  // the corners of the thumb (the thumb surface is drawn at the position of the bar)
  Assert.AreEqual(21, Integer(FTarget.GetPixel(100, 30)));
  Assert.AreEqual(24, Integer(FTarget.GetPixel(112, 30)));
  Assert.AreEqual(24, Integer(FTarget.GetPixel(100, 42)));
end;

procedure TTestXcomScrollBar.IlPollliceTrascinatoScorreLaLista;
begin
  FBar.Draw;
  // the press inside the thumb keeps the distance from its top
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 32);
  TEventSender.Mouse(FBar, ekMouseDown, 105, 32);
  FList.Calls.Clear;
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 52);
  // cursor 32 from the top, offset -2: 30; 20 rows over 50 pixels: 12
  Assert.AreEqual('to12', FList.Calls[FList.Calls.Count - 1]);
end;

procedure TTestXcomScrollBar.UnClickFuoriDalPollliceLoCentra;
begin
  FBar.Draw;
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 60);
  TEventSender.Mouse(FBar, ekMouseDown, 105, 60);
  FList.Calls.Clear;
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 60);
  // cursor 40, offset -6 (half of the thumb): 34, over the 38 of the limit; 34 * 0.4 = 13.6
  Assert.AreEqual('to14', FList.Calls[FList.Calls.Count - 1]);
end;

procedure TTestXcomScrollBar.RilasciareFermaIlTrascinamento;
begin
  FBar.Draw;
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 32);
  TEventSender.Mouse(FBar, ekMouseDown, 105, 32);
  TEventSender.Mouse(FBar, ekMouseUp, 105, 32);
  FList.Calls.Clear;
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 52);
  Assert.AreEqual(0, FList.Calls.Count);
end;

procedure TTestXcomScrollBar.LaRotellaScorreLaLista;
begin
  TEventSender.Mouse(FBar, ekMouseMotion, 105, 32);
  TEventSender.Mouse(FBar, ekMouseDown, 105, 32, XCOM_BUTTON_WHEELUP);
  TEventSender.Mouse(FBar, ekMouseDown, 105, 32, XCOM_BUTTON_WHEELDOWN);
  Assert.IsTrue(FList.Calls.IndexOf('up01') >= 0);
  Assert.IsTrue(FList.Calls.IndexOf('down01') >= 0);
end;

procedure TTestXcomScrollBar.LaPistaUsaLoSfondoScuritoDi5;
var
  LBackground: TXcomSurface;
begin
  LBackground := TXcomSurface.Create(200, 100);
  try
    LBackground.Clear(90);
    FBar.SetBackground(LBackground);
    FBar.Draw;
    FBar.Redraw := False;
    FBar.Blit(FTarget);
    // 5 darker inside the block of 16 (the track is blitted before the thumb)
    Assert.AreEqual(85, Integer(FTarget.GetPixel(101, 25)));
  finally
    LBackground.Free;
  end;
end;

procedure TTestXcomScrollBar.ConUnComboBoxLaPistaSiSchiarisce;
var
  LBackground: TXcomSurface;
begin
  FList.Combo := True;
  LBackground := TXcomSurface.Create(200, 100);
  try
    LBackground.Clear(XCOM_BACKPOS + 3);
    FBar.SetBackground(LBackground);
    FBar.Draw;
    FBar.Blit(FTarget);
    Assert.AreEqual(XCOM_BACKPOS + 4, Integer(FTarget.GetPixel(101, 25)));
  finally
    LBackground.Free;
  end;
end;

procedure TTestXcomScrollBar.SpostandoLaBarraSiSpostanoPistaEPollice;
begin
  FBar.X := 50;
  FBar.Y := 5;
  FBar.Redraw := True;
  FBar.Blit(FTarget);
  Assert.AreEqual(21, Integer(FTarget.GetPixel(50, 15)));
  FBar.SetHeight(40);
  Assert.AreEqual(40, FBar.Height);
end;

{ TTestXcomSlider }

procedure TTestXcomSlider.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FSlider := TXcomSlider.Create(100, 10, 20, 30);
  FState.Add(FSlider);
  FSlider.SetColor(20);
  FSlider.SetRange(0, 100);
  FChanges := 0;
end;

procedure TTestXcomSlider.TearDown;
begin
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomSlider.ILPulsanteSiPosizionaSecondoIlValore;
begin
  // the frame goes from 28 to 112; the button is 10 wide: 28 to 102
  FSlider.SetValue(0);
  Assert.AreEqual(28, FSlider.Button.X);
  FSlider.SetValue(50);
  Assert.AreEqual(65, FSlider.Button.X);
  FSlider.SetValue(100);
  Assert.AreEqual(102, FSlider.Button.X);
end;

procedure TTestXcomSlider.IlValoreSiTieneNelRange;
begin
  FSlider.SetValue(250);
  Assert.AreEqual(100, FSlider.GetValue);
  FSlider.SetValue(-3);
  Assert.AreEqual(0, FSlider.GetValue);
  FSlider.SetValue(30);
  FSlider.SetRange(0, 20);
  Assert.AreEqual(20, FSlider.GetValue);
end;

procedure TTestXcomSlider.UnRangeInvertitoFunziona;
begin
  FSlider.SetRange(100, 0);
  FSlider.SetValue(30);
  Assert.AreEqual(30, FSlider.GetValue);
  // (30 - 100) / (0 - 100) = 0.7 of the way
  Assert.AreEqual(Trunc(28 + 74 * 0.7), FSlider.Button.X);
  FSlider.SetValue(500);
  Assert.AreEqual(100, FSlider.GetValue);
end;

procedure TTestXcomSlider.TrascinareImpostaIlValoreEAvvisa;
begin
  FSlider.SetValue(50);
  FSlider.OnChange(
    procedure(AAction: TXcomAction)
    begin
      Inc(FChanges);
    end);
  // the button goes from 65 to 74: pressed at 70 keeps 5 pixels to its left
  TEventSender.Mouse(FSlider, ekMouseMotion, 70, 35);
  TEventSender.Mouse(FSlider, ekMouseDown, 70, 35);
  TEventSender.Mouse(FSlider, ekMouseMotion, 90, 35);
  // the button at 85: (85 - 28) / 74 of 100 = 77
  Assert.AreEqual(77, FSlider.GetValue);
  Assert.IsTrue(FChanges > 0);
  TEventSender.Mouse(FSlider, ekMouseUp, 90, 35);
  FChanges := 0;
  TEventSender.Mouse(FSlider, ekMouseMotion, 100, 35);
  Assert.AreEqual(0, FChanges);
  Assert.AreEqual(77, FSlider.GetValue);
end;

procedure TTestXcomSlider.SpostareLoSliderSpostaIlPulsante;
begin
  FSlider.SetValue(50);
  FSlider.X := 40;
  // the frame starts at 48: 48 + 74 / 2
  Assert.AreEqual(85, FSlider.Button.X);
  FSlider.Y := 60;
  Assert.AreEqual(60, FSlider.Button.Y);
end;

procedure TTestXcomSlider.UnRangeNulloNonDividePerZero;
begin
  FSlider.SetRange(5, 5);
  FSlider.SetValue(5);
  Assert.AreEqual(5, FSlider.GetValue);
  Assert.AreEqual(28, FSlider.Button.X);
end;

procedure TTestXcomSlider.IlColoreSiPassaATutto;
begin
  FSlider.SetColor(40);
  Assert.AreEqual(40, Integer(FSlider.GetColor));
  Assert.AreEqual(40, Integer(FSlider.Button.GetColor));
end;

procedure TTestXcomSlider.DisegnaIlMenoEIlPiu;
var
  LTarget: TXcomSurface;
  LX: Integer;
  LCount: Integer;
begin
  LTarget := TXcomSurface.Create(200, 100);
  try
    FSlider.Button.Redraw := True;
    FSlider.Blit(LTarget);
    LCount := 0;
    // something is drawn at the left end (the minus) and at the right end (the plus)
    for LX := 19 to 27 do
      if LTarget.GetPixel(LX, 32) <> 0 then
        Inc(LCount);
    Assert.IsTrue(LCount > 0);
    LCount := 0;
    for LX := 112 to 119 do
      if LTarget.GetPixel(LX, 32) <> 0 then
        Inc(LCount);
    Assert.IsTrue(LCount > 0);
  finally
    LTarget.Free;
  end;
end;

{ TTestXcomTextList }

type
  TRecordingCombo = class(TInterfacedObject, IXcomComboBoxLink)
  public
    Selected: Integer;
    Toggles: Integer;
    procedure SetSelected(ASelected: Integer);
    procedure ToggleList;
  end;

procedure TRecordingCombo.SetSelected(ASelected: Integer);
begin
  Selected := ASelected;
end;

procedure TRecordingCombo.ToggleList;
begin
  Inc(Toggles);
end;

procedure TTestXcomTextList.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FBackground := TXcomSurface.Create(320, 200);
  FBackground.Clear(80);
  FList := TXcomTextList.Create(FWorld.Game.Options, FWorld.Game.Clock, 100, 40, 10, 20);
  FState.Add(FList);
  FList.SetColor(20);
  FList.SetColumns([60, 40]);
  FList.SetBackground(FBackground);
end;

procedure TTestXcomTextList.TearDown;
begin
  FState.Free;
  FBackground.Free;
  FWorld.Free;
end;

procedure TTestXcomTextList.Fill(ARows: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ARows do
    FList.AddRow(['A' + IntToStr(LIndex), 'B']);
end;

procedure TTestXcomTextList.LeRigheVisibiliDipendonoDallAltezza;
begin
  // 40 pixels of height and a font of 8 with a spacing of 1: rows at 0, 9, 18, 27, 36
  Assert.AreEqual(5, FList.GetVisibleRows);
  FList.SetHeight(20);
  Assert.AreEqual(3, FList.GetVisibleRows);
end;

procedure TTestXcomTextList.AggiungereRigheLeConta;
begin
  Fill(3);
  Assert.AreEqual(3, FList.GetTexts);
  Assert.AreEqual(3, FList.GetRows);
end;

procedure TTestXcomTextList.ILTestoDelleCelleSiLegge;
begin
  Fill(3);
  Assert.AreEqual('A2', FList.GetCellText(1, 0));
  Assert.AreEqual('B', FList.GetCellText(1, 1));
  FList.SetCellText(1, 0, 'ZZ');
  Assert.AreEqual('ZZ', FList.GetCellText(1, 0));
end;

procedure TTestXcomTextList.ScorreInSuEInGiu;
begin
  Fill(8);
  FList.ScrollDown(False);
  Assert.AreEqual(1, FList.GetScroll);
  FList.ScrollDown(False);
  Assert.AreEqual(2, FList.GetScroll);
  FList.ScrollUp(False);
  Assert.AreEqual(1, FList.GetScroll);
end;

procedure TTestXcomTextList.ScrollToTieneLaListaNelLimite;
begin
  Fill(8);
  FList.ScrollTo(100);
  Assert.AreEqual(3, FList.GetScroll);
  FList.ScrollTo(-5);
  Assert.AreEqual(0, FList.GetScroll);
end;

procedure TTestXcomTextList.ScorrereAlMassimoVaAllaFine;
begin
  Fill(8);
  FList.ScrollDown(True);
  Assert.AreEqual(3, FList.GetScroll);
  FList.ScrollUp(True);
  Assert.AreEqual(0, FList.GetScroll);
end;

procedure TTestXcomTextList.LaRotellaScorreDellaVelocitaDelleOpzioni;
begin
  Fill(20);
  FList.ScrollDown(False, True);
  Assert.AreEqual(3, FList.GetScroll);
  FWorld.Game.Options.MousewheelSpeed := 5;
  FList.ScrollDown(False, True);
  Assert.AreEqual(8, FList.GetScroll);
  // upwards it stops at the top
  FList.ScrollUp(False, True);
  Assert.AreEqual(3, FList.GetScroll);
  FList.ScrollUp(False, True);
  Assert.AreEqual(0, FList.GetScroll);
end;

procedure TTestXcomTextList.SenzaScorrimentoNonScorre;
begin
  Fill(8);
  FList.SetScrolling(False);
  FList.ScrollDown(False);
  Assert.AreEqual(0, FList.GetScroll);
  FList.ScrollTo(2);
  Assert.AreEqual(0, FList.GetScroll);
end;

procedure TTestXcomTextList.SvuotareLaListaAzzeraLoScorrimento;
begin
  Fill(8);
  FList.ScrollDown(True);
  FList.ClearList;
  Assert.AreEqual(0, FList.GetRows);
  Assert.AreEqual(0, FList.GetTexts);
  Fill(2);
  Assert.AreEqual(0, FList.GetScroll);
  Assert.AreEqual(2, FList.GetRows);
end;

procedure TTestXcomTextList.IlTestoAcapoOccupaPiuRighe;
begin
  FList.SetWordWrap(True);
  FList.AddRow(['AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA BBBBBBBBBBBBBBBBBBBBBBBBBB', 'X']);
  Assert.AreEqual(1, FList.GetTexts);
  Assert.IsTrue(FList.GetRows > 1);
  Assert.IsTrue(FList.GetNumTextLines(0) > 1);
end;

procedure TTestXcomTextList.IPuntiRiempionoLaColonna;
begin
  FList.SetDot(True);
  FList.AddRow(['AB', '1']);
  Assert.IsTrue(Length(FList.GetCellText(0, 0)) > 2);
  Assert.AreEqual('AB', Copy(FList.GetCellText(0, 0), 1, 2));
  Assert.AreEqual('.', Copy(FList.GetCellText(0, 0), Length(FList.GetCellText(0, 0)), 1));
  // the last column has none
  Assert.AreEqual('1', FList.GetCellText(0, 1));
end;

procedure TTestXcomTextList.LeColonneSiPosizionano;
begin
  FList.SetMargin(5);
  Fill(2);
  Assert.AreEqual(15, FList.GetColumnX(0));
  Assert.AreEqual(75, FList.GetColumnX(1));
  Assert.AreEqual(20, FList.GetRowY(0));
end;

procedure TTestXcomTextList.SelezionabileEvidenziaLaRigaSottoIlMouse;
begin
  FList.SetSelectable(True);
  Fill(3);
  // before the mouse passes, the selected row is the first (as in the C++)
  Assert.AreEqual(0, FList.GetSelectedRow);
  TEventSender.Mouse(FList, ekMouseMotion, 30, 30);
  Assert.AreEqual(1, FList.GetSelectedRow);
  TEventSender.Mouse(FList, ekMouseMotion, 30, 22);
  Assert.AreEqual(0, FList.GetSelectedRow);
  // below the last row nothing is selected
  TEventSender.Mouse(FList, ekMouseMotion, 30, 55);
  Assert.AreEqual(-1, FList.GetSelectedRow);
end;

procedure TTestXcomTextList.IlClickDaLaRigaSelezionata;
var
  LRow: Integer;
begin
  LRow := -2;
  FList.SetSelectable(True);
  Fill(3);
  FList.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      LRow := FList.GetSelectedRow;
    end);
  TEventSender.Mouse(FList, ekMouseMotion, 30, 30);
  TEventSender.Mouse(FList, ekMouseDown, 30, 30);
  TEventSender.Mouse(FList, ekMouseUp, 30, 30);
  Assert.AreEqual(1, LRow);
  // a click on an empty place is not given to the handler
  LRow := -2;
  TEventSender.Mouse(FList, ekMouseMotion, 30, 55);
  TEventSender.Mouse(FList, ekMouseDown, 30, 55);
  TEventSender.Mouse(FList, ekMouseUp, 30, 55);
  Assert.AreEqual(-2, LRow);
end;

procedure TTestXcomTextList.IlComboBoxRiceveLaRigaScelta;
var
  LCombo: TRecordingCombo;
  LRef: IXcomComboBoxLink;
begin
  LCombo := TRecordingCombo.Create;
  LRef := LCombo;
  FList.SetSelectable(True);
  Fill(3);
  FList.SetComboBox(LRef);
  Assert.IsTrue(FList.HasComboBox);
  TEventSender.Mouse(FList, ekMouseMotion, 30, 30);
  TEventSender.Mouse(FList, ekMouseDown, 30, 30);
  TEventSender.Mouse(FList, ekMouseUp, 30, 30);
  Assert.AreEqual(1, LCombo.Selected);
  Assert.AreEqual(1, LCombo.Toggles);
  FList.SetComboBox(nil);
end;

procedure TTestXcomTextList.IlFontGrandeCambiaLeRigheVisibili;
begin
  FList.SetBig;
  // the big font is 10 high with a spacing of 1: rows at 0, 11, 22, 33
  Assert.AreEqual(4, FList.GetVisibleRows);
  FList.SetSmall;
  Assert.AreEqual(5, FList.GetVisibleRows);
end;

procedure TTestXcomTextList.LeFrecceDiRigaGestisconoIClick;
var
  LTarget: TXcomSurface;
  LLeft: Integer;
  LRight: Integer;
begin
  LLeft := 0;
  LRight := 0;
  FList.SetArrowColumn(20, aoVertical);
  FList.OnLeftArrowClick(
    procedure(AAction: TXcomAction)
    begin
      Inc(LLeft);
    end);
  FList.OnRightArrowClick(
    procedure(AAction: TXcomAction)
    begin
      Inc(LRight);
    end);
  Fill(3);
  LTarget := TXcomSurface.Create(320, 200);
  try
    FList.Redraw := True;
    // the position of the arrows is set while the list is blitted
    FList.Blit(LTarget);
  finally
    LTarget.Free;
  end;
  Assert.AreEqual(30, FList.GetArrowsLeftEdge);
  Assert.AreEqual(30 + 12 + 11, FList.GetArrowsRightEdge);
  TEventSender.Mouse(FList, ekMouseMotion, 33, 23);
  TEventSender.Mouse(FList, ekMouseDown, 33, 23);
  TEventSender.Mouse(FList, ekMouseUp, 33, 23);
  Assert.AreEqual(1, LLeft);
  TEventSender.Mouse(FList, ekMouseMotion, 46, 23);
  TEventSender.Mouse(FList, ekMouseDown, 46, 23);
  TEventSender.Mouse(FList, ekMouseUp, 46, 23);
  Assert.AreEqual(1, LRight);
end;

{ TTestXcomComboBox }

procedure TTestXcomComboBox.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FCombo := TXcomComboBox.Create(FState, 80, 14, 10, 10);
  FState.Add(FCombo);
  FCombo.SetColor(20);
  FCombo.SetOptions(['a', 'b', 'c']);
  FChanges := 0;
end;

procedure TTestXcomComboBox.TearDown;
begin
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomComboBox.PartiChiuso;
begin
  Assert.IsFalse(FCombo.PopupWindow.Visible);
  Assert.IsFalse(FCombo.List.Visible);
  Assert.AreEqual(0, FCombo.GetSelected);
  Assert.AreEqual('a', FCombo.Button.GetText);
end;

procedure TTestXcomComboBox.SelezionareMostraIlTestoNelPulsante;
begin
  FCombo.SetSelected(1);
  Assert.AreEqual('b', FCombo.Button.GetText);
  Assert.AreEqual(1, FCombo.GetSelected);
  FCombo.SetText('free');
  Assert.AreEqual('free', FCombo.Button.GetText);
end;

procedure TTestXcomComboBox.IlToggleApreELaListaEModale;
var
  LAction: TXcomAction;
  LEvent: TXcomInputEvent;
begin
  FCombo.ToggleList;
  Assert.IsTrue(FCombo.PopupWindow.Visible);
  Assert.IsTrue(FCombo.List.Visible);
  // modal: the state gives the events only to the combo box (a click on the list reaches it)
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := 30;
  LEvent.Y := 30;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    FState.Handle(LAction);
  finally
    LAction.Free;
  end;
  Assert.AreEqual(0, FCombo.List.GetSelectedRow);
  FCombo.ToggleList;
  Assert.IsFalse(FCombo.PopupWindow.Visible);
end;

procedure TTestXcomComboBox.ChiudereAvvisaDelCambiamentoAlProssimoEvento;
begin
  FCombo.OnChange(
    procedure(AAction: TXcomAction)
    begin
      Inc(FChanges);
    end);
  FCombo.ToggleList;
  FCombo.ToggleList;
  Assert.AreEqual(0, FChanges);
  TEventSender.Mouse(FCombo, ekMouseMotion, 300, 190);
  Assert.AreEqual(1, FChanges);
  TEventSender.Mouse(FCombo, ekMouseMotion, 300, 190);
  Assert.AreEqual(1, FChanges);
end;

procedure TTestXcomComboBox.IlSuggerimentoEIlSelezionatoSeLaListaEChiusa;
begin
  FCombo.SetSelected(2);
  Assert.AreEqual(2, FCombo.GetHoveredListIdx);
end;

procedure TTestXcomComboBox.IlMenuAppareSottoIlPulsanteOSopra;
var
  LAbove: TXcomComboBox;
begin
  // 3 rows of 9 and the margins: 33 pixels; below the button (10 + 14)
  Assert.AreEqual(24, FCombo.PopupWindow.Y);
  Assert.AreEqual(33, FCombo.PopupWindow.Height);
  LAbove := TXcomComboBox.Create(FState, 80, 14, 10, 100, True);
  FState.Add(LAbove);
  LAbove.SetColor(20);
  LAbove.SetOptions(['a', 'b', 'c']);
  Assert.AreEqual(100 - 33, LAbove.PopupWindow.Y);
  LAbove.Y := 120;
  Assert.AreEqual(120 - 33, LAbove.PopupWindow.Y);
end;

procedure TTestXcomComboBox.LaListaSiAccorciaSeNonStaNelloSchermo;
var
  LLow: TXcomComboBox;
begin
  LLow := TXcomComboBox.Create(FState, 80, 14, 10, 170);
  FState.Add(LLow);
  LLow.SetColor(20);
  LLow.SetOptions(['a', 'b', 'c']);
  // below the button at 184: only one row of 9 plus the margins fits before 200
  Assert.AreEqual(15, LLow.PopupWindow.Height);
  Assert.AreEqual(9, LLow.List.Height);
end;

procedure TTestXcomComboBox.UnClickFuoriChiudeLaLista;
begin
  FCombo.ToggleList;
  Assert.IsTrue(FCombo.PopupWindow.Visible);
  TEventSender.Mouse(FCombo, ekMouseDown, 300, 150);
  Assert.IsFalse(FCombo.PopupWindow.Visible);
end;

{ TTestXcomTextEdit }

procedure TTestXcomTextEdit.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FEdit := TXcomTextEdit.Create(FState, 100, 12, 10, 10);
  FState.Add(FEdit);
  FEdit.SetColor(20);
  FChanges := 0;
end;

procedure TTestXcomTextEdit.TearDown;
begin
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomTextEdit.TypeText(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    TEventSender.Key(FEdit, 0, Ord(AText[LIndex]));
end;

procedure TTestXcomTextEdit.PartiSenzaFocus;
begin
  Assert.IsFalse(FEdit.IsFocused);
  TypeText('abc');
  Assert.AreEqual('', FEdit.GetText);
end;

procedure TTestXcomTextEdit.UnClickDaIlFocusEMettaIlCursoreInFondo;
begin
  FEdit.SetText('abc');
  TEventSender.Mouse(FEdit, ekMouseMotion, 20, 15);
  TEventSender.Mouse(FEdit, ekMouseDown, 20, 15);
  Assert.IsTrue(FEdit.IsFocused);
  TypeText('d');
  Assert.AreEqual('abcd', FEdit.GetText);
end;

procedure TTestXcomTextEdit.SiScriveCarattereDopoCarattere;
begin
  FEdit.SetFocus(True);
  TypeText('Hi 5');
  Assert.AreEqual('Hi 5', FEdit.GetText);
end;

procedure TTestXcomTextEdit.IlBackspaceCancellaPrimaDelCursore;
begin
  FEdit.SetFocus(True);
  TypeText('abc');
  TEventSender.Key(FEdit, XCOM_KEY_BACKSPACE);
  Assert.AreEqual('ab', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_LEFT);
  TEventSender.Key(FEdit, XCOM_KEY_LEFT);
  TEventSender.Key(FEdit, XCOM_KEY_BACKSPACE);
  Assert.AreEqual('ab', FEdit.GetText);
end;

procedure TTestXcomTextEdit.CancCancellaDopoIlCursore;
begin
  FEdit.SetFocus(True);
  TypeText('abc');
  TEventSender.Key(FEdit, XCOM_KEY_HOME);
  TEventSender.Key(FEdit, XCOM_KEY_DELETE);
  Assert.AreEqual('bc', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_END);
  TEventSender.Key(FEdit, XCOM_KEY_DELETE);
  Assert.AreEqual('bc', FEdit.GetText);
end;

procedure TTestXcomTextEdit.FreccePrincipioEFineEInserimento;
begin
  FEdit.SetFocus(True);
  TypeText('abc');
  TEventSender.Key(FEdit, XCOM_KEY_HOME);
  TypeText('X');
  Assert.AreEqual('Xabc', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_RIGHT);
  TypeText('Y');
  Assert.AreEqual('XaYbc', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_END);
  TypeText('Z');
  Assert.AreEqual('XaYbcZ', FEdit.GetText);
end;

procedure TTestXcomTextEdit.InvioChiudeSoloSeCEDelTesto;
begin
  FEdit.SetFocus(True);
  TEventSender.Key(FEdit, XCOM_KEY_RETURN);
  Assert.IsTrue(FEdit.IsFocused);
  TypeText('x');
  TEventSender.Key(FEdit, XCOM_KEY_RETURN);
  Assert.IsFalse(FEdit.IsFocused);
end;

procedure TTestXcomTextEdit.NonSiScriveOltreLaLarghezza;
begin
  FEdit.SetFocus(True);
  TypeText(StringOfChar('M', 60));
  Assert.IsTrue(Length(FEdit.GetText) > 5);
  Assert.IsTrue(Length(FEdit.GetText) < 60);
end;

procedure TTestXcomTextEdit.IlVincoloNumericoPositivoAccettaSoloCifre;
begin
  FEdit.SetConstraint(tecNumericPositive);
  FEdit.SetFocus(True);
  TypeText('a5b-7+');
  Assert.AreEqual('57', FEdit.GetText);
end;

procedure TTestXcomTextEdit.IlVincoloNumericoAccettaIlSegnoSoloInTesta;
begin
  FEdit.SetConstraint(tecNumeric);
  FEdit.SetFocus(True);
  TypeText('-5-');
  Assert.AreEqual('-5', FEdit.GetText);
  FEdit.SetText('5');
  TEventSender.Key(FEdit, XCOM_KEY_HOME);
  TypeText('-');
  Assert.AreEqual('-5', FEdit.GetText);
  // with a sign already there, a second one is refused
  TEventSender.Key(FEdit, XCOM_KEY_HOME);
  TypeText('+');
  Assert.AreEqual('-5', FEdit.GetText);
end;

procedure TTestXcomTextEdit.IlCursoreLampeggiaOgniCentoMillisecondi;
  function Count: Integer;
  var
    LX: Integer;
    LY: Integer;
  begin
    Result := 0;
    for LY := 0 to 11 do
      for LX := 0 to 99 do
        if FEdit.GetPixel(LX, LY) <> 0 then
          Inc(Result);
  end;
begin
  FEdit.SetFocus(True);
  FEdit.Draw;
  Assert.IsTrue(Count > 0);
  FWorld.Clock.Advance(100);
  FEdit.Think;
  FEdit.Draw;
  Assert.AreEqual(0, Count);
  FWorld.Clock.Advance(100);
  FEdit.Think;
  FEdit.Draw;
  Assert.IsTrue(Count > 0);
end;

procedure TTestXcomTextEdit.ClickFuoriTogliIlFocus;
begin
  FEdit.SetFocus(True);
  TEventSender.Mouse(FEdit, ekMouseDown, 300, 190);
  Assert.IsFalse(FEdit.IsFocused);
end;

procedure TTestXcomTextEdit.SenzaTastieraSiSceglieLaLetteraConLeFrecce;
begin
  FWorld.Game.Options.KeyboardMode := kmOff;
  FEdit.SetFocus(True);
  TEventSender.Key(FEdit, XCOM_KEY_UP);
  TEventSender.Key(FEdit, XCOM_KEY_RIGHT);
  Assert.AreEqual('B', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_DOWN);
  TEventSender.Key(FEdit, XCOM_KEY_RIGHT);
  Assert.AreEqual('BA', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_LEFT);
  Assert.AreEqual('B', FEdit.GetText);
  TEventSender.Key(FEdit, XCOM_KEY_LEFT);
  TEventSender.Key(FEdit, XCOM_KEY_LEFT);
  Assert.AreEqual('', FEdit.GetText);
end;

procedure TTestXcomTextEdit.IlGestoreDelCambioViene;
begin
  FEdit.OnChange(
    procedure(AAction: TXcomAction)
    begin
      Inc(FChanges);
    end);
  FEdit.SetFocus(True);
  TypeText('ab');
  Assert.AreEqual(2, FChanges);
end;

{ TTestXcomBattlescapeButton }

procedure TTestXcomBattlescapeButton.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TFlatState.Create(FWorld.Game);
  FButton := TXcomBattlescapeButton.Create(10, 10, 5, 5);
  FState.Add(FButton);
  FButton.SetColor(20);
  FTarget := TXcomSurface.Create(40, 40);
end;

procedure TTestXcomBattlescapeButton.TearDown;
begin
  FTarget.Free;
  FState.Free;
  FWorld.Free;
end;

procedure TTestXcomBattlescapeButton.Prepare;
begin
  FButton.SetPixel(1, 1, 5);
  FButton.SetPixel(2, 2, 3);
  FButton.InitSurfaces;
end;

procedure TTestXcomBattlescapeButton.LaSecondaImmagineInvertePerIlColore;
begin
  Prepare;
  FButton.AllowToggleInversion;
  FButton.Toggle(True);
  FButton.Blit(FTarget);
  // 5 + 2 * (23 - 5) = 41; 3 + 2 * (23 - 3) = 43; the transparent stays
  Assert.AreEqual(41, Integer(FTarget.GetPixel(6, 6)));
  Assert.AreEqual(43, Integer(FTarget.GetPixel(7, 7)));
  Assert.AreEqual(0, Integer(FTarget.GetPixel(8, 8)));
end;

procedure TTestXcomBattlescapeButton.InModalitaTftdUsaLaTabella;
begin
  FButton.TftdMode := True;
  FButton.SetPixel(1, 1, 3);
  FButton.SetPixel(2, 2, 47);
  FButton.SetPixel(3, 3, 99);
  FButton.InitSurfaces;
  // in the TFTD mode Toggle always works
  FButton.Toggle(True);
  Assert.IsTrue(FButton.Inverted);
  FButton.Blit(FTarget);
  Assert.AreEqual(4, Integer(FTarget.GetPixel(6, 6)));
  Assert.AreEqual(2, Integer(FTarget.GetPixel(7, 7)));
  Assert.AreEqual(99, Integer(FTarget.GetPixel(8, 8)));
end;

procedure TTestXcomBattlescapeButton.PremutoDisegnaLaSecondaImmagine;
begin
  Prepare;
  FButton.Blit(FTarget);
  Assert.AreEqual(5, Integer(FTarget.GetPixel(6, 6)));
  FButton.AllowToggleInversion;
  FButton.Toggle(True);
  FTarget.Clear;
  FButton.Blit(FTarget);
  Assert.AreEqual(41, Integer(FTarget.GetPixel(6, 6)));
  FButton.Toggle(False);
  FTarget.Clear;
  FButton.Blit(FTarget);
  Assert.AreEqual(5, Integer(FTarget.GetPixel(6, 6)));
end;

procedure TTestXcomBattlescapeButton.IlGruppoTieneSoloUnPulsante;
var
  LGroup: TXcomBattlescapeButtonGroup;
  LOther: TXcomBattlescapeButton;
begin
  LGroup := TXcomBattlescapeButtonGroup.Create;
  LOther := TXcomBattlescapeButton.Create(10, 10, 20, 5);
  try
    FState.Add(LOther);
    FButton.SetGroup(LGroup);
    LOther.SetGroup(LGroup);
    LGroup.Selected := FButton;
    FButton.SetGroup(LGroup);
    Assert.IsTrue(FButton.Inverted);
    TEventSender.Mouse(LOther, ekMouseMotion, 25, 8);
    TEventSender.Mouse(LOther, ekMouseDown, 25, 8);
    Assert.AreSame(LOther, LGroup.Selected);
    Assert.IsTrue(LOther.Inverted);
    Assert.IsFalse(FButton.Inverted);
  finally
    FButton.SetGroup(nil);
    LOther.SetGroup(nil);
    LGroup.Free;
  end;
end;

procedure TTestXcomBattlescapeButton.IlClickInvertePerIlTempoDelClick;
begin
  FButton.AllowClickInversion;
  FButton.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
    end);
  TEventSender.Mouse(FButton, ekMouseMotion, 8, 8);
  TEventSender.Mouse(FButton, ekMouseDown, 8, 8);
  Assert.IsTrue(FButton.Inverted);
  TEventSender.Mouse(FButton, ekMouseUp, 8, 8);
  Assert.IsFalse(FButton.Inverted);
end;

procedure TTestXcomBattlescapeButton.IlToggleDeveEssereConsentito;
begin
  FButton.Toggle(True);
  Assert.IsFalse(FButton.Inverted);
  FButton.AllowToggleInversion;
  FButton.Toggle(True);
  Assert.IsTrue(FButton.Inverted);
end;

end.
