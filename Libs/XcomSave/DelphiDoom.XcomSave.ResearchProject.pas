{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a research project in progress         }
{  (ResearchProject)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.ResearchProject;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>A research topic that scientists are working on: how much was spent and how many work on it</summary>
  TXcomResearchProject = class
  strict private
    FProject: TXcomRuleResearch;
    FAssigned: Integer;
    FSpent: Integer;
    FCost: Integer;
  public
    /// <param name="AProject">Not owned</param>
    constructor Create(const AProject: TXcomRuleResearch; ACost: Integer);
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: TXcomRuleResearch read FProject;
    property Assigned: Integer read FAssigned write FAssigned;
    property Spent: Integer read FSpent write FSpent;
    property Cost: Integer read FCost write FCost;
    /// <summary>step: a day of work; true when the project is finished</summary>
    function Step: Boolean;
    function IsFinished: Boolean;
    /// <summary>
    ///   getResearchProgress: the key of the text that describes how it goes (STR_NONE, STR_UNKNOWN, STR_POOR,
    ///   STR_AVERAGE, STR_GOOD, STR_EXCELLENT). The ratios are computed with floats as the C++ does; a topic with
    ///   cost zero divides by zero there and gets an infinite or not a number ratio, which the checks handle
    /// </summary>
    function ResearchProgress: string;
  end;

implementation

const
  PROGRESS_LIMIT_UNKNOWN: Single = 0.333;
  PROGRESS_LIMIT_POOR: Single = 0.07;
  PROGRESS_LIMIT_AVERAGE: Single = 0.13;
  PROGRESS_LIMIT_GOOD: Single = 0.25;

{ TXcomResearchProject }

constructor TXcomResearchProject.Create(const AProject: TXcomRuleResearch; ACost: Integer);
begin
  inherited Create;
  FProject := AProject;
  FCost := ACost;
end;

procedure TXcomResearchProject.Load(const ANode: IYamlNode);
begin
  FAssigned := TXcomNodeReader.ReadInteger(ANode, 'assigned', FAssigned);
  FSpent := TXcomNodeReader.ReadInteger(ANode, 'spent', FSpent);
  FCost := TXcomNodeReader.ReadInteger(ANode, 'cost', FCost);
end;

function TXcomResearchProject.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'project', FProject.Name);
  TXcomNodeWriter.SetInteger(Result, 'assigned', FAssigned);
  TXcomNodeWriter.SetInteger(Result, 'spent', FSpent);
  TXcomNodeWriter.SetInteger(Result, 'cost', FCost);
end;

function TXcomResearchProject.IsFinished: Boolean;
begin
  Result := FSpent >= FCost;
end;

function TXcomResearchProject.Step: Boolean;
begin
  Inc(FSpent, FAssigned);
  Result := IsFinished;
end;

function TXcomResearchProject.ResearchProgress: string;
var
  LProgress, LRating, LCost: Single;
  LRuleCost: Integer;
begin
  LRuleCost := FProject.Cost;
  if FAssigned = 0 then
    Exit('STR_NONE');
  if LRuleCost = 0 then
  begin
    // float / 0: +inf, -inf or nan (nan fails every comparison)
    if FSpent < 0 then
      Exit('STR_UNKNOWN');
    if FAssigned > 0 then
      Exit('STR_EXCELLENT');
    Exit('STR_POOR');
  end;
  LCost := LRuleCost;
  LProgress := Single(FSpent);
  LProgress := LProgress / LCost;
  if LProgress <= PROGRESS_LIMIT_UNKNOWN then
    Exit('STR_UNKNOWN');
  LRating := Single(FAssigned);
  LRating := LRating / LCost;
  if LRating <= PROGRESS_LIMIT_POOR then
    Exit('STR_POOR');
  if LRating <= PROGRESS_LIMIT_AVERAGE then
    Exit('STR_AVERAGE');
  if LRating <= PROGRESS_LIMIT_GOOD then
    Exit('STR_GOOD');
  Result := 'STR_EXCELLENT';
end;

end.
