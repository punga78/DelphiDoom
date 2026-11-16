{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the tokenizer                             }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Tokenizer;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Types, DelphiDoom.Acs.Intf, DelphiDoom.Acs.Diagnostics,
  DelphiDoom.Acs.SymbolTable;

type
  /// <summary>
  ///   Cuts the text of a script in tokens, follows the #include of other files (up to 16 deep)
  ///   and counts the lines. It knows where it is, for the messages of the errors
  /// </summary>
  TAcsTokenizer = class(TInterfacedObject, IAcsSourcePosition)
  private
    type
      TNestInfo = record
        Name: string;
        Text: TBytes;
        Position: Integer;
        Line: Integer;
        IncLineNumber: Boolean;
        LastChar: AnsiChar;
      end;
    var
      FDiagnostics: TAcsDiagnostics;
      FSymbols: TAcsSymbolTable;
      FProvider: IAcsSourceProvider;
      FChar: AnsiChar;
      FText: TBytes;
      FPosition: Integer;
      FAlreadyGot: Boolean;
      FNestDepth: Integer;
      FIncLineNumber: Boolean;
      FOpenFiles: array[0..MAX_NESTED_SOURCES - 1] of TNestInfo;
      FToken: Integer;
      FLine: Integer;
      FNum: Integer;
      FTokenText: string;
      FSpecialValue: Integer;
      FSpecialArgCount: Integer;
      FSourceName: string;
      FIncludedLines: Integer;
      FAsciiToChrCode: array[0..255] of Byte;
      FAsciiToHexDigit: array[0..255] of Byte;
    procedure InitTables;
    procedure NextChr;
    function CheckForKeyword: Boolean;
    function CheckForLineSpecial: Boolean;
    function CheckForConstant: Boolean;
    procedure ProcessLetterToken;
    procedure EvalFixedConstant(AWhole: Integer);
    procedure EvalHexConstant;
    function DigitValue(ADigit: AnsiChar; ARadix: Integer): Integer;
    procedure EvalRadixConstant;
    procedure ProcessNumberToken;
    procedure ProcessQuoteToken;
    procedure ProcessSpecialToken;
    procedure SkipComment;
    procedure SkipCppComment;
    procedure PopNestedSource;
    function GetLine: Integer;
    function GetSourceName: string;
  public
    const
      NON_HEX_DIGIT = 255;
    constructor Create(const ADiagnostics: TAcsDiagnostics; const ASymbols: TAcsSymbolTable;
      const AProvider: IAcsSourceProvider);
    /// <summary>Starts a text: the first token is read by NextToken</summary>
    procedure Open(const ASourceName: string; const AText: TBytes);
    procedure Undo;
    /// <summary>Goes on reading from another file; at its end the reading goes back here</summary>
    procedure DoInclude(const AFileName: string);
    function NextToken: Integer;
    procedure NextTokenMustBe(AToken, AError: Integer);
    procedure TokenMustBe(AToken, AError: Integer);
    /// <summary>The next character that is not a space, or -1 at the end</summary>
    function NextCharacter: Integer;
    /// <summary>True if the current token is one of the list; the list ends with TK_NONE</summary>
    function Member(const AList: array of Integer): Boolean;
    property Token: Integer read FToken;
    property Line: Integer read FLine;
    property Num: Integer read FNum;
    property Text: string read FTokenText;
    property SpecialValue: Integer read FSpecialValue;
    property SpecialArgCount: Integer read FSpecialArgCount;
    property SourceName: string read FSourceName;
    /// <summary>Lines of the files that were included, once they were read to the end</summary>
    property IncludedLines: Integer read FIncludedLines;
  end;

implementation

uses
  DelphiDoom.Acs.Tokens, DelphiDoom.Acs.ErrorCodes;

type
  TKeyword = record
    Name: string;
    Token: Integer;
  end;

