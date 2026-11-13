{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqModeCodebook                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.ModeCodebook;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.YuvConverter,
  DelphiDoom.Cinematic.ModeCodebook;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqModeCodebook = class(TObject)
  strict private
    FConverter: TRoqYuvConverter;
    FGray: TBytes;
    function Mode(AFormat: TRoqPixelFormat; AHalf, ASmoothed: Boolean): TRoqCodebookMode;
    function WordAt(const ABytes: TBytes; AIndex: Integer): Cardinal;
    function Make(AFormat: TRoqPixelFormat; AHalf, ASmoothed: Boolean): TRoqModeCodebook;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeDimensioniDeiBufferDelCodice;
    [Test]
    procedure DovrebbeDireLaDimensioneDelPixel;
    [Test]
    procedure DovrebbeRipetereIlCodebookA32BitDiTRoqCodebook;
    [Test]
    procedure DovrebbeCostruireIVettoriInModoNormale;
    [Test]
    procedure DovrebbeInterpolareLeRigheInModoDoppiaAltezza;
    [Test]
    procedure DovrebbeTenereSoloDuePixelInModoMeta;
    [Test]
    procedure DovrebbeUsareLaTabellaDeiGrigi;
    [Test]
    procedure DovrebbeUsareIColoriA16Bit;
    [Test]
    procedure DovrebbeDareLaPrecedenzaAMetaSuDoppiaAltezza;
    [Test]
    procedure DovrebbeRichiedereLaTabellaDeiGrigiDi256Livelli;
    [Test]
    procedure DovrebbeSollevareSeIDatiSonoTroncati;
    [Test]
    procedure DovrebbeDimenticareTuttoConClear;
    [Test]
    procedure DovrebbeLiberareIlConvertitoreDellaFabbrica;
  end;

implementation

uses
  DelphiDoom.Cinematic.Codebook,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqModeCodebook }

procedure TTestRoqModeCodebook.Setup;
var
  LIndex: Integer;
begin
  FConverter := TRoqYuvConverter.Create(ROQ_ALPHA_OPAQUE);
  SetLength(FGray, 256);
  for LIndex := 0 to 255 do
    FGray[LIndex] := 255 - LIndex;
end;

procedure TTestRoqModeCodebook.TearDown;
begin
  FConverter.Free;
end;

function TTestRoqModeCodebook.Mode(AFormat: TRoqPixelFormat; AHalf, ASmoothed: Boolean): TRoqCodebookMode;
begin
  Result.PixelFormat := AFormat;
  Result.Half := AHalf;
  Result.SmoothedDouble := ASmoothed;
end;

function TTestRoqModeCodebook.Make(AFormat: TRoqPixelFormat; AHalf, ASmoothed: Boolean): TRoqModeCodebook;
begin
  Result := TRoqModeCodebook.Create(FConverter, Mode(AFormat, AHalf, ASmoothed), FGray);
end;

function TTestRoqModeCodebook.WordAt(const ABytes: TBytes; AIndex: Integer): Cardinal;
begin
  Result := ABytes[AIndex * 4] or (Cardinal(ABytes[AIndex * 4 + 1]) shl 8) or
    (Cardinal(ABytes[AIndex * 4 + 2]) shl 16) or (Cardinal(ABytes[AIndex * 4 + 3]) shl 24);
end;

procedure TTestRoqModeCodebook.DovrebbeDareLeDimensioniDeiBufferDelCodice;
var
  LCodebook: TRoqModeCodebook;
  LFormat: TRoqPixelFormat;
begin
  for LFormat := Low(TRoqPixelFormat) to High(TRoqPixelFormat) do
  begin
    LCodebook := Make(LFormat, False, False);
    try
      Assert.AreEqual<Integer>(32768, Length(LCodebook.Vq2Bytes));
      Assert.AreEqual<Integer>(131072, Length(LCodebook.Vq4Bytes));
      Assert.AreEqual<Integer>(524288, Length(LCodebook.Vq8Bytes));
      Assert.IsFalse(LCodebook.Loaded);
    finally
      LCodebook.Free;
    end;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeDireLaDimensioneDelPixel;
var
  LCodebook: TRoqModeCodebook;
begin
  LCodebook := Make(rpfRgba32, False, False);
  try
    Assert.AreEqual(4, LCodebook.PixelSize);
    Assert.AreEqual(Ord(rpfRgba32), Ord(LCodebook.Mode.PixelFormat));
  finally
    LCodebook.Free;
  end;
  LCodebook := Make(rpfRgb565, False, False);
  try
    Assert.AreEqual(2, LCodebook.PixelSize);
  finally
    LCodebook.Free;
  end;
  LCodebook := Make(rpfGray8, False, False);
  try
    Assert.AreEqual(1, LCodebook.PixelSize);
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeRipetereIlCodebookA32BitDiTRoqCodebook;
var
  LPlain: TRoqCodebook;
  LModes: TRoqModeCodebook;
  LData: TBytes;
  LIndex: Integer;
  LBytes: TBytes;
