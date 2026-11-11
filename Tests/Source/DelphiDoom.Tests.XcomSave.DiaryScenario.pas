{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - replay of the careers of  }
{  the diary corpus (diarygen.cpp) with the Pascal diary                        }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.DiaryScenario;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.XcomMod.UnitStats,
  DelphiDoom.XcomSave.DiaryRules.Intf, DelphiDoom.XcomSave.SoldierDiary, DelphiDoom.XcomSave.MissionStatistics,
  DelphiDoom.XcomSave.BattleUnitStatistics, DelphiDoom.XcomSave.BattleUnitKills,
  DelphiDoom.XcomSave.CommendationManager, DelphiDoom.XcomSave.SoldierCommendation;

type
  /// <summary>Runs the lines of the corpus and writes the lines of the golden file</summary>
  TXcomDiaryScenario = class
  strict private
    FRules: IXcomDiaryRules;
    FDiary: TXcomSoldierDiary;
    FMissions: TObjectList<TXcomMissionStatistics>;
    FStats: TXcomBattleUnitStatistics;
    FOutput: TStringList;
    procedure Dump(AAwarded: Boolean);
    procedure StartUnit(const AParts: TArray<string>);
    procedure AddKill(const AParts: TArray<string>);
    procedure AddMission(const AParts: TArray<string>);
    procedure Reset;
  public
    constructor Create(const ARules: IXcomDiaryRules);
    destructor Destroy; override;
    /// <summary>The golden lines for the lines of the corpus (the caller frees the list)</summary>
    function Run(const ACorpus: TStrings): TStringList;
  end;

implementation

{ TXcomDiaryScenario }

constructor TXcomDiaryScenario.Create(const ARules: IXcomDiaryRules);
begin
  inherited Create;
  FRules := ARules;
  FMissions := TObjectList<TXcomMissionStatistics>.Create(True);
end;

destructor TXcomDiaryScenario.Destroy;
begin
  FStats.Free;
  FDiary.Free;
  FMissions.Free;
  inherited Destroy;
end;

procedure TXcomDiaryScenario.Reset;
begin
  FDiary.Free;
  FDiary := TXcomSoldierDiary.Create;
  FMissions.Clear;
end;

procedure TXcomDiaryScenario.Dump(AAwarded: Boolean);
var
  LIndex: Integer;
  LLine: string;
  LKill: TXcomBattleUnitKills;
  LItem: TXcomSoldierCommendation;
  LId: Integer;
begin
  FOutput.Add(Format('R %d %d %d', [Ord(AAwarded), FDiary.KIA, FDiary.MIA]));
  LLine := 'D';
  // the order of the counters of save() is not the one of the harness: the harness prints the fields in order
  for LIndex := 0 to High(TXcomSoldierDiary.COUNTER_KEYS) do
    LLine := LLine + ' ' + IntToStr(FDiary.Counter(TXcomSoldierDiary.COUNTER_KEYS[LIndex]));
  LLine := LLine + ' ' + IntToStr(FDiary.SlaveKillsTotal);
  FOutput.Add(LLine);
  LLine := 'L ' + IntToStr(FDiary.KillList.Count);
  for LKill in FDiary.KillList do
    LLine := LLine + ' ' + IntToStr(LKill.Turn);
  FOutput.Add(LLine);
  LLine := 'I';
  for LId in FDiary.MissionIdList do
    LLine := LLine + ' ' + IntToStr(LId);
  FOutput.Add(LLine);
  for LItem in FDiary.Commendations do
    FOutput.Add(Format('C %s %s %d %d', [LItem.CommendationType, LItem.Noun, LItem.DecorationLevel,
      Ord(LItem.IsNew)]));
end;

procedure TXcomDiaryScenario.AddMission(const AParts: TArray<string>);
var
  LMission: TXcomMissionStatistics;
begin
  LMission := TXcomMissionStatistics.Create;
  LMission.Id := StrToInt(AParts[1]);
  LMission.Success := StrToInt(AParts[2]) <> 0;
  LMission.Score := StrToInt(AParts[3]);
  LMission.Region := AParts[4];
  LMission.Country := AParts[5];
  LMission.MissionType := AParts[6];
  LMission.Ufo := AParts[7];
  LMission.Daylight := StrToInt(AParts[8]);
  LMission.ValiantCrux := StrToInt(AParts[9]) <> 0;
  FMissions.Add(LMission);
end;

procedure TXcomDiaryScenario.StartUnit(const AParts: TArray<string>);
var
  LValue: array[0..39] of Integer;
  LIndex: Integer;
  LDelta: TXcomUnitStats;
