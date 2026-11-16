{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keys of Greed32 from the messages of the       }
{  window: TGreedHostControls and TGreedHostKeyboard over the translator and    }
{  the key state of Framework\GameHost (no window: made up messages)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.HostKeys;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.Win.MessageTranslator, DelphiDoom.GameHost.KeyState,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Application.Intf,
  DelphiDoom.Greed.HostControls, DelphiDoom.Greed.HostKeyboard, DelphiDoom.Greed.MenuInput,
  DelphiDoom.Tests.GameHost.Fakes;

type
  /// <summary>
  ///   The defect of the issue #175 "an Escape after a CTRL in the window did not open the menu", reproduced with
  ///   the messages that the window gets: a key that goes down and up between two readings of the controls (the
  ///   game reads them every two tics, and all the tics of a picture after one pump of the messages) was lost
  /// </summary>
  [TestFixture]
  [Category('Greed')]
  TTestGreedHostKeys = class
  strict private
    FKeysRef: IGameHostKeyState;
    FKeyboardRef: IGameHostKeyboard;
    FTranslator: TGameHostWinMessageTranslator;
    FState: TGameHostWindowState;
    FCommands: TGreedCommandState;
    FControls: IGreedControls;
    FSampler: IGreedControlsSampler;
    FMenuKeys: IGreedKeyboard;
    procedure Send(AMessage: UINT; AWParam: WPARAM);
    procedure Tap(AVirtualKey: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebberoRifiutareLoStatoNil;
    [Test]
    procedure UnEscBreveTraDueLettureDovrebbeAprireIlMenu;
    [Test]
    procedure UnEscSubitoDopoUnCtrlDovrebbeAprireIlMenu;
    [Test]
    procedure UnEscDopoUnAltDovrebbeAprireIlMenu;
    [Test]
    procedure UnTastoBreveDovrebbeValerePerUnaSolaLettura;
    [Test]
    procedure UnTastoTenutoDovrebbeRestarePremutoEMangiato;
    [Test]
    procedure UnaLetteraBreveDovrebbeEssereScrittaUnaVolta;
    [Test]
    procedure SenzaIlFuocoITastiTenutiDovrebberoCadere;
    [Test]
    procedure UnInvioBreveNelMenuDovrebbeVedersiPerUnTic;
    [Test]
    procedure IlMenuNonDovrebbeRubareIlTastoAlGioco;
  end;

implementation

procedure TTestGreedHostKeys.Setup;
var
  LKeys: TGameHostKeyState;
begin
  LKeys := TGameHostKeyState.Create;
  FKeysRef := LKeys;
  FKeyboardRef := TFakeKeyboard.Create;
  FTranslator := TGameHostWinMessageTranslator.Create(LKeys as IGameHostEventSink, FKeyboardRef);
  FTranslator.SuppressKeyMenu := True;
  FState := Default(TGameHostWindowState);
  FCommands := TGreedCommandState.Create(TGreedHostControls.Create(FKeysRef));
  FControls := FCommands;
  FSampler := FCommands;
  FMenuKeys := TGreedHostKeyboard.Create(FKeysRef);
end;

procedure TTestGreedHostKeys.TearDown;
begin
  FMenuKeys := nil;
  FSampler := nil;
  FControls := nil;
  FTranslator.Free;
  FKeyboardRef := nil;
  FKeysRef := nil;
end;

procedure TTestGreedHostKeys.Send(AMessage: UINT; AWParam: WPARAM);
var
  LAnswer: LRESULT;
begin
  FTranslator.Translate(AMessage, AWParam, 0, FState, LAnswer);
end;

procedure TTestGreedHostKeys.Tap(AVirtualKey: Integer);
begin
  Send(WM_KEYDOWN, AVirtualKey);
  Send(WM_KEYUP, AVirtualKey);
end;

procedure TTestGreedHostKeys.DovrebberoRifiutareLoStatoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedHostControls.Create(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedHostKeyboard.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestGreedHostKeys.UnEscBreveTraDueLettureDovrebbeAprireIlMenu;
begin
  FSampler.ReadControls;
  // both messages are read by the same pump, before the next reading of the controls
  Tap(VK_ESCAPE);
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsFresh(gcMenu), 'the press was lost');
end;

procedure TTestGreedHostKeys.UnEscSubitoDopoUnCtrlDovrebbeAprireIlMenu;
begin
  FSampler.ReadControls;
  Tap(VK_CONTROL);
  Tap(VK_ESCAPE);
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsDown(gcFire), 'the shot was lost');
  Assert.IsTrue(FControls.IsFresh(gcMenu), 'the menu was lost');
  // PlayerCommand eats the key of the menu
  FControls.Eat(gcMenu);
  FSampler.ReadControls;
  Assert.IsFalse(FControls.IsDown(gcFire));
  Assert.IsFalse(FControls.IsDown(gcMenu));
end;

procedure TTestGreedHostKeys.UnEscDopoUnAltDovrebbeAprireIlMenu;
var
  LAnswer: LRESULT;
begin
  FSampler.ReadControls;
  // Alt alone: Windows would enter the menu of the window and take the key that follows
  Send(WM_SYSKEYDOWN, VK_MENU);
  Send(WM_SYSKEYUP, VK_MENU);
  Assert.IsTrue(FTranslator.Translate(WM_SYSCOMMAND, SC_KEYMENU, 0, FState, LAnswer),
    'the menu of the window must not open');
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsDown(gcStrafe));
  Tap(VK_ESCAPE);
  FSampler.ReadControls;
  Assert.IsFalse(FControls.IsDown(gcStrafe));
  Assert.IsTrue(FControls.IsFresh(gcMenu));
