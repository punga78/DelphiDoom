{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the mouse and the joystick as the    }
{  input manager reads them, with fake devices                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.InputDevices;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.Keen.ScriptedDevices, DelphiDoom.Tests.Keen.InputAdapters;

type
  /// <summary>A gate that a test opens and closes</summary>
  TFakeGate = class(TInterfacedObject, IInputGate)
  public
    Allowed: Boolean;
    function IsInputAllowed: Boolean;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenGatedAdapters = class(TObject)
  strict private
    FCursor: TFakeMouseDevice;
    FCursorKeeper: IMouseDevice;
    FGate: TFakeGate;
    FGateKeeper: IInputGate;
    FMouse: IKeenMouse;
    FStick: TFakeJoystickDevice;
    FStickKeeper: IJoystickDevice;
    FJoysticks: IKeenJoysticks;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure ConLaPortaChiusaIlMouseNonSiMuoveENonHaPulsanti;
    [Test]
    procedure ConLaPortaChiusaNonDovrebbeToccareIlCursore;
    [Test]
    procedure QuandoLaPortaSiApreIlCursoreDovrebbeTornareAlCentro;
    [Test]
    procedure DopoLaRiaperturaIlMovimentoDovrebbePartireDalCentro;
    [Test]
    procedure ConLaPortaChiusaIlJoystickDovrebbeStareAlCentroSenzaPulsanti;
    [Test]
    procedure ConLaPortaApertaIlJoystickDovrebbeDareLaLetturaVera;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenScriptedDevices = class(TObject)
  strict private
    FDevices: TKeenScriptedDevices;
    FKeeper: IInterface;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure IlMouseDovrebbeDareLaSommaDeiMovimentiUnaSolaVolta;
    [Test]
    procedure IPulsantiDelMouseDovrebberoRestareFinoAlCambio;
    [Test]
    procedure IlJoystickDovrebbePartireDalCentro;
    [Test]
    procedure IlJoystickDovrebbeDareLaPosizioneEIPulsanti;
    [Test]
    procedure SoloIlPrimoJoystickDovrebbeEsserci;
    [Test]
    procedure UnDispositivoAssenteDovrebbeDareZero;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenInputWithDevices = class(TObject)
  strict private
    FDevices: TKeenScriptedDevices;
    FKeeper: IInterface;
    FClock: IKeenClock;
    FInput: IKeenInput;
    procedure Build(AMouse, AJoystick, AUseMouse, AUseJoysticks: Boolean);
  public
    [Test]
    procedure DovrebbeTrovareIlMouseEIlJoystick;
    [Test]
    procedure NoMouseDovrebbeLasciareIlMouseFuori;
    [Test]
    procedure NoJoysDovrebbeLasciareIJoystickFuori;
    [Test]
    procedure SenzaDispositiviNonCeNulla;
    [Test]
    procedure UnJoystickAlLimiteNonDovrebbeEsserciSeSiLeggeZero;
    [Test]
    procedure UnJoystickConUnAssePressoloLimiteNonDovrebbeEsserci;
    [Test]
    procedure IlControlloSalvatoSulMouseSenzaMouseDovrebbeTornareATastiera;
    [Test]
    procedure IlControlloSalvatoSulMouseConIlMouseDovrebbeRestare;
    [Test]
    procedure IlControlloSalvatoSulJoystickSenzaJoystickDovrebbeTornareATastiera;
    [Test]
    procedure ReadControlConIlMouseDovrebbeDareLaDirezioneDelMovimento;
    [Test]
    procedure ReadControlConIlMouseDovrebbeDareIPulsanti;
    [Test]
    procedure ReadControlConIlMouseFermoDovrebbeDareNessunMovimento;
    [Test]
    procedure ReadControlConIlJoystickFuoriDallaZonaMortaDovrebbeMuovere;
    [Test]
    procedure ReadControlConIlJoystickAlCentroNonDovrebbeMuovere;
    [Test]
    procedure ReadCursorDovrebbeSommareMouseEJoystick;
    [Test]
    procedure AckDovrebbeFinireConUnClicDelMouse;
    [Test]
    procedure UserInputDovrebbeVedereUnPulsanteDelJoystick;
    [Test]
    procedure UserInputSenzaNullaDovrebbeScadere;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.MouseAdapter, DelphiDoom.Keen.JoystickAdapter,
  DelphiDoom.Keen.ManualClock;

{ TFakeGate }

function TFakeGate.IsInputAllowed: Boolean;
begin
  Result := Allowed;
end;

{ TTestKeenGatedAdapters }

procedure TTestKeenGatedAdapters.Setup;
begin
  FCursor := TFakeMouseDevice.Create;
  FCursorKeeper := FCursor;
  FCursor.X := 320;
  FCursor.Y := 240;
  FGate := TFakeGate.Create;
  FGateKeeper := FGate;
  FGate.Allowed := True;
  FMouse := TKeenMouseAdapter.Create(FCursorKeeper, TFakeScreenSize.Create, FGateKeeper);
  FStick := TFakeJoystickDevice.Create;
  FStickKeeper := FStick;
  FStick.Present := True;
  FStick.Reading.X := 60000;
  FStick.Reading.Y := 5000;
  FStick.Reading.Buttons := 3;
  FJoysticks := TKeenJoystickAdapter.Create(FStickKeeper, FGateKeeper);
end;

procedure TTestKeenGatedAdapters.ConLaPortaChiusaIlMouseNonSiMuoveENonHaPulsanti;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  // the first look with the gate open centres the cursor
  FMouse.GetDelta(LDeltaX, LDeltaY);
  FCursor.X := 400;
  FCursor.Down[TMouseButton.Left] := True;
  FGate.Allowed := False;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX);
  Assert.AreEqual(0, LDeltaY);
  Assert.AreEqual(0, Integer(FMouse.GetButtons));
