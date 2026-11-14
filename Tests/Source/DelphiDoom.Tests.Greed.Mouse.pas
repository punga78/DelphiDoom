unit DelphiDoom.Tests.Greed.Mouse;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.Mouse,
  DelphiDoom.Tests.Greed.MenuScenarios;

type
  /// <summary>Says when the program listens, as the test decides</summary>
  TFakeInputGate = class(TInterfacedObject, IInputGate)
  public
    Allowed: Boolean;
    function IsInputAllowed: Boolean;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedMouse = class(TObject)
  strict private
    FDevice: TMenuMouseFake;
    FDeviceIntf: IMouseDevice;
    FGate: TFakeInputGate;
    FGateIntf: IInputGate;
    FMouse: TGreedMouse;
    FMouseIntf: IGreedMouse;
    procedure Build(AWithGate: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaDispositivoOSenzaFinestra;
    [Test]
    procedure DovrebbePartireAlCentroDelloSchermoENascosto;
    [Test]
    procedure DovrebbeDareLoSpostamentoDalPuntoDoveHaLasciatoIlCursore;
    [Test]
    procedure DovrebbeMisurareLaPrimaLetturaDallAngolo;
    [Test]
    procedure DovrebbeRimettereIlCursoreAlCentroDopoOgniLettura;
    [Test]
    procedure DovrebbeLeggereITreBottoni;
    [Test]
    procedure DovrebbeMuovereIlPuntatoreSoloSeMostrato;
    [Test]
    procedure DovrebbeScalareIlPuntatoreAllaFinestra;
    [Test]
    procedure DovrebbeFermareIlPuntatoreAiBordi;
    [Test]
    procedure DovrebbeDareIlClicUnaVoltaSulFronteDiSalita;
    [Test]
    procedure DovrebbeArrotondareIlPuntatoreNelClic;
    [Test]
    procedure NonDovrebbeDareClicSeIMenuNonUsanoIlMouse;
    [Test]
    procedure NonDovrebbeMostrareIlPuntatoreSeIMenuNonUsanoIlMouse;
    [Test]
    procedure NonDovrebbeLeggereSeLaFinestraNonEAttiva;
    [Test]
    procedure DovrebbeSaltareTrentacinqueLettureQuandoLaFinestraTornaAttiva;
    [Test]
    procedure NonDovrebbeMuovereIlPuntatoreSeLaFinestraNonHaMisura;
    [Test]
    procedure DovrebbeButtareLoSpostamentoConReset;
  end;

implementation

{ TFakeInputGate }

function TFakeInputGate.IsInputAllowed: Boolean;
begin
  Result := Allowed;
end;

{ TTestGreedMouse }

procedure TTestGreedMouse.Setup;
begin
  FDevice := TMenuMouseFake.Create;
  FDeviceIntf := FDevice;
  FDevice.Width := 640;
  FDevice.Height := 400;
  FGate := TFakeInputGate.Create;
  FGateIntf := FGate;
  FGate.Allowed := True;
  Build(False);
end;

procedure TTestGreedMouse.TearDown;
begin
  FMouseIntf := nil;
  FMouse := nil;
  FGateIntf := nil;
  FDeviceIntf := nil;
end;

procedure TTestGreedMouse.Build(AWithGate: Boolean);
begin
  FMouseIntf := nil;
  if AWithGate then
    FMouse := TGreedMouse.Create(FDeviceIntf, FDevice, FGateIntf)
  else
    FMouse := TGreedMouse.Create(FDeviceIntf, FDevice, nil);
  FMouseIntf := FMouse;
end;

procedure TTestGreedMouse.DovrebbeSollevareSenzaDispositivoOSenzaFinestra;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedMouse.Create(nil, FDevice, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMouse.Create(FDeviceIntf, nil, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedMouse.DovrebbePartireAlCentroDelloSchermoENascosto;
begin
  Assert.AreEqual<Single>(160, FMouse.GetPointerX);
  Assert.AreEqual<Single>(100, FMouse.GetPointerY);
  Assert.IsFalse(FMouse.IsVisible);
  Assert.IsTrue(FMouse.GetMenuEnabled, 'menuusemouse starts true');
  Assert.AreEqual(0, FMouse.Flags);
end;

procedure TTestGreedMouse.DovrebbeDareLoSpostamentoDalPuntoDoveHaLasciatoIlCursore;
begin
  FMouse.Read;
  // the cursor is now in the middle (320, 200): 25 to the right and 10 up
  FDevice.X := FDevice.X + 25;
  FDevice.Y := FDevice.Y - 10;
  FMouse.Read;
  Assert.AreEqual(-25, FMouse.GetDeltaX, 'left is positive');
  Assert.AreEqual(10, FMouse.GetDeltaY, 'up is positive');
  FMouse.Read;
  Assert.AreEqual(0, FMouse.GetDeltaX, 'the cursor was put back');
  Assert.AreEqual(0, FMouse.GetDeltaY);
end;

procedure TTestGreedMouse.DovrebbeMisurareLaPrimaLetturaDallAngolo;
begin
  // mlastx and mlasty are 0 until the first ResetMouse
  FDevice.X := 30;
  FDevice.Y := 7;
  FMouse.Read;
  Assert.AreEqual(-30, FMouse.GetDeltaX);
  Assert.AreEqual(-7, FMouse.GetDeltaY);
end;

procedure TTestGreedMouse.DovrebbeRimettereIlCursoreAlCentroDopoOgniLettura;
begin
  FDevice.X := 500;
  FDevice.Y := 17;
  FMouse.Read;
  Assert.AreEqual(320, FDevice.X);
  Assert.AreEqual(200, FDevice.Y);
  FDevice.Width := 801;
  FDevice.Height := 601;
  FMouse.Read;
  Assert.AreEqual(400, FDevice.X, 'I_WindowWidth div 2');
  Assert.AreEqual(300, FDevice.Y);
end;

procedure TTestGreedMouse.DovrebbeLeggereITreBottoni;
begin
  FDevice.Buttons := 1;
  FMouse.Read;
  Assert.IsTrue(FMouse.IsDown(gmbFire), 'the left button fires');
  Assert.IsFalse(FMouse.IsDown(gmbUse));
  Assert.IsFalse(FMouse.IsDown(gmbNorth));
  FDevice.Buttons := 2;
  FMouse.Read;
  Assert.IsTrue(FMouse.IsDown(gmbUse), 'the right button uses');
  Assert.AreEqual(GREED_MOUSE_FLAG_RIGHT, FMouse.Flags);
  Assert.AreEqual(GREED_MOUSE_FLAG_LEFT, FMouse.OldFlags);
  FDevice.Buttons := 4;
  FMouse.Read;
  Assert.IsTrue(FMouse.IsDown(gmbNorth), 'the middle button walks');
  FDevice.Buttons := 7;
  Assert.AreEqual(GREED_MOUSE_FLAG_MIDDLE, FMouse.Flags, 'the buttons change only when the mouse is read');
end;

procedure TTestGreedMouse.DovrebbeMuovereIlPuntatoreSoloSeMostrato;
begin
  FMouse.Read;
  FDevice.X := FDevice.X + 40;
  FMouse.Read;
  Assert.AreEqual<Single>(160, FMouse.GetPointerX, 'hidden: it stays');
  FMouse.Show;
  Assert.IsTrue(FMouse.IsVisible);
  FDevice.X := FDevice.X + 40;
  FDevice.Y := FDevice.Y - 20;
  FMouse.Read;
  Assert.AreEqual<Single>(180, FMouse.GetPointerX, '40 pixels of a window of 640 are 20 of the screen');
  Assert.AreEqual<Single>(90, FMouse.GetPointerY);
  FMouse.Hide;
  FDevice.X := FDevice.X + 40;
  FMouse.Read;
  Assert.AreEqual<Single>(180, FMouse.GetPointerX);
end;

procedure TTestGreedMouse.DovrebbeScalareIlPuntatoreAllaFinestra;
var
  LExpected: Single;
begin
  FDevice.Width := 800;
  FDevice.Height := 500;
  FMouse.Show;
  FMouse.Read;
  // the first reading is measured from the corner: the cursor was at 0, 0
  Assert.AreEqual<Single>(160, FMouse.GetPointerX);
  FDevice.X := FDevice.X + 7;
  FDevice.Y := FDevice.Y + 3;
  FMouse.Read;
  LExpected := 160;
  LExpected := LExpected - (-7) * 320 / 800;
  Assert.AreEqual<Single>(LExpected, FMouse.GetPointerX);
  LExpected := 100;
  LExpected := LExpected - (-3) * 200 / 500;
  Assert.AreEqual<Single>(LExpected, FMouse.GetPointerY);
end;

procedure TTestGreedMouse.DovrebbeFermareIlPuntatoreAiBordi;
begin
  FMouse.Show;
  FMouse.Read;
  FDevice.X := FDevice.X - 5000;
  FDevice.Y := FDevice.Y - 5000;
  FMouse.Read;
  Assert.AreEqual<Single>(0, FMouse.GetPointerX);
  Assert.AreEqual<Single>(0, FMouse.GetPointerY);
  FDevice.X := FDevice.X + 5000;
  FDevice.Y := FDevice.Y + 5000;
  FMouse.Read;
  Assert.AreEqual<Single>(319, FMouse.GetPointerX);
  Assert.AreEqual<Single>(199, FMouse.GetPointerY);
end;

procedure TTestGreedMouse.DovrebbeDareIlClicUnaVoltaSulFronteDiSalita;
var
  LX, LY: Integer;
begin
  FMouse.Read;
  Assert.IsFalse(FMouse.TakeClick(LX, LY), 'nothing pressed');
  FDevice.Buttons := 1;
  FMouse.Read;
  Assert.IsTrue(FMouse.TakeClick(LX, LY));
  Assert.AreEqual(160, LX);
  Assert.AreEqual(100, LY);
  Assert.IsFalse(FMouse.TakeClick(LX, LY), 'the same click is not given twice');
  FMouse.Read;
  Assert.IsFalse(FMouse.TakeClick(LX, LY), 'held down is not a click');
  FDevice.Buttons := 0;
  FMouse.Read;
  FDevice.Buttons := 3;
  FMouse.Read;
  Assert.IsTrue(FMouse.TakeClick(LX, LY), 'pressed again');
  FDevice.Buttons := 0;
  FMouse.Read;
  FDevice.Buttons := 2;
  FMouse.Read;
  Assert.IsFalse(FMouse.TakeClick(LX, LY), 'the right button is not a click');
end;

procedure TTestGreedMouse.DovrebbeArrotondareIlPuntatoreNelClic;
var
  LX, LY: Integer;
begin
  FMouse.Show;
  FMouse.Read;
  // 3 pixels of the window are 1.5 of the screen: 161.5 and 98.5 round to the even one
  FDevice.X := FDevice.X + 3;
  FDevice.Y := FDevice.Y - 3;
  FDevice.Buttons := 1;
  FMouse.Read;
  Assert.IsTrue(FMouse.TakeClick(LX, LY));
  Assert.AreEqual(162, LX);
  Assert.AreEqual(98, LY);
end;

procedure TTestGreedMouse.NonDovrebbeDareClicSeIMenuNonUsanoIlMouse;
var
  LX, LY: Integer;
begin
  FMouseIntf.MenuEnabled := False;
  FMouse.Read;
  FDevice.Buttons := 1;
  FMouse.Read;
  Assert.IsFalse(FMouse.TakeClick(LX, LY));
  Assert.IsTrue(FMouse.IsDown(gmbFire), 'the game still sees the button');
  FMouseIntf.MenuEnabled := True;
  Assert.IsTrue(FMouse.TakeClick(LX, LY), 'the click was not used up');
end;

procedure TTestGreedMouse.NonDovrebbeMostrareIlPuntatoreSeIMenuNonUsanoIlMouse;
begin
  FMouseIntf.MenuEnabled := False;
  FMouse.Show;
  Assert.IsFalse(FMouse.IsVisible);
  FMouseIntf.MenuEnabled := True;
  FMouse.Show;
  Assert.IsTrue(FMouse.IsVisible);
  FMouseIntf.MenuEnabled := False;
  Assert.IsTrue(FMouse.IsVisible, 'the setting is read by MouseShow only');
end;

procedure TTestGreedMouse.NonDovrebbeLeggereSeLaFinestraNonEAttiva;
begin
  Build(True);
  FGate.Allowed := False;
  FDevice.X := 77;
  FDevice.Y := 55;
  FDevice.Buttons := 1;
  FMouse.Read;
  Assert.AreEqual(0, FMouse.Flags);
  Assert.AreEqual(0, FMouse.GetDeltaX);
  Assert.AreEqual(77, FDevice.X, 'the cursor of the system is left alone');
end;

procedure TTestGreedMouse.DovrebbeSaltareTrentacinqueLettureQuandoLaFinestraTornaAttiva;
var
  LIndex: Integer;
begin
  Build(True);
  FDevice.X := 77;
  FDevice.Buttons := 1;
  for LIndex := 1 to GREED_MOUSE_IGNORED_READINGS do
  begin
    FMouse.Read;
    Assert.AreEqual(0, FMouse.Flags, 'reading ' + IntToStr(LIndex));
  end;
  FMouse.Read;
  Assert.AreEqual(GREED_MOUSE_FLAG_LEFT, FMouse.Flags, 'the reading after the half second');
  Assert.AreEqual(-77, FMouse.GetDeltaX);
  // the window goes away and comes back: the state stays, then another half second
  FGate.Allowed := False;
  FDevice.Buttons := 0;
  FMouse.Read;
  Assert.AreEqual(GREED_MOUSE_FLAG_LEFT, FMouse.Flags, 'the last reading stays while the window is away');
  FGate.Allowed := True;
  for LIndex := 1 to GREED_MOUSE_IGNORED_READINGS do
    FMouse.Read;
  Assert.AreEqual(GREED_MOUSE_FLAG_LEFT, FMouse.Flags);
  FMouse.Read;
  Assert.AreEqual(0, FMouse.Flags);
end;

procedure TTestGreedMouse.NonDovrebbeMuovereIlPuntatoreSeLaFinestraNonHaMisura;
begin
  FDevice.Width := 0;
  FDevice.Height := 0;
  FDevice.X := 40;
  FMouse.Show;
  FMouse.Read;
  Assert.AreEqual(-40, FMouse.GetDeltaX);
  Assert.AreEqual<Single>(160, FMouse.GetPointerX);
  Assert.AreEqual<Single>(100, FMouse.GetPointerY);
end;

procedure TTestGreedMouse.DovrebbeButtareLoSpostamentoConReset;
begin
  FMouse.Read;
  FDevice.X := FDevice.X + 90;
  FMouse.Reset;
  Assert.AreEqual(320, FDevice.X);
  FMouse.Read;
  Assert.AreEqual(0, FMouse.GetDeltaX, 'what was not read is thrown away');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMouse);

end.
