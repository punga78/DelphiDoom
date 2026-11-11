{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - NewBattleState of OpenXcom (the mission      }
{  generator of the main menu: a battle with a craft, soldiers and equipment    }
{  made for it)                                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.NewBattleState;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.Frame,
  DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.Slider, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomMenu.NewBattle.Intf;

type
  /// <summary>
  ///   The New Battle window: mission, craft, darkness, terrain, depth, difficulty, alien race and alien
  ///   technology. It makes a saved game of its own (a base from the starting base, a craft, thirty soldiers,
  ///   one of every item, all the research) and keeps it as the session of the game; OK gives the battle to the
  ///   navigator, Cancel throws the saved game away, Randomize starts again with random choices. The choices and
  ///   the base go to the store (battle.cfg) at OK and Cancel and come back the next time. The state needs a
  ///   host whose data has rules (IXcomGameRules)
  /// </summary>
  TXcomNewBattleState = class(TXcomState)
  strict private
    FNavigator: IXcomNewBattleNavigator;
    FStore: IXcomNewBattleStore;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FSettings: IXcomSaveSettings;
    FSave: TXcomSavedGame;
    FRules: TXcomRulesetRules;
    FCraft: TXcomCraft;
    FWindow: TXcomWindow;
    FTxtTitle, FTxtMapOptions, FTxtAlienOptions, FTxtMission, FTxtCraft, FTxtDarkness, FTxtTerrain, FTxtDepth,
      FTxtDifficulty, FTxtAlienRace, FTxtAlienTech: TXcomText;
    FFrameLeft, FFrameRight: TXcomFrame;
    FCbxMission, FCbxCraft, FCbxTerrain, FCbxDifficulty, FCbxAlienRace: TXcomComboBox;
    FSlrDarkness, FSlrDepth, FSlrAlienTech: TXcomSlider;
    FBtnEquip, FBtnOk, FBtnCancel, FBtnRandom: TXcomTextButton;
    FMissionTypes, FTerrainTypes, FAlienRaces, FCrafts: TArray<string>;
    function StartingBaseNode: IYamlNode;
    function NewSave: TXcomSavedGame;
    function SelectedMission: string;
    procedure AddAllResearch;
    procedure AddItems(ABase: TXcomBase; AToCraft: Boolean);
    procedure InitSave;
    procedure LoadChoices;
    procedure LoadBase(const ADocument: IYamlNode);
    procedure SaveChoices;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure RandomClick(AAction: TXcomAction);
    procedure EquipClick(AAction: TXcomAction);
    procedure MissionChange(AAction: TXcomAction);
    procedure CraftChange(AAction: TXcomAction);
    procedure TerrainChange(AAction: TXcomAction);
  public
    /// <param name="AStore">nil: the choices are not kept</param>
    /// <param name="ARandom">nil: a generator seeded with the clock of the system</param>
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomNewBattleNavigator;
      const AStore: IXcomNewBattleStore = nil; const ARandom: IXcomRandom = nil);
    procedure Init; override;
    property Craft: TXcomCraft read FCraft;
    property SavedGame: TXcomSavedGame read FSave;
    property MissionBox: TXcomComboBox read FCbxMission;
    property CraftBox: TXcomComboBox read FCbxCraft;
    property TerrainBox: TXcomComboBox read FCbxTerrain;
    property DifficultyBox: TXcomComboBox read FCbxDifficulty;
    property AlienRaceBox: TXcomComboBox read FCbxAlienRace;
    property DarknessSlider: TXcomSlider read FSlrDarkness;
    property DepthSlider: TXcomSlider read FSlrDepth;
    property AlienTechSlider: TXcomSlider read FSlrAlienTech;
    property OkButton: TXcomTextButton read FBtnOk;
    property CancelButton: TXcomTextButton read FBtnCancel;
    property RandomButton: TXcomTextButton read FBtnRandom;
    property EquipButton: TXcomTextButton read FBtnEquip;
    property MissionTypes: TArray<string> read FMissionTypes;
    property TerrainTypes: TArray<string> read FTerrainTypes;
    property AlienRaces: TArray<string> read FAlienRaces;
    property CraftTypes: TArray<string> read FCrafts;
  end;

implementation

uses
  System.Math, System.Diagnostics, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomUi.Types, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.RuleCraft,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleTerrain, DelphiDoom.XcomMod.UnitStats,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.NewGame,
  DelphiDoom.XcomSave.DefaultSettings, DelphiDoom.XcomSave.SavedGameHolder, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase;

