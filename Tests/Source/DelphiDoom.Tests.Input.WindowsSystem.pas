{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the input library - the calls of Windows                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.WindowsSystem;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>
  ///   Only the calls that do not change anything: the cursor is never moved (it is asked to
  ///   move only when the functions are not loaded, and then the call is refused) and the
  ///   joystick is captured with no window, which the system refuses. What the system answers
  ///   depends on the machine, so the tests look at what is always true
  /// </summary>
  [TestFixture]
  [Category('input')]
  TTestInputWindowsSystem = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereLaTastieraDelSistema;
    [Test]
    procedure DovrebbeLeggereLoStatoDiUnTasto;
    [Test]
    procedure DovrebbeRifiutareIlCursoreSenzaAprirlo;
    [Test]
    procedure DovrebbeLeggereIlCursoreDopoAverloAperto;
    [Test]
    procedure DovrebbeChiudereIlCursorePiuVolte;
    [Test]
    procedure DovrebbeChiedereIlJoystickSenzaErrori;
  end;

implementation

uses
  Winapi.Windows, DelphiDoom.Input.WindowsSystem;

{ TTestInputWindowsSystem }

procedure TTestInputWindowsSystem.DovrebbeLeggereLaTastieraDelSistema;
var
  LSystem: IKeyboardSystem;
  LStates: TKeyStates;
begin
  LSystem := TWindowsInputSystem.Create;
  FillChar(LStates, SizeOf(LStates), 0);
  if LSystem.ReadKeyboardState(LStates) then
    // the table and GetKeyState see the same state of the thread
    Assert.AreEqual(Integer(GetKeyState(VK_CAPITAL)) and 1, Integer(LStates[VK_CAPITAL]) and 1);
end;

procedure TTestInputWindowsSystem.DovrebbeLeggereLoStatoDiUnTasto;
var
  LSystem: IKeyboardSystem;
  LState: SmallInt;
begin
  LSystem := TWindowsInputSystem.Create;
  LState := LSystem.GetKeyState(VK_CAPITAL);
  // only the high bit (down) and the low bit (toggled) can be set
  Assert.AreEqual(0, Integer(LState) and $7FFE);
end;

procedure TTestInputWindowsSystem.DovrebbeRifiutareIlCursoreSenzaAprirlo;
var
  LSystem: ICursorSystem;
  LX: Integer;
  LY: Integer;
begin
  LSystem := TWindowsInputSystem.Create;
  Assert.IsFalse(LSystem.SetCursorPosition(10, 10));
  Assert.IsFalse(LSystem.GetCursorPosition(LX, LY));
  Assert.AreEqual(0, LX);
  Assert.AreEqual(0, LY);
end;

procedure TTestInputWindowsSystem.DovrebbeLeggereIlCursoreDopoAverloAperto;
var
  LSystem: ICursorSystem;
  LX: Integer;
  LY: Integer;
  LPoint: TPoint;
begin
  LSystem := TWindowsInputSystem.Create;
  LSystem.Open;
  if LSystem.GetCursorPosition(LX, LY) then
  begin
    // the cursor is on a screen: the same position GetCursorPos gives, in physical pixels
    Assert.IsTrue(GetCursorPos(LPoint));
  end;
  Assert.AreEqual(0, Integer(LSystem.GetKeyState(VK_LBUTTON)) and $7FFE);
  LSystem.Close;
  Assert.IsFalse(LSystem.SetCursorPosition(LX, LY));
end;

procedure TTestInputWindowsSystem.DovrebbeChiudereIlCursorePiuVolte;
var
  LSystem: ICursorSystem;
begin
  LSystem := TWindowsInputSystem.Create;
  LSystem.Close;
  LSystem.Open;
  LSystem.Open;
  LSystem.Close;
  LSystem.Close;
  Assert.IsFalse(LSystem.SetCursorPosition(0, 0));
end;

procedure TTestInputWindowsSystem.DovrebbeChiedereIlJoystickSenzaErrori;
var
  LSystem: IJoystickSystem;
  LReading: TJoystickReading;
begin
  LSystem := TWindowsInputSystem.Create;
  LSystem.DeviceCount;
  // no window: the system does not capture anything
  Assert.IsFalse(LSystem.Capture(0));
  LSystem.Release;
  if not LSystem.ReadPosition(LReading) then
    Assert.AreEqual(Cardinal(0), LReading.Buttons);
end;

end.
