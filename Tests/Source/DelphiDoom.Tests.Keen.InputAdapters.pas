{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the scan tables and the adapters     }
{  of the keyboard, the mouse and the joystick of Windows                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.InputAdapters;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Keen.Types,
  DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenScanTables = class(TObject)
  public
    [TestCase('a', '$1E,97,65,0')]
    [TestCase('digitoUno', '$02,49,33,0')]
    [TestCase('punto', '$34,46,62,0')]
    [TestCase('invio', '$1C,13,13,13')]
    [TestCase('divisioneDelTastierino', '$35,47,63,47')]
    [TestCase('nessuno', '$3B,0,0,0')]
    procedure DovrebbeDareIlCarattereDelTasto(AScan, APlain, AShifted, ASpecial: Integer);
    [Test]
    procedure DovrebbeNonDareNulla;
    [Test]
    procedure DovrebbeDareINomiDeiTastiLunghi;
    [Test]
    procedure DovrebbeDareINomiDiUnCarattere;
    [Test]
    procedure DovrebbeDareUnPuntoInterrogativoAiTastiSenzaNome;
  end;

  TFakeKeyboardDevice = class(TInterfacedObject, IKeyboardDevice)
  public
    States: TKeyStates;
    Refuse: Boolean;
    procedure Initialize;
    procedure Shutdown;
    function ReadState(var AStates: TKeyStates): Boolean;
    procedure SetActive(AActive: Boolean);
    function IsCapsLockOn: Boolean;
  end;

  TFakeMouseDevice = class(TInterfacedObject, IMouseDevice)
  public
    X: Integer;
    Y: Integer;
    Down: array[TMouseButton] of Boolean;
    SetCalls: Integer;
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
  end;

  TFakeScreenSize = class(TInterfacedObject, IScreenSize)
  public
    function GetWidth: Integer;
    function GetHeight: Integer;
  end;

  TFakeJoystickDevice = class(TInterfacedObject, IJoystickDevice)
  public
    Present: Boolean;
    Reading: TJoystickReading;
    Fail: Boolean;
    function Initialize: Boolean;
    procedure Shutdown;
    function Read(out AReading: TJoystickReading): Boolean;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenKeyboardPump = class(TObject)
  strict private
    FKeyboard: TFakeKeyboardDevice;
    FKeyboardIntf: IKeyboardDevice;
    FInput: IKeenInput;
    FPump: IKeenInputPump;
    procedure SetKey(AVirtualKey: Integer; ADown: Boolean);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLoScanCodeDiUnTastoPremuto;
    [Test]
    procedure DovrebbeDareIlCodiceDiRilascio;
    [Test]
    procedure DovrebbeDareIlPrefissoAiTastiSpeciali;
    [Test]
    procedure DovrebbeFarMuovereKeenConLeFrecce;
    [Test]
    procedure DovrebbeDareILetteraEIlMaiuscolo;
    [Test]
    procedure DovrebbeDareLaPausa;
    [Test]
    procedure DovrebbeNonRipetereUnTastoCheRestaGiu;
    [Test]
    procedure DovrebbeNonFareNulleSeLaTastieraNonRisponde;
    [Test]
    procedure DovrebbeDareLoScanCodeDeiTastiDelBloccoPrincipale;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenMouseAdapter = class(TObject)
  strict private
    FDevice: TFakeMouseDevice;
    FDeviceIntf: IMouseDevice;
    FMouse: IKeenMouse;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLaDistanzaDalCentro;
    [Test]
    procedure DovrebbeRiportareIlMouseAlCentro;
    [Test]
    procedure DovrebbeNonToccareIlMouseFermo;
    [Test]
    procedure DovrebbeDareIPulsantiNeiBitDelDriver;
    [Test]
    procedure DovrebbeEssereSempreCollegato;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenJoystickAdapter = class(TObject)
  strict private
    FDevice: TFakeJoystickDevice;
    FDeviceIntf: IJoystickDevice;
    FJoysticks: IKeenJoysticks;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeEssereSoloIlPrimo;
    [Test]
    procedure DovrebbeNonEsserciSeIlDispositivoNonCe;
    [Test]
    procedure DovrebbeMettereIlCentroDoveLoVuoleIlDriver;
    [Test]
    procedure DovrebbeRestareNelCampoDelPorto;
    [Test]
    procedure DovrebbeDareIDuePrimiPulsanti;
    [Test]
    procedure DovrebbeDareZeroSeLaLetturaFallisce;
  end;

implementation

uses
  DelphiDoom.Keen.ScanTables, DelphiDoom.Keen.Input, DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.KeyboardPump,
  DelphiDoom.Keen.MouseAdapter, DelphiDoom.Keen.JoystickAdapter;

{ TTestKeenScanTables }

procedure TTestKeenScanTables.DovrebbeDareIlCarattereDelTasto(AScan, APlain, AShifted, ASpecial: Integer);
begin
  Assert.AreEqual(APlain, Integer(TKeenScanTables.PlainAscii(AScan)));
  Assert.AreEqual(AShifted, Integer(TKeenScanTables.ShiftedAscii(AScan)));
  Assert.AreEqual(ASpecial, Integer(TKeenScanTables.SpecialAscii(AScan)));
end;

procedure TTestKeenScanTables.DovrebbeNonDareNulla;
begin
  Assert.AreEqual(0, Integer(TKeenScanTables.PlainAscii(-1)));
  Assert.AreEqual(0, Integer(TKeenScanTables.ShiftedAscii(128)));
  Assert.AreEqual(0, Integer(TKeenScanTables.SpecialAscii(300)));
end;

procedure TTestKeenScanTables.DovrebbeDareINomiDeiTastiLunghi;
begin
  Assert.AreEqual('Esc', string(TKeenScanTables.ScanName(KEEN_SC_ESCAPE)));
  Assert.AreEqual('Ctrl', string(TKeenScanTables.ScanName(KEEN_SC_CONTROL)));
  Assert.AreEqual('Enter', string(TKeenScanTables.ScanName(KEEN_SC_RETURN)));
  Assert.AreEqual('F10', string(TKeenScanTables.ScanName(KEEN_SC_F10)));
  Assert.AreEqual('F12', string(TKeenScanTables.ScanName(KEEN_SC_F12)));
  Assert.AreEqual('Right', string(TKeenScanTables.ScanName(KEEN_SC_RIGHTARROW)));
  Assert.AreEqual('Del', string(TKeenScanTables.ScanName(KEEN_SC_DELETE)));
end;

procedure TTestKeenScanTables.DovrebbeDareINomiDiUnCarattere;
begin
  Assert.AreEqual('A', string(TKeenScanTables.ScanName($1E)));
  Assert.AreEqual('5', string(TKeenScanTables.ScanName(6)));
  Assert.AreEqual(';', string(TKeenScanTables.ScanName($27)));
  Assert.AreEqual('"', string(TKeenScanTables.ScanName($28)));
  Assert.AreEqual('Z', string(TKeenScanTables.ScanName($2C)));
  // the keys of the keypad that the table of the long names does not have
  Assert.AreEqual('-', string(TKeenScanTables.ScanName($4A)));
  Assert.AreEqual('5', string(TKeenScanTables.ScanName($4C)));
  Assert.AreEqual('+', string(TKeenScanTables.ScanName($4E)));
end;

procedure TTestKeenScanTables.DovrebbeDareUnPuntoInterrogativoAiTastiSenzaNome;
begin
  Assert.AreEqual('?', string(TKeenScanTables.ScanName($6A)));
  Assert.AreEqual('?', string(TKeenScanTables.ScanName(200)));
  Assert.AreEqual('?', string(TKeenScanTables.ScanName(0)));
end;

{ TFakeKeyboardDevice }

procedure TFakeKeyboardDevice.Initialize;
begin
end;

procedure TFakeKeyboardDevice.Shutdown;
begin
end;

function TFakeKeyboardDevice.ReadState(var AStates: TKeyStates): Boolean;
begin
  Result := not Refuse;
  if Result then
    AStates := States;
end;

procedure TFakeKeyboardDevice.SetActive(AActive: Boolean);
begin
end;

function TFakeKeyboardDevice.IsCapsLockOn: Boolean;
begin
  Result := False;
end;

{ TFakeMouseDevice }

procedure TFakeMouseDevice.Initialize;
begin
end;

procedure TFakeMouseDevice.Shutdown;
begin
end;

procedure TFakeMouseDevice.GetPosition(out AX, AY: Integer);
begin
  AX := X;
  AY := Y;
end;

procedure TFakeMouseDevice.SetPosition(AX, AY: Integer);
begin
  X := AX;
  Y := AY;
  Inc(SetCalls);
end;

function TFakeMouseDevice.IsButtonDown(AButton: TMouseButton): Boolean;
begin
  Result := Down[AButton];
end;

{ TFakeScreenSize }

function TFakeScreenSize.GetWidth: Integer;
begin
  Result := 640;
end;

function TFakeScreenSize.GetHeight: Integer;
begin
  Result := 480;
end;

{ TFakeJoystickDevice }

function TFakeJoystickDevice.Initialize: Boolean;
begin
  Result := Present;
end;

procedure TFakeJoystickDevice.Shutdown;
begin
end;

function TFakeJoystickDevice.Read(out AReading: TJoystickReading): Boolean;
begin
  AReading := Reading;
  Result := not Fail;
end;

{ TTestKeenKeyboardPump }

procedure TTestKeenKeyboardPump.Setup;
begin
  FKeyboard := TFakeKeyboardDevice.Create;
  FKeyboardIntf := FKeyboard;
  FInput := TKeenInput.Create(TKeenManualClock.Create, nil, nil, nil);
  FPump := TKeenKeyboardPump.Create(FKeyboardIntf, FInput);
end;

procedure TTestKeenKeyboardPump.SetKey(AVirtualKey: Integer; ADown: Boolean);
begin
  if ADown then
    FKeyboard.States[AVirtualKey] := KEYSTATE_DOWN
  else
    FKeyboard.States[AVirtualKey] := 0;
end;

procedure TTestKeenKeyboardPump.DovrebbeDareLoScanCodeDiUnTastoPremuto;
begin
  SetKey(Ord('A'), True);
  FPump.Pump;
  Assert.IsTrue(FInput.IsKeyDown($1E));
  Assert.AreEqual($1E, Integer(FInput.LastScan));
  Assert.AreEqual(Ord('a'), Integer(FInput.LastAscii));
end;

procedure TTestKeenKeyboardPump.DovrebbeDareIlCodiceDiRilascio;
begin
  SetKey(Ord('A'), True);
  FPump.Pump;
  SetKey(Ord('A'), False);
  FPump.Pump;
  Assert.IsFalse(FInput.IsKeyDown($1E));
end;

procedure TTestKeenKeyboardPump.DovrebbeDareIlPrefissoAiTastiSpeciali;
var
  LExtended: Boolean;
begin
  Assert.AreEqual($48, Integer(TKeenKeyboardPump.ScanOf($26, LExtended)));
  Assert.IsTrue(LExtended);
  Assert.AreEqual($48, Integer(TKeenKeyboardPump.ScanOf($68, LExtended)));
  Assert.IsFalse(LExtended);
  Assert.AreEqual($1D, Integer(TKeenKeyboardPump.ScanOf($A3, LExtended)));
  Assert.IsTrue(LExtended);
  Assert.AreEqual(0, Integer(TKeenKeyboardPump.ScanOf($E8, LExtended)));
end;

procedure TTestKeenKeyboardPump.DovrebbeFarMuovereKeenConLeFrecce;
var
  LInfo: TKeenControlInfo;
begin
  FInput.SetControlType(0, kctKeyboard1);
  SetKey($27, True);
  SetKey($26, True);
  FPump.Pump;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(Ord(kdNorthEast), Ord(LInfo.Direction));
  // the control and the alt are the buttons
  SetKey($A2, True);
  SetKey($A4, True);
  FPump.Pump;
  LInfo := FInput.ReadControl(0);
  Assert.IsTrue(LInfo.Button0 and LInfo.Button1);
end;

procedure TTestKeenKeyboardPump.DovrebbeDareILetteraEIlMaiuscolo;
begin
  SetKey($A0, True);
  FPump.Pump;
  SetKey(Ord('Q'), True);
  FPump.Pump;
  Assert.AreEqual(Ord('Q'), Integer(FInput.LastAscii));
end;

procedure TTestKeenKeyboardPump.DovrebbeDareLaPausa;
begin
  SetKey($13, True);
  FPump.Pump;
  Assert.IsTrue(FInput.Paused);
end;

procedure TTestKeenKeyboardPump.DovrebbeNonRipetereUnTastoCheRestaGiu;
begin
  SetKey(Ord('A'), True);
  FPump.Pump;
  FInput.LastScan := 0;
  FPump.Pump;
  FPump.Pump;
  Assert.AreEqual(0, Integer(FInput.LastScan));
end;

procedure TTestKeenKeyboardPump.DovrebbeNonFareNulleSeLaTastieraNonRisponde;
begin
  FKeyboard.Refuse := True;
  SetKey(Ord('A'), True);
  FPump.Pump;
  Assert.IsFalse(FInput.IsKeyDown($1E));
end;

procedure TTestKeenKeyboardPump.DovrebbeDareLoScanCodeDeiTastiDelBloccoPrincipale;
var
  LExtended: Boolean;
begin
  Assert.AreEqual($39, Integer(TKeenKeyboardPump.ScanOf($20, LExtended)));
  Assert.AreEqual($01, Integer(TKeenKeyboardPump.ScanOf($1B, LExtended)));
  Assert.AreEqual($1C, Integer(TKeenKeyboardPump.ScanOf($0D, LExtended)));
  Assert.AreEqual($0B, Integer(TKeenKeyboardPump.ScanOf(Ord('0'), LExtended)));
  Assert.AreEqual($3B, Integer(TKeenKeyboardPump.ScanOf($70, LExtended)));
  Assert.AreEqual($59, Integer(TKeenKeyboardPump.ScanOf($7B, LExtended)));
  Assert.AreEqual($2A, Integer(TKeenKeyboardPump.ScanOf($A0, LExtended)));
  Assert.AreEqual($36, Integer(TKeenKeyboardPump.ScanOf($A1, LExtended)));
  Assert.AreEqual($3A, Integer(TKeenKeyboardPump.ScanOf($14, LExtended)));
end;

procedure TTestKeenKeyboardPump.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenKeyboardPump.Create(nil, FInput);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenKeyboardPump.Create(FKeyboardIntf, nil);
    end, EArgumentNilException);
