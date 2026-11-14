unit DelphiDoom.Tests.Greed.MouseControls;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Intf, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Settings,
  DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.Mouse, DelphiDoom.Greed.MouseControls,
  DelphiDoom.Greed.MouseSettings, DelphiDoom.Tests.Greed.MenuScenarios, DelphiDoom.Tests.Greed.GameFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMouseControls = class(TObject)
  strict private
    FKeys: TFakeCommandSource;
    FKeysIntf: IGreedCommandSource;
    FDevice: TMenuMouseFake;
    FDeviceIntf: IMouseDevice;
    FMouse: IGreedMouse;
    FControls: IGreedCommandSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaTastiOSenzaMouse;
    [Test]
    procedure DovrebbeLeggereITastiEPoiIlMouseAOgniLettura;
    [Test]
    procedure DovrebbeDareITastiDellAltraOrigine;
    [Test]
    procedure DovrebbeDareIBottoniELoSpostamentoDellUltimaLettura;
    [Test]
    procedure DovrebbeArrivareAiComandiDelGiocoAttraversoLoStato;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedMouseSettings = class(TObject)
  strict private
    FSetup: TFakeGameSetup;
    FSettings: IGreedSettings;
    FDevice: TMenuMouseFake;
    FDeviceIntf: IMouseDevice;
    FMouse: IGreedMouse;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaImpostazioniOSenzaControllo;
    [Test]
    procedure DovrebbeDareAlGiocoIValoriDiDefaultDellOriginale;
    [Test]
    procedure DovrebbeDareAlGiocoLeImpostazioniLette;
    [Test]
    procedure DovrebbeSpegnereIlMouseDelGiocoSeNonCeNessunMouse;
    [Test]
    procedure DovrebbeDireAiMenuSeUsareIlMouse;
    [Test]
    procedure DovrebbeLeggereLeImpostazioniDalTestoDelFile;
    [Test]
    procedure DovrebbeRimettereIlCursoreAlCentroQuandoIlMotoreRiparte;
  end;

implementation

{ TTestGreedMouseControls }

procedure TTestGreedMouseControls.Setup;
begin
  FKeys := TFakeCommandSource.Create;
  FKeysIntf := FKeys;
  FDevice := TMenuMouseFake.Create;
  FDeviceIntf := FDevice;
  FDevice.Width := 640;
  FDevice.Height := 400;
  FMouse := TGreedMouse.Create(FDeviceIntf, FDevice, nil);
  FControls := TGreedMouseControls.Create(FKeysIntf, FMouse);
end;

procedure TTestGreedMouseControls.TearDown;
begin
  FControls := nil;
  FMouse := nil;
  FDeviceIntf := nil;
  FKeysIntf := nil;
end;

procedure TTestGreedMouseControls.DovrebbeSollevareSenzaTastiOSenzaMouse;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedMouseControls.Create(nil, FMouse);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMouseControls.Create(FKeysIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedMouseControls.DovrebbeLeggereITastiEPoiIlMouseAOgniLettura;
begin
  FDevice.X := 123;
  FControls.BeginReading;
  Assert.AreEqual(1, FKeys.Readings);
  Assert.AreEqual(320, FDevice.X, 'the mouse was read: the cursor is in the middle');
  FControls.BeginReading;
  Assert.AreEqual(2, FKeys.Readings);
end;

procedure TTestGreedMouseControls.DovrebbeDareITastiDellAltraOrigine;
var
  LCharacter: Char;
begin
  FKeys.Pressed := [gcJump];
  FKeys.Typed := 'A';
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsPressed(gcJump));
  Assert.IsFalse(FControls.IsPressed(gcFire));
  Assert.IsTrue(FControls.TakeTyped(LCharacter));
  Assert.AreEqual('A', LCharacter);
  Assert.IsFalse(FControls.TakeTyped(LCharacter));
end;

procedure TTestGreedMouseControls.DovrebbeDareIBottoniELoSpostamentoDellUltimaLettura;
var
  LDeltaX, LDeltaY: Integer;
