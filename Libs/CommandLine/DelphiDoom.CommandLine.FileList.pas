{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - lists of files                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.FileList;

interface

type
  /// <summary>
  ///   The lists of files of the configuration (wads_autoload, paks_autoload) as the old
  ///   D_WadsAutoLoad and D_PaksAutoload read them
  /// </summary>
  TCommandLineFileList = class
  public
    /// <summary>
    ///   Splits a list into its names: at each step the text is trimmed (characters up to ' ')
    ///   and cut at its first ';', or at its first ',' when it has no ';'; the rest is the
    ///   list of the next step. A name can be empty (",a" gives "" and "a") and is kept: the
    ///   caller decides what an empty name means
    /// </summary>
    class function Split(const AList: string): TArray<string>; static;
  end;

implementation

function TrimControl(const AText: string): string;
var
  LStart: Integer;
  LEnd: Integer;
begin
  LStart := 1;
  LEnd := Length(AText);
  while (LStart <= LEnd) and (AText[LStart] <= ' ') do
    Inc(LStart);
  while (LEnd >= LStart) and (AText[LEnd] <= ' ') do
    Dec(LEnd);
  Result := Copy(AText, LStart, LEnd - LStart + 1);
end;

{ TCommandLineFileList }

class function TCommandLineFileList.Split(const AList: string): TArray<string>;
var
  LRest: string;
  LSeparator: Char;
  LPosition: Integer;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  LRest := TrimControl(AList);
  while LRest <> '' do
  begin
    if Pos(';', LRest) > 0 then
      LSeparator := ';'
    else
      LSeparator := ',';
    LPosition := Pos(LSeparator, LRest);
    SetLength(Result, LCount + 1);
    if LPosition = 0 then
    begin
      Result[LCount] := LRest;
      LRest := '';
    end
    else
    begin
      Result[LCount] := TrimControl(Copy(LRest, 1, LPosition - 1));
      LRest := TrimControl(Copy(LRest, LPosition + 1, Length(LRest) - LPosition));
    end;
    Inc(LCount);
  end;
end;

end.