const
  SNoRules = 'XcomMenu: the New Battle screen needs the rules of the game';
  MISSION_BASE_DEFENSE = 'STR_BASE_DEFENSE';
  MISSION_UFO_GROUND_ASSAULT = 'STR_UFO_GROUND_ASSAULT';
  MISSION_UFO_CRASH_RECOVERY = 'STR_UFO_CRASH_RECOVERY';
  UNDERWATER_RACE = '_UNDERWATER';
  SOLDIER_COUNT = 30;
  PROMOTION_TRIES = 5;
  DIFFICULTIES: array[0..4] of string = ('STR_1_BEGINNER', 'STR_2_EXPERIENCED', 'STR_3_VETERAN', 'STR_4_GENIUS',
    'STR_5_SUPERHUMAN');

constructor TXcomNewBattleState.Create(AHost: TXcomStateHost; const ANavigator: IXcomNewBattleNavigator;
  const AStore: IXcomNewBattleStore; const ARandom: IXcomRandom);
var
  LRules: IXcomGameRules;
  LName: string;
  LDifficulty: TArray<string>;
  LIndex: Integer;
  LCrafts, LRaces: TList<string>;
begin
  inherited Create(AHost);
  if (not Supports(Host.Resources, IXcomGameRules, LRules)) or (LRules.Ruleset = nil) then
    raise EArgumentException.Create(SNoRules);
  FRuleset := LRules.Ruleset;
  FNavigator := ANavigator;
  FStore := AStore;
  FRandom := ARandom;
  if FRandom = nil then
    FRandom := TXcomRandom.Create(UInt64(TStopwatch.GetTimeStamp));
  FSettings := TXcomDefaultSaveSettings.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FTxtTitle := TXcomText.Create(320, 17, 0, 9);
  FTxtMapOptions := TXcomText.Create(148, 9, 8, 68);
  FFrameLeft := TXcomFrame.Create(148, 96, 8, 78);
  FTxtAlienOptions := TXcomText.Create(148, 9, 164, 68);
  FFrameRight := TXcomFrame.Create(148, 96, 164, 78);
  FTxtMission := TXcomText.Create(100, 9, 8, 30);
  FCbxMission := TXcomComboBox.Create(Self, 214, 16, 98, 26, False);
  FTxtCraft := TXcomText.Create(100, 9, 8, 50);
  FCbxCraft := TXcomComboBox.Create(Self, 106, 16, 98, 46, False);
  FBtnEquip := TXcomTextButton.Create(106, 16, 206, 46);
  FTxtDarkness := TXcomText.Create(120, 9, 22, 83);
  FSlrDarkness := TXcomSlider.Create(120, 16, 22, 93);
  FTxtTerrain := TXcomText.Create(120, 9, 22, 113);
  FCbxTerrain := TXcomComboBox.Create(Self, 120, 16, 22, 123, False);
  FTxtDepth := TXcomText.Create(120, 9, 22, 143);
  FSlrDepth := TXcomSlider.Create(120, 16, 22, 153);
  FTxtDifficulty := TXcomText.Create(120, 9, 178, 83);
  FCbxDifficulty := TXcomComboBox.Create(Self, 120, 16, 178, 93, False);
  FTxtAlienRace := TXcomText.Create(120, 9, 178, 113);
  FCbxAlienRace := TXcomComboBox.Create(Self, 120, 16, 178, 123, False);
  FTxtAlienTech := TXcomText.Create(120, 9, 178, 143);
  FSlrAlienTech := TXcomSlider.Create(120, 16, 178, 153);
  FBtnOk := TXcomTextButton.Create(100, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(100, 16, 110, 176);
  FBtnRandom := TXcomTextButton.Create(100, 16, 212, 176);
  SetInterface('newBattleMenu');
  Add(FWindow, 'window', 'newBattleMenu');
  Add(FTxtTitle, 'heading', 'newBattleMenu');
  Add(FTxtMapOptions, 'heading', 'newBattleMenu');
  Add(FFrameLeft, 'frames', 'newBattleMenu');
  Add(FTxtAlienOptions, 'heading', 'newBattleMenu');
  Add(FFrameRight, 'frames', 'newBattleMenu');
  Add(FTxtMission, 'text', 'newBattleMenu');
  Add(FTxtCraft, 'text', 'newBattleMenu');
  Add(FBtnEquip, 'button1', 'newBattleMenu');
  Add(FTxtDarkness, 'text', 'newBattleMenu');
  Add(FSlrDarkness, 'button1', 'newBattleMenu');
  Add(FTxtDepth, 'text', 'newBattleMenu');
  Add(FSlrDepth, 'button1', 'newBattleMenu');
  Add(FTxtTerrain, 'text', 'newBattleMenu');
  Add(FTxtDifficulty, 'text', 'newBattleMenu');
  Add(FTxtAlienRace, 'text', 'newBattleMenu');
  Add(FTxtAlienTech, 'text', 'newBattleMenu');
  Add(FSlrAlienTech, 'button1', 'newBattleMenu');
  Add(FBtnOk, 'button2', 'newBattleMenu');
  Add(FBtnCancel, 'button2', 'newBattleMenu');
  Add(FBtnRandom, 'button2', 'newBattleMenu');
  Add(FCbxTerrain, 'button1', 'newBattleMenu');
  Add(FCbxAlienRace, 'button1', 'newBattleMenu');
  Add(FCbxDifficulty, 'button1', 'newBattleMenu');
  Add(FCbxCraft, 'button1', 'newBattleMenu');
  Add(FCbxMission, 'button1', 'newBattleMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_MISSION_GENERATOR'));
  FTxtMapOptions.SetText(Tr('STR_MAP_OPTIONS'));
  FFrameLeft.SetThickness(3);
  FTxtAlienOptions.SetText(Tr('STR_ALIEN_OPTIONS'));
  FFrameRight.SetThickness(3);
  FTxtMission.SetText(Tr('STR_MISSION'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));
  FTxtDarkness.SetText(Tr('STR_MAP_DARKNESS'));
  FTxtDepth.SetText(Tr('STR_MAP_DEPTH'));
  FTxtTerrain.SetText(Tr('STR_MAP_TERRAIN'));
  FTxtDifficulty.SetText(Tr('STR_DIFFICULTY'));
  FTxtAlienRace.SetText(Tr('STR_ALIEN_RACE'));
  FTxtAlienTech.SetText(Tr('STR_ALIEN_TECH_LEVEL'));
  FMissionTypes := FRuleset.AlienDeployments.Index;
  FCbxMission.SetOptions(FMissionTypes, True);
  FCbxMission.OnChange(MissionChange);
  LCrafts := TList<string>.Create;
  LRaces := TList<string>.Create;
  try
    // the crafts that carry soldiers
    for LName in FRuleset.Crafts.Index do
      if FRuleset.Crafts.Find(LName).Soldiers > 0 then
        LCrafts.Add(LName);
    FCrafts := LCrafts.ToArray;
    for LName in FRuleset.AlienRaces.Index do
      if Pos(UNDERWATER_RACE, LName) = 0 then
        LRaces.Add(LName);
    FAlienRaces := LRaces.ToArray;
  finally
    LRaces.Free;
    LCrafts.Free;
  end;
  FCbxCraft.SetOptions(FCrafts, True);
  FCbxCraft.OnChange(CraftChange);
  FSlrDarkness.SetRange(0, 15);
  FSlrDepth.SetRange(1, 3);
  FCbxTerrain.OnChange(TerrainChange);
  SetLength(LDifficulty, Length(DIFFICULTIES));
  for LIndex := 0 to High(DIFFICULTIES) do
    LDifficulty[LIndex] := Tr(DIFFICULTIES[LIndex]).Text;
  FCbxDifficulty.SetOptions(LDifficulty);
  FCbxAlienRace.SetOptions(FAlienRaces, True);
  FSlrAlienTech.SetRange(0, Length(FRuleset.Settings.AlienItemLevels) - 1);
  FBtnEquip.SetText(Tr('STR_EQUIP_CRAFT'));
  FBtnEquip.OnMouseClick(EquipClick);
  FBtnRandom.SetText(Tr('STR_RANDOMIZE'));
  FBtnRandom.OnMouseClick(RandomClick);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  LoadChoices;
