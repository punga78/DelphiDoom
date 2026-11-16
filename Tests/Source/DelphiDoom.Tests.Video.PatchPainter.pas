{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the columns of a patch              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.PatchPainter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.Stretch,
  DelphiDoom.Video.PatchPainter;

type
  [TestFixture]
  [Category('video')]
  TTestVideoPatchPainter = class(TObject)
  public
    [Test]
    procedure DovrebbeDisegnareUnaPatchSempliceComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDisegnareUnaPatchAltaComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDisegnareLaPatchRovesciataComeIlVecchioCodice;
    [Test]
    procedure DovrebbeTradurreIColori;
  end;

implementation

type
  TPatchData = record
    Bytes: TBytes;
    Width: Integer;
    Offsets: array of Integer;
  end;

  TOldPost = packed record
    topdelta: Byte;
    length: Byte;
  end;
  POldPost = ^TOldPost;

const
  SCREEN_WIDTH = 32;
  SCREEN_HEIGHT = 40;

// A patch of AWidth columns; each column has the posts given by (top, length) pairs. The pixel
// values depend on the column and on the row, so that a wrong column shows up
function BuildPatch(const AWidth: Integer; const APosts: array of Integer): TPatchData;
var
  LColumn, LPost, LRow: Integer;
  LLength: Integer;

  procedure AddByte(const AValue: Byte);
  begin
    SetLength(Result.Bytes, Length(Result.Bytes) + 1);
    Result.Bytes[High(Result.Bytes)] := AValue;
  end;

begin
  Result.Width := AWidth;
  SetLength(Result.Offsets, AWidth);
  // 8 bytes of header (width, height, leftoffset, topoffset) and the offsets of the columns
  SetLength(Result.Bytes, 8 + AWidth * 4);
  for LColumn := 0 to AWidth - 1 do
  begin
    Result.Offsets[LColumn] := Length(Result.Bytes);
    PInteger(@Result.Bytes[8 + LColumn * 4])^ := Length(Result.Bytes);
    for LPost := 0 to (Length(APosts) div 2) - 1 do
    begin
      LLength := APosts[LPost * 2 + 1];
      AddByte(APosts[LPost * 2]);
      AddByte(LLength);
      AddByte(0);
      for LRow := 0 to LLength - 1 do
        AddByte(Byte(1 + LColumn * 16 + LPost * 4 + LRow));
      AddByte(0);
    end;
    AddByte($FF);
  end;
end;
// The old text of V_DrawPatch8 (plain branch, flipped = False) and of V_DrawPatchFlipped
procedure OldDraw(const APatch: PByte; const AOffsets: PVideoIntegerRow; const AWidth: Integer;
  const ADestTop: PByte; const AStride: Integer; const ATranslation: PVideoByteRow; const AFlipped: Boolean);
var
  count: Integer;
  col: Integer;
  column: POldPost;
  desttop: PByte;
  dest: PByte;
  source: PByte;
  delta, prevdelta: Integer;
  tallpatch: Boolean;
  ofs: Integer;
begin
  col := 0;
  desttop := ADestTop;
  while col < AWidth do
  begin
    if AFlipped then
      ofs := AOffsets[AWidth - 1 - col]
    else
      ofs := AOffsets[col];
    column := POldPost(NativeInt(APatch) + ofs);
    delta := 0;
    tallpatch := False;
    while column.topdelta <> $FF do
    begin
      source := PByte(NativeInt(column) + 3);
      delta := delta + column.topdelta;
      dest := PByte(NativeInt(desttop) + delta * AStride);
      count := column.length;

      while count > 0 do
      begin
        dest^ := ATranslation[source^];
        Inc(source);
        Inc(dest, AStride);
        Dec(count);
      end;
      if not tallpatch then
      begin
        prevdelta := column.topdelta;
        column := POldPost(NativeInt(column) + column.length + 4);
        if column.topdelta > prevdelta then
          delta := 0
        else
          tallpatch := True;
      end
      else
        column := POldPost(NativeInt(column) + column.length + 4);
    end;
    Inc(col);
    Inc(desttop);
  end;
end;

procedure Compare(const APosts: array of Integer; const AFlipped: Boolean; const ATranslate: Boolean);
var
  LPatch: TPatchData;
  LTranslation: array[0..255] of Byte;
  LExpected, LActual: TBytes;
  LIndex: Integer;
begin
  LPatch := BuildPatch(5, APosts);
  for LIndex := 0 to 255 do
    if ATranslate then
      LTranslation[LIndex] := Byte(255 - LIndex)
    else
      LTranslation[LIndex] := Byte(LIndex);
  SetLength(LExpected, SCREEN_WIDTH * SCREEN_HEIGHT);
  SetLength(LActual, SCREEN_WIDTH * SCREEN_HEIGHT);
  FillChar(LExpected[0], Length(LExpected), $EE);
  FillChar(LActual[0], Length(LActual), $EE);
  OldDraw(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), 5, @LExpected[2 * SCREEN_WIDTH + 3],
    SCREEN_WIDTH, PVideoByteRow(@LTranslation[0]), AFlipped);
  TVideoPatchPainter.DrawColumns8(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), 5,
    @LActual[2 * SCREEN_WIDTH + 3], SCREEN_WIDTH, PVideoByteRow(@LTranslation[0]), AFlipped);
  Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected)));
  // something was drawn
  Assert.AreNotEqual<Integer>($EE, LActual[2 * SCREEN_WIDTH + 3 + 3 * SCREEN_WIDTH]);
end;

{ TTestVideoPatchPainter }

procedure TTestVideoPatchPainter.DovrebbeDisegnareUnaPatchSempliceComeIlVecchioCodice;
begin
  Compare([0, 6, 8, 4], False, False);
end;

procedure TTestVideoPatchPainter.DovrebbeDisegnareUnaPatchAltaComeIlVecchioCodice;
begin
  // the second post has a top delta below the first: a tall patch (offsets from the previous post)
  Compare([3, 5, 2, 4, 1, 3], False, False);
end;

procedure TTestVideoPatchPainter.DovrebbeDisegnareLaPatchRovesciataComeIlVecchioCodice;
begin
  Compare([0, 6, 8, 4], True, False);
  Compare([3, 5, 2, 4, 1, 3], True, False);
end;

procedure TTestVideoPatchPainter.DovrebbeTradurreIColori;
begin
  Compare([0, 6, 8, 4], False, True);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoPatchPainter);

end.
