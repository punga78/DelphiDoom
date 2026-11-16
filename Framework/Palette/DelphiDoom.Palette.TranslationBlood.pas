{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the names and the regions of the blood colors }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.TranslationBlood;

interface

uses
  DelphiDoom.Palette.Types;

type
  /// <summary>
  ///   The blood colors of the actors (R_GetBloodTranslationIdForName, R_GetBloodName and
  ///   R_BloodTranslation of the old r_translations.pas): a fixed table, without state, so the
  ///   callers use it directly
  /// </summary>
  TTranslationBlood = class
  strict private
    const
      BLOOD_NAMES: array[0..BLOOD_COLOR_COUNT - 1] of string = (
        'RED', 'GRAY', 'GREEN', 'BLUE2', 'YELLOW', 'BLACK', 'PURPL', 'WHITE', 'ORANGE');
    class function IsDigitsOnly(const AText: string): Boolean; static;
  public
    /// <summary>
    ///   A number 0..BLOOD_COLOR_COUNT - 1, or a name (also with CR or CR_ before, PURPLE for
    ///   PURPL, any case): 0 if unknown
    /// </summary>
    class function IdForName(const AName: string): Integer; static;
    /// <summary>The name of a blood color: '' for 0 and for what does not exist</summary>
    class function NameOf(AId: Integer): string; static;
    /// <summary>The REGION_* of a blood color, -1 for 0 and unknown</summary>
    class function Region(ABlood: Integer): Integer; static;
  end;

implementation

uses
  System.SysUtils;

{ TTranslationBlood }

class function TTranslationBlood.IsDigitsOnly(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  Result := AText <> '';
  for LIndex := 1 to Length(AText) do
    if (AText[LIndex] < '0') or (AText[LIndex] > '9') then
      Exit(False);
end;

class function TTranslationBlood.IdForName(const AName: string): Integer;
var
  LNumber: Integer;
  LUpper: string;
  LIndex: Integer;
begin
  if IsDigitsOnly(AName) then
  begin
    if TryStrToInt(AName, LNumber) and (LNumber >= 0) and (LNumber <= BLOOD_COLOR_COUNT - 1) then
      Result := LNumber
    else
      Result := 0;
    Exit;
  end;
  LUpper := UpperCase(AName);
  if LUpper = 'PURPLE' then
    LUpper := 'PURPL';
  for LIndex := 0 to BLOOD_COLOR_COUNT - 1 do
    if (LUpper = BLOOD_NAMES[LIndex]) or (LUpper = 'CR' + BLOOD_NAMES[LIndex]) or
      (LUpper = 'CR_' + BLOOD_NAMES[LIndex]) then
      Exit(LIndex);
  Result := 0;
end;

class function TTranslationBlood.NameOf(AId: Integer): string;
begin
  if (AId < 1) or (AId > BLOOD_COLOR_COUNT - 1) then
    Result := ''
  else
    Result := BLOOD_NAMES[AId];
end;

class function TTranslationBlood.Region(ABlood: Integer): Integer;
begin
  case ABlood of
    1: Result := REGION_GRAY;
    2: Result := REGION_GREEN;
    3: Result := REGION_BLUE2;
    4: Result := REGION_YELLOW;
    5: Result := REGION_BLACK;
    6: Result := REGION_PURPL;
    7: Result := REGION_WHITE;
    8: Result := REGION_ORANGE;
  else
    Result := -1;
  end;
end;

end.
