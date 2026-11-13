{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFlicDecoder (issue #199)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicDecoder;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.Flic.Intf,
  DelphiDoom.Tests.Cinematic.FlicSupport;

type
  [TestFixture]
  [Category('cinematic')]
  TTestFlicDecoder = class(TObject)
  strict private
    /// <summary>A builder for a picture of 8x4 whose first frame is all color 1 (red) with color 0 = (10, 20, 30)</summary>
    function BaseBuilder: TFlicTestBuilder;
    function Decode(const ABytes: TBytes; ALastFrame: Integer): IFlicDecoder;
    procedure AssertIndices(const ADecoder: IFlicDecoder; const AExpected: TBytes);
    function Filled(AValue: Byte): TBytes;
  public
    [Test]
    procedure DovrebbeLeggereLIntestazione;
    [Test]
    procedure DovrebbeDipingereIlPrimoFotogrammaConPaletteEPixel;
    [Test]
    procedure DovrebbeDareIPixelA32BitConLaPaletteSenzaTrasparenza;
    [Test]
    procedure DovrebbeApplicareIlDeltaFli;
    [Test]
    procedure DovrebbeApplicareIlDeltaFlcConPacchettiCopiaEDiRiempimento;
    [Test]
    procedure DovrebbeApplicareIlDeltaFlcConUltimoPixelESaltoDiRighe;
    [Test]
    procedure DovrebbeLeggereUnUltimoPixelConIlByteAltoDaFormatoCorretto;
    [Test]
    procedure DovrebbeLeggereLaPaletteA6Bit;
    [Test]
    procedure DovrebbeCopiareIlFotogrammaLetterale;
    [Test]
    procedure DovrebbeAzzerareLaPitturaConBlackSeLaFiguraEQuadrata;
    [Test]
    procedure DovrebbeConservareIlDifettoDiBlackConLaFiguraLarga;
    [Test]
    procedure DovrebbeSaltareICunkDiTipoSconosciutoELAnteprima;
    [Test]
    procedure DovrebbeSaltarePrefissiEPezziAudio;
    [Test]
    procedure DovrebbeNonDareLUltimoFotogrammaDelCicloSalvoSeRichiesto;
    [Test]
    procedure DovrebbeDareTuttiIFotogrammiSeLIntestazioneNeDiceZero;
    [Test]
    procedure DovrebbeFermarsiAllaFineELasciareLUltimoFotogramma;
    [Test]
    procedure DovrebbeUsareLaVelocitaDellIntestazioneInMillisecondiPerUnFlc;
    [Test]
    procedure DovrebbeUsareIlRitardoDelFotogrammaOLaVelocitaInSettantesimiPerUnFli;
    [Test]
    procedure DovrebbeUsareUnRitardoDiDefaultSeLaVelocitaEZero;
    [Test]
    procedure DovrebbeRipartireDaCapoConReset;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiversoDaFliEFlc;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaFotogrammi;
    [Test]
    procedure DovrebbeRifiutareUnaFiguraVuota;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaDiDimensioneZero;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaCheEsceDalFile;
    [Test]
    procedure DovrebbeSegnalareUnChunkChePassaLaFineDelFile;
    [Test]
    procedure DovrebbeSegnalareUnChunkCheScriveFuoriDallaFigura;
  end;

implementation

uses
  DelphiDoom.Cinematic.Flic.Types,
  DelphiDoom.Cinematic.Flic.Factory;

const
  RED_PIXEL = Cardinal($FF0000FF);
  COLOR_ZERO_PIXEL = Cardinal($FF1E140A);

{ TTestFlicDecoder }

function TTestFlicDecoder.BaseBuilder: TFlicTestBuilder;
begin
  Result := TFlicTestBuilder.Create(8, 4);
  Result.Frame([TFlicTestBuilder.Color256(0, [10, 20, 30, 255, 0, 0]),
    TFlicTestBuilder.ByteRun(8, [1, 1, 1, 1])]);
end;

function TTestFlicDecoder.Decode(const ABytes: TBytes; ALastFrame: Integer): IFlicDecoder;
var
  LIndex: Integer;
begin
  Result := TFlicFactory.CreateDecoder(ABytes);
  for LIndex := 0 to ALastFrame do
    Assert.IsTrue(Result.NextFrame, 'frame ' + IntToStr(LIndex));
end;

function TTestFlicDecoder.Filled(AValue: Byte): TBytes;
begin
  SetLength(Result, 32);
  FillChar(Result[0], 32, AValue);
end;

procedure TTestFlicDecoder.AssertIndices(const ADecoder: IFlicDecoder; const AExpected: TBytes);
var
  LActual: TBytes;
  LIndex: Integer;
begin
  LActual := ADecoder.Indices;
  Assert.AreEqual<Integer>(Length(AExpected), Length(LActual));
  for LIndex := 0 to High(AExpected) do
    if AExpected[LIndex] <> LActual[LIndex] then
      Assert.Fail(Format('pixel %d: expected %d, got %d', [LIndex, AExpected[LIndex], LActual[LIndex]]));
end;

procedure TTestFlicDecoder.DovrebbeLeggereLIntestazione;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LDecoder := TFlicFactory.CreateDecoder(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(8, LDecoder.Width);
  Assert.AreEqual(4, LDecoder.Height);
  Assert.AreEqual(1, LDecoder.HeaderFrames);
  Assert.AreEqual(1, LDecoder.FrameCount);
  Assert.AreEqual(-1, LDecoder.FrameIndex);
  Assert.IsFalse(LDecoder.IsFli);
end;

procedure TTestFlicDecoder.DovrebbeDipingereIlPrimoFotogrammaConPaletteEPixel;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LDecoder := Decode(LBuilder.ToBytes, 0);
  finally
    LBuilder.Free;
  end;
  AssertIndices(LDecoder, Filled(1));
  Assert.AreEqual(0, LDecoder.FrameIndex);
end;

procedure TTestFlicDecoder.DovrebbeDareIPixelA32BitConLaPaletteSenzaTrasparenza;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LPixels: TArray<Cardinal>;
begin
  LBuilder := BaseBuilder;
  try
    LDecoder := Decode(LBuilder.ToBytes, 0);
  finally
    LBuilder.Free;
  end;
  LPixels := LDecoder.Frame;
  Assert.AreEqual<Integer>(32, Length(LPixels));
  Assert.AreEqual(RED_PIXEL, LPixels[0]);
  Assert.AreEqual(RED_PIXEL, LPixels[31]);
  Assert.AreEqual(COLOR_ZERO_PIXEL, LDecoder.Palette[0]);
  // a color that no chunk has set is opaque black
  Assert.AreEqual(Cardinal($FF000000), LDecoder.Palette[200]);
end;

procedure TTestFlicDecoder.DovrebbeApplicareIlDeltaFli;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LExpected: TBytes;
begin
  LBuilder := BaseBuilder;
  try
    // from line 1, one line, one packet: skip 2, 3 literal bytes
    LBuilder.Frame([TFlicTestBuilder.Chunk(12, TFlicTestBuilder.Bytes([1, 0, 1, 0, 1, 2, 3, 3, 3, 3]))]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  LExpected := Filled(1);
  LExpected[10] := 3;
  LExpected[11] := 3;
  LExpected[12] := 3;
  AssertIndices(LDecoder, LExpected);
end;

procedure TTestFlicDecoder.DovrebbeApplicareIlDeltaFlcConPacchettiCopiaEDiRiempimento;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LExpected: TBytes;
begin
  LBuilder := BaseBuilder;
  try
    // one line with two packets: skip 1 and 1 word copied, then skip 1 and a word filled twice
    LBuilder.Frame([TFlicTestBuilder.Chunk(7, TFlicTestBuilder.Bytes([1, 0, 2, 0, 1, 1, 8, 9, 1, $FE, 5, 6]))]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  LExpected := Filled(1);
  LExpected[1] := 8;
  LExpected[2] := 9;
  LExpected[4] := 5;
  LExpected[5] := 6;
  LExpected[6] := 5;
  LExpected[7] := 6;
  AssertIndices(LDecoder, LExpected);
end;

procedure TTestFlicDecoder.DovrebbeApplicareIlDeltaFlcConUltimoPixelESaltoDiRighe;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LExpected: TBytes;
begin
  LBuilder := BaseBuilder;
  try
    // line 0: the last pixel is 9 and no packets
    LBuilder.Frame([TFlicTestBuilder.Chunk(7, TFlicTestBuilder.Bytes([1, 0, 9, $80, 0, 0]))]);
    // skip one line, then a line with a packet of one word at the start
    LBuilder.Frame([TFlicTestBuilder.Chunk(7, TFlicTestBuilder.Bytes([1, 0, $FF, $FF, 1, 0, 0, 1, 7, 7]))]);
    LDecoder := Decode(LBuilder.ToBytes, 2);
  finally
    LBuilder.Free;
  end;
  LExpected := Filled(1);
  LExpected[7] := 9;
  LExpected[8] := 7;
  LExpected[9] := 7;
  AssertIndices(LDecoder, LExpected);
end;

procedure TTestFlicDecoder.DovrebbeLeggereUnUltimoPixelConIlByteAltoDaFormatoCorretto;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LExpected: TBytes;
begin
  // The word $8086 is "last pixel $86". readS16 of OpenXcom reads its low byte as a signed char,
  // gets $FFFFFF86, and takes the word for a skip of 122 lines (the C++ then writes outside the
  // picture): not kept, the decoder follows the format
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Chunk(7, TFlicTestBuilder.Bytes([1, 0, $86, $80, 0, 0]))]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  LExpected := Filled(1);
  LExpected[7] := $86;
  AssertIndices(LDecoder, LExpected);
end;

procedure TTestFlicDecoder.DovrebbeLeggereLaPaletteA6Bit;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Color64(2, [63, 0, 32])]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Cardinal($FF8000FC), LDecoder.Palette[2]);
  Assert.AreEqual(RED_PIXEL, LDecoder.Palette[1]);
end;

procedure TTestFlicDecoder.DovrebbeCopiareIlFotogrammaLetterale;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LPixels: TBytes;
  LIndex: Integer;
begin
  SetLength(LPixels, 32);
  for LIndex := 0 to 31 do
    LPixels[LIndex] := LIndex * 3;
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Literal(LPixels)]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  AssertIndices(LDecoder, LPixels);
end;

procedure TTestFlicDecoder.DovrebbeAzzerareLaPitturaConBlackSeLaFiguraEQuadrata;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(4, 4);
  try
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [1, 1, 1, 1])]);
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  AssertIndices(LDecoder, TFlicTestBuilder.Bytes([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
end;

procedure TTestFlicDecoder.DovrebbeConservareIlDifettoDiBlackConLaFiguraLarga;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
  LExpected: TBytes;
  LRow: Integer;
begin
  // OpenXcom clears "height" pixels of each row (memset(pDst, 0, _screenHeight)), not "width"
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  LExpected := Filled(1);
  for LRow := 0 to 3 do
    FillChar(LExpected[LRow * 8], 4, 0);
  AssertIndices(LDecoder, LExpected);
end;

procedure TTestFlicDecoder.DovrebbeSaltareICunkDiTipoSconosciutoELAnteprima;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Chunk(18, TFlicTestBuilder.Bytes([1, 2, 3])),
      TFlicTestBuilder.Chunk(99, TFlicTestBuilder.Bytes([4, 5]))]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  AssertIndices(LDecoder, Filled(1));
end;

procedure TTestFlicDecoder.DovrebbeSaltarePrefissiEPezziAudio;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4);
  try
    LBuilder.Prefix;
    LBuilder.Frame([TFlicTestBuilder.Color256(0, [0, 0, 0, 255, 0, 0]),
      TFlicTestBuilder.ByteRun(8, [1, 1, 1, 1])]);
    LBuilder.AudioFrame;
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LDecoder := TFlicFactory.CreateDecoder(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, LDecoder.FrameCount);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsFalse(LDecoder.NextFrame);
end;

procedure TTestFlicDecoder.DovrebbeNonDareLUltimoFotogrammaDelCicloSalvoSeRichiesto;
var
  LBuilder: TFlicTestBuilder;
  LBytes: TBytes;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    // the header counts one frame: the second is the ring frame
    LBytes := LBuilder.ToBytes(1);
  finally
    LBuilder.Free;
  end;
  LDecoder := TFlicFactory.CreateDecoder(LBytes);
  Assert.AreEqual(1, LDecoder.FrameCount);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsFalse(LDecoder.NextFrame);
  LDecoder := TFlicFactory.CreateDecoder(LBytes, True);
  Assert.AreEqual(2, LDecoder.FrameCount);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.IsFalse(LDecoder.NextFrame);
end;

procedure TTestFlicDecoder.DovrebbeDareTuttiIFotogrammiSeLIntestazioneNeDiceZero;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LDecoder := TFlicFactory.CreateDecoder(LBuilder.ToBytes(0));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, LDecoder.FrameCount);
  Assert.AreEqual(0, LDecoder.HeaderFrames);
