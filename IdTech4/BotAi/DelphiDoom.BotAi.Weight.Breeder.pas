{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeightBreeder, EvolveWeightConfig and              }
{  InterbreedWeightConfigs                                                     }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later):                     }
{  EvolveFuzzySeperator_r, EvolveWeightConfig, InterbreedFuzzySeperator_r and  }
{  InterbreedWeightConfigs of code\botlib\be_ai_weight.c. Based on the Quake   }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Breeder;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Weight.Separator, DelphiDoom.BotAi.Weight.Config;

type
  /// <summary>
  ///   The genetic changes of the weights. Defects of the original that are kept: the interbreeding of
  ///   children reads the second configuration twice (<c>fs2->child, fs2->child</c>) and raises the minimum
  ///   of the result with the same test as its maximum (<c>weight > minweight</c>).
  /// </summary>
  TBotWeightBreeder = class
  strict private
    FImport: IBotImport;
    FRandom: IBotRandom;
    procedure EvolveSeparator(const ASeparator: TBotFuzzySeparator);
    function InterbreedSeparator(const AFirst, ASecond, AOutput: TBotFuzzySeparator): Boolean;
  public
    constructor Create(const AImport: IBotImport; const ARandom: IBotRandom);
    /// <summary>EvolveWeightConfig: mutates every balance weight (crandom() is 2 * (random() - 0.5), a double)</summary>
    procedure Evolve(const AConfig: TBotWeightConfig);
    /// <summary>
    ///   InterbreedWeightConfigs: the average of two configurations is stored in the third; unequal
    ///   configurations are reported to botimport.Print (PRT_ERROR) and left as they are.
    /// </summary>
    procedure Interbreed(const AFirst, ASecond, AOutput: TBotWeightConfig);
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Weight.Types;

const
  // "random() < 0.01" compares with a double
  MUTATION_LEAP: Double = 0.01;

{ TBotWeightBreeder }

constructor TBotWeightBreeder.Create(const AImport: IBotImport; const ARandom: IBotRandom);
begin
  inherited Create;
  FImport := AImport;
  FRandom := ARandom;
end;

procedure TBotWeightBreeder.EvolveSeparator(const ASeparator: TBotFuzzySeparator);
var
  LCurrent: TBotFuzzySeparator;
  LRange: Single;
  LRandom: Single;
  LCrandom: Double;
  LTerm: Double;
  LSum: Double;
begin
  LCurrent := ASeparator;
  while Assigned(LCurrent) do
  begin
    if Assigned(LCurrent.Child) then
      EvolveSeparator(LCurrent.Child)
    else if LCurrent.WeightType = WT_BALANCE then
    begin
      // every once in a while an evolution leap occurs, mutation
      LRange := LCurrent.MaxWeight - LCurrent.MinWeight;
      LRandom := FRandom.NextFloat;
      if LRandom < MUTATION_LEAP then
      begin
        LCrandom := 2.0 * (Double(FRandom.NextFloat) - 0.5);
        LTerm := LCrandom * Double(LRange);
      end
      else
      begin
        LCrandom := 2.0 * (Double(FRandom.NextFloat) - 0.5);
        LTerm := LCrandom * Double(LRange);
        LTerm := LTerm * 0.5;
      end;
      LSum := Double(LCurrent.Weight) + LTerm;
      LCurrent.Weight := LSum;
      // modify bounds if necesary because of mutation
      if LCurrent.Weight < LCurrent.MinWeight then
        LCurrent.MinWeight := LCurrent.Weight
      else if LCurrent.Weight > LCurrent.MaxWeight then
        LCurrent.MaxWeight := LCurrent.Weight;
    end;
    LCurrent := LCurrent.Next;
  end;
end;

procedure TBotWeightBreeder.Evolve(const AConfig: TBotWeightConfig);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AConfig.Count - 1 do
    EvolveSeparator(AConfig.FirstSeparator[LIndex]);
end;

function TBotWeightBreeder.InterbreedSeparator(const AFirst, ASecond, AOutput: TBotFuzzySeparator): Boolean;
var
  LSum: Single;
begin
  if Assigned(AFirst.Child) then
  begin
    if (not Assigned(ASecond.Child)) or (not Assigned(AOutput.Child)) then
    begin
      FImport.Print(PRT_ERROR, 'cannot interbreed weight configs, unequal child'#10);
      Exit(False);
    end;
    // the original passes fs2->child twice
    if not InterbreedSeparator(ASecond.Child, ASecond.Child, AOutput.Child) then
      Exit(False);
  end
  else if AFirst.WeightType = WT_BALANCE then
  begin
    if (ASecond.WeightType <> WT_BALANCE) or (AOutput.WeightType <> WT_BALANCE) then
    begin
      FImport.Print(PRT_ERROR, 'cannot interbreed weight configs, unequal balance'#10);
      Exit(False);
    end;
    LSum := AFirst.Weight + ASecond.Weight;
    AOutput.Weight := LSum / 2;
    if AOutput.Weight > AOutput.MaxWeight then
      AOutput.MaxWeight := AOutput.Weight;
    // the original compares with the minimum too
    if AOutput.Weight > AOutput.MinWeight then
      AOutput.MinWeight := AOutput.Weight;
  end;
  if Assigned(AFirst.Next) then
  begin
    if (not Assigned(ASecond.Next)) or (not Assigned(AOutput.Next)) then
    begin
      FImport.Print(PRT_ERROR, 'cannot interbreed weight configs, unequal next'#10);
      Exit(False);
    end;
    if not InterbreedSeparator(AFirst.Next, ASecond.Next, AOutput.Next) then
      Exit(False);
  end;
  Result := True;
end;

procedure TBotWeightBreeder.Interbreed(const AFirst, ASecond, AOutput: TBotWeightConfig);
var
  LIndex: Integer;
begin
  if (AFirst.Count <> ASecond.Count) or (AFirst.Count <> AOutput.Count) then
  begin
    FImport.Print(PRT_ERROR, 'cannot interbreed weight configs, unequal numweights'#10);
    Exit;
  end;
  for LIndex := 0 to AFirst.Count - 1 do
    InterbreedSeparator(AFirst.FirstSeparator[LIndex], ASecond.FirstSeparator[LIndex], AOutput.FirstSeparator[LIndex]);
end;

end.
