{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomFlcDecoder (the FLI/FLC animations) on files  }
{  built in memory; the expected pixels are worked out by hand from the code    }
{  of FlcPlayer of OpenXcom                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FlcDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.FlcDecoder,
  DelphiDoom.Tests.XcomEngine.FlcBuilder;

type
  [TestFixture]
  [Category('XcomFlc')]
  TTestXcomFlcDecoder = class
  strict private
    FBuilder: TFlcBuilder;
    FDecoder: TXcomFlcDecoder;
    FTarget: TBytes;
    /// <summary>A FLC of 4 x 3 pixels; the target is 6 x 5 and the picture starts at row 1, column 1</summary>
    procedure NewFile(AType: Word = XCOM_FLC_TYPE_FLC; ASpeed: Integer = 40);
    procedure Open;
    procedure DecodeNext(ASkipLast: Boolean = False);
    function Row(ARow: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnFilePiuCortoDellIntestazione;
    [Test]
    procedure DovrebbeRifiutareUnTipoSconosciuto;
    [Test]
    procedure DovrebbeLeggereLIntestazione;
    [Test]
    procedure DovrebbeCopiareUnFotogrammaNonCompresso;
    [Test]
    procedure DovrebbeDecodificareBRunConRiempimentiELetterali;
    [Test]
    procedure DovrebbeDecodificareIlDeltaLC;
    [Test]
    procedure DovrebbeDecodificareIlDeltaSS2ConSaltoDiRigheECoppie;
    [Test]
    procedure DovrebbeScrivereLUltimoByteDellaRigaInSS2;
    [Test]
    procedure DovrebbeAzzerareAltezzaPixelPerRigaConBlack;
    [Test]
    procedure DovrebbeLeggereIColoriA6BitPer4;
    [Test]
    procedure DovrebbeLeggereIColoriA8BitConIlSalto;
    [Test]
    procedure DovrebbeSaltareIPrefissiELAudioCercandoIlFotogramma;
    [Test]
    procedure DovrebbeFinireSullUltimoFotogrammaESaltarloSeRichiesto;
    [Test]
    procedure DovrebbeFinireSeCioCheSegueNonEUnFotogramma;
    [Test]
    procedure DovrebbeDareIlRitardoDiUnFli;
    [Test]
    procedure DovrebbeDareIlRitardoDiUnFlc;
    [Test]
    procedure DovrebbeLeggereIPezziAudioEIlLoroRitardo;
    [Test]
    procedure DovrebbeConvertireICampioniA16Bit;
    [Test]
    procedure DovrebbeDareErroreSeIlPezzoLeggeOltreIlFile;
    [Test]
    procedure DovrebbeDareErroreSeIlPezzoScriveFuoriDalQuadro;
    [Test]
    procedure DovrebbeContareIFotogrammiECambiareVelocita;
  end;

implementation

const
  PICTURE_WIDTH = 4;
  PICTURE_HEIGHT = 3;
  TARGET_PITCH = 6;
  TARGET_ROWS = 5;
  TARGET_OFFSET = TARGET_PITCH + 1;

procedure TTestXcomFlcDecoder.Setup;
begin
  FBuilder := nil;
  FDecoder := nil;
  SetLength(FTarget, TARGET_PITCH * TARGET_ROWS);
  FillChar(FTarget[0], Length(FTarget), 9);
end;

procedure TTestXcomFlcDecoder.TearDown;
begin
  FDecoder.Free;
  FBuilder.Free;
end;

procedure TTestXcomFlcDecoder.NewFile(AType: Word; ASpeed: Integer);
begin
  FBuilder := TFlcBuilder.Create(AType, PICTURE_WIDTH, PICTURE_HEIGHT, 2, ASpeed);
end;

procedure TTestXcomFlcDecoder.Open;
begin
  FDecoder := TXcomFlcDecoder.Create(FBuilder.Build);
end;

procedure TTestXcomFlcDecoder.DecodeNext(ASkipLast: Boolean);
begin
  Assert.IsTrue(FDecoder.FindFrame, 'un fotogramma');
  FDecoder.DecodeFrame(FTarget, TARGET_PITCH, TARGET_OFFSET, ASkipLast);
end;

function TTestXcomFlcDecoder.Row(ARow: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to TARGET_PITCH - 1 do
    Result := Result + IntToStr(FTarget[ARow * TARGET_PITCH + LIndex]);
end;

procedure TTestXcomFlcDecoder.DovrebbeRifiutareUnFilePiuCortoDellIntestazione;
begin
  Assert.WillRaise(
    procedure
    var
      LBytes: TBytes;
    begin
      SetLength(LBytes, 100);
      TXcomFlcDecoder.Create(LBytes).Free;
    end, EXcomFlcException);
end;

procedure TTestXcomFlcDecoder.DovrebbeRifiutareUnTipoSconosciuto;
begin
  FBuilder := TFlcBuilder.Create($1234, 4, 3, 1, 5);
  Assert.WillRaise(
    procedure
    begin
      Open;
    end, EXcomFlcException);
end;

procedure TTestXcomFlcDecoder.DovrebbeLeggereLIntestazione;
begin
  FBuilder := TFlcBuilder.Create(XCOM_FLC_TYPE_FLI, 320, 200, 900, 5);
  Open;
  Assert.IsTrue(FDecoder.IsFli);
  Assert.AreEqual(320, Integer(FDecoder.Width));
  Assert.AreEqual(200, Integer(FDecoder.Height));
  Assert.AreEqual(900, Integer(FDecoder.Frames));
  Assert.AreEqual(8, Integer(FDecoder.Depth));
  Assert.AreEqual(5, Integer(FDecoder.Speed));
  Assert.AreEqual(0, FDecoder.FrameCount);
  Assert.IsFalse(FDecoder.Finished);
end;

procedure TTestXcomFlcDecoder.DovrebbeCopiareUnFotogrammaNonCompresso;
begin
  NewFile;
  FBuilder.CopyFrame([1, 2, 3, 4, 5, 6, 7, 8, 1, 3, 5, 7]);
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  Assert.AreEqual('999999', Row(0), 'la riga sopra il quadro non si tocca');
  Assert.AreEqual('912349', Row(1));
  Assert.AreEqual('956789', Row(2));
  Assert.AreEqual('913579', Row(3));
  Assert.AreEqual('999999', Row(4));
  Assert.AreEqual(1, FDecoder.FrameCount);
end;

procedure TTestXcomFlcDecoder.DovrebbeDecodificareBRunConRiempimentiELetterali;
begin
  NewFile;
  FBuilder.BeginFrame;
  // per row: the packet count (ignored), then a positive count fills and a negative one copies
  FBuilder.Chunk(FLC_BRUN, [
    1, 4, 7,
    2, 2, 5, Byte(-2), 1, 2,
    2, Byte(-1), 8, 0, 3, 6]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  Assert.AreEqual('977779', Row(1));
  Assert.AreEqual('955129', Row(2));
  Assert.AreEqual('986669', Row(3), 'un conteggio 0 non fa nulla e si va avanti');
end;

procedure TTestXcomFlcDecoder.DovrebbeDecodificareIlDeltaLC;
begin
  NewFile;
  FBuilder.CopyFrame([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
  FBuilder.BeginFrame;
  // skip one row, two rows change: row 1 has a literal after one pixel; row 2 a fill of three after one pixel
  FBuilder.Chunk(FLC_LC, [
    1, 0, 2, 0,
    1, 1, 2, 4, 5,
    1, 1, Byte(-3), 8]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  DecodeNext;
  Assert.AreEqual('911119', Row(1));
  Assert.AreEqual('914519', Row(2));
  Assert.AreEqual('918889', Row(3));
end;

procedure TTestXcomFlcDecoder.DovrebbeDecodificareIlDeltaSS2ConSaltoDiRigheECoppie;
begin
  NewFile;
  FBuilder.CopyFrame([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
  FBuilder.BeginFrame;
  // two lines: the first word -1 ($FFFF) skips one row and does not count as a line; then one packet that
  // copies a pair (4, 5); then a line with one packet that skips two pixels and repeats the pair (7, 8) once
  FBuilder.Chunk(FLC_SS2, [
    2, 0,
    $FF, $FF,
    1, 0, 0, 1, 4, 5,
    1, 0, 2, Byte(-1), 7, 8]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  DecodeNext;
  Assert.AreEqual('911119', Row(1));
  Assert.AreEqual('945119', Row(2));
  Assert.AreEqual('911789', Row(3));
end;

procedure TTestXcomFlcDecoder.DovrebbeScrivereLUltimoByteDellaRigaInSS2;
begin
  NewFile;
  FBuilder.CopyFrame([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
  FBuilder.BeginFrame;
  // $8003: the last byte of the row is 3; then the packet count (0 packets). The C++ writes it at the end of
  // the row of the SCREEN (row start + pitch - 1), not of the picture
  FBuilder.Chunk(FLC_SS2, [1, 0, $03, $80, 0, 0]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  DecodeNext;
  Assert.AreEqual('911119', Row(1));
  Assert.AreEqual('311119', Row(2), 'riga 1 del quadro piu'' passo meno 1: la prima colonna della riga dopo');
end;

procedure TTestXcomFlcDecoder.DovrebbeAzzerareAltezzaPixelPerRigaConBlack;
begin
  NewFile;
  FBuilder.CopyFrame([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
  FBuilder.BeginFrame;
  FBuilder.Chunk(FLC_BLACK, []);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  DecodeNext;
  // memset(row, 0, height): three pixels of four
  Assert.AreEqual('900019', Row(1));
  Assert.AreEqual('900019', Row(2));
  Assert.AreEqual('900019', Row(3));
end;

procedure TTestXcomFlcDecoder.DovrebbeLeggereIColoriA6BitPer4;
var
  LFirst: Integer;
  LCount: Integer;
begin
  NewFile;
  FBuilder.BeginFrame;
  FBuilder.Chunk(FLC_COLOR_64, [1, 0, 10, 2, 63, 1, 2, 3, 4, 5]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  LFirst := -1;
  LCount := -1;
  FDecoder.OnPalette :=
    procedure(AFirst, ACount: Integer)
    begin
      LFirst := AFirst;
      LCount := ACount;
    end;
  DecodeNext;
  Assert.AreEqual(10, LFirst);
  Assert.AreEqual(2, LCount);
  Assert.AreEqual(252, Integer(FDecoder.Color(10).Red));
  Assert.AreEqual(4, Integer(FDecoder.Color(10).Green));
  Assert.AreEqual(8, Integer(FDecoder.Color(10).Blue));
  Assert.AreEqual(12, Integer(FDecoder.Color(11).Red));
  Assert.AreEqual(20, Integer(FDecoder.Color(11).Blue));
end;

procedure TTestXcomFlcDecoder.DovrebbeLeggereIColoriA8BitConIlSalto;
var
  LCalls: string;
begin
  NewFile;
  FBuilder.BeginFrame;
  // two packets: skip 5, one color; then skip 3, one color. The C++ adds to the second skip the count of the
  // packet before plus one: 3 + 2 = color 5 again
  FBuilder.Chunk(FLC_COLOR_256, [2, 0, 5, 1, 200, 100, 50, 3, 1, 1, 2, 3]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  LCalls := '';
  FDecoder.OnPalette :=
    procedure(AFirst, ACount: Integer)
    begin
      LCalls := LCalls + Format('%d+%d;', [AFirst, ACount]);
    end;
  DecodeNext;
  Assert.AreEqual('5+1;5+1;', LCalls);
  Assert.AreEqual(1, Integer(FDecoder.Color(5).Red));
  Assert.AreEqual(3, Integer(FDecoder.Color(5).Blue));
  Assert.AreEqual(255, Integer(FDecoder.Color(5).Alpha));
end;

procedure TTestXcomFlcDecoder.DovrebbeSaltareIPrefissiELAudioCercandoIlFotogramma;
begin
  NewFile;
  FBuilder.Prefix([1, 2, 3, 4]);
  FBuilder.Audio(11025, [128, 129, 130]);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  DecodeNext;
  Assert.AreEqual('922229', Row(1));
end;

procedure TTestXcomFlcDecoder.DovrebbeFinireSullUltimoFotogrammaESaltarloSeRichiesto;
begin
  NewFile;
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.CopyFrame([3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]);
  Open;
  DecodeNext(True);
  Assert.IsFalse(FDecoder.Finished);
  DecodeNext(True);
  Assert.IsTrue(FDecoder.Finished);
  Assert.AreEqual('922229', Row(1), 'l''ultimo fotogramma non si disegna');
  Assert.AreEqual(1, FDecoder.FrameCount);
end;

procedure TTestXcomFlcDecoder.DovrebbeFinireSeCioCheSegueNonEUnFotogramma;
begin
  NewFile;
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.Prefix([]);
  Open;
  DecodeNext;
  Assert.IsFalse(FDecoder.Finished, 'dopo il fotogramma c''e'' ancora un prefisso');
  Assert.IsFalse(FDecoder.FindFrame);
  Assert.IsTrue(FDecoder.Finished);
end;

procedure TTestXcomFlcDecoder.DovrebbeDareIlRitardoDiUnFli;
begin
  NewFile(XCOM_FLC_TYPE_FLI, 5);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], 33);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  Open;
  Assert.IsTrue(FDecoder.FindFrame);
  // 5 * (1000 / 70) = 71.43
  Assert.AreEqual(71, Integer(FDecoder.FrameDelay(False)));
  FDecoder.DecodeFrame(FTarget, TARGET_PITCH, TARGET_OFFSET, False);
  Assert.IsTrue(FDecoder.FindFrame);
  Assert.AreEqual(33, Integer(FDecoder.FrameDelay(False)), 'il ritardo proprio del fotogramma');
end;

procedure TTestXcomFlcDecoder.DovrebbeDareIlRitardoDiUnFlc;
begin
  NewFile(XCOM_FLC_TYPE_FLC, 40);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], 33);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  Open;
  Assert.IsTrue(FDecoder.FindFrame);
  Assert.AreEqual(40, Integer(FDecoder.FrameDelay(False)), 'un FLC non guarda il ritardo del fotogramma');
  Assert.AreEqual(0, Integer(FDecoder.FrameDelay(True)), 'con l''audio interno e nessun pezzo audio letto');
end;

procedure TTestXcomFlcDecoder.DovrebbeLeggereIPezziAudioEIlLoroRitardo;
var
  LSamples: TBytes;
  LBig: TBytes;
  LIndex: Integer;
begin
  NewFile;
  SetLength(LBig, 1000);
  for LIndex := 0 to High(LBig) do
    LBig[LIndex] := LIndex and $FF;
  FBuilder.Audio(22050, LBig);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.Audio(22050, [1, 2, 3]);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  Open;
  Assert.IsTrue(FDecoder.NextAudioChunk(LSamples));
  Assert.AreEqual<Integer>(1000, Length(LSamples));
  Assert.AreEqual(231, Integer(LSamples[999]));
  Assert.IsTrue(FDecoder.HasAudio);
  Assert.AreEqual(22050, FDecoder.SampleRate);
  // 1000 / (22050 / 1000) = 1000 / 22 = 45
  Assert.AreEqual(45, FDecoder.VideoDelay);
  Assert.IsTrue(FDecoder.NextAudioChunk(LSamples));
  Assert.AreEqual<Integer>(3, Length(LSamples));
  Assert.IsFalse(FDecoder.NextAudioChunk(LSamples), 'non ce ne sono altri');
  Assert.IsFalse(FDecoder.Finished, 'la fine del file non ferma il video');
  Assert.IsTrue(FDecoder.FindFrame);
  Assert.AreEqual(45, Integer(FDecoder.FrameDelay(True)));
end;

procedure TTestXcomFlcDecoder.DovrebbeConvertireICampioniA16Bit;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TXcomFlcDecoder.ToSigned16(TBytes.Create(128, 129, 0, 255), 0.5);
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(120, Integer(LSamples[1]));
  Assert.AreEqual(-15360, Integer(LSamples[2]));
  Assert.AreEqual(15240, Integer(LSamples[3]));
end;

procedure TTestXcomFlcDecoder.DovrebbeDareErroreSeIlPezzoLeggeOltreIlFile;
begin
  NewFile;
  FBuilder.BeginFrame;
  // a copy chunk with half of the pixels
  FBuilder.Chunk(FLC_COPY, [1, 2, 3, 4, 5, 6]);
  FBuilder.EndFrame;
  Open;
  Assert.WillRaise(
    procedure
    begin
      DecodeNext;
    end, EXcomFlcException);
end;

procedure TTestXcomFlcDecoder.DovrebbeDareErroreSeIlPezzoScriveFuoriDalQuadro;
begin
  NewFile;
  FBuilder.BeginFrame;
  // the delta starts 200 rows below
  FBuilder.Chunk(FLC_LC, [200, 0, 1, 0, 1, 0, 1, 7]);
  FBuilder.EndFrame;
  FBuilder.CopyFrame([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Open;
  Assert.WillRaise(
    procedure
    begin
      DecodeNext;
    end, EXcomFlcException);
end;

procedure TTestXcomFlcDecoder.DovrebbeContareIFotogrammiECambiareVelocita;
begin
  NewFile(XCOM_FLC_TYPE_FLI, 5);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  FBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
  Open;
  DecodeNext;
  DecodeNext;
  Assert.AreEqual(2, FDecoder.FrameCount);
  FDecoder.SetHeaderSpeed(6);
  Assert.IsTrue(FDecoder.FindFrame);
  Assert.AreEqual(85, Integer(FDecoder.FrameDelay(False)));
  FDecoder.Stop;
  Assert.IsTrue(FDecoder.Finished);
end;

end.
