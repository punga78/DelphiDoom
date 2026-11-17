{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the packets between a      }
{  client and a server against the real code of Quake III (cryptgen.c of        }
{  Tools\Verifica\254): Com_HashKey, CL_WritePacket with CL_Netchan_Encode,      }
{  SV_Netchan_Decode, SV_Netchan_Encode and CL_Netchan_Decode. The golden is     }
{  Tests\Data\Q3Host\netcrypt.golden.txt. No bit of difference is allowed        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.NetCrypt;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3NetCrypt')]
  TTestQ3NetCrypt = class
  public
    [Test]
    procedure ComHashKeyDovrebbeDareGliStessiNumeriDelC;
    [Test]
    procedure IlPacchettoDelClientDovrebbeAvereGliStessiByteDelC;
    [Test]
    procedure IlServerDovrebbeLeggereIlPacchettoDelClientComeIlC;
    [Test]
    procedure IlMessaggioDelServerDovrebbeAvereGliStessiByteDelCEIlClientLeggerlo;
    [Test]
    procedure CodificareEDecodificareDovrebbeRidareIlMessaggio;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Console.Q3.CommandArguments,
  DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.Factory,
  DelphiDoom.Net.Q3.Netchan, DelphiDoom.Net.Q3.HashKey, DelphiDoom.Net.Q3.PacketCrypt,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientPacketWriter,
  DelphiDoom.Tests.Shared.Files;

type
  /// <summary>NET_SendPacket: the datagrams are kept</summary>
  TCaptureTransport = class(TInterfacedObject, IQ3NetTransport)
  public
    Packets: TList<TBytes>;
    constructor Create;
    destructor Destroy; override;
    procedure SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; const AData: TBytes);
  end;

constructor TCaptureTransport.Create;
begin
  inherited Create;
  Packets := TList<TBytes>.Create;
end;

destructor TCaptureTransport.Destroy;
begin
  Packets.Free;
  inherited Destroy;
end;

procedure TCaptureTransport.SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; const AData: TBytes);
begin
  Packets.Add(Copy(AData));
end;

function HexToBytes(const AText: string): TBytes;
var
  LIndex: Integer;
begin
  if AText = '-' then
    Exit(nil);
  SetLength(Result, Length(AText) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := StrToInt('$' + Copy(AText, LIndex * 2 + 1, 2));
end;

function BytesToHex(const AData: TBytes; AStart, ACount: Integer): string;
var
  LIndex: Integer;
begin
  if ACount <= 0 then
    Exit('-');
  Result := '';
  for LIndex := AStart to AStart + ACount - 1 do
    Result := Result + LowerCase(IntToHex(AData[LIndex], 2));
end;

// text( n, variant ) of cryptgen.c
function CommandText(ANumber, AVariant: Integer): AnsiString;
begin
  Result := AnsiString(Format('cs %d v%d', [ANumber, AVariant]));
  if ANumber mod 3 = 0 then
    Result := Result + '%x';
  if ANumber mod 5 = 0 then
    Result := Result + #$E9 + 'z';
end;

function Lines(const AKind: string): TStringList;
var
  LAll: TStringList;
  LLine: string;
begin
  Result := TStringList.Create;
  LAll := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'netcrypt.golden.txt'));
  try
    for LLine in LAll do
      if LLine.StartsWith(AKind + ' ') then
        Result.Add(LLine);
  finally
    LAll.Free;
  end;
end;

function Int(const AText: string): Integer;
begin
  Result := Integer(StrToInt64(AText));
end;

procedure TTestQ3NetCrypt.ComHashKeyDovrebbeDareGliStessiNumeriDelC;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LBytes: TBytes;
  LText: AnsiString;
