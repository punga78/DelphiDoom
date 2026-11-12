{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TGreedHostWindow (the pictures and the keys of     }
{  Greed32 on the game host library), with a fake display and no window         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.HostWindow;

interface

uses
  Winapi.Windows, System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.GameHost.KeyState, DelphiDoom.Greed.HostWindow;

type
  /// <summary>A display that remembers the mode and the last picture</summary>
  TFakeGreedDisplay = class(TInterfacedObject, IGameHostVideoDevice)
  public
    Title: string;
    ModeWidth: Integer;
    ModeHeight: Integer;
    Fullscreen: Boolean;
    Presented: Integer;
    Width: Integer;
    Height: Integer;
    Color: TGameHostColor;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette);
    procedure SetTitle(const ATitle: string);
  end;

  [TestFixture]
  [Category('Greed')]
  TTestGreedHostWindow = class
  strict private
    FDisplay: TFakeGreedDisplay;
    FDisplayRef: IGameHostVideoDevice;
    FKeys: IGameHostKeyState;
    FOpen: Boolean;
    FWindow: IGreedFramePresenter;
    procedure Press(AVirtualKey: Integer; ADown: Boolean = True);
    function Input: IGreedInput;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeImpostareIlModoScalatoEIlTitolo;
    [Test]
    procedure DovrebbeRifiutareMisureNonPositive;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure DovrebbePresentareIlFotogrammaConIColori;
    [Test]
    procedure NonDovrebbePresentareUnFotogrammaIncompleto;
    [Test]
    procedure IlPumpDovrebbeEssereQuelloDellaFinestra;
    [Test]
    [TestCase('avanti freccia', '38,0')]
    [TestCase('avanti W', '87,0')]
    [TestCase('indietro S', '83,1')]
    [TestCase('gira a sinistra Q', '81,2')]
    [TestCase('gira a destra freccia', '39,3')]
    [TestCase('passo a sinistra A', '65,4')]
    [TestCase('passo a destra D', '68,5')]
    [TestCase('corsa', '16,6')]
    [TestCase('uscita', '27,7')]
    procedure UnTastoPremutoDovrebbeEssereIlSuoComando(AVirtualKey, AKey: Integer);
    [Test]
    procedure UnTastoRilasciatoNonDovrebbeEsserePremuto;
  end;

implementation

{ TFakeGreedDisplay }

procedure TFakeGreedDisplay.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  ModeWidth := AWidth;
  ModeHeight := AHeight;
  Fullscreen := AFullscreen;
end;

procedure TFakeGreedDisplay.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
begin
  Inc(Presented);
  Width := AWidth;
  Height := AHeight;
  Color := APalette[APixels[0]];
end;

procedure TFakeGreedDisplay.SetTitle(const ATitle: string);
begin
  Title := ATitle;
end;

{ TTestGreedHostWindow }

procedure TTestGreedHostWindow.Setup;
begin
  FDisplay := TFakeGreedDisplay.Create;
  FDisplayRef := FDisplay;
  FKeys := TGameHostKeyState.Create;
  FOpen := True;
  FWindow := TGreedHostWindow.Create(FDisplayRef, FKeys,
    function: Boolean
    begin
      Result := FOpen;
    end, 'Greed32', 320, 200, 3);
end;

procedure TTestGreedHostWindow.TearDown;
begin
  FWindow := nil;
  FKeys := nil;
  FDisplayRef := nil;
end;

procedure TTestGreedHostWindow.Press(AVirtualKey: Integer; ADown: Boolean);
var
  LEvent: TGameHostEvent;
begin
  if ADown then
    LEvent := TGameHostEvent.Make(hekKeyDown)
  else
    LEvent := TGameHostEvent.Make(hekKeyUp);
  LEvent.VirtualKey := AVirtualKey;
  (FKeys as IGameHostEventSink).Post(LEvent);
end;

function TTestGreedHostWindow.Input: IGreedInput;
begin
  Result := FWindow as IGreedInput;
end;

procedure TTestGreedHostWindow.DovrebbeImpostareIlModoScalatoEIlTitolo;
begin
  Assert.AreEqual(960, FDisplay.ModeWidth);
  Assert.AreEqual(600, FDisplay.ModeHeight);
  Assert.IsFalse(FDisplay.Fullscreen);
  Assert.AreEqual('Greed32', FDisplay.Title);
end;

procedure TTestGreedHostWindow.DovrebbeRifiutareMisureNonPositive;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedHostWindow.Create(FDisplayRef, FKeys,
        function: Boolean
        begin
          Result := True;
        end, 'x', 320, 200, 0);
    end, EGreedException);
end;

procedure TTestGreedHostWindow.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedHostWindow.Create(nil, FKeys,
        function: Boolean
        begin
          Result := True;
        end, 'x', 320, 200, 1);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHostWindow.Create(FDisplayRef, FKeys, nil, 'x', 320, 200, 1);
    end, EArgumentNilException);
end;

procedure TTestGreedHostWindow.DovrebbePresentareIlFotogrammaConIColori;
var
  LFrame: TGreedFrame;
  LColors: TGreedColors;
begin
  LFrame := TGreedFrame.Make(320, 200);
  LFrame.Pixels[0] := 9;
  FillChar(LColors, SizeOf(LColors), 0);
  LColors[9] := $00112233;
  FWindow.Present(LFrame, LColors);
  Assert.AreEqual(1, FDisplay.Presented);
  Assert.AreEqual(320, FDisplay.Width);
  Assert.AreEqual(200, FDisplay.Height);
  Assert.AreEqual($11, Integer(FDisplay.Color.Red));
  Assert.AreEqual($22, Integer(FDisplay.Color.Green));
  Assert.AreEqual($33, Integer(FDisplay.Color.Blue));
end;

procedure TTestGreedHostWindow.NonDovrebbePresentareUnFotogrammaIncompleto;
var
  LFrame: TGreedFrame;
  LColors: TGreedColors;
begin
  FillChar(LColors, SizeOf(LColors), 0);
  LFrame := TGreedFrame.Make(4, 4);
  SetLength(LFrame.Pixels, 3);
  FWindow.Present(LFrame, LColors);
  LFrame.Width := 0;
  FWindow.Present(LFrame, LColors);
  Assert.AreEqual(0, FDisplay.Presented);
end;

procedure TTestGreedHostWindow.IlPumpDovrebbeEssereQuelloDellaFinestra;
begin
  Assert.IsTrue(Input.Pump);
  FOpen := False;
  Assert.IsFalse(Input.Pump);
end;

procedure TTestGreedHostWindow.UnTastoPremutoDovrebbeEssereIlSuoComando(AVirtualKey, AKey: Integer);
var
  LKey: TGreedKey;
begin
  Press(AVirtualKey);
  for LKey := Low(TGreedKey) to High(TGreedKey) do
    Assert.AreEqual(Ord(LKey) = AKey, Input.IsDown(LKey), 'comando ' + IntToStr(Ord(LKey)));
end;

procedure TTestGreedHostWindow.UnTastoRilasciatoNonDovrebbeEsserePremuto;
begin
  Press(VK_UP);
  Press(Ord('W'));
  Press(VK_UP, False);
  Assert.IsTrue(Input.IsDown(gkForward), 'resta W');
  Press(Ord('W'), False);
  Assert.IsFalse(Input.IsDown(gkForward));
end;

end.
