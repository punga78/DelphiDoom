{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a soldier (Soldier)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Soldier;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.RuleSoldier,
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Types, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.UnitStats, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.EquipmentLayoutItem,
  DelphiDoom.XcomSave.SoldierDeath, DelphiDoom.XcomSave.SoldierDiary, DelphiDoom.XcomSave.Settings.Intf;

type
  /// <summary>
  ///   A soldier of the player: name, stats, rank, armor, equipment layout, death and diary (Soldier). The craft
  ///   it is in is a reference to the target of the craft (not owned); the rules, armor and ruleset belong to
  ///   the ruleset. The stat string (calcStatString) and the names for the user interface are not ported
  /// </summary>
  TXcomSoldier = class
  public
    const
      RANK_ROOKIE = 0;
      RANK_SQUADDIE = 1;
      RANK_SERGEANT = 2;
      RANK_CAPTAIN = 3;
      RANK_COLONEL = 4;
      RANK_COMMANDER = 5;
      GENDER_MALE = 0;
      GENDER_FEMALE = 1;
  strict private
    FName: string;
    FId: Integer;
    FInitialStats: TXcomUnitStats;
    FCurrentStats: TXcomUnitStats;
    FImprovement: Integer;
    FPsiStrImprovement: Integer;
    FRules: TXcomRuleSoldier;
    FRank: Integer;
    FCraft: TXcomTarget;
    FGender: Integer;
    FLook: Integer;
    FMissions: Integer;
    FKills: Integer;
    FRecovery: Integer;
    FRecentlyPromoted: Boolean;
    FPsiTraining: Boolean;
    FArmor: TXcomArmor;
    FEquipmentLayout: TObjectList<TXcomEquipmentLayoutItem>;
    FDeath: TXcomSoldierDeath;
    FDiary: TXcomSoldierDiary;
  public
    /// <summary>
    ///   Soldier(rules, armor, id): with an id other than 0 the stats, name, gender and look are made at random
    ///   (an id of 0 is the soldier that load reads). A name file with no first names is EXcomModException
    /// </summary>
    constructor Create(const ARules: TXcomRuleSoldier; const AArmor: TXcomArmor; AId: Integer;
      const ARandom: IXcomRandom);
    destructor Destroy; override;
    /// <summary>
    ///   load: a soldier with no name or rank is EYamlBadConversion (as&lt;T&gt;() without a fallback); an
    ///   armor the ruleset does not know is the armor of the first soldier type; equipment on an inventory
    ///   the ruleset does not know is dropped
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset);
    /// <summary>save: the diary is saved only when the option is on and it has something</summary>
    function Save(const ASettings: IXcomSaveSettings): IYamlNode;
    property Name: string read FName write FName;
    property Id: Integer read FId;
    property Rules: TXcomRuleSoldier read FRules;
    property Rank: Integer read FRank;
    property Gender: Integer read FGender;
    property Look: Integer read FLook;
    property Missions: Integer read FMissions;
    property Kills: Integer read FKills;
    property InitialStats: TXcomUnitStats read FInitialStats write FInitialStats;
    property CurrentStats: TXcomUnitStats read FCurrentStats write FCurrentStats;
    property Armor: TXcomArmor read FArmor write FArmor;
    /// <summary>getCraft / setCraft: the target of the craft that carries the soldier; nil if none</summary>
    property Craft: TXcomTarget read FCraft write FCraft;
    property Improvement: Integer read FImprovement;
    property PsiStrImprovement: Integer read FPsiStrImprovement;
    property PsiTraining: Boolean read FPsiTraining write FPsiTraining;
    property EquipmentLayout: TObjectList<TXcomEquipmentLayoutItem> read FEquipmentLayout;
    property Death: TXcomSoldierDeath read FDeath;
    property Diary: TXcomSoldierDiary read FDiary;
    property WoundRecovery: Integer read FRecovery;
    /// <summary>setWoundRecovery: a wounded soldier leaves the craft</summary>
    procedure SetWoundRecovery(ARecovery: Integer);
    /// <summary>heal</summary>
    procedure Heal;
    procedure PromoteRank;
    /// <summary>isPromoted: true once after a promotion above squaddie</summary>
    function IsPromoted: Boolean;
    procedure AddMissionCount;
    procedure AddKillCount(ACount: Integer);
    /// <summary>die: takes the death record (owned from now on) and clears the craft, training, wounds and equipment</summary>
    procedure Die(const ADeath: TXcomSoldierDeath);
    /// <summary>trainPsi: the monthly psionic training</summary>
    procedure TrainPsi(const ASettings: IXcomSaveSettings; const ARandom: IXcomRandom);
    /// <summary>trainPsi1Day: the daily psionic training</summary>
    procedure TrainPsiOneDay(const ASettings: IXcomSaveSettings; const ARandom: IXcomRandom);
  end;

