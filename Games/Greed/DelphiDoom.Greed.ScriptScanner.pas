{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the words of the script of a map                 }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the methods of              }
{  TScriptEngine of scriptengine.pas that event.pas uses                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScriptScanner;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_STRING_SIZE - 1: the longest word; what follows is the next word</summary>
  GREED_SCRIPT_MAX_WORD = 1023;

type
  /// <summary>
  ///   The scanner of the script of a map, on the 8 bit text of the lump: GetString, MustGetString, GetInteger,
  ///   MustGetInteger and GetStringEOL of TScriptEngine, line by line. A word ends at a byte up to 32, at one of
  ///   { } ( ) , and at //; between quotes everything is kept up to the closing quote. What the original only
  ///   printed (a missing word, a bad number, a bracket that closes without opening) is counted in Problems and
  ///   the reading goes on as in the original: a number that is missing because the text is over leaves the number
  ///   read before, a bad number gives what Val read before the wrong character. Kept defects: a single / is
  ///   thrown away; after GetStringEOL at the end of the text the last word is given once more. The original read
  ///   one byte past the end of its buffer: here that byte is 0 (the text that event.pas gives always ends with a
  ///   line break, so the byte is never part of a word)
  /// </summary>
  TGreedScriptScanner = class
  strict private
    FText: TBytes;
    FPosition: Integer;
    FToken: TBytes;
    FInteger: Integer;
    FLine: Integer;
    FFinished: Boolean;
    FNewLine: Boolean;
    FAlreadyGot: Boolean;
    FProblems: Integer;
    function ByteAt(AIndex: Integer): Byte; inline;
    function GetToken: string;
    function GetUpperToken: string;
    function ReachedEnd: Boolean;
    procedure ReadWord;
  public
    /// <summary>AText is the text as the scanner reads it (see NormalizeLines)</summary>
    constructor Create(const AText: TBytes);
    /// <summary>
    ///   What TStringList.Text gives back of a text (event.pas passes the script through a TStringList): the lines
    ///   end with CR, LF or CR LF and are joined with CR LF, also the last one
    /// </summary>
    class function NormalizeLines(const AText: TBytes): TBytes; static;
    /// <summary>The next word; False when the text is over</summary>
    function GetString: Boolean;
    procedure MustGetString;
    /// <summary>
    ///   The next word as a number. False only if the word is not a number; True also when the text is over (the
    ///   number stays the one read before), as in the original
    /// </summary>
    function GetInteger: Boolean;
    procedure MustGetInteger;
    /// <summary>GetStringEOL: the words up to the end of the line are thrown away</summary>
    procedure SkipToEndOfLine;
    /// <summary>The last word, a character for each byte</summary>
    property Token: string read GetToken;
    /// <summary>The last word with a..z as capitals (strupper of the original)</summary>
    property UpperToken: string read GetUpperToken;
    property IntegerValue: Integer read FInteger;
    property Line: Integer read FLine;
    property Finished: Boolean read FFinished;
    /// <summary>How many times the original would have printed an error of the script</summary>
    property Problems: Integer read FProblems;
  end;

implementation

const
  ASCII_LINE_FEED = 10;
  ASCII_CARRIAGE_RETURN = 13;
  ASCII_SPACE = 32;
  ASCII_QUOTE = Ord('"');
  ASCII_SLASH = Ord('/');

function IsSeparator(AByte: Byte): Boolean; inline;
begin
  Result := (AByte = Ord('{')) or (AByte = Ord('}')) or (AByte = Ord('(')) or (AByte = Ord(')')) or
    (AByte = Ord(','));
end;

{ TGreedScriptScanner }

constructor TGreedScriptScanner.Create(const AText: TBytes);
begin
  inherited Create;
  FText := Copy(AText);
  FLine := 1;
end;

class function TGreedScriptScanner.NormalizeLines(const AText: TBytes): TBytes;
var
  LPosition, LStart, LLength, LCount: Integer;
begin
  LLength := Length(AText);
  // every line gets at most two bytes more than it has
  SetLength(Result, LLength * 2 + 2);
  LCount := 0;
  LPosition := 0;
  while LPosition < LLength do
  begin
    LStart := LPosition;
    while (LPosition < LLength) and (AText[LPosition] <> ASCII_LINE_FEED) and
      (AText[LPosition] <> ASCII_CARRIAGE_RETURN) do
      Inc(LPosition);
    if LPosition > LStart then
      Move(AText[LStart], Result[LCount], LPosition - LStart);
    Inc(LCount, LPosition - LStart);
    Result[LCount] := ASCII_CARRIAGE_RETURN;
    Result[LCount + 1] := ASCII_LINE_FEED;
    Inc(LCount, 2);
    if (LPosition < LLength) and (AText[LPosition] = ASCII_CARRIAGE_RETURN) then
      Inc(LPosition);
    if (LPosition < LLength) and (AText[LPosition] = ASCII_LINE_FEED) then
      Inc(LPosition);
  end;
  SetLength(Result, LCount);
end;

function TGreedScriptScanner.ByteAt(AIndex: Integer): Byte;
begin
  if AIndex < Length(FText) then
    Result := FText[AIndex]
  else
    Result := 0;
end;

function TGreedScriptScanner.GetToken: string;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(FToken));
  for LIndex := 0 to High(FToken) do
    Result[LIndex + 1] := Char(FToken[LIndex]);
