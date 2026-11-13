{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the server message parser of Quake III (DUnitX)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Q3.ServerMessageParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.MessageHuffman,
  DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec, DelphiDoom.Net.Q3.NetFieldTable,
  DelphiDoom.Net.Q3.ServerMessage.Intf, DelphiDoom.Net.Q3.ServerMessageParser, DelphiDoom.Net.Q3.DemoReader,
  DelphiDoom.Tests.Net.Q3Fakes;

type
  /// <summary>
  ///   The parser of server messages: unit tests with messages written by <c>TQ3Message</c> and parity with the real
  ///   <c>cl_parse.c</c> on a whole demo (Tests\Data\Net\q3demo-golden.txt, Tools\Verifica\121\build-demo.sh): the
  ///   messages (bytes in hex) are read through <c>TQ3DemoReader</c> and the client state after each one (command,
  ///   gamestate, baselines, snapshot with its entities) is compared with the one of the C code
  /// </summary>
  [TestFixture]
  [Category('net')]
  TTestQ3ServerMessageParser = class
  strict private
    FCoder: IQ3HuffmanCoder;
    FEntityCodec: TQ3EntityStateCodec;
    FPlayerCodec: TQ3PlayerStateCodec;
    FSinkObject: TFakeQ3ServerSink;
    FSink: IQ3ServerMessageSink;
    FLogObject: TFakeQ3Log;
    FLog: IInterface;
    FParser: TQ3ServerMessageParser;
    function NewWriter: TQ3Message;
    procedure Parse(AWriter: TQ3Message; ASequence: Integer = 1);
    class function HashUpdate(AHash: Cardinal; const AData; ALength: Integer): Cardinal; static;
    class function HexToBytes(const AText: string): TBytes; static;
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
    procedure DovrebbeRifiutareArgomentiNil;
    [Test]
    procedure DovrebbeLeggereUnMessaggioConSoloNopEFine;
    [Test]
    procedure DovrebbeRifiutareUnComandoSconosciuto;
    [Test]
    procedure DovrebbeIgnorareUnComandoGiaVisto;
    [Test]
    procedure DovrebbeLeggereUnGamestate;
    [Test]
    procedure DovrebbeRifiutareUnaConfigstringFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnComandoSconosciutoNelGamestate;
    [Test]
    procedure DovrebbeRifiutareTroppiCaratteriNelGamestate;
    [Test]
    procedure DovrebbeLeggereUnDownload;
    [Test]
    procedure DovrebbeRifiutareUnDownloadRifiutatoDalServer;
    [Test]
    procedure DovrebbeRifiutareUnaAreaMaskTroppoLunga;
    [Test]
    procedure DovrebbeRifiutareUnMessaggioChiusoSenzaFine;
    [Test]
    procedure DovrebbeDimenticareLoStatoConClearState;
    [Test]
    procedure DovrebbeDareLoStessoDelCPerOgniMessaggioDelGolden;
  end;

implementation

function SnapshotAreaHash(const ASnapshot: TQ3Snapshot): Cardinal; forward;

class function TTestQ3ServerMessageParser.HashUpdate(AHash: Cardinal; const AData; ALength: Integer): Cardinal;
var
  LBytes: PByte;
  LIndex: Integer;
begin
  Result := AHash;
  LBytes := @AData;
  for LIndex := 0 to ALength - 1 do
  begin
    Result := Result xor LBytes^;
    Result := Result * 16777619;
    Inc(LBytes);
  end;
end;

class function TTestQ3ServerMessageParser.HexToBytes(const AText: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AText) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(StrToInt('$' + Copy(AText, LIndex * 2 + 1, 2)));
end;

function SnapshotAreaHash(const ASnapshot: TQ3Snapshot): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 0 to High(ASnapshot.AreaMask) do
    Result := (Result xor ASnapshot.AreaMask[LIndex]) * 16777619;
end;

{ TTestQ3ServerMessageParser }

procedure TTestQ3ServerMessageParser.SetupFixture;
begin
  FCoder := TQ3MessageHuffman.Create;
  FEntityCodec := TQ3EntityStateCodec.Create(TQ3NetFieldTable.ForEntityState);
  FPlayerCodec := TQ3PlayerStateCodec.Create(TQ3NetFieldTable.ForPlayerState);
end;

procedure TTestQ3ServerMessageParser.TearDownFixture;
begin
  FPlayerCodec.Free;
  FEntityCodec.Free;
  FCoder := nil;
end;

procedure TTestQ3ServerMessageParser.Setup;
begin
  FSinkObject := TFakeQ3ServerSink.Create;
  FSink := FSinkObject; // the interface keeps the sink alive for the length of the test
  FLogObject := TFakeQ3Log.Create;
  FLog := FLogObject;
  FParser := TQ3ServerMessageParser.Create(FCoder, FEntityCodec, FPlayerCodec, FSink, FLogObject);
end;

procedure TTestQ3ServerMessageParser.TearDown;
begin
  FParser.Free;
  FSink := nil;
  FLog := nil;
end;

function TTestQ3ServerMessageParser.NewWriter: TQ3Message;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, Q3_MAX_MSGLEN);
  Result := TQ3Message.Create(FCoder);
  Result.Init(LBuffer, Length(LBuffer));
  Result.WriteLong(42); // the reliable acknowledge
