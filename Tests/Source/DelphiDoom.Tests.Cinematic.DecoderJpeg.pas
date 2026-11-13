{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG frames (ROQ_QUAD_JPEG) of TRoqDecoder         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.DecoderJpeg;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.Intf,
  DelphiDoom.Cinematic.Jpeg.Intf;

type
  /// <summary>A JPEG decoder that gives a picture made by rule: R = row * 10 + base, G = column, B = 200</summary>
  TFakeRoqJpegDecoder = class(TInterfacedObject, IRoqJpegDecoder)
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FBase: Integer;
  public
    Calls: Integer;
    constructor Create(AWidth, AHeight, ABase: Integer);
    function Decode(const AData: TBytes; out AWidth, AHeight: Integer): TBytes;
  end;

  [TestFixture]
  [Category('cinematic')]
  TTestRoqDecoderJpeg = class(TObject)
  strict private
    function Decoder(const ABytes: TBytes; const AJpeg: IRoqJpegDecoder;
      AAlpha: Byte = $FF): IRoqDecoder;
    function SkipFrame(ACodes: Integer): TBytes;
    function Expected(ARow, AColumn, ABase, AHeight: Integer; AAlpha: Cardinal): Cardinal;
  public
    [Test]
    procedure DovrebbeDipingereIlPrimoFotogrammaCapovolto;
    [Test]
    procedure DovrebbeUsareLAlphaDelDecoder;
    [Test]
    procedure DovrebbeSaltareIlChunkJpegSenzaDecoderJpeg;
    [Test]
    procedure DovrebbeIgnorareUnSecondoChunkJpeg;
    [Test]
    procedure DovrebbeIgnorareUnChunkJpegPrimaDelleInformazioni;
    [Test]
    procedure DovrebbeSollevareSeLeDimensioniDelJpegNonSonoQuelleDelVideo;
    [Test]
    procedure DovrebbeContinuareConUnFotogrammaVqDopoIlJpeg;
    [Test]
    procedure DovrebbeRipetereIlJpegDopoReset;
    [Test]
    procedure DovrebbeDecodificareUnJpegVeroConLaLibreriaJpeg;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Cinematic.Jpeg.Factory,
  DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Decoder,
  DelphiDoom.Tests.Cinematic.Support;

{ TFakeRoqJpegDecoder }

constructor TFakeRoqJpegDecoder.Create(AWidth, AHeight, ABase: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FBase := ABase;
end;

function TFakeRoqJpegDecoder.Decode(const AData: TBytes; out AWidth, AHeight: Integer): TBytes;
var
  LRow, LColumn: Integer;
begin
  Inc(Calls);
  AWidth := FWidth;
  AHeight := FHeight;
  SetLength(Result, FWidth * FHeight * 3);
  for LRow := 0 to FHeight - 1 do
    for LColumn := 0 to FWidth - 1 do
    begin
      Result[(LRow * FWidth + LColumn) * 3] := LRow * 10 + FBase;
      Result[(LRow * FWidth + LColumn) * 3 + 1] := LColumn;
      Result[(LRow * FWidth + LColumn) * 3 + 2] := 200;
    end;
end;

{ TTestRoqDecoderJpeg }

function TTestRoqDecoderJpeg.Decoder(const ABytes: TBytes; const AJpeg: IRoqJpegDecoder;
  AAlpha: Byte): IRoqDecoder;
begin
  Result := TCinematicFactory.CreateDecoder(TCinematicFactory.CreateMemorySource(ABytes), nil,
    AAlpha, AJpeg);
end;

function TTestRoqDecoderJpeg.SkipFrame(ACodes: Integer): TBytes;
var
  LBuilder: TRoqTestBuilder;
  LIndex: Integer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    for LIndex := 1 to ACodes do
      LBuilder.Code(0, []);
    Result := LBuilder.FrameBytes;
  finally
    LBuilder.Free;
  end;
end;

function TTestRoqDecoderJpeg.Expected(ARow, AColumn, ABase, AHeight: Integer; AAlpha: Cardinal): Cardinal;
var
  LSourceRow: Integer;
begin
  // the row ARow of the image is the scanline AHeight - 1 - ARow of the JPEG
  LSourceRow := AHeight - 1 - ARow;
  Result := Cardinal(LSourceRow * 10 + ABase) or (Cardinal(AColumn) shl 8) or (Cardinal(200) shl 16) or
    (AAlpha shl 24);
end;

procedure TTestRoqDecoderJpeg.DovrebbeDipingereIlPrimoFotogrammaCapovolto;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
  LRow, LColumn: Integer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1, 2, 3]));
    LDecoder := Decoder(LBuilder.ToBytes, TFakeRoqJpegDecoder.Create(16, 16, 5));
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckInfo), Ord(LKind));
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckFrame), Ord(LKind));
  Assert.AreEqual(0, LDecoder.FrameIndex);
  Assert.AreEqual<Integer>(256, Length(LDecoder.Frame));
  for LRow := 0 to 15 do
    for LColumn := 0 to 15 do
      Assert.AreEqual(Expected(LRow, LColumn, 5, 16, $FF), LDecoder.Frame[LRow * 16 + LColumn]);
end;

