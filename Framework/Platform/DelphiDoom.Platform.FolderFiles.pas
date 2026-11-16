{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - files looked for in several folders of the    }
{  disk                                                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.FolderFiles;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Platform.FolderFiles.Intf;

type
  /// <summary>
  ///   IFolderFiles on the disk. The folders are tried in the order they were given. With AFileNamesOnly a name
  ///   that has a folder in it is never found: for the names that come from the data of a game, which must not be
  ///   able to point anywhere on the disk
  /// </summary>
  TFolderFiles = class(TInterfacedObject, IFolderFiles)
  strict private
    FFolders: TArray<string>;
    FFileNamesOnly: Boolean;
  public
    constructor Create(const AFolders: array of string; AFileNamesOnly: Boolean = False);
    function Find(const AName: string): string;
    function Exists(const AName: string): Boolean;
    function OpenStream(const AName: string): TStream;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

uses
  System.IOUtils;

const
  SFolderFileMissing = 'The file %s was not found in the folders';
  SFolderFileUnreadable = 'The file %s cannot be read';

constructor TFolderFiles.Create(const AFolders: array of string; AFileNamesOnly: Boolean);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FFolders, Length(AFolders));
  for LIndex := 0 to High(AFolders) do
    FFolders[LIndex] := AFolders[LIndex];
  FFileNamesOnly := AFileNamesOnly;
end;

function TFolderFiles.Find(const AName: string): string;
var
  LName: string;
  LFolder: string;
  LCandidate: string;
begin
  Result := '';
  if AName = '' then
    Exit;
  LName := AName.Replace('/', '\');
  if FFileNamesOnly and (ExtractFileName(LName) <> LName) then
    Exit;
  for LFolder in FFolders do
  begin
    LCandidate := TPath.Combine(LFolder, LName);
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  end;
end;

function TFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := Find(AName) <> '';
end;

function TFolderFiles.OpenStream(const AName: string): TStream;
var
  LPath: string;
begin
  LPath := Find(AName);
  if LPath = '' then
    raise EFolderFileException.CreateFmt(SFolderFileMissing, [AName]);
  try
    Result := TFileStream.Create(LPath, fmOpenRead or fmShareDenyNone);
  except
    on E: EStreamError do
      raise EFolderFileException.CreateFmt(SFolderFileUnreadable, [LPath]);
  end;
end;

function TFolderFiles.ReadAll(const AName: string): TBytes;
var
  LStream: TStream;
begin
  LStream := OpenStream(AName);
  try
    try
      SetLength(Result, LStream.Size);
      if Length(Result) > 0 then
        LStream.ReadBuffer(Result[0], Length(Result));
    except
      on E: EStreamError do
        raise EFolderFileException.CreateFmt(SFolderFileUnreadable, [AName]);
    end;
  finally
    LStream.Free;
  end;
end;

end.