end;

procedure TTestKeenGatedAdapters.ConLaPortaChiusaNonDovrebbeToccareIlCursore;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FGate.Allowed := False;
  FCursor.X := 5;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, FCursor.SetCalls);
  Assert.AreEqual(5, FCursor.X);
end;

procedure TTestKeenGatedAdapters.QuandoLaPortaSiApreIlCursoreDovrebbeTornareAlCentro;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FCursor.X := 17;
  FCursor.Y := 3;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  // no jump from where the cursor was
  Assert.AreEqual(0, LDeltaX);
  Assert.AreEqual(0, LDeltaY);
  Assert.AreEqual(320, FCursor.X);
  Assert.AreEqual(240, FCursor.Y);
end;

procedure TTestKeenGatedAdapters.DopoLaRiaperturaIlMovimentoDovrebbePartireDalCentro;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FMouse.GetDelta(LDeltaX, LDeltaY);
  FGate.Allowed := False;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  FGate.Allowed := True;
  FCursor.X := 900;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX);
  FCursor.X := 330;
  FCursor.Y := 235;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(10, LDeltaX);
  Assert.AreEqual(-5, LDeltaY);
end;

procedure TTestKeenGatedAdapters.ConLaPortaChiusaIlJoystickDovrebbeStareAlCentroSenzaPulsanti;
var
  LX: Word;
  LY: Word;
begin
  FGate.Allowed := False;
  FJoysticks.GetAbs(0, LX, LY);
  Assert.IsTrue((LX > 990) and (LX < 1010));
  Assert.IsTrue((LY > 990) and (LY < 1010));
  Assert.AreEqual(0, Integer(FJoysticks.GetButtons(0)));
end;

procedure TTestKeenGatedAdapters.ConLaPortaApertaIlJoystickDovrebbeDareLaLetturaVera;
var
  LX: Word;
  LY: Word;
begin
  FJoysticks.GetAbs(0, LX, LY);
  Assert.IsTrue(LX > 1800);
  Assert.IsTrue(LY < 200);
  Assert.AreEqual(3, Integer(FJoysticks.GetButtons(0)));
end;

{ TTestKeenScriptedDevices }

procedure TTestKeenScriptedDevices.Setup;
begin
  FDevices := TKeenScriptedDevices.Create(True, True);
  FKeeper := FDevices;
end;

procedure TTestKeenScriptedDevices.IlMouseDovrebbeDareLaSommaDeiMovimentiUnaSolaVolta;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FDevices.MoveMouse(3, -2);
  FDevices.MoveMouse(4, 1);
  FDevices.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(7, LDeltaX);
  Assert.AreEqual(-1, LDeltaY);
  FDevices.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX);
  Assert.AreEqual(0, LDeltaY);
end;

procedure TTestKeenScriptedDevices.IPulsantiDelMouseDovrebberoRestareFinoAlCambio;
begin
  FDevices.SetMouseButtons(5);
  Assert.AreEqual(5, Integer(FDevices.GetButtons));
  Assert.AreEqual(5, Integer(FDevices.GetButtons));
  FDevices.SetMouseButtons(15);
  Assert.AreEqual(7, Integer(FDevices.GetButtons));
end;

procedure TTestKeenScriptedDevices.IlJoystickDovrebbePartireDalCentro;
var
  LX: Word;
  LY: Word;
begin
  FDevices.GetAbs(0, LX, LY);
  Assert.AreEqual(KEEN_SCRIPT_JOYSTICK_CENTER, Integer(LX));
  Assert.AreEqual(KEEN_SCRIPT_JOYSTICK_CENTER, Integer(LY));
end;

