{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of building and training with  }
{  the C of the remake                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ConstructionParity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Diagnostics, DUnitX.TestFramework,
  DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   model.construction.*.golden.txt are the output of war_model_ref.exe (Tools\Verifica\194) for the second slice of
  ///   the model: the steps of the actions and the resources of the images of construction (compared one by one) and
  ///   24 scenarios of 400 tics in which workers build and repair, buildings train, research, cancel and collapse, and walls
  ///   are put up and broken, all with the true wcmd_* functions and states of the remake. One line per tic with the
  ///   fingerprint of all the state (the base of the first slice plus the sprites, the ruins, the walls and the sounds);
  ///   a text of the full state of one tic is compared line by line
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarConstructionParity = class(TObject)
  private
    function Golden(const AName: string): TStringList;
    procedure CompareLines(const AExpected, AActual: TStringList);
  public
    [Test]
    procedure DovrebbeDareLeRisorseDelleImmaginiDiCostruzioneEICostiDelleMura;
    [Test]
    procedure DovrebbeDareLeStesseImprontiPerTicDiVentiquattroScenariDiCostruzione;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDiCostruzione;
    [Test]
    procedure DovrebbeRaggiungereTuttiGliStatiDiCostruzioneNegliScenari;
    /// <summary>
    ///   An aid to look for a difference: with DELPHIDOOM_WAR_CONSTRUCTION_DUMP=seed,tic,file it writes the text of the
    ///   state of that tic (compare it with `war_model_ref dump construction seed tic`); without the variable it does nothing
    /// </summary>
    [Test]
    procedure DovrebbeScrivereIlTestoDelloStatoSeRichiesto;
    /// <summary>
    ///   A measure, only if DELPHIDOOM_WAR_BENCH=file is set: 400 footmen that stand and play their idle action, 1500 tics, with
    ///   the update of the states alone and with the update of the actions too; the microseconds per unit and tic go in the file
    /// </summary>
    [Test]
    procedure DovrebbeMisurareIlCostoDeiPassiDelleAzioniSeRichiesto;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.BuildingResources.Data,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Model.ActionRunner,
  DelphiDoom.Tests.War.ConstructionScenario, DelphiDoom.Tests.War.ConstructionRig;

{ TTestWarConstructionParity }

function TTestWarConstructionParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarConstructionParity.CompareLines(const AExpected, AActual: TStringList);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AExpected.Count - 1 do
  begin
    Assert.IsTrue(LIndex < AActual.Count, 'Il modello ha meno righe del C: ' + AExpected[LIndex]);
    Assert.AreEqual(AExpected[LIndex], AActual[LIndex], Format('riga %d', [LIndex + 1]));
  end;
  Assert.AreEqual<Integer>(AExpected.Count, AActual.Count);
end;

procedure TTestWarConstructionParity.DovrebbeDareLeRisorseDelleImmaginiDiCostruzioneEICostiDelleMura;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LFactor: Single;
  LCount: Integer;
begin
  LGolden := Golden('model.construction.tables.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      LFields := LLine.Split([' ']);
      if LLine.StartsWith('R ') then
      begin
        Assert.AreEqual<Integer>(StrToInt(LFields[2]),
          WAR_BUILDING_CONSTRUCTION_RESOURCES[StrToInt(LFields[1]) - WAR_BUILDING_FIRST_TYPE], LLine);
        Inc(LCount);
      end
      else if LLine.StartsWith('K ') then
      begin
        Assert.AreEqual<Integer>(StrToInt(LFields[1]), WAR_WALL_GOLD_COST, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[2]), WAR_WALL_WOOD_COST, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[3]), WAR_WALL_MAX_HP, LLine);
        Inc(LCount);
      end
      else if LLine.StartsWith('H ') then
      begin
        LFactor := WAR_MODEL_HURRY_UP_FACTOR;
        Assert.AreEqual(LFields[1], LowerCase(IntToHex(PCardinal(@LFactor)^, 8)), LLine);
        Inc(LCount);
      end;
    end;
    Assert.AreEqual<Integer>(16 + 1 + 1, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarConstructionParity.DovrebbeDareLeStesseImprontiPerTicDiVentiquattroScenariDiCostruzione;
var
  LGolden: TStringList;
  LActual: TStringList;
  LSeed: Integer;
  LDump: string;
begin
  LGolden := Golden('model.construction.golden.txt');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to 24 do
      TConstructionScenario.Run(LSeed, -1, LActual, LDump);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarConstructionParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDiCostruzione;
var
  LGolden: TStringList;
  LActual: TStringList;
  LDump: string;
begin
  LGolden := Golden('model.construction.dump.golden.txt');
  LActual := TStringList.Create;
  try
    TConstructionScenario.Run(17, 200, nil, LDump);
    LActual.Text := LDump;
    while (LActual.Count > 0) and (LActual[LActual.Count - 1] = '') do
      LActual.Delete(LActual.Count - 1);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarConstructionParity.DovrebbeScrivereIlTestoDelloStatoSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LDump: string;
begin
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_CONSTRUCTION_DUMP');
  if LRequest = '' then
  begin
    Assert.Pass;
    Exit;
  end;
  LParts := LRequest.Split([',']);
  TConstructionScenario.Run(StrToInt(LParts[0]), StrToInt(LParts[1]), nil, LDump);
  TFile.WriteAllText(LParts[2], LDump, TEncoding.ASCII);
end;

procedure TTestWarConstructionParity.DovrebbeMisurareIlCostoDeiPassiDelleAzioniSeRichiesto;
var
  LFile: string;
  LRig: TConstructionRig;
  LIndex: Integer;
  LWatch: TStopwatch;
  LStates: Double;
  LActions: Double;
  LRunner: Double;
begin
  LFile := GetEnvironmentVariable('DELPHIDOOM_WAR_BENCH');
  if LFile = '' then
  begin
    Assert.Pass;
    Exit;
  end;
  LRig := TConstructionRig.Create;
  try
    for LIndex := 0 to 399 do
      LRig.World.Entities.SetInitialIdle(LRig.World.Entities.CreateDude(WAR_UNIT_FOOTMAN, 2 + LIndex mod 56,
        2 + (LIndex div 56) * 4, 0, False));
    LRig.Tick(5);
    LWatch := TStopwatch.StartNew;
    for LIndex := 1 to 1500 do
    begin
      LRig.World.AdvanceClock(0.016666668);
      LRig.World.Update;
    end;
    LStates := LWatch.Elapsed.TotalMilliseconds * 1000 / (400 * 1500);
    LWatch := TStopwatch.StartNew;
    for LIndex := 1 to 1500 do
    begin
      LRig.World.AdvanceClock(0.016666668);
      LRig.World.Update;
      LRig.World.UpdateAfterStates;
    end;
    LActions := LWatch.Elapsed.TotalMilliseconds * 1000 / (400 * 1500);
    // the steps of the actions alone (the one TWarActionRunner), without the grid of the near units
    LWatch := TStopwatch.StartNew;
    for LIndex := 1 to 1500 do
    begin
      LRig.World.AdvanceClock(0.016666668);
      TWarActionRunner.UpdateAll(LRig.World.Context);
    end;
    LRunner := LWatch.Elapsed.TotalMilliseconds * 1000 / (400 * 1500);
    TFile.WriteAllText(LFile, Format('states %.4f us, states+UpdateAfterStates %.4f us, action steps alone %.4f us ' +
      '(per unit and tic)', [LStates, LActions, LRunner], TFormatSettings.Invariant));
  finally
    LRig.Free;
  end;
end;

procedure TTestWarConstructionParity.DovrebbeRaggiungereTuttiGliStatiDiCostruzioneNegliScenari;
var
  LSeed: Integer;
  LCover: TArray<Integer>;
  LTotal: array[0..WAR_STATE_COUNT - 1] of Integer;
  LType: Integer;
begin
  // the scenarios must reach every state of building and training: the golden would prove nothing otherwise
  FillChar(LTotal, SizeOf(LTotal), 0);
  for LSeed := 1 to 24 do
  begin
    LCover := TConstructionScenario.Coverage(LSeed);
    for LType := 0 to WAR_STATE_COUNT - 1 do
      Inc(LTotal[LType], LCover[LType]);
  end;
  for LType := WAR_STATE_COLLAPSE to WAR_STATE_REPAIRING do
    Assert.IsTrue(LTotal[LType] > 0, Format('nessuno stato di tipo %d negli scenari', [LType]));
end;

end.
