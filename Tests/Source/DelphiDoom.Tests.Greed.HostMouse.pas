{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TGreedHostMouse (the mouse of the system inside    }
{  the window of Greed32), with a fake cursor and a fake window: no window      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.HostMouse;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.MouseState,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.Mouse,
  DelphiDoom.Greed.HostMouse, DelphiDoom.Tests.Greed.MenuScenarios;

type
  /// <summary>The place of a window that does not exist</summary>
  TFakeCursorArea = class(TInterfacedObject, IGameHostCursorArea)
  public
    HasWindow: Boolean;
    Left, Top, Width, Height: Integer;
    Foreground: Boolean;
    function ClientOrigin(out AX, AY: Integer): Boolean;
    function ClientWidth: Integer;
    function ClientHeight: Integer;
    function IsForeground: Boolean;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedHostMouse = class(TObject)
  strict private
    FCursor: TMenuMouseFake;
    FCursorIntf: IMouseDevice;
    FArea: TFakeCursorArea;
    FAreaIntf: IGameHostCursorArea;
    FButtons: IGameHostMouseState;
    FHost: TGreedHostMouse;
    FHostIntf: IMouseDevice;
    procedure Button(AButton: TGameHostMouseButton; ADown: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareConUnaDipendenzaNulla;
    [Test]
    procedure DovrebbeDareIlCursoreInPixelDellaFinestra;
    [Test]
    procedure DovrebbeMettereIlCursoreInPixelDelloSchermo;
    [Test]
    procedure NonDovrebbeSpostareIlCursoreSenzaFinestra;
    [Test]
    procedure DovrebbeDareIBottoniVistiDallaFinestra;
    [Test]
    procedure DovrebbeRilasciareIBottoniQuandoCambiaIlFuoco;
    [Test]
    procedure DovrebbeDareLaMisuraDellAreaDellaFinestra;
    [Test]
    procedure DovrebbeAscoltareSoloConLaFinestraInPrimoPiano;
    [Test]
    procedure DovrebbeTenereIlCursoreAlCentroDellaFinestraPerIlGioco;
  end;

implementation

{ TFakeCursorArea }

function TFakeCursorArea.ClientOrigin(out AX, AY: Integer): Boolean;
begin
  AX := Left;
  AY := Top;
  Result := HasWindow;
end;

function TFakeCursorArea.ClientWidth: Integer;
begin
  Result := Width;
end;

function TFakeCursorArea.ClientHeight: Integer;
begin
  Result := Height;
end;

function TFakeCursorArea.IsForeground: Boolean;
begin
  Result := Foreground;
end;

{ TTestGreedHostMouse }

procedure TTestGreedHostMouse.Setup;
begin
  FCursor := TMenuMouseFake.Create;
  FCursorIntf := FCursor;
  FArea := TFakeCursorArea.Create;
  FAreaIntf := FArea;
  FArea.HasWindow := True;
  FArea.Left := 300;
  FArea.Top := 120;
  FArea.Width := 640;
  FArea.Height := 400;
  FArea.Foreground := True;
  FButtons := TGameHostMouseState.Create;
  FHost := TGreedHostMouse.Create(FCursorIntf, FAreaIntf, FButtons);
  FHostIntf := FHost;
end;

procedure TTestGreedHostMouse.TearDown;
begin
  FHostIntf := nil;
  FButtons := nil;
  FAreaIntf := nil;
  FCursorIntf := nil;
end;

procedure TTestGreedHostMouse.Button(AButton: TGameHostMouseButton; ADown: Boolean);
var
  LEvent: TGameHostEvent;
begin
  if ADown then
    LEvent := TGameHostEvent.Make(hekMouseDown)
  else
    LEvent := TGameHostEvent.Make(hekMouseUp);
  LEvent.Button := AButton;
  (FButtons as IGameHostEventSink).Post(LEvent);
end;

procedure TTestGreedHostMouse.DovrebbeSollevareConUnaDipendenzaNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedHostMouse.Create(nil, FAreaIntf, FButtons);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHostMouse.Create(FCursorIntf, nil, FButtons);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHostMouse.Create(FCursorIntf, FAreaIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedHostMouse.DovrebbeDareIlCursoreInPixelDellaFinestra;
var
  LX, LY: Integer;
begin
  FHostIntf.Initialize;
  FCursor.X := 350;
  FCursor.Y := 130;
  FHost.GetPosition(LX, LY);
  Assert.AreEqual(50, LX);
  Assert.AreEqual(10, LY);
  FArea.HasWindow := False;
  FHost.GetPosition(LX, LY);
  Assert.AreEqual(350, LX, 'without a window: the pixels of the screen');
  FHostIntf.Shutdown;
end;

procedure TTestGreedHostMouse.DovrebbeMettereIlCursoreInPixelDelloSchermo;
begin
  FHost.SetPosition(320, 200);
  Assert.AreEqual(620, FCursor.X);
  Assert.AreEqual(320, FCursor.Y);
end;

procedure TTestGreedHostMouse.NonDovrebbeSpostareIlCursoreSenzaFinestra;
begin
  FCursor.X := 11;
  FCursor.Y := 12;
  FArea.HasWindow := False;
  FHost.SetPosition(320, 200);
  Assert.AreEqual(11, FCursor.X);
  Assert.AreEqual(12, FCursor.Y);
end;

procedure TTestGreedHostMouse.DovrebbeDareIBottoniVistiDallaFinestra;
begin
  // the buttons of the system (the fake cursor says all down) are not asked: the window says
  FCursor.Buttons := 7;
  Assert.IsFalse(FHost.IsButtonDown(TMouseButton.Left));
  Button(hmbLeft, True);
  Button(hmbMiddle, True);
  Assert.IsTrue(FHost.IsButtonDown(TMouseButton.Left));
  Assert.IsTrue(FHost.IsButtonDown(TMouseButton.Middle));
  Assert.IsFalse(FHost.IsButtonDown(TMouseButton.Right));
  Button(hmbLeft, False);
  Button(hmbRight, True);
  Assert.IsFalse(FHost.IsButtonDown(TMouseButton.Left));
  Assert.IsTrue(FHost.IsButtonDown(TMouseButton.Right));
end;

procedure TTestGreedHostMouse.DovrebbeRilasciareIBottoniQuandoCambiaIlFuoco;
var
  LEvent: TGameHostEvent;
begin
  Button(hmbLeft, True);
  LEvent := TGameHostEvent.Make(hekActive);
  LEvent.Focused := False;
  (FButtons as IGameHostEventSink).Post(LEvent);
  Assert.IsFalse(FHost.IsButtonDown(TMouseButton.Left));
end;

procedure TTestGreedHostMouse.DovrebbeDareLaMisuraDellAreaDellaFinestra;
begin
  Assert.AreEqual(640, FHost.GetWidth);
  Assert.AreEqual(400, FHost.GetHeight);
  FArea.Width := 960;
  FArea.Height := 600;
  Assert.AreEqual(960, FHost.GetWidth);
  Assert.AreEqual(600, FHost.GetHeight);
end;

procedure TTestGreedHostMouse.DovrebbeAscoltareSoloConLaFinestraInPrimoPiano;
begin
  Assert.IsTrue(FHost.IsInputAllowed);
  FArea.Foreground := False;
  Assert.IsFalse(FHost.IsInputAllowed);
end;

procedure TTestGreedHostMouse.DovrebbeTenereIlCursoreAlCentroDellaFinestraPerIlGioco;
var
  LMouse: IGreedMouse;
begin
  // the mouse of the game on this device, with no gate: the reading puts the cursor at the centre of the window
  LMouse := TGreedMouse.Create(FHostIntf, FHost, nil);
  FCursor.X := 700;
  FCursor.Y := 500;
  LMouse.Read;
  Assert.AreEqual(300 + 320, FCursor.X);
  Assert.AreEqual(120 + 200, FCursor.Y);
  FCursor.X := FCursor.X + 15;
  Button(hmbRight, True);
  LMouse.Read;
  Assert.AreEqual(-15, LMouse.DeltaX);
  Assert.IsTrue(LMouse.IsDown(gmbUse), 'the right button uses');
  Assert.AreEqual(620, FCursor.X);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedHostMouse);

end.
