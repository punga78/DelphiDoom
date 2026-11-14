{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the game model with the C  }
{  of the remake                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   model.*.golden.txt are the output of war_model_ref.exe (Tools\Verifica\194): the model of war1 (entities, units, state
  ///   machine, economy, damage, the actions' durations) compiled as it is with gcc, with no pathfinding and no other units
  ///   in the way of a moving one. The tables are compared field by field (the speeds by their bits); the scenarios
  ///   are 20 friendly and 16 hostile lives of 300 and up to 900 tics, one line per tic with the fingerprint of all the
  ///   state (entities, components, stacks of states, storage, grid of occupation, random draws); a text of the full
  ///   state of one tic is compared line by line
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarModelParity = class(TObject)
  private
    function Golden(const AName: string): TStringList;
    function Fields(const ALine: string): TArray<string>;
    function BitsOf(AValue: Single): string;
    function RunScenarios(AHostile: Boolean; ACount: Integer): TStringList;
    procedure CompareLines(const AExpected, AActual: TStringList);
  public
    [Test]
    procedure DovrebbeDareLeStatisticheDelleUnitaDelC;
    [Test]
    procedure DovrebbeDareLeStatisticheDegliEdificiDelMiglioramentiEDegliIncantesimiDelC;
    [Test]
    procedure DovrebbeClassificareITipiDiUnitaComeIlC;
    [Test]
    procedure DovrebbeDareLeAzioniEDurateDelC;
    [Test]
    procedure DovrebbeDareIlTempoDellaMappaDelC;
    [Test]
    procedure DovrebbeDareLeStesseImprontiPerTicDiVentiScenariAmichevoli;
    [Test]
    procedure DovrebbeDareLeStesseImprontiPerTicDiSedicidScenariOstili;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTic;
    [Test]
    procedure DovrebbeUsareLaDurataDiUnTicDelC;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Intf,
  DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.Database, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.Math, DelphiDoom.Tests.War.ModelScenario;

{ TTestWarModelParity }

function TTestWarModelParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

function TTestWarModelParity.Fields(const ALine: string): TArray<string>;
begin
  Result := ALine.Split([' ']);
end;

function TTestWarModelParity.BitsOf(AValue: Single): string;
begin
  Result := LowerCase(IntToHex(PCardinal(@AValue)^, 8));
end;

procedure TTestWarModelParity.DovrebbeDareLeStatisticheDelleUnitaDelC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LDatabase: IWarDatabase;
  LStats: TWarUnitStatsFull;
  LCount: Integer;
  LLevel: Integer;
begin
  LDatabase := TWarDatabase.Create;
  LGolden := Golden('model.tables.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      if not LLine.StartsWith('U ') then
        Continue;
      LFields := Fields(LLine);
      LStats := LDatabase.GetUnitStats(StrToInt(LFields[1]));
      Assert.AreEqual<Integer>(StrToInt(LFields[2]), LStats.Range, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[3]), LStats.Sight, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[4]), LStats.Armor, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[5]), LStats.Hp, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[6]), LStats.Mana, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[7]), LStats.MinDamage, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[8]), LStats.RndDamage, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[9]), LStats.BuildTime, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[10]), LStats.GoldCost, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[11]), LStats.WoodCost, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[12]), LStats.Decay, LLine);
      for LLevel := 0 to 2 do
        Assert.AreEqual(LFields[13 + LLevel], BitsOf(LStats.Speeds[LLevel]), LLine);
      Inc(LCount);
    end;
    Assert.AreEqual<Integer>(28, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeDareLeStatisticheDegliEdificiDelMiglioramentiEDegliIncantesimiDelC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LDatabase: IWarDatabase;
  LBuilding: TWarBuildingStatsFull;
  LUpgrade: TWarUpgradeStats;
  LSpell: TWarSpellStats;
  LCount: Integer;
begin
  LDatabase := TWarDatabase.Create;
  LGolden := Golden('model.tables.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      LFields := Fields(LLine);
      if LLine.StartsWith('B ') then
      begin
        LBuilding := LDatabase.GetBuildingStats(StrToInt(LFields[1]));
        Assert.AreEqual<Integer>(StrToInt(LFields[2]), LBuilding.Armor, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[3]), LBuilding.Sight, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[4]), LBuilding.Hp, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[5]), LBuilding.BuildTime, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[6]), LBuilding.GoldCost, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[7]), LBuilding.WoodCost, LLine);
        Inc(LCount);
      end
      else if LLine.StartsWith('G ') then
      begin
        LUpgrade := LDatabase.GetUpgradeStats(StrToInt(LFields[1]));
        Assert.AreEqual<Integer>(StrToInt(LFields[2]), LUpgrade.BuildTime, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[3]), LUpgrade.GoldCost1, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[4]), LUpgrade.GoldCost2, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[5]), LUpgrade.MaxLevel, LLine);
        Inc(LCount);
      end
      else if LLine.StartsWith('P ') then
      begin
        LSpell := LDatabase.GetSpellStats(StrToInt(LFields[1]));
        Assert.AreEqual<Integer>(StrToInt(LFields[2]), LSpell.ManaCost, LLine);
        Assert.AreEqual(LFields[3], BitsOf(LSpell.Time), LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[4]), LSpell.Range, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[5]), LSpell.MappedUnit, LLine);
        Inc(LCount);
      end;
    end;
    Assert.AreEqual<Integer>(19 + 19 + 12, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeClassificareITipiDiUnitaComeIlC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LType: Integer;
  LFlags: string;
  LExpected: string;
  LCount: Integer;
begin
  LGolden := Golden('model.tables.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      if not LLine.StartsWith('C ') then
        Continue;
      LFields := Fields(LLine);
      LType := StrToInt(LFields[1]);
      LFlags := '';
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsDude(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsBuilding(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsWorker(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsWarrior(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsRange(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsMelee(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsFist(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsSword(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsMagic(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsCorpse(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsCatapult(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsConjurerOrWarlock(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsClericOrNecrolyte(LType)));
      LFlags := LFlags + IntToStr(Ord(TWarUnitClassifier.IsSummon(LType)));
      LExpected := LFields[2];
      Assert.AreEqual(LExpected, LFlags, LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[3]), Ord(TWarUnitClassifier.RaceOf(LType)), LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[4]), TWarUnitClassifier.TypeForRace(LType, wraHumans), LLine);
      Assert.AreEqual<Integer>(StrToInt(LFields[5]), TWarUnitClassifier.TypeForRace(LType, wraOrcs), LLine);
      Inc(LCount);
    end;
    Assert.AreEqual<Integer>(WAR_UNIT_COUNT, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeDareLeAzioniEDurateDelC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LPair: TArray<string>;
  LType: Integer;
  LAction: Integer;
  LCount: Integer;
begin
  LGolden := Golden('model.tables.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      if not LLine.StartsWith('A ') then
        Continue;
      LFields := Fields(LLine);
      LType := StrToInt(LFields[1]);
      for LAction := 0 to WAR_ACTION_TYPE_COUNT - 1 do
      begin
        LPair := LFields[2 + LAction].Split([',']);
        Assert.AreEqual(LPair[0] = '1', TWarActionTable.Has(LType, LAction), LLine);
        Assert.AreEqual<Integer>(StrToInt(LPair[1]), TWarActionTable.Duration(LType, LAction), LLine);
      end;
      Inc(LCount);
    end;
    Assert.AreEqual<Integer>(WAR_UNIT_COUNT, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeDareIlTempoDellaMappaDelC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LClock: TWarGameClock;
  LSeconds: Single;
  LGlobal: Cardinal;
  LBits: Cardinal;
  LCount: Integer;
begin
  LGolden := Golden('model.tables.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      if not LLine.StartsWith('T ') then
        Continue;
      LFields := Fields(LLine);
      LClock := Default(TWarGameClock);
      LClock.GameSpeed := StrToInt(LFields[1]);
      LGlobal := StrToUInt('$' + LFields[2]);
      LClock.GlobalSpeed := PSingle(@LGlobal)^;
      LBits := StrToUInt('$' + LFields[3]);
      LSeconds := PSingle(@LBits)^;
      Assert.AreEqual(LFields[4], BitsOf(TWarModelMath.ScaledTime(LClock, LSeconds)), LLine);
      Inc(LCount);
    end;
    Assert.AreEqual<Integer>(60, LCount);
  finally
    LGolden.Free;
  end;
end;

function TTestWarModelParity.RunScenarios(AHostile: Boolean; ACount: Integer): TStringList;
var
  LSeed: Integer;
  LDump: string;
begin
  Result := TStringList.Create;
  for LSeed := 1 to ACount do
    TModelScenario.Run(AHostile, LSeed, -1, Result, LDump);
end;

procedure TTestWarModelParity.CompareLines(const AExpected, AActual: TStringList);
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

procedure TTestWarModelParity.DovrebbeDareLeStesseImprontiPerTicDiVentiScenariAmichevoli;
var
  LGolden: TStringList;
  LActual: TStringList;
begin
  LGolden := Golden('model.friendly.golden.txt');
  LActual := RunScenarios(False, 20);
  try
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeDareLeStesseImprontiPerTicDiSedicidScenariOstili;
var
  LGolden: TStringList;
  LActual: TStringList;
begin
  LGolden := Golden('model.hostile.golden.txt');
  LActual := RunScenarios(True, 16);
  try
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeDareLoStessoTestoDelloStatoAUnTic;
var
  LGolden: TStringList;
  LActual: TStringList;
  LDump: string;
begin
  LGolden := Golden('model.dump.golden.txt');
  LActual := TStringList.Create;
  try
    TModelScenario.Run(False, 3, 120, nil, LDump);
    LActual.Text := LDump;
    while (LActual.Count > 0) and (LActual[LActual.Count - 1] = '') do
      LActual.Delete(LActual.Count - 1);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarModelParity.DovrebbeUsareLaDurataDiUnTicDelC;
var
  LBits: Single;
begin
  // 1.0f / 60.0f of the C: the scenarios use the number of the test, not the division
  LBits := 1.0 / 60.0;
  Assert.AreEqual($3C888889, Integer(PCardinal(@LBits)^));
end;

end.
