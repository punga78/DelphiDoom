{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom engine - screen, interactive surfaces,    }
{  states and the game loop                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Game;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomInteractiveSurface = class
  strict private
    FSurface: TXcomInteractiveSurface;
    FLog: string;
    function Action(AKind: TXcomEventKind; AX, AY: Integer; AButton: Integer = 1;
      AKey: Integer = 0; AModifiers: Integer = 0): TXcomAction;
    procedure Send(AKind: TXcomEventKind; AX, AY: Integer; AButton: Integer = 1; AKey: Integer = 0;
      AModifiers: Integer = 0);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure EntrareNellaSuperficieChiamaIn;
    [Test]
    procedure UscireChiamaOut;
    [Test]
    procedure PremereEDareClickChiamaPressRilascioEClick;
    [Test]
    procedure IlClickSenzaEssereDentroNonCliccaMaRilascia;
    [Test]
    procedure UnGestoreDiUnSoloPulsanteNonRispondeAGliAltri;
    [Test]
    procedure UnGestoreDiTuttiIPulsantiRispondeAQualunque;
    [Test]
    procedure IlTastoChiamaIlGestore;
    [Test]
    procedure ConUnModificatoreIlTastoSpecificoNonScatta;
    [Test]
    procedure IlGestoreDiOgniTastoScattaSempre;
    [Test]
    procedure IlRilascioDelTastoChiamaIlGestoreDelRilascio;
    [Test]
    procedure SenzaFuocoITastiNonArrivano;
    [Test]
    procedure UnaSuperficieNascostaNonRiceveEventi;
    [Test]
    procedure RendereInvisibileSollevaIlPulsante;
    [Test]
    procedure UnpressRilasciaIlPulsante;
    [Test]
    procedure IsButtonHandledVedeIGestori;
    [Test]
    procedure TogliereUnGestoreLoCancella;
    [Test]
    procedure IlTastoSconosciutoSiIgnora;
    [Test]
    procedure LaSuperficieListaPremeQuandoIlMouseEntraConIlPulsanteGiaGiu;
    [Test]
    procedure LaSuperficieListaRilasciaQuandoIlMouseEsce;
    [Test]
    procedure LeCoordinateDelMouseSonoQuelleDelGioco;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomScreen = class
  strict private
    FWorld: TTestWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaScalaDuePerDueCopiaOgniPixelInUnQuadrato;
    [Test]
    procedure IlPaletteDifferitoArrivaAlDisplayConIlFlip;
    [Test]
    procedure ConLaProporzioneMantenutaNascenoLeFasceLaterali;
    [Test]
    procedure ConLaProporzioneMantenutaNascenoLeFasceInAltoEInBasso;
    [Test]
    procedure IlCursoreNelleFasceCambiaLaScala;
    [Test]
    procedure DXeDYCentranoLoSchermoOriginale;
    [Test]
    procedure UpdateScaleDaLeDimensioniDelleOpzioni;
    [Test]
    procedure UpdateScaleNonCambiaLaBaseSeNonSiChiede;
    [Test]
    procedure ClearAzzeraLaBase;
    [Test]
    procedure IlTastoDelloScreenshotSiRicordaUnaSolaVolta;
    [Test]
    procedure ResetDisplayAdattaLaBaseALleOpzioni;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomGame = class
  strict private
    FWorld: TTestWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaStatiIlGiocoEsce;
    [Test]
    procedure LoStatoInCimaRiceveInitEThink;
    [Test]
    procedure DisegnaCirca60FotogrammiAlSecondo;
    [Test]
    procedure PushEPopCambianoLoStatoInCima;
    [Test]
    procedure SetStateSostituisceTuttiGliStati;
    [Test]
    procedure UnEventoDiUscitaFermaIlGioco;
    [Test]
    procedure IlTastoScreenshotChiamaIlGestore;
    [Test]
    procedure DisegnaDallUltimoStatoATuttoSchermo;
    [Test]
    procedure UnStatoPoppatoSiLiberaAlTurnoDopo;
    [Test]
    procedure LeAzioniDelMouseArrivanoSoloSeIlMouseEAttivo;
    [Test]
    procedure AdoptDataCambiaLaLingua;
    [Test]
    procedure IlCursoreSegueIlMouse;
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomState = class
  strict private
    FWorld: TTestWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure AddDaLaPaletteDelloStatoALaSuperficie;
    [Test]
    procedure IlColoreDellInterfacciaVieneApplicatoAlLElemento;
    [Test]
    procedure SetInterfaceCaricaLaPaletteELoSfondoDelleFinestre;
    [Test]
    procedure TrDaLeStringhe;
    [Test]
    procedure CenterAllSurfacesAggiungeIlCentro;
    [Test]
    procedure HideAllEShowAll;
    [Test]
    procedure ILStatoModaleRiceveGliEventiDaSolo;
    [Test]
    procedure ResizeSpostaLeSuperfici;
    [Test]
    procedure SetPaletteDaNomeCopiaIBlocchiDiBackpals;
    [Test]
    procedure LoStatoDiUnoSchermoEUnoSchermo;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.Language;

type
  TProbeSurface = class(TXcomInteractiveSurface)
  public
    Thinks: Integer;
    Blits: Integer;
    Drawn: Integer;
    procedure Think; override;
    procedure Draw; override;
    procedure Blit(ATarget: TXcomSurface); override;
  end;

  TProbeState = class(TXcomState)
  public
    Inits: Integer;
    Thinks: Integer;
    Blits: Integer;
    Handled: Integer;
    Probe: TProbeSurface;
    constructor Create(AHost: TXcomStateHost);
    procedure Init; override;
    procedure Think; override;
    procedure Blit; override;
    procedure Handle(AAction: TXcomAction); override;
  end;

procedure TProbeSurface.Think;
begin
  Inc(Thinks);
end;

procedure TProbeSurface.Draw;
begin
  inherited Draw;
  Inc(Drawn);
end;

procedure TProbeSurface.Blit(ATarget: TXcomSurface);
begin
  Inc(Blits);
  inherited Blit(ATarget);
end;

constructor TProbeState.Create(AHost: TXcomStateHost);
begin
  inherited Create(AHost);
  Probe := TProbeSurface.Create(10, 10, 0, 0);
  Add(Probe);
end;

procedure TProbeState.Init;
begin
  Inc(Inits);
  inherited Init;
end;

procedure TProbeState.Think;
begin
  Inc(Thinks);
  inherited Think;
end;

procedure TProbeState.Blit;
begin
  Inc(Blits);
  inherited Blit;
end;

procedure TProbeState.Handle(AAction: TXcomAction);
begin
  Inc(Handled);
  inherited Handle(AAction);
end;

{ TTestXcomInteractiveSurface }

procedure TTestXcomInteractiveSurface.Setup;
begin
  FSurface := TXcomInteractiveSurface.Create(20, 20, 10, 10);
  FLog := '';
end;

procedure TTestXcomInteractiveSurface.TearDown;
begin
  FSurface.Free;
end;

function TTestXcomInteractiveSurface.Action(AKind: TXcomEventKind; AX, AY, AButton, AKey,
  AModifiers: Integer): TXcomAction;
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := AButton;
  LEvent.Key := AKey;
  LEvent.Modifiers := AModifiers;
  Result := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
end;

procedure TTestXcomInteractiveSurface.Send(AKind: TXcomEventKind; AX, AY, AButton, AKey, AModifiers: Integer);
var
  LAction: TXcomAction;
begin
  LAction := Action(AKind, AX, AY, AButton, AKey, AModifiers);
  try
    FSurface.Handle(LAction);
  finally
    LAction.Free;
  end;
end;

procedure TTestXcomInteractiveSurface.EntrareNellaSuperficieChiamaIn;
begin
  FSurface.OnMouseIn(procedure(A: TXcomAction) begin FLog := FLog + 'in;'; end);
  FSurface.OnMouseOver(procedure(A: TXcomAction) begin FLog := FLog + 'over;'; end);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseMotion, 16, 16);
  Assert.AreEqual('in;over;over;', FLog);
  Assert.IsTrue(FSurface.IsHovered);
