{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - reading the words of an action script             }
{                                                                              }
{  Port of COM_ParseExt (q_shared.c) and of Float_Parse, Int_Parse,            }
{  Color_Parse, Rect_Parse and String_Parse (ui_shared.c), the functions that  }
{  take the arguments of a script command out of a text. Quake III Arena, id   }
{  Software, GPL v2 or later. Based on the Quake III Arena GPL Source Code     }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.ScriptCursor;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.StringPool;

type
  /// <summary>Where a cursor is, to go back to it (the "char *p" of the original)</summary>
  TGuiScriptCursorState = record
    Position: Integer;
    Ended: Boolean;
  end;

  /// <summary>
  ///   The "char **p" of the script functions: a text and a position. Bytes of 128 and more are negative
  ///   characters in the original (white space between words, and the end of a word).
  /// </summary>
  TGuiScriptCursor = class
  strict private
    FText: AnsiString;
    FState: TGuiScriptCursorState;
    FStrings: TGuiStringPool;
    function CharAt(const APosition: Integer): Integer;
  public
    /// <summary>The pool is optional (String_Parse puts the words in it)</summary>
    constructor Create(const AText: AnsiString; const AStrings: TGuiStringPool = nil);
    /// <summary>
    ///   COM_ParseExt(p, qfalse): the next word; a word in quotes keeps its blanks; "//" and "/* */" are
    ///   comments; empty at the end or at a new line; a word of 1024 characters or more is discarded (empty)
    /// </summary>
    function ParseExt: AnsiString;
    function SaveState: TGuiScriptCursorState;
    procedure RestoreState(const AState: TGuiScriptCursorState);
    /// <summary>String_Parse: false if the word is empty</summary>
    function ParseString(var AText: AnsiString): Boolean;
    /// <summary>Float_Parse: atof of the word</summary>
    function ParseFloat(var AValue: Single): Boolean;
    /// <summary>Int_Parse: atoi of the word</summary>
    function ParseInt(var AValue: Integer): Boolean;
    /// <summary>Color_Parse: four floats, each stored as it is read</summary>
    function ParseColor(var AColor: TGuiColor): Boolean;
    function ParseRect(var ARect: TGuiRect): Boolean;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers;

const
  // MAX_TOKEN_CHARS
  MAX_WORD_CHARS = 1024;

constructor TGuiScriptCursor.Create(const AText: AnsiString; const AStrings: TGuiStringPool);
begin
  inherited Create;
  FText := AText;
  FStrings := AStrings;
  FState.Position := 1;
end;

// the character at a position as a signed char; zero at and after the end
function TGuiScriptCursor.CharAt(const APosition: Integer): Integer;
begin
  if (APosition < 1) or (APosition > Length(FText)) then
    Exit(0);
  Result := ShortInt(Byte(FText[APosition]));
end;

function TGuiScriptCursor.SaveState: TGuiScriptCursorState;
begin
  Result := FState;
end;

procedure TGuiScriptCursor.RestoreState(const AState: TGuiScriptCursorState);
begin
  FState := AState;
end;

function TGuiScriptCursor.ParseExt: AnsiString;
var
  LPosition: Integer;
  LHasNewLines: Boolean;
  LChar: Integer;
  LWord: AnsiString;
begin
  Result := '';
  if FState.Ended then
    Exit;
  LPosition := FState.Position;
  LHasNewLines := False;
  while True do
  begin
    // skip white space
    while CharAt(LPosition) <= 32 do
    begin
      if LPosition > Length(FText) then
      begin
        FState.Ended := True;
        Exit;
      end;
      if CharAt(LPosition) = 10 then
        LHasNewLines := True;
      Inc(LPosition);
    end;
    if LHasNewLines then
    begin
      FState.Position := LPosition;
      Exit;
    end;
    LChar := CharAt(LPosition);
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
  LWord := '';
  if LChar = Ord('"') then
  begin
    Inc(LPosition);
    while True do
    begin
      LChar := CharAt(LPosition);
      Inc(LPosition);
      if (LChar = Ord('"')) or (LChar = 0) then
      begin
        FState.Position := LPosition;
        if LChar = 0 then
          FState.Ended := True;
        Exit(LWord);
      end;
      if Length(LWord) < MAX_WORD_CHARS then
        LWord := LWord + AnsiChar(Byte(LChar));
    end;
  end;
  repeat
    if Length(LWord) < MAX_WORD_CHARS then
      LWord := LWord + AnsiChar(Byte(LChar));
    Inc(LPosition);
    LChar := CharAt(LPosition);
  until LChar <= 32;
  if Length(LWord) = MAX_WORD_CHARS then
    LWord := '';
  FState.Position := LPosition;
  Result := LWord;
end;

function TGuiScriptCursor.ParseString(var AText: AnsiString): Boolean;
var
  LWord: AnsiString;
begin
  LWord := ParseExt;
  if LWord = '' then
    Exit(False);
  if Assigned(FStrings) then
    AText := FStrings.Alloc(LWord)
  else
    AText := LWord;
  Result := True;
end;

function TGuiScriptCursor.ParseFloat(var AValue: Single): Boolean;
var
  LWord: AnsiString;
begin
  LWord := ParseExt;
  if LWord = '' then
    Exit(False);
  AValue := TIdCNumbers.Atof(LWord);
  Result := True;
end;

function TGuiScriptCursor.ParseInt(var AValue: Integer): Boolean;
var
  LWord: AnsiString;
begin
  LWord := ParseExt;
  if LWord = '' then
    Exit(False);
  AValue := TIdCNumbers.Atoi(LWord);
  Result := True;
end;

function TGuiScriptCursor.ParseColor(var AColor: TGuiColor): Boolean;
var
  LIndex: Integer;
  LValue: Single;
begin
  LValue := 0;
  for LIndex := 0 to 3 do
  begin
    if not ParseFloat(LValue) then
      Exit(False);
    AColor[LIndex] := LValue;
  end;
  Result := True;
end;

function TGuiScriptCursor.ParseRect(var ARect: TGuiRect): Boolean;
begin
  Result := ParseFloat(ARect.X) and ParseFloat(ARect.Y) and ParseFloat(ARect.W) and ParseFloat(ARect.H);
end;

end.
