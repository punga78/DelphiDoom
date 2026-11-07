{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the tables the compiler library hands over        }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Csv;

interface

type
  /// <summary>
  ///   The "csv" the ddc_*.dll writes for mobjinfo, states and sprites: the first line has the
  ///   names of the columns, the cells are separated by semicolons and may be in quotes
  /// </summary>
  TIdeCsv = class
  public
    /// <summary>
    ///   The cells of a line, without the quotes around them. As in the old code, an empty cell at
    ///   the end of the line is not a cell, so a line that ends with one is shorter than the header
    /// </summary>
    class function ParseLine(const ALine: string): TArray<string>; static;
    /// <summary>
    ///   The cells of one column (found by the name in the first line, without regard to the case),
    ///   one for each line after the first; a short line gives an empty cell. A missing column
    ///   gives an empty list
    /// </summary>
    class function Column(const ALines: TArray<string>; const AColumnName: string): TArray<string>; static;
    /// <summary>
    ///   A number that is a multiple of 65536 (and 65536 or more) is written with FRACUNIT:
    ///   "65536" is FRACUNIT, "131072" is "2 * FRACUNIT". Any other text is not changed
    /// </summary>
    class function ExpandFracUnit(const AValue: string): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TIdeCsv }

class function TIdeCsv.ParseLine(const ALine: string): TArray<string>;
var
  LCells: TArray<string>;
  LCount: Integer;
  LToken: string;
  LIndex: Integer;

  function StripQuotes(const AText: string): string;
  begin
    if (Length(AText) >= 2) and (AText[1] = '"') and (AText[Length(AText)] = '"') then
      Result := Copy(AText, 2, Length(AText) - 2)
    else
      Result := AText;
  end;

  procedure Append(const AText: string);
  begin
    if LCount = Length(LCells) then
      SetLength(LCells, LCount * 2 + 8);
    LCells[LCount] := AText;
    Inc(LCount);
  end;

begin
  LCells := nil;
  LCount := 0;
  LToken := '';
  for LIndex := 1 to Length(ALine) do
    if ALine[LIndex] = ';' then
    begin
      Append(StripQuotes(LToken));
      LToken := '';
    end
    else
      LToken := LToken + ALine[LIndex];
  LToken := StripQuotes(LToken);
  if LToken <> '' then
    Append(LToken);
  SetLength(LCells, LCount);
  Result := LCells;
end;

class function TIdeCsv.Column(const ALines: TArray<string>; const AColumnName: string): TArray<string>;
var
  LHeader, LCells: TArray<string>;
  LColumn, LIndex: Integer;
begin
  Result := nil;
  if Length(ALines) = 0 then
    Exit;
  LHeader := ParseLine(ALines[0]);
  LColumn := -1;
  for LIndex := 0 to High(LHeader) do
    if UpperCase(AColumnName) = UpperCase(LHeader[LIndex]) then
    begin
      LColumn := LIndex;
      Break;
    end;
  if LColumn = -1 then
    Exit;
  SetLength(Result, Length(ALines) - 1);
  for LIndex := 1 to High(ALines) do
  begin
    LCells := ParseLine(ALines[LIndex]);
    if LColumn < Length(LCells) then
      Result[LIndex - 1] := LCells[LColumn]
    else
      Result[LIndex - 1] := '';
  end;
end;

class function TIdeCsv.ExpandFracUnit(const AValue: string): string;
var
  LNumber: Integer;
begin
  LNumber := StrToIntDef(AValue, -1);
  if LNumber < 65536 then
    Exit(AValue);
  if IntToStr(LNumber) <> AValue then
    Exit(AValue);
  if LNumber mod 65536 <> 0 then
    Exit(AValue);
  if LNumber = 65536 then
    Result := 'FRACUNIT'
  else
    Result := IntToStr(LNumber div 65536) + ' * FRACUNIT';
end;

end.
