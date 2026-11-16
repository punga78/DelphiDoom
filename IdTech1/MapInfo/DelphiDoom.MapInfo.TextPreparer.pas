{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the text for the scanner                    }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.TextPreparer;

interface

type
  /// <summary>
  ///   Turns the text of UMAPINFO into the words the parser reads (the old U_Preproccessor):
  ///   it drops the comments and the commas, puts spaces around "=" and makes "{" and "}"
  ///   words of their own (_BEGINBLOCK, _ENDBLOCK). What is between quotes is not touched
  /// </summary>
  TMapInfoTextPreparer = class
  public
    class function Prepare(const AText: string): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TMapInfoTextPreparer }

class function TMapInfoTextPreparer.Prepare(const AText: string): string;
var
  LText: string;
  LBuilder: TStringBuilder;
  LIndex: Integer;
  LLength: Integer;
  LChar: Char;
  LInQuotes: Boolean;
  LInBlockComment: Boolean;
  LInLineComment: Boolean;
begin
  LText := AText + #13#10;
  LBuilder := TStringBuilder.Create;
  try
    LInQuotes := False;
    LInBlockComment := False;
    LInLineComment := False;
    LIndex := 1;
    // the last character (the line feed that was added) is not read, like the old code
    LLength := Length(LText);
    while LIndex < LLength do
    begin
      LChar := LText[LIndex];
      if LChar = '"' then
        if not (LInBlockComment or LInLineComment) then
          LInQuotes := not LInQuotes;
      if not LInQuotes then
      begin
        if LChar = '/' then
        begin
          if LText[LIndex + 1] = '/' then
            LInLineComment := True
          else if LText[LIndex + 1] = '*' then
            LInBlockComment := True;
        end;
        if (LChar = #13) or (LChar = #10) then
          LInLineComment := False;
        if LChar = '*' then
          if LText[LIndex + 1] = '/' then
            LInBlockComment := False;
      end;
      if not (LInBlockComment or LInLineComment) then
      begin
        if LInQuotes then
          LBuilder.Append(LChar)
        else if LChar = ',' then
        begin
          // the commas that separate the values are dropped
        end
        else if LChar = '=' then
          LBuilder.Append(' = ')
        else if LChar = '{' then
          LBuilder.Append(#13#10'_BEGINBLOCK'#13#10)
        else if LChar = '}' then
          LBuilder.Append(#13#10'_ENDBLOCK'#13#10)
        else
          LBuilder.Append(LChar);
      end;
      Inc(LIndex);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
