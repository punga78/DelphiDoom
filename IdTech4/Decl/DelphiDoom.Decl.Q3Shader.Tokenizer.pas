{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the words of a script                       }
{                                                                              }
{  Port of COM_ParseExt, SkipBracedSection and SkipRestOfLine (game\q_shared.c) }
{  of Quake III Arena (id Software, GPL v2 or later). Based on the Quake III   }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Tokenizer;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The <c>char **text</c> of the script functions of Quake III: a text and a position. Not the lexer of
  ///   Doom 3: words are separated by blanks only (a "{" glued to a word is part of the word), quotes keep
  ///   blanks, "//" and "/* */" are comments, and a word of 1024 characters or more is dropped. Bytes of 128
  ///   and more are negative characters in the original, so they are blanks and end a word.
  /// </summary>
  TQ3ShaderTokenizer = class
  strict private
    FText: AnsiString;
    FPosition: Integer;
    FEnded: Boolean;
    function CharAt(const APosition: Integer): Integer;
  public
    /// <summary><c>AStart</c> is the 1 based position of the first character to read</summary>
    constructor Create(const AText: AnsiString; const AStart: Integer = 1);
    /// <summary>
    ///   COM_ParseExt: the next word, empty at the end of the text. Without <c>AAllowLineBreaks</c> the answer is
    ///   empty too when a new line comes before the next word (the line is not consumed).
    /// </summary>
    function ParseExt(const AAllowLineBreaks: Boolean): AnsiString;
    /// <summary>SkipRestOfLine: moves after the next new line</summary>
    procedure SkipRestOfLine;
    /// <summary>
    ///   SkipBracedSection: the next word should be an open brace; skips until the matching close brace.
    ///   When it is not a brace only that word is skipped (the original stops when the depth is zero).
    /// </summary>
    procedure SkipBracedSection;
    /// <summary>The pointer of the original is NULL: the end of the text was reached while looking for a word</summary>
    property Ended: Boolean read FEnded;
    /// <summary>The 1 based position of the next character</summary>
    property Position: Integer read FPosition;
  end;

implementation

const
  // MAX_TOKEN_CHARS
  MAX_TOKEN_CHARS = 1024;

constructor TQ3ShaderTokenizer.Create(const AText: AnsiString; const AStart: Integer);
begin
  inherited Create;
  FText := AText;
  FPosition := AStart;
end;

// the character at a position as a signed char; zero at and after the end
function TQ3ShaderTokenizer.CharAt(const APosition: Integer): Integer;
begin
  if (APosition < 1) or (APosition > Length(FText)) then
    Exit(0);
  Result := ShortInt(Byte(FText[APosition]));
end;

function TQ3ShaderTokenizer.ParseExt(const AAllowLineBreaks: Boolean): AnsiString;
var
  LPosition: Integer;
  LHasNewLines: Boolean;
  LChar: Integer;
begin
  Result := '';
  if FEnded then
    Exit;
  LPosition := FPosition;
  LHasNewLines := False;
  while True do
  begin
    // SkipWhitespace
    LChar := CharAt(LPosition);
    while LChar <= 32 do
    begin
      if LChar = 0 then
      begin
        FEnded := True;
        Exit;
      end;
      if LChar = 10 then
        LHasNewLines := True;
      Inc(LPosition);
      LChar := CharAt(LPosition);
    end;
    if LHasNewLines and (not AAllowLineBreaks) then
    begin
      FPosition := LPosition;
      Exit;
    end;
    if (LChar = Ord('/')) and (CharAt(LPosition + 1) = Ord('/')) then
    begin
      Inc(LPosition, 2);
      while (CharAt(LPosition) <> 0) and (CharAt(LPosition) <> 10) do
        Inc(LPosition);
    end
    else if (LChar = Ord('/')) and (CharAt(LPosition + 1) = Ord('*')) then
    begin
      Inc(LPosition, 2);
      while (CharAt(LPosition) <> 0) and ((CharAt(LPosition) <> Ord('*')) or (CharAt(LPosition + 1) <> Ord('/'))) do
        Inc(LPosition);
      if CharAt(LPosition) <> 0 then
        Inc(LPosition, 2);
    end
    else
      Break;
  end;
  if LChar = Ord('"') then
  begin
    Inc(LPosition);
    while True do
    begin
      LChar := CharAt(LPosition);
      Inc(LPosition);
      if (LChar = Ord('"')) or (LChar = 0) then
      begin
        FPosition := LPosition;
        // the original goes on after the terminator; here the text is over
        if LChar = 0 then
          FEnded := True;
        Exit;
      end;
      if Length(Result) < MAX_TOKEN_CHARS then
        Result := Result + AnsiChar(Byte(LChar));
    end;
  end;
  repeat
    if Length(Result) < MAX_TOKEN_CHARS then
      Result := Result + AnsiChar(Byte(LChar));
    Inc(LPosition);
    LChar := CharAt(LPosition);
  until LChar <= 32;
  if Length(Result) = MAX_TOKEN_CHARS then
    Result := '';
  FPosition := LPosition;
end;

procedure TQ3ShaderTokenizer.SkipRestOfLine;
var
  LChar: Integer;
begin
  if FEnded then
    Exit;
  while True do
  begin
    LChar := CharAt(FPosition);
    Inc(FPosition);
    if LChar = 0 then
    begin
      FEnded := True;
      Exit;
    end;
    if LChar = 10 then
      Exit;
  end;
end;

procedure TQ3ShaderTokenizer.SkipBracedSection;
var
  LToken: AnsiString;
  LDepth: Integer;
begin
  LDepth := 0;
  repeat
    LToken := ParseExt(True);
    if Length(LToken) = 1 then
    begin
      if LToken[1] = '{' then
        Inc(LDepth)
      else if LToken[1] = '}' then
        Dec(LDepth);
    end;
  until (LDepth = 0) or FEnded;
end;

end.