procedure TTestRoqDecoderJpeg.DovrebbeUsareLAlphaDelDecoder;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1]));
    LDecoder := Decoder(LBuilder.ToBytes, TFakeRoqJpegDecoder.Create(16, 16, 0), 0);
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  LDecoder.ReadChunk(LKind);
  Assert.AreEqual(Expected(0, 3, 0, 16, 0), LDecoder.Frame[3]);
  Assert.AreEqual(0, Integer(LDecoder.Frame[3] shr 24));
end;

procedure TTestRoqDecoderJpeg.DovrebbeSaltareIlChunkJpegSenzaDecoderJpeg;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1, 2, 3]));
    LDecoder := Decoder(LBuilder.ToBytes, nil);
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckOther), Ord(LKind));
  Assert.AreEqual(-1, LDecoder.FrameIndex);
end;

procedure TTestRoqDecoderJpeg.DovrebbeIgnorareUnSecondoChunkJpeg;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LFake: TFakeRoqJpegDecoder;
  LJpeg: IRoqJpegDecoder;
  LKind: TRoqChunkKind;
  LFirst: Cardinal;
begin
  LFake := TFakeRoqJpegDecoder.Create(16, 16, 5);
  LJpeg := LFake;
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1]));
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([2]));
    LDecoder := Decoder(LBuilder.ToBytes, LJpeg);
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  LDecoder.ReadChunk(LKind);
  LFirst := LDecoder.Frame[0];
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckOther), Ord(LKind));
  Assert.AreEqual(0, LDecoder.FrameIndex);
  Assert.AreEqual(LFirst, LDecoder.Frame[0]);
  Assert.AreEqual(1, LFake.Calls);
end;

procedure TTestRoqDecoderJpeg.DovrebbeIgnorareUnChunkJpegPrimaDelleInformazioni;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1]));
    LDecoder := Decoder(LBuilder.ToBytes, TFakeRoqJpegDecoder.Create(16, 16, 5));
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckOther), Ord(LKind));
  Assert.AreEqual(-1, LDecoder.FrameIndex);
end;

procedure TTestRoqDecoderJpeg.DovrebbeSollevareSeLeDimensioniDelJpegNonSonoQuelleDelVideo;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(32, 32);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1]));
    LDecoder := Decoder(LBuilder.ToBytes, TFakeRoqJpegDecoder.Create(16, 16, 5));
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  Assert.WillRaise(
    procedure
    var
      LInner: TRoqChunkKind;
    begin
      LDecoder.ReadChunk(LInner);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqDecoderJpeg.DovrebbeContinuareConUnFotogrammaVqDopoIlJpeg;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
  LImage: TArray<Cardinal>;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1]));
    // a frame that skips every block keeps the JPEG as it is
    LBuilder.Chunk(ROQ_QUAD_VQ, 0, SkipFrame(4));
    LDecoder := Decoder(LBuilder.ToBytes, TFakeRoqJpegDecoder.Create(16, 16, 5));
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  LDecoder.ReadChunk(LKind);
  LImage := Copy(LDecoder.Frame);
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckFrame), Ord(LKind));
  Assert.AreEqual(1, LDecoder.FrameIndex);
  Assert.AreEqual(PixelsCrc(LImage), PixelsCrc(LDecoder.Frame));
end;

procedure TTestRoqDecoderJpeg.DovrebbeRipetereIlJpegDopoReset;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
  LFirst: Cardinal;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, TRoqTestBuilder.Bytes([1]));
    LDecoder := Decoder(LBuilder.ToBytes, TFakeRoqJpegDecoder.Create(16, 16, 7));
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  LDecoder.ReadChunk(LKind);
  LFirst := LDecoder.Frame[17];
  LDecoder.Reset;
  LDecoder.ReadChunk(LKind);
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckFrame), Ord(LKind));
  Assert.AreEqual(0, LDecoder.FrameIndex);
  Assert.AreEqual(LFirst, LDecoder.Frame[17]);
end;

procedure TTestRoqDecoderJpeg.DovrebbeDecodificareUnJpegVeroConLaLibreriaJpeg;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
  LKind: TRoqChunkKind;
  LData, LRaw: TBytes;
  LInfo: TJpegInfo;
  LRow, LColumn, LSource: Integer;
begin
  LData := TRoqTestData.ReadJpeg('encoder-48x48-c3-q100.jpg');
  SetLength(LRaw, 48 * 48 * 3);
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(@LData[0], Length(LData), @LRaw[0], Length(LRaw), LInfo));
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(48, 48);
    LBuilder.Chunk(ROQ_QUAD_JPEG, 0, LData);
    LDecoder := Decoder(LBuilder.ToBytes, TRoqJpegFactory.CreateDecoder, 0);
  finally
    LBuilder.Free;
  end;
  LDecoder.ReadChunk(LKind);
  Assert.IsTrue(LDecoder.ReadChunk(LKind));
  Assert.AreEqual(Ord(rckFrame), Ord(LKind));
  for LRow := 0 to 47 do
    for LColumn := 0 to 47 do
    begin
      LSource := ((47 - LRow) * 48 + LColumn) * 3;
      Assert.AreEqual(Cardinal(LRaw[LSource]) or (Cardinal(LRaw[LSource + 1]) shl 8) or
        (Cardinal(LRaw[LSource + 2]) shl 16), LDecoder.Frame[LRow * 48 + LColumn],
        Format('pixel %d,%d', [LColumn, LRow]));
    end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqDecoderJpeg);

end.
