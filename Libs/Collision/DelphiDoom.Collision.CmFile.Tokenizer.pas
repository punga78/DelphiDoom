{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the tokenizer of the .cm file               }
{                                                                              }
{  A small lexer for the text of a collision model file. It replaces the use   }
{  of idLexer in CollisionModel_files.cpp (Doom 3 GPL Source Code, Copyright   }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company; GPL v3 with         }
{  additional terms): only the part the .cm syntax needs, written from the     }
{  behaviour of the original, not copied from it.                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.CmFile.Tokenizer;

interface

type
  /// <summary>
  ///   Splits the text into words, numbers, quoted strings and the punctuation { } ( ),
  ///   skipping spaces, line comments and block comments
  /// </summary>
  TCollisionTokenizer = class
  private
    FText: string;
    FPosition: Integer;
    FLine: Integer;
    FHasPeek: Boolean;
    FPeekToken: string;
    FPeekIsString: Boolean;
    procedure SkipBlanks;
    procedure Scan(out AToken: string; out AIsString: Boolean; out AEndOfText: Boolean);
  public
    constructor Create(const AText: string);
    /// <summary>The next token; false at the end of the text. A quoted string comes without quotes</summary>
    function ReadToken(out AToken: string; out AIsString: Boolean): Boolean;
    /// <summary>True (and consumes it) when the next token is exactly AToken (a word, not a string)</summary>
    function CheckTokenString(const AToken: string): Boolean;
    /// <summary>Consumes AToken or raises ECollisionFormatException</summary>
    procedure ExpectTokenString(const AToken: string);
    /// <summary>The next token must be a quoted string</summary>
    function ExpectString: string;
    function ParseInt: Integer;
    function ParseFloat: Single;
    /// <summary>The next token must be a number: it is not consumed; true if a number comes next</summary>
    function NextIsNumber: Boolean;
    /// <summary>Current line, for the messages</summary>
    property Line: Integer read FLine;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Types;

resourcestring
  SUnexpectedEnd = 'collision model file: unexpected end of file at line %d';
  SExpectedToken = 'collision model file: expected "%s" but found "%s" at line %d';
  SExpectedString = 'collision model file: expected a quoted string but found "%s" at line %d';
  SBadNumber = 'collision model file: "%s" is not a number at line %d';

{ TCollisionTokenizer }

constructor TCollisionTokenizer.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FPosition := 1;
  FLine := 1;
end;

procedure TCollisionTokenizer.SkipBlanks;
begin
  while FPosition <= Length(FText) do
  begin
    if FText[FPosition] = #10 then
    begin
      Inc(FLine);
      Inc(FPosition);
    end
    else if FText[FPosition] <= ' ' then
      Inc(FPosition)
    else if (FText[FPosition] = '/') and (FPosition < Length(FText)) and (FText[FPosition + 1] = '/') then
    begin
      while (FPosition <= Length(FText)) and (FText[FPosition] <> #10) do
        Inc(FPosition);
    end
    else if (FText[FPosition] = '/') and (FPosition < Length(FText)) and (FText[FPosition + 1] = '*') then
    begin
      Inc(FPosition, 2);
      while (FPosition < Length(FText)) and not ((FText[FPosition] = '*') and (FText[FPosition + 1] = '/')) do
      begin
        if FText[FPosition] = #10 then
          Inc(FLine);
        Inc(FPosition);
      end;
      Inc(FPosition, 2);
    end
    else
      Break;
  end;
end;

procedure TCollisionTokenizer.Scan(out AToken: string; out AIsString: Boolean; out AEndOfText: Boolean);
var
  LStart: Integer;
begin
  AToken := '';
  AIsString := False;
  SkipBlanks;
  AEndOfText := FPosition > Length(FText);
  if AEndOfText then
    Exit;
  if FText[FPosition] = '"' then
  begin
    Inc(FPosition);
    LStart := FPosition;
    while (FPosition <= Length(FText)) and (FText[FPosition] <> '"') do
    begin
      if FText[FPosition] = #10 then
        Inc(FLine);
      Inc(FPosition);
    end;
    AToken := Copy(FText, LStart, FPosition - LStart);
    AIsString := True;
    Inc(FPosition); // closing quote
  end
  else if CharInSet(FText[FPosition], ['{', '}', '(', ')', ',']) then
  begin
    AToken := FText[FPosition];
    Inc(FPosition);
  end
  else
  begin
    LStart := FPosition;
    while (FPosition <= Length(FText)) and (FText[FPosition] > ' ') and
      not CharInSet(FText[FPosition], ['{', '}', '(', ')', ',', '"']) do
      Inc(FPosition);
    AToken := Copy(FText, LStart, FPosition - LStart);
  end;
end;

function TCollisionTokenizer.ReadToken(out AToken: string; out AIsString: Boolean): Boolean;
var
  LEnd: Boolean;
begin
  if FHasPeek then
  begin
    AToken := FPeekToken;
    AIsString := FPeekIsString;
    FHasPeek := False;
    Exit(True);
  end;
  Scan(AToken, AIsString, LEnd);
  Result := not LEnd;
end;

function TCollisionTokenizer.CheckTokenString(const AToken: string): Boolean;
var
  LToken: string;
  LIsString: Boolean;
  LEnd: Boolean;
begin
  if not FHasPeek then
  begin
    Scan(LToken, LIsString, LEnd);
    if LEnd then
      Exit(False);
    FPeekToken := LToken;
    FPeekIsString := LIsString;
    FHasPeek := True;
  end;
  Result := (not FPeekIsString) and (FPeekToken = AToken);
  if Result then
    FHasPeek := False;
end;

procedure TCollisionTokenizer.ExpectTokenString(const AToken: string);
var
  LToken: string;
  LIsString: Boolean;
begin
  if not ReadToken(LToken, LIsString) then
    raise ECollisionFormatException.CreateFmt(SUnexpectedEnd, [FLine]);
  if LIsString or (LToken <> AToken) then
    raise ECollisionFormatException.CreateFmt(SExpectedToken, [AToken, LToken, FLine]);
end;

function TCollisionTokenizer.ExpectString: string;
var
  LIsString: Boolean;
begin
  if not ReadToken(Result, LIsString) then
    raise ECollisionFormatException.CreateFmt(SUnexpectedEnd, [FLine]);
  if not LIsString then
    raise ECollisionFormatException.CreateFmt(SExpectedString, [Result, FLine]);
end;

function TCollisionTokenizer.ParseInt: Integer;
var
  LToken: string;
  LIsString: Boolean;
begin
  if not ReadToken(LToken, LIsString) then
    raise ECollisionFormatException.CreateFmt(SUnexpectedEnd, [FLine]);
  if LIsString or not TryStrToInt(LToken, Result) then
    raise ECollisionFormatException.CreateFmt(SBadNumber, [LToken, FLine]);
end;

function TCollisionTokenizer.ParseFloat: Single;
var
  LToken: string;
  LIsString: Boolean;
  LValue: Double;
begin
  if not ReadToken(LToken, LIsString) then
    raise ECollisionFormatException.CreateFmt(SUnexpectedEnd, [FLine]);
  if LIsString or not TryStrToFloat(LToken, LValue, TFormatSettings.Invariant) then
    raise ECollisionFormatException.CreateFmt(SBadNumber, [LToken, FLine]);
  Result := LValue;
end;

function TCollisionTokenizer.NextIsNumber: Boolean;
var
  LToken: string;
  LIsString: Boolean;
  LEnd: Boolean;
  LValue: Double;
begin
  if not FHasPeek then
  begin
    Scan(LToken, LIsString, LEnd);
    if LEnd then
      Exit(False);
    FPeekToken := LToken;
    FPeekIsString := LIsString;
    FHasPeek := True;
  end;
  Result := (not FPeekIsString) and TryStrToFloat(FPeekToken, LValue, TFormatSettings.Invariant);
end;

end.