end;

procedure TXcomNewBattleState.Init;
begin
  inherited Init;
  if FCraft = nil then
    LoadChoices;
end;

function TXcomNewBattleState.SelectedMission: string;
begin
  Result := FMissionTypes[FCbxMission.GetSelected];
end;

function TXcomNewBattleState.StartingBaseNode: IYamlNode;
var
  LIndex: Integer;
begin
  // Mod keeps the keys of "startingBase" one by one; Base::load wants them as one map node
  Result := TYamlFactory.CreateNode(ntMap);
  for LIndex := 0 to FRuleset.StartingBase.Count - 1 do
    Result.Child(YamlStringToText(FRuleset.StartingBase.Key(LIndex))).Assign(FRuleset.StartingBase.Value(LIndex));
end;

function TXcomNewBattleState.NewSave: TXcomSavedGame;
begin
  // Game::setSavedGame: the session owns the saved game and its rules; the one before goes away
  FCraft := nil;
  FRules := TXcomRulesetRules.Create(FRuleset);
  FSave := TXcomSavedGame.Create;
  Host.SetSession(TXcomSavedGameHolder.Create(FSave, FRules, FRandom));
  Result := FSave;
end;

procedure TXcomNewBattleState.AddAllResearch;
var
  LName: string;
begin
  for LName in FRuleset.Research.Index do
    FSave.Discovered.Add(FRuleset.Research.Find(LName));