end;

procedure TTestQ3ServerMessageParser.Parse(AWriter: TQ3Message; ASequence: Integer);
var
  LLength: Integer;
begin
  try
    AWriter.WriteByte(Q3_SVC_EOF);
    LLength := AWriter.CurSize;
    FParser.ParseMessage(Copy(AWriter.Data, 0, LLength), LLength, ASequence);
  finally
    AWriter.Free;
  end;
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareArgomentiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3ServerMessageParser.Create(nil, FEntityCodec, FPlayerCodec, FSink).Free;
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3ServerMessageParser.Create(FCoder, nil, FPlayerCodec, FSink).Free;
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3ServerMessageParser.Create(FCoder, FEntityCodec, nil, FSink).Free;
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3ServerMessageParser.Create(FCoder, FEntityCodec, FPlayerCodec, nil).Free;
    end,
    EArgumentNilException);
end;

procedure TTestQ3ServerMessageParser.DovrebbeLeggereUnMessaggioConSoloNopEFine;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_NOP);
  Parse(LWriter);
  Assert.AreEqual(42, FParser.ReliableAcknowledge);
  Assert.AreEqual(1, FSinkObject.Events.Count);
  Assert.AreEqual('ack 42', FSinkObject.Events[0]);
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareUnComandoSconosciuto;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(99);
  Assert.WillRaise(
    procedure
    begin
      Parse(LWriter);
    end,
    EQ3ServerMessageException);
end;

procedure TTestQ3ServerMessageParser.DovrebbeIgnorareUnComandoGiaVisto;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_SERVERCOMMAND);
  LWriter.WriteLong(3);
  LWriter.WriteString('cs 1 "x"');
  LWriter.WriteByte(Q3_SVC_SERVERCOMMAND);
  LWriter.WriteLong(3);
  LWriter.WriteString('repeated');
  LWriter.WriteByte(Q3_SVC_SERVERCOMMAND);
  LWriter.WriteLong(4);
  LWriter.WriteString('next');
  Parse(LWriter);
  Assert.AreEqual(4, FParser.ServerCommandSequence);
  Assert.AreEqual(AnsiString('cs 1 "x"'), FSinkObject.CommandAt(3));
  Assert.AreEqual(AnsiString('next'), FSinkObject.CommandAt(4));
  Assert.AreEqual(3, FSinkObject.Events.Count);
end;