end;

{ TTestKeenMouseAdapter }

procedure TTestKeenMouseAdapter.Setup;
begin
  FDevice := TFakeMouseDevice.Create;
  FDeviceIntf := FDevice;
  FDevice.X := 320;
  FDevice.Y := 240;
  FMouse := TKeenMouseAdapter.Create(FDeviceIntf, TFakeScreenSize.Create);
end;

procedure TTestKeenMouseAdapter.DovrebbeDareLaDistanzaDalCentro;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FDevice.X := 350;
  FDevice.Y := 200;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(30, LDeltaX);
  Assert.AreEqual(-40, LDeltaY);
end;

procedure TTestKeenMouseAdapter.DovrebbeRiportareIlMouseAlCentro;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FDevice.X := 350;
  FDevice.Y := 200;
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(320, FDevice.X);
  Assert.AreEqual(240, FDevice.Y);
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX);
end;

procedure TTestKeenMouseAdapter.DovrebbeNonToccareIlMouseFermo;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FMouse.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, FDevice.SetCalls);
end;

procedure TTestKeenMouseAdapter.DovrebbeDareIPulsantiNeiBitDelDriver;
begin
  Assert.AreEqual(0, Integer(FMouse.GetButtons));
  FDevice.Down[TMouseButton.Left] := True;
  Assert.AreEqual(1, Integer(FMouse.GetButtons));
  FDevice.Down[TMouseButton.Right] := True;
  FDevice.Down[TMouseButton.Middle] := True;
  Assert.AreEqual(7, Integer(FMouse.GetButtons));
