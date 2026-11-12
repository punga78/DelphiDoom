{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - the diaries and the       }
{  commendations of the soldiers (parity with the real SoldierDiary)            }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Diary;

interface

uses
  DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Shared.Files,
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.XcomSave.DiaryRules.Intf, DelphiDoom.XcomSave.SoldierDiary, DelphiDoom.XcomSave.MissionStatistics,
  DelphiDoom.XcomSave.BattleUnitStatistics, DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomSave.UnitEnums,
  DelphiDoom.Tests.XcomSave.FakeDiaryRules, DelphiDoom.Tests.XcomSave.DiaryScenario;

type
  [TestFixture]
  [Category('xcom-save')]
  TTestXcomDiary = class(TObject)
  private
    function DataFile(const AName: string): string;
    function MakeRules: IXcomDiaryRules;
  public
    [Test]
    procedure DovrebbeDareLeStesseRigheDelVeroOpenXcomSuTuttiIPercorsi;
    [Test]
    procedure DovrebbeAssegnareLeMedaglieDelCorpus;
    [Test]
    procedure DovrebbeSpostareLeUccisioniNelDiarioEContareLeMissioni;
    [Test]
    procedure DovrebbeCalcolareLaPrecisione;
    [Test]
    procedure DovrebbeNonFareNullaSenzaMissioni;
    [Test]
    procedure DovrebbeContareLeMissioniNotturneEDiTerrore;
  end;

implementation

{ TTestXcomDiary }

function TTestXcomDiary.DataFile(const AName: string): string;
begin
  Result := TTestFiles.DataFile('XcomSave', AName);
end;

function TTestXcomDiary.MakeRules: IXcomDiaryRules;
begin
  Result := TXcomFakeDiaryRules.Create(TFile.ReadAllText(DataFile('diary.rules.yml'), TEncoding.UTF8));
end;

procedure TTestXcomDiary.DovrebbeDareLeStesseRigheDelVeroOpenXcomSuTuttiIPercorsi;
var
  LGolden, LCorpus, LActual: TStringList;
  LScenario: TXcomDiaryScenario;
begin
  LGolden := TStringList.Create;
  LCorpus := TStringList.Create;
  LScenario := TXcomDiaryScenario.Create(MakeRules);
  try
    LGolden.LoadFromFile(DataFile('diary.golden.txt'), TEncoding.UTF8);
    LCorpus.LoadFromFile(DataFile('diary.corpus.txt'), TEncoding.UTF8);
    LActual := LScenario.Run(LCorpus);
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LActual.Free;
    end;
  finally
    LScenario.Free;
    LCorpus.Free;
    LGolden.Free;
  end;
end;

procedure TTestXcomDiary.DovrebbeAssegnareLeMedaglieDelCorpus;
var
  LGolden: TStringList;
  LText, LType: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(DataFile('diary.golden.txt'), TEncoding.UTF8);
    LText := LGolden.Text;
    // the corpus has to exercise every kind of criterion
    for LType in ['STR_MEDAL_KILLS', 'STR_MEDAL_WEAPON', 'STR_MEDAL_REGION', 'STR_MEDAL_RACE', 'STR_MEDAL_RANK',
      'STR_MEDAL_CAREER', 'STR_MEDAL_MISSIONK', 'STR_MEDAL_TURN', 'STR_MEDAL_TRAP', 'STR_MEDAL_REACTION',
      'STR_MEDAL_NIGHT', 'STR_MEDAL_DEAD', 'STR_MEDAL_WORLD', 'STR_MEDAL_BASES', 'STR_MEDAL_FRIENDLY'] do
      Assert.IsTrue(Pos('C ' + LType + ' ', LText) > 0, LType);
  finally
    LGolden.Free;
  end;
end;

procedure TTestXcomDiary.DovrebbeSpostareLeUccisioniNelDiarioEContareLeMissioni;
var
  LDiary: TXcomSoldierDiary;
  LStats: TXcomBattleUnitStatistics;
  LMissions: TObjectList<TXcomMissionStatistics>;
  LKill: TXcomBattleUnitKills;
