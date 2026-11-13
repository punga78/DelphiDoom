{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqDecoder on files built in memory                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Decoder;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  DelphiDoom.Cinematic.Intf;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqDecoder = class(TObject)
  strict private
    function Open(const ABytes: TBytes; const ASink: IRoqAudioSink = nil): IRoqDecoder;
    function SimpleFile(AFrames: Integer): TBytes;
  public
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonERoQ;
    [Test]
    procedure DovrebbeSollevareSeLIntestazioneETroncata;
    [Test]
    procedure DovrebbeLeggereIFotogrammiAlSecondo;
    [Test]
    procedure DovrebbeUsareTrentaFotogrammiSeIFpsSonoZero;
    [Test]
    procedure DovrebbeLeggereLeDimensioniDallInformazione;
    [Test]
    procedure DovrebbeDecodificareIFotogrammiInOrdine;
    [Test]
    procedure DovrebbeDareFalsoAllaFineDelFile;
    [Test]
    procedure DovrebbeDireCheCosaHaLettoPerOgniChunk;
    [Test]
    procedure DovrebbeSollevareSeUnFotogrammaPrecedeLInformazione;
    [Test]
    procedure DovrebbeSollevareSeUnFotogrammaPrecedeIlCodebook;
    [Test]
    procedure DovrebbeSollevareSeLeDimensioniNonSonoMultipleDiSedici;
    [Test]
    procedure DovrebbeSollevareSeLInformazioneEBreve;
    [Test]
    procedure DovrebbeSollevareSeUnChunkESuperioreAlMassimo;
    [Test]
    procedure DovrebbeSollevareSeUnChunkETroncato;
    [Test]
    procedure DovrebbeSollevareSeUnaIntestazioneDiChunkETroncata;
    [Test]
    procedure DovrebbeSaltareIChunkSconosciuti;
    [Test]
    procedure DovrebbeLeggereIChunkDentroUnPacchetto;
    [Test]
    procedure DovrebbeFinireConUnaIntestazioneDiFileACentro;
    [Test]
    procedure DovrebbeDareLAudioMonoComeStereoDoppio;
    [Test]
    procedure DovrebbeDareLAudioStereo;
    [Test]
    procedure DovrebbeIgnorareLAudioSenzaSink;
    [Test]
    procedure DovrebbeRicominciareConReset;
    [Test]
    procedure DovrebbeDareUnaCopiaDelFotogramma;
    [Test]
    procedure DovrebbeIgnorareUnaSecondaInformazioneDopoIlPrimoFotogramma;
    [Test]
    procedure DovrebbeUsareLAlphaDato;
  end;

implementation

uses
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqDecoder }

function TTestRoqDecoder.Open(const ABytes: TBytes; const ASink: IRoqAudioSink): IRoqDecoder;
begin
  Result := TCinematicFactory.CreateDecoder(TCinematicFactory.CreateMemorySource(ABytes), ASink);
end;

function TTestRoqDecoder.SimpleFile(AFrames: Integer): TBytes;
var
  LBuilder: TRoqTestBuilder;
  LIndex: Integer;
begin
  LBuilder := TRoqTestBuilder.Create(10);
  try
    LBuilder.Info(16, 16);
    LBuilder.Codebook(4, 2);
    for LIndex := 0 to AFrames - 1 do
      LBuilder.FullFrame16(LIndex);
    Result := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRoqDecoder.DovrebbeRifiutareUnFileCheNonERoQ;
begin
  Assert.WillRaise(
    procedure
    begin
      Open(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9));
    end, ERoqInvalidDataException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeLIntestazioneETroncata;
begin
  Assert.WillRaise(
    procedure
    begin
      Open(TBytes.Create($84, $10, 255));
    end, ERoqTruncatedException);
  Assert.WillRaise(
    procedure
    begin
      Open(nil);
    end, ERoqTruncatedException);
end;

procedure TTestRoqDecoder.DovrebbeLeggereIFotogrammiAlSecondo;
begin
  Assert.AreEqual(10, Open(SimpleFile(1)).FramesPerSecond);
end;

procedure TTestRoqDecoder.DovrebbeUsareTrentaFotogrammiSeIFpsSonoZero;
var
  LBuilder: TRoqTestBuilder;
begin
  LBuilder := TRoqTestBuilder.Create(0);
  try
    Assert.AreEqual(ROQ_DEFAULT_FPS, Open(LBuilder.ToBytes).FramesPerSecond);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRoqDecoder.DovrebbeLeggereLeDimensioniDallInformazione;
var
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LDecoder := Open(SimpleFile(1));
  Assert.AreEqual(0, LDecoder.Width);
  Assert.AreEqual(0, LDecoder.Height);
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckInfo), Ord(LKind));
  Assert.AreEqual(16, LDecoder.Width);
  Assert.AreEqual(16, LDecoder.Height);