end;

procedure TTestFlicDecoder.DovrebbeFermarsiAllaFineELasciareLUltimoFotogramma;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LDecoder := Decode(LBuilder.ToBytes, 0);
  finally
    LBuilder.Free;
  end;
  Assert.IsFalse(LDecoder.NextFrame);
  Assert.AreEqual(0, LDecoder.FrameIndex);
  AssertIndices(LDecoder, Filled(1));
end;

procedure TTestFlicDecoder.DovrebbeUsareLaVelocitaDellIntestazioneInMillisecondiPerUnFlc;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4, False, 85);
  try
    LBuilder.Frame([TFlicTestBuilder.Black], 7);
    LDecoder := Decode(LBuilder.ToBytes, 0);
  finally
    LBuilder.Free;
  end;
  // a FLC ignores the delay of the frame
  Assert.AreEqual(85, LDecoder.FrameDelay);
end;

procedure TTestFlicDecoder.DovrebbeUsareIlRitardoDelFotogrammaOLaVelocitaInSettantesimiPerUnFli;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4, True, 3);
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LBuilder.Frame([TFlicTestBuilder.Black], 9);
    LDecoder := TFlicFactory.CreateDecoder(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.IsFli);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(42, LDecoder.FrameDelay);
  Assert.IsTrue(LDecoder.NextFrame);
  Assert.AreEqual(9, LDecoder.FrameDelay);
