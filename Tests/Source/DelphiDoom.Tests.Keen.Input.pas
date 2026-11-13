{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the input manager                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Input;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Tests.Keen.VideoFakes, DelphiDoom.Tests.Keen.InputFakes;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenInput = class(TObject)
  strict private
    FClock: IKeenClock;
    FMouse: TFakeKeenMouse;
    FMouseIntf: IKeenMouse;
    FJoysticks: TFakeKeenJoysticks;
    FJoysticksIntf: IKeenJoysticks;
    FPump: TFakeKeenPump;
    FPumpIntf: IKeenInputPump;
    FInput: IKeenInput;
    procedure Press(AScan: Byte);
    procedure Release(AScan: Byte);
    procedure PressSpecial(AScan: Byte);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeSegnareUnTastoGiuEPoiSu;
    [Test]
    procedure DovrebbeRicordareLUltimoScanCode;
    [Test]
    procedure DovrebbeDareLAsciiDelTasto;
    [Test]
    procedure DovrebbeDareLAsciiConLoShift;
    [Test]
    procedure DovrebbeFareMaiuscoleConIlCapsLock;
    [Test]
    procedure DovrebbeFareMinuscoleConShiftECapsLock;
    [Test]
    procedure DovrebbeLasciareLAsciiDiUnTastoSenzaCarattere;
    [Test]
    procedure DovrebbeUsareLaTabellaDeiTastiConIlPrefisso;
    [Test]
    procedure DovrebbeSegnareLaPausa;
    [Test]
    procedure DovrebbeChiamareIlHookDopoOgniCodice;
    [Test]
    procedure DovrebbeNonChiamareIlHookDopoIlPrefisso;
    [Test]
    procedure DovrebbeTogliereUnTastoELUltimoScanCode;
    [Test]
    procedure DovrebbeTenereLUltimoScanSeSiTogliePiuUnAltroTasto;
    [Test]
    procedure DovrebbeAzzerareTuttiITasti;
    [Test]
    procedure DovrebbeIgnorareUnTastoFuoriTabella;
    [Test]
    procedure DovrebbeLeggereIlControlloDaTastiera;
    [TestCase('nord', '$48,0,-1,0')]
    [TestCase('sud', '$50,0,1,4')]
    [TestCase('ovest', '$4B,-1,0,6')]
    [TestCase('est', '$4D,1,0,2')]
    [TestCase('nordovest', '$47,-1,-1,7')]
    [TestCase('nordest', '$49,1,-1,1')]
    [TestCase('sudovest', '$4F,-1,1,5')]
    [TestCase('sudest', '$51,1,1,3')]
    procedure DovrebbeLeggereLeOttoDirezioniDellaTastiera(AScan, AXAxis, AYAxis, ADirection: Integer);
    [Test]
    procedure DovrebbeNonMuoversiSenzaTasti;
    [Test]
    procedure DovrebbeLeggereIPulsantiDallaTastiera;
    [Test]
    procedure DovrebbeFarVincereLaSuIlGiu;
    [Test]
    procedure DovrebbeUsareITastiScelti;
    [Test]
    procedure DovrebbeLeggereIlMouse;
    [Test]
    procedure DovrebbeLeggereIPulsantiDelMouse;
    [Test]
    procedure DovrebbeTrovareIlMouseSoloSeLoVuole;
    [Test]
    procedure DovrebbeRifiutareUnGiocatoreCheNonEsiste;
    [Test]
    procedure DovrebbeTrovareIlJoystickAlCentro;
    [Test]
    procedure DovrebbeNonTrovareUnJoystickConUnAsseA0;
    [Test]
    procedure DovrebbeNonTrovareUnJoystickConUnValoreTroppoAlto;
    [Test]
    procedure DovrebbeFareLaZonaMortaDiUnQuintoAlCentro;
    [Test]
    procedure DovrebbeLeggereIlJoystickConLaScala;
    [Test]
    procedure DovrebbeLimitareIlJoystickA127;
    [Test]
    procedure DovrebbeFareIlGiroDelleParoleNellaScalaDelJoystick;
    [Test]
    procedure DovrebbeRifiutareUnIntervalloNulloDelJoystick;
    [Test]
    procedure DovrebbeUsareIlJoystickDelSecondoGiocatore;
    [Test]
    procedure DovrebbeLeggereIlCursoreDalMouseEDalJoystick;
    [Test]
    procedure DovrebbeScalareIlCursoreDelJoystickConIlTempo;
    [Test]
    procedure DovrebbeTornareAllaTastieraSeIlDispositivoNonCe;
    [Test]
    procedure DovrebbeTenereIlDispositivoSeCe;
    [Test]
    procedure DovrebbeSpegnereMouseEJoystickConShutdown;
    [Test]
    procedure DovrebbeRegistrareUnDemo;
    [Test]
    procedure DovrebbeRifiutareUnDemoSenzaSpazio;
    [Test]
    procedure DovrebbeSuonareUnDemo;
    [Test]
    procedure DovrebbeFinireIlDemoELasciareLaLetturaALeggereIlMotoDelDemo;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaDopoLaFineDelDemo;
    [Test]
    procedure DovrebbeRifiutareDemoBytesSenzaRegistrazione;
    [Test]
    procedure DovrebbeTrovareInputDellUtente;
    [Test]
    procedure DovrebbeAspettareUnTasto;
    [Test]
    procedure DovrebbeAspettareUnCarattere;
    [Test]
    procedure DovrebbeFinireLAttesaDopoIlRitardo;
    [Test]
    procedure DovrebbeAspettareChePulsantiDelMouseSianoRilasciati;
    [Test]
    procedure DovrebbeAspettareIlPulsanteDelJoystick;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.Input, DelphiDoom.Keen.ManualClock;

{ TTestKeenInput }

procedure TTestKeenInput.Setup;
begin
  FClock := TKeenManualClock.Create(1);
  FMouse := TFakeKeenMouse.Create;
  FMouseIntf := FMouse;
  FJoysticks := TFakeKeenJoysticks.Create;
  FJoysticksIntf := FJoysticks;
  FPump := TFakeKeenPump.Create;
  FPumpIntf := FPump;
  FInput := TKeenInput.Create(FClock, FMouseIntf, FJoysticksIntf, FPumpIntf);
  FInput.SetControlType(0, kctKeyboard1);
end;

procedure TTestKeenInput.Press(AScan: Byte);
begin
  FInput.KeyService(AScan);
end;

procedure TTestKeenInput.Release(AScan: Byte);
begin
  FInput.KeyService(AScan or $80);
end;

procedure TTestKeenInput.PressSpecial(AScan: Byte);
begin
  FInput.KeyService($E0);
  FInput.KeyService(AScan);
end;

procedure TTestKeenInput.DovrebbeSegnareUnTastoGiuEPoiSu;
begin
  Assert.IsFalse(FInput.IsKeyDown(KEEN_SC_SPACE));
  Press(KEEN_SC_SPACE);
  Assert.IsTrue(FInput.IsKeyDown(KEEN_SC_SPACE));
  Release(KEEN_SC_SPACE);
  Assert.IsFalse(FInput.IsKeyDown(KEEN_SC_SPACE));
end;

procedure TTestKeenInput.DovrebbeRicordareLUltimoScanCode;
begin
  Press($1E);
  Press($30);
  Assert.AreEqual($30, Integer(FInput.LastScan));
  // a break code does not change it
  Release($30);
  Assert.AreEqual($30, Integer(FInput.LastScan));
end;

procedure TTestKeenInput.DovrebbeDareLAsciiDelTasto;
begin
  Press($1E);
  Assert.AreEqual(Ord('a'), Integer(FInput.LastAscii));
  Press($02);
  Assert.AreEqual(Ord('1'), Integer(FInput.LastAscii));
  Press(KEEN_SC_RETURN);
  Assert.AreEqual(13, Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeDareLAsciiConLoShift;
begin
  Press(KEEN_SC_LSHIFT);
  Press($1E);
  Assert.AreEqual(Ord('A'), Integer(FInput.LastAscii));
  Press($02);
  Assert.AreEqual(Ord('!'), Integer(FInput.LastAscii));
  Release(KEEN_SC_LSHIFT);
  Press(KEEN_SC_RSHIFT);
  Press($27);
  Assert.AreEqual(Ord(':'), Integer(FInput.LastAscii));
  Release(KEEN_SC_RSHIFT);
  Press($27);
  Assert.AreEqual(Ord(';'), Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeFareMaiuscoleConIlCapsLock;
begin
  Press(KEEN_SC_CAPSLOCK);
  Press($1E);
  Assert.AreEqual(Ord('A'), Integer(FInput.LastAscii));
  // the digits do not change
  Press($02);
  Assert.AreEqual(Ord('1'), Integer(FInput.LastAscii));
  Press(KEEN_SC_CAPSLOCK);
  Press($1E);
  Assert.AreEqual(Ord('a'), Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeFareMinuscoleConShiftECapsLock;
begin
  Press(KEEN_SC_CAPSLOCK);
  Press(KEEN_SC_LSHIFT);
  Press($1E);
  Assert.AreEqual(Ord('a'), Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeLasciareLAsciiDiUnTastoSenzaCarattere;
begin
  Press($1E);
  Press(KEEN_SC_LSHIFT);
  Assert.AreEqual(Ord('a'), Integer(FInput.LastAscii));
  Assert.AreEqual(KEEN_SC_LSHIFT, Integer(FInput.LastScan));
end;

procedure TTestKeenInput.DovrebbeUsareLaTabellaDeiTastiConIlPrefisso;
begin
  // the divide of the keypad is $E0 $35; without the prefix $35 is the slash of the main block, the same here
  PressSpecial($35);
  Assert.AreEqual(Ord('/'), Integer(FInput.LastAscii));
  // the arrows have the prefix and no character: the ASCII does not change
  FInput.LastAscii := 0;
  PressSpecial(KEEN_SC_UPARROW);
  Assert.AreEqual(0, Integer(FInput.LastAscii));
  Assert.IsTrue(FInput.IsKeyDown(KEEN_SC_UPARROW));
  // the enter of the keypad
  PressSpecial($1C);
  Assert.AreEqual(13, Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeSegnareLaPausa;
begin
  Assert.IsFalse(FInput.Paused);
  Press($E1);
  Assert.IsTrue(FInput.Paused);
end;

procedure TTestKeenInput.DovrebbeChiamareIlHookDopoOgniCodice;
var
  LCalls: Integer;
begin
  LCalls := 0;
  FInput.SetKeyHook(
    procedure
    begin
      Inc(LCalls);
    end);
  Press($1E);
  Release($1E);
  Press($E1);
  Assert.AreEqual(3, LCalls);
  FInput.SetKeyHook(nil);
  Press($1E);
  Assert.AreEqual(3, LCalls);
end;

procedure TTestKeenInput.DovrebbeNonChiamareIlHookDopoIlPrefisso;
var
  LCalls: Integer;
begin
  LCalls := 0;
  FInput.SetKeyHook(
    procedure
    begin
      Inc(LCalls);
    end);
  FInput.KeyService($E0);
  Assert.AreEqual(0, LCalls);
  FInput.KeyService($48);
  Assert.AreEqual(1, LCalls);
end;

procedure TTestKeenInput.DovrebbeTogliereUnTastoELUltimoScanCode;
begin
  Press($1E);
  FInput.ClearKey($1E);
  Assert.IsFalse(FInput.IsKeyDown($1E));
  Assert.AreEqual(0, Integer(FInput.LastScan));
end;

procedure TTestKeenInput.DovrebbeTenereLUltimoScanSeSiTogliePiuUnAltroTasto;
begin
  Press($1E);
  Press($30);
  FInput.ClearKey($1E);
  Assert.IsFalse(FInput.IsKeyDown($1E));
  Assert.AreEqual($30, Integer(FInput.LastScan));
end;

procedure TTestKeenInput.DovrebbeAzzerareTuttiITasti;
begin
  Press($1E);
  Press($30);
  FInput.ClearKeysDown;
  Assert.IsFalse(FInput.IsKeyDown($1E));
  Assert.IsFalse(FInput.IsKeyDown($30));
  Assert.AreEqual(0, Integer(FInput.LastScan));
  Assert.AreEqual(0, Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeIgnorareUnTastoFuoriTabella;
begin
  Assert.IsFalse(FInput.IsKeyDown(-1));
  Assert.IsFalse(FInput.IsKeyDown(200));
  FInput.ClearKey(200);
end;

procedure TTestKeenInput.DovrebbeLeggereIlControlloDaTastiera;
var
  LInfo: TKeenControlInfo;
begin
  Press(KEEN_SC_UPARROW);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(-1, Integer(LInfo.YAxis));
  Assert.AreEqual(-127, LInfo.Y);
  Assert.AreEqual(0, LInfo.X);
  Assert.AreEqual(Ord(kdNorth), Ord(LInfo.Direction));
end;

procedure TTestKeenInput.DovrebbeLeggereLeOttoDirezioniDellaTastiera(AScan, AXAxis, AYAxis, ADirection: Integer);
var
  LInfo: TKeenControlInfo;
begin
  Press(Byte(AScan));
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(AXAxis, Integer(LInfo.XAxis));
  Assert.AreEqual(AYAxis, Integer(LInfo.YAxis));
  Assert.AreEqual(AXAxis * 127, LInfo.X);
  Assert.AreEqual(AYAxis * 127, LInfo.Y);
  Assert.AreEqual(ADirection, Integer(LInfo.Direction));
end;

procedure TTestKeenInput.DovrebbeNonMuoversiSenzaTasti;
var
  LInfo: TKeenControlInfo;
begin
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(0, LInfo.X);
  Assert.AreEqual(0, LInfo.Y);
  Assert.AreEqual(Ord(kdNone), Ord(LInfo.Direction));
  Assert.IsFalse(LInfo.Button0);
  Assert.IsFalse(LInfo.Button1);
end;

procedure TTestKeenInput.DovrebbeLeggereIPulsantiDallaTastiera;
var
  LInfo: TKeenControlInfo;
begin
  // button 0 is the control, button 1 the alt
  Press(KEEN_SC_CONTROL);
  LInfo := FInput.ReadControl(0);
  Assert.IsTrue(LInfo.Button0);
  Assert.IsFalse(LInfo.Button1);
  Press(KEEN_SC_ALT);
  LInfo := FInput.ReadControl(0);
  Assert.IsTrue(LInfo.Button0);
  Assert.IsTrue(LInfo.Button1);
end;

procedure TTestKeenInput.DovrebbeFarVincereLaSuIlGiu;
var
  LInfo: TKeenControlInfo;
begin
  // the up key is read before the down key, the left before the right
  Press(KEEN_SC_UPARROW);
  Press(KEEN_SC_DOWNARROW);
  Press(KEEN_SC_LEFTARROW);
  Press(KEEN_SC_RIGHTARROW);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(-1, Integer(LInfo.YAxis));
  Assert.AreEqual(-1, Integer(LInfo.XAxis));
end;

procedure TTestKeenInput.DovrebbeUsareITastiScelti;
var
  LDef: TKeenKeyboardDef;
  LInfo: TKeenControlInfo;
begin
  LDef := FInput.KeyboardDefs[0];
  LDef.Up := $11;
  LDef.Button0 := $39;
  FInput.KeyboardDefs[0] := LDef;
  Press($11);
  Press(KEEN_SC_SPACE);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(Ord(kdNorth), Ord(LInfo.Direction));
  Assert.IsTrue(LInfo.Button0);
  Assert.WillRaise(
    procedure
    var
      LOutside: TKeenKeyboardDef;
    begin
      LOutside := FInput.KeyboardDefs[2];
    end, EKeenException);
end;

procedure TTestKeenInput.DovrebbeLeggereIlMouse;
var
  LInfo: TKeenControlInfo;
begin
  FInput.SetControlType(0, kctMouse);
  FMouse.DeltaX := -30;
  FMouse.DeltaY := 9;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(-30, LInfo.X);
  Assert.AreEqual(9, LInfo.Y);
  Assert.AreEqual(-1, Integer(LInfo.XAxis));
  Assert.AreEqual(1, Integer(LInfo.YAxis));
  Assert.AreEqual(Ord(kdSouthWest), Ord(LInfo.Direction));
end;

procedure TTestKeenInput.DovrebbeLeggereIPulsantiDelMouse;
var
  LInfo: TKeenControlInfo;
begin
  FInput.SetControlType(0, kctMouse);
  FMouse.Buttons := 2;
  LInfo := FInput.ReadControl(0);
  Assert.IsFalse(LInfo.Button0);
  Assert.IsTrue(LInfo.Button1);
  Assert.AreEqual(0, LInfo.X);
  Assert.AreEqual(Ord(kdNone), Ord(LInfo.Direction));
end;

procedure TTestKeenInput.DovrebbeTrovareIlMouseSoloSeLoVuole;
begin
  FInput.Startup(False, False);
  Assert.IsFalse(FInput.MousePresent);
  FInput.Shutdown;
  FInput.Startup(True, False);
  Assert.IsTrue(FInput.MousePresent);
end;

procedure TTestKeenInput.DovrebbeRifiutareUnGiocatoreCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FInput.ReadControl(4);
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      FInput.SetControlType(-1, kctMouse);
    end, EKeenException);
end;

procedure TTestKeenInput.DovrebbeTrovareIlJoystickAlCentro;
var
  LDef: TKeenJoystickDef;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 150;
  FInput.Startup(False, True);
  Assert.IsTrue(FInput.JoystickPresent[0]);
  Assert.IsFalse(FInput.JoystickPresent[1]);
  LDef := FInput.JoystickDefs[0];
  // the range is 0..2 * the centre, the dead zone the middle fifth of it
  Assert.AreEqual(0, Integer(LDef.JoyMinX));
  Assert.AreEqual(200, Integer(LDef.JoyMaxX));
  Assert.AreEqual(300, Integer(LDef.JoyMaxY));
  Assert.AreEqual(100 - 40, Integer(LDef.ThreshMinX));
  Assert.AreEqual(100 + 40, Integer(LDef.ThreshMaxX));
  Assert.AreEqual(150 - 60, Integer(LDef.ThreshMinY));
  Assert.AreEqual(150 + 60, Integer(LDef.ThreshMaxY));
  Assert.AreEqual(32768 div 60, Integer(LDef.JoyMultXL));
  Assert.AreEqual(32768 div 60, Integer(LDef.JoyMultXH));
  Assert.AreEqual(32768 div 90, Integer(LDef.JoyMultYL));
end;

procedure TTestKeenInput.DovrebbeNonTrovareUnJoystickConUnAsseA0;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 0;
  FJoysticks.Y[0] := 100;
  FInput.Startup(False, True);
  Assert.IsFalse(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInput.DovrebbeNonTrovareUnJoystickConUnValoreTroppoAlto;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 4991;
  FInput.Startup(False, True);
  Assert.IsFalse(FInput.JoystickPresent[0]);
  FInput.Shutdown;
  FJoysticks.Y[0] := 4990;
  FInput.Startup(False, True);
  Assert.IsTrue(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInput.DovrebbeFareLaZonaMortaDiUnQuintoAlCentro;
var
  LInfo: TKeenControlInfo;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(False, True);
  FInput.SetControlType(0, kctJoystick1);
  // the dead zone goes from 60 to 140 on each axis
  FJoysticks.X[0] := 60;
  FJoysticks.Y[0] := 140;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(0, LInfo.X);
  Assert.AreEqual(0, LInfo.Y);
  FJoysticks.X[0] := 59;
  FJoysticks.Y[0] := 141;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(Ord(kdSouthWest), Ord(LInfo.Direction));
end;

procedure TTestKeenInput.DovrebbeLeggereIlJoystickConLaScala;
var
  LInfo: TKeenControlInfo;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(False, True);
  FInput.SetControlType(0, kctJoystick1);
  // the left side: (60 - 20) * (32768 div 60) >> 8 = 40 * 546 >> 8
  FJoysticks.X[0] := 20;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(-((40 * 546) shr 8), LInfo.X);
  // the right side: (190 - 140) * 546 >> 8
  FJoysticks.X[0] := 190;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual((50 * 546) shr 8, LInfo.X);
end;

procedure TTestKeenInput.DovrebbeLimitareIlJoystickA127;
var
  LInfo: TKeenControlInfo;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(False, True);
  FInput.SetControlType(0, kctJoystick1);
  // past the end of the range the value is the end of the range
  FJoysticks.X[0] := 4000;
  FJoysticks.Y[0] := 0;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual((60 * 546) shr 8, LInfo.X);
  Assert.AreEqual(-((60 * 546) shr 8), LInfo.Y);
  // a joystick with a short range has a scale that goes over 127
  FInput.SetupJoystick(0, 0, 40, 0, 40);
  FJoysticks.X[0] := 40;
  FJoysticks.Y[0] := 0;
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(127, LInfo.X);
  Assert.AreEqual(-127, LInfo.Y);
end;

procedure TTestKeenInput.DovrebbeFareIlGiroDelleParoleNellaScalaDelJoystick;
var
  LInfo: TKeenControlInfo;
begin
  // a range of 2: the multiplier is 32768 / 1 and the product wraps at 16 bits (the C has a word there)
  FInput.SetupJoystick(0, 0, 10, 0, 10);
  FJoysticks.Present[0] := True;
  FInput.SetControlType(0, kctJoystick1);
  Assert.AreEqual(32768 div 3, Integer(FInput.JoystickDefs[0].JoyMultXL));
  FJoysticks.X[0] := 0;
  FJoysticks.Y[0] := 5;
  LInfo := FInput.ReadControl(0);
  // (3 - 0) * 10922 = 32766 >> 8 = 127
  Assert.AreEqual(-127, LInfo.X);
  FInput.SetupJoystick(0, 0, 5, 0, 5);
  Assert.AreEqual(32768 div 1, Integer(FInput.JoystickDefs[0].JoyMultXL));
  FJoysticks.X[0] := 0;
  LInfo := FInput.ReadControl(0);
  // thresholds 1 and 3 (a range of 5: 2 - 1 + 0, 2 + 1): (1 - 0) * 32768 = 32768 >> 8 = 128 -> 127
  Assert.AreEqual(-127, LInfo.X);
end;

procedure TTestKeenInput.DovrebbeRifiutareUnIntervalloNulloDelJoystick;
begin
  Assert.WillRaise(
    procedure
    begin
      FInput.SetupJoystick(0, 5, 5, 0, 100);
    end, EKeenException);
end;

procedure TTestKeenInput.DovrebbeUsareIlJoystickDelSecondoGiocatore;
var
  LInfo: TKeenControlInfo;
begin
  FJoysticks.Present[1] := True;
  FJoysticks.X[1] := 100;
  FJoysticks.Y[1] := 100;
  FInput.Startup(False, True);
  Assert.IsTrue(FInput.JoystickPresent[1]);
  FInput.SetControlType(1, kctJoystick2);
  FJoysticks.Y[1] := 190;
  FJoysticks.Buttons[1] := 3;
  LInfo := FInput.ReadControl(1);
  Assert.AreEqual(Ord(kdSouth), Ord(LInfo.Direction));
  Assert.IsTrue(LInfo.Button0);
  Assert.IsTrue(LInfo.Button1);
end;

procedure TTestKeenInput.DovrebbeLeggereIlCursoreDalMouseEDalJoystick;
var
  LInfo: TKeenControlInfo;
begin
  FMouse.DeltaX := 10;
  FMouse.DeltaY := -4;
  FMouse.Buttons := 1;
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(True, True);
  FJoysticks.Buttons[0] := 2;
  FJoysticks.X[0] := 190;
  LInfo := FInput.ReadCursor;
  Assert.IsTrue(LInfo.Button0);
  Assert.IsTrue(LInfo.Button1);
  // the joystick moves the cursor by its value / 64 (8 readings in the time scale: it is the first read)
  Assert.AreEqual(10 + (((50 * 546) shr 8) * 1) div 64, LInfo.X);
  Assert.AreEqual(-4, LInfo.Y);
end;

procedure TTestKeenInput.DovrebbeScalareIlCursoreDelJoystickConIlTempo;
var
  LInfo: TKeenControlInfo;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(False, True);
  FJoysticks.X[0] := 199;
  // the first reading: the time since the start is 0 tics, no scale
  LInfo := FInput.ReadCursor;
  Assert.AreEqual(((59 * 546) shr 8) div 64, LInfo.X);
  // 40 tics later the value is multiplied by 8 (the most), then divided by 64
  FClock.TimeCount := FClock.TimeCount + 40;
  LInfo := FInput.ReadCursor;
  Assert.AreEqual((((59 * 546) shr 8) * 8) div 64, LInfo.X);
end;

procedure TTestKeenInput.DovrebbeTornareAllaTastieraSeIlDispositivoNonCe;
begin
  FInput.Startup(True, True);
  FInput.SetDefault(True, kctJoystick1);
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FInput.Controls[0]));
  FInput.SetDefault(True, kctJoystick2);
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FInput.Controls[0]));
  FMouse.Present := False;
  FInput.Shutdown;
  FInput.Startup(True, True);
  FInput.SetDefault(True, kctMouse);
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FInput.Controls[0]));
  FInput.SetDefault(False, kctMouse);
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FInput.Controls[0]));
end;

