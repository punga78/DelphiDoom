{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingSpanGrower                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.SpanGrower;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.SpanGrower, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingSpanGrower = class(TObject)
  private
    FGrower: IImagingSpanGrower;
    function Source(ASeed: Integer): TImagingPixels;
    function Solid(AColor: Cardinal): TImagingPixels;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestGrowMatchesOldCodeInEveryCase;
    [Test]
    procedure TestGrowGivesTheSizeOfTheNewFlat;
    [Test]
    procedure TestGrow128KeepsTheOriginalPixelsAtEvenPositions;
    [Test]
    procedure TestGrowOfASolidFlatKeepsTheColor;
    [Test]
    procedure TestGrow256BlendsWithTheNeighbors;
    [Test]
    procedure TestGrowWrapsAroundTheEdges;
    [Test]
    procedure TestGrowOfALongerSourceUsesTheFirst4096;
    [Test]
    procedure TestGrowOfAShortSourceRaises;
  end;

implementation

function TTestImagingSpanGrower.Source(ASeed: Integer): TImagingPixels;
begin
  Result := TImagingSamples.RandomPixels(Cardinal(ASeed), 4096, $00FFFFFF);
end;

function TTestImagingSpanGrower.Solid(AColor: Cardinal): TImagingPixels;
var
  LIndex: Integer;
begin
  SetLength(Result, 4096);
  for LIndex := 0 to 4095 do
    Result[LIndex] := AColor;
end;

procedure TTestImagingSpanGrower.Setup;
begin
  FGrower := TImagingSpanGrower.Create;
end;

procedure TTestImagingSpanGrower.TestGrowMatchesOldCodeInEveryCase;
var
  LSeed: Integer;
  LMasks: array[0..2] of Cardinal;
  LSource: TImagingPixels;
  LIndex: Integer;
begin
  LMasks[0] := $00FFFFFF;
  LMasks[1] := $FFFFFFFF;
  LMasks[2] := $00FFFFFF;
  for LSeed := 0 to 2 do
  begin
    LSource := TImagingSamples.RandomPixels(Cardinal(LSeed) + 31, 4096, LMasks[LSeed]);
    if LSeed = 2 then
      for LIndex := 0 to 4095 do
        LSource[LIndex] := $00336699;
    TImagingGolden.Check('grow.golden.txt', 'source_' + IntToStr(LSeed),
      TImagingSamples.Hex(TImagingSamples.Hash(FGrower.Grow64to128(LSource))) + ':' +
      TImagingSamples.Hex(TImagingSamples.Hash(FGrower.Grow64to256(LSource))) + ':' +
      TImagingSamples.Hex(TImagingSamples.Hash(FGrower.Grow64to512(LSource))));
  end;
end;

procedure TTestImagingSpanGrower.TestGrowGivesTheSizeOfTheNewFlat;
begin
  Assert.AreEqual(128 * 128, Length(FGrower.Grow64to128(Source(1))), 'dovrebbe dare 128x128 pixel');
  Assert.AreEqual(256 * 256, Length(FGrower.Grow64to256(Source(1))), 'dovrebbe dare 256x256 pixel');
  Assert.AreEqual(512 * 512, Length(FGrower.Grow64to512(Source(1))), 'dovrebbe dare 512x512 pixel');
end;

procedure TTestImagingSpanGrower.TestGrow128KeepsTheOriginalPixelsAtEvenPositions;
var
  LSource, LGrown: TImagingPixels;
  LRow, LColumn: Integer;
begin
  LSource := Source(2);
  LGrown := FGrower.Grow64to128(LSource);
  for LRow := 0 to 63 do
    for LColumn := 0 to 63 do
      if LGrown[LRow * 2 * 128 + LColumn * 2] <> LSource[LRow * 64 + LColumn] then
        Assert.Fail(Format('dovrebbe tenere il pixel originale (%d, %d)', [LColumn, LRow]));
  Assert.Pass;
end;

procedure TTestImagingSpanGrower.TestGrowOfASolidFlatKeepsTheColor;
var
  LGrown: TImagingPixels;
begin
  LGrown := FGrower.Grow64to128(Solid($00404040));
  Assert.AreEqual(Cardinal($00404040), LGrown[0], 'dovrebbe tenere il colore nel pixel originale');
  Assert.AreEqual(Cardinal($00404040), LGrown[1], 'dovrebbe dare lo stesso colore tra due uguali');
  Assert.AreEqual(Cardinal($00404040), LGrown[129], 'dovrebbe dare lo stesso colore al centro');
end;

procedure TTestImagingSpanGrower.TestGrow256BlendsWithTheNeighbors;
var
  LSource, LGrown: TImagingPixels;
begin
  LSource := Solid($00000000);
  LSource[1] := $00FFFFFF;
  LGrown := FGrower.Grow64to256(LSource);
  // from the pixel 0 (black) to the pixel 1 (white): each step of 4 gets lighter
  Assert.IsTrue(Byte(LGrown[0]) < Byte(LGrown[2]), 'dovrebbe schiarire andando verso il vicino bianco');
  Assert.IsTrue(Byte(LGrown[2]) < Byte(LGrown[3]), 'dovrebbe continuare a schiarire');
end;

procedure TTestImagingSpanGrower.TestGrowWrapsAroundTheEdges;
var
  LSource, LGrown: TImagingPixels;
begin
  LSource := Solid($00000000);
  LSource[0] := $00FFFFFF;
  LGrown := FGrower.Grow64to128(LSource);
  // the last pixel of the first row blends with the first of the row (it wraps)
  Assert.AreNotEqual(Cardinal(0), LGrown[127], 'dovrebbe mescolare l''ultimo pixel della riga con il primo');
end;

procedure TTestImagingSpanGrower.TestGrowOfALongerSourceUsesTheFirst4096;
var
  LLong: TImagingPixels;
begin
  LLong := TImagingSamples.RandomPixels(5, 8192, $00FFFFFF);
  Assert.AreEqual(TImagingSamples.Hex(TImagingSamples.Hash(FGrower.Grow64to128(Copy(LLong, 0, 4096)))),
    TImagingSamples.Hex(TImagingSamples.Hash(FGrower.Grow64to128(LLong))), 'dovrebbe usare solo i primi 4096 pixel');
end;

procedure TTestImagingSpanGrower.TestGrowOfAShortSourceRaises;
var
  LShort: TImagingPixels;
begin
  SetLength(LShort, 100);
  Assert.WillRaise(
    procedure
    begin
      FGrower.Grow64to128(LShort);
    end, EImagingException, 'dovrebbe rifiutare meno di 4096 pixel');
end;

end.