procedure TTestQ3ServerMessageParser.DovrebbeLeggereUnGamestate;
var
  LWriter: TQ3Message;
  LNull, LState: TQ3EntityState;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_GAMESTATE);
  LWriter.WriteLong(9);
  LWriter.WriteByte(Q3_SVC_CONFIGSTRING);
  LWriter.WriteShort(5);
  LWriter.WriteBigString('hello');
  FillChar(LNull, SizeOf(LNull), 0);
  FillChar(LState, SizeOf(LState), 0);
  LState.Number := 7;
  LState.ModelIndex := 3;
  LWriter.WriteByte(Q3_SVC_BASELINE);
  FEntityCodec.WriteDelta(LWriter, @LNull, @LState, True);
  LWriter.WriteByte(Q3_SVC_EOF);
  LWriter.WriteLong(11);
  LWriter.WriteLong(-5);
  Parse(LWriter);
  Assert.AreEqual(9, FParser.ServerCommandSequence);
  Assert.AreEqual(11, FParser.ClientNum);
  Assert.AreEqual(-5, FParser.ChecksumFeed);
  Assert.AreEqual(1 + Length('hello') + 1, FParser.GameStateChars);
  Assert.AreEqual(AnsiString('hello'), FSinkObject.ConfigStrings[5]);
  Assert.AreEqual(3, FSinkObject.BaselineAt(7).ModelIndex);
  Assert.AreEqual(7, FSinkObject.BaselineAt(7).Number);
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareUnaConfigstringFuoriIntervallo;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_GAMESTATE);
  LWriter.WriteLong(1);
  LWriter.WriteByte(Q3_SVC_CONFIGSTRING);
  LWriter.WriteShort(Q3_MAX_CONFIGSTRINGS);
  LWriter.WriteBigString('x');
  Assert.WillRaise(
    procedure
    begin
      Parse(LWriter);
    end,
    EQ3ServerMessageException, SQ3ServerConfigStringRange);
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareUnComandoSconosciutoNelGamestate;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_GAMESTATE);
  LWriter.WriteLong(1);
  LWriter.WriteByte(Q3_SVC_NOP);
  Assert.WillRaise(
    procedure
    begin
      Parse(LWriter);
    end,
    EQ3ServerMessageException, SQ3ServerBadGamestateCommand);
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareTroppiCaratteriNelGamestate;
var
  LWriter: TQ3Message;
  LIndex: Integer;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_GAMESTATE);
  LWriter.WriteLong(1);
  for LIndex := 0 to 3 do
  begin
    LWriter.WriteByte(Q3_SVC_CONFIGSTRING);
    LWriter.WriteShort(LIndex);
    LWriter.WriteBigString(AnsiString(StringOfChar('a', 4000)));
  end;
  Assert.WillRaise(
    procedure
    begin
      Parse(LWriter);
    end,
    EQ3ServerMessageException, SQ3ServerGamestateChars);
end;

procedure TTestQ3ServerMessageParser.DovrebbeLeggereUnDownload;
var
  LWriter: TQ3Message;
  LData: TBytes;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_DOWNLOAD);
  LWriter.WriteShort(0);
  LWriter.WriteLong(5000);
  LWriter.WriteShort(3);
  LData := TBytes.Create(1, 2, 3);
  LWriter.WriteData(LData, 3);
  LWriter.WriteByte(Q3_SVC_DOWNLOAD);
  LWriter.WriteShort(1);
  LWriter.WriteShort(0);
  Parse(LWriter);
  Assert.AreEqual(3, FSinkObject.DownloadBytes);
  Assert.AreEqual('download 0 5000 3', FSinkObject.Events[1]);
  Assert.AreEqual('download 1 0 0', FSinkObject.Events[2]);
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareUnDownloadRifiutatoDalServer;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_DOWNLOAD);
  LWriter.WriteShort(0);
  LWriter.WriteLong(-1);
  LWriter.WriteString('no such file');
  Assert.WillRaise(
    procedure
    begin
      Parse(LWriter);
    end,
    EQ3ServerMessageException, Format(SQ3ServerDownloadFailed, ['no such file']));
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareUnaAreaMaskTroppoLunga;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_SNAPSHOT);
  LWriter.WriteLong(100);
  LWriter.WriteByte(0);
  LWriter.WriteByte(0);
  LWriter.WriteByte(33);
  Assert.WillRaise(
    procedure
    begin
      Parse(LWriter);
    end,
    EQ3ServerMessageException, Format(SQ3ServerAreaMaskLength, [33]));