begin
  LLines := Lines('H');
  try
    Assert.AreEqual(21, LLines.Count);
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      LBytes := HexToBytes(LParts[1]);
      SetLength(LText, Length(LBytes));
      if Length(LBytes) > 0 then
        Move(LBytes[0], LText[1], Length(LBytes));
      Assert.AreEqual(Int(LParts[3]), TQ3HashKey.Compute(LText, Int(LParts[2])), LLine);
    end;
  finally
    LLines.Free;
  end;
end;

// what the client sends, as the C writes it
procedure TTestQ3NetCrypt.IlPacchettoDelClientDovrebbeAvereGliStessiByteDelC;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LState: TQ3ClientState;
  LWriter: TQ3ClientPacketWriter;
  LCoder: IQ3HuffmanCoder;
  LInput: TQ3ClientPacketInput;
  LTransport: TCaptureTransport;
  LTransportIntf: IQ3NetTransport;
  LNetchan: TQ3Netchan;
  LMessage: TQ3Message;
  LPayload, LBuffer, LCommand: TBytes;
  LIndex, LCount, LNumber, LOutSeq, LQPort, LChallenge: Integer;
  LCommands: TArray<string>;
  LUser: TQ3HostUserCmd;
  LAddress: TQ3NetAddress;
begin
  LLines := Lines('CW');
  LCoder := TQ3NetFactory.CreateMessageHuffman;
  try
    Assert.AreEqual(6, LLines.Count);
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      LState := TQ3ClientState.Create(TQ3CommandArguments.Create);
      LWriter := TQ3ClientPacketWriter.Create(LState, LCoder);
      LTransport := TCaptureTransport.Create;
      LTransportIntf := LTransport;
      LNetchan := TQ3NetFactory.CreateNetchan(LTransportIntf);
      try
        LNumber := Int(LParts[1]);
        LChallenge := Int(LParts[2]);
        LOutSeq := Int(LParts[9]);
        LQPort := Int(LParts[15]);
        LCount := Int(LParts[16]);
        // the commands of the server and the commands of the client
        for LIndex := 1 to 64 do
          LState.StoreServerCommand(LIndex, CommandText(LIndex, 1));
        LState.SetServerCommandSequence(Int(LParts[5]));
        for LIndex := 1 to Int(LParts[7]) do
          LState.AddReliableCommand(CommandText(LIndex, 2));
        LState.AcknowledgeReliableCommands(Int(LParts[6]));
        // the user commands: the ones of the packet are the last ones
        for LIndex := 1 to Int(LParts[10]) - LCount do
          LState.AddUserCommand(Default(TQ3HostUserCmd));
        if LCount > 0 then
        begin
          LCommands := LParts[17].Split([',']);
          for LIndex := 0 to LCount - 1 do
          begin
            LCommand := HexToBytes(LCommands[LIndex]);
            Move(LCommand[0], LUser[0], SizeOf(LUser));
            LState.AddUserCommand(LUser);
          end;
        end;
        LWriter.SetSentCommandNumber(LOutSeq - 1 - Int(LParts[11]), Int(LParts[10]) - LCount);
        LInput := Default(TQ3ClientPacketInput);
        LInput.ServerId := Int(LParts[3]);
        LInput.ServerMessageSequence := Int(LParts[4]);
        LInput.ChecksumFeed := Int(LParts[8]);
        LInput.OutgoingSequence := LOutSeq;
        LInput.PacketDup := Int(LParts[11]);
        LInput.NoDelta := Int(LParts[12]) <> 0;
        LInput.SnapshotValid := Int(LParts[13]) <> 0;
        LInput.SnapshotMessageNum := Int(LParts[14]);
        LPayload := LWriter.Write(LInput);
        // CL_Netchan_Transmit
        SetLength(LBuffer, Length(LPayload) + 4);
        Move(LPayload[0], LBuffer[0], Length(LPayload));
        LMessage := TQ3NetFactory.CreateMessage(LCoder);
        try
          LMessage.Init(LBuffer, Length(LBuffer));
          LMessage.CurSize := Length(LPayload);
          TQ3PacketCrypt.ClientEncode(LMessage, LChallenge,
            function(ASequence: Integer): AnsiString
            begin
              Result := LState.ServerCommandText(ASequence);
            end);
          LAddress := Default(TQ3NetAddress);
          LNetchan.Setup(nsClient, LAddress, LQPort);
          LNetchan.OutgoingSequence := LOutSeq;
          LNetchan.Transmit(LMessage.Data, LMessage.CurSize);
        finally
          LMessage.Free;
        end;
        Assert.AreEqual(1, LTransport.Packets.Count);
        Assert.AreEqual(LParts[18], BytesToHex(LTransport.Packets[0], 0, Length(LTransport.Packets[0])),
          'CW ' + IntToStr(LNumber));
      finally
        LNetchan.Free;
        LWriter.Free;
        LState.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

