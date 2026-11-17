{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the map from the file system           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): CM_LoadMap of   }
{  cm_load.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.MapLoader;

interface

uses
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   The bytes of "maps/x.bsp" from the file system (FS_ReadFile) become a collision model with the patches
  ///   that collide (the patch builder of Framework\Collision); nil when the file is not there
  /// </summary>
  TQ3HostMapLoader = class(TInterfacedObject, IQ3HostMapLoader)
  strict private
    FFiles: IGameFileSystem;
  public
    constructor Create(const AFiles: IGameFileSystem);
    function Load(const AName: AnsiString): IQ3CollisionModel;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Factory, DelphiDoom.MapFile.Bsp.Factory;

constructor TQ3HostMapLoader.Create(const AFiles: IGameFileSystem);
begin
  inherited Create;
  FFiles := AFiles;
end;

function TQ3HostMapLoader.Load(const AName: AnsiString): IQ3CollisionModel;
var
  LData: TBytes;
begin
  if not FFiles.ReadFile(string(AName), LData) then
    Exit(nil);
  Result := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, LData, AName,
    TQ3CollisionFactory.CreatePatchBuilder);
end;

end.