procedure TTestKeenInput.DovrebbeTenereIlDispositivoSeCe;
begin
  FInput.Startup(True, True);
  FInput.SetDefault(True, kctMouse);
  Assert.AreEqual(Ord(kctMouse), Ord(FInput.Controls[0]));
end;

procedure TTestKeenInput.DovrebbeSpegnereMouseEJoystickConShutdown;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(True, True);
  Assert.IsTrue(FInput.MousePresent);
  FInput.Shutdown;
  Assert.IsFalse(FInput.MousePresent);
  Assert.IsFalse(FInput.JoystickPresent[0]);
end;

procedure TTestKeenInput.DovrebbeRegistrareUnDemo;
var
  LBytes: TBytes;
begin
  Assert.IsTrue(FInput.StartDemoRecord(32));
  Assert.AreEqual(Ord(kdmRecord), Ord(FInput.DemoMode));
  Press(KEEN_SC_UPARROW);
  FInput.ReadControl(0);
  FInput.ReadControl(0);
  Release(KEEN_SC_UPARROW);
  FInput.ReadControl(0);
  FInput.StopDemo;
  Assert.AreEqual(Ord(kdmOff), Ord(FInput.DemoMode));
  LBytes := FInput.DemoBytes;
  // the keyboard puts +/-127 in the packed byte: the bits go over and are cut to a byte, like in the C
  Assert.AreEqual<Integer>(4, Length(LBytes));
  Assert.AreEqual(2, Integer(LBytes[0]));
  Assert.AreEqual(Integer(Byte(((0 + 1) shl 2) or (-127 + 1))), Integer(LBytes[1]));
  Assert.AreEqual(1, Integer(LBytes[2]));
  Assert.AreEqual(Integer(Byte(((0 + 1) shl 2) or (0 + 1))), Integer(LBytes[3]));