end;

procedure TTestGreedHostKeys.UnTastoBreveDovrebbeValerePerUnaSolaLettura;
begin
  Tap(VK_SPACE);
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsDown(gcUse));
  FSampler.ReadControls;
  Assert.IsFalse(FControls.IsDown(gcUse));
end;

procedure TTestGreedHostKeys.UnTastoTenutoDovrebbeRestarePremutoEMangiato;
begin
  Send(WM_KEYDOWN, VK_ESCAPE);
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsFresh(gcMenu));
  FControls.Eat(gcMenu);
  // the repeats of the held key are not new presses
  Send(WM_KEYDOWN, VK_ESCAPE);
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsDown(gcMenu));
  Assert.IsFalse(FControls.IsFresh(gcMenu));
  Send(WM_KEYUP, VK_ESCAPE);
  FSampler.ReadControls;
  Assert.IsFalse(FControls.IsDown(gcMenu));
end;

procedure TTestGreedHostKeys.UnaLetteraBreveDovrebbeEssereScrittaUnaVolta;
var
  LCharacter: Char;
begin
  Tap(Ord('G'));
  FSampler.ReadControls;
  Assert.IsTrue(FControls.TakeCharacter(LCharacter));
  Assert.AreEqual('G', LCharacter);
  FSampler.ReadControls;
  Assert.IsFalse(FControls.TakeCharacter(LCharacter));
end;

procedure TTestGreedHostKeys.SenzaIlFuocoITastiTenutiDovrebberoCadere;
begin
  Send(WM_KEYDOWN, VK_UP);
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsDown(gcNorth));
  Send(WM_ACTIVATE, WA_INACTIVE);
  FSampler.ReadControls;
  Assert.IsFalse(FControls.IsDown(gcNorth));
end;

procedure TTestGreedHostKeys.UnInvioBreveNelMenuDovrebbeVedersiPerUnTic;
begin
  Assert.IsFalse(FMenuKeys.IsDown(GREED_SC_ENTER));
  Tap(VK_RETURN);
  Assert.IsTrue(FMenuKeys.IsDown(GREED_SC_ENTER));
  Assert.IsFalse(FMenuKeys.IsDown(GREED_SC_ENTER));
  Send(WM_KEYDOWN, VK_RETURN);
  Assert.IsTrue(FMenuKeys.IsDown(GREED_SC_ENTER));
  Assert.IsTrue(FMenuKeys.IsDown(GREED_SC_ENTER));
  Assert.IsFalse(FMenuKeys.IsDown(0));
  Assert.IsFalse(FMenuKeys.IsDown(200));
end;

procedure TTestGreedHostKeys.IlMenuNonDovrebbeRubareIlTastoAlGioco;
begin
  FSampler.ReadControls;
  Tap(VK_ESCAPE);
  Assert.IsTrue(FMenuKeys.IsDown(GREED_SC_ESCAPE));
  FSampler.ReadControls;
  Assert.IsTrue(FControls.IsFresh(gcMenu));
end;

end.
