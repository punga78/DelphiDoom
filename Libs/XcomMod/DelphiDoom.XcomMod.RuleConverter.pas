{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the tables that convert a saved game of   }
{  the original game (RuleConverter)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleConverter;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>
  ///   The offsets and the lists of names (markers, countries, regions, facilities, items, crews, crafts, UFOs,
  ///   craft weapons, missions, armor, alien races and ranks, research, manufacture, ufopaedia) that the converter
  ///   of the original saved games uses to name what it finds (RuleConverter)
  /// </summary>
  TXcomRuleConverter = class
  public
    const
      /// <summary>The names of the lists, in the order of the C++ members</summary>
      LIST_NAMES: array[0..15] of string = ('markers', 'countries', 'regions', 'facilities', 'items', 'crews',
        'crafts', 'ufos', 'craftWeapons', 'missions', 'armor', 'alienRaces', 'alienRanks', 'research',
        'manufacture', 'ufopaedia');
  strict private
    FOffsets: TXcomStringMap<Integer>;
    FLists: array[0..15] of TArray<string>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Loads from a node; each list that the node has replaces the one there was</summary>
    procedure Load(const ANode: IYamlNode);
    property Offsets: TXcomStringMap<Integer> read FOffsets;
    /// <summary>One of the lists by name (one of LIST_NAMES); empty for another name</summary>
    function List(const AName: string): TArray<string>;
  end;

implementation

{ TXcomRuleConverter }

constructor TXcomRuleConverter.Create;
begin
  inherited Create;
  FOffsets := TXcomStringMap<Integer>.Create;
end;

destructor TXcomRuleConverter.Destroy;
begin
  FOffsets.Free;
  inherited Destroy;
end;

procedure TXcomRuleConverter.Load(const ANode: IYamlNode);
var
  LIndex: Integer;
begin
  TXcomNodeReader.ReadStringIntMap(ANode, 'offsets', FOffsets);
  for LIndex := 0 to High(LIST_NAMES) do
    FLists[LIndex] := TXcomNodeReader.ReadStrings(ANode, LIST_NAMES[LIndex], FLists[LIndex]);
end;

function TXcomRuleConverter.List(const AName: string): TArray<string>;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(LIST_NAMES) do
    if LIST_NAMES[LIndex] = AName then
      Exit(FLists[LIndex]);
  Result := nil;
end;

end.
