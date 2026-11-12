{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - data files in folders                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.FolderFiles;

interface

uses
  System.SysUtils, DelphiDoom.Platform.FolderFiles.Intf, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   The files of the game on disk: IXcomDataFiles over the IFolderFiles of Libs\Platform, with the errors of
  ///   the xcom library. Several folders can be given (the data of UFO in one, a mod in another): a file is taken
  ///   from the first folder that has it, as the stack of folders of OpenXcom does. The file system of Windows
  ///   does not care about the case of the names
  /// </summary>
  TXcomFolderFiles = class(TInterfacedObject, IXcomDataFiles)
  strict private
    FFiles: IFolderFiles;
  public
    constructor Create(const AFiles: IFolderFiles);
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

constructor TXcomFolderFiles.Create(const AFiles: IFolderFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

function TXcomFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := FFiles.Exists(AName);
end;

function TXcomFolderFiles.ReadAll(const AName: string): TBytes;
var
  LPath: string;
begin
  LPath := FFiles.Find(AName);
  if LPath = '' then
    raise EXcomFileNotFoundException.CreateFmt(SXcomFileMissing, [AName]);
  try
    Result := FFiles.ReadAll(AName);
  except
    on E: EFolderFileException do
      raise EXcomFileNotFoundException.CreateFmt(SXcomFileUnreadable, [LPath]);
  end;
end;

end.
