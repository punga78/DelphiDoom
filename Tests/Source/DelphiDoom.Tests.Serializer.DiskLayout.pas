{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer library - the layouts on disk           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.DiskLayout;

interface

{$ALIGN 8}
{$MINENUMSIZE 1}

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Serializer.Types, DelphiDoom.Serializer.Intf;

type
  TTestLayoutAction = procedure(AValue: Pointer);

  // the same value seen in more ways, as the function of a thinker
  TTestLayoutFunction = record
    case Integer of
      0: (First: TTestLayoutAction);
      1: (Second: Pointer);
  end;

  PTestLayoutThinker = ^TTestLayoutThinker;
  TTestLayoutThinker = record
    Prev: PTestLayoutThinker;
    Next: PTestLayoutThinker;
    Action: TTestLayoutFunction;
  end;

  TTestLayoutKind = (First, Second, Third);

  // like a door: 36 bytes for the 32 bit compiler, 64 for the other one
  TTestLayoutDoor = record
    Thinker: TTestLayoutThinker;
    Kind: TTestLayoutKind;
    Sector: Pointer;
    TopHeight: Integer;
    Speed: Integer;
    Line: Pointer;
    Count: Integer;
  end;

  // like a sprite of the player: 16 bytes and 24
  TTestLayoutSprite = record
    State: Pointer;
    Tics: Integer;
    X: Integer;
    Y: Integer;
  end;

  // like a player: 88 bytes for the 32 bit compiler, 128 for the other one
  TTestLayoutPlayer = record
    Mobj: Pointer;
    State: Byte;
    Powers: array[0..2] of Integer;
    Cards: array[0..4] of Boolean;
    Backpack: Boolean;
    Health: Integer;
    Sprites: array[0..1] of TTestLayoutSprite;
    Special: NativeInt;
    Scale: Single;
    Name: array[0..7] of AnsiChar;
    Target: Pointer;
    Last: Byte;
  end;

  TTestLayoutPacked = packed record
    Flag: Byte;
    Owner: Pointer;
    Number: Word;
  end;

  // bytes with an unnamed type before a field aligned to 8: their size cannot be told
  TTestLayoutUncertain = record
    Bytes: array[0..2] of Byte;
    Big: Int64;
  end;

  TTestLayoutOverlap = record
    case Integer of
      0: (Small: Byte);
      1: (Large: Pointer);
  end;

  TTestLayoutPlain = record
    Number: Integer;
    Flag: Byte;
    Big: Int64;
    Value: Double;
  end;

  // packed, but every field is where it would be anyway (like ticcmd_t): only its place in another record
  // tells that it is packed
  TTestLayoutCommand = packed record
    Forward: ShortInt;
    Side: ShortInt;
    Turn: SmallInt;
  end;

  TTestLayoutHolder = record
    Mobj: Pointer;
    State: Byte;
    Command: TTestLayoutCommand;
    Height: Integer;
  end;

  // the record of an old version of the saved games and the one of today: the first is the start of the
  // second on disk, but not in the memory of the 64 bit program (an Integer became a NativeInt)
  TTestLayoutOldMobj = record
    X: Integer;
    Special: Integer;
    Flags: Integer;
  end;

  TTestLayoutNewMobj = record
    X: Integer;
    Special: NativeInt;
    Flags: Integer;
    Added: Integer;
  end;

  [TestFixture]
  [Category('serializer')]
  TTestSerializerDiskLayout = class(TObject)
  private
    FLayouts: IDiskLayouts;
    procedure DescribePlayer;
    function FilledPlayer: TTestLayoutPlayer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLaDimensioneDelProgrammaA32Bit;
    [Test]
    procedure DovrebbeEssereLaStessaMemoriaConIlProgrammaA32Bit;
    [Test]
    procedure DovrebbeDireCampiERiferimentiSenzaParlareDellaMemoria;
    [Test]
    procedure DovrebbeScrivereOgniCampoAlSuoPostoSulDisco;
    [Test]
    procedure DovrebbeRileggereCioCheHaScritto;
    [Test]
    procedure DovrebbeTenereIlSegnoDiUnRiferimento;
    [Test]
    procedure DovrebbeNonLeggereOltreLaDimensioneDelRecord;
    [Test]
    procedure DovrebbeLeggereSoloIlPrefissoDiUnRecordVecchio;
    [Test]
    procedure DovrebbeCapireUnRecordPackedCoiCampiAllineati;
    [Test]
    procedure DovrebbeCapireUnRecordPacked;
    [Test]
    procedure DovrebbeCopiareInteroUnRecordSenzaPuntatori;
    [Test]
    procedure DovrebbeChiedereLaDescrizioneDiUnCampoIncerto;
    [Test]
    procedure DovrebbeAccettareIlCampoIncertoDopoLaDescrizione;
    [Test]
    procedure DovrebbeRifiutareUnaDescrizioneConIlNumeroSbagliato;
    [Test]
    procedure DovrebbeRifiutareDueCampiSovrappostiDiversi;
    [Test]
    procedure DovrebbeDescrivereIRecordDichiaratiNellOrdine;
    [Test]
    procedure DovrebbeNonFarDiventareNilUnValoreNonNil;
    [Test]
    procedure DovrebbeDareEccezioneSenzaInformazioniDiTipo;
  end;

implementation

uses
  DelphiDoom.Serializer.Factory;

const
  DOOR_DISK_SIZE = 36;
  PLAYER_DISK_SIZE = 88;
  // where the fields of TTestLayoutPlayer are for the 32 bit compiler
  PLAYER_DISK_MOBJ = 0;
  PLAYER_DISK_STATE = 4;
  PLAYER_DISK_POWERS = 8;
  PLAYER_DISK_CARDS = 20;
  PLAYER_DISK_BACKPACK = 25;
  PLAYER_DISK_HEALTH = 28;
  PLAYER_DISK_SPRITES = 32;
  PLAYER_DISK_SPECIAL = 64;
  PLAYER_DISK_SCALE = 68;
  PLAYER_DISK_NAME = 72;
  PLAYER_DISK_TARGET = 80;
  PLAYER_DISK_LAST = 84;
  SPRITE_DISK_SIZE = 16;

{ TTestSerializerDiskLayout }

procedure TTestSerializerDiskLayout.Setup;
begin
  FLayouts := TSerializerFactory.CreateDiskLayouts;
end;

procedure TTestSerializerDiskLayout.TearDown;
begin
  FLayouts := nil;
end;

procedure TTestSerializerDiskLayout.DescribePlayer;
begin
  FLayouts.DescribeArray(TypeInfo(TTestLayoutPlayer), 'Sprites', TypeInfo(TTestLayoutSprite), 2);
  FLayouts.DescribeArray(TypeInfo(TTestLayoutPlayer), 'Name', TypeInfo(AnsiChar), 8);
end;

function TTestSerializerDiskLayout.FilledPlayer: TTestLayoutPlayer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Mobj := Pointer(NativeInt(7));
  Result.State := 3;
  Result.Powers[0] := 11;
  Result.Powers[1] := -12;
  Result.Powers[2] := 13;
  Result.Cards[0] := True;
  Result.Cards[4] := True;
  Result.Backpack := True;
  Result.Health := 100;
  Result.Sprites[0].State := Pointer(NativeInt(21));
  Result.Sprites[0].Tics := 5;
  Result.Sprites[0].X := 6;
  Result.Sprites[0].Y := 7;
  Result.Sprites[1].State := nil;
  Result.Sprites[1].Tics := -1;
  Result.Sprites[1].X := 8;
  Result.Sprites[1].Y := 9;
  Result.Special := -2;
  Result.Scale := 1.5;
  Result.Name := 'ABCDEFG';
  Result.Target := Pointer(NativeInt(-1));
  Result.Last := 200;
end;

procedure TTestSerializerDiskLayout.DovrebbeDareLaDimensioneDelProgrammaA32Bit;
begin
  DescribePlayer;
  Assert.AreEqual<Integer>(DOOR_DISK_SIZE, FLayouts.LayoutOf(TypeInfo(TTestLayoutDoor)).DiskSize);
  Assert.AreEqual<Integer>(PLAYER_DISK_SIZE, FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer)).DiskSize);
  Assert.AreEqual<Integer>(SPRITE_DISK_SIZE, FLayouts.LayoutOf(TypeInfo(TTestLayoutSprite)).DiskSize);
  Assert.AreEqual<Integer>(SizeOf(TTestLayoutPlayer), FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer)).NativeSize);
