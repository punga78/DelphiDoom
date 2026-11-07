{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - text that indents the blocks              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.IndentedText;

interface

type
  /// <summary>
  ///   The text of a definition: every line ends with CR LF, "{" opens a level (two blanks
  ///   more) and "}" closes it
  /// </summary>
  TExportIndentedText = class
  strict private
    FText: string;
    FLevel: Integer;
  public
    procedure AddLine(const ALine: string);
    property Text: string read FText;
  end;

implementation

{ TExportIndentedText }

procedure TExportIndentedText.AddLine(const ALine: string);
begin
  if ALine = '}' then
    Dec(FLevel);
  FText := FText + StringOfChar(' ', FLevel * 2) + ALine + #13#10;
  if ALine = '{' then
    Inc(FLevel);
end;

end.