end;

procedure TTestFlicDecoder.DovrebbeUsareUnRitardoDiDefaultSeLaVelocitaEZero;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4, False, 0);
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LDecoder := Decode(LBuilder.ToBytes, 0);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(FLIC_DEFAULT_DELAY, LDecoder.FrameDelay);
end;

procedure TTestFlicDecoder.DovrebbeRipartireDaCapoConReset;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := BaseBuilder;
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LDecoder := Decode(LBuilder.ToBytes, 1);
  finally
    LBuilder.Free;
  end;
  LDecoder.Reset;
  Assert.AreEqual(-1, LDecoder.FrameIndex);
  Assert.AreEqual(0, LDecoder.FrameDelay);
  AssertIndices(LDecoder, Filled(0));
  Assert.AreEqual(Cardinal($FF000000), LDecoder.Palette[1]);
  Assert.IsTrue(LDecoder.NextFrame);
  AssertIndices(LDecoder, Filled(1));
  Assert.AreEqual(RED_PIXEL, LDecoder.Palette[1]);
end;

procedure TTestFlicDecoder.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TFlicFactory.CreateDecoder(TFlicTestBuilder.Bytes([1, 2, 3]));
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeRifiutareUnTipoDiversoDaFliEFlc;
var
  LBuilder: TFlicTestBuilder;
  LBytes: TBytes;
