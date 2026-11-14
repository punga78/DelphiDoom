{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer library - the raw records being written }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.DiskRecordWriter;

interface

{$ALIGN 8}

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Serializer.Types, DelphiDoom.Serializer.Intf;

type
  // like a thinker of a sector: 12 bytes for the 32 bit compiler, 24 for the other one
  TTestWriterThinker = record
    Sector: Pointer;
    Speed: Integer;
    Line: Pointer;
  end;
  PTestWriterThinker = ^TTestWriterThinker;

  [TestFixture]
  [Category('serializer')]
  TTestSerializerDiskRecordWriter = class(TObject)
  private
    FLayout: IDiskLayout;
    FWriter: IDiskRecordWriter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareUnaCopiaESpostareIlPostoDellaDimensioneSuDisco;
    [Test]
    procedure DovrebbeNonToccareIlBufferPrimaDiCommit;
    [Test]
    procedure DovrebbeScrivereLaCopiaCambiataENonLOriginale;
    [Test]
    procedure DovrebbeScriverePiuRecordOgnunoAlSuoPosto;
    [Test]
    procedure DovrebbeNonScrivereDueVolteConDueCommit;
    [Test]
    procedure DovrebbeDareEccezioneSenzaLayout;
  end;

implementation

uses
  DelphiDoom.Serializer.Factory;

const
  THINKER_DISK_SIZE = 12;

{ TTestSerializerDiskRecordWriter }

procedure TTestSerializerDiskRecordWriter.Setup;
begin
  FLayout := TSerializerFactory.CreateDiskLayouts.LayoutOf(TypeInfo(TTestWriterThinker));
  FWriter := TSerializerFactory.CreateDiskRecordWriter;
end;

procedure TTestSerializerDiskRecordWriter.TearDown;
begin
  FWriter := nil;
  FLayout := nil;
end;

procedure TTestSerializerDiskRecordWriter.DovrebbeDareUnaCopiaESpostareIlPostoDellaDimensioneSuDisco;
var
  LSource: TTestWriterThinker;
  LBuffer: array[0..63] of Byte;
  LPlace: Pointer;
  LCopy: PTestWriterThinker;
begin
  LSource.Sector := Pointer(NativeInt(5));
  LSource.Speed := 77;
  LSource.Line := nil;
  LPlace := @LBuffer[0];
  LCopy := FWriter.Reserve(FLayout, @LSource, LPlace);
  Assert.AreNotEqual<Pointer>(@LSource, LCopy);
  Assert.AreEqual<Integer>(77, LCopy.Speed);
  Assert.AreEqual<NativeInt>(THINKER_DISK_SIZE, NativeInt(LPlace) - NativeInt(@LBuffer[0]));
  FWriter.Commit;
end;

procedure TTestSerializerDiskRecordWriter.DovrebbeNonToccareIlBufferPrimaDiCommit;
var
  LSource: TTestWriterThinker;
  LBuffer: array[0..15] of Byte;
  LPlace: Pointer;
begin
  FillChar(LSource, SizeOf(LSource), 1);
  FillChar(LBuffer, SizeOf(LBuffer), $EE);
  LPlace := @LBuffer[0];
  FWriter.Reserve(FLayout, @LSource, LPlace);
  Assert.AreEqual<Integer>($EE, LBuffer[0]);
  Assert.AreEqual<Integer>($EE, LBuffer[THINKER_DISK_SIZE - 1]);
  FWriter.Commit;
  Assert.AreEqual<Integer>(1, LBuffer[4]);
  Assert.AreEqual<Integer>($EE, LBuffer[THINKER_DISK_SIZE]);
end;

procedure TTestSerializerDiskRecordWriter.DovrebbeScrivereLaCopiaCambiataENonLOriginale;
var
  LSource: TTestWriterThinker;
  LBuffer: array[0..15] of Byte;
  LPlace: Pointer;
  LCopy: PTestWriterThinker;
begin
  // as the engine does: the pointer of the copy becomes the index of the sector, the thinker stays as it is
  LSource.Sector := @LSource;
  LSource.Speed := 3;
  LSource.Line := @LBuffer;
  LPlace := @LBuffer[0];
  LCopy := FWriter.Reserve(FLayout, @LSource, LPlace);
  LCopy.Sector := Pointer(NativeInt(42));
  LCopy.Line := Pointer(NativeInt(-1));
  FWriter.Commit;
  Assert.AreEqual<Integer>(42, PInteger(@LBuffer[0])^);
  Assert.AreEqual<Integer>(3, PInteger(@LBuffer[4])^);
  Assert.AreEqual<Integer>(-1, PInteger(@LBuffer[8])^);
  Assert.AreEqual<Pointer>(@LSource, LSource.Sector);
end;

procedure TTestSerializerDiskRecordWriter.DovrebbeScriverePiuRecordOgnunoAlSuoPosto;
var
  LSource: TTestWriterThinker;
  LBuffer: array[0..63] of Byte;
  LPlace: Pointer;
  LIndex: Integer;
  LCopy: PTestWriterThinker;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LPlace := @LBuffer[0];
  for LIndex := 0 to 2 do
  begin
    LSource.Sector := nil;
    LSource.Speed := 100 + LIndex;
    LSource.Line := nil;
    LCopy := FWriter.Reserve(FLayout, @LSource, LPlace);
    LCopy.Sector := Pointer(NativeInt(LIndex + 1));
    // a byte between two records, as the class of the thinker in a saved game
    PByte(LPlace)^ := $AA;
    LPlace := PByte(LPlace) + 1;
  end;
  FWriter.Commit;
  for LIndex := 0 to 2 do
  begin
    Assert.AreEqual<Integer>(LIndex + 1, PInteger(@LBuffer[LIndex * (THINKER_DISK_SIZE + 1)])^);
    Assert.AreEqual<Integer>(100 + LIndex, PInteger(@LBuffer[LIndex * (THINKER_DISK_SIZE + 1) + 4])^);
    Assert.AreEqual<Integer>($AA, LBuffer[LIndex * (THINKER_DISK_SIZE + 1) + THINKER_DISK_SIZE]);
  end;
end;

procedure TTestSerializerDiskRecordWriter.DovrebbeNonScrivereDueVolteConDueCommit;
var
  LSource: TTestWriterThinker;
  LBuffer: array[0..15] of Byte;
  LPlace: Pointer;
begin
  FillChar(LSource, SizeOf(LSource), 2);
  LPlace := @LBuffer[0];
  FWriter.Reserve(FLayout, @LSource, LPlace);
  FWriter.Commit;
  // the buffer is then written to the file and used again: a second Commit must leave it alone
  FillChar(LBuffer, SizeOf(LBuffer), $55);
  FWriter.Commit;
  Assert.AreEqual<Integer>($55, LBuffer[0]);
end;

procedure TTestSerializerDiskRecordWriter.DovrebbeDareEccezioneSenzaLayout;
var
  LSource: TTestWriterThinker;
  LPlace: Pointer;
begin
  LPlace := @LSource;
  Assert.WillRaise(
    procedure
    begin
      FWriter.Reserve(nil, @LSource, LPlace);
    end,
    EArgumentNilException);
end;

end.
