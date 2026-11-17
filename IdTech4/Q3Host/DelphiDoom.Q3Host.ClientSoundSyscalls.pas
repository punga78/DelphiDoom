{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the sound calls of cgame and ui         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c and   }
{  cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived      }
{  from the Quake III Arena source code and is therefore available under the    }
{  GNU General Public License, version 2 or (at your option) any later          }
{  version.                                                                     }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientSoundSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   CG_S_STARTSOUND, STARTLOCALSOUND, CLEARLOOPINGSOUNDS, ADDLOOPINGSOUND, ADDREALLOOPINGSOUND,
  ///   STOPLOOPINGSOUND, UPDATEENTITYPOSITION, RESPATIALIZE, REGISTERSOUND, STARTBACKGROUNDTRACK,
  ///   STOPBACKGROUNDTRACK and UI_S_REGISTERSOUND, STARTLOCALSOUND, STARTBACKGROUNDTRACK, STOPBACKGROUNDTRACK.
  ///   A pointer to a vector that is NULL is the zero vector (the C reads address 0 of the host), except for the
  ///   origin of CG_S_STARTSOUND where NULL means "follow the entity"
  /// </summary>
  TQ3SoundSyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const ASound: IQ3HostSound); static;
  end;

implementation

uses
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Arguments;

function ReadVec3(const AMemory: IQvmMemory; AAddress: Integer): TQ3HostVec3;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    if AAddress = 0 then
      Result[LIndex] := 0
    else
      Result[LIndex] := TQ3SyscallArguments.ToSingle(AMemory.ReadInt32(AAddress + 4 * LIndex));
end;

// the string of an argument that may be NULL
function OptionalText(const AMemory: IQvmMemory; AAddress: Integer): AnsiString;
begin
  if AAddress = 0 then
    Result := ''
  else
    Result := AMemory.ReadString(AAddress);
end;

class procedure TQ3SoundSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const ASound: IQ3HostSound);
begin
  case AModule of
    TQ3Module.CGame:
      begin
        ARegistry.Register(CG_S_STARTSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          var
            LOrigin: PQ3HostVec3;
          begin
            LOrigin := nil;
            if AArgs[1] <> 0 then
              LOrigin := PQ3HostVec3(AMachine.Memory.Range(AArgs[1], SizeOf(TQ3HostVec3)));
            ASound.StartSound(LOrigin, AArgs[2], AArgs[3], AArgs[4]);
            Result := 0;
          end);
        ARegistry.Register(CG_S_STARTLOCALSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StartLocalSound(AArgs[1], AArgs[2]);
            Result := 0;
          end);
        ARegistry.Register(CG_S_CLEARLOOPINGSOUNDS,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.ClearLoopingSounds(AArgs[1] <> 0);
            Result := 0;
          end);
        ARegistry.Register(CG_S_ADDLOOPINGSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.AddLoopingSound(AArgs[1], ReadVec3(AMachine.Memory, AArgs[2]),
              ReadVec3(AMachine.Memory, AArgs[3]), AArgs[4]);
            Result := 0;
          end);
        ARegistry.Register(CG_S_ADDREALLOOPINGSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.AddRealLoopingSound(AArgs[1], ReadVec3(AMachine.Memory, AArgs[2]),
              ReadVec3(AMachine.Memory, AArgs[3]), AArgs[4]);
            Result := 0;
          end);
        ARegistry.Register(CG_S_STOPLOOPINGSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StopLoopingSound(AArgs[1]);
            Result := 0;
          end);
        ARegistry.Register(CG_S_UPDATEENTITYPOSITION,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.UpdateEntityPosition(AArgs[1], ReadVec3(AMachine.Memory, AArgs[2]));
            Result := 0;
          end);
        ARegistry.Register(CG_S_RESPATIALIZE,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          var
            LAxis: TQ3HostAxis;
            LRow: Integer;
          begin
            for LRow := 0 to 2 do
              if AArgs[3] = 0 then
                LAxis[LRow] := ReadVec3(AMachine.Memory, 0)
              else
                LAxis[LRow] := ReadVec3(AMachine.Memory, AArgs[3] + 12 * LRow);
            ASound.Respatialize(AArgs[1], ReadVec3(AMachine.Memory, AArgs[2]), LAxis, AArgs[4]);
            Result := 0;
          end);
        ARegistry.Register(CG_S_REGISTERSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ASound.RegisterSound(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'CG_S_REGISTERSOUND'),
              AArgs[2] <> 0);
          end);
        ARegistry.Register(CG_S_STARTBACKGROUNDTRACK,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StartBackgroundTrack(OptionalText(AMachine.Memory, AArgs[1]),
              OptionalText(AMachine.Memory, AArgs[2]));
            Result := 0;
          end);
        ARegistry.Register(CG_S_STOPBACKGROUNDTRACK,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StopBackgroundTrack;
            Result := 0;
          end);
      end;
    TQ3Module.Ui:
      begin
        ARegistry.Register(UI_S_REGISTERSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ASound.RegisterSound(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'UI_S_REGISTERSOUND'),
              AArgs[2] <> 0);
          end);
        ARegistry.Register(UI_S_STARTLOCALSOUND,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StartLocalSound(AArgs[1], AArgs[2]);
            Result := 0;
          end);
        ARegistry.Register(UI_S_STARTBACKGROUNDTRACK,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StartBackgroundTrack(OptionalText(AMachine.Memory, AArgs[1]),
              OptionalText(AMachine.Memory, AArgs[2]));
            Result := 0;
          end);
        ARegistry.Register(UI_S_STOPBACKGROUNDTRACK,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ASound.StopBackgroundTrack;
            Result := 0;
          end);
      end;
  end;
end;

end.
