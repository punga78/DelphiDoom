{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the default file of arguments            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.DefaultFile;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The text of the file with the arguments to add at every start (Doom32.cmd). A line that
  ///   begins with "// " is a comment; so is what follows "// " in the middle of a line.
  ///   Arguments are separated by spaces and line breaks, and are made upper case
  /// </summary>
  TDefaultArgumentsFile = class
  public
    class function Parse(const AText: string): TArray<string>; static;
    /// <summary>
    ///   The text of a new file: two comment lines (with the name of the application) and the
    ///   name of the program, as the engine writes it when the file does not exist
    /// </summary>
    class function Template(const AApplicationName, AProgramName: string): string; static;
  end;

implementation

uses
  System.Generics.Collections;

const
  COMMENT_MARK = '// ';

{ TDefaultArgumentsFile }

class function TDefaultArgumentsFile.Parse(const AText: string): TArray<string>;
var
  LLines: TArray<string>;
  LLine, LText, LToken: string;
  LResult: TList<string>;
  LPosition, LIndex: Integer;
begin
  LResult := TList<string>.Create;
  try
    LLines := AText.Replace(#13#10, #10).Replace(#13, #10).Split([#10]);
    for LLine in LLines do
    begin
      LText := LLine;
      LPosition := Pos(COMMENT_MARK, LText);
      if LPosition = 1 then
        Continue;
      if LPosition > 1 then
        LText := Copy(LText, 1, LPosition - 1);
      LToken := '';
      for LIndex := 1 to Length(LText) + 1 do
        if (LIndex > Length(LText)) or (LText[LIndex] = ' ') then
        begin
          LToken := Trim(LToken);
          if LToken <> '' then
            LResult.Add(UpperCase(LToken));
          LToken := '';
        end
        else
          LToken := LToken + LText[LIndex];
    end;
    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

class function TDefaultArgumentsFile.Template(const AApplicationName, AProgramName: string): string;
begin
  Result := '// Add default command line parameters to this file.' + sLineBreak +
    '// These command line parameters will be appended everytime you run ' + AApplicationName + '.' +
    sLineBreak + LowerCase(AProgramName) + ' ' + sLineBreak;
end;

end.