end;

procedure TTestXcomInteractiveSurface.UscireChiamaOut;
begin
  FSurface.OnMouseOut(procedure(A: TXcomAction) begin FLog := FLog + 'out;'; end);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseMotion, 100, 100);
  Send(ekMouseMotion, 101, 101);
  Assert.AreEqual('out;', FLog);
  Assert.IsFalse(FSurface.IsHovered);
end;

procedure TTestXcomInteractiveSurface.PremereEDareClickChiamaPressRilascioEClick;
begin
  FSurface.OnMousePress(procedure(A: TXcomAction) begin FLog := FLog + 'press;'; end);
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin FLog := FLog + 'release;'; end);
  FSurface.OnMouseClick(procedure(A: TXcomAction) begin FLog := FLog + 'click;'; end);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseDown, 15, 15);
  Assert.IsTrue(FSurface.IsButtonPressed(XCOM_BUTTON_LEFT));
  Assert.IsTrue(FSurface.IsButtonPressed);
  Send(ekMouseUp, 15, 15);
  Assert.AreEqual('press;release;click;', FLog);
  Assert.IsFalse(FSurface.IsButtonPressed);
end;

procedure TTestXcomInteractiveSurface.IlClickSenzaEssereDentroNonCliccaMaRilascia;
begin
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin FLog := FLog + 'release;'; end);
  FSurface.OnMouseClick(procedure(A: TXcomAction) begin FLog := FLog + 'click;'; end);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseDown, 15, 15);
  Send(ekMouseMotion, 100, 100);
  Send(ekMouseUp, 100, 100);
  Assert.AreEqual('release;', FLog);
end;

