{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the choice of the sounds of Libs\War                   }
{                                                                              }
{  The parity tests read the golden files of Tests\Data\War made by            }
{  Tools\Verifica\198\Compila-SoundRef.ps1 from the code of the remake         }
{  (war_audio.c); they need no data of the game.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.SoundPicker;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Sound.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarSoundPicker = class
  strict private
    function Picker(const ARandom: IWarRandom): IWarSoundPicker;
  public
    [Test]
    procedure DovrebbeDareIlSuonoFissoSenzaChiedereNumeriCasuali;
    [Test]
    procedure DovrebbeScegliereNellIntervalloConIlNumeroCasuale;
    [Test]
    procedure DovrebbeDareLUltimoSuonoDellIntervalloConIlNumeroPiuAlto;
    [Test]
    procedure DovrebbeNonSuonareUnPassoCheNonHaSuono;
    [Test]
    procedure DovrebbeInfastidireLUnicaUnitaSelezionata;
    [Test]
    procedure DovrebbeRispondereAllaSelezioneDiPiuUnita;
    [Test]
    procedure DovrebbeSuonareLaCostruzioneDiUnEdificioInCostruzione;
    [Test]
    procedure DovrebbeCrepitareSottoUnTerzoDellaVita;
    [Test]
    procedure DovrebbeNonCrepitareSopraUnTerzoDellaVita;
    [Test]
    procedure DovrebbeNonCrepitareSeLaVitaMassimaENulla;
    [Test]
    procedure DovrebbeDareIlSuonoDiOgniEdificioChiaveInMano;
    [Test]
    procedure DovrebbeDareIlSuonoDellaMorteSecondoLUnita;
    [Test]
    procedure DovrebbeDareIlBriefingDiOgniMissione;
    [Test]
    procedure DovrebbeNonDareIlBriefingFuoriDalleMissioni;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaONumeriCasualiNulli;
    [Test]
    procedure DovrebbeLeggereUnaRazzaNeutraleComeGliOrchi;
    [Test]
    procedure DovrebbeDareLeStesseScelteDelCDelRemake;
    [Test]
    procedure DovrebbeAvereTuttiGliIntervalliCheIlRemakeUsa;
    [Test]
    procedure DovrebbeDareGliStessiNumeriConLoStessoSeme;
    [Test]
    procedure DovrebbeDareNumeriMinoriDelLimiteEZeroSenzaLimite;
    [Test]
    procedure DovrebbeDareNumeriDiversiConSemiDiversi;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Types,
  DelphiDoom.War.Sound.Ids, DelphiDoom.War.Sound.Factory, DelphiDoom.War.Sound.Table,
  DelphiDoom.War.Sound.Picker, DelphiDoom.War.Sound.SeededRandom, DelphiDoom.Tests.War.MusicFakes,
  DelphiDoom.Tests.War.RealData;

{ TTestWarSoundPicker }

function TTestWarSoundPicker.Picker(const ARandom: IWarRandom): IWarSoundPicker;
begin
  Result := TWarSoundFactory.CreatePicker(ARandom);
end;

procedure TTestWarSoundPicker.DovrebbeDareIlSuonoFissoSenzaChiedereNumeriCasuali;
var
  LRandom: TScriptedRandom;
  LHold: IWarRandom;
begin
  LRandom := TScriptedRandom.Create([]);
  LHold := LRandom;
  Assert.AreEqual<Integer>(WAR_SND_FIST_ATTACK, Picker(LHold).AttackSound(wasSoundFist));
  Assert.AreEqual<Integer>(0, Length(LRandom.Limits));
end;

procedure TTestWarSoundPicker.DovrebbeScegliereNellIntervalloConIlNumeroCasuale;
var
  LRandom: TScriptedRandom;
  LHold: IWarRandom;
begin
  LRandom := TScriptedRandom.Create([2]);
  LHold := LRandom;
  // randomi(487, 490) = 487 + SDL_rand(3)
  Assert.AreEqual<Integer>(489, Picker(LHold).AttackSound(wasSoundSword));
  Assert.AreEqual<Integer>(1, Length(LRandom.Limits));
  Assert.AreEqual<Integer>(3, LRandom.Limits[0]);
end;

procedure TTestWarSoundPicker.DovrebbeDareLUltimoSuonoDellIntervalloConIlNumeroPiuAlto;
var
  LHold: IWarRandom;
begin
  LHold := TScriptedRandom.Create([3]);
  Assert.AreEqual<Integer>(WAR_SND_ORC_ACKNOWLEDGEMENT_LAST, Picker(LHold).Pick(wseAcknowledgement, wraOrcs));
end;

procedure TTestWarSoundPicker.DovrebbeNonSuonareUnPassoCheNonHaSuono;
var
  LPicker: IWarSoundPicker;
begin
  LPicker := Picker(TScriptedRandom.Create([]));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.AttackSound(wasNone));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.AttackSound(wasWait));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.AttackSound(wasSoundChopping));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.AttackSound(wasSoundLightning));