end;

procedure TTestKeenInput.DovrebbeRifiutareUnDemoSenzaSpazio;
begin
  Assert.IsFalse(FInput.StartDemoRecord(0));
  Assert.AreEqual(Ord(kdmOff), Ord(FInput.DemoMode));
end;

procedure TTestKeenInput.DovrebbeSuonareUnDemo;
var
  LInfo: TKeenControlInfo;
begin
  // one reading: the buttons 1 (bit 4), x -1 (0 in the bits 2 and 3), y +1 (2 in the bits 0 and 1)
  FInput.StartDemoPlayback(TBytes.Create(0, $12), 2);
  Assert.AreEqual(Ord(kdmPlayback), Ord(FInput.DemoMode));
  // whatever the keys do, the demo has the control
  Press(KEEN_SC_UPARROW);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(-1, Integer(LInfo.XAxis));
  Assert.AreEqual(1, Integer(LInfo.YAxis));
  Assert.AreEqual(-1, LInfo.X);
  Assert.AreEqual(1, LInfo.Y);
  Assert.IsTrue(LInfo.Button0);
  Assert.IsFalse(LInfo.Button1);
  Assert.AreEqual(Ord(kdSouthWest), Ord(LInfo.Direction));
end;

procedure TTestKeenInput.DovrebbeFinireIlDemoELasciareLaLetturaALeggereIlMotoDelDemo;
var
  LInfo: TKeenControlInfo;
