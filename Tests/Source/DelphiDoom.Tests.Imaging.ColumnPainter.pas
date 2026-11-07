{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingColumnPainter                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ColumnPainter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf, DelphiDoom.Imaging.ColumnPainter,
  DelphiDoom.Tests.Imaging.Samples, DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingColumnPainter = class(TObject)
  private
    FPainter: IImagingColumnPainter;
    function Post(ATopDelta, ALength, ASeed: Integer): TSamplePost;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestPaintMatchesOldCodeInEveryCase;
    [Test]
    procedure TestPaintCopiesAPostAtItsTopDelta;
    [Test]
    procedure TestPaintMarksOnlyTheCopiedPixels;
    [Test]
    procedure TestPaintWithoutMarksLeavesTheMarksAlone;
    [Test]
    procedure TestPaintUsesTheOffsets;
    [Test]
    procedure TestPaintClipsAtTheBottom;
    [Test]
    procedure TestPaintClippedAtTheTopCopiesTheFirstPixelsOfThePost;
    [Test]
    procedure TestPaintOfAColumnWithoutEndRaises;
    [Test]
    procedure TestPaintOfATruncatedPostRaises;
    [Test]
    procedure TestPaintWithSmallCacheRaises;
    [Test]
    procedure TestPaintOfAColumnWithoutPostsNeedsNoRoom;
    [Test]
    procedure TestPaintWithSmallMarksRaises;
  end;

implementation

function TTestImagingColumnPainter.Post(ATopDelta, ALength, ASeed: Integer): TSamplePost;
begin
  Result.TopDelta := ATopDelta;
  Result.Length := ALength;
  Result.Seed := ASeed;
end;

procedure TTestImagingColumnPainter.Setup;
begin
  FPainter := TImagingColumnPainter.Create;
end;

procedure TTestImagingColumnPainter.TestPaintMatchesOldCodeInEveryCase;
var
  LCases: TArray<TSamplePainterCase>;
  LCase: TSamplePainterCase;
  LCache, LMarks: TBytes;
begin
  LCases := TImagingSamples.PainterCases;
  for LCase in LCases do
  begin
    SetLength(LCache, LCase.CacheHeight);
    SetLength(LMarks, LCase.CacheHeight);
    if LCase.CacheHeight > 0 then
    begin
      FillChar(LCache[0], LCase.CacheHeight, 0);
      FillChar(LMarks[0], LCase.CacheHeight, 0);
    end;
    FPainter.Paint(LCase.Column, 0, LCache, 0, LCase.OriginY, LCase.CacheHeight, LMarks, 0);
    TImagingGolden.Check('painter.golden.txt', LCase.Name,
      TImagingSamples.Hex(TImagingSamples.Hash(LCache)) + '/' +
      TImagingSamples.Hex(TImagingSamples.Hash(LMarks)));
  end;
end;

procedure TTestImagingColumnPainter.TestPaintCopiesAPostAtItsTopDelta;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(3, 2, 1)]);
  LCache := TImagingSamples.ZeroBytes(8);
  FPainter.Paint(LColumn, 0, LCache, 0, 0, 8, nil, 0);
  Assert.AreEqual(Integer(0), Integer(LCache[2]), 'dovrebbe lasciare vuoto sopra il post');
  Assert.AreEqual(Integer(LColumn[3]), Integer(LCache[3]), 'dovrebbe copiare il primo pixel del post');
  Assert.AreEqual(Integer(LColumn[4]), Integer(LCache[4]), 'dovrebbe copiare il secondo pixel del post');
  Assert.AreEqual(Integer(0), Integer(LCache[5]), 'dovrebbe lasciare vuoto sotto il post');
end;

procedure TTestImagingColumnPainter.TestPaintMarksOnlyTheCopiedPixels;
var
  LColumn, LCache, LMarks: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(1, 2, 1), Post(5, 1, 2)]);
  LCache := TImagingSamples.ZeroBytes(8);
  LMarks := TImagingSamples.ZeroBytes(8);
  FPainter.Paint(LColumn, 0, LCache, 0, 0, 8, LMarks, 0);
  Assert.AreEqual('00FFFF0000FF0000', IntToHex(LMarks[0], 2) + IntToHex(LMarks[1], 2) +
    IntToHex(LMarks[2], 2) + IntToHex(LMarks[3], 2) + IntToHex(LMarks[4], 2) +
    IntToHex(LMarks[5], 2) + IntToHex(LMarks[6], 2) + IntToHex(LMarks[7], 2),
    'dovrebbe segnare $FF solo i pixel dei post');
end;

procedure TTestImagingColumnPainter.TestPaintWithoutMarksLeavesTheMarksAlone;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 4, 1)]);
  LCache := TImagingSamples.ZeroBytes(4);
  FPainter.Paint(LColumn, 0, LCache, 0, 0, 4, nil, 0);
  Assert.AreEqual(Integer(LColumn[3]), Integer(LCache[0]), 'dovrebbe dipingere anche senza segni');
end;

