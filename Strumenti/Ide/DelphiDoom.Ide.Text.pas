{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - splitting of the lines of the ide                 }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Text;

interface

type
  /// <summary>
  ///   The "name|value" and "name=value" lines the ide reads (project files, the lists of the
  ///   compiler library)
  /// </summary>
  TIdeText = class
  public
    /// <summary>
    ///   Cuts a line at the first separator. Both halves are trimmed. Without the separator the
    ///   first half is the whole line, as it is (not trimmed), and the second one is empty.
    ///   Only one character after the separator is skipped, whatever its length
    /// </summary>
    class procedure SplitPair(const AInput, ASeparator: string; out AFirst, ASecond: string); static;
    /// <summary>The first half of SplitPair</summary>
    class function FirstWord(const AInput, ASeparator: string): string; static;
    /// <summary>The second half of SplitPair</summary>
    class function SecondWord(const AInput, ASeparator: string): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TIdeText }

class procedure TIdeText.SplitPair(const AInput, ASeparator: string; out AFirst, ASecond: string);
var
  LPosition: Integer;
begin
  LPosition := Pos(ASeparator, AInput);
  if LPosition = 0 then
  begin
    AFirst := AInput;
    ASecond := '';
  end
  else
  begin
    AFirst := Trim(Copy(AInput, 1, LPosition - 1));
    ASecond := Trim(Copy(AInput, LPosition + 1, Length(AInput) - LPosition));
  end;
end;

class function TIdeText.FirstWord(const AInput, ASeparator: string): string;
var
  LSecond: string;
begin
  SplitPair(AInput, ASeparator, Result, LSecond);
end;

class function TIdeText.SecondWord(const AInput, ASeparator: string): string;
var
  LFirst: string;
begin
  SplitPair(AInput, ASeparator, LFirst, Result);
end;

end.