begin
  // the buttons 3 (bits 4 and 5), x +1, y 0
  FInput.StartDemoPlayback(TBytes.Create(1, $39, 0, $05), 4);
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(1, Integer(LInfo.XAxis));
  Assert.AreEqual(0, Integer(LInfo.YAxis));
  Assert.IsTrue(LInfo.Button0 and LInfo.Button1);
  FInput.ReadControl(0);
  Assert.AreEqual(Ord(kdmPlayback), Ord(FInput.DemoMode));
  LInfo := FInput.ReadControl(0);
  Assert.AreEqual(Ord(kdmPlayDone), Ord(FInput.DemoMode));
  Assert.AreEqual(0, Integer(LInfo.XAxis));
  Assert.IsTrue(LInfo.Button1 = False);
end;

procedure TTestKeenInput.DovrebbeRifiutareUnaLetturaDopoLaFineDelDemo;
begin
  FInput.StartDemoPlayback(TBytes.Create(0, $15), 2);
  FInput.ReadControl(0);
  Assert.WillRaise(
    procedure
    begin
      FInput.ReadControl(0);
    end, EKeenException);
end;

procedure TTestKeenInput.DovrebbeRifiutareDemoBytesSenzaRegistrazione;
begin
  Assert.WillRaise(
    procedure
    begin
      FInput.DemoBytes;
    end, EKeenException);