begin
  LData := TRoqTestBuilder.CodebookData(5, 3);
  LPlain := TRoqCodebook.Create(FConverter);
  LModes := Make(rpfRgba32, False, False);
  try
    LPlain.Decode(LData, (5 shl 8) or 3);
    LModes.Decode(LData, (5 shl 8) or 3);
    Assert.IsTrue(LModes.Loaded);
    LBytes := LModes.Vq2Bytes;
    for LIndex := 0 to High(LPlain.Vq2) do
      Assert.AreEqual(LPlain.Vq2[LIndex], WordAt(LBytes, LIndex), 'vq2 ' + IntToStr(LIndex));
    LBytes := LModes.Vq4Bytes;
    for LIndex := 0 to High(LPlain.Vq4) do
      Assert.AreEqual(LPlain.Vq4[LIndex], WordAt(LBytes, LIndex), 'vq4 ' + IntToStr(LIndex));
    LBytes := LModes.Vq8Bytes;
    for LIndex := 0 to High(LPlain.Vq8) do
      Assert.AreEqual(LPlain.Vq8[LIndex], WordAt(LBytes, LIndex), 'vq8 ' + IntToStr(LIndex));
  finally
    LModes.Free;
    LPlain.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeCostruireIVettoriInModoNormale;
var
  LCodebook: TRoqModeCodebook;
  LBytes: TBytes;
begin
  LCodebook := Make(rpfRgba32, False, False);
  try
    // one 2x2 vector: Y 10, 80, 150, 220, Cr 100, Cb 160
    LCodebook.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    LBytes := LCodebook.Vq2Bytes;
    Assert.AreEqual(FConverter.ToPixel(10, 100, 160), WordAt(LBytes, 0));
    Assert.AreEqual(FConverter.ToPixel(80, 100, 160), WordAt(LBytes, 1));
    Assert.AreEqual(FConverter.ToPixel(150, 100, 160), WordAt(LBytes, 2));
    Assert.AreEqual(FConverter.ToPixel(220, 100, 160), WordAt(LBytes, 3));
    Assert.AreEqual(0, Integer(WordAt(LBytes, 4)));
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeInterpolareLeRigheInModoDoppiaAltezza;
var
  LCodebook: TRoqModeCodebook;
  LBytes: TBytes;
begin
  LCodebook := Make(rpfRgba32, False, True);
  try
    LCodebook.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    LBytes := LCodebook.Vq2Bytes;
    // eight pixels: the rows 0, 3/4 + 1/4, 1/4 + 3/4 and 1 of the two columns
    Assert.AreEqual(FConverter.ToPixel(10, 100, 160), WordAt(LBytes, 0));
    Assert.AreEqual(FConverter.ToPixel(80, 100, 160), WordAt(LBytes, 1));
    Assert.AreEqual(FConverter.ToPixel((10 * 3 + 150) div 4, 100, 160), WordAt(LBytes, 2));
    Assert.AreEqual(FConverter.ToPixel((80 * 3 + 220) div 4, 100, 160), WordAt(LBytes, 3));
    Assert.AreEqual(FConverter.ToPixel((10 + 150 * 3) div 4, 100, 160), WordAt(LBytes, 4));
    Assert.AreEqual(FConverter.ToPixel((80 + 220 * 3) div 4, 100, 160), WordAt(LBytes, 5));
    Assert.AreEqual(FConverter.ToPixel(150, 100, 160), WordAt(LBytes, 6));
    Assert.AreEqual(FConverter.ToPixel(220, 100, 160), WordAt(LBytes, 7));
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeTenereSoloDuePixelInModoMeta;
var
  LCodebook: TRoqModeCodebook;
  LBytes: TBytes;
begin
  LCodebook := Make(rpfRgba32, True, False);
  try
    LCodebook.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    LBytes := LCodebook.Vq2Bytes;
    // the first and the third luminance
    Assert.AreEqual(FConverter.ToPixel(10, 100, 160), WordAt(LBytes, 0));
    Assert.AreEqual(FConverter.ToPixel(150, 100, 160), WordAt(LBytes, 1));
    Assert.AreEqual(0, Integer(WordAt(LBytes, 2)));
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeUsareLaTabellaDeiGrigi;
var
  LCodebook: TRoqModeCodebook;
  LBytes: TBytes;
