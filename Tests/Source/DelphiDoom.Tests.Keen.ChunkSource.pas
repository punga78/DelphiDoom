{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the files of chunks                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.ChunkSource;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Tests.Keen.Builders;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenChunkSource = class(TObject)
  private
    FGame: TTestGame;
    function Graphics: IKeenChunkSource;
    function Audio: IKeenChunkSource;
    function SameBytes(const AExpected, AActual: TBytes): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeContareITileDelFileGrafico;
    [Test]
    procedure DovrebbeEspandereUnChunkConLaLunghezzaEsplicita;
    [Test]
    procedure DovrebbeEspandereUnTileConLaLunghezzaImplicita;
    [Test]
    procedure DovrebbeEspandereTuttiITileInUnSoloChunk;
    [Test]
    procedure DovrebbeLeggereUnChunkAudioCheContinuaOltreLaFineDelFile;
    [Test]
    procedure DovrebbeDareVuotoUnChunkAudioCheIniziaOltreLaFineDelFile;
    [Test]
    procedure DovrebbeDareUnaRispostaVuotaPerUnChunkSenzaDati;
    [Test]
    procedure DovrebbeDareIByteCompressiCosiComeSono;
    [Test]
    procedure DovrebbeLeggereIChunkDelFileAudio;
    [Test]
    procedure DovrebbeTrattareDueOffsetUgualiComeUnChunkVuoto;
    [Test]
    procedure DovrebbeRifiutareUnChunkCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncato;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaEspansaEsagerata;
    [Test]
    procedure DovrebbeDareLeLunghezzeImplicitiDeiTile;
    [Test]
    procedure DovrebbeVolerOgniArgomento;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.GraphicsLayout, DelphiDoom.Keen.ExplicitLayout,
  DelphiDoom.Keen.ChunkSource;

{ TTestKeenChunkSource }

procedure TTestKeenChunkSource.Setup;
begin
  FGame := TTestGame.Create(1);
end;

procedure TTestKeenChunkSource.TearDown;
begin
  FGame.Free;
end;

function TTestKeenChunkSource.Graphics: IKeenChunkSource;
begin
  Result := TKeenFactory.CreateGraphicsChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('EGAHEAD.KDR'), 'EGAHEAD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('EGADICT.KDR')), FGame.Files.OpenStream('KDREAMS.EGA'));
end;

function TTestKeenChunkSource.Audio: IKeenChunkSource;
begin
  Result := TKeenFactory.CreateAudioChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('AUDIOHHD.KDR'), 'AUDIOHHD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('AUDIODCT.KDR')), FGame.Files.OpenStream('KDREAMS.AUD'));
end;

function TTestKeenChunkSource.SameBytes(const AExpected, AActual: TBytes): Boolean;
begin
  Result := (Length(AExpected) = Length(AActual)) and
    ((Length(AExpected) = 0) or CompareMem(@AExpected[0], @AActual[0], Length(AExpected)));
end;

procedure TTestKeenChunkSource.DovrebbeContareITileDelFileGrafico;
begin
  Assert.AreEqual(KEEN_NUMCHUNKS, Graphics.ChunkCount);
  Assert.AreEqual(KEEN_NUMSNDCHUNKS, Audio.ChunkCount);
end;

procedure TTestKeenChunkSource.DovrebbeEspandereUnChunkConLaLunghezzaEsplicita;
begin
  Assert.IsTrue(SameBytes(FGame.PictureTable, Graphics.Read(KEEN_STRUCTPIC)), 'pictable');
  Assert.IsTrue(SameBytes(FGame.Picture0, Graphics.Read(KEEN_STARTPICS)), 'immagine 0');
  Assert.IsTrue(SameBytes(FGame.Sprite0, Graphics.Read(KEEN_STARTSPRITES)), 'sprite 0');
end;

procedure TTestKeenChunkSource.DovrebbeEspandereUnTileConLaLunghezzaImplicita;
begin
  Assert.IsTrue(SameBytes(FGame.Tile16Zero, Graphics.Read(KEEN_STARTTILE16)));
  Assert.IsTrue(SameBytes(FGame.Tile16MaskedZero, Graphics.Read(KEEN_STARTTILE16M)));
end;

procedure TTestKeenChunkSource.DovrebbeEspandereTuttiITileInUnSoloChunk;
var
  LTiles: TBytes;
  LMasked: TBytes;
begin
  LTiles := Graphics.Read(KEEN_STARTTILE8);
  LMasked := Graphics.Read(KEEN_STARTTILE8M);
  // the size is the one of graphkdr.h whatever the data have
  Assert.AreEqual(KEEN_TILE8_BYTES * KEEN_NUMTILE8, Length(LTiles));
  Assert.AreEqual(KEEN_TILE8M_BYTES * KEEN_NUMTILE8M, Length(LMasked));
  Assert.IsTrue(SameBytes(Copy(FGame.Tile8All, 0, TEST_TILE8_PRESENT * KEEN_TILE8_BYTES),
    Copy(LTiles, 0, TEST_TILE8_PRESENT * KEEN_TILE8_BYTES)));
  Assert.IsTrue(SameBytes(Copy(FGame.Tile8MaskedAll, 0, TEST_TILE8M_PRESENT * KEEN_TILE8M_BYTES),
    Copy(LMasked, 0, TEST_TILE8M_PRESENT * KEEN_TILE8M_BYTES)));
end;

procedure TTestKeenChunkSource.DovrebbeLeggereUnChunkAudioCheContinuaOltreLaFineDelFile;
var
  LData: TBytes;
  LChunks: IKeenChunkSource;
  LResult: TBytes;
begin
  // the audio file of the shareware is shorter than its header says: a short read, the rest is zero
  LData := Copy(FGame.Files.ReadAll('KDREAMS.AUD'), 0, Length(FGame.Files.ReadAll('KDREAMS.AUD')) - 10);
  LChunks := TKeenFactory.CreateAudioChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('AUDIOHHD.KDR'), 'AUDIOHHD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('AUDIODCT.KDR')), TBytesStream.Create(LData));
  LResult := LChunks.Read(5);
  Assert.AreEqual(Length(FGame.Audio5), Length(LResult));
  Assert.IsTrue(SameBytes(Copy(FGame.Audio5, 0, 200), Copy(LResult, 0, 200)));
  Assert.IsTrue(SameBytes(FGame.Audio0, LChunks.Read(0)), 'i chunk interi sono uguali');
end;

procedure TTestKeenChunkSource.DovrebbeDareVuotoUnChunkAudioCheIniziaOltreLaFineDelFile;
var
  LChunks: IKeenChunkSource;
begin
  LChunks := TKeenFactory.CreateAudioChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('AUDIOHHD.KDR'), 'AUDIOHHD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('AUDIODCT.KDR')),
    TBytesStream.Create(Copy(FGame.Files.ReadAll('KDREAMS.AUD'), 0, 5)));
  Assert.AreEqual(0, Length(LChunks.Read(5)));
  Assert.AreEqual(0, Length(LChunks.ReadCompressed(5)));
