{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the input library - the poller                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.Poller;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Input.Types,
  DelphiDoom.Input.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Tests.Input.Fakes;

type
  [TestFixture]
  [Category('input')]
  TTestInputPoller = class(TObject)
  private
    FCalls: TList<string>;
    FKeyboard: TFakeKeyboard;
    FMouse: TFakeMouse;
    FJoystick: TFakeJoystick;
    FGate: TFakeGate;
    FSink: TFakeSink;
    FKeyboardIntf: IKeyboardDevice;
    FMouseIntf: IMouseDevice;
    FJoystickIntf: IJoystickDevice;
    FGateIntf: IInputGate;
    FSinkIntf: IInputEventSink;
    FRecorder: TLogRecorder;
    FRecorderIntf: ILogSink;
    FPoller: IInputPoller;
    procedure MakePoller;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestKeyGoingDownPostsKeyDown;
    [Test]
    procedure TestKeyGoingUpPostsKeyUp;
    [Test]
    procedure TestNothingChangedPostsNoKey;
    [Test]
    procedure TestKeyWithoutCodeInTheGameIsNotPosted;
    [Test]
    procedure TestModifierIsPostedAsASecondEvent;
    [Test]
    procedure TestClosedGatePostsNothing;
    [Test]
    procedure TestLostKeyboardPostsNothingAndLeavesTheMouse;
    [Test]
    procedure TestAfterTheFocusTheFirstTicsAreIgnored;
    [Test]
    procedure TestSynchronizeTellsTheKeyboard;
    [Test]
    procedure TestMouseEventHasTheDistanceFromTheCentre;
    [Test]
    procedure TestMouseButtonsAreCollected;
    [Test]
    procedure TestMouseGoesBackToTheCentreAndButtonsClear;
    [Test]
    procedure TestMouseClicksSetAndClear;
    [Test]
    procedure TestJoystickEventHasTheDistanceFromTheStart;
    [Test]
    procedure TestJoystickButtonsAreMasked;
    [Test]
    procedure TestJoystickWithoutButtonsHasNoButtons;
    [Test]
    procedure TestNoJoystickNoJoystickEvent;
    [Test]
    procedure TestInitializeStartsTheDevicesAndTells;
    [Test]
    procedure TestInitializeWithoutJoystickTells;
    [Test]
    procedure TestShutdownStopsTheDevices;
    [Test]
    procedure TestCapsLockComesFromTheKeyboard;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.Input.Factory;

{ TTestInputPoller }

procedure TTestInputPoller.Setup;
begin
  FCalls := TList<string>.Create;
  FKeyboard := TFakeKeyboard.Create(FCalls);
  FMouse := TFakeMouse.Create(FCalls);
  FJoystick := TFakeJoystick.Create(FCalls);
  FGate := TFakeGate.Create;
  FGate.Allowed := True;
  FSink := TFakeSink.Create;
  FKeyboardIntf := FKeyboard;
  FMouseIntf := FMouse;
  FJoystickIntf := FJoystick;
  FGateIntf := FGate;
  FSinkIntf := FSink;
  FRecorder := TLogRecorder.Create;
  FRecorderIntf := FRecorder;
  FMouse.X := 320;
  FMouse.Y := 200;
  MakePoller;
end;

procedure TTestInputPoller.MakePoller;
begin
  FPoller := TInputFactory.CreatePoller(FKeyboardIntf, FMouseIntf, FJoystickIntf, FGateIntf,
    TFakeScreen.Create, TFakeKeyMap.Create, FSinkIntf,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderIntf), nil), 12);
end;

procedure TTestInputPoller.TearDown;
begin
  FPoller := nil;
  FRecorderIntf := nil;
  FRecorder := nil;
  FSinkIntf := nil;
  FGateIntf := nil;
  FJoystickIntf := nil;
  FMouseIntf := nil;
  FKeyboardIntf := nil;
  FSink := nil;
  FGate := nil;
  FJoystick := nil;
  FMouse := nil;
  FKeyboard := nil;
  FreeAndNil(FCalls);
end;

