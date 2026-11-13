{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the message bar         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.MessageBar;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.MessageBar, DelphiDoom.Tests.Hud.Fakes;

type
  [TestFixture]
  [Category('hud')]
  TTestHudMessageBar = class(TObject)
  private
    FWorld: TFakeHudWorld;
    FWorldRef: IInterface;
    FBar: THudMessageBar;
    FBarRef: IInterface;
    procedure TickMany(const ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareIServiziMancanti;
    [Test]
    procedure DovrebbePartireSenzaMessaggi;
    [Test]
    procedure DovrebbeMostrareIlMessaggioDelGiocatore;
    [Test]
    procedure DovrebbeNonMostrareSeIMessaggiSonoSpenti;
    [Test]
    procedure DovrebbeMostrareUnMessaggioForzatoAncheSeSpenti;
    [Test]
    procedure DovrebbeNonSostituireUnMessaggioProtetto;
    [Test]
    procedure DovrebbeSostituireUnMessaggioProtettoSeIlNuovoEForzato;
    [Test]
    procedure DovrebbeSpegnereIlMessaggioDopoIlTempo;
    [Test]
    procedure DovrebbeTenereAcceseLeRigheCheRestano;
    [Test]
    procedure DovrebbeRimostrareIlMessaggioConRefresh;
    [Test]
    procedure DovrebbeMettereUnaRigaDiChatEProteggerla;
    [Test]
    procedure DovrebbeIgnorareIlMessaggioSenzaGiocatore;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Types;

{ TTestHudMessageBar }

procedure TTestHudMessageBar.Setup;
begin
  FWorld := TFakeHudWorld.Create;
  FWorldRef := FWorld;
  FBar := THudMessageBar.Create(140, FWorld, FWorld, FWorld, FWorld);
  FBarRef := FBar;
  FBar.Start(0, 0, 1, 9, 33);
  FWorld.Attached := True;
end;

procedure TTestHudMessageBar.TearDown;
begin
  FBar := nil;
  FBarRef := nil;
  FWorldRef := nil;
end;

procedure TTestHudMessageBar.TickMany(const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FBar.Tick;
end;

procedure TTestHudMessageBar.DovrebbeRifiutareIServiziMancanti;
begin
  Assert.WillRaise(
    procedure
    begin
      THudMessageBar.Create(140, nil, FWorld, FWorld, FWorld);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudMessageBar.Create(140, FWorld, nil, FWorld, FWorld);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      THudMessageBar.Create(140, FWorld, FWorld, nil, FWorld);
    end,
    EArgumentNilException);
end;

procedure TTestHudMessageBar.DovrebbePartireSenzaMessaggi;
begin
  FBar.Tick;
  Assert.IsFalse(FBar.Visible);
  Assert.IsFalse(FBar.Locked);
  Assert.AreEqual(0, FBar.Counter);
end;

procedure TTestHudMessageBar.DovrebbeMostrareIlMessaggioDelGiocatore;
begin
  FWorld.PlayerMessage := 'You got the shotgun';
  FBar.Tick;
  Assert.IsTrue(FBar.Visible);
  Assert.AreEqual(140, FBar.Counter);
  Assert.AreEqual('You got the shotgun', string(FBar.Window.Current.Text));
  Assert.AreEqual('', FWorld.PlayerMessage);
  Assert.IsFalse(FBar.Locked);
end;

procedure TTestHudMessageBar.DovrebbeNonMostrareSeIMessaggiSonoSpenti;
begin
  FWorld.MessagesShown := False;
  FWorld.PlayerMessage := 'hidden';
  FBar.Tick;
  Assert.IsFalse(FBar.Visible);
  Assert.AreEqual('hidden', FWorld.PlayerMessage);
end;

procedure TTestHudMessageBar.DovrebbeMostrareUnMessaggioForzatoAncheSeSpenti;
begin
  FWorld.MessagesShown := False;
  FWorld.MessageForced := True;
  FWorld.PlayerMessage := 'important';
  FBar.Tick;
  Assert.IsTrue(FBar.Visible);
  Assert.IsTrue(FBar.Locked);
  Assert.IsFalse(FWorld.MessageForced);
end;

procedure TTestHudMessageBar.DovrebbeNonSostituireUnMessaggioProtetto;
begin
  FWorld.MessageForced := True;
  FWorld.PlayerMessage := 'first';
  FBar.Tick;
  FWorld.PlayerMessage := 'second';
  FBar.Tick;
  Assert.AreEqual('first', string(FBar.Window.Current.Text));
  Assert.AreEqual('second', FWorld.PlayerMessage);
end;

procedure TTestHudMessageBar.DovrebbeSostituireUnMessaggioProtettoSeIlNuovoEForzato;
begin
  FWorld.MessageForced := True;
  FWorld.PlayerMessage := 'first';
  FBar.Tick;
  FWorld.MessageForced := True;
  FWorld.PlayerMessage := 'second';
  FBar.Tick;
  Assert.AreEqual('first'#13#10'second', string(FBar.Window.Current.Text));
  Assert.AreEqual('', FWorld.PlayerMessage);
end;

procedure TTestHudMessageBar.DovrebbeSpegnereIlMessaggioDopoIlTempo;
begin
  FWorld.MessageForced := True;
  FWorld.PlayerMessage := 'bye';
  FBar.Tick;
  TickMany(139);
  Assert.IsTrue(FBar.Visible);
  Assert.AreEqual(1, FBar.Counter);
  FBar.Tick;
  Assert.IsFalse(FBar.Visible);
  Assert.IsFalse(FBar.Locked);
  Assert.AreEqual(0, FBar.Counter);
  Assert.AreEqual(0, FBar.Window.Current.Length);
end;

procedure TTestHudMessageBar.DovrebbeTenereAcceseLeRigheCheRestano;
begin
  FWorld.PlayerMessage := 'one';
  FBar.Tick;
  FWorld.PlayerMessage := 'two';
  FBar.Tick;
  TickMany(139);
  FBar.Tick;
  // the first row went away, the second is still there for a new timeout
  Assert.IsTrue(FBar.Visible);
  Assert.AreEqual(140, FBar.Counter);
  Assert.AreEqual('two', string(FBar.Window.Current.Text));
end;

procedure TTestHudMessageBar.DovrebbeRimostrareIlMessaggioConRefresh;
begin
  FBar.Refresh;
  Assert.IsTrue(FBar.Visible);
  Assert.AreEqual(140, FBar.Counter);
end;

procedure TTestHudMessageBar.DovrebbeMettereUnaRigaDiChatEProteggerla;
begin
  FBar.PostChat('Ann: ', 'hello');
  Assert.AreEqual('Ann: hello', string(FBar.Window.Current.Text));
  Assert.IsTrue(FBar.Visible);
  Assert.IsTrue(FBar.Locked);
  Assert.AreEqual(140, FBar.Counter);
  Assert.AreEqual('Ann: hello'#13#10, FWorld.EchoLog);
end;

procedure TTestHudMessageBar.DovrebbeIgnorareIlMessaggioSenzaGiocatore;
begin
  FWorld.Attached := False;
  FWorld.PlayerMessage := 'lost';
  FBar.Tick;
  Assert.IsFalse(FBar.Visible);
end;

end.