procedure TTestXcomInteractiveSurface.UnGestoreDiUnSoloPulsanteNonRispondeAGliAltri;
begin
  FSurface.OnMouseClick(procedure(A: TXcomAction) begin FLog := FLog + 'left;'; end, XCOM_BUTTON_LEFT);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseDown, 15, 15, XCOM_BUTTON_RIGHT);
  Send(ekMouseUp, 15, 15, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('', FLog);
  Send(ekMouseDown, 15, 15, XCOM_BUTTON_LEFT);
  Send(ekMouseUp, 15, 15, XCOM_BUTTON_LEFT);
  Assert.AreEqual('left;', FLog);
end;

procedure TTestXcomInteractiveSurface.UnGestoreDiTuttiIPulsantiRispondeAQualunque;
begin
  FSurface.OnMousePress(procedure(A: TXcomAction) begin FLog := FLog + 'all;'; end, 0);
  FSurface.OnMousePress(procedure(A: TXcomAction) begin FLog := FLog + 'one;'; end, XCOM_BUTTON_RIGHT);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseDown, 15, 15, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('all;one;', FLog);
end;

procedure TTestXcomInteractiveSurface.IlTastoChiamaIlGestore;
begin
  FSurface.OnKeyboardPress(procedure(A: TXcomAction) begin FLog := FLog + 'k;'; end, 65);
  Send(ekKeyDown, 0, 0, 0, 65);
  Send(ekKeyDown, 0, 0, 0, 66);
  Assert.AreEqual('k;', FLog);
end;

procedure TTestXcomInteractiveSurface.ConUnModificatoreIlTastoSpecificoNonScatta;
begin
  FSurface.OnKeyboardPress(procedure(A: TXcomAction) begin FLog := FLog + 'k;'; end, 65);
  Send(ekKeyDown, 0, 0, 0, 65, XCOM_KMOD_CTRL);
  Assert.AreEqual('', FLog);
end;

procedure TTestXcomInteractiveSurface.IlGestoreDiOgniTastoScattaSempre;
begin
  FSurface.OnKeyboardPress(procedure(A: TXcomAction) begin FLog := FLog + 'any;'; end);
  Send(ekKeyDown, 0, 0, 0, 65, XCOM_KMOD_CTRL);
  Send(ekKeyDown, 0, 0, 0, 66);
  Assert.AreEqual('any;any;', FLog);
end;

procedure TTestXcomInteractiveSurface.IlRilascioDelTastoChiamaIlGestoreDelRilascio;
begin
  FSurface.OnKeyboardRelease(procedure(A: TXcomAction) begin FLog := FLog + 'up;'; end, 13);
  Send(ekKeyUp, 0, 0, 0, 13);
  Assert.AreEqual('up;', FLog);
end;

procedure TTestXcomInteractiveSurface.SenzaFuocoITastiNonArrivano;
begin
  FSurface.OnKeyboardPress(procedure(A: TXcomAction) begin FLog := FLog + 'k;'; end, 65);
  FSurface.SetFocus(False);
  Assert.IsFalse(FSurface.IsFocused);
  Send(ekKeyDown, 0, 0, 0, 65);
  Assert.AreEqual('', FLog);
end;

procedure TTestXcomInteractiveSurface.UnaSuperficieNascostaNonRiceveEventi;
begin
  FSurface.OnMouseIn(procedure(A: TXcomAction) begin FLog := FLog + 'in;'; end);
  FSurface.Hidden := True;
  Send(ekMouseMotion, 15, 15);
  Assert.AreEqual('', FLog);
  FSurface.Hidden := False;
  FSurface.Visible := False;
  Send(ekMouseMotion, 15, 15);
  Assert.AreEqual('', FLog);
end;

procedure TTestXcomInteractiveSurface.RendereInvisibileSollevaIlPulsante;
begin
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin FLog := FLog + 'release;'; end);
  Send(ekMouseMotion, 15, 15);
  Send(ekMouseDown, 15, 15);
  FSurface.Visible := False;
  Assert.AreEqual('release;', FLog);
  Assert.IsFalse(FSurface.IsButtonPressed);
end;

procedure TTestXcomInteractiveSurface.UnpressRilasciaIlPulsante;
begin
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin FLog := FLog + 'release;'; end);
  FSurface.Unpress;
  Assert.AreEqual('', FLog);
  FSurface.SetButtonPressed(XCOM_BUTTON_LEFT, True);
  FSurface.Unpress;
  Assert.AreEqual('release;', FLog);
end;

procedure TTestXcomInteractiveSurface.IsButtonHandledVedeIGestori;
begin
  Assert.IsFalse(FSurface.IsButtonHandled(XCOM_BUTTON_LEFT));
  FSurface.OnMouseClick(procedure(A: TXcomAction) begin end, XCOM_BUTTON_RIGHT);
  Assert.IsFalse(FSurface.IsButtonHandled(XCOM_BUTTON_LEFT));
  Assert.IsTrue(FSurface.IsButtonHandled(XCOM_BUTTON_RIGHT));
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin end, 0);
  Assert.IsTrue(FSurface.IsButtonHandled(XCOM_BUTTON_LEFT));
end;