implementation

const
  SBadLoad = 'Xcom: a soldier needs a name and a rank';

{ TXcomSoldier }

constructor TXcomSoldier.Create(const ARules: TXcomRuleSoldier; const AArmor: TXcomArmor; AId: Integer;
  const ARandom: IXcomRandom);
var
  LMin, LMax: TXcomUnitStats;
  LNationality: Integer;
  LFemale: Boolean;
begin
  inherited Create;
  FId := AId;
  FRules := ARules;
  FArmor := AArmor;
  FEquipmentLayout := TObjectList<TXcomEquipmentLayoutItem>.Create(True);
  FDiary := TXcomSoldierDiary.Create;
  if AId <> 0 then
  begin
    LMin := ARules.MinStats;
    LMax := ARules.MaxStats;
    FInitialStats.TimeUnits := ARandom.Generate(LMin.TimeUnits, LMax.TimeUnits);
    FInitialStats.Stamina := ARandom.Generate(LMin.Stamina, LMax.Stamina);
    FInitialStats.Health := ARandom.Generate(LMin.Health, LMax.Health);
    FInitialStats.Bravery := ARandom.Generate(LMin.Bravery div 10, LMax.Bravery div 10) * 10;
    FInitialStats.Reactions := ARandom.Generate(LMin.Reactions, LMax.Reactions);
    FInitialStats.Firing := ARandom.Generate(LMin.Firing, LMax.Firing);
    FInitialStats.Throwing := ARandom.Generate(LMin.Throwing, LMax.Throwing);
    FInitialStats.Strength := ARandom.Generate(LMin.Strength, LMax.Strength);
    FInitialStats.PsiStrength := ARandom.Generate(LMin.PsiStrength, LMax.PsiStrength);
    FInitialStats.Melee := ARandom.Generate(LMin.Melee, LMax.Melee);
    FInitialStats.PsiSkill := LMin.PsiSkill;
    FCurrentStats := FInitialStats;
    if ARules.Names.Count > 0 then
    begin
      LNationality := ARandom.Generate(0, ARules.Names.Count - 1);
      FName := ARules.Names[LNationality].GenName(LFemale, ARules.FemaleFrequency, ARandom);
      FGender := Ord(LFemale);
      FLook := ARules.Names[LNationality].GenLook(4, ARandom);
    end
    else
    begin
      // no possible names, just wing it
      FGender := Ord(ARandom.Generate(0, 99) < ARules.FemaleFrequency);
      FLook := ARandom.Generate(0, 3);
      if FGender = GENDER_FEMALE then
        FName := 'Jane'
      else
        FName := 'John';
      FName := FName + ' Doe';
    end;
  end;
end;

destructor TXcomSoldier.Destroy;
begin
  FDiary.Free;
  FDeath.Free;
  FEquipmentLayout.Free;
  inherited Destroy;
end;

procedure TXcomSoldier.Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset);
var
  LField, LItem: IYamlNode;
  LArmor: TXcomArmor;
  LLayoutItem: TXcomEquipmentLayoutItem;
  LRank, LName: IYamlNode;
