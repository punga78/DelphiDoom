{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a soldier commendation                    }
{  (RuleCommendations)                                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleCommendations;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>One condition of a kill criterion: a number and the names (weapons, races...) it applies to</summary>
  TXcomKillCondition = record
    Count: Integer;
    Names: TArray<string>;
  end;

  /// <summary>Represents a commendation that soldiers can earn: its text, sprite and what it takes to get it</summary>
  TXcomRuleCommendations = class
  strict private
    FDescription: string;
    FCriteria: TXcomStringMap<TArray<Integer>>;
    FKillCriteria: TArray<TArray<TXcomKillCondition>>;
    FSprite: Integer;
    procedure ReadCriteria(const ANode: IYamlNode);
    class function ReadKillCondition(const ANode: IYamlNode): TXcomKillCondition; static;
    class function ReadKillCriteria(const ANode: IYamlNode; const ADefault: TArray<TArray<TXcomKillCondition>>)
      : TArray<TArray<TXcomKillCondition>>; static;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const ANode: IYamlNode);
    property Description: string read FDescription;
    /// <summary>What it takes: a name and the numbers for each level of the commendation</summary>
    property Criteria: TXcomStringMap<TArray<Integer>> read FCriteria;
    /// <summary>Alternatives (the outer list) of lists of conditions</summary>
    property KillCriteria: TArray<TArray<TXcomKillCondition>> read FKillCriteria;
    property Sprite: Integer read FSprite;
  end;

implementation

{ TXcomRuleCommendations }

constructor TXcomRuleCommendations.Create;
begin
  inherited Create;
  FCriteria := TXcomStringMap<TArray<Integer>>.Create;
end;

destructor TXcomRuleCommendations.Destroy;
begin
  FCriteria.Free;
  inherited Destroy;
end;

procedure TXcomRuleCommendations.ReadCriteria(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LPair: TYamlPair;
begin
  LField := TXcomNodeReader.Field(ANode, 'criteria');
  if not LField.IsDefined or not LField.IsMap then
    Exit;
  FCriteria.Clear;
  for LPair in LField.Pairs do
    FCriteria.SetValue(TXcomNodeReader.TextOf(LPair.Key), TXcomNodeReader.IntegersOf(LPair.Value));
end;

class function TXcomRuleCommendations.ReadKillCondition(const ANode: IYamlNode): TXcomKillCondition;
var
  LCells: TArray<IYamlNode>;
begin
  // convert<std::pair<int, std::vector<std::string>>>::decode: a sequence of two elements
  if not ANode.IsSequence or (ANode.Size <> 2) then
    raise TXcomNodeReader.BadConversion(ANode);
  LCells := ANode.Items;
  Result.Count := LCells[0].AsInteger;
  Result.Names := TXcomNodeReader.StringsOf(LCells[1]);
end;

class function TXcomRuleCommendations.ReadKillCriteria(const ANode: IYamlNode;
  const ADefault: TArray<TArray<TXcomKillCondition>>): TArray<TArray<TXcomKillCondition>>;
var
  LField, LRow: IYamlNode;
  LRows, LCells: TArray<IYamlNode>;
  LIndex, LCell: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'killCriteria');
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LRows := LField.Items;
  SetLength(Result, Length(LRows));
  for LIndex := 0 to High(LRows) do
  begin
    LRow := LRows[LIndex];
    if not LRow.IsSequence then
      raise TXcomNodeReader.BadConversion(LRow);
    LCells := LRow.Items;
    SetLength(Result[LIndex], Length(LCells));
    for LCell := 0 to High(LCells) do
      Result[LIndex][LCell] := ReadKillCondition(LCells[LCell]);
  end;
end;

procedure TXcomRuleCommendations.Load(const ANode: IYamlNode);
begin
  FDescription := TXcomNodeReader.ReadString(ANode, 'description', FDescription);
  ReadCriteria(ANode);
  FSprite := TXcomNodeReader.ReadInteger(ANode, 'sprite', FSprite);
  FKillCriteria := ReadKillCriteria(ANode, FKillCriteria);
end;

end.
