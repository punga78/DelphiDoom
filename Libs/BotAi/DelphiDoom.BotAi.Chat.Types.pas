{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - types and constants of the chat                        }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c and code\game\be_ai_chat.h. Based on the Quake III Arena GPL   }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_MESSAGE_SIZE: the size of a message with the terminating zero</summary>
  MAX_MESSAGE_SIZE = 256;
  MAX_CHATTYPE_NAME = 32;
  MAX_MATCHVARIABLES = 8;

  CHAT_GENDERLESS = 0;
  CHAT_GENDERFEMALE = 1;
  CHAT_GENDERMALE = 2;

  CHAT_ALL = 0;
  CHAT_TEAM = 1;
  CHAT_TELL = 2;

  /// <summary>ESCAPE_CHAR: marks a variable (v) or a random string (r) in a compiled message</summary>
  ESCAPE_CHAR = #1;

  MT_VARIABLE = 1;
  MT_STRING = 2;

  RCKFL_AND = 1;
  RCKFL_NOT = 2;
  RCKFL_NAME = 4;
  RCKFL_STRING = 8;
  RCKFL_VARIABLES = 16;
  RCKFL_BOTNAMES = 32;
  RCKFL_GENDERFEMALE = 64;
  RCKFL_GENDERMALE = 128;
  RCKFL_GENDERLESS = 256;

  /// <summary>CHATMESSAGE_RECENTTIME: seconds a message is not used again after it was</summary>
  CHATMESSAGE_RECENTTIME = 20;

type
  /// <summary>bot_matchvariable_t; the offset is a signed char in the original, so one of 128 or more wraps</summary>
  TBotMatchVariable = record
    Offset: ShortInt;
    Length: Integer;
  end;

  /// <summary>
  ///   bot_match_t: what a match template found in a message. The text holds at most
  ///   MAX_MESSAGE_SIZE - 1 characters (the original overflows its buffer with more).
  /// </summary>
  TBotMatch = record
    Text: AnsiString;
    MatchType: Integer;
    SubType: Integer;
    Variables: array[0..MAX_MATCHVARIABLES - 1] of TBotMatchVariable;
  end;

  /// <summary>The characters of a chat message of the state (chatmessage[MAX_MESSAGE_SIZE]) as the original keeps them</summary>
  TBotMessageBuffer = array[0..MAX_MESSAGE_SIZE - 1] of AnsiChar;

  PBotMessageBuffer = ^TBotMessageBuffer;

  /// <summary>bot_consolemessage_t</summary>
  TBotConsoleMessage = record
    Handle: Integer;
    Time: Single;
    MessageType: Integer;
    Text: AnsiString;
  end;

  /// <summary>A variable text the game gives to BotInitialChat and BotReplyChat: a null pointer in the original is not set</summary>
  TBotChatVariable = record
    IsSet: Boolean;
    Text: AnsiString;
  end;

  /// <summary>The eight variables (var0..var7) of BotInitialChat and BotReplyChat</summary>
  TBotChatVariables = record
    Items: array[0..MAX_MATCHVARIABLES - 1] of TBotChatVariable;
    /// <summary>All null pointers</summary>
    class function None: TBotChatVariables; static;
    /// <summary>The first variables set to the texts, the others null</summary>
    class function FromTexts(const ATexts: array of AnsiString): TBotChatVariables; static;
  end;

  /// <summary>bot_synonym_t</summary>
  TBotSynonym = record
    Text: AnsiString;
    Weight: Single;
  end;

  /// <summary>bot_matchpiece_t: a variable or the alternative strings of a piece of a match template</summary>
  TBotMatchPiece = record
    PieceType: Integer;
    Strings: TArray<AnsiString>;
    Variable: Integer;
  end;

  TBotMatchPieces = TArray<TBotMatchPiece>;

  /// <summary>bot_matchtemplate_t</summary>
  TBotMatchTemplate = record
    Context: Cardinal;
    MatchType: Integer;
    SubType: Integer;
    Pieces: TBotMatchPieces;
  end;

  /// <summary>bot_replychatkey_t</summary>
  TBotReplyChatKey = record
    Flags: Integer;
    Text: AnsiString;
    Match: TBotMatchPieces;
  end;

  /// <summary>
  ///   A file of the bots could not be read: the problem was already reported to botimport.Print
  ///   (as the original does) and the loading stops, as the original returned NULL.
  /// </summary>
  EBotChatParseException = class(Exception)
  strict private
    FFileName: string;
    FLine: Integer;
  public
    constructor Create(const AMessage, AFileName: string; const ALine: Integer);
    property FileName: string read FFileName;
    property Line: Integer read FLine;
  end;

implementation

{ TBotChatVariables }

class function TBotChatVariables.None: TBotChatVariables;
begin
  Result := Default(TBotChatVariables);
end;

class function TBotChatVariables.FromTexts(const ATexts: array of AnsiString): TBotChatVariables;
var
  LIndex: Integer;
begin
  Result := Default(TBotChatVariables);
  for LIndex := 0 to High(ATexts) do
  begin
    if LIndex >= MAX_MATCHVARIABLES then
      Break;
    Result.Items[LIndex].IsSet := True;
    Result.Items[LIndex].Text := ATexts[LIndex];
  end;
end;

{ EBotChatParseException }

constructor EBotChatParseException.Create(const AMessage, AFileName: string; const ALine: Integer);
begin
  inherited Create(AMessage);
  FFileName := AFileName;
  FLine := ALine;
end;

end.
