unit DelphiDoom.Tests.Greed.JoystickControls;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Mouse.Intf,
  DelphiDoom.Greed.Mouse, DelphiDoom.Greed.MouseControls, DelphiDoom.Greed.JoystickControls,
  DelphiDoom.Tests.Greed.MenuScenarios, DelphiDoom.Tests.Greed.GameFakes;

type
  /// <summary>A joystick that says what the test wants</summary>
  TFakeGreedJoystick = class(TInterfacedObject, IJoystickDevice)
  public
    Present: Boolean;
    Fails: Boolean;
    Reading: TJoystickReading;
    Initialized: Integer;
    Stopped: Integer;
    Reads: Integer;
    function Initialize: Boolean;
    procedure Shutdown;
    function Read(out AReading: TJoystickReading): Boolean;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedJoystickControls = class(TObject)
  strict private
    FKeys: TFakeCommandSource;
    FKeysIntf: IGreedCommandSource;
    FJoystick: TFakeGreedJoystick;
    FJoystickIntf: IJoystickDevice;
    FControls: IGreedCommandSource;
    procedure Build;
    procedure Stick(AX, AY: Integer; AButtons: Cardinal = 0);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaTastiOSenzaJoystick;
    [Test]
    procedure DovrebbeAvereLeOpzioniDiInitDefaults;
    [Test]
    procedure DovrebbeAvviareEFermareIlJoystick;
    [Test]
    procedure NonDovrebbePremereNullaSenzaJoystick;
    [Test]
    procedure NonDovrebbePremereNullaConLaLevaAlCentro;
    [Test]
    procedure DovrebbeDareLeQuattroDirezioniOltreLaSoglia;
    [Test]
    procedure DovrebbeMisurareDalPuntoDellaPrimaLettura;
    [Test]
    procedure DovrebbeDareIComandiDeiPrimiDueBottoni;
    [Test]
    procedure DovrebbeUsareIComandiDelleOpzioni;
    [Test]
    procedure DovrebbeUnireITastiAlJoystick;
    [Test]
    procedure NonDovrebbePremereNullaSeLaLetturaFallisce;
    [Test]
    procedure DovrebbeLasciarePassareCaratteriEMouse;
  end;

implementation

const
  CENTER = 32767;

{ TFakeGreedJoystick }

function TFakeGreedJoystick.Initialize: Boolean;
begin
  Inc(Initialized);
  Result := Present;
end;

procedure TFakeGreedJoystick.Shutdown;
begin
  Inc(Stopped);
end;

function TFakeGreedJoystick.Read(out AReading: TJoystickReading): Boolean;
begin
  Inc(Reads);
  Result := not Fails;
  if Result then
    AReading := Reading;
end;

{ TTestGreedJoystickControls }

procedure TTestGreedJoystickControls.Setup;
begin
  FKeys := TFakeCommandSource.Create;
  FKeysIntf := FKeys;
  FJoystick := TFakeGreedJoystick.Create;
  FJoystickIntf := FJoystick;
  FJoystick.Present := True;
  Stick(CENTER, CENTER);
  Build;
end;

procedure TTestGreedJoystickControls.TearDown;
begin
  FControls := nil;
  FJoystickIntf := nil;
  FKeysIntf := nil;
end;

procedure TTestGreedJoystickControls.Build;
begin
  FControls := nil;
  FControls := TGreedJoystickControls.Create(FKeysIntf, FJoystickIntf, TGreedJoystickOptions.Standard);
end;

procedure TTestGreedJoystickControls.Stick(AX, AY: Integer; AButtons: Cardinal);
begin
  FJoystick.Reading.ButtonCount := 4;
  FJoystick.Reading.X := AX;
  FJoystick.Reading.Y := AY;
  FJoystick.Reading.Buttons := AButtons;
end;

procedure TTestGreedJoystickControls.DovrebbeSollevareSenzaTastiOSenzaJoystick;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedJoystickControls.Create(nil, FJoystickIntf, TGreedJoystickOptions.Standard);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedJoystickControls.Create(FKeysIntf, nil, TGreedJoystickOptions.Standard);
    end, EArgumentNilException);
end;

procedure TTestGreedJoystickControls.DovrebbeAvereLeOpzioniDiInitDefaults;
var
  LOptions: TGreedJoystickOptions;
begin
  // SC.joybut1 := bt_fire; SC.joybut2 := bt_straf
  LOptions := TGreedJoystickOptions.Standard;
  Assert.AreEqual(Ord(gcFire), Ord(LOptions.Button1));
  Assert.AreEqual(Ord(gcStrafe), Ord(LOptions.Button2));
  Assert.AreEqual(GREED_JOYSTICK_THRESHOLD, LOptions.Threshold);
end;

procedure TTestGreedJoystickControls.DovrebbeAvviareEFermareIlJoystick;
begin
  Assert.AreEqual(1, FJoystick.Initialized);
  Assert.IsTrue((FControls as TGreedJoystickControls).Installed);
  FControls := nil;
  Assert.AreEqual(1, FJoystick.Stopped);
end;

procedure TTestGreedJoystickControls.NonDovrebbePremereNullaSenzaJoystick;
begin
  FJoystick.Present := False;
  Build;
  Assert.IsFalse((FControls as TGreedJoystickControls).Installed);
  Stick(0, 0, 3);
  FControls.BeginReading;
  Assert.AreEqual(0, FJoystick.Reads, 'a joystick that is not there is not read');
  Assert.IsFalse(FControls.IsPressed(gcFire));
  Assert.IsFalse(FControls.IsPressed(gcWest));
  FControls := nil;
  Assert.AreEqual(1, FJoystick.Stopped, 'only the joystick that started is stopped');
end;

