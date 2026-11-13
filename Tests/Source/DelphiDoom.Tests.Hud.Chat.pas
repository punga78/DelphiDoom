{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the chat                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.Chat;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.Intf, DelphiDoom.Hud.MessageBar, DelphiDoom.Hud.Chat,
  DelphiDoom.Tests.Hud.Fakes;

type
  [TestFixture]
  [Category('hud')]
  TTestHudChat = class(TObject)
  private
    FWorld: TFakeHudWorld;
    FWorldRef: IInterface;
    FBar: THudMessageBar;
    FBarRef: IHudMessageTarget;
    FChat: THudChat;
    procedure Type_(const AText: string);
    function Drain: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareIServiziMancanti;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiGiocatoriNonValido;
    [Test]
    procedure DovrebbeRicordareLoShiftEdAlt;
    [Test]
    procedure DovrebbeIgnorareITastiCheNonSiAbbassano;
    [Test]
    procedure DovrebbeRimostrareIlMessaggioConIlTastoDiRefresh;
    [Test]
    procedure DovrebbeAprireLaChatConIlTastoDellaChatInRete;
    [Test]
    procedure DovrebbeNonAprireLaChatSenzaRete;
    [Test]
    procedure DovrebbeAprireLaChatVersoUnGiocatore;
    [Test]
    procedure DovrebbeNonAprireLaChatVersoUnGiocatoreConDueGiocatori;
    [Test]
    procedure DovrebbeNonAprireLaChatVersoUnGiocatoreAssenteOSenzaTasto;
    [Test]
    procedure DovrebbeSgridareChiParlaDaSolo;
    [Test]
    procedure DovrebbeScrivereInMaiuscoloEMandareICaratteri;
    [Test]
    procedure DovrebbeInviareIlMessaggioConInvio;
    [Test]
    procedure DovrebbeChiudereSenzaMessaggioConUnaRigaVuota;
    [Test]
    procedure DovrebbeChiudereConEscSenzaMangiareIlTasto;
    [Test]
    procedure DovrebbeCancellareConIlBackspace;
    [Test]
    procedure DovrebbeUsareLoShiftPerIlSimbolo;
    [Test]
    procedure DovrebbeTradurreLaTastieraFrancese;
    [Test]
    procedure DovrebbeLasciareUnTastoOltreLaTabellaDelloShift;
    [Test]
    procedure DovrebbeMandareUnaMacro;
    [Test]
    procedure DovrebbeIgnorareUnTastoCheNonEUnNumeroConAlt;
    [Test]
    procedure DovrebbeDireSeLaCodaEPiena;
    [Test]
    procedure DovrebbeRicevereUnMessaggioPerTutti;
    [Test]
    procedure DovrebbeRicevereUnMessaggioPerMe;
    [Test]
    procedure DovrebbeIgnorareUnMessaggioPerUnAltro;
    [Test]
    procedure DovrebbeIgnorareChiNonGioca;
    [Test]
    procedure DovrebbeIgnorareIPropriCaratteri;
    [Test]
    procedure DovrebbeNonLeggereNienteSenzaRete;
    [Test]
    procedure DovrebbeIgnorareUnaRigaVuotaRicevuta;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Types;

const
  KEY_ENTER = 13;
  KEY_ESCAPE = 27;
  KEY_BACKSPACE = 127;
  KEY_RSHIFT = $80 + $36;
  KEY_ALT = $80 + $38;

{ TTestHudChat }

procedure TTestHudChat.Setup;
begin
  FWorld := TFakeHudWorld.Create;
  FWorldRef := FWorld;
  FWorld.NetGame := True;
  FWorld.Attached := True;
  FWorld.InGame[0] := True;
  FWorld.InGame[1] := True;
  FWorld.InGame[2] := True;
  FWorld.Console := 0;
  FBar := THudMessageBar.Create(140, FWorld, FWorld, FWorld, FWorld);
  FBarRef := FBar;
  FBar.Start(0, 0, 1, 9, 33);
  FChat := THudChat.Create(DoomHudRules, FWorld, FWorld, FWorld, FWorld, FWorld, FBarRef);
  FChat.Start(0, 9, 33);
end;

procedure TTestHudChat.TearDown;
begin
  FChat.Free;
  FBar := nil;
  FBarRef := nil;
  FWorldRef := nil;
end;

procedure TTestHudChat.Type_(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    FChat.Responder(Ord(AText[LIndex]), True);
end;

function TTestHudChat.Drain: string;
var
  LChar: Char;
begin
  Result := '';
  repeat
    LChar := FChat.DequeueChar;
    if LChar <> #0 then
      Result := Result + LChar;
  until LChar = #0;
end;

procedure TTestHudChat.DovrebbeRifiutareIServiziMancanti;
begin
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(DoomHudRules, nil, FWorld, FWorld, FWorld, FWorld, FBarRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(DoomHudRules, FWorld, nil, FWorld, FWorld, FWorld, FBarRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(DoomHudRules, FWorld, FWorld, nil, FWorld, FWorld, FBarRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(DoomHudRules, FWorld, FWorld, FWorld, nil, FWorld, FBarRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(DoomHudRules, FWorld, FWorld, FWorld, FWorld, nil, FBarRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(DoomHudRules, FWorld, FWorld, FWorld, FWorld, FWorld, nil);
    end,
    EArgumentNilException);
end;

procedure TTestHudChat.DovrebbeRifiutareUnNumeroDiGiocatoriNonValido;
var
  LRules: THudRules;
begin
  LRules := DoomHudRules;
  LRules.MaxPlayers := 0;
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(LRules, FWorld, FWorld, FWorld, FWorld, FWorld, FBarRef);
    end,
    EHudException);
  LRules.MaxPlayers := HUD_MAX_PLAYERS + 1;
  Assert.WillRaise(
    procedure
    begin
      THudChat.Create(LRules, FWorld, FWorld, FWorld, FWorld, FWorld, FBarRef);
    end,
    EHudException);
end;

procedure TTestHudChat.DovrebbeRicordareLoShiftEdAlt;
begin
  Assert.IsFalse(FChat.Responder(KEY_RSHIFT, True));
  Assert.IsFalse(FChat.Responder(KEY_ALT, True));
  Assert.IsFalse(FChat.Responder(KEY_RSHIFT, False));
  Assert.IsFalse(FChat.Responder(KEY_ALT, False));
end;

procedure TTestHudChat.DovrebbeIgnorareITastiCheNonSiAbbassano;
begin
  Assert.IsFalse(FChat.Responder(Ord('t'), False));
  Assert.IsFalse(FWorld.ChatOn);
end;

procedure TTestHudChat.DovrebbeRimostrareIlMessaggioConIlTastoDiRefresh;
begin
  Assert.IsTrue(FChat.Responder(KEY_ENTER, True));
  Assert.IsTrue(FBar.Visible);
  Assert.AreEqual(140, FBar.Counter);
end;

procedure TTestHudChat.DovrebbeAprireLaChatConIlTastoDellaChatInRete;
begin
  Assert.IsTrue(FChat.Responder(Ord('t'), True));
  Assert.IsTrue(FWorld.ChatOn);
  Assert.AreEqual(#5, Drain);
  Assert.AreEqual(0, FChat.Input.Line.Length);
end;

procedure TTestHudChat.DovrebbeNonAprireLaChatSenzaRete;
begin
  FWorld.NetGame := False;
  Assert.IsFalse(FChat.Responder(Ord('t'), True));
  Assert.IsFalse(FWorld.ChatOn);
end;

procedure TTestHudChat.DovrebbeAprireLaChatVersoUnGiocatore;
begin
  Assert.IsTrue(FChat.Responder(Ord('b'), True));
  Assert.IsTrue(FWorld.ChatOn);
  Assert.AreEqual(#2, Drain);
end;

procedure TTestHudChat.DovrebbeNonAprireLaChatVersoUnGiocatoreConDueGiocatori;
begin
  FWorld.InGame[2] := False;
  Assert.IsFalse(FChat.Responder(Ord('b'), True));
  Assert.IsFalse(FWorld.ChatOn);
end;

procedure TTestHudChat.DovrebbeNonAprireLaChatVersoUnGiocatoreAssenteOSenzaTasto;
begin
  // player 3 is not in the game, player 2 has no key
  Assert.IsFalse(FChat.Responder(Ord('d'), True));
  FWorld.DestinationKeys[2] := '';
  Assert.IsFalse(FChat.Responder(Ord('c'), True));
  Assert.IsFalse(FWorld.ChatOn);
end;

procedure TTestHudChat.DovrebbeSgridareChiParlaDaSolo;
var
  LIndex: Integer;
begin
  // the key of the console player: the message gets harsher with the tries
  FChat.Responder(Ord('a'), True);
  Assert.AreEqual('You mumble 1', FWorld.PlayerMessage);
  for LIndex := 2 to 5 do
    FChat.Responder(Ord('a'), True);
  Assert.AreEqual('You mumble 2', FWorld.PlayerMessage);
  for LIndex := 6 to 8 do
    FChat.Responder(Ord('a'), True);
  Assert.AreEqual('You mumble 3', FWorld.PlayerMessage);
  for LIndex := 9 to 31 do
    FChat.Responder(Ord('a'), True);
  Assert.AreEqual('You mumble 4', FWorld.PlayerMessage);
  Assert.AreEqual(31, FChat.TalkToSelfCount);
  FChat.Responder(Ord('a'), True);
  Assert.AreEqual('You mumble 5', FWorld.PlayerMessage);
  Assert.IsFalse(FWorld.ChatOn);
end;

procedure TTestHudChat.DovrebbeScrivereInMaiuscoloEMandareICaratteri;
begin
  FChat.Responder(Ord('t'), True);
  Type_('hi!');
  Assert.AreEqual('HI!', string(FChat.Input.Line.Text));
  Assert.AreEqual(#5'HI!', Drain);
end;

procedure TTestHudChat.DovrebbeInviareIlMessaggioConInvio;
begin
  FChat.Responder(Ord('t'), True);
  Type_('hello');
  Assert.IsTrue(FChat.Responder(KEY_ENTER, True));
  Assert.IsFalse(FWorld.ChatOn);
  Assert.AreEqual('HELLO', FWorld.PlayerMessage);
  Assert.AreEqual('HELLO', FChat.LastMessage);
  Assert.AreEqual(#5'HELLO'#13, Drain);
end;

procedure TTestHudChat.DovrebbeChiudereSenzaMessaggioConUnaRigaVuota;
begin
  FChat.Responder(Ord('t'), True);
  Assert.IsTrue(FChat.Responder(KEY_ENTER, True));
  Assert.IsFalse(FWorld.ChatOn);
  Assert.AreEqual('', FWorld.PlayerMessage);
end;

procedure TTestHudChat.DovrebbeChiudereConEscSenzaMangiareIlTasto;
begin
  FChat.Responder(Ord('t'), True);
  Assert.IsFalse(FChat.Responder(KEY_ESCAPE, True));
  Assert.IsFalse(FWorld.ChatOn);
end;

procedure TTestHudChat.DovrebbeCancellareConIlBackspace;
begin
  FChat.Responder(Ord('t'), True);
  Type_('ab');
  Assert.IsTrue(FChat.Responder(KEY_BACKSPACE, True));
  Assert.AreEqual('A', string(FChat.Input.Line.Text));
  Assert.AreEqual(#5'AB'#127, Drain);
end;

procedure TTestHudChat.DovrebbeUsareLoShiftPerIlSimbolo;
begin
  FChat.Responder(Ord('t'), True);
  FChat.Responder(KEY_RSHIFT, True);
  Type_('1');
  FChat.Responder(KEY_RSHIFT, False);
  Type_('1');
  Assert.AreEqual('!1', string(FChat.Input.Line.Text));
end;

procedure TTestHudChat.DovrebbeTradurreLaTastieraFrancese;
begin
  FWorld.French := True;
  FChat.Responder(Ord('t'), True);
  // 'a' is the key of the 'q'
  Type_('a');
  Assert.AreEqual('Q', string(FChat.Input.Line.Text));
end;

procedure TTestHudChat.DovrebbeLasciareUnTastoOltreLaTabellaDelloShift;
begin
  FChat.Responder(Ord('t'), True);
  FChat.Responder(KEY_RSHIFT, True);
  Assert.IsFalse(FChat.Responder($AE, True));
  Assert.AreEqual(0, FChat.Input.Line.Length);
end;

procedure TTestHudChat.DovrebbeMandareUnaMacro;
begin
  FChat.Responder(Ord('t'), True);
  FChat.Responder(KEY_ALT, True);
  Assert.IsTrue(FChat.Responder(Ord('3'), True));
  Assert.IsFalse(FWorld.ChatOn);
  Assert.AreEqual('macro3', FWorld.PlayerMessage);
  Assert.AreEqual('macro3', FChat.LastMessage);
  Assert.AreEqual(#5#13'macro3'#13, Drain);
end;

procedure TTestHudChat.DovrebbeIgnorareUnTastoCheNonEUnNumeroConAlt;
begin
  FChat.Responder(Ord('t'), True);
  FChat.Responder(KEY_ALT, True);
  Assert.IsFalse(FChat.Responder(Ord('x'), True));
  Assert.IsFalse(FChat.Responder(Ord(' '), True));
  Assert.IsTrue(FWorld.ChatOn);
  Assert.AreEqual(#5, Drain);
end;

procedure TTestHudChat.DovrebbeDireSeLaCodaEPiena;
var
  LIndex: Integer;
begin
  FChat.Responder(Ord('t'), True);
  for LIndex := 1 to HUD_CHAT_QUEUE_SIZE do
    FChat.Responder(Ord('A'), True);
  Assert.AreEqual('[Message unsent]', FWorld.PlayerMessage);
end;

procedure TTestHudChat.DovrebbeRicevereUnMessaggioPerTutti;
begin
  // player 1 sends to everybody: the destination, then H, I and return
  FWorld.ChatChars[1] := 5;
  FChat.Tick;
  FWorld.ChatChars[1] := Ord('h');
  FChat.Tick;
  FWorld.ChatChars[1] := Ord('I');
  FChat.Tick;
  FWorld.ChatChars[1] := KEY_ENTER;
  FChat.Tick;
  Assert.AreEqual('Player1: HI', string(FBar.Window.Current.Text));
  Assert.AreEqual(1, FWorld.Sounds);
  Assert.AreEqual(0, Integer(FWorld.ChatChars[1]));
  Assert.IsTrue(FBar.Locked);
end;

procedure TTestHudChat.DovrebbeRicevereUnMessaggioPerMe;
begin
  FWorld.ChatChars[2] := 1;
  FChat.Tick;
  FWorld.ChatChars[2] := Ord('A');
  FChat.Tick;
  FWorld.ChatChars[2] := KEY_ENTER;
  FChat.Tick;
  Assert.AreEqual('Player2: A', string(FBar.Window.Current.Text));
end;

procedure TTestHudChat.DovrebbeIgnorareUnMessaggioPerUnAltro;
begin
  FWorld.ChatChars[2] := 2;
  FChat.Tick;
  FWorld.ChatChars[2] := Ord('A');
  FChat.Tick;
  FWorld.ChatChars[2] := KEY_ENTER;
  FChat.Tick;
  Assert.AreEqual(0, FBar.Window.Current.Length);
  Assert.AreEqual(0, FWorld.Sounds);
  // the line was emptied anyway: a new message for everybody has only its own text
  FWorld.ChatChars[2] := 5;
  FChat.Tick;
  FWorld.ChatChars[2] := Ord('B');
  FChat.Tick;
  FWorld.ChatChars[2] := KEY_ENTER;
  FChat.Tick;
  Assert.AreEqual('Player2: B', string(FBar.Window.Current.Text));
end;

procedure TTestHudChat.DovrebbeIgnorareChiNonGioca;
begin
  FWorld.InGame[1] := False;
  FWorld.ChatChars[1] := 5;
  FChat.Tick;
  Assert.AreEqual(5, Integer(FWorld.ChatChars[1]));
end;

procedure TTestHudChat.DovrebbeIgnorareIPropriCaratteri;
begin
  FWorld.ChatChars[0] := Ord('A');
  FChat.Tick;
  Assert.AreEqual(Ord('A'), Integer(FWorld.ChatChars[0]));
end;

procedure TTestHudChat.DovrebbeNonLeggereNienteSenzaRete;
begin
  FWorld.NetGame := False;
  FWorld.ChatChars[1] := 5;
  FChat.Tick;
  Assert.AreEqual(5, Integer(FWorld.ChatChars[1]));
end;

procedure TTestHudChat.DovrebbeIgnorareUnaRigaVuotaRicevuta;
begin
  FWorld.ChatChars[1] := 5;
  FChat.Tick;
  FWorld.ChatChars[1] := KEY_ENTER;
  FChat.Tick;
  Assert.AreEqual(0, FBar.Window.Current.Length);
  Assert.AreEqual(0, FWorld.Sounds);
end;

end.
