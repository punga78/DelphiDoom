{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - sorting the sprites with the quick sort      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_SortVisSprites_QSort of r_things_sortvissprites.pas               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.QuickSorter;

interface

uses
  DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>The quick sort of the engine (the middle element as the pivot)</summary>
  TRendererQuickSorter = class(TInterfacedObject, IRendererSpriteSorter)
  strict private
    class procedure SortRange(AItems: PRendererSortItemArray; ALeft, ARight: Integer); static;
  public
    function UsesDroppedAdjustment: Boolean;
    procedure Reserve(ACount: Integer);
    procedure Sort(AItems: PRendererSortItemArray; ACount: Integer);
    procedure Release;
  end;

implementation

{ TRendererQuickSorter }

function TRendererQuickSorter.UsesDroppedAdjustment: Boolean;
begin
  Result := True;
end;

procedure TRendererQuickSorter.Reserve(ACount: Integer);
begin
  // it sorts in place
end;

class procedure TRendererQuickSorter.SortRange(AItems: PRendererSortItemArray; ALeft,
  ARight: Integer);
var
  LLow: Integer;
  LHigh: Integer;
  LTemp: TRendererSortItem;
  LPivot: Integer;
begin
  repeat
    LLow := ALeft;
    LHigh := ARight;
    LPivot := AItems[(ALeft + ARight) shr 1].Key;
    repeat
      while AItems[LLow].Key < LPivot do
        Inc(LLow);
      while AItems[LHigh].Key > LPivot do
        Dec(LHigh);
      if LLow <= LHigh then
      begin
        LTemp := AItems[LLow];
        AItems[LLow] := AItems[LHigh];
        AItems[LHigh] := LTemp;
        Inc(LLow);
        Dec(LHigh);
      end;
    until LLow > LHigh;
    if ALeft < LHigh then
      SortRange(AItems, ALeft, LHigh);
    ALeft := LLow;
  until LLow >= ARight;
end;

procedure TRendererQuickSorter.Sort(AItems: PRendererSortItemArray; ACount: Integer);
begin
  if ACount > 1 then
    SortRange(AItems, 0, ACount - 1);
end;

procedure TRendererQuickSorter.Release;
begin
end;

end.
