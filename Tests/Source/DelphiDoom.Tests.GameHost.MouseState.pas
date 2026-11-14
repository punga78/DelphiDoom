{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the game host library - the buttons of the mouse   }
{  that are down, one event for several listeners, the place of the window      }
{  No window is shown: the events are made up, the window has no handle         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.MouseState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.GameHost.KeyState, DelphiDoom.GameHost.MouseState, DelphiDoom.GameHost.EventFanOut,
  DelphiDoom.GameHost.Win.Window, DelphiDoom.GameHost.Factory;

type
  [TestFixture]
  [Category('GameHost')]
  TTestGameHostMouseState = class
  strict private
    FState: IGameHostMouseState;
    procedure Post(AKind: TGameHostEventKind; AButton: TGameHostMouseButton = hmbNone; AFocused: Boolean = False);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbePartireSenzaBottoniEConIlFuoco;
    [Test]
    procedure DovrebbeRicordareIBottoniPremuti;
    [Test]
    procedure DovrebbeDimenticareIlBottoneRilasciato;
    [Test]
    procedure NonDovrebbeAvereUnBottoneNessuno;
    [Test]
    procedure DovrebbeRilasciareTuttoQuandoIlFuocoCambia;
    [Test]
    procedure DovrebbeDireSeLaFinestraHaIlFuoco;
    [Test]
    procedure DovrebbeIgnorareGliAltriEventi;
  end;

  [TestFixture]
  [Category('GameHost')]
  TTestGameHostEventFanOut = class
  public
    [Test]
    procedure DovrebbeDareOgniEventoATuttiGliAscoltatori;
    [Test]
    procedure DovrebbeAccettareNessunAscoltatore;
    [Test]
    procedure DovrebbeRifiutareUnAscoltatoreNil;
  end;

  [TestFixture]
  [Category('GameHost')]
  TTestGameHostCursorArea = class
  public
    [Test]
    procedure DovrebbeRifiutareUnaFinestraNil;
    [Test]
    procedure NonDovrebbeAvereUnPostoPrimaCheLaFinestraEsista;
  end;

implementation

{ TTestGameHostMouseState }

procedure TTestGameHostMouseState.Setup;
begin
  FState := TGameHostMouseState.Create;
end;

procedure TTestGameHostMouseState.Post(AKind: TGameHostEventKind; AButton: TGameHostMouseButton; AFocused: Boolean);
var
  LEvent: TGameHostEvent;
begin
  LEvent := TGameHostEvent.Make(AKind);
  LEvent.Button := AButton;
  LEvent.Focused := AFocused;
  (FState as IGameHostEventSink).Post(LEvent);
end;

procedure TTestGameHostMouseState.DovrebbePartireSenzaBottoniEConIlFuoco;
begin
  Assert.IsFalse(FState.IsDown(hmbLeft));
  Assert.IsFalse(FState.IsDown(hmbMiddle));
  Assert.IsFalse(FState.IsDown(hmbRight));
  Assert.IsTrue(FState.IsFocused, 'until the window says otherwise');
end;

procedure TTestGameHostMouseState.DovrebbeRicordareIBottoniPremuti;
begin
  Post(hekMouseDown, hmbLeft);
  Post(hekMouseDown, hmbRight);
  Assert.IsTrue(FState.IsDown(hmbLeft));
  Assert.IsTrue(FState.IsDown(hmbRight));
  Assert.IsFalse(FState.IsDown(hmbMiddle));
end;

procedure TTestGameHostMouseState.DovrebbeDimenticareIlBottoneRilasciato;
begin
  Post(hekMouseDown, hmbMiddle);
  Post(hekMouseDown, hmbLeft);
  Post(hekMouseUp, hmbMiddle);
  Assert.IsFalse(FState.IsDown(hmbMiddle));
  Assert.IsTrue(FState.IsDown(hmbLeft));
end;

procedure TTestGameHostMouseState.NonDovrebbeAvereUnBottoneNessuno;
begin
  Post(hekMouseDown, hmbNone);
  Assert.IsFalse(FState.IsDown(hmbNone));
  Assert.IsFalse(FState.IsDown(hmbLeft));
end;

procedure TTestGameHostMouseState.DovrebbeRilasciareTuttoQuandoIlFuocoCambia;
begin
  Post(hekMouseDown, hmbLeft);
  Post(hekActive, hmbNone, False);
  Assert.IsFalse(FState.IsDown(hmbLeft), 'the window does not see the button go up');
  Post(hekMouseDown, hmbRight);
  Post(hekActive, hmbNone, True);
  Assert.IsFalse(FState.IsDown(hmbRight), 'also when the focus comes back');
end;

procedure TTestGameHostMouseState.DovrebbeDireSeLaFinestraHaIlFuoco;
begin
  Post(hekActive, hmbNone, False);
  Assert.IsFalse(FState.IsFocused);
  Post(hekActive, hmbNone, True);
  Assert.IsTrue(FState.IsFocused);
end;

procedure TTestGameHostMouseState.DovrebbeIgnorareGliAltriEventi;
begin
  Post(hekMouseDown, hmbLeft);
  Post(hekMouseMotion, hmbLeft);
  Post(hekKeyDown);
  Post(hekMouseWheel);
  Post(hekResize);
  Post(hekQuit);
  Assert.IsTrue(FState.IsDown(hmbLeft));
  Assert.IsTrue(FState.IsFocused);
end;

{ TTestGameHostEventFanOut }

procedure TTestGameHostEventFanOut.DovrebbeDareOgniEventoATuttiGliAscoltatori;
var
  LKeys: IGameHostKeyState;
  LButtons: IGameHostMouseState;
  LSink: IGameHostEventSink;
  LEvent: TGameHostEvent;
begin
  LKeys := TGameHostKeyState.Create;
  LButtons := TGameHostMouseState.Create;
  LSink := TGameHostEventFanOut.Create([LKeys as IGameHostEventSink, LButtons as IGameHostEventSink]);
  LEvent := TGameHostEvent.Make(hekKeyDown);
  LEvent.VirtualKey := 65;
  LSink.Post(LEvent);
  LEvent := TGameHostEvent.Make(hekMouseDown);
  LEvent.Button := hmbLeft;
  LSink.Post(LEvent);
  Assert.IsTrue(LKeys.IsDown(65));
  Assert.IsTrue(LButtons.IsDown(hmbLeft));
  // the loss of the focus reaches both: the keys and the buttons are released
  LEvent := TGameHostEvent.Make(hekActive);
  LSink.Post(LEvent);
  Assert.IsFalse(LKeys.IsDown(65));
  Assert.IsFalse(LButtons.IsDown(hmbLeft));
  Assert.IsFalse(LButtons.IsFocused);
end;

procedure TTestGameHostEventFanOut.DovrebbeAccettareNessunAscoltatore;
var
  LSink: IGameHostEventSink;
begin
  LSink := TGameHostEventFanOut.Create([]);
  LSink.Post(TGameHostEvent.Make(hekQuit));
  Assert.Pass;
end;

procedure TTestGameHostEventFanOut.DovrebbeRifiutareUnAscoltatoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGameHostEventFanOut.Create([TGameHostKeyState.Create as IGameHostEventSink, nil]);
    end, EArgumentNilException);
