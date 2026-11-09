{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - the virtual files of the     }
{  mods on disk (what FileMap does for the data folder of OpenXcom)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.DiskModFiles;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Yaml.Intf,
  DelphiDoom.XcomMod.ModFiles.Intf;

type
  /// <summary>
  ///   A tree of files made of several folders: a path is looked up in the folders in order and the first
  ///   one that has it wins (the mods from the last to the first, then common)
  /// </summary>
  TXcomDiskModFiles = class(TInterfacedObject, IXcomModFiles)
  strict private
    FRoots: TArray<string>;
    FParser: IYamlParser;
  public
    /// <param name="ARoots">The folders in order of priority</param>
    constructor Create(const ARoots: TArray<string>; const AParser: IYamlParser);
    function FolderContents(const AVirtualFolder: string): TArray<string>;
    function LoadYaml(const AVirtualFile: string): IYamlNode;
    function LoadBytes(const AVirtualFile: string): TBytes;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.XcomMod.Types;

{ TXcomDiskModFiles }

constructor TXcomDiskModFiles.Create(const ARoots: TArray<string>; const AParser: IYamlParser);
begin
  inherited Create;
  FRoots := ARoots;
  FParser := AParser;
end;

function TXcomDiskModFiles.FolderContents(const AVirtualFolder: string): TArray<string>;
var
  LRoot, LFolder, LPath: string;
  LNames: TList<string>;
begin
  LNames := TList<string>.Create;
  try
    for LRoot in FRoots do
    begin
      LFolder := IncludeTrailingPathDelimiter(LRoot) + StringReplace(AVirtualFolder, '/', '\', [rfReplaceAll]);
      if not DirectoryExists(LFolder) then
        Continue;
      for LPath in TDirectory.GetFiles(LFolder) do
        if not LNames.Contains(ExtractFileName(LPath)) then
          LNames.Add(ExtractFileName(LPath));
    end;
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

function TXcomDiskModFiles.LoadYaml(const AVirtualFile: string): IYamlNode;
var
  LRoot, LPath: string;
begin
  for LRoot in FRoots do
  begin
    LPath := IncludeTrailingPathDelimiter(LRoot) + StringReplace(AVirtualFile, '/', '\', [rfReplaceAll]);
    if FileExists(LPath) then
      Exit(FParser.LoadFile(LPath));
  end;
  raise EXcomModException.CreateFmt('File %s not found', [AVirtualFile]);
end;

function TXcomDiskModFiles.LoadBytes(const AVirtualFile: string): TBytes;
var
  LRoot, LPath: string;
begin
  for LRoot in FRoots do
  begin
    LPath := IncludeTrailingPathDelimiter(LRoot) + StringReplace(AVirtualFile, '/', '\', [rfReplaceAll]);
    if FileExists(LPath) then
      Exit(TFile.ReadAllBytes(LPath));
  end;
  raise EXcomModException.CreateFmt('File %s not found', [AVirtualFile]);
end;

end.