end;

procedure TTestKeenChunkSource.DovrebbeDareUnaRispostaVuotaPerUnChunkSenzaDati;
var
  LGraphics: IKeenChunkSource;
begin
  LGraphics := Graphics;
  Assert.IsFalse(LGraphics.HasChunk(KEEN_STARTTILE16 + 1));
  Assert.AreEqual(0, Length(LGraphics.Read(KEEN_STARTTILE16 + 1)));
  Assert.AreEqual(0, Length(LGraphics.ReadCompressed(KEEN_STARTTILE16 + 1)));
  Assert.AreEqual(0, Length(LGraphics.Read(KEEN_NUMCHUNKS - 1)), 'l''ultimo chunk e'' vuoto e la sua fine e'' l''ultima voce');
end;

procedure TTestKeenChunkSource.DovrebbeDareIByteCompressiCosiComeSono;
var
  LCompressed: TBytes;
begin
  LCompressed := Graphics.ReadCompressed(KEEN_STRUCTPIC);
  Assert.IsTrue(Length(LCompressed) > 4);
  // the first 4 bytes are the expanded length
  Assert.AreEqual(Length(FGame.PictureTable), Integer(LCompressed[0]));
end;

procedure TTestKeenChunkSource.DovrebbeLeggereIChunkDelFileAudio;
var
  LAudio: IKeenChunkSource;
begin
  LAudio := Audio;
  Assert.IsTrue(SameBytes(FGame.Audio0, LAudio.Read(0)));
  Assert.IsTrue(SameBytes(FGame.Audio5, LAudio.Read(5)));
end;

procedure TTestKeenChunkSource.DovrebbeTrattareDueOffsetUgualiComeUnChunkVuoto;
var
  LAudio: IKeenChunkSource;
begin
  LAudio := Audio;
  Assert.IsFalse(LAudio.HasChunk(1));
  Assert.AreEqual(0, Length(LAudio.Read(1)));
  Assert.AreEqual(0, Length(LAudio.Read(83)));
end;

procedure TTestKeenChunkSource.DovrebbeRifiutareUnChunkCheNonCe;
var
  LGraphics: IKeenChunkSource;
