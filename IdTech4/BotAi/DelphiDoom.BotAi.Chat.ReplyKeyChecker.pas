{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotReplyKeyChecker, BotCheckValidReplyChatKeySet      }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ReplyKeyChecker;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Source;

type
  /// <summary>Warns about reply keys that cannot work together (&amp; and ! prefixes, variables)</summary>
  TBotReplyKeyChecker = class
  public
    /// <summary>The warnings go to the source (SourceWarning), with the line the parser is at</summary>
    class procedure Check(const ASource: TBotChatSource; const AKeys: TList<TBotReplyChatKey>); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Chat.Text;

{ TBotReplyKeyChecker }

class procedure TBotReplyKeyChecker.Check(const ASource: TBotChatSource; const AKeys: TList<TBotReplyChatKey>);
var
  LAllPrefixed: Boolean;
  LHasVariablesKey: Boolean;
  LHasStringKey: Boolean;
  LKeyIndex: Integer;
  LOtherIndex: Integer;
  LKey: TBotReplyChatKey;
  LOther: TBotReplyChatKey;
  LPieceIndex: Integer;
  LStringIndex: Integer;
  LPiece: TBotMatchPiece;
  LFound: Boolean;
begin
  LAllPrefixed := True;
  LHasVariablesKey := False;
  LHasStringKey := False;
  for LKeyIndex := 0 to AKeys.Count - 1 do
  begin
    LKey := AKeys[LKeyIndex];
    if (LKey.Flags and (RCKFL_AND or RCKFL_NOT)) = 0 then
    begin
      LAllPrefixed := False;
      if (LKey.Flags and RCKFL_VARIABLES) <> 0 then
      begin
        for LPiece in LKey.Match do
          if LPiece.PieceType = MT_VARIABLE then
            LHasVariablesKey := True;
      end
      else if (LKey.Flags and RCKFL_STRING) <> 0 then
        LHasStringKey := True;
    end
    else if ((LKey.Flags and RCKFL_AND) <> 0) and ((LKey.Flags and RCKFL_STRING) <> 0) then
    begin
      for LOtherIndex := 0 to AKeys.Count - 1 do
      begin
        if LOtherIndex = LKeyIndex then
          Continue;
        LOther := AKeys[LOtherIndex];
        if (LOther.Flags and RCKFL_NOT) <> 0 then
          Continue;
        if (LOther.Flags and RCKFL_VARIABLES) <> 0 then
        begin
          // does a piece leave space for the key?
          LFound := False;
          for LPieceIndex := 0 to High(LOther.Match) do
          begin
            LPiece := LOther.Match[LPieceIndex];
            if LPiece.PieceType = MT_STRING then
            begin
              for LStringIndex := 0 to High(LPiece.Strings) do
              begin
                if TBotChatText.StringContains(LPiece.Strings[LStringIndex], LKey.Text, False) <> -1 then
                begin
                  LFound := True;
                  Break;
                end;
              end;
              if LFound then
                Break;
            end
            else if LPiece.PieceType = MT_VARIABLE then
            begin
              LFound := True;
              Break;
            end;
          end;
          if not LFound then
            ASource.Warning(Format('one of the match templates does not leave space for the key %s with the & prefix',
              [string(LKey.Text)]));
        end;
      end;
    end;
    if ((LKey.Flags and RCKFL_NOT) <> 0) and ((LKey.Flags and RCKFL_STRING) <> 0) then
    begin
      for LOtherIndex := 0 to AKeys.Count - 1 do
      begin
        if LOtherIndex = LKeyIndex then
          Continue;
        LOther := AKeys[LOtherIndex];
        if (LOther.Flags and RCKFL_NOT) <> 0 then
          Continue;
        if (LOther.Flags and RCKFL_STRING) <> 0 then
        begin
          if TBotChatText.StringContains(LOther.Text, LKey.Text, False) <> -1 then
            ASource.Warning(Format('the key %s with prefix ! is inside the key %s', [string(LKey.Text), string(LOther.Text)]));
        end
        else if (LOther.Flags and RCKFL_VARIABLES) <> 0 then
        begin
          for LPiece in LOther.Match do
          begin
            if LPiece.PieceType = MT_STRING then
            begin
              for LStringIndex := 0 to High(LPiece.Strings) do
              begin
                if TBotChatText.StringContains(LPiece.Strings[LStringIndex], LKey.Text, False) <> -1 then
                  ASource.Warning(Format('the key %s with prefix ! is inside the match template string %s',
                    [string(LKey.Text), string(LPiece.Strings[LStringIndex])]));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if LAllPrefixed then
    ASource.Warning('all keys have a & or ! prefix');
  if LHasVariablesKey and LHasStringKey then
    ASource.Warning('variables from the match template(s) could be invalid when outputting one of the chat messages');
end;

end.
