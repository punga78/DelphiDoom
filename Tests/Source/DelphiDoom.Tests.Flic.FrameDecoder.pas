{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TFlicFrameDecoder (issue #229)                     }
{                                                                              }
{  The decoder that was TXcomFlcDecoder: the parity tests run it and a faithful }
{  copy of the old one (DelphiDoom.Tests.Flic.XcomReference) on the same files  }
{  and compare every frame, palette, delay and error byte for byte; the files   }
{  are built here (a valid set, every truncation of it and mutated copies of    }
{  it), no data of a game.                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Flic.FrameDecoder;

// the FNV-1a hash of the transcripts wraps around on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Flic.Types,
  DelphiDoom.Flic.FrameDecoder,
  DelphiDoom.Tests.Flic.XcomReference,
  DelphiDoom.Tests.XcomEngine.FlcBuilder;

type
  [TestFixture]
  [Category('flic')]
  TTestFlicFrameDecoder = class
  strict private
    class function Fnv(const ABytes: TBytes): Cardinal; static;
    class function RunShared(const AFile: TBytes): string; static;
    class function RunReference(const AFile: TBytes): string; static;
    class function FlcFile: TBytes; static;
    class function FliFile: TBytes; static;
    class function AudioFile: TBytes; static;
    class function FileSet: TArray<TBytes>; static;
    class function CopyPixels: TBytes; static;
    class function RaisesFormatError(const ABytes: TBytes): Boolean; static;
    function DecodeOne(const AFile: TBytes; out AColors: TArray<TFlicColor>): TBytes;
  public
    [Test]
    procedure DovrebbeAvereUnColoreDiQuattroByte;
    [Test]
    procedure DovrebbeRifiutareUnFilePiuCortoDellIntestazione;
    [Test]
    procedure DovrebbeRifiutareUnTipoSconosciuto;
    [Test]
    procedure DovrebbeCopiareUnFotogrammaNonCompresso;
    [Test]
    procedure DovrebbeConservareIlDifettoDiBlackCheAzzeraAltezzaPixelPerRiga;
    [Test]
    procedure DovrebbeConservareIlDifettoDelSaltoDiColor256ADuePacchetti;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioDecoderSuiFileCostruiti;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioDecoderSuOgniTroncamento;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioDecoderSuiFileMutati;
  end;

implementation

const
  PICTURE_WIDTH = 8;
  PICTURE_HEIGHT = 4;
  TARGET_PITCH = PICTURE_WIDTH + 3;
  TARGET_OFFSET = 5;
  TARGET_BYTES = TARGET_OFFSET + PICTURE_HEIGHT * TARGET_PITCH + 64;
  MUTATIONS_PER_FILE = 400;

{ TTestFlicFrameDecoder }

class function TTestFlicFrameDecoder.Fnv(const ABytes: TBytes): Cardinal;
var
  LIndex: Integer;
begin
  Result := $811C9DC5;
  for LIndex := 0 to High(ABytes) do
    Result := (Result xor ABytes[LIndex]) * 16777619;
end;

class function TTestFlicFrameDecoder.CopyPixels: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, PICTURE_WIDTH * PICTURE_HEIGHT);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(LIndex + 1);
end;

class function TTestFlicFrameDecoder.FlcFile: TBytes;
var
  LBuilder: TFlcBuilder;
begin
  LBuilder := TFlcBuilder.Create($AF12, PICTURE_WIDTH, PICTURE_HEIGHT, 6, 40);
  try
    // COLOR_256 with two packets (the skip of the second adds the count of the first) and BYTE_RUN
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_COLOR_256, [2, 0, 0, 2, 10, 20, 30, 40, 50, 60, 1, 2, 70, 80, 90, 100, 110, 120]);
    LBuilder.Chunk(FLC_BRUN, [1, 8, 5, 1, $F8, 1, 2, 3, 4, 5, 6, 7, 8, 2, 3, 9, $FB, 1, 2, 3, 4, 5, 1, 8, 0]);
    LBuilder.EndFrame;
    // DELTA_FLC with the "last pixel" opcode ($86: a low byte of 128 or more) and a fill of a pair
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_SS2, [2, 0, $86, $80, 1, 0, 0, 2, 11, 12, 13, 14, 1, 0, 1, $FF, 21, 22]);
    LBuilder.EndFrame;
    // DELTA_FLI and COLOR_64
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_LC, [1, 0, 2, 0, 2, 1, 2, 5, 6, 0, $FD, 7, 1, 0, 3, 1, 2, 3]);
    LBuilder.Chunk(FLC_COLOR_64, [1, 0, 3, 2, 63, 0, 31, 1, 2, 3]);
    LBuilder.EndFrame;
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_BLACK, []);
    LBuilder.EndFrame;
    LBuilder.CopyFrame(CopyPixels);
    LBuilder.Prefix([1, 2, 3, 4]);
    // a thumbnail chunk (18, skipped) and a COLOR_256 that goes past the end of the palette
    LBuilder.BeginFrame;
    LBuilder.Chunk(18, [9, 9, 9]);
    LBuilder.Chunk(FLC_COLOR_256, [1, 0, 254, 4, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    LBuilder.EndFrame;
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

class function TTestFlicFrameDecoder.FliFile: TBytes;
var
  LBuilder: TFlcBuilder;
begin
  // a FLI: the delay of the frame, or the speed of the header in 1/70 s when it is 0
  LBuilder := TFlcBuilder.Create($AF11, PICTURE_WIDTH, PICTURE_HEIGHT, 3, 3);
  try
    LBuilder.BeginFrame(0);
    LBuilder.Chunk(FLC_COLOR_64, [1, 0, 0, 2, 1, 2, 3, 4, 5, 6]);
    LBuilder.Chunk(FLC_BRUN, [1, 8, 5, 1, 8, 6, 1, 8, 7, 1, 8, 8]);
    LBuilder.EndFrame;
    LBuilder.BeginFrame(20);
    LBuilder.Chunk(FLC_LC, [0, 0, 1, 0, 1, 0, 2, 9, 9]);
    LBuilder.EndFrame;
    LBuilder.CopyFrame(CopyPixels, 7);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

class function TTestFlicFrameDecoder.AudioFile: TBytes;
var
  LBuilder: TFlcBuilder;
begin
  // the audio chunks of the videos of TFTD between the frames
  LBuilder := TFlcBuilder.Create($AF12, PICTURE_WIDTH, PICTURE_HEIGHT, 3, 40);
  try
    LBuilder.Audio(11025, [128, 129, 0, 255, 10, 20, 30, 40]);
    LBuilder.CopyFrame(CopyPixels);
    LBuilder.Audio(11025, [1, 2, 3, 4, 5, 6, 7, 8]);
    LBuilder.CopyFrame(CopyPixels);
    LBuilder.Prefix([1, 2]);
    LBuilder.Audio(8000, [90, 91, 92, 93]);
    LBuilder.CopyFrame(CopyPixels);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

class function TTestFlicFrameDecoder.FileSet: TArray<TBytes>;
begin
  Result := [FlcFile, FliFile, AudioFile];
end;

class function TTestFlicFrameDecoder.RunShared(const AFile: TBytes): string;
var
  LDecoder: TFlicFrameDecoder;
  LTarget: TBytes;
  LColors: TBytes;
  LSamples: TBytes;
  LIndex: Integer;
  LColor: Integer;
  LStored: TFlicColor;
  LCount: Integer;
begin
  Result := '';
  try
    LDecoder := TFlicFrameDecoder.Create(AFile);
  except
    on E: Exception do
      Exit('create:' + E.ClassName);
  end;
  try
    SetLength(LTarget, TARGET_BYTES);
    FillChar(LTarget[0], TARGET_BYTES, $11);
    SetLength(LColors, 1024);
    try
      for LIndex := 1 to 30 do
      begin
        if not LDecoder.FindFrame then
        begin
          Result := Result + 'nf;';
          Break;
        end;
        Result := Result + Format('d%d,%d;', [LDecoder.FrameDelay(False), LDecoder.FrameDelay(True)]);
        LDecoder.DecodeFrame(LTarget, TARGET_PITCH, TARGET_OFFSET, (LIndex mod 2) = 0);
        for LColor := 0 to 255 do
          begin
            LStored := LDecoder.Color(LColor);
            Move(LStored, LColors[LColor * 4], 4);
          end;
        Result := Result + Format('t%.8x,p%.8x,%d,%d;', [Fnv(LTarget), Fnv(LColors), Ord(LDecoder.Finished),
          LDecoder.FrameCount]);
      end;
    except
      on E: EFlicFormatException do
        Result := Result + Format('FMT,t%.8x;', [Fnv(LTarget)]);
      on E: Exception do
        Result := Result + E.ClassName + ';';
    end;
  finally
    LDecoder.Free;
  end;
  LDecoder := TFlicFrameDecoder.Create(AFile);
  try
    LCount := 0;
    try
      while (LCount < 10) and LDecoder.NextAudioChunk(LSamples) do
      begin
        Inc(LCount);
        Result := Result + Format('a%.8x,%d,%d,%d,%.8x;', [Fnv(LSamples), Ord(LDecoder.HasAudio),
          LDecoder.SampleRate, LDecoder.VideoDelay, Length(LDecoder.ToSigned16(LSamples, 0.5))]);
      end;
    except
      on E: EFlicFormatException do
        Result := Result + 'aFMT;';
      on E: Exception do
        Result := Result + 'a' + E.ClassName + ';';
    end;
  finally
    LDecoder.Free;
  end;
end;

class function TTestFlicFrameDecoder.RunReference(const AFile: TBytes): string;
var
  LDecoder: TReferenceFlcDecoder;
  LTarget: TBytes;
  LColors: TBytes;
  LSamples: TBytes;
  LIndex: Integer;
  LColor: Integer;
  LStored: TReferenceColor;
  LCount: Integer;
begin
  Result := '';
  try
    LDecoder := TReferenceFlcDecoder.Create(AFile);
  except
    on E: Exception do
      Exit('create:' + 'EFlicFormatException');
  end;
  try
    SetLength(LTarget, TARGET_BYTES);
    FillChar(LTarget[0], TARGET_BYTES, $11);
    SetLength(LColors, 1024);
    try
      for LIndex := 1 to 30 do
      begin
        if not LDecoder.FindFrame then
        begin
          Result := Result + 'nf;';
          Break;
        end;
        Result := Result + Format('d%d,%d;', [LDecoder.FrameDelay(False), LDecoder.FrameDelay(True)]);
        LDecoder.DecodeFrame(LTarget, TARGET_PITCH, TARGET_OFFSET, (LIndex mod 2) = 0);
        for LColor := 0 to 255 do
          begin
            LStored := LDecoder.Color(LColor);
            Move(LStored, LColors[LColor * 4], 4);
          end;
        Result := Result + Format('t%.8x,p%.8x,%d,%d;', [Fnv(LTarget), Fnv(LColors), Ord(LDecoder.Finished),
          LDecoder.FrameCount]);
      end;
    except
      on E: EReferenceFlcException do
        Result := Result + Format('FMT,t%.8x;', [Fnv(LTarget)]);
      on E: Exception do
        Result := Result + E.ClassName + ';';
    end;
  finally
    LDecoder.Free;
  end;
  LDecoder := TReferenceFlcDecoder.Create(AFile);
  try
    LCount := 0;
    try
      while (LCount < 10) and LDecoder.NextAudioChunk(LSamples) do
      begin
        Inc(LCount);
        Result := Result + Format('a%.8x,%d,%d,%d,%.8x;', [Fnv(LSamples), Ord(LDecoder.HasAudio),
          LDecoder.SampleRate, LDecoder.VideoDelay, Length(LDecoder.ToSigned16(LSamples, 0.5))]);
      end;
    except
      on E: EReferenceFlcException do
        Result := Result + 'aFMT;';
      on E: Exception do
        Result := Result + 'a' + E.ClassName + ';';
    end;
  finally
    LDecoder.Free;
  end;
end;

class function TTestFlicFrameDecoder.RaisesFormatError(const ABytes: TBytes): Boolean;
begin
  Result := False;
  try
    TFlicFrameDecoder.Create(ABytes).Free;
  except
    on EFlicFormatException do
      Result := True;
  end;
end;


function TTestFlicFrameDecoder.DecodeOne(const AFile: TBytes; out AColors: TArray<TFlicColor>): TBytes;
var
  LDecoder: TFlicFrameDecoder;
  LIndex: Integer;
begin
  LDecoder := TFlicFrameDecoder.Create(AFile);
  try
    SetLength(Result, TARGET_BYTES);
    FillChar(Result[0], TARGET_BYTES, 0);
    Assert.IsTrue(LDecoder.FindFrame);
    LDecoder.DecodeFrame(Result, TARGET_PITCH, TARGET_OFFSET, False);
    SetLength(AColors, 256);
    for LIndex := 0 to 255 do
      AColors[LIndex] := LDecoder.Color(LIndex);
  finally
    LDecoder.Free;
  end;
end;

procedure TTestFlicFrameDecoder.DovrebbeAvereUnColoreDiQuattroByte;
begin
  Assert.AreEqual(4, SizeOf(TFlicColor));
end;

procedure TTestFlicFrameDecoder.DovrebbeRifiutareUnFilePiuCortoDellIntestazione;
begin
  Assert.IsTrue(RaisesFormatError(TBytes.Create(1, 2, 3)));
end;

procedure TTestFlicFrameDecoder.DovrebbeRifiutareUnTipoSconosciuto;
var
  LBytes: TBytes;
begin
  LBytes := FlcFile;
  LBytes[4] := $34;
  Assert.IsTrue(RaisesFormatError(LBytes));
end;

procedure TTestFlicFrameDecoder.DovrebbeCopiareUnFotogrammaNonCompresso;
var
  LBuilder: TFlcBuilder;
  LPixels: TBytes;
  LColors: TArray<TFlicColor>;
  LRow: Integer;
  LColumn: Integer;
begin
  LBuilder := TFlcBuilder.Create($AF12, PICTURE_WIDTH, PICTURE_HEIGHT, 1, 40);
  try
    LBuilder.CopyFrame(CopyPixels);
    LPixels := DecodeOne(LBuilder.Build, LColors);
  finally
    LBuilder.Free;
  end;
  for LRow := 0 to PICTURE_HEIGHT - 1 do
    for LColumn := 0 to PICTURE_WIDTH - 1 do
      Assert.AreEqual(LRow * PICTURE_WIDTH + LColumn + 1,
        Integer(LPixels[TARGET_OFFSET + LRow * TARGET_PITCH + LColumn]));
end;

procedure TTestFlicFrameDecoder.DovrebbeConservareIlDifettoDiBlackCheAzzeraAltezzaPixelPerRiga;
var
  LBuilder: TFlcBuilder;
  LPixels: TBytes;
  LColors: TArray<TFlicColor>;
  LRow: Integer;
begin
  // the C++ clears "height" (4) pixels of each row, not "width" (8): the columns 4..7 keep what they had
  LBuilder := TFlcBuilder.Create($AF12, PICTURE_WIDTH, PICTURE_HEIGHT, 1, 40);
  try
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_COPY, CopyPixels);
    LBuilder.Chunk(FLC_BLACK, []);
    LBuilder.EndFrame;
    LPixels := DecodeOne(LBuilder.Build, LColors);
  finally
    LBuilder.Free;
  end;
  for LRow := 0 to PICTURE_HEIGHT - 1 do
  begin
    Assert.AreEqual(0, Integer(LPixels[TARGET_OFFSET + LRow * TARGET_PITCH + 3]));
    Assert.AreEqual(LRow * PICTURE_WIDTH + 5, Integer(LPixels[TARGET_OFFSET + LRow * TARGET_PITCH + 4]));
  end;
end;

procedure TTestFlicFrameDecoder.DovrebbeConservareIlDifettoDelSaltoDiColor256ADuePacchetti;
var
  LBuilder: TFlcBuilder;
  LPixels: TBytes;
  LColors: TArray<TFlicColor>;
begin
  // the second packet says "skip 1": the format puts it at the color 3 (1 + 2), the C++ adds the count of the
  // packet before and one more (1 + 2 + 1 = 4)
  LBuilder := TFlcBuilder.Create($AF12, PICTURE_WIDTH, PICTURE_HEIGHT, 1, 40);
  try
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_COLOR_256, [2, 0, 0, 2, 10, 20, 30, 40, 50, 60, 1, 2, 70, 80, 90, 100, 110, 120]);
    LBuilder.EndFrame;
    LPixels := DecodeOne(LBuilder.Build, LColors);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(50, Integer(LColors[1].Green));
  Assert.AreEqual(255, Integer(LColors[1].Alpha));
  Assert.AreEqual(0, Integer(LColors[3].Alpha));
  Assert.AreEqual(70, Integer(LColors[4].Red));
  Assert.AreEqual(120, Integer(LColors[5].Blue));
