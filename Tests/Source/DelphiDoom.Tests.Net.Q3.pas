{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the network of Quake III (messages, Huffman,      }
{  deltas, network channel)                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Q3;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.AdaptiveHuffman,
  DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.HuffmanCompressor, DelphiDoom.Net.Q3.EntityStateCodec,
  DelphiDoom.Net.Q3.PlayerStateCodec, DelphiDoom.Net.Q3.Netchan, DelphiDoom.Net.Q3.Factory,
  DelphiDoom.Tests.Net.Q3Fakes;

type
  /// <summary>The rules of the network of Quake III that the parity scenarios do not show one by one</summary>
  [TestFixture]
  [Category('Net')]
  TTestQ3Net = class
  strict private
    FCoder: IQ3HuffmanCoder;
    FLog: TFakeQ3Log;
    FLogIntf: ILog;
    FTransport: TFakeQ3Transport;
    FTransportIntf: IQ3NetTransport;
    function NewMessage(ALength: Integer; ABufferLength: Integer = -1): TQ3Message;
    function NewChannel(ASource: TQ3NetSource): TQ3Netchan;
    function Address: TQ3NetAddress;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLeDimensioniDelC;
    [Test]
    procedure DovrebbeAvereLeTabelleDeiCampi;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaOltreIlBuffer;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiBitSbagliato;
    [Test]
    procedure DovrebbeSegnalareLOverflowDelMessaggio;
    [Test]
    procedure DovrebbeSollevareSeLaScritturaEsceDalBuffer;
    [Test]
    procedure DovrebbeRifiutareIBitSenzaCoder;
    [Test]
    procedure DovrebbeCopiareUnMessaggio;
    [Test]
    procedure DovrebbeRifiutareLaCopiaInUnBufferPiuPiccolo;
    [Test]
    procedure DovrebbeTroncareLeStringheAlPrimoNul;
    [Test]
    procedure DovrebbeLeggereMenoUnoOltreLaFine;
    [Test]
    procedure DovrebbeTrattareINanComeIlC;
    [Test]
    procedure DovrebbeConvertireGliAngoli;
    [Test]
    procedure DovrebbeLeggereZeroOltreIlBufferNelMessaggioOutOfBand;
    [Test]
    procedure DovrebbeContareINodiDellAlberoAdattivo;
    [Test]
    procedure DovrebbeRifiutareUnSimboloAssenteNellAlbero;
    [Test]
    procedure DovrebbeLeggereZeroOltreIlBufferNeiBit;
    [Test]
    procedure DovrebbeRifiutareLaCompressioneInUnBufferPiuPiccolo;
    [Test]
    procedure DovrebbeSollevareSeIlCampoDeiCambiamentiEFuoriTabella;
    [Test]
    procedure DovrebbeUsareLoStatoZeroSeMancaLaBase;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiEntitaFuoriLimite;
    [Test]
    procedure DovrebbeRiportareIPacchettiSeRichiesto;
    [Test]
    procedure DovrebbeSollevareSeIlMessaggioDiRiassemblaggioEPiccolo;
    [Test]
    procedure DovrebbeRifiutareUnMessaggioTroppoLungo;
    [Test]
    procedure DovrebbeTrasferireUnMessaggioDalClientAlServer;
    [Test]
    procedure DovrebbeCreareGliOggettiDallaFactory;
  end;

implementation

{ TTestQ3Net }

procedure TTestQ3Net.SetupFixture;
begin
  FCoder := TQ3NetFactory.CreateMessageHuffman;
end;

procedure TTestQ3Net.TearDownFixture;
begin
  FCoder := nil;
end;

procedure TTestQ3Net.Setup;
begin
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FTransport := TFakeQ3Transport.Create;
  FTransportIntf := FTransport;
end;

procedure TTestQ3Net.TearDown;
begin
  FTransportIntf := nil;
  FLogIntf := nil;
end;

function TTestQ3Net.NewMessage(ALength, ABufferLength: Integer): TQ3Message;
var
  LBuffer: TBytes;
begin
  if ABufferLength < 0 then
    ABufferLength := ALength;
  SetLength(LBuffer, ABufferLength);
  if ABufferLength > 0 then
    FillChar(LBuffer[0], ABufferLength, 0);
  Result := TQ3NetFactory.CreateMessage(FCoder, FLogIntf);
  Result.Init(LBuffer, ALength);
end;

function TTestQ3Net.NewChannel(ASource: TQ3NetSource): TQ3Netchan;
begin
  Result := TQ3NetFactory.CreateNetchan(FTransportIntf, FLogIntf);
  Result.Setup(ASource, Address, 77);
end;

function TTestQ3Net.Address: TQ3NetAddress;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.AddressType := Ord(natIp);
  Result.Port := 27960;
end;

procedure TTestQ3Net.DovrebbeAvereLeDimensioniDelC;
begin
  Assert.AreEqual<Integer>(20, SizeOf(TQ3NetAddress));
  Assert.AreEqual<Integer>(24, SizeOf(TQ3UserCmd));
  Assert.AreEqual<Integer>(36, SizeOf(TQ3Trajectory));
  Assert.AreEqual<Integer>(208, SizeOf(TQ3EntityState));
  Assert.AreEqual<Integer>(468, SizeOf(TQ3PlayerState));
end;

procedure TTestQ3Net.DovrebbeAvereLeTabelleDeiCampi;
var
  LEntity, LPlayer: IQ3NetFieldTable;
begin
  LEntity := TQ3NetFactory.CreateEntityStateTable;
  LPlayer := TQ3NetFactory.CreatePlayerStateTable;
  Assert.AreEqual<Integer>(51, LEntity.Count);
  Assert.AreEqual<Integer>(48, LPlayer.Count);
  Assert.AreEqual('pos.trTime', LEntity[0].Name);
  Assert.AreEqual<Integer>(16, LEntity[0].Offset);
  Assert.AreEqual<Integer>(0, LPlayer[0].Offset);
  Assert.AreEqual<Integer>(-16, LPlayer[8].Bits);
end;

procedure TTestQ3Net.DovrebbeRifiutareUnaLunghezzaOltreIlBuffer;
var
  LMessage: TQ3Message;
begin
  LMessage := TQ3NetFactory.CreateMessage(FCoder);
  try
    Assert.WillRaise(
      procedure
      begin
        LMessage.Init(TBytes.Create(1, 2), 3);
      end, EQ3MessageException);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRifiutareUnNumeroDiBitSbagliato;
var
  LMessage: TQ3Message;
begin
  LMessage := NewMessage(64);
  try
    Assert.WillRaise(
      procedure
      begin
        LMessage.WriteBits(1, 33);
      end, EQ3MessageException);
    Assert.WillRaise(
      procedure
      begin
        LMessage.WriteBits(1, 0);
      end, EQ3MessageException);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeSegnalareLOverflowDelMessaggio;
var
  LMessage: TQ3Message;
begin
  LMessage := NewMessage(4, 64);
  try
    LMessage.WriteByte(1);
    Assert.IsFalse(LMessage.Overflowed);
    // fewer than 4 bytes left: nothing is written
    LMessage.WriteByte(1);
    Assert.IsTrue(LMessage.Overflowed);
    Assert.AreEqual(1, LMessage.CurSize);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeSollevareSeLaScritturaEsceDalBuffer;
var
  LMessage: TQ3Message;
begin
  // the message thinks it has room (maxsize 100) but the buffer is 12 bytes: the original writes outside it
  LMessage := NewMessage(12, 12);
  try
    LMessage.MaxSize := 100;
    Assert.WillRaise(
      procedure
      var
        LIndex: Integer;
      begin
        for LIndex := 0 to 40 do
          LMessage.WriteLong(Integer($F5F5F5F5));
      end, EQ3MessageOverflowException);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRifiutareIBitSenzaCoder;
var
  LMessage: TQ3Message;
begin
  LMessage := TQ3Message.Create(nil);
  try
    LMessage.Init(TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0), 8);
    Assert.WillRaise(
      procedure
      begin
        LMessage.WriteByte(1);
      end, EQ3MessageException);
    Assert.WillRaise(
      procedure
      begin
        LMessage.ReadByte;
      end, EQ3MessageException);
    LMessage.Oob := True;
    LMessage.WriteByte(1);
    Assert.AreEqual<Integer>(1, LMessage.CurSize);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeCopiareUnMessaggio;
