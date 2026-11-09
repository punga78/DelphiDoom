{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a country in a game (Country)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Country;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleCountry, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>
  ///   Represents a country that funds the player, with its funding and the activity of aliens and X-COM over
  ///   the last months. The lists keep one entry per month (the last one is the current month); functions that use
  ///   the last entry of an empty list (undefined in the C++) raise EXcomModException
  /// </summary>
  TXcomCountry = class
  strict private
    FRules: TXcomRuleCountry;
    FPact: Boolean;
    FNewPact: Boolean;
    FFunding: TArray<Integer>;
    FActivityXcom: TArray<Integer>;
    FActivityAlien: TArray<Integer>;
    FSatisfaction: Integer;
    procedure AddActivityAlien(AActivity: Integer);
    class function LastOf(const AValues: TArray<Integer>): Integer; static;
    class procedure DropFirstIfLong(var AValues: TArray<Integer>); static;
  public
    /// <param name="ARules">Not owned</param>
    /// <param name="AGenerate">Whether to start with a random funding</param>
    constructor Create(const ARules: TXcomRuleCountry; AGenerate: Boolean; const ARandom: IXcomRandom);
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: TXcomRuleCountry read FRules;
    property Funding: TArray<Integer> read FFunding write FFunding;
    property ActivityXcom: TArray<Integer> read FActivityXcom write FActivityXcom;
    property ActivityAlien: TArray<Integer> read FActivityAlien write FActivityAlien;
    property Pact: Boolean read FPact write FPact;
    property NewPact: Boolean read FNewPact write FNewPact;
    /// <summary>setFunding: the funding of the current month</summary>
    procedure SetFunding(AValue: Integer);
    /// <summary>getSatisfaction: 0 = alien pact, 1 = unhappy, 2 = satisfied, 3 = happy</summary>
    function Satisfaction: Integer;
    /// <summary>
    ///   newMonth: counts the activity, changes the funding (within the cap) and starts a new month. A month
    ///   keeps at most 12 entries
    /// </summary>
    procedure NewMonth(AXcomTotal, AAlienTotal, APactScore: Integer; const ARandom: IXcomRandom);
  end;

implementation

const
  SNoMonth = 'Xcom: the country has no entry for the current month';

{ TXcomCountry }

constructor TXcomCountry.Create(const ARules: TXcomRuleCountry; AGenerate: Boolean; const ARandom: IXcomRandom);
begin
  inherited Create;
  FRules := ARules;
  FSatisfaction := 2;
  if AGenerate then
  begin
    SetLength(FFunding, 1);
    FFunding[0] := FRules.GenerateFunding(ARandom);
  end;
  SetLength(FActivityAlien, 1);
  SetLength(FActivityXcom, 1);
end;

class function TXcomCountry.LastOf(const AValues: TArray<Integer>): Integer;
begin
  if Length(AValues) = 0 then
    raise EXcomModException.Create(SNoMonth);
  Result := AValues[High(AValues)];
end;

class procedure TXcomCountry.DropFirstIfLong(var AValues: TArray<Integer>);
begin
  if Length(AValues) > 12 then
    Delete(AValues, 0, 1);
end;

procedure TXcomCountry.Load(const ANode: IYamlNode);

  function ReadIntegers(const AKey: string; const ADefault: TArray<Integer>): TArray<Integer>;
  var
    LField: IYamlNode;
    LItems: TArray<IYamlNode>;
    LIndex: Integer;
  begin
    LField := TXcomNodeReader.Field(ANode, AKey);
    if not LField.IsDefined or not LField.IsSequence then
      Exit(ADefault);
    LItems := LField.Items;
    SetLength(Result, Length(LItems));
    for LIndex := 0 to High(LItems) do
      Result[LIndex] := LItems[LIndex].AsInteger;
  end;

begin
  FFunding := ReadIntegers('funding', FFunding);
  FActivityXcom := ReadIntegers('activityXcom', FActivityXcom);
  FActivityAlien := ReadIntegers('activityAlien', FActivityAlien);
  FPact := TXcomNodeReader.ReadBoolean(ANode, 'pact', FPact);
  FNewPact := TXcomNodeReader.ReadBoolean(ANode, 'newPact', FNewPact);
end;

function TXcomCountry.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRules.CountryType);
  TXcomNodeWriter.SetIntegers(Result, 'funding', FFunding);
  TXcomNodeWriter.SetIntegers(Result, 'activityXcom', FActivityXcom);
  TXcomNodeWriter.SetIntegers(Result, 'activityAlien', FActivityAlien);
  if FPact then
    TXcomNodeWriter.SetBoolean(Result, 'pact', FPact)
  else if FNewPact then
    TXcomNodeWriter.SetBoolean(Result, 'newPact', FNewPact);
end;

procedure TXcomCountry.SetFunding(AValue: Integer);
begin
  LastOf(FFunding);
  FFunding[High(FFunding)] := AValue;
end;

function TXcomCountry.Satisfaction: Integer;
begin
  if FPact then
    Exit(0);
  Result := FSatisfaction;
end;

procedure TXcomCountry.AddActivityAlien(AActivity: Integer);
begin
  LastOf(FActivityAlien);
  Inc(FActivityAlien[High(FActivityAlien)], AActivity);
end;

procedure TXcomCountry.NewMonth(AXcomTotal, AAlienTotal, APactScore: Integer; const ARandom: IXcomRandom);
var
  LFunding, LGood, LBad, LOldFunding, LNewFunding, LCap: Integer;
begin
  FSatisfaction := 2;
  LFunding := LastOf(FFunding);
  LGood := AXcomTotal div 10 + LastOf(FActivityXcom);
  LBad := AAlienTotal div 20 + LastOf(FActivityAlien);
  LOldFunding := LastOf(FFunding) div 1000;
  LNewFunding := (LOldFunding * ARandom.Generate(5, 20) div 100) * 1000;
  if LBad <= LGood + 30 then
  begin
    if LGood > LBad + 30 then
      if ARandom.Generate(0, LGood) > LBad then
      begin
        // don't go over the cap
        LCap := FRules.FundingCap * 1000;
        if LFunding + LNewFunding > LCap then
          LNewFunding := LCap - LFunding;
        if LNewFunding <> 0 then
          FSatisfaction := 3;
      end;
  end
  else if ARandom.Generate(0, LBad) > LGood then
    if LNewFunding <> 0 then
    begin
      LNewFunding := -LNewFunding;
      // don't go below zero
      if LFunding + LNewFunding < 0 then
        LNewFunding := 0 - LFunding;
      if LNewFunding <> 0 then
        FSatisfaction := 1;
    end;
  // about to be in cahoots
  if FNewPact and not FPact then
  begin
    FNewPact := False;
    FPact := True;
    AddActivityAlien(APactScore);
  end;
  // set the new funding and reset the activity meters
  SetLength(FFunding, Length(FFunding) + 1);
  if FPact then
    FFunding[High(FFunding)] := 0
  else if FSatisfaction <> 2 then
    FFunding[High(FFunding)] := LFunding + LNewFunding
  else
    FFunding[High(FFunding)] := LFunding;
  SetLength(FActivityAlien, Length(FActivityAlien) + 1);
  SetLength(FActivityXcom, Length(FActivityXcom) + 1);
  DropFirstIfLong(FActivityAlien);
  DropFirstIfLong(FActivityXcom);
  DropFirstIfLong(FFunding);
end;

end.
