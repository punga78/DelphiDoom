{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the values of the lines                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Values;

interface

uses
  System.SysUtils;

type
  /// <summary>How the numbers of a configuration file are read and written</summary>
  TConfigurationValues = class
  public
    /// <summary>
    ///   Decimal, hexadecimal (0x10, -0x10, $10) or with # (#10); anything else gives 0. Then:
    ///   three characters between the same quotes ('a', "7") are the code of the character, or
    ///   the digit; a lone character that is not a digit is its code. So a key can be written as 'q'
    /// </summary>
    class function ParseInteger(const AText: string): Integer; static;
    /// <summary>The number is not zero</summary>
    class function ParseBoolean(const AText: string): Boolean; static;
    class function FormatInteger(AValue: Integer): string; static;
    class function FormatBoolean(AValue: Boolean): string; static;
  end;

implementation

function IsDigit(AChar: Char): Boolean;
begin
  Result := (AChar >= '0') and (AChar <= '9');
end;

function ParseNumber(const AText: string): Integer;
var
  LCode, LOther: Integer;
begin
  Val(AText, Result, LCode);
  if LCode = 0 then
    Exit;
  LOther := 0;
  if AText.StartsWith('0x') then
    Val('$' + Copy(AText, 3, MaxInt), LOther, LCode)
  else if AText.StartsWith('-0x') then
  begin
    Val('$' + Copy(AText, 4, MaxInt), LOther, LCode);
    LOther := -LOther;
  end
  else if (AText <> '') and (AText[1] = '#') then
    Val(Copy(AText, 2, MaxInt), LOther, LCode);
  if LCode = 0 then
    Result := LOther
  else
    Result := 0;
end;

{ TConfigurationValues }

class function TConfigurationValues.ParseInteger(const AText: string): Integer;
begin
  Result := ParseNumber(AText);
  if Length(AText) = 3 then
  begin
    if ((AText[1] = '''') or (AText[1] = '"')) and (AText[1] = AText[3]) then
    begin
      if IsDigit(AText[2]) then
        Result := ParseNumber(AText[2])
      else
        Result := Ord(AText[2]);
    end;
  end;
  if Length(AText) = 1 then
    if not IsDigit(AText[1]) then
      Result := Ord(AText[1]);
end;

class function TConfigurationValues.ParseBoolean(const AText: string): Boolean;
begin
  Result := ParseNumber(AText) <> 0;
end;

class function TConfigurationValues.FormatInteger(AValue: Integer): string;
begin
  Result := IntToStr(AValue);
end;

class function TConfigurationValues.FormatBoolean(AValue: Boolean): string;
begin
  if AValue then
    Result := '1'
  else
    Result := '0';
end;

end.
