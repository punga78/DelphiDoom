{******************************************************************************}
{                                                                              }
{  DelphiDoom: models library - model files on IGameFileSystem                 }
{                                                                              }
{  Written for this repository (GPL v2 or later): the adapter that the         }
{  contract IModelFileSource (idFileSystem::ReadFile with the time stamp)      }
{  waited for.                                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Source.GameFileSystem;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Models.Source.Intf;

type
  /// <summary>
  ///   <c>IModelFileSource</c> on the file system of id Tech 4 (<c>IGameFileSystem</c> of Libs\Wad: the search
  ///   list of folders and paks). The bytes are returned as an 8-bit string, one character a byte; the time stamp is
  ///   that of the file in a folder and 0 inside a pak (as <c>idFile_InZip</c>)
  /// </summary>
  TModelGameFileSource = class(TInterfacedObject, IModelFileSource)
  strict private
    FFileSystem: IGameFileSystem;
  public
    constructor Create(const AFileSystem: IGameFileSystem);
    function ReadFile(const AName: AnsiString; out AData: AnsiString; out ATimeStamp: Int64): Boolean;
  end;

implementation

{ TModelGameFileSource }

constructor TModelGameFileSource.Create(const AFileSystem: IGameFileSystem);
begin
  inherited Create;
  FFileSystem := AFileSystem;
end;

function TModelGameFileSource.ReadFile(const AName: AnsiString; out AData: AnsiString; out ATimeStamp: Int64): Boolean;
var
  LBytes: TBytes;
  LFile: IGameFile;
begin
  AData := '';
  ATimeStamp := 0;
  Result := FFileSystem.ReadFile(string(AName), LBytes);
  if not Result then
    Exit;
  if Length(LBytes) > 0 then
    SetString(AData, PAnsiChar(@LBytes[0]), Length(LBytes));
  LFile := FFileSystem.OpenFileRead(string(AName));
  if Assigned(LFile) then
    ATimeStamp := LFile.Timestamp;
end;

end.
