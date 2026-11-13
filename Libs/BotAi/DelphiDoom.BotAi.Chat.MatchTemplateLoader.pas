{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMatchTemplateLoader, BotLoadMatchTemplates         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotLoadMatchTemplates}
{  of code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.MatchTemplateLoader;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Types;

type
  /// <summary>Reads the file of match templates: <c>context { pieces = (type, subtype); }</c></summary>
  TBotMatchTemplateLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    procedure ParseFile(const AFileName: AnsiString; const AList: TList<TBotMatchTemplate>);
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource);
    /// <summary>BotLoadMatchTemplates; false (list empty, the reason printed) if the file cannot be loaded</summary>
    function Load(const AFileName: AnsiString; const AList: TList<TBotMatchTemplate>): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Source,
  DelphiDoom.BotAi.Chat.MatchPieceReader;

{ TBotMatchTemplateLoader }

constructor TBotMatchTemplateLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
end;

procedure TBotMatchTemplateLoader.ParseFile(const AFileName: AnsiString; const AList: TList<TBotMatchTemplate>);
var
  LSource: TBotChatSource;
  LToken: TIdToken;
  LContext: Cardinal;
  LTemplate: TBotMatchTemplate;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if LSource = nil then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    raise EBotChatParseException.Create('counldn''t load ' + string(AFileName), string(AFileName), 0);
  end;
  try
    while LSource.ReadToken(LToken) do
    begin
      if (LToken.TokenType <> TT_NUMBER) or ((LToken.SubType and TT_INTEGER) = 0) then
        LSource.Fail('expected integer, found ' + string(TBotChatSource.CText(LToken)) + #10);
      LContext := LToken.GetUnsignedLongValue;
      LSource.ExpectTokenString('{');
      while LSource.ReadToken(LToken) do
      begin
        if TBotChatSource.CText(LToken) = '}' then
          Break;
        LSource.UnreadLastToken;
        LTemplate := Default(TBotMatchTemplate);
        LTemplate.Context := LContext;
        LTemplate.Pieces := TBotMatchPieceReader.Read(LSource, '=');
        // the original fails without a message when there is no piece
        if Length(LTemplate.Pieces) = 0 then
          raise EBotChatParseException.Create('no match pieces', LSource.FileName, 0);
        LSource.ExpectTokenString('(');
        LSource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
        LTemplate.MatchType := Integer(LToken.GetUnsignedLongValue);
        LSource.ExpectTokenString(',');
        LSource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
        LTemplate.SubType := Integer(LToken.GetUnsignedLongValue);
        LSource.ExpectTokenString(')');
        LSource.ExpectTokenString(';');
        AList.Add(LTemplate);
      end;
    end;
  finally
    LSource.Free;
  end;
end;

function TBotMatchTemplateLoader.Load(const AFileName: AnsiString; const AList: TList<TBotMatchTemplate>): Boolean;
begin
  AList.Clear;
  try
    ParseFile(AFileName, AList);
  except
    on EBotChatParseException do
    begin
      AList.Clear;
      Exit(False);
    end;
  end;
  FImport.Print(PRT_MESSAGE, 'loaded ' + AFileName + #10);
  Result := True;
end;

end.
