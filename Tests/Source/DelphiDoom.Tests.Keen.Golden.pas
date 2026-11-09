{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - parity with the original program     }
{                                                                              }
{  The file Tests\Data\Keen\KDGOLD.TXT is the answer of kdgold.exe, the         }
{  original id_ca.c and id_mm.c of the game built with Open Watcom, on the      }
{  files of the shareware 1.13 (Tests\Data\README.md). Every test needs         }
{  those files and is skipped if they are not on the machine                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Golden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-golden')]
  TTestKeenGolden = class(TObject)
  private
    FLines: TStringList;
    FData: IKeenGameData;
    function Crc(const ABytes: TBytes): string;
    function GoldenCrc(const AName: string; out ASize: Integer): string;
    procedure SkipIfMissing;
    function WordsToBytes(const AWords: TArray<Word>): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIlMarcatoreRlewEGliOffsetDellaTestata;
    [Test]
    procedure DovrebbeDareLeStesseIntestazioniDelleMappe;
    [Test]
    procedure DovrebbeDareGliStessiTrePianiDiOgniMappa;
    [Test]
    procedure DovrebbeDareLaStessaTabellaDelleImmagini;
    [Test]
    procedure DovrebbeDareGliStessiSessantacinqueBlocchiImmagine;
    [Test]
    procedure DovrebbeDareGliStessiTile8;
    [Test]
    procedure DovrebbeDareLeStesseInformazioniDeiTile;
    [Test]
    procedure DovrebbeEspandereOgniChunkDelFileGraficoELaDimensioneChePrevede;
    [Test]
    procedure DovrebbeEspandereOgniSuonoDelFileAudio;
    [Test]
    procedure DovrebbeLeggereLeTabelleDegliSprite;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.MathCore.Crc32,
  DelphiDoom.Tests.Keen.RealData;

const
  // the maps of the shareware: 0..16 and 20 (the others have no header)
  GOLDEN_MAPS: array[0..17] of Integer = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 20);

{ TTestKeenGolden }

procedure TTestKeenGolden.Setup;
var
  LFiles: IKeenDataFiles;
  LExtra: TStringList;
begin
  FLines := TStringList.Create;
  LFiles := TKeenRealData.OpenFiles;
  if Assigned(LFiles) then
  begin
    FData := TKeenFactory.OpenGameData(LFiles);
    FLines.LoadFromFile(TKeenRealData.GoldenPath);
    LExtra := TStringList.Create;
    try
      LExtra.LoadFromFile(TKeenRealData.GoldenExtraPath);
      FLines.AddStrings(LExtra);
    finally
      LExtra.Free;
    end;
  end;
end;

procedure TTestKeenGolden.TearDown;
begin
  FData := nil;
  FLines.Free;
end;

procedure TTestKeenGolden.SkipIfMissing;
begin
  if not Assigned(FData) then
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
end;

function TTestKeenGolden.Crc(const ABytes: TBytes): string;
begin
  if Length(ABytes) = 0 then
    Result := TCrc32.ToHex(0)
  else
    Result := TCrc32.ToHex(TCrc32.Calculate(ABytes[0], Length(ABytes)));
end;

/// <summary>The line "name size=N crc32=XXXXXXXX" of the golden file</summary>
function TTestKeenGolden.GoldenCrc(const AName: string; out ASize: Integer): string;
var
  LLine: string;
  LParts: TArray<string>;
begin
  Result := '';
  ASize := -1;
  for LLine in FLines do
    if LLine.StartsWith(AName + ' ') and LLine.Contains('crc32=') then
    begin
      LParts := LLine.Split([' '], TStringSplitOptions.ExcludeEmpty);
      ASize := StrToInt(LParts[1].Substring(5));
      Result := LParts[2].Substring(6);
      Exit;
    end;
  Assert.Fail('il golden non ha ' + AName);
end;

function TTestKeenGolden.WordsToBytes(const AWords: TArray<Word>): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AWords) * 2);
  for LIndex := 0 to High(AWords) do
  begin
    Result[LIndex * 2] := Byte(AWords[LIndex]);
    Result[LIndex * 2 + 1] := Byte(AWords[LIndex] shr 8);
  end;
end;

procedure TTestKeenGolden.DovrebbeLeggereIlMarcatoreRlewEGliOffsetDellaTestata;
begin
  SkipIfMissing;
  // "tinf_s=... RLEWtag=ABCD off0=5475 off1=8454 hs0=36 hs1=37"
  Assert.AreEqual($ABCD, Integer(FData.Maps.RlewTag));
  Assert.AreEqual(18, Length(FData.Maps.MapNumbers));
  Assert.IsTrue(FData.Maps.HasMap(0));
  Assert.IsTrue(FData.Maps.HasMap(1));
  Assert.IsFalse(FData.Maps.HasMap(17), 'la mappa 17 non c''e'' nello shareware');
  Assert.IsTrue(FData.Maps.HasMap(20));
