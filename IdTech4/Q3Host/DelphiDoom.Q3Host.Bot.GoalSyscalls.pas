{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the BOTLIB_AI_* system calls of the    }
{  goals (be_ai_goal.c)                                                        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c.      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.GoalSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Bot.Registrar;

type
  /// <summary>
  ///   The 33 goal calls: the avoid goals and the goal stack, the choice of the long term and nearby items, the
  ///   level items and camp spots, the item weights and the genetic operators on them. A goal is a bot_goal_t of 56
  ///   bytes; it is written only where the C writes it (a top goal that does not exist, an item that is not found
  ///   leave the module's structure as it was). The inventory is the MAX_ITEMS (256) integers of the game
  /// </summary>
  TQ3BotGoalSyscalls = class
  public
    class procedure Register(const ARegistrar: TQ3BotRegistrar); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.MathCore.Types,
  DelphiDoom.BotAi.Goal.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Arguments, DelphiDoom.Q3Host.Bot.Memory;

class procedure TQ3BotGoalSyscalls.Register(const ARegistrar: TQ3BotRegistrar);
  procedure RegisterStacks;
  begin
    ARegistrar.Add(BOTLIB_AI_RESET_GOAL_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.ResetGoalState(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_RESET_AVOID_GOALS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.ResetAvoidGoals(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_REMOVE_FROM_AVOID_GOALS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.RemoveFromAvoidGoals(AArgs[1], AArgs[2]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_PUSH_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.PushGoal(AArgs[1], TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[2]));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_POP_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.PopGoal(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_EMPTY_GOAL_STACK,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.EmptyGoalStack(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_DUMP_AVOID_GOALS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.DumpAvoidGoals(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_DUMP_GOAL_STACK,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.DumpGoalStack(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_GOAL_NAME,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LName: AnsiString;
      begin
        LName := ARegistrar.Lib.Ai.Goals.GoalName(AArgs[1], AArgs[3]);
        if AArgs[3] > 0 then
          AMachine.Memory.WriteString(AArgs[2], LName, AArgs[3]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_GET_TOP_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
      begin
        Result := Ord(ARegistrar.Lib.Ai.Goals.GetTopGoal(AArgs[1], LGoal));
        if Result <> 0 then
          TQ3BotMemory.WriteGoal(AMachine.Memory, AArgs[2], LGoal);
      end);

    ARegistrar.Add(BOTLIB_AI_GET_SECOND_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
      begin
        Result := Ord(ARegistrar.Lib.Ai.Goals.GetSecondGoal(AArgs[1], LGoal));
        if Result <> 0 then
          TQ3BotMemory.WriteGoal(AMachine.Memory, AArgs[2], LGoal);
      end);

    ARegistrar.Add(BOTLIB_AI_AVOID_GOAL_TIME,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := TQ3SyscallArguments.FromSingle(ARegistrar.Lib.Ai.Goals.AvoidGoalTime(AArgs[1], AArgs[2]));
      end);

    ARegistrar.Add(BOTLIB_AI_SET_AVOID_GOAL_TIME,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.SetAvoidGoalTime(AArgs[1], AArgs[2], TQ3SyscallArguments.ToSingle(AArgs[3]));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_ALLOC_GOAL_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Goals.AllocGoalState(AArgs[1]);
      end);

    ARegistrar.Add(BOTLIB_AI_FREE_GOAL_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.FreeGoalState(AArgs[1]);
        Result := 0;
      end);
  end;

  procedure RegisterChoices;
  begin
    ARegistrar.Add(BOTLIB_AI_CHOOSE_LTG_ITEM,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Ai.Goals.ChooseLTGItem(AArgs[1], TQ3BotMemory.ReadVec3(AMachine.Memory,
          AArgs[2]), TQ3BotMemory.ReadInventory(AMachine.Memory, AArgs[3]), AArgs[4]));
      end);

    ARegistrar.Add(BOTLIB_AI_CHOOSE_NBG_ITEM,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LLtg: TBotGoal;
        LOrigin: TVec3;
      begin
        // the long term goal may be NULL
        LOrigin := TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]);
        if AArgs[5] = 0 then
          Exit(Ord(ARegistrar.Lib.Ai.Goals.ChooseNBGItem(AArgs[1], LOrigin,
            TQ3BotMemory.ReadInventory(AMachine.Memory, AArgs[3]), AArgs[4], nil,
            TQ3SyscallArguments.ToSingle(AArgs[6]))));
        LLtg := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[5]);
        Result := Ord(ARegistrar.Lib.Ai.Goals.ChooseNBGItem(AArgs[1], LOrigin,
          TQ3BotMemory.ReadInventory(AMachine.Memory, AArgs[3]), AArgs[4], @LLtg,
          TQ3SyscallArguments.ToSingle(AArgs[6])));
      end);

    ARegistrar.Add(BOTLIB_AI_TOUCHING_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Ai.Goals.TouchingGoal(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]),
          TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[2])));
      end);

    ARegistrar.Add(BOTLIB_AI_ITEM_GOAL_IN_VIS_BUT_NOT_VISIBLE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Ai.Goals.ItemGoalInVisButNotVisible(AArgs[1],
          TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]), TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[3]),
          TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[4])));
      end);
  end;

  procedure RegisterLevel;
  begin
    ARegistrar.Add(BOTLIB_AI_GET_LEVEL_ITEM_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
      begin
        LGoal := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[3]);
        Result := ARegistrar.Lib.Ai.Goals.GetLevelItemGoal(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_GET_LEVEL_ITEM_GOAL'), LGoal);
        // -1: no item, the goal is as the module had it
        if Result >= 0 then
          TQ3BotMemory.WriteGoal(AMachine.Memory, AArgs[3], LGoal);
      end);

    ARegistrar.Add(BOTLIB_AI_GET_NEXT_CAMP_SPOT_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
      begin
        LGoal := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[2]);
        Result := ARegistrar.Lib.Ai.Goals.GetNextCampSpotGoal(AArgs[1], LGoal);
        if Result <> 0 then
          TQ3BotMemory.WriteGoal(AMachine.Memory, AArgs[2], LGoal);
      end);

    ARegistrar.Add(BOTLIB_AI_GET_MAP_LOCATION_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
      begin
        LGoal := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[2]);
        Result := Ord(ARegistrar.Lib.Ai.Goals.GetMapLocationGoal(TQ3SyscallArguments.Text(AMachine, AArgs[1],
          'BOTLIB_AI_GET_MAP_LOCATION_GOAL'), LGoal));
        if Result <> 0 then
          TQ3BotMemory.WriteGoal(AMachine.Memory, AArgs[2], LGoal);
      end);

    ARegistrar.Add(BOTLIB_AI_INIT_LEVEL_ITEMS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.InitLevelItems;
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_UPDATE_ENTITY_ITEMS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.UpdateEntityItems;
        Result := 0;
      end);
  end;

  procedure RegisterWeights;
  begin
    ARegistrar.Add(BOTLIB_AI_LOAD_ITEM_WEIGHTS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Goals.LoadItemWeights(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_LOAD_ITEM_WEIGHTS'));
      end);

    ARegistrar.Add(BOTLIB_AI_FREE_ITEM_WEIGHTS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.FreeItemWeights(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_INTERBREED_GOAL_FUZZY_LOGIC,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.InterbreedGoalFuzzyLogic(AArgs[1], AArgs[2], AArgs[3]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_SAVE_GOAL_FUZZY_LOGIC,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.SaveGoalFuzzyLogic(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_SAVE_GOAL_FUZZY_LOGIC'));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_MUTATE_GOAL_FUZZY_LOGIC,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Goals.MutateGoalFuzzyLogic(AArgs[1], TQ3SyscallArguments.ToSingle(AArgs[2]));
        Result := 0;
      end);
  end;

begin
  RegisterStacks;
  RegisterChoices;
  RegisterLevel;
  RegisterWeights;
end;

end.
