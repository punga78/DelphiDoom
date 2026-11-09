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
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The files of the game on disk. Several folders can be given (the data of the game in one, the
  ///   dictionaries and headers of the .KDR files in another): a file is taken from the first that has it
  /// </summary>
  TKeenFolderFiles = class(TInterfacedObject, IKeenDataFiles)
  strict private
    FFolders: TArray<string>;
    function PathOf(const AName: string): string;
  public
    constructor Create(const AFolders: array of string);
    function Exists(const AName: string): Boolean;
    function OpenStream(const AName: string): TStream;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

uses
  System.IOUtils;

{ TKeenFolderFiles }

constructor TKeenFolderFiles.Create(const AFolders: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FFolders, Length(AFolders));
  for LIndex := 0 to High(AFolders) do
    FFolders[LIndex] := AFolders[LIndex];
end;

function TKeenFolderFiles.PathOf(const AName: string): string;
var
  LFolder: string;
  LCandidate: string;
begin
  for LFolder in FFolders do
  begin
    LCandidate := TPath.Combine(LFolder, AName);
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  end;
  Result := '';
end;

function TKeenFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := PathOf(AName) <> '';
end;

function TKeenFolderFiles.OpenStream(const AName: string): TStream;
var
  LPath: string;
begin
  LPath := PathOf(AName);
  if LPath = '' then
    raise EKeenFileNotFoundException.CreateFmt(SKeenFileMissing, [AName]);
  try
    Result := TFileStream.Create(LPath, fmOpenRead or fmShareDenyNone);
  except
    on E: EFOpenError do
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
