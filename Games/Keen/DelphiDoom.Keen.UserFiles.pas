{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the files that the game writes: a folder          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.UserFiles;

interface

uses
  System.SysUtils, DelphiDoom.Keen.UserIntf, DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   The configuration file and the saved games in a folder of the disk (the original writes them in the
  ///   current folder). A file that cannot be read or written is a False, never an exception: the game goes on
  ///   with its defaults, as the original does when open() fails
  /// </summary>
  TKeenFolderUserFiles = class(TInterfacedObject, IKeenUserFiles)
  strict private
    FStore: IFileStore;
    FFolder: string;
    function PathOf(const AName: string): string;
  public
    /// <param name="AStore">The files of the machine</param>
    /// <param name="AFolder">The folder; it is made when the first file is written</param>
    constructor Create(const AStore: IFileStore; const AFolder: string);
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
    function TryWrite(const AName: string; const ABytes: TBytes): Boolean;
    procedure Delete(const AName: string);
  end;

implementation

{ TKeenFolderUserFiles }

constructor TKeenFolderUserFiles.Create(const AStore: IFileStore; const AFolder: string);
begin
  inherited Create;
  if not Assigned(AStore) then
    raise EArgumentNilException.Create('AStore');
  FStore := AStore;
  FFolder := AFolder;
end;

function TKeenFolderUserFiles.PathOf(const AName: string): string;
begin
  if FFolder = '' then
    Result := AName
  else
    Result := IncludeTrailingPathDelimiter(FFolder) + AName;
end;

function TKeenFolderUserFiles.TryRead(const AName: string; out ABytes: TBytes): Boolean;
begin
  ABytes := nil;
  Result := FStore.Exists(PathOf(AName));
  if not Result then
    Exit;
  try
    ABytes := FStore.Read(PathOf(AName));
  except
    on E: Exception do
    begin
      // a file that is there and cannot be read is the same as no file for the game
      ABytes := nil;
      Result := False;
    end;
  end;
end;

function TKeenFolderUserFiles.TryWrite(const AName: string; const ABytes: TBytes): Boolean;
var
  LSource: Pointer;
begin
  if (FFolder <> '') and not FStore.EnsureDirectory(FFolder) then
    Exit(False);
  LSource := nil;
  if Length(ABytes) > 0 then
    LSource := @ABytes[0];
  Result := FStore.Write(PathOf(AName), LSource, Length(ABytes));
end;

procedure TKeenFolderUserFiles.Delete(const AName: string);
begin
  if FStore.Exists(PathOf(AName)) then
    FStore.Delete(PathOf(AName));
end;

end.
