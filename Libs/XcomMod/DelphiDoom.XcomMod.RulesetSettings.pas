{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the numbers and texts of the ruleset      }
{  that are not a rule (costs, AI turns, defeat, difficulty, stat growth)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RulesetSettings;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.UnitStats;

type
  /// <summary>StatAdjustment: how a difficulty level changes the stats of the aliens</summary>
  TXcomStatAdjustment = record
    StatGrowth: TXcomUnitStats;
    GrowthMultiplier: Integer;
    AimAndArmorMultiplier: Double;
  end;

  /// <summary>
  ///   The values of the ruleset files that are not rules: the price of engineers and scientists, the time to
  ///   hire, the initial funding, the fuel of the aliens, the font, the turns when the AI uses grenades and
  ///   blasters, the defeat limits, the difficulty coefficients and stat growth by level (members of Mod)
  /// </summary>
  TXcomRulesetSettings = class
  public
    const
      DIFFICULTY_LEVELS = 5;
  strict private
    FCostEngineer: Integer;
    FCostScientist: Integer;
    FTimePersonnel: Integer;
    FInitialFunding: Integer;
    FTurnAIUseGrenade: Integer;
    FTurnAIUseBlaster: Integer;
    FDefeatScore: Integer;
    FDefeatFunds: Integer;
    FDifficultyDemigod: Boolean;
    FAlienFuelName: string;
    FAlienFuelQuantity: Integer;
    FFontName: string;
    FAlienItemLevels: TArray<TArray<Integer>>;
    FStatAdjustment: array[0..DIFFICULTY_LEVELS - 1] of TXcomStatAdjustment;
    FDifficultyCoefficient: array[0..DIFFICULTY_LEVELS - 1] of Integer;
    function GetStatAdjustment(ALevel: Integer): TXcomStatAdjustment;
    function GetDifficultyCoefficient(ALevel: Integer): Integer;
    procedure ReadAlienFuel(const ADocument: IYamlNode);
  public
    /// <summary>The defaults of the constructor of Mod</summary>
    constructor Create;
    /// <summary>The part of Mod::loadFile that reads these values; what the document does not have stays</summary>
    procedure Load(const ADocument: IYamlNode);
    property CostEngineer: Integer read FCostEngineer;
    property CostScientist: Integer read FCostScientist;
    property TimePersonnel: Integer read FTimePersonnel;
    property InitialFunding: Integer read FInitialFunding;
    property TurnAIUseGrenade: Integer read FTurnAIUseGrenade;
    property TurnAIUseBlaster: Integer read FTurnAIUseBlaster;
    property DefeatScore: Integer read FDefeatScore;
    property DefeatFunds: Integer read FDefeatFunds;
    property DifficultyDemigod: Boolean read FDifficultyDemigod;
    property AlienFuelName: string read FAlienFuelName;
    property AlienFuelQuantity: Integer read FAlienFuelQuantity;
    property FontName: string read FFontName;
    property AlienItemLevels: TArray<TArray<Integer>> read FAlienItemLevels;
    /// <summary>The adjustment of a difficulty level (0 to 4)</summary>
    property StatAdjustment[ALevel: Integer]: TXcomStatAdjustment read GetStatAdjustment;
    /// <summary>DIFFICULTY_COEFFICIENT of a level (0 to 4)</summary>
    property DifficultyCoefficient[ALevel: Integer]: Integer read GetDifficultyCoefficient;
  end;

implementation

{ TXcomRulesetSettings }

constructor TXcomRulesetSettings.Create;
var
  LLevel: Integer;
begin
  inherited Create;
  FTurnAIUseGrenade := 3;
  FTurnAIUseBlaster := 3;
  FStatAdjustment[0].AimAndArmorMultiplier := 0.5;
  FStatAdjustment[0].GrowthMultiplier := 0;
  for LLevel := 1 to DIFFICULTY_LEVELS - 1 do
  begin
    FStatAdjustment[LLevel].AimAndArmorMultiplier := 1.0;
    FStatAdjustment[LLevel].GrowthMultiplier := LLevel;
  end;
  // the statics that Mod::resetGlobalStatics sets
  for LLevel := 0 to DIFFICULTY_LEVELS - 1 do
    FDifficultyCoefficient[LLevel] := LLevel;
end;

function TXcomRulesetSettings.GetStatAdjustment(ALevel: Integer): TXcomStatAdjustment;
begin
  Result := FStatAdjustment[ALevel];
end;

function TXcomRulesetSettings.GetDifficultyCoefficient(ALevel: Integer): Integer;
begin
  Result := FDifficultyCoefficient[ALevel];
end;

procedure TXcomRulesetSettings.ReadAlienFuel(const ADocument: IYamlNode);
var
  LField: IYamlNode;
begin
  // as<std::pair<std::string, int>>(pair): a sequence of two items; anything else leaves it
  LField := TXcomNodeReader.Field(ADocument, 'alienFuel');
  if not LField.IsDefined or not LField.IsSequence or (LField.Size <> 2) then
    Exit;
  FAlienFuelName := TXcomNodeReader.TextOf(LField.Find(0));
  FAlienFuelQuantity := LField.Find(1).AsInteger;
end;

procedure TXcomRulesetSettings.Load(const ADocument: IYamlNode);
var
  LField, LItem: IYamlNode;
  LLevel: Integer;
begin
  FCostEngineer := TXcomNodeReader.ReadInteger(ADocument, 'costEngineer', FCostEngineer);
  FCostScientist := TXcomNodeReader.ReadInteger(ADocument, 'costScientist', FCostScientist);
  FTimePersonnel := TXcomNodeReader.ReadInteger(ADocument, 'timePersonnel', FTimePersonnel);
  FInitialFunding := TXcomNodeReader.ReadInteger(ADocument, 'initialFunding', FInitialFunding);
  ReadAlienFuel(ADocument);
  FFontName := TXcomNodeReader.ReadString(ADocument, 'fontName', FFontName);
  FTurnAIUseGrenade := TXcomNodeReader.ReadInteger(ADocument, 'turnAIUseGrenade', FTurnAIUseGrenade);
  FTurnAIUseBlaster := TXcomNodeReader.ReadInteger(ADocument, 'turnAIUseBlaster', FTurnAIUseBlaster);
  FDefeatScore := TXcomNodeReader.ReadInteger(ADocument, 'defeatScore', FDefeatScore);
  FDefeatFunds := TXcomNodeReader.ReadInteger(ADocument, 'defeatFunds', FDefeatFunds);
  FDifficultyDemigod := TXcomNodeReader.ReadBoolean(ADocument, 'difficultyDemigod', FDifficultyDemigod);
  LField := TXcomNodeReader.Field(ADocument, 'difficultyCoefficient');
  if LField.IsDefined then
  begin
    LLevel := 0;
    for LItem in LField.Items do
    begin
      if LLevel >= DIFFICULTY_LEVELS then
        Break;
      FDifficultyCoefficient[LLevel] := LItem.AsInteger(FDifficultyCoefficient[LLevel]);
      FStatAdjustment[LLevel].GrowthMultiplier := FDifficultyCoefficient[LLevel];
      Inc(LLevel);
    end;
  end;
  FAlienItemLevels := TXcomNodeReader.ReadIntegerRows(ADocument, 'alienItemLevels', FAlienItemLevels);
  LLevel := 0;
  for LItem in TXcomNodeReader.Field(ADocument, 'aimAndArmorMultipliers').Items do
  begin
    if LLevel >= DIFFICULTY_LEVELS then
      Break;
    FStatAdjustment[LLevel].AimAndArmorMultiplier := LItem.AsDouble(FStatAdjustment[LLevel].AimAndArmorMultiplier);
    Inc(LLevel);
  end;
  LField := TXcomNodeReader.Field(ADocument, 'statGrowthMultipliers');
  if LField.IsDefined then
  begin
    FStatAdjustment[0].StatGrowth := TXcomUnitStatsReader.Decode(LField, FStatAdjustment[0].StatGrowth);
    for LLevel := 1 to DIFFICULTY_LEVELS - 1 do
      FStatAdjustment[LLevel].StatGrowth := FStatAdjustment[0].StatGrowth;
  end;
end;

end.
