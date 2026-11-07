{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the view and its navigation      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.View;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Automap.Types, DelphiDoom.Automap.Intf;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapView = class(TObject)
  private
    FView: IAutomapView;
    FNavigator: IAutomapNavigator;
    FPlayerX: Integer;
    FPlayerY: Integer;
    procedure FitLevel(const AMinX, AMinY, AMaxX, AMaxY: Integer);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbePartireSeguendoIlGiocatoreConLaScalaIniziale;
    [Test]
    procedure DovrebbeTenereLaCornice;
    [Test]
    procedure DovrebbeDareUnaCopiaDellaFinestra;
    [Test]
    procedure DovrebbeTrovareLaScalaMinimaDalLivello;
    [Test]
    procedure DovrebbeTrovareLaScalaMassimaDalRaggioDelGiocatore;
    [Test]
    procedure DovrebbeContareIlPrimoVerticeNelMassimoDelLivello;
    [Test]
    procedure DovrebbeContareUnVerticeCheDiventaMinimoENelloStessoTempoMassimo;
    [Test]
    procedure DovrebbeLeggereVerticiConUnPassoDiverso;
    [Test]
    procedure DovrebbeIniziareLaScalaDaUnSettimoDellaMinima;
    [Test]
    procedure DovrebbeUsareLaScalaMinimaSeLaInizialeEOltreIlMassimo;
    [Test]
    procedure DovrebbeCentrareLaFinestraSulGiocatoreAllAvvio;
    [Test]
    procedure DovrebbeLasciareLaFinestraSeNonCeIlGiocatore;
    [Test]
    procedure DovrebbeFermarsiAlLimiteDelLivelloQuandoSiSposta;
    [Test]
    procedure DovrebbeSmettereDiSeguireIlGiocatoreQuandoSiSposta;
    [Test]
    procedure DovrebbeSeguireIlGiocatoreAlTic;
    [Test]
    procedure DovrebbeNonSpostareDueVolteLaFinestraPerLoStessoPunto;
    [Test]
    procedure DovrebbeSpostareDiNuovoDopoAverDimenticatoIlPunto;
    [Test]
    procedure DovrebbeIngrandireFinoAlLimiteEFermarsi;
    [Test]
    procedure DovrebbeRimpicciolireFinoAlLimiteEFermarsi;
    [Test]
    procedure DovrebbeMostrareTuttoIlLivelloConMinOut;
    [Test]
    procedure DovrebbeAvvicinarsiAlMassimoConMaxOut;
    [Test]
    procedure DovrebbeRipristinareLaFinestraSalvata;
    [Test]
    procedure DovrebbeRipristinareCentratoSulGiocatoreSeLoSegue;
    [Test]
    procedure DovrebbeCentrareSulGiocatoreSenzaToccareLAngoloInAlto;
    [Test]
    procedure DovrebbeRitagliareUnaLineaConLaFinestra;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath, DelphiDoom.Automap.Factory;

const
  FRAME_WIDTH = 320;
  FRAME_HEIGHT = 168;

{ TTestAutomapView }

procedure TTestAutomapView.Setup;
begin
  TAutomapFactory.CreateView(FView, FNavigator);
  FView.SetFrame(0, 0, FRAME_WIDTH, FRAME_HEIGHT);
  FPlayerX := 500 * FIXED_ONE;
  FPlayerY := 300 * FIXED_ONE;
end;

// A level whose vertices are the corners of a box, in units of the level
procedure TTestAutomapView.FitLevel(const AMinX, AMinY, AMaxX, AMaxY: Integer);
var
  LVertices: TArray<TAutomapPoint>;
begin
  SetLength(LVertices, 4);
  LVertices[0].X := (AMinX + AMaxX) div 2 * FIXED_ONE;
  LVertices[0].Y := (AMinY + AMaxY) div 2 * FIXED_ONE;
  LVertices[1].X := AMaxX * FIXED_ONE;
  LVertices[1].Y := AMaxY * FIXED_ONE;
  LVertices[2].X := AMinX * FIXED_ONE;
  LVertices[2].Y := AMinY * FIXED_ONE;
  LVertices[3].X := LVertices[0].X;
  LVertices[3].Y := LVertices[0].Y;
  FNavigator.FitToVertices(@LVertices[0], Length(LVertices), SizeOf(TAutomapPoint));
end;

procedure TTestAutomapView.DovrebbePartireSeguendoIlGiocatoreConLaScalaIniziale;
begin
  Assert.IsTrue(FNavigator.FollowPlayer);
  Assert.AreEqual(AUTOMAP_INITIAL_SCALE, FView.Window.ScaleMapToFrame);
  Assert.AreEqual(FIXED_ONE, FNavigator.ZoomMapToFrame);
  Assert.AreEqual(FIXED_ONE, FNavigator.ZoomFrameToMap);
end;

procedure TTestAutomapView.DovrebbeTenereLaCornice;
begin
  FView.SetFrame(4, 6, 640, 336);
  Assert.AreEqual(4, FView.Window.FrameX);
  Assert.AreEqual(6, FView.Window.FrameY);
  Assert.AreEqual(640, FView.Window.FrameWidth);
  Assert.AreEqual(336, FView.Window.FrameHeight);
end;

procedure TTestAutomapView.DovrebbeDareUnaCopiaDellaFinestra;
var
  LWindow: TAutomapWindow;
begin
  LWindow := FView.Window;
  LWindow.FrameWidth := 1;
  Assert.AreEqual(FRAME_WIDTH, FView.Window.FrameWidth);
end;

procedure TTestAutomapView.DovrebbeTrovareLaScalaMinimaDalLivello;
var
  LScaleX: TFixed;
  LScaleY: TFixed;
begin
  FitLevel(0, 0, 1000, 600);
  // the level is 1000 x 600 units, that is 16000 x 9600 pixels of 1/16 unit
  LScaleX := TFixedMath.Divide(FRAME_WIDTH * FIXED_ONE, 1000 * 4096);
  LScaleY := TFixedMath.Divide(FRAME_HEIGHT * FIXED_ONE, 600 * 4096);
  if LScaleX < LScaleY then
    Assert.AreEqual(LScaleX, FNavigator.MinScale)
  else
    Assert.AreEqual(LScaleY, FNavigator.MinScale);
end;

procedure TTestAutomapView.DovrebbeTrovareLaScalaMassimaDalRaggioDelGiocatore;
begin
  FitLevel(0, 0, 1000, 600);
  Assert.AreEqual(TFixedMath.Divide(FRAME_HEIGHT * FIXED_ONE, 2 * AUTOMAP_PLAYERRADIUS),
    FNavigator.MaxScale);
end;

procedure TTestAutomapView.DovrebbeContareIlPrimoVerticeNelMassimoDelLivello;
var
  LVertices: TArray<TAutomapPoint>;
begin
  // regressione: il vecchio AM_findMinMaxBoundaries non guardava il massimo del primo vertice
  // (e di un vertice che diventava minimo), quindi qui vedeva un livello largo 300 e non 500
  SetLength(LVertices, 3);
  LVertices[0].X := 1000 * FIXED_ONE;
  LVertices[0].Y := 0;
  LVertices[1].X := 500 * FIXED_ONE;
  LVertices[1].Y := 0;
  LVertices[2].X := 800 * FIXED_ONE;
  LVertices[2].Y := 100 * FIXED_ONE;
  FNavigator.FitToVertices(@LVertices[0], Length(LVertices), SizeOf(TAutomapPoint));
  Assert.AreEqual(
    TFixedMath.Divide(FRAME_WIDTH * FIXED_ONE, 500 * 4096), FNavigator.MinScale);
end;

procedure TTestAutomapView.DovrebbeContareUnVerticeCheDiventaMinimoENelloStessoTempoMassimo;
var
  LVertices: TArray<TAutomapPoint>;
begin
  // regressione: una serie di vertici sempre piu' a sinistra non aveva mai un massimo
  SetLength(LVertices, 3);
  LVertices[0].X := 900 * FIXED_ONE;
  LVertices[0].Y := 400 * FIXED_ONE;
  LVertices[1].X := 600 * FIXED_ONE;
  LVertices[1].Y := 300 * FIXED_ONE;
  LVertices[2].X := 300 * FIXED_ONE;
  LVertices[2].Y := 0;
  FNavigator.FitToVertices(@LVertices[0], Length(LVertices), SizeOf(TAutomapPoint));
  Assert.AreEqual(
    TFixedMath.Divide(FRAME_HEIGHT * FIXED_ONE, 400 * 4096), FNavigator.MinScale);
end;

procedure TTestAutomapView.DovrebbeLeggereVerticiConUnPassoDiverso;
type
  // as vertex_t of the engine: x and y, then two more fields
  TWideVertex = record
    X: Integer;
    Y: Integer;
    First: Integer;
    Second: Integer;
  end;
var
  LVertices: array[0..2] of TWideVertex;
begin
  LVertices[0].X := 500 * FIXED_ONE;
  LVertices[0].Y := 0;
  LVertices[1].X := 1500 * FIXED_ONE;
  LVertices[1].Y := 100 * FIXED_ONE;
  LVertices[2].X := 1000 * FIXED_ONE;
  LVertices[2].Y := 50 * FIXED_ONE;
  FNavigator.FitToVertices(@LVertices[0], Length(LVertices), SizeOf(TWideVertex));
  Assert.AreEqual(
    TFixedMath.Divide(FRAME_WIDTH * FIXED_ONE, 1000 * 4096), FNavigator.MinScale);
end;

procedure TTestAutomapView.DovrebbeIniziareLaScalaDaUnSettimoDellaMinima;
var
  LExpected: TFixed;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  LExpected := TFixedMath.Divide(FNavigator.MinScale, Trunc(0.7 * FIXED_ONE));
  Assert.IsTrue(LExpected <= FNavigator.MaxScale);
  Assert.AreEqual(LExpected, FView.Window.ScaleMapToFrame);
  Assert.AreEqual(TFixedMath.Divide(FIXED_ONE, LExpected), FView.Window.ScaleFrameToMap);
end;

procedure TTestAutomapView.DovrebbeUsareLaScalaMinimaSeLaInizialeEOltreIlMassimo;
begin
  // a level so small that the fitted scale passes the maximum one: the scale is the minimum
  FitLevel(0, 0, 10, 10);
  FNavigator.InitializeScale;
  Assert.AreEqual(FNavigator.MinScale, FView.Window.ScaleMapToFrame);
end;

procedure TTestAutomapView.DovrebbeCentrareLaFinestraSulGiocatoreAllAvvio;
var
  LWindow: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  LWindow := FView.Window;
  Assert.AreEqual(FView.FrameToMap(FRAME_WIDTH), LWindow.MapWidth);
  Assert.AreEqual(FView.FrameToMap(FRAME_HEIGHT), LWindow.MapHeight);
  Assert.AreEqual(FPlayerX div 16 - LWindow.MapWidth div 2, LWindow.MapX);
  Assert.AreEqual(FPlayerY div 16 - LWindow.MapHeight div 2, LWindow.MapY);
  Assert.AreEqual(LWindow.MapX + LWindow.MapWidth, LWindow.MapX2);
  Assert.AreEqual(LWindow.MapY + LWindow.MapHeight, LWindow.MapY2);
end;

procedure TTestAutomapView.DovrebbeLasciareLaFinestraSeNonCeIlGiocatore;
var
  LBefore: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  LBefore := FView.Window;
  FNavigator.StartWindow(False, 0, 0);
  Assert.AreEqual(LBefore.MapX, FView.Window.MapX);
  Assert.AreEqual(LBefore.MapY, FView.Window.MapY);
end;

procedure TTestAutomapView.DovrebbeFermarsiAlLimiteDelLivelloQuandoSiSposta;
var
  LStep: Integer;
  LWindow: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.PanX := FView.FrameToMap(4);
  for LStep := 1 to 2000 do
    FNavigator.Tick(FPlayerX, FPlayerY);
  LWindow := FView.Window;
  // the center of the window never goes past the right edge of the level
  Assert.IsTrue(LWindow.MapX + LWindow.MapWidth div 2 <= 1000 * 4096);
  Assert.IsTrue(LWindow.MapX + LWindow.MapWidth div 2 >= 1000 * 4096 - 4 * FView.FrameToMap(4));
end;

procedure TTestAutomapView.DovrebbeSmettereDiSeguireIlGiocatoreQuandoSiSposta;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.PanY := FView.FrameToMap(4);
  FNavigator.Tick(FPlayerX, FPlayerY);
  Assert.IsFalse(FNavigator.FollowPlayer);
end;

procedure TTestAutomapView.DovrebbeSeguireIlGiocatoreAlTic;
var
  LWindow: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, 0, 0);
  FNavigator.Tick(FPlayerX, FPlayerY);
  LWindow := FView.Window;
  // the center is the player, on the pixels of the frame buffer
  Assert.AreEqual(
    FView.FrameToMap(FView.MapToFrame(FPlayerX div 16)) - LWindow.MapWidth div 2, LWindow.MapX);
  Assert.AreEqual(LWindow.MapX + LWindow.MapWidth, LWindow.MapX2);
