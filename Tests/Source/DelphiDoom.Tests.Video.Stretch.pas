{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - stretching of rows and buffers      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.Stretch;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.Stretch;

type
  [TestFixture]
  [Category('video')]
  TTestVideoStretch = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaPercentualeDelVecchioCodice;
    [Test]
    procedure DovrebbeStirareUnaRigaA8BitComeIlVecchioCodice;
    [Test]
    procedure DovrebbeStirareUnaRigaA32BitComeIlVecchioCodice;
    [Test]
    procedure DovrebbeRendereOpacheLeRigheStirateSeRichiesto;
    [Test]
    procedure DovrebbeScalareUnaImmagineComeIlVecchioV_ScaleBuffer8;
    [Test]
    procedure DovrebbeNonScrivereFuoriDallIntervallo;
  end;

implementation

type
  TByteRow = array of Byte;
  TLongWordRow = array of LongWord;

// The clamp of d_delphi.ibetween (the old text called it for every pixel)
function OldBetween(const AValue, ALow, AHigh: Integer): Integer;
begin
  if AValue <= ALow then
    Result := ALow
  else if AValue >= AHigh then
    Result := AHigh
  else
    Result := AValue;
end;

// The loop that was in V_FullScreenStretch and V_StatusBarStretch (8 bit)
procedure OldStretch8(const ASource: TByteRow; var ABuffer: TByteRow; const AWidth, AStart, AStop: Integer);
var
  LIndex: Integer;
begin
  for LIndex := AStart to AStop do
    ABuffer[LIndex] := ASource[OldBetween(AWidth * (LIndex - AStart) div (AStop - AStart + 1), 0, AWidth - 1)];
end;

procedure OldStretch32(const ASource: TLongWordRow; var ABuffer: TLongWordRow; const AWidth, AStart, AStop: Integer;
  const AOr: LongWord);
var
  LIndex: Integer;
begin
  for LIndex := AStart to AStop do
    ABuffer[LIndex] := AOr or ASource[OldBetween(AWidth * (LIndex - AStart) div (AStop - AStart + 1), 0, AWidth - 1)];
end;

// V_ScaleBuffer8 before TVideoStretch
procedure OldScale8(const ASource: TByteRow; var ADest: TByteRow; const FWidth, FHeight, AWidth, AHeight: Integer);
var
  xs, ys, xi, yi, x, y: Integer;
  edi: Integer;
  esi: Integer;
begin
  xi := (FWidth shl 16) div AWidth;
  yi := (FHeight shl 16) div AHeight;
  edi := 0;
  ys := 0;
  for y := 0 to AHeight - 1 do
  begin
    esi := (ys shr 16) * FWidth;
    xs := 0;
    for x := 0 to AWidth - 1 do
    begin
      ADest[edi + x] := ASource[esi + xs shr 16];
      xs := xs + xi;
    end;
    edi := edi + AWidth;
    ys := ys + yi;
  end;
end;

function RandomRow8(const ACount: Integer): TByteRow;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(LIndex * 37 + 11);
end;

function RandomRow32(const ACount: Integer): TLongWordRow;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := LongWord((Int64(LIndex) * 2654435761) and $00FFFFFF);
end;

{ TTestVideoStretch }

procedure TTestVideoStretch.DovrebbeDareLaPercentualeDelVecchioCodice;
begin
  Assert.AreEqual<Integer>(Round((1 - (4 / 3) / (1920 / 1080)) * 100), TVideoStretch.WidePercentage(1920, 1080));
  Assert.AreEqual<Integer>(Round((1 - (4 / 3) / (640 / 480)) * 100), TVideoStretch.WidePercentage(640, 480));
  Assert.AreEqual<Integer>(Round((1 - (4 / 3) / (1280 / 800)) * 100), TVideoStretch.WidePercentage(1280, 800));
  Assert.IsTrue(TVideoStretch.WidePercentage(640, 480) <= 0);
end;

procedure TTestVideoStretch.DovrebbeStirareUnaRigaA8BitComeIlVecchioCodice;
var
  LWidth, LStart: Integer;
  LSource, LExpected, LActual: TByteRow;
begin
  for LWidth in [320, 640, 1280, 1920] do
  begin
    LStart := (LWidth div 8);
    LSource := RandomRow8(LWidth);
    SetLength(LExpected, LWidth);
    SetLength(LActual, LWidth);
    OldStretch8(LSource, LExpected, LWidth, LStart, LWidth - LStart);
    TVideoStretch.StretchRow8(PVideoByteRow(LSource), PVideoByteRow(LActual), LWidth, LStart, LWidth - LStart);
    Assert.IsTrue(CompareMem(LExpected, LActual, LWidth), 'width ' + IntToStr(LWidth));
  end;
end;

procedure TTestVideoStretch.DovrebbeStirareUnaRigaA32BitComeIlVecchioCodice;
var
  LWidth, LStart: Integer;
  LSource, LExpected, LActual: TLongWordRow;
begin
  for LWidth in [320, 640, 1280, 1920] do
  begin
    LStart := (LWidth div 6);
    LSource := RandomRow32(LWidth);
    SetLength(LExpected, LWidth);
    SetLength(LActual, LWidth);
    OldStretch32(LSource, LExpected, LWidth, LStart, LWidth - LStart, 0);
    TVideoStretch.StretchRow32(PVideoLongWordRow(LSource), PVideoLongWordRow(LActual), LWidth, LStart, LWidth - LStart);
    Assert.IsTrue(CompareMem(LExpected, LActual, LWidth * SizeOf(LongWord)), 'width ' + IntToStr(LWidth));
  end;
end;

procedure TTestVideoStretch.DovrebbeRendereOpacheLeRigheStirateSeRichiesto;
var
  LSource, LExpected, LActual: TLongWordRow;
begin
  LSource := RandomRow32(800);
  SetLength(LExpected, 800);
  SetLength(LActual, 800);
  OldStretch32(LSource, LExpected, 800, 100, 700, $FF000000);
  TVideoStretch.StretchRow32Opaque(PVideoLongWordRow(LSource), PVideoLongWordRow(LActual), 800, 100, 700);
  Assert.IsTrue(CompareMem(LExpected, LActual, 800 * SizeOf(LongWord)));
  Assert.AreEqual<LongWord>($FF000000, LActual[100] and $FF000000);
end;

procedure TTestVideoStretch.DovrebbeScalareUnaImmagineComeIlVecchioV_ScaleBuffer8;
const
  SIZES: array[0..5, 0..3] of Integer = (
    (320, 200, 320, 200), (640, 400, 320, 200), (100, 80, 320, 200),
    (426, 200, 320, 200), (1920, 1080, 320, 200), (7, 3, 13, 29));
var
  LCase: Integer;
  LSource, LExpected, LActual: TByteRow;
begin
  for LCase := 0 to High(SIZES) do
  begin
    LSource := RandomRow8(SIZES[LCase, 0] * SIZES[LCase, 1]);
    SetLength(LExpected, SIZES[LCase, 2] * SIZES[LCase, 3]);
    SetLength(LActual, SIZES[LCase, 2] * SIZES[LCase, 3]);
    OldScale8(LSource, LExpected, SIZES[LCase, 0], SIZES[LCase, 1], SIZES[LCase, 2], SIZES[LCase, 3]);
    TVideoStretch.ScaleNearest8(PVideoByteRow(LSource), PVideoByteRow(LActual),
      SIZES[LCase, 0], SIZES[LCase, 1], SIZES[LCase, 2], SIZES[LCase, 3]);
    Assert.IsTrue(CompareMem(LExpected, LActual, Length(LExpected)), 'case ' + IntToStr(LCase));
  end;
end;

procedure TTestVideoStretch.DovrebbeNonScrivereFuoriDallIntervallo;
var
  LSource, LBuffer: TLongWordRow;
  LIndex: Integer;
begin
  LSource := RandomRow32(100);
  SetLength(LBuffer, 100);
  for LIndex := 0 to 99 do
    LBuffer[LIndex] := $DEADBEEF;
  TVideoStretch.StretchRow32(PVideoLongWordRow(LSource), PVideoLongWordRow(LBuffer), 100, 10, 89);
  Assert.AreEqual<LongWord>($DEADBEEF, LBuffer[9]);
  Assert.AreEqual<LongWord>($DEADBEEF, LBuffer[90]);
  Assert.AreNotEqual<LongWord>($DEADBEEF, LBuffer[10]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoStretch);

end.
