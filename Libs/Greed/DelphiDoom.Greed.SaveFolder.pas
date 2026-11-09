{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the saved games in a folder                      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SaveFolder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Save.Intf;

type
  /// <summary>The files of the saved games in a folder of the disk (the folder of the game)</summary>
  TGreedSaveFolder = class(TInterfacedObject, IGreedSaveFiles)
  strict private
    FFolder: string;
    function PathOf(const AName: string): string;
  public
    constructor Create(const AFolder: string);
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
    procedure WriteAll(const AName: string; const ABytes: TBytes);
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Types;

{ TGreedSaveFolder }

constructor TGreedSaveFolder.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := AFolder;
end;

function TGreedSaveFolder.PathOf(const AName: string): string;
begin
  // a name is a file of the folder, never a path
  if (AName = '') or (ExtractFileName(AName) <> AName) then
    raise EGreedException.CreateFmt(SGreedFileNotWritten, [AName]);
  Result := TPath.Combine(FFolder, AName);
end;

function TGreedSaveFolder.Exists(const AName: string): Boolean;
begin
  Result := TFile.Exists(PathOf(AName));
end;

function TGreedSaveFolder.ReadAll(const AName: string): TBytes;
begin
  if not Exists(AName) then
    raise EGreedNotFoundException.CreateFmt(SGreedFileNotFound, [AName]);
  Result := TFile.ReadAllBytes(PathOf(AName));
end;

procedure TGreedSaveFolder.WriteAll(const AName: string; const ABytes: TBytes);
begin
  try
    TFile.WriteAllBytes(PathOf(AName), ABytes);
  except
    on E: EInOutError do
      raise EGreedException.CreateFmt(SGreedFileNotWritten, [AName]);
  end;
end;

end.