const
  KEYWORDS: array[0..26] of TKeyword = (
    (Name: 'break'; Token: TK_BREAK),
    (Name: 'case'; Token: TK_CASE),
    (Name: 'const'; Token: TK_CONST),
    (Name: 'continue'; Token: TK_CONTINUE),
    (Name: 'default'; Token: TK_DEFAULT),
    (Name: 'define'; Token: TK_DEFINE),
    (Name: 'do'; Token: TK_DO),
    (Name: 'else'; Token: TK_ELSE),
    (Name: 'for'; Token: TK_FOR),
    (Name: 'goto'; Token: TK_GOTO),
    (Name: 'if'; Token: TK_IF),
    (Name: 'include'; Token: TK_INCLUDE),
    (Name: 'int'; Token: TK_INT),
    (Name: 'open'; Token: TK_OPEN),
    (Name: 'print'; Token: TK_PRINT),
    (Name: 'printbold'; Token: TK_PRINTBOLD),
    (Name: 'restart'; Token: TK_RESTART),
    (Name: 'script'; Token: TK_SCRIPT),
    (Name: 'special'; Token: TK_SPECIAL),
    (Name: 'str'; Token: TK_STR),
    (Name: 'suspend'; Token: TK_SUSPEND),
    (Name: 'switch'; Token: TK_SWITCH),
    (Name: 'terminate'; Token: TK_TERMINATE),
    (Name: 'until'; Token: TK_UNTIL),
    (Name: 'void'; Token: TK_VOID),
    (Name: 'while'; Token: TK_WHILE),
    (Name: 'world'; Token: TK_WORLD)
  );

{ TAcsTokenizer }

constructor TAcsTokenizer.Create(const ADiagnostics: TAcsDiagnostics;
  const ASymbols: TAcsSymbolTable; const AProvider: IAcsSourceProvider);
begin
  inherited Create;
  FDiagnostics := ADiagnostics;
  FSymbols := ASymbols;
  FProvider := AProvider;
  InitTables;
end;

procedure TAcsTokenizer.InitTables;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    FAsciiToChrCode[LIndex] := CHR_SPECIAL;
    FAsciiToHexDigit[LIndex] := NON_HEX_DIGIT;
  end;

  for LIndex := Ord('0') to Ord('9') do
  begin
    FAsciiToChrCode[LIndex] := CHR_NUMBER;
    FAsciiToHexDigit[LIndex] := LIndex - Ord('0');
  end;

  for LIndex := Ord('A') to Ord('F') do
    FAsciiToHexDigit[LIndex] := 10 + (LIndex - Ord('A'));

  for LIndex := Ord('a') to Ord('f') do
    FAsciiToHexDigit[LIndex] := 10 + (LIndex - Ord('a'));

  for LIndex := Ord('A') to Ord('Z') do
    FAsciiToChrCode[LIndex] := CHR_LETTER;

  for LIndex := Ord('a') to Ord('z') do
    FAsciiToChrCode[LIndex] := CHR_LETTER;

  FAsciiToChrCode[ASCII_QUOTE] := CHR_QUOTE;
  FAsciiToChrCode[ASCII_UNDERSCORE] := CHR_LETTER;
  FAsciiToChrCode[EOF_CHARACTER] := CHR_EOF;
end;

function TAcsTokenizer.GetLine: Integer;
begin
  Result := FLine;
end;

function TAcsTokenizer.GetSourceName: string;
begin
  Result := FSourceName;
end;

procedure TAcsTokenizer.NextChr;
begin
  if FPosition >= Length(FText) then
  begin
    FChar := AnsiChar(EOF_CHARACTER);
    Exit;
  end;

  if FIncLineNumber then
  begin
    Inc(FLine);
    FIncLineNumber := False;
  end;

  FChar := AnsiChar(FText[FPosition]);
  Inc(FPosition);
  if FChar < AnsiChar(ASCII_SPACE) then
  begin
    if FChar = #10 then
      FIncLineNumber := True;
    FChar := AnsiChar(ASCII_SPACE);
  end;
end;

procedure TAcsTokenizer.Open(const ASourceName: string; const AText: TBytes);
begin
  FText := AText;
  FSourceName := ASourceName;
  FPosition := 0;
  FLine := 1;
  FToken := TK_NONE;
  FTokenText := '';
  FIncLineNumber := False;
  FIncludedLines := 0;
  FAlreadyGot := False;
  FNestDepth := 0;
  NextChr;
end;

procedure TAcsTokenizer.DoInclude(const AFileName: string);
var
  LInfo: ^TNestInfo;
  LText: TBytes;
