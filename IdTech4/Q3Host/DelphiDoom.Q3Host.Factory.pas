{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - factory                                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,       }
{  cl_cgame.c, cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Factory;

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf;

type
  /// <summary>The only place that knows the classes of the host</summary>
  TQ3HostFactory = class
  public
    /// <summary>
    ///   The host of a module with the common system calls already registered (see TQ3CommonSyscalls); the
    ///   engine adds the others (cvars, file system, entities, renderer ...) through Registry
    /// </summary>
    class function CreateHost(AModule: TQ3Module; const AConsole: IQ3HostConsole;
      const ATime: IQ3HostTime): IQ3SyscallHost; static;
  end;

implementation

uses
  DelphiDoom.Q3Host.SyscallHost, DelphiDoom.Q3Host.CommonSyscalls;

class function TQ3HostFactory.CreateHost(AModule: TQ3Module; const AConsole: IQ3HostConsole;
  const ATime: IQ3HostTime): IQ3SyscallHost;
var
  LHost: TQ3SyscallHost;
begin
  LHost := TQ3SyscallHost.Create(AModule);
  Result := LHost;
  TQ3CommonSyscalls.Register(AModule, Result.Registry, AConsole, ATime);
end;

end.
