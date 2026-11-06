{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the scanner of the text scripts                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Scanner;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Cuts the text of a script in words (the old TScriptEngine). A word ends at a space or
  ///   at one of { } ( ) , and at //; a word in quotes keeps everything up to the closing
  ///   quote. A word is at most 1023 characters; a longer one goes on in the next word.
  ///   The text is read as 8 bit characters. Problems are warnings to the log, never
  ///   exceptions: the call that fails gives false
  /// </summary>
  TScriptScanner = class
  public
    const
      MAX_WORD_LENGTH = 1023;
  private
    FText: TBytes;
    FPosition: Integer; // 0-based, the next character
    FWord: string;
    FInteger: Integer;
    FFloat: Single;
    FBoolean: Boolean;
    FLine: Integer;
    FFinished: Boolean;
    FNewLine: Boolean;
    FBracketLevel: Integer;
    FParenthesisLevel: Integer;
    FAlreadyGot: Boolean;
    FQuoted: Boolean;
    FIgnored: TArray<string>;
    FAliasNames: TArray<string>;
    FAliasValues: TArray<string>;
    FLog: ILog;
    function CharAt(AIndex: Integer): Byte;
    function IsSeparator(AChar: Byte): Boolean;
    function AliasIndexOf(const AName: string): Integer;
    function GetWord: string;
    function GetUpperWord: string;
    procedure Reset;
  public
    constructor Create(const AText: string; const ALog: ILog);
    /// <summary>Another text: the position, the line and the levels start again; the ignored words and the aliases stay</summary>
    procedure SetText(const AText: string);
    /// <summary>The words that GetString skips (case does not matter)</summary>
    procedure AddIgnoreToken(const AWord: string);
    procedure AddAlias(const ASource, ADestination: string);
    procedure ClearAliases;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AFormat: string; const AArguments: array of const); overload;
    /// <summary>Writes the lines around ALine (AOffset lines before and after)</summary>
    procedure PrintLineError(ALine, AOffset: Integer);

    function GetString: Boolean;
    function MustGetString: Boolean;
    function MustGetStringName(const AName: string): Boolean;
    function GetStringEOL: string;
    function GetStringEOLWithQuotes: string;
    function GetTokensEOL: TArray<string>;
    function GetStringEOLUnchanged: string;
    function GetInteger: Boolean;
    function MustGetInteger: Boolean;
    function GetFloat: Boolean;
    function MustGetFloat: Boolean;
    function GetBoolean: Boolean;
    function MustGetBoolean: Boolean;
    procedure UnGet;
    /// <summary>Index of the first of AWords that is the current word, or -1</summary>
    function MatchString(const AWords: TArray<string>): Integer; overload;
    function MatchString(const AWord: string): Boolean; overload;
    function MatchPosString(const AWord: string): Boolean;
    function MustMatchString(const AWords: TArray<string>): Integer;
    function Compare(const AWord: string): Boolean; overload;
    function Compare(const AWord: string; const AUpperCurrent: string): Boolean; overload;

    property AsString: string read GetWord;
    property AsInteger: Integer read FInteger;
    property AsFloat: Single read FFloat;
    property AsBoolean: Boolean read FBoolean;
    property Finished: Boolean read FFinished;
    property Line: Integer read FLine;
    property NewLine: Boolean read FNewLine;
    property BracketLevel: Integer read FBracketLevel;
    property ParenthesisLevel: Integer read FParenthesisLevel;
    property QuotedToken: Boolean read FQuoted;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TScriptScanner }