begin
  LCodebook := Make(rpfGray8, False, False);
  try
    LCodebook.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    LBytes := LCodebook.Vq2Bytes;
    Assert.AreEqual(Integer(FGray[10]), Integer(LBytes[0]));
    Assert.AreEqual(Integer(FGray[80]), Integer(LBytes[1]));
    Assert.AreEqual(Integer(FGray[150]), Integer(LBytes[2]));
    Assert.AreEqual(Integer(FGray[220]), Integer(LBytes[3]));
    Assert.AreEqual(0, Integer(LBytes[4]));
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeUsareIColoriA16Bit;
var
  LCodebook: TRoqModeCodebook;
  LBytes: TBytes;
begin
  LCodebook := Make(rpfRgb565, False, False);
  try
    LCodebook.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    LBytes := LCodebook.Vq2Bytes;
    // little endian words
    Assert.AreEqual(Integer(FConverter.ToRgb565(10, 100, 160)), Integer(LBytes[0] or (LBytes[1] shl 8)));
    Assert.AreEqual(Integer(FConverter.ToRgb565(220, 100, 160)), Integer(LBytes[6] or (LBytes[7] shl 8)));
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeDareLaPrecedenzaAMetaSuDoppiaAltezza;
var
  LBoth, LHalf: TRoqModeCodebook;
begin
  LBoth := Make(rpfRgba32, True, True);
  LHalf := Make(rpfRgba32, True, False);
  try
    LBoth.Decode(TRoqTestBuilder.CodebookData(3, 2), (3 shl 8) or 2);
    LHalf.Decode(TRoqTestBuilder.CodebookData(3, 2), (3 shl 8) or 2);
    Assert.AreEqual(LHalf.Vq8Bytes, LBoth.Vq8Bytes);
    Assert.AreEqual(LHalf.Vq4Bytes, LBoth.Vq4Bytes);
  finally
    LHalf.Free;
    LBoth.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeRichiedereLaTabellaDeiGrigiDi256Livelli;
var
  LShort: TBytes;
begin
  Assert.WillRaise(
    procedure
    begin
      TRoqModeCodebook.Create(FConverter, Mode(rpfGray8, False, False), nil).Free;
    end, ERoqInvalidDataException);
  SetLength(LShort, 255);
  Assert.WillRaise(
    procedure
    begin
      TRoqModeCodebook.Create(FConverter, Mode(rpfGray8, False, False), LShort).Free;
    end, ERoqInvalidDataException);
  Assert.WillRaise(
    procedure
    begin
      TCinematicFactory.CreateModeCodebook(Mode(rpfGray8, False, False), ROQ_ALPHA_OPAQUE, LShort).Free;
    end, ERoqInvalidDataException);
end;

procedure TTestRoqModeCodebook.DovrebbeSollevareSeIDatiSonoTroncati;
var
  LCodebook: TRoqModeCodebook;
  LData: TBytes;
begin
  LCodebook := Make(rpfRgb565, False, False);
  try
    LData := TRoqTestBuilder.CodebookData(2, 2);
    SetLength(LData, Length(LData) - 1);
    Assert.WillRaise(
      procedure
      begin
        LCodebook.Decode(LData, (2 shl 8) or 2);
      end, ERoqTruncatedException);
    Assert.IsFalse(LCodebook.Loaded);
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeDimenticareTuttoConClear;
var
  LCodebook: TRoqModeCodebook;
  LBytes: TBytes;
begin
  LCodebook := Make(rpfRgba32, False, False);
  try
    LCodebook.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    Assert.IsTrue(LCodebook.Loaded);
    LCodebook.Clear;
    Assert.IsFalse(LCodebook.Loaded);
    LBytes := LCodebook.Vq2Bytes;
    Assert.AreEqual(0, Integer(WordAt(LBytes, 0)));
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeCodebook.DovrebbeLiberareIlConvertitoreDellaFabbrica;
var
  LOwned: TRoqModeCodebook;
begin
  // the factory gives the converter to the codebook: the test only needs it to decode and to be freed
  // without leaks (the runner reports them)
  LOwned := TCinematicFactory.CreateModeCodebook(Mode(rpfRgba32, False, False));
  try
    LOwned.Decode(TRoqTestBuilder.CodebookData(1, 0), $0100);
    Assert.IsTrue(LOwned.Loaded);
    // the alpha byte of the first pixel
    Assert.AreEqual($FF, Integer(LOwned.Vq2Bytes[3]));
  finally
    LOwned.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqModeCodebook);

end.
