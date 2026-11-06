{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - numbers and booleans typed by the user        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Numbers;

interface

type
  /// <summary>How the console reads the values that the user types</summary>
  TConsoleNumbers = class
  public
    /// <summary>
    ///   What Val reads, plus "0x" and "-0x" with hexadecimal digits and "#" with decimal
    ///   digits; what is not a number gives 0
    /// </summary>
    class function ParseInteger(const AText: string): Integer; static;
    /// <summary>TRUE, ON, YES, 1 and FALSE, OFF, NO, 0 in any case; anything else is ADefault</summary>
    class function EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Console.Text;

const
  TRUE_VALUES: array[0..3] of string = ('TRUE', 'ON', 'YES', '1');
  FALSE_VALUES: array[0..3] of string = ('FALSE', 'OFF', 'NO', '0');

{ TConsoleNumbers }

class function TConsoleNumbers.ParseInteger(const AText: string): Integer;
var
  LCode: Integer;
  LOther: Integer;
begin
  Val(AText, Result, LCode);
  if LCode = 0 then
    Exit;
  LOther := 0;
  if TConsoleText.StartsWith('0x', AText) then
    Val('$' + Copy(AText, 3, Length(AText) - 2), LOther, LCode)
  else if TConsoleText.StartsWith('-0x', AText) then
  begin
    Val('$' + Copy(AText, 4, Length(AText) - 3), LOther, LCode);
    LOther := -LOther;
  end
  else if (Length(AText) > 0) and (AText[1] = '#') then
    Val(Copy(AText, 2, Length(AText) - 1), LOther, LCode);
  if LCode = 0 then
    Result := LOther
  else
    Result := 0;
end;

class function TConsoleNumbers.EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
var
  LUpper: string;
  LIndex: Integer;
begin
  LUpper := TConsoleText.UpperCase(AText);
  for LIndex := Low(TRUE_VALUES) to High(TRUE_VALUES) do
    if LUpper = TRUE_VALUES[LIndex] then
      Exit(True);
  for LIndex := Low(FALSE_VALUES) to High(FALSE_VALUES) do
    if LUpper = FALSE_VALUES[LIndex] then
      Exit(False);
  Result := ADefault;
end;

end.
