{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedMonsterPictureFix                                 }
{                                                                              }
{  The oracle is the loop of DemandLoadMonster of spawn.pas of xGreed, copied   }
{  here as it was (on one lump in memory)                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.MonsterPictureFix;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.MonsterPictureFix;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMonsterPictureFix = class(TObject)
  public
    [Test]
    procedure DovrebbeAzzerareIlColore255DiUnaColonna;
    [Test]
    procedure DovrebbeLasciareUnLumpTroppoCorto;
    [Test]
    procedure DovrebbeNonUscireDalLump;
    [Test]
    procedure DovrebbeDareGliStessiByteDelCicloOriginale;
  end;

implementation

type
  // r_refdef.pas
  scalepic_t = packed record
    leftoffset: SmallInt;
    width: SmallInt;
    collumnofs: packed array[0..255] of SmallInt;
  end;
  Pscalepic_t = ^scalepic_t;

// the body of the loop "for l := 0 to num - 1" of DemandLoadMonster, on the lump that pic points to
procedure OriginalFix(pic: Pscalepic_t);
var
  i, j, count, top, bottom: Integer;
  collumn: PByteArray;
begin
  for i := 0 to pic.width - 1 do
    if pic.collumnofs[i] <> 0 then
    begin
      collumn := PByteArray(pic);
      collumn := @collumn[pic.collumnofs[i]];
      top := collumn[1];
      bottom := collumn[0];
      count := bottom - top + 1;
      collumn := @collumn[2];
      for j := 0 to count - 1 do
      begin
        if collumn[0] = 255 then
          collumn[0] := 0;
        collumn := @collumn[1];
      end;
    end;
end;

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8) and $FFFFFF;
end;

// A sprite of AWidth columns: some are empty, the others have a run of pixels where 255 is frequent
function MakeSprite(var ASeed: Cardinal; AWidth: Integer): TBytes;
var
  LColumn, LPosition, LTop, LBottom, LPixel: Integer;
begin
  // a new array of zeros: Result can still be the sprite of the call before
  Result := nil;
  SetLength(Result, 4 + AWidth * 2 + AWidth * 70);
  Result[2] := AWidth and $FF;
  Result[3] := AWidth shr 8;
  LPosition := 4 + AWidth * 2;
  for LColumn := 0 to AWidth - 1 do
  begin
    if NextRandom(ASeed) mod 5 = 0 then
      Continue;
    Result[4 + LColumn * 2] := LPosition and $FF;
    Result[5 + LColumn * 2] := LPosition shr 8;
    LTop := NextRandom(ASeed) mod 30;
    // sometimes the run is empty or upside down
    LBottom := LTop - 2 + NextRandom(ASeed) mod 40;
    if LBottom < 0 then
      LBottom := 0;
    Result[LPosition] := LBottom;
    Result[LPosition + 1] := LTop;
    Inc(LPosition, 2);
    for LPixel := 0 to LBottom - LTop do
    begin
      if NextRandom(ASeed) mod 3 = 0 then
        Result[LPosition] := 255
      else
        Result[LPosition] := NextRandom(ASeed) mod 256;
      Inc(LPosition);
    end;
    // what follows the run is not touched, even if it is 255
    Result[LPosition] := 255;
    Inc(LPosition);
  end;
  SetLength(Result, LPosition);
end;

{ TTestGreedMonsterPictureFix }

procedure TTestGreedMonsterPictureFix.DovrebbeAzzerareIlColore255DiUnaColonna;
var
  LLump: TBytes;
begin
  // one column at the offset 6: bottom 3, top 1, three pixels, and a byte that is not of the column
  LLump := TBytes.Create(0, 0, 1, 0, 6, 0, 3, 1, 255, 7, 255, 255);
  Assert.AreEqual(2, TGreedMonsterPictureFix.Apply(LLump));
  Assert.AreEqual<Byte>(0, LLump[8]);
  Assert.AreEqual<Byte>(7, LLump[9]);
  Assert.AreEqual<Byte>(0, LLump[10]);
  Assert.AreEqual<Byte>(255, LLump[11]);
  Assert.AreEqual(0, TGreedMonsterPictureFix.Apply(LLump));
end;

procedure TTestGreedMonsterPictureFix.DovrebbeLasciareUnLumpTroppoCorto;
var
  LLump: TBytes;
begin
  LLump := nil;
  Assert.AreEqual(0, TGreedMonsterPictureFix.Apply(LLump));
  LLump := TBytes.Create(0, 0, 1);
  Assert.AreEqual(0, TGreedMonsterPictureFix.Apply(LLump));
  Assert.AreEqual<Integer>(3, Length(LLump));
end;

procedure TTestGreedMonsterPictureFix.DovrebbeNonUscireDalLump;
var
  LLump: TBytes;
begin
  // three columns are declared: the first run is longer than the lump, the second starts after its end, the
  // third has no offset in the lump
  LLump := TBytes.Create(0, 0, 3, 0, 8, 0, 100, 0, 200, 0, 255, 255);
  Assert.AreEqual(2, TGreedMonsterPictureFix.Apply(LLump));
  Assert.AreEqual<Byte>(0, LLump[10]);
  Assert.AreEqual<Byte>(0, LLump[11]);
  // a negative offset
  LLump := TBytes.Create(0, 0, 1, 0, 255, 255, 255, 255);
  Assert.AreEqual(0, TGreedMonsterPictureFix.Apply(LLump));
end;

procedure TTestGreedMonsterPictureFix.DovrebbeDareGliStessiByteDelCicloOriginale;
var
  LSeed: Cardinal;
  LRound, LIndex, LDifferences: Integer;
  LNew, LOld: TBytes;
begin
  LSeed := 20261112;
  LDifferences := 0;
  for LRound := 1 to 500 do
  begin
    LNew := MakeSprite(LSeed, 1 + NextRandom(LSeed) mod 200);
    LOld := Copy(LNew);
    TGreedMonsterPictureFix.Apply(LNew);
    OriginalFix(Pscalepic_t(@LOld[0]));
    for LIndex := 0 to High(LNew) do
      if LNew[LIndex] <> LOld[LIndex] then
        Inc(LDifferences);
  end;
  Assert.AreEqual(0, LDifferences);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMonsterPictureFix);

end.
