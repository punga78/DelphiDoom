{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMatchPieceReader, BotLoadMatchPieces               }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadMatchPieces  }
{  of code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.MatchPieceReader;

interface

uses
  DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Source;

type
  /// <summary>Reads the pieces of a match template or of a reply key: strings (with | alternatives) and variables</summary>
  TBotMatchPieceReader = class
  public
    /// <summary>
    ///   BotLoadMatchPieces up to the end token; empty if the file ends before a piece (the caller
    ///   treats it as a failure without a message, as the original does)
    /// </summary>
    class function Read(const ASource: TBotChatSource; const AEndToken: AnsiString): TBotMatchPieces; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types;

{ TBotMatchPieceReader }

class function TBotMatchPieceReader.Read(const ASource: TBotChatSource; const AEndToken: AnsiString): TBotMatchPieces;
var
  LToken: TIdToken;
  LPiece: TBotMatchPiece;
  LLastWasVariable: Boolean;
  LEmptyString: Boolean;
begin
  Result := nil;
  LLastWasVariable := False;
  while ASource.ReadToken(LToken) do
  begin
    if (LToken.TokenType = TT_NUMBER) and ((LToken.SubType and TT_INTEGER) <> 0) then
    begin
      if (Integer(LToken.GetUnsignedLongValue) < 0) or (Integer(LToken.GetUnsignedLongValue) >= MAX_MATCHVARIABLES) then
        ASource.Fail(Format('can''t have more than %d match variables'#10, [MAX_MATCHVARIABLES]));
      if LLastWasVariable then
        ASource.Fail('not allowed to have adjacent variables'#10);
      LLastWasVariable := True;
      LPiece := Default(TBotMatchPiece);
      LPiece.PieceType := MT_VARIABLE;
      LPiece.Variable := Integer(LToken.GetUnsignedLongValue);
      Result := Result + [LPiece];
    end
    else if LToken.TokenType = TT_STRING then
    begin
      LPiece := Default(TBotMatchPiece);
      LPiece.PieceType := MT_STRING;
      LEmptyString := False;
      repeat
        if Length(LPiece.Strings) > 0 then
          ASource.ExpectTokenType(TT_STRING, 0, LToken);
        LPiece.Strings := LPiece.Strings + [LToken.Text];
        if LToken.Text = '' then
          LEmptyString := True;
      until not ASource.CheckTokenString('|');
      Result := Result + [LPiece];
      // if there was no empty string found
      if not LEmptyString then
        LLastWasVariable := False;
    end
    else
      ASource.Fail('invalid token ' + string(TBotChatSource.CText(LToken)) + #10);
    if ASource.CheckTokenString(AEndToken) then
      Break;
    ASource.ExpectTokenString(',');
  end;
end;

end.