end;

procedure TXcomNewBattleState.AddItems(ABase: TXcomBase; AToCraft: Boolean);
var
  LName: string;
  LRule: TXcomRuleItem;
begin
  for LName in FRuleset.Items.Index do
  begin
    LRule := FRuleset.Items.Find(LName);
    if (LRule.BattleType <> TXcomRuleItem.BT_CORPSE) and LRule.Recoverable then
    begin
      ABase.StorageItems.AddItem(LName, 1);
      if AToCraft and (LRule.BattleType <> TXcomRuleItem.BT_NONE) and (not LRule.FixedWeapon) and
        (LRule.BigSprite > -1) then
        FCraft.Items.AddItem(LName, 1);
    end;
  end;
end;

procedure TXcomNewBattleState.InitSave;
var
  LBase: TXcomBase;
  LMaker: TXcomNewGame;
  LSoldier: TXcomSoldier;
  LStats: TXcomUnitStats;
  LTypes: TArray<string>;
  LIndex, LTry: Integer;
begin
  NewSave;
  LBase := TXcomBase.Create;
  FSave.Bases.Add(LBase);
  LBase.Load(StartingBaseNode, FRuleset, FRules, nil, FSettings, True, False, True);
  // kill everything we don't want in this base
  LBase.Soldiers.Clear;
  LBase.Crafts.Clear;
  LBase.StorageItems.Contents.Clear;
  FCraft := TXcomCraft.Create(FRuleset.Crafts.Find(FCrafts[FCbxCraft.GetSelected]), LBase, 1);
  LBase.Crafts.Add(FCraft);
  // generate soldiers
  LTypes := FRuleset.Soldiers.Index;
  LMaker := TXcomNewGame.Create(FRuleset, FRules, FSettings, FRandom);
  try
    for LIndex := 0 to SOLDIER_COUNT - 1 do
    begin
      LSoldier := LMaker.GenSoldier(FSave, LTypes[FRandom.Generate(0, High(LTypes))]);
      LBase.Soldiers.Add(LSoldier);
      for LTry := 1 to PROMOTION_TRIES do
      begin
        // RNG::percent(70)
        if FRandom.Generate(0, 99) < 70 then
          Continue;
        LSoldier.PromoteRank;
        LStats := LSoldier.CurrentStats;
        Inc(LStats.TimeUnits, FRandom.Generate(0, 5));
        Inc(LStats.Stamina, FRandom.Generate(0, 5));
        Inc(LStats.Health, FRandom.Generate(0, 5));
        Inc(LStats.Bravery, FRandom.Generate(0, 5));
        Inc(LStats.Reactions, FRandom.Generate(0, 5));
        Inc(LStats.Firing, FRandom.Generate(0, 5));
        Inc(LStats.Throwing, FRandom.Generate(0, 5));
        Inc(LStats.Strength, FRandom.Generate(0, 5));
        Inc(LStats.PsiStrength, FRandom.Generate(0, 5));
        Inc(LStats.Melee, FRandom.Generate(0, 5));
        Inc(LStats.PsiSkill, FRandom.Generate(0, 20));
        LSoldier.CurrentStats := LStats;
      end;
      LStats := LSoldier.CurrentStats;
      // keep it a multiple of 10
      LStats.Bravery := Ceil(LStats.Bravery / 10.0) * 10;
      LSoldier.CurrentStats := LStats;
      if LIndex < FCraft.Rules.Soldiers then
        LSoldier.Craft := FCraft;
    end;
  finally
    LMaker.Free;
  end;
  AddItems(LBase, True);
  AddAllResearch;
  MissionChange(nil);