end;

procedure TTestSerializerDiskLayout.DovrebbeEssereLaStessaMemoriaConIlProgrammaA32Bit;
var
  LPlayer: TTestLayoutPlayer;
  LDisk: array[0..PLAYER_DISK_SIZE - 1] of Byte;
  LPointerSize: Integer;
begin
  LPointerSize := SizeOf(Pointer);
  if LPointerSize <> SizeOf(Integer) then
  begin
    // the 64 bit program: the record in memory is larger than the one on disk
    Assert.IsTrue(SizeOf(TTestLayoutPlayer) > PLAYER_DISK_SIZE);
    Exit;
  end;
  DescribePlayer;
  Assert.AreEqual<Integer>(PLAYER_DISK_SIZE, SizeOf(TTestLayoutPlayer));
  Assert.AreEqual<Integer>(DOOR_DISK_SIZE, SizeOf(TTestLayoutDoor));
  LPlayer := FilledPlayer;
  FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer)).Pack(@LPlayer, @LDisk);
  Assert.IsTrue(CompareMem(@LPlayer, @LDisk, PLAYER_DISK_SIZE));
end;

procedure TTestSerializerDiskLayout.DovrebbeDireCampiERiferimentiSenzaParlareDellaMemoria;
var
  LLines: TArray<string>;