end;

function TGreedScriptScanner.GetUpperToken: string;
var
  LIndex: Integer;
begin
  Result := GetToken;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

function TGreedScriptScanner.ReachedEnd: Boolean;
begin
  Result := FPosition >= Length(FText);
  if Result then
    FFinished := True;
end;

procedure TGreedScriptScanner.ReadWord;
var
  LWord: TBytes;
  LCount, LEnd, LIndex: Integer;
begin
  LEnd := Length(FText);
  SetLength(LWord, GREED_SCRIPT_MAX_WORD);
  LCount := 0;
  if ByteAt(FPosition) = ASCII_QUOTE then
  begin
    Inc(FPosition);
    while ByteAt(FPosition) <> ASCII_QUOTE do
    begin
      LWord[LCount] := ByteAt(FPosition);
      Inc(LCount);
      Inc(FPosition);
      if (FPosition = LEnd) or (LCount = GREED_SCRIPT_MAX_WORD) then
        Break;
    end;
    Inc(FPosition);
  end
  else
  begin
    while (ByteAt(FPosition) > ASCII_SPACE) and (FPosition < LEnd) and
      not ((ByteAt(FPosition) = ASCII_SLASH) and (ByteAt(FPosition + 1) = ASCII_SLASH)) and
      not IsSeparator(ByteAt(FPosition)) do
    begin
      LWord[LCount] := ByteAt(FPosition);
      Inc(LCount);
      Inc(FPosition);
      if (FPosition = LEnd) or (LCount = GREED_SCRIPT_MAX_WORD) then
        Break;
    end;
  end;
  // the word of the original is a C string: it ends at its first zero
  for LIndex := 0 to LCount - 1 do
    if LWord[LIndex] = 0 then
    begin
      LCount := LIndex;
      Break;
    end;
  FToken := Copy(LWord, 0, LCount);
end;

function TGreedScriptScanner.GetString: Boolean;
var
  LFound: Boolean;
  LByte: Byte;
begin
  if FAlreadyGot then
  begin
    FAlreadyGot := False;
    Exit(True);
  end;
  FNewLine := False;
  if ReachedEnd then
    Exit(False);
  LFound := False;
  while not LFound do
  begin
    LByte := ByteAt(FPosition);
    while (LByte <= ASCII_SPACE) or IsSeparator(LByte) do
    begin
      if ReachedEnd then
        Exit(False);
      if LByte = ASCII_LINE_FEED then
      begin
        Inc(FLine);
        FNewLine := True;
      end;
      Inc(FPosition);
      LByte := ByteAt(FPosition);
    end;
    if ReachedEnd then
      Exit(False);
    if ByteAt(FPosition) <> ASCII_SLASH then
      LFound := True
    else
    begin
      Inc(FPosition);
      if ByteAt(FPosition) = ASCII_SLASH then
      begin
        while (ByteAt(FPosition) <> ASCII_CARRIAGE_RETURN) and (ByteAt(FPosition) <> ASCII_LINE_FEED) do
        begin
          if ReachedEnd then
            Exit(False);
          Inc(FPosition);
        end;
        Inc(FLine);
        FNewLine := True;
      end;
    end;
  end;
  ReadWord;
  Result := True;
end;

procedure TGreedScriptScanner.MustGetString;
begin
  if not GetString then
    Inc(FProblems);
end;

function TGreedScriptScanner.GetInteger: Boolean;
var
  LCode: Integer;
begin
  Result := True;
  if GetString then
  begin
    // the number of a word that is not one is what Val leaves, as in the original
    Val(GetToken, FInteger, LCode);
    if LCode <> 0 then
    begin
      Inc(FProblems);
      Result := False;
    end;
  end;
end;

procedure TGreedScriptScanner.MustGetInteger;
begin
  if not GetInteger then
    Inc(FProblems);
end;

procedure TGreedScriptScanner.SkipToEndOfLine;
begin
  if not GetString then
    Exit;
  if FNewLine then
  begin
    FAlreadyGot := True;
    Exit;
  end;
  while not FFinished and not FNewLine do
  begin
    GetString;
    if FNewLine then
    begin
      FAlreadyGot := True;
      Exit;
    end;
  end;
end;

end.
