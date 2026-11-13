{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texts of the battlescape that are copied on the    }
{  screen itself, so that they leave their ink there (issue 188)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.InkLayers;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattleStates.OffsetBlit,
  DelphiDoom.XcomBattleStates.WarningMessage, DelphiDoom.XcomBattleStates.BattlescapeMessage,
  DelphiDoom.XcomBattleStates.ActionMenuItem, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.DetailFakes;

type
  EProbeBlitError = class(Exception);

  /// <summary>A surface that fails when it is copied</summary>
  TFailingSurface = class(TXcomSurface)
  public
    procedure Blit(ATarget: TXcomSurface); override;
  end;

  /// <summary>A state with nothing in it (the message takes the clock of its host)</summary>
  TProbeState = class(TXcomState);

  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomInkLayers = class
  strict private
    FWorld: TTestWorld;
    FScreen: TXcomSurface;
    FOther: TXcomSurface;
    FLayers: TFakeInkLayers;
    FLayersRef: IXcomInkLayers;
    FSmallDetail: TFakeFontDetail;
    FBigDetail: TFakeFontDetail;
    FState: TProbeState;
    procedure WithDetail(AScale: Integer);
    function Small: TXcomFont;
    function Big: TXcomFont;
    function NewWarning: TXcomWarningMessage;
    function NewItem: TXcomActionMenuItem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure OffsetBlitDovrebbeSpostareIlWidgetSoloPerLaCopia;
    [Test]
    procedure OffsetBlitDovrebbeRimettereIlPostoAncheSeLaCopiaFallisce;
    [Test]
    procedure IlAvvisoDovrebbeLasciareLInchiostroSulloSchermo;
    [Test]
    procedure IlAvvisoDovrebbeLasciareLInchiostroNellaScalaDelFont;
    [Test]
    procedure IlAvvisoCopiatoSuUnAltraSuperficieNonDovrebbeLasciareInchiostro;
    [Test]
    procedure IlAvvisoNascostoNonDovrebbeLasciareInchiostro;
    [Test]
    procedure IlAvvisoSenzaDettaglioNonDovrebbeLasciareInchiostro;
    [Test]
    procedure IlAvvisoDovrebbeDisegnareLoSfondoSulloSchermoPrimaDelTesto;
    [Test]
    procedure LaVoceDelMenuDovrebbeLasciareTreInchiostriNelPostoDeiTesti;
    [Test]
    procedure LaVoceDelMenuNonDovrebbeDisegnareITestiDentroDiSe;
    [Test]
    procedure IlMessaggioDelMovimentoNascostoDovrebbeLasciareLInchiostroNelPostoGiusto;
  end;

implementation

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;

{ TFailingSurface }

procedure TFailingSurface.Blit(ATarget: TXcomSurface);
begin
  raise EProbeBlitError.Create('blit failed');
end;

{ TTestXcomInkLayers }

procedure TTestXcomInkLayers.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TProbeState.Create(FWorld.Game);
  FScreen := TXcomSurface.Create(SCREEN_WIDTH, SCREEN_HEIGHT);
  FOther := TXcomSurface.Create(SCREEN_WIDTH, SCREEN_HEIGHT);
  // no palette is given to any surface: the copy remaps the colors between palettes, as SDL does, so they share one
  FLayers := TFakeInkLayers.Create;
  FLayersRef := FLayers;
  FLayers.Base := FScreen;
end;

procedure TTestXcomInkLayers.TearDown;
begin
  // the fonts of the world hold the details: they go before the layers
  Small.Detail := nil;
  Big.Detail := nil;
  FSmallDetail := nil;
  FBigDetail := nil;
  FState.Free;
  FOther.Free;
  FScreen.Free;
  FLayersRef := nil;
  FWorld.Free;
end;

function TTestXcomInkLayers.Small: TXcomFont;
begin
  Result := FWorld.Resources.GetFont('FONT_SMALL');
end;

function TTestXcomInkLayers.Big: TXcomFont;
begin
  Result := FWorld.Resources.GetFont('FONT_BIG');
end;

procedure TTestXcomInkLayers.WithDetail(AScale: Integer);
begin
  FSmallDetail := TFakeFontDetail.Create(Small, FLayersRef, AScale);
  Small.Detail := FSmallDetail;
  FBigDetail := TFakeFontDetail.Create(Big, FLayersRef, AScale);
  Big.Detail := FBigDetail;
end;

function TTestXcomInkLayers.NewWarning: TXcomWarningMessage;
begin
  Result := TXcomWarningMessage.Create(FWorld.Game.Clock, 224, 24, 48, 32);
  Result.SetColor(32);
  Result.InitText(Big, Small, FWorld.Game.Language);
  Result.ShowMessage('NOT ENOUGH');
end;

function TTestXcomInkLayers.NewItem: TXcomActionMenuItem;
var
  LElement: TXcomInterfaceElement;
begin
  LElement := Default(TXcomInterfaceElement);
  LElement.Color := 47;
  LElement.Color2 := 61;
  LElement.Border := 51;
  Result := TXcomActionMenuItem.Create(0, LElement, Big, Small, FWorld.Game.Language, 0, 100);
  Result.SetAction(1, 'SNAP', '34%', '16', 16);
end;

procedure TTestXcomInkLayers.OffsetBlitDovrebbeSpostareIlWidgetSoloPerLaCopia;
var
  LWidget: TXcomSurface;
begin
  LWidget := TXcomSurface.Create(10, 10);
  try
    LWidget.X := 5;
    LWidget.Y := 7;
    LWidget.Clear(9);
    TXcomOffsetBlit.Blit(LWidget, FScreen, 100, 50);
    Assert.AreEqual(5, LWidget.X);
    Assert.AreEqual(7, LWidget.Y);
    // copied at its place plus the offset
    Assert.AreEqual(9, Integer(FScreen.GetPixel(105, 57)));
    Assert.AreEqual(9, Integer(FScreen.GetPixel(114, 66)));
    Assert.AreEqual(0, Integer(FScreen.GetPixel(104, 57)));
    Assert.AreEqual(0, Integer(FScreen.GetPixel(5, 7)));
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomInkLayers.OffsetBlitDovrebbeRimettereIlPostoAncheSeLaCopiaFallisce;
var
  LWidget: TFailingSurface;
begin
  LWidget := TFailingSurface.Create(10, 10);
  try
    LWidget.X := 5;
    LWidget.Y := 7;
    Assert.WillRaise(
      procedure
      begin
        TXcomOffsetBlit.Blit(LWidget, FScreen, 100, 50);
      end, EProbeBlitError);
    Assert.AreEqual(5, LWidget.X);
    Assert.AreEqual(7, LWidget.Y);
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomInkLayers.IlAvvisoDovrebbeLasciareLInchiostroSulloSchermo;
var
  LWarning: TXcomWarningMessage;
begin
  WithDetail(2);
  LWarning := NewWarning;
  try
    LWarning.Blit(FScreen);
    Assert.AreEqual(1, FLayers.Layers.Count);
    Assert.AreEqual(48, FLayers.Last.X);
    Assert.AreEqual(32, FLayers.Last.Y);
    Assert.AreEqual(224, FLayers.Last.Width);
    Assert.AreEqual(24, FLayers.Last.Height);
    Assert.IsTrue(FLayers.Last.Ended);
  finally
    LWarning.Free;
  end;
end;

procedure TTestXcomInkLayers.IlAvvisoDovrebbeLasciareLInchiostroNellaScalaDelFont;
var
  LWarning: TXcomWarningMessage;
begin
  WithDetail(3);
  LWarning := NewWarning;
  try
    LWarning.Blit(FScreen);
    Assert.AreEqual(3, FLayers.Last.Ink.Scale);
    Assert.AreEqual(224, FLayers.Last.Ink.Width);
  finally
    LWarning.Free;
  end;
end;

procedure TTestXcomInkLayers.IlAvvisoCopiatoSuUnAltraSuperficieNonDovrebbeLasciareInchiostro;
var
  LWarning: TXcomWarningMessage;
begin
  WithDetail(2);
  LWarning := NewWarning;
  try
    LWarning.Blit(FOther);
    Assert.AreEqual(0, FLayers.Layers.Count);
    // but the box is there: the text goes on as a picture of the game
    Assert.AreEqual(32, Integer(FOther.GetPixel(48, 32)));
  finally
    LWarning.Free;
  end;
end;

procedure TTestXcomInkLayers.IlAvvisoNascostoNonDovrebbeLasciareInchiostro;
var
  LWarning: TXcomWarningMessage;
begin
  WithDetail(2);
  LWarning := TXcomWarningMessage.Create(FWorld.Game.Clock, 224, 24, 48, 32);
  try
    LWarning.InitText(Big, Small, FWorld.Game.Language);
    // never shown: invisible
    LWarning.Blit(FScreen);
    Assert.AreEqual(0, FLayers.Layers.Count);
  finally
    LWarning.Free;
  end;
end;

procedure TTestXcomInkLayers.IlAvvisoSenzaDettaglioNonDovrebbeLasciareInchiostro;
var
  LWarning: TXcomWarningMessage;
begin
  LWarning := NewWarning;
  try
    LWarning.Blit(FScreen);
    Assert.AreEqual(0, FLayers.Layers.Count);
    Assert.AreEqual(0, FLayers.Asked);
  finally
    LWarning.Free;
  end;
end;

procedure TTestXcomInkLayers.IlAvvisoDovrebbeDisegnareLoSfondoSulloSchermoPrimaDelTesto;
var
  LWarning: TXcomWarningMessage;
  LCount: Integer;
  LX: Integer;
  LY: Integer;
  LBackground: Integer;
begin
  LWarning := NewWarning;
  try
    LWarning.Blit(FScreen);
    LBackground := Integer(FScreen.GetPixel(48, 32));
    Assert.AreEqual(32, LBackground);
    // the text of the picture is over the box, on the screen: some pixels of the box are not the box
    LCount := 0;
    for LY := 32 to 55 do
      for LX := 48 to 271 do
        if Integer(FScreen.GetPixel(LX, LY)) <> LBackground then
          Inc(LCount);
    Assert.IsTrue(LCount > 0);
    // and nothing outside the box
    Assert.AreEqual(0, Integer(FScreen.GetPixel(47, 32)));
    Assert.AreEqual(0, Integer(FScreen.GetPixel(48, 56)));
  finally
    LWarning.Free;
  end;
end;

procedure TTestXcomInkLayers.LaVoceDelMenuDovrebbeLasciareTreInchiostriNelPostoDeiTesti;
var
  LItem: TXcomActionMenuItem;
begin
  WithDetail(2);
  LItem := NewItem;
  try
    LItem.Blit(FScreen);
    Assert.AreEqual(3, FLayers.Layers.Count);
    // the texts are at 10, 140 and 210 in the line, and at row 13; the line is at 24 and 100
    Assert.AreEqual(LItem.X + 10, FLayers.Layers[0].X);
    Assert.AreEqual(LItem.X + 140, FLayers.Layers[1].X);
    Assert.AreEqual(LItem.X + 210, FLayers.Layers[2].X);
    Assert.AreEqual(LItem.Y + 13, FLayers.Layers[0].Y);
    Assert.AreEqual(LItem.Y + 13, FLayers.Layers[2].Y);
    Assert.AreEqual(200, FLayers.Layers[0].Width);
    Assert.AreEqual(2, FLayers.Layers[0].Ink.Scale);
  finally
    LItem.Free;
  end;
end;

procedure TTestXcomInkLayers.LaVoceDelMenuNonDovrebbeDisegnareITestiDentroDiSe;
var
  LItem: TXcomActionMenuItem;
  LX: Integer;
  LY: Integer;
  LBase: Integer;
begin
  LItem := NewItem;
  try
    LItem.Draw;
    // inside the frame, where the texts are: only the frame is on the surface of the line
    LBase := Integer(LItem.GetPixel(100, 20));
    for LY := 13 to 25 do
      for LX := 10 to 60 do
        Assert.AreEqual(LBase, Integer(LItem.GetPixel(LX, LY)));
  finally
    LItem.Free;
  end;
end;

procedure TTestXcomInkLayers.IlMessaggioDelMovimentoNascostoDovrebbeLasciareLInchiostroNelPostoGiusto;
var
  LMessage: TXcomBattlescapeMessage;
begin
  WithDetail(2);
  LMessage := TXcomBattlescapeMessage.Create(FState, 160, 100, 20, 30);
  try
    LMessage.InitText(Big, Small, FWorld.Game.Language);
    LMessage.SetText('HIDDEN');
    // what the map widget does: the message sits in the map, which is at (10, 5) on the screen
    TXcomOffsetBlit.Blit(LMessage, FScreen, 10, 5);
    Assert.AreEqual(1, FLayers.Layers.Count);
    Assert.AreEqual(30, FLayers.Last.X);
    Assert.AreEqual(35, FLayers.Last.Y);
    Assert.AreEqual(160, FLayers.Last.Width);
    Assert.AreEqual(100, FLayers.Last.Height);
    // the message is back in its place in the map
    Assert.AreEqual(20, LMessage.X);
    Assert.AreEqual(30, LMessage.Y);
  finally
    LMessage.Free;
  end;
end;

end.
