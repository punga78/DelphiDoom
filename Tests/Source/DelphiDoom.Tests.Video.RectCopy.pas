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
    [Test]
    procedure DovrebbeStirareConTrasparenzaA8Bit;
    [Test]
    procedure DovrebbeCopiareUnoAUnoConTrasparenzaConIlFilo;
    [Test]
    procedure DovrebbeStirareConTrasparenzaA32BitComeIlVecchioCodice;
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

procedure TTestVideoRectCopy.DovrebbeStirareConTrasparenzaA8Bit;
var
  LRow, LColumn, LPitch, LSourceRow, LDestWidth, LIndex: Integer;
  LScreen: TBytes;
  LParams: TVideoRectCopyParams;
  LPixel: Byte;
begin
  for LIndex := 0 to High(FSource) do
    if LIndex mod 3 = 0 then
      FSource[LIndex] := 0;
  LDestWidth := 19;
  LPitch := 3 + LDestWidth + 4;
  SetLength(LScreen, LPitch * (DEST_ROWS + 4));
  FillChar(LScreen[0], Length(LScreen), MARK8);
  LParams := Params(1, @LScreen[0], LPitch, 0, 1);
  LParams.DestinationWidth := LDestWidth;
  LParams.FracXStep := FRACUNIT * SRC_WIDTH div LDestWidth;
  TVideoRectCopy.StretchRowsTransparent8(LParams);
  for LRow := 0 to DEST_ROWS - 1 do
  begin
    LSourceRow := (LRow * LParams.FracYStep) div FRACUNIT;
    for LColumn := 0 to LDestWidth - 1 do
    begin
      LPixel := SourcePixel(LSourceRow, (LColumn * LParams.FracXStep) div FRACUNIT);
      if LPixel = 0 then
        Assert.AreEqual<Integer>(MARK8, LScreen[(2 + LRow) * LPitch + 3 + LColumn])
      else
        Assert.AreEqual<Integer>(LPixel, LScreen[(2 + LRow) * LPitch + 3 + LColumn]);
    end;
  end;
end;

procedure TTestVideoRectCopy.DovrebbeCopiareUnoAUnoConTrasparenzaConIlFilo;
var
  LIndex, LRow, LColumn, LPitch: Integer;
  LScreen: TBytes;
  LPixel: Byte;
begin
  for LIndex := 0 to High(FSource) do
    if LIndex mod 4 = 1 then
      FSource[LIndex] := 0;
  LPitch := 20;
  for LIndex := 0 to 2 do
  begin
    SetLength(LScreen, LPitch * (SRC_HEIGHT + 2));
    FillChar(LScreen[0], Length(LScreen), MARK8);
    // the rows count down: the row of the source r is the number SRC_HEIGHT - r
    TVideoRectCopy.CopyRowsTransparent8(@FSource[0], @LScreen[0], SRC_WIDTH, LPitch, SRC_WIDTH, SRC_HEIGHT, LIndex, 3);
    for LRow := 0 to SRC_HEIGHT - 1 do
      for LColumn := 0 to SRC_WIDTH - 1 do
      begin
        LPixel := SourcePixel(LRow, LColumn);
        if ((SRC_HEIGHT - LRow) mod 3 = LIndex) and (LPixel <> 0) then
          Assert.AreEqual<Integer>(LPixel, LScreen[LRow * LPitch + LColumn])
        else
          Assert.AreEqual<Integer>(MARK8, LScreen[LRow * LPitch + LColumn]);
      end;
  end;
end;

// The loop of V_CopyRectTransparent32 before TVideoRectCopy, with its skip of four zero pixels
procedure OldTransparent32(const ASource: PByte; const ADest: PLongWord; const APalette: PLongWord;
  const ASourcePitch, ADestPitch, ASourceX, ADestX, ADestY, ADestW, ADestH, AFracY, AFracYStep, AFracXStep: Integer);
type
  TBytes0 = array[0..MaxInt div 2 - 1] of Byte;
  PBytes0 = ^TBytes0;
  TLongs0 = array[0..MaxInt div 8 - 1] of LongWord;
  PLongs0 = ^TLongs0;
var
  src: PBytes0;
  dest: PLongs0;
  destw, destw1, row, col, fracx, fracy, fracxstep4: Integer;
  psrcl: PLongWord;
  srcb: Byte;
begin
  destw1 := ADestW and $3;
  fracxstep4 := 4 * AFracXStep;
  fracy := AFracY;
  destw := ADestW - destw1;
  for row := ADestY to ADestY + ADestH - 1 do
  begin
    fracx := 0;
    dest := PLongs0(NativeInt(ADest) + (ADestPitch * row + ADestX) * 4);
    src := PBytes0(NativeInt(ASource) + ASourcePitch * (fracy div 65536) + ASourceX);
    col := 0;
    while col < destw do
    begin
      psrcl := @src[LongWord(fracx) shr 16];
      if psrcl^ = 0 then
      begin
        Inc(col, 4);
        fracx := fracx + fracxstep4;
      end
      else
      begin
        srcb := PByte(psrcl)^;
        if srcb <> 0 then
          dest[col] := PLongs0(APalette)[srcb];
        Inc(col);
        fracx := fracx + AFracXStep;
      end;
    end;
    for col := destw to destw + destw1 - 1 do
    begin
      srcb := src[LongWord(fracx) shr 16];
      if srcb <> 0 then
        dest[col] := PLongs0(APalette)[srcb];
      fracx := fracx + AFracXStep;
    end;
    fracy := fracy + AFracYStep;
  end;
end;

procedure TTestVideoRectCopy.DovrebbeStirareConTrasparenzaA32BitComeIlVecchioCodice;
var
  LIndex, LDestWidth, LPitch: Integer;
  LExpected, LActual: array of LongWord;
  LParams: TVideoRectCopyParams;
begin
  // runs of zero pixels exercise the skip of four
  for LIndex := 0 to High(FSource) do
    if (LIndex mod 8) < 5 then
      FSource[LIndex] := 0;
  for LDestWidth in [8, 11, 16, 19, 23] do
  begin
    LPitch := 3 + LDestWidth + 4;
    SetLength(LExpected, LPitch * (DEST_ROWS + 4));
    SetLength(LActual, LPitch * (DEST_ROWS + 4));
    for LIndex := 0 to High(LExpected) do
    begin
      LExpected[LIndex] := MARK32;
      LActual[LIndex] := MARK32;
    end;
    LParams := Params(1, @LActual[0], LPitch, 0, 1);
    LParams.DestinationWidth := LDestWidth;
    LParams.FracXStep := FRACUNIT * SRC_WIDTH div LDestWidth;
    OldTransparent32(@FSource[0], @LExpected[0], @FPalette[0], SRC_WIDTH, LPitch, 0, 3, 2, LDestWidth, DEST_ROWS,
      0, LParams.FracYStep, LParams.FracXStep);
    TVideoRectCopy.StretchRowsTransparent32(LParams, @FPalette[0]);
    Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected) * SizeOf(LongWord)), 'width ' + IntToStr(LDestWidth));
  end;
end;
initialization
  TDUnitX.RegisterTestFixture(TTestVideoRectCopy);

end.
