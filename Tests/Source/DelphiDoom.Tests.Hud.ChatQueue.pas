{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the chat queue          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.ChatQueue;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.ChatQueue;

type
  [TestFixture]
  [Category('hud')]
  TTestHudChatQueue = class(TObject)
  private
    FQueue: THudChatQueue;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareZeroSeVuota;
    [Test]
    procedure DovrebbeRestituireICaratteriNellOrdineIn;
    [Test]
    procedure DovrebbeRifiutareUnCarattereQuandoEPiena;
    [Test]
    procedure DovrebbeRiusareIPostiLiberati;
    [Test]
    procedure DovrebbeContareICaratteriInAttesa;
  end;

implementation

uses
  DelphiDoom.Hud.Types;

{ TTestHudChatQueue }

procedure TTestHudChatQueue.Setup;
begin
  FQueue := THudChatQueue.Create;
end;

procedure TTestHudChatQueue.TearDown;
begin
  FQueue.Free;
end;

procedure TTestHudChatQueue.DovrebbeDareZeroSeVuota;
begin
  Assert.AreEqual(#0, FQueue.Dequeue);
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestHudChatQueue.DovrebbeRestituireICaratteriNellOrdineIn;
begin
  FQueue.Enqueue('a');
  FQueue.Enqueue('b');
  FQueue.Enqueue('c');
  Assert.AreEqual('a', FQueue.Dequeue);
  Assert.AreEqual('b', FQueue.Dequeue);
  Assert.AreEqual('c', FQueue.Dequeue);
  Assert.AreEqual(#0, FQueue.Dequeue);
end;

procedure TTestHudChatQueue.DovrebbeRifiutareUnCarattereQuandoEPiena;
var
  LIndex: Integer;
begin
  for LIndex := 1 to HUD_CHAT_QUEUE_SIZE - 1 do
    Assert.IsTrue(FQueue.Enqueue('x'));
  Assert.IsFalse(FQueue.Enqueue('y'));
  Assert.AreEqual(HUD_CHAT_QUEUE_SIZE - 1, FQueue.Count);
end;

procedure TTestHudChatQueue.DovrebbeRiusareIPostiLiberati;
var
  LIndex: Integer;
begin
  for LIndex := 1 to HUD_CHAT_QUEUE_SIZE - 1 do
    FQueue.Enqueue('x');
  Assert.AreEqual('x', FQueue.Dequeue);
  Assert.IsTrue(FQueue.Enqueue('z'));
  for LIndex := 2 to HUD_CHAT_QUEUE_SIZE - 1 do
    FQueue.Dequeue;
  Assert.AreEqual('z', FQueue.Dequeue);
end;

procedure TTestHudChatQueue.DovrebbeContareICaratteriInAttesa;
begin
  FQueue.Enqueue('a');
  FQueue.Enqueue('b');
  Assert.AreEqual(2, FQueue.Count);
  FQueue.Dequeue;
  Assert.AreEqual(1, FQueue.Count);
end;

end.