end;

procedure TTestFlicFrameDecoder.DovrebbeDareGliStessiByteDelVecchioDecoderSuiFileCostruiti;
var
  LFile: TBytes;
begin
  for LFile in FileSet do
    Assert.AreEqual(RunReference(LFile), RunShared(LFile));
end;

procedure TTestFlicFrameDecoder.DovrebbeDareGliStessiByteDelVecchioDecoderSuOgniTroncamento;
var
  LFile: TBytes;
  LLength: Integer;
begin
  for LFile in FileSet do
    for LLength := FLIC_FILE_HEADER_BYTES to Length(LFile) do
      Assert.AreEqual(RunReference(Copy(LFile, 0, LLength)), RunShared(Copy(LFile, 0, LLength)),
        Format('length %d', [LLength]));
end;

procedure TTestFlicFrameDecoder.DovrebbeDareGliStessiByteDelVecchioDecoderSuiFileMutati;
var
  LFile: TBytes;
  LMutated: TBytes;
  LHeaders: TArray<Boolean>;
  LPosition: Integer;
  LSize: Cardinal;
  LType: Word;
  LRun: Integer;
  LChanges: Integer;
  LAt: Integer;
begin
  RandSeed := 229;
  for LFile in FileSet do
  begin
    // the 16 bytes of a frame header are not touched: a prefix of size 0 would make both decoders loop for ever
    SetLength(LHeaders, Length(LFile));
    for LRun := 0 to High(LHeaders) do
      LHeaders[LRun] := LRun < FLIC_FILE_HEADER_BYTES;
    LPosition := FLIC_FILE_HEADER_BYTES;
    while LPosition + 16 <= Length(LFile) do
    begin
      LSize := LFile[LPosition] or (Cardinal(LFile[LPosition + 1]) shl 8);
      LType := LFile[LPosition + 4] or (Word(LFile[LPosition + 5]) shl 8);
      for LRun := LPosition to LPosition + 15 do
        LHeaders[LRun] := True;
      if LType = $AAAA then
        Inc(LPosition, Integer(LSize) + 16)
      else
        Inc(LPosition, Integer(LSize));
    end;
    for LRun := 1 to MUTATIONS_PER_FILE do
    begin
      LMutated := Copy(LFile);
      for LChanges := 0 to Random(3) do
      begin
        LAt := Random(Length(LMutated));
        if not LHeaders[LAt] then
          LMutated[LAt] := Random(256);
      end;
      Assert.AreEqual(RunReference(LMutated), RunShared(LMutated), Format('run %d', [LRun]));
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFlicFrameDecoder);

end.
