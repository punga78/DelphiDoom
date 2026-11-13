{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatMessageReader, BotLoadChatMessage              }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadChatMessage  }
{  of code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.MessageReader;

interface

uses
  DelphiDoom.BotAi.Chat.Source;

type
  /// <summary>
  ///   Reads one chat message: strings, variables (numbers) and random strings (names) separated by
  ///   commas and ended by a semicolon, into the compiled form with the escape characters.
  /// </summary>
  TBotChatMessageReader = class
  public
    /// <summary>BotLoadChatMessage; a message that does not fit MAX_MESSAGE_SIZE is an error</summary>
    class function Read(const ASource: TBotChatSource): AnsiString; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Chat.Types;

{ TBotChatMessageReader }

class function TBotChatMessageReader.Read(const ASource: TBotChatSource): AnsiString;
var
  LToken: TIdToken;
begin
  Result := '';
  while True do
  begin
    ASource.ExpectAnyToken(LToken);
    if LToken.TokenType = TT_STRING then
    begin
      // fixed string
      if Length(Result) + Length(LToken.Text) + 1 > MAX_MESSAGE_SIZE then
        ASource.Fail('chat message too long'#10);
      Result := Result + LToken.Text;
    end
    else if (LToken.TokenType = TT_NUMBER) and ((LToken.SubType and TT_INTEGER) <> 0) then
    begin
      // variable string
      if Length(Result) + 7 > MAX_MESSAGE_SIZE then
        ASource.Fail('chat message too long'#10);
      Result := Result + ESCAPE_CHAR + 'v' + AnsiString(IntToStr(Integer(LToken.GetUnsignedLongValue))) + ESCAPE_CHAR;
    end
    else if LToken.TokenType = TT_NAME then
    begin
      // random string; the original checks only 7 characters and overflows with a long name
      if Length(Result) + 7 > MAX_MESSAGE_SIZE then
        ASource.Fail('chat message too long'#10);
      if Length(Result) + 3 + Length(LToken.Text) >= MAX_MESSAGE_SIZE then
        ASource.Fail('chat message too long'#10);
      Result := Result + ESCAPE_CHAR + 'r' + LToken.Text + ESCAPE_CHAR;
    end
    else
      ASource.Fail('unknown message component ' + string(TBotChatSource.CText(LToken)) + #10);
    if ASource.CheckTokenString(';') then
      Break;
    ASource.ExpectTokenString(',');
  end;
end;

end.