end;

procedure TTestWarSoundPicker.DovrebbeInfastidireLUnicaUnitaSelezionata;
var
  LPicker: IWarSoundPicker;
begin
  LPicker := Picker(TScriptedRandom.Create([0, 1]));
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_ANNOYED_FIRST, LPicker.DudeSelectionSound(wraHumans, True));
  Assert.AreEqual<Integer>(WAR_SND_ORC_ANNOYED_FIRST + 1, LPicker.DudeSelectionSound(wraOrcs, True));
end;

procedure TTestWarSoundPicker.DovrebbeRispondereAllaSelezioneDiPiuUnita;
var
  LPicker: IWarSoundPicker;
begin
  LPicker := Picker(TScriptedRandom.Create([4, 0]));
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_SELECTED_LAST, LPicker.DudeSelectionSound(wraHumans, False));
  Assert.AreEqual<Integer>(WAR_SND_ORC_SELECTED_FIRST, LPicker.DudeSelectionSound(wraOrcs, False));
end;

procedure TTestWarSoundPicker.DovrebbeSuonareLaCostruzioneDiUnEdificioInCostruzione;
var
  LState: TWarBuildingSoundState;
begin
  LState := Default(TWarBuildingSoundState);
  LState.UnderConstruction := True;
  LState.Hp := 1;
  LState.MaxHp := 100;
  LState.UnitType := WAR_UNIT_CHURCH;
  // under construction wins over the fire and over the type
  Assert.AreEqual<Integer>(WAR_SND_BUILDING, Picker(TScriptedRandom.Create([])).BuildingSelectionSound(LState));
end;

procedure TTestWarSoundPicker.DovrebbeCrepitareSottoUnTerzoDellaVita;
var
  LState: TWarBuildingSoundState;
begin
  LState := Default(TWarBuildingSoundState);
  LState.Hp := 33;
  LState.MaxHp := 100;
  LState.UnitType := WAR_UNIT_CHURCH;
  Assert.AreEqual<Integer>(WAR_SND_FIRE_CRACKLING, Picker(TScriptedRandom.Create([])).BuildingSelectionSound(LState));
end;

procedure TTestWarSoundPicker.DovrebbeNonCrepitareSopraUnTerzoDellaVita;
var
  LState: TWarBuildingSoundState;
begin
  LState := Default(TWarBuildingSoundState);
  LState.Hp := 34;
  LState.MaxHp := 100;
  LState.UnitType := WAR_UNIT_CHURCH;
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_CHURCH, Picker(TScriptedRandom.Create([])).BuildingSelectionSound(LState));
end;

procedure TTestWarSoundPicker.DovrebbeNonCrepitareSeLaVitaMassimaENulla;
var
  LState: TWarBuildingSoundState;
