{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - records and constants of the files   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenTypes = class(TObject)
  public
    /// <summary>The sizes that the C compiler gave to the structures of the files (16 bit int, packed)</summary>
    [Test]
    procedure DovrebbeAvereLeDimensioniDelC;
    [Test]
    procedure DovrebbeAvereIlRecordDellaMappaNeiPostiGiusti;
    [Test]
    procedure DovrebbeTornareLaTabellaDelleInformazioniDeiTile;
    [Test]
    procedure DovrebbeTornareLeDimensioniDelleTabelleDelleImmagini;
    [Test]
    procedure DovrebbeTornareLeDimensioniDelFileDelleMappe;
  end;

implementation

{ TTestKeenTypes }

procedure TTestKeenTypes.DovrebbeAvereLeDimensioniDelC;
begin
  Assert.AreEqual(4, SizeOf(TKeenHuffNode), 'huffnode');
  Assert.AreEqual(38, SizeOf(TKeenMapHeader), 'maptype');
  Assert.AreEqual(502, SizeOf(TKeenMapFileHeader), 'mapfiletype fino ai tile info');
  Assert.AreEqual(4, SizeOf(TKeenPictureEntry), 'pictabletype');
  Assert.AreEqual(18, SizeOf(TKeenSpriteEntry), 'spritetabletype');
  Assert.AreEqual(6, SizeOf(TKeenSoundCommon), 'SoundCommon');
end;

procedure TTestKeenTypes.DovrebbeAvereIlRecordDellaMappaNeiPostiGiusti;
var
  LHeader: TKeenMapHeader;
begin
  Assert.AreEqual(0, Integer(NativeInt(@LHeader.PlaneStart) - NativeInt(@LHeader)));
  Assert.AreEqual(12, Integer(NativeInt(@LHeader.PlaneLength) - NativeInt(@LHeader)));
  Assert.AreEqual(18, Integer(NativeInt(@LHeader.Width) - NativeInt(@LHeader)));
  Assert.AreEqual(20, Integer(NativeInt(@LHeader.Height) - NativeInt(@LHeader)));
  Assert.AreEqual(22, Integer(NativeInt(@LHeader.Name) - NativeInt(@LHeader)));
end;

procedure TTestKeenTypes.DovrebbeTornareLaTabellaDelleInformazioniDeiTile;
begin
  // SPEED = 502 in id_ca.h: after the 502 bytes of the start of MAPHEAD
  Assert.AreEqual(502, KEEN_MAPHEAD_PREFIX);
  Assert.AreEqual(1440, KEEN_TINF_ANIM);
  Assert.AreEqual(2880, KEEN_TINF_NORTHWALL);
  Assert.AreEqual(2880 + 1206, KEEN_TINF_EASTWALL);
  Assert.AreEqual(2880 + 4 * 1206, KEEN_TINF_MANIM);
  Assert.AreEqual(2880 + 6 * 1206, KEEN_TINF_MSPEED);
  Assert.AreEqual(11322, KEEN_TINF_SIZE, 'il blocco tileinfo del golden');
end;

procedure TTestKeenTypes.DovrebbeTornareLeDimensioniDelleTabelleDelleImmagini;
begin
  Assert.AreEqual(260, KEEN_NUMPICS * SizeOf(TKeenPictureEntry), 'pictable del golden');
  Assert.AreEqual(5346, KEEN_NUMSPRITES * SizeOf(TKeenSpriteEntry));
  Assert.AreEqual(KEEN_NUMCHUNKS, KEEN_STARTTILE16M + KEEN_NUMTILE16M);
  Assert.AreEqual(KEEN_STARTTILE16M, KEEN_STARTTILE16 + KEEN_NUMTILE16);
  Assert.AreEqual(KEEN_STARTSPRITES + KEEN_NUMSPRITES, KEEN_STARTTILE8);
end;

procedure TTestKeenTypes.DovrebbeTornareLeDimensioniDelFileDelleMappe;
begin
  Assert.AreEqual(11824, KEEN_MAPHEAD_PREFIX + KEEN_TINF_SIZE, 'MAPHEAD.KDR');
  Assert.AreEqual(1020, KEEN_HUFF_DICT_BYTES, 'MAPDICT.KDR');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenTypes);

end.
