{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - names and paths of the PAK file system            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Pak.Names;

interface

// The hashes wrap around on purpose (the old MkHash of w_pak)
{$Q-}
{$R-}

uses
  DelphiDoom.Wad.Pak.Types;

type
  /// <summary>
  ///   The functions of d_delphi that the PAK file system used on its names (strupper,
  ///   fshortname, fixpathname, strtrim, the lines of TDStrings.Text) and the hash of a name
  /// </summary>
  TPakNames = class
  public
    /// <summary>
    ///   The old MkHash: rotate left by 7 and add the character in upper case. The upper case
    ///   is the one of toupper of d_delphi, that looked at the low byte only: a character whose
    ///   low byte is a..z loses 32 even if it is above $FF (defect kept: the hash is in the
    ///   names of the cache files)
    /// </summary>
    class function Hash(const AName: string): Integer; static;
    /// <summary>The chain of a hash: Abs(AHash) mod PAK_HASH_SIZE (Low(Integer) gives 0)</summary>
    class function HashTableIndex(AHash: Integer): Integer; static;
    /// <summary>a..z become A..Z, nothing else changes</summary>
    class function UpperCase(const AName: string): string; static;
    /// <summary>What follows the last '\' or '/'</summary>
    class function ShortName(const APath: string): string; static;
    /// <summary>'/' becomes '\' and a run of '\' becomes one</summary>
    class function FixPath(const APath: string): string; static;
    /// <summary>Without the characters up to ' ' at the two ends</summary>
    class function Trim(const AText: string): string; static;
    /// <summary>
    ///   The lines of a text as TDStrings.Text reads them: CR, LF or CR LF end a line, a #0
    ///   ends the text, a last line without end is a line
    /// </summary>
    class function SplitLines(const AText: string): TArray<string>; static;
    /// <summary>
    ///   PAK_GetDirectoryListFromString: the folders of a list separated by spaces or commas,
    ///   upper case (with the toupper of Hash), each one ending with '\'
    /// </summary>
    class function DirectoryList(const ADirectories: string): TArray<string>; static;
  end;

implementation

uses
  DelphiDoom.Wad.Name;

function LowByteUpperCase(AChar: Char): Char;
begin
  if ((Ord(AChar) and $FF) >= Ord('a')) and ((Ord(AChar) and $FF) <= Ord('z')) then
    Result := Char(Ord(AChar) - 32)
  else
    Result := AChar;
end;

{ TPakNames }

class function TPakNames.Hash(const AName: string): Integer;
var
  LHash: Cardinal;
  LIndex: Integer;
begin
  LHash := 0;
  for LIndex := 1 to Length(AName) do
    LHash := ((LHash shl 7) or (LHash shr 25)) + Cardinal(Ord(LowByteUpperCase(AName[LIndex])));
  Result := Integer(LHash);
end;

class function TPakNames.HashTableIndex(AHash: Integer): Integer;
begin
  Result := Abs(AHash) mod PAK_HASH_SIZE;
end;

class function TPakNames.UpperCase(const AName: string): string;
begin
  Result := TWadLumpName.UpperCase(AName);
end;

class function TPakNames.ShortName(const APath: string): string;
var
  LIndex: Integer;
begin
  LIndex := Length(APath);
  while (LIndex > 0) and (APath[LIndex] <> '\') and (APath[LIndex] <> '/') do
    Dec(LIndex);
  Result := Copy(APath, LIndex + 1, MaxInt);
end;

class function TPakNames.FixPath(const APath: string): string;
var
  LBuilder: TArray<Char>;
  LCount: Integer;
  LIndex: Integer;
  LChar: Char;
  LLast: Char;
begin
  SetLength(LBuilder, Length(APath));
  LCount := 0;
  LLast := #0;
  for LIndex := 1 to Length(APath) do
  begin
    LChar := APath[LIndex];
    if LChar = '/' then
      LChar := '\';
    if (LLast <> '\') or (LChar <> '\') then
    begin
      LBuilder[LCount] := LChar;
      Inc(LCount);
    end;
    LLast := LChar;
  end;
  SetString(Result, PChar(LBuilder), LCount);
end;

class function TPakNames.Trim(const AText: string): string;
var
  LFirst: Integer;
  LLast: Integer;
begin
  LFirst := 1;
  LLast := Length(AText);
  while (LFirst <= LLast) and (AText[LFirst] <= ' ') do
    Inc(LFirst);
  while (LLast >= LFirst) and (AText[LLast] <= ' ') do
    Dec(LLast);
  Result := Copy(AText, LFirst, LLast - LFirst + 1);
end;

class function TPakNames.SplitLines(const AText: string): TArray<string>;
var
  LIndex: Integer;
  LStart: Integer;
  LLength: Integer;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  LLength := Length(AText);
  LIndex := 1;
  while (LIndex <= LLength) and (AText[LIndex] <> #0) do
  begin
    LStart := LIndex;
    while (LIndex <= LLength) and (AText[LIndex] <> #0) and (AText[LIndex] <> #10) and
      (AText[LIndex] <> #13) do
      Inc(LIndex);
    if LCount = Length(Result) then
      SetLength(Result, LCount * 2 + 4);
    Result[LCount] := Copy(AText, LStart, LIndex - LStart);
    Inc(LCount);
    if (LIndex <= LLength) and (AText[LIndex] = #13) then
      Inc(LIndex);
    if (LIndex <= LLength) and (AText[LIndex] = #10) then
      Inc(LIndex);
  end;
  SetLength(Result, LCount);
end;

class function TPakNames.DirectoryList(const ADirectories: string): TArray<string>;
var
  LText: string;
  LIndex: Integer;
  LLines: TArray<string>;
  LLine: string;
  LCount: Integer;
begin
  Result := nil;
  if ADirectories = '' then
    Exit;
  // a separator is a whole CR LF, as in the old code: a CR of the text before it is a line more
  LText := '';
  for LIndex := 1 to Length(ADirectories) do
    if (ADirectories[LIndex] = ' ') or (ADirectories[LIndex] = ',') then
      LText := LText + #13#10
    else
      LText := LText + LowByteUpperCase(ADirectories[LIndex]);
  LLines := SplitLines(LText);
  SetLength(Result, Length(LLines));
  LCount := 0;
  for LIndex := 0 to High(LLines) do
  begin
    LLine := Trim(LLines[LIndex]);
    if LLine = '' then
      Continue;
    if LLine[Length(LLine)] <> '\' then
      LLine := LLine + '\';
    Result[LCount] := LLine;
    Inc(LCount);
  end;
  SetLength(Result, LCount);
end;

end.
