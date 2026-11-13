{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqFramePainter                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FramePainter;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.YuvConverter,
  DelphiDoom.Cinematic.Codebook,
  DelphiDoom.Cinematic.FramePainter;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqFramePainter = class(TObject)
  strict private
    FConverter: TRoqYuvConverter;
    FCodebook: TRoqCodebook;
    FPainter: TRoqFramePainter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareDimensioniNonMultipleDiSedici;
    [Test]
    procedure DovrebbeDipingereIlVettoreOttoPerOtto;
    [Test]
    procedure DovrebbeDipingereLaSecondaMetaSenzaToccareLaPrima;
    [Test]
    procedure DovrebbeLasciareICampiConIlCodiceZero;
    [Test]
    procedure DovrebbeDipingereLeDivisioniInQuattroPerQuattroEDuePerDue;
    [Test]
    procedure DovrebbeCopiareConIlMovimentoZero;
    [Test]
    procedure DovrebbeSollevareSeIlMovimentoLeggeFuoriDalBuffer;
    [Test]
    procedure DovrebbeSollevareSenzaCodebook;
    [Test]
    procedure DovrebbeSollevareSeIDatiFinisconoPrimaDellUltimoBlocco;
    [Test]
    procedure DovrebbeCopiareIlPrimoFotogrammaNelSecondo;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqFramePainter }

procedure TTestRoqFramePainter.Setup;
begin
  FConverter := TRoqYuvConverter.Create($FF);
  FCodebook := TRoqCodebook.Create(FConverter);
  FCodebook.Decode(TRoqTestBuilder.CodebookData(2, 2), (2 shl 8) or 2);
  FPainter := TRoqFramePainter.Create(16, 16, FCodebook);
end;

procedure TTestRoqFramePainter.TearDown;
begin
  FPainter.Free;
  FCodebook.Free;
  FConverter.Free;
end;

procedure TTestRoqFramePainter.DovrebbeRifiutareDimensioniNonMultipleDiSedici;
begin
  Assert.WillRaise(
    procedure
    begin
      TRoqFramePainter.Create(20, 16, FCodebook).Free;
    end, ERoqInvalidDataException);
  Assert.WillRaise(
    procedure
    begin
      TRoqFramePainter.Create(16, 0, FCodebook).Free;
    end, ERoqInvalidDataException);
end;

procedure TTestRoqFramePainter.DovrebbeDipingereIlVettoreOttoPerOtto;
var
  LBuilder: TRoqTestBuilder;
  LFrame: TImagingPixels;
  LRow, LColumn: Integer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    LBuilder.Code(2, [1]);
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, [1]);
    LBuilder.Code(2, [0]);
    FPainter.PrepareMotion(0, 0, FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 0);
  finally
    LBuilder.Free;
  end;
  LFrame := FPainter.FrameCopy(0);
  Assert.AreEqual(256, Integer(Length(LFrame)));
  for LRow := 0 to 15 do
    for LColumn := 0 to 15 do
      // block order: (0,0) vector 1, (8,0) vector 0, (0,8) vector 1, (8,8) vector 0
      Assert.AreEqual(FCodebook.Vq8[((LRow mod 8) * 8 + LColumn mod 8) + 64 * Ord(LColumn < 8)],
        LFrame[LRow * 16 + LColumn]);
end;

procedure TTestRoqFramePainter.DovrebbeDipingereLaSecondaMetaSenzaToccareLaPrima;
var
  LBuilder: TRoqTestBuilder;
  LFirst, LSecond: TImagingPixels;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, [0]);
    FPainter.PrepareMotion(0, 0, -FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 1);
  finally
    LBuilder.Free;
  end;
  LFirst := FPainter.FrameCopy(0);
  LSecond := FPainter.FrameCopy(1);
  Assert.AreEqual(Cardinal(0), LFirst[0]);
  Assert.AreEqual(FCodebook.Vq8[0], LSecond[0]);
  Assert.AreEqual(FCodebook.Vq8[63], LSecond[7 * 16 + 7]);
end;

procedure TTestRoqFramePainter.DovrebbeLasciareICampiConIlCodiceZero;
var
  LBuilder: TRoqTestBuilder;
  LFrame: TImagingPixels;
  LIndex: Integer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    for LIndex := 0 to 3 do
      LBuilder.Code(0, []);
    FPainter.PrepareMotion(0, 0, FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 0);
  finally
    LBuilder.Free;
  end;
  LFrame := FPainter.FrameCopy(0);
  for LIndex := 0 to 255 do
    Assert.AreEqual(Cardinal(0), LFrame[LIndex]);
end;

