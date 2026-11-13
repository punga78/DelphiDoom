{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotSynonymReplacer, BotReplaceSynonyms,               }
{  BotReplaceWeightedSynonyms and BotReplaceReplySynonyms                      }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.SynonymReplacer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Tables;

type
  /// <summary>Replaces the words of a text with their synonyms for a context (a bit mask)</summary>
  TBotSynonymReplacer = class
  strict private
    FTables: TBotChatTables;
    FRandom: IBotRandom;
  public
    constructor Create(const ATables: TBotChatTables; const ARandom: IBotRandom);
    /// <summary>BotReplaceSynonyms: every other synonym of a list becomes the first</summary>
    function ReplaceSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    /// <summary>BotReplaceWeightedSynonyms: all the synonyms of a list become one chosen by weight</summary>
    function ReplaceWeightedSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
    /// <summary>BotReplaceReplySynonyms: only the words at the start of a word of the text, once each</summary>
    function ReplaceReplySynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
  end;

implementation

uses
  DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.SynonymList, DelphiDoom.BotAi.Chat.Text;

{ TBotSynonymReplacer }

constructor TBotSynonymReplacer.Create(const ATables: TBotChatTables; const ARandom: IBotRandom);
begin
  inherited Create;
  FTables := ATables;
  FRandom := ARandom;
end;

function TBotSynonymReplacer.ReplaceSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
var
  LList: TBotSynonymList;
  LIndex: Integer;
begin
  Result := AText;
  for LList in FTables.Synonyms do
  begin
    if (LList.Context and AContext) = 0 then
      Continue;
    for LIndex := 1 to LList.Synonyms.Count - 1 do
      Result := TBotChatText.ReplaceWords(Result, LList.Synonyms[LIndex].Text, LList.Synonyms[0].Text);
  end;
end;

function TBotSynonymReplacer.ReplaceWeightedSynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
var
  LList: TBotSynonymList;
  LWeight: Single;
  LCurrent: Single;
  LReplacement: Integer;
  LIndex: Integer;
begin
  Result := AText;
  for LList in FTables.Synonyms do
  begin
    if (LList.Context and AContext) = 0 then
      Continue;
    // choose a weighted random replacement synonym
    LWeight := FRandom.NextFloat * LList.TotalWeight;
    if LWeight = 0 then
      Continue;
    LCurrent := 0;
    LReplacement := -1;
    for LIndex := 0 to LList.Synonyms.Count - 1 do
    begin
      LCurrent := LCurrent + LList.Synonyms[LIndex].Weight;
      if LWeight < LCurrent then
      begin
        LReplacement := LIndex;
        Break;
      end;
    end;
    if LReplacement < 0 then
      Continue;
    // replace all synonyms with the replacement
    for LIndex := 0 to LList.Synonyms.Count - 1 do
    begin
      if LIndex = LReplacement then
        Continue;
      Result := TBotChatText.ReplaceWords(Result, LList.Synonyms[LIndex].Text, LList.Synonyms[LReplacement].Text);
    end;
  end;
end;

function TBotSynonymReplacer.ReplaceReplySynonyms(const AText: AnsiString; const AContext: Cardinal): AnsiString;
var
  LPosition: Integer;
  LList: TBotSynonymList;
  LIndex: Integer;
  LReplacement: AnsiString;
  LRest: AnsiString;
  LReplaced: Boolean;
begin
  Result := AText;
  LPosition := 0;
  while TBotChatText.CharAt(Result, LPosition) <> #0 do
  begin
    // go to the start of the next word
    while (TBotChatText.CharAt(Result, LPosition) <> #0) and (TBotChatText.SignedChar(TBotChatText.CharAt(Result, LPosition)) <= 32) do
      Inc(LPosition);
    if TBotChatText.CharAt(Result, LPosition) = #0 then
      Break;
    LReplaced := False;
    for LList in FTables.Synonyms do
    begin
      if (LList.Context and AContext) = 0 then
        Continue;
      for LIndex := 1 to LList.Synonyms.Count - 1 do
      begin
        LRest := Copy(Result, LPosition + 1, MaxInt);
        // if the synonym is not at the front of the string continue
        if TBotChatText.StringContainsWord(LRest, LList.Synonyms[LIndex].Text, False) <> 0 then
          Continue;
        LReplacement := LList.Synonyms[0].Text;
        // if the replacement IS in front of the string continue
        if TBotChatText.StringContainsWord(LRest, LReplacement, False) = 0 then
          Continue;
        Result := Copy(Result, 1, LPosition) + LReplacement + Copy(Result, LPosition + Length(LList.Synonyms[LIndex].Text) + 1, MaxInt);
        LReplaced := True;
        Break;
      end;
      if LReplaced then
        Break;
    end;
    // skip over this word
    while (TBotChatText.CharAt(Result, LPosition) <> #0) and (TBotChatText.SignedChar(TBotChatText.CharAt(Result, LPosition)) > 32) do
      Inc(LPosition);
    if TBotChatText.CharAt(Result, LPosition) = #0 then
      Break;
  end;
end;

end.