end;

procedure TXcomNewBattleState.LoadChoices;
var
  LDocument: IYamlNode;
begin
  LDocument := nil;
  if Assigned(FStore) then
    LDocument := FStore.Load;
  if (LDocument = nil) or (not LDocument.IsMap) then
  begin
    InitSave;
    Exit;
  end;
  try
    FCbxMission.SetSelected(Min(TXcomNodeReader.ReadInteger(LDocument, 'mission', 0), High(FMissionTypes)));
    MissionChange(nil);
    FCbxCraft.SetSelected(Min(TXcomNodeReader.ReadInteger(LDocument, 'craft', 0), High(FCrafts)));
    FSlrDarkness.SetValue(TXcomNodeReader.ReadInteger(LDocument, 'darkness', 0));
    FCbxTerrain.SetSelected(Min(TXcomNodeReader.ReadInteger(LDocument, 'terrain', 0), High(FTerrainTypes)));
    TerrainChange(nil);
    FCbxAlienRace.SetSelected(Min(TXcomNodeReader.ReadInteger(LDocument, 'alienRace', 0), High(FAlienRaces)));
    FCbxDifficulty.SetSelected(TXcomNodeReader.ReadInteger(LDocument, 'difficulty', 0));
    FSlrAlienTech.SetValue(TXcomNodeReader.ReadInteger(LDocument, 'alienTech', 0));
    if TXcomNodeReader.Field(LDocument, 'base').IsDefined then
      LoadBase(TXcomNodeReader.Field(LDocument, 'base'))
    else
      InitSave;
  except
    // YAML::Exception: a file that does not say what it should starts from the defaults
    on EYamlException do
      InitSave;
  end;
end;

procedure TXcomNewBattleState.LoadBase(const ADocument: IYamlNode);
var
  LBase: TXcomBase;
  LCraftType: string;
  LIndex: Integer;
  LContents: TXcomStringMap<Integer>;
begin
  NewSave;
  LBase := TXcomBase.Create;
  FSave.Bases.Add(LBase);
  LBase.Load(ADocument, FRuleset, FRules, nil, FSettings, False, False, False);
  AddAllResearch;
  // generate items
  LBase.StorageItems.Contents.Clear;
  AddItems(LBase, False);
  // fix invalid contents
  if LBase.Crafts.Count = 0 then
  begin
    LCraftType := FCrafts[FCbxCraft.GetSelected];
    FCraft := TXcomCraft.Create(FRuleset.Crafts.Find(LCraftType), LBase, FSave.GetId(LCraftType));
    LBase.Crafts.Add(FCraft);
  end
  else
  begin
    FCraft := LBase.Crafts.First;
    LContents := FCraft.Items.Contents;
    for LIndex := 0 to LContents.Count - 1 do
      if FRuleset.Items.Find(LContents.Key(LIndex)) = nil then
        LContents.SetValue(LContents.Key(LIndex), 0);
  end;
end;

procedure TXcomNewBattleState.SaveChoices;
var
  LNode: IYamlNode;
begin
  if (not Assigned(FStore)) or (FSave = nil) or (FSave.Bases.Count = 0) then
    Exit;
  LNode := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(LNode, 'mission', FCbxMission.GetSelected);
  TXcomNodeWriter.SetInteger(LNode, 'craft', FCbxCraft.GetSelected);
  TXcomNodeWriter.SetInteger(LNode, 'darkness', FSlrDarkness.GetValue);
  TXcomNodeWriter.SetInteger(LNode, 'terrain', FCbxTerrain.GetSelected);
  TXcomNodeWriter.SetInteger(LNode, 'alienRace', FCbxAlienRace.GetSelected);
  TXcomNodeWriter.SetInteger(LNode, 'difficulty', FCbxDifficulty.GetSelected);
  TXcomNodeWriter.SetInteger(LNode, 'alienTech', FSlrAlienTech.GetValue);
  TXcomNodeWriter.SetNode(LNode, 'base', FSave.Bases.First.Save(FSettings));
  FStore.Save(LNode);
end;

procedure TXcomNewBattleState.OkClick(AAction: TXcomAction);
var
  LChoice: TXcomNewBattleChoice;
  LDeployment: TXcomAlienDeployment;
  LNavigator: IXcomNewBattleNavigator;
