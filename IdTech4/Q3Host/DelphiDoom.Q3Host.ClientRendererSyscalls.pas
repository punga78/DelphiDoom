{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the renderer calls of cgame and ui      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c and   }
{  cl_ui.c (the re.* calls, CL_GetGlconfig). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientRendererSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   The renderer calls of cgame (CG_R_*, CG_GETGLCONFIG, CG_CM_MARKFRAGMENTS) and of ui (UI_R_*, UI_CM_LERPTAG,
  ///   UI_GETGLCONFIG). Defect of the C kept: CG_R_REGISTERFONT has no return, so it runs on into
  ///   CG_R_CLEARSCENE (the scene is cleared after every font that cgame registers) and returns 0; the ui version
  ///   returns. UI_CM_LERPTAG calls the renderer and returns 0 whatever it says
  /// </summary>
  TQ3RendererSyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const ARenderer: IQ3HostRenderer); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Arguments;

function ReadVec3(const AMemory: IQvmMemory; AAddress: Integer): TQ3HostVec3;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
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

class procedure TQ3RendererSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const ARenderer: IQ3HostRenderer);

  procedure Text(ANumber: Integer; const AName: string; const AHandler: TProc<AnsiString>);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AHandler(TQ3SyscallArguments.Text(AMachine, AArgs[1], AName));
        Result := 0;
      end);
  end;

  procedure Handle(ANumber: Integer; const AName: string; const AFunction: TFunc<AnsiString, Integer>);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := AFunction(TQ3SyscallArguments.Text(AMachine, AArgs[1], AName));
      end);
  end;

  procedure Light(ANumber: Integer; AAdditive: Boolean);
  begin
    ARegistry.Register(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.AddLightToScene(ReadVec3(AMachine.Memory, AArgs[1]), TQ3SyscallArguments.ToSingle(AArgs[2]),
          TQ3SyscallArguments.ToSingle(AArgs[3]), TQ3SyscallArguments.ToSingle(AArgs[4]),
          TQ3SyscallArguments.ToSingle(AArgs[5]), AAdditive);
        Result := 0;
      end);
  end;

  procedure Common(AClearScene, AAddRefEntity, AAddPoly, AAddLight, ARenderScene, ASetColor, ADrawStretchPic,
    AModelBounds, AGetGlConfig: Integer);
  begin
    ARegistry.Register(AClearScene,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.ClearScene;
        Result := 0;
      end);
    ARegistry.Register(AAddRefEntity,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.AddRefEntityToScene(AMachine.Memory, AArgs[1]);
        Result := 0;
      end);
    ARegistry.Register(AAddPoly,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.AddPolyToScene(AMachine.Memory, AArgs[1], AArgs[2], AArgs[3], 1);
        Result := 0;
      end);
    Light(AAddLight, False);
    ARegistry.Register(ARenderScene,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.RenderScene(AMachine.Memory, AArgs[1]);
        Result := 0;
      end);
    ARegistry.Register(ASetColor,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.SetColor(AMachine.Memory, AArgs[1]);
        Result := 0;
      end);
    ARegistry.Register(ADrawStretchPic,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.DrawStretchPic(TQ3SyscallArguments.ToSingle(AArgs[1]), TQ3SyscallArguments.ToSingle(AArgs[2]),
          TQ3SyscallArguments.ToSingle(AArgs[3]), TQ3SyscallArguments.ToSingle(AArgs[4]),
          TQ3SyscallArguments.ToSingle(AArgs[5]), TQ3SyscallArguments.ToSingle(AArgs[6]),
          TQ3SyscallArguments.ToSingle(AArgs[7]), TQ3SyscallArguments.ToSingle(AArgs[8]), AArgs[9]);
        Result := 0;
      end);
    ARegistry.Register(AModelBounds,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARenderer.ModelBounds(AMachine.Memory, AArgs[1], AArgs[2], AArgs[3]);
        Result := 0;
      end);
    ARegistry.Register(AGetGlConfig,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AMachine.Memory.WriteBytes(AArgs[1], ARenderer.GlConfig);
        Result := 0;
      end);
  end;

