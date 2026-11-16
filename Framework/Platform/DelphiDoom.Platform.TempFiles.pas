{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the temporary files                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.TempFiles;

interface

uses
  System.Generics.Collections, DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   The temporary files: new ones go in the temporary directory, any file can be declared,
  ///   and DeleteAll removes what is still there
  /// </summary>
  TTempFiles = class(TInterfacedObject, ITempFiles)
  strict private
    FDirectory: ITempDirectory;
    FStore: IFileStore;
    FNames: TList<string>;
  public
    constructor Create(const ADirectory: ITempDirectory; const AStore: IFileStore);
    destructor Destroy; override;
    function NewTempFile(const AName: string): string;
    procedure Declare(const AName: string);
    procedure DeleteAll;
    function GetCount: Integer;
    function GetName(AIndex: Integer): string;
  end;

implementation

uses
  System.SysUtils;

{ TTempFiles }

constructor TTempFiles.Create(const ADirectory: ITempDirectory; const AStore: IFileStore);
begin
  inherited Create;
  if not Assigned(ADirectory) then
    raise EArgumentNilException.Create('ADirectory');
  if not Assigned(AStore) then
    raise EArgumentNilException.Create('AStore');
  FDirectory := ADirectory;
  FStore := AStore;
  FNames := TList<string>.Create;
end;

destructor TTempFiles.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

function TTempFiles.NewTempFile(const AName: string): string;
var
  LDirectory: string;
begin
  LDirectory := IncludeTrailingPathDelimiter(FDirectory.Directory);
  // a directory that cannot be made shows up when the file is created
  FStore.EnsureDirectory(LDirectory);
  Result := LDirectory + ExtractFileName(AName);
  FNames.Add(Result);
end;

procedure TTempFiles.Declare(const AName: string);
begin
  FNames.Add(AName);
end;

procedure TTempFiles.DeleteAll;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FNames.Count - 1 do
    FStore.Delete(FNames[LIndex]);
  FNames.Clear;
end;

function TTempFiles.GetCount: Integer;
begin
  Result := FNames.Count;
end;

function TTempFiles.GetName(AIndex: Integer): string;
begin
  Result := FNames[AIndex];
end;

end.