procedure TTestXcomInteractiveSurface.TogliereUnGestoreLoCancella;
begin
  FSurface.OnMouseClick(procedure(A: TXcomAction) begin end);
  Assert.IsTrue(FSurface.IsButtonHandled(XCOM_BUTTON_LEFT));
  FSurface.OnMouseClick(nil);
  Assert.IsFalse(FSurface.IsButtonHandled(XCOM_BUTTON_LEFT));
  FSurface.OnMousePress(procedure(A: TXcomAction) begin end);
  FSurface.OnMousePress(nil);
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin end);
  FSurface.OnMouseRelease(nil);
  FSurface.OnKeyboardPress(procedure(A: TXcomAction) begin end, 5);
  FSurface.OnKeyboardPress(nil, 5);
  FSurface.OnKeyboardRelease(procedure(A: TXcomAction) begin end, 5);
  FSurface.OnKeyboardRelease(nil, 5);
  Assert.IsFalse(FSurface.IsButtonHandled);
end;

procedure TTestXcomInteractiveSurface.IlTastoSconosciutoSiIgnora;
begin
  FSurface.OnKeyboardPress(procedure(A: TXcomAction) begin FLog := FLog + 'k;'; end, XCOM_KEY_UNKNOWN);
  FSurface.OnKeyboardRelease(procedure(A: TXcomAction) begin FLog := FLog + 'k;'; end, XCOM_KEY_UNKNOWN);
  Send(ekKeyDown, 0, 0, 0, 0);
  Send(ekKeyUp, 0, 0, 0, 0);
  Assert.AreEqual('', FLog);
end;

procedure TTestXcomInteractiveSurface.LaSuperficieListaPremeQuandoIlMouseEntraConIlPulsanteGiaGiu;
var
  LAction: TXcomAction;
  LEvent: TXcomInputEvent;
begin
  FSurface.SetListButton;
  FSurface.OnMousePress(procedure(A: TXcomAction) begin FLog := FLog + 'press;'; end);
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := 15;
  LEvent.Y := 15;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    LAction.ButtonMask := 1;
    FSurface.Handle(LAction);
  finally
    LAction.Free;
  end;
  Assert.AreEqual('press;', FLog);
end;

procedure TTestXcomInteractiveSurface.LaSuperficieListaRilasciaQuandoIlMouseEsce;
var
  LAction: TXcomAction;
  LEvent: TXcomInputEvent;
begin
  FSurface.SetListButton;
  FSurface.OnMouseRelease(procedure(A: TXcomAction) begin FLog := FLog + 'r;'; end, 0);
  Send(ekMouseMotion, 15, 15);
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := 100;
  LEvent.Y := 100;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    FSurface.Handle(LAction);
  finally
    LAction.Free;
  end;
  // one release for each of the five buttons
  Assert.AreEqual('r;r;r;r;r;', FLog);
end;

procedure TTestXcomInteractiveSurface.LeCoordinateDelMouseSonoQuelleDelGioco;
var
  LAction: TXcomAction;
  LEvent: TXcomInputEvent;
begin
  // a scale of 2: the window position 40,40 is the game position 20,20, inside the surface at 10,10 of 20 x 20
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := 40;
  LEvent.Y := 40;
  LAction := TXcomAction.Create(LEvent, 2.0, 2.0, 0, 0);
  try
    FSurface.OnMouseIn(procedure(A: TXcomAction) begin FLog := FLog + 'in;'; end);
    FSurface.Handle(LAction);
    Assert.AreEqual('in;', FLog);
    Assert.AreEqual(20.0, LAction.AbsoluteXMouse, 0.001);
    Assert.AreSame(TObject(FSurface), LAction.Sender);
  finally
    LAction.Free;
  end;
end;

{ TTestXcomScreen }

procedure TTestXcomScreen.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomScreen.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomScreen.LaScalaDuePerDueCopiaOgniPixelInUnQuadrato;
var
  LScreen: TXcomScreen;
begin
  LScreen := FWorld.Game.Screen;
  Assert.AreEqual(640, LScreen.Width);
  Assert.AreEqual(400, LScreen.Height);
  LScreen.GetSurface.SetPixel(0, 0, 7);
  LScreen.GetSurface.SetPixel(319, 199, 9);
  LScreen.Flip;
  Assert.AreEqual(7, Integer(FWorld.Pixel(0, 0)));
  Assert.AreEqual(7, Integer(FWorld.Pixel(1, 1)));
  Assert.AreEqual(0, Integer(FWorld.Pixel(2, 0)));
  Assert.AreEqual(9, Integer(FWorld.Pixel(638, 398)));
  Assert.AreEqual(9, Integer(FWorld.Pixel(639, 399)));
  Assert.AreEqual(2.0, LScreen.XScale, 0.0001);
  Assert.AreEqual(2.0, LScreen.YScale, 0.0001);
end;

procedure TTestXcomScreen.IlPaletteDifferitoArrivaAlDisplayConIlFlip;
var
  LColors: array[0..2] of TXcomColor;
