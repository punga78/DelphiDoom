{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the services of cgame and ui and the    }
{  groups of system calls they switch on                                        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c,      }
{  cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived      }
{  from the Quake III Arena source code and is therefore available under the    }
{  GNU General Public License, version 2 or (at your option) any later          }
{  version.                                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Client.Services;

interface

uses
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.ClientCdKey;

type
  /// <summary>
  ///   What the client gives to cgame and ui (phase 2c). Every service is optional: a group of calls is registered
  ///   only when the services it needs are there. The CD key and the sources of the parser are not owned
  /// </summary>
  TQ3HostClientServices = record
    State: IQ3HostClientState;
    Connection: IQ3HostUiConnection;
    ClientSystem: IQ3HostClientSystem;
    Keys: IQ3HostKeys;
    Sound: IQ3HostSound;
    Cinematics: IQ3HostCinematics;
    Renderer: IQ3HostRenderer;
    Lan: IQ3HostLan;
    CdKey: TQ3ClientCdKey;
    Sources: TQ3SourceHandles;
  end;

  /// <summary>Registers the groups of calls of cgame and ui that have their services</summary>
  TQ3ClientGroups = class sealed
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const AServices: TQ3HostClientServices; const ACVars: IQ3CVarSystem); static;
  end;

implementation

uses
  DelphiDoom.Q3Host.ClientStateSyscalls, DelphiDoom.Q3Host.KeySyscalls, DelphiDoom.Q3Host.SoundSyscalls,
  DelphiDoom.Q3Host.CinematicSyscalls, DelphiDoom.Q3Host.RendererSyscalls, DelphiDoom.Q3Host.PrecompilerSyscalls,
  DelphiDoom.Q3Host.LanSyscalls, DelphiDoom.Q3Host.CdKeySyscalls;

class procedure TQ3ClientGroups.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const AServices: TQ3HostClientServices; const ACVars: IQ3CVarSystem);
begin
  if AModule = TQ3Module.Game then
    Exit;
  if (AModule = TQ3Module.CGame) and Assigned(AServices.State) then
    TQ3ClientStateSyscalls.RegisterCGame(ARegistry, AServices.State);
  if AModule = TQ3Module.Ui then
    TQ3ClientStateSyscalls.RegisterUi(ARegistry, AServices.State, AServices.Connection);
  if Assigned(AServices.ClientSystem) then
    TQ3ClientStateSyscalls.RegisterSystem(AModule, ARegistry, AServices.ClientSystem);
  if Assigned(AServices.Keys) then
    TQ3KeySyscalls.Register(AModule, ARegistry, AServices.Keys);
  if Assigned(AServices.Sound) then
    TQ3SoundSyscalls.Register(AModule, ARegistry, AServices.Sound);
  if Assigned(AServices.Cinematics) then
    TQ3CinematicSyscalls.Register(AModule, ARegistry, AServices.Cinematics);
  if Assigned(AServices.Renderer) then
    TQ3RendererSyscalls.Register(AModule, ARegistry, AServices.Renderer);
  if Assigned(AServices.Sources) then
    TQ3PrecompilerSyscalls.Register(AModule, ARegistry, AServices.Sources);
  if (AModule = TQ3Module.Ui) and Assigned(AServices.Lan) then
    TQ3LanSyscalls.Register(ARegistry, AServices.Lan);
  if (AModule = TQ3Module.Ui) and Assigned(AServices.CdKey) and Assigned(ACVars) then
    TQ3CdKeySyscalls.Register(ARegistry, AServices.CdKey, ACVars);
end;

end.