begin
  LLines := FLayouts.LayoutOf(TypeInfo(TTestLayoutDoor)).Describe;
  Assert.AreEqual<Integer>(9, Length(LLines));
  Assert.AreEqual('TTestLayoutDoor disk=36', LLines[0]);
  Assert.AreEqual('  0 12 Thinker record', LLines[1]);
  Assert.AreEqual('  12 1 Kind value', LLines[2]);
  Assert.AreEqual('  16 4 Sector ref', LLines[3]);
  Assert.AreEqual('  20 4 TopHeight value', LLines[4]);
  Assert.AreEqual('  24 4 Speed value', LLines[5]);
  Assert.AreEqual('  28 4 Line ref', LLines[6]);
  Assert.AreEqual('  32 4 Count value', LLines[7]);
  Assert.AreEqual('  references: 0 4 8 16 28', LLines[8]);

  DescribePlayer;
  LLines := FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer)).Describe;
  Assert.AreEqual('  8 12 Powers bytes', LLines[3]);
  Assert.AreEqual('  32 32 Sprites array', LLines[7]);
  Assert.AreEqual('  references: 0 32 48 64 80', LLines[High(LLines)]);
end;

procedure TTestSerializerDiskLayout.DovrebbeScrivereOgniCampoAlSuoPostoSulDisco;
var
  LPlayer: TTestLayoutPlayer;
  LDisk: array[0..PLAYER_DISK_SIZE - 1] of Byte;
