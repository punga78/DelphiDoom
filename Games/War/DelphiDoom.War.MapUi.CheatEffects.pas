{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the cheats of the map                              }
{                                                                              }
{  Port of war1 (acoto87/war1), war_cheats.c (wcheat_apply* that need a map),   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CheatEffects;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Economy, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Intf;

type
  /// <summary>
  ///   What the cheats do on a map: gold and lumber, the spells and the upgrades of the player, the end of the demo, the
  ///   god mode, victory and defeat, the fog, the skip to a briefing, the faster building, the modes of editing and
  ///   "Debug render". The cheats of the settings (cheats on and off, music, sound, scale, speed) are given to the
  ///   next effects, which is where they were before the map. Nothing but "Corwin of Amber" (the next ones) does anything
  ///   with the cheats off. Defects of the original kept: "Add unit" shows the part of the argument that the two words did
  ///   not use (nothing, for the usual two); an unknown unit or race leaves the mode off and shows nothing; "Edit" with
  ///   something that is not a mode turns the editing off and shows nothing
  /// </summary>
  TWarMapCheatEffects = class(TInterfacedObject, IWarCheatEffects)
  strict private
    FContext: TWarModelContext;
    FEconomy: TWarEconomy;
    // the target is the scene, which owns these effects through its cheat line: a counted reference would never let go
    [weak] FTarget: IWarMapCheatTarget;
    FSettings: IWarGameSettings;
    FDebugRender: IWarDebugRender;
    FNext: IWarCheatEffects;
    function Wabbit: AnsiString;
    function Gold: AnsiString;
    function Spells: AnsiString;
    function Upgrades: AnsiString;
    function GodMode: AnsiString;
    function Skip(AHumans: Boolean; const AArgument: AnsiString): AnsiString;
    function Edit(const AArgument: AnsiString): AnsiString;
    function ToggleMode(AMode: TWarMapEditMode; const AName: AnsiString): AnsiString;
    function AddUnit(const AArgument: AnsiString): AnsiString;
    function RaceUnit(const APart: AnsiString; AHumans, AOrcs: Integer; out AType: Integer): Boolean;
    function NextToken(var ARemaining: AnsiString; out AToken: AnsiString): Boolean;
  public
    /// <summary>Nothing is owned; the next effects, the debug render and the settings may be nil</summary>
    constructor Create(const AContext: TWarModelContext; const AEconomy: TWarEconomy; const ATarget: IWarMapCheatTarget;
      const ASettings: IWarGameSettings; const ADebugRender: IWarDebugRender; const ANext: IWarCheatEffects);
    function Apply(const AName: string; const AArgument: AnsiString): AnsiString;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Purse,
  DelphiDoom.War.Ui.Strings, DelphiDoom.War.MapUi.CommandData.Data,
  DelphiDoom.War.MapUi.UnitNames.Data;

const
  /// <summary>CHEAT_GOLD_INCREASE and CHEAT_WOOD_INCREASE</summary>
  CHEAT_GOLD_INCREASE = 10000;
  CHEAT_WOOD_INCREASE = 5000;
  FEEDBACK_WABBIT = 'cheat enabled you wascally wabbit';

{ TWarMapCheatEffects }

constructor TWarMapCheatEffects.Create(const AContext: TWarModelContext; const AEconomy: TWarEconomy;
  const ATarget: IWarMapCheatTarget; const ASettings: IWarGameSettings; const ADebugRender: IWarDebugRender;
  const ANext: IWarCheatEffects);
begin
  inherited Create;
  FContext := AContext;
  FEconomy := AEconomy;
  FTarget := ATarget;
  FSettings := ASettings;
  FDebugRender := ADebugRender;
  FNext := ANext;
end;

function TWarMapCheatEffects.Wabbit: AnsiString;
begin
  Result := FEEDBACK_WABBIT;
end;

function TWarMapCheatEffects.Gold: AnsiString;
begin
  FEconomy.IncreaseResources(FContext.Players[0], CHEAT_GOLD_INCREASE, CHEAT_WOOD_INCREASE);
  Result := Wabbit;
end;

function TWarMapCheatEffects.Spells: AnsiString;
const
  FEATURES: array[0..11] of Integer = (WAR_FEATURE_SPELL_HEALING, WAR_FEATURE_SPELL_RAISE_DEAD,
    WAR_FEATURE_SPELL_FAR_SIGHT, WAR_FEATURE_SPELL_DARK_VISION, WAR_FEATURE_SPELL_INVISIBILITY,
    WAR_FEATURE_SPELL_UNHOLY_ARMOR, WAR_FEATURE_SPELL_SCORPION, WAR_FEATURE_SPELL_SPIDER,
    WAR_FEATURE_SPELL_RAIN_OF_FIRE, WAR_FEATURE_SPELL_POISON_CLOUD, WAR_FEATURE_SPELL_WATER_ELEMENTAL,
    WAR_FEATURE_SPELL_DAEMON);
  UPGRADES: array[0..11] of Integer = (WAR_UPGRADE_SCORPIONS, WAR_UPGRADE_SPIDERS, WAR_UPGRADE_RAIN_OF_FIRE,
    WAR_UPGRADE_POISON_CLOUD, WAR_UPGRADE_WATER_ELEMENTAL, WAR_UPGRADE_DAEMON, WAR_UPGRADE_HEALING,
    WAR_UPGRADE_RAISE_DEAD, WAR_UPGRADE_FAR_SIGHT, WAR_UPGRADE_DARK_VISION, WAR_UPGRADE_INVISIBILITY,
    WAR_UPGRADE_UNHOLY_ARMOR);
var
  LPlayer: PWarPlayerInfo;
  LIndex: Integer;
begin
  LPlayer := FContext.Players[0];
  for LIndex := 0 to High(FEATURES) do
    LPlayer^.Features[FEATURES[LIndex] div 2] := 1;
  for LIndex := 0 to High(UPGRADES) do
  begin
    LPlayer^.Upgrades[UPGRADES[LIndex] div 2].Allowed := FContext.Database.GetUpgradeStats(UPGRADES[LIndex]).MaxLevel;
    while LPlayer^.Upgrades[UPGRADES[LIndex] div 2].Level < LPlayer^.Upgrades[UPGRADES[LIndex] div 2].Allowed do
      FEconomy.IncreaseUpgradeLevel(LPlayer, UPGRADES[LIndex]);
  end;
  Result := Wabbit;
end;

function TWarMapCheatEffects.Upgrades: AnsiString;
const
  UPGRADES: array[0..4] of Integer = (WAR_UPGRADE_ARROWS, WAR_UPGRADE_SPEARS, WAR_UPGRADE_SWORDS, WAR_UPGRADE_AXES,
    WAR_UPGRADE_SHIELD);
var
  LPlayer: PWarPlayerInfo;
  LIndex: Integer;
begin
  LPlayer := FContext.Players[0];
  for LIndex := 0 to High(UPGRADES) do
  begin
    LPlayer^.Upgrades[UPGRADES[LIndex] div 2].Allowed := FContext.Database.GetUpgradeStats(UPGRADES[LIndex]).MaxLevel;
    while LPlayer^.Upgrades[UPGRADES[LIndex] div 2].Level < LPlayer^.Upgrades[UPGRADES[LIndex] div 2].Allowed do
      FEconomy.IncreaseUpgradeLevel(LPlayer, UPGRADES[LIndex]);
  end;
  Result := Wabbit;
end;

function TWarMapCheatEffects.GodMode: AnsiString;
begin
  FContext.Players[0]^.GodMode := not FContext.Players[0]^.GodMode;
  Result := Wabbit;
end;

function TWarMapCheatEffects.Skip(AHumans: Boolean; const AArgument: AnsiString): AnsiString;
var
  LLevel: Integer;
begin
  Result := '';
  // only the two missions of the demo can be skipped to
  if TWarStrings.TryParseS32(AArgument, LLevel) and (LLevel > 0) and (LLevel <= 2) then
  begin
    if AHumans then
      FTarget.SkipToBriefing(wraHumans, WAR_CAMPAIGN_HUMANS_01 + 2 * (LLevel - 1))
    else
      FTarget.SkipToBriefing(wraOrcs, WAR_CAMPAIGN_ORCS_01 + 2 * (LLevel - 1));
  end;
end;

function TWarMapCheatEffects.ToggleMode(AMode: TWarMapEditMode; const AName: AnsiString): AnsiString;
begin
  if FTarget.GetEditMode = AMode then
  begin
    FTarget.SetEditing(wemNone, 0);
    Result := AName + ' off';
  end
  else
  begin
    FTarget.SetEditing(AMode, 0);
    Result := AName + ' on';
  end;
end;

function TWarMapCheatEffects.Edit(const AArgument: AnsiString): AnsiString;
begin
  Result := '';
  FTarget.SetEditing(wemNone, 0);
  if TWarStrings.EqualsIgnoreCase(AArgument, 'off') then
    Result := 'Edit off'
  else if TWarStrings.EqualsIgnoreCase(AArgument, 'trees') then
  begin
    FTarget.SetEditing(wemTrees, 0);
    Result := 'Edit trees on';
  end
  else if TWarStrings.EqualsIgnoreCase(AArgument, 'walls') then
  begin
    FTarget.SetEditing(wemWalls, 0);
    Result := 'Edit walls on';
  end
  else if TWarStrings.EqualsIgnoreCase(AArgument, 'roads') then
  begin
    FTarget.SetEditing(wemRoads, 0);
    Result := 'Edit roads on';
  end
  else if TWarStrings.EqualsIgnoreCase(AArgument, 'ruins') then
  begin
    FTarget.SetEditing(wemRuins, 0);
    Result := 'Edit ruins on';
  end;
end;

function TWarMapCheatEffects.NextToken(var ARemaining: AnsiString; out AToken: AnsiString): Boolean;
var
  LStart: Integer;
  LEnd: Integer;
begin
  // wsv_nextToken with a space as the separator: the spaces before the token are skipped, the rest starts at the next space
  LStart := 1;
  while (LStart <= Length(ARemaining)) and (ARemaining[LStart] = ' ') do
    Inc(LStart);
  AToken := '';
  if LStart > Length(ARemaining) then
  begin
    ARemaining := '';
    Exit(False);
  end;
  LEnd := LStart;
  while (LEnd <= Length(ARemaining)) and (ARemaining[LEnd] <> ' ') do
    Inc(LEnd);
  AToken := Copy(ARemaining, LStart, LEnd - LStart);
  ARemaining := Copy(ARemaining, LEnd, MaxInt);
  Result := True;
end;

function TWarMapCheatEffects.RaceUnit(const APart: AnsiString; AHumans, AOrcs: Integer; out AType: Integer): Boolean;
begin
  Result := True;
  if TWarStrings.StartsWithIgnoreCase(APart, 'HUMANS') then
    AType := AHumans
  else if TWarStrings.StartsWithIgnoreCase(APart, 'ORCS') then
    AType := AOrcs
  else
    Result := False;
end;

function TWarMapCheatEffects.AddUnit(const AArgument: AnsiString): AnsiString;
var
  LRemaining: AnsiString;
  LPart1: AnsiString;
  LPart2: AnsiString;
  LPart3: AnsiString;
  LType: Integer;
  LIndex: Integer;
  LFound: Boolean;
begin
  Result := '';
  FTarget.SetEditing(wemNone, 0);
  if TWarStrings.StartsWithIgnoreCase(AArgument, 'off') then
    Exit('Add unit off');
  LRemaining := AArgument;
  if not NextToken(LRemaining, LPart1) then
    LPart1 := LRemaining;
  NextToken(LRemaining, LPart2);
  LFound := False;
  LType := 0;
  if TWarStrings.EqualsIgnoreCase(LPart1, 'CATAPULT') then
    LFound := RaceUnit(LPart2, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS, LType)
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'FARM') then
    LFound := RaceUnit(LPart2, WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, LType)
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'BARRACKS') then
    LFound := RaceUnit(LPart2, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS, LType)
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'TOWER') then
    LFound := RaceUnit(LPart2, WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS, LType)
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'TOWN') and TWarStrings.EqualsIgnoreCase(LPart2, 'HALL') then
  begin
    NextToken(LRemaining, LPart3);
    LFound := RaceUnit(LPart3, WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS, LType);
  end
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'MILL') then
    LFound := RaceUnit(LPart2, WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_LUMBERMILL_ORCS, LType)
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'BLACKSMITH') then
    LFound := RaceUnit(LPart2, WAR_UNIT_BLACKSMITH_HUMANS, WAR_UNIT_BLACKSMITH_ORCS, LType)
  else if TWarStrings.EqualsIgnoreCase(LPart1, 'CORPSE') then
    LFound := RaceUnit(LPart2, WAR_UNIT_HUMAN_CORPSE, WAR_UNIT_ORC_CORPSE, LType)
  else
  begin
    // the other names (and a "TOWN" that is not followed by "HALL"): the first row of the table with that name; the index
    // of the row is the type of the unit
    for LIndex := 0 to High(WAR_UNIT_NAMES) do
      if TWarStrings.EqualsIgnoreCase(LPart1, WAR_UNIT_NAMES[LIndex].Name) then
      begin
        LType := LIndex;
        LFound := True;
        Break;
      end;
  end;
  if LFound then
  begin
    FTarget.SetEditing(wemAddUnit, LType);
    // the argument that is left: the original prints it, after the words that were taken from it
    Result := 'Add unit ' + LRemaining;
  end;
