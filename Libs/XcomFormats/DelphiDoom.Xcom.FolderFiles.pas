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
  System.SysUtils, System.Classes, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   The files of the game on disk. Several folders can be given (the data of UFO in one, a mod in another): a
  ///   file is taken from the first folder that has it, as the stack of folders of OpenXcom does. The file
  ///   system of Windows does not care about the case of the names
  /// </summary>
  TXcomFolderFiles = class(TInterfacedObject, IXcomDataFiles)
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
  System.IOUtils;

{ TXcomFolderFiles }

constructor TXcomFolderFiles.Create(const AFolders: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FFolders, Length(AFolders));
  for LIndex := 0 to High(AFolders) do
    FFolders[LIndex] := AFolders[LIndex];
end;

function TXcomFolderFiles.PathOf(const AName: string): string;
var
  LFolder: string;
  LCandidate: string;
begin
  for LFolder in FFolders do
  begin
    LCandidate := TPath.Combine(LFolder, AName.Replace('/', '\'));
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  end;
  Result := '';
end;

function TXcomFolderFiles.Exists(const AName: string): Boolean;
begin
  Result := PathOf(AName) <> '';
end;

function TXcomFolderFiles.ReadAll(const AName: string): TBytes;
var
  LPath: string;
begin
  LPath := PathOf(AName);
  if LPath = '' then
    raise EXcomFileNotFoundException.CreateFmt(SXcomFileMissing, [AName]);
  try
    Result := TFile.ReadAllBytes(LPath);
  except
    on E: EStreamError do
      raise EXcomFileNotFoundException.CreateFmt(SXcomFileUnreadable, [LPath]);
  end;
end;

end.