end;

{ TTestGameHostCursorArea }

procedure TTestGameHostCursorArea.DovrebbeRifiutareUnaFinestraNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGameHostFactory.CreateCursorArea(nil);
    end, EArgumentNilException);
end;

procedure TTestGameHostCursorArea.NonDovrebbeAvereUnPostoPrimaCheLaFinestraEsista;
var
  LWindow: TGameHostWinWindow;
  LArea: IGameHostCursorArea;
  LX, LY: Integer;
begin
  // a window has no handle until a display sets a mode: nothing is shown here
  LWindow := TGameHostFactory.CreateWindow('test', TGameHostKeyState.Create as IGameHostEventSink, False);
  try
    LArea := TGameHostFactory.CreateCursorArea(LWindow);
    LX := 5;
    LY := 6;
    Assert.IsFalse(LArea.ClientOrigin(LX, LY));
    Assert.AreEqual(0, LX);
    Assert.AreEqual(0, LY);
    Assert.AreEqual(0, LArea.ClientWidth);
    Assert.AreEqual(0, LArea.ClientHeight);
    Assert.IsFalse(LArea.IsForeground);
    LArea := nil;
  finally
    LWindow.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameHostMouseState);
  TDUnitX.RegisterTestFixture(TTestGameHostEventFanOut);
  TDUnitX.RegisterTestFixture(TTestGameHostCursorArea);

end.