begin
  LGraphics := Graphics;
  Assert.WillRaise(
    procedure
    begin
      LGraphics.Read(KEEN_NUMCHUNKS);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      LGraphics.HasChunk(-1);
    end, EKeenDataException);
end;

procedure TTestKeenChunkSource.DovrebbeRifiutareUnFileTroncato;
var
  LChunks: IKeenChunkSource;
begin
  // the header says that the data are longer than the file
  LChunks := TKeenFactory.CreateGraphicsChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('EGAHEAD.KDR'), 'EGAHEAD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('EGADICT.KDR')),
    TBytesStream.Create(Copy(FGame.Files.ReadAll('KDREAMS.EGA'), 0, 20)));
  Assert.WillRaise(
    procedure
    begin
      LChunks.Read(KEEN_STARTTILE16);
    end, EKeenDataException);
end;

procedure TTestKeenChunkSource.DovrebbeRifiutareUnaLunghezzaEspansaEsagerata;
var
  LData: TBytes;
  LChunks: IKeenChunkSource;
begin
  // the first chunk starts with a length of 2 GB
  LData := Copy(FGame.Files.ReadAll('KDREAMS.EGA'));
  LData[0] := 0;
  LData[1] := 0;
  LData[2] := 0;
  LData[3] := $7F;
  LChunks := TKeenFactory.CreateGraphicsChunks(
    TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('EGAHEAD.KDR'), 'EGAHEAD.KDR'),
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('EGADICT.KDR')), TBytesStream.Create(LData));
  Assert.WillRaise(
    procedure
    begin
      LChunks.Read(KEEN_STRUCTPIC);
    end, EKeenDataException);
end;

procedure TTestKeenChunkSource.DovrebbeDareLeLunghezzeImplicitiDeiTile;
var
  LLayout: IKeenChunkLayout;
begin
  LLayout := TKeenGraphicsLayout.Create;
  Assert.AreEqual(-1, LLayout.ImplicitLength(KEEN_STARTTILE8 - 1), 'ultimo sprite');
  Assert.AreEqual(2304, LLayout.ImplicitLength(KEEN_STARTTILE8));
  Assert.AreEqual(1440, LLayout.ImplicitLength(KEEN_STARTTILE8M));
  Assert.AreEqual(128, LLayout.ImplicitLength(KEEN_STARTTILE16));
  Assert.AreEqual(128, LLayout.ImplicitLength(KEEN_STARTTILE16M - 1));
  Assert.AreEqual(160, LLayout.ImplicitLength(KEEN_STARTTILE16M));
  Assert.AreEqual(160, LLayout.ImplicitLength(KEEN_NUMCHUNKS - 1));
  Assert.AreEqual(-1, (TKeenExplicitLayout.Create as IKeenChunkLayout).ImplicitLength(KEEN_STARTTILE16));
  // the chunks that may have less data than they say
  Assert.IsTrue(LLayout.IsLenient(KEEN_STARTTILE8));
  Assert.IsTrue(LLayout.IsLenient(KEEN_STARTTILE8M));
  Assert.IsFalse(LLayout.IsLenient(KEEN_STARTTILE16));
  Assert.IsFalse(LLayout.IsLenient(KEEN_STARTPICS));
  Assert.IsFalse((TKeenExplicitLayout.Create as IKeenChunkLayout).IsLenient(3));
  Assert.IsTrue((TKeenExplicitLayout.Create(True) as IKeenChunkLayout).IsLenient(3));
end;

procedure TTestKeenChunkSource.DovrebbeVolerOgniArgomento;
var
  LOffsets: IKeenOffsetTable;
  LHuffman: IKeenHuffman;
  LLayout: IKeenChunkLayout;
  LStream: TStream;
begin
  LOffsets :=TKeenFactory.CreateOffsetTable(FGame.Files.ReadAll('AUDIOHHD.KDR'), 'AUDIOHHD.KDR');
  LHuffman := TKeenFactory.CreateHuffman(FGame.Files.ReadAll('AUDIODCT.KDR'));
  LLayout := TKeenExplicitLayout.Create;
  LStream := TMemoryStream.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        TKeenChunkSource.Create(nil, LHuffman, LLayout, LStream);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TKeenChunkSource.Create(LOffsets, nil, LLayout, LStream);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TKeenChunkSource.Create(LOffsets, LHuffman, nil, LStream);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TKeenChunkSource.Create(LOffsets, LHuffman, LLayout, nil);
      end, EArgumentNilException);
  finally
    LStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenChunkSource);

end.
