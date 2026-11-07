{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - a file system in memory              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeFileSystem;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   Files and folders kept in memory. Names are compared without regard to the case, relative
  ///   names rest on a current folder that the test can change, and a file can only be written in a
  ///   folder that exists (as on a disk)
  /// </summary>
  TFakeIdeFileSystem = class(TInterfacedObject, IIdeFileSystem)
  strict private
    FFiles: TDictionary<string, AnsiString>;
    FNames: TDictionary<string, string>;
    FFolders: TDictionary<string, string>;
    FCurrentFolder: string;
    FProgramFolder: string;
    FFailWritesTo: TStringList;
    function Normalize(const APath: string): string;
    function ParentExists(const AFullPath: string): Boolean;
  public
    constructor Create(const ACurrentFolder: string);
    destructor Destroy; override;
    /// <summary>Makes a folder (and its parents) exist</summary>
    procedure AddFolder(const APath: string);
    procedure AddFile(const APath: string; const AText: AnsiString);
    /// <summary>The text of a file; fails if it does not exist</summary>
    function Content(const APath: string): AnsiString;
    /// <summary>The full names of the files, in lower case and sorted</summary>
    function FileNames: TArray<string>;
    /// <summary>A write to this file (or a copy to it) fails, as a locked file does</summary>
    procedure FailWritesTo(const APath: string);
    property CurrentFolder: string read FCurrentFolder;
    { IIdeFileSystem }
    function FileExists(const APath: string): Boolean;
    function DirectoryExists(const APath: string): Boolean;
    function ExpandFileName(const APath: string): string;
    function TryCreateEmptyFile(const APath: string): Boolean;
    function TryReadAllText(const APath: string; out AText: AnsiString): Boolean;
    function TryWriteAllText(const APath: string; const AText: AnsiString): Boolean;
    function TryCopyFile(const ASource, ATarget: string): Boolean;
    function TrySetCurrentDirectory(const APath: string): Boolean;
    function TryCreateDirectory(const APath: string): Boolean;
    function TryLoadTextFile(const APath: string; out AText: string): Boolean;
    function TrySaveTextFile(const APath: string; const AText: string): Boolean;
    function ProgramFolder: string;
  end;

implementation

{ TFakeIdeFileSystem }

constructor TFakeIdeFileSystem.Create(const ACurrentFolder: string);
begin
  inherited Create;
  FFiles := TDictionary<string, AnsiString>.Create;
  FNames := TDictionary<string, string>.Create;
  FFolders := TDictionary<string, string>.Create;
  FFailWritesTo := TStringList.Create;
  FCurrentFolder := ExcludeTrailingPathDelimiter(ACurrentFolder);
  FProgramFolder := 'C:\program\';
  AddFolder(FCurrentFolder);
end;

destructor TFakeIdeFileSystem.Destroy;
begin
  FFailWritesTo.Free;
  FFolders.Free;
  FNames.Free;
  FFiles.Free;
  inherited Destroy;
end;

function TFakeIdeFileSystem.Normalize(const APath: string): string;
var
  LParts, LKept: TStringList;
  LIndex: Integer;
  LFull: string;
begin
  if APath = '' then
    Exit('');
  if (Length(APath) >= 2) and (APath[2] = ':') then
    LFull := APath
  else
    LFull := FCurrentFolder + '\' + APath;
  LParts := TStringList.Create;
  LKept := TStringList.Create;
  try
    LParts.Delimiter := '\';
    LParts.StrictDelimiter := True;
    LParts.DelimitedText := StringReplace(LFull, '/', '\', [rfReplaceAll]);
    for LIndex := 0 to LParts.Count - 1 do
      if (LParts[LIndex] = '') or (LParts[LIndex] = '.') then
        Continue
      else if LParts[LIndex] = '..' then
      begin
        if LKept.Count > 1 then
          LKept.Delete(LKept.Count - 1);
      end
      else
        LKept.Add(LParts[LIndex]);
    LKept.Delimiter := '\';
    LKept.StrictDelimiter := True;
    Result := LKept.DelimitedText;
  finally
    LKept.Free;
    LParts.Free;
  end;
end;

function TFakeIdeFileSystem.ParentExists(const AFullPath: string): Boolean;
begin
  Result := DirectoryExists(ExtractFileDir(AFullPath));
end;

procedure TFakeIdeFileSystem.AddFolder(const APath: string);
var
  LFull, LParent: string;
begin
  LFull := Normalize(APath);
  FFolders.AddOrSetValue(LowerCase(LFull), LFull);
  LParent := ExtractFileDir(LFull);
  if (LParent <> '') and (LParent <> LFull) and (Length(LParent) > 2) then
    AddFolder(LParent);
end;

procedure TFakeIdeFileSystem.AddFile(const APath: string; const AText: AnsiString);
var
  LFull: string;
begin
  LFull := Normalize(APath);
  AddFolder(ExtractFileDir(LFull));
  FFiles.AddOrSetValue(LowerCase(LFull), AText);
  FNames.AddOrSetValue(LowerCase(LFull), LFull);
end;

function TFakeIdeFileSystem.Content(const APath: string): AnsiString;
begin
  if not FFiles.TryGetValue(LowerCase(Normalize(APath)), Result) then
    raise Exception.CreateFmt('Fake file "%s" does not exist', [APath]);
end;

function TFakeIdeFileSystem.FileNames: TArray<string>;
var
  LList: TStringList;
  LKey: string;
begin
  LList := TStringList.Create;
  try
    for LKey in FFiles.Keys do
      LList.Add(LKey);
    LList.Sort;
    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

procedure TFakeIdeFileSystem.FailWritesTo(const APath: string);
begin
  FFailWritesTo.Add(LowerCase(Normalize(APath)));
end;

function TFakeIdeFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := (APath <> '') and FFiles.ContainsKey(LowerCase(Normalize(APath)));
end;

function TFakeIdeFileSystem.DirectoryExists(const APath: string): Boolean;
begin
  Result := (APath <> '') and FFolders.ContainsKey(LowerCase(Normalize(APath)));
end;

function TFakeIdeFileSystem.ExpandFileName(const APath: string): string;
begin
  Result := Normalize(APath);
end;

function TFakeIdeFileSystem.TryCreateEmptyFile(const APath: string): Boolean;
begin
  Result := TryWriteAllText(APath, '');
end;

function TFakeIdeFileSystem.TryReadAllText(const APath: string; out AText: AnsiString): Boolean;
begin
  Result := (APath <> '') and FFiles.TryGetValue(LowerCase(Normalize(APath)), AText);
  if not Result then
    AText := '';
end;

function TFakeIdeFileSystem.TryWriteAllText(const APath: string; const AText: AnsiString): Boolean;
var
  LFull: string;
begin
  LFull := Normalize(APath);
  Result := (LFull <> '') and ParentExists(LFull) and (FFailWritesTo.IndexOf(LowerCase(LFull)) < 0);
  if Result then
    AddFile(LFull, AText);
end;

function TFakeIdeFileSystem.TryCopyFile(const ASource, ATarget: string): Boolean;
var
  LText: AnsiString;
begin
  if not TryReadAllText(ASource, LText) then
    LText := '';
  Result := TryWriteAllText(ATarget, LText);
end;

function TFakeIdeFileSystem.TrySetCurrentDirectory(const APath: string): Boolean;
begin
  Result := DirectoryExists(APath);
  if Result then
    FCurrentFolder := Normalize(APath);
end;

function TFakeIdeFileSystem.TryCreateDirectory(const APath: string): Boolean;
begin
  Result := (APath <> '') and ParentExists(Normalize(APath));
  if Result then
    AddFolder(APath);
end;

function TFakeIdeFileSystem.TryLoadTextFile(const APath: string; out AText: string): Boolean;
var
  LBytes: AnsiString;
  LLines: TStringList;
begin
  Result := TryReadAllText(APath, LBytes);
  AText := '';
  if Result then
  begin
    LLines := TStringList.Create;
    try
      LLines.Text := string(LBytes);
      AText := LLines.Text;
    finally
      LLines.Free;
    end;
  end;
end;

function TFakeIdeFileSystem.TrySaveTextFile(const APath: string; const AText: string): Boolean;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    Result := TryWriteAllText(APath, AnsiString(LLines.Text));
  finally
    LLines.Free;
  end;
end;

function TFakeIdeFileSystem.ProgramFolder: string;
begin
  Result := FProgramFolder;
end;

end.
