{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the rows of a rectangle copy        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.RectCopy;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.RectCopy;

type
  [TestFixture]
  [Category('video')]
  TTestVideoRectCopy = class(TObject)
  strict private
    FSource: array[0..(8 * 6) - 1] of Byte;
    FToWord: array[0..255] of LongWord;
    FToLong: array[0..255] of LongWord;
    FPalette: array[0..255] of LongWord;
    function Params(const AFactor: Integer; const ADestination: Pointer; const APitch: Integer;
      const AIndex, ACount: Integer): TVideoRectCopyParams;
    function SourcePixel(const ARow, AColumn: Integer): Byte;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeEspandereGliOttoBitDeiFattoriGestiti;
    [Test]
    procedure DovrebbeEspandereITrentaduebitDeiFattoriGestiti;
    [Test]
    procedure DovrebbeRifiutareUnFattoreNonGestito;
    [Test]
    procedure DovrebbeDisegnareSoloLeRigheDelFiloNelleEspansioni;
    [Test]
    procedure DovrebbeStirareConIlPixelPiuVicinoA8Bit;
    [Test]
    procedure DovrebbeStirareConIlPixelPiuVicinoA32Bit;
    [Test]
    procedure DovrebbeDisegnareSoloLeRigheDelFiloNelloStiramento;
  end;

implementation

const
  SRC_WIDTH = 8;
  SRC_HEIGHT = 6;
  DEST_ROWS = 14;
  FRACUNIT = 65536;
  MARK8 = $EE;
  MARK32 = $11223344;

procedure TTestVideoRectCopy.Setup;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FSource) do
    FSource[LIndex] := Byte(LIndex * 13 + 5);
  for LIndex := 0 to 255 do
  begin
    // patterns of equal bytes: an expansion is the pixel repeated
    FToWord[LIndex] := LongWord(LIndex) * $0101;
    FToLong[LIndex] := LongWord(LIndex) * $01010101;
    FPalette[LIndex] := $FF000000 or (LongWord(LIndex) * $010203);
  end;
end;

function TTestVideoRectCopy.SourcePixel(const ARow, AColumn: Integer): Byte;
begin
  Result := FSource[ARow * SRC_WIDTH + AColumn];
end;

function TTestVideoRectCopy.Params(const AFactor: Integer; const ADestination: Pointer; const APitch: Integer;
  const AIndex, ACount: Integer): TVideoRectCopyParams;
begin
  Result.Source := @FSource[0];
  Result.Destination := ADestination;
  Result.SourcePitch := SRC_WIDTH;
  Result.DestinationPitch := APitch;
  Result.SourceX := 0;
  Result.DestinationX := 3;
  Result.DestinationY := 2;
  Result.DestinationWidth := SRC_WIDTH * AFactor;
  Result.DestinationHeight := DEST_ROWS;
  Result.FracY := 0;
  Result.FracYStep := FRACUNIT * SRC_HEIGHT div DEST_ROWS;
  Result.FracXStep := FRACUNIT * SRC_WIDTH div (SRC_WIDTH * AFactor);
  Result.Index := AIndex;
  Result.IndexCount := ACount;
end;

procedure TTestVideoRectCopy.DovrebbeEspandereGliOttoBitDeiFattoriGestiti;
var
  LFactor, LRow, LColumn, LPitch: Integer;
  LScreen: TBytes;
  LParams: TVideoRectCopyParams;
  LSourceRow: Integer;
