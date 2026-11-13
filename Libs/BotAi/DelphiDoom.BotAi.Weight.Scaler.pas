{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeightScaler, ScaleWeight                          }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): ScaleFuzzySeperator_r}
{  ScaleWeight, ScaleFuzzySeperatorBalanceRange_r and ScaleFuzzyBalanceRange   }
{  of code\botlib\be_ai_weight.c (be_ai_weight.h declares the last one as      }
{  ScaleBalanceRange, which does not exist). Based on the Quake III Arena GPL  }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Scaler;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Weight.Separator, DelphiDoom.BotAi.Weight.Config;

type
  /// <summary>Changes the balance weights of a configuration (the bot "personality" scale)</summary>
  TBotWeightScaler = class
  strict private
    class procedure ScaleSeparator(const ASeparator: TBotFuzzySeparator; const AScale: Single); static;
    class procedure ScaleSeparatorRange(const ASeparator: TBotFuzzySeparator; const AScale: Single); static;
  public
    /// <summary>ScaleWeight: the scale is limited to [0, 1]; only the first weight with the name is scaled</summary>
    class procedure ScaleWeight(const AConfig: TBotWeightConfig; const AName: AnsiString; const AScale: Single); static;
    /// <summary>ScaleFuzzyBalanceRange: the scale is limited to [0, 100]</summary>
    class procedure ScaleBalanceRange(const AConfig: TBotWeightConfig; const AScale: Single); static;
  end;

implementation

uses
  DelphiDoom.BotAi.Weight.Types;

{ TBotWeightScaler }

class procedure TBotWeightScaler.ScaleSeparator(const ASeparator: TBotFuzzySeparator; const AScale: Single);
var
  LCurrent: TBotFuzzySeparator;
  LSum: Single;
begin
  LCurrent := ASeparator;
  while Assigned(LCurrent) do
  begin
    if Assigned(LCurrent.Child) then
      ScaleSeparator(LCurrent.Child, AScale)
    else if LCurrent.WeightType = WT_BALANCE then
    begin
      LSum := LCurrent.MaxWeight + LCurrent.MinWeight;
      LCurrent.Weight := LSum * AScale;
      // get the weight between bounds
      if LCurrent.Weight < LCurrent.MinWeight then
        LCurrent.Weight := LCurrent.MinWeight
      else if LCurrent.Weight > LCurrent.MaxWeight then
        LCurrent.Weight := LCurrent.MaxWeight;
    end;
    LCurrent := LCurrent.Next;
  end;
end;

class procedure TBotWeightScaler.ScaleSeparatorRange(const ASeparator: TBotFuzzySeparator; const AScale: Single);
var
  LCurrent: TBotFuzzySeparator;
  LMiddle: Single;
  LSum: Single;
  LOffset: Single;
  LProduct: Single;
begin
  LCurrent := ASeparator;
  while Assigned(LCurrent) do
  begin
    if Assigned(LCurrent.Child) then
      ScaleSeparatorRange(LCurrent.Child, AScale)
    else if LCurrent.WeightType = WT_BALANCE then
    begin
      LSum := LCurrent.MinWeight + LCurrent.MaxWeight;
      LMiddle := LSum * 0.5;
      // get the weight between bounds
      LOffset := LCurrent.MaxWeight - LMiddle;
      LProduct := LOffset * AScale;
      LCurrent.MaxWeight := LMiddle + LProduct;
      LOffset := LCurrent.MinWeight - LMiddle;
      LProduct := LOffset * AScale;
      LCurrent.MinWeight := LMiddle + LProduct;
      if LCurrent.MaxWeight < LCurrent.MinWeight then
        LCurrent.MaxWeight := LCurrent.MinWeight;
    end;
    LCurrent := LCurrent.Next;
  end;
end;

class procedure TBotWeightScaler.ScaleWeight(const AConfig: TBotWeightConfig; const AName: AnsiString;
  const AScale: Single);
var
  LScale: Single;
  LIndex: Integer;
begin
  LScale := AScale;
  if LScale < 0 then
    LScale := 0
  else if LScale > 1 then
    LScale := 1;
  for LIndex := 0 to AConfig.Count - 1 do
  begin
    if AName = AConfig.Names[LIndex] then
    begin
      ScaleSeparator(AConfig.FirstSeparator[LIndex], LScale);
      Break;
    end;
  end;
end;

class procedure TBotWeightScaler.ScaleBalanceRange(const AConfig: TBotWeightConfig; const AScale: Single);
var
  LScale: Single;
  LIndex: Integer;
begin
  LScale := AScale;
  if LScale < 0 then
    LScale := 0
  else if LScale > 100 then
    LScale := 100;
  for LIndex := 0 to AConfig.Count - 1 do
    ScaleSeparatorRange(AConfig.FirstSeparator[LIndex], LScale);
end;

end.
