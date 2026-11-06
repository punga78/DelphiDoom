{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the random numbers of the game }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.GameRandom;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf,
  DelphiDoom.Tests.MathCore.Golden;

type
  /// <summary>A source of unpredictable numbers that counts the calls and gives a fixed series</summary>
  TFakeEntropySource = class(TInterfacedObject, IEntropySource)
  public
    Calls: Integer;
    LastRange: Integer;
    function Next(ARange: Integer): Integer;
  end;

  /// <summary>
  ///   Parity with the old m_rnd (golden file random.golden.txt: the series of the tables, the
  ///   indexes, save and restore, the hitscan formulas) and the state held in the object
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreGameRandom = class(TObject)
  private
    FGolden: TGoldenFile;
    FEntropy: TFakeEntropySource;
    FEntropyIntf: IEntropySource;
    FRandom: IGameRandom;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLaSerieDelMenuCometMRandom;
    [Test]
    procedure DovrebbeDareLaSerieDelGiocoCometPRandom;
    [Test]
    procedure DovrebbeDareLaSerieNonCompatibileCometNRandom;
    [Test]
    procedure DovrebbeDareLaSerieDiSistemaCometSysRandomConDiversiSeme;
    [Test]
    procedure DovrebbeUsareUnIndiceDelChiamanteCometCRandom;
    [Test]
    procedure DovrebbeDareIlNumeroDiUnSemeCometPRandomFromSeed;
    [Test]
    procedure DovrebbeSalvareERipristinareLIndiceDiGioco;
    [Test]
    procedure DovrebbeCalcolareLAngoloDelColpoCometPRandomHitscanAngle;
    [Test]
    procedure DovrebbeCalcolareLaPendenzaDelColpoCometPRandomHitscanSlope;

    [Test]
    procedure DovrebbePartireDalSecondoNumeroDellaTabella;
    [Test]
    procedure DovrebbeTenereGliIndiciIndipendenti;
    [Test]
    procedure DovrebbeRiportareGliIndiciAZeroConClear;
    [Test]
    procedure DovrebbeDareFalsoSeNonCEUnIndiceSalvato;
    [Test]
    procedure DovrebbeSvuotareGliIndiciSalvatiConClear;
    [Test]
    procedure DovrebbeLasciarePassareGliIndiciDelSalvataggio;
    [Test]
    procedure DovrebbeChiedereLNumeroImprevedibileALLaFonte;
    [Test]
    procedure DovrebbeAvereDueOggettiConStatiSeparati;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLIndiceDiSistemaEsceDallaTabella;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Factory, DelphiDoom.Tests.MathCore.Fingerprint,
  DelphiDoom.Tests.MathCore.Samples;

{ TFakeEntropySource }

function TFakeEntropySource.Next(ARange: Integer): Integer;
begin
  Inc(Calls);
  LastRange := ARange;
  Result := 77;
end;

{ TTestMathCoreGameRandom }

procedure TTestMathCoreGameRandom.Setup;
begin
  FGolden := TGoldenFile.Create('random.golden.txt');
  FEntropy := TFakeEntropySource.Create;
  FEntropyIntf := FEntropy;
  FRandom := TMathCoreFactory.CreateGameRandom(FEntropyIntf);
end;

procedure TTestMathCoreGameRandom.TearDown;
begin
  FRandom := nil;
  FEntropyIntf := nil;
  FGolden.Free;
end;

