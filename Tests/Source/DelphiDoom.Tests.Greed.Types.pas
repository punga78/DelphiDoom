{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - records of the files, constants     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiRecordSuDisco;
    [Test]
    procedure DovrebbeTenereIOffsetDeiCampiDeiRecord;
    [Test]
    procedure DovrebbeUsareByteEPerICaratteriDeiNomi;
    [Test]
    procedure DovrebbeAvereDiciottoPianiDaQuattromilaNovantasei;
    [Test]
    procedure DovrebbeAvereLaVirgolaFissaSedicibit;
    [Test]
    procedure DovrebbeAvereIPianiNellOrdineDelFile;
    [Test]
    procedure DovrebbeAvereEccezioniDedicate;
  end;

implementation

{ TTestGreedTypes }

procedure TTestGreedTypes.DovrebbeAvereLeDimensioniDeiRecordSuDisco;
begin
  Assert.AreEqual(10, SizeOf(TGreedFileInfo));
  Assert.AreEqual(GREED_FILEINFO_BYTES, SizeOf(TGreedFileInfo));
  Assert.AreEqual(12, SizeOf(TGreedLumpInfo));
  Assert.AreEqual(GREED_LUMPINFO_BYTES, SizeOf(TGreedLumpInfo));
  Assert.AreEqual(8, SizeOf(TGreedPictureHeader));
  Assert.AreEqual(GREED_PICTURE_HEADER_BYTES, SizeOf(TGreedPictureHeader));
  Assert.AreEqual(4, SizeOf(TGreedSpriteHeader));
  Assert.AreEqual(GREED_SPRITE_HEADER_BYTES, SizeOf(TGreedSpriteHeader));
  Assert.AreEqual(8, SizeOf(TGreedName8));
  Assert.AreEqual(4, SizeOf(TGreedFixed));
end;

procedure TTestGreedTypes.DovrebbeTenereIOffsetDeiCampiDeiRecord;
var
  LInfo: TGreedFileInfo;
  LLump: TGreedLumpInfo;
begin
  Assert.AreEqual(2, Integer(NativeInt(@LInfo.InfoTableOffset) - NativeInt(@LInfo)));
  Assert.AreEqual(6, Integer(NativeInt(@LInfo.InfoTableSize) - NativeInt(@LInfo)));
  Assert.AreEqual(4, Integer(NativeInt(@LLump.Size) - NativeInt(@LLump)));
  Assert.AreEqual(8, Integer(NativeInt(@LLump.NameOffset) - NativeInt(@LLump)));
  Assert.AreEqual(10, Integer(NativeInt(@LLump.Compress) - NativeInt(@LLump)));
end;

procedure TTestGreedTypes.DovrebbeUsareByteEPerICaratteriDeiNomi;
begin
  Assert.AreEqual(1, SizeOf(AnsiChar));
  Assert.AreEqual(7, High(TGreedName8));
end;

procedure TTestGreedTypes.DovrebbeAvereDiciottoPianiDaQuattromilaNovantasei;
begin
  Assert.AreEqual(4096, GREED_MAP_TILES);
  Assert.AreEqual(18, GREED_MAP_PLANES);
  Assert.AreEqual(73728, GREED_MAP_BYTES);
  Assert.AreEqual(GREED_MAP_PLANES, Ord(High(TGreedPlane)) + 1);
end;

procedure TTestGreedTypes.DovrebbeAvereLaVirgolaFissaSedicibit;
begin
  Assert.AreEqual(16, GREED_FRACBITS);
  Assert.AreEqual(65536, GREED_FRACUNIT);
end;

procedure TTestGreedTypes.DovrebbeAvereIPianiNellOrdineDelFile;
begin
  // northwall, northflags, westwall, westflags, floorpic ... mapslopes (DoLoadMapData)
  Assert.AreEqual(0, Ord(gpNorthWall));
  Assert.AreEqual(2, Ord(gpWestWall));
  Assert.AreEqual(4, Ord(gpFloorPic));
  Assert.AreEqual(6, Ord(gpCeilingPic));
  Assert.AreEqual(10, Ord(gpFloorDef));
  Assert.AreEqual(14, Ord(gpMapLights));
  Assert.AreEqual(17, Ord(gpMapSlopes));
end;

procedure TTestGreedTypes.DovrebbeAvereEccezioniDedicate;
begin
  Assert.WillRaiseDescendant(procedure begin raise EGreedDataException.Create('x'); end, EGreedException);
  Assert.WillRaiseDescendant(procedure begin raise EGreedNotFoundException.Create('x'); end, EGreedException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedTypes);

end.
