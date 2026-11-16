{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotFuzzySeparator, a case of a fuzzy weight           }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): fuzzyseperator_t of }
{  code\botlib\be_ai_weight.h. Based on the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Separator;

interface

type
  /// <summary>
  ///   fuzzyseperator_t: one <c>case</c> of a <c>switch</c> on an inventory item. The cases of a switch are
  ///   a chain (<c>Next</c>); a case either has a weight or a nested switch (<c>Child</c>). The
  ///   object owns its child and its next (FreeFuzzySeperators_r).
  /// </summary>
  TBotFuzzySeparator = class
  strict private
    FChild: TBotFuzzySeparator;
    FNext: TBotFuzzySeparator;
  public
    /// <summary>The index in the inventory the switch looks at</summary>
    Index: Integer;
    /// <summary>The value of the case (MAX_INVENTORYVALUE for the default)</summary>
    Value: Integer;
    /// <summary>0, or WT_BALANCE</summary>
    WeightType: Integer;
    Weight: Single;
    MinWeight: Single;
    MaxWeight: Single;
    destructor Destroy; override;
    property Child: TBotFuzzySeparator read FChild write FChild;
    property Next: TBotFuzzySeparator read FNext write FNext;
  end;

implementation

{ TBotFuzzySeparator }

destructor TBotFuzzySeparator.Destroy;
begin
  FChild.Free;
  FNext.Free;
  inherited Destroy;
end;

end.