constructor TScriptScanner.Create(const AText: string; const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
  SetText(AText);
end;

procedure TScriptScanner.Reset;
begin
  FPosition := 0;
  FLine := 1;
  FFinished := False;
  FQuoted := False;
  FAlreadyGot := False;
  FWord := '';
end;

procedure TScriptScanner.SetText(const AText: string);
var
  LAnsi: AnsiString;
begin
  // the script text is parsed as 8 bit characters
  LAnsi := AnsiString(AText);
  SetLength(FText, Length(LAnsi));
  if Length(LAnsi) > 0 then
    Move(LAnsi[1], FText[0], Length(LAnsi));
  Reset;
end;

function TScriptScanner.CharAt(AIndex: Integer): Byte;
begin
  // the old code read the byte after the text: here it is a zero
  if (AIndex >= 0) and (AIndex < Length(FText)) then
    Result := FText[AIndex]
  else
    Result := 0;
end;

function TScriptScanner.IsSeparator(AChar: Byte): Boolean;
begin
  Result := AChar in [Ord('{'), Ord('}'), Ord('('), Ord(')'), Ord(',')];
end;

function TScriptScanner.GetWord: string;
var
  LIndex: Integer;
begin
  Result := FWord;
  LIndex := AliasIndexOf(TScannerStrings.UpperAscii(Result));
  if LIndex >= 0 then
    Result := FAliasValues[LIndex];
end;

function TScriptScanner.GetUpperWord: string;
var
  LIndex: Integer;
begin
  Result := TScannerStrings.UpperAscii(FWord);
  LIndex := AliasIndexOf(Result);
  if LIndex >= 0 then
    Result := FAliasValues[LIndex];
end;

function TScriptScanner.AliasIndexOf(const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FAliasNames) do
    if FAliasNames[LIndex] = AName then
      Exit(LIndex);
  Result := -1;
end;

procedure TScriptScanner.AddIgnoreToken(const AWord: string);
begin
  SetLength(FIgnored, Length(FIgnored) + 1);
  FIgnored[High(FIgnored)] := TScannerStrings.UpperAscii(AWord);
end;

procedure TScriptScanner.AddAlias(const ASource, ADestination: string);
begin
  // the old list stored "SOURCE=DESTINATION" in upper case
  SetLength(FAliasNames, Length(FAliasNames) + 1);
  SetLength(FAliasValues, Length(FAliasValues) + 1);
  FAliasNames[High(FAliasNames)] := TScannerStrings.UpperAscii(ASource);
  FAliasValues[High(FAliasValues)] := TScannerStrings.UpperAscii(ADestination);
end;

procedure TScriptScanner.ClearAliases;
begin
  FAliasNames := nil;
  FAliasValues := nil;
end;

procedure TScriptScanner.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage + #13#10);
end;

procedure TScriptScanner.Warn(const AFormat: string; const AArguments: array of const);
begin
  Warn(Format(AFormat, AArguments));
end;

procedure TScriptScanner.PrintLineError(ALine, AOffset: Integer);
const
  LRULE = '==========================================================================';
var
  LLines: TArray<string>;
  LAnsi: AnsiString;
  LFrom: Integer;
  LTo: Integer;
  LIndex: Integer;
  LPrefix: string;
begin
  if not Assigned(FLog) then
    Exit;
  SetLength(LAnsi, Length(FText));
  if Length(FText) > 0 then
    Move(FText[0], LAnsi[1], Length(FText));
  LLines := string(LAnsi).Replace(#13#10, #10).Replace(#13, #10).Split([#10]);
  // a final line break does not start a new line
  if (Length(LLines) > 0) and (LLines[High(LLines)] = '') then
    SetLength(LLines, Length(LLines) - 1);
  LFrom := ALine - AOffset - 1;
  LTo := ALine + AOffset - 1;
  if LFrom < 0 then
    LFrom := 0;
  // like the old code, the last line printed is one past the end when the context reaches it
  if LTo >= High(LLines) then
    LTo := Length(LLines);
  FLog.Warning(LRULE + #13#10);
  for LIndex := LFrom to LTo do
  begin
    LPrefix := Format('%.5d', [LIndex]);
    if LIndex = ALine - 1 then
      LPrefix := LPrefix + ' *** '
    else
      LPrefix := LPrefix + '     ';
    if LIndex < Length(LLines) then
      FLog.Warning(LPrefix + LLines[LIndex] + #13#10)
    else
      FLog.Warning(LPrefix + #13#10);
  end;
  FLog.Warning(LRULE + #13#10);
  FLog.Warning(#13#10);
end;

function TScriptScanner.GetString: Boolean;
var
  LFound: Boolean;
  LChar: Byte;
  LBuffer: TBytes;
  LCount: Integer;
  LAnsi: AnsiString;
begin
  if FAlreadyGot then
  begin
    FAlreadyGot := False;
    Exit(True);
  end;

  FQuoted := False;
  FNewLine := False;
  LFound := False;
  if FPosition >= Length(FText) then
  begin
    FFinished := True;
    Exit(False);
  end;

  while not LFound do
  begin
    LChar := CharAt(FPosition);
    while (LChar <= 32) or IsSeparator(LChar) do
    begin
      if FPosition >= Length(FText) then
      begin
        FFinished := True;
        Exit(False);
      end;
      case LChar of
        Ord('{'):
          Inc(FBracketLevel);
        Ord('}'):
          begin
            Dec(FBracketLevel);
            if FBracketLevel < 0 then
            begin
              Warn('TScriptEngine.GetString(): Closing bracket "}" found at line %d without opening bracket "{"', [FLine]);
              PrintLineError(FLine, 2);
              FBracketLevel := 0;
            end;
          end;
        Ord('('):
          Inc(FParenthesisLevel);
        Ord(')'):
          begin
            Dec(FParenthesisLevel);
            if FParenthesisLevel < 0 then
            begin
              Warn('TScriptEngine.GetString(): Closing parenthesis ")" found at line %d without opening parenthesis "("', [FLine]);
              PrintLineError(FLine, 2);
              FParenthesisLevel := 0;
            end;
          end;
        10:
          begin
            Inc(FLine);
            FNewLine := True;
          end;
      end;
      Inc(FPosition);
      LChar := CharAt(FPosition);
    end;

    if FPosition >= Length(FText) then
    begin
      FFinished := True;
      Exit(False);
    end;

    if LChar <> Ord('/') then
      LFound := True
    else
    begin
      // a comment, or a lone slash that is dropped
      Inc(FPosition);
      if CharAt(FPosition) = Ord('/') then
      begin
        while (CharAt(FPosition) <> 13) and (CharAt(FPosition) <> 10) do
        begin
          if FPosition >= Length(FText) then
          begin
            FFinished := True;
            Exit(False);
          end;
          Inc(FPosition);
        end;
        // the line break that ends the comment is counted here and again as a space
        Inc(FLine);
        FNewLine := True;
      end;
    end;
  end;

  SetLength(LBuffer, MAX_WORD_LENGTH);
  LCount := 0;
  if CharAt(FPosition) = Ord('"') then
  begin
    FQuoted := True;
    Inc(FPosition);
    while (FPosition < Length(FText)) and (CharAt(FPosition) <> Ord('"')) do
    begin
      LBuffer[LCount] := CharAt(FPosition);
      Inc(LCount);
      Inc(FPosition);
      if (FPosition = Length(FText)) or (LCount = MAX_WORD_LENGTH) then
        Break;
    end;
    Inc(FPosition);
  end
  else
  begin
    while (CharAt(FPosition) > 32) and (FPosition < Length(FText)) and
      not ((CharAt(FPosition) = Ord('/')) and (CharAt(FPosition + 1) = Ord('/'))) and
      not IsSeparator(CharAt(FPosition)) do
    begin
      LBuffer[LCount] := CharAt(FPosition);
      Inc(LCount);
      Inc(FPosition);
      if (FPosition = Length(FText)) or (LCount = MAX_WORD_LENGTH) then
        Break;
    end;
  end;
  SetLength(LAnsi, LCount);
  if LCount > 0 then
    Move(LBuffer[0], LAnsi[1], LCount);
  FWord := string(LAnsi);
  if Length(FIgnored) = 0 then
    Exit(True);
  for LCount := 0 to High(FIgnored) do
    if FIgnored[LCount] = TScannerStrings.UpperAscii(FWord) then
      Exit(GetString);
  Result := True;
end;

function TScriptScanner.MustGetString: Boolean;
begin
  Result := GetString;
  if not Result then
  begin
    Warn('TScriptEngine.MustGetString(): Missing string at Line %d', [FLine]);
    PrintLineError(FLine, 2);
  end;
end;

function TScriptScanner.MustGetStringName(const AName: string): Boolean;
begin
  Result := MustGetString;
  if not Result or not Compare(AName) then
  begin
    Warn('TScriptEngine.MustGetStringName(): "%s" expected at Line %d', [AName, FLine]);
    PrintLineError(FLine, 2);
    Result := False;
  end;
end;

function TScriptScanner.GetInteger: Boolean;
var
  LCode: Integer;
begin
  if not GetString then
    Exit(False);
  Val(FWord, FInteger, LCode);
  if LCode <> 0 then
  begin
    Warn('TScriptEngine.GetInteger(): Bad numeric constant "%s" at Line %d', [FWord, FLine]);
    PrintLineError(FLine, 2);
    Exit(False);
  end;
  Result := True;
end;

function TScriptScanner.MustGetInteger: Boolean;
begin
  Result := GetInteger;
  if not Result then
  begin
    Warn('TScriptEngine.MustGetInteger(): Missing integer at Line %d', [FLine]);
    PrintLineError(FLine, 2);
  end;
end;

function TScriptScanner.GetFloat: Boolean;
var
  LCode: Integer;
  LText: string;
begin
  if not GetString then
    Exit(False);
  LText := FWord;
  Val(LText, FFloat, LCode);
  if LCode <> 0 then
  begin
    LText := LText.Replace(',', '.');
    Val(LText, FFloat, LCode);
    if LCode <> 0 then
    begin
      LText := LText.Replace('.', ',');
      Val(LText, FFloat, LCode);
      if LCode <> 0 then
      begin
        Warn('TScriptEngine.GetFloat(): Bad numeric constant "%s" at Line %d', [FWord, FLine]);
        PrintLineError(FLine, 2);
        Exit(False);
      end;
    end;
  end;
  Result := True;
end;

function TScriptScanner.MustGetFloat: Boolean;
begin
  Result := GetFloat;
  if not Result then
  begin
    Warn('TScriptEngine.MustGetFloat(): Missing float at Line %d', [FLine]);
    PrintLineError(FLine, 2);
  end;
end;

function TScriptScanner.GetBoolean: Boolean;
var
  LUpper: string;
begin
  if not GetString then
    Exit(False);
  LUpper := TScannerStrings.UpperAscii(FWord);
  Result := (LUpper = 'TRUE') or (LUpper = 'FALSE');
  FBoolean := LUpper = 'TRUE';
end;

function TScriptScanner.MustGetBoolean: Boolean;
begin
  Result := GetBoolean;
  if not Result then
  begin
    Warn('TScriptEngine.MustGetBoolean(): Missing boolean at Line %d', [FLine]);
    PrintLineError(FLine, 2);
  end;
end;

procedure TScriptScanner.UnGet;
begin
  // there has to be a valid word
  FAlreadyGot := True;
end;

function TScriptScanner.MatchString(const AWord: string): Boolean;
begin
  Result := Compare(AWord);
end;

function TScriptScanner.MatchString(const AWords: TArray<string>): Integer;
var
  LIndex: Integer;
  LUpper: string;
begin
  LUpper := GetUpperWord;
  for LIndex := 0 to High(AWords) do
    if Compare(AWords[LIndex], LUpper) then
      Exit(LIndex);
  Result := -1;
end;

function TScriptScanner.MatchPosString(const AWord: string): Boolean;
begin
  Result := TScannerStrings.UpperAscii(FWord).Contains(TScannerStrings.UpperAscii(AWord));
end;

function TScriptScanner.MustMatchString(const AWords: TArray<string>): Integer;
begin
  Result := MatchString(AWords);
  if Result = -1 then
  begin
    Warn('TScriptEngine.MustMatchString(): List'#13#10'%s'#13#10'expected at Line %d',
      [string.Join(#13#10, AWords) + #13#10, FLine]);
    PrintLineError(FLine, 2);
  end;
end;

function TScriptScanner.Compare(const AWord: string): Boolean;
begin
  Result := TScannerStrings.UpperAscii(AWord) = GetUpperWord;
end;

function TScriptScanner.Compare(const AWord: string; const AUpperCurrent: string): Boolean;
begin
  Result := TScannerStrings.UpperAscii(AWord) = AUpperCurrent;
end;

function TScriptScanner.GetStringEOL: string;
begin
  Result := '';
  if not GetString then
    Exit;
  if FNewLine then
  begin
    FAlreadyGot := True;
    Exit;
  end;
  Result := FWord;
  while not FFinished and not FNewLine do
  begin
    GetString;
    if FNewLine then
    begin
      FAlreadyGot := True;
      Exit;
    end;
    Result := Result + ' ' + FWord;
  end;
end;

function TScriptScanner.GetStringEOLWithQuotes: string;
begin
  Result := '';
  if not GetString then
    Exit;
  if FNewLine then
  begin
    FAlreadyGot := True;
    Exit;
  end;
  Result := '"' + FWord + '"';
  while not FFinished and not FNewLine do
  begin
    GetString;
    if FNewLine then
    begin
      FAlreadyGot := True;
      Exit;
    end;
    Result := Result + ' "' + FWord + '"';
  end;
end;

function TScriptScanner.GetTokensEOL: TArray<string>;
begin
  Result := nil;
  if not GetString then
    Exit;
  if FNewLine then
  begin
    FAlreadyGot := True;
    Exit;
  end;
  SetLength(Result, 1);
  Result[0] := FWord;
  while not FFinished and not FNewLine do
  begin
    GetString;
    if FNewLine then
    begin
      FAlreadyGot := True;
      Exit;
    end;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := FWord;
  end;
end;

function TScriptScanner.GetStringEOLUnchanged: string;
begin
  Result := '';
  if FPosition < Length(FText) then
    if CharAt(FPosition) = 10 then
    begin
      Inc(FPosition);
      if FPosition < Length(FText) then
        Result := Char(CharAt(FPosition));
    end;
  while CharAt(FPosition) <> 10 do
  begin
    Inc(FPosition);
    if FPosition >= Length(FText) then
    begin
      FFinished := True;
      Exit;
    end;
    if not (CharAt(FPosition) in [10, 13]) then
      Result := Result + Char(CharAt(FPosition));
  end;
end;

end.
