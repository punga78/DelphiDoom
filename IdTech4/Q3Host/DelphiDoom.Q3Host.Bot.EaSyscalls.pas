{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the BOTLIB_EA_* system calls (the      }
{  elementary actions of the bots)                                             }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  be_ea.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived     }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.EaSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Bot.Registrar;

type
  /// <summary>
  ///   The 27 calls of ea_export_t: the commands (say, command), the one button actions, EA_Move, EA_View,
  ///   EA_GetInput and EA_ResetInput. EA_EndRegular is an empty function in the library. <c>BOTLIB_EA_ACTION</c>
  ///   ends its case with <c>break</c> and the function with <c>return -1</c>: it answers -1, as the C does
  /// </summary>
  TQ3BotEaSyscalls = class
  public
    class procedure Register(const ARegistrar: TQ3BotRegistrar); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.BotAi.Ea.Intf, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Arguments, DelphiDoom.Q3Host.Bot.Memory;

type
  TClientAction = reference to procedure(const AActions: IBotElementaryActions; AClient: Integer);

class procedure TQ3BotEaSyscalls.Register(const ARegistrar: TQ3BotRegistrar);
  // a call with the client number only
  procedure ClientCall(ANumber: Integer; const AAction: TClientAction);
  begin
    ARegistrar.Add(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AAction(ARegistrar.Lib.Ai.Actions, AArgs[1]);
        Result := 0;
      end);
  end;

  // a call with the client number and a string
  procedure TextCall(ANumber: Integer; const AName: string;
    const AAction: TProc<IBotElementaryActions, Integer, AnsiString>);
  begin
    ARegistrar.Add(ANumber,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AAction(ARegistrar.Lib.Ai.Actions, AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2], AName));
        Result := 0;
      end);
  end;

begin
  TextCall(BOTLIB_EA_SAY, 'BOTLIB_EA_SAY',
    procedure(AActions: IBotElementaryActions; AClient: Integer; AText: AnsiString)
    begin
      AActions.Say(AClient, AText);
    end);
  TextCall(BOTLIB_EA_SAY_TEAM, 'BOTLIB_EA_SAY_TEAM',
    procedure(AActions: IBotElementaryActions; AClient: Integer; AText: AnsiString)
    begin
      AActions.SayTeam(AClient, AText);
    end);
  TextCall(BOTLIB_EA_COMMAND, 'BOTLIB_EA_COMMAND',
    procedure(AActions: IBotElementaryActions; AClient: Integer; AText: AnsiString)
    begin
      AActions.Command(AClient, AText);
    end);

  ARegistrar.Add(BOTLIB_EA_ACTION,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ARegistrar.Lib.Ai.Actions.Action(AArgs[1], AArgs[2]);
      // "break" leaves the switch, and the function ends with return -1
      Result := -1;
    end);

  ClientCall(BOTLIB_EA_GESTURE,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Gesture(AClient);
    end);
  ClientCall(BOTLIB_EA_TALK,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Talk(AClient);
    end);
  ClientCall(BOTLIB_EA_ATTACK,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Attack(AClient);
    end);
  ClientCall(BOTLIB_EA_USE,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Use(AClient);
    end);
  ClientCall(BOTLIB_EA_RESPAWN,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Respawn(AClient);
    end);
  ClientCall(BOTLIB_EA_CROUCH,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Crouch(AClient);
    end);
  ClientCall(BOTLIB_EA_MOVE_UP,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.MoveUp(AClient);
    end);
  ClientCall(BOTLIB_EA_MOVE_DOWN,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.MoveDown(AClient);
    end);
  ClientCall(BOTLIB_EA_MOVE_FORWARD,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.MoveForward(AClient);
    end);
  ClientCall(BOTLIB_EA_MOVE_BACK,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.MoveBack(AClient);
    end);
  ClientCall(BOTLIB_EA_MOVE_LEFT,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.MoveLeft(AClient);
    end);
  ClientCall(BOTLIB_EA_MOVE_RIGHT,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.MoveRight(AClient);
    end);
  ClientCall(BOTLIB_EA_JUMP,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.Jump(AClient);
    end);
  ClientCall(BOTLIB_EA_DELAYED_JUMP,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.DelayedJump(AClient);
    end);
  ClientCall(BOTLIB_EA_RESET_INPUT,
    procedure(const AActions: IBotElementaryActions; AClient: Integer)
    begin
      AActions.ResetInput(AClient);
    end);

  ARegistrar.Add(BOTLIB_EA_SELECT_WEAPON,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ARegistrar.Lib.Ai.Actions.SelectWeapon(AArgs[1], AArgs[2]);
      Result := 0;
    end);

  ARegistrar.Add(BOTLIB_EA_MOVE,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ARegistrar.Lib.Ai.Actions.Move(AArgs[1], TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]),
        TQ3SyscallArguments.ToSingle(AArgs[3]));
      Result := 0;
    end);

  ARegistrar.Add(BOTLIB_EA_VIEW,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      ARegistrar.Lib.Ai.Actions.View(AArgs[1], TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]));
      Result := 0;
    end);

  ARegistrar.Add(BOTLIB_EA_END_REGULAR,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      // EA_EndRegular( client, thinktime ) has an empty body in be_ea.c
      Result := 0;
    end);

  ARegistrar.Add(BOTLIB_EA_GET_INPUT,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      TQ3BotMemory.WriteInput(AMachine.Memory, AArgs[3],
        ARegistrar.Lib.Ai.Actions.GetInput(AArgs[1], TQ3SyscallArguments.ToSingle(AArgs[2])));
      Result := 0;
    end);
end;

end.
