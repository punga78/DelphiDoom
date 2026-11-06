{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - palette, size limit, stall hack     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.Services;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Video.Intf;

type
  TFakeDisplayMetrics = class(TInterfacedObject, IDisplayMetrics)
  private
    FWidth: Integer;
    FHeight: Integer;
  public
    constructor Create(AWidth, AHeight: Integer);
    function GetWidth: Integer;
    function GetHeight: Integer;
  end;

  [TestFixture]
  [Category('video')]
  TTestVideoServices = class(TObject)
  private
    FGamma: array[0..255] of Byte;
    FSource: array[0..255 * 3 + 2] of Byte;
    FDest: array[0..255] of Cardinal;
    function Limiter(AWidth, AHeight: Integer): ISizeLimiter;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestPaletteIdentityGammaPacksRedGreenBlue;
    [Test]
    procedure TestPaletteGammaIsAppliedToEveryChannel;
    [Test]
    procedure TestPaletteConvertsAllTheColors;
    [Test]
    procedure TestPaletteAlphaStaysZero;
    [Test]
    procedure TestLimiterLeavesWhatFits;
    [Test]
    procedure TestLimiterReducesTheWidth;
    [Test]
    procedure TestLimiterReducesTheHeight;
    [Test]
    procedure TestLimiterReducesBoth;
    [Test]
    procedure TestLimiterEqualSizeIsFine;
    [Test]
    [TestCase('1024', '1024,1022')]
    [TestCase('1152', '1152,1150')]
    [TestCase('1280', '1280,1278')]
    procedure TestStallHackNarrowsTheKnownWidths(AWidth, AExpected: Integer);
    [Test]
    [TestCase('640', '640')]
    [TestCase('800', '800')]
    [TestCase('1023', '1023')]
    [TestCase('1920', '1920')]
    procedure TestStallHackLeavesTheOthers(AWidth: Integer);
    [Test]
    procedure TestStallHackDisabledDoesNotTouchTheWidth;
    [Test]
    procedure TestStallHackRemembersUntilAnotherWidth;
    [Test]
    procedure TestServicesGiveWhatTheyWereMadeWith;
    [Test]
    procedure TestWindowsMetricsAreRealNumbers;
  end;

implementation

uses
  DelphiDoom.Video.Factory, DelphiDoom.Video.Services;

{ TFakeDisplayMetrics }

constructor TFakeDisplayMetrics.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
end;

function TFakeDisplayMetrics.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TFakeDisplayMetrics.GetHeight: Integer;
begin
  Result := FHeight;
end;

{ TTestVideoServices }

procedure TTestVideoServices.Setup;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    FGamma[LIndex] := Byte(LIndex);
  FillChar(FSource, SizeOf(FSource), 0);
  FillChar(FDest, SizeOf(FDest), $FF);
end;

function TTestVideoServices.Limiter(AWidth, AHeight: Integer): ISizeLimiter;
begin
  Result := TVideoFactory.CreateSizeLimiter(TFakeDisplayMetrics.Create(AWidth, AHeight));
end;

procedure TTestVideoServices.TestPaletteIdentityGammaPacksRedGreenBlue;
begin
  FSource[0] := $12;
  FSource[1] := $34;
  FSource[2] := $56;
  TVideoFactory.CreatePaletteConverter.Convert(@FSource[0], @FGamma[0], @FDest[0]);
  Assert.AreEqual(Cardinal($00123456), FDest[0]);
end;

procedure TTestVideoServices.TestPaletteGammaIsAppliedToEveryChannel;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    FGamma[LIndex] := Byte(255 - LIndex);
  FSource[3] := 0;
  FSource[4] := 100;
  FSource[5] := 255;
  TVideoFactory.CreatePaletteConverter.Convert(@FSource[0], @FGamma[0], @FDest[0]);
  Assert.AreEqual(Cardinal($00FF9B00), FDest[1]);
end;

procedure TTestVideoServices.TestPaletteConvertsAllTheColors;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    FSource[LIndex * 3] := Byte(LIndex);
    FSource[LIndex * 3 + 1] := 0;
    FSource[LIndex * 3 + 2] := 0;
  end;
  TVideoFactory.CreatePaletteConverter.Convert(@FSource[0], @FGamma[0], @FDest[0]);
  Assert.AreEqual(Cardinal($00FF0000), FDest[255]);
  Assert.AreEqual(Cardinal($00800000), FDest[128]);
end;

procedure TTestVideoServices.TestPaletteAlphaStaysZero;
begin
  FSource[0] := 255;
  FSource[1] := 255;
  FSource[2] := 255;
  TVideoFactory.CreatePaletteConverter.Convert(@FSource[0], @FGamma[0], @FDest[0]);
  Assert.AreEqual(Cardinal($00FFFFFF), FDest[0]);
end;

procedure TTestVideoServices.TestLimiterLeavesWhatFits;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 800;
  LHeight := 600;
  Assert.IsFalse(Limiter(1920, 1080).Limit(LWidth, LHeight));
  Assert.AreEqual(800, LWidth);
  Assert.AreEqual(600, LHeight);
end;

procedure TTestVideoServices.TestLimiterReducesTheWidth;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 3000;
  LHeight := 600;
  Assert.IsTrue(Limiter(1920, 1080).Limit(LWidth, LHeight));
  Assert.AreEqual(1920, LWidth);
  Assert.AreEqual(600, LHeight);
end;

procedure TTestVideoServices.TestLimiterReducesTheHeight;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 800;
  LHeight := 2000;
  Assert.IsTrue(Limiter(1920, 1080).Limit(LWidth, LHeight));
  Assert.AreEqual(800, LWidth);
  Assert.AreEqual(1080, LHeight);
end;

procedure TTestVideoServices.TestLimiterReducesBoth;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 4000;
  LHeight := 3000;
  Assert.IsTrue(Limiter(1920, 1080).Limit(LWidth, LHeight));
  Assert.AreEqual(1920, LWidth);
  Assert.AreEqual(1080, LHeight);
end;

procedure TTestVideoServices.TestLimiterEqualSizeIsFine;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 1920;
  LHeight := 1080;
  Assert.IsFalse(Limiter(1920, 1080).Limit(LWidth, LHeight));
end;

procedure TTestVideoServices.TestStallHackNarrowsTheKnownWidths(AWidth, AExpected: Integer);
begin
  Assert.IsTrue(TVideoFactory.CreateMemoryStallHack.Apply(AWidth, True));
  Assert.AreEqual(AExpected, AWidth);
end;

procedure TTestVideoServices.TestStallHackLeavesTheOthers(AWidth: Integer);
var
  LExpected: Integer;
begin
  LExpected := AWidth;
  Assert.IsFalse(TVideoFactory.CreateMemoryStallHack.Apply(AWidth, True));
  Assert.AreEqual(LExpected, AWidth);
end;

procedure TTestVideoServices.TestStallHackDisabledDoesNotTouchTheWidth;
var
  LWidth: Integer;
begin
  LWidth := 1024;
  Assert.IsFalse(TVideoFactory.CreateMemoryStallHack.Apply(LWidth, False));
  Assert.AreEqual(1024, LWidth);
end;

procedure TTestVideoServices.TestStallHackRemembersUntilAnotherWidth;
var
  LHack: IMemoryStallHack;
  LWidth: Integer;
begin
  LHack := TVideoFactory.CreateMemoryStallHack;
  LWidth := 1280;
  Assert.IsTrue(LHack.Apply(LWidth, True));
  // the same width again, now disabled: the answer is still the one of before
  LWidth := 1280;
  Assert.IsTrue(LHack.Apply(LWidth, False));
  Assert.AreEqual(1280, LWidth);
  LWidth := 800;
  Assert.IsFalse(LHack.Apply(LWidth, False));
  LWidth := 1280;
  Assert.IsFalse(LHack.Apply(LWidth, False));
end;

procedure TTestVideoServices.TestServicesGiveWhatTheyWereMadeWith;
var
  LPalette: IPaletteConverter;
  LLimiter: ISizeLimiter;
  LHack: IMemoryStallHack;
  LServices: IVideoServices;
begin
  LPalette := TVideoFactory.CreatePaletteConverter;
  LLimiter := Limiter(10, 10);
  LHack := TVideoFactory.CreateMemoryStallHack;
  LServices := TVideoServices.Create(LPalette, LLimiter, LHack);
  Assert.AreSame(LPalette, LServices.Palette);
  Assert.AreSame(LLimiter, LServices.SizeLimiter);
  Assert.AreSame(LHack, LServices.StallHack);
end;

procedure TTestVideoServices.TestWindowsMetricsAreRealNumbers;
var
  LMetrics: IDisplayMetrics;
begin
  LMetrics := TVideoFactory.CreateWindowsDisplayMetrics;
  Assert.IsTrue(LMetrics.Width > 0);
  Assert.IsTrue(LMetrics.Height > 0);
end;

end.