begin
  for LFactor in [2, 4, 6, 8, 12] do
  begin
    LPitch := 3 + SRC_WIDTH * LFactor + 4;
    SetLength(LScreen, LPitch * (DEST_ROWS + 4));
    FillChar(LScreen[0], Length(LScreen), MARK8);
    LParams := Params(LFactor, @LScreen[0], LPitch, 0, 1);
    Assert.IsTrue(TVideoRectCopy.ExpandRows8(LFactor, LParams, @FToWord[0], @FToLong[0]), 'factor ' + IntToStr(LFactor));
    for LRow := 0 to DEST_ROWS - 1 do
    begin
      LSourceRow := (LRow * (FRACUNIT * SRC_HEIGHT div DEST_ROWS)) div FRACUNIT;
      for LColumn := 0 to SRC_WIDTH * LFactor - 1 do
        Assert.AreEqual<Integer>(SourcePixel(LSourceRow, LColumn div LFactor),
          LScreen[(2 + LRow) * LPitch + 3 + LColumn], Format('factor %d row %d col %d', [LFactor, LRow, LColumn]));
      // the border stays
      Assert.AreEqual<Integer>(MARK8, LScreen[(2 + LRow) * LPitch + 3 + SRC_WIDTH * LFactor]);
    end;
  end;
end;

procedure TTestVideoRectCopy.DovrebbeEspandereITrentaduebitDeiFattoriGestiti;
var
  LFactor, LRow, LColumn, LPitch: Integer;
  LScreen: array of LongWord;
  LParams: TVideoRectCopyParams;
  LSourceRow: Integer;
begin
  for LFactor in [2, 4, 5, 6, 8, 12] do
  begin
    LPitch := 3 + SRC_WIDTH * LFactor + 4;
    SetLength(LScreen, LPitch * (DEST_ROWS + 4));
    for LColumn := 0 to High(LScreen) do
      LScreen[LColumn] := MARK32;
    LParams := Params(LFactor, @LScreen[0], LPitch, 0, 1);
    Assert.IsTrue(TVideoRectCopy.ExpandRows32(LFactor, LParams, @FPalette[0]), 'factor ' + IntToStr(LFactor));
    for LRow := 0 to DEST_ROWS - 1 do
    begin
      LSourceRow := (LRow * (FRACUNIT * SRC_HEIGHT div DEST_ROWS)) div FRACUNIT;
      for LColumn := 0 to SRC_WIDTH * LFactor - 1 do
        Assert.AreEqual<LongWord>(FPalette[SourcePixel(LSourceRow, LColumn div LFactor)],
          LScreen[(2 + LRow) * LPitch + 3 + LColumn], Format('factor %d row %d col %d', [LFactor, LRow, LColumn]));
      Assert.AreEqual<LongWord>(MARK32, LScreen[(2 + LRow) * LPitch + 3 + SRC_WIDTH * LFactor]);
    end;
  end;
end;

procedure TTestVideoRectCopy.DovrebbeRifiutareUnFattoreNonGestito;
var
  LScreen: TBytes;
  LParams: TVideoRectCopyParams;
begin
  SetLength(LScreen, 400);
  FillChar(LScreen[0], 400, MARK8);
  LParams := Params(3, @LScreen[0], 40, 0, 1);
  Assert.IsFalse(TVideoRectCopy.ExpandRows8(3, LParams, @FToWord[0], @FToLong[0]));
  Assert.IsFalse(TVideoRectCopy.ExpandRows8(0, LParams, @FToWord[0], @FToLong[0]));
  Assert.AreEqual<Integer>(MARK8, LScreen[2 * 40 + 3]);
end;

procedure TTestVideoRectCopy.DovrebbeDisegnareSoloLeRigheDelFiloNelleEspansioni;
var
  LPitch, LRow, LIndex: Integer;
  LScreen: TBytes;
  LParams: TVideoRectCopyParams;
begin
  LPitch := 3 + SRC_WIDTH * 2 + 4;
  for LIndex := 0 to 2 do
  begin
    SetLength(LScreen, LPitch * (DEST_ROWS + 4));
    FillChar(LScreen[0], Length(LScreen), MARK8);
    LParams := Params(2, @LScreen[0], LPitch, LIndex, 3);
    TVideoRectCopy.ExpandRows8(2, LParams, @FToWord[0], @FToLong[0]);
    for LRow := 2 to 2 + DEST_ROWS - 1 do
      if LRow mod 3 = LIndex then
        Assert.AreNotEqual<Integer>(MARK8, LScreen[LRow * LPitch + 3], 'row ' + IntToStr(LRow))
      else
        Assert.AreEqual<Integer>(MARK8, LScreen[LRow * LPitch + 3], 'row ' + IntToStr(LRow));
  end;
