{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - TGreedFliDecoder against the shared }
{  FLI/FLC decoder of Libs\Flic (issue #229)                                    }
{                                                                              }
{  TGreedFliDecoder is NOT replaced by TFlicFrameDecoder: the two read the same }
{  format but differ in what they draw. These tests pin both sides: the common  }
{  subset (COLOR_64, BYTE_RUN, DELTA_FLI, FLI_COPY on a picture without a zero  }
{  pixel) gives the same pixels and colors, and each known difference gives     }
{  different bytes, so a future merge cannot hide it. The table is in           }
{  Libs\Flic\CLAUDE.md.                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.FliVsFlic;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Flic.FrameDecoder,
  DelphiDoom.Greed.FliDecoder,
  DelphiDoom.Tests.Greed.FliScenarios;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedFliVsFlic = class
  strict private
    FBuilder: TFliBuilder;
    FGreed: TGreedFliDecoder;
    FFlic: TFlicFrameDecoder;
    FGreedScreen: TBytes;
    FFlicScreen: TBytes;
    procedure Open;
    procedure DecodeBoth;
    function RunFill(AValue: Byte): TBytes;
    function ColorsSixBit: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliStessiPixelEColoriSuIlSottoinsiemeComune;
    [Test]
    procedure DovrebbeDifferireSulloZeroCheGreedSostituisceConApproxZero;
    [Test]
    procedure DovrebbeDifferireSuBlackCheGreedRiempieEIlComuneConservaAMeta;
    [Test]
    procedure DovrebbeDifferireSuColor256CheGreedIgnora;
  end;

implementation

uses
  DelphiDoom.Flic.Types;

const
  PIXELS = 64000;

{ TTestGreedFliVsFlic }

procedure TTestGreedFliVsFlic.Setup;
begin
  FBuilder := TFliBuilder.Create(200, 3);
  SetLength(FGreedScreen, PIXELS);
  SetLength(FFlicScreen, PIXELS);
end;

procedure TTestGreedFliVsFlic.TearDown;
begin
  FreeAndNil(FGreed);
  FreeAndNil(FFlic);
  FreeAndNil(FBuilder);
end;

function TTestGreedFliVsFlic.ColorsSixBit: TBytes;
begin
  // one packet: skip 0, 3 colors: black, black, white (6 bit values)
  Result := TBytes.Create(1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 63, 63, 63);
end;

function TTestGreedFliVsFlic.RunFill(AValue: Byte): TBytes;
var
  LRow: Integer;
begin
  // BYTE_RUN: every row is three runs of AValue (127 + 127 + 66 = 320 pixels)
  SetLength(Result, 200 * 7);
  for LRow := 0 to 199 do
  begin
    Result[LRow * 7] := 3;
    Result[LRow * 7 + 1] := 127;
    Result[LRow * 7 + 2] := AValue;
    Result[LRow * 7 + 3] := 127;
    Result[LRow * 7 + 4] := AValue;
    Result[LRow * 7 + 5] := 66;
    Result[LRow * 7 + 6] := AValue;
  end;
end;

procedure TTestGreedFliVsFlic.Open;
var
  LBytes: TBytes;
begin
  LBytes := FBuilder.Build;
  FGreed := TGreedFliDecoder.Create(LBytes);
  FFlic := TFlicFrameDecoder.Create(LBytes);
end;

procedure TTestGreedFliVsFlic.DecodeBoth;
begin
  Assert.IsTrue(FGreed.DecodeFrame(FGreedScreen));
  Assert.IsTrue(FFlic.FindFrame);
  FFlic.DecodeFrame(FFlicScreen, 320, 0, False);
end;

procedure TTestGreedFliVsFlic.DovrebbeDareGliStessiPixelEColoriSuIlSottoinsiemeComune;
var
  LIndex: Integer;
begin
  FBuilder.BeginFrame;
  FBuilder.Chunk(GREED_FLI_CHUNK_COLORS, ColorsSixBit);
  FBuilder.Chunk(GREED_FLI_CHUNK_RUN, RunFill(9));
  // DELTA_FLI: from row 5, two rows: skip 1 and 3 literal pixels, then a fill of 3
  FBuilder.Chunk(GREED_FLI_CHUNK_LINES, TBytes.Create(5, 0, 2, 0, 2, 1, 3, 7, 8, 7, 0, $FD, 6, 1, 4, 2, 1, 2));
  FBuilder.EndFrame;
  Open;
  DecodeBoth;
  for LIndex := 0 to PIXELS - 1 do
    if FGreedScreen[LIndex] <> FFlicScreen[LIndex] then
      Assert.Fail(Format('pixel %d: %d and %d', [LIndex, FGreedScreen[LIndex], FFlicScreen[LIndex]]));
  Assert.AreEqual(252, Integer(FGreed.Palette[2 * 3]));
  Assert.AreEqual(Integer(FGreed.Palette[2 * 3]), Integer(FFlic.Color(2).Red));
  Assert.AreEqual(Integer(FGreed.Palette[2 * 3 + 2]), Integer(FFlic.Color(2).Blue));
end;

procedure TTestGreedFliVsFlic.DovrebbeDifferireSulloZeroCheGreedSostituisceConApproxZero;
begin
  FBuilder.BeginFrame;
  FBuilder.Chunk(GREED_FLI_CHUNK_COLORS, ColorsSixBit);
  FBuilder.Chunk(GREED_FLI_CHUNK_RUN, RunFill(0));
  FBuilder.EndFrame;
  Open;
  DecodeBoth;
  // Greed turns every 0 into the color that looks most like black (the color 0 is the transparent one of the screen)
  Assert.AreNotEqual(0, Integer(FGreed.ApproxZero));
  Assert.AreEqual(Integer(FGreed.ApproxZero), Integer(FGreedScreen[0]));
  Assert.AreEqual(0, Integer(FFlicScreen[0]));
end;

procedure TTestGreedFliVsFlic.DovrebbeDifferireSuBlackCheGreedRiempieEIlComuneConservaAMeta;
begin
  FBuilder.BeginFrame;
  FBuilder.Chunk(GREED_FLI_CHUNK_COLORS, ColorsSixBit);
  FBuilder.Chunk(GREED_FLI_CHUNK_RUN, RunFill(9));
  FBuilder.Chunk(GREED_FLI_CHUNK_CLEAR, nil);
  FBuilder.EndFrame;
  Open;
  DecodeBoth;
  // Greed fills the whole screen with ApproxZero; the shared decoder keeps the C++ of OpenXcom, which clears
  // "height" (200) pixels of every 320-pixel row
  Assert.AreEqual(Integer(FGreed.ApproxZero), Integer(FGreedScreen[PIXELS - 1]));
  Assert.AreEqual(0, Integer(FFlicScreen[199]));
  Assert.AreEqual(9, Integer(FFlicScreen[200]));
end;

procedure TTestGreedFliVsFlic.DovrebbeDifferireSuColor256CheGreedIgnora;
begin
  FBuilder.BeginFrame;
  // COLOR_256 (type 4): one packet, skip 1, one color (8 bit values)
  FBuilder.Chunk(4, TBytes.Create(1, 0, 1, 1, 10, 20, 30));
  FBuilder.EndFrame;
  Open;
  DecodeBoth;
  Assert.AreEqual(0, Integer(FGreed.Palette[3]));
  Assert.AreEqual(10, Integer(FFlic.Color(1).Red));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedFliVsFlic);

end.
