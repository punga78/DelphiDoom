{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TGameHostWinMessageTranslator and of              }
{  TGameHostKeyState (the messages of a window as events, without a window)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.MessageTranslator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.Win.MessageTranslator, DelphiDoom.GameHost.KeyState,
  DelphiDoom.Tests.GameHost.Fakes;

type
  [TestFixture]
  [Category('GameHost')]
  TTestGameHostMessageTranslator = class
  strict private
    FSink: TFakeEventSink;
    FSinkRef: IGameHostEventSink;
    FKeyboard: TFakeKeyboard;
    FKeyboardRef: IGameHostKeyboard;
    FTranslator: TGameHostWinMessageTranslator;
    FState: TGameHostWindowState;
    FResult: LRESULT;
    function Send(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure UnTastoPremutoDovrebbeDareTastoCarattereEModificatori;
    [Test]
    procedure UnTastoRilasciatoNonDovrebbeChiedereIlCarattere;
    [Test]
    procedure ITastiDiSistemaDovrebberoRestareAWindows;
    [Test]
    procedure IlMouseDovrebbeDareBottoneEPosizioneConSegno;
    [Test]
    procedure ASchermoInteroLaPosizioneDovrebbeEssereNellImmagine;
    [Test]
    procedure LaRotellaDovrebbeDareUnSoloEventoSenzaPosizione;
    [Test]
    procedure LAttivazioneDovrebbeDireFuocoEMinimizzataERestareAWindows;
    [Test]
    procedure LaChiusuraDovrebbeDareQuitEdEssereConclusa;
    [Test]
    procedure IlTrascinamentoDelBordoDovrebbeDareIlRidimensionamento;
    [Test]
    [TestCase('non ridimensionabile', 'False,False,False,1,800,500')]
    [TestCase('a schermo intero', 'True,True,False,0,800,500')]
    [TestCase('mentre il gioco imposta il modo', 'True,False,True,0,800,500')]
    [TestCase('minimizzata', 'True,False,False,1,800,500')]
    [TestCase('stessa misura del modo', 'True,False,False,0,640,400')]
    procedure NonDovrebbeDareIlRidimensionamento(AResizable, AFullscreen, ASettingMode: Boolean; AKind, AWidth,
      AHeight: Integer);
    [Test]
    procedure UnMessaggioCheNonEUnInputNonDovrebbeDareEventi;
    [Test]
    procedure LoStatoDeiTastiDovrebbeSeguireIMessaggi;
    [Test]
    procedure LoStatoDeiTastiDovrebbeAzzerarsiSenzaIlFuoco;
  end;

implementation

procedure TTestGameHostMessageTranslator.Setup;
begin
  FSink := TFakeEventSink.Create;
  FSinkRef := FSink;
  FKeyboard := TFakeKeyboard.Create;
  FKeyboardRef := FKeyboard;
  FTranslator := TGameHostWinMessageTranslator.Create(FSinkRef, FKeyboardRef);
  FState := Default(TGameHostWindowState);
  FState.Width := 640;
  FState.Height := 400;
  FState.ClientWidth := 640;
  FState.ClientHeight := 400;
end;

procedure TTestGameHostMessageTranslator.TearDown;
begin
  FTranslator.Free;
  FSinkRef := nil;
  FKeyboardRef := nil;
end;

function TTestGameHostMessageTranslator.Send(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): Boolean;
begin
  Result := FTranslator.Translate(AMessage, AWParam, ALParam, FState, FResult);
end;

procedure TTestGameHostMessageTranslator.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGameHostWinMessageTranslator.Create(nil, FKeyboardRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGameHostWinMessageTranslator.Create(FSinkRef, nil);
    end, EArgumentNilException);
end;

procedure TTestGameHostMessageTranslator.UnTastoPremutoDovrebbeDareTastoCarattereEModificatori;
begin
  FKeyboard.Typed := Ord('Q');
  FKeyboard.Held := [hmShift];
  // the scan code is in bits 16..23 of the long parameter
  Assert.IsTrue(Send(WM_KEYDOWN, Ord('Q'), $00100001));
  Assert.AreEqual(NativeInt(0), NativeInt(FResult));
  Assert.AreEqual(1, FSink.Count);
  Assert.IsTrue(FSink[0].Kind = hekKeyDown);
  Assert.AreEqual(Ord('Q'), FSink[0].VirtualKey);
  Assert.AreEqual(Cardinal(Ord('Q')), FSink[0].Character);
  Assert.IsTrue(FSink[0].Modifiers = [hmShift]);
  Assert.AreEqual(Cardinal(Ord('Q')), FKeyboard.AskedKey);
  Assert.AreEqual(Cardinal($10), FKeyboard.AskedScanCode);
end;

procedure TTestGameHostMessageTranslator.UnTastoRilasciatoNonDovrebbeChiedereIlCarattere;
begin
  FKeyboard.Typed := Ord('Q');
  Assert.IsTrue(Send(WM_KEYUP, Ord('Q'), 0));
  Assert.IsTrue(FSink[0].Kind = hekKeyUp);
  Assert.AreEqual(Ord('Q'), FSink[0].VirtualKey);
  Assert.AreEqual(Cardinal(0), FSink[0].Character);
  Assert.AreEqual(0, FKeyboard.CharacterCalls);
end;

procedure TTestGameHostMessageTranslator.ITastiDiSistemaDovrebberoRestareAWindows;
begin
  // Alt+F4 must still close the window: the event is posted and the message goes on
  Assert.IsFalse(Send(WM_SYSKEYDOWN, VK_F4, 0));
  Assert.IsFalse(Send(WM_SYSKEYUP, VK_F4, 0));
  Assert.AreEqual(2, FSink.Count);
  Assert.IsTrue(FSink[0].Kind = hekKeyDown);
  Assert.IsTrue(FSink[1].Kind = hekKeyUp);
end;

procedure TTestGameHostMessageTranslator.IlMouseDovrebbeDareBottoneEPosizioneConSegno;
begin
  Assert.IsTrue(Send(WM_MOUSEMOVE, 0, MakeLParam(10, 20)));
  Assert.IsTrue(Send(WM_LBUTTONDOWN, 0, MakeLParam(11, 21)));
  Assert.IsTrue(Send(WM_LBUTTONUP, 0, MakeLParam(Word(-5), Word(-6))));
  Assert.IsTrue(Send(WM_MBUTTONDOWN, 0, 0));
  Assert.IsTrue(Send(WM_MBUTTONUP, 0, 0));
  Assert.IsTrue(Send(WM_RBUTTONDOWN, 0, 0));
  Assert.IsTrue(Send(WM_RBUTTONUP, 0, 0));
  Assert.AreEqual(7, FSink.Count);
  Assert.IsTrue(FSink[0].Kind = hekMouseMotion);
  Assert.IsTrue(FSink[0].Button = hmbNone);
  Assert.AreEqual(10, FSink[0].X);
  Assert.AreEqual(20, FSink[0].Y);
  Assert.IsTrue((FSink[1].Kind = hekMouseDown) and (FSink[1].Button = hmbLeft));
  Assert.IsTrue((FSink[2].Kind = hekMouseUp) and (FSink[2].Button = hmbLeft));
  Assert.AreEqual(-5, FSink[2].X);
  Assert.AreEqual(-6, FSink[2].Y);
  Assert.IsTrue((FSink[3].Kind = hekMouseDown) and (FSink[3].Button = hmbMiddle));
  Assert.IsTrue((FSink[4].Kind = hekMouseUp) and (FSink[4].Button = hmbMiddle));
  Assert.IsTrue((FSink[5].Kind = hekMouseDown) and (FSink[5].Button = hmbRight));
  Assert.IsTrue((FSink[6].Kind = hekMouseUp) and (FSink[6].Button = hmbRight));
end;

procedure TTestGameHostMessageTranslator.ASchermoInteroLaPosizioneDovrebbeEssereNellImmagine;
begin
  FState.Fullscreen := True;
  FState.ClientWidth := 1920;
  FState.ClientHeight := 1080;
  Send(WM_MOUSEMOVE, 0, MakeLParam(960, 540));
  Assert.AreEqual(320, FSink[0].X);
  Assert.AreEqual(200, FSink[0].Y);
end;

procedure TTestGameHostMessageTranslator.LaRotellaDovrebbeDareUnSoloEventoSenzaPosizione;
begin
  FState.Fullscreen := True;
  FState.ClientWidth := 1920;
  FState.ClientHeight := 1080;
  // the position of a wheel message is of the screen: it is not the one of the picture and is not passed on
  Assert.IsTrue(Send(WM_MOUSEWHEEL, MakeWParam(0, Word(-120)), MakeLParam(700, 300)));
  Assert.IsTrue(Send(WM_MOUSEWHEEL, MakeWParam(0, 240), MakeLParam(700, 300)));
  Assert.AreEqual(2, FSink.Count);
  Assert.IsTrue(FSink[0].Kind = hekMouseWheel);
  Assert.AreEqual(-120, FSink[0].WheelDelta);
  Assert.AreEqual(0, FSink[0].X);
  Assert.AreEqual(0, FSink[0].Y);
  Assert.AreEqual(240, FSink[1].WheelDelta);
end;

procedure TTestGameHostMessageTranslator.LAttivazioneDovrebbeDireFuocoEMinimizzataERestareAWindows;
begin
  Assert.IsFalse(Send(WM_ACTIVATE, MakeWParam(WA_CLICKACTIVE, 0), 0));
  Assert.IsFalse(Send(WM_ACTIVATE, MakeWParam(WA_INACTIVE, 0), 0));
  Assert.IsFalse(Send(WM_ACTIVATE, MakeWParam(WA_ACTIVE, 1), 0));
  Assert.IsTrue(FSink[0].Focused and not FSink[0].Minimized);
  Assert.IsTrue((not FSink[1].Focused) and not FSink[1].Minimized);
  Assert.IsTrue((not FSink[2].Focused) and FSink[2].Minimized);
end;

procedure TTestGameHostMessageTranslator.LaChiusuraDovrebbeDareQuitEdEssereConclusa;
begin
  Assert.IsTrue(Send(WM_CLOSE, 0, 0));
  Assert.AreEqual(1, FSink.Count);
  Assert.IsTrue(FSink[0].Kind = hekQuit);
end;

procedure TTestGameHostMessageTranslator.IlTrascinamentoDelBordoDovrebbeDareIlRidimensionamento;
begin
  FState.Resizable := True;
  Assert.IsFalse(Send(WM_SIZE, SIZE_RESTORED, MakeLParam(800, 500)), 'Windows deve ancora vedere il messaggio');
  Assert.AreEqual(1, FSink.Count);
  Assert.IsTrue(FSink[0].Kind = hekResize);
  Assert.AreEqual(800, FSink[0].X);
  Assert.AreEqual(500, FSink[0].Y);
end;

procedure TTestGameHostMessageTranslator.NonDovrebbeDareIlRidimensionamento(AResizable, AFullscreen,
  ASettingMode: Boolean; AKind, AWidth, AHeight: Integer);
begin
  FState.Resizable := AResizable;
  FState.Fullscreen := AFullscreen;
  FState.SettingMode := ASettingMode;
  Assert.IsFalse(Send(WM_SIZE, WPARAM(AKind), MakeLParam(AWidth, AHeight)));
  Assert.AreEqual(0, FSink.Count);
end;

procedure TTestGameHostMessageTranslator.UnMessaggioCheNonEUnInputNonDovrebbeDareEventi;
begin
  Assert.IsFalse(Send(WM_PAINT, 0, 0));
  Assert.IsFalse(Send(WM_TIMER, 1, 0));
  Assert.AreEqual(0, FSink.Count);
end;

procedure TTestGameHostMessageTranslator.LoStatoDeiTastiDovrebbeSeguireIMessaggi;
var
  LKeys: TGameHostKeyState;
  LKeysRef: IGameHostEventSink;
  LTranslator: TGameHostWinMessageTranslator;
  LAnswer: LRESULT;
begin
  LKeys := TGameHostKeyState.Create;
  LKeysRef := LKeys;
  LTranslator := TGameHostWinMessageTranslator.Create(LKeysRef, FKeyboardRef);
  try
    Assert.IsFalse(LKeys.IsDown(VK_UP));
    LTranslator.Translate(WM_KEYDOWN, VK_UP, 0, FState, LAnswer);
    LTranslator.Translate(WM_SYSKEYDOWN, VK_MENU, 0, FState, LAnswer);
    Assert.IsTrue(LKeys.IsDown(VK_UP));
    Assert.IsTrue(LKeys.IsDown(VK_MENU));
    Assert.IsFalse(LKeys.IsDown(VK_DOWN));
    LTranslator.Translate(WM_KEYUP, VK_UP, 0, FState, LAnswer);
    Assert.IsFalse(LKeys.IsDown(VK_UP));
    Assert.IsFalse(LKeys.IsDown(-1));
    Assert.IsFalse(LKeys.IsDown(256));
  finally
    LTranslator.Free;
  end;
end;

procedure TTestGameHostMessageTranslator.LoStatoDeiTastiDovrebbeAzzerarsiSenzaIlFuoco;
var
  LKeys: TGameHostKeyState;
  LKeysRef: IGameHostEventSink;
  LTranslator: TGameHostWinMessageTranslator;
  LAnswer: LRESULT;
begin
  LKeys := TGameHostKeyState.Create;
  LKeysRef := LKeys;
  LTranslator := TGameHostWinMessageTranslator.Create(LKeysRef, FKeyboardRef);
  try
    LTranslator.Translate(WM_KEYDOWN, VK_SHIFT, 0, FState, LAnswer);
    // the focus comes: the keys stay
    LTranslator.Translate(WM_ACTIVATE, MakeWParam(WA_ACTIVE, 0), 0, FState, LAnswer);
    Assert.IsTrue(LKeys.IsDown(VK_SHIFT));
    // the focus goes: the release will never be seen
    LTranslator.Translate(WM_ACTIVATE, MakeWParam(WA_INACTIVE, 0), 0, FState, LAnswer);
    Assert.IsFalse(LKeys.IsDown(VK_SHIFT));
  finally
    LTranslator.Free;
  end;
end;

end.
