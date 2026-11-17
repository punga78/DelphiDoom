{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the clipmap the server and the         }
{  client game share                                                           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): CM_LoadMap of   }
{  cm_load.c and CL_CM_LoadMap of cl_cgame.c. Copyright (C) 1999-2005 Id       }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClipMap;

interface

uses
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   The map that is loaded: in the C a global of cm_load.c, here an object the engine gives to the host of
  ///   qagame and of cgame (CM_LoadMap with clientload does nothing for the name already loaded)
  /// </summary>
  TQ3HostClipMap = class(TInterfacedObject, IQ3HostClipMap)
  strict private
    FLoader: IQ3HostMapLoader;
    FModel: IQ3CollisionModel;
    FName: AnsiString;
  public
    constructor Create(const ALoader: IQ3HostMapLoader);
    function GetModel: IQ3CollisionModel;
    function GetName: AnsiString;
    procedure Load(const AName: AnsiString);
    procedure SetModel(const AModel: IQ3CollisionModel; const AName: AnsiString);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Q3Host.Types;

resourcestring
  SCouldNotLoadMap = 'Couldn''t load %s';

constructor TQ3HostClipMap.Create(const ALoader: IQ3HostMapLoader);
begin
  inherited Create;
  FLoader := ALoader;
end;

function TQ3HostClipMap.GetModel: IQ3CollisionModel;
begin
  Result := FModel;
end;

function TQ3HostClipMap.GetName: AnsiString;
begin
  Result := FName;
end;

procedure TQ3HostClipMap.Load(const AName: AnsiString);
var
  LModel: IQ3CollisionModel;
begin
  if Assigned(FModel) and (FName = AName) then
    Exit;
  if not Assigned(FLoader) then
    raise EQ3HostException.CreateFmt(SCouldNotLoadMap, [string(AName)]);
  LModel := FLoader.Load(AName);
  if not Assigned(LModel) then
    raise EQ3HostException.CreateFmt(SCouldNotLoadMap, [string(AName)]);
  FModel := LModel;
  FName := AName;
end;

procedure TQ3HostClipMap.SetModel(const AModel: IQ3CollisionModel; const AName: AnsiString);
begin
  FModel := AModel;
  FName := AName;
end;

end.
