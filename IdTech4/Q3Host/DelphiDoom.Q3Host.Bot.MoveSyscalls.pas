{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the BOTLIB_AI_* system calls of the    }
{  movement, the weapons and the genetic selection                             }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c.      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.MoveSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Bot.Registrar;

type
  /// <summary>
  ///   The 14 movement calls (be_ai_move.c: bot_moveresult_t, bot_initmove_t), the 6 weapon calls (be_ai_weap.c:
  ///   weaponinfo_t, 552 bytes) and the genetic selection (be_ai_gen.c). A target or a weapon info is written only
  ///   where the C writes it
  /// </summary>
  TQ3BotMoveSyscalls = class
  public
    class procedure Register(const ARegistrar: TQ3BotRegistrar); static;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Goal.Types,
  DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Weapon.Types, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments,
  DelphiDoom.Q3Host.Bot.Memory;

const
  // GeneticParentsAndChildSelection refuses more ranks than this
  MAX_RANKS = 256;

class procedure TQ3BotMoveSyscalls.Register(const ARegistrar: TQ3BotRegistrar);
  procedure RegisterStates;
  begin
    ARegistrar.Add(BOTLIB_AI_RESET_MOVE_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Moves.ResetMoveState(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_ALLOC_MOVE_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Moves.AllocMoveState;
      end);

    ARegistrar.Add(BOTLIB_AI_FREE_MOVE_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Moves.FreeMoveState(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_INIT_MOVE_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Moves.InitMoveState(AArgs[1], TQ3BotMemory.ReadInitMove(AMachine.Memory, AArgs[2]));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_RESET_AVOID_REACH,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Moves.ResetAvoidReach(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_RESET_LAST_AVOID_REACH,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Moves.ResetLastAvoidReach(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_ADD_AVOID_SPOT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Moves.AddAvoidSpot(AArgs[1], TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[2]),
          TQ3SyscallArguments.ToSingle(AArgs[3]), AArgs[4]);
        Result := 0;
      end);
  end;

  procedure RegisterMoves;
  begin
    ARegistrar.Add(BOTLIB_AI_MOVE_TO_GOAL,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
      begin
        LGoal := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[3]);
        TQ3BotMemory.WriteMoveResult(AMachine.Memory, AArgs[1], ARegistrar.Lib.Ai.Moves.MoveToGoal(AArgs[2], @LGoal,
          AArgs[4]));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_MOVE_IN_DIRECTION,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Ai.Moves.MoveInDirection(AArgs[1], TQ3BotMemory.ReadVec3(AMachine.Memory,
          AArgs[2]), TQ3SyscallArguments.ToSingle(AArgs[3]), AArgs[4]));
      end);

    ARegistrar.Add(BOTLIB_AI_REACHABILITY_AREA,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Moves.ReachabilityArea(TQ3BotMemory.ReadVec3(AMachine.Memory, AArgs[1]),
          AArgs[2]);
      end);

    ARegistrar.Add(BOTLIB_AI_MOVEMENT_VIEW_TARGET,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
        LTarget: TVec3;
      begin
        LGoal := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[2]);
        Result := Ord(ARegistrar.Lib.Ai.Moves.MovementViewTarget(AArgs[1], @LGoal, AArgs[3],
          TQ3SyscallArguments.ToSingle(AArgs[4]), LTarget));
        if Result <> 0 then
          TQ3BotMemory.WriteVec3(AMachine.Memory, AArgs[5], LTarget);
      end);

    ARegistrar.Add(BOTLIB_AI_PREDICT_VISIBLE_POSITION,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LGoal: TBotGoal;
        LTarget: TVec3;
      begin
        LGoal := TQ3BotMemory.ReadGoal(AMachine.Memory, AArgs[3]);
        Result := Ord(ARegistrar.Lib.Ai.Moves.PredictVisiblePosition(TQ3BotMemory.ReadVec3(AMachine.Memory,
          AArgs[1]), AArgs[2], @LGoal, AArgs[4], LTarget));
        if Result <> 0 then
          TQ3BotMemory.WriteVec3(AMachine.Memory, AArgs[5], LTarget);
      end);
  end;

  procedure RegisterWeapons;
  begin
    ARegistrar.Add(BOTLIB_AI_CHOOSE_BEST_FIGHT_WEAPON,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Weapons.ChooseBestFightWeapon(AArgs[1], TQ3BotMemory.ReadInventory(AMachine.Memory,
          AArgs[2]));
      end);

    ARegistrar.Add(BOTLIB_AI_GET_WEAPON_INFO,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LInfo: TBotWeaponInfo;
      begin
        // not written for a weapon or a state that does not exist
        if ARegistrar.Lib.Ai.Weapons.GetWeaponInfo(AArgs[1], AArgs[2], LInfo) then
          TQ3BotMemory.WriteWeaponInfo(AMachine.Memory, AArgs[3], LInfo);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_LOAD_WEAPON_WEIGHTS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Weapons.LoadWeaponWeights(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_LOAD_WEAPON_WEIGHTS'));
      end);

    ARegistrar.Add(BOTLIB_AI_ALLOC_WEAPON_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Weapons.AllocWeaponState;
      end);

    ARegistrar.Add(BOTLIB_AI_FREE_WEAPON_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Weapons.FreeWeaponState(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_RESET_WEAPON_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Weapons.ResetWeaponState(AArgs[1]);
        Result := 0;
      end);
  end;

  procedure RegisterGenetics;
  begin
    ARegistrar.Add(BOTLIB_AI_GENETIC_PARENTS_AND_CHILD_SELECTION,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LRanks: TArray<Single>;
        LIndex, LParent1, LParent2, LChild: Integer;
        LAddress: Integer;
      begin
        LParent1 := 0;
        LParent2 := 0;
        LChild := 0;
        LRanks := nil;
        // more than MAX_RANKS: the library refuses before it reads them (the array only has the length)
        SetLength(LRanks, Integer(Min(Max(AArgs[1], 0), MAX_RANKS + 1)));
        if AArgs[1] <= MAX_RANKS then
        begin
          LAddress := AArgs[2];
          for LIndex := 0 to Length(LRanks) - 1 do
            LRanks[LIndex] := TQ3BotMemory.Float(AMachine.Memory.ReadInt32(LAddress + 4 * LIndex));
        end;
        Result := Ord(ARegistrar.Lib.Ai.Genetics.ParentsAndChildSelection(LRanks, LParent1, LParent2, LChild));
        // the three numbers are always written (zeros when the library refuses)
        AMachine.Memory.WriteInt32(AArgs[3], LParent1);
        AMachine.Memory.WriteInt32(AArgs[4], LParent2);
        AMachine.Memory.WriteInt32(AArgs[5], LChild);
      end);
  end;

begin
  RegisterStates;
  RegisterMoves;
  RegisterWeapons;
  RegisterGenetics;
end;

end.
