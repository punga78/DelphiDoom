{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingColorMath                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ColorMath;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.ColorMath,
  DelphiDoom.Tests.Imaging.Samples, DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingColorMath = class(TObject)
  private
    procedure CheckPairs(const AName: string; const AOperation: TFunc<Cardinal, Cardinal, Cardinal>);
  public
    [Test]
    procedure TestAddMatchesOldCode;
    [Test]
    procedure TestSubtractMatchesOldCode;
    [Test]
    procedure TestMeanMatchesOldCode;
    [Test]
    procedure TestMidAverageMatchesOldCode;
    [Test]
    procedure TestAverageMatchesOldCode;
    [Test]
    procedure TestLightAverageMatchesOldCode;
    [Test]
    procedure TestInverseLightAverageMatchesOldCode;
    [Test]
    procedure TestLightMatchesOldCode;
    [Test]
    procedure TestBoostMatchesOldCode;
    [Test]
    procedure TestInverseLightMatchesOldCode;
    [Test]
    procedure TestFuzzLightMatchesOldCode;
    [Test]
    procedure TestLightAddMatchesOldCode;
    [Test]
    procedure TestAverageWithFactorZeroGivesTheFirstColor;
    [Test]
    procedure TestAddLimitsEachChannelTo255;
    [Test]
    procedure TestSubtractNeverGoesBelowZero;
  end;

implementation

procedure TTestImagingColorMath.CheckPairs(const AName: string;
  const AOperation: TFunc<Cardinal, Cardinal, Cardinal>);
var
  LSamples: TArray<Cardinal>;
  LResults: TArray<Cardinal>;
  LFirst, LSecond: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  for LFirst := 0 to High(LSamples) do
    for LSecond := 0 to High(LSamples) do
    begin
      SetLength(LResults, Length(LResults) + 1);
      LResults[High(LResults)] := AOperation(LSamples[LFirst], LSamples[LSecond]);
    end;
  TImagingGolden.Check('colormath.golden.txt', AName, TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestAddMatchesOldCode;
begin
  CheckPairs('add', function(A, B: Cardinal): Cardinal begin Result := TImagingColorMath.Add(A, B); end);
end;

procedure TTestImagingColorMath.TestSubtractMatchesOldCode;
begin
  CheckPairs('subtract', function(A, B: Cardinal): Cardinal begin Result := TImagingColorMath.Subtract(A, B); end);
end;

procedure TTestImagingColorMath.TestMeanMatchesOldCode;
begin
  CheckPairs('mean', function(A, B: Cardinal): Cardinal begin Result := TImagingColorMath.Mean(A, B); end);
end;

procedure TTestImagingColorMath.TestMidAverageMatchesOldCode;
begin
  CheckPairs('midaverage', function(A, B: Cardinal): Cardinal begin Result := TImagingColorMath.MidAverage(A, B); end);
end;

procedure TTestImagingColorMath.TestAverageMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LFactors: TArray<Integer>;
  LResults: TArray<Cardinal>;
  LFirst, LSecond, LFactor: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  LFactors := TImagingSamples.ColorFactors;
  for LFirst := 0 to High(LSamples) do
    for LSecond := 0 to High(LSamples) do
      for LFactor := 0 to High(LFactors) do
      begin
        SetLength(LResults, Length(LResults) + 1);
        LResults[High(LResults)] := TImagingColorMath.Average(LSamples[LFirst], LSamples[LSecond], LFactors[LFactor]);
      end;
  TImagingGolden.Check('colormath.golden.txt', 'average', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestLightAverageMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LFactors, LLights: TArray<Integer>;
  LResults: TArray<Cardinal>;
  LFirst, LSecond, LFactor, LLight: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  LFactors := TImagingSamples.ColorFactors;
  LLights := TImagingSamples.LightFactors;
  for LFirst := 0 to High(LSamples) do
    for LSecond := 0 to High(LSamples) do
      for LFactor := 0 to High(LFactors) do
        for LLight := 0 to High(LLights) do
        begin
          SetLength(LResults, Length(LResults) + 1);
          LResults[High(LResults)] := TImagingColorMath.LightAverage(LSamples[LFirst],
            LSamples[LSecond], LFactors[LFactor], LLights[LLight]);
        end;
  TImagingGolden.Check('colormath.golden.txt', 'lightaverage', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestInverseLightAverageMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LFactors: TArray<Integer>;
  LResults: TArray<Cardinal>;
  LFirst, LSecond, LFactor: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  LFactors := TImagingSamples.ColorFactors;
  for LFirst := 0 to High(LSamples) do
    for LSecond := 0 to High(LSamples) do
      for LFactor := 0 to High(LFactors) do
      begin
        SetLength(LResults, Length(LResults) + 1);
        LResults[High(LResults)] := TImagingColorMath.InverseLightAverage(LSamples[LFirst],
          LSamples[LSecond], LFactors[LFactor]);
      end;
  TImagingGolden.Check('colormath.golden.txt', 'inverselightaverage', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestLightMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LLights: TArray<Integer>;
  LResults: TArray<Cardinal>;
  LColor, LLight: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  LLights := TImagingSamples.LightFactors;
  for LColor := 0 to High(LSamples) do
    for LLight := 0 to High(LLights) do
    begin
      SetLength(LResults, Length(LResults) + 1);
      LResults[High(LResults)] := TImagingColorMath.Light(LSamples[LColor], LLights[LLight]);
    end;
  TImagingGolden.Check('colormath.golden.txt', 'light', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestBoostMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LLights: TArray<Integer>;
  LResults: TArray<Cardinal>;
  LColor, LLight: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  LLights := TImagingSamples.LightFactors;
  for LColor := 0 to High(LSamples) do
    for LLight := 0 to High(LLights) do
    begin
      SetLength(LResults, Length(LResults) + 1);
      LResults[High(LResults)] := TImagingColorMath.Boost(LSamples[LColor], LLights[LLight]);
    end;
  TImagingGolden.Check('colormath.golden.txt', 'boost', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestInverseLightMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LResults: TArray<Cardinal>;
  LColor: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  SetLength(LResults, Length(LSamples));
  for LColor := 0 to High(LSamples) do
    LResults[LColor] := TImagingColorMath.InverseLight(LSamples[LColor]);
  TImagingGolden.Check('colormath.golden.txt', 'inverselight', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestFuzzLightMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LResults: TArray<Cardinal>;
  LColor: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  SetLength(LResults, Length(LSamples));
  for LColor := 0 to High(LSamples) do
    LResults[LColor] := TImagingColorMath.FuzzLight(LSamples[LColor]);
  TImagingGolden.Check('colormath.golden.txt', 'fuzzlight', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestLightAddMatchesOldCode;
var
  LSamples: TArray<Cardinal>;
  LValues: TArray<Cardinal>;
  LResults: TArray<Cardinal>;
  LColor, LRed, LGreen, LBlue: Integer;
begin
  LSamples := TImagingSamples.ColorSamples;
  LValues := TImagingSamples.LightAddValues;
  for LColor := 0 to High(LSamples) do
    for LRed := 0 to High(LValues) do
      for LGreen := 0 to High(LValues) do
        for LBlue := 0 to High(LValues) do
        begin
          SetLength(LResults, Length(LResults) + 1);
          LResults[High(LResults)] := TImagingColorMath.LightAdd(LSamples[LColor], LValues[LRed],
            LValues[LGreen], LValues[LBlue]);
        end;
  TImagingGolden.Check('colormath.golden.txt', 'lightadd', TImagingSamples.Hex(TImagingSamples.Hash(LResults)));
end;

procedure TTestImagingColorMath.TestAverageWithFactorZeroGivesTheFirstColor;
begin
  // factor 0 uses FRACUNIT - 1 for the first color: the channels lose at most one step
  Assert.AreEqual(Cardinal($00000000), TImagingColorMath.Average(0, $00FFFFFF, 0), 'dovrebbe dare nero se il primo colore e'' nero');
  Assert.AreEqual(Cardinal($00FEFEFE), TImagingColorMath.Average($00FFFFFF, 0, 0), 'dovrebbe dare quasi il primo colore');
end;

procedure TTestImagingColorMath.TestAddLimitsEachChannelTo255;
begin
  Assert.AreEqual(Cardinal($00FFFFFF), TImagingColorMath.Add($00F0F0F0, $00F0F0F0), 'dovrebbe limitare a 255 ogni canale');
  Assert.AreEqual(Cardinal($00020406), TImagingColorMath.Add($00010203, $00010203), 'dovrebbe sommare canale per canale');
end;

procedure TTestImagingColorMath.TestSubtractNeverGoesBelowZero;
begin
  Assert.AreEqual(Cardinal(0), TImagingColorMath.Subtract($00102030, $00FFFFFF), 'dovrebbe fermarsi a zero');
  Assert.AreEqual(Cardinal($00010101), TImagingColorMath.Subtract($00020202, $00010101), 'dovrebbe sottrarre canale per canale');
end;

end.
