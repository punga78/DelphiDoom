{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keys that the player chose (bt_* of            }
{  xGreed.ini) and of TGreedHostControls with them (no window: made up          }
{  messages)                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.KeyBindings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.Win.MessageTranslator, DelphiDoom.GameHost.KeyState,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Settings,
  DelphiDoom.Greed.KeyBindings.Intf, DelphiDoom.Greed.KeyBindings, DelphiDoom.Greed.HostControls,
  DelphiDoom.Tests.GameHost.Fakes;

type
  /// <summary>
  ///   The 19 buttons of the game take the keys of the settings. With the default settings they have to be the keys
  ///   that the game used when they were fixed in the adapter of the window (the table EXPECTED below is that old
  ///   table, written here as a list of what the player presses)
  /// </summary>
  [TestFixture]
  [Category('Greed')]
  TTestGreedKeyBindings = class
  strict private
    FSettings: IGreedSettings;
    FKeysRef: IGameHostKeyState;
    FKeyboardRef: IGameHostKeyboard;
    FTranslator: TGameHostWinMessageTranslator;
    FState: TGameHostWindowState;
    procedure Send(AMessage: UINT; AWParam: WPARAM);
    function ControlsWith(const ABindings: IGreedKeyBindings): IGreedCommandSource;
    function IsPressedAfterHolding(const ASource: IGreedCommandSource; ACommand: TGreedCommand;
      AVirtualKey: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareLeImpostazioniNil;
    [Test]
    procedure DovrebbeRifiutareIBindingNilNelCostruttoreDelleLetture;
    [Test]
    procedure DovrebbeEssereModificabileSoloPerLeDiciannoveCommandiDeiBottoni;
    [Test]
    procedure DovrebbeDareIlNomeDelBottoneNelFile;
    [Test]
    procedure ConLeImpostazioniDiDefaultDovrebbeDareITastiDiPrima;
    [Test]
    procedure SenzaBindingDovrebbeDareGliStessiTastiDelleImpostazioniDiDefault;
    [Test]
    procedure UnTastoCambiatoDovrebbeSostituireQuelloDiPrima;
    [Test]
    procedure UnCodiceCheNonETastoDovrebbeLasciareIlComandoSenzaTasto;
    [Test]
    procedure UnTastoCambiatoNelFileDovrebbeValere;
    [Test]
    procedure IComandiFissiNonDovrebberoCambiare;
    [Test]
    procedure IlDestroEIlSinistroDiShiftDovrebberoDareLaCorsa;
  end;

implementation

const
  // the 19 buttons in the order of the original and the key that the player pressed in the first version
  BUTTON_COMMANDS: array[0..18] of TGreedCommand = (
    gcNorth, gcEast, gcSouth, gcWest, gcFire, gcStrafe, gcUse, gcRun, gcJump, gcUseItem, gcRearView, gcLookUp,
    gcLookDown, gcCenterView, gcSlideLeft, gcSlideRight, gcInventoryLeft, gcInventoryRight, gcMotionMode);
  EXPECTED: array[0..18] of Integer = (
    VK_UP, VK_RIGHT, VK_DOWN, VK_LEFT, VK_CONTROL, VK_MENU, VK_SPACE, VK_SHIFT, Ord('Z'), Ord('X'), Ord('A'),
    VK_PRIOR, VK_NEXT, VK_HOME, VK_OEM_COMMA, VK_OEM_PERIOD, VK_INSERT, VK_DELETE, Ord('S'));

procedure TTestGreedKeyBindings.Setup;
var
  LKeys: TGameHostKeyState;
begin
  FSettings := TGreedSettings.Create;
  LKeys := TGameHostKeyState.Create;
  FKeysRef := LKeys;
  FKeyboardRef := TFakeKeyboard.Create;
  FTranslator := TGameHostWinMessageTranslator.Create(LKeys as IGameHostEventSink, FKeyboardRef);
  FState := Default(TGameHostWindowState);
end;

procedure TTestGreedKeyBindings.TearDown;
begin
  FTranslator.Free;
  FKeyboardRef := nil;
  FKeysRef := nil;
  FSettings := nil;
end;

procedure TTestGreedKeyBindings.Send(AMessage: UINT; AWParam: WPARAM);
var
  LAnswer: LRESULT;
begin
  FTranslator.Translate(AMessage, AWParam, 0, FState, LAnswer);
end;

function TTestGreedKeyBindings.ControlsWith(const ABindings: IGreedKeyBindings): IGreedCommandSource;
begin
  if Assigned(ABindings) then
    Result := TGreedHostControls.Create(FKeysRef, ABindings)
  else
    Result := TGreedHostControls.Create(FKeysRef);
end;

function TTestGreedKeyBindings.IsPressedAfterHolding(const ASource: IGreedCommandSource; ACommand: TGreedCommand;
  AVirtualKey: Integer): Boolean;
begin
  Send(WM_KEYDOWN, AVirtualKey);
  ASource.BeginReading;
  Result := ASource.IsPressed(ACommand);
  Send(WM_KEYUP, AVirtualKey);
  ASource.BeginReading;
  // the key went up: after the second reading of the latch the command is released
  ASource.BeginReading;
end;

procedure TTestGreedKeyBindings.DovrebbeRifiutareLeImpostazioniNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedKeyBindings.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestGreedKeyBindings.DovrebbeRifiutareIBindingNilNelCostruttoreDelleLetture;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedHostControls.Create(FKeysRef, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedKeyBindings.DovrebbeEssereModificabileSoloPerLeDiciannoveCommandiDeiBottoni;
var
  LBindings: IGreedKeyBindings;
  LCommand: TGreedCommand;
  LCount: Integer;
begin
  LBindings := TGreedKeyBindings.Create(FSettings);
  LCount := 0;
  for LCommand := Low(TGreedCommand) to High(TGreedCommand) do
    if LBindings.IsBindable(LCommand) then
    begin
      Inc(LCount);
      Assert.IsTrue(LCount <= 19);
      Assert.IsTrue(LCommand <= gcMotionMode, 'only the buttons of the original');
    end
    else
      Assert.AreEqual(0, LBindings.VirtualKeyOf(LCommand));
  Assert.AreEqual(19, LCount);
end;

procedure TTestGreedKeyBindings.DovrebbeDareIlNomeDelBottoneNelFile;
begin
  Assert.AreEqual('bt_north', TGreedKeyBindings.SettingNameOf(gcNorth));
  Assert.AreEqual('bt_motionmode', TGreedKeyBindings.SettingNameOf(gcMotionMode));
  Assert.AreEqual('', TGreedKeyBindings.SettingNameOf(gcMenu));
  // every name is a setting of the file, of the integer kind
  Assert.AreEqual(Ord(gskInteger), Ord(FSettings.KindOf(TGreedKeyBindings.SettingNameOf(gcFire))));
end;

procedure TTestGreedKeyBindings.ConLeImpostazioniDiDefaultDovrebbeDareITastiDiPrima;
var
  LBindings: IGreedKeyBindings;
  LIndex: Integer;
begin
  LBindings := TGreedKeyBindings.Create(FSettings);
  for LIndex := Low(BUTTON_COMMANDS) to High(BUTTON_COMMANDS) do
    Assert.AreEqual(EXPECTED[LIndex], LBindings.VirtualKeyOf(BUTTON_COMMANDS[LIndex]),
      TGreedKeyBindings.SettingNameOf(BUTTON_COMMANDS[LIndex]));
end;

procedure TTestGreedKeyBindings.SenzaBindingDovrebbeDareGliStessiTastiDelleImpostazioniDiDefault;
var
  LWithout, LWith: IGreedCommandSource;
  LIndex: Integer;
begin
  // the controls of the program that has no settings (Greed32 -play) press the same keys as the ones with the
  // default settings: the same key makes the same command in both
  LWithout := ControlsWith(nil);
  LWith := ControlsWith(TGreedKeyBindings.Create(FSettings));
  for LIndex := Low(BUTTON_COMMANDS) to High(BUTTON_COMMANDS) do
  begin
    Assert.IsTrue(IsPressedAfterHolding(LWithout, BUTTON_COMMANDS[LIndex], EXPECTED[LIndex]), 'without');
    Assert.IsTrue(IsPressedAfterHolding(LWith, BUTTON_COMMANDS[LIndex], EXPECTED[LIndex]), 'with');
  end;
end;

procedure TTestGreedKeyBindings.UnTastoCambiatoDovrebbeSostituireQuelloDiPrima;
var
  LSource: IGreedCommandSource;
begin
  // bt_fire to SC_B: Ctrl does not fire any more, B does
  FSettings.SetInteger('bt_fire', $30);
  LSource := ControlsWith(TGreedKeyBindings.Create(FSettings));
  Assert.IsFalse(IsPressedAfterHolding(LSource, gcFire, VK_CONTROL), 'the old key');
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcFire, Ord('B')), 'the new key');
  // the others are not touched
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcUse, VK_SPACE));
end;

