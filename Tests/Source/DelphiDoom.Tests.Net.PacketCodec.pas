{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - the bytes of a packet                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.PacketCodec;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Net.Types, DelphiDoom.Net.Intf, DelphiDoom.Net.PacketCodec;

type
  /// <summary>
  ///   Tests\Data\Net\wire_golden.txt was written by a program that compiled the old d_ticcmd and d_net_h
  ///   (once for each game, with its define) and printed SizeOf, the offsets of the fields and, for
  ///   packets filled in a known way, the bytes of the record and the checksum computed by the old
  ///   NetbufferChecksum on a buffer that is zero after the end of the packet
  /// </summary>
  [TestFixture]
  [Category('net')]
  TTestNetPacketCodec = class(TObject)
  private
    FGolden: TDictionary<string, string>;
    function GoldenPath: string;
    function Value(const AGame, AName: string): string;
    function HexToBytes(const AHex: string): TBytes;
    function GoldenCommandSize(const AGame: string): Integer;
    function MakePacket(ANumTics, ACommandSize: Integer): TNetPacket;
    function MakeCodec(const AGame: string): INetPacketCodec;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    [TestCase('Doom', 'DOOM,14')]
    [TestCase('Heretic', 'HERETIC,16')]
    [TestCase('Hexen', 'HEXEN,16')]
    [TestCase('Strife', 'STRIFE,19')]
    procedure TestCommandSizeIsTheOldTiccmdSize(const AGame: string; AExpected: Integer);

    [Test]
    [TestCase('Doom', 'DOOM')]
    [TestCase('Heretic', 'HERETIC')]
    [TestCase('Hexen', 'HEXEN')]
    [TestCase('Strife', 'STRIFE')]
    procedure TestLargestPacketHasTheSizeOfTheOldDoomdata(const AGame: string);

    [Test]
    [TestCase('Doom', 'DOOM')]
    [TestCase('Heretic', 'HERETIC')]
    [TestCase('Hexen', 'HEXEN')]
    [TestCase('Strife', 'STRIFE')]
    procedure TestFieldOffsetsAreTheOldOnes(const AGame: string);

    [Test]
    [TestCase('Doom', 'DOOM')]
    [TestCase('Heretic', 'HERETIC')]
    [TestCase('Hexen', 'HEXEN')]
    [TestCase('Strife', 'STRIFE')]
    procedure TestEncodedBytesAreTheOldBytes(const AGame: string);

    [Test]
    [TestCase('Doom', 'DOOM')]
    [TestCase('Heretic', 'HERETIC')]
    [TestCase('Hexen', 'HEXEN')]
    [TestCase('Strife', 'STRIFE')]
    procedure TestChecksumIsTheOldChecksum(const AGame: string);

    [Test]
    [TestCase('Doom', 'DOOM')]
    [TestCase('Heretic', 'HERETIC')]
    [TestCase('Hexen', 'HEXEN')]
    [TestCase('Strife', 'STRIFE')]
    procedure TestOldBytesAreDecoded(const AGame: string);

    [Test]
    procedure TestStaleBytesAfterTheEndAreZeroHere;
    [Test]
    procedure TestControlFlagsGoInTheHighBitsOfTheChecksumWord;
    [Test]
    procedure TestFlagsAreLittleEndianAtOffsetEight;
    [Test]
    procedure TestRoundTripKeepsEveryField;
    [Test]
    procedure TestShortDatagramIsBadLength;
    [Test]
    procedure TestExtraByteIsBadLength;
    [Test]
    procedure TestMoreTicsThanTheMaximumIsBadLength;
    [Test]
    procedure TestChangedByteIsBadChecksum;
    [Test]
    procedure TestChangedFlagsAreBadChecksum;
    [Test]
    procedure TestEncodeRefusesTooManyTics;
    [Test]
    procedure TestEncodeRefusesCommandsOfTheWrongLength;
    [Test]
    procedure TestCodecRefusesBadParameters;
    [Test]
    procedure TestChecksumIgnoresBytesBeyondTheSize;
  end;

implementation

{ TTestNetPacketCodec }

procedure TTestNetPacketCodec.SetupFixture;
var
  LLines: TStringList;
  LLine: string;
  LGame: string;
  LPosition: Integer;
begin
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(GoldenPath);
    for LLine in LLines do
    begin
      if LLine.StartsWith('game=') then
        LGame := Copy(LLine, 6, MaxInt)
      else if LLine.StartsWith('packet n=') then
      begin
        // "packet n=3 size=54 checksum=$04BEDF42 bytes=..."
        LPosition := Pos(' ', Copy(LLine, 10, MaxInt));
        FGolden.Add(LGame + '|packet' + Copy(LLine, 10, LPosition - 1), Copy(LLine, 10 + LPosition, MaxInt));
      end
      else if LLine.StartsWith('stale n=1 checksum=$') then
        FGolden.Add(LGame + '|stale', Copy(LLine, 21, MaxInt))
      else if Pos('=', LLine) > 0 then
        FGolden.Add(LGame + '|' + Copy(LLine, 1, Pos('=', LLine) - 1), Copy(LLine, Pos('=', LLine) + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestNetPacketCodec.TearDownFixture;
begin
  FGolden.Free;
end;

function TTestNetPacketCodec.GoldenPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Net\wire_golden.txt'));
end;

function TTestNetPacketCodec.Value(const AGame, AName: string): string;
begin
  if not FGolden.TryGetValue(AGame + '|' + AName, Result) then
    Assert.Fail('Golden value not found: ' + AGame + ' ' + AName);
end;

function TTestNetPacketCodec.HexToBytes(const AHex: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(StrToInt('$' + Copy(AHex, LIndex * 2 + 1, 2)));
end;

function TTestNetPacketCodec.GoldenCommandSize(const AGame: string): Integer;
begin
  Result := StrToInt(Value(AGame, 'sizeof(ticcmd_t)'));
end;

function TTestNetPacketCodec.MakePacket(ANumTics, ACommandSize: Integer): TNetPacket;
var
  LIndex: Integer;
begin
  // the same fill as the program that made the golden file
  Result := Default(TNetPacket);
  Result.RetransmitFrom := $11;
  Result.StartTic := $22;
  Result.Player := 1;
  Result.NumTics := ANumTics;
  Result.Flags := $A5;
  SetLength(Result.Commands, ANumTics * ACommandSize);
  for LIndex := 0 to High(Result.Commands) do
    Result.Commands[LIndex] := Byte(LIndex * 7 + 3);
end;

function TTestNetPacketCodec.MakeCodec(const AGame: string): INetPacketCodec;
begin
  Result := TNetPacketCodec.Create(GoldenCommandSize(AGame), NET_BACKUPTICS);
end;

procedure TTestNetPacketCodec.TestCommandSizeIsTheOldTiccmdSize(const AGame: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, GoldenCommandSize(AGame), 'dimensione nel golden');
  Assert.AreEqual(AExpected, MakeCodec(AGame).CommandSize);
end;

procedure TTestNetPacketCodec.TestLargestPacketHasTheSizeOfTheOldDoomdata(const AGame: string);
begin
  Assert.AreEqual(StrToInt(Value(AGame, 'sizeof(doomdata_t)')), MakeCodec(AGame).PacketSize(NET_BACKUPTICS));
  Assert.AreEqual(NET_BACKUPTICS, MakeCodec(AGame).MaxTics);
end;

procedure TTestNetPacketCodec.TestFieldOffsetsAreTheOldOnes(const AGame: string);
var
  LPacket: TNetPacket;
  LBytes: TBytes;
  LCodec: INetPacketCodec;
begin
  LCodec := MakeCodec(AGame);
  LPacket := Default(TNetPacket);
  LPacket.RetransmitFrom := $A1;
  LPacket.StartTic := $A2;
  LPacket.Player := $A3;
  LPacket.NumTics := 1;
  LPacket.Flags := $A4A5A6A7;
  SetLength(LPacket.Commands, LCodec.CommandSize);
  LPacket.Commands[0] := $B1;
  LBytes := LCodec.Encode(LPacket, 0);

  Assert.AreEqual(0, StrToInt(Value(AGame, 'off.checksum')));
  Assert.AreEqual(Byte($A1), LBytes[StrToInt(Value(AGame, 'off.retransmitfrom'))], 'retransmitfrom');
  Assert.AreEqual(Byte($A2), LBytes[StrToInt(Value(AGame, 'off.starttic'))], 'starttic');
  Assert.AreEqual(Byte($A3), LBytes[StrToInt(Value(AGame, 'off.player'))], 'player');
  Assert.AreEqual(Byte(1), LBytes[StrToInt(Value(AGame, 'off.numtics'))], 'numtics');
  Assert.AreEqual(Byte($A7), LBytes[StrToInt(Value(AGame, 'off.flags'))], 'flags, byte basso');
  Assert.AreEqual(Byte($A4), LBytes[StrToInt(Value(AGame, 'off.flags')) + 3], 'flags, byte alto');
  Assert.AreEqual(Byte($B1), LBytes[StrToInt(Value(AGame, 'off.cmds'))], 'cmds');
  Assert.AreEqual(NET_PACKET_HEADER_SIZE, StrToInt(Value(AGame, 'off.cmds')));
  Assert.AreEqual(StrToInt(Value(AGame, 'off.cmds[1]')), NET_PACKET_HEADER_SIZE + LCodec.CommandSize);
  // the consistency of a command is a smallint at offset 4 of the command in every game: the
  // net library does not need to know it, the engine does
  Assert.AreEqual(4, StrToInt(Value(AGame, 'off.ticcmd.consistency')));
end;

procedure TTestNetPacketCodec.TestEncodedBytesAreTheOldBytes(const AGame: string);
var
  LCodec: INetPacketCodec;
  LCount: Integer;
  LPacket: TNetPacket;
  LLine: string;
  LExpected: string;
  LBytes: TBytes;
  LText: string;
  LIndex: Integer;
begin
  LCodec := MakeCodec(AGame);
  for LCount in [0, 1, 2, 3, 5, 12] do
  begin
    LLine := Value(AGame, 'packet' + IntToStr(LCount));
    LExpected := Copy(LLine, Pos('bytes=', LLine) + 6, MaxInt);
    LPacket := MakePacket(LCount, LCodec.CommandSize);
    LBytes := LCodec.Encode(LPacket, 0);
    LText := '';
    for LIndex := 0 to High(LBytes) do
      LText := LText + IntToHex(LBytes[LIndex], 2);
    Assert.AreEqual(LExpected, LText, AGame + ' pacchetto di ' + IntToStr(LCount) + ' tic');
  end;
end;

procedure TTestNetPacketCodec.TestChecksumIsTheOldChecksum(const AGame: string);
var
  LCodec: INetPacketCodec;
  LCount: Integer;
  LPacket: TNetPacket;
  LLine: string;
  LExpected: LongWord;
  LBytes: TBytes;
begin
  LCodec := MakeCodec(AGame);
  for LCount in [0, 1, 2, 3, 5, 12] do
  begin
    LLine := Value(AGame, 'packet' + IntToStr(LCount));
    LExpected := LongWord(StrToInt64('$' + Copy(LLine, Pos('checksum=$', LLine) + 10, 8)));
    LPacket := MakePacket(LCount, LCodec.CommandSize);
    LBytes := LCodec.Encode(LPacket, 0);
    Assert.AreEqual(LExpected, LPacket.Checksum, AGame + ' checksum scritto nel pacchetto, ' + IntToStr(LCount) + ' tic');
    Assert.AreEqual(LExpected, TNetPacketCodec.ComputeChecksum(LBytes, Length(LBytes)), AGame + ' ComputeChecksum');
  end;
end;

procedure TTestNetPacketCodec.TestOldBytesAreDecoded(const AGame: string);
var
  LCodec: INetPacketCodec;
  LCount: Integer;
  LLine: string;
  LPacket: TNetPacket;
  LExpected: TNetPacket;
begin
  LCodec := MakeCodec(AGame);
  for LCount in [0, 1, 2, 3, 5, 12] do
  begin
    LLine := Value(AGame, 'packet' + IntToStr(LCount));
    Assert.AreEqual(ndsOk, LCodec.Decode(HexToBytes(Copy(LLine, Pos('bytes=', LLine) + 6, MaxInt)), LPacket));
    LExpected := MakePacket(LCount, LCodec.CommandSize);
    Assert.AreEqual(LExpected.RetransmitFrom, LPacket.RetransmitFrom);
    Assert.AreEqual(LExpected.StartTic, LPacket.StartTic);
    Assert.AreEqual(LExpected.Player, LPacket.Player);
    Assert.AreEqual(LExpected.NumTics, LPacket.NumTics);
    Assert.AreEqual(LExpected.Flags, LPacket.Flags);
    Assert.AreEqual(Length(LExpected.Commands), Length(LPacket.Commands));
    if Length(LExpected.Commands) > 0 then
      Assert.IsTrue(CompareMem(@LExpected.Commands[0], @LPacket.Commands[0], Length(LExpected.Commands)), 'comandi');
  end;
end;

procedure TTestNetPacketCodec.TestStaleBytesAfterTheEndAreZeroHere;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
begin
  // the old code, on a buffer that held 0xFF bytes after the end, summed them: 0F..AB38D1 for a
  // packet of one Doom tic. Here the bytes after the end are zero (see TNetPacketCodec.ComputeChecksum)
  LCodec := MakeCodec('DOOM');
  LPacket := MakePacket(1, LCodec.CommandSize);
  LBytes := LCodec.Encode(LPacket, 0);
  Assert.AreEqual(LongWord($0EAC38D1), LPacket.Checksum);
  Assert.AreEqual(LongWord(StrToInt64('$' + Value('DOOM', 'stale'))), LongWord($0EAB38D1), 'valore del vecchio codice');
  Assert.IsTrue(LongWord(StrToInt64('$' + Value('DOOM', 'stale'))) <> LPacket.Checksum);
end;

procedure TTestNetPacketCodec.TestControlFlagsGoInTheHighBitsOfTheChecksumWord;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
  LPlain: LongWord;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(1, 14);
  LBytes := LCodec.Encode(LPacket, 0);
  LPlain := LPacket.Checksum;
  LBytes := LCodec.Encode(LPacket, NCMD_RETRANSMIT or NCMD_EXIT);
  Assert.AreEqual(LPlain or NCMD_RETRANSMIT or NCMD_EXIT, LPacket.Checksum);
  Assert.AreEqual(Byte(((LPlain shr 24) and $FF) or $C0), LBytes[3], 'byte alto della parola');
  Assert.AreEqual(Byte(LPlain and $FF), LBytes[0], 'byte basso, little endian');
  Assert.IsTrue(LPacket.IsExit);
  Assert.IsTrue(LPacket.IsRetransmit);
  Assert.IsFalse(LPacket.IsSetup);
  Assert.IsFalse(LPacket.IsKill);
end;

procedure TTestNetPacketCodec.TestFlagsAreLittleEndianAtOffsetEight;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(0, 14);
  LPacket.Flags := $01020304;
  LBytes := LCodec.Encode(LPacket, 0);
  Assert.AreEqual(Byte(4), LBytes[8]);
  Assert.AreEqual(Byte(3), LBytes[9]);
  Assert.AreEqual(Byte(2), LBytes[10]);
  Assert.AreEqual(Byte(1), LBytes[11]);
end;

procedure TTestNetPacketCodec.TestRoundTripKeepsEveryField;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LDecoded: TNetPacket;
  LBytes: TBytes;
begin
  LCodec := TNetPacketCodec.Create(19, NET_BACKUPTICS);
  LPacket := MakePacket(7, 19);
  LBytes := LCodec.Encode(LPacket, NCMD_RETRANSMIT);
  Assert.AreEqual(ndsOk, LCodec.Decode(LBytes, LDecoded));
  Assert.AreEqual(LPacket.Checksum, LDecoded.Checksum);
  Assert.AreEqual(LPacket.NumTics, LDecoded.NumTics);
  Assert.AreEqual(LPacket.Flags, LDecoded.Flags);
  Assert.IsTrue(LDecoded.IsRetransmit);
  Assert.AreEqual<Integer>(133, Length(LDecoded.Commands));
  Assert.IsTrue(CompareMem(@LPacket.Commands[0], @LDecoded.Commands[0], 133));
end;

procedure TTestNetPacketCodec.TestShortDatagramIsBadLength;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  Assert.AreEqual(ndsBadLength, LCodec.Decode(nil, LPacket));
  Assert.AreEqual(ndsBadLength, LCodec.Decode(HexToBytes('0102030405060708090A0B'), LPacket));
end;

procedure TTestNetPacketCodec.TestExtraByteIsBadLength;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(2, 14);
  LBytes := LCodec.Encode(LPacket, 0);
  SetLength(LBytes, Length(LBytes) + 1);
  Assert.AreEqual(ndsBadLength, LCodec.Decode(LBytes, LPacket));
  LPacket := MakePacket(2, 14);
  LBytes := LCodec.Encode(LPacket, 0);
  SetLength(LBytes, Length(LBytes) - 1);
  Assert.AreEqual(ndsBadLength, LCodec.Decode(LBytes, LPacket));
end;

procedure TTestNetPacketCodec.TestMoreTicsThanTheMaximumIsBadLength;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(1, 14);
  LBytes := LCodec.Encode(LPacket, 0);
  LBytes[7] := 13;
  SetLength(LBytes, NET_PACKET_HEADER_SIZE + 13 * 14);
  Assert.AreEqual(ndsBadLength, LCodec.Decode(LBytes, LPacket));
end;

procedure TTestNetPacketCodec.TestChangedByteIsBadChecksum;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(3, 14);
  LBytes := LCodec.Encode(LPacket, 0);
  LBytes[20] := LBytes[20] xor $01;
  Assert.AreEqual(ndsBadChecksum, LCodec.Decode(LBytes, LPacket));
end;

procedure TTestNetPacketCodec.TestChangedFlagsAreBadChecksum;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
  LBytes: TBytes;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(3, 14);
  LBytes := LCodec.Encode(LPacket, 0);
  LBytes[9] := LBytes[9] xor $80;
  Assert.AreEqual(ndsBadChecksum, LCodec.Decode(LBytes, LPacket));
end;

procedure TTestNetPacketCodec.TestEncodeRefusesTooManyTics;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(13, 14);
  Assert.WillRaise(
    procedure
    begin
      LCodec.Encode(LPacket, 0);
    end, ENetException);
end;

procedure TTestNetPacketCodec.TestEncodeRefusesCommandsOfTheWrongLength;
var
  LCodec: INetPacketCodec;
  LPacket: TNetPacket;
begin
  LCodec := TNetPacketCodec.Create(14, NET_BACKUPTICS);
  LPacket := MakePacket(2, 14);
  SetLength(LPacket.Commands, 27);
  Assert.WillRaise(
    procedure
    begin
      LCodec.Encode(LPacket, 0);
    end, ENetException);
end;

procedure TTestNetPacketCodec.TestCodecRefusesBadParameters;
begin
  Assert.WillRaise(
    procedure
    begin
      TNetPacketCodec.Create(0, 12);
    end, ENetException);
  Assert.WillRaise(
    procedure
    begin
      TNetPacketCodec.Create(14, 0);
    end, ENetException);
  Assert.WillRaise(
    procedure
    begin
      TNetPacketCodec.Create(14, 256);
    end, ENetException);
end;

procedure TTestNetPacketCodec.TestChecksumIgnoresBytesBeyondTheSize;
var
  LShort: TBytes;
  LLong: TBytes;
begin
  LShort := HexToBytes('000000001122010201020304');
  SetLength(LLong, 32);
  Move(LShort[0], LLong[0], Length(LShort));
  LLong[13] := $FF;
  LLong[27] := $55;
  Assert.AreEqual(TNetPacketCodec.ComputeChecksum(LShort, 12), TNetPacketCodec.ComputeChecksum(LLong, 12));
end;

end.
