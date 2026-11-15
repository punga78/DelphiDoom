{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGeneticSelector, the genetic selection             }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_gen.c. Based on the Quake III Arena GPL Source Code (id Software).    }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Gen.Selector;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Gen.Intf;

type
  /// <summary>
  ///   Defect of the original kept (the answers must be the same): <c>GeneticSelection</c> computes
  ///   <c>select = random() * sum</c> and then walks the rankings subtracting them from <c>sum</c>, not from
  ///   <c>select</c>: the first index where the running total reaches zero is always the last one with a positive
  ///   ranking, so the choice is not random; the random number is still drawn. Defect corrected (a test): a draw of
  ///   exactly 1.0 (one in 32768) made the original read <c>rankings[numranks]</c>; here the index is the last one.
  /// </summary>
  TBotGeneticSelector = class(TInterfacedObject, IBotGenetics)
  strict private
    FImport: IBotImport;
    FRandom: IBotRandom;
  public
    constructor Create(const AImport: IBotImport; const ARandom: IBotRandom);
    function Selection(const ARankings: TArray<Single>): Integer;
    function ParentsAndChildSelection(const ARanks: TArray<Single>; out AParent1, AParent2, AChild: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.BotAi.Types;

const
  /// <summary>The size of the array of rankings in the original</summary>
  MAX_RANKS = 256;

{ TBotGeneticSelector }

constructor TBotGeneticSelector.Create(const AImport: IBotImport; const ARandom: IBotRandom);
begin
  inherited Create;
  FImport := AImport;
  FRandom := ARandom;
end;

function TBotGeneticSelector.Selection(const ARankings: TArray<Single>): Integer;
var
  LSum: Single;
  LProduct: Single;
  LCount: Integer;
  LIndex: Integer;
  LLoop: Integer;
begin
  LCount := Length(ARankings);
  LSum := 0;
  for LLoop := 0 to LCount - 1 do
  begin
    if ARankings[LLoop] < 0 then
      Continue;
    LSum := LSum + ARankings[LLoop];
  end;
  if LSum > 0 then
  begin
    // select = random() * sum is never used by the original (see the class comment): the draw is kept
    FRandom.NextFloat;
    for LLoop := 0 to LCount - 1 do
    begin
      if ARankings[LLoop] < 0 then
        Continue;
      LSum := LSum - ARankings[LLoop];
      if LSum <= 0 then
        Exit(LLoop);
    end;
  end;
  // select a bot randomly
  LProduct := FRandom.NextFloat * LCount;
  LIndex := Trunc(LProduct);
  if LIndex >= LCount then
    LIndex := LCount - 1;
  if LIndex < 0 then
    Exit(0);
  for LLoop := 0 to LCount - 1 do
  begin
    if ARankings[LIndex] >= 0 then
      Exit(LIndex);
    LIndex := (LIndex + 1) mod LCount;
  end;
  Result := 0;
end;

function TBotGeneticSelector.ParentsAndChildSelection(const ARanks: TArray<Single>; out AParent1, AParent2,
  AChild: Integer): Boolean;
var
  LRankings: TArray<Single>;
  LMax: Single;
  LIndex: Integer;
begin
  if Length(ARanks) > MAX_RANKS then
  begin
    FImport.Print(PRT_WARNING, 'GeneticParentsAndChildSelection: too many bots'#10);
    AParent1 := 0;
    AParent2 := 0;
    AChild := 0;
    Exit(False);
  end;
  LMax := 0;
  for LIndex := 0 to High(ARanks) do
  begin
    if ARanks[LIndex] < 0 then
      Continue;
    LMax := LMax + 1;
  end;
  if LMax < 3 then
  begin
    FImport.Print(PRT_WARNING, 'GeneticParentsAndChildSelection: too few valid bots'#10);
    AParent1 := 0;
    AParent2 := 0;
    AChild := 0;
    Exit(False);
  end;
  LRankings := Copy(ARanks);
  // select first parent
  AParent1 := Selection(LRankings);
  LRankings[AParent1] := -1;
  // select second parent
  AParent2 := Selection(LRankings);
  LRankings[AParent2] := -1;
  // reverse the rankings
  LMax := 0;
  for LIndex := 0 to High(LRankings) do
  begin
    if LRankings[LIndex] < 0 then
      Continue;
    if LRankings[LIndex] > LMax then
      LMax := LRankings[LIndex];
  end;
  for LIndex := 0 to High(LRankings) do
  begin
    if LRankings[LIndex] < 0 then
      Continue;
    LRankings[LIndex] := LMax - LRankings[LIndex];
  end;
  // select child
  AChild := Selection(LRankings);
  Result := True;
end;

end.