begin
  SaveChoices;
  if (SelectedMission <> MISSION_BASE_DEFENSE) and (FCraft.NumSoldiers(FSave.Bases.First.Soldiers) = 0) and
    (FCraft.NumVehicles = 0) then
    Exit;
  LChoice := Default(TXcomNewBattleChoice);
  LChoice.MissionType := SelectedMission;
  LChoice.Terrain := FTerrainTypes[FCbxTerrain.GetSelected];
  LChoice.AlienRace := FAlienRaces[FCbxAlienRace.GetSelected];
  LDeployment := FRuleset.AlienDeployments.Find(SelectedMission);
  if SelectedMission = MISSION_BASE_DEFENSE then
    // base defense
    LChoice.Base := FSave.Bases.First
  else if LDeployment.IsAlienBase then
  begin
    // alien base
    LChoice.AlienBase := TXcomAlienBase.Create(FRules.Deployment(SelectedMission));
    FSave.AlienBases.Add(LChoice.AlienBase);
    LChoice.AlienBase.Id := 1;
    LChoice.AlienBase.AlienRace := LChoice.AlienRace;
    FCraft.SetDestination(LChoice.AlienBase);
  end
  else if FRuleset.Ufos.Find(SelectedMission) <> nil then
  begin
    // ufo assault
    LChoice.Ufo := TXcomUfo.Create(FRuleset.Ufos.Find(SelectedMission));
    FSave.Ufos.Add(LChoice.Ufo);
    LChoice.Ufo.Id := 1;
    FCraft.SetDestination(LChoice.Ufo);
    // either ground assault or ufo crash
    if FRandom.Generate(0, 1) = 1 then
    begin
      LChoice.Ufo.Status := TXcomUfo.STATUS_LANDED;
      LChoice.MissionType := MISSION_UFO_GROUND_ASSAULT;
    end
    else
    begin
      LChoice.Ufo.Status := TXcomUfo.STATUS_CRASHED;
      LChoice.MissionType := MISSION_UFO_CRASH_RECOVERY;
    end;
  end
  else
  begin
    // mission site: which alien mission does not matter
    LChoice.Site := TXcomMissionSite.Create(FRules.Mission(FRuleset.AlienMissions.Index[0]),
      FRules.Deployment(SelectedMission));
    FSave.MissionSites.Add(LChoice.Site);
    LChoice.Site.Id := 1;
    LChoice.Site.AlienRace := LChoice.AlienRace;
    FCraft.SetDestination(LChoice.Site);
  end;
  if LChoice.Base = nil then
  begin
    FCraft.SetSpeed(0);
    LChoice.Craft := FCraft;
  end;
  FSave.Difficulty := FCbxDifficulty.GetSelected;
  LChoice.Darkness := FSlrDarkness.GetValue;
  LChoice.AlienItemLevel := FSlrAlienTech.GetValue;
  LChoice.Depth := FSlrDepth.GetValue;
  // the state goes away: what it needs after that is kept in locals
  LNavigator := FNavigator;
  FCraft := nil;
  Host.PopState;
  if Assigned(LNavigator) then
    LNavigator.Launch(LChoice);
end;

procedure TXcomNewBattleState.CancelClick(AAction: TXcomAction);
begin
  SaveChoices;
  FCraft := nil;
  FSave := nil;
  FRules := nil;
  Host.SetSession(nil);
  Host.PopState;
end;

procedure TXcomNewBattleState.RandomClick(AAction: TXcomAction);
begin
  InitSave;
  FCbxMission.SetSelected(FRandom.Generate(0, High(FMissionTypes)));
  MissionChange(nil);
  FCbxCraft.SetSelected(FRandom.Generate(0, High(FCrafts)));
  CraftChange(nil);
  FSlrDarkness.SetValue(FRandom.Generate(0, 15));
  FCbxTerrain.SetSelected(FRandom.Generate(0, High(FTerrainTypes)));
  TerrainChange(nil);
  FCbxAlienRace.SetSelected(FRandom.Generate(0, High(FAlienRaces)));
  FCbxDifficulty.SetSelected(FRandom.Generate(0, 4));
  FSlrAlienTech.SetValue(FRandom.Generate(0, Length(FRuleset.Settings.AlienItemLevels) - 1));
end;

