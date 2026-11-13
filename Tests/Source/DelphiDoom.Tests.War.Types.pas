{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - types and little endian numbers      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.LittleEndian;

type
  [TestFixture]
  [Category('war')]
  TTestWarTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereUnaIntestazioneDiOttoByteSenzaPuntatori;
    [Test]
    procedure DovrebbeTenereIValoriDelleCostantiDelFormato;
    [Test]
    procedure DovrebbeTenereLOrdineDeiTipiDiRecordDelRemake;
    [Test]
    procedure DovrebbeDareUnNomeAOgniStato;
    [Test]
    procedure DovrebbeLeggereUnWordLittleEndian;
    [Test]
    procedure DovrebbeLeggereUnCardinalLittleEndianSenzaSegno;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaFuoriDalBuffer;
  end;

implementation

{ TTestWarTypes }

procedure TTestWarTypes.DovrebbeAvereUnaIntestazioneDiOttoByteSenzaPuntatori;
begin
  // stessi byte a 32 e a 64 bit: due numeri da 32 bit e niente altro
  Assert.AreEqual(8, SizeOf(TWarArchiveHeader));
  Assert.AreEqual(WAR_ARCHIVE_HEADER_SIZE, SizeOf(TWarArchiveHeader));
  Assert.AreEqual(2 * SizeOf(Cardinal), SizeOf(TWarArchiveHeader));
end;

procedure TTestWarTypes.DovrebbeTenereIValoriDelleCostantiDelFormato;
begin
  Assert.AreEqual(586, WAR_MAX_RESOURCES_COUNT);
  Assert.AreEqual(Cardinal($18), Cardinal(WAR_ARCHIVE_ID_RETAIL_DOS));
  Assert.AreEqual(Cardinal($19), Cardinal(WAR_ARCHIVE_ID_DEMO));
  Assert.AreEqual(Cardinal($1A), Cardinal(WAR_ARCHIVE_ID_RETAIL_ALT));
  Assert.AreEqual(Cardinal($1FFFFFFF), Cardinal(WAR_LENGTH_MASK));
  Assert.AreEqual(Cardinal($E0000000), Cardinal(WAR_COMPRESSED_MASK));
  Assert.AreEqual(4096, WAR_WINDOW_SIZE);
end;

procedure TTestWarTypes.DovrebbeTenereLOrdineDeiTipiDiRecordDelRemake;
begin
  // DatabaseEntryType di war_enums.h: il catalogo generato usa questi numeri
  Assert.AreEqual(0, Ord(wrtUnknown));
  Assert.AreEqual(1, Ord(wrtImage));
  Assert.AreEqual(2, Ord(wrtPalette));
  Assert.AreEqual(7, Ord(wrtLevelInfo));
  Assert.AreEqual(10, Ord(wrtSprite));
  Assert.AreEqual(14, Ord(wrtTiles));
end;

procedure TTestWarTypes.DovrebbeDareUnNomeAOgniStato;
var
  LStatus: TWarRecordStatus;
begin
  for LStatus := Low(TWarRecordStatus) to High(TWarRecordStatus) do
    Assert.AreNotEqual('', WarRecordStatusName(LStatus));
  Assert.AreEqual('placeholder', WarRecordStatusName(wrsPlaceholder));
end;

procedure TTestWarTypes.DovrebbeLeggereUnWordLittleEndian;
begin
  Assert.AreEqual(Word($3412), TWarLittleEndian.ReadWord(TBytes.Create(0, $12, $34), 1));
end;

procedure TTestWarTypes.DovrebbeLeggereUnCardinalLittleEndianSenzaSegno;
begin
  Assert.AreEqual(Cardinal($F4030201), TWarLittleEndian.ReadCardinal(TBytes.Create(1, 2, 3, $F4), 0));
end;

procedure TTestWarTypes.DovrebbeRifiutareUnaLetturaFuoriDalBuffer;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarLittleEndian.ReadCardinal(TBytes.Create(1, 2, 3), 0);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarLittleEndian.ReadWord(TBytes.Create(1, 2), 1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarLittleEndian.ReadWord(TBytes.Create(1, 2), -1);
    end, EWarException);
end;

end.