procedure TTestKeenScriptedDevices.IlJoystickDovrebbeDareLaPosizioneEIPulsanti;
var
  LX: Word;
  LY: Word;
begin
  FDevices.SetJoystickPosition(1900, 120);
  FDevices.SetJoystickButtons(7);
  FDevices.GetAbs(0, LX, LY);
  Assert.AreEqual(1900, Integer(LX));
  Assert.AreEqual(120, Integer(LY));
  Assert.AreEqual(3, Integer(FDevices.GetButtons(0)));
end;

procedure TTestKeenScriptedDevices.SoloIlPrimoJoystickDovrebbeEsserci;
begin
  Assert.IsTrue(FDevices.IsPresent(0));
  Assert.IsFalse(FDevices.IsPresent(1));
  Assert.IsTrue(FDevices.IsPresent);
end;

procedure TTestKeenScriptedDevices.UnDispositivoAssenteDovrebbeDareZero;
var
  LNone: TKeenScriptedDevices;
  LKeeper: IInterface;
  LX: Word;
  LY: Word;
begin
  LNone := TKeenScriptedDevices.Create(False, False);
  LKeeper := LNone;
  Assert.IsFalse(LNone.IsPresent);
  Assert.IsFalse(LNone.IsPresent(0));
  LNone.GetAbs(0, LX, LY);
  Assert.AreEqual(0, Integer(LX));
  Assert.AreEqual(0, Integer(LNone.GetButtons(0)));
end;

{ TTestKeenInputWithDevices }

procedure TTestKeenInputWithDevices.Build(AMouse, AJoystick, AUseMouse, AUseJoysticks: Boolean);
begin
  FDevices := TKeenScriptedDevices.Create(AMouse, AJoystick);
  FKeeper := FDevices;
  FClock := TKeenManualClock.Create(1);
  FInput := TKeenFactory.CreateInput(FClock, FDevices, FDevices, nil);
  FInput.Startup(AUseMouse, AUseJoysticks);
end;

procedure TTestKeenInputWithDevices.DovrebbeTrovareIlMouseEIlJoystick;
begin
  Build(True, True, True, True);
  Assert.IsTrue(FInput.MousePresent);
  Assert.IsTrue(FInput.JoystickPresent[0]);
  Assert.IsFalse(FInput.JoystickPresent[1]);
end;