begin
  LDiary := TXcomSoldierDiary.Create;
  LStats := TXcomBattleUnitStatistics.Create;
  LMissions := TObjectList<TXcomMissionStatistics>.Create(True);
  try
    LMissions.Add(TXcomMissionStatistics.Create);
    LMissions.Last.Id := 7;
    LKill := TXcomBattleUnitKills.Create;
    LKill.Status := XcomStatusDead;
    LKill.Faction := XcomFactionHostile;
    LKill.Mission := 2;
    LKill.Turn := 4;
    LStats.Kills.Add(LKill);
    LDiary.UpdateDiary(LStats, LMissions, MakeRules);
    Assert.AreEqual(0, LStats.Kills.Count, 'le uccisioni passano al diario');
    Assert.AreEqual(1, LDiary.KillList.Count);
    Assert.AreEqual(604, LDiary.KillList[0].Turn, 'turno reso unico');
    Assert.AreEqual(1, LDiary.KillTotal);
    Assert.AreEqual(1, LDiary.MissionTotal);
    Assert.AreEqual(7, LDiary.MissionIdList[0]);
  finally
    LMissions.Free;
    LStats.Free;
    LDiary.Free;
  end;
end;

procedure TTestXcomDiary.DovrebbeCalcolareLaPrecisione;
var
  LDiary: TXcomSoldierDiary;
begin
  LDiary := TXcomSoldierDiary.Create;
  try
    Assert.AreEqual(0, LDiary.Accuracy);
    LDiary.SetCounter('shotsFiredCounterTotal', 7);
    LDiary.SetCounter('shotsLandedCounterTotal', 3);
    Assert.AreEqual(42, LDiary.Accuracy);
  finally
    LDiary.Free;
  end;
end;

procedure TTestXcomDiary.DovrebbeNonFareNullaSenzaMissioni;
var
  LDiary: TXcomSoldierDiary;
  LStats: TXcomBattleUnitStatistics;
  LMissions: TObjectList<TXcomMissionStatistics>;
begin
  LDiary := TXcomSoldierDiary.Create;
  LStats := TXcomBattleUnitStatistics.Create;
  LMissions := TObjectList<TXcomMissionStatistics>.Create(True);
  try
    LStats.ShotAtCounter := 5;
    LDiary.UpdateDiary(LStats, LMissions, MakeRules);
    Assert.AreEqual(0, LDiary.Counter('shotAtCounterTotal'));
    Assert.AreEqual(0, LDiary.MissionTotal);
  finally
    LMissions.Free;
    LStats.Free;
    LDiary.Free;
  end;
end;

procedure TTestXcomDiary.DovrebbeContareLeMissioniNotturneEDiTerrore;
var
  LDiary: TXcomSoldierDiary;
  LMissions: TObjectList<TXcomMissionStatistics>;
  LMission: TXcomMissionStatistics;
begin
  LDiary := TXcomSoldierDiary.Create;
  LMissions := TObjectList<TXcomMissionStatistics>.Create(True);
  try
    LMission := TXcomMissionStatistics.Create;
    LMission.Id := 1;
    LMission.Success := True;
    LMission.Daylight := 10;
    LMission.MissionType := 'STR_TERROR_MISSION';
    LMissions.Add(LMission);
    LDiary.MissionIdList := [1];
    Assert.AreEqual(1, LDiary.NightMissionTotal(LMissions));
    Assert.AreEqual(1, LDiary.NightTerrorMissionTotal(LMissions));
    Assert.AreEqual(1, LDiary.TerrorMissionTotal(LMissions));
    LMission.Daylight := 9;
    Assert.AreEqual(0, LDiary.NightMissionTotal(LMissions), 'oltre 9 e'' buio');
  finally
    LMissions.Free;
    LDiary.Free;
  end;
end;

end.
