{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TOggStream - the cases at the edges of libogg          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.Stream;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Ogg.Types;

type
  [TestFixture]
  [Category('ogg')]
  TTestOggStream = class(TObject)
  private
    FEncoder: TOggStreamState;
    FDecoder: TOggStreamState;
    FPages: TArray<TBytes>;
    procedure AddPacket(ASize: Integer; AFirstByte: Byte; AEnd: Boolean);
    procedure FlushPages;
    function PageOf(AIndex: Integer; out AStorage: TBytes): TOggPage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnoStatoNil;
    [Test]
    procedure DovrebbeLiberareUnoStatoAllocato;
    [Test]
    procedure DovrebbeRifiutareVettoriTroppoLunghi;
    [Test]
    procedure DovrebbeChiudereLaPaginaConUnRiempimentoDato;
    [Test]
    procedure DovrebbeTenereIPacchettiNonLettiTraDuePagine;
    [Test]
    procedure DovrebbeRifiutareUnaPaginaDiUnAltroFlussoODiUnAltraVersione;
    [Test]
    procedure DovrebbePerdereIlPacchettoInterrottoDaUnBuco;
    [Test]
    procedure DovrebbeSaltareIlSeguitoDiUnPacchettoMaiIniziato;
    [Test]
    procedure DovrebbeRifiutareIlCambioDiSerieSuUnoStatoVuoto;
    [Test]
    procedure DovrebbeLiberareIlPacchetto;
  end;

implementation

uses
  DelphiDoom.Ogg.Memory, DelphiDoom.Ogg.Stream;

const
  SERIAL = 1234;

{ TTestOggStream }

procedure TTestOggStream.Setup;
begin
  TOggStream.Init(@FEncoder, SERIAL);
  TOggStream.Init(@FDecoder, SERIAL);
  FPages := nil;
end;

procedure TTestOggStream.TearDown;
begin
  TOggStream.Clear(@FEncoder);
  TOggStream.Clear(@FDecoder);
end;

procedure TTestOggStream.AddPacket(ASize: Integer; AFirstByte: Byte; AEnd: Boolean);
var
  LData: TBytes;
  LPacket: TOggPacket;
  LIndex: Integer;
begin
  SetLength(LData, ASize);
  for LIndex := 0 to ASize - 1 do
    LData[LIndex] := Byte(AFirstByte + LIndex);
  FillChar(LPacket, SizeOf(LPacket), 0);
  LPacket.Packet := @LData[0];
  LPacket.Bytes := ASize;
  LPacket.EndOfStream := Ord(AEnd);
  LPacket.GranulePosition := ASize;
  Assert.AreEqual(0, TOggStream.PacketIn(@FEncoder, @LPacket));
end;

procedure TTestOggStream.FlushPages;
var
  LPage: TOggPage;
  LBytes: TBytes;
begin
  while TOggStream.Flush(@FEncoder, @LPage) <> 0 do
  begin
    SetLength(LBytes, LPage.HeaderLength + LPage.BodyLength);
    Move(LPage.Header^, LBytes[0], LPage.HeaderLength);
    Move(LPage.Body^, LBytes[LPage.HeaderLength], LPage.BodyLength);
    FPages := FPages + [LBytes];
  end;
end;

function TTestOggStream.PageOf(AIndex: Integer; out AStorage: TBytes): TOggPage;
begin
  // A copy: the decoder must not depend on the buffer of the encoder
  AStorage := Copy(FPages[AIndex]);
  Result.Header := @AStorage[0];
  Result.HeaderLength := 27 + AStorage[26];
  Result.Body := @AStorage[Result.HeaderLength];
  Result.BodyLength := Length(AStorage) - Result.HeaderLength;
end;

procedure TTestOggStream.DovrebbeRifiutareUnoStatoNil;
begin
  Assert.AreEqual(-1, TOggStream.Init(nil, SERIAL));
end;

procedure TTestOggStream.DovrebbeLiberareUnoStatoAllocato;
var
  LState: POggStreamState;
begin
  LState := TOggMemory.Allocate(SizeOf(TOggStreamState));
  Assert.AreEqual(0, TOggStream.Init(LState, SERIAL));
  Assert.AreEqual(0, TOggStream.ClearAndFree(LState));
  Assert.AreEqual(0, TOggStream.ClearAndFree(nil));
end;

procedure TTestOggStream.DovrebbeRifiutareVettoriTroppoLunghi;
var
  LEmpty: TOggStreamState;
  LVectors: array[0..1] of TOggIoVec;
  LByte: Byte;
begin
  FillChar(LEmpty, SizeOf(LEmpty), 0);
  LByte := 0;
  LVectors[0].Base := @LByte;
  LVectors[0].Length := 1;
  LVectors[1] := LVectors[0];
  Assert.AreEqual(-1, TOggStream.IoVecIn(@LEmpty, @LVectors[0], 1, 0, 0));
  Assert.AreEqual(0, TOggStream.IoVecIn(@FEncoder, nil, 1, 0, 0));

  // More than the largest long, alone or added up
  LVectors[0].Length := $80000000;
  Assert.AreEqual(-1, TOggStream.IoVecIn(@FEncoder, @LVectors[0], 1, 0, 0));
  LVectors[0].Length := $7FFFFFF0;
  LVectors[1].Length := $7FFFFFF0;
  Assert.AreEqual(-1, TOggStream.IoVecIn(@FEncoder, @LVectors[0], 2, 0, 0));
end;

procedure TTestOggStream.DovrebbeChiudereLaPaginaConUnRiempimentoDato;
var
  LPage: TOggPage;
begin
  AddPacket(100, 1, False);
  Assert.AreEqual(1, TOggStream.FlushFill(@FEncoder, @LPage, 50));
  Assert.AreEqual(100, Integer(LPage.BodyLength));
  Assert.AreEqual(0, TOggStream.FlushFill(@FEncoder, @LPage, 50));
end;

procedure TTestOggStream.DovrebbeTenereIPacchettiNonLettiTraDuePagine;
var
  LPage: TOggPage;
  LPacket: TOggPacket;
  LHeader, LFirst, LSecond: TBytes;
begin
  // The first page holds the first packet alone
  AddPacket(5, 0, False);
  AddPacket(10, 1, False);
  AddPacket(20, 2, False);
  AddPacket(30, 3, False);
  FlushPages;
  AddPacket(40, 4, True);
  FlushPages;
  Assert.AreEqual<Integer>(3, Length(FPages));

  LPage := PageOf(0, LHeader);
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(5, Integer(LPacket.Bytes));
  LPage := PageOf(1, LFirst);
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(10, Integer(LPacket.Bytes));

  // The packet that was given is dropped, the two that were not are kept
  LPage := PageOf(2, LSecond);
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(20, Integer(LPacket.Bytes));
  Assert.AreEqual(2, Integer(LPacket.Packet^));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(30, Integer(LPacket.Bytes));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(40, Integer(LPacket.Bytes));
  // libogg gives the flag of the lacing value (), not 1
  Assert.AreNotEqual(0, Integer(LPacket.EndOfStream));
  Assert.AreEqual(0, TOggStream.PacketOut(@FDecoder, @LPacket));
end;

procedure TTestOggStream.DovrebbeRifiutareUnaPaginaDiUnAltroFlussoODiUnAltraVersione;
var
  LPage: TOggPage;
  LBytes: TBytes;
  LOther: TOggStreamState;
begin
  AddPacket(10, 1, False);
  FlushPages;

  TOggStream.Init(@LOther, SERIAL + 1);
  try
    LPage := PageOf(0, LBytes);
    Assert.AreEqual(-1, TOggStream.PageIn(@LOther, @LPage));
  finally
    TOggStream.Clear(@LOther);
  end;

  // Byte 4 of the header is the version of the format, which is always 0
  LPage := PageOf(0, LBytes);
  LBytes[4] := 1;
  Assert.AreEqual(-1, TOggStream.PageIn(@FDecoder, @LPage));
end;

procedure TTestOggStream.DovrebbePerdereIlPacchettoInterrottoDaUnBuco;
var
  LPage: TOggPage;
  LPacket: TOggPacket;
  LFirst, LThird: TBytes;
begin
  // A packet longer than the 255 segments of a page, then a short one
  AddPacket(70000, 1, False);
  FlushPages;
  AddPacket(10, 9, True);
  FlushPages;
  Assert.AreEqual<Integer>(3, Length(FPages));

  LPage := PageOf(0, LFirst);
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(0, TOggStream.PacketOut(@FDecoder, @LPacket));

  // The second page is lost: the beginning of the long packet goes with it
  LPage := PageOf(2, LThird);
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(-1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(10, Integer(LPacket.Bytes));
  Assert.AreEqual(9, Integer(LPacket.Packet^));
end;

procedure TTestOggStream.DovrebbeSaltareIlSeguitoDiUnPacchettoMaiIniziato;
var
  LPage: TOggPage;
  LPacket: TOggPacket;
  LSecond, LThird: TBytes;
begin
  AddPacket(70000, 1, False);
  FlushPages;
  AddPacket(10, 9, True);
  FlushPages;

  // The first page that is seen continues a packet: a new state waits for page 0,
  // so the hole is told, and the segments of the packet that never began are skipped
  LPage := PageOf(1, LSecond);
  Assert.AreEqual(1, Integer(LSecond[5] and 1));
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(-1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(0, TOggStream.PacketOut(@FDecoder, @LPacket));

  LPage := PageOf(2, LThird);
  Assert.AreEqual(0, TOggStream.PageIn(@FDecoder, @LPage));
  Assert.AreEqual(1, TOggStream.PacketOut(@FDecoder, @LPacket));
  Assert.AreEqual(10, Integer(LPacket.Bytes));
end;

procedure TTestOggStream.DovrebbeRifiutareIlCambioDiSerieSuUnoStatoVuoto;
var
  LEmpty: TOggStreamState;
begin
  FillChar(LEmpty, SizeOf(LEmpty), 0);
  Assert.AreEqual(-1, TOggStream.ResetSerialNumber(@LEmpty, SERIAL));
  Assert.AreEqual(0, TOggStream.ResetSerialNumber(@FDecoder, SERIAL + 5));
  Assert.AreEqual(SERIAL + 5, Integer(FDecoder.SerialNumber));
end;

procedure TTestOggStream.DovrebbeLiberareIlPacchetto;
var
  LPacket: TOggPacket;
begin
  FillChar(LPacket, SizeOf(LPacket), 0);
  LPacket.Packet := TOggMemory.Allocate(10);
  LPacket.Bytes := 10;
  LPacket.GranulePosition := 77;
  TOggStream.ClearPacket(@LPacket);
  Assert.IsNull(LPacket.Packet);
  Assert.AreEqual(0, Integer(LPacket.Bytes));
  Assert.AreEqual(Int64(0), LPacket.GranulePosition);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOggStream);

end.
