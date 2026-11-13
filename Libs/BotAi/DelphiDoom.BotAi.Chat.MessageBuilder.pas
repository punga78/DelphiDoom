{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatMessageBuilder, BotExpandChatMessage and       }
{  BotConstructChatMessage                                                     }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.MessageBuilder;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.RandomStrings,
  DelphiDoom.BotAi.Chat.SynonymReplacer;

type
  /// <summary>
  ///   Turns a compiled message (variables and random strings between escape characters) into the
  ///   text the bot says. The output is the message buffer of the chat state, written in place as the
  ///   original does: after an error the new characters are followed by what the buffer held before.
  /// </summary>
  TBotChatMessageBuilder = class
  strict private
    FImport: IBotImport;
    FRandomStrings: TBotRandomStrings;
    FReplacer: TBotSynonymReplacer;
    class function StrLen(const ABuffer: TBotMessageBuffer): Integer; static;
    class procedure SetText(var ABuffer: TBotMessageBuffer; const AText: AnsiString); static;
  public
    constructor Create(const AImport: IBotImport; const ARandomStrings: TBotRandomStrings;
      const AReplacer: TBotSynonymReplacer);
    /// <summary>The characters of the buffer up to the first zero (strlen of the C string)</summary>
    class function BufferText(const ABuffer: TBotMessageBuffer): AnsiString; static;
    /// <summary>
    ///   BotExpandChatMessage: true if a random string was expanded (the message may have more to
    ///   expand), false if not or after an error. A variable above 7 is an error (the original reads
    ///   outside the match for 8).
    /// </summary>
    function Expand(var AOutput: TBotMessageBuffer; const AMessage: AnsiString; const AMessageContext: Cardinal;
      const AMatch: TBotMatch; const AVariableContext: Cardinal; const AReply: Boolean): Boolean;
    /// <summary>BotConstructChatMessage: expands up to ten times, until nothing is left to expand</summary>
    procedure Construct(var AOutput: TBotMessageBuffer; const AMessage: AnsiString; const AMessageContext: Cardinal;
      const AMatch: TBotMatch; const AVariableContext: Cardinal; const AReply: Boolean);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Text;

{ TBotChatMessageBuilder }

constructor TBotChatMessageBuilder.Create(const AImport: IBotImport; const ARandomStrings: TBotRandomStrings;
  const AReplacer: TBotSynonymReplacer);
begin
  inherited Create;
  FImport := AImport;
  FRandomStrings := ARandomStrings;
  FReplacer := AReplacer;
end;

