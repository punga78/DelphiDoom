{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotFuzzyEvaluator, FuzzyWeight                        }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): FuzzyWeight_r,      }
{  FuzzyWeightUndecided_r, FuzzyWeight and FuzzyWeightUndecided of             }
{  code\botlib\be_ai_weight.c. Based on the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Evaluator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Weight.Separator, DelphiDoom.BotAi.Weight.Config;

type
  /// <summary>
  ///   The value of a fuzzy weight for an inventory. Every float operation is done on its own as a
  ///   <c>Single</c> (as SSE does in the C build). Defect of the original that is kept: the position between
  ///   two cases is an integer division, so it is always 0 and the weight is simply the one of the next case.
  /// </summary>
  TBotFuzzyEvaluator = class
  strict private
    FRandom: IBotRandom;
    class function InventoryValue(const AInventory: TArray<Integer>; const AIndex: Integer): Integer; static;
    class function Mix(const AScale, AFirst, ASecond: Single): Single; static;
    function RandomWeight(const ASeparator: TBotFuzzySeparator): Single;
    function WeightOf(const AInventory: TArray<Integer>; const ASeparator: TBotFuzzySeparator): Single;
    function UndecidedOf(const AInventory: TArray<Integer>; const ASeparator: TBotFuzzySeparator): Single;
  public
    /// <summary>The generator is used by FuzzyWeightUndecided only (it may be nil for FuzzyWeight)</summary>
    constructor Create(const ARandom: IBotRandom);
    /// <summary>FuzzyWeight_r of the first case of the weight</summary>
    function FuzzyWeight(const AInventory: TArray<Integer>; const AConfig: TBotWeightConfig;
      const AWeightNumber: Integer): Single;
    /// <summary>FuzzyWeightUndecided_r: balance weights are a random value between their bounds</summary>
    function FuzzyWeightUndecided(const AInventory: TArray<Integer>; const AConfig: TBotWeightConfig;
      const AWeightNumber: Integer): Single;
  end;

implementation

uses
  DelphiDoom.BotAi.Exceptions;

{ TBotFuzzyEvaluator }

constructor TBotFuzzyEvaluator.Create(const ARandom: IBotRandom);
begin
  inherited Create;
  FRandom := ARandom;
end;

class function TBotFuzzyEvaluator.InventoryValue(const AInventory: TArray<Integer>; const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= Length(AInventory)) then
    raise EBotAiException.CreateFmt('inventory index %d out of range (inventory of %d)', [AIndex, Length(AInventory)]);
  Result := AInventory[AIndex];
end;

class function TBotFuzzyEvaluator.Mix(const AScale, AFirst, ASecond: Single): Single;
var
  LFirstPart: Single;
  LRest: Single;
  LSecondPart: Single;
begin
  // scale * w1 + (1 - scale) * w2
  LFirstPart := AScale * AFirst;
  LRest := 1 - AScale;
  LSecondPart := LRest * ASecond;
  Result := LFirstPart + LSecondPart;
end;

function TBotFuzzyEvaluator.RandomWeight(const ASeparator: TBotFuzzySeparator): Single;
var
  LRange: Single;
  LRandom: Single;
  LOffset: Single;
begin
  // minweight + random() * (maxweight - minweight)
  LRandom := FRandom.NextFloat;
  LRange := ASeparator.MaxWeight - ASeparator.MinWeight;
  LOffset := LRandom * LRange;
  Result := ASeparator.MinWeight + LOffset;
end;

function TBotFuzzyEvaluator.WeightOf(const AInventory: TArray<Integer>; const ASeparator: TBotFuzzySeparator): Single;
var
  LValue: Integer;
  LScale: Single;
  LFirst: Single;
  LSecond: Single;
begin
  LValue := InventoryValue(AInventory, ASeparator.Index);
  if LValue < ASeparator.Value then
  begin
    if Assigned(ASeparator.Child) then
      Exit(WeightOf(AInventory, ASeparator.Child));
    Exit(ASeparator.Weight);
  end
  else if Assigned(ASeparator.Next) then
  begin
    if LValue < ASeparator.Next.Value then
    begin
      // first weight
      if Assigned(ASeparator.Child) then
        LFirst := WeightOf(AInventory, ASeparator.Child)
      else
        LFirst := ASeparator.Weight;
      // second weight
      if Assigned(ASeparator.Next.Child) then
        LSecond := WeightOf(AInventory, ASeparator.Next.Child)
      else
        LSecond := ASeparator.Next.Weight;
      // the scale factor: an integer division in the original
      LScale := (LValue - ASeparator.Value) div (ASeparator.Next.Value - ASeparator.Value);
      Exit(Mix(LScale, LFirst, LSecond));
    end;
    Exit(WeightOf(AInventory, ASeparator.Next));
  end;
  Result := ASeparator.Weight;
end;

function TBotFuzzyEvaluator.UndecidedOf(const AInventory: TArray<Integer>; const ASeparator: TBotFuzzySeparator): Single;
var
  LValue: Integer;
  LScale: Single;
  LFirst: Single;
  LSecond: Single;
begin
  LValue := InventoryValue(AInventory, ASeparator.Index);
  if LValue < ASeparator.Value then
  begin
    if Assigned(ASeparator.Child) then
      Exit(UndecidedOf(AInventory, ASeparator.Child));
    Exit(RandomWeight(ASeparator));
  end
  else if Assigned(ASeparator.Next) then
  begin
    if LValue < ASeparator.Next.Value then
    begin
      // first weight
      if Assigned(ASeparator.Child) then
        LFirst := UndecidedOf(AInventory, ASeparator.Child)
      else
        LFirst := RandomWeight(ASeparator);
      // second weight: the original evaluates the child of the next case as a decided weight
      if Assigned(ASeparator.Next.Child) then
        LSecond := WeightOf(AInventory, ASeparator.Next.Child)
      else
        LSecond := RandomWeight(ASeparator.Next);
      LScale := (LValue - ASeparator.Value) div (ASeparator.Next.Value - ASeparator.Value);
      Exit(Mix(LScale, LFirst, LSecond));
    end;
    Exit(UndecidedOf(AInventory, ASeparator.Next));
  end;
  Result := ASeparator.Weight;
end;

function TBotFuzzyEvaluator.FuzzyWeight(const AInventory: TArray<Integer>; const AConfig: TBotWeightConfig;
  const AWeightNumber: Integer): Single;
begin
  Result := WeightOf(AInventory, AConfig.FirstSeparator[AWeightNumber]);
end;

function TBotFuzzyEvaluator.FuzzyWeightUndecided(const AInventory: TArray<Integer>; const AConfig: TBotWeightConfig;
  const AWeightNumber: Integer): Single;
begin
  Result := UndecidedOf(AInventory, AConfig.FirstSeparator[AWeightNumber]);
end;

end.