procedure TTestMathCoreGameRandom.DovrebbeDareLaSerieDelMenuCometMRandom;
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 1 to 600 do
      LFingerprint.AddInteger(FRandom.NextMenu);
    LFingerprint.AddInteger(FRandom.MenuIndex);
    FGolden.Check('rnd.NextMenu', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeDareLaSerieDelGiocoCometPRandom;
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 1 to 600 do
      LFingerprint.AddInteger(FRandom.NextPlay);
    LFingerprint.AddInteger(FRandom.PlayIndex);
    FGolden.Check('rnd.NextPlay', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeDareLaSerieNonCompatibileCometNRandom;
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 1 to 600 do
      LFingerprint.AddInteger(FRandom.NextNonCompatible);
    LFingerprint.AddInteger(FRandom.NonCompatibleIndex);
    FGolden.Check('rnd.NextNonCompatible', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeDareLaSerieDiSistemaCometSysRandomConDiversiSeme;
const
  SEEDS: array[0..5] of Integer = (0, 7, 100, 5000, 10006, 1);
var
  LFingerprint: TFingerprint;
  LSeed, LIndex: Integer;
begin
  for LSeed := 0 to 5 do
  begin
    FRandom.Clear;
    FRandom.SystemSeed := SEEDS[LSeed];
    LFingerprint := TFingerprint.Create;
    try
      for LIndex := 1 to 20050 do
        LFingerprint.AddInteger(FRandom.NextSystem);
      LFingerprint.AddInteger(FRandom.SystemIndex);
      FGolden.Check('rnd.NextSystem.seed' + IntToStr(SEEDS[LSeed]), LFingerprint.ToHex);
    finally
      LFingerprint.Free;
    end;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeUsareUnIndiceDelChiamanteCometCRandom;
const
  STARTS: array[0..3] of Integer = (-3, 0, 250, 100000);
var
  LFingerprint: TFingerprint;
  LStart, LIndex, LCustom: Integer;
begin
  for LStart := 0 to 3 do
  begin
    LCustom := STARTS[LStart];
    LFingerprint := TFingerprint.Create;
    try
      for LIndex := 1 to 300 do
        LFingerprint.AddInteger(FRandom.NextWithIndex(LCustom));
      LFingerprint.AddInteger(LCustom);
      FGolden.Check('rnd.NextWithIndex.start' + IntToStr(STARTS[LStart]), LFingerprint.ToHex);
    finally
      LFingerprint.Free;
    end;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeDareIlNumeroDiUnSemeCometPRandomFromSeed;
var
  LFingerprint: TFingerprint;
  LSeed: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LSeed := -600 to 1000 do
      LFingerprint.AddInteger(FRandom.FromSeed(LSeed));
    FGolden.Check('rnd.FromSeed', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeSalvareERipristinareLIndiceDiGioco;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex, LDepth: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    LDepth := 0;
    for LIndex := 1 to 2000 do
      case TMathCoreSamples.NextRandom(LState) mod 4 of
        0:
          begin
            FRandom.SavePlayIndex;
            Inc(LDepth);
          end;
        1:
          if LDepth > 0 then
          begin
            Assert.IsTrue(FRandom.RestorePlayIndex);
            Dec(LDepth);
            LFingerprint.AddInteger(FRandom.PlayIndex);
          end;
      else
        LFingerprint.AddInteger(FRandom.NextPlay);
      end;
    FGolden.Check('rnd.SaveRestore', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeCalcolareLAngoloDelColpoCometPRandomHitscanAngle;
const
  SPREADS: array[0..8] of Integer = (0, 65536, 360448, 1966080, 2949120, 5898240, -655360, 11796480, 100000);
var
  LFingerprint: TFingerprint;
  LSpread, LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LSpread := 0 to 8 do
      for LIndex := 1 to 200 do
        LFingerprint.AddInteger(FRandom.HitscanAngle(SPREADS[LSpread]));
    LFingerprint.AddInteger(FRandom.NonCompatibleIndex);
    FGolden.Check('rnd.HitscanAngle', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbeCalcolareLaPendenzaDelColpoCometPRandomHitscanSlope;
const
  SPREADS: array[0..8] of Integer = (0, 65536, 360448, 1966080, 2949120, 5898240, -655360, 11796480, 100000);
var
  LFingerprint: TFingerprint;
  LSpread, LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LSpread := 0 to 8 do
      for LIndex := 1 to 200 do
        LFingerprint.AddInteger(FRandom.HitscanSlope(SPREADS[LSpread]));
    LFingerprint.AddInteger(FRandom.NonCompatibleIndex);
    FGolden.Check('rnd.HitscanSlope', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreGameRandom.DovrebbePartireDalSecondoNumeroDellaTabella;
begin
  // the index moves first: the first number is the one at index 1 (8), then 109
  Assert.AreEqual(8, FRandom.NextPlay);
  Assert.AreEqual(109, FRandom.NextPlay);
  Assert.AreEqual(8, FRandom.NextMenu);
end;

procedure TTestMathCoreGameRandom.DovrebbeTenereGliIndiciIndipendenti;
begin
  FRandom.NextPlay;
  FRandom.NextPlay;
  FRandom.NextMenu;
  Assert.AreEqual(2, FRandom.PlayIndex);
  Assert.AreEqual(1, FRandom.MenuIndex);
  Assert.AreEqual(0, FRandom.NonCompatibleIndex);
end;

procedure TTestMathCoreGameRandom.DovrebbeRiportareGliIndiciAZeroConClear;
begin
  FRandom.NextPlay;
  FRandom.NextMenu;
  FRandom.NextNonCompatible;
  FRandom.SystemSeed := 3;
  FRandom.NextSystem;
  FRandom.Clear;
  Assert.AreEqual(0, FRandom.PlayIndex);
  Assert.AreEqual(0, FRandom.MenuIndex);
  Assert.AreEqual(0, FRandom.NonCompatibleIndex);
  Assert.AreEqual(0, FRandom.SystemIndex);
  // as the old M_ClearRandom, the seed of the system random stays
  Assert.AreEqual(3, FRandom.SystemSeed);
end;

procedure TTestMathCoreGameRandom.DovrebbeDareFalsoSeNonCEUnIndiceSalvato;
begin
  FRandom.PlayIndex := 9;
  Assert.IsFalse(FRandom.RestorePlayIndex);
  Assert.AreEqual(9, FRandom.PlayIndex);
end;

procedure TTestMathCoreGameRandom.DovrebbeSvuotareGliIndiciSalvatiConClear;
begin
  FRandom.SavePlayIndex;
  FRandom.Clear;
  Assert.IsFalse(FRandom.RestorePlayIndex);
end;

procedure TTestMathCoreGameRandom.DovrebbeLasciarePassareGliIndiciDelSalvataggio;
begin
  FRandom.PlayIndex := 200;
  FRandom.SavePlayIndex;
  FRandom.PlayIndex := 5;
  Assert.IsTrue(FRandom.RestorePlayIndex);
  Assert.AreEqual(200, FRandom.PlayIndex);
end;

procedure TTestMathCoreGameRandom.DovrebbeChiedereLNumeroImprevedibileALLaFonte;
begin
  Assert.AreEqual(77, FRandom.NextUnpredictable);
  Assert.AreEqual(1, FEntropy.Calls);
  Assert.AreEqual(256, FEntropy.LastRange);
end;

procedure TTestMathCoreGameRandom.DovrebbeAvereDueOggettiConStatiSeparati;
var
  LOther: IGameRandom;
begin
  LOther := TMathCoreFactory.CreateGameRandom(FEntropyIntf);
  FRandom.NextPlay;
  FRandom.NextPlay;
  Assert.AreEqual(0, LOther.PlayIndex);
  Assert.AreEqual(8, LOther.NextPlay);
end;

procedure TTestMathCoreGameRandom.DovrebbeSollevareUnErroreSeLIndiceDiSistemaEsceDallaTabella;
begin
  FRandom.SystemSeed := -20;
  Assert.WillRaise(
    procedure
    begin
      FRandom.NextSystem;
    end, EMathCoreException);
end;

end.
