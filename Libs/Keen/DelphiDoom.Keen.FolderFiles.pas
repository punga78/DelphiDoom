{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - data files in folders                             }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.FolderFiles;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Platform.FolderFiles.Intf, DelphiDoom.Keen.Types,
  DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The files of the game on disk: IKeenDataFiles over the IFolderFiles of Libs\Platform, with the errors of
  ///   the keen library. Several folders can be given (the data of the game in one, the dictionaries and
  ///   headers of the .KDR files in another): a file is taken from the first that has it
  /// </summary>
  TKeenFolderFiles = class(TInterfacedObject, IKeenDataFiles)
  strict private
    FFiles: IFolderFiles;
  public
    constructor Create(const AFiles: IFolderFiles);
    function Exists(const AName: string): Boolean;
    function OpenStream(const AName: string): TStream;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

constructor TKeenFolderFiles.Create(const AFiles: IFolderFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

function TKeenFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := FFiles.Exists(AName);
end;

function TKeenFolderFiles.OpenStream(const AName: string): TStream;
var
  LPath: string;
begin
  LPath := FFiles.Find(AName);
  if LPath = '' then
    raise EKeenFileNotFoundException.CreateFmt(SKeenFileMissing, [AName]);
  try
    Result := FFiles.OpenStream(AName);
  except
    on E: EFolderFileException do
      raise EKeenFileNotFoundException.CreateFmt(SKeenFileUnreadable, [LPath]);
  end;
end;

function TKeenFolderFiles.ReadAll(const AName: string): TBytes;
var
  LStream: TStream;
begin
  LStream := OpenStream(AName);
  try
    SetLength(Result, LStream.Size);
    if Length(Result) > 0 then
      LStream.ReadBuffer(Result[0], Length(Result));
  finally
    LStream.Free;
  end;
end;

end.