begin
  if FNestDepth = MAX_NESTED_SOURCES then
    FDiagnostics.Fail(ERR_INCL_NESTING_TOO_DEEP, True, 'Unable to include file ''%s''.',
      [AFileName]);

  LInfo := @FOpenFiles[FNestDepth];
  Inc(FNestDepth);
  LInfo.Name := FSourceName;
  LInfo.Text := FText;
  LInfo.Position := FPosition;
  LInfo.Line := FLine;
  LInfo.IncLineNumber := FIncLineNumber;
  LInfo.LastChar := FChar;

  FSourceName := AFileName;
  if not FProvider.TryLoad(FSourceName, LText) then
    FDiagnostics.Fail(ERR_CANT_OPEN_FILE, False, 'File: ''%s''.', [FSourceName]);

  FText := LText;
  FPosition := 0;
  FLine := 1;
  FIncLineNumber := False;
  FToken := TK_NONE;
  FAlreadyGot := False;
  NextChr;
end;

procedure TAcsTokenizer.PopNestedSource;
var
  LInfo: ^TNestInfo;
begin
  FIncludedLines := FIncludedLines + FLine;
  Dec(FNestDepth);
  LInfo := @FOpenFiles[FNestDepth];
  FSourceName := LInfo.Name;
  FText := LInfo.Text;
  FPosition := LInfo.Position;
  FLine := LInfo.Line;
  FIncLineNumber := LInfo.IncLineNumber;
  FChar := LInfo.LastChar;
  FToken := TK_NONE;
  FAlreadyGot := False;
  LInfo.Text := nil;
end;

function TAcsTokenizer.NextCharacter: Integer;
begin
  while FChar = AnsiChar(ASCII_SPACE) do
    NextChr;

  Result := Ord(FChar);
  if Result = EOF_CHARACTER then
    Result := -1;

  NextChr;
end;

