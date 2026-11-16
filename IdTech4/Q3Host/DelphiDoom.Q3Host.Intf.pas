{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the contracts                           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,       }
{  cl_cgame.c, cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Intf;

interface

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf;

type
  /// <summary>
  ///   What answers one system call: AArguments[0] is the number, [1..9] the arguments as the program pushed
  ///   them; the result is the value the program sees
  /// </summary>
  TQ3SyscallHandler = reference to function(const AMachine: IQvmMachine;
    const AArguments: TQvmSystemCallArguments): Integer;

  /// <summary>Where the handlers of the system calls of one module are put (one per number)</summary>
  IQ3SyscallRegistry = interface
    ['{8A41C7E2-5D03-4B96-A1F8-2E67B0D93C54}']
    /// <summary>Replaces the handler of the number, if there was one</summary>
    procedure Register(ANumber: Integer; const AHandler: TQ3SyscallHandler);
    function IsRegistered(ANumber: Integer): Boolean;
    function RegisteredCount: Integer;
  end;

  /// <summary>The IQvmHost of a module with the registry of its handlers (the same object)</summary>
  IQ3SyscallHost = interface(IQvmHost)
    ['{5B7D0E93-A216-4C48-8E5F-91C3D4A7F620}']
    function GetRegistry: IQ3SyscallRegistry;
    function GetFallback: IQvmHost;
    procedure SetFallback(const AValue: IQvmHost);
    property Registry: IQ3SyscallRegistry read GetRegistry;
    /// <summary>Asked for the system calls the module has and nobody registered; may be nil</summary>
    property Fallback: IQvmHost read GetFallback write SetFallback;
  end;

  /// <summary>Com_Printf: the text of G_PRINT, CG_PRINT and UI_PRINT, as the module wrote it</summary>
  IQ3HostConsole = interface
    ['{3E9B52D8-17C4-4A60-8F2B-C5D1A7E04B39}']
    procedure Print(const AText: AnsiString);
  end;

  /// <summary>Sys_Milliseconds</summary>
  IQ3HostTime = interface
    ['{D7160A4F-B2E5-4C38-9A71-0F83E6C2B5D4}']
    function Milliseconds: Integer;
  end;

implementation

end.
