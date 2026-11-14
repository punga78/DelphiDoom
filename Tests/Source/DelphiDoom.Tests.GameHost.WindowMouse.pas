{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the game host library - the mouse of the system inside  }
{  the window of the game, with a fake cursor, a fake window and fake buttons   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.WindowMouse;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.MouseState, DelphiDoom.GameHost.WindowMouse;

type
  /// <summary>The cursor of a system that has no screen: it remembers where it was put</summary>
  TFakeSystemCursor = class(TInterfacedObject, IMouseDevice)
  public
    X: Integer;
    Y: Integer;
    Started: Integer;
    Stopped: Integer;
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
  end;

  /// <summary>The place of a window that may not exist</summary>
  TFakeWindowArea = class(TInterfacedObject, IGameHostCursorArea)
  public
    HasWindow: Boolean;
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    Foreground: Boolean;
    function ClientOrigin(out AX, AY: Integer): Boolean;
    function ClientWidth: Integer;
    function ClientHeight: Integer;
    function IsForeground: Boolean;
  end;

  [TestFixture]
  [Category('gamehost')]
  TTestGameHostWindowMouse = class(TObject)
  strict private
    FCursor: TFakeSystemCursor;
    FCursorKeeper: IMouseDevice;
    FArea: TFakeWindowArea;
    FAreaKeeper: IGameHostCursorArea;
    FButtons: IGameHostMouseState;
    FMouse: TGameHostWindowMouse;
    FMouseKeeper: IMouseDevice;
    procedure Post(AKind: TGameHostEventKind; AButton: TGameHostMouseButton = hmbNone; AFocused: Boolean = True);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
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
    procedure DovrebbeDareLaMisuraDellAreaClient;
    [Test]
    procedure DovrebbeAscoltareSoloConLaFinestraInPrimoPiano;
    [Test]
    procedure DovrebbeAvviareEFermareIlCursoreDelSistema;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaNulla;
  end;

implementation

{ TFakeSystemCursor }

procedure TFakeSystemCursor.Initialize;
begin
  Inc(Started);
end;

procedure TFakeSystemCursor.Shutdown;
begin
  Inc(Stopped);
end;

procedure TFakeSystemCursor.GetPosition(out AX, AY: Integer);
begin
  AX := X;
  AY := Y;
end;

procedure TFakeSystemCursor.SetPosition(AX, AY: Integer);
begin
  X := AX;
  Y := AY;
end;

function TFakeSystemCursor.IsButtonDown(AButton: TMouseButton): Boolean;
begin
  // the buttons of the game come from the window, not from the cursor
  Result := True;
end;

{ TFakeWindowArea }

function TFakeWindowArea.ClientOrigin(out AX, AY: Integer): Boolean;
begin
  AX := Left;
  AY := Top;
  Result := HasWindow;
end;

function TFakeWindowArea.ClientWidth: Integer;
begin
  if HasWindow then
    Result := Width
  else
    Result := 0;
end;

function TFakeWindowArea.ClientHeight: Integer;
begin
  if HasWindow then
    Result := Height
  else
    Result := 0;
end;

function TFakeWindowArea.IsForeground: Boolean;
begin
  Result := HasWindow and Foreground;
end;

{ TTestGameHostWindowMouse }

procedure TTestGameHostWindowMouse.Setup;
begin
  FCursor := TFakeSystemCursor.Create;
  FCursorKeeper := FCursor;
  FArea := TFakeWindowArea.Create;
  FAreaKeeper := FArea;
  FArea.HasWindow := True;
  FArea.Left := 100;
  FArea.Top := 50;
  FArea.Width := 960;
  FArea.Height := 600;
  FArea.Foreground := True;
  FButtons := TGameHostMouseState.Create;
  FMouse := TGameHostWindowMouse.Create(FCursorKeeper, FAreaKeeper, FButtons);
  FMouseKeeper := FMouse;
end;

procedure TTestGameHostWindowMouse.TearDown;
begin
  FMouseKeeper := nil;
  FMouse := nil;
  FButtons := nil;
  FAreaKeeper := nil;
  FArea := nil;
  FCursorKeeper := nil;
  FCursor := nil;
end;

procedure TTestGameHostWindowMouse.Post(AKind: TGameHostEventKind; AButton: TGameHostMouseButton;
  AFocused: Boolean);
var
  LEvent: TGameHostEvent;
begin
  LEvent := Default(TGameHostEvent);
  LEvent.Kind := AKind;
  LEvent.Button := AButton;
  LEvent.Focused := AFocused;
  (FButtons as IGameHostEventSink).Post(LEvent);
end;

procedure TTestGameHostWindowMouse.DovrebbeDareIlCursoreInPixelDellaFinestra;
var
  LX: Integer;
  LY: Integer;
begin
  FCursor.X := 100 + 480 + 7;
  FCursor.Y := 50 + 300 - 3;
  FMouseKeeper.GetPosition(LX, LY);
  Assert.AreEqual(487, LX);
  Assert.AreEqual(297, LY);
end;

procedure TTestGameHostWindowMouse.DovrebbeMettereIlCursoreInPixelDelloSchermo;
begin
  FMouseKeeper.SetPosition(480, 300);
  Assert.AreEqual(580, FCursor.X);
  Assert.AreEqual(350, FCursor.Y);
end;

procedure TTestGameHostWindowMouse.NonDovrebbeSpostareIlCursoreSenzaFinestra;
var
  LX: Integer;
  LY: Integer;
begin
  FArea.HasWindow := False;
  FCursor.X := 11;
  FCursor.Y := 22;
  FMouseKeeper.SetPosition(480, 300);
  Assert.AreEqual(11, FCursor.X);
  Assert.AreEqual(22, FCursor.Y);
  // without a window the position is the one of the screen
  FMouseKeeper.GetPosition(LX, LY);
  Assert.AreEqual(11, LX);
  Assert.AreEqual(22, LY);
end;

procedure TTestGameHostWindowMouse.DovrebbeDareIBottoniVistiDallaFinestra;
begin
  Assert.IsFalse(FMouseKeeper.IsButtonDown(TMouseButton.Left));
  Post(hekMouseDown, hmbLeft);
  Post(hekMouseDown, hmbMiddle);
  Assert.IsTrue(FMouseKeeper.IsButtonDown(TMouseButton.Left));
  Assert.IsFalse(FMouseKeeper.IsButtonDown(TMouseButton.Right));
  Assert.IsTrue(FMouseKeeper.IsButtonDown(TMouseButton.Middle));
  Post(hekMouseUp, hmbLeft);
  Assert.IsFalse(FMouseKeeper.IsButtonDown(TMouseButton.Left));
end;

procedure TTestGameHostWindowMouse.DovrebbeRilasciareIBottoniQuandoCambiaIlFuoco;
begin
  Post(hekMouseDown, hmbRight);
  Assert.IsTrue(FMouseKeeper.IsButtonDown(TMouseButton.Right));
  Post(hekActive, hmbNone, False);
  Assert.IsFalse(FMouseKeeper.IsButtonDown(TMouseButton.Right));
end;

procedure TTestGameHostWindowMouse.DovrebbeDareLaMisuraDellAreaClient;
begin
  Assert.AreEqual(960, (FMouse as IScreenSize).Width);
  Assert.AreEqual(600, (FMouse as IScreenSize).Height);
  FArea.HasWindow := False;
  Assert.AreEqual(0, (FMouse as IScreenSize).Width);
end;

procedure TTestGameHostWindowMouse.DovrebbeAscoltareSoloConLaFinestraInPrimoPiano;
begin
  Assert.IsTrue((FMouse as IInputGate).IsInputAllowed);
  FArea.Foreground := False;
  Assert.IsFalse((FMouse as IInputGate).IsInputAllowed);
end;

procedure TTestGameHostWindowMouse.DovrebbeAvviareEFermareIlCursoreDelSistema;
begin
  FMouseKeeper.Initialize;
  FMouseKeeper.Shutdown;
  Assert.AreEqual(1, FCursor.Started);
  Assert.AreEqual(1, FCursor.Stopped);
end;

procedure TTestGameHostWindowMouse.DovrebbeRifiutareUnaDipendenzaNulla;
var
  LNoCursor: IMouseDevice;
  LNoArea: IGameHostCursorArea;
  LNoButtons: IGameHostMouseState;
begin
  LNoCursor := nil;
  LNoArea := nil;
  LNoButtons := nil;
  Assert.WillRaise(
    procedure
    begin
      TGameHostWindowMouse.Create(LNoCursor, FAreaKeeper, FButtons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGameHostWindowMouse.Create(FCursorKeeper, LNoArea, FButtons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGameHostWindowMouse.Create(FCursorKeeper, FAreaKeeper, LNoButtons).Free;
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameHostWindowMouse);

end.
