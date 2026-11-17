{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the cinematic calls of cgame and ui     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c and   }
{  cl_ui.c (CIN_PlayCinematic, CIN_StopCinematic, CIN_RunCinematic,             }
{  CIN_DrawCinematic, CIN_SetExtents). Copyright (C) 1999-2005 Id Software,     }
{  Inc. This unit is derived from the Quake III Arena source code and is        }
{  therefore available under the GNU General Public License, version 2 or (at   }
{  your option) any later version.                                              }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.CinematicSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>CG_CIN_* and UI_CIN_* (five calls each)</summary>
  TQ3CinematicSyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const ACinematics: IQ3HostCinematics); static;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

class procedure TQ3CinematicSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const ACinematics: IQ3HostCinematics);
const
  PLAY: array[TQ3Module] of Integer = (-1, CG_CIN_PLAYCINEMATIC, UI_CIN_PLAYCINEMATIC);
  STOP: array[TQ3Module] of Integer = (-1, CG_CIN_STOPCINEMATIC, UI_CIN_STOPCINEMATIC);
  RUN: array[TQ3Module] of Integer = (-1, CG_CIN_RUNCINEMATIC, UI_CIN_RUNCINEMATIC);
  DRAW: array[TQ3Module] of Integer = (-1, CG_CIN_DRAWCINEMATIC, UI_CIN_DRAWCINEMATIC);
  EXTENTS: array[TQ3Module] of Integer = (-1, CG_CIN_SETEXTENTS, UI_CIN_SETEXTENTS);
begin
  if AModule = TQ3Module.Game then
    Exit;
  ARegistry.Register(PLAY[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ACinematics.Play(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'CIN_PlayCinematic'), AArgs[2],
        AArgs[3], AArgs[4], AArgs[5], AArgs[6]);
    end);
  ARegistry.Register(STOP[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ACinematics.Stop(AArgs[1]);
    end);
  ARegistry.Register(RUN[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ACinematics.Run(AArgs[1]);
    end);
  ARegistry.Register(DRAW[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ACinematics.Draw(AArgs[1]);
      Result := 0;
    end);
  ARegistry.Register(EXTENTS[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ACinematics.SetExtents(AArgs[1], AArgs[2], AArgs[3], AArgs[4], AArgs[5]);
      Result := 0;
    end);
end;

end.