begin
  LColors[0].Red := 1;
  LColors[1].Red := 22;
  LColors[1].Green := 33;
  LColors[2].Red := 3;
  FWorld.Game.Screen.SetPalette(@LColors[0], 10, 3);
  FWorld.Game.Screen.Flip;
  Assert.AreEqual(22, Integer(FWorld.Device.Palette[11].Red));
  Assert.AreEqual(33, Integer(FWorld.Device.Palette[11].Green));
  Assert.AreEqual(22, Integer(FWorld.Game.Screen.Palette^[11].Red));
  Assert.AreEqual(22, Integer(FWorld.Game.Screen.GetSurface.Palette.Colors[11].Red));
end;

procedure TTestXcomScreen.ConLaProporzioneMantenutaNascenoLeFasceLaterali;
var
  LOptions: TXcomOptions;
begin
  LOptions := FWorld.Game.Options;
  LOptions.DisplayWidth := 800;
  LOptions.DisplayHeight := 400;
  FWorld.Game.Screen.ResetDisplay;
  FWorld.Game.Screen.GetSurface.SetPixel(0, 0, 5);
  FWorld.Game.Screen.Flip;
  // the picture is 640 wide in the middle of 800: 80 pixels of band on each side
  Assert.AreEqual(0, Integer(FWorld.Pixel(79, 0)));
  Assert.AreEqual(5, Integer(FWorld.Pixel(80, 0)));
  Assert.AreEqual(2.0, FWorld.Game.Screen.YScale, 0.0001);
end;

procedure TTestXcomScreen.ConLaProporzioneMantenutaNascenoLeFasceInAltoEInBasso;
begin
  FWorld.Game.Options.DisplayWidth := 640;
  FWorld.Game.Options.DisplayHeight := 600;
  FWorld.Game.Screen.ResetDisplay;
  FWorld.Game.Screen.GetSurface.SetPixel(0, 0, 5);
  FWorld.Game.Screen.Flip;
  // 640 x 400 of picture centered in 600: 100 pixels of band above
  Assert.AreEqual(0, Integer(FWorld.Pixel(0, 99)));
  Assert.AreEqual(5, Integer(FWorld.Pixel(0, 100)));
end;

procedure TTestXcomScreen.IlCursoreNelleFasceCambiaLaScala;
begin
  FWorld.Game.Options.DisplayWidth := 800;
  FWorld.Game.Options.DisplayHeight := 400;
  FWorld.Game.Options.CursorInBlackBandsInWindow := True;
  FWorld.Game.Screen.ResetDisplay;
  Assert.AreEqual(2.0, FWorld.Game.Screen.XScale, 0.0001);
  Assert.AreEqual(80, FWorld.Game.Screen.CursorLeftBlackBand);
  FWorld.Game.Options.CursorInBlackBandsInWindow := False;
  FWorld.Game.Screen.ResetDisplay;
  Assert.AreEqual(2.5, FWorld.Game.Screen.XScale, 0.0001);
  Assert.AreEqual(0, FWorld.Game.Screen.CursorLeftBlackBand);
end;

procedure TTestXcomScreen.DXeDYCentranoLoSchermoOriginale;
begin
  Assert.AreEqual(0, FWorld.Game.Screen.DX);
  Assert.AreEqual(0, FWorld.Game.Screen.DY);
  FWorld.Game.Options.BaseXResolution := 640;
  FWorld.Game.Options.BaseYResolution := 400;
  FWorld.Game.Screen.ResetDisplay;
  Assert.AreEqual(160, FWorld.Game.Screen.DX);
  Assert.AreEqual(100, FWorld.Game.Screen.DY);
end;

procedure TTestXcomScreen.UpdateScaleDaLeDimensioniDelleOpzioni;
var
  LWidth: Integer;
  LHeight: Integer;
  LOptions: TXcomOptions;
begin
  LOptions := FWorld.Game.Options;
  LOptions.DisplayWidth := 1000;
  LOptions.DisplayHeight := 600;
  TXcomScreen.UpdateScale(LOptions, 0, LWidth, LHeight, False);
  Assert.AreEqual(320, LWidth);
  Assert.AreEqual(200, LHeight);
  TXcomScreen.UpdateScale(LOptions, 1, LWidth, LHeight, False);
  Assert.AreEqual(480, LWidth);
  Assert.AreEqual(300, LHeight);
  TXcomScreen.UpdateScale(LOptions, 2, LWidth, LHeight, False);
  Assert.AreEqual(640, LWidth);
  Assert.AreEqual(400, LHeight);
  TXcomScreen.UpdateScale(LOptions, 3, LWidth, LHeight, False);
  Assert.AreEqual(333, LWidth);
  Assert.AreEqual(200, LHeight);
  TXcomScreen.UpdateScale(LOptions, 4, LWidth, LHeight, False);
  Assert.AreEqual(500, LWidth);
  Assert.AreEqual(300, LHeight);
  TXcomScreen.UpdateScale(LOptions, 5, LWidth, LHeight, False);
  Assert.AreEqual(1000, LWidth);
  Assert.AreEqual(600, LHeight);
  LOptions.NonSquarePixelRatio := True;
  TXcomScreen.UpdateScale(LOptions, 5, LWidth, LHeight, False);
  Assert.AreEqual(500, LHeight);
