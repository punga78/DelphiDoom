{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the virtual files of the mods for the      }
{  ruleset (FileMap of OpenXcom seen through IXcomModFiles)                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FileMapModFiles;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomEngine.FileMap;

type
  /// <summary>
  ///   IXcomModFiles on a TXcomFileMap: folders and files of the virtual tree, YAML through a parser. The map is not
  ///   owned: it must live as long as this object
  /// </summary>
  TXcomFileMapModFiles = class(TInterfacedObject, IXcomModFiles)
  strict private
    FMap: TXcomFileMap;
    FParser: IYamlParser;
  public
    constructor Create(AMap: TXcomFileMap; const AParser: IYamlParser);
    function FolderContents(const AVirtualFolder: string): TArray<string>;
    function LoadYaml(const AVirtualFile: string): IYamlNode;
    function LoadBytes(const AVirtualFile: string): TBytes;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.IOUtils;

constructor TXcomFileMapModFiles.Create(AMap: TXcomFileMap; const AParser: IYamlParser);
begin
  inherited Create;
  FMap := AMap;
  FParser := AParser;
end;

function TXcomFileMapModFiles.FolderContents(const AVirtualFolder: string): TArray<string>;
var
  LNames: TList<string>;
  LFolder: string;
  LPath: string;
  LName: string;
begin
  LNames := TList<string>.Create;
  try
    for LFolder in FMap.Folders(AVirtualFolder) do
    begin
      for LPath in TDirectory.GetFileSystemEntries(LFolder) do
      begin
        LName := ExtractFileName(LPath);
        if not LNames.Contains(LName) then
          LNames.Add(LName);
      end;
    end;
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

function TXcomFileMapModFiles.LoadYaml(const AVirtualFile: string): IYamlNode;
begin
  Result := FParser.LoadFile(FMap.FilePath(AVirtualFile));
end;

function TXcomFileMapModFiles.LoadBytes(const AVirtualFile: string): TBytes;
begin
  Result := FMap.ReadAll(AVirtualFile);
end;

end.
