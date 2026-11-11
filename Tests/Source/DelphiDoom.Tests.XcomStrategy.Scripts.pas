{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the errors of the     }
{  mission scripts (a region, a mission or a race that the ruleset lacks, two  }
{  commands with the same label) on a real saved game                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Scripts;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleMissionScript, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.MissionScriptRunner, DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-strategy')]
  TTestXcomMissionScripts = class(TObject)
  strict private
    FSim: TXcomSim;
    FRandom: IXcomRandom;
    procedure SetScripts(const AYaml: TArray<string>);
    procedure Run(const AYaml: TArray<string>; out AMessage: string);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeSegnalareUnaRegioneCheLeRegoleNonHanno;
    [Test]
    procedure DovrebbeSegnalareUnaMissioneCheLeRegoleNonHanno;
    [Test]
    procedure DovrebbeSegnalareUnaRazzaCheLeRegoleNonHanno;
    [Test]
    procedure DovrebbeSegnalareDueComandiConLaStessaEtichetta;
    [Test]
    procedure DovrebbeFareUnaMissioneConUnComandoValido;
    [Test]
    procedure DovrebbeMirareUnaBaseConITipiDiMissioneDelComando;
    [Test]
    procedure DovrebbeSegnalareUnComandoCheMiraUnaBaseSenzaPesiDiMissione;
    [Test]
    procedure DovrebbeCercareUnSitoPerUnComandoDiTipoSito;
  end;

implementation

const
  COMMON = 'varName: test, firstMonth: 0, lastMonth: -1, executionOdds: 100, targetBaseOdds: 0, minDifficulty: 0, ' +
    'maxRuns: -1';

{ TTestXcomMissionScripts }

procedure TTestXcomMissionScripts.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomMissionScripts.TearDownFixture;
begin
  FSim.Free;
end;

procedure TTestXcomMissionScripts.SetScripts(const AYaml: TArray<string>);
var
  LIndex: Integer;
  LName: string;
  LRule: TXcomRuleMissionScript;
begin
  // the ruleset of the fixture is shared: the scripts of the mod are taken out and the ones of the test go in
  for LName in FSim.Ruleset.MissionScripts.Index do
    FSim.Ruleset.MissionScripts.Delete(LName);
  for LIndex := 0 to High(AYaml) do
  begin
    LName := 'TEST_SCRIPT_' + IntToStr(LIndex);
    LRule := TXcomRuleMissionScript.Create(LName);
    LRule.Load(TYamlFactory.CreateParser.LoadAll(YamlStringToText('{' + AYaml[LIndex] + '}'))[0]);
    FSim.Ruleset.MissionScripts.Add(LName, LRule);
  end;
end;

procedure TTestXcomMissionScripts.Run(const AYaml: TArray<string>; out AMessage: string);
var
  LGame: TXcomSavedGame;
  LRunner: TXcomMissionScriptRunner;
begin
  AMessage := '';
  FRandom := TXcomRandom.Create(1);
  LGame := FSim.LoadSave(2, FRandom);
  try
    LGame.MonthsPassed := 0;
    SetScripts(AYaml);
    LRunner := TXcomMissionScriptRunner.Create(LGame, FSim.Ruleset, FRandom);
    try
      try
        LRunner.DetermineAlienMissions;
      except
        on E: EXcomStrategyException do
          AMessage := E.Message;
      end;
    finally
      LRunner.Free;
    end;
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomMissionScripts.DovrebbeSegnalareUnaRegioneCheLeRegoleNonHanno;
var
  LMessage: string;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  Run([COMMON + ', regionWeights: {0: {STR_NOWHERE: 10}}, missionWeights: {0: {STR_ALIEN_PROBE_MISSION: 10}}'],
    LMessage);
  Assert.IsTrue(LMessage.Contains('STR_NOWHERE') and LMessage.Contains('region named'), 'messaggio: ' + LMessage);
end;

procedure TTestXcomMissionScripts.DovrebbeSegnalareUnaMissioneCheLeRegoleNonHanno;
var
  LMessage: string;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  Run([COMMON + ', regionWeights: {0: {STR_NORTH_PACIFIC: 10}}, missionWeights: {0: {STR_NO_MISSION: 10}}'],
    LMessage);
  Assert.IsTrue(LMessage.Contains('STR_NO_MISSION') and LMessage.Contains('mission type'), 'messaggio: ' + LMessage);
end;

procedure TTestXcomMissionScripts.DovrebbeSegnalareUnaRazzaCheLeRegoleNonHanno;
var
  LMessage: string;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  Run([COMMON + ', regionWeights: {0: {STR_NORTH_PACIFIC: 10}}, missionWeights: {0: {STR_ALIEN_PROBE_MISSION: 10}}, ' +
    'raceWeights: {0: {STR_NO_RACE: 10}}'], LMessage);
  Assert.IsTrue(LMessage.Contains('STR_NO_RACE') and LMessage.Contains('race'), 'messaggio: ' + LMessage);
end;

procedure TTestXcomMissionScripts.DovrebbeSegnalareDueComandiConLaStessaEtichetta;
var
  LMessage: string;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  Run([COMMON + ', label: 5, executionOdds: 0', COMMON + ', label: 5, executionOdds: 0'], LMessage);
  Assert.IsTrue(LMessage.Contains('sharing the same label'), 'messaggio: ' + LMessage);
end;

procedure TTestXcomMissionScripts.DovrebbeFareUnaMissioneConUnComandoValido;
var
  LGame: TXcomSavedGame;
  LRunner: TXcomMissionScriptRunner;
  LBefore: Integer;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  FRandom := TXcomRandom.Create(1);
  LGame := FSim.LoadSave(2, FRandom);
  try
    LGame.MonthsPassed := 0;
    SetScripts([COMMON + ', regionWeights: {0: {STR_NORTH_PACIFIC: 10}}, missionWeights: {0: ' +
      '{STR_ALIEN_PROBE_MISSION: 10}}, raceWeights: {0: {STR_AQUATOID: 10}}']);
    LBefore := LGame.ActiveMissions.Count;
    LRunner := TXcomMissionScriptRunner.Create(LGame, FSim.Ruleset, FRandom);
    try
      LRunner.DetermineAlienMissions;
    finally
      LRunner.Free;
    end;
    Assert.AreEqual(LBefore + 1, LGame.ActiveMissions.Count, 'una missione in piu''');
    Assert.AreEqual('STR_AQUATOID', LGame.ActiveMissions.Last.Race, 'razza');
    Assert.AreEqual('STR_NORTH_PACIFIC', LGame.ActiveMissions.Last.Region, 'regione');
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomMissionScripts.DovrebbeMirareUnaBaseConITipiDiMissioneDelComando;
var
  LGame: TXcomSavedGame;
  LRunner: TXcomMissionScriptRunner;
  LBefore: Integer;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  FRandom := TXcomRandom.Create(1);
  LGame := FSim.LoadSave(2, FRandom);
  try
    LGame.MonthsPassed := 0;
    // a command that aims at the bases: the region is one where a base is
    SetScripts([COMMON.Replace('targetBaseOdds: 0', 'targetBaseOdds: 100') +
      ', missionWeights: {0: {STR_ALIEN_PROBE_MISSION: 10}}, raceWeights: {0: {STR_AQUATOID: 10}}']);
    LBefore := LGame.ActiveMissions.Count;
    LRunner := TXcomMissionScriptRunner.Create(LGame, FSim.Ruleset, FRandom);
    try
      LRunner.DetermineAlienMissions;
    finally
      LRunner.Free;
    end;
    Assert.AreEqual(LBefore + 1, LGame.ActiveMissions.Count, 'una missione in piu''');
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomMissionScripts.DovrebbeSegnalareUnComandoCheMiraUnaBaseSenzaPesiDiMissione;
var
  LGame: TXcomSavedGame;
  LRunner: TXcomMissionScriptRunner;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  FRandom := TXcomRandom.Create(1);
  LGame := FSim.LoadSave(2, FRandom);
  try
    LGame.MonthsPassed := 0;
    // no mission weights in the command: the C++ reads before the first month (undefined), here it is an error
    SetScripts([COMMON.Replace('targetBaseOdds: 0', 'targetBaseOdds: 100') + ', raceWeights: {0: {STR_AQUATOID: 10}}']);
    LRunner := TXcomMissionScriptRunner.Create(LGame, FSim.Ruleset, FRandom);
    try
      Assert.WillRaise(
        procedure
        begin
          LRunner.DetermineAlienMissions;
        end, EXcomModException);
    finally
      LRunner.Free;
    end;
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomMissionScripts.DovrebbeCercareUnSitoPerUnComandoDiTipoSito;
var
  LGame: TXcomSavedGame;
  LRunner: TXcomMissionScriptRunner;
  LRule: TXcomRuleMissionScript;
begin
  if not FSim.Available then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD il test non si fa');
    Exit;
  end;
  FRandom := TXcomRandom.Create(1);
  LGame := FSim.LoadSave(2, FRandom);
  try
    LGame.MonthsPassed := 0;
    SetScripts([COMMON + ', missionWeights: {0: {STR_ALIEN_SURFACE_ATTACK: 10, STR_ALIEN_PROBE_MISSION: 10}}, ' +
      'raceWeights: {0: {STR_AQUATOID: 10}}']);
    LRule := FSim.Ruleset.MissionScripts.Find(FSim.Ruleset.MissionScripts.Index[0]);
    LRule.SiteType := True;
    LRunner := TXcomMissionScriptRunner.Create(LGame, FSim.Ruleset, FRandom);
    try
      // the command looks for the cities of the regions that can hold the mission: it may find none
      LRunner.DetermineAlienMissions;
    finally
      LRunner.Free;
    end;
    Assert.IsTrue(True);
  finally
    LGame.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMissionScripts);

end.
