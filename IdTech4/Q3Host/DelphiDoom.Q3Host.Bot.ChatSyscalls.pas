{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the BOTLIB_AI_* system calls of the    }
{  characters and of the chat                                                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c.      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.ChatSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Bot.Registrar;

type
  /// <summary>
  ///   BOTLIB_AI_LOAD_CHARACTER ... BOTLIB_AI_CHARACTERISTIC_STRING (be_ai_char.c) and the 20 chat calls
  ///   (be_ai_chat.c). The strings the C changes in place (UnifyWhiteSpaces, BotReplaceSynonyms) are written back
  ///   in a buffer of MAX_MESSAGE_SIZE (256) characters, the size every caller of the game gives them; the
  ///   <c>var0</c>..<c>var7</c> of a chat are NULL when the module has nothing for them
  /// </summary>
  TQ3BotChatSyscalls = class
  public
    class procedure Register(const ARegistrar: TQ3BotRegistrar); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Text,
  DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments, DelphiDoom.Q3Host.Bot.Memory;

// the eight pointers of the arguments from AFirst on: the ones that are not NULL are set
function ReadVariables(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments;
  AFirst: Integer): TBotChatVariables;
var
  LIndex: Integer;
begin
  Result := TBotChatVariables.None;
  for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
    if AArgs[AFirst + LIndex] <> 0 then
    begin
      Result.Items[LIndex].IsSet := True;
      Result.Items[LIndex].Text := AMachine.Memory.ReadString(AArgs[AFirst + LIndex]);
    end;
end;

class procedure TQ3BotChatSyscalls.Register(const ARegistrar: TQ3BotRegistrar);
  procedure RegisterCharacters;
  begin
    ARegistrar.Add(BOTLIB_AI_LOAD_CHARACTER,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Characters.LoadCharacter(TQ3SyscallArguments.Text(AMachine, AArgs[1],
          'BOTLIB_AI_LOAD_CHARACTER'), TQ3SyscallArguments.ToSingle(AArgs[2]));
      end);

    ARegistrar.Add(BOTLIB_AI_FREE_CHARACTER,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Characters.FreeCharacter(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_CHARACTERISTIC_FLOAT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := TQ3SyscallArguments.FromSingle(ARegistrar.Lib.Ai.Characters.CharacteristicFloat(AArgs[1],
          AArgs[2]));
      end);

    ARegistrar.Add(BOTLIB_AI_CHARACTERISTIC_BFLOAT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := TQ3SyscallArguments.FromSingle(ARegistrar.Lib.Ai.Characters.CharacteristicBoundedFloat(AArgs[1],
          AArgs[2], TQ3SyscallArguments.ToSingle(AArgs[3]), TQ3SyscallArguments.ToSingle(AArgs[4])));
      end);

    ARegistrar.Add(BOTLIB_AI_CHARACTERISTIC_INTEGER,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Characters.CharacteristicInteger(AArgs[1], AArgs[2]);
      end);

    ARegistrar.Add(BOTLIB_AI_CHARACTERISTIC_BINTEGER,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Characters.CharacteristicBoundedInteger(AArgs[1], AArgs[2], AArgs[3], AArgs[4]);
      end);

    ARegistrar.Add(BOTLIB_AI_CHARACTERISTIC_STRING,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LText: AnsiString;
      begin
        LText := ARegistrar.Lib.Ai.Characters.CharacteristicString(AArgs[1], AArgs[2], AArgs[4]);
        if AArgs[4] > 0 then
          AMachine.Memory.WriteString(AArgs[3], LText, AArgs[4]);
        Result := 0;
      end);
  end;

  procedure RegisterConsole;
  begin
    ARegistrar.Add(BOTLIB_AI_ALLOC_CHAT_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Chat.AllocChatState;
      end);

    ARegistrar.Add(BOTLIB_AI_FREE_CHAT_STATE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.FreeChatState(AArgs[1]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_QUEUE_CONSOLE_MESSAGE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.QueueConsoleMessage(AArgs[1], AArgs[2], TQ3SyscallArguments.Text(AMachine, AArgs[3],
          'BOTLIB_AI_QUEUE_CONSOLE_MESSAGE'));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_REMOVE_CONSOLE_MESSAGE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.RemoveConsoleMessage(AArgs[1], AArgs[2]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_NEXT_CONSOLE_MESSAGE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LMessage: TBotConsoleMessage;
      begin
        // the message is copied only when there is one
        Result := ARegistrar.Lib.Ai.Chat.NextConsoleMessage(AArgs[1], LMessage);
        if Result <> 0 then
          TQ3BotMemory.WriteConsoleMessage(AMachine.Memory, AArgs[2], LMessage);
      end);

    ARegistrar.Add(BOTLIB_AI_NUM_CONSOLE_MESSAGE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Chat.NumConsoleMessages(AArgs[1]);
      end);
  end;

  procedure RegisterChats;
  begin
    ARegistrar.Add(BOTLIB_AI_INITIAL_CHAT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.InitialChat(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_INITIAL_CHAT'), AArgs[3], ReadVariables(AMachine, AArgs, 4));
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_NUM_INITIAL_CHATS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Chat.NumInitialChats(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_NUM_INITIAL_CHATS'));
      end);

    ARegistrar.Add(BOTLIB_AI_REPLY_CHAT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := Ord(ARegistrar.Lib.Ai.Chat.ReplyChat(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_REPLY_CHAT'), AArgs[3], AArgs[4], ReadVariables(AMachine, AArgs, 5)));
      end);

    ARegistrar.Add(BOTLIB_AI_CHAT_LENGTH,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Chat.ChatLength(AArgs[1]);
      end);

    ARegistrar.Add(BOTLIB_AI_ENTER_CHAT,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.EnterChat(AArgs[1], AArgs[2], AArgs[3]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_GET_CHAT_MESSAGE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LText: AnsiString;
      begin
        LText := ARegistrar.Lib.Ai.Chat.GetChatMessage(AArgs[1], AArgs[3]);
        if AArgs[3] > 0 then
          AMachine.Memory.WriteString(AArgs[2], LText, AArgs[3]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_LOAD_CHAT_FILE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := ARegistrar.Lib.Ai.Chat.LoadChatFile(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_LOAD_CHAT_FILE'), TQ3SyscallArguments.Text(AMachine, AArgs[3], 'BOTLIB_AI_LOAD_CHAT_FILE'));
      end);

    ARegistrar.Add(BOTLIB_AI_SET_CHAT_GENDER,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.SetChatGender(AArgs[1], AArgs[2]);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_SET_CHAT_NAME,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        ARegistrar.Lib.Ai.Chat.SetChatName(AArgs[1], TQ3SyscallArguments.Text(AMachine, AArgs[2],
          'BOTLIB_AI_SET_CHAT_NAME'), AArgs[3]);
        Result := 0;
      end);
  end;

  procedure RegisterMatches;
  begin
    ARegistrar.Add(BOTLIB_AI_STRING_CONTAINS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        Result := TBotChatText.StringContains(TQ3SyscallArguments.Text(AMachine, AArgs[1],
          'BOTLIB_AI_STRING_CONTAINS'), TQ3SyscallArguments.Text(AMachine, AArgs[2], 'BOTLIB_AI_STRING_CONTAINS'),
          AArgs[3] <> 0);
      end);

    ARegistrar.Add(BOTLIB_AI_FIND_MATCH,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LMatch: TBotMatch;
      begin
        // the match is read, changed and written back: the fields the C does not touch keep what the module put
        LMatch := TQ3BotMemory.ReadMatch(AMachine.Memory, AArgs[2]);
        Result := Ord(ARegistrar.Lib.Ai.Chat.FindMatch(TQ3SyscallArguments.Text(AMachine, AArgs[1],
          'BOTLIB_AI_FIND_MATCH'), LMatch, Cardinal(AArgs[3])));
        TQ3BotMemory.WriteMatch(AMachine.Memory, AArgs[2], LMatch);
      end);

    ARegistrar.Add(BOTLIB_AI_MATCH_VARIABLE,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LText: AnsiString;
      begin
        LText := ARegistrar.Lib.Ai.Chat.MatchVariable(TQ3BotMemory.ReadMatch(AMachine.Memory, AArgs[1]), AArgs[2],
          AArgs[4]);
        if AArgs[4] > 0 then
          AMachine.Memory.WriteString(AArgs[3], LText, AArgs[4])
        else
          AMachine.Memory.WriteByte(AArgs[3], 0);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_UNIFY_WHITE_SPACES,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AMachine.Memory.WriteString(AArgs[1], TBotChatText.UnifyWhiteSpaces(TQ3SyscallArguments.Text(AMachine,
          AArgs[1], 'BOTLIB_AI_UNIFY_WHITE_SPACES')), TQ3BotMemory.MAX_MESSAGE_SIZE);
        Result := 0;
      end);

    ARegistrar.Add(BOTLIB_AI_REPLACE_SYNONYMS,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      begin
        AMachine.Memory.WriteString(AArgs[1], ARegistrar.Lib.Ai.Chat.ReplaceSynonyms(
          TQ3SyscallArguments.Text(AMachine, AArgs[1], 'BOTLIB_AI_REPLACE_SYNONYMS'), Cardinal(AArgs[2])),
          TQ3BotMemory.MAX_MESSAGE_SIZE);
        Result := 0;
      end);
  end;

begin
  RegisterCharacters;
  RegisterConsole;
  RegisterChats;
  RegisterMatches;
end;

end.