procedure TTestRoqFramePainter.DovrebbeDipingereLeDivisioniInQuattroPerQuattroEDuePerDue;
var
  LBuilder: TRoqTestBuilder;
  LFrame: TImagingPixels;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    // the first 8x8 block is split: 4x4 vector 0, four 2x2 vectors (0, 1, 0, 1), two skips
    LBuilder.Code(3, []);
    LBuilder.Code(2, [0]);
    LBuilder.Code(3, [0, 1, 0, 1]);
    LBuilder.Code(0, []);
    LBuilder.Code(0, []);
    LBuilder.Code(0, []);
    LBuilder.Code(0, []);
    LBuilder.Code(0, []);
    FPainter.PrepareMotion(0, 0, FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 0);
  finally
    LBuilder.Free;
  end;
  LFrame := FPainter.FrameCopy(0);
  Assert.AreEqual(FCodebook.Vq4[2 * 4 + 1], LFrame[2 * 16 + 1]);
  // the 2x2 vectors of the block at (4, 0): vector 0 at (4, 0), vector 1 at (6, 0), vector 0 at (4, 2)
  Assert.AreEqual(FCodebook.Vq2[0 * 4 + 1], LFrame[0 * 16 + 5]);
  Assert.AreEqual(FCodebook.Vq2[1 * 4 + 0], LFrame[0 * 16 + 6]);
  Assert.AreEqual(FCodebook.Vq2[0 * 4 + 3], LFrame[3 * 16 + 5]);
  Assert.AreEqual(FCodebook.Vq2[1 * 4 + 3], LFrame[3 * 16 + 7]);
  // what was skipped stays black
  Assert.AreEqual(Cardinal(0), LFrame[8]);
  Assert.AreEqual(Cardinal(0), LFrame[4 * 16]);
end;

procedure TTestRoqFramePainter.DovrebbeCopiareConIlMovimentoZero;
var
  LBuilder: TRoqTestBuilder;
  LFirst, LSecond: TImagingPixels;
  LIndex: Integer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    LBuilder.Code(2, [1]);
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, [1]);
    FPainter.PrepareMotion(0, 0, FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 0);
    FPainter.CopyFirstToSecond;
    // the byte 8 * 16 + 8 is the vector (0, 0): the second frame is a copy of the first
    LBuilder.BeginFrame;
    for LIndex := 0 to 3 do
      LBuilder.Code(1, [8 * 16 + 8]);
    FPainter.PrepareMotion(0, 0, -FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 1);
  finally
    LBuilder.Free;
  end;
  LFirst := FPainter.FrameCopy(0);
  LSecond := FPainter.FrameCopy(1);
  for LIndex := 0 to 255 do
    Assert.AreEqual(LFirst[LIndex], LSecond[LIndex]);
end;

procedure TTestRoqFramePainter.DovrebbeSollevareSeIlMovimentoLeggeFuoriDalBuffer;
var
  LBuilder: TRoqTestBuilder;
  LData: TBytes;
  LIndex: Integer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    // the byte 0 points 8 pixels up and left: the block at (8, 0) of the first half reads past the end
    for LIndex := 0 to 3 do
      LBuilder.Code(1, [0]);
    LData := LBuilder.FrameBytes;
  finally
    LBuilder.Free;
  end;
  FPainter.PrepareMotion(0, 0, FPainter.Delta);
  Assert.WillRaise(
    procedure
    begin
      FPainter.Paint(LData, Length(LData), 0);
    end, ERoqInvalidDataException);
end;

procedure TTestRoqFramePainter.DovrebbeSollevareSenzaCodebook;
var
  LEmpty: TRoqCodebook;
  LPainter: TRoqFramePainter;
  LBuilder: TRoqTestBuilder;
  LData: TBytes;
begin
  LEmpty := TRoqCodebook.Create(FConverter);
  LPainter := TRoqFramePainter.Create(16, 16, LEmpty);
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    LBuilder.Code(2, [0]);
    LData := LBuilder.FrameBytes;
    LPainter.PrepareMotion(0, 0, LPainter.Delta);
    Assert.WillRaise(
      procedure
      begin
        LPainter.Paint(LData, Length(LData), 0);
      end, ERoqMissingCodebookException);
  finally
    LBuilder.Free;
    LPainter.Free;
    LEmpty.Free;
  end;
end;

procedure TTestRoqFramePainter.DovrebbeSollevareSeIDatiFinisconoPrimaDellUltimoBlocco;
var
  LBuilder: TRoqTestBuilder;
  LData: TBytes;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.BeginFrame;
    // the second code asks for a vector and there is no byte for it
    LBuilder.Code(2, [0]);
    LBuilder.Code(2, []);
    LData := LBuilder.FrameBytes;
  finally
    LBuilder.Free;
  end;
  FPainter.PrepareMotion(0, 0, FPainter.Delta);
  Assert.WillRaise(
    procedure
    begin
      FPainter.Paint(LData, Length(LData), 0);
    end, ERoqTruncatedException);
end;

procedure TTestRoqFramePainter.DovrebbeCopiareIlPrimoFotogrammaNelSecondo;
var
  LBuilder: TRoqTestBuilder;
  LSecond: TImagingPixels;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.FullFrame16(1);
    LBuilder.BeginFrame;
    LBuilder.Code(2, [1]);
    LBuilder.Code(2, [1]);
    LBuilder.Code(2, [1]);
    LBuilder.Code(2, [1]);
    FPainter.PrepareMotion(0, 0, FPainter.Delta);
    FPainter.Paint(LBuilder.FrameBytes, Length(LBuilder.FrameBytes), 0);
  finally
    LBuilder.Free;
  end;
  FPainter.CopyFirstToSecond;
  LSecond := FPainter.FrameCopy(1);
  Assert.AreEqual(FCodebook.Vq8[64], LSecond[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqFramePainter);

end.