procedure TTestGreedKeyBindings.UnCodiceCheNonETastoDovrebbeLasciareIlComandoSenzaTasto;
var
  LSource: IGreedCommandSource;
begin
  FSettings.SetInteger('bt_jump', 0);
  FSettings.SetInteger('bt_run', 999);
  LSource := ControlsWith(TGreedKeyBindings.Create(FSettings));
  Assert.IsFalse(IsPressedAfterHolding(LSource, gcJump, Ord('Z')), 'bt_jump 0');
  Assert.IsFalse(IsPressedAfterHolding(LSource, gcRun, VK_SHIFT), 'bt_run 999');
end;

procedure TTestGreedKeyBindings.UnTastoCambiatoNelFileDovrebbeValere;
var
  LSource: IGreedCommandSource;
begin
  // the file xGreed.ini of the player: hexadecimal numbers are read as atoi of the original does
  FSettings.LoadFromText('bt_useitem=0x2e' + #13#10 + 'bt_north=17');
  LSource := ControlsWith(TGreedKeyBindings.Create(FSettings));
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcUseItem, Ord('C')), 'SC_C');
  // the number is in decimal as in the original: 17 is $11, the scan code of W, so the arrow is not north any more
  Assert.IsFalse(IsPressedAfterHolding(LSource, gcNorth, VK_UP));
