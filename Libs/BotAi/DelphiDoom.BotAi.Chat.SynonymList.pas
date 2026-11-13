{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotSynonymList, a list of synonyms of a context       }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_synonymlist_t,  }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.SynonymList;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.Types;

type
  /// <summary>
  ///   Words with the same meaning for the contexts (a bit mask); the first one is the replacement
  ///   of the others, the weights drive the random choice.
  /// </summary>
  TBotSynonymList = class
  strict private
    FContext: Cardinal;
    FTotalWeight: Single;
    FSynonyms: TList<TBotSynonym>;
  public
    constructor Create(const AContext: Cardinal);
    destructor Destroy; override;
    procedure Add(const AText: AnsiString; const AWeight: Single);
    property Context: Cardinal read FContext;
    property TotalWeight: Single read FTotalWeight;
    property Synonyms: TList<TBotSynonym> read FSynonyms;
  end;

implementation

{ TBotSynonymList }

constructor TBotSynonymList.Create(const AContext: Cardinal);
begin
  inherited Create;
  FContext := AContext;
  FSynonyms := TList<TBotSynonym>.Create;
end;

destructor TBotSynonymList.Destroy;
begin
  FSynonyms.Free;
  inherited Destroy;
end;

procedure TBotSynonymList.Add(const AText: AnsiString; const AWeight: Single);
var
  LSynonym: TBotSynonym;
begin
  LSynonym.Text := AText;
  LSynonym.Weight := AWeight;
  FSynonyms.Add(LSynonym);
  FTotalWeight := FTotalWeight + AWeight;
end;

end.