end;

procedure TTestKeenGolden.DovrebbeDareLeStesseIntestazioniDelleMappe;
var
  LMapNumber: Integer;
  LMap: IKeenMap;
  LExpected: string;
  LLine: string;
  LFound: Boolean;
begin
  SkipIfMissing;
  for LMapNumber in GOLDEN_MAPS do
  begin
    LMap := FData.Maps.LoadMap(LMapNumber);
    LExpected := Format('map %d name=%s width=%d height=%d', [LMapNumber, LMap.Name, LMap.Width, LMap.Height]);
    LFound := False;
    for LLine in FLines do
      if LLine.TrimRight = LExpected then
        LFound := True;
    Assert.IsTrue(LFound, 'manca nel golden: ' + LExpected);
  end;
end;

procedure TTestKeenGolden.DovrebbeDareGliStessiTrePianiDiOgniMappa;
var
  LMapNumber: Integer;
  LMap: IKeenMap;
  LPlane: Integer;
  LName: string;
  LSize: Integer;
  LChecked: Integer;
begin
  SkipIfMissing;
  LChecked := 0;
  for LMapNumber in GOLDEN_MAPS do
  begin
    LMap := FData.Maps.LoadMap(LMapNumber);
    for LPlane := 0 to 2 do
    begin
      LName := Format('map%.2d_plane%d', [LMapNumber, LPlane]);
      Assert.AreEqual(GoldenCrc(LName, LSize), Crc(WordsToBytes(LMap.Planes[LPlane])), LName);
      Assert.AreEqual(LMap.Width * LMap.Height * 2, LSize, LName + ': dimensione');
      Inc(LChecked);
    end;
  end;
  Assert.AreEqual(54, LChecked);
end;

procedure TTestKeenGolden.DovrebbeDareLaStessaTabellaDelleImmagini;
var
  LTable: TArray<TKeenPictureEntry>;
  LBytes: TBytes;
  LIndex: Integer;
  LSize: Integer;
begin
  SkipIfMissing;
  LTable := FData.Graphics.PictureTable;
  Assert.AreEqual(KEEN_NUMPICS, Length(LTable));
  SetLength(LBytes, Length(LTable) * 4);
  for LIndex := 0 to High(LTable) do
  begin
    LBytes[LIndex * 4] := Byte(LTable[LIndex].Width);
    LBytes[LIndex * 4 + 1] := Byte(LTable[LIndex].Width shr 8);
    LBytes[LIndex * 4 + 2] := Byte(LTable[LIndex].Height);
    LBytes[LIndex * 4 + 3] := Byte(LTable[LIndex].Height shr 8);
  end;
  Assert.AreEqual(GoldenCrc('pictable', LSize), Crc(LBytes));
  Assert.AreEqual(260, LSize);
end;

procedure TTestKeenGolden.DovrebbeDareGliStessiSessantacinqueBlocchiImmagine;
var
  LTable: TArray<TKeenPictureEntry>;
  LIndex: Integer;
  LName: string;
  LSize: Integer;
begin
  SkipIfMissing;
  LTable := FData.Graphics.PictureTable;
  for LIndex := 0 to KEEN_NUMPICS - 1 do
  begin
    LName := Format('pic%.3d_w%d_h%d', [LIndex, LTable[LIndex].Width, LTable[LIndex].Height]);
    Assert.AreEqual(GoldenCrc(LName, LSize), Crc(FData.Graphics.PicturePlanar(LIndex)), LName);
    Assert.AreEqual(LTable[LIndex].Width * LTable[LIndex].Height * 4, LSize, LName + ': dimensione');
  end;
end;

procedure TTestKeenGolden.DovrebbeDareGliStessiTile8;
var
  LSize: Integer;
  LAll: TBytes;
  LIndex: Integer;
begin
  SkipIfMissing;
  // The shareware has the data of 40 8x8 tiles (and 30 masked ones) in the chunk of 72 (36) that graphkdr.h declares:
  // the C expands the 2304 (1440) bytes and what is after the data is whatever the file buffer had, so kdgold.exe
  // gives a CRC of 2304 bytes that cannot be the same. The first 1280 (1200) bytes are the same: their CRC is in
  // KDGOLD_EXTRA.TXT, taken from the -raw dump of kdgold.exe
  LAll := FData.Graphics.Chunks.Read(KEEN_STARTTILE8);
  Assert.AreEqual(2304, Length(LAll));
  Assert.AreEqual(GoldenCrc('tile8_first1280', LSize), Crc(Copy(LAll, 0, 1280)));
  Assert.AreEqual(1280, LSize);
  GoldenCrc('tile8_all', LSize);
  Assert.AreEqual(2304, LSize);
  // the single tiles are the slices of the chunk
  for LIndex := 0 to KEEN_NUMTILE8 - 1 do
    Assert.IsTrue(CompareMem(@LAll[LIndex * 32], @FData.Graphics.Tile8(LIndex)[0], 32));
  LAll := FData.Graphics.Chunks.Read(KEEN_STARTTILE8M);
  Assert.AreEqual(1440, Length(LAll));
  Assert.AreEqual(GoldenCrc('tile8m_first1200', LSize), Crc(Copy(LAll, 0, 1200)));
  Assert.AreEqual(1200, LSize);
  GoldenCrc('tile8m_all', LSize);
  Assert.AreEqual(1440, LSize);
