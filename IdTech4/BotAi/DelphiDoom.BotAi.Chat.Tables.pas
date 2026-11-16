{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatTables, what BotSetupChatAI loads              }
{                                                                              }
{  Replaces the globals synonyms, randomstrings, matchtemplates and replychats }
{  of code\botlib\be_ai_chat.c (Quake III Arena, id Software, GPL v2 or later).}
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Tables;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.SynonymList,
  DelphiDoom.BotAi.Chat.RandomList, DelphiDoom.BotAi.Chat.ReplyChat;

type
  /// <summary>The synonyms, random strings, match templates and reply chats shared by all the chat states</summary>
  TBotChatTables = class
  strict private
    FSynonyms: TObjectList<TBotSynonymList>;
    FRandomLists: TObjectList<TBotRandomList>;
    FTemplates: TList<TBotMatchTemplate>;
    FReplyChats: TObjectList<TBotReplyChat>;
  public
    constructor Create;
    destructor Destroy; override;
    property Synonyms: TObjectList<TBotSynonymList> read FSynonyms;
    property RandomLists: TObjectList<TBotRandomList> read FRandomLists;
    property Templates: TList<TBotMatchTemplate> read FTemplates;
    property ReplyChats: TObjectList<TBotReplyChat> read FReplyChats;
  end;

implementation

{ TBotChatTables }

constructor TBotChatTables.Create;
begin
  inherited Create;
  FSynonyms := TObjectList<TBotSynonymList>.Create(True);
  FRandomLists := TObjectList<TBotRandomList>.Create(True);
  FTemplates := TList<TBotMatchTemplate>.Create;
  FReplyChats := TObjectList<TBotReplyChat>.Create(True);
end;

destructor TBotChatTables.Destroy;
begin
  FReplyChats.Free;
  FTemplates.Free;
  FRandomLists.Free;
  FSynonyms.Free;
  inherited Destroy;
end;

end.