end;

procedure TTestXcomScreen.UpdateScaleNonCambiaLaBaseSeNonSiChiede;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  TXcomScreen.UpdateScale(FWorld.Game.Options, 2, LWidth, LHeight, False);
  Assert.AreEqual(320, FWorld.Game.Options.BaseXResolution);
  TXcomScreen.UpdateScale(FWorld.Game.Options, 2, LWidth, LHeight, True);
  Assert.AreEqual(640, FWorld.Game.Options.BaseXResolution);
  Assert.AreEqual(400, FWorld.Game.Options.BaseYResolution);
end;

procedure TTestXcomScreen.ClearAzzeraLaBase;
begin
  FWorld.Game.Screen.GetSurface.SetPixel(4, 4, 3);
  FWorld.Game.Screen.Clear;
  Assert.AreEqual(0, Integer(FWorld.Game.Screen.GetSurface.GetPixel(4, 4)));
end;

procedure TTestXcomScreen.IlTastoDelloScreenshotSiRicordaUnaSolaVolta;
var
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := XCOM_KEY_F12;
  LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
  try
    FWorld.Game.Screen.Handle(LAction);
  finally
    LAction.Free;
  end;
  Assert.IsTrue(FWorld.Game.Screen.TakeScreenshotRequest);
  Assert.IsFalse(FWorld.Game.Screen.TakeScreenshotRequest);
end;

procedure TTestXcomScreen.ResetDisplayAdattaLaBaseALleOpzioni;
begin
  FWorld.Game.Options.BaseXResolution := 400;
  FWorld.Game.Options.BaseYResolution := 300;
  FWorld.Game.Screen.ResetDisplay;
  Assert.AreEqual(400, FWorld.Game.Screen.GetSurface.Width);
  Assert.AreEqual(300, FWorld.Game.Screen.GetSurface.Height);
end;

{ TTestXcomGame }

procedure TTestXcomGame.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomGame.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomGame.SenzaStatiIlGiocoEsce;
begin
  FWorld.Game.RunFrame;
  Assert.IsTrue(FWorld.Game.IsQuitting);
end;

procedure TTestXcomGame.LoStatoInCimaRiceveInitEThink;
var
  LState: TProbeState;
begin
  LState := TProbeState.Create(FWorld.Game);
  FWorld.Game.SetState(LState);
  FWorld.Wait(50);
  Assert.AreEqual(1, LState.Inits);
  Assert.AreEqual(50, LState.Thinks);
  Assert.AreEqual(50, LState.Probe.Thinks);
  Assert.IsTrue(FWorld.Game.IsState(LState));
end;

procedure TTestXcomGame.DisegnaCirca60FotogrammiAlSecondo;
begin
  FWorld.Game.SetState(TProbeState.Create(FWorld.Game));
  FWorld.Wait(1000);
  Assert.IsTrue((FWorld.Game.Frames >= 58) and (FWorld.Game.Frames <= 62), IntToStr(FWorld.Game.Frames));
  Assert.AreEqual(FWorld.Game.Frames, FWorld.Device.Presented);
end;

procedure TTestXcomGame.PushEPopCambianoLoStatoInCima;
var
  LFirst: TProbeState;
  LSecond: TProbeState;
begin
  LFirst := TProbeState.Create(FWorld.Game);
  LSecond := TProbeState.Create(FWorld.Game);
  FWorld.Game.PushState(LFirst);
  FWorld.Game.PushState(LSecond);
  Assert.IsTrue(FWorld.Game.IsState(LSecond));
  Assert.IsFalse(FWorld.Game.IsState(LFirst));
  FWorld.Wait(10);
  Assert.AreEqual(1, LSecond.Inits);
  Assert.AreEqual(0, LFirst.Inits);
  FWorld.Game.PopState;
  FWorld.Wait(10);
  Assert.IsTrue(FWorld.Game.IsState(LFirst));
  Assert.AreEqual(1, LFirst.Inits);
end;

procedure TTestXcomGame.SetStateSostituisceTuttiGliStati;
var
  LNew: TProbeState;
begin
  FWorld.Game.PushState(TProbeState.Create(FWorld.Game));
  FWorld.Game.PushState(TProbeState.Create(FWorld.Game));
  LNew := TProbeState.Create(FWorld.Game);
  FWorld.Game.SetState(LNew);
  FWorld.Wait(5);
  Assert.IsTrue(FWorld.Game.IsState(LNew));
  FWorld.Game.PopState;
  FWorld.Wait(5);
  Assert.IsTrue(FWorld.Game.IsQuitting);
end;

procedure TTestXcomGame.UnEventoDiUscitaFermaIlGioco;
begin
  FWorld.Game.SetState(TProbeState.Create(FWorld.Game));
  FWorld.Events.Enqueue(TXcomInputEvent.Make(ekQuit));
  FWorld.Wait(5);
  Assert.IsTrue(FWorld.Game.IsQuitting);
end;

