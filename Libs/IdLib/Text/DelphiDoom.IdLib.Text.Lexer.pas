{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - TIdLexer, the lexicographical parser of idTech 4   }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Lexer.h, Lexer.cpp.      }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.Lexer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token;

type
  /// <summary>
  ///   The lexer of Doom 3 (idLexer): reads names, numbers, strings, literals and punctuation from
  ///   a text with the same rules as the original, including its quirks (a char is a signed byte:
  ///   bytes above 127 are white space; the character after a <c>/* */</c> comment is skipped).
  ///   The text is an 8-bit AnsiString. Replacements for the engine singletons: the log (warnings)
  ///   and the file system come from the constructor; <c>common->Error</c> is an
  ///   EIdLexerException with the message "file F, line N: text" (a warning in the log when the
  ///   flag LEXFL_NOFATALERRORS is set, nothing when LEXFL_NOERRORS is set). The static
  ///   <c>baseFolder</c> is the property <c>BaseFolder</c> of the instance. Methods that return
  ///   <c>int</c> in C++ return Boolean (0 / 1).
  /// </summary>
  TIdLexer = class
  private
    FLoaded: Boolean;
    FFileName: AnsiString;
    FBuffer: AnsiString;
    FScriptPosition: Integer;
    FEndPosition: Integer;
    FLastScriptPosition: Integer;
    FWhiteSpaceStart: Integer;
    FWhiteSpaceEnd: Integer;
    FFileTime: Int64;
    FLength: Integer;
    FLine: Integer;
    FLastLine: Integer;
    FTokenAvailable: Boolean;
    FFlags: Integer;
    FPunctuations: TIdPunctuationList;
    FPunctuationTable: array[0..255] of Integer;
    FNextPunctuation: TArray<Integer>;
    FToken: TIdToken;
    FHadError: Boolean;
    FBaseFolder: AnsiString;
    FLog: IIdLibLog;
    FFileSystem: IIdLibFileSystem;
    function Ch(const AOffset: Integer = 0): Integer; inline;
    procedure CreatePunctuationTable;
    function ReadWhiteSpace: Boolean;
    function ReadEscapeCharacter(out AChar: AnsiChar): Boolean;
    function ReadString(var AToken: TIdToken; const AQuote: Integer): Boolean;
    function ReadName(var AToken: TIdToken): Boolean;
    function ReadNumber(var AToken: TIdToken): Boolean;
    function ReadPunctuation(var AToken: TIdToken): Boolean;
    procedure ResetLexerFields;
    function PrintPrefix(const AText: string): string;
  public
    constructor Create(const AFlags: Integer = 0; const ALog: IIdLibLog = nil;
      const AFileSystem: IIdLibFileSystem = nil); overload;
    destructor Destroy; override;
    /// <summary>Loads a script from a file (idLexer(filename, flags, OSPath))</summary>
    function LoadFile(const AFileName: AnsiString; const AIsOsPath: Boolean = False): Boolean;
    /// <summary>Loads a script from memory with a starting line number</summary>
    function LoadMemory(const AText: AnsiString; const ALength: Integer; const AName: AnsiString;
      const AStartLine: Integer = 1): Boolean; overload;
    function LoadMemory(const AText: AnsiString; const AName: AnsiString): Boolean; overload;
    procedure FreeSource;
    function IsLoaded: Boolean;
    function ReadToken(var AToken: TIdToken): Boolean;
    function ExpectTokenString(const AText: AnsiString): Boolean;
    function ExpectTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
    function ExpectAnyToken(var AToken: TIdToken): Boolean;
    function CheckTokenString(const AText: AnsiString): Boolean;
    function CheckTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
    function PeekTokenString(const AText: AnsiString): Boolean;
    function PeekTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
    function SkipUntilString(const AText: AnsiString): Boolean;
    function SkipRestOfLine: Boolean;
    function SkipBracedSection(const AParseFirstBrace: Boolean = True): Boolean;
    procedure UnreadToken(const AToken: TIdToken);
    function ReadTokenOnLine(var AToken: TIdToken): Boolean;
    /// <summary>Appends the rest of the current line to <c>AOutput</c> (it does not clear it), strips spaces</summary>
    function ReadRestOfLine(var AOutput: AnsiString): AnsiString;
    function ParseInt: Integer;
    function ParseBool: Boolean;
    /// <summary>With <c>AErrorFlag</c> the problems are warnings and the flag is set, without it they are errors</summary>
    function ParseFloat(const AErrorFlag: PBoolean = nil): Single;
    function Parse1DMatrix(const AX: Integer; var AMatrix: array of Single; const AOffset: Integer = 0): Boolean;
    function Parse2DMatrix(const AY, AX: Integer; var AMatrix: array of Single; const AOffset: Integer = 0): Boolean;
    function Parse3DMatrix(const AZ, AY, AX: Integer; var AMatrix: array of Single): Boolean;
    function ParseBracedSection(var AOutput: AnsiString): AnsiString;
    function ParseBracedSectionExact(var AOutput: AnsiString; ATabs: Integer = -1): AnsiString;
    function ParseRestOfLine(var AOutput: AnsiString): AnsiString;
    function GetLastWhiteSpace(var AWhiteSpace: AnsiString): Integer;
    function GetLastWhiteSpaceStart: Integer;
    function GetLastWhiteSpaceEnd: Integer;
    /// <summary>Sets the punctuation set; an empty list restores the default C/C++ set</summary>
    procedure SetPunctuations(const APunctuations: TIdPunctuationList);
    function GetPunctuationFromId(const AId: Integer): AnsiString;
    function GetPunctuationId(const AText: AnsiString): Integer;
    procedure Reset;
    function EndOfFile: Boolean;
    function NumLinesCrossed: Integer;
    procedure Error(const AFormat: string; const AArgs: array of const);
    procedure Warning(const AFormat: string; const AArgs: array of const);
    function HadError: Boolean;
    property Flags: Integer read FFlags write FFlags;
    property FileName: AnsiString read FFileName;
    property FileTime: Int64 read FFileTime;
    property LineNum: Integer read FLine;
    /// <summary>The offset in the script (idLexer::GetFileOffset)</summary>
    function GetFileOffset: Integer;
    /// <summary>The characters of the script from <c>AStart</c> up to (not including) <c>AEnd</c> (offsets in the script)</summary>
    function GetBufferText(const AStart, AEnd: Integer): AnsiString;
    /// <summary>The base folder idLexer::SetBaseFolder sets (a static in the original)</summary>
    property BaseFolder: AnsiString read FBaseFolder write FBaseFolder;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Str;

