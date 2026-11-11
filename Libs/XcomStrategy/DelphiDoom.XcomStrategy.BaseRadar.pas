{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the radars of a base (Base::detect and  }
{  Base::insideRadarRange)                                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.BaseRadar;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.Ufo;

type
  /// <summary>
  ///   What the radars of the facilities of a base see. The ruleset gives the range and the chance of each
  ///   facility; the generator is injected
  /// </summary>
  TXcomBaseRadar = class
  strict private
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    function RuleOf(const AFacility: TXcomBaseFacility): TXcomRuleBaseFacility;
  public
    constructor Create(const ARuleset: TXcomRuleset; const ARandom: IXcomRandom);
    /// <summary>
    ///   detect: 0 not seen, 1 seen by a conventional radar (the chances of the facilities in range add up and
    ///   are made worse by the size of a UFO), 2 seen by a hyper-wave decoder (the first one that makes its
    ///   roll)
    /// </summary>
    function Detect(const ABase: TXcomBase; const ATarget: TXcomTarget): Integer;
    /// <summary>insideRadarRange: 0 outside, 1 inside a conventional radar, 2 inside a hyper-wave decoder</summary>
    function InsideRadarRange(const ABase: TXcomBase; const ATarget: TXcomTarget): Integer;
  end;

implementation

{ TXcomBaseRadar }

constructor TXcomBaseRadar.Create(const ARuleset: TXcomRuleset; const ARandom: IXcomRandom);
begin
  inherited Create;
  if not Assigned(ARuleset) then
    raise EArgumentNilException.Create('ARuleset');
  FRuleset := ARuleset;
  FRandom := ARandom;
end;

function TXcomBaseRadar.RuleOf(const AFacility: TXcomBaseFacility): TXcomRuleBaseFacility;
begin
  Result := FRuleset.Facilities.Find(AFacility.Rules.FacilityType);
end;

function TXcomBaseRadar.Detect(const ABase: TXcomBase; const ATarget: TXcomTarget): Integer;
var
  LChance, LRadarChance: Integer;
  LDistance: Double;
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
begin
  LChance := 0;
  // getDistance(target) * 60.0 * (180.0 / M_PI)
  LDistance := ABase.Distance(ATarget);
  LDistance := LDistance * 60.0;
  LDistance := LDistance * (180.0 / 3.14159265358979323846);
  for LFacility in ABase.Facilities do
  begin
    LRule := RuleOf(LFacility);
    if (LRule.RadarRange >= LDistance) and (LFacility.BuildTime = 0) then
    begin
      LRadarChance := LRule.RadarChance;
      if LRule.IsHyperwave then
      begin
        if (LRadarChance = 100) or (FRandom.Generate(0, 99) < LRadarChance) then
          Exit(2);
      end
      else
        Inc(LChance, LRadarChance);
    end;
  end;
  if LChance = 0 then
    Exit(0);
  if ATarget is TXcomUfo then
    LChance := LChance * (100 + TXcomUfo(ATarget).Visibility) div 100;
  if FRandom.Generate(0, 99) < LChance then
    Result := 1
  else
    Result := 0;
end;

function TXcomBaseRadar.InsideRadarRange(const ABase: TXcomBase; const ATarget: TXcomTarget): Integer;
var
  LInside: Boolean;
  LDistance: Double;
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
begin
  LInside := False;
  LDistance := ABase.Distance(ATarget);
  LDistance := LDistance * 60.0;
  LDistance := LDistance * (180.0 / 3.14159265358979323846);
  for LFacility in ABase.Facilities do
  begin
    LRule := RuleOf(LFacility);
    if (LRule.RadarRange >= LDistance) and (LFacility.BuildTime = 0) then
    begin
      if LRule.IsHyperwave then
        Exit(2);
      LInside := True;
    end;
  end;
  if LInside then
    Result := 1
  else
    Result := 0;
end;

end.
