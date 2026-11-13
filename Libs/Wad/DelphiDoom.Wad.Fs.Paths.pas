{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: rules on names          }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): HashFileName,      }
{  FilenameCompare, BuildOSPath, GetExtensionList and the checks of            }
{  OpenFileReadFlags (framework\FileSystem.cpp). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Paths;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The rules of the file system of id Tech 4 on names of files, as pure functions: how a name is
  ///   hashed and compared, what a relative path may be, how an OS path is built. Case means ASCII case
  ///   only (idStr::ToLower and Icmp), like the original; names are Unicode strings.
  /// </summary>
  TGameFsPaths = class
  public
    /// <summary>The character in lower case if it is A to Z, as idStr::ToLower</summary>
    class function LowerAscii(AChar: Char): Char; static; inline;
    /// <summary>The text with the letters A to Z in lower case</summary>
    class function ToLowerAscii(const AText: string): string; static;
    /// <summary>Icmp: the two texts are the same apart from the case of the letters A to Z</summary>
    class function SameIgnoringCase(const ALeft, ARight: string): Boolean; static;
    /// <summary>
    ///   HashFileName: the bucket (0 to 1023) of a name, without case, with '\' as '/', ignoring from the
    ///   first '.' on. Two names the file system finds equal can still land in different buckets when
    ///   one of them has ':' where the other has a separator, and then they are not found as equal
    ///   (kept: it is how the original behaves)
    /// </summary>
    class function HashFileName(const AName: string): Integer; static;
    /// <summary>
    ///   FilenameCompare, with the sense reversed (True when equal): the case does not count, '\' and ':'
    ///   count as '/'
    /// </summary>
    class function NamesEqual(const ALeft, ARight: string): Boolean; static;
    /// <summary>
    ///   The checks that OpenFileReadFlags makes on a path: a leading slash is dropped, and a path with
    ///   '..' or '::' is refused (False). An empty path is accepted here; the callers decide
    /// </summary>
    class function CleanRelativePath(const APath: string; out AClean: string): Boolean; static;
    /// <summary>
    ///   BuildOSPath: base, game and relative path joined with the separator of the platform, without
    ///   the trailing separators of the base. (The fs_caseSensitiveOS fix-up of upper case folders is not
    ///   ported: it is only for case sensitive systems.)
    /// </summary>
    class function BuildOSPath(const ABase, AGame, ARelativePath: string): string; static;
    /// <summary>GetExtensionList: 'tga|dds' to ['tga', 'dds']; the text with no bar is one extension, an empty text one empty extension</summary>
    class function SplitExtensions(const AExtension: string): TArray<string>; static;
    /// <summary>StripTrailing('/'): every slash at the end</summary>
    class function StripTrailingSlashes(const AText: string): string; static;
    /// <summary>
    ///   idStrListSortPaths: sorts in place, folders first, then alphabetically without case (idStr::IcmpPath,
    ///   from Libs\IdLib). Names that IcmpPath finds equal (the original's qsort leaves them in any order)
    ///   are put in the order of CompareStr, so the result is always the same
    /// </summary>
    class procedure SortPaths(var AList: TArray<string>); static;
  end;

implementation

uses
  System.Generics.Defaults, System.Generics.Collections, DelphiDoom.IdLib.Text.Strings;

{ TGameFsPaths }

class function TGameFsPaths.LowerAscii(AChar: Char): Char;
begin
  if (AChar >= 'A') and (AChar <= 'Z') then
    Result := Char(Ord(AChar) + (Ord('a') - Ord('A')))
  else
    Result := AChar;
end;

class function TGameFsPaths.ToLowerAscii(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  UniqueString(Result);
  for LIndex := 1 to Length(Result) do
    Result[LIndex] := LowerAscii(Result[LIndex]);
end;

class function TGameFsPaths.SameIgnoringCase(const ALeft, ARight: string): Boolean;
var
  LIndex: Integer;
begin
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  for LIndex := 1 to Length(ALeft) do
    if LowerAscii(ALeft[LIndex]) <> LowerAscii(ARight[LIndex]) then
      Exit(False);
  Result := True;
end;

class function TGameFsPaths.HashFileName(const AName: string): Integer;
var
  LIndex: Integer;
  LLetter: Char;
begin
  Result := 0;
  for LIndex := 1 to Length(AName) do
  begin
    LLetter := LowerAscii(AName[LIndex]);
    if LLetter = '.' then
      Break;
    if LLetter = '\' then
      LLetter := '/';
    Result := Result + Ord(LLetter) * (LIndex - 1 + 119);
  end;
  Result := Result and 1023;
end;

class function TGameFsPaths.NamesEqual(const ALeft, ARight: string): Boolean;
var
  LIndex: Integer;
  LLeft, LRight: Char;
begin
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  for LIndex := 1 to Length(ALeft) do
  begin
    LLeft := LowerAscii(ALeft[LIndex]);
    LRight := LowerAscii(ARight[LIndex]);
    if (LLeft = '\') or (LLeft = ':') then
      LLeft := '/';
    if (LRight = '\') or (LRight = ':') then
      LRight := '/';
    if LLeft <> LRight then
      Exit(False);
  end;
  Result := True;
end;

class function TGameFsPaths.CleanRelativePath(const APath: string; out AClean: string): Boolean;
begin
  AClean := APath;
  if (AClean <> '') and ((AClean[1] = '/') or (AClean[1] = '\')) then
    Delete(AClean, 1, 1);
  Result := (Pos('..', AClean) = 0) and (Pos('::', AClean) = 0);
end;

class function TGameFsPaths.BuildOSPath(const ABase, AGame, ARelativePath: string): string;
var
  LBase: string;
begin
  LBase := ABase;
  while (LBase <> '') and ((LBase[Length(LBase)] = '/') or (LBase[Length(LBase)] = '\')) do
    SetLength(LBase, Length(LBase) - 1);
  Result := LBase + '/' + AGame + '/' + ARelativePath;
  Result := StringReplace(Result, '/', PathDelim, [rfReplaceAll]);
  Result := StringReplace(Result, '\', PathDelim, [rfReplaceAll]);
end;

class function TGameFsPaths.SplitExtensions(const AExtension: string): TArray<string>;
var
  LStart, LBar: Integer;
begin
  Result := nil;
  LStart := 1;
  while True do
  begin
    LBar := Pos('|', AExtension, LStart);
    if LBar > 0 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Copy(AExtension, LStart, LBar - LStart);
      LStart := LBar + 1;
    end
    else
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Copy(AExtension, LStart, MaxInt);
      Break;
    end;
  end;
end;

class function TGameFsPaths.StripTrailingSlashes(const AText: string): string;
var
  LLength: Integer;
begin
  LLength := Length(AText);
  while (LLength > 0) and (AText[LLength] = '/') do
    Dec(LLength);
  Result := Copy(AText, 1, LLength);
end;

class procedure TGameFsPaths.SortPaths(var AList: TArray<string>);
var
  LKeys: TArray<TPair<AnsiString, string>>;
  LIndex: Integer;
  LRaw: RawByteString;
begin
  SetLength(LKeys, Length(AList));
  for LIndex := 0 to High(AList) do
  begin
    // the bytes of the UTF-8 form, as the comparison of the original sees the bytes of the name
    LRaw := UTF8Encode(AList[LIndex]);
    SetCodePage(LRaw, 0, False);
    LKeys[LIndex] := TPair<AnsiString, string>.Create(AnsiString(LRaw), AList[LIndex]);
  end;
  TArray.Sort<TPair<AnsiString, string>>(LKeys, TComparer<TPair<AnsiString, string>>.Construct(
    function(const ALeft, ARight: TPair<AnsiString, string>): Integer
    begin
      Result := TIdStrings.IcmpPath(ALeft.Key, ARight.Key);
      if Result = 0 then
        Result := CompareStr(ALeft.Value, ARight.Value);
    end));
  for LIndex := 0 to High(AList) do
    AList[LIndex] := LKeys[LIndex].Value;
end;

end.