// the text of a token as the C library prints it with %s: up to the first #0
function CText(const AText: AnsiString): string;
begin
  Result := string(Copy(AText, 1, TIdStrings.Length(AText)));
end;

{ TIdLexer }

constructor TIdLexer.Create(const AFlags: Integer; const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem);
begin
  inherited Create;
  FLog := ALog;
  FFileSystem := AFileSystem;
  FFlags := AFlags;
  FFileName := '';
  FToken := TIdToken.Create;
  ResetLexerFields;
  SetPunctuations(nil);
end;

destructor TIdLexer.Destroy;
begin
  FreeSource;
  inherited Destroy;
end;

procedure TIdLexer.ResetLexerFields;
begin
  FLoaded := False;
  FFileTime := 0;
  FLength := 0;
  FLine := 0;
  FLastLine := 0;
  FTokenAvailable := False;
  FHadError := False;
  FBuffer := '';
  FScriptPosition := 0;
  FEndPosition := 0;
  FLastScriptPosition := 0;
  FWhiteSpaceStart := -1;
  FWhiteSpaceEnd := -1;
end;

function TIdLexer.Ch(const AOffset: Integer): Integer;
var
  LIndex: Integer;
begin
  LIndex := FScriptPosition + AOffset;
  if (LIndex < 0) or (LIndex >= System.Length(FBuffer)) then
    Result := 0
  else
    Result := ShortInt(Byte(FBuffer[LIndex + 1]));
end;

function TIdLexer.PrintPrefix(const AText: string): string;
begin
  Result := Format('file %s, line %d: %s', [string(FFileName), FLine, AText]);
end;

procedure TIdLexer.Error(const AFormat: string; const AArgs: array of const);
var
  LText: string;
begin
  FHadError := True;
  if (FFlags and LEXFL_NOERRORS) <> 0 then
    Exit;
  LText := PrintPrefix(Format(AFormat, AArgs));
  if (FFlags and LEXFL_NOFATALERRORS) <> 0 then
  begin
    if Assigned(FLog) then
      FLog.Warning(LText);
  end
  else
    raise EIdLexerException.Create(LText);
end;

procedure TIdLexer.Warning(const AFormat: string; const AArgs: array of const);
begin
  if (FFlags and LEXFL_NOWARNINGS) <> 0 then
    Exit;
  if Assigned(FLog) then
    FLog.Warning(PrintPrefix(Format(AFormat, AArgs)));
end;

function TIdLexer.HadError: Boolean;
begin
  Result := FHadError;
end;

procedure TIdLexer.CreatePunctuationTable;
var
  LIndex, LPrevious, LNext, LFirst: Integer;
  LNewText: AnsiString;
begin
  for LIndex := 0 to 255 do
    FPunctuationTable[LIndex] := -1;
  SetLength(FNextPunctuation, System.Length(FPunctuations));
  for LIndex := 0 to High(FNextPunctuation) do
    FNextPunctuation[LIndex] := -1;
  // add the punctuations of the list to the table, longer punctuations first in each entry
  for LIndex := 0 to High(FPunctuations) do
  begin
    LNewText := FPunctuations[LIndex].Text;
    LFirst := Byte(LNewText[1]);
    LPrevious := -1;
    LNext := FPunctuationTable[LFirst];
    while LNext >= 0 do
    begin
      if System.Length(FPunctuations[LNext].Text) < System.Length(LNewText) then
      begin
        FNextPunctuation[LIndex] := LNext;
        if LPrevious >= 0 then
          FNextPunctuation[LPrevious] := LIndex
        else
          FPunctuationTable[LFirst] := LIndex;
        Break;
      end;
      LPrevious := LNext;
      LNext := FNextPunctuation[LNext];
    end;
    if LNext < 0 then
    begin
      FNextPunctuation[LIndex] := -1;
      if LPrevious >= 0 then
        FNextPunctuation[LPrevious] := LIndex
      else
        FPunctuationTable[LFirst] := LIndex;
    end;
  end;
end;

procedure TIdLexer.SetPunctuations(const APunctuations: TIdPunctuationList);
begin
  if System.Length(APunctuations) > 0 then
    FPunctuations := Copy(APunctuations)
  else
    FPunctuations := TIdPunctuations.Default;
  CreatePunctuationTable;
end;

function TIdLexer.GetPunctuationFromId(const AId: Integer): AnsiString;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FPunctuations) do
    if FPunctuations[LIndex].Id = AId then
      Exit(FPunctuations[LIndex].Text);
  Result := 'unkown punctuation';
end;

function TIdLexer.GetPunctuationId(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FPunctuations) do
    if TIdStrings.Cmp(FPunctuations[LIndex].Text, AText) = 0 then
      Exit(FPunctuations[LIndex].Id);
  Result := 0;
end;