procedure TTestInputPoller.TestKeyGoingDownPostsKeyDown;
begin
  FPoller.Initialize;
  FKeyboard.Keys[65] := KEYSTATE_DOWN;
  FPoller.Process;
  Assert.AreEqual(2, FSink.Events.Count); // the key and the mouse
  Assert.AreEqual(Ord(TInputEventKind.KeyDown), Ord(FSink.Events[0].Kind));
  Assert.AreEqual(1065, FSink.Events[0].Data1);
end;

procedure TTestInputPoller.TestKeyGoingUpPostsKeyUp;
begin
  FPoller.Initialize;
  FKeyboard.Keys[65] := KEYSTATE_DOWN;
  FPoller.Process;
  FSink.Events.Clear;
  FKeyboard.Keys[65] := 0;
  FPoller.Process;
  Assert.AreEqual(Ord(TInputEventKind.KeyUp), Ord(FSink.Events[0].Kind));
  Assert.AreEqual(1065, FSink.Events[0].Data1);
end;

procedure TTestInputPoller.TestNothingChangedPostsNoKey;
begin
  FPoller.Initialize;
  FKeyboard.Keys[65] := KEYSTATE_DOWN;
  FPoller.Process;
  FSink.Events.Clear;
  FPoller.Process;
  Assert.AreEqual(1, FSink.Events.Count); // only the mouse
  Assert.AreEqual(Ord(TInputEventKind.Mouse), Ord(FSink.Events[0].Kind));
end;

procedure TTestInputPoller.TestKeyWithoutCodeInTheGameIsNotPosted;
begin
  FPoller.Initialize;
  FKeyboard.Keys[99] := KEYSTATE_DOWN;
  FPoller.Process;
  Assert.AreEqual(1, FSink.Events.Count);
end;

procedure TTestInputPoller.TestModifierIsPostedAsASecondEvent;
begin
  FPoller.Initialize;
  FKeyboard.Keys[16] := KEYSTATE_DOWN;
  FPoller.Process;
  Assert.AreEqual(3, FSink.Events.Count);
  Assert.AreEqual(1016, FSink.Events[0].Data1);
  Assert.AreEqual(5000, FSink.Events[1].Data1);
end;

procedure TTestInputPoller.TestClosedGatePostsNothing;
begin
  FPoller.Initialize;
  FGate.Allowed := False;
  FKeyboard.Keys[65] := KEYSTATE_DOWN;
  FPoller.Process;
  Assert.AreEqual(0, FSink.Events.Count);
end;

procedure TTestInputPoller.TestLostKeyboardPostsNothingAndLeavesTheMouse;
var
  LPlaced: Integer;
begin
  FPoller.Initialize;
  LPlaced := FMouse.Placed.Count;
  FKeyboard.Available := False;
  FPoller.Process;
  Assert.AreEqual(0, FSink.Events.Count);
  Assert.AreEqual(LPlaced, FMouse.Placed.Count);
end;

procedure TTestInputPoller.TestAfterTheFocusTheFirstTicsAreIgnored;
var
  LIndex: Integer;
begin
  FPoller.Initialize;
  FPoller.Synchronize(True);
  for LIndex := 1 to 15 do
    FPoller.Process;
  Assert.AreEqual(0, FSink.Events.Count);
  FPoller.Process;
  Assert.AreEqual(1, FSink.Events.Count);
end;

procedure TTestInputPoller.TestSynchronizeTellsTheKeyboard;
begin
  FPoller.Synchronize(True);
  Assert.AreEqual(1, FKeyboard.Active);
  FPoller.Synchronize(False);
  Assert.AreEqual(0, FKeyboard.Active);
end;

procedure TTestInputPoller.TestMouseEventHasTheDistanceFromTheCentre;
begin
  FPoller.Initialize;
  FMouse.X := 330;
  FMouse.Y := 195;
  FPoller.Process;
  Assert.AreEqual(Ord(TInputEventKind.Mouse), Ord(FSink.Events[0].Kind));
  Assert.AreEqual(-10, FSink.Events[0].Data2);
  Assert.AreEqual(5, FSink.Events[0].Data3);
end;

procedure TTestInputPoller.TestMouseButtonsAreCollected;
begin
  FPoller.Initialize;
  FMouse.Buttons[TMouseButton.Left] := True;
  FMouse.Buttons[TMouseButton.Middle] := True;
  FPoller.Process;
  Assert.AreEqual(MOUSEBUTTON_LEFT or MOUSEBUTTON_MIDDLE, FSink.Events[0].Data1);