end;

procedure TTestQ3ServerMessageParser.DovrebbeRifiutareUnMessaggioChiusoSenzaFine;
var
  LWriter: TQ3Message;
  LLength: Integer;
begin
  LWriter := NewWriter;
  try
    LLength := LWriter.CurSize;
    Assert.WillRaise(
      procedure
      begin
        FParser.ParseMessage(Copy(LWriter.Data, 0, LLength), LLength, 1);
      end,
      EQ3ServerMessageException);
  finally
    LWriter.Free;
  end;
end;

procedure TTestQ3ServerMessageParser.DovrebbeDimenticareLoStatoConClearState;
var
  LWriter: TQ3Message;
begin
  LWriter := NewWriter;
  LWriter.WriteByte(Q3_SVC_GAMESTATE);
  LWriter.WriteLong(1);
  LWriter.WriteByte(Q3_SVC_CONFIGSTRING);
  LWriter.WriteShort(2);
  LWriter.WriteBigString('abc');
  LWriter.WriteByte(Q3_SVC_EOF);
  LWriter.WriteLong(0);
  LWriter.WriteLong(0);
  Parse(LWriter);
  Assert.AreEqual(5, FParser.GameStateChars);
  FParser.ClearState;
  Assert.AreEqual(0, FParser.GameStateChars);
  Assert.AreEqual(0, FParser.ParseEntitiesNum);
  Assert.IsFalse(FParser.CurrentSnapshot.Valid);
end;

procedure TTestQ3ServerMessageParser.DovrebbeDareLoStessoDelCPerOgniMessaggioDelGolden;
var
  LLines: TArray<string>;
  LLine: string;
  LExpected: TStringList;
  LStream: TMemoryStream;
  LReader: TQ3DemoReader;
  LTerminator: Byte;
  LBytes: TBytes;
  LSequence: Integer;
  LData: TBytes;
  LIndex: Integer;
  LFailed: Boolean;
  LSnapshot: TQ3Snapshot;
  LHash: Cardinal;
  LPair: TPair<Integer, AnsiString>;
  LSorted: TList<Integer>;
  LKey: Integer;
  LCount: Integer;
  LText: string;
  LPrints: string;
  LState: TQ3EntityState;
  LZero: TQ3EntityState;
  LEntity: TQ3EntityState;
  LPlayerHash: Cardinal;
  LEntityHash: Cardinal;
  LLength: Integer;

  procedure WriteInteger(AValue: Integer);
  begin
    LStream.WriteBuffer(AValue, 4);
  end;