function TIdLexer.ReadWhiteSpace: Boolean;
begin
  while True do
  begin
    // skip white space
    while Ch <= Ord(' ') do
    begin
      if Ch = 0 then
        Exit(False);
      if Ch = 10 then
        Inc(FLine);
      Inc(FScriptPosition);
    end;
    // skip comments
    if Ch = Ord('/') then
    begin
      // comments //
      if Ch(1) = Ord('/') then
      begin
        Inc(FScriptPosition);
        repeat
          Inc(FScriptPosition);
          if Ch = 0 then
            Exit(False);
        until Ch = 10;
        Inc(FLine);
        Inc(FScriptPosition);
        if Ch = 0 then
          Exit(False);
        Continue;
      end
      // comments /* */
      else if Ch(1) = Ord('*') then
      begin
        Inc(FScriptPosition);
        while True do
        begin
          Inc(FScriptPosition);
          if Ch = 0 then
            Exit(False);
          if Ch = 10 then
            Inc(FLine)
          else if Ch = Ord('/') then
          begin
            if Ch(-1) = Ord('*') then
              Break;
            if Ch(1) = Ord('*') then
              Warning('nested comment', []);
          end;
        end;
        Inc(FScriptPosition);
        if Ch = 0 then
          Exit(False);
        Inc(FScriptPosition);
        if Ch = 0 then
          Exit(False);
        Continue;
      end;
    end;
    Break;
  end;
  Result := True;
end;

function TIdLexer.ReadEscapeCharacter(out AChar: AnsiChar): Boolean;
var
  LChar, LValue: Integer;
begin
  // step over the leading '\\'
  Inc(FScriptPosition);
  // determine the escape character
  case AnsiChar(Ch) of
    '\': LChar := Ord('\');
    'n': LChar := 10;
    'r': LChar := 13;
    't': LChar := 9;
    'v': LChar := 11;
    'b': LChar := 8;
    'f': LChar := 12;
    'a': LChar := 7;
    '''': LChar := Ord('''');
    '"': LChar := Ord('"');
    '?': LChar := Ord('?');
    'x':
      begin
        Inc(FScriptPosition);
        LValue := 0;
        while True do
        begin
          LChar := Ch;
          if (LChar >= Ord('0')) and (LChar <= Ord('9')) then
            LChar := LChar - Ord('0')
          else if (LChar >= Ord('A')) and (LChar <= Ord('Z')) then
            LChar := LChar - Ord('A') + 10
          else if (LChar >= Ord('a')) and (LChar <= Ord('z')) then
            LChar := LChar - Ord('a') + 10
          else
            Break;
          LValue := (LValue shl 4) + LChar;
          Inc(FScriptPosition);
        end;
        Dec(FScriptPosition);
        if LValue > $FF then
        begin
          Warning('too large value in escape character', []);
          LValue := $FF;
        end;
        LChar := LValue;
      end;
  else
    begin
      // NOTE: decimal ASCII code, NOT octal
      if (Ch < Ord('0')) or (Ch > Ord('9')) then
        Error('unknown escape char', []);
      LValue := 0;
      while True do
      begin
        LChar := Ch;
        if (LChar >= Ord('0')) and (LChar <= Ord('9')) then
          LChar := LChar - Ord('0')
        else
          Break;
        LValue := LValue * 10 + LChar;
        Inc(FScriptPosition);
      end;
      Dec(FScriptPosition);
      if LValue > $FF then
      begin
        Warning('too large value in escape character', []);
        LValue := $FF;
      end;
      LChar := LValue;
    end;
  end;
  // step over the escape character or the last digit of the number
  Inc(FScriptPosition);
  AChar := AnsiChar(Byte(LChar and $FF));
  Result := True;
end;

function TIdLexer.ReadString(var AToken: TIdToken; const AQuote: Integer): Boolean;
var
  LTempLine, LTempPosition: Integer;
  LChar: AnsiChar;
