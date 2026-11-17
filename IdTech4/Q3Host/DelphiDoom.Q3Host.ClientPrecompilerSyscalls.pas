{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the parser calls of cgame and ui        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c,      }
{  cl_ui.c and botlib\l_precomp.c (PC_LoadSourceHandle, PC_FreeSourceHandle,    }
{  PC_ReadTokenHandle, PC_SourceFileAndLine). Copyright (C) 1999-2005 Id        }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientPrecompilerSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Scanner.Q3.SourceHandles;

type
  /// <summary>
  ///   CG_PC_LOAD_SOURCE, FREE_SOURCE, READ_TOKEN, SOURCE_FILE_AND_LINE and the UI_PC_* twins, on the numbered
  ///   sources of the precompiler of botlib (TQ3SourceHandles of Framework\Scanner: the port of l_precomp.c, equal to
  ///   the C on its golden). The table of sources is the one of botlib and is shared with the bots, as in the C
  ///   (botlib_export): the BOTLIB_PC_* of qagame are registered on it too (TQ3BotFactory), with the same object. CG_PC_ADD_GLOBAL_DEFINE and UI_PC_ADD_GLOBAL_DEFINE are not served: the scanner has no
  ///   PC_DefineFromString and none of the twelve modules of OpenArena calls it
  /// </summary>
  TQ3PrecompilerSyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      ASources: TQ3SourceHandles); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Scanner.Q3.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Arguments;

class procedure TQ3PrecompilerSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  ASources: TQ3SourceHandles);
const
  LOAD: array[TQ3Module] of Integer = (BOTLIB_PC_LOAD_SOURCE, CG_PC_LOAD_SOURCE, UI_PC_LOAD_SOURCE);
  FREE: array[TQ3Module] of Integer = (BOTLIB_PC_FREE_SOURCE, CG_PC_FREE_SOURCE, UI_PC_FREE_SOURCE);
  READ: array[TQ3Module] of Integer = (BOTLIB_PC_READ_TOKEN, CG_PC_READ_TOKEN, UI_PC_READ_TOKEN);
  WHERE: array[TQ3Module] of Integer = (BOTLIB_PC_SOURCE_FILE_AND_LINE, CG_PC_SOURCE_FILE_AND_LINE, UI_PC_SOURCE_FILE_AND_LINE);
begin
  ARegistry.Register(LOAD[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := ASources.Load(TQ3SyscallArguments.Text(AMachine, AArgs[1], 'PC_LoadSource'));
    end);

  ARegistry.Register(FREE[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := Ord(ASources.Release(AArgs[1]));
    end);

  ARegistry.Register(READ[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LToken: TQ3PcToken;
      LFileName: AnsiString;
      LLine: Integer;
      LMemory: IQvmMemory;
    begin
      LMemory := AMachine.Memory;
      // a handle that is not open returns 0 and leaves the token alone
      if not ASources.SourceFileAndLine(AArgs[1], LFileName, LLine) then
        Exit(0);
      Result := Ord(ASources.ReadToken(AArgs[1], LToken));
      LMemory.WriteInt32(AArgs[2], LToken.TokenType);
      LMemory.WriteInt32(AArgs[2] + 4, LToken.Subtype);
      LMemory.WriteInt32(AArgs[2] + 8, LToken.IntValue);
      LMemory.WriteInt32(AArgs[2] + 12, TQ3SyscallArguments.FromSingle(LToken.FloatValue));
      // strcpy( pc_token->string, token.string ): the text and its zero, no more
      LMemory.WriteString(AArgs[2] + Q3_PCTOKEN_STRING, LToken.Text, Length(LToken.Text) + 1);
    end);

  ARegistry.Register(WHERE[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LFileName: AnsiString;
      LLine: Integer;
    begin
      if not ASources.SourceFileAndLine(AArgs[1], LFileName, LLine) then
        Exit(0);
      // strcpy( filename, ... ): no limit, as in the C
      AMachine.Memory.WriteString(AArgs[2], LFileName, Length(LFileName) + 1);
      AMachine.Memory.WriteInt32(AArgs[3], LLine);
      Result := 1;
    end);
end;

end.