begin
  LState := Default(TWarBuildingSoundState);
  LState.UnitType := WAR_UNIT_TEMPLE;
  // the original divides by 0 here: no building has no life points, the choice is the one of a healthy one
  Assert.AreEqual<Integer>(WAR_SND_ORC_TEMPLE, Picker(TScriptedRandom.Create([])).BuildingSelectionSound(LState));
end;

procedure TTestWarSoundPicker.DovrebbeDareIlSuonoDiOgniEdificioChiaveInMano;
var
  LPicker: IWarSoundPicker;
  LState: TWarBuildingSoundState;
begin
  LPicker := Picker(TScriptedRandom.Create([]));
  LState := Default(TWarBuildingSoundState);
  LState.Hp := 100;
  LState.MaxHp := 100;
  LState.UnitType := WAR_UNIT_STABLE;
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_STABLE, LPicker.BuildingSelectionSound(LState));
  LState.UnitType := WAR_UNIT_KENNEL;
  Assert.AreEqual<Integer>(WAR_SND_ORC_KENNEL, LPicker.BuildingSelectionSound(LState));
  LState.UnitType := WAR_UNIT_BLACKSMITH_HUMANS;
  Assert.AreEqual<Integer>(WAR_SND_BLACKSMITH, LPicker.BuildingSelectionSound(LState));
  LState.UnitType := WAR_UNIT_BLACKSMITH_ORCS;
  Assert.AreEqual<Integer>(WAR_SND_BLACKSMITH, LPicker.BuildingSelectionSound(LState));
  LState.UnitType := WAR_UNIT_FARM_HUMANS;
  Assert.AreEqual<Integer>(WAR_SND_UI_CLICK, LPicker.BuildingSelectionSound(LState));
end;

procedure TTestWarSoundPicker.DovrebbeDareIlSuonoDellaMorteSecondoLUnita;
var
  LPicker: IWarSoundPicker;
begin
  LPicker := Picker(TScriptedRandom.Create([1]));
  Assert.AreEqual<Integer>(WAR_SND_DEAD_SPIDER_SCORPION, LPicker.DeathSound(WAR_UNIT_SPIDER, wraHumans));
  Assert.AreEqual<Integer>(WAR_SND_DEAD_SPIDER_SCORPION, LPicker.DeathSound(WAR_UNIT_SCORPION, wraOrcs));
  // a catapult falls apart like a building
  Assert.AreEqual<Integer>(WAR_SND_BUILDING_COLLAPSE_FIRST + 1, LPicker.DeathSound(WAR_UNIT_CATAPULT_ORCS, wraOrcs));
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_DEAD, LPicker.DeathSound(0, wraHumans));
  Assert.AreEqual<Integer>(WAR_SND_ORC_DEAD, LPicker.DeathSound(0, wraOrcs));
end;

procedure TTestWarSoundPicker.DovrebbeDareIlBriefingDiOgniMissione;
var
  LPicker: IWarSoundPicker;
  LMission: Integer;
begin
  LPicker := Picker(TScriptedRandom.Create([]));
  for LMission := 1 to 12 do
  begin
    Assert.AreEqual<Integer>(550 + LMission, LPicker.BriefingSound(wraHumans, LMission));
    Assert.AreEqual<Integer>(562 + LMission, LPicker.BriefingSound(wraOrcs, LMission));
  end;
end;

procedure TTestWarSoundPicker.DovrebbeNonDareIlBriefingFuoriDalleMissioni;
var
  LPicker: IWarSoundPicker;
begin
  LPicker := Picker(TScriptedRandom.Create([]));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.BriefingSound(wraHumans, 0));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.BriefingSound(wraOrcs, 13));
  Assert.AreEqual<Integer>(WAR_SND_NONE, LPicker.BriefingSound(wraNeutral, 1));
end;