begin
  case AModule of
    TQ3Module.CGame:
      begin
        Text(CG_R_LOADWORLDMAP, 'CG_R_LOADWORLDMAP',
          procedure(AName: AnsiString)
          begin
            ARenderer.LoadWorld(AName);
          end);
        Handle(CG_R_REGISTERMODEL, 'CG_R_REGISTERMODEL',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterModel(AName);
          end);
        Handle(CG_R_REGISTERSKIN, 'CG_R_REGISTERSKIN',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterSkin(AName);
          end);
        Handle(CG_R_REGISTERSHADER, 'CG_R_REGISTERSHADER',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterShader(AName);
          end);
        Handle(CG_R_REGISTERSHADERNOMIP, 'CG_R_REGISTERSHADERNOMIP',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterShaderNoMip(AName);
          end);
        // the fall through of the C: RegisterFont, then ClearScene
        ARegistry.Register(CG_R_REGISTERFONT,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ARenderer.RegisterFont(AMachine.Memory, TQ3SyscallArguments.Text(AMachine, AArgs[1], 'CG_R_REGISTERFONT'),
              AArgs[2], AArgs[3]);
            ARenderer.ClearScene;
            Result := 0;
          end);
        Common(CG_R_CLEARSCENE, CG_R_ADDREFENTITYTOSCENE, CG_R_ADDPOLYTOSCENE, CG_R_ADDLIGHTTOSCENE,
          CG_R_RENDERSCENE, CG_R_SETCOLOR, CG_R_DRAWSTRETCHPIC, CG_R_MODELBOUNDS, CG_GETGLCONFIG);
        ARegistry.Register(CG_R_ADDPOLYSTOSCENE,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ARenderer.AddPolyToScene(AMachine.Memory, AArgs[1], AArgs[2], AArgs[3], AArgs[4]);
            Result := 0;
          end);
        Light(CG_R_ADDADDITIVELIGHTTOSCENE, True);
        ARegistry.Register(CG_R_LIGHTFORPOINT,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ARenderer.LightForPoint(AMachine.Memory, ReadVec3(AMachine.Memory, AArgs[1]), AArgs[2],
              AArgs[3], AArgs[4]);
          end);
        ARegistry.Register(CG_R_LERPTAG,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ARenderer.LerpTag(AMachine.Memory, AArgs[1], AArgs[2], AArgs[3], AArgs[4],
              TQ3SyscallArguments.ToSingle(AArgs[5]), TQ3SyscallArguments.Text(AMachine, AArgs[6], 'CG_R_LERPTAG'));
          end);
        ARegistry.Register(CG_CM_MARKFRAGMENTS,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ARenderer.MarkFragments(AMachine.Memory, AArgs[1], AArgs[2], AArgs[3], AArgs[4], AArgs[5],
              AArgs[6], AArgs[7]);
          end);
        ARegistry.Register(CG_R_REMAP_SHADER,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ARenderer.RemapShader(OptionalText(AMachine.Memory, AArgs[1]), OptionalText(AMachine.Memory, AArgs[2]),
              OptionalText(AMachine.Memory, AArgs[3]));
            Result := 0;
          end);
        ARegistry.Register(CG_R_INPVS,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            Result := ARenderer.InPVS(ReadVec3(AMachine.Memory, AArgs[1]), ReadVec3(AMachine.Memory, AArgs[2]));
          end);
      end;
    TQ3Module.Ui:
      begin
        Handle(UI_R_REGISTERMODEL, 'UI_R_REGISTERMODEL',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterModel(AName);
          end);
        Handle(UI_R_REGISTERSKIN, 'UI_R_REGISTERSKIN',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterSkin(AName);
          end);
        Handle(UI_R_REGISTERSHADERNOMIP, 'UI_R_REGISTERSHADERNOMIP',
          function(AName: AnsiString): Integer
          begin
            Result := ARenderer.RegisterShaderNoMip(AName);
          end);
        ARegistry.Register(UI_R_REGISTERFONT,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ARenderer.RegisterFont(AMachine.Memory, TQ3SyscallArguments.Text(AMachine, AArgs[1], 'UI_R_REGISTERFONT'),
              AArgs[2], AArgs[3]);
            Result := 0;
          end);
        Common(UI_R_CLEARSCENE, UI_R_ADDREFENTITYTOSCENE, UI_R_ADDPOLYTOSCENE, UI_R_ADDLIGHTTOSCENE,
          UI_R_RENDERSCENE, UI_R_SETCOLOR, UI_R_DRAWSTRETCHPIC, UI_R_MODELBOUNDS, UI_GETGLCONFIG);
        ARegistry.Register(UI_CM_LERPTAG,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ARenderer.LerpTag(AMachine.Memory, AArgs[1], AArgs[2], AArgs[3], AArgs[4],
              TQ3SyscallArguments.ToSingle(AArgs[5]), TQ3SyscallArguments.Text(AMachine, AArgs[6], 'UI_CM_LERPTAG'));
            Result := 0;
          end);
        ARegistry.Register(UI_R_REMAP_SHADER,
          function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
          begin
            ARenderer.RemapShader(OptionalText(AMachine.Memory, AArgs[1]), OptionalText(AMachine.Memory, AArgs[2]),
              OptionalText(AMachine.Memory, AArgs[3]));
            Result := 0;
          end);
      end;
  end;
end;

end.