procedure TTestXcomGame.IlTastoScreenshotChiamaIlGestore;
var
  LEvent: TXcomInputEvent;
  LCalls: Integer;
begin
  LCalls := 0;
  FWorld.Game.OnScreenshot :=
    procedure(AScreen: TXcomScreen)
    begin
      Inc(LCalls);
    end;
  FWorld.Game.SetState(TProbeState.Create(FWorld.Game));
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := XCOM_KEY_F12;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  Assert.AreEqual(1, LCalls);
end;

procedure TTestXcomGame.DisegnaDallUltimoStatoATuttoSchermo;
var
  LBottom: TProbeState;
  LWindow: TProbeState;
  LTop: TProbeState;
begin
  LBottom := TProbeState.Create(FWorld.Game);
  LWindow := TProbeState.Create(FWorld.Game);
  LTop := TProbeState.Create(FWorld.Game);
  LWindow.ToggleScreen;
  LTop.ToggleScreen;
  FWorld.Game.PushState(LBottom);
  FWorld.Game.PushState(LWindow);
  FWorld.Game.PushState(LTop);
  FWorld.Wait(40);
  // the two above the full screen state are windows: all three are drawn
  Assert.IsTrue(LBottom.Blits > 0);
  Assert.IsTrue(LWindow.Blits > 0);
  Assert.IsTrue(LTop.Blits > 0);
  LWindow.ToggleScreen;
  LBottom.Blits := 0;
  LWindow.Blits := 0;
  FWorld.Wait(40);
  Assert.AreEqual(0, LBottom.Blits);
  Assert.IsTrue(LWindow.Blits > 0);
end;

procedure TTestXcomGame.UnStatoPoppatoSiLiberaAlTurnoDopo;
begin
  FWorld.Game.PushState(TProbeState.Create(FWorld.Game));
  FWorld.Game.PushState(TProbeState.Create(FWorld.Game));
  FWorld.Wait(5);
  FWorld.Game.PopState;
  FWorld.Wait(5);
  Assert.IsFalse(FWorld.Game.IsQuitting);
end;

procedure TTestXcomGame.LeAzioniDelMouseArrivanoSoloSeIlMouseEAttivo;
var
  LState: TProbeState;
  LEvent: TXcomInputEvent;
begin
  LState := TProbeState.Create(FWorld.Game);
  FWorld.Game.SetState(LState);
  FWorld.Wait(5);
  LState.Handled := 0;
  FWorld.Game.SetMouseActive(False);
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  Assert.AreEqual(0, LState.Handled);
  FWorld.Game.SetMouseActive(True);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  Assert.AreEqual(1, LState.Handled);
end;

procedure TTestXcomGame.AdoptDataCambiaLaLingua;
begin
  Assert.AreEqual('en-US', FWorld.Game.Language.LanguageId);
  FWorld.Game.AdoptData(FWorld.Game.Resources, TXcomLanguage.Create('de', twAuto, nil, nil));
  Assert.AreEqual('de', FWorld.Game.Language.LanguageId);
  Assert.AreEqual('de', FWorld.Game.Options.Language);
end;

procedure TTestXcomGame.IlCursoreSegueIlMouse;
var
  LEvent: TXcomInputEvent;
begin
  FWorld.Game.SetState(TProbeState.Create(FWorld.Game));
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := 100;
  LEvent.Y := 60;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  Assert.AreEqual(50, FWorld.Game.Cursor.X);
  Assert.AreEqual(30, FWorld.Game.Cursor.Y);
end;

{ TTestXcomState }

procedure TTestXcomState.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomState.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomState.AddDaLaPaletteDelloStatoALaSuperficie;
var
  LState: TProbeState;
  LSurface: TProbeSurface;
  LColors: array[0..0] of TXcomColor;
begin
  LState := TProbeState.Create(FWorld.Game);
  FWorld.Game.SetState(LState);
  LColors[0].Red := 77;
  LState.SetPalette(@LColors[0], 5, 1, False);
  Assert.AreEqual(77, Integer(LState.Palette^[5].Red));
  LSurface := TProbeSurface.Create(4, 4);
  LState.Add(LSurface);
  Assert.AreEqual(77, Integer(LSurface.Palette.Colors[5].Red));
end;

procedure TTestXcomState.IlColoreDellInterfacciaVieneApplicatoAlLElemento;
var
  LRule: TXcomRuleInterface;
  LState: TProbeState;
  LFrame: TProbeSurface;
