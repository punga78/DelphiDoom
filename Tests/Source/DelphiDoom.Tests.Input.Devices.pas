{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the input library - the devices of Windows over a       }
{  fake system                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.Devices;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf,
  DelphiDoom.Tests.Input.Fakes;

type
  [TestFixture]
  [Category('input')]
  TTestInputDevices = class(TObject)
  private
    FSystem: TFakeInputSystem;
    FSystemRef: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaTastieraDalSistema;
    [Test]
    procedure DovrebbeDareLaTastieraAncheSeIlSistemaRifiuta;
    [Test]
    procedure DovrebbeLeggereIlCapsLockDalBitZero;
    [Test]
    procedure DovrebbeNonToccareIlSistemaAdAvvioEFermataDellaTastiera;
    [Test]
    procedure DovrebbeAprireEChiudereIlCursore;
    [Test]
    procedure DovrebbeLeggereEScrivereLaPosizioneDelCursore;
    [Test]
    procedure DovrebbeLeggereIPulsantiDelMouseDalSegno;
    [Test]
    procedure DovrebbeNonTrovareIlJoystickSenzaDispositivi;
    [Test]
    procedure DovrebbeCatturareIlJoystickConLaFinestra;
    [Test]
    procedure DovrebbeNonTrovareIlJoystickSeLaCatturaFallisce;
    [Test]
    procedure DovrebbeRilasciareIlJoystick;
    [Test]
    procedure DovrebbeDareLaLetturaDelJoystickSoloSeCe;
    [Test]
    procedure DovrebbeRifiutareIlSistemaNil;
    [Test]
    procedure DovrebbeCreareIDispositiviDiWindowsDallaFabbrica;
  end;

implementation

uses
  Winapi.Windows, DelphiDoom.Input.WindowsKeyboard, DelphiDoom.Input.WindowsMouse,
  DelphiDoom.Input.WindowsJoystick, DelphiDoom.Input.Factory;

{ TTestInputDevices }

procedure TTestInputDevices.Setup;
begin
  FSystem := TFakeInputSystem.Create;
  FSystemRef := FSystem as IKeyboardSystem;
end;

procedure TTestInputDevices.TearDown;
begin
  FSystem := nil;
  FSystemRef := nil;
end;

procedure TTestInputDevices.DovrebbeLeggereLaTastieraDalSistema;
var
  LKeyboard: IKeyboardDevice;
  LStates: TKeyStates;
begin
  LKeyboard := TWindowsKeyboard.Create(FSystem);
  FSystem.Keys[65] := KEYSTATE_DOWN;
  FillChar(LStates, SizeOf(LStates), 0);
  Assert.IsTrue(LKeyboard.ReadState(LStates));
  Assert.AreEqual(KEYSTATE_DOWN, Integer(LStates[65]));
  Assert.AreEqual(0, Integer(LStates[66]));
end;

procedure TTestInputDevices.DovrebbeDareLaTastieraAncheSeIlSistemaRifiuta;
var
  LKeyboard: IKeyboardDevice;
  LStates: TKeyStates;
begin
  LKeyboard := TWindowsKeyboard.Create(FSystem);
  FSystem.KeyboardAccepted := False;
  Assert.IsTrue(LKeyboard.ReadState(LStates));
end;

procedure TTestInputDevices.DovrebbeLeggereIlCapsLockDalBitZero;
var
  LKeyboard: IKeyboardDevice;
begin
  LKeyboard := TWindowsKeyboard.Create(FSystem);
  FSystem.KeyStates[VK_CAPITAL] := 1;
  Assert.IsTrue(LKeyboard.IsCapsLockOn);
  // down but not toggled
  FSystem.KeyStates[VK_CAPITAL] := SmallInt($8000);
  Assert.IsFalse(LKeyboard.IsCapsLockOn);
  Assert.AreEqual(Format('keystate %d', [VK_CAPITAL]), FSystem.Calls.Last);
end;

procedure TTestInputDevices.DovrebbeNonToccareIlSistemaAdAvvioEFermataDellaTastiera;
var
  LKeyboard: IKeyboardDevice;
begin
  LKeyboard := TWindowsKeyboard.Create(FSystem);
  LKeyboard.Initialize;
  LKeyboard.SetActive(True);
  LKeyboard.SetActive(False);
  LKeyboard.Shutdown;
  Assert.AreEqual(0, FSystem.Calls.Count);
end;

procedure TTestInputDevices.DovrebbeAprireEChiudereIlCursore;
var
  LMouse: IMouseDevice;
begin
  LMouse := TWindowsMouse.Create(FSystem);
  LMouse.Initialize;
  LMouse.Shutdown;
  Assert.AreEqual(2, FSystem.Calls.Count);
  Assert.AreEqual('open', FSystem.Calls[0]);
  Assert.AreEqual('close', FSystem.Calls[1]);
end;

procedure TTestInputDevices.DovrebbeLeggereEScrivereLaPosizioneDelCursore;
var
  LMouse: IMouseDevice;
  LX: Integer;
  LY: Integer;
begin
  LMouse := TWindowsMouse.Create(FSystem);
  FSystem.CursorX := 123;
  FSystem.CursorY := 45;
  LMouse.GetPosition(LX, LY);
  Assert.AreEqual(123, LX);
  Assert.AreEqual(45, LY);
  LMouse.SetPosition(320, 200);
  Assert.AreEqual('setcursor 320 200', FSystem.Calls.Last);
end;

procedure TTestInputDevices.DovrebbeLeggereIPulsantiDelMouseDalSegno;
var
  LMouse: IMouseDevice;
begin
  LMouse := TWindowsMouse.Create(FSystem);
  FSystem.KeyStates[VK_LBUTTON] := -1;
  FSystem.KeyStates[VK_RBUTTON] := 1; // toggled, not down
  FSystem.KeyStates[VK_MBUTTON] := SmallInt($8000);
  Assert.IsTrue(LMouse.IsButtonDown(TMouseButton.Left));
  Assert.IsFalse(LMouse.IsButtonDown(TMouseButton.Right));
  Assert.IsTrue(LMouse.IsButtonDown(TMouseButton.Middle));
end;

procedure TTestInputDevices.DovrebbeNonTrovareIlJoystickSenzaDispositivi;
var
  LJoystick: IJoystickDevice;
begin
  LJoystick := TWindowsJoystick.Create(
    function: THandle
    begin
      Result := 77;
    end,
    FSystem);
  FSystem.Devices := 0;
  FSystem.CaptureAccepted := True;
  Assert.IsFalse(LJoystick.Initialize);
  Assert.IsFalse(FSystem.Calls.Contains('capture'));
end;

procedure TTestInputDevices.DovrebbeCatturareIlJoystickConLaFinestra;
var
  LJoystick: IJoystickDevice;
begin
  LJoystick := TWindowsJoystick.Create(
    function: THandle
    begin
      Result := 77;
    end,
    FSystem);
  FSystem.Devices := 16;
  FSystem.CaptureAccepted := True;
  Assert.IsTrue(LJoystick.Initialize);
  Assert.AreEqual(THandle(77), FSystem.CapturedWindow);
end;

procedure TTestInputDevices.DovrebbeNonTrovareIlJoystickSeLaCatturaFallisce;
var
  LJoystick: IJoystickDevice;
begin
  LJoystick := TWindowsJoystick.Create(
    function: THandle
    begin
      Result := 0;
    end,
    FSystem);
  FSystem.Devices := 16;
  FSystem.CaptureAccepted := False;
  Assert.IsFalse(LJoystick.Initialize);
end;

procedure TTestInputDevices.DovrebbeRilasciareIlJoystick;
var
  LJoystick: IJoystickDevice;
begin
  LJoystick := TWindowsJoystick.Create(
    function: THandle
    begin
      Result := 0;
    end,
    FSystem);
  LJoystick.Shutdown;
  Assert.AreEqual('release', FSystem.Calls.Last);
end;

procedure TTestInputDevices.DovrebbeDareLaLetturaDelJoystickSoloSeCe;
var
  LJoystick: IJoystickDevice;
  LReading: TJoystickReading;
begin
  LJoystick := TWindowsJoystick.Create(
    function: THandle
    begin
      Result := 0;
    end,
    FSystem);
  FSystem.Reading.ButtonCount := 4;
  FSystem.Reading.Buttons := 5;
  FSystem.Reading.X := 1000;
  FSystem.Reading.Y := 2000;
  FSystem.ReadingAvailable := True;
  Assert.IsTrue(LJoystick.Read(LReading));
  Assert.AreEqual(Cardinal(4), LReading.ButtonCount);
  Assert.AreEqual(Cardinal(5), LReading.Buttons);
  Assert.AreEqual(1000, LReading.X);
  Assert.AreEqual(2000, LReading.Y);

  FSystem.ReadingAvailable := False;
  FSystem.Reading.X := 9;
  LReading.X := 55;
  Assert.IsFalse(LJoystick.Read(LReading));
  Assert.AreEqual(55, LReading.X);
end;

procedure TTestInputDevices.DovrebbeRifiutareIlSistemaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWindowsKeyboard.Create(nil).Free;
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TWindowsMouse.Create(nil).Free;
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TWindowsJoystick.Create(nil, FSystem).Free;
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TWindowsJoystick.Create(
        function: THandle
        begin
          Result := 0;
        end,
        nil).Free;
    end,
    EArgumentNilException);
end;

procedure TTestInputDevices.DovrebbeCreareIDispositiviDiWindowsDallaFabbrica;
var
  LKeyboard: IKeyboardDevice;
  LMouse: IMouseDevice;
  LJoystick: IJoystickDevice;
begin
  LKeyboard := TInputFactory.CreateWindowsKeyboard;
  LMouse := TInputFactory.CreateWindowsMouse;
  LJoystick := TInputFactory.CreateWindowsJoystick(
    function: THandle
    begin
      Result := 0;
    end);
  Assert.IsTrue(Assigned(LKeyboard));
  Assert.IsTrue(Assigned(LMouse));
  Assert.IsTrue(Assigned(LJoystick));
end;

end.
