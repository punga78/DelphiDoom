{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom rules library - the stat string of a soldier               }
{  (StatString::calcStatString)                                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.StatStringCalculator;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.StatString;

type
  /// <summary>
  ///   Works out the string that goes after the name of a soldier from its current stats (the letters or marks
  ///   that the rules of the mod give to good and bad stats)
  /// </summary>
  TXcomStatStringCalculator = class
  public
    /// <summary>
    ///   calcStatString: the strings of the rules whose conditions are all met are added, in the order of the
    ///   rules, up to the first that is longer than one byte (it ends the list). A condition on a stat that
    ///   does not exist is not met: only a soldier in psionic training has "psiTraining". psiStrength and
    ///   psiSkill count only for a soldier with psi skill or when the strength is evaluated anyway
    /// </summary>
    class function Calculate(const AStats: TXcomUnitStats; const AStatStrings: TObjectList<TXcomStatString>;
      APsiStrengthEval, AInTraining: Boolean): string; static;
  end;

implementation

{ TXcomStatStringCalculator }

class function TXcomStatStringCalculator.Calculate(const AStats: TXcomUnitStats;
  const AStatStrings: TObjectList<TXcomStatString>; APsiStrengthEval, AInTraining: Boolean): string;

  function StatOf(const AName: string; out AValue: Integer): Boolean;
  begin
    Result := True;
    if AName = 'psiStrength' then
      AValue := AStats.PsiStrength
    else if AName = 'psiSkill' then
      AValue := AStats.PsiSkill
    else if AName = 'bravery' then
      AValue := AStats.Bravery
    else if AName = 'strength' then
      AValue := AStats.Strength
    else if AName = 'firing' then
      AValue := AStats.Firing
    else if AName = 'reactions' then
      AValue := AStats.Reactions
    else if AName = 'stamina' then
      AValue := AStats.Stamina
    else if AName = 'tu' then
      AValue := AStats.TimeUnits
    else if AName = 'health' then
      AValue := AStats.Health
    else if AName = 'throwing' then
      AValue := AStats.Throwing
    else if AName = 'melee' then
      AValue := AStats.Melee
    else if (AName = 'psiTraining') and AInTraining then
      AValue := 1
    else
    begin
      AValue := 0;
      Result := False;
    end;
  end;

var
  LString: TXcomStatString;
  LCondition: TXcomStatStringCondition;
  LValue: Integer;
  LMet: Boolean;
begin
  Result := '';
  for LString in AStatStrings do
  begin
    LMet := True;
    for LCondition in LString.Conditions do
    begin
      if not LMet then
        Break;
      if StatOf(LCondition.ConditionName, LValue) then
        LMet := LCondition.IsMet(LValue, (AStats.PsiSkill > 0) or APsiStrengthEval)
      else
        // a stat that does not exist: the soldier is not in training
        LMet := False;
    end;
    if LMet then
    begin
      Result := Result + LString.Text;
      // the length of the std::string is in bytes
      if Length(TEncoding.UTF8.GetBytes(LString.Text)) > 1 then
        Break;
    end;
  end;
end;

end.
