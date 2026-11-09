{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomColorQuantizer                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.ColorQuantizer;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   The QUANT lines of Tests\Data\Endoom\editor.golden.txt are the color indices that the old
  ///   TEndScreen (getcoloridx) chose for the colors of TEditorScenarios.ColorsToQuantize
  /// </summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomColorQuantizer = class(TObject)
  public
    [Test]
    procedure DovrebbeTrovareUnColoreEsatto;
    [Test]
    procedure DovrebbeTrovareIlPiuVicino;
    [Test]
    procedure DovrebbeScegliereIlPrimoInCasoDiParita;
    [Test]
    procedure DovrebbeUsareSoloGliOttoColoriDelloSfondo;
    [Test]
    procedure DovrebbeIgnorareIlByteAltoDelColore;
    [Test]
    procedure DovrebbeCalcolareLaDistanzaAlQuadrato;
    [Test]
    procedure DovrebbeRifiutareUnIntervalloSbagliato;
    [Test]
    procedure DovrebbeScegliereGliStessiColoriDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.ColorQuantizer,
  DelphiDoom.Tests.Endoom.Digest, DelphiDoom.Tests.Endoom.EditorScenarios, DelphiDoom.Tests.Endoom.EditorHelper;

{ TTestEndoomColorQuantizer }

procedure TTestEndoomColorQuantizer.DovrebbeTrovareUnColoreEsatto;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ENDOOM_COLOR_COUNT - 1 do
    Assert.AreEqual(LIndex, TEndoomColorQuantizer.NearestForeground(ENDOOM_COLORS[LIndex]));
  for LIndex := 0 to ENDOOM_BACKGROUND_COLOR_COUNT - 1 do
    Assert.AreEqual(LIndex, TEndoomColorQuantizer.NearestBackground(ENDOOM_COLORS[LIndex]));
end;

procedure TTestEndoomColorQuantizer.DovrebbeTrovareIlPiuVicino;
begin
  Assert.AreEqual(15, TEndoomColorQuantizer.NearestForeground($FEFEFE));
  Assert.AreEqual(0, TEndoomColorQuantizer.NearestForeground($010101));
  Assert.AreEqual(14, TEndoomColorQuantizer.NearestForeground($FFFF00));
  Assert.AreEqual(2, TEndoomColorQuantizer.NearestForeground($00B000));
end;

procedure TTestEndoomColorQuantizer.DovrebbeScegliereIlPrimoInCasoDiParita;
var
  LColors: TArray<Cardinal>;
  LColor: Cardinal;
  LIndex: Integer;
  LBest: Integer;
  LBestDistance: Integer;
  LDistance: Integer;
begin
  // an independent search: the first of the colors with the least distance (a strictly smaller one replaces it)
  LColors := TEditorScenarios.ColorsToQuantize;
  for LColor in LColors do
  begin
    LBest := -1;
    LBestDistance := MaxInt;
    for LIndex := 0 to ENDOOM_COLOR_COUNT - 1 do
    begin
      LDistance := TEndoomColorQuantizer.Distance(TEditorScenarios.ToRgb(LColor), ENDOOM_COLORS[LIndex]);
      if LDistance < LBestDistance then
      begin
        LBestDistance := LDistance;
        LBest := LIndex;
      end;
    end;
    Assert.AreEqual(LBest, TEndoomColorQuantizer.NearestForeground(TEditorScenarios.ToRgb(LColor)));
  end;
  // the colors of the table are a tie with themselves only: the first one found is the color
  Assert.AreEqual(0, TEndoomColorQuantizer.NearestIndex($000000, ENDOOM_COLOR_COUNT));
end;

procedure TTestEndoomColorQuantizer.DovrebbeUsareSoloGliOttoColoriDelloSfondo;
begin
  // white is the 15th color: a background gets the nearest of the first eight, the light gray
  Assert.AreEqual(7, TEndoomColorQuantizer.NearestBackground($FFFFFF));
  Assert.AreEqual(15, TEndoomColorQuantizer.NearestForeground($FFFFFF));
end;

procedure TTestEndoomColorQuantizer.DovrebbeIgnorareIlByteAltoDelColore;
begin
  Assert.AreEqual(TEndoomColorQuantizer.NearestForeground($AA5500), TEndoomColorQuantizer.NearestForeground($FFAA5500));
  Assert.AreEqual(6, TEndoomColorQuantizer.NearestForeground($FFAA5500));
end;

procedure TTestEndoomColorQuantizer.DovrebbeCalcolareLaDistanzaAlQuadrato;
begin
  Assert.AreEqual(0, TEndoomColorQuantizer.Distance($123456, $123456));
  Assert.AreEqual(3, TEndoomColorQuantizer.Distance($010101, $000000));
  Assert.AreEqual(3 * 255 * 255, TEndoomColorQuantizer.Distance($000000, $FFFFFF));
  Assert.AreEqual(100 * 100, TEndoomColorQuantizer.Distance($640000, $000000));
end;

procedure TTestEndoomColorQuantizer.DovrebbeRifiutareUnIntervalloSbagliato;
begin
  Assert.WillRaise(
    procedure
    begin
      TEndoomColorQuantizer.NearestIndex(0, 0);
    end, EEndoomException);
  Assert.WillRaise(
    procedure
    begin
      TEndoomColorQuantizer.NearestIndex(0, 17);
    end, EEndoomException);
end;

procedure TTestEndoomColorQuantizer.DovrebbeScegliereGliStessiColoriDelVecchioCodice;
var
  LColors: TArray<Cardinal>;
  LBackgrounds: TBytes;
  LForegrounds: TBytes;
  LIndex: Integer;
  LGolden: TArray<string>;
begin
  LColors := TEditorScenarios.ColorsToQuantize;
  SetLength(LBackgrounds, Length(LColors));
  SetLength(LForegrounds, Length(LColors));
  for LIndex := 0 to High(LColors) do
  begin
    LBackgrounds[LIndex] := TEndoomColorQuantizer.NearestBackground(TEditorScenarios.ToRgb(LColors[LIndex]));
    LForegrounds[LIndex] := TEndoomColorQuantizer.NearestForeground(TEditorScenarios.ToRgb(LColors[LIndex]));
  end;
  LGolden := TEditorHelper.GoldenLines('QUANT');
  Assert.AreEqual('bg ' + TEndoomDigest.OfBytes(LBackgrounds), LGolden[0]);
  Assert.AreEqual('fg ' + TEndoomDigest.OfBytes(LForegrounds), LGolden[1]);
end;

end.
