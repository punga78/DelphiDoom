{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatSource, a script of the bots with the          }
{  PC_ functions of the precompiler of Quake III                               }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): PC_ReadToken and    }
{  the PC_Expect*/PC_Check* functions of code\botlib\l_precomp.c over the      }
{  parser of id Tech 4 (TIdParser). Based on the Quake III Arena GPL Source    }
{  Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Source;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.Scanner.IdParser, DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>
  ///   A source file of the bots (LoadSourceFile): the preprocessing and the tokens are those of
  ///   TIdParser, which is the descendant of the precompiler of Quake III; the PC_ functions keep their
  ///   messages. The tokens are as the original gives them with one exception: a string is without its
  ///   quotes (StripDoubleQuotes is already done), so use <c>CText</c> to compare or print one.
  ///   Every Expect* failure is reported to botimport.Print as the original does and raises
  ///   EBotChatParseException (the original returned false and its caller returned NULL).
  /// </summary>
  TBotChatSource = class
  strict private
    FParser: TIdParser;
    FImport: IBotImport;
    FLast: TIdToken;
    FFileName: string;
  public
    constructor Create(const AParser: TIdParser; const AImport: IBotImport; const AFileName: string);
    destructor Destroy; override;
    /// <summary>LoadSourceFile of a file of the base folder; nil if it cannot be read (nothing is printed)</summary>
    class function Open(const AImport: IBotImport; const AFiles: IBotFileSource;
      const AFileName: AnsiString): TBotChatSource; static;
    /// <summary>The text of the token as the C string token_t.string: strings and literals with their quotes</summary>
    class function CText(const AToken: TIdToken): AnsiString; static;
    /// <summary>PC_ReadToken: false at the end of the file or after an error of the scanner (which is printed)</summary>
    function ReadToken(out AToken: TIdToken): Boolean;
    function ExpectTokenString(const AText: AnsiString): Boolean;
    function ExpectTokenType(const AType, ASubType: Integer; out AToken: TIdToken): Boolean;
    function ExpectAnyToken(out AToken: TIdToken): Boolean;
    function CheckTokenString(const AText: AnsiString): Boolean;
    function CheckTokenType(const AType, ASubType: Integer; out AToken: TIdToken): Boolean;
    procedure UnreadLastToken;
    /// <summary>SourceError: prints "file F, line N: text" at PRT_ERROR and raises</summary>
    procedure Fail(const AText: string);
    /// <summary>SourceWarning: prints "file F, line N: text" at PRT_WARNING</summary>
    procedure Warning(const AText: string);
    property FileName: string read FFileName;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Chat.ScriptFileSystem, DelphiDoom.BotAi.Chat.ScriptLog, DelphiDoom.IdLib.Core.Exceptions;

{ TBotChatSource }

constructor TBotChatSource.Create(const AParser: TIdParser; const AImport: IBotImport; const AFileName: string);
begin
  inherited Create;
  FParser := AParser;
  FImport := AImport;
  FFileName := AFileName;
  FLast := TIdToken.Create;
end;

destructor TBotChatSource.Destroy;
begin
  FParser.Free;
  inherited Destroy;
end;

class function TBotChatSource.Open(const AImport: IBotImport; const AFiles: IBotFileSource;
  const AFileName: AnsiString): TBotChatSource;
var
  LParser: TIdParser;
begin
  LParser := TIdParser.Create(0, TBotScriptLog.Create(AImport), TBotScriptFileSystem.Create(AFiles, BOT_FILES_BASE_FOLDER));
  if not LParser.LoadFile(AFileName) then
  begin
    LParser.Free;
    Exit(nil);
  end;
  Result := TBotChatSource.Create(LParser, AImport, string(AFileName));
end;

class function TBotChatSource.CText(const AToken: TIdToken): AnsiString;
begin
  case AToken.TokenType of
    TT_STRING:
      Result := '"' + AToken.Text + '"';
    TT_LITERAL:
      Result := '''' + AToken.Text + '''';
  else
    Result := AToken.Text;
  end;
end;

procedure TBotChatSource.Fail(const AText: string);
begin
  FImport.Print(PRT_ERROR, AnsiString(Format('file %s, line %d: %s', [FFileName, FParser.LineNum, AText])) + #10);
  raise EBotChatParseException.Create(AText, FFileName, FParser.LineNum);
end;

procedure TBotChatSource.Warning(const AText: string);
begin
  FImport.Print(PRT_WARNING, AnsiString(Format('file %s, line %d: %s', [FFileName, FParser.LineNum, AText])) + #10);
end;

function TBotChatSource.ReadToken(out AToken: TIdToken): Boolean;
begin
  AToken := TIdToken.Create;
  try
    Result := FParser.ReadToken(AToken);
  except
    on E: EIdLexerException do
    begin
      FImport.Print(PRT_ERROR, AnsiString(E.Message) + #10);
      Result := False;
    end;
  end;
  if Result then
    FLast := AToken;
end;

function TBotChatSource.ExpectTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Fail('couldn''t find expected ' + string(AText));
  if CText(LToken) <> AText then
    Fail(Format('expected %s, found %s', [string(AText), string(CText(LToken))]));
  Result := True;
end;

function TBotChatSource.ExpectTokenType(const AType, ASubType: Integer; out AToken: TIdToken): Boolean;
var
  LName: string;
begin
  if not ReadToken(AToken) then
    Fail('couldn''t read expected token');
  if AToken.TokenType <> AType then
  begin
    LName := '';
    case AType of
      TT_STRING: LName := 'string';
      TT_LITERAL: LName := 'literal';
      TT_NUMBER: LName := 'number';
      TT_NAME: LName := 'name';
      TT_PUNCTUATION: LName := 'punctuation';
    end;
    Fail(Format('expected a %s, found %s', [LName, string(CText(AToken))]));
  end;
  if AToken.TokenType = TT_NUMBER then
  begin
    if (AToken.SubType and ASubType) <> ASubType then
    begin
      // the original prints an uninitialised buffer before the names; here it is empty
      LName := '';
      if (ASubType and TT_DECIMAL) <> 0 then LName := 'decimal';
      if (ASubType and TT_HEX) <> 0 then LName := 'hex';
      if (ASubType and TT_OCTAL) <> 0 then LName := 'octal';
      if (ASubType and TT_BINARY) <> 0 then LName := 'binary';
      if (ASubType and TT_LONG) <> 0 then LName := LName + ' long';
      if (ASubType and TT_UNSIGNED) <> 0 then LName := LName + ' unsigned';
      if (ASubType and TT_FLOAT) <> 0 then LName := LName + ' float';
      if (ASubType and TT_INTEGER) <> 0 then LName := LName + ' integer';
      Fail(Format('expected %s, found %s', [LName, string(CText(AToken))]));
    end;
  end
  else if AToken.TokenType = TT_PUNCTUATION then
  begin
    if AToken.SubType <> ASubType then
      Fail(Format('found %s', [string(CText(AToken))]));
  end;
  Result := True;
end;

function TBotChatSource.ExpectAnyToken(out AToken: TIdToken): Boolean;
begin
  if not ReadToken(AToken) then
    Fail('couldn''t read expected token');
  Result := True;
end;

function TBotChatSource.CheckTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  if CText(LToken) = AText then
    Exit(True);
  FParser.UnreadToken(LToken);
  Result := False;
end;

function TBotChatSource.CheckTokenType(const AType, ASubType: Integer; out AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  AToken := TIdToken.Create;
  if not ReadToken(LToken) then
    Exit(False);
  if (LToken.TokenType = AType) and ((LToken.SubType and ASubType) = ASubType) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  FParser.UnreadToken(LToken);
  Result := False;
end;

procedure TBotChatSource.UnreadLastToken;
begin
  FParser.UnreadToken(FLast);
end;

end.
