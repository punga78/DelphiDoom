{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what happens when a research project     }
{  is finished (GeoscapeState::time1Day, the part about the science projects)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.ResearchCompletion;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleManufacture,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.Events.Intf,
  DelphiDoom.XcomStrategy.ResearchRules;

type
  /// <summary>
  ///   The research of a base for one day, with what follows a finished project: the topic is discovered with its
  ///   lookup, one of the topics that come free is picked at random and discovered, the new topics and the items to
  ///   produce are worked out, and the project is taken off the other bases when it cannot give anything more. The
  ///   corpse that interrogation leaves (option retainCorpses, off by default) is not ported
  /// </summary>
  TXcomResearchCompletion = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FEvents: IXcomGeoscapeEvents;
    FRules: TXcomResearchRules;
    function WeaponNeedingAmmo(const ANewResearch: TXcomRuleResearch): string;
    procedure RemoveFromOtherBases(const AResearch: TXcomRuleResearch);
    procedure Finish(const ABase: TXcomBase; const AProject: TXcomResearchProject;
      const ABefore: TList<TXcomRuleResearch>);
  public
    constructor Create(AGame: TXcomSavedGame; ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
      const AEvents: IXcomGeoscapeEvents);
    destructor Destroy; override;
    /// <summary>The rules of availability that this uses (not owned)</summary>
    property Rules: TXcomResearchRules read FRules;
    /// <summary>
    ///   The projects of the base go one day on; the ones that are finished are completed one after the other (each
    ///   one reports ResearchCompleted)
    /// </summary>
    procedure Daily(const ABase: TXcomBase);
  end;

implementation

{ TXcomResearchCompletion }

constructor TXcomResearchCompletion.Create(AGame: TXcomSavedGame; ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
  const AEvents: IXcomGeoscapeEvents);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
  FEvents := AEvents;
  FRules := TXcomResearchRules.Create(AGame, ARuleset);
end;

destructor TXcomResearchCompletion.Destroy;
begin
  FRules.Free;
  inherited Destroy;
end;

procedure TXcomResearchCompletion.Daily(const ABase: TXcomBase);
var
  LFinished: TList<TXcomResearchProject>;
  LProject: TXcomResearchProject;
  LBefore: TList<TXcomRuleResearch>;
begin
  LFinished := TList<TXcomResearchProject>.Create;
  LBefore := nil;
  try
    // 1. gather the finished projects
    for LProject in ABase.Research do
      if LProject.Step then
        LFinished.Add(LProject);
    // 2. remember what could be researched before
    if LFinished.Count > 0 then
      LBefore := FRules.AvailableProjects(ABase);
    // 3. complete them
    for LProject in LFinished do
      Finish(ABase, LProject, LBefore);
  finally
    LBefore.Free;
    LFinished.Free;
  end;
end;

function TXcomResearchCompletion.WeaponNeedingAmmo(const ANewResearch: TXcomRuleResearch): string;
var
  LItem, LAmmo: TXcomRuleItem;
  LManufacture: TXcomRuleManufacture;
  LName: string;
begin
  Result := '';
  if ANewResearch = nil then
    Exit;
  LItem := FRuleset.Items.Find(ANewResearch.Name);
  if (LItem = nil) or (LItem.BattleType <> TXcomRuleItem.BT_FIREARM) or (Length(LItem.CompatibleAmmo) = 0) then
    Exit;
  LManufacture := FRuleset.Manufacture.Find(LItem.ItemType);
  if (LManufacture = nil) or (Length(LManufacture.Requirements) = 0) then
    Exit;
  LAmmo := FRuleset.Items.Find(LItem.CompatibleAmmo[0]);
  if LAmmo = nil then
    Exit;
  for LName in LManufacture.Requirements do
    if LName = LAmmo.ItemType then
    begin
      if not FGame.IsResearched(LManufacture.Requirements, True) then
        Result := LItem.ItemType;
      Break;
    end;
end;

procedure TXcomResearchCompletion.RemoveFromOtherBases(const AResearch: TXcomRuleResearch);
var
  LBase: TXcomBase;
  LIndex: Integer;
begin
  // 3j: the project goes from the labs of every base, unless it can still yield more
  for LBase in FGame.Bases do
    for LIndex := 0 to LBase.Research.Count - 1 do
      if LBase.Research[LIndex].Rules.Name = AResearch.Name then
      begin
        if not FGame.IsResearched(AResearch.GetOneFree, False) then
          // some getOneFree topics are still undiscovered: keep it
        else if FRules.HasUndiscoveredProtectedUnlock(AResearch) then
          // some protected unlocks are still undiscovered: keep it
        else
        begin
          LBase.RemoveResearch(LBase.Research[LIndex]);
          Break;
        end;
      end;
end;

procedure TXcomResearchCompletion.Finish(const ABase: TXcomBase; const AProject: TXcomResearchProject;
  const ABefore: TList<TXcomRuleResearch>);
var
  LResearch, LBonus, LNewResearch: TXcomRuleResearch;
  LPossibilities: TList<string>;
  LName: string;
  LAfter, LNewPossible: TList<TXcomRuleResearch>;
  LManufacture: TList<TXcomRuleManufacture>;
  LOutcome: TXcomResearchOutcome;
begin
  LResearch := AProject.Rules;
  LBonus := nil;
  // a. the finished research leaves the base where it was researched
  ABase.RemoveResearch(AProject);
  // c. the topics that come free (topic and lookup)
  if Length(LResearch.GetOneFree) > 0 then
  begin
    LPossibilities := TList<string>.Create;
    try
      for LName in LResearch.GetOneFree do
        if not FGame.IsResearched(LName, False) then
          LPossibilities.Add(LName);
      if LPossibilities.Count > 0 then
      begin
        LBonus := FRuleset.Research.Find(LPossibilities[FRandom.Generate(0, LPossibilities.Count - 1)]);
        FRules.AddFinishedResearch(LBonus, ABase);
        if LBonus.Lookup <> '' then
          FRules.AddFinishedResearch(FRuleset.Research.Find(LBonus.Lookup), ABase);
      end;
    finally
      LPossibilities.Free;
    end;
  end;
  // d. the Ufopaedia article pops up again only when its entry is not known yet
  LNewResearch := LResearch;
  if LResearch.Lookup = '' then
    LName := LResearch.Name
  else
    LName := LResearch.Lookup;
  if FGame.IsResearched(LName, False) then
    LNewResearch := nil;
  // e. the core research (topic and lookup)
  FRules.AddFinishedResearch(LResearch, ABase);
  if LResearch.Lookup <> '' then
    FRules.AddFinishedResearch(FRuleset.Research.Find(LResearch.Lookup), ABase);
  // h. new possible research, i. new possible manufacture
  LAfter := FRules.AvailableProjects(ABase);
  LNewPossible := FRules.NewlyAvailable(ABefore, LAfter);
  LManufacture := FRules.DependableManufacture(LResearch);
  try
    LOutcome := Default(TXcomResearchOutcome);
    LOutcome.Research := LResearch;
    LOutcome.Bonus := LBonus;
    LOutcome.NewResearch := LNewResearch;
    LOutcome.NewPossibleResearch := LNewPossible.ToArray;
    LOutcome.NewPossibleManufacture := LManufacture.ToArray;
    LOutcome.WeaponNeedingAmmo := WeaponNeedingAmmo(LNewResearch);
    FEvents.ResearchCompleted(ABase, LOutcome);
  finally
    LManufacture.Free;
    LNewPossible.Free;
    LAfter.Free;
  end;
  RemoveFromOtherBases(LResearch);
end;

end.