end;

procedure TTestAutomapView.DovrebbeNonSpostareDueVolteLaFinestraPerLoStessoPunto;
var
  LAfterFirst: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, 0, 0);
  FNavigator.Tick(FPlayerX, FPlayerY);
  LAfterFirst := FView.Window;
  // somebody moves the window (the drawing does) and the next tic leaves it as it is
  FNavigator.CenterOnPlayer(0, 0);
  FNavigator.Tick(FPlayerX, FPlayerY);
  Assert.AreNotEqual(LAfterFirst.MapX, FView.Window.MapX);
  Assert.AreEqual(0 div 16 - LAfterFirst.MapWidth div 2, FView.Window.MapX);
end;

procedure TTestAutomapView.DovrebbeSpostareDiNuovoDopoAverDimenticatoIlPunto;
var
  LAfterFirst: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, 0, 0);
  FNavigator.Tick(FPlayerX, FPlayerY);
  LAfterFirst := FView.Window;
  FNavigator.CenterOnPlayer(0, 0);
  FNavigator.ForgetPlayerLocation;
  FNavigator.Tick(FPlayerX, FPlayerY);
  Assert.AreEqual(LAfterFirst.MapX, FView.Window.MapX);
end;

procedure TTestAutomapView.DovrebbeIngrandireFinoAlLimiteEFermarsi;
var
  LStep: Integer;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.SetZoom(AUTOMAP_ZOOM_IN, AUTOMAP_ZOOM_OUT);
  for LStep := 1 to 2000 do
    FNavigator.Tick(FPlayerX, FPlayerY);
  Assert.AreEqual(FNavigator.MaxScale, FView.Window.ScaleMapToFrame);