procedure TTestWarSoundPicker.DovrebbeRifiutareUnaTabellaONumeriCasualiNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSoundPicker.Create(nil, TScriptedRandom.Create([]));
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarSoundPicker.Create(TWarSoundTable.Create, nil);
    end, EWarException);
end;

procedure TTestWarSoundPicker.DovrebbeLeggereUnaRazzaNeutraleComeGliOrchi;
var
  LTable: IWarSoundTable;
begin
  LTable := TWarSoundTable.Create;
  Assert.AreEqual<Integer>(WAR_SND_ORC_DEAD, LTable.Choice(wseUnitDeath, wraNeutral).First);
  Assert.AreEqual<Integer>(WAR_SND_ORC_ACKNOWLEDGEMENT_FIRST, LTable.Choice(wseAcknowledgement, wraNeutral).First);
  Assert.IsTrue(LTable.Choice(wseSpell, wraHumans).First = LTable.Choice(wseSpell, wraOrcs).First,
    'A spell sounds the same for both races');
end;

procedure TTestWarSoundPicker.DovrebbeDareLeStesseScelteDelCDelRemake;
var
  LLines: TArray<string>;
  LLine: string;
  LParts: TArray<string>;
  LRandom: TScriptedRandom;
  LPicker: IWarSoundPicker;
  LHold: IWarRandom;
  LSound, LExpectedFirst, LExpectedLast, LChecked: Integer;
  LRace: TWarRace;
  LState: TWarBuildingSoundState;
  LExpected: string;
begin
  LLines := TFile.ReadAllLines(TWarRealData.GoldenPath('sounds.tables.golden.txt'));
  LChecked := 0;
  for LLine in LLines do
  begin
    if LLine = '' then
      Continue;
    LParts := LLine.Split([' ']);
    // the generator always answers 0: a range gives its first sound and asks Below(last - first + 1)
    LRandom := TScriptedRandom.Create([]);
    LHold := LRandom;
    LPicker := Picker(LHold);
    if LParts[0] = 'A' then
      LSound := LPicker.AttackSound(TWarActionStep(StrToInt(LParts[1])))
    else if LParts[0] = 'D' then
    begin
      LRace := wraOrcs;
      if LParts[1] = '1' then
        LRace := wraHumans;
      LSound := LPicker.DudeSelectionSound(LRace, LParts[2] = '1');
    end
    else if LParts[0] = 'B' then
    begin
      LState := Default(TWarBuildingSoundState);
      LState.UnderConstruction := LParts[1] <> '0';
      LState.Hp := StrToInt(LParts[2]);
      LState.MaxHp := StrToInt(LParts[3]);
      LState.UnitType := StrToInt(LParts[4]);
      LSound := LPicker.BuildingSelectionSound(LState);
    end
    else if LParts[0] = 'K' then
    begin
      LRace := wraOrcs;
      if LParts[1] = '1' then
        LRace := wraHumans;
      LSound := LPicker.Pick(wseAcknowledgement, LRace);
    end
    else
      Continue;
    // the golden says how the C answers: N (nothing), F id (that sound) or R first last (one of them)
    LExpected := LParts[High(LParts) - 2] + ' ' + LParts[High(LParts) - 1] + ' ' + LParts[High(LParts)];
    if LLine.EndsWith(' N') then
    begin
      Assert.AreEqual<Integer>(WAR_SND_NONE, LSound, LLine);
      Assert.AreEqual<Integer>(0, Length(LRandom.Limits), LLine);
    end
    else if LParts[High(LParts) - 1] = 'F' then
    begin
      Assert.AreEqual<Integer>(StrToInt(LParts[High(LParts)]), LSound, LLine);
      Assert.AreEqual<Integer>(0, Length(LRandom.Limits), LLine);
    end
    else
    begin
      LExpectedFirst := StrToInt(LParts[High(LParts) - 1]);
      LExpectedLast := StrToInt(LParts[High(LParts)]);
      Assert.AreEqual<Integer>(LExpectedFirst, LSound, LLine);
      Assert.AreEqual<Integer>(1, Length(LRandom.Limits), LLine);
      Assert.AreEqual<Integer>(LExpectedLast - LExpectedFirst + 1, LRandom.Limits[0], LLine);
    end;
    Inc(LChecked);
  end;
  // 11 steps, 4 selections, 3 x 10 x 16 buildings, 2 answers
  Assert.AreEqual<Integer>(11 + 4 + 3 * 10 * 16 + 2, LChecked);
  Assert.IsTrue(LExpected <> '');
