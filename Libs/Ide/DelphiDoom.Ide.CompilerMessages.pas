{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - reading the messages of the script compiler       }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.CompilerMessages;

interface

uses
  DelphiDoom.Ide.Types;

type
  /// <summary>
  ///   The text the compiler gives back, for example
  ///   " Pos: 000046 Compiler: [Error] (6:3): Unknown identifier 'UnknownFunc'"
  /// </summary>
  TIdeCompilerMessages = class
  public
    /// <summary>The lines of the text, as a string list would cut them</summary>
    class function SplitLines(const AMessages: string): TArray<string>; static;
    /// <summary>
    ///   Finds where the first error is: the digits between "[Error]" and the first "):" are two
    ///   numbers, the line and the column. It is the rule of the old editor, so a name with digits
    ///   before the brackets (as in "unit1(2:3)") confuses it, and then there is no location.
    ///   Gives false if there is no error, or the numbers are not two
    /// </summary>
    class function TryFindErrorLocation(const AMessages: string;
      out ALocation: TIdeSourceLocation): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Text;

{ TIdeCompilerMessages }

class function TIdeCompilerMessages.SplitLines(const AMessages: string): TArray<string>;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AMessages;
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

class function TIdeCompilerMessages.TryFindErrorLocation(const AMessages: string;
  out ALocation: TIdeSourceLocation): Boolean;
var
  LErrorPosition, LCloseBracketPosition, LIndex: Integer;
  LDigits: string;
  LLine, LColumn: string;
begin
  Result := False;
  ALocation.Line := -1;
  ALocation.Column := -1;
  if AMessages = '' then
    Exit;
  LErrorPosition := Pos('[Error]', AMessages);
  LCloseBracketPosition := Pos('):', AMessages);
  // the old code went on with a position of 0 (a text without "[Error]") and read the string
  // before its first character
  if (LErrorPosition = 0) or (LCloseBracketPosition <= LErrorPosition) then
    Exit;
  LDigits := '';
  for LIndex := LErrorPosition to LCloseBracketPosition do
    if CharInSet(AMessages[LIndex], ['0'..'9']) then
      LDigits := LDigits + AMessages[LIndex]
    else
      LDigits := LDigits + ' ';
  TIdeText.SplitPair(Trim(LDigits), ' ', LLine, LColumn);
  ALocation.Line := StrToIntDef(LLine, -1);
  ALocation.Column := StrToIntDef(LColumn, -1);
  Result := (ALocation.Line >= 0) and (ALocation.Column >= 0);
end;

end.
