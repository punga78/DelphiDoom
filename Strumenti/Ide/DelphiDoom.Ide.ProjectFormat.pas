{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the text of a project file                        }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ProjectFormat;

interface

uses
  DelphiDoom.Ide.Types;

type
  /// <summary>
  ///   Reads and writes the project file (".ddide"): a line "version|1.0", a line "game|name" and
  ///   one line "kind|path" for each item. The reader is as forgiving as the old one: a file
  ///   without the right version in the first line is an empty project, blank or broken lines
  ///   are items of kind none
  /// </summary>
  TIdeProjectFormat = class
  public
    /// <summary>
    ///   The lines after the version line, in order. A file that does not start with
    ///   "version|1.0" (any case for the word) gives nothing. The game names are lower case but
    ///   not checked: whoever applies them decides
    /// </summary>
    class function Parse(const AText: AnsiString): TArray<TIdeProjectDirective>; static;
    /// <summary>The text of a project, every line ends with CR LF</summary>
    class function Serialize(const AGame: string; const AEntries: TArray<TIdeProjectEntry>): AnsiString; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Text,
  DelphiDoom.Ide.ItemKinds;

{ TIdeProjectFormat }

class function TIdeProjectFormat.Parse(const AText: AnsiString): TArray<TIdeProjectDirective>;
var
  LLines: TStringList;
  LIndex: Integer;
  LWord, LValue: string;
  LDirective: TIdeProjectDirective;
begin
  Result := nil;
  LLines := TStringList.Create;
  try
    LLines.Text := string(AText);
    if LLines.Count = 0 then
      Exit;
    TIdeText.SplitPair(LLines[0], '|', LWord, LValue);
    if (AnsiCompareText(LWord, 'version') <> 0) or (LValue <> IDE_PROJECT_VERSION) then
      Exit;
    SetLength(Result, LLines.Count - 1);
    for LIndex := 1 to LLines.Count - 1 do
    begin
      TIdeText.SplitPair(LLines[LIndex], '|', LWord, LValue);
      if AnsiCompareText(LWord, 'game') = 0 then
      begin
        LDirective.IsGame := True;
        LDirective.Value := LowerCase(LValue);
        LDirective.Kind := ikNone;
      end
      else
      begin
        LDirective.IsGame := False;
        LDirective.Value := LValue;
        LDirective.Kind := TIdeItemKinds.FromText(LWord);
      end;
      Result[LIndex - 1] := LDirective;
    end;
  finally
    LLines.Free;
  end;
end;

class function TIdeProjectFormat.Serialize(const AGame: string;
  const AEntries: TArray<TIdeProjectEntry>): AnsiString;
var
  LLines: TStringList;
  LEntry: TIdeProjectEntry;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('version|' + IDE_PROJECT_VERSION);
    LLines.Add('game|' + AGame);
    for LEntry in AEntries do
      LLines.Add(TIdeItemKinds.ToText(LEntry.Kind) + '|' + LEntry.RelativePath);
    Result := AnsiString(LLines.Text);
  finally
    LLines.Free;
  end;
end;

end.
