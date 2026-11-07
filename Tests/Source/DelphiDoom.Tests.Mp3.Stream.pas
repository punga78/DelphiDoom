{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mp3 library - the stream fed by the caller          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Stream;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mp3.Stream;

type
  [TestFixture]
  [Category('mp3')]
  TTestMp3FeedStream = class(TObject)
  private
    FStream: TMp3FeedStream;
    procedure AppendCounting(AFirst, ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeLeggereInOrdine;
    [Test]
    procedure DovrebbeLeggereSoloCioCheCe;
    [Test]
    procedure DovrebbeRifiutareLaScrittura;
    [Test]
    procedure DovrebbeSaltareAlPiuCioCheCe;
    [Test]
    procedure DovrebbeSpostarsiDallaPosizioneEDallaFine;
    [Test]
    procedure DovrebbeIgnorareIlRitornoAllInizio;
    [Test]
    procedure DovrebbeSpostarsiAUnaPosizioneAssoluta;
    [Test]
    procedure DovrebbeTenereIByteDaLeggereQuandoCresce;
    [Test]
    procedure DovrebbeIgnorareUnBloccoVuoto;
  end;

implementation

uses
  d_delphi;

{ TTestMp3FeedStream }

procedure TTestMp3FeedStream.Setup;
begin
  FStream := TMp3FeedStream.Create;
end;

procedure TTestMp3FeedStream.TearDown;
begin
  FreeAndNil(FStream);
end;

procedure TTestMp3FeedStream.AppendCounting(AFirst, ACount: Integer);
var
  LData: TBytes;
  LIndex: Integer;
begin
  SetLength(LData, ACount);
  for LIndex := 0 to ACount - 1 do
    LData[LIndex] := Byte(AFirst + LIndex);
  FStream.Append(@LData[0], ACount);
end;

procedure TTestMp3FeedStream.DovrebbeEssereVuotoAllInizio;
begin
  Assert.IsTrue(FStream.Peek = nil);
  Assert.AreEqual(0, FStream.Available);
  Assert.AreEqual(0, FStream.Size);
  Assert.AreEqual(0, FStream.Position);
end;

procedure TTestMp3FeedStream.DovrebbeLeggereInOrdine;
var
  LBuffer: array[0..3] of Byte;
begin
  AppendCounting(10, 6);
  Assert.AreEqual(4, FStream.Read(LBuffer, 4));
  Assert.AreEqual(10, Integer(LBuffer[0]));
  Assert.AreEqual(13, Integer(LBuffer[3]));
  Assert.AreEqual(14, Integer(FStream.Peek^));
  Assert.AreEqual(2, FStream.Available);
  Assert.AreEqual(4, FStream.Position);
  Assert.AreEqual(6, FStream.Size);
end;

procedure TTestMp3FeedStream.DovrebbeLeggereSoloCioCheCe;
var
  LBuffer: array[0..9] of Byte;
begin
  AppendCounting(0, 3);
  Assert.AreEqual(3, FStream.Read(LBuffer, 10));
  Assert.AreEqual(0, FStream.Read(LBuffer, 10));
  Assert.AreEqual(0, FStream.Read(LBuffer, -1));
end;

procedure TTestMp3FeedStream.DovrebbeRifiutareLaScrittura;
var
  LByte: Byte;
begin
  LByte := 1;
  Assert.AreEqual(0, FStream.Write(LByte, 1));
  Assert.AreEqual(1, FStream.IOResult);
  // IOResult is cleared once read
  Assert.AreEqual(0, FStream.IOResult);
end;

procedure TTestMp3FeedStream.DovrebbeSaltareAlPiuCioCheCe;
begin
  AppendCounting(0, 5);
  FStream.Skip(2);
  Assert.AreEqual(3, FStream.Available);
  FStream.Skip(100);
  Assert.AreEqual(0, FStream.Available);
  FStream.Skip(-3);
  Assert.AreEqual(5, FStream.Position);
end;

procedure TTestMp3FeedStream.DovrebbeSpostarsiDallaPosizioneEDallaFine;
begin
  AppendCounting(0, 10);
  Assert.AreEqual(4, FStream.Seek(4, sFromCurrent));
  Assert.AreEqual(2, FStream.Seek(-2, sFromCurrent));
  Assert.AreEqual(7, FStream.Seek(3, sFromEnd));
  // outside the bytes: kept at the ends
  Assert.AreEqual(0, FStream.Seek(-50, sFromCurrent));
  Assert.AreEqual(10, FStream.Seek(-50, sFromEnd));
end;

procedure TTestMp3FeedStream.DovrebbeIgnorareIlRitornoAllInizio;
begin
  AppendCounting(0, 10);
  FStream.Skip(6);
  // the Restart of the bit stream: there is no history to go back to
  Assert.AreEqual(6, FStream.Seek(0, sFromBeginning));
end;

procedure TTestMp3FeedStream.DovrebbeSpostarsiAUnaPosizioneAssoluta;
begin
  AppendCounting(0, 10);
  Assert.AreEqual(3, FStream.Seek(3, sFromBeginning));
  Assert.AreEqual(3, Integer(FStream.Peek^));
end;

procedure TTestMp3FeedStream.DovrebbeTenereIByteDaLeggereQuandoCresce;
var
  LBuffer: TBytes;
  LValue: Byte;
begin
  // more than the first capacity (16 KB): the bytes already read are dropped, except the
  // last three, and the position counts from the start of the stream
  AppendCounting(0, 10000);
  SetLength(LBuffer, 9000);
  FStream.Read(LBuffer[0], 9000);
  AppendCounting(0, 10000);
  Assert.AreEqual(9000, FStream.Position);
  Assert.AreEqual(20000, FStream.Size);
  Assert.AreEqual(11000, FStream.Available);
  FStream.Read(LValue, 1);
  Assert.AreEqual(Byte(9000 and $FF), LValue);
  // the three bytes kept before the position can still be reached
  Assert.AreEqual(8998, FStream.Seek(-3, sFromCurrent));
  // and also with an absolute position
  Assert.AreEqual(9999, FStream.Seek(9999, sFromBeginning));
  // a block that does not fit even after dropping: the buffer grows
  AppendCounting(0, 40000);
  Assert.AreEqual(60000, FStream.Size);
end;

procedure TTestMp3FeedStream.DovrebbeIgnorareUnBloccoVuoto;
begin
  FStream.Append(nil, 0);
  FStream.Append(nil, -4);
  Assert.AreEqual(0, FStream.Size);
end;

end.