end;

procedure TTestRoqDecoder.DovrebbeDecodificareIFotogrammiInOrdine;
var
  LDecoder: IRoqDecoder;
  LFirst, LSecond: TImagingPixels;
begin
  LDecoder := Open(SimpleFile(2));
  Assert.AreEqual(-1, LDecoder.FrameIndex);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(0, LDecoder.FrameIndex);
  LFirst := LDecoder.Frame;
  Assert.AreEqual(256, Integer(Length(LFirst)));
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(1, LDecoder.FrameIndex);
  LSecond := LDecoder.Frame;
  // vector 0 and vector 1 have different colors
  Assert.AreNotEqual(LFirst[0], LSecond[0]);
  // the 8x8 vectors double every pixel of the 4x4 ones
  Assert.AreEqual(LFirst[0], LFirst[1]);
end;

procedure TTestRoqDecoder.DovrebbeDareFalsoAllaFineDelFile;
var
  LDecoder: IRoqDecoder;
begin
  LDecoder := Open(SimpleFile(1));
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsFalse(LDecoder.NextFrame);
  Assert.IsFalse(LDecoder.NextFrame);
  Assert.AreEqual(0, LDecoder.FrameIndex);
end;

procedure TTestRoqDecoder.DovrebbeDireCheCosaHaLettoPerOgniChunk;
var
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
  LBuilder: TRoqTestBuilder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Codebook(1, 1);
    LBuilder.Chunk(ROQ_SOUND_MONO, 0, TRoqTestBuilder.Bytes([1, 2]));
    LBuilder.FullFrame16(0);
    LBuilder.Chunk($1234, 0, nil);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckInfo), Ord(LKind));
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckCodebook), Ord(LKind));
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckSound), Ord(LKind));
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckFrame), Ord(LKind));
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckOther), Ord(LKind));
  Assert.IsFalse(LDecoder.ReadChunk(LKind));
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeUnFotogrammaPrecedeLInformazione;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Codebook(1, 1);
    LBuilder.FullFrame16(0);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LDecoder.NextFrame;
    end, ERoqMissingInfoException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeUnFotogrammaPrecedeIlCodebook;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.FullFrame16(0);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LDecoder.NextFrame;
    end, ERoqMissingCodebookException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeLeDimensioniNonSonoMultipleDiSedici;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(20, 16);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LDecoder.ReadChunk(LKind);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeLInformazioneEBreve;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_QUAD_INFO, 0, TRoqTestBuilder.Bytes([16, 0, 16, 0]));
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LDecoder.ReadChunk(LKind);
    end, ERoqTruncatedException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeUnChunkESuperioreAlMassimo;
var
  LBytes: TBytes;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  // a header that says 65537 bytes
  LBytes := TRoqTestBuilder.Bytes([$84, $10, $FF, $FF, $FF, $FF, 24, 0, $11, $10, $01, $00, $01, 0, 0, 0]);
  LDecoder := Open(LBytes);
  Assert.WillRaise(
    procedure
    begin
      LDecoder.ReadChunk(LKind);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeUnChunkETroncato;
var
  LBytes: TBytes;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBytes := SimpleFile(1);
  SetLength(LBytes, Length(LBytes) - 3);
  LDecoder := Open(LBytes);
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.WillRaise(
    procedure
    begin
      LDecoder.ReadChunk(LKind);
    end, ERoqTruncatedException);
end;

procedure TTestRoqDecoder.DovrebbeSollevareSeUnaIntestazioneDiChunkETroncata;
var
  LBytes: TBytes;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBytes := TRoqTestBuilder.Bytes([$84, $10, $FF, $FF, $FF, $FF, 24, 0, $11, $10, 0]);
  LDecoder := Open(LBytes);
  Assert.WillRaise(
    procedure
    begin
      LDecoder.ReadChunk(LKind);
    end, ERoqTruncatedException);
end;

procedure TTestRoqDecoder.DovrebbeSaltareIChunkSconosciuti;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk($7777, 5, TRoqTestBuilder.Bytes([1, 2, 3]));
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([9, 9]));
    LBuilder.Info(16, 16);
    LBuilder.Codebook(1, 1);
    LBuilder.FullFrame16(0);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(0, LDecoder.FrameIndex);
end;

procedure TTestRoqDecoder.DovrebbeLeggereIChunkDentroUnPacchetto;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    // a packet is only a header: the chunks that it holds come after it
    LBuilder.Chunk(ROQ_PACKET, 2, nil);
    LBuilder.Info(16, 16);
    LBuilder.Codebook(1, 1);
    LBuilder.FullFrame16(0);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckOther), Ord(LKind));
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(16, LDecoder.Width);
end;