var
  LSource, LCopy: TQ3Message;
begin
  LSource := NewMessage(64);
  LCopy := TQ3Message.Create(nil);
  try
    LSource.WriteString('copy');
    LSource.WriteShort(1234);
    LCopy.CopyFrom(LSource, TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), 16);
    Assert.AreEqual(LSource.CurSize, LCopy.CurSize);
    Assert.AreEqual(LSource.Bit, LCopy.Bit);
    LCopy.BeginReading;
    Assert.AreEqual('copy', string(LCopy.ReadString));
    Assert.AreEqual(1234, LCopy.ReadShort);
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRifiutareLaCopiaInUnBufferPiuPiccolo;
var
  LSource, LCopy: TQ3Message;
begin
  LSource := NewMessage(64);
  LCopy := TQ3Message.Create(nil);
  try
    LSource.WriteString('a long enough text');
    Assert.WillRaise(
      procedure
      begin
        LCopy.CopyFrom(LSource, TBytes.Create(0, 0), 2);
      end, EQ3MessageException);
    Assert.WillRaise(
      procedure
      begin
        LCopy.CopyFrom(LSource, TBytes.Create(0, 0), 64);
      end, EQ3MessageOverflowException);
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeTroncareLeStringheAlPrimoNul;
var
  LMessage: TQ3Message;