begin
  FControls.BeginReading;
  FDevice.X := FDevice.X - 12;
  FDevice.Y := FDevice.Y + 5;
  FDevice.Buttons := 5;
  Assert.IsFalse(FControls.IsMousePressed(gmbFire), 'not read yet');
  FControls.BeginReading;
  Assert.IsTrue(FControls.IsMousePressed(gmbFire));
  Assert.IsFalse(FControls.IsMousePressed(gmbUse));
  Assert.IsTrue(FControls.IsMousePressed(gmbNorth));
  FControls.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(12, LDeltaX, 'left is positive');
  Assert.AreEqual(-5, LDeltaY);
  FControls.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(12, LDeltaX, 'mouse.dx stays until the next reading');
end;

procedure TTestGreedMouseControls.DovrebbeArrivareAiComandiDelGiocoAttraversoLoStato;
var
  LState: IGreedControls;
begin
  LState := TGreedCommandState.Create(FControls);
  (LState as IGreedControlsSampler).ReadControls;
  FDevice.X := FDevice.X + 9;
  FDevice.Buttons := 2;
  (LState as IGreedControlsSampler).ReadControls;
  Assert.AreEqual(-9, LState.MouseDeltaX);
  Assert.IsTrue(LState.IsMouseDown(gmbUse));
  Assert.IsFalse(LState.IsMouseDown(gmbFire));
end;

{ TTestGreedMouseSettings }

procedure TTestGreedMouseSettings.Setup;
begin
  FSetup := TFakeGameSetup.Create;
  FSetup.CreateGame;
  FSettings := TGreedSettings.Create;
  FDevice := TMenuMouseFake.Create;
  FDeviceIntf := FDevice;
  FDevice.Width := 640;
  FDevice.Height := 400;
  FMouse := TGreedMouse.Create(FDeviceIntf, FDevice, nil);
end;

procedure TTestGreedMouseSettings.TearDown;
begin
  FSetup.Free;
  FMouse := nil;
  FDeviceIntf := nil;
  FSettings := nil;
end;

procedure TTestGreedMouseSettings.DovrebbeSollevareSenzaImpostazioniOSenzaControllo;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedMouseSettings.Apply(nil, FSetup.Game.Parts.Control, FMouse);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMouseSettings.Apply(FSettings, nil, FMouse);
    end, EArgumentNilException);
end;

procedure TTestGreedMouseSettings.DovrebbeDareAlGiocoIValoriDiDefaultDellOriginale;
begin
  Assert.IsFalse(FSetup.Game.Parts.Control.MouseEnabled, 'a game that was given no mouse does not use one');
  TGreedMouseSettings.Apply(FSettings, FSetup.Game.Parts.Control, FMouse);
  // SC.mouse = 1, SC.mousesensitivity = 10, mousesensitivityx = 10, mousesensitivityy = 5
  Assert.IsTrue(FSetup.Game.Parts.Control.MouseEnabled);
  Assert.AreEqual(10, FSetup.Game.Parts.Control.MouseSensitivity);
  Assert.AreEqual(10, FSetup.Game.Parts.Control.MouseSensitivityX);
  Assert.AreEqual(5, FSetup.Game.Parts.Control.MouseSensitivityY);
  Assert.IsFalse(FSetup.Game.Parts.Control.InvertMouseTurn);
  Assert.IsFalse(FSetup.Game.Parts.Control.InvertMouseLook);
  Assert.IsTrue(FMouse.MenuEnabled);
end;

