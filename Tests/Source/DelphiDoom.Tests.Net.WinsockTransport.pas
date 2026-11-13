{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - UDP on the loopback                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.WinsockTransport;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Types, DelphiDoom.Net.Intf,
  DelphiDoom.Net.WinsockTransport, DelphiDoom.Tests.Net.Fakes, DelphiDoom.Tests.Net.TicSync;

type
  /// <summary>
  ///   Two transports on 127.0.0.1 with ports chosen by Windows. No sleep: a datagram is looked for
  ///   a bounded number of times. This is the only test that uses the network of the machine
  /// </summary>
  [TestFixture]
  [Category('net')]
  [Category('loopback')]
  TTestNetWinsockTransport = class(TObject)
  private
    FFirst: TWinsockNetTransport;
    FFirstIntf: INetTransport;
    FSecond: TWinsockNetTransport;
    FSecondIntf: INetTransport;
    function Loopback(APort: Word): TNetNodeAddress;
    function Poll(const ATransport: INetTransport; out ANode: Integer; out AData: TBytes): Boolean;
    procedure Connect(ASecondMaxPacket: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDatagramsGoBothWays;
    [Test]
    procedure TestSenderIsKnownByItsAddress;
    [Test]
    procedure TestNoDatagramIsNoPacket;
    [Test]
    procedure TestDatagramLongerThanTheBufferIsLost;
    [Test]
    procedure TestLocalPortChosenByWindows;
    [Test]
    procedure TestNodeZeroCannotBeSentTo;
    [Test]
    procedure TestTwoSyncsExchangeCommandsOverUdp;
  end;

implementation

uses
  DelphiDoom.Net.Factory;

{ TTestNetWinsockTransport }

function Bytes(const AValues: array of Byte): TBytes;
begin
  SetLength(Result, Length(AValues));
  if Length(AValues) > 0 then
    Move(AValues[0], Result[0], Length(AValues));
end;

procedure TTestNetWinsockTransport.TearDown;
begin
  FSecondIntf := nil;
  FFirstIntf := nil;
  FSecond := nil;
  FFirst := nil;
end;

function TTestNetWinsockTransport.Loopback(APort: Word): TNetNodeAddress;
begin
  Result := Default(TNetNodeAddress);
  Result.Host := '127.0.0.1';
  Result.IsLiteral := True;
  Result.Port := APort;
end;

procedure TTestNetWinsockTransport.Connect(ASecondMaxPacket: Integer);
begin
  FFirst := TWinsockNetTransport.Create(0, [Loopback(1)]);
  FFirstIntf := FFirst;
  FSecond := TWinsockNetTransport.Create(0, [Loopback(FFirst.LocalPort)], ASecondMaxPacket);
  FSecondIntf := FSecond;
  FFirst.SetPeerAddress(1, Loopback(FSecond.LocalPort));
end;

function TTestNetWinsockTransport.Poll(const ATransport: INetTransport; out ANode: Integer;
  out AData: TBytes): Boolean;
var
  LAttempt: Integer;
begin
  Result := False;
  for LAttempt := 1 to 200000 do
    if ATransport.Receive(ANode, AData) then
      Exit(True);
end;

procedure TTestNetWinsockTransport.TestDatagramsGoBothWays;
var
  LNode: Integer;
  LData: TBytes;
begin
  Connect(1500);
  FFirstIntf.Send(1, Bytes([1, 2, 3, 4, 5]));
  Assert.IsTrue(Poll(FSecondIntf, LNode, LData), 'il secondo riceve');
  Assert.AreEqual(1, LNode);
  Assert.AreEqual<Integer>(5, Length(LData));
  Assert.AreEqual(Byte(3), LData[2]);
  FSecondIntf.Send(1, Bytes([9, 8]));
  Assert.IsTrue(Poll(FFirstIntf, LNode, LData), 'il primo riceve');
  Assert.AreEqual(1, LNode);
  Assert.AreEqual<Integer>(2, Length(LData));
  Assert.AreEqual(Byte(8), LData[1]);
end;

procedure TTestNetWinsockTransport.TestSenderIsKnownByItsAddress;
var
  LNode: Integer;
  LData: TBytes;
begin
  Connect(1500);
  Assert.AreEqual(2, FFirstIntf.NodeCount);
  FSecondIntf.Send(1, Bytes([7]));
  Assert.IsTrue(Poll(FFirstIntf, LNode, LData));
  Assert.AreEqual(1, LNode, 'il nodo 0 e il computer stesso, mai un mittente');
end;

procedure TTestNetWinsockTransport.TestNoDatagramIsNoPacket;
var
  LNode: Integer;
  LData: TBytes;
begin
  Connect(1500);
  Assert.IsFalse(FFirstIntf.Receive(LNode, LData));
  Assert.AreEqual(-1, LNode);
end;

procedure TTestNetWinsockTransport.TestDatagramLongerThanTheBufferIsLost;
var
  LNode: Integer;
  LData: TBytes;
begin
  Connect(16);
  SetLength(LData, 100);
  FillChar(LData[0], 100, 1);
  FFirstIntf.Send(1, LData);
  // Windows reports the datagram that does not fit; it is not an error of the game
  Poll(FSecondIntf, LNode, LData);
  FFirstIntf.Send(1, Bytes([5, 6, 7]));
  Assert.IsTrue(Poll(FSecondIntf, LNode, LData));
  Assert.AreEqual<Integer>(3, Length(LData), 'il pacchetto dopo arriva');
end;

procedure TTestNetWinsockTransport.TestLocalPortChosenByWindows;
begin
  Connect(1500);
  Assert.IsTrue(FFirst.LocalPort <> 0);
  Assert.IsTrue(FSecond.LocalPort <> 0);
  Assert.IsTrue(FFirst.LocalPort <> FSecond.LocalPort);
end;

procedure TTestNetWinsockTransport.TestNodeZeroCannotBeSentTo;
begin
  Connect(1500);
  Assert.WillRaise(
    procedure
    begin
      FFirstIntf.Send(0, Bytes([1]));
    end, ENetException);
  Assert.WillRaise(
    procedure
    begin
      FFirstIntf.Send(2, Bytes([1]));
    end, ENetException);
end;

procedure TTestNetWinsockTransport.TestTwoSyncsExchangeCommandsOverUdp;
var
  LA: TNodeRig;
  LB: TNodeRig;
  LAttempt: Integer;
begin
  Connect(1500);
  LA := TNodeRig.CreateOn(FFirstIntf, 2, 0, 1, 0);
  LB := TNodeRig.CreateOn(FSecondIntf, 2, 1, 1, 0);
  try
    LA.Clock.Tics := 1;
    LB.Clock.Tics := 1;
    LAttempt := 0;
    repeat
      LA.Sync.NetUpdate;
      LB.Sync.NetUpdate;
      Inc(LAttempt);
    until ((LA.Sync.NetTic(1) >= 1) and (LB.Sync.NetTic(1) >= 1)) or (LAttempt > 100000);
    Assert.AreEqual(1, LA.Sync.NetTic(1), 'A ha il comando di B');
    Assert.AreEqual(1, LB.Sync.NetTic(1), 'B ha il comando di A');
    Assert.AreEqual(Byte(1), LA.Sync.NetCommand(1, 0)[0], 'e viene dal giocatore 1');
    Assert.AreEqual(Byte(0), LB.Sync.NetCommand(0, 0)[0]);
    Assert.AreEqual(1, LA.Planner.LowTic);
  finally
    LB.Free;
    LA.Free;
  end;
end;

end.