begin
  LRule := FWorld.Resources.GetInterface('testMenu');
  LRule.Load(TTestWorld.Parse(
    'elements:'#10'  - id: box'#10'    size: [30, 40]'#10'    pos: [5, 6]'#10'    color: 9'#10));
  LState := TProbeState.Create(FWorld.Game);
  FWorld.Game.SetState(LState);
  LFrame := TProbeSurface.Create(4, 4, 1, 1);
  LState.Add(LFrame, 'box', 'testMenu', LFrame);
  Assert.AreEqual(30, LFrame.Width);
  Assert.AreEqual(40, LFrame.Height);
  Assert.AreEqual(6, LFrame.X);
  Assert.AreEqual(7, LFrame.Y);
end;

procedure TTestXcomState.SetInterfaceCaricaLaPaletteELoSfondoDelleFinestre;
var
  LState: TProbeState;
begin
  LState := TProbeState.Create(FWorld.Game);
  FWorld.Game.SetState(LState);
  LState.SetInterface('testMenu');
  Assert.AreEqual(3, Integer(LState.Palette^[3].Red));
  Assert.AreEqual(200, Integer(LState.Palette^[200].Red));
end;

procedure TTestXcomState.TrDaLeStringhe;
var
  LState: TProbeState;
begin
  LState := TProbeState.Create(FWorld.Game);
  Assert.AreEqual('STR_UNKNOWN', LState.Tr('STR_UNKNOWN').Text);
  Assert.AreEqual('STR_UNKNOWN', LState.Tr('STR_UNKNOWN', 4).Text);
  LState.Free;
end;

procedure TTestXcomState.CenterAllSurfacesAggiungeIlCentro;
var
  LState: TProbeState;
begin
  FWorld.Game.Options.BaseXResolution := 640;
  FWorld.Game.Options.BaseYResolution := 400;
  FWorld.Game.Screen.ResetDisplay;
  LState := TProbeState.Create(FWorld.Game);
  LState.Probe.X := 10;
  LState.CenterAllSurfaces;
  Assert.AreEqual(170, LState.Probe.X);
  Assert.AreEqual(100, LState.Probe.Y);
  LState.LowerAllSurfaces;
  Assert.AreEqual(150, LState.Probe.Y);
  LState.Free;
end;

procedure TTestXcomState.HideAllEShowAll;
var
  LState: TProbeState;
begin
  LState := TProbeState.Create(FWorld.Game);
  LState.HideAll;
  Assert.IsTrue(LState.Probe.Hidden);
  LState.ShowAll;
  Assert.IsFalse(LState.Probe.Hidden);
  LState.Free;
end;

procedure TTestXcomState.ILStatoModaleRiceveGliEventiDaSolo;
var
  LState: TProbeState;
  LModal: TXcomInteractiveSurface;
  LOther: TXcomInteractiveSurface;
  LLog: string;
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  LState := TProbeState.Create(FWorld.Game);
  LModal := TXcomInteractiveSurface.Create(10, 10, 100, 100);
  LOther := TXcomInteractiveSurface.Create(10, 10, 0, 0);
  try
    LState.Add(LOther);
    LOther.OnMouseIn(procedure(A: TXcomAction) begin LLog := LLog + 'other;'; end);
    LModal.OnMouseIn(procedure(A: TXcomAction) begin LLog := LLog + 'modal;'; end);
    LState.SetModal(LModal);
    LEvent := TXcomInputEvent.Make(ekMouseMotion);
    LEvent.X := 3;
    LEvent.Y := 3;
    LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
    try
      LState.Handle(LAction);
    finally
      LAction.Free;
    end;
    Assert.AreEqual('', LLog);
    LState.SetModal(nil);
    LAction := TXcomAction.Create(LEvent, 1.0, 1.0, 0, 0);
    try
      LState.Handle(LAction);
    finally
      LAction.Free;
    end;
    Assert.AreEqual('other;', LLog);
  finally
    LModal.Free;
    LState.Free;
  end;
end;

procedure TTestXcomState.ResizeSpostaLeSuperfici;
var
  LState: TProbeState;
  LDX: Integer;
  LDY: Integer;
begin
  LState := TProbeState.Create(FWorld.Game);
  LDX := 20;
  LDY := 10;
  LState.Resize(LDX, LDY);
  Assert.AreEqual(10, LState.Probe.X);
  Assert.AreEqual(5, LState.Probe.Y);
  LState.Free;
end;

procedure TTestXcomState.SetPaletteDaNomeCopiaIBlocchiDiBackpals;
var
  LState: TProbeState;
begin
  LState := TProbeState.Create(FWorld.Game);
  LState.SetPalette('PAL_GEOSCAPE', 2);
  // the block 2 of the back palettes (the color 32) goes to the 16 colors at 224
  Assert.AreEqual(255 - 32, Integer(LState.Palette^[224].Red));
  Assert.AreEqual(255 - 47, Integer(LState.Palette^[239].Red));
  Assert.AreEqual(5, Integer(LState.Palette^[5].Red));
  LState.Free;
end;

procedure TTestXcomState.LoStatoDiUnoSchermoEUnoSchermo;
var
  LState: TProbeState;
begin
  LState := TProbeState.Create(FWorld.Game);
  Assert.IsTrue(LState.IsScreen);
  LState.ToggleScreen;
  Assert.IsFalse(LState.IsScreen);
  LState.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomInteractiveSurface);
  TDUnitX.RegisterTestFixture(TTestXcomScreen);
  TDUnitX.RegisterTestFixture(TTestXcomGame);
  TDUnitX.RegisterTestFixture(TTestXcomState);

end.
