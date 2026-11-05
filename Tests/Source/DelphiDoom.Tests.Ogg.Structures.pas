{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the structures, the checksum and the memory of Ogg     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.Structures;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ogg')]
  TTestOggStructures = class(TObject)
  private
    function Crc(const AText: AnsiString; const AStart: Cardinal = 0): Cardinal;
  public
    [Test]
    procedure TestDimensioniDelleStrutture;
    [Test]
    procedure TestPosizioneDeiCampiDelloStato;
    [Test]
    procedure TestCrcDelVuoto;
    [Test]
    procedure TestCrcDiUnaStringaCorta;
    [Test]
    procedure TestCrcDiUnaStringaLunga;
    [Test]
    procedure TestCrcDiOttoByteEOltre;
    [Test]
    procedure TestCrcPuoContinuare;
    [Test]
    procedure TestLaMemoriaEAzzerata;
    [Test]
    procedure TestRiallocaConservaIDati;
    [Test]
    procedure TestRilasciaNilEAmmesso;
  end;

implementation

uses
  DelphiDoom.Ogg.Crc,
  DelphiDoom.Ogg.Memory,
  DelphiDoom.Ogg.Types;

{ TTestOggStructures }

function TTestOggStructures.Crc(const AText: AnsiString; const AStart: Cardinal): Cardinal;
begin
  if AText = '' then
    Exit(AStart);
  Result := TOggCrc.Update(AStart, PByte(PAnsiChar(AText)), Length(AText));
end;

procedure TTestOggStructures.TestDimensioniDelleStrutture;
begin
  // Those of the C structures that the objects of the other libraries use
  Assert.AreEqual(20, SizeOf(TOggPackBuffer));
  Assert.AreEqual(16, SizeOf(TOggPage));
  Assert.AreEqual(8, SizeOf(TOggIoVec));
  Assert.AreEqual(32, SizeOf(TOggPacket));
  Assert.AreEqual(360, SizeOf(TOggStreamState));
  Assert.AreEqual(28, SizeOf(TOggSyncState));
end;

procedure TTestOggStructures.TestPosizioneDeiCampiDelloStato;
var
  LState: TOggStreamState;
  LPacket: TOggPacket;
begin
  Assert.AreEqual(40, Integer(NativeInt(@LState.Header) - NativeInt(@LState)));
  Assert.AreEqual(324, Integer(NativeInt(@LState.HeaderFill) - NativeInt(@LState)));
  Assert.AreEqual(336, Integer(NativeInt(@LState.SerialNumber) - NativeInt(@LState)));
  Assert.AreEqual(344, Integer(NativeInt(@LState.PacketNumber) - NativeInt(@LState)));
  Assert.AreEqual(352, Integer(NativeInt(@LState.GranulePosition) - NativeInt(@LState)));
  Assert.AreEqual(16, Integer(NativeInt(@LPacket.GranulePosition) - NativeInt(@LPacket)));
end;

procedure TTestOggStructures.TestCrcDelVuoto;
begin
  Assert.AreEqual(Int64(0), Int64(Crc('')));
end;

procedure TTestOggStructures.TestCrcDiUnaStringaCorta;
begin
  // Computed with a plain bit by bit CRC: polynomial 04C11DB7, not reflected, start and end at zero
  Assert.AreEqual(Int64($2C17398C), Int64(Crc('abc')));
end;

procedure TTestOggStructures.TestCrcDiUnaStringaLunga;
begin
  Assert.AreEqual(Int64($89A1897F), Int64(Crc('123456789')));
  Assert.AreEqual(Int64($C9487F7E), Int64(Crc('The quick brown fox jumps over the lazy dog')));
end;

procedure TTestOggStructures.TestCrcDiOttoByteEOltre;
var
  LBytes: array[0..31] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 31 do
    LBytes[LIndex] := LIndex;

  Assert.AreEqual(Int64($C5D43637), Int64(TOggCrc.Update(0, @LBytes[0], 32)));
end;

procedure TTestOggStructures.TestCrcPuoContinuare;
var
  LBytes: array[0..39] of Byte;
  LIndex: Integer;
  LFirst: Cardinal;
begin
  for LIndex := 0 to 39 do
    LBytes[LIndex] := LIndex;

  LFirst := TOggCrc.Update(0, @LBytes[0], 20);

  Assert.AreEqual(Int64($D9D74F3A), Int64(TOggCrc.Update(LFirst, @LBytes[20], 20)));
  Assert.AreEqual(Int64($D9D74F3A), Int64(TOggCrc.Update(0, @LBytes[0], 40)));
end;

procedure TTestOggStructures.TestLaMemoriaEAzzerata;
var
  LBlock: PByteArray;
  LIndex: Integer;
begin
  LBlock := TOggMemory.Allocate(1000);
  try
    for LIndex := 0 to 999 do
      Assert.AreEqual(0, Integer(LBlock[LIndex]));
  finally
    TOggMemory.Release(LBlock);
  end;
end;

procedure TTestOggStructures.TestRiallocaConservaIDati;
var
  LBlock: PByteArray;
  LIndex: Integer;
begin
  LBlock := TOggMemory.Allocate(10);
  for LIndex := 0 to 9 do
    LBlock[LIndex] := LIndex + 1;

  LBlock := TOggMemory.Reallocate(LBlock, 5000);
  try
    for LIndex := 0 to 9 do
      Assert.AreEqual(LIndex + 1, Integer(LBlock[LIndex]));
  finally
    TOggMemory.Release(LBlock);
  end;
end;

procedure TTestOggStructures.TestRilasciaNilEAmmesso;
begin
  TOggMemory.Release(nil);
  Assert.Pass('Release(nil) does nothing');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOggStructures);

end.
