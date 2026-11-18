{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - files            }
{                                                                              }
{  Written for the repository (licence GPL v2 or later).                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Files.GameFs;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Q3Render.Intf;

type
  /// <summary>ri.FS_ReadFile on the file system of Framework\Wad (folders and pk3 files, the last pak first)</summary>
  TQ3RenderGameFiles = class(TInterfacedObject, IQ3RenderFiles)
  strict private
    FFileSystem: IGameFileSystem;
  public
    constructor Create(const AFileSystem: IGameFileSystem);
    function ReadFile(const AName: AnsiString; out AData: TBytes): Boolean;
  end;

implementation

constructor TQ3RenderGameFiles.Create(const AFileSystem: IGameFileSystem);
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  FFileSystem := AFileSystem;
end;

function TQ3RenderGameFiles.ReadFile(const AName: AnsiString; out AData: TBytes): Boolean;
begin
  AData := nil;
  if AName = '' then
    Exit(False);
  Result := FFileSystem.ReadFile(string(AName), AData);
end;

end.