begin
  LMessage := NewMessage(64);
  try
    LMessage.WriteString('ab' + #0 + 'cd');
    LMessage.WriteString('x');
    LMessage.BeginReading;
    Assert.AreEqual('ab', string(LMessage.ReadString));
    Assert.AreEqual('x', string(LMessage.ReadString));
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeLeggereMenoUnoOltreLaFine;
var
  LMessage: TQ3Message;
begin
  LMessage := NewMessage(16);
  try
    LMessage.WriteByte(5);
    LMessage.BeginReading;
    Assert.AreEqual(5, LMessage.ReadByte);
    Assert.AreEqual(-1, LMessage.ReadByte);
    Assert.AreEqual(-1, LMessage.ReadChar);
    Assert.AreEqual(-1, LMessage.ReadShort);
    Assert.AreEqual(-1, LMessage.ReadLong);
    Assert.AreEqual<Single>(-1, LMessage.ReadFloat);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeTrattareINanComeIlC;
begin
  Assert.AreEqual(Low(Integer), TQ3Message.TruncToInteger(TQ3Message.BitsToFloat($7FC00000)));
  Assert.AreEqual(Low(Integer), TQ3Message.TruncToInteger(1e20));
  Assert.AreEqual(-3, TQ3Message.TruncToInteger(-3.9));
  Assert.IsFalse(TQ3Message.FloatsEqual(TQ3Message.BitsToFloat($7FC00000), TQ3Message.BitsToFloat($7FC00000)));
  Assert.IsTrue(TQ3Message.FloatsEqual(0.0, TQ3Message.BitsToFloat(Integer($80000000))));
end;

procedure TTestQ3Net.DovrebbeConvertireGliAngoli;
begin
  Assert.AreEqual(16384, TQ3Message.AngleToShort(90.0));
  Assert.AreEqual(49152, TQ3Message.AngleToShort(-90.0));
  Assert.AreEqual<Single>(90.0, TQ3Message.ShortToAngle(16384));
end;

procedure TTestQ3Net.DovrebbeLeggereZeroOltreIlBufferNelMessaggioOutOfBand;
var
  LMessage: TQ3Message;
begin
  LMessage := NewMessage(4);
  try
    LMessage.BeginReadingOOB;
    LMessage.CurSize := 4;
    Assert.AreEqual(0, LMessage.ReadLong);
    Assert.AreEqual(-1, LMessage.ReadByte, 'oltre la fine del messaggio');
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeContareINodiDellAlberoAdattivo;
var
  LTree, LReceiver: TQ3AdaptiveHuffman;
  LData: TBytes;
  LBit, LIndex, LSymbol, LBitIndex: Integer;
begin
  LTree := TQ3AdaptiveHuffman.Create;
  LReceiver := TQ3AdaptiveHuffman.Create;
  try
    Assert.AreEqual(1, LTree.UsedNodes);
    SetLength(LData, 4096);
    LBit := 0;
    for LIndex := 0 to 255 do
    begin
      LTree.Transmit(LIndex, LData, LBit);
      LTree.AddRef(LIndex);
    end;
    Assert.AreEqual(513, LTree.UsedNodes);
    // the receiver learns the same bytes: a NYT and the 8 bits of the byte, then the code
    LBit := 0;
    for LIndex := 0 to 255 do
    begin
      LSymbol := LReceiver.Receive(LData, LBit);
      Assert.AreEqual(Q3_HUFFMAN_NYT, LSymbol);
      LSymbol := 0;
      for LBitIndex := 0 to 7 do
        LSymbol := (LSymbol shl 1) + TQ3AdaptiveHuffman.GetBit(LData, LBit);
      Assert.AreEqual(LIndex, LSymbol);
      LReceiver.AddRef(LSymbol);
    end;
    Assert.AreEqual(513, LReceiver.UsedNodes);
  finally
    LReceiver.Free;
    LTree.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRifiutareUnSimboloAssenteNellAlbero;
var
  LTree: TQ3AdaptiveHuffman;
  LData: TBytes;
  LBit: Integer;
begin
  LTree := TQ3AdaptiveHuffman.Create;
  try
    SetLength(LData, 16);
    LBit := 0;
    Assert.WillRaise(
      procedure
      begin
        LTree.OffsetTransmit(65, LData, LBit);
      end, EQ3MessageException);
    Assert.WillRaise(
      procedure
      begin
        LTree.OffsetTransmit(300, LData, LBit);
      end, EQ3MessageException);
  finally
    LTree.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeLeggereZeroOltreIlBufferNeiBit;
var
  LData: TBytes;
  LBit: Integer;
begin
  SetLength(LData, 1);
  LBit := 100;
  Assert.AreEqual(0, TQ3AdaptiveHuffman.GetBit(LData, LBit));
  Assert.AreEqual(101, LBit);
  LBit := 8;
  Assert.WillRaise(
    procedure
    begin
      TQ3AdaptiveHuffman.PutBit(1, LData, LBit);
    end, EQ3MessageOverflowException);
end;

procedure TTestQ3Net.DovrebbeRifiutareLaCompressioneInUnBufferPiuPiccolo;
var
  LMessage: TQ3Message;
begin
  LMessage := NewMessage(64);
  try
    // 60 different bytes compress to more than the 64 bytes of the buffer
    LMessage.CurSize := 60;
    Assert.WillRaise(
      procedure
      var
        LIndex: Integer;
      begin
        for LIndex := 0 to 59 do
          LMessage.Data[LIndex] := Byte(LIndex * 37 + 11);
        TQ3HuffmanCompressor.Compress(LMessage, 0);
      end, EQ3MessageOverflowException);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeSollevareSeIlCampoDeiCambiamentiEFuoriTabella;
var
  LMessage: TQ3Message;
  LEntityCodec: TQ3EntityStateCodec;
  LPlayerCodec: TQ3PlayerStateCodec;
  LFrom, LTo: TQ3EntityState;
  LPlayerFrom, LPlayerTo: TQ3PlayerState;
begin
  LEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  LPlayerCodec := TQ3NetFactory.CreatePlayerStateCodec;
  LMessage := NewMessage(64);
  try
    FillChar(LFrom, SizeOf(LFrom), 0);
    FillChar(LPlayerFrom, SizeOf(LPlayerFrom), 0);
    // an entity delta that claims 200 fields
    LMessage.WriteBits(0, 1);
    LMessage.WriteBits(1, 1);
    LMessage.WriteByte(200);
    LMessage.BeginReading;
    Assert.WillRaise(
      procedure
      begin
        LEntityCodec.ReadDelta(LMessage, @LFrom, @LTo, 3);
      end, EQ3MessageException);
    LMessage.Init(LMessage.Data, 64);
    LMessage.WriteByte(200);
    LMessage.BeginReading;
    Assert.WillRaise(
      procedure
      begin
        LPlayerCodec.ReadDelta(LMessage, @LPlayerFrom, @LPlayerTo);
      end, EQ3MessageException);
  finally
    LMessage.Free;
    LPlayerCodec.Free;
    LEntityCodec.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeUsareLoStatoZeroSeMancaLaBase;
var
  LMessage: TQ3Message;
  LEntityCodec: TQ3EntityStateCodec;
  LTo, LDecoded, LZero: TQ3EntityState;
begin
  LEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  LMessage := NewMessage(256);
  try
    FillChar(LTo, SizeOf(LTo), 0);
    FillChar(LZero, SizeOf(LZero), 0);
    LTo.Number := 9;
    LTo.EType := 3;
    LTo.Origin[0] := 12.0;
    LEntityCodec.WriteDelta(LMessage, nil, @LTo, False);
    LMessage.BeginReading;
    Assert.AreEqual(9, LMessage.ReadBits(Q3_GENTITYNUM_BITS));
    LEntityCodec.ReadDelta(LMessage, @LZero, @LDecoded, 9);
    Assert.AreEqual(3, LDecoded.EType);
    Assert.AreEqual<Single>(12.0, LDecoded.Origin[0]);
  finally
    LMessage.Free;
    LEntityCodec.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRifiutareUnNumeroDiEntitaFuoriLimite;
var
  LMessage: TQ3Message;
  LEntityCodec: TQ3EntityStateCodec;
  LFrom, LTo: TQ3EntityState;
begin
  LEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  LMessage := NewMessage(64);
  try
    FillChar(LFrom, SizeOf(LFrom), 0);
    LTo := LFrom;
    LTo.Number := -1;
    Assert.WillRaise(
      procedure
      begin
        LEntityCodec.WriteDelta(LMessage, @LFrom, @LTo, True);
      end, EQ3MessageException);
    Assert.WillRaise(
      procedure
      begin
        LEntityCodec.ReadDelta(LMessage, @LFrom, @LTo, Q3_MAX_GENTITIES);
      end, EQ3MessageException);
  finally
    LMessage.Free;
    LEntityCodec.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRiportareIPacchettiSeRichiesto;
var
  LClient, LServer: TQ3Netchan;
  LMessage: TQ3Message;
  LBuffer: TBytes;
  LCount: Integer;
begin
  LClient := NewChannel(nsClient);
  LServer := NewChannel(nsServer);
  try
    LClient.ShowPackets := True;
    LServer.ShowPackets := True;
    LServer.ShowDrop := True;
    SetLength(LBuffer, 2000);
    LClient.Transmit(TBytes.Create(1, 2, 3), 3);
    LClient.Transmit(BytesOf(StringOfChar('x', 2000)), 2000);
    while LClient.UnsentFragments do
      LClient.TransmitNextFragment;
    Assert.IsTrue(FLog.Infos.Count >= 3, 'invii riportati');
    LCount := FLog.Infos.Count;
    SetLength(LBuffer, Q3_MAX_MSGLEN + 16);
    LMessage := NewMessage(Q3_MAX_MSGLEN, Q3_MAX_MSGLEN + 16);
    try
      Move(FTransport.Packets[0].Data[0], LMessage.Data[0], Length(FTransport.Packets[0].Data));
      LMessage.CurSize := Length(FTransport.Packets[0].Data);
      Assert.IsTrue(LServer.Process(LMessage));
      // the same packet again is out of order
      Move(FTransport.Packets[0].Data[0], LMessage.Data[0], Length(FTransport.Packets[0].Data));
      LMessage.CurSize := Length(FTransport.Packets[0].Data);
      Assert.IsFalse(LServer.Process(LMessage));
      Assert.IsTrue(FLog.Infos.Count > LCount + 1, 'ricezioni e scarti riportati');
    finally
      LMessage.Free;
    end;
  finally
    LServer.Free;
    LClient.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeSollevareSeIlMessaggioDiRiassemblaggioEPiccolo;
var
  LClient, LServer: TQ3Netchan;
  LMessage: TQ3Message;
  LIndex: Integer;
begin
  LClient := NewChannel(nsClient);
  LServer := NewChannel(nsServer);
  try
    LClient.Transmit(BytesOf(StringOfChar('y', 1500)), 1500);
    while LClient.UnsentFragments do
      LClient.TransmitNextFragment;
    // the message holds only the first datagram: the whole message needs more
    LMessage := NewMessage(1400, 1400);
    try
      LMessage.MaxSize := Q3_MAX_MSGLEN;
      for LIndex := 0 to FTransport.Packets.Count - 1 do
      begin
        Move(FTransport.Packets[LIndex].Data[0], LMessage.Data[0], Length(FTransport.Packets[LIndex].Data));
        LMessage.CurSize := Length(FTransport.Packets[LIndex].Data);
        if LIndex = FTransport.Packets.Count - 1 then
          Assert.WillRaise(
            procedure
            begin
              LServer.Process(LMessage);
            end, EQ3MessageOverflowException)
        else
          LServer.Process(LMessage);
      end;
    finally
      LMessage.Free;
    end;
  finally
    LServer.Free;
    LClient.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeRifiutareUnMessaggioTroppoLungo;
var
  LClient: TQ3Netchan;
begin
  LClient := NewChannel(nsClient);
  try
    Assert.WillRaise(
      procedure
      begin
        LClient.Transmit(nil, Q3_MAX_MSGLEN + 1);
      end, EQ3NetchanException);
  finally
    LClient.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeTrasferireUnMessaggioDalClientAlServer;
var
  LClient, LServer: TQ3Netchan;
  LPayload: TBytes;
  LReceived: TQ3Message;
  LIndex: Integer;
begin
  LClient := NewChannel(nsClient);
  LServer := NewChannel(nsServer);
  try
    SetLength(LPayload, 5000);
    for LIndex := 0 to 4999 do
      LPayload[LIndex] := Byte(LIndex * 13);
    LClient.Transmit(LPayload, 5000);
    while LClient.UnsentFragments do
      LClient.TransmitNextFragment;
    Assert.AreEqual<Integer>(4, FTransport.Packets.Count, '3 pieni e uno corto');
    LReceived := NewMessage(Q3_MAX_MSGLEN, Q3_MAX_MSGLEN + 16);
    try
      for LIndex := 0 to 3 do
      begin
        FillChar(LReceived.Data[0], Length(LReceived.Data), 0);
        Move(FTransport.Packets[LIndex].Data[0], LReceived.Data[0], Length(FTransport.Packets[LIndex].Data));
        LReceived.CurSize := Length(FTransport.Packets[LIndex].Data);
        Assert.AreEqual(LIndex = 3, LServer.Process(LReceived));
      end;
      Assert.AreEqual<Integer>(5004, LReceived.CurSize);
      Assert.IsTrue(CompareMem(@LReceived.Data[4], @LPayload[0], 5000));
      Assert.AreEqual<Integer>(1, LServer.IncomingSequence);
      Assert.AreEqual<Integer>(0, LServer.Dropped);
    finally
      LReceived.Free;
    end;
  finally
    LServer.Free;
    LClient.Free;
  end;
end;

procedure TTestQ3Net.DovrebbeCreareGliOggettiDallaFactory;
var
  LCodec: TQ3EntityStateCodec;
  LPlayer: TQ3PlayerStateCodec;
  LChannel: TQ3Netchan;
begin
  LCodec := TQ3NetFactory.CreateEntityStateCodec;
  LPlayer := TQ3NetFactory.CreatePlayerStateCodec;
  LChannel := TQ3NetFactory.CreateNetchan(FTransportIntf);
  try
    Assert.IsNotNull(LCodec);
    Assert.IsNotNull(LPlayer);
    Assert.IsNotNull(LChannel);
    Assert.IsNotNull(FCoder);
  finally
    LChannel.Free;
    LPlayer.Free;
    LCodec.Free;
  end;
end;

end.