procedure TXcomNewBattleState.EquipClick(AAction: TXcomAction);
begin
  if Assigned(FNavigator) and (FSave <> nil) then
    FNavigator.EquipCraft(FSave.Bases.First);
end;

procedure TXcomNewBattleState.MissionChange(AAction: TXcomAction);
var
  LDeployment: TXcomAlienDeployment;
  LTerrains: TList<string>;
  LGlobeTerrains, LStrings: TArray<string>;
  LName: string;
  LIndex: Integer;
begin
  LDeployment := FRuleset.AlienDeployments.Find(SelectedMission);
  // the terrains of the mission and the ones of the globe for it, each once and in byte order (a std::set)
  if Length(LDeployment.Terrains) = 0 then
    LGlobeTerrains := FRuleset.Globe.GetTerrains('')
  else
    LGlobeTerrains := FRuleset.Globe.GetTerrains(LDeployment.DeploymentType);
  LTerrains := TList<string>.Create;
  try
    for LName in LDeployment.Terrains do
      if not LTerrains.Contains(LName) then
        LTerrains.Add(LName);
    for LName in LGlobeTerrains do
      if not LTerrains.Contains(LName) then
        LTerrains.Add(LName);
    LTerrains.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := XcomCompareUtf8(ALeft, ARight);
      end));
    FTerrainTypes := LTerrains.ToArray;
  finally
    LTerrains.Free;
  end;
  SetLength(LStrings, Length(FTerrainTypes));
  for LIndex := 0 to High(FTerrainTypes) do
    LStrings[LIndex] := 'MAP_' + FTerrainTypes[LIndex];
  // hide controls that don't apply to mission
  FTxtDarkness.Visible := LDeployment.Shade = -1;
  FSlrDarkness.Visible := LDeployment.Shade = -1;
  FTxtTerrain.Visible := Length(FTerrainTypes) > 1;
  FCbxTerrain.Visible := Length(FTerrainTypes) > 1;
  FCbxTerrain.SetOptions(LStrings, True);
  FCbxTerrain.SetSelected(0);
  TerrainChange(nil);
end;

procedure TXcomNewBattleState.CraftChange(AAction: TXcomAction);
var
  LCurrent, LMax, LIndex: Integer;
  LSoldiers: TObjectList<TXcomSoldier>;
begin
  FCraft.ChangeRules(FRuleset.Crafts.Find(FCrafts[FCbxCraft.GetSelected]));
  LSoldiers := FSave.Bases.First.Soldiers;
  LCurrent := FCraft.NumSoldiers(LSoldiers);
  LMax := FCraft.Rules.Soldiers;
  // the last soldiers get off a craft that has become too small
  LIndex := LSoldiers.Count - 1;
  while (LIndex >= 0) and (LCurrent > LMax) do
  begin
    if LSoldiers[LIndex].Craft = FCraft then
    begin
      LSoldiers[LIndex].Craft := nil;
      Dec(LCurrent);
    end;
    Dec(LIndex);
  end;
end;

procedure TXcomNewBattleState.TerrainChange(AAction: TXcomAction);
var
  LDeployment: TXcomAlienDeployment;
  LTerrain: TXcomRuleTerrain;
  LMinDepth, LMaxDepth: Integer;
  LUnderwater: Boolean;
begin
  LDeployment := FRuleset.AlienDeployments.Find(SelectedMission);
  LMinDepth := 0;
  LMaxDepth := 0;
  LUnderwater := LDeployment.MaxDepth > 0;
  if (not LUnderwater) and (Length(FTerrainTypes) > 0) then
  begin
    LTerrain := FRuleset.Terrains.Find(FTerrainTypes[FCbxTerrain.GetSelected]);
    LUnderwater := (LTerrain <> nil) and (LTerrain.MaxDepth > 0);
  end;
  if (not LUnderwater) and (Length(LDeployment.Terrains) > 0) then
  begin
    LTerrain := FRuleset.Terrains.Find(LDeployment.Terrains[0]);
    LUnderwater := (LTerrain <> nil) and (LTerrain.MaxDepth > 0);
  end;
  if LUnderwater then
  begin
    LMinDepth := 1;
    LMaxDepth := 3;
  end;
  FTxtDepth.Visible := LMinDepth <> LMaxDepth;
  FSlrDepth.Visible := LMinDepth <> LMaxDepth;
  FSlrDepth.SetRange(LMinDepth, LMaxDepth);
  FSlrDepth.SetValue(LMinDepth);
end;

end.
