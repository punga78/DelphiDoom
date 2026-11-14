{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the path finding and of    }
{  the avoidance with the C of the remake                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PathParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.War.RealData,
  DelphiDoom.Tests.War.PathScenario, DelphiDoom.Tests.War.MoveScenario, DelphiDoom.Tests.War.CombatScenario,
  DelphiDoom.Tests.War.FullScenario, DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Factory,
  DelphiDoom.War.Level.MapReader;

type
  /// <summary>
  ///   The golden files path.paths and path.rvo of Tests\Data\War are the output of `war_model_ref paths 36` and
  ///   `war_model_ref rvo 20` (Tools\Verifica\194, group 195 of Tools\Verifica\201): the functions wpath_astar,
  ///   wpath_computeFlowField, wpath_flowFieldSample and wrvo_computeNewVelocity of the remake, compiled as they are
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarPathParity = class(TObject)
  private
    function Golden(const AName: string; const APrefixes: string): TStringList;
    function Actual(AMode: Integer; const APrefixes: string): TStringList;
    procedure Compare(const AExpected, AActual: TStringList);
    procedure CompareFull(AMode: TFullMode; const AName: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiPercorsiDellAStarSuMappeSintetiche;
    [Test]
    procedure DovrebbeDareGliStessiCampiDiFlussoESuiCampioniSuMappeSintetiche;
    [Test]
    procedure DovrebbeDareLaStessaSceltaDiVelocitaDellEvitamento;
    [Test]
    procedure DovrebbeDareGliStessiCoseniESeniDegliAnelliDelleVelocitaEKCostanti;
    [Test]
    procedure DovrebbeDareGliStessiPercorsiEICampiDiFlussoSuiLivelliVeriDelDataWar;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicDeiGruppiCheSiIncrociano;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDeiGruppiCheSiIncrociano;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicDelCombattimentoConPercorsiENebbia;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicDeiComandiConPercorsiENebbia;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicDegliIncantesimiConPercorsiENebbia;
    [Test]
    procedure DovrebbeDareLeStesseImprontePerTicDelTicInteroConPercorsiENebbia;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDelTicInteroConPercorsiENebbia;
  end;

implementation

const
  PATH_SEEDS = 36;
  RVO_SEEDS = 20;
  MOVE_SEEDS = 12;
  REAL_COMBAT_SEEDS = 12;
  REAL_FULL_SEEDS = 12;
  ALL_LINES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  MODE_PATHS = 0;
  MODE_RVO = 1;

{ TTestWarPathParity }

function TTestWarPathParity.Golden(const AName: string; const APrefixes: string): TStringList;
var
  LAll: TStringList;
  LLine: string;
begin
  Result := TStringList.Create;
  LAll := TStringList.Create;
  try
    LAll.LoadFromFile(TWarRealData.GoldenPath(AName));
    for LLine in LAll do
      if (LLine <> '') and (Pos(LLine[1], APrefixes) > 0) then
        Result.Add(LLine);
  finally
    LAll.Free;
  end;
end;

function TTestWarPathParity.Actual(AMode: Integer; const APrefixes: string): TStringList;
var
  LAll: TStringList;
  LLine: string;
  LSeed: Cardinal;
begin
  Result := TStringList.Create;
  LAll := TStringList.Create;
  try
    if AMode = MODE_PATHS then
      for LSeed := 1 to PATH_SEEDS do
        TPathScenario.RunPaths(LSeed, LAll)
    else
    begin
      TPathScenario.RvoTables(LAll);
      for LSeed := 1 to RVO_SEEDS do
        TPathScenario.RunRvo(LSeed, LAll);
    end;
    for LLine in LAll do
      if (LLine <> '') and (Pos(LLine[1], APrefixes) > 0) then
        Result.Add(LLine);
  finally
    LAll.Free;
  end;
end;

procedure TTestWarPathParity.Compare(const AExpected, AActual: TStringList);
var
  LIndex: Integer;
begin
  Assert.IsTrue(AExpected.Count > 0, 'il golden ha righe');
  for LIndex := 0 to AExpected.Count - 1 do
  begin
    Assert.IsTrue(LIndex < AActual.Count, 'Delphi ha meno righe del C: ' + AExpected[LIndex]);
    if AExpected[LIndex] <> AActual[LIndex] then
      Assert.AreEqual(AExpected[LIndex], AActual[LIndex], Format('riga %d', [LIndex + 1]));
  end;
  Assert.AreEqual(AExpected.Count, AActual.Count, 'righe');
end;

procedure TTestWarPathParity.DovrebbeDareGliStessiPercorsiDellAStarSuMappeSintetiche;
var
  LExpected: TStringList;
  LActual: TStringList;
begin
  LExpected := Golden('path.paths.golden.txt', 'A');
  LActual := Actual(MODE_PATHS, 'A');
  try
    Assert.AreEqual(PATH_SEEDS * PATH_ASTARS, LExpected.Count, 'ricerche del golden');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareGliStessiCampiDiFlussoESuiCampioniSuMappeSintetiche;
var
  LExpected: TStringList;
  LActual: TStringList;
begin
  LExpected := Golden('path.paths.golden.txt', 'F');
  LActual := Actual(MODE_PATHS, 'F');
  try
    Assert.AreEqual(PATH_SEEDS * PATH_FIELDS, LExpected.Count, 'campi del golden');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareLaStessaSceltaDiVelocitaDellEvitamento;
var
  LExpected: TStringList;
  LActual: TStringList;
begin
  LExpected := Golden('path.rvo.golden.txt', 'R');
  LActual := Actual(MODE_RVO, 'R');
  try
    Assert.AreEqual(RVO_SEEDS * RVO_CASES, LExpected.Count, 'scelte del golden');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareGliStessiCoseniESeniDegliAnelliDelleVelocitaEKCostanti;
var
  LExpected: TStringList;
  LActual: TStringList;
begin
  LExpected := Golden('path.rvo.golden.txt', 'TK');
  LActual := Actual(MODE_RVO, 'TK');
  try
    Assert.AreEqual(17, LExpected.Count, 'sedici angoli e le costanti');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareGliStessiPercorsiEICampiDiFlussoSuiLivelliVeriDelDataWar;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
  LExpected: TStringList;
  LActual: TStringList;
  LPosition: Integer;
  LEntry: TWarCatalogEntry;
begin
  LExpected := Golden('path.levels.golden.txt', ALL_LINES);
  LActual := TStringList.Create;
  try
    LCatalog := TWarFactory.CreateCatalog;
    LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
    for LPosition := 0 to LCatalog.Count - 1 do
    begin
      LEntry := LCatalog.GetEntry(LPosition);
      if LEntry.RecordType = wrtLevelPassable then
        TPathScenario.RunLevel(LEntry.Index, TWarLevelMapReader.Read(LArchive.ReadRecord(LEntry.Index)), LActual);
    end;
    Assert.AreEqual(36 * (1 + 8 + 3), LExpected.Count, 'righe del golden: 36 livelli');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareLeStesseImprontePerTicDeiGruppiCheSiIncrociano;
var
  LExpected: TStringList;
  LActual: TStringList;
  LSeed: Cardinal;
  LDump: string;
begin
  LExpected := Golden('path.move.golden.txt', 'M');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to MOVE_SEEDS do
      TMoveScenario.Run(LSeed, -1, LActual, LDump);
    Assert.AreEqual(MOVE_SEEDS * MOVE_SCENARIO_TICS, LExpected.Count, 'righe del golden');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDeiGruppiCheSiIncrociano;
var
  LExpected: TStringList;
  LActual: TStringList;
  LDump: string;
begin
  LExpected := Golden('path.move.dump.golden.txt', ALL_LINES);
  LActual := TStringList.Create;
  try
    TMoveScenario.Run(2, 300, nil, LDump);
    LActual.Text := LDump;
    Assert.IsTrue(LExpected.Count > 20, 'il golden ha il testo dello stato');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareLeStesseImprontePerTicDelCombattimentoConPercorsiENebbia;
var
  LExpected: TStringList;
  LActual: TStringList;
  LSeed: Cardinal;
  LDump: string;
begin
  LExpected := Golden('path.combat.golden.txt', 'C');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to REAL_COMBAT_SEEDS do
      TCombatScenario.Run(LSeed, -1, LActual, LDump, True);
    Assert.AreEqual(REAL_COMBAT_SEEDS * 600, LExpected.Count, 'righe del golden');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.CompareFull(AMode: TFullMode; const AName: string);
var
  LExpected: TStringList;
  LActual: TStringList;
  LSeed: Cardinal;
  LDump: string;
begin
  LExpected := Golden(AName, 'OIA');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to REAL_FULL_SEEDS do
      TFullScenario.Run(AMode, LSeed, -1, LActual, LDump, True);
    Assert.AreEqual(REAL_FULL_SEEDS * FULL_SCENARIO_TICS, LExpected.Count, 'righe del golden');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestWarPathParity.DovrebbeDareLeStesseImprontePerTicDeiComandiConPercorsiENebbia;
begin
  CompareFull(fmCommands, 'path.commands.golden.txt');
end;

procedure TTestWarPathParity.DovrebbeDareLeStesseImprontePerTicDegliIncantesimiConPercorsiENebbia;
begin
  CompareFull(fmSpells, 'path.spells.golden.txt');
end;

procedure TTestWarPathParity.DovrebbeDareLeStesseImprontePerTicDelTicInteroConPercorsiENebbia;
begin
  CompareFull(fmFull, 'path.full.golden.txt');
end;

procedure TTestWarPathParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDelTicInteroConPercorsiENebbia;
var
  LExpected: TStringList;
  LActual: TStringList;
  LDump: string;
begin
  LExpected := Golden('path.full.dump.golden.txt', ALL_LINES);
  LActual := TStringList.Create;
  try
    TFullScenario.Run(fmFull, 11, 450, nil, LDump, True);
    LActual.Text := LDump;
    Assert.IsTrue(LExpected.Count > 50, 'il golden ha il testo dello stato');
    Compare(LExpected, LActual);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

end.