end;

procedure TTestKeenMouseAdapter.DovrebbeEssereSempreCollegato;
begin
  Assert.IsTrue(FMouse.IsPresent);
end;

{ TTestKeenJoystickAdapter }

procedure TTestKeenJoystickAdapter.Setup;
begin
  FDevice := TFakeJoystickDevice.Create;
  FDeviceIntf := FDevice;
  FDevice.Present := True;
  FDevice.Reading.X := 32768;
  FDevice.Reading.Y := 32768;
  FJoysticks := TKeenJoystickAdapter.Create(FDeviceIntf);
end;

procedure TTestKeenJoystickAdapter.DovrebbeEssereSoloIlPrimo;
begin
  Assert.IsTrue(FJoysticks.IsPresent(0));
  Assert.IsFalse(FJoysticks.IsPresent(1));
end;

procedure TTestKeenJoystickAdapter.DovrebbeNonEsserciSeIlDispositivoNonCe;
begin
  FDevice.Present := False;
  FJoysticks := TKeenJoystickAdapter.Create(FDeviceIntf);
  Assert.IsFalse(FJoysticks.IsPresent(0));
end;

procedure TTestKeenJoystickAdapter.DovrebbeMettereIlCentroDoveLoVuoleIlDriver;
var
  LX: Word;
  LY: Word;
