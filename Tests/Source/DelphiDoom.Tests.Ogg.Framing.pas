{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the framing of Ogg: packets, pages and sync            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.Framing;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Ogg.Types,
  DelphiDoom.Tests.Ogg.Backends;

type
  TTestPacket = record
    Data: TBytes;
    Granule: Int64;
    EndOfStream: Boolean;
  end;

  [TestFixture]
  [Category('ogg')]
  TTestOggFraming = class(TObject)
  private
    FPascal: TOggBackend;
    function MakePacket(const ASize: Integer; const AGranule: Int64; const AEnd: Boolean): TTestPacket;
    function PageBytes(const APage: POggPage): TBytes;
    function Encode(const ABackend: TOggBackend; const APackets: TArray<TTestPacket>; const ASerial: Integer;
      const AMode: Integer): TArray<TBytes>;
    function Decode(const ABackend: TOggBackend; const AStream: TBytes; const ASerial: Integer;
      const AChunk: Integer; const AUseSeek: Boolean): string;
    function Join(const APages: TArray<TBytes>): TBytes;
    function RandomPackets(const ACount: Integer; const AMaxSize: Integer): TArray<TTestPacket>;
    function PacketSummary(const APacket: POggPacket): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUnPacchettoPiccoloFaUnaPagina;
    [Test]
    procedure TestIlPrimoPacchettoStaDaSoloNellaPrimaPagina;
    [Test]
    procedure TestUnPacchettoGrandeOccupaPiuPagine;
    [Test]
    procedure TestCodificaEDecodificaDannoGliStessiPacchetti;
    [Test]
    procedure TestUnaPaginaPersaSiVedeComeBuco;
    [Test]
    procedure TestUnaPaginaConChecksumErrataNonSiLegge;
    [Test]
    procedure TestServonoAltriDatiPerUnaPaginaIntera;
    [Test]
    procedure TestUnNumeroDiSerieDiversoVieneRifiutato;
    [Test]
    procedure TestResetRicominciaLaNumerazione;
    [Test]
    procedure TestIlGranuleDiUnaPaginaSenzaPacchettiCompletiENegativo;
    [Test]
    procedure TestLeFunzioniSuUnoStatoVuotoNonFannoNulla;
  end;

implementation

uses
  DelphiDoom.Ogg.Stream;

{ TTestOggFraming }

procedure TTestOggFraming.Setup;
begin
  FPascal := TPascalOggBackend.Create;
end;

procedure TTestOggFraming.TearDown;
begin
  FPascal.Free;
end;

function TTestOggFraming.MakePacket(const ASize: Integer; const AGranule: Int64; const AEnd: Boolean): TTestPacket;
var
  LIndex: Integer;
begin
  SetLength(Result.Data, ASize);
  for LIndex := 0 to ASize - 1 do
    Result.Data[LIndex] := Byte(LIndex * 7 + ASize);
  Result.Granule := AGranule;
  Result.EndOfStream := AEnd;
end;

function TTestOggFraming.PageBytes(const APage: POggPage): TBytes;
begin
  SetLength(Result, APage.HeaderLength + APage.BodyLength);
  Move(APage.Header^, Result[0], APage.HeaderLength);
  if APage.BodyLength > 0 then
    Move(APage.Body^, Result[APage.HeaderLength], APage.BodyLength);
end;

function TTestOggFraming.Join(const APages: TArray<TBytes>): TBytes;
var
  LPage: TBytes;
  LOffset: Integer;
begin
  LOffset := 0;
  for LPage in APages do
    Inc(LOffset, Length(LPage));
  SetLength(Result, LOffset);
  LOffset := 0;
  for LPage in APages do
  begin
    if Length(LPage) > 0 then
      Move(LPage[0], Result[LOffset], Length(LPage));
    Inc(LOffset, Length(LPage));
  end;
end;

// Submits the packets and takes the pages out, in one of four ways
function TTestOggFraming.Encode(const ABackend: TOggBackend; const APackets: TArray<TTestPacket>;
  const ASerial: Integer; const AMode: Integer): TArray<TBytes>;
var
  LState: TOggStreamState;
  LPage: TOggPage;
  LPacket: TOggPacket;
  LVectors: array[0..1] of TOggIoVec;
  LPages: TList<TBytes>;
  LIndex, LHalf: Integer;
  LDummy: Byte;

  procedure Collect;
  begin
    case AMode of
      0, 3:
        while ABackend.PageOut(@LState, @LPage) = 1 do
          LPages.Add(PageBytes(@LPage));
      1:
        while ABackend.Flush(@LState, @LPage) = 1 do
          LPages.Add(PageBytes(@LPage));
    else
      while ABackend.PageOutFill(@LState, @LPage, 1000) = 1 do
        LPages.Add(PageBytes(@LPage));
    end;
  end;

begin
  LPages := TList<TBytes>.Create;
  try
    ABackend.StreamInit(@LState, ASerial);
    for LIndex := 0 to High(APackets) do
    begin
      if AMode = 3 then
      begin
        // The packet in two blocks
        LHalf := Length(APackets[LIndex].Data) div 2;
        LVectors[0].Base := @LDummy;
        if LHalf > 0 then
          LVectors[0].Base := @APackets[LIndex].Data[0];
        LVectors[0].Length := LHalf;
        LVectors[1].Base := @LDummy;
        if Length(APackets[LIndex].Data) - LHalf > 0 then
          LVectors[1].Base := @APackets[LIndex].Data[LHalf];
        LVectors[1].Length := Length(APackets[LIndex].Data) - LHalf;
        ABackend.IoVecIn(@LState, @LVectors[0], 2, Ord(APackets[LIndex].EndOfStream), APackets[LIndex].Granule);
      end
      else
      begin
        FillChar(LPacket, SizeOf(LPacket), 0);
        if Length(APackets[LIndex].Data) > 0 then
          LPacket.Packet := @APackets[LIndex].Data[0]
        else
          LPacket.Packet := @LDummy;
        LPacket.Bytes := Length(APackets[LIndex].Data);
        LPacket.EndOfStream := Ord(APackets[LIndex].EndOfStream);
        LPacket.GranulePosition := APackets[LIndex].Granule;
        ABackend.PacketIn(@LState, @LPacket);
      end;
      Collect;
    end;
    // What is left
    while ABackend.Flush(@LState, @LPage) = 1 do
      LPages.Add(PageBytes(@LPage));
    ABackend.StreamClear(@LState);
    Result := LPages.ToArray;
  finally
    LPages.Free;
  end;
end;

function TTestOggFraming.PacketSummary(const APacket: POggPacket): string;
var
  LSum: Cardinal;
  LIndex: Integer;
begin
  // A fingerprint of the bytes keeps the log short
  LSum := 17;
  for LIndex := 0 to APacket.Bytes - 1 do
    LSum := LSum * 31 + APacket.Packet[LIndex];
  Result := Format('pkt bytes=%d bos=%d eos=%d granule=%d no=%d sum=%d',
    [APacket.Bytes, APacket.BeginningOfStream, APacket.EndOfStream, APacket.GranulePosition,
     APacket.PacketNumber, LSum]);
end;

// Gives the bytes to the sync in chunks and logs what comes out of it and of the stream
function TTestOggFraming.Decode(const ABackend: TOggBackend; const AStream: TBytes; const ASerial: Integer;
  const AChunk: Integer; const AUseSeek: Boolean): string;
var
  LSync: TOggSyncState;
  LState: TOggStreamState;
  LPage: TOggPage;
  LPacket: TOggPacket;
  LLog: TStringBuilder;
  LOffset, LCount, LResult: Integer;
  LSeek: Longint;
  LBuffer: PByte;

  procedure HandlePage;
  var
    LPackets: Integer;
  begin
    LLog.AppendFormat('page bos=%d eos=%d cont=%d granule=%d serial=%d no=%d packets=%d version=%d',
      [ABackend.PageBeginning(@LPage), ABackend.PageEnd(@LPage), ABackend.PageContinued(@LPage),
       ABackend.PageGranule(@LPage), ABackend.PageSerial(@LPage), ABackend.PageNumber(@LPage),
       ABackend.PagePackets(@LPage), ABackend.PageVersion(@LPage)]).AppendLine;
    LLog.AppendFormat('pagein=%d', [ABackend.PageIn(@LState, @LPage)]).AppendLine;
    LPackets := 0;
    while LPackets < 100000 do
    begin
      LResult := ABackend.PacketPeek(@LState, nil);
      LLog.AppendFormat('peek=%d', [LResult]).AppendLine;
      LResult := ABackend.PacketOut(@LState, @LPacket);
      if LResult = 0 then
        Break;
      if LResult = 1 then
        LLog.AppendLine(PacketSummary(@LPacket))
      else
        LLog.AppendFormat('packetout=%d', [LResult]).AppendLine;
      Inc(LPackets);
    end;
  end;

begin
  LLog := TStringBuilder.Create;
  try
    ABackend.SyncInit(@LSync);
    ABackend.StreamInit(@LState, ASerial);
    LOffset := 0;
    while LOffset <= Length(AStream) do
    begin
      LCount := Length(AStream) - LOffset;
      if LCount > AChunk then
        LCount := AChunk;
      if LCount > 0 then
      begin
        LBuffer := ABackend.SyncBuffer(@LSync, LCount);
        Move(AStream[LOffset], LBuffer^, LCount);
        LLog.AppendFormat('wrote=%d', [ABackend.SyncWrote(@LSync, LCount)]).AppendLine;
      end;
      Inc(LOffset, AChunk);

      while True do
      begin
        if AUseSeek then
        begin
          LSeek := ABackend.SyncPageSeek(@LSync, @LPage);
          LLog.AppendFormat('seek=%d', [LSeek]).AppendLine;
          if LSeek = 0 then
            Break;
          if LSeek < 0 then
            Continue;
          HandlePage;
        end
        else
        begin
          LResult := ABackend.SyncPageOut(@LSync, @LPage);
          LLog.AppendFormat('pageout=%d', [LResult]).AppendLine;
          if LResult = 0 then
            Break;
          if LResult < 0 then
            Continue;
          HandlePage;
        end;
      end;
      if LCount = 0 then
        Break;
    end;
    LLog.AppendFormat('eos=%d', [ABackend.StreamEnd(@LState)]).AppendLine;
    ABackend.SyncClear(@LSync);
    ABackend.StreamClear(@LState);
    Result := LLog.ToString;
  finally
    LLog.Free;
  end;
end;

function TTestOggFraming.RandomPackets(const ACount: Integer; const AMaxSize: Integer): TArray<TTestPacket>;
var
  LIndex, LSize: Integer;
  LGranule: Int64;
begin
  SetLength(Result, ACount);
  LGranule := 0;
  for LIndex := 0 to ACount - 1 do
  begin
    case Random(6) of
      0: LSize := 0;
      1: LSize := Random(5);
      2: LSize := 250 + Random(12);
      3: LSize := Random(AMaxSize);
    else
      LSize := Random(600);
    end;
    LGranule := LGranule + Random(2000);
    Result[LIndex] := MakePacket(LSize, LGranule, (LIndex = ACount - 1) and (Random(2) = 0));
    // Some packets without a position
    if Random(10) = 0 then
      Result[LIndex].Granule := -1;
  end;
end;

procedure TTestOggFraming.TestUnPacchettoPiccoloFaUnaPagina;
var
  LState: TOggStreamState;
  LPage: TOggPage;
  LPacket: TOggPacket;
  LData: TBytes;
  LCrc: array[0..3] of Byte;
  LIndex: Integer;
begin
  LData := MakePacket(10, 77, True).Data;
  FPascal.StreamInit(@LState, 1234);
  FillChar(LPacket, SizeOf(LPacket), 0);
  LPacket.Packet := @LData[0];
  LPacket.Bytes := 10;
  LPacket.EndOfStream := 1;
  LPacket.GranulePosition := 77;
  FPascal.PacketIn(@LState, @LPacket);

  Assert.AreEqual(1, FPascal.Flush(@LState, @LPage));

  Assert.AreEqual(28, LPage.HeaderLength);
  Assert.AreEqual(10, LPage.BodyLength);
  Assert.AreEqual(Integer(Ord('O')), Integer(LPage.Header[0]));
  Assert.AreEqual(Integer(Ord('S')), Integer(LPage.Header[3]));
  Assert.AreEqual(0, FPascal.PageVersion(@LPage));
  Assert.AreEqual(2, FPascal.PageBeginning(@LPage));
  Assert.AreEqual(4, FPascal.PageEnd(@LPage));
  Assert.AreEqual(0, FPascal.PageContinued(@LPage));
  // The first page of a stream has the position 0 whatever the packet says
  Assert.AreEqual(Int64(0), FPascal.PageGranule(@LPage));
  Assert.AreEqual(1234, FPascal.PageSerial(@LPage));
  Assert.AreEqual(0, Integer(FPascal.PageNumber(@LPage)));
  Assert.AreEqual(1, FPascal.PagePackets(@LPage));
  Assert.AreEqual(1, Integer(LPage.Header[26]));
  Assert.AreEqual(10, Integer(LPage.Header[27]));

  // The checksum in the header is the one that setting it again gives
  for LIndex := 0 to 3 do
    LCrc[LIndex] := LPage.Header[22 + LIndex];
  FPascal.PageChecksum(@LPage);
  for LIndex := 0 to 3 do
    Assert.AreEqual(Integer(LCrc[LIndex]), Integer(LPage.Header[22 + LIndex]));
  Assert.IsTrue((LCrc[0] or LCrc[1] or LCrc[2] or LCrc[3]) <> 0);
  FPascal.StreamClear(@LState);
end;

procedure TTestOggFraming.TestIlPrimoPacchettoStaDaSoloNellaPrimaPagina;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
begin
  SetLength(LPackets, 3);
  LPackets[0] := MakePacket(30, 0, False);
  LPackets[1] := MakePacket(40, 100, False);
  LPackets[2] := MakePacket(50, 200, True);

  LPages := Encode(FPascal, LPackets, 5, 0);

  // The header packet has a page for itself; the others share the next one
  Assert.AreEqual<Integer>(2, Length(LPages));
  Assert.AreEqual<Integer>(27 + 1 + 30, Length(LPages[0]));
  Assert.AreEqual<Integer>(27 + 2 + 90, Length(LPages[1]));
end;

procedure TTestOggFraming.TestUnPacchettoGrandeOccupaPiuPagine;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LLog: string;
begin
  SetLength(LPackets, 2);
  LPackets[0] := MakePacket(20, 0, False);
  LPackets[1] := MakePacket(70000, 5000, True);

  LPages := Encode(FPascal, LPackets, 9, 0);

  Assert.IsTrue(Length(LPages) > 2, 'more pages');
  LLog := Decode(FPascal, Join(LPages), 9, 4000, False);
  Assert.IsTrue(Pos('pkt bytes=70000', LLog) > 0, 'the big packet is back');
  Assert.IsTrue(Pos('cont=1', LLog) > 0, 'a page continues the packet');
end;

procedure TTestOggFraming.TestCodificaEDecodificaDannoGliStessiPacchetti;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LLog: string;
  LExpected: string;
  LIndex: Integer;
  LSum: Cardinal;
  LByte: Integer;
begin
  RandSeed := 99;
  LPackets := RandomPackets(40, 3000);
  LPackets[High(LPackets)].EndOfStream := True;

  LPages := Encode(FPascal, LPackets, 31, 0);
  LLog := Decode(FPascal, Join(LPages), 31, 777, False);

  for LIndex := 0 to High(LPackets) do
  begin
    LSum := 17;
    for LByte := 0 to High(LPackets[LIndex].Data) do
      LSum := LSum * 31 + LPackets[LIndex].Data[LByte];
    LExpected := Format('bytes=%d ', [Length(LPackets[LIndex].Data)]);
    Assert.IsTrue(Pos(LExpected, LLog) > 0, Format('packet %d (%s)', [LIndex, LExpected]));
    Assert.IsTrue(Pos(Format('sum=%d', [LSum]), LLog) > 0, Format('packet %d: bytes', [LIndex]));
  end;
  Assert.IsTrue(Pos('eos=1', LLog) > 0);
end;

procedure TTestOggFraming.TestUnaPaginaPersaSiVedeComeBuco;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LKept: TList<TBytes>;
  LIndex: Integer;
  LLog: string;
begin
  SetLength(LPackets, 30);
  for LIndex := 0 to High(LPackets) do
    LPackets[LIndex] := MakePacket(200, LIndex * 10, LIndex = High(LPackets));
  LPages := Encode(FPascal, LPackets, 3, 1);
  Assert.IsTrue(Length(LPages) > 5);

  LKept := TList<TBytes>.Create;
  try
    for LIndex := 0 to High(LPages) do
    begin
      // The third page is lost
      if LIndex <> 2 then
        LKept.Add(LPages[LIndex]);
    end;
    LLog := Decode(FPascal, Join(LKept.ToArray), 3, 100000, False);
  finally
    LKept.Free;
  end;

  // The hole is told by the first call that meets it: the peek of the log or the packetout
  Assert.IsTrue((Pos('packetout=-1', LLog) > 0) or (Pos('peek=-1', LLog) > 0), 'the codec is told about the hole');
end;

procedure TTestOggFraming.TestUnaPaginaConChecksumErrataNonSiLegge;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LStream: TBytes;
  LLog, LCleanLog: string;
begin
  SetLength(LPackets, 6);
  LPackets[0] := MakePacket(30, 0, False);
  LPackets[1] := MakePacket(100, 10, False);
  LPackets[2] := MakePacket(100, 20, False);
  LPackets[3] := MakePacket(100, 30, False);
  LPackets[4] := MakePacket(100, 40, False);
  LPackets[5] := MakePacket(100, 50, True);
  LPages := Encode(FPascal, LPackets, 8, 1);
  LStream := Join(LPages);
  LCleanLog := Decode(FPascal, LStream, 8, 100000, False);

  // A byte of the body of the second page changes
  LStream[Length(LPages[0]) + Length(LPages[1]) - 3] := LStream[Length(LPages[0]) + Length(LPages[1]) - 3] xor $55;
  LLog := Decode(FPascal, LStream, 8, 100000, False);

  Assert.IsFalse(LLog = LCleanLog);
  Assert.IsTrue(Pos('pageout=-1', LLog) > 0, 'sync is lost once');
end;

procedure TTestOggFraming.TestServonoAltriDatiPerUnaPaginaIntera;
var
  LSync: TOggSyncState;
  LPage: TOggPage;
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LBuffer: PByte;
  LHalf: Integer;
begin
  SetLength(LPackets, 1);
  LPackets[0] := MakePacket(500, 5, True);
  LPages := Encode(FPascal, LPackets, 2, 1);
  Assert.AreEqual<Integer>(1, Length(LPages));
  LHalf := Length(LPages[0]) div 2;

  FPascal.SyncInit(@LSync);
  LBuffer := FPascal.SyncBuffer(@LSync, LHalf);
  Move(LPages[0][0], LBuffer^, LHalf);
  FPascal.SyncWrote(@LSync, LHalf);
  Assert.AreEqual(0, FPascal.SyncPageOut(@LSync, @LPage));

  LBuffer := FPascal.SyncBuffer(@LSync, Length(LPages[0]) - LHalf);
  Move(LPages[0][LHalf], LBuffer^, Length(LPages[0]) - LHalf);
  FPascal.SyncWrote(@LSync, Length(LPages[0]) - LHalf);
  Assert.AreEqual(1, FPascal.SyncPageOut(@LSync, @LPage));
  Assert.AreEqual(500, Integer(LPage.BodyLength));
  FPascal.SyncClear(@LSync);
end;

procedure TTestOggFraming.TestUnNumeroDiSerieDiversoVieneRifiutato;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LLog: string;
begin
  SetLength(LPackets, 1);
  LPackets[0] := MakePacket(50, 5, True);
  LPages := Encode(FPascal, LPackets, 100, 1);

  LLog := Decode(FPascal, Join(LPages), 101, 1000, False);

  Assert.IsTrue(Pos('pagein=-1', LLog) > 0);
  Assert.IsFalse(Pos('pkt bytes', LLog) > 0);
end;

procedure TTestOggFraming.TestResetRicominciaLaNumerazione;
var
  LState: TOggStreamState;
  LPage: TOggPage;
  LPacket: TOggPacket;
  LData: TBytes;
begin
  LData := MakePacket(10, 1, False).Data;
  FPascal.StreamInit(@LState, 4);
  FillChar(LPacket, SizeOf(LPacket), 0);
  LPacket.Packet := @LData[0];
  LPacket.Bytes := 10;
  FPascal.PacketIn(@LState, @LPacket);
  FPascal.Flush(@LState, @LPage);
  FPascal.PacketIn(@LState, @LPacket);
  FPascal.Flush(@LState, @LPage);
  Assert.AreEqual(1, Integer(FPascal.PageNumber(@LPage)));

  Assert.AreEqual(0, FPascal.StreamResetSerial(@LState, 8));
  FPascal.PacketIn(@LState, @LPacket);
  FPascal.Flush(@LState, @LPage);

  Assert.AreEqual(0, Integer(FPascal.PageNumber(@LPage)));
  Assert.AreEqual(8, FPascal.PageSerial(@LPage));
  Assert.AreEqual(2, FPascal.PageBeginning(@LPage));
  FPascal.StreamClear(@LState);
end;

procedure TTestOggFraming.TestIlGranuleDiUnaPaginaSenzaPacchettiCompletiENegativo;
var
  LPackets: TArray<TTestPacket>;
  LPages: TArray<TBytes>;
  LPage: TOggPage;
  LStream: TBytes;
  LSync: TOggSyncState;
  LBuffer: PByte;
begin
  SetLength(LPackets, 2);
  LPackets[0] := MakePacket(10, 0, False);
  LPackets[1] := MakePacket(70000, 500, True);
  LPages := Encode(FPascal, LPackets, 6, 0);
  LStream := LPages[1];

  FPascal.SyncInit(@LSync);
  LBuffer := FPascal.SyncBuffer(@LSync, Length(LStream));
  Move(LStream[0], LBuffer^, Length(LStream));
  FPascal.SyncWrote(@LSync, Length(LStream));
  Assert.AreEqual(1, FPascal.SyncPageOut(@LSync, @LPage));

  // The packet goes on after the page: the position is -1
  Assert.AreEqual(Int64(-1), FPascal.PageGranule(@LPage));
  FPascal.SyncClear(@LSync);
end;

procedure TTestOggFraming.TestLeFunzioniSuUnoStatoVuotoNonFannoNulla;
var
  LState: TOggStreamState;
  LPage: TOggPage;
  LPacket: TOggPacket;
  LHeader: array[0..26] of Byte;
begin
  FillChar(LState, SizeOf(LState), 0);
  FillChar(LHeader, SizeOf(LHeader), 0);
  FillChar(LPage, SizeOf(LPage), 0);
  LPage.Header := @LHeader[0];
  LPage.HeaderLength := SizeOf(LHeader);

  Assert.AreEqual(-1, FPascal.StreamReset(@LState));
  Assert.AreEqual(0, FPascal.PacketOut(@LState, @LPacket));
  Assert.AreEqual(0, FPascal.PacketPeek(@LState, @LPacket));
  Assert.AreEqual(0, FPascal.PageOut(@LState, @LPage));
  Assert.AreEqual(0, FPascal.Flush(@LState, @LPage));
  Assert.AreEqual(1, FPascal.StreamEnd(@LState));
  Assert.AreEqual(-1, FPascal.PageIn(@LState, @LPage));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOggFraming);

end.