begin
  FreeAndNil(FStats);
  FStats := TXcomBattleUnitStatistics.Create;
  FillChar(LValue, SizeOf(LValue), 0);
  for LIndex := 1 to High(AParts) do
    LValue[LIndex] := StrToInt(AParts[LIndex]);
  FStats.WasUnconscious := LValue[1] <> 0;
  FStats.ShotAtCounter := LValue[2];
  FStats.HitCounter := LValue[3];
  FStats.ShotByFriendlyCounter := LValue[4];
  FStats.ShotFriendlyCounter := LValue[5];
  FStats.LoneSurvivor := LValue[6] <> 0;
  FStats.IronMan := LValue[7] <> 0;
  FStats.LongDistanceHitCounter := LValue[8];
  FStats.LowAccuracyHitCounter := LValue[9];
  FStats.ShotsFiredCounter := LValue[10];
  FStats.ShotsLandedCounter := LValue[11];
  FStats.DaysWounded := LValue[12];
  FStats.KIA := LValue[13] <> 0;
  FStats.NikeCross := LValue[14] <> 0;
  FStats.MercyCross := LValue[15] <> 0;
  FStats.WoundsHealed := LValue[16];
  LDelta := Default(TXcomUnitStats);
  LDelta.TimeUnits := LValue[17];
  LDelta.Stamina := LValue[18];
  LDelta.Health := LValue[19];
  LDelta.Bravery := LValue[20];
  LDelta.Reactions := LValue[21];
  LDelta.Firing := LValue[22];
  LDelta.Throwing := LValue[23];
  LDelta.Strength := LValue[24];
  LDelta.PsiStrength := LValue[25];
  LDelta.PsiSkill := LValue[26];
  LDelta.Melee := LValue[27];
  FStats.Delta := LDelta;
  FStats.AppliedStimulant := LValue[28];
  FStats.AppliedPainKill := LValue[29];
  FStats.RevivedSoldier := LValue[30];
  FStats.RevivedHostile := LValue[31];
  FStats.RevivedNeutral := LValue[32];
  FStats.MIA := LValue[33] <> 0;
  FStats.Martyr := LValue[34];
  FStats.SlaveKills := LValue[35];
end;

procedure TXcomDiaryScenario.AddKill(const AParts: TArray<string>);
var
  LKill: TXcomBattleUnitKills;
begin
  LKill := TXcomBattleUnitKills.Create;
  LKill.Rank := AParts[1];
  LKill.Race := AParts[2];
  LKill.Weapon := AParts[3];
  LKill.WeaponAmmo := AParts[4];
  LKill.Faction := StrToInt(AParts[5]);
  LKill.Status := StrToInt(AParts[6]);
  LKill.Mission := StrToInt(AParts[7]);
  LKill.Turn := StrToInt(AParts[8]);
  LKill.Side := StrToInt(AParts[9]);
  LKill.BodyPart := StrToInt(AParts[10]);
  FStats.Kills.Add(LKill);
end;

function TXcomDiaryScenario.Run(const ACorpus: TStrings): TStringList;
var
  LLine: string;
  LParts: TArray<string>;
  LAwarded: Boolean;
  LManager: TXcomCommendationManager;
begin
  FOutput := TStringList.Create;
  Result := FOutput;
  for LLine in ACorpus do
  begin
    LParts := LLine.Split([' ']);
    if (Length(LParts) = 0) or (LParts[0] = '') then
      Continue;
    if LParts[0] = 'CASE' then
    begin
      Reset;
      FOutput.Add(LLine);
    end
    else if LParts[0] = 'MS' then
      FDiary.AddMonthlyService
    else if LParts[0] = 'BR' then
      FDiary.AwardBestOfRank(StrToInt(LParts[1]))
    else if LParts[0] = 'PM' then
      FDiary.AwardPostMortemKill(StrToInt(LParts[1]))
    else if LParts[0] = 'M' then
      AddMission(LParts)
    else if LParts[0] = 'U' then
      StartUnit(LParts)
    else if LParts[0] = 'K' then
      AddKill(LParts)
    else if LParts[0] = 'E' then
    begin
      FDiary.UpdateDiary(FStats, FMissions, FRules);
      LManager := TXcomCommendationManager.Create(FDiary, FRules, FMissions);
      try
        LAwarded := LManager.Manage;
      finally
        LManager.Free;
      end;
      Dump(LAwarded);
      FreeAndNil(FStats);
    end;
  end;
end;

end.
