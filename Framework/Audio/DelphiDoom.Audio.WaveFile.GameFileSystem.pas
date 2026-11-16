{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - wave file system on the file system of Wad      }
{                                                                              }
{  Written for this repository (GPL v2 or later); the contract it fills is     }
{  that of idFileSystem as idWaveFile uses it.                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveFile.GameFileSystem;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Audio.WaveFile.Intf;

type
  /// <summary>
  ///   <c>IWaveFileSystem</c> on <c>IGameFileSystem</c>: the search list of folders and paks. The file system must
  ///   be started (before <c>Startup</c> it raises <c>EGameFsException</c>)
  /// </summary>
  TWaveGameFileSystem = class(TInterfacedObject, IWaveFileSystem)
  strict private
    FFileSystem: IGameFileSystem;
  public
    constructor Create(const AFileSystem: IGameFileSystem);
    function FileLength(const AName: string): Integer;
    function TryReadFile(const AName: string; out AData: TBytes): Boolean;
    function Timestamp(const AName: string): Int64;
  end;

implementation

{ TWaveGameFileSystem }

constructor TWaveGameFileSystem.Create(const AFileSystem: IGameFileSystem);
begin
  inherited Create;
  FFileSystem := AFileSystem;
end;

function TWaveGameFileSystem.FileLength(const AName: string): Integer;
begin
  Result := FFileSystem.FileLength(AName);
end;

function TWaveGameFileSystem.TryReadFile(const AName: string; out AData: TBytes): Boolean;
begin
  Result := FFileSystem.ReadFile(AName, AData);
end;

function TWaveGameFileSystem.Timestamp(const AName: string): Int64;
var
  LFile: IGameFile;
begin
  LFile := FFileSystem.OpenFileRead(AName);
  if Assigned(LFile) then
    Result := LFile.Timestamp
  else
    Result := 0;
end;

end.
