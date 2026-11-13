{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the names of an entry of a token list         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.TokenEntry;

interface

type
  /// <summary>
  ///   An entry of a token list (the names of the states, the flags, the ammo...) is one name
  ///   or several names separated by commas ("S_PLAY, S_PLAYER"); the position of the entry is
  ///   the value of all its names. The old TTokenList did the splitting inside the list
  /// </summary>
  TScannerTokenEntry = class sealed
  strict private
    class function SplitAtCommas(const AEntry: string): TArray<string>; static;
  public
    /// <summary>
    ///   The names of the entry, trimmed. An entry without a comma is one name (the entry
    ///   itself, trimmed, even if it is empty); with commas the entry is cut at every comma,
    ///   trimmed as a whole, then split at the line breaks and every name is trimmed
    /// </summary>
    class function Split(const AEntry: string): TArray<string>; static;
    /// <summary>
    ///   True if the entry lists several names (it has a comma) and one of them is AToken,
    ///   ignoring the case. An entry that is a single name is not looked at: the list finds
    ///   it with its plain search first. The first name is not trimmed at its end (old
    ///   defect kept: "S_A , S_B" does not list "S_A")
    /// </summary>
    class function ListsToken(const AEntry, AToken: string): Boolean; static;
    /// <summary>
    ///   The position of the entry that is, or lists, AToken: first the plain search (whole
    ///   entry, ignoring the case), then the entries with commas; -1 if none
    /// </summary>
    class function IndexOfToken(const AEntries: array of string; const AToken: string): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TScannerTokenEntry }

class function TScannerTokenEntry.SplitAtCommas(const AEntry: string): TArray<string>;
var
  LJoined: string;
begin
  LJoined := AEntry.Replace(',', #13#10, [rfReplaceAll]);
  LJoined := TScannerStrings.Trim(LJoined);
  if LJoined = '' then
    Result := nil
  else
    Result := TScannerStrings.SplitLines(LJoined);
end;

class function TScannerTokenEntry.Split(const AEntry: string): TArray<string>;
var
  LIndex: Integer;
begin
  if Pos(',', AEntry) = 0 then
  begin
    SetLength(Result, 1);
    Result[0] := TScannerStrings.Trim(AEntry);
    Exit;
  end;
  Result := SplitAtCommas(AEntry);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := TScannerStrings.Trim(Result[LIndex]);
end;

class function TScannerTokenEntry.ListsToken(const AEntry, AToken: string): Boolean;
var
  LNames: TArray<string>;
  LIndex: Integer;
  LName: string;
begin
  Result := False;
  if Pos(',', AEntry) = 0 then
    Exit;
  LNames := SplitAtCommas(AEntry);
  for LIndex := 0 to High(LNames) do
  begin
    LName := LNames[LIndex];
    // Conserved defect: the old code trimmed the names with TDStringList.Strings[j] :=, whose
    // Put ignores index 0 (Index > 0), so the first name keeps its trailing blanks
    if LIndex > 0 then
      LName := TScannerStrings.Trim(LName);
    if AnsiCompareText(LName, AToken) = 0 then
      Exit(True);
  end;
end;

class function TScannerTokenEntry.IndexOfToken(const AEntries: array of string;
  const AToken: string): Integer;
begin
  for Result := 0 to High(AEntries) do
    if AnsiCompareText(AEntries[Result], AToken) = 0 then
      Exit;
  for Result := 0 to High(AEntries) do
    if ListsToken(AEntries[Result], AToken) then
      Exit;
  Result := -1;
end;

end.
