{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TGameHostKeyLatch, of the press count of           }
{  TGameHostKeyState and of the SuppressKeyMenu option of the translator        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.KeyLatch;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.Win.MessageTranslator, DelphiDoom.GameHost.KeyState,
  DelphiDoom.GameHost.KeyLatch, DelphiDoom.Tests.GameHost.Fakes;

type
  /// <summary>A key state that only says which keys are down (no press count)</summary>
  TPlainKeyState = class(TInterfacedObject, IGameHostKeyState)
  public
    Down: Integer;
    function IsDown(AVirtualKey: Integer): Boolean;
  end;

  [TestFixture]
  [Category('GameHost')]
  TTestGameHostKeyLatch = class
  strict private
    FKeys: TGameHostKeyState;
    FKeysRef: IGameHostKeyState;
    FKeyboardRef: IGameHostKeyboard;
    FTranslator: TGameHostWinMessageTranslator;
    FState: TGameHostWindowState;
    FLatch: TGameHostKeyLatch;
    function Send(AMessage: UINT; AWParam: WPARAM): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareLoStatoNil;
    [Test]
    procedure LoStatoDovrebbeContareLePressioniSenzaLeRipetizioni;
    [Test]
    procedure IlContoDiUnCodiceCheNonEUnTastoDovrebbeEssereZero;
    [Test]
    procedure UnTastoPremutoERilasciatoTraDueLettureDovrebbeVedersiUnaVolta;
    [Test]
    procedure UnTastoTenutoDovrebbeRestarePremuto;
    [Test]
    procedure LePressioniPrimaDelLatchNonDovrebberoContare;
    [Test]
    procedure DueLatchNonDovrebberoRubarsiLePressioni;
    [Test]
    procedure IlCampioneDovrebbeValereFinoAlProssimo;
    [Test]
    procedure UnCodiceFuoriDaiTastiDovrebbeEssereFalso;
    [Test]
    procedure SenzaIlContoDovrebbeRispondereComeLoStato;
    [Test]
    procedure IlMenuDaTastieraDovrebbeRestareAWindowsSeNonSoppresso;
    [Test]
    procedure IlMenuDaTastieraSoppressoNonDovrebbeArrivareAWindows;
    [Test]
    procedure LaChiusuraDalMenuDiSistemaDovrebbeRestareAWindowsAncheSoppresso;
  end;

implementation

{ TPlainKeyState }

function TPlainKeyState.IsDown(AVirtualKey: Integer): Boolean;
begin
  Result := AVirtualKey = Down;
end;

{ TTestGameHostKeyLatch }

procedure TTestGameHostKeyLatch.Setup;
begin
  FKeys := TGameHostKeyState.Create;
  FKeysRef := FKeys;
  FKeyboardRef := TFakeKeyboard.Create;
  FTranslator := TGameHostWinMessageTranslator.Create(FKeys as IGameHostEventSink, FKeyboardRef);
  FState := Default(TGameHostWindowState);
  FLatch := TGameHostKeyLatch.Create(FKeysRef);
end;

procedure TTestGameHostKeyLatch.TearDown;
begin
  FLatch.Free;
  FTranslator.Free;
  FKeyboardRef := nil;
  FKeysRef := nil;
end;

function TTestGameHostKeyLatch.Send(AMessage: UINT; AWParam: WPARAM): Boolean;
var
  LAnswer: LRESULT;
begin
  Result := FTranslator.Translate(AMessage, AWParam, 0, FState, LAnswer);
end;

procedure TTestGameHostKeyLatch.DovrebbeRifiutareLoStatoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGameHostKeyLatch.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestGameHostKeyLatch.LoStatoDovrebbeContareLePressioniSenzaLeRipetizioni;
begin
  Assert.AreEqual(Cardinal(0), FKeys.PressCount(VK_ESCAPE));
  Send(WM_KEYDOWN, VK_ESCAPE);
  // the repeats of a held key
  Send(WM_KEYDOWN, VK_ESCAPE);
  Send(WM_KEYDOWN, VK_ESCAPE);
  Assert.AreEqual(Cardinal(1), FKeys.PressCount(VK_ESCAPE));
  Send(WM_KEYUP, VK_ESCAPE);
  Assert.AreEqual(Cardinal(1), FKeys.PressCount(VK_ESCAPE));
  Send(WM_KEYDOWN, VK_ESCAPE);
  Assert.AreEqual(Cardinal(2), FKeys.PressCount(VK_ESCAPE));
  Assert.AreEqual(Cardinal(0), FKeys.PressCount(VK_CONTROL));
end;

procedure TTestGameHostKeyLatch.IlContoDiUnCodiceCheNonEUnTastoDovrebbeEssereZero;
begin
  Assert.AreEqual(Cardinal(0), FKeys.PressCount(-1));
  Assert.AreEqual(Cardinal(0), FKeys.PressCount(256));
end;

procedure TTestGameHostKeyLatch.UnTastoPremutoERilasciatoTraDueLettureDovrebbeVedersiUnaVolta;
begin
  Assert.IsFalse(FLatch.Take(VK_ESCAPE));
  Send(WM_KEYDOWN, VK_ESCAPE);
  Send(WM_KEYUP, VK_ESCAPE);
  Assert.IsFalse(FKeys.IsDown(VK_ESCAPE), 'the key state alone has lost the press');
  Assert.IsTrue(FLatch.Take(VK_ESCAPE));
  Assert.IsFalse(FLatch.Take(VK_ESCAPE));
end;

procedure TTestGameHostKeyLatch.UnTastoTenutoDovrebbeRestarePremuto;
begin
  Send(WM_KEYDOWN, VK_UP);
  Assert.IsTrue(FLatch.Take(VK_UP));
  Assert.IsTrue(FLatch.Take(VK_UP));
  Send(WM_KEYUP, VK_UP);
  Assert.IsFalse(FLatch.Take(VK_UP));
end;

procedure TTestGameHostKeyLatch.LePressioniPrimaDelLatchNonDovrebberoContare;
var
  LLatch: TGameHostKeyLatch;
begin
  Send(WM_KEYDOWN, VK_RETURN);
  Send(WM_KEYUP, VK_RETURN);
  LLatch := TGameHostKeyLatch.Create(FKeysRef);
  try
    Assert.IsFalse(LLatch.Take(VK_RETURN));
  finally
    LLatch.Free;
  end;
end;

procedure TTestGameHostKeyLatch.DueLatchNonDovrebberoRubarsiLePressioni;
var
  LOther: TGameHostKeyLatch;
begin
  LOther := TGameHostKeyLatch.Create(FKeysRef);
  try
    Send(WM_KEYDOWN, VK_SPACE);
    Send(WM_KEYUP, VK_SPACE);
    Assert.IsTrue(FLatch.Take(VK_SPACE));
    Assert.IsTrue(LOther.Take(VK_SPACE));
    Assert.IsFalse(LOther.Take(VK_SPACE));
  finally
    LOther.Free;
  end;
end;

procedure TTestGameHostKeyLatch.IlCampioneDovrebbeValereFinoAlProssimo;
begin
  Send(WM_KEYDOWN, Ord('A'));
  Send(WM_KEYUP, Ord('A'));
  Assert.IsFalse(FLatch.IsDown(Ord('A')), 'nothing sampled yet');
  FLatch.Sample;
  Assert.IsTrue(FLatch.IsDown(Ord('A')));
  Assert.IsTrue(FLatch.IsDown(Ord('A')), 'asking does not take the press');
  Assert.IsFalse(FLatch.IsDown(Ord('B')));
  FLatch.Sample;
  Assert.IsFalse(FLatch.IsDown(Ord('A')));
end;

procedure TTestGameHostKeyLatch.UnCodiceFuoriDaiTastiDovrebbeEssereFalso;
begin
  FLatch.Sample;
  Assert.IsFalse(FLatch.Take(-1));
  Assert.IsFalse(FLatch.Take(256));
  Assert.IsFalse(FLatch.IsDown(-1));
  Assert.IsFalse(FLatch.IsDown(256));
end;

procedure TTestGameHostKeyLatch.SenzaIlContoDovrebbeRispondereComeLoStato;
var
  LPlain: TPlainKeyState;
  LPlainRef: IGameHostKeyState;
  LLatch: TGameHostKeyLatch;
begin
  LPlain := TPlainKeyState.Create;
  LPlainRef := LPlain;
  LLatch := TGameHostKeyLatch.Create(LPlainRef);
  try
    LPlain.Down := VK_LEFT;
    Assert.IsTrue(LLatch.Take(VK_LEFT));
    LPlain.Down := 0;
    Assert.IsFalse(LLatch.Take(VK_LEFT));
  finally
    LLatch.Free;
  end;
end;

procedure TTestGameHostKeyLatch.IlMenuDaTastieraDovrebbeRestareAWindowsSeNonSoppresso;
begin
  Assert.IsFalse(FTranslator.SuppressKeyMenu);
  Assert.IsFalse(Send(WM_SYSCOMMAND, SC_KEYMENU));
end;

procedure TTestGameHostKeyLatch.IlMenuDaTastieraSoppressoNonDovrebbeArrivareAWindows;
begin
  FTranslator.SuppressKeyMenu := True;
  Assert.IsTrue(Send(WM_SYSCOMMAND, SC_KEYMENU));
  // the four low bits of the command belong to the system
  Assert.IsTrue(Send(WM_SYSCOMMAND, SC_KEYMENU or 3));
end;

procedure TTestGameHostKeyLatch.LaChiusuraDalMenuDiSistemaDovrebbeRestareAWindowsAncheSoppresso;
begin
  FTranslator.SuppressKeyMenu := True;
  Assert.IsFalse(Send(WM_SYSCOMMAND, SC_CLOSE));
  Assert.IsFalse(Send(WM_SYSCOMMAND, SC_MINIMIZE));
  // Alt+F4 is a system key that Windows must still see
  Assert.IsFalse(Send(WM_SYSKEYDOWN, VK_F4));
end;

end.