class function TBotChatMessageBuilder.StrLen(const ABuffer: TBotMessageBuffer): Integer;
begin
  Result := 0;
  while (Result < MAX_MESSAGE_SIZE) and (ABuffer[Result] <> #0) do
    Inc(Result);
end;

class function TBotChatMessageBuilder.BufferText(const ABuffer: TBotMessageBuffer): AnsiString;
begin
  SetString(Result, PAnsiChar(@ABuffer[0]), StrLen(ABuffer));
end;

class procedure TBotChatMessageBuilder.SetText(var ABuffer: TBotMessageBuffer; const AText: AnsiString);
var
  LLength: Integer;
begin
  // the text and its zero are written over the buffer, the bytes behind stay (the original works in place)
  LLength := Length(AText);
  if LLength > MAX_MESSAGE_SIZE - 1 then
    LLength := MAX_MESSAGE_SIZE - 1;
  if LLength > 0 then
    Move(AText[1], ABuffer[0], LLength);
  ABuffer[LLength] := #0;
end;

function TBotChatMessageBuilder.Expand(var AOutput: TBotMessageBuffer; const AMessage: AnsiString;
  const AMessageContext: Cardinal; const AMatch: TBotMatch; const AVariableContext: Cardinal;
  const AReply: Boolean): Boolean;
var
  LPosition: Integer;
  LLength: Integer;
  LNumber: Integer;
  LName: AnsiString;
  LText: AnsiString;
  LExpansion: Boolean;

  procedure Append(const AAdd: AnsiString);
  begin
    if AAdd <> '' then
      Move(AAdd[1], AOutput[LLength], Length(AAdd));
    Inc(LLength, Length(AAdd));
  end;

begin
  LExpansion := False;
  LPosition := 0;
  LLength := 0;
  while TBotChatText.CharAt(AMessage, LPosition) <> #0 do
  begin
    if TBotChatText.CharAt(AMessage, LPosition) = ESCAPE_CHAR then
    begin
      Inc(LPosition);
      case TBotChatText.CharAt(AMessage, LPosition) of
        'v':
          begin
            Inc(LPosition);
            LNumber := 0;
            while (TBotChatText.CharAt(AMessage, LPosition) <> #0) and (TBotChatText.CharAt(AMessage, LPosition) <> ESCAPE_CHAR) do
            begin
              LNumber := LNumber * 10 + Ord(TBotChatText.CharAt(AMessage, LPosition)) - Ord('0');
              Inc(LPosition);
            end;
            // step over the trailing escape char
            if TBotChatText.CharAt(AMessage, LPosition) <> #0 then
              Inc(LPosition);
            if (LNumber >= MAX_MATCHVARIABLES) or (LNumber < 0) then
            begin
              FImport.Print(PRT_ERROR, 'BotConstructChat: message ' + AMessage + ' variable ' +
                AnsiString(IntToStr(LNumber)) + ' out of range'#10);
              Exit(False);
            end;
            if AMatch.Variables[LNumber].Offset >= 0 then
            begin
              LText := Copy(AMatch.Text, AMatch.Variables[LNumber].Offset + 1, AMatch.Variables[LNumber].Length);
              if AReply then
                LText := FReplacer.ReplaceReplySynonyms(LText, AVariableContext)
              else
                LText := FReplacer.ReplaceSynonyms(LText, AVariableContext);
              if LLength + Length(LText) >= MAX_MESSAGE_SIZE then
              begin
                FImport.Print(PRT_ERROR, 'BotConstructChat: message ' + AMessage + ' too long'#10);
                Exit(False);
              end;
              Append(LText);
              AOutput[LLength] := #0;
            end;
          end;
        'r':
          begin
            Inc(LPosition);
            LName := '';
            while (TBotChatText.CharAt(AMessage, LPosition) <> #0) and (TBotChatText.CharAt(AMessage, LPosition) <> ESCAPE_CHAR) do
            begin
              LName := LName + TBotChatText.CharAt(AMessage, LPosition);
              Inc(LPosition);
            end;
            if TBotChatText.CharAt(AMessage, LPosition) <> #0 then
              Inc(LPosition);
            // find the random keyword
            if not FRandomStrings.TryChoose(LName, LText) then
            begin
              FImport.Print(PRT_ERROR, 'BotConstructChat: unknown random string ' + LName + #10);
              Exit(False);
            end;
            if LLength + Length(LText) >= MAX_MESSAGE_SIZE then
            begin
              FImport.Print(PRT_ERROR, 'BotConstructChat: message "' + AMessage + '" too long'#10);
              Exit(False);
            end;
            Append(LText);
            AOutput[LLength] := #0;
            LExpansion := True;
          end;
      else
        // the character is then copied as a normal one
        FImport.Print(PRT_FATAL, 'BotConstructChat: message "' + AMessage + '" invalid escape char'#10);
      end;
    end
    else
    begin
      AOutput[LLength] := TBotChatText.CharAt(AMessage, LPosition);
      Inc(LLength);
      Inc(LPosition);
      if LLength >= MAX_MESSAGE_SIZE then
      begin
        FImport.Print(PRT_ERROR, 'BotConstructChat: message "' + AMessage + '" too long'#10);
        // the original writes the zero after the buffer
        LLength := MAX_MESSAGE_SIZE - 1;
        Break;
      end;
    end;
  end;
  AOutput[LLength] := #0;
  // replace synonyms weighted in the message context
  SetText(AOutput, FReplacer.ReplaceWeightedSynonyms(BufferText(AOutput), AMessageContext));
  // true if a random was expanded
  Result := LExpansion;
end;

procedure TBotChatMessageBuilder.Construct(var AOutput: TBotMessageBuffer; const AMessage: AnsiString;
  const AMessageContext: Cardinal; const AMatch: TBotMatch; const AVariableContext: Cardinal;
  const AReply: Boolean);
var
  LSource: AnsiString;
  LIndex: Integer;
begin
  LSource := Copy(AMessage, 1, MAX_MESSAGE_SIZE - 1);
  LIndex := 0;
  while LIndex < 10 do
  begin
    if not Expand(AOutput, LSource, AMessageContext, AMatch, AVariableContext, AReply) then
      Break;
    LSource := BufferText(AOutput);
    Inc(LIndex);
  end;
  if LIndex >= 10 then
  begin
    FImport.Print(PRT_WARNING, 'too many expansions in chat message'#10);
    FImport.Print(PRT_WARNING, BufferText(AOutput) + #10);
  end;
end;

end.
