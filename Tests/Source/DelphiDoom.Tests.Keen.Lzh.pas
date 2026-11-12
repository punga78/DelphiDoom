{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the LZH expansion against the   }
{  streams of the original compressor, the SoftLib library and the ILBM          }
{  picture of the title                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Lzh;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Tests\Data\Keen\lzh.golden.txt has seven buffers compressed by the original lzhuf.c (Tools\Verifica\165\lzh,
  ///   Open Watcom 16 bit in DOSBox): the port must expand each to the buffer, that Fill makes again here with the
  ///   generator of the harness
  /// </summary>
  [TestFixture]
  [Category('keen')]
  [Category('keen-parity')]
  TTestKeenLzh = class(TObject)
  strict private
    class function Fill(AKind, ASize: Integer): TBytes; static;
  public
    [Test]
    procedure DovrebbeEspandereOgniFlussoDelCompressoreOriginale;
    [Test]
    procedure DovrebbeDareNullaPerUnaLunghezzaZero;
    [Test]
    procedure IDatiCheFinisconoPrestoDovrebberoEssereLettiComeZeri;
    [Test]
    procedure DovrebbeRifiutareDatiFuoriDalBuffer;
    [Test]
    procedure DueChiamateNonDovrebberoCondividereLoStato;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenShapeLibrary = class(TObject)
  strict private
    class function MakeLibrary(const ANames: array of AnsiString; const AContents: array of TBytes;
      ACompression: Integer = 0): TBytes; static;
    class function MakeIlbm(AWidth, AHeight, ADepth, ACompression: Integer; const ABody: TBytes;
      AWithExtraChunk: Boolean): TBytes; static;
  public
    [Test]
    procedure IRecordDovrebberoAvereLeDimensioniDelC;
    [Test]
    procedure DovrebbeElencareETrovareIFile;
    [Test]
    procedure DovrebbeDareIDatiDiUnFileNonCompresso;
    [Test]
    procedure DiDueFileConLoStessoNomeDovrebbePrendereLUltimo;
    [Test]
    procedure DovrebbeDareEccezionePerUnFileCheManca;
    [Test]
    procedure DovrebbeRifiutareCioCheNonEUnaLibreria;
    [Test]
    procedure DovrebbeRifiutareUnaCompressioneSconosciuta;
    [Test]
    procedure DovrebbeLeggereLaTestataEIlCorpoDiUnIlbm;
    [Test]
    procedure DovrebbeRifiutareCioCheNonEUnIlbm;
    [Test]
    procedure DovrebbeDisegnareLeRigheNonCompressePianoPerPiano;
    [Test]
    procedure DovrebbeEspandereLeSerieELeCopie;
    [Test]
    procedure NonDovrebbeDisegnareIlByteDiRiempimentoDiUnaRigaDispari;
    [Test]
    procedure UnaSerieOltreLaRigaDovrebbeDareEccezione;
    [Test]
    procedure UnCorpoTroppoCortoDovrebbeDareEccezione;
    [Test]
    procedure LoSpostamentoDovrebbePuntareLeDuePagine;
    [Test]
    procedure IlTitoloDelloSharewareDovrebbeEssereUnImmagineDaTrecentoventiPerDuecento;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Keen.Lzh, DelphiDoom.Keen.ShapeLibrary, DelphiDoom.Keen.Shape,
  DelphiDoom.Keen.GameFactory, DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.DisplayCapture,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Keen.VideoFakes;

{ TTestKeenLzh }

class function TTestKeenLzh.Fill(AKind, ASize: Integer): TBytes;
const
  WORDS: AnsiString = 'the quick brown ';
  LETTERS: AnsiString = 'abcdefg';
var
  LSeed: Cardinal;
  LIndex: Integer;
  LValue: Cardinal;
begin
  SetLength(Result, ASize);
  LSeed := 12345 + Cardinal(AKind);
  for LIndex := 0 to ASize - 1 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    LValue := LSeed shr 24;
    case AKind of
      0: Result[LIndex] := Ord('K');
      1: Result[LIndex] := Ord('A');
      2: Result[LIndex] := Ord(WORDS[(LValue and 15) + 1]);
      3: Result[LIndex] := Byte(LValue);
      4:
        if (LValue and $C0) <> 0 then
          Result[LIndex] := Byte(LValue and $3F)
        else
          Result[LIndex] := Byte(LIndex shr 8);
      5: Result[LIndex] := Byte(Ord(LETTERS[(LIndex mod 7) + 1]) + ((LIndex div 700) and 1));
    else
      Result[LIndex] := Byte(LIndex * 3);
    end;
  end;
end;

procedure TTestKeenLzh.DovrebbeEspandereOgniFlussoDelCompressoreOriginale;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LKind: Integer;
  LSize: Integer;
  LCompressedLength: Integer;
  LCompressed: TBytes;
  LPosition: Integer;
  LIndex: Integer;
  LCases: Integer;
  LLzh: TKeenLzh;

  procedure CheckCase;
  var
    LExpected: TBytes;
    LActual: TBytes;
    LByte: Integer;
  begin
    if LKind < 0 then
      Exit;
    Assert.AreEqual(LCompressedLength, LPosition, Format('case %d: the hex lines', [LKind]));
    LExpected := Fill(LKind, LSize);
    LActual := LLzh.Decompress(LCompressed, 0, LCompressedLength, LSize);
    Assert.AreEqual(LSize, Length(LActual));
    for LByte := 0 to LSize - 1 do
      if LActual[LByte] <> LExpected[LByte] then
        Assert.Fail(Format('case %d: the byte %d is %d, the buffer has %d', [LKind, LByte, LActual[LByte],
          LExpected[LByte]]));
    Inc(LCases);
    LKind := -1;
  end;

begin
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Keen', 'lzh.golden.txt'));
  LLzh := TKeenLzh.Create;
  try
    LKind := -1;
    LCases := 0;
    LSize := 0;
    LCompressedLength := 0;
    LPosition := 0;
    for LLine in LLines do
    begin
      if LLine = '' then
        Continue;
      LParts := LLine.Split([' ']);
      case LLine[1] of
        'C':
          begin
            CheckCase;
            LKind := StrToInt(LParts[1]);
            LSize := StrToInt(LParts[2]);
            LCompressedLength := StrToInt(LParts[3]);
            SetLength(LCompressed, LCompressedLength);
            LPosition := 0;
          end;
        'H':
          for LIndex := 0 to (Length(LParts[1]) div 2) - 1 do
          begin
            LCompressed[LPosition] := Byte(StrToInt('$' + Copy(LParts[1], LIndex * 2 + 1, 2)));
            Inc(LPosition);
          end;
        'D':
          // the original expanded its own stream to the same buffer
          Assert.AreEqual('same', LParts[3]);
      end;
    end;
    CheckCase;
    Assert.AreEqual(7, LCases);
  finally
    LLzh.Free;
    LLines.Free;
  end;
end;

procedure TTestKeenLzh.DovrebbeDareNullaPerUnaLunghezzaZero;
var
  LLzh: TKeenLzh;
begin
  LLzh := TKeenLzh.Create;
  try
    Assert.AreEqual(0, Length(LLzh.Decompress(TBytes.Create(1, 2, 3), 0, 3, 0)));
  finally
    LLzh.Free;
  end;
end;

procedure TTestKeenLzh.IDatiCheFinisconoPrestoDovrebberoEssereLettiComeZeri;
var
  LLzh: TKeenLzh;
  LBytes: TBytes;
begin
  // the C reads 0 when the compressed length runs out (the last code often needs bits that are not there): the
  // expansion still gives all the bytes that were asked
  LLzh := TKeenLzh.Create;
  try
    LBytes := LLzh.Decompress(TBytes.Create($FF), 0, 1, 50);
    Assert.AreEqual(50, Length(LBytes));
    LBytes := LLzh.Decompress(nil, 0, 0, 10);
    Assert.AreEqual(10, Length(LBytes));
  finally
    LLzh.Free;
  end;
end;

procedure TTestKeenLzh.DovrebbeRifiutareDatiFuoriDalBuffer;
var
  LLzh: TKeenLzh;
begin
  LLzh := TKeenLzh.Create;
  try
    Assert.WillRaise(procedure begin LLzh.Decompress(TBytes.Create(1, 2, 3), 2, 5, 10); end, EKeenDataException);
    Assert.WillRaise(procedure begin LLzh.Decompress(TBytes.Create(1, 2, 3), -1, 2, 10); end, EKeenDataException);
    Assert.WillRaise(procedure begin LLzh.Decompress(TBytes.Create(1, 2, 3), 0, 2, -1); end, EKeenDataException);
  finally
    LLzh.Free;
  end;
end;

procedure TTestKeenLzh.DueChiamateNonDovrebberoCondividereLoStato;
var
  LLzh: TKeenLzh;
  LOther: TKeenLzh;
  LSource: TBytes;
  LFirst: TBytes;
  LSecond: TBytes;
  LFresh: TBytes;
begin
  // the tree and the window of the C are globals that a call leaves as they are: here the second call on the
  // same object gives what a new object gives
  LSource := TBytes.Create($12, $34, $56, $78, $9A, $BC, $DE, $F0, $11, $22, $33, $44, $55, $66, $77, $88);
  LLzh := TKeenLzh.Create;
  LOther := TKeenLzh.Create;
  try
    LFirst := LLzh.Decompress(LSource, 0, Length(LSource), 200);
    LSecond := LLzh.Decompress(LSource, 0, Length(LSource), 200);
    LFresh := LOther.Decompress(LSource, 0, Length(LSource), 200);
    Assert.AreEqual(LFirst, LSecond);
    Assert.AreEqual(LFirst, LFresh);
  finally
    LOther.Free;
    LLzh.Free;
  end;
end;

{ TTestKeenShapeLibrary }

class function TTestKeenShapeLibrary.MakeLibrary(const ANames: array of AnsiString; const AContents: array of TBytes;
  ACompression: Integer): TBytes;
var
  LStream: TBytesStream;
  LIndex: Integer;
  LEntry: TKeenSoftLibEntry;
  LChunk: TKeenSoftLibChunk;
  LHeader: TKeenSoftLibHeader;
  LOffset: Cardinal;
  LName: AnsiString;
const
  SIGNATURE: array[0..3] of AnsiChar = 'SLIB';
begin
  LStream := TBytesStream.Create;
  try
    LStream.WriteBuffer(SIGNATURE, 4);
    LHeader.Version := KEEN_SOFTLIB_VERSION;
    LHeader.FileCount := Length(ANames);
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    LOffset := 0;
    for LIndex := 0 to High(ANames) do
    begin
      FillChar(LEntry, SizeOf(LEntry), 0);
      LName := Copy(ANames[LIndex], 1, KEEN_SOFTLIB_NAME_SIZE);
      Move(LName[1], LEntry.FileName[0], Length(LName));
      LEntry.Offset := LOffset;
      LEntry.ChunkLength := SizeOf(LChunk) + Length(AContents[LIndex]);
      LEntry.OriginalLength := Length(AContents[LIndex]);
      LEntry.Compression := ACompression;
      LStream.WriteBuffer(LEntry, SizeOf(LEntry));
      Inc(LOffset, LEntry.ChunkLength);
    end;
    for LIndex := 0 to High(ANames) do
    begin
      LChunk.HeaderId[0] := 'C';
      LChunk.HeaderId[1] := 'U';
      LChunk.HeaderId[2] := 'N';
      LChunk.HeaderId[3] := 'K';
      LChunk.OriginalLength := Length(AContents[LIndex]);
      LChunk.Compression := ACompression;
      LStream.WriteBuffer(LChunk, SizeOf(LChunk));
      if Length(AContents[LIndex]) > 0 then
        LStream.WriteBuffer(AContents[LIndex][0], Length(AContents[LIndex]));
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TTestKeenShapeLibrary.MakeIlbm(AWidth, AHeight, ADepth, ACompression: Integer; const ABody: TBytes;
  AWithExtraChunk: Boolean): TBytes;
var
  LStream: TBytesStream;

  procedure Tag(const AName: AnsiString);
  begin
    LStream.WriteBuffer(AName[1], 4);
  end;

  procedure BigLong(AValue: Cardinal);
  var
    LBytes: array[0..3] of Byte;
  begin
    LBytes[0] := Byte(AValue shr 24);
    LBytes[1] := Byte(AValue shr 16);
    LBytes[2] := Byte(AValue shr 8);
    LBytes[3] := Byte(AValue);
    LStream.WriteBuffer(LBytes, 4);
  end;

  procedure BigWord(AValue: Word);
  var
    LBytes: array[0..1] of Byte;
  begin
    LBytes[0] := Byte(AValue shr 8);
    LBytes[1] := Byte(AValue);
    LStream.WriteBuffer(LBytes, 2);
  end;

  procedure OneByte(AValue: Byte);
  begin
    LStream.WriteBuffer(AValue, 1);
  end;

begin
  LStream := TBytesStream.Create;
  try
    Tag('FORM');
    BigLong(0);
    Tag('ILBM');
    Tag('BMHD');
    BigLong(20);
    BigWord(AWidth);
    BigWord(AHeight);
    BigWord(3);
    BigWord(4);
    OneByte(ADepth);
    OneByte(0);
    OneByte(ACompression);
    OneByte(0);
    BigWord(0);
    OneByte(10);
    OneByte(11);
    BigWord(320);
    BigWord(200);
    if AWithExtraChunk then
    begin
      // a chunk of an odd length that the reader skips with its pad byte
      Tag('CMAP');
      BigLong(3);
      OneByte(1);
      OneByte(2);
      OneByte(3);
      OneByte(0);
    end;
    Tag('BODY');
    BigLong(Length(ABody));
    if Length(ABody) > 0 then
      LStream.WriteBuffer(ABody[0], Length(ABody));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TTestKeenShapeLibrary.IRecordDovrebberoAvereLeDimensioniDelC;
begin
  Assert.AreEqual(4, SizeOf(TKeenSoftLibHeader));
  Assert.AreEqual(30, SizeOf(TKeenSoftLibEntry));
  Assert.AreEqual(10, SizeOf(TKeenSoftLibChunk));
end;

procedure TTestKeenShapeLibrary.DovrebbeElencareETrovareIFile;
var
  LLibrary: TKeenShapeLibrary;
  LNames: TArray<AnsiString>;
begin
  LLibrary := TKeenShapeLibrary.Create(MakeLibrary(['FIRST.LBM', 'SIXTEENLETTERS.X'], [TBytes.Create(1), TBytes.Create(2)]));
  try
    LNames := LLibrary.FileNames;
    Assert.AreEqual(2, Length(LNames));
    Assert.AreEqual(AnsiString('FIRST.LBM'), LNames[0]);
    Assert.AreEqual(AnsiString('SIXTEENLETTERS.X'), LNames[1], 'a name of 16 letters has no 0 after it');
    Assert.IsTrue(LLibrary.HasFile('first.lbm'), 'the names are compared without case');
    Assert.IsFalse(LLibrary.HasFile('SECOND.LBM'));
  finally
    LLibrary.Free;
  end;
end;

procedure TTestKeenShapeLibrary.DovrebbeDareIDatiDiUnFileNonCompresso;
var
  LLibrary: TKeenShapeLibrary;
begin
  LLibrary := TKeenShapeLibrary.Create(MakeLibrary(['A.BIN', 'B.BIN'], [TBytes.Create(1, 2, 3), TBytes.Create(9, 8)]));
  try
    Assert.AreEqual(TBytes.Create(1, 2, 3), LLibrary.LoadFile('A.BIN'));
    Assert.AreEqual(TBytes.Create(9, 8), LLibrary.LoadFile('b.bin'));
  finally
    LLibrary.Free;
  end;
end;

procedure TTestKeenShapeLibrary.DiDueFileConLoStessoNomeDovrebbePrendereLUltimo;
var
  LLibrary: TKeenShapeLibrary;
begin
  LLibrary := TKeenShapeLibrary.Create(MakeLibrary(['A.BIN', 'A.BIN'], [TBytes.Create(1), TBytes.Create(2)]));
  try
    Assert.AreEqual(TBytes.Create(2), LLibrary.LoadFile('A.BIN'));
  finally
    LLibrary.Free;
  end;
end;

procedure TTestKeenShapeLibrary.DovrebbeDareEccezionePerUnFileCheManca;
var
  LLibrary: TKeenShapeLibrary;
begin
  LLibrary := TKeenShapeLibrary.Create(MakeLibrary(['A.BIN'], [TBytes.Create(1)]));
  try
    Assert.WillRaise(procedure begin LLibrary.LoadFile('CREDITS.LBM'); end, EKeenFileNotFoundException);
  finally
    LLibrary.Free;
  end;
end;

procedure TTestKeenShapeLibrary.DovrebbeRifiutareCioCheNonEUnaLibreria;
var
  LBytes: TBytes;
begin
  Assert.WillRaise(procedure begin TKeenShapeLibrary.Create(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8)).Free; end,
    EKeenDataException);
  Assert.WillRaise(procedure begin TKeenShapeLibrary.Create(nil).Free; end, EKeenDataException);
  // a version that the game does not know
  LBytes := MakeLibrary(['A.BIN'], [TBytes.Create(1)]);
  LBytes[4] := 3;
  Assert.WillRaise(procedure begin TKeenShapeLibrary.Create(LBytes).Free; end, EKeenDataException);
  // a directory that says more files than the file has
  LBytes := MakeLibrary(['A.BIN'], [TBytes.Create(1)]);
  LBytes[6] := 200;
  Assert.WillRaise(procedure begin TKeenShapeLibrary.Create(LBytes).Free; end, EKeenDataException);
end;

procedure TTestKeenShapeLibrary.DovrebbeRifiutareUnaCompressioneSconosciuta;
var
  LLibrary: TKeenShapeLibrary;
  LBytes: TBytes;
begin
  // LZW (1) is of older libraries: its code is not in the sources of the game
  LLibrary := TKeenShapeLibrary.Create(MakeLibrary(['A.BIN'], [TBytes.Create(1, 2)], KEEN_CT_LZW));
  try
    Assert.WillRaise(procedure begin LLibrary.LoadFile('A.BIN'); end, EKeenDataException);
  finally
    LLibrary.Free;
  end;
  // a chunk without its "CUNK"
  LBytes := MakeLibrary(['A.BIN'], [TBytes.Create(1, 2)]);
  LBytes[4 + 4 + 30] := Ord('X');
  LLibrary := TKeenShapeLibrary.Create(LBytes);
  try
    Assert.WillRaise(procedure begin LLibrary.LoadFile('A.BIN'); end, EKeenDataException);
  finally
    LLibrary.Free;
  end;
end;

procedure TTestKeenShapeLibrary.DovrebbeLeggereLaTestataEIlCorpoDiUnIlbm;
var
  LShape: TKeenShape;
begin
  LShape := TKeenShapeReader.Parse(MakeIlbm(320, 200, 4, 1, TBytes.Create(5, 6, 7), True));
  Assert.AreEqual(320, Integer(LShape.Width));
  Assert.AreEqual(200, Integer(LShape.Height));
  Assert.AreEqual(3, Integer(LShape.X));
  Assert.AreEqual(4, Integer(LShape.Y));
  Assert.AreEqual(4, Integer(LShape.Depth));
  Assert.AreEqual(1, Integer(LShape.Compression));
  Assert.AreEqual(40, LShape.BytesPerRow);
  Assert.AreEqual(TBytes.Create(5, 6, 7), LShape.Data);
  // a width that is not a multiple of 8
  LShape := TKeenShapeReader.Parse(MakeIlbm(17, 2, 1, 0, TBytes.Create(1), False));
  Assert.AreEqual(3, LShape.BytesPerRow);
end;

procedure TTestKeenShapeLibrary.DovrebbeRifiutareCioCheNonEUnIlbm;
var
  LBytes: TBytes;
begin
  Assert.WillRaise(procedure begin TKeenShapeReader.Parse(TBytes.Create(1, 2, 3)); end, EKeenDataException);
  LBytes := MakeIlbm(8, 1, 1, 0, TBytes.Create(1), False);
  LBytes[8] := Ord('P');
  Assert.WillRaise(procedure begin TKeenShapeReader.Parse(LBytes); end, EKeenDataException);
  // no BODY: the file ends after the header
  LBytes := Copy(MakeIlbm(8, 1, 1, 0, TBytes.Create(1), False), 0, 40);
  Assert.WillRaise(procedure begin TKeenShapeReader.Parse(LBytes); end, EKeenDataException);
  // a BODY that says it is longer than the file
  LBytes := MakeIlbm(8, 1, 1, 0, TBytes.Create(1, 2, 3, 4), False);
  SetLength(LBytes, Length(LBytes) - 2);
  Assert.WillRaise(procedure begin TKeenShapeReader.Parse(LBytes); end, EKeenDataException);
end;

procedure TTestKeenShapeLibrary.DovrebbeDisegnareLeRigheNonCompressePianoPerPiano;
var
  LMemory: IKeenEgaMemory;
  LVideo: IKeenVideo;
  LShape: TKeenShape;
begin
  LMemory := TKeenEgaMemory.Create;
  LVideo := TKeenVideo.Create(LMemory, nil, nil);
  // 16 pixels by 2 rows, 4 planes, plain: for each row the two bytes of the plane 0, then of the plane 1...
  LShape := TKeenShapeReader.Parse(MakeIlbm(16, 2, 4, 0, TBytes.Create(
    $80, $01, $00, $01, $00, $00, $00, $01,
    $FF, $00, $FF, $00, $FF, $00, $FF, $00), False));
  LVideo.DisplayOfs := 1000;
  TKeenShapeReader.UnpackToScreen(LVideo, LShape, 16, 3);
  // the first pixel of the first row has only the plane 0: the color 1; the last pixel has the planes 0, 1 and 3
  Assert.AreEqual(1, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 16, 3)));
  Assert.AreEqual(11, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 31, 3)));
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 17, 3)));
  // the second row: the left byte white, the right one black
  Assert.AreEqual(15, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 20, 4)));
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 28, 4)));
  // nothing outside the picture
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 32, 3)));
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 1000, LVideo.LineWidth, 16, 5)));
end;

