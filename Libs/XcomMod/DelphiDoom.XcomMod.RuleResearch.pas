{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a research topic (RuleResearch)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleResearch;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>Represents one research topic the player can research: its cost and what it needs and unlocks</summary>
  TXcomRuleResearch = class
  strict private
    FName: string;
    FLookup: string;
    FCutscene: string;
    FCost: Integer;
    FPoints: Integer;
    FDependencies: TArray<string>;
    FUnlocks: TArray<string>;
    FGetOneFree: TArray<string>;
    FRequires: TArray<string>;
    FNeedItem: Boolean;
    FDestroyItem: Boolean;
    FListOrder: Integer;
  public
    constructor Create(const AName: string);
    /// <summary>
    ///   Loads the topic. A topic with requirements must cost nothing: otherwise EXcomModException
    ///   (the Exception of the C++ with the same text)
    /// </summary>
    procedure Load(const ANode: IYamlNode; AListOrder: Integer);
    property Name: string read FName;
    property Lookup: string read FLookup;
    property Cutscene: string read FCutscene;
    property Cost: Integer read FCost;
    property Points: Integer read FPoints;
    property Dependencies: TArray<string> read FDependencies;
    property Unlocks: TArray<string> read FUnlocks;
    property GetOneFree: TArray<string> read FGetOneFree;
    property Requirements: TArray<string> read FRequires;
    property NeedItem: Boolean read FNeedItem;
    property DestroyItem: Boolean read FDestroyItem;
    property ListOrder: Integer read FListOrder;
  end;

implementation

{ TXcomRuleResearch }

constructor TXcomRuleResearch.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

procedure TXcomRuleResearch.Load(const ANode: IYamlNode; AListOrder: Integer);
begin
  FName := TXcomNodeReader.ReadString(ANode, 'name', FName);
  FLookup := TXcomNodeReader.ReadString(ANode, 'lookup', FLookup);
  FCutscene := TXcomNodeReader.ReadString(ANode, 'cutscene', FCutscene);
  FCost := TXcomNodeReader.ReadInteger(ANode, 'cost', FCost);
  FPoints := TXcomNodeReader.ReadInteger(ANode, 'points', FPoints);
  FDependencies := TXcomNodeReader.ReadStrings(ANode, 'dependencies', FDependencies);
  FUnlocks := TXcomNodeReader.ReadStrings(ANode, 'unlocks', FUnlocks);
  FGetOneFree := TXcomNodeReader.ReadStrings(ANode, 'getOneFree', FGetOneFree);
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  FNeedItem := TXcomNodeReader.ReadBoolean(ANode, 'needItem', FNeedItem);
  FDestroyItem := TXcomNodeReader.ReadBoolean(ANode, 'destroyItem', FDestroyItem);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', FListOrder);
  if FListOrder = 0 then
    FListOrder := AListOrder;
  // this is necessary, research code assumes it
  if (Length(FRequires) > 0) and (FCost <> 0) then
    raise EXcomModException.Create('Research topic ' + FName +
      ' has requirements, but the cost is not zero. Sorry, this is not allowed!');
end;

end.
