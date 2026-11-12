{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the way of a frame of colors to the display        }
{  (issue 183): the adapter of the game, the selector of Libs\GameHost and a    }
{  display that shows pictures of colors, or one that does not                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.TrueColorDisplay;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf,
  DelphiDoom.GameHost.TrueColor.Intf, DelphiDoom.GameHost.VideoDeviceSelector, DelphiDoom.Xcom.HostVideoDevice;

type
  /// <summary>A display of Libs\GameHost that only shows 8 bit pictures</summary>
  TFakeHostIndexedDisplay = class(TInterfacedObject, IGameHostVideoDevice)
  public
    Presented: Integer;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette);
    procedure SetTitle(const ATitle: string);
  end;

  /// <summary>A display of Libs\GameHost that records the pictures of colors it is given</summary>
  TFakeHostTrueColorDisplay = class(TFakeHostIndexedDisplay, IGameHostTrueColorDisplay)
  public
    TrueColorPresented: Integer;
    Width: Integer;
    Height: Integer;
    First: Cardinal;
    Answer: Boolean;
    function PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth, AHeight: Integer): Boolean;
  end;

  [TestFixture]
  [Category('XcomTrueColor')]
  TTestXcomTrueColorDisplay = class
  strict private
    function Chain(const AHost: IGameHostVideoDevice; ASetMode: Boolean = True): IXcomVideoDevice;
  public
    [Test]
    procedure IlFotogrammaDovrebbeArrivareAlDispositivoDelSelettore;
    [Test]
    procedure UnDispositivoSenzaColoriDovrebbeFarRispondereFalso;
    [Test]
    procedure IlRifiutoDelDispositivoDovrebbeTornareAlGioco;
    [Test]
    procedure PrimaDelPrimoModoIlSelettoreDovrebbeRispondereFalso;
  end;

implementation

{ TFakeHostIndexedDisplay }

procedure TFakeHostIndexedDisplay.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
end;

procedure TFakeHostIndexedDisplay.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
begin
  Inc(Presented);
end;

procedure TFakeHostIndexedDisplay.SetTitle(const ATitle: string);
begin
end;

{ TFakeHostTrueColorDisplay }

function TFakeHostTrueColorDisplay.PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth,
  AHeight: Integer): Boolean;
begin
  Inc(TrueColorPresented);
  Width := AWidth;
  Height := AHeight;
  First := APixels[0];
  Result := Answer;
end;

{ TTestXcomTrueColorDisplay }

function TTestXcomTrueColorDisplay.Chain(const AHost: IGameHostVideoDevice; ASetMode: Boolean): IXcomVideoDevice;
var
  LFactory: TGameHostVideoDeviceFactory;
  LSelector: IGameHostVideoDevice;
  LWidth: Integer;
  LHeight: Integer;
begin
  // the chain of Xcom32: the adapter of the game, the selector of Libs\GameHost, the display it makes
  LFactory :=
    function: IGameHostVideoDevice
    begin
      Result := AHost;
    end;
  LSelector := TGameHostVideoDeviceSelector.Create(LFactory, nil);
  Result := TXcomHostVideoDevice.Create(LSelector);
  if ASetMode then
  begin
    LWidth := 640;
    LHeight := 400;
    Result.SetMode(LWidth, LHeight, False);
  end;
end;

procedure TTestXcomTrueColorDisplay.IlFotogrammaDovrebbeArrivareAlDispositivoDelSelettore;
var
  LHost: TFakeHostTrueColorDisplay;
  LHostRef: IGameHostVideoDevice;
  LDevice: IXcomVideoDevice;
  LPixels: TXcomTrueColorPixels;
begin
  LHost := TFakeHostTrueColorDisplay.Create;
  LHostRef := LHost;
  LHost.Answer := True;
  LDevice := Chain(LHostRef);
  SetLength(LPixels, 6);
  LPixels[0] := $FF112233;
  Assert.IsTrue((LDevice as IXcomTrueColorDisplay).PresentTrueColor(LPixels, 3, 2));
  Assert.AreEqual(1, LHost.TrueColorPresented);
  Assert.AreEqual(3, LHost.Width);
  Assert.AreEqual(2, LHost.Height);
  Assert.AreEqual(Cardinal($FF112233), LHost.First);
  Assert.AreEqual(0, LHost.Presented);
end;

procedure TTestXcomTrueColorDisplay.UnDispositivoSenzaColoriDovrebbeFarRispondereFalso;
var
  LHost: TFakeHostIndexedDisplay;
  LHostRef: IGameHostVideoDevice;
  LDevice: IXcomVideoDevice;
  LPixels: TXcomTrueColorPixels;
begin
  LHost := TFakeHostIndexedDisplay.Create;
  LHostRef := LHost;
  LDevice := Chain(LHostRef);
  SetLength(LPixels, 6);
  Assert.IsFalse((LDevice as IXcomTrueColorDisplay).PresentTrueColor(LPixels, 3, 2));
  Assert.AreEqual(0, LHost.Presented);
end;

procedure TTestXcomTrueColorDisplay.IlRifiutoDelDispositivoDovrebbeTornareAlGioco;
var
  LHost: TFakeHostTrueColorDisplay;
  LHostRef: IGameHostVideoDevice;
  LDevice: IXcomVideoDevice;
  LPixels: TXcomTrueColorPixels;
begin
  LHost := TFakeHostTrueColorDisplay.Create;
  LHostRef := LHost;
  LHost.Answer := False;
  LDevice := Chain(LHostRef);
  SetLength(LPixels, 6);
  Assert.IsFalse((LDevice as IXcomTrueColorDisplay).PresentTrueColor(LPixels, 3, 2));
  Assert.AreEqual(1, LHost.TrueColorPresented);
end;

procedure TTestXcomTrueColorDisplay.PrimaDelPrimoModoIlSelettoreDovrebbeRispondereFalso;
var
  LHost: TFakeHostTrueColorDisplay;
  LHostRef: IGameHostVideoDevice;
  LDevice: IXcomVideoDevice;
  LPixels: TXcomTrueColorPixels;
begin
  LHost := TFakeHostTrueColorDisplay.Create;
  LHostRef := LHost;
  LHost.Answer := True;
  LDevice := Chain(LHostRef, False);
  SetLength(LPixels, 6);
  Assert.IsFalse((LDevice as IXcomTrueColorDisplay).PresentTrueColor(LPixels, 3, 2));
  Assert.AreEqual(0, LHost.TrueColorPresented);
end;

end.