begin
  DescribePlayer;
  LPlayer := FilledPlayer;
  FillChar(LDisk, SizeOf(LDisk), $EE);
  FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer)).Pack(@LPlayer, @LDisk);
  Assert.AreEqual<Integer>(7, PInteger(@LDisk[PLAYER_DISK_MOBJ])^);
  Assert.AreEqual<Integer>(3, LDisk[PLAYER_DISK_STATE]);
  Assert.AreEqual<Integer>(11, PInteger(@LDisk[PLAYER_DISK_POWERS])^);
  Assert.AreEqual<Integer>(-12, PInteger(@LDisk[PLAYER_DISK_POWERS + 4])^);
  Assert.AreEqual<Integer>(13, PInteger(@LDisk[PLAYER_DISK_POWERS + 8])^);
  Assert.AreEqual<Integer>(1, LDisk[PLAYER_DISK_CARDS]);
  Assert.AreEqual<Integer>(0, LDisk[PLAYER_DISK_CARDS + 1]);
  Assert.AreEqual<Integer>(1, LDisk[PLAYER_DISK_CARDS + 4]);
  Assert.AreEqual<Integer>(1, LDisk[PLAYER_DISK_BACKPACK]);
  Assert.AreEqual<Integer>(100, PInteger(@LDisk[PLAYER_DISK_HEALTH])^);
  Assert.AreEqual<Integer>(21, PInteger(@LDisk[PLAYER_DISK_SPRITES])^);
  Assert.AreEqual<Integer>(5, PInteger(@LDisk[PLAYER_DISK_SPRITES + 4])^);
  Assert.AreEqual<Integer>(7, PInteger(@LDisk[PLAYER_DISK_SPRITES + 12])^);
  Assert.AreEqual<Integer>(0, PInteger(@LDisk[PLAYER_DISK_SPRITES + SPRITE_DISK_SIZE])^);
  Assert.AreEqual<Integer>(-1, PInteger(@LDisk[PLAYER_DISK_SPRITES + SPRITE_DISK_SIZE + 4])^);
  Assert.AreEqual<Integer>(9, PInteger(@LDisk[PLAYER_DISK_SPRITES + SPRITE_DISK_SIZE + 12])^);
  Assert.AreEqual<Integer>(-2, PInteger(@LDisk[PLAYER_DISK_SPECIAL])^);
  Assert.AreEqual<Single>(1.5, PSingle(@LDisk[PLAYER_DISK_SCALE])^);
  Assert.AreEqual<Integer>(Ord('A'), LDisk[PLAYER_DISK_NAME]);
  Assert.AreEqual<Integer>(Ord('G'), LDisk[PLAYER_DISK_NAME + 6]);
  Assert.AreEqual<Integer>(-1, PInteger(@LDisk[PLAYER_DISK_TARGET])^);
  Assert.AreEqual<Integer>(200, LDisk[PLAYER_DISK_LAST]);
end;

procedure TTestSerializerDiskLayout.DovrebbeRileggereCioCheHaScritto;
var
  LPlayer: TTestLayoutPlayer;
  LRead: TTestLayoutPlayer;
  LDisk: array[0..PLAYER_DISK_SIZE - 1] of Byte;
  LLayout: IDiskLayout;
begin
  DescribePlayer;
  LLayout := FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer));
  LPlayer := FilledPlayer;
  LLayout.Pack(@LPlayer, @LDisk);
  FillChar(LRead, SizeOf(LRead), $EE);
  LLayout.Unpack(@LDisk, @LRead);
  Assert.AreEqual<NativeInt>(7, NativeInt(LRead.Mobj));
  Assert.AreEqual<Integer>(3, LRead.State);
  Assert.AreEqual<Integer>(-12, LRead.Powers[1]);
  Assert.IsTrue(LRead.Cards[4]);
  Assert.IsFalse(LRead.Cards[3]);
  Assert.IsTrue(LRead.Backpack);
  Assert.AreEqual<Integer>(100, LRead.Health);
  Assert.AreEqual<NativeInt>(21, NativeInt(LRead.Sprites[0].State));
  Assert.AreEqual<Integer>(6, LRead.Sprites[0].X);
  Assert.IsNull(LRead.Sprites[1].State);
  Assert.AreEqual<Integer>(9, LRead.Sprites[1].Y);
  Assert.AreEqual<NativeInt>(-2, LRead.Special);
  Assert.AreEqual<Single>(1.5, LRead.Scale);
  Assert.AreEqual<Integer>(Ord('C'), Ord(LRead.Name[2]));
  Assert.AreEqual<Integer>(200, LRead.Last);
end;

procedure TTestSerializerDiskLayout.DovrebbeTenereIlSegnoDiUnRiferimento;
var
  LDoor: TTestLayoutDoor;
  LRead: TTestLayoutDoor;
  LDisk: array[0..DOOR_DISK_SIZE - 1] of Byte;
  LLayout: IDiskLayout;