procedure TTestKeenShapeLibrary.DovrebbeEspandereLeSerieELeCopie;
var
  LMemory: IKeenEgaMemory;
  LVideo: IKeenVideo;
  LShape: TKeenShape;
  LX: Integer;
begin
  LMemory := TKeenEgaMemory.Create;
  LVideo := TKeenVideo.Create(LMemory, nil, nil);
  // 32 pixels, one plane, one row packed: a run of three $FF (the code -2) and one literal byte $0F (the code 0)
  LShape := TKeenShapeReader.Parse(MakeIlbm(32, 1, 1, 1, TBytes.Create($FE, $FF, $00, $0F), False));
  TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0);
  for LX := 0 to 23 do
    Assert.AreEqual(1, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, LX, 0)));
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 24, 0)));
  Assert.AreEqual(1, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 28, 0)));
end;

procedure TTestKeenShapeLibrary.NonDovrebbeDisegnareIlByteDiRiempimentoDiUnaRigaDispari;
var
  LMemory: IKeenEgaMemory;
  LVideo: IKeenVideo;
  LShape: TKeenShape;
begin
  LMemory := TKeenEgaMemory.Create;
  LVideo := TKeenVideo.Create(LMemory, nil, nil);
  // 24 pixels are 3 bytes a row, 4 in the file: the fourth byte ($FF here) is not drawn, in a plain row...
  LShape := TKeenShapeReader.Parse(MakeIlbm(24, 2, 1, 0, TBytes.Create($00, $00, $80, $FF, $00, $00, $01, $FF), False));
  TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0);
  Assert.AreEqual(1, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 16, 0)));
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 24, 0)), 'the pad byte');
  Assert.AreEqual(1, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 23, 1)), 'the second row starts after the pad');
  // ...and in a run that ends the row (four times $FF: only three are drawn)
  LMemory := TKeenEgaMemory.Create;
  LVideo := TKeenVideo.Create(LMemory, nil, nil);
  LShape := TKeenShapeReader.Parse(MakeIlbm(24, 1, 1, 1, TBytes.Create($FD, $FF), False));
  TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0);
  Assert.AreEqual(1, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 23, 0)));
  Assert.AreEqual(0, Integer(TFakeKeenPixels.Pixel(LMemory, 0, LVideo.LineWidth, 24, 0)));