begin
  if AQuote = Ord('"') then
    AToken.TokenType := TT_STRING
  else
    AToken.TokenType := TT_LITERAL;
  // leading quote
  Inc(FScriptPosition);
  while True do
  begin
    // if there is an escape character and escape characters are allowed
    if (Ch = Ord('\')) and ((FFlags and LEXFL_NOSTRINGESCAPECHARS) = 0) then
    begin
      if not ReadEscapeCharacter(LChar) then
        Exit(False);
      AToken.Text := AToken.Text + LChar;
    end
    // if a trailing quote
    else if Ch = AQuote then
    begin
      // step over the quote
      Inc(FScriptPosition);
      // if consecutive strings should not be concatenated
      if ((FFlags and LEXFL_NOSTRINGCONCAT) <> 0) and
        (((FFlags and LEXFL_ALLOWBACKSLASHSTRINGCONCAT) = 0) or (AQuote <> Ord('"'))) then
        Break;
      LTempPosition := FScriptPosition;
      LTempLine := FLine;
      // read white space between possible two consecutive strings
      if not ReadWhiteSpace then
      begin
        FScriptPosition := LTempPosition;
        FLine := LTempLine;
        Break;
      end;
      if (FFlags and LEXFL_NOSTRINGCONCAT) <> 0 then
      begin
        if Ch <> Ord('\') then
        begin
          FScriptPosition := LTempPosition;
          FLine := LTempLine;
          Break;
        end;
        // step over the '\\'
        Inc(FScriptPosition);
        if (not ReadWhiteSpace) or (Ch <> AQuote) then
        begin
          // the C string literal "'\'" is just ''
          Error('expecting string after '''' terminated line', []);
          Exit(False);
        end;
      end;
      // if there's no leading quote
      if Ch <> AQuote then
      begin
        FScriptPosition := LTempPosition;
        FLine := LTempLine;
        Break;
      end;
      // step over the new leading quote
      Inc(FScriptPosition);
    end
    else
    begin
      if Ch = 0 then
      begin
        Error('missing trailing quote', []);
        Exit(False);
      end;
      if Ch = 10 then
      begin
        Error('newline inside string', []);
        Exit(False);
      end;
      AToken.Text := AToken.Text + AnsiChar(Byte(Ch));
      Inc(FScriptPosition);
    end;
  end;
  if AToken.TokenType = TT_LITERAL then
  begin
    if (FFlags and LEXFL_ALLOWMULTICHARLITERALS) = 0 then
      if System.Length(AToken.Text) <> 1 then
        Warning('literal is not one character long', []);
    if System.Length(AToken.Text) > 0 then
      AToken.SubType := ShortInt(Byte(AToken.Text[1]))
    else
      AToken.SubType := 0;
  end
  else
    // the sub type is the length of the string
    AToken.SubType := System.Length(AToken.Text);
  Result := True;
end;

function TIdLexer.ReadName(var AToken: TIdToken): Boolean;
var
  LChar: Integer;
begin
  AToken.TokenType := TT_NAME;
  repeat
    AToken.Text := AToken.Text + AnsiChar(Byte(Ch));
    Inc(FScriptPosition);
    LChar := Ch;
  until not (((LChar >= Ord('a')) and (LChar <= Ord('z'))) or ((LChar >= Ord('A')) and (LChar <= Ord('Z'))) or
    ((LChar >= Ord('0')) and (LChar <= Ord('9'))) or (LChar = Ord('_')) or
    // if treating all tokens as strings, don't parse '-' as a separate token
    (((FFlags and LEXFL_ONLYSTRINGS) <> 0) and (LChar = Ord('-'))) or
    // if special path name characters are allowed
    (((FFlags and LEXFL_ALLOWPATHNAMES) <> 0) and
    ((LChar = Ord('/')) or (LChar = Ord('\')) or (LChar = Ord(':')) or (LChar = Ord('.')))));
  // the sub type is the length of the name
  AToken.SubType := System.Length(AToken.Text);
  Result := True;
end;

function TIdLexer.ReadNumber(var AToken: TIdToken): Boolean;
var
  LIndex, LDot, LChar, LChar2: Integer;

  procedure Take(const AValue: Integer);
  begin
    AToken.Text := AToken.Text + AnsiChar(Byte(AValue and $FF));
  end;

begin
  AToken.TokenType := TT_NUMBER;
  AToken.SubType := 0;
  AToken.ClearValues;
  LChar := Ch;
  LChar2 := Ch(1);
  if (LChar = Ord('0')) and (LChar2 <> Ord('.')) then
  begin
    // check for a hexadecimal number
    if (LChar2 = Ord('x')) or (LChar2 = Ord('X')) then
    begin
      Take(Ch); Inc(FScriptPosition);
      Take(Ch); Inc(FScriptPosition);
      LChar := Ch;
      while ((LChar >= Ord('0')) and (LChar <= Ord('9'))) or ((LChar >= Ord('a')) and (LChar <= Ord('f'))) or
        ((LChar >= Ord('A')) and (LChar <= Ord('F'))) do
      begin
        Take(LChar);
        Inc(FScriptPosition);
        LChar := Ch;
      end;
      AToken.SubType := TT_HEX or TT_INTEGER;
    end
    // check for a binary number
    else if (LChar2 = Ord('b')) or (LChar2 = Ord('B')) then
    begin
      Take(Ch); Inc(FScriptPosition);
      Take(Ch); Inc(FScriptPosition);
      LChar := Ch;
      while (LChar = Ord('0')) or (LChar = Ord('1')) do
      begin
        Take(LChar);
        Inc(FScriptPosition);
        LChar := Ch;
      end;
      AToken.SubType := TT_BINARY or TT_INTEGER;
    end
    // its an octal number
    else
    begin
      Take(Ch); Inc(FScriptPosition);
      LChar := Ch;
      while (LChar >= Ord('0')) and (LChar <= Ord('7')) do
      begin
        Take(LChar);
        Inc(FScriptPosition);
        LChar := Ch;
      end;
      AToken.SubType := TT_OCTAL or TT_INTEGER;
    end;
  end
  else
  begin
    // decimal integer or floating point number or ip address
    LDot := 0;
    while True do
    begin
      if (LChar >= Ord('0')) and (LChar <= Ord('9')) then
      begin
      end
      else if LChar = Ord('.') then
        Inc(LDot)
      else
        Break;
      Take(LChar);
      Inc(FScriptPosition);
      LChar := Ch;
    end;
    if (LChar = Ord('e')) and (LDot = 0) then
      // scientific notation without a decimal point
      Inc(LDot);
    // if a floating point number
    if LDot = 1 then
    begin
      AToken.SubType := TT_DECIMAL or TT_FLOAT;
      // check for floating point exponent
      if LChar = Ord('e') then
      begin
        // append the e so that the value code works
        Take(LChar);
        Inc(FScriptPosition);
        LChar := Ch;
        if LChar = Ord('-') then
        begin
          Take(LChar);
          Inc(FScriptPosition);
          LChar := Ch;
        end
        else if LChar = Ord('+') then
        begin
          Take(LChar);
          Inc(FScriptPosition);
          LChar := Ch;
        end;
        while (LChar >= Ord('0')) and (LChar <= Ord('9')) do
        begin
          Take(LChar);
          Inc(FScriptPosition);
          LChar := Ch;
        end;
      end
      // check for floating point exception infinite 1.#INF or indefinite 1.#IND or NaN
      else if LChar = Ord('#') then
      begin
        // the original tests CheckString( "INF" ), "IND", "NAN", "QNAN" and "SNAN" here, but the
        // position is still on the '#', so none of them can match (a defect kept, see README): the
        // flags TT_INFINITE, TT_INDEFINITE and TT_NAN are never set and four characters are taken
        LChar2 := 4;
        for LIndex := 0 to LChar2 - 1 do
        begin
          Take(LChar);
          Inc(FScriptPosition);
          LChar := Ch;
        end;
        while (LChar >= Ord('0')) and (LChar <= Ord('9')) do
        begin
          Take(LChar);
          Inc(FScriptPosition);
          LChar := Ch;
        end;
        if (FFlags and LEXFL_ALLOWFLOATEXCEPTIONS) = 0 then
        begin
          // zero terminate for the message: the original appends a NUL that stays in the token
          AToken.Text := AToken.Text + #0;
          Error('parsed %s', [CText(AToken.Text)]);
        end;
      end;
    end
    else if LDot > 1 then
    begin
      if (FFlags and LEXFL_ALLOWIPADDRESSES) = 0 then
      begin
        Error('more than one dot in number', []);
        Exit(False);
      end;
      if LDot <> 3 then
      begin
        Error('ip address should have three dots', []);
        Exit(False);
      end;
      AToken.SubType := TT_IPADDRESS;
    end
    else
      AToken.SubType := TT_DECIMAL or TT_INTEGER;
  end;
  if (AToken.SubType and TT_FLOAT) <> 0 then
  begin
    if LChar > Ord(' ') then
    begin
      // single-precision: float
      if (LChar = Ord('f')) or (LChar = Ord('F')) then
      begin
        AToken.SubType := AToken.SubType or TT_SINGLE_PRECISION;
        Inc(FScriptPosition);
      end
      // extended-precision: long double
      else if (LChar = Ord('l')) or (LChar = Ord('L')) then
      begin
        AToken.SubType := AToken.SubType or TT_EXTENDED_PRECISION;
        Inc(FScriptPosition);
      end
      // default is double-precision: double
      else
        AToken.SubType := AToken.SubType or TT_DOUBLE_PRECISION;
    end
    else
      AToken.SubType := AToken.SubType or TT_DOUBLE_PRECISION;
  end
  else if (AToken.SubType and TT_INTEGER) <> 0 then
  begin
    if LChar > Ord(' ') then
    begin
      // default: signed long
      for LIndex := 0 to 1 do
      begin
        // long integer
        if (LChar = Ord('l')) or (LChar = Ord('L')) then
          AToken.SubType := AToken.SubType or TT_LONG
        // unsigned integer
        else if (LChar = Ord('u')) or (LChar = Ord('U')) then
          AToken.SubType := AToken.SubType or TT_UNSIGNED
        else
          Break;
        Inc(FScriptPosition);
        LChar := Ch;
      end;
    end;
  end
  else if (AToken.SubType and TT_IPADDRESS) <> 0 then
  begin
    if LChar = Ord(':') then
    begin
      Take(LChar);
      Inc(FScriptPosition);
      LChar := Ch;
      while (LChar >= Ord('0')) and (LChar <= Ord('9')) do
      begin
        Take(LChar);
        Inc(FScriptPosition);
        LChar := Ch;
      end;
      AToken.SubType := AToken.SubType or TT_IPPORT;
    end;
  end;
  Result := True;
end;

function TIdLexer.ReadPunctuation(var AToken: TIdToken): Boolean;
var
  LNode, LLength: Integer;
  LText: AnsiString;
begin
  LNode := FPunctuationTable[Ch and $FF];
  while LNode >= 0 do
  begin
    LText := FPunctuations[LNode].Text;
    // check for this punctuation in the script
    LLength := 0;
    while (LLength < System.Length(LText)) and (Ch(LLength) <> 0) do
    begin
      if Ch(LLength) <> ShortInt(Byte(LText[LLength + 1])) then
        Break;
      Inc(LLength);
    end;
    if LLength >= System.Length(LText) then
    begin
      AToken.Text := LText;
      Inc(FScriptPosition, LLength);
      AToken.TokenType := TT_PUNCTUATION;
      // sub type is the punctuation id
      AToken.SubType := FPunctuations[LNode].Id;
      Exit(True);
    end;
    LNode := FNextPunctuation[LNode];
  end;
  Result := False;
end;

function TIdLexer.ReadToken(var AToken: TIdToken): Boolean;
var
  LChar: Integer;
begin
  if not FLoaded then
    raise EIdLexerException.Create('idLexer::ReadToken: no file loaded');
  // if there is a token available (from UnreadToken)
  if FTokenAvailable then
  begin
    FTokenAvailable := False;
    AToken := FToken;
    Exit(True);
  end;
  // save script pointer and line counter
  FLastScriptPosition := FScriptPosition;
  FLastLine := FLine;
  // clear the token stuff
  AToken.Text := '';
  // start of the white space
  FWhiteSpaceStart := FScriptPosition;
  AToken.WhiteSpaceStart := FScriptPosition;
  // read white space before token
  if not ReadWhiteSpace then
    Exit(False);
  // end of the white space
  FWhiteSpaceEnd := FScriptPosition;
  AToken.WhiteSpaceEnd := FScriptPosition;
  // line the token is on
  AToken.Line := FLine;
  // number of lines crossed before token
  AToken.LinesCrossed := FLine - FLastLine;
  // clear token flags
  AToken.Flags := 0;
  LChar := Ch;
  // if we're keeping everything as white space delimited strings
  if (FFlags and LEXFL_ONLYSTRINGS) <> 0 then
  begin
    // if there is a leading quote
    if (LChar = Ord('"')) or (LChar = Ord('''')) then
    begin
      if not ReadString(AToken, LChar) then
        Exit(False);
    end
    else if not ReadName(AToken) then
      Exit(False);
  end
  // if there is a number
  else if ((LChar >= Ord('0')) and (LChar <= Ord('9'))) or
    ((LChar = Ord('.')) and ((Ch(1) >= Ord('0')) and (Ch(1) <= Ord('9')))) then
  begin
    if not ReadNumber(AToken) then
      Exit(False);
    // if names are allowed to start with a number
    if (FFlags and LEXFL_ALLOWNUMBERNAMES) <> 0 then
    begin
      LChar := Ch;
      if ((LChar >= Ord('a')) and (LChar <= Ord('z'))) or ((LChar >= Ord('A')) and (LChar <= Ord('Z'))) or
        (LChar = Ord('_')) then
        if not ReadName(AToken) then
          Exit(False);
    end;
  end
  // if there is a leading quote
  else if (LChar = Ord('"')) or (LChar = Ord('''')) then
  begin
    if not ReadString(AToken, LChar) then
      Exit(False);
  end
  // if there is a name
  else if ((LChar >= Ord('a')) and (LChar <= Ord('z'))) or ((LChar >= Ord('A')) and (LChar <= Ord('Z'))) or
    (LChar = Ord('_')) then
  begin
    if not ReadName(AToken) then
      Exit(False);
  end
  // names may also start with a slash when path names are allowed
  else if ((FFlags and LEXFL_ALLOWPATHNAMES) <> 0) and
    ((LChar = Ord('/')) or (LChar = Ord('\')) or (LChar = Ord('.'))) then
  begin
    if not ReadName(AToken) then
      Exit(False);
  end
  // check for punctuations
  else if not ReadPunctuation(AToken) then
  begin
    Error('unknown punctuation %s', [string(AnsiChar(Byte(LChar and $FF)))]);
    Exit(False);
  end;
  // successfully read a token
  Result := True;
end;

function TIdLexer.ExpectTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
  begin
    Error('couldn''t find expected ''%s''', [CText(AText)]);
    Exit(False);
  end;
  if not LToken.IsText(AText) then
  begin
    Error('expected ''%s'' but found ''%s''', [CText(AText), CText(LToken.Text)]);
    Exit(False);
  end;
  Result := True;
end;

function TIdLexer.ExpectTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
var
  LText: TIdStr;
begin
  if not ReadToken(AToken) then
  begin
    Error('couldn''t read expected token', []);
    Exit(False);
  end;
  if AToken.TokenType <> AType then
  begin
    case AType of
      TT_STRING: LText := 'string';
      TT_LITERAL: LText := 'literal';
      TT_NUMBER: LText := 'number';
      TT_NAME: LText := 'name';
      TT_PUNCTUATION: LText := 'punctuation';
    else
      LText := 'unknown type';
    end;
    Error('expected a %s but found ''%s''', [CText(LText.Text), CText(AToken.Text)]);
    Exit(False);
  end;
  if AToken.TokenType = TT_NUMBER then
  begin
    if (AToken.SubType and ASubType) <> ASubType then
    begin
      LText.Clear;
      if (ASubType and TT_DECIMAL) <> 0 then
        LText := 'decimal ';
      if (ASubType and TT_HEX) <> 0 then
        LText := 'hex ';
      if (ASubType and TT_OCTAL) <> 0 then
        LText := 'octal ';
      if (ASubType and TT_BINARY) <> 0 then
        LText := 'binary ';
      if (ASubType and TT_UNSIGNED) <> 0 then
        LText.Append('unsigned ');
      if (ASubType and TT_LONG) <> 0 then
        LText.Append('long ');
      if (ASubType and TT_FLOAT) <> 0 then
        LText.Append('float ');
      if (ASubType and TT_INTEGER) <> 0 then
        LText.Append('integer ');
      LText.StripTrailing(' ');
      Error('expected %s but found ''%s''', [CText(LText.Text), CText(AToken.Text)]);
      Exit(False);
    end;
  end
  else if AToken.TokenType = TT_PUNCTUATION then
  begin
    if ASubType < 0 then
    begin
      Error('BUG: wrong punctuation subtype', []);
      Exit(False);
    end;
    if AToken.SubType <> ASubType then
    begin
      Error('expected ''%s'' but found ''%s''', [string(GetPunctuationFromId(ASubType)), CText(AToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

function TIdLexer.ExpectAnyToken(var AToken: TIdToken): Boolean;
begin
  if not ReadToken(AToken) then
  begin
    Error('couldn''t read expected token', []);
    Exit(False);
  end;
  Result := True;
end;

function TIdLexer.CheckTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
    Exit(False);
  // if the given string is available
  if LToken.IsText(AText) then
    Exit(True);
  // unread token
  FScriptPosition := FLastScriptPosition;
  FLine := FLastLine;
  Result := False;
end;

function TIdLexer.CheckTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
    Exit(False);
  // if the type matches
  if (LToken.TokenType = AType) and ((LToken.SubType and ASubType) = ASubType) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  // unread token
  FScriptPosition := FLastScriptPosition;
  FLine := FLastLine;
  Result := False;
end;

function TIdLexer.PeekTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
    Exit(False);
  // unread token
  FScriptPosition := FLastScriptPosition;
  FLine := FLastLine;
  Result := LToken.IsText(AText);
end;

function TIdLexer.PeekTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
    Exit(False);
  // unread token
  FScriptPosition := FLastScriptPosition;
  FLine := FLastLine;
  // if the type matches
  if (LToken.TokenType = AType) and ((LToken.SubType and ASubType) = ASubType) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  Result := False;
end;

function TIdLexer.SkipUntilString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  while ReadToken(LToken) do
    if LToken.IsText(AText) then
      Exit(True);
  Result := False;
end;

function TIdLexer.SkipRestOfLine: Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  while ReadToken(LToken) do
    if LToken.LinesCrossed <> 0 then
    begin
      FScriptPosition := FLastScriptPosition;
      FLine := FLastLine;
      Exit(True);
    end;
  Result := False;
end;

function TIdLexer.SkipBracedSection(const AParseFirstBrace: Boolean): Boolean;
var
  LToken: TIdToken;
  LDepth: Integer;
begin
  LToken := TIdToken.Create;
  if AParseFirstBrace then
    LDepth := 0
  else
    LDepth := 1;
  repeat
    if not ReadToken(LToken) then
      Exit(False);
    if LToken.TokenType = TT_PUNCTUATION then
    begin
      if LToken.IsText('{') then
        Inc(LDepth)
      else if LToken.IsText('}') then
        Dec(LDepth);
    end;
  until LDepth = 0;
  Result := True;
end;

procedure TIdLexer.UnreadToken(const AToken: TIdToken);
begin
  if FTokenAvailable then
    raise EIdLibFatalException.Create('idLexer::unreadToken, unread token twice'#10);
  FToken := AToken;
  FTokenAvailable := True;
end;

function TIdLexer.ReadTokenOnLine(var AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
  begin
    FScriptPosition := FLastScriptPosition;
    FLine := FLastLine;
    Exit(False);
  end;
  // if no lines were crossed before this token
  if LToken.LinesCrossed = 0 then
  begin
    AToken := LToken;
    Exit(True);
  end;
  // restore our position
  FScriptPosition := FLastScriptPosition;
  FLine := FLastLine;
  AToken.Text := '';
  Result := False;
end;

function TIdLexer.ReadRestOfLine(var AOutput: AnsiString): AnsiString;
var
  LText: TIdStr;
begin
  LText := AOutput;
  while True do
  begin
    if Ch = 10 then
    begin
      Inc(FLine);
      Break;
    end;
    if Ch = 0 then
      Break;
    if Ch <= Ord(' ') then
      LText.Append(' ')
    else
      LText.Append(AnsiChar(Byte(Ch)));
    Inc(FScriptPosition);
  end;
  LText.Strip(' ');
  AOutput := LText.Text;
  Result := AOutput;
end;

function TIdLexer.ParseInt: Integer;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ReadToken(LToken) then
  begin
    Error('couldn''t read expected integer', []);
    Exit(0);
  end;
  if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('-') then
  begin
    ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
    Exit(-LToken.GetIntValue);
  end
  else if (LToken.TokenType <> TT_NUMBER) or (LToken.SubType = TT_FLOAT) then
    Error('expected integer value, found ''%s''', [CText(LToken.Text)]);
  Result := LToken.GetIntValue;
end;

function TIdLexer.ParseBool: Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ExpectTokenType(TT_NUMBER, 0, LToken) then
  begin
    Error('couldn''t read expected boolean', []);
    Exit(False);
  end;
  Result := LToken.GetIntValue <> 0;
end;

function TIdLexer.ParseFloat(const AErrorFlag: PBoolean): Single;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if Assigned(AErrorFlag) then
    AErrorFlag^ := False;
  if not ReadToken(LToken) then
  begin
    if Assigned(AErrorFlag) then
    begin
      Warning('couldn''t read expected floating point number', []);
      AErrorFlag^ := True;
    end
    else
      Error('couldn''t read expected floating point number', []);
    Exit(0);
  end;
  if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('-') then
  begin
    ExpectTokenType(TT_NUMBER, 0, LToken);
    Exit(-LToken.GetFloatValue);
  end
  else if LToken.TokenType <> TT_NUMBER then
  begin
    if Assigned(AErrorFlag) then
    begin
      Warning('expected float value, found ''%s''', [CText(LToken.Text)]);
      AErrorFlag^ := True;
    end
    else
      Error('expected float value, found ''%s''', [CText(LToken.Text)]);
  end;
  Result := LToken.GetFloatValue;
end;

function TIdLexer.Parse1DMatrix(const AX: Integer; var AMatrix: array of Single; const AOffset: Integer): Boolean;
var
  LIndex: Integer;
begin
  if not ExpectTokenString('(') then
    Exit(False);
  for LIndex := 0 to AX - 1 do
    AMatrix[AOffset + LIndex] := ParseFloat;
  if not ExpectTokenString(')') then
    Exit(False);
  Result := True;
end;

function TIdLexer.Parse2DMatrix(const AY, AX: Integer; var AMatrix: array of Single; const AOffset: Integer): Boolean;
var
  LIndex: Integer;
begin
  if not ExpectTokenString('(') then
    Exit(False);
  for LIndex := 0 to AY - 1 do
    if not Parse1DMatrix(AX, AMatrix, AOffset + LIndex * AX) then
      Exit(False);
  if not ExpectTokenString(')') then
    Exit(False);
  Result := True;
end;

function TIdLexer.Parse3DMatrix(const AZ, AY, AX: Integer; var AMatrix: array of Single): Boolean;
var
  LIndex: Integer;
begin
  if not ExpectTokenString('(') then
    Exit(False);
  for LIndex := 0 to AZ - 1 do
    if not Parse2DMatrix(AY, AX, AMatrix, LIndex * AX * AY) then
      Exit(False);
  if not ExpectTokenString(')') then
    Exit(False);
  Result := True;
end;

function TIdLexer.ParseBracedSectionExact(var AOutput: AnsiString; ATabs: Integer): AnsiString;
var
  LDepth, LIndex: Integer;
  LDoTabs, LSkipWhite: Boolean;
  LChar: AnsiChar;
  LNext: Boolean;
begin
  AOutput := '';
  if not ExpectTokenString('{') then
    Exit(AOutput);
  AOutput := '{';
  LDepth := 1;
  LSkipWhite := False;
  LDoTabs := ATabs >= 0;
  while (LDepth <> 0) and (Ch <> 0) do
  begin
    LChar := AnsiChar(Byte(Ch));
    Inc(FScriptPosition);
    LNext := False;
    case LChar of
      #9, ' ':
        if LSkipWhite then
          LNext := True;
      #10:
        if LDoTabs then
        begin
          LSkipWhite := True;
          AOutput := AOutput + LChar;
          LNext := True;
        end;
      '{':
        begin
          Inc(LDepth);
          Inc(ATabs);
        end;
      '}':
        begin
          Dec(LDepth);
          Dec(ATabs);
        end;
    end;
    if LNext then
      Continue;
    if LSkipWhite then
    begin
      LIndex := ATabs;
      if LChar = '{' then
        Dec(LIndex);
      LSkipWhite := False;
      while LIndex > 0 do
      begin
        AOutput := AOutput + #9;
        Dec(LIndex);
      end;
    end;
    AOutput := AOutput + LChar;
  end;
  Result := AOutput;
end;

function TIdLexer.ParseBracedSection(var AOutput: AnsiString): AnsiString;
var
  LToken: TIdToken;
  LIndex, LDepth: Integer;
begin
  LToken := TIdToken.Create;
  AOutput := '';
  if not ExpectTokenString('{') then
    Exit(AOutput);
  AOutput := '{';
  LDepth := 1;
  repeat
    if not ReadToken(LToken) then
    begin
      Error('missing closing brace', []);
      Exit(AOutput);
    end;
    // if the token is on a new line
    for LIndex := 0 to LToken.LinesCrossed - 1 do
      AOutput := AOutput + #13#10;
    if LToken.TokenType = TT_PUNCTUATION then
    begin
      if (System.Length(LToken.Text) > 0) and (LToken.Text[1] = '{') then
        Inc(LDepth)
      else if (System.Length(LToken.Text) > 0) and (LToken.Text[1] = '}') then
        Dec(LDepth);
    end;
    if LToken.TokenType = TT_STRING then
      AOutput := AOutput + '"' + LToken.Text + '"'
    else
      AOutput := AOutput + LToken.Text;
    AOutput := AOutput + ' ';
  until LDepth = 0;
  Result := AOutput;
end;

function TIdLexer.ParseRestOfLine(var AOutput: AnsiString): AnsiString;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  AOutput := '';
  while ReadToken(LToken) do
  begin
    if LToken.LinesCrossed <> 0 then
    begin
      FScriptPosition := FLastScriptPosition;
      FLine := FLastLine;
      Break;
    end;
    if System.Length(AOutput) > 0 then
      AOutput := AOutput + ' ';
    AOutput := AOutput + LToken.Text;
  end;
  Result := AOutput;
end;

function TIdLexer.GetLastWhiteSpace(var AWhiteSpace: AnsiString): Integer;
begin
  AWhiteSpace := '';
  if (FWhiteSpaceStart >= 0) and (FWhiteSpaceEnd > FWhiteSpaceStart) then
    AWhiteSpace := Copy(FBuffer, FWhiteSpaceStart + 1, FWhiteSpaceEnd - FWhiteSpaceStart);
  Result := System.Length(AWhiteSpace);
end;

function TIdLexer.GetLastWhiteSpaceStart: Integer;
begin
  Result := FWhiteSpaceStart;
end;

function TIdLexer.GetLastWhiteSpaceEnd: Integer;
begin
  Result := FWhiteSpaceEnd;
end;

procedure TIdLexer.Reset;
begin
  FScriptPosition := 0;
  FLastScriptPosition := 0;
  FWhiteSpaceStart := -1;
  FWhiteSpaceEnd := -1;
  FTokenAvailable := False;
  FLine := 1;
  FLastLine := 1;
  FToken := TIdToken.Create;
end;

function TIdLexer.EndOfFile: Boolean;
begin
  Result := FScriptPosition >= FEndPosition;
end;

function TIdLexer.NumLinesCrossed: Integer;
begin
  Result := FLine - FLastLine;
end;

function TIdLexer.GetFileOffset: Integer;
begin
  Result := FScriptPosition;
end;

function TIdLexer.GetBufferText(const AStart, AEnd: Integer): AnsiString;
var
  LStart, LEnd: Integer;
begin
  LStart := AStart;
  LEnd := AEnd;
  if LStart < 0 then
    LStart := 0;
  if LEnd > System.Length(FBuffer) then
    LEnd := System.Length(FBuffer);
  if LEnd <= LStart then
    Exit('');
  Result := Copy(FBuffer, LStart + 1, LEnd - LStart);
end;

function TIdLexer.IsLoaded: Boolean;
begin
  Result := FLoaded;
end;

function TIdLexer.LoadFile(const AFileName: AnsiString; const AIsOsPath: Boolean): Boolean;
var
  LPath: AnsiString;
  LFile: TIdLibFileData;
begin
  if FLoaded then
    raise EIdLibException.Create('idLexer::LoadFile: another script already loaded');
  if (not AIsOsPath) and (FBaseFolder <> '') then
    LPath := FBaseFolder + '/' + AFileName
  else
    LPath := AFileName;
  if (not Assigned(FFileSystem)) or (not FFileSystem.TryReadFile(LPath, AIsOsPath, LFile)) then
    Exit(False);
  SetLength(FBuffer, Length(LFile.Data));
  if Length(LFile.Data) > 0 then
    Move(LFile.Data[0], FBuffer[1], Length(LFile.Data));
  FFileTime := LFile.Timestamp;
  FFileName := LFile.FullPath;
  FLength := Length(LFile.Data);
  FScriptPosition := 0;
  FLastScriptPosition := 0;
  FEndPosition := FLength;
  FTokenAvailable := False;
  FLine := 1;
  FLastLine := 1;
  FLoaded := True;
  Result := True;
end;

function TIdLexer.LoadMemory(const AText: AnsiString; const ALength: Integer; const AName: AnsiString;
  const AStartLine: Integer): Boolean;
begin
  if FLoaded then
    raise EIdLibException.Create('idLexer::LoadMemory: another script already loaded');
  FFileName := AName;
  FBuffer := Copy(AText, 1, ALength);
  FFileTime := 0;
  FLength := ALength;
  FScriptPosition := 0;
  FLastScriptPosition := 0;
  FEndPosition := ALength;
  FTokenAvailable := False;
  FLine := AStartLine;
  FLastLine := AStartLine;
  FLoaded := True;
  Result := True;
end;

function TIdLexer.LoadMemory(const AText: AnsiString; const AName: AnsiString): Boolean;
begin
  Result := LoadMemory(AText, System.Length(AText), AName, 1);
end;

procedure TIdLexer.FreeSource;
begin
  FBuffer := '';
  FTokenAvailable := False;
  FToken := TIdToken.Create;
  FLoaded := False;
end;

end.