begin
  // the saved games use -1 for "no line": it must come back as -1, not as 4294967295
  LLayout := FLayouts.LayoutOf(TypeInfo(TTestLayoutDoor));
  FillChar(LDoor, SizeOf(LDoor), 0);
  LDoor.Line := Pointer(NativeInt(-1));
  LDoor.Sector := Pointer(NativeInt(41));
  LLayout.Pack(@LDoor, @LDisk);
  Assert.AreEqual<Cardinal>($FFFFFFFF, PCardinal(@LDisk[28])^);
  FillChar(LRead, SizeOf(LRead), 0);
  LLayout.Unpack(@LDisk, @LRead);
  Assert.AreEqual<NativeInt>(-1, NativeInt(LRead.Line));
  Assert.AreEqual<NativeInt>(41, NativeInt(LRead.Sector));
end;

procedure TTestSerializerDiskLayout.DovrebbeNonLeggereOltreLaDimensioneDelRecord;
var
  LMemory: array[0..1] of TTestLayoutSprite;
  LDisk: array[0..SPRITE_DISK_SIZE - 1] of Byte;
begin
  // an old record is read over the start of a newer and longer one: the rest must stay as it is
  FillChar(LDisk, SizeOf(LDisk), 1);
  FillChar(LMemory, SizeOf(LMemory), $EE);
  FLayouts.LayoutOf(TypeInfo(TTestLayoutSprite)).Unpack(@LDisk, @LMemory[0]);
  Assert.AreEqual<Integer>($01010101, LMemory[0].Y);
  Assert.AreEqual<Integer>(Integer($EEEEEEEE), LMemory[1].Tics);
  Assert.AreEqual<Integer>($EE, PByte(@LMemory[1])^);
end;

procedure TTestSerializerDiskLayout.DovrebbeCapireUnRecordPacked;
var
  LLines: TArray<string>;
begin
  LLines := FLayouts.LayoutOf(TypeInfo(TTestLayoutPacked)).Describe;
  Assert.AreEqual('TTestLayoutPacked disk=7', LLines[0]);
  Assert.AreEqual('  1 4 Owner ref', LLines[2]);
  Assert.AreEqual('  5 2 Number value', LLines[3]);
  Assert.AreEqual('  references: 1', LLines[4]);
end;

procedure TTestSerializerDiskLayout.DovrebbeCopiareInteroUnRecordSenzaPuntatori;
var
  LPlain: TTestLayoutPlain;
  LDisk: TTestLayoutPlain;
  LLayout: IDiskLayout;
begin
  LLayout := FLayouts.LayoutOf(TypeInfo(TTestLayoutPlain));
  Assert.AreEqual<Integer>(24, LLayout.DiskSize);
  Assert.AreEqual<Integer>(SizeOf(TTestLayoutPlain), LLayout.NativeSize);
  // the padding too: the engine has always copied these records whole
  FillChar(LPlain, SizeOf(LPlain), $5A);
  FillChar(LDisk, SizeOf(LDisk), 0);
  LLayout.Pack(@LPlain, @LDisk);
  Assert.IsTrue(CompareMem(@LPlain, @LDisk, SizeOf(LPlain)));
end;

procedure TTestSerializerDiskLayout.DovrebbeChiedereLaDescrizioneDiUnCampoIncerto;
begin
  Assert.WillRaise(
    procedure
    begin
      FLayouts.LayoutOf(TypeInfo(TTestLayoutUncertain));
    end,
    ESerializerException);
end;

procedure TTestSerializerDiskLayout.DovrebbeAccettareIlCampoIncertoDopoLaDescrizione;
begin
  FLayouts.DescribeArray(TypeInfo(TTestLayoutUncertain), 'bytes', TypeInfo(Byte), 3);
  Assert.AreEqual<Integer>(16, FLayouts.LayoutOf(TypeInfo(TTestLayoutUncertain)).DiskSize);
end;

procedure TTestSerializerDiskLayout.DovrebbeRifiutareUnaDescrizioneConIlNumeroSbagliato;
begin
  FLayouts.DescribeArray(TypeInfo(TTestLayoutPlayer), 'Sprites', TypeInfo(TTestLayoutSprite), 3);
  Assert.WillRaise(
    procedure
    begin
      FLayouts.LayoutOf(TypeInfo(TTestLayoutPlayer));
    end,
    ESerializerException);
