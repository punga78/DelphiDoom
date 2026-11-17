{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the sink that fills the    }
{  state of the client from the messages the parser of NetQ3 reads (the         }
{  parser has its own parity on cl_parse.c: Tests\Data\Net\q3demo-golden.txt)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientMessageSink;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostLoop')]
  TTestQ3ClientMessageSink = class
  public
    [Test]
    procedure UnGamestateDovrebbeRiempireLeConfigstringEIlNumeroDelClient;
    [Test]
    procedure UnoSnapshotDovrebbeDiventareQuelloCorrenteConLeSueEntita;
    [Test]
    procedure UnComandoDelServerGiaVistoNonDovrebbeEssereRiscritto;
    [Test]
    procedure UnSecondoGamestateDovrebbeCancellareLoStatoDiPrima;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Q3.Factory, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf,
  DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec,
  DelphiDoom.Net.Q3.Factory, DelphiDoom.Net.Q3.ServerMessageParser, DelphiDoom.Q3Host.Client.Types,
  DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientMessageSink;

type
  /// <summary>The state, the sink and the parser, and a writer of server messages</summary>
  TRig = class
  public
    Console: TQ3Console;
    State: TQ3ClientState;
    StateIntf: IQ3HostClientState;
    Coder: IQ3HuffmanCoder;
    EntityCodec: TQ3EntityStateCodec;
    PlayerCodec: TQ3PlayerStateCodec;
    Parser: TQ3ServerMessageParser;
    constructor Create;
    destructor Destroy; override;
    function NewWriter: TQ3Message;
    procedure Parse(AWriter: TQ3Message; ASequence: Integer);
  end;

constructor TRig.Create;
begin
  inherited Create;
  Console := TQ3Console.Create;
  Console.Init;
  State := TQ3ClientState.Create(Console.Arguments);
  StateIntf := State;
  Coder := TQ3NetFactory.CreateMessageHuffman;
  EntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  PlayerCodec := TQ3NetFactory.CreatePlayerStateCodec;
  Parser := TQ3NetFactory.CreateServerMessageParser(Coder, EntityCodec, PlayerCodec,
    TQ3ClientMessageSink.Create(State));
end;

destructor TRig.Destroy;
begin
  Parser.Free;
  EntityCodec.Free;
  PlayerCodec.Free;
  Console.Free;
  inherited Destroy;
end;

function TRig.NewWriter: TQ3Message;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 16384);
  Result := TQ3NetFactory.CreateMessage(Coder);
  Result.Init(LBuffer, Length(LBuffer));
  Result.AllowOverflow := True;
end;

procedure TRig.Parse(AWriter: TQ3Message; ASequence: Integer);
begin
  AWriter.WriteByte(Q3_SVC_EOF);
  Parser.ParseMessage(Copy(AWriter.Data, 0, AWriter.CurSize), AWriter.CurSize, ASequence);
end;

// a gamestate with two configstrings and a baseline
procedure WriteGamestate(ARig: TRig; AWriter: TQ3Message; ACommandSequence, AClientNumber: Integer);
var
  LNull, LBaseline: TQ3EntityState;
begin
  AWriter.WriteLong(0);
  AWriter.WriteByte(Q3_SVC_GAMESTATE);
  AWriter.WriteLong(ACommandSequence);
  AWriter.WriteByte(Q3_SVC_CONFIGSTRING);
  AWriter.WriteShort(1);
  AWriter.WriteBigString('\sv_serverid\77');
  AWriter.WriteByte(Q3_SVC_CONFIGSTRING);
  AWriter.WriteShort(5);
  AWriter.WriteBigString('hello');
  LNull := Default(TQ3EntityState);
  LBaseline := Default(TQ3EntityState);
  LBaseline.Number := 3;
  LBaseline.ModelIndex := 9;
  AWriter.WriteByte(Q3_SVC_BASELINE);
  ARig.EntityCodec.WriteDelta(AWriter, @LNull, @LBaseline, True);
  AWriter.WriteByte(Q3_SVC_EOF);
  AWriter.WriteLong(AClientNumber);
  AWriter.WriteLong(4321);
end;

procedure TTestQ3ClientMessageSink.UnGamestateDovrebbeRiempireLeConfigstringEIlNumeroDelClient;
var
  LRig: TRig;
  LWriter: TQ3Message;
  LValue: AnsiString;
begin
  LRig := TRig.Create;
  try
    LWriter := LRig.NewWriter;
    try
      WriteGamestate(LRig, LWriter, 7, 2);
      LRig.Parse(LWriter, 1);
    finally
      LWriter.Free;
    end;
    Assert.IsTrue(LRig.StateIntf.TryGetConfigString(5, LValue));
    Assert.AreEqual('hello', string(LValue));
    Assert.IsTrue(LRig.StateIntf.TryGetConfigString(1, LValue));
    Assert.AreEqual('\sv_serverid\77', string(LValue));
    Assert.IsFalse(LRig.StateIntf.TryGetConfigString(2, LValue), 'a string never sent has no offset');
    Assert.AreEqual(2, LRig.State.ConnectedClientNumber);
    Assert.AreEqual(4321, LRig.State.ChecksumFeed);
    Assert.AreEqual(7, LRig.State.ServerCommandSequence);
  finally
    LRig.Free;
  end;