end;

procedure TTestAutomapView.DovrebbeRimpicciolireFinoAlLimiteEFermarsi;
var
  LStep: Integer;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.SetZoom(AUTOMAP_ZOOM_OUT, AUTOMAP_ZOOM_IN);
  for LStep := 1 to 2000 do
    FNavigator.Tick(FPlayerX, FPlayerY);
  Assert.AreEqual(FNavigator.MinScale, FView.Window.ScaleMapToFrame);
end;

procedure TTestAutomapView.DovrebbeMostrareTuttoIlLivelloConMinOut;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.MinOutWindowScale;
  Assert.AreEqual(FNavigator.MinScale, FView.Window.ScaleMapToFrame);
  Assert.AreEqual(TFixedMath.Divide(FIXED_ONE, FNavigator.MinScale), FView.Window.ScaleFrameToMap);
  Assert.AreEqual(FView.FrameToMap(FRAME_WIDTH), FView.Window.MapWidth);
end;

procedure TTestAutomapView.DovrebbeAvvicinarsiAlMassimoConMaxOut;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.MaxOutWindowScale;
  Assert.AreEqual(FNavigator.MaxScale, FView.Window.ScaleMapToFrame);
end;

procedure TTestAutomapView.DovrebbeRipristinareLaFinestraSalvata;
var
  LSaved: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.FollowPlayer := False;
  FNavigator.SaveScaleAndLocation;
  LSaved := FView.Window;
  FNavigator.MinOutWindowScale;
  Assert.AreNotEqual(LSaved.MapWidth, FView.Window.MapWidth);
  FNavigator.RestoreScaleAndLocation(FPlayerX, FPlayerY);
  Assert.AreEqual(LSaved.MapX, FView.Window.MapX);
  Assert.AreEqual(LSaved.MapY, FView.Window.MapY);
  Assert.AreEqual(LSaved.MapWidth, FView.Window.MapWidth);
  Assert.AreEqual(LSaved.MapHeight, FView.Window.MapHeight);
  Assert.AreEqual(TFixedMath.Divide(FRAME_WIDTH * FIXED_ONE, LSaved.MapWidth),
    FView.Window.ScaleMapToFrame);