end;

procedure TTestKeenInput.DovrebbeTrovareInputDellUtente;
begin
  Assert.IsFalse(FInput.IsUserInput);
  Press($1E);
  Assert.IsTrue(FInput.IsUserInput);
  FInput.LastScan := 0;
  FInput.Startup(True, False);
  FMouse.Buttons := 1;
  Assert.IsTrue(FInput.IsUserInput);
end;

procedure TTestKeenInput.DovrebbeAspettareUnTasto;
begin
  FPump.OnPump :=
    procedure(ACall: Integer)
    begin
      if ACall = 3 then
        Press($1E);
    end;
  Assert.AreEqual($1E, Integer(FInput.WaitForKey));
  Assert.AreEqual(0, Integer(FInput.LastScan));
  Assert.AreEqual(3, FPump.Calls);
end;

procedure TTestKeenInput.DovrebbeAspettareUnCarattere;
begin
  FPump.OnPump :=
    procedure(ACall: Integer)
    begin
      if ACall = 2 then
        Press($10);
    end;
  Assert.AreEqual(Ord('q'), Integer(FInput.WaitForAscii));
  Assert.AreEqual(0, Integer(FInput.LastAscii));
end;

procedure TTestKeenInput.DovrebbeFinireLAttesaDopoIlRitardo;
begin
  Assert.IsFalse(FInput.UserInput(5, False));
  Assert.AreEqual(5, FClock.TimeCount);