end;

procedure TTestQ3ClientMessageSink.UnoSnapshotDovrebbeDiventareQuelloCorrenteConLeSueEntita;
var
  LRig: TRig;
  LWriter: TQ3Message;
  LNull, LEntity: TQ3EntityState;
  LPlayer: TQ3PlayerState;
  LNumber, LTime: Integer;
  LSnapshot: TQ3HostSnapshot;
begin
  LRig := TRig.Create;
  try
    LWriter := LRig.NewWriter;
    try
      WriteGamestate(LRig, LWriter, 0, 0);
      LRig.Parse(LWriter, 1);
    finally
      LWriter.Free;
    end;
    LWriter := LRig.NewWriter;
    try
      LWriter.WriteLong(0);
      LWriter.WriteByte(Q3_SVC_SNAPSHOT);
      LWriter.WriteLong(1250);
      LWriter.WriteByte(0);
      LWriter.WriteByte(0);
      LWriter.WriteByte(0);
      LPlayer := Default(TQ3PlayerState);
      LPlayer.CommandTime := 1200;
      LPlayer.ClientNum := 0;
      LRig.PlayerCodec.WriteDelta(LWriter, nil, @LPlayer);
      LNull := Default(TQ3EntityState);
      LEntity := Default(TQ3EntityState);
      LEntity.Number := 3;
      LEntity.ModelIndex := 9;
      LRig.EntityCodec.WriteDelta(LWriter, @LNull, @LEntity, True);
      LWriter.WriteBits(Q3_MAX_GENTITIES - 1, Q3_GENTITYNUM_BITS);
      LRig.Parse(LWriter, 2);
    finally
      LWriter.Free;
    end;
    LRig.State.CurrentSnapshotNumber(LNumber, LTime);
    Assert.AreEqual(2, LNumber);
    Assert.AreEqual(1250, LTime);
    Assert.IsTrue(LRig.State.TryGetSnapshot(2, LSnapshot));
    Assert.AreEqual(1, LSnapshot.NumEntities);
    Assert.AreEqual(3, PQ3EntityState(@LSnapshot.Entities[0])^.Number);
    Assert.AreEqual(9, PQ3EntityState(@LSnapshot.Entities[0])^.ModelIndex);
    Assert.AreEqual(1200, PQ3PlayerState(@LSnapshot.PlayerState[0])^.CommandTime);
  finally
    LRig.Free;
  end;
end;

procedure TTestQ3ClientMessageSink.UnComandoDelServerGiaVistoNonDovrebbeEssereRiscritto;
var
  LRig: TRig;
  LWriter: TQ3Message;
begin
  LRig := TRig.Create;
  try
    LWriter := LRig.NewWriter;
    try
      LWriter.WriteLong(0);
      LWriter.WriteByte(Q3_SVC_SERVERCOMMAND);
      LWriter.WriteLong(3);
      LWriter.WriteString('print "one"');
      // the same sequence again with another text: the C ignores it
      LWriter.WriteByte(Q3_SVC_SERVERCOMMAND);
      LWriter.WriteLong(3);
      LWriter.WriteString('print "two"');
      LRig.Parse(LWriter, 1);
    finally
      LWriter.Free;
    end;
    // the sequence jumps to 3 (commands 1 and 2 were lost)
    Assert.AreEqual(3, LRig.State.ServerCommandSequence);
    Assert.IsTrue(LRig.StateIntf.GetServerCommand(3));
    Assert.AreEqual('print', string(LRig.Console.Arguments.Argv(0)));
    Assert.AreEqual('one', string(LRig.Console.Arguments.Argv(1)));
  finally
    LRig.Free;
  end;
end;

procedure TTestQ3ClientMessageSink.UnSecondoGamestateDovrebbeCancellareLoStatoDiPrima;
var
  LRig: TRig;
  LWriter: TQ3Message;
  LValue: AnsiString;
begin
  LRig := TRig.Create;
  try
    LWriter := LRig.NewWriter;
    try
      WriteGamestate(LRig, LWriter, 7, 2);
      LRig.Parse(LWriter, 1);
    finally
      LWriter.Free;
    end;
    // a second gamestate with no configstring 5 (CL_ClearState wipes the state)
    LWriter := LRig.NewWriter;
    try
      LWriter.WriteLong(0);
      LWriter.WriteByte(Q3_SVC_GAMESTATE);
      LWriter.WriteLong(9);
      LWriter.WriteByte(Q3_SVC_EOF);
      LWriter.WriteLong(1);
      LWriter.WriteLong(0);
      LRig.Parse(LWriter, 2);
    finally
      LWriter.Free;
    end;
    Assert.IsFalse(LRig.StateIntf.TryGetConfigString(5, LValue));
    Assert.AreEqual(1, LRig.State.ConnectedClientNumber);
    Assert.AreEqual(9, LRig.State.ServerCommandSequence);
  finally
    LRig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3ClientMessageSink);

end.
