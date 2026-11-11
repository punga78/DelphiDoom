{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the research cascade   }
{  (finished projects, free topics, new topics and items to produce) on the     }
{  real saved games, against what the real OpenXcom objects did (simgen         }
{  research)                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Research;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomStrategy.Types,
  DelphiDoom.XcomStrategy.NullEvents, DelphiDoom.XcomStrategy.Events.Intf, DelphiDoom.XcomStrategy.ResearchRules,
  DelphiDoom.XcomStrategy.ResearchCompletion, DelphiDoom.Tests.XcomSave.Sim;

type
  /// <summary>Writes what ResearchCompleted reports as the lines of the harness (ev|research|...)</summary>
  TResearchRecorder = class(TXcomNullGeoscapeEvents)
  strict private
    FLines: TStringList;
    function Names(const ANames: TArray<string>): string;
  public
    constructor Create(ALines: TStringList);
    procedure ResearchCompleted(const ABase: TXcomBase; const AOutcome: TXcomResearchOutcome); override;
  end;

  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomResearchCascade = class(TObject)
  strict private
    FSim: TXcomSim;
    FRandom: IXcomRandom;
    function Pick(AValue: Integer): Integer;
    function NamesOf(const AList: TList<TXcomRuleResearch>): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareLaStessaCascataDelleRicercheDelVeroOpenXcom;
  end;

implementation

{ TResearchRecorder }

constructor TResearchRecorder.Create(ALines: TStringList);
begin
  inherited Create;
  FLines := ALines;
end;

function TResearchRecorder.Names(const ANames: TArray<string>): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(ANames) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + ANames[LIndex];
  end;
end;

procedure TResearchRecorder.ResearchCompleted(const ABase: TXcomBase; const AOutcome: TXcomResearchOutcome);
var
  LPossible, LManufacture: TArray<string>;
  LIndex: Integer;
  LBonus, LNew: string;
begin
  SetLength(LPossible, Length(AOutcome.NewPossibleResearch));
  for LIndex := 0 to High(LPossible) do
    LPossible[LIndex] := AOutcome.NewPossibleResearch[LIndex].Name;
  SetLength(LManufacture, Length(AOutcome.NewPossibleManufacture));
  for LIndex := 0 to High(LManufacture) do
    LManufacture[LIndex] := AOutcome.NewPossibleManufacture[LIndex].Name;
  LBonus := '';
  if Assigned(AOutcome.Bonus) then
    LBonus := AOutcome.Bonus.Name;
  LNew := '';
  if Assigned(AOutcome.NewResearch) then
    LNew := AOutcome.NewResearch.Name;
  FLines.Add(Format('ev|research|0|%s|bonus=%s|new=%s|weapon=%s|possible=%s|manufacture=%s', [AOutcome.Research.Name,
    LBonus, LNew, AOutcome.WeaponNeedingAmmo, Names(LPossible), Names(LManufacture)]));
end;

{ TTestXcomResearchCascade }

procedure TTestXcomResearchCascade.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomResearchCascade.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomResearchCascade.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

function TTestXcomResearchCascade.NamesOf(const AList: TList<TXcomRuleResearch>): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to AList.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + AList[LIndex].Name;
  end;
end;

procedure TTestXcomResearchCascade.DovrebbeFareLaStessaCascataDelleRicercheDelVeroOpenXcom;
var
  LFolder: string;
  LVariant, LRound, LAdded, LPick: Integer;
  LGame: TXcomSavedGame;
  LBase: TXcomBase;
  LLines: TStringList;
  LAvailable: TList<TXcomRuleResearch>;
  LProductions: TList<TXcomRuleManufacture>;
  LRule: TXcomRuleResearch;
  LProject: TXcomResearchProject;
  LRules: TXcomResearchRules;
  LCompletion: TXcomResearchCompletion;
  LEvents: IXcomGeoscapeEvents;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if not FSim.Available or (LFolder = '') then
  begin
    Assert.Pass('senza i dati di TFTD o i golden il confronto non si fa');
    Exit;
  end;
  LLines := TStringList.Create;
  try
    for LVariant := 0 to 15 do
    begin
      LLines.Clear;
      FRandom := TXcomRandom.Create(1);
      LGame := FSim.LoadSave(LVariant, FRandom);
      try
        FRandom.SetSeed(5000 + LVariant);
        if LGame.Bases.Count > 0 then
        begin
          LBase := LGame.Bases.First;
          LEvents := TResearchRecorder.Create(LLines);
          LRules := TXcomResearchRules.Create(LGame, FSim.Ruleset);
          LCompletion := TXcomResearchCompletion.Create(LGame, FSim.Ruleset, FRandom, LEvents);
          try
            for LRound := 0 to 11 do
            begin
              LAvailable := LRules.AvailableProjects(LBase);
              LProductions := LRules.AvailableProductions(LBase);
              try
                LLines.Add(Format('avail|%d|%d|%s', [LVariant, LRound, NamesOf(LAvailable)]));
                LLines.Add(Format('productions|%d|%d|%d', [LVariant, LRound, LProductions.Count]));
                LAdded := 0;
                while (LAdded < 3) and (LAvailable.Count > 0) do
                begin
                  LPick := Pick(LAvailable.Count);
                  LRule := LAvailable[LPick];
                  LAvailable.Delete(LPick);
                  // the topics with "requires" are not shown to the player
                  if Length(LRule.Requirements) > 0 then
                    Continue;
                  LProject := TXcomResearchProject.Create(LRule, LRule.Cost);
                  LProject.Assigned := 1;
                  LProject.Spent := LRule.Cost;
                  LBase.AddResearch(LProject);
                  Inc(LAdded);
                end;
              finally
                LProductions.Free;
                LAvailable.Free;
              end;
              LCompletion.Daily(LBase);
              LLines.Add(Format('day|%d|%d|discovered=%d|popped=%d|score=%d', [LVariant, LRound, LGame.Discovered.Count,
                LGame.PoppedResearch.Count, LGame.ResearchScores[High(LGame.ResearchScores)]]));
            end;
          finally
            LCompletion.Free;
            LRules.Free;
          end;
        end;
        LLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        Assert.AreEqual('', TXcomSim.FirstDifference(string(TXcomSim.GoldenText(LFolder +
          Format('sim%.2d.research.txt', [LVariant]))), LLines.Text), Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.SaveDifference(TXcomSim.GoldenText(LFolder + Format('sim%.2d.research.sav',
          [LVariant])), FSim.SaveText(LGame, FRandom)), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LGame.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomResearchCascade);

end.