procedure TTestGreedJoystickControls.NonDovrebbePremereNullaConLaLevaAlCentro;
var
  LCommand: TGreedCommand;
begin
  FControls.BeginReading;
  Stick(CENTER + GREED_JOYSTICK_THRESHOLD - 1, CENTER - GREED_JOYSTICK_THRESHOLD + 1);
  FControls.BeginReading;
  for LCommand := Low(TGreedCommand) to High(TGreedCommand) do
    Assert.IsFalse(FControls.IsPressed(LCommand));
end;

procedure TTestGreedJoystickControls.DovrebbeDareLeQuattroDirezioniOltreLaSoglia;
begin
  FControls.BeginReading;
  Stick(CENTER - GREED_JOYSTICK_THRESHOLD, CENTER);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcWest));
  Assert.IsFalse(FControls.IsPressed(gcEast));
  Assert.IsFalse(FControls.IsPressed(gcNorth));
  Stick(CENTER + GREED_JOYSTICK_THRESHOLD, CENTER - GREED_JOYSTICK_THRESHOLD);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcEast));
  Assert.IsTrue(FControls.IsPressed(gcNorth));
  Assert.IsFalse(FControls.IsPressed(gcWest), 'the reading before is forgotten');
  Stick(CENTER, 65535);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcSouth));
  Assert.IsFalse(FControls.IsPressed(gcNorth));
  Assert.IsFalse(FControls.IsPressed(gcEast));
end;

procedure TTestGreedJoystickControls.DovrebbeMisurareDalPuntoDellaPrimaLettura;
begin
  // a stick that rests away from the middle of its range: jcenx and jceny are where it is at the start
  Stick(50000, 10000);
  FControls.BeginReading;
  Assert.IsFalse(FControls.IsPressed(gcEast));
  Assert.IsFalse(FControls.IsPressed(gcNorth));
  Stick(50000 - GREED_JOYSTICK_THRESHOLD, 10000 + GREED_JOYSTICK_THRESHOLD);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcWest));
  Assert.IsTrue(FControls.IsPressed(gcSouth));
end;

procedure TTestGreedJoystickControls.DovrebbeDareIComandiDeiPrimiDueBottoni;
begin
  Stick(CENTER, CENTER, 1);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcFire));
  Assert.IsFalse(FControls.IsPressed(gcStrafe));
  Stick(CENTER, CENTER, 2);
  FControls.BeginReading;
  Assert.IsFalse(FControls.IsPressed(gcFire));
  Assert.IsTrue(FControls.IsPressed(gcStrafe));
  Stick(CENTER, CENTER, 12);
  FControls.BeginReading;
  Assert.IsFalse(FControls.IsPressed(gcFire), 'the other buttons do nothing');
  Assert.IsFalse(FControls.IsPressed(gcStrafe));
end;

procedure TTestGreedJoystickControls.DovrebbeUsareIComandiDelleOpzioni;
var
  LOptions: TGreedJoystickOptions;
begin
  LOptions := TGreedJoystickOptions.Standard;
  LOptions.Button1 := gcJump;
  LOptions.Button2 := gcUse;
  LOptions.Threshold := 100;
  FControls := nil;
  FControls := TGreedJoystickControls.Create(FKeysIntf, FJoystickIntf, LOptions);
  FControls.BeginReading;
  Stick(CENTER + 100, CENTER, 3);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcJump));
  Assert.IsTrue(FControls.IsPressed(gcUse));
  Assert.IsTrue(FControls.IsPressed(gcEast));
  Assert.IsFalse(FControls.IsPressed(gcFire));
end;

procedure TTestGreedJoystickControls.DovrebbeUnireITastiAlJoystick;
begin
  FKeys.Pressed := [gcRun, gcFire];
  Stick(CENTER, CENTER, 2);
  FControls.BeginReading;
  Assert.AreEqual(1, FKeys.Readings, 'the keys are read with the joystick');
  Assert.IsTrue(FControls.IsPressed(gcRun), 'from the keys');
  Assert.IsTrue(FControls.IsPressed(gcFire), 'from the keys');
  Assert.IsTrue(FControls.IsPressed(gcStrafe), 'from the joystick');
  Assert.IsFalse(FControls.IsPressed(gcUse));
end;

procedure TTestGreedJoystickControls.NonDovrebbePremereNullaSeLaLetturaFallisce;
begin
  Stick(CENTER, CENTER, 1);
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcFire));
  FJoystick.Fails := True;
  FControls.BeginReading;
  Assert.IsFalse(FControls.IsPressed(gcFire), 'the joystick was unplugged');
end;

procedure TTestGreedJoystickControls.DovrebbeLasciarePassareCaratteriEMouse;
var
  LDevice: TMenuMouseFake;
  LDeviceIntf: IMouseDevice;
  LMouse: IGreedMouse;
  LCharacter: Char;
  LDeltaX, LDeltaY: Integer;
begin
  LDevice := TMenuMouseFake.Create;
  LDeviceIntf := LDevice;
  LDevice.Width := 640;
  LDevice.Height := 400;
  LMouse := TGreedMouse.Create(LDeviceIntf, LDevice, nil);
  FControls := nil;
  FControls := TGreedJoystickControls.Create(TGreedMouseControls.Create(FKeysIntf, LMouse), FJoystickIntf,
    TGreedJoystickOptions.Standard);
  FKeys.Typed := 'Q';
  FControls.BeginReading;
  LDevice.X := LDevice.X - 8;
  LDevice.Y := LDevice.Y - 2;
  LDevice.Buttons := 1;
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsMousePressed(gmbFire));
  FControls.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(8, LDeltaX);
  Assert.AreEqual(2, LDeltaY);
  Assert.IsTrue(FControls.TakeTyped(LCharacter));
  Assert.AreEqual('Q', LCharacter);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedJoystickControls);

end.