end;

procedure TTestKeenGolden.DovrebbeDareLeStesseInformazioniDeiTile;
var
  LSize: Integer;
begin
  SkipIfMissing;
  Assert.AreEqual(GoldenCrc('tileinfo_block', LSize), Crc(FData.Maps.TileInfo.Bytes));
  Assert.AreEqual(KEEN_TINF_SIZE, LSize);
end;

procedure TTestKeenGolden.DovrebbeEspandereOgniChunkDelFileGraficoELaDimensioneChePrevede;
var
  LChunk: Integer;
  LCount: Integer;
  LSprites: Integer;
  LBytes: TBytes;
begin
  SkipIfMissing;
  LCount := 0;
  LSprites := 0;
  for LChunk := 0 to FData.Graphics.Chunks.ChunkCount - 1 do
  begin
    LBytes := FData.Graphics.Chunks.Read(LChunk);
    if FData.Graphics.Chunks.HasChunk(LChunk) then
    begin
      Inc(LCount);
      if (LChunk >= KEEN_STARTSPRITES) and (LChunk < KEEN_STARTTILE8) then
      begin
        Inc(LSprites);
        Assert.AreEqual(Integer(FData.Graphics.SpriteTable[LChunk - KEEN_STARTSPRITES].Width) *
          FData.Graphics.SpriteTable[LChunk - KEEN_STARTSPRITES].Height * 5, Length(LBytes),
          'sprite ' + IntToStr(LChunk - KEEN_STARTSPRITES));
      end;
      if LChunk >= KEEN_STARTTILE16 then
        Assert.IsTrue(Length(LBytes) in [KEEN_TILE16_BYTES, KEEN_TILE16M_BYTES], 'tile ' + IntToStr(LChunk));
    end
    else
      Assert.AreEqual(0, Length(LBytes));
  end;
  // 3016 chunks: 3 tables, the font, 65 + 2 pictures, 297 sprites, 2 groups of tiles, and the 16x16 tiles that are there
  Assert.IsTrue(LCount > 700, 'i chunk che ci sono: ' + IntToStr(LCount));
  Assert.AreEqual(KEEN_NUMSPRITES, LSprites, 'ogni sprite c''e''');
end;

procedure TTestKeenGolden.DovrebbeEspandereOgniSuonoDelFileAudio;
var
  LChunk: Integer;
  LBytes: TBytes;
  LWithData: Integer;
begin
  SkipIfMissing;
  Assert.AreEqual(KEEN_NUMSNDCHUNKS, FData.Audio.ChunkCount);
  LWithData := 0;
  for LChunk := 0 to FData.Audio.ChunkCount - 1 do
  begin
    LBytes := FData.Audio.Read(LChunk);
    if Length(LBytes) > 0 then
    begin
      Inc(LWithData);
      // every sound starts with SoundCommon (length and priority)
      Assert.IsTrue(Length(LBytes) >= SizeOf(TKeenSoundCommon), 'suono ' + IntToStr(LChunk));
    end;
  end;
  Assert.IsTrue(LWithData > 0);
end;

procedure TTestKeenGolden.DovrebbeLeggereLeTabelleDegliSprite;
var
  LTable: TArray<TKeenSpriteEntry>;
  LIndex: Integer;
begin
  SkipIfMissing;
  LTable := FData.Graphics.SpriteTable;
  Assert.AreEqual(KEEN_NUMSPRITES, Length(LTable));
  for LIndex := 0 to High(LTable) do
  begin
    Assert.IsTrue(LTable[LIndex].Width > 0, 'larghezza ' + IntToStr(LIndex));
    Assert.IsTrue(LTable[LIndex].Height > 0, 'altezza ' + IntToStr(LIndex));
    Assert.IsTrue(LTable[LIndex].Shifts in [1, 2, 4], 'shift ' + IntToStr(LIndex));
  end;
  Assert.AreEqual(2, Length(FData.Graphics.MaskedPictureTable));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenGolden);

end.