end;

procedure TTestVideoRectCopy.DovrebbeStirareConIlPixelPiuVicinoA8Bit;
var
  LRow, LColumn, LPitch, LSourceRow, LDestWidth: Integer;
  LScreen: TBytes;
  LParams: TVideoRectCopyParams;
begin
  LDestWidth := 19;
  LPitch := 3 + LDestWidth + 4;
  SetLength(LScreen, LPitch * (DEST_ROWS + 4));
  FillChar(LScreen[0], Length(LScreen), MARK8);
  LParams := Params(1, @LScreen[0], LPitch, 0, 1);
  LParams.DestinationWidth := LDestWidth;
  LParams.FracXStep := FRACUNIT * SRC_WIDTH div LDestWidth;
  TVideoRectCopy.StretchRows8(LParams);
  for LRow := 0 to DEST_ROWS - 1 do
  begin
    LSourceRow := (LRow * LParams.FracYStep) div FRACUNIT;
    for LColumn := 0 to LDestWidth - 1 do
      Assert.AreEqual<Integer>(SourcePixel(LSourceRow, (LColumn * LParams.FracXStep) div FRACUNIT),
        LScreen[(2 + LRow) * LPitch + 3 + LColumn], Format('row %d col %d', [LRow, LColumn]));
  end;
end;

procedure TTestVideoRectCopy.DovrebbeStirareConIlPixelPiuVicinoA32Bit;
var
  LRow, LColumn, LPitch, LSourceRow, LDestWidth: Integer;
  LScreen: array of LongWord;
  LParams: TVideoRectCopyParams;
begin
  LDestWidth := 19;
  LPitch := 3 + LDestWidth + 4;
  SetLength(LScreen, LPitch * (DEST_ROWS + 4));
  for LColumn := 0 to High(LScreen) do
    LScreen[LColumn] := MARK32;
  LParams := Params(1, @LScreen[0], LPitch, 0, 1);
  LParams.DestinationWidth := LDestWidth;
  LParams.FracXStep := FRACUNIT * SRC_WIDTH div LDestWidth;
  TVideoRectCopy.StretchRows32(LParams, @FPalette[0]);
  for LRow := 0 to DEST_ROWS - 1 do
  begin
    LSourceRow := (LRow * LParams.FracYStep) div FRACUNIT;
    for LColumn := 0 to LDestWidth - 1 do
      Assert.AreEqual<LongWord>(FPalette[SourcePixel(LSourceRow, (LColumn * LParams.FracXStep) div FRACUNIT)],
        LScreen[(2 + LRow) * LPitch + 3 + LColumn], Format('row %d col %d', [LRow, LColumn]));
  end;
end;

procedure TTestVideoRectCopy.DovrebbeDisegnareSoloLeRigheDelFiloNelloStiramento;
var
  LRow, LPitch: Integer;
  LScreen: TBytes;
  LParams: TVideoRectCopyParams;
begin
  LPitch := 3 + 19 + 4;
  SetLength(LScreen, LPitch * (DEST_ROWS + 4));
  FillChar(LScreen[0], Length(LScreen), MARK8);
  LParams := Params(1, @LScreen[0], LPitch, 1, 2);
  LParams.DestinationWidth := 19;
  LParams.FracXStep := FRACUNIT * SRC_WIDTH div 19;
  TVideoRectCopy.StretchRows8(LParams);
  for LRow := 2 to 2 + DEST_ROWS - 1 do
    if LRow mod 2 = 1 then
      Assert.AreNotEqual<Integer>(MARK8, LScreen[LRow * LPitch + 3], 'row ' + IntToStr(LRow))
    else
      Assert.AreEqual<Integer>(MARK8, LScreen[LRow * LPitch + 3], 'row ' + IntToStr(LRow));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoRectCopy);

end.