end;

function TWarMapCheatEffects.Apply(const AName: string; const AArgument: AnsiString): AnsiString;
begin
  Result := '';
  if (not Assigned(FSettings)) or (AName = 'Corwin of Amber') or FSettings.CheatsEnabled then
  begin
    if AName = 'Pot of gold' then
      Exit(Gold)
    else if AName = 'Eye of newt' then
      Exit(Spells)
    else if AName = 'Iron forge' then
      Exit(Upgrades)
    else if AName = 'Ides of march' then
    begin
      FTarget.ShowDemoEnd;
      Exit('');
    end
    else if AName = 'There can be only one' then
      Exit(GodMode)
    else if AName = 'Yours truly' then
    begin
      FTarget.ConcludeMap(wlrWin);
      Exit(Wabbit);
    end
    else if AName = 'Crushing defeat' then
    begin
      FTarget.ConcludeMap(wlrLose);
      Exit(Wabbit);
    end
    else if AName = 'Sally Shears' then
    begin
      FTarget.ToggleFog;
      Exit(Wabbit);
    end
    else if AName = 'Human' then
      Exit(Skip(True, AArgument))
    else if AName = 'Orc' then
      Exit(Skip(False, AArgument))
    else if AName = 'Hurry up guys' then
    begin
      FContext.HurryUp := not FContext.HurryUp;
      Exit(Wabbit);
    end
    else if AName = 'Edit' then
      Exit(Edit(AArgument))
    else if AName = 'Add unit' then
      Exit(AddUnit(AArgument))
    else if AName = 'Rain of fire' then
      Exit(ToggleMode(wemRainOfFire, 'Rain of fire'))
    else if AName = 'Poison cloud' then
      Exit(ToggleMode(wemPoisonCloud, 'Poison cloud'))
    else if AName = 'Raise dead' then
      Exit(ToggleMode(wemRaiseDead, 'Raise dead'))
    else if AName = 'Debug render' then
    begin
      if Assigned(FDebugRender) then
        Exit(FDebugRender.ApplyCheat(AArgument));
      Exit('');
    end;
  end;
  if Assigned(FNext) then
    Result := FNext.Apply(AName, AArgument);
end;

end.