end;

procedure TTestAutomapView.DovrebbeRipristinareCentratoSulGiocatoreSeLoSegue;
var
  LWindow: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  FNavigator.SaveScaleAndLocation;
  FNavigator.MinOutWindowScale;
  FNavigator.RestoreScaleAndLocation(FPlayerX + 16 * 4096, FPlayerY);
  LWindow := FView.Window;
  Assert.AreEqual((FPlayerX + 16 * 4096) div 16 - LWindow.MapWidth div 2, LWindow.MapX);
end;

procedure TTestAutomapView.DovrebbeCentrareSulGiocatoreSenzaToccareLAngoloInAlto;
var
  LBefore: TAutomapWindow;
  LAfter: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, 0, 0);
  LBefore := FView.Window;
  FNavigator.CenterOnPlayer(FPlayerX, FPlayerY);
  LAfter := FView.Window;
  Assert.AreEqual(FPlayerX div 16 - LAfter.MapWidth div 2, LAfter.MapX);
  // difetto conservato: il vecchio AM_Drawer non aggiornava m_x2 e m_y2
  Assert.AreEqual(LBefore.MapX2, LAfter.MapX2);
  Assert.AreEqual(LBefore.MapY2, LAfter.MapY2);
end;

procedure TTestAutomapView.DovrebbeRitagliareUnaLineaConLaFinestra;
var
  LLine: TAutomapLine;
  LFrame: TAutomapFrameLine;
  LWindow: TAutomapWindow;
begin
  FitLevel(0, 0, 1000, 600);
  FNavigator.InitializeScale;
  FNavigator.StartWindow(True, FPlayerX, FPlayerY);
  LWindow := FView.Window;
  LLine.A.X := LWindow.MapX + LWindow.MapWidth div 4;
  LLine.A.Y := LWindow.MapY + LWindow.MapHeight div 4;
  LLine.B.X := LWindow.MapX + LWindow.MapWidth div 2;
  LLine.B.Y := LWindow.MapY + LWindow.MapHeight div 2;
  Assert.IsTrue(FView.ClipLine(LLine, LFrame));
  Assert.AreEqual(FView.MapToFrameX(LLine.A.X), LFrame.A.X);
  Assert.AreEqual(FView.MapToFrameY(LLine.B.Y), LFrame.B.Y);
  // a line far away is rejected
  LLine.A.X := LWindow.MapX2 + 100 * 4096;
  LLine.B.X := LLine.A.X + 100;
  Assert.IsFalse(FView.ClipLine(LLine, LFrame));
end;

end.