end;

procedure TTestWarSoundPicker.DovrebbeAvereTuttiGliIntervalliCheIlRemakeUsa;
var
  LLine: string;
  LParts: TArray<string>;
  LRanges: TArray<TWarSoundChoice>;
  LIndex, LFound, LFrom, LTo, LExtra, LGolden: Integer;
  LTable: IWarSoundTable;
begin
  LTable := TWarSoundFactory.CreateTable;
  LRanges := LTable.RandomRanges;
  LGolden := 0;
  LFound := 0;
  for LLine in TFile.ReadAllLines(TWarRealData.GoldenPath('sounds.ranges.golden.txt')) do
  begin
    if LLine = '' then
      Continue;
    LParts := LLine.Split([' ']);
    LFrom := StrToInt(LParts[2]);
    LTo := StrToInt(LParts[3]);
    Inc(LGolden);
    for LIndex := 0 to High(LRanges) do
      if (LRanges[LIndex].First = LFrom) and (LRanges[LIndex].Last = LTo) then
        Inc(LFound);
  end;
  Assert.AreEqual<Integer>(9, LGolden);
  Assert.AreEqual<Integer>(LGolden, LFound, 'Every range of the remake is in the table');
  // the only ranges that the remake does not have are the victories of the two races (a project decision)
  LExtra := Length(LRanges) - LGolden;
  Assert.AreEqual<Integer>(2, LExtra);
end;

procedure TTestWarSoundPicker.DovrebbeDareGliStessiNumeriConLoStessoSeme;
var
  LFirst, LSecond: IWarRandom;
  LIndex: Integer;
begin
  LFirst := TWarSoundFactory.CreateRandom(1234);
  LSecond := TWarSoundFactory.CreateRandom(1234);
  for LIndex := 1 to 50 do
    Assert.AreEqual<Integer>(LFirst.Below(97), LSecond.Below(97));
end;

procedure TTestWarSoundPicker.DovrebbeDareNumeriMinoriDelLimiteEZeroSenzaLimite;
var
  LRandom: IWarRandom;
  LIndex, LValue: Integer;
  LSeen: array[0..4] of Boolean;
begin
  LRandom := TWarSoundFactory.CreateRandom(7);
  FillChar(LSeen, SizeOf(LSeen), 0);
  for LIndex := 1 to 500 do
  begin
    LValue := LRandom.Below(5);
    Assert.IsTrue((LValue >= 0) and (LValue < 5));
    LSeen[LValue] := True;
  end;
  for LIndex := 0 to 4 do
    Assert.IsTrue(LSeen[LIndex], 'Every number comes out');
  Assert.AreEqual<Integer>(0, LRandom.Below(0));
  Assert.AreEqual<Integer>(0, LRandom.Below(-3));
  Assert.AreEqual<Integer>(0, LRandom.Below(1));
end;

procedure TTestWarSoundPicker.DovrebbeDareNumeriDiversiConSemiDiversi;
var
  LFirst, LSecond: IWarRandom;
  LIndex, LDifferent: Integer;
begin
  LFirst := TWarSeededRandom.Create(1);
  LSecond := TWarSeededRandom.Create(2);
  LDifferent := 0;
  for LIndex := 1 to 50 do
    if LFirst.Below(1000) <> LSecond.Below(1000) then
      Inc(LDifferent);
  Assert.IsTrue(LDifferent > 40);
end;

end.
