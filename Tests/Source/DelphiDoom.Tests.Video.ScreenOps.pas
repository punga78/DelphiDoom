{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the loops over a screen             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.ScreenOps;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.ScreenOps;

type
  [TestFixture]
  [Category('video')]
  TTestVideoScreenOps = class(TObject)
  public
    [Test]
    procedure DovrebbeCopiareSoloIPixelNonTrasparenti;
    [Test]
    procedure DovrebbeCopiareComeIlModelloPerOgniLunghezza;
    [Test]
    procedure DovrebbeCopiareAttraversoLaPaletteA32Bit;
    [Test]
    procedure DovrebbeDimezzareOgniByteInOgniLunghezza;
    [Test]
    procedure DovrebbeMappareConLaColormap;
    [Test]
    procedure DovrebbeDimezzareITreCanaliEImpostareLAlfa;
    [Test]
    procedure DovrebbeSostituireLIndiceZero;
    [Test]
    procedure DovrebbeNonScrivereOltreIlConteggio;
  end;

implementation

type
  TBytes8 = array of Byte;

function Pattern(const ACount: Integer; const ASeed: Integer): TBytes8;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    if ((LIndex + ASeed) mod 7) < 3 then
      Result[LIndex] := 0
    else
      Result[LIndex] := Byte((LIndex * 29 + ASeed) and $FF);
end;

procedure TTestVideoScreenOps.DovrebbeCopiareSoloIPixelNonTrasparenti;
var
  LSource, LDest: TBytes8;
begin
  LSource := Pattern(16, 0);
  LSource[2] := 0;
  LSource[3] := 77;
  SetLength(LDest, 16);
  FillChar(LDest[0], 16, 9);
  TVideoScreenOps.CopyTransparent8(@LSource[0], @LDest[0], 16);
  Assert.AreEqual<Integer>(77, LDest[3]);
  Assert.IsTrue((LSource[0] <> 0) or (LDest[0] = 9));
end;

procedure TTestVideoScreenOps.DovrebbeCopiareComeIlModelloPerOgniLunghezza;
var
  LCount, LIndex: Integer;
  LSource, LDest, LExpected: TBytes8;
begin
  for LCount := 0 to 40 do
  begin
    LSource := Pattern(LCount + 8, LCount);
    // runs of four zeroes exercise the 4 bytes at a time skip
    if LCount > 12 then
      FillChar(LSource[4], 8, 0);
    SetLength(LDest, LCount + 8);
    SetLength(LExpected, LCount + 8);
    for LIndex := 0 to LCount + 7 do
    begin
      LDest[LIndex] := Byte(200 + LIndex);
      LExpected[LIndex] := LDest[LIndex];
    end;
    for LIndex := 0 to LCount - 1 do
      if LSource[LIndex] <> 0 then
        LExpected[LIndex] := LSource[LIndex];
    TVideoScreenOps.CopyTransparent8(@LSource[0], @LDest[0], LCount);
    Assert.IsTrue(CompareMem(@LExpected[0], @LDest[0], LCount + 8), 'count ' + IntToStr(LCount));
  end;
end;

procedure TTestVideoScreenOps.DovrebbeCopiareAttraversoLaPaletteA32Bit;
var
  LSource: TBytes8;
  LPalette: array[0..255] of LongWord;
  LDest: array of LongWord;
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    LPalette[LIndex] := $FF000000 or LongWord(LIndex * 65793);
  LSource := Pattern(50, 3);
  SetLength(LDest, 52);
  for LIndex := 0 to 51 do
    LDest[LIndex] := $11223344;
  TVideoScreenOps.CopyTransparent32(@LSource[0], @LDest[0], @LPalette[0], 50);
  for LIndex := 0 to 49 do
    if LSource[LIndex] = 0 then
      Assert.AreEqual<LongWord>($11223344, LDest[LIndex])
    else
      Assert.AreEqual<LongWord>(LPalette[LSource[LIndex]], LDest[LIndex]);
  Assert.AreEqual<LongWord>($11223344, LDest[50]);
end;

procedure TTestVideoScreenOps.DovrebbeDimezzareOgniByteInOgniLunghezza;
var
  LCount, LIndex: Integer;
  LData, LExpected: TBytes8;
begin
  for LCount := 0 to 70 do
  begin
    LData := Pattern(LCount + 4, 5);
    SetLength(LExpected, LCount + 4);
    for LIndex := 0 to LCount + 3 do
      if LIndex < LCount then
        LExpected[LIndex] := LData[LIndex] shr 1
      else
        LExpected[LIndex] := LData[LIndex];
    TVideoScreenOps.Shade32(@LData[0], LCount);
    Assert.IsTrue(CompareMem(@LExpected[0], @LData[0], LCount + 4), 'count ' + IntToStr(LCount));
  end;
end;

procedure TTestVideoScreenOps.DovrebbeMappareConLaColormap;
var
  LMap: array[0..255] of Byte;
  LData: TBytes8;
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    LMap[LIndex] := Byte(255 - LIndex);
  LData := Pattern(33, 1);
  TVideoScreenOps.ShadeIndexed(@LData[0], @LMap[0], 30);
  for LIndex := 0 to 29 do
    Assert.AreEqual<Integer>(255 - Pattern(33, 1)[LIndex], LData[LIndex]);
  for LIndex := 30 to 32 do
    Assert.AreEqual<Integer>(Pattern(33, 1)[LIndex], LData[LIndex]);
end;

procedure TTestVideoScreenOps.DovrebbeDimezzareITreCanaliEImpostareLAlfa;
var
  LData: TBytes8;
  LIndex: Integer;
begin
  LData := Pattern(40, 2);
  TVideoScreenOps.ShadeOpaque32(@LData[0], 8);
  for LIndex := 0 to 31 do
    if LIndex mod 4 = 3 then
      Assert.AreEqual<Integer>(Pattern(40, 2)[LIndex] or $80, LData[LIndex])
    else
      Assert.AreEqual<Integer>(Pattern(40, 2)[LIndex] shr 1, LData[LIndex]);
  for LIndex := 32 to 39 do
    Assert.AreEqual<Integer>(Pattern(40, 2)[LIndex], LData[LIndex]);
end;

procedure TTestVideoScreenOps.DovrebbeSostituireLIndiceZero;
var
  LData: TBytes8;
  LIndex: Integer;
begin
  LData := Pattern(20, 4);
  TVideoScreenOps.RemoveTransparency(@LData[0], 99, 20);
  for LIndex := 0 to 19 do
    if Pattern(20, 4)[LIndex] = 0 then
      Assert.AreEqual<Integer>(99, LData[LIndex])
    else
      Assert.AreEqual<Integer>(Pattern(20, 4)[LIndex], LData[LIndex]);
end;

procedure TTestVideoScreenOps.DovrebbeNonScrivereOltreIlConteggio;
var
  LData: TBytes8;
begin
  SetLength(LData, 8);
  FillChar(LData[0], 8, 0);
  TVideoScreenOps.RemoveTransparency(@LData[0], 5, 3);
  Assert.AreEqual<Integer>(5, LData[2]);
  Assert.AreEqual<Integer>(0, LData[3]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoScreenOps);

end.
