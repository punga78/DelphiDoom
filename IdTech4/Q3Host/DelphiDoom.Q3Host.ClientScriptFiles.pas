{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - where the scripts of the precompiler    }
{  come from                                                                    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): botlib\          }
{  be_interface.c (botimport.FS_FOpenFile, FS_Read, FS_FCloseFile).             }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the      }
{  Quake III Arena source code and is therefore available under the GNU         }
{  General Public License, version 2 or (at your option) any later version.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientScriptFiles;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Scanner.Q3.Intf;

type
  /// <summary>IQ3ScriptFiles on the file system of the game (the whole file, from the folders and the paks)</summary>
  TQ3HostScriptFiles = class(TInterfacedObject, IQ3ScriptFiles)
  strict private
    FFiles: IGameFileSystem;
  public
    constructor Create(const AFiles: IGameFileSystem);
    function TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

implementation

constructor TQ3HostScriptFiles.Create(const AFiles: IGameFileSystem);
begin
  inherited Create;
  FFiles := AFiles;
end;

function TQ3HostScriptFiles.TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
begin
  Result := FFiles.ReadFile(string(APath), AData);
end;

end.