end;

procedure TTestSerializerDiskLayout.DovrebbeRifiutareDueCampiSovrappostiDiversi;
begin
  Assert.WillRaise(
    procedure
    begin
      FLayouts.LayoutOf(TypeInfo(TTestLayoutOverlap));
    end,
    ESerializerException);
end;

procedure TTestSerializerDiskLayout.DovrebbeDescrivereIRecordDichiaratiNellOrdine;
var
  LLines: TArray<string>;
begin
  FLayouts.Declare(TypeInfo(TTestLayoutSprite));
  FLayouts.Declare(TypeInfo(TTestLayoutPacked));
  FLayouts.Declare(TypeInfo(TTestLayoutSprite));
  LLines := FLayouts.DescribeAll;
  Assert.AreEqual<Integer>(6 + 5, Length(LLines));
  Assert.AreEqual('TTestLayoutSprite disk=16', LLines[0]);
  Assert.AreEqual('TTestLayoutPacked disk=7', LLines[6]);
end;

procedure TTestSerializerDiskLayout.DovrebbeNonFarDiventareNilUnValoreNonNil;
var
  LValue: NativeInt;
  LExpected: Integer;
begin
  // an address of the 64 bit program whose low half is 0: on disk it must not look like nil
  LValue := 1;
  LValue := LValue shl 16;
  LValue := LValue shl 16;
  LExpected := 0;
  if LValue <> 0 then
    LExpected := 1;
  Assert.AreEqual<Integer>(LExpected, TSerializerNativeValue.ToDisk(LValue));
  Assert.AreEqual<Integer>(0, TSerializerNativeValue.ToDisk(0));
  Assert.AreEqual<Integer>(-1, TSerializerNativeValue.ToDisk(-1));
  Assert.AreEqual<NativeInt>(-1, TSerializerNativeValue.FromDisk(-1));
end;

procedure TTestSerializerDiskLayout.DovrebbeDareEccezioneSenzaInformazioniDiTipo;
begin
  Assert.WillRaise(
    procedure
    begin
      FLayouts.LayoutOf(nil);
    end,
    ESerializerException);
end;

procedure TTestSerializerDiskLayout.DovrebbeLeggereSoloIlPrefissoDiUnRecordVecchio;
var
  LOld: TTestLayoutOldMobj;
  LNew: TTestLayoutNewMobj;
  LOldSize: Integer;
begin
  LOld.X := 10;
  LOld.Special := -20;
  LOld.Flags := 30;
  LOldSize := FLayouts.LayoutOf(TypeInfo(TTestLayoutOldMobj)).DiskSize;
  Assert.AreEqual<Integer>(12, LOldSize);
  Assert.AreEqual<Integer>(16, FLayouts.LayoutOf(TypeInfo(TTestLayoutNewMobj)).DiskSize);
  LNew.X := 0;
  LNew.Special := 0;
  LNew.Flags := 0;
  LNew.Added := 99;
  // the old record is what the 32 bit program has in memory: it is the layout on disk of itself
  FLayouts.LayoutOf(TypeInfo(TTestLayoutNewMobj)).UnpackPrefix(@LOld, @LNew, LOldSize);
  Assert.AreEqual<Integer>(10, LNew.X);
  Assert.AreEqual<NativeInt>(-20, LNew.Special);
  Assert.AreEqual<Integer>(30, LNew.Flags);
  Assert.AreEqual<Integer>(99, LNew.Added);
end;

procedure TTestSerializerDiskLayout.DovrebbeCapireUnRecordPackedCoiCampiAllineati;
var
  LLines: TArray<string>;
begin
  LLines := FLayouts.LayoutOf(TypeInfo(TTestLayoutHolder)).Describe;
  Assert.AreEqual('TTestLayoutHolder disk=16', LLines[0]);
  Assert.AreEqual('  4 1 State value', LLines[2]);
  Assert.AreEqual('  5 4 Command record', LLines[3]);
  Assert.AreEqual('  12 4 Height value', LLines[4]);
end;

end.
