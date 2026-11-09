{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - LanguagePlurality of OpenXcom              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.LanguagePlurality;

interface

uses
  System.SysUtils;

type
  /// <summary>The plural rules of the languages of OpenXcom (the subclasses of LanguagePlurality)</summary>
  TXcomPluralRule = (prOneSingular, prZeroOneSingular, prNoSingular, prCyrillic, prCzech, prPolish, prRomanian,
    prCroatian);

  /// <summary>Tells the suffix of a string key (_one, _few, _many, _other) for a number, by language</summary>
  TXcomLanguagePlurality = class
  strict private
    FRule: TXcomPluralRule;
  public
    constructor Create(ARule: TXcomPluralRule);
    /// <summary>LanguagePlurality::create: the rule of the language id (English-like when unknown)</summary>
    class function ForLanguage(const ALanguage: string): TXcomLanguagePlurality; static;
    /// <summary>LanguagePlurality::getSuffix, with the unsigned arithmetic of the C++</summary>
    function Suffix(AValue: Cardinal): string;
  end;

implementation

constructor TXcomLanguagePlurality.Create(ARule: TXcomPluralRule);
begin
  inherited Create;
  FRule := ARule;
end;

class function TXcomLanguagePlurality.ForLanguage(const ALanguage: string): TXcomLanguagePlurality;
begin
  if (ALanguage = 'fr') or (ALanguage = 'fr-CA') then
    Result := TXcomLanguagePlurality.Create(prZeroOneSingular)
  else if (ALanguage = 'hu') or (ALanguage = 'tr') or (ALanguage = 'ja') or (ALanguage = 'ko') or
    (ALanguage = 'zh-CN') or (ALanguage = 'zh-TW') then
    Result := TXcomLanguagePlurality.Create(prNoSingular)
  else if (ALanguage = 'cs') or (ALanguage = 'sk') then
    Result := TXcomLanguagePlurality.Create(prCzech)
  else if ALanguage = 'pl' then
    Result := TXcomLanguagePlurality.Create(prPolish)
  else if ALanguage = 'ro' then
    Result := TXcomLanguagePlurality.Create(prRomanian)
  else if (ALanguage = 'ru') or (ALanguage = 'uk') then
    Result := TXcomLanguagePlurality.Create(prCyrillic)
  else if ALanguage = 'hr' then
    Result := TXcomLanguagePlurality.Create(prCroatian)
  else
    Result := TXcomLanguagePlurality.Create(prOneSingular);
end;

function TXcomLanguagePlurality.Suffix(AValue: Cardinal): string;
var
  LMod10: Cardinal;
  LMod100: Cardinal;
begin
  LMod10 := AValue mod 10;
  LMod100 := AValue mod 100;
  Result := '_other';
  case FRule of
    prOneSingular:
      if AValue = 1 then
        Result := '_one';
    prZeroOneSingular:
      if (AValue = 0) or (AValue = 1) then
        Result := '_one';
    prNoSingular:
      ;
    prCyrillic:
      if (LMod10 = 1) and (LMod100 <> 11) then
        Result := '_one'
      else if (LMod10 >= 2) and (LMod10 <= 4) and not ((LMod100 >= 12) and (LMod100 <= 14)) then
        Result := '_few'
      else if (LMod10 = 0) or ((LMod10 >= 5) and (LMod10 <= 9)) or ((LMod100 >= 11) and (LMod100 <= 14)) then
        Result := '_many';
    prCzech:
      if AValue = 1 then
        Result := '_one'
      else if (AValue >= 2) and (AValue <= 4) then
        Result := '_few';
    prPolish:
      if AValue = 1 then
        Result := '_one'
      else if (LMod10 >= 2) and (LMod10 <= 4) and not ((LMod100 >= 12) and (LMod100 <= 14)) then
        Result := '_few'
      else if (LMod10 <= 1) or ((LMod10 >= 5) and (LMod10 <= 9)) or ((LMod100 >= 12) and (LMod100 <= 14)) then
        Result := '_many';
    prRomanian:
      if AValue = 1 then
        Result := '_one'
      else if (AValue = 0) or ((LMod100 >= 1) and (LMod100 <= 19)) then
        Result := '_few';
    prCroatian:
      if (LMod10 = 1) and (LMod100 <> 11) then
        Result := '_one'
      else if (LMod10 >= 2) and (LMod10 <= 4) and not ((LMod100 >= 12) and (LMod100 <= 14)) then
        Result := '_few';
  end;
end;

end.