// the server reads what the C client wrote
procedure TTestQ3NetCrypt.IlServerDovrebbeLeggereIlPacchettoDelClientComeIlC;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LCoder: IQ3HuffmanCoder;
  LNetchan: TQ3Netchan;
  LTransport: IQ3NetTransport;
  LMessage: TQ3Message;
  LData, LBuffer: TBytes;
  LAddress: TQ3NetAddress;
begin
  LLines := Lines('CW');
  LCoder := TQ3NetFactory.CreateMessageHuffman;
  LTransport := TCaptureTransport.Create;
  try
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      LData := HexToBytes(LParts[18]);
      SetLength(LBuffer, Q3_MAX_MSGLEN + 4);
      Move(LData[0], LBuffer[0], Length(LData));
      LNetchan := TQ3NetFactory.CreateNetchan(LTransport);
      LMessage := TQ3NetFactory.CreateMessage(LCoder);
      try
        LAddress := Default(TQ3NetAddress);
        LNetchan.Setup(nsServer, LAddress, Int(LParts[15]));
        LNetchan.IncomingSequence := Int(LParts[9]) - 1;
        LMessage.Init(LBuffer, Length(LBuffer));
        LMessage.CurSize := Length(LData);
        Assert.IsTrue(LNetchan.Process(LMessage), 'process');
        TQ3PacketCrypt.ServerDecode(LMessage, Int(LParts[2]),
          function(ASequence: Integer): AnsiString
          begin
            Result := CommandText(ASequence, 1);
          end);
        Assert.AreEqual(LParts[19], BytesToHex(LMessage.Data, LMessage.ReadCount,
          LMessage.CurSize - LMessage.ReadCount), 'CW ' + LParts[1]);
      finally
        LMessage.Free;
        LNetchan.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3NetCrypt.IlMessaggioDelServerDovrebbeAvereGliStessiByteDelCEIlClientLeggerlo;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LCoder: IQ3HuffmanCoder;
  LServerTransport, LClientTransport: TCaptureTransport;
  LServerIntf, LClientIntf: IQ3NetTransport;
  LNetchan: TQ3Netchan;
  LMessage: TQ3Message;
  LPayload, LBuffer, LData: TBytes;
  LAddress: TQ3NetAddress;
  LOutSeq, LChallenge, LLast: Integer;
