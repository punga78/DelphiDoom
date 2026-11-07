{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the dump of a project                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.ProjectDump;

interface

uses
  System.SysUtils,
  System.Classes;

type
  /// <summary>
  ///   Does with the new project classes what the old golden generator did with TIDEProject, and
  ///   writes the same lines (see Tests\Data\Ide\Projects\*.golden.txt)
  /// </summary>
  TProjectDump = class
  public
    /// <summary>
    ///   Loads the project file, asks the project what it holds, saves it under another name
    ///   and tells what happened. The folder of the files is C:\prj
    /// </summary>
    class function Run(const AProjectFileText: AnsiString; const AProjectName: string): TStringList; static;
    /// <summary>Adds, deletes and renames items of a new project</summary>
    class function RunOperations: TStringList; static;
  end;

implementation

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.ItemKinds,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeClock;

const
  PROJECT_FOLDER = 'C:\prj\';

function Escape(const AText: AnsiString): string;
begin
  Result := StringReplace(StringReplace(string(AText), #13, '\r', [rfReplaceAll]), #10, '\n', [rfReplaceAll]);
end;

function YesNo(const AValue: Boolean): string;
begin
  if AValue then
    Result := 'True'
  else
    Result := 'False';
end;

procedure AddLog(const ADump: TStringList; const ALog: TFakeIdeLog);
var
  LLine: string;
begin
  // the folder of the project and its parent are markers, as in the golden files
  for LLine in ALog.LinesWithout(PROJECT_FOLDER, '<dir>\') do
    ADump.Add(StringReplace(LLine, 'C:\', '<parent>\', [rfReplaceAll]));
end;

class function TProjectDump.Run(const AProjectFileText: AnsiString;
  const AProjectName: string): TStringList;
var
  LFileSystem: TFakeIdeFileSystem;
  LLog: TFakeIdeLog;
  LClock: IIdeClock;
  LFileSystemIntf: IIdeFileSystem;
  LLogIntf: IIdeLog;
  LProject: TIdeProject;
  LIndex: Integer;
  LItem: TIdeProjectItem;
  LName, LFileName, LRelative: string;
begin
  Result := TStringList.Create;
  LFileSystem := TFakeIdeFileSystem.Create(PROJECT_FOLDER);
  LFileSystemIntf := LFileSystem;
  LLog := TFakeIdeLog.Create;
  LLogIntf := LLog;
  LClock := TFakeIdeClock.Create;
  LFileSystem.AddFile(PROJECT_FOLDER + AProjectName, AProjectFileText);
  LProject := TIdeProject.Create(LFileSystemIntf, LLogIntf, LClock, PROJECT_FOLDER + AProjectName);
  try
    Result.Add('game=' + LProject.Game);
    Result.Add('count=' + IntToStr(LProject.Count));
    for LIndex := 0 to LProject.Count - 1 do
    begin
      LItem := LProject.Items[LIndex];
      Result.Add('item=' + TIdeItemKinds.ToText(LItem.Kind) + '|' + LItem.RelativePath);
    end;
    Result.Add('data=' + Escape(LProject.Data));
    Result.Add('modified=' + YesNo(LProject.Modified));
    Result.Add('find a.ddscript=' + YesNo(LProject.Find('a.ddscript') <> nil));
    Result.Add('find main.ddscript=' + YesNo(LProject.Find('main.ddscript') <> nil));
    Result.Add('find A.DDSCRIPT=' + YesNo(LProject.Find('A.DDSCRIPT') <> nil));
    Result.Add('find missing=' + YesNo(LProject.Find('missing.ddscript') <> nil));
    Result.Add('find empty=' + YesNo(LProject.Find('') <> nil));
    Result.Add('-- log');
    AddLog(Result, LLog);

    LLog.Clear;
    Result.Add('save=' + YesNo(LProject.SaveToFile(PROJECT_FOLDER + 'saved.ddide')));
    Result.Add('modified after save=' + YesNo(LProject.Modified));
    Result.Add('saved content=' + Escape(LFileSystem.Content(PROJECT_FOLDER + 'saved.ddide')));
    for LFileName in LFileSystem.FileNames do
    begin
      LRelative := Copy(LFileName, Length(PROJECT_FOLDER) + 1, MaxInt);
      LName := StringReplace(LRelative, '_' + TFakeIdeClock.BACKUP_DATE, '_<date>', [rfReplaceAll]);
      Result.Add('file=' + LName);
    end;
    Result.Add('-- save log');
    AddLog(Result, LLog);
  finally
    LProject.Free;
  end;
end;

class function TProjectDump.RunOperations: TStringList;
var
  LFileSystem: TFakeIdeFileSystem;
  LLog: TFakeIdeLog;
  LClock: IIdeClock;
  LFileSystemIntf: IIdeFileSystem;
  LLogIntf: IIdeLog;
  LProject: TIdeProject;
  LDirectory: string;
  LIndex: Integer;
  LItem: TIdeProjectItem;
begin
  Result := TStringList.Create;
  LFileSystem := TFakeIdeFileSystem.Create(PROJECT_FOLDER);
  LFileSystemIntf := LFileSystem;
  LLog := TFakeIdeLog.Create;
  LLogIntf := LLog;
  LClock := TFakeIdeClock.Create;
  LDirectory := PROJECT_FOLDER + 'ops';
  LFileSystem.AddFolder(LDirectory);
  LProject := TIdeProject.Create(LFileSystemIntf, LLogIntf, LClock, LDirectory + '\ops.ddide');
  try
    LProject.Add(LDirectory + '\one.ddscript', ikScript);
    LProject.Add(LDirectory + '\one.ddscript', ikScript);
    LProject.Add(LDirectory + '\two.txt', ikActor);
    LProject.Add(LDirectory + '\three.ddout', ikCompiledScript);
    Result.Add('count after add=' + IntToStr(LProject.Count));
    Result.Add('data=' + Escape(LProject.Data));
    LProject.Delete('two.txt');
    Result.Add('count after delete=' + IntToStr(LProject.Count));
    LProject.Delete(99);
    LProject.Delete(-1);
    LProject.Delete('nothing');
    Result.Add('count after bad deletes=' + IntToStr(LProject.Count));
    LProject.Game := 'Heretic ';
    Result.Add('game=' + LProject.Game);
    LProject.Game := 'nothing';
    Result.Add('game after unknown=' + LProject.Game);
    Result.Add('can rename missing=' + YesNo(LProject.CanRename('zzz')));
    Result.Add('exec rename empty=' + YesNo(LProject.ExecRename('')));
    Result.Add('rename new=' + YesNo(LProject.Rename('one.ddscript', 'renamed.ddscript')));
    Result.Add('rename onto existing item=' + YesNo(LProject.Rename('renamed.ddscript', 'three.ddout')));
    for LIndex := 0 to LProject.Count - 1 do
    begin
      LItem := LProject.Items[LIndex];
      Result.Add('item=' + TIdeItemKinds.ToText(LItem.Kind) + '|' + LItem.RelativePath);
    end;
    Result.Add('-- log');
    for LIndex := 0 to LLog.Lines.Count - 1 do
      Result.Add(StringReplace(LLog.Lines[LIndex], LDirectory + '\', '<dir>\', [rfReplaceAll, rfIgnoreCase]));
  finally
    LProject.Free;
  end;
end;

end.
