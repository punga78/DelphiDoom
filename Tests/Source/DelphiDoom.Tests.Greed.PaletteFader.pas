{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the fades of the palette            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PaletteFader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.PaletteFader;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedPaletteFader = class(TObject)
  strict private
    FFader: TGreedPaletteFader;
    function Flat(AValue: Byte): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRiempireLaPalettaConUnColore;
    [Test]
    procedure DovrebbeTrovareIlColorePiuVicinoAlloZero;
    [Test]
    procedure DovrebbeFermarsiAlPrimoColoreUgualeAlloZero;
    [Test]
    procedure DovrebbeNonEssereAttivoPrimaDiUnaDissolvenza;
    [Test]
    procedure DovrebbeScendereAlColoreInTantiPassiPiuUno;
    [Test]
    procedure DovrebbeLasciareIColoriFuoriDallIntervalloFinoAllUltimoPasso;
    [Test]
    procedure DovrebbeSalireDalNeroAllaPalettaData;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCorta;
    [Test]
    procedure DovrebbeRifiutareZeroPassi;
  end;

implementation

{ TTestGreedPaletteFader }

procedure TTestGreedPaletteFader.Setup;
begin
  FFader := TGreedPaletteFader.Create;
end;

procedure TTestGreedPaletteFader.TearDown;
begin
  FFader.Free;
end;

function TTestGreedPaletteFader.Flat(AValue: Byte): TBytes;
begin
  Result := TGreedPaletteFader.FillPalette(AValue, AValue, AValue);
end;

procedure TTestGreedPaletteFader.DovrebbeRiempireLaPalettaConUnColore;
var
  LPalette: TBytes;
begin
  LPalette := TGreedPaletteFader.FillPalette(1, 2, 3);
  Assert.AreEqual(768, Integer(Length(LPalette)));
  Assert.AreEqual(Byte(1), LPalette[0]);
  Assert.AreEqual(Byte(2), LPalette[766]);
  Assert.AreEqual(Byte(3), LPalette[767]);
end;

procedure TTestGreedPaletteFader.DovrebbeTrovareIlColorePiuVicinoAlloZero;
var
  LPalette: TBytes;
begin
  LPalette := Flat(60);
  LPalette[0] := 0;
  LPalette[1] := 0;
  LPalette[2] := 0;
  // the color 9 is (3, 0, 0) and the color 20 is (2, 2, 2): 9 against 12
  LPalette[27] := 3;
  LPalette[28] := 0;
  LPalette[29] := 0;
  LPalette[60] := 2;
  LPalette[61] := 2;
  LPalette[62] := 2;
  Assert.AreEqual(Byte(9), TGreedPaletteFader.ApproximateZero(LPalette));
end;

procedure TTestGreedPaletteFader.DovrebbeFermarsiAlPrimoColoreUgualeAlloZero;
var
  LPalette: TBytes;
  LIndex: Integer;
begin
  SetLength(LPalette, 768);
  for LIndex := 0 to 767 do
    LPalette[LIndex] := LIndex div 3;
  LPalette[15] := 0;
  LPalette[16] := 0;
  LPalette[17] := 0;
  LPalette[30] := 0;
  LPalette[31] := 0;
  LPalette[32] := 0;
  Assert.AreEqual(Byte(5), TGreedPaletteFader.ApproximateZero(LPalette));
  // every color the same: the first one after the 0
  Assert.AreEqual(Byte(1), TGreedPaletteFader.ApproximateZero(Flat(7)));
end;

procedure TTestGreedPaletteFader.DovrebbeNonEssereAttivoPrimaDiUnaDissolvenza;
begin
  Assert.IsFalse(FFader.Active);
  Assert.IsFalse(FFader.Step);
  Assert.AreEqual(768, Integer(Length(FFader.Current)));
end;

procedure TTestGreedPaletteFader.DovrebbeScendereAlColoreInTantiPassiPiuUno;
var
  LSteps: Integer;
  LLast: Byte;
begin
  FFader.StartFadeOut(Flat(63), 0, 256, 0, 0, 0, 10);
  Assert.AreEqual(Byte(63), FFader.Current[5], 'before the first step the palette is the one shown');
  LSteps := 0;
  LLast := 63;
  while FFader.Step do
  begin
    Inc(LSteps);
    Assert.IsTrue(FFader.Current[5] <= LLast, 'never brighter');
    LLast := FFader.Current[5];
    if LSteps = 1 then
      // 63 div 10 = 6, and the remainders (3 a step) have not made a whole step yet
      Assert.AreEqual(Byte(57), LLast);
  end;
  Assert.AreEqual(11, LSteps, 'ten steps and the flat color');
  Assert.AreEqual(Byte(0), LLast);
  Assert.IsFalse(FFader.Active);
end;

procedure TTestGreedPaletteFader.DovrebbeLasciareIColoriFuoriDallIntervalloFinoAllUltimoPasso;
var
  LIndex: Integer;
begin
  FFader.StartFadeOut(Flat(40), 10, 20, 5, 5, 5, 4);
  for LIndex := 1 to 4 do
  begin
    Assert.IsTrue(FFader.Step);
    Assert.AreEqual(Byte(40), FFader.Current[0]);
    Assert.AreEqual(Byte(40), FFader.Current[20 * 3]);
  end;
  Assert.AreEqual(Byte(5), FFader.Current[10 * 3], 'the colors of the interval are at the target after the steps');
  Assert.AreEqual(Byte(5), FFader.Current[19 * 3 + 2]);
  // the end is VI_FillPalette: every color
  Assert.IsTrue(FFader.Step);
  Assert.AreEqual(Byte(5), FFader.Current[0]);
  Assert.IsFalse(FFader.Step);
end;

procedure TTestGreedPaletteFader.DovrebbeSalireDalNeroAllaPalettaData;
var
  LTarget: TBytes;
  LSteps: Integer;
begin
  LTarget := Flat(50);
  LTarget[3] := 13;
  FFader.StartFadeIn(Flat(0), LTarget, 0, 256, 8);
  Assert.AreEqual(Byte(0), FFader.Current[3]);
  LSteps := 0;
  while FFader.Step do
  begin
    Inc(LSteps);
    if LSteps = 8 then
    begin
      Assert.AreEqual(Byte(13), FFader.Current[3]);
      Assert.AreEqual(Byte(50), FFader.Current[4]);
    end;
  end;
  Assert.AreEqual(9, LSteps);
  Assert.AreEqual(Byte(13), FFader.Current[3]);
  Assert.AreEqual(Byte(50), FFader.Current[767]);
end;

procedure TTestGreedPaletteFader.DovrebbeRifiutareUnaPalettaCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      FFader.StartFadeOut(TBytes.Create(1, 2, 3), 0, 256, 0, 0, 0, 4);
    end, EGreedDataException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPaletteFader.ApproximateZero(nil);
    end, EGreedDataException);
end;

procedure TTestGreedPaletteFader.DovrebbeRifiutareZeroPassi;
begin
  Assert.WillRaise(
    procedure
    begin
      FFader.StartFadeIn(Flat(0), Flat(1), 0, 256, 0);
    end, EGreedException);
end;

end.