begin
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
  LName := TXcomNodeReader.Field(ANode, 'name');
  LRank := TXcomNodeReader.Field(ANode, 'rank');
  if not LName.IsDefined or not LRank.IsDefined then
    raise EXcomSaveException.Create(SBadLoad);
  FName := TXcomNodeReader.TextOf(LName);
  FInitialStats := TXcomUnitStatsCodec.Read(ANode, 'initialStats', FInitialStats);
  FCurrentStats := TXcomUnitStatsCodec.Read(ANode, 'currentStats', FCurrentStats);
  FRank := LRank.AsInteger;
  FGender := TXcomNodeReader.Field(ANode, 'gender').AsInteger;
  FLook := TXcomNodeReader.Field(ANode, 'look').AsInteger;
  FMissions := TXcomNodeReader.ReadInteger(ANode, 'missions', FMissions);
  FKills := TXcomNodeReader.ReadInteger(ANode, 'kills', FKills);
  FRecovery := TXcomNodeReader.ReadInteger(ANode, 'recovery', FRecovery);
  LArmor := ARuleset.Armors.Find(TXcomNodeReader.TextOf(TXcomNodeReader.Field(ANode, 'armor')));
  if not Assigned(LArmor) then
    LArmor := ARuleset.Armors.Find(ARuleset.Soldiers.Find(ARuleset.Soldiers.Index[0]).ArmorName);
  FArmor := LArmor;
  FPsiTraining := TXcomNodeReader.ReadBoolean(ANode, 'psiTraining', FPsiTraining);
  FImprovement := TXcomNodeReader.ReadInteger(ANode, 'improvement', FImprovement);
  FPsiStrImprovement := TXcomNodeReader.ReadInteger(ANode, 'psiStrImprovement', FPsiStrImprovement);
  LField := TXcomNodeReader.Field(ANode, 'equipmentLayout');
  if LField.IsDefined then
    for LItem in LField.Items do
    begin
      LLayoutItem := TXcomEquipmentLayoutItem.Create(LItem);
      if Assigned(ARuleset.Inventories.Find(LLayoutItem.Slot)) then
        FEquipmentLayout.Add(LLayoutItem)
      else
        LLayoutItem.Free;
    end;
  LField := TXcomNodeReader.Field(ANode, 'death');
  if LField.IsDefined then
  begin
    FDeath.Free;
    FDeath := TXcomSoldierDeath.Create;
    FDeath.Load(LField);
  end;
  LField := TXcomNodeReader.Field(ANode, 'diary');
  if LField.IsDefined then
  begin
    FDiary.Free;
    FDiary := TXcomSoldierDiary.Create;
    FDiary.Load(LField, ARuleset.Commendations);
  end;
end;

function TXcomSoldier.Save(const ASettings: IXcomSaveSettings): IYamlNode;
var
  LItem: TXcomEquipmentLayoutItem;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRules.SoldierType);
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
  TXcomNodeWriter.SetString(Result, 'name', FName);
  TXcomNodeWriter.SetNode(Result, 'initialStats', TXcomUnitStatsCodec.Encode(FInitialStats));
  TXcomNodeWriter.SetNode(Result, 'currentStats', TXcomUnitStatsCodec.Encode(FCurrentStats));
  TXcomNodeWriter.SetInteger(Result, 'rank', FRank);
  if Assigned(FCraft) then
    TXcomNodeWriter.SetNode(Result, 'craft', FCraft.SaveId);
  TXcomNodeWriter.SetInteger(Result, 'gender', FGender);
  TXcomNodeWriter.SetInteger(Result, 'look', FLook);
  TXcomNodeWriter.SetInteger(Result, 'missions', FMissions);
  TXcomNodeWriter.SetInteger(Result, 'kills', FKills);
  if FRecovery > 0 then
    TXcomNodeWriter.SetInteger(Result, 'recovery', FRecovery);
  TXcomNodeWriter.SetString(Result, 'armor', FArmor.ArmorType);
  if FPsiTraining then
    TXcomNodeWriter.SetBoolean(Result, 'psiTraining', True);
  TXcomNodeWriter.SetInteger(Result, 'improvement', FImprovement);
  TXcomNodeWriter.SetInteger(Result, 'psiStrImprovement', FPsiStrImprovement);
  for LItem in FEquipmentLayout do
    TXcomNodeWriter.PushBack(Result, 'equipmentLayout', LItem.Save);
  if Assigned(FDeath) then
    TXcomNodeWriter.SetNode(Result, 'death', FDeath.Save);
  if ASettings.SoldierDiaries and ((FDiary.MissionTotal > 0) or (FDiary.Commendations.Count > 0) or
    (FDiary.MonthsService > 0)) then
    TXcomNodeWriter.SetNode(Result, 'diary', FDiary.Save);
end;

procedure TXcomSoldier.SetWoundRecovery(ARecovery: Integer);
begin
  FRecovery := ARecovery;
  if FRecovery > 0 then
    FCraft := nil;
end;

procedure TXcomSoldier.Heal;
begin
  Dec(FRecovery);
end;

procedure TXcomSoldier.PromoteRank;
begin
  Inc(FRank);
  if FRank > RANK_SQUADDIE then
    FRecentlyPromoted := True;
end;

