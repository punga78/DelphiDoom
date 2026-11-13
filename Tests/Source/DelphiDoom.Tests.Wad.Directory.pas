{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TWadDirectory                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Directory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  [TestFixture]
  [Category('wad')]
  TTestWadDirectory = class(TObject)
  private
    FDirectory: IWadDirectory;
    FFinder: IWadFinder;
    FReader: ILumpReader;
    procedure AddWad(const ANames: array of string; const AData: array of string);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestLumpsOfSeveralSourcesFollowEachOther;
    [Test]
    procedure TestLastLumpWithAnEqualNameWins;
    [Test]
    procedure TestFirstLumpWithAnEqualName;
    [Test]
    procedure TestSearchIsCaseInsensitive;
    [Test]
    procedure TestMissingNameGivesMinusOne;
    [Test]
    procedure TestGetNumForNameRaises;
    [Test]
    procedure TestRangeSearch;
    [Test]
    procedure TestRangeSearchWhereTheLastIsOutside;
    [Test]
    procedure TestMarkersSetTheFlags;
    [Test]
    procedure TestFlagsLimitTheSearch;
    [Test]
    procedure TestNestedPairsOfDifferentKinds;
    [Test]
    procedure TestTruncateForgetsTheLastSources;
    [Test]
    procedure TestTruncateWithTooManySources;
    [Test]
    procedure TestReadLumpAndText;
    [Test]
    procedure TestReadLumpInto;
    [Test]
    procedure TestLumpIndexOutOfRange;
    [Test]
    procedure TestLumpKnowsItsSource;
    [Test]
    procedure TestAddNilSource;
    [Test]
    procedure TestReplaceSourceKeepsTheLumpNumbers;
    [Test]
    procedure TestReplaceSourceWithAnotherLumpCount;
    [Test]
    procedure TestLumpOffset;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Tests.Wad.Helpers;

type
  H = TWadTestHelpers;

{ TTestWadDirectory }

procedure TTestWadDirectory.Setup;
begin
  FDirectory := TWadFactory.CreateDirectory;
  FFinder := TWadFactory.CreateFinder(FDirectory);
  FReader := TWadFactory.CreateReader(FDirectory);
end;

procedure TTestWadDirectory.AddWad(const ANames: array of string; const AData: array of string);
var
  LData: array of TBytes;
  LIndex: Integer;
begin
  SetLength(LData, Length(AData));
  for LIndex := 0 to High(AData) do
    LData[LIndex] := H.Bytes(AData[LIndex]);
  FDirectory.AddSource(TWadFactory.OpenBytes('w' + IntToStr(FDirectory.SourceCount),
    H.MakeWad(ANames, LData)));
end;

procedure TTestWadDirectory.TestLumpsOfSeveralSourcesFollowEachOther;
begin
  AddWad(['A', 'B'], ['a', 'b']);
  AddWad(['C'], ['c']);
  Assert.AreEqual(3, FDirectory.Count);
  Assert.AreEqual(2, FDirectory.SourceCount);
  Assert.AreEqual('A', FDirectory.LumpName(0));
  Assert.AreEqual('C', FDirectory.LumpName(2));
  Assert.AreEqual(1, FDirectory.LumpSize(2));
end;

procedure TTestWadDirectory.TestLastLumpWithAnEqualNameWins;
begin
  AddWad(['PLAYPAL', 'X'], ['old', 'x']);
  AddWad(['PLAYPAL'], ['patch']);
  Assert.AreEqual(2, FFinder.CheckNumForName('PLAYPAL'));
  Assert.AreEqual('patch', FReader.TextLump(FFinder.GetNumForName('PLAYPAL')));
end;

procedure TTestWadDirectory.TestFirstLumpWithAnEqualName;
begin
  AddWad(['PLAYPAL', 'X'], ['old', 'x']);
  AddWad(['PLAYPAL'], ['patch']);
  Assert.AreEqual(0, FFinder.CheckFirstNumForName('PLAYPAL'));
  Assert.AreEqual(0, FFinder.GetFirstNumForName('playpal'));
end;

procedure TTestWadDirectory.TestSearchIsCaseInsensitive;
begin
  AddWad(['SKY1'], ['s']);
  Assert.AreEqual(0, FFinder.CheckNumForName('sky1'));
  Assert.AreEqual(0, FFinder.CheckNumForName('Sky1'));
end;

procedure TTestWadDirectory.TestMissingNameGivesMinusOne;
begin
  AddWad(['A'], ['a']);
  Assert.AreEqual(-1, FFinder.CheckNumForName('B'));
  Assert.AreEqual(-1, FFinder.CheckFirstNumForName('B'));
  Assert.AreEqual(-1, FFinder.CheckNumForNameInRange('B', 0, 0));
  Assert.AreEqual(-1, FFinder.CheckNumForName('A_NAME_TOO_LONG'));
end;

procedure TTestWadDirectory.TestGetNumForNameRaises;
begin
  AddWad(['A'], ['a']);
  Assert.WillRaise(procedure begin FFinder.GetNumForName('NOPE'); end, EWadException);
  Assert.WillRaise(procedure begin FFinder.GetFirstNumForName('NOPE'); end, EWadException);
end;

procedure TTestWadDirectory.TestRangeSearch;
begin
  // a level: every map has its own THINGS
  AddWad(['MAP01', 'THINGS', 'MAP02', 'THINGS', 'MAP03', 'THINGS'], ['', '1', '', '2', '', '3']);
  Assert.AreEqual(1, FFinder.CheckNumForNameInRange('THINGS', 0, 2));
  Assert.AreEqual(3, FFinder.CheckNumForNameInRange('THINGS', 2, 4));
  Assert.AreEqual(5, FFinder.CheckNumForNameInRange('THINGS', 4, 5));
  Assert.AreEqual(3, FFinder.CheckNumForNameInRange('THINGS', 3, 3));
end;

procedure TTestWadDirectory.TestRangeSearchWhereTheLastIsOutside;
begin
  AddWad(['A', 'B', 'A'], ['0', '1', '2']);
  // the last A is at 2, out of the range 0..1: the one at 0 is taken
  Assert.AreEqual(0, FFinder.CheckNumForNameInRange('A', 0, 1));
  // and none in 1..1
  Assert.AreEqual(-1, FFinder.CheckNumForNameInRange('A', 1, 1));
end;

procedure TTestWadDirectory.TestMarkersSetTheFlags;
begin
  AddWad(['S_START', 'TROOA1', 'S_END', 'OTHER', 'F_START', 'FLOOR0', 'F_END'],
    ['', 'a', '', 'o', '', 'f', '']);
  Assert.AreEqual(Cardinal(0), FDirectory.LumpFlags(0), 'S_START is not inside');
  Assert.AreEqual(Cardinal(TYPE_SPRITE), FDirectory.LumpFlags(1));
  Assert.AreEqual(Cardinal(TYPE_SPRITE), FDirectory.LumpFlags(2), 'S_END is inside');
  Assert.AreEqual(Cardinal(0), FDirectory.LumpFlags(3));
  Assert.AreEqual(Cardinal(TYPE_FLOOR), FDirectory.LumpFlags(5));
end;

procedure TTestWadDirectory.TestFlagsLimitTheSearch;
begin
  // the same name as a flat and as a patch
  AddWad(['P_START', 'WALL', 'P_END', 'F_START', 'WALL', 'F_END'], ['', 'p', '', '', 'f', '']);
  Assert.AreEqual(4, FFinder.CheckNumForName('WALL'));
  Assert.AreEqual(4, FFinder.CheckNumForName('WALL', TYPE_FLOOR));
  Assert.AreEqual(1, FFinder.CheckNumForName('WALL', TYPE_PATCH));
  Assert.AreEqual(1, FFinder.CheckNumForName('WALL', TYPE_PATCH or TYPE_SPRITE));
  Assert.AreEqual(-1, FFinder.CheckNumForName('WALL', TYPE_VOXEL));
end;

procedure TTestWadDirectory.TestNestedPairsOfDifferentKinds;
begin
  AddWad(['F_START', 'S_START', 'X', 'S_END', 'Y', 'F_END', 'Z'], ['', '', 'x', '', 'y', '', 'z']);
  Assert.AreEqual(Cardinal(TYPE_FLOOR or TYPE_SPRITE), FDirectory.LumpFlags(2));
  Assert.AreEqual(Cardinal(TYPE_FLOOR), FDirectory.LumpFlags(4));
  Assert.AreEqual(Cardinal(0), FDirectory.LumpFlags(6));
end;

procedure TTestWadDirectory.TestTruncateForgetsTheLastSources;
begin
  AddWad(['A'], ['a']);
  AddWad(['B'], ['b']);
  AddWad(['A', 'C'], ['a2', 'c']);
  Assert.AreEqual(2, FFinder.CheckNumForName('A'));
  FDirectory.Truncate(2);
  Assert.AreEqual(2, FDirectory.Count);
  Assert.AreEqual(0, FFinder.CheckNumForName('A'));
  Assert.AreEqual(-1, FFinder.CheckNumForName('C'));
  FDirectory.Truncate(0);
  Assert.AreEqual(0, FDirectory.Count);
end;

procedure TTestWadDirectory.TestTruncateWithTooManySources;
begin
  AddWad(['A'], ['a']);
  Assert.WillRaise(procedure begin FDirectory.Truncate(2); end, EWadException);
  Assert.WillRaise(procedure begin FDirectory.Truncate(-1); end, EWadException);
end;

procedure TTestWadDirectory.TestReadLumpAndText;
begin
  AddWad(['TEXT', 'EMPTY'], ['hello'#13#10'world', '']);
  Assert.AreEqual('hello'#13#10'world', FReader.TextLump(0));
  Assert.AreEqual('', FReader.TextLump(1));
  Assert.AreEqual<Integer>(12, Length(FReader.ReadLump(0)));
end;

procedure TTestWadDirectory.TestReadLumpInto;
var
  LBuffer: array[0..8] of AnsiChar;
begin
  AddWad(['A'], ['abcd']);
  FillChar(LBuffer, SizeOf(LBuffer), 46);
  LBuffer[8] := #0;
  FReader.ReadLumpInto(0, @LBuffer);
  Assert.AreEqual('abcd....', string(AnsiString(PAnsiChar(@LBuffer))));
end;

procedure TTestWadDirectory.TestLumpIndexOutOfRange;
begin
  AddWad(['A'], ['a']);
  Assert.WillRaise(procedure begin FDirectory.LumpName(1); end, EWadException);
  Assert.WillRaise(procedure begin FDirectory.LumpSize(-1); end, EWadException);
  Assert.WillRaise(procedure begin FReader.ReadLump(5); end, EWadException);
end;

procedure TTestWadDirectory.TestLumpKnowsItsSource;
begin
  AddWad(['A'], ['a']);
  AddWad(['B', 'C'], ['b', 'c']);
  Assert.AreEqual(0, FDirectory.LumpSourceIndex(0));
  Assert.AreEqual(1, FDirectory.LumpSourceIndex(2));
  Assert.AreEqual('w1', FDirectory.Sources[FDirectory.LumpSourceIndex(2)].Name);
end;

procedure TTestWadDirectory.TestAddNilSource;
begin
  Assert.WillRaise(procedure begin FDirectory.AddSource(nil); end, EWadException);
end;

procedure TTestWadDirectory.TestReplaceSourceKeepsTheLumpNumbers;
begin
  AddWad(['A', 'B'], ['a1', 'b1']);
  AddWad(['C'], ['c1']);
  FDirectory.ReplaceSource(0, TWadFactory.OpenBytes('again',
    H.MakeWad(['A', 'B'], [H.Bytes('a2'), H.Bytes('bbbb')])));
  Assert.AreEqual(3, FDirectory.Count);
  Assert.AreEqual(4, FDirectory.LumpSize(1));
  Assert.AreEqual('bbbb', FReader.TextLump(1));
  Assert.AreEqual('c1', FReader.TextLump(2));
  Assert.AreEqual('again', FDirectory.Sources[0].Name);
end;

procedure TTestWadDirectory.TestReplaceSourceWithAnotherLumpCount;
begin
  AddWad(['A', 'B'], ['a1', 'b1']);
  Assert.WillRaise(procedure begin FDirectory.ReplaceSource(0,
    TWadFactory.OpenBytes('x', H.MakeWad(['A'], [H.Bytes('a')]))); end, EWadException);
  Assert.WillRaise(procedure begin FDirectory.ReplaceSource(1,
    TWadFactory.OpenBytes('x', H.MakeWad(['A', 'B'], [H.Bytes('a'), H.Bytes('b')]))); end, EWadException);
  Assert.WillRaise(procedure begin FDirectory.ReplaceSource(0, nil); end, EWadException);
  Assert.AreEqual(2, FDirectory.Count);
end;

procedure TTestWadDirectory.TestLumpOffset;
begin
  AddWad(['A', 'B'], ['abc', 'de']);
  Assert.AreEqual(12, FDirectory.LumpOffset(0));
  Assert.AreEqual(15, FDirectory.LumpOffset(1));
  Assert.WillRaise(procedure begin FDirectory.LumpOffset(2); end, EWadException);
end;

end.