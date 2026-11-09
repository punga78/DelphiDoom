{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a string added to the name of a soldier   }
{  by its stats (StatString and StatStringCondition)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.StatString;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>StatStringCondition: a stat and the range of values it must be in</summary>
  TXcomStatStringCondition = record
    ConditionName: string;
    MinVal: Integer;
    MaxVal: Integer;
    /// <summary>isMet: psiTraining is always met; psiStrength and psiSkill also need APsi</summary>
    function IsMet(AStat: Integer; APsi: Boolean): Boolean;
  end;

  /// <summary>A string that is added to the name of a soldier if all of its conditions are met (StatString)</summary>
  TXcomStatString = class
  strict private
    FText: string;
    FConditions: TArray<TXcomStatStringCondition>;
    class function ReadCondition(const AName: string; const ANode: IYamlNode): TXcomStatStringCondition; static;
  public
    /// <summary>Loads from a node; the conditions are in the order of the stats of the C++ (not of the node)</summary>
    procedure Load(const ANode: IYamlNode);
    property Text: string read FText;
    property Conditions: TArray<TXcomStatStringCondition> read FConditions;
  end;

implementation

const
  CONDITION_NAMES: array[0..11] of string = ('psiStrength', 'psiSkill', 'bravery', 'strength', 'firing', 'reactions',
    'stamina', 'tu', 'health', 'throwing', 'melee', 'psiTraining');

{ TXcomStatStringCondition }

function TXcomStatStringCondition.IsMet(AStat: Integer; APsi: Boolean): Boolean;
begin
  if ConditionName = 'psiTraining' then
    Exit(True);
  Result := (AStat >= MinVal) and (AStat <= MaxVal);
  if (ConditionName = 'psiStrength') or (ConditionName = 'psiSkill') then
    Result := Result and APsi;
end;

{ TXcomStatString }

class function TXcomStatString.ReadCondition(const AName: string; const ANode: IYamlNode): TXcomStatStringCondition;
var
  LField: IYamlNode;
begin
  // the defaults are the ones of xcomutil
  Result.ConditionName := AName;
  Result.MinVal := 0;
  Result.MaxVal := 255;
  LField := TXcomNodeReader.Field(ANode, AName);
  if LField.Find(0).IsDefined then
    Result.MinVal := LField.Find(0).AsInteger(Result.MinVal);
  if LField.Find(1).IsDefined then
    Result.MaxVal := LField.Find(1).AsInteger(Result.MaxVal);
end;

procedure TXcomStatString.Load(const ANode: IYamlNode);
var
  LName: string;
begin
  FText := TXcomNodeReader.ReadString(ANode, 'string', FText);
  for LName in CONDITION_NAMES do
    if TXcomNodeReader.Field(ANode, LName).IsDefined then
    begin
      SetLength(FConditions, Length(FConditions) + 1);
      FConditions[High(FConditions)] := ReadCondition(LName, ANode);
    end;
end;

end.
