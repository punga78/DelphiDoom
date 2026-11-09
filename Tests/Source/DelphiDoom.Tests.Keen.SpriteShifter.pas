{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the shifted copies of a sprite       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.SpriteShifter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenSpriteShifter = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeParoleDelleTabelleDelloAssembler;
    [Test]
    procedure DovrebbeNonSpostareConUnaTabellaDiZero;
    [TestCase('2', '2')]
    [TestCase('4', '4')]
    [TestCase('6', '6')]
    procedure DovrebbeSpostareIPixelVersoDestra(AShift: Integer);
    [Test]
    procedure DovrebbeRiempireDiUnoLaMaschera;
    [Test]
    procedure DovrebbeRiempireDiZeroIDati;
    [Test]
    procedure DovrebbeRifiutareUnaDestinazioneTroppoCorta;
    [Test]
    procedure DovrebbeRifiutareUnaMisuraNulla;
    [Test]
    procedure DovrebbeCalcolareLaDimensioneDeiPiani;
  end;

implementation

uses
  DelphiDoom.Keen.SpriteShifter, DelphiDoom.Keen.PlanarConverter;

const
  WIDTH_BYTES = 3;
  HEIGHT_ROWS = 5;

function MakeSource(ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := Byte(LIndex * 53 + 29);
end;

{ TTestKeenSpriteShifter }

procedure TTestKeenSpriteShifter.DovrebbeDareLeParoleDelleTabelleDelloAssembler;
begin
  // values read in shiftdata1, shiftdata2 and shiftdata7 of id_vw_a.asm
  Assert.AreEqual(Word(32768), TKeenSpriteShifter.ShiftWord(1, 1));
  Assert.AreEqual(Word(32769), TKeenSpriteShifter.ShiftWord(3, 1));
  Assert.AreEqual(Word(16384), TKeenSpriteShifter.ShiftWord(1, 2));
  Assert.AreEqual(Word(49155), TKeenSpriteShifter.ShiftWord(15, 2));
  Assert.AreEqual(Word(1), TKeenSpriteShifter.ShiftWord(4, 2));
  Assert.AreEqual(Word(24576), TKeenSpriteShifter.ShiftWord(3, 3));
  Assert.AreEqual(Word(1), TKeenSpriteShifter.ShiftWord(8, 3));
end;

procedure TTestKeenSpriteShifter.DovrebbeNonSpostareConUnaTabellaDiZero;
begin
  Assert.AreEqual(Word($AB), TKeenSpriteShifter.ShiftWord($AB, 0));
end;

procedure TTestKeenSpriteShifter.DovrebbeSpostareIPixelVersoDestra(AShift: Integer);
var
  LData: TBytes;
  LSmallSize: Integer;
  LBigOffset: Integer;
  LPlain: TKeenChunkyImage;
  LShifted: TKeenChunkyImage;
  LMaskPlain: TBytes;
  LMaskShifted: TBytes;
  LX: Integer;
  LY: Integer;
begin
  LSmallSize := WIDTH_BYTES * HEIGHT_ROWS * 5;
  LBigOffset := LSmallSize;
  LData := MakeSource(LSmallSize + (WIDTH_BYTES + 1) * HEIGHT_ROWS * 5);
  TKeenSpriteShifter.ShiftSprite(LData, 0, LBigOffset, WIDTH_BYTES, HEIGHT_ROWS, AShift);
  LPlain := TKeenPlanarConverter.ToChunkyMasked(LData, 0, WIDTH_BYTES, HEIGHT_ROWS, LMaskPlain);
  LShifted := TKeenPlanarConverter.ToChunkyMasked(LData, LBigOffset, WIDTH_BYTES + 1, HEIGHT_ROWS, LMaskShifted);
  for LY := 0 to HEIGHT_ROWS - 1 do
    for LX := 0 to WIDTH_BYTES * 8 - 1 do
    begin
      Assert.AreEqual(Integer(LPlain.Pixels[LY * WIDTH_BYTES * 8 + LX]),
        Integer(LShifted.Pixels[LY * (WIDTH_BYTES + 1) * 8 + LX + AShift]));
      Assert.AreEqual(Integer(LMaskPlain[LY * WIDTH_BYTES * 8 + LX]),
        Integer(LMaskShifted[LY * (WIDTH_BYTES + 1) * 8 + LX + AShift]));
    end;
end;

procedure TTestKeenSpriteShifter.DovrebbeRiempireDiUnoLaMaschera;
var
  LData: TBytes;
  LShifted: TKeenChunkyImage;
  LMask: TBytes;
  LY: Integer;
  LX: Integer;
begin
  LData := MakeSource(WIDTH_BYTES * HEIGHT_ROWS * 5 + (WIDTH_BYTES + 1) * HEIGHT_ROWS * 5);
  TKeenSpriteShifter.ShiftSprite(LData, 0, WIDTH_BYTES * HEIGHT_ROWS * 5, WIDTH_BYTES, HEIGHT_ROWS, 4);
  LShifted := TKeenPlanarConverter.ToChunkyMasked(LData, WIDTH_BYTES * HEIGHT_ROWS * 5, WIDTH_BYTES + 1,
    HEIGHT_ROWS, LMask);
  // the pixels that the shift adds, at the left and at the right of each row, leave the screen as it is
  for LY := 0 to HEIGHT_ROWS - 1 do
  begin
    for LX := 0 to 3 do
      Assert.AreEqual(15, Integer(LMask[LY * (WIDTH_BYTES + 1) * 8 + LX]));
    for LX := WIDTH_BYTES * 8 + 4 to (WIDTH_BYTES + 1) * 8 - 1 do
      Assert.AreEqual(15, Integer(LMask[LY * (WIDTH_BYTES + 1) * 8 + LX]));
  end;
end;

procedure TTestKeenSpriteShifter.DovrebbeRiempireDiZeroIDati;
var
  LData: TBytes;
  LShifted: TKeenChunkyImage;
  LMask: TBytes;
  LY: Integer;
  LX: Integer;
begin
  LData := MakeSource(WIDTH_BYTES * HEIGHT_ROWS * 5 + (WIDTH_BYTES + 1) * HEIGHT_ROWS * 5);
  TKeenSpriteShifter.ShiftSprite(LData, 0, WIDTH_BYTES * HEIGHT_ROWS * 5, WIDTH_BYTES, HEIGHT_ROWS, 6);
  LShifted := TKeenPlanarConverter.ToChunkyMasked(LData, WIDTH_BYTES * HEIGHT_ROWS * 5, WIDTH_BYTES + 1,
    HEIGHT_ROWS, LMask);
  for LY := 0 to HEIGHT_ROWS - 1 do
  begin
    for LX := 0 to 5 do
      Assert.AreEqual(0, Integer(LShifted.Pixels[LY * (WIDTH_BYTES + 1) * 8 + LX]));
    for LX := WIDTH_BYTES * 8 + 6 to (WIDTH_BYTES + 1) * 8 - 1 do
      Assert.AreEqual(0, Integer(LShifted.Pixels[LY * (WIDTH_BYTES + 1) * 8 + LX]));
  end;
end;

procedure TTestKeenSpriteShifter.DovrebbeRifiutareUnaDestinazioneTroppoCorta;
var
  LData: TBytes;
begin
  LData := MakeSource(WIDTH_BYTES * HEIGHT_ROWS * 5 + 10);
  Assert.WillRaise(
    procedure
    begin
      TKeenSpriteShifter.ShiftSprite(LData, 0, WIDTH_BYTES * HEIGHT_ROWS * 5, WIDTH_BYTES, HEIGHT_ROWS, 2);
    end, EKeenDataException);
end;

procedure TTestKeenSpriteShifter.DovrebbeRifiutareUnaMisuraNulla;
var
  LData: TBytes;
begin
  LData := MakeSource(100);
  Assert.WillRaise(
    procedure
    begin
      TKeenSpriteShifter.ShiftSprite(LData, 0, 50, 0, 3, 2);
    end, EKeenException);
end;

procedure TTestKeenSpriteShifter.DovrebbeCalcolareLaDimensioneDeiPiani;
begin
  Assert.AreEqual(4 * 5 * 5, TKeenSpriteShifter.ShiftedSize(3, 5));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenSpriteShifter);

end.
