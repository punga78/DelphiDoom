{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the commands, of the spells }
{  and of the whole tic with the C of the remake                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.FullParity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.RealData,
  DelphiDoom.Tests.War.FullScenario;

type
  /// <summary>
  ///   The golden files model.commands, model.spells and model.full of Tests\Data\War are the output of
  ///   `war_model_ref commands|spells|full 12` (Tools\Verifica\194, the C of the remake as a unity build): one
  ///   fingerprint of the whole state for each tic of twelve scenarios of 900 tics. Zero differences is the only result
  ///   accepted
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarFullParity = class(TObject)
  private
    function Golden(const AName: string): TStringList;
    procedure CompareScenarios(AMode: TFullMode; const AGolden: string);
    procedure CompareDump(AMode: TFullMode; ASeed: Cardinal; ATic: Integer; const AGolden: string);
  public
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicNegliScenariDeiComandi;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicNegliScenariDegliIncantesimi;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicNegliScenariDelTicIntero;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDeiComandi;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDegliIncantesimi;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDelTicIntero;
    [Test]
    procedure DovrebbeRaggiungereGliStatiELeEntitaDegliIncantesimiNegliScenari;
    [Test]
    procedure DovrebbeFarConvivereRaccoltaCombattimentoCostruzioneEIncantesimiNelTicIntero;
    [Test]
    procedure DovrebbeScrivereLeRigheELoStatoSeRichiesto;
  end;

implementation

uses
  DelphiDoom.War.Model.Types;

const
  SCENARIOS = 12;

{ TTestWarFullParity }

function TTestWarFullParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarFullParity.CompareScenarios(AMode: TFullMode; const AGolden: string);
var
  LExpected: TStringList;
  LActual: TStringList;
  LSeed: Cardinal;
  LIndex: Integer;
  LDump: string;
begin
  LExpected := Golden(AGolden);
  LActual := TStringList.Create;
  try
    for LSeed := 1 to SCENARIOS do
      TFullScenario.Run(AMode, LSeed, -1, LActual, LDump);
    Assert.AreEqual(SCENARIOS * FULL_SCENARIO_TICS, LExpected.Count, 'righe del golden');
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

procedure TTestWarFullParity.CompareDump(AMode: TFullMode; ASeed: Cardinal; ATic: Integer; const AGolden: string);
var
  LExpected: TStringList;
  LActual: TStringList;
  LDump: string;
  LIndex: Integer;
begin
  LExpected := Golden(AGolden);
  LActual := TStringList.Create;
  try
    TFullScenario.Run(AMode, ASeed, ATic, nil, LDump);
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

procedure TTestWarFullParity.DovrebbeDareLeStesseImprontePerTicNegliScenariDeiComandi;
begin
  CompareScenarios(fmCommands, 'model.commands.golden.txt');
end;

procedure TTestWarFullParity.DovrebbeDareLeStesseImprontePerTicNegliScenariDegliIncantesimi;
begin
  CompareScenarios(fmSpells, 'model.spells.golden.txt');
end;

procedure TTestWarFullParity.DovrebbeDareLeStesseImprontePerTicNegliScenariDelTicIntero;
begin
  CompareScenarios(fmFull, 'model.full.golden.txt');
end;

procedure TTestWarFullParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDeiComandi;
begin
  CompareDump(fmCommands, 6, 450, 'model.commands.dump.golden.txt');
end;

procedure TTestWarFullParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDegliIncantesimi;
begin
  CompareDump(fmSpells, 3, 450, 'model.spells.dump.golden.txt');
end;

procedure TTestWarFullParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDelTicIntero;
begin
  CompareDump(fmFull, 11, 450, 'model.full.dump.golden.txt');
end;

procedure TTestWarFullParity.DovrebbeRaggiungereGliStatiELeEntitaDegliIncantesimiNegliScenari;
var
  LSeed: Cardinal;
  LStates: TArray<Integer>;
  LEntities: TArray<Integer>;
  LCast: Integer;
  LClouds: Integer;
  LSights: Integer;
  LAnimations: Integer;
  LProjectiles: Integer;
begin
  LCast := 0;
  LClouds := 0;
  LSights := 0;
  LAnimations := 0;
  LProjectiles := 0;
  for LSeed := 1 to SCENARIOS do
  begin
    TFullScenario.Coverage(fmSpells, LSeed, LStates, LEntities);
    Inc(LCast, LStates[WAR_STATE_CAST]);
    Inc(LClouds, LEntities[WAR_ENTITY_POISON_CLOUD]);
    Inc(LSights, LEntities[WAR_ENTITY_SIGHT]);
    Inc(LAnimations, LEntities[WAR_ENTITY_ANIMATION]);
    Inc(LProjectiles, LEntities[WAR_ENTITY_PROJECTILE]);
  end;
  Assert.IsTrue(LCast > 1000, 'tic con uno stato di incantesimo');
  Assert.IsTrue(LClouds > 100, 'tic con una nube velenosa');
  Assert.IsTrue(LSights > 100, 'tic con una vista');
  Assert.IsTrue(LAnimations > 1000, 'tic con una animazione');
  Assert.IsTrue(LProjectiles > 100, 'tic con un proiettile');
end;

procedure TTestWarFullParity.DovrebbeFarConvivereRaccoltaCombattimentoCostruzioneEIncantesimiNelTicIntero;
var
  LSeed: Cardinal;
  LStates: TArray<Integer>;
  LEntities: TArray<Integer>;
  LTotals: array[0..WAR_STATE_COUNT - 1] of Integer;
  LType: Integer;
begin
  for LType := 0 to High(LTotals) do
    LTotals[LType] := 0;
  for LSeed := 1 to SCENARIOS do
  begin
    TFullScenario.Coverage(fmFull, LSeed, LStates, LEntities);
    for LType := 0 to High(LTotals) do
      Inc(LTotals[LType], LStates[LType]);
  end;
  // every type of state but the patrol (the original has no patrol command) and the wait (only an attack on a worker
  // that is inside a building pushes it)
  for LType := 0 to WAR_STATE_COUNT - 1 do
    if (LType <> WAR_STATE_PATROL) and (LType <> WAR_STATE_WAIT) then
      Assert.IsTrue(LTotals[LType] > 0, Format('stato %d mai raggiunto', [LType]));
end;

procedure TTestWarFullParity.DovrebbeScrivereLeRigheELoStatoSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LLines: TStringList;
  LDump: string;
  LMode: TFullMode;
begin
  // DELPHIDOOM_WAR_FULL_DUMP=modo(0..2),seme,tic,file: with tic -1 the lines of the scenario, otherwise the text of the state
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_FULL_DUMP');
  if LRequest = '' then
  begin
    Assert.Pass('DELPHIDOOM_WAR_FULL_DUMP non impostata');
    Exit;
  end;
  LParts := LRequest.Split([',']);
  Assert.AreEqual<Integer>(4, Length(LParts), 'modo,seme,tic,file');
  LMode := TFullMode(StrToInt(LParts[0]));
  LLines := TStringList.Create;
  try
    TFullScenario.Run(LMode, Cardinal(StrToInt(LParts[1])), StrToInt(LParts[2]), LLines, LDump);
    if StrToInt(LParts[2]) >= 0 then
      TFile.WriteAllText(LParts[3], LDump)
    else
      LLines.SaveToFile(LParts[3]);
  finally
    LLines.Free;
  end;
  Assert.Pass('scritto ' + LParts[3]);
end;

end.
