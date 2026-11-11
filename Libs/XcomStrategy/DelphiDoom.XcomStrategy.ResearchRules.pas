{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what research makes available (the       }
{  functions of SavedGame that look at the discovered topics)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.ResearchRules;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleResearch,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   SavedGame::getAvailableResearchProjects, getNewlyAvailableResearchProjects, getAvailableProductions,
  ///   getDependableManufacture, hasUndiscoveredProtectedUnlock and addFinishedResearch: what the discovered topics
  ///   of a saved game make available, with the rules of the ruleset. The saved game and the ruleset are not owned
  /// </summary>
  TXcomResearchRules = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
  public
    constructor Create(AGame: TXcomSavedGame; ARuleset: TXcomRuleset);
    /// <summary>
    ///   The topics that can be researched in a base, in the order of the research list of the ruleset; ABase nil is
    ///   the converter of the vanilla saved games (topics that need an item and cost nothing are left out). The list
    ///   is the caller's (the rules are not owned)
    /// </summary>
    function AvailableProjects(ABase: TXcomBase; AConsiderDebug: Boolean = False): TList<TXcomRuleResearch>;
    /// <summary>
    ///   getNewlyAvailableResearchProjects: after minus before (set difference by list order, both ordered by
    ///   listOrder: the list of the C++ is sorted by CompareRuleResearch)
    /// </summary>
    function NewlyAvailable(const ABefore, AAfter: TList<TXcomRuleResearch>): TList<TXcomRuleResearch>;
    /// <summary>getAvailableProductions: the items that can be produced in the base and are not in production there</summary>
    function AvailableProductions(ABase: TXcomBase): TList<TXcomRuleManufacture>;
    /// <summary>getDependableManufacture: the items that the topic made available (it is among their requirements)</summary>
    function DependableManufacture(const AResearch: TXcomRuleResearch): TList<TXcomRuleManufacture>;
    /// <summary>hasUndiscoveredProtectedUnlock: an unlocked topic with "requires" that is not discovered yet</summary>
    function HasUndiscoveredProtectedUnlock(const AResearch: TXcomRuleResearch): Boolean;
    /// <summary>
    ///   addFinishedResearch: the topic is discovered (once), and the zero cost topics that it unlocks are discovered
    ///   in cascade (a queue that is walked once: each topic is processed once)
    /// </summary>
    procedure AddFinishedResearch(const AResearch: TXcomRuleResearch; ABase: TXcomBase; AScore: Boolean = True);
  end;

implementation

{ TXcomResearchRules }

constructor TXcomResearchRules.Create(AGame: TXcomSavedGame; ARuleset: TXcomRuleset);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
end;

function TXcomResearchRules.HasUndiscoveredProtectedUnlock(const AResearch: TXcomRuleResearch): Boolean;
var
  LName: string;
  LUnlock: TXcomRuleResearch;
begin
  // checking for the unlocks that are protected by "requires" (which also means cost = 0)
  for LName in AResearch.Unlocks do
  begin
    LUnlock := FRuleset.Research.Find(LName);
    if (LUnlock <> nil) and (Length(LUnlock.Requirements) > 0) and not FGame.IsResearched(LUnlock.Name, False) then
      Exit(True);
  end;
  Result := False;
end;

function TXcomResearchRules.AvailableProjects(ABase: TXcomBase; AConsiderDebug: Boolean): TList<TXcomRuleResearch>;
var
  LUnlocked: TList<TXcomRuleResearch>;
  LDiscovered, LResearch: TXcomRuleResearch;
  LName: string;
  LProject: TObject;
  LBeingResearched: Boolean;
  LIndex: Integer;
begin
  Result := TList<TXcomRuleResearch>.Create;
  // the topics that can be researched even if not all their dependencies are discovered (their requirements are)
  LUnlocked := TList<TXcomRuleResearch>.Create;
  try
    for LDiscovered in FGame.Discovered do
      for LName in LDiscovered.Unlocks do
        LUnlocked.Add(FRuleset.Research.Find(LName));
    for LName in FRuleset.Research.Index do
    begin
      LResearch := FRuleset.Research.Find(LName);
      // the debug mode of the saved game is not ported: AConsiderDebug never adds anything
      if not LUnlocked.Contains(LResearch) then
        if not FGame.IsResearched(LResearch.Dependencies, AConsiderDebug) then
          Continue;
      // "requires": topics with it are never visible to the player directly, other code filters them
      if not FGame.IsResearched(LResearch.Requirements, AConsiderDebug) then
        Continue;
      // a topic that is researched is left out unless it can still give something
      if FGame.IsResearched(LResearch.Name, False) then
      begin
        if not FGame.IsResearched(LResearch.GetOneFree, False) then
          // some of its getOneFree topics are still undiscovered: keep it
        else if HasUndiscoveredProtectedUnlock(LResearch) then
          // some of the unlocks that are protected are still undiscovered: keep it
        else
          Continue;
      end;
      if Assigned(ABase) then
      begin
        LBeingResearched := False;
        for LIndex := 0 to ABase.Research.Count - 1 do
          if ABase.Research[LIndex].Rules = LResearch then
          begin
            LBeingResearched := True;
            Break;
          end;
        if LBeingResearched then
          Continue;
        // a topic that needs an item needs it in the stores of the base
        if LResearch.NeedItem and (ABase.StorageItems.GetItem(LResearch.Name) = 0) then
          Continue;
      end
      else if LResearch.NeedItem and (LResearch.Cost = 0) then
        Continue;
      Result.Add(LResearch);
    end;
  finally
    LUnlocked.Free;
  end;
end;

function TXcomResearchRules.NewlyAvailable(const ABefore, AAfter: TList<TXcomRuleResearch>):
  TList<TXcomRuleResearch>;
var
  LResearch: TXcomRuleResearch;
begin
  // std::set_difference of two lists sorted by CompareRuleResearch (the name): the topics of "after" that "before"
  // lacks, in the order of the names
  Result := TList<TXcomRuleResearch>.Create;
  for LResearch in AAfter do
    if not ABefore.Contains(LResearch) then
      Result.Add(LResearch);
  Result.Sort(TComparer<TXcomRuleResearch>.Construct(
    function(const ALeft, ARight: TXcomRuleResearch): Integer
    begin
      Result := CompareStr(ALeft.Name, ARight.Name);
    end));
end;

function TXcomResearchRules.AvailableProductions(ABase: TXcomBase): TList<TXcomRuleManufacture>;
var
  LName: string;
  LRule: TXcomRuleManufacture;
  LIndex: Integer;
  LInProduction: Boolean;
begin
  Result := TList<TXcomRuleManufacture>.Create;
  for LName in FRuleset.Manufacture.Index do
  begin
    LRule := FRuleset.Manufacture.Find(LName);
    if not FGame.IsResearched(LRule.Requirements) then
      Continue;
    LInProduction := False;
    for LIndex := 0 to ABase.Productions.Count - 1 do
      if ABase.Productions[LIndex].Rules = LRule then
      begin
        LInProduction := True;
        Break;
      end;
    if not LInProduction then
      Result.Add(LRule);
  end;
end;

function TXcomResearchRules.DependableManufacture(const AResearch: TXcomRuleResearch): TList<TXcomRuleManufacture>;
var
  LName, LRequirement: string;
  LRule: TXcomRuleManufacture;
  LContains: Boolean;
begin
  Result := TList<TXcomRuleManufacture>.Create;
  for LName in FRuleset.Manufacture.Index do
  begin
    LRule := FRuleset.Manufacture.Find(LName);
    LContains := False;
    for LRequirement in LRule.Requirements do
      if LRequirement = AResearch.Name then
        LContains := True;
    if LContains and FGame.IsResearched(LRule.Requirements) then
      Result.Add(LRule);
  end;
end;

procedure TXcomResearchRules.AddFinishedResearch(const AResearch: TXcomRuleResearch; ABase: TXcomBase;
  AScore: Boolean);
var
  LQueue: TList<TXcomRuleResearch>;
  LCurrent, LTest: TXcomRuleResearch;
  LAvailable: TList<TXcomRuleResearch>;
  LIndex: Integer;
  LUndiscovered, LCheckRelated: Boolean;
  LUnlock: string;
begin
  LQueue := TList<TXcomRuleResearch>.Create;
  try
    LQueue.Add(AResearch);
    LIndex := 0;
    while LQueue.Count > LIndex do
    begin
      LCurrent := LQueue[LIndex];
      // 1. does the topic have unlocks that are protected and not discovered?
      LUndiscovered := HasUndiscoveredProtectedUnlock(LCurrent);
      // 2. a topic that was not discovered is added to the discovered ones
      LCheckRelated := True;
      if not FGame.IsResearched(LCurrent.Name, False) then
      begin
        FGame.Discovered.Add(LCurrent);
        if not LUndiscovered and FGame.IsResearched(LCurrent.GetOneFree, False) then
          FGame.RemovePoppedResearch(LCurrent);
        if AScore then
          FGame.AddResearchScore(LCurrent.Points);
      end
      else if not LUndiscovered then
        // discovered before and nothing protected is left: its zero cost topics were processed the first time
        LCheckRelated := False;
      // 3. the zero cost topics that are related are processed too
      if LCheckRelated then
      begin
        LAvailable := AvailableProjects(ABase);
        try
          for LTest in LAvailable do
          begin
            if LTest.Cost <> 0 then
              Continue;
            if LQueue.Contains(LTest) then
              Continue;
            if Length(LTest.Requirements) = 0 then
              LQueue.Add(LTest)
            else
              for LUnlock in LCurrent.Unlocks do
                if LTest.Name = LUnlock then
                begin
                  LQueue.Add(LTest);
                  Break;
                end;
          end;
        finally
          LAvailable.Free;
        end;
      end;
      Inc(LIndex);
    end;
  finally
    LQueue.Free;
  end;
end;

end.
