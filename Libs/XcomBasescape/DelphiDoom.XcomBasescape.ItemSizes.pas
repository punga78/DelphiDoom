{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - ItemContainer::getTotalSize of OpenXcom }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ItemSizes;

interface

uses
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.ItemContainer;

type
  /// <summary>The storage that the items of a container take (the container does not know the item rules)</summary>
  TXcomItemSizes = class
  public
    /// <summary>getTotalSize: the sum of the size of the rule times the quantity; an item with no rule counts 0</summary>
    class function TotalSize(const AContainer: TXcomItemContainer; const ARuleset: TXcomRuleset): Double; static;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem;

class function TXcomItemSizes.TotalSize(const AContainer: TXcomItemContainer; const ARuleset: TXcomRuleset): Double;
var
  LIndex: Integer;
  LRule: TXcomRuleItem;
begin
  Result := 0.0;
  for LIndex := 0 to AContainer.Contents.Count - 1 do
  begin
    LRule := ARuleset.Items.Find(AContainer.Contents.Key(LIndex));
    if Assigned(LRule) then
      Result := Result + LRule.Size * AContainer.Contents.Value(LIndex);
  end;
end;

end.
