{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, files on IGameFileSystem   }
{                                                                              }
{  FS_ReadFile as the exec command uses it, on the file system of Libs\Wad.    }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.GameFileSystem;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   <c>IQ3FileSystem</c> on an <c>IGameFileSystem</c> (the search list of folders and paks): the
  ///   bytes of the file are the characters of the text, one to one. The file system must be started:
  ///   before <c>Startup</c> it raises <c>EGameFsException</c>, a programming error that is not hidden
  /// </summary>
  TQ3GameFileSystem = class(TInterfacedObject, IQ3FileSystem)
  strict private
    FFileSystem: IGameFileSystem;
  public
    constructor Create(const AFileSystem: IGameFileSystem);
    function TryReadFile(const AName: AnsiString; out AText: AnsiString): Boolean;
  end;

implementation

{ TQ3GameFileSystem }

constructor TQ3GameFileSystem.Create(const AFileSystem: IGameFileSystem);
begin
  inherited Create;
  FFileSystem := AFileSystem;
end;

function TQ3GameFileSystem.TryReadFile(const AName: AnsiString; out AText: AnsiString): Boolean;
var
  LBytes: TBytes;
begin
  AText := '';
  Result := FFileSystem.ReadFile(string(AName), LBytes);
  if Result and (Length(LBytes) > 0) then
    SetString(AText, PAnsiChar(@LBytes[0]), Length(LBytes));
end;

end.
