{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - sorting the sprites by selection             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_SortVisSprites_SelectionSort of r_things_sortvissprites.pas       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.SelectionSorter;

interface

uses
  DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   The same execution speed as the quick sort or faster for few sprites
  /// </summary>
  TRendererSelectionSorter = class(TInterfacedObject, IRendererSpriteSorter)
  public
    function UsesDroppedAdjustment: Boolean;
    procedure Reserve(ACount: Integer);
    procedure Sort(AItems: PRendererSortItemArray; ACount: Integer);
    procedure Release;
  end;

implementation

{ TRendererSelectionSorter }

function TRendererSelectionSorter.UsesDroppedAdjustment: Boolean;
begin
  Result := True;
end;

procedure TRendererSelectionSorter.Reserve(ACount: Integer);
begin
  // it sorts in place
end;

procedure TRendererSelectionSorter.Sort(AItems: PRendererSortItemArray; ACount: Integer);
var
  LFirst: Integer;
  LSecond: Integer;
  LTemp: TRendererSortItem;
begin
  for LFirst := 0 to ACount - 2 do
    for LSecond := ACount - 1 downto LFirst + 1 do
      if AItems[LFirst].Key > AItems[LSecond].Key then
      begin
        LTemp := AItems[LFirst];
        AItems[LFirst] := AItems[LSecond];
        AItems[LSecond] := LTemp;
      end;
end;

procedure TRendererSelectionSorter.Release;
begin
end;

end.