begin
  LBuilder := BaseBuilder;
  try
    LBytes := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
  LBytes[4] := $34;
  LBytes[5] := $12;
  Assert.WillRaise(
    procedure
    begin
      TFlicFactory.CreateDecoder(LBytes);
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeRifiutareUnFileSenzaFotogrammi;
var
  LBuilder: TFlicTestBuilder;
  LBytes: TBytes;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4);
  try
    LBuilder.Prefix;
    LBytes := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      TFlicFactory.CreateDecoder(LBytes);
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeRifiutareUnaFiguraVuota;
var
  LBuilder: TFlicTestBuilder;
  LBytes: TBytes;
begin
  LBuilder := TFlicTestBuilder.Create(0, 4);
  try
    LBuilder.Frame([TFlicTestBuilder.Black]);
    LBytes := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      TFlicFactory.CreateDecoder(LBytes);
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeRifiutareUnFotogrammaDiDimensioneZero;
var
  LBuilder: TFlicTestBuilder;
  LBytes: TBytes;
begin
  LBuilder := BaseBuilder;
  try
    LBytes := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
  // the size of the frame is 0: the player of OpenXcom would stay on it for ever
  LBytes[FLIC_HEADER_SIZE] := 0;
  LBytes[FLIC_HEADER_SIZE + 1] := 0;
  Assert.WillRaise(
    procedure
    begin
      TFlicFactory.CreateDecoder(LBytes);
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeRifiutareUnFotogrammaCheEsceDalFile;
var
  LBuilder: TFlicTestBuilder;
  LBytes: TBytes;
begin
  LBuilder := BaseBuilder;
  try
    LBytes := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
  SetLength(LBytes, Length(LBytes) - 3);
  Assert.WillRaise(
    procedure
    begin
      TFlicFactory.CreateDecoder(LBytes);
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeSegnalareUnChunkChePassaLaFineDelFile;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4);
  try
    // BYTE_RUN with the data of one row only
    LBuilder.Frame([TFlicTestBuilder.Chunk(15, TFlicTestBuilder.Bytes([0, 8, 1]))]);
    LDecoder := TFlicFactory.CreateDecoder(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LDecoder.NextFrame;
    end, EFlicInvalidDataException);
end;

procedure TTestFlicDecoder.DovrebbeSegnalareUnChunkCheScriveFuoriDallaFigura;
var
  LBuilder: TFlicTestBuilder;
  LDecoder: IFlicDecoder;
begin
  LBuilder := TFlicTestBuilder.Create(8, 4);
  try
    // DELTA_FLI that starts at line 100
    LBuilder.Frame([TFlicTestBuilder.Chunk(12, TFlicTestBuilder.Bytes([100, 0, 1, 0, 1, 0, 1, 5]))]);
    LDecoder := TFlicFactory.CreateDecoder(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LDecoder.NextFrame;
    end, EFlicInvalidDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFlicDecoder);

end.