procedure TTestImagingColumnPainter.TestPaintUsesTheOffsets;
var
  LColumn, LSource, LCache, LMarks: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(1, 2, 1)]);
  // the column is not at the start of the bytes, the cache and the marks neither
  SetLength(LSource, 5 + Length(LColumn));
  Move(LColumn[0], LSource[5], Length(LColumn));
  LCache := TImagingSamples.ZeroBytes(10);
  LMarks := TImagingSamples.ZeroBytes(12);
  FPainter.Paint(LSource, 5, LCache, 4, 0, 6, LMarks, 3);
  Assert.AreEqual(Integer(0), Integer(LCache[4]), 'dovrebbe lasciare il primo pixel della cache');
  Assert.AreEqual(Integer(LColumn[3]), Integer(LCache[5]), 'dovrebbe scrivere dopo lo scostamento della cache');
  Assert.AreEqual(Integer($FF), Integer(LMarks[4]), 'dovrebbe segnare dopo lo scostamento dei segni');
  Assert.AreEqual(Integer(0), Integer(LMarks[0]), 'non dovrebbe toccare i segni prima dello scostamento');
end;

procedure TTestImagingColumnPainter.TestPaintClipsAtTheBottom;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(2, 10, 1)]);
  LCache := TImagingSamples.ZeroBytes(6);
  FPainter.Paint(LColumn, 0, LCache, 0, 0, 4, nil, 0);
  Assert.AreEqual(Integer(0), Integer(LCache[4]), 'non dovrebbe scrivere oltre l''altezza chiesta');
  Assert.AreEqual(Integer(LColumn[4]), Integer(LCache[3]), 'dovrebbe scrivere fino all''altezza chiesta');
end;

procedure TTestImagingColumnPainter.TestPaintClippedAtTheTopCopiesTheFirstPixelsOfThePost;
var
  LColumn, LCache: TBytes;
begin
  // difetto del vecchio codice, conservato: con origine -2 il post comincia 2 righe sopra la
  // cache, ma si copiano i suoi primi pixel e non quelli dentro la cache
  LColumn := TImagingSamples.Column([Post(0, 4, 1)]);
  LCache := TImagingSamples.ZeroBytes(4);
  FPainter.Paint(LColumn, 0, LCache, 0, -2, 4, nil, 0);
  Assert.AreEqual(Integer(LColumn[3]), Integer(LCache[0]), 'dovrebbe copiare il primo pixel del post');
  Assert.AreEqual(Integer(LColumn[4]), Integer(LCache[1]), 'dovrebbe copiare il secondo pixel del post');
  Assert.AreEqual(Integer(0), Integer(LCache[2]), 'dovrebbe copiare solo i pixel che restano');
end;

procedure TTestImagingColumnPainter.TestPaintOfAColumnWithoutEndRaises;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 2, 1)]);
  SetLength(LColumn, Length(LColumn) - 1);
  LCache := TImagingSamples.ZeroBytes(4);
  Assert.WillRaise(
    procedure
    begin
      FPainter.Paint(LColumn, 0, LCache, 0, 0, 4, nil, 0);
    end, EImagingException, 'dovrebbe rifiutare una colonna che non finisce');
end;

procedure TTestImagingColumnPainter.TestPaintOfATruncatedPostRaises;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 6, 1)]);
  SetLength(LColumn, 6);
  LCache := TImagingSamples.ZeroBytes(8);
  Assert.WillRaise(
    procedure
    begin
      FPainter.Paint(LColumn, 0, LCache, 0, 0, 8, nil, 0);
    end, EImagingException, 'dovrebbe rifiutare un post che esce dai byte');
end;

procedure TTestImagingColumnPainter.TestPaintWithSmallCacheRaises;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 4, 1)]);
  LCache := TImagingSamples.ZeroBytes(3);
  Assert.WillRaise(
    procedure
    begin
      FPainter.Paint(LColumn, 0, LCache, 0, 0, 4, nil, 0);
    end, EImagingException, 'dovrebbe rifiutare una cache piu'' piccola dell''altezza');
end;

// Regressione: l'ultima colonna di una texture con patch senza post sta in un blocco
// che finisce due byte prima dell'altezza; il vecchio codice non scriveva nulla e andava bene
procedure TTestImagingColumnPainter.TestPaintOfAColumnWithoutPostsNeedsNoRoom;
var
  LColumn, LCache: TBytes;
begin
  LColumn := TImagingSamples.Column([]);
  LCache := TImagingSamples.ZeroBytes(2);
  FPainter.Paint(LColumn, 0, LCache, 0, 0, 4, nil, 0);
  Assert.AreEqual(Integer(0), Integer(LCache[0]), 'dovrebbe lasciare la cache com''e'''); 
end;

procedure TTestImagingColumnPainter.TestPaintWithSmallMarksRaises;
var
  LColumn, LCache, LMarks: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 2, 1)]);
  LCache := TImagingSamples.ZeroBytes(4);
  LMarks := TImagingSamples.ZeroBytes(3);
  Assert.WillRaise(
    procedure
    begin
      FPainter.Paint(LColumn, 0, LCache, 0, 0, 4, LMarks, 0);
    end, EImagingException, 'dovrebbe rifiutare segni piu'' piccoli dell''altezza');
end;

end.