begin
  FJoysticks.GetAbs(0, LX, LY);
  // about 1000 with the stick at the centre, as the game port gives
  Assert.IsTrue((LX > 990) and (LX < 1010));
  Assert.IsTrue((LY > 990) and (LY < 1010));
end;

procedure TTestKeenJoystickAdapter.DovrebbeRestareNelCampoDelPorto;
var
  LX: Word;
  LY: Word;
begin
  FDevice.Reading.X := 0;
  FDevice.Reading.Y := 65535;
  FJoysticks.GetAbs(0, LX, LY);
  Assert.AreEqual(1, Integer(LX));
  Assert.AreEqual(2000, Integer(LY));
  FDevice.Reading.X := -50;
  FDevice.Reading.Y := 90000;
  FJoysticks.GetAbs(0, LX, LY);
  Assert.AreEqual(1, Integer(LX));
  Assert.AreEqual(2000, Integer(LY));
end;

procedure TTestKeenJoystickAdapter.DovrebbeDareIDuePrimiPulsanti;
begin
  FDevice.Reading.Buttons := 7;
  Assert.AreEqual(3, Integer(FJoysticks.GetButtons(0)));
  FDevice.Reading.Buttons := 4;
  Assert.AreEqual(0, Integer(FJoysticks.GetButtons(0)));
end;

procedure TTestKeenJoystickAdapter.DovrebbeDareZeroSeLaLetturaFallisce;
var
  LX: Word;
  LY: Word;
begin
  FDevice.Fail := True;
  FDevice.Reading.Buttons := 3;
  FJoysticks.GetAbs(0, LX, LY);
  Assert.AreEqual(0, Integer(LX));
  Assert.AreEqual(0, Integer(FJoysticks.GetButtons(0)));
  Assert.AreEqual(0, Integer(FJoysticks.GetButtons(1)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenScanTables);
  TDUnitX.RegisterTestFixture(TTestKeenKeyboardPump);
  TDUnitX.RegisterTestFixture(TTestKeenMouseAdapter);
  TDUnitX.RegisterTestFixture(TTestKeenJoystickAdapter);

end.
