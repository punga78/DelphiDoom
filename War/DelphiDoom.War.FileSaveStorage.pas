{******************************************************************************}
{                                                                              }
{  Warcraft32: the quick slot of the saved game, a file next to the program    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.FileSaveStorage;

interface

uses
  System.SysUtils, DelphiDoom.War.App.Intf;

type
  /// <summary>IWarSaveStorage on a file: the folder is made when the game is saved</summary>
  TWarFileSaveStorage = class(TInterfacedObject, IWarSaveStorage)
  strict private
    FPath: string;
  public
    constructor Create(const APath: string);
    procedure Write(const ABytes: TBytes);
    function TryRead(out ABytes: TBytes): Boolean;
    property Path: string read FPath;
  end;

implementation

uses
  System.IOUtils;

{ TWarFileSaveStorage }

constructor TWarFileSaveStorage.Create(const APath: string);
begin
  inherited Create;
  FPath := APath;
end;

procedure TWarFileSaveStorage.Write(const ABytes: TBytes);
var
  LTemporary: string;
begin
  ForceDirectories(ExtractFilePath(ExpandFileName(FPath)));
  // written beside and renamed, so that a game that is saved over the old one is never half of each
  LTemporary := FPath + '.tmp';
  TFile.WriteAllBytes(LTemporary, ABytes);
  if TFile.Exists(FPath) then
    TFile.Delete(FPath);
  TFile.Move(LTemporary, FPath);
end;

function TWarFileSaveStorage.TryRead(out ABytes: TBytes): Boolean;
begin
  Result := TFile.Exists(FPath);
  if Result then
    ABytes := TFile.ReadAllBytes(FPath)
  else
    ABytes := nil;
end;

end.
