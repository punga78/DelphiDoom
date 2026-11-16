{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatIntegrityChecker, BotCheckChatMessageIntegrety }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.IntegrityChecker;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.RandomStrings,
  DelphiDoom.BotAi.Chat.Chat, DelphiDoom.BotAi.Chat.ReplyChat;

type
  /// <summary>
  ///   The check of the developer mode: every random string a message names must exist; each
  ///   missing one is written once to the log as a line to add to the random string file.
  /// </summary>
  TBotChatIntegrityChecker = class
  strict private
    FImport: IBotImport;
    FRandomStrings: TBotRandomStrings;
    procedure CheckMessage(const AMessage: AnsiString; const AMissing: TList<AnsiString>);
  public
    constructor Create(const AImport: IBotImport; const ARandomStrings: TBotRandomStrings);
    /// <summary>BotCheckInitialChatIntegrety</summary>
    procedure CheckInitialChat(const AChat: TBotChat);
    /// <summary>BotCheckReplyChatIntegrety</summary>
    procedure CheckReplyChats(const AReplyChats: TObjectList<TBotReplyChat>);
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.ChatType, DelphiDoom.BotAi.Chat.Message;

{ TBotChatIntegrityChecker }

constructor TBotChatIntegrityChecker.Create(const AImport: IBotImport; const ARandomStrings: TBotRandomStrings);
begin
  inherited Create;
  FImport := AImport;
  FRandomStrings := ARandomStrings;
end;

procedure TBotChatIntegrityChecker.CheckMessage(const AMessage: AnsiString; const AMissing: TList<AnsiString>);
var
  LPosition: Integer;
  LName: AnsiString;
  LText: AnsiString;
begin
  LPosition := 1;
  while LPosition <= Length(AMessage) do
  begin
    if AMessage[LPosition] = ESCAPE_CHAR then
    begin
      Inc(LPosition);
      if (LPosition <= Length(AMessage)) and (AMessage[LPosition] = 'v') then
      begin
        Inc(LPosition);
        while (LPosition <= Length(AMessage)) and (AMessage[LPosition] <> ESCAPE_CHAR) do
          Inc(LPosition);
        if LPosition <= Length(AMessage) then
          Inc(LPosition);
      end
      else if (LPosition <= Length(AMessage)) and (AMessage[LPosition] = 'r') then
      begin
        Inc(LPosition);
        LName := '';
        while (LPosition <= Length(AMessage)) and (AMessage[LPosition] <> ESCAPE_CHAR) do
        begin
          LName := LName + AMessage[LPosition];
          Inc(LPosition);
        end;
        if LPosition <= Length(AMessage) then
          Inc(LPosition);
        if not FRandomStrings.TryChoose(LName, LText) then
        begin
          if not AMissing.Contains(LName) then
          begin
            FImport.LogWrite(LName + ' = {"' + LName + '"} //MISSING RANDOM'#13#10);
            AMissing.Insert(0, LName);
          end;
        end;
      end
      else
        FImport.Print(PRT_FATAL, 'BotCheckChatMessageIntegrety: message "' + AMessage + '" invalid escape char'#10);
    end
    else
      Inc(LPosition);
  end;
end;

procedure TBotChatIntegrityChecker.CheckInitialChat(const AChat: TBotChat);
var
  LMissing: TList<AnsiString>;
  LType: TBotChatType;
  LMessage: TBotChatMessage;
begin
  LMissing := TList<AnsiString>.Create;
  try
    for LType in AChat.Types do
      for LMessage in LType.Messages do
        CheckMessage(LMessage.Text, LMissing);
  finally
    LMissing.Free;
  end;
end;

procedure TBotChatIntegrityChecker.CheckReplyChats(const AReplyChats: TObjectList<TBotReplyChat>);
var
  LMissing: TList<AnsiString>;
  LReply: TBotReplyChat;
  LMessage: TBotChatMessage;
begin
  LMissing := TList<AnsiString>.Create;
  try
    for LReply in AReplyChats do
      for LMessage in LReply.Messages do
        CheckMessage(LMessage.Text, LMissing);
  finally
    LMissing.Free;
  end;
end;

end.