end;

procedure TTestKeenInput.DovrebbeAspettareChePulsantiDelMouseSianoRilasciati;
var
  LDone: Boolean;
begin
  FInput.Startup(True, False);
  FMouse.Buttons := 1;
  FPump.OnPump :=
    procedure(ACall: Integer)
    begin
      if ACall = 4 then
        FMouse.Buttons := 0;
    end;
  LDone := FInput.UserInput(100, True);
  Assert.IsTrue(LDone);
  Assert.AreEqual(0, Integer(FMouse.Buttons));
  Assert.IsTrue(FPump.Calls >= 4);
end;

procedure TTestKeenInput.DovrebbeAspettareIlPulsanteDelJoystick;
begin
  FJoysticks.Present[0] := True;
  FJoysticks.X[0] := 100;
  FJoysticks.Y[0] := 100;
  FInput.Startup(False, True);
  FJoysticks.Buttons[0] := 1;
  FPump.OnPump :=
    procedure(ACall: Integer)
    begin
      if ACall = 5 then
        FJoysticks.Buttons[0] := 0;
    end;
  FInput.AckBack;
  Assert.AreEqual(0, Integer(FJoysticks.Buttons[0]));
  Assert.AreEqual(1, Integer(FInput.GetJoystickButtonsDebounced(0) + 1));
end;

procedure TTestKeenInput.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenInput.Create(nil, nil, nil, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenInput);

end.
