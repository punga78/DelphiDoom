{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the computer player (AI)    }
{  with the C of the remake                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AiParity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.RealData,
  DelphiDoom.Tests.War.FullScenario;

type
  /// <summary>
  ///   The golden files ai.* of Tests\Data\War are the output of `war_model_ref ai-tables`, `ai 8` and `dump ai SEED TIC`
  ///   (Tools\Verifica\194, group "196 ia": war_ai.c of the remake whole, in the unity build, over the world of the full
  ///   scenarios): the script and the producers, and one fingerprint of the whole state for each tic of eight scenarios
  ///   of 3000 tics in which the player 1 is the computer. Zero differences is the only result accepted
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarAiParity = class(TObject)
  private
    function Golden(const AName: string): TStringList;
    procedure CompareDump(ASeed: Cardinal; ATic: Integer; const AGolden: string);
  public
    [Test]
    procedure DovrebbeDareLeStesseTabelleDelC;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicNegliOttoScenariDellIa;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAMetaDiUnoScenarioDellIa;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAllaFineDiUnoScenarioDellIa;
    [Test]
    procedure DovrebbeFarLavorareLIaNegliScenari;
    [Test]
    procedure DovrebbeScrivereLeRigheDellIaSeRichiesto;
    [Test]
    procedure DovrebbeMisurareIlCostoPerTicDellIaSeRichiesto;
  end;

implementation

uses
  System.Diagnostics, DelphiDoom.War.Level.Types, DelphiDoom.War.Ai.Types, DelphiDoom.War.Ai.Tables.Data,
  DelphiDoom.War.Ai.Players, DelphiDoom.War.Model.UnitProducers, DelphiDoom.War.Model.Factory,
  DelphiDoom.Tests.War.ModelRig;

const
  SCENARIOS = 8;

{ TTestWarAiParity }

function TTestWarAiParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarAiParity.CompareDump(ASeed: Cardinal; ATic: Integer; const AGolden: string);
var
  LExpected: TStringList;
  LActual: TStringList;
  LDump: string;
  LIndex: Integer;
begin
  LExpected := Golden(AGolden);
  LActual := TStringList.Create;
  try
    TFullScenario.Run(fmAi, ASeed, ATic, nil, LDump);
    LActual.Text := LDump;
    Assert.IsTrue(LExpected.Count > 50, 'il golden ha il testo dello stato');
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      Assert.IsTrue(LIndex < LActual.Count, 'Il modello ha meno righe del C: ' + LExpected[LIndex]);
      Assert.AreEqual(LExpected[LIndex], LActual[LIndex], Format('riga %d', [LIndex + 1]));
    end;
    Assert.AreEqual(LExpected.Count, LActual.Count, 'righe');
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarAiParity.DovrebbeDareLeStesseTabelleDelC;
var
  LExpected: TStringList;
  LParts: TArray<string>;
  LLine: string;
  LRace: Integer;
  LEntry: TWarAiScriptEntry;
  LProducers: Integer;
  LScript: Integer;
begin
  LExpected := Golden('ai.tables.golden.txt');
  try
    LProducers := 0;
    LScript := 0;
    for LLine in LExpected do
    begin
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      LParts := LLine.Split([' ']);
      if LParts[0] = 'E' then
      begin
        Assert.AreEqual(WAR_AI_COMMAND_REQUEST, StrToInt(LParts[1]), 'REQUEST');
        Assert.AreEqual(WAR_AI_COMMAND_WAIT, StrToInt(LParts[2]), 'WAIT');
        Assert.AreEqual(WAR_AI_COMMAND_ATTACK, StrToInt(LParts[3]), 'ATTACK');
        Assert.AreEqual(WAR_AI_COMMAND_DEFEND, StrToInt(LParts[4]), 'DEFEND');
        Assert.AreEqual(WAR_AI_COMMAND_SLEEP, StrToInt(LParts[5]), 'SLEEP');
        Assert.AreEqual(WAR_AI_COMMAND_COUNT, StrToInt(LParts[6]), 'COUNT');
      end
      else if LParts[0] = 'Z' then
      begin
        Assert.AreEqual(WAR_AI_STATUS_CREATED, StrToInt(LParts[1]), 'CREATED');
        Assert.AreEqual(WAR_AI_STATUS_STARTED, StrToInt(LParts[2]), 'STARTED');
        Assert.AreEqual(WAR_AI_STATUS_COMPLETED, StrToInt(LParts[3]), 'COMPLETED');
      end
      else if LParts[0] = 'P' then
      begin
        Assert.AreEqual(StrToInt(LParts[2]), TWarUnitProducers.ProducerOf(StrToInt(LParts[1])),
          'produttore di ' + LParts[1]);
        Assert.AreEqual(StrToInt(LParts[3]) <> 0, TWarUnitProducers.IsValidType(StrToInt(LParts[2])),
          'valido ' + LParts[2]);
        Inc(LProducers);
      end
      else if LParts[0] = 'S' then
      begin
        LRace := StrToInt(LParts[1]);
        LEntry := WAR_AI_SCRIPT[LRace, StrToInt(LParts[2])];
        Assert.AreEqual(StrToInt(LParts[3]), LEntry.Kind, 'tipo di comando ' + LLine);
        Assert.AreEqual(StrToInt(LParts[4]), LEntry.UnitType, 'unita ' + LLine);
        Assert.AreEqual(StrToInt(LParts[5]), LEntry.Count, 'quantita ' + LLine);
        Inc(LScript);
      end;
    end;
    Assert.AreEqual<Integer>(WAR_UNIT_COUNT, LProducers, 'un produttore per tipo');
    Assert.AreEqual<Integer>(3 * WAR_AI_SCRIPT_LENGTH, LScript, 'il copione di tre razze');
  finally
    LExpected.Free;
  end;
end;

procedure TTestWarAiParity.DovrebbeDareLeStesseImprontePerTicNegliOttoScenariDellIa;
var
  LExpected: TStringList;
  LActual: TStringList;
  LSeed: Cardinal;
  LIndex: Integer;
  LDump: string;
begin
  LExpected := Golden('ai.scenarios.golden.txt');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to SCENARIOS do
      TFullScenario.Run(fmAi, LSeed, -1, LActual, LDump);
    Assert.AreEqual(SCENARIOS * AI_SCENARIO_TICS, LExpected.Count, 'righe del golden');
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      Assert.IsTrue(LIndex < LActual.Count, 'Il modello ha meno righe del C: ' + LExpected[LIndex]);
      if LExpected[LIndex] <> LActual[LIndex] then
        Assert.AreEqual(LExpected[LIndex], LActual[LIndex], Format('riga %d', [LIndex + 1]));
    end;
    Assert.AreEqual(LExpected.Count, LActual.Count, 'righe');
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarAiParity.DovrebbeDareLoStessoTestoDelloStatoAMetaDiUnoScenarioDellIa;
begin
  CompareDump(5, 1200, 'ai.dump.golden.txt');
end;

procedure TTestWarAiParity.DovrebbeDareLoStessoTestoDelloStatoAllaFineDiUnoScenarioDellIa;
begin
  CompareDump(6, 2999, 'ai.dump2.golden.txt');
end;

procedure TTestWarAiParity.DovrebbeFarLavorareLIaNegliScenari;
var
  LSeed: Cardinal;
  LLastId: Cardinal;
  LIndex: Integer;
  LProgressCalls: Integer;
  LSleepTics: Integer;
  LTotalProgress: Integer;
  LTotalSleep: Integer;
  LFinished: Integer;
  LMaxId: Cardinal;
begin
  LTotalProgress := 0;
  LTotalSleep := 0;
  LFinished := 0;
  LMaxId := 0;
  for LSeed := 1 to SCENARIOS do
  begin
    TFullScenario.AiCoverage(LSeed, LLastId, LIndex, LProgressCalls, LSleepTics);
    Inc(LTotalProgress, LProgressCalls);
    Inc(LTotalSleep, LSleepTics);
    if LIndex = WAR_AI_SCRIPT_LENGTH then
      Inc(LFinished);
    if LLastId > LMaxId then
      LMaxId := LLastId;
  end;
  // the requests of units reach the training states, some scripts end and the AI sleeps (a pause is a command with an id)
  // (the training holds the request only until it is paid: the tic in which it enters its state)
  Assert.IsTrue(LTotalProgress > 8, 'volte che un addestramento ha contato una richiesta');
  Assert.IsTrue(LTotalSleep > 1000, 'tic con una pausa');
  Assert.AreEqual(SCENARIOS, LFinished, 'scenari in cui il copione arriva alla fine');
  Assert.IsTrue(LMaxId > 40, 'molte pause');
end;

procedure TTestWarAiParity.DovrebbeScrivereLeRigheDellIaSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LLines: TStringList;
  LDump: string;
begin
  // DELPHIDOOM_WAR_AI_DUMP=seme,tic,file: with tic -1 the lines of the scenario, otherwise the text of the state
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_AI_DUMP');
  if LRequest = '' then
  begin
    Assert.Pass('DELPHIDOOM_WAR_AI_DUMP non impostata');
    Exit;
  end;
  LParts := LRequest.Split([',']);
  Assert.AreEqual<Integer>(3, Length(LParts), 'seme,tic,file');
  LLines := TStringList.Create;
  try
    TFullScenario.Run(fmAi, Cardinal(StrToInt(LParts[0])), StrToInt(LParts[1]), LLines, LDump);
    if StrToInt(LParts[1]) >= 0 then
      TFile.WriteAllText(LParts[2], LDump)
    else
      LLines.SaveToFile(LParts[2]);
  finally
    LLines.Free;
  end;
  Assert.Pass('scritto ' + LParts[2]);
end;

procedure TTestWarAiParity.DovrebbeMisurareIlCostoPerTicDellIaSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LRig: TModelRig;
  LPlayers: TWarComputerPlayers;
  LTics: Integer;
  LTic: Integer;
  LIndex: Integer;
  LStart: Int64;
  LStop: Int64;
  LTotal: Int64;
  LOverhead: Int64;
  LMicroseconds: Double;
  LLine: string;
begin
  // DELPHIDOOM_WAR_BENCH_AI=tic,file: the same world as `war_model_ref benchai` (four town halls and two farms of the
  // player 1, always full purses, the real time at ten times the game's): microseconds per tic of the update of the
  // computer players alone (the counter's own cost taken off)
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_BENCH_AI');
  if LRequest = '' then
  begin
    Assert.Pass('DELPHIDOOM_WAR_BENCH_AI non impostata');
    Exit;
  end;
  LParts := LRequest.Split([',']);
  Assert.AreEqual<Integer>(2, Length(LParts), 'tic,file');
  LTics := StrToInt(LParts[0]);
  LRig := TModelRig.Create(777);
  try
    for LIndex := 0 to 3 do
      LRig.AddBuilding(WAR_UNIT_TOWNHALL_ORCS, 4 + 6 * LIndex, 4, 1);
    for LIndex := 0 to 1 do
      LRig.AddBuilding(WAR_UNIT_FARM_ORCS, 4 + 3 * LIndex, 20, 1);
    LRig.World.Context.RealTime := 0;
    LPlayers := TWarModelFactory.AttachComputerPlayers(LRig.World, [1]);
    LOverhead := 0;
    for LIndex := 1 to 100000 do
    begin
      LStart := TStopwatch.GetTimestamp;
      LStop := TStopwatch.GetTimestamp;
      Inc(LOverhead, LStop - LStart);
    end;
    LTotal := 0;
    for LTic := 1 to LTics do
    begin
      LRig.World.AdvanceClock(TIC_LENGTH);
      LRig.World.Context.RealTime := LRig.World.Context.RealTime + Double(TIC_LENGTH) * 10.0;
      LRig.World.Context.Players[1]^.Gold := 5000;
      LRig.World.Context.Players[1]^.Wood := 5000;
      LStart := TStopwatch.GetTimestamp;
      LPlayers.UpdateComputerPlayers;
      LStop := TStopwatch.GetTimestamp;
      Inc(LTotal, LStop - LStart);
      LRig.World.Machine.ProcessPendingTransitions;
      LRig.World.Machine.UpdateStates;
    end;
  finally
    LRig.Free;
  end;
  LMicroseconds := 1E6 * (LTotal - LOverhead / 100000.0 * LTics) / TStopwatch.Frequency / LTics;
  LLine := Format('Delphi %d bit, %d tic, 1 giocatore IA (us per tic, solo l''aggiornamento dell''IA, tolto il contatore): %.4f',
    [SizeOf(Pointer) * 8, LTics, LMicroseconds], TFormatSettings.Invariant);
  TFile.WriteAllText(LParts[1], LLine + sLineBreak);
  Assert.Pass(LLine);
end;

end.