function TXcomSoldier.IsPromoted: Boolean;
begin
  Result := FRecentlyPromoted;
  FRecentlyPromoted := False;
end;

procedure TXcomSoldier.AddMissionCount;
begin
  Inc(FMissions);
end;

procedure TXcomSoldier.AddKillCount(ACount: Integer);
begin
  Inc(FKills, ACount);
end;

procedure TXcomSoldier.Die(const ADeath: TXcomSoldierDeath);
begin
  if FDeath <> ADeath then
    FDeath.Free;
  FDeath := ADeath;
  FCraft := nil;
  FPsiTraining := False;
  FRecentlyPromoted := False;
  FRecovery := 0;
  FEquipmentLayout.Clear;
end;

procedure TXcomSoldier.TrainPsi(const ASettings: IXcomSaveSettings; const ARandom: IXcomRandom);
var
  LSkillCap, LStrengthCap, LMax: Integer;
begin
  LSkillCap := FRules.StatCaps.PsiSkill;
  LStrengthCap := FRules.StatCaps.PsiStrength;
  FImprovement := 0;
  FPsiStrImprovement := 0;
  // -10 days: the tolerance threshold for the switch from the anytime psi training option
  if FCurrentStats.PsiSkill < -10 + FRules.MinStats.PsiSkill then
    FCurrentStats.PsiSkill := FRules.MinStats.PsiSkill
  else if FCurrentStats.PsiSkill <= FRules.MaxStats.PsiSkill then
  begin
    LMax := FRules.MaxStats.PsiSkill + FRules.MaxStats.PsiSkill div 2;
    FImprovement := ARandom.Generate(FRules.MaxStats.PsiSkill, LMax);
  end
  else
  begin
    if FCurrentStats.PsiSkill <= LSkillCap div 2 then
      FImprovement := ARandom.Generate(5, 12)
    else if FCurrentStats.PsiSkill < LSkillCap then
      FImprovement := ARandom.Generate(1, 3);
    if ASettings.AllowPsiStrengthImprovement then
    begin
      if FCurrentStats.PsiStrength <= LStrengthCap div 2 then
        FPsiStrImprovement := ARandom.Generate(5, 12)
      else if FCurrentStats.PsiStrength < LStrengthCap then
        FPsiStrImprovement := ARandom.Generate(1, 3);
    end;
  end;
  Inc(FCurrentStats.PsiSkill, FImprovement);
  Inc(FCurrentStats.PsiStrength, FPsiStrImprovement);
  if FCurrentStats.PsiSkill > LSkillCap then
    FCurrentStats.PsiSkill := LSkillCap;
  if FCurrentStats.PsiStrength > LStrengthCap then
    FCurrentStats.PsiStrength := LStrengthCap;
end;

procedure TXcomSoldier.TrainPsiOneDay(const ASettings: IXcomSaveSettings; const ARandom: IXcomRandom);
begin
  if not FPsiTraining then
  begin
    FImprovement := 0;
    Exit;
  end;
  if FCurrentStats.PsiSkill > 0 then
  begin
    if (8 * 100 >= FCurrentStats.PsiSkill * ARandom.Generate(1, 100)) and
      (FCurrentStats.PsiSkill < FRules.StatCaps.PsiSkill) then
    begin
      Inc(FImprovement);
      Inc(FCurrentStats.PsiSkill);
    end;
    if ASettings.AllowPsiStrengthImprovement then
    begin
      if (8 * 100 >= FCurrentStats.PsiStrength * ARandom.Generate(1, 100)) and
        (FCurrentStats.PsiStrength < FRules.StatCaps.PsiStrength) then
      begin
        Inc(FPsiStrImprovement);
        Inc(FCurrentStats.PsiStrength);
      end;
    end;
  end
  else if FCurrentStats.PsiSkill < FRules.MinStats.PsiSkill then
  begin
    Inc(FCurrentStats.PsiSkill);
    if FCurrentStats.PsiSkill = FRules.MinStats.PsiSkill then
    begin
      // the initial training is over
      FImprovement := FRules.MaxStats.PsiSkill + ARandom.Generate(0, FRules.MaxStats.PsiSkill div 2);
      FCurrentStats.PsiSkill := FImprovement;
    end;
  end
  else
    // minStats.psiSkill <= 0 and the skill is the minimum: the initial training lasts 30 to 60 days
    Dec(FCurrentStats.PsiSkill, ARandom.Generate(30, 60));
end;

end.
