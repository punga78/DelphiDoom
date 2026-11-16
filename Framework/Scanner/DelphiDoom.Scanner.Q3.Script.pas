{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3Script, the lexer of the scripts of        }
{  Quake III Arena                                                             }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_script.c. Copyright (C) 1999-2005 Id Software, Inc. Licensed under the    }
{  GNU General Public License, version 2 or later.                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Script;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.SoftExtended, DelphiDoom.Scanner.Q3.Types,
  DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Scanner.Q3.Punctuations;

type
  /// <summary>
  ///   script_t: a text, the position in it and the token reader. Where the C reads bytes through a
  ///   signed char (everything above 127 is white space) so does this class. The text is read to the
  ///   first zero byte; the end that EndOfScript compares with is given by the creator (LoadScriptFile
  ///   takes it before the text is compressed, so a compressed script is never "at the end")
  /// </summary>
  TQ3Script = class sealed
  strict private
    FLog: IQ3ScriptLog;
    FFileName: AnsiString;
    FBuffer: TBytes;
    FScriptP: Integer;
    FEndP: Integer;
    FLastScriptP: Integer;
    FWhitespaceP: Integer;
    FEndWhitespaceP: Integer;
    FLength: Integer;
    FLine: Integer;
    FLastLine: Integer;
    FTokenAvailable: Boolean;
    FFlags: Integer;
    FPunctuations: TQ3PunctuationTable;
    FToken: TQ3Token;
    FNext: TQ3Script;
    FTag: Integer;
    function Ch(const AOffset: Integer): Integer; inline;
    procedure ScriptError(const AText: AnsiString);
    procedure ScriptWarning(const AText: AnsiString);
    function ReadWhiteSpace: Boolean;
    function ReadEscapeCharacter(out AChar: Byte): Boolean;
    function ReadString(var AToken: TQ3Token; const AQuote: AnsiChar): Boolean;
    function ReadName(var AToken: TQ3Token): Boolean;
    function ReadNumber(var AToken: TQ3Token): Boolean;
    function ReadPunctuation(var AToken: TQ3Token): Boolean;
    function ReadPrimitive(var AToken: TQ3Token): Boolean;
    class function CString(const AText: AnsiString): AnsiString; static;
  public
    /// <summary>
    ///   AText is the text of the script (no terminator needed), AEndOffset the value of end_p (the length
    ///   of the text for a script from memory); the punctuations are the default ones
    /// </summary>
    constructor Create(const ALog: IQ3ScriptLog; const AFileName: AnsiString; const AText: TBytes;
      const AEndOffset: Integer);
    destructor Destroy; override;
    /// <summary>NumberValue: the integer and floating point value of the text of a number token</summary>
    class procedure NumberValue(const AText: AnsiString; const ASubtype: Integer; out AIntValue: Cardinal;
      out AFloatValue: TSoftExtended); static;
    /// <summary>SetScriptPunctuations (empty: the default C/C++ set)</summary>
    procedure SetPunctuations(const APunctuations: TQ3PunctuationArray);
    /// <summary>PS_ReadToken</summary>
    function ReadToken(var AToken: TQ3Token): Boolean;
    /// <summary>PS_ExpectTokenString</summary>
    function ExpectTokenString(const AText: AnsiString): Boolean;
    /// <summary>PS_ExpectTokenType</summary>
    function ExpectTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
    /// <summary>PS_ExpectAnyToken</summary>
    function ExpectAnyToken(var AToken: TQ3Token): Boolean;
    /// <summary>PS_CheckTokenString</summary>
    function CheckTokenString(const AText: AnsiString): Boolean;
    /// <summary>PS_CheckTokenType</summary>
    function CheckTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
    /// <summary>PS_SkipUntilString</summary>
    function SkipUntilString(const AText: AnsiString): Boolean;
    /// <summary>PS_UnreadLastToken</summary>
    procedure UnreadLastToken;
    /// <summary>PS_UnreadToken</summary>
    procedure UnreadToken(const AToken: TQ3Token);
    /// <summary>PS_NextWhiteSpaceChar: the next character of the white space read before the token, 0 if none</summary>
    function NextWhiteSpaceChar: Byte;
    /// <summary>ReadSignedInt</summary>
    function ReadSignedInt: Integer;
    /// <summary>ReadSignedFloat</summary>
    function ReadSignedFloat: TSoftExtended;
    /// <summary>ResetScript</summary>
    procedure Reset;
    /// <summary>EndOfScript</summary>
    function EndOfScript: Boolean;
    /// <summary>ScriptSkipTo</summary>
    function SkipTo(const AText: AnsiString): Boolean;
    /// <summary>PunctuationFromNum</summary>
    function PunctuationFromNumber(const ANumber: Integer): AnsiString;
    /// <summary>StripDoubleQuotes</summary>
    class procedure StripDoubleQuotes(var AText: AnsiString); static;
    /// <summary>StripSingleQuotes</summary>
    class procedure StripSingleQuotes(var AText: AnsiString); static;
    /// <summary>
    ///   An identity that a source gives to the scripts it stacks (the indents of the C compare the
    ///   address of the script, which a script freed and a new one can share: a number cannot)
    /// </summary>
    property Tag: Integer read FTag write FTag;
    property FileName: AnsiString read FFileName write FFileName;
    property Flags: Integer read FFlags write FFlags;
    property Line: Integer read FLine write FLine;
    property LastLine: Integer read FLastLine;
    /// <summary>script_p: the offset of the next byte to read</summary>
    property Position: Integer read FScriptP write FScriptP;
    property LastPosition: Integer read FLastScriptP;
    property TextLength: Integer read FLength;
    /// <summary>The script that included this one (the stack of a source)</summary>
    property Next: TQ3Script read FNext write FNext;
    property LastToken: TQ3Token read FToken;
  end;

implementation

{ TQ3Script }

constructor TQ3Script.Create(const ALog: IQ3ScriptLog; const AFileName: AnsiString; const AText: TBytes;
  const AEndOffset: Integer);
var
  LSize: Integer;
begin
  inherited Create;
  FLog := ALog;
  FFileName := CString(AFileName);
  LSize := System.Length(AText);
  if AEndOffset > LSize then
    LSize := AEndOffset;
  // zero bytes after the text: a look ahead from the last byte reads a zero
  SetLength(FBuffer, LSize + 16);
  if System.Length(AText) > 0 then
    Move(AText[0], FBuffer[0], System.Length(AText));
  FLength := System.Length(AText);
  FEndP := AEndOffset;
  FPunctuations := TQ3PunctuationTable.Create(nil);
  FWhitespaceP := -1;
  FEndWhitespaceP := -1;
  FLine := 1;
  FLastLine := 1;
end;

destructor TQ3Script.Destroy;
begin
  FPunctuations.Free;
  inherited;
end;

function TQ3Script.Ch(const AOffset: Integer): Integer;
begin
  if (AOffset >= 0) and (AOffset < System.Length(FBuffer)) then
    Result := ShortInt(FBuffer[AOffset])
  else
    Result := 0;
end;

class function TQ3Script.CString(const AText: AnsiString): AnsiString;
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < System.Length(AText)) and (AText[LLength + 1] <> #0) do
    Inc(LLength);
  Result := Copy(AText, 1, LLength);
end;

procedure TQ3Script.ScriptError(const AText: AnsiString);
begin
  if (FFlags and SCFL_NOERRORS) <> 0 then
    Exit;
  if Assigned(FLog) then
    FLog.Print(Q3_PRT_ERROR, 'file ' + FFileName + ', line ' + AnsiString(IntToStr(FLine)) + ': ' + AText + #10);
end;

procedure TQ3Script.ScriptWarning(const AText: AnsiString);
begin
  if (FFlags and SCFL_NOWARNINGS) <> 0 then
    Exit;
  if Assigned(FLog) then
    FLog.Print(Q3_PRT_WARNING, 'file ' + FFileName + ', line ' + AnsiString(IntToStr(FLine)) + ': ' + AText + #10);
end;

procedure TQ3Script.SetPunctuations(const APunctuations: TQ3PunctuationArray);
begin
  FPunctuations.Free;
  FPunctuations := TQ3PunctuationTable.Create(APunctuations);
end;

function TQ3Script.PunctuationFromNumber(const ANumber: Integer): AnsiString;
begin
  Result := FPunctuations.TextFromNumber(ANumber);
end;

// Reads spaces, tabs, C-like comments etc. When a newline is found the line counter is increased
function TQ3Script.ReadWhiteSpace: Boolean;
begin
  while True do
  begin
    // skip white space (a signed char: every byte above 127 is white space)
    while Ch(FScriptP) <= 32 do
    begin
      if Ch(FScriptP) = 0 then
        Exit(False);
      if Ch(FScriptP) = 10 then
        Inc(FLine);
      Inc(FScriptP);
    end;
    // skip comments
    if Ch(FScriptP) = Ord('/') then
    begin
      // comments //
      if Ch(FScriptP + 1) = Ord('/') then
      begin
        Inc(FScriptP);
        repeat
          Inc(FScriptP);
          if Ch(FScriptP) = 0 then
            Exit(False);
        until Ch(FScriptP) = 10;
        Inc(FLine);
        Inc(FScriptP);
        if Ch(FScriptP) = 0 then
          Exit(False);
        Continue;
      end
      // comments /* */
      else if Ch(FScriptP + 1) = Ord('*') then
      begin
        Inc(FScriptP);
        repeat
          Inc(FScriptP);
          if Ch(FScriptP) = 0 then
            Exit(False);
          if Ch(FScriptP) = 10 then
            Inc(FLine);
        until (Ch(FScriptP) = Ord('*')) and (Ch(FScriptP + 1) = Ord('/'));
        Inc(FScriptP);
        if Ch(FScriptP) = 0 then
          Exit(False);
        Inc(FScriptP);
        if Ch(FScriptP) = 0 then
          Exit(False);
        Continue;
      end;
    end;
    Break;
  end;
  Result := True;
end;

// Reads an escape character; the decimal code is NOT octal
function TQ3Script.ReadEscapeCharacter(out AChar: Byte): Boolean;
var
  LChar: Integer;
  LValue: Integer;
begin
  // step over the leading '\\'
  Inc(FScriptP);
  case Ch(FScriptP) of
    Ord('\'): LChar := Ord('\');
    Ord('n'): LChar := 10;
    Ord('r'): LChar := 13;
    Ord('t'): LChar := 9;
    Ord('v'): LChar := 11;
    Ord('b'): LChar := 8;
    Ord('f'): LChar := 12;
    Ord('a'): LChar := 7;
    Ord(''''): LChar := Ord('''');
    Ord('"'): LChar := Ord('"');
    Ord('?'): LChar := Ord('?');
    Ord('x'):
      begin
        Inc(FScriptP);
        LValue := 0;
        while True do
        begin
          LChar := Ch(FScriptP);
          if (LChar >= Ord('0')) and (LChar <= Ord('9')) then
            LChar := LChar - Ord('0')
          else if (LChar >= Ord('A')) and (LChar <= Ord('Z')) then
            LChar := LChar - Ord('A') + 10
          else if (LChar >= Ord('a')) and (LChar <= Ord('z')) then
            LChar := LChar - Ord('a') + 10
          else
            Break;
          LValue := (LValue shl 4) + LChar;
          Inc(FScriptP);
        end;
        Dec(FScriptP);
        if LValue > $FF then
        begin
          ScriptWarning('too large value in escape character');
          LValue := $FF;
        end;
        LChar := LValue;
      end;
  else
    // decimal ASCII code
    begin
      if (Ch(FScriptP) < Ord('0')) or (Ch(FScriptP) > Ord('9')) then
        ScriptError('unknown escape char');
      LValue := 0;
      while True do
      begin
        LChar := Ch(FScriptP);
        if (LChar >= Ord('0')) and (LChar <= Ord('9')) then
          LChar := LChar - Ord('0')
        else
          Break;
        LValue := LValue * 10 + LChar;
        Inc(FScriptP);
      end;
      Dec(FScriptP);
      if LValue > $FF then
      begin
        ScriptWarning('too large value in escape character');
        LValue := $FF;
      end;
      LChar := LValue;
    end;
  end;
  // step over the escape character or the last digit of the number
  Inc(FScriptP);
  AChar := Byte(LChar and $FF);
  Result := True;
end;

// Reads a C-like string with the quotes; two strings with white space between them are one string
function TQ3Script.ReadString(var AToken: TQ3Token; const AQuote: AnsiChar): Boolean;
var
  LRaw: AnsiString;
  LChar: Byte;
  LTempP: Integer;
  LTempLine: Integer;
begin
  if AQuote = '"' then
    AToken.TokenType := TT_STRING
  else
    AToken.TokenType := TT_LITERAL;
  // leading quote
  LRaw := AnsiChar(FBuffer[FScriptP]);
  Inc(FScriptP);
  while True do
  begin
    // minus 2 because trailing double quote and zero have to be appended
    if System.Length(LRaw) >= Q3_MAX_TOKEN - 2 then
    begin
      AToken.Text := CString(LRaw);
      ScriptError('string longer than MAX_TOKEN = ' + AnsiString(IntToStr(Q3_MAX_TOKEN)));
      Exit(False);
    end;
    // an escape character, if allowed inside a string
    if (Ch(FScriptP) = Ord('\')) and ((FFlags and SCFL_NOSTRINGESCAPECHARS) = 0) then
    begin
      ReadEscapeCharacter(LChar);
      LRaw := LRaw + AnsiChar(LChar);
    end
    // a trailing quote
    else if Ch(FScriptP) = Ord(AQuote) then
    begin
      Inc(FScriptP);
      // if white spaces in a string are not allowed
      if (FFlags and SCFL_NOSTRINGWHITESPACES) <> 0 then
        Break;
      LTempP := FScriptP;
      LTempLine := FLine;
      // read useless stuff between two following strings
      if not ReadWhiteSpace then
      begin
        FScriptP := LTempP;
        FLine := LTempLine;
        Break;
      end;
      // if there is no leading quote
      if Ch(FScriptP) <> Ord(AQuote) then
      begin
        FScriptP := LTempP;
        FLine := LTempLine;
        Break;
      end;
      // step over the new leading quote
      Inc(FScriptP);
    end
    else
    begin
      if Ch(FScriptP) = 0 then
      begin
        AToken.Text := CString(LRaw);
        ScriptError('missing trailing quote');
        Exit(False);
      end;
      if Ch(FScriptP) = 10 then
      begin
        AToken.Text := CString(LRaw);
        ScriptError('newline inside string ' + AToken.Text);
        Exit(False);
      end;
      LRaw := LRaw + AnsiChar(FBuffer[FScriptP]);
      Inc(FScriptP);
    end;
  end;
  // trailing quote
  LRaw := LRaw + AQuote;
  AToken.Text := CString(LRaw);
  // the sub type is the length of the string
  AToken.Subtype := System.Length(LRaw);
  Result := True;
end;

function TQ3Script.ReadName(var AToken: TQ3Token): Boolean;
var
  LRaw: AnsiString;
  LChar: Integer;
begin
  AToken.TokenType := TT_NAME;
  LRaw := '';
  repeat
    LRaw := LRaw + AnsiChar(FBuffer[FScriptP]);
    Inc(FScriptP);
    if System.Length(LRaw) >= Q3_MAX_TOKEN then
    begin
      AToken.Text := LRaw;
      ScriptError('name longer than MAX_TOKEN = ' + AnsiString(IntToStr(Q3_MAX_TOKEN)));
      Exit(False);
    end;
    LChar := Ch(FScriptP);
  until not (((LChar >= Ord('a')) and (LChar <= Ord('z'))) or ((LChar >= Ord('A')) and (LChar <= Ord('Z'))) or
    ((LChar >= Ord('0')) and (LChar <= Ord('9'))) or (LChar = Ord('_')));
  AToken.Text := LRaw;
  // the sub type is the length of the name
  AToken.Subtype := System.Length(LRaw);
  Result := True;
end;

class procedure TQ3Script.NumberValue(const AText: AnsiString; const ASubtype: Integer; out AIntValue: Cardinal;
  out AFloatValue: TSoftExtended);
var
  LIndex: Integer;
  LDotFound: Cardinal;

  // *string: the zero terminator, and what follows it, read as zero
  function At(const AIndex: Integer): Integer;
  begin
    if AIndex <= System.Length(AText) then
      Result := Ord(AText[AIndex])
    else
      Result := 0;
  end;

begin
  AIntValue := 0;
  AFloatValue := TSoftExtended.FromInt64(0);
  // floating point number
  if (ASubtype and TT_FLOAT) <> 0 then
  begin
    LDotFound := 0;
    LIndex := 1;
    while At(LIndex) <> 0 do
    begin
      if At(LIndex) = Ord('.') then
      begin
        if LDotFound <> 0 then
          Exit;
        LDotFound := 10;
        Inc(LIndex);
      end;
      if LDotFound <> 0 then
      begin
        // the zero terminator after a final '.' is read as a digit: (0 - '0') / 10
        AFloatValue := AFloatValue + TSoftExtended.FromInt64(At(LIndex) - Ord('0')) /
          TSoftExtended.FromInt64(LDotFound);
        LDotFound := LDotFound * 10;
      end
      else
        AFloatValue := AFloatValue * TSoftExtended.FromInt64(10) + TSoftExtended.FromInt64(At(LIndex) - Ord('0'));
      Inc(LIndex);
    end;
    AIntValue := Cardinal(AFloatValue.Truncate and $FFFFFFFF);
  end
  else if (ASubtype and TT_DECIMAL) <> 0 then
  begin
    for LIndex := 1 to System.Length(AText) do
      AIntValue := AIntValue * 10 + Cardinal(Ord(AText[LIndex]) - Ord('0'));
    AFloatValue := TSoftExtended.FromInt64(AIntValue);
  end
  else if (ASubtype and TT_HEX) <> 0 then
  begin
    // step over the leading 0x or 0X
    for LIndex := 3 to System.Length(AText) do
    begin
      AIntValue := AIntValue shl 4;
      if (AText[LIndex] >= 'a') and (AText[LIndex] <= 'f') then
        AIntValue := AIntValue + Cardinal(Ord(AText[LIndex]) - Ord('a') + 10)
      else if (AText[LIndex] >= 'A') and (AText[LIndex] <= 'F') then
        AIntValue := AIntValue + Cardinal(Ord(AText[LIndex]) - Ord('A') + 10)
      else
        AIntValue := AIntValue + Cardinal(Ord(AText[LIndex]) - Ord('0'));
    end;
    AFloatValue := TSoftExtended.FromInt64(AIntValue);
  end
  else if (ASubtype and TT_OCTAL) <> 0 then
  begin
    // step over the first zero
    for LIndex := 2 to System.Length(AText) do
      AIntValue := (AIntValue shl 3) + Cardinal(Ord(AText[LIndex]) - Ord('0'));
    AFloatValue := TSoftExtended.FromInt64(AIntValue);
  end
  else if (ASubtype and TT_BINARY) <> 0 then
  begin
    // step over the leading 0b or 0B
    for LIndex := 3 to System.Length(AText) do
      AIntValue := (AIntValue shl 1) + Cardinal(Ord(AText[LIndex]) - Ord('0'));
    AFloatValue := TSoftExtended.FromInt64(AIntValue);
  end;
end;

function TQ3Script.ReadNumber(var AToken: TQ3Token): Boolean;
var
  LRaw: AnsiString;
  LChar: Integer;
  LIndex: Integer;
  LOctal: Boolean;
  LDot: Boolean;
begin
  AToken.TokenType := TT_NUMBER;
  LRaw := '';
  // a hexadecimal number
  if (Ch(FScriptP) = Ord('0')) and ((Ch(FScriptP + 1) = Ord('x')) or (Ch(FScriptP + 1) = Ord('X'))) then
  begin
    LRaw := LRaw + AnsiChar(FBuffer[FScriptP]) + AnsiChar(FBuffer[FScriptP + 1]);
    Inc(FScriptP, 2);
    LChar := Ch(FScriptP);
    // the C accepts 'A' as the only capital letter (c >= 'A' && c <= 'A')
    while ((LChar >= Ord('0')) and (LChar <= Ord('9'))) or ((LChar >= Ord('a')) and (LChar <= Ord('f'))) or
      (LChar = Ord('A')) do
    begin
      LRaw := LRaw + AnsiChar(FBuffer[FScriptP]);
      Inc(FScriptP);
      if System.Length(LRaw) >= Q3_MAX_TOKEN then
      begin
        AToken.Text := LRaw;
        ScriptError('hexadecimal number longer than MAX_TOKEN = ' + AnsiString(IntToStr(Q3_MAX_TOKEN)));
        Exit(False);
      end;
      LChar := Ch(FScriptP);
    end;
    AToken.Subtype := AToken.Subtype or TT_HEX;
  end
  // a binary number
  else if (Ch(FScriptP) = Ord('0')) and ((Ch(FScriptP + 1) = Ord('b')) or (Ch(FScriptP + 1) = Ord('B'))) then
  begin
    LRaw := LRaw + AnsiChar(FBuffer[FScriptP]) + AnsiChar(FBuffer[FScriptP + 1]);
    Inc(FScriptP, 2);
    LChar := Ch(FScriptP);
    while (LChar = Ord('0')) or (LChar = Ord('1')) do
    begin
      LRaw := LRaw + AnsiChar(FBuffer[FScriptP]);
      Inc(FScriptP);
      if System.Length(LRaw) >= Q3_MAX_TOKEN then
      begin
        AToken.Text := LRaw;
        ScriptError('binary number longer than MAX_TOKEN = ' + AnsiString(IntToStr(Q3_MAX_TOKEN)));
        Exit(False);
      end;
      LChar := Ch(FScriptP);
    end;
    AToken.Subtype := AToken.Subtype or TT_BINARY;
  end
  else
  begin
    // decimal or octal integer or floating point number
    LOctal := False;
    LDot := False;
    if Ch(FScriptP) = Ord('0') then
      LOctal := True;
    while True do
    begin
      LChar := Ch(FScriptP);
      if LChar = Ord('.') then
        LDot := True
      else if (LChar = Ord('8')) or (LChar = Ord('9')) then
        LOctal := False
      else if (LChar < Ord('0')) or (LChar > Ord('9')) then
        Break;
      LRaw := LRaw + AnsiChar(FBuffer[FScriptP]);
      Inc(FScriptP);
      if System.Length(LRaw) >= Q3_MAX_TOKEN - 1 then
      begin
        AToken.Text := LRaw;
        ScriptError('number longer than MAX_TOKEN = ' + AnsiString(IntToStr(Q3_MAX_TOKEN)));
        Exit(False);
      end;
    end;
    if LOctal then
      AToken.Subtype := AToken.Subtype or TT_OCTAL
    else
      AToken.Subtype := AToken.Subtype or TT_DECIMAL;
    if LDot then
      AToken.Subtype := AToken.Subtype or TT_FLOAT;
  end;
  for LIndex := 0 to 1 do
  begin
    LChar := Ch(FScriptP);
    // a LONG number
    if ((LChar = Ord('l')) or (LChar = Ord('L'))) and ((AToken.Subtype and TT_LONG) = 0) then
    begin
      Inc(FScriptP);
      AToken.Subtype := AToken.Subtype or TT_LONG;
    end
    // an UNSIGNED number
    else if ((LChar = Ord('u')) or (LChar = Ord('U'))) and ((AToken.Subtype and (TT_UNSIGNED or TT_FLOAT)) = 0) then
    begin
      Inc(FScriptP);
      AToken.Subtype := AToken.Subtype or TT_UNSIGNED;
    end;
  end;
  AToken.Text := LRaw;
  NumberValue(AToken.Text, AToken.Subtype, AToken.IntValue, AToken.FloatValue);
  if (AToken.Subtype and TT_FLOAT) = 0 then
    AToken.Subtype := AToken.Subtype or TT_INTEGER;
  Result := True;
end;

function TQ3Script.ReadPunctuation(var AToken: TQ3Token): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FPunctuations.Find(FBuffer, FScriptP, FEndP);
  Result := LIndex >= 0;
  if Result then
  begin
    AToken.Text := FPunctuations.Punctuations[LIndex].Text;
    Inc(FScriptP, System.Length(AToken.Text));
    AToken.TokenType := TT_PUNCTUATION;
    // sub type is the number of the punctuation
    AToken.Subtype := FPunctuations.Punctuations[LIndex].Number;
  end;
end;

// A primitive script: the token is everything up to the next white space or ';' (a ';' is not
// stepped over: the C reads an empty token forever at it)
function TQ3Script.ReadPrimitive(var AToken: TQ3Token): Boolean;
var
  LRaw: AnsiString;
begin
  LRaw := '';
  while (Ch(FScriptP) > 32) and (Ch(FScriptP) <> Ord(';')) do
  begin
    if System.Length(LRaw) >= Q3_MAX_TOKEN then
    begin
      AToken.Text := LRaw;
      ScriptError('primitive token longer than MAX_TOKEN = ' + AnsiString(IntToStr(Q3_MAX_TOKEN)));
      Exit(False);
    end;
    LRaw := LRaw + AnsiChar(FBuffer[FScriptP]);
    Inc(FScriptP);
  end;
  AToken.Text := LRaw;
  // copy the token into the script structure
  FToken := AToken;
  Result := True;
end;

function TQ3Script.ReadToken(var AToken: TQ3Token): Boolean;
begin
  // if there is a token available (from UnreadToken)
  if FTokenAvailable then
  begin
    FTokenAvailable := False;
    AToken := FToken;
    Exit(True);
  end;
  // save script pointer and line counter
  FLastScriptP := FScriptP;
  FLastLine := FLine;
  // clear the token stuff
  AToken := Default(TQ3Token);
  // start of the white space
  FWhitespaceP := FScriptP;
  AToken.WhitespaceOffset := FScriptP;
  // read useless stuff
  if not ReadWhiteSpace then
    Exit(False);
  // end of the white space
  FEndWhitespaceP := FScriptP;
  AToken.EndWhitespaceOffset := FScriptP;
  // line the token is on and number of lines crossed before token
  AToken.Line := FLine;
  AToken.LinesCrossed := FLine - FLastLine;
  if Ch(FScriptP) = Ord('"') then
  begin
    if not ReadString(AToken, '"') then
      Exit(False);
  end
  else if Ch(FScriptP) = Ord('''') then
  begin
    if not ReadString(AToken, '''') then
      Exit(False);
  end
  // a number
  else if ((Ch(FScriptP) >= Ord('0')) and (Ch(FScriptP) <= Ord('9'))) or
    ((Ch(FScriptP) = Ord('.')) and (Ch(FScriptP + 1) >= Ord('0')) and (Ch(FScriptP + 1) <= Ord('9'))) then
  begin
    if not ReadNumber(AToken) then
      Exit(False);
  end
  // a primitive script
  else if (FFlags and SCFL_PRIMITIVE) <> 0 then
    Exit(ReadPrimitive(AToken))
  // a name
  else if ((Ch(FScriptP) >= Ord('a')) and (Ch(FScriptP) <= Ord('z'))) or
    ((Ch(FScriptP) >= Ord('A')) and (Ch(FScriptP) <= Ord('Z'))) or (Ch(FScriptP) = Ord('_')) then
  begin
    if not ReadName(AToken) then
      Exit(False);
  end
  // punctuations
  else if not ReadPunctuation(AToken) then
  begin
    ScriptError('can''t read token');
    Exit(False);
  end;
  // copy the token into the script structure
  FToken := AToken;
  Result := True;
end;

function TQ3Script.ExpectTokenString(const AText: AnsiString): Boolean;
var
  LToken: TQ3Token;
begin
  if not ReadToken(LToken) then
  begin
    ScriptError('couldn''t find expected ' + AText);
    Exit(False);
  end;
  if LToken.Text <> AText then
  begin
    ScriptError('expected ' + AText + ', found ' + LToken.Text);
    Exit(False);
  end;
  Result := True;
end;

function TQ3Script.ExpectTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
var
  LText: AnsiString;
begin
  if not ReadToken(AToken) then
  begin
    ScriptError('couldn''t read expected token');
    Exit(False);
  end;
  if AToken.TokenType <> AType then
  begin
    LText := '';
    if AType = TT_STRING then
      LText := 'string';
    if AType = TT_LITERAL then
      LText := 'literal';
    if AType = TT_NUMBER then
      LText := 'number';
    if AType = TT_NAME then
      LText := 'name';
    if AType = TT_PUNCTUATION then
      LText := 'punctuation';
    ScriptError('expected a ' + LText + ', found ' + AToken.Text);
    Exit(False);
  end;
  if AToken.TokenType = TT_NUMBER then
  begin
    if (AToken.Subtype and ASubtype) <> ASubtype then
    begin
      LText := '';
      if (ASubtype and TT_DECIMAL) <> 0 then
        LText := 'decimal';
      if (ASubtype and TT_HEX) <> 0 then
        LText := 'hex';
      if (ASubtype and TT_OCTAL) <> 0 then
        LText := 'octal';
      if (ASubtype and TT_BINARY) <> 0 then
        LText := 'binary';
      if (ASubtype and TT_LONG) <> 0 then
        LText := LText + ' long';
      if (ASubtype and TT_UNSIGNED) <> 0 then
        LText := LText + ' unsigned';
      if (ASubtype and TT_FLOAT) <> 0 then
        LText := LText + ' float';
      if (ASubtype and TT_INTEGER) <> 0 then
        LText := LText + ' integer';
      ScriptError('expected ' + LText + ', found ' + AToken.Text);
      Exit(False);
    end;
  end
  else if AToken.TokenType = TT_PUNCTUATION then
  begin
    if ASubtype < 0 then
    begin
      ScriptError('BUG: wrong punctuation subtype');
      Exit(False);
    end;
    if AToken.Subtype <> ASubtype then
    begin
      // the C passes a punctuation_t to "%s" (undefined): here the text of the punctuation at that index
      if ASubtype < System.Length(FPunctuations.Punctuations) then
        LText := FPunctuations.Punctuations[ASubtype].Text
      else
        LText := '';
      ScriptError('expected ' + LText + ', found ' + AToken.Text);
      Exit(False);
    end;
  end;
  Result := True;
end;

function TQ3Script.ExpectAnyToken(var AToken: TQ3Token): Boolean;
begin
  Result := ReadToken(AToken);
  if not Result then
    ScriptError('couldn''t read expected token');
end;

function TQ3Script.CheckTokenString(const AText: AnsiString): Boolean;
var
  LToken: TQ3Token;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if the token is available
  if LToken.Text = AText then
    Exit(True);
  // token not available (the line counter is not put back)
  FScriptP := FLastScriptP;
  Result := False;
end;

function TQ3Script.CheckTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
var
  LToken: TQ3Token;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if the type matches
  if (LToken.TokenType = AType) and ((LToken.Subtype and ASubtype) = ASubtype) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  FScriptP := FLastScriptP;
  Result := False;
end;

function TQ3Script.SkipUntilString(const AText: AnsiString): Boolean;
var
  LToken: TQ3Token;
begin
  while ReadToken(LToken) do
    if LToken.Text = AText then
      Exit(True);
  Result := False;
end;

procedure TQ3Script.UnreadLastToken;
begin
  FTokenAvailable := True;
end;

procedure TQ3Script.UnreadToken(const AToken: TQ3Token);
begin
  FToken := AToken;
  FTokenAvailable := True;
end;

function TQ3Script.NextWhiteSpaceChar: Byte;
begin
  if FWhitespaceP <> FEndWhitespaceP then
  begin
    Result := FBuffer[FWhitespaceP];
    Inc(FWhitespaceP);
  end
  else
    Result := 0;
end;

class procedure TQ3Script.StripDoubleQuotes(var AText: AnsiString);
begin
  if (AText <> '') and (AText[1] = '"') then
    Delete(AText, 1, 1);
  if (AText <> '') and (AText[System.Length(AText)] = '"') then
    Delete(AText, System.Length(AText), 1);
end;

class procedure TQ3Script.StripSingleQuotes(var AText: AnsiString);
begin
  if (AText <> '') and (AText[1] = '''') then
    Delete(AText, 1, 1);
  if (AText <> '') and (AText[System.Length(AText)] = '''') then
    Delete(AText, System.Length(AText), 1);
end;

function TQ3Script.ReadSignedFloat: TSoftExtended;
var
  LToken: TQ3Token;
  LNegative: Boolean;
begin
  LNegative := False;
  ExpectAnyToken(LToken);
  if LToken.Text = '-' then
  begin
    LNegative := True;
    ExpectTokenType(TT_NUMBER, 0, LToken);
  end
  else if LToken.TokenType <> TT_NUMBER then
    ScriptError('expected float value, found ' + LToken.Text + #10);
  Result := LToken.FloatValue;
  if LNegative then
    Result := -Result;
end;

function TQ3Script.ReadSignedInt: Integer;
var
  LToken: TQ3Token;
  LNegative: Boolean;
begin
  LNegative := False;
  ExpectAnyToken(LToken);
  if LToken.Text = '-' then
  begin
    LNegative := True;
    ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
  end
  else if (LToken.TokenType <> TT_NUMBER) or (LToken.Subtype = TT_FLOAT) then
    ScriptError('expected integer value, found ' + LToken.Text + #10);
  // signed long * unsigned long is an unsigned long that wraps
  if LNegative then
    Result := Integer(Cardinal(0) - LToken.IntValue)
  else
    Result := Integer(LToken.IntValue);
end;

procedure TQ3Script.Reset;
begin
  FScriptP := 0;
  FLastScriptP := 0;
  FWhitespaceP := -1;
  FEndWhitespaceP := -1;
  FTokenAvailable := False;
  FLine := 1;
  FLastLine := 1;
  FToken := Default(TQ3Token);
end;

function TQ3Script.EndOfScript: Boolean;
begin
  Result := FScriptP >= FEndP;
end;

function TQ3Script.SkipTo(const AText: AnsiString): Boolean;
var
  LIndex: Integer;
  LMatch: Boolean;
begin
  while True do
  begin
    if not ReadWhiteSpace then
      Exit(False);
    if (AText <> '') and (Ch(FScriptP) = Ord(AText[1])) then
    begin
      LMatch := True;
      for LIndex := 1 to System.Length(AText) do
        if Ch(FScriptP + LIndex - 1) <> Ord(AText[LIndex]) then
        begin
          LMatch := False;
          Break;
        end;
      if LMatch then
        Exit(True);
    end;
    Inc(FScriptP);
  end;
end;

end.