begin
  LTerminator := 0;
  LExpected := TStringList.Create;
  LStream := TMemoryStream.Create;
  LSorted := TList<Integer>.Create;
  try
    LLines := TFile.ReadAllLines(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Net\q3demo-golden.txt')));
    for LLine in LLines do
      if LLine.StartsWith('demo.message ') then
      begin
        LBytes := HexToBytes(Copy(LLine, Pos('hex=', LLine) + 4, MaxInt));
        WriteInteger(StrToInt(Copy(LLine, Pos('seq=', LLine) + 4, Pos(' len=', LLine) - Pos('seq=', LLine) - 4)));
        WriteInteger(Length(LBytes));
        LStream.WriteBuffer(LBytes[0], Length(LBytes));
      end
      else
        LExpected.Add(LLine);
    WriteInteger(0);
    WriteInteger(-1);
    Assert.AreEqual(0, LExpected.Count mod 5, 'il golden ha cinque righe per messaggio');
    LStream.Position := 0;
    LReader := TQ3DemoReader.Create(LStream);
    try
      LIndex := 0;
      while LReader.ReadMessage(LSequence, LData) = drMessage do
      begin
        FLogObject.Clear;
        LFailed := False;
        try
          FParser.ParseMessage(LData, Length(LData), LSequence);
        except
          on EQ3NetException do
            LFailed := True;
        end;
        LPrints := '';
        for LText in FLogObject.Infos do
          LPrints := LPrints + LText + '|';
        Assert.AreEqual(Format('demo.parse %d err=%d prints=[%s]', [LIndex, Ord(LFailed), LPrints]),
          LExpected[LIndex * 5], 'messaggio ' + IntToStr(LIndex));
        Assert.AreEqual(Format('demo.state %d ack=%d scs=%d cmd=[%s] dc=%d cn=%d cf=%d pe=%d',
          [LIndex, FParser.ReliableAcknowledge, FParser.ServerCommandSequence,
          string(FSinkObject.CommandAt(FParser.ServerCommandSequence)), FParser.GameStateChars, FParser.ClientNum,
          FParser.ChecksumFeed, FParser.ParseEntitiesNum]), LExpected[LIndex * 5 + 1], 'messaggio ' + IntToStr(LIndex));

        LSorted.Clear;
        for LPair in FSinkObject.ConfigStrings do
          LSorted.Add(LPair.Key);
        LSorted.Sort;
        LHash := 2166136261;
        for LKey in LSorted do
        begin
          LHash := HashUpdate(LHash, LKey, 4);
          LHash := HashUpdate(LHash, FSinkObject.ConfigStrings[LKey][1], Length(FSinkObject.ConfigStrings[LKey]));
          LHash := HashUpdate(LHash, LTerminator, 1);
        end;
        Assert.AreEqual(Format('demo.cs %d n=%d fnv=%.8x', [LIndex, LSorted.Count, LHash]),
          LExpected[LIndex * 5 + 2], 'messaggio ' + IntToStr(LIndex));

        FillChar(LZero, SizeOf(LZero), 0);
        LHash := 2166136261;
        LCount := 0;
        for LKey := 0 to Q3_MAX_GENTITIES - 1 do
        begin
          LState := FSinkObject.BaselineAt(LKey);
          LHash := HashUpdate(LHash, LState, SizeOf(LState));
          if not CompareMem(@LState, @LZero, SizeOf(LState)) then
            Inc(LCount);
        end;
        Assert.AreEqual(Format('demo.bl %d n=%d fnv=%.8x', [LIndex, LCount, LHash]),
          LExpected[LIndex * 5 + 3], 'messaggio ' + IntToStr(LIndex));

        LSnapshot := FSinkObject.LastSnapshot;
        LPlayerHash := HashUpdate(2166136261, LSnapshot.PlayerState, SizeOf(LSnapshot.PlayerState));
        LEntityHash := 2166136261;
        for LEntity in LSnapshot.Entities do
          LEntityHash := HashUpdate(LEntityHash, LEntity, SizeOf(LEntity));
        LLength := LSnapshot.NumEntities;
        Assert.AreEqual(Format('demo.snap %d valid=%d flags=%d time=%d msg=%d delta=%d scn=%d ne=%d pen=%d ' +
          'area=%.8x ps=%.8x ents=%.8x', [LIndex, Ord(LSnapshot.Valid), LSnapshot.SnapFlags, LSnapshot.ServerTime,
          LSnapshot.MessageNum, LSnapshot.DeltaNum, LSnapshot.ServerCommandNum, LLength,
          LSnapshot.ParseEntitiesNum, SnapshotAreaHash(LSnapshot), LPlayerHash, LEntityHash]),
          LExpected[LIndex * 5 + 4], 'messaggio ' + IntToStr(LIndex));
        Inc(LIndex);
      end;
      Assert.AreEqual(LExpected.Count div 5, LIndex, 'messaggi letti');
      Assert.AreEqual(LIndex, LReader.MessageCount);
    finally
      LReader.Free;
    end;
  finally
    LSorted.Free;
    LStream.Free;
    LExpected.Free;
  end;
end;

end.