end;

procedure TTestKeenShapeLibrary.UnaSerieOltreLaRigaDovrebbeDareEccezione;
var
  LVideo: IKeenVideo;
  LShape: TKeenShape;
begin
  LVideo := TKeenVideo.Create(TKeenEgaMemory.Create, nil, nil);
  // a run of 5 bytes in a row of 2: the C goes on in the video memory for ever
  LShape := TKeenShapeReader.Parse(MakeIlbm(16, 1, 1, 1, TBytes.Create($FC, $FF), False));
  Assert.WillRaise(procedure begin TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0); end, EKeenDataException);
  LShape := TKeenShapeReader.Parse(MakeIlbm(16, 1, 1, 1, TBytes.Create($04, 1, 2, 3, 4, 5), False));
  Assert.WillRaise(procedure begin TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0); end, EKeenDataException);
end;

procedure TTestKeenShapeLibrary.UnCorpoTroppoCortoDovrebbeDareEccezione;
var
  LVideo: IKeenVideo;
  LShape: TKeenShape;
begin
  LVideo := TKeenVideo.Create(TKeenEgaMemory.Create, nil, nil);
  LShape := TKeenShapeReader.Parse(MakeIlbm(16, 3, 1, 0, TBytes.Create(1, 2, 3), False));
  Assert.WillRaise(procedure begin TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0); end, EKeenDataException);
  // more planes than the card has
  LShape := TKeenShapeReader.Parse(MakeIlbm(16, 1, 5, 0, TBytes.Create(1, 2, 3), False));
  Assert.WillRaise(procedure begin TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0); end, EKeenDataException);