procedure TTestRoqDecoder.DovrebbeFinireConUnaIntestazioneDiFileACentro;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_FILE, 0, nil);
    LBuilder.Info(16, 16);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsFalse(LDecoder.ReadChunk(LKind));
end;

procedure TTestRoqDecoder.DovrebbeDareLAudioMonoComeStereoDoppio;
var
  LSink: TRoqRecordingSink;
  LHolder: IRoqAudioSink;
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LSink := TRoqRecordingSink.Create;
  LHolder := LSink;
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_SOUND_MONO, 100, TRoqTestBuilder.Bytes([1, 2]));
    LDecoder := Open(LBuilder.ToBytes, LHolder);
  finally
    LBuilder.Free;
  end;
  Assert.IsFalse(LDecoder.NextFrame);
  Assert.AreEqual(1, Integer(Length(LSink.Chunks)));
  Assert.AreEqual(2, LSink.Channels[0]);
  Assert.AreEqual(ROQ_SOUND_RATE, LSink.Rates[0]);
  Assert.AreEqual(4, Integer(Length(LSink.Chunks[0])));
  Assert.AreEqual(101, Integer(LSink.Chunks[0][0]));
  Assert.AreEqual(101, Integer(LSink.Chunks[0][1]));
  Assert.AreEqual(105, Integer(LSink.Chunks[0][2]));
  Assert.AreEqual(105, Integer(LSink.Chunks[0][3]));
end;

procedure TTestRoqDecoder.DovrebbeDareLAudioStereo;
var
  LSink: TRoqRecordingSink;
  LHolder: IRoqAudioSink;
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LSink := TRoqRecordingSink.Create;
  LHolder := LSink;
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_SOUND_STEREO, $0A05, TRoqTestBuilder.Bytes([1, 2]));
    LDecoder := Open(LBuilder.ToBytes, LHolder);
  finally
    LBuilder.Free;
  end;
  Assert.IsFalse(LDecoder.NextFrame);
  Assert.AreEqual(2, LSink.Channels[0]);
  Assert.AreEqual(2, Integer(Length(LSink.Chunks[0])));
  Assert.AreEqual($0A01, Integer(LSink.Chunks[0][0]));
  Assert.AreEqual($0504, Integer(LSink.Chunks[0][1]));
end;

procedure TTestRoqDecoder.DovrebbeIgnorareLAudioSenzaSink;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_SOUND_MONO, 0, TRoqTestBuilder.Bytes([1, 2]));
    LBuilder.Chunk(ROQ_SOUND_STEREO, 0, TRoqTestBuilder.Bytes([1, 2]));
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsFalse(LDecoder.NextFrame);
end;

procedure TTestRoqDecoder.DovrebbeRicominciareConReset;
var
  LDecoder: IRoqDecoder;
  LFirst: TImagingPixels;
begin
  LDecoder := Open(SimpleFile(2));
  Assert.IsTrue(LDecoder.NextFrame);
  LFirst := LDecoder.Frame;
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsFalse(LDecoder.NextFrame);
  LDecoder.Reset;
  Assert.AreEqual(-1, LDecoder.FrameIndex);
  Assert.AreEqual(0, LDecoder.Width);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(0, LDecoder.FrameIndex);
  Assert.AreEqual(PixelsCrc(LFirst), PixelsCrc(LDecoder.Frame));
end;

procedure TTestRoqDecoder.DovrebbeDareUnaCopiaDelFotogramma;
var
  LDecoder: IRoqDecoder;
  LFirst: TImagingPixels;
  LCrc: Cardinal;
begin
  LDecoder := Open(SimpleFile(2));
  LDecoder.NextFrame;
  LFirst := LDecoder.Frame;
  LCrc := PixelsCrc(LFirst);
  LDecoder.NextFrame;
  Assert.AreEqual(LCrc, PixelsCrc(LFirst));
end;

procedure TTestRoqDecoder.DovrebbeIgnorareUnaSecondaInformazioneDopoIlPrimoFotogramma;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Codebook(2, 1);
    LBuilder.FullFrame16(0);
    // the size in a second information chunk is not read
    LBuilder.Info(32, 32);
    LBuilder.FullFrame16(1);
    LDecoder := Open(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(16, LDecoder.Width);
  Assert.AreEqual(256, Integer(Length(LDecoder.Frame)));
end;

procedure TTestRoqDecoder.DovrebbeUsareLAlphaDato;
var
  LDecoder: IRoqDecoder;
begin
  LDecoder := TCinematicFactory.CreateDecoder(
    TCinematicFactory.CreateMemorySource(SimpleFile(1)), nil, 0);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(0, Integer(LDecoder.Frame[0] shr 24));
  LDecoder := Open(SimpleFile(1));
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual($FF, Integer(LDecoder.Frame[0] shr 24));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqDecoder);

end.
