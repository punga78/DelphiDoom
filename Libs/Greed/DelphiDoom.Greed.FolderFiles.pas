{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - files in folders                                 }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.FolderFiles;

interface

uses
  System.SysUtils, DelphiDoom.Platform.FolderFiles.Intf, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The files next to the archive on disk (the .LAY maps of the demos): IGreedExternalFiles over the
  ///   IFolderFiles of Libs\Platform, with the errors of the greed library. The files must be the ones that take
  ///   file names only (TFolderFilesFactory.CreateFileNamesOnly): a name with a folder would let a lump of the
  ///   archive point anywhere on the disk
  /// </summary>
  TGreedFolderFiles = class(TInterfacedObject, IGreedExternalFiles)
  strict private
    FFiles: IFolderFiles;
  public
    constructor Create(const AFiles: IFolderFiles);
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

constructor TGreedFolderFiles.Create(const AFiles: IFolderFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

function TGreedFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := FFiles.Exists(AName);
end;

function TGreedFolderFiles.ReadAll(const AName: string): TBytes;
begin
  if not FFiles.Exists(AName) then
    raise EGreedNotFoundException.CreateFmt(SGreedFileNotFound, [AName]);
  Result := FFiles.ReadAll(AName);
end;

end.