begin
  LLines := Lines('SE');
  LCoder := TQ3NetFactory.CreateMessageHuffman;
  try
    Assert.AreEqual(6, LLines.Count);
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      LChallenge := Int(LParts[2]);
      LOutSeq := Int(LParts[3]);
      LLast := Int(LParts[4]);
      LPayload := HexToBytes(LParts[5]);
      LServerTransport := TCaptureTransport.Create;
      LServerIntf := LServerTransport;
      LNetchan := TQ3NetFactory.CreateNetchan(LServerIntf);
      SetLength(LBuffer, Length(LPayload) + 4);
      Move(LPayload[0], LBuffer[0], Length(LPayload));
      LMessage := TQ3NetFactory.CreateMessage(LCoder);
      try
        LMessage.Init(LBuffer, Length(LBuffer));
        LMessage.CurSize := Length(LPayload);
        // SV_Netchan_Encode and Netchan_Transmit
        TQ3PacketCrypt.ServerEncode(LMessage, LChallenge, LOutSeq, CommandText(LLast, 2));
        LAddress := Default(TQ3NetAddress);
        LNetchan.Setup(nsServer, LAddress, 1234);
        LNetchan.OutgoingSequence := LOutSeq;
        LNetchan.Transmit(LMessage.Data, LMessage.CurSize);
      finally
        LMessage.Free;
        LNetchan.Free;
      end;
      Assert.IsTrue(LServerTransport.Packets.Count >= 1);
      Assert.AreEqual(LParts[6], BytesToHex(LServerTransport.Packets[0], 0, Length(LServerTransport.Packets[0])),
        'SE ' + LParts[1]);
      // the client reads the datagram that the C wrote
      if LParts[7] = 'rejected' then
        Continue;
      LData := HexToBytes(LParts[6]);
      SetLength(LBuffer, Q3_MAX_MSGLEN + 4);
      Move(LData[0], LBuffer[0], Length(LData));
      LClientTransport := TCaptureTransport.Create;
      LClientIntf := LClientTransport;
      LNetchan := TQ3NetFactory.CreateNetchan(LClientIntf);
      LMessage := TQ3NetFactory.CreateMessage(LCoder);
      try
        LAddress := Default(TQ3NetAddress);
        LNetchan.Setup(nsClient, LAddress, 1234);
        LMessage.Init(LBuffer, Length(LBuffer));
        LMessage.CurSize := Length(LData);
        Assert.IsTrue(LNetchan.Process(LMessage), 'client process');
        TQ3PacketCrypt.ClientDecode(LMessage, LChallenge,
          function(ASequence: Integer): AnsiString
          begin
            Result := CommandText(ASequence, 2);
          end);
        Assert.AreEqual(LParts[7], BytesToHex(LMessage.Data, LMessage.ReadCount, LMessage.CurSize - LMessage.ReadCount),
          'SD ' + LParts[1]);
      finally
        LMessage.Free;
        LNetchan.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3NetCrypt.CodificareEDecodificareDovrebbeRidareIlMessaggio;
var
  LCoder: IQ3HuffmanCoder;
  LMessage: TQ3Message;
  LBuffer, LOriginal: TBytes;
  LIndex: Integer;
begin
  LCoder := TQ3NetFactory.CreateMessageHuffman;
  SetLength(LOriginal, 60);
  for LIndex := 0 to High(LOriginal) do
    LOriginal[LIndex] := Byte(LIndex * 7 + 1);
  SetLength(LBuffer, 64);
  Move(LOriginal[0], LBuffer[0], 60);
  LMessage := TQ3NetFactory.CreateMessage(LCoder);
  try
    LMessage.Init(LBuffer, 64);
    LMessage.CurSize := 60;
    // a message shorter than the start of the encoding is left alone
    TQ3PacketCrypt.ServerEncode(LMessage, 99, 5, 'say hello');
    Assert.IsTrue(not CompareMem(@LBuffer[4], @LOriginal[4], 56), 'cambiato');
    Assert.IsTrue(CompareMem(@LBuffer[0], @LOriginal[0], 4), 'i primi quattro byte restano');
    // xor again with the same key gives the message back
    TQ3PacketCrypt.ServerEncode(LMessage, 99, 5, 'say hello');
    Assert.IsTrue(CompareMem(@LBuffer[0], @LOriginal[0], 60));
    LMessage.CurSize := 3;
    TQ3PacketCrypt.ServerEncode(LMessage, 99, 5, 'say hello');
    Assert.IsTrue(CompareMem(@LBuffer[0], @LOriginal[0], 60), 'messaggio troppo corto');
  finally
    LMessage.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3NetCrypt);

end.
