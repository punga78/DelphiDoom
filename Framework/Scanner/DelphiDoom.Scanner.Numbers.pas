{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - numbers as texts, like the old script code     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Numbers;

interface

type
  /// <summary>
  ///   The conversions of d_delphi that the expressions use (StrIsFloat, atof, ftoa, itoa),
  ///   with the same results but without touching the global format settings: the point is
  ///   always the decimal separator
  /// </summary>
  TScannerNumbers = class
  public
    /// <summary>Digits with at most one . or , and an optional - in front</summary>
    class function IsFloat(const AText: string): Boolean; static;
    /// <summary>The number in a text, with . or , ; 0 if it is not one</summary>
    class function ToFloat(const AText: string): Single; static;
    /// <summary>The shortest text that reads back as the Extended value of the Single (FloatToStr)</summary>
    class function FloatToText(AValue: Single): string; static;
    class function IntToText(AValue: Integer): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TScannerNumbers }

class function TScannerNumbers.IsFloat(const AText: string): Boolean;
var
  LCheck: string;
  LIndex: Integer;
  LDot: Boolean;
begin
  Result := False;
  LDot := False;
  LCheck := AText;
  if LCheck = '' then
    Exit;
  if LCheck[1] = '-' then
    Delete(LCheck, 1, 1);
  for LIndex := 1 to Length(LCheck) do
  begin
    if CharInSet(LCheck[LIndex], ['0'..'9']) then
      Result := True
    else if (LCheck[LIndex] = '.') or (LCheck[LIndex] = ',') then
    begin
      if LDot then
        Exit(False);
      LDot := True;
    end
    else
      Exit(False);
  end;
end;

class function TScannerNumbers.ToFloat(const AText: string): Single;
var
  LCode: Integer;
  LText: string;
begin
  Val(AText, Result, LCode);
  if LCode = 0 then
    Exit;
  LText := AText.Replace(',', '.');
  Val(LText, Result, LCode);
  if LCode = 0 then
    Exit;
  LText := LText.Replace('.', ',');
  Val(LText, Result, LCode);
  if LCode = 0 then
    Exit;
  Result := 0.0;
end;

class function TScannerNumbers.FloatToText(AValue: Single): string;
var
  LSettings: TFormatSettings;
begin
  LSettings := TFormatSettings.Create;
  LSettings.DecimalSeparator := '.';
  LSettings.ThousandSeparator := #0;
  Result := FloatToStr(AValue, LSettings);
end;

class function TScannerNumbers.IntToText(AValue: Integer): string;
begin
  Result := IntToStr(AValue);
end;

end.
