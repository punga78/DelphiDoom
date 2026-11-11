{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the place of the window (IXcomWindowPlacement):    }
{  what the screen asks of the display from the options, and the selector of    }
{  the displays that passes it on                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.WindowPlacement;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.Xcom.VideoDevice.Types,
  DelphiDoom.Xcom.VideoDeviceSelector;

type
  /// <summary>A display that records where it is told to put its window and the size it is given</summary>
  TFakePlacedDisplay = class(TInterfacedObject, IXcomVideoDevice, IXcomWindowPlacement)
  public
    Placements: Integer;
    Fixed: Boolean;
    Centered: Boolean;
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    PlacedBeforeMode: Boolean;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
    procedure SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
  end;

  [TestFixture]
  [Category('XcomWindow')]
  TTestXcomWindowPlacement = class
  strict private
    FOptions: TXcomOptions;
    FDisplay: TFakePlacedDisplay;
    FDisplayRef: IXcomVideoDevice;
    procedure Reset;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaFinestraSiRiapreAllaMisuraDelleOpzioni;
    [Test]
    procedure SenzaPosizioneFissaLaFinestraRestaDovE;
    [Test]
    procedure LaPosizioneFissaVaAlDispositivoPrimaDelModo;
    [Test]
    procedure ASchermoInteroLaPosizioneFissaNonVale;
    [Test]
    procedure UnaFinestraSenzaBordiVaAlCentro;
    [Test]
    procedure LaPosizioneFissaVinceSulCentro;
    [Test]
    procedure IlSelettorePassaLaPosizioneAlDispositivoCheCrea;
  end;

implementation

{ TFakePlacedDisplay }

procedure TFakePlacedDisplay.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  Width := AWidth;
  Height := AHeight;
  PlacedBeforeMode := Placements > 0;
end;

procedure TFakePlacedDisplay.Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
begin
end;

procedure TFakePlacedDisplay.SetTitle(const ATitle: string);
begin
end;

procedure TFakePlacedDisplay.SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
begin
  Inc(Placements);
  Fixed := AFixed;
  X := AX;
  Y := AY;
  Centered := ACentered;
end;

{ TTestXcomWindowPlacement }

procedure TTestXcomWindowPlacement.Setup;
begin
  FOptions := TXcomOptions.Create;
  FDisplay := TFakePlacedDisplay.Create;
  FDisplayRef := FDisplay;
end;

procedure TTestXcomWindowPlacement.TearDown;
begin
  FDisplayRef := nil;
  FOptions.Free;
end;

procedure TTestXcomWindowPlacement.Reset;
var
  LScreen: TXcomScreen;
begin
  // the constructor of the screen sets the mode of the display (Screen::resetDisplay)
  LScreen := TXcomScreen.Create(FOptions, FDisplayRef);
  LScreen.Free;
end;

procedure TTestXcomWindowPlacement.LaFinestraSiRiapreAllaMisuraDelleOpzioni;
begin
  FOptions.DisplayWidth := 884;
  FOptions.DisplayHeight := 611;
  Reset;
  Assert.AreEqual(884, FDisplay.Width);
  Assert.AreEqual(611, FDisplay.Height);
end;

procedure TTestXcomWindowPlacement.SenzaPosizioneFissaLaFinestraRestaDovE;
begin
  FOptions.WindowedModePositionX := 120;
  FOptions.WindowedModePositionY := 70;
  Reset;
  Assert.IsFalse(FDisplay.Fixed);
  Assert.IsFalse(FDisplay.Centered);
end;

procedure TTestXcomWindowPlacement.LaPosizioneFissaVaAlDispositivoPrimaDelModo;
begin
  FOptions.RootWindowedMode := True;
  FOptions.WindowedModePositionX := 120;
  FOptions.WindowedModePositionY := 70;
  Reset;
  Assert.IsTrue(FDisplay.Fixed);
  Assert.AreEqual(120, FDisplay.X);
  Assert.AreEqual(70, FDisplay.Y);
  Assert.IsFalse(FDisplay.Centered);
  Assert.IsTrue(FDisplay.PlacedBeforeMode, 'la posizione si sa quando la finestra nasce');
end;

procedure TTestXcomWindowPlacement.ASchermoInteroLaPosizioneFissaNonVale;
begin
  FOptions.RootWindowedMode := True;
  FOptions.Fullscreen := True;
  Reset;
  Assert.IsFalse(FDisplay.Fixed);
end;

procedure TTestXcomWindowPlacement.UnaFinestraSenzaBordiVaAlCentro;
begin
  FOptions.Borderless := True;
  Reset;
  Assert.IsTrue(FDisplay.Centered);
  Assert.IsFalse(FDisplay.Fixed);
end;

procedure TTestXcomWindowPlacement.LaPosizioneFissaVinceSulCentro;
begin
  FOptions.Borderless := True;
  FOptions.RootWindowedMode := True;
  Reset;
  Assert.IsTrue(FDisplay.Fixed);
  Assert.IsFalse(FDisplay.Centered);
end;

procedure TTestXcomWindowPlacement.IlSelettorePassaLaPosizioneAlDispositivoCheCrea;
var
  LSelector: TXcomVideoDeviceSelector;
  LDevice: IXcomVideoDevice;
  LFactory: TXcomVideoDeviceFactory;
  LWidth, LHeight: Integer;
begin
  LFactory :=
    function: IXcomVideoDevice
    begin
      Result := FDisplayRef;
    end;
  LSelector := TXcomVideoDeviceSelector.Create(LFactory, nil);
  // one interface reference for the whole life of the object
  LDevice := LSelector;
  LSelector.SetWindowPlacement(True, 33, 44, False);
  Assert.AreEqual(0, FDisplay.Placements, 'nessun dispositivo prima del primo modo');
  LWidth := 640;
  LHeight := 400;
  LDevice.SetMode(LWidth, LHeight, False);
  Assert.AreEqual(1, FDisplay.Placements);
  Assert.IsTrue(FDisplay.Fixed);
  Assert.AreEqual(33, FDisplay.X);
  Assert.AreEqual(44, FDisplay.Y);
  Assert.IsTrue(FDisplay.PlacedBeforeMode);
end;

end.