end;

procedure TTestInputPoller.TestMouseGoesBackToTheCentreAndButtonsClear;
begin
  FPoller.Initialize;
  FMouse.Buttons[TMouseButton.Right] := True;
  FPoller.Process;
  FMouse.Buttons[TMouseButton.Right] := False;
  FSink.Events.Clear;
  FPoller.Process;
  Assert.AreEqual(320, FMouse.Placed.Last.X);
  Assert.AreEqual(200, FMouse.Placed.Last.Y);
  Assert.AreEqual(0, FSink.Events[0].Data1);
end;

procedure TTestInputPoller.TestMouseClicksSetAndClear;
begin
  FPoller.Initialize;
  FPoller.SetMouseClicks(3);
  FPoller.SetMouseClicks(-1);
  FPoller.Process;
  Assert.AreEqual(2, FSink.Events[0].Data1);
end;

procedure TTestInputPoller.TestJoystickEventHasTheDistanceFromTheStart;
begin
  FJoystick.Present := True;
  FJoystick.Reading.ButtonCount := 4;
  FJoystick.Reading.X := 1000;
  FJoystick.Reading.Y := 2000;
  FPoller.Initialize;
  FJoystick.Reading.X := 1300;
  FJoystick.Reading.Y := 1900;
  FPoller.Process;
  Assert.AreEqual(Ord(TInputEventKind.Joystick), Ord(FSink.Events.Last.Kind));
  Assert.AreEqual(300, FSink.Events.Last.Data2);
  Assert.AreEqual(-100, FSink.Events.Last.Data3);
end;

procedure TTestInputPoller.TestJoystickButtonsAreMasked;
begin
  FJoystick.Present := True;
  FJoystick.Reading.ButtonCount := 16;
  FPoller.Initialize;
  FJoystick.Reading.Buttons := $FFFF;
  FPoller.Process;
  Assert.AreEqual($FFF, FSink.Events.Last.Data1);
end;

procedure TTestInputPoller.TestJoystickWithoutButtonsHasNoButtons;
begin
  FJoystick.Present := True;
  FJoystick.Reading.ButtonCount := 0;
  FPoller.Initialize;
  FJoystick.Reading.Buttons := $FF;
  FPoller.Process;
  Assert.AreEqual(0, FSink.Events.Last.Data1);
end;

procedure TTestInputPoller.TestNoJoystickNoJoystickEvent;
begin
  FPoller.Initialize;
  FPoller.Process;
  Assert.AreEqual(1, FSink.Events.Count);
  Assert.AreEqual(Ord(TInputEventKind.Mouse), Ord(FSink.Events[0].Kind));
end;

procedure TTestInputPoller.TestInitializeStartsTheDevicesAndTells;
begin
  FJoystick.Present := True;
  FPoller.Initialize;
  Assert.AreEqual('mouse.initialize', FCalls[0]);
  Assert.AreEqual('keyboard.initialize', FCalls[1]);
  Assert.AreEqual('joystick.initialize', FCalls[2]);
  Assert.AreEqual(' Keyboard initialized'#13#10' Mouse initialized'#13#10' Joystick initialized'#13#10,
    FRecorder.TextOf(TLogChannel.Output));
end;

procedure TTestInputPoller.TestInitializeWithoutJoystickTells;
begin
  FPoller.Initialize;
  Assert.IsTrue(Pos(' Joystick not found', FRecorder.TextOf(TLogChannel.Output)) > 0);
end;

procedure TTestInputPoller.TestShutdownStopsTheDevices;
begin
  FPoller.Shutdown;
  Assert.AreEqual(3, FCalls.Count);
  Assert.IsTrue(FCalls.Contains('keyboard.shutdown'));
  Assert.IsTrue(FCalls.Contains('joystick.shutdown'));
  Assert.IsTrue(FCalls.Contains('mouse.shutdown'));
end;

procedure TTestInputPoller.TestCapsLockComesFromTheKeyboard;
begin
  Assert.IsFalse(FPoller.IsCapsLockOn);
  FKeyboard.Caps := True;
  Assert.IsTrue(FPoller.IsCapsLockOn);
end;

end.