function TAcsTokenizer.Member(const AList: array of Integer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := 0;
  while AList[LIndex] <> TK_NONE do
  begin
    if FToken = AList[LIndex] then
    begin
      Result := True;
      Exit;
    end;
    Inc(LIndex);
  end;
  Result := False;
end;

procedure TAcsTokenizer.Undo;
begin
  if FToken <> TK_NONE then
    FAlreadyGot := True;
end;

function TAcsTokenizer.CheckForKeyword: Boolean;
var
  LIndex: Integer;
begin
  for LIndex := Low(KEYWORDS) to High(KEYWORDS) do
    if FTokenText = KEYWORDS[LIndex].Name then
    begin
      FToken := KEYWORDS[LIndex].Token;
      Result := True;
      Exit;
    end;
  Result := False;
end;

function TAcsTokenizer.CheckForLineSpecial: Boolean;
var
  LSymbol: TAcsSymbol;
begin
  LSymbol := FSymbols.FindGlobal(FTokenText);
  if (LSymbol = nil) or (LSymbol.typ <> SY_SPECIAL) then
  begin
    Result := False;
    Exit;
  end;

  FToken := TK_LINESPECIAL;
  FSpecialValue := LSymbol.info.special.value;
  FSpecialArgCount := LSymbol.info.special.argCount;
  Result := True;
end;

function TAcsTokenizer.CheckForConstant: Boolean;
var
  LSymbol: TAcsSymbol;
begin
  LSymbol := FSymbols.FindGlobal(FTokenText);
  if (LSymbol = nil) or (LSymbol.typ <> SY_CONSTANT) then
  begin
    Result := False;
    Exit;
  end;

  FToken := TK_NUMBER;
  FNum := LSymbol.info.constant.value;
  Result := True;
end;

procedure TAcsTokenizer.ProcessLetterToken;
var
  LText: string;
begin
  LText := '';
  while FAsciiToChrCode[Ord(FChar)] in [CHR_LETTER, CHR_NUMBER] do
  begin
    if Length(LText) = MAX_IDENTIFIER_LENGTH then
      FDiagnostics.Fail(ERR_IDENTIFIER_TOO_LONG, True);
    LText := LText + Char(FChar);
    NextChr;
  end;
  FTokenText := LowerCase(LText);
  if not CheckForKeyword and not CheckForLineSpecial and not CheckForConstant then
    FToken := TK_IDENTIFIER;
end;

procedure TAcsTokenizer.EvalFixedConstant(AWhole: Integer);
var
  LFraction: Integer;
  LDivisor: Integer;
begin
  LFraction := 0;
  LDivisor := 1;
  while FAsciiToChrCode[Ord(FChar)] = CHR_NUMBER do
  begin
    LFraction := 10 * LFraction + (Ord(FChar) - Ord('0'));
    LDivisor := LDivisor * 10;
    NextChr;
  end;
  FNum := (AWhole shl 16) + ((LFraction shl 16) div LDivisor);
  FToken := TK_NUMBER;
end;

procedure TAcsTokenizer.EvalHexConstant;
begin
  FNum := 0;
  while FAsciiToHexDigit[Ord(FChar)] <> NON_HEX_DIGIT do
  begin
    FNum := (FNum shl 4) + FAsciiToHexDigit[Ord(FChar)];
    NextChr;
  end;
  FToken := TK_NUMBER;
end;

function TAcsTokenizer.DigitValue(ADigit: AnsiChar; ARadix: Integer): Integer;
var
  LValue: Integer;
begin
  if (ADigit >= 'a') and (ADigit <= 'z') then
    ADigit := AnsiChar(Ord(ADigit) - 32);
  if (ADigit < '0') or ((ADigit > '9') and (ADigit < 'A')) or (ADigit > 'Z') then
  begin
    Result := -1;
    Exit;
  end;
  if ADigit > '9' then
    LValue := 10 + Ord(ADigit) - Ord('A')
  else
    LValue := Ord(ADigit) - Ord('0');
  if LValue >= ARadix then
    Result := -1
  else
    Result := LValue;
end;

procedure TAcsTokenizer.EvalRadixConstant;
var
  LRadix: Integer;
  LDigitValue: Integer;
begin
  LRadix := FNum;
  if (LRadix < 2) or (LRadix > 36) then
    FDiagnostics.Fail(ERR_BAD_RADIX_CONSTANT, True);

  FNum := 0;
  while True do
  begin
    LDigitValue := DigitValue(FChar, LRadix);
    if LDigitValue = -1 then
      Break;
    FNum := LRadix * FNum + LDigitValue;
    NextChr;
  end;
  FToken := TK_NUMBER;
end;

procedure TAcsTokenizer.ProcessNumberToken;
var
  LChar: AnsiChar;
begin
  LChar := FChar;
  NextChr;

  if (LChar = '0') and (FChar in ['x', 'X']) then
  begin // hexadecimal
    NextChr;
    EvalHexConstant;
    Exit;
  end;

  FNum := Ord(LChar) - Ord('0');
  while FAsciiToChrCode[Ord(FChar)] = CHR_NUMBER do
  begin
    FNum := 10 * FNum + (Ord(FChar) - Ord('0'));
    NextChr;
  end;

  if FChar = '.' then
  begin // fixed point
    NextChr;
    EvalFixedConstant(FNum);
    Exit;
  end;

  if FChar = AnsiChar(ASCII_UNDERSCORE) then
  begin // radix: 2_1010
    NextChr;
    EvalRadixConstant;
    Exit;
  end;

  FToken := TK_NUMBER;
end;

procedure TAcsTokenizer.ProcessQuoteToken;
begin
  FTokenText := '';
  NextChr;
  while FChar <> AnsiChar(EOF_CHARACTER) do
  begin
    if FChar = AnsiChar(ASCII_QUOTE) then
      Break;
    if Length(FTokenText) = MAX_QUOTED_LENGTH then
      FDiagnostics.Fail(ERR_STRING_TOO_LONG, True);

    FTokenText := FTokenText + Char(FChar);
    NextChr;
  end;

  if FChar = AnsiChar(ASCII_QUOTE) then
    NextChr;

  FToken := TK_STRING;
end;

procedure TAcsTokenizer.ProcessSpecialToken;
var
  LChar: AnsiChar;
begin
  LChar := FChar;
  NextChr;
  case LChar of
    '+':
      case FChar of
        '=':
          begin
            FToken := TK_ADDASSIGN;
            NextChr;
          end;
        '+':
          begin
            FToken := TK_INC;
            NextChr;
          end;
      else
        FToken := TK_PLUS;
      end;
    '-':
      case FChar of
        '=':
          begin
            FToken := TK_SUBASSIGN;
            NextChr;
          end;
        '-':
          begin
            FToken := TK_DEC;
            NextChr;
          end;
      else
        FToken := TK_MINUS;
      end;
    '*':
      case FChar of
        '=':
          begin
            FToken := TK_MULASSIGN;
            NextChr;
          end;
        '/':
          begin
            FToken := TK_ENDCOMMENT;
            NextChr;
          end;
      else
        FToken := TK_ASTERISK;
      end;
    '/':
      case FChar of
        '=':
          begin
            FToken := TK_DIVASSIGN;
            NextChr;
          end;
        '/':
          FToken := TK_CPPCOMMENT;
        '*':
          begin
            FToken := TK_STARTCOMMENT;
            NextChr;
          end;
      else
        FToken := TK_SLASH;
      end;
    '%':
      if FChar = '=' then
      begin
        FToken := TK_MODASSIGN;
        NextChr;
      end
      else
        FToken := TK_PERCENT;
    '=':
      if FChar = '=' then
      begin
        FToken := TK_EQ;
        NextChr;
      end
      else
        FToken := TK_ASSIGN;
    '<':
      if FChar = '=' then
      begin
        FToken := TK_LE;
        NextChr;
      end
      else if FChar = '<' then
      begin
        FToken := TK_LSHIFT;
        NextChr;
      end
      else
        FToken := TK_LT;
    '>':
      if FChar = '=' then
      begin
        FToken := TK_GE;
        NextChr;
      end
      else if FChar = '>' then
      begin
        FToken := TK_RSHIFT;
        NextChr;
      end
      else
        FToken := TK_GT;
    '!':
      if FChar = '=' then
      begin
        FToken := TK_NE;
        NextChr;
      end
      else
        FToken := TK_NOT;
    '&':
      if FChar = '&' then
      begin
        FToken := TK_ANDLOGICAL;
        NextChr;
      end
      else
        FToken := TK_ANDBITWISE;
    '|':
      if FChar = '|' then
      begin
        FToken := TK_ORLOGICAL;
        NextChr;
      end
      else
        FToken := TK_ORBITWISE;
    '(':
      FToken := TK_LPAREN;
    ')':
      FToken := TK_RPAREN;
    '{':
      FToken := TK_LBRACE;
    '}':
      FToken := TK_RBRACE;
    '[':
      FToken := TK_LBRACKET;
    ']':
      FToken := TK_RBRACKET;
    ':':
      FToken := TK_COLON;
    ';':
      FToken := TK_SEMICOLON;
    ',':
      FToken := TK_COMMA;
    '.':
      FToken := TK_PERIOD;
    '#':
      FToken := TK_NUMBERSIGN;
    '^':
      FToken := TK_EORBITWISE;
    '~':
      FToken := TK_TILDE;
  else
    FDiagnostics.Fail(ERR_BAD_CHARACTER, True);
  end;
end;

procedure TAcsTokenizer.SkipComment;
var
  LFirst: Boolean;
begin
  LFirst := False;
  while FChar <> AnsiChar(EOF_CHARACTER) do
  begin
    if LFirst and (FChar = '/') then
      Break;
    LFirst := FChar = '*';
    NextChr;
  end;
  NextChr;
end;

procedure TAcsTokenizer.SkipCppComment;
var
  LChar: Byte;
begin
  while FPosition < Length(FText) do
  begin
    LChar := FText[FPosition];
    Inc(FPosition);
    if LChar = 10 then
    begin
      Inc(FLine);
      Break;
    end;
  end;
  NextChr;
end;

function TAcsTokenizer.NextToken: Integer;
var
  LValidToken: Boolean;
begin
  if FAlreadyGot then
  begin
    FAlreadyGot := False;
    Result := FToken;
    Exit;
  end;

  LValidToken := False;
  repeat
    while FChar = AnsiChar(ASCII_SPACE) do
      NextChr;

    case FAsciiToChrCode[Ord(FChar)] of
      CHR_EOF:
        FToken := TK_EOF;
      CHR_LETTER:
        ProcessLetterToken;
      CHR_NUMBER:
        ProcessNumberToken;
      CHR_QUOTE:
        ProcessQuoteToken;
    else
      ProcessSpecialToken;
    end;

    if FToken = TK_STARTCOMMENT then
      SkipComment
    else if FToken = TK_CPPCOMMENT then
      SkipCppComment
    else if (FToken = TK_EOF) and (FNestDepth > 0) then
      PopNestedSource
    else
      LValidToken := True;
  until LValidToken;

  Result := FToken;
end;

procedure TAcsTokenizer.NextTokenMustBe(AToken, AError: Integer);
begin
  if NextToken <> AToken then
    FDiagnostics.Fail(AError, True);
end;

procedure TAcsTokenizer.TokenMustBe(AToken, AError: Integer);
begin
  if FToken <> AToken then
    FDiagnostics.Fail(AError, True);
end;

end.
