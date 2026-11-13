{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingFixedColumnBuilder                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.FixedColumn;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf, DelphiDoom.Imaging.FixedColumn,
  DelphiDoom.Tests.Imaging.Samples, DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingFixedColumn = class(TObject)
  private
    FBuilder: IImagingFixedColumnBuilder;
    function Post(ATopDelta, ALength, ASeed: Integer): TSamplePost;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestRepeat128MatchesOldCodeInEveryCase;
    [Test]
    procedure TestFromPostsMatchesOldCodeInEveryCase;
    [Test]
    procedure TestRepeat128RepeatsTheColumn;
    [Test]
    procedure TestRepeat128OfAColumnOf128KeepsIt;
    [Test]
    procedure TestRepeat128WithBadHeightRaises;
    [Test]
    procedure TestRepeat128PastTheEndOfTheBytesRaises;
    [Test]
    procedure TestFromPostsLeavesZeroWhereThereIsNoPost;
    [Test]
    procedure TestFromPostsOfAColumnWithoutEndRaises;
    [Test]
    procedure TestFromPostsOfATruncatedPostRaises;
    [Test]
    procedure TestFromPostsWithNegativeHeightRaises;
  end;

implementation

function TTestImagingFixedColumn.Post(ATopDelta, ALength, ASeed: Integer): TSamplePost;
begin
  Result.TopDelta := ATopDelta;
  Result.Length := ALength;
  Result.Seed := ASeed;
end;

procedure TTestImagingFixedColumn.Setup;
begin
  FBuilder := TImagingFixedColumnBuilder.Create;
end;

procedure TTestImagingFixedColumn.TestRepeat128MatchesOldCodeInEveryCase;
var
  LCase: TSampleFixedCase;
begin
  for LCase in TImagingSamples.FixedRepeatCases do
    TImagingGolden.Check('fixed_repeat.golden.txt', LCase.Name,
      TImagingSamples.Hex(TImagingSamples.Hash(FBuilder.Repeat128(LCase.Column, 3, LCase.Height))));
end;

procedure TTestImagingFixedColumn.TestFromPostsMatchesOldCodeInEveryCase;
var
  LCase: TSampleFixedCase;
begin
  for LCase in TImagingSamples.FixedPostCases do
    TImagingGolden.Check('fixed_posts.golden.txt', LCase.Name,
      TImagingSamples.Hex(TImagingSamples.Hash(FBuilder.FromPosts(LCase.Column, 0, LCase.Height))));
end;

procedure TTestImagingFixedColumn.TestRepeat128RepeatsTheColumn;
var
  LResult: TBytes;
  LSource: TBytes;
  LIndex: Integer;
begin
  LSource := TBytes.Create(1, 2, 3, 4);
  LResult := FBuilder.Repeat128(LSource, 0, 4);
  Assert.AreEqual<Integer>(128, Length(LResult), 'dovrebbe dare 128 pixel');
  for LIndex := 0 to 127 do
    Assert.AreEqual(Integer(LSource[LIndex mod 4]), Integer(LResult[LIndex]), 'dovrebbe ripetere la colonna al pixel ' + IntToStr(LIndex));
end;

procedure TTestImagingFixedColumn.TestRepeat128OfAColumnOf128KeepsIt;
var
  LSource: TBytes;
begin
  LSource := TImagingSamples.RandomBytes(5, 128);
  Assert.AreEqual(TImagingSamples.Hex(TImagingSamples.Hash(LSource)),
    TImagingSamples.Hex(TImagingSamples.Hash(FBuilder.Repeat128(LSource, 0, 128))), 'dovrebbe lasciare uguale una colonna di 128');
end;

procedure TTestImagingFixedColumn.TestRepeat128WithBadHeightRaises;
var
  LSource: TBytes;
begin
  SetLength(LSource, 200);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Repeat128(LSource, 0, 0);
    end, EImagingException, 'dovrebbe rifiutare l''altezza zero');
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Repeat128(LSource, 0, 129);
    end, EImagingException, 'dovrebbe rifiutare un''altezza oltre 128');
end;

procedure TTestImagingFixedColumn.TestRepeat128PastTheEndOfTheBytesRaises;
var
  LSource: TBytes;
begin
  SetLength(LSource, 10);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Repeat128(LSource, 4, 8);
    end, EImagingException, 'dovrebbe rifiutare pixel oltre i byte');
end;

procedure TTestImagingFixedColumn.TestFromPostsLeavesZeroWhereThereIsNoPost;
var
  LResult: TBytes;
begin
  LResult := FBuilder.FromPosts(TImagingSamples.Column([Post(3, 2, 1)]), 0, 8);
  Assert.AreEqual<Integer>(8, Length(LResult), 'dovrebbe dare l''altezza chiesta');
  Assert.AreEqual(Integer(0), Integer(LResult[0]), 'dovrebbe dare zero sopra il post');
  Assert.AreNotEqual(Integer(0), Integer(LResult[3]), 'dovrebbe avere il pixel del post');
  Assert.AreEqual(Integer(0), Integer(LResult[7]), 'dovrebbe dare zero sotto il post');
end;

procedure TTestImagingFixedColumn.TestFromPostsOfAColumnWithoutEndRaises;
var
  LColumn: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 2, 1)]);
  SetLength(LColumn, Length(LColumn) - 1);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.FromPosts(LColumn, 0, 8);
    end, EImagingException, 'dovrebbe rifiutare una colonna che non finisce');
end;

procedure TTestImagingFixedColumn.TestFromPostsOfATruncatedPostRaises;
var
  LColumn: TBytes;
begin
  LColumn := TImagingSamples.Column([Post(0, 6, 1)]);
  SetLength(LColumn, 6);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.FromPosts(LColumn, 0, 8);
    end, EImagingException, 'dovrebbe rifiutare un post che esce dai byte');
end;

procedure TTestImagingFixedColumn.TestFromPostsWithNegativeHeightRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.FromPosts(TImagingSamples.Column([]), 0, -1);
    end, EImagingException, 'dovrebbe rifiutare un''altezza negativa');
end;

end.
