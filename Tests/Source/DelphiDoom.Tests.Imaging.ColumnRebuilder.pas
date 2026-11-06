{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingColumnRebuilder                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ColumnRebuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf, DelphiDoom.Imaging.ColumnRebuilder,
  DelphiDoom.Tests.Imaging.Samples, DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingColumnRebuilder = class(TObject)
  private
    FRebuilder: IImagingColumnRebuilder;
    function Marks(AHeight: Integer; const ARuns: array of Integer): TBytes;
    function Block(AHeight: Integer; ASize: Integer): TBytes;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestRebuildMatchesOldCodeInEveryCase;
    [Test]
    procedure TestRebuildOfAnEmptyColumnWritesOnlyTheEnd;
    [Test]
    procedure TestRebuildWritesOnePostForEachRun;
    [Test]
    procedure TestRebuildKeepsThePixelsOfTheRuns;
    [Test]
    procedure TestRebuildWorksFromAnOffset;
    [Test]
    procedure TestRebuildSplitsALongRunInTallColumns;
    [Test]
    procedure TestRebuildOfARunPastTheLimitFarFromThePreviousOneRaises;
    [Test]
    procedure TestRebuildWithZeroHeightRaises;
    [Test]
    procedure TestRebuildInASmallBlockRaises;
    [Test]
    procedure TestRebuildWithSmallMarksRaises;
  end;

implementation

function TTestImagingColumnRebuilder.Marks(AHeight: Integer; const ARuns: array of Integer): TBytes;
var
  LRun, LRow: Integer;
begin
  Result := TImagingSamples.ZeroBytes(AHeight);
  LRun := 0;
  while LRun < Length(ARuns) do
  begin
    for LRow := ARuns[LRun] to ARuns[LRun] + ARuns[LRun + 1] - 1 do
      Result[LRow] := $FF;
    Inc(LRun, 2);
  end;
end;

function TTestImagingColumnRebuilder.Block(AHeight, ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  Result := TImagingSamples.ZeroBytes(ASize);
  for LIndex := 0 to AHeight - 1 do
    Result[3 + LIndex] := Byte(LIndex or 1);
end;

procedure TTestImagingColumnRebuilder.Setup;
begin
  FRebuilder := TImagingColumnRebuilder.Create;
end;

procedure TTestImagingColumnRebuilder.TestRebuildMatchesOldCodeInEveryCase;
var
  LCases: TArray<TSampleRebuildCase>;
  LCase: TSampleRebuildCase;
  LBlock: TBytes;
begin
  LCases := TImagingSamples.RebuildCases;
  for LCase in LCases do
  begin
    SetLength(LBlock, LCase.BlockSize);
    FillChar(LBlock[0], Length(LBlock), 0);
    Move(LCase.Pixels[0], LBlock[3], LCase.Height);
    FRebuilder.Rebuild(LBlock, 0, LCase.Marks, 0, LCase.Height);
    TImagingGolden.Check('rebuild.golden.txt', LCase.Name, TImagingSamples.DumpPosts(LBlock, 0));
  end;
end;

procedure TTestImagingColumnRebuilder.TestRebuildOfAnEmptyColumnWritesOnlyTheEnd;
var
  LBlock: TBytes;
begin
  LBlock := Block(8, 64);
  LBlock[0] := 7;
  FRebuilder.Rebuild(LBlock, 0, Marks(8, []), 0, 8);
  Assert.AreEqual(Integer($FF), Integer(LBlock[0]), 'dovrebbe scrivere la fine della colonna');
end;

procedure TTestImagingColumnRebuilder.TestRebuildWritesOnePostForEachRun;
var
  LBlock: TBytes;
begin
  LBlock := Block(16, 128);
  FRebuilder.Rebuild(LBlock, 0, Marks(16, [2, 3, 8, 2]), 0, 16);
  Assert.AreEqual(2, Integer(LBlock[0]), 'dovrebbe cominciare il primo post alla riga 2');
  Assert.AreEqual(3, Integer(LBlock[1]), 'dovrebbe dare al primo post 3 righe');
  Assert.AreEqual(8, Integer(LBlock[3 + 3 + 1]), 'dovrebbe cominciare il secondo post alla riga 8');
  Assert.AreEqual(2, Integer(LBlock[3 + 3 + 2]), 'dovrebbe dare al secondo post 2 righe');
  Assert.AreEqual(Integer($FF), Integer(LBlock[7 + 6]), 'dovrebbe chiudere con la fine della colonna');
end;

procedure TTestImagingColumnRebuilder.TestRebuildKeepsThePixelsOfTheRuns;
var
  LBlock: TBytes;
begin
  LBlock := Block(16, 128);
  FRebuilder.Rebuild(LBlock, 0, Marks(16, [4, 2]), 0, 16);
  // the pixels of the rows 4 and 5 were 5 and 5 (Block writes row or 1)
  Assert.AreEqual(Integer(4 or 1), Integer(LBlock[3]), 'dovrebbe copiare il pixel della riga 4');
  Assert.AreEqual(Integer(5 or 1), Integer(LBlock[4]), 'dovrebbe copiare il pixel della riga 5');
end;

procedure TTestImagingColumnRebuilder.TestRebuildWorksFromAnOffset;
var
  LBlock, LMarks: TBytes;
begin
  LBlock := Block(16, 128);
  LMarks := Marks(16, [1, 4]);
  // the same column, ten bytes further, with its marks in a longer array
  SetLength(LBlock, 138);
  Move(LBlock[0], LBlock[10], 128);
  FillChar(LBlock[0], 10, 0);
  SetLength(LMarks, 30);
  Move(LMarks[0], LMarks[9], 16);
  FillChar(LMarks[0], 9, 0);
  FRebuilder.Rebuild(LBlock, 10, LMarks, 9, 16);
  Assert.AreEqual(1, Integer(LBlock[10]), 'dovrebbe scrivere dallo scostamento della colonna');
  Assert.AreEqual(4, Integer(LBlock[11]), 'dovrebbe leggere i segni dal loro scostamento');
  Assert.AreEqual(Integer($FF), Integer(LBlock[10 + 4 + 4]), 'dovrebbe chiudere dopo il post');
end;

procedure TTestImagingColumnRebuilder.TestRebuildSplitsALongRunInTallColumns;
var
  LBlock: TBytes;
begin
  LBlock := Block(300, 3 + 5 * 300 + 16);
  FRebuilder.Rebuild(LBlock, 0, Marks(300, [0, 300]), 0, 300);
  Assert.AreEqual(254, Integer(LBlock[1]), 'dovrebbe tagliare il primo post a 254 pixel');
  Assert.AreEqual(46, Integer(LBlock[254 + 4 + 1]), 'dovrebbe dare al secondo post il resto');
end;

procedure TTestImagingColumnRebuilder.TestRebuildOfARunPastTheLimitFarFromThePreviousOneRaises;
var
  LBlock, LMarks: TBytes;
begin
  // il vecchio codice qui girava all'infinito scrivendo post vuoti
  LBlock := Block(400, 3 + 5 * 400 + 16);
  LMarks := Marks(400, [300, 10]);
  Assert.WillRaise(
    procedure
    begin
      FRebuilder.Rebuild(LBlock, 0, LMarks, 0, 400);
    end, EImagingException, 'dovrebbe segnalare che gli scostamenti non convergono');
end;

procedure TTestImagingColumnRebuilder.TestRebuildWithZeroHeightRaises;
var
  LBlock: TBytes;
begin
  SetLength(LBlock, 16);
  Assert.WillRaise(
    procedure
    begin
      FRebuilder.Rebuild(LBlock, 0, nil, 0, 0);
    end, EImagingException, 'dovrebbe rifiutare l''altezza zero');
end;

procedure TTestImagingColumnRebuilder.TestRebuildInASmallBlockRaises;
var
  LBlock: TBytes;
begin
  SetLength(LBlock, 10);
  Assert.WillRaise(
    procedure
    begin
      FRebuilder.Rebuild(LBlock, 0, Marks(16, [0, 16]), 0, 16);
    end, EImagingException, 'dovrebbe rifiutare un blocco piu'' piccolo della colonna');
end;

procedure TTestImagingColumnRebuilder.TestRebuildWithSmallMarksRaises;
var
  LBlock: TBytes;
begin
  LBlock := Block(16, 128);
  Assert.WillRaise(
    procedure
    begin
      FRebuilder.Rebuild(LBlock, 0, Marks(8, [0, 8]), 0, 16);
    end, EImagingException, 'dovrebbe rifiutare segni piu'' piccoli dell''altezza');
end;

end.
