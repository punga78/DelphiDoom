{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the events a script can handle                    }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.EventSnippets;

interface

type
  /// <summary>An event of the game: the name for the menu and the text to write in a script</summary>
  TIdeEventEntry = record
    Name: string;
    /// <summary>The lines of the declaration, separated by "|"</summary>
    Declaration: string;
  end;

  /// <summary>
  ///   The "Events" menu of the script editor: the library gives a line "Name|first line|second
  ///   line|..." for each event, and the editor writes the declaration at the end of the script
  /// </summary>
  TIdeEventSnippets = class
  public
    /// <summary>The name and the declaration from each line of the library; a line without "|" has no declaration</summary>
    class function Parse(const ALines: TArray<string>): TArray<TIdeEventEntry>; static;
    /// <summary>
    ///   The text with the declaration added after two empty lines. A script that is empty (or only
    ///   spaces) starts with "uses all;" first. The offset is where the caret goes in the new text:
    ///   inside the begin and end of the event, three characters before its "end;" (the
    ///   offset is of the characters of the new text)
    /// </summary>
    class function Append(const ADeclaration, ACurrentText: string; out ACaretOffset: Integer): string; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Text;

{ TIdeEventSnippets }

class function TIdeEventSnippets.Parse(const ALines: TArray<string>): TArray<TIdeEventEntry>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ALines));
  for LIndex := 0 to High(ALines) do
    TIdeText.SplitPair(ALines[LIndex], '|', Result[LIndex].Name, Result[LIndex].Declaration);
end;

class function TIdeEventSnippets.Append(const ADeclaration, ACurrentText: string;
  out ACaretOffset: Integer): string;
var
  LDeclaration: string;
  LPosition: Integer;
begin
  LDeclaration := #13#10#13#10 + StringReplace(ADeclaration, '|', #13#10, [rfReplaceAll]);
  if Trim(ACurrentText) = '' then
    LDeclaration := 'uses'#13#10'  all;'#13#10 + LDeclaration;
  LPosition := Pos('end;', LDeclaration);
  if LPosition > 3 then
    LPosition := LPosition - 3
  else
    LPosition := 0;
  ACaretOffset := Length(ACurrentText) + LPosition;
  Result := ACurrentText + LDeclaration;
end;

end.