end;

procedure TTestGreedKeyBindings.IComandiFissiNonDovrebberoCambiare;
var
  LBindings: IGreedKeyBindings;
  LSource: IGreedCommandSource;
begin
  // every button on the key of another command: the fixed keys are where they were
  FSettings.SetInteger('bt_north', $01);
  FSettings.SetInteger('bt_fire', $3B);
  LBindings := TGreedKeyBindings.Create(FSettings);
  LSource := ControlsWith(LBindings);
  Assert.IsFalse(LBindings.IsBindable(gcMenu));
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcMenu, VK_ESCAPE), 'Esc is still the menu');
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcHelp, VK_F1), 'F1 is still the help');
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcWeapon1, Ord('1')), '1 is still the first weapon');
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcPause, Ord('P')), 'P is still the pause');
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcAlt, VK_MENU), 'Alt is still the Alt of the quick exit');
end;

procedure TTestGreedKeyBindings.IlDestroEIlSinistroDiShiftDovrebberoDareLaCorsa;
var
  LSource: IGreedCommandSource;
begin
  // the right Shift (SC_RSHIFT, $36) is the same key as the left one for the window
  FSettings.SetInteger('bt_run', $36);
  LSource := ControlsWith(TGreedKeyBindings.Create(FSettings));
  Assert.IsTrue(IsPressedAfterHolding(LSource, gcRun, VK_SHIFT));
end;

end.