end;

procedure TTestKeenShapeLibrary.LoSpostamentoDovrebbePuntareLeDuePagine;
var
  LVideo: IKeenVideo;
begin
  LVideo := TKeenVideo.Create(TKeenEgaMemory.Create, nil, nil);
  TKeenShapeReader.MoveGfxDst(LVideo, 0, 200);
  Assert.AreEqual(64 * 200, LVideo.BufferOfs);
  Assert.AreEqual(64 * 200, LVideo.DisplayOfs);
  TKeenShapeReader.MoveGfxDst(LVideo, 24, 1);
  Assert.AreEqual(64 + 3, LVideo.DisplayOfs);
end;

procedure TTestKeenShapeLibrary.IlTitoloDelloSharewareDovrebbeEssereUnImmagineDaTrecentoventiPerDuecento;
var
  LPath: string;
  LLibrary: TKeenShapeLibrary;
  LIff: TBytes;
  LShape: TKeenShape;
  LMemory: IKeenEgaMemory;
  LVideo: IKeenVideo;
  LImage: TKeenChunkyImage;
  LColors: array[0..15] of Integer;
  LIndex: Integer;
  LUsed: Integer;
begin
  LPath := TTestFiles.FindFileUp('Reference\_dati\keen_build\riferimento\dati\KDREAMS.CMP');
  if LPath = '' then
    TTestSkip.Ignore('il KDREAMS.CMP dello shareware di Keen Dreams non e'' su questa macchina');
  LLibrary := TKeenShapeLibrary.Create(TFile.ReadAllBytes(LPath));
  try
    Assert.IsTrue(LLibrary.HasFile('TITLESCR.LBM'));
    LIff := LLibrary.LoadFile('TITLESCR.LBM');
  finally
    LLibrary.Free;
  end;
  // the expanded file is an IFF: its length is the one that FORM says, plus the 8 bytes of FORM itself
  Assert.AreEqual(Ord('F'), Integer(LIff[0]));
  Assert.AreEqual(Length(LIff), 8 + ((Integer(LIff[4]) shl 24) or (Integer(LIff[5]) shl 16) or (Integer(LIff[6]) shl 8) or
    Integer(LIff[7])));
  LShape := TKeenGameFactory.LoadTitle(TFile.ReadAllBytes(LPath));
  Assert.AreEqual(320, Integer(LShape.Width));
  Assert.AreEqual(200, Integer(LShape.Height));
  Assert.AreEqual(4, Integer(LShape.Depth));
  // the whole body is used by the 200 rows, no more and no less: the picture is drawn without an error
  LMemory := TKeenEgaMemory.Create;
  LVideo := TKeenVideo.Create(LMemory, nil, nil);
  TKeenShapeReader.UnpackToScreen(LVideo, LShape, 0, 0);
  LImage := TKeenDisplayCapture.CaptureVideo(LVideo);
  FillChar(LColors, SizeOf(LColors), 0);
  for LIndex := 0 to High(LImage.Pixels) do
    Inc(LColors[LImage.Pixels[LIndex]]);
  LUsed := 0;
  for LIndex := 0 to 15 do
    if LColors[LIndex] > 0 then
      Inc(LUsed);
  Assert.IsTrue(LUsed >= 8, 'a picture with many colors: ' + IntToStr(LUsed));
end;

end.
