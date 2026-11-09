{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the files of the disk                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.DiskFileSystem;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>IXcomFileSystem on the disk (the file functions of CrossPlatform)</summary>
  TXcomDiskFileSystem = class(TInterfacedObject, IXcomFileSystem)
  public
    function FileExists(const APath: string): Boolean;
    function FolderExists(const APath: string): Boolean;
    function ReadAll(const APath: string): TBytes;
    procedure WriteAll(const APath: string; const ABytes: TBytes);
    function FolderContents(const AFolder, AExtension: string): TArray<string>;
  end;

implementation

function TXcomDiskFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := TFile.Exists(APath);
end;

function TXcomDiskFileSystem.FolderExists(const APath: string): Boolean;
begin
  Result := TDirectory.Exists(APath);
end;

function TXcomDiskFileSystem.ReadAll(const APath: string): TBytes;
begin
  if not TFile.Exists(APath) then
    raise EXcomEngineException.Create('File not found: ' + APath);
  Result := TFile.ReadAllBytes(APath);
end;

procedure TXcomDiskFileSystem.WriteAll(const APath: string; const ABytes: TBytes);
begin
  TDirectory.CreateDirectory(ExtractFilePath(ExpandFileName(APath)));
  TFile.WriteAllBytes(APath, ABytes);
end;

function TXcomDiskFileSystem.FolderContents(const AFolder, AExtension: string): TArray<string>;
var
  LList: TList<string>;
  LFile: string;
  LExtension: string;
begin
  LList := TList<string>.Create;
  try
    if TDirectory.Exists(AFolder) then
    begin
      LExtension := '.' + AExtension;
      for LFile in TDirectory.GetFiles(AFolder) do
        if SameText(ExtractFileExt(LFile), LExtension) then
          LList.Add(ChangeFileExt(ExtractFileName(LFile), ''));
    end;
    LList.Sort(TComparer<string>.Default);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