procedure TTestKeenInputWithDevices.NoMouseDovrebbeLasciareIlMouseFuori;
begin
  Build(True, True, False, True);
  Assert.IsFalse(FInput.MousePresent);
  Assert.IsTrue(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInputWithDevices.NoJoysDovrebbeLasciareIJoystickFuori;
begin
  Build(True, True, True, False);
  Assert.IsTrue(FInput.MousePresent);
  Assert.IsFalse(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInputWithDevices.SenzaDispositiviNonCeNulla;
begin
  Build(False, False, True, True);
  Assert.IsFalse(FInput.MousePresent);
  Assert.IsFalse(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInputWithDevices.UnJoystickAlLimiteNonDovrebbeEsserciSeSiLeggeZero;
begin
  // INL_StartJoy: an axis that reads 0 means no joystick
  FDevices := TKeenScriptedDevices.Create(False, True);
  FKeeper := FDevices;
  FDevices.SetJoystickPosition(0, 1000);
  FClock := TKeenManualClock.Create(1);
  FInput := TKeenFactory.CreateInput(FClock, FDevices, FDevices, nil);
  FInput.Startup(True, True);
  Assert.IsFalse(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInputWithDevices.UnJoystickConUnAssePressoloLimiteNonDovrebbeEsserci;
begin
  // and an axis above MaxJoyValue - 10 means that the stick is not connected (the loop of the game port ran out)
  FDevices := TKeenScriptedDevices.Create(False, True);
  FKeeper := FDevices;
  FDevices.SetJoystickPosition(1000, KEEN_MAX_JOY_VALUE - 9);
  FClock := TKeenManualClock.Create(1);
  FInput := TKeenFactory.CreateInput(FClock, FDevices, FDevices, nil);
  FInput.Startup(True, True);
  Assert.IsFalse(FInput.JoystickPresent[0]);
  FInput.Shutdown;
  FDevices.SetJoystickPosition(1000, KEEN_MAX_JOY_VALUE - 10);
  FInput := TKeenFactory.CreateInput(FClock, FDevices, FDevices, nil);
  FInput.Startup(True, True);
  Assert.IsTrue(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInputWithDevices.IlControlloSalvatoSulMouseSenzaMouseDovrebbeTornareATastiera;
begin
  Build(False, False, True, True);
  FInput.SetDefault(True, kctMouse);
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FInput.Controls[0]));
end;

procedure TTestKeenInputWithDevices.IlControlloSalvatoSulMouseConIlMouseDovrebbeRestare;
begin
  Build(True, False, True, True);
  FInput.SetDefault(True, kctMouse);
  Assert.AreEqual(Ord(kctMouse), Ord(FInput.Controls[0]));
end;

procedure TTestKeenInputWithDevices.IlControlloSalvatoSulJoystickSenzaJoystickDovrebbeTornareATastiera;
begin
  Build(True, False, True, True);
  FInput.SetDefault(True, kctJoystick1);
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FInput.Controls[0]));
end;

procedure TTestKeenInputWithDevices.ReadControlConIlMouseDovrebbeDareLaDirezioneDelMovimento;
var
  LInfo: TKeenControlInfo;
begin
  Build(True, False, True, True);
  FInput.SetControlType(0, kctMouse);
  FDevices.MoveMouse(5, -3);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(5, LInfo.X);
  Assert.AreEqual(-3, LInfo.Y);
  Assert.AreEqual(1, Integer(LInfo.XAxis));
  Assert.AreEqual(-1, Integer(LInfo.YAxis));
  Assert.AreEqual(Ord(kdNorthEast), Ord(LInfo.Direction));
end;

procedure TTestKeenInputWithDevices.ReadControlConIlMouseDovrebbeDareIPulsanti;
var
  LInfo: TKeenControlInfo;
begin
  Build(True, False, True, True);
  FInput.SetControlType(0, kctMouse);
  FDevices.SetMouseButtons(2);
  LInfo := FInput.ReadControl(0);
  Assert.IsFalse(LInfo.Button0);
  Assert.IsTrue(LInfo.Button1);
  FDevices.SetMouseButtons(1);
  LInfo := FInput.ReadControl(0);
  Assert.IsTrue(LInfo.Button0);
  Assert.IsFalse(LInfo.Button1);
end;

procedure TTestKeenInputWithDevices.ReadControlConIlMouseFermoDovrebbeDareNessunMovimento;
var
  LInfo: TKeenControlInfo;
begin
  Build(True, False, True, True);
  FInput.SetControlType(0, kctMouse);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(Ord(kdNone), Ord(LInfo.Direction));
  Assert.AreEqual(0, Integer(LInfo.XAxis));
end;

procedure TTestKeenInputWithDevices.ReadControlConIlJoystickFuoriDallaZonaMortaDovrebbeMuovere;
var
  LInfo: TKeenControlInfo;
begin
  Build(False, True, True, True);
  FInput.SetControlType(0, kctJoystick1);
  FDevices.SetJoystickPosition(1950, 1000);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(1, Integer(LInfo.XAxis));
  Assert.AreEqual(0, Integer(LInfo.YAxis));
  FDevices.SetJoystickPosition(50, 1000);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(-1, Integer(LInfo.XAxis));
end;

procedure TTestKeenInputWithDevices.ReadControlConIlJoystickAlCentroNonDovrebbeMuovere;
var
  LInfo: TKeenControlInfo;
begin
  Build(False, True, True, True);
  FInput.SetControlType(0, kctJoystick1);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(0, Integer(LInfo.XAxis));
  Assert.AreEqual(0, Integer(LInfo.YAxis));
end;

procedure TTestKeenInputWithDevices.ReadCursorDovrebbeSommareMouseEJoystick;
var
  LInfo: TKeenControlInfo;
begin
  Build(True, True, True, True);
  FDevices.MoveMouse(10, 20);
  FDevices.SetMouseButtons(1);
  FDevices.SetJoystickButtons(2);
  LInfo := FInput.ReadCursor;
  Assert.IsTrue(LInfo.X >= 10);
  Assert.IsTrue(LInfo.Y >= 20);
  Assert.IsTrue(LInfo.Button0);
  Assert.IsTrue(LInfo.Button1);
end;

procedure TTestKeenInputWithDevices.AckDovrebbeFinireConUnClicDelMouse;
var
  LDone: Boolean;
begin
  Build(True, False, True, True);
  // nothing is pressed: IN_Ack waits; the click ends it (the manual clock moves on at each wait)
  FDevices.SetMouseButtons(1);
  LDone := FInput.UserInput(5, False);
  Assert.IsTrue(LDone);
end;

procedure TTestKeenInputWithDevices.UserInputDovrebbeVedereUnPulsanteDelJoystick;
begin
  Build(False, True, True, True);
  FDevices.SetJoystickButtons(1);
  Assert.IsTrue(FInput.IsUserInput);
end;

procedure TTestKeenInputWithDevices.UserInputSenzaNullaDovrebbeScadere;
begin
  Build(True, True, True, True);
  Assert.IsFalse(FInput.UserInput(3, False));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenGatedAdapters);
  TDUnitX.RegisterTestFixture(TTestKeenScriptedDevices);
  TDUnitX.RegisterTestFixture(TTestKeenInputWithDevices);

end.
