{******************************************************************************}
{                                                                              }
{  DelphiDoom: obituary library - the genders and their pronouns               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Obituary.Genders;

interface

uses
  DelphiDoom.Obituary.Types;

type
  /// <summary>
  ///   The six genders of the game with their pronouns (the old GENDERINFO and
  ///   R_GetGenderForName). The table is compiled in and has no state: the engine calls it
  ///   directly
  /// </summary>
  TObituaryGenders = class
  strict private
    class function UpperCase(const AText: string): string; static;
    class procedure CheckGender(const AGender: TObituaryGender); static;
  public
    /// <summary>The name of a gender; EObituaryException if the gender is not known</summary>
    class function NameOf(const AGender: TObituaryGender): string; static;
    /// <summary>The pronouns of a gender; EObituaryException if the gender is not known</summary>
    class function PronounsOf(const AGender: TObituaryGender): TObituaryPronouns; static;
    /// <summary>
    ///   The gender that a text names: a number (decimal, $, 0x, #), a name in any case or
    ///   GENDER_ and a name; ogDefault if none
    /// </summary>
    class function FindByName(const AName: string): TObituaryGender; static;
  end;

implementation

uses
  System.SysUtils;

const
  GENDER_NAMES: array[TObituaryGender] of string = (
    'Default', 'Male', 'Female', 'Plural', 'Team', 'Neutral'
  );

  // %g, %h, %p, %s, %r
  GENDER_PRONOUNS: array[TObituaryGender] of array[0..4] of string = (
    ('it', 'it', 'its', 'its', 'it''s'),
    ('he', 'him', 'his', 'his', 'he''s'),
    ('she', 'her', 'her', 'hers', 'she''s'),
    ('they', 'them', 'their', 'theirs', 'they''re'),
    ('they', 'them', 'their', 'theirs', 'they''re'),
    ('it', 'it', 'its', 'its', 'it''s')
  );

  GENDER_PREFIX = 'GENDER_';

{ TObituaryGenders }

// only the letters a..z, as the names of the genders are plain ASCII
class function TObituaryGenders.UpperCase(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

class procedure TObituaryGenders.CheckGender(const AGender: TObituaryGender);
begin
  if Ord(AGender) >= OBITUARY_GENDER_COUNT then
    raise EObituaryException.CreateFmt(SObituaryUnknownGender, [Ord(AGender)]);
end;

class function TObituaryGenders.NameOf(const AGender: TObituaryGender): string;
begin
  CheckGender(AGender);
  Result := GENDER_NAMES[AGender];
end;

class function TObituaryGenders.PronounsOf(const AGender: TObituaryGender): TObituaryPronouns;
begin
  CheckGender(AGender);
  Result.Subject := GENDER_PRONOUNS[AGender][0];
  Result.ObjectForm := GENDER_PRONOUNS[AGender][1];
  Result.Possessive := GENDER_PRONOUNS[AGender][2];
  Result.Independent := GENDER_PRONOUNS[AGender][3];
  Result.Contraction := GENDER_PRONOUNS[AGender][4];
end;

class function TObituaryGenders.FindByName(const AName: string): TObituaryGender;
var
  LIndex: Integer;
  LCode: Integer;
  LUpper: string;
  LGender: TObituaryGender;
begin
  Result := ogDefault;

  Val(AName, LIndex, LCode);
  if (LCode <> 0) and (Copy(AName, 1, 1) = '#') then
    Val(Copy(AName, 2, Length(AName) - 1), LIndex, LCode);
  if (LCode = 0) and (LIndex >= 0) and (LIndex < OBITUARY_GENDER_COUNT) then
  begin
    Result := TObituaryGender(LIndex);
    Exit;
  end;

  LUpper := UpperCase(AName);
  for LGender := Low(TObituaryGender) to High(TObituaryGender) do
    if LUpper = UpperCase(GENDER_NAMES[LGender]) then
    begin
      Result := LGender;
      Exit;
    end;

  for LGender := Low(TObituaryGender) to High(TObituaryGender) do
    if LUpper = GENDER_PREFIX + UpperCase(GENDER_NAMES[LGender]) then
    begin
      Result := LGender;
      Exit;
    end;
end;

end.