procedure TTestGreedMouseSettings.DovrebbeDareAlGiocoLeImpostazioniLette;
begin
  FSettings.SetInteger(GREED_SETTING_MOUSE_SENSITIVITY, 3);
  FSettings.SetInteger(GREED_SETTING_MOUSE_SENSITIVITY_X, 21);
  FSettings.SetInteger(GREED_SETTING_MOUSE_SENSITIVITY_Y, 17);
  FSettings.SetBoolean(GREED_SETTING_INVERT_MOUSE_TURN, True);
  FSettings.SetBoolean(GREED_SETTING_INVERT_MOUSE_LOOK, True);
  TGreedMouseSettings.Apply(FSettings, FSetup.Game.Parts.Control, FMouse);
  Assert.AreEqual(3, FSetup.Game.Parts.Control.MouseSensitivity);
  Assert.AreEqual(21, FSetup.Game.Parts.Control.MouseSensitivityX);
  Assert.AreEqual(17, FSetup.Game.Parts.Control.MouseSensitivityY);
  Assert.IsTrue(FSetup.Game.Parts.Control.InvertMouseTurn);
  Assert.IsTrue(FSetup.Game.Parts.Control.InvertMouseLook);
  FSettings.SetBoolean(GREED_SETTING_MOUSE, False);
  TGreedMouseSettings.Apply(FSettings, FSetup.Game.Parts.Control, FMouse);
  Assert.IsFalse(FSetup.Game.Parts.Control.MouseEnabled, 'mouse=0');
end;

procedure TTestGreedMouseSettings.DovrebbeSpegnereIlMouseDelGiocoSeNonCeNessunMouse;
begin
  TGreedMouseSettings.Apply(FSettings, FSetup.Game.Parts.Control, nil);
  Assert.IsFalse(FSetup.Game.Parts.Control.MouseEnabled, 'mouseinstalled is false');
  Assert.AreEqual(10, FSetup.Game.Parts.Control.MouseSensitivity, 'the other settings are given all the same');
end;

procedure TTestGreedMouseSettings.DovrebbeDireAiMenuSeUsareIlMouse;
begin
  FSettings.SetBoolean(GREED_SETTING_MENU_MOUSE, False);
  TGreedMouseSettings.Apply(FSettings, FSetup.Game.Parts.Control, FMouse);
  Assert.IsFalse(FMouse.MenuEnabled);
  Assert.IsTrue(FSetup.Game.Parts.Control.MouseEnabled, 'the mouse of the game is another setting');
end;

procedure TTestGreedMouseSettings.DovrebbeLeggereLeImpostazioniDalTestoDelFile;
begin
  // the lines of xGreed.ini
  FSettings.LoadFromText('mouse=1'#13#10'menumouse=0'#13#10'mousesensitivity=7'#13#10'mousesensitivityx=12'#13#10 +
    'mousesensitivityy=4'#13#10'invertmouseturn=1'#13#10'invertmouselook=0'#13#10);
  TGreedMouseSettings.Apply(FSettings, FSetup.Game.Parts.Control, FMouse);
  Assert.IsTrue(FSetup.Game.Parts.Control.MouseEnabled);
  Assert.IsFalse(FMouse.MenuEnabled);
  Assert.AreEqual(7, FSetup.Game.Parts.Control.MouseSensitivity);
  Assert.AreEqual(12, FSetup.Game.Parts.Control.MouseSensitivityX);
  Assert.AreEqual(4, FSetup.Game.Parts.Control.MouseSensitivityY);
  Assert.IsTrue(FSetup.Game.Parts.Control.InvertMouseTurn);
  Assert.IsFalse(FSetup.Game.Parts.Control.InvertMouseLook);
end;

procedure TTestGreedMouseSettings.DovrebbeRimettereIlCursoreAlCentroQuandoIlMotoreRiparte;
begin
  Assert.IsNull(FSetup.Game.Mouse, 'no mouse unless one is given');
  // resetengine ends with ResetMouse: without a mouse nothing happens
  FSetup.Game.NewGame(0, 0, 2);
  FSetup.Game.Mouse := FMouse;
  Assert.AreSame(FMouse, FSetup.Game.Mouse);
  FDevice.X := 5;
  FDevice.Y := 6;
  FSetup.Game.NewGame(0, 0, 2);
  Assert.AreEqual(320, FDevice.X, 'ResetMouse of the new map');
  Assert.AreEqual(200, FDevice.Y);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMouseControls);
  TDUnitX.RegisterTestFixture(TTestGreedMouseSettings);

end.
