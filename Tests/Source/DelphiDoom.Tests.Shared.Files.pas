{******************************************************************************}
{                                                                              }
{  DelphiDoom: common code of the test suites - where the files of the tests    }
{  are                                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Shared.Files;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   The files a test reads are looked for from the folder of the test program upwards (bin\Tests, the root of
  ///   the repository, and above a worktree the repository it belongs to): Tests\Data of the repository, and the
  ///   data of the real games in Reference\_dati, which are not in the repository
  /// </summary>
  TTestFiles = class
  public
    /// <summary>
    ///   The path of ARelative under the folder of the program or under the nearest folder above that has it;
    ///   empty when no folder up to the root of the disk has it. AFolder: a folder is looked for, not a file
    /// </summary>
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function FindFileUp(const ARelative: string): string; static;
    class function FindFolderUp(const ARelative: string): string; static;
    /// <summary>The file AName of Tests\Data\AArea; raises when it is not there (the data of a test are in the repository)</summary>
    class function DataFile(const AArea, AName: string): string; static;
    /// <summary>The lines of a text file, that the caller frees; AEncoding nil reads it as the system does</summary>
    class function Lines(const AFileName: string; AEncoding: TEncoding = nil): TStringList; static;
  end;

implementation

const
  SDataFileMissing = 'Data file %s not found';
  DATA_FOLDER = 'Tests\Data\';

class function TTestFiles.FindUp(const ARelative: string; AFolder: Boolean): string;
var
  LFolder: string;
  LParent: string;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    Result := LFolder + ARelative;
    if (AFolder and DirectoryExists(Result)) or ((not AFolder) and FileExists(Result)) then
      Exit;
    LParent := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
    if LParent = LFolder then
      Break;
    LFolder := LParent;
  end;
  Result := '';
end;

class function TTestFiles.FindFileUp(const ARelative: string): string;
begin
  Result := FindUp(ARelative, False);
end;

class function TTestFiles.FindFolderUp(const ARelative: string): string;
begin
  Result := FindUp(ARelative, True);
end;

class function TTestFiles.DataFile(const AArea, AName: string): string;
begin
  Result := FindUp(DATA_FOLDER + AArea + PathDelim + AName, False);
  if Result = '' then
    raise Exception.CreateFmt(SDataFileMissing, [AName]);
end;

class function TTestFiles.Lines(const AFileName: string; AEncoding: TEncoding): TStringList;
begin
  Result := TStringList.Create;
  try
    if Assigned(AEncoding) then
      Result.LoadFromFile(AFileName, AEncoding)
    else
      Result.LoadFromFile(AFileName);
  except
    Result.Free;
    raise;
  end;
end;

end.
