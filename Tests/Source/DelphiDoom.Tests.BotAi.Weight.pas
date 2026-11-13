{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the fuzzy weights of the bots (DUnitX)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Weight;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Table,
  DelphiDoom.BotAi.Weight.Config, DelphiDoom.BotAi.Weight.Intf, DelphiDoom.Tests.BotAi.Support;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotWeight = class
  strict private
    FImport: TFakeBotImport;
    FImportRef: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesRef: IBotFileSource;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IInterface;
    FCache: IBotWeightCache;
    function Config(const AText: AnsiString): TBotWeightConfig;
    function Printed: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrovareUnPesoPerNome;
    [Test]
    procedure DovrebbeDareIlPesoDelCasoCheContieneLInventario;
    [Test]
    procedure DovrebbeDareIlPesoDelCasoSuccessivoTraDueCasiPerLaDivisioneIntera;
    [Test]
    procedure DovrebbeAlzareUnErroreSeLIndiceDellInventarioNonEsiste;
    [Test]
    procedure DovrebbeAlzareUnErroreSeIlPesoNonEsiste;
    [Test]
    procedure DovrebbeDareUnValoreCasualeTraIlimitiDelBalance;
    [Test]
    procedure DovrebbeScalareIlBalanceEMantenerloTraILimiti;
    [Test]
    procedure DovrebbeScalareLIntervalloDelBalance;
    [Test]
    procedure DovrebbeEvolvereIPesiConIlGeneratoreIniettato;
    [Test]
    procedure DovrebbeAlzareIlMassimoSeLEvoluzioneLoSupera;
    [Test]
    procedure DovrebbeFareLaMediaDiDuePesiConInterbreed;
    [Test]
    procedure DovrebbeAlzareIlMassimoSeLaMediaLoSupera;
    [Test]
    procedure DovrebbeLeggereUnPesoNegativoSenzaIlSegno;
    [Test]
    procedure DovrebbeRitenereUnFileGiaLetto;
    [Test]
    procedure DovrebbeLeggereDiNuovoUnFileConBotReloadCharacters;
    [Test]
    procedure DovrebbeSegnalareLaCacheDeiFilePiena;
    [Test]
    procedure DovrebbeLiberareLeConfigurazioniConShutdown;
    [Test]
    procedure DovrebbeIgnorareLaLiberazioneDiUnaConfigurazioneNulla;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Random.MsvcRand,
  DelphiDoom.BotAi.Weight.Reader, DelphiDoom.BotAi.Weight.Evaluator, DelphiDoom.BotAi.Weight.Scaler,
  DelphiDoom.BotAi.Weight.Breeder, DelphiDoom.BotAi.Weight.Separator, DelphiDoom.BotAi.Weight.Factory;

const
  SWITCHES =
    'weight "a" { switch(1) { case 10: return 100; case 20: return 200; default: return 300; } } ' +
    'weight "b" return balance(5, 1, 9);';

{ TTestBotWeight }

procedure TTestBotWeight.Setup;
begin
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesRef := FFiles;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FCache := TBotWeightFactory.CreateWeightCache(FImport, FFiles, FLibVars);
end;

procedure TTestBotWeight.TearDown;
begin
  FCache := nil;
  FLibVarsRef := nil;
  FFilesRef := nil;
  FImportRef := nil;
end;

function TTestBotWeight.Config(const AText: AnsiString): TBotWeightConfig;
begin
  FFiles.Add('botfiles/w.c', AText);
  Result := FCache.ReadWeightConfig('w.c');
  Assert.IsNotNull(Result, FImport.Lines.Text);
end;

function TTestBotWeight.Printed: string;
begin
  Result := FImport.Lines.Text;
end;

procedure TTestBotWeight.DovrebbeTrovareUnPesoPerNome;
var
  LConfig: TBotWeightConfig;
begin
  LConfig := Config(SWITCHES);
  Assert.AreEqual(2, LConfig.Count);
  Assert.AreEqual(0, LConfig.FindFuzzyWeight('a'));
  Assert.AreEqual(1, LConfig.FindFuzzyWeight('b'));
  Assert.AreEqual(-1, LConfig.FindFuzzyWeight('A'));
  Assert.AreEqual('b', string(LConfig.Names[1]));
  Assert.WillRaise(
    procedure
    begin
      LConfig.Names[2];
    end,
    EBotAiException);
  Assert.WillRaise(
    procedure
    begin
      LConfig.FirstSeparator[-1];
    end,
    EBotAiException);
end;

procedure TTestBotWeight.DovrebbeDareIlPesoDelCasoCheContieneLInventario;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config(SWITCHES);
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    Assert.AreEqual(Double(100.0), Double(LEvaluator.FuzzyWeight([0, 5], LConfig, 0)));
    Assert.AreEqual(Double(300.0), Double(LEvaluator.FuzzyWeight([0, 25], LConfig, 0)));
    Assert.AreEqual(Double(5.0), Double(LEvaluator.FuzzyWeight([0, 0], LConfig, 1)));
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeDareIlPesoDelCasoSuccessivoTraDueCasiPerLaDivisioneIntera;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config(SWITCHES);
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    // 15 is between the cases 10 and 20: the scale is (15 - 10) div (20 - 10) = 0, so the weight is the next one
    Assert.AreEqual(Double(200.0), Double(LEvaluator.FuzzyWeight([0, 15], LConfig, 0)));
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeAlzareUnErroreSeLIndiceDellInventarioNonEsiste;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config(SWITCHES);
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    Assert.WillRaise(
      procedure
      begin
        LEvaluator.FuzzyWeight([1], LConfig, 0);
      end,
      EBotAiException);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeAlzareUnErroreSeIlPesoNonEsiste;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config(SWITCHES);
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    Assert.WillRaise(
      procedure
      begin
        LEvaluator.FuzzyWeight([0, 0], LConfig, 2);
      end,
      EBotAiException);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeDareUnValoreCasualeTraIlimitiDelBalance;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config(SWITCHES);
  LEvaluator := TBotFuzzyEvaluator.Create(TSequenceRandom.Create([0.0, 1.0, 0.5]));
  try
    Assert.AreEqual(Double(1.0), Double(LEvaluator.FuzzyWeightUndecided([0, 0], LConfig, 1)), 0.00001);
    Assert.AreEqual(Double(9.0), Double(LEvaluator.FuzzyWeightUndecided([0, 0], LConfig, 1)), 0.00001);
    Assert.AreEqual(Double(5.0), Double(LEvaluator.FuzzyWeightUndecided([0, 0], LConfig, 1)), 0.00001);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeScalareIlBalanceEMantenerloTraILimiti;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config(SWITCHES);
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    // weight = (max + min) * scale, between the bounds
    TBotWeightScaler.ScaleWeight(LConfig, 'b', 0.25);
    Assert.AreEqual(Double(2.5), Double(LEvaluator.FuzzyWeight([0, 0], LConfig, 1)), 0.00001);
    TBotWeightScaler.ScaleWeight(LConfig, 'b', 5);
    Assert.AreEqual(Double(9.0), Double(LEvaluator.FuzzyWeight([0, 0], LConfig, 1)), 0.00001);
    TBotWeightScaler.ScaleWeight(LConfig, 'b', -1);
    Assert.AreEqual(Double(1.0), Double(LEvaluator.FuzzyWeight([0, 0], LConfig, 1)), 0.00001);
    // a weight that does not exist or has no balance is left alone
    TBotWeightScaler.ScaleWeight(LConfig, 'nothing', 0.5);
    TBotWeightScaler.ScaleWeight(LConfig, 'a', 0.5);
    Assert.AreEqual(Double(100.0), Double(LEvaluator.FuzzyWeight([0, 5], LConfig, 0)));
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeScalareLIntervalloDelBalance;
var
  LConfig: TBotWeightConfig;
  LSeparator: TBotFuzzySeparator;
begin
  LConfig := Config(SWITCHES);
  LSeparator := LConfig.FirstSeparator[1];
  TBotWeightScaler.ScaleBalanceRange(LConfig, 0.5);
  Assert.AreEqual(Double(3.0), Double(LSeparator.MinWeight), 0.00001);
  Assert.AreEqual(Double(7.0), Double(LSeparator.MaxWeight), 0.00001);
  // the scale is limited to 100
  TBotWeightScaler.ScaleBalanceRange(LConfig, 1000);
  Assert.AreEqual(Double(-195.0), Double(LSeparator.MinWeight), 0.00001);
  TBotWeightScaler.ScaleBalanceRange(LConfig, -3);
  Assert.AreEqual(Double(5.0), Double(LSeparator.MinWeight), 0.00001);
  Assert.AreEqual(Double(5.0), Double(LSeparator.MaxWeight), 0.00001);
end;

procedure TTestBotWeight.DovrebbeEvolvereIPesiConIlGeneratoreIniettato;
var
  LConfig: TBotWeightConfig;
  LBreeder: TBotWeightBreeder;
  LSeparator: TBotFuzzySeparator;
begin
  LConfig := Config('weight "b" return balance(5, 1, 9);');
  LSeparator := LConfig.FirstSeparator[0];
  // random() = 0.5 is not a leap; crandom() = 2 * (0.5 - 0.5) = 0
  LBreeder := TBotWeightBreeder.Create(FImport, TSequenceRandom.Create([0.5]));
  try
    LBreeder.Evolve(LConfig);
    Assert.AreEqual(Double(5.0), Double(LSeparator.Weight), 0.00001);
  finally
    LBreeder.Free;
  end;
  // random() = 0 is a leap, then crandom() = 2 * (0 - 0.5) = -1: weight = 5 - 1 * 8
  LBreeder := TBotWeightBreeder.Create(FImport, TSequenceRandom.Create([0.0]));
  try
    LBreeder.Evolve(LConfig);
    Assert.AreEqual(Double(-3.0), Double(LSeparator.Weight), 0.00001);
    Assert.AreEqual(Double(-3.0), Double(LSeparator.MinWeight), 0.00001);
  finally
    LBreeder.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeAlzareIlMassimoSeLEvoluzioneLoSupera;
var
  LConfig: TBotWeightConfig;
  LBreeder: TBotWeightBreeder;
  LSeparator: TBotFuzzySeparator;
begin
  LConfig := Config('weight "b" return balance(5, 1, 9);');
  LSeparator := LConfig.FirstSeparator[0];
  // a leap (random() = 0) with crandom() = 2 * (1 - 0.5) = 1: weight = 5 + 1 * 8
  LBreeder := TBotWeightBreeder.Create(FImport, TSequenceRandom.Create([0.0, 1.0]));
  try
    LBreeder.Evolve(LConfig);
    Assert.AreEqual(Double(13.0), Double(LSeparator.Weight), 0.00001);
    Assert.AreEqual(Double(13.0), Double(LSeparator.MaxWeight), 0.00001);
  finally
    LBreeder.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeFareLaMediaDiDuePesiConInterbreed;
var
  LFirst: TBotWeightConfig;
  LSecond: TBotWeightConfig;
  LOutput: TBotWeightConfig;
  LBreeder: TBotWeightBreeder;
begin
  FLibVars.SetText('bot_reloadcharacters', '1');
  FFiles.Add('botfiles/a.c', 'weight "x" return balance(2, 0, 10);');
  FFiles.Add('botfiles/b.c', 'weight "x" return balance(6, 0, 10);');
  LFirst := FCache.ReadWeightConfig('a.c');
  LSecond := FCache.ReadWeightConfig('b.c');
  LOutput := FCache.ReadWeightConfig('a.c');
  LBreeder := TBotWeightBreeder.Create(FImport, nil);
  try
    LBreeder.Interbreed(LFirst, LSecond, LOutput);
    Assert.AreEqual(Double(4.0), Double(LOutput.FirstSeparator[0].Weight), 0.00001);
  finally
    LBreeder.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeAlzareIlMassimoSeLaMediaLoSupera;
var
  LFirst: TBotWeightConfig;
  LSecond: TBotWeightConfig;
  LOutput: TBotWeightConfig;
  LBreeder: TBotWeightBreeder;
begin
  FLibVars.SetText('bot_reloadcharacters', '1');
  FFiles.Add('botfiles/a.c', 'weight "x" return balance(20, 0, 10);');
  FFiles.Add('botfiles/b.c', 'weight "x" return balance(40, 0, 10);');
  LFirst := FCache.ReadWeightConfig('a.c');
  LSecond := FCache.ReadWeightConfig('b.c');
  LOutput := FCache.ReadWeightConfig('a.c');
  LBreeder := TBotWeightBreeder.Create(FImport, nil);
  try
    LBreeder.Interbreed(LFirst, LSecond, LOutput);
    Assert.AreEqual(Double(30.0), Double(LOutput.FirstSeparator[0].MaxWeight), 0.00001);
    // the minimum is raised with the same test as the maximum
    Assert.AreEqual(Double(30.0), Double(LOutput.FirstSeparator[0].MinWeight), 0.00001);
  finally
    LBreeder.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeLeggereUnPesoNegativoSenzaIlSegno;
var
  LConfig: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
begin
  LConfig := Config('weight "n" return -5;');
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    Assert.AreEqual(Double(5.0), Double(LEvaluator.FuzzyWeight([0], LConfig, 0)));
    Assert.Contains(Printed, 'negative value set to zero');
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestBotWeight.DovrebbeRitenereUnFileGiaLetto;
var
  LFirst: TBotWeightConfig;
begin
  FFiles.Add('botfiles/w.c', 'weight "x" return 1;');
  LFirst := FCache.ReadWeightConfig('w.c');
  Assert.AreSame(LFirst, FCache.ReadWeightConfig('w.c'));
  // freeing does nothing without bot_reloadcharacters
  FCache.FreeWeightConfig(LFirst);
  Assert.AreSame(LFirst, FCache.ReadWeightConfig('w.c'));
end;

procedure TTestBotWeight.DovrebbeLeggereDiNuovoUnFileConBotReloadCharacters;
var
  LFirst: TBotWeightConfig;
  LSecond: TBotWeightConfig;
begin
  FLibVars.SetText('bot_reloadcharacters', '1');
  FFiles.Add('botfiles/w.c', 'weight "x" return 1;');
  LFirst := FCache.ReadWeightConfig('w.c');
  LSecond := FCache.ReadWeightConfig('w.c');
  Assert.AreNotSame(LFirst, LSecond);
  FCache.FreeWeightConfig(LFirst);
  FCache.FreeWeightConfig(LSecond);
end;

procedure TTestBotWeight.DovrebbeSegnalareLaCacheDeiFilePiena;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 128 do
    FFiles.Add(Format('botfiles/f%d.c', [LIndex]), 'weight "x" return 1;');
  for LIndex := 0 to 127 do
    Assert.IsNotNull(FCache.ReadWeightConfig(AnsiString(Format('f%d.c', [LIndex]))));
  FImport.Lines.Clear;
  Assert.IsNull(FCache.ReadWeightConfig('f128.c'));
  Assert.Contains(Printed, 'weightFileList was full trying to load f128.c');
end;

procedure TTestBotWeight.DovrebbeLiberareLeConfigurazioniConShutdown;
begin
  FFiles.Add('botfiles/w.c', 'weight "x" return 1;');
  FCache.ReadWeightConfig('w.c');
  FCache.Shutdown;
  // a new reading makes a new configuration
  Assert.IsNotNull(FCache.ReadWeightConfig('w.c'));
end;

procedure TTestBotWeight.DovrebbeIgnorareLaLiberazioneDiUnaConfigurazioneNulla;
begin
  FLibVars.SetText('bot_reloadcharacters', '1');
  FCache.FreeWeightConfig(nil);
  Assert.Pass;
end;

end.
