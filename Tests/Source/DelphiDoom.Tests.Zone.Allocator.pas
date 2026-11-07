{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the zone library - the allocator                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zone.Allocator;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zone.Intf, DelphiDoom.Zone.Types,
  DelphiDoom.Tests.Zone.FakeMemory;

type
  [TestFixture]
  [Category('zone')]
  TTestZoneAllocator = class(TObject)
  private
    FMemory: TFakeZoneMemory;
    FMemoryIntf: IZoneMemory;
    FAllocator: IZoneAllocator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareUnBloccoDellaDimensioneChiesta;
    [Test]
    procedure DovrebbeAccettareUnBloccoDiZeroByte;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNegativa;
    [Test]
    procedure DovrebbeScrivereIlPuntatoreUtenteEAzzerarloConLaFree;
    [Test]
    procedure DovrebbeAccettareUnBloccoSenzaPuntatoreUtente;
    [Test]
    procedure DovrebbeRifiutareLaFreeDiNil;
    [Test]
    procedure DovrebbeRifiutareUnDoppioFree;
    [Test]
    procedure DovrebbeRifiutareUnPuntatoreCheNonEDellaZona;
    [Test]
    procedure DovrebbeRifiutareLaDimensioneDiUnBloccoGiaLiberato;
    [Test]
    procedure DovrebbeRestituireLaMemoriaConLaDimensioneGiusta;
    [Test]
    procedure DovrebbeLiberareTuttoQuandoLAllocatoreMuore;
    [Test]
    procedure DovrebbeTenereValideLeAltreTraccePiuDiCentoBlocchiLiberatiInOrdineSparso;
    [Test]
    procedure DovrebbeRestareConsistenteSeLaMemoriaFinisce;
    [Test]
    procedure DovrebbeRifiutareUnaMemoriaNil;
    [Test]
    procedure ReallocDiNilDovrebbeAllocare;
    [Test]
    procedure ReallocConDimensioneZeroDovrebbeLiberare;
    [Test]
    procedure ReallocConLaStessaDimensioneDovrebbeDareLoStessoBlocco;
    [Test]
    procedure ReallocDovrebbeTenereIByteCheCiStanno;
    [Test]
    procedure ReallocDovrebbeAggiornareLoStessoPuntatoreUtente;
    [Test]
    procedure ReallocSenzaUtenteDovrebbeAzzerareIlVecchioUtente;
    [Test]
    procedure ReallocDiUnPuntatoreEstraneoDovrebbeDareErrore;
    [Test]
    procedure ChangeTagDovrebbeCambiareIlDestinoDelBlocco;
    [Test]
    procedure FreeTagsDovrebbeLiberareLIntervalloIncluseLeEstremita;
    [Test]
    procedure FreeTagsDovrebbeAzzerareIPuntatoriUtente;
    [Test]
    procedure FreeTagsDovrebbeDareZeroSeNienteCorrisponde;
    [Test]
    procedure FreeTagsDovrebbeLasciareIntattiIBlocchiFuoriIntervallo;
    [Test]
    procedure MoveUsersDovrebbeSpostareISoliPuntatoriDentroLIntervallo;
    [Test]
    procedure MoveUsersDovrebbeSeguireUnaTabellaCheCambiaIndirizzo;
    [Test]
    procedure CheckHeapDovrebbeAccettareUnaZonaSana;
    [Test]
    procedure CheckHeapDovrebbeAccettareUnaZonaVuota;
    [Test]
    procedure CheckHeapDovrebbeTrovareUnaIntestazioneDanneggiata;
    [Test]
    procedure CheckHeapDovrebbeTrovareUnaDimensioneNegativa;
    [Test]
    procedure CheckUsersDovrebbeAccettareIndirizziENil;
    [Test]
    procedure CheckUsersDovrebbeTrovareUnNumeroPiccolo;
    [Test]
    procedure StatisticsDovrebbeContareBlocchiEByte;
    [Test]
    procedure StatisticsDovrebbeContareLaCacheComeRecuperabile;
    [Test]
    procedure DescribeDovrebbeDareUnaRigaPerOgniBloccoNellIntervallo;
    [Test]
    procedure LIntestazioneDovrebbeAvereLaDimensioneAttesa;
    [Test]
    procedure LaMemoriaDelloHeapDovrebbeDareEPrendereByte;
  end;

implementation

uses
  DelphiDoom.Zone.Allocator, DelphiDoom.Zone.Factory, DelphiDoom.Zone.HeapMemory;

{ TTestZoneAllocator }

procedure TTestZoneAllocator.Setup;
begin
  FMemory := TFakeZoneMemory.Create;
  FMemoryIntf := FMemory;
  FAllocator := TZoneFactory.CreateAllocator(FMemoryIntf);
end;

procedure TTestZoneAllocator.TearDown;
begin
  FAllocator := nil;
  Assert.AreEqual(0, FMemory.BadReleases);
  FMemoryIntf := nil;
end;

procedure TTestZoneAllocator.DovrebbeDareUnBloccoDellaDimensioneChiesta;
var
  LBlock: PByte;
begin
  LBlock := FAllocator.Allocate(100, ZONE_TAG_STATIC, nil);
  Assert.IsNotNull(LBlock);
  Assert.AreEqual(100, FAllocator.BlockSize(LBlock));
  // the whole block can be written
  FillChar(LBlock^, 100, $AB);
  Assert.AreEqual(1, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.DovrebbeAccettareUnBloccoDiZeroByte;
var
  LBlock: Pointer;
begin
  LBlock := FAllocator.Allocate(0, ZONE_TAG_LEVEL, nil);
  Assert.IsNotNull(LBlock);
  Assert.AreEqual(0, FAllocator.BlockSize(LBlock));
  FAllocator.FreeBlock(LBlock);
  Assert.AreEqual(0, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.DovrebbeRifiutareUnaDimensioneNegativa;
begin
  Assert.WillRaise(
    procedure
    begin
      FAllocator.Allocate(-1, ZONE_TAG_STATIC, nil);
    end, EZoneException);
  Assert.AreEqual(0, FMemory.AllocateCalls);
end;

procedure TTestZoneAllocator.DovrebbeScrivereIlPuntatoreUtenteEAzzerarloConLaFree;
var
  LUser: Pointer;
  LBlock: Pointer;
begin
  LUser := nil;
  LBlock := FAllocator.Allocate(16, ZONE_TAG_CACHE, @LUser);
  Assert.IsTrue(LUser = LBlock);
  FAllocator.FreeBlock(LBlock);
  Assert.IsNull(LUser);
end;

procedure TTestZoneAllocator.DovrebbeAccettareUnBloccoSenzaPuntatoreUtente;
var
  LBlock: Pointer;
begin
  LBlock := FAllocator.Allocate(16, ZONE_TAG_STATIC, nil);
  FAllocator.FreeBlock(LBlock);
  Assert.AreEqual(0, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.DovrebbeRifiutareLaFreeDiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FAllocator.FreeBlock(nil);
    end, EZoneException);
end;

procedure TTestZoneAllocator.DovrebbeRifiutareUnDoppioFree;
var
  LBlock: Pointer;
  LOther: Pointer;
begin
  LBlock := FAllocator.Allocate(32, ZONE_TAG_STATIC, nil);
  LOther := FAllocator.Allocate(32, ZONE_TAG_STATIC, nil);
  FAllocator.FreeBlock(LBlock);
  Assert.WillRaise(
    procedure
    begin
      FAllocator.FreeBlock(LBlock);
    end, EZoneException);
  // the other block was not touched
  Assert.AreEqual(1, FAllocator.Statistics.BlockCount);
  Assert.AreEqual(32, FAllocator.BlockSize(LOther));
end;

procedure TTestZoneAllocator.DovrebbeRifiutareUnPuntatoreCheNonEDellaZona;
var
  LBuffer: array[0..127] of Byte;
  LForeign: Pointer;
begin
  FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LForeign := @LBuffer[64];
  Assert.WillRaise(
    procedure
    begin
      FAllocator.FreeBlock(LForeign);
    end, EZoneException);
  Assert.WillRaise(
    procedure
    begin
      FAllocator.BlockSize(LForeign);
    end, EZoneException);
  Assert.WillRaise(
    procedure
    begin
      FAllocator.ChangeTag(LForeign, ZONE_TAG_LEVEL);
    end, EZoneException);
end;

procedure TTestZoneAllocator.DovrebbeRifiutareLaDimensioneDiUnBloccoGiaLiberato;
var
  LBlock: Pointer;
begin
  LBlock := FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  FAllocator.FreeBlock(LBlock);
  Assert.WillRaise(
    procedure
    begin
      FAllocator.BlockSize(LBlock);
    end, EZoneException);
end;

procedure TTestZoneAllocator.DovrebbeRestituireLaMemoriaConLaDimensioneGiusta;
var
  LBlock: Pointer;
begin
  LBlock := FAllocator.Allocate(40, ZONE_TAG_STATIC, nil);
  Assert.AreEqual(Int64(40 + SizeOf(TZoneBlock)), FMemory.LiveBytes);
  FAllocator.FreeBlock(LBlock);
  Assert.AreEqual(Int64(0), FMemory.LiveBytes);
  Assert.AreEqual(0, FMemory.BadReleases);
end;

procedure TTestZoneAllocator.DovrebbeLiberareTuttoQuandoLAllocatoreMuore;
var
  LUser: Pointer;
begin
  FAllocator.Allocate(10, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(20, ZONE_TAG_CACHE, nil);
  FAllocator.Allocate(30, ZONE_TAG_LEVEL, nil);
  Assert.AreEqual(3, FMemory.LiveBlocks);
  LUser := nil;
  FAllocator.Allocate(5, ZONE_TAG_CACHE, @LUser);
  FAllocator := nil;
  Assert.AreEqual(0, FMemory.LiveBlocks);
  Assert.AreEqual(0, FMemory.BadReleases);
end;

procedure TTestZoneAllocator.DovrebbeTenereValideLeAltreTraccePiuDiCentoBlocchiLiberatiInOrdineSparso;
var
  LBlocks: array[0..299] of PByte;
  LIndex: Integer;
begin
  for LIndex := 0 to High(LBlocks) do
  begin
    LBlocks[LIndex] := FAllocator.Allocate(LIndex + 1, ZONE_TAG_STATIC, nil);
    FillChar(LBlocks[LIndex]^, LIndex + 1, Byte(LIndex));
  end;
  // the table grew more than once
  Assert.AreEqual(300, FAllocator.Statistics.BlockCount);
  LIndex := 0;
  while LIndex <= High(LBlocks) do
  begin
    FAllocator.FreeBlock(LBlocks[LIndex]);
    LBlocks[LIndex] := nil;
    Inc(LIndex, 3);
  end;
  FAllocator.CheckHeap;
  for LIndex := 0 to High(LBlocks) do
    if Assigned(LBlocks[LIndex]) then
    begin
      Assert.AreEqual(LIndex + 1, FAllocator.BlockSize(LBlocks[LIndex]));
      Assert.AreEqual(Byte(LIndex), LBlocks[LIndex][LIndex]);
    end;
  Assert.AreEqual(200, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.DovrebbeRestareConsistenteSeLaMemoriaFinisce;
var
  LUser: Pointer;
begin
  FMemory.FailAtLiveBlocks := 2;
  FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  LUser := nil;
  Assert.WillRaise(
    procedure
    begin
      FAllocator.Allocate(8, ZONE_TAG_STATIC, @LUser);
    end, EOutOfMemory);
  Assert.IsNull(LUser);
  Assert.AreEqual(2, FAllocator.Statistics.BlockCount);
  FAllocator.CheckHeap;
end;

procedure TTestZoneAllocator.DovrebbeRifiutareUnaMemoriaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TZoneFactory.CreateAllocator(nil);
    end, EArgumentNilException);
end;

procedure TTestZoneAllocator.ReallocDiNilDovrebbeAllocare;
var
  LUser: Pointer;
  LBlock: Pointer;
begin
  LUser := nil;
  LBlock := FAllocator.Reallocate(nil, 24, ZONE_TAG_LEVEL, @LUser);
  Assert.IsNotNull(LBlock);
  Assert.IsTrue(LUser = LBlock);
  Assert.AreEqual(24, FAllocator.BlockSize(LBlock));
end;

procedure TTestZoneAllocator.ReallocConDimensioneZeroDovrebbeLiberare;
var
  LUser: Pointer;
  LBlock: Pointer;
begin
  LUser := nil;
  LBlock := FAllocator.Allocate(24, ZONE_TAG_LEVEL, @LUser);
  Assert.IsNull(FAllocator.Reallocate(LBlock, 0, ZONE_TAG_LEVEL, nil));
  Assert.IsNull(LUser);
  Assert.AreEqual(0, FAllocator.Statistics.BlockCount);
  // nil with size 0 is nothing to do
  Assert.IsNull(FAllocator.Reallocate(nil, 0, ZONE_TAG_LEVEL, nil));
end;

procedure TTestZoneAllocator.ReallocConLaStessaDimensioneDovrebbeDareLoStessoBlocco;
var
  LUser: Pointer;
  LBlock: Pointer;
begin
  LUser := nil;
  LBlock := FAllocator.Allocate(24, ZONE_TAG_LEVEL, @LUser);
  Assert.IsTrue(FAllocator.Reallocate(LBlock, 24, ZONE_TAG_CACHE, nil) = LBlock);
  // the tag and the user are not changed
  Assert.IsTrue(LUser = LBlock);
  Assert.AreEqual(0, FAllocator.FreeTags(ZONE_TAG_CACHE, ZONE_TAG_CACHE));
  Assert.AreEqual(1, FAllocator.FreeTags(ZONE_TAG_LEVEL, ZONE_TAG_LEVEL));
end;

procedure TTestZoneAllocator.ReallocDovrebbeTenereIByteCheCiStanno;
var
  LBlock: PByte;
  LIndex: Integer;
begin
  LBlock := FAllocator.Allocate(10, ZONE_TAG_STATIC, nil);
  for LIndex := 0 to 9 do
    LBlock[LIndex] := Byte(LIndex + 1);
  LBlock := FAllocator.Reallocate(LBlock, 50, ZONE_TAG_STATIC, nil);
  Assert.AreEqual(50, FAllocator.BlockSize(LBlock));
  for LIndex := 0 to 9 do
    Assert.AreEqual(Byte(LIndex + 1), LBlock[LIndex]);
  LBlock := FAllocator.Reallocate(LBlock, 4, ZONE_TAG_STATIC, nil);
  Assert.AreEqual(4, FAllocator.BlockSize(LBlock));
  for LIndex := 0 to 3 do
    Assert.AreEqual(Byte(LIndex + 1), LBlock[LIndex]);
  Assert.AreEqual(1, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.ReallocDovrebbeAggiornareLoStessoPuntatoreUtente;
var
  LUser: Pointer;
  LBlock: Pointer;
begin
  LUser := nil;
  LBlock := FAllocator.Allocate(10, ZONE_TAG_CACHE, @LUser);
  LBlock := FAllocator.Reallocate(LBlock, 400, ZONE_TAG_CACHE, @LUser);
  // freed with the old block, set again for the new one
  Assert.IsTrue(LUser = LBlock);
  FAllocator.FreeBlock(LBlock);
  Assert.IsNull(LUser);
end;

procedure TTestZoneAllocator.ReallocSenzaUtenteDovrebbeAzzerareIlVecchioUtente;
var
  LUser: Pointer;
  LBlock: Pointer;
begin
  LUser := nil;
  LBlock := FAllocator.Allocate(10, ZONE_TAG_CACHE, @LUser);
  LBlock := FAllocator.Reallocate(LBlock, 20, ZONE_TAG_CACHE, nil);
  Assert.IsNull(LUser);
  Assert.AreEqual(20, FAllocator.BlockSize(LBlock));
end;

procedure TTestZoneAllocator.ReallocDiUnPuntatoreEstraneoDovrebbeDareErrore;
var
  LBuffer: array[0..127] of Byte;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  Assert.WillRaise(
    procedure
    begin
      FAllocator.Reallocate(@LBuffer[64], 10, ZONE_TAG_STATIC, nil);
    end, EZoneException);
  Assert.AreEqual(0, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.ChangeTagDovrebbeCambiareIlDestinoDelBlocco;
var
  LBlock: Pointer;
begin
  LBlock := FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  FAllocator.ChangeTag(LBlock, ZONE_TAG_CACHE);
  Assert.AreEqual(0, FAllocator.FreeTags(ZONE_TAG_STATIC, ZONE_TAG_STATIC));
  Assert.AreEqual(1, FAllocator.FreeTags(ZONE_TAG_PURGELEVEL, ZONE_TAG_CACHE));
end;

procedure TTestZoneAllocator.FreeTagsDovrebbeLiberareLIntervalloIncluseLeEstremita;
begin
  FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(8, ZONE_TAG_LEVEL, nil);
  FAllocator.Allocate(8, ZONE_TAG_LEVSPEC, nil);
  FAllocator.Allocate(8, ZONE_TAG_CACHE, nil);
  Assert.AreEqual(2, FAllocator.FreeTags(ZONE_TAG_LEVEL, ZONE_TAG_LEVSPEC));
  Assert.AreEqual(2, FAllocator.Statistics.BlockCount);
  FAllocator.CheckHeap;
end;

procedure TTestZoneAllocator.FreeTagsDovrebbeAzzerareIPuntatoriUtente;
var
  LUsers: array[0..4] of Pointer;
  LIndex: Integer;
begin
  for LIndex := 0 to High(LUsers) do
    FAllocator.Allocate(8, ZONE_TAG_CACHE, @LUsers[LIndex]);
  Assert.AreEqual(5, FAllocator.FreeTags(ZONE_TAG_PURGELEVEL, MaxInt));
  for LIndex := 0 to High(LUsers) do
    Assert.IsNull(LUsers[LIndex]);
end;

procedure TTestZoneAllocator.FreeTagsDovrebbeDareZeroSeNienteCorrisponde;
begin
  FAllocator.Allocate(8, ZONE_TAG_STATIC, nil);
  Assert.AreEqual(0, FAllocator.FreeTags(ZONE_TAG_LEVEL, ZONE_TAG_CACHE));
  // an empty range
  Assert.AreEqual(0, FAllocator.FreeTags(ZONE_TAG_CACHE, ZONE_TAG_STATIC));
  Assert.AreEqual(1, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.FreeTagsDovrebbeLasciareIntattiIBlocchiFuoriIntervallo;
var
  LKept: PByte;
  LUser: Pointer;
begin
  LUser := nil;
  LKept := FAllocator.Allocate(4, ZONE_TAG_STATIC, @LUser);
  LKept[0] := 7;
  FAllocator.Allocate(4, ZONE_TAG_CACHE, nil);
  FAllocator.Allocate(4, ZONE_TAG_CACHE, nil);
  FAllocator.FreeTags(ZONE_TAG_CACHE, ZONE_TAG_CACHE);
  Assert.IsTrue(LUser = Pointer(LKept));
  Assert.AreEqual(Byte(7), LKept[0]);
  Assert.AreEqual(1, FAllocator.Statistics.BlockCount);
end;

procedure TTestZoneAllocator.MoveUsersDovrebbeSpostareISoliPuntatoriDentroLIntervallo;
var
  LOld: array[0..3] of Pointer;
  LNew: array[0..3] of Pointer;
  LOutside: Pointer;
  LBlocks: array[0..4] of Pointer;
begin
  FillChar(LOld, SizeOf(LOld), 0);
  FillChar(LNew, SizeOf(LNew), 0);
  LOutside := nil;
  LBlocks[0] := FAllocator.Allocate(4, ZONE_TAG_CACHE, @LOld[0]);
  LBlocks[1] := FAllocator.Allocate(4, ZONE_TAG_CACHE, @LOld[2]);
  // the cell 3 is outside the three cells that are moved
  LBlocks[2] := FAllocator.Allocate(4, ZONE_TAG_CACHE, @LOld[3]);
  LBlocks[3] := FAllocator.Allocate(4, ZONE_TAG_CACHE, @LOutside);
  LBlocks[4] := FAllocator.Allocate(4, ZONE_TAG_CACHE, nil);
  Assert.AreEqual(2, FAllocator.MoveUsers(@LOld[0], 3 * SizeOf(Pointer), @LNew[0]));
  FAllocator.FreeBlock(LBlocks[2]);
  Assert.IsNull(LOld[3], 'a cell outside the range is still the user');
  FAllocator.FreeBlock(LBlocks[3]);
  Assert.IsNull(LOutside);
  FAllocator.FreeBlock(LBlocks[0]);
  Assert.IsNotNull(LOld[0], 'a cell that moved is not written anymore');
end;

procedure TTestZoneAllocator.MoveUsersDovrebbeSeguireUnaTabellaCheCambiaIndirizzo;
var
  LOld: array[0..3] of Pointer;
  LNew: array[0..3] of Pointer;
  LBlock0: Pointer;
  LBlock2: Pointer;
begin
  LBlock0 := FAllocator.Allocate(4, ZONE_TAG_CACHE, @LOld[0]);
  LBlock2 := FAllocator.Allocate(4, ZONE_TAG_CACHE, @LOld[2]);
  Move(LOld, LNew, SizeOf(LOld));
  Assert.AreEqual(2, FAllocator.MoveUsers(@LOld[0], SizeOf(LOld), @LNew[0]));
  FAllocator.FreeBlock(LBlock0);
  Assert.IsNull(LNew[0]);
  Assert.IsTrue(LNew[2] = LBlock2);
  FAllocator.FreeBlock(LBlock2);
  Assert.IsNull(LNew[2]);
  Assert.IsTrue(LOld[2] = LBlock2, 'the old table is not written after the move');
end;

procedure TTestZoneAllocator.CheckHeapDovrebbeAccettareUnaZonaSana;
var
  LBlock: Pointer;
begin
  LBlock := FAllocator.Allocate(10, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(10, ZONE_TAG_CACHE, nil);
  FAllocator.Allocate(10, ZONE_TAG_LEVEL, nil);
  FAllocator.FreeBlock(LBlock);
  FAllocator.CheckHeap;
  Assert.Pass;
end;

procedure TTestZoneAllocator.CheckHeapDovrebbeAccettareUnaZonaVuota;
begin
  FAllocator.CheckHeap;
  FAllocator.CheckUsers;
  Assert.Pass;
end;

procedure TTestZoneAllocator.CheckHeapDovrebbeTrovareUnaIntestazioneDanneggiata;
var
  LBlock: Pointer;
begin
  FAllocator.Allocate(10, ZONE_TAG_STATIC, nil);
  LBlock := FAllocator.Allocate(10, ZONE_TAG_STATIC, nil);
  PZoneBlock(PByte(LBlock) - SizeOf(TZoneBlock)).Index := 7;
  Assert.WillRaise(
    procedure
    begin
      FAllocator.CheckHeap;
    end, EZoneException);
  // let the allocator free it
  PZoneBlock(PByte(LBlock) - SizeOf(TZoneBlock)).Index := 1;
end;

procedure TTestZoneAllocator.CheckHeapDovrebbeTrovareUnaDimensioneNegativa;
var
  LBlock: Pointer;
  LHeader: PZoneBlock;
begin
  LBlock := FAllocator.Allocate(10, ZONE_TAG_STATIC, nil);
  LHeader := PZoneBlock(PByte(LBlock) - SizeOf(TZoneBlock));
  LHeader.Size := -5;
  Assert.WillRaise(
    procedure
    begin
      FAllocator.CheckHeap;
    end, EZoneException);
  LHeader.Size := 10;
end;

procedure TTestZoneAllocator.CheckUsersDovrebbeAccettareIndirizziENil;
var
  LUser: Pointer;
begin
  LUser := nil;
  FAllocator.Allocate(4, ZONE_TAG_CACHE, @LUser);
  FAllocator.Allocate(4, ZONE_TAG_CACHE, nil);
  FAllocator.CheckUsers;
  Assert.Pass;
end;

procedure TTestZoneAllocator.CheckUsersDovrebbeTrovareUnNumeroPiccolo;
var
  LBlock: Pointer;
  LHeader: PZoneBlock;
begin
  LBlock := FAllocator.Allocate(4, ZONE_TAG_CACHE, nil);
  LHeader := PZoneBlock(PByte(LBlock) - SizeOf(TZoneBlock));
  // 0 and the numbers up to 100 are accepted, the others below 64 KB are not addresses
  LHeader.User := PPointer(100);
  FAllocator.CheckUsers;
  LHeader.User := PPointer($1234);
  Assert.WillRaise(
    procedure
    begin
      FAllocator.CheckUsers;
    end, EZoneException);
  LHeader.User := nil;
end;

procedure TTestZoneAllocator.StatisticsDovrebbeContareBlocchiEByte;
var
  LStatistics: TZoneStatistics;
begin
  FAllocator.Allocate(100, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(50, ZONE_TAG_LEVEL, nil);
  LStatistics := FAllocator.Statistics;
  Assert.AreEqual(2, LStatistics.BlockCount);
  Assert.AreEqual(Int64(150), LStatistics.UserBytes);
  Assert.AreEqual(Int64(150 + 2 * SizeOf(TZoneBlock)), LStatistics.TotalBytes);
  Assert.AreEqual(Int64(0), LStatistics.PurgableBytes);
end;

procedure TTestZoneAllocator.StatisticsDovrebbeContareLaCacheComeRecuperabile;
var
  LStatistics: TZoneStatistics;
begin
  FAllocator.Allocate(100, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(60, ZONE_TAG_PURGELEVEL, nil);
  FAllocator.Allocate(40, ZONE_TAG_CACHE, nil);
  LStatistics := FAllocator.Statistics;
  Assert.AreEqual(Int64(100 + 2 * SizeOf(TZoneBlock)), LStatistics.PurgableBytes);
end;

procedure TTestZoneAllocator.DescribeDovrebbeDareUnaRigaPerOgniBloccoNellIntervallo;
var
  LLines: TArray<string>;
begin
  FAllocator.Allocate(100, ZONE_TAG_STATIC, nil);
  FAllocator.Allocate(50, ZONE_TAG_LEVEL, nil);
  FAllocator.Allocate(25, ZONE_TAG_LEVEL, nil);
  LLines := FAllocator.Describe(ZONE_TAG_LEVEL, ZONE_TAG_LEVSPEC);
  // the zone, the range, two blocks
  Assert.AreEqual(4, Length(LLines));
  Assert.IsTrue(LLines[0].Contains('blocks: 3'));
  Assert.IsTrue(LLines[1].Contains('050'));
  Assert.IsTrue(LLines[2].Contains('size:0000050'));
  Assert.IsTrue(LLines[2].Contains('tag:050'));
  Assert.IsTrue(LLines[3].Contains('size:0000025'));
  Assert.AreEqual(2, Length(FAllocator.Describe(ZONE_TAG_LEVEL, 0)));
end;

procedure TTestZoneAllocator.LIntestazioneDovrebbeAvereLaDimensioneAttesa;
begin
  // three integers and a pointer: 16 bytes in 32 bits, 24 in 64 bits
  Assert.AreEqual(12 + SizeOf(Pointer) + (SizeOf(Pointer) - 4), SizeOf(TZoneBlock));
end;

procedure TTestZoneAllocator.LaMemoriaDelloHeapDovrebbeDareEPrendereByte;
var
  LMemory: IZoneMemory;
  LBlock: PByte;
begin
  LMemory := TZoneHeapMemory.Create;
  LBlock := LMemory.Allocate(64);
  Assert.IsNotNull(LBlock);
  FillChar(LBlock^, 64, 1);
  LMemory.Release(LBlock, 64);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZoneAllocator);

end.
