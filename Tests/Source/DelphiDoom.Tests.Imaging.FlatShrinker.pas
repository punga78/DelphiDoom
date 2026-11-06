{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingFlatShrinker                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.FlatShrinker;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.FlatShrinker, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingFlatShrinker = class(TObject)
  private
    FShrinker: IImagingFlatShrinker;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestShrinkMatchesOldCodeInEveryCase;
    [Test]
    procedure TestShrinkKeepsA64x64Flat;
    [Test]
    procedure TestShrinkKeepsTheFirstHalfOfA64x128Flat;
    [Test]
    procedure TestShrinkOf128TakesOnePixelEveryTwo;
    [Test]
    procedure TestShrinkWritesWithAStrideOf64;
    [Test]
    procedure TestShrinkOfAnotherLengthFails;
    [Test]
    procedure TestShrinkOfAnEmptyLumpFails;
  end;

implementation

procedure TTestImagingFlatShrinker.Setup;
begin
  FShrinker := TImagingFlatShrinker.Create;
end;

procedure TTestImagingFlatShrinker.TestShrinkMatchesOldCodeInEveryCase;
var
  LLength: Integer;
  LResult: TBytes;
  LActual: string;
begin
  for LLength in TImagingSamples.ShrinkLengths do
  begin
    if FShrinker.Shrink(TImagingSamples.RandomBytes(Cardinal(LLength) + 5, LLength), LResult) then
      LActual := 'ok:' + TImagingSamples.Hex(TImagingSamples.Hash(LResult))
    else
      LActual := 'no';
    TImagingGolden.Check('shrink.golden.txt', IntToStr(LLength), LActual);
  end;
end;

procedure TTestImagingFlatShrinker.TestShrinkKeepsA64x64Flat;
var
  LFlat, LResult: TBytes;
begin
  LFlat := TImagingSamples.RandomBytes(3, 4096);
  Assert.IsTrue(FShrinker.Shrink(LFlat, LResult), 'dovrebbe riconoscere il flat 64x64');
  Assert.AreEqual(TImagingSamples.Hex(TImagingSamples.Hash(LFlat)),
    TImagingSamples.Hex(TImagingSamples.Hash(LResult)), 'dovrebbe dare gli stessi pixel');
end;

procedure TTestImagingFlatShrinker.TestShrinkKeepsTheFirstHalfOfA64x128Flat;
var
  LFlat, LResult: TBytes;
begin
  LFlat := TImagingSamples.RandomBytes(4, 8192);
  Assert.IsTrue(FShrinker.Shrink(LFlat, LResult), 'dovrebbe riconoscere il flat 64x128');
  Assert.AreEqual(4096, Length(LResult), 'dovrebbe dare 4096 pixel');
  Assert.AreEqual(Integer(LFlat[4095]), Integer(LResult[4095]), 'dovrebbe tenere i primi 4096 pixel');
end;

procedure TTestImagingFlatShrinker.TestShrinkOf128TakesOnePixelEveryTwo;
var
  LFlat, LResult: TBytes;
begin
  LFlat := TImagingSamples.RandomBytes(5, 16384);
  Assert.IsTrue(FShrinker.Shrink(LFlat, LResult), 'dovrebbe riconoscere il flat 128x128');
  Assert.AreEqual(Integer(LFlat[0]), Integer(LResult[0]), 'dovrebbe tenere il primo pixel');
  Assert.AreEqual(Integer(LFlat[2]), Integer(LResult[1]), 'dovrebbe saltare un pixel a destra');
  Assert.AreEqual(Integer(LFlat[256]), Integer(LResult[64]), 'dovrebbe saltare una riga sotto');
end;

procedure TTestImagingFlatShrinker.TestShrinkWritesWithAStrideOf64;
var
  LFlat, LResult: TBytes;
begin
  // il vecchio codice scriveva con passo 128 e usciva dal buffer di 4096 byte
  LFlat := TImagingSamples.RandomBytes(6, 65536);
  Assert.IsTrue(FShrinker.Shrink(LFlat, LResult), 'dovrebbe riconoscere il flat 256x256');
  Assert.AreEqual(4096, Length(LResult), 'dovrebbe dare 4096 pixel');
  Assert.AreEqual(Integer(LFlat[4 * 256 + 4]), Integer(LResult[64 + 1]), 'dovrebbe mettere la riga 1 subito dopo la riga 0');
  Assert.AreEqual(Integer(LFlat[63 * 4 * 256 + 63 * 4]), Integer(LResult[4095]), 'dovrebbe riempire fino all''ultimo pixel');
end;

procedure TTestImagingFlatShrinker.TestShrinkOfAnotherLengthFails;
var
  LResult: TBytes;
begin
  Assert.IsFalse(FShrinker.Shrink(TImagingSamples.RandomBytes(7, 5000), LResult), 'dovrebbe rifiutare una lunghezza che non e'' di un flat');
  Assert.AreEqual(0, Length(LResult), 'non dovrebbe dare pixel');
end;

procedure TTestImagingFlatShrinker.TestShrinkOfAnEmptyLumpFails;
var
  LResult: TBytes;
begin
  Assert.IsFalse(FShrinker.Shrink(nil, LResult), 'dovrebbe rifiutare un lump vuoto');
end;

end.
