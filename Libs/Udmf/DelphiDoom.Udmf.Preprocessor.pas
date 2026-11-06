{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the text before it is read                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Preprocessor;

interface

type
  /// <summary>
  ///   Makes the text of a map simple to read: no comments, the = and the ; become a space and
  ///   a new line and the braces become the words _BEGINBLOCK and _ENDBLOCK, each on its own line.
  ///   It is the one of the old code, with its defects: the characters of the end of a block
  ///   comment (the star and the slash) are left in the text
  /// </summary>
  TUdmfPreprocessor = class
  public
    class function Process(const AText: string): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TUdmfPreprocessor }

class function TUdmfPreprocessor.Process(const AText: string): string;
var
  LText: string;
  LIndex: Integer;
  LLength: Integer;
  LInQuotes: Boolean;
  LInComment: Boolean;
  LInLineComment: Boolean;
  LResult: TStringBuilder;
begin
  LText := AText + #13#10;
  LResult := TStringBuilder.Create;
  try
    LInQuotes := False;
    LInComment := False;
    LInLineComment := False;
    LIndex := 1;
    LLength := Length(LText);
    while LIndex < LLength do
    begin
      if LText[LIndex] = '"' then
        if not (LInComment or LInLineComment) then
          LInQuotes := not LInQuotes;
      if not LInQuotes then
      begin
        if LText[LIndex] = '/' then
        begin
          if LText[LIndex + 1] = '/' then
            LInLineComment := True
          else if LText[LIndex + 1] = '*' then
            LInComment := True;
        end;
        if (LText[LIndex] = #13) or (LText[LIndex] = #10) then
          LInLineComment := False;
        if LText[LIndex] = '*' then
          if LText[LIndex + 1] = '/' then
            LInComment := False;
      end;
      if not (LInComment or LInLineComment) then
      begin
        if LInQuotes then
          LResult.Append(LText[LIndex])
        else if LText[LIndex] = '=' then
          LResult.Append(' ')
        else if LText[LIndex] = '{' then
          LResult.Append(#13#10'_BEGINBLOCK'#13#10)
        else if LText[LIndex] = '}' then
          LResult.Append(#13#10'_ENDBLOCK'#13#10)
        else if LText[LIndex] = ';' then
          LResult.Append(#13#10)
        else
          LResult.Append(LText[LIndex]);
      end;
      Inc(LIndex);
    end;
    Result := LResult.ToString;
  finally
    LResult.Free;
  end;
end;

end.