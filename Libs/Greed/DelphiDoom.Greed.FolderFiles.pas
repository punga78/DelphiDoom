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
  System.SysUtils, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The files next to the archive on disk (the .LAY maps of the demos). Several folders can be given: a
  ///   file is taken from the first that has it. The name is a file name, never a path
  /// </summary>
  TGreedFolderFiles = class(TInterfacedObject, IGreedExternalFiles)
  strict private
    FFolders: TArray<string>;
    function PathOf(const AName: string): string;
  public
    constructor Create(const AFolders: array of string);
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Types;

{ TGreedFolderFiles }

constructor TGreedFolderFiles.Create(const AFolders: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FFolders, Length(AFolders));
  for LIndex := 0 to High(AFolders) do
    FFolders[LIndex] := AFolders[LIndex];
end;

function TGreedFolderFiles.PathOf(const AName: string): string;
var
  LFolder: string;
  LCandidate: string;
begin
  Result := '';
  // a name with a folder would let a lump of the archive point anywhere on the disk
  if (AName = '') or (ExtractFileName(AName) <> AName) then
    Exit;
  for LFolder in FFolders do
  begin
    LCandidate := TPath.Combine(LFolder, AName);
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  end;
end;

function TGreedFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := PathOf(AName) <> '';
end;

function TGreedFolderFiles.ReadAll(const AName: string): TBytes;
var
  LPath: string;
begin
  LPath := PathOf(AName);
  if LPath = '' then
    raise EGreedNotFoundException.CreateFmt(SGreedFileNotFound, [AName]);
  Result := TFile.ReadAllBytes(LPath);
end;

end.
