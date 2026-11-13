{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the blockmap library - TBlockmapLumpReader             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Blockmap.LumpReader;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Blockmap.Types,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Blockmap.Factory;

type
  [TestFixture]
  [Category('blockmap')]
  TTestBlockmapLumpReader = class
  strict private
    FReader: IBlockmapLumpReader;
    class function MakeLump(const AWords: array of SmallInt): TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnLumpVuoto;
    [Test]
    procedure DovrebbeRifiutareUnLumpSenzaIntestazioneCompleta;
    [Test]
    procedure DovrebbeAccettareUnLumpConUnaCella;
    [Test]
    procedure DovrebbeRifiutareUnLumpDiTroppiValori;
    [Test]
    procedure DovrebbeRifiutareUnaIntestazioneChePromettePiuCelleDelleSue;
    [Test]
    procedure DovrebbeRifiutareColonneORigheNegative;
    [Test]
    procedure DovrebbeLeggereLIntestazioneConSegno;
    [Test]
    procedure DovrebbeTenereIlMenoUnoEDareIValoriSenzaSegnoAlResto;
    [Test]
    procedure DovrebbeLasciareIlWrapDisattivato;
  end;

implementation

{ TTestBlockmapLumpReader }

class function TTestBlockmapLumpReader.MakeLump(const AWords: array of SmallInt): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AWords) * 2);
  for LIndex := 0 to High(AWords) do
  begin
    Result[LIndex * 2] := Byte(Word(AWords[LIndex]) and $FF);
    Result[LIndex * 2 + 1] := Byte(Word(AWords[LIndex]) shr 8);
  end;
end;

procedure TTestBlockmapLumpReader.Setup;
begin
  FReader := TBlockmapFactory.CreateLumpReader;
end;

procedure TTestBlockmapLumpReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestBlockmapLumpReader.DovrebbeRifiutareUnLumpVuoto;
begin
  Assert.IsFalse(FReader.IsUsable(nil));
end;

procedure TTestBlockmapLumpReader.DovrebbeRifiutareUnLumpSenzaIntestazioneCompleta;
begin
  Assert.IsFalse(FReader.IsUsable(MakeLump([0, 0, 1])));
  // odd number of bytes: 3 whole values
  Assert.IsFalse(FReader.IsUsable(TBytes.Create(0, 0, 0, 0, 1, 0, 9)));
end;

procedure TTestBlockmapLumpReader.DovrebbeAccettareUnLumpConUnaCella;
begin
  Assert.IsTrue(FReader.IsUsable(MakeLump([0, 0, 1, 1, 5, 0, 0, -1])));
  // no cells at all
  Assert.IsTrue(FReader.IsUsable(MakeLump([0, 0, 0, 0])));
end;

procedure TTestBlockmapLumpReader.DovrebbeRifiutareUnLumpDiTroppiValori;
var
  LLump: TBytes;
begin
  SetLength(LLump, BLOCKMAP_MAX_LUMP_WORDS * 2);
  LLump[4] := 1;
  LLump[6] := 1;
  Assert.IsFalse(FReader.IsUsable(LLump), 'the offsets could not reach the end');
  SetLength(LLump, (BLOCKMAP_MAX_LUMP_WORDS - 1) * 2);
  Assert.IsTrue(FReader.IsUsable(LLump));
end;

procedure TTestBlockmapLumpReader.DovrebbeRifiutareUnaIntestazioneChePromettePiuCelleDelleSue;
begin
  // regression: the old code trusted the header and read offsets past the end of the lump
  Assert.IsFalse(FReader.IsUsable(MakeLump([0, 0, 3, 3, 13, 0, -1])));
end;

procedure TTestBlockmapLumpReader.DovrebbeRifiutareColonneORigheNegative;
begin
  Assert.IsFalse(FReader.IsUsable(MakeLump([0, 0, -2, -2, 5, 0, 0, -1])));
end;

procedure TTestBlockmapLumpReader.DovrebbeLeggereLIntestazioneConSegno;
var
  LData: TBlockmapData;
begin
  LData := FReader.Read(MakeLump([-768, -1024, 1, 1, 5, 0, 0, -1]));
  Assert.AreEqual(-768, LData.OriginX);
  Assert.AreEqual(-1024, LData.OriginY);
  Assert.AreEqual(1, LData.Columns);
  Assert.AreEqual(1, LData.Rows);
  Assert.AreEqual(-768, LData.Lump[0]);
  Assert.IsFalse(LData.Built);
end;

procedure TTestBlockmapLumpReader.DovrebbeTenereIlMenoUnoEDareIValoriSenzaSegnoAlResto;
var
  LData: TBlockmapData;
begin
  // $FFFE is line 65534 and $8000 is 32768; only $FFFF is the end of a list
  LData := FReader.Read(MakeLump([0, 0, 1, 1, 5, 0, -2, -32768, 7, -1]));
  Assert.AreEqual<Integer>(10, Length(LData.Lump));
  Assert.AreEqual(5, LData.Lump[4]);
  Assert.AreEqual(65534, LData.Lump[6]);
  Assert.AreEqual(32768, LData.Lump[7]);
  Assert.AreEqual(7, LData.Lump[8]);
  Assert.AreEqual(-1, LData.Lump[9]);
end;

procedure TTestBlockmapLumpReader.DovrebbeLasciareIlWrapDisattivato;
var
  LData: TBlockmapData;
begin
  LData := FReader.Read(MakeLump([0, 0, 1, 1, 5, 0, 0, -1]));
  Assert.AreEqual(BLOCKMAP_NEG_DISABLED, LData.NegX);
  Assert.AreEqual(BLOCKMAP_NEG_DISABLED, LData.NegY);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBlockmapLumpReader);

end.
